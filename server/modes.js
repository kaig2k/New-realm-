'use strict';
/*
 * Hero modes (Data.MODES), checked on every save.
 *
 * Regular heroes play the normal game. Ironman heroes can't trade or use the
 * Marketplace, the guild bank or the vault; Hardcore heroes follow the same
 * rules and must also climb the gear tiers one at a time in each slot (use a
 * T3 weapon before a T4, a T7 before anything rarer). In return both get
 * extra loot luck (the server adds it to their rolls), and Hardcore heroes
 * extra stats.
 *
 * A hero's mode is set when it's made and can't change afterwards. The
 * server keeps its own record of each Hardcore hero's best tier per slot
 * (`_climb` on the hero), so the game can't skip steps.
 */
const { Data } = require('./sim/gen/game');

const SLOTS = Data.CLIMB_SLOTS;

function modeOf(ch) { return ch && (ch.mode === 'ironman' || ch.mode === 'hardcore') ? ch.mode : ''; }
function restricted(mode) { return mode === 'ironman' || mode === 'hardcore'; }
/** Extra loot luck the server gives a hero of this mode. */
function luck(mode) { return Data.findMode(mode || '').luck | 0; }

/** Every item id (sid) a save holds, and where: Map sid -> 'vault' | hero id. */
function where(sv) {
  const out = new Map();
  for (const it of sv.vault || []) if (it && it.sid) out.set(it.sid, 'vault');
  for (const ch of sv.chars || []) {
    if (!ch) continue;
    for (const it of heroItems(ch)) if (it.sid) out.set(it.sid, ch.id);
  }
  return out;
}

function heroItems(ch) {
  const out = [];
  for (const it of [ch.weapon, ch.ability, ch.armor, ch.ring].concat(Array.isArray(ch.inv) ? ch.inv : [])) if (it && typeof it === 'object') out.push(it);
  return out;
}

/**
 * Checks a new save against the stored one. Fixes what it can in `next`
 * (modes can't change; the server's climb record replaces the game's) and
 * returns a reason to refuse the save, or null.
 *
 * fixes (optional array): a Hardcore item equipped too early is put back in
 * the hero's inventory instead of refusing the whole save (which would undo
 * everything since the last save, loot included); what was done is added to
 * fixes, and the caller tells the game.
 */
function check(prev, next, fixes) {
  if (!next || !Array.isArray(next.chars)) return null;
  const before = new Map((prev.chars || []).filter((h) => h && h.id).map((h) => [h.id, h]));
  const had = where(prev);
  for (const ch of next.chars) {
    if (!ch || typeof ch !== 'object') continue;
    const was = before.get(ch.id);
    // the mode is picked when the hero is made, and kept
    if (was) { if (modeOf(was)) ch.mode = modeOf(was); else delete ch.mode; }
    else if (!modeOf(ch)) delete ch.mode;
    const mode = modeOf(ch);
    if (!restricted(mode)) { delete ch._climb; continue; }
    // no items from the vault or from other heroes (new loot, shop buys and the hero's own items are fine)
    for (const it of heroItems(ch)) {
      if (!it.sid) continue;
      const from = had.get(it.sid);
      if (from !== undefined && from !== ch.id) {
        return (mode === 'hardcore' ? 'Hardcore' : 'Ironman') + ' heroes can only use what they found themselves (' + (it.name || 'an item') + ' came from ' + (from === 'vault' ? 'the vault' : 'another hero') + ')';
      }
    }
    if (mode !== 'hardcore') { delete ch._climb; continue; }
    // the climb: each equipped item at most one tier above the best this hero has used in that slot
    const climb = Object.assign({}, was && was._climb && typeof was._climb === 'object' ? was._climb : {});
    for (const slot of SLOTS) {
      let best = Math.max(0, Number(climb[slot]) || 0);
      const old = was ? was[slot] : null;
      if (old && typeof old === 'object') best = Math.max(best, Data.climbTier(old));
      const it = ch[slot];
      if (it && typeof it === 'object') {
        const t = Data.climbTier(it);
        // (starter gear has no id and is always low tier: it just counts as used)
        if (it.sid && t > best + 1) {
          const why = 'Hardcore: ' + (it.name || 'that item') + ' is T' + (t >= 8 ? '8+' : t) + ' but the best ' + slot + ' used so far is T' + best;
          const back = fixes ? unequip(ch, slot, old, best) : null;
          if (!back) return why;
          fixes.push(why + '. It went back to your inventory' + (back.name ? ' and ' + back.name + ' is equipped again' : '') + ': equip T' + (best + 1) + ' first.');
          if (ch[slot] && typeof ch[slot] === 'object') best = Math.max(best, Data.climbTier(ch[slot]));
        } else best = Math.max(best, t);
      }
      climb[slot] = best;
    }
    ch._climb = climb;
  }
  return null;
}

/**
 * Takes ch[slot] off (it was equipped too early) and puts it in the inventory,
 * swapping in the item that was there before (or the best allowed one the hero
 * carries). Returns the item now in the slot ({} if the slot is left empty), or
 * null if there is no room.
 */
function unequip(ch, slot, old, best) {
  if (!Array.isArray(ch.inv)) return null;
  const it = ch[slot];
  const same = (a, b) => a && b && (a.sid ? a.sid === b.sid : JSON.stringify(a) === JSON.stringify(b));
  let i = old && typeof old === 'object' ? ch.inv.findIndex((o) => same(o, old)) : -1;
  if (i < 0) {
    let bt = -1;
    ch.inv.forEach((o, k) => {
      if (!o || typeof o !== 'object' || o.kind !== it.kind || o.sub !== it.sub) return;
      const t = Data.climbTier(o);
      if (t <= best + 1 && t > bt) { bt = t; i = k; }
    });
  }
  if (i >= 0) { const was = ch.inv[i]; ch.inv[i] = it; ch[slot] = was; return was; }
  i = ch.inv.indexOf(null);
  if (i < 0) return null;
  ch.inv[i] = it;
  ch[slot] = null;
  return {};
}

module.exports = { check, modeOf, restricted, luck };
