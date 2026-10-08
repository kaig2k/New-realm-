'use strict';
/*
 * Gold and fame the server has seen earned.
 *
 * When the server runs the monsters it decides every kill, so it knows what
 * each player could have earned. Every kill credits each player who hit it with
 * the most gold that kill can pay (kill gold, elite and goblin bounties, crate
 * gold, landmark hoards, the kill streak bonus), and the hero who made it with
 * the most fame it can add to that hero's death fame. A save may then only
 * raise gold by credit it really has, and account fame only when a hero dies,
 * by what that hero earned; anything above that is cut back and the game is
 * told the real totals.
 *
 * Gold credit runs out after a while (games save every few seconds), so credit
 * left over from gold spent in the game can't be turned into gold later. A
 * small allowance that refills slowly covers rounding and odd cases.
 * Spending is the game's own business: it can only lower the totals.
 */

const { Data } = require('./sim/gen/game');

const GOLD_LIFE = 20 * 60 * 1000;
/** The small allowance: [most it holds, per second]. */
const ALLOW = { gold: [500, 0.5], fame: [200, 0.25] };
/** Death fame bonuses add at most this much (see Data.fameBonuses). */
const FAME_BONUS = 2.2;

/** The account's credit kept in memory: gold [{n, at}], allowance {gold, fame}, t (last refill). */
function state(meta) {
  if (!meta.wallet) meta.wallet = { gold: [], allow: { gold: ALLOW.gold[0], fame: ALLOW.fame[0] }, t: Date.now() };
  return meta.wallet;
}

/** Fame credit per hero, kept in the save (heroes live for days): sv._fame[charId]. */
function fameBook(sv) {
  if (!sv._fame || typeof sv._fame !== 'object') sv._fame = {};
  return sv._fame;
}

/** The most gold and fame one kill of enemy e can pay a player who hit it. */
function killValue(e) {
  const d = e.def || {}, z = Math.max(0, e.zone | 0);
  // kill gold with the best Scavenger rank, and the streak bonus (5 a kill)
  let gold = Math.ceil((d.gold || Math.floor((d.xp || 0) / 6)) * 1.5) + 5;
  if (e.elite) gold += Math.floor((d.xp || 0) / 2) + 20;
  if (d.goblin) gold += (d.gold || 0) * (z + 1);
  if (d.crate) gold += 26 * (z + 1);
  if (e.site) gold += 25 + z * 25;
  // death fame: xp / 8 (streak and elite xp up to 3.5x), half a fame a kill, 150 a boss, then the bonuses
  const xpFame = (d.xp || 0) * 3.5 / 8 * FAME_BONUS;
  const fame = xpFame + (0.5 + (e.isBoss ? 150 : 0)) * FAME_BONUS;
  return { gold, fame, xpFame };
}

/** A saved hero's own fame (Player.fame), from its saved counters. */
function heroFame(c) {
  const n = (k) => Math.max(0, Number(c[k]) || 0);
  return Math.min(5000000, n('totalXp') / 8 + n('kills') * 0.5 + n('bossKills') * 150 + n('potsDrunk') * 5);
}

/** Player (meta, save, hero id) took part in killing e; near: only close by (XP, so fame, but no gold). */
function credit(meta, sv, charId, e, now, near) {
  const v = killValue(e);
  if (!near) {
    const w = state(meta);
    w.gold.push({ n: v.gold, at: now || Date.now() });
    if (w.gold.length > 4000) w.gold.splice(0, w.gold.length - 4000);
  }
  if (charId) {
    const book = fameBook(sv);
    book[charId] = (book[charId] || 0) + (near ? v.xpFame : v.fame);
  }
}

function refill(w, now) {
  const secs = Math.max(0, (now - w.t) / 1000);
  w.t = now;
  for (const k in ALLOW) w.allow[k] = Math.min(ALLOW[k][0], w.allow[k] + ALLOW[k][1] * secs);
}

/** Gold credit still good. */
function goldCredit(w, now) {
  while (w.gold.length && now - w.gold[0].at > GOLD_LIFE) w.gold.shift();
  let n = 0;
  for (const g of w.gold) n += g.n;
  return n;
}

function useGold(w, n) {
  while (n > 0 && w.gold.length) {
    const g = w.gold[0];
    if (g.n > n) { g.n -= n; return 0; }
    n -= g.n;
    w.gold.shift();
  }
  return n;
}

/** Fame each cosmetic costs (skins, dyes, titles and pet skins bought with fame). */
function cosmeticCost(id) {
  const f = Data.findSkin(id);
  if (f) return f.skin.cost || 0;
  const d = Data.findDye(id) || Data.findPetSkin(id);
  if (d) return d.cost || 0;
  const t = Data.findTitle(id);
  return t && !t.earn ? t.cost || 0 : 0;
}

