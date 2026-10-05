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
			stormbreaker: ["Stormbreaker", "weapon", "sword", {att: 6}, {shots: 3, arc: 18, pierce: true, passive: "rampage", mult: 1.0, col: 0xffff60}, "Splits the sky in three."]
		};

		/** Boss name for each unique (filled in by Bosses.init). */
		public static var source:Object = {};

		public static function make(id:String):Object {
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
			it.rarity = "ut";
			it.tier = 8;
			it.name = u[0];
			it.uid = id;
			it.lore = u[5];
			var st:Object = u[3];
			for (var k:String in st) it[k] = (it[k] || 0) + st[k];
			var x:Object = u[4];
			if (kind == "weapon") {
				// a little above a top-tier weapon, then shaped by its extras
				it.dmin = int(it.dmin * 1.12);
				it.dmax = int(it.dmax * 1.12);
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
			} else if (kind == "ability" && x && x.power) {
				it.power = x.power;
			}
			return it;
		}

		/** Tooltip lines for a unique. */
		public static function describe(it:Object):String {
			var s:String = "";
			if (it.lore) s += "<font color='#c8b080'><i>" + it.lore + "</i></font>\n";
			var src:String = source[it.uid];
			if (src) s += "<font color='#ff9a2e'>Unique: only " + src + " drops this.</font>\n";
			return s;
		}
	}
}
