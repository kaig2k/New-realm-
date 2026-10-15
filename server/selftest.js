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
const VERSION = 12;
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
    // (like the game: a keep-alive every 10 seconds, or the server drops a connection quiet for 45)
    const keep = setInterval(() => c.send({ t: 'ping', at: -1 }), 10000);
    keep.unref();
    s.on('close', () => { c.closed = true; clearInterval(keep); });
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

/** The skills of hero id in the last save the server sent back (saveRejected), if any. */
function AQ_skills(cl, id) {
  const r = cl.msgs.filter((m) => m.t === 'saveRejected').pop();
  const h = r && r.data && (r.data.chars || []).find((x) => x && x.id === id);
  return h ? h.skills || {} : null;
}

async function run() {
  console.log('New Realm server self-test (port ' + PORT + ')');
  // a stand-in for Discord: collects what the server posts to its webhook
  const posts = [];
  const hook = require('http').createServer((q, r) => { let b = ''; q.on('data', (d) => { b += d; }); q.on('end', () => { try { posts.push(JSON.parse(b)); } catch (e) {} r.writeHead(204); r.end(); }); });
  await new Promise((r) => hook.listen(0, '127.0.0.1', r));
  const hookUrl = 'http://127.0.0.1:' + hook.address().port + '/api/webhooks/1/x';
  fs.writeFileSync(path.join(DATA, 'config.json'), JSON.stringify({ admins: ['TestBoss'], motd: 'test', discordWebhook: hookUrl, combatCheck: 'auto' }));
  // two accounts from before account numbers (oldest first gets #1)
  fs.writeFileSync(path.join(DATA, 'accounts.json'), JSON.stringify({ yold: { name: 'Yold', created: 2000 }, zold: { name: 'Zold', created: 1000 } }));
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
  // a Hardcore hero with T1 equipped and T2 and T3 staffs in the bag
  {
    const { Data: HD } = require('./sim/gen/game');
    fs.writeFileSync(path.join(DATA, 'saves', ('Thx' + n).toLowerCase() + '.json'), JSON.stringify({ gold: 0, fame: 0,
      chars: [{ id: 'hx', cls: 'wizard', name: 'Hx', level: 5, mode: 'hardcore', weapon: HD.makeWeapon('staff', 1), inv: [HD.makeWeapon('staff', 2), HD.makeWeapon('staff', 3), null, null] }] }));
  }
  // C has fame to spend in the Fame Store
  fs.writeFileSync(path.join(DATA, 'saves', ('Tc' + n).toLowerCase() + '.json'), JSON.stringify({ fame: 1000, chars: [] }));
  await wait(900);

  console.log('accounts');
  const old = await login('Old' + n, { password: 'x', ver: 3 });
  check('old game version is refused', old.find((m) => m.t === 'error' && /Version/.test(m.msg)));
  const A = await login(nameA, { password: 'pass1234', register: true });
  check('register works', A.id > 0 && A.find((m) => m.t === 'welcome' && m.session));
  const tokenA = A.find((m) => m.t === 'welcome').session;
  const noA = A.find((m) => m.t === 'welcome').no;
  const dup = await login(nameA.toLowerCase(), { password: 'pass1234', register: true });
  check('a taken name is refused', dup.find((m) => m.t === 'error' && /taken/.test(m.msg)));
  const wrong = await login(nameA, { password: 'nope1234' });
  check('a wrong password is refused', wrong.find((m) => m.t === 'error' && /Wrong password/.test(m.msg)));
  const bad = await login('x!', { password: 'pass1234', register: true });
  check('a bad username is refused', bad.find((m) => m.t === 'error'));
  const B = await login(nameB, { password: 'pass1234', register: true });
  check('second account registers', B.id > 0);
  const noB = (B.find((m) => m.t === 'welcome') || {}).no;
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
  // (the connection last entered with some other hero id: the shop goes by the id sent with the request)
  A.send({ t: 'enter', key: 'nexus', x: 100, y: 100, cid: 'not-this-hero' });
  await wait(150);
  A.clear();
  A.send({ t: 'buy', what: 'stat', data: goodA(), cid: 'ca' });
  await wait(400);
  let sd = A.find((m) => m.t === 'shopDone');
  check('a shop request names its hero, so a stale or missing enter never blocks it', sd, JSON.stringify(A.find((m) => m.t === 'shopFail')));
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
  A2.clear();
  A2.send({ t: 'tpreq', id: B.id });
  await wait(150);
  check('teleport to anyone in the same world (RotMG style): the server sends their real spot', A2.find((m) => m.t === 'tppos' && m.id === B.id));
  await wait(1600);
  const mapMsg = A2.find((m) => m.t === 'map');
  check('everyone in a world gets the minimap positions of everyone there', mapMsg && mapMsg.l.some((e) => e[0] === B.id) && mapMsg.l.some((e) => e[0] === A2.id), JSON.stringify(mapMsg));

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
  // dungeons open only through a portal: B uses the Sunken Crypt key it was traded
  const { Data: PD } = require('./sim/gen/game');
  const ci = PD.dungeonIndex('crypt'), dg = 'dg:' + ci + ':777';
  A2.clear();
  A2.send({ t: 'enter', key: 'dg:' + ci + ':778', x: 100, y: 180, cid: 'ca' });
  await wait(200);
  check('nobody gets into a dungeon without a portal (a changed game can\'t walk in)', A2.find((m) => m.t === 'toNexus'));
  const dkey = doneB && doneB.inv.find((it) => it && it.sub === 'dg_crypt');
  B.send({ t: 'portalKey', sid: 'not-a-key', k: 'dungeon', i: ci, s: 999 });
  B.send({ t: 'portalKey', sid: dkey ? dkey.sid : '', k: 'dungeon', i: ci, s: 777 });
  await wait(200);
  A2.clear(); B.clear();
  A2.send({ t: 'enter', key: dg, x: 100, y: 180, cid: 'ca' });
  B.send({ t: 'enter', key: dg, x: 100, y: 180, cid: 'cb' });
  await wait(200);
  check('...but a key opens one, for everyone who takes its portal', !A2.find((m) => m.t === 'toNexus') && !B.find((m) => m.t === 'toNexus'));
  const C9 = await login('Tk' + n, { password: 'pass1234', register: true });
  C9.send({ t: 'enter', key: 'dg:' + ci + ':999', x: 100, y: 180 });
  await wait(200);
  check('a key the server never saw opens nothing', C9.find((m) => m.t === 'toNexus'));
  C9.s.destroy();
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
    check('every class, Eldmere\'s own included, is open from the start', !Data.classUnlocked && ['bard', 'alchemist', 'chronomancer'].every((k) => Data.CLASSES[k] && Data.ELDMERE_CLASSES[k]));
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

  console.log('heroic raids and weekly first clears');
  {
    const { WorldSim } = require('./sim/worldsim');
    const { Data: HDt } = require('./sim/gen/game');
    // Heroic: ':h' on the world key, its bosses and guards tougher
    const norm = new WorldSim('raid:0:4321'), hero = new WorldSim('raid:0:4321:h');
    norm.w.raidT = 0; hero.w.raidT = 0;
    norm.updateRaid(0.05); hero.updateRaid(0.05);
    // (the guards are picked at random: compare the same kind in both)
    const gid = norm.enemies.find((e) => !e.isBoss && hero.enemies.some((h) => !h.isBoss && h.defId === e.defId)).defId;
    const gmax = (ws) => Math.max(...ws.enemies.filter((e) => !e.isBoss && e.defId === gid).map((e) => e.maxHp));
    check('a Heroic raid knows it is (its world key ends in :h), and its bosses and guards are tougher and fiercer',
      hero.heroic && !norm.heroic && hero.w.boss.maxHp > norm.w.boss.maxHp * 1.5 && hero.w.boss.dmgMult > norm.w.boss.dmgMult * 1.2 &&
      gmax(hero) > gmax(norm) * 1.4 && norm.week === hero.week && norm.week > 0, [hero.w.boss.maxHp, norm.w.boss.maxHp, gmax(hero), gmax(norm)].join(' '));
    // the final boss: the first clear of the week rolls its loot again; not the second
    const fc = new WorldSim('raid:1:555:h');
    const asked = [], got = [];
    const done = new Set();
    fc.firstClear = (c, id, week) => { asked.push(id + '@' + week); if (done.has(id)) return false; done.add(id); return true; };
    fc.issuer = (c, it) => got.push(it);
    const pl = { id: 7, name: 'Raider', x: 100, y: 100, maxDps: 1e9, send: () => {}, profile: { cls: 'wizard' } };
    fc.join(pl);
    fc.w.raidStage = fc.w.raid.stages.length - 1;
    const runs = [];
    for (let k = 0; k < 2; k++) {
      const msgs = [];
      pl.send = (m) => msgs.push(m.d || m);
      got.length = 0;
      const fin = fc.spawn('tempestus', 100, 100, 5, true);
      fin.hitters.set(7, 1000);
      fc.kill(fin);
      runs.push({ n: got.length, bonus: msgs.some((m) => m.t === 'msg' && /first .*clear this week/.test(m.text)) });
    }
    check('...and the first Heroic clear of the week gives a bonus roll from the final boss, the second doesn\'t',
      asked[0] === 'storm:h@' + fc.week && runs[0].bonus && !runs[1].bonus && runs[0].n > 0, JSON.stringify(runs) + ' ' + asked.join(','));
    check('every raid has a title for its final boss, and Heroic ones exist', ['vault', 'conclave', 'storm', 'heroic', 'heroic_all', 'raidrecord'].every((t) => HDt.findTitle(t)));
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
    // ...and per hit and per monster, by the hero the server knows (combat.js), whatever the game claims
    {
      const combat = require('./combat');
      const cls = PD.CLASSES.wizard;
      const starter = { cls: 'wizard', level: 1, stats: clone(cls.base), weapon: PD.makeWeapon('staff', 0), ability: PD.makeAbility(cls.abilityType, 0), armor: PD.makeArmor(cls.armor, 0) };
      const cw = new WorldSim('dg:6:779'), cb = cw.w.boss;
      cb.maxHp = cb.hp = 1e7;
      const hk = { id: 4, x: cb.x, y: cb.y + 1, maxDps: 1e9, caps: combat.caps(starter, null), send: () => {} };
      cw.join(hk);
      const h0 = cb.hp, s0 = Date.now();
      cw.hit(hk, { id: cb.id, d: 6000 });
      const one = h0 - cb.hp;
      for (let i = 0; i < 300; i++) cw.hit(hk, { id: cb.id, d: 6000 });
      const all = h0 - cb.hp, sec = (Date.now() - s0) / 1000;
      check('a hacked starter\'s 6,000 hit lands as at most ' + hk.caps.hit + ' (what a starter staff and ability can do)', one <= hk.caps.hit && one > 0, String(one));
      check('...and 300 of them deal no more than a starter could on one monster (' + Math.round(all) + ')', all <= hk.caps.burst + hk.caps.rate * (sec + 0.1), Math.round(all) + ' vs ' + hk.caps.burst);
      // an honest late hero firing as fast as it can (crits and all) for 8 seconds is never held back
      const late = { cls: 'wizard', level: 20, stats: clone(cls.max), weapon: PD.makeWeapon('staff', 7), ability: PD.makeAbility(cls.abilityType, 6), armor: PD.makeArmor(cls.armor, 7),
        skills: { brutality: 3 } };
      const hw = new WorldSim('dg:6:780'), hb = hw.w.boss;
      hb.maxHp = hb.hp = 1e9;
      const me2 = { id: 5, x: hb.x, y: hb.y + 1, maxDps: 1e9, caps: combat.caps(late, null), send: () => {} };
      hw.join(me2);
      const att = combat.stat(late, 'att'), dex = combat.stat(late, 'dex'), w7 = late.weapon;
      const perSec = (1.5 + 6.5 * dex / 75) * w7.rate * w7.shots * 1.5 * 1.4;
      const t1 = Date.now();
      let fakeT = 0;
      const realNow = Date.now;
      Date.now = () => t1 + fakeT;
      try {
        for (let k = 0; k < Math.ceil(perSec * 8); k++) {
          fakeT = Math.floor(k / perSec * 1000);
          let dmg = Math.floor((w7.dmin + Math.random() * (w7.dmax - w7.dmin)) * (0.5 + att / 50) * 1.15 * 1.3);
          if (Math.random() < 0.15) dmg = Math.floor(dmg * 1.7);
          hw.hit(me2, { id: hb.id, d: dmg });
          // and its ability on cooldown
          if (k % Math.ceil(perSec * 3) === 0) hw.hit(me2, { id: hb.id, d: Math.floor((130 + 16 * 20) * late.ability.power * 1.3) });
        }
      } finally { Date.now = realNow; }
      check('an honest late-game hero firing flat out (' + Math.round(perSec) + ' shots a second, Haste and Berserk) is never cut', !me2.dpsCut, me2.dpsCut + ' hits cut');
    }
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

  console.log('realm siege');
  {
    const { WorldSim } = require('./sim/worldsim');
    const { Data: SD, World: SW } = require('./sim/gen/game');
    const ws = new WorldSim('realm:Siegetest:4242');
    const sent = [[], [], []];
    const ps = [0, 1, 2].map((i) => ({ id: 70 + i, name: 'S' + i, x: 10, y: 10, maxDps: 1e9, profile: { cls: 'wizard', lk: 0 }, send: (m) => sent[i].push(m) }));
    for (const p of ps) ws.join(p);
    let result = null;
    ws.onSiege = (sim, kind, d) => { result = { kind, d }; };
    const got = [];
    ws.issuer = (c, it) => got.push([c.id, it]);
    check('a siege starts in the realm\'s Godlands, with soldiers', ws.startSiege() && ws.siege && SW.GOD_ZONE === ws.w.zoneAt(ws.siege.e.x, ws.siege.e.y) &&
      ws.enemies.some((e) => e.defId === 'siege_soldier') && !ws.startSiege());
    const e = ws.siege.e;
    // his war camp: laid into the realm round him, with four ballistas and scorched earth beyond
    const camp = e.arena || [];
    const scorched = camp.filter((k) => k.ch === 's');
    check('Vorgath\'s war camp rises round him: open (no walls), 35 tiles across, lava trenches, tents, four ballistas, scorched ground', camp.length > 900 && e.props.length === 4 &&
      e.props.every((p) => p.defId === 'siege_ballista') && !camp.some((k) => k.ch === '#' || k.nt === SW.WALL) && camp.some((k) => k.d > 15) &&
      camp.some((k) => k.ch === 'b') &&
      camp.some((k) => k.ch === '~' && ws.w.tiles[k.i] === SW.LAVA) && scorched.length > 40, [camp.length, e.props.length, scorched.length].join(' '));
    // breaking the ballistas tears the tents open and his guard pours out (after the warning)
    const soldiers0 = ws.enemies.filter((o) => !o.dead && o.defId === 'siege_soldier').length;
    for (const pr of e.props) { pr.hitters.set(70, 1); ws.kill(pr); }
    ws.updateArena(0.05); ws.updateArena(3);
    check('...break its ballistas and the tents are torn open, his guard storming out', camp.filter((k) => k.ch === 'b').every((k) => ws.w.objs[k.i] === 0) && (e.spMask & 1) &&
      ws.enemies.filter((o) => !o.dead && o.defId === 'siege_soldier').length > soldiers0);
    // at 30% the camp burns: the outer camp and the scorched land beyond turn to fire
    e.hp = e.maxHp * 0.25;
    for (let k = 0; k < 4; k++) { ws.updateArena(0.05); ws.updateArena(3); }
    check('...and at 30% the outer camp burns, the middle stays standing', scorched.every((k) => ws.w.tiles[k.i] === SW.LAVA) &&
      camp.filter((k) => k.d >= 12.5 && k.ch !== 'P').every((k) => ws.w.tiles[k.i] === SW.LAVA) && camp.some((k) => k.d < 6 && ws.w.tiles[k.i] !== SW.LAVA), String(e.spMask));
    e.hp = e.maxHp;
    check('...and everyone in the realm gets the siege panel', sent.every((l) => l.some((m) => m.t === 'siege' && m.on && m.id === e.id && m.left > 800)));
    for (const p of ps) { p.x = e.x; p.y = e.y + 2; }
    // S0 does most of the damage, S1 some, S2 a scratch (under half a percent: no loot)
    e.hitters.set(70, 70000); e.hitters.set(71, 20000); e.hitters.set(72, 100);
    ws.siegeStatus(false);
    const panel = sent[1].filter((m) => m.t === 'siege').pop();
    check('the panel shows the top damage dealers and your own share', panel.top[0][0] === 'S0' && panel.rank === 2 && panel.me > 20 && panel.me < 23, JSON.stringify(panel));
    ws.kill(e);
    check('when the Warlord falls: the result, MVP first, and the soldiers go', result && result.kind === 'win' && result.d.team[0].c.name === 'S0' && !ws.siege &&
      !ws.enemies.some((o) => !o.dead && o.defId === 'siege_soldier') && sent[2].some((m) => m.t === 'siege' && m.won && m.mvp === 'S0'), JSON.stringify(result && result.kind));
    const lootOf = (id) => got.filter((g) => g[0] === id).length;
    check('loot follows the share: the MVP rolls the most, a scratch gets nothing', lootOf(70) > 0 && lootOf(72) === 0 && !(ws.w.eventsDone > 0), [lootOf(70), lootOf(71), lootOf(72)].join(','));
    // not beaten in time: he leaves
    const ws2 = new WorldSim('realm:Siegetest2:4343');
    const q = { id: 80, name: 'Q', x: 10, y: 10, send: () => {} };
    ws2.join(q);
    let r2 = null;
    ws2.onSiege = (sim, kind) => { r2 = kind; };
    ws2.startSiege();
    const camp2 = ws2.siege.e.arena.slice();
    ws2.siege.left = 0.01;
    ws2.updateSiege(0.05);
    check('a siege that isn\'t beaten in 15 minutes ends (the Warlord leaves)', r2 === 'fail' && !ws2.siege && !ws2.enemies.some((o) => !o.dead && (o.defId === 'siege_warlord' || o.defId === 'siege_soldier' || o.defId === 'siege_ballista')));
    check('...and his camp comes down with him, the land as it was', camp2.every((k) => ws2.w.tiles[k.i] === k.t && ws2.w.objs[k.i] === k.o));
    check('the Warlord has three Starforged uniques and the titles exist', SD.bossUniques('siege_warlord').length === 3 && SD.findTitle('siege') && SD.findTitle('siegeguard'));
    // his attacks from the design sheet: each plays its own animation, and the charge really lunges
    const VD = SD.ENEMIES.siege_warlord;
    const vAll = [].concat(...VD.phases.map((p) => p.attacks || [].concat(...(p.cycle || []))));
    check('every one of Vorgath\'s attacks but his last-stand spiral has an animation he has frames for', vAll.filter((a) => a.p !== 'spiral').every((a) => a.anim && VD.seq[a.anim]) &&
      ['swing', 'smash', 'bash', 'barrage', 'warcry', 'charge'].every((k) => vAll.some((a) => a.anim === k)), vAll.map((a) => a.anim).join(','));
    const ws3 = new WorldSim('realm:Siegetest3:4545');
    ws3.join({ id: 81, name: 'R', x: 10, y: 10, send: () => {} });
    ws3.startSiege();
    const v = ws3.siege.e;
    const ci = VD.phases[2].attacks.findIndex((a) => a.dash);
    v.setAttacks([VD.phases[2].attacks[ci]]);
    const vx0 = v.x, vy0 = v.y;
    v.fire(0, 0, 8, ws3.g);
    for (let k = 0; k < 10; k++) v.update(0.05, ws3.g);
    check('...and his charge carries him several tiles at whoever he charged', v.x - vx0 > 3 && Math.abs(v.y - vy0) < 1, [vx0, v.x, vy0, v.y].join(' '));

    // the Dark Elder, after his design sheet: an animation for every attack, a gravity well, a blink, and his new chamber
    const ED = SD.ENEMIES.elder;
    const eAll = [].concat(...ED.phases.map((p) => p.attacks || [].concat(...(p.cycle || []))));
    check('every one of the Dark Elder\'s attacks but his last spiral has an animation he has frames for', eAll.filter((a) => a.p !== 'spiral').every((a) => a.anim && ED.seq[a.anim]) &&
      ['blast', 'pillars', 'slam', 'spread', 'explode', 'gravity', 'teleport', 'summon', 'rift'].every((k) => eAll.some((a) => a.anim === k)), eAll.map((a) => a.anim).join(','));
    const wa = new WorldSim('arena:elder-test');
    const N = wa.w.N, at = (x, y) => wa.w.tiles[Math.floor(y) * N + Math.floor(x)];
    let walls = 0, floor = 0;
    for (let i = 0; i < N * N; i++) { if (wa.w.tiles[i] === SW.WALL) walls++; if (wa.w.zones[i] === SW.ARENA_ZONE) floor++; }
    const crystalSpots = [[-8, -5], [8, -5], [-8, 5], [8, 5]].map(([dx, dy]) => [100.5 + dx, 91.5 + 7 + dy]);
    check('his chamber is an eye-shaped platform in the void: no walls, room to fight, and the spawn, his spot and the crystals\' spots all stand on it',
      walls === 0 && floor > 900 && wa.w.canStand(wa.w.spawnX, wa.w.spawnY, 0.4, true) && wa.w.canStand(100.5, 91.5, 0.6, true) &&
      crystalSpots.every(([x, y]) => wa.w.canStand(x, y, 0.35, true)) && at(100.5, 70) === SW.VOID, [walls, floor].join(' '));
    const el = wa.w.boss;
    const gi = ED.phases[1].cycle.findIndex((c) => c.some((a) => a.p === 'implode'));
    el.setAttacks(ED.phases[1].cycle[gi]);
    wa.shots = [];
    el.fire(ED.phases[1].cycle[gi].findIndex((a) => a.p === 'implode'), Math.PI / 2, 8, wa.g);
    const well = wa.shots;
    const cxw = el.x, cyw = el.y + 8;
    check('...his gravity well: a ring of shots round you, every one falling inward', well.length === 14 &&
      well.every((sh) => Math.abs(Math.hypot(sh.x - cxw, sh.y - cyw) - 5.5) < 0.2 && ((cxw - sh.x) * Math.cos(sh.a) + (cyw - sh.y) * Math.sin(sh.a)) > 0), String(well.length));
    const ti = ED.phases[0].attacks.findIndex((a) => a.blink);
    el.setAttacks(ED.phases[0].attacks);
    const ex0 = el.x, ey0 = el.y;
    el.fire(ti, 0, 5, wa.g);
    check('...and his teleport takes him elsewhere on the platform', Math.hypot(el.x - ex0, el.y - ey0) > 1.5 && wa.w.canStand(el.x, el.y, 0.6, true), [ex0, ey0, el.x, el.y].join(' '));
    // the Abyssal Herald, after its design sheet: an animation for every attack, and its own spawn of the deep
    const HD = SD.ENEMIES.abyss_herald;
    const hAll = [].concat(...HD.phases.map((p) => p.attacks || [].concat(...(p.cycle || []))));
    check('every one of the Abyssal Herald\'s attacks but its last spiral has an animation it has frames for, and it calls its own spawn',
      hAll.filter((a) => a.p !== 'spiral').every((a) => a.anim && HD.seq[a.anim]) && ['barrage', 'rain', 'slam', 'spread', 'explode', 'gravity', 'teleport', 'summon', 'rift'].every((k) => hAll.some((a) => a.anim === k)) &&
      SD.ENEMIES.abyss_spawn && !SD.ENEMIES.abyss_spawn.drop && hAll.some((a) => a.p === 'summon' && a.what === 'abyss_spawn'), hAll.map((a) => a.anim).join(','));
    // online the server runs his crystal phase, and his chamber burns as he weakens
    const el2 = new WorldSim('arena:elder-test2');
    const E2 = el2.w.boss;
    E2.hp = E2.maxHp * 0.4;
    E2.update(0.05, el2.g);
    const crystals = el2.enemies.filter((o) => !o.dead && o.defId === 'elder_crystal');
    let veins = 0;
    for (let i = 0; i < N * N; i++) if (el2.w.tiles[i] === SW.VOIDFIRE) veins++;
    check('his third phase on the server: four crystals rise and he can\'t be hurt, and the veins of the chamber catch void fire', crystals.length === 4 && E2.invuln && veins > 20 &&
      el2.w.tiles[Math.floor(el2.w.spawnY) * N + Math.floor(el2.w.spawnX)] !== SW.VOIDFIRE, [crystals.length, E2.invuln, veins].join(' '));
    for (const cr of crystals) { cr.hitters.set(90, 1); el2.kill(cr); }
    check('...break the crystals and he can be hurt again', !E2.invuln);
    E2.hp = E2.maxHp * 0.15;
    E2.update(0.05, el2.g);
    let rim = 0;
    for (let i = 0; i < N * N; i++) if (el2.w.tiles[i] === SW.VOIDFIRE) rim++;
    check('...and in his last phase the rim of the platform burns too (the middle and the way in stay clear)', rim > veins + 60 &&
      el2.w.tiles[Math.floor(el2.w.spawnY) * N + Math.floor(el2.w.spawnX)] !== SW.VOIDFIRE && el2.w.tiles[91 * N + 100] !== SW.VOIDFIRE, [veins, rim].join(' '));
  }

  console.log('guild territory');
  {
    const { Territory, weekOf } = require('./territory');
    const NOW = Date.now();
    const T = new Territory({});
    const at = (g, n) => [new Map(g ? [[g, n]] : []), new Map(), new Map(), new Map()];
    let ev = [];
    for (let k = 0; k < 59; k++) ev = ev.concat(T.tick(1, at('alpha', 1), NOW));
    check('one member alone hasn\'t taken a Spire in 59 seconds...', !ev.length && T.holder(0) === '' && T.cap[0].g === 'alpha');
    ev = T.tick(1.5, at('alpha', 1), NOW);
    check('...and has at 60: the guild holds it, +5 loot luck', ev.length === 1 && ev[0].kind === 'capture' && T.holder(0) === 'alpha' && T.luck('alpha') === 5);
    // three members are three times as fast; more don't help
    const T3 = new Territory({});
    for (let k = 0; k < 21; k++) ev = T3.tick(1, at('beta', 6), NOW);
    check('three or more members take it in 20 seconds', T3.holder(0) === 'beta');
    // a defender stops them
    for (let k = 0; k < 120; k++) T.tick(1, [new Map([['alpha', 1], ['beta', 3]]), new Map(), new Map(), new Map()], NOW);
    check('a single defender on the Spire holds off any number of attackers', T.holder(0) === 'alpha' && T.cap[0].p === 0);
    // two attacking guilds and nobody defending: contested
    const T4 = new Territory({});
    for (let k = 0; k < 120; k++) T4.tick(1, [new Map([['a', 2], ['b', 2]]), new Map(), new Map(), new Map()], NOW);
    check('two guilds fighting over an empty Spire: neither takes it', T4.holder(0) === '');
    // the week: minutes held, a winner on Monday, then a fresh week
    const T5 = new Territory({ week: weekOf(Date.UTC(2026, 9, 14)) });
    T5.s.spires[0].g = 'gamma'; T5.s.spires[1].g = 'gamma'; T5.s.spires[2].g = 'delta';
    for (let k = 0; k < 180; k++) T5.tick(1, [], Date.UTC(2026, 9, 14));
    const wk = T5.tick(1, [], Date.UTC(2026, 9, 19, 1));
    check('each week the guild that held the Spires longest is crowned, then the count starts over', wk.some((e) => e.kind === 'week' && e.winner === 'gamma' && e.minutes === 6) && !Object.keys(T5.s.held).length, JSON.stringify(wk));
    T5.forget('gamma');
    check('a disbanded guild\'s Spires stand empty', T5.holder(0) === '' && T5.holder(1) === '' && T5.holder(2) === 'delta');
    const { WorldSim: TW } = require('./sim/worldsim');
    const { World: TWW } = require('./sim/gen/game');
    const tw = new TW('realm:Spiretest:5151');
    const sp = Territory.spots(tw.w, TWW);
    check('the four Spires stand in the Godlands, one each way, apart from each other', sp.length === 4 && sp.every((p) => tw.w.zoneAt(p.x, p.y) === TWW.GOD_ZONE) &&
      Math.hypot(sp[0].x - sp[2].x, sp[0].y - sp[2].y) > 20, JSON.stringify(sp));
  }

  console.log('the endless abyss (world)');
  {
    const { WorldSim: DW } = require('./sim/worldsim');
    const { Data: DD } = require('./sim/gen/game');
    const ws = new DW('deep:321');
    const got = [], said = [], cleared = [];
    ws.issuer = (c, it) => got.push(it);
    ws.onDeep = (sim, pl, wave, chest) => cleared.push([wave, chest, pl.length]);
    const pp = { id: 92, name: 'Waver', x: 100.5, y: 113.5, maxDps: 1e9, profile: { cls: 'wizard', lk: 0 }, send: (m) => said.push(m) };
    ws.join(pp);
    check('the Abyss is an arena: empty until the first wave', ws.enemies.length === 0 && said.some((m) => m.t === 'deepWave' && m.wave === 0 && m.state === 'break'));
    ws.deep.t = 0; ws.updateWaves(0.05);
    const mobs = ws.enemies.filter((e) => !e.dead);
    check('wave 1 comes: its monsters, and everyone is told', ws.deep.wave === 1 && mobs.length === DD.deepCount(1, 1) && said.some((m) => m.t === 'deepWave' && m.wave === 1 && m.state === 'fight'), mobs.length + '');
    // (kill everything, splitters' children and late pulses too, until the wave is over)
    const killAll = () => {
      for (let r = 0; r < 30 && ws.deep.state !== 'break'; r++) {
        for (const e of ws.enemies.slice()) if (!e.dead && !e.def.abyssChest) { e.hitters.set(92, 100); ws.kill(e); }
        if (ws.deep.pulses.length) ws.deep.fightT = 99;
        ws.updateWaves(0.05);
      }
    };
    killAll();
    check('its monsters drop nothing', got.length === 0, got.map((i) => i.name).join(','));
    check('wave cleared: a short break, and it counts', ws.deep.state === 'break' && cleared.length === 1 && cleared[0][0] === 1 && !cleared[0][1]);
    ws.deep.wave = 4; ws.deep.t = 0; ws.updateWaves(0.05);
    const boss = ws.w.boss;
    check('wave 5 brings a boss, tougher for the depth', boss && boss.defId === DD.deepBoss(5) && boss.maxHp > boss.def.hp * 1.5 && boss.dmgMult > 1.1, boss && boss.defId);
    killAll();
    const chest = ws.enemies.find((e) => !e.dead && e.def.abyssChest);
    check('...and once it\'s down, a chest (and a boon for everyone)', got.length === 0 && chest && chest.def.abyssChest === 1 && cleared.pop()[1] === true);
    chest.hitters.set(92, 600); ws.kill(chest);
    check('the chest gives its loot', got.length >= 4 && got.some((i) => i.kind === 'potion' || /Potion/.test(i.name)), got.map((i) => i.name).join(','));
    const t1 = DD.deepChest(1, DD.CLASSES.wizard, 0), t6 = DD.deepChest(6, DD.CLASSES.wizard, 0);
    let early = 0;
    for (let k = 0; k < 300; k++) early += DD.deepChest(2, DD.CLASSES.wizard, 200).filter((i) => i.uid).length;
    check('deeper chests give more, and the Abyss uniques only from wave 15 on', t6.length > t1.length && early === 0 && DD.deepChestTier(30) === 6 && DD.deepChestTier(5) === 1, [t1.length, t6.length, early].join(' '));
    check('wave sizes and bosses: every 5th a boss, every 10th the Herald, two at once from wave 20', DD.deepBoss(10) === 'abyss_herald' && DD.deepBoss(7) === null &&
      DD.deepCount(20) > DD.deepCount(3) && DD.deepBosses(25).length === 2 && DD.deepCount(8, 3) > DD.deepCount(8, 1));
    // modifiers, and the restless Abyss
    const w2 = new DW('deep:654'), said2 = [];
    w2.join({ id: 93, name: 'Mod', x: 100.5, y: 113.5, send: (m) => said2.push(m) });
    w2.startWave(12);
    const st = said2.find((m) => m.t === 'deepWave' && m.state === 'fight');
    check('from wave 11 a wave has two modifiers, and the players are told', w2.deep.mods.length === 2 && st && st.mods.length === 2 && st.mods.every((id) => DD.findDeepMod(id)), JSON.stringify(st && st.mods));
    const before = w2.enemies.filter((e) => !e.dead).length;
    w2.deep.fightT = DD.DEEP_RESTLESS + 1; w2.deep.pulses = [];
    w2.updateWaves(0.05);
    const added = w2.enemies.filter((e) => !e.dead).slice(before);
    check('a wave left too long: the Abyss sends elites', added.length >= 2 && added.every((e) => e.elite) && said2.some((m) => m.state === 'restless'), added.length + '');
    check('deep waves are much tougher than early ones', DD.deepScale(20)[0] > 5 && DD.deepScale(20)[1] > 2.4 && DD.deepEliteChance(20) >= 0.4);
    check('boons add stats (and Greed adds luck)', DD.deepBonus(['might', 'might', 'life']).att === 8 && DD.deepBonus(['life']).hp === 60 && DD.deepBoonLuck(['greed', 'might']) === 15);
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
    // the damage of those hits: the least each could do to this hero (its Defense, or 15%)
    {
      const { damageVerdict } = require('./godmode');
      const tough = { id: 11, x: room.x + 0.5, y: room.y + 0.5, maxDps: 1e9, defMax: 10, send: () => {} };
      const ws2 = new WorldSim('dg:6:31');
      ws2.join(tough);
      for (let i = 0; i < 400; i++) ws2.tick(0.05);
      check('the server adds up the damage of the clean hits (' + (tough.expHits || 0) + ' hits, at least ' + Math.round(tough.expDmg || 0) + ' damage)', (tough.expHits || 0) > 0 && tough.expDmg > 0, String(tough.expDmg));
      check('a game reporting far less damage than those hits did (edited Defense, ignored hits) is caught; an honest one is not',
        damageVerdict(30, 2000, 300) && !damageVerdict(30, 2000, 1800) && !damageVerdict(30, 2000, 2600) && !damageVerdict(10, 2000, 0) && !damageVerdict(30, 200, 0));
    }
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
    check('Swarming Halls: twice the guards', swarm.guards >= 1.5 * glass.guards, swarm.guards + ' vs ' + glass.guards);
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
    // the website: the landing page, browser play, its images, and nothing else
    const home = (await get('/')).toString();
    const play = (await get('/play')).toString();
    const logo = await get('/logo.png');
    const sneaky = [await get('/promo/../server/config.json'), await get('/promo/%2e%2e%2fconfig.png'), await get('/../server/data/accounts.json'), await get('/promo/x.mp4.json')];
    check('the server shows a landing page (live player count) and a browser-play page', /Dodge\. Loot\. Survive\./.test(home) && /playing now/.test(home) && /href="\/play"/.test(home)
      && /ruffle/i.test(play) && /NewRealm\.swf/.test(play) && /^HTTP\/1\.1 200/.test(logo.toString('latin1', 0, 20)) && /image\/png/.test(logo.toString('latin1', 0, 200)));
    check('...and serves no other files (no ../ tricks)', sneaky.every((b) => /^HTTP\/1\.1 404/.test(b.toString('latin1', 0, 30))), sneaky.map((b) => b.toString('latin1', 0, 30)).join(' | '));
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
    {
      // two tiers between saves: the early one goes back to the inventory instead of the save being refused
      const pv = { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(1, 'a'), inv: [null, null] }] };
      const nx = { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(3, 'c'), inv: [w(1, 'a'), w(2, 'b')] }] };
      const fx = [];
      const why = modes.check(pv, nx, fx);
      const h = nx.chars[0];
      check('a Hardcore item equipped too early goes back to the inventory (nothing else is undone)', why === null && fx.length === 1 && /went back to your inventory/.test(fx[0]) &&
        h.weapon.sid === 'a' && h.inv.some((it) => it && it.sid === 'c') && h.inv.some((it) => it && it.sid === 'b') && h._climb.weapon === 1, why || fx.join());
      check('...and without room for it, the save is refused as before', /Hardcore/.test(modes.check(pv, { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(3, 'c'), inv: [w(5, 'd')] }] }, []) || ''));
    }
    check('special rarities need a T7 first; regular heroes have no climb', modes.check(t7, { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(7, 'e', 'lg'), inv: [] }] }) === null
      && !!modes.check(hp, { chars: [{ id: 'hc', mode: 'hardcore', weapon: w(7, 'e', 'lg'), inv: [] }] })
      && modes.check({ chars: [{ id: 'x', weapon: w(1, 'p') }] }, { chars: [{ id: 'x', weapon: w(7, 'q', 'lg') }] }) === null);
    {
      // abilities top out at T6 and rings at T5: their special rarities open up after those (not a T7 that doesn't exist)
      const r = (tier, sid, rarity) => Object.assign(MD.makeRing('att', tier, rarity || null), { sid });
      const ab = (tier, sid, rarity) => Object.assign(MD.makeAbility('spell', tier, rarity || null), { sid });
      const hr = (ring, ability, climb) => ({ chars: [{ id: 'hc', mode: 'hardcore', ring, ability, inv: [], _climb: climb }] });
      const okRing = modes.check(hr(r(5, 'r5'), ab(6, 'a6'), { ring: 5, ability: 6 }), hr(r(5, 'rx', 'lg'), ab(6, 'ax', 'lg')));
      const earlyRing = modes.check(hr(r(4, 'r4'), ab(5, 'a5'), { ring: 4, ability: 5 }), hr(r(4, 'ry', 'lg'), ab(5, 'a5')));
      check('Hardcore: a special ring after a T5 ring and a special ability after a T6 ability (their top tiers) are fine; earlier they are not',
        okRing === null && /Hardcore/.test(earlyRing || '') && MD.climbTop('ring') === 5 && MD.climbTop('ability') === 6, okRing + ' / ' + earlyRing);
    }
    check('Ironman and Hardcore heroes get extra loot luck, Hardcore extra stats', modes.luck('') === 0 && modes.luck('ironman') > 0 && modes.luck('hardcore') > modes.luck('ironman')
      && MD.findMode('hardcore').stats.att > 0 && !MD.findMode('ironman').stats);
    // over the wire: equipping T3 straight after T1 (no save between) keeps the loot, the T3 just goes back to the bag
    {
      const X = await login('Thx' + n, { password: 'pass1234', register: true });
      const xs = X.find((m) => m.t === 'welcome').save;
      const hx = xs.chars[0], [t2, t3] = hx.inv;
      X.clear();
      X.send({ t: 'save', data: Object.assign({}, xs, { chars: [Object.assign({}, hx, { weapon: t3, inv: [hx.weapon, t2, null, null] })] }) });
      await wait(450);
      const back = X.find((m) => m.t === 'saveRejected');
      const bh = back && back.data.chars[0];
      check('over the wire: the game is sent the hero with the early item back in the inventory', bh && bh.weapon.sid === hx.weapon.sid && bh.inv.some((it) => it && it.sid === t3.sid) && /went back/.test(back.reason),
        JSON.stringify(back && back.reason));
      X.clear();
      X.send({ t: 'save', data: Object.assign({}, back.data, { chars: [Object.assign({}, bh, { weapon: t2, inv: bh.inv.map((it) => (it && it.sid === t2.sid ? hx.weapon : it)) })] }) });
      await wait(450);
      const step2 = Object.assign({}, back.data, { chars: [Object.assign({}, bh, { weapon: t3, inv: bh.inv.map((it) => (it && it.sid === t2.sid ? hx.weapon : it && it.sid === t3.sid ? t2 : it)) })] });
      X.send({ t: 'save', data: step2 });
      await wait(450);
      check('...and climbing one tier per save works', !X.find((m) => m.t === 'saveRejected'), JSON.stringify(X.find((m) => m.t === 'saveRejected')));
      X.s.destroy();
    }
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

  console.log('daily login reward');
  {
    const L = await login('Tdl' + n, { password: 'pass1234', register: true });
    L.send({ t: 'save', data: { gold: 0, fame: 0, chars: [{ id: 'dl1', cls: 'wizard', name: 'Dl', level: 1, inv: [] }] } });
    await wait(300);
    L.send({ t: 'enter', key: 'nexus', cid: 'dl1', x: 100, y: 100, profile: { cls: 'wizard' } });
    await wait(300);
    const d1 = L.find((m) => m.t === 'daily');
    L.clear();
    L.send({ t: 'enter', key: 'nexus', cid: 'dl1', x: 100, y: 100, profile: { cls: 'wizard' } });
    await wait(300);
    check('the first time in each day pays a daily reward (once)', d1 && d1.streak === 1 && d1.addGold === 100 && !L.find((m) => m.t === 'daily'), JSON.stringify(d1));
    // the game adds it and saves: the wallet lets it through (and a save can't reset the streak to claim it again)
    L.clear();
    L.send({ t: 'save', data: { gold: 100, fame: 0, _login: { day: 1, streak: 0 }, chars: [{ id: 'dl1', cls: 'wizard', name: 'Dl', level: 1, inv: [] }] } });
    await wait(300);
    check('the reward\'s gold is kept when the game saves it', !L.find((m) => m.t === 'wallet' || m.t === 'saveRejected'), JSON.stringify(L.msgs.filter((m) => m.t === 'wallet' || m.t === 'saveRejected')));
    L.clear();
    L.send({ t: 'enter', key: 'nexus', cid: 'dl1', x: 100, y: 100, profile: { cls: 'wizard' } });
    await wait(300);
    check('...and the game can\'t reset its streak to claim it twice', !L.find((m) => m.t === 'daily'));
    L.s.destroy();
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

  console.log('discord status board');
  {
    const http = require('http');
    const { StatusBoard } = require('./discord');
    const seen = [];
    const fake = http.createServer((req, res) => {
      let b = ''; req.on('data', (d) => { b += d; });
      req.on('end', () => { seen.push(req.method + ' ' + req.url); res.writeHead(200, { 'Content-Type': 'application/json' }); res.end(JSON.stringify({ id: '777' })); });
    });
    await new Promise((r) => fake.listen(0, '127.0.0.1', r));
    let saved = '';
    const sb = new StatusBoard('http://127.0.0.1:' + fake.address().port + '/api/webhooks/1/abc', 'Eldmere', '', (id) => { saved = id; });
    sb.show('12 playing now', 0x8fd16a);
    await wait(300);
    sb.show('13 playing now', 0x8fd16a);
    await wait(300);
    check('the Discord status board posts once, then keeps editing that message (remembering its id)',
      seen[0] === 'POST /api/webhooks/1/abc?wait=true' && seen[1] === 'PATCH /api/webhooks/1/abc/messages/777' && saved === '777', seen.join(', '));
    fake.close();
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
    // an honest hero plays the way the game does (the most XP and stat growth it can roll), saving as it goes:
    // the server's progress checks must never put anything back
    {
      const progress = require('./progress');
      const items = require('./items');
      const { WorldSim } = require('./sim/worldsim');
      const { Data: GD2 } = require('./sim/gen/game');
      const cls = GD2.CLASSES.wizard, pm = {}, t0 = Date.now();
      const h = { id: 'hp', cls: 'wizard', name: 'Honest', level: 1, xp: 0, xpNext: progress.xpFor(1), totalXp: 0, ascXp: 0, kills: 0, bossKills: 0, potsDrunk: 0,
        stats: clone(cls.base), skills: {}, skillPoints: 0, tree2: true, inv: [null, null, null, null, null, null, null, null] };
      let stored = { gold: 5000, fame: 0, chars: [clone(h)], pet: { species: 'pup', name: 'Realm Pup', rarity: 'common', level: 1, xp: 0 }, _fame: {} };
      const pet = clone(stored.pet);
      const gainXp = (amount) => {
        h.totalXp += amount;
        if (h.level >= 20) {
          h.ascXp += amount;
          for (;;) { let n = h.skillPoints; for (const k in h.skills) n += h.skills[k]; const cost = GD2.skillPointXp(Math.max(0, n - (h.level - 1))); if (h.ascXp < cost) break; h.ascXp -= cost; h.skillPoints++; }
          return;
        }
        h.xp += amount;
        while (h.xp >= h.xpNext && h.level < 20) {
          h.xp -= h.xpNext; h.level++; h.xpNext = progress.xpFor(h.level);
          for (const k of GD2.STATS) h.stats[k] = Math.min(cls.max[k], h.stats[k] + GD2.grow(cls, k) * 1.2);
          h.skillPoints++;
        }
      };
      const fixes = [];
      const save = (extra) => {
        const next = Object.assign(clone(stored), { chars: [clone(h)], pet: clone(pet) }, extra || {});
        // (as applySave does: the ledger is the server's, carried over as it is)
        next._ledger = stored._ledger;
        const f = progress.check(stored, next, pm, Date.now());
        fixes.push(...f);
        stored = next;
      };
      let n = 0;
      for (let run = 0; run < 14 && h.ascXp < 1500; run++) {
        const ws = new WorldSim('dg:6:' + (4300 + run));
        const me = { id: 7, x: 100, y: 100, maxDps: 1e9, send: () => {} };
        ws.join(me);
        ws.onEarn = (c, e, near) => wallet.credit(pm, stored, 'hp', e, t0, near);
        for (let pass = 0; pass < 6; pass++) for (const e of ws.enemies.slice()) {
          if (e.dead || e.immune) continue;
          me.x = e.x; me.y = e.y + 1;
          ws.hit(me, { id: e.id, d: 6000 });
          if (!e.dead) continue;
          gainXp(Math.floor(e.def.xp * (1.5 + (e.elite ? 2 : 0))));
          h.kills++; if (e.isBoss) h.bossKills++;
          if (!e.def.crate && !e.def.prop) pet.xp += GD2.petKillXp(Math.floor(e.def.xp * (1.5 + (e.elite ? 2 : 0))));
          while (pet.level < 30 && pet.xp >= GD2.petXpNeeded(pet.level)) { pet.xp -= GD2.petXpNeeded(pet.level); pet.level++; }
          if (++n % 25 === 0) save();
        }
        save();
      }
      // a backpack (the server sells it: its copy has it first), then the game's save with it
      stored.chars[0].backpack = true; stored.gold -= 3000;
      h.backpack = true; while (h.inv.length < 16) h.inv.push(null);
      save({ gold: stored.gold });
      // a stat potion the server dropped for it, drunk straight from the loot bag (never in the inventory)
      stored._ledger = stored._ledger || {};
      stored._ledger.bagpot = { f: items.fingerprint(GD2.makePotion('stat', 'att')), t: Date.now() };
      h.stats.att = Math.min(cls.max.att, h.stats.att + 1); h.potsDrunk++;
      save();
      const bagOk = fixes.length === 0 && !stored._ledger.bagpot;
      // ...and drinking another that it was never given is put back
      const fx0 = fixes.length;
      h.stats.dex = Math.min(cls.max.dex, h.stats.dex + 1); h.potsDrunk++;
      save();
      const twiceOut = fixes.length === fx0 + 1 && /stat potions drunk/.test(fixes[fixes.length - 1]);
      fixes.length = fx0;
      Object.assign(h, clone(stored.chars[0]));
      // and the skill points spent in the tree
      h.skills = { brutality: 2 }; h.skillPoints -= 2;
      save();
      check('an honest hero (' + n + ' kills, level ' + h.level + ', ' + (h.skillPoints + 2) + ' skill points, pet level ' + pet.level + ') never has progress put back',
        h.level === 20 && h.skillPoints > 19 && fixes.length === 0, fixes.slice(0, 3).join(' | '));
      // ...while the same hero claiming one level more than its XP buys is put back
      const cheat = Object.assign(clone(stored), { chars: [Object.assign(clone(h), { skillPoints: h.skillPoints + 5 })] });
      check('...and five skill points more than it earned are put back', progress.check(stored, cheat, pm, Date.now()).length === 1 && cheat.chars[0].skillPoints === h.skillPoints);
      check('a stat potion drunk straight from a loot bag counts (once); one the server never gave is put back', bagOk && twiceOut, bagOk + ' ' + twiceOut + ' ' + fixes.join(' | '));
      // deeper skills cost more a rank: Ferocity (tier 2) is 2 points, so 3 ranks for 3 points is put back
      const cheap = Object.assign(clone(stored), { chars: [Object.assign(clone(h), { skills: { brutality: 2, ferocity: 3 }, skillPoints: h.skillPoints - 3 })] });
      const fair = Object.assign(clone(stored), { chars: [Object.assign(clone(h), { skills: { brutality: 2, ferocity: 3 }, skillPoints: h.skillPoints - 6 })] });
      check('skills cost their tier\'s price: 3 ranks of a 2-point skill for 3 points is put back, for 6 it\'s fine',
        progress.check(stored, cheap, pm, Date.now()).length === 1 && progress.check(stored, fair, pm, Date.now()).length === 0);
      // a hero from the old three-branch tree gets its points back to spend again
      const oldTree = Object.assign(clone(stored), { chars: [Object.assign(clone(h), { skills: { ferocity: 3, executioner: 1 }, tree3: false })] });
      const refunded = Object.assign(clone(oldTree), { chars: [Object.assign(clone(h), { skills: {}, skillPoints: h.skillPoints + 4, tree3: true })] });
      check('...and a hero from the old tree gets every spent point back once (the server accepts it)', progress.check(oldTree, refunded, pm, Date.now()).length === 0);
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

  console.log('account numbers, revives and password resets');
  {
    const bz = await login('TestBoss', { password: 'pass1234' });
    const notes = (c) => c.msgs.filter((m) => m.t === 'msg').map((m) => m.text).join('\n');
    check('accounts made before numbers are numbered oldest first', noA === 3 && noB === 4, noA + ',' + noB);
    bz.clear();
    bz.send({ t: 'cmd', text: '/whois #1' });
    await wait(200);
    check('/whois #number finds the account', /#1 Zold/.test(notes(bz)), notes(bz));
    const vn = 'Tv' + n;
    const V = await login(vn, { password: 'pass1234', register: true });
    const noV = V.find((m) => m.t === 'welcome').no;
    check('a new account gets the next number', noV > noB, String(noV));
    const hero = { id: 'hv', cls: 'wizard', name: 'Vic', level: 1, inv: [null, null, null, null, null, null, null, null] };
    V.send({ t: 'save', data: { gold: 0, fame: 0, chars: [hero] } });
    await wait(450);
    V.send({ t: 'save', data: { gold: 0, fame: 0, chars: [], deaths: 1, graves: [{ name: 'Vic', cls: 'wizard', level: 1, killer: 'Gorehorn' }] } });
    await wait(450);
    bz.clear();
    bz.send({ t: 'cmd', text: '/graves ' + vn });
    await wait(200);
    check('/graves lists a fallen hero and what killed it', /1\) Vic, level 1 Wizard, died .* to Gorehorn/.test(notes(bz)), notes(bz));
    B.clear();
    B.send({ t: 'cmd', text: '/revive ' + vn + ' 1' });
    await wait(200);
    check('players who are not admins cannot revive heroes', /Only server admins/.test(notes(B)));
    V.clear(); bz.clear();
    bz.send({ t: 'cmd', text: '/revive #' + noV + ' 1' });
    await wait(250);
    const rv = V.find((m) => m.t === 'revived');
    check('/revive brings the hero back, and the player is told at once', rv && rv.hero.id === 'hv' && rv.deaths === 0 && !rv.graves.length && /Revived Vic/.test(notes(bz)), notes(bz));
    // the game's next save from before it heard of the revive can't undo it
    V.clear();
    V.send({ t: 'save', data: { gold: 0, fame: 0, chars: [] } });
    await wait(450);
    const kept = V.find((m) => m.t === 'saveRejected');
    check('a save sent before the revive arrived cannot remove the hero again', kept && kept.data.chars.some((h) => h && h.id === 'hv'));
    V.clear();
    V.send({ t: 'save', data: { gold: 0, fame: 0, chars: [rv.hero], tradeSeq: rv.seq } });
    await wait(450);
    check('the revived hero saves normally', !V.find((m) => m.t === 'saveRejected'), JSON.stringify(V.find((m) => m.t === 'saveRejected')));
    bz.clear();
    bz.send({ t: 'cmd', text: '/revive ' + vn + ' 1' });
    await wait(200);
    check('a hero can only be revived once', /no fallen heroes/.test(notes(bz)), notes(bz));
    bz.clear(); V.clear();
    bz.send({ t: 'cmd', text: '/setpassword ' + vn + ' fresh5678' });
    await wait(400);
    check('/setpassword sets a new password and logs the player out', /New password set/.test(notes(bz)) && V.find((m) => m.t === 'kicked'), notes(bz));
    const vOld = await login(vn, { password: 'pass1234' });
    const vNew = await login(vn, { password: 'fresh5678' });
    check('the old password no longer works and the new one does', vOld.find((m) => m.t === 'error') && vNew.find((m) => m.t === 'welcome'));
    B.clear();
    B.send({ t: 'cmd', text: '/setpassword ' + vn + ' hacked123' });
    await wait(200);
    check('players who are not admins cannot set passwords', /Only server admins/.test(notes(B)));
    for (const c of [V, vOld, vNew, bz]) c.s.destroy();
  }

  console.log('realm close: into its finale, then the Dark Elder');
  {
    const { WorldSim } = require('./sim/worldsim');
    const { Data: RD, Bosses: RB } = require('./sim/gen/game');
    const ws = new WorldSim('realm:Medusa:123456789');
    const me = { id: 1, x: ws.w.spawnX, y: ws.w.spawnY, maxDps: 1e9, send: () => {} };
    ws.join(me);
    let opened = null;
    ws.onPortal = (k) => { opened = k; };
    ws.w.eventsDone = RD.EVENTS_PER_REALM - 1;
    for (let i = 0; i < 4000 && !ws.w.boss; i++) ws.tick(0.1);
    const b = ws.w.boss;
    if (b) { me.x = b.x; me.y = b.y + 2; for (let i = 0; i < 400 && !b.dead; i++) { ws.hit(me, { id: b.id, d: 6000 }); for (const e of ws.enemies) if (e.def.prop && !e.dead) ws.hit(me, { id: e.id, d: 6000 }); } }
    // the game's own choice (Game.finaleFor and enterCitadel), worked out here the same way
    const seed = 123456789, fid = RB.FINALES[seed % RB.FINALES.length];
    const want = 'dg:' + RD.dungeonIndex(fid) + ':' + ((((seed * 2654435761) & 0x7fffffff) | 1) >>> 0);
    check('when a realm starts closing, the server opens the way into its finale (the one every player there is pulled into)', b && b.dead && ws.closeT > 0 && opened === want, opened + ' vs ' + want);
    check('every finale ends in a way to the Dark Elder: the Citadel by its lieutenants, the others by their boss',
      RB.FINALES.every((f) => { const d = RD.DUNGEONS[RD.dungeonIndex(f)]; return d && (d.toElder || (d.boss && RD.ENEMIES[d.boss] && RD.ENEMIES[d.boss].finale)); }));
  }

  console.log('renaming accounts and heroes');
  {
    const on = 'Trn' + n, nn = 'Tnew' + n;
    const R1 = await login(on, { password: 'pass1234', register: true });
    const { Data: RN } = require('./sim/gen/game');
    R1.send({ t: 'save', data: { gold: 0, fame: 0, chars: [{ id: 'rn1', cls: 'wizard', name: 'Rudeword', level: 1, stats: clone(RN.CLASSES.wizard.base), inv: [null, null, null, null, null, null, null, null] }] } });
    await wait(400);
    const bz4 = await login('TestBoss', { password: 'pass1234' });
    const notes4 = () => bz4.msgs.filter((m) => m.t === 'msg').map((m) => m.text).join('\n');
    bz4.send({ t: 'cmd', text: '/rename ' + on + ' ' + nn });
    await wait(400);
    check('/rename changes an account\'s name (the player on it is logged out)', /Renamed/.test(notes4()) && R1.find((m) => m.t === 'kicked'), notes4());
    const oldL = await login(on, { password: 'pass1234' });
    const newL = await login(nn, { password: 'pass1234' });
    const wn = newL.find((m) => m.t === 'welcome');
    check('...the old name no longer logs in, the new one does with the same password, and the heroes are still there',
      oldL.find((m) => m.t === 'error') && wn && wn.name === nn && wn.save.chars.some((h) => h && h.id === 'rn1'), JSON.stringify(wn && wn.name));
    bz4.clear();
    bz4.send({ t: 'cmd', text: '/heroname ' + nn + ' Rudeword Hero' + (n % 100) });
    await wait(400);
    const back = await login(nn, { password: 'pass1234' });
    const wb = back.find((m) => m.t === 'welcome');
    check('/heroname renames a hero', /Renamed/.test(notes4()) && wb && wb.save.chars.some((h) => h && h.name === 'Hero' + (n % 100)), notes4());
    for (const c of [R1, oldL, newL, back, bz4]) c.s.destroy();
  }

  console.log('locked gear, the Oracle and /realms');
  {
    const { Market: M3 } = require('./market');
    const t3 = {};
    const mk3 = new M3((f, d) => t3[f] || d, (f, o) => { t3[f] = o; });
    const lsv = { gold: 0, chars: [], _ledger: { s1: { f: 'x', t: 0 } } };
    const linv = [{ name: 'Precious', kind: 'ring', sid: 's1', locked: true }];
    check('locked gear can\'t be listed on the Marketplace', /locked/.test(String(mk3.list(lsv, 'lk', 'Lk', linv, 0, 100))) && linv[0]);
    const oracle = require('./oracle');
    const osv = {};
    oracle.record(osv, 'cube', 'Cube Overlord', [{ name: 'Cube Crown', rarity: 'lg', uid: 'cube_crown' }, { name: 'Health Potion', kind: 'hp' }], 1000);
    oracle.record(osv, 'cube', 'Cube Overlord', [], 2000);
    const ob = oracle.view(osv).b.cube;
    check('the Oracle counts boss kills and what they dropped, and logs the rare ones',
      ob && ob.k === 2 && ob.d['Cube Crown'].c === 1 && ob.d['Health Potion'].c === 1 && oracle.view(osv).log.length === 1 && oracle.view(osv).log[0].name === 'Cube Crown', JSON.stringify(oracle.view(osv)));
    // a boss's collection: all its uniques found -> done (once), and its stat for every hero
    {
      const { Data: OD, Uniques: OU } = require('./sim/gen/game');
      const combat = require('./combat');
      const osv2 = {};
      const need = OD.bossUniques('ev_cube');
      oracle.record(osv2, 'ev_cube', 'Cube Overlord', [OU.make(need[0])], 1000);
      const none = oracle.completions(osv2);
      oracle.record(osv2, 'ev_cube', 'Cube Overlord', need.map((u) => OU.make(u)), 2000);
      const got = oracle.completions(osv2), again = oracle.completions(osv2);
      const st = OD.oracleStat('ev_cube');
      const hero = { cls: 'wizard', stats: { hp: 100, mp: 100, att: 20, def: 0, spd: 10, dex: 10, vit: 10, wis: 10, mgt: 0, luc: 0, prt: 0 }, level: 1 };
      const base = combat.stat(hero, st), withB = combat.stat(hero, st, OD.oracleBonus(osv2.oracleDone));
      check('the Oracle: finding every unique of a boss completes its collection once, and its stat counts for every hero (server caps too)',
        none.length === 0 && got.length === 1 && got[0] === 'ev_cube' && again.length === 0 && withB - base === (st === 'hp' || st === 'mp' ? 5 : 1) && oracle.collectionCount() > 20 && OD.findTitle('oracle_ev_cube'),
        JSON.stringify([none, got, again, base, withB]));
    }
    const bz5 = await login('TestBoss', { password: 'pass1234' });
    const realmsBefore = bz5.find((m) => m.t === 'welcome').realms.length;
    check('one realm is open by default', realmsBefore === 1, String(realmsBefore));
    bz5.clear();
    bz5.send({ t: 'cmd', text: '/realms 2' });
    await wait(1500);
    const rl2 = bz5.msgs.filter((m) => m.t === 'realms').pop();
    check('/realms 2 opens a second realm', rl2 && rl2.list.length === 2, JSON.stringify(rl2 || bz5.msgs.filter((m) => m.t === 'msg').map((m) => m.text)));
    bz5.send({ t: 'cmd', text: '/realms 1' });
    await wait(1500);
    const rl1 = bz5.msgs.filter((m) => m.t === 'realms').pop();
    check('...and /realms 1 closes it again once it\'s empty', rl1 && rl1.list.length === 1, JSON.stringify(rl1));
    bz5.clear();
    bz5.send({ t: 'oracleView' });
    await wait(250);
    check('the game can ask for its Oracle record', !!bz5.find((m) => m.t === 'oracle' && m.o && m.o.b));
    bz5.clear();
    bz5.send({ t: 'cmd', text: '/siege' });
    await wait(400);
    check('admins can start a Realm Siege (/siege): everyone is told', bz5.find((m) => m.t === 'banner' && /SIEGE/.test(m.text)) && bz5.find((m) => m.t === 'msg' && /begun/.test(m.text)), JSON.stringify(bz5.msgs.slice(0, 4)));
    bz5.send({ t: 'cmd', text: '/siege' });
    await wait(300);
    check('...one at a time', bz5.find((m) => m.t === 'msg' && /already a siege/.test(m.text)));
    bz5.s.destroy();
  }

  console.log('/glands');
  {
    const G2 = await login('Tgl' + n, { password: 'pass1234', register: true });
    const rl = G2.find((m) => m.t === 'welcome').realms[0];
    const { Data: GL, World: GW } = require('./sim/gen/game');
    G2.send({ t: 'save', data: { gold: 0, fame: 0, chars: [{ id: 'gl1', cls: 'wizard', name: 'Gl', level: 1, stats: clone(GL.CLASSES.wizard.base), inv: [null, null, null, null, null, null, null, null] }] } });
    await wait(300);
    const rw = new GW('realm', rl.name, null, rl.seed >>> 0);
    G2.send({ t: 'enter', key: 'realm:' + rl.name + ':' + rl.seed, cid: 'gl1', x: rw.spawnX, y: rw.spawnY });
    await wait(300);
    G2.clear();
    G2.send({ t: 'glands' });
    await wait(200);
    const gp = G2.find((m) => m.t === 'glandsPos');
    check('/glands: the server picks a spot in the Godlands', gp && rw.zoneAt(gp.x, gp.y) === GW.GOD_ZONE, JSON.stringify(gp));
    G2.clear();
    if (gp) G2.send({ t: 'move', x: gp.x, y: gp.y, f: 0 });
    await wait(200);
    check('...and the jump there is allowed (not put back)', gp && !G2.find((m) => m.t === 'pos'), JSON.stringify(G2.find((m) => m.t === 'pos')));
    G2.clear();
    G2.send({ t: 'enter', key: 'realm:' + rl.name + ':' + rl.seed, cid: 'gl1', x: gp ? gp.x : rw.spawnX, y: gp ? gp.y : rw.spawnY });
    await wait(1300);
    const spm = G2.msgs.filter((m) => m.t === 'spires').pop();
    check('players in a realm are shown its four Godlands Spires', spm && spm.l.length === 4 && spm.l.every((sp) => rw.zoneAt(sp.x, sp.y) === GW.GOD_ZONE && sp.name), JSON.stringify(spm && spm.l));
    G2.clear();
    G2.send({ t: 'cmd', text: '/spires' });
    await wait(300);
    check('/spires: who holds each Spire', G2.find((m) => m.t === 'msg' && /North Spire: nobody/.test(m.text)), JSON.stringify(G2.msgs));
    G2.s.destroy();
  }

  console.log('backpacks and pet feeds through the server');
  {
    const nm = 'Tf' + n;
    const F = await login(nm, { password: 'pass1234', register: true });
    const { Data: FD3 } = require('./sim/gen/game');
    const fh = { id: 'fh1', cls: 'wizard', name: 'Feeder', level: 1, stats: clone(FD3.CLASSES.wizard.base), inv: [null, null, null, null, null, null, null, null] };
    F.send({ t: 'save', data: { gold: 0, fame: 0, chars: [fh] } });
    await wait(400);
    F.send({ t: 'enter', key: 'nexus', cid: 'fh1', x: 100, y: 100 });
    const bz3 = await login('TestBoss', { password: 'pass1234' });
    bz3.send({ t: 'cmd', text: '/give ' + nm + ' 10000 gold' });
    await wait(300);
    const given = F.find((m) => m.t === 'given');
    let seqF = given ? given.seq : 0, goldF = given ? given.gold : 0;
    const dataF = (extra) => Object.assign({ gold: goldF, fame: 0, chars: [clone(fh)], tradeSeq: seqF }, extra || {});
    F.clear();
    F.send({ t: 'buy', what: 'backpack', data: dataF(), cid: 'fh1' });
    await wait(400);
    const bp = F.find((m) => m.t === 'shopDone');
    check('the server sells a backpack (the gold goes, the bag gets 8 more slots)', bp && bp.backpack && bp.inv.length === 16 && bp.gold === 7000, JSON.stringify(bp || F.find((m) => m.t === 'shopFail')));
    if (bp) { seqF = bp.seq; goldF = bp.gold; fh.backpack = true; fh.inv = bp.inv; }
    F.clear();
    F.send({ t: 'hatch', data: dataF(), cid: 'fh1' });
    await wait(400);
    const hp2 = F.find((m) => m.t === 'shopDone');
    if (hp2) { seqF = hp2.seq; goldF = hp2.gold; }
    F.clear();
    F.send({ t: 'petFeed', data: dataF({ pet: hp2 && hp2.pet }), cid: 'fh1' });
    await wait(400);
    check('pets aren\'t fed for gold any more (they grow from the XP you earn)', !F.find((m) => m.t === 'shopDone') && /XP you earn/.test((F.find((m) => m.t === 'shopFail') || {}).msg), JSON.stringify(F.msgs.slice(-2)));
    const fed = hp2;
    const { wallet: W2 } = { wallet: require('./wallet') };
    const psv = {};
    W2.credit({}, psv, 'x', { def: { xp: 500 }, zone: 4, isBoss: true }, Date.now(), false);
    W2.credit({}, psv, 'x', { def: { xp: 100 }, zone: 4 }, Date.now(), true);
    check('...and the server credits the pet a share of each kill\'s XP, close-by kills too', psv._petb === FD3.petKillXp(750) + FD3.petKillXp(150), String(psv._petb));
    F.clear();
    // the game's next save, with gold picked up meanwhile: nothing is put back
    F.send({ t: 'save', data: dataF({ pet: fed && fed.pet, gold: goldF }) });
    await wait(450);
    check('a save after buying a backpack and hatching a pet keeps both', !F.find((m) => m.t === 'saveRejected'), JSON.stringify(F.find((m) => m.t === 'saveRejected')));
    for (const c of [F, bz3]) c.s.destroy();
  }

  console.log('roles: owner, moderators and VIPs');
  {
    const { Data: RD } = require('./sim/gen/game');
    const bz8 = await login('TestBoss', { password: 'pass1234' });
    const M8 = await login('Tmod' + n, { password: 'pass1234', register: true });
    const V8 = await login('Tvip' + n, { password: 'pass1234', register: true });
    const P8 = await login('Tpl' + n, { password: 'pass1234', register: true });
    const note = (c) => c.msgs.filter((m) => m.t === 'msg').map((m) => m.text).join(' | ');
    check('the owner (the first admin here) is told so', bz8.find((m) => m.t === 'welcome').role === 'owner');
    bz8.send({ t: 'cmd', text: '/mod Tmod' + n });
    bz8.send({ t: 'cmd', text: '/vip Tvip' + n + ' 30' });
    await wait(400);
    check('/mod and /vip: the players are told their new role', M8.find((m) => m.t === 'role' && m.role === 'mod') && V8.find((m) => m.t === 'role' && m.role === 'vip' && m.vip), JSON.stringify([M8.msgs.slice(-2), V8.msgs.slice(-2)]));
    M8.clear();
    M8.send({ t: 'cmd', text: '/give Tpl' + n + ' 1000 gold' });
    M8.send({ t: 'cmd', text: '/kick TestBoss' });
    M8.send({ t: 'cmd', text: '/ban Tpl' + n + ' spam' });
    await wait(400);
    check('moderators can\'t /give, can\'t touch staff, and only ban for a while', /Only server admins can use \/give/.test(note(M8)) && /can't kick other staff/.test(note(M8)) && /up to 72 hours/.test(note(M8)), note(M8));
    M8.clear();
    M8.send({ t: 'cmd', text: '/kick Tpl' + n + ' calm down' });
    await wait(400);
    check('...but they can kick players', P8.find((m) => m.t === 'kicked') && /Kicked/.test(note(M8)), note(M8));
    // VIP: /l20 and /backpack on the hero being played
    const vh = { id: 'vh1', cls: 'wizard', name: 'Vippy', level: 1, xp: 0, stats: clone(RD.CLASSES.wizard.base), inv: [null, null, null, null, null, null, null, null] };
    V8.send({ t: 'save', data: { gold: 0, fame: 0, chars: [vh] } });
    await wait(400);
    V8.send({ t: 'enter', key: 'nexus', cid: 'vh1', x: 100, y: 100 });
    await wait(200);
    V8.clear();
    V8.send({ t: 'cmd', text: '/l20' });
    await wait(400);
    const lv = V8.find((m) => m.t === 'saveRejected');
    const h20 = lv && lv.data.chars.find((h) => h.id === 'vh1');
    check('VIP /l20 takes the hero to level 20 with its stats and skill points (the game reloads it)', h20 && h20.level === 20 && h20.skillPoints === 19 && h20.stats.att > RD.CLASSES.wizard.base.att && /VIP/.test(lv.reason), JSON.stringify(lv && lv.reason));
    V8.clear();
    V8.send({ t: 'cmd', text: '/backpack' });
    await wait(400);
    const bp8 = V8.find((m) => m.t === 'shopDone');
    check('...and /backpack gives it a backpack', bp8 && bp8.backpack && bp8.inv.length === 16, JSON.stringify(bp8 || note(V8)));
    // and the next save, from the game that took the server's copy, is fine
    V8.clear();
    V8.send({ t: 'save', data: Object.assign({}, lv.data, { chars: [Object.assign({}, h20, { backpack: true, inv: bp8.inv })], tradeSeq: bp8.seq }) });
    await wait(400);
    check('...and the game\'s next save keeps both', !V8.find((m) => m.t === 'saveRejected'), JSON.stringify(V8.find((m) => m.t === 'saveRejected')));
    P8.s.destroy();
    const P9 = await login('Tpl' + n, { password: 'pass1234' });
    P9.send({ t: 'cmd', text: '/l20' });
    await wait(300);
    check('players without VIP can\'t use /l20', /VIP perk/.test(note(P9)), note(P9));
    for (const c of [bz8, M8, V8, P9]) c.s.destroy();
  }

  console.log('ascension');
  {
    const { Data: AD } = require('./sim/gen/game');
    const A1 = await login('Tasc' + n, { password: 'pass1234', register: true });
    const AB = await login('TestBoss', { password: 'pass1234' });
    const ah = { id: 'as1', cls: 'wizard', name: 'Asc', level: 1, xp: 0, stats: clone(AD.CLASSES.wizard.base), inv: [null, null, null, null, null, null, null, null] };
    A1.send({ t: 'save', data: { gold: 0, fame: 0, chars: [ah] } });
    await wait(400);
    A1.send({ t: 'enter', key: 'nexus', cid: 'as1', x: 100, y: 100 });
    await wait(200);
    A1.clear();
    A1.send({ t: 'ascend' });
    await wait(300);
    check('a hero that isn\'t maxed can\'t ascend', A1.find((m) => m.t === 'shopFail' && /level 20/.test(m.msg)), JSON.stringify(A1.msgs));
    AB.send({ t: 'cmd', text: '/maxhero Tasc' + n });
    await wait(300);
    const mx = A1.find((m) => m.t === 'saveRejected');
    const hm = mx && mx.data.chars.find((h) => h.id === 'as1');
    check('/maxhero: level 20, every stat maxed', hm && hm.level === 20 && AD.canAscend(hm), JSON.stringify(mx && mx.reason));
    A1.clear();
    A1.send({ t: 'ascend' });
    await wait(400);
    const as = A1.find((m) => m.t === 'asc'), rs = A1.find((m) => m.t === 'saveRejected');
    const ha = rs && rs.data.chars.find((h) => h.id === 'as1');
    check('ascending: back to level 1 with base stats, its inventory kept, the skill points past 20 kept, +1 point', as && as.asc.pts === 1 && as.ascended === 1 && ha && ha.level === 1 && ha.asc === 1 &&
      ha.stats.att === AD.CLASSES.wizard.base.att && ha.name === 'Asc' && ha.inv.length === 8 && ha.skillPoints === 0 && /Ascended/.test(rs.reason), JSON.stringify([as, ha && ha.level, ha && ha.skillPoints, rs && rs.reason]));
    A1.clear();
    A1.send({ t: 'ascSpend', id: 'might' });
    await wait(300);
    const sp = A1.find((m) => m.t === 'asc');
    check('spending the point: a rank of Ascendant Might', sp && sp.asc.pts === 0 && sp.asc.r.might === 1, JSON.stringify(A1.msgs));
    A1.clear();
    A1.send({ t: 'ascSpend', id: 'might' });
    await wait(300);
    check('...and no more without points', A1.find((m) => m.t === 'shopFail'), JSON.stringify(A1.msgs));
    const combat = require('./combat');
    const ob = AD.oracleBonus([], sp.asc);
    check('Ascendant Might and Vigor count in the server\'s stat caps', combat.stat(ha, 'att', ob) - combat.stat(ha, 'att') === 1 && AD.oracleBonus([], { r: { vigor: 2 } }).hp === 20);
    // the game's next save, from the reloaded hero, is accepted
    A1.clear();
    A1.send({ t: 'save', data: Object.assign({}, rs.data, { asc: sp.asc, tradeSeq: sp.seq }) });
    await wait(400);
    check('...and the game\'s next save is fine', !A1.find((m) => m.t === 'saveRejected'), JSON.stringify(A1.find((m) => m.t === 'saveRejected')));
    // skill ranks: never past a skill's top, and no made-up skills (whatever a changed game saves)
    const hk = Object.assign({}, ha, { skills: { brutality: 50, made_up: 3 } });
    A1.clear();
    A1.send({ t: 'save', data: Object.assign({}, rs.data, { asc: sp.asc, tradeSeq: sp.seq, chars: [hk] }) });
    await wait(400);
    const sk = AQ_skills(A1, 'as1');
    check('a save can\'t raise a skill past its top rank or invent one', !sk || (!(sk.brutality > 5) && sk.made_up === undefined), JSON.stringify(sk));
    // the damage limits never count ranks past the top either
    const combat2 = require('./combat');
    const capsA = combat2.caps({ cls: 'wizard', level: 20, stats: clone(AD.CLASSES.wizard.max), skills: { brutality: 5 } }, null);
    const capsB = combat2.caps({ cls: 'wizard', level: 20, stats: clone(AD.CLASSES.wizard.max), skills: { brutality: 5000 } }, null);
    check('...and the damage limits ignore ranks past the top', capsA.hit === capsB.hit, capsA.hit + ' vs ' + capsB.hit);
    A1.s.destroy();
    AB.s.destroy();
  }

  console.log('the endless abyss (online)');
  {
    const { Data: AQ } = require('./sim/gen/game');
    const nm = 'Tdeep' + n;
    const P = await login(nm, { password: 'pass1234', register: true });
    const AD2 = await login('TestBoss', { password: 'pass1234' });
    P.send({ t: 'save', data: { gold: 0, fame: 0, chars: [{ id: 'dp1', cls: 'wizard', name: 'Diver', level: 1, xp: 0, stats: clone(AQ.CLASSES.wizard.base), inv: [null, null, null, null, null, null, null, null] }] } });
    await wait(400);
    P.send({ t: 'enter', key: 'nexus', cid: 'dp1', x: 100, y: 100 });
    await wait(200);
    P.clear();
    P.send({ t: 'enter', key: 'deep:4545', cid: 'dp1', x: 100.5, y: 113.5 });
    await wait(300);
    check('a hero under level 20 can\'t enter the Abyss', P.find((m) => m.t === 'toNexus'));
    P.send({ t: 'enter', key: 'nexus', cid: 'dp1', x: 100, y: 100 });
    AD2.send({ t: 'cmd', text: '/maxhero ' + nm });
    await wait(400);
    P.clear();
    P.send({ t: 'enter', key: 'deep:4545', cid: 'dp1', x: 100.5, y: 113.5 });
    await wait(300);
    check('a level 20 hero can: a run starts, the first wave on its way', !P.find((m) => m.t === 'toNexus') && P.find((m) => m.t === 'abyssRun' && m.on && m.wave === 0) &&
      P.find((m) => m.t === 'deepWave' && m.state === 'break' && m.secs > 0), JSON.stringify(P.msgs.slice(0, 4)));
    P.send({ t: 'abyssBoon', id: 'might' });
    await wait(200);
    check('no boon without one being offered', !P.msgs.some((m) => m.t === 'abyssRun' && m.boons && m.boons.length));
    // an admin in the same arena clears wave 1
    AD2.send({ t: 'enter', key: 'deep:4545', x: 100.5, y: 113.5 });
    P.clear();
    for (let k = 0; k < 60 && !P.find((m) => m.t === 'deepWave' && m.state === 'fight'); k++) await wait(250);
    const fight = P.find((m) => m.t === 'deepWave' && m.state === 'fight');
    check('wave 1 starts after the break', fight && fight.wave === 1 && fight.left > 0, JSON.stringify(fight));
    AD2.clear();
    AD2.send({ t: 'w', to: 'host', d: { t: 'sync' } });
    await wait(300);
    const dsp = AD2.find((m) => m.t === 'w' && m.d.t === 'espawn');
    for (const e of (dsp ? dsp.d.l : [])) {
      AD2.send({ t: 'move', x: e[2], y: e[3] + 1 });
      await wait(60);
      for (let k = 0; k < 5; k++) AD2.send({ t: 'w', to: 'host', d: { t: 'ehit', id: e[0], d: 5e6 } });
    }
    await wait(500);
    check('wave cleared: everyone in the arena hears it and the run counts it', P.find((m) => m.t === 'deepWave' && m.state === 'cleared' && m.wave === 1) && P.find((m) => m.t === 'abyssRun' && m.wave === 1),
      JSON.stringify(P.msgs.filter((m) => m.t === 'deepWave').slice(-3)));
    check('...and the monsters dropped nothing', !P.find((m) => m.t === 'w' && m.d.t === 'loot') && !AD2.find((m) => m.t === 'w' && m.d.t === 'loot'));
    P.clear();
    P.send({ t: 'deepBoard', cls: 'wizard' });
    await wait(250);
    const bd = P.find((m) => m.t === 'deepBoard');
    check('the week\'s board: the best waves of each class (the diver is on it)', bd && bd.list.some((r) => r.name === nm && r.wave === 1 && r.hero === 'Diver') && bd.best === 1, JSON.stringify(bd));
    P.clear();
    P.send({ t: 'enter', key: 'nexus', cid: 'dp1', x: 100, y: 100 });
    await wait(250);
    check('leaving the Abyss ends the run', P.find((m) => m.t === 'abyssRun' && !m.on));
    P.s.destroy(); AD2.s.destroy();
  }

  console.log('bug reports');
  {
    const B7 = await login('Tbug' + n, { password: 'pass1234', register: true });
    const bz7 = await login('TestBoss', { password: 'pass1234' });
    const before = posts.length;
    B7.send({ t: 'bug', text: 'my pet vanished after swapping heroes', ctx: { ver: 'v1.1', fps: 58, ping: 40 } });
    await wait(600);
    const thanks = B7.msgs.find((m) => m.t === 'msg' && /Bug #\d+ was sent/.test(m.text));
    check('/bug thanks the player and tells online admins', thanks && bz7.msgs.some((m) => m.t === 'msg' && /\[Bug #\d+\].*pet vanished/.test(m.text)), JSON.stringify(B7.msgs.slice(-2)));
    check('...and posts it to the Discord feed', posts.slice(before).some((p) => JSON.stringify(p).includes('pet vanished')), JSON.stringify(posts.slice(before)));
    B7.clear();
    B7.send({ t: 'bug', text: 'second report straight away' });
    await wait(300);
    check('...one report every 30 seconds per player', B7.msgs.some((m) => m.t === 'msg' && /Wait a moment/.test(m.text)));
    bz7.clear();
    bz7.send({ t: 'cmd', text: '/bugs' });
    await wait(300);
    const bl = bz7.find((m) => m.t === 'bugs');
    const mine = bl && bl.list.find((b) => b.name === 'Tbug' + n);
    check('/bugs lists reports with who, where and the game\'s fps and ping', mine && /pet vanished/.test(mine.text) && mine.fps === 58 && mine.ping === 40 && !mine.done, JSON.stringify(bl && bl.list.slice(0, 1)));
    bz7.clear();
    bz7.send({ t: 'cmd', text: '/bugs done ' + (mine ? mine.id : 0) });
    await wait(300);
    const bl2 = bz7.find((m) => m.t === 'bugs');
    check('/bugs done marks one fixed', bl2 && bl2.list.find((b) => mine && b.id === mine.id && b.done));
    for (const c of [B7, bz7]) c.s.destroy();
  }

  console.log('pet evolution, the Stable, runes and the Anvil');
  {
    const { Data: PD } = require('./sim/gen/game');
    // the numbers
    const juv = { species: 'golem', rarity: 'common', level: 12, stage: 1 };
    check('pets: a Juvenile Golem guards you (+3 Defense) and a common pet stops at Adult',
      PD.petDef(juv) === 3 && PD.petMaxStage(juv) === 2 && PD.petEvolveBlock({ species: 'pup', rarity: 'rare', level: 9 }) !== null && PD.petEvolveBlock({ species: 'pup', rarity: 'rare', level: 10 }) === null);
    const ring = PD.makeRing('att', 3, 'ut');
    const withRune = PD.rerollStatsWith(ring, 'dex');
    check('a rune makes sure its stat is among a reroll\'s bonuses', withRune.dex > 0 && withRune.rarity === 'ut' && !PD.canUseRune(PD.makeWeapon('sword', 7, 'ut'), 'spd'));
    const t3 = PD.makeArmor('heavy', 3, null);
    const upA = PD.anvilStep(t3, true), downA = PD.anvilStep(t3, false), topUp = PD.anvilStep(PD.makeArmor('heavy', 7, null), true);
    check('the Anvil climbs tiers, then Runed, Bonded, Eldritch (and refuses locked, unique and Starforged items)',
      upA.tier === 4 && downA.tier === 2 && topUp.rarity === 'ut' && PD.anvilStep(PD.makeRing('hp', 0, null), false) === null &&
      PD.anvilBlock(Object.assign(PD.makeArmor('heavy', 3, null), { locked: true })) !== null && PD.anvilBlock(PD.makeArmor('heavy', 7, 'lg')) !== null && PD.anvilBlock(PD.makeArmor('heavy', 7, 'fb')) !== null);
    // through the server
    const nm = 'Te' + n;
    const E = await login(nm, { password: 'pass1234', register: true });
    const eh = { id: 'eh1', cls: 'wizard', name: 'Evolver', level: 1, stats: clone(PD.CLASSES.wizard.base), inv: [null, null, null, null, null, null, null, null] };
    E.send({ t: 'save', data: { gold: 0, fame: 0, chars: [eh] } });
    await wait(400);
    E.send({ t: 'enter', key: 'nexus', cid: 'eh1', x: 100, y: 100 });
    const bz6 = await login('TestBoss', { password: 'pass1234' });
    bz6.send({ t: 'cmd', text: '/give ' + nm + ' 30000 gold' });
    await wait(300);
    const g6 = E.find((m) => m.t === 'given');
    let seq = g6 ? g6.seq : 0, gold = g6 ? g6.gold : 0, pet = null, stable = [];
    const take = (r) => { if (r) { seq = r.seq; gold = r.gold; eh.inv = r.inv; if (r.pet !== undefined) pet = r.pet; if (r.stable) stable = r.stable; } return r; };
    const data = () => Object.assign({ gold, fame: 0, chars: [clone(eh)], tradeSeq: seq }, pet ? { pet: clone(pet) } : {});
    const ask = async (msg) => { E.clear(); E.send(Object.assign({ data: data(), cid: 'eh1' }, msg)); await wait(350); return take(E.find((m) => m.t === 'shopDone')) || E.find((m) => m.t === 'shopFail'); };
    E.clear();
    bz6.send({ t: 'cmd', text: '/give ' + nm + ' 3 stone' });
    await wait(400);
    take(E.find((m) => m.t === 'shopDone'));
    check('/give name 3 stone puts Evolution Stones in an online player\'s inventory', eh.inv.filter((it) => it && it.kind === 'stone').length === 3, JSON.stringify(eh.inv));
    await ask({ t: 'hatch' });
    const early = await ask({ t: 'petEvolve' });
    check('a pet can\'t evolve before its level allows', early && early.t === 'shopFail' && /level 10/.test(early.msg), JSON.stringify(early));
    E.clear();
    bz6.send({ t: 'cmd', text: '/give ' + nm + ' 200 petxp' });
    await wait(400);
    take(E.find((m) => m.t === 'shopDone'));
    check('/give name 200 petxp grows an online player\'s pet', pet && pet.level >= 10, JSON.stringify(pet));
    // /give name [count] item name: any item, by name
    E.clear();
    bz6.send({ t: 'cmd', text: '/give ' + nm + ' siegebreaker' });
    await wait(400);
    take(E.find((m) => m.t === 'shopDone'));
    check('/give name siegebreaker hands an online player that unique', eh.inv.some((it) => it && it.name === 'Siegebreaker'), JSON.stringify(eh.inv));
    E.clear();
    bz6.send({ t: 'cmd', text: '/give ' + nm + ' 2 health potion' });
    await wait(400);
    take(E.find((m) => m.t === 'shopDone'));
    check('/give name 2 health potion gives two', eh.inv.filter((it) => it && it.kind === 'hp').length === 2, JSON.stringify(eh.inv));
    bz6.clear();
    bz6.send({ t: 'cmd', text: '/give ' + nm + ' potion' });
    bz6.send({ t: 'cmd', text: '/give ' + nm + ' zzqqxx' });
    await wait(400);
    const notes = JSON.stringify(bz6.msgs);
    check('/give with a vague name asks which one; an unknown name says so', /Which one\?/.test(notes) && /zzqqxx|No item|no item/i.test(notes), notes);
    // make room again for what follows
    eh.inv = eh.inv.map((it) => it && (it.kind === 'hp' || it.name === 'Siegebreaker') ? null : it);
    const goldBefore = gold;
    const evo = await ask({ t: 'petEvolve' });
    check('at level 10, a Stone and 500 gold evolve it to Juvenile (the server takes both)',
      evo && evo.evolved && pet.stage === 1 && eh.inv.filter((it) => it && it.kind === 'stone').length === 2 && gold === goldBefore - 500, JSON.stringify(evo));
    // a game that claims a later stage keeps the server's
    E.clear();
    E.send({ t: 'save', data: Object.assign(data(), { pet: Object.assign(clone(pet), { stage: 3, path: 'b' }) }) });
    await wait(400);
    const st1 = await ask({ t: 'petStable', op: 'store' });
    check('the server keeps the pet\'s real stage whatever the game says; the Stable takes it in', st1 && st1.stabled === 'store' && !pet && stable.length === 1 && stable[0].stage === 1 && !stable[0].path, JSON.stringify(st1));
    await ask({ t: 'hatch' });
    const second = pet;
    const sw = await ask({ t: 'petStable', op: 'take', i: 0 });
    check('...and swaps: the evolved pet comes out, the new one goes in', sw && pet && pet.stage === 1 && stable.length === 1 && stable[0].species === second.species && stable[0].level === second.level, JSON.stringify(sw));
    const bad = await ask({ t: 'anvil', slot: 7 });
    check('the Anvil refuses an empty slot', bad && bad.t === 'shopFail');
    // cursed gear: big boons, a stat below zero; the server's checks accept it and the Anvil won't touch it
    const { checkItem: CI } = require('./validate');
    const cur = PD.makeCursed(PD.CLASSES.wizard, 2, 'hexed');
    check('cursed gear: two boons and a price below zero, accepted by the save checks (an unknown curse isn\'t)',
      cur.curse === 'hexed' && cur.wis >= 16 && cur.hp < 0 && /^Hexed /.test(cur.name) && CI(cur) === null && CI(Object.assign({}, cur, { curse: 'mystery' })) !== null &&
      PD.anvilBlock(cur) !== null && !PD.canRerollStats(cur) && !PD.canRerollForm(PD.makeCursed(PD.CLASSES.wizard, 0)));
    E.clear();
    bz6.send({ t: 'cmd', text: '/give ' + nm + ' 1 cursed bloodbound' });
    await wait(400);
    take(E.find((m) => m.t === 'shopDone'));
    const ci = eh.inv.findIndex((it) => it && it.curse === 'bloodbound');
    E.clear();
    E.send({ t: 'save', data: data() });
    await wait(400);
    check('/give name 1 cursed bloodbound hands one out, and a save holding it is kept', ci >= 0 && !E.find((m) => m.t === 'saveRejected'), JSON.stringify(E.find((m) => m.t === 'saveRejected') || eh.inv));
    const curA = await ask({ t: 'anvil', slot: ci });
    check('...and the server\'s Anvil refuses it', curA && curA.t === 'shopFail' && /curse/.test(curA.msg), JSON.stringify(curA));
    for (const c of [E, bz6]) c.s.destroy();
  }

  console.log('health and damage the game reports');
  {
    const nm = 'Th' + n;
    let H = await login(nm, { password: 'pass1234', register: true });
    const realmsH = H.find((m) => m.t === 'welcome').realms;
    const { Data: HD2 } = require('./sim/gen/game');
    const hero = { id: 'hh1', cls: 'wizard', name: 'Hpx', level: 1, stats: clone(HD2.CLASSES.wizard.base), inv: [null, null, null, null, null, null, null, null] };
    H.send({ t: 'save', data: { gold: 0, fame: 0, chars: [hero] } });
    await wait(400);
    const rk = 'realm:' + realmsH[0].name + ':' + realmsH[0].seed;
    const goIn = (c) => { c.send({ t: 'enter', key: rk, cid: 'hh1', x: 100, y: 100, profile: { cls: 'wizard' } }); };
    goIn(H);
    await wait(300);
    // an honest report is left alone
    H.send({ t: 'hits', n: 0, d: 0, hp: 80, mhp: 80 });
    // ...a game claiming 99,999 health (its hero has 80) is flagged for the admins, never disconnected
    const bz2 = await login('TestBoss', { password: 'pass1234' });
    const t1 = setInterval(() => H.send({ t: 'hits', n: 0, d: 0, hp: 99999, mhp: 99999 }), 800);
    const told = () => bz2.msgs.find((m) => m.t === 'msg' && /\[Anti-cheat\] /.test(m.text) && m.text.includes(nm + ' (health)'));
    for (let k = 0; k < 50 && !told(); k++) await wait(500);
    clearInterval(t1);
    check('a game claiming more health than its hero can have is flagged to the admins', !!told(), JSON.stringify(bz2.msgs.filter((m) => m.t === 'msg').slice(-3)));
    check('...and is not disconnected', !H.find((m) => m.t === 'kicked') && !H.s.destroyed, JSON.stringify(H.find((m) => m.t === 'kicked')));
    bz2.send({ t: 'cmd', text: '/flags' });
    await wait(300);
    const fl = bz2.find((m) => m.t === 'flags');
    const me = fl && fl.list.find((f) => f.name === nm);
    check('/flags lists the flagged player, why, and that they\'re online', me && me.kinds.health >= 1 && me.online && me.notes[0] && /health/.test(me.notes[0].note), JSON.stringify(fl));
    bz2.clear();
    bz2.send({ t: 'cmd', text: '/flags clear ' + nm });
    await wait(300);
    const fl2 = bz2.find((m) => m.t === 'flags');
    check('/flags clear name takes them off the list', fl2 && !fl2.list.some((f) => f.name === nm), JSON.stringify(fl2));
    for (const c of [H, bz2]) c.s.destroy();
  }

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
