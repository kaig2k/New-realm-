'use strict';
/*
 * How hard a hero can hit, worked out by the server from its own copy of the
 * hero (stats checked on every save, gear from the item ledger), never from
 * what the player's game says. WorldSim.hit caps every hit a player reports:
 *
 *   hit    the most one hit can do: the bigger of the weapon's top roll, the
 *          ability's (Player.useAbility's formulas) and the pet's, times every
 *          damage boost there is at once (Brutality, Might, Bloodlust x5, War
 *          Cry, Executioner, Backstab and a crit with the hero's Might).
 *   rate   the most damage a second on ONE monster: the weapon firing as fast
 *          as it can (Dexterity, Berserk and Haste at once), its ability on
 *          cooldown landing a dozen hits a cast, and the pet.
 *   burst  how much may land at once on one monster (an ability's volley).
 *
 * A changed game that reports bigger numbers only gets these. Generous enough
 * that honest play never reaches them (every boost at once is rare), and far
 * below what a hacked game could otherwise claim.
 */
const { Data } = require('./sim/gen/game');

/** Damage per ability, as (a + b * level) * power: the largest formula in each (Player.useAbility). */
const ABILITY = {
  fireball: [130, 16], arrowstorm: [40, 5], sanctuary: [40, 4], charge: [60, 8], harvest: [70, 8], snare: [60, 7],
  lightning: [160, 18], frostnova: [90, 10], pierce: [110, 12], volley: [35, 4], bash: [50, 6], smite: [120, 14],
  ward: [60, 6], knives: [30, 4], whirlwind: [45, 5.5], prison: [16, 2], raise: [20, 3], explosive: [150, 16],
  wolf: [35, 4], requiem: [95, 11], acidflask: [22, 3], elixir: [50, 5], philbomb: [260, 28], rewind: [80, 9],
  // (abilities that don't hit for damage themselves still get a little, for anything they set off)
  shieldwall: [40, 5], shadowstep: [40, 5], banner: [40, 5], smoke: [40, 5], warcry: [40, 5], valor: [40, 5],
  lullaby: [40, 5], timestop: [40, 5], hastefield: [40, 5]
};
/** Hits one cast can land on the same monster (volleys, damage over time, minions): 2 unless listed. */
const HITS = { arrowstorm: 10, volley: 8, knives: 8, whirlwind: 12, sanctuary: 10, harvest: 6, raise: 12, wolf: 12, prison: 8,
  acidflask: 10, requiem: 4, snare: 4, explosive: 3, lightning: 3, ward: 6, smite: 3 };
const HITS_PER_CAST = 12;

const num = (v) => (typeof v === 'number' && isFinite(v) ? v : 0);

/** A hero's total for stat k: base stats, gear, set bonus, mode and skill-tree stats (Player.stat). */
function stat(ch, k) {
  let n = num((ch.stats || {})[k]);
  let set = null;
  for (const it of [ch.weapon, ch.ability, ch.armor, ch.ring]) {
    if (!it || typeof it !== 'object') continue;
    if (!(k === 'spd' && it.kind === 'weapon')) n += num(it[k]);
    if (it.set) set = it.set;
  }
  if (set) { const b = Data.setBonus(set); if (b && b[k]) n += num(b[k]); }
  const md = ch.mode ? Data.findMode(ch.mode) : null;
  if (md && md.stats && md.stats[k]) n += num(md.stats[k]);
  const skills = ch.skills && typeof ch.skills === 'object' ? ch.skills : {};
  for (const sk in Data.SKILL_STATS) if (skills[sk] && Data.SKILL_STATS[sk][k]) n += num(skills[sk]) * Data.SKILL_STATS[sk][k];
  return n;
}

/** {hit, rate, burst} for hero ch (and the account's pet), or null for no hero. */
function caps(ch, pet) {
  if (!ch || typeof ch !== 'object') return null;
  const skills = ch.skills && typeof ch.skills === 'object' ? ch.skills : {};
  const rank = (id) => Math.max(0, num(skills[id]));
  const level = Math.max(1, Math.min(20, num(ch.level) || 1));
  // every boost at once (Player.damageMult, Game.hurtEnemy, Player.critMult)
  const boost = (1 + rank('brutality') * 0.05) * 1.3 * (1 + 5 * 0.06) * 1.25 * (1 + rank('executioner') * 0.1) * 1.5 *
    (1.5 + stat(ch, 'mgt') / 100 + rank('ferocity') * 0.1);
  const mult = 0.5 + stat(ch, 'att') / 50;
  const w = ch.weapon && typeof ch.weapon === 'object' ? ch.weapon : null;
  const weaponHit = w ? num(w.dmax) * mult : 0;
  const shots = w ? Math.max(1, Math.min(9, num(w.shots) || 1)) : 0;
  const fireRate = (1.5 + 6.5 * stat(ch, 'dex') / 75) * (w ? Math.min(2.5, num(w.rate) || 1) : 1) * 1.5 * 1.4;
  // (Rampage: a ring of ten every twelfth shot)
  const weaponDps = weaponHit * shots * fireRate * (w && w.passive === 'rampage' ? 1.9 : 1);
  const a = ch.ability && typeof ch.ability === 'object' ? ch.ability : null;
  const id = a ? Data.abilityId(a) : '';
  const f = ABILITY[id] || [40, 5];
  const pow = a ? Math.max(1, num(a.power) || 1) : 1;
  const abilityHit = (f[0] + f[1] * level) * pow;
  const cd = Math.max(1, num((Data.ABILITIES[id] || {}).cd) || 4);
  const abilityDps = abilityHit * (HITS[id] || 2) / cd;
  const petHit = pet && typeof pet === 'object' ? Data.petAttack(pet) : 0;
  const hit = Math.ceil(Math.max(weaponHit, abilityHit, petHit, 10) * boost) + 5;
  const rate = Math.ceil((weaponDps + abilityDps + petHit * 1.5 + (8 + level) * pow * 2) * boost * 1.25) + 50;
  // (and what it can take: its Defense with the best Defense aura there is, and its health)
  return { hit, rate, burst: hit * HITS_PER_CAST + rate * 2, def: stat(ch, 'def') + AURA_DEF, maxHp: stat(ch, 'hp') };
}
/** The most Defense a Warrior's banner (Abilities: 10 x its power) gives everyone near it. */
const AURA_DEF = 30;

module.exports = { caps, stat, ABILITY, AURA_DEF };
