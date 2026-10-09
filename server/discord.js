'use strict';
/*
 * Posts what happens on the server to a Discord channel through a webhook
 * (Discord: channel settings > Integrations > Webhooks > New Webhook > Copy
 * Webhook URL, then put it in config.json as "discordWebhook").
 *
 * Messages wait in a short queue and go out one at a time, at most one every
 * two seconds (well inside Discord's limits); if Discord is down or the queue
 * backs up, the oldest are dropped. The game never waits on Discord.
 */

const http = require('http');
const https = require('https');

const GAP_MS = 2000;
const MAX_QUEUE = 25;

class Discord {
  /** url: the webhook (or '' to do nothing); name: who the posts come from; log(text) for problems. */
  constructor(url, name, log) {
    this.url = typeof url === 'string' ? url.trim() : '';
    this.name = name || 'Eldmere';
    this.log = log || (() => {});
    this.queue = [];
    this.busy = false;
    this.sent = 0;
  }

  get on() { return /^https?:\/\//.test(this.url); }

  /** Queues a post: text, with an optional colour stripe (embed). */
  post(text, color) {
    if (!this.on || !text) return;
    const body = color === undefined
      ? { username: this.name, content: String(text).slice(0, 1900), allowed_mentions: { parse: [] } }
      : { username: this.name, embeds: [{ description: String(text).slice(0, 1900), color: color & 0xffffff }], allowed_mentions: { parse: [] } };
    this.queue.push(body);
    if (this.queue.length > MAX_QUEUE) this.queue.shift();
    this.pump();
  }

  pump() {
    if (this.busy || !this.queue.length) return;
    this.busy = true;
    const body = JSON.stringify(this.queue.shift());
    let u;
    try { u = new URL(this.url); } catch (e) { this.log('discord: bad webhook address'); this.queue.length = 0; this.busy = false; return; }
    const lib = u.protocol === 'http:' ? http : https;
    const done = () => { setTimeout(() => { this.busy = false; this.pump(); }, GAP_MS); };
    const req = lib.request(u, { method: 'POST', headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) }, timeout: 8000 }, (res) => {
      res.resume();
      if (res.statusCode >= 200 && res.statusCode < 300) this.sent++;
      else this.log('discord: webhook answered ' + res.statusCode);
      done();
    });
    req.on('timeout', () => req.destroy(new Error('timed out')));
    req.on('error', (e) => { this.log('discord: ' + e.message); done(); });
    req.end(body);
  }
}

/**
 * One message in a channel that the server keeps editing: a live status board
 * (players online, the season, records...). A webhook can edit its own messages,
 * so no bot is needed. The message's id is remembered (saveId) so a restart edits
 * the same message instead of posting a new one; if it was deleted, a new one is posted.
 */
class StatusBoard {
  constructor(url, name, id, saveId, log) {
    this.url = typeof url === 'string' ? url.trim().replace(/\/+$/, '') : '';
    this.name = name || 'Eldmere';
    this.id = id || '';
    this.saveId = saveId || (() => {});
    this.log = log || (() => {});
    this.busy = false;
  }

  get on() { return /^https?:\/\//.test(this.url); }

  /** Shows `text` (an embed with a colour stripe), editing the board's message or posting it the first time. */
  show(text, color) {
    if (!this.on || this.busy) return;
    this.busy = true;
    const body = JSON.stringify({ username: this.name, embeds: [{ description: String(text).slice(0, 3900), color: (color || 0x8fd16a) & 0xffffff }], allowed_mentions: { parse: [] } });
    const editing = !!this.id;
    let u;
    try { u = new URL(editing ? this.url + '/messages/' + this.id : this.url + '?wait=true'); } catch (e) { this.busy = false; return this.log('discord status: bad webhook address'); }
    const lib = u.protocol === 'http:' ? http : https;
    const req = lib.request(u, { method: editing ? 'PATCH' : 'POST', headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) }, timeout: 8000 }, (res) => {
      let data = '';
      res.on('data', (d) => { data += d; });
      res.on('end', () => {
        this.busy = false;
        if (editing && res.statusCode === 404) { this.id = ''; this.saveId(''); return; } // deleted: post a new one next time
        if (res.statusCode < 200 || res.statusCode >= 300) return this.log('discord status: webhook answered ' + res.statusCode);
        if (!editing) {
          try { this.id = JSON.parse(data).id || ''; this.saveId(this.id); } catch (e) {}
        }
      });
    });
    req.on('timeout', () => req.destroy(new Error('timed out')));
    req.on('error', (e) => { this.busy = false; this.log('discord status: ' + e.message); });
    req.end(body);
  }
}

/** Discord markdown would bold or hide parts of names with * _ ~ ` |. */
function esc(s) { return String(s).replace(/([*_~`|>\\])/g, '\\$1'); }

/** "A, B and C" (and "and 3 more" past five). */
function names(list) {
  const n = list.map(esc);
  if (n.length > 5) return n.slice(0, 5).join(', ') + ' and ' + (n.length - 5) + ' more';
  return n.length > 1 ? n.slice(0, -1).join(', ') + ' and ' + n[n.length - 1] : n[0] || 'someone';
}

module.exports = { Discord, StatusBoard, esc, names };
