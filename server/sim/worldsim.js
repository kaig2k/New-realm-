'use strict';
/*
 * Server-run monsters. Each realm, dungeon, raid and Dark Elder chamber that
 * players are in gets a WorldSim: the same map the game generates (from the
 * world's seed), the same monster AI and boss scripts (converted from the
 * game's code into gen/game.js), and the spawning, event and kill rules the
 * game used to run on one player's PC (the "host").
 *
 * The server speaks the game's existing host protocol, so players' games
 * treat it exactly like a host: "espawn" (new monsters), "esnap" (positions,
 * health, phase), "efire" (a monster attacks; every game replays the same
 * bullets), "ekill", "edel", "emax", "wstate", "rstage" and "portal". Games
 * send their hits as "ehit"; the server decides when a monster dies.
 */
const { Bosses, Data, World, Enemy, SetPieces } = require('./gen/game');

Bosses.init();

const TICK = 0.05;
const SNAP_RANGE = 24;
const FIRE_RANGE = 34;
const DESPAWN_RANGE = 34;
const MAX_NEAR = 15;
const PORTAL_TIME = 30;
const ELITES = ['Swift', 'Armored', 'Frenzied', 'Giant', 'Splitting', 'Vampiric'];
const SIEGE_TIME = 15 * 60;
const r2 = (v) => Math.round(v * 100) / 100;

let nextId = 1;

/** Damage a second for a player the server knows nothing about yet (see maxDps in server.js), and seconds of it to hold for bursts. */
const MAX_DPS = 20000, DPS_BURST = 3;

class WorldSim {
  /** key: "realm:Name:seed", "dg:index:seed", "raid:index:seed" or "arena:seed". */
  constructor(key) {
    this.key = key;
    this.players = new Map(); // client id -> client {id, x, y, send, hidden}
    this.emptyFor = 0;
    this.time = 0;
    this.snapT = 0;
    this.spawnT = 1;
    this.scaleT = 0;
    this.goblinT = 150 + Math.random() * 150;
    this.closeT = 0;
    const p = key.split(':');
    this.kind = p[0];
    if (this.kind === 'realm') {
      this.w = new World('realm', p.slice(1, -1).join(':'), null, Number(p[p.length - 1]) >>> 0);
    } else if (this.kind === 'dg') {
      this.theme = Data.DUNGEONS[Number(p[1])];
      if (!this.theme) throw new Error('unknown dungeon ' + key);
      this.w = new World('dungeon', this.theme.name, this.theme, Number(p[2]) >>> 0);
    } else if (this.kind === 'raid') {
      const rd = Bosses.RAIDS[Number(p[1])];
      if (!rd) throw new Error('unknown raid ' + key);
      this.w = new World('dungeon', rd.name, rd.theme, Number(p[2]) >>> 0);
      this.w.raid = rd;
      this.w.raidStage = -1;
      this.w.raidT = 1;
      // Heroic: its world key ends in ':h' (two keys at the Raid Table: see server.js portalKey)
      this.heroic = p[3] === 'h';
      this.w.heroic = this.heroic;
      // the week the run counts for (its first clear, its board), fixed for the run even past midnight on Sunday
      this.week = Math.floor((Math.floor(Date.now() / 86400000) + 3) / 7);
      // and the Starfall Vault's rule for this week
      if (rd.twists) this.twist = Bosses.vaultTwist(this.week);
    } else if (this.kind === 'deep') {
      // the Endless Abyss: an arena where the waves keep coming (updateWaves)
      this.w = new World('abyss', 'The Endless Abyss');
      this.deep = { wave: 0, state: 'break', t: 10, left: 0, mods: [], pulses: [], fightT: 0, restT: 0 };
    } else if (this.kind === 'arena') {
      this.w = new World('arena', "Dark Elder's Chamber");
    } else throw new Error('not a simulated world: ' + key);
    this.w.key = key;
    this.byId = new Map();
    this.g = this.gameShim();
    this.populate();
  }

  static simulates(key) { return /^(realm|dg|raid|arena|deep):/.test(key); }

  get enemies() { return this.w.enemies; }

  // ------------------------------------------------------------ what Enemy.update needs from "the game"
  gameShim() {
    const sim = this;
    return {
      world: this.w, camCos: 1, camSin: 0,
      scrX: (x) => x,
      aggroTarget: (e) => sim.target(e),
      spawnEnemy: (id, x, y, zone) => sim.spawn(id, x, y, zone),
      countAlive: (id) => sim.enemies.filter((e) => !e.dead && e.defId === id).length,
      burst() {}, later() {}, addMarker() {}, groundFx() {}, addWeb() {}, soundAt() {}, bossPhase: (ph, b) => sim.bossPhase(ph, b),
      addShot: (s) => sim.trackShot(s), areaHit: (x, y, r) => sim.expectArea(x, y, r),
      sync: { fired: (e, i, ang, spin, code, dist) => sim.fired(e, i, ang, spin, code, dist) }
    };
  }

  /** The nearest player a monster can see (not invisible, not in a safe zone). */
  target(e) {
    let best = null, bd = 1e9;
    for (const c of this.players.values()) {
      if (c.hidden || this.w.isSafe(c.x, c.y)) continue;
      const d = (c.x - e.x) * (c.x - e.x) + (c.y - e.y) * (c.y - e.y);
      if (d < bd) { bd = d; best = c; }
    }
    return best;
  }

  spawn(id, x, y, zone, force) {
    if (!Data.ENEMIES[id]) return null;
    if (!force && !this.w.canStand(x, y, 0.35, true)) return null;
    const e = new Enemy(id, x, y, zone);
    this.add(e);
    return e;
  }

  add(e) {
    // (the Endless Abyss: everything in a wave is as tough as the wave)
    if (this.deep && this.deep.wave && !e.def.treasure && !e.deepScaled) {
      const m = Data.deepScale(this.deep.wave);
      e.deepScaled = true;
      e.maxHp *= m[0];
      e.hp = e.maxHp;
      e.dmgMult = (e.dmgMult || 1) * m[1];
    }
    e.id = nextId++;
    e.hitters = new Map(); // client id -> damage dealt (who gets loot)
    this.w.enemies.push(e);
    this.byId.set(e.id, e);
    this.fresh = this.fresh || [];
    this.fresh.push(e);
  }

  entry(e) {
    return [e.id, e.defId, r2(e.x), r2(e.y), e.zone, Math.ceil(e.hp), Math.ceil(e.maxHp), r2(e.dmgMult), this.flags(e),
      this.w.boss === e ? 1 : 0, r2(e.homeX), r2(e.homeY), e.elite || '', e.spMask || 0];
  }

  flags(e) { return (e.immune ? 1 : 0) | (e.stunT > 0 ? 2 : 0) | (e.phaseCode << 2); }

  // ------------------------------------------------------------ messages out
  send(c, d) { c.send({ t: 'w', from: 0, d }); }
  all(d) { for (const c of this.players.values()) this.send(c, d); }
  near(x, y, r, d) {
    for (const c of this.players.values()) {
      if ((c.x - x) * (c.x - x) + (c.y - y) * (c.y - y) < r * r) this.send(c, d);
    }
  }

  fired(e, i, ang, spin, code, dist) {
    this.near(e.x, e.y, FIRE_RANGE, { t: 'efire', id: e.id, i, a: Math.round(ang * 1000) / 1000, s: Math.round(spin * 1000) / 1000, p: code, d: Math.round(dist * 10) / 10 });
  }

  /**
   * The dungeon a closing realm pulls its players into (Game.enterCitadel and finaleFor): one of
   * the finales, picked by the realm's seed, with a seed of its own made from it, so everyone from
   * the realm lands in the same one.
   */
  finaleKey() {
    const seed = Number(this.key.split(':').pop()) >>> 0;
    const ids = Bosses.FINALES;
    const fid = ids[seed % ids.length];
    const dseed = (((seed * 2654435761) & 0x7fffffff) | 1) >>> 0;
    return 'dg:' + Data.dungeonIndex(fid) + ':' + dseed;
  }

  portal(x, y, kind, idx, color) {
    const seed = 1 + Math.floor(Math.random() * 0x7ffffffe);
    this.all({ t: 'portal', x: r2(x), y: r2(y), k: kind, i: idx, c: color, l: PORTAL_TIME, s: seed });
    // (the server lets people into the world behind it: see server.js openWorlds)
    if (this.onPortal) this.onPortal((kind === 'raid' ? 'raid:' : 'dg:') + idx + ':' + seed);
  }

