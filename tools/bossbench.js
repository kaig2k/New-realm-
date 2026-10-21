'use strict';
/*
 * Boss benchmark: bots fight every boss in the server's own simulation and report how
 * long each fight takes, how much it hurts, and how varied it is.
 *
 *   node tools/bossbench.js [--only id,id] [--cls archer] [--runs 3] [--json out.json]
 *
 * Each fight runs the real boss scripts (server/sim/gen/game.js) in its real world (realm
 * event with its set piece, dungeon room, raid stage, the Dark Elder's chamber). The world
 * shim here also runs what the server normally leaves to players' games: delayed volleys,
 * telegraphed blasts (markers) and blood brands, so every attack happens.
 *
 * The bots: a hero of the given class with the gear a player would have by then (see GEAR),
 * shooting the boss (or the wards, altars and rods that shield it) with ~85% of shots landing,
 * and dodging: each tick it tries 16 directions and standing still, plays every bullet and
 * pending blast forward 0.6s, and takes the safest spot that keeps it at its weapon's range.
 * It reacts a little late (0.12s) and isn't perfect, like a decent player.
 *
 * A second run with a bot that stands still and only shoots shows how much of the fight is
 * dodging: if standing still is safe, the fight asks nothing of you.
 */
const path = require('path');
const { Data, Bosses, World, Enemy, SetPieces } = require(path.join(__dirname, '..', 'server', 'sim', 'gen', 'game'));
const { WorldSim } = require(path.join(__dirname, '..', 'server', 'sim', 'worldsim'));

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf('--' + k); return i >= 0 ? args[i + 1] : d; };
const ONLY = opt('only') ? opt('only').split(',') : null;
const CLS = opt('cls', 'archer');
const RUNS = Number(opt('runs', 2));
const DT = 0.05, MAX_T = Number(opt('max', 420));
const DEBUG = args.indexOf('--debug') >= 0;

// ---------------------------------------------------------------- the heroes
/** Gear and stats by where a boss is met: L = how far through levels 1-20, f = how far to maxed stats. */
const GEAR = {
  starter: { L: 0.4, f: 0, T: 2 },
  early: { L: 0.7, f: 0, T: 3 },
  mid: { L: 1, f: 0, T: 4 },
  dungeon: { L: 1, f: 0.15, T: 5 },
  event: { L: 1, f: 0.3, T: 6 },
  hard: { L: 1, f: 0.6, T: 7 },
  finale: { L: 1, f: 0.8, T: 7, rar: 'fb' },
  raid: { L: 1, f: 1, T: 7, rar: 'lg' }
};

function hero(cls, g) {
  const C = Data.CLASSES[cls];
  const st = {};
  for (const s of Data.STATS) {
    const l20 = C.base[s] + (C.l20[s] - C.base[s]) * g.L;
    st[s] = l20 + Math.max(0, C.max[s] - C.l20[s]) * g.f;
  }
  const w = Data.makeWeapon(C.weapon, g.T, g.rar || null, '');
  const ar = Data.makeArmor(C.armor, g.T, g.rar || null);
  const rg = Data.makeRing('att', Math.min(5, g.T - 1), g.rar || null);
  const add = (k) => (ar[k] || 0) + (rg[k] || 0);
  const att = st.att + add('att'), dex = st.dex + add('dex'), spd = st.spd + add('spd');
  return {
    cls, weapon: w,
    maxHp: Math.round(st.hp + add('hp')), def: Math.round(st.def + add('def')),
    regen: 1 + (st.vit + add('vit')) * 0.12,
    speed: 4 + 5.6 * (spd / 75),
    fireRate: (1.5 + 6.5 * dex / 75) * (w.rate || 1),
    mult: 0.5 + att / 50,
    range: (w.spd || 10) * (w.life || 0.6)
  };
}

/** Damage one volley does to an enemy with this defense (Game.hurtEnemy), times how many shots land. */
function volley(h, def) {
  const w = h.weapon, avg = (w.dmin + w.dmax) / 2 * h.mult;
  return w.shots * Math.max(1, avg - def, Math.floor(avg * 0.15));
}

// ---------------------------------------------------------------- one fight
/**
 * where: how to set the fight up. Returns the world, the bosses to beat, and the gear tier.
 */
