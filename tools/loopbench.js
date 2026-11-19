'use strict';
/*
 * Core loop benchmark: a bot plays a fresh hero in a real realm, from level 1 on the beach, the way a
 * player does, and reports how the loop feels in numbers: how long each level takes, how much of the
 * time is spent fighting versus walking with nothing to shoot, how often it dies, and what it finds.
 *
 *   node tools/loopbench.js [--cls archer] [--min 40] [--runs 2] [--seed 7] [--json out.json]
 *
 * The realm is the server's own (WorldSim: its spawning, landmarks, events and treasure goblins, the
 * game's own monsters and loot tables). What players' games do is done here as in tools/bossbench.js:
 * monsters' shots fly, and hit the bot if it doesn't dodge.
 *
 * The bot: it heads inland as it levels (a zone that suits its level, like the quest arrow), shoots
 * whatever is nearest in range (~85% of shots land), dodges like a decent player, drinks a health
 * potion when low, picks up loot and wears anything better for its class, drinks stat potions, and
 * gains XP as Game.as does (its own kills, and kills near it). Permadeath: when it dies, its hero is
 * gone and a new one starts on the beach, as in the game.
 */
const path = require('path');
const { Data, World } = require(path.join(__dirname, '..', 'server', 'sim', 'gen', 'game'));
const { WorldSim } = require(path.join(__dirname, '..', 'server', 'sim', 'worldsim'));

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf('--' + k); return i >= 0 ? args[i + 1] : d; };
const CLS = opt('cls', 'archer');
const MINUTES = Number(opt('min', 40));
const RUNS = Number(opt('runs', 2));
const SEED = Number(opt('seed', 7));
const DT = 0.05;
const MAX_LEVEL = 20;
const TRACE = args.indexOf('--trace') >= 0;
const EVENT_LEVEL = Number(opt('evlevel', 16));
const xpFor = (l) => 40 + l * 45 + l * l * 3;
const BOSS_NAMES = new Set(Object.values(Data.ENEMIES).filter((d) => d.ai === 'boss' || d.isBoss || d.siege).map((d) => d.name));

/** The zone a hero of this level heads for (the quest arrow's "a monster suited to your level"). */
function zoneFor(level) { return level < 4 ? 0 : level < 8 ? 1 : level < 12 ? 2 : level < 17 ? 3 : 4; }

// ---------------------------------------------------------------- the hero
function newHero(C) {
  const st = {};
  for (const s of Data.STATS) st[s] = C.base[s];
  const gear = {
    weapon: Data.makeWeapon(C.weapon, 0, null, ''),
    ability: null,
    armor: Data.makeArmor(C.armor, 0, null),
    ring: null
  };
  return { level: 1, xp: 0, st, gear, pots: { hp: 2, mp: 0 }, kills: 0, statPots: 0, born: 0 };
}

/** What the hero can do now: Player's formulas, as tools/bossbench.js has them. */
function derive(h, C) {
  const add = (k) => ['weapon', 'ability', 'armor', 'ring'].reduce((a, s) => a + ((h.gear[s] && h.gear[s][k]) || 0), 0);
  const w = h.gear.weapon;
  const att = h.st.att + add('att'), dex = h.st.dex + add('dex'), spd = h.st.spd + add('spd');
  return {
    maxHp: Math.round(h.st.hp + add('hp')), def: Math.round(h.st.def + add('def')),
    regen: 1 + (h.st.vit + add('vit')) * 0.12,
    speed: 4 + 5.6 * (spd / 75),
    fireRate: (1.5 + 6.5 * dex / 75) * (w.rate || 1),
    mult: 0.5 + att / 50,
    range: (w.spd || 10) * (w.life || 0.6),
    weapon: w
  };
}

function levelUp(h, C) {
  h.level++;
  for (const s of Data.STATS) h.st[s] = Math.min(C.max[s], h.st[s] + Data.grow(C, s) * (0.8 + Math.random() * 0.4));
}

/** How good a piece is for this hero, by slot (a rough stand-in for a player reading tooltips). */
function score(it) {
  if (!it) return -1;
  if (it.kind === 'weapon') return ((it.dmin + it.dmax) / 2) * (it.shots || 1) * (it.rate || 1);
  let s = 0;
  for (const k of Data.STATS) s += (it[k] || 0) * (k === 'hp' || k === 'mp' ? 0.2 : 1);
  return s + (it.def || 0) * 1.5;
}

