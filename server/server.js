#!/usr/bin/env node
/*
 * New Realm game server.
 *
 * Shares the Nexus and the realms between players: positions, chat, parties,
 * guilds and trades. Monsters still run in each player's own game for now.
 *
 * Run:  node server/server.js [port]      (default port 2050)
 *
 * Speaks newline-separated JSON over plain TCP (the AIR game) and over
 * WebSocket on the same port (browser builds / testing). No npm packages needed.
 */
'use strict';
const net = require('net');
const os = require('os');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = parseInt(process.argv[2] || process.env.PORT || '2050', 10);
/** Bump when the game and server stop understanding each other. */
const VERSION = 3;
const IDLE_KICK_MS = 45000;
const MAX_MSGS_PER_SEC = 250;
const DATA_DIR = path.join(__dirname, 'data');
const PARTY_MAX = 6;
const GUILD_MAX = 27;
const RANKS = ['Initiate', 'Member', 'Officer', 'Leader', 'Founder'];
const OFFICER = 2, FOUNDER = 4;
const REALM_NAMES = ['Ashveil', 'Thornwick', 'Glimmerfen', 'Duskhollow', 'Brineholt', 'Stormreach', 'Mirewood', 'Emberfall',
  'Frostgate', 'Sunspire', 'Wraithmoor', 'Ironvale', 'Starhaven', 'Mosscairn', 'Grimtide'];

// ------------------------------------------------------------------ storage
fs.mkdirSync(DATA_DIR, { recursive: true });
function load(file, fallback) {
  try { return JSON.parse(fs.readFileSync(path.join(DATA_DIR, file), 'utf8')); } catch (e) { return fallback; }
}
const saveTimers = {};
function save(file, obj) {
  clearTimeout(saveTimers[file]);
  saveTimers[file] = setTimeout(() => {
    const p = path.join(DATA_DIR, file);
    fs.writeFileSync(p + '.tmp', JSON.stringify(obj, null, 1));
    fs.renameSync(p + '.tmp', p);
  }, 300);
}
/** accounts[lowername] = {name, salt, hash, created} */
const accounts = load('accounts.json', {});
/** guilds[lowername] = {name, members: {lowername: {name, rank, cls, level, fame}}} */
const guilds = load('guilds.json', {});

function hashToken(token, salt) {
  return crypto.createHash('sha256').update(salt + ':' + token).digest('hex');
}

// ------------------------------------------------------------------ realms
/** The three realms behind the Nexus portals; the seed makes every game build the same map. */
let realms = [];
function rollRealms() {
  const pool = REALM_NAMES.slice();
  realms = [];
  for (let i = 0; i < 3; i++) {
    const name = pool.splice(Math.floor(Math.random() * pool.length), 1)[0];
    realms.push({ name, seed: 1 + Math.floor(Math.random() * 0x7ffffffe) });
  }
}
rollRealms();

// ------------------------------------------------------------------ clients
const clients = new Map(); // id -> client
const byName = new Map();  // lowername -> client
let nextId = 1;
const parties = new Map(); // party id -> {id, leader, members: Set<client>}
/** world key -> client whose game runs that world's monsters */
const hosts = new Map();
let nextParty = 1;

function log(...a) { console.log(new Date().toISOString().slice(11, 19), ...a); }

function str(v, max) { return typeof v === 'string' ? v.slice(0, max) : ''; }
function num(v) { return typeof v === 'number' && isFinite(v) ? v : 0; }

function inWorld(world, except) {
  const out = [];
  for (const c of clients.values()) if (c.authed && c.world === world && c !== except) out.push(c);
  return out;
}

function publicInfo(c) {
  return { id: c.id, name: c.name, x: c.x, y: c.y, profile: c.profile };
}

function guildOf(c) { return c.guild ? guilds[c.guild] : null; }

