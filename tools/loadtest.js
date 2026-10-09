'use strict';
/*
 * Load test: starts a private copy of the server (throwaway data folder, spare
 * port) and connects fake players that play roughly like people do: they make
 * a hero, walk into a realm, hunt monsters, shoot, take hits, report them and
 * save now and then. Every few seconds it prints the server's own health
 * (/stats) and how quickly it answers.
 *
 *   node tools/loadtest.js [bots=60] [seconds=90]
 *
 * Your real server, accounts and saves are never touched.
 */
const net = require('net');
const fs = require('fs');
const os = require('os');
const path = require('path');
const http = require('http');
const { spawn } = require('child_process');

const BOTS = Number(process.argv[2]) || 60;
const SECS = Number(process.argv[3]) || 90;
const PORT = 21000 + Math.floor(Math.random() * 20000);
const DATA = fs.mkdtempSync(path.join(os.tmpdir(), 'newrealm-load-'));
const ROOT = path.join(__dirname, '..');
const { World } = require(path.join(ROOT, 'server/sim/gen/game'));
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

const rtts = [];
let kills = 0, refusedMoves = 0, errors = 0;
const refusals = [], slow = [];

function bot(i) {
  return new Promise((resolve) => {
    const s = net.connect(PORT, '127.0.0.1');
    const b = { i, s, x: 0, y: 0, enemies: new Map(), target: null, world: null, hits: 0, alive: true };
    let buf = '';
    b.send = (o) => { if (b.alive) s.write(JSON.stringify(o) + '\n'); };
    s.on('data', (d) => {
      buf += d;
      let k;
      while ((k = buf.indexOf('\n')) >= 0) {
        const line = buf.slice(0, k); buf = buf.slice(k + 1);
        let m; try { m = JSON.parse(line); } catch (e) { continue; }
        onMsg(b, m);
      }
    });
    s.on('error', () => { errors++; });
    s.on('close', () => { b.alive = false; });
    s.on('connect', () => resolve(b));
  });
}

function onMsg(b, m) {
  if (m.t === 'welcome') { b.id = m.id; b.realms = m.realms; }
  else if (m.t === 'pong') rtts.push(Date.now() - m.at);
  else if (m.t === 'pos') { refusedMoves++; b.x = m.x; b.y = m.y; }
  else if (m.t === 'w' && m.d) {
    const d = m.d;
    if (d.t === 'espawn') for (const e of d.l || []) b.enemies.set(e[0], { x: e[2], y: e[3] });
    else if (d.t === 'ekill' || d.t === 'edel') { if (b.enemies.delete(d.id) && b.target === d.id) { b.target = null; kills++; } }
  }
}

const realmMaps = new Map();
function realmSpawn(r) {
  const key = r.name + ':' + r.seed;
  if (!realmMaps.has(key)) { const w = new World('realm', r.name, null, r.seed >>> 0); realmMaps.set(key, w); }
  const w = realmMaps.get(key);
  return { x: w.spawnX, y: w.spawnY, w };
}

async function play(b) {
  b.send({ t: 'hello', ver: 11, name: 'Bot' + b.i, password: 'botpass1', register: true });
  for (let k = 0; k < 40 && !b.realms; k++) await wait(100);
  if (!b.realms) return;
  const cid = 'bot' + b.i;
  const hero = { id: cid, cls: 'wizard', name: 'Bot' + b.i, level: 1, inv: [null, null, null, null, null, null, null, null] };
  b.send({ t: 'save', data: { gold: 0, fame: 0, chars: [hero] } });
  await wait(300);
  // spread over the realms the server offers
  const r = b.realms[b.i % b.realms.length];
  const sp = realmSpawn(r);
  b.x = sp.x; b.y = sp.y; b.w = sp.w;
  b.world = 'realm:' + r.name + ':' + r.seed;
  b.send({ t: 'enter', key: b.world, cid, x: b.x, y: b.y, profile: { cls: 'wizard', level: 5 } });
  await wait(200);
  b.send({ t: 'w', to: 'host', d: { t: 'sync' } });
  let tick = 0;
  const end = Date.now() + SECS * 1000;
  while (Date.now() < end && b.alive) {
    tick++;
    // pick the nearest known monster, walk at a player's pace (about 5 tiles/s) toward it
    if (!b.target || !b.enemies.has(b.target)) {
      let best = null, bd = 1e9;
      for (const [id, e] of b.enemies) { const d = (e.x - b.x) ** 2 + (e.y - b.y) ** 2; if (d < bd) { bd = d; best = id; } }
      b.target = best;
    }
    const e = b.target ? b.enemies.get(b.target) : null;
    if (e) {
      const dx = e.x - b.x, dy = e.y - b.y, d = Math.sqrt(dx * dx + dy * dy) || 1;
      if (d > 4) {
        const step = 0.4, nx = b.x + dx / d * step, ny = b.y + dy / d * step;
        // (like the game, never step through a tree or wall: check the whole way, as the server does)
        const clear = (tx, ty) => b.w.canStand(tx, ty, 0.35, false);
        if (clear(nx, ny)) { b.x = nx; b.y = ny; }
        else { const a = Math.random() * 6.283, ax = b.x + Math.cos(a) * 0.5, ay = b.y + Math.sin(a) * 0.5; if (clear(ax, ay)) { b.x = ax; b.y = ay; } }
        b.send({ t: 'move', x: Math.round(b.x * 100) / 100, y: Math.round(b.y * 100) / 100, f: 0 });
      }
      if (d < 9 && tick % 2 === 0) {
        b.send({ t: 'shoot', ang: Math.atan2(dy, dx) });
        b.send({ t: 'w', to: 'host', d: { t: 'ehit', id: b.target, d: 40 + Math.random() * 40 } });
      }
    }
    if (tick % 10 === 0) { b.hits += Math.random() < 0.3 ? 1 : 0; b.send({ t: 'hits', n: b.hits }); }
    if (tick % 20 === 0) b.send({ t: 'ping', at: Date.now() });
    if (tick % 100 === 0) b.send({ t: 'save', data: { gold: 0, fame: 0, chars: [Object.assign({}, hero, { x: b.x, y: b.y })] } });
    if (tick % 60 === 0) b.send({ t: 'w', to: 'host', d: { t: 'sync' } });
    await wait(100);
  }
  b.alive = false;
  b.s.destroy();
}

