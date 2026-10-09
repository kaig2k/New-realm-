'use strict';
/*
 * The Guild Hall (Nexus): what a guild shares.
 *
 * Bank: 24 slots any member can put items into; members (not Initiates) can
 * take them out. An item leaves its giver's save and ledger and waits in the
 * guild's record, and whoever takes it gets it with its ledger entry, so it
 * stays a real server-given item (like the Marketplace).
 *
 * Weekly goals: three goals a week, the same for every guild, counted by the
 * server from what members really do (the same things quests count). Each
 * goal finished adds guild fame; finishing all three unlocks that week's
 * banner for good, which the guild's leaders can fly. Guild fame also grows
 * with the fame of members' fallen heroes, and guilds are ranked by it.
 */
const items = require('./items');
const { Data } = require('./sim/gen/game');

const BANK_SLOTS = 24;
/** Ranks (see server.js RANKS): Initiates can only put items in. */
const TAKE_RANK = 1, BANNER_RANK = 3;

const GOALS = [
  { id: 'kills', ev: 'kills', n: 4000, text: 'Slay 4,000 monsters', fame: 400 },
  { id: 'godkills', ev: 'godkills', n: 900, text: 'Slay 900 monsters in the Godlands', fame: 500 },
  { id: 'events', ev: 'events', n: 15, text: 'Defeat 15 realm event bosses', fame: 500 },
  { id: 'dungeons', ev: 'dungeon', n: 25, text: 'Clear 25 dungeons', fame: 500 },
  { id: 'elites', ev: 'elites', n: 80, text: 'Slay 80 elite monsters', fame: 400 },
  { id: 'pieces', ev: 'pieces', n: 60, text: 'Break 60 set-piece wards, menders or hazards', fame: 400 },
  { id: 'elder', ev: 'elder', n: 4, text: 'Defeat the Dark Elder (or a realm finale) 4 times', fame: 600 },
  { id: 'party', ev: 'partyevent', n: 10, text: 'Take down 10 realm events together (2+ players)', fame: 500 },
  { id: 'fast', ev: 'fastevent', n: 5, text: 'Kill 5 realm events in under 90 seconds', fame: 600 }
];

/** Banners (Data.GUILD_BANNERS): one is unlocked by finishing all three goals of a week (each week has its own). */
const BANNERS = Data.GUILD_BANNERS;
const GOAL_BONUS = 1000;

/** The week number (Monday to Sunday, UTC), as the rest of the server counts it. */
function weekOf(now) { return Math.floor((Math.floor((now || Date.now()) / 86400000) + 3) / 7); }

/** This week's three goals (every guild has the same ones). */
function goalsFor(week) {
  const out = [], n = GOALS.length;
  let k = ((week * 7) % n + n) % n;
  while (out.length < 3) { if (!out.includes(GOALS[k])) out.push(GOALS[k]); k = (k + 4) % n; }
  return out;
}

function bannerFor(week) { return BANNERS[((week % BANNERS.length) + BANNERS.length) % BANNERS.length]; }
function findBanner(id) { return BANNERS.find((b) => b.id === id) || null; }

/** Fills in a guild record's newer parts (guilds made before the hall have none). */
function ready(g, now) {
  if (!Array.isArray(g.bank)) g.bank = [];
  while (g.bank.length < BANK_SLOTS) g.bank.push(null);
  if (!Array.isArray(g.log)) g.log = [];
  if (!Array.isArray(g.banners)) g.banners = [];
  g.fame = Math.max(0, Number(g.fame) || 0);
  const week = weekOf(now);
  if (!g.goals || g.goals.week !== week) g.goals = { week, prog: {}, done: {} };
  return g;
}

function note(g, text) {
  g.log.unshift({ text: String(text).slice(0, 120), at: Date.now() });
  if (g.log.length > 20) g.log.length = 20;
}

/** Puts inv[slot] in the bank. Returns the item, or an error string. */
function deposit(g, sv, inv, slot, who) {
  ready(g);
  const item = inv[slot];
  if (!item || typeof item !== 'object') return 'There is nothing in that slot.';
  if (!item.sid) return 'Starter gear stays with its hero.';
  const free = g.bank.indexOf(null);
  if (free < 0) return 'The guild bank is full.';
  const entry = items.release(sv, item);
  if (!entry) return 'That item can\'t go in the bank.';
  inv[slot] = null;
  g.bank[free] = { item, entry, by: who };
  note(g, who + ' put in ' + (item.name || 'an item'));
  return item;
}

