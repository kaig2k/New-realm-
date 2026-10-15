'use strict';
/*
 * The item ledger: every item the server hands out (loot, shop, Key Merchant,
 * Starforge) gets an id ("sid") and its fingerprint is written into a private
 * ledger kept with the account's save. A save may only hold items from its
 * own ledger, unchanged and once each, so items can't be made up, edited or
 * copied. Trades move ledger entries between the two accounts.
 *
 * Starter gear (the tier-0 items every new character gets) needs no id.
 * Items that existed before the ledger were given ids once, when the save was
 * first loaded by this version of the server (see migrate).
 */
const crypto = require('crypto');
const { Data } = require('./sim/gen/game');

const STATS = ['hp', 'mp', 'att', 'def', 'spd', 'dex', 'vit', 'wis', 'mgt', 'luc', 'prt', 'frt'];
const CORE = ['kind', 'sub', 'ab', 'tier', 'rarity', 'uid', 'set', 'passive', 'form', 'motion', 'shots', 'dmin', 'dmax', 'rate', 'life',
  'arc', 'parallel', 'power', 'pierce', 'size', 'shape', 'col', 'curse',
  // (a tiered weapon's signature shot: Data.SIGS)
  'accel', 'walls', 'effect', 'split', 'boom'].concat(STATS);
/** Most entries one ledger keeps (old entries for items no longer held are dropped first). */
const LEDGER_MAX = 4000;

/** An object's JSON with its keys in a fixed order (the game client doesn't keep the order they came in). */
function stable(v) {
  if (Array.isArray(v)) return '[' + v.map(stable).join(',') + ']';
  if (v && typeof v === 'object') return '{' + Object.keys(v).sort().map((k) => JSON.stringify(k) + ':' + stable(v[k])).join(',') + '}';
  if (typeof v === 'number') return String(Math.round(v * 1e4) / 1e4);
  return JSON.stringify(v);
}

/** What makes an item that item (its name and other cosmetics aside). */
function fingerprint(it, keys) {
  const o = [];
  for (const k of keys || CORE) {
    let v = it[k];
    if (v === undefined || v === null || v === '' || v === false) continue;
    if (typeof v === 'number') v = Math.round(v * 1e4) / 1e4;
    else if (typeof v === 'object') v = stable(v);
    o.push(k + '=' + v);
  }
  return o.join(';');
}

/** The fields items were told apart by before weapons had signature shots (ledger entries written then). */
const CORE_V1 = CORE.filter((k) => ['accel', 'walls', 'effect', 'split', 'boom'].indexOf(k) < 0);

/** A ledger fingerprint with any object in it rewritten with its keys in order (entries written before stable()). */
function canon(f) {
  return String(f).split(';').map((part) => {
    const i = part.indexOf('=');
    const v = part.slice(i + 1);
    if (v[0] !== '{' && v[0] !== '[') return part;
    try { return part.slice(0, i + 1) + stable(JSON.parse(v)); } catch (e) { return part; }
  }).join(';');
}

/**
 * Whether ledger entry e records item it: exactly, or as written by an earlier version of the
 * server (objects in another order, or before signature shots' fields counted). An entry that
 * matches the old way is rewritten the new way.
 */
function matches(e, it) {
  const f = fingerprint(it);
  if (e.f === f) return true;
  if (canon(e.f) === f || e.f === fingerprint(it, CORE_V1) || canon(e.f) === fingerprint(it, CORE_V1)) { e.f = f; return true; }
  return false;
}

/** The tier-0 starter items of every class (no id needed). */
const STARTERS = new Set();
for (const id in Data.CLASSES) {
  const c = Data.CLASSES[id];
  STARTERS.add(fingerprint(Data.makeWeapon(c.weapon, 0)));
  STARTERS.add(fingerprint(Data.makeAbility(c.abilityType, 0)));
  STARTERS.add(fingerprint(Data.makeArmor(c.armor, 0)));
}

const newSid = () => crypto.randomBytes(9).toString('base64').replace(/[+/=]/g, 'x');

function eachItem(save, fn) {
  for (const c of save.chars || []) {
    if (!c) continue;
    for (const k of ['weapon', 'ability', 'armor', 'ring']) if (c[k]) fn(c[k]);
    for (const it of c.inv || []) if (it) fn(it);
  }
  for (const it of save.vault || []) if (it) fn(it);
  // what pets carry (the active one and those in the Stable)
  const pets = [save.pet].concat(Array.isArray(save.stable) ? save.stable : []);
  for (const p of pets) if (p && typeof p === 'object' && Array.isArray(p.bag)) for (const it of p.bag) if (it && typeof it === 'object') fn(it);
}

/** The account's ledger (server-only part of its save). */
function ledger(save) {
  if (!save._ledger || typeof save._ledger !== 'object') save._ledger = {};
  return save._ledger;
}

