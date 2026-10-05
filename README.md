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
  potions, gold / Onrane / account fame, backpack, clear inventory, a level 30 pet.
  - **World buttons:** kill all monsters, teleport to the Godlands or the Nexus, finish the
    realm's events (the realm closes and the Dark Elder fight starts), spawn an event now,
    reveal the minimap.
- **Monsters / Bosses**: every monster and boss in the game, sorted by health. Click one to
  spawn it in front of you (toward the mouse).
- **Dungeons**: open a portal to any dungeon next to you, or go straight in. Also has the
  Dark Elder's chamber and a realm portal.
- **Items**: any tier (T0-T7) or rarity (RN, BD, EL, SF, PR) of weapon, ability, armor and
  ring for your class, a full ST set, potions, Sor Crystals and every stat potion.

## Accounts and saves

The game opens on a home screen. The first time you play it asks you to **create an
account** (username and password). PLAY then takes you to character select. The top-right
box lets you log out, switch accounts or change your password, and the game remembers the
last account you used.

There is no server: accounts and saves are stored locally on this computer, in the AIR or
Flash Player local storage. Each account has its own save (characters, vault, gold,
Onrane, fame, pets, skins, quests and achievements). Passwords are never stored as
plain text, only as salted SHA-256 hashes. Progress saved before accounts existed is moved
into the first account you create.

## Controls

| Key | Action |
| --- | --- |
| WASD / arrows | Move |
| Mouse | Aim; hold left button to shoot |
| Space | Class ability (aimed at cursor) |
| F / G | Drink health / magic potion |
| 1-8 | Use or equip the item in that inventory slot |
| R | Return to the Nexus (full heal) |
| Enter | Go through the portal you are standing on |
| Enter (elsewhere) | Chat / commands: `/help`, `/nexus`, `/realm`, `/glands`, `/stats`, `/quests`, `/achievements`, `/tips`, `/admin` |
| I | Toggle auto-fire |
| M | Mute / unmute sound |
| P / Esc | Pause menu (options, Save & Quit) |

**Items work like RotMG, with drag and drop:**
- **Drop:** drag an inventory item onto the ground (anywhere in the game view) to drop it in
  a loot bag.
- **Move:** drag between inventory slots to move or swap items.
- **Equip:** drag onto a gear slot to equip, or drag gear into an empty inventory slot to take it off.
- **Loot bags:** drag items between a loot bag (or the vault) and your inventory.
- **Click:** clicking an item still uses or equips it, and clicking a loot bag item picks
  it up.
- **Shift+click:** sells an item at the Marketplace, and quick-drops it anywhere else.

## Features

The game is modelled closely on **Valor**, the RotMG private server. Its systems come from
the public [Valor wiki](https://github.com/Valor-Inc/Wiki); the names and pixel art are original.

- **8 classes with Valor's stat tables**: Wizard (Spell), Archer (Quiver), Knight (Shield),
  Priest (Tome), Rogue (Cloak, invisibility), Warrior (Helm, berserk), Necromancer (Skull,
  life-draining blast) and Huntress (Trap).
- **11 maxable stats ("11/11")**: the vanilla 8 plus Valor's **Might** (crit damage, +0.1x per
  10), **Luck** (crit chance, +1% per 10) and **Protection**. Gear can also add **Fortune**
  (+1% loot chance per point).
- **PT and SG bars**: Protection fills a white **PT** shield (about 3 PT per point) that
  absorbs damage before HP. **Surge** gains +2 for each kill near you and refills PT at 100.
- **Item tiers and rarities**: tiered gear T0-T7, then New Realm's own rarities, from common
  to rarest. Each has its own colour, tag and loot bag.

  | Rarity | Tag | Colour | What it is |
  | --- | --- | --- | --- |
  | **Runed** | RN | azure | Rare drops from events, dungeons and the Godlands |
  | **Bonded** | BD | jade | Class sets, such as the Wizard's Archmage's set or the Knight's Crusader's set; wearing all 4 pieces gives a set bonus |
  | **Eldritch** | EL | violet | Dropped by the Dark Elder |
  | **Starforged** | SF | gold | Made at the forge, or very rare drops. Weapons carry passives such as Lifebloom, Shardstorm, Frostbite, Executioner and Rampage |
  | **Primordial** | PR | ember red | The rarest drops |