// ------------------------------------------------------------------ messages
const handlers = {
  hello(c, m) {
    if (c.authed) return;
    if (m.ver !== VERSION) return c.fail('Version mismatch: this server runs New Realm network version ' + VERSION +
      ' and your game uses version ' + m.ver + '. Get the same game build as the host.');
    const name = str(m.name, 12);
    const token = str(m.token, 64);
    if (!/^[A-Za-z0-9]{3,12}$/.test(name)) return c.fail('Invalid name.');
    if (token.length < 16) return c.fail('Invalid login token.');
    const key = name.toLowerCase();
    let acc = accounts[key];
    if (!acc) {
      const salt = crypto.randomBytes(8).toString('hex');
      acc = accounts[key] = { name, salt, hash: hashToken(token, salt), created: Date.now() };
      save('accounts.json', accounts);
      log('new account', name);
    } else if (hashToken(token, acc.salt) !== acc.hash) {
      return c.fail('The name "' + acc.name + '" belongs to someone else on this server.');
    }
    const old = byName.get(key);
    if (old) { old.send({ t: 'kicked', msg: 'You logged in from somewhere else.' }); old.close(); }
    c.authed = true;
    c.name = acc.name;
    c.key = key;
    byName.set(key, c);
    // guild membership lives on the server
    c.guild = null;
    for (const gk in guilds) if (guilds[gk].members[key]) c.guild = gk;
    c.send({ t: 'welcome', id: c.id, name: c.name, ver: VERSION, realms, online: byName.size });
    sendGuild(c.guild);
    log(c.name, 'joined (' + byName.size + ' online)');
  },

  enter(c, m) {
    const world = str(m.key, 80);
    leaveWorld(c);
    c.world = world;
    c.x = num(m.x); c.y = num(m.y);
    if (m.profile && typeof m.profile === 'object') c.profile = m.profile;
    if (c.trade) endTrade(c, 'The trade was cancelled.');
    // the first player in a world runs its monsters
    if (!hosts.get(world) || hosts.get(world).world !== world) hosts.set(world, c);
    c.send({ t: 'players', key: world, host: hosts.get(world).id, list: inWorld(world, c).map(publicInfo) });
    for (const o of inWorld(world, c)) o.send({ t: 'join', p: publicInfo(c) });
    updateGuildMember(c);
    sendParty(c.party);
    // let the party follow you into dungeons
    const p = parties.get(c.party);
    if (p && world.startsWith('dg:')) {
      for (const o of p.members) if (o !== c && o.world !== world) o.note(c.name + ' entered the ' + str(m.label, 40) + '. Type /join ' + c.name + ' to follow.', 0x7fd8ff);
    }
  },

  move(c, m) {
    c.x = num(m.x); c.y = num(m.y);
    const msg = { t: 'move', id: c.id, x: c.x, y: c.y, f: m.f ? 1 : 0, a: m.a ? 1 : 0 };
    for (const o of inWorld(c.world, c)) o.send(msg);
  },

  shoot(c, m) {
    const msg = { t: 'shoot', id: c.id, ang: num(m.ang) };
    for (const o of inWorld(c.world, c)) o.send(msg);
  },

  profile(c, m) {
    if (!m.profile || typeof m.profile !== 'object') return;
    c.profile = m.profile;
    for (const o of inWorld(c.world, c)) o.send({ t: 'profile', id: c.id, profile: c.profile });
    updateGuildMember(c);
  },

  chat(c, m) {
    const text = str(m.text, 120);
    if (!text) return;
    for (const o of inWorld(c.world, c)) o.send({ t: 'chat', id: c.id, name: c.name, text });
  },

  pchat(c, m) {
    const text = str(m.text, 120);
    const p = parties.get(c.party);
    if (!text || !p) return;
    for (const o of p.members) if (o !== c) o.send({ t: 'chat', ch: 'party', id: c.id, name: c.name, text });
  },

  gchat(c, m) {
    const text = str(m.text, 120);
    if (!text || !c.guild) return;
    for (const o of byName.values()) if (o !== c && o.guild === c.guild) o.send({ t: 'chat', ch: 'guild', id: c.id, name: c.name, text });
  },

  // ---------------------------------------------------------------- trading
  tradeReq(c, m) {
    const o = clients.get(m.to);
    if (!o || !o.authed || o.world !== c.world) return c.note('That player isn\'t here.');
    if (o.trade) return c.note(o.name + ' is busy trading.');
    if (c.trade) return;
    c.tradeAsk = o.id;
    o.send({ t: 'tradeReq', from: c.id, name: c.name });
  },

  tradeAns(c, m) {
    const o = clients.get(m.to);
    if (!o || o.tradeAsk !== c.id) return;
    o.tradeAsk = 0;
    if (!m.yes) return o.note(c.name + ' declined the trade.', 0xff8080);
    if (o.trade || c.trade) return;
    const t = { a: o, b: c, acc: new Set() };
    o.trade = c.trade = t;
    // the asker gets the answerer's inventory, then sends its own (tradeInv)
    o.send({ t: 'tradeStart', with: c.id, inv: Array.isArray(m.inv) ? m.inv : [], sendInv: true });
  },

  tradeInv(c, m) {
    const t = c.trade;
    if (!t || t.a !== c) return;
    t.b.send({ t: 'tradeStart', with: c.id, inv: Array.isArray(m.inv) ? m.inv : [] });
  },

  tradeOffer(c, m) {
    const t = c.trade;
    if (!t) return;
    t.acc.clear();
    partner(c).send({ t: 'tradeOffer', sel: Array.isArray(m.sel) ? m.sel : [], want: Array.isArray(m.want) ? m.want : [] });
  },

  tradeAccept(c) {
    const t = c.trade;
    if (!t) return;
    t.acc.add(c);
    partner(c).send({ t: 'tradeAccept' });
    if (t.acc.size === 2) {
      t.a.send({ t: 'tradeDone' });
      t.b.send({ t: 'tradeDone' });
      log('trade', t.a.name, '<->', t.b.name);
      t.a.trade = t.b.trade = null;
    }
  },

  tradeCancel(c) {
    if (c.trade) endTrade(c, c.name + ' cancelled the trade.');
  },

  // ---------------------------------------------------------------- party
  partyInvite(c, m) {
    const o = clients.get(m.to);
    if (!o || !o.authed) return c.note('That player isn\'t online.');
    let p = parties.get(c.party);
    if (p && p.members.has(o)) return c.note(o.name + ' is already in your party.');
    if (p && p.members.size >= PARTY_MAX) return c.note('Your party is full (' + PARTY_MAX + ' players max).');
    o.partyAsk = c.id;
    o.send({ t: 'partyInvite', from: c.id, name: c.name });
    c.note('You invited ' + o.name + ' to your party.', 0x7fd8ff);
  },

  partyAns(c, m) {
    const o = clients.get(m.from);
    if (!o || c.partyAsk !== o.id) return;
    c.partyAsk = 0;
    if (!m.yes) return o.note(c.name + ' declined your party invite.', 0xff8080);
    let p = parties.get(o.party);
    if (!p) {
      p = { id: nextParty++, leader: o, members: new Set([o]) };
      parties.set(p.id, p);
      o.party = p.id;
    }
    if (p.members.size >= PARTY_MAX) return c.note('That party is full.');
    leaveParty(c, true);
    p.members.add(c);
    c.party = p.id;
    for (const x of p.members) x.note(c.name + ' joined the party. (' + p.members.size + '/' + PARTY_MAX + ')', 0x7fd8ff);
    sendParty(p.id);
  },

  partyLeave(c) { leaveParty(c); },

  partyKick(c, m) {
    const p = parties.get(c.party);
    if (!p) return;
    if (p.leader !== c) return c.note('Only the party leader can kick.');
    for (const x of p.members) if (x.name.toLowerCase() === str(m.name, 12).toLowerCase() && x !== c) {
      x.note('You were removed from the party.', 0xff8080);
      leaveParty(x);
    }
  },

  // ---------------------------------------------------------------- guild
  guildCreate(c, m) {
    const name = str(m.name, 20).trim().replace(/\s+/g, ' ');
    if (c.guild) return c.send({ t: 'guildCreated', err: 'You\'re already in a guild.' });
    if (!/^[A-Za-z][A-Za-z ]{2,19}$/.test(name)) return c.send({ t: 'guildCreated', err: 'Guild names are 3-20 letters (spaces allowed).' });
    const gk = name.toLowerCase();
    if (guilds[gk]) return c.send({ t: 'guildCreated', err: 'That guild name is taken.' });
    guilds[gk] = { name, members: {} };
    guilds[gk].members[c.key] = memberRecord(c, FOUNDER);
    c.guild = gk;
    save('guilds.json', guilds);
    c.send({ t: 'guildCreated' });
    sendGuild(gk);
    log(c.name, 'founded', name);
  },

  guildInvite(c, m) {
    const g = guildOf(c), o = clients.get(m.to);
    if (!g) return c.note('You\'re not in a guild.');
    if (g.members[c.key].rank < OFFICER) return c.note('Only Officers and above can invite.');
    if (Object.keys(g.members).length >= GUILD_MAX) return c.note('Your guild is full (' + GUILD_MAX + ' members max).');
    if (!o || !o.authed) return c.note('That player isn\'t online.');
    if (o.guild) return c.note(o.name + ' is already in a guild.');
    o.guildAsk = c.guild;
    o.send({ t: 'guildInvite', from: c.id, name: c.name, guild: g.name });
    c.note('You invited ' + o.name + ' to ' + g.name + '.', 0x80ff80);
  },

  guildAns(c, m) {
    const gk = c.guildAsk;
    c.guildAsk = null;
    const g = gk && guilds[gk];
    if (!g || !m.yes || c.guild) return;
    if (Object.keys(g.members).length >= GUILD_MAX) return c.note('That guild is full.');
    g.members[c.key] = memberRecord(c, 0);
    c.guild = gk;
    save('guilds.json', guilds);
    for (const o of byName.values()) if (o.guild === gk) o.note(c.name + ' joined ' + g.name + '.', 0x80ff80);
    sendGuild(gk);
  },

  guildLeave(c) {
    const g = guildOf(c);
    if (!g) return;
    const gk = c.guild;
    if (g.members[c.key].rank === FOUNDER) {
      // the founder leaving disbands the guild
      delete guilds[gk];
      for (const o of byName.values()) if (o.guild === gk) { o.guild = null; o.note(g.name + ' was disbanded.', 0x80ff80); o.send({ t: 'guild', guild: null }); }
    } else {
      delete g.members[c.key];
      c.guild = null;
      c.send({ t: 'guild', guild: null });
      c.note('You left ' + g.name + '.', 0x80ff80);
      sendGuild(gk);
    }
    save('guilds.json', guilds);
  },

  guildKick(c, m) {
    const g = guildOf(c);
    const tk = str(m.name, 12).toLowerCase();
    if (!g || !g.members[tk]) return;
    const me = g.members[c.key].rank;
    if (me < OFFICER || g.members[tk].rank >= me) return c.note('You can\'t remove ' + g.members[tk].name + '.');
    const name = g.members[tk].name;
    delete g.members[tk];
    const o = byName.get(tk);
    if (o) { o.guild = null; o.send({ t: 'guild', guild: null }); o.note('You were removed from ' + g.name + '.', 0xff8080); }
    save('guilds.json', guilds);
    for (const x of byName.values()) if (x.guild === c.guild) x.note(name + ' was removed from the guild.', 0x80ff80);
    sendGuild(c.guild);
  },

  guildRank(c, m) {
    const g = guildOf(c);
    const tk = str(m.name, 12).toLowerCase();
    const rank = Math.floor(num(m.rank));
    if (!g || !g.members[tk]) return;
    const me = g.members[c.key].rank;
    if (me < OFFICER || rank < 0 || rank >= me || g.members[tk].rank >= me) return;
    const up = rank > g.members[tk].rank;
    g.members[tk].rank = rank;
    save('guilds.json', guilds);
    for (const x of byName.values()) if (x.guild === c.guild) x.note(g.members[tk].name + ' was ' + (up ? 'promoted' : 'demoted') + ' to ' + RANKS[rank] + '.', 0x80ff80);
    sendGuild(c.guild);
  },

  /** Monster sync between the world host and the others (see WorldSync.as). */
  w(c, m) {
    if (!c.world || !m.d || typeof m.d !== 'object') return;
    const out = { t: 'w', from: c.id, d: m.d };
    if (m.to === 'all') { for (const o of inWorld(c.world, c)) o.send(out); return; }
    const target = m.to === 'host' ? hosts.get(c.world) : clients.get(m.to);
    if (target && target !== c && target.world === c.world) target.send(out);
  },

  ping(c, m) { c.send({ t: 'pong', at: m.at }); }
};

