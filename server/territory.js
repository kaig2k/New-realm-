'use strict';
/*
 * Guild territory: four Spires stand at the edge of every realm's Godlands.
 * A guild takes one by holding its ground: members standing within reach of it
 * fill its capture bar (faster with more of them, up to three), while any of
 * the holders being there too stops them. A guild's Spires give its members
 * loot luck (SPIRE_LUCK each, wherever they are). Every minute a Spire is held
 * counts toward the week; on Monday the guild that held the most is crowned
 * Lords of the Godlands (a title for every member, and guild fame).
 *
 * The Spires are the same four in every realm (holding the North Spire in one
 * realm holds it everywhere); only where they stand differs. Saved in
 * territory.json: {spires: [{g: guildKey, since}], held: {guildKey: minutes}, week}.
 */

const NAMES = ['North Spire', 'East Spire', 'South Spire', 'West Spire'];
const REACH = 5;           // tiles from the Spire that count
const CAPTURE = 60;        // seconds for one member alone (three: a third of that)
const SPIRE_LUCK = 5;      // loot luck per Spire the guild holds
const WEEK_FAME = 500;     // guild fame for the week's winner

const weekOf = (t) => Math.floor((Math.floor(t / 86400000) + 3) / 7);

class Territory {
  constructor(state) {
    this.s = state && typeof state === 'object' ? state : {};
    if (!Array.isArray(this.s.spires) || this.s.spires.length !== NAMES.length) this.s.spires = NAMES.map(() => ({ g: '', since: 0 }));
    if (!this.s.held || typeof this.s.held !== 'object') this.s.held = {};
    if (!this.s.week) this.s.week = weekOf(Date.now());
    this.cap = NAMES.map(() => ({ g: '', p: 0 }));
    this.minuteT = 60;
  }

  /** Where the four Spires stand in a realm (cached on its World): the outer edge of the Godlands, one each way. */
  static spots(w, World) {
    if (w.spireSpots) return w.spireSpots;
    const out = [], c = w.N / 2;
    for (let i = 0; i < NAMES.length; i++) {
      const a = -Math.PI / 2 + i * Math.PI / 2;
      let spot = null;
      for (let r = Math.floor(w.N / 2) - 2; r > 4 && !spot; r--) {
        const x = Math.floor(c + Math.cos(a) * r) + 0.5, y = Math.floor(c + Math.sin(a) * r) + 0.5;
        if (w.zoneAt(x, y) === World.GOD_ZONE && w.canStand(x, y, 0.9, true) && !w.isSafe(x, y)) spot = { x, y };
      }
      // (no Godlands that way: the Spire stands near the middle)
      out.push(spot || { x: Math.floor(c) + 0.5 + Math.cos(a) * 4, y: Math.floor(c) + 0.5 + Math.sin(a) * 4 });
    }
    return (w.spireSpots = out);
  }

  /** The guild key holding Spire i ('' for none). */
  holder(i) { return this.s.spires[i].g || ''; }

  /** How many Spires guild gk holds. */
  count(gk) { return gk ? this.s.spires.filter((sp) => sp.g === gk).length : 0; }

  /** Loot luck for a member of guild gk. */
  luck(gk) { return this.count(gk) * SPIRE_LUCK; }

  /**
   * One step. present[i] = Map(guildKey -> members standing at Spire i, over every realm).
   * Returns what happened: [{kind: 'capture', i, g, from}], plus {kind: 'week', winner, minutes} on Monday.
   */
  tick(dt, present, now) {
    now = now || Date.now();
    const out = [];
    for (let i = 0; i < NAMES.length; i++) {
      const here = present[i] || new Map();
      const hold = this.holder(i), cap = this.cap[i];
      const others = [...here.keys()].filter((g) => g !== hold);
      if (hold && here.has(hold)) {
        // defended: the attackers' bar drains
        cap.p = Math.max(0, cap.p - dt / 20);
      } else if (others.length === 1) {
        const g = others[0];
        if (cap.g !== g) { cap.g = g; cap.p = 0; }
        cap.p += dt * Math.min(3, here.get(g)) / CAPTURE;
        if (cap.p >= 1) {
          this.s.spires[i] = { g, since: now };
          out.push({ kind: 'capture', i, g, from: hold });
          cap.g = ''; cap.p = 0;
        }
      } else if (!others.length) {
        cap.p = Math.max(0, cap.p - dt / 60);
      }
      // (two attacking guilds and no defenders: contested, nothing moves)
      if (cap.p <= 0) cap.g = '';
    }
    this.minuteT -= dt;
    if (this.minuteT <= 0) {
      this.minuteT += 60;
      for (const sp of this.s.spires) if (sp.g) this.s.held[sp.g] = (this.s.held[sp.g] || 0) + 1;
    }
    const wk = weekOf(now);
    if (wk !== this.s.week) {
      let winner = '', most = 0;
      for (const g in this.s.held) if (this.s.held[g] > most) { most = this.s.held[g]; winner = g; }
      out.push({ kind: 'week', winner, minutes: most });
      this.s.week = wk;
      this.s.held = {};
    }
    return out;
  }

  /** A guild is gone (disbanded): its Spires stand empty. */
  forget(gk) {
    for (const sp of this.s.spires) if (sp.g === gk) { sp.g = ''; sp.since = 0; }
    delete this.s.held[gk];
    for (const c of this.cap) if (c.g === gk) { c.g = ''; c.p = 0; }
  }

  /** What a realm's players are sent: each Spire, where it stands there, who holds it and who's taking it. */
  view(spots, guildInfo) {
    return NAMES.map((name, i) => {
      const h = this.holder(i), c = this.cap[i], hi = h ? guildInfo(h) : null, ci = c.g ? guildInfo(c.g) : null;
      return { i, name, x: spots[i].x, y: spots[i].y, g: hi ? hi.name : '', b: hi ? hi.banner : '', since: this.s.spires[i].since || 0,
        cg: ci ? ci.name : '', cp: Math.round(c.p * 100) / 100 };
    });
  }

  /** The week so far, most minutes first: [[guildKey, minutes], ...]. */
  standings() { return Object.entries(this.s.held).sort((a, b) => b[1] - a[1]); }
}

module.exports = { Territory, NAMES, REACH, SPIRE_LUCK, WEEK_FAME, weekOf };
