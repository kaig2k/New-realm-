# Running a public New Realm server

This guide puts the server on a rented Linux machine (a VPS) so it runs 24/7.

## 1. Rent a server

Any small VPS works: Hetzner, DigitalOcean, Vultr, OVH, AWS Lightsail and so on.

- 1-2 CPU cores and 2 GB of RAM are plenty for a few hundred players.
- Pick **Ubuntu 24.04** and the location closest to most of your players.
- Note the server's IP address, and log in with `ssh root@YOUR_IP`.

## 2. Install and start

```
# a normal user to run the game as
adduser newrealm
usermod -aG sudo newrealm
su - newrealm

# Node.js 22 and git
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs git

# the game
git clone https://github.com/kaig2k/New-realm-.git
cd New-realm-
git checkout claude/rotmg-air-game

# try it (Ctrl+C to stop): this also creates server/config.json
node server/server.js
```

## 3. Firewall

```
sudo ufw allow OpenSSH
sudo ufw allow 2050/tcp
sudo ufw enable
```

Some providers also have a firewall in their web panel. Open TCP 2050 there too.

## 4. Run it as a service (starts on boot, restarts if it crashes)

```
sed -i 's/YOURUSER/newrealm/g' server/newrealm.service
sudo cp server/newrealm.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now newrealm
journalctl -u newrealm -f        # watch the log (Ctrl+C to stop watching)
```

To update the game later, with a warning for everyone playing:

```
cd ~/New-realm-
sh restart.sh 5        # restart in 5 minutes (or: sh restart.sh 2, now, cancel)
```

Players see a countdown, no new realm events start in the last two minutes, and at
zero the server pulls the latest update itself (`git pull`), saves and restarts on it
(systemd starts it again). Admins can do the same in game with `/restart 5`,
`/restart now` or `/restart cancel`. To restart straight away without the countdown:
`git pull && sudo systemctl restart newrealm`.

Players also need the matching game build. The server turns away old builds with an
"update" message.

### Check the server works

After an update you can run the self-test:

```
cd /home/newrealm/New-realm- && node server/selftest.js
```

It starts a private copy of the server on a spare port, using a throwaway data folder, so
your players and saves are never touched. Then it plays through the protocol with fake
players: accounts, saves, the anti-cheat checks, trades (including a duplication attempt),
movement, ability effects, raid announcements and junk input. Every line should say `ok`,
ending with `0 failed`.

## 5. A name instead of an IP

Buy a domain and add an **A record**, for example `play` pointing to your server's IP.
Players then join with `play.yourgame.com:2050`.

## 6. Settings: `server/config.json`