  // ------------------------------------------------------------ players
  join(c) {
    this.players.set(c.id, c);
    this.emptyFor = 0;
    // (the Abyss: where the waves are at)
    if (this.deep) { const d = this.deep; c.send({ t: 'deepWave', wave: d.wave, state: d.state, left: d.left, secs: Math.ceil(d.t) }); }
  }

  leave(c) { this.players.delete(c.id); }

  /** A game's message to the world host. */
  onClient(c, d) {
    if (!d || typeof d !== 'object') return;
    if (d.t === 'sync') {
      const list = [];
      for (const e of this.enemies) if (!e.dead) list.push(this.entry(e));
      this.send(c, { t: 'espawn', l: list, n: 0 });
      this.send(c, { t: 'wstate', ev: this.w.eventsDone, ct: r2(this.closeT), rs: this.w.raidStage });
    } else if (d.t === 'ehit') {
      this.hit(c, d);
    }
  }

  /** A player's shot or ability landed. */
  hit(c, d) {
    const e = this.byId.get(Number(d.id));
    if (!e || e.dead) return;
    const dx = e.x - c.x, dy = e.y - c.y;
    // you can only hit what is reasonably near you
    if (dx * dx + dy * dy > 30 * 30) return;
    const sl = Math.min(5, Math.max(0, Number(d.sl) || 0)), st = Math.min(5, Math.max(0, Number(d.st) || 0));
    if (sl) e.slowT = Math.max(e.slowT, sl);
    if (st) e.stunT = Math.max(e.stunT, e.isBoss ? st * 0.4 : st);
    // no bigger than the hero's own gear and stats allow (server/combat.js; admins have no caps)
    let dmg = Math.min(c.caps ? c.caps.hit : 6000, Math.max(0, Number(d.d) || 0));
    if (dmg > 0 && c.caps) {
      // and no faster on any one monster than its weapon, ability and pet could manage
      const now = Date.now();
      const tb = e.tb || (e.tb = new Map());
      const b = tb.get(c.id) || { left: c.caps.burst, t: now };
      b.left = Math.min(c.caps.burst, b.left + c.caps.rate * (now - b.t) / 1000);
      b.t = now;
      tb.set(c.id, b);
      if (b.left <= 0) { c.dpsCut = (c.dpsCut || 0) + 1; return; }
      if (dmg > b.left) { c.dpsCut = (c.dpsCut || 0) + 1; dmg = b.left; }
      b.left -= dmg;
    }
    // nobody deals damage faster than the best gear can: a budget that refills at MAX_DPS
    // (with room for big ability bursts); hits beyond it don't count
    if (dmg > 0) {
      const now = Date.now();
      const rate = c.maxDps || MAX_DPS, cap = rate * DPS_BURST + 20000;
      const b = c.dps || (c.dps = { left: cap, t: now });
      b.left = Math.min(cap, b.left + rate * (now - b.t) / 1000);
      b.t = now;
      if (b.left <= 0) { c.dpsCut = (c.dpsCut || 0) + 1; return; }
      dmg = Math.min(dmg, b.left);
      b.left -= dmg;
    }
    // an event's clock (for the fastest-kill records) starts at the first hit on the boss or its set piece
    if (dmg > 0 && this.kind === 'realm' && this.w.boss && !this.w.boss.firstHit && (e === this.w.boss || e.def.prop)) this.w.boss.firstHit = Date.now();
    if (dmg > 0 && !e.immune) {
      if (dmg > e.hp) dmg = Math.ceil(e.hp);
      e.hp -= dmg;
      e.hitT = 0.08;
      e.hitters.set(c.id, (e.hitters.get(c.id) || 0) + dmg);
      // under 1 HP left (scaled health isn't whole) counts as dead
      if (e.hp < 1) this.kill(e);
    }
  }

  // ------------------------------------------------------------ the world's monsters
  populate() {
    const w = this.w;
    if (this.kind === 'dg') this.populateDungeon(this.theme);
    else if (this.kind === 'raid') this.populateRaid();
    else if (this.kind === 'arena') {
      w.boss = new Enemy('elder', 100.5, 91.5, World.ARENA_ZONE);
      this.add(w.boss);
    }
  }

  populateDungeon(th) {
    const w = this.w, rooms = w.rooms, rnd = Math.random;
    const pick = () => th.mobs[Math.floor(rnd() * th.mobs.length)];
    for (let r = 1; r < rooms.length - 1; r++) {
      const rm = rooms[r];
      const n = 3 + Math.floor(rnd() * 3);
      for (let k = 0; k < n; k++) this.spawn(pick(), rm.x + (rnd() - 0.5) * (rm.w - 3), rm.y + (rnd() - 0.5) * (rm.h - 3), th.tier);
    }
    for (let r = 1; r < rooms.length - 1; r++) {
      if (rnd() > 0.45) continue;
      const crm = rooms[r];
      for (let k = 1 + Math.floor(rnd() * 2); k > 0; k--) this.spawn('crate', crm.x + (rnd() - 0.5) * (crm.w - 3), crm.y + (rnd() - 0.5) * (crm.h - 3), th.tier);
    }
    const tr = w.treasure;
    if (tr) {
      this.spawn('treasure', tr.x + 0.5, tr.y + 0.5, th.tier);
      for (let k = 0; k < 3; k++) this.spawn(pick(), tr.x + 0.5 + (k - 1) * 2, tr.y + 2, th.tier);
    }
    const last = rooms[rooms.length - 1];
    if (th.guardians) {
      th.guardians.forEach((gid, gi) => {
        const gr = rooms[Math.max(1, Math.round((gi + 1) * (rooms.length - 1) / (th.guardians.length + 1)))];
        this.add(new Enemy(gid, gr.x + 0.5, gr.y + 0.5, th.tier));
      });
    }
    if (th.trio) {
      th.trio.forEach((tid, gi) => {
        const e = new Enemy(tid, last.x + 0.5 + (gi - 1) * 5, last.y + 0.5 + (gi === 1 ? -2 : 1), th.tier);
        this.add(e);
        if (gi === 0) w.boss = e;
      });
    }
    if (th.boss) {
      w.boss = new Enemy(th.boss, last.x + 0.5, last.y + 0.5, th.tier);
      if (w.boss.def.sealed) w.boss.invuln = true;
      this.add(w.boss);
    }
    if (th.hard) {
      for (const e of w.enemies) {
        if (e.def.treasure) continue;
        e.maxHp *= th.hard;
        e.hp = e.maxHp;
        e.dmgMult = 1 + (th.hard - 1) * 0.6;
      }
    }
  }

  populateRaid() {
    const w = this.w, th = w.raid.theme;
    const tw = this.twist;
    for (const rm of w.mobRooms) {
      for (let k = 0; k < rm.n * (tw && tw.guards ? tw.guards : 1); k++) {
        const e = this.spawn(th.mobs[Math.floor(Math.random() * th.mobs.length)], rm.x + (Math.random() - 0.5) * rm.w, rm.y + (Math.random() - 0.5) * rm.h, th.tier);
        if (!e) continue;
        e.maxHp *= th.hard;
        e.hp = e.maxHp;
        e.dmgMult = 1 + (th.hard - 1) * 0.6;
        Bosses.twistEnemy(e, tw, false);
        if (this.heroic) Bosses.heroicEnemy(e, false);
      }
    }
  }

  // ------------------------------------------------------------ shots that should hit (godmode checks)
  /**
   * The server follows every enemy shot (straight, weaving, speeding up or
   * coming back; homing ones are left out) and counts, per player, the ones
   * that pass clean through the middle of where that player is. Their games
   * report the hits they took; a game that keeps taking none of them is
   * ignoring damage (see godmodeCheck in server.js).
   */
  /**
   * A boss entered a new phase. The Dark Elder's chamber burns (World.elderPhase,
   * as every game does), and in his third phase his four crystals rise and keep
   * him immune until they're broken (see the crystal check in kill).
   */
  bossPhase(ph, b) {
    if (!b || !b.def.final || this.kind !== 'arena') return;
    for (let k = 0; k <= ph; k++) this.w.elderPhase(k);
    if (ph === 2) {
      let n = 0;
      for (const [dx, dy] of Data.ELDER_CRYSTALS) if (this.spawn('elder_crystal', b.homeX + dx, b.homeY + 7 + dy, World.ARENA_ZONE, true)) n++;
      if (n) b.invuln = true;
    }
  }

