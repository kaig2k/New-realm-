'use strict';
/*
 * A Discord bot that lets the server's owners restart it from Discord.
 * (A webhook can only post; a bot can also take commands.)
 *
 *   /restart minutes:5     restart in 5 minutes (with the in-game countdown and the latest update)
 *   /restart minutes:now   restart straight away
 *   /restart minutes:cancel
 *   /status                players online and whether a restart is coming
 *
 * Setup (DEPLOY.md has the steps): make an application and bot at
 * discord.com/developers, invite it with the "applications.commands" and "bot"
 * scopes, then put in config.json:
 *   "discordBotToken": "the bot's token",
 *   "discordGuild": "your Discord server's ID",
 *   "discordBotAdmins": ["your Discord user ID", ...]
 * Only the people in discordBotAdmins may use it (if that list is empty, members
 * with the Administrator permission may). Answers are only shown to whoever asked.
 *
 * It talks to Discord's gateway with Node's built-in WebSocket (Node 22), so there
 * is nothing to install and nothing to open on the VPS's firewall.
 */

const API = 'https://discord.com/api/v10';
const GATEWAY = 'wss://gateway.discord.gg/?v=10&encoding=json';
const ADMINISTRATOR = 1n << 3n;

const COMMANDS = [
  {
    name: 'restart', description: 'Restart the game server (players get a countdown, then it updates)', type: 1,
    default_member_permissions: '8', dm_permission: false,
    options: [{ type: 3, name: 'minutes', description: 'Minutes until the restart (0-120), "now" or "cancel"', required: false }]
  },
  { name: 'status', description: 'Players online and whether a restart is coming', type: 1, default_member_permissions: '8', dm_permission: false }
];

/**
 * What to answer an interaction with (pure: no network, so the self-tests can use it).
 * hooks: { restart(seconds, by), cancel() -> bool, status() -> text }
 */
function answer(i, opts, hooks) {
  if (!i || i.type !== 2 || !i.data) return null;
  const user = (i.member && i.member.user) || i.user || {};
  const who = String(user.username || user.id || 'someone');
  if (opts.guild && String(i.guild_id || '') !== String(opts.guild)) return 'This bot only takes commands in its own Discord server.';
  const admins = (opts.admins || []).map(String);
  let ok = false;
  if (admins.length) ok = admins.includes(String(user.id));
  else if (i.member && i.member.permissions) { try { ok = (BigInt(i.member.permissions) & ADMINISTRATOR) !== 0n; } catch (e) { ok = false; } }
  if (!ok) return 'You are not allowed to do that.';
  if (i.data.name === 'status') return hooks.status();
  if (i.data.name === 'restart') {
    const opt = (i.data.options || []).find((o) => o.name === 'minutes');
    const arg = String(opt && opt.value !== undefined ? opt.value : '5').trim().toLowerCase();
    if (arg === 'cancel') return hooks.cancel() ? 'Restart cancelled.' : 'No restart was coming.';
    const mins = arg === 'now' ? 0 : Number(arg);
    if (!(arg !== '' && mins >= 0 && mins <= 120)) return 'Minutes must be 0-120, now or cancel.';
    hooks.restart(Math.round(mins * 60), who + ' (Discord)');
    return mins === 0 ? 'Restarting now with the latest update.' : 'Restarting in ' + mins + ' minute' + (mins === 1 ? '' : 's') + ': players are being warned. It will pull the latest update first.';
  }
  return 'Unknown command.';
}

class DiscordBot {
  /** opts: { token, guild, admins }, hooks: see answer(), log(text). */
  constructor(opts, hooks, log) {
    this.opts = opts || {};
    this.hooks = hooks;
    this.log = log || (() => {});
    this.ws = null;
    this.seq = null;
    this.beat = null;
    this.acked = true;
    this.appId = '';
    this.registered = false;
    this.retry = 0;
    this.stopped = false;
  }

  get on() { return typeof this.opts.token === 'string' && this.opts.token.trim().length > 20; }

  start() {
    if (!this.on) return;
    if (typeof WebSocket !== 'function') { this.log('discord bot: this Node has no WebSocket (needs Node 22), so the bot is off'); return; }
    this.connect();
  }

  stop() {
    this.stopped = true;
    clearInterval(this.beat);
    try { if (this.ws) this.ws.close(1000); } catch (e) {}
  }

