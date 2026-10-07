'use strict';
/*
 * Basic save checks. The game still runs combat and loot on players' PCs, so
 * the server can't prove every item was earned; what it can do is refuse
 * saves that are clearly impossible:
 *   - items with unknown kinds or rarities, or stats far beyond what the game
 *     can ever roll (an edited "+9999 attack" ring)
 *   - currencies jumping faster than play allows (gold set to 9,999,999)
 *   - inventories older than the last trade (an attempt to undo a trade and
 *     keep both sides' items)
 * The limits are generous on purpose: honest players should never hit them.
 */

const KINDS = new Set(['weapon', 'ability', 'armor', 'ring', 'hp', 'mp', 'stat', 'material', 'key']);
const RARITIES = new Set(['ut', 'st', 'fb', 'lg', 'ar', 'gd']);
const PASSIVES = new Set(['lifesteal', 'shards', 'frost', 'critical', 'rampage']);
const MOTIONS = new Set(['wave', 'return', 'accel', 'home']);
const STAT_CAP = { hp: 400, mp: 400, def: 130, frt: 40 };
const STATS = ['hp', 'mp', 'att', 'def', 'spd', 'dex', 'vit', 'wis', 'mgt', 'luc', 'prt', 'frt'];
const LIMITS = {
  chars: 20, inv: 16, vault: 80,
  // currency gain allowed per save: a flat allowance plus a rate per second since the last save
  // generous: selling a Godly item alone is worth 25,000 gold
  gold: [150000, 200], fame: [400000, 200], onrane: [300, 2]
};

function isNum(v) { return typeof v === 'number' && isFinite(v); }

/** Returns an error string for an impossible item, or null. */
function checkItem(it) {
  if (it === null || it === undefined) return null;
  if (typeof it !== 'object' || Array.isArray(it)) return 'not an item';
  if (!KINDS.has(it.kind)) return 'unknown item kind';
  if (it.rarity !== undefined && it.rarity !== null && !RARITIES.has(it.rarity)) return 'unknown rarity';
  if (it.tier !== undefined && (!isNum(it.tier) || it.tier < 0 || it.tier > 8)) return 'bad tier';
  if (typeof it.name === 'string' && it.name.length > 80) return 'bad name';
  for (const s of STATS) {
    if (it[s] === undefined) continue;
    if (!isNum(it[s])) return 'bad stat';
    // a weapon's "spd" is its bullet speed (older weapons may also carry a Speed roll in it)
    const cap = s === 'spd' && it.kind === 'weapon' ? 120 : STAT_CAP[s] || 150;
    if (it[s] > cap || it[s] < -60) return s + ' too high on ' + (it.name || 'an item');
  }
  if (it.kind === 'weapon') {
    if (!isNum(it.dmin) || !isNum(it.dmax) || it.dmin < 0 || it.dmax > 800 || it.dmin > it.dmax) return 'impossible damage on ' + (it.name || 'a weapon');
    if (it.shots !== undefined && (!isNum(it.shots) || it.shots < 1 || it.shots > 9)) return 'impossible shot count';
    if (it.rate !== undefined && (!isNum(it.rate) || it.rate <= 0 || it.rate > 2.5)) return 'impossible fire rate';
    if (it.life !== undefined && (!isNum(it.life) || it.life > 3)) return 'impossible range';
    if (it.passive !== undefined && it.passive !== null && !PASSIVES.has(it.passive)) return 'unknown passive';
    if (it.motion !== undefined && it.motion !== null && !MOTIONS.has(it.motion)) return 'unknown shot motion';
  }
  if (it.kind === 'ability' && it.power !== undefined && (!isNum(it.power) || it.power > 4)) return 'impossible ability power';
  return null;
}

function eachItem(save, fn) {
  for (const c of save.chars || []) {
    if (!c) continue;
    for (const it of [c.weapon, c.ability, c.armor, c.ring].concat(c.inv || [])) fn(it);
  }
  for (const it of save.vault || []) fn(it);
}

function godlyCount(save) {
  let n = 0;
  eachItem(save, (it) => { if (it && it.rarity === 'gd') n++; });
  return n;
}

/**
 * Checks a new save against the account's previous one.
 * meta: {lastSave (ms), lastGodly (ms)} kept per account by the server.
 * Returns null if fine, or the reason it was refused.
 */
function checkSave(prev, next, meta, now) {
  if (!next || typeof next !== 'object' || Array.isArray(next)) return 'not a save';
  if (next.chars !== undefined && !Array.isArray(next.chars)) return 'bad character list';
  if ((next.chars || []).length > LIMITS.chars) return 'too many characters';
  if (next.vault !== undefined && !Array.isArray(next.vault)) return 'bad vault';
  if ((next.vault || []).length > LIMITS.vault) return 'vault too big';
  for (const c of next.chars || []) {
    if (!c || typeof c !== 'object') return 'bad character';
    if ((c.inv || []).length > LIMITS.inv) return 'inventory too big';
    if (c.level !== undefined && (!isNum(c.level) || c.level < 1 || c.level > 20)) return 'impossible level';
    for (const k in c.stats || {}) if (!isNum(c.stats[k]) || c.stats[k] > 1200) return 'impossible character stats';
  }
  let bad = null;
  eachItem(next, (it) => { if (!bad) bad = checkItem(it); });
  if (bad) return bad;
  if (!prev) return null;

  // a save from before the last trade would undo it (and duplicate items)
  if ((next.tradeSeq || 0) < (prev.tradeSeq || 0)) return 'stale save (from before your last trade)';

  // items this account just traded away may not come back in its save
  const out = (meta.tradedOut || []).filter((e) => now - e.at < 15 * 60 * 1000);
  if (out.length) {
    const count = (save) => { const m = new Map(); eachItem(save, (it) => { if (it) { const k = JSON.stringify(it); m.set(k, (m.get(k) || 0) + 1); } }); return m; };
    const was = count(prev), is = count(next);
    for (const e of out) if ((is.get(e.item) || 0) > (was.get(e.item) || 0)) return 'an item you traded away is still in your save';
  }

  // currencies: a budget that refills over time, so many quick saves can't each add the full allowance
  const secs = Math.max(0, (now - (meta.lastSave || now)) / 1000);
  const budget = meta.budget || (meta.budget = {});
  const spend = {};
  for (const k of ['gold', 'fame', 'onrane']) {
    const gain = (next[k] || 0) - (prev[k] || 0);
    const lim = LIMITS[k];
    const have = Math.min(lim[0], (budget[k] === undefined ? lim[0] : budget[k]) + lim[1] * secs);
    if (gain > have) return k + ' went up too fast';
    spend[k] = have - Math.max(0, gain);
  }
  Object.assign(budget, spend);
  return null;
}

module.exports = { checkSave, checkItem, godlyCount };