  trackShot(s) {
    if (!s || !s.enemy || s.motion === 'home') return;
    if (!this.shots) this.shots = [];
    if (this.shots.length > 3000) this.shots.shift();
    // (only players whose game was sent this shot can be expected to take it: see fired)
    const to = new Set();
    for (const c of this.players.values()) if ((c.x - s.x) * (c.x - s.x) + (c.y - s.y) * (c.y - s.y) < FIRE_RANGE * FIRE_RANGE) to.add(c.id);
    this.shots.push({ to, x: s.x, y: s.y, a: s.angle, spd: s.speed, life: s.life, life0: s.life, r: s.r, motion: s.motion || '', accel: s.accel || 0, age: 0, back: false, walls: !s.passWalls,
      dmg: Math.max(0, Number(s.dmg) || 0) });
  }

  expectArea(x, y, r) {
    const now = Date.now();
    for (const c of this.players.values()) {
      if ((c.grace || 0) > now) continue;
      const dx = c.x - x, dy = c.y - y;
      if (dx * dx + dy * dy < r * r * 0.5) c.expHits = (c.expHits || 0) + 1;
    }
  }

  stepShots(dt) {
    const list = this.shots;
    if (!list || !list.length) return;
    const now = Date.now(), w = this.w;
    for (let i = list.length - 1; i >= 0; i--) {
      const s = list[i];
      s.age += dt; s.life -= dt;
      if (s.accel) s.spd += s.accel * dt;
      if ((s.motion === 'return' || s.motion === 'boomerang') && !s.back && s.age > s.life0 / 2) { s.back = true; s.a += Math.PI; }
      s.x += Math.cos(s.a) * s.spd * dt;
      s.y += Math.sin(s.a) * s.spd * dt;
      let gone = s.life <= 0 || (s.walls && w.blocksShot(s.x, s.y)) || w.isSafe(s.x, s.y);
      if (!gone) {
        // a clean hit: well inside the shot's reach (weaving shots wander, so they need to be closer)
        const reach = (s.r + 0.4) * (s.motion === 'wave' ? 0.35 : 0.6);
        for (const c of this.players.values()) {
          if ((c.grace || 0) > now || !s.to.has(c.id)) continue;
          const dx = c.x - s.x, dy = c.y - s.y;
          if (dx * dx + dy * dy < reach * reach) {
            c.expHits = (c.expHits || 0) + 1;
            // the least this hit can have done to them: their Defense as the server knows it (with every
            // Defense boost there is), or 15% of it, whichever is more (Player.takeHit)
            c.expDmg = (c.expDmg || 0) + Math.max(s.dmg - (c.defMax || 0), Math.floor(s.dmg * 0.15));
            gone = true;
            break;
          }
        }
      }
      if (gone) list.splice(i, 1);
    }
  }

  // ------------------------------------------------------------ the clock
  tick(dt) {
    this.time += dt;
    // (a siege's clock runs on with nobody there, so an abandoned one still ends)
    if (!this.players.size) { this.emptyFor += dt; if (this.siege) this.updateSiege(dt); return; }
    for (const e of this.enemies.slice()) {
      if (e.dead) continue;
      try { e.update(dt, this.g); } catch (err) { e.dead = true; console.error('monster error', e.defId, err.message); }
    }
    for (let i = this.enemies.length - 1; i >= 0; i--) if (this.enemies[i].dead) { this.byId.delete(this.enemies[i].id); this.enemies.splice(i, 1); }
    this.stepShots(dt);
    if (this.kind === 'realm') {
      this.updateSpawns(dt);
      this.updateEvents(dt);
      this.updateGoblin(dt);
      if (this.closeT > 0) { this.closeT -= dt; if (this.closeT <= 0) this.w.closed = true; }
    }
    if (this.w.raid) this.updateRaid(dt);
    if (this.deep) this.updateWaves(dt);
    if (this.siege) this.updateSiege(dt);
    this.updateArena(dt);
    for (const e of this.enemies) {
      if (e.elite === 'Vampiric' && !e.dead && e.hp < e.maxHp) e.hp = Math.min(e.maxHp, e.hp + e.maxHp * 0.03 * dt);
    }
    this.scaleBosses(dt);
    this.flush(dt);
  }

  /** New monsters, then positions every tenth of a second (each player gets what's near them). */
  flush(dt) {
    if (this.fresh && this.fresh.length) {
      const list = this.fresh.filter((e) => !e.dead).map((e) => this.entry(e));
      if (list.length) this.all({ t: 'espawn', l: list, n: 1 });
      this.fresh = [];
    }
    this.snapT -= dt;
    if (this.snapT > 0) return;
    this.snapT = 0.1;
    for (const c of this.players.values()) {
      const flat = [];
      for (const e of this.enemies) {
        if (e.dead) continue;
        const dx = e.x - c.x, dy = e.y - c.y;
        if (!e.isBoss && dx * dx + dy * dy > SNAP_RANGE * SNAP_RANGE) continue;
        flat.push(e.id, Math.trunc(e.x * 100), Math.trunc(e.y * 100), Math.ceil(Math.max(0, e.hp)), this.flags(e));
      }
      if (flat.length) this.send(c, { t: 'esnap', l: flat });
    }
  }

  // ------------------------------------------------------------ realm rules (were Game.updateSpawns etc.)
  updateSpawns(dt) {
    this.spawnT -= dt;
    if (this.spawnT > 0) return;
    this.spawnT = 0.6;
    const spots = [...this.players.values()];
    // monsters far from everyone despawn
    for (let i = this.enemies.length - 1; i >= 0; i--) {
      const e = this.enemies[i];
      if (e.isBoss || e.def.prop) continue;
      if (!spots.some((s) => (e.x - s.x) * (e.x - s.x) + (e.y - s.y) * (e.y - s.y) < DESPAWN_RANGE * DESPAWN_RANGE)) {
        this.enemies.splice(i, 1);
        this.byId.delete(e.id);
        this.all({ t: 'edel', id: e.id });
      }
    }
    this.updateSites(spots);
    if (this.closeT > 0 || this.w.closed) return;
    const who = spots[Math.floor(Math.random() * spots.length)];
    if (this.w.isSafe(who.x, who.y)) return;
    let near = 0;
    for (const e of this.enemies) if ((e.x - who.x) * (e.x - who.x) + (e.y - who.y) * (e.y - who.y) < 24 * 24) near++;
    const pz = this.w.zoneAt(who.x, who.y);
    const cap = pz === 0 ? 8 : pz === 1 ? 11 : pz === 2 ? 13 : pz === 3 ? 14 : MAX_NEAR;
    if (near >= cap) return;
    for (let tries = 0; tries < 6; tries++) {
      const a = Math.random() * Math.PI * 2, r = 14 + Math.random() * 8;
      const sx = who.x + Math.cos(a) * r, sy = who.y + Math.sin(a) * r;
      const z = this.w.zoneAt(sx, sy);
      if (z < 0 || z > World.GOD_ZONE || !this.w.canStand(sx, sy, 0.4, true)) continue;
      if (z >= World.LOW_ZONE && Math.random() < 0.1) {
        for (let cr = 1 + Math.floor(Math.random() * 3); cr > 0; cr--) {
          const crx = sx + Math.random() * 3 - 1.5, cry = sy + Math.random() * 3 - 1.5;
          if (this.w.canStand(crx, cry, 0.45, true)) this.spawn('crate', crx, cry, z);
        }
        return;
      }
      const list = Data.ZONE_SPAWNS[z];
      const id = list[Math.floor(Math.random() * list.length)];
      const count = 1 + Math.floor(Math.random() * (z <= 1 ? 2 : z === World.GOD_ZONE ? 2 : 3));
      for (let k = 0; k < count; k++) {
        const ox = sx + Math.random() * 2 - 1, oy = sy + Math.random() * 2 - 1;
        if (!this.w.canStand(ox, oy, 0.4, true)) continue;
        const ne = this.spawn(id, ox, oy, z);
        if (ne && z >= World.LOW_ZONE && Math.random() < 0.035) this.makeElite(ne);
      }
      return;
    }
  }

