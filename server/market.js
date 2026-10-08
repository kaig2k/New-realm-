'use strict';
/*
 * The player marketplace: list an item for gold at the Nexus Marketplace and
 * anyone can buy it, even while you're offline.
 *
 * A listed item leaves its seller's save (and item ledger) and waits here;
 * a buyer gets it with its ledger entry, so it stays a real server-given item.
 * Sellers' takings (minus the fee) and items that come back (expired
 * listings) wait in their save's server-only `_market` box until they
 * collect them at the Marketplace, so a sale never overwrites the gold of a
 * seller who is playing at the time.
 */
const items = require('./items');

const FEE = 0.05;              // the Marketplace keeps 5% of each sale (gold leaves the game)
const MAX_LISTINGS = 10;       // per account
const MAX_PRICE = 100000000;
const LIFE_MS = 7 * 86400000;  // listings come back after a week

class Market {
  /** load(file, fallback) / save(file, obj): the server's table storage. */
  constructor(load, save) {
    this.data = load('market.json', { next: 1, list: [] });
    if (!Array.isArray(this.data.list)) this.data.list = [];
    this.persist = () => save('market.json', this.data);
  }

  /** The seller's box in their save: {earned, sales: [{name, price, buyer, at}], returns: [{item, entry}]}. */
  static box(sv) {
    if (!sv._market || typeof sv._market !== 'object') sv._market = { earned: 0, sales: [], returns: [] };
    const b = sv._market;
    b.earned = b.earned || 0; b.sales = b.sales || []; b.returns = b.returns || [];
    return b;
  }

  find(id) { return this.data.list.find((l) => l.id === id) || null; }
  countOf(key) { return this.data.list.filter((l) => l.seller === key).length; }

  /** Lists inv[slot] of the seller's character for `price` gold. Returns the listing or an error string. */
  list(sv, sellerKey, sellerName, inv, slot, price, now) {
    price = Math.floor(Number(price));
    const item = inv[slot];
    if (!item) return 'There is nothing in that slot.';
    if (!item.sid) return 'Starter gear can\'t be sold.';
    if (!(price >= 1 && price <= MAX_PRICE)) return 'Pick a price from 1 to ' + MAX_PRICE.toLocaleString('en') + ' gold.';
    if (this.countOf(sellerKey) >= MAX_LISTINGS) return 'You can have ' + MAX_LISTINGS + ' items for sale at once.';
    const entry = items.release(sv, item);
    if (!entry) return 'That item can\'t be sold.';
    inv[slot] = null;
    const l = { id: this.data.next++, seller: sellerKey, sellerName, item, entry, price, at: now || Date.now() };
    this.data.list.push(l);
    this.persist();
    return l;
  }

  /** The buyer takes listing `id` into their inventory. Returns {listing, paid, earned} or an error string. */
  buy(buyerSv, buyerKey, inv, id, sellerSv) {
    const l = this.find(id);
    if (!l) return 'Someone else bought that first.';
    if (l.seller === buyerKey) return 'That\'s your own listing (cancel it under My listings).';
    if ((buyerSv.gold || 0) < l.price) return 'Not enough gold.';
    const slot = inv.indexOf(null);
    if (slot < 0) return 'Your inventory is full.';
    buyerSv.gold -= l.price;
    inv[slot] = l.item;
    items.adopt(buyerSv, l.item, l.entry);
    const earned = Math.floor(l.price * (1 - FEE));
    if (sellerSv) {
      const b = Market.box(sellerSv);
      b.earned += earned;
      b.sales.unshift({ name: l.item.name || 'an item', price: l.price, got: earned, at: Date.now() });
      if (b.sales.length > 20) b.sales.length = 20;
    }
    this.data.list = this.data.list.filter((x) => x !== l);
    this.persist();
    return { listing: l, paid: l.price, earned };
  }

  /** The seller takes listing `id` back into their inventory. Returns the listing or an error string. */
  cancel(sv, key, inv, id) {
    const l = this.find(id);
    if (!l || l.seller !== key) return 'That listing is gone.';
    const slot = inv.indexOf(null);
    if (slot < 0) return 'Make room in your inventory first.';
    inv[slot] = l.item;
    items.adopt(sv, l.item, l.entry);
    this.data.list = this.data.list.filter((x) => x !== l);
    this.persist();
    return l;
  }

  /** Listings older than a week go back to their sellers' boxes. getSave(key) gives a seller's save (or null). Returns the sellers touched. */
  expire(getSave, now) {
    now = now || Date.now();
    const old = this.data.list.filter((l) => now - l.at > LIFE_MS);
    if (!old.length) return [];
    const touched = new Set();
    for (const l of old) {
      const sv = getSave(l.seller);
      if (sv) Market.box(sv).returns.push({ item: l.item, entry: l.entry });
      touched.add(l.seller);
    }
    this.data.list = this.data.list.filter((l) => now - l.at <= LIFE_MS);
    this.persist();
    return [...touched];
  }

  /** Takes the seller's earnings into their gold and returned items into their inventory (as room allows). */
  static collect(sv, inv) {
    const b = Market.box(sv);
    const gold = b.earned;
    sv.gold = (sv.gold || 0) + gold;
    b.earned = 0;
    let got = 0;
    while (b.returns.length) {
      const slot = inv.indexOf(null);
      if (slot < 0) break;
      const r = b.returns.shift();
      inv[slot] = r.item;
      items.adopt(sv, r.item, r.entry);
      got++;
    }
    return { gold, items: got, left: b.returns.length };
  }

  /** What the Marketplace shows `key`: every listing (newest first), theirs marked, and their box. */
  view(key, sv, now) {
    now = now || Date.now();
    const b = Market.box(sv);
    return {
      list: this.data.list.slice().sort((a, c) => c.at - a.at).map((l) => ({ id: l.id, item: l.item, price: l.price, seller: l.sellerName,
        mine: l.seller === key, left: Math.max(0, l.at + LIFE_MS - now) })),
      earned: b.earned, returns: b.returns.length, sales: b.sales.slice(0, 5), fee: FEE, max: MAX_LISTINGS
    };
  }
}

module.exports = { Market, FEE, MAX_LISTINGS, LIFE_MS };