function setup(id) {
  const d = Data.ENEMIES[id];
  const evIdx = Data.EVENTS.indexOf(id);
  let sim, targets, tier, group = 1, label = d.name;
  if (evIdx >= 0) {
    const keep = Data.EVENTS;
    Data.EVENTS = [id];
    sim = new WorldSim('realm:Bench:' + (1000 + evIdx * 7));
    sim.updateSpawns = () => {};
    sim.updateGoblin = () => {};
    sim.w.eventT = 0;
    // (it needs a player in the world to start the clock)
    sim.players.set(-1, { id: -1, x: 0, y: 0, send() {}, hidden: true });
    sim.updateEvents(DT);
    sim.players.delete(-1);
    Data.EVENTS = keep;
    const boss = sim.w.boss;
    targets = () => boss && !boss.dead ? [boss].concat((boss.props || []).filter((p) => !p.dead)) : [];
    tier = 'event';
  } else if (id === 'elder') {
    sim = new WorldSim('arena:1');
    targets = () => sim.enemies.filter((e) => !e.dead && (e.isBoss || e.defId === 'elder_crystal'));
    tier = 'finale'; group = 3;
  } else if (id === 'abyss_herald') {
    sim = new WorldSim('deep:1');
    sim.updateWaves = () => {};
    // (it comes on every 10th wave, as tough as that wave: WorldSim.add)
    sim.deep.wave = 10;
    const b = sim.spawn('abyss_herald', 100.5, 96.5, World.ARENA_ZONE || 1, true);
    targets = () => sim.enemies.filter((e) => !e.dead && (e === b || e.def.prop));
    tier = 'finale';
  } else if (id === 'siege_warlord') {
    sim = new WorldSim('realm:Bench:77');
    sim.updateSpawns = () => {}; sim.updateEvents = () => {}; sim.updateGoblin = () => {};
    sim.startSiege();
    targets = () => sim.siege && sim.siege.e && !sim.siege.e.dead ? [sim.siege.e] : [];
    tier = 'raid'; group = 6;
  } else if (d.raid || d.stageFoe) {
    const ri = Bosses.RAIDS.findIndex((r) => r.stages.some((s) => s.indexOf(id) >= 0));
    const rd = Bosses.RAIDS[ri];
    const si = rd.stages.findIndex((s) => s.indexOf(id) >= 0);
    sim = new WorldSim('raid:' + ri + ':4242');
    // clear the mobs and jump straight to this stage
    for (const e of sim.enemies) e.dead = true;
    sim.players.set(-1, { id: -1, x: 100, y: 100, send() {}, hidden: true });
    for (let s = 0; s <= si; s++) {
      sim.w.raidT = 0;
      sim.updateRaid(DT);
      if (s < si) for (const e of sim.enemies) e.dead = true;
      sim.enemies.splice(0, sim.enemies.length, ...sim.enemies.filter((e) => !e.dead));
    }
    sim.players.delete(-1);
    const st = sim.w.raidStage;
    targets = () => sim.w.raidStage === st ? sim.enemies.filter((e) => !e.dead && (e.isBoss || e.def.stageFoe || e.def.prop)) : [];
    tier = 'raid'; group = 4;
    label = rd.name + ' ' + (si + 1) + ': ' + rd.stages[si].map((x) => Data.ENEMIES[x].name).filter((v, i, a) => a.indexOf(v) === i).join(' + ');
  } else {
    const di = Data.DUNGEONS.findIndex((t) => t.boss === id || (t.guardians || []).indexOf(id) >= 0 || (t.trio || []).indexOf(id) >= 0);
    const th = Data.DUNGEONS[di];
    sim = new WorldSim('dg:' + di + ':4242');
    const trio = (th.trio || []).indexOf(id) >= 0;
    const keep = (e) => trio ? th.trio.indexOf(e.defId) >= 0 : e.defId === id;
    for (const e of sim.enemies) if (!keep(e)) e.dead = true;
    sim.enemies.splice(0, sim.enemies.length, ...sim.enemies.filter((e) => !e.dead));
    for (const e of sim.enemies) e.invuln = false;
    targets = () => sim.enemies.filter((e) => !e.dead && (keep(e) || e.def.prop));
    tier = d.dtier === 0 ? 'starter' : d.dtier === 1 ? 'early' : d.dtier === 2 ? 'mid' : d.dtier >= 5 ? (d.finale ? 'finale' : 'hard') : 'dungeon';
    if (d.finale) group = 3;
    if (trio) label = th.name + ' (the three kings)';
  }
  return { sim, targets, tier, group, label };
}

