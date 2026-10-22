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
const progress = require('./progress');
const combat = require('./combat');
const { Data, Bosses, World, Uniques } = require('./sim/gen/game');
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
  // how many realms are open: minRealms always, up to maxRealms as they fill (admins: /realms n)
  minRealms: 1,
  maxRealms: 1,
  admins: [],
  // a Discord webhook address: records, raid clears, Godly drops, titles and restarts are posted there
  discordWebhook: '',
  // a Discord bot for /restart and /status from Discord (DEPLOY.md): its token, your Discord server's ID, and who may use it
  discordBotToken: '',
  discordGuild: '',
  discordBotAdmins: [],
  // channel IDs the bot keeps a log of (e.g. #mod-chat), and the key for reading it at /discordlog (DEPLOY.md)
  discordReadChannels: [],
  // a webhook in a Discord Forum channel: every /bug report becomes a post of its own there
  discordBugForum: '',
  discordLogKey: '',
  viewRange: 32,
  chatPerTenSeconds: 8,
  // true: click anyone on the minimap (or /tp name) to teleport to them, like RotMG; false: party and guild only
  teleportToAnyone: true
};
let config = Object.assign({}, DEFAULT_CONFIG);
try { Object.assign(config, JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'))); }
catch (e) { try { fs.writeFileSync(CONFIG_FILE, JSON.stringify(DEFAULT_CONFIG, null, 2)); } catch (e2) {} }
// one realm for now (an older config.json still says 3 to 6): once, then /realms changes it
if (!config.realmsSet) {
  config.minRealms = 1; config.maxRealms = 1; config.realmsSet = true;
  try { const f = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8')); Object.assign(f, { minRealms: 1, maxRealms: 1, realmsSet: true }); fs.writeFileSync(CONFIG_FILE, JSON.stringify(f, null, 2)); } catch (e) {}
}
/**
 * Roles, from most to least: the owner (config "owner", else the first admin: everything,
 * including making admins), admins (everything else), moderators (config "mods": kick,
 * mute, short bans, /whois, /flags, /bugs, /graves), testers (config "testers": the admin
 * menu's levelling, items and dungeons for themselves, but no moderation, and nothing they
 * make can leave them: no trading, Marketplace, guild bank, Group Storage, selling or
 * dropping) and VIPs (vips.json, often for a while: /l20, /backpack, a little more loot
 * luck and a badge).
 */
const lcName = (a) => String(a).toLowerCase();
// (config "owner"; else account #1 if it's an admin; else the first admin)
// (worked out again only when the owner or admin list changes: it's asked on every move)
let ownerCache = { sig: null, key: '' };
function ownerKey() {
  if (config.owner) return lcName(config.owner);
  const sig = config.admins.join('\n');
  if (ownerCache.sig === sig) return ownerCache.key;
  let key = lcName(config.admins[0] || '');
  if (typeof accounts !== 'undefined') for (const k in accounts) if (Number(accounts[k].no) === 1 && config.admins.some((a) => lcName(a) === k)) { key = k; break; }
  ownerCache = { sig, key };
  return key;
}
// (the fallback owner is always one of the admins, so only a configured owner needs its own check)
const isAdmin = (c) => !!c.key && (config.admins.some(a => lcName(a) === c.key) || (!!config.owner && c.key === lcName(config.owner)));
const isMod = (c) => isAdmin(c) || (Array.isArray(config.mods) && config.mods.some(a => lcName(a) === c.key));
/** A tester (not an admin): the admin menu's testing tools for themselves only. */
const isTester = (c) => !!c.key && !isAdmin(c) && Array.isArray(config.testers) && config.testers.some(a => lcName(a) === c.key);
/** Admins and testers: their own saves may hold items, levels and stats the admin menu made. */
const canTest = (c) => isAdmin(c) || isTester(c);
/** Why a tester can't do this (their items can't reach anyone else), or ''. */
const testerBlock = (c, what) => (isTester(c) ? 'Testers can\'t ' + what + ': what the admin menu makes stays with you.' : '');
/** Writes the admin list back to config.json (keeping everything else in the file as it is). */
function saveAdmins() { return saveConfig(['admins']); }
/** Writes these settings back to config.json (keeping everything else in the file as it is). */
function saveConfig(keys) {
  let file = {};
  try { file = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8')); } catch (e) { file = Object.assign({}, DEFAULT_CONFIG); }
  for (const k of keys) file[k] = config[k];
  try { fs.writeFileSync(CONFIG_FILE, JSON.stringify(file, null, 2)); return true; } catch (e) { log('could not save config.json: ' + e.message); return false; }
}

const PORT = parseInt(process.argv[2] || process.env.PORT || config.port || '2050', 10);
/** Bump when the game and server stop understanding each other. */
const VERSION = 12;
const IDLE_KICK_MS = 45000;
const MAX_MSGS_PER_SEC = 250;
const MAX_LINE = 1536 * 1024;
const DATA_DIR = process.env.NEWREALM_DATA || path.join(__dirname, 'data');
const PARTY_MAX = 6;
/** Pets the Stable holds (besides the one with you). */
const PET_STABLE = 6;
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
if (sims) sims.issuer = (c, it) => { const sv = onlineSave(c.key); items.issue(sv, it, modes.modeOf(serverChar(c))); store.putSave(c.key, sv); };
const oracle = require('./oracle');
if (sims) sims.onOracle = (c, e, got) => {
  if (!c.key) return;
  const sv = onlineSave(c.key);
  // (the Abyss's chests hold the Herald's uniques: they count toward its collection, not as kills)
  if (e.def.abyssChest) oracle.record(sv, 'abyss_herald', Data.ENEMIES.abyss_herald.name, got, 0, true);
  else oracle.record(sv, e.defId, e.def.name, got);
  // a boss's collection finished: its title, and +1 to a stat for every hero
  const fresh = oracle.completions(sv);
  store.putSave(c.key, sv);
  if (!fresh.length) return;
  for (const id of fresh) {
    const st = Data.oracleStat(id);
    grantTitle(c.key, 'oracle_' + id);
    c.send({ t: 'oracleDone', id, done: sv.oracleDone, stat: st });
    feat('oracle', { name: c.name, boss: Data.ENEMIES[id].name });
  }
  if (sv.oracleDone.length >= 5) grantTitle(c.key, 'oracle5');
  if (sv.oracleDone.length >= oracle.collectionCount()) grantTitle(c.key, 'oracleall');
  setCaps(c);
};
// the Realm Siege: everyone who fought is a Realm Defender; the top damage dealer earns Siegebreaker
if (sims) sims.onSiege = (sim, kind, d) => {
  const realm = sim.key.split(':').slice(1, -1).join(':') || 'the realm';
  if (kind === 'fail') {
    broadcast('' + d.name + ' has withdrawn from ' + realm + '. The siege was not broken this time.', 0xd09060);
    feat('siege', { won: false, realm });
    return;
  }
  const team = d.team || [];
  for (const r of team) if (r.pct >= 0.5) grantTitle(r.c.key, 'siegeguard');
  if (team.length) grantTitle(team[0].c.key, 'siege');
  const mvp = team[0];
  broadcast('' + d.name + ' has fallen in ' + realm + '! ' + team.length + ' defender' + (team.length === 1 ? '' : 's') + (mvp ? '. MVP: ' + mvp.c.name + ' (' + mvp.pct + '% of the damage)' : '') + '.', 0xffa020);
  log('siege won in ' + realm + ' by ' + team.map((r) => r.c.name + ' ' + r.pct + '%').join(', '));
  feat('siege', { won: true, realm, names: team.map((r) => r.c.name), mvp: mvp ? mvp.c.name : '', pct: mvp ? mvp.pct : 0 });
};
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
  // the Realm Leaders race: the boss counts once for every guild whose members fought it
  leaderEvents(leaders.kill(team.map((c) => c.guild && guilds[c.guild] ? c.guild : '')));
  for (const gk of new Set(team.map((c) => c.guild).filter(Boolean))) for (const o of byName.values()) if (o.guild === gk) sendLeaders(o);
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
  c.vip = isVip(c);
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
    save: publicSave(onlineSave(key)), motd: config.motd, serverMonsters: !!sims, admin: isAdmin(c), tester: isTester(c), role: roleOf(c), vip: isVip(c), session, needPassword: !acc.pwHash, build: GAME_BUILD, restartIn: restartLeft(), season: ladder.current, tpAny: !!config.teleportToAnyone });
  sendRaidState(c);
  if (Object.keys(itemArt).length) c.send({ t: 'itemArt', art: itemArt, all: true });
  sendGuild(c.guild);
  c.send({ t: 'quests', q: quests.view(onlineSave(key)) });
  sendLeaders(c);
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
    if (r && !id.startsWith('vault:') && !id.startsWith('rb:') && (!rec || r.at > rec.r.at)) rec = { id, r };
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
  const t = Data.findTitle(id) || Data.findDye(id) || Data.findPetSkin(id);
  if (!key || !t || !t.earn) return false;
  const sv = onlineSave(key);
  if (!sv._titles || typeof sv._titles !== 'object') sv._titles = {};
  if (sv._titles[id]) return false;
  sv._titles[id] = Date.now();
  store.putSave(key, sv);
  feat('title', { name: (accounts[key] && accounts[key].name) || key, title: t.name + (Data.findDye(id) ? ' dye' : Data.findPetSkin(id) ? ' pet skin' : ''), color: t.col });
  const c = byName.get(key);
  if (c) {
    c.send({ t: 'title', id, earned: Object.keys(sv._titles) });
    const kind = Data.findDye(id) ? 'Dye' : Data.findPetSkin(id) ? 'Pet skin' : 'Title';
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
  if (evs.includes('raid:conclave')) grantTitle(c.key, 'conclave');
  if (evs.includes('raid:storm')) grantTitle(c.key, 'storm');
  // Heroic: any raid, then all three (kept in the save: sv.heroics = {raid id: true})
  const hid = evs.find((v) => v.startsWith('raidh:'));
  if (hid) {
    grantTitle(c.key, 'heroic');
    const hs = onlineSave(c.key);
    if (hs) {
      hs.heroics = Object.assign({}, hs.heroics, { [hid.slice(6)]: true });
      if (Bosses.RAIDS.map((r) => r.id).every((id) => hs.heroics[id])) grantTitle(c.key, 'heroic_all');
      store.putSave(c.key, hs);
    }
  }
  const sv = onlineSave(c.key);
  const done = quests.progress(sv, evs);
  if (done === null) return;
  store.putSave(c.key, sv);
  c.send({ t: 'quests', q: quests.view(sv) });
  for (const text of done) c.send({ t: 'questComplete', text: text + ' Claim it at the Quest Board in the Nexus.' });
}
if (sims) sims.onQuest = questProgress;
/**
 * Dungeons and raids open behind portals: ones the server's monsters drop, and ones opened
 * with a key the server saw used (handlers.portalKey). Their worlds can be entered while the
 * portal is up (and a little after), or while anyone is still inside: world key -> until (ms).
 */
const openWorlds = new Map();
const PORTAL_MS = 90 * 1000;
function openWorld(key) {
  openWorlds.set(key, Date.now() + PORTAL_MS);
  if (openWorlds.size > 2000) { const now = Date.now(); for (const [k, t] of openWorlds) if (t < now) openWorlds.delete(k); }
}
/**
 * One raid at a time, server-wide: while a raid's portal is open in the Nexus (30 seconds),
 * and then while anyone is still fighting in a raid that isn't finished, no other raid opens.
 */
const RAID_PORTAL_MS = 30 * 1000;
let raidLock = null; // {key, name, color, until, by}
function raidNameOf(key) { const p = String(key).split(':'); return Bosses.raidName(Number(p[1]) | 0, p[3] === 'h'); }
/** Why no raid can be opened right now, or ''. */
function raidBusy() {
  const now = Date.now();
  if (raidLock && raidLock.until > now) return raidLock.name + '\'s portal is open in the Nexus (' + Math.ceil((raidLock.until - now) / 1000) + 's left to get in). Raids open one at a time.';
  const inside = new Map();
  for (const o of clients.values()) {
    if (!o.authed || !String(o.world || '').startsWith('raid:')) continue;
    // (a cleared raid doesn't hold the next one back)
    const sm = sims && sims.get(o.world), rd = Bosses.RAIDS[Number(String(o.world).split(':')[1]) | 0];
    if (sm && sm.w && rd && sm.w.raidStage >= rd.stages.length) continue;
    inside.set(o.world, (inside.get(o.world) || 0) + 1);
  }
  for (const [k, n] of inside) return raidNameOf(k) + ' is under way (' + n + ' player' + (n === 1 ? '' : 's') + ' inside). Raids open one at a time: wait for it to end.';
  return '';
}
/** Tells every game whether a raid can be opened (the Raid Table shows it). */
function sendRaidState(to) {
  const busy = raidBusy();
  const msg = { t: 'raidState', busy: busy || '', name: raidLock && raidLock.until > Date.now() ? raidLock.name : '', left: raidLock ? Math.max(0, Math.ceil((raidLock.until - Date.now()) / 1000)) : 0 };
  if (to) return to.send(msg);
  for (const o of clients.values()) if (o.authed) o.send(msg);
}
// (whenever that changes, every game hears: a raid ending frees the Raid Table)
let raidStateWas = '';
setInterval(() => { const b = raidBusy(); if (b.replace(/\(\d+s left/, '(') !== raidStateWas) { raidStateWas = b.replace(/\(\d+s left/, '('); sendRaidState(); } }, 5000).unref();
/** A raid is open: its portal by the Raid Table for everyone in the Nexus, and the news for the whole server. */
function announceRaid(c, wkey, i, seed, heroic) {
  const rd = Bosses.RAIDS[i];
  const name = raidNameOf(wkey), color = heroic ? 0xffb040 : (rd ? rd.color : 0xff3050);
  raidLock = { key: wkey, name, color, until: Date.now() + RAID_PORTAL_MS, by: c.name };
  const pi = heroic ? 100 + i : i; // (Game.RAID_HEROIC + the raid)
  const portal = { t: 'w', from: 0, d: { t: 'portal', x: 113.5, y: 107.5, k: 'raid', i: pi, c: color, l: RAID_PORTAL_MS / 1000, s: seed, by: c.name } };
  for (const o of clients.values()) {
    if (!o.authed) continue;
    if (o.world === 'nexus') o.send(portal);
    o.send({ t: 'raidOpened', name, color, by: c.name, heroic: !!heroic, secs: RAID_PORTAL_MS / 1000, here: o.world === 'nexus' });
  }
  log(c.name + ' opened ' + name);
  feat('raidopen', { name: c.name, raid: name, heroic: !!heroic });
  sendRaidState();
  setTimeout(sendRaidState, RAID_PORTAL_MS + 500).unref();
}
/** May c go into world (from the world it was in)? Admins go anywhere. */
function mayEnter(c, world, from) {
  if (!sims || canTest(c)) return true;
  const kind = world.split(':')[0];
  // the Endless Abyss: level 20 heroes only
  if (kind === 'deep') { const ch = serverChar(c); return !!(ch && Number(ch.level) >= 20); }
  if (kind !== 'dg' && kind !== 'raid' && kind !== 'arena') return true;
  // someone is in there now (a party member followed with /join, a reconnect)
  const sm = sims.get(world);
  if (sm && sm.players && sm.players.size > 0) return true;
  if (kind === 'arena') {
    // the Elder's chamber: from the Citadel (or the realm) it belongs to
    const seed = world.slice(6);
    const f = (from || '').split(':');
    return seed.charAt(0) === 'r' ? f[0] === 'realm' && f[f.length - 1] === seed.slice(1) : f[0] === 'dg' && f[2] === seed;
  }
  return (openWorlds.get(world) || 0) > Date.now();
}
if (sims) sims.onPortal = openWorld;
if (sims) sims.onFeat = (k, d) => {
  if (k === 'raid' && d.week !== undefined && d.ms > 0) {
    if (d.twist && !d.heroic) vaultCleared(d);
    raidCleared(d);
  }
  feat(k, d);
};
/**
 * The first clear of each raid each week, on each difficulty (raid id, plus ':h' for
 * Heroic), for each account: sv.raidWeek = {week, done: {id: true}}. True (and marked)
 * the first time; the raid's final boss then rolls its loot again (worldsim dropLoot).
 */
if (sims) sims.firstClear = (c, id, week) => {
  if (!c || !c.key || !c.authed) return false;
  const sv = onlineSave(c.key);
  if (!sv) return false;
  if (!sv.raidWeek || sv.raidWeek.week !== week) sv.raidWeek = { week, done: {} };
  if (sv.raidWeek.done[id]) return false;
  sv.raidWeek.done[id] = true;
  store.putSave(c.key, sv);
  return true;
};

/**
 * Every raid's weekly boards, one per difficulty: records['rb:<raid id>[h]:<week>'], fastest
 * clears first (from the first stage's start to the last boss's fall). The week's fastest
 * team earns Raid Record Holder.
 */
function raidCleared(d) {
  const team = (d.team || []).filter((c) => c && c.key);
  const names = team.map((c) => c.name).filter(Boolean).slice(0, 8);
  if (!names.length || d.ms < 1000 || !d.id) return;
  const key = 'rb:' + d.id + (d.heroic ? 'h' : '') + ':' + d.week;
  const list = records[key] || (records[key] = []);
  const entry = { ms: d.ms, names, at: Date.now() };
  list.push(entry);
  list.sort((a, b) => a.ms - b.ms);
  list.length = Math.min(list.length, RECORDS_KEPT);
  const at = list.indexOf(entry);
  for (const k of Object.keys(records)) if (k.startsWith('rb:') && Number(k.split(':').pop()) < d.week - 8) delete records[k];
  save('records.json', records);
  const nm = (d.heroic ? 'Heroic ' : '') + d.raid;
  for (const c of team) {
    c.send({ t: 'msg', color: 0xffd75e, text: nm + ' cleared in ' + clock(d.ms) + (at >= 0 ? ': #' + (at + 1) + " on this week's board!" : '. The best this week is ' + clock(list[0].ms) + '.') });
    if (at === 0) grantTitle(c.key, 'raidrecord');
  }
  if (at === 0) feat('raidrecord', { names, time: clock(d.ms), raid: nm });
}

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
if (sims) sims.onEarn = (c, e, near) => { if (c.authed && c.key && c.meta) wallet.credit(c.meta, onlineSave(c.key), c.charId, e, Date.now(), near, leaders.xp(c.guild)); };

// ------------------------------------------------------------------ player marketplace
const market = new Market(load, save);
// (tiered weapons listed before signature shots: brought up to their tier's shot, once)
{
  let up = false;
  for (const l of market.data.list) if (l && items.upgradeHeld(l.item, l.entry)) up = true;
  if (up) market.persist();
}
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
const isOwner = (c) => ownerKey() === c.key;
/** vips[key] = {until: 0 (for good) or ms, by, at}. */
const vips = load('vips.json', {});
function isVipKey(key) { const v = vips[key]; return !!v && (!v.until || v.until > Date.now()); }
const isVip = (c) => isVipKey(c.key);
/** owner, admin, mod, tester, vip or '' (shown as a badge in chat). */
const roleOf = (c) => isOwner(c) ? 'owner' : isAdmin(c) ? 'admin' : isMod(c) ? 'mod' : isTester(c) ? 'tester' : isVip(c) ? 'vip' : '';
/** The most loot luck VIP adds (WorldSim.dropLoot). */
const VIP_LUCK = 15;
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
/**
 * Gives account `key` the name `name`: its key, save, guild membership, ban, admin rights,
 * Marketplace listings and season ladder entry all move with it. A player on it is logged out
 * (they log in again with the new name and the same password).
 */
function renameAccount(key, name) {
  const nk = name.toLowerCase();
  const on = byName.get(key);
  if (on) { on.send({ t: 'kicked', msg: 'An admin changed your account name to ' + name + '. Log in with the new name (same password).' }); on.close(true); }
  const acc = accounts[key];
  acc.name = name;
  if (nk !== key) {
    delete accounts[key];
    accounts[nk] = acc;
    // nobody stays logged in under the old name on any PC
    acc.sessions = [];
    store.renameSave(key, nk);
    if (bans[key]) { bans[nk] = bans[key]; delete bans[key]; save('bans.json', bans); }
    if (accountMeta.has(key)) { accountMeta.set(nk, accountMeta.get(key)); accountMeta.delete(key); }
    if (flags[key]) { flags[nk] = flags[key]; flags[nk].name = name; delete flags[key]; store.saveTable('flags.json', flags); }
    const sc = ladder.t && ladder.t.scores;
    if (sc && sc[key]) { sc[nk] = sc[key]; delete sc[key]; }
  }
  save('accounts.json', accounts);
  // (and in a Group Ironman group)
  const gim = groupsMod.groupOf(groupsT, key);
  if (gim) {
    const g = gim[1];
    delete g.members[key];
    g.members[nk] = name;
    if (g.leader === key) g.leader = nk;
    save('groups.json', groupsT);
  }
  for (const gk in guilds) {
    const g = guilds[gk];
    if (!g.members[key]) continue;
    const m = g.members[key];
    m.name = name;
    if (nk !== key) { g.members[nk] = m; delete g.members[key]; }
    save('guilds.json', guilds);
  }
  for (const l of market.data.list) if (l.seller === key) { l.seller = nk; l.sellerName = name; }
  market.persist();
  if (ladder.t && ladder.t.scores && ladder.t.scores[nk]) { ladder.t.scores[nk].name = name; ladder.save(); }
  if (config.admins.some((a) => String(a).toLowerCase() === key)) {
    config.admins = config.admins.map((a) => (String(a).toLowerCase() === key ? name : a));
    saveAdmins();
  }
  // the owner, moderator, tester and VIP roles go with the account (nobody can take them by registering the old name)
  const roles = [];
  if (config.owner && String(config.owner).toLowerCase() === key) { config.owner = name; roles.push('owner'); }
  if (Array.isArray(config.mods) && config.mods.some((a) => String(a).toLowerCase() === key)) {
    config.mods = config.mods.map((a) => (String(a).toLowerCase() === key ? name : a));
    roles.push('mods');
  }
  if (Array.isArray(config.testers) && config.testers.some((a) => String(a).toLowerCase() === key)) {
    config.testers = config.testers.map((a) => (String(a).toLowerCase() === key ? name : a));
    roles.push('testers');
  }
  if (roles.length) saveConfig(roles);
  if (nk !== key && vips[key]) { vips[nk] = vips[key]; delete vips[key]; save('vips.json', vips); }
}

function c2g(key) { for (const gk in guilds) if (guilds[gk].members[key]) return guilds[gk].name || gk; return ''; }
/** guilds[lowername] = {name, members: {lowername: {name, rank, cls, level, fame}}} */
const guilds = load('guilds.json', {});
// (and those in guild banks)
{
  let up = false;
  for (const gk in guilds) for (const b of (guilds[gk] && guilds[gk].bank) || []) if (b && items.upgradeHeld(b.item, b.entry)) up = true;
  if (up) save('guilds.json', guilds);
}
/** Group Ironman groups (groups.js): groupsT[lowername] = {name, leader, members: {key: name}, bank, log} */
const groupsMod = require('./groups');
const groupsT = load('groups.json', {});
{
  let up = false;
  for (const id in groupsT) for (const b of (groupsT[id] && groupsT[id].bank) || []) if (b && items.upgradeHeld(b.item, b.entry)) up = true;
  if (up) save('groups.json', groupsT);
}
/** Group invites waiting for an answer: account key -> {id, from, at}. */
const groupInvites = new Map();
/** The Group Ironman group an account is in, or null. */
function gimOf(c) { const f = groupsMod.groupOf(groupsT, c.key); return f ? f[1] : null; }
/** Whether an account still has a Group Ironman hero alive. */
function hasGimHero(key) { const sv = store.getSave(key); return !!(sv && Array.isArray(sv.chars) && sv.chars.some((h) => h && typeof h === 'object' && modes.modeOf(h) === 'group')); }
/** Two players' heroes can trade: both regular, or both Group Ironman heroes of the same group. */
function canTrade(a, b) {
  if (!modes.restricted(a.mode) && !modes.restricted(b.mode)) return '';
  if (a.mode === 'group' && b.mode === 'group') {
    const ga = groupsMod.groupOf(groupsT, a.key), gb = groupsMod.groupOf(groupsT, b.key);
    if (ga && gb && ga[0] === gb[0]) return '';
    return 'Group Ironman heroes can only trade with their own group (/group).';
  }
  const r = modes.restricted(a.mode) ? a : b;
  return (r === a ? 'Your ' : r.name + '\'s ') + modes.nameOf(r.mode) + ' hero can\'t trade' + (r.mode === 'group' ? ' outside its group.' : ': everything it uses, it finds.');
}
function sendGroup(c) {
  const g = gimOf(c);
  c.send({ t: 'gstore', g: g ? groupsMod.view(g, (k) => [...byName.values()].some((o) => o.key === k)) : null });
}

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
  // fewer realms wanted (/realms): an extra one goes once nobody is in it
  for (let i = realms.length - 1; i >= 0 && realms.length > Math.max(1, config.maxRealms); i--) {
    if (realms[i].count === 0) { log('Closed the extra realm ' + realms[i].name); realms.splice(i, 1); }
  }
  while (realms.length < Math.max(1, config.minRealms)) realms.push(newRealm());
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
/** config "discordBugForum": a webhook in a Discord Forum channel, where every /bug report opens a post of its own. */
const bugForum = new Discord(config.discordBugForum, config.name || 'Eldmere', log);
/** What the server did that's worth telling the Discord: (kind, details). */
function feat(kind, d) {
  // the rarest drops are news for everyone online too
  if (kind === 'godly' || kind === 'primordial') {
    const text = (kind === 'godly' ? '✦ GODLY DROP ✦ ' : '✦ Primordial drop ✦ ') + d.name + ' found ' + d.item + (d.from ? ' from ' + d.from : '') + '!';
    for (const o of clients.values()) if (o.authed) o.send({ t: 'msg', text, color: kind === 'godly' ? 0xfff6e0 : 0xff5533 });
  }
  if (!discord.on) return;
  if (kind === 'record') discord.post('🏆 **New record!** ' + dnames(d.names) + ' killed **' + desc(d.boss) + '** in **' + d.time + '**' + (d.old ? ' (beating ' + d.old + ')' : '') + '.', 0xffd75e);
  else if (kind === 'raid') discord.post('⭐ **' + desc(d.raid) + ' cleared!** ' + dnames(d.names) + ' defeated ' + desc(d.boss) + '.', d.color === undefined ? 0xffd060 : d.color);
  else if (kind === 'raidopen') discord.post('🌀 **' + desc(d.name) + '** opened **' + desc(d.raid) + '** in the Nexus! The portal closes in 30 seconds.', d.heroic ? 0xffb040 : 0xff3050);
  else if (kind === 'elder') discord.post('💀 **The Dark Elder has fallen** to ' + dnames(d.names) + '!', 0xff4060);
  else if (kind === 'siege') discord.post(d.won ? '⚔️ **The Realm Siege is broken!** ' + dnames(d.names) + ' brought down Vorgath the Siege Warlord in ' + desc(d.realm) + (d.mvp ? '. MVP: **' + desc(d.mvp) + '** (' + d.pct + '%)' : '') + '.' : '⚔️ Vorgath withdrew from ' + desc(d.realm) + ' undefeated.', 0xffa020);
  else if (kind === 'deep') discord.post('🕳️ **' + desc(d.name) + '** leads the ' + desc(d.cls) + 's in the Endless Abyss: wave **' + d.wave + '**!', 0xa060ff);
  else if (kind === 'deepweek') discord.post('🕳️ **The Endless Abyss\'s champions this week:** ' + d.champs.map(desc).join(', ') + '.', 0xa060ff);
  else if (kind === 'leaders') discord.post('👑 **' + desc(d.guild) + '** are this week\'s **Realm Leaders**, with ' + d.kills + ' realm bosses slain last week!', 0xffd75e);
  else if (kind === 'siegestart') discord.post('⚔️ **A Realm Siege has begun!** Vorgath the Siege Warlord marches on the Godlands of ' + desc(d.realm) + '. 15 minutes to break it.', 0xffa020);
  else if (kind === 'ascend') discord.post('✦ **' + desc(d.name) + '**\'s ' + desc(d.hero) + ' has **Ascended**' + (d.n > 1 ? ' (×' + d.n + ')' : '') + '!', 0xffd75e);
  else if (kind === 'oracle') discord.post('👁️ **' + desc(d.name) + '** completed the Oracle\'s collection for **' + desc(d.boss) + '**!', 0xb9a9ff);
  else if (kind === 'primordial') discord.post('🔥 **' + desc(d.name) + '** found a Primordial item: **' + desc(d.item) + '**' + (d.from ? ' from ' + desc(d.from) : '') + '!', 0xff5533);
  else if (kind === 'godly') discord.post('✨ **' + desc(d.name) + '** found a Godly item: **' + desc(d.item) + '**' + (d.from ? ' from ' + desc(d.from) : '') + '!', 0xff60ff);
  else if (kind === 'raidrecord') discord.post('⏱️ **Fastest ' + desc(d.raid) + ' clear this week:** ' + dnames(d.names) + ' in **' + d.time + '**!', 0xffd75e);
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
  charge: { secs: 1.4 }, volley: { secs: 1 }, bash: { secs: 1.9 }, shadow: { secs: 1 }, rewind: { secs: 1.2 },
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
  delete o._oracle;
  delete o._titles;
  delete o._fame;
  delete o._login;
  delete o._graves;
  delete o._xpb;
  delete o._petb;
  delete o._dead;
  o.earned = Object.keys(s._titles || {});
  return o;
}

/**
 * Checks a save from the player's game and stores it. Returns true if it was accepted;
 * otherwise the game gets its last good save back.
 */
function applySave(c, data, cid) {
  const prev = onlineSave(c.key);
  // hero names: letters, digits and spaces, as the game's hero menu allows (others see them)
  if (data && Array.isArray(data.chars)) for (const h of data.chars) if (h && typeof h === 'object' && h.name !== undefined) h.name = String(h.name).replace(/[^A-Za-z0-9 ]/g, '').slice(0, 16);
  // heroes the anti-cheat killed stay dead, whatever the game still holds (an admin's /revive brings one back)
  if (Array.isArray(prev._dead) && data && Array.isArray(data.chars)) {
    const dead = new Set(prev._dead);
    data.chars = data.chars.filter((h) => !(h && dead.has(h.id)));
  }
  // (with server-run monsters, gold and fame are checked against what was earned instead of a time budget)
  let why = checkSave(prev, data, c.meta, Date.now(), sims && !isAdmin(c) ? ['gold', 'fame', 'onrane'] : null);
  // items must come from the server (admins are trusted), and stats stay within the class limits
  // (only when the server runs the monsters: otherwise players' games still roll loot)
  if (!why && !canTest(c) && sims) why = items.check(prev, data) || items.checkStats(data);
  // hero modes: Ironman and Hardcore rules (and modes can't change)
  const modeFixes = [];
  if (!why && prev) why = modes.check(prev, data, modeFixes);
  if (why) {
    log('refused save from ' + c.name + ': ' + why);
    counters.savesRefused++;
    flag(c, 'save refused', why);
    c.send({ t: 'saveRejected', reason: why, data: publicSave(prev) });
    return false;
  }
  c.meta.lastSave = Date.now();
  // (a VIP that ran out mid-session stops counting)
  c.vip = isVip(c);
  data.tradeSeq = Math.max(data.tradeSeq || 0, prev ? prev.tradeSeq || 0 : 0);
  // the ledger is the server's: the game's copy is never trusted
  data._ledger = prev._ledger || {};
  data._ledgerV = prev._ledgerV || 1;
  // so is quest progress, and the Marketplace box (takings, returned items)
  if (prev._quests) data._quests = prev._quests; else delete data._quests;
  if (prev._market) data._market = prev._market; else delete data._market;
  // and the Oracle's record of boss kills and drops
  if (prev._oracle) data._oracle = prev._oracle; else delete data._oracle;
  if (prev.oracleDone) data.oracleDone = prev.oracleDone; else delete data.oracleDone;
  // and the Ascension tree
  if (prev.asc) data.asc = prev.asc; else delete data.asc;
  // and the Pet Stable (it only changes through petStable and hatch)
  if (prev.stable) data.stable = prev.stable; else delete data.stable;
  // and the daily login streak
  if (prev._login) data._login = prev._login; else delete data._login;
  // and the week's raid first clears, and the raids cleared on Heroic
  if (prev.raidWeek) data.raidWeek = prev.raidWeek; else delete data.raidWeek;
  if (prev.heroics) data.heroics = prev.heroics; else delete data.heroics;
  // and the fallen heroes an admin can bring back (see graves.js)
  if (prev._graves) data._graves = prev._graves; else delete data._graves;
  if (prev._dead) data._dead = prev._dead; else delete data._dead;
  const fell = graves.fallen(prev, data);
  // the hero being played died: until a hero enters a world again, monsters' shots at where it fell
  // aren't hits it should have taken (it sits on the death screen; no godmode flags for that)
  if (c.charId && fell.some((f) => f.hero.id === c.charId)) {
    c.heroDead = true;
    c.grace = Date.now() + 1e12;
    c.expHits = 0; c.expBase = 0; c.hitsBase = c.hitsRep || 0; c.expDmg = 0; c.expDmgBase = 0; c.dmgBase = c.dmgRep || 0;
  }
  // gold and fame only go up by what the server saw earned
  if (sims && !isAdmin(c)) {
    const cut = wallet.settle(prev, data, c.meta, Date.now());
    if (cut) {
      log('wallet ' + c.name + ': ' + cut);
      counters.savesCut++;
      flag(c, 'gold/fame cut', cut);
      c.send({ t: 'wallet', gold: data.gold || 0, fame: data.fame || 0, onrane: data.onrane || 0, skins: data.skins || {}, cosmetics: data.cosmetics || {} });
    }
    // and hero progress (XP, levels, stats, skill points, potions, backpacks, the pet) only by what was earned
    // (testers level and max their heroes from the admin menu)
    const fixed = isTester(c) ? [] : progress.check(prev, data, c.meta, Date.now());
    if (fixed.length) {
      const why2 = 'put back: ' + fixed.join('; ');
      log('progress ' + c.name + ': ' + why2);
      counters.savesCut++;
      flag(c, 'progress put back', fixed.join('; '));
      modeFixes.push('The server put back what its records don\'t show you earned (' + fixed.join('; ') + ').');
    }
  } else {
    if (prev._fame) data._fame = prev._fame;
    if (prev._xpb) data._xpb = prev._xpb; else delete data._xpb;
    if (prev._petb !== undefined) data._petb = prev._petb; else delete data._petb;
  }
  // heroes that died go on the season ladder, and into the server's graves
  seasonSave(c, prev, data);
  graves.bury(data, fell, wallet.fameGain(prev, data));
  // and earned titles (the game's list is only a copy)
  if (prev._titles) data._titles = prev._titles; else delete data._titles;
  // and the Fate Crate's chest, filters and bad-luck count, and the Fate Dust (all the server's)
  if (prev._crate) data._crate = prev._crate; else delete data._crate;
  data.earned = Object.keys(data._titles || {});
  // admins' own new items join their ledger
  if (canTest(c)) items.eachItem(data, (it) => { if (!it.sid && !items.STARTERS.has(items.fingerprint(it))) items.issue(data, it); });
  store.putSave(c.key, data);
  // a Hardcore item equipped too early went back to the inventory, or progress was put back: the game takes the server's copy
  if (modeFixes.length) c.send({ t: 'saveRejected', reason: modeFixes.join(' '), data: publicSave(data) });
  // the game says which hero it's playing with each shop request, so the shops never depend on
  // having seen this connection's last 'enter' (a reconnect, or a hero whose id was only just set)
  // (no swapping heroes in the middle of an Abyss run)
  if (typeof cid === 'string' && cid && (data.chars || []).some((h) => h && h.id === cid) && !(String(c.world || '').startsWith('deep:') && c.charId && c.charId !== cid)) c.charId = cid.slice(0, 64);
  // what this hero can deal now (new weapon, more Attack...), and its mode (a new hero's first save sets it)
  setCaps(c);
  c.mode = modes.modeOf(serverChar(c));
  // a cosmetic bought just now: the profile that came before this save can wear it now
  if (c.rawProfile && !isAdmin(c)) {
    const p = withBanner(c, cleanProfile(c.rawProfile, data));
    if (p.dye !== c.profile.dye || p.title !== c.profile.title || p.skin !== c.profile.skin || p.level !== c.profile.level || JSON.stringify(p.equip) !== JSON.stringify(c.profile.equip)) {
      c.profile = p;
      for (const o of inWorld(c.world, c)) o.send({ t: 'profile', id: c.id, profile: c.profile });
    }
  }
  return true;
}

/**
 * How hard this player can hit, from the server's copy of their hero (combat.js): c.caps limits
 * each hit and each monster's damage a second; c.maxDps all their damage a second together
 * (area attacks spread over many monsters). Admins aren't limited.
 */
const NEW_HERO_CAPS = { hit: 300, rate: 1500, burst: 6000, def: 0, maxHp: 0 };
function setCaps(c) {
  if (isAdmin(c)) { c.caps = null; c.maxDps = 1e9; c.defMax = 1e9; return; }
  const sv = store.getSave(c.key) || {};
  const extra = Data.oracleBonus(sv.oracleDone || [], sv.asc);
  // (the Endless Abyss run's boons)
  if (c.abyss) { const db = Data.deepBonus(c.abyss.boons); for (const k in db) extra[k] = (extra[k] || 0) + db[k]; }
  c.caps = combat.caps(serverChar(c), sv.pet, extra) || NEW_HERO_CAPS;
  // (Ascendant Fortune: loot luck the server adds to its own drops)
  c.ascLuck = Data.ascRank(sv.asc, 'fortune') * 3;
  c.maxDps = c.caps.rate * 3;
  // (damage checks: the most Defense, and the most health, this hero can have)
  c.defMax = c.caps.def;
}

/** A purchase or forge went through: the player's game takes the server's inventory and currencies. */
// ------------------------------------------------------------------ the Fate Crate
/** The account's crate state (sv._crate, the server's): the chest, filters, bad-luck count and Fate Dust. */
function crateState(sv) {
  let cr = sv._crate;
  if (!cr || typeof cr !== 'object') cr = sv._crate = {};
  if (!Array.isArray(cr.box)) cr.box = [];
  if (!cr.filter || typeof cr.filter !== 'object') cr.filter = { stat: 'keep', gold: 'keep', aether: 'keep', reroll: 'keep' };
  cr.pity = Math.max(0, cr.pity | 0);
  cr.dust = Math.max(0, cr.dust | 0);
  return cr;
}
/** What the game is told about it. */
function crateView(cr) {
  return { box: cr.box, filter: cr.filter, pity: cr.pity, dust: cr.dust, opened: cr.opened || 0 };
}
/** One crate: rolls its prize and puts it in the chest, unlocks it, or uses it at once (the filters). */
function openCrate(c, sv, cr) {
  const p = Data.crateRoll(cr.pity >= Data.CRATE_PITY - 1);
  cr.pity = p.tier >= 2 ? 0 : cr.pity + 1;
  const f = cr.filter;
  const res = { id: p.id, tier: p.tier, name: p.name };
  const keep = (it) => { cr.box.push(it); res.item = it; };
  const gold = (n, why) => { sv.gold = (sv.gold || 0) + n; res.auto = why; };
  switch (p.id) {
    case 'stat': {
      const it = Data.makePotion('stat', Data.randomStat());
      res.name = it.name;
      if (f.stat === 'sell') { res.item = it; gold(Data.sellValue(it), 'sold for ' + Data.sellValue(it) + ' gold'); } else keep(it);
      break;
    }
    case 'gold': {
      const amt = Math.round((Data.CRATE_GOLD[0] + Math.random() * (Data.CRATE_GOLD[1] - Data.CRATE_GOLD[0])) / 50) * 50;
      const it = Data.makePouch('gold', amt);
      res.name = 'Gold Pouch (' + amt.toLocaleString('en') + ' gold)';
      if (f.gold === 'open') { res.item = it; gold(amt, 'opened: +' + amt.toLocaleString('en') + ' gold'); } else keep(it);
      break;
    }
    case 'aether': {
      const it = Data.makePouch('aether', Data.CRATE_AETHER);
      res.name = 'Aether Vial (' + Data.CRATE_AETHER + ' Aether)';
      if (f.aether === 'open') { res.item = it; sv.onrane = (sv.onrane || 0) + Data.CRATE_AETHER; res.auto = 'opened: +' + Data.CRATE_AETHER + ' Aether'; } else keep(it);
      break;
    }
    case 'reroll': {
      const it = Data.makeCharm('reroll');
      res.name = it.name;
      if (f.reroll === 'sell') { res.item = it; gold(Data.sellValue(it), 'sold for ' + Data.sellValue(it).toLocaleString('en') + ' gold'); } else keep(it);
      break;
    }
    case 'sovereign': {
      const it = Data.makeCharm('sovereign');
      res.name = it.name;
      keep(it);
      broadcast('✦ ' + c.name + ' found a Sovereign Charm in a Fate Crate!', 0xffd23a);
      break;
    }
    case 'ring': {
      const it = Uniques.graded(Uniques.make(Uniques.LUCK_RING), Uniques.rollGrade(), 0);
      res.name = Uniques.displayName(it);
      keep(it);
      feat('godly', { name: c.name, item: res.name, from: 'a Fate Crate' });
      for (const o of clients.values()) if (o.authed && o !== c) o.send({ t: 'banner', text: c.name + ' found Fortune\'s Favour!', color: 0xfff6e0, msg: 'The Godly loot ring, from a Fate Crate.', sfx: 'fanfare' });
      break;
    }
    case 'pet': case 'title': {
      // a crate-only pet skin or title the account doesn't have yet (every one owned: gold instead)
      const list = (p.id === 'pet' ? Data.PET_SKINS : Data.TITLES).filter((t) => t.crate && !(sv._titles && sv._titles[t.id]));
      if (!list.length) { res.name = (p.id === 'pet' ? 'Pet skin' : 'Title') + ' (all owned)'; gold(25000, 'you have them all: 25,000 gold instead'); break; }
      const t = list[Math.floor(Math.random() * list.length)];
      res.name = (p.id === 'pet' ? 'Pet skin: ' : 'Title: ') + t.name;
      res.cos = t.id;
      grantTitle(c.key, t.id);
      break;
    }
  }
  return res;
}

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
    // loot luck (gear Luck + streak + shrine), capped at what the game can reach
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

// ------------------------------------------------------------------ item art (the admins' Item Art Maker)
/**
 * Inventory art drawn in game by the admins (Creator Tools > Item Art): itemArt[key] = {rows: 8 strings of
 * 8 letters a-p or '.', pal: {letter: colour}}, key "weapon:staff:3", "ability:spell:2", "armor:robe:5" or
 * "ring:4". Everyone gets it when they log in, and again whenever an admin saves.
 */
const itemArt = load('itemart.json', {});
const ITEM_ART_KEY = /^(weapon:[a-z]{2,12}:[0-9]|ability:[a-z]{2,12}:[0-9]|armor:[a-z]{2,12}:[0-9]|ring:[0-9])$/;
function cleanItemArt(m) {
  const size = 8;
  if (!Array.isArray(m.rows) || m.rows.length !== size) return null;
  const rows = m.rows.map((x) => String(x));
  if (!rows.every((x) => x.length === size && /^[a-p.]+$/.test(x))) return null;
  if (!rows.some((x) => /[a-p]/.test(x))) return null;
  const pal = {};
  for (const k of 'abcdefghijklmnop') {
    const v = m.pal && m.pal[k];
    if (v !== undefined) { const n = Number(v); if (!(n >= 0 && n <= 0xffffff)) return null; pal[k] = n | 0; }
  }
  return { rows, pal };
}

const handlers = {
  /** An admin saved (or removed: del) a piece of item art: it's kept, and everyone online gets it. */
  itemArtPut(c, m) {
    if (!isAdmin(c)) return c.note('Only admins can change item art.');
    const key = String(m.key || '');
    if (!ITEM_ART_KEY.test(key)) return c.note('That isn\'t an item the Item Art Maker knows.');
    let v = null;
    if (!m.del) { v = cleanItemArt(m); if (!v) return c.note('That drawing couldn\'t be saved (8x8, a-p colours).'); itemArt[key] = v; }
    else delete itemArt[key];
    save('itemart.json', itemArt);
    log(c.name + (m.del ? ' reset the art of ' : ' drew new art for ') + key);
    for (const o of clients.values()) if (o.authed) o.send({ t: 'itemArt', art: { [key]: v } });
    c.note(m.del ? 'Back to the game\'s own art.' : 'Saved: everyone sees the new art now.', 0x80ff80);
  },

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
    // (the hero going in is the one checked: the Abyss is for level 20 heroes)
    if (m.cid) c.charId = str(m.cid, 64);
    // dungeons and raids only through an open portal (a changed game can't walk into one)
    if (!mayEnter(c, world, c.world)) {
      log(c.name + ' tried to enter ' + world + ' without a portal');
      flag(c, 'no portal', 'entered ' + world + ' without a portal');
      c.send({ t: 'toNexus', msg: 'That portal has closed.' });
      world = 'solo:closed:' + c.id;
    }
    // (entering the world you're already in is no way to jump across it: you stay where the server has you)
    const same = c.world === world && !!c.sim;
    leaveWorld(c);
    c.world = world;
    if (!same) {
      c.x = num(m.x); c.y = num(m.y);
      // (the Abyss: everyone arrives at its spawn)
      if (world.startsWith('deep:')) { c.x = 100.5; c.y = 114; }
      c.mv = null; // a new world: movement checks start again from where you arrive
    }
    if (m.cid) c.charId = str(m.cid, 64);
    // the godmode count starts over in each world (and arriving, you can't be hit for a moment)
    c.expHits = 0; c.hitsBase = c.hitsRep || 0; c.expBase = 0;
    c.expDmg = 0; c.expDmgBase = 0; c.dmgBase = c.dmgRep || 0;
    if (c.heroDead) { c.heroDead = false; c.grace = 0; }
    c.grace = Math.max(c.grace || 0, Date.now() + 3500);
    deepEnter(c, world);
    setCaps(c);
    c.mode = modes.modeOf(serverChar(c));
    if (m.profile && typeof m.profile === 'object') c.rawProfile = m.profile;
    c.profile = withBanner(c, cleanProfile(m.profile, isAdmin(c) ? null : onlineSave(c.key)));
    // (its Ascension aura: how often the hero being played has ascended, by the server's copy)
    if (c.profile) c.profile.asc = Math.min(99, Number((serverChar(c) || {}).asc) || 0);
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
  // (raid openings are announced by the server itself now: announceRaid)
  raidOpen() {},

  /** Teleport: the exact spot of a party or guild member in your world, straight from the server. */
  tpreq(c, m) {
    const o = clients.get(Number(m.id));
    if (!o || !o.authed || o.world !== c.world) return c.note('They are not in this world.');
    if (!config.teleportToAnyone && !friends(c, o)) return c.note('You can only teleport to party and guild members.');
    c.send({ t: 'tppos', id: o.id, name: o.name, x: o.x, y: o.y });
    // the jump to them is expected (and you can't be hit for a moment as you land)
    c.tpTo = { x: o.x, y: o.y, until: Date.now() + 8000 };
    c.grace = Math.max(c.grace || 0, Date.now() + 2500);
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

  /**
   * The game's count of monster hits it has taken and the damage they did (both only grow), and its
   * health now; see godmodeCheck.
   */
  hits(c, m) {
    const n = num(m.n) | 0, d = Math.max(0, num(m.d));
    if (m.d !== undefined && m.mhp !== undefined) c.sendsDmg = true;
    // (the counts run for the whole game session: a reconnect starts from wherever they are)
    if (c.hitsRep === undefined) { c.hitsRep = c.hitsBase = n; c.dmgRep = c.dmgBase = d; }
    else {
      if (n > c.hitsRep && n - c.hitsRep < 500) c.hitsRep = n;
      if (d > c.dmgRep && d - c.dmgRep < 1e6) c.dmgRep = d;
    }
    // health beyond what the hero can have (its saved stats and gear): an edited game
    if (m.mhp !== undefined && c.caps && c.caps.maxHp > 0) {
      // (the server's copy is from the last save: a level-up, potion or armour since then adds health)
      const top = c.caps.maxHp * 1.1 + 60;
      if (num(m.hp) > top || num(m.mhp) > top) c.hpOver = (c.hpOver || 0) + 1;
      else c.hpOver = 0;
      c.hpSeen = { hp: num(m.hp), mhp: num(m.mhp), top: Math.round(top) };
    }
  },

  profile(c, m) {
    if (!m.profile || typeof m.profile !== 'object') return;
    c.rawProfile = m.profile;
    c.profile = withBanner(c, cleanProfile(m.profile, isAdmin(c) ? null : onlineSave(c.key)));
    // (its Ascension aura: how often the hero being played has ascended, by the server's copy)
    if (c.profile) c.profile.asc = Math.min(99, Number((serverChar(c) || {}).asc) || 0);
    for (const o of inWorld(c.world, c)) o.send({ t: 'profile', id: c.id, profile: c.profile });
    updateGuildMember(c);
  },

  chat(c, m) {
    const text = str(m.text, 120);
    if (!text || !chatAllowed(c)) return;
    for (const o of inWorld(c.world, c)) o.send({ t: 'chat', id: c.id, name: c.name, text, role: roleOf(c) || undefined });
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
    if (isTester(c)) return c.note(testerBlock(c, 'trade'));
    if (isTester(o)) return c.note(o.name + ' is a tester: testers can\'t trade.');
    { const why = canTrade(c, o); if (why) return c.note(why); }
    if (o.trade) return c.note(o.name + ' is busy trading.');
    if (c.trade) return;
    c.tradeAsk = o.id;
    o.send({ t: 'tradeReq', from: c.id, name: c.name });
  },

  tradeAns(c, m) {
    const o = clients.get(m.to);
    if (!o || o.tradeAsk !== c.id) return;
    if (isTester(c) || isTester(o)) { o.tradeAsk = 0; return c.note('Testers can\'t trade.'); }
    o.tradeAsk = 0;
    if (!m.yes) return o.note(c.name + ' declined the trade.', 0xff8080);
    if (o.trade || c.trade) return;
    { const why = canTrade(o, c); if (why) return o.note(why); }
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
      leaders.forget(gk);
      leaderLuck();
      save('leaders.json', leaders.s);
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

  // ---------------------------------------------------------------- Group Ironman storage
  /** The group's page: members and Group Storage (any of the group's members may look). */
  gsView(c) {
    const now = Date.now();
    if (now - (c.gsT || 0) < 400) return;
    c.gsT = now;
    sendGroup(c);
  },

  /** Puts an inventory item in the group's storage (Group Ironman heroes only). */
  gsPut(c, m) {
    if (isTester(c)) return c.send({ t: 'shopFail', msg: testerBlock(c, 'use Group Storage') });
    if (c.mode !== 'group') return c.send({ t: 'shopFail', msg: 'Only Group Ironman heroes can use Group Storage.' });
    const g = gimOf(c);
    if (!g) return c.send({ t: 'shopFail', msg: 'You\'re not in a group: /group create Name, or ask a friend for an invite.' });
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was stored.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const r = groupsMod.deposit(g, sv, ch.inv, num(m.slot) | 0, c.name);
    if (typeof r === 'string') return c.send({ t: 'shopFail', msg: r });
    save('groups.json', groupsT);
    shopDone(c, sv, ch, { market: 'You put ' + (r.name || 'your item') + ' in Group Storage.' });
    for (const o of byName.values()) if (gimOf(o) === g) sendGroup(o);
  },

  /** Takes an item out of the group's storage. */
  gsTake(c, m) {
    if (c.mode !== 'group') return c.send({ t: 'shopFail', msg: 'Only Group Ironman heroes can use Group Storage.' });
    const g = gimOf(c);
    if (!g) return c.send({ t: 'shopFail', msg: 'You\'re not in a group.' });
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was taken.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const r = groupsMod.withdraw(g, sv, ch.inv, num(m.idx) | 0, c.name);
    if (typeof r === 'string') { sendGroup(c); return c.send({ t: 'shopFail', msg: r }); }
    save('groups.json', groupsT);
    shopDone(c, sv, ch, { market: 'You took ' + (r.name || 'an item') + ' from Group Storage.' });
    for (const o of byName.values()) if (gimOf(o) === g) sendGroup(o);
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
    if (isTester(c)) return c.send({ t: 'shopFail', msg: testerBlock(c, 'put items in the guild bank') });
    if (modes.restricted(c.mode)) return c.send({ t: 'shopFail', msg: modes.nameOf(c.mode) + ' heroes can\'t use the guild bank.' });
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
    if (modes.restricted(c.mode)) return c.send({ t: 'shopFail', msg: modes.nameOf(c.mode) + ' heroes can\'t use the guild bank.' });
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
    // (raid portals come from the server only: see announceRaid)
    if (m.d.t === 'portal' && m.d.k === 'raid') return;
    const out = { t: 'w', from: c.id, d: m.d };
    if (m.to === 'all') { for (const o of inWorld(c.world, c)) o.send(out); return; }
    const target = m.to === 'host' ? hosts.get(c.world) : clients.get(m.to);
    if (target && target !== c && target.world === c.world) target.send(out);
  },

  ping(c, m) { c.send({ t: 'pong', at: m.at }); },

  /**
   * A bug report (/bug what happened): kept in bugs.json with where the player was and
   * what they had, posted to the Discord feed, and shown to admins (/bugs).
   */
  bug(c, m) {
    const text = str(m.text, 400).trim();
    if (text.length < 5) return c.note('Usage: /bug what happened (a sentence or two helps a lot).');
    const now = Date.now();
    // (per account, so reconnecting doesn't reset it)
    if (now - (bugAt.get(c.key) || 0) < 30000) return c.note('Thanks! Wait a moment before sending another report.');
    bugAt.set(c.key, now);
    const x = m.ctx && typeof m.ctx === 'object' ? m.ctx : {};
    const ch = serverChar(c), sv = onlineSave(c.key) || {};
    const p = sv.pet;
    const b = {
      id: (bugs.next = (bugs.next || 0) + 1), at: now, key: c.key, name: c.name, no: (accounts[c.key] && accounts[c.key].no) || 0, text,
      world: String(c.world || '').split(':').slice(0, 2).join(':').slice(0, 40), x: Math.round(num(c.x)), y: Math.round(num(c.y)),
      hero: ch ? (Data.CLASSES[ch.cls] ? Data.CLASSES[ch.cls].name : ch.cls) + ' lv ' + (ch.level || 1) + (ch.mode ? ' ' + ch.mode : '') : 'no hero',
      pet: p && typeof p === 'object' ? Data.petTitle(p) + ' lv ' + (p.level || 1) : '',
      game: str(x.ver, 20), fps: num(x.fps) | 0, ping: num(x.ping) | 0, done: false
    };
    bugs.list.unshift(b);
    if (bugs.list.length > 300) bugs.list.length = 300;
    save('bugs.json', bugs);
    store.appendLog('bugs.log', new Date(now).toISOString() + ' #' + b.id + ' ' + c.name + ' (' + b.hero + ', ' + b.world + '): ' + text);
    for (const a of byName.values()) if (isAdmin(a)) a.note('[Bug #' + b.id + '] ' + c.name + ': ' + text + '  (/bugs to see them all)', 0xffb040);
    const bugLine = '🐞 **Bug #' + b.id + '** from **' + desc(c.name) + '**: ' + desc(text) + '\n_' + desc(b.hero) + (b.pet ? ', ' + desc(b.pet) : '') + ' · ' + desc(b.world || 'menu') + (b.fps ? ' · ' + b.fps + ' fps' : '') + (b.ping ? ' · ' + b.ping + ' ms' : '') + '_';
    // a bug forum (config discordBugForum): every report its own post, titled after it; else the main feed
    if (bugForum.on) bugForum.post(bugLine, 0xffa040, { title: 'Bug #' + b.id + ': ' + text.replace(/\s+/g, ' ').slice(0, 70) }, (thread) => { if (thread) { b.thread = thread; save('bugs.json', bugs); } });
    else if (discord.on) discord.post(bugLine, 0xffa040);
    c.note('Thanks! Bug #' + b.id + ' was sent to the admins.', 0x80ff80);
  },

  /**
   * Ascension: a level 20 hero with every stat maxed starts again at level 1 (it keeps
   * its gear and the skill points it earned past 20) for a point in the account's tree.
   */
  ascend(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved. Try again in a moment.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch) return c.send({ t: 'shopFail', msg: 'Pick a hero and enter the game first.' });
    if (!Data.canAscend(ch)) return c.send({ t: 'shopFail', msg: 'Only a level 20 hero with every stat maxed can ascend.' });
    const cls = Data.CLASSES[ch.cls] || Data.CLASSES.wizard;
    const kept = Math.max(0, (Number(ch.skillPoints) || 0) + Data.skillSpent(ch.skills || {}) - 19);
    ch.level = 1; ch.xp = 0; ch.xpNext = progress.xpFor(1); ch.ascXp = 0;
    ch.stats = JSON.parse(JSON.stringify(cls.base));
    ch.skills = {}; ch.skillPoints = kept; ch.highStakes = false;
    ch.asc = (Number(ch.asc) || 0) + 1;
    const a = sv.asc && typeof sv.asc === 'object' ? sv.asc : (sv.asc = { pts: 0, r: {}, n: 0 });
    a.pts = (a.pts || 0) + 1; a.n = (a.n || 0) + 1;
    sv.tradeSeq = (sv.tradeSeq || 0) + 1;
    store.putSave(c.key, sv);
    setCaps(c);
    log(c.name + '\'s ' + (ch.name || 'hero') + ' ascended (' + ch.asc + ')');
    feat('ascend', { name: c.name, hero: ch.name || cls.name, n: ch.asc });
    for (const o of clients.values()) if (o.authed && o !== c) o.send({ t: 'msg', text: '✦ ' + c.name + '\'s ' + (ch.name || cls.name) + ' has Ascended' + (ch.asc > 1 ? ' for the ' + ch.asc + (ch.asc === 2 ? 'nd' : ch.asc === 3 ? 'rd' : 'th') + ' time' : '') + '! ✦', color: 0xffd75e });
    c.send({ t: 'asc', asc: a, ascended: ch.asc });
    c.send({ t: 'saveRejected', reason: 'OK: ' + (ch.name || 'Your hero') + ' has Ascended! Level 1 again, gear kept' + (kept ? ', ' + kept + ' skill point' + (kept === 1 ? '' : 's') + ' kept' : '') + ', and +1 Ascension point to spend.', data: publicSave(sv) });
  },

  /** A point into the Ascension tree (m.id: an ASC_PERKS id). */
  ascSpend(c, m) {
    const sv = onlineSave(c.key);
    const p = Data.ASC_PERKS.find((x) => x.id === m.id);
    const a = sv && sv.asc;
    if (!p || !a || !(a.pts > 0)) return c.send({ t: 'shopFail', msg: 'You have no Ascension points: ascend a maxed hero to earn one.' });
    if (!a.r) a.r = {};
    if ((a.r[p.id] || 0) >= p.max) return c.send({ t: 'shopFail', msg: p.name + ' is already at its highest rank.' });
    a.r[p.id] = (a.r[p.id] || 0) + 1;
    a.pts--;
    sv.tradeSeq = (sv.tradeSeq || 0) + 1;
    store.putSave(c.key, sv);
    setCaps(c);
    c.send({ t: 'asc', asc: a, seq: sv.tradeSeq });
  },

  /** The Endless Abyss: the boon picked after a boss wave (one of the three offered). */
  abyssBoon(c, m) {
    const off = c.abyssOffer;
    if (!c.abyss || !off || !off.ids.includes(m.id)) return;
    c.abyssOffer = null;
    c.abyss.boons.push(m.id);
    setCaps(c);
    c.send({ t: 'abyssRun', on: true, wave: c.abyss.wave, boons: c.abyss.boons });
  },

  /** The Endless Abyss's board for one class (the window). */
  deepBoard(c, m) {
    deepWeek();
    const cls = typeof m.cls === 'string' && Object.prototype.hasOwnProperty.call(Data.CLASSES, m.cls) ? m.cls : 'wizard';
    const list = (Object.prototype.hasOwnProperty.call(deep.cls, cls) ? deep.cls[cls] : []).map((r) => ({ name: r.name, hero: r.hero, wave: r.wave || 0 }));
    let best = 0;
    for (const k in deep.cls) for (const r of deep.cls[k]) if (r.key === c.key) best = Math.max(best, r.wave || 0);
    c.send({ t: 'deepBoard', cls, list, best, week: deep.week });
  },

  /** The Oracle (O, or /oracle): the bosses you've killed and what they dropped. */
  oracleView(c, m) { c.send({ t: 'oracle', o: oracle.view(onlineSave(c.key)) }); },

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

  /** /glands: the server picks a spot in this realm's Godlands and expects the jump there. */
  glands(c, m) {
    const sm = c.sim;
    if (!sm || !sm.w || !String(c.world || '').startsWith('realm:')) return c.note('/glands only works inside a realm.');
    const now = Date.now();
    if (now - (c.glandsAt || 0) < 5000) return c.note('Wait a moment before using /glands again.');
    const w = sm.w;
    for (let i = 0; i < 600; i++) {
      const x = Math.random() * w.N, y = Math.random() * w.N;
      if (w.zoneAt(x, y) === World.GOD_ZONE && w.canStand(x, y, 0.5, false)) {
        c.glandsAt = now;
        const px = Math.round(x * 100) / 100, py = Math.round(y * 100) / 100;
        c.tpTo = { x: px, y: py, until: now + 8000 };
        c.grace = Math.max(c.grace || 0, now + 2500);
        return c.send({ t: 'glandsPos', x: px, y: py });
      }
    }
    c.note('Couldn\'t find a spot in the Godlands.');
  },

  /** A key was used: it leaves the server's copy of the hero, and the portal it opened lets people in. */
  portalKey(c, m) {
    const sv = onlineSave(c.key), ch = serverChar(c);
    const sid = str(m.sid, 40), i = num(m.i) | 0, seed = num(m.s) >>> 0;
    // (admins open raids for everyone from the admin menu, without a key)
    // (a Heroic raid takes two of its keys; its world key ends in ':h')
    const heroic = m.k === 'raid' && !!m.h;
    const wkey = (m.k === 'raid' ? 'raid:' : 'dg:') + i + ':' + seed + (heroic ? ':h' : '');
    // one raid at a time: the key stays in your bag
    if (m.k === 'raid') {
      const busy = raidBusy();
      if (busy) {
        c.send({ t: 'raidBusy', msg: busy });
        if (sv) c.send({ t: 'saveRejected', reason: 'OK: ' + busy, data: publicSave(sv) });
        return;
      }
      if (c.world !== 'nexus') return c.send({ t: 'raidBusy', msg: 'Raids open in the Nexus, at the Raid Table.' });
    }
    // (admins open raids for everyone from the admin menu, without a key)
    if (canTest(c) && !sid && seed) { openWorld(wkey); if (m.k === 'raid') announceRaid(c, wkey, i, seed, heroic); return; }
    if (!ch || !Array.isArray(ch.inv)) return;
    const at = sid ? ch.inv.findIndex((it) => it && it.sid === sid) : -1;
    const key = at >= 0 ? ch.inv[at] : null;
    const ok = key && (m.k === 'raid' ? Data.keyRaid(key) === i : Data.keyDungeon(key) === i);
    const sid2 = heroic ? str(m.sid2, 40) : '';
    const at2 = sid2 && sid2 !== sid ? ch.inv.findIndex((it) => it && it.sid === sid2) : -1;
    const key2 = at2 >= 0 ? ch.inv[at2] : null;
    if (!ok || !seed || (heroic && !(key2 && Data.keyRaid(key2) === i))) { log(c.name + ' opened a portal without a key it has'); return; }
    ch.inv[at] = null;
    // (used up: a save that still holds it is refused, see items.check)
    items.release(sv, key);
    if (key2) { ch.inv[at2] = null; items.release(sv, key2); }
    store.putSave(c.key, sv);
    openWorld(wkey);
    if (m.k === 'raid') announceRaid(c, wkey, i, seed, heroic);
  },

  /** A pet egg: the server takes the gold and rolls the pet (the game can't pick its own). */
  hatch(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so no egg was bought.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    // a pet you already have goes to the Stable to make room
    const stable = Array.isArray(sv.stable) ? sv.stable : [];
    if (sv.pet && stable.length >= PET_STABLE) return c.send({ t: 'shopFail', msg: 'Your Stable is full (' + PET_STABLE + ' pets). Release one first.' });
    if ((sv.gold || 0) < Data.PET_EGG_PRICE) return c.send({ t: 'shopFail', msg: 'You need ' + Data.PET_EGG_PRICE.toLocaleString('en') + ' gold to buy a pet egg.' });
    sv.gold -= Data.PET_EGG_PRICE;
    if (sv.pet) { stable.push(sv.pet); sv.stable = stable; }
    sv.pet = progress.hatch();
    shopDone(c, sv, ch, { pet: sv.pet, stable: sv.stable || [] });
  },

  /**
   * Evolving the pet (Pet Yard): its level, Evolution Stones from your inventory and gold;
   * at Adult it takes path m.path ('a' or 'b') for good.
   */
  petEvolve(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so your pet didn\'t evolve.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const p = sv.pet;
    if (!p || typeof p !== 'object') return c.send({ t: 'shopFail', msg: 'You have no pet.' });
    const block = Data.petEvolveBlock(p);
    if (block) return c.send({ t: 'shopFail', msg: block });
    const next = Data.PET_STAGES[Data.petStage(p) + 1];
    const stones = [];
    ch.inv.forEach((it, i) => { if (it && it.kind === 'stone') stones.push(i); });
    if (stones.length < next.stones) return c.send({ t: 'shopFail', msg: 'Evolving to ' + next.name + ' takes ' + next.stones + ' Evolution Stone' + (next.stones === 1 ? '' : 's') + ' (you have ' + stones.length + '). Bosses drop them.' });
    if ((sv.gold || 0) < next.gold) return c.send({ t: 'shopFail', msg: 'Evolving to ' + next.name + ' costs ' + next.gold.toLocaleString('en') + ' gold.' });
    const stage = Data.petStage(p) + 1;
    if (stage === 2 && m.path !== 'a' && m.path !== 'b') return c.send({ t: 'shopFail', msg: 'Pick a path for your pet first.' });
    // the stones are used up for good
    const l = sv._ledger || {};
    for (const i of stones.slice(0, next.stones)) { if (ch.inv[i].sid) delete l[ch.inv[i].sid]; ch.inv[i] = null; }
    sv.gold -= next.gold;
    p.stage = stage;
    if (stage === 2) p.path = m.path;
    log(c.name + '\'s pet evolved to ' + Data.petTitle(p));
    shopDone(c, sv, ch, { pet: p, evolved: Data.petTitle(p) });
  },

  /** The Pet Stable: m.op 'store' (the active pet goes in) or 'take' (pet m.i comes out; the active one swaps in). */
  petStable(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved. Try again in a moment.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const stable = Array.isArray(sv.stable) ? sv.stable : (sv.stable = []);
    if (m.op === 'store') {
      if (!sv.pet) return c.send({ t: 'shopFail', msg: 'You have no pet with you.' });
      if (stable.length >= PET_STABLE) return c.send({ t: 'shopFail', msg: 'Your Stable is full (' + PET_STABLE + ' pets).' });
      stable.push(sv.pet);
      delete sv.pet;
    } else if (m.op === 'take') {
      const i = num(m.i) | 0;
      if (!stable[i]) return c.send({ t: 'shopFail', msg: 'That pet isn\'t in your Stable.' });
      const out = stable.splice(i, 1)[0];
      if (sv.pet) stable.splice(i, 0, sv.pet);
      sv.pet = out;
    } else if (m.op === 'release') {
      // (a pet released from the Stable; anything it carried comes back to the inventory first)
      const i = num(m.i) | 0;
      if (!stable[i]) return c.send({ t: 'shopFail', msg: 'That pet isn\'t in your Stable.' });
      if ((stable[i].bag || []).some(Boolean)) return c.send({ t: 'shopFail', msg: 'Take out what it carries first (bring it out of the Stable).' });
      stable.splice(i, 1);
    } else return;
    shopDone(c, sv, ch, { pet: sv.pet || null, stable, stabled: m.op });
  },

  /** (Pets aren't fed any more: they grow from the XP you earn. An older game may still ask.) */
  petFeed(c, m) {
    c.send({ t: 'shopFail', msg: 'Pets don\'t need feeding any more: they grow from the XP you earn in the realm.' });
  },

  /** Marketplace and Key Merchant: the server checks the gold and hands out the item. */
  buy(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was bought.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const what = str(m.what, 12);
    // a backpack: eight more slots for this hero (the server's record of it is what counts, see progress.js)
    if (what === 'backpack') {
      const e = Data.SHOP.find((x) => x.id === 'backpack');
      if (ch.backpack) return c.send({ t: 'shopFail', msg: 'This character already has a backpack.' });
      if ((sv.gold || 0) < e.price) return c.send({ t: 'shopFail', msg: 'Not enough gold.' });
      sv.gold -= e.price;
      ch.backpack = true;
      while (ch.inv.length < 16) ch.inv.push(null);
      return shopDone(c, sv, ch, { backpack: true, bought: e.name });
    }
    let price, make;
    if (what === 'key') {
      const di = num(m.dg) | 0;
      if (!Data.DUNGEONS[di]) return;
      price = Data.keyPrice(di);
      if (!(price > 0)) return;   // (lairs have no keys)
      make = () => Data.makeDungeonKey(di);
    } else {
      const e = Data.SHOP.find((x) => x.id === what);
      const cls = Data.CLASSES[ch.cls] || Data.CLASSES.wizard;
      const makers = { hp: () => Data.makePotion('hp'), mp: () => Data.makePotion('mp'), stat: () => Data.makePotion('stat', Data.randomStat()),
        ut: () => Data.makeForSlot(cls, Math.floor(Math.random() * 3), 7, null) };
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
    if (isTester(c)) return c.send({ t: 'shopFail', msg: testerBlock(c, 'sell items') });
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was sold.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const slot = num(m.slot) | 0, item = ch.inv[slot];
    if (!item || typeof item !== 'object') return c.send({ t: 'shopFail', msg: 'There is nothing to sell there.' });
    if (item.locked) return c.send({ t: 'shopFail', msg: (item.name || 'That item') + ' is locked. Unlock it first (right-click it).' });
    const value = Math.max(0, Data.sellValue(item) | 0);
    ch.inv[slot] = null;
    items.release(sv, item);
    sv.gold = (sv.gold || 0) + value;
    shopDone(c, sv, ch, { sold: item.name || 'an item', value });
  },

  /**
   * Fortune's Anvil (at the Starforge): pay gold and strike an item. It climbs a step
   * (tiers, then Runed, Bonded, Eldritch), drops one, or shatters. The server rolls.
   */
  anvil(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so the Anvil stayed cold.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const slot = num(m.slot) | 0, item = ch.inv[slot];
    const why = Data.anvilBlock(item);
    if (why) return c.send({ t: 'shopFail', msg: why });
    const cost = Data.anvilCost(item);
    if ((sv.gold || 0) < cost) return c.send({ t: 'shopFail', msg: 'Striking that costs ' + cost.toLocaleString('en') + ' gold.' });
    sv.gold -= cost;
    const roll = Math.random();
    const way = roll < Data.ANVIL_UP ? 'up' : roll < Data.ANVIL_UP + Data.ANVIL_DOWN ? 'down' : 'shatter';
    const made = way === 'shatter' ? null : Data.anvilStep(item, way === 'up');
    if (item.sid && sv._ledger) delete sv._ledger[item.sid];
    ch.inv[slot] = made ? items.issue(sv, made) : null;
    log(c.name + ' struck ' + (item.name || 'an item') + ' on the Anvil: ' + (made ? way + ' to ' + made.name : 'shattered'));
    shopDone(c, sv, ch, { anvil: made ? way : 'shatter', was: item.name, now: made ? made.name : '', slot });
  },

  /** Starforge: a Legendary + a Star Shard + Aether = its Starforged self (Uniques.starforge). */
  forge(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was forged.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const slot = num(m.slot) | 0, item = ch.inv[slot];
    if (!Uniques.canStarforge(item)) return c.send({ t: 'shopFail', msg: 'Only a Legendary can be Starforged.' });
    const sor = ch.inv.findIndex((it) => it && it.kind === 'material');
    if (sor < 0) return c.send({ t: 'shopFail', msg: 'You need a Star Shard.' });
    if ((sv.onrane || 0) < Data.STARFORGE_AETHER) return c.send({ t: 'shopFail', msg: 'You need ' + Data.STARFORGE_AETHER + ' Aether.' });
    const cls = Data.CLASSES[ch.cls] || Data.CLASSES.wizard;
    const lg = items.issue(sv, Data.forgeLegendary(item, cls));
    // the two items it was made from are used up for good
    const l = sv._ledger || {};
    delete l[item.sid];
    delete l[ch.inv[sor].sid];
    ch.inv[sor] = null;
    ch.inv[slot] = lg;
    sv.onrane = (sv.onrane || 0) - Data.STARFORGE_AETHER;
    shopDone(c, sv, ch, { forged: lg.name, slot });
  },

  /**
   * Grades at the Starforge (Uniques: grades D-SSS, forging +1..+5, Fate Dust). a:
   *  salvage (slot): the item becomes Fate Dust;  reroll (slot): 10 Fate Dust, a new grade;
   *  charm (slot, cs): a Reroll Charm (never lower) or Sovereign Charm (S or better);
   *  fuse (slot, fs): a copy of the same item is forged in, +1 (+3% to everything).
   * The item's forging is always kept; its new self takes a new ledger id.
   */
  grade(c, m) {
    const now = Date.now();
    if (now - (c.gradeAt || 0) < 250) return;
    c.gradeAt = now;
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing changed.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!sv || !ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const cr = crateState(sv);
    const slot = num(m.slot) | 0, item = ch.inv[slot];
    if (!Uniques.gradeable(item)) return c.send({ t: 'shopFail', msg: 'Only UT, Legendary, Starforged and Primordial items have a grade.' });
    const a = str(m.a, 12);
    const was = Uniques.displayName(item);
    let made = null, extra = {};
    if (a === 'salvage') {
      const d = Uniques.dustOf(item);
      if (!d) return c.send({ t: 'shopFail', msg: 'That can\'t be salvaged.' });
      if (item.locked) return c.send({ t: 'shopFail', msg: was + ' is locked. Unlock it first (right-click it).' });
      ch.inv[slot] = null;
      items.release(sv, item);
      cr.dust += d;
      log(c.name + ' salvaged ' + was + ' for ' + d + ' Fate Dust');
      return shopDone(c, sv, ch, { graded: 'salvage', was, got: d, dust: cr.dust });
    } else if (a === 'reroll') {
      if (cr.dust < Uniques.REROLL_DUST) return c.send({ t: 'shopFail', msg: 'A reroll costs ' + Uniques.REROLL_DUST + ' Fate Dust (you have ' + cr.dust + '). Salvage items you don\'t need for it.' });
      cr.dust -= Uniques.REROLL_DUST;
      made = Uniques.graded(item, Uniques.rollGrade(), item.fg | 0);
    } else if (a === 'charm') {
      const cs = num(m.cs) | 0, charm = ch.inv[cs];
      if (!charm || charm.kind !== 'charm') return c.send({ t: 'shopFail', msg: 'You need a Reroll Charm or a Sovereign Charm.' });
      const min = charm.sub === 'sovereign' ? Uniques.GRADE_S : Uniques.gradeOf(item);
      made = Uniques.graded(item, Uniques.rollGrade(min), item.fg | 0);
      ch.inv[cs] = null;
      items.release(sv, charm);
      extra.charm = charm.name;
    } else if (a === 'fuse') {
      const fs = num(m.fs) | 0, copy = ch.inv[fs];
      if (fs === slot || !Uniques.canFuse(item, copy)) return c.send({ t: 'shopFail', msg: (item.fg | 0) >= Uniques.FORGE_MAX ? was + ' is already +' + Uniques.FORGE_MAX + '.' : 'Forge in another copy of the same item.' });
      if (copy.locked) return c.send({ t: 'shopFail', msg: Uniques.displayName(copy) + ' is locked. Unlock it first (right-click it).' });
      made = Uniques.graded(item, Uniques.gradeOf(item), (item.fg | 0) + 1);
      ch.inv[fs] = null;
      items.release(sv, copy);
    } else return;
    items.release(sv, item);
    ch.inv[slot] = items.issue(sv, made);
    log(c.name + ' ' + a + ': ' + was + ' -> ' + Uniques.displayName(made));
    shopDone(c, sv, ch, Object.assign({ graded: a, was, now: Uniques.displayName(made), slot, dust: cr.dust }, extra));
  },

  /** The Fate Crate: n = 1 or 10 crates, 5,000 fame each. Prizes go to the crate chest (or are used at once, by the player's filters). */
  crate(c, m) {
    const now = Date.now();
    if (now - (c.crateAt || 0) < 400) return;
    c.crateAt = now;
    if (isTester(c)) return c.send({ t: 'shopFail', msg: testerBlock(c, 'open Fate Crates') });
    if (modes.restricted(c.mode)) return c.send({ t: 'shopFail', msg: modes.nameOf(c.mode) + ' heroes can\'t open Fate Crates.' });
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so no crate was opened.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!sv || !ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const n = (num(m.n) | 0) === 10 ? 10 : 1;
    const cost = Data.CRATE_COST * n;
    if ((sv.fame || 0) < cost) return c.send({ t: 'shopFail', msg: 'You need ' + cost.toLocaleString('en') + ' fame for ' + (n === 1 ? 'a crate' : n + ' crates') + ' (you have ' + (sv.fame || 0).toLocaleString('en') + ').' });
    const cr = crateState(sv);
    if (cr.box.length + n > Data.CRATE_BOX) return c.send({ t: 'shopFail', msg: 'Your crate chest is full. Take some prizes out first.' });
    sv.fame -= cost;
    const out = [];
    for (let i = 0; i < n; i++) out.push(openCrate(c, sv, cr));
    cr.opened = (cr.opened || 0) + n;
    log(c.name + ' opened ' + n + ' Fate Crate' + (n === 1 ? '' : 's') + ': ' + out.map((r) => r.name).join(', '));
    shopDone(c, sv, ch, { crate: out, fame: sv.fame, cr: crateView(cr) });
  },

  /** Takes prizes out of the crate chest into the inventory: i (one), or all. */
  crateTake(c, m) {
    if (modes.restricted(c.mode)) return c.send({ t: 'shopFail', msg: modes.nameOf(c.mode) + ' heroes can\'t take Fate Crate prizes.' });
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so nothing was taken.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!sv || !ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const cr = crateState(sv);
    const want = m.all ? cr.box.map((_, i) => i) : [num(m.i) | 0];
    let took = 0;
    for (const i of want.sort((a, b) => b - a)) {
      const it = cr.box[i];
      if (!it) continue;
      const slot = ch.inv.indexOf(null);
      if (slot < 0) break;
      ch.inv[slot] = items.issue(sv, it);
      cr.box.splice(i, 1);
      took++;
    }
    if (!took) return c.send({ t: 'shopFail', msg: ch.inv.indexOf(null) < 0 ? 'Inventory full!' : 'Nothing to take.' });
    shopDone(c, sv, ch, { crateTook: took, cr: crateView(cr) });
  },

  /** The crate chest and filters (when the station opens), and filter changes: f = {stat, gold, aether, reroll}. */
  crateView(c, m) {
    const sv = onlineSave(c.key);
    if (!sv) return;
    const cr = crateState(sv);
    if (m && m.f && typeof m.f === 'object') {
      const ok = { stat: ['keep', 'sell'], gold: ['keep', 'open'], aether: ['keep', 'open'], reroll: ['keep', 'sell'] };
      for (const k in ok) if (ok[k].indexOf(m.f[k]) >= 0) cr.filter[k] = m.f[k];
      store.putSave(c.key, sv);
    }
    c.send(Object.assign({ t: 'crateState', fame: sv.fame || 0 }, crateView(cr)));
  },

  /** Opens a Gold Pouch or Aether Vial from the inventory. */
  pouch(c, m) {
    if (m.data && !applySave(c, m.data, m.cid)) return c.send({ t: 'shopFail', msg: 'Your progress could not be saved, so it wasn\'t opened.' });
    const sv = onlineSave(c.key), ch = serverChar(c);
    if (!sv || !ch || !Array.isArray(ch.inv)) return c.send({ t: 'shopFail', msg: 'Your character has not been saved yet. Try again in a moment.' });
    const slot = num(m.slot) | 0, it = ch.inv[slot];
    if (!it || it.kind !== 'pouch') return;
    const amt = Math.max(0, Math.min(it.sub === 'aether' ? 1000 : 100000, it.amt | 0));
    ch.inv[slot] = null;
    items.release(sv, it);
    if (it.sub === 'aether') sv.onrane = (sv.onrane || 0) + amt; else sv.gold = (sv.gold || 0) + amt;
    shopDone(c, sv, ch, { pouch: it.sub === 'aether' ? 'aether' : 'gold', amt });
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
    if (isTester(c)) return c.send({ t: 'shopFail', msg: testerBlock(c, 'use the Marketplace') });
    if (modes.restricted(c.mode)) return c.send({ t: 'shopFail', msg: modes.nameOf(c.mode) + ' heroes can\'t use the Marketplace.' });
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
    if (modes.restricted(c.mode)) return c.send({ t: 'shopFail', msg: modes.nameOf(c.mode) + ' heroes can\'t use the Marketplace.' });
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
    // a rune (m.rune: its inventory slot) makes sure its stat is among the new bonuses, and is used up
    let rune = null;
    if (!form && m.rune !== undefined && m.rune !== null) {
      const ri = num(m.rune) | 0;
      rune = ch.inv[ri];
      if (!rune || rune.kind !== 'rune' || ri === slot) return c.send({ t: 'shopFail', msg: 'That rune isn\'t in your inventory.' });
      if (!Data.canUseRune(item, rune.sub)) return c.send({ t: 'shopFail', msg: 'That rune can\'t be used on this item.' });
      if (rune.sid && sv._ledger) delete sv._ledger[rune.sid];
      ch.inv[ri] = null;
    }
    const made = items.issue(sv, form ? Data.rerollForm(item) : rune ? Data.rerollStatsWith(item, rune.sub) : Data.rerollStats(item));
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
    if (cmd === '/group' || cmd === '/gim') {
      const sub = (parts[1] || '').toLowerCase(), arg = parts.slice(2).join(' ');
      const mine = groupsMod.groupOf(groupsT, c.key);
      if (sub === 'create') {
        const r = groupsMod.create(groupsT, c.key, c.name, arg);
        if (typeof r === 'string') return c.note(r);
        save('groups.json', groupsT);
        log(c.name + ' founded the Group Ironman group ' + r[1].name);
        sendGroup(c);
        return c.note('You founded the Group Ironman group ' + r[1].name + '. Invite up to ' + (groupsMod.MAX - 1) + ' friends with /group invite name in the next ' +
          groupsMod.INVITE_DAYS + ' days: after that the group is locked, and nobody who joins can leave or be removed.', 0x7fd8a8);
      }
      if (sub === 'invite') {
        if (!mine) return c.note('Make a group first: /group create Name');
        const o = byName.get(accountKey(parts[2]) || (parts[2] || '').toLowerCase());
        if (!o) return c.note('Nobody called ' + (parts[2] || '?') + ' is online.');
        if (o === c) return;
        if (groupsMod.groupOf(groupsT, o.key)) return c.note(o.name + ' is already in a group.');
        // (testers and players don't mix: a tester's items come from the admin menu)
        if (isTester(c) !== isTester(o)) return c.note('Testers and players can\'t share a Group Ironman group.');
        const shut = groupsMod.closed(mine[1]);
        if (shut) return c.note(shut);
        groupInvites.set(o.key, { id: mine[0], from: c.name, at: Date.now() });
        o.note(c.name + ' invited you to their Group Ironman group ' + mine[1].name + '. Joining is for good: you can\'t leave or be removed. Type /group accept to join.', 0x7fd8a8);
        return c.note('Invited ' + o.name + ' to ' + mine[1].name + '.', 0x7fd8a8);
      }
      if (sub === 'accept' || sub === 'join') {
        const inv = groupInvites.get(c.key);
        if (!inv || Date.now() - inv.at > 10 * 60000) return c.note('You have no group invite (they last 10 minutes).');
        groupInvites.delete(c.key);
        const tg = groupsT[inv.id];
        if (tg && Object.keys(tg.members).some((k) => isTester({ key: k, name: tg.members[k] }) !== isTester(c))) return c.note('Testers and players can\'t share a Group Ironman group.');
        const r = groupsMod.join(groupsT, inv.id, c.key, c.name);
        if (typeof r === 'string') return c.note(r);
        save('groups.json', groupsT);
        for (const o of byName.values()) if (gimOf(o) === r) { o.note(c.name + ' joined the Group Ironman group ' + r.name + '.', 0x7fd8a8); sendGroup(o); }
        return;
      }
      if (sub === 'leave' || sub === 'disband') {
        const g0 = mine && mine[1];
        const r = groupsMod.leave(groupsT, c.key, hasGimHero(c.key));
        if (r.err) return c.note(r.err);
        save('groups.json', groupsT);
        sendGroup(c);
        log(c.name + ' left the Group Ironman group ' + r.name);
        if (r.gone) {
          for (const o of byName.values()) if (gimOf(o) === g0) { o.note(c.name + ' left the Group Ironman group ' + r.name + '. Their spot stays taken.', 0x7fd8a8); sendGroup(o); }
          return c.note('You left ' + r.name + '. You can found or join another group now.', 0x7fd8a8);
        }
        return c.note('You gave up ' + r.name + ' (nobody had joined yet). Your heroes keep what they carry.', 0x7fd8a8);
      }
      if (sub === 'kick' || sub === 'remove') return c.note('Group Ironman is for good: nobody can be removed from a group (members leave by giving up all their Group Ironman heroes).');
      if (!mine) return c.note('Group Ironman: /group create Name to start a group (up to ' + groupsMod.MAX + ' accounts), or /group accept an invite. ' +
        'Group Ironman heroes trade only with their group, and share its Group Storage in the vault.', 0x7fd8a8);
      const v = groupsMod.view(mine[1], (k) => [...byName.values()].some((o) => o.key === k));
      const left = groupsMod.closed(mine[1]) ? 'Locked: no one new can join.' : 'Invites open for ' + Math.ceil(v.open / 3600000) + 'h more (/group invite name).' +
        (v.members.length === 1 ? ' While nobody has joined, /group leave gives the group up.' : '');
      return c.note('Group ' + v.name + ' (founded by ' + v.leader + '): ' + v.members.map((x) => x.name + (x.on ? ' (online)' : '')).join(', ') + '. ' + left, 0x7fd8a8);
    }
    if (cmd === '/leaders' || cmd === '/spires') {
      const lv = leaders.view(guildInfo, c.guild);
      c.note('Realm Leaders: ' + (lv.name || 'nobody yet') + (lv.me ? ' (your guild! +' + lv.luck + ' loot luck, +' + lv.xp + '% XP)' : ''), 0xffd75e);
      c.note(lv.top.length ? 'This week (realm bosses): ' + lv.top.map((r, i) => (i + 1) + '. ' + r.name + ' ' + r.kills).join('   ') : 'No guild has killed a realm boss this week yet.', 0xffd75e);
      if (c.guild) c.note('Your guild this week: ' + lv.kills + ' realm boss' + (lv.kills === 1 ? '' : 'es') + '.', 0x80ff80);
      return;
    }
    // VIP perks
    if (cmd === '/l20' || cmd === '/backpack') {
      if (!isVip(c) && !isAdmin(c)) return c.note(cmd + ' is a VIP perk. Ask the server owner about VIP.', 0xffd75e);
      return vipPerk(c, cmd);
    }
    // moderators have the moderation commands; everything else is the admins'
    if (!isAdmin(c)) {
      // testers level and max their own hero (and nobody else's)
      const testing = isTester(c) && TESTER_CMDS.has(cmd);
      if (testing && parts[1]) return c.note('Testers can only use ' + cmd + ' on themselves.');
      if (!testing && !(isMod(c) && MOD_CMDS.has(cmd))) return c.note('Only server ' + (MOD_CMDS.has(cmd) ? 'moderators' : 'admins') + ' can use ' + cmd + '.');
      // (and they can't act on staff)
      const tk = accountKey(parts[1]) || (parts[1] || '').toLowerCase();
      if (['/kick', '/ban', '/mute'].includes(cmd) && tk && (tk === ownerKey() || config.admins.some(a => lcName(a) === tk) || (config.mods || []).some(a => lcName(a) === tk)))
        return c.note('Moderators can\'t ' + cmd.slice(1) + ' other staff.');
      if (cmd === '/ban' && !(parseFloat(parts[2]) > 0 && parseFloat(parts[2]) <= MOD_BAN_HOURS)) return c.note('Moderators ban for up to ' + MOD_BAN_HOURS + ' hours: /ban name hours reason');
    }
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
      case '/announce': {
        // (to everyone online: a line in chat, and a panel across the top of their screen)
        const text = parts.slice(1).join(' ').trim().slice(0, 300);
        if (!text) return c.note('Usage: /announce your message');
        broadcast('[Announcement] ' + text);
        for (const o of online()) o.send({ t: 'announce', text, from: c.name });
        log(c.name + ' announced: ' + text);
        return;
      }
      case '/aspawn': {
        // (admins, the Admin menu: a monster or boss the server runs, so it drops real loot)
        const sm = sims && sims.get(c.world);
        if (!sm) return c.note('Nothing can be spawned here.');
        const id = String(parts[1] || ''), x = Number(parts[2]), y = Number(parts[3]);
        if (!Data.ENEMIES[id]) return c.note('No monster called ' + id + '.');
        if (!isFinite(x) || !isFinite(y) || (x - c.x) * (x - c.x) + (y - c.y) * (y - c.y) > 30 * 30) return c.note('Spawn closer to you.');
        const z = Math.max(0, Math.min(World.GOD_ZONE, sm.w.zoneAt(x, y)));
        if (!sm.spawn(id, x, y, z)) return c.note('No room to spawn there (safe zones and walls block monsters).');
        log(c.name + ' spawned ' + id + ' in ' + c.world);
        return;
      }
      case '/akill': {
        // (admins: everything here dies, and you get the loot)
        const sm = sims && sims.get(c.world);
        if (!sm) return c.note('Nothing to kill here.');
        let n = 0;
        for (const e of sm.enemies.slice()) {
          if (e.dead) continue;
          e.hitters.set(c.id, Math.max(1, e.hitters.get(c.id) || 0) + Math.ceil(e.hp));
          sm.kill(e);
          n++;
        }
        log(c.name + ' killed ' + n + ' monsters in ' + c.world);
        return c.note('Killed ' + n + ' monsters.', 0x80ff80);
      }
      case '/aevent': {
        // (admins: the realm's next event now)
        const sm = sims && sims.get(c.world);
        if (!sm || sm.kind !== 'realm') return c.note('Only works inside a realm.');
        if (sm.w.boss && !sm.w.boss.dead) return c.note('A boss is already alive here.');
        sm.w.eventT = 0;
        return c.note('An event is on its way.', 0x80ff80);
      }
      case '/siege': {
        // (admins: a Realm Siege now, in the realm you're in or the busiest one)
        const why = startSiege(realms.some((r) => realmKey(r) === c.world) ? c.world : '');
        if (why) return c.note(why);
        siege.at = Date.now() + (Number(config.siegeEveryMinutes) || 120) * 60000; siege.warned = false;
        return c.note('The siege has begun.', 0x80ff80);
      }
      case '/maxhero': {
        // (admins, for testing: the hero being played, yours or /maxhero name's, to level 20 with every stat maxed)
        const tc = parts[1] ? target : c;
        if (!tc) return c.note('Nobody called ' + parts[1] + ' is online.');
        const sv = onlineSave(tc.key), ch = serverChar(tc);
        if (!sv || !ch) return c.note((tc === c ? 'Pick a hero' : tc.name + ' has to pick a hero') + ' and enter the game first.');
        const cls = Data.CLASSES[ch.cls] || Data.CLASSES.wizard;
        ch.stats = Object.assign({}, cls.max);
        ch.skillPoints = (Number(ch.skillPoints) || 0) + Math.max(0, 20 - (Number(ch.level) || 1));
        ch.level = 20; ch.xp = 0; ch.xpNext = progress.xpFor(20); ch.ascXp = 0;
        sv.tradeSeq = (sv.tradeSeq || 0) + 1;
        store.putSave(tc.key, sv);
        setCaps(tc);
        log(c.name + ' used /maxhero on ' + tc.name + '\'s ' + (ch.name || ch.id));
        if (tc !== c) c.note('Maxed ' + tc.name + '\'s ' + (ch.name || 'hero') + '.', 0x80ff80);
        return tc.send({ t: 'saveRejected', reason: 'OK: ' + (ch.name || 'Your hero') + ' is level 20 with every stat maxed.', data: publicSave(sv) });
      }
      case '/maxtree': {
        // (admins, for testing: every skill in the hero's tree at its top rank; yours or /maxtree name's)
        const tc = parts[1] ? target : c;
        if (!tc) return c.note('Nobody called ' + parts[1] + ' is online.');
        const sv = onlineSave(tc.key), ch = serverChar(tc);
        if (!sv || !ch) return c.note((tc === c ? 'Pick a hero' : tc.name + ' has to pick a hero') + ' and enter the game first.');
        ch.skills = {};
        for (const sk of Data.SKILLS) ch.skills[sk.id] = sk.max;
        ch.tree2 = true;
        sv.tradeSeq = (sv.tradeSeq || 0) + 1;
        store.putSave(tc.key, sv);
        setCaps(tc);
        log(c.name + ' used /maxtree on ' + tc.name + '\'s ' + (ch.name || ch.id));
        if (tc !== c) c.note('Maxed ' + tc.name + '\'s skill tree.', 0x80ff80);
        return tc.send({ t: 'saveRejected', reason: 'OK: every skill in ' + (ch.name || 'your hero') + '\'s tree is at its top rank.', data: publicSave(sv) });
      }
      case '/maxasc': {
        // (admins, for testing: every Ascension perk at its top rank, for the account; yours or /maxasc name's)
        const tc = parts[1] ? target : c;
        if (!tc) return c.note('Nobody called ' + parts[1] + ' is online.');
        const sv = onlineSave(tc.key);
        if (!sv) return c.note('No save for ' + (tc === c ? 'you' : tc.name) + ' yet.');
        const a = sv.asc && typeof sv.asc === 'object' ? sv.asc : (sv.asc = { pts: 0, r: {}, n: 0 });
        if (!a.r || typeof a.r !== 'object') a.r = {};
        for (const pk of Data.ASC_PERKS) a.r[pk.id] = pk.max;
        sv.tradeSeq = (sv.tradeSeq || 0) + 1;
        store.putSave(tc.key, sv);
        setCaps(tc);
        log(c.name + ' used /maxasc on ' + tc.name);
        if (tc !== c) c.note('Maxed ' + tc.name + '\'s Ascension tree.', 0x80ff80);
        tc.send({ t: 'asc', asc: a, seq: sv.tradeSeq });
        return tc.note('Every Ascension perk is at its top rank.', 0x80ff80);
      }
      case '/give': {
        // /give name 1000 gold|fame|aether: gold and fame are the server's to hand out now
        const amount = Math.floor(Number(parts[2]));
        // /give name 3 stone, /give name 2 rune att: items into an online player's inventory (for events and testing)
        const kind = (parts[3] || '').toLowerCase();
        if (kind === 'stone' || kind === 'rune' || kind === 'stones' || kind === 'runes' || kind === 'cursed') {
          if (!target) return c.note('They have to be online to get items.');
          const ch = serverChar(target), sv = onlineSave(who);
          const stat = (parts[4] || '').toLowerCase();
          if (kind.startsWith('rune') && !Data.STATS.includes(stat)) return c.note('Usage: /give name 2 rune att (any stat: ' + Data.STATS.join(' ') + ')');
          if (kind === 'cursed' && stat && !Data.CURSES[stat]) return c.note('Usage: /give name 1 cursed [' + Data.CURSE_IDS.join('|') + ']');
          if (!ch || !Array.isArray(ch.inv) || !(amount > 0 && amount <= 16)) return c.note('Usage: /give name 3 stone, or /give name 2 rune att');
          let n = 0;
          for (let i = 0; i < ch.inv.length && n < amount; i++) {
            if (ch.inv[i]) continue;
            ch.inv[i] = items.issue(sv, kind === 'cursed' ? Data.makeCursed(Data.CLASSES[ch.cls] || Data.CLASSES.wizard, -1, stat || null) : kind.startsWith('rune') ? Data.makeRune(stat) : Data.makeStone());
            n++;
          }
          if (!n) return c.note(accounts[who].name + '\'s inventory is full.');
          log(c.name + ' gave ' + accounts[who].name + ' ' + n + ' ' + kind);
          shopDone(target, sv, ch, { market: c.name + ' gave you ' + n + ' ' + (kind === 'cursed' ? 'cursed item' : kind.startsWith('rune') ? Data.STAT_NAMES[stat] + ' Rune' : 'Evolution Stone') + (n === 1 ? '' : 's') + '.' });
          return c.note('Gave ' + accounts[who].name + ' ' + n + ' of them.', 0x80ff80);
        }
        // /give name 200 petxp: grows their active pet (events, testing)
        if (kind === 'petxp') {
          const sv = onlineSave(who), p = sv.pet;
          if (!p || !(amount > 0 && amount <= 100000)) return c.note('Usage: /give name 200 petxp (they need a pet)');
          const max = (Data.PET_RARITIES[p.rarity] || { max: 30 }).max;
          p.level = Number(p.level) || 1;
          p.xp = (Number(p.xp) || 0) + amount;
          while (p.level < max && p.xp >= Data.petXpNeeded(p.level)) { p.xp -= Data.petXpNeeded(p.level); p.level++; }
          if (p.level >= max) p.xp = 0;
          sv.tradeSeq = (sv.tradeSeq || 0) + 1;
          store.putSave(who, sv);
          log(c.name + ' gave ' + accounts[who].name + '\'s pet ' + amount + ' XP');
          if (target) { const ch = serverChar(target); if (ch) shopDone(target, sv, ch, { pet: p, petxp: amount }); }
          return c.note(accounts[who].name + '\'s pet is level ' + p.level + ' now.', 0x80ff80);
        }
        // /give name [count] item name: any item by name (the catalogue: uniques, Godly pieces, potions,
        // runes, keys, "T7 Armor", "Starforged Ring", "Bloodbound Weapon"...), into an online player's inventory
        const currency = { gold: 1, fame: 1, aether: 1, onrane: 1 };
        if (parts.length >= 3 && !(parts.length <= 4 && (parts.length === 3 ? Number.isFinite(amount) : currency[kind]))) {
          const counted = Number.isFinite(amount) && parts.length > 3;
          const count = counted ? amount : 1;
          const query = parts.slice(counted ? 3 : 2).join(' ');
          if (!who || !accounts[who]) return c.note('No account called ' + parts[1] + '.');
          if (!target) return c.note(accounts[who].name + ' has to be online to get items.');
          if (!(count > 0 && count <= 16)) return c.note('Give 1 to 16 at a time: /give name [count] item name');
          const found = Data.findCatalog(query, 8);
          if (!found.length) return c.note('No item called "' + query + '". Try part of its name, e.g. /give ' + parts[1] + ' starforged armor');
          if (found.length > 1) return c.note('Which one? ' + found.map((e) => e.name).join(', ') + (found.length >= 8 ? '...' : ''), 0xffd75e);
          const ch = serverChar(target), sv = onlineSave(who);
          if (!ch || !Array.isArray(ch.inv)) return c.note(accounts[who].name + ' has to pick a hero and enter the game first.');
          const cls = Data.CLASSES[ch.cls] || Data.CLASSES.wizard;
          let n = 0, name = found[0].name;
          for (let i = 0; i < ch.inv.length && n < count; i++) {
            if (ch.inv[i]) continue;
            const it = Data.makeCatalogItem(found[0], cls);
            if (!it) break;
            name = it.name;
            ch.inv[i] = items.issue(sv, it);
            n++;
          }
          if (!n) return c.note(accounts[who].name + '\'s inventory is full.');
          log(c.name + ' gave ' + accounts[who].name + ' ' + n + ' x ' + name);
          shopDone(target, sv, ch, { market: c.name + ' gave you ' + (n > 1 ? n + ' x ' : '') + name + '.' });
          return c.note('Gave ' + accounts[who].name + ' ' + (n > 1 ? n + ' x ' : '') + name + (n < count ? ' (their inventory filled up)' : '') + '.', 0x80ff80);
        }
        const what = { gold: 'gold', fame: 'fame', aether: 'onrane', onrane: 'onrane' }[(parts[3] || 'gold').toLowerCase()];
        if (!who || !accounts[who] || !(Math.abs(amount) > 0 && Math.abs(amount) <= 10000000) || !what) return c.note('Usage: /give name amount gold|fame|aether, or /give name [count] item name');
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
      case '/rename': {
        // /rename name newname: change an account's name (what everyone sees); its heroes, items and all stay
        const nn = parts[2] || '';
        if (!accounts[who] || !nn) return c.note('Usage: /rename name newname (or #number newname). For a hero\'s name: /heroname');
        if (!/^[A-Za-z0-9]{3,12}$/.test(nn)) return c.note('Names are 3-12 letters or numbers.');
        const nk = nn.toLowerCase();
        if (nk !== who && accounts[nk]) return c.note('The name ' + nn + ' is already taken.');
        const was = accounts[who].name;
        renameAccount(who, nn);
        log(c.name + ' renamed ' + was + ' to ' + nn);
        store.appendLog('admin.log', new Date().toISOString() + ' ' + c.name + ' renamed the account ' + was + ' to ' + nn);
        return c.note('Renamed ' + was + ' to ' + nn + ' (#' + accounts[nk].no + '). They log in with the new name and the same password.', 0x80ff80);
      }
      case '/heroname': {
        // /heroname name heroname newname: rename one of an account's heroes
        const hn = (parts[2] || '').toLowerCase(), nn = parts[3] || '';
        if (!accounts[who] || !hn || !nn) return c.note('Usage: /heroname accountname heroname newname (see /whois for the heroes)');
        if (!/^[A-Za-z0-9]{2,12}$/.test(nn)) return c.note('Hero names are 2-12 letters or numbers.');
        const sv = onlineSave(who);
        const h = (sv.chars || []).find((x) => x && String(x.name || '').toLowerCase() === hn);
        if (!h) return c.note(accounts[who].name + ' has no hero called ' + parts[2] + '. /whois ' + accounts[who].name + ' lists them.');
        const was = h.name;
        h.name = nn;
        // (newer than any save the game has in flight, so the old name can't come back)
        sv.tradeSeq = (sv.tradeSeq || 0) + 1;
        store.putSave(who, sv);
        if (target) { target.send({ t: 'kicked', msg: 'An admin renamed your hero ' + was + ' to ' + nn + '. Log in again to carry on.' }); target.close(true); }
        log(c.name + ' renamed ' + accountTag(who) + '\'s hero ' + was + ' to ' + nn);
        store.appendLog('admin.log', new Date().toISOString() + ' ' + c.name + ' renamed ' + accountTag(who) + '\'s hero ' + was + ' to ' + nn);
        return c.note('Renamed ' + accountTag(who) + '\'s hero ' + was + ' to ' + nn + '.', 0x80ff80);
      }
      case '/bugs': {
        // /bugs: the window of bug reports; /bugs done 12 marks one fixed; /bugs clear forgets the fixed ones
        const sub = (parts[1] || '').toLowerCase();
        if (sub === 'done' || sub === 'open') {
          const b = bugs.list.find((e) => e.id === (Number(parts[2]) | 0));
          if (!b) return c.note('Usage: /bugs done number');
          b.done = sub === 'done';
          b.by = c.name;
          save('bugs.json', bugs);
          // (and its forum post hears about it)
          if (b.thread && bugForum.on) bugForum.post(b.done ? '✅ Marked fixed by **' + desc(c.name) + '**.' : '🔁 Reopened by **' + desc(c.name) + '**.', b.done ? 0x60d060 : 0xffa040, { thread: b.thread });
        } else if (sub === 'clear') {
          bugs.list = bugs.list.filter((e) => !e.done);
          save('bugs.json', bugs);
          c.note('Cleared the fixed reports.', 0x80ff80);
        }
        return c.send({ t: 'bugs', list: bugs.list.slice(0, 150) });
      }
      case '/flags': {
        // /flags: the window of everyone the anti-cheat flagged; /flags clear name: forget one (checked, honest)
        if ((parts[1] || '').toLowerCase() === 'clear') {
          const k = accountKey(parts[2] || '');
          if (!k || !flags[k]) return c.note('Usage: /flags clear name (someone on the list)');
          delete flags[k];
          store.saveTable('flags.json', flags);
          c.note('Cleared ' + (accounts[k] ? accounts[k].name : parts[2]) + ' from the flagged list.', 0x80ff80);
        }
        return c.send({ t: 'flags', list: flagList() });
      }
      case '/realms': {
        // /realms n: how many realms are open (extra ones close once empty); /realms min max to let more open as they fill
        const lo = Math.floor(Number(parts[1])), hi = parts[2] === undefined ? lo : Math.floor(Number(parts[2]));
        if (!(lo >= 1 && lo <= 6 && hi >= lo && hi <= 6)) return c.note('Usage: /realms n (1 to 6), or /realms min max. Now: ' + config.minRealms + (config.maxRealms !== config.minRealms ? ' to ' + config.maxRealms : '') + ' (' + realms.length + ' open).');
        config.minRealms = lo; config.maxRealms = hi; config.realmsSet = true;
        saveConfig(['minRealms', 'maxRealms', 'realmsSet']);
        updateRealms();
        log(c.name + ' set realms to ' + lo + (hi !== lo ? '-' + hi : ''));
        return c.note('Realms: ' + lo + (hi !== lo ? ' (up to ' + hi + ' as they fill)' : '') + '. Extra realms close once they\'re empty.', 0x80ff80);
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
      case '/tester': case '/untester': {
        // /tester name, /untester name: testers (saved in config.json)
        if (!who || !accounts[who]) return c.note('Usage: ' + cmd + ' name   (/testers lists them)');
        const name = accounts[who].name || parts[1];
        const list = Array.isArray(config.testers) ? config.testers : [];
        const has = list.some((a) => lcName(a) === who);
        if (cmd === '/tester') {
          if (has) return c.note(name + ' is already a tester.');
          if (config.admins.some((a) => lcName(a) === who)) return c.note(name + ' is an admin: they have every tool already.');
          config.testers = list.concat([name]);
        } else {
          if (!has) return c.note(name + ' is not a tester.');
          config.testers = list.filter((a) => lcName(a) !== who);
        }
        saveConfig(['testers']);
        log(c.name + (cmd === '/tester' ? ' made ' + name + ' a tester' : ' removed ' + name + ' from the testers'));
        if (target) {
          target.send({ t: 'role', role: roleOf(target), vip: isVip(target), tester: isTester(target) });
          target.note(cmd === '/tester' ? c.name + ' made you a tester: press ` (or /admin) for the testing tools. What they make stays with you: no trading, selling or dropping.' : 'You are no longer a tester.', 0x80ff80);
          setCaps(target);
        }
        return c.note(name + (cmd === '/tester' ? ' is now a tester.' : ' is no longer a tester.'), 0x80ff80);
      }
      case '/gimremove': {
        // /gimremove name: take someone out of their Group Ironman group (a mistake, a test account); frees the spot
        if (!who || !accounts[who]) return c.note('Usage: /gimremove name');
        const name = accounts[who].name || parts[1];
        const r = groupsMod.remove(groupsT, who);
        if (r.err) return c.note(name + ': ' + r.err);
        save('groups.json', groupsT);
        log(c.name + ' took ' + name + ' out of the Group Ironman group ' + r.name);
        for (const o of byName.values()) if (o.key === who || (groupsT[r.name.toLowerCase()] && gimOf(o) === groupsT[r.name.toLowerCase()])) sendGroup(o);
        if (target) target.note('An admin took you out of the Group Ironman group ' + r.name + '. You can found or join another group now.', 0x7fd8a8);
        return c.note('Took ' + name + ' out of ' + r.name + (r.emptied ? ' (nobody was left, so the group is gone)' : '') + '.', 0x80ff80);
      }
      case '/testers':
        return c.note('Testers: ' + ((config.testers || []).join(', ') || 'none'), 0x80ff80);
      case '/mod': case '/unmod': {
        // /mod name, /unmod name: moderators (saved in config.json)
        if (!who || !accounts[who]) return c.note('Usage: ' + cmd + ' name');
        const name = accounts[who].name || parts[1];
        const mods = Array.isArray(config.mods) ? config.mods : [];
        const has = mods.some((a) => lcName(a) === who);
        if (cmd === '/mod') {
          if (has) return c.note(name + ' is already a moderator.');
          config.mods = mods.concat([name]);
        } else {
          if (!has) return c.note(name + ' is not a moderator.');
          config.mods = mods.filter((a) => lcName(a) !== who);
        }
        saveConfig(['mods']);
        log(c.name + (cmd === '/mod' ? ' made ' + name + ' a moderator' : ' removed ' + name + ' from the moderators'));
        if (target) { target.send({ t: 'role', role: roleOf(target), vip: isVip(target) }); target.note(cmd === '/mod' ? c.name + ' made you a moderator. Type /help to see your commands.' : 'You are no longer a moderator.', 0x80ff80); }
        return c.note(name + (cmd === '/mod' ? ' is now a moderator.' : ' is no longer a moderator.'), 0x80ff80);
      }
      case '/mods':
        return c.note('Owner: ' + (accounts[ownerKey()] ? accounts[ownerKey()].name : ownerKey() || 'none') + '   Admins: ' + (config.admins.join(', ') || 'none') + '   Moderators: ' + ((config.mods || []).join(', ') || 'none') + '   Testers: ' + ((config.testers || []).join(', ') || 'none'), 0x80ff80);
      case '/vip': case '/unvip': {
        // /vip name [days] (none: for good), /unvip name
        if (!who || !accounts[who]) return c.note('Usage: /vip name [days]  (no days: for good)   /unvip name   /vips');
        const name = accounts[who].name || parts[1];
        if (cmd === '/vip') {
          const days = parseFloat(parts[2]);
          const from = isVipKey(who) && vips[who].until ? vips[who].until : Date.now();
          vips[who] = { until: days > 0 ? from + days * 86400000 : 0, by: c.name, at: Date.now() };
        } else {
          if (!vips[who]) return c.note(name + ' is not a VIP.');
          delete vips[who];
        }
        save('vips.json', vips);
        const v = vips[who];
        const left = v ? (v.until ? Math.ceil((v.until - Date.now()) / 86400000) + ' days' : 'for good') : '';
        log(c.name + (v ? ' made ' + name + ' a VIP (' + left + ')' : ' removed ' + name + '\'s VIP'));
        if (target) {
          target.vip = isVip(target);
          target.send({ t: 'role', role: roleOf(target), vip: target.vip });
          target.note(v ? 'You are a VIP (' + left + ')! /l20 levels your hero to 20, /backpack gives it a backpack, and you find a little more loot. Thank you!' : 'Your VIP has ended. Thanks for your support!', 0xffd75e);
        }
        return c.note(v ? name + ' is a VIP (' + left + ').' : name + ' is no longer a VIP.', 0x80ff80);
      }
      case '/vips': {
        const now = Date.now();
        const list = Object.keys(vips).filter(isVipKey).map((k) => (accounts[k] ? accounts[k].name : k) + (vips[k].until ? ' (' + Math.ceil((vips[k].until - now) / 86400000) + 'd)' : ''));
        return c.note('VIPs: ' + (list.join(', ') || 'none'), 0xffd75e);
      }
      case '/admin': {
        // /admin name: make an account an admin (saved in config.json, so it lasts)
        if (!isOwner(c) && parts[1]) return c.note('Only the server owner can make admins.');
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
        if (!isOwner(c)) return c.note('Only the server owner can remove admins.');
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

// ------------------------------------------------------------------ roles: moderator commands and VIP perks
/** What testers may use, on themselves only. */
const TESTER_CMDS = new Set(['/maxhero', '/maxtree', '/maxasc']);
/** What moderators may use (admins and the owner have everything). */
const MOD_CMDS = new Set(['/kick', '/mute', '/unmute', '/ban', '/unban', '/whois', '/graves', '/flags', '/bugs', '/mods', '/vips']);
const MOD_BAN_HOURS = 72;

/** /l20 (the hero you're playing goes to level 20) and /backpack (it gets a backpack). */
function vipPerk(c, cmd) {
  const sv = onlineSave(c.key), ch = serverChar(c);
  if (!sv || !ch) return c.note('Pick a hero and enter the game first.');
  if (cmd === '/backpack') {
    if (ch.backpack) return c.note((ch.name || 'This hero') + ' already has a backpack.');
    ch.backpack = true;
    if (!Array.isArray(ch.inv)) ch.inv = [];
    while (ch.inv.length < 16) ch.inv.push(null);
    log(c.name + ' used VIP /backpack on ' + (ch.name || ch.id));
    return shopDone(c, sv, ch, { backpack: true });
  }
  if (modes.restricted(modes.modeOf(ch))) return c.note('VIP levelling doesn\'t work on ' + modes.nameOf(modes.modeOf(ch)) + ' heroes: they earn every level.');
  const L = Math.max(1, Number(ch.level) || 1);
  if (L >= 20) return c.note((ch.name || 'This hero') + ' is already level 20.');
  // the levels, the stats they grow, the XP they took and a skill point each
  const cls = Data.CLASSES[ch.cls] || Data.CLASSES.wizard;
  const lv = 20 - L;
  if (!ch.stats || typeof ch.stats !== 'object') ch.stats = Object.assign({}, cls.base);
  for (const k of Data.STATS) ch.stats[k] = Math.min(cls.max[k], (Number(ch.stats[k]) || cls.base[k] || 0) + Data.grow(cls, k) * lv);
  let xp = -(Number(ch.xp) || 0);
  for (let l = L; l < 20; l++) xp += progress.xpFor(l);
  ch.totalXp = (Number(ch.totalXp) || 0) + Math.max(0, xp);
  ch.level = 20; ch.xp = 0; ch.xpNext = progress.xpFor(20); ch.ascXp = 0;
  ch.skillPoints = (Number(ch.skillPoints) || 0) + lv;
  sv.tradeSeq = (sv.tradeSeq || 0) + 1;
  store.putSave(c.key, sv);
  setCaps(c);
  log(c.name + ' used VIP /l20 on ' + (ch.name || ch.id) + ' (was level ' + L + ')');
  c.send({ t: 'saveRejected', reason: 'VIP: ' + (ch.name || 'your hero') + ' is level 20! (+' + lv + ' skill points)', data: publicSave(sv) });
}

// ------------------------------------------------------------------ bug reports (/bug, /bugs)
const bugs = load('bugs.json', { next: 0, list: [] });
if (!Array.isArray(bugs.list)) bugs.list = [];

// ------------------------------------------------------------------ godmode checks
const { godmodeVerdict, damageVerdict } = require('./godmode');

/**
 * The anti-cheat never disconnects or kills anyone (honest players were caught by
 * it): it only flags. Each flag goes to anticheat.log and to the account's line in
 * flags.json, and online admins are told (once every 5 minutes per player and kind).
 * Admins see every flagged player with /flags and decide for themselves (/kick, /ban).
 */
const flags = store.loadTable('flags.json', {});
const FLAG_KEEP = 200, FLAG_NOTES = 8;
function flag(c, kind, note) {
  const now = Date.now();
  store.appendLog('anticheat.log', new Date(now).toISOString() + ' ' + c.name + ' [' + kind + ']: ' + note);
  if (!c.key) return;
  const f = flags[c.key] || (flags[c.key] = { name: c.name, n: 0, first: now, last: 0, kinds: {}, notes: [] });
  f.name = c.name;
  f.n++;
  f.last = now;
  f.kinds[kind] = (f.kinds[kind] || 0) + 1;
  f.notes.unshift({ at: now, kind, note: String(note).slice(0, 200), world: String(c.world || '').split(':')[0] });
  if (f.notes.length > FLAG_NOTES) f.notes.length = FLAG_NOTES;
  // only the most recently flagged accounts are kept
  const keys = Object.keys(flags);
  if (keys.length > FLAG_KEEP) {
    keys.sort((a, b) => flags[a].last - flags[b].last);
    for (const k of keys.slice(0, keys.length - FLAG_KEEP)) delete flags[k];
  }
  store.saveTable('flags.json', flags);
  if (!c.flagTold) c.flagTold = {};
  if (now - (c.flagTold[kind] || 0) > 300000) {
    c.flagTold[kind] = now;
    for (const a of byName.values()) if (isAdmin(a)) a.note('[Anti-cheat] ' + c.name + ' (' + kind + '): ' + note + '  (/flags to see everyone flagged)', 0xffb040);
  }
}

/** The flagged accounts, most recent first (for the /flags window). */
function flagList() {
  return Object.keys(flags).sort((a, b) => flags[b].last - flags[a].last).map((k) => {
    const f = flags[k];
    return { name: (accounts[k] && accounts[k].name) || f.name, no: (accounts[k] && accounts[k].no) || 0, online: byName.has(k),
      n: f.n, first: f.first, last: f.last, kinds: f.kinds, notes: f.notes };
  });
}

// ------------------------------------------------------------------ server health (/stats)
/** NEWREALM_SLOW_LOG=1: log any message that takes the server over 30 ms (for load tests). */
const SLOW_LOG = !!process.env.NEWREALM_SLOW_LOG;
const counters = { startedAt: Date.now(), godmodeFlags: 0, savesCut: 0, savesRefused: 0, peak: 0 };
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
  lines.push('Anti-cheat since start: ' + counters.godmodeFlags + ' godmode flags (flag only: /flags), ' +
    counters.savesCut + ' saves cut back, ' + counters.savesRefused + ' refused');
  return lines;
}

/** Every 10 seconds: compare each player's expected and reported hits since they entered the world (or the last check that settled it). */
function godmodeCheck() {
  for (const c of clients.values()) {
    if (!c.authed || isAdmin(c) || !c.sim) continue;
    const exp = (c.expHits || 0) - (c.expBase || 0), took = (c.hitsRep || 0) - (c.hitsBase || 0);
    const v = godmodeVerdict(exp, took);
    // the damage those hits did, and the health the game says it has
    const expD = (c.expDmg || 0) - (c.expDmgBase || 0), tookD = (c.dmgRep || 0) - (c.dmgBase || 0);
    const dmgBad = c.sendsDmg && damageVerdict(exp, expD, tookD);
    const hpBad = (c.hpOver || 0) >= 6;
    // (a game that never says what damage it took is too old, or changed: it has to be the current one)
    const silent = !c.sendsDmg && exp >= 40;
    if (dmgBad || hpBad || silent) {
      const note = c.name + (dmgBad ? ' took ' + Math.round(tookD) + ' damage from hits that did at least ' + Math.round(expD) + ' (' + exp + ' clean hits)'
        : hpBad ? ' has ' + c.hpSeen.hp + '/' + c.hpSeen.mhp + ' health, more than its hero can have (' + c.hpSeen.top + ')' : '\'s game does not report the damage it takes');
      log('anti-cheat ' + note);
      counters.godmodeFlags++;
      flag(c, dmgBad ? 'damage taken' : hpBad ? 'health' : 'old game', note.slice(c.name.length).replace(/^'s /, '').trim());
      if (silent && !c.toldOld) { c.toldOld = true; c.note('Your game is out of date. Open it again to get the latest version.', 0xff8080); }
      if (hpBad) c.hpOver = 0;
    }
    if (v) {
      const note = c.name + ' took ' + took + ' of ' + exp + ' clean monster hits (godmode?)';
      log('godmode ' + note);
      counters.godmodeFlags++;
      flag(c, 'hits ignored', 'took ' + took + ' of ' + exp + ' clean monster hits');
    }
    // a settled window starts again (so an old good record can't hide new cheating)
    if (exp >= 60 || v) { c.expBase = c.expHits || 0; c.hitsBase = c.hitsRep || 0; c.expDmgBase = c.expDmg || 0; c.dmgBase = c.dmgRep || 0; }
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
    flag(c, 'movement', '15 impossible moves in a minute (' + why + ') in ' + c.world);
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
  // level and gear as the server knows them (the game's own claim is never shown to others)
  const ch = sims && !isAdmin(c) ? serverChar(c) : null;
  if (ch) {
    p.level = Math.max(1, Math.min(20, Number(ch.level) | 0));
    if (Data.CLASSES[ch.cls]) p.cls = ch.cls;
    p.equip = [ch.weapon, ch.ability, ch.armor, ch.ring].map((it) => (it && typeof it === 'object' && JSON.stringify(it).length < 4000 ? it : null));
  }
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
    o.send({ t: 'guild', guild: { name: g.name, myRank: g.members[o.key].rank, members, banner: g.banner || '', leader: leaders.isLeader(gk) } });
    sendLeaders(o);
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
      try { h(c, m); } catch (e) { log('error handling', m.t, e.message, (e.stack || '').split('\n').slice(1, 4).join(' | ')); }
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
  // the logged Discord channels, for the owner (and Claude): needs the key from config "discordLogKey" in an X-Log-Key header
  if (pathOnly === '/discordlog') {
    const want = String(config.discordLogKey || '');
    const got = String((/^x-log-key:[ \t]*(\S+)/im.exec(req) || [])[1] || '');
    let ok = want.length >= 24 && got.length === want.length;
    if (ok) ok = crypto.timingSafeEqual(Buffer.from(got), Buffer.from(want));
    const q = (k) => decodeURIComponent((new RegExp('[?&]' + k + '=([^&]*)').exec(url) || [])[1] || '');
    const txt = ok ? discordLogText(Number(q('n')) || 300, Number(q('since')) || 0, q('ch')) + '\n' : 'Not allowed.\n';
    if (!ok) log('discordlog: refused a request from ' + sock.remoteAddress);
    sock.end(head('text/plain; charset=utf-8', Buffer.byteLength(txt)) + txt);
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
// ------------------------------------------------------------------ Realm Leaders
const { Leaders, WEEK_FAME: LEADER_FAME } = require('./leaders');
const leaders = new Leaders(load('leaders.json', {}));
const guildInfo = (gk) => guilds[gk] ? { name: guilds[gk].name || gk, banner: guilds[gk].banner || '' } : null;
/** The leaders' loot luck (WorldSim.dropLoot reads it). */
function leaderLuck() {
  WorldSim.guildLuck = leaders.leader ? { [leaders.leader]: leaders.luck(leaders.leader) } : {};
}
leaderLuck();
/** Everyone online hears who leads, and their guild's count this week. */
function sendLeaders(c) { if (c && c.authed) c.send({ t: 'leaders', l: leaders.view(guildInfo, c.guild && guilds[c.guild] ? c.guild : '') }); }
function sendLeadersAll() { for (const o of byName.values()) sendLeaders(o); }
/** The week turned: the new leaders are crowned. */
function leaderEvents(evs) {
  for (const ev of evs) {
    if (ev.kind !== 'crown') continue;
    const g = guilds[ev.g];
    if (g) {
      g.fame = (Number(g.fame) || 0) + LEADER_FAME;
      save('guilds.json', guilds);
      for (const k in g.members) grantTitle(k, 'realmlord');
      broadcast('👑 ' + g.name + ' killed the most realm bosses last week (' + ev.kills + '): they are the Realm Leaders! Their members find more loot and gain more XP all week. (+' + LEADER_FAME + ' guild fame)', 0xffd75e);
      log(g.name + ' crowned Realm Leaders (' + ev.kills + ' realm bosses)');
      feat('leaders', { guild: g.name, kills: ev.kills });
    } else broadcast('A new week: nobody holds the realms. Kill realm bosses with your guild to be crowned Realm Leaders!', 0xffd75e);
  }
  if (evs.length) { leaderLuck(); sendLeadersAll(); }
  save('leaders.json', leaders.s);
}
setInterval(() => { const evs = leaders.turn(); if (evs.length) leaderEvents(evs); }, 60000).unref();

// ------------------------------------------------------------------ the Endless Abyss
/** The week's highest waves cleared, per class: deep.cls[cls] = [{key, name, hero, wave, at}] (top DEEP_KEEP). */
const DEEP_KEEP = 10;
const deep = load('deep.json', {});
if (!deep.cls || !deep.waves) { deep.cls = {}; deep.waves = true; }
const deepWeekOf = (t) => Math.floor((Math.floor(t / 86400000) + 3) / 7);
if (!deep.week) deep.week = deepWeekOf(Date.now());
/** A new week: the deepest of each class are crowned (Abyss Champion), then the board starts over. */
function deepWeek() {
  const wk = deepWeekOf(Date.now());
  if (wk === deep.week) return;
  const champs = [];
  for (const cls in deep.cls) { const top = deep.cls[cls][0]; if (top) { grantTitle(top.key, 'deepking'); champs.push(top.name + ' (' + (Data.CLASSES[cls] ? Data.CLASSES[cls].name : cls) + ', wave ' + (top.wave || 0) + ')'); } }
  if (champs.length) { broadcast('The Endless Abyss\'s champions this week: ' + champs.join(', ') + '!', 0xd080ff); feat('deepweek', { champs }); }
  deep.week = wk;
  deep.cls = {};
  save('deep.json', deep);
}
setInterval(deepWeek, 60000).unref();

/** c steps into a world: the Abyss starts a run (its boons start empty); anywhere else ends it. */
/** Runs by account, so a dropped connection rejoining the same arena keeps its boons. */
const deepRuns = new Map();
/** When each account last sent a /bug report. */
const bugAt = new Map();
function deepEnter(c, world) {
  if (!world.startsWith('deep:')) {
    if (c.key) deepRuns.delete(c.key);
    // (always say so: a game that reconnected may still think it's on a run)
    c.send({ t: 'abyssRun', on: false });
    c.abyss = null; c.abyssOffer = null;
    return;
  }
  const kept = c.key && deepRuns.get(c.key);
  if (kept && kept.key === world) c.abyss = kept;
  else if (!c.abyss || c.abyss.key !== world) c.abyss = { key: world, wave: 0, boons: [], start: Date.now() };
  if (c.key) deepRuns.set(c.key, c.abyss);
  c.abyssOffer = null;
  c.send({ t: 'abyssRun', on: true, wave: c.abyss.wave, boons: c.abyss.boons });
}

/** A wave is cleared: it counts for everyone in the arena; after every 5th, a boon to pick. */
if (sims) sims.onDeep = (sim, players, wave, chest) => {
  deepWeek();
  let changed = false;
  for (const c of players) {
    if (!c.key || !c.abyss) continue;
    c.abyss.wave = wave;
    const ch = serverChar(c);
    // the week's board (each account once per class, its best)
    if (ch && typeof ch.cls === 'string' && Object.prototype.hasOwnProperty.call(Data.CLASSES, ch.cls)) {
      const list = Object.prototype.hasOwnProperty.call(deep.cls, ch.cls) ? deep.cls[ch.cls] : (deep.cls[ch.cls] = []);
      let row = list.find((r) => r.key === c.key);
      if (!row) { row = { key: c.key, name: c.name, hero: ch.name || '', wave: 0, at: 0 }; list.push(row); }
      if (wave > (row.wave || 0)) {
        row.wave = wave; row.at = Date.now(); row.hero = ch.name || ''; row.name = c.name;
        list.sort((a, b) => (b.wave || 0) - (a.wave || 0) || a.at - b.at);
        if (list.length > DEEP_KEEP) list.length = DEEP_KEEP;
        changed = true;
        if (list[0] === row && wave >= 10 && wave % 5 === 0) feat('deep', { name: c.name, cls: Data.CLASSES[ch.cls] ? Data.CLASSES[ch.cls].name : ch.cls, wave });
      }
    }
    if (wave >= 10) grantTitle(c.key, 'deep10');
    if (wave >= 25) grantTitle(c.key, 'deep25');
    if (chest) {
      const ids = Data.DEEP_BOONS.map((b) => b.id).sort(() => Math.random() - 0.5).slice(0, 3);
      c.abyssOffer = { wave, ids };
      c.send({ t: 'abyssBoons', wave, choices: ids });
    }
    c.send({ t: 'abyssRun', on: true, wave, boons: c.abyss.boons });
  }
  if (changed) save('deep.json', deep);
  if (wave % 10 === 0 && players.length) broadcast(players.map((c) => c.name).join(', ') + ' cleared wave ' + wave + ' of the Endless Abyss!', 0xd080ff);
};

// ------------------------------------------------------------------ the Realm Siege
/** Every siegeEveryMinutes (config, default 120; 0 turns it off): a two minute warning, then the Warlord comes. */
const siege = { at: Date.now() + (Number(config.siegeFirstMinutes) || 40) * 60000, warned: false, key: '' };
function siegeRealm() {
  // the realm with the most players in it
  let best = null;
  for (const r of realms) { const sm = sims && sims.get(realmKey(r)); if (sm && !sm.w.closed && !sm.closeT && !sm.siege && (!best || r.count > best.r.count)) best = { r, sm }; }
  return best;
}
/** Starts one now (admins' /siege, or the timer). Returns why not, or ''. */
function startSiege(key) {
  // (one at a time)
  for (const r of realms) { const sm = sims && sims.get(realmKey(r)); if (sm && sm.siege) return 'There is already a siege in ' + r.name + '.'; }
  const best = key ? { sm: sims && sims.get(key), r: realms.find((r) => realmKey(r) === key) } : siegeRealm();
  if (!best || !best.sm) return 'No realm is open.';
  if (best.sm.siege) return 'There is already a siege in ' + best.r.name + '.';
  if (!best.sm.startSiege()) return 'The Warlord found no room in ' + best.r.name + '\'s Godlands.';
  for (const c of online()) c.send({ t: 'banner', text: 'THE REALM SIEGE HAS BEGUN!', color: 0xffa020, msg: 'Vorgath the Siege Warlord marches on the Godlands of ' + best.r.name + '. Beat him in 15 minutes! (/glands)', sfx: 'fanfare' });
  log('siege started in ' + best.r.name);
  feat('siegestart', { realm: best.r.name });
  return '';
}
function siegeTick() {
  const every = config.siegeEveryMinutes === undefined ? 120 : Number(config.siegeEveryMinutes);
  if (!sims || !(every > 0) || WorldSim.restartSoon) return;
  const now = Date.now();
  if (!siege.warned && now >= siege.at - 120000) {
    const best = siegeRealm();
    // nobody in a realm: try again in ten minutes
    if (!best || !best.r.count) { siege.at = now + 600000; return; }
    siege.warned = true;
    siege.key = realmKey(best.r);
    broadcast('In 2 minutes Vorgath the Siege Warlord marches on the Godlands of ' + best.r.name + '! Gather your strongest heroes.', 0xffa020);
    return;
  }
  if (siege.warned && now >= siege.at) {
    const why = startSiege(realms.some((r) => realmKey(r) === siege.key) ? siege.key : '');
    siege.warned = false;
    // (it couldn't start: try again in five minutes, warning again first, rather than repeating the warning every minute)
    siege.at = now + (why ? 300000 : every * 60000);
  }
}
setInterval(siegeTick, 5000).unref();

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
      case 'say': if (arg) { broadcast('[Server] ' + arg); for (const o of online()) o.send({ t: 'announce', text: arg.slice(0, 300), from: 'Server' }); log('said: ' + arg); } break;
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
// ------------------------------------------------------------------ Discord bot: /restart and /status from Discord
const { DiscordBot } = require('./discordbot');
/** The log of the Discord channels the bot reads: discordLog.msgs = [{id, ch, chName, at, by, bot, text, att, edited}], oldest first. */
const DISCORD_LOG_MAX = 5000;
const discordLog = load('discordlog.json', { msgs: [] });
if (!Array.isArray(discordLog.msgs)) discordLog.msgs = [];
let discordLogTimer = null;
function keepDiscordMessage(m) {
  const at = discordLog.msgs.findIndex((x) => x.id === m.id);
  if (at >= 0) { if (m.edited) Object.assign(discordLog.msgs[at], { text: m.text, att: m.att, edited: true }); else return; }
  else {
    discordLog.msgs.push(m);
    if (discordLog.msgs.length > 1 && m.at < discordLog.msgs[discordLog.msgs.length - 2].at) discordLog.msgs.sort((a, b) => a.at - b.at);
    if (discordLog.msgs.length > DISCORD_LOG_MAX) discordLog.msgs.splice(0, discordLog.msgs.length - DISCORD_LOG_MAX);
  }
  if (!discordLogTimer) discordLogTimer = setTimeout(() => { discordLogTimer = null; save('discordlog.json', discordLog); }, 5000);
}
/** The log as text: the last n messages (or those after `since`, ms), one per line. */
function discordLogText(n, since, ch) {
  let list = discordLog.msgs;
  if (ch) { const id = (discordLog.msgs.find((m) => m.chName === ch) || {}).ch; list = list.filter((m) => m.ch === ch || m.ch === id); }
  if (since > 0) list = list.filter((m) => m.at > since);
  list = list.slice(-Math.max(1, Math.min(DISCORD_LOG_MAX, n || 300)));
  const names = {};
  for (const m of discordLog.msgs) if (m.chName) names[m.ch] = m.chName;
  return list.map((m) => new Date(m.at).toISOString().slice(0, 16).replace('T', ' ') + ' #' + (m.chName || names[m.ch] || m.ch) + ' ' + m.by + (m.bot ? ' [bot]' : '') + ': ' +
    m.text.replace(/\n/g, ' / ') + (m.att && m.att.length ? ' [attached: ' + m.att.join(' ') + ']' : '') + (m.edited ? ' (edited)' : '')).join('\n');
}

const discordBot = new DiscordBot({ token: config.discordBotToken, guild: config.discordGuild, admins: Array.isArray(config.discordBotAdmins) ? config.discordBotAdmins : [],
  read: Array.isArray(config.discordReadChannels) ? config.discordReadChannels : [] }, {
  message: keepDiscordMessage,
  chatlog: (n) => discordLogText(n),
  restart: (seconds, by) => scheduleRestart(seconds, by),
  cancel: () => cancelRestart(),
  status: () => {
    let n = 0;
    for (const c of clients.values()) if (c.authed) n++;
    const left = restartLeft();
    return '🟢 **' + (config.name || 'Eldmere') + '** is up: **' + n + '** player' + (n === 1 ? '' : 's') + ' online, up for ' + Math.round(process.uptime() / 60) + ' min.' +
      (left >= 0 ? '\n🔄 Restarting in ' + (left >= 60 ? Math.ceil(left / 60) + ' min' : left + 's') + '.' : '');
  }
}, log);
if (!process.env.NEWREALM_NO_BOT) discordBot.start();

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
setInterval(updateRealms, 5000);
