'use strict';
/*
 * Daily backups of the server's data (accounts, saves, guilds, records,
 * seasons, the Marketplace...), made by the server itself so nothing has to
 * be set up on the VPS. Each day's copy goes in data/backups/YYYY-MM-DD/ and
 * the newest `keep` days are kept. The first copy is made a minute after the
 * server starts, then once a day.
 *
 * To restore: stop the server, copy a day's files back over data/, start it.
 */
const fs = require('fs');
const path = require('path');

const DAY = 24 * 60 * 60 * 1000;

/** dataDir: the server's data folder; flush(): writes pending saves first; log(text). */
function start(dataDir, flush, log, keep) {
  keep = Math.max(1, keep || 14);
  const dir = path.join(dataDir, 'backups');
  const run = () => {
    try { backupNow(dataDir, dir, flush, keep, log); } catch (e) { log('backup failed: ' + e.message); }
  };
  setTimeout(run, 60 * 1000).unref();
  setInterval(run, 60 * 60 * 1000).unref(); // checks hourly, copies once a day
}

function backupNow(dataDir, dir, flush, keep, log) {
  const day = new Date().toISOString().slice(0, 10);
  const to = path.join(dir, day);
  if (fs.existsSync(to)) return null;
  if (flush) flush();
  fs.mkdirSync(to, { recursive: true });
  let files = 0;
  for (const name of fs.readdirSync(dataDir)) {
    if (name === 'backups') continue;
    const from = path.join(dataDir, name);
    fs.cpSync(from, path.join(to, name), { recursive: true });
    files++;
  }
  // only the newest `keep` days stay
  const days = fs.readdirSync(dir).filter((d) => /^\d{4}-\d{2}-\d{2}$/.test(d)).sort();
  for (const old of days.slice(0, Math.max(0, days.length - keep))) fs.rmSync(path.join(dir, old), { recursive: true, force: true });
  if (log) log('backup made: data/backups/' + day + ' (' + files + ' files and folders)');
  return to;
}

module.exports = { start, backupNow };