function fight(id, opts) {
  const { sim, targets, tier, group, label } = setup(id);
  const w = sim.w, g = sim.g;
  const n = opts.group ? group : 1;
  const H = hero(CLS, GEAR[tier]);
  const shots = [], timers = [], marks = [];
  const stats = { label, tier, n, hits: 0, dmg: 0, deaths: 0, attacks: new Map(), quiet: 0, windows: 0, area: 0, time: 0, done: false, phases: 0, maxPhase: 0 };
  // ---- the world as the bots see it (what players' games do with a boss's attacks)
  g.addShot = (s) => {
    if (!s.enemy) return;
    s.vx = Math.cos(s.angle) * s.speed; s.vy = Math.sin(s.angle) * s.speed; s.bx = s.x; s.by = s.y; s.age = 0; s.life0 = s.life;
    shots.push(s);
    if (s.attack) bump(stats.attacks, s.attack);
  };
  g.later = (t, fn) => timers.push({ t, fn });
  g.addMarker = (x, y, r, d, col, fn) => marks.push({ x, y, r, t: d, fn });
  g.brand = (who, r, d, col, dmg, src, eff, attack) => { bump(stats.attacks, attack || 'brand'); marks.push({ x: who.x, y: who.y, r, t: d, follow: who, fn: () => brandHit(who, r, dmg, attack || 'blood brand') }); };
  g.areaHit = (x, y, r, dmg, src, eff, col, attack) => { if (attack) bump(stats.attacks, attack); for (const b of bots) if (b.alive && (b.x - x) ** 2 + (b.y - y) ** 2 < r * r) { hurt(b, dmg, attack); stats.area++; } };
  g.eclipse = () => {};
  const bots = [];
  const first = targets()[0];
  if (!first) return null;
  for (let k = 0; k < n; k++) {
    const a = k * Math.PI * 2 / n + 0.4;
    const c = { id: 900 + k, send() {}, hidden: false, caps: null, maxDps: 1e9, hp: H.maxHp, alive: true, deadT: 0, shootT: 0, stand: !!opts.stand, pots: GEAR[tier].T >= 7 ? 6 : 3, potT: 0 };
    place(c, first.x + Math.cos(a) * Math.min(7, H.range * 0.8), first.y + Math.sin(a) * Math.min(7, H.range * 0.8));
    bots.push(c);
    sim.join(c);
  }
  function place(c, x, y) {
    for (let r = 0; r < 8; r += 0.5) for (let a = 0; a < 6.28; a += 0.4) {
      const px = x + Math.cos(a) * r, py = y + Math.sin(a) * r;
      if (w.canStand(px, py, 0.3, false) && !w.isSafe(px, py)) { c.x = px; c.y = py; return; }
    }
    c.x = x; c.y = y;
  }
  function hurt(b, raw, src) {
    const d = Math.max(raw - H.def, Math.floor(raw * 0.15));
    b.hp -= d; stats.dmg += d; stats.hits++;
    stats.by = stats.by || new Map(); stats.by.set(src || '?', (stats.by.get(src || '?') || 0) + d);
    if (b.hp <= 0) { stats.deaths++; b.hp = H.maxHp; } // (it gets right back up: we count, and fight on)
  }
  function brandHit(who, r, dmg, src) {
    for (const b of bots) {
      if (b === who) hurt(b, Math.floor(dmg / 3), src);
      else if ((b.x - who.x) ** 2 + (b.y - who.y) ** 2 < r * r) hurt(b, dmg, src);
    }
  }
  // ---- shots, as Projectile.move does
  function moveShot(s, dt) {
    s.age += dt; s.life -= dt;
    if (s.motion === 'wave') {
      s.bx += s.vx * dt; s.by += s.vy * dt;
      const off = Math.sin(s.age * 16 + (s.phase || 0)) * 0.5;
      s.x = s.bx - Math.sin(s.angle) * off; s.y = s.by + Math.cos(s.angle) * off;
      return;
    }
    if (s.motion === 'accel') { const f = 1 + (s.accel || 0) * dt; if (f > 0) { s.vx *= f; s.vy *= f; } }
    else if (s.motion === 'home' && s.age > 0.15) {
      const t = nearestBot(s.x, s.y);
      if (t) {
        let diff = Math.atan2(t.y - s.y, t.x - s.x) - s.angle;
        while (diff > Math.PI) diff -= Math.PI * 2; while (diff < -Math.PI) diff += Math.PI * 2;
        s.angle += Math.max(-1.6 * dt, Math.min(1.6 * dt, diff));
        const sp = Math.hypot(s.vx, s.vy); s.vx = Math.cos(s.angle) * sp; s.vy = Math.sin(s.angle) * sp;
      }
    }
    if (s.motion === 'return' && !s.turned && s.life < s.life0 * 0.5) { s.turned = true; s.vx = -s.vx; s.vy = -s.vy; s.angle += Math.PI; }
    s.x += s.vx * dt; s.y += s.vy * dt;
  }
  function nearestBot(x, y) { let best = null, bd = 1e9; for (const b of bots) { const d = (b.x - x) ** 2 + (b.y - y) ** 2; if (d < bd) { bd = d; best = b; } } return best; }
  /** Where a shot will be t seconds on (good enough for dodging: straight, or along its weave). */
  function ahead(s, t) {
    const ax = s.x + s.vx * t, ay = s.y + s.vy * t;
    return [ax, ay];
  }
  // ---- a bot's turn
  function think(b, dt) {
    const tg = pick(b);
    // far away or cut off (another room, behind a wall): it walks there (we skip the walk)
    if (tg) {
      const far = Math.hypot(tg.x - b.x, tg.y - b.y);
      b.farT = far > Math.max(12, H.range * 1.6) ? (b.farT || 0) + dt : 0;
      if (b.farT > 2) { place(b, tg.x + (b.x - tg.x) / far * H.range * 0.7, tg.y + (b.y - tg.y) / far * H.range * 0.7); b.farT = 0; return; }
    }
    if (b.stand) {
      // no dodging: it only walks into range
      if (tg) {
        const d = Math.hypot(tg.x - b.x, tg.y - b.y);
        if (d > H.range * 0.85) { const nx = b.x + (tg.x - b.x) / d * H.speed * dt, ny = b.y + (tg.y - b.y) / d * H.speed * dt; if (w.canStand(nx, ny, 0.3, false)) { b.x = nx; b.y = ny; } else b.farT = (b.farT || 0) + dt * 2; }
      }
      return;
    }
    let best = null, bs = 1e18;
    const v = H.speed;
    const pend = marks.filter((m) => m.t < 0.9);
    for (let k = -1; k < 16; k++) {
      const a = k * Math.PI / 8, mx = k < 0 ? 0 : Math.cos(a) * v, my = k < 0 ? 0 : Math.sin(a) * v;
      const nx = b.x + mx * 0.12, ny = b.y + my * 0.12;
      if (k >= 0 && !w.canStand(nx, ny, 0.3, false)) continue;
      let danger = 0;
      for (const s of shots) {
        if (s.age < 0.12) continue; // (it reacts a little late)
        const dx0 = s.x - b.x, dy0 = s.y - b.y;
        if (dx0 * dx0 + dy0 * dy0 > 100) continue;
        for (let t = 0.05; t <= 0.6; t += 0.11) {
          const [sx, sy] = ahead(s, t);
          const px = b.x + mx * Math.min(t, 0.35), py = b.y + my * Math.min(t, 0.35);
          const rr = (s.r || 0.3) + 0.3 + 0.15;
          const d2 = (sx - px) ** 2 + (sy - py) ** 2;
          if (d2 < rr * rr * 2.2) danger += (1 - t) * 4 / (0.05 + d2);
        }
      }
      for (const m of pend) {
        const px = b.x + mx * 0.35, py = b.y + my * 0.35;
        const cx = m.follow ? m.follow.x : m.x, cy = m.follow ? m.follow.y : m.y;
        const d = Math.hypot(px - cx, py - cy);
        if (m.follow === b) { for (const o of bots) if (o !== b && Math.hypot(px - o.x, py - o.y) < m.r + 1) danger += 20; }
        else if (d < m.r + 0.6) danger += 30 * (1 - m.t);
      }
      // keep to the weapon's range, and out of the boss's reach
      if (tg) {
        const d = Math.hypot(b.x + mx * 0.35 - tg.x, b.y + my * 0.35 - tg.y), want = Math.max(2.5, H.range * 0.75);
        danger += Math.abs(d - want) * (d > H.range * 0.9 ? 3 : 0.6) * (1 + (b.idleT || 0)) + (d < (tg.r || 0.6) + 1.2 ? 8 : 0);
      }
      danger += Math.random() * 0.4; // (not a perfect player)
      if (danger < bs) { bs = danger; best = [mx, my]; }
    }
    if (best) {
      const nx = b.x + best[0] * dt, ny = b.y + best[1] * dt;
      if (w.canStand(nx, ny, 0.3, false)) { b.x = nx; b.y = ny; }
    }
  }
  function pick(b) {
    const list = targets();
    if (!list.length) return null;
    // adds the boss called up, when they're on top of you, go first (as players do)
    let add = null, ad = 25;
    for (const e of sim.enemies) {
      if (e.dead || e.isBoss || e.def.prop || e.def.stageFoe || list.indexOf(e) >= 0 || e.immune) continue;
      const d = (e.x - b.x) ** 2 + (e.y - b.y) ** 2;
      if (d < ad) { ad = d; add = e; }
    }
    if (add) return add;
    // what shields, heals or helps the boss first (its wards, menders, altars, rods, crystals), then the boss
    const open = list.filter((e) => !e.immune && !e.invuln);
    const pool = open.length ? open : list;
    const props = pool.filter((e) => (e.def.prop && !e.def.invuln) || e.def.stageFoe || e.defId === 'elder_crystal');
    const from = props.length ? props : pool;
    let best = null, bd = 1e9;
    for (const e of from) { const d = (e.x - b.x) ** 2 + (e.y - b.y) ** 2; if (d < bd) { bd = d; best = e; } }
    return best;
  }
  function shoot(b, dt) {
    b.shootT -= dt;
    if (b.shootT > 0) return;
    b.shootT = 1 / H.fireRate;
    const t = pick(b);
    if (!t || t.immune) return;
    if (Math.hypot(t.x - b.x, t.y - b.y) > H.range + (t.r || 0.5)) { b.idleT = (b.idleT || 0) + 1 / H.fireRate; return; }
    b.idleT = 0;
    if (Math.random() > 0.85) return; // (a miss)
    // plus its ability now and then (about a fifth of a hero's damage)
    const dmg = Math.round(volley(H, t.defense || 0) * 1.2);
    const hp0 = t.hp;
    sim.hit(b, { id: t.id, d: dmg });
    b.dealt = (b.dealt || 0) + Math.round(hp0 - t.hp);
  }
  // ---- the clock
  let lastWin = 0, winShots = 0;
  for (let time = 0; time < MAX_T; time += DT) {
    stats.time = time;
    if (!targets().length) { stats.done = true; break; }
    for (const b of bots) {
      think(b, DT); shoot(b, DT); b.hp = Math.min(H.maxHp, b.hp + H.regen * DT);
      // a health potion when it's low (+100, Player.drinkHp)
      b.potT -= DT;
      if (b.hp < H.maxHp * 0.45 && b.pots > 0 && b.potT <= 0) { b.pots--; b.potT = 0.6; b.hp = Math.min(H.maxHp, b.hp + 100); }
    }
    sim.tick(DT);
    for (let i = timers.length - 1; i >= 0; i--) { timers[i].t -= DT; if (timers[i].t <= 0) { const f = timers[i].fn; timers.splice(i, 1); try { f(); } catch (e) {} } }
    for (let i = marks.length - 1; i >= 0; i--) {
      const m = marks[i]; m.t -= DT;
      if (m.follow) { m.x = m.follow.x; m.y = m.follow.y; }
      if (m.t <= 0) { marks.splice(i, 1); if (m.fn) try { m.fn(); } catch (e) {} }
    }
    for (let i = shots.length - 1; i >= 0; i--) {
      const s = shots[i];
      moveShot(s, DT);
      let gone = s.life <= 0 || (!s.passWalls && w.blocksShot(s.x, s.y)) || w.isSafe(s.x, s.y);
      if (!gone) for (const b of bots) {
        const rr = (s.r || 0.3) + 0.3;
        if ((b.x - s.x) ** 2 + (b.y - s.y) ** 2 < rr * rr) { hurt(b, s.dmg, s.attack); gone = true; break; }
      }
      if (gone) {
        if (s.split && s.life <= 0) for (let k = 0; k < (s.split.n || 8); k++) g.addShot(Object.assign(new (require(path.join(__dirname, '..', 'server', 'sim', 'shims')).Projectile)(s.x, s.y, s.angle + k * Math.PI * 2 / (s.split.n || 8), s.split.spd || 5, s.split.life || 1, s.split.dmg || Math.floor(s.dmg * 0.6), true, 0.18), {}));
        shots.splice(i, 1);
      }
    }
    // quiet seconds: nothing aimed anywhere near the bots
    for (const s of shots) if (s.age < DT * 1.5) { const b = nearestBot(s.x, s.y); if (b && Math.hypot(b.x - s.x, b.y - s.y) < 12) winShots++; }
    if (marks.length) winShots++;
    if (time - lastWin >= 1) { stats.windows++; if (winShots === 0) stats.quiet++; winShots = 0; lastWin = time; }
    if (DEBUG && time >= (stats.dbgT || 0)) {
      stats.dbgT = (stats.dbgT || 0) + 10;
      const tl = targets(); const b0 = bots[0];
      console.log('  t=' + Math.round(time), tl.map((e) => e.defId + ' ' + Math.round(e.hp) + '/' + Math.round(e.maxHp) + (e.immune ? ' IMM' : '') + (e.invuln ? ' INV' : '') + ' d' + Math.round(Math.hypot(e.x - b0.x, e.y - b0.y))).join(' | '), 'bot', b0.x.toFixed(1), b0.y.toFixed(1), 'dealt', b0.dealt || 0, 'shots', shots.length);
    }
    for (const e of targets()) if (e.isBoss) stats.maxPhase = Math.max(stats.maxPhase, e.phase || e.phaseIdx || 0);
  }
  stats.hp = H.maxHp; stats.range = Math.round(H.range * 10) / 10;
  stats.bossPhases = (Data.ENEMIES[id].phases || []).length;
  return stats;
}

