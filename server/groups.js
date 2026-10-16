'use strict';
/*
 * Group Ironman groups: up to MAX accounts whose Group Ironman heroes can trade
 * with each other and share the group's Group Storage (in the vault). Their
 * items stay Group Ironman items (modes.js): a trade or a trip through the
 * storage keeps each item's pool.
 *
 * groups[id] = {name, leader (account key), members: {key: name}, bank: [{item, entry, by} | null], log: [{text, at}]}
 */
const items = require('./items');

const MAX = 5;
const BANK_SLOTS = 32;

/** The group an account is in: [id, group], or null. */
function groupOf(groups, key) {
  for (const id in groups) if (groups[id] && groups[id].members && groups[id].members[key]) return [id, groups[id]];
  return null;
}

function ready(g) {
  if (!Array.isArray(g.bank)) g.bank = [];
  while (g.bank.length < BANK_SLOTS) g.bank.push(null);
  if (!Array.isArray(g.log)) g.log = [];
  return g;
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
  groups[id] = ready({ name, leader: key, members: { [key]: who } });
  note(groups[id], who + ' founded the group');
  return [id, groups[id]];
}

/** key joins group id. Returns the group, or an error string. */
function join(groups, id, key, who) {
  const g = groups[id];
  if (!g) return 'That group no longer exists.';
  if (groupOf(groups, key)) return 'You\'re already in a group (/group leave first).';
  if (Object.keys(g.members).length >= MAX) return 'That group is full (' + MAX + ' members).';
  g.members[key] = who;
  note(ready(g), who + ' joined');
  return g;
}

/** key leaves its group (the last one out takes the group with them, once its storage is empty). Returns {name}, or {err}. */
function leave(groups, key) {
  const found = groupOf(groups, key);
  if (!found) return { err: 'You\'re not in a group.' };
  const [id, g] = found;
  const others = Object.keys(g.members).filter((k) => k !== key);
  if (!others.length && ready(g).bank.some(Boolean)) return { err: 'You\'re the last one in ' + g.name + ': take everything out of its Group Storage first.' };
  const who = g.members[key];
  delete g.members[key];
  if (!others.length) { delete groups[id]; return { name: g.name }; }
  if (g.leader === key) g.leader = others[0];
  note(g, who + ' left');
  return { name: g.name };
}

/** The leader removes an account from the group. Returns {name} (theirs), or {err}. */
function kick(groups, key, target) {
  const found = groupOf(groups, key);
  if (!found) return { err: 'You\'re not in a group.' };
  const [, g] = found;
  if (g.leader !== key) return { err: 'Only the group\'s leader can remove members.' };
  if (!g.members[target] || target === key) return { err: 'They\'re not in your group.' };
  const name = g.members[target];
  delete g.members[target];
  note(ready(g), name + ' was removed');
  return { name };
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
    name: g.name, leader: g.members[g.leader] || '',
    members: Object.keys(g.members).map((k) => ({ name: g.members[k], on: !!online(k) })),
    bank: g.bank, log: g.log.slice(0, 6)
  };
}

module.exports = { groupOf, create, join, leave, kick, deposit, withdraw, view, ready, MAX, BANK_SLOTS };