// ---------------------------------------------------------------- one life after another
function run(seed) {
  const C = Data.CLASSES[CLS];
  const sim = new WorldSim('realm:Loop:' + seed);
  const w = sim.w, g = sim.g;
  const shots = [], timers = [], marks = [];
  const out = { seed, lives: [], levelAt: {}, deaths: [], kills: 0, fightT: 0, idleT: 0, walkT: 0, loot: {}, statPots: 0, events: 0, goblins: 0,
    upgrades: [], evLog: [], time: 0, l20: null, xpBy: { own: 0, near: 0 }, perZone: {} };
  let h = newHero(C), H = derive(h, C), hp = H.maxHp;
  const bot = { id: 1, name: 'Bot', send: onMsg, hidden: false, caps: null, maxDps: 1e9, x: w.spawnX, y: w.spawnY, profile: { cls: CLS, lk: 0 } };
  sim.join(bot);
  bot.x = w.spawnX; bot.y = w.spawnY;

  function onMsg(m) {
    const d = m.d || m;
    if (d.t === 'loot') take(d.l || [], d.n);
  }
  function take(items, from) {
    for (const it of items) {
      const key = it.kind === 'stat' ? 'stat potion' : it.kind === 'hp' || it.kind === 'mp' ? it.kind + ' potion' : (it.rarity || ('T' + (it.tier | 0))) + ' ' + it.kind;
      out.loot[key] = (out.loot[key] || 0) + 1;
      if (it.kind === 'stat') {
        out.statPots++;
        const s = it.sub;
        if (h.st[s] < C.max[s]) h.st[s] = Math.min(C.max[s], h.st[s] + (s === 'hp' || s === 'mp' ? 5 : 1));
        continue;
      }
      if (it.kind === 'hp' || it.kind === 'mp') { h.pots[it.kind]++; continue; }
      const slot = it.kind === 'weapon' ? 'weapon' : it.kind === 'armor' ? 'armor' : it.kind === 'ring' ? 'ring' : it.kind === 'ability' ? 'ability' : null;
      if (!slot) continue;
      const ok = slot === 'ring' || (slot === 'weapon' && it.sub === C.weapon) || (slot === 'armor' && it.sub === C.armor) || (slot === 'ability' && it.sub === C.abilityType);
      if (ok && score(it) > score(h.gear[slot])) {
        h.gear[slot] = it;
        out.upgrades.push({ t: Math.round(out.time), level: h.level, slot, name: it.name, from });
        const keep = hp / H.maxHp;
        H = derive(h, C);
        hp = H.maxHp * keep;
      }
    }
  }

  // ---- the world as the bot's game sees it
  g.addShot = (s) => {
    if (!s.enemy) return;
    s.vx = Math.cos(s.angle) * s.speed; s.vy = Math.sin(s.angle) * s.speed; s.age = 0; s.life0 = s.life;
    shots.push(s);
  };
  g.later = (t, fn) => timers.push({ t, fn });
  g.addMarker = (x, y, r, d, col, fn) => marks.push({ x, y, r, t: d, fn });
  g.brand = (who, r, d, col, dmg, src) => marks.push({ x: who.x, y: who.y, r, t: d, follow: who, fn: () => hurt(dmg, true, src, 'brand') });
  g.areaHit = (x, y, r, dmg, src, eff, col, attack) => { if ((bot.x - x) ** 2 + (bot.y - y) ** 2 < r * r) hurt(dmg, BOSS_NAMES.has(src), src, attack || 'blast'); };
  g.eclipse = () => {};

  // XP as Game.as gives it: the kills you hit, and every kill near you
  const kill0 = sim.kill.bind(sim);
  sim.kill = (e, ...rest) => {
    const mine = e.hitters && e.hitters.has(bot.id);
    const near = (e.x - bot.x) ** 2 + (e.y - bot.y) ** 2 < 15 * 15;
    if (mine && !e.def.crate) { out.kills++; h.kills++; out.perZone[e.zone] = (out.perZone[e.zone] || 0) + 1; }
    if (mine && e.isBoss && e.def.setpiece) { out.events++; out.evLog.push({ id: e.defId, t: Math.round(out.time), took: Math.round(out.time - (bot.evSince || out.time)), level: h.level }); bot.evSince = 0; }
    if (mine && e.def.goblin) out.goblins++;
    if (mine || near) {
      const xp = Math.round((e.def.xp || 0) * (e.elite ? 3 : 1));
      out.xpBy[mine ? 'own' : 'near'] += xp;
      gain(xp);
    }
    return kill0(e, ...rest);
  };
  function gain(xp) {
    if (h.level >= MAX_LEVEL) return;
    h.xp += xp;
    while (h.level < MAX_LEVEL && h.xp >= xpFor(h.level)) {
      h.xp -= xpFor(h.level);
      levelUp(h, C);
      if (!out.lives.length && out.levelAt[h.level] == null) out.levelAt[h.level] = Math.round(out.time - h.born);
      if (h.level >= MAX_LEVEL && out.l20 == null) out.l20 = Math.round(out.time - h.born);
      const keep = hp / H.maxHp;
      H = derive(h, C);
      hp = Math.max(hp, H.maxHp * keep);
    }
  }
  const recent = [];
  function hurt(raw, boss, src, attack) {
    const d = boss ? Math.max(raw - Math.floor(H.def * 0.5), Math.floor(raw * 0.35)) : Math.max(raw - H.def, Math.floor(raw * 0.15));
    hp -= d;
    recent.push({ t: out.time, d, src: src || '?', attack: attack || '' });
    while (recent.length && recent[0].t < out.time - 5) recent.shift();
    if (hp <= 0) die(src, attack);
  }
  function die(src, attack) {
    // what did it in, and what had hurt it in the last 5 seconds (by source)
    const by = {};
    for (const r of recent) by[r.src] = (by[r.src] || 0) + r.d;
    const nearby = sim.enemies.filter((e) => !e.dead && Math.hypot(e.x - bot.x, e.y - bot.y) < 12).length;
    out.deaths.push({ t: Math.round(out.time), level: h.level, life: Math.round(out.time - h.born), zone: w.zoneAt(bot.x, bot.y), src, attack, by, maxHp: H.maxHp, def: H.def, nearby, gear: h.gear.weapon.name + '/' + h.gear.armor.name });
    out.lives.push({ level: h.level, secs: Math.round(out.time - h.born), kills: h.kills });
    h = newHero(C); h.born = out.time; H = derive(h, C); hp = H.maxHp;
    bot.x = w.spawnX; bot.y = w.spawnY;
    shots.length = 0; marks.length = 0;
  }

  // ---- what to shoot: the nearest monster (bosses only once it's ready for them)
  const skip = new Map();
  function pick() {
    let best = null, bd = 1e9;
    for (const e of sim.enemies) {
      if (e.dead || e.immune || e.invuln || (skip.get(e.id) || 0) > out.time) continue;
      if (e.isBoss && h.level < EVENT_LEVEL && !e.site) continue;
      const d = (e.x - bot.x) ** 2 + (e.y - bot.y) ** 2;
      if (d < bd) { bd = d; best = e; }
    }
    // (heading for an event: only what's close, so it doesn't get drawn off the way)
    const reach = w.boss && !w.boss.dead && h.level >= EVENT_LEVEL && best !== w.boss ? 9 : 14;
    return best && bd < reach * reach ? best : null;
  }

  // ---- getting about: toward the zone that suits its level (inland is toward the middle)
  const CX = w.N / 2, CY = w.N / 2;
  // ---- a map of where it can walk (by tile), and a path search over it
  const N = w.N, open = new Uint8Array(N * N);
  for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) open[y * N + x] = w.canStand(x + 0.5, y + 0.5, 0.3, false) && !w.isSafe(x + 0.5, y + 0.5) ? 1 : 0;
  const prev = new Int32Array(N * N);
  /** Breadth-first from the bot to the nearest tile that ok(x, y) accepts (up to a few thousand steps): the path, or null. */
  function pathTo(ok, limit) {
    const sx = Math.floor(bot.x), sy = Math.floor(bot.y), start = sy * N + sx;
    prev.fill(-1);
    const q = [start]; prev[start] = start;
    for (let qi = 0; qi < q.length && qi < (limit || 60000); qi++) {
      const c = q[qi], cx = c % N, cy = (c - cx) / N;
      if (qi > 0 && ok(cx, cy)) {
        const path = [];
        for (let k = c; k !== start; k = prev[k]) path.push([k % N + 0.5, Math.floor(k / N) + 0.5]);
        return path.reverse();
      }
      for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const nx = cx + dx, ny = cy + dy;
        if (nx < 0 || ny < 0 || nx >= N || ny >= N) continue;
        const n = ny * N + nx;
        if (prev[n] >= 0 || !open[n]) continue;
        prev[n] = c; q.push(n);
      }
    }
    return null;
  }
  /** The next step along its route (replanned every few seconds, or when it runs out). */
  function routeStep() {
    bot.routeT = (bot.routeT || 0) - DT;
    if (!bot.route || !bot.route.length || bot.routeT <= 0) {
      bot.routeT = 4;
      const ev = w.boss && !w.boss.dead && h.level >= EVENT_LEVEL ? w.boss : null;
      const want = zoneFor(h.level);
      bot.route = ev ? pathTo((x, y) => Math.abs(x + 0.5 - ev.x) + Math.abs(y + 0.5 - ev.y) < 8, 260000)
        : w.zoneAt(bot.x, bot.y) === want ? null
        : pathTo((x, y) => w.zoneAt(x + 0.5, y + 0.5) === want && Math.hypot(x - bot.x, y - bot.y) > 6, 260000);
    }
    while (bot.route && bot.route.length && Math.hypot(bot.route[0][0] - bot.x, bot.route[0][1] - bot.y) < 0.6) bot.route.shift();
    if (!bot.route || !bot.route.length) return null;
    const p = bot.route[Math.min(2, bot.route.length - 1)], dx = p[0] - bot.x, dy = p[1] - bot.y, d = Math.hypot(dx, dy) || 1;
    return [dx / d, dy / d];
  }
  function heading() {
    const r = routeStep();
    if (r) { const ev = w.boss && !w.boss.dead && h.level >= EVENT_LEVEL; if (ev && !bot.evSince) bot.evSince = out.time; return r; }
    return [Math.cos(bot.wander || 0), Math.sin(bot.wander || 0)];
  }

  function think(dt, tg) {
    let best = null, bs = 1e18;
    const v = H.speed;
    const pend = marks.filter((m) => m.t < 0.9);
    const head = tg ? null : heading();
    // (standing somewhere it couldn't step to: something grew under it; it may walk out)
    const trapped = !w.canStand(bot.x, bot.y, 0.3, false);
    for (let k = -1; k < 16; k++) {
      const a = k * Math.PI / 8, mx = k < 0 ? 0 : Math.cos(a) * v, my = k < 0 ? 0 : Math.sin(a) * v;
      const nx = bot.x + mx * 0.12, ny = bot.y + my * 0.12;
      if (k >= 0 && !trapped && !w.canStand(nx, ny, 0.3, false)) continue;
      let danger = 0;
      for (const s of shots) {
        if (s.age < 0.12) continue;
        const dx0 = s.x - bot.x, dy0 = s.y - bot.y;
        if (dx0 * dx0 + dy0 * dy0 > 100) continue;
        for (let t = 0.05; t <= 0.6; t += 0.11) {
          const sx = s.x + s.vx * t, sy = s.y + s.vy * t;
          const px = bot.x + mx * Math.min(t, 0.35), py = bot.y + my * Math.min(t, 0.35);
          const rr = (s.r || 0.3) + 0.45;
          const d2 = (sx - px) ** 2 + (sy - py) ** 2;
          if (d2 < rr * rr * 2.2) danger += (1 - t) * 4 / (0.05 + d2);
        }
      }
      for (const m of pend) {
        const cx = m.follow ? m.follow.x : m.x, cy = m.follow ? m.follow.y : m.y;
        if (m.follow !== bot && Math.hypot(bot.x + mx * 0.35 - cx, bot.y + my * 0.35 - cy) < m.r + 0.6) danger += 30 * (1 - m.t);
      }
      if (tg) {
        const d = Math.hypot(bot.x + mx * 0.35 - tg.x, bot.y + my * 0.35 - tg.y), want = Math.max(2.5, H.range * 0.75);
        danger += Math.abs(d - want) * (d > H.range * 0.9 ? 3 : 0.6) + (d < (tg.r || 0.6) + 1.2 ? 8 : 0);
      } else if (k >= 0) {
        // walking: the way it wants to go, and not back into a wall
        danger += (1 - (Math.cos(a) * head[0] + Math.sin(a) * head[1])) * 2;
      } else danger += 3;
      danger += Math.random() * 0.4;
      if (danger < bs) { bs = danger; best = [mx, my]; }
    }
    if (best) {
      const nx = bot.x + best[0] * dt, ny = bot.y + best[1] * dt;
      if (trapped || w.canStand(nx, ny, 0.3, false)) { bot.x = nx; bot.y = ny; }
      else { bot.stuck = (bot.stuck || 0) + dt; }
    }
    if (!tg) {
      // (stuck on a coast or a ruin: try another way for a while)
      bot.wanderT = (bot.wanderT || 0) - dt;
      if (bot.wanderT <= 0 || (bot.stuck || 0) > 1) { bot.wander = Math.random() * Math.PI * 2; bot.wanderT = 6; bot.stuck = 0; }
    }
  }

  let shootT = 0, potT = 0;
  const END = MINUTES * 60;
  for (let time = 0; time < END; time += DT) {
    out.time = time;
    if (TRACE && w.boss && !w.boss.dead && Math.hypot(w.boss.x - bot.x, w.boss.y - bot.y) < 12 && Math.floor(time) % 20 === 0 && Math.floor(time - DT) % 20 !== 0) console.log('   near event:', sim.enemies.filter((e) => !e.dead && Math.hypot(e.x - bot.x, e.y - bot.y) < 14).map((e) => e.defId + ' ' + Math.round(e.hp) + (e.immune ? ' IMM' : '') + (e.invuln ? ' INV' : '') + ((skip.get(e.id) || 0) > out.time ? ' SKIP' : '')).join(', '), '| target', (pick() || {}).defId);
    if (TRACE && Math.floor(time) % 30 === 0 && Math.floor(time - DT) % 30 !== 0) console.log('t' + Math.round(time), 'L' + h.level, 'at', bot.x.toFixed(0) + ',' + bot.y.toFixed(0), 'zone', w.zoneAt(bot.x, bot.y), 'ev', w.boss && !w.boss.dead ? w.boss.defId + '@' + w.boss.x.toFixed(0) + ',' + w.boss.y.toFixed(0) + ' d' + Math.hypot(w.boss.x - bot.x, w.boss.y - bot.y).toFixed(0) : '-', 'route', bot.route ? bot.route.length : 'none', 'enemies', sim.enemies.length);
    const tg = pick();
    const inRange = tg && Math.hypot(tg.x - bot.x, tg.y - bot.y) <= H.range + (tg.r || 0.5);
    // (closing on something for 4s without getting it in range: across water or a wall; leave it for a while)
    if (tg && !inRange) { if (bot.chase !== tg.id) { bot.chase = tg.id; bot.chaseT = 0; } bot.chaseT += DT; if (bot.chaseT > 4) skip.set(tg.id, out.time + 20); }
    else bot.chase = 0;
    if (inRange) out.fightT += DT; else if (tg) out.walkT += DT; else out.idleT += DT;
    think(DT, tg);
    shootT -= DT;
    if (shootT <= 0 && inRange) {
      shootT = 1 / H.fireRate;
      if (Math.random() < 0.85) {
        const wpn = H.weapon, avg = (wpn.dmin + wpn.dmax) / 2 * H.mult;
        const dmg = Math.round((wpn.shots || 1) * Math.max(1, avg - (tg.defense || 0), Math.floor(avg * 0.15)) * 1.2);
        sim.hit(bot, { id: tg.id, d: dmg });
      }
    }
    hp = Math.min(H.maxHp, hp + H.regen * DT);
    potT -= DT;
    if (hp < H.maxHp * 0.4 && h.pots.hp > 0 && potT <= 0) { h.pots.hp--; potT = 0.6; hp = Math.min(H.maxHp, hp + 100); }
    sim.tick(DT);
    for (let i = timers.length - 1; i >= 0; i--) { timers[i].t -= DT; if (timers[i].t <= 0) { const f = timers[i].fn; timers.splice(i, 1); try { f(); } catch (e) {} } }
    for (let i = marks.length - 1; i >= 0; i--) {
      const m = marks[i]; m.t -= DT;
      if (m.follow) { m.x = m.follow.x; m.y = m.follow.y; }
      if (m.t <= 0) { marks.splice(i, 1); if (m.fn) try { m.fn(); } catch (e) {} }
    }
    for (let i = shots.length - 1; i >= 0; i--) {
      const s = shots[i];
      if (!s) continue; // (it died: the screen was cleared)
      s.age += DT; s.life -= DT;
      s.x += s.vx * DT; s.y += s.vy * DT;
      let gone = s.life <= 0 || (!s.passWalls && w.blocksShot(s.x, s.y));
      const rr = (s.r || 0.3) + 0.3;
      if (!gone && (bot.x - s.x) ** 2 + (bot.y - s.y) ** 2 < rr * rr) { hurt(s.dmg, BOSS_NAMES.has(s.owner), s.owner, s.attack); gone = true; }
      if (gone) shots.splice(i, 1);
    }
  }
  out.final = { level: h.level, life: Math.round(out.time - h.born), gear: Object.fromEntries(Object.entries(h.gear).map(([k, v]) => [k, v ? v.name : '-'])) };
  return out;
}

