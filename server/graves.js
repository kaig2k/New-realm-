'use strict';
/*
 * Fallen heroes the server keeps, so an admin can bring one back after an
 * unfair death (lag, a bug, a server restart mid-fight).
 *
 * Whenever a save drops a hero, the server's last copy of that hero goes into
 * the account's `_graves` (newest first, at most KEEP), with what the death
 * paid out in fame. Players never see or change this list. /revive puts the
 * hero back exactly as the server last saw it (items, stats, mode, season),
 * and takes back the fame the death gave, so a revive can't be used to earn a
 * hero's fame twice.
 */
const items = require('./items');

const KEEP = 20;

const clone = (o) => JSON.parse(JSON.stringify(o));

/** Heroes in prev that next no longer has, with each one's fame credit (before the wallet uses it up). */
function fallen(prev, next) {
  if (!prev || !next || !Array.isArray(prev.chars)) return [];
  const alive = new Set((Array.isArray(next.chars) ? next.chars : []).filter(Boolean).map((h) => h.id));
  const book = prev._fame && typeof prev._fame === 'object' ? prev._fame : {};
  return prev.chars.filter((h) => h && h.id && !alive.has(h.id)).map((h) => ({ hero: clone(h), book: Number(book[h.id]) || 0 }));
}

/**
 * Adds the fallen heroes to next._graves. fame: how much account fame the save
 * added (shared between them by their credit). The game's own graveyard entry,
 * when there is one, says what killed the hero.
 */
function bury(next, list, fame, now) {
  if (!list.length) return;
  const g = Array.isArray(next._graves) ? next._graves : [];
  const total = list.reduce((n, f) => n + Math.max(1, f.book), 0);
  const shown = Array.isArray(next.graves) ? next.graves : [];
  for (const f of list) {
    const h = f.hero;
    const seen = shown.find((s) => s && s.name === h.name && s.cls === h.cls);
    g.unshift({
      hero: h, at: now || Date.now(), book: f.book,
      fame: Math.max(0, Math.round((fame || 0) * Math.max(1, f.book) / total)),
      killer: seen && typeof seen.killer === 'string' ? seen.killer.slice(0, 40) : '',
      died: !!seen
    });
  }
  if (g.length > KEEP) g.length = KEEP;
  next._graves = g;
}

/** The account's fallen heroes, newest first (for /graves). */
function list(sv) { return sv && Array.isArray(sv._graves) ? sv._graves : []; }

/**
 * Brings back fallen hero number n (1 = most recent) into sv. Returns
 * {hero, fameBack} or {error}. The caller saves sv and tells the player.
 */
function revive(sv, n) {
  const g = list(sv);
  const e = g[n - 1];
  if (!e) return { error: g.length ? 'Pick a number from 1 to ' + g.length + '.' : 'This account has no fallen heroes to bring back.' };
  const hero = clone(e.hero);
  if (!Array.isArray(sv.chars)) sv.chars = [];
  if (sv.chars.some((h) => h && h.id === hero.id)) return { error: hero.name + ' is already alive.' };
  // its items belong to the account again (the ledger may have let them go since);
  // anything the account holds now as well (it shouldn't) stays where it is
  const held = new Set();
  items.eachItem(sv, (it) => { if (it.sid) held.add(it.sid); });
  const led = sv._ledger && typeof sv._ledger === 'object' ? sv._ledger : (sv._ledger = {});
  const keep = (it) => {
    if (!it || typeof it !== 'object' || !it.sid) return it;
    if (held.has(it.sid)) return null;
    held.add(it.sid);
    led[it.sid] = { f: items.fingerprint(it), t: Date.now() };
    return it;
  };
  for (const slot of ['weapon', 'ability', 'armor', 'ring']) if (hero[slot]) hero[slot] = keep(hero[slot]);
  if (Array.isArray(hero.inv)) hero.inv = hero.inv.map(keep);
  // the fame its death paid goes back, and its fame credit returns for when it dies again
  const fameBack = Math.min(Math.max(0, sv.fame || 0), e.fame || 0);
  sv.fame = Math.max(0, (sv.fame || 0) - fameBack);
  if (!sv._fame || typeof sv._fame !== 'object') sv._fame = {};
  sv._fame[hero.id] = e.book || 0;
  if (e.died) sv.deaths = Math.max(0, (sv.deaths || 0) - 1);
  // and its line in the game's graveyard goes
  if (Array.isArray(sv.graves)) {
    const i = sv.graves.findIndex((s) => s && s.name === hero.name && s.cls === hero.cls);
    if (i >= 0) sv.graves.splice(i, 1);
  }
  sv.chars.push(hero);
  g.splice(n - 1, 1);
  // newer than any save the game has in flight, so the revive can't be overwritten
  sv.tradeSeq = (sv.tradeSeq || 0) + 1;
  return { hero, fameBack };
}

module.exports = { fallen, bury, list, revive, KEEP };
