'use strict';
/*
 * Realm Leaders: every realm boss (the realm's events) a guild's members kill counts for their guild
 * that week (once a boss, however many of them fought it). When the week turns (Monday, UTC: the
 * quest week) the guild with the most is crowned Realm Leaders for the whole of the next one: its
 * members find more loot (LUCK) and gain more XP (XP), wherever they are, and each wears a title.
 *
 * leaders.json: {week, kills: {guildKey: n}, leader: guildKey, leaderWeek, last: {guildKey: n}}.
 */

const LUCK = 15;          // loot luck for the leaders' members
const XP = 0.1;           // +10% XP for them
const WEEK_FAME = 500;    // guild fame for being crowned

const weekOf = (now) => Math.floor((Math.floor((now || Date.now()) / 86400000) + 3) / 7);

class Leaders {
  constructor(s) {
    this.s = s || {};
    if (!this.s.kills || typeof this.s.kills !== 'object') this.s.kills = {};
    if (!this.s.week) this.s.week = weekOf();
    if (typeof this.s.leader !== 'string') this.s.leader = '';
  }

  /** The leaders' guild key ('' for nobody). */
  get leader() { return this.s.leader || ''; }
  isLeader(gk) { return !!gk && gk === this.s.leader; }
  luck(gk) { return this.isLeader(gk) ? LUCK : 0; }
  xp(gk) { return this.isLeader(gk) ? XP : 0; }

  /** A realm boss fell to these guilds (each counted once). Returns turn() events, if the week turned. */
  kill(guildKeys, now) {
    const evs = this.turn(now);
    for (const gk of new Set(guildKeys.filter(Boolean))) this.s.kills[gk] = (this.s.kills[gk] || 0) + 1;
    return evs;
  }

  /**
   * The week turned: crown last week's top guild (most kills; ties go to who got there first, the
   * order they were counted in). Returns [{kind: 'crown', g, kills, from}] or [].
   */
  turn(now) {
    const wk = weekOf(now);
    if (wk === this.s.week) return [];
    const top = this.standings()[0];
    const from = this.s.leader;
    this.s.last = this.s.kills;
    this.s.kills = {};
    this.s.week = wk;
    this.s.leader = top ? top[0] : '';
    this.s.leaderWeek = wk;
    return top ? [{ kind: 'crown', g: top[0], kills: top[1], from }] : [{ kind: 'crown', g: '', kills: 0, from }];
  }

  /** This week's race: [[guildKey, kills]], most first. */
  standings() {
    return Object.entries(this.s.kills).filter((r) => r[1] > 0).sort((a, b) => b[1] - a[1]);
  }

  /** A guild disbanded: it leaves the race (and the crown). */
  forget(gk) {
    delete this.s.kills[gk];
    if (this.s.leader === gk) this.s.leader = '';
  }

  /** What every player is told: {name, banner, me, top: [{name, kills}], kills (theirs), ends (ms)}. */
  view(info, gk) {
    const li = this.s.leader ? info(this.s.leader) : null;
    return {
      name: li ? li.name : '', banner: li ? li.banner : '', me: this.isLeader(gk),
      top: this.standings().slice(0, 5).map((r) => ({ name: info(r[0]) ? info(r[0]).name : r[0], kills: r[1] })),
      kills: gk ? this.s.kills[gk] || 0 : 0, luck: LUCK, xp: Math.round(XP * 100),
      ends: (this.s.week * 7 - 3 + 7) * 86400000
    };
  }
}

module.exports = { Leaders, LUCK, XP, WEEK_FAME, weekOf };