  /** Landmarks: a player coming near wakes its leader and band. */
  updateSites(spots) {
    for (const s of this.w.sites) {
      if (s.cleared) continue;
      const nearby = spots.some((sp) => { const dx = sp.x - s.x, dy = sp.y - s.y, rr = s.r + 12; return dx * dx + dy * dy < rr * rr; });
      const alive = s.leader && !s.leader.dead && this.enemies.indexOf(s.leader) >= 0;
      if (s.active && !alive) { s.active = false; s.leader = null; s.retryAt = this.time + 90; }
      if (s.active || !nearby || this.time < (s.retryAt || 0)) continue;
      let crowd = 0;
      for (const e of this.enemies) if (!e.dead && (e.x - s.x) * (e.x - s.x) + (e.y - s.y) * (e.y - s.y) < 400) crowd++;
      if (crowd > 18) continue;
      const leader = this.spawn(s.boss, s.x, s.y, s.zone);
      if (!leader) continue;
      s.active = true;
      s.leader = leader;
      leader.site = s;
      const extra = Math.min(3, Math.max(0, spots.length - 1));
      for (let k = 0; k < s.n + extra; k++) {
        const a = k * Math.PI * 2 / (s.n + extra) + Math.random() * 0.4;
        const d = 2 + Math.random() * (s.r - 3);
        const gd = this.spawn(s.guards[k % s.guards.length], s.x + Math.cos(a) * d, s.y + Math.sin(a) * d, s.zone);
        if (gd) gd.site = s;
      }
    }
  }

  updateEvents(dt) {
    const w = this.w;
    // a restart is close: no new event bosses that nobody could finish
    if (WorldSim.restartSoon) return;
    if (this.closeT > 0 || w.closed || this.siege || w.eventsDone >= Data.EVENTS_PER_REALM || (w.boss && !w.boss.dead)) return;
    w.eventT -= dt;
    if (w.eventT > 0) return;
    if (!w.recentEvents) w.recentEvents = [];
    let id;
    do id = Data.EVENTS[Math.floor(Math.random() * Data.EVENTS.length)]; while (w.recentEvents.indexOf(id) >= 0);
    for (let tries = 0; tries < 500; tries++) {
      // the boss stands in the middle of a tile, at the centre of its set piece
      const x = Math.floor(w.N / 2 + (Math.random() - 0.5) * w.N * 0.6) + 0.5, y = Math.floor(w.N / 2 + (Math.random() - 0.5) * w.N * 0.6) + 0.5;
      const z = w.zoneAt(x, y);
      if (z >= World.MID_ZONE && z <= World.GOD_ZONE && w.canStand(x, y, 0.6, true) && SetPieces.fits(id, w, Math.floor(x), Math.floor(y))) {
        w.nextEvent++;
        w.recentEvents.push(id);
        if (w.recentEvents.length > 4) w.recentEvents.shift();
        // its arena: the structure goes down first, so the boss and its pieces stand on it
        const cells = SetPieces.plan(id, w, Math.floor(x), Math.floor(y));
        SetPieces.apply(w, cells);
        w.boss = new Enemy(id, x, y, z);
        w.boss.arena = cells;
        this.add(w.boss);
        this.unstick(cells);
        // and its wards, menders or hazards
        w.boss.props = [];
        for (const sp of Bosses.setPieceSpots(id, x, y, w)) {
          const pr = this.spawn(sp.what, sp.x, sp.y, z, true);
          if (pr) w.boss.props.push(pr);
        }
        return;
      }
    }
    w.eventT = 5;
  }

  /**
   * The event boss's arena changing mid-fight: once a phase's moment comes
   * (its pieces all broken, or the boss low) the floor flashes for everyone,
   * then the tiles change and any reinforcements come out.
   */
  updateArena(dt) {
    this.arenaFor(this.w.boss, dt);
    // (the Siege's Warlord has a war camp of his own, besides any realm event)
    if (this.siege && this.siege.e !== this.w.boss) this.arenaFor(this.siege.e, dt);
  }

  arenaFor(b, dt) {
    if (!b || b.dead || !b.arena) return;
    if (b.spPend) {
      b.spPend.t -= dt;
      if (b.spPend.t > 0) return;
      const k = b.spPend.k;
      b.spPend = null;
      const ph = SetPieces.phasesOf(b.defId)[k];
      const sel = SetPieces.applyPhase(this.w, b.defId, b.arena, k);
      this.all({ t: 'sphase', id: b.id, k, go: 1 });
      if (ph && ph.spawn) for (const sp of SetPieces.spawnSpots(sel, ph.n)) this.spawn(ph.spawn, sp.x, sp.y, b.zone, true);
      return;
    }
    const k = SetPieces.trigger(b, b.spMask);
    if (k < 0) return;
    b.spMask |= 1 << k;
    b.spPend = { k, t: SetPieces.WARN };
    this.all({ t: 'sphase', id: b.id, k, w: SetPieces.WARN });
  }

  /** Monsters caught inside a set piece's new walls or decorations are moved to open ground nearby. */
  unstick(cells) {
    const w = this.w;
    for (const e of this.enemies) {
      if (e.dead || e.def.prop || w.canStand(e.x, e.y, Math.min(0.45, e.def.r || 0.45), true)) continue;
      if (!cells.some((k) => Math.abs(k.x + 0.5 - e.x) < 2 && Math.abs(k.y + 0.5 - e.y) < 2)) continue;
      for (let r = 1; r <= 6; r++) {
        let done = false;
        for (let a = 0; a < 8 && !done; a++) {
          const nx = e.x + Math.cos(a * Math.PI / 4) * r, ny = e.y + Math.sin(a * Math.PI / 4) * r;
          if (w.canStand(nx, ny, 0.45, true)) { e.x = nx; e.y = ny; done = true; }
        }
        if (done) break;
      }
    }
  }

  updateGoblin(dt) {
    for (let i = this.enemies.length - 1; i >= 0; i--) {
      const g = this.enemies[i];
      if (!g.def.goblin || g.dead) continue;
      g.age += dt;
      if (g.age > 30) { this.enemies.splice(i, 1); this.byId.delete(g.id); this.all({ t: 'edel', id: g.id }); }
      return;
    }
    if (this.closeT > 0) return;
    this.goblinT -= dt;
    if (this.goblinT > 0) return;
    this.goblinT = 150 + Math.random() * 150;
    const spots = [...this.players.values()];
    const who = spots[Math.floor(Math.random() * spots.length)];
    for (let tries = 0; tries < 20; tries++) {
      const a = Math.random() * Math.PI * 2, r = 9 + Math.random() * 4;
      const gx = who.x + Math.cos(a) * r, gy = who.y + Math.sin(a) * r;
      const z = this.w.zoneAt(gx, gy);
      if (z < World.LOW_ZONE || z > World.GOD_ZONE || !this.w.canStand(gx, gy, 0.4, true)) continue;
      const gob = this.spawn('loot_goblin', gx, gy, z);
      if (gob) gob.maxHp = gob.hp = 800 + z * 900;
      return;
    }
  }

  makeElite(e, id) {
    id = id || ELITES[Math.floor(Math.random() * ELITES.length)];
    e.elite = id;
    e.maxHp *= 2.5;
    if (id === 'Swift') e.spdMult = 1.7;
    else if (id === 'Armored') { e.defense += 15; e.maxHp *= 1.4; }
    else if (id === 'Frenzied') { e.dmgMult *= 1.4; e.spdMult = 1.25; }
    else if (id === 'Giant') { e.maxHp *= 2; e.dmgMult *= 1.2; }
    e.hp = e.maxHp;
  }

