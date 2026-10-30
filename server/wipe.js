'use strict';
/*
 * Wipes the server so every player starts fresh: every hero, vault, gold, fame,
 * pet, guild, Group Storage, marketplace listing, record, leaderboard and season
 * goes. Accounts (names and passwords), bans, VIPs, flags, bug reports and edited
 * item art stay, so players log in as before to an empty account.
 *
 * Everything is copied to data/backups/wipe-<time> first (never pruned), so a
 * wipe can be undone by copying that folder back.
 *
 * Stop the server first (it holds saves in memory and would write them back):
 *   sudo systemctl stop newrealm
 *   node server/wipe.js --yes
 *   sudo systemctl start newrealm
 */
const fs = require('fs');
const path = require('path');
const net = require('net');

const DATA_DIR = process.env.NEWREALM_DATA || path.join(__dirname, 'data');
const PORT = Number(process.env.PORT) || 2050;
/** Progress: wiped. */
const WIPE = ['saves', 'market.json', 'records.json', 'guilds.json', 'groups.json', 'season.json', 'leaders.json', 'deep.json'];
/** Kept: accounts.json, bans.json, vips.json, flags.json, bugs.json, itemart.json, status.json, discordlog.json, backups/. */

function running(cb) {
  const s = net.connect(PORT, '127.0.0.1');
  s.setTimeout(1500);
  s.on('connect', () => { s.destroy(); cb(true); });
  s.on('error', () => cb(false));
  s.on('timeout', () => { s.destroy(); cb(false); });
}

if (!process.argv.includes('--yes')) {
  console.log('This deletes every player\'s progress in ' + DATA_DIR + ' (a backup is made first).');
  console.log('Wiped: ' + WIPE.join(', '));
  console.log('Stop the server, then run: node server/wipe.js --yes');
  process.exit(1);
}
if (!fs.existsSync(DATA_DIR)) { console.log('No data folder at ' + DATA_DIR + ': nothing to wipe.'); process.exit(0); }

running((up) => {
  if (up) {
    console.log('The server is still running on port ' + PORT + '. Stop it first (sudo systemctl stop newrealm), then run this again.');
    process.exit(1);
  }
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const to = path.join(DATA_DIR, 'backups', 'wipe-' + stamp);
  fs.mkdirSync(to, { recursive: true });
  for (const name of fs.readdirSync(DATA_DIR)) {
    if (name === 'backups') continue;
    fs.cpSync(path.join(DATA_DIR, name), path.join(to, name), { recursive: true });
  }
  console.log('Backup made: ' + to);
  let saves = 0;
  try { saves = fs.readdirSync(path.join(DATA_DIR, 'saves')).length; } catch (e) {}
  for (const name of WIPE) fs.rmSync(path.join(DATA_DIR, name), { recursive: true, force: true });
  fs.mkdirSync(path.join(DATA_DIR, 'saves'), { recursive: true });
  console.log('Wiped ' + saves + ' account saves and the shared tables (' + WIPE.slice(1).join(', ') + ').');
  console.log('Accounts, bans and VIPs kept. Start the server: sudo systemctl start newrealm');
  console.log('To undo: stop the server, copy ' + to + '/* back into ' + DATA_DIR + ', start it.');
});
