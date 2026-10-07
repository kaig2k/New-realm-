'use strict';
/*
 * Storage for the New Realm server.
 *
 * Small shared tables (accounts, guilds, bans) live in one JSON file each;
 * every account's save (characters, vault, gold, fame, skins...) lives in its
 * own file under data/saves/. Writes are delayed a moment and atomic (write to
 * a temp file, then rename), so a crash never leaves a half-written save.
 *
 * Everything goes through this module, so moving to a database (PostgreSQL,
 * SQLite...) later only means rewriting this file.
 */
const fs = require('fs');
const path = require('path');

class Store {
  constructor(dir) {
    this.dir = dir;
    this.savesDir = path.join(dir, 'saves');
    fs.mkdirSync(this.savesDir, { recursive: true });
    this.timers = {};
    this.pending = {};
    this.saves = new Map(); // account key -> save object (loaded on demand)
  }

  file(name) { return path.join(this.dir, name); }

  loadTable(name, fallback) {
    let text;
    try { text = fs.readFileSync(this.file(name), 'utf8'); } catch (e) { return fallback; } // not made yet
    try { return JSON.parse(text); } catch (e) {
      // never start over on a damaged file: that would wipe every account on the next write
      fs.copyFileSync(this.file(name), this.file(name) + '.corrupt-' + Date.now());
      throw new Error(name + ' is damaged (a copy was kept as ' + name + '.corrupt-*). Restore it from a backup, then start the server again.');
    }
  }

  /** Writes a table soon (calls within the delay are merged). */
  saveTable(name, obj) {
    this.later(this.file(name), () => JSON.stringify(obj, null, 1));
  }

  savePath(key) { return path.join(this.savesDir, key.replace(/[^a-z0-9]/g, '') + '.json'); }

  /** An account's save, or null if it has none on this server. */
  getSave(key) {
    if (this.saves.has(key)) return this.saves.get(key);
    let data = null, text = null;
    try { text = fs.readFileSync(this.savePath(key), 'utf8'); } catch (e) {}
    if (text !== null) {
      try { data = JSON.parse(text); } catch (e) {
        // keep the damaged file instead of replacing the player's progress with an empty save
        const bad = this.savePath(key) + '.corrupt-' + Date.now();
        try { fs.copyFileSync(this.savePath(key), bad); } catch (e2) {}
        console.error('Save for ' + key + ' was damaged; kept a copy as ' + bad);
      }
    }
    this.saves.set(key, data);
    return data;
  }

  putSave(key, data) {
    this.saves.set(key, data);
    this.later(this.savePath(key), () => JSON.stringify(this.saves.get(key)));
  }

  /** Drops an account's save from memory once it has been written (player logged off). */
  release(key) {
    const p = this.savePath(key);
    if (this.pending[p]) this.flushOne(p);
    this.saves.delete(key);
  }

  later(file, make) {
    this.pending[file] = make;
    clearTimeout(this.timers[file]);
    this.timers[file] = setTimeout(() => this.flushOne(file), 1500);
  }

  flushOne(file) {
    const make = this.pending[file];
    if (!make) return;
    delete this.pending[file];
    clearTimeout(this.timers[file]);
    try {
      const fd = fs.openSync(file + '.tmp', 'w');
      fs.writeSync(fd, make());
      fs.fsyncSync(fd);
      fs.closeSync(fd);
      fs.renameSync(file + '.tmp', file);
    } catch (e) {
      console.error('Could not write ' + file + ': ' + e.message);
    }
  }

  /** Writes everything now (shutdown). */
  flushAll() {
    for (const f of Object.keys(this.pending)) this.flushOne(f);
  }

  appendLog(name, line) {
    try { fs.appendFileSync(this.file(name), line + '\n'); } catch (e) {}
  }
}

module.exports = { Store };