function bump(m, k) { m.set(k, (m.get(k) || 0) + 1); }

// ---------------------------------------------------------------- all of them
function bossIds() {
  const ids = [];
  const add = (x) => { if (x && Data.ENEMIES[x] && ids.indexOf(x) < 0) ids.push(x); };
  for (const d of Data.DUNGEONS) { for (const g of d.guardians || []) add(g); if (d.trio) add(d.trio[0]); add(d.boss); }
  for (const e of Data.EVENTS) add(e);
  add('abyss_herald'); add('elder'); add('siege_warlord');
  for (const r of Bosses.RAIDS) for (const s of r.stages) add(s[0]);
  return ids;
}

/** The fight as it's meant to be played: raids with 4, the Siege with 6, finales and the Dark Elder with 3, the rest solo. */
function intended(r) { return r.group || r; }

function verdict(r) {
  const out = [];
  const m = intended(r);
  const mins = m.time / 60;
  const hpPerMin = m.dmg / m.n / Math.max(0.25, mins) / r.hp; // whole health bars lost a minute, per bot
  const deaths = m.deaths / m.n;
  const standDeaths = r.stand ? r.stand.deaths / r.stand.n : 0;
  if (!m.done) out.push('not finished in ' + Math.round(MAX_T / 60) + ' min');
  if (deaths >= 1 || hpPerMin > 2.2) out.push('TOO HARD');
  else if (standDeaths < 0.5 || (m.done && m.time < 15)) out.push('TOO EASY');
  const atk = r.attacks.size, quiet = r.quiet / Math.max(1, r.windows);
  if (atk <= 3 || quiet > 0.35 || (m.time > 150 && atk <= 5)) out.push('BORING');
  if (m.time > 240) out.push('drags on');
  return { hpPerMin, deaths, standDeaths, quiet, out };
}