/** Leaving a world: tell the others, and hand its monsters to someone else if we ran them. */
function leaveWorld(c) {
  const old = c.world;
  if (!old) return;
  c.world = '';
  const rest = inWorld(old, c);
  for (const o of rest) o.send({ t: 'leave', id: c.id });
  if (hosts.get(old) === c) {
    if (rest.length) {
      const h = rest[0];
      hosts.set(old, h);
      for (const o of rest) o.send({ t: 'host', key: old, id: h.id });
    } else hosts.delete(old);
  }
}

function partner(c) { return c.trade.a === c ? c.trade.b : c.trade.a; }

function endTrade(c, msg) {
  const t = c.trade;
  if (!t) return;
  const o = partner(c);
  t.a.trade = t.b.trade = null;
  o.send({ t: 'tradeCancel', msg });
  c.send({ t: 'tradeCancel', msg: null });
}

function leaveParty(c, quiet) {
  const p = parties.get(c.party);
  c.party = 0;
  if (!p) return;
  p.members.delete(c);
  if (!quiet) c.note('You left the party.', 0x7fd8ff);
  c.send({ t: 'party', members: [] });
  if (p.members.size <= 1) {
    for (const x of p.members) { x.party = 0; x.note('The party was disbanded.', 0x7fd8ff); x.send({ t: 'party', members: [] }); }
    parties.delete(p.id);
    return;
  }
  if (p.leader === c) p.leader = p.members.values().next().value;
  for (const x of p.members) x.note(c.name + ' left the party.', 0x7fd8ff);
  sendParty(p.id);
}