function stats() {
  return new Promise((resolve) => {
    http.get({ host: '127.0.0.1', port: PORT, path: '/stats' }, (res) => {
      let t = ''; res.on('data', (d) => { t += d; }); res.on('end', () => resolve(t.trim()));
    }).on('error', () => resolve('(no answer)'));
  });
}

function pct(a, p) { const s = a.slice().sort((x, y) => x - y); return s.length ? s[Math.min(s.length - 1, Math.floor(s.length * p))] : 0; }

async function main() {
  fs.writeFileSync(path.join(DATA, 'config.json'), JSON.stringify({ port: PORT, minRealms: 3, maxRealms: 6, admins: [] }));
  const srv = spawn(process.execPath, [path.join(ROOT, 'server/server.js'), String(PORT)], {
    env: Object.assign({}, process.env, process.env.LOAD_MOVE_DEBUG ? { NEWREALM_MOVE_DEBUG: '1' } : {}, { NEWREALM_SLOW_LOG: '1' }, { NEWREALM_DATA: DATA, NEWREALM_CONFIG: path.join(DATA, 'config.json') }), stdio: ['pipe', 'pipe', 'pipe'] });
  let serverErr = '';
  srv.stderr.on('data', (d) => { serverErr += d; });
  srv.stdout.on('data', (d) => { for (const l of String(d).split('\n')) if (/slow: /.test(l)) slow.push(l.replace(/^.*slow: /, '')); if (process.env.LOAD_MOVE_DEBUG) for (const l of String(d).split('\n')) if (/REFUSED/.test(l)) refusals.push(l); });
  await wait(2500);
  console.log('Load test: ' + BOTS + ' fake players for ' + SECS + 's on port ' + PORT);
  const bots = [];
  for (let i = 0; i < BOTS; i++) {
    const b = await bot(i);
    bots.push(b);
    play(b).catch((e) => { errors++; console.error('bot', i, e.message); });
    await wait(60);
  }
  const t0 = Date.now();
  while (Date.now() - t0 < SECS * 1000) {
    await wait(10000);
    const recent = rtts.splice(0);
    console.log('--- ' + Math.round((Date.now() - t0) / 1000) + 's: answers in ' + pct(recent, 0.5) + ' ms typical, ' + pct(recent, 0.95) + ' ms slow 5%; ' +
      kills + ' kills, ' + refusedMoves + ' refused moves, ' + errors + ' socket errors');
    console.log((await stats()).split('\n').map((l) => '    ' + l).join('\n'));
  }
  srv.kill('SIGTERM');
  await wait(500);
  if (refusals.length) { const why = {}; for (const l of refusals) { const k = (/REFUSED (.*)$/.exec(l) || [])[1].replace(/ at [0-9.,]+/, ''); why[k] = (why[k] || 0) + 1; } console.log('Refused moves by reason:', why); }
  if (slow.length) { const by = {}; for (const l of slow) { const k = l.split(' ')[0]; (by[k] = by[k] || []).push(parseInt(l.split('took ')[1])); }
    console.log('Slow messages:', Object.keys(by).map((k) => k + ' x' + by[k].length + ' (worst ' + Math.max.apply(null, by[k]) + ' ms)').join(', ')); }
  if (serverErr.trim()) console.log('Server errors:\n' + serverErr.split('\n').slice(0, 30).join('\n'));
  fs.rmSync(DATA, { recursive: true, force: true });
  process.exit(0);
}

main();
