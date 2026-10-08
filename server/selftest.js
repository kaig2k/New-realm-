'use strict';
/*
 * Server self-test: starts a private copy of the server on a spare port with
 * a throwaway data folder, plays through the protocol with fake clients and
 * checks the answers. Your real accounts and saves are never touched.
 *
 *   node server/selftest.js                 run every check
 *   node server/selftest.js items.json      also check that every item in
 *                                           the file passes the save checks
 */
const net = require('net');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');
const { checkItem, checkSave } = require('./validate');

const PORT = 20000 + Math.floor(Math.random() * 20000);
const VERSION = 11;
const DATA = fs.mkdtempSync(path.join(os.tmpdir(), 'newrealm-test-'));
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
let passed = 0, failed = 0;

function check(name, ok, detail) {
  if (ok) { passed++; console.log('  ok   ' + name); }
  else { failed++; console.log('  FAIL ' + name + (detail ? '  (' + detail + ')' : '')); }
}

/** A fake game client speaking newline-separated JSON. */
function client() {
  return new Promise((resolve) => {
    const s = net.connect(PORT, '127.0.0.1');
    const c = { s, msgs: [], id: 0, closed: false };
    let buf = '';
    s.on('data', (d) => {
      buf += d;
      let i;
      while ((i = buf.indexOf('\n')) >= 0) {
        const line = buf.slice(0, i);
        buf = buf.slice(i + 1);
        try {
          const m = JSON.parse(line);
          c.msgs.push(m);
          if (m.t === 'welcome') c.id = m.id;
        } catch (e) {}
      }
    });
    s.on('close', () => { c.closed = true; });
    s.on('error', () => {});
    c.send = (o) => { if (!c.closed) s.write((typeof o === 'string' ? o : JSON.stringify(o)) + '\n'); };
    c.find = (fn) => c.msgs.find(fn);
    c.clear = () => { c.msgs.length = 0; };
    s.on('connect', () => resolve(c));
  });
}

async function login(name, opts) {
  const c = await client();
  c.send(Object.assign({ t: 'hello', ver: VERSION, name }, opts));
  await wait(250);
  return c;
}

const ITEMS = {
  weapon: { kind: 'weapon', sub: 'staff', tier: 5, name: 'Staff', dmin: 40, dmax: 70, shots: 2, rate: 1, life: 0.8, spd: 14 },
  ring: { kind: 'ring', sub: 'att', tier: 3, name: 'Ring of Attack', att: 6 },
  godly: { kind: 'armor', sub: 'robe', tier: 8, rarity: 'gd', name: 'Godly Robe', def: 30, hp: 80 },
  raidKey: { kind: 'key', sub: 'conclave', tier: 0, name: 'Raid Key', color: 0xff3050 },
  dungeonKey: { kind: 'key', sub: 'dg_crypt', tier: 0, name: 'Sunken Crypt Key', color: 0x6ad0ff },
  potion: { kind: 'stat', sub: 'att', tier: 0, name: 'Potion of Attack', color: 0xff0000 }
};

function charSave(id, inv) {
  const pad = inv.concat(); while (pad.length < 8) pad.push(null);
  return { id, cls: 'wizard', name: 'Hero', level: 20, stats: { hp: 600, att: 70 }, weapon: ITEMS.weapon, ability: null, armor: null, ring: null,
    inv: pad, skills: { brutality: 2, highstakes: 1 }, skillPoints: 3, highStakes: true, tree2: true };
}