- **Currencies**: account-wide **Gold** and **Onrane**, plus account Fame.
- **The Nexus**: realm portals, a healing fountain, the vault, the Pet Yard, the Fame Store, the **Sor Forge** (a Runed, Bonded
  or Eldritch item + a Sor Crystal + 100 Onrane = a Starforged item) and the **Marketplace** (buy
  potions, stat potions, Sor Crystals, mystery Runed items and a **Backpack**, and shift+click items to sell them). A
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
  chat as `[3/6][Realm: Medusa]`. Clear all 6 events and the realm closes. You're pulled
  into the **Dark Elder's Chamber**, a white arena ringed in red bloodstone, to fight him
  for Eldritch, Starforged and Primordial loot. At a third of his health he becomes immune and
  summons four Elder Crystals. Destroy them all to make him vulnerable again.
- **Dungeons**: event bosses often drop a portal (open for 90 seconds) to one of four
  dungeons: the Sunken Crypt, the Ember Depths (lava pools), the Storm Spire or the
  Forgotten Cellar. Each is a chain of monster rooms with a boss at the end (the Crypt
  Warden, Pyrelord Ignaar, the Tempest Seraph or the Cellar Sorcerer). Most dungeons also
  have a side treasure room with a guarded chest holding a set piece and stat potions.
- **Chat and Valor-style commands** (Enter): `/glands` teleports you to the Godlands, plus
  `/nexus`, `/realm`, `/stats` and `/quests`. One-time tips guide new players.
- **Skill tree (Valor's Ascension)**: at level 20 with 11/11 stats, every 600 XP gives a
  skill point. Spend points on 9 nodes (Brutality, Precision, Ferocity, Vigor, Bulwark,
  Aegis, Swiftness, Leech, Prosperity) in the star tab.
- **Saved characters**: characters are saved automatically and live until they die. The
  title screen lists them under "Your Characters".
- **Status effects**: bosses and dungeon enemies can leave you Slowed, Paralyzed, Confused
  (controls reversed), Armor Broken (0 Defense) or Bleeding (draining HP, no regen).
- **Sound effects**, all synthesised in code: shots, hits, kills, level-ups, loot, rare-drop
  chimes, portals and boss spawns. A banner announces Eldritch, Starforged and Primordial drops.
- **Daily Quest Board** (Valor's daily contracts): three missions picked by date, such as
  "Clear a dungeon" or "Defeat 2 realm event bosses", paying gold and Onrane.
- **Quest arrow** (like RotMG's quest marker): a gold arrow at the edge of the screen points
  to your current objective, with its name and distance. That's the area boss, the nearest
  Elder Crystal while the Dark Elder is immune, or a monster suited to your level.
- **Achievements**: 16 account-wide goals, such as First Blood, Dungeon Master, Treasure
  Hunter, Bane of Azrakor and Perfection (11/11). Each pays gold and Onrane once. See them
  at the Quest Board, or type `/achievements`.
- **Screen shake** on heavy hits, explosions and boss deaths.
- **Pause menu** with Resume, sound, damage numbers, particle and screen shake toggles, and Save & Quit
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
src/realm/Ui.as          fonts, text, panels and buttons
src/realm/TitleScreen.as home screen, log in / register dialogs
src/realm/Accounts.as    local accounts (salted password hashes)
src/realm/Menu.as        character / class select
src/realm/DeathScreen.as death + fame screen
src/realm/Sfx.as         synthesised sound effects
src/realm/Save.as        local save data (characters, vault, currencies, options)
```

To add a monster, add an entry to `Data.ENEMIES` (and optionally a sprite to
`Sprites.DEFS`), then list it in `Data.ZONE_SPAWNS`.