  connect() {
    if (this.stopped) return;
    let ws;
    try { ws = new WebSocket(GATEWAY); } catch (e) { this.again('could not connect: ' + e.message); return; }
    this.ws = ws;
    ws.onmessage = (ev) => { let m; try { m = JSON.parse(String(ev.data)); } catch (e) { return; } this.onPayload(m); };
    ws.onclose = (ev) => {
      clearInterval(this.beat);
      if (this.ws !== ws) return;
      this.ws = null;
      // 4004: bad token; 4013/4014: intents not allowed. Retrying won't help.
      if (ev && (ev.code === 4004 || ev.code === 4013 || ev.code === 4014)) { this.log('discord bot: Discord refused the bot (code ' + ev.code + '): check discordBotToken'); return; }
      this.again('disconnected' + (ev && ev.code ? ' (' + ev.code + ')' : ''));
    };
    ws.onerror = () => {};
  }

  again(why) {
    if (this.stopped) return;
    const wait = Math.min(120000, 3000 * Math.pow(2, this.retry++));
    this.log('discord bot: ' + why + '; trying again in ' + Math.round(wait / 1000) + 's');
    setTimeout(() => this.connect(), wait);
  }

  send(op, d) { try { if (this.ws && this.ws.readyState === 1) this.ws.send(JSON.stringify({ op, d })); } catch (e) {} }

  onPayload(m) {
    if (m.s !== null && m.s !== undefined) this.seq = m.s;
    if (m.op === 10) {
      // hello: keep a heartbeat going, then log in (no intents: slash commands still arrive)
      clearInterval(this.beat);
      this.acked = true;
      const iv = m.d.heartbeat_interval;
      this.beat = setInterval(() => {
        if (!this.acked) { try { this.ws.close(4000); } catch (e) {} return; }
        this.acked = false;
        this.send(1, this.seq);
      }, iv);
      this.send(2, { token: this.opts.token.trim(), intents: 0, properties: { os: 'linux', browser: 'eldmere', device: 'eldmere' } });
    } else if (m.op === 11) this.acked = true;
    else if (m.op === 1) this.send(1, this.seq);
    else if (m.op === 7 || m.op === 9) { try { this.ws.close(4000); } catch (e) {} }
    else if (m.op === 0) {
      if (m.t === 'READY') {
        this.retry = 0;
        this.appId = m.d.application && m.d.application.id;
        this.log('discord bot: online as ' + (m.d.user && m.d.user.username));
        if (!this.registered) this.register();
      } else if (m.t === 'INTERACTION_CREATE') this.onInteraction(m.d);
    }
  }

  /** Puts /restart and /status on the Discord server (instant), or everywhere the bot is (can take an hour) with no discordGuild. */
  async register() {
    if (!this.appId) return;
    const where = this.opts.guild ? '/applications/' + this.appId + '/guilds/' + this.opts.guild + '/commands' : '/applications/' + this.appId + '/commands';
    try {
      const r = await this.rest('PUT', where, COMMANDS);
      if (r.ok) this.registered = true;
      else this.log('discord bot: could not add its commands (' + r.status + '): is it invited with the applications.commands scope?');
    } catch (e) { this.log('discord bot: could not add its commands: ' + e.message); }
  }

  async onInteraction(i) {
    let text;
    try { text = answer(i, this.opts, this.hooks); } catch (e) { text = 'Something went wrong: ' + e.message; }
    if (text === null) return;
    const user = (i.member && i.member.user) || i.user || {};
    if (i.data && i.data.name === 'restart') this.log('discord bot: ' + (user.username || user.id) + ' used /restart ' + JSON.stringify((i.data.options || []).map((o) => o.value)) + ': ' + text);
    try {
      await this.rest('POST', '/interactions/' + i.id + '/' + i.token + '/callback',
        { type: 4, data: { content: String(text).slice(0, 1900), flags: 64, allowed_mentions: { parse: [] } } });
    } catch (e) { this.log('discord bot: could not answer: ' + e.message); }
  }

  rest(method, route, body) {
    return fetch(API + route, {
      method, body: JSON.stringify(body), signal: AbortSignal.timeout(10000),
      headers: { 'Authorization': 'Bot ' + this.opts.token.trim(), 'Content-Type': 'application/json', 'User-Agent': 'DiscordBot (eldmere, 1)' }
    });
  }
}

module.exports = { DiscordBot, answer, COMMANDS };