function sendParty(pid) {
  const p = parties.get(pid);
  if (!p) return;
  const members = [...p.members].map(x => ({ id: x.id, name: x.name, profile: x.profile, world: x.world }));
  for (const x of p.members) x.send({ t: 'party', leader: p.leader.id, members });
}

function memberRecord(c, rank) {
  const pr = c.profile || {};
  return { name: c.name, rank, cls: pr.cls || 'wizard', level: pr.level || 1, fame: pr.fame || 0 };
}

function updateGuildMember(c) {
  const g = guildOf(c);
  if (!g) return;
  const r = g.members[c.key];
  const pr = c.profile || {};
  if (pr.cls) { r.cls = pr.cls; r.level = pr.level || 1; r.fame = pr.fame || 0; }
  save('guilds.json', guilds);
  sendGuild(c.guild);
}

/** Sends each online member the guild roster, from their point of view. */
function sendGuild(gk) {
  const g = gk && guilds[gk];
  if (!g) return;
  for (const o of byName.values()) {
    if (o.guild !== gk) continue;
    const members = [];
    for (const k in g.members) {
      if (k === o.key) continue;
      const m = g.members[k], on = byName.get(k);
      members.push({ name: m.name, rank: m.rank, cls: m.cls, level: m.level, fame: m.fame, online: !!on, world: on ? on.world : '', id: on ? on.id : 0 });
    }
    o.send({ t: 'guild', guild: { name: g.name, myRank: g.members[o.key].rank, members } });
  }
}

