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
  // a stand-in for Discord: collects what the server posts to its webhook
  const posts = [];
  const hook = require('http').createServer((q, r) => { let b = ''; q.on('data', (d) => { b += d; }); q.on('end', () => { try { posts.push(JSON.parse(b)); } catch (e) {} r.writeHead(204); r.end(); }); });
  await new Promise((r) => hook.listen(0, '127.0.0.1', r));
  const hookUrl = 'http://127.0.0.1:' + hook.address().port + '/api/webhooks/1/x';
  fs.writeFileSync(path.join(DATA, 'config.json'), JSON.stringify({ admins: ['TestBoss'], motd: 'test', discordWebhook: hookUrl }));
  const srv = spawn(process.execPath, [path.join(__dirname, 'server.js'), String(PORT)], {
    env: Object.assign({}, process.env, { NEWREALM_DATA: DATA, NEWREALM_CONFIG: path.join(DATA, 'config.json') }), stdio: ['ignore', 'pipe', 'pipe']
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
  // B finished today's first quest already (kept by the server, in _quests)
  const Q = require('./quests');
  const qsv = {};
  const qst = Q.state(qsv);
  const { Data: QD } = require('./sim/gen/game');
  qst.d[0].p = QD.quest(qst.d[0].id).goal;
  const questReward = QD.quest(qst.d[0].id);
  fs.writeFileSync(path.join(DATA, 'saves', nameB.toLowerCase() + '.json'), JSON.stringify({ gold: 3000, chars: [charSave('cb', [ITEMS.potion])], _quests: qsv._quests }));
  // C has fame to spend in the Fame Store
  fs.writeFileSync(path.join(DATA, 'saves', ('Tc' + n).toLowerCase() + '.json'), JSON.stringify({ fame: 1000, chars: [] }));
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
  const boss0 = await login('TestBoss', { password: 'pass1234', register: true });
  const bossWelcome = boss0.find((m) => m.t === 'welcome');

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
  const rej = A.find((m) => m.t === 'saveRejected');
  check('a refused save sends back the last good save (without the ledger)', rej && rej.data && rej.data.gold === 5000 && !rej.data._ledger);
  A.clear();
  { const d = goodA(); d.gold = 99999999; A.send({ t: 'save', data: d }); }
  await wait(450);
  const cut = A.find((m) => m.t === 'wallet');
  check('gold jumping by millions is cut back to what was earned (the game is told)', cut && cut.gold <= 5000 + 500 && !A.find((m) => m.t === 'saveRejected'), JSON.stringify(cut));
  await tryA((d) => { d.chars[0].inv[5] = { kind: 'sword?', name: 'x' }; }, /unknown item kind/, 'unknown item kinds are refused');
  A.clear();
  for (let i = 1; i <= 4; i++) { const d = goodA(); d.gold = 5000 + i * 100000; A.send({ t: 'save', data: d }); await wait(450); }
  const cuts = A.msgs.filter((m) => m.t === 'wallet');
  check('repeated gold jumps never add up to more than was earned', cuts.length === 4 && cuts.every((m) => m.gold <= 5000 + 505 && m.gold === Math.floor(m.gold)), cuts.map((m) => m.gold).join(','));
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
  check('the Marketplace sells through the server: the item has an id and the gold is taken', bought && sd.gold === 5000 - 1200, sd ? sd.gold : 'no reply');
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
  A.send({ t: 'buy', what: 'key', dg: 12, data: withInv() });
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

  console.log('classes');
  {
    const { Data, Godly } = require('./sim/gen/game');
    const items = require('./items');
    const missing = [];
    for (const id of Data.CLASS_ORDER) {
      const c = Data.CLASSES[id];
      if (!c) { missing.push(id + ': no class'); continue; }
      for (const t of ['base', 'l20', 'max']) for (const st of Data.STATS) if (typeof c[t][st] !== 'number') missing.push(id + ' ' + t + '.' + st);
      if (!Data.SETS[id]) missing.push(id + ': Bonded set');
      if (!Godly.SETS[id]) missing.push(id + ': Godly set');
      if (!Data.SKINS[id] || !Data.SKINS[id].length) missing.push(id + ': skins');
      if (!Data.DYE_KEYS[id]) missing.push(id + ': dye keys');
      const abs = Data.ABILITY_SETS[c.abilityType] || [];
      if (abs.length !== 3 || !abs.every((a) => Data.ABILITIES[a] && Data.ABILITIES[a].type === c.abilityType)) missing.push(id + ': abilities');
      if (!Data.ABILITY_NAMES[c.abilityType] || Data.ABILITY_NAMES[c.abilityType].length !== 7) missing.push(id + ': ability names');
      for (const a of abs) if (!Data.abilityText(Data.makeAbility(c.abilityType, 3, null, a))) missing.push(id + ': ' + a + ' tooltip');
      if (!items.STARTERS.has(items.fingerprint(Data.makeAbility(c.abilityType, 0)))) missing.push(id + ': starter ability');
      if (!Object.values(Godly.DROPS).some((l) => l.some((d) => d[0] === id))) missing.push(id + ': Godly drops');
    }
    check('all ' + Data.CLASS_ORDER.length + ' classes are complete (stats, sets, skins, dyes, 3 abilities, tooltips, starter gear)', missing.length === 0, missing.join('; '));
    check('Eldmere\'s own classes unlock by playing', !Data.classUnlocked('chronomancer', { wizard: 20, priest: 20 }) && Data.classUnlocked('chronomancer', { wizard: 20, priest: 20, rogue: 20 }) &&
      Data.classUnlocked('bard', { knight: 12 }) && !Data.classUnlocked('alchemist', { knight: 19 }) && Data.classUnlocked('wizard', {}));
  }

  console.log('raids');
  {
    const { WorldSim } = require('./sim/worldsim');
    for (const r of [0, 1, 2]) {
      const ws = new WorldSim('raid:' + r + ':777');
      const arenas = [];
      const got = [];
      const themes = [];
      const c = { id: 1, x: 100, y: 100, maxDps: 1e9, send: (m) => got.push(m.d) };
      ws.join(c);
      let err = null;
      try {
        for (let step = 0; step < 4000; step++) {
          ws.tick(0.05);
          if (step % 20) continue;
          for (const e of ws.enemies.slice()) {
            if (!e.dead && e.isBoss && e.arena && arenas.indexOf(e.defId) < 0) { arenas.push(e.defId); themes.push(ws.w.tiles[188 * ws.w.N + 101]); }
            if (!e.dead && (e.isBoss || e.def.prop)) { c.x = e.x; c.y = e.y + 2; ws.hit(c, { id: e.id, d: 6000 }); }
          }
        }
      } catch (e) { err = e.message; }
      const nst = ws.w.raid.stages.length;
      check('raid ' + r + ' (' + ws.w.raid.name + '): every stage starts and every wall opens', !err && got.filter((m) => m.t === 'rstage').length === nst && ws.w.gates.every((g) => !g.length), err || '');
      if (r === 2) check('the Starfall Vault: every chamber raises its set piece, and the Star Throne changes three times',
        arenas.length === 4 && got.filter((m) => m.t === 'sphase' && m.go).length >= 3 + 2 + 1 + 1, arenas.join(',') + ' / ' + got.filter((m) => m.t === 'sphase' && m.go).length);
      if (r === 2) check('each Vault master remakes the whole dungeon in its style (even the entrance hall)',
        new Set(themes).size === 4 && themes.every((t) => t !== 9), themes.join(','));
    }
  }

  console.log('pacing and boss scaling');
  {
    const { WorldSim } = require('./sim/worldsim');
    const { Data: PD } = require('./sim/gen/game');
    // a hacked game sending huge hits as fast as it can is held to what its gear can do
    const ws = new WorldSim('dg:6:777');
    const boss = ws.w.boss;
    boss.maxHp = boss.hp = 1e7;
    const cheat = { id: 3, x: boss.x, y: boss.y + 1, maxDps: 8000, send: () => {} };
    ws.join(cheat);
    const hp0 = boss.hp, t0 = Date.now();
    for (let i = 0; i < 300; i++) ws.hit(cheat, { id: boss.id, d: 6000 });
    const dealt = hp0 - boss.hp, secs = (Date.now() - t0) / 1000;
    // (a slow machine takes longer over the 300 hits, and the budget refills meanwhile)
    check('damage is capped by what the hero\'s own gear can deal (300 hits of 6,000 at once)', dealt <= 8000 * (3 + secs) + 20000 && cheat.dpsCut > 0, Math.round(dealt) + ' dealt in ' + secs + 's');
    // bosses grow with the players fighting them, not with everyone in the world
    const rw = new WorldSim('dg:6:778');
    const rb = rw.w.boss;
    const solo = rb.maxHp;
    for (let i = 0; i < 4; i++) rw.join({ id: 10 + i, x: rb.x + i, y: rb.y + 2, send: () => {} });
    rw.join({ id: 20, x: rb.x + 200, y: rb.y + 200, send: () => {} });
    rw.scaleT = 0; rw.scaleBosses(0.1);
    check('a boss scales with the players fighting it (4 near, 1 far away: 4 counted)', rb.scalePlayers === 4 && rb.maxHp > solo * 2.4, rb.scalePlayers + ' / ' + Math.round(rb.maxHp / solo * 100) + '%');
    const total = (() => { let t = 0; for (let l = 1; l < 20; l++) t += 40 + l * 45 + l * l * 3; return t; })();
    check('reaching level 20 takes a real climb (' + total + ' XP)', total > 15000 && PD.SHOP.find((x) => x.id === 'stat').price >= 1200);
  }

  console.log('godmode checks');
  {
    const { WorldSim } = require('./sim/worldsim');
    const { godmodeVerdict } = require('./godmode');
    // a player standing in the open next to a pack of monsters: the server sees shots land on them
    const ws = new WorldSim('dg:6:31');
    const room = ws.w.rooms[2] || ws.w.rooms[1];
    const me = { id: 9, x: room.x + 0.5, y: room.y + 0.5, maxDps: 1e9, send: () => {} };
    ws.join(me);
    for (let i = 0; i < 400; i++) ws.tick(0.05);
    check('the server follows monster shots and counts the clean hits a player should take', (me.expHits || 0) > 0, String(me.expHits));
    const before = me.expHits || 0;
    me.grace = Date.now() + 60000;
    for (let i = 0; i < 200; i++) ws.tick(0.05);
    check('no hits are expected while a shield wall, Time Stop or a dash protects you', (me.expHits || 0) === before);
    check('taking almost none of many clean hits is flagged, then kicked; honest dodging is not',
      godmodeVerdict(35, 1) === 'flag' && godmodeVerdict(80, 2) === 'kick' && godmodeVerdict(80, 20) === '' && godmodeVerdict(10, 0) === '');
  }

  console.log('monster families');
  {
    const { WorldSim } = require('./sim/worldsim');
    const { Data: FD } = require('./sim/gen/game');
    const E = FD.ENEMIES;
    check('goblins throw daggers that come back; golems slam the ground; spiders spit webs',
      E.goblin.attacks.some((a) => a.motion === 'return' && a.spin) && E.golem.attacks.some((a) => a.p === 'nova' && a.reach === 0 && a.burst > 0)
      && E.spider.attacks.some((a) => a.web > 0 && a.eff === 'slowed') && !E.golem.attacks.some((a) => a.p === 'ring'));
    const ws = new WorldSim('realm:1');
    const slime = ws.spawn('slime', ws.w.spawnX + 30, ws.w.spawnY, 1, true);
    const before = ws.enemies.filter((e) => !e.dead && e.defId === 'slimelet').length;
    ws.kill(slime);
    const after = ws.enemies.filter((e) => !e.dead && e.defId === 'slimelet').length;
    check('slimes split into slimelets when they die (and those drop nothing)', after > before && E.slimelet.drop === 0 && !E.slimelet.splits, before + ' -> ' + after);
    // a ghost drifts into a wall where nothing else could stand; its shots fly through walls
    let wx = -1, wy = -1;
    for (let y = 10; y < ws.w.N - 10 && wx < 0; y++) for (let x = 10; x < ws.w.N - 10; x++) if (!ws.w.walkable(x + 0.5, y + 0.5) && ws.w.canFloat(x + 0.5, y + 0.5, 0.3)) { wx = x + 0.5; wy = y + 0.5; break; }
    const ghost = ws.spawn('ghost', wx, wy, 3, true);
    check('ghosts drift through walls and their shots pass through them', wx > 0 && E.ghost.ghostly && E.ghost.attacks.every((a) => a.ghost) && ws.w.canFloat(wx, wy, 0.3) && !ws.w.canStand(wx, wy, 0.3, true) && ghost);
  }

  console.log('weekly vault twists');
  {
    const { WorldSim } = require('./sim/worldsim');
    const { Bosses: VB } = require('./sim/gen/game');
    const vi = VB.RAIDS.findIndex((r) => r.id === 'starfall');
    const run = (twistId) => {
      const ws = new WorldSim('raid:' + vi + ':99');
      ws.twist = VB.VAULT_TWISTS.find((t) => t.id === twistId);
      ws.enemies.length = 0;
      ws.populateRaid();
      const guards = ws.enemies.length;
      ws.w.raidT = 0; ws.updateRaid(0.1);
      return { ws, guards, master: ws.w.boss, all: ws.enemies.length };
    };
    const plain = new WorldSim('raid:' + vi + ':99');
    check('the Vault has a rule each week, the same for the whole week', VB.VAULT_TWISTS.length >= 5 && plain.twist && plain.twist === VB.vaultTwist(plain.week) && VB.vaultTwist(plain.week + 1) !== plain.twist);
    const swarm = run('swarm'), glass = run('glass'), quick = run('quick'), escort = run('escort'), stone = run('stone');
    check('Swarming Halls: twice the guards', swarm.guards >= 1.7 * glass.guards, swarm.guards + ' vs ' + glass.guards);
    check('Glass Vault: less health, harder hits; Quickened Sands: faster attacks', glass.master.maxHp < stone.master.maxHp && glass.master.dmgMult > 1.3 && quick.master.rateMult === 1.25);
    check('Honour Guard: guards wake at the master\'s side', escort.all - escort.guards >= 1 + 4);
    const feats = [];
    const ws = escort.ws;
    ws.onQuest = () => {}; ws.onFeat = (k, d) => feats.push([k, d]);
    ws.players.set(1, { id: 1, name: 'Hero', x: 0, y: 0 });
    ws.w.raidStage = ws.w.raid.stages.length - 1;
    ws.w.raidStart = Date.now() - 300000;
    const fin = { def: { name: 'Astraeon', raid: true }, isBoss: true, hitters: new Map([[1, 100]]), defId: 'astraeon' };
    ws.enemies.length = 0; ws.enemies.push(fin);
    ws.questKill(fin);
    const rf = feats.find(([k]) => k === 'raid');
    check('a Vault clear is timed for the week\'s board', rf && rf[1].ms >= 300000 && rf[1].week === ws.week && rf[1].twist === 'Honour Guard');
  }

  console.log('boss set pieces');
  {
    const { WorldSim } = require('./sim/worldsim');
    const { Data, SetPieces } = require('./sim/gen/game');
    const ws = new WorldSim('realm:Test:4242');
    const got = [];
    const c = { id: 1, x: ws.w.spawnX, y: ws.w.spawnY, maxDps: 1e9, send: (m) => got.push(m.d || m) };
    ws.join(c);
    const bad = [];
    const kills = [];
    ws.onEventKill = (id, ms, team) => kills.push({ id, ms, team });
    c.name = 'Tester';
    const all = Data.EVENTS.slice();
    for (const ev of Object.keys(Data.ENEMIES).filter((k) => Data.ENEMIES[k].setpiece && Data.EVENTS.indexOf(k) >= 0)) {
      ws.w.eventT = 0; ws.w.eventsDone = 0; ws.closeT = 0; ws.w.closed = false; ws.w.recentEvents = [];
      const before = Array.from(ws.w.tiles).join(',') + '|' + Array.from(ws.w.objs).join(',');
      Data.EVENTS.length = 0; Data.EVENTS.push(ev);
      try { ws.updateEvents(0.1); } finally { Data.EVENTS.length = 0; Data.EVENTS.push(...all); }
      const b = ws.w.boss;
      if (!b || b.defId !== ev) { bad.push(ev + ': no boss'); continue; }
      const sp = b.def.setpiece;
      c.x = b.x; c.y = b.y + 3;
      ws.tick(0.05);
      if (!b.props || b.props.length !== sp.n) { bad.push(ev + ': ' + (b.props ? b.props.length : 0) + ' pieces'); continue; }
      got.length = 0;
      if (!b.arena || b.arena.length < 150) bad.push(ev + ': no structure laid down');
      for (const p of b.props) if (!ws.w.canStand(p.x, p.y, 0.3, true)) bad.push(ev + ': a piece stands in a wall');
      if (sp.ward) {
        ws.hit(c, { id: b.id, d: 1000 });
        if (b.hp < b.maxHp) bad.push(ev + ': hurt while warded');
        for (const p of b.props) { c.x = p.x; c.y = p.y + 2; for (let k = 0; k < 5; k++) ws.hit(c, { id: p.id, d: 1000 }); }
        ws.tick(0.05);
        if (b.invuln) bad.push(ev + ': still warded with its pieces gone');
      }
      // the arena changes mid-fight: break every piece, bring the boss low, wait out the warning
      const phs = SetPieces.phasesOf(ev);
      for (let k = 0; k < phs.length; k++) if (!SetPieces.phaseCells(ev, b.arena, k).length) bad.push(ev + ': phase ' + k + ' changes nothing');
      for (const p of b.props) if (!p.dead) { c.x = p.x; c.y = p.y + 2; for (let k = 0; k < 5; k++) ws.hit(c, { id: p.id, d: 1000 }); }
      c.x = b.x; c.y = b.y + 2;
      b.hp = b.maxHp * 0.25;
      const mid = Array.from(ws.w.tiles).join(',') + '|' + Array.from(ws.w.objs).join(',');
      for (let k = 0; k < 150; k++) { b.hp = Math.min(b.hp, b.maxHp * 0.25); ws.tick(0.05); }
      const warns = got.filter((m) => m.t === 'sphase' && m.w > 0).length, goes = got.filter((m) => m.t === 'sphase' && m.go).length;
      if (warns !== phs.length || goes !== phs.length) bad.push(ev + ': ' + warns + ' warnings and ' + goes + ' changes for ' + phs.length + ' phases');
      else if (phs.length && Array.from(ws.w.tiles).join(',') + '|' + Array.from(ws.w.objs).join(',') === mid) bad.push(ev + ': its phases changed no tiles');
      const born = [].concat(...got.filter((m) => m.t === 'espawn').map((m) => m.l));
      for (const ph of phs) if (ph.spawn && born.filter((en) => en[1] === ph.spawn).length < ph.n) bad.push(ev + ': too few ' + ph.spawn + ' came out');
      if (phs.length && !(b.spMask > 0)) bad.push(ev + ': phases not marked for late arrivals');
      got.length = 0;
      for (let k = 0; k < 40 && !b.dead; k++) { b.invuln = false; b.shieldT = 0; ws.hit(c, { id: b.id, d: 6000 }); ws.tick(0.05); }
      if (!b.dead) bad.push(ev + ': boss did not die');
      else if (b.props.some((p) => !p.dead)) bad.push(ev + ': pieces left after the boss died');
      else if (Array.from(ws.w.tiles).join(',') + '|' + Array.from(ws.w.objs).join(',') !== before) bad.push(ev + ': the ground was not put back');
      ws.tick(0.05);
    }
    const evCount = Object.keys(Data.ENEMIES).filter((k) => Data.ENEMIES[k].setpiece && Data.EVENTS.indexOf(k) >= 0).length;
    check('every event kill reaches the records with its time and team', kills.length === evCount && kills.every((k) => k.ms >= 0 && k.team.length === 1 && k.team[0].name === 'Tester'),
      kills.length + ' of ' + evCount);
    check('every event boss raises its set piece, wards hold, its arena changes mid-fight, and it all goes (ground restored) when the boss dies', !bad.length, bad.join('; '));
  }

  console.log('quests');
  {
    const Q2 = require('./quests');
    const { Data: D2 } = require('./sim/gen/game');
    // the module: counting, finishing, claiming once, a new day
    const sv = {}, day1 = Date.UTC(2026, 9, 8, 12), day2 = Date.UTC(2026, 9, 9, 1);
    const st = Q2.state(sv, day1);
    const goals = st.d.map((x) => D2.quest(x.id));
    const evOf = (x, def) => def.ev === 'event' ? 'event:' + x.arg : def.ev;
    const evs = [];
    for (let k = 0; k < goals[0].goal; k++) evs.push(evOf(st.d[0], goals[0]));
    const done = Q2.progress(sv, evs, day1);
    check('a quest finishes when the server counts enough', done && done.length >= 1 && sv._quests.d[0].p === goals[0].goal);
    check('an unfinished quest cannot be claimed', typeof Q2.claim(sv, false, 1, day1) === 'string' || sv._quests.d[1].p >= goals[1].goal);
    const r = Q2.claim(sv, false, 0, day1);
    check('a finished quest pays its gold and Aether once', typeof r === 'object' && sv.gold === (goals[0].gold || 0) && sv.onrane === (goals[0].onrane || 0) &&
      typeof Q2.claim(sv, false, 0, day1) === 'string');
    Q2.state(sv, day2);
    check('a new day brings new quests', sv._quests.day === '2026-10-09' && sv._quests.d.every((x) => x.p === 0 && !x.c));
    check('everyone gets the same quests on the same day', JSON.stringify(D2.dailyQuests('2026-10-08')) === JSON.stringify(D2.dailyQuests('2026-10-08')) &&
      D2.dailyQuests('2026-10-08').length === 3 && new Set(D2.dailyQuests('2026-10-08').map((x) => x.id)).size === 3);
    // the simulation reports kills to the quest keeper
    const { WorldSim } = require('./sim/worldsim');
    const ws = new WorldSim('realm:Quest:99');
    const seen = [];
    ws.onQuest = (c, e) => seen.push(...e);
    const cq = { id: 7, x: ws.w.spawnX, y: ws.w.spawnY, maxDps: 1e9, send: () => {} };
    ws.join(cq);
    const mob = ws.spawn('orc', cq.x + 3, cq.y, 2, true);
    if (mob) { cq.x = mob.x; cq.y = mob.y + 2; for (let k = 0; k < 40 && !mob.dead; k++) ws.hit(cq, { id: mob.id, d: 6000 }); }
    check('the server counts your kills for quests', seen.includes('kills'), seen.join(','));
    // over the wire: B's finished quest
    B.clear();
    B.send({ t: 'quests' });
    await wait(300);
    const qv = B.find((m) => m.t === 'quests');
    check('the server sends your quests (3 daily and a weekly)', qv && qv.q.list.length === 4 && qv.q.list.filter((x) => x.weekly).length === 1);
    B.clear();
    B.send({ t: 'questClaim', w: 0, i: 0 });
    await wait(400);
    const qd = B.find((m) => m.t === 'questDone');
    check('claiming a finished quest pays out on the server', qd && qd.gold >= 3000 + (questReward.gold || 0) && qd.got.gold === (questReward.gold || 0), JSON.stringify(qd || B.find((m) => m.t === 'shopFail')));
    B.clear();
    B.send({ t: 'questClaim', w: 0, i: 0 });
    await wait(300);
    check('the same quest cannot be claimed twice', !B.find((m) => m.t === 'questDone') && B.find((m) => m.t === 'shopFail'));
    B.clear();
    B.send({ t: 'questClaim', w: 1, i: 0 });
    await wait(300);
    check('an unfinished weekly quest cannot be claimed', !B.find((m) => m.t === 'questDone'));
  }

  console.log('records');
  {
    A2.clear();
    A2.send({ t: 'records' });
    await wait(300);
    const r = A2.find((m) => m.t === 'records');
    check('the server answers a Records request', r && typeof r.r === 'object');
    check('...with this month\'s season ladder', r && r.season && /^Season \d+: /.test(r.season.name) && Array.isArray(r.season.top) && r.season.ends > Date.now());
  }

  console.log('seasons');
  {
    const season = require('./season');
    const { Data: SD } = require('./sim/gen/game');
    const oct = season.seasonAt(Date.UTC(2026, 9, 20)), nov = season.seasonAt(Date.UTC(2026, 10, 1));
    check('one season a month, numbered from October 2026', oct.id === '2026-10' && oct.n === 1 && nov.n === 2 && oct.ends === nov.start && oct.name !== nov.name);
    const tables = {};
    const L = new season.Ladder((f, fb) => tables[f] || fb, (f, o) => { tables[f] = JSON.parse(JSON.stringify(o)); });
    L.t.id = '2026-10';
    L.heroesDied('ann', 'Ann', 1000, [{ fame: 900, seasonal: false, cls: 'wizard', level: 20 }]);
    L.heroesDied('bo', 'Bo', 1000, [{ fame: 900, seasonal: true, cls: 'bard', level: 18 }]);
    L.heroesDied('cy', 'Cy', 0, [{ fame: 900, seasonal: true }]);
    const v = L.view('ann');
    check('dead heroes put their fame on the ladder, Seasonal heroes double', v.top[0].name === 'Bo' && v.top[0].pts === 2000 && v.top[1].pts === 1000 && v.you.place === 2 && v.top.length === 2);
    const won = [];
    let told = null;
    L.rollover(Date.UTC(2026, 10, 2), (key, place) => won.push(key + place), (old) => { told = old; });
    check('a new month closes the ladder: the top ten earn rewards and Discord hears who won',
      won.join() === 'bo1,ann2' && told && told.top[0].name === 'Bo' && L.t.id === '2026-11' && !Object.keys(L.t.scores).length && L.view('x').last.name === oct.name);
    check('season rewards are earned titles and dyes the game knows', ['season_champion', 'season_podium', 'season_top10'].every((id) => SD.findTitle(id) && SD.findTitle(id).earn)
      && SD.findDye('dye_laurel').earn && SD.findDye('dye_champion').earn && season.rewardsFor(1).length === 5 && season.rewardsFor(7).length === 2 && !season.rewardsFor(11).length);
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

  console.log('marketplace');
  {
    // B sells the potion from its first slot; A (A2) buys it
    B.send({ t: 'enter', key: 'nexus', cid: 'cb', x: 100, y: 100, profile: {} });
    A2.send({ t: 'enter', key: 'nexus', cid: 'ca', x: 100, y: 100, profile: {} });
    await wait(300);
    B.clear();
    B.send({ t: 'mkList', slot: 0, price: 500 });
    await wait(300);
    const listed = B.find((m) => m.t === 'shopDone');
    const bView = B.find((m) => m.t === 'market');
    const lst = bView && bView.m.list.find((l) => l.mine);
    check('a player can list an item (it leaves their inventory)', listed && listed.inv[0] === null && lst && lst.price === 500, JSON.stringify(B.find((m) => m.t === 'shopFail')));
    B.clear();
    B.send({ t: 'mkBuy', id: lst ? lst.id : 0 });
    await wait(250);
    check('nobody can buy their own listing', B.find((m) => m.t === 'shopFail') && !B.find((m) => m.t === 'shopDone'));
    A2.clear();
    A2.send({ t: 'mkView' });
    await wait(250);
    const aView = A2.find((m) => m.t === 'market');
    const forA = aView && aView.m.list.find((l) => lst && l.id === lst.id);
    check('other players see it for sale, with the seller', forA && !forA.mine && forA.seller === nameB);
    A2.clear(); B.clear();
    A2.send({ t: 'mkBuy', id: lst ? lst.id : 0 });
    await wait(300);
    const bought = A2.find((m) => m.t === 'shopDone');
    check('buying takes the gold and puts the item in the buyer\'s inventory', bought && bought.inv.some((it) => it && it.name === ITEMS.potion.name) && /Bought/.test(bought.market),
      JSON.stringify(A2.find((m) => m.t === 'shopFail')));
    check('the seller is told it sold', B.find((m) => m.t === 'msg' && /bought your/.test(m.text)));
    // selling to the Nexus merchant goes through the server, which pays
    const si = bought ? bought.inv.findIndex((it) => it && it.kind) : -1;
    if (si >= 0) {
      const { Data: SD } = require('./sim/gen/game');
      const worth = SD.sellValue(bought.inv[si]);
      A2.clear();
      A2.send({ t: 'sell', slot: si });
      await wait(300);
      const sold = A2.find((m) => m.t === 'shopDone');
      check('selling to the merchant: the server takes the item and pays its value', sold && sold.sold && sold.inv[si] === null && sold.gold === bought.gold + worth,
        JSON.stringify(sold || A2.find((m) => m.t === 'shopFail')));
    }
    A2.clear();
    A2.send({ t: 'mkBuy', id: lst ? lst.id : 0 });
    await wait(250);
    check('a sold item can\'t be bought twice', A2.find((m) => m.t === 'shopFail') && !A2.find((m) => m.t === 'shopDone'));
    B.clear();
    B.send({ t: 'mkView' });
    await wait(250);
    const bv2 = B.find((m) => m.t === 'market');
    check('the seller\'s takings wait for them (minus the 5% fee)', bv2 && bv2.m.earned === 475);
    B.clear();
    B.send({ t: 'mkCollect' });
    await wait(300);
    const col = B.find((m) => m.t === 'shopDone');
    check('collecting adds the takings to the seller\'s gold', col && /Collected 475 gold/.test(col.market));
    // the bought item really is the buyer's now: a save holding it is accepted
    const { Market } = require('./market');
    const items = require('./items');
    const tables = {};
    const mk = new Market((f, d) => tables[f] || d, (f, o) => { tables[f] = o; });
    const S1 = {}, S2 = { gold: 100 };
    const pot = items.issue(S1, { kind: 'stat', sub: 'att', name: 'Potion of Attack' });
    const inv1 = [pot], inv2 = [null];
    const l2 = mk.list(S1, 's1', 'One', inv1, 0, 50);
    check('a cancelled listing comes back to its seller', mk.cancel(S1, 's1', inv1, l2.id) && inv1[0] === pot && !items.check(S1, { chars: [{ inv: inv1 }] }));
    const l3 = mk.list(S1, 's1', 'One', inv1, 0, 50);
    mk.buy(S2, 's2', inv2, l3.id, S1);
    check('a bought item passes the buyer\'s item checks (and not the seller\'s)', !items.check(S2, { chars: [{ inv: inv2 }] }) && !!items.check(S1, { chars: [{ inv: [pot] }] }));
    const l4 = mk.list(S2, 's2', 'Two', inv2, 0, 10);
    l4.at -= 8 * 86400000;
    mk.expire((k) => (k === 's2' ? S2 : null));
    const back = Market.collect(S2, inv2);
    check('listings come back after a week, to collect', back.items === 1 && inv2[0] === pot && mk.data.list.length === 0);
  }

  console.log('movement');
  {
    const { WorldSim } = require('./sim/worldsim');
    const key = 'realm:MoveTest:4242';
    const w = new WorldSim(key).w;
    // a spot with open ground, something solid one tile east, and open ground again past it
    let spot = null;
    for (let y = 60; y < w.N - 60 && !spot; y++) for (let x = 60; x < w.N - 60 && !spot; x++) {
      if (w.walkable(x + 0.5, y + 0.5) && w.walkable(x - 0.5, y + 0.5) && w.walkable(x - 1.5, y + 0.5) && !w.walkable(x + 1.5, y + 0.5) && w.walkable(x + 2.5, y + 0.5)) spot = [x + 0.5, y + 0.5];
    }
    check('found a test spot beside a wall or tree', !!spot);
    if (spot) {
      const [sx, sy] = spot;
      B.send({ t: 'enter', key, x: sx, y: sy, profile: {} });
      await wait(300);
      B.clear();
      B.send({ t: 'move', x: sx - 0.4, y: sy });
      await wait(200);
      check('an ordinary step is allowed', !B.find((m) => m.t === 'pos'));
      B.send({ t: 'move', x: sx, y: sy });
      await wait(150);
      B.clear();
      B.send({ t: 'move', x: sx + 2, y: sy });
      await wait(200);
      const back = B.find((m) => m.t === 'pos');
      check('walking through a wall or tree is refused (put back)', back && Math.abs(back.x - sx) < 0.01);
      B.clear();
      B.send({ t: 'move', x: sx - 30, y: sy });
      await wait(200);
      check('a 30-tile jump is refused', B.find((m) => m.t === 'pos'));
      // walking at an honest pace keeps working
      B.clear();
      for (let k = 1; k <= 8; k++) { B.send({ t: 'move', x: sx - k * 0.15, y: sy }); await wait(100); }
      check('walking along at a normal speed is never refused', !B.find((m) => m.t === 'pos'));
      // a speed hack: many quick steps far faster than anyone can go
      B.clear();
      let x = sx - 1.2;
      for (let k = 0; k < 12; k++) { x -= 3; B.send({ t: 'move', x, y: sy }); await wait(40); }
      await wait(150);
      check('moving far faster than anyone can is refused', B.find((m) => m.t === 'pos'));
      B.send({ t: 'enter', key: 'nexus', x: 100, y: 100, profile: {} });
      await wait(150);
    }
  }

  console.log('restart countdown');
  {
    const get = (pathName) => new Promise((resolve) => {
      const s = net.connect(PORT, '127.0.0.1');
      const parts = [];
      s.on('data', (d) => parts.push(d));
      s.on('end', () => resolve(Buffer.concat(parts).toString()));
      s.on('error', () => resolve(''));
      s.on('connect', () => s.write('GET ' + pathName + ' HTTP/1.1\r\nHost: localhost\r\n\r\n'));
    });
    B.clear();
    const r = await get('/restart?m=3');
    await wait(300);
    const rin = B.find((m) => m.t === 'restartIn');
    check('the VPS can start a restart countdown, and players are told', /Restarting in 3/.test(r) && rin && rin.s > 170 && rin.s <= 180, r.split('\r\n\r\n')[1]);
    B.clear();
    const r2 = await get('/restart?m=cancel');
    await wait(300);
    check('a restart can be called off (players are told)', /cancelled/.test(r2) && B.find((m) => m.t === 'restartIn' && m.s === -1));
    B.clear();
    B.send({ t: 'cmd', text: '/restart 1' });
    await wait(300);
    check('players who are not admins cannot restart the server', B.find((m) => m.t === 'note' || m.t === 'msg') && !B.find((m) => m.t === 'restartIn'));
    // no new event bosses once the restart is close
    const { WorldSim } = require('./sim/worldsim');
    const ws = new WorldSim('realm:Restart:5');
    ws.w.eventT = 0;
    WorldSim.restartSoon = true;
    ws.updateEvents(0.1);
    const noneSoon = !ws.w.boss;
    WorldSim.restartSoon = false;
    for (let k = 0; k < 20 && !ws.w.boss; k++) { ws.w.eventT = 0; ws.updateEvents(0.1); }
    check('no new realm events start just before a restart', noneSoon && !!ws.w.boss);
  }

  console.log('guild hall');
  {
    const hall = require('./guildhall');
    const itemsMod = require('./items');
    const { Data: GD } = require('./sim/gen/game');
    const wk = hall.weekOf();
    const goals = hall.goalsFor(wk);
    check('three different guild goals a week, changing week to week', goals.length === 3 && new Set(goals).size === 3 && hall.goalsFor(wk + 1).map((x) => x.id).join() !== goals.map((x) => x.id).join());
    const g = { name: 'Testers', members: {} };
    const evs = [];
    for (const goal of goals) for (let k = 0; k < goal.n; k++) evs.push(goal.ev);
    const done = hall.progress(g, evs.slice(0, goals[0].n));
    check('a finished goal adds guild fame', done.length === 1 && g.fame === goals[0].fame && g.goals.done[goals[0].id]);
    const all = hall.progress(g, evs);
    const ban = all.find((d) => d.banner);
    check('finishing all three earns that week\'s banner for good (and it flies)', ban && g.banners.includes(ban.banner.id) && g.banner === ban.banner.id && GD.findBanner(ban.banner.id) && g.fame > 2000);
    check('a goal only counts once', hall.progress(g, evs).length === 0);
    // the bank: an item leaves its giver's ledger and joins the taker's
    const giver = { chars: [] }, taker = { chars: [] };
    const sword = itemsMod.issue(giver, GD.makeWeapon('sword', 5));
    const ginv = [sword, null], tinv = [null, null];
    const put = hall.deposit(g, giver, ginv, 0, 'Ann');
    check('putting an item in the guild bank takes it out of your inventory and ledger', put === sword && !ginv[0] && !giver._ledger[sword.sid] && g.bank.some((b) => b && b.item === sword));
    const idx = g.bank.findIndex((b) => b && b.item === sword);
    check('Initiates can\'t take items out', typeof hall.withdraw(g, taker, tinv, idx, 0, 'Bo') === 'string' && !tinv[0]);
    const got = hall.withdraw(g, taker, tinv, idx, 1, 'Bo');
    check('members take it with its ledger entry (still a real server item)', got === sword && tinv[0] === sword && taker._ledger[sword.sid] && !g.bank[idx] && !itemsMod.check(taker, { chars: [{ inv: tinv }] }));
    check('only leaders change the banner, and only to one the guild earned', typeof hall.fly(g, '', 2) === 'string' && hall.fly(g, '', 3) === null && typeof hall.fly(g, 'nope', 4) === 'string');
    // the Banner Maker
    check('only leaders can design a banner, and only a real design', typeof hall.design(g, 'c:1-2-3-4-5', 2, 'Bo') === 'string' && !hall.design(g, 'c:1-2-3-4-5', 2, 'Bo').startsWith('c:')
      && !hall.design(g, 'c:99-0-0-0-0', 4, 'Ann').startsWith('c:') && !hall.design(g, 'c:1-2-3', 4, 'Ann').startsWith('c:') && !hall.design(g, '<b>', 4, 'Ann').startsWith('c:'));
    const made = hall.design(g, 'c:09-5-4-1-03', 4, 'Ann');
    check('a saved design flies straight away (in its tidy form) and can be flown again later', made === 'c:9-5-4-1-3' && g.banner === made && g.custom === made
      && hall.fly(g, '', 4) === null && hall.fly(g, made, 4) === null && g.banner === made && GD.findBanner(made).custom.length === 5);
    let cells = new Set();
    for (let y = 0; y < GD.BANNER_H; y++) for (let x = 0; x < GD.BANNER_W; x++) cells.add(GD.bannerCell(GD.parseBanner(made), x, y));
    check('a design draws its cloth, pattern and emblem in their own colours', cells.size === 3 && cells.has(GD.BANNER_COLORS[9]) && cells.has(GD.BANNER_COLORS[4]) && cells.has(GD.BANNER_COLORS[3]));
    const v = hall.view(g, 'testers', { testers: g, other: { name: 'Others', members: {}, fame: 1e9 } }, 1);
    check('the Guild Hall shows goals, the bank and the guild ranking', v.goals.length === 3 && v.bank.length === hall.BANK_SLOTS && v.place === 2 && v.top[0].name === 'Others' && v.canTake && !v.canFly);
    // over the wire
    const G = await login('Tg' + n, { password: 'pass1234', register: true });
    G.send({ t: 'guildCreate', name: 'Hall Testers ' + String.fromCharCode(65 + (n % 26)) });
    await wait(300);
    G.clear();
    G.send({ t: 'ghView' });
    await wait(300);
    const hv = G.find((m) => m.t === 'hall');
    check('a guild member can open the Guild Hall', hv && hv.hall && hv.hall.goals.length === 3 && hv.hall.canFly, JSON.stringify(G.find((m) => m.t === 'msg')));
    G.clear();
    G.send({ t: 'ghBanner', id: 'crimson' });
    await wait(250);
    check('a banner the guild hasn\'t earned can\'t be flown', G.find((m) => m.t === 'msg' && /hasn't earned/.test(m.text)));
    G.clear();
    G.send({ t: 'ghDesign', code: 'c:15-7-3-2-13' });
    await wait(300);
    const gv = G.find((m) => m.t === 'hall'), gg = G.find((m) => m.t === 'guild');
    check('the founder designs a banner: the guild flies it at once', gv && gv.hall.banner === 'c:15-7-3-2-13' && gv.hall.custom === 'c:15-7-3-2-13' && gg && gg.guild.banner === 'c:15-7-3-2-13',
      JSON.stringify(G.msgs.filter((m) => m.t === 'msg')));
    // the Guild Hall itself: a world members walk into from the Nexus
    const { World: HW } = require('./sim/gen/game');
    const hw = new HW('guildhall', 'Hall');
    check('the Guild Hall is a real place: you arrive inside, the aisles and dais are open floor', hw.walkable(hw.spawnX, hw.spawnY)
      && [[86.5, 96.5], [86.5, 104.5], [114.5, 96.5], [114.5, 104.5], [100.5, 115.4], [100.5, 83]].every(([x, y]) => hw.walkable(x, y)) && hw.isSafe(hw.spawnX, hw.spawnY));
    const gkey = 'ghall:' + ('hall testers ' + String.fromCharCode(97 + (n % 26)));
    G.clear();
    G.send({ t: 'enter', key: gkey, cid: 'gh1', x: 100.5, y: 112.5, profile: { cls: 'wizard' } });
    const O = await login('Tgo' + n, { password: 'pass1234', register: true });
    O.send({ t: 'enter', key: gkey, cid: 'go1', x: 100.5, y: 112.5, profile: { cls: 'knight' } });
    await wait(400);
    const seen = O.find((m) => m.t === 'players');
    check('only members get into their guild\'s hall (others land in an empty one)', seen && seen.key !== gkey && !seen.list.some((p) => p.name === G.name) && !G.find((m) => m.t === 'join'),
      JSON.stringify(seen && seen.key));
    const mine = G.find((m) => m.t === 'players');
    check('a member walks into their guild\'s own hall', mine && mine.key === gkey, JSON.stringify(mine && mine.key));
    O.s.destroy();
    G.s.destroy();
  }

  console.log('hero modes');
  {
    const modes = require('./modes');
    const { Data: MD } = require('./sim/gen/game');
    const w = (tier, sid, rarity) => Object.assign(MD.makeWeapon('staff', tier, rarity || null), { sid });
    // the mode is picked when a hero is made, and kept
    const prev0 = { chars: [{ id: 'r1' }] };
    const next0 = { chars: [{ id: 'r1', mode: 'hardcore' }, { id: 'n1', mode: 'ironman' }, { id: 'n2', mode: 'god' }] };
    check('a hero\'s mode is set when it\'s made and can\'t change', modes.check(prev0, next0) === null && !next0.chars[0].mode && next0.chars[1].mode === 'ironman' && !next0.chars[2].mode);
    // Ironman: nothing from the vault or other heroes
    const pv = { vault: [w(5, 'v1')], chars: [{ id: 'im', mode: 'ironman', inv: [w(3, 'own')] }, { id: 'reg', inv: [w(6, 'other')] }] };
    check('Ironman heroes can\'t take items from the vault or another hero', !!modes.check(pv, { vault: [], chars: [{ id: 'im', mode: 'ironman', inv: [w(3, 'own'), w(5, 'v1')] }, { id: 'reg', inv: [w(6, 'other')] }] })
      && !!modes.check(pv, { vault: [w(5, 'v1')], chars: [{ id: 'im', mode: 'ironman', inv: [w(3, 'own'), w(6, 'other')] }, { id: 'reg', inv: [] }] }));
    check('...but new loot and their own items are fine (and regular heroes may use the vault)', modes.check(pv, { vault: [], chars: [{ id: 'im', mode: 'ironman', inv: [w(3, 'own'), w(7, 'fresh')] }, { id: 'reg', inv: [w(6, 'other'), w(5, 'v1')] }] }) === null);
    // Hardcore: one tier at a time per slot
    const hp = { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(2, 'a'), inv: [] }] };
    check('Hardcore heroes can\'t skip a tier', /Hardcore/.test(modes.check(hp, { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(4, 'b'), inv: [w(2, 'a')] }] }) || ''));
    const step = { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(3, 'c'), inv: [w(2, 'a')] }] };
    check('...but climb one tier at a time, and the server remembers the climb', modes.check(hp, step) === null && step.chars[0]._climb.weapon === 3
      && modes.check(step, { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(2, 'a'), inv: [w(3, 'c')] }] }) === null);
    const t7 = { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(7, 'd'), inv: [], _climb: { weapon: 7 } }] };
    check('special rarities need a T7 first; regular heroes have no climb', modes.check(t7, { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(7, 'e', 'lg'), inv: [] }] }) === null
      && !!modes.check(hp, { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(7, 'e', 'lg'), inv: [] }] })
      && modes.check({ chars: [{ id: 'x', weapon: w(1, 'p') }] }, { chars: [{ id: 'x', weapon: w(7, 'q', 'lg') }] }) === null);
    check('Ironman and Hardcore heroes get extra loot luck, Hardcore extra stats', modes.luck('') === 0 && modes.luck('ironman') > 0 && modes.luck('hardcore') > modes.luck('ironman')
      && MD.findMode('hardcore').stats.att > 0 && !MD.findMode('ironman').stats);
    // over the wire: no trading or Marketplace
    const H = await login('Thc' + n, { password: 'pass1234', register: true });
    const R = await login('Trg' + n, { password: 'pass1234', register: true });
    H.send({ t: 'save', data: { gold: 0, fame: 0, chars: [{ id: 'hch', cls: 'wizard', name: 'Hc', level: 1, mode: 'hardcore', inv: [] }] } });
    await wait(300);
    H.send({ t: 'enter', key: 'nexus', cid: 'hch', x: 100, y: 100, profile: { cls: 'wizard' } });
    R.send({ t: 'enter', key: 'nexus', cid: 'rgh', x: 101, y: 100, profile: { cls: 'knight' } });
    await wait(300);
    H.clear(); R.clear();
    H.send({ t: 'tradeReq', to: R.id });
    R.send({ t: 'tradeReq', to: H.id });
    H.send({ t: 'mkList', slot: 0, price: 100 });
    await wait(300);
    check('Hardcore heroes can\'t trade either way, or list on the Marketplace', H.find((m) => m.t === 'msg' && /can't trade/.test(m.text)) && R.find((m) => m.t === 'msg' && /can't trade/.test(m.text))
      && !H.find((m) => m.t === 'tradeReq') && H.find((m) => m.t === 'shopFail' && /Marketplace/.test(m.msg)));
    H.s.destroy(); R.s.destroy();
  }

  console.log('cosmetics');
  {
    const C = await login('Tc' + n, { password: 'pass1234', register: true });
    const D = await login('Td' + n, { password: 'pass1234', register: true });
    const wC = C.find((m) => m.t === 'welcome');
    check('the game gets its earned titles (none yet) with the save', wC && Array.isArray(wC.save.earned) && wC.save.earned.length === 0);
    C.send({ t: 'enter', key: 'nexus', cid: 'cc', x: 100, y: 100, profile: { cls: 'wizard' } });
    D.send({ t: 'enter', key: 'nexus', cid: 'cd', x: 101, y: 100, profile: { cls: 'knight' } });
    await wait(300);
    D.clear();
    const worn = { cls: 'wizard', dye: 'dye_ocean', title: 't_bold', level: 3 };
    C.send({ t: 'profile', profile: worn });
    await wait(250);
    const p1 = D.find((m) => m.t === 'profile' && m.id === C.id);
    check('nobody can wear a dye or title they don\'t own', p1 && !p1.profile.dye && !p1.profile.title, JSON.stringify(p1));
    D.clear();
    C.send({ t: 'save', data: { fame: 350, cosmetics: { dye_ocean: true, t_bold: true, elder: true }, chars: [] } });
    await wait(400);
    const p2 = D.find((m) => m.t === 'profile' && m.id === C.id);
    check('once bought (the save arrives), others see the dye and title', p2 && p2.profile.dye === 'dye_ocean' && p2.profile.title === 't_bold',
      JSON.stringify(p2 || C.find((m) => m.t === 'saveRejected')));
    D.clear();
    C.send({ t: 'profile', profile: Object.assign({}, worn, { title: 'elder' }) });
    await wait(250);
    const p3 = D.find((m) => m.t === 'profile' && m.id === C.id);
    check('earned titles can\'t be bought or faked in the save', p3 && !p3.profile.title && p3.profile.dye === 'dye_ocean');
    const { Data } = require('./sim/gen/game');
    check('a top-5 Records time has a Slayer title for every realm event', Data.EVENTS.every((ev) => { const t = Data.findTitle('slayer_' + ev); return t && t.earn && /\w/.test(t.name); }) &&
      Data.findTitle('slayer_ev_kraken').name === 'Kraken Slayer');
    // Seasonal heroes: only new ones, marked with this season, can carry the mark; when one dies it scores double
    const curSeason = wC.season && wC.season.id;
    const svNow = () => JSON.parse(fs.readFileSync(path.join(DATA, 'saves', ('Tc' + n).toLowerCase() + '.json'), 'utf8'));
    await wait(1800);
    const fameNow = svNow().fame;
    C.send({ t: 'save', data: Object.assign(svNow(), { _titles: undefined, chars: [{ id: 'sh1', cls: 'wizard', name: 'Sea', level: 5, season: curSeason }, { id: 'sh2', cls: 'knight', name: 'Old', level: 3, season: '2020-01' }] }) });
    await wait(1800);
    let hs = svNow().chars || [];
    check('a new hero can be Seasonal (this season only)', curSeason && hs.find((h) => h.id === 'sh1').season === curSeason && !hs.find((h) => h.id === 'sh2').season, JSON.stringify(hs));
    C.send({ t: 'save', data: Object.assign(svNow(), { _titles: undefined, chars: hs.map((h) => Object.assign({}, h, { season: curSeason })) }) });
    await wait(1800);
    hs = svNow().chars;
    check('an existing hero can\'t become Seasonal later', !hs.find((h) => h.id === 'sh2').season && hs.find((h) => h.id === 'sh1').season === curSeason);
    C.clear();
    C.send({ t: 'save', data: Object.assign(svNow(), { _titles: undefined, fame: fameNow + 100, chars: hs.filter((h) => h.id !== 'sh1') }) });
    await wait(1800);
    C.clear();
    C.send({ t: 'records' });
    await wait(300);
    const lad = C.find((m) => m.t === 'records');
    check('when a Seasonal hero dies its fame scores double on the ladder', lad && lad.season.you && lad.season.you.pts === 200 && lad.season.top.some((e) => e.name.toLowerCase() === ('tc' + n).toLowerCase()), JSON.stringify(lad && lad.season));
    C.s.destroy(); D.s.destroy();
  }

  console.log('discord feed');
  {
    const text = (p) => p.content || (p.embeds && p.embeds[0] && p.embeds[0].description) || '';
    check('the server says it is online in Discord when it starts', posts.some((p) => /is online/.test(text(p)) && p.username));
    const { Discord, names } = require('./discord');
    check('names are escaped for Discord (no bold or hidden text from a name)', names(['a*b', 'c_d']) === 'a\\*b and c\\_d');
    const off = new Discord('', 'X');
    off.post('nothing');
    check('with no webhook set, nothing is sent', !off.on && off.queue.length === 0);
    const before = posts.length;
    const { WorldSim } = require('./sim/worldsim');
    const { Bosses: DB } = require('./sim/gen/game');
    const feats = [];
    const ws = new WorldSim('raid:' + DB.RAIDS.findIndex((r) => r.id === 'starfall') + ':5');
    ws.onQuest = () => {}; ws.onFeat = (k, d) => feats.push([k, d]);
    ws.players.set(1, { id: 1, name: 'Hero', x: 0, y: 0 });
    ws.w.raidStage = ws.w.raid.stages.length - 1;
    const fin = { def: { name: 'Astraeon', raid: true }, isBoss: true, hitters: new Map([[1, 100]]), defId: 'astraeon' };
    ws.enemies.length = 0; ws.enemies.push(fin);
    ws.questKill(fin);
    check('clearing the Starfall Vault is a moment for the feed (with the team)', feats.some(([k, d]) => k === 'raid' && d.names[0] === 'Hero' && /Starfall/.test(d.raid)));
    boss0.clear();
    boss0.send({ t: 'cmd', text: '/discord' });
    await wait(2600);
    check('/discord (admins) sends a test message', posts.length > before && /Test message/.test(text(posts[posts.length - 1])) && boss0.find((m) => m.t === 'msg' && /Sent a test/.test(m.text)));
  }

  console.log('gold and fame (wallet)');
  {
    const wallet = require('./wallet');
    const meta = {}, now = Date.now();
    const prev = { gold: 100, fame: 50, chars: [{ id: 'h1', totalXp: 0 }], _fame: {} };
    const orc = { def: { xp: 300 }, zone: 2, hitters: [] };
    for (let i = 0; i < 10; i++) wallet.credit(meta, prev, 'h1', orc, now);
    const per = wallet.killValue(orc).gold;
    const ok = { gold: 100 + 10 * per, fame: 50, chars: [{ id: 'h1' }] };
    check('gold earned from kills the server saw is accepted', wallet.settle(prev, ok, meta, now) === null && ok.gold === 100 + 10 * per);
    const big = { gold: ok.gold + 100000, fame: 50, chars: [{ id: 'h1' }] };
    check('gold beyond what was earned is cut back', /gold cut back/.test(wallet.settle(ok, big, meta, now) || '') && big.gold <= ok.gold + wallet.ALLOW.gold[0]);
    const alive = { gold: big.gold, fame: 5000, chars: [{ id: 'h1' }] };
    check('fame does not go up while every hero lives', /fame cut back/.test(wallet.settle(big, alive, meta, now) || '') && alive.fame <= 50 + wallet.ALLOW.fame[0]);
    const book = alive._fame.h1;
    const died = { gold: alive.gold, fame: alive.fame + Math.floor(book), chars: [] };
    check('when a hero dies, the account gets the fame that hero earned', book > 0 && wallet.settle(alive, died, meta, now + 600000) === null && !died._fame.h1);
    const old = { gold: 0, fame: 0, chars: [{ id: 'v', totalXp: 80000, kills: 2000, bossKills: 10 }] };
    const oldDied = { gold: 0, fame: 15000, chars: [] };
    check('heroes from before this update keep the fame they already earned', wallet.settle(old, oldDied, {}, now) === null && oldDied.fame === 15000);
    // an honest player clears a whole dungeon, then saves exactly what the game gives: nothing may be cut
    {
      const { WorldSim } = require('./sim/worldsim');
      const hm = {}, hsv = { gold: 0, fame: 0, chars: [{ id: 'hh' }], _fame: {} }, t0 = Date.now();
      const ws = new WorldSim('dg:6:4242');
      const me = { id: 7, x: 100, y: 100, maxDps: 1e9, send: () => {} };
      ws.join(me);
      ws.onEarn = (c, e, near) => wallet.credit(hm, hsv, 'hh', e, t0, near);
      let gold = 0, xp = 0, kills = 0, bosses = 0, n = 0;
      for (let pass = 0; pass < 6; pass++) for (const e of ws.enemies.slice()) {
        if (e.dead || e.immune) continue;
        me.x = e.x; me.y = e.y + 1;
        ws.hit(me, { id: e.id, d: 6000 });
        if (!e.dead) continue;
        const d = e.def;
        // the game's own sums (Game.killEnemy, crateLoot, endStreak) at their most generous
        gold += Math.floor((d.gold || Math.floor(d.xp / 6)) * 1.24) + 5;
        if (e.elite) gold += Math.floor(d.xp / 2) + 20;
        if (d.crate) gold += 25 * (Math.max(0, e.zone) + 1);
        xp += Math.floor(d.xp * (1.5 + (e.elite ? 2 : 0)));
        kills++; if (e.isBoss) bosses++;
        n++;
      }
      const saved = { gold, fame: 0, chars: [{ id: 'hh' }] };
      const r1 = wallet.settle(hsv, saved, hm, t0);
      const heroFame = Math.floor(xp / 8 + kills * 0.5 + bosses * 150);
      const died = { gold, fame: Math.floor(heroFame * 2.15), chars: [] };
      const r2 = wallet.settle(saved, died, hm, t0 + 1000);
      check('an honest dungeon clear (' + n + ' kills, ' + gold + ' gold, ' + died.fame + ' death fame) is never cut back', n > 10 && r1 === null && r2 === null, r1 + ' / ' + r2);
    }
    {
      const am = {}, asv = { gold: 0, onrane: 5, chars: [], _fame: {} };
      const lord = { def: { xp: 900, onrane: 3, gold: 200 }, zone: 4, isBoss: true, hitters: [] };
      wallet.credit(am, asv, null, lord, now);
      const fine = { gold: 0, onrane: 8, chars: [] };
      const greedy = { gold: 0, onrane: 9999, chars: [] };
      check('Aether: what bosses drop is accepted, more is cut back', wallet.settle(asv, fine, am, now) === null &&
        /Aether cut back/.test(wallet.settle(fine, greedy, am, now) || '') && greedy.onrane <= 8 + wallet.ALLOW.onrane[0]);
    }
    const poor = { gold: 0, fame: 100, chars: [], _fame: {} };
    const buys = { gold: 0, fame: 0, chars: [], cosmetics: { t_eternal: true } };
    check('cosmetics bought without the fame are taken back', /cosmetics refused/.test(wallet.settle(poor, buys, {}, now) || '') && !buys.cosmetics.t_eternal);
  }

  console.log('making admins in game');
  {
    const boss = boss0;
    const pal = await login('Tp' + n, { password: 'pass1234', register: true });
    check('an admin from config.json is told so at login', bossWelcome && bossWelcome.admin);
    pal.clear();
    pal.send({ t: 'cmd', text: '/admin ' + nameB });
    await wait(250);
    check('players who are not admins cannot make admins', pal.find((m) => m.t === 'msg' && /Only server admins/.test(m.msg || m.text || '')), JSON.stringify(pal.msgs));
    boss.clear(); pal.clear();
    boss.send({ t: 'cmd', text: '/admin Tp' + n });
    await wait(300);
    const cfg = JSON.parse(fs.readFileSync(path.join(DATA, 'config.json'), 'utf8'));
    check('/admin name makes them an admin at once, and it is saved in config.json', pal.find((m) => m.t === 'admin' && m.on) &&
      cfg.admins.includes('Tp' + n) && cfg.motd === 'test', JSON.stringify(cfg));
    pal.clear();
    pal.send({ t: 'cmd', text: '/announce hello from a new admin' });
    await wait(250);
    check('the new admin can use admin commands straight away', !pal.find((m) => m.t === 'msg' && /Only server admins/.test(m.msg || m.text || '')));
    boss.clear(); pal.clear();
    boss.send({ t: 'cmd', text: '/unadmin Tp' + n });
    await wait(300);
    check('/unadmin name takes it away again', pal.find((m) => m.t === 'admin' && m.on === false) &&
      !JSON.parse(fs.readFileSync(path.join(DATA, 'config.json'), 'utf8')).admins.includes('Tp' + n));
    boss.clear(); pal.clear();
    boss.send({ t: 'cmd', text: '/give Tp' + n + ' 1500 gold' });
    await wait(300);
    const gift = pal.find((m) => m.t === 'given');
    check('/give name 1500 gold: the server hands out gold (the game gets the new total)', gift && gift.gold === 1500 && gift.seq > 0, JSON.stringify(pal.msgs));
    pal.clear();
    pal.send({ t: 'cmd', text: '/give TestBoss 99999 gold' });
    await wait(200);
    check('only admins can give', pal.find((m) => m.t === 'msg' && /Only server admins/.test(m.text || '')));
    boss.clear();
    boss.send({ t: 'cmd', text: '/unadmin TestBoss' });
    await wait(200);
    check('an admin cannot remove themselves (no locking yourself out)', boss.find((m) => m.t === 'msg' && /yourself/.test(m.msg || m.text || '')));
    boss.s.destroy(); pal.s.destroy();
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
  hook.close();
  await new Promise((r) => { srv.on('exit', r); srv.kill(); });
  try { fs.rmSync(DATA, { recursive: true, force: true }); } catch (e) {}
  console.log('\n' + passed + ' passed, ' + failed + ' failed');
  process.exit(failed ? 1 : 0);
}

run().catch((e) => { console.error(e); fs.rmSync(DATA, { recursive: true, force: true }); process.exit(1); });