function owned(save) {
  const out = new Set();
  for (const k of ['skins', 'cosmetics']) {
    const o = save[k];
    if (o && typeof o === 'object') for (const id in o) if (o[id]) out.add(id);
  }
  return out;
}

/**
 * Checks a new save's gold and fame against what the account earned, and cuts
 * them back if needed. prev is the stored save, next the game's (changed in
 * place; it also takes over the fame book). Returns null if all was fine, or a
 * note on what was cut back.
 */
function settle(prev, next, meta, now) {
  now = now || Date.now();
  const w = state(meta);
  refill(w, now);
  const notes = [];

  // ---- gold: gains up to the credit, plus achievements reached for the first time
  const pd = (prev.ach && prev.ach.done) || {}, nd = (next.ach && next.ach.done) || {};
  let achGold = 0;
  for (const a of Data.ACHIEVEMENTS) if (nd[a.id] && !pd[a.id]) achGold += a.gold || 0;
  const pg = Math.max(0, prev.gold || 0);
  let gain = (Number(next.gold) || 0) - pg;
  if (!isFinite(gain)) gain = 0;
  if (gain > 0) {
    let left = gain - achGold;
    if (left > 0) {
      const take = Math.min(left, goldCredit(w, now));
      useGold(w, take);
      left -= take;
    }
    // anything beyond the credit comes out of the allowance
    if (left > 0) {
      const a = Math.min(left, w.allow.gold);
      w.allow.gold -= a;
      left -= a;
    }
    if (left > 0) {
      next.gold = Math.floor(pg + gain - left);
      notes.push('gold cut back by ' + Math.round(left));
    }
  }

  // ---- fame: rises only when heroes die (by what each earned), less what cosmetics cost
  // (heroes from before the server kept count start with what they had already earned)
  if (!prev._fame) {
    const b = fameBook(prev);
    for (const c of prev.chars || []) if (c && c.id) b[c.id] = heroFame(c) * FAME_BONUS;
  }
  const book = fameBook(prev);
  // stat potions drunk (5 fame each): as many as really left the account's items
  const stat = (sv) => { let k = 0; for (const c of sv.chars || []) if (c) for (const it of [].concat(c.inv || [])) if (it && it.kind === 'stat') k++;
    for (const it of sv.vault || []) if (it && it.kind === 'stat') k++; return k; };
  let gone = Math.max(0, stat(prev) - stat(next));
  for (const c of next.chars || []) {
    if (!c || !gone) continue;
    const was = (prev.chars || []).find((o) => o && o.id === c.id);
    const drunk = Math.min(gone, Math.max(0, (Number(c.potsDrunk) || 0) - (was ? Number(was.potsDrunk) || 0 : 0)));
    if (drunk > 0) { book[c.id] = (book[c.id] || 0) + drunk * 5 * FAME_BONUS; gone -= drunk; }
  }
  const alive = new Set((next.chars || []).filter(Boolean).map((c) => c.id));
  let earned = 0;
  for (const c of prev.chars || []) {
    if (!c || alive.has(c.id)) continue;
    earned += book[c.id] || 0;
    delete book[c.id];
  }
  for (const id in book) if (!alive.has(id) && !(prev.chars || []).some((c) => c && c.id === id)) delete book[id];
  const newly = [...owned(next)].filter((id) => !owned(prev).has(id));
  let spent = 0;
  for (const id of newly) spent += cosmeticCost(id);
  const pf = Math.max(0, prev.fame || 0);
  let room = earned + w.allow.fame;
  if (pf + room < spent) {
    // bought more than the account had: those purchases don't count
    for (const k of ['skins', 'cosmetics']) {
      if (!next[k] || typeof next[k] !== 'object') continue;
      for (const id of newly) if (next[k][id] && !(prev[k] && prev[k][id])) delete next[k][id];
    }
    notes.push('cosmetics refused (not enough fame)');
    spent = 0;
  }
  const fgain = (Number(next.fame) || 0) - pf + spent;
  if (fgain > 0) {
    const fromAllow = Math.max(0, fgain - earned);
    if (fromAllow > w.allow.fame) {
      next.fame = Math.floor(pf - spent + earned + w.allow.fame);
      notes.push('fame cut back by ' + Math.round(fromAllow - w.allow.fame));
      w.allow.fame = 0;
    } else w.allow.fame -= fromAllow;
  }
  if (!isFinite(Number(next.fame))) next.fame = pf;
  next._fame = book;
  return notes.length ? notes.join(', ') : null;
}

module.exports = { credit, settle, killValue, GOLD_LIFE, ALLOW };