  /** Endgame bosses: +80% health for each extra player here (only ever goes up). */
  /**
   * Bosses get tougher with every player fighting them: those within 24 tiles,
   * or who have hit it. Endgame bosses (raids, finales, hard dungeons, the Dark
   * Elder) +75% health per extra player, the rest +50% (counting up to 20).
   * Health only goes up and keeps its percentage, so leaving mid-fight doesn't help.
   */
  scaleBosses(dt) {
    this.scaleT -= dt;
    if (this.scaleT > 0) return;
    this.scaleT = 1;
    for (const e of this.enemies) {
      if (e.dead || !e.isBoss || !e.def.scales) continue;
      let n = 0;
      for (const c of this.players.values()) {
        const dx = c.x - e.x, dy = c.y - e.y;
        if (dx * dx + dy * dy < 24 * 24 || (e.hitters && e.hitters.get(c.id) > 0)) n++;
      }
      n = Math.max(1, Math.min(20, n));
      const d = e.def, endgame = d.raid || d.finale || d.final || d.siege || d.dtier >= 5;
      const mult = 1 + (endgame ? 0.75 : 0.5) * (n - 1);
      if (mult <= e.scaleMult + 0.01) continue;
      const frac = e.hp / e.maxHp;
      e.maxHp = e.maxHp / e.scaleMult * mult;
      e.hp = frac * e.maxHp;
      e.scaleMult = mult;
      e.scalePlayers = n;
      this.all({ t: 'emax', id: e.id, m: Math.ceil(e.maxHp), h: Math.ceil(e.hp), n });
    }
  }

  updateRaid(dt) {
    const w = this.w, rd = w.raid;
    if (w.raidStage >= rd.stages.length) return;
    if (w.raidStage >= 0 && this.enemies.some((e) => !e.dead && e.isBoss)) return;
    w.raidT -= dt;
    if (w.raidT > 0) return;
    if (w.raidStage === rd.stages.length - 1) { w.raidStage++; return; }
    w.raidStage++;
    w.raidT = 2;
    const n = w.raidStage;
    const st = rd.stages[n], spots = w.stageSpots[n] || [];
    for (let k = 0; k < st.length; k++) {
      const at = spots[k] || spots[0] || [100.5, 100.5];
      const b = this.spawn(st[k], at[0], at[1], World.DUNGEON_ZONE, true);
      if (b && k === 0) w.boss = b;
      if (b && this.heroic) Bosses.heroicEnemy(b, true);
      if (b && this.twist) {
        Bosses.twistEnemy(b, this.twist, true);
        // Honour Guard: guards at the master's side
        const th = rd.theme;
        for (let g = 0; g < (this.twist.escort || 0); g++) {
          const a = g * Math.PI * 2 / this.twist.escort;
          const ge = this.spawn(th.mobs[g % th.mobs.length], at[0] + Math.cos(a) * 4, at[1] + Math.sin(a) * 4, th.tier, true);
          if (!ge) continue;
          ge.maxHp *= th.hard; ge.hp = ge.maxHp; ge.dmgMult = 1 + (th.hard - 1) * 0.6;
          Bosses.twistEnemy(ge, this.twist, false);
          if (this.heroic) Bosses.heroicEnemy(ge, false);
        }
      }
      if (n === 0 && k === 0) w.raidStart = Date.now();
      // a chamber master raises its set piece (structure, then its wards, menders or hazards)
      if (b && b.def.setpiece) {
        // (in the Starfall Vault the master first remakes the whole dungeon in its style)
        if (rd.takeover) SetPieces.applyTakeover(w, SetPieces.takeover(st[k], w, Math.floor(at[0]) + 0.5, Math.floor(at[1]) + 0.5));
        const cells = SetPieces.plan(st[k], w, Math.floor(at[0]), Math.floor(at[1]));
        SetPieces.apply(w, cells);
        b.arena = cells;
        this.unstick(cells);
        b.props = [];
        for (const sp of Bosses.setPieceSpots(st[k], at[0], at[1], w)) {
          const pr = this.spawn(sp.what, sp.x, sp.y, World.DUNGEON_ZONE, true);
          if (pr) b.props.push(pr);
        }
      }
    }
    for (let k = 0; k < n; k++) w.openGate(k);
    this.all({ t: 'rstage', n });
  }

  // ------------------------------------------------------------ deaths (were Game.killEnemy's host parts)
  kill(e) {
    if (e.dead) return;
    e.dead = true;
    const w = this.w;
    this.all({ t: 'ekill', id: e.id });
    // what each player who hit it could earn from it (gold and fame checks)
    // (players close by who didn't hit it share its XP, so its fame, but not its gold)
    if (this.onEarn) {
      const hit = new Set();
      for (const h of e.hitters || []) if (h[1] > 0) { const c = this.players.get(h[0]); if (c) { hit.add(c); this.onEarn(c, e, false); } }
      for (const c of this.players.values()) {
        if (hit.has(c)) continue;
        const dx = c.x - e.x, dy = c.y - e.y;
        if (dx * dx + dy * dy < 16 * 16) this.onEarn(c, e, true);
      }
    }
    this.questKill(e);
    this.dropLoot(e);
    if (e.def.crate && Math.random() < 0.12) {
      const m = this.spawn('mimic', e.x, e.y, e.zone, true);
      if (m) m.maxHp = m.hp = 1200 + Math.max(0, e.zone) * 900;
    }
    // slimes burst into smaller slimes
    if (e.def.splits) {
      const sp = e.def.splits;
      for (let k = 0; k < sp.n; k++) { const a = k * Math.PI * 2 / sp.n + Math.random(); this.spawn(sp.what, e.x + Math.cos(a) * 0.8, e.y + Math.sin(a) * 0.8, e.zone); }
    }
    if (e.elite === 'Splitting') {
      for (let k = 0; k < 3; k++) {
        const a = k * Math.PI * 2 / 3, sp = this.spawn(e.defId, e.x + Math.cos(a) * 1.2, e.y + Math.sin(a) * 1.2, e.zone);
        // (the Abyss's splitters split into smaller ones)
        if (sp && this.deep) { sp.maxHp *= 0.35; sp.hp = sp.maxHp; }
      }
    }
    if (e.def.crystal && w.boss && w.boss.invuln && !this.enemies.some((o) => !o.dead && o.def.crystal)) w.boss.invuln = false;
    if (e.site) { e.site.cleared = true; e.site.active = false; if (this.kind === 'realm') w.eventT -= 8; }
    if (e.isBoss) {
      if (w.boss === e) w.boss = null;
      // the boss's arena goes with it
      if (e.props) for (const pr of e.props) if (!pr.dead) { pr.dead = true; this.all({ t: 'edel', id: pr.id }); }
      if (e.arena) { SetPieces.undo(w, e.arena); e.arena = null; }
      // (the Abyss borrows these bosses but not their dungeons' rules)
      if (this.deep) { /* nothing */ }
      else if (e.def.guardian) this.guardianDown();
      else if (e.def.trio && this.enemies.some((o) => !o.dead && o.def.trio)) this.kingDown();
      else if (e.def.siege) this.siegeDown(e);
      else if (this.kind === 'realm' && !e.def.dungeon && !e.def.raid && !e.def.final) {
        w.eventsDone++;
        if (this.onEventKill && e.firstHit && e.def.setpiece) {
          // who fought it, most damage first
          const team = [...(e.hitters || [])].filter((h) => h[1] > 0).sort((a, b) => b[1] - a[1]).map((h) => this.players.get(h[0])).filter(Boolean);
          if (team.length) this.onEventKill(e.defId, Date.now() - e.firstHit, team);
        }
        w.eventT = 20 + Math.random() * 10;
        if (Math.random() < Data.DUNGEON_DROP_CHANCE) {
          let di = Math.floor(Math.random() * Data.EVENT_DUNGEONS);
          if (e.def.hardDungeon && Math.random() < 0.35) di = Data.dungeonIndex(e.def.hardDungeon);
          this.portal(e.x + 1.5, e.y, 'dungeon', di, Data.DUNGEONS[di].color);
        }
        if (w.eventsDone >= Data.EVENTS_PER_REALM) {
          this.closeT = 15;
          // everyone here is about to be pulled into the realm's finale: its way in is open
          if (this.onPortal) this.onPortal(this.finaleKey());
        }
      }
    } else if (this.kind === 'realm' && !(w.boss && !w.boss.dead) && e.def.drop > 0) {
      w.eventT -= 1.2;
    }
    if (this.kind === 'realm' && e.def.portal && Math.random() < e.def.portalChance) {
      const pi = Data.dungeonIndex(e.def.portal);
      if (pi >= 0) this.portal(e.x, e.y, 'dungeon', pi, Data.DUNGEONS[pi].color);
    }
  }

