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
| `admins` | Account names with moderator powers, the in-game admin menu and the Creator Tools (Boss Maker, Map Builder, Sprite Editor), e.g. `["YourName"]`. |
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
- **Everyone:** `/report name reason` alerts online admins and is logged to `server/data/reports.log`.
- **Server console** (when running it by hand): `list`, `worlds` (the worlds the server is running, with player and monster counts), `say`, `kick`, `ban`, `unban`, `realms`, `stop`.
- **Refused saves** (likely cheating) are logged to `server/data/anticheat.log`.

## 8. Backups

Everything lives in `server/data/`:
- `accounts.json`, `guilds.json` and `bans.json`;
- `saves/` with one file per account.

A nightly backup:

```
mkdir -p ~/backups
(crontab -l 2>/dev/null; echo "0 4 * * * tar czf ~/backups/newrealm-\$(date +\%F).tgz -C ~/New-realm-/server data") | crontab -
```

Copy the backups somewhere off the server now and then (or use your provider's snapshots).

## 9. Give players the Eldmere launcher (updates reach everyone by themselves)

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
- **Not yet covered:** dodging is worked out in each player's game. Gold, fame and Aether
  totals come from the game, limited by a refilling allowance per account.
