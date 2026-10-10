'use strict';
/*
 * Hero progress the server checks on every save (when it runs the monsters),
 * so a changed game (an "admin menu" that isn't the server's, a memory
 * editor) can't hand out levels, stats, skill points, potion slots,
 * backpacks or pets:
 *
 *   XP          kills are the only XP there is, and the server sees every one:
 *               each credits the heroes who earned it with the most XP it can
 *               give (wallet.credit, sv._xpb). A hero's XP may only rise by that
 *               credit, plus a small allowance that refills slowly.
 *   level       only as many levels as that XP buys.
 *   stats       only the growth those levels give, plus stat potions drunk
 *               (and only as many potions as really left the account).
 *   skills      one point a level, then one per 1,000+ XP at level 20.
 *   potions     the F/G slots hold at most Player.MAX_POTS.
 *   backpack    bought from the server (handlers.buy), never just claimed.
 *   pet         hatched and fed by the server (handlers.hatch, petFeed); its kind
 *               and rarity never change, and otherwise it grows only by the
 *               kills the server saw (wallet.credit, sv._petb).
 *
 * Nothing is refused outright: what doesn't add up goes back to the last
 * good save's values (loot and everything else stay), the game is sent the
 * fixed save, and the reason goes to the anti-cheat log.
 */
const { Data } = require('./sim/gen/game');
const items = require('./items');

const MAX_LEVEL = 20, MAX_POTS = 6;
const xpFor = (level) => 40 + level * 45 + level * level * 3; // Player.xpFor
/** XP allowance: [most it holds, per second] (rounding, the odd kill the server credited late). */
const ALLOW = [400, 1];
/** The progress fields that go back together when XP, level, stats or skills don't add up. */
const PROGRESS = ['level', 'xp', 'xpNext', 'totalXp', 'ascXp', 'kills', 'bossKills', 'potsDrunk', 'stats', 'skills', 'skillPoints', 'highStakes', 'tree2'];

const num = (v) => (typeof v === 'number' && isFinite(v) ? v : 0);
const clone = (o) => (o === undefined ? undefined : JSON.parse(JSON.stringify(o)));
const ranks = (h) => { let n = 0; for (const k in (h.skills && typeof h.skills === 'object' ? h.skills : {})) n += Math.max(0, num(h.skills[k])); return n; };

/** A hero as it starts (what a hero new to the server is compared with). */
function fresh(h) {
  const cls = Data.CLASSES[h.cls] || Data.CLASSES.wizard;
  return { level: 1, xp: 0, xpNext: xpFor(1), totalXp: 0, ascXp: 0, kills: 0, bossKills: 0, potsDrunk: 0, stats: clone(cls.base), skills: {}, skillPoints: 0, tree2: true };
}

/** The level a hero at (level, xp) reaches with `gain` more XP. */
function levelAfter(level, xp, gain) {
  let L = Math.max(1, Math.min(MAX_LEVEL, Math.floor(num(level)) || 1)), x = Math.max(0, num(xp)) + Math.max(0, gain);
  while (L < MAX_LEVEL && x >= xpFor(L)) { x -= xpFor(L); L++; }
  return L;
}

function petXpTotal(p) {
  let n = Math.max(0, num(p.xp));
  for (let l = 1; l < Math.max(1, Math.floor(num(p.level))); l++) n += Data.petXpNeeded(l);
  return n;
}

/** The account's XP allowance kept in memory: {n, t}. */
function allowance(meta, now) {
  const a = meta.xpAllow || (meta.xpAllow = { n: ALLOW[0], t: now });
  a.n = Math.min(ALLOW[0], a.n + Math.max(0, (now - a.t) / 1000) * ALLOW[1]);
  a.t = now;
  return a;
}

/**
 * Checks next against prev (both saves; next is changed in place). meta: the
 * account's in-memory state. Returns the reasons for anything put back
 * (empty if all was fine).
 */
