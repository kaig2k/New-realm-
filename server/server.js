#!/usr/bin/env node
/*
 * New Realm game server.
 *
 * Shares the Nexus and the realms between players: positions, chat, parties,
 * guilds and trades. Account saves (characters, vault, gold...) live on the
 * server, which checks them and carries out trades itself. Monsters run in
 * one player's game per world (the "world host", see WorldSync.as).
 *
 * Run:  node server/server.js [port]      (default port 2050)
 * Settings: server/config.json (created on first run).
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
const { StringDecoder } = require('string_decoder');
const { Store } = require('./store');
const { checkSave } = require('./validate');
const { Sims, WorldSim } = require('./sim/worldsim');
const items = require('./items');
const wallet = require('./wallet');
const season = require('./season');
const hall = require('./guildhall');
const modes = require('./modes');
const graves = require('./graves');
const { Data, Bosses } = require('./sim/gen/game');
const quests = require('./quests');
const { Market } = require('./market');

// ------------------------------------------------------------------ config
const CONFIG_FILE = process.env.NEWREALM_CONFIG || path.join(__dirname, 'config.json');
const DEFAULT_CONFIG = {
  port: 2050,
  // the name players see in the game (the IP address is never shown)
  name: 'Eldmere',
  motd: 'Welcome to New Realm!',
  realmCap: 85,
  minRealms: 3,
  maxRealms: 6,
  admins: [],
  // a Discord webhook address: records, raid clears, Godly drops, titles and restarts are posted there
  discordWebhook: '',
  viewRange: 32,
  chatPerTenSeconds: 8,
  // true: click anyone on the minimap (or /tp name) to teleport to them, like RotMG; false: party and guild only
  teleportToAnyone: true
};
let config = Object.assign({}, DEFAULT_CONFIG);
try { Object.assign(config, JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'))); }
catch (e) { try { fs.writeFileSync(CONFIG_FILE, JSON.stringify(DEFAULT_CONFIG, null, 2)); } catch (e2) {} }
const isAdmin = (c) => config.admins.some(a => String(a).toLowerCase() === c.key);
/** Writes the admin list back to config.json (keeping everything else in the file as it is). */
function saveAdmins() {
  let file = {};
  try { file = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8')); } catch (e) { file = Object.assign({}, DEFAULT_CONFIG); }
  file.admins = config.admins;
  try { fs.writeFileSync(CONFIG_FILE, JSON.stringify(file, null, 2)); return true; } catch (e) { log('could not save config.json: ' + e.message); return false; }
}

const PORT = parseInt(process.argv[2] || process.env.PORT || config.port || '2050', 10);
/** Bump when the game and server stop understanding each other. */
const VERSION = 11;
const IDLE_KICK_MS = 45000;
const MAX_MSGS_PER_SEC = 250;
const MAX_LINE = 1536 * 1024;
const DATA_DIR = process.env.NEWREALM_DATA || path.join(__dirname, 'data');
const PARTY_MAX = 6;
const GUILD_MAX = 27;
const RANKS = ['Initiate', 'Member', 'Officer', 'Leader', 'Founder'];
const OFFICER = 2, FOUNDER = 4;
const REALM_NAMES = ['Ashveil', 'Thornwick', 'Glimmerfen', 'Duskhollow', 'Brineholt', 'Stormreach', 'Mirewood', 'Emberfall',
  'Frostgate', 'Sunspire', 'Wraithmoor', 'Ironvale', 'Starhaven', 'Mosscairn', 'Grimtide'];

// ------------------------------------------------------------------ storage
const store = new Store(DATA_DIR);
// a copy of everything in data/ each day (data/backups/YYYY-MM-DD, newest 14 kept; config "backups": false turns it off)
const backup = require('./backup');
const site = require('./site');
/** Server-run monsters for every realm, dungeon, raid and Elder chamber (config "serverMonsters": false turns it off). */
const sims = config.serverMonsters === false ? null : new Sims();
// loot the server rolls is written into the looter's ledger
if (sims) sims.issuer = (c, it) => { const sv = onlineSave(c.key); items.issue(sv, it); store.putSave(c.key, sv); };
const load = (file, fallback) => store.loadTable(file, fallback);
const save = (file, obj) => store.saveTable(file, obj);

// ------------------------------------------------------------------ fastest event kills
/** records[eventId] = [{ms, names, at}] fastest first (first hit to kill). */
const records = load('records.json', {});
const RECORDS_KEPT = 5;
const clock = (ms) => { const s = ms / 1000; return Math.floor(s / 60) + ':' + (s % 60 < 10 ? '0' : '') + (s % 60).toFixed(1); };
/** A realm event boss died: put the team on the board if they were quick, and tell people. */
function eventKilled(id, ms, team) {
  if (ms < 1000) return; // nothing real dies that fast
  const names = team.map((c) => c.name).filter(Boolean).slice(0, 8);
  if (!names.length) return;
  const list = records[id] || (records[id] = []);
  const old = list[0];
  list.push({ ms, names, at: Date.now() });
  list.sort((a, b) => a.ms - b.ms);
  list.length = Math.min(list.length, RECORDS_KEPT);
  const place = list.findIndex((r) => r.at && r.names === names) + 1;
  if (place) for (const c of team) questProgress(c, ['record']);
  // a top-5 time earns the boss's Slayer title, the best time Record Holder
  if (place) for (const c of team) if (c.key) { grantTitle(c.key, 'slayer_' + id); if (place === 1) grantTitle(c.key, 'record'); }
  save('records.json', records);
  const boss = (Data.ENEMIES[id] && Data.ENEMIES[id].name) || id;
  const who = names.length > 3 ? names.slice(0, 3).join(', ') + ' and ' + (names.length - 3) + ' more' : names.join(', ');
  if (place === 1) {
    feat('record', { names, boss, time: clock(ms), old: old ? clock(old.ms) : '' });
    for (const o of clients.values()) {
      if (!o.authed) continue;
      o.send({ t: 'banner', text: 'New record: ' + boss + '!', color: 0xffd75e,
        msg: who + ' killed ' + boss + ' in ' + clock(ms) + (old ? ', beating ' + clock(old.ms) + '!' : ', the first time on the board!') });
    }
  } else {
    const best = list[0];
    for (const c of team) c.send({ t: 'msg', color: 0xffd75e, text: boss + ' down in ' + clock(ms) + (place ? ': #' + place + ' on the board!' : '. The record is ' + clock(best.ms) + ' (' + best.names[0] + ').') });
  }
}
if (sims) sims.onEventKill = eventKilled;

// ------------------------------------------------------------------ seasons
const ladder = new season.Ladder(load, save);
/** A new month: the old ladder's top ten get their rewards, and everyone hears about it. */
function seasonTick() {
  ladder.rollover(Date.now(), (key, place) => {
    for (const id of season.rewardsFor(place)) grantTitle(key, id);
  }, (old, cur) => {
    const top = old.top;
    log('season over: ' + old.name + (top.length ? ', won by ' + top[0].name : ''));
    if (discord.on) {
      discord.post('🏁 **' + desc(old.name) + ' is over!** ' + (top.length
        ? top.slice(0, 3).map((e, i) => ['🥇', '🥈', '🥉'][i] + ' ' + dnames([e.name]) + ' (' + e.pts.toLocaleString('en') + ')').join('   ') + '. The top ten earn the season\'s titles and dyes.'
        : 'Nobody made the ladder this time.'), 0x8fd16a);
      discord.post('🌱 **' + desc(cur.name) + ' begins!** Seasonal heroes score double on the new ladder until ' + new Date(cur.ends - 1).toUTCString().slice(5, 16) + '.', 0x8fd16a);
    }
    for (const o of clients.values()) if (o.authed) o.send({ t: 'banner', text: cur.name + ' begins!', color: 0x8fd16a,
      msg: old.name + (top.length ? ' was won by ' + top[0].name + '.' : ' is over.') + ' Make a Seasonal hero to score double on the new ladder.', sfx: 'fanfare' });
  });
}
setInterval(seasonTick, 60 * 1000).unref();

/**
 * A save let heroes die: their fame (as the server accepted it) goes on the season ladder.
 * Also keeps the Seasonal mark honest: only heroes made this season can carry it, and only from the start.
 */
function seasonSave(c, prev, data) {
  if (!prev || !data) return;
  const cur = ladder.current;
  const old = new Map((prev.chars || []).filter((h) => h && h.id).map((h) => [h.id, h]));
  for (const h of data.chars || []) {
    if (!h || typeof h !== 'object') continue;
    const was = old.get(h.id);
    if (was) { if (was.season) h.season = was.season; else delete h.season; }
    else if (h.season !== cur.id) delete h.season;
  }
  const alive = new Set((data.chars || []).filter(Boolean).map((h) => h.id));
  const dead = [];
  for (const [id, h] of old) if (!alive.has(id)) dead.push({ fame: wallet.heroFame(h), seasonal: h.season === cur.id, cls: h.cls, level: h.level });
  if (!dead.length) return;
  const gain = wallet.fameGain(prev, data);
  const pts = ladder.heroesDied(c.key, c.name, gain, dead);
  // a tenth of a fallen hero's fame goes to its guild
  const g = guildOf(c);
  if (g && gain > 0) { g.fame = (Number(g.fame) || 0) + gain / 10; save('guilds.json', guilds); }
  if (pts > 0) c.send({ t: 'msg', color: 0x8fd16a, text: '+' + pts.toLocaleString('en') + ' season points (' + cur.name + '). See the Season page in the Wiki (K).' });
}

/** A login that checked out: ban check, then into the game (see handlers.hello). */
function finishLogin(c, acc, key, session) {
  if (c.authed) return;
  const ban = bans[key];
  if (ban && (!ban.until || ban.until > Date.now())) {
    return c.fail('You are banned from this server' + (ban.until ? ' until ' + new Date(ban.until).toUTCString() : '') + (ban.reason ? ': ' + ban.reason : '.'));
  }
  const old = byName.get(key);
  if (old) { old.send({ t: 'kicked', msg: 'You logged in from somewhere else.' }); old.replaced = true; setTimeout(() => old.close(true), 200); }
  c.authed = true;
  c.name = acc.name;
  c.key = key;
  byName.set(key, c);
  // guild membership lives on the server
  c.guild = null;
  for (const gk in guilds) if (guilds[gk].members[key]) c.guild = gk;
  c.meta = accountMeta.get(key) || { lastSave: Date.now(), lastGodly: 0 };
  accountMeta.set(key, c.meta);
  c.chatTimes = [];
  acc.lastSeen = Date.now();
  save('accounts.json', accounts);
  c.send({ t: 'welcome', id: c.id, name: c.name, no: acc.no || 0, ver: VERSION, serverName: str(config.name, 32) || 'Eldmere', realms: realmList(), online: byName.size,
    save: publicSave(onlineSave(key)), motd: config.motd, serverMonsters: !!sims, admin: isAdmin(c), session, needPassword: !acc.pwHash, build: GAME_BUILD, restartIn: restartLeft(), season: ladder.current, tpAny: !!config.teleportToAnyone });
  sendGuild(c.guild);
  c.send({ t: 'quests', q: quests.view(onlineSave(key)) });
  log(c.name, '#' + (acc.no || '?'), 'joined (' + byName.size + ' online)');
}

// ------------------------------------------------------------------ the minimap
// everyone sees where everyone else in their world is, about every 1.5 seconds (like RotMG's
// map): one small message per player, so it costs little even in a full realm
setInterval(() => {
  const byWorld = new Map();
  for (const c of clients.values()) {
    if (!c.authed || !c.world) continue;
    if (!byWorld.has(c.world)) byWorld.set(c.world, []);
    byWorld.get(c.world).push(c);
  }
  for (const list of byWorld.values()) {
    if (list.length < 2) continue;
    const l = list.map((c) => [c.id, Math.round(num(c.x) * 10) / 10, Math.round(num(c.y) * 10) / 10]);
    for (const c of list) c.send({ t: 'map', l });
  }
}, 1500).unref();

// ------------------------------------------------------------------ Discord status board
/** config "discordStatusWebhook": a webhook (best in its own #status channel) whose one message the server keeps up to date. */
const statusMeta = load('status.json', {});
let statusBoard = null;
function statusTick() {
  // (made on first use: the Discord module is loaded further down)
  if (!statusBoard) statusBoard = new StatusBoard(config.discordStatusWebhook, str(config.name, 32) || 'Eldmere', statusMeta.id,
    (id) => { statusMeta.id = id; save('status.json', statusMeta); }, (t) => log(t));
  if (!statusBoard.on) return;
  const on = online();
  counters.peak = Math.max(counters.peak, on.length);
  const ranked = ladder.ranked().slice(0, 3);
  const gtop = Object.keys(guilds).map((k) => guilds[k]).sort((a, b) => (Number(b.fame) || 0) - (Number(a.fame) || 0))[0];
  // the newest #1 Records time
  let rec = null;
  for (const id of Object.keys(records)) {
    const r = records[id] && records[id][0];
    if (r && !id.startsWith('vault:') && (!rec || r.at > rec.r.at)) rec = { id, r };
  }
  const tw = Bosses.vaultTwist(Math.floor((Math.floor(Date.now() / 86400000) + 3) / 7));
  const lines = [
    '🟢 **' + on.length + '** playing now · peak today **' + counters.peak + '**',
    '🌱 **' + desc(ladder.current.name) + '**' + (ranked.length ? ': ' + ranked.map((e, i) => ['🥇', '🥈', '🥉'][i] + ' ' + desc(e.name) + ' (' + e.pts.toLocaleString('en') + ')').join('  ') : ': nobody on the ladder yet'),
    gtop ? '🏰 Top guild: **' + desc(gtop.name) + '** (' + Math.round(Number(gtop.fame) || 0).toLocaleString('en') + ' guild fame)' : '🏰 No guilds yet: make one in game!',
    '🌀 Starfall Vault this week: **' + desc(tw.name) + '**',
    rec ? '🏆 Latest record: **' + desc((Data.ENEMIES[rec.id] && Data.ENEMIES[rec.id].name) || rec.id) + '** in ' + clock(rec.r.ms) + ' by ' + dnames(rec.r.names) : '🏆 No Records times yet',
    '_Updated <t:' + Math.floor(Date.now() / 1000) + ':R>_'
  ];
  statusBoard.show(lines.join('\n'), 0x8fd16a);
}
setInterval(statusTick, 5 * 60 * 1000).unref();

// ------------------------------------------------------------------ daily login reward
/** Gold for each day in a row (a week, then it starts again); day 7 adds Aether. */
const DAILY_GOLD = [100, 150, 200, 250, 300, 400, 500], DAILY_AETHER = 25;
function dailyLogin(c) {
  if (!c.authed || !c.key || !c.charId) return;
  const sv = onlineSave(c.key);
  const day = Math.floor(Date.now() / 86400000);
  const d = sv._login && typeof sv._login === 'object' ? sv._login : { day: -9, streak: 0 };
  if (d.day === day) return;
  const streak = d.day === day - 1 ? (d.streak | 0) + 1 : 1;
  const k = (streak - 1) % 7;
  const gold = DAILY_GOLD[k], aether = k === 6 ? DAILY_AETHER : 0;
  sv._login = { day, streak };
  store.putSave(c.key, sv);
  // the game adds it and saves; the wallet lets exactly that much through
  if (c.meta) wallet.grant(c.meta, gold, aether);
  c.send({ t: 'daily', streak, addGold: gold, addOnrane: aether });
}

// ------------------------------------------------------------------ earned titles
/** Gives account `key` an earned nameplate title (see Data.TITLES / Data.SLAYER) for good, and tells them if they're on. */
function grantTitle(key, id) {
  const t = Data.findTitle(id) || Data.findDye(id);
  if (!key || !t || !t.earn) return false;
  const sv = onlineSave(key);
  if (!sv._titles || typeof sv._titles !== 'object') sv._titles = {};
  if (sv._titles[id]) return false;
  sv._titles[id] = Date.now();
  store.putSave(key, sv);
  feat('title', { name: (accounts[key] && accounts[key].name) || key, title: t.name + (Data.findDye(id) ? ' dye' : ''), color: t.col });
  const c = byName.get(key);
  if (c) {
    c.send({ t: 'title', id, earned: Object.keys(sv._titles) });
    const kind = Data.findDye(id) ? 'Dye' : 'Title';
    c.send({ t: 'banner', text: kind + ' earned: ' + t.name + '!', color: t.col || 0xff9a2e, msg: 'Wear it from the Fame Store in the Nexus.', sfx: 'fanfare' });
  }
  return true;
}

// ------------------------------------------------------------------ quests
/** Something the server saw counts toward c's quests (evs: what happened, see WorldSim.questKill). */
function questProgress(c, evs) {
  if (!c || !c.key || !c.authed) return;
  guildProgress(c, evs);
  if (evs.includes('darkelder')) grantTitle(c.key, 'elder');
  if (evs.includes('raid:starfall')) grantTitle(c.key, 'vault');
  const sv = onlineSave(c.key);
  const done = quests.progress(sv, evs);
  if (done === null) return;
  store.putSave(c.key, sv);
  c.send({ t: 'quests', q: quests.view(sv) });
  for (const text of done) c.send({ t: 'questComplete', text: text + ' Claim it at the Quest Board in the Nexus.' });
}
if (sims) sims.onQuest = questProgress;
if (sims) sims.onFeat = (k, d) => { if (k === 'raid' && d.week !== undefined && d.ms > 0) vaultCleared(d); feat(k, d); };

/** The Starfall Vault's weekly board: records['vault:<week>'], fastest clears on that week's twist (top 5 earn Twistbreaker). */
function vaultCleared(d) {
  const team = (d.team || []).filter((c) => c && c.key);
  const names = team.map((c) => c.name).filter(Boolean).slice(0, 8);
  if (!names.length || d.ms < 1000) return;
  const key = 'vault:' + d.week;
  const list = records[key] || (records[key] = []);
  const entry = { ms: d.ms, names, at: Date.now(), twist: d.twist };
  list.push(entry);
  list.sort((a, b) => a.ms - b.ms);
  list.length = Math.min(list.length, RECORDS_KEPT);
  const place = list.indexOf(entry) + 1;
  // only the last couple of months of weekly boards are kept
  for (const k of Object.keys(records)) if (k.startsWith('vault:') && Number(k.slice(6)) < d.week - 8) delete records[k];
  save('records.json', records);
  for (const c of team) {
    c.send({ t: 'msg', color: 0x80e0ff, text: 'Starfall Vault cleared in ' + clock(d.ms) + ' on ' + d.twist + (place ? ': #' + place + " on this week's board!" : '. The best this week is ' + clock(list[0].ms) + '.') });
    if (place) grantTitle(c.key, 'twistbreaker');
  }
  if (place === 1) feat('vaultrecord', { names, time: clock(d.ms), twist: d.twist });
}
// every kill the server decides credits the gold and fame it can pay (see wallet.js)
if (sims) sims.onEarn = (c, e, near) => { if (c.authed && c.key && c.meta) wallet.credit(c.meta, onlineSave(c.key), c.charId, e, Date.now(), near); };

// ------------------------------------------------------------------ player marketplace
const market = new Market(load, save);
/** The Marketplace as c sees it (all listings, theirs marked, their takings). */
function sendMarket(c) { c.send({ t: 'market', m: market.view(c.key, onlineSave(c.key)) }); }
// week-old listings go back to their sellers (to collect at the Marketplace)
setInterval(() => {
  for (const key of market.expire((k) => store.getSave(k))) {
    const sv = store.getSave(key);
    if (sv) store.putSave(key, sv);
    const c = byName.get(key);
    if (c) c.send({ t: 'msg', color: 0x6fe08f, text: 'A Marketplace listing of yours ran out after a week. Collect the item at the Marketplace.' });
  }
}, 60000).unref();
/** accounts[lowername] = {name, created, pwSalt, pwHash, sessions: [hashes]} (+ salt/hash on accounts made before passwords) */
const accounts = load('accounts.json', {});
/**
 * Every account has a number (accounts[key].no), in the order they were made, for
 * moderation: #1 is the server's owner (config "owner", else the first admin).
 * Accounts from before numbers get theirs the first time the server starts.
 */
function numberAccounts() {
  const keys = Object.keys(accounts);
  let next = 1 + keys.reduce((n, k) => Math.max(n, Number(accounts[k].no) || 0), 0);
  const todo = keys.filter((k) => !(Number(accounts[k].no) > 0)).sort((a, b) => (accounts[a].created || 0) - (accounts[b].created || 0));
  if (!todo.length) return;
  const owner = String(config.owner || config.admins[0] || '').toLowerCase();
  if (next === 1 && todo.includes(owner)) { todo.splice(todo.indexOf(owner), 1); todo.unshift(owner); }
  for (const k of todo) accounts[k].no = next++;
  save('accounts.json', accounts);
}
function nextAccountNo() { return 1 + Object.keys(accounts).reduce((n, k) => Math.max(n, Number(accounts[k].no) || 0), 0); }
/** An account from what an admin typed: a name, or #number. Returns its key, or ''. */
function accountKey(arg) {
  const t = String(arg || '').trim().toLowerCase();
  const m = /^#(\d+)$/.exec(t);
  if (m) { const n = Number(m[1]); return Object.keys(accounts).find((k) => accounts[k].no === n) || ''; }
  return accounts[t] ? t : '';
}
numberAccounts();
const accountTag = (key) => (accounts[key] ? accounts[key].name + ' (#' + accounts[key].no + ')' : key);
/** The server's owner: config "owner", else the first admin. */
const isOwner = (c) => String(config.owner || config.admins[0] || '').toLowerCase() === c.key;
const clsName = (id) => (Data.CLASSES[id] && Data.CLASSES[id].name) || id || 'hero';
const ago = (t) => { const s = Math.max(0, (Date.now() - (t || 0)) / 1000); return s < 90 ? 'just now' : s < 5400 ? Math.round(s / 60) + ' min ago' : s < 129600 ? Math.round(s / 3600) + ' h ago' : Math.round(s / 86400) + ' days ago'; };
const dayOf = (t) => (t ? new Date(t).toISOString().slice(0, 10) : '?');
function heroLine(h) {
  return (h.name || '?') + ', level ' + (h.level || 1) + ' ' + clsName(h.cls) + (h.mode === 'ironman' ? ', Ironman' : h.mode === 'hardcore' ? ', Hardcore' : '') + (h.season ? ', Seasonal' : '');
}
function graveLine(e) {
  return heroLine(e.hero) + ', ' + (e.died ? 'died ' + ago(e.at) + (e.killer ? ' to ' + e.killer : '') : 'gone ' + ago(e.at)) + (e.fame ? ' (' + e.fame.toLocaleString('en') + ' fame)' : '');
}
/** /whois: number, dates, heroes and standing, so an admin can check someone owns an account before helping. */
function whoisLines(key) {
  const a = accounts[key], sv = store.getSave(key) || {};
  const on = byName.get(key), ban = bans[key];
  const out = ['#' + a.no + ' ' + a.name + (config.admins.some((x) => String(x).toLowerCase() === key) ? ' (admin)' : '') +
    ': made ' + dayOf(a.created) + ', ' + (on ? 'online now' + (on.world ? ' in ' + on.world.split(':')[0] : '') : 'last seen ' + (a.lastSeen ? ago(a.lastSeen) : 'before numbers')) +
    (ban && (!ban.until || ban.until > Date.now()) ? ', BANNED' + (ban.until ? ' until ' + dayOf(ban.until) : '') + (ban.reason ? ' (' + ban.reason + ')' : '') : '')];
  out.push('  Fame ' + (sv.fame || 0).toLocaleString('en') + ', gold ' + (sv.gold || 0).toLocaleString('en') + ', Aether ' + (sv.onrane || 0).toLocaleString('en') +
    ', heroes lost ' + (sv.deaths || 0) + (c2g(key) ? ', guild ' + c2g(key) : ''));
  const live = (sv.chars || []).filter(Boolean);
  out.push('  Heroes: ' + (live.length ? live.map(heroLine).join('; ') : 'none'));
  const g = graves.list(sv);
  if (g.length) out.push('  ' + g.length + ' fallen hero' + (g.length === 1 ? '' : 'es') + ' can be brought back: /graves ' + a.name);
  return out;
}
function c2g(key) { for (const gk in guilds) if (guilds[gk].members[key]) return guilds[gk].name || gk; return ''; }
/** guilds[lowername] = {name, members: {lowername: {name, rank, cls, level, fame}}} */
const guilds = load('guilds.json', {});
/** bans[lowername] = {until (ms, 0 = forever), reason, by} */
const bans = load('bans.json', {});

function hashToken(token, salt) {
  return crypto.createHash('sha256').update(salt + ':' + token).digest('hex');
}

/** Passwords are stored as salted scrypt hashes, never as text. */
function hashPassword(pw, salt) {
  return crypto.scryptSync(String(pw), salt, 32).toString('hex');
}

function checkPassword(acc, pw) {
  if (!acc.pwHash) return false;
  const a = Buffer.from(hashPassword(pw, acc.pwSalt), 'hex'), b = Buffer.from(acc.pwHash, 'hex');
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function setPassword(acc, pw) {
  acc.pwSalt = crypto.randomBytes(16).toString('hex');
  acc.pwHash = hashPassword(pw, acc.pwSalt);
}

/** A new "remember me" session for this PC; only its hash is kept. */
function newSession(acc) {
  const token = crypto.randomBytes(24).toString('hex');
  acc.sessions = (acc.sessions || []).concat([hashToken(token, 'session')]).slice(-10);
  return token;
}

function hasSession(acc, token) {
  if (!token) return false;
  if (acc.hash && acc.salt && hashToken(token, acc.salt) === acc.hash) return true; // the old per-PC token
  return (acc.sessions || []).indexOf(hashToken(token, 'session')) >= 0;
}

/** Slows down password guessing: 8 failed logins from one address locks it out for 5 minutes. */
const failedLogins = new Map();
function loginLocked(ip) {
  const f = failedLogins.get(ip);
  return f && f.n >= 8 && Date.now() - f.t < 5 * 60 * 1000;
}
function loginFailed(ip) {
  const f = failedLogins.get(ip) || { n: 0, t: 0 };
  if (Date.now() - f.t > 5 * 60 * 1000) f.n = 0;
  f.n++; f.t = Date.now();
  failedLogins.set(ip, f);
}

// ------------------------------------------------------------------ realms
/**
 * The realms behind the Nexus portals (up to maxRealms). The seed makes every
 * game build the same map. A realm holds realmCap players; when the open ones
 * fill up a new one opens, and a closed realm is replaced by a fresh one.
 */
let realms = [];
function newRealm() {
  const used = new Set(realms.map(r => r.name));
  const pool = REALM_NAMES.filter(n => !used.has(n));
  const name = (pool.length ? pool : REALM_NAMES)[Math.floor(Math.random() * (pool.length || REALM_NAMES.length))];
  return { name, seed: 1 + Math.floor(Math.random() * 0x7ffffffe), count: 0 };
}
const realmKey = (r) => 'realm:' + r.name + ':' + r.seed;
function rollRealms() {
  realms = [];
  for (let i = 0; i < config.minRealms; i++) realms.push(newRealm());
}
rollRealms();

function realmList() {
  return realms.map(r => ({ name: r.name, seed: r.seed, count: r.count, cap: config.realmCap }));
}

let lastRealmJson = '';
/** Recounts realm populations, opens a new realm when they fill up, and tells the Nexus. */
function updateRealms() {
  for (const r of realms) r.count = 0;
  const byKey = new Map(realms.map(r => [realmKey(r), r]));
  for (const c of clients.values()) { const r = c.authed && byKey.get(c.world); if (r) r.count++; }
  // build open realms' maps ahead of time, and keep them while they're open
  if (sims) sims.keepOnly(realms.map(realmKey));
  const full = realms.every(r => r.count >= config.realmCap * 0.75);
  if (full && realms.length < config.maxRealms) { const r = newRealm(); realms.push(r); log('Opened a new realm: ' + r.name); }
  const js = JSON.stringify(realmList());
  if (js === lastRealmJson) return;
  lastRealmJson = js;
  for (const c of clients.values()) if (c.authed) c.send({ t: 'realms', list: realmList() });
}

// ------------------------------------------------------------------ clients
const clients = new Map(); // id -> client
const byName = new Map();  // lowername -> client
let nextId = 1;
const parties = new Map(); // party id -> {id, leader, members: Set<client>}
/** world key -> client whose game runs that world's monsters */
const hosts = new Map();
let nextParty = 1;

function log(...a) { console.log(new Date().toISOString().slice(11, 19), ...a); }

// ------------------------------------------------------------------ Discord feed
const { Discord, StatusBoard, esc: desc, names: dnames } = require('./discord');
const discord = new Discord(config.discordWebhook, config.name || 'Eldmere', log);
/** What the server did that's worth telling the Discord: (kind, details). */
function feat(kind, d) {
  if (!discord.on) return;
  if (kind === 'record') discord.post('🏆 **New record!** ' + dnames(d.names) + ' killed **' + desc(d.boss) + '** in **' + d.time + '**' + (d.old ? ' (beating ' + d.old + ')' : '') + '.', 0xffd75e);
  else if (kind === 'raid') discord.post('⭐ **' + desc(d.raid) + ' cleared!** ' + dnames(d.names) + ' defeated ' + desc(d.boss) + '.', d.color === undefined ? 0xffd060 : d.color);
  else if (kind === 'elder') discord.post('💀 **The Dark Elder has fallen** to ' + dnames(d.names) + '!', 0xff4060);
  else if (kind === 'godly') discord.post('✨ **' + desc(d.name) + '** found a Godly item: **' + desc(d.item) + '**' + (d.from ? ' from ' + desc(d.from) : '') + '!', 0xff60ff);
  else if (kind === 'vaultrecord') discord.post('⏱️ **Fastest Starfall Vault clear this week** (' + desc(d.twist) + '): ' + dnames(d.names) + ' in **' + d.time + '**!', 0x80e0ff);
  else if (kind === 'twist') discord.post('🌀 **This week in the Starfall Vault: ' + desc(d.name) + '.** ' + desc(d.desc) + ' Fastest clears earn the Twistbreaker title.', 0x80e0ff);
  else if (kind === 'title') discord.post('🎖️ **' + desc(d.name) + '** earned the title **' + desc(d.title) + '**.', d.color === undefined ? 0xff9a2e : d.color);
}

function str(v, max) { return typeof v === 'string' ? v.slice(0, max) : ''; }
function num(v) { return typeof v === 'number' && isFinite(v) ? v : 0; }

function inWorld(world, except) {
  const out = [];
  for (const c of clients.values()) if (c.authed && c.world === world && c !== except) out.push(c);
  return out;
}

/** Players near (x, y) in a world: movement and shots only go to those who can see them. */
/**
 * Casts after which a player rightly takes no hits for a while: their own dashes,
 * blinks and rewinds; a shield wall (everyone behind it); Time Stop (everyone near).
 * secs: how long (else the cast's own length); r: everyone within r of it (at the target for a shield).
 */
const GRACE = {
  charge: { secs: 1 }, volley: { secs: 1 }, bash: { secs: 1 }, shadow: { secs: 1 }, rewind: { secs: 1.2 },
  shield: { r: 6, at: 'target' }, timestop: { r: 5 }, ward: { secs: 1 }, whirlwind: { secs: 0.5 }
};

const FX_KINDS = new Set(['fireball', 'shield', 'storm', 'sanctuary', 'shadow', 'charge', 'harvest', 'snare',
  'lightning', 'frostnova', 'pierce', 'volley', 'bash', 'banner', 'smite', 'ward', 'knives', 'smoke', 'whirlwind', 'warcry',
  'prison', 'raise', 'explosive', 'wolf',
  'valor', 'lullaby', 'requiem', 'acid', 'elixir', 'philbomb', 'rewind', 'timestop', 'hastefield']);

function nearby(c) {
  const r2 = config.viewRange * config.viewRange;
  return inWorld(c.world, c).filter(o => (o.x - c.x) * (o.x - c.x) + (o.y - c.y) * (o.y - c.y) < r2);
}

function publicInfo(c) {
  return { id: c.id, name: c.name, x: c.x, y: c.y, profile: c.profile };
}

function guildOf(c) { return c.guild ? guilds[c.guild] : null; }

/** Same party or same guild. */
function friends(a, b) {
  return (a.party && a.party === b.party) || (a.guild && a.guild === b.guild);
}

// ------------------------------------------------------------------ messages
/**
 * An account's online save. Online and offline progress never mix: a new
 * account gets an empty save here on its first visit, and nothing from a
 * player's PC is ever imported.
 */
function onlineSave(key) {
  let s = store.getSave(key);
  if (!s) { s = {}; store.putSave(key, s); }
  // saves from before the item ledger: their items get ids once
  if (items.migrate(s)) store.putSave(key, s);
  return s;
}

/** A save as the player's game sees it (without the server's private ledger). */
function publicSave(s) {
  const o = Object.assign({}, s);
  delete o._ledger;
  delete o._ledgerV;
  delete o._quests;
  delete o._market;
  delete o._titles;
  delete o._fame;
  delete o._login;
  delete o._graves;
  o.earned = Object.keys(s._titles || {});
  return o;
}

/**
 * Checks a save from the player's game and stores it. Returns true if it was accepted;
 * otherwise the game gets its last good save back.
 */
function applySave(c, data, cid) {
  const prev = onlineSave(c.key);
  // (with server-run monsters, gold and fame are checked against what was earned instead of a time budget)
  let why = checkSave(prev, data, c.meta, Date.now(), sims && !isAdmin(c) ? ['gold', 'fame', 'onrane'] : null);
  // items must come from the server (admins are trusted), and stats stay within the class limits
  // (only when the server runs the monsters: otherwise players' games still roll loot)
  if (!why && !isAdmin(c) && sims) why = items.check(prev, data) || items.checkStats(data);
  // hero modes: Ironman and Hardcore rules (and modes can't change)
  const modeFixes = [];
  if (!why && prev) why = modes.check(prev, data, modeFixes);
  if (why) {
    log('refused save from ' + c.name + ': ' + why);
    counters.savesRefused++;
    store.appendLog('anticheat.log', new Date().toISOString() + ' ' + c.name + ': ' + why);
    c.send({ t: 'saveRejected', reason: why, data: publicSave(prev) });
    return false;
  }
  c.meta.lastSave = Date.now();
  data.tradeSeq = Math.max(data.tradeSeq || 0, prev ? prev.tradeSeq || 0 : 0);
  // the ledger is the server's: the game's copy is never trusted
  data._ledger = prev._ledger || {};
  data._ledgerV = prev._ledgerV || 1;
  // so is quest progress, and the Marketplace box (takings, returned items)
  if (prev._quests) data._quests = prev._quests; else delete data._quests;
  if (prev._market) data._market = prev._market; else delete data._market;
  // and the daily login streak
  if (prev._login) data._login = prev._login; else delete data._login;
  // and the fallen heroes an admin can bring back (see graves.js)
  if (prev._graves) data._graves = prev._graves; else delete data._graves;
  const fell = graves.fallen(prev, data);
  // gold and fame only go up by what the server saw earned
  if (sims && !isAdmin(c)) {
    const cut = wallet.settle(prev, data, c.meta, Date.now());
    if (cut) {
      log('wallet ' + c.name + ': ' + cut);
      counters.savesCut++;
      store.appendLog('anticheat.log', new Date().toISOString() + ' ' + c.name + ': ' + cut);
      c.send({ t: 'wallet', gold: data.gold || 0, fame: data.fame || 0, onrane: data.onrane || 0, skins: data.skins || {}, cosmetics: data.cosmetics || {} });
    }
  } else if (prev._fame) data._fame = prev._fame;
  // heroes that died go on the season ladder, and into the server's graves
  seasonSave(c, prev, data);
  graves.bury(data, fell, wallet.fameGain(prev, data));
  // and earned titles (the game's list is only a copy)
  if (prev._titles) data._titles = prev._titles; else delete data._titles;
  data.earned = Object.keys(data._titles || {});
  // admins' own new items join their ledger
  if (isAdmin(c)) items.eachItem(data, (it) => { if (!it.sid && !items.STARTERS.has(items.fingerprint(it))) items.issue(data, it); });
  store.putSave(c.key, data);
  // a Hardcore item equipped too early went back to the inventory: the game takes the server's copy
  if (modeFixes.length) c.send({ t: 'saveRejected', reason: modeFixes.join(' '), data: publicSave(data) });
  // the game says which hero it's playing with each shop request, so the shops never depend on
  // having seen this connection's last 'enter' (a reconnect, or a hero whose id was only just set)
  if (typeof cid === 'string' && cid && (data.chars || []).some((h) => h && h.id === cid)) c.charId = cid.slice(0, 64);
  // what this hero can deal now (new weapon, more Attack...), and its mode (a new hero's first save sets it)
  c.maxDps = isAdmin(c) ? 1e9 : maxDps(serverChar(c));
  c.mode = modes.modeOf(serverChar(c));
  // a cosmetic bought just now: the profile that came before this save can wear it now
  if (c.rawProfile && !isAdmin(c)) {
    const p = withBanner(c, cleanProfile(c.rawProfile, data));
    if (p.dye !== c.profile.dye || p.title !== c.profile.title || p.skin !== c.profile.skin) {
      c.profile = p;
      for (const o of inWorld(c.world, c)) o.send({ t: 'profile', id: c.id, profile: c.profile });
    }
  }
  return true;
}

/**
 * The most damage a second this hero could possibly deal with its own weapon and stats: every
 * shot hitting, crits, berserk, haste and might all at once, then half as much again for
 * abilities, pets and minions. The world simulations refuse damage beyond it (see WorldSim.hit).
 */
function maxDps(ch) {
  if (!ch || typeof ch !== 'object') return 0;
  const w = ch.weapon;
  const gear = (k) => [ch.weapon, ch.ability, ch.armor, ch.ring].reduce((n, it) => n + (it && typeof it === 'object' ? Number(it[k]) || 0 : 0), 0);
  const att = (Number(ch.stats && ch.stats.att) || 0) + gear('att') + 40;
  const dex = (Number(ch.stats && ch.stats.dex) || 0) + gear('dex') + 40;
  if (!w || typeof w !== 'object') return 3000;
  const avg = ((Number(w.dmin) || 0) + (Number(w.dmax) || 0)) / 2 * (Number(w.mult) || 1);
  const shots = Math.max(1, Math.min(9, Number(w.shots) || 1));
  const rate = (1.5 + 6.5 * dex / 75) * Math.min(2.5, Number(w.rate) || 1) * 1.5 * 1.4;
  const dps = avg * (0.5 + att / 50) * 1.3 * 1.6 * shots * rate;
  return Math.max(3000, Math.round(dps * 1.5 + 2000));
}

/** A purchase or forge went through: the player's game takes the server's inventory and currencies. */
function shopDone(c, sv, ch, extra) {
  sv.tradeSeq = (sv.tradeSeq || 0) + 1;
  store.putSave(c.key, sv);
  c.send(Object.assign({ t: 'shopDone', inv: ch.inv, gold: sv.gold || 0, onrane: sv.onrane || 0, seq: sv.tradeSeq }, extra));
}

/** Per-account anti-cheat state ({lastSave, budget}), kept across reconnects. */
const accountMeta = new Map();

/** Profiles are shown to everyone: keep only the fields the game uses, with sane types. sv: the account's save, to check cosmetics are owned. */
function cleanProfile(p, sv) {
  if (!p || typeof p !== 'object') return {};
  const out = { cls: str(p.cls, 16), skin: str(p.skin, 24), dye: str(p.dye, 24), title: str(p.title, 32), level: Math.max(1, Math.min(20, num(p.level) | 0)),
    fame: Math.max(0, num(p.fame) | 0), maxed: Math.max(0, Math.min(11, num(p.maxed) | 0)), guild: str(p.guild, 24),
    // loot luck (Bounty + streak + shrine), capped at what the game can reach
    lk: Math.max(0, Math.min(160, num(p.lk) | 0)), hs: p.hs ? 1 : 0 };
  // cosmetics: only ones this account owns (earned titles from the server's own list)
  if (sv) {
    const own = sv.cosmetics && typeof sv.cosmetics === 'object' ? sv.cosmetics : {};
    if (out.skin && !(sv.skins && sv.skins[out.skin])) out.skin = '';
    const dy = out.dye && Data.findDye(out.dye);
    if (out.dye && !(dy && (dy.earn ? sv._titles && sv._titles[out.dye] : own[out.dye]))) out.dye = '';
    const t = out.title && Data.findTitle(out.title);
    if (out.title && !(t && (t.earn ? sv._titles && sv._titles[out.title] : own[out.title]))) out.title = '';
  }
  if (!out.dye) delete out.dye;
  if (!out.title) delete out.title;
  if (Array.isArray(p.equip)) out.equip = p.equip.slice(0, 4).map((it) => (it && typeof it === 'object' && JSON.stringify(it).length < 4000 ? it : null));
  return out;
}

const handlers = {
  hello(c, m) {
    if (c.authed || c.loggingIn) return;
    if (m.ver !== VERSION) return c.fail('Version mismatch: this server runs New Realm network version ' + VERSION +
      ' and your game uses version ' + m.ver + '. Open the game with the Eldmere launcher to get the latest version.');
    // accounts live on the server: register, log in with a password, or resume a remembered session
    const name = str(m.name, 12);
    const password = typeof m.password === 'string' ? m.password.slice(0, 64) : '';
    const token = str(m.token, 64);
    if (!/^[A-Za-z0-9]{3,12}$/.test(name)) return c.fail('Usernames are 3-12 letters or numbers.');
    if (loginLocked(c.ip)) return c.fail('Too many failed logins. Wait a few minutes and try again.');
    const key = name.toLowerCase();
    const acc = accounts[key];
    // (password hashing is slow on purpose, so it runs off the main thread: everyone else keeps playing)
    const hashThen = (pw, salt, done) => {
      c.loggingIn = true;
      crypto.scrypt(String(pw), salt, 32, (err, buf) => {
        c.loggingIn = false;
        if (err || !clients.has(c.id)) return;
        done(buf.toString('hex'));
      });
    };
    if (m.register) {
      if (acc) return c.fail('That username is already taken.');
      if (password.length < 4) return c.fail('Passwords need at least 4 characters.');
      const salt = crypto.randomBytes(16).toString('hex');
      return hashThen(password, salt, (hash) => {
        if (accounts[key]) return c.fail('That username is already taken.');
        const a = accounts[key] = { name, no: nextAccountNo(), created: Date.now(), pwSalt: salt, pwHash: hash };
        const session = newSession(a);
        save('accounts.json', accounts);
        log('new account', name, '#' + a.no);
        finishLogin(c, a, key, session);
      });
    }
    if (password) {
      if (!acc) { loginFailed(c.ip); return c.fail('No account with that username.'); }
      if (!acc.pwHash) {
        // made before passwords: the PC it was first played on still holds its token
        if (!hasSession(acc, str(m.legacy, 64))) {
          return c.fail('This account was made before passwords. Log in once from the PC you first played on to set its password.');
        }
        const salt = crypto.randomBytes(16).toString('hex');
        return hashThen(password, salt, (hash) => {
          acc.pwSalt = salt; acc.pwHash = hash;
          log(name, 'set a password');
          const session = newSession(acc);
          save('accounts.json', accounts);
          finishLogin(c, acc, key, session);
        });
      }
      return hashThen(password, acc.pwSalt, (hash) => {
        const a = Buffer.from(hash, 'hex'), b = Buffer.from(acc.pwHash, 'hex');
        if (!(a.length === b.length && crypto.timingSafeEqual(a, b))) { loginFailed(c.ip); return c.fail('Wrong password.'); }
        const session = newSession(acc);
        save('accounts.json', accounts);
        finishLogin(c, acc, key, session);
      });
    }
    if (!acc || !hasSession(acc, token)) { loginFailed(c.ip); return c.fail('Please log in again.'); }
    finishLogin(c, acc, key, null);
  },

  enter(c, m) {
    let world = str(m.key, 80);
    // a guild's hall is for its members: anyone else gets a hall of their own (empty)
    if (world.startsWith('ghall:') && world !== 'ghall:' + c.guild) world = 'solo:hall:' + c.id;
    leaveWorld(c);
    c.world = world;
    c.x = num(m.x); c.y = num(m.y);
    c.mv = null; // a new world: movement checks start again from where you arrive
    if (m.cid) c.charId = str(m.cid, 64);
    // the godmode count starts over in each world
    c.expHits = 0; c.hitsBase = c.hitsRep || 0; c.expBase = 0;
    c.maxDps = isAdmin(c) ? 1e9 : maxDps(serverChar(c));
    c.mode = modes.modeOf(serverChar(c));
    if (m.profile && typeof m.profile === 'object') c.rawProfile = m.profile;
    c.profile = withBanner(c, cleanProfile(m.profile, isAdmin(c) ? null : onlineSave(c.key)));
    if (c.trade) endTrade(c, 'The trade was cancelled.');
    updateRealms();
    // the first player in a world runs its monsters
    // the server runs this world's monsters, or else the first player in it does
    c.sim = sims ? sims.join(world, c) : null;
    if (!c.sim && (!hosts.get(world) || hosts.get(world).world !== world)) hosts.set(world, c);
    c.send({ t: 'players', key: world, host: c.sim ? 0 : hosts.get(world).id, list: inWorld(world, c).map(publicInfo) });
    for (const o of inWorld(world, c)) o.send({ t: 'join', p: publicInfo(c) });
    updateGuildMember(c);
    sendParty(c.party);
    // the first time into the game each day: the daily login reward
    dailyLogin(c);
    // let the party follow you into dungeons
    const p = parties.get(c.party);
    if (p && world.startsWith('dg:')) {
      for (const o of p.members) if (o !== c && o.world !== world) o.note(c.name + ' entered the ' + str(m.label, 40) + '. Type /join ' + c.name + ' to follow.', 0x7fd8ff);
    }
  },

  move(c, m) {
    const nx = num(m.x), ny = num(m.y);
    if (!moveAllowed(c, nx, ny)) return;
    c.x = nx; c.y = ny;
    c.hidden = !!m.h;
    const msg = { t: 'move', id: c.id, x: c.x, y: c.y, f: m.f ? 1 : 0, a: m.a ? 1 : 0 };
    const near = new Set(nearby(c));
    if (!c.seen) c.seen = new Set();
    for (const o of near) {
      o.send(msg);
      (o.seen || (o.seen = new Set())).add(c.id);
      // someone standing still sends no moves: show them to you as you walk up
      if (!c.seen.has(o.id)) { c.seen.add(o.id); c.send({ t: 'move', id: o.id, x: o.x, y: o.y, f: 0, a: 0 }); }
    }
    // everyone else in the world: hide you once you're out of sight, and keep
    // party and guild members posted about once a second (minimap, teleports)
    const now = Date.now();
    const slow = now - (c.farT || 0) > 1000;
    if (slow) c.farT = now;
    for (const o of inWorld(c.world, c)) {
      if (near.has(o)) continue;
      if (o.seen && o.seen.delete(c.id)) o.send({ t: 'far', id: c.id });
      if (c.seen.delete(o.id)) c.send({ t: 'far', id: o.id });
      if (slow && friends(o, c)) o.send({ t: 'move', id: c.id, x: c.x, y: c.y, f: 0, a: 0, far: 1 });
    }
  },

  /** Someone opened a raid: tell everyone on the server. */
  raidOpen(c, m) {
    if (c.world !== 'nexus') return;
    const now = Date.now();
    if (now - (c.raidT || 0) < 20000) return;
    c.raidT = now;
    const name = str(m.name, 40);
    const color = Number(m.color) & 0xffffff;
    for (const o of clients.values()) {
      if (!o.authed || o === c) continue;
      o.send({ t: 'banner', text: name + ' is open!', color,
        msg: c.name + ' opened a portal to ' + name + ' in the Nexus! It closes in 30 seconds.' });
    }
  },

  /** Teleport: the exact spot of a party or guild member in your world, straight from the server. */
  tpreq(c, m) {
    const o = clients.get(Number(m.id));
    if (!o || !o.authed || o.world !== c.world) return c.note('They are not in this world.');
    if (!config.teleportToAnyone && !friends(c, o)) return c.note('You can only teleport to party and guild members.');
    c.send({ t: 'tppos', id: o.id, name: o.name, x: o.x, y: o.y });
    // the jump to them is expected
    c.tpTo = { x: o.x, y: o.y, until: Date.now() + 8000 };
  },

  shoot(c, m) {
    const now = Date.now();
    if (now - (c.shotAt || 0) < 40) return;
    c.shotAt = now;
    const msg = { t: 'shoot', id: c.id, ang: num(m.ang) };
    for (const o of nearby(c)) o.send(msg);
  },

  /** An ability cast: only its animation is shown to the players around. */
  fx(c, m) {
    const now = Date.now();
    if (now - (c.fxAt || 0) < 300) return;
    c.fxAt = now;
    const k = String(m.k || '').slice(0, 12);
    if (!FX_KINDS.has(k)) return;
    const msg = { t: 'fx', id: c.id, k, x: num(m.x), y: num(m.y), tx: num(m.tx), ty: num(m.ty), n: Math.min(2000, Math.max(0, num(m.n))) };
    for (const o of nearby(c)) o.send(msg);
    // abilities that rightly stop shots: no hits are expected for a moment (godmode checks)
    const g = GRACE[k];
    if (g) {
      const until = now + (g.secs ? g.secs : Math.min(12, msg.n)) * 1000;
      const gx = g.at === 'target' ? msg.tx : msg.x, gy = g.at === 'target' ? msg.ty : msg.y;
      for (const o of [c].concat(g.r ? inWorld(c.world, c) : [])) {
        if (o !== c && (o.x - gx) * (o.x - gx) + (o.y - gy) * (o.y - gy) > g.r * g.r) continue;
        o.grace = Math.max(o.grace || 0, until);
      }
    }
  },

  /** The game's count of monster hits it has taken (it only grows); see godmodeCheck. */
  hits(c, m) {
    const n = num(m.n) | 0;
    // (the count runs for the whole game session: a reconnect starts from wherever it is)
    if (c.hitsRep === undefined) { c.hitsRep = c.hitsBase = n; return; }
    if (n > c.hitsRep && n - c.hitsRep < 500) c.hitsRep = n;
  },

  profile(c, m) {
    if (!m.profile || typeof m.profile !== 'object') return;
    c.rawProfile = m.profile;
    c.profile = withBanner(c, cleanProfile(m.profile, isAdmin(c) ? null : onlineSave(c.key)));
    for (const o of inWorld(c.world, c)) o.send({ t: 'profile', id: c.id, profile: c.profile });
    updateGuildMember(c);
  },

  chat(c, m) {
    const text = str(m.text, 120);
    if (!text || !chatAllowed(c)) return;
    for (const o of inWorld(c.world, c)) o.send({ t: 'chat', id: c.id, name: c.name, text });
  },

  pchat(c, m) {
    const text = str(m.text, 120);
    const p = parties.get(c.party);
    if (!text || !p || !chatAllowed(c)) return;
    for (const o of p.members) if (o !== c) o.send({ t: 'chat', ch: 'party', id: c.id, name: c.name, text });
  },

  gchat(c, m) {
    const text = str(m.text, 120);
    if (!text || !c.guild || !chatAllowed(c)) return;
    for (const o of byName.values()) if (o !== c && o.guild === c.guild) o.send({ t: 'chat', ch: 'guild', id: c.id, name: c.name, text });
  },

  // ---------------------------------------------------------------- trading
  tradeReq(c, m) {
    const o = clients.get(m.to);
    if (!o || !o.authed || o.world !== c.world) return c.note('That player isn\'t here.');
    if (o === c) return;
    if (modes.restricted(c.mode)) return c.note('Ironman and Hardcore heroes can\'t trade.');
    if (modes.restricted(o.mode)) return c.note(o.name + ' is an ' + (o.mode === 'hardcore' ? 'Hardcore' : 'Ironman') + ' hero and can\'t trade.');
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
    if (modes.restricted(c.mode) || modes.restricted(o.mode)) return o.note('Ironman and Hardcore heroes can\'t trade.');
    // trades run on the server's copies of both inventories (each side saves just before)
    if (!serverInv(o) || !serverInv(c)) {
      o.note('The trade could not start: a character has not been saved yet. Try again in a moment.');
      return c.note('The trade could not start: a character has not been saved yet. Try again in a moment.');
    }
    const t = { a: o, b: c, acc: new Set(), sel: new Map(), offers: new Map() };
    o.trade = c.trade = t;
    t.snapA = JSON.stringify(serverInv(o));
    t.snapB = JSON.stringify(serverInv(c));
    // both sides trade from the server's copy of their inventory (saved just before)
    o.send({ t: 'tradeStart', with: c.id, inv: serverInv(c) || (Array.isArray(m.inv) ? m.inv : []), sendInv: !serverInv(o) });
    if (serverInv(o)) c.send({ t: 'tradeStart', with: o.id, inv: serverInv(o) });
  },

  tradeInv(c, m) {
    // only for a side the server has no copy of (never, since trades need one): ignore fakes
    const t = c.trade;
    if (!t || t.a !== c || serverInv(c)) return;
    t.b.send({ t: 'tradeStart', with: c.id, inv: Array.isArray(m.inv) ? m.inv : [] });
  },

  tradeOffer(c, m) {
    const t = c.trade;
    if (!t) return;
    t.acc.clear();
    const sel = Array.isArray(m.sel) ? m.sel.slice(0, 16).map(v => v === true) : [];
    t.sel.set(c, sel);
    // numbered, so an accept sent before this change can't count for it
    const n = (t.offers.get(c) || 0) + 1;
    t.offers.set(c, n);
    partner(c).send({ t: 'tradeOffer', sel, want: Array.isArray(m.want) ? m.want.slice(0, 16) : [], n });
  },

  tradeAccept(c, m) {
    const t = c.trade;
    if (!t) return;
    // the accept must be for the partner's latest offer
    if ((m.seen | 0) !== (t.offers.get(partner(c)) || 0)) return;
    t.acc.add(c);
    partner(c).send({ t: 'tradeAccept' });
    if (t.acc.size === 2) finishTrade(t);
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
    reshowOne(c);
    sendGuild(gk);
  },

  guildLeave(c) {
    const g = guildOf(c);
    if (!g) return;
    const gk = c.guild;
    if (g.members[c.key].rank === FOUNDER) {
      if ((g.bank || []).some(Boolean)) return c.note('Empty the guild bank (Guild Hall, Nexus) before disbanding the guild.');
      // the founder leaving disbands the guild
      delete guilds[gk];
      for (const o of byName.values()) if (o.guild === gk) { o.guild = null; o.note(g.name + ' was disbanded.', 0x80ff80); o.send({ t: 'guild', guild: null }); reshowOne(o); }
    } else {
      delete g.members[c.key];
      c.guild = null;
      c.send({ t: 'guild', guild: null });
      c.note('You left ' + g.name + '.', 0x80ff80);
      reshowOne(c);
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
    if (o) { o.guild = null; o.send({ t: 'guild', guild: null }); o.note('You were removed from ' + g.name + '.', 0xff8080); reshowOne(o); }
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

  // ---------------------------------------------------------------- guild hall
  /** The Guild Hall page. */
  ghView(c) {
    const now = Date.now();
    if (now - (c.ghT || 0) < 400) return;
    c.ghT = now;
    sendHall(c);
  },

  /** Puts an inventory item in the guild bank. */
  ghPut(c, m) {
    if (modes.restricted(c.mode)) return c.send({ t: 'shopFail', msg: 'Ironman and Hardcore heroes can\'t use the guild bank.' });
    const g = guildOf(c);
    if (!g) return c.send({ t: 'shopFail', msg: 'You\'re not in a guild.' });
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was stored.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const r = hall.deposit(g, sv, ch.inv, num(m.slot) | 0, c.name);
    if (typeof r === 'string') return c.send({ t: 'shopFail', msg: r });
    save('guilds.json', guilds);
    shopDone(c, sv, ch, { market: 'You put ' + (r.name || 'your item') + ' in the guild bank.' });
    for (const o of byName.values()) if (o.guild === c.guild) sendHall(o);
  },

  /** Takes an item out of the guild bank. */
  ghTake(c, m) {
    if (modes.restricted(c.mode)) return c.send({ t: 'shopFail', msg: 'Ironman and Hardcore heroes can\'t use the guild bank.' });
    const g = guildOf(c);
    if (!g) return c.send({ t: 'shopFail', msg: 'You\'re not in a guild.' });
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was taken.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const r = hall.withdraw(g, sv, ch.inv, num(m.idx) | 0, g.members[c.key].rank, c.name);
    if (typeof r === 'string') { sendHall(c); return c.send({ t: 'shopFail', msg: r }); }
    save('guilds.json', guilds);
    shopDone(c, sv, ch, { market: 'You took ' + (r.name || 'an item') + ' from the guild bank.' });
    for (const o of byName.values()) if (o.guild === c.guild) sendHall(o);
  },

  /** Flies one of the guild's earned banners (leaders). */
  ghBanner(c, m) {
    const g = guildOf(c);
    if (!g) return;
    const id = str(m.id, 24);
    const err = hall.fly(g, id, g.members[c.key].rank);
    if (err) return c.note(err);
    save('guilds.json', guilds);
    const b = hall.findBanner(id);
    for (const o of byName.values()) if (o.guild === c.guild) { o.note(c.name + (b ? ' raised the ' + b.name + ' banner.' : ' lowered the guild banner.'), 0x80ff80); sendHall(o); }
    reshowBanner(c.guild);
    sendGuild(c.guild);
  },

  /** The Banner Maker: a leader saves the guild's own banner design and flies it. */
  ghDesign(c, m) {
    const g = guildOf(c);
    if (!g) return;
    const now = Date.now();
    if (now - (c.ghDesignT || 0) < 3000) return c.note('Give it a moment before saving another design.');
    const r = hall.design(g, str(m.code, 24), g.members[c.key].rank, c.name);
    if (!r.startsWith('c:')) return c.note(r);
    c.ghDesignT = now;
    save('guilds.json', guilds);
    for (const o of byName.values()) if (o.guild === c.guild) { o.note(c.name + ' raised a new guild-made banner.', 0x80ff80); sendHall(o); }
    reshowBanner(c.guild);
    sendGuild(c.guild);
  },

  /** Monster sync between the world host and the others (see WorldSync.as). */
  w(c, m) {
    if (!c.world || !m.d || typeof m.d !== 'object') return;
    // server-run world: the server is the host; players may only share portals
    if (c.sim) {
      if (m.to === 'host') return c.sim.onClient(c, m.d);
      if (m.to !== 'all' || m.d.t !== 'portal') return;
    }
    if (m.to === 'all' && hosts.get(c.world) !== c && m.d.t !== 'portal' && m.d.t !== 'rstage') return;
    const out = { t: 'w', from: c.id, d: m.d };
    if (m.to === 'all') { for (const o of inWorld(c.world, c)) o.send(out); return; }
    const target = m.to === 'host' ? hosts.get(c.world) : clients.get(m.to);
    if (target && target !== c && target.world === c.world) target.send(out);
  },

  ping(c, m) { c.send({ t: 'pong', at: m.at }); },

  /** Change (or, for old accounts, set) the password. */
  password(c, m) {
    const acc = accounts[c.key];
    const pw = typeof m.pw === 'string' ? m.pw.slice(0, 64) : '';
    if (acc.pwHash && !checkPassword(acc, typeof m.old === 'string' ? m.old : '')) return c.send({ t: 'password', ok: false, msg: 'Current password is wrong.' });
    if (pw.length < 4) return c.send({ t: 'password', ok: false, msg: 'Passwords need at least 4 characters.' });
    setPassword(acc, pw);
    // other PCs have to log in again with the new password
    acc.sessions = [];
    const session = newSession(acc);
    save('accounts.json', accounts);
    c.send({ t: 'password', ok: true, session });
  },

  /** Log out: forget this PC's remembered session. */
  logout(c, m) {
    const acc = accounts[c.key];
    const h = hashToken(str(m.token, 64), 'session');
    acc.sessions = (acc.sessions || []).filter(s => s !== h);
    save('accounts.json', accounts);
    c.close();
  },

  /** The account's save (characters, vault, gold...). Checked, then stored. */
  save(c, m) {
    // at most a few saves a second; a burst keeps only the newest
    const now = Date.now();
    if (now - (c.saveAt || 0) < 300) {
      c.pendingSave = m;
      if (!c.saveTimer) c.saveTimer = setTimeout(() => { c.saveTimer = null; const p = c.pendingSave; c.pendingSave = null; if (p && !c.replaced && clients.has(c.id)) handlers.save(c, p); }, 320);
      return;
    }
    c.saveAt = now;
    applySave(c, m.data);
  },

  /** Marketplace and Key Merchant: the server checks the gold and hands out the item. */
  buy(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was bought.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const what = str(m.what, 12);
    let price, make;
    if (what === 'key') {
      const di = num(m.dg) | 0;
      if (!Data.DUNGEONS[di]) return;
      price = Data.keyPrice(di);
      make = () => Data.makeDungeonKey(di);
    } else {
      const e = Data.SHOP.find((x) => x.id === what);
      const cls = Data.CLASSES[ch.cls] || Data.CLASSES.wizard;
      const makers = { hp: () => Data.makePotion('hp'), mp: () => Data.makePotion('mp'), stat: () => Data.makePotion('stat', Data.randomStat()),
        sor: () => Data.makeSor(), ut: () => Data.makeForSlot(cls, Math.floor(Math.random() * 3), 7, null) };
      if (!e || !makers[what]) return;
      price = e.price;
      make = makers[what];
    }
    if ((sv.gold || 0) < price) return c.send({ t: 'shopFail', msg: 'Not enough gold.' });
    const slot = ch.inv.indexOf(null);
    if (slot < 0) return c.send({ t: 'shopFail', msg: 'Inventory full!' });
    const item = items.issue(sv, make());
    ch.inv[slot] = item;
    sv.gold = (sv.gold || 0) - price;
    shopDone(c, sv, ch, { bought: item.name });
  },

  /** Selling an item to the Nexus merchant (shift-click at the Marketplace): the server pays for it. */
  sell(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was sold.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const slot = num(m.slot) | 0, item = ch.inv[slot];
    if (!item || typeof item !== 'object') return c.send({ t: 'shopFail', msg: 'There is nothing to sell there.' });
    const value = Math.max(0, Data.sellValue(item) | 0);
    ch.inv[slot] = null;
    items.release(sv, item);
    sv.gold = (sv.gold || 0) + value;
    shopDone(c, sv, ch, { sold: item.name || 'an item', value });
  },

  /** Starforge: a Runed, Bonded or Eldritch item + a Star Shard + 100 Aether = a Starforged item. */
  forge(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was forged.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const slot = num(m.slot) | 0, item = ch.inv[slot];
    if (!item || !item.rarity || item.rarity === 'lg' || item.rarity === 'ar' || item.rarity === 'gd') return c.send({ t: 'shopFail', msg: 'That item cannot be forged.' });
    const sor = ch.inv.findIndex((it) => it && it.kind === 'material');
    if (sor < 0) return c.send({ t: 'shopFail', msg: 'You need a Star Shard.' });
    if ((sv.onrane || 0) < 100) return c.send({ t: 'shopFail', msg: 'You need 100 Aether.' });
    const cls = Data.CLASSES[ch.cls] || Data.CLASSES.wizard;
    const lg = items.issue(sv, Data.forgeLegendary(item, cls));
    // the two items it was made from are used up for good
    const l = sv._ledger || {};
    delete l[item.sid];
    delete l[ch.inv[sor].sid];
    ch.inv[sor] = null;
    ch.inv[slot] = lg;
    sv.onrane = (sv.onrane || 0) - 100;
    shopDone(c, sv, ch, { forged: lg.name, slot });
  },

  /** The player marketplace: what's for sale. */
  mkView(c) {
    const now = Date.now();
    if (now - (c.mkT || 0) < 400) return;
    c.mkT = now;
    sendMarket(c);
  },

  /** Puts an inventory item up for sale. */
  mkList(c, m) {
    if (modes.restricted(c.mode)) return c.send({ t: 'shopFail', msg: 'Ironman and Hardcore heroes can\'t use the Marketplace.' });
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was listed.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const r = market.list(sv, c.key, c.name, ch.inv, num(m.slot) | 0, num(m.price));
    if (typeof r === 'string') return c.send({ t: 'shopFail', msg: r });
    shopDone(c, sv, ch, { market: 'Listed ' + (r.item.name || 'your item') + ' for ' + r.price.toLocaleString('en') + ' gold.' });
    sendMarket(c);
  },

  /** Buys a listing (the seller can be offline: their takings wait for them). */
  mkBuy(c, m) {
    if (modes.restricted(c.mode)) return c.send({ t: 'shopFail', msg: 'Ironman and Hardcore heroes can\'t use the Marketplace.' });
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was bought.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const l = market.find(num(m.id) | 0);
    if (!l) { sendMarket(c); return c.send({ t: 'shopFail', msg: 'Someone else bought that first.' }); }
    const sellerSv = l.seller === c.key ? null : onlineSave(l.seller);
    const r = market.buy(sv, c.key, ch.inv, l.id, sellerSv);
    if (typeof r === 'string') return c.send({ t: 'shopFail', msg: r });
    if (sellerSv) store.putSave(l.seller, sellerSv);
    if (sellerSv && Market.box(sellerSv).sold >= 10) grantTitle(l.seller, 'merchant');
    shopDone(c, sv, ch, { market: 'Bought ' + (l.item.name || 'an item') + ' from ' + l.sellerName + ' for ' + r.paid.toLocaleString('en') + ' gold.' });
    sendMarket(c);
    const seller = byName.get(l.seller);
    if (seller) {
      seller.send({ t: 'msg', color: 0x6fe08f, text: c.name + ' bought your ' + (l.item.name || 'item') + ' for ' + r.paid.toLocaleString('en') + ' gold! Collect ' + r.earned.toLocaleString('en') + ' gold at the Marketplace.' });
      sendMarket(seller);
    }
  },

  /** Takes a listing back. */
  mkCancel(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const r = market.cancel(sv, c.key, ch.inv, num(m.id) | 0);
    if (typeof r === 'string') return c.send({ t: 'shopFail', msg: r });
    shopDone(c, sv, ch, { market: 'Took ' + (r.item.name || 'your item') + ' off the market.' });
    sendMarket(c);
  },

  /** Collects takings and returned items. */
  mkCollect(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const r = Market.collect(sv, ch.inv);
    shopDone(c, sv, ch, { market: 'Collected ' + r.gold.toLocaleString('en') + ' gold' + (r.items ? ' and ' + r.items + ' item' + (r.items === 1 ? '' : 's') : '') +
      (r.left ? ' (' + r.left + ' more waiting: make room in your inventory)' : '') + '.' });
    sendMarket(c);
  },

  /** Today's quests and the week's, for the Quest Board. */
  quests(c) {
    const now = Date.now();
    if (now - (c.questsT || 0) < 1000) return;
    c.questsT = now;
    c.send({ t: 'quests', q: quests.view(onlineSave(c.key)) });
  },

  /** Claims a finished quest: the reward goes into the server's copy of the save, then the game takes it. */
  questClaim(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so the reward was not claimed.' });
    const sv = onlineSave(c.key);
    const got = quests.claim(sv, !!m.w, num(m.i) | 0);
    if (typeof got === 'string') return c.send({ t: 'shopFail', msg: got });
    sv.tradeSeq = (sv.tradeSeq || 0) + 1;
    store.putSave(c.key, sv);
    c.send({ t: 'questDone', gold: sv.gold || 0, onrane: sv.onrane || 0, seq: sv.tradeSeq, got, q: quests.view(sv) });
    if (sv._quests.wk >= 4) grantTitle(c.key, 'questor');
  },

  /** The fastest event kills, for the Records page. */
  records(c) {
    const now = Date.now();
    if (now - (c.recordsT || 0) < 1000) return;
    c.recordsT = now;
    c.send({ t: 'records', r: records, season: ladder.view(c.key) });
  },

  /** Starforge reroll: a weapon's prefix for gold, or a special item's bonus stats for Aether. */
  reroll(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was rerolled.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const slot = num(m.slot) | 0, item = ch.inv[slot];
    const form = m.what === 'form';
    if (!item || !(form ? Data.canRerollForm(item) : Data.canRerollStats(item))) return c.send({ t: 'shopFail', msg: 'That item cannot be rerolled.' });
    if (form && (sv.gold || 0) < Data.REROLL_FORM_GOLD) return c.send({ t: 'shopFail', msg: 'Not enough gold.' });
    if (!form && (sv.onrane || 0) < Data.REROLL_STATS_AETHER) return c.send({ t: 'shopFail', msg: 'Not enough Aether.' });
    const made = items.issue(sv, form ? Data.rerollForm(item) : Data.rerollStats(item));
    // the old item is gone for good
    if (item.sid && sv._ledger) delete sv._ledger[item.sid];
    ch.inv[slot] = made;
    if (form) sv.gold = (sv.gold || 0) - Data.REROLL_FORM_GOLD;
    else sv.onrane = (sv.onrane || 0) - Data.REROLL_STATS_AETHER;
    shopDone(c, sv, ch, { rerolled: made.name, slot });
  },

  /** A realm closed in someone's game: replace it with a fresh one. */
  realmClosed(c, m) {
    const key = str(m.key, 80);
    const i = realms.findIndex(r => realmKey(r) === key);
    if (i < 0) return;
    realms[i] = newRealm();
    log('Realm ' + key.split(':')[1] + ' closed; opened ' + realms[i].name);
    lastRealmJson = '';
    updateRealms();
  },

  /** Slash commands the server handles: /report for everyone, moderation for admins. */
  cmd(c, m) {
    const parts = str(m.text, 200).trim().split(/\s+/);
    const cmd = (parts[0] || '').toLowerCase();
    // (an account can be named by its number too: /ban #12)
    const who = accountKey(parts[1]) || (parts[1] || '').toLowerCase();
    const rest = parts.slice(2).join(' ');
    if (cmd === '/report') {
      if (!who) return c.note('Usage: /report name reason');
      store.appendLog('reports.log', new Date().toISOString() + ' ' + c.name + ' reported ' + parts[1] + ': ' + rest);
      for (const a of byName.values()) if (isAdmin(a)) a.note('[Report] ' + c.name + ' reported ' + parts[1] + ': ' + rest, 0xffb040);
      return c.note('Thanks, your report was sent to the server admins.', 0x80ff80);
    }
    if (!isAdmin(c)) return c.note('Only server admins can use ' + cmd + '.');
    const target = byName.get(who);
    switch (cmd) {
      case '/kick':
        if (!target) return c.note('Nobody called ' + parts[1] + ' is online.');
        target.send({ t: 'kicked', msg: 'You were kicked by ' + c.name + (rest ? ': ' + rest : '.') });
        target.close(true);
        return c.note('Kicked ' + target.name + '.', 0x80ff80);
      case '/ban': {
        // /ban name [hours] [reason]
        if (!who || !accounts[who]) return c.note('No account called ' + parts[1] + '.');
        const hours = parseFloat(parts[2]);
        const reason = isNaN(hours) ? rest : parts.slice(3).join(' ');
        bans[who] = { until: isNaN(hours) ? 0 : Date.now() + hours * 3600000, reason, by: c.name };
        save('bans.json', bans);
        if (target) { target.send({ t: 'kicked', msg: 'You were banned' + (reason ? ': ' + reason : '.') }); target.close(true); }
        log(c.name + ' banned ' + who + (isNaN(hours) ? '' : ' for ' + hours + 'h'));
        return c.note('Banned ' + parts[1] + (isNaN(hours) ? ' permanently.' : ' for ' + hours + ' hours.'), 0x80ff80);
      }
      case '/unban':
        delete bans[who];
        save('bans.json', bans);
        return c.note('Unbanned ' + parts[1] + '.', 0x80ff80);
      case '/mute': {
        if (!target) return c.note('Nobody called ' + parts[1] + ' is online.');
        const mins = parseFloat(parts[2]) || 10;
        target.mutedUntil = Date.now() + mins * 60000;
        target.note('You were muted for ' + mins + ' minutes.');
        return c.note('Muted ' + target.name + ' for ' + mins + ' minutes.', 0x80ff80);
      }
      case '/unmute':
        if (target) target.mutedUntil = 0;
        return c.note('Unmuted ' + parts[1] + '.', 0x80ff80);
      case '/announce':
        broadcast('[Server] ' + parts.slice(1).join(' '));
        return;
      case '/give': {
        // /give name 1000 gold|fame|aether: gold and fame are the server's to hand out now
        const amount = Math.floor(Number(parts[2]));
        const what = { gold: 'gold', fame: 'fame', aether: 'onrane', onrane: 'onrane' }[(parts[3] || 'gold').toLowerCase()];
        if (!who || !accounts[who] || !(Math.abs(amount) > 0 && Math.abs(amount) <= 10000000) || !what) return c.note('Usage: /give name amount gold|fame|aether');
        const sv = onlineSave(who);
        sv[what] = Math.max(0, (sv[what] || 0) + amount);
        // (newer than any save the game has in flight, so the gift can't be overwritten)
        sv.tradeSeq = (sv.tradeSeq || 0) + 1;
        store.putSave(who, sv);
        const label = what === 'onrane' ? 'Aether' : what;
        log(c.name + ' gave ' + accounts[who].name + ' ' + amount + ' ' + label);
        if (target) {
          target.send({ t: 'given', gold: sv.gold || 0, fame: sv.fame || 0, onrane: sv.onrane || 0, seq: sv.tradeSeq });
          target.note(c.name + (amount > 0 ? ' gave you ' : ' took ') + Math.abs(amount).toLocaleString('en') + ' ' + label + '.', 0x80ff80);
        }
        return c.note((amount > 0 ? 'Gave ' : 'Took ') + Math.abs(amount).toLocaleString('en') + ' ' + label + (amount > 0 ? ' to ' : ' from ') + accounts[who].name + '.', 0x80ff80);
      }
      case '/whois': {
        // /whois name or #number: the account at a glance (also helps check someone really owns it)
        if (!accounts[who]) return c.note('Usage: /whois name or /whois #number');
        for (const line of whoisLines(who)) c.note(line, 0x9fe0ff);
        return;
      }
      case '/graves': {
        // /graves name: the account's fallen heroes, newest first, to pick one for /revive
        if (!accounts[who]) return c.note('Usage: /graves name (then /revive name number)');
        const g = graves.list(onlineSave(who));
        if (!g.length) return c.note(accountTag(who) + ' has no fallen heroes the server kept.');
        c.note(accountTag(who) + ': fallen heroes (newest first). /revive ' + accounts[who].name + ' number', 0x9fe0ff);
        g.forEach((e, i) => c.note('  ' + (i + 1) + ') ' + graveLine(e), 0x9fe0ff));
        return;
      }
      case '/revive': {
        // /revive name number: bring a fallen hero back (after an unfair death)
        const n = Math.floor(Number(parts[2]));
        if (!accounts[who] || !(n >= 1)) return c.note('Usage: /revive name number (see /graves name for the numbers)');
        const sv = onlineSave(who);
        const r = graves.revive(sv, n);
        if (r.error) return c.note(r.error);
        store.putSave(who, sv);
        const h = r.hero, what = h.name + ' (level ' + (h.level || 1) + ' ' + clsName(h.cls) + ')';
        log(c.name + ' revived ' + what + ' for ' + accountTag(who) + (r.fameBack ? ', taking back ' + r.fameBack + ' fame' : ''));
        store.appendLog('admin.log', new Date().toISOString() + ' ' + c.name + ' revived ' + what + ' for ' + accountTag(who));
        if (target) {
          target.send({ t: 'revived', hero: h, fame: sv.fame || 0, deaths: sv.deaths || 0, graves: sv.graves || [], seq: sv.tradeSeq });
          target.note(c.name + ' brought back your hero ' + h.name + '. Pick it on the character screen.' + (r.fameBack ? ' (The ' + r.fameBack.toLocaleString('en') + ' fame its death gave was taken back.)' : ''), 0x80ff80);
        }
        return c.note('Revived ' + what + ' for ' + accountTag(who) + '.' + (r.fameBack ? ' Took back the ' + r.fameBack.toLocaleString('en') + ' fame its death gave.' : ''), 0x80ff80);
      }
      case '/setpassword': {
        // /setpassword name newpassword: for players who forgot theirs (check it's really them first: /whois)
        const pw = parts[2] || '';
        if (!accounts[who] || !pw) return c.note('Usage: /setpassword name newpassword (they log in with it, then can change it under Account)');
        if (pw.length < 4 || pw.length > 64) return c.note('Passwords need 4-64 characters.');
        if (who !== c.key && config.admins.some((a) => String(a).toLowerCase() === who) && !isOwner(c)) return c.note('Only the server owner can reset another admin\'s password.');
        setPassword(accounts[who], pw);
        // every PC logged in to it has to use the new password
        accounts[who].sessions = [];
        save('accounts.json', accounts);
        log(c.name + ' set a new password for ' + accountTag(who));
        store.appendLog('admin.log', new Date().toISOString() + ' ' + c.name + ' set a new password for ' + accountTag(who));
        if (target && target !== c) { target.send({ t: 'kicked', msg: 'An admin set a new password for your account. Log in with it.' }); target.close(true); }
        return c.note('New password set for ' + accountTag(who) + '. Every PC logged in to it now has to log in again.', 0x80ff80);
      }
      case '/discord':
        if (!discord.on) return c.note('No Discord webhook is set. Put "discordWebhook" in server/config.json and restart.');
        discord.post('👋 Test message from ' + desc(c.name) + ' in game.');
        return c.note('Sent a test message to Discord (' + discord.sent + ' sent since the server started).', 0x80ff80);
      case '/stats':
        for (const line of statsLines()) c.note(line, 0x9fe0ff);
        return;
      case '/admins':
        return c.note('Admins: ' + (config.admins.join(', ') || 'none'), 0x80ff80);
      case '/admin': {
        // /admin name: make an account an admin (saved in config.json, so it lasts)
        if (!who) return c.note('Usage: /admin name (also /unadmin name, /admins)');
        if (!accounts[who]) return c.note('No account called ' + parts[1] + '.');
        const name = accounts[who].name || parts[1];
        if (config.admins.some((a) => String(a).toLowerCase() === who)) return c.note(name + ' is already an admin.');
        config.admins = config.admins.concat([name]);
        saveAdmins();
        log(c.name + ' made ' + name + ' an admin');
        if (target) { target.send({ t: 'admin', on: true }); target.note(c.name + ' made you a server admin. Type /help to see the admin commands.', 0x80ff80); }
        return c.note(name + ' is now an admin.', 0x80ff80);
      }
      case '/unadmin': {
        if (!who) return c.note('Usage: /unadmin name');
        if (who === c.key) return c.note('You can\'t remove yourself (ask another admin, or edit server/config.json).');
        const before = config.admins.length;
        config.admins = config.admins.filter((a) => String(a).toLowerCase() !== who);
        if (config.admins.length === before) return c.note(parts[1] + ' is not an admin.');
        saveAdmins();
        log(c.name + ' removed ' + parts[1] + ' from the admins');
        if (target) { target.send({ t: 'admin', on: false }); target.note('You are no longer a server admin.'); }
        return c.note(parts[1] + ' is no longer an admin.', 0x80ff80);
      }
      case '/restart': {
        // /restart 5 (minutes), /restart now, /restart cancel
        const arg = (parts[1] || '5').toLowerCase();
        if (arg === 'cancel') return c.note(cancelRestart() ? 'Restart cancelled.' : 'No restart was coming.', 0x80ff80);
        const mins = arg === 'now' ? 0 : Number(arg);
        if (!(mins >= 0 && mins <= 120)) return c.note('Usage: /restart minutes (0-120), /restart now or /restart cancel');
        scheduleRestart(mins * 60, c.name);
        return c.note('Restarting in ' + mins + ' minute' + (mins === 1 ? '' : 's') + ' (with the latest update).', 0x80ff80);
      }
    }
    c.note('Unknown command.');
  }
};

// ------------------------------------------------------------------ godmode checks
const { godmodeVerdict } = require('./godmode');

// ------------------------------------------------------------------ server health (/stats)
/** NEWREALM_SLOW_LOG=1: log any message that takes the server over 30 ms (for load tests). */
const SLOW_LOG = !!process.env.NEWREALM_SLOW_LOG;
const counters = { startedAt: Date.now(), godmodeFlags: 0, godmodeKicks: 0, savesCut: 0, savesRefused: 0, peak: 0 };
/** How late the event loop runs (ms): a busy server answers everyone late. */
let loopLag = 0, loopLagMax = 0;
{
  let last = Date.now();
  setInterval(() => {
    const now = Date.now(), lag = Math.max(0, now - last - 500);
    last = now;
    loopLag = lag;
    loopLagMax = Math.max(loopLagMax * 0.98, lag);
  }, 500).unref();
}

/** The server's health in a few lines (in game: /stats, admins; console: stats). */
function statsLines() {
  const on = online();
  counters.peak = Math.max(counters.peak, on.length);
  const mem = process.memoryUsage();
  const up = (Date.now() - counters.startedAt) / 1000;
  const lines = [];
  lines.push(on.length + ' online (peak ' + counters.peak + '), up ' + (up > 86400 ? (up / 86400).toFixed(1) + ' days' : (up / 3600).toFixed(1) + ' hours'));
  const where = {};
  for (const c of on) { const w = String(c.world || '-').split(':')[0]; where[w] = (where[w] || 0) + 1; }
  lines.push('Where: ' + (Object.keys(where).map((k) => k + ' ' + where[k]).join(', ') || 'nobody'));
  if (sims) {
    const st = sims.stats();
    lines.push(st.worlds + ' worlds, ' + st.monsters + ' monsters; world tick ' + st.avgMs + ' ms avg, ' + st.p99Ms + ' ms worst 1% (budget 50)');
  }
  lines.push('Memory ' + Math.round(mem.rss / 1048576) + ' MB; event loop late by ' + loopLag + ' ms (recent worst ' + Math.round(loopLagMax) + ')');
  lines.push('Anti-cheat since start: ' + counters.godmodeFlags + ' godmode flags, ' + counters.godmodeKicks + ' kicks (kicking ' + (config.godmodeKick === true ? 'on' : 'off') + '), ' +
    counters.savesCut + ' saves cut back, ' + counters.savesRefused + ' refused');
  return lines;
}

/** Every 10 seconds: compare each player's expected and reported hits since they entered the world (or the last check that settled it). */
function godmodeCheck() {
  for (const c of clients.values()) {
    if (!c.authed || isAdmin(c) || !c.sim) continue;
    const exp = (c.expHits || 0) - (c.expBase || 0), took = (c.hitsRep || 0) - (c.hitsBase || 0);
    const v = godmodeVerdict(exp, took);
    if (v) {
      const note = c.name + ' took ' + took + ' of ' + exp + ' clean monster hits (godmode?)';
      log('godmode ' + note);
      counters.godmodeFlags++;
      store.appendLog('anticheat.log', new Date().toISOString() + ' ' + note);
      if (Date.now() - (c.flaggedAt || 0) > 300000) {
        c.flaggedAt = Date.now();
        for (const a of byName.values()) if (isAdmin(a)) a.note('[Anti-cheat] ' + note, 0xffb040);
      }
      // (kicking is off unless config.json says "godmodeKick": true: until you've seen the log, honest players are only flagged)
      if (v === 'kick' && config.godmodeKick === true) {
        counters.godmodeKicks++;
        c.send({ t: 'kicked', msg: 'Your game ignored hits from monsters, so you were disconnected. If you think this is a mistake, tell an admin.' });
        c.close(true);
        continue;
      }
    }
    // a settled window starts again (so an old good record can't hide new cheating)
    if (exp >= 60 || v) { c.expBase = c.expHits || 0; c.hitsBase = c.hitsRep || 0; }
  }
}
setInterval(godmodeCheck, 10000).unref();

// ------------------------------------------------------------------ movement checks
/** Fastest anyone can move (tiles a second, with every speed boost and some lag), and the most saved up for dashes and blinks. */
const MOVE_SPEED = 20, MOVE_BURST = 14;
/**
 * Where the server runs a world it knows its map (walls included, and every set
 * piece), so a move there must be possible: no faster than anyone can go (dashes
 * and blinks come out of a small allowance), never through a wall in a normal step,
 * and never ending inside a wall. A refused move puts the player back where the
 * server last had them.
 */
function moveAllowed(c, nx, ny) {
  const w = c.sim && c.sim.w;
  if (!w || isAdmin(c)) return true;
  const now = Date.now();
  if (!c.mv) { c.mv = { t: now, budget: MOVE_BURST }; return true; }
  const mv = c.mv;
  mv.budget = Math.min(MOVE_BURST, mv.budget + MOVE_SPEED * Math.min(2, (now - mv.t) / 1000));
  mv.t = now;
  const dx = nx - c.x, dy = ny - c.y, dist = Math.sqrt(dx * dx + dy * dy);
  // a teleport (to a player in the same world) the server handed out
  if (c.tpTo && now < c.tpTo.until && Math.abs(nx - c.tpTo.x) < 3 && Math.abs(ny - c.tpTo.y) < 3) { c.tpTo = null; return true; }
  let why = null;
  if (dist > mv.budget + 0.5) why = 'too fast (' + dist.toFixed(1) + ' tiles)';
  else if (!w.walkable(nx, ny) && w.walkable(c.x, c.y)) why = 'into a wall';
  else if (dist <= 2.5 && w.walkable(c.x, c.y)) {
    // a normal step: every point on the way must be open ground
    const steps = Math.ceil(dist / 0.2);
    for (let k = 1; k < steps && !why; k++) {
      const px = c.x + dx * k / steps, py = c.y + dy * k / steps;
      if (!w.walkable(px, py)) why = 'through a wall' + (process.env.NEWREALM_MOVE_DEBUG ? ' (tile ' + w.tileAt(px, py) + ' obj ' + w.objs[Math.floor(py) * w.N + Math.floor(px)] + ' at ' + px.toFixed(1) + ',' + py.toFixed(1) + ')' : '');
    }
  }
  if (process.env.NEWREALM_MOVE_DEBUG) log('move ' + c.name + ' ' + dist.toFixed(2) + ' budget ' + mv.budget.toFixed(1) + (why ? ' REFUSED ' + why : ''));
  if (!why) { mv.budget -= dist; return true; }
  // back to where the server last had you
  c.send({ t: 'pos', x: Math.round(c.x * 100) / 100, y: Math.round(c.y * 100) / 100 });
  mv.strikes = (now - (mv.strikeT || 0) > 60000 ? 0 : mv.strikes || 0) + 1;
  if (mv.strikes === 1) mv.strikeT = now;
  if (mv.strikes === 15) {
    log('movement refused for ' + c.name + ': ' + why);
    store.appendLog('anticheat.log', new Date().toISOString() + ' ' + c.name + ': 15 impossible moves in a minute (' + why + ') in ' + c.world);
  }
  return false;
}

/** Leaving a world: tell the others, and hand its monsters to someone else if we ran them. */
function leaveWorld(c) {
  const old = c.world;
  if (!old) return;
  c.world = '';
  if (c.sim) { c.sim.leave(c); c.sim = null; }
  const rest = inWorld(old, c);
  for (const o of rest) { o.send({ t: 'leave', id: c.id }); if (o.seen) o.seen.delete(c.id); }
  c.seen = new Set();
  if (hosts.get(old) === c) {
    if (rest.length) {
      const h = rest[0];
      hosts.set(old, h);
      for (const o of rest) o.send({ t: 'host', key: old, id: h.id });
    } else hosts.delete(old);
  }
}

function chatAllowed(c) {
  const now = Date.now();
  if (c.mutedUntil && c.mutedUntil > now) { c.note('You are muted.'); return false; }
  c.chatTimes = (c.chatTimes || []).filter(t => now - t < 10000);
  if (c.chatTimes.length >= config.chatPerTenSeconds) { c.note('Slow down! You are sending messages too fast.'); return false; }
  c.chatTimes.push(now);
  return true;
}

/** The server's copy of a player's current character, or null. */
function serverChar(c) {
  const sv = store.getSave(c.key);
  if (!sv || !c.charId) return null;
  return (sv.chars || []).find(ch => ch && ch.id === c.charId) || null;
}

function serverInv(c) {
  const ch = serverChar(c);
  return ch && Array.isArray(ch.inv) ? ch.inv : null;
}

/** Both accepted: swap the items in the server's copies, then tell both players their new inventories. */
function finishTrade(t) {
  const a = t.a, b = t.b;
  a.trade = b.trade = null;
  const ca = serverChar(a), cb = serverChar(b);
  if (!ca || !cb) {
    a.send({ t: 'tradeCancel', msg: 'The trade failed. Try again.' }); b.send({ t: 'tradeCancel', msg: 'The trade failed. Try again.' });
    return;
  }
  // a save during the trade could have moved items under the offered slots
  if (JSON.stringify(ca.inv) !== t.snapA || JSON.stringify(cb.inv) !== t.snapB) {
    const why = 'An inventory changed during the trade. Please trade again.';
    a.send({ t: 'tradeCancel', msg: why }); b.send({ t: 'tradeCancel', msg: why });
    return;
  }
  const sa = t.sel.get(a) || [], sb = t.sel.get(b) || [];
  const give = (ch, sel) => { const out = []; for (let i = 0; i < ch.inv.length; i++) if (sel[i] && ch.inv[i]) out.push(ch.inv[i]); return out; };
  const ga = give(ca, sa), gb = give(cb, sb);
  const free = (ch, sel) => ch.inv.filter((it, i) => !it || sel[i]).length;
  if (free(ca, sa) < gb.length || free(cb, sb) < ga.length) {
    a.send({ t: 'tradeCancel', msg: 'Not enough inventory space.' }); b.send({ t: 'tradeCancel', msg: 'Not enough inventory space.' });
    return;
  }
  const apply = (ch, sel, incoming) => {
    for (let i = 0; i < ch.inv.length; i++) if (sel[i]) ch.inv[i] = null;
    for (const it of incoming) { const k = ch.inv.indexOf(null); if (k >= 0) ch.inv[k] = it; }
  };
  apply(ca, sa, gb);
  apply(cb, sb, ga);
  const svA = store.getSave(a.key), svB = store.getSave(b.key);
  for (const it of ga) items.transfer(svA, svB, it);
  for (const it of gb) items.transfer(svB, svA, it);
  for (const [cl, ch, gave] of [[a, ca, ga], [b, cb, gb]]) {
    const sv = store.getSave(cl.key);
    sv.tradeSeq = (sv.tradeSeq || 0) + 1;
    // what left this account may not reappear in its next save (a client that ignores the swap)
    const meta = accountMeta.get(cl.key);
    if (meta) {
      meta.tradedOut = (meta.tradedOut || []).filter((e) => Date.now() - e.at < 15 * 60 * 1000);
      // (potions and shards are all alike, so a new one found later can't be told apart: skip those)
      for (const it of gave) if (!['hp', 'mp', 'stat', 'material'].includes(it.kind)) meta.tradedOut.push({ at: Date.now(), item: JSON.stringify(it) });
    }
    store.putSave(cl.key, sv);
    cl.send({ t: 'tradeDone', inv: ch.inv, seq: sv.tradeSeq });
  }
  log('trade', a.name, '(' + ga.length + ') <->', b.name, '(' + gb.length + ')');
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

/** Guild members show their guild's banner (if it flies one) by their name. */
function withBanner(c, p) {
  // (the hero's mode, as the server knows it, shows by the name too)
  if (c.mode) p.md = c.mode; else delete p.md;
  // the account number, so players can name someone exactly in a report
  if (accounts[c.key] && accounts[c.key].no) p.no = accounts[c.key].no;
  const g = guildOf(c);
  if (g && g.banner) p.gb = g.banner; else delete p.gb;
  return p;
}

/** The guild's banner changed (or someone joined or left): everyone sees the members' new look. */
function reshowBanner(gk) {
  for (const o of byName.values()) {
    if (gk && o.guild !== gk) continue;
    if (!o.profile || !o.world) continue;
    withBanner(o, o.profile);
    for (const x of inWorld(o.world, o)) x.send({ t: 'profile', id: o.id, profile: o.profile });
  }
}

function reshowOne(o) {
  if (!o.profile || !o.world) return;
  withBanner(o, o.profile);
  for (const x of inWorld(o.world, o)) x.send({ t: 'profile', id: o.id, profile: o.profile });
}

/** Sends c the Guild Hall (bank, goals, banners, ranking). */
function sendHall(c) {
  const g = guildOf(c);
  if (!g) return c.send({ t: 'hall', hall: null });
  c.send({ t: 'hall', hall: hall.view(g, c.guild, guilds, g.members[c.key].rank) });
}

/** What members did counts toward their guild's weekly goals. */
function guildProgress(c, evs) {
  const g = guildOf(c);
  if (!g) return;
  const done = hall.progress(g, evs);
  if (!done.length) { if (Math.random() < 0.05) save('guilds.json', guilds); return; }
  save('guilds.json', guilds);
  for (const d of done) {
    for (const o of byName.values()) {
      if (o.guild !== c.guild) continue;
      if (d.banner) o.send({ t: 'banner', text: 'New guild banner: ' + d.banner.name + '!', color: d.banner.col, msg: g.name + ' finished all three weekly goals (+' + d.fame + ' guild fame). Leaders can fly it from the Guild Hall.', sfx: 'fanfare' });
      else o.note('Guild goal done: ' + d.text + ' (+' + d.fame + ' guild fame)', 0x80ff80);
    }
    if (d.banner && discord.on) discord.post('🚩 **' + desc(g.name) + '** finished all three weekly guild goals and earned the **' + desc(d.banner.name) + '** banner!', d.banner.col);
  }
  if (done.some((d) => d.banner)) { reshowBanner(c.guild); sendGuild(c.guild); }
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
    o.send({ t: 'guild', guild: { name: g.name, myRank: g.members[o.key].rank, members, banner: g.banner || '' } });
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
    if (line.length > MAX_LINE) return;
    let m;
    try { m = JSON.parse(line); } catch (e) { return; }
    if (!m || typeof m.t !== 'string') return;
    if (line.length > 64 * 1024 && m.t !== 'save') return;
    if (!c.authed && m.t !== 'hello') return;
    // a connection replaced by a newer login may not save over it
    if (c.replaced) return;
    const h = handlers[m.t];
    if (h) {
      const t0 = SLOW_LOG ? Date.now() : 0;
      try { h(c, m); } catch (e) { log('error handling', m.t, e.message); }
      if (SLOW_LOG && Date.now() - t0 > 30) log('slow: ' + m.t + ' took ' + (Date.now() - t0) + ' ms');
    }
  };
  c.onClose = () => {
    try { closeClient(c); } catch (e) { log('error closing', c.name, e.message); }
  };
}

function closeClient(c) {
  {
    if (!clients.has(c.id)) return;
    clients.delete(c.id);
    if (!c.authed) return;
    if (byName.get(c.key) === c) byName.delete(c.key);
    if (c.trade) endTrade(c, c.name + ' left.');
    leaveParty(c, true);
    leaveWorld(c);
    if (c.guild) sendGuild(c.guild);
    store.release(c.key);
    updateRealms();
    log(c.name, 'left (' + byName.size + ' online)');
  };
}

/**
 * Plain web requests on the game port. The launcher downloads the latest game
 * from here (/NewRealm.swf), so players never need a new file after an update:
 * a git pull on the server is enough. Flash also asks for /crossdomain.xml.
 */
const GAME_SWF = process.env.NEWREALM_GAME_SWF || path.join(__dirname, '..', 'bin', 'NewRealm.swf');
/** Which build of the game this server hands out: a player still on an older one is told to reopen the game. */
const GAME_BUILD = (() => {
  try { return require('crypto').createHash('sha1').update(fs.readFileSync(GAME_SWF)).digest('hex').slice(0, 12); } catch (e) { return ''; }
})();
function serveHttp(sock, req) {
  const url = (/^GET\s+(\S+)/.exec(req) || [])[1] || '/';
  const pathOnly = url.split('?')[0];
  const head = (type, len) => 'HTTP/1.1 200 OK\r\nContent-Type: ' + type + '\r\nContent-Length: ' + len +
    '\r\nCache-Control: no-cache\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n';
  if (pathOnly === '/NewRealm.swf') {
    fs.readFile(GAME_SWF, (err, data) => {
      if (err) { sock.end('HTTP/1.1 404 Not Found\r\nConnection: close\r\nContent-Length: 0\r\n\r\n'); return; }
      sock.write(head('application/x-shockwave-flash', data.length));
      sock.end(data);
    });
    return;
  }
  // the VPS itself (restart.sh) can start or cancel a restart countdown
  if (pathOnly === '/restart') {
    const local = /^(::ffff:)?127\.0\.0\.1$|^::1$/.test(String(sock.remoteAddress || ''));
    let msg;
    if (!local) msg = 'Only the server itself can do that.\n';
    else {
      const m = (/[?&]m=([^&]+)/.exec(url) || [])[1] || '5';
      if (m === 'cancel') msg = cancelRestart() ? 'Restart cancelled.\n' : 'No restart was coming.\n';
      else {
        const mins = m === 'now' ? 0 : Number(m);
        if (!(mins >= 0 && mins <= 120)) msg = 'Minutes must be 0-120, now or cancel.\n';
        else { scheduleRestart(Math.round(mins * 60), 'the server console'); msg = 'Restarting in ' + mins + ' minute(s): players are being warned. It will pull the latest update first.\n'; }
      }
    }
    sock.end(head('text/plain', Buffer.byteLength(msg)) + msg);
    return;
  }
  // the VPS itself can read the server's health (curl http://127.0.0.1:PORT/stats)
  if (pathOnly === '/stats') {
    const local = /^(::ffff:)?127\.0\.0\.1$|^::1$/.test(String(sock.remoteAddress || ''));
    const txt = local ? statsLines().join('\n') + '\n' : 'Only the server itself can do that.\n';
    sock.end(head('text/plain', Buffer.byteLength(txt)) + txt);
    return;
  }
  if (pathOnly === '/crossdomain.xml') {
    const xml = '<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*"/></cross-domain-policy>';
    sock.end(head('text/x-cross-domain-policy', Buffer.byteLength(xml)) + xml);
    return;
  }
  // the website: the landing page, browser play, and the files they use
  const siteInfo = () => {
    const top = ladder.ranked()[0];
    return { name: str(config.name, 32) || 'Eldmere', online: byName.size, discord: str(config.discordInvite, 200),
      season: { name: ladder.current.name, leader: top ? top.name : '' }, launcher: site.hasLauncher() };
  };
  if (pathOnly === '/' || pathOnly === '/index.html' || pathOnly === '/play') {
    const html = pathOnly === '/play' ? site.play(siteInfo()) : site.landing(siteInfo());
    sock.end(head('text/html; charset=utf-8', Buffer.byteLength(html)) + html);
    return;
  }
  const f = site.file(pathOnly);
  if (f) {
    fs.readFile(f[0], (err, data) => {
      if (err) { sock.end('HTTP/1.1 404 Not Found\r\nConnection: close\r\nContent-Length: 0\r\n\r\n'); return; }
      sock.write(head(f[1], data.length));
      sock.end(data);
    });
    return;
  }
  sock.end('HTTP/1.1 404 Not Found\r\nConnection: close\r\nContent-Length: 0\r\n\r\n');
}

const POLICY = '<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>\0';

const server = net.createServer((sock) => {
  sock.setNoDelay(true);
  const c = { id: nextId++, authed: false, world: '', x: 0, y: 0, profile: {}, party: 0, ip: String(sock.remoteAddress || '') };
  let mode = null; // 'tcp' | 'ws' | 'http'
  let buf = Buffer.alloc(0);
  let text = '';
  const decoder = new StringDecoder('utf8');

  const lines = (chunk) => {
    text += chunk;
    let i;
    while ((i = text.indexOf('\n')) >= 0) {
      const line = text.slice(0, i);
      text = text.slice(i + 1);
      c.onLine(line.trim());
    }
    if (text.length > MAX_LINE * 2) sock.destroy();
  };

  c.send = (obj) => {
    if (sock.destroyed) return;
    // a client that stops reading would make us hold its messages forever
    if (sock.writableLength > 4 * 1024 * 1024) return sock.destroy();
    const data = Buffer.from(JSON.stringify(obj) + '\n', 'utf8');
    if (mode === 'ws') sock.write(wsFrame(data));
    else sock.write(data);
  };
  c.close = (hard) => { if (hard) sock.destroy(); else sock.end(); };
  attach(c);

  sock.on('data', (chunk) => {
    if (mode === 'http') return;
    buf = Buffer.concat([buf, chunk]);
    // never buffer more than one message's worth (a fake frame length or an endless header)
    if (buf.length > MAX_LINE * 2 + 16 || (!mode && buf.length > 16384)) return sock.destroy();
    if (!mode) {
      const head = buf.toString('latin1', 0, Math.min(buf.length, 23));
      if (head.startsWith('<policy-file-request/>')) { sock.end(POLICY); return; }
      if (head.startsWith('GET ')) {
        const end = buf.indexOf('\r\n\r\n');
        if (end < 0) return;
        const req = buf.toString('latin1', 0, end);
        const keyM = /Sec-WebSocket-Key:\s*(.+)/i.exec(req);
        if (!keyM) { mode = 'http'; serveHttp(sock, req); return; }
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
      lines(decoder.write(buf));
      buf = Buffer.alloc(0);
      return;
    }
    // websocket frames
    while (buf.length >= 2) {
      const op = buf[0] & 0x0f;
      let len = buf[1] & 0x7f, off = 2;
      if (len === 126) { if (buf.length < 4) return; len = buf.readUInt16BE(2); off = 4; }
      else if (len === 127) { if (buf.length < 10) return; len = Number(buf.readBigUInt64BE(2)); off = 10; }
      if (len > MAX_LINE) return sock.destroy();
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

/** Tells the Discord about the Vault's twist when a new week starts (and once each start-up). */
let twistWeek = -1;
function announceTwist() {
  const week = Math.floor((Math.floor(Date.now() / 86400000) + 3) / 7);
  if (week === twistWeek) return;
  twistWeek = week;
  const tw = Bosses.vaultTwist(week);
  feat('twist', { name: tw.name, desc: tw.desc });
}
setInterval(announceTwist, 10 * 60 * 1000).unref();

server.listen(PORT, () => {
  log('New Realm server running on port ' + PORT);
  discord.post('🟢 **' + desc(config.name || 'Eldmere') + '** is online. Come and play!', 0x60e070);
  announceTwist();
  seasonTick();
  statusTick();
  if (config.backups !== false) backup.start(DATA_DIR, () => store.flushAll(), log, Number(config.backupKeep) || 14);
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
  for (const [ip, f] of failedLogins) if (now - f.t > 5 * 60 * 1000) failedLogins.delete(ip);
}, 1000);

// ------------------------------------------------------------------ console
const HELP = 'Commands: list | stats | worlds | say <message> | kick <name> | ban <name> [hours] [reason] | unban <name> | whois <name|#n> | setpassword <name|#n> <password> | realms (new realms) | stop';
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
      case 'stats':
        for (const line of statsLines()) console.log(line);
        break;
      case 'worlds': {
        if (!sims) { console.log('Server monsters are off (config serverMonsters: false).'); break; }
        const st = sims.stats();
        console.log(st.worlds + ' worlds running, ' + st.monsters + ' monsters, last tick ' + st.tickMs + ' ms');
        for (const [key, sm] of sims.map) console.log('  ' + key + ': ' + sm.players.size + ' players, ' + sm.enemies.length + ' monsters');
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
      case 'ban': {
        const [who, hrs, ...why] = rest;
        const k = (who || '').toLowerCase();
        if (!accounts[k]) { console.log('No account called ' + who + '.'); break; }
        const h = parseFloat(hrs);
        bans[k] = { until: isNaN(h) ? 0 : Date.now() + h * 3600000, reason: (isNaN(h) ? [hrs].concat(why) : why).filter(Boolean).join(' '), by: 'console' };
        save('bans.json', bans);
        const on = byName.get(k);
        if (on) { on.send({ t: 'kicked', msg: 'You were banned.' }); on.close(true); }
        log('banned ' + who);
        break;
      }
      case 'whois': {
        const k = accountKey(rest[0]);
        if (!k) { console.log('No account called ' + rest[0] + '.'); break; }
        for (const line of whoisLines(k)) console.log(line);
        break;
      }
      case 'setpassword': {
        // (from the VPS itself: for when the owner is locked out too)
        const k = accountKey(rest[0]), pw = rest[1] || '';
        if (!k || pw.length < 4) { console.log('Usage: setpassword <name|#n> <password of 4+ characters>'); break; }
        setPassword(accounts[k], pw);
        accounts[k].sessions = [];
        save('accounts.json', accounts);
        const on = byName.get(k);
        if (on) { on.send({ t: 'kicked', msg: 'Your password was changed. Log in with the new one.' }); on.close(true); }
        log('set a new password for ' + accountTag(k));
        break;
      }
      case 'unban':
        delete bans[arg.toLowerCase()];
        save('bans.json', bans);
        log('unbanned ' + arg);
        break;
      case 'realms':
        rollRealms();
        lastRealmJson = '';
        updateRealms();
        log('New realms: ' + realms.map(r => r.name).join(', ') + ' (players get them when they next log in)');
        break;
      case 'stop': case 'exit': case 'quit':
        broadcast('[Server] The server is shutting down.', 0xff8080);
        shutdown();
        break;
      default: console.log('Unknown command. ' + HELP);
    }
  }
});

// ------------------------------------------------------------------ restart countdown
/**
 * A restart with a warning: everyone sees a countdown, realm events stop starting in
 * the last two minutes, and at zero the server pulls the latest update (git pull) and
 * stops; systemd (Restart=always) starts it again on the new code. Started by an admin
 * (/restart 5) or from the VPS itself (restart.sh, or http://127.0.0.1:PORT/restart?m=5).
 */
let restartAt = 0, restartTimer = null, restartTick = null;
const restartLeft = () => restartAt ? Math.max(0, Math.ceil((restartAt - Date.now()) / 1000)) : -1;
function scheduleRestart(seconds, by) {
  cancelRestart(true);
  restartAt = Date.now() + seconds * 1000;
  log('Restart in ' + seconds + 's' + (by ? ' (by ' + by + ')' : ''));
  if (discord.on) discord.post(seconds >= 60 ? '🔄 The server restarts for an update in **' + Math.round(seconds / 60) + ' minute' + (Math.round(seconds / 60) === 1 ? '' : 's') + '**.' : '🔄 The server is restarting for an update now.', 0x80a0ff);
  const tell = () => { for (const c of clients.values()) if (c.authed) c.send({ t: 'restartIn', s: restartLeft() }); };
  tell();
  // keep everyone's clocks right, and stop new events near the end
  restartTick = setInterval(() => {
    const left = restartLeft();
    WorldSim.restartSoon = left <= 120;
    if (left % 60 === 0 || left === 30 || left === 10) tell();
  }, 1000);
  WorldSim.restartSoon = seconds <= 120;
  restartTimer = setTimeout(() => { restartTimer = null; updateAndStop(); }, seconds * 1000);
}
function cancelRestart(quiet) {
  if (!restartAt) return false;
  clearTimeout(restartTimer); clearInterval(restartTick);
  restartAt = 0; restartTimer = restartTick = null;
  WorldSim.restartSoon = false;
  if (!quiet) { log('Restart cancelled'); discord.post('The restart was called off.', 0x80a0ff); for (const c of clients.values()) if (c.authed) c.send({ t: 'restartIn', s: -1 }); }
  return true;
}
/** Gets the latest update (when the server runs from a git checkout), then stops for systemd to start it again. */
function updateAndStop() {
  try {
    const out = require('child_process').execFileSync('git', ['pull', '--ff-only'], { cwd: path.join(__dirname, '..'), timeout: 60000, stdio: ['ignore', 'pipe', 'pipe'] });
    log('git pull: ' + String(out).trim().split('\n').pop());
  } catch (e) {
    log('git pull failed (restarting on the code already here): ' + String(e.stderr || e.message).trim().split('\n')[0]);
  }
  shutdown();
}

let shuttingDown = false;
/** Stopping (an update or restart): everyone is told and sends their save, then it's all written and the server exits. */
function shutdown() {
  if (shuttingDown) return;
  shuttingDown = true;
  log('Restarting: telling players, saving and shutting down...');
  for (const c of clients.values()) if (c.authed) c.send({ t: 'restart' });
  setTimeout(() => {
    store.flushAll();
    setTimeout(() => process.exit(0), 300);
  }, 1500);
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
setInterval(updateRealms, 5000);