// ------------------------------------------------------------------ connections
function attach(c) {
  clients.set(c.id, c);
  c.note = (text, color) => c.send({ t: 'msg', text, color: color || 0xff8080 });
  c.fail = (msg) => { c.send({ t: 'error', msg }); setTimeout(() => c.close(), 100); };
  c.lastSeen = Date.now();
  c.budget = MAX_MSGS_PER_SEC;
  c.onLine = (line) => {
    if (!line) return;
    c.lastSeen = Date.now();
    if (--c.budget < 0) return; // flooding: drop until the budget refills
    if (line.length > 65536) return;
    let m;
    try { m = JSON.parse(line); } catch (e) { return; }
    if (!m || typeof m.t !== 'string') return;
    if (!c.authed && m.t !== 'hello') return;
    const h = handlers[m.t];
    if (h) {
      try { h(c, m); } catch (e) { log('error handling', m.t, e.message); }
    }
  };
  c.onClose = () => {
    if (!clients.has(c.id)) return;
    clients.delete(c.id);
    if (!c.authed) return;
    if (byName.get(c.key) === c) byName.delete(c.key);
    if (c.trade) endTrade(c, c.name + ' left.');
    leaveParty(c, true);
    leaveWorld(c);
    if (c.guild) sendGuild(c.guild);
    log(c.name, 'left (' + byName.size + ' online)');
  };
}