  /**
   * Tells the quest keeper what this kill counts for, for everyone who hurt it:
   * kills, godkills, elites, pieces (set pieces), events and event:<id> (realm
   * event bosses), fastevent (under 90 seconds), partyevent (2+ players),
   * dungeon (a dungeon's last boss) and elder.
   */
  questKill(e) {
    if (!this.onQuest) return;
    const team = [...(e.hitters || [])].filter((h) => h[1] > 0).map((h) => this.players.get(h[0])).filter(Boolean);
    if (!team.length) return;
    const evs = [];
    if (e.def.prop) evs.push('pieces');
    else if (!e.def.crate) {
      evs.push('kills');
      if (this.kind === 'realm' && e.zone === World.GOD_ZONE) evs.push('godkills');
    }
    if (e.elite) evs.push('elites');
    if (e.isBoss) {
      if (e.def.final) evs.push('darkelder');
      // a raid's last boss (titles)
      if (this.kind === 'raid' && this.w.raidStage === this.w.raid.stages.length - 1 &&
        !this.enemies.some((o) => o !== e && !o.dead && o.isBoss)) evs.push('raid:' + this.w.raid.id);
      if (this.heroic && evs.includes('raid:' + this.w.raid.id)) evs.push('raidh:' + this.w.raid.id);
      if (e.def.final || e.def.finale) evs.push('elder');
      else if (this.kind === 'dg' && e.def.dungeon && !e.def.guardian && !(e.def.trio && this.enemies.some((o) => o !== e && !o.dead && o.def.trio))) evs.push('dungeon');
      else if (this.kind === 'realm' && e.def.setpiece) {
        evs.push('events', 'event:' + e.defId);
        if (e.firstHit && Date.now() - e.firstHit < 90000) evs.push('fastevent');
        if (team.length >= 2) evs.push('partyevent');
      }
    }
    for (const c of team) this.onQuest(c, evs);
    // big moments for the Discord feed
    if (this.onFeat) {
      const names = team.map((c) => c.name).filter(Boolean);
      if (evs.includes('darkelder')) this.onFeat('elder', { names });
      const rd = evs.find((v) => v.startsWith('raid:'));
      if (rd) this.onFeat('raid', { names, raid: this.w.raid.name, boss: e.def.name, color: this.w.raid.color,
        ms: this.w.raidStart ? Date.now() - this.w.raidStart : 0, week: this.week, twist: this.twist ? this.twist.name : '', team,
        id: this.w.raid.id, heroic: !!this.heroic });
    }
  }

  /** Everyone who hurt the monster gets their own roll (sent only to them). */
  dropLoot(e) {
    const zone = Math.max(0, Math.min(World.GOD_ZONE, e.zone));
    const siteHoard = e.site && !e.site.cleared;
    // the Siege: loot follows your share of the fight (under 0.5%, nothing); the MVP rolls twice
    let total = 0, mvp = null;
    // (the MVP is the top damage dealer still here: the same one siegeDown names)
    if (e.def.siege) for (const [cid, dmg] of e.hitters || []) { total += Math.max(0, dmg); if (this.players.has(cid) && (!mvp || dmg > e.hitters.get(mvp))) mvp = cid; }
    // a raid's final boss (its last stage, nothing else of it left standing)
    const raidEnd = this.kind === 'raid' && e.isBoss && this.w.raidStage === this.w.raid.stages.length - 1 &&
      !this.enemies.some((o) => o !== e && !o.dead && o.isBoss);
    for (const [cid, dmg] of e.hitters || []) {
      const c = this.players.get(cid);
      if (!c || dmg <= 0) continue;
      const share = total ? dmg / total : 0;
      if (e.def.siege && share < 0.005) continue;
      const prof = c.profile || {};
      const cls = Data.CLASSES[prof.cls] || Data.CLASSES.wizard;
      // (Ironman and Hardcore heroes get extra luck on top: see modes.js)
      // (VIPs find a little more: VIP_LUCK in server.js)
      const lk = (this.deep ? Data.deepBoonLuck(c.abyss ? c.abyss.boons : null) : 0) + Math.max(0, Math.min(160, prof.lk | 0)) + (c.mode ? Data.findMode(c.mode).luck | 0 : 0) + (c.vip ? 15 : 0) + (c.ascLuck | 0) + (c.guild && WorldSim.guildLuck ? WorldSim.guildLuck[c.guild] | 0 : 0);
      // a heroic raid's bosses drop better
      const hl = this.heroic && e.def.raid ? Bosses.HEROIC.luck : 0;
      let items = Data.rollLoot(e.def, zone, cls, lk + hl);
      if (e.elite) items = items.concat(Data.rollLoot(e.def, zone, cls, lk + 50));
      // a raid's final boss: the first clear of the week (on this difficulty) rolls again, luckier
      let first = false;
      if (raidEnd && this.firstClear && this.firstClear(c, this.w.raid.id + (this.heroic ? ':h' : ''), this.week)) {
        first = true;
        items = items.concat(Data.rollLoot(e.def, zone, cls, lk + hl + 120));
      }
      if (e.def.goblin) items = items.concat(goblinLoot(zone, cls, lk));
      if (e.def.crate && Math.random() < 0.45) items.push(Math.random() < 0.67 ? Data.makePotion(Math.random() < 0.5 ? 'hp' : 'mp') : Data.makePotion('stat', Data.randomStat()));
      if (e.def.mimic) items = items.concat(mimicLoot(cls));
      if (siteHoard) items = items.concat(Data.rollLoot(e.def, zone, cls, lk));
      if (e.def.siege) {
        items = items.concat(Data.rollLoot(e.def, zone, cls, lk + Math.min(80, Math.round(share * 300))));
        if (cid === mvp) items = items.concat(Data.rollLoot(e.def, zone, cls, lk + 120));
      }
      // High Stakes (a skill): the drop is doubled or lost on a coin flip
      let hs = '';
      if (items.length && prof.hs) {
        if (Math.random() < 0.5) { items = items.concat(items.map((it) => JSON.parse(JSON.stringify(it)))); hs = 'won'; }
        else { items = []; hs = 'lost'; }
      }
      // the Endless Abyss: its monsters drop nothing, only its chests do
      if (this.deep && !e.def.abyssChest) { items = []; hs = ''; }
      if (this.issuer) for (const it of items) this.issuer(c, it);
      // the Oracle counts every boss kill and what it dropped for you (and the Abyss's chests)
      if (this.onOracle && (e.isBoss || e.def.abyssChest)) this.onOracle(c, e, items);
      if (this.onFeat) for (const it of items) if (it && (it.rarity === 'gd' || it.rarity === 'ar')) this.onFeat(it.rarity === 'gd' ? 'godly' : 'primordial', { name: c.name, item: it.name, from: e.def.name });
      if (first) this.send(c, { t: 'msg', color: 0xffd75e, text: 'Your first ' + Bosses.raidName(Bosses.RAIDS.indexOf(this.w.raid), this.heroic) + ' clear this week: a bonus roll of its loot!' });
      if (items.length || hs) this.send(c, { t: 'loot', id: e.id, x: r2(e.x), y: r2(e.y), l: items, n: e.def.name, hs });
    }
  }

  // ------------------------------------------------------------ the Endless Abyss
  /** Waves: a short break, then a wave (a boss every 5th); once it's all down the next break, and a chest every 5. */
  updateWaves(dt) {
    const d = this.deep;
    if (!this.players.size) return;
    if (d.state === 'break') {
      d.t -= dt;
      if (d.t <= 0) this.startWave(d.wave + 1);
      return;
    }
    d.fightT += dt;
    // Reinforcements: the rest of the wave comes in pulses
    if (d.pulses && d.pulses.length && d.fightT >= d.pulses[0].at) this.waveSpawn(d.pulses.shift().n, d.mods);
    // a wave left too long: the Abyss grows restless and sends elites, more and more often
    if (d.fightT > Data.DEEP_RESTLESS) {
      d.restT -= dt;
      if (d.restT <= 0) {
        if (!d.restless) {
          d.restless = true;
          for (const c of this.players.values()) c.send({ t: 'deepWave', wave: d.wave, state: 'restless', left: d.left });
        }
        d.restT = Math.max(4, 10 - (d.fightT - Data.DEEP_RESTLESS) / 10);
        // (never more than so many alive at once: a group that can't keep up isn't buried, and the server isn't either)
        const alive = this.enemies.filter((e) => !e.dead && !e.def.abyssChest).length;
        const room = 40 + 10 * this.players.size - alive;
        if (room > 0) this.waveSpawn(Math.min(room, 2 + Math.floor(d.wave / 8)), ['ambush'], true);
      }
    }
    const left = this.enemies.filter((e) => !e.dead && !e.def.abyssChest).length;
    if (left !== d.left) { d.left = left; this.waveStatus(); }
    if (!left && !(d.pulses && d.pulses.length)) this.waveCleared();
  }

