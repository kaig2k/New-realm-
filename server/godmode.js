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

module.exports = { godmodeVerdict };
