'use strict';
/*
 * The Oracle: every boss an account has killed (how many times, first and last)
 * and everything those bosses dropped for it, kept by the server as the kills
 * happen (WorldSim.dropLoot), so it can't be edited. Lives in the save as
 * `_oracle` (server-owned, like _quests):
 *
 *   b[bossId] = {n: name, k: kills, f: first, l: last, d: {itemName: {c: count, r: rarity, u: uniqueId}}}
 *   log       = rare drops, newest first: [{at, from, name, r, u}]
 */

const ITEMS_PER_BOSS = 60, LOG_KEEP = 60;
const RARE = new Set(['ut', 'st', 'fb', 'lg', 'ar', 'gd']);

function notable(it) { return !!(it && (RARE.has(it.rarity) || it.uid || it.curse || it.kind === 'material')); }

/** A boss died with c's help: count it and its drops (items: what c got, maybe none). */
function record(sv, bossId, bossName, items, now) {
  now = now || Date.now();
  const o = sv._oracle && typeof sv._oracle === 'object' ? sv._oracle : (sv._oracle = { b: {}, log: [] });
  if (!o.b) o.b = {};
  if (!Array.isArray(o.log)) o.log = [];
  const b = o.b[bossId] || (o.b[bossId] = { n: bossName, k: 0, f: now, l: 0, d: {} });
  b.n = bossName;
  b.k++;
  b.l = now;
  for (const it of items || []) {
    if (!it || !it.name) continue;
    const d = b.d[it.name] || (b.d[it.name] = { c: 0, r: it.rarity || '' });
    d.c++;
    if (it.uid) d.u = it.uid;
    if (notable(it)) {
      o.log.unshift({ at: now, from: bossName, name: it.name, r: it.rarity || '', u: it.uid || '' });
      if (o.log.length > LOG_KEEP) o.log.length = LOG_KEEP;
    }
  }
  // (only the rarest and most common names stay once a boss has dropped too many kinds)
  const names = Object.keys(b.d);
  if (names.length > ITEMS_PER_BOSS) {
    const score = (k) => (b.d[k].u ? 1e6 : 0) + (RARE.has(b.d[k].r) ? 1e5 : 0) + b.d[k].c;
    names.sort((x, y) => score(x) - score(y));
    for (const k of names.slice(0, names.length - ITEMS_PER_BOSS)) delete b.d[k];
  }
}

/** What the game is sent (/oracle): the whole record. */
function view(sv) {
  const o = sv && sv._oracle && typeof sv._oracle === 'object' ? sv._oracle : { b: {}, log: [] };
  return { b: o.b || {}, log: o.log || [] };
}

module.exports = { record, view, notable };