/** Gives a new item its id and records it for this account. */
function issue(save, item) {
  if (!item || typeof item !== 'object') return item;
  item.sid = newSid();
  ledger(save)[item.sid] = { f: fingerprint(item), t: Date.now() };
  trim(save);
  return item;
}

/** First load under the ledger: every item already in the save gets an id. */
function migrate(save) {
  if (!save) return false;
  let changed = false;
  if (!save._ledgerV) {
    eachItem(save, (it) => { if (!it.sid && !STARTERS.has(fingerprint(it))) issue(save, it); });
    save._ledgerV = 1;
    changed = true;
  }
  if (upgradeWeapons(save)) changed = true;
  return changed;
}

/**
 * Tiered weapons from before signature shots (Data.SIGS) are brought up to their tier's shot,
 * once: the same weapon and form, its ledger entry rewritten to match. Also the ones waiting in
 * the seller's market box. Returns whether anything changed.
 */
function upgradeWeapons(save) {
  let changed = false;
  const l = ledger(save);
  const up = (it, entry) => {
    if (!Data.upgradeWeapon(it)) return;
    changed = true;
    if (entry) entry.f = fingerprint(it);
    else if (it.sid && l[it.sid]) l[it.sid].f = fingerprint(it);
  };
  eachItem(save, (it) => up(it, null));
  const box = save._market;
  if (box && Array.isArray(box.returns)) for (const r of box.returns) if (r && r.item) up(r.item, r.entry);
  return changed;
}

/** The same for an item held somewhere else with its ledger entry beside it (a market listing, the guild bank). */
function upgradeHeld(item, entry) {
  if (!item || !Data.upgradeWeapon(item)) return false;
  if (entry) entry.f = fingerprint(item);
  return true;
}

/** Moves a traded item's entry from one account's ledger to another's. */
function transfer(fromSave, toSave, item) {
  if (!item || !item.sid) return;
  const from = ledger(fromSave), entry = from[item.sid];
  if (!entry) return;
  delete from[item.sid];
  ledger(toSave)[item.sid] = { f: entry.f, t: Date.now() };
}

/** Keeps the ledger to LEDGER_MAX: entries for items still held always stay. */
function trim(save) {
  const l = ledger(save);
  const keys = Object.keys(l);
  if (keys.length <= LEDGER_MAX) return;
  const held = new Set();
  eachItem(save, (it) => { if (it.sid) held.add(it.sid); });
  keys.filter((k) => !held.has(k)).sort((a, b) => l[a].t - l[b].t).slice(0, keys.length - LEDGER_MAX).forEach((k) => delete l[k]);
}

/**
 * Checks every item in a new save against the account's ledger.
 * Returns null if fine, or why it was refused.
 */
function check(prev, next) {
  const l = ledger(prev);
  const seen = new Set();
  let bad = null;
  eachItem(next, (it) => {
    if (bad) return;
    const f = fingerprint(it);
    if (!it.sid) {
      if (!STARTERS.has(f)) bad = (it.name || 'an item') + ' was not given out by the server';
      return;
    }
    if (seen.has(it.sid)) { bad = (it.name || 'an item') + ' appears twice'; return; }
    seen.add(it.sid);
    const e = l[it.sid];
    if (!e) bad = (it.name || 'an item') + ' does not belong to this account';
    else if (!matches(e, it)) bad = (it.name || 'an item') + ' was changed';
  });
  return bad;
}

/** A character's base stats can't pass its class's maximums. */
function checkStats(save) {
  for (const c of save.chars || []) {
    const cls = c && Data.CLASSES[c.cls];
    if (!cls || !c.stats) continue;
    for (const k in cls.max) if (c.stats[k] > cls.max[k] + 0.001) return 'impossible ' + k + ' on ' + (c.name || 'a character');
  }
  return null;
}

/** Takes an item's entry out of an account's ledger (it's leaving for the market). Returns the entry, or null. */
function release(save, item) {
  if (!item || !item.sid) return null;
  const l = ledger(save), e = l[item.sid];
  if (!e) return null;
  delete l[item.sid];
  return e;
}

/** Writes a market item's entry into an account's ledger (bought, or coming back to its seller). */
function adopt(save, item, entry) {
  if (!item || !item.sid || !entry) return;
  ledger(save)[item.sid] = { f: entry.f, t: Date.now() };
  trim(save);
}

/**
 * Ids of stat potions this account was given (its ledger) that `save` no longer holds: the
 * ones it may have drunk, whether from its inventory or straight from a loot bag.
 */
function unheldStat(ledger, save) {
  const held = new Set();
  eachItem(save, (it) => { if (it.sid) held.add(it.sid); });
  const out = [];
  for (const sid in ledger || {}) {
    const e = ledger[sid];
    if (e && typeof e.f === 'string' && e.f.indexOf('kind=stat;') === 0 && !held.has(sid)) out.push(sid);
  }
  return out;
}

module.exports = { fingerprint, issue, migrate, upgradeHeld, transfer, check, checkStats, eachItem, release, adopt, unheldStat, STARTERS };
