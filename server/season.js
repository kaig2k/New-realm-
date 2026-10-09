'use strict';
/*
 * Seasons: one a month (UTC calendar months), each with its own ladder.
 *
 * When a hero dies, the fame it brings the account (as the server accepted
 * it, see wallet.js) goes on the account's season score. Seasonal heroes, made
 * during this season with the Seasonal box ticked, score double. When the
 * month ends the ladder is closed: the top ten earn the season's rewards for
 * good (titles and dyes, see Data.TITLES / Data.DYES), Discord is told, and a
 * fresh ladder opens. Seasonal heroes simply carry on as ordinary heroes.
 */

const NAMES = ['Embers', 'Frost', 'Tides', 'Stars', 'Thorns', 'Storms', 'Ashes', 'Echoes', 'Blossoms', 'Shadows', 'Crowns', 'Wolves'];
/** Season 1 is October 2026. */
const FIRST = 2026 * 12 + 9;
const TOP = 10;
const SEASONAL_MULT = 2;

/** The season at time `now`: {id: '2026-10', n, name, start, ends} (ms). */
function seasonAt(now) {
  const d = new Date(now || Date.now());
  const y = d.getUTCFullYear(), m = d.getUTCMonth();
  const n = y * 12 + m - FIRST + 1;
  return {
    id: y + '-' + (m < 9 ? '0' : '') + (m + 1),
    n,
    name: 'Season ' + n + ': ' + NAMES[((n - 1) % NAMES.length + NAMES.length) % NAMES.length],
    start: Date.UTC(y, m, 1),
    ends: Date.UTC(y, m + 1, 1)
  };
}

class Ladder {
  /** load(file, fallback) / save(file, obj): the server's tables. */
  constructor(load, save) {
    this.saveTable = save;
    this.t = load('season.json', {});
    if (!this.t.scores || typeof this.t.scores !== 'object') this.t.scores = {};
    if (!Array.isArray(this.t.past)) this.t.past = [];
    if (!this.t.id) this.t.id = seasonAt().id;
  }

  get current() { return seasonAt(); }

  save() { this.saveTable('season.json', this.t); }

  /**
   * A save of account `key` (shown as `name`) let heroes die and raised fame by `gain`.
   * dead: [{fame, seasonal, cls, level}] for each hero that died (fame: its own count, for sharing out the gain).
   * Returns the points added.
   */
  heroesDied(key, name, gain, dead) {
    if (!(gain > 0) || !dead || !dead.length) return 0;
    const total = dead.reduce((n, h) => n + Math.max(1, h.fame || 0), 0);
    let pts = 0;
    for (const h of dead) pts += gain * Math.max(1, h.fame || 0) / total * (h.seasonal ? SEASONAL_MULT : 1);
    pts = Math.round(pts);
    if (pts <= 0) return 0;
    const s = this.t.scores[key] || (this.t.scores[key] = { name, pts: 0, deaths: 0, best: null });
    s.name = name;
    s.pts += pts;
    s.deaths += dead.length;
    for (const h of dead) {
      const hp = Math.round(gain * Math.max(1, h.fame || 0) / total);
      if (!s.best || hp > s.best.fame) s.best = { fame: hp, cls: String(h.cls || '').slice(0, 16), level: h.level | 0, seasonal: !!h.seasonal };
    }
    this.save();
    return pts;
  }

  /** The ladder, best first: [{key, name, pts, deaths, best}]. */
  ranked() {
    return Object.keys(this.t.scores).map((key) => Object.assign({ key }, this.t.scores[key])).sort((a, b) => b.pts - a.pts || a.name.localeCompare(b.name));
  }

  /**
   * A new month: closes the old ladder and calls award(key, place, entry) for its top ten
   * and ended(summary) once. Returns the closed season's summary, or null if nothing changed.
   */
  rollover(now, award, ended) {
    const cur = seasonAt(now);
    if (this.t.id === cur.id) return null;
    const [y, m] = this.t.id.split('-').map(Number);
    const old = seasonAt(Date.UTC(y, m - 1, 15));
    const top = this.ranked().slice(0, TOP);
    const summary = { id: old.id, name: old.name, top: top.map((e) => ({ name: e.name, pts: e.pts })) };
    this.t.past.unshift(summary);
    this.t.past.length = Math.min(this.t.past.length, 12);
    this.t.id = cur.id;
    this.t.scores = {};
    this.save();
    if (award) top.forEach((e, i) => award(e.key, i + 1, e));
    if (ended) ended(summary, cur);
    return summary;
  }

  /** What account `key` sees on the Season page. */
  view(key) {
    const cur = seasonAt();
    const all = this.ranked();
    const at = all.findIndex((e) => e.key === key);
    return {
      id: cur.id, name: cur.name, ends: cur.ends, left: cur.ends - Date.now(), mult: SEASONAL_MULT,
      top: all.slice(0, TOP).map((e) => ({ name: e.name, pts: e.pts, deaths: e.deaths, best: e.best })),
      you: at >= 0 ? { place: at + 1, pts: all[at].pts, deaths: all[at].deaths } : null,
      players: all.length,
      last: this.t.past[0] || null
    };
  }
}

/** Rewards by ladder place: earned titles and dyes (ids in Data.TITLES / Data.DYES). */
function rewardsFor(place) {
  const out = [];
  if (place === 1) out.push('season_champion', 'dye_champion');
  if (place <= 3) out.push('season_podium');
  if (place <= TOP) out.push('season_top10', 'dye_laurel');
  return out;
}

module.exports = { Ladder, seasonAt, rewardsFor, SEASONAL_MULT, TOP };
