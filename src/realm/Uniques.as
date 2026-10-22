package realm {
	/**
	 * Unique items: named Runed gear with fixed stats and its own way of
	 * shooting. Each one drops from one boss only (listed in Bosses.as).
	 *
	 * Entry: [name, kind, sub, stats, extras, lore]
	 *   weapon extras: mult (damage), shots, arc, parallel, rate, spd (shot speed),
	 *                  range (lifetime), motion, pierce, shape, col, passive, size
	 *   ability extras: power
	 */
	public class Uniques {
		public static const ALL:Object = {
			// ---- Captain Saltbeard (Pirate Cove)
			saltbeard_cutlass: ["Saltbeard's Cutlass", "weapon", "sword", {dex: 4}, {shots: 3, arc: 26, mult: 0.62, col: 0xe0c070}, "Three swings in one. Still smells of rum."],
			parrot_charm: ["Polly's Charm", "ring", "spd", {spd: 6, dex: 6}, null, "The captain's parrot never missed a thing."],
			powder_keg: ["Powder Keg", "ability", "trap", {att: 4}, {power: 1.7}, "Handle with care. Or don't."],
			// ---- Mother Mothwing (Forest Maze)
			lantern_wand: ["Moonlantern Wand", "weapon", "wand", {wis: 5}, {shots: 2, parallel: true, motion: "wave", mult: 0.7, col: 0xfff0a0}, "Its twin lights weave like moths around a flame."],
			mothwing_cloak: ["Mothwing Cloak", "ability", "cloak", {spd: 8}, {power: 1.6}, "Dusted with scales that shimmer out of sight."],
			dustveil_robe: ["Dustveil Robe", "armor", "robe", {wis: 8, mp: 40}, null, "Woven by a thousand tiny wings."],
			// ---- Ssythra the Serpent Queen (Snake Pit)
			fang_of_ssythra: ["Fang of Ssythra", "weapon", "dagger", {dex: 4}, {shots: 2, parallel: true, motion: "wave", mult: 0.8, col: 0x60e060}, "Strikes twice, weaving like a snake."],
			venom_quiver: ["Venomtip Quiver", "ability", "quiver", {dex: 5}, {power: 1.7}, "Every arrow drips with the queen's venom."],
			scaled_hide: ["Serpentscale Hide", "armor", "leather", {spd: 6, vit: 5}, null, "Shed by the queen herself."],
			// ---- Arachnia the Broodmother (Spider Den)
			widowmaker: ["The Widowmaker", "weapon", "bow", {}, {shots: 1, mult: 2.2, rate: 0.7, pierce: true, passive: "frost", col: 0xd0c040}, "One silk-strung arrow. One is enough."],
			silkspinner: ["Silkspinner Snare", "ability", "trap", {wis: 6}, {power: 1.8}, "Webs that hold even the strongest."],
			chitin_mail: ["Chitin Mail", "armor", "heavy", {hp: 60, vit: 6}, null, "Plates of the Broodmother's shell."],
			// ---- The Crypt Warden (Sunken Crypt)
			wardens_lantern: ["The Warden's Lantern", "ability", "tome", {wis: 8}, {power: 1.8}, "It lit the way for the dead. Now it lights yours."],
			cryptkeeper_blade: ["Cryptkeeper's Blade", "weapon", "sword", {def: 4}, {motion: "return", pierce: true, range: 1.5, mult: 0.85, col: 0x6ad0ff}, "Thrown blades that always come home."],
			gravebind_ring: ["Gravebind Ring", "ring", "hp", {hp: 80, vit: 6}, null, "Cold to the touch. Warm to the living."],
			// ---- Pyrelord Ignaar (Ember Depths)
			emberheart_staff: ["Emberheart Staff", "weapon", "staff", {att: 4}, {shots: 3, arc: 18, parallel: false, mult: 0.8, col: 0xff7020}, "A heart of living flame, split three ways."],
			magma_plate: ["Magma Plate", "armor", "heavy", {att: 6, hp: 40}, null, "Forged in the Pyrelord's own furnace."],
			cinder_ring: ["Cinder Ring", "ring", "att", {att: 7, dex: 4}, null, "It never stops smoldering."],
			// ---- Tempest Seraph (Storm Spire)
			stormcall_bow: ["Stormcall Bow", "weapon", "bow", {dex: 4}, {shots: 5, arc: 30, mult: 0.55, rate: 1.15, col: 0xfff060}, "Five bolts of lightning per draw."],
			tempest_quiver: ["Tempest Quiver", "ability", "quiver", {spd: 6}, {power: 1.9}, "The wind itself carries these arrows."],
			thunderhide: ["Thunderhide", "armor", "leather", {dex: 8, spd: 6}, null, "Crackles when you move."],
			// ---- the Starfall Vault
			// abilities for Eldmere's own classes
			everburning_flask: ["Everburning Flask", "ability", "flask", {att: 4, dex: 5}, {power: 1.7}, "Ignis's own fire, corked. It is never quite cool."],
			siren_lyre: ["Lyre of the Drowned Siren", "ability", "lyre", {wis: 6, mp: 40}, {power: 1.7}, "Pulled from the Archive's flooded stacks, still dripping. Its song carries underwater."],
			hourglass_fallen_star: ["Hourglass of the Fallen Star", "ability", "hourglass", {wis: 6, dex: 5}, {power: 1.8}, "The sand inside is starlight. It falls upward."],
			ignis_brand: ["Brand of Ignis", "weapon", "sword", {att: 5}, {shots: 3, arc: 20, mult: 0.72, col: 0xffb040}, "Still warm from the Hall of Embers."],
			drowned_codex: ["The Drowned Codex", "ability", "tome", {wis: 9, vit: 4}, {power: 1.9}, "Every page is wet, and every word still works."],
			sovereign_signet: ["Bone Sovereign's Signet", "ring", "hp", {hp: 90, def: 6, vit: 4}, null, "Morvath wore it for a thousand years. It remembers."],
			starfall_staff: ["Starfall", "weapon", "staff", {att: 6, wis: 4}, {shots: 4, arc: 24, mult: 0.62, motion: "wave", col: 0xfff0a0}, "A shard of the star itself, still falling."],
			fallen_star_mantle: ["Mantle of the Fallen Star", "armor", "robe", {hp: 80, mp: 60, wis: 8}, null, "It glows faintly in the dark, like a memory of the sky."],
			// ---- The Cellar Sorcerer (Forgotten Cellar)
			illusionist_wand: ["Illusionist's Wand", "weapon", "wand", {wis: 4}, {shots: 3, arc: 20, motion: "wave", mult: 0.6, col: 0x80c0ff}, "Which bolt is real? All of them."],
			mirror_cloak: ["Cloak of Mirrors", "ability", "cloak", {dex: 6}, {power: 1.9}, "You were never there."],
			arcane_vestments: ["Arcane Vestments", "armor", "robe", {mp: 80, wis: 10}, null, "Stitched with runes that hum softly."],
			// ---- Septorius the Lich King (Undead Lair)
			phylactery: ["Phylactery of Septorius", "ability", "skull", {wis: 10}, {power: 2.0}, "The Lich King's soul, still screaming."],
			soulreaper: ["Soulreaper Staff", "weapon", "staff", {att: 5}, {pierce: true, range: 1.35, mult: 1.0, col: 0x40ffb0}, "Its bolts pass through flesh and bone alike."],
			deathshroud: ["Deathshroud", "armor", "robe", {hp: 60, att: 5}, null, "Worn by the Lich in life. And after."],
			// ---- Malgoroth the Archdemon (Abyss of Demons)
			hellfire_blade: ["Hellfire Greatblade", "weapon", "sword", {att: 6}, {mult: 1.9, rate: 0.7, size: 6, col: 0xff3010}, "Slow, heavy, and furious."],
			infernal_helm: ["Infernal Helm", "ability", "helm", {att: 6}, {power: 1.9}, "Horns of the Archdemon, hammered into a crown."],
			brimstone_ring: ["Brimstone Ring", "ring", "att", {att: 9, vit: 3}, null, "Burns with the Abyss's anger."],
			// ---- Lumina the Sprite Queen (Sprite World)
			prismatic_wand: ["Prismatic Wand", "weapon", "wand", {}, {shots: 3, arc: 30, rate: 1.1, mult: 0.6, col: 0xff80e0}, "Every color at once."],
			fae_quiver: ["Quiver of the Fae", "ability", "quiver", {spd: 10}, {power: 1.7}, "Light as a sprite's wing."],
			pixie_ring: ["Pixie Ring", "ring", "spd", {spd: 10, dex: 6}, null, "It giggles."],
			// ---- the Endless Abyss (the Abyssal Herald)
			voidrend: ["Voidrend", "weapon", "dagger", {dex: 6, att: 3}, {shots: 3, arc: 16, pierce: true, mult: 0.75, col: 0xc060ff}, "It cuts the dark itself."],
			abyssal_crown: ["Abyssal Crown", "ability", "helm", {wis: 6, hp: 40}, {power: 1.9}, "Worn by whoever reaches the bottom. Nobody has."],
			depthstone: ["Depthstone", "ring", "def", {def: 8, vit: 6, hp: 40}, null, "Heavier the deeper you go."],
			// ---- the Realm Siege (Vorgath)
			siegebreaker: ["Siegebreaker", "weapon", "sword", {att: 6, def: 4}, {mult: 1.9, size: 7, pierce: true, rate: 0.75, col: 0xffa020}, "Forged to bring down gates. Works on warlords too."],
			warlords_banner: ["Warlord's Banner", "ability", "helm", {att: 5, vit: 5}, {power: 1.9}, "Where it flies, armies follow."],
			rampart_plate: ["Rampart Plate", "armor", "heavy", {def: 10, hp: 80}, null, "A piece of the wall he couldn't break."],
			// ---- realm events
			cube_core: ["Cube Core", "ring", "hp", {hp: 100, def: 5}, null, "A perfect, humming cube."],
			cubic_staff: ["Cubic Staff", "weapon", "staff", {wis: 4}, {shots: 4, parallel: true, mult: 0.55, col: 0xc060ff}, "Four parallel bolts, perfectly aligned."],
			titanbreaker: ["Titanbreaker", "weapon", "sword", {vit: 4}, {mult: 1.6, size: 6, pierce: true, rate: 0.8, col: 0xffa040}, "Made to fell giants."],
			ember_mantle: ["Ember Mantle", "armor", "heavy", {att: 6, vit: 6}, null, "Still warm from the Titan's fires."],
			frostfang: ["Frostfang", "weapon", "dagger", {dex: 5}, {shots: 2, arc: 10, passive: "frost", mult: 0.85, col: 0xa0e8ff}, "A sliver of the Frost Wyrm's tooth."],
			wyrmscale: ["Wyrmscale Hide", "armor", "leather", {def: 6, spd: 5}, null, "Each scale as cold as ice."],
			hollow_crown: ["The Hollow Crown", "ability", "helm", {hp: 50}, {power: 1.8}, "Heavy is the head."],
			kings_ransom: ["King's Ransom", "ring", "luc", {luc: 8, frt: 10}, null, "Gold attracts gold."],
			gorehorn_bow: ["Gorehorn Longbow", "weapon", "bow", {att: 4}, {shots: 1, mult: 1.5, pierce: true, range: 1.3, col: 0x9aff5a}, "Strung with the Behemoth's sinew."],
			behemoth_hide: ["Behemoth Hide", "armor", "heavy", {hp: 100, def: 6}, null, "Nothing gets through. Almost nothing."],
			regents_scepter: ["Regent's Scepter", "weapon", "wand", {wis: 5}, {motion: "return", pierce: true, mult: 1.0, col: 0xc090ff}, "Commands every bolt to return."],
			phantom_veil: ["Phantom Veil", "ability", "cloak", {dex: 5}, {power: 2.0}, "Between this world and the next."],
			riddle_tome: ["Tome of Riddles", "ability", "tome", {wis: 8}, {power: 1.9}, "The answer is always 'heal'."],
			sandglass_ring: ["Sandglass Ring", "ring", "dex", {dex: 8, spd: 4}, null, "Time runs faster around it."],
			sunken_trident: ["Trident of the Deep", "weapon", "staff", {}, {shots: 3, arc: 14, motion: "wave", mult: 0.7, col: 0x60e0ff}, "Three tides, weaving together."],
			drowned_plate: ["Drowned Plate", "armor", "heavy", {def: 6, vit: 8}, null, "Barnacles included."],
			tidecaller: ["Tidecaller Quiver", "ability", "quiver", {wis: 5}, {power: 1.8}, "Arrows that ride the waves."],
			hermit_shell: ["Hermit's Shell", "ring", "def", {def: 8, hp: 40}, null, "Crawl inside and wait it out."],
			skullforge: ["Skullforge", "ability", "skull", {att: 5}, {power: 2.0}, "Hammered on the Shrine's own altar."],
			shrineflame: ["Shrineflame Staff", "weapon", "staff", {}, {passive: "shards", mult: 0.95, col: 0xff8a20}, "The eternal flame, on a stick."],
			obsidian_maul: ["Obsidian Maul", "weapon", "sword", {def: 5}, {mult: 1.8, rate: 0.65, size: 6, col: 0xb060ff}, "Volcanic glass. Very heavy."],
			colossus_core: ["Colossus Core", "ring", "def", {def: 10, vit: 4}, null, "The heart of a mountain."],
			phoenix_quill: ["Phoenix Quill", "weapon", "bow", {}, {shots: 3, arc: 12, passive: "lifesteal", mult: 0.7, col: 0xffa030}, "Every hit rekindles you."],
			rebirth_tome: ["Tome of Rebirth", "ability", "tome", {hp: 40}, {power: 2.1}, "From ashes, again and again."],
			hexbound_wand: ["Hexbound Wand", "weapon", "wand", {}, {passive: "frost", shots: 2, arc: 12, mult: 0.75, col: 0x80ff60}, "Its curses slow the cursed."],
			witchs_brew: ["Witch's Brew", "ability", "trap", {wis: 8}, {power: 2.0}, "Do not drink."],
			krakens_grasp: ["Kraken's Grasp", "weapon", "dagger", {}, {shots: 3, arc: 40, motion: "return", mult: 0.6, col: 0xff6080}, "Tentacles that pull back."],
			abyssal_mail: ["Abyssal Mail", "armor", "leather", {def: 4, mp: 40, dex: 4}, null, "Pressure-forged in the deep."],
			// ---- hard dungeons
			solar_crown: ["Crown of the Sun King", "ability", "helm", {att: 8, hp: 60}, {power: 2.2}, "Blinding."],
			sunfire_staff: ["Sunfire Staff", "weapon", "staff", {att: 4}, {shots: 3, arc: 12, passive: "rampage", mult: 0.9, col: 0xffd040}, "The noon sun, in your hands."],
			moonlight_bow: ["Moonlight Bow", "weapon", "bow", {wis: 5}, {shots: 3, arc: 10, motion: "wave", passive: "frost", mult: 0.75, col: 0xb0c0ff}, "Silver arrows that dance."],
			lunar_robe: ["Lunar Robe", "armor", "robe", {mp: 100, wis: 12}, null, "Glows faintly at night."],
			starfall_dagger: ["Starfall Dagger", "weapon", "dagger", {dex: 6}, {shots: 3, arc: 18, passive: "shards", mult: 0.7, col: 0xd080ff}, "Fallen stars, sharpened."],
			astral_cloak: ["Astral Cloak", "ability", "cloak", {spd: 8}, {power: 2.2}, "Step between the stars."],
			glacial_plate: ["Glacial Plate", "armor", "heavy", {def: 8, vit: 8}, null, "Never melts."],
			icicle_ring: ["Icicle Ring", "ring", "dex", {dex: 8, spd: 8}, null, "Sharp and quick."],
			flamewarden_blade: ["Flamewarden's Blade", "weapon", "sword", {vit: 5}, {passive: "lifesteal", mult: 1.3, col: 0xff6020}, "Guards its wielder's life."],
			ember_ring: ["Ember Ring", "ring", "att", {att: 8, hp: 40}, null, "A spark that never dies."],
			shardwing_bow: ["Shardwing Bow", "weapon", "bow", {}, {shots: 6, arc: 40, pierce: true, mult: 0.55, col: 0xff60c0}, "Shards of a broken angel."],
			seraph_halo: ["Halo of the Seraph", "ability", "tome", {hp: 80, wis: 6}, {power: 2.4}, "Cracked, but still holy."],
			bloodletter: ["Bloodletter", "weapon", "sword", {att: 5}, {passive: "lifesteal", mult: 1.5, size: 5, col: 0xd02030}, "It drinks so you don't have to."],
			sanguine_plate: ["Sanguine Plate", "armor", "heavy", {hp: 120, att: 6}, null, "Red, and getting redder."],
			hexweave_robe: ["Hexweave Robe", "armor", "robe", {wis: 12, att: 6}, null, "Every thread a curse."],
			cursed_skull: ["The Cursed Skull", "ability", "skull", {wis: 6}, {power: 2.3}, "It whispers your name."],
			// ---- realm finales
			elder_scepter: ["Scepter of Azrakor", "weapon", "staff", {att: 6}, {shots: 4, arc: 24, passive: "shards", mult: 0.85, col: 0xc060ff}, "The Dark Elder's own staff."],
			crown_of_azrakor: ["Crown of Azrakor", "ability", "helm", {att: 8, def: 8}, {power: 2.5}, "Kneel before no one."],
			tidebreaker: ["Tidebreaker", "weapon", "bow", {}, {shots: 4, arc: 18, motion: "wave", pierce: true, mult: 0.8, col: 0x40d0ff}, "The Empress's own bow, still dripping."],
			empress_coral: ["Empress Coral", "ring", "hp", {hp: 120, wis: 10}, null, "A living crown of coral."],
			gearblade: ["Gearblade", "weapon", "dagger", {dex: 6}, {shots: 2, arc: 8, motion: "return", rate: 1.2, mult: 0.8, col: 0xffd060}, "Spinning cogs that come back for more."],
			cogwork_plate: ["Cogwork Plate", "armor", "heavy", {def: 10, dex: 6}, null, "Ticks softly."],
			voidfang: ["Voidfang", "weapon", "sword", {att: 6}, {shots: 3, arc: 30, pierce: true, passive: "critical", mult: 0.9, col: 0xd040ff}, "A tooth of the Void Dragon."],
			dragonscale: ["Void Dragonscale", "armor", "leather", {def: 8, att: 8, spd: 6}, null, "Darker than the night sky."],
			// ---- raids
			blood_chalice: ["Blood Chalice", "ability", "tome", {hp: 100}, {power: 2.6}, "Drink deep."],
			vesper_staff: ["Vesper's Staff", "weapon", "staff", {att: 8}, {shots: 5, arc: 40, motion: "wave", passive: "lifesteal", mult: 0.65, col: 0xff3060}, "The Archon's last word."],
			crimson_crown: ["Crimson Crown", "ring", "att", {att: 12, dex: 8, hp: 60}, null, "Worn by the Conclave's master."],
			galecaller_bow: ["Galecaller's Bow", "weapon", "bow", {dex: 8}, {shots: 4, arc: 16, rate: 1.3, mult: 0.7, col: 0x80ffff}, "Arrows ride the gale."],
			heart_of_storm: ["Heart of the Storm", "ring", "spd", {spd: 12, dex: 12}, null, "It beats like thunder."],
			stormbreaker: ["Stormbreaker", "weapon", "sword", {att: 6}, {shots: 3, arc: 18, pierce: true, passive: "rampage", mult: 1.0, col: 0xffff60}, "Splits the sky in three."],
			// ---- Primordial: with the ones above, a raid master's unique for every item there is
			// Archon Vesper (the Conclave)
			vesper_kiss: ["Vesper's Kiss", "weapon", "dagger", {dex: 6, att: 4}, {shots: 2, arc: 10, motion: "wave", passive: "lifesteal", mult: 0.9, col: 0xff3060}, "Two red lips of steel. Every cut is a little drink."],
			bloodsworn_bulwark: ["Bloodsworn Bulwark", "armor", "heavy", {hp: 120, def: 8, vit: 4}, null, "Quenched in the Conclave's altar. It closes its own wounds."],
			red_mass_codex: ["Codex of the Red Mass", "ability", "tome", {hp: 60, wis: 8}, {power: 2.5}, "The Conclave's hymnal. Its pages are warm."],
			first_zealot_skull: ["Skull of the First Zealot", "ability", "skull", {wis: 8, att: 4}, {power: 2.5}, "He was the first to kneel. He never stood up again."],
			vesper_shroud: ["Vesper's Shroud", "ability", "cloak", {dex: 8, spd: 6}, {power: 2.4}, "Night falls wherever he stands."],
			heartblood_signet: ["Heartblood Signet", "ring", "hp", {hp: 80, vit: 8}, null, "It beats a moment before you do."],
			unbleeding_ring: ["Ring of the Unbleeding", "ring", "vit", {vit: 10, hp: 60}, null, "Wounds close before they open."],
			archon_brand: ["Brand of the Archon", "ring", "mgt", {mgt: 10, att: 6}, null, "His mark, burned into gold."],
			// Tempestus (the Storm Spire raid)
			tempest_eye: ["Eye of the Tempest", "weapon", "bow", {dex: 8}, {shots: 3, arc: 14, pierce: true, passive: "critical", rate: 1.2, mult: 0.85, col: 0x9ae8ff}, "Draw it and the air goes still. Loose it and the sky breaks."],
			stormweave_jerkin: ["Stormweave Jerkin", "armor", "leather", {dex: 8, spd: 8, def: 4}, null, "Woven from cloud. It never quite dries."],
			rolling_thunder: ["Quiver of Rolling Thunder", "ability", "quiver", {dex: 8, spd: 4}, {power: 2.4}, "Each arrow arrives a heartbeat before its own thunder."],
			squall_crown: ["Crown of the Squall", "ability", "helm", {att: 6, spd: 6}, {power: 2.4}, "Put it on and charge like the wind."],
			cyclone_snare: ["Cyclone Snare", "ability", "trap", {wis: 6, dex: 6}, {power: 2.4}, "Step in, and the storm keeps you."],
			galeband: ["Galeband", "ring", "dex", {dex: 10, spd: 6}, null, "Your hands move with the wind."],
			stormwall_ring: ["Stormwall Ring", "ring", "def", {def: 10, hp: 60}, null, "The eye of the storm is always calm."],
			lightning_rod: ["The Lightning Rod", "ring", "prt", {prt: 10, def: 4}, null, "It takes the strike so you don't."],
			// Astraeon (the Starfall Vault)
			seventh_star_wand: ["Wand of the Seventh Star", "weapon", "wand", {wis: 8, att: 4}, {shots: 3, arc: 16, motion: "seek", mult: 0.75, col: 0xfff0a0}, "Its sparks find their mark the way stars find the dark."],
			falling_sky_spell: ["Spell of the Falling Sky", "ability", "spell", {att: 6, wis: 6}, {power: 2.5}, "Read it aloud and the heavens answer."],
			star_throne_aegis: ["Aegis of the Star Throne", "ability", "shield", {def: 8, hp: 80}, {power: 2.5}, "Astraeon's own shield. Starlight pours off its rim."],
			liquid_starlight: ["Flask of Liquid Starlight", "ability", "flask", {att: 5, dex: 6}, {power: 2.4}, "Too bright to look at. Throw it anyway."],
			lyre_of_spheres: ["Lyre of the Spheres", "ability", "lyre", {wis: 8, mp: 60}, {power: 2.4}, "It plays the music the planets hum."],
			starwell_ring: ["Starwell Ring", "ring", "mp", {mp: 80, wis: 6}, null, "A well with no bottom, full of light."],
			eye_of_astraeon: ["Eye of Astraeon", "ring", "wis", {wis: 10, mp: 40}, null, "It saw the world before it fell."],
			comets_tail: ["Comet's Tail", "ring", "luc", {luc: 10, dex: 6}, null, "Bright, fast, and always on target."]
		};

		/**
		 * The item ladder (the Tier Changes plan): every UT and Legendary has fixed numbers and a special.
		 * n name, k kind, s sub, r rarity, st stats (luc is Focus, mgt Fury, prt Warding), and by kind:
		 *  weapons: d [min, max] a shot, sh shots, rt fire rate, rg range (x a normal one), arc, par (side
		 *           by side), mo motion, pc pierce, eff hit effect, sp shot speed, split, boom, walls,
		 *           passive, x (specials that need their own code: prism, hex, trail, armor), sfk (how
		 *           much of its slot's Starforged budget goes to damage: long reach gives some up)
		 *  abilities: pw power, ab which ability, abx what the item does to it
		 *  armour: df Defense
		 * txt is the special as players read it.
		 */
		public static const FIXED:Object = {
			// ---- early dungeons (UT, T4-T5)
			saltbeard_cutlass: {n: "Saltbeard's Cutlass", k: "weapon", s: "sword", r: "ut", st: {dex: 2}, d: [36, 50], sh: 3, rt: 1, arc: 26, txt: "Three blades in a wide fan: good against groups."},
			swashbuckler_tunic: {n: "Swashbuckler's Tunic", k: "armor", s: "leather", r: "ut", df: 14, st: {spd: 4, dex: 4}, txt: "T4 defense with agility on top.", lore: "Cut for boarding actions."},
			pirates_treasure: {n: "Pirate's Treasure", k: "ring", s: "luc", r: "ut", st: {luc: 12, mgt: 12, dex: 2}, txt: "The crit ring.", lore: "X marked the spot."},
			lantern_wand: {n: "Moonlantern Wand", k: "weapon", s: "wand", r: "ut", st: {wis: 3}, d: [30, 42], sh: 2, rt: 1, par: true, mo: "wave", txt: "Twin shots, side by side, weaving."},
			dustveil_robe: {n: "Dustveil Robe", k: "armor", s: "robe", r: "ut", df: 8, st: {mp: 60, wis: 5}, txt: "Less defense, more mana."},
			mothwing_cloak: {n: "Mothwing Cloak", k: "ability", s: "cloak", r: "ut", pw: 1.8, st: {spd: 4}, ab: "shadowstep", abx: {invis: 0.5}, txt: "Shadowstep leaves you invisible 0.5s longer."},
			fang_of_ssythra: {n: "Fang of Ssythra", k: "weapon", s: "dagger", r: "ut", st: {dex: 3}, d: [42, 60], sh: 2, rt: 1, rg: 1.2, mo: "wave", txt: "A snake-like weave with a wider reach."},
			venomspit_staff: {n: "Venomspit Staff", k: "weapon", s: "staff", r: "ut", st: {att: 2}, d: [42, 58], sh: 2, rt: 1, pc: true, col: 0x9aff50, txt: "Shots pierce through enemies.", lore: "It still drips."},
			venom_quiver: {n: "Venomtip Quiver", k: "ability", s: "quiver", r: "ut", pw: 1.8, st: {dex: 3}, ab: "arrowstorm", abx: {poison: true}, txt: "Arrow Storm also poisons, ignoring defense."},
			widowmaker: {n: "The Widowmaker", k: "weapon", s: "bow", r: "ut", st: {}, d: [125, 175], sh: 1, rt: 0.7, rg: 1.4, pc: true, eff: "slow", txt: "One long piercing arrow that slows its target."},
			chitin_mail: {n: "Chitin Mail", k: "armor", s: "heavy", r: "ut", df: 19, st: {hp: 40, vit: 4}, txt: "T4 defense with health and regeneration."},
			carapace_band: {n: "Carapace Band", k: "ring", s: "hp", r: "ut", st: {hp: 60, def: 4, vit: 3}, txt: "The tank ring.", lore: "Shed by the Broodmother's eldest."},
			// ---- Godlands dungeons (UT between T6 and T7, a Legendary each)
			soulreaper: {n: "Soulreaper Staff", k: "weapon", s: "staff", r: "ut", st: {att: 4}, d: [75, 100], sh: 2, rt: 1, rg: 1.3, pc: true, txt: "Shots pierce and fly further than a normal staff's."},
			deathshroud: {n: "Deathshroud", k: "armor", s: "robe", r: "ut", df: 14, st: {mp: 60, hp: 40, att: 4}, txt: "A sturdier caster robe."},
			bonebind_snare: {n: "Bonebind Snare", k: "ability", s: "trap", r: "ut", pw: 2.1, st: {wis: 4}, ab: "snare", abx: {rootVuln: 0.15}, txt: "Rooted monsters take 15% more damage.", lore: "Woven from the Lich King's own ribs."},
			phylactery: {n: "Phylactery of Septorius", k: "ability", s: "skull", r: "lg", pw: 2.7, st: {mp: 60, wis: 8, att: 5}, ab: "harvest", abx: {skulls: 3}, txt: "Sustained: Soul Harvest raises 3 spirit skulls instead of 2."},
			imps_fang: {n: "Imp's Fang", k: "weapon", s: "dagger", r: "ut", st: {dex: 5, spd: 3}, d: [64, 88], sh: 2, rt: 1.15, txt: "Fast-firing.", lore: "Snapped off a laughing imp."},
			demonhide_plate: {n: "Demonhide Plate", k: "armor", s: "heavy", r: "ut", df: 28, st: {att: 5, mgt: 3}, txt: "An attacking heavy armor.", lore: "Still warm."},
			infernal_helm: {n: "Infernal Helm", k: "ability", s: "helm", r: "ut", pw: 2.1, st: {att: 4, def: 3}, ab: "charge", abx: {fireTrail: true}, txt: "Berserker Charge leaves a trail of fire."},
			hellfire_blade: {n: "Hellfire Greatblade", k: "weapon", s: "sword", r: "lg", st: {att: 8}, d: [560, 760], sh: 1, rt: 0.45, rg: 2, pc: true, shape: "blade", sfk: 0.85, txt: "Javelin: one thrown blade, huge piercing hits at long range."},
			spritestring_bow: {n: "Spritestring Bow", k: "weapon", s: "bow", r: "ut", st: {dex: 4}, d: [58, 80], sh: 3, rt: 1, mo: "seek", txt: "Arrows curve slightly toward targets.", lore: "Strung with a pixie's hair. She wants it back."},
			faesilk_tunic: {n: "Faesilk Tunic", k: "armor", s: "leather", r: "ut", df: 21, st: {spd: 5, dex: 4}, txt: "Light and quick.", lore: "It weighs less than its own shadow."},
			pixiesong_lyre: {n: "Pixiesong Lyre", k: "ability", s: "lyre", r: "ut", pw: 2.1, st: {wis: 4, mp: 40}, ab: "valor", abx: {dur: 1}, txt: "Ballad of Valor lasts 1s longer.", lore: "It only knows happy songs."},
			prismatic_wand: {n: "Prismatic Wand", k: "weapon", s: "wand", r: "lg", st: {wis: 6, dex: 4}, d: [40, 54], sh: 3, rt: 1.1, arc: 8, x: {prism: true}, sfk: 0.85, txt: "Support: red shots hit 25% harder, blue ones slow, green ones heal you 2 HP a hit."},
			// ---- realm events (a UT at T7, one or two Legendaries)
			cubic_grimoire: {n: "Cubic Grimoire", k: "ability", s: "spell", r: "ut", pw: 2.15, st: {wis: 4}, ab: "fireball", abx: {cubes: 4}, txt: "Fireball bursts into 4 small cubes.", lore: "Every page is a perfect square."},
			cubic_staff: {n: "Cubic Staff", k: "weapon", s: "staff", r: "lg", st: {att: 6, wis: 4}, d: [80, 106], sh: 3, rt: 1, split: {n: 4, spd: 4, life: 0.5, mul: 0.35}, txt: "Zoner: shots split into 4 cubes at the end of their range."},
			molten_flask: {n: "Molten Flask", k: "ability", s: "flask", r: "ut", pw: 2.15, st: {att: 4}, ab: "acidflask", abx: {dur: 2}, txt: "Volatile Flask's pool burns 2s longer.", lore: "Handle with the other hand."},
			titanbreaker: {n: "Titanbreaker", k: "weapon", s: "sword", r: "lg", st: {att: 8}, d: [170, 220], sh: 2, rt: 1, rg: 0.6, pc: true, x: {armor: 15}, sfk: 1.15, txt: "Brawler: short-range blades that pierce and ignore 15 enemy defense."},
			wyrmscale: {n: "Wyrmscale Hide", k: "armor", s: "leather", r: "ut", df: 23, st: {spd: 5, vit: 3}, txt: "Cold to the touch, hard to cut."},
			frostfang: {n: "Frostfang", k: "weapon", s: "dagger", r: "lg", st: {dex: 6}, d: [112, 153], sh: 2, rt: 1, passive: "frost", txt: "Control: Frostbite, a 12% chance to slow for 2s."},
			hollow_guard_aegis: {n: "Aegis of the Hollow Guard", k: "ability", s: "shield", r: "ut", pw: 2.15, st: {hp: 40, def: 4}, ab: "shieldwall", abx: {dur: 1}, txt: "Shield Wall lasts 1s longer.", lore: "Its bearer died standing."},
			hollow_crown: {n: "The Hollow Crown", k: "ability", s: "helm", r: "lg", pw: 2.7, st: {att: 8, def: 6, hp: 40}, ab: "charge", abx: {reach: 0.3}, txt: "Berserker Charge reaches 30% further."},
			behemoth_hide: {n: "Behemoth Hide", k: "armor", s: "heavy", r: "ut", df: 33, st: {hp: 60}, txt: "Thick enough to stop a charge."},
			gorehorn_bow: {n: "Gorehorn Longbow", k: "weapon", s: "bow", r: "lg", st: {dex: 6, hp: 40}, d: [74, 100], sh: 4, rt: 1, pc: true, txt: "Line clearer: four piercing arrows."},
			phantom_hourglass: {n: "Phantom Hourglass", k: "ability", s: "hourglass", r: "ut", pw: 2.15, st: {wis: 4}, ab: "rewind", abx: {invis: 1}, txt: "Rewind also turns you invisible for 1s.", lore: "The sand falls both ways."},
			regents_scepter: {n: "Regent's Scepter", k: "weapon", s: "wand", r: "lg", st: {wis: 6, spd: 4}, d: [58, 78], sh: 2, rt: 1, rg: 1.5, walls: true, sfk: 0.9, txt: "Long-range poke: shots fly half as far again and pass through walls."},
			riddle_tome: {n: "Tome of Riddles", k: "ability", s: "tome", r: "ut", pw: 2.15, st: {wis: 5, mp: 40}, ab: "sanctuary", abx: {cure: true}, txt: "Sanctuary also cures bad effects."},
			sandglass_ring: {n: "Sandglass Ring", k: "ring", s: "dex", r: "lg", st: {dex: 8, spd: 6, luc: 4}, txt: "The speed ring."},
			hermit_shell: {n: "Hermit's Shell", k: "ring", s: "def", r: "ut", st: {hp: 80, def: 6}, txt: "The tank ring."},
			tidecaller: {n: "Tidecaller Quiver", k: "ability", s: "quiver", r: "lg", pw: 2.7, st: {dex: 6, att: 4}, ab: "arrowstorm", abx: {slow: 2}, txt: "Arrow Storm slows everything it hits for longer."},
			kelpweave_robe: {n: "Kelpweave Robe", k: "armor", s: "robe", r: "ut", df: 15, st: {mp: 70, wis: 4, vit: 3}, txt: "Damp, but the tide keeps it whole.", lore: "Woven on the drowned looms."},
			sunken_trident: {n: "Trident of the Deep", k: "weapon", s: "staff", r: "lg", st: {att: 6, wis: 4}, d: [86, 114], sh: 3, rt: 1, arc: 14, mo: "wave", txt: "Sustained: three weaving shots, the widest coverage."},
			drowned_plate: {n: "Drowned Plate", k: "armor", s: "heavy", r: "lg", df: 40, st: {hp: 80, vit: 6, prt: 4}, txt: "Tank heavy armor."},
			cinderfeather_staff: {n: "Cinderfeather Staff", k: "weapon", s: "staff", r: "ut", st: {att: 4}, d: [85, 115], sh: 2, rt: 1, split: {n: 5, spd: 3.5, life: 0.35, mul: 0.25}, col: 0xff8a30, txt: "Shots burst into embers at the end of their range.", lore: "A phoenix feather that never stopped burning."},
			phoenix_quill: {n: "Phoenix Quill", k: "weapon", s: "bow", r: "lg", st: {dex: 6, att: 4}, d: [102, 135], sh: 3, rt: 1, x: {trail: true}, txt: "Area denial: arrows leave a short trail of fire."},
			rebirth_tome: {n: "Tome of Rebirth", k: "ability", s: "tome", r: "lg", pw: 2.85, st: {wis: 8, mp: 60}, ab: "sanctuary", abx: {heal: 0.25}, txt: "Healer: Sanctuary heals 25% more."},
			hexstring_bow: {n: "Hexstring Bow", k: "weapon", s: "bow", r: "ut", st: {dex: 4}, d: [66, 90], sh: 3, rt: 1, eff: "slow", txt: "Arrows slow what they hit.", lore: "Strung with a curse."},
			hexbound_wand: {n: "Hexbound Wand", k: "weapon", s: "wand", r: "lg", st: {wis: 6, att: 4}, d: [140, 180], sh: 1, rt: 1, x: {hex: true}, txt: "Boss killer: hexed targets take 10% more damage from your whole party for 3s."},
			witchs_brew: {n: "Witch's Brew", k: "ability", s: "trap", r: "lg", pw: 2.85, st: {wis: 6, dex: 4}, ab: "snare", abx: {cloud: true}, txt: "Snare leaves a poison cloud."},
			bonechime_wand: {n: "Bonechime Wand", k: "weapon", s: "wand", r: "ut", st: {wis: 3}, d: [48, 62], sh: 2, rt: 1, pc: true, txt: "Shots pierce.", lore: "It rings like a bell made of ribs."},
			shrineflame: {n: "Shrineflame Staff", k: "weapon", s: "staff", r: "lg", st: {att: 8}, d: [160, 210], sh: 2, rt: 0.8, sp: 0.6, boom: {r: 1.4, mul: 0.6}, txt: "Burst: slow shots that explode on impact."},
			skullforge: {n: "Skullforge", k: "ability", s: "skull", r: "lg", pw: 2.85, st: {wis: 8, att: 5}, ab: "harvest", abx: {wide: 0.3}, txt: "Burst: Soul Harvest's blast is 30% wider."},
			obsidian_shiv: {n: "Obsidian Shiv", k: "weapon", s: "dagger", r: "ut", st: {dex: 4}, d: [80, 110], sh: 2, rt: 1, rg: 0.6, txt: "Short range, heavy hits.", lore: "Knapped from the Colossus's heel."},
			basalt_hide: {n: "Basalt Hide", k: "armor", s: "leather", r: "lg", df: 34, st: {hp: 80, vit: 6}, txt: "Defense: the toughest leather.", lore: "Leather that thinks it's stone."},
			colossus_core: {n: "Colossus Core", k: "ring", s: "hp", r: "lg", st: {hp: 160, def: 8, vit: 4}, txt: "The tank ring."},
			coralblade: {n: "Coralblade", k: "weapon", s: "sword", r: "ut", st: {dex: 3}, d: [68, 92], sh: 3, rt: 1, arc: 18, mo: "wave", txt: "Blades weave.", lore: "Grown, not forged."},
			krakens_grasp: {n: "Kraken's Grasp", k: "weapon", s: "dagger", r: "lg", st: {dex: 6}, d: [122, 163], sh: 2, rt: 1, mo: "return", txt: "Up close: shots fly out and come back, hitting both ways."},
			abyssal_mail: {n: "Abyssal Mail", k: "armor", s: "leather", r: "lg", df: 32, st: {spd: 6, dex: 6, hp: 60}, txt: "Agility leather."},
			// ---- event dungeons (Legendaries; the last boss of a multi-boss dungeon may drop a Star Shard)
			cryptkeeper_blade: {n: "Cryptkeeper's Blade", k: "weapon", s: "sword", r: "lg", st: {att: 4, def: 6}, d: [152, 204], sh: 2, rt: 1, pc: true, mo: "return", txt: "All-rounder: blades pierce, then fly back to you, hitting both ways."},
			wardens_lantern: {n: "The Warden's Lantern", k: "ability", s: "tome", r: "lg", pw: 2.85, st: {wis: 8, hp: 60}, ab: "sanctuary", abx: {vuln: 0.2}, txt: "Damage support: monsters inside your Sanctuary take 20% more damage."},
			cinderweave_robe: {n: "Cinderweave Robe", k: "armor", s: "robe", r: "lg", df: 20, st: {mp: 70, att: 8, mgt: 4}, txt: "Offense robe for damage casters.", lore: "Spun from the Pyrelord's banked fires."},
			magma_plate: {n: "Magma Plate", k: "armor", s: "heavy", r: "lg", df: 42, st: {hp: 60, att: 8}, txt: "Offense heavy armor."},
			stormcall_bow: {n: "Stormcall Bow", k: "weapon", s: "bow", r: "lg", st: {dex: 6}, d: [56, 72], sh: 5, rt: 1, rg: 1.4, sp: 1.4, sfk: 0.9, txt: "Sniper volley: five fast arrows, long range, softer each."},
			stormcaller_grimoire: {n: "Stormcaller's Grimoire", k: "ability", s: "spell", r: "lg", pw: 2.85, st: {wis: 8, att: 4}, ab: "lightning", abx: {chain: 1}, txt: "Lightning Strike jumps to one more nearby monster.", lore: "The pages crackle when turned."},
			sorcerers_seal: {n: "Sorcerer's Seal", k: "ring", s: "mp", r: "lg", st: {mp: 100, wis: 8, att: 4}, txt: "The caster ring.", lore: "Pressed into the wax of forbidden letters."},
			mirror_cloak: {n: "Cloak of Mirrors", k: "ability", s: "cloak", r: "lg", pw: 2.85, st: {dex: 8, spd: 4}, ab: "shadowstep", abx: {decoy: 2}, txt: "Shadowstep leaves a mirror image that draws enemy fire for 2s."},
			sunking_aegis: {n: "Aegis of the Sun King", k: "ability", s: "shield", r: "lg", pw: 2.95, st: {hp: 60, def: 8}, ab: "shieldwall", abx: {regen: 0.03}, txt: "While Shield Wall stands, you heal 3% of your HP a second.", lore: "Solhar's shield, still warm from noon."},
			lunar_robe: {n: "Lunar Robe", k: "armor", s: "robe", r: "lg", df: 22, st: {mp: 100, wis: 8, vit: 4}, txt: "The best caster robe."},
			star_prince_hourglass: {n: "Hourglass of the Star Prince", k: "ability", s: "hourglass", r: "lg", pw: 2.95, st: {wis: 8, dex: 6}, ab: "timestop", abx: {dur: 1}, txt: "Time Stop lasts 1s longer.", lore: "Astrel's toy. He never let the sand run out."},
			frozen_choir_lyre: {n: "Lyre of the Frozen Choir", k: "ability", s: "lyre", r: "lg", pw: 2.95, st: {wis: 8, mp: 60}, ab: "lullaby", abx: {slowAfter: 2}, txt: "Monsters slept by Lullaby stay slowed for 2s after they wake.", lore: "Its strings are icicles that never melt."},
			flamewarden_signet: {n: "Flamewarden's Signet", k: "ring", s: "mgt", r: "lg", st: {att: 8, mgt: 12, dex: 4}, txt: "The raw damage ring.", lore: "Ignivar's seal of office."},
			shardglass_alembic: {n: "Shardglass Alembic", k: "ability", s: "flask", r: "lg", pw: 2.95, st: {att: 6, dex: 6}, ab: "philbomb", abx: {shards: true}, txt: "Philosopher's Bomb scatters glass shards outwards.", lore: "Blown from the Seraph's broken wings."}
		};

		/** Which boss drops which of them (replacing what the bosses carried before). */
		public static const DROPS:Object = {
			cove_boss: ["saltbeard_cutlass", "swashbuckler_tunic", "pirates_treasure"],
			moth_boss: ["lantern_wand", "dustveil_robe", "mothwing_cloak"],
			serpent_boss: ["fang_of_ssythra", "venomspit_staff", "venom_quiver"],
			spider_boss: ["widowmaker", "chitin_mail", "carapace_band"],
			lich_boss: ["soulreaper", "deathshroud", "bonebind_snare", "phylactery"],
			lich_risen: ["soulreaper", "deathshroud", "bonebind_snare", "phylactery"],
			demon_boss: ["imps_fang", "demonhide_plate", "infernal_helm", "hellfire_blade"],
			sprite_boss: ["spritestring_bow", "faesilk_tunic", "pixiesong_lyre", "prismatic_wand"],
			ev_cube: ["cubic_grimoire", "cubic_staff"],
			ev_titan: ["molten_flask", "titanbreaker"],
			ev_wyrm: ["wyrmscale", "frostfang"],
			ev_king: ["hollow_guard_aegis", "hollow_crown"],
			ev_behemoth: ["behemoth_hide", "gorehorn_bow"],
			ev_regent: ["phantom_hourglass", "regents_scepter"],
			ev_sphinx: ["riddle_tome", "sandglass_ring"],
			ev_hermit: ["hermit_shell", "tidecaller"],
			ev_lord: ["kelpweave_robe", "sunken_trident", "drowned_plate"],
			ev_phoenix: ["cinderfeather_staff", "phoenix_quill", "rebirth_tome"],
			ev_witch: ["hexstring_bow", "hexbound_wand", "witchs_brew"],
			ev_shrine: ["bonechime_wand", "shrineflame", "skullforge"],
			ev_colossus: ["obsidian_shiv", "basalt_hide", "colossus_core"],
			ev_kraken: ["coralblade", "krakens_grasp", "abyssal_mail"],
			warden: ["cryptkeeper_blade", "wardens_lantern"],
			pyrelord: ["cinderweave_robe", "magma_plate"],
			seraph: ["stormcall_bow", "stormcaller_grimoire"],
			sorcerer: ["sorcerers_seal", "mirror_cloak"],
			sun_king: ["sunking_aegis"],
			moon_queen: ["lunar_robe"],
			star_prince: ["star_prince_hourglass"],
			frost_warden: ["frozen_choir_lyre"],
			flame_warden: ["flamewarden_signet"],
			shattered_seraph: ["shardglass_alembic"]
		};
		/** Per item, each rolled on its own: a UT 1 in 50, a Legendary 1 in 100 (UTs before any luck). */
		public static const CHANCE:Object = {ut: 0.02, lg: 0.01};

		/** Puts the plan's drops on its bosses (Bosses.init, once every boss exists). */
		public static function assign():void {
			for (var bid:String in DROPS) {
				var d:Object = Data.ENEMIES[bid];
				if (!d) continue;
				d.uniques = DROPS[bid];
				d.planned = true;
				// the last boss of each multi-boss dungeon can give a Star Shard (the Tomb: whichever king falls last)
				if (bid == "shattered_seraph" || bid == "sun_king" || bid == "moon_queen" || bid == "star_prince") d.shard = true;
				for each (var u:String in DROPS[bid]) { source[u] = d.name; bossOf[u] = bid; }
			}
			// (every planned item is also in ALL, so the catalogue, the wiki and old saves find it)
			for (var id:String in FIXED) {
				var f:Object = FIXED[id];
				ALL[id] = [f.n, f.k, f.s, f.st, null, f.lore || (ALL[id] ? ALL[id][5] : "")];
			}
		}

		/** Items no longer made (old saves still read them). */
		public static const RETIRED:Array = ["parrot_charm", "scaled_hide", "powder_keg", "silkspinner", "brimstone_ring", "pixie_ring", "fae_quiver",
			"cube_core", "ember_mantle", "kings_ransom", "phantom_veil", "obsidian_maul", "gravebind_ring", "cinder_ring", "emberheart_staff",
			"illusionist_wand", "flamewarden_blade", "tempest_quiver", "thunderhide", "arcane_vestments", "sunfire_staff", "solar_crown",
			"moonlight_bow", "starfall_dagger", "astral_cloak", "glacial_plate", "icicle_ring", "ember_ring", "shardwing_bow", "seraph_halo"];

		/** Boss name and id for each unique (filled in by Bosses.init). */
		public static var source:Object = {};
		public static var bossOf:Object = {};

		/**
		 * A unique's rarity follows where it comes from: early dungeons give
		 * Runed, later dungeons and realm events Eldritch, the toughest events,
		 * endgame dungeons and realm finales Starforged, and raid masters Primordial.
		 */
		public static function rarityOf(id:String):String {
			if (FIXED[id]) return FIXED[id].r;
			var bid:String = bossOf[id];
			var d:Object = bid ? Data.ENEMIES[bid] : null;
			if (!d) return "ut";
			if (d.raid) {
				for each (var rd:Object in Bosses.RAIDS) {
					var last:Array = rd.stages[rd.stages.length - 1];
					if (last.indexOf(bid) >= 0) return "ar";
				}
				return "lg";
			}
			if (d.final || d.finale) return "lg";
			if (d.dungeon) return d.dtier != undefined && d.dtier <= 2 ? "ut" : "lg";
			// realm events: the biggest ones (worth 1,800 XP and more) give Starforged
			return d.xp >= 1800 ? "lg" : "ut";
		}

		/** How much stronger each rarity makes a unique (stats, then weapon damage). */
		private static const STAT_MUL:Object = {ut: 1, fb: 1.25, lg: 1.5, ar: 1.8};
		private static const DMG_MUL:Object = {ut: 1.12, fb: 1.2, lg: 1.3, ar: 1.42};
		/** Unique weapons: at least this much above a plain weapon of their rarity (Data.weaponDps). */
		private static const FLOOR:Number = 1.08;
		/** What a passive adds on its own (so a Rampage weapon's floor counts its rings). */
		private static const PASSIVE_DPS:Object = {rampage: 1.3, critical: 1.08};
		/** Bumped when unique weapons' numbers change: older copies are remade (Data.upgradeWeapon). */
		public static const VERSION:int = 2;
		private static const POWER_ADD:Object = {ut: 0, fb: 0.15, lg: 0.3, ar: 0.45};

		public static function make(id:String):Object {
			if (FIXED[id]) return makeFixed(id);
			var u:Array = ALL[id];
			if (!u) return null;
			var kind:String = u[1], sub:String = u[2];
			var it:Object;
			switch (kind) {
				case "weapon": it = Data.makeWeapon(sub, 7, null, ""); break;
				case "ability": it = Data.makeAbility(sub, 6, null); break;
				case "armor": it = Data.makeArmor(sub, 7, null); break;
				default: it = Data.makeRing(sub, 5, null);
			}
			var rar:String = rarityOf(id);
			it.rarity = rar;
			it.tier = 8;
			it.name = u[0];
			it.uid = id;
			it.lore = u[5];
			var st:Object = u[3];
			for (var k:String in st) it[k] = (it[k] || 0) + st[k];
			// rarer uniques: every stat on it is stronger
			if (rar != "ut") for each (var sk:String in Data.STATS.concat(Data.GEAR_STATS)) {
				if (sk == "spd" && kind == "weapon") continue;
				if (it[sk]) it[sk] = Math.round(it[sk] * STAT_MUL[rar]);
			}
			var x:Object = u[4];
			if (kind == "weapon") {
				// a little above a top-tier weapon, then shaped by its extras
				it.dmin = int(it.dmin * DMG_MUL[rar]);
				it.dmax = int(it.dmax * DMG_MUL[rar]);
				if (x) {
					if (x.shots) it.shots = x.shots;
					if (x.arc != undefined) it.arc = x.arc;
					if (x.parallel != undefined) it.parallel = x.parallel;
					else if (x.shots) it.parallel = false;
					if (x.rate) it.rate = x.rate;
					if (x.spd) it.spd *= x.spd;
					if (x.range) it.life *= x.range;
					if (x.motion) it.motion = x.motion;
					if (x.pierce) it.pierce = true;
					if (x.shape) it.shape = x.shape;
					if (x.col) it.col = x.col;
					if (x.passive) it.passive = x.passive;
					if (x.size) it.size = x.size;
					if (x.mult) { it.dmin = int(it.dmin * x.mult); it.dmax = int(it.dmax * x.mult); }
				}
				// never weaker than a plain weapon of its rarity: at least 8% above one, its own trick on top
				// (one that's already stronger, like the Seventh Star's seeking sparks, keeps its numbers)
				var plain:Number = Data.weaponDps(Data.makeWeapon(sub, 7, rar, "")) * FLOOR / (PASSIVE_DPS[it.passive] || 1);
				var mine:Number = Data.weaponDps(it);
				if (mine > 0 && mine < plain) { it.dmin = int(it.dmin * plain / mine) + 1; it.dmax = int(it.dmax * plain / mine) + 1; }
				it.uv = VERSION;
			} else if (kind == "ability" && x && x.power) {
				it.power = x.power;
			}
			if (kind == "ability") it.power = Math.round((it.power + POWER_ADD[rar]) * 100) / 100;
			return it;
		}

		/** One of the plan's items, exactly as written (no rolls: the same item every time). */
		public static function makeFixed(id:String):Object {
			var f:Object = FIXED[id];
			var it:Object;
			switch (f.k) {
				case "weapon": it = Data.makeWeapon(f.s, 7, null, ""); break;
				case "ability": it = Data.makeAbility(f.s, 6, null, f.ab); break;
				case "armor": it = Data.makeArmor(f.s, 7, null); break;
				default: it = {kind: "ring", sub: f.s, tier: 5};
			}
			// (only the plan's own stats: a tiered base's are cleared first)
			for each (var sk:String in Data.STATS.concat(Data.GEAR_STATS)) if (!(sk == "spd" && f.k == "weapon")) delete it[sk];
			delete it.sig;
			it.rarity = f.r;
			it.tier = 8;
			it.name = f.n;
			it.uid = id;
			it.lore = f.lore || (ALL[id] ? ALL[id][5] : "");
			for (var k:String in f.st) it[k] = f.st[k];
			if (f.k == "armor") it.def = f.df;
			if (f.k == "ability") {
				it.power = f.pw;
				if (f.ab) it.ab = f.ab;
				if (f.abx) it.abx = f.abx;
			}
			if (f.k == "weapon") {
				it.dmin = f.d[0]; it.dmax = f.d[1];
				it.shots = f.sh || 1;
				it.rate = f.rt || 1;
				it.parallel = f.par == true;
				it.arc = f.arc != undefined ? f.arc : it.shots > 1 ? (f.s == "bow" ? 10 : 12) : 0;
				if (f.rg) it.life *= f.rg;
				if (f.sp) it.spd *= f.sp;
				if (f.mo) it.motion = f.mo; else delete it.motion;
				if (f.pc) it.pierce = true; else delete it.pierce;
				if (f.eff) it.effect = f.eff;
				if (f.shape) it.shape = f.shape;
				if (f.col) it.col = f.col;
				if (f.passive) it.passive = f.passive;
				if (f.split) it.split = {n: f.split.n, spd: f.split.spd, life: f.split.life, sh: "star", mul: f.split.mul};
				if (f.boom) it.boom = {r: f.boom.r, mul: f.boom.mul};
				if (f.walls) it.walls = true;
				if (f.x) it.x = f.x;
				delete it.form; delete it.accel;
				it.uv = VERSION;
			}
			return it;
		}

		/**
		 * A random item of the ladder for one of a class's slots (0 weapon, 1 ability, 2 armor, 3 ring), of
		 * this rarity ("sf" gives a Legendary already Starforged), or null if there's none.
		 */
		public static function randomFor(cls:Object, slot:int, rarity:String):Object {
			var want:String = rarity == "sf" ? "lg" : rarity;
			var kind:String = ["weapon", "ability", "armor", "ring"][slot];
			var sub:String = [cls.weapon, cls.abilityType, cls.armor, null][slot];
			var pool:Array = [];
			for (var id:String in FIXED) {
				var f:Object = FIXED[id];
				if (f.r == want && f.k == kind && (sub == null || f.s == sub)) pool.push(id);
			}
			if (!pool.length) return null;
			pool.sort();
			var it:Object = make(pool[int(Math.random() * pool.length)]);
			return rarity == "sf" ? starforge(it) : it;
		}

		// ---- the Starforge: a Legendary and a Star Shard make its Starforged self
		/** Weapon damage a second (every shot landing) a Starforged weapon of each type reaches. */
		public static const SF_DPS:Object = {staff: 345, bow: 405, sword: 405, dagger: 325, wand: 185};
		public static const SF_WEAPON_STATS:int = 12, SF_POWER:Number = 3.05, SF_ABILITY_STATS:int = 16;
		public static const SF_DEF:Object = {robe: 25, leather: 36, heavy: 46};
		public static const SF_ARMOR_STATS:int = 22, SF_RING_STATS:int = 30;
		/** What Starforging unlocks on the Legendary armours and rings (a weapon or ability keeps its special, a little stronger). */
		public static const SF_PASSIVES:Object = {
			drowned_plate: {id: "tidebound", name: "Tidebound", desc: "Standing in water gives +15% damage, and you wade at full speed."},
			magma_plate: {id: "lavawalker", name: "Lavawalker", desc: "Lava and burning ground deal 80% less damage to you and don't slow you."},
			lunar_robe: {id: "moonwell", name: "Moonwell", desc: "Below 25% MP, MP regenerates 3x faster."},
			cinderweave_robe: {id: "kindling", name: "Kindling", desc: "After you cast an ability, your next 3 shots deal +20% damage."},
			abyssal_mail: {id: "riptide", name: "Riptide", desc: "After 5s without being hit, +10% Speed and Dexterity until you're hit."},
			basalt_hide: {id: "hardened", name: "Hardened", desc: "When hit, +10 Defense for 3s (8s cooldown)."},
			sandglass_ring: {id: "shifting", name: "Shifting Sands", desc: "Each kill gives +3% fire rate for 4s, stacking up to 5 times."},
			colossus_core: {id: "bastion", name: "Last Bastion", desc: "Below 30% HP, take 25% less damage for 5s (once every 30s)."},
			flamewarden_signet: {id: "ignite", name: "Ignite", desc: "Crits set the target burning for 2s (20% of the hit again over time)."},
			sorcerers_seal: {id: "overflow", name: "Overflow", desc: "MP regenerated while already full fills your Ward shield instead."}
		};
		/** How a Starforged special grows (Frostbite 12% to 15%, a second longer, a little wider...). */
		public static const SF_BUMP:Number = 1.25;

		/** A stat total as the plan counts it: 1 a point, Health and MP 1 per 10. */
		public static function statTotal(it:Object):Number {
			var t:Number = 0;
			for each (var k:String in Data.STATS) {
				if (k == "def" && it.kind == "armor") continue;
				if (k == "spd" && it.kind == "weapon") continue;
				if (it[k]) t += k == "hp" || k == "mp" ? it[k] / 10 : it[k];
			}
			return t;
		}
		private static function growStats(it:Object, target:Number):void {
			var now:Number = statTotal(it);
			// (never weaker for it: one already past the target keeps what it has)
			if (now <= 0 || now >= target) return;
			var f:Number = target / now;
			for each (var k:String in Data.STATS) {
				if ((k == "def" && it.kind == "armor") || (k == "spd" && it.kind == "weapon")) continue;
				if (it[k]) it[k] = Math.round(it[k] * f);
			}
		}

		/** Whether this item can be Starforged (a Legendary of the plan's). */
		public static function canStarforge(it:Object):Boolean {
			return it && it.rarity == "lg" && it.uid && FIXED[it.uid] && FIXED[it.uid].r == "lg";
		}

		/** The Starforged version of a Legendary: same name, look and special, raised to its slot's target. */
		public static function starforge(src:Object):Object {
			if (!canStarforge(src)) return src;
			var it:Object = makeFixed(src.uid);
			var f:Object = FIXED[src.uid];
			it.rarity = "sf";
			switch (it.kind) {
				case "weapon":
					var dps:Number = (it.dmin + it.dmax) / 2 * it.shots * it.rate;
					var want:Number = (SF_DPS[it.sub] || dps) * (f.sfk || 1);
					it.dmin = Math.round(it.dmin * want / dps);
					it.dmax = Math.round(it.dmax * want / dps);
					growStats(it, SF_WEAPON_STATS);
					break;
				case "ability":
					it.power = SF_POWER;
					growStats(it, SF_ABILITY_STATS);
					if (it.abx) {
						var bx:Object = {};
						for (var k:String in it.abx) bx[k] = typeof it.abx[k] == "number" && k != "skulls" && k != "chain" ? Math.round(it.abx[k] * SF_BUMP * 100) / 100 : it.abx[k];
						it.abx = bx;
					}
					break;
				case "armor":
					it.def = SF_DEF[it.sub] || it.def;
					growStats(it, SF_ARMOR_STATS);
					break;
				default:
					growStats(it, SF_RING_STATS);
			}
			if (SF_PASSIVES[it.uid]) it.sfp = SF_PASSIVES[it.uid].id;
			// (its weapon special a little stronger: Frostbite and the like read this)
			if (it.kind == "weapon") it.sfb = SF_BUMP;
			return it;
		}

		/** Tooltip lines for a unique. */
		public static function describe(it:Object):String {
			var s:String = "";
			if (it.lore) s += "<font color='#c8b080'><i>" + it.lore + "</i></font>\n";
			var f:Object = FIXED[it.uid];
			if (f && f.txt) s += "<font color='#ffd27a'><b>Special:</b> " + f.txt + "</font>\n";
			var src:String = source[it.uid];
			var rar:String = it.rarity || rarityOf(it.uid);
			var sp:Object = SF_PASSIVES[it.uid];
			if (sp && rar == "sf") s += "<font color='#8ae8ff'><b>" + sp.name + ":</b> " + sp.desc + "</font>\n";
			else if (sp && rar == "lg") s += "<font color='#6a9aa8'>Starforged, it gains " + sp.name + ": " + sp.desc + "</font>\n";
			if (rar == "sf") s += "<font color='#8ae8ff'>Starforged from the Legendary" + (src ? " " + src + " drops" : "") + ".</font>\n";
			else if (rar == "lg" && canStarforge(it)) s += "<font color='#8ae8ff'>Bring it and a Star Shard to the Starforge to make it Starforged.</font>\n";
			else if (src) s += "<font color='#ff9a2e'>" + Data.RARITY_NAMES[rar] + ": only " + src + " drops this.</font>\n";
			return s;
		}
	}
}
