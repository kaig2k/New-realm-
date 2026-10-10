'use strict';
/*
 * Godmode checks: the world simulations count the clean hits each player should
 * have taken (WorldSim.stepShots); the player's game reports the hits it took.
 */

/**
 * What to do about a player who should have been hit `exp` times (clean hits the
 * server followed) but whose game reports only `took`: '' (fine), 'flag' or 'kick'.
 * Generous on purpose: lag and dodging at the last moment make honest players miss
 * some, but nobody honest takes almost none of dozens of clean hits.
 */
function godmodeVerdict(exp, took) {
  if (exp >= 60 && took < exp * 0.05) return 'kick';
  if (exp >= 30 && took < exp * 0.1) return 'flag';
  return '';
}

/**
 * Damage: the server added up the least each clean hit could have done (expDmg); the game says
 * it took tookDmg from every hit (clean or not). An honest game always reports at least that
 * much (more, from hits the server couldn't be sure of); one that edits Defense, or ignores
 * hits, reports far less. True when it is far too little, over enough hits to be sure.
 */
function damageVerdict(expHits, expDmg, tookDmg) {
  return expHits >= 20 && expDmg >= 400 && tookDmg < expDmg * 0.35;
}

module.exports = { godmodeVerdict, damageVerdict };
