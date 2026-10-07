# New Realm

A top-down bullet-hell adventure inspired by *Realm of the Mad God*, written in pure
ActionScript 3 for **Adobe AIR**. All of the pixel art is generated in code: 8x8 sprites
scaled 5x with thin outlines and drop shadows, textured tiles, and rotated projectiles.

![screenshot](docs/screenshot.png)
![nexus](docs/nexus.png)
![realm map](docs/realm-map.png)

## Play it

A pre-built `bin/NewRealm.swf` is included, so you only need an AIR SDK
([HARMAN AIR SDK](https://airsdk.harman.io/), or the old Adobe AIR SDK 32).

**Windows:** unzip the AIR SDK to `C:\AIRSDK` (so `C:\AIRSDK\bin\adl.exe` exists), then
double-click `run.bat`. It also finds SDK folders named `AIRSDK*` in your user folder,
Downloads or Desktop, or next to the game folder. If yours is somewhere else, either put
its path on one line in a file called `airsdk.txt` next to `run.bat`, or `set AIR_SDK=...`
first. If anything goes wrong, the window stays open and shows the error.

**macOS / Linux:**

```sh
AIR_SDK=/path/to/AIRSDK ./run.sh
```

`run` opens the game with `adl`, the AIR Debug Launcher. To get a standalone app you can
double-click, run `package.sh` / `package.bat`. It builds a captive-runtime bundle in
`dist/NewRealm` and creates a self-signed certificate the first time.

After changing the code, rebuild with `build.sh` / `build.bat` (uses `amxmlc`).
The source also compiles with the Apache Flex SDK's `mxmlc`, and the SWF runs in
Flash Player or Ruffle.

The UI font is Source Sans Pro (SIL Open Font License, see `assets/fonts/`). It is
precompiled into `assets/fonts/RealmFonts.swf` and loaded at startup. You only need to
rebuild that file if you change the fonts, and that needs the Apache Flex SDK's `mxmlc`
(see `assets/fonts/RealmFonts.as`).

## Admin menu (for testing)

Press **`** (the key under Esc) or type `/admin` in chat to open the admin menu. Close it
with ` or Esc. It has five tabs:

- **Player**: max level, max all stats (11/11), god mode, full heal, skill points, max
  potions, gold / Aether / account fame, backpack, clear inventory, a level 30 pet.
  - **World buttons:** kill all monsters, teleport to the Godlands or the Nexus, finish the
    realm's events (the realm closes and the Dark Elder fight starts), spawn an event now,
    reveal the minimap.
- **Monsters / Bosses**: every monster and boss in the game, sorted by health. Click one to
  spawn it in front of you (toward the mouse).
- **Dungeons**: open a portal to any dungeon next to you, or go straight in. Also has the
  Dark Elder's chamber and a realm portal.
- **Items**: any tier (T0-T7) or rarity (RN, BD, EL, SF, PR) of weapon, ability, armor and
  ring for your class, a full Bonded set, potions, Star Shards and every stat potion.

## Accounts and saves

New Realm is **online-only**. Accounts, characters and items all live on the game server:
- The first time you open the game it asks you to **create an account** (username and
  password) on the server. After that the game remembers you on that PC and logs you in by
  itself, so PLAY goes straight to character select.
- You can log in to the same account from any computer with your password.
- The top-right box lets you log out (the server forgets that PC) or change your password
  (other PCs then have to log in again).
- Passwords are stored on the server only as salted scrypt hashes. Eight wrong passwords from
  one address lock it out for 5 minutes.
- If the server goes down mid-game, the game keeps trying to reconnect for about a minute,
  then returns to the title screen. Your progress up to the last save is safe on the server.
- **Accounts from before passwords** keep working: log in once from the PC you first played
  on, and the password you type becomes the account's password.
- A build without a server baked in (`build.bat` with no address) shows a "Server" button on
  the title screen to choose one.

## Controls

These are the defaults. You can change any of them in Menu (Esc) > Controls.

| Key | Action |
| --- | --- |
| WASD / arrows | Move |
| Mouse wheel / - and = | Zoom the view out and in |
| Q / E | Rotate the camera |
| Z | Snap the camera straight back to 0 degrees (instantly) |
| Mouse | Aim; hold left button to shoot |
| Space | Class ability (aimed at cursor) |
| F / G | Drink health / magic potion |
| 1-8 | Use or equip the item in that inventory slot |
| R | Return to the Nexus (full heal) |
| Enter | Go through the portal you are standing on |
| Enter (elsewhere) | Chat / commands: `/help`, `/nexus`, `/realm`, `/glands`, `/stats`, `/quests`, `/achievements`, `/who`, `/trade name`, `/inspect name`, `/tips`, `/admin` |
| Click a player (Nexus) / right-click (anywhere) | Player menu: Inspect, Trade, party / guild invite, Teleport |
| L | Party and guild window |
| K (or the book button) | Boss wiki: every boss, where it is and its unique drops |
| T | Skill tree |
| I | Toggle auto-fire |
| M | Mute / unmute sound |
| Esc / P | Menu: an overlay over the game. The game does not pause, so you can still move and dodge. It has Resume, **Settings** (volume, sound, show players, names, chat bubbles, damage numbers, particles, screen shake), **Controls** (rebind every key) and Save & Quit |

**Items work like RotMG, with drag and drop:**
- **Drop:** drag an inventory item onto the ground (anywhere in the game view) to drop it in
  a loot bag.
- **Move:** drag between inventory slots to move or swap items.
- **Equip:** drag onto a gear slot to equip, or drag gear into an empty inventory slot to take it off.
- **Loot bags:** drag items between a loot bag (or the vault) and your inventory.
- **Click:** clicking an item still uses or equips it, and clicking a loot bag item picks
  it up.
- **Shift+click:** sells an item at the Marketplace, and quick-drops it anywhere else.

## What keeps it lively

- **Kill streaks:** kills within 3.5 seconds of each other build a streak, shown under the
  top of the screen with a timer bar. Each kill in a streak adds +1% loot luck (up to +30%) and
  bonus XP. Milestones get their own call-outs: Killing Spree (5), Rampage (10), Unstoppable
  (20), Godlike (35), Legendary (50), Mythical (75), Beyond Mortal (100). Streaks of 10+ pay out
  gold when they end, and your best streak is remembered.
- **Elite monsters:** about 1 in 30 realm monsters spawns as an elite with a coloured aura and
  name plate. Each has one trait: **Swift** (fast), **Armored** (tough), **Frenzied** (hits hard),
  **Giant** (huge health), **Splitting** (bursts into three when killed) or **Vampiric** (heals).
  Elites drop loot twice, with better odds, and give triple XP and bonus gold.
- **Treasure Goblins:** every few minutes a gold-glowing Treasure Goblin appears near a player
  inland and runs away. The quest arrow points to it. Catch it within 30 seconds for a big
  sack: gold, a Runed item for your class, stat potions, a good chance of a Star Shard, and
  sometimes Bonded or Eldritch gear.
- **Shrines:** about 12 shrines stand in each realm's inland biomes (shown on the minimap once
  seen). Walk up to one for a 60-second blessing: **Might** (+30% damage), **Haste** (+35%
  speed), **Fortune** (+25% loot luck), **Vigor** (regenerate 4% HP a second) or **Arcana**
  (regenerate 10% MP a second). Active blessings show a countdown at the top of the screen. A
  shrine rests for 2 minutes after blessing you.
- **Crates and Mimics:** piles of breakable crates turn up in the realm and in dungeon rooms.
  Shoot them for gold or potions. One in eight is a **Mimic** that jumps out and fights back,
  and guards stat potions, a 40% chance of a Runed item and sometimes a Star Shard.
- **Loot beams:** white bags and rarer shine a column of light into the sky in their colour,
  so you can spot good drops from across the screen.
- **Atmosphere:** the light shifts with where you are (warm beach, shaded forests, violet
  Godlands, blood-red Conclave, stormy blue skies). Leaves drift through the forests, embers
  rise in the Godlands and lava dungeons, ash falls in the Conclave, and rain pours through
  Heart of the Storm, where lightning flashes the screen. Water sparkles as you pass.

## The realm

Realms are now 512 x 512 tiles, about 2.5 times the old size, with more rivers, roads and
ruins. The ground is drawn in chunks as you get near them, so the bigger map loads faster
and uses less memory than the old one did.

**Landmarks.** Each realm has about 30-40 guarded places spread across its biomes:

| Biome | Landmarks |
|---|---|
| Beach | Smugglers' Cove (Pirate Captain) |
| Lowlands | Bandit Camp (Bandit Leader), Goblin Warren (Goblin Chieftain) |
| Midlands | Spider Grove (Spider Queen), Orc Warcamp (Orc King) |
| Highlands | Dwarven Hall (Dwarf King), Ogre Den (Minotaur) |
| Godlands | Fallen Temple (Demon), Lich's Barrow (Lich) |

- Walking near one wakes its leader and band; more players bring a bigger band.
- Killing the leader clears the landmark for everyone in the realm and gives everyone
  who hit it a **bonus loot roll** plus gold.
- Landmarks you've seen show on the minimap as coloured diamonds, and turn grey once
  cleared.
- Clearing landmarks also brings the next realm event sooner.
- Realms now need **8 event bosses** (up from 6) before they close.

## Item art

Every item has its own 8x8 sprite, like RotMG:
- **Weapons:** each of the 8 tiers of every weapon type is its own drawing (Rusty Sword
  through Sunforged Blade, Twig Staff through Staff of the Void, and so on).
- **Abilities, armor and rings:** each tier has its own shape, emblem and colours.
- **Stat potions:** each stat has its own bottle and colour.
- **Named gear:** uniques, Godly pieces, class sets and Starforged, Eldritch and
  Primordial items each get a look of their own, picked from the item's identity. The same
  item always looks the same, and its rarity glow still shows what tier it is.
- **Godly** items are ivory and gold with one jewel colour, framed by an off-white border
  and a soft warm glow. Godly loot bags, banners and text use the same off-white.

## Bosses, raids and loot

**Boss fights.** Every boss now runs a scripted fight with 2-4 phases.
- Each phase has its own lines, movement (orbiting, charging, teleporting, holding the
  centre) and attacks.
- Many phases open with a few seconds of shield while the boss powers up.
- Patterns include flowers, walls with a gap to slip through, telegraphed ground blasts
  (a circle fills up, then explodes), meteor rain, weaving, returning, accelerating,
  homing and splitting shots, and multi-wave bursts.
- Some phases rotate between attack sets.

**New bosses**
- Realm events: the Obsidian Colossus, Pyraxis the Phoenix, Mother Hexis and the Reef Kraken.
- Three new realm finales (below), and six raid bosses.

**Wiki.** The book button next to the Nexus button (or K, or `/wiki`) lists every boss
by category: realm events, dungeons, hard dungeons, finales and raids. Each entry shows
where to find the boss, its HP and phase count, and its unique drops; hover an item for its
full stats. The **Abilities** tab shows every class's three abilities with their MP cost and
cooldown, and the **Guide** tab explains rarities, boss uniques, the Starforge and rerolls,
abilities, stat potions, skill points and pets.

**Unique drops.** About 70 named items, each dropped by **one boss only**. The tooltip shows
its lore and which boss drops it. Uniques have their own shot patterns: Saltbeard's Cutlass
swings three blades, the Fang of Ssythra weaves like a snake, the Cryptkeeper's Blade
returns to you. Runed items no longer drop from random monsters. Star Shards are much rarer.

**Endgame difficulty.** Hard-dungeon bosses, realm finales and raid bosses have about twice
the health, +10 defense, 35% harder bullets and faster attacks. They also **scale with the
players fighting them**:
- Each extra player in the world adds +80% boss health; offline, each simulated party member
  adds +40%.
- Health only goes up, keeping the same percentage, so leaving mid-fight doesn't help.
- The boss bar shows how many players it's scaled for.

**Godly items (GD), 1 in 3,000.** The rarest tier: a full four-piece Godly set for every class,
32 items with no duplicates:

| Class | Set |
| --- | --- |
| Wizard | Astral Archmage |
| Archer | Skypiercer |
| Knight | Aegis Eternal |
| Priest | Seraphic |
| Rogue | Nightfall |
| Warrior | Titanslayer |
| Necromancer | Soulforge |
| Huntress | Wildheart Eternal |

- Every hard-dungeon boss, realm finale boss and raid boss carries one or two pieces. Each
  piece rolls 1 in 3,000 per kill (Bounty helps a little).
- Each set has a big 4-piece bonus.
- A Godly drop comes in a cyan bag with a screen-wide announcement, and online it's
  announced in chat.
- The boss wiki shows which boss drops which piece.

**Skins.** 16 new skins in the Fame Store, two per class, inspired by pop-culture archetypes
but with original designs: Space Wizard, Vampire Lord, Cyber Ranger, Outlaw, Star Trooper,
Mecha Pilot, Pop Idol, Wasteland Medic, Ninja, Phantom Thief, Barbarian King, Galactic
Gladiator, Zombie King, Grim Reaper, Tomb Explorer and Neon Hunter.

**Realm finales.** When a realm closes, it sends everyone to one of four finales, picked per
realm (online, the same one for everyone from that realm):
- Azrakor's Citadel, then the Dark Elder;
- the Drowned Throne (Nerezza, the Tide Empress);
- the Clockwork Foundry (Gearmind Omega);
- the Void Rift (Vael'thrax the Void Dragon).

**Raids.** Raids are opened with **raid keys**, which drop rarely from bosses:

| Boss | Key chance |
|---|---|
| Dark Elder and realm finales | 8% |
| Hard dungeon bosses | 6% |
| Raid bosses | 4% |
| Other dungeon bosses | 2.5% |
| Realm event bosses | 2% |

Bounty raises these chances like other loot. Keys can be traded, stored in the vault and sold.
Click a key in the Nexus, or use it at the **Raid Table** (east, below the Starforge), to open
its raid portal. Everyone on the server is told, and the portal lasts 30 seconds. A raid is three
full dungeon of its own and the hardest content in the game: guarded halls full of elite
raid monsters, then three boss stages behind seals that open as each stage falls.
- **The Crimson Conclave**, a blood cathedral: a pillared nave of Crimson Cultists, Bone
  Thralls and Blood Hounds with burning blood pools, then the two Zealots in their chapels,
  then Matron Sanguine's sanctum, then Archon Vesper at the altar.
- **Heart of the Storm**, floating islands climbing into the clouds: Gale Harpies, Thunder
  Golems and Cloud Serpents, then three Thunder Sentinels on their pylon islands, then a
  bridge forms to Galecaller Ysra's terrace, and finally Tempestus in the eye of the storm.
  Lightning keeps striking near you the whole way, so keep moving.

Raid bosses have more health, armor and damage than any other boss, and scale with the
number of players.

Raid bosses drop the best loot and their own uniques.

**Dungeons.** Each dungeon now has its own layout and atmosphere:

| Layout | What it's like | Dungeons |
| --- | --- | --- |
| Caverns | Winding caves | Sunken Crypt, Ember Depths, Pirate Cove, Drowned Throne |
| Labyrinth | A real maze | Forest Maze, Spider Den |
| Pillared halls | Grid of halls | Forgotten Cellar, Undead Lair, Tomb, Clockwork Foundry |
| Floating islands | Narrow bridges over an abyss | Storm Spire, Abyss of Demons, Sprite World, Void Rift |
| Ring | Chambers around a central sanctum | Snake Pit, Shattered Sanctum |

Some dungeons also have lava pools, flooded rooms or darkness (you only see a pool of light
around yourself).

## Playing with friends (multiplayer)

**Hand out a ready-to-join game:** build with your server address (`build.bat your.server:2050`)
and players who open the .swf join your server automatically. It also builds
`bin/EldmereLauncher.swf`: give players that once and it always downloads the latest game from
your server, so updates reach everyone after a `git pull` there. See DEPLOY.md, step 9.

One person hosts the server; everyone (the host too) joins it from the title screen.

### Playtest checklist

**Host, before the session**
1. Install **Node.js** (LTS, https://nodejs.org). You only need to do this once.
2. Build the game: `build.bat` then `package.bat`. You get `dist\NewRealm.zip`, a standalone
   game (no AIR install needed). Send the zip to your friends. **Everyone must use the same
   build**: the server turns away a mismatched game with a clear message.
3. Pick how friends will reach you (see below). Tailscale is easiest.

**Host, when you play**
1. Double-click **`server.bat`** and leave the window open. It shows the addresses to share.
2. Start the game, log in, click **Play Online**, enter `localhost:2050`.

**Friends**
1. Unzip `NewRealm.zip` and run `NewRealm.exe`.
2. Register an account (it's stored on your own PC), click **Play Online** and enter the
   host's address, e.g. `100.101.102.103:2050`.

**Reaching the host**
- **Same Wi-Fi:** use the `192.168.x.x:2050` address the server window shows.
- **Tailscale (easiest over the internet, no router setup):** everyone installs Tailscale
  (https://tailscale.com, free). The host shares their PC with the friends from the
  Tailscale admin page. Friends use the host's `100.x.x.x:2050` address; the server window
  marks it "(Tailscale)".
- **Port forwarding:** forward TCP port 2050 on the router to the host PC, allow it through
  Windows Firewall, and friends use the host's public IP (search "what is my ip") + `:2050`.
- **Always-on:** run `node server/server.js` on any small cloud server and open port 2050.

**Server window commands:** `list` (who's online and where), `say message` (announce to
everyone), `kick name`, `ban name [hours] [reason]`, `unban name`, `realms` (new realms),
`stop` (saves and shuts down).

Accounts, guilds, bans and every account's save are kept in `server/data/`. Settings are in
`server/config.json`; add your name to `admins` to get moderator commands and the admin menu
online.

### Running a public server

See **[DEPLOY.md](DEPLOY.md)** for running the server 24/7 on a rented Linux server: install,
firewall, systemd service, domain name, settings, moderation and backups.

On a server, your **characters, vault, gold and fame are stored on the server**:
- They follow your account to any PC.
- The game is online-only, and everyone starts fresh on a server. Nothing from a PC is ever
  uploaded as a save.
- The server checks every save and refuses impossible items or currency jumps.
- Trades are done by the server itself.

Servers run 3-6 realms with up to 85 players each. New realms open as they fill up, and the
Nexus portals show how many players are in each.

### What's shared online
- **Monsters, bosses and events run on the server**, like in RotMG. For every realm, dungeon,
  raid and Dark Elder chamber, the server generates the same map the game does and runs all
  of these itself:
  - monster AI and boss phases;
  - spawning, landmarks, realm events and treasure goblins;
  - elites and raid stages.

  Every player sees and fights the same monsters. Your game draws them and replays their
  bullets, so dodging never waits on the network.
- **Kills and loot.** Your game sends your hits to the server. The server decides when a
  monster dies and ignores hits from too far away. It then rolls the loot for each player
  who damaged it and sends each of you your own bag (RotMG-style). Everyone near a kill
  shares its XP.
- **Dungeons.** Portals that drop in a realm appear for everyone there and lead to the same
  dungeon. `/join name` follows a party or guild member wherever they are. When a realm
  closes, everyone from it goes to the same Citadel and the same Dark Elder fight.
- **Realms.** The server picks the three realms and everyone gets the same maps.
- **Players and social.** Positions and shots; public, party (`/p`) and guild (`/g`) chat;
  trades (both players accept the same offer); parties (6); guilds (27, saved on the server).
- **Reconnects.** If the connection drops, the game keeps running and reconnects by itself.
  The online line shows your ping.

### Known limits for the playtest
- Whether a monster's bullet hits *you* is still worked out in your own game, so dodging never
  waits on the network. A laggy player's view of a monster can be a few tiles behind the
  server's.
- Items can only come from the server: loot, the Marketplace, the Key Merchant and the
  Starforge. Each one carries an id from the server's ledger, so a modified game can't make up,
  improve or copy items. Gold, fame and Aether still come from the game, but they can only rise
  as fast as the server's allowance lets them.
- Your name on a server is protected by a secret key your game makes the first time you
  join. If you change PC or wipe your game data, the host can free the name by deleting
  your entry from `server/data/accounts.json` (with the server stopped).

Server options: `server.bat 3000` runs on port 3000. The server speaks plain TCP for the
game and WebSocket on the same port (for browser builds).

## Other players and trading

When you play offline, the other players are simulated on your computer (`LocalNet.as`).
Online, the same features talk to the real server (`ServerNet.as`).

- **Inspect:** click a player in the Nexus (or right-click anywhere, or `/inspect name`) to
  see their class, level, fame, maxed stats and equipment, with item tooltips.
- **Trade:** choose Trade from the player menu, or type `/trade name`. In the trade window:
  - Click your own items to offer them (green).
  - Click the other player's items to ask for them (gold outline).
  - What they offer turns green.
  - Any change un-ticks both Accepts. Accept unlocks a moment after the last change, so
    nothing can be swapped at the last second.
  - Both players accept, and the items swap.
- Players sometimes ask to trade with you, and they advertise what they're selling in chat.
  Simulated traders want a fair deal: they say how much more they want, and value stat
  potions and Star Shards highly.
- In the realms other players fight monsters too. You share the XP from kills near you,
  but loot only drops for monsters you hit yourself.
- Other players show as yellow dots on the minimap.

**Parties** (up to 6 players)
- Invite someone from the player menu or with `/party invite name`.
- Party members follow you into realms and dungeons and fight beside you.
- Party members have blue names and blue minimap dots.
- `/p message` is party chat.

**Guilds** (up to 27 members)
- Found one for 1,000 gold with `/guild create Name`.
- Officers and above can invite. Ranks are Initiate, Member, Officer, Leader and Founder;
  promote, demote and kick from the guild window (L).
- `/g message` is guild chat. Guild members have green names, and online members hang out
  in the Nexus.
- You can teleport to party and guild members (`/tp name`, 10s cooldown).
- Setting: **Show players: Party & guild** hides everyone else (their sprites, names, chat and shots).

**Weapon forms:** half of all dropped weapons come in a form that changes how they shoot.

| Form | What it does |
| --- | --- |
| Heavy | One big, slow-firing shot that hits very hard (good against armor) |
| Farshot | Much longer range, a little less damage |
| Brutal | Short range, a lot more damage |
| Scattershot | Two extra shots in a wide spread; each hits softer |
| Swift | Fires much faster; each shot hits softer |
| Siege | Slow, heavy shots that pierce through everything |
| Serpent | Shots weave in a wave |
| Returning | Shots fly out and come back, hitting on both passes |

**Loot for every class:** monsters drop weapons, abilities and armor for every class, not just
yours. Half of gear drops are for your own class; the rest can be for any class. Gear your
class can't use has a red slot, and its tooltip says which classes can use it. You can still
trade it, store it in the vault or sell it.

**Abilities:** ability tooltips explain what the ability does, with its damage, healing and
duration at your level, and its MP cost.

**Water:** lakes and rivers can be waded through at half speed (you sink in up to your
waist). The open sea is still impassable.

## Features

The game is set on **Eldmere**, an island of realms ruled by Azrakor the Dark Elder. It plays
like Realm of the Mad God, but its names, systems and pixel art are New Realm's own.

- **8 classes**, each with three abilities (Space, aimed at the cursor). An ability item holds
  one of them (its name says which, e.g. "Comet Spell of Storms" is Lightning Strike); each has
  its own MP cost and cooldown, shown on the ability slot. Other players see your casts. The
  first ability of each class is listed below; the in-game wiki's Abilities tab lists all 24.
  - **Wizard, Fireball:** a fireball that explodes where it hits and scatters embers.
  - **Archer, Arrow Storm:** arrows rain on an area and slow what they hit.
  - **Knight, Shield Wall:** plants the shield in front of you. Bullets from the front stop
    on it, for your party too. Behind it you take 60% less damage but move slower.
  - **Priest, Sanctuary:** a holy circle that heals you while you stand in it and burns
    monsters inside. It works in the Nexus too.
  - **Rogue, Shadowstep:** vanish in smoke and reappear at the cursor. You stay invisible
    for a moment, and your next hit is a Backstab (a sure crit, +50%).
  - **Warrior, Berserker Charge:** rush through monsters, hitting each one, then go berserk.
  - **Necromancer, Soul Harvest:** a draining blast, plus two spirit skulls that circle you
    and shoot.
  - **Huntress, Snare:** a trap that roots nearby monsters in vines, then bursts into
    slowing shards.
- **11 maxable stats ("11/11")**: the classic 8 plus **Fury** (crit damage, +0.1x per
  10), **Focus** (crit chance, +1% per 10) and **Warding**. Gear can also add **Bounty**
  (+1% loot chance per point).
- **Ward and Fervor bars**: Warding fills a white **Ward** shield (about 3 per point) that
  absorbs damage before HP. **Fervor** gains +2 for each kill near you and refills your Ward at 100.
- **Item tiers and rarities**: tiered gear T0-T7, then New Realm's own rarities, from common
  to rarest. Each has its own colour, tag and loot bag.

  | Rarity | Tag | Colour | What it is |
  | --- | --- | --- | --- |
  | **Runed** | RN | azure | Rare drops from events, dungeons and the Godlands |
  | **Bonded** | BD | jade | Class sets, such as the Wizard's Archmage's set or the Knight's Crusader's set; wearing all 4 pieces gives a set bonus |
  | **Eldritch** | EL | violet | Dropped by the Dark Elder |
  | **Starforged** | SF | gold | Made at the forge, or very rare drops. Weapons carry passives such as Lifebloom, Shardstorm, Frostbite, Executioner and Rampage |
  | **Primordial** | PR | ember red | The rarest drops |
- **Currencies**: account-wide **Gold** and **Aether**, plus account Fame.
- **The Nexus** is a great hall. The **Realm Gate** of portals runs along the north wall. A
  round plaza in the middle holds the healing fountain, ringed by stone statues of the eight
  classes, with a garden in each corner. The **east wing** has the Starforge and Raid Table; the
  **west wing** has the Fame Store, the Pet Yard and the gold **vault portal**; the Marketplace
  and Quest Board stand by the south entrance.
- **Key Merchant** (south-east garden): sells a key for every dungeon. Prices go from
  300 gold (Pirate Cove) to 11,000 gold (Azrakor's Citadel); harder dungeons cost more.
  Click the key in the Nexus or a realm to open that dungeon's portal beside you for
  30 seconds. Your party can follow you in.
- **The Vault** is your own private room behind the gold portal: up to 10 chests of 8 slots
  (80 in all), shared by all your characters and safe when one dies. You start with 3 chests;
  the **Vault Keeper** sells the rest (1,000 gold for the 4th, then 500 more each). Stand by
  a chest to see inside and drag items between it and your inventory.
- Nexus stations: the Pet Yard (pets heal you and shoot monsters), the Fame Store, the **Starforge** (a Runed, Bonded
  or Eldritch item + a Star Shard + 100 Aether = a Starforged item; its Reroll tab gives a weapon a new
  prefix for 400 gold, or special-rarity gear new bonus stats for 60 Aether) and the **Marketplace** (buy
  potions, stat potions, Star Shards, mystery Runed items and a **Backpack**, and shift+click items to sell them). A
  backpack gives that character 8 more inventory slots. Switch pages with the button by
  the sidebar tabs; keys 1-8 use the page you're on.
- **Fame Store** (Nexus, north-west): spend account fame on skins, two per class, such as
  Frost Mage, Dark Knight, Ghost (Rogue) and Plague Doctor (Necromancer). Skins cost
  400 or 1,000 fame. Once bought, a skin can be equipped by any character of that class.
- **Pet Yard**: hatch a pet egg (1,000 gold) in the Nexus to get one of six pets (Realm
  Pup, Jelly, Night Owl, Ember Drake, Wisp, Pebble Golem). Pets are Common, Rare or
  Legendary. They follow you, heal HP and MP every 3 seconds, and level up with every kill
  (or when you feed them gold). Rarer pets reach higher levels. Your pet is shared by all
  your characters and survives their deaths.
- **Graveyard**: the title screen lists your 30 most recently fallen heroes. Each entry shows
  the hero's level, kills, fame and what killed them.
- **Realm events**: the realm's overlord, *Azrakor the Dark Elder*, keeps summoning event
  bosses (Cube Overlord, Ember Titan, Frost Wyrm, Hollow King, Gorehorn the Behemoth, the
  Phantom Regent) and announces each kill in
  chat as `[3/8][Realm: Ashveil]`. Clear all 8 events and the realm closes. You storm
  **Azrakor's Citadel** and then the **Dark Elder's Chamber**, a white arena ringed in red bloodstone, to fight him
  for Eldritch, Starforged and Primordial loot. At a third of his health he becomes immune and
  summons four Elder Crystals. Destroy them all to make him vulnerable again.
- **Dungeons**: event bosses often drop a portal (open for 30 seconds) to one of four
  dungeons: the Sunken Crypt, the Ember Depths (lava pools), the Storm Spire or the
  Forgotten Cellar. Each is a chain of monster rooms with a boss at the end (the Crypt
  Warden, Pyrelord Ignaar, the Tempest Seraph or the Cellar Sorcerer). Most dungeons also
  have a side treasure room with a guarded chest holding a set piece and stat potions.
- **Chat and commands** (Enter): `/glands` teleports you to the Godlands, plus
  `/nexus`, `/realm`, `/stats` and `/quests`. One-time tips guide new players.
- **Skill tree** (T, or the star tab): you get a skill point every level, then one per
  1,000 XP at level 20. There are three branches, and each skill needs 2 ranks in the one
  above it:
  - **Might:** Brutality, Precision, Ferocity, Executioner.
  - **Guard:** Vigor, Bulwark, Aegis, Leech.
  - **Fortune:** Swiftness, Prosperity, Arcane Flow, Scavenger.

  Each branch ends in a capstone that unlocks at level 20:
  - **Bloodlust:** kills stack up extra damage.
  - **Last Stand:** survive a killing blow once a minute.
  - **High Stakes:** every loot bag is either doubled or lost on a coin flip. You can switch
    it on or off.

  Resetting the tree costs 1,000 gold.
- **Creator Tools** (admins only; the button appears on the character screen for accounts listed under `admins` in the server's `config.json`):
  - **Boss Maker:** pick a look (any boss in the game, or your own sprite) and set its
    health, defense and speed. Then build up to 4 phases. Each phase has a health threshold,
    a movement style, a line the boss says, and up to 4 attacks: aimed shots, ring, spiral,
    flower, a wall with a gap, ground blasts, meteor rain or summoned minions. You can set the
    count, speed, damage, cooldown, colour, bullet shape and on-hit effect. Values stay within
    the limits the game's own bosses use, so every boss you make can be dodged.
    **Test Fight** puts you in its arena with a level 20 hero of the class you choose. R
    restarts the fight, and dying restarts it too. Test fights run offline on a throwaway save,
    so nothing reaches your account.
  - **Map Builder:** paint a boss arena up to 60x60 with 16 floor types (including water,
    lava, walls and void) and 13 decorations, then mark the start point and the boss spot.
  - **Sprite Editor:** draw a 16x16 sprite with 16 colours you choose. It has a pen, an
    eraser, fill, mirror drawing and a live preview.

  Everything you make is saved on this PC.
- **Saved characters**: characters are saved automatically and live until they die. The
  title screen lists them under "Your Characters".
- **Status effects**: bosses and dungeon enemies can leave you Slowed, Paralyzed, Confused
  (controls reversed), Armor Broken (0 Defense) or Bleeding (draining HP, no regen).
- **Sound effects**, all synthesised in code: shots, hits, kills, level-ups, loot, rare-drop
  chimes, portals and boss spawns. A banner announces Eldritch, Starforged and Primordial drops.
- **Daily Quest Board**: three missions picked by date, such as
  "Clear a dungeon" or "Defeat 2 realm event bosses", paying gold and Aether.
- **Quest arrow** (like RotMG's quest marker): a gold arrow at the edge of the screen points
  to your current objective, with its name and distance. That's the area boss, the nearest
  Elder Crystal while the Dark Elder is immune, or a monster suited to your level.
- **Achievements**: 16 account-wide goals, such as First Blood, Dungeon Master, Treasure
  Hunter, Bane of Azrakor and Perfection (11/11). Each pays gold and Aether once. See them
  at the Quest Board, or type `/achievements`.
- **Screen shake** on heavy hits, explosions and boss deaths.
- **Menu overlay** (Esc). The game keeps running behind it. It has Settings, Controls and Save & Quit. In Controls you can rebind every action. If you pick a key another action uses, the two swap. Esc, Enter and the admin key are fixed.
  to the title screen.
- **Boss damage meter** with your damage share and the loot threshold.
- **RotMG-style realms**: a big procedurally generated island (320x320 tiles) with five
  biomes from the coast inwards: **Beach → Lowlands → Midlands → Highlands → Godlands**.
  There are cobblestone roads running inland with bridges over rivers, lakes, shallows,
  forests in the Midlands, rocky Highlands, and brick and lava ruins.
- **More monsters**: 7-9 types per biome, including leaders drawn bigger than normal
  monsters:
  - Beach: Pirates, Pirate Brawlers, the Pirate Captain, Sand Scorpions.
  - Lowlands: Big Green Slimes, the Goblin Chieftain, the Bandit Leader.
  - Midlands: Forest Spiders, the Spider Queen, Swamp Serpents, the Orc King.
  - Highlands: Harpies, Dwarves and the Dwarf King, Ogres, Minotaurs.
  - Godlands: Ghost Gods, White Demons, Sprite Gods, Slime Gods, plus the classic Godlands
    monsters.
- **Monster dungeons**: like RotMG, monsters can drop a portal (open for 60 seconds) to
  their own dungeon:

  | Dropped by | Dungeon | Boss |
  | --- | --- | --- |
  | Pirates | Pirate Cove | Captain Saltbeard |
  | Big Green Slimes | Forest Maze | Mother Mothwing |
  | Snakes | Snake Pit | Ssythra the Serpent Queen |
  | Spiders | Spider Den | Arachnia the Broodmother |
  | Ghost Gods / Liches | Undead Lair | Septorius the Lich King |
  | White Demons | Abyss of Demons | Malgoroth the Archdemon |
  | Sprite Gods | Sprite World | Lumina the Sprite Queen |

  Leaders such as the Pirate Captain and Spider Queen drop their portal far more often.
  Low-level dungeons drop good tiered gear and sometimes a Runed item.
- **Hard multi-boss dungeons**: elite monsters (about 1.5-1.7x health and harder hits) and the
  best loot outside the Dark Elder.
  - **Azrakor's Citadel**: when a realm closes you storm the Dark Elder's Citadel. Kill his two
    lieutenants, Kael'zar the Blood Knight and Morwyn the Hex Queen, and the way to his chamber
    opens.
  - **Tomb of the Three Kings**: Solhar the Sun King, Lunara the Moon Queen and Astrel the
    Star Prince fight you together in the last hall. Every king that falls heals the others a little
    and makes them hit harder. Dropped by the Sand Sphinx.
  - **The Shattered Sanctum**: Glacius the Frost Warden and Ignivar the Flame Warden guard the
    sealed Shattered Seraph, who can't be hurt until both Wardens are dead. Dropped by the
    Phantom Regent and the Lord of the Sunken Lands.

  With several bosses in a dungeon, the boss health bar and quest arrow follow whichever boss is
  nearest.
- **10 realm events**, picked at random, now including Nekhret the Sand Sphinx, the Lord of the
  Sunken Lands, the Tide Hermit and the Skull Shrine.
- Permadeath. Fame from a dead character is added to your account. Like RotMG, the death
  screen lists **fame bonuses**:
  - Ancestor: the first hero of a class to die.
  - Thirsty: level 20 without drinking a stat potion.
  - Well Equipped: wearing four Runed or better items.
  - Set Master: wearing a full set.
  - Well Fed / Fully Maxed: 8/11 or 11/11 maxed stats.
  - Tunnel Rat: 3+ dungeons cleared.
  - Realm Hero: 6+ bosses killed.
  - Elder Slayer: killed the Dark Elder.
  - Godlands Hunter: 100+ Godlands kills.
  - Accurate: hit with 40%+ of your shots.

## Code layout

```
src/NewRealm.as          entry point / screen switching
src/realm/Game.as        game loop, collisions, spawning, rendering
src/realm/World.as       island generation and tile rendering
src/realm/Player.as      movement, shooting, abilities, levelling, items
src/realm/Enemy.as       AI and bullet patterns
src/realm/Data.as        classes, enemies, items, loot tables (balance lives here)
src/realm/Sprites.as     text-defined pixel art, bullets, icons
src/realm/Hud.as         sidebar UI (minimap, bars, gear, inventory, loot bag)
src/realm/Tooltip.as     item tooltip
src/realm/Net.as         connection to other players (the seam for the game server)
src/realm/Online.as      socket connection to a New Realm server
src/realm/ServerNet.as   online Net: real players, chat, parties, guilds, trades
src/realm/WorldSync.as   shared monsters online (world host streams monsters to the others)
src/realm/Bosses.as      every boss fight script, new bosses, raids and realm finales
src/realm/Uniques.as     unique items and which boss drops each one
src/realm/Godly.as       Godly sets (1 in 5,000) and which boss drops each piece
server/server.js         the multiplayer server (Node.js, no dependencies)
server/sim/worldsim.js   server-run monsters: one simulation per realm, dungeon, raid and chamber
server/sim/gen/game.js   GENERATED: Data, Bosses, Uniques, Godly, World and Enemy converted from AS3
tools/as2js.py           the AS3 -> JavaScript converter that writes server/sim/gen/game.js
src/realm/LocalNet.as    offline Net: simulated players who chat, fight and trade
src/realm/RemotePlayer.as another player (position smoothing, public profile)
src/realm/TradeSession.as trade rules (offers, accept lock, space check, swap)
src/realm/TradeWindow.as trade screen; InspectWindow.as player inspect screen
src/realm/SocialWindow.as party and guild window
src/realm/Ui.as          fonts, text, panels and buttons
src/realm/TitleScreen.as home screen, log in / register dialogs
src/realm/Accounts.as    local accounts (salted password hashes)
src/realm/Menu.as        character / class select
src/realm/DeathScreen.as death + fame screen
src/realm/Sfx.as         synthesised sound effects
src/realm/Save.as        local save data (characters, vault, currencies, options)
```

**Server code generated from the game:** the server runs the game's own monster, boss, loot
and map code. After changing `Data.as`, `Bosses.as`, `Uniques.as`, `Godly.as`, `World.as` or
`Enemy.as`, run `python3 tools/as2js.py` and commit the regenerated
`server/sim/gen/game.js`. Then `node server/sim/worldhash.js` prints map fingerprints. The
game's `/thash` test command prints the same ones, so you can check the two still build
identical maps.

To add a monster, add an entry to `Data.ENEMIES` (and optionally a sprite to
`Sprites.DEFS`), then list it in `Data.ZONE_SPAWNS`.
