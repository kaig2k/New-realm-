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
  'arc', 'parallel', 'power', 'pierce', 'size', 'shape', 'col'].concat(STATS);
/** Most entries one ledger keeps (old entries for items no longer held are dropped first). */
const LEDGER_MAX = 4000;

/** What makes an item that item (its name and other cosmetics aside). */
function fingerprint(it) {
  const o = [];
  for (const k of CORE) {
    let v = it[k];
    if (v === undefined || v === null || v === '' || v === false) continue;
    if (typeof v === 'number') v = Math.round(v * 1e4) / 1e4;
    else if (typeof v === 'object') v = JSON.stringify(v);
    o.push(k + '=' + v);
  }
  return o.join(';');
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
  if (!save || save._ledgerV) return false;
  eachItem(save, (it) => { if (!it.sid && !STARTERS.has(fingerprint(it))) issue(save, it); });
  save._ledgerV = 1;
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
    else if (e.f !== f) bad = (it.name || 'an item') + ' was changed';
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

module.exports = { fingerprint, issue, migrate, transfer, check, checkStats, eachItem, STARTERS };