function main() {
  const ids = ONLY || bossIds();
  const rows = [];
  for (const id of ids) {
    const acc = [];
    for (let k = 0; k < RUNS; k++) {
      try {
        const a = fight(id, {});
        if (!a) continue;
        const s = fight(id, { stand: true });
        a.stand = s;
        const grp = (Data.ENEMIES[id].raid || Data.ENEMIES[id].finale || Data.ENEMIES[id].final || id === 'siege_warlord' || Data.ENEMIES[id].stageFoe) ? fight(id, { group: true }) : null;
        a.group = grp;
        acc.push(a);
      } catch (err) { console.error(id, err.stack.split('\n').slice(0, 3).join(' | ')); }
    }
    if (!acc.length) continue;
    // average the runs
    const r = acc[0];
    // the middle run (one unlucky spawn spot shouldn't decide it)
    const avg = (f) => { const v = acc.map(f).sort((a, b) => a - b); return v.length % 2 ? v[(v.length - 1) / 2] : (v[v.length / 2 - 1] + v[v.length / 2]) / 2; };
    r.spread = acc.map((x) => Math.round(((x.group || x).deaths / (x.group || x).n) * 10) / 10);
    r.time = avg((x) => x.time); r.dmg = avg((x) => x.dmg); r.deaths = avg((x) => x.deaths); r.quiet = avg((x) => x.quiet); r.windows = avg((x) => x.windows);
    r.done = acc.every((x) => x.done);
    r.stand.deaths = avg((x) => x.stand.deaths); r.stand.done = acc.every((x) => x.stand.done);
    for (const x of acc.slice(1)) for (const [k, v] of x.attacks) if (!r.attacks.has(k)) r.attacks.set(k, v);
    if (r.group) { r.group.time = avg((x) => x.group.time); r.group.deaths = avg((x) => x.group.deaths); r.group.dmg = avg((x) => x.group.dmg); r.group.done = acc.every((x) => x.group.done); }
    const v = verdict(r);
    rows.push({ id, r, v });
    const line = [
      r.label.slice(0, 44).padEnd(44), r.tier.padEnd(8),
      (Math.round(r.time) + 's').padStart(5), (r.done ? '' : '*').padEnd(1),
      ('dmg/min ' + v.hpPerMin.toFixed(2)).padEnd(13), ('deaths ' + v.deaths.toFixed(1)).padEnd(11), ('stand ' + v.standDeaths.toFixed(1)).padEnd(10),
      ('atk ' + r.attacks.size).padEnd(7), ('quiet ' + Math.round(100 * r.quiet / Math.max(1, r.windows)) + '%').padEnd(10),
      r.group ? ('grp' + r.group.n + ' ' + Math.round(r.group.time) + 's d' + (r.group.deaths / r.group.n).toFixed(1)).padEnd(16) : ''.padEnd(16),
      v.out.join(', '),
      acc.length > 1 ? '[deaths by run ' + r.spread.join(' ') + ']' : ''
    ];
    console.log(line.join(' '));
    const src = (intended(r).by ? [...intended(r).by] : []).sort((a, b) => b[1] - a[1]).slice(0, 3);
    if (src.length) { const tot = src.reduce((t, x) => t + x[1], 0) || 1; const all = [...intended(r).by.values()].reduce((t, x) => t + x, 0) || 1; console.log('      hurts most: ' + src.map((x) => x[0] + ' ' + Math.round(100 * x[1] / all) + '%').join(', ')); }
  }
  if (opt('json')) require('fs').writeFileSync(opt('json'), JSON.stringify(rows.map((x) => ({ id: x.id, label: x.r.label, tier: x.r.tier, time: x.r.time, done: x.r.done,
    hpPerMin: x.v.hpPerMin, deaths: x.v.deaths, standDeaths: x.v.standDeaths, attacks: [...x.r.attacks.keys()], quiet: x.r.quiet / Math.max(1, x.r.windows),
    group: x.r.group ? { n: x.r.group.n, time: x.r.group.time, deaths: x.r.group.deaths / x.r.group.n } : null, verdict: x.v.out })), null, 1));
}

main();
