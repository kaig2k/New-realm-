# New Realm

A top-down bullet-hell adventure inspired by *Realm of the Mad God*, written in pure
ActionScript 3 for **Adobe AIR**. All of the pixel art is generated in code: 8x8 sprites
scaled 5x with thin outlines and drop shadows, textured tiles, and rotated projectiles.

![screenshot](docs/screenshot.png)
![nexus](docs/nexus.png)

## Play it

A pre-built `bin/NewRealm.swf` is included, so you only need an AIR SDK
([HARMAN AIR SDK](https://airsdk.harman.io/), or the old Adobe AIR SDK 32).

```sh
# macOS / Linux
AIR_SDK=/path/to/AIRSDK ./run.sh

# Windows
set AIR_SDK=C:\AIRSDK
run.bat
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
| Enter (elsewhere) | Chat / commands: `/help`, `/nexus`, `/realm`, `/glands`, `/stats`, `/quests`, `/achievements`, `/tips` |
| I | Toggle auto-fire |
| M | Mute / unmute sound |
| P / Esc | Pause menu (options, Save & Quit) |

To pick up loot, stand on a loot bag and click its items in the sidebar. Click an
inventory item to equip or drink it, and shift+click to drop it.

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
- **Valor item tiers**: T0-T7, then **UT**, **ST** (class set items, such as the Wizard's
  Archmage's set or the Knight's Crusader's set; wearing all 4 pieces gives a set bonus),
  **FB** (Fabled), **LG** (Legendary, with passives such as Lifebloom, Shardstorm,
  Frostbite, Executioner and Rampage) and **AR** (Ancient Relic). Each has its own coloured
  tag and loot bag.
- **Currencies**: account-wide **Gold** and **Onrane**, plus account Fame.
- **The Nexus**: realm portals, a healing fountain, the vault, the Pet Yard, the **Sor Forge** (a UT, ST
  or FB item + a Sor Crystal + 100 Onrane = a Legendary) and the **Marketplace** (buy
  potions, stat potions, Sor Crystals, mystery UTs and a **Backpack**, and shift+click items to sell them). A
  backpack gives that character 8 more inventory slots. Switch pages with the button by
  the sidebar tabs; keys 1-8 use the page you're on.
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
  for Fabled, Legendary and Relic loot. At a third of his health he becomes immune and
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
  chimes, portals and boss spawns. A banner announces Legendary, Relic and Fabled drops.
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
- **Boss damage meter** with your damage share and the LG threshold.
- Procedurally generated island realms: Shore → Lowlands → Midlands → Godlands, with brick
  ruins and lava. Each zone has five monster types, such as Sea Slimes, Dire Wolves,
  Stone Golems and teleporting Liches. Fewer, smaller packs spawn near the shore so new
  characters can level up.
- Permadeath. Fame from a dead character is added to your account. Like RotMG, the death
  screen lists **fame bonuses**:
  - Ancestor: the first hero of a class to die.
  - Thirsty: level 20 without drinking a stat potion.
  - Well Equipped: wearing four UT or better items.
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
src/realm/Menu.as        title / class select
src/realm/DeathScreen.as death + fame screen
src/realm/Sfx.as         synthesised sound effects
src/realm/Save.as        local save data (characters, vault, currencies, options)
```

To add a monster, add an entry to `Data.ENEMIES` (and optionally a sprite to
`Sprites.DEFS`), then list it in `Data.ZONE_SPAWNS`.