async function run() {
  console.log('New Realm server self-test (port ' + PORT + ')');
  const srv = spawn(process.execPath, [path.join(__dirname, 'server.js'), String(PORT)], {
    env: Object.assign({}, process.env, { NEWREALM_DATA: DATA }), stdio: ['ignore', 'pipe', 'pipe']
  });
  let srvOut = '';
  srv.stdout.on('data', (d) => { srvOut += d; });
  srv.stderr.on('data', (d) => { srvOut += d; });
  const n = Math.floor(Math.random() * 9000 + 1000);
  const nameA = 'Ta' + n, nameB = 'Tb' + n;
  // saves from before the item ledger (items without ids), as on a server being upgraded
  fs.mkdirSync(path.join(DATA, 'saves'), { recursive: true });
  fs.writeFileSync(path.join(DATA, 'saves', nameA.toLowerCase() + '.json'), JSON.stringify({ gold: 5000, fame: 100, onrane: 300,
    chars: [charSave('ca', [ITEMS.ring, ITEMS.godly, ITEMS.raidKey, ITEMS.dungeonKey, ITEMS.weapon])], vault: [ITEMS.potion, null, ITEMS.godly], vaultChests: 3 }));
  fs.writeFileSync(path.join(DATA, 'saves', nameB.toLowerCase() + '.json'), JSON.stringify({ gold: 3000, chars: [charSave('cb', [ITEMS.potion])] }));
  await wait(900);

  console.log('accounts');
  const old = await login('Old' + n, { password: 'x', ver: 3 });
  check('old game version is refused', old.find((m) => m.t === 'error' && /Version/.test(m.msg)));
  const A = await login(nameA, { password: 'pass1234', register: true });
  check('register works', A.id > 0 && A.find((m) => m.t === 'welcome' && m.session));
  const tokenA = A.find((m) => m.t === 'welcome').session;
  const dup = await login(nameA.toLowerCase(), { password: 'pass1234', register: true });
  check('a taken name is refused', dup.find((m) => m.t === 'error' && /taken/.test(m.msg)));
  const wrong = await login(nameA, { password: 'nope1234' });
  check('a wrong password is refused', wrong.find((m) => m.t === 'error' && /Wrong password/.test(m.msg)));
  const bad = await login('x!', { password: 'pass1234', register: true });
  check('a bad username is refused', bad.find((m) => m.t === 'error'));
  const B = await login(nameB, { password: 'pass1234', register: true });
  check('second account registers', B.id > 0);

  console.log('item ledger and anti-cheat');
  const clone = (o) => JSON.parse(JSON.stringify(o));
  const wA = A.find((m) => m.t === 'welcome').save;
  const all = [].concat(wA.chars[0].inv.filter(Boolean), [wA.chars[0].weapon], wA.vault.filter(Boolean));
  check('items from before the ledger got ids when the server first loaded the save', all.length >= 7 && all.every((it) => it.sid), all.length + ' items');
  check("the server's private ledger is not sent to the game", !wA._ledger);
  const goodA = () => ({ gold: 5000, fame: 100, onrane: 300, chars: [clone(wA.chars[0])], vault: clone(wA.vault), vaultChests: 3, opt: { shake: false }, keys: { up: 85 } });
  A.send({ t: 'save', data: goodA() });
  await wait(450);
  check('a normal save (godly, raid key, dungeon key, vault, settings) is accepted', !A.find((m) => m.t === 'saveRejected'),
    JSON.stringify(A.find((m) => m.t === 'saveRejected')));
  const tryA = async (fn, re, name) => {
    A.clear();
    const d = goodA(); fn(d);
    A.send({ t: 'save', data: d });
    await wait(450);
    const r = A.find((m) => m.t === 'saveRejected');
    check(name, r && re.test(r.reason), r ? r.reason : 'accepted');
  };
  await tryA((d) => { d.chars[0].inv[5] = clone(ITEMS.ring); }, /not given out/, 'an item the server never gave out is refused');
  await tryA((d) => { d.chars[0].inv[0].att = 20; }, /was changed/, 'an edited item (better stats) is refused');
  await tryA((d) => { d.chars[0].inv[5] = clone(d.chars[0].inv[1]); }, /appears twice/, 'a copied item (same id twice) is refused');
  await tryA((d) => { d.chars[0].inv[5] = { kind: 'ring', sub: 'att', tier: 3, name: 'Hacked Ring', att: 9999 }; }, /att/, 'an edited +9999 ring is refused');
  await tryA((d) => { d.chars[0].stats.att = 500; }, /impossible att/, 'stats above the class maximum are refused');
  await tryA((d) => { d.gold = 99999999; }, /gold/, 'gold jumping by millions is refused');
  const rej = A.find((m) => m.t === 'saveRejected');
  check('a refused save sends back the last good save (without the ledger)', rej && rej.data && rej.data.gold === 5000 && !rej.data._ledger);
  await tryA((d) => { d.chars[0].inv[5] = { kind: 'sword?', name: 'x' }; }, /unknown item kind/, 'unknown item kinds are refused');
  A.clear();
  for (let i = 1; i <= 4; i++) { const d = goodA(); d.gold = 5000 + i * 100000; A.send({ t: 'save', data: d }); await wait(450); }
  check('repeated quick gold jumps are refused once the allowance is used up', A.find((m) => m.t === 'saveRejected' && /gold/.test(m.reason)));
  A.clear();
  A.send({ t: 'save', data: goodA() });
  await wait(450);

  console.log('shops on the server');
  A.send({ t: 'enter', key: 'nexus', x: 100, y: 100, cid: 'ca' });
  await wait(150);
  A.clear();
  A.send({ t: 'buy', what: 'stat', data: goodA() });
  await wait(400);
  let sd = A.find((m) => m.t === 'shopDone');
  const bought = sd && sd.inv.find((it) => it && it.kind === 'stat' && it.sid && !all.some((o) => o.sid === it.sid));
  check('the Marketplace sells through the server: the item has an id and the gold is taken', bought && sd.gold === 5000 - 450, sd ? sd.gold : 'no reply');
  let invA = sd ? sd.inv : [];
  let gA = sd ? sd.gold : 5000, seqA = sd ? sd.seq : 0;
  A.clear();
  const withInv = () => { const d = goodA(); d.chars[0].inv = clone(invA); d.gold = gA; d.tradeSeq = seqA; return d; };
  A.send({ t: 'buy', what: 'key', dg: 0, data: withInv() });
  await wait(400);
  sd = A.find((m) => m.t === 'shopDone');
  const key = sd && sd.inv.find((it) => it && it.kind === 'key' && /^dg_/.test(it.sub) && it.sid && !invA.some((o) => o && o.sid === it.sid));
  check('the Key Merchant sells through the server, at the right price', key && sd.gold === gA - 1800, sd ? sd.gold : 'no reply');
  if (sd) { invA = sd.inv; gA = sd.gold; seqA = sd.seq; }
  A.clear();
  A.send({ t: 'buy', what: 'ut', data: Object.assign(withInv(), { gold: 10 }) });
  await wait(400);
  check('buying without enough gold is refused', A.find((m) => m.t === 'shopFail'));
  A.clear();
  A.send({ t: 'save', data: withInv() });
  await wait(450);
  check('a save holding the bought items is accepted', !A.find((m) => m.t === 'saveRejected'), JSON.stringify(A.find((m) => m.t === 'saveRejected')));
  A.clear();
  A.send({ t: 'forge', slot: invA.indexOf(invA.find((it) => it && it.kind === 'stat')), data: withInv() });
  await wait(400);
  check('the Starforge on the server refuses items that cannot be forged', A.find((m) => m.t === 'shopFail' && /cannot be forged/.test(m.msg)));
  const wi = invA.findIndex((it) => it && it.kind === 'weapon');
  check('test setup: a weapon to reroll', wi >= 0);
  if (wi >= 0) {
    A.clear();
    A.send({ t: 'reroll', slot: wi, what: 'form', data: withInv() });
    await wait(400);
    sd = A.find((m) => m.t === 'shopDone');
    const nw = sd && sd.inv[wi];
    check('a new weapon prefix on the server: new id, new prefix, gold taken', nw && sd.rerolled && nw.sid && nw.sid !== invA[wi].sid && nw.form && nw.form !== invA[wi].form && sd.gold === gA - 400,
      sd ? JSON.stringify({ g: sd.gold, f: nw && nw.form }) : JSON.stringify(A.find((m) => m.t === 'shopFail')));
    if (sd) { invA = sd.inv; gA = sd.gold; seqA = sd.seq; }
  }
  const gi = invA.findIndex((it) => it && it.rarity === 'gd');
  if (gi >= 0) {
    A.clear();
    A.send({ t: 'reroll', slot: gi, what: 'stats', data: withInv() });
    await wait(400);
    check('Godly items cannot be rerolled', A.find((m) => m.t === 'shopFail' && /cannot be rerolled/.test(m.msg)));
  }
  A.clear();
  A.send({ t: 'save', data: Object.assign(withInv(), { tradeSeq: 0 }) });
  await wait(450);
  check('a save from before a purchase (would undo it) is refused', A.find((m) => m.t === 'saveRejected' && /stale/.test(m.reason)));

  console.log('resume and log out');
  const A2 = await login(nameA, { token: tokenA });
  check('a remembered session logs back in', A2.id > 0);
  await wait(200);
  check('logging in elsewhere kicks the old connection', A.find((m) => m.t === 'kicked') || A.closed);
  const saved = A2.find((m) => m.t === 'welcome').save;
  check('the save comes back on login', saved && saved.chars && saved.chars[0].inv.some((it) => it && /^dg_/.test(it.sub)));

  console.log('worlds and relays');
  const wB = B.find((m) => m.t === 'welcome').save;
  B.send({ t: 'save', data: { gold: 3000, chars: [clone(wB.chars[0])] } });
  await wait(450);
  check("the other account's save is accepted too", !B.find((m) => m.t === 'saveRejected'));
  A2.send({ t: 'enter', key: 'nexus', x: 100, y: 100, cid: 'ca', profile: { cls: 'wizard', level: 20 } });
  B.send({ t: 'enter', key: 'nexus', x: 101, y: 100, cid: 'cb', profile: { cls: 'knight', level: 20 } });
  await wait(300);
  A2.clear();
  B.send({ t: 'move', x: 102, y: 100 });
  await wait(200);
  check('nearby movement is relayed', A2.find((m) => m.t === 'move' && m.id === B.id && !m.far));
  A2.clear();
  B.send({ t: 'move', x: 190, y: 100 });
  await wait(200);
  check('moving out of view sends "far" and no exact position',
    A2.find((m) => m.t === 'far' && m.id === B.id) && !A2.find((m) => m.t === 'move' && m.id === B.id && !m.far));
  B.send({ t: 'move', x: 101, y: 100 });
  await wait(200);
  A2.clear();
  B.send({ t: 'fx', k: 'fireball', x: 101, y: 100, tx: 105, ty: 100, n: 0 });
  await wait(150);
  check('ability casts are shown to nearby players', A2.find((m) => m.t === 'fx' && m.k === 'fireball'));
  A2.clear();
  await wait(350);
  B.send({ t: 'fx', k: '<script>', x: 1, y: 1 });
  await wait(150);
  check('unknown ability effects are dropped', !A2.find((m) => m.t === 'fx'));
  B.send({ t: 'raidOpen', name: 'The Conclave', color: 0xff3050 });
  await wait(150);
  check('raid openings are announced to everyone', A2.find((m) => m.t === 'banner' && /Conclave/.test(m.text)));
  A2.send({ t: 'tpreq', id: B.id });
  await wait(150);
  check('teleport to a stranger is refused', A2.find((m) => m.t === 'msg' && /party and guild/.test(m.text)));

  console.log('trades');
  A2.clear(); B.clear();
  A2.send({ t: 'tradeReq', to: B.id });
  await wait(150);
  B.send({ t: 'tradeAns', to: A2.id, yes: true });
  await wait(150);
  check('both sides get the trade window', A2.find((m) => m.t === 'tradeStart') && B.find((m) => m.t === 'tradeStart'));
  A2.send({ t: 'tradeInv', inv: [{ kind: 'armor', rarity: 'gd', name: 'Fake Godly' }] });
  await wait(150);
  check('a faked trade inventory is not shown to the partner', !B.find((m) => m.t === 'tradeStart' && JSON.stringify(m.inv).includes('Fake Godly')));
  A2.send({ t: 'tradeOffer', sel: [false], want: [] });
  B.send({ t: 'tradeOffer', sel: [true], want: [] });
  await wait(150);
  // B accepts A's first offer while A is already changing it
  B.send({ t: 'tradeAccept', seen: 1 });
  A2.send({ t: 'tradeOffer', sel: [true, false, false, true], want: [] });
  await wait(150);
  A2.send({ t: 'tradeAccept', seen: 1 });
  await wait(300);
  check('an accept for an older offer does not count', !A2.find((m) => m.t === 'tradeDone'));
  B.send({ t: 'tradeAccept', seen: 2 });
  await wait(300);
  const doneA = A2.find((m) => m.t === 'tradeDone'), doneB = B.find((m) => m.t === 'tradeDone');
  check('the trade completes on the server', doneA && doneB && doneA.inv && doneB.inv);
  const ringSid = invA[0] && invA[0].sid;
  if (doneA && doneB && doneA.inv && doneB.inv) {
    check('items moved: A gave its ring and dungeon key and got the potion', !doneA.inv.some((i) => i && i.sid === ringSid) && doneA.inv.some((i) => i && i.sid === wB.chars[0].inv[0].sid));
    check('B got the ring and the dungeon key', doneB.inv.some((i) => i && i.sid === ringSid) && doneB.inv.some((i) => i && i.sub === 'dg_crypt'));
  }
  const seq = doneA ? doneA.seq : 1;
  const saveA = (inv, sq) => { const d = goodA(); d.chars[0].inv = clone(inv); d.gold = gA; d.tradeSeq = sq; return d; };
  A2.clear();
  A2.send({ t: 'save', data: saveA(invA, 0) });
  await wait(450);
  check('a save from before the trade (dupe attempt) is refused', A2.find((m) => m.t === 'saveRejected' && /stale/.test(m.reason)));
  A2.clear();
  A2.send({ t: 'save', data: saveA(invA, seq) });
  await wait(450);
  check('keeping traded-away items in a save (modified client) is refused', A2.find((m) => m.t === 'saveRejected' && /traded away|does not belong/.test(m.reason)));
  A2.clear();
  A2.send({ t: 'save', data: saveA(doneA ? doneA.inv : [], seq) });
  await wait(450);
  check('the honest save after a trade is accepted', !A2.find((m) => m.t === 'saveRejected'), JSON.stringify(A2.find((m) => m.t === 'saveRejected')));

  console.log('server-run monsters');
  A2.send({ t: 'enter', key: 'dg:4:777', x: 100, y: 180, cid: 'ca' });
  B.send({ t: 'enter', key: 'dg:4:777', x: 100, y: 180, cid: 'cb' });
  await wait(300);
  A2.clear(); B.clear();
  A2.send({ t: 'w', to: 'host', d: { t: 'sync' } });
  await wait(300);
  const spawnMsg = A2.find((m) => m.t === 'w' && m.d.t === 'espawn');
  const mons = spawnMsg ? spawnMsg.d.l : [];
  check('the server fills a dungeon with its monsters (and its boss)', mons.length > 5 && mons.some((e) => e[9] === 1), mons.length + ' monsters');
  // B fakes a monster's death to everyone: ignored
  B.send({ t: 'w', to: 'all', d: { t: 'ekill', id: mons[0] && mons[0][0] } });
  await wait(200);
  check('players cannot fake monster deaths', !A2.find((m) => m.t === 'w' && m.d.t === 'ekill'));
  const target = mons.find((e) => !/crate|treasure/.test(e[1]) && e[9] !== 1);
  if (target) {
    A2.send({ t: 'move', x: target[2], y: target[3] + 1 });
    await wait(150);
    A2.clear(); B.clear();
    for (let k = 0; k < 30; k++) A2.send({ t: 'w', to: 'host', d: { t: 'ehit', id: target[0], d: 800 } });
    await wait(400);
    check('hits from a player kill a server monster, and everyone hears it', A2.find((m) => m.t === 'w' && m.d.t === 'ekill' && m.d.id === target[0]) && B.find((m) => m.t === 'w' && m.d.t === 'ekill' && m.d.id === target[0]));
    check('only the player who hit it can get its loot', !B.find((m) => m.t === 'w' && m.d.t === 'loot'));
    const lootMsg = A2.find((m) => m.t === 'w' && m.d.t === 'loot');
    check('server loot carries ids from the ledger', !lootMsg || lootMsg.d.l.every((it) => it.sid), lootMsg ? lootMsg.d.l.length + ' items' : 'no drop this time');
  }
  const boss = mons.find((e) => e[9] === 1);
  if (boss) {
    A2.send({ t: 'move', x: boss[2] + 60, y: boss[3] + 60 });
    await wait(150);
    A2.clear();
    for (let k = 0; k < 10; k++) A2.send({ t: 'w', to: 'host', d: { t: 'ehit', id: boss[0], d: 6000 } });
    await wait(300);
    check('hits from too far away are ignored', !A2.find((m) => m.t === 'w' && m.d.t === 'ekill' && m.d.id === boss[0]));
  }
  A2.send({ t: 'enter', key: 'nexus', x: 100, y: 100, cid: 'ca' });
  B.send({ t: 'enter', key: 'nexus', x: 101, y: 100, cid: 'cb' });
  await wait(200);

  console.log('ability items');
  {
    const { Data } = require('./sim/gen/game');
    const items = require('./items');
    const storm = Data.makeAbility('spell', 3, null, 'lightning');
    check('a Spell of Storms is a valid item', checkItem(storm) === null && storm.ab === 'lightning');
    check('an ability from another class is refused', checkItem(Object.assign({}, storm, { ab: 'wolf' })) !== null);
    check('changing which ability an item holds changes its fingerprint', items.fingerprint(storm) !== items.fingerprint(Object.assign({}, storm, { ab: 'frostnova' })));
    check('starter abilities still need no id', items.STARTERS.has(items.fingerprint(Data.makeAbility('spell', 0))));
  }

  console.log('raids');
  {
    const { WorldSim } = require('./sim/worldsim');
    for (const r of [0, 1]) {
      const ws = new WorldSim('raid:' + r + ':777');
      const got = [];
      const c = { id: 1, x: 100, y: 100, send: (m) => got.push(m.d) };
      ws.join(c);
      let err = null;
      try {
        for (let step = 0; step < 4000; step++) {
          ws.tick(0.05);
          if (step % 20) continue;
          for (const e of ws.enemies.slice()) { if (!e.dead && e.isBoss) { c.x = e.x; c.y = e.y + 2; ws.hit(c, { id: e.id, d: 6000 }); } }
        }
      } catch (e) { err = e.message; }
      check('raid ' + r + ': every stage starts and every wall opens', !err && got.filter((m) => m.t === 'rstage').length === 3 && ws.w.gates.every((g) => !g.length), err || '');
    }
  }

  console.log('boss set pieces');
  {
    const { WorldSim } = require('./sim/worldsim');
    const { Data } = require('./sim/gen/game');
    const ws = new WorldSim('realm:Test:4242');
    const got = [];
    const c = { id: 1, x: ws.w.spawnX, y: ws.w.spawnY, send: (m) => got.push(m.d || m) };
    ws.join(c);
    const bad = [];
    const all = Data.EVENTS.slice();
    for (const ev of Object.keys(Data.ENEMIES).filter((k) => Data.ENEMIES[k].setpiece)) {
      ws.w.eventT = 0; ws.w.eventsDone = 0; ws.closeT = 0; ws.w.closed = false; ws.w.recentEvents = [];
      Data.EVENTS.length = 0; Data.EVENTS.push(ev);
      try { ws.updateEvents(0.1); } finally { Data.EVENTS.length = 0; Data.EVENTS.push(...all); }
      const b = ws.w.boss;
      if (!b || b.defId !== ev) { bad.push(ev + ': no boss'); continue; }
      const sp = b.def.setpiece;
      c.x = b.x; c.y = b.y + 3;
      ws.tick(0.05);
      if (!b.props || b.props.length !== sp.n) { bad.push(ev + ': ' + (b.props ? b.props.length : 0) + ' pieces'); continue; }
      if (sp.ward) {
        ws.hit(c, { id: b.id, d: 1000 });
        if (b.hp < b.maxHp) bad.push(ev + ': hurt while warded');
        for (const p of b.props) { c.x = p.x; c.y = p.y + 2; for (let k = 0; k < 5; k++) ws.hit(c, { id: p.id, d: 1000 }); }
        ws.tick(0.05);
        if (b.invuln) bad.push(ev + ': still warded with its pieces gone');
      }
      got.length = 0;
      c.x = b.x; c.y = b.y + 2;
      for (let k = 0; k < 40 && !b.dead; k++) { b.invuln = false; b.shieldT = 0; ws.hit(c, { id: b.id, d: 6000 }); ws.tick(0.05); }
      if (!b.dead) bad.push(ev + ': boss did not die');
      else if (b.props.some((p) => !p.dead)) bad.push(ev + ': pieces left after the boss died');
      ws.tick(0.05);
    }
    check('every event boss brings its set piece, wards hold, and it all goes when the boss dies', !bad.length, bad.join('; '));
  }

  console.log('launcher downloads');
  {
    const get = (pathName) => new Promise((resolve) => {
      const s = net.connect(PORT, '127.0.0.1');
      const parts = [];
      s.on('data', (d) => parts.push(d));
      s.on('end', () => resolve(Buffer.concat(parts)));
      s.on('error', () => resolve(Buffer.alloc(0)));
      s.on('connect', () => s.write('GET ' + pathName + ' HTTP/1.1\r\nHost: localhost\r\n\r\n'));
    });
    const swf = await get('/NewRealm.swf?t=123');
    const at = swf.indexOf('\r\n\r\n');
    const body = at >= 0 ? swf.slice(at + 4) : Buffer.alloc(0);
    const sig = body.slice(0, 3).toString('latin1');
    check('the server hands out the latest game to the launcher', /^HTTP\/1\.1 200/.test(swf.toString('latin1', 0, 20)) &&
      (sig === 'FWS' || sig === 'CWS' || sig === 'ZWS') && body.length === fs.statSync(path.join(__dirname, '..', 'bin', 'NewRealm.swf')).size,
      swf.toString('latin1', 0, 40));
    const cd = (await get('/crossdomain.xml')).toString();
    check('and the cross-domain file Flash asks for', /allow-access-from domain="\*"/.test(cd));
  }

  console.log('bad input');
  const evil = await login('Ev' + n, { password: 'pass1234', register: true });
  evil.send('{{{ not json');
  evil.send('[1,2,3]');
  evil.send({ t: 'move' });
  evil.send({ t: 'enter' });
  evil.send({ t: 'fx' });
  evil.send({ t: 'tradeOffer', sel: 'x' });
  evil.send({ t: 'tradeAccept' });
  evil.send({ t: 'save', data: [] });
  evil.send({ t: 'save' });
  evil.send({ t: 'chat', text: { a: 1 } });
  evil.send({ t: 'w', to: 5, text: null });
  evil.send({ t: 'nonexistent' });
  for (let i = 0; i < 400; i++) evil.send({ t: 'ping', at: i });
  await wait(400);
  evil.clear();
  await wait(1100);
  evil.send({ t: 'ping', at: 7 });
  await wait(200);
  check('the server survives junk and floods, and still answers', evil.find((m) => m.t === 'pong' && m.at === 7));
  A2.clear();
  A2.send({ t: 'ping', at: 1 });
  await wait(200);
  check('other players are unaffected', A2.find((m) => m.t === 'pong'));

  const ws = await client();
  ws.s.write('GET / HTTP/1.1\r\nUpgrade: websocket\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n\r\n');
  await wait(150);
  const hdr = Buffer.from([0x81, 0xff, 0x40, 0, 0, 0, 0, 0, 0, 0]);
  ws.s.write(hdr);
  await wait(300);
  check('a websocket frame claiming a huge size is dropped at once', ws.closed);

  console.log('log out');
  A2.send({ t: 'logout', token: tokenA });
  await wait(250);
  const A3 = await login(nameA, { token: tokenA });
  check('a logged-out session can no longer log in', A3.find((m) => m.t === 'error'));

  if (process.argv[2]) {
    console.log('items from ' + process.argv[2]);
    const items = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
    let bad = 0;
    for (const it of items) {
      const why = checkItem(it);
      if (why) { bad++; if (bad <= 10) console.log('       refused: ' + (it.name || it.kind) + ': ' + why); }
    }
    check(items.length + ' items made by the game all pass the save checks', bad === 0, bad + ' refused');
    const why = checkSave({}, { chars: [{ inv: items.slice(0, 16), level: 20 }], vault: items.slice(0, 80) }, { lastSave: Date.now() }, Date.now());
    check('a save full of them is accepted', !why, why);
  }

  check('no errors in the server log', !/error handling|TypeError|ReferenceError/.test(srvOut), (srvOut.match(/.*error.*/i) || [''])[0]);
  for (const c of [A, A2, A3, B, old, dup, wrong, bad, evil, ws]) c.s.destroy();
  await new Promise((r) => { srv.on('exit', r); srv.kill(); });
  try { fs.rmSync(DATA, { recursive: true, force: true }); } catch (e) {}
  console.log('\n' + passed + ' passed, ' + failed + ' failed');
  process.exit(failed ? 1 : 0);
}

run().catch((e) => { console.error(e); fs.rmSync(DATA, { recursive: true, force: true }); process.exit(1); });