/** Takes bank slot `idx` into inv (rank: the taker's guild rank). Returns the item, or an error string. */
function withdraw(g, sv, inv, idx, rank, who) {
  ready(g);
  if (rank < TAKE_RANK) return 'Initiates can put items in the bank, but not take them out. Ask an officer to promote you.';
  const b = g.bank[idx];
  if (!b) return 'Someone took that first.';
  const slot = inv.indexOf(null);
  if (slot < 0) return 'Your inventory is full.';
  inv[slot] = b.item;
  items.adopt(sv, b.item, b.entry);
  g.bank[idx] = null;
  note(g, who + ' took ' + (b.item.name || 'an item'));
  return b.item;
}

/**
 * Something members did (evs, as in quests): counts toward this week's goals.
 * Returns what was finished: [{text, fame}] and maybe {banner} (all three done).
 */
function progress(g, evs, now) {
  ready(g, now);
  const out = [];
  const week = g.goals.week;
  const list = goalsFor(week);
  for (const goal of list) {
    if (g.goals.done[goal.id]) continue;
    const k = evs.filter((e) => e === goal.ev).length;
    if (!k) continue;
    g.goals.prog[goal.id] = Math.min(goal.n, (g.goals.prog[goal.id] || 0) + k);
    if (g.goals.prog[goal.id] >= goal.n) {
      g.goals.done[goal.id] = true;
      g.fame += goal.fame;
      out.push({ text: goal.text, fame: goal.fame });
      note(g, 'Goal done: ' + goal.text + ' (+' + goal.fame + ' guild fame)');
    }
  }
  if (out.length && list.every((goal) => g.goals.done[goal.id])) {
    const b = bannerFor(week);
    g.fame += GOAL_BONUS;
    if (!g.banners.includes(b.id)) g.banners.push(b.id);
    if (!g.banner) g.banner = b.id;
    note(g, 'All three goals done: the ' + b.name + ' banner is yours (+' + GOAL_BONUS + ' guild fame)');
    out.push({ banner: b, fame: GOAL_BONUS });
  }
  return out;
}

/** Flies one of the guild's banners (leaders only). Returns null or an error string. */
function fly(g, id, rank) {
  ready(g);
  if (rank < BANNER_RANK) return 'Only the guild\'s leaders can change its banner.';
  if (id && !g.banners.includes(id)) return 'Your guild hasn\'t earned that banner yet.';
  g.banner = id || '';
  return null;
}

/** What a member sees in the Guild Hall. guilds: every guild (for the ranking). */
function view(g, gk, guilds, rank) {
  ready(g);
  const week = g.goals.week;
  const ranking = Object.keys(guilds).map((k) => ({ k, name: guilds[k].name, fame: Math.round(Number(guilds[k].fame) || 0), members: Object.keys(guilds[k].members || {}).length }))
    .sort((a, b) => b.fame - a.fame || a.name.localeCompare(b.name));
  return {
    name: g.name, fame: Math.round(g.fame), rank, place: ranking.findIndex((r) => r.k === gk) + 1,
    bank: g.bank.map((b) => (b ? { item: b.item, by: b.by } : null)),
    log: g.log.slice(0, 8),
    goals: goalsFor(week).map((goal) => ({ text: goal.text, n: goal.n, at: g.goals.prog[goal.id] || 0, done: !!g.goals.done[goal.id], fame: goal.fame })),
    weekBanner: bannerFor(week), banner: g.banner || '', banners: g.banners.slice(),
    top: ranking.slice(0, 10).map((r) => ({ name: r.name, fame: r.fame, members: r.members })),
    canTake: rank >= TAKE_RANK, canFly: rank >= BANNER_RANK
  };
}

module.exports = { ready, deposit, withdraw, progress, fly, view, goalsFor, bannerFor, findBanner, weekOf, BANNERS, GOALS, BANK_SLOTS };