| Setting | What it does |
| --- | --- |
| `port` | Port to listen on (2050). |
| `serverMonsters` | `true` (the default): the server runs all monsters. `false` goes back to the first player in each area running them. |
| `name` | Your server's name. Players see it in the game instead of the IP address, default `"Eldmere"`. |
| `motd` | Message shown to players when they join. |
| `realmCap` | Players per realm (85). |
| `minRealms` / `maxRealms` | Realms open at once. New ones open as the others fill up (3 to 6). |
| `admins` | Account names with moderator powers, the in-game admin menu and the Creator Tools (Boss Maker, Map Builder, Sprite Editor), e.g. `["YourName"]`. Put yourself here once; after that you can add others in game with `/admin name`. |
| `discordWebhook` | A Discord webhook address. The server posts there when it comes online, before restarts, each week's Starfall Vault twist, and for new #1 Records times (and the Vault's weekly board), raid clears, Dark Elder kills, Godly drops and earned titles. In Discord: channel settings > Integrations > Webhooks > New Webhook > Copy Webhook URL. Test it in game with `/discord`. |
| `godmodeKick` | Off by default: players who take almost none of the monster shots the server sees hit them are only flagged (admins are told, and it's logged to `anticheat.log`). Once you've watched the log for a while and trust it, set it to `true` to kick them too. |
| `backups` | `true` (the default): the server copies everything in `server/data/` once a day into `server/data/backups/YYYY-MM-DD/`. `false` turns it off. |
| `backupKeep` | How many days of backups to keep (14). |
| `discordStatusWebhook` | A second Discord webhook (best in its own read-only #status channel). The server posts one message there and keeps editing it every 5 minutes: players online, today's peak, the season leaders, the top guild, this week's Vault twist and the latest Records time. |
| `discordInvite` | Your Discord invite link, shown on the website. |
| `viewRange` | How far away (in tiles) players see each other move and shoot. |
| `chatPerTenSeconds` | Chat messages allowed per player per 10 seconds. |

Restart the service after editing: `sudo systemctl restart newrealm`.

## 7. Moderation

- **In game (admins only):**
  - `/kick name [reason]`
  - `/ban name [hours] [reason]` (no hours means forever)
  - `/unban name`
  - `/mute name [minutes]`
  - `/unmute name`
  - `/announce message`
  - `/admin name` makes that account an admin straight away (saved in `config.json`, so it lasts), `/unadmin name` takes it back, `/admins` lists them. `/admin` on its own opens the admin menu.
  - `/restart 5`, `/restart now`, `/restart cancel`
  - `/give name 1000 gold` (or `fame`, `aether`; a minus number takes it away), works on offline accounts too
  - `/discord` sends a test message to the Discord feed
  - `/stats` shows the server's health: players online and where, world tick time, memory, how late the server is answering, and anti-cheat counts. On the VPS: `curl http://127.0.0.1:2050/stats` (or `stats` in the server console).
- **Everyone:** `/report name reason` alerts online admins and is logged to `server/data/reports.log`.
- **Server console** (when running it by hand): `list`, `worlds` (the worlds the server is running, with player and monster counts), `say`, `kick`, `ban`, `unban`, `realms`, `stop`.
- **Refused saves** (likely cheating) are logged to `server/data/anticheat.log`.

### Seasons

There's a new season every month (UTC), with nothing to set up. When a hero dies, the fame it brings its
account (as the server accepted it) goes on that month's ladder; Seasonal heroes (players tick the box when
making one) score double. When the month ends, the top ten get the Ladder Elite title and the Laurel dye,
the top three Season Medallist, and the winner Season Champion and the Champion's Gold dye, and the
Discord feed announces the winners and the new season. Players see the ladder on the Wiki's Season page.
The ladder is kept in `server/data/season.json`.

### Hero modes

Players pick a mode when they make a hero, and it never changes. **Regular** is the normal game.
**Ironman** heroes can't trade or use the Marketplace, the guild bank or the vault, and get +30 loot luck.
**Hardcore** heroes follow the same rules and must climb the gear tiers one at a time in each slot (a T3
before a T4, a T7 before anything rarer), for +60 loot luck and +5 to every stat. The server enforces all
of it: refused trades and Marketplace/guild bank use, and saves where such a hero gained an item from the
vault or another hero, or skipped a tier, are refused (logged in `anticheat.log`).

### Guild Halls

The Guild Hall portal in the Nexus takes guild members to their guild's own hall, a place every
member online shares (others can't get in). Its stations give every guild a shared bank (24 slots; Initiates can put items in but not
take them out), three weekly goals counted by the server from what members really do (finishing all three
earns that week's banner, which members then show by their names; leaders can also design their own
banner in the Banner Maker from a cloth colour, a pattern, an emblem and their colours), and a ranking by guild fame (from goals
and a tenth of the fame of members' fallen heroes). A founder can't disband a guild while its bank holds
items. It's all kept in `guilds.json`.

## 8. Backups

The server backs itself up once a day (see `backups` above): `server/data/backups/YYYY-MM-DD/` holds a
full copy of that day's data, and the newest 14 are kept. To restore one: stop the server
(`sudo systemctl stop newrealm`), copy that day's files back into `server/data/`, and start it again.
For extra safety you can also copy the backups off the VPS now and then.

Everything lives in `server/data/`:
- `accounts.json`, `guilds.json`, `bans.json`, `records.json` and `season.json`;
- `saves/` with one file per account.

A nightly backup:

```
mkdir -p ~/backups
(crontab -l 2>/dev/null; echo "0 4 * * * tar czf ~/backups/newrealm-\$(date +\%F).tgz -C ~/New-realm-/server data") | crontab -
```

Copy the backups somewhere off the server now and then (or use your provider's snapshots).

## 9. The website, and playing in the browser

The server is also a small website, on the same port as the game:

- `http://your-server:2050/` is the landing page: the logo, what the game is, the promo images from
  `promo/`, live numbers (players online, the season and its leader), and buttons to play. Share
  this link in your ads.
- `http://your-server:2050/play` runs the game **right in the browser** (through Ruffle), already
  connected to your server. No download needed, which makes it the easiest way for new players to
  try Eldmere. It's marked as beta: the launcher below is still the best way to play.
- If `bin/EldmereLauncher.swf` exists (see below), the page also offers it as a download, and
  `discordInvite` in `config.json` adds a Discord button.

For a nicer address (and https), point a domain at the VPS and put a reverse proxy such as Caddy
or nginx in front of port 2050: the pages and browser play work behind one (browser play then
connects with secure websockets).

## 10. Give players the Eldmere launcher (updates reach everyone by themselves)

Build once with your server's address:

```
build.bat play.example.com:2050        (Windows)
AIR_SDK=~/AIRSDK ./build.sh play.example.com:2050
```

This builds `bin/EldmereLauncher.swf` (a few KB). **Give that file to your players once.** They
open it the same way they opened the game before. Every time it starts it downloads the latest
game from your server and runs it, already pointed at your server: no address to type, and
nobody ever needs a new file again.

The server hands out the game from its own copy of the repo (`bin/NewRealm.swf`, at
`http://your-server:2050/NewRealm.swf`, on the same port as the game). So to update everyone:

```
cd /home/newrealm/New-realm- && sh restart.sh 5
```

(5 minutes of warning in game, then it updates and restarts by itself. `sh restart.sh now`
skips the wait.)

Players get the new version the next time they open the launcher. If the server is down (for
example mid-restart), the launcher says so and tries again every 10 seconds.

To hand out a game from somewhere else, set `NEWREALM_GAME_SWF=/path/to/NewRealm.swf` for the
server. The same build also writes the address into `src/realm/ServerConfig.as` and makes a
`bin/NewRealm.swf` that joins your server on its own, if you'd rather send the game itself.

Online and offline progress are always kept apart: every account starts fresh on your server,
and offline characters, items and currencies can't be brought in. (Older servers had an
`importLocalSaves` setting; it's gone, and an old `config.json` line for it is simply ignored.)

## What this setup does and doesn't protect

- **Saves:** characters, the vault and currencies live on the server. Players can't edit
  files on their PC to cheat.
- **Trades:** the server swaps items between its own copies of both inventories, so trades
  can't be faked or used to duplicate items.
- **Checks:** the server refuses impossible items (stats beyond what the game can roll),
  currencies rising too fast, and Godly items appearing faster than their 1 in 5,000 rate.
- **Monsters:** the server runs every monster, boss and event, decides kills (hits from far
  away are ignored), and rolls the loot. Players can't kill monsters instantly or roll their
  own drops.
- **Items:** every item comes from the server: loot, the Marketplace, the Key Merchant and the
  Starforge. When the server hands out an item, it gives it an id and writes it into the
  account's private ledger (kept in the save, never sent to the game). A save may only hold
  items from its own ledger, unchanged and each once. Made-up, edited and copied items are
  refused, and trades move items from one ledger to the other. Each character's base stats
  must also stay within its class's limits. Starter gear needs no id, and admins are trusted.
  Saves from before the ledger: their items get ids the first time this version loads them,
  so nobody loses anything.
- **Gold, fame and Aether:** every kill the server decides credits each player who hit it with
  the most gold and Aether it can pay, and the hero with the fame it can add. A save can only raise
  gold and Aether by that credit (it runs out after 20 minutes), and account fame only goes up
  when a hero dies, by what that hero earned. Selling to the Nexus merchant goes through
  the server, and Fame Store purchases must be paid for. Anything above that is cut back
  (logged in `anticheat.log`) and the game is told the real totals.
- **Dodging:** the server follows every monster shot and counts the ones that land cleanly on
  each player (skipping moments a shield wall, Time Stop, dash or similar protects them). The
  game reports the hits it took. Someone taking almost none of many clean hits (godmode) is
  flagged to admins and logged in `anticheat.log`, and kicked unless `godmodeKick` is `false`.
  Honest dodging is never punished: only shots that pass right through a player count.
- **Not yet covered:** the hits a game reports aren't proof; a determined cheater could fake them.

## Load testing

`node tools/loadtest.js 120 120` starts a private copy of the server and connects 120 fake players
for 120 seconds (they make heroes, walk into realms, fight, take hits and save), printing the
server's health every 10 seconds. Your real server and data are never touched. Tested on this
version: 120 players use about 2-3 ms of each 50 ms world tick and about 170 MB of memory.
