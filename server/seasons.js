/**
 * The seasonal world bosses: Halloween's Pumpkin King and Winter's Grimsnow. Each comes every
 * <cfg>EveryMinutes (config, default 10; 0 turns it off) in every realm with heroes in it, but only
 * in its season, by the server's local date, every year. <cfg>Always: true runs it out of season
 * too (for testing). server.js seasonalTick does the timing; admins call one up with /halloween or /winter.
 */
const SEASONAL = [
  { id: 'pumpkin_king', cfg: 'halloween', name: 'The Pumpkin King', color: 0xff8020,
    // 17 October to 2 November
    from: [10, 17], to: [11, 2],
    rise: 'THE PUMPKIN KING RISES!', warn: 'Something stirs in the pumpkin patch... the Pumpkin King rises in 30 seconds!',
    risen: (realm) => 'The Pumpkin King has risen in ' + realm + '! Smash him within 5 minutes (follow the panel at the top).',
    fail: (realm) => 'The Pumpkin King sinks back into the earth of ' + realm + ', cackling. He\'ll be back.', won: (realm) => 'The Pumpkin King is smashed in ' + realm },
  { id: 'snow_tyrant', cfg: 'winter', name: 'Grimsnow', color: 0x9fe0ff,
    // 1 December to 6 January
    from: [12, 1], to: [1, 6],
    rise: 'GRIMSNOW STOMPS IN!', warn: 'The wind turns bitter and the snow starts to fall... Grimsnow the Snow Tyrant comes in 30 seconds!',
    risen: (realm) => 'Grimsnow the Snow Tyrant has come to ' + realm + '! Melt him within 5 minutes (follow the panel at the top).',
    fail: (realm) => 'Grimsnow stomps off into the blizzard over ' + realm + '. He\'ll be back.', won: (realm) => 'Grimsnow is melted in ' + realm },
];

/** Is it this world boss's season on the given date? (A season can wrap the new year.) */
function inSeason(s, date) {
  const md = (date.getMonth() + 1) * 100 + date.getDate(), a = s.from[0] * 100 + s.from[1], b = s.to[0] * 100 + s.to[1];
  return a <= b ? md >= a && md <= b : md >= a || md <= b;
}

/** How often it comes (minutes; 0 = never), from the config. */
function every(config, s) {
  const v = config[s.cfg + 'EveryMinutes'];
  return v === undefined ? 10 : Number(v);
}

/** The seasonal world boss that's on at that date (or null), by the config. */
function seasonNow(config, date) {
  return SEASONAL.find((s) => every(config, s) > 0 && (config[s.cfg + 'Always'] || inSeason(s, date))) || null;
}

module.exports = { SEASONAL, inSeason, seasonNow, every };
