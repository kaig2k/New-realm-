'use strict';
/*
 * Group Ironman groups: up to MAX accounts whose Group Ironman heroes can trade
 * with each other and share the group's Group Storage (in the vault). Their
 * items stay Group Ironman items (modes.js): a trade or a trip through the
 * storage keeps each item's pool.
 *
 * Groups are for good: friends can only join in the first INVITE_DAYS after the group is
 * founded, and once someone has joined they stay (nobody can remove them, and they can't
 * leave). Only a founder who is still alone in the group can give it up.
 *
 * groups[id] = {name, leader (account key), founded (ms), members: {key: name}, bank: [{item, entry, by} | null], log: [{text, at}]}
 */
const items = require('./items');

const MAX = 5;
const BANK_SLOTS = 32;
const INVITE_DAYS = 7;
const INVITE_MS = INVITE_DAYS * 24 * 3600 * 1000;

/** The group an account is in: [id, group], or null. */
function groupOf(groups, key) {
  for (const id in groups) if (groups[id] && groups[id].members && groups[id].members[key]) return [id, groups[id]];
  return null;
}

function ready(g) {
  if (!Array.isArray(g.bank)) g.bank = [];
  while (g.bank.length < BANK_SLOTS) g.bank.push(null);
  if (!Array.isArray(g.log)) g.log = [];
  if (!(g.founded > 0)) g.founded = Date.now(); // (groups from before the time limit get a full window from now)
  return g;
}

/** How long new members can still join (ms), 0 once the group is locked. */
function openFor(g, now) {
  ready(g);
  return Math.max(0, g.founded + INVITE_MS - (now || Date.now()));
}

/** Why nobody new can join g right now, or null. */
function closed(g, now) {
  if (Object.keys(g.members).length >= MAX) return 'That group is full (' + MAX + ' members).';
  if (!openFor(g, now)) return g.name + ' is locked: friends can only join in the first ' + INVITE_DAYS + ' days after a group is founded.';
  return null;
}

function note(g, text) {
  g.log.unshift({ text: String(text).slice(0, 120), at: Date.now() });
  if (g.log.length > 20) g.log.length = 20;
}

/** A new group led by key. Returns [id, group], or an error string. */
function create(groups, key, who, name) {
  if (groupOf(groups, key)) return 'You\'re already in a group (/group leave first).';
  name = String(name || '').trim();
  if (!/^[A-Za-z][A-Za-z ]{2,19}$/.test(name)) return 'Group names are 3-20 letters (spaces allowed).';
  const id = name.toLowerCase();
  if (groups[id]) return 'That group name is taken.';
  groups[id] = ready({ name, leader: key, founded: Date.now(), members: { [key]: who } });
  note(groups[id], who + ' founded the group');
  return [id, groups[id]];
}

/** key joins group id. Returns the group, or an error string. */
function join(groups, id, key, who) {
  const g = groups[id];
  if (!g) return 'That group no longer exists.';
  if (groupOf(groups, key)) return 'You\'re already in a group (/group leave first).';
  const why = closed(g);
  if (why) return why;
  g.members[key] = who;
  note(ready(g), who + ' joined');
  return g;
}

/** A founder still alone in their group gives it up (once anyone has joined, everyone stays for good). Returns {name}, or {err}. */
function leave(groups, key) {
  const found = groupOf(groups, key);
  if (!found) return { err: 'You\'re not in a group.' };
  const [id, g] = found;
  if (Object.keys(g.members).some((k) => k !== key)) return { err: 'Group Ironman is for good: once friends have joined, nobody leaves ' + g.name + ' and nobody can be removed.' };
  if (ready(g).bank.some(Boolean)) return { err: 'Take everything out of ' + g.name + '\'s Group Storage first.' };
  delete groups[id];
  return { name: g.name };
}

/** Puts inv[slot] in the group's storage. Returns the item, or an error string. */
function deposit(g, sv, inv, slot, who) {
  ready(g);
  const item = inv[slot];
  if (!item || typeof item !== 'object') return 'There is nothing in that slot.';
  if (!item.sid) return 'Starter gear stays with its hero.';
  if (item.locked) return 'That item is locked (right-click it to unlock it).';
  const free = g.bank.indexOf(null);
  if (free < 0) return 'Your Group Storage is full.';
  const entry = items.release(sv, item);
  if (!entry) return 'That item can\'t go in the storage.';
  entry.p = 'group';
  inv[slot] = null;
  g.bank[free] = { item, entry, by: who };
  note(g, who + ' put in ' + (item.name || 'an item'));
  return item;
}

/** Takes storage slot idx into inv. Returns the item, or an error string. */
function withdraw(g, sv, inv, idx, who) {
  ready(g);
  const b = g.bank[idx];
  if (!b) return 'Someone took that first.';
  const slot = inv.indexOf(null);
  if (slot < 0) return 'Your inventory is full.';
  inv[slot] = b.item;
  items.adopt(sv, b.item, b.entry);
  g.bank[idx] = null;
  note(g, who + ' took ' + (b.item.name || 'an item'));
  return b.item;
}

/** What a member's game shows: the group, its members (and who's online) and its storage. */
function view(g, online) {
  ready(g);
  return {
    name: g.name, leader: g.members[g.leader] || '', open: openFor(g), max: MAX,
    members: Object.keys(g.members).map((k) => ({ name: g.members[k], on: !!online(k) })),
    bank: g.bank, log: g.log.slice(0, 6)
  };
}

module.exports = { groupOf, create, join, leave, deposit, withdraw, view, ready, openFor, closed, MAX, BANK_SLOTS, INVITE_DAYS };