function check(prev, next, meta, now) {
  now = now || Date.now();
  const fixes = [];
  if (!next || !Array.isArray(next.chars)) return fixes;
  const before = new Map((prev.chars || []).filter((h) => h && h.id).map((h) => [h.id, h]));
  const credit = prev._xpb && typeof prev._xpb === 'object' ? prev._xpb : {};
  const allow = allowance(meta, now);
  // stat potions drunk can only be ones the server gave the account that it no longer holds
  // (drunk from the inventory or straight from a loot bag); each counts once
  const potIds = items.unheldStat(prev._ledger, next);
  let potsLeft = potIds.length, potsUsed = 0;
  for (const h of next.chars) {
    if (!h || typeof h !== 'object') continue;
    const was = before.get(h.id) || fresh(h);
    const name = h.name || 'a hero';
    let bad = null;
    // ---- XP: only what the server credited (and a little allowance)
    const gain = num(h.totalXp) - num(was.totalXp);
    if (gain > 0) {
      const have = Math.max(0, num(credit[h.id]));
      const fromAllow = Math.max(0, gain - have);
      if (fromAllow > allow.n) bad = 'XP rose by ' + Math.round(gain) + ' but kills gave ' + Math.round(have);
      else { allow.n -= fromAllow; credit[h.id] = have - Math.min(have, gain); }
    } else if (gain < 0) bad = 'XP went down';
    // ---- levels: only as many as that XP buys
    if (!bad && num(h.level) > levelAfter(was.level, was.xp, Math.max(0, gain))) bad = 'level ' + h.level + ' with that XP';
    // ---- stats: growth for the levels gained, plus the stat potions drunk
    if (!bad) {
      const cls = Data.CLASSES[h.cls] || Data.CLASSES.wizard;
      const lv = Math.max(0, num(h.level) - num(was.level));
      const drunk = Math.max(0, num(h.potsDrunk) - num(was.potsDrunk));
      if (drunk > potsLeft) bad = drunk + ' stat potions drunk but ' + potsLeft + ' left the account';
      else {
        potsLeft -= drunk; potsUsed += drunk;
        let need = 0;
        const ws = was.stats && typeof was.stats === 'object' ? was.stats : cls.base;
        for (const k of Data.STATS) {
          const up = num((h.stats || {})[k]) - Math.max(num(ws[k]), 0) - Data.grow(cls, k) * 1.2 * lv;
          if (up > 0.01) need += (k === 'hp' || k === 'mp') ? Math.ceil(up / 5 - 0.001) : Math.ceil(up - 0.001);
        }
        if (need > drunk) bad = 'stats rose beyond its levels and potions';
      }
    }
    // ---- skill points: one a level, then one per 1,000+ XP at level 20 (and the one-off tree refund)
    if (!bad) {
      const had = num(was.skillPoints) + ranks(was), has = num(h.skillPoints) + ranks(h);
      const lv = Math.max(0, num(h.level) - num(was.level));
      const asc = num(h.level) >= MAX_LEVEL ? Math.ceil(Math.max(0, gain) / Data.XP_PER_SKILL_POINT) + 1 : 0;
      const refund = !was.tree2 && h.tree2 ? Math.max(0, num(h.level) - 1) : 0;
      if (has > had + lv + asc + refund) bad = has + ' skill points (at most ' + (had + lv + asc + refund) + ')';
    }
    if (bad) {
      // the progress goes back to the last good save (or a new hero's start)
      for (const k of PROGRESS) { if (was[k] === undefined) delete h[k]; else h[k] = clone(was[k]); }
      fixes.push(name + ': ' + bad);
    }
    // ---- potion slots
    for (const k of ['hpPots', 'mpPots']) if (num(h[k]) > MAX_POTS) { h[k] = MAX_POTS; fixes.push(name + ': more than ' + MAX_POTS + ' potions'); }
    // ---- backpack: the server sells them (handlers.buy), so it already knows of every one
    if (h.backpack && !(before.get(h.id) && before.get(h.id).backpack)) {
      h.backpack = false;
      if (Array.isArray(h.inv)) {
        while (h.inv.length > 8 && h.inv[h.inv.length - 1] == null) h.inv.pop();
        fixes.push(name + ': a backpack the server didn\'t sell' + (h.inv.length > 8 ? ' (items in it kept)' : ''));
      }
    }
  }
  next._xpb = credit;
  // (the pet's kill credit is the server's: whatever the game sent is replaced)
  if (prev._petb !== undefined) next._petb = prev._petb; else delete next._petb;
  // the potions counted as drunk can't be counted again
  if (potsUsed > 0 && prev._ledger) for (const sid of potIds.slice(0, potsUsed)) delete prev._ledger[sid];
  // ---- the pet: the server hatches it; it grows by kills and by feeds paid for
  if (next.pet && typeof next.pet === 'object') {
    const had = prev.pet && typeof prev.pet === 'object' ? prev.pet : null;
    if (!had) { delete next.pet; fixes.push('a pet the server didn\'t hatch'); }
    else {
      const p = next.pet;
      for (const k of ['species', 'name', 'rarity']) p[k] = had[k];
      const max = (Data.PET_RARITIES[p.rarity] || { max: 30 }).max;
      // (feeds go through the server and are already in its copy; kills it saw were credited)
      const room = Math.max(0, num(prev._petb)) + 3;
      const grew = petXpTotal(p) - petXpTotal(had);
      if (num(p.level) > max || grew > room) {
        p.level = had.level; p.xp = had.xp;
        fixes.push('pet grew faster than its kills allow');
      } else next._petb = Math.max(0, num(prev._petb) - Math.max(0, grew));
    }
  } else if (prev.pet && next.pet === undefined) {
    // (a pet only goes when the game releases it: keep that)
  }
  return fixes;
}

/** A new pet, rolled by the server (handlers.hatch). */
function hatch() { return Data.hatchPet(); }

module.exports = { check, hatch, levelAfter, xpFor, MAX_POTS };
