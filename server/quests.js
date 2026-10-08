'use strict';
/*
 * Daily and weekly quests, kept and counted on the server.
 *
 * The quests themselves (what they ask, their rewards, which ones come up on
 * which day) are the game's own tables (Data.QUESTS / WEEKLY_QUESTS); this
 * module keeps each account's progress in its save (save._quests, which the
 * game's copy never overwrites) and counts it from what the server saw happen:
 * its monsters dying, the Records board.
 */
const { Data } = require('./sim/gen/game');

/** Today in UTC, like 2026-10-08. */
function dayKey(now) { return new Date(now).toISOString().slice(0, 10); }
/** This week (Monday to Sunday, UTC) as year-number, like 2026-41. */
function weekKey(now) {
  const days = Math.floor(now / 86400000) + 3; // 1970-01-01 was a Thursday: count from the Monday before
  return String(Math.floor(days / 7));
}

/** The account's quest state, started over when a new day or week has begun. */
function state(sv, now) {
  now = now || Date.now();
  let q = sv._quests;
  if (!q || typeof q !== 'object') q = sv._quests = {};
  const day = dayKey(now), week = weekKey(now);
  if (q.day !== day) {
    q.day = day;
    q.d = Data.dailyQuests(day).map((x) => ({ id: x.id, arg: x.arg, p: 0, c: false }));
  }
  if (q.week !== week) {
    q.week = week;
    const w = Data.weeklyQuest(week);
    q.w = { id: w.id, arg: w.arg, p: 0, c: false };
  }
  return q;
}

/** Each quest with its definition: [{q, def, weekly, i}]. */
function entries(q) {
  const out = q.d.map((x, i) => ({ q: x, def: Data.quest(x.id), weekly: false, i }));
  out.push({ q: q.w, def: Data.quest(q.w.id), weekly: true, i: 0 });
  return out.filter((e) => e.def);
}

/** Does event `ev` (like "events" or "event:ev_king") count for this quest? */
function counts(e, ev) {
  if (e.def.ev === 'event') return ev === 'event:' + e.q.arg;
  return e.def.ev === ev;
}

/**
 * Something happened that quests might count: adds n to every matching quest.
 * Returns the quests it finished just now (their wording), or [] (or null if nothing changed).
 */
function progress(sv, evs, now) {
  const q = state(sv, now);
  let changed = false;
  const done = [];
  for (const e of entries(q)) {
    if (e.q.c || e.q.p >= e.def.goal) continue;
    let n = 0;
    for (const ev of evs) if (counts(e, ev)) n++;
    if (!n) continue;
    e.q.p = Math.min(e.def.goal, e.q.p + n);
    changed = true;
    if (e.q.p >= e.def.goal) done.push((e.weekly ? 'Weekly quest' : 'Quest') + ' complete: ' + Data.questText(e.def, e.q.arg) + '!');
  }
  return changed ? done : null;
}

/** Claims a finished quest's reward into the save. Returns the reward {gold, onrane} or an error string. */
function claim(sv, weekly, i, now) {
  const q = state(sv, now);
  const e = weekly ? entries(q).find((x) => x.weekly) : entries(q).find((x) => !x.weekly && x.i === i);
  if (!e) return 'There is no such quest.';
  if (e.q.c) return 'You already claimed that one.';
  if (e.q.p < e.def.goal) return 'That quest is not finished yet.';
  e.q.c = true;
  sv.gold = (sv.gold || 0) + (e.def.gold || 0);
  sv.onrane = (sv.onrane || 0) + (e.def.onrane || 0);
  return { gold: e.def.gold || 0, onrane: e.def.onrane || 0 };
}

/** What the game shows: [{text, p, goal, gold, onrane, claimed, weekly, i}] plus when they reset. */
function view(sv, now) {
  now = now || Date.now();
  const q = state(sv, now);
  const dayEnd = (Math.floor(now / 86400000) + 1) * 86400000;
  const weekEnd = (Number(q.week) * 7 - 3 + 7) * 86400000;
  return {
    list: entries(q).map((e) => ({ text: Data.questText(e.def, e.q.arg), p: e.q.p, goal: e.def.goal, gold: e.def.gold || 0,
      onrane: e.def.onrane || 0, claimed: !!e.q.c, weekly: e.weekly, i: e.i })),
    dayLeft: dayEnd - now, weekLeft: weekEnd - now
  };
}

module.exports = { state, progress, claim, view, dayKey, weekKey };