  /** Where a wave monster appears: away from the players, or (Ambush) right beside one. */
  waveSpot(ambush) {
    const w = this.w, ps = [...this.players.values()];
    for (let k = 0; k < 80; k++) {
      let x, y;
      if (ambush && ps.length) {
        const c = ps[Math.floor(Math.random() * ps.length)], a = Math.random() * Math.PI * 2, r = 3 + Math.random() * 3;
        x = Math.floor(c.x + Math.cos(a) * r) + 0.5; y = Math.floor(c.y + Math.sin(a) * r) + 0.5;
      } else {
        // anywhere on the platform, away from the dais
        const a = Math.random() * Math.PI * 2, r = 5 + Math.random() * 10.5;
        x = Math.floor(100.5 + Math.cos(a) * r) + 0.5; y = Math.floor(100.5 + Math.sin(a) * r) + 0.5;
      }
      if (!w.canStand(x, y, 0.5, true)) continue;
      if (!ambush) {
        let near = false;
        for (const c of ps) if ((c.x - x) * (c.x - x) + (c.y - y) * (c.y - y) < 49) near = true;
        if (near) continue;
      }
      return [x, y];
    }
    return [100.5, 90.5];
  }

  /** n monsters of this wave, with its modifiers (allElite: the restless Abyss's elites). */
  waveSpawn(n, mods, allElite) {
    const d = this.deep, pool = Data.deepMobs(d.wave);
    const has = (m) => mods.includes(m);
    const eliteP = allElite ? 1 : Data.deepEliteChance(d.wave) + (has('elite') ? 0.35 : 0);
    for (let k = 0; k < n; k++) {
      const p = this.waveSpot(has('ambush'));
      const e = this.spawn(pool[Math.floor(Math.random() * pool.length)], p[0], p[1], World.ARENA_ZONE, true);
      if (!e) continue;
      if (has('giants')) this.makeElite(e, 'Giant');
      else if (Math.random() < eliteP) this.makeElite(e);
      if (has('swarm')) { e.maxHp *= 0.55; e.hp = e.maxHp; }
      if (has('frenzy')) { e.dmgMult *= 1.3; e.spdMult = (e.spdMult || 1) * 1.35; }
      if (has('blood') && !e.elite) e.elite = 'Vampiric';
      if (has('split') && !e.elite) e.elite = 'Splitting';
    }
  }

  startWave(n) {
    const d = this.deep, w = this.w;
    d.wave = n;
    d.state = 'fight';
    d.fightT = 0; d.restT = 0; d.restless = false;
    // this wave's modifiers
    const ids = Data.DEEP_MODS.map((m) => m.id).sort(() => Math.random() - 0.5);
    const mods = [];
    // (Juggernauts and Swarm pull against each other: never both)
    for (const id of ids) {
      if (mods.length >= Data.deepModCount(n)) break;
      if ((id === 'swarm' && mods.includes('giants')) || (id === 'giants' && mods.includes('swarm'))) continue;
      mods.push(id);
    }
    d.mods = mods;
    let count = Data.deepCount(n, this.players.size);
    if (mods.includes('swarm')) count = Math.round(count * 1.8);
    if (mods.includes('giants')) count = Math.max(2, Math.round(count * 0.4));
    if (mods.includes('split')) count = Math.max(2, Math.round(count * 0.6));
    d.pulses = [];
    if (mods.includes('reinforce')) {
      const part = Math.ceil(count / 3);
      d.pulses = [{ at: 10, n: part }, { at: 20, n: part }];
      count -= part * 2;
    }
    this.waveSpawn(count, mods);
    // the bosses (the Herald on every 10th), with elite escorts from wave 20
    const bosses = Data.deepBosses(n);
    for (let i = 0; i < bosses.length; i++) {
      const b = new Enemy(bosses[i], bosses.length > 1 ? (i ? 106.5 : 94.5) : 100.5, 92.5, World.ARENA_ZONE);
      this.add(b);
      if (!b.def.scales && this.players.size > 1) { b.maxHp *= 1 + 0.6 * (this.players.size - 1); b.hp = b.maxHp; }
      if (mods.includes('frenzy')) b.dmgMult *= 1.15;
      if (i === 0) w.boss = b;
    }
    if (bosses.length && n >= 20) this.waveSpawn(2, mods, true);
    d.left = this.enemies.filter((e) => !e.dead && !e.def.abyssChest).length;
    const names = bosses.map((b) => Data.ENEMIES[b].name).join(' & ');
    for (const c of this.players.values()) c.send({ t: 'deepWave', wave: n, state: 'fight', left: d.left, boss: names, mods });
  }

  waveStatus() {
    const d = this.deep;
    for (const c of this.players.values()) c.send({ t: 'deepWave', wave: d.wave, state: d.state, left: d.left, secs: Math.ceil(d.t) });
  }

  /** Wave cleared: a breather; every 5th a chest (better the further you got) and a boon for everyone. */
  waveCleared() {
    const d = this.deep, n = d.wave;
    const chest = n % Data.DEEP_CHEST_EVERY === 0;
    d.state = 'break';
    d.t = chest ? 15 : 6;
    if (chest) this.spawn('abyss_chest_' + Data.deepChestTier(n), 100.5, 100.5, World.ARENA_ZONE, true);
    for (const c of this.players.values()) c.send({ t: 'deepWave', wave: n, state: 'cleared', secs: d.t, chest: chest ? Data.DEEP_CHEST_NAMES[Data.deepChestTier(n)] : '' });
    if (this.onDeep) this.onDeep(this, [...this.players.values()], n, chest);
  }

  // ------------------------------------------------------------ the Realm Siege
  /** The Warlord marches into this realm's Godlands (server.js decides when). False if there's no room. */
  startSiege() {
    const w = this.w;
    // (not while a realm event boss is up or the realm is about to close: its finale would cut the siege short)
    if (this.kind !== 'realm' || this.siege || w.closed || this.closeT > 0 || (w.boss && !w.boss.dead) || w.eventsDone >= Data.EVENTS_PER_REALM - 1) return false;
    for (let tries = 0; tries < 1500; tries++) {
      const x = Math.floor(w.N / 2 + (Math.random() - 0.5) * w.N * 0.5) + 0.5, y = Math.floor(w.N / 2 + (Math.random() - 0.5) * w.N * 0.5) + 0.5;
      if (w.zoneAt(x, y) !== World.GOD_ZONE || !w.canStand(x, y, 1.2, true)) continue;
      // (his war camp has to fit: the later tries settle for less)
      if (tries < 1200 && !SetPieces.fits('siege_warlord', w, Math.floor(x), Math.floor(y))) continue;
      // the camp rises first, so he and his ballistas stand on it
      const cells = SetPieces.plan('siege_warlord', w, Math.floor(x), Math.floor(y));
      SetPieces.apply(w, cells);
      const e = new Enemy('siege_warlord', x, y, World.GOD_ZONE);
      e.arena = cells;
      this.add(e);
      this.unstick(cells);
      e.props = [];
      for (const sp of Bosses.setPieceSpots('siege_warlord', x, y, w)) {
        const pr = this.spawn(sp.what, sp.x, sp.y, World.GOD_ZONE, true);
        if (pr) e.props.push(pr);
      }
      this.siege = { e, left: SIEGE_TIME, waveT: 20, sendT: 0 };
      this.siegeSoldiers(4);
      this.siegeStatus(true);
      return true;
    }
    return false;
  }

  /** Soldiers march out around the Warlord (never more than 10 at once). */
  siegeSoldiers(n) {
    const e = this.siege.e;
    const alive = this.enemies.filter((o) => !o.dead && o.defId === 'siege_soldier').length;
    for (let k = 0; k < Math.min(n, 10 - alive); k++) {
      const a = Math.random() * Math.PI * 2, r = 3 + Math.random() * 3;
      this.spawn('siege_soldier', e.x + Math.cos(a) * r, e.y + Math.sin(a) * r, World.GOD_ZONE);
    }
  }

