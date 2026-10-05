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
| I | Toggle auto-fire |
| P / Esc | Pause |

To pick up loot, stand on a loot bag and click its items in the sidebar. Click an
inventory item to equip or drink it, and shift+click to drop it.

## Features

- **4 classes**: Wizard (twin-bolt staff, Spell Bomb), Archer (piercing arrows, slowing
  Quiver), Knight (sword, stunning Shield Bash) and Priest (wand, Holy Tome heal).
- **The Nexus hub.** Every character starts in the Nexus: a walled stone hall with red
  carpets, braziers and a healing fountain. Three portals along the north wall each lead
  to their own realm, and their labels show the realm's Overlord progress. Press R (or
  the temple button) to return from anywhere. The **vault** chest on the west side stores
  up to 8 items that carry over between characters: shift+click an inventory item while
  standing at the vault to deposit it, and click a vault item to take it out. After you
  kill a realm's Cube Overlord, that realm closes 30 seconds later and its portal opens
  a fresh realm.
- **Procedurally generated island realms.** Difficulty rises as you head inland:
  Shore → Lowlands → Midlands → Godlands. Brick ruins are scattered inland, and the
  Godlands ruins have lava rivers that burn you. You start in the Safe Haven, where
  enemies and their bullets can't reach you.
- **14 monster types** with different movement (chase, orbit, wander, charge) and bullet
  patterns (aimed spreads, rings, spirals).
- **Cube Overlord boss.** It appears in the Godlands after enough kills, fights in three
  phases (spirals, rings with summoned cubelets, an enraged bullet storm), and drops
  a white bag with UT gear.
- **Loot**: T0–T7 weapons, abilities and armour, rings (T0–T5) and UT items. Bag colour shows rarity
  (brown → purple → cyan → white). There are also health/magic potions and stat potions
  that permanently raise stats up to each class's max.
- **Levels 1–20** with per-class stat growth, RotMG-style defence and dexterity formulas.
- **Permadeath and fame.** When you die, the death screen shows who killed you and the
  fame you earned. Your best fame and best level per class are saved.
- **RotMG-style HUD**: fog-of-war minimap with zoom, Lvl/Fame/HP/MP bars, 4 equipment
  slots (weapon, ability, armour, ring), Items/Stats tabs, potion counters, loot bag panel,
  item tooltips, a boss damage tracker, and a chat log with taunts from the Mad Sovereign.

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
```

To add a monster, add an entry to `Data.ENEMIES` (and optionally a sprite to
`Sprites.DEFS`), then list it in `Data.ZONE_SPAWNS`.