const POLICY = '<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>\0';

const server = net.createServer((sock) => {
  sock.setNoDelay(true);
  const c = { id: nextId++, authed: false, world: '', x: 0, y: 0, profile: {}, party: 0 };
  let mode = null; // 'tcp' | 'ws'
  let buf = Buffer.alloc(0);
  let text = '';

  const lines = (chunk) => {
    text += chunk;
    let i;
    while ((i = text.indexOf('\n')) >= 0) {
      const line = text.slice(0, i);
      text = text.slice(i + 1);
      c.onLine(line.trim());
    }
    if (text.length > 1 << 20) sock.destroy();
  };

  c.send = (obj) => {
    if (sock.destroyed) return;
    const data = Buffer.from(JSON.stringify(obj) + '\n', 'utf8');
    if (mode === 'ws') sock.write(wsFrame(data));
    else sock.write(data);
  };
  c.close = (hard) => { if (hard) sock.destroy(); else sock.end(); };
  attach(c);

  sock.on('data', (chunk) => {
    buf = Buffer.concat([buf, chunk]);
    if (!mode) {
      const head = buf.toString('latin1', 0, Math.min(buf.length, 23));
      if (head.startsWith('<policy-file-request/>')) { sock.end(POLICY); return; }
      if (head.startsWith('GET ')) {
        const end = buf.indexOf('\r\n\r\n');
        if (end < 0) return;
        const req = buf.toString('latin1', 0, end);
        const keyM = /Sec-WebSocket-Key:\s*(.+)/i.exec(req);
        if (!keyM) { sock.end('HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nNew Realm server is running.\n'); return; }
        const accept = crypto.createHash('sha1').update(keyM[1].trim() + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11').digest('base64');
        const proto = /Sec-WebSocket-Protocol:\s*([^,\r\n]+)/i.exec(req);
        sock.write('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ' + accept +
          (proto ? '\r\nSec-WebSocket-Protocol: ' + proto[1].trim() : '') + '\r\n\r\n');
        mode = 'ws';
        buf = buf.slice(end + 4);
      } else {
        mode = 'tcp';
      }
    }
    if (mode === 'tcp') {
      lines(buf.toString('utf8'));
      buf = Buffer.alloc(0);
      return;
    }
    // websocket frames
    while (buf.length >= 2) {
      const op = buf[0] & 0x0f;
      let len = buf[1] & 0x7f, off = 2;
      if (len === 126) { if (buf.length < 4) return; len = buf.readUInt16BE(2); off = 4; }
      else if (len === 127) { if (buf.length < 10) return; len = Number(buf.readBigUInt64BE(2)); off = 10; }
      const masked = (buf[1] & 0x80) !== 0;
      if (buf.length < off + (masked ? 4 : 0) + len) return;
      let payload = buf.slice(off + (masked ? 4 : 0), off + (masked ? 4 : 0) + len);
      if (masked) {
        const mask = buf.slice(off, off + 4);
        payload = Buffer.from(payload.map((b, i) => b ^ mask[i & 3]));
      }
      buf = buf.slice(off + (masked ? 4 : 0) + len);
      if (op === 8) { sock.end(); return; }
      if (op === 9) { sock.write(wsFrame(payload, 10)); continue; }
      if (op === 1 || op === 2 || op === 0) lines(payload.toString('utf8'));
    }
  });
  sock.on('close', () => c.onClose());
  sock.on('error', () => {});
});

function wsFrame(data, op = 2) {
  const len = data.length;
  let head;
  if (len < 126) head = Buffer.from([0x80 | op, len]);
  else if (len < 65536) { head = Buffer.alloc(4); head[0] = 0x80 | op; head[1] = 126; head.writeUInt16BE(len, 2); }
  else { head = Buffer.alloc(10); head[0] = 0x80 | op; head[1] = 127; head.writeBigUInt64BE(BigInt(len), 2); }
  return Buffer.concat([head, data]);
}

server.listen(PORT, () => {
  log('New Realm server running on port ' + PORT);
  log('Realms: ' + realms.map(r => r.name).join(', '));
  log('Type "help" here for server commands (list, say, kick, stop).');
  const addrs = [];
  for (const list of Object.values(os.networkInterfaces())) for (const a of list || []) if (a.family === 'IPv4' && !a.internal) addrs.push(a.address);
  log('Players on this PC connect to:  localhost:' + PORT);
  for (const a of addrs) log('Friends connect to:  ' + a + ':' + PORT + (a.startsWith('100.') ? '   (Tailscale)' : ''));
});

// ------------------------------------------------------------------ housekeeping
setInterval(() => {
  const now = Date.now();
  for (const c of clients.values()) {
    c.budget = MAX_MSGS_PER_SEC;
    if (now - c.lastSeen > IDLE_KICK_MS) { log((c.name || 'connection ' + c.id) + ' timed out'); c.close(true); }
  }
}, 1000);

// ------------------------------------------------------------------ console
const HELP = 'Commands: list | say <message> | kick <name> | realms (new realms) | stop';
function online() { return [...byName.values()]; }
function broadcast(text, color) { for (const c of online()) c.send({ t: 'msg', text, color: color || 0xffd75e }); }
process.stdin.setEncoding('utf8');
process.stdin.on('data', (data) => {
  for (const raw of data.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line) continue;
    const [cmd, ...rest] = line.split(' ');
    const arg = rest.join(' ');
    switch (cmd.toLowerCase()) {
      case 'help': console.log(HELP); break;
      case 'list': case 'who': {
        const list = online();
        console.log(list.length + ' online' + (list.length ? ': ' + list.map(c => c.name + ' (' + (c.world || '-') + (hosts.get(c.world) === c ? ', host' : '') + ')').join(', ') : ''));
        break;
      }
      case 'say': if (arg) { broadcast('[Server] ' + arg); log('said: ' + arg); } break;
      case 'kick': {
        const c = byName.get(arg.toLowerCase());
        if (!c) { console.log('Nobody called ' + arg + ' is online.'); break; }
        c.send({ t: 'kicked', msg: 'You were kicked from the server.' });
        c.close(true);
        log('kicked ' + c.name);
        break;
      }
      case 'realms':
        rollRealms();
        log('New realms: ' + realms.map(r => r.name).join(', ') + ' (players get them when they next log in)');
        break;
      case 'stop': case 'exit': case 'quit':
        broadcast('[Server] The server is shutting down.', 0xff8080);
        for (const f in saveTimers) clearTimeout(saveTimers[f]);
        fs.writeFileSync(path.join(DATA_DIR, 'accounts.json'), JSON.stringify(accounts, null, 1));
        fs.writeFileSync(path.join(DATA_DIR, 'guilds.json'), JSON.stringify(guilds, null, 1));
        setTimeout(() => process.exit(0), 300);
        break;
      default: console.log('Unknown command. ' + HELP);
    }
  }
});