  updateSiege(dt) {
    const sg = this.siege, e = sg.e;
    // (the Warlord gone without a kill, e.g. an error, or the realm closing under it: the siege fails)
    if (e.dead && !this.byId.has(e.id)) { this.siegeFail(); return; }
    if (e.dead) return;
    if (this.closeT > 0 || this.w.closed) { this.siegeFail(); return; }
    sg.left -= dt;
    sg.waveT -= dt;
    if (sg.waveT <= 0) { sg.waveT = 25; this.siegeSoldiers(2 + Math.min(6, (e.scalePlayers || 1))); }
    if (sg.left <= 0) { this.siegeFail(); return; }
    sg.sendT -= dt;
    if (sg.sendT <= 0) { sg.sendT = 2; this.siegeStatus(false); }
  }

  /** Time's up (or the siege can't go on): he marches away, and his soldiers with him. */
  siegeFail() {
    const e = this.siege.e;
    for (const o of this.enemies) if (!o.dead && (o === e || o.defId === 'siege_soldier' || o.defId === 'siege_ballista')) { o.dead = true; this.all({ t: 'edel', id: o.id }); }
    // (his camp comes down with him)
    if (e.arena) { SetPieces.undo(this.w, e.arena); e.arena = null; }
    this.siege = null;
    for (const c of this.players.values()) c.send({ t: 'siege', on: false, lost: true });
    if (this.onSiege) this.onSiege(this, 'fail', { name: e.def.name });
  }

  /** Who's done what so far, most damage first: [[client, damage], ...] and the total. */
  siegeBoard() {
    const e = this.siege.e;
    let total = 0;
    const rows = [];
    for (const [cid, dmg] of e.hitters || []) { if (dmg <= 0) continue; total += dmg; rows.push([cid, dmg]); }
    rows.sort((a, b) => b[1] - a[1]);
    return { rows, total };
  }

  /** The siege panel for everyone in the realm: his health, the time left, the top three and your own share. */
  siegeStatus(start) {
    const sg = this.siege, e = sg.e;
    const { rows, total } = this.siegeBoard();
    const top = rows.slice(0, 3).map((r) => { const c = this.players.get(r[0]); return [c ? c.name : '?', Math.round(r[1] / total * 1000) / 10]; });
    for (const c of this.players.values()) {
      const i = rows.findIndex((r) => r[0] === c.id);
      c.send({ t: 'siege', on: true, start: !!start, id: e.id, name: e.def.name, hp: Math.ceil(e.hp), max: Math.ceil(e.maxHp), left: Math.ceil(sg.left),
        x: r2(e.x), y: r2(e.y), top, me: i >= 0 ? Math.round(rows[i][1] / total * 1000) / 10 : 0, rank: i + 1, n: rows.length });
    }
  }

  siegeDown(e) {
    const { rows, total } = this.siegeBoard();
    this.siege = null;
    for (const o of this.enemies) if (!o.dead && o.defId === 'siege_soldier') { o.dead = true; this.all({ t: 'edel', id: o.id }); }
    const team = rows.map((r) => ({ c: this.players.get(r[0]), pct: Math.round(r[1] / total * 1000) / 10 })).filter((r) => r.c);
    for (const c of this.players.values()) c.send({ t: 'siege', on: false, won: true, mvp: team.length ? team[0].c.name : '', top: team.slice(0, 3).map((r) => [r.c.name, r.pct]) });
    if (this.onSiege) this.onSiege(this, 'win', { name: e.def.name, team });
  }

  guardianDown() {
    if (this.enemies.some((o) => !o.dead && o.def.guardian)) return;
    for (const s of this.enemies) {
      if (s.dead || !s.def.sealed) continue;
      s.invuln = false;
      this.w.boss = s;
    }
  }

  kingDown() {
    for (const k of this.enemies) {
      if (k.dead || !k.def.trio) continue;
      k.dmgMult *= 1.25;
      k.hp = Math.min(k.maxHp, k.hp + k.maxHp * 0.15);
      if (!this.w.boss || this.w.boss.dead) this.w.boss = k;
    }
  }
}

/** The treasure goblin's sack (was Game.goblinLoot). */
function goblinLoot(zone, cls, lk) {
  const out = [Data.makeForSlot(cls, Math.floor(Math.random() * 4), 7, 'ut'), Data.makePotion('stat', Data.randomStat()), Data.makePotion('stat', Data.randomStat())];
  if (Math.random() < 0.12) out.push(Data.makeSor());
  if (Math.random() < 0.25) out.push(Data.makeForSlot(cls, Math.floor(Math.random() * 4), 7, Math.random() < 0.85 ? 'st' : 'fb'));
  return out.concat(Data.rollLoot(Data.ENEMIES.loot_goblin, zone, cls, lk + 40));
}

/** A mimic's insides (was Game.mimicLoot). */
function mimicLoot(cls) {
  const out = [Data.makePotion('stat', Data.randomStat())];
  if (Math.random() < 0.4) out.push(Data.makeForSlot(cls, Math.floor(Math.random() * 4), 7, 'ut'));
  if (Math.random() < 0.06) out.push(Data.makeSor());
  return out;
}

/** All running simulations, ticked together. */
class Sims {
  constructor() {
    this.map = new Map();
    this.timer = setInterval(() => this.tick(), TICK * 1000);
    this.timer.unref && this.timer.unref();
  }

  get(key) { return this.map.get(key); }

  /** Hands a new world the server's hooks. */
  wire(s) {
    for (const k of ['issuer', 'onEventKill', 'onQuest', 'onEarn', 'onFeat', 'onPortal', 'onOracle', 'onSiege', 'onDeep', 'firstClear']) s[k] = this[k];
  }

  join(key, c) {
    if (!WorldSim.simulates(key)) return null;
    let s = this.map.get(key);
    if (!s) {
      try { s = new WorldSim(key); this.wire(s); } catch (e) { console.error('could not start world', key, e.message); return null; }
      this.map.set(key, s);
    }
    s.join(c);
    return s;
  }

  /** Realms in the Nexus list: built ahead of time and kept even while empty. */
  keepOnly(keys) {
    const want = new Set(keys);
    for (const s of this.map.values()) if (s.kind === 'realm') s.keep = want.has(s.key);
    for (const key of want) {
      if (this.map.has(key)) continue;
      try { const s = new WorldSim(key); s.keep = true; this.wire(s); this.map.set(key, s); } catch (e) { console.error('could not start world', key, e.message); }
    }
  }

  leave(key, c) {
    const s = this.map.get(key);
    if (s) s.leave(c);
  }

  tick() {
    const t0 = Date.now();
    for (const [key, s] of this.map) {
      try { s.tick(TICK); } catch (e) { console.error('world', key, e.stack); }
      // empty dungeons end after a minute, empty realms after ten
      if (!s.players.size && !s.keep && s.emptyFor > (s.kind === 'realm' ? 600 : 60)) this.map.delete(key);
    }
    this.lastMs = Date.now() - t0;
    // the last minute of tick times (the budget is 50 ms a tick)
    if (!this.hist) this.hist = [];
    this.hist.push(this.lastMs);
    if (this.hist.length > 1200) this.hist.shift();
  }

  stats() {
    let monsters = 0;
    for (const s of this.map.values()) monsters += s.enemies.length;
    const h = (this.hist || []).slice().sort((a, b) => a - b);
    const avg = h.length ? h.reduce((n, v) => n + v, 0) / h.length : 0;
    return { worlds: this.map.size, monsters, tickMs: this.lastMs || 0, avgMs: Math.round(avg * 10) / 10,
      p99Ms: h.length ? h[Math.min(h.length - 1, Math.floor(h.length * 0.99))] : 0, maxMs: h.length ? h[h.length - 1] : 0 };
  }
}

/** Loot luck from each guild's Godlands Spires (server.js, territory.js). */
WorldSim.guildLuck = {};
/** Set by the server in the last minutes before a restart. */
WorldSim.restartSoon = false;

module.exports = { MAX_DPS, DPS_BURST, WorldSim, Sims };