// ---------------------------------------------------------------- the report
function main() {
  const t0 = Date.now();
  const all = [];
  for (let r = 0; r < RUNS; r++) {
    const o = run(SEED + r * 101);
    all.push(o);
    const m = (s) => (s / 60).toFixed(1) + 'm';
    console.log('\n=== run ' + (r + 1) + ' (' + CLS + ', ' + MINUTES + ' min, seed ' + o.seed + ')');
    console.log('first hero: level by time  ' + [2, 5, 8, 10, 12, 15, 18, 20].map((l) => 'L' + l + ' ' + (o.levelAt[l] != null ? m(o.levelAt[l]) : '-')).join('  '));
    console.log('deaths: ' + (o.deaths.length ? '' : 'none'));
    for (const d of o.deaths) console.log('   L' + d.level + ' at ' + m(d.t) + ' zone ' + d.zone + ': ' + d.src + (d.attack ? ' (' + d.attack + ')' : '') + ', last 5s ' + JSON.stringify(d.by) + ', hp ' + d.maxHp + ' def ' + d.def + ', ' + d.nearby + ' monsters near, ' + d.gear);
    const tot = o.fightT + o.walkT + o.idleT;
    console.log('time: fighting ' + Math.round(o.fightT / tot * 100) + '%, closing in ' + Math.round(o.walkT / tot * 100) + '%, nothing near ' + Math.round(o.idleT / tot * 100) + '%');
    console.log('kills ' + o.kills + ' (' + (o.kills / MINUTES).toFixed(1) + '/min) by zone ' + JSON.stringify(o.perZone) + ', events ' + o.events + ', goblins ' + o.goblins + ', XP own/near ' + o.xpBy.own + '/' + o.xpBy.near);
    console.log('loot: ' + Object.entries(o.loot).sort((a, b) => b[1] - a[1]).map(([k, v]) => k + ' ' + v).join(', '));
    console.log('events: ' + o.evLog.map((e) => e.id + ' (' + e.took + 's from setting out, L' + e.level + ')').join(', '));
    console.log('upgrades: ' + o.upgrades.map((u) => m(u.t) + ' L' + u.level + ' ' + u.name).join(' | '));
    console.log('end: level ' + o.final.level + ', ' + JSON.stringify(o.final.gear));
  }
  if (opt('json')) require('fs').writeFileSync(opt('json'), JSON.stringify(all, null, 1));
  console.log('\n(' + ((Date.now() - t0) / 1000).toFixed(0) + 's)');
}

main();
