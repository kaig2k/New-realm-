package realm {
	/**
	 * Game balance: classes, enemies, items and loot tables.
	 * New Realm's systems: 11 maxable stats (the classic 8 +
	 * Fury, Focus, Warding), Luck (better loot) from gear, and the T0-T7 / RN / BD /
	 * EL / SF / PR item rarities.
	 */
	public class Data {
		public static const STATS:Array = ["hp", "mp", "att", "def", "spd", "dex", "vit", "wis", "mgt", "luc", "prt"];
		/** Stats that only come from gear. */
		public static const GEAR_STATS:Array = ["frt"];
		public static const STAT_NAMES:Object = {hp: "Life", mp: "Mana", att: "Attack", def: "Defense", spd: "Speed", dex: "Dexterity", vit: "Vitality",
			wis: "Wisdom", mgt: "Fury", luc: "Focus", prt: "Warding", frt: "Luck"};
		public static const STAT_SHORT:Object = {hp: "HP", mp: "MP", att: "ATT", def: "DEF", spd: "SPD", dex: "DEX", vit: "VIT", wis: "WIS",
			mgt: "FUR", luc: "FOC", prt: "WRD", frt: "LCK"};
		public static const STAT_COLORS:Object = {hp: 0xff70b0, mp: 0x5080ff, att: 0xa040e0, def: 0x303030, spd: 0x40c040, dex: 0xff9020, vit: 0xd02020,
			wis: 0x40e0e0, mgt: 0xff5a2a, luc: 0x3ae07a, prt: 0xe8e8f0, frt: 0xf0c030};

		// base = level 1, l20 = level 20, max = "11/11" caps (tuned from RotMG-style class tables)
		public static const CLASSES:Object = {
			wizard: {
				id: "wizard", name: "Wizard", weapon: "staff", armor: "robe", abilityType: "spell",
				desc: "Long-range burst damage. Twin bolts and an explosive Spell.",
				base: {hp: 80, mp: 100, att: 15, def: 0, spd: 10, dex: 20, vit: 12, wis: 12, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 580, mp: 300, att: 45, def: 0, spd: 30, dex: 50, vit: 22, wis: 32, mgt: 12, luc: 2, prt: 4},
				max: {hp: 630, mp: 385, att: 70, def: 25, spd: 50, dex: 70, vit: 40, wis: 60, mgt: 30, luc: 30, prt: 25},
				ability: {name: "Fireball", cost: 30, desc: "A fireball that explodes where it hits."}
			},
			archer: {
				id: "archer", name: "Archer", weapon: "bow", armor: "leather", abilityType: "quiver",
				desc: "Piercing arrows from long range. Quiver arrows slow their target.",
				base: {hp: 130, mp: 100, att: 12, def: 0, spd: 12, dex: 12, vit: 12, wis: 10, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 630, mp: 200, att: 42, def: 0, spd: 32, dex: 32, vit: 22, wis: 30, mgt: 12, luc: 12, prt: 4},
				max: {hp: 680, mp: 252, att: 75, def: 25, spd: 50, dex: 50, vit: 40, wis: 50, mgt: 80, luc: 40, prt: 25},
				ability: {name: "Arrow Storm", cost: 30, desc: "Arrows rain on an area and slow."}
			},
			knight: {
				id: "knight", name: "Knight", weapon: "sword", armor: "heavy", abilityType: "shield",
				desc: "The tank. Huge HP and Defense; the Shield stuns everything nearby.",
				base: {hp: 210, mp: 100, att: 15, def: 0, spd: 7, dex: 10, vit: 10, wis: 10, mgt: 5, luc: 2, prt: 4},
				l20: {hp: 710, mp: 200, att: 45, def: 0, spd: 27, dex: 30, vit: 40, wis: 30, mgt: 5, luc: 2, prt: 14},
				max: {hp: 950, mp: 252, att: 50, def: 40, spd: 50, dex: 50, vit: 75, wis: 50, mgt: 50, luc: 35, prt: 40},
				ability: {name: "Shield Wall", cost: 30, desc: "Plant your shield: blocks bullets, -60% damage, slower."}
			},
			priest: {
				id: "priest", name: "Priest", weapon: "wand", armor: "robe", abilityType: "tome",
				desc: "Support with real damage. The Tome heals and bursts holy light.",
				base: {hp: 80, mp: 100, att: 15, def: 0, spd: 12, dex: 13, vit: 10, wis: 15, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 580, mp: 300, att: 35, def: 0, spd: 42, dex: 33, vit: 20, wis: 45, mgt: 12, luc: 2, prt: 14},
				max: {hp: 630, mp: 385, att: 65, def: 25, spd: 55, dex: 65, vit: 40, wis: 75, mgt: 50, luc: 70, prt: 60},
				ability: {name: "Sanctuary", cost: 40, desc: "Holy circle: heals you inside, burns enemies."}
			},
			rogue: {
				id: "rogue", name: "Rogue", weapon: "dagger", armor: "leather", abilityType: "cloak",
				desc: "Fast medium-range daggers. The Cloak turns you invisible.",
				base: {hp: 110, mp: 100, att: 10, def: 0, spd: 15, dex: 15, vit: 15, wis: 13, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 610, mp: 200, att: 30, def: 0, spd: 45, dex: 45, vit: 25, wis: 33, mgt: 22, luc: 22, prt: 4},
				max: {hp: 680, mp: 252, att: 55, def: 25, spd: 75, dex: 75, vit: 40, wis: 55, mgt: 60, luc: 75, prt: 25},
				ability: {name: "Shadowstep", cost: 30, desc: "Blink to the cursor, vanish, next hit Backstabs."}
			},
			warrior: {
				id: "warrior", name: "Warrior", weapon: "sword", armor: "heavy", abilityType: "helm",
				desc: "Melee bruiser. The Helm sends you berserk: faster attacks and speed.",
				base: {hp: 180, mp: 100, att: 15, def: 0, spd: 7, dex: 10, vit: 10, wis: 10, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 680, mp: 200, att: 45, def: 0, spd: 27, dex: 30, vit: 40, wis: 30, mgt: 2, luc: 2, prt: 4},
				max: {hp: 730, mp: 385, att: 75, def: 25, spd: 50, dex: 50, vit: 75, wis: 50, mgt: 50, luc: 10, prt: 25},
				ability: {name: "Berserker Charge", cost: 35, desc: "Charge through enemies, then go berserk."}
			},
			necromancer: {
				id: "necromancer", name: "Necromancer", weapon: "staff", armor: "robe", abilityType: "skull",
				desc: "Dark caster. The Skull blasts an area and drains life from it.",
				base: {hp: 100, mp: 100, att: 15, def: 0, spd: 12, dex: 12, vit: 10, wis: 15, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 600, mp: 300, att: 45, def: 0, spd: 32, dex: 42, vit: 20, wis: 40, mgt: 12, luc: 12, prt: 4},
				max: {hp: 650, mp: 385, att: 70, def: 25, spd: 50, dex: 60, vit: 40, wis: 75, mgt: 40, luc: 40, prt: 30},
				ability: {name: "Soul Harvest", cost: 35, desc: "Draining blast + 2 spirit skulls that shoot."}
			},
			huntress: {
				id: "huntress", name: "Huntress", weapon: "bow", armor: "leather", abilityType: "trap",
				desc: "Archer of the wilds. Traps explode into slowing shards.",
				base: {hp: 130, mp: 100, att: 12, def: 0, spd: 12, dex: 12, vit: 12, wis: 10, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 630, mp: 200, att: 42, def: 0, spd: 32, dex: 32, vit: 22, wis: 30, mgt: 12, luc: 12, prt: 4},
				max: {hp: 680, mp: 252, att: 75, def: 25, spd: 50, dex: 50, vit: 40, wis: 50, mgt: 60, luc: 50, prt: 25},
				ability: {name: "Snare", cost: 25, desc: "Trap roots enemies in vines, then bursts."}
			},
			// ---- Eldmere's own classes (open to everyone: see ELDMERE_CLASSES)
			bard: {
				id: "bard", name: "Bard", weapon: "bow", armor: "leather", abilityType: "lyre",
				desc: "The party's heart. Songs that make allies hit harder, lull monsters to sleep or shatter them.",
				base: {hp: 120, mp: 110, att: 12, def: 0, spd: 13, dex: 13, vit: 11, wis: 14, mgt: 2, luc: 6, prt: 4},
				l20: {hp: 610, mp: 280, att: 38, def: 0, spd: 36, dex: 34, vit: 22, wis: 38, mgt: 10, luc: 20, prt: 8},
				max: {hp: 660, mp: 340, att: 65, def: 25, spd: 60, dex: 55, vit: 40, wis: 65, mgt: 50, luc: 75, prt: 35},
				ability: {name: "Ballad of Valor", cost: 40, desc: "You and nearby allies deal +30% damage."}
			},
			alchemist: {
				id: "alchemist", name: "Alchemist", weapon: "dagger", armor: "leather", abilityType: "flask",
				desc: "Brews trouble. Acid pools, healing elixirs and a bomb that levels a room.",
				base: {hp: 115, mp: 105, att: 12, def: 0, spd: 13, dex: 14, vit: 14, wis: 12, mgt: 4, luc: 2, prt: 4},
				l20: {hp: 615, mp: 260, att: 36, def: 0, spd: 38, dex: 42, vit: 32, wis: 32, mgt: 18, luc: 10, prt: 8},
				max: {hp: 680, mp: 320, att: 60, def: 25, spd: 65, dex: 70, vit: 60, wis: 55, mgt: 60, luc: 45, prt: 30},
				ability: {name: "Volatile Flask", cost: 35, desc: "An acid pool that eats away at monsters."}
			},
			chronomancer: {
				id: "chronomancer", name: "Chronomancer", weapon: "wand", armor: "robe", abilityType: "hourglass",
				desc: "Bends time. Rewind a mistake, freeze bullets in the air, speed up your party.",
				base: {hp: 90, mp: 120, att: 14, def: 0, spd: 12, dex: 15, vit: 10, wis: 16, mgt: 2, luc: 4, prt: 4},
				l20: {hp: 590, mp: 320, att: 42, def: 0, spd: 36, dex: 40, vit: 20, wis: 44, mgt: 12, luc: 14, prt: 10},
				max: {hp: 640, mp: 400, att: 70, def: 25, spd: 60, dex: 65, vit: 40, wis: 75, mgt: 40, luc: 50, prt: 40},
				ability: {name: "Rewind", cost: 40, desc: "Snap back 3 seconds: place and health."}
			}
		};
		public static const CLASS_ORDER:Array = ["wizard", "archer", "knight", "priest", "rogue", "warrior", "necromancer", "huntress", "bard", "alchemist", "chronomancer"];

		/**
		 * Classes you earn (RotMG style): {need: best level to reach, classes: how many different classes must reach it, text}.
		 * The rest are open from the start.
		 */
		/** The classes found only in Eldmere (marked on the class screen). Every class is open from the start. */
		public static const ELDMERE_CLASSES:Object = {bard: true, alchemist: true, chronomancer: true};

		/** Per-level growth, derived from the level 1 and level 20 stat tables. */
		public static function grow(cls:Object, s:String):Number {
			return (cls.l20[s] - cls.base[s]) / 19;
		}

		// ---- item tiers -------------------------------------------------
		// Tiered items are T0..T7. Above them one ladder of named items with fixed stats, every step stronger:
		// UT (Untiered), Legendary, Starforged (a Legendary upgraded at the Starforge), Primordial (endgame only),
		// Godly. Bonded (st) and Eldritch (fb) are retired: still read from old saves, never made.
		// The short ids are only save-file keys and never shown to players.
		public static const RARITIES:Array = ["ut", "st", "fb", "lg", "sf", "ar", "gd"];
		/** The ladder, weakest first (what drops and is shown; st and fb are only old saves). */
		public static const LADDER:Array = ["ut", "lg", "sf", "ar", "gd"];
		public static const RARITY_NAMES:Object = {ut: "Untiered", st: "Bonded", fb: "Eldritch", lg: "Legendary", sf: "Starforged", ar: "Primordial", gd: "Godly"};
		public static const RARITY_LABELS:Object = {ut: "UT", st: "BD", fb: "EL", lg: "LG", sf: "SF", ar: "PR", gd: "GD"};
		public static const RARITY_COLORS:Object = {ut: 0xb070ff, st: 0x4ee08a, fb: 0xd070c0, lg: 0xffd23a, sf: 0x8ae8ff, ar: 0xff5533, gd: 0xfff6e0};
		/** Effective tier used for item stats (the ladder's power, in tiers: T7 = 7). */
		private static const RARITY_POWER:Object = {ut: 7, st: 8.5, fb: 9.5, lg: 10, sf: 11.5, ar: 12.5, gd: 14};

		public static const WEAPON_NAMES:Object = {
			staff: ["Twig Staff", "Ember Staff", "Comet Staff", "Serpent Staff", "Starfall Staff", "Ruin Staff", "Nebula Staff", "Staff of the Void"],
			bow: ["Short Bow", "Twin Bow", "Hunter's Bow", "Gilded Bow", "Thornwood Bow", "Fey Bow", "Bloodstring Bow", "Bow of Distant Stars"],
			sword: ["Rusty Sword", "Broad Sword", "Saber", "Long Sword", "Falchion", "Flame Blade", "Crystal Blade", "Sunforged Blade"],
			wand: ["Bone Wand", "Ember Wand", "Grave Wand", "Deep Wand", "Shadow Wand", "Warden's Wand", "Penance Wand", "Wand of Radiance"],
			dagger: ["Rusty Dirk", "Iron Dagger", "Steel Dagger", "Silver Dirk", "Viper Fang", "Agate Dagger", "Ghostblade", "Dagger of Dusk"]
		};
		public static const ARMOR_NAMES:Object = {
			robe: ["Cloth Robe", "Apprentice Robe", "Silk Robe", "Mystic Robe", "Star Robe", "Ether Robe", "Archmage Robe", "Robe of the Void"],
			leather: ["Leather Vest", "Studded Vest", "Hunter's Hide", "Ranger Leather", "Drake Hide", "Wyvern Hide", "Hydra Hide", "Leviathan Hide"],
			heavy: ["Chainmail", "Ring Mail", "Scale Armor", "Plate Mail", "Steel Plate", "Mithril Plate", "Dragonscale Plate", "Titan Plate"]
		};
		public static const ABILITY_NAMES:Object = {
			spell: ["Spark Spell", "Flare Spell", "Blaze Spell", "Comet Spell", "Starburst Spell", "Nova Spell", "Cataclysm Spell"],
			quiver: ["Thorn Quiver", "Hunter's Quiver", "Iron Quiver", "Silver Quiver", "Golden Quiver", "Hawk Quiver", "Phoenix Quiver"],
			shield: ["Wooden Shield", "Buckler", "Kite Shield", "Tower Shield", "Steel Shield", "Mithril Shield", "Dragon Shield"],
			tome: ["Tome of Mending", "Tome of Renewal", "Tome of Grace", "Tome of Light", "Tome of Dawn", "Tome of Saints", "Tome of Miracles"],
			cloak: ["Dusky Cloak", "Shadow Cloak", "Night Cloak", "Cloak of Shades", "Wraith Cloak", "Cloak of Silence", "Cloak of the Void"],
			helm: ["Iron Helm", "Bronze Helm", "Steel Helm", "Horned Helm", "War Helm", "Helm of Rage", "Helm of the Titan"],
			skull: ["Bone Skull", "Spirit Skull", "Grim Skull", "Wraith Skull", "Lich Skull", "Skull of Ruin", "Skull of the Damned"],
			trap: ["Snare Trap", "Spike Trap", "Thorn Trap", "Barbed Trap", "Hunter's Trap", "Trap of Vines", "Trap of the Wild"],
			lyre: ["Reed Lyre", "Oak Lyre", "Silver Lyre", "Siren's Lyre", "Lyre of Echoes", "Starstrung Lyre", "Lyre of the First Song"],
			flask: ["Cracked Flask", "Glass Flask", "Bubbling Flask", "Fuming Flask", "Quicksilver Flask", "Dragonbile Flask", "Flask of the Magnum Opus"],
			hourglass: ["Sand Glass", "Brass Hourglass", "Silver Hourglass", "Moonsand Hourglass", "Hourglass of Ages", "Aeon Hourglass", "Hourglass of the End of Time"]
		};
		/** Nouns used to name special-rarity items. */
		private static const NOUNS:Object = {staff: "Staff", bow: "Longbow", sword: "Greatsword", wand: "Wand", dagger: "Kris",
			spell: "Grimoire", quiver: "Quiver", shield: "Aegis", tome: "Codex", cloak: "Shroud", helm: "Crown", skull: "Skull", trap: "Snare", lyre: "Lyre", flask: "Alembic", hourglass: "Hourglass",
			robe: "Vestments", leather: "Hide", heavy: "Plate", ring: "Signet"};
		private static const UT_PREFIX:Array = ["Runed", "Ember-Runed", "Frostrune", "Bloodrune", "Stormrune", "Graverune", "Tiderune", "Hollowrune"];
		private static const LG_PREFIX:Array = ["Starforged", "Starfall", "Comet-Forged", "Nova", "Sunforged", "Moonforged", "Starlit", "Celestial"];
		private static const AR_SUFFIX:Array = ["of the First Dawn", "of the Old Realm", "of the Unmade", "of the Primal Flame"];
		public static const FB_SOURCE:String = "Eldritch";
		/** Save-file id of the generic set from early versions (shown as "Old Realm"). */
		public static const SET_NAME:String = "Valorous";

		/** Passives on Starforged and Primordial weapons. */
		public static const PASSIVES:Object = {
			lifesteal: {name: "Lifebloom", desc: "Heal 4 HP on every hit."},
			shards: {name: "Shardstorm", desc: "6% on hit: 8 shards burst from the target (60% damage)."},
			frost: {name: "Frostbite", desc: "12% on hit: slow the target for 2s."},
			critical: {name: "Executioner", desc: "+10% critical hit chance."},
			rampage: {name: "Rampage", desc: "Every 12th shot fires a ring of 10 shots."}
		};
		public static const PASSIVE_IDS:Array = ["lifesteal", "shards", "frost", "critical", "rampage"];

		private static function pick(a:Array):* { return a[int(Math.random() * a.length)]; }

		private static function rarityName(sub:String, rarity:String, fallback:String):String {
			var noun:String = NOUNS[sub] || "Relic";
			switch (rarity) {
				case "ut": return pick(UT_PREFIX) + " " + noun;
				case "st": return SET_NAME + " " + noun;
				case "fb": return FB_SOURCE + " " + noun;
				case "lg": return pick(LG_PREFIX) + " " + noun;
				case "ar": return noun + " " + pick(AR_SUFFIX);
			}
			return fallback;
		}

		/** Extra stats, passives and set tags for special rarities. */
		private static function enchant(item:Object, rarity:String):Object {
			if (!rarity) return item;
			item.rarity = rarity;
			item.name = rarityName(item.sub, rarity, item.name);
			var pool:Array = ["att", "dex", "spd", "vit", "wis", "mgt", "luc", "prt"];
			// (Godly pieces roll nothing: Godly.make gives every drop the same stats)
			var n:int = rarity == "ut" ? 1 : rarity == "st" ? 1 : rarity == "fb" ? 2 : rarity == "lg" ? 2 : rarity == "gd" ? 0 : 3;
			var amt:int = rarity == "ut" ? 5 : rarity == "st" ? 6 : rarity == "fb" ? 8 : rarity == "lg" ? 10 : rarity == "gd" ? 18 : 15;
			// weapons keep their bullet speed in "spd", so they roll Dexterity instead of Speed
			if (item.kind == "weapon") pool = ["att", "dex", "vit", "wis", "mgt", "luc", "prt"];
			for (var i:int = 0; i < n; i++) {
				var s:String = pick(pool);
				item[s] = (item[s] || 0) + amt + int(Math.random() * 4);
			}
			if (rarity == "fb") item.frt = 5;
			if (rarity == "ar") item.frt = 8;
			if (rarity == "st") item.set = SET_NAME;
			if ((rarity == "lg" || rarity == "ar") && item.kind == "weapon") item.passive = pick(PASSIVE_IDS);
			if (rarity == "ar") item.hp = (item.hp || 0) + 60;
			return item;
		}

		/** Bonus for wearing all 4 pieces of a set (the generic set from early saves; its saved id is "Valorous"). */
		public static const SET_BONUS:Object = {hp: 80, att: 10, def: 10, dex: 10, frt: 10};

		/** Class sets: Bonded drops are tagged with the class id and give a class-flavoured 4-piece bonus. */
		public static const SETS:Object = {
			wizard: {name: "Archmage's", bonus: {mp: 80, att: 12, wis: 10, luc: 12, frt: 10}},
			archer: {name: "Ranger's", bonus: {hp: 60, att: 10, dex: 12, luc: 10, frt: 10}},
			knight: {name: "Crusader's", bonus: {hp: 120, def: 15, vit: 15, prt: 15, frt: 10}},
			priest: {name: "Saint's", bonus: {hp: 60, mp: 60, wis: 15, vit: 10, frt: 10}},
			rogue: {name: "Nightblade's", bonus: {hp: 60, dex: 12, spd: 12, mgt: 12, frt: 10}},
			warrior: {name: "Warlord's", bonus: {hp: 100, att: 15, vit: 10, mgt: 10, frt: 10}},
			necromancer: {name: "Gravecaller's", bonus: {mp: 80, att: 10, wis: 12, mgt: 12, frt: 10}},
			huntress: {name: "Wildheart's", bonus: {hp: 60, att: 10, dex: 10, spd: 10, luc: 10, frt: 10}},
			bard: {name: "Troubadour's", bonus: {hp: 60, mp: 60, wis: 12, luc: 15, frt: 10}},
			alchemist: {name: "Transmuter's", bonus: {hp: 80, dex: 12, vit: 12, mgt: 12, frt: 10}},
			chronomancer: {name: "Timekeeper's", bonus: {mp: 80, att: 10, dex: 10, wis: 15, frt: 10}}
		};

		public static function setName(id:String):String {
			if (id == SET_NAME) return "Old Realm";
			return SETS[id] ? SETS[id].name : id;
		}

		public static function setBonus(id:String):Object {
			return SETS[id] ? SETS[id].bonus : SET_BONUS;
		}

		public static function setBonusText(id:String):String {
			var b:Object = setBonus(id), parts:Array = [];
			for each (var k:String in STATS) if (b[k]) parts.push("+" + b[k] + " " + STAT_SHORT[k]);
			if (b.frt) parts.push("+" + b.frt + " Luck");
			return parts.join(", ");
		}

		/**
		 * Weapon forms: the same weapon type can drop with a different shot pattern
		 * and trade-offs (more damage for less range, one big shot, faster fire...).
		 */
		public static const FORMS:Object = {
			heavy: {name: "Heavy", desc: "One big, slow-firing shot that hits very hard. Great against armored enemies."},
			long: {name: "Farshot", desc: "Much longer range, a little less damage."},
			brutal: {name: "Brutal", desc: "Short range, a lot more damage."},
			scatter: {name: "Scattershot", desc: "Two extra shots in a wide spread; each one hits softer."},
			swift: {name: "Swift", desc: "Fires much faster; each shot hits softer."},
			siege: {name: "Siege", desc: "Slow, heavy shots that pierce through every enemy in their path."},
			serpent: {name: "Serpent", desc: "Shots weave in a wave, sweeping a wider path."},
			returning: {name: "Returning", desc: "Shots fly out and come back, hitting enemies on the way out and back."}
		};
		public static const FORM_IDS:Array = ["heavy", "long", "brutal", "scatter", "swift", "siege", "serpent", "returning"];

		/** Half of all dropped weapons have a form. */
		public static function rollForm():String {
			// (weapons no longer drop in random forms: every named item is fixed, tiered gear is plain)
			return "";
		}

		private static function applyForm(w:Object, form:String):void {
			if (!form || !FORMS[form]) return;
			var mul:Number = 1;
			switch (form) {
				case "heavy":
					mul = w.shots * 1.15 + 0.35;
					w.shots = 1; w.parallel = false; w.pierce = false;
					w.rate *= 0.6; w.spd *= 0.85; w.size = (w.size || 3) + 2;
					break;
				case "long": w.life *= 1.5; mul = 0.8; break;
				case "brutal": w.life *= 0.6; mul = 1.45; break;
				case "scatter":
					w.shots += 2; w.parallel = false; w.arc = Math.max(w.arc, 12); mul = 0.6;
					break;
				case "swift": w.rate *= 1.45; mul = 0.7; break;
				case "siege":
					// (it pierces and reaches far: so it hits only a little harder, and fires a little slower)
					w.spd *= 0.55; w.life *= 1.7; w.pierce = true; mul = 1.05; w.rate *= 0.85; w.size = (w.size || 3) + 1;
					w.fv = SIEGE_V;
					break;
				case "serpent": w.motion = "wave"; w.life *= 1.15; mul = 1.1; break;
				case "returning": w.motion = "return"; w.pierce = true; w.life *= 1.3; mul = 0.85; break;
			}
			w.dmin = int(w.dmin * mul);
			w.dmax = int(w.dmax * mul);
			w.form = form;
			w.name = FORMS[form].name + " " + w.name;
		}

		/** form: "" = plain, "?" = roll a random form, or a FORMS id. */
		/**
		 * Every tier of every weapon fires its own signature shot: its look (shape, colour, size), its pattern
		 * (shots, spread, side by side) and what it does (weaves, comes back, speeds up, seeks, pierces, passes
		 * walls, poisons, explodes where it hits, shatters into shards). Fields:
		 *   sh shape, col colour, n shots, arc spread (degrees), par side by side, pc pierce, rate, spd, life, sz size,
		 *   mo motion (wave, return, accel, seek), ac acceleration, walls (through walls), fx effect ("venom"),
		 *   split {n, mul (each shard's share of a shot), spd, life, sh}, boom {r, mul}, tx what it does (the tooltip).
		 */
		public static const SIGS:Object = {
			staff: [
				{sh: "bolt", col: 0xc070ff, n: 2, par: true, spd: 13, life: 0.6, tx: "Twin arcane bolts."},
				{sh: "fire", col: 0xff8030, n: 2, par: true, spd: 13, life: 0.62, mo: "accel", ac: 0.9, tx: "Twin embers that gather speed."},
				{sh: "star", col: 0x80c8ff, n: 2, par: true, spd: 12, life: 0.7, sz: 4, tx: "Twin comets, longer reach."},
				{sh: "wisp", col: 0x60e080, n: 2, par: true, spd: 13, life: 0.68, mo: "wave", tx: "Twin serpents that weave as they fly."},
				{sh: "star", col: 0xffe070, n: 3, par: true, spd: 13, life: 0.66, pc: true, tx: "Three falling stars that pierce."},
				{sh: "voidorb", col: 0xb050ff, n: 2, par: true, spd: 12, life: 0.62, sz: 4, split: {n: 4, mul: 0.4, spd: 7, life: 0.35, sh: "dart"}, tx: "Ruin orbs that shatter into four shards."},
				{sh: "orb", col: 0xff70d0, n: 3, par: true, spd: 13, life: 0.7, mo: "wave", pc: true, tx: "Three weaving nebula orbs that pierce."},
				{sh: "rift", col: 0xd060ff, n: 2, par: true, spd: 12, life: 0.7, sz: 5, boom: {r: 1.3, mul: 0.6}, tx: "Rifts of the void that explode where they strike."}
			],
			bow: [
				{sh: "arrow", col: 0xe0c080, n: 1, spd: 15, life: 0.52, pc: true, tx: "A piercing arrow."},
				{sh: "arrow", col: 0xf0d090, n: 2, arc: 6, spd: 15, life: 0.52, pc: true, tx: "Two arrows at once."},
				{sh: "spear", col: 0xd0d8e0, n: 1, spd: 19, life: 0.55, pc: true, sz: 4, tx: "One fast, heavy hunting arrow."},
				{sh: "arrow", col: 0xffd040, n: 3, arc: 8, spd: 15, life: 0.54, pc: true, tx: "Three gilded arrows in a fan."},
				{sh: "spike", col: 0x70d050, n: 2, arc: 7, spd: 15, life: 0.52, pc: true, split: {n: 3, mul: 0.35, spd: 9, life: 0.3, sh: "spike"}, tx: "Thorn arrows that burst into three thorns."},
				{sh: "wisp", col: 0x90ffd0, n: 3, arc: 12, spd: 14, life: 0.62, mo: "seek", pc: true, tx: "Three fey arrows that seek out enemies."},
				{sh: "arrow", col: 0xff3040, n: 3, arc: 7, spd: 12, life: 0.55, mo: "accel", ac: 1.6, pc: true, fx: "venom", tx: "Three blood arrows that speed up and make enemies bleed."},
				{sh: "star", col: 0xfff4c0, n: 5, arc: 6, spd: 16, life: 0.58, pc: true, tx: "A volley of five starlit arrows."}
			],
			sword: [
				{sh: "blade", col: 0xc8d0d8, n: 1, spd: 11, life: 0.34, sz: 4, tx: "A short slash."},
				{sh: "blade", col: 0xe0e8f0, n: 1, spd: 11, life: 0.36, sz: 5, tx: "A broad, wide slash."},
				{sh: "blade", col: 0xd8e8ff, n: 2, arc: 14, spd: 11, life: 0.34, sz: 4, tx: "Two quick slashes in a V."},
				{sh: "spear", col: 0xd0e0ff, n: 1, spd: 12, life: 0.44, sz: 5, pc: true, tx: "A long thrust that pierces."},
				{sh: "crescent", col: 0xfff0d0, n: 1, spd: 11, life: 0.38, sz: 5, pc: true, tx: "A crescent cut that cleaves through every enemy."},
				{sh: "crescent", col: 0xff7020, n: 1, spd: 11, life: 0.38, sz: 5, boom: {r: 1.2, mul: 0.55}, tx: "A flaming cut that explodes where it strikes."},
				{sh: "spike", col: 0x80f0ff, n: 1, spd: 11, life: 0.4, sz: 5, pc: true, split: {n: 5, mul: 0.3, spd: 8, life: 0.3, sh: "spike"}, tx: "A crystal cut that shatters into five shards."},
				{sh: "crescent", col: 0xffd040, n: 3, arc: 16, spd: 12, life: 0.4, sz: 5, pc: true, tx: "Three sunlit crescents that cleave through everything."}
			],
			wand: [
				{sh: "orb", col: 0xe8e0c8, n: 1, spd: 16, life: 0.56, tx: "A bone-white bolt."},
				{sh: "fire", col: 0xffa040, n: 1, spd: 16, life: 0.56, mo: "accel", ac: 0.8, tx: "An ember that gathers speed."},
				{sh: "soul", col: 0x90ffb0, n: 1, spd: 15, life: 0.6, mo: "wave", tx: "A weaving grave-light."},
				{sh: "orb", col: 0x40c0ff, n: 1, spd: 15, life: 0.7, mo: "return", pc: true, tx: "A tide orb that flies out and comes back."},
				{sh: "voidorb", col: 0x8050d0, n: 1, spd: 14, life: 0.66, mo: "seek", tx: "A shadow that seeks out enemies."},
				{sh: "star", col: 0xfff0a0, n: 2, par: true, spd: 16, life: 0.58, pc: true, tx: "Twin warding stars that pierce."},
				{sh: "orb", col: 0xffe8a0, n: 1, spd: 15, life: 0.6, sz: 4, boom: {r: 1.2, mul: 0.6}, tx: "A holy orb that bursts where it strikes."},
				{sh: "star", col: 0xffffff, n: 1, spd: 15, life: 0.66, sz: 4, mo: "seek", split: {n: 6, mul: 0.35, spd: 6, life: 0.35, sh: "star"}, tx: "A radiant seeker that bursts into a ring of light."}
			],
			dagger: [
				{sh: "knife", col: 0xb0a8a0, n: 1, spd: 15, life: 0.36, tx: "A thrown dirk."},
				{sh: "knife", col: 0xc8d0d8, n: 1, spd: 16, life: 0.36, rate: 1.25, tx: "Faster throws."},
				{sh: "knife", col: 0xe0e8f0, n: 2, arc: 8, spd: 15, life: 0.36, tx: "Two knives at once."},
				{sh: "knife", col: 0xe8f0ff, n: 1, spd: 15, life: 0.5, mo: "return", pc: true, tx: "A silver dirk that flies out and comes back."},
				{sh: "dart", col: 0x60e040, n: 1, spd: 15, life: 0.42, mo: "wave", fx: "venom", tx: "A weaving viper fang that poisons."},
				{sh: "knife", col: 0xff9070, n: 3, arc: 10, spd: 15, life: 0.38, tx: "A fan of three agate knives."},
				{sh: "soul", col: 0xa0e8ff, n: 2, arc: 8, spd: 15, life: 0.42, pc: true, walls: true, tx: "Ghost knives that pierce and pass through walls."},
				{sh: "voidorb", col: 0x9040c0, n: 2, arc: 10, spd: 15, life: 0.48, mo: "seek", split: {n: 3, mul: 0.35, spd: 8, life: 0.3, sh: "dart"}, tx: "Dusk blades that seek out enemies and split in three."}
			]
		};
		/** What a weapon type's tier-0 and tier-7 deal in a second of steady fire (each tier between is a fixed step up). */
		public static const TIER_DPS:Object = {staff: [36, 197], bow: [24, 234], sword: [43, 235], wand: [29, 110], dagger: [30, 188]};

		/** How much more a weapon deals than its shots alone: its shards and explosions (honest play, then the most it could). */
		public static function weaponExtra(w:Object, most:Boolean = false):Number {
			var f:Number = 1;
			if (w && w.split) f += (w.split.n || 0) * (w.split.mul || 0) * (most ? 1 : 0.35);
			// (an explosion also flings embers: Abilities.explode)
			if (w && w.boom) f += (w.boom.mul || 0) * (most ? 3 : 1.5);
			// (a Godly weapon's Divine Wrath: at most every wrath shot on one monster; honestly about a third)
			if (w && w.gid) f += Godly.wrathExtra(w) * (most ? 1 : 0.3);
			return f;
		}

		/** The biggest single hit a weapon's shots can land, in its top roll (a Godly weapon's Divine Wrath, an explosion). */
		public static function weaponHitMul(w:Object):Number {
			var m:Number = 1;
			if (w && w.boom) m = Math.max(m, w.boom.mul || 0);
			if (w && w.gid) m = Math.max(m, Godly.wrathHit(w));
			return m;
		}

		/** A tiered weapon's signature shot laid onto it (its damage set so the tier deals its share of the curve). */
		private static function signature(w:Object, sub:String, tier:int):void {
			var sig:Object = SIGS[sub][Math.max(0, Math.min(7, tier))];
			var ends:Array = TIER_DPS[sub];
			w.shape = sig.sh; w.col = sig.col; w.shots = sig.n; w.arc = sig.arc || 0; w.parallel = !!sig.par; w.pierce = !!sig.pc;
			w.rate = sig.rate || 1; w.spd = sig.spd; w.life = sig.life;
			if (sig.sz) w.size = sig.sz;
			if (sig.mo) w.motion = sig.mo;
			if (sig.ac) w.accel = sig.ac;
			if (sig.walls) w.walls = true;
			if (sig.fx) w.effect = sig.fx;
			if (sig.split) w.split = {n: sig.split.n, mul: sig.split.mul, spd: sig.split.spd, life: sig.split.life, sh: sig.split.sh};
			if (sig.boom) w.boom = {r: sig.boom.r, mul: sig.boom.mul};
			var dps:Number = ends[0] * Math.pow(ends[1] / ends[0], tier / 7);
			var avg:Number = dps / (w.shots * w.rate * weaponExtra(w));
			w.dmin = int(avg * 0.82);
			w.dmax = int(avg * 1.18);
			w.sig = tier;
		}

		/** The trail a weapon's shots leave: from its signature (or its rarity: always sparkling). */
		public static function trailOf(w:Object):String {
			if (!w) return "";
			if (w.rarity) return "spark";
			if (w.sig === undefined) return "glow";
			if (w.effect == "venom") return "drip";
			if (w.boom) return "ember";
			switch (w.shape) {
				case "fire": return "ember";
				case "voidorb": case "rift": return "smoke";
				case "star": return "spark";
				case "wisp": case "soul": return "wisp";
				case "spike": return "frost";
			}
			return int(w.sig) >= 4 ? "spark" : "glow";
		}

		/** Whether an item is a plain tiered weapon (they all fire their tier's signature shot). */
		public static function isTieredWeapon(it:Object):Boolean {
			return it && it.kind == "weapon" && !it.rarity && !it.uid && !it.curse && SIGS[it.sub] && it.tier >= 0 && it.tier <= 7;
		}

		/** An older tiered weapon brought up to its tier's signature (same weapon, same form; true if it changed). */
		/** Siege weapons from before its rebalance (+35% damage, full fire rate) are brought in line once. */
		public static const SIEGE_V:int = 2;
		/** A weapon's damage a second on one target (both ends of its roll, every shot, its extras). */
		public static function weaponDps(w:Object):Number {
			if (!w) return 0;
			return (w.dmin + w.dmax) / 2 * Math.max(1, w.shots || 1) * (w.rate || 1) * weaponExtra(w) * (w.motion == "return" ? 1.5 : 1);
		}
		private static const WEAPON_KEYS:Array = ["shape", "col", "shots", "arc", "parallel", "pierce", "rate", "spd", "life", "size", "motion", "accel", "walls", "effect", "split", "boom", "dmin", "dmax", "sig", "passive", "uv", "fv"];

		public static function upgradeWeapon(it:Object):Boolean {
			// (and Godly pieces from before every drop was the same: remade as they drop now)
			if (it && it.gid) return Godly.upgrade(it);
			// a unique weapon from before its numbers changed: remade as it drops now
			if (it && it.uid && it.kind == "weapon" && it.uv !== Uniques.VERSION) {
				// (a Starforged one is remade Starforged)
				var uq:Object = it.rarity == "sf" && Uniques.FIXED[it.uid] ? Uniques.starforge(Uniques.make(it.uid)) : Uniques.make(it.uid);
				if (!uq) return false;
				for each (var uk:String in WEAPON_KEYS) { if (uq[uk] === undefined) delete it[uk]; else it[uk] = uq[uk]; }
				return true;
			}
			// a Siege weapon from before its rebalance
			if (it && it.kind == "weapon" && it.form == "siege" && it.fv !== SIEGE_V && (!isTieredWeapon(it) || it.sig === it.tier)) {
				it.dmin = int(it.dmin * 1.05 / 1.35); it.dmax = int(it.dmax * 1.05 / 1.35);
				it.rate = Math.round((it.rate || 1) * 0.85 * 1000) / 1000;
				it.fv = SIEGE_V;
				return true;
			}
			if (!isTieredWeapon(it) || it.sig === it.tier) return false;
			var fresh:Object = makeWeapon(it.sub, it.tier, null, it.form || "");
			for each (var k:String in ["shape", "col", "shots", "arc", "parallel", "pierce", "rate", "spd", "life", "size", "motion", "accel", "walls", "effect", "split", "boom", "dmin", "dmax", "sig"]) {
				if (fresh[k] === undefined) delete it[k];
				else it[k] = fresh[k];
			}
			return true;
		}

		public static function makeWeapon(sub:String, tier:int, rarity:String = null, form:String = ""):Object {
			var t:Number = rarity ? RARITY_POWER[rarity] : tier;
			var w:Object = {kind: "weapon", sub: sub, tier: rarity ? 8 : tier, name: WEAPON_NAMES[sub][Math.min(tier, 7)], shots: 1, arc: 0, parallel: false, pierce: false, rate: 1};
			switch (sub) {
				case "staff":
					w.dmin = int(14 + 7 * t); w.dmax = int(22 + 9 * t); w.shots = 2; w.parallel = true;
					w.spd = 13; w.life = 0.6; w.col = 0xd060ff; w.shape = "bolt";
					break;
				case "bow":
					w.dmin = int(12 + 6 * t); w.dmax = int(22 + 8 * t); w.shots = t < 3 ? 1 : (t < 6 ? 2 : 3); w.arc = 9;
					w.spd = 15; w.life = 0.52; w.pierce = true; w.col = 0xffe080; w.shape = "arrow";
					break;
				case "sword":
					w.dmin = int(34 + 11 * t); w.dmax = int(52 + 15 * t);
					w.spd = 11; w.life = 0.34; w.col = 0xd0e8ff; w.shape = "blade";
					break;
				case "dagger":
					w.dmin = int(20 + 8 * t); w.dmax = int(32 + 11 * t); w.rate = 1.15;
					w.spd = 15; w.life = 0.36; w.col = 0xe8e8f0; w.shape = "knife";
					break;
				default:
					w.dmin = int(22 + 8 * t); w.dmax = int(36 + 10 * t);
					w.spd = 16; w.life = 0.56; w.col = 0xfff0a0; w.shape = "orb";
			}
			if (rarity) {
				w.col = RARITY_COLORS[rarity];
				if (sub == "staff") { w.shots = 3; }
				else if (sub == "bow") { w.shots = rarity == "ar" ? 5 : 4; w.arc = 10; }
				else if (sub == "sword") { w.shots = 2; w.arc = 12; w.pierce = true; }
				else if (sub == "dagger") { w.shots = 2; w.arc = 6; }
				else { w.pierce = true; w.rate = 1.2; }
			}
			if (sub == "sword") w.size = 4;
			// (a plain tiered weapon fires its tier's signature shot instead)
			if (!rarity && SIGS[sub]) signature(w, sub, tier);
			w = enchant(w, rarity);
			applyForm(w, form == "?" ? rollForm() : form);
			return w;
		}

		public static function makeArmor(sub:String, tier:int, rarity:String = null):Object {
			var t:Number = rarity ? RARITY_POWER[rarity] : tier;
			var bonus:int = sub == "heavy" ? 3 + 4 * t : sub == "leather" ? 2 + 3 * t : 1 + 2 * t;
			var a:Object = {kind: "armor", sub: sub, tier: rarity ? 8 : tier, name: ARMOR_NAMES[sub][Math.min(tier, 7)], def: bonus};
			if (sub == "robe") a.mp = int(10 + 8 * t);
			if (sub == "leather") a.dex = int(t / 2);
			if (sub == "heavy") a.prt = int(t / 2);
			return enchant(a, rarity);
		}

		/**
		 * Every class has three abilities; an ability item holds one of them ("ab",
		 * left out for the class's first). Stronger abilities cost more MP and take
		 * longer to come back (cd, seconds). school names the item: "Comet Spell of Storms".
		 */
		public static const ABILITIES:Object = {
			fireball: {type: "spell", name: "Fireball", cost: 30, cd: 3, col: 0},
			lightning: {type: "spell", name: "Lightning Strike", cost: 40, cd: 5, school: "Storms", col: 0x3a5ad0},
			frostnova: {type: "spell", name: "Frost Nova", cost: 45, cd: 9, school: "Frost", col: 0x3aa8d0},
			arrowstorm: {type: "quiver", name: "Arrow Storm", cost: 30, cd: 4, col: 0},
			pierce: {type: "quiver", name: "Piercing Shot", cost: 35, cd: 4, school: "Piercing", col: 0x8a8aa0},
			volley: {type: "quiver", name: "Volley Leap", cost: 30, cd: 7, school: "Flight", col: 0x4a9a5a},
			shieldwall: {type: "shield", name: "Shield Wall", cost: 30, cd: 9, col: 0},
			bash: {type: "shield", name: "Shield Bash", cost: 30, cd: 5, school: "Bashing", col: 0x9a6a3a},
			banner: {type: "shield", name: "Rallying Banner", cost: 45, cd: 16, school: "Rallying", col: 0xb03030},
			sanctuary: {type: "tome", name: "Sanctuary", cost: 40, cd: 10, col: 0},
			smite: {type: "tome", name: "Holy Smite", cost: 35, cd: 5, school: "Smiting", col: 0xd0a020},
			ward: {type: "tome", name: "Divine Ward", cost: 50, cd: 15, school: "Warding", col: 0x60a0e0},
			shadowstep: {type: "cloak", name: "Shadowstep", cost: 30, cd: 6, col: 0},
			knives: {type: "cloak", name: "Fan of Knives", cost: 30, cd: 4, school: "Knives", col: 0x3a7a3a},
			smoke: {type: "cloak", name: "Smoke Bomb", cost: 40, cd: 13, school: "Smoke", col: 0x6a6a6a},
			charge: {type: "helm", name: "Berserker Charge", cost: 35, cd: 7, col: 0},
			whirlwind: {type: "helm", name: "Whirlwind", cost: 35, cd: 6, school: "the Whirlwind", col: 0x7a8aa0},
			warcry: {type: "helm", name: "War Cry", cost: 45, cd: 15, school: "War", col: 0xc04020},
			harvest: {type: "skull", name: "Soul Harvest", cost: 35, cd: 6, col: 0},
			prison: {type: "skull", name: "Bone Prison", cost: 35, cd: 7, school: "Bones", col: 0xc0b090},
			raise: {type: "skull", name: "Raise Dead", cost: 50, cd: 16, school: "the Risen", col: 0x5a9a4a},
			snare: {type: "trap", name: "Snare", cost: 25, cd: 4, col: 0},
			explosive: {type: "trap", name: "Explosive Trap", cost: 35, cd: 5, school: "Fire", col: 0xd05020},
			wolf: {type: "trap", name: "Spirit Wolf", cost: 45, cd: 16, school: "the Wolf", col: 0x7ab0e0},
			valor: {type: "lyre", name: "Ballad of Valor", cost: 40, cd: 8, col: 0},
			lullaby: {type: "lyre", name: "Lullaby", cost: 45, cd: 7, school: "Slumber", col: 0x8a7ad0},
			requiem: {type: "lyre", name: "Requiem", cost: 45, cd: 5, school: "Echoes", col: 0xc04a6a},
			acidflask: {type: "flask", name: "Volatile Flask", cost: 35, cd: 4, col: 0},
			elixir: {type: "flask", name: "Elixir of Renewal", cost: 50, cd: 12, school: "Renewal", col: 0xd04a8a},
			philbomb: {type: "flask", name: "Philosopher's Bomb", cost: 55, cd: 7, school: "Ruin", col: 0xe0a020},
			rewind: {type: "hourglass", name: "Rewind", cost: 40, cd: 8, col: 0},
			timestop: {type: "hourglass", name: "Time Stop", cost: 55, cd: 12, school: "Stasis", col: 0x7ab8e0},
			hastefield: {type: "hourglass", name: "Haste Field", cost: 45, cd: 14, school: "Acceleration", col: 0xe0c040}
		};
		/** Each ability type's three abilities, the first being the original. */
		public static const ABILITY_SETS:Object = {
			spell: ["fireball", "lightning", "frostnova"], quiver: ["arrowstorm", "pierce", "volley"],
			shield: ["shieldwall", "bash", "banner"], tome: ["sanctuary", "smite", "ward"],
			cloak: ["shadowstep", "knives", "smoke"], helm: ["charge", "whirlwind", "warcry"],
			skull: ["harvest", "prison", "raise"], trap: ["snare", "explosive", "wolf"],
			lyre: ["valor", "lullaby", "requiem"], flask: ["acidflask", "elixir", "philbomb"], hourglass: ["rewind", "timestop", "hastefield"]
		};

		/** Which of its type's abilities an ability item holds. */
		public static function abilityId(item:Object):String {
			if (!item) return null;
			var ab:Object = item.ab ? ABILITIES[item.ab] : null;
			if (ab && ab.type == item.sub) return item.ab;
			var set:Array = ABILITY_SETS[item.sub];
			return set ? set[0] : null;
		}

		/** A random one of a type's three abilities (for drops). */
		public static function randomAbility(sub:String):String {
			var set:Array = ABILITY_SETS[sub];
			return set ? set[int(Math.random() * set.length)] : null;
		}

		public static function makeAbility(sub:String, tier:int, rarity:String = null, ab:String = null):Object {
			var t:Number = rarity ? RARITY_POWER[rarity] : tier;
			var a:Object = {kind: "ability", sub: sub, tier: rarity ? 8 : tier, name: ABILITY_NAMES[sub][Math.min(tier, 6)], power: 1 + t * 0.18};
			a = enchant(a, rarity);
			var set:Array = ABILITY_SETS[sub];
			if (ab && set && ab != set[0] && ABILITIES[ab] && ABILITIES[ab].type == sub) {
				a.ab = ab;
				a.name += " of " + ABILITIES[ab].school;
			}
			return a;
		}

		public static const RING_PREFIX:Array = ["Minor", "", "Greater", "Superior", "Paramount", "Exalted"];

		public static function makeRing(stat:String, tier:int, rarity:String = null):Object {
			var t:int = rarity ? 6 : tier;
			var r:Object = {kind: "ring", sub: stat, tier: rarity ? 8 : tier};
			var pre:String = RING_PREFIX[Math.min(t, 5)];
			r.name = "Ring of " + (pre ? pre + " " : "") + STAT_NAMES[stat];
			r[stat] = (stat == "hp" || stat == "mp") ? 20 + t * 20 : 2 + t * 2;
			if (rarity) {
				r = enchant(r, rarity);
				r.sub = stat;
				r.name = rarityName("ring", rarity, r.name);
			}
			return r;
		}

		public static function makePotion(kind:String, stat:String = null):Object {
			if (kind == "hp") return {kind: "hp", tier: 0, name: "Health Potion", color: 0xff3030};
			if (kind == "mp") return {kind: "mp", tier: 0, name: "Magic Potion", color: 0x3060ff};
			return {kind: "stat", sub: stat, tier: 0, name: "Potion of " + STAT_NAMES[stat], color: STAT_COLORS[stat]};
		}

		// ---- the item catalogue: every item that can be named (admins' /give and the Admin Menu's search)
		private static var catalog:Array = null;
		/**
		 * [{name, k, a, b}]: k says how to make it (Data.makeCatalogItem): "u" a unique (a: its id),
		 * "g" a Godly piece (a: class, b: slot), "p" a potion (a: hp, mp or a stat), "m" a material
		 * (a: sor or stone), "n" a rune (a: stat), "k" a raid key / "d" a dungeon key (a: index),
		 * "t" class gear (a: slot, b: tier), "r" class gear of a rarity (a: slot, b: rarity),
		 * "c" cursed class gear (a: slot, b: curse or "").
		 */
		public static function itemCatalog():Array {
			if (catalog) return catalog;
			var out:Array = [];
			var id:String, i:int, s:int;
			for (id in Uniques.ALL) out.push({name: Uniques.ALL[id][0], k: "u", a: id});
			for (id in Godly.SETS) for (s = 0; s < 4; s++) out.push({name: Godly.SETS[id].items[s], k: "g", a: id, b: s});
			out.push({name: "Health Potion", k: "p", a: "hp"}, {name: "Magic Potion", k: "p", a: "mp"});
			for each (var st:String in STATS) {
				out.push({name: "Potion of " + STAT_NAMES[st], k: "p", a: st});
				out.push({name: STAT_NAMES[st] + " Rune", k: "n", a: st});
			}
			out.push({name: "Star Shard", k: "m", a: "sor"}, {name: "Evolution Stone", k: "m", a: "stone"});
			for (i = 0; i < Bosses.RAIDS.length; i++) out.push({name: Bosses.RAIDS[i].name + " Key", k: "k", a: i});
			for (i = 0; i < DUNGEONS.length; i++) out.push({name: DUNGEONS[i].name + " Key", k: "d", a: i});
			var slots:Array = ["Weapon", "Ability", "Armor", "Ring"], tops:Array = [7, 6, 7, 5];
			for (s = 0; s < 4; s++) {
				for (i = 0; i <= tops[s]; i++) out.push({name: "T" + i + " " + slots[s], k: "t", a: s, b: i});
				out.push({name: RARITY_NAMES.gd + " " + slots[s], k: "r", a: s, b: "gd"});
				out.push({name: "Cursed " + slots[s], k: "c", a: s, b: ""});
				for each (var cu:String in CURSE_IDS) out.push({name: CURSES[cu].name + " " + slots[s], k: "c", a: s, b: cu});
			}
			return catalog = out;
		}

		private static function catKey(s:String):String { return String(s).toLowerCase().replace(/[^a-z0-9]/g, ""); }

		/** Catalogue entries matching what was typed: an exact name first, else every name containing it (at most max). */
		public static function findCatalog(query:String, max:int = 8):Array {
			var q:String = catKey(query);
			if (!q) return [];
			var all:Array = itemCatalog(), out:Array = [];
			for each (var e:Object in all) if (catKey(e.name) == q) return [e];
			for each (e in all) if (catKey(e.name).indexOf(q) >= 0) { out.push(e); if (out.length >= max) break; }
			return out;
		}

		/** Makes a catalogue entry's item (class gear for cls). */
		public static function makeCatalogItem(e:Object, cls:Object):Object {
			switch (e.k) {
				case "u": return Uniques.make(e.a);
				case "g": return Godly.make(e.a, e.b);
				case "p": return e.a == "hp" || e.a == "mp" ? makePotion(e.a) : makePotion("stat", e.a);
				case "m": return e.a == "sor" ? makeSor() : makeStone();
				case "n": return makeRune(e.a);
				case "k": return makeKey(e.a);
				case "d": return makeDungeonKey(e.a);
				case "t": return makeForSlot(cls, e.a, e.b, null);
				case "r": return e.b == "gd" ? Godly.make(cls.id, e.a) : makeForSlot(cls, e.a, 7, e.b);
				case "c": return makeCursed(cls, e.a, e.b || null);
			}
			return null;
		}

		/** A raid key: use it in the Nexus to open that raid's portal. */
		public static function makeKey(raid:int):Object {
			var rd:Object = Bosses.RAIDS[raid];
			return {kind: "key", sub: rd.id, tier: 0, name: rd.name + " Key", color: rd.color};
		}

		/** The Marketplace (online, the server sells these and checks the gold). */
		public static const SHOP:Array = [
			{id: "hp", name: "Health Potion", price: 50},
			{id: "mp", name: "Magic Potion", price: 50},
			{id: "stat", name: "Random Stat Potion", price: 1200},
			{id: "ut", name: "Mystery T7 item", price: 2500},
			{id: "backpack", name: "Backpack (+8 slots)", price: 3000}
		];

		/** A dungeon key (Key Merchant): opens a portal to that dungeon. */
		public static function makeDungeonKey(idx:int):Object {
			var d:Object = DUNGEONS[idx];
			return {kind: "key", sub: "dg_" + d.id, tier: 0, name: d.name + " Key", color: d.color};
		}

		/** Which dungeon a key opens (-1 if it isn't a dungeon key). */
		public static function keyDungeon(item:Object):int {
			if (!item || item.kind != "key" || String(item.sub).indexOf("dg_") != 0) return -1;
			return dungeonIndex(String(item.sub).substr(3));
		}

		/** A dungeon's name after "to"/"into": "the Sunken Crypt", but "The Ossuary" stays as it is. */
		public static function theName(name:String):String { return name.indexOf("The ") == 0 ? name : "the " + name; }

		/** Key Merchant price: harder dungeons cost more. */
		public static function keyPrice(idx:int):int {
			var d:Object = DUNGEONS[idx];
			// (a lair only opens from its realm boss's portal: no key for it)
			if (d.by) return -1;
			if (d.hard) return 5000 + int((d.hard - 1.5) * 30000 + 0.5);
			return [300, 600, 1000, 1400, 1800][Math.min(4, d.tier)];
		}

		/** Which raid a key opens (-1 if none). */
		public static function keyRaid(item:Object):int {
			if (!item || item.kind != "key") return -1;
			for (var i:int = 0; i < Bosses.RAIDS.length; i++) if (Bosses.RAIDS[i].id == item.sub) return i;
			return -1;
		}

		/** Bosses rarely drop a raid key: the Dark Elder and finales most often, realm events least. */
		private static function rollKey(def:Object, items:Array, boost:Number):void {
			var c:Number = def.final || def.finale ? 0.08 : def.raid ? 0.04 : def.dungeon && !def.guardian ? (def.dtier >= 5 ? 0.06 : 0.025) : def.ai == "boss" ? 0.02 : 0;
			if (c > 0 && Math.random() < c * boost) items.push(makeKey(int(Math.random() * Bosses.RAIDS.length)));
		}

		public static function makeSor():Object {
			return {kind: "material", sub: "sor", tier: 0, name: "Star Shard"};
		}

		/** Evolution Stone: bosses drop them; pets need them to evolve (the Pet Yard). */
		public static function makeStone():Object {
			return {kind: "stone", sub: "evo", tier: 0, name: "Evolution Stone"};
		}

		/** A rune: used at the Starforge, its stat is sure to be among a stat reroll's bonuses. */
		public static function makeRune(stat:String):Object {
			return {kind: "rune", sub: stat, tier: 0, name: STAT_NAMES[stat] + " Rune"};
		}

		/**
		 * Cursed gear: top-tier gear with a curse, two big boons and a price (a stat
		 * below zero). Only bosses drop it. The Anvil and stat rerolls can't touch it.
		 */
		public static const CURSES:Object = {
			bloodbound: {name: "Bloodbound", boon: {att: 16, mgt: 14}, bane: {def: -10}, desc: "hits like a storm, guards like paper"},
			hexed: {name: "Hexed", boon: {wis: 16, mp: 60}, bane: {hp: -50}, desc: "a well of magic that drinks your life"},
			feral: {name: "Feral", boon: {spd: 14, dex: 14}, bane: {vit: -10}, desc: "fast and wild, slow to mend"},
			gilded: {name: "Gilded", boon: {luc: 18, frt: 12}, bane: {att: -8}, desc: "fortune smiles, the blade dulls"},
			reckless: {name: "Reckless", boon: {att: 12, dex: 14}, bane: {prt: -12}, desc: "all offence, no warding"},
			brittle: {name: "Brittle", boon: {def: 16, vit: 12}, bane: {spd: -10}, desc: "a fortress that barely moves"}
		};
		public static const CURSE_IDS:Array = ["bloodbound", "hexed", "feral", "gilded", "reckless", "brittle"];
		public static const CURSE_COLOR:uint = 0x7ad03a;

		/** A cursed piece of gear for one of cls's four slots (curse: a CURSES id, or one at random). */
		public static function makeCursed(cls:Object, slot:int = -1, curse:String = null):Object {
			if (slot < 0) slot = int(Math.random() * 4);
			if (!curse || !CURSES[curse]) curse = pick(CURSE_IDS);
			var it:Object = makeForSlot(cls, slot, slot == 1 ? 6 : slot == 3 ? 5 : 7, null);
			var c:Object = CURSES[curse];
			var k:String;
			for (k in c.boon) {
				// (a weapon's "spd" is its bullets: its Speed boon becomes Dexterity)
				var key:String = it.kind == "weapon" && k == "spd" ? "dex" : k;
				it[key] = (it[key] || 0) + c.boon[k] + int(Math.random() * 4);
			}
			for (k in c.bane) {
				if (it.kind == "weapon" && k == "spd") continue;
				it[k] = (it[k] || 0) + c.bane[k];
			}
			it.curse = curse;
			it.name = c.name + " " + it.name;
			return it;
		}

		/** Evolution Stones and runes from bosses: [stone chance, rune chance] for this boss (none for other monsters). */
		public static function bossExtras(def:Object):Array {
			if (!def || def.ai != "boss" || def.prop) return [0, 0];
			if (def.raid || def.final || def.finale) return [0.3, 0.18];
			if (def.dungeon && def.dtier >= 5) return [0.2, 0.12];
			if (def.dungeon) return [0.12, 0.07];
			return [0.1, 0.06];
		}

		/** Gear for one of a class's 4 slots. */
		public static function makeForSlot(cls:Object, slot:int, tier:int, rarity:String):Object {
			// above the tiers every item is a named one: a Godly piece, or a random one of the ladder's for this slot
			if (rarity == "gd") return Godly.make(cls.id, slot);
			if (rarity) {
				var named:Object = Uniques.randomFor(cls, slot, rarity == "st" || rarity == "fb" ? "lg" : rarity);
				if (named) return named;
				tier = 7;
			}
			switch (slot) {
				case 0: return makeWeapon(cls.weapon, tier, null, "");
				case 1: return makeAbility(cls.abilityType, tier, null, randomAbility(cls.abilityType));
				case 2: return makeArmor(cls.armor, tier, null);
			}
			return makeRing(randomStat(), Math.min(5, tier), null);
		}

		/** Re-tag a generic set item as a piece of the class's own set. */
		private static function classSet(item:Object, cls:Object):Object {
			if (item.rarity == "st" && SETS[cls.id]) {
				item.set = cls.id;
				item.name = SETS[cls.id].name + " " + (NOUNS[item.sub] || "Relic");
			}
			return item;
		}

		// ---- Starforge rerolls ------------------------------------------
		public static const REROLL_FORM_GOLD:int = 400;
		public static const REROLL_STATS_AETHER:int = 60;

		/** Weapons (but not uniques or Godly items) can get a new prefix (form). */
		public static function canRerollForm(item:Object):Boolean {
			return false; // (rerolls are gone: every named item is fixed)

			return item && item.kind == "weapon" && !item.uid && !item.gid && !item.curse && FORM_IDS.length > 1;
		}

		/** Special-rarity gear (but not uniques or Godly items) can roll its bonus stats again. */
		public static function canRerollStats(item:Object):Boolean {
			return false; // (rerolls are gone: every named item is fixed)

			return item && isGear(item) && item.rarity && item.rarity != "gd" && !item.uid && !item.gid;
		}

		private static const ROLLED:Array = ["hp", "mp", "att", "def", "spd", "dex", "vit", "wis", "mgt", "luc", "prt", "frt"];

		/** The same weapon with a different prefix: everything else it rolled stays. */
		public static function rerollForm(item:Object):Object {
			var forms:Array = FORM_IDS.filter(function(f:*, i:int, a:Array):Boolean { return f != item.form; });
			var form:String = forms[int(Math.random() * forms.length)];
			var w:Object = makeWeapon(item.sub, item.rarity ? 7 : item.tier, item.rarity, form);
			for each (var k:String in ROLLED) {
				if (k == "spd") continue;
				if (item[k]) w[k] = item[k]; else delete w[k];
			}
			if (item.passive) w.passive = item.passive; else delete w.passive;
			if (item.set) w.set = item.set; else delete w.set;
			if (item.col) w.col = item.col;
			var base:String = item.name;
			if (item.form && FORMS[item.form] && base.indexOf(FORMS[item.form].name + " ") == 0) base = base.substr(FORMS[item.form].name.length + 1);
			w.name = FORMS[form].name + " " + base;
			return w;
		}

		/** The same item with its bonus stats (and a weapon's passive) rolled again. */
		public static function rerollStats(item:Object):Object {
			var n:Object;
			switch (item.kind) {
				case "weapon": n = makeWeapon(item.sub, 7, item.rarity, item.form || ""); break;
				case "ability": n = makeAbility(item.sub, 6, item.rarity, item.ab); break;
				case "armor": n = makeArmor(item.sub, 7, item.rarity); break;
				default: n = makeRing(item.sub, 5, item.rarity);
			}
			n.name = item.name;
			if (item.set) n.set = item.set; else delete n.set;
			if (item.col && item.kind == "weapon") n.col = item.col;
			return n;
		}

		/**
		 * A stat reroll with a rune: rolled until the rune's stat is among the bonuses
		 * (a weapon's Speed is its bullets, so weapons can't take a Speed rune).
		 */
		public static function canUseRune(item:Object, stat:String):Boolean {
			return false; // (rerolls are gone: every named item is fixed)

			return canRerollStats(item) && ROLLED.indexOf(stat) >= 0 && !(item.kind == "weapon" && stat == "spd");
		}
		public static function rerollStatsWith(item:Object, stat:String):Object {
			var n:Object;
			for (var i:int = 0; i < 200; i++) { n = rerollStats(item); if (n[stat] > 0) return n; }
			// (never rolled it: one of the bonuses becomes it)
			for each (var k:String in ROLLED) {
				if (k == stat || !n[k] || (n.kind == "weapon" && k == "spd")) continue;
				var v:Number = n[k];
				if ((k == "hp" || k == "mp") != (stat == "hp" || stat == "mp")) v = (stat == "hp" || stat == "mp") ? v * 5 : Math.max(1, Math.round(v / 5));
				delete n[k];
				n[stat] = v;
				break;
			}
			return n;
		}

		// ---- Fortune's Anvil (a gamble at the Starforge) -------------------
		/** The rarities the Anvil climbs (Starforged and better can't go on it). */
		public static const ANVIL_RARITIES:Array = ["ut", "st", "fb"];
		/** Odds: up, down; the rest of the time the item shatters. */
		public static const ANVIL_UP:Number = 0.45, ANVIL_DOWN:Number = 0.4;
		private static const ANVIL_MAX_TIER:Object = {weapon: 7, ability: 6, armor: 7, ring: 5};

		/** Why this item can't go on the Anvil, or null. */
		public static function anvilBlock(item:Object):String {
			return "Fortune's Anvil has gone cold: every named item is fixed now.";

			if (!item || !isGear(item)) return "Only gear goes on the Anvil.";
			if (item.uid || item.gid) return "Unique and Godly items are too precious for the Anvil.";
			if (item.set) return "Set pieces can't go on the Anvil.";
			if (item.curse) return "The curse won't let the Anvil touch it.";
			if (item.rarity && ANVIL_RARITIES.indexOf(item.rarity) < 0) return "Starforged and better items can't go on the Anvil.";
			if (item.rarity == "fb") return "Eldritch is as high as the Anvil goes: the Starforge takes it further.";
			if (item.locked) return "That item is locked (right-click it to unlock it).";
			if (!item.rarity && int(item.tier) <= 0 && item.kind != "ring") return "Starter gear can't go on the Anvil.";
			return null;
		}

		/** Gold it costs to strike an item. */
		public static function anvilCost(item:Object):int {
			if (item.rarity) return {ut: 3000, st: 5000, fb: 9000}[item.rarity];
			return 200 + int(item.tier) * int(item.tier) * 60;
		}

		/** The item one step up (or down) the Anvil's ladder: tiers, then Runed, Bonded, Eldritch. null: it shatters (going down from the bottom). */
		public static function anvilStep(item:Object, up:Boolean):Object {
			var top:int = ANVIL_MAX_TIER[item.kind];
			var ri:int = item.rarity ? ANVIL_RARITIES.indexOf(item.rarity) : -1;
			var tier:int = int(item.tier), rar:String = null;
			if (ri >= 0) {
				// a rarity: the next one up, or down (Runed falls back to the best plain tier)
				if (up) rar = ANVIL_RARITIES[ri + 1];
				else if (ri > 0) rar = ANVIL_RARITIES[ri - 1];
				else tier = top;
			} else if (up) {
				if (tier >= top) rar = "ut"; else tier++;
			} else {
				if (tier <= 0) return null;
				tier--;
			}
			var n:Object;
			switch (item.kind) {
				case "weapon": n = makeWeapon(item.sub, rar ? 7 : tier, rar, item.form || ""); break;
				case "ability": n = makeAbility(item.sub, rar ? 6 : tier, rar, item.ab); break;
				case "armor": n = makeArmor(item.sub, rar ? 7 : tier, rar); break;
				default: n = makeRing(item.sub, rar ? 5 : tier, rar);
			}
			return n;
		}

		/** The Starforge's price besides the item and a Star Shard. */
		public static const STARFORGE_AETHER:int = 100;
		/** A Legendary's Starforged self (Uniques.starforge); anything else stays as it is. */
		public static function forgeLegendary(item:Object, cls:Object):Object {
			return Uniques.starforge(item);
		}

		public static function isGear(item:Object):Boolean {
			return item && (item.kind == "weapon" || item.kind == "armor" || item.kind == "ability" || item.kind == "ring");
		}

		/** "T3", "RN", "SF"... or "" for consumables. */
		public static function tierLabel(item:Object):String {
			if (!item) return "";
			if (item.rarity) return RARITY_LABELS[item.rarity] || String(item.rarity).toUpperCase();
			if (!isGear(item)) return "";
			return "T" + item.tier;
		}

		public static function tierColor(item:Object):uint {
			if (item && item.rarity) return RARITY_COLORS[item.rarity];
			if (item && item.curse) return CURSE_COLOR;
			return 0xffffff;
		}

		/** Gold value when selling at the marketplace. */
		public static function sellValue(item:Object):int {
			if (!item) return 0;
			if (item.rarity) return {ut: 400, st: 600, fb: 1500, lg: 3000, ar: 8000, gd: 25000}[item.rarity];
			if (item.curse) return 1500;
			switch (item.kind) {
				case "stat": return 250;
				case "material": return 300;
				case "stone": return 400;
				case "rune": return 300;
				case "key": return 2000;
				case "hp": case "mp": return 20;
			}
			return 10 + item.tier * item.tier * 12;
		}

		/** Level used for the numbers in ability tooltips (the game keeps it up to date). */
		public static var viewerLevel:int = 1;

		/** What an ability does, with its numbers at your level. */
		public static function abilityText(item:Object):String {
			var lv:int = viewerLevel, pw:Number = item.power, sq:Number = Math.sqrt(pw);
			var id:String = abilityId(item);
			var ab:Object = ABILITIES[id];
			if (!ab) return "";
			var n:Function = function(base:Number, per:Number):int { return int((base + lv * per) * pw); };
			var t:String;
			switch (id) {
				case "fireball": t = "Hurls a fireball at the cursor (up to 9 tiles). It explodes on impact for " + n(130, 16) + " damage in " + (2.6 * sq).toFixed(1) + " tiles and scatters burning embers."; break;
				case "lightning": t = "After a flash of warning, a bolt drops from the sky at the cursor for " + n(160, 18) + " damage, then jumps to up to 3 more monsters nearby, losing a third each jump."; break;
				case "frostnova": t = "A burst of ice around you (3.5 tiles): " + n(90, 10) + " damage, freezes monsters for " + (1.2 * sq).toFixed(1) + "s and chills them, and shatters every enemy bullet close to you."; break;
				case "arrowstorm": t = "6 arrows rain down around the cursor over a second. Each hits a small area for " + n(40, 5) + " damage and slows."; break;
				case "pierce": t = "One huge arrow that flies 14 tiles, going through every monster in its path for " + n(110, 12) + " damage, ignoring their defense."; break;
				case "volley": t = "Leap back 3.5 tiles, untouchable in the air, firing a fan of 7 arrows forward for " + n(35, 4) + " each."; break;
				case "shieldwall": t = "Plants your shield in front of you for " + (4 * sq).toFixed(1) + "s. Bullets from the front stop on it (it shields your party too). Behind it you take 60% less damage but move slower. The plant bashes and stuns enemies in front."; break;
				case "bash": t = "Charge 3 tiles behind your shield: everything you hit takes " + n(50, 6) + " damage, is knocked back and stunned for " + (1.5 * sq).toFixed(1) + "s. You can't be hurt during the charge, and take half damage for 1.5s after."; break;
				case "banner": t = "Plants a war banner for " + (6 * sq).toFixed(1) + "s. You and your allies within 4 tiles of it get +" + int(10 * pw) + " Defense and heal " + n(4, 0.5) + " HP every half second."; break;
				case "sanctuary": t = "Heals you " + n(34, 3.4) + " HP and consecrates a 3-tile circle for " + (5 * sq).toFixed(1) + "s. Standing in it heals " + n(8.5, 1) + " HP every half second; monsters inside burn for " + n(20, 2.5) + ". Grows with your Wisdom; heals can crit. Works in the Nexus too."; break;
				case "smite": t = "A pillar of light strikes the cursor: " + n(120, 14) + " damage in 1.8 tiles, and you and allies in it are healed " + n(26, 2.6) + " HP. Grows with your Wisdom; the heal can crit."; break;
				case "ward": t = "Heals you and allies within 5 tiles " + n(51, 5.1) + " HP (grows with your Wisdom, and can crit), clears bad effects, and wraps everyone in a ward that soaks up the next " + n(40, 5) + " damage for 6s."; break;
				case "shadowstep": t = "Vanish in smoke and reappear at the cursor (up to 6 tiles, not through walls). You stay invisible for " + (2 * sq).toFixed(1) + "s and your next hit is a Backstab: a guaranteed crit with +50% damage."; break;
				case "knives": t = "12 knives fly out all around you for " + n(30, 4) + " each and poison what they hit: " + n(16, 2.5) + " damage every half second for 4s that ignores Defense."; break;
				case "smoke": t = "Drops a smoke cloud (3 tiles) for " + (5 * sq).toFixed(1) + "s. While you are inside you are invisible; monsters inside are slowed."; break;
				case "charge": t = "Rush about 6 tiles toward the cursor, taking a third less damage for a second, hitting everything you pass for " + n(60, 8) + ". Then go berserk for " + (4 * sq).toFixed(1) + "s: +50% fire rate, +25% speed."; break;
				case "whirlwind": t = "Spin for 2s, hitting everything within 3.2 tiles for " + n(45, 5.5) + " five times a second. You move a little slower while spinning."; break;
				case "warcry": t = "A roar that stuns monsters within 4.5 tiles for 1.5s (bosses briefly) and leaves them taking 25% more damage for 5s. You go berserk for 2s."; break;
				case "harvest": t = "Blasts a 3-tile area at the cursor for " + n(70, 8) + " damage, healing 20 HP + 15 per enemy hit. Two spirit skulls circle you for " + (5 * sq).toFixed(1) + "s, shooting the nearest monster for " + n(18, 2.5) + ". All of it grows with your Wisdom."; break;
				case "prison": t = "Bone spikes burst up in a ring at the cursor: monsters inside (2.5 tiles) are held in place for " + (2.5 * sq).toFixed(1) + "s (bosses for a second, then not again for 6s) and take " + n(16, 2) + " every half second for 3s."; break;
				case "raise": t = "Three skeletons claw out of the ground and fight for you for " + (8 * sq).toFixed(1) + "s, throwing bones at monsters for " + n(20, 3) + " that slow them and pass through. They throw faster the more Dexterity you have."; break;
				case "snare": t = "Throws a trap at the cursor. When a monster comes close, vines root everything nearby (bosses briefly), then it bursts into slowing shards for " + n(60, 7) + " damage."; break;
				case "explosive": t = "Throws a trap at the cursor that blows up when a monster comes close: " + n(150, 16) + " damage in 3 tiles. No roots, just fire."; break;
				case "valor": t = "A rousing ballad: you and every ally within 6 tiles deal +30% damage for " + (5 * sq).toFixed(1) + "s."; break;
				case "lullaby": t = "A soft song at the cursor puts monsters within 3 tiles to sleep for " + (2.5 * sq).toFixed(1) + "s (bosses only nod off briefly)."; break;
				case "requiem": t = "A wave of sound rolls out 5 tiles around you: " + n(95, 11) + " damage to everything it reaches, and they're slowed."; break;
				case "acidflask": t = "Throws a flask at the cursor that bursts into an acid pool (2 tiles, up to 3.2 on better flasks) for " + (4 * sq).toFixed(1) + "s. Monsters in it take " + n(28, 4) + " every half second, ignoring Defense."; break;
				case "elixir": t = "Drink and share: heals you and allies within 5 tiles " + n(50, 5) + " HP at once, clears bad effects, and regenerates health quickly for 4s."; break;
				case "philbomb": t = "Lobs a bomb at the cursor. After a 1.5 second fuse it levels everything within 3.2 tiles for " + n(260, 28) + " damage."; break;
				case "rewind": t = "Snap back to where you were 3 seconds ago (up to 10 tiles), and get back the health you had then, up to " + n(80, 9) + " HP."; break;
				case "timestop": t = "Stops time around you (4 tiles): enemy bullets freeze in the air for " + (2.5 * sq).toFixed(1) + "s and monsters are held still for " + (1.2 * sq).toFixed(1) + "s (bosses briefly)."; break;
				case "hastefield": t = "A field of quickened time (4 tiles) for " + (5 * sq).toFixed(1) + "s: you and allies in it shoot 40% faster and move 35% faster."; break;
				case "wolf": t = "A spirit wolf hunts the nearest monsters for " + (12 * sq).toFixed(1) + "s, biting for " + n(35, 4) + " and slowing them."; break;
				default: return "";
			}
			return "<font color='#e8e0a0'><b>" + ab.name + "</b>: " + t + "</font>\n<font color='#9a9aaa'>Costs " + ab.cost + " MP. Cooldown " + ab.cd + "s. Press SPACE to use.</font>";
		}

		/** Tooltip body text (HTML). */
		public static function describe(item:Object):String {
			if (!item) return "";
			var s:String = "";
			if (item.rarity) s += "<font color='" + Ui.hex(RARITY_COLORS[item.rarity]) + "'>" + RARITY_NAMES[item.rarity] + "</font>\n";
			switch (item.kind) {
				case "weapon":
					// (a tiered weapon's signature shot)
					// (only a plain tiered weapon: a named one may be built on a tiered base, but shoots its own way)
					if (item.sig !== undefined && !item.uid && !item.rarity && SIGS[item.sub] && SIGS[item.sub][item.sig]) s += "<font color='#ffd27a'>" + SIGS[item.sub][item.sig].tx + "</font>\n";
					if (item.form && FORMS[item.form]) s += "<font color='#9ad0ff'>" + FORMS[item.form].name + ":</font> " + FORMS[item.form].desc + "\n";
					s += "Damage: " + item.dmin + "-" + item.dmax + (item.shots > 1 ? " per shot" : "") + "\n";
					if (item.shots > 1) s += "Shots: " + item.shots + "\n";
					s += "Range: " + (item.spd * item.life).toFixed(1) + " tiles\n";
					if (item.pierce) s += "Shots hit multiple targets\n";
					if (item.rate != 1) s += "Rate of fire: " + Math.round(item.rate * 100) + "%\n";
					break;
				case "armor":
					break;
				case "ability":
					s += abilityText(item) + "\n";
					s += "Ability power: " + Math.round(item.power * 100) + "%\n";
					break;
				case "hp": s += "Restores 100 HP\n"; break;
				case "mp": s += "Restores 100 MP\n"; break;
				case "stat": s += "Permanently raises " + STAT_NAMES[item.sub] + "\n"; break;
				case "key":
					if (keyDungeon(item) >= 0) s += "Opens a portal to the " + DUNGEONS[keyDungeon(item)].name + " (30 seconds; your party can follow).\nClick it in the Nexus or a realm.\nSold by the Key Merchant.\n";
					else s += "Opens a portal to " + Bosses.RAIDS[Math.max(0, keyRaid(item))].name + ".\nUse it in the Nexus (click it) or at the Raid Table.\nDrops rarely from bosses.\n";
					break;
				case "material": s += "Crafting material for the Starforge.\nForge: Runed, Bonded or Eldritch item + Star Shard + 100 Aether = Starforged\n"; break;
				case "stone": s += "Pets evolve with these at the Pet Yard.\nBosses drop them (raids and the Dark Elder most often).\n"; break;
				case "rune": s += "Starforge: carry it when you reroll an item's bonus stats and " + STAT_NAMES[item.sub] + " is sure to be one of them (the rune is used up).\n"; break;
			}
			if (isGear(item)) {
				var on:String = "";
				for each (var k:String in STATS.concat(GEAR_STATS)) {
					if (item[k] && !(k == "spd" && item.kind == "weapon")) on += (item[k] < 0 ? "  <font color='#ff6060'>" + item[k] + " " + STAT_NAMES[k] + "</font>" : "  +" + item[k] + " " + STAT_NAMES[k]) + "\n";
				}
				if (on) s += "On equip:\n" + on;
			}
			if (item.curse && CURSES[item.curse]) s += "<font color='" + Ui.hex(CURSE_COLOR) + "'>Cursed (" + CURSES[item.curse].name + "): " + CURSES[item.curse].desc + ".</font>\n<font color='#8a7aa0'>The Anvil and stat rerolls can't touch it.</font>\n";
			if (item.passive) {
				var p:Object = PASSIVES[item.passive];
				s += "<font color='#d8e040'>" + p.name + ":</font> " + p.desc + "\n";
			}
			if (item.uid) s += Uniques.describe(item);
			if (item.rarity == "gd") s += Godly.describe(item);
			if (item.set) s += "<font color='" + Ui.hex(RARITY_COLORS.st) + "'>" + setName(item.set) + " Set (4 pieces): " + setBonusText(item.set) + "</font>\n";
			if (isGear(item) && item.kind != "ring") {
				var ok:Boolean = !viewerClass || canUse(item, viewerClass);
				s += "<font color='" + (ok ? "#9a9aaa" : "#ff6060") + "'>Usable by: " + usableBy(item).join(", ") + (ok ? "" : " (not your class)") + "</font>\n";
			}
			s += "<font color='#888888'>Sells for " + sellValue(item) + " gold</font>\n";
			return s;
		}

		// ---- enemies ----------------------------------------------------
		// ai: chase (close to `keep`), orbit (circle at `keep`), wander, charge, boss
		// attacks: p = aimed | ring | spiral | summon ; arc in degrees ; spd tiles/s ; life seconds
		public static const ENEMIES:Object = {
			pirate: {name: "Pirate", spr: "pirate", hp: 30, def: 0, spd: 1.6, xp: 10, ai: "chase", keep: 3, drop: 0.12, col: 0xc02020,
				portal: "pirate_cove", portalChance: 0.01,
				attacks: [{p: "aimed", n: 1, spd: 6, life: 1.0, dmg: 8, cd: 1.3, r: 0.15, col: 0xffffff}]},
			snake: {name: "Sand Snake", spr: "snake", hp: 22, def: 0, spd: 2.2, xp: 8, ai: "orbit", keep: 3, drop: 0.1, col: 0xc8b040,
				portal: "snake_pit", portalChance: 0.01,
				attacks: [{p: "aimed", n: 1, spd: 7, life: 0.8, dmg: 6, cd: 0.9, r: 0.12, col: 0x80ff80}]},
			crab: {name: "Shore Crab", spr: "crab", hp: 50, def: 2, spd: 1.0, xp: 12, ai: "wander", drop: 0.15, col: 0xe05030,
				attacks: [{p: "ring", n: 6, rot: 30, spd: 4, life: 1.3, dmg: 10, cd: 2.0, r: 0.2, col: 0xe08030, shape: "ring"}]},

			goblin: {name: "Goblin", spr: "goblin", hp: 90, def: 2, spd: 2.4, xp: 18, ai: "chase", keep: 1.5, drop: 0.16, col: 0x6ab040,
				attacks: [{p: "aimed", n: 2, arc: 15, spd: 7, life: 0.6, dmg: 12, cd: 1.0, r: 0.15, col: 0xc0ff60}]},
			hobbit: {name: "Hobbit Mage", spr: "hobbit", hp: 70, def: 0, spd: 1.6, xp: 18, ai: "orbit", keep: 4, drop: 0.16, col: 0x8040a0,
				attacks: [{p: "aimed", n: 3, arc: 30, spd: 6, life: 1.1, dmg: 14, cd: 1.4, r: 0.15, col: 0x66ccff}]},
			bandit: {name: "Bandit", spr: "bandit", hp: 120, def: 3, spd: 1.8, xp: 22, ai: "charge", keep: 2, drop: 0.18, col: 0x404040,
				attacks: [{p: "aimed", n: 1, spd: 9, life: 0.8, dmg: 15, cd: 1.0, r: 0.17, col: 0xff6060}]},

			orc: {name: "Orc Warrior", spr: "orc", hp: 260, def: 4, spd: 2.6, xp: 30, ai: "chase", keep: 1, drop: 0.2, col: 0x3a7a3a,
				attacks: [{p: "aimed", n: 3, arc: 40, spd: 8, life: 0.5, dmg: 30, cd: 0.8, r: 0.18, col: 0xff5050}]},
			elf: {name: "Dark Elf Archer", spr: "elf", hp: 180, def: 2, spd: 2.0, xp: 30, ai: "orbit", keep: 5, drop: 0.2, col: 0x40204a,
				attacks: [{p: "aimed", n: 1, spd: 12, life: 0.7, dmg: 28, cd: 1.0, r: 0.14, col: 0xd0a0ff, shape: "arrow", eff: "slowed"},
					{p: "aimed", n: 3, arc: 20, spd: 9, life: 0.8, dmg: 22, cd: 2.5, r: 0.14, col: 0xd0a0ff}]},
			gazer: {name: "Gazer", spr: "gazer", hp: 320, def: 6, spd: 1.2, xp: 34, ai: "wander", drop: 0.22, col: 0x9040a0,
				attacks: [{p: "ring", n: 8, rot: 22, spd: 5, life: 1.5, dmg: 24, cd: 1.6, r: 0.18, col: 0xff80ff, shape: "star"}]},

			medusa: {name: "Medusa", spr: "medusa", hp: 900, def: 10, spd: 1.6, xp: 70, ai: "orbit", keep: 5, drop: 0.3, col: 0x40c040,
				attacks: [{p: "ring", n: 12, rot: 15, spd: 5, life: 1.6, dmg: 45, cd: 2.0, r: 0.2, col: 0x60ff60},
					{p: "aimed", n: 1, spd: 9, life: 1.0, dmg: 60, cd: 1.2, r: 0.25, col: 0xffff60, eff: "paralyzed"}]},
			djinn: {name: "Djinn", spr: "djinn", hp: 700, def: 8, spd: 2.8, xp: 65, ai: "orbit", keep: 4, drop: 0.3, col: 0x50a0ff,
				attacks: [{p: "spiral", n: 4, rot: 13, spd: 6, life: 1.4, dmg: 35, cd: 0.18, r: 0.16, col: 0x60c0ff}]},
			ent: {name: "Ent Ancient", spr: "ent", hp: 1500, def: 20, spd: 0.8, xp: 90, ai: "chase", keep: 2, drop: 0.35, col: 0x3a8a2a,
				attacks: [{p: "aimed", n: 5, arc: 60, spd: 6, life: 1.2, dmg: 50, cd: 1.5, r: 0.22, col: 0x99ff44}]},
			beholder: {name: "Beholder", spr: "beholder", hp: 1100, def: 12, spd: 1.4, xp: 80, ai: "wander", drop: 0.32, col: 0xb02020,
				attacks: [{p: "ring", n: 16, rot: 11, spd: 4.5, life: 2.0, dmg: 40, cd: 2.6, r: 0.22, col: 0xd02020, shape: "star"},
					{p: "aimed", n: 2, arc: 10, spd: 10, life: 1.0, dmg: 55, cd: 1.3, r: 0.2, col: 0xffe0a0}]},

			cubelet: {name: "Cubelet", spr: "cubelet", hp: 150, def: 5, spd: 3.2, xp: 10, ai: "chase", keep: 0.5, drop: 0, col: 0x9040e0,
				attacks: [{p: "aimed", n: 1, spd: 8, life: 1.0, dmg: 30, cd: 0.7, r: 0.15, col: 0xc080ff}]},

			// ---- realm events ---------------------------------------------------
			ev_cube: {name: "Cube Overlord", spr: "boss", hp: 11000, def: 22, spd: 1.2, xp: 1500, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0x7a30c0,
				gold: 400, onrane: 4,
				phases: [
					[{p: "spiral", n: 4, rot: 11, spd: 5.5, life: 2.4, dmg: 55, cd: 0.14, r: 0.2, col: 0xff40ff},
						{p: "aimed", n: 3, arc: 24, spd: 9, life: 1.5, dmg: 70, cd: 1.4, r: 0.25, col: 0xf0d040, shape: "blade"}],
					[{p: "ring", n: 24, rot: 7.5, spd: 4.5, life: 2.8, dmg: 60, cd: 1.1, r: 0.25, col: 0xe08030, shape: "ring"},
						{p: "aimed", n: 1, spd: 12, life: 1.2, dmg: 90, cd: 0.6, r: 0.3, col: 0xff4040, shape: "blade"},
						{p: "summon", n: 2, cd: 6, what: "cubelet"}],
					[{p: "spiral", n: 6, rot: -9, spd: 6, life: 2.2, dmg: 60, cd: 0.12, r: 0.2, col: 0xffff40},
						{p: "aimed", n: 7, arc: 70, spd: 8, life: 1.6, dmg: 65, cd: 1.0, r: 0.22, col: 0xff8040}]
				]},
			ev_titan: {name: "Vorgath the Ember Titan", spr: "titan", hp: 13000, def: 28, spd: 1.0, xp: 1700, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0xff7020,
				gold: 450, onrane: 5,
				phases: [
					[{p: "aimed", n: 5, arc: 50, spd: 7, life: 1.8, dmg: 65, cd: 1.1, r: 0.25, col: 0xff7020, shape: "orb"},
						{p: "ring", n: 12, rot: 15, spd: 4, life: 2.6, dmg: 50, cd: 2.2, r: 0.22, col: 0xffb030, shape: "ring"}],
					[{p: "spiral", n: 3, rot: 17, spd: 6, life: 2.2, dmg: 60, cd: 0.13, r: 0.22, col: 0xff5020, shape: "star"},
						{p: "summon", n: 3, cd: 7, what: "imp"}],
					[{p: "ring", n: 30, rot: 6, spd: 5, life: 2.6, dmg: 70, cd: 0.9, r: 0.25, col: 0xffd040, shape: "orb"},
						{p: "aimed", n: 3, arc: 16, spd: 11, life: 1.4, dmg: 95, cd: 0.7, r: 0.3, col: 0xff3010, shape: "blade"}]
				]},
			ev_wyrm: {name: "Sylith the Frost Wyrm", spr: "wyrm", hp: 10000, def: 18, spd: 2.0, xp: 1600, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0x60c8ff,
				gold: 400, onrane: 4,
				phases: [
					[{p: "spiral", n: 5, rot: 9, spd: 6.5, life: 2.0, dmg: 50, cd: 0.16, r: 0.2, col: 0x8ad8ff, shape: "star", eff: "slowed"}],
					[{p: "aimed", n: 9, arc: 90, spd: 7, life: 1.8, dmg: 60, cd: 0.9, r: 0.22, col: 0xe0f4ff, shape: "dart"},
						{p: "ring", n: 16, rot: 11, spd: 3.5, life: 3.0, dmg: 55, cd: 1.6, r: 0.25, col: 0x40a0ff, shape: "ring"}],
					[{p: "spiral", n: 8, rot: -7, spd: 5.5, life: 2.4, dmg: 60, cd: 0.14, r: 0.22, col: 0xc0ecff, shape: "star"},
						{p: "aimed", n: 1, spd: 13, life: 1.4, dmg: 110, cd: 0.8, r: 0.3, col: 0xffffff, shape: "blade"}]
				]},
			ev_king: {name: "The Hollow King", spr: "hollowking", hp: 12000, def: 20, spd: 1.3, xp: 1600, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0xe8e0c0,
				gold: 450, onrane: 5,
				phases: [
					[{p: "aimed", n: 3, arc: 20, spd: 8, life: 1.6, dmg: 70, cd: 1.0, r: 0.25, col: 0x9aff7a, shape: "star", eff: "bleeding"},
						{p: "summon", n: 2, cd: 6, what: "skeleton"}],
					[{p: "ring", n: 20, rot: 9, spd: 4.5, life: 2.4, dmg: 55, cd: 1.0, r: 0.22, col: 0x6aff4a, shape: "orb"},
						{p: "aimed", n: 5, arc: 40, spd: 9, life: 1.4, dmg: 70, cd: 1.2, r: 0.22, col: 0xe8e0c0, shape: "dart"}],
					[{p: "spiral", n: 4, rot: 14, spd: 6, life: 2.4, dmg: 65, cd: 0.12, r: 0.22, col: 0x9aff7a, shape: "star"},
						{p: "summon", n: 3, cd: 8, what: "skeleton"}]
				]},
			// ---- the realm's overlord, fought in his chamber when the realm closes
			elder: {name: "Azrakor the Dark Elder", spr: "elder", hp: 55000, def: 34, spd: 1.4, xp: 5000, ai: "boss", r: 0.9, aggro: 20, range: 18, drop: 1, col: 0xa040ff,
				gold: 1500, onrane: 15, final: true,
				phases: [
					[{p: "spiral", n: 4, rot: 12, spd: 5.5, life: 3.0, dmg: 60, cd: 0.12, r: 0.22, col: 0xc060ff, shape: "star"},
						{p: "aimed", n: 3, arc: 18, spd: 10, life: 2.0, dmg: 80, cd: 1.2, r: 0.28, col: 0xffe060, shape: "blade"}],
					[{p: "ring", n: 32, rot: 5.6, spd: 4.5, life: 3.4, dmg: 65, cd: 1.0, r: 0.25, col: 0xe02040, shape: "ring"},
						{p: "aimed", n: 7, arc: 60, spd: 8, life: 2.0, dmg: 70, cd: 1.3, r: 0.22, col: 0xffffff, shape: "dart", eff: "confused"},
						{p: "summon", n: 2, cd: 8, what: "shade"}],
					[{p: "spiral", n: 6, rot: -10, spd: 6, life: 3.0, dmg: 70, cd: 0.1, r: 0.22, col: 0xff40a0, shape: "star"},
						{p: "aimed", n: 1, spd: 14, life: 1.8, dmg: 130, cd: 0.6, r: 0.32, col: 0xffe060, shape: "blade", eff: "armorbroken"},
						{p: "ring", n: 12, rot: 15, spd: 3, life: 4, dmg: 60, cd: 2.0, r: 0.28, col: 0xa040ff, shape: "orb"}]
				]},
			// ---- dungeon bosses
			warden: {name: "The Crypt Warden", spr: "warden", hp: 9000, def: 18, spd: 1.2, xp: 1200, ai: "boss", r: 0.9, aggro: 12, range: 13, drop: 1, col: 0x6ad0ff,
				gold: 300, onrane: 3, dungeon: true,
				phases: [
					[{p: "aimed", n: 5, arc: 50, spd: 7, life: 1.8, dmg: 55, cd: 1.0, r: 0.22, col: 0x6ad0ff, shape: "star", eff: "paralyzed"},
						{p: "summon", n: 2, cd: 7, what: "skeleton"}],
					[{p: "ring", n: 18, rot: 10, spd: 4.5, life: 2.4, dmg: 55, cd: 1.0, r: 0.22, col: 0x9ae8ff, shape: "orb"},
						{p: "aimed", n: 1, spd: 12, life: 1.4, dmg: 90, cd: 0.7, r: 0.3, col: 0xffffff, shape: "blade"}],
					[{p: "spiral", n: 5, rot: 12, spd: 6, life: 2.2, dmg: 60, cd: 0.13, r: 0.22, col: 0x6ad0ff, shape: "star"},
						{p: "summon", n: 2, cd: 8, what: "shade"}]
				]},
			pyrelord: {name: "Pyrelord Ignaar", spr: "pyrelord", hp: 10000, def: 22, spd: 1.0, xp: 1300, ai: "boss", r: 0.9, aggro: 12, range: 13, drop: 1, col: 0xff5020,
				gold: 320, onrane: 3, dungeon: true,
				phases: [
					[{p: "ring", n: 14, rot: 13, spd: 4, life: 2.6, dmg: 55, cd: 1.6, r: 0.24, col: 0xff7020, shape: "ring"},
						{p: "aimed", n: 3, arc: 24, spd: 9, life: 1.5, dmg: 70, cd: 0.9, r: 0.24, col: 0xffd040, shape: "orb"}],
					[{p: "spiral", n: 4, rot: -15, spd: 6, life: 2.2, dmg: 60, cd: 0.12, r: 0.22, col: 0xff4010, shape: "star"},
						{p: "summon", n: 3, cd: 7, what: "imp"}],
					[{p: "aimed", n: 9, arc: 100, spd: 8, life: 1.6, dmg: 70, cd: 0.8, r: 0.24, col: 0xffb030, shape: "orb"},
						{p: "ring", n: 24, rot: 7.5, spd: 5, life: 2.4, dmg: 65, cd: 1.2, r: 0.24, col: 0xff3010, shape: "ring", eff: "bleeding"}]
				]},
			// ---- more realm events
			ev_behemoth: {name: "Gorehorn the Behemoth", spr: "behemoth", hp: 14000, def: 30, spd: 1.6, xp: 1700, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0x6ac040,
				gold: 450, onrane: 5,
				phases: [
					[{p: "aimed", n: 7, arc: 70, spd: 7, life: 1.6, dmg: 70, cd: 1.2, r: 0.26, col: 0x9aff5a, shape: "orb", eff: "bleeding"}],
					[{p: "ring", n: 20, rot: 9, spd: 5, life: 2.2, dmg: 60, cd: 0.9, r: 0.24, col: 0x6ac040, shape: "ring"},
						{p: "summon", n: 3, cd: 7, what: "orc"}],
					[{p: "spiral", n: 4, rot: 21, spd: 7, life: 2.0, dmg: 65, cd: 0.1, r: 0.22, col: 0xc0ff60, shape: "star"},
						{p: "aimed", n: 3, arc: 30, spd: 10, life: 1.4, dmg: 90, cd: 0.8, r: 0.3, col: 0xffffff, shape: "blade", eff: "armorbroken"}]
				]},
			ev_regent: {name: "The Phantom Regent", spr: "regent", hp: 11000, def: 18, spd: 2.4, xp: 1600, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0xb070ff,
				gold: 420, onrane: 5, hardDungeon: "sanctum",
				phases: [
					[{p: "spiral", n: 6, rot: 8, spd: 5, life: 2.6, dmg: 50, cd: 0.15, r: 0.2, col: 0xc090ff, shape: "star"},
						{p: "aimed", n: 1, spd: 11, life: 1.4, dmg: 80, cd: 0.9, r: 0.26, col: 0xffffff, shape: "dart", eff: "confused"}],
					[{p: "summon", n: 3, cd: 6, what: "shade"},
						{p: "ring", n: 16, rot: 11, spd: 4, life: 2.8, dmg: 60, cd: 1.3, r: 0.24, col: 0x8040c0, shape: "orb"}],
					[{p: "spiral", n: 8, rot: -6, spd: 6, life: 2.4, dmg: 60, cd: 0.12, r: 0.2, col: 0xe0b0ff, shape: "star"},
						{p: "aimed", n: 5, arc: 40, spd: 9, life: 1.6, dmg: 75, cd: 1.0, r: 0.24, col: 0xff60c0, shape: "blade", eff: "slowed"}]
				]},
			sorcerer: {name: "The Cellar Sorcerer", spr: "sorcerer", hp: 9500, def: 16, spd: 1.8, xp: 1300, ai: "boss", r: 0.9, aggro: 12, range: 13, drop: 1, col: 0x60a0ff,
				gold: 320, onrane: 3, dungeon: true,
				phases: [
					[{p: "aimed", n: 3, arc: 12, spd: 10, life: 1.4, dmg: 45, cd: 0.35, r: 0.2, col: 0x4080ff, shape: "orb"},
						{p: "aimed", n: 5, arc: 60, spd: 7, life: 1.6, dmg: 55, cd: 1.4, r: 0.22, col: 0xffffff, shape: "dart", eff: "confused"}],
					[{p: "ring", n: 14, rot: 13, spd: 5, life: 2.2, dmg: 50, cd: 0.8, r: 0.22, col: 0xff4040, shape: "orb"},
						{p: "summon", n: 2, cd: 7, what: "hobbit"}],
					[{p: "aimed", n: 3, arc: 10, spd: 12, life: 1.4, dmg: 120, cd: 0.9, r: 0.3, col: 0x2040c0, shape: "blade"},
						{p: "spiral", n: 4, rot: 16, spd: 6, life: 2.2, dmg: 55, cd: 0.14, r: 0.2, col: 0x80c0ff, shape: "star", eff: "paralyzed"}]
				]},
			seraph: {name: "Tempest Seraph", spr: "seraph", hp: 8500, def: 15, spd: 2.2, xp: 1200, ai: "boss", r: 0.9, aggro: 12, range: 13, drop: 1, col: 0xf0e040,
				gold: 300, onrane: 3, dungeon: true,
				phases: [
					[{p: "spiral", n: 3, rot: 19, spd: 7, life: 1.8, dmg: 50, cd: 0.12, r: 0.2, col: 0xfff060, shape: "dart"}],
					[{p: "aimed", n: 1, spd: 15, life: 1.2, dmg: 100, cd: 0.5, r: 0.3, col: 0xffffff, shape: "blade", eff: "paralyzed"},
						{p: "ring", n: 12, rot: 15, spd: 6, life: 1.8, dmg: 55, cd: 1.3, r: 0.22, col: 0xd0d0ff, shape: "star"}],
					[{p: "spiral", n: 6, rot: 9, spd: 7, life: 2.0, dmg: 60, cd: 0.11, r: 0.2, col: 0xfff060, shape: "dart"},
						{p: "summon", n: 2, cd: 8, what: "djinn"}]
				]},
			// ---- extra realm monsters
			slime: {name: "Sea Slime", spr: "slime", hp: 40, def: 0, spd: 1.2, xp: 10, ai: "wander", drop: 0.12, col: 0x5ac040,
				attacks: [{p: "ring", n: 4, rot: 45, spd: 3.5, life: 1.2, dmg: 9, cd: 1.8, r: 0.16, col: 0x9aff7a, shape: "orb"}]},
			wolf: {name: "Dire Wolf", spr: "wolf", hp: 55, def: 0, spd: 3.2, xp: 16, ai: "chase", keep: 1.5, drop: 0.12, col: 0x8a8a92,
				attacks: [{p: "aimed", n: 2, arc: 24, spd: 8, life: 0.35, dmg: 7, cd: 1.2, r: 0.15, col: 0xffffff, shape: "blade"}]},
			golem: {name: "Stone Golem", spr: "golem", hp: 600, def: 12, spd: 0.9, xp: 38, ai: "chase", keep: 2, drop: 0.25, col: 0x8a8a8a,
				attacks: [{p: "ring", n: 10, rot: 18, spd: 4, life: 1.8, dmg: 26, cd: 2.2, r: 0.22, col: 0xb0b0b0, shape: "orb"},
					{p: "aimed", n: 1, spd: 9, life: 1.0, dmg: 40, cd: 1.6, r: 0.28, col: 0xe0e0e0, shape: "orb"}]},
			lich: {name: "Lich", spr: "lich", hp: 850, def: 10, spd: 1.5, xp: 75, ai: "blink", keep: 5, drop: 0.32, col: 0x60e0ff,
				portal: "undead_lair", portalChance: 0.03,
				attacks: [{p: "spiral", n: 3, rot: 20, spd: 5.5, life: 1.6, dmg: 40, cd: 0.22, r: 0.18, col: 0x60e0ff, shape: "star"},
					{p: "aimed", n: 1, spd: 10, life: 1.2, dmg: 55, cd: 1.4, r: 0.22, col: 0xffffff, shape: "dart", eff: "slowed"}]},
			imp: {name: "Ember Imp", spr: "imp", hp: 300, def: 5, spd: 3.0, xp: 15, ai: "chase", keep: 1, drop: 0, col: 0xff6020,
				attacks: [{p: "aimed", n: 2, arc: 20, spd: 8, life: 0.9, dmg: 35, cd: 0.8, r: 0.16, col: 0xff8030}]},
			skeleton: {name: "Bone Soldier", spr: "skeleton", hp: 350, def: 8, spd: 2.4, xp: 15, ai: "chase", keep: 1.5, drop: 0, col: 0xe8e0c0,
				attacks: [{p: "aimed", n: 1, spd: 10, life: 0.9, dmg: 45, cd: 0.9, r: 0.18, col: 0xe8e0c0, shape: "dart"}]},
			shade: {name: "Elder's Shade", spr: "shade", hp: 600, def: 10, spd: 3.0, xp: 20, ai: "orbit", keep: 4, drop: 0, col: 0x8040c0,
				attacks: [{p: "aimed", n: 3, arc: 24, spd: 9, life: 1.2, dmg: 50, cd: 1.1, r: 0.18, col: 0xc080ff, shape: "dart", eff: "confused"}]},
			// ================= RotMG-style realm monsters by biome =================
			// portal: the dungeon this monster can drop (portalChance per kill)
			// ---- Beach
			pirate_brawler: {name: "Pirate Brawler", spr: "pirate_brawler", hp: 48, def: 1, spd: 2.0, xp: 12, ai: "chase", keep: 1.5, drop: 0.13, col: 0x2a2a6a,
				portal: "pirate_cove", portalChance: 0.012,
				attacks: [{p: "aimed", n: 2, arc: 30, spd: 6, life: 0.6, dmg: 9, cd: 1.2, r: 0.15, col: 0xe0e0e0, shape: "blade"}]},
			pirate_captain: {name: "Pirate Captain", spr: "pirate_captain", hp: 170, def: 2, spd: 1.5, xp: 40, ai: "orbit", keep: 4, drop: 0.5, col: 0xb02020, r: 0.55,
				portal: "pirate_cove", portalChance: 0.15,
				attacks: [{p: "aimed", n: 3, arc: 24, spd: 6.5, life: 1.2, dmg: 11, cd: 1.3, r: 0.17, col: 0x404040, shape: "orb"},
					{p: "summon", n: 1, cd: 6, what: "pirate"}]},
			scorpion: {name: "Sand Scorpion", spr: "scorpion", hp: 35, def: 0, spd: 2.4, xp: 10, ai: "chase", keep: 2, drop: 0.1, col: 0xd06030,
				attacks: [{p: "aimed", n: 1, spd: 8, life: 0.6, dmg: 8, cd: 0.8, r: 0.13, col: 0x90ff40, shape: "dart"}]},
			// ---- Lowlands
			green_slime: {name: "Big Green Slime", spr: "green_slime", hp: 150, def: 2, spd: 1.0, xp: 26, ai: "wander", drop: 0.25, col: 0x40b030, r: 0.55,
				portal: "forest_maze", portalChance: 0.06,
				attacks: [{p: "ring", n: 8, rot: 22, spd: 3.5, life: 1.6, dmg: 12, cd: 1.6, r: 0.18, col: 0x9aff7a, shape: "orb"}]},
			goblin_chief: {name: "Goblin Chieftain", spr: "goblin_chief", hp: 320, def: 4, spd: 2.0, xp: 60, ai: "chase", keep: 2.5, drop: 0.45, col: 0x58a030, r: 0.55,
				attacks: [{p: "aimed", n: 5, arc: 50, spd: 7, life: 0.8, dmg: 15, cd: 1.3, r: 0.17, col: 0xc0ff60},
					{p: "summon", n: 2, cd: 7, what: "goblin"}]},
			bandit_leader: {name: "Bandit Leader", spr: "bandit_leader", hp: 380, def: 5, spd: 1.8, xp: 65, ai: "orbit", keep: 4, drop: 0.45, col: 0x6a1a1a, r: 0.55,
				attacks: [{p: "aimed", n: 1, spd: 11, life: 0.9, dmg: 22, cd: 0.8, r: 0.18, col: 0xff6060, shape: "knife"},
					{p: "summon", n: 2, cd: 8, what: "bandit"}]},
			// ---- Midlands
			spider: {name: "Forest Spider", spr: "spider", hp: 170, def: 3, spd: 3.0, xp: 26, ai: "chase", keep: 1.5, drop: 0.18, col: 0x3a2a3a,
				portal: "spider_den", portalChance: 0.02,
				attacks: [{p: "aimed", n: 2, arc: 16, spd: 8, life: 0.6, dmg: 20, cd: 0.9, r: 0.15, col: 0xffffff, shape: "dart", eff: "slowed"}]},
			spider_queen: {name: "Spider Queen", spr: "spider_queen", hp: 800, def: 6, spd: 1.6, xp: 120, ai: "orbit", keep: 4, drop: 0.5, col: 0xe0c020, r: 0.6,
				portal: "spider_den", portalChance: 0.18,
				attacks: [{p: "ring", n: 10, rot: 18, spd: 4.5, life: 1.6, dmg: 24, cd: 1.6, r: 0.18, col: 0xffffff, shape: "star", eff: "slowed"},
					{p: "summon", n: 2, cd: 6, what: "spider"}]},
			great_snake: {name: "Swamp Serpent", spr: "great_snake", hp: 380, def: 4, spd: 2.2, xp: 45, ai: "orbit", keep: 3.5, drop: 0.25, col: 0x3a8a3a, r: 0.55,
				portal: "snake_pit", portalChance: 0.06,
				attacks: [{p: "spiral", n: 2, rot: 25, spd: 5, life: 1.4, dmg: 20, cd: 0.25, r: 0.15, col: 0x80ff80, shape: "star"}]},
			orc_king: {name: "Orc King", spr: "orc_king", hp: 1000, def: 8, spd: 1.8, xp: 140, ai: "chase", keep: 2, drop: 0.5, col: 0x2a6a2a, r: 0.65,
				attacks: [{p: "aimed", n: 5, arc: 60, spd: 8, life: 0.7, dmg: 32, cd: 1.0, r: 0.2, col: 0xff5050, shape: "blade"},
					{p: "summon", n: 2, cd: 7, what: "orc"}]},
			// ---- Highlands
			harpy: {name: "Harpy", spr: "harpy", hp: 420, def: 5, spd: 3.2, xp: 50, ai: "orbit", keep: 4.5, drop: 0.24, col: 0x8a6a4a,
				attacks: [{p: "aimed", n: 3, arc: 30, spd: 9, life: 0.9, dmg: 30, cd: 1.0, r: 0.16, col: 0xe0c0a0, shape: "dart"}]},
			dwarf: {name: "Dwarf Axeman", spr: "dwarf", hp: 500, def: 9, spd: 2.0, xp: 50, ai: "chase", keep: 1.2, drop: 0.24, col: 0xc04a20,
				attacks: [{p: "aimed", n: 3, arc: 40, spd: 7, life: 0.5, dmg: 38, cd: 0.9, r: 0.2, col: 0xd0d0d0, shape: "blade"}]},
			dwarf_king: {name: "Dwarf King", spr: "dwarf_king", hp: 1700, def: 14, spd: 1.6, xp: 180, ai: "chase", keep: 2.5, drop: 0.55, col: 0xf0c030, r: 0.6,
				attacks: [{p: "ring", n: 12, rot: 15, spd: 5, life: 1.4, dmg: 36, cd: 1.6, r: 0.2, col: 0xf0c030, shape: "blade"},
					{p: "summon", n: 2, cd: 7, what: "dwarf"}]},
			ogre: {name: "Ogre", spr: "ogre", hp: 1300, def: 12, spd: 1.1, xp: 110, ai: "chase", keep: 2, drop: 0.32, col: 0xa08a5a, r: 0.65,
				attacks: [{p: "ring", n: 14, rot: 13, spd: 4, life: 1.8, dmg: 34, cd: 2.0, r: 0.24, col: 0xc0a070, shape: "orb"},
					{p: "aimed", n: 1, spd: 8, life: 1.2, dmg: 55, cd: 1.6, r: 0.3, col: 0x8a6a4a, shape: "orb", eff: "armorbroken"}]},
			minotaur: {name: "Minotaur", spr: "minotaur", hp: 900, def: 10, spd: 2.2, xp: 90, ai: "charge", keep: 2, drop: 0.3, col: 0x6a3a1a, r: 0.6,
				attacks: [{p: "aimed", n: 3, arc: 20, spd: 10, life: 0.6, dmg: 40, cd: 1.0, r: 0.2, col: 0xffffff, shape: "blade"}]},
			// ---- Godlands
			ghost_god: {name: "Ghost God", spr: "ghost_god", hp: 1200, def: 10, spd: 2.0, xp: 95, ai: "blink", keep: 4, drop: 0.32, col: 0xc8d8f0,
				portal: "undead_lair", portalChance: 0.05,
				attacks: [{p: "ring", n: 12, rot: 10, spd: 5, life: 1.6, dmg: 45, cd: 1.4, r: 0.2, col: 0xc8d8f0, shape: "star"},
					{p: "aimed", n: 1, spd: 10, life: 1.2, dmg: 60, cd: 1.2, r: 0.24, col: 0xffffff, shape: "dart", eff: "confused"}]},
			demon: {name: "White Demon", spr: "demon", hp: 1300, def: 14, spd: 2.4, xp: 100, ai: "orbit", keep: 4, drop: 0.34, col: 0xd02020,
				portal: "abyss", portalChance: 0.05,
				attacks: [{p: "aimed", n: 5, arc: 40, spd: 8, life: 1.2, dmg: 50, cd: 1.0, r: 0.22, col: 0xff4020, shape: "orb"},
					{p: "spiral", n: 2, rot: 30, spd: 5, life: 1.4, dmg: 40, cd: 0.3, r: 0.18, col: 0xffe040, shape: "star"}]},
			sprite_god: {name: "Sprite God", spr: "sprite_god", hp: 1000, def: 8, spd: 3.0, xp: 95, ai: "orbit", keep: 5, drop: 0.32, col: 0xff80d0,
				portal: "sprite_world", portalChance: 0.06,
				attacks: [{p: "spiral", n: 3, rot: -18, spd: 6, life: 1.4, dmg: 38, cd: 0.2, r: 0.16, col: 0xff80d0, shape: "star"}]},
			slime_god: {name: "Slime God", spr: "slime_god", hp: 1600, def: 12, spd: 1.0, xp: 100, ai: "wander", drop: 0.34, col: 0x8040c0, r: 0.65,
				attacks: [{p: "ring", n: 20, rot: 9, spd: 4, life: 2.0, dmg: 42, cd: 1.6, r: 0.22, col: 0xd0a0ff, shape: "orb", eff: "slowed"}]},

			// ================= dungeon minions =================
			mothling: {name: "Mothling", spr: "mothling", hp: 160, def: 2, spd: 3.0, xp: 12, ai: "chase", keep: 1, drop: 0, col: 0xc8c090,
				attacks: [{p: "aimed", n: 1, spd: 8, life: 0.7, dmg: 16, cd: 1.0, r: 0.15, col: 0xe0d8a0, shape: "dart"}]},
			ghost: {name: "Lost Soul", spr: "ghost", hp: 500, def: 8, spd: 2.8, xp: 20, ai: "orbit", keep: 3, drop: 0, col: 0xc8d8f0,
				attacks: [{p: "aimed", n: 2, arc: 20, spd: 9, life: 1.0, dmg: 45, cd: 1.0, r: 0.17, col: 0xc8d8f0, shape: "star"}]},
			lesser_demon: {name: "Lesser Demon", spr: "lesser_demon", hp: 650, def: 10, spd: 2.6, xp: 22, ai: "chase", keep: 2, drop: 0, col: 0xa02828,
				attacks: [{p: "aimed", n: 3, arc: 30, spd: 8, life: 1.0, dmg: 50, cd: 1.0, r: 0.2, col: 0xff4020, shape: "orb"}]},
			sprite: {name: "Sprite", spr: "sprite", hp: 450, def: 5, spd: 3.6, xp: 18, ai: "orbit", keep: 3, drop: 0, col: 0x80e080,
				attacks: [{p: "aimed", n: 1, spd: 10, life: 1.0, dmg: 45, cd: 0.7, r: 0.16, col: 0x80ff80, shape: "star"}]},

			// ================= dungeon bosses (dtier: 0 easy .. 4 endgame) =================
			cove_boss: {name: "Captain Saltbeard", spr: "pirate_king", hp: 1600, def: 3, spd: 1.4, xp: 400, ai: "boss", r: 0.9, aggro: 12, range: 12, drop: 1, col: 0x2a2a6a,
				gold: 120, onrane: 1, dungeon: true, dtier: 0,
				phases: [
					[{p: "aimed", n: 3, arc: 30, spd: 6, life: 1.6, dmg: 14, cd: 1.0, r: 0.22, col: 0x404040, shape: "orb"},
						{p: "summon", n: 1, cd: 6, what: "pirate"}],
					[{p: "ring", n: 10, rot: 18, spd: 4, life: 1.8, dmg: 14, cd: 1.4, r: 0.2, col: 0xe0e0e0, shape: "blade"},
						{p: "summon", n: 2, cd: 7, what: "pirate_brawler"}],
					[{p: "spiral", n: 3, rot: 20, spd: 5, life: 1.6, dmg: 15, cd: 0.25, r: 0.2, col: 0x404040, shape: "orb"},
						{p: "aimed", n: 1, spd: 9, life: 1.4, dmg: 25, cd: 0.9, r: 0.26, col: 0xf0c030, shape: "blade"}]
				]},
			moth_boss: {name: "Mother Mothwing", spr: "moth", hp: 3500, def: 5, spd: 2.0, xp: 700, ai: "boss", r: 0.9, aggro: 12, range: 12, drop: 1, col: 0xe0d8a0,
				gold: 180, onrane: 2, dungeon: true, dtier: 1,
				phases: [
					[{p: "spiral", n: 4, rot: 14, spd: 4.5, life: 1.8, dmg: 18, cd: 0.25, r: 0.2, col: 0xe0d8a0, shape: "star"}],
					[{p: "summon", n: 3, cd: 6, what: "mothling"},
						{p: "aimed", n: 5, arc: 50, spd: 6, life: 1.6, dmg: 22, cd: 1.2, r: 0.2, col: 0x9aff7a, shape: "orb", eff: "slowed"}],
					[{p: "ring", n: 16, rot: 11, spd: 5, life: 1.8, dmg: 22, cd: 0.9, r: 0.2, col: 0xffe080, shape: "star"},
						{p: "summon", n: 2, cd: 7, what: "mothling"}]
				]},
			serpent_boss: {name: "Ssythra the Serpent Queen", spr: "serpent_queen", hp: 5500, def: 8, spd: 1.6, xp: 1000, ai: "boss", r: 0.9, aggro: 12, range: 13, drop: 1, col: 0x2a9a6a,
				gold: 240, onrane: 2, dungeon: true, dtier: 2,
				phases: [
					[{p: "spiral", n: 4, rot: 12, spd: 5, life: 2.0, dmg: 28, cd: 0.18, r: 0.2, col: 0x60ff90, shape: "star"}],
					[{p: "aimed", n: 7, arc: 60, spd: 7, life: 1.6, dmg: 32, cd: 1.0, r: 0.22, col: 0xffe020, shape: "dart", eff: "paralyzed"},
						{p: "summon", n: 3, cd: 7, what: "great_snake"}],
					[{p: "ring", n: 24, rot: 7.5, spd: 4.5, life: 2.2, dmg: 30, cd: 1.0, r: 0.22, col: 0x2a9a6a, shape: "orb"},
						{p: "spiral", n: 2, rot: -22, spd: 6, life: 1.8, dmg: 30, cd: 0.15, r: 0.2, col: 0xa0e0c0, shape: "star"}]
				]},
			spider_boss: {name: "Arachnia the Broodmother", spr: "broodmother", hp: 6000, def: 9, spd: 1.8, xp: 1100, ai: "boss", r: 0.9, aggro: 12, range: 13, drop: 1, col: 0xff3030,
				gold: 260, onrane: 3, dungeon: true, dtier: 2,
				phases: [
					[{p: "aimed", n: 5, arc: 40, spd: 7, life: 1.6, dmg: 30, cd: 0.9, r: 0.2, col: 0xffffff, shape: "dart", eff: "slowed"},
						{p: "summon", n: 2, cd: 6, what: "spider"}],
					[{p: "ring", n: 20, rot: 9, spd: 5, life: 1.8, dmg: 28, cd: 1.0, r: 0.2, col: 0xffffff, shape: "star"},
						{p: "summon", n: 3, cd: 7, what: "spider"}],
					[{p: "spiral", n: 6, rot: 10, spd: 6, life: 1.8, dmg: 30, cd: 0.14, r: 0.2, col: 0xff3030, shape: "star"},
						{p: "aimed", n: 1, spd: 11, life: 1.4, dmg: 55, cd: 0.8, r: 0.26, col: 0xffe040, shape: "blade", eff: "paralyzed"}]
				]},
			lich_boss: {name: "Septorius the Lich King", spr: "lich_king", hp: 11000, def: 18, spd: 1.4, xp: 1400, ai: "boss", r: 0.9, aggro: 12, range: 13, drop: 1, col: 0xff4060,
				gold: 320, onrane: 4, dungeon: true, dtier: 4,
				phases: [
					[{p: "spiral", n: 4, rot: 13, spd: 5.5, life: 2.2, dmg: 55, cd: 0.14, r: 0.2, col: 0xff4060, shape: "star"},
						{p: "summon", n: 2, cd: 7, what: "ghost"}],
					[{p: "aimed", n: 1, spd: 13, life: 1.4, dmg: 110, cd: 0.7, r: 0.3, col: 0xffffff, shape: "blade", eff: "armorbroken"},
						{p: "ring", n: 18, rot: 10, spd: 4.5, life: 2.4, dmg: 55, cd: 1.1, r: 0.22, col: 0x8a60ff, shape: "orb"}],
					[{p: "spiral", n: 6, rot: -9, spd: 6, life: 2.2, dmg: 60, cd: 0.12, r: 0.2, col: 0xc0c0d0, shape: "star"},
						{p: "summon", n: 3, cd: 8, what: "skeleton"}]
				]},
			demon_boss: {name: "Malgoroth the Archdemon", spr: "archdemon", hp: 12000, def: 20, spd: 1.6, xp: 1500, ai: "boss", r: 0.9, aggro: 12, range: 13, drop: 1, col: 0xff6020,
				gold: 340, onrane: 4, dungeon: true, dtier: 4,
				phases: [
					[{p: "aimed", n: 5, arc: 40, spd: 8, life: 1.6, dmg: 65, cd: 1.0, r: 0.24, col: 0xff4020, shape: "orb"},
						{p: "summon", n: 2, cd: 7, what: "lesser_demon"}],
					[{p: "ring", n: 24, rot: 7.5, spd: 5, life: 2.2, dmg: 60, cd: 0.9, r: 0.24, col: 0xff6020, shape: "ring", eff: "bleeding"}],
					[{p: "spiral", n: 4, rot: 17, spd: 6.5, life: 2.0, dmg: 65, cd: 0.1, r: 0.22, col: 0xffe040, shape: "star"},
						{p: "aimed", n: 3, arc: 20, spd: 11, life: 1.4, dmg: 100, cd: 0.8, r: 0.3, col: 0xff2020, shape: "blade"}]
				]},
			sprite_boss: {name: "Lumina the Sprite Queen", spr: "sprite_queen", hp: 9500, def: 14, spd: 2.6, xp: 1300, ai: "boss", r: 0.9, aggro: 12, range: 13, drop: 1, col: 0xff60c0,
				gold: 300, onrane: 4, dungeon: true, dtier: 4,
				phases: [
					[{p: "spiral", n: 5, rot: 11, spd: 6, life: 2.0, dmg: 50, cd: 0.13, r: 0.2, col: 0xff80d0, shape: "star"}],
					[{p: "summon", n: 3, cd: 6, what: "sprite"},
						{p: "aimed", n: 7, arc: 70, spd: 8, life: 1.6, dmg: 55, cd: 1.0, r: 0.22, col: 0xfff0a0, shape: "dart", eff: "confused"}],
					[{p: "spiral", n: 8, rot: -8, spd: 6.5, life: 2.0, dmg: 55, cd: 0.12, r: 0.2, col: 0xff60c0, shape: "star"},
						{p: "aimed", n: 1, spd: 14, life: 1.2, dmg: 110, cd: 0.6, r: 0.3, col: 0xffffff, shape: "blade"}]
				]},

			// ================= more realm event bosses =================
			ev_sphinx: {name: "Nekhret the Sand Sphinx", spr: "sphinx", hp: 13000, def: 25, spd: 0.8, xp: 1700, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0xc8a050,
				gold: 450, onrane: 5, hardDungeon: "tomb",
				phases: [
					[{p: "ring", n: 18, rot: 10, spd: 4, life: 2.6, dmg: 55, cd: 1.2, r: 0.24, col: 0xe8c870, shape: "orb"},
						{p: "aimed", n: 3, arc: 20, spd: 9, life: 1.6, dmg: 70, cd: 1.0, r: 0.24, col: 0x40c0ff, shape: "blade", eff: "armorbroken"}],
					[{p: "spiral", n: 3, rot: 20, spd: 6, life: 2.2, dmg: 60, cd: 0.12, r: 0.22, col: 0xffe080, shape: "star"},
						{p: "summon", n: 3, cd: 8, what: "scorpion"}],
					[{p: "ring", n: 32, rot: 5.6, spd: 5, life: 2.4, dmg: 65, cd: 0.9, r: 0.24, col: 0xc8a050, shape: "orb"},
						{p: "aimed", n: 1, spd: 13, life: 1.6, dmg: 120, cd: 0.7, r: 0.3, col: 0x40c0ff, shape: "blade"}]
				]},
			ev_lord: {name: "Lord of the Sunken Lands", spr: "sunken_lord", hp: 14000, def: 28, spd: 1.2, xp: 1800, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0x6a8aa0,
				gold: 480, onrane: 5, hardDungeon: "sanctum",
				phases: [
					[{p: "aimed", n: 9, arc: 90, spd: 6.5, life: 1.8, dmg: 60, cd: 1.1, r: 0.22, col: 0x60e0ff, shape: "dart"},
						{p: "summon", n: 2, cd: 7, what: "ghost"}],
					[{p: "ring", n: 22, rot: 8, spd: 4.5, life: 2.4, dmg: 60, cd: 1.0, r: 0.22, col: 0x8aa0b0, shape: "ring", eff: "slowed"}],
					[{p: "spiral", n: 5, rot: 12, spd: 6, life: 2.2, dmg: 65, cd: 0.12, r: 0.22, col: 0x60e0ff, shape: "star"},
						{p: "aimed", n: 3, arc: 24, spd: 11, life: 1.4, dmg: 95, cd: 0.8, r: 0.3, col: 0xffffff, shape: "blade"}]
				]},
			ev_hermit: {name: "The Tide Hermit", spr: "hermit", hp: 12000, def: 22, spd: 0.6, xp: 1600, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0x2a9a8a,
				gold: 430, onrane: 5,
				phases: [
					[{p: "spiral", n: 6, rot: 9, spd: 5, life: 2.4, dmg: 50, cd: 0.16, r: 0.2, col: 0x60ffe0, shape: "orb"}],
					[{p: "ring", n: 16, rot: 11, spd: 3.5, life: 3.0, dmg: 60, cd: 1.0, r: 0.25, col: 0x2a9a8a, shape: "ring", eff: "paralyzed"},
						{p: "summon", n: 3, cd: 7, what: "slime_god"}],
					[{p: "spiral", n: 8, rot: -7, spd: 6, life: 2.2, dmg: 60, cd: 0.12, r: 0.2, col: 0xe0ff80, shape: "star"}]
				]},
			ev_shrine: {name: "The Skull Shrine", spr: "shrine", hp: 15000, def: 30, spd: 0.01, xp: 1900, ai: "boss", r: 0.9, aggro: 14, range: 15, drop: 1, col: 0xe8e0c8,
				gold: 500, onrane: 6,
				phases: [
					[{p: "ring", n: 12, rot: 15, spd: 5, life: 2.6, dmg: 60, cd: 0.8, r: 0.24, col: 0xff4040, shape: "orb"},
						{p: "summon", n: 2, cd: 6, what: "skeleton"}],
					[{p: "spiral", n: 4, rot: 15, spd: 6, life: 2.4, dmg: 60, cd: 0.1, r: 0.22, col: 0xffa040, shape: "star"},
						{p: "aimed", n: 5, arc: 30, spd: 9, life: 1.8, dmg: 70, cd: 1.0, r: 0.24, col: 0xe8e0c8, shape: "dart"}],
					[{p: "ring", n: 36, rot: 5, spd: 5, life: 2.6, dmg: 70, cd: 0.8, r: 0.24, col: 0xff2020, shape: "orb", eff: "bleeding"},
						{p: "summon", n: 3, cd: 8, what: "lesser_demon"}]
				]},

			// ================= hard multi-boss dungeon bosses (dtier 5) =================
			// guardian: must die before the sealed boss can be hurt; trio: fought together, survivors grow stronger
			sun_king: {name: "Solhar the Sun King", spr: "sun_king", hp: 15000, def: 22, spd: 1.3, xp: 1500, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0xffb020,
				gold: 400, onrane: 5, dungeon: true, dtier: 5, trio: true,
				phases: [
					[{p: "ring", n: 16, rot: 11, spd: 5, life: 2.4, dmg: 70, cd: 1.2, r: 0.24, col: 0xffc040, shape: "orb"},
						{p: "aimed", n: 3, arc: 20, spd: 10, life: 1.6, dmg: 85, cd: 1.0, r: 0.26, col: 0xff8020, shape: "blade"}],
					[{p: "spiral", n: 4, rot: 14, spd: 6, life: 2.4, dmg: 70, cd: 0.12, r: 0.22, col: 0xffe060, shape: "star"}],
					[{p: "ring", n: 28, rot: 6.4, spd: 5.5, life: 2.4, dmg: 75, cd: 0.8, r: 0.24, col: 0xff6010, shape: "orb", eff: "bleeding"},
						{p: "aimed", n: 1, spd: 14, life: 1.4, dmg: 130, cd: 0.6, r: 0.3, col: 0xffffff, shape: "blade"}]
				]},
			moon_queen: {name: "Lunara the Moon Queen", spr: "moon_queen", hp: 13500, def: 18, spd: 1.8, xp: 1500, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0x8a9aff,
				gold: 400, onrane: 5, dungeon: true, dtier: 5, trio: true,
				phases: [
					[{p: "spiral", n: 5, rot: -10, spd: 5.5, life: 2.6, dmg: 60, cd: 0.15, r: 0.2, col: 0xc0d0ff, shape: "star", eff: "slowed"}],
					[{p: "aimed", n: 9, arc: 100, spd: 7, life: 2.0, dmg: 70, cd: 1.0, r: 0.22, col: 0xe0e8ff, shape: "dart"},
						{p: "summon", n: 2, cd: 8, what: "ghost"}],
					[{p: "spiral", n: 8, rot: 8, spd: 6, life: 2.4, dmg: 70, cd: 0.12, r: 0.22, col: 0x8a9aff, shape: "star", eff: "confused"}]
				]},
			star_prince: {name: "Astrel the Star Prince", spr: "star_prince", hp: 12500, def: 16, spd: 2.4, xp: 1500, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0xc070ff,
				gold: 400, onrane: 5, dungeon: true, dtier: 5, trio: true,
				phases: [
					[{p: "aimed", n: 3, arc: 12, spd: 11, life: 1.6, dmg: 75, cd: 0.4, r: 0.22, col: 0xfff060, shape: "star"}],
					[{p: "ring", n: 20, rot: 9, spd: 6, life: 2.0, dmg: 65, cd: 0.9, r: 0.22, col: 0xc070ff, shape: "orb"},
						{p: "aimed", n: 1, spd: 15, life: 1.4, dmg: 120, cd: 0.8, r: 0.3, col: 0xffffff, shape: "blade", eff: "paralyzed"}],
					[{p: "spiral", n: 6, rot: -13, spd: 7, life: 2.0, dmg: 70, cd: 0.1, r: 0.2, col: 0xfff060, shape: "star"}]
				]},
			frost_warden: {name: "Glacius the Frost Warden", spr: "frost_warden", hp: 18000, def: 25, spd: 1.2, xp: 1600, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0x80e0ff,
				gold: 400, onrane: 5, dungeon: true, dtier: 5, guardian: true,
				phases: [
					[{p: "ring", n: 18, rot: 10, spd: 4.5, life: 2.8, dmg: 70, cd: 1.1, r: 0.24, col: 0xc0f0ff, shape: "ring", eff: "slowed"},
						{p: "aimed", n: 5, arc: 40, spd: 9, life: 1.6, dmg: 80, cd: 1.0, r: 0.22, col: 0xffffff, shape: "dart"}],
					[{p: "spiral", n: 5, rot: 11, spd: 6, life: 2.4, dmg: 70, cd: 0.13, r: 0.22, col: 0x80e0ff, shape: "star"},
						{p: "summon", n: 2, cd: 8, what: "ghost"}],
					[{p: "ring", n: 32, rot: 5.6, spd: 5, life: 2.6, dmg: 80, cd: 0.8, r: 0.24, col: 0x40a0ff, shape: "orb", eff: "paralyzed"}]
				]},
			flame_warden: {name: "Ignivar the Flame Warden", spr: "flame_warden", hp: 18000, def: 25, spd: 1.4, xp: 1600, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0xff6020,
				gold: 400, onrane: 5, dungeon: true, dtier: 5, guardian: true,
				phases: [
					[{p: "aimed", n: 7, arc: 70, spd: 8, life: 1.8, dmg: 80, cd: 1.0, r: 0.24, col: 0xff6020, shape: "orb", eff: "bleeding"}],
					[{p: "spiral", n: 4, rot: -16, spd: 6.5, life: 2.2, dmg: 75, cd: 0.11, r: 0.22, col: 0xffb030, shape: "star"},
						{p: "summon", n: 2, cd: 8, what: "lesser_demon"}],
					[{p: "ring", n: 24, rot: 7.5, spd: 6, life: 2.4, dmg: 85, cd: 0.7, r: 0.24, col: 0xff3010, shape: "ring"},
						{p: "aimed", n: 1, spd: 15, life: 1.4, dmg: 140, cd: 0.7, r: 0.32, col: 0xffff80, shape: "blade"}]
				]},
			shattered_seraph: {name: "The Shattered Seraph", spr: "shattered_seraph", hp: 32000, def: 30, spd: 2.0, xp: 4000, ai: "boss", r: 0.9, aggro: 16, range: 16, drop: 1, col: 0xff60c0,
				gold: 900, onrane: 10, dungeon: true, dtier: 5, sealed: true,
				phases: [
					[{p: "spiral", n: 6, rot: 10, spd: 6, life: 2.8, dmg: 75, cd: 0.12, r: 0.22, col: 0xff60c0, shape: "star"},
						{p: "aimed", n: 3, arc: 18, spd: 11, life: 2.0, dmg: 95, cd: 1.0, r: 0.28, col: 0xffffff, shape: "blade"}],
					[{p: "ring", n: 36, rot: 5, spd: 5, life: 3.0, dmg: 80, cd: 0.9, r: 0.24, col: 0x9a7aff, shape: "ring", eff: "armorbroken"},
						{p: "summon", n: 2, cd: 7, what: "sprite"}],
					[{p: "spiral", n: 8, rot: -9, spd: 7, life: 2.6, dmg: 85, cd: 0.1, r: 0.22, col: 0xff2060, shape: "star"},
						{p: "aimed", n: 7, arc: 60, spd: 9, life: 2.0, dmg: 90, cd: 1.1, r: 0.24, col: 0xffd0f0, shape: "dart", eff: "confused"}]
				]},
			blood_knight: {name: "Kael'zar the Blood Knight", spr: "blood_knight", hp: 20000, def: 30, spd: 1.8, xp: 1800, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0xd02030,
				gold: 450, onrane: 6, dungeon: true, dtier: 5, guardian: true,
				phases: [
					[{p: "aimed", n: 5, arc: 50, spd: 9, life: 1.4, dmg: 90, cd: 0.9, r: 0.26, col: 0xff4040, shape: "blade", eff: "bleeding"}],
					[{p: "ring", n: 20, rot: 9, spd: 6, life: 2.0, dmg: 80, cd: 0.9, r: 0.24, col: 0xa01020, shape: "blade"},
						{p: "summon", n: 3, cd: 8, what: "skeleton"}],
					[{p: "spiral", n: 4, rot: 19, spd: 7.5, life: 2.0, dmg: 85, cd: 0.1, r: 0.22, col: 0xff4040, shape: "blade"},
						{p: "aimed", n: 1, spd: 16, life: 1.2, dmg: 150, cd: 0.6, r: 0.32, col: 0xffffff, shape: "blade", eff: "armorbroken"}]
				]},
			hex_queen: {name: "Morwyn the Hex Queen", spr: "hex_queen", hp: 17000, def: 22, spd: 2.2, xp: 1800, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0x80ff60,
				gold: 450, onrane: 6, dungeon: true, dtier: 5, guardian: true,
				phases: [
					[{p: "spiral", n: 5, rot: 12, spd: 5.5, life: 2.6, dmg: 70, cd: 0.14, r: 0.22, col: 0x80ff60, shape: "star", eff: "confused"}],
					[{p: "aimed", n: 7, arc: 70, spd: 8, life: 2.0, dmg: 80, cd: 1.0, r: 0.22, col: 0xff60ff, shape: "dart", eff: "slowed"},
						{p: "summon", n: 2, cd: 7, what: "shade"}],
					[{p: "ring", n: 30, rot: 6, spd: 5.5, life: 2.6, dmg: 85, cd: 0.8, r: 0.24, col: 0xd060ff, shape: "orb", eff: "paralyzed"},
						{p: "spiral", n: 2, rot: -21, spd: 7, life: 2.0, dmg: 80, cd: 0.12, r: 0.2, col: 0x80ff60, shape: "star"}]
				]},

			// the Dark Elder is immune while these stand
			elder_crystal: {name: "Elder Crystal", spr: "crystal", hp: 2600, def: 15, spd: 0, xp: 120, ai: "still", r: 0.6, aggro: 16, range: 13, drop: 0, col: 0xff4080, crystal: true,
				attacks: [{p: "spiral", n: 2, rot: 23, spd: 4.5, life: 2.2, dmg: 45, cd: 0.8, r: 0.2, col: 0xff4080, shape: "star"},
					{p: "aimed", n: 1, spd: 9, life: 1.4, dmg: 55, cd: 1.6, r: 0.22, col: 0xffd0e8, shape: "dart"}]},
			// dungeon treasure rooms
			treasure: {name: "Treasure Chest", spr: "chest", hp: 1800, def: 0, spd: 0, xp: 150, ai: "still", r: 0.5, aggro: 0, range: 0, drop: 1, col: 0xf0c030, treasure: true,
				gold: 150, onrane: 3, attacks: []},
			// the Endless Abyss's chests (Data.deepChest), one for each step down
			abyss_chest_1: {name: "Abyssal Chest", spr: "abyss_chest", hp: 600, def: 0, spd: 0, xp: 0, ai: "still", r: 0.6, aggro: 0, range: 0, drop: 1, col: 0xa060ff, treasure: true, abyssChest: 1, attacks: []},
			abyss_chest_2: {name: "Abyssal Chest II", spr: "abyss_chest", hp: 600, def: 0, spd: 0, xp: 0, ai: "still", r: 0.6, aggro: 0, range: 0, drop: 1, col: 0xb070ff, treasure: true, abyssChest: 2, attacks: []},
			abyss_chest_3: {name: "Abyssal Chest III", spr: "abyss_chest", hp: 600, def: 0, spd: 0, xp: 0, ai: "still", r: 0.6, aggro: 0, range: 0, drop: 1, col: 0xc080ff, treasure: true, abyssChest: 3, attacks: []},
			abyss_chest_4: {name: "Abyssal Chest IV", spr: "abyss_chest", hp: 600, def: 0, spd: 0, xp: 0, ai: "still", r: 0.6, aggro: 0, range: 0, drop: 1, col: 0xd080ff, treasure: true, abyssChest: 4, attacks: []},
			abyss_chest_5: {name: "Abyssal Chest V", spr: "abyss_chest", hp: 600, def: 0, spd: 0, xp: 0, ai: "still", r: 0.6, aggro: 0, range: 0, drop: 1, col: 0xe090ff, treasure: true, abyssChest: 5, attacks: []},
			abyss_chest_6: {name: "The Abyss's Hoard", spr: "abyss_chest", hp: 600, def: 0, spd: 0, xp: 0, ai: "still", r: 0.7, aggro: 0, range: 0, drop: 1, col: 0xff80ff, treasure: true, abyssChest: 6, attacks: []}
		};

		// ---- fame bonuses on death (RotMG style) -------------------------------
		/** Bonuses earned by a fallen hero: [{name, desc, pct}]. */
		public static function fameBonuses(p:Player, firstOfClass:Boolean):Array {
			var list:Array = [];
			var add:Function = function(name:String, desc:String, pct:int):void { list.push({name: name, desc: desc, pct: pct}); };
			if (firstOfClass) add("Ancestor", "First " + p.cls.name + " to fall", 10);
			if (p.level >= 20 && p.potsDrunk == 0) add("Thirsty", "Level 20 without stat potions", 10);
			var rare:int = 0;
			for each (var it:Object in [p.weapon, p.ability, p.armor, p.ring]) if (it && it.rarity) rare++;
			if (rare >= 4) add("Well Equipped", "4 Runed or better items equipped", 10);
			if (p.activeSet) add("Set Master", "Died wearing a full set", 5);
			if (p.maxedCount >= 11) add("Fully Maxed", "11/11 stats", 25);
			else if (p.maxedCount >= 8) add("Well Fed", p.maxedCount + "/11 stats", 10);
			if (p.dungeons >= 3) add("Tunnel Rat", "Cleared " + p.dungeons + " dungeons", 10);
			if (p.bossKills >= 6) add("Realm Hero", "Slew " + p.bossKills + " bosses", 10);
			if (p.elders > 0) add("Elder Slayer", "Defeated the Dark Elder", 25);
			if (p.godKills >= 100) add("Godlands Hunter", p.godKills + " Godlands kills", 5);
			if (p.shotsFired >= 500 && p.shotsHit / p.shotsFired >= 0.4) add("Accurate", int(p.shotsHit * 100 / p.shotsFired) + "% of shots hit", 5);
			return list;
		}

		// ---- skins (bought with account fame, RotMG style) --------------------
		public static const SKINS:Object = {
			wizard: [{id: "wizard_frost", name: "Frost Mage", cost: 400, pal: {R: 0x3a7ad4, r: 0x1a4a8a, G: 0xffffff}},
				{id: "wizard_shadow", name: "Shadow Mage", cost: 1000, pal: {R: 0x2a2a34, r: 0x141418, Y: 0xa040ff, G: 0xff40a0}}],
			archer: [{id: "archer_autumn", name: "Autumn Ranger", cost: 400, pal: {G: 0xc06a20, g: 0x8a4410}},
				{id: "archer_shadow", name: "Shadow Ranger", cost: 1000, pal: {G: 0x34343c, g: 0x1c1c22, W: 0xa0a0b0}}],
			knight: [{id: "knight_gold", name: "Golden Knight", cost: 400, pal: {H: 0xf0c840, h: 0xa88a20, M: 0xe0b030, m: 0x9a7818, K: 0x2a5ad0}},
				{id: "knight_dark", name: "Dark Knight", cost: 1000, pal: {H: 0x3a3a44, h: 0x22222a, M: 0x2e2e38, m: 0x18181e, K: 0x7a1010, r: 0x5a0a0a}}],
			priest: [{id: "priest_sun", name: "Sun Priest", cost: 400, pal: {W: 0xfff0b0, w: 0xd8b860, G: 0xff9a20}},
				{id: "priest_dark", name: "Dark Priest", cost: 1000, pal: {W: 0x2a2a34, w: 0x16161c, G: 0xff4040}}],
			rogue: [{id: "rogue_assassin", name: "Assassin", cost: 400, pal: {P: 0x9a1a1a, p: 0x5a0a0a}},
				{id: "rogue_ghost", name: "Ghost", cost: 1000, pal: {P: 0xd8d8e8, p: 0x9a9aa8, K: 0xb8b8c8, k: 0x8a8a9a}}],
			warrior: [{id: "warrior_viking", name: "Viking", cost: 400, pal: {H: 0x8a8a92, h: 0x5a5a62, R: 0x2a5ad0, M: 0x3a6ae0, m: 0x1a3a8a}},
				{id: "warrior_blood", name: "Bloodlord", cost: 1000, pal: {R: 0x5a0a0a, M: 0x8a1010, m: 0x4a0808, Y: 0x2a2a2a}}],
			necromancer: [{id: "necro_lich", name: "Lichlord", cost: 400, pal: {D: 0x2a4a6a, d: 0x142a40, E: 0x60e0ff, K: 0x2a8ad0}},
				{id: "necro_plague", name: "Plague Doctor", cost: 1000, pal: {D: 0x3a5a2a, d: 0x203a14, K: 0x6ad040, E: 0xffe040}}],
			huntress: [{id: "huntress_snow", name: "Snow Huntress", cost: 400, pal: {R: 0xe8f0ff, r: 0xa8b8d0, G: 0x6a8aa8, g: 0x4a6080}},
				{id: "huntress_jungle", name: "Jungle Huntress", cost: 1000, pal: {R: 0x2a8a3a, r: 0x145a20, G: 0xc0a040, g: 0x8a7020}}],
			bard: [{id: "bard_jester", name: "Jester", cost: 600, pal: {V: 0xd0302a, v: 0x8a1a14, H: 0xf0c030, h: 0xa08010}},
				{id: "bard_siren", name: "Siren", cost: 1500, pal: {V: 0x2a9ab0, v: 0x14606e, H: 0xc0f0ff, h: 0x70b0c0, L: 0xe0e8ff}}],
			alchemist: [{id: "alch_plague", name: "Plague Brewer", cost: 600, pal: {A: 0x3a3a34, a: 0x22221e, G: 0x9aff40, M: 0x6a6a5a}},
				{id: "alch_gold", name: "Goldmaker", cost: 1500, pal: {A: 0xa07a20, a: 0x6a4e10, G: 0xffe060, M: 0xfff0b0}}],
			chronomancer: [{id: "chrono_dusk", name: "Dusk Weaver", cost: 600, pal: {T: 0x4a2a7a, t: 0x2a1448, Y: 0xff9ad8}},
				{id: "chrono_aeon", name: "Aeon Warden", cost: 1500, pal: {T: 0xe8e8f0, t: 0xa8a8b8, Y: 0x40e0ff, O: 0x40e0ff}}]
		};

		/** Skin definition by id, with its base class id, or null. */
		public static function findSkin(id:String):Object {
			for (var cls:String in SKINS) {
				for each (var sk:Object in SKINS[cls]) if (sk.id == id) return {base: cls, skin: sk};
			}
			return null;
		}

		// ---- cosmetics: dyes, pet skins and nameplate titles (Fame Store) ---------
		/** Cloth dyes: recolour a hero's robe / tunic / tabard, on any class and any skin. */
		public static const DYES:Array = [
			{id: "dye_crimson", name: "Crimson", cost: 150, col: 0xc82828}, {id: "dye_ocean", name: "Ocean", cost: 150, col: 0x2a6ad8},
			{id: "dye_forest", name: "Forest", cost: 150, col: 0x2e9a3a}, {id: "dye_violet", name: "Violet", cost: 150, col: 0x8a3ad0},
			{id: "dye_sunset", name: "Sunset", cost: 250, col: 0xf07a20}, {id: "dye_rose", name: "Rose", cost: 250, col: 0xf070b0},
			{id: "dye_teal", name: "Teal", cost: 250, col: 0x20b8b0}, {id: "dye_snow", name: "Snow", cost: 400, col: 0xeef2ff},
			{id: "dye_midnight", name: "Midnight", cost: 400, col: 0x30304a}, {id: "dye_gold", name: "Royal Gold", cost: 800, col: 0xf0c030},
			{id: "dye_void", name: "Void", cost: 1500, col: 0x5a10a0}, {id: "dye_ember", name: "Living Ember", cost: 1500, col: 0xff4a10},
			// earned on the season ladder (the server hands these out)
			{id: "dye_laurel", name: "Laurel", earn: "Finish a season in the ladder's top ten", col: 0x8fd16a},
			{id: "dye_champion", name: "Champion's Gold", earn: "Win a season: first place on the ladder", col: 0xffe27a}
		];
		/** Which palette keys a dye recolours, per class: main colour first, then its shade. */
		public static const DYE_KEYS:Object = {
			wizard: ["R", "r"], archer: ["G", "g"], knight: ["K"], priest: ["W", "w"], rogue: ["P", "p"],
			warrior: ["R", "M", "m"], necromancer: ["D", "d"], huntress: ["R", "r"],
			bard: ["V", "v"], alchemist: ["A", "a"], chronomancer: ["T", "t"]
		};
		public static function findDye(id:String):Object {
			for each (var d:Object in DYES) if (d.id == id) return d;
			return null;
		}

		// ---- news: shown once per account after an update (newest first) ---------
		public static const NEWS:Array = [
			{id: "2026-10-effects", title: "Weapon fixes",
				lines: ["<b>Fifteen dungeon weapons had hidden effects</b> left over from the tiered weapons they're built on: wands and daggers threw extra sparks, staves exploded. They're gone. Each weapon now does exactly what its tooltip says.",
					"Affected: <b>Moonlantern, Prismatic, Regent's Scepter, Hexbound, Bonechime</b> (wands), <b>Fang of Ssythra, Imp's Fang, Frostfang, Obsidian Shiv, Kraken's Grasp</b> (daggers), <b>Venomspit, Soulreaper, Cubic, Trident, Cinderfeather</b> (staves). Copies you own are updated, Starforged ones included.",
					"Named weapons no longer show the tiered weapon's shot text (Galecaller's Bow said 5 arrows; it shoots 4).",
					"Fixed outdated lore on Cubic Staff, Regent's Scepter and Hexbound Wand."]},
			{id: "2026-10-trial2", title: "The Starfall Trial's dungeons",
				lines: ["<b>Each Starfall master now has a dungeon of its own</b>, built in its style: no more set pieces rising out of the floor.",
					"<b>Ignis</b>: a lava river with two bridges under fire from magma vents, Cinder Imps and Ash Fiends, lava in the arena's corners.",
					"<b>The Drowned Archivist</b>: a flooded library of shelf-pillars and drowned souls, and an arena whose rim lies under water.",
					"<b>Morvath the Bone Sovereign</b>: a graveyard of Crypt Archers and Bone Thralls, and an ossuary stained with blood.",
					"<b>Astraeon</b>: halls striped with starfire, Comet Wisps and Star Guards, and round his dais a ring of starfire his gravity drags you into.",
					"Each dungeon's guards hold the seal to its master's arena: clear the halls, step into the arena, and the master wakes."]},
			{id: "2026-10-trial", title: "The Starfall Trial",
				lines: ["<b>The Starfall Vault is now a trial</b>: no more halls to walk. You arrive straight in the first of four sealed chambers and its master wakes. Beat it and a portal opens where it fell; step through when you're ready and the next master wakes as you land.",
					"<b>Astraeon, the Fallen Star</b> waits in the last chamber, and he is now the hardest fight in Eldmere: five phases, far more health, and four things nothing else does.",
					"<b>His constellation</b>: stars light up round him, joined by lines of starlight that burn a moment later. Stand between them.",
					"<b>His gravity</b> drags you toward him, and into the ring of starfire round him. <b>The eclipse</b> plunges the throne into darkness lit only by falling stars.",
					"<b>The supernova</b>: when the star collapses, a few pools of starlight open round him. Only those standing in one are spared, and each holds only a player or two. At the very end, he does it all at once.",
					"The weekly twist Swarming Halls is now <b>Swarming Chambers</b>: each master wakes with two guards that hit 15% harder."]},
			{id: "2026-10-storm", title: "Heart of the Storm reworked",
				lines: ["<b>No more stun-locks</b>: once a paralysis wears off you can't be paralyzed again for 3 seconds, and a new hit no longer restarts one. This holds everywhere in the game.",
					"<b>Thunder Sentinels</b> fire a fan of static bolts and <b>overcharge</b>: a rune circle under them, then a burst. Step out of it.",
					"<b>Lightning Rods</b> cast true chain lightning: a marked strike that leaps to anyone standing close. Spread out.",
					"<b>Tempestus</b>: only his Heavy Lightning Strike stuns now, and only the marked bolt itself, not its sparks. His chain lightning and the storm's radius just hurt. Thunder Golems and Heroic's storm eye slow instead of stunning."]},
			{id: "2026-10-ladder", title: "What's new in Eldmere",
				lines: ["<b>One item ladder</b>: above T7 every item is now a named one with fixed stats and a special of its own: <font color='#b070ff'>UT</font>, <font color='#ffd23a'>Legendary</font>, <font color='#8ae8ff'>Starforged</font>, <font color='#ff5533'>Primordial</font> and <font color='#fff6e0'>Godly</font>, each step clearly stronger. No random rolls: the same item every time.",
					"<b>Every boss has its own</b>: the early dungeons three UTs each, the Godlands dungeons three UTs and a Legendary, every realm event a UT and one or two Legendaries, the event dungeons Legendaries. A UT drops 1 in 50 (luck doesn't change it), a Legendary 1 in 100. Over 30 new items, from Swashbuckler's Tunic to the Shardglass Alembic.",
					"<b>Specials</b>: the Prismatic Wand's three colours, the Hexbound Wand's hex (+10% damage from your whole party), Titanbreaker's blades that ignore 15 defense, the Phoenix Quill's fire trail, the Cloak of Mirrors' decoy, a third spirit skull, chain lightning and more.",
					"<b>The Starforge</b> now upgrades a Legendary: it + a Star Shard + 100 Aether = its Starforged self, same name and special, raised to the top of its slot. Armour and rings gain a passive (Tidebound, Lavawalker, Moonwell, Riptide, Last Bastion, Ignite...).",
					"<b>Star Shards</b> drop only from the last boss of a multi-boss dungeon (the Tomb of the Three Kings, the Shattered Sanctum), 1 in 150 for each player. The Marketplace, goblins and mimics no longer have them.",
					"<b>Gone</b>: Runed, Bonded and Eldritch random gear, class sets, rerolls, Fortune's Anvil and random weapon forms. Items you already have keep working. Cursed gear stays, now in green.",
					"<b>Harder</b>: the Sunken Crypt, Ember Depths, Storm Spire and Forgotten Cellar have about 40% more health and hit harder."]},
			{id: "2026-10-itemart", title: "What's new in Eldmere",
				lines: ["<b>Every item redrawn</b>: weapons, armour, abilities, rings, uniques and Godly gear all have new art, built on one set of shapes so they read clearly at a glance: swords with crossguards, daggers hilt-up, wands and staves with glowing orb heads, bows with their strings.",
					"<b>They look like what they're called</b>: Flame weapons burn, Frost ones grow crystals, Void and Shadow ones trail wisps, Star ones glint, Blood and Venom drip. Rusty is rusty, Mithril is pale blue, Bone is bone. The Powder Keg is a keg, the Crowns are crowns, the Trident is a trident.",
					"<b>New shading</b>: light falls on every item from the top-left, with a glint on its blade, gem and gold.",
					"<b>Godly gear</b> is ivory and gold touched with its set's own colour, in a new gold frame."]},
			{id: "2026-10-godlytrim", title: "What's new in Eldmere",
				lines: ["<b>Godly sets toned down</b>: a full Godly set with a maxed skill tree dealt far too much damage. Each piece trades damage stats for Health (stats 16/14/13/12, was 24/20/16/14; +200 Health, was +120), the set bonus gives half the Attack, Dexterity and Might, and with the full set Divine Wrath comes every 5th volley (was every 4th). Pieces you own update by themselves, and Godly still beats Primordial on every piece.",
					"<b>Skill tree</b>: Brutality +2% damage a rank (was 3%), Predator +3% (was 4%), Ferocity +0.05x crit damage (was 0.08x), Apex Predator +15% on boss crits (was 25%).",
					"There are no caps: every point of every stat still counts in full."]},
			{id: "2026-10-outliers", title: "What's new in Eldmere",
				lines: ["<b>Boss fixes</b>: after the big health boost a few bosses went too far, and they're brought back in line.",
					"<b>Realm Siege</b>: Vorgath the Siege Warlord had been given far too much health and hit harder than he should. A full camp of heroes now brings him down in about a quarter of an hour, not most of an hour.",
					"<b>Gentler</b>: the Reef Kraken (slower ink rings, fewer spiral arms, less health), Ignaria Reborn in the Ashen Aerie, the Leviathan and its tentacles in the Kraken's Maw, the Abyssal Herald's last phase, and Glacius's snowflake spiral (no longer slows you).",
					"<b>Quicker</b>: the Tomb of the Three Kings and the Shattered Seraph no longer drag on as long."]},
			{id: "2026-10-realmleaders", title: "What's new in Eldmere",
				lines: ["<b>Realm Leaders</b>: the shrines and the Godlands Spires are gone. Every realm boss your guild helps kill counts for it, and each Monday the guild with the most is crowned Realm Leaders for the week: +15 loot luck and +10% XP for its members, and a Realm Leader title. <b>/leaders</b> shows the race.",
					"<b>Every realm boss has its own lair</b>: they always drop a portal to a dungeon built in their image, with its own way through (shields to break, menders to smash, waves to hold, eggs to break, tentacles that grow back) and its master at the end.",
					"<b>Dungeons with a way of their own</b>: the finales, the old endgame dungeons and the early ones now ask something of you besides the boss: drowned souls to cut down before Nerezza drinks them, Gearmind's cores to break in turn, a phylactery to smash before the Lich King rises again, cocoons hidden in the Forest Maze, and more.",
					"<b>Bosses hit back</b>: boss attacks pierce half your Defense (at least 35% always gets through) and every boss has far more health. Raids were retuned stage by stage.",
					"<b>Heroic raids have rules of their own</b>: Blood Moon in the Conclave, the Eye of the Storm, Falling Stars in the Vault. Heroic's flat boosts are gentler to make room for them.",
					"<b>New look</b>: bosses animate (walking, casting, striking, summoning, raging, dying) and fire shots of their own; realm and dungeon monsters are redrawn to match; raids and dungeons have walls and gates of their own; banners, headings, buttons and panels have a new style.",
					"<b>Smoother</b>: big boss sprites and the HUD no longer slow the game down."]},
			{id: "2026-10-nexus", title: "What's new in Eldmere",
				lines: ["<b>A new Nexus</b>: the Nexus is now a starstone citadel adrift among the stars, with a great star well and its floating shard at its heart, a marble Realm Gate, violet gardens with star trees and ponds, a Treasury and a War Quarter.",
					"<b>Everything is where it was</b>: every portal, merchant and station stands in the same spot, so your way around hasn't changed."]},
			{id: "2026-10-camoffset", title: "What's new in Eldmere",
				lines: ["<b>Camera offset</b>: press <b>C</b> to move your hero down the screen so you can see further ahead, like Realm's \"toggle centering\". Press it again to centre the camera. It works with camera rotation and zoom, and you can rebind it in Menu > Controls."]},
			{id: "2026-10-raidgates", title: "What's new in Eldmere",
				lines: ["<b>Raid gates</b>: raid portals are now great obsidian gates with a swirling vortex, a rune circle turning on the ground and a beam of light into the sky. They rise out of a shockwave when they open (gold for Heroic).",
					"<b>The whole server hears it</b>: when anyone opens a raid, everyone gets the news, wherever they are.",
					"<b>One raid at a time</b>: while a raid's portal is open, or anyone is still fighting in one, no other raid can open. Your key stays in your bag until it can."]},
			{id: "2026-10-bossbalance", title: "What's new in Eldmere",
				lines: ["<b>Boss balance pass</b>: every boss was fought by bots that dodge, and by bots that don't. Now nearly every boss can be beaten without a scratch if you dodge well, and will kill you if you don't.",
					"<b>Easier to read</b>: Astraeon, the Siege Warlord, Archon Vesper, Tempestus, Nerezza, the Void Dragon, Malgoroth, the Skull Shrine and the Shattered Sanctum's wardens fire spirals and fans with real gaps in them, and their blasts give you time to get out.",
					"<b>Harder</b>: Ssythra, Sylith, the Tempest Seraph, the Tide Hermit, Glacius and Morwyn have new attacks, and the raids' Blood Altars and Lightning Rods now fight back.",
					"<b>Confused</b> now works like Realm of the Mad God: up moves you right, right moves you up, down moves you left, left moves you down."]},
			{id: "2026-10-primordial", title: "What's new in Eldmere",
				lines: ["<b>24 new Primordial uniques</b>: now every weapon, armor, ability and ring type has its own Primordial unique. Archon Vesper, Tempestus and Astraeon each carry a set of them.",
					"<b>New wiki page</b>: the Primordial tab shows all of them by item type. Hover one to see its stats and who drops it."]},
			{id: "2026-10-heroes", title: "What's new in Eldmere",
				lines: ["<b>New hero screens</b>: every hero is a card showing its level, stats maxed and the gear it wears, with a tab for each mode.",
					"<b>New Hero</b>: pick a class to see its ability and max stats side by side, then name your hero and press Create (or double-click the class)."]},
			{id: "2026-10-modes", title: "What's new in Eldmere",
				lines: ["<b>A character screen for each mode</b>: Regular, Ironman, Hardcore and Group Ironman heroes each have their own tab. Make new heroes from the tab they belong to.",
					"<b>A vault for each mode</b>: Ironman and Hardcore heroes now have vaults of their own. Items stay in their mode: what your Ironmen find, only your Ironmen use.",
					"<b>Group Ironman</b>: Ironman with up to 4 friends. <b>/group create Name</b>, then <b>/group invite name</b>. Your group trades only with each other and shares a <b>Group Storage</b> chest in the vault. Choose well: friends can join for 7 days, and nobody leaves or is removed.",
					"<b>Tip</b>: type <b>/</b> to start a command straight away."]},
			{id: "2026-10-godly", title: "What's new in Eldmere",
				lines: ["<b>Godly is truly Godly</b>: every drop has the same, best-in-game stats (no bad rolls), weapons hit 35% harder than Primordial, and each set has its own art, shots and a <b>Divine Wrath</b> special attack. Wear Godly for a golden aura; the full set crowns you with a halo.",
					"<b>Every weapon tier has its own shot</b>: new projectiles, trails and impacts, and each tier is a clear step up from the last.",
					"<b>Bosses</b>: the Dark Elder has new survive phases, and Archon Vesper and Nerezza have new looks and attacks.",
					"<b>Quality of life</b>: delete characters from the character screen, a V-Sync setting (off = up to 240 FPS), and big announcement banners from the admins.",
					"<b>Fixed</b>: saves refused with \"was changed\" or \"unknown shot motion\" (this also undid stat potions you drank)."]},
			{id: "2026-10-map", title: "What's new in Eldmere",
				lines: ["<b>A living minimap</b>: every player in your world shows as an arrow pointing the way they're going. Hover one for their name, click to teleport to them (every 10s).",
					"<b>Every class is open</b>: the Bard, Alchemist and Chronomancer can be played straight away, no levels needed.",
					"<b>Account numbers</b>: your account's number is shown on the character screen, and on players you inspect. Use it in /report.",
					"<b>Unfair death?</b> If a hero died to lag or a bug, tell an admin: fallen heroes can now be brought back."]},
			{id: "2026-10-launch", title: "What's new in Eldmere",
				lines: ["<b>Hero modes</b>: make an Ironman or Hardcore hero for more loot luck (pick on the class screen).",
					"<b>Guild Halls</b>: walk into your guild's own hall from the Nexus portal. Shared bank, weekly goals, and a Banner Maker.",
					"<b>Seasons</b>: a new ladder every month. Seasonal heroes score double; the top ten win titles and dyes.",
					"<b>Monster families</b>: goblin daggers come back, slimes split, spiders web the ground, ghosts pass through walls.",
					"<b>Daily rewards</b>: log in each day for gold, more for every day in a row (Aether on day 7)."]}
		];

		// ---- hero modes: picked when a hero is made, kept for its whole life -------
		/**
		 * Regular: the normal game. Ironman: no trading, Marketplace, guild bank or
		 * vault, for more loot luck. Hardcore: Ironman's rules, and gear must be
		 * climbed a tier at a time in each slot (use a T3 before a T4...), for even
		 * more luck and extra stats. The server enforces all of it.
		 */
		public static const MODES:Array = [
			{id: "", name: "Regular", col: 0xd8d8d8, luck: 0, desc: "The game as it is: trade, use the Marketplace, the vault and the guild bank."},
			{id: "ironman", name: "Ironman", tag: "IM", col: 0xb8c4d8, luck: 30,
				desc: "No trading, Marketplace or guild bank: everything your Ironman heroes use, they found. Own vault. +30 loot luck."},
			{id: "hardcore", name: "Hardcore", tag: "HC", col: 0xff5a4a, luck: 60, stats: {hp: 30, mp: 20, att: 5, def: 5, spd: 5, dex: 5, vit: 5, wis: 5},
				desc: "Ironman's rules, and use each tier in a slot before the next (T1, T2, T3...). Own vault. +60 loot luck, +5 every stat."},
			{id: "group", name: "Group Ironman", tag: "GIM", col: 0x7fd8a8, luck: 20,
				desc: "Ironman with up to 4 friends (/group): trade only within your group and share its Group Storage. Own vault. +20 loot luck."}
		];
		/** The modes in the order the character screen shows them, as tabs. */
		public static const MODE_TABS:Array = ["", "ironman", "hardcore", "group"];
		/**
		 * Each mode's heroes have a vault of their own, and items never cross between modes:
		 * the regular vault is save.vault, the others save.vaults[mode] (with save.vaultChestsBy[mode] chests).
		 */
		public static function vaultOf(save:Object, mode:String):Array {
			if (!save) return [];
			if (!mode) return (save.vault as Array) || [];
			return save.vaults && (save.vaults[mode] is Array) ? save.vaults[mode] : [];
		}
		public static function setVault(save:Object, mode:String, items:Array):void {
			if (!mode) { save.vault = items; return; }
			if (!save.vaults || typeof save.vaults != "object") save.vaults = {};
			save.vaults[mode] = items;
		}
		public static function findMode(id:String):Object {
			for each (var m:Object in MODES) if (m.id == (id || "")) return m;
			return MODES[0];
		}
		/** Ironman and Hardcore heroes can't trade, use the Marketplace, the guild bank or the vault. */
		public static function modeRestricted(id:String):Boolean { return id == "ironman" || id == "hardcore" || id == "group"; }
		/** The highest regular tier in each Hardcore slot (abilities stop at T6, rings at T5). */
		public static const CLIMB_TOP:Object = {weapon: 7, ability: 6, armor: 7, ring: 5};
		/** The slot's top regular tier. */
		public static function climbTop(kind:String):int { return CLIMB_TOP[kind] != undefined ? int(CLIMB_TOP[kind]) : 7; }
		/**
		 * An item's tier for Hardcore's climb: its regular tier, and one above its slot's top tier for
		 * anything rarer (uniques, Runed and up), so they open up after the slot's best regular item.
		 */
		public static function climbTier(it:Object):int {
			if (!it) return 0;
			var top:int = climbTop(it.kind);
			if (it.rarity || it.tier == undefined) return top + 1;
			return Math.max(0, Math.min(top, int(it.tier)));
		}
		/** How a climb tier reads: "T5", or "special rarity" past the slot's top tier. */
		public static function climbName(kind:String, t:int):String { return t > climbTop(kind) ? "special rarity" : "T" + t; }
		public static const CLIMB_SLOTS:Array = ["weapon", "ability", "armor", "ring"];

		/** Guild banners, earned by finishing a week's three guild goals (server/guildhall.js); members show their guild's by their name. */
		public static const GUILD_BANNERS:Array = [
			{id: "crimson", name: "Crimson Lion", col: 0xd03030, trim: 0xffd75e},
			{id: "azure", name: "Azure Tide", col: 0x2a6ad8, trim: 0xd8f0ff},
			{id: "emerald", name: "Emerald Oak", col: 0x2e9a3a, trim: 0xe0ffb0},
			{id: "gold", name: "Sunburst", col: 0xf0b020, trim: 0xfff4c0},
			{id: "violet", name: "Violet Star", col: 0x8a3ad0, trim: 0xf0d0ff},
			{id: "obsidian", name: "Obsidian Skull", col: 0x26222e, trim: 0xe04060},
			{id: "frost", name: "Frostfang", col: 0x80d8ff, trim: 0x2050a0},
			{id: "ember", name: "Emberheart", col: 0xff5a20, trim: 0x401008}
		];
		/** A banner by id: an earned one, or a guild's own design ("c:..." from the Banner Maker); null if unknown. */
		public static function findBanner(id:String):Object {
			if (!id) return null;
			for each (var b:Object in GUILD_BANNERS) if (b.id == id) return b;
			var parts:Array = parseBanner(id);
			if (!parts) return null;
			return {id: id, name: "Guild-made banner", col: BANNER_COLORS[parts[0]], trim: BANNER_COLORS[parts[2]], custom: parts};
		}

		// ---- the Banner Maker: guilds design their own banner ---------------------
		// A design is "c:" + background-pattern-patternColour-emblem-emblemColour (indices into the lists below).
		public static const BANNER_COLORS:Array = [0xd03030, 0x8a1a1a, 0xff7a20, 0xf0b020, 0xfff0a0, 0x6ac040, 0x2e7a3a, 0x30c0b0,
			0x80d8ff, 0x2a6ad8, 0x1a2a6a, 0x8a3ad0, 0xf070b0, 0xf4f4f4, 0x8a8a92, 0x1e1a24];
		public static const BANNER_COLOR_NAMES:Array = ["Red", "Wine", "Orange", "Gold", "Cream", "Lime", "Forest", "Teal",
			"Sky", "Blue", "Navy", "Purple", "Pink", "White", "Grey", "Black"];
		public static const BANNER_PATTERNS:Array = ["Plain", "Stripe", "Pale", "Bend", "Chevron", "Cross", "Saltire", "Border",
			"Quartered", "Halves", "Bars", "Chief"];
		public static const BANNER_EMBLEMS:Array = ["None", "Star", "Skull", "Sword", "Crown", "Moon", "Sun", "Tree", "Flame", "Wave", "Shield", "Paw"];
		/** Emblems: 6x6 pictures put in the middle of the 12x10 field (X = emblem colour). */
		private static const EMBLEM_ART:Array = [
			null,
			["..X...", "..X...", "XXXXX.", ".XXX..", ".X.X..", "X...X."],
			[".XXXX.", "XXXXXX", "X.XX.X", "XXXXXX", ".XXXX.", ".X.X.."],
			["....X.", "...X..", "..X...", "XX....", ".X....", "X.X..."],
			["X.X.X.", "XXXXX.", "X.X.X.", "XXXXX.", "XXXXX.", "......"],
			["..XX..", ".X....", "X.....", "X.....", ".X....", "..XX.."],
			["X.X.X.", ".XXX..", "XXXXX.", ".XXX..", "X.X.X.", "......"],
			["..X...", ".XXX..", "XXXXX.", ".XXX..", "..X...", "..X..."],
			["..X...", ".XX...", ".XXX..", "XXXXX.", "XX.XX.", ".XXX.."],
			["......", ".X..X.", "X.XX.X", "......", ".X..X.", "X.XX.X"],
			["XXXXX.", "X.X.X.", "XXXXX.", "X.X.X.", ".XXX..", "..X..."],
			["X.X.X.", "......", ".XXX..", "XXXXX.", "XXXXX.", ".X.X.."]
		];
		public static const BANNER_W:int = 12, BANNER_H:int = 10;

		/** A Banner Maker design's parts [bg, pattern, pattern colour, emblem, emblem colour], or null if it isn't one. */
		public static function parseBanner(id:String):Array {
			if (!id || id.substr(0, 2) != "c:") return null;
			var bits:Array = id.substr(2).split("-");
			if (bits.length != 5) return null;
			var lim:Array = [BANNER_COLORS.length, BANNER_PATTERNS.length, BANNER_COLORS.length, BANNER_EMBLEMS.length, BANNER_COLORS.length];
			var out:Array = [];
			for (var i:int = 0; i < 5; i++) {
				if (!/^[0-9]{1,2}$/.test(bits[i])) return null;
				var n:int = int(bits[i]);
				if (n < 0 || n >= lim[i]) return null;
				out.push(n);
			}
			return out;
		}

		public static function bannerCode(parts:Array):String { return "c:" + parts.join("-"); }

		/** The colour of cell (x, y) of a design's 12x10 field. */
		public static function bannerCell(parts:Array, x:int, y:int):uint {
			var em:Array = EMBLEM_ART[parts[3]];
			if (em) {
				var ex:int = x - 3, ey:int = y - 2;
				if (ex >= 0 && ey >= 0 && ex < 6 && ey < 6 && String(em[ey]).charAt(ex) == "X") return BANNER_COLORS[parts[4]];
			}
			var on:Boolean = false;
			switch (parts[1]) {
				case 1: on = y >= 4 && y <= 5; break;
				case 2: on = x >= 5 && x <= 6; break;
				case 3: on = Math.abs(x - y * 1.2) < 1.6; break;
				case 4: on = Math.abs(y - (9 - Math.abs(x - 5.5) * 0.9)) < 1.2; break;
				case 5: on = (y >= 4 && y <= 5) || (x >= 5 && x <= 6); break;
				case 6: on = Math.abs(x - y * 1.2) < 1.3 || Math.abs((11 - x) - y * 1.2) < 1.3; break;
				case 7: on = x == 0 || y == 0 || x == BANNER_W - 1 || y == BANNER_H - 1; break;
				case 8: on = (x < 6) != (y < 5); break;
				case 9: on = x >= 6; break;
				case 10: on = y % 3 == 1; break;
				case 11: on = y <= 2; break;
			}
			return BANNER_COLORS[on ? parts[2] : parts[0]];
		}

		/** Pet skins: a colour wash over any pet species. */
		public static const PET_SKINS:Array = [
			{id: "pskin_golden", name: "Golden", cost: 600, col: 0xf0c030}, {id: "pskin_frost", name: "Frost", cost: 600, col: 0x80d8ff},
			{id: "pskin_shadow", name: "Shadow", cost: 1200, col: 0x3a2a5a}, {id: "pskin_ember", name: "Ember", cost: 1200, col: 0xff5a20},
			{id: "pskin_spectral", name: "Spectral", cost: 2500, col: 0x70ffd0}
		];
		public static function findPetSkin(id:String):Object {
			for each (var d:Object in PET_SKINS) if (d.id == id) return d;
			return null;
		}

		/** Nameplate titles: bought with fame, or earned (the server hands those out). */
		public static const TITLES:Array = [
			{id: "t_bold", name: "the Bold", cost: 500}, {id: "t_wanderer", name: "the Wanderer", cost: 500},
			{id: "t_lucky", name: "the Lucky", cost: 800}, {id: "t_starborn", name: "Starborn", cost: 2000},
			{id: "t_unbroken", name: "the Unbroken", cost: 5000}, {id: "t_eternal", name: "the Eternal", cost: 12000},
			{id: "record", name: "Record Holder", earn: "Hold the #1 time for any realm event on the Records board", col: 0xffd75e},
			{id: "vault", name: "Vault Breaker", earn: "Defeat Astraeon at the end of the Starfall Vault", col: 0xfff0a0},
			{id: "conclave", name: "Bloodbreaker", earn: "Defeat Archon Vesper at the end of the Crimson Conclave", col: 0xff3050},
			{id: "storm", name: "Stormrider", earn: "Defeat Tempestus at the heart of the storm", col: 0x80ffff},
			{id: "heroic", name: "the Heroic", earn: "Clear any raid on Heroic", col: 0xffb040},
			{id: "heroic_all", name: "Raid Conqueror", earn: "Clear all three raids on Heroic", col: 0xff7040},
			{id: "raidrecord", name: "Raid Record Holder", earn: "The fastest clear of a raid in a week (on its weekly board)", col: 0xffe27a},
			{id: "elder", name: "Elderbane", earn: "Defeat the Dark Elder", col: 0xff5060},
			{id: "siege", name: "Siegebreaker", earn: "Be the MVP (most damage) when a Realm Siege's Warlord falls", col: 0xffa020},
			{id: "deep10", name: "the Abyssal", earn: "Clear wave 10 of the Endless Abyss", col: 0xa060ff},
			{id: "deep25", name: "Voidwalker", earn: "Clear wave 25 of the Endless Abyss", col: 0xd080ff},
			{id: "deepking", name: "Abyss Champion", earn: "Reach the highest wave of your class in the Endless Abyss in a week", col: 0xff60ff},
			{id: "realmlord", name: "Realm Leader", earn: "Be in the guild crowned Realm Leaders (the most realm bosses slain in a week)", col: 0xffd75e},
			{id: "spirelord", name: "Lord of the Godlands", earn: "Held the old Godlands Spires longest in a week (no longer earned)", col: 0x7fd8ff},
			{id: "siegeguard", name: "Realm Defender", earn: "Help beat back a Realm Siege", col: 0xd09060},
			{id: "merchant", name: "Merchant Prince", earn: "Sell 10 items on the Marketplace", col: 0x6fe08f},
			{id: "questor", name: "Questmaster", earn: "Claim 4 weekly quests", col: 0xf0d080},
			{id: "twistbreaker", name: "Twistbreaker", earn: "A top-5 Starfall Vault clear on its weekly twist board", col: 0x80e0ff},
			{id: "season_top10", name: "Ladder Elite", earn: "Finish a season in the ladder's top ten", col: 0x8fd16a},
			{id: "season_podium", name: "Season Medallist", earn: "Finish a season in the ladder's top three", col: 0xc0e8ff},
			{id: "season_champion", name: "Season Champion", earn: "Win a season: first place on the ladder", col: 0xffe27a},
			{id: "oracle5", name: "Oracle's Favoured", earn: "Complete 5 boss collections in the Oracle", col: 0xb9a9ff},
			{id: "oracleall", name: "the All-Seeing", earn: "Complete every boss collection in the Oracle", col: 0xe0d0ff}
		];
		/** Short names for the "<boss> Slayer" titles earned with a top-5 Records time. */
		public static const SLAYER:Object = {
			ev_cube: "Cube Crusher", ev_titan: "Titanslayer", ev_wyrm: "Wyrmslayer", ev_king: "Kingslayer", ev_behemoth: "Behemoth Hunter",
			ev_regent: "Regent's Bane", ev_sphinx: "Riddle Breaker", ev_lord: "Tidebreaker", ev_hermit: "Hermit Hunter", ev_shrine: "Shrine Breaker",
			ev_colossus: "Colossus Toppler", ev_phoenix: "Phoenix Slayer", ev_witch: "Witch Hunter", ev_kraken: "Kraken Slayer"
		};
		// ---- Oracle collections: every unique a boss drops, found -> a title and +1 to a stat for every hero
		/** The unique items that make up a boss's collection (the zealot pair share one). */
		public static function bossUniques(id:String):Array {
			var d:Object = ENEMIES[id];
			if (!d || !d.uniques) return [];
			var ids:Array = d.uniques.concat();
			if (id == "zealot_a" && ENEMIES.zealot_b && ENEMIES.zealot_b.uniques) ids = ids.concat(ENEMIES.zealot_b.uniques);
			return ids;
		}
		/** The stat a boss's collection raises (the same for everyone). */
		public static function oracleStat(id:String):String {
			var h:int = 0;
			for (var i:int = 0; i < id.length; i++) h = (h * 31 + id.charCodeAt(i)) & 0xffff;
			return STATS[h % STATS.length];
		}
		/** What completed collections (boss ids) add to every hero: {stat: amount}; HP and MP get 5 a collection. */
		public static function oracleBonus(done:Array, asc:Object = null):Object {
			var out:Object = {};
			// (and the Ascension tree's stats)
			if (asc) { var ast:Object = ascStats(asc); for (var ak:String in ast) if (ast[ak]) out[ak] = ast[ak]; }
			for each (var id:String in done || []) {
				var s:String = oracleStat(id);
				out[s] = (out[s] || 0) + (s == "hp" || s == "mp" ? 5 : 1);
			}
			return out;
		}
		public static const ORACLE_TITLES:Array = [[5, "oracle5"], [0, "oracleall"]];

		// ---- Ascension: a maxed hero starts again at level 1 (gear kept) for a point in the account's tree
		/** The tree (Save.data.asc = {pts, r: {id: rank}}, the server's): every perk is for every hero. */
		public static const ASC_PERKS:Array = [
			{id: "wisdom", name: "Ascendant Wisdom", desc: "+4% XP", max: 5, col: 0x80e0ff},
			{id: "fortune", name: "Ascendant Fortune", desc: "+3 loot luck", max: 5, col: 0xffd040},
			{id: "wealth", name: "Ascendant Wealth", desc: "+5% gold from monsters", max: 5, col: 0xf0c030},
			{id: "bond", name: "Ascendant Bond", desc: "+8% pet XP", max: 5, col: 0x60f0a0},
			{id: "vigor", name: "Ascendant Vigor", desc: "+10 max HP", max: 5, col: 0xff6a6a},
			{id: "might", name: "Ascendant Might", desc: "+1 Attack", max: 5, col: 0xff9a50}
		];
		/** Aura colours by how many times a hero has ascended (1, 2, 3, 4+: prismatic). */
		public static const ASC_AURAS:Array = [0, 0xcd7f32, 0xd8e0f0, 0xffd75e, 0xff60ff];
		public static function ascRank(asc:Object, id:String):int { return asc && asc.r ? Math.max(0, int(asc.r[id] || 0)) : 0; }
		/** Stats the tree adds to every hero. */
		public static function ascStats(asc:Object):Object { return {hp: ascRank(asc, "vigor") * 10, att: ascRank(asc, "might")}; }
		/** Can this hero (a save entry or Player) ascend: level 20 and every stat at its class's best. */
		public static function canAscend(h:Object):Boolean {
			var cls:Object = CLASSES[typeof h.cls == "string" ? h.cls : h.cls.id];
			if (!cls || int(h.level) < 20 || !h.stats) return false;
			for each (var s:String in STATS) if (Number(h.stats[s]) < cls.max[s] - 0.001) return false;
			return true;
		}

		/** A title by id: {id, name, cost} for bought ones, {id, name, earn, col} for earned ones; null if unknown. */
		public static function findTitle(id:String):Object {
			if (!id) return null;
			for each (var t:Object in TITLES) if (t.id == id) return t;
			if (id.indexOf("oracle_") == 0 && ENEMIES[id.substr(7)]) {
				var bn:String = String(ENEMIES[id.substr(7)].name).split(" ")[0];
				if (bn == "The") bn = String(ENEMIES[id.substr(7)].name).split(" ")[1];
				return {id: id, name: bn + "'s Chosen", earn: "Find every unique drop of " + ENEMIES[id.substr(7)].name + " (the Oracle)", col: 0xb9a9ff};
			}
			if (id.indexOf("slayer_") == 0 && SLAYER[id.substr(7)]) {
				var ev:String = id.substr(7);
				return {id: id, name: SLAYER[ev], earn: "A top-5 time against " + (ENEMIES[ev] ? ENEMIES[ev].name : ev) + " on the Records board", col: 0xff9a2e};
			}
			return null;
		}
		/** Every title there is, slayer titles included. */
		public static function allTitles():Array {
			var out:Array = TITLES.slice();
			for each (var ev:String in EVENTS) if (SLAYER[ev]) out.push(findTitle("slayer_" + ev));
			return out;
		}

		// ---- pets (account-wide, like RotMG's pet yard) ---------------------------
		public static const PET_SPECIES:Array = [
			{id: "pup", name: "Realm Pup"}, {id: "slime", name: "Jelly"}, {id: "owl", name: "Night Owl"},
			{id: "drake", name: "Ember Drake"}, {id: "wisp", name: "Wisp"}, {id: "golem", name: "Pebble Golem"}
		];
		public static const PET_RARITIES:Object = {
			common: {name: "Common", max: 30, col: 0xe0e0e0},
			rare: {name: "Rare", max: 50, col: 0x40a0ff},
			legendary: {name: "Legendary", max: 70, col: 0xd8e040}
		};
		public static const PET_EGG_PRICE:int = 1000;
		/** Pets grow from the XP you earn fighting: 1 pet XP for every PET_XP_SHARE of yours (at least 1 a kill). */
		public static const PET_XP_SHARE:int = 25;
		public static function petKillXp(xp:Number, asc:Object = null):int { return Math.max(1, Math.round(xp * (1 + ascRank(asc, "bond") * 0.08) / PET_XP_SHARE)); }

		public static function hatchPet():Object {
			var sp:Object = pick(PET_SPECIES);
			var r:Number = Math.random();
			return {species: sp.id, name: sp.name, rarity: r < 0.1 ? "legendary" : r < 0.4 ? "rare" : "common", level: 1, xp: 0};
		}

		public static function petXpNeeded(level:int):int { return 8 + level * 2; }
		/**
		 * Pet evolution: Hatchling, Juvenile, Adult, Ascended. Each stage needs the
		 * pet's level plus Evolution Stones (bosses drop them) and gold, paid at the
		 * Pet Yard (the server evolves it). Commons stop at Adult. At Adult the pet
		 * takes one of its species' two paths for good, and its own look (Sprites.petForm).
		 * Every stage makes it bigger
		 * and stronger and its species skill better; Adults carry 2 items, Ascended 4.
		 */
		public static const PET_STAGES:Array = [
			{name: "Hatchling", lv: 1, stones: 0, gold: 0, mult: 1, scale: 1, bag: 0},
			{name: "Juvenile", lv: 10, stones: 1, gold: 500, mult: 1.25, scale: 1.2, bag: 0},
			{name: "Adult", lv: 25, stones: 2, gold: 2000, mult: 1.6, scale: 1.15, bag: 2},
			{name: "Ascended", lv: 45, stones: 4, gold: 6000, mult: 2.1, scale: 1.3, bag: 4}
		];
		/** Each species' skill, and its two Adult paths: a = the skill grows, b = it fights harder. */
		public static const PET_SKILLS:Object = {
			pup: {skill: "Fetch", desc: "Brings you health and magic potions from loot bags nearby",
				a: {name: "Treasure Hound", desc: "Fetches from much further away, stat potions too (into your inventory)"},
				b: {name: "Warhound", desc: "+40% damage and it shoots faster"}},
			slime: {skill: "Split", desc: "Fires one more blob a volley at every stage",
				a: {name: "Royal Jelly", desc: "Heals twice as much"},
				b: {name: "Acid Ooze", desc: "+40% damage and its blobs eat through Defense"}},
			owl: {skill: "Night Sight", desc: "Lights up the map around you, wider at every stage",
				a: {name: "Seer", desc: "+5 loot luck a stage and the widest sight"},
				b: {name: "Hunter Owl", desc: "+40% damage and it shoots from further away"}},
			drake: {skill: "Fire Breath", desc: "+15% damage at every stage",
				a: {name: "Inferno Wyrm", desc: "+60% damage"},
				b: {name: "Ash Guardian", desc: "Shields you: +4 Defense a stage"}},
			wisp: {skill: "Mana Spring", desc: "Restores half again as much MP at every stage",
				a: {name: "Arcane Wisp", desc: "Restores twice the MP and heals half again as much"},
				b: {name: "Storm Wisp", desc: "+40% damage and two bolts at once"}},
			golem: {skill: "Stone Guard", desc: "+3 Defense for you at every stage",
				a: {name: "Bastion", desc: "+6 Defense a stage and heals half again as much"},
				b: {name: "Boulder", desc: "+50% damage"}}
		};
		public static function petStage(pet:Object):int { return pet ? Math.max(0, Math.min(3, int(pet.stage || 0))) : 0; }
		/** Commons stop at Adult; Rare and Legendary pets can ascend. */
		public static function petMaxStage(pet:Object):int { return pet && pet.rarity == "common" ? 2 : 3; }
		public static function petPath(pet:Object):String { return pet && petStage(pet) >= 2 && (pet.path == "a" || pet.path == "b") ? pet.path : ""; }
		/** Items the pet carries (its bag). */
		public static function petBagSlots(pet:Object):int { return pet ? PET_STAGES[petStage(pet)].bag : 0; }
		/** Why the pet can't evolve now (null when it can, given stones and gold). */
		public static function petEvolveBlock(pet:Object):String {
			if (!pet) return "You have no pet.";
			var st:int = petStage(pet);
			if (st >= petMaxStage(pet)) return st >= 3 ? "It has reached its final form." : "Common pets stop at Adult. Rare and Legendary pets can ascend.";
			var next:Object = PET_STAGES[st + 1];
			if (int(pet.level) < next.lv) return "It needs to reach level " + next.lv + " first.";
			return null;
		}
		private static function petMult(pet:Object):Number {
			var m:Number = PET_STAGES[petStage(pet)].mult;
			// legendaries that ascend shine brightest
			if (pet.rarity == "legendary" && petStage(pet) >= 3) m *= 1.15;
			return m;
		}
		/** HP and MP the pet heals every 3 seconds. */
		public static function petHeal(pet:Object):int {
			var p:String = petPath(pet), sp:String = pet.species;
			var k:Number = (sp == "slime" && p == "a") ? 2 : ((sp == "wisp" || sp == "golem") && p == "a") ? 1.5 : 1;
			return int((4 + pet.level * 1.2) * petMult(pet) * k);
		}
		public static function petMagic(pet:Object):int {
			var k:Number = 1;
			if (pet.species == "wisp") k = 1 + petStage(pet) * 0.5 + (petPath(pet) == "a" ? 1 : 0);
			return int((1 + pet.level * 0.4) * petMult(pet) * k);
		}
		/** Damage of each of the pet's shots (pets shoot the nearest monster about once a second). */
		public static function petAttack(pet:Object):int {
			var mul:Number = pet.rarity == "legendary" ? 1.3 : pet.rarity == "rare" ? 1.15 : 1;
			var p:String = petPath(pet), sp:String = pet.species;
			if (sp == "drake") mul *= 1 + petStage(pet) * 0.15 + (p == "a" ? 0.6 : 0);
			else if (p == "b") mul *= sp == "golem" ? 1.5 : 1.4;
			return int((8 + pet.level * 2.2) * mul * petMult(pet));
		}
		/** Shots a volley (Split, Storm Wisp). */
		public static function petShots(pet:Object):int {
			if (pet.species == "slime") return 1 + petStage(pet);
			return pet.species == "wisp" && petPath(pet) == "b" ? 2 : 1;
		}
		/** Seconds between volleys. */
		public static function petShotGap(pet:Object):Number { return pet.species == "pup" && petPath(pet) == "b" ? 0.7 : 1; }
		/** How far it shoots (tiles). */
		public static function petRange(pet:Object):Number { return pet.species == "owl" && petPath(pet) == "b" ? 9.5 : 7; }
		/** Defense the pet gives you (Stone Guard, Bastion, Ash Guardian). */
		public static function petDef(pet:Object):int {
			if (!pet) return 0;
			var st:int = petStage(pet), p:String = petPath(pet);
			if (pet.species == "golem") return st * (p == "a" ? 6 : 3);
			if (pet.species == "drake" && p == "b") return st * 4;
			return 0;
		}
		/** Extra loot luck (Seer). */
		public static function petLuck(pet:Object):int { return pet && pet.species == "owl" && petPath(pet) == "a" ? petStage(pet) * 5 : 0; }
		/** The pet's name for its stage and path ("Adult Warhound"). */
		public static function petTitle(pet:Object):String {
			var p:String = petPath(pet);
			var sk:Object = PET_SKILLS[pet.species];
			return PET_STAGES[petStage(pet)].name + " " + (p && sk ? sk[p].name : pet.name);
		}
		/** How each kind of pet shoots: [projectile shape, colour]. */
		public static const PET_SHOTS:Object = {pup: ["orb", 0xffd080], slime: ["orb", 0x60ff60], owl: ["dart", 0xc0a0ff],
			drake: ["fire", 0xff7020], wisp: ["star", 0x80e0ff], golem: ["orb", 0xb0a090]};

		/** Which enemies spawn in each biome (repeats make a monster more common). */
		public static const ZONE_SPAWNS:Array = [
			["pirate", "pirate", "pirate_brawler", "snake", "scorpion", "crab", "slime", "pirate_captain"],
			["goblin", "goblin", "hobbit", "bandit", "wolf", "green_slime", "goblin_chief", "bandit_leader"],
			["orc", "orc", "gazer", "spider", "spider", "great_snake", "spider_queen", "orc_king"],
			["golem", "harpy", "dwarf", "dwarf", "elf", "ogre", "minotaur", "dwarf_king"],
			["medusa", "djinn", "ent", "beholder", "lich", "ghost_god", "demon", "sprite_god", "slime_god"]
		];
		public static const ZONE_NAMES:Array = ["Beach", "Lowlands", "Midlands", "Highlands", "Godlands", "Nexus", "Dark Elder's Chamber", "Dungeon", "", "Safe Haven"];
		/** Gear tier dropped by ordinary monsters in each biome. */
		public static const ZONE_TIER:Array = [0, 2, 3, 5, 6];
		/** The world: the isle of Eldmere. Each realm is one of its regions. */
		public static const WORLD_NAME:String = "Eldmere";
		public static const REALM_NAMES:Array = ["Ashveil", "Thornwick", "Glimmerfen", "Duskhollow", "Brineholt", "Stormreach", "Mirewood", "Emberfall",
			"Frostgate", "Sunspire", "Wraithmoor", "Ironvale", "Starhaven", "Mosscairn", "Grimtide"];

		/**
		 * Realm landmarks, several of each per realm. Walking up to one wakes its
		 * band; killing the leader clears it for a bonus loot bag.
		 * Tiles: -1 keep, 1 sand, 5 plaza, 6 brick, 16 road, 18 ruin.
		 * Scenery: 3 palm, 4 rock, 5 boulder, 6 dead tree, 7 brazier, 8 pillar,
		 * 9 ruin wall, 10 tent, 11 grave, 12 campfire, 13 totem.
		 */
		public static const SITES:Array = [
			{id: "cove", name: "Smugglers' Cove", zone: 0, r: 6, boss: "pirate_captain", guards: ["pirate", "pirate_brawler", "pirate"], n: 6, color: 0xffd070,
				floor: 1, inner: -1, wall: 3, wallChance: 0.35, prop: 10, propChance: 0.03, centre: 12},
			{id: "bandits", name: "Bandit Camp", zone: 1, r: 7, boss: "bandit_leader", guards: ["bandit", "bandit", "wolf"], n: 7, color: 0xd08a50,
				floor: -1, inner: 16, wall: 4, wallChance: 0.25, prop: 10, propChance: 0.05, centre: 12},
			{id: "warren", name: "Goblin Warren", zone: 1, r: 6, boss: "goblin_chief", guards: ["goblin", "goblin", "green_slime"], n: 7, color: 0x9cd060,
				floor: -1, inner: 1, wall: 13, wallChance: 0.12, prop: 5, propChance: 0.03, centre: 13},
			{id: "grove", name: "Spider Grove", zone: 2, r: 7, boss: "spider_queen", guards: ["spider", "spider", "great_snake"], n: 8, color: 0xe0c020,
				floor: -1, inner: -1, wall: 6, wallChance: 0.45, prop: 6, propChance: 0.04, centre: 0},
			{id: "warcamp", name: "Orc Warcamp", zone: 2, r: 8, boss: "orc_king", guards: ["orc", "orc", "gazer"], n: 8, color: 0x60b060,
				floor: 16, inner: -1, wall: 9, wallChance: 0.5, prop: 10, propChance: 0.04, centre: 12},
			{id: "hall", name: "Dwarven Hall", zone: 3, r: 8, boss: "dwarf_king", guards: ["dwarf", "dwarf", "golem"], n: 8, color: 0xf0c030,
				floor: 18, inner: 5, wall: 9, wallChance: 0.45, prop: 0, propChance: 0, centre: 7, pillars: 8},
			{id: "den", name: "Ogre Den", zone: 3, r: 7, boss: "minotaur", guards: ["ogre", "harpy", "harpy"], n: 7, color: 0xa08a5a,
				floor: -1, inner: 1, wall: 5, wallChance: 0.4, prop: 4, propChance: 0.04, centre: 12},
			{id: "temple", name: "Fallen Temple", zone: 4, r: 8, boss: "demon", guards: ["djinn", "medusa", "beholder"], n: 8, color: 0xff6060,
				floor: 18, inner: 6, wall: 9, wallChance: 0.4, prop: 0, propChance: 0, centre: 7, pillars: 8},
			{id: "barrow", name: "Lich's Barrow", zone: 4, r: 7, boss: "lich", guards: ["ghost_god", "ghost_god", "beholder"], n: 8, color: 0xa070ff,
				floor: -1, inner: 18, wall: 9, wallChance: 0.3, prop: 11, propChance: 0.12, centre: 7}
		];

		/** Realm events; each realm needs EVENTS_PER_REALM of them killed. */
		public static const EVENTS:Array = ["ev_cube", "ev_titan", "ev_wyrm", "ev_king", "ev_behemoth", "ev_regent", "ev_sphinx", "ev_lord", "ev_hermit", "ev_shrine"];
		public static const EVENTS_PER_REALM:int = 8;
		public static const OVERLORD:String = "Azrakor the Dark Elder";
		/** Where the Dark Elder's four crystals rise in his third phase (from his home, plus 7 tiles down). */
		public static const ELDER_CRYSTALS:Array = [[-8, -5], [8, -5], [-8, 5], [8, 5]];

		/**
		 * Dungeons. Event bosses drop the endgame ones; realm monsters drop
		 * their own (`portal` on the enemy). tier: mob strength and loot, 0 (beach) .. 4 (godlands).
		 */
		public static const DUNGEONS:Array = [
			{id: "crypt", hard: 1.4, wall: "crypt", layout: "cave", hazard: "water", dark: true, name: "Sunken Crypt", color: 0x6ad0ff, floor: 9, accent: 4, tier: 4, mobs: ["skeleton", "skeleton", "shade", "gazer"], boss: "warden"},
			{id: "depths", hard: 1.4, wall: "basalt", layout: "cave", hazard: "lava", name: "Ember Depths", color: 0xff6020, floor: 6, accent: 7, tier: 4, mobs: ["imp", "imp", "orc", "goblin"], boss: "pyrelord"},
			{id: "spire", hard: 1.4, wall: "pale", layout: "islands", name: "Storm Spire", color: 0xf0e040, floor: 13, accent: 14, tier: 4, mobs: ["djinn", "elf", "elf", "hobbit"], boss: "seraph"},
			{id: "cellar", hard: 1.4, layout: "grid", dark: true, name: "Forgotten Cellar", color: 0x6090ff, floor: 4, accent: 9, tier: 4, mobs: ["bandit", "hobbit", "gazer", "elf"], boss: "sorcerer"},
			{id: "pirate_cove", wall: "driftwood", layout: "cave", hazard: "water", name: "Pirate Cove", color: 0xe0b060, floor: 1, accent: 16, tier: 0, small: true, mobs: ["pirate", "pirate", "pirate_brawler", "scorpion"], boss: "cove_boss"},
			{id: "forest_maze", wall: "roots", layout: "maze", name: "Forest Maze", color: 0x40c040, floor: 2, accent: 3, tier: 1, small: true, mobs: ["green_slime", "wolf", "goblin", "hobbit"], boss: "moth_boss"},
			{id: "snake_pit", wall: "mossy", layout: "ring", hazard: "water", name: "Snake Pit", color: 0x60d060, floor: 6, accent: 1, tier: 2, mobs: ["great_snake", "snake", "great_snake", "spider"], boss: "serpent_boss"},
			{id: "spider_den", wall: "roots", layout: "maze", dark: true, name: "Spider Den", color: 0xd0c040, floor: 3, accent: 4, tier: 2, mobs: ["spider", "spider", "spider", "great_snake"], boss: "spider_boss"},
			{id: "undead_lair", wall: "bone", layout: "grid", dark: true, name: "Undead Lair", color: 0x9ab0d0, floor: 4, accent: 6, tier: 4, mobs: ["skeleton", "ghost", "shade", "skeleton"], boss: "lich_boss"},
			{id: "abyss", wall: "hellstone", layout: "islands", hazard: "lava", name: "Abyss of Demons", color: 0xff3020, floor: 6, accent: 7, tier: 4, mobs: ["imp", "lesser_demon", "imp", "lesser_demon"], boss: "demon_boss"},
			// ---- hard multi-boss dungeons: elite monsters (hard = health/damage multiplier)
			{id: "tomb", wall: "sandstone", layout: "grid", name: "Tomb of the Three Kings", color: 0xffc040, floor: 1, accent: 6, tier: 4, hard: 1.5,
				mobs: ["scorpion", "great_snake", "lesser_demon", "ghost"], trio: ["sun_king", "moon_queen", "star_prince"]},
			{id: "sanctum", wall: "blush", layout: "ring", name: "The Shattered Sanctum", color: 0xff80d0, floor: 13, accent: 5, tier: 4, hard: 1.6,
				mobs: ["sprite", "ghost", "lich", "djinn"], guardians: ["frost_warden", "flame_warden"], boss: "shattered_seraph"},
			{id: "citadel", wall: "voidstone", name: "Azrakor's Citadel", color: 0xc060ff, floor: 9, accent: 14, tier: 4, hard: 1.7,
				mobs: ["shade", "lesser_demon", "skeleton", "lich"], guardians: ["blood_knight", "hex_queen"], toElder: true},
			{id: "sprite_world", wall: "coral_pastel", layout: "islands", name: "Sprite World", color: 0xff80d0, floor: 13, accent: 5, tier: 4, mobs: ["sprite", "sprite", "sprite_god", "sprite"], boss: "sprite_boss"}
		];
		// ---- The Endless Abyss (/abyss): a wave arena for level 20 heroes (world key "deep:seed").
		// Its monsters drop nothing; every DEEP_CHEST_EVERY waves cleared an Abyssal Chest appears instead,
		// better the further you got (deepChest).
		public static const DEEP_CHEST_EVERY:int = 5;
		/** Every 10th wave the Abyssal Herald comes (with the other boss waves between). */
		public static const DEEP_HERALD:int = 10;
		/** Boss waves (every 5th): dungeon masters first, the hard dungeons' bosses from wave 25; the Herald on every 10th. */
		public static const DEEP_BOSSES:Array = ["warden", "pyrelord", "spider_boss", "seraph", "lich_boss", "serpent_boss", "sorcerer", "demon_boss", "sprite_boss"];
		public static const DEEP_BOSSES_LATE:Array = ["sun_king", "moon_queen", "star_prince", "frost_warden", "flame_warden", "blood_knight", "hex_queen", "shattered_seraph"];
		/** The monsters of a wave, by how deep it is (a new, nastier mix every 4 waves). */
		public static const DEEP_MOBS:Array = [
			["shade", "gazer", "lesser_demon", "ghost", "orc", "imp"],
			["lich", "djinn", "elf", "lesser_demon", "shade", "great_snake"],
			["lich", "sprite_god", "lesser_demon", "ghost", "djinn"],
			["gale_harpy", "bone_thrall", "blood_hound", "lich", "sprite_god"],
			["gale_harpy", "bone_thrall", "blood_hound", "thunder_golem", "cloud_serpent"]
		];
		public static function deepMobs(wave:int):Array { return DEEP_MOBS[Math.min(DEEP_MOBS.length - 1, int((wave - 1) / 4))]; }
		/** How many monsters come in wave n for this many players (before its modifiers; a boss wave brings fewer). */
		public static function deepCount(wave:int, players:int = 1):int {
			var n:Number = Math.min(30, 5 + wave * 1.6) * (1 + 0.5 * (Math.max(1, players) - 1));
			return int(n) - (wave % DEEP_CHEST_EVERY == 0 ? 5 : 0);
		}
		/** The bosses of wave n (none for an ordinary wave; two at once from wave 20). */
		public static function deepBosses(wave:int):Array {
			if (wave % DEEP_CHEST_EVERY != 0) return [];
			var k:int = int(wave / DEEP_CHEST_EVERY);
			var pool:Array = wave >= 25 ? DEEP_BOSSES_LATE : DEEP_BOSSES;
			var out:Array = [wave % DEEP_HERALD == 0 ? "abyss_herald" : pool[k % pool.length]];
			if (wave >= 20) out.push(pool[(k * 3 + 1) % pool.length]);
			return out;
		}
		/** (the first boss of wave n, or null) */
		public static function deepBoss(wave:int):String { var b:Array = deepBosses(wave); return b.length ? b[0] : null; }
		/** How much tougher wave n's monsters are: [health, damage]. */
		public static function deepScale(wave:int):Array {
			var f:int = Math.max(0, wave - 1);
			return [1 + 0.22 * f + 0.004 * f * f, 1 + 0.08 * f];
		}
		/** The chance any monster of wave n comes as an elite. */
		public static function deepEliteChance(wave:int):Number { return Math.min(0.45, 0.02 * wave); }
		/** A wave left too long: after this many seconds the Abyss grows restless and sends elites. */
		public static const DEEP_RESTLESS:int = 40;
		/** Wave modifiers (one from wave 2, two from 11, three from 21; the server rolls them). */
		public static const DEEP_MODS:Array = [
			{id: "swarm", name: "Swarm", desc: "Twice as many monsters, weaker each", col: 0x80ff80},
			{id: "elite", name: "Elite Pack", desc: "Many of them are elites", col: 0xffd040},
			{id: "frenzy", name: "Frenzy", desc: "Faster and they hit harder", col: 0xff6040},
			{id: "giants", name: "Juggernauts", desc: "Fewer, but all giants", col: 0xc08060},
			{id: "blood", name: "Bloodthirst", desc: "Monsters regenerate", col: 0xff3060},
			{id: "split", name: "Splitters", desc: "Monsters split when they die", col: 0x60e0a0},
			{id: "reinforce", name: "Reinforcements", desc: "The wave comes in three pulses", col: 0x80b0ff},
			{id: "ambush", name: "Ambush", desc: "They appear right beside you", col: 0xd080ff}
		];
		public static function findDeepMod(id:String):Object {
			for each (var m:Object in DEEP_MODS) if (m.id == id) return m;
			return null;
		}
		/** How many modifiers wave n has. */
		public static function deepModCount(wave:int):int { return wave < 2 ? 0 : wave < 11 ? 1 : wave < 21 ? 2 : 3; }
		/** The chest after wave n is cleared (1 at wave 5 .. 6 from wave 30). */
		public static function deepChestTier(wave:int):int { return Math.max(1, Math.min(6, int(wave / DEEP_CHEST_EVERY))); }
		public static const DEEP_CHEST_NAMES:Array = ["", "Abyssal Chest", "Abyssal Chest II", "Abyssal Chest III", "Abyssal Chest IV", "Abyssal Chest V", "The Abyss's Hoard"];
		/** What each chest can give (the Abyss window lists it). */
		public static const DEEP_CHEST_INFO:Array = ["",
			"Wave 5: stat potions and a tier 6 item",
			"Wave 10: more potions, a tier 7 item, a chance at runes and Evolution Stones",
			"Wave 15: two tier 7 items, runes, stones, a small chance at an Abyss unique",
			"Wave 20: three tier 7 items, a better chance at an Abyss unique",
			"Wave 25: three tier 7 items, a good chance at an Abyss unique",
			"Wave 30+: the Hoard: three tier 7 items, a coin flip for an Abyss unique"];
		/** The Abyss's own uniques: only its chests have them. */
		public static const DEEP_UNIQUES:Array = ["voidrend", "abyssal_crown", "depthstone"];
		/** A chest's loot for one player (every player who opens it rolls their own). */
		public static function deepChest(tier:int, cls:Object, lk:int):Array {
			var items:Array = [];
			var rare:Number = 1 + lk / 100;
			var lc:Object = lootClass(cls);
			for (var p:int = 0; p < [0, 2, 3, 4, 5, 6, 8][tier]; p++) items.push(makePotion("stat", randomStat()));
			if (tier == 1) items.push(makeForSlot(lc, int(Math.random() * 4), 6, null));
			else if (tier == 2) items.push(makeForSlot(lc, int(Math.random() * 4), 7, null));
			else for (var k:int = 0; k < Math.min(3, tier - 1); k++) items.push(makeForSlot(lc, int(Math.random() * 4), 7, null));
			if (tier >= 2 && Math.random() < 0.1 + 0.08 * tier) items.push(makeStone());
			var uc:Number = [0, 0, 0, 0.05, 0.12, 0.25, 0.5][tier] * rare;
			if (Math.random() < uc) items.push(Uniques.make(DEEP_UNIQUES[int(Math.random() * DEEP_UNIQUES.length)]));
			items.push(makePotion("hp"));
			items.push(makePotion("mp"));
			return items;
		}
		/** Boons: after each boss wave everyone picks one of three; they last for the run. */
		public static const DEEP_BOONS:Array = [
			{id: "might", name: "Abyssal Might", desc: "+4 Attack", st: {att: 4}, col: 0xff6a50},
			{id: "haste", name: "Quickened", desc: "+5 Speed", st: {spd: 5}, col: 0x80ffa0},
			{id: "dex", name: "Steady Hand", desc: "+5 Dexterity", st: {dex: 5}, col: 0xffd040},
			{id: "guard", name: "Stoneskin", desc: "+5 Defense", st: {def: 5}, col: 0xb0b0c0},
			{id: "life", name: "Deep Vigor", desc: "+60 max HP", st: {hp: 60}, col: 0xff4060},
			{id: "mind", name: "Void Mind", desc: "+40 max MP, +3 Wisdom", st: {mp: 40, wis: 3}, col: 0x6080ff},
			{id: "mend", name: "Regrowth", desc: "+5 Vitality", st: {vit: 5}, col: 0x60e060},
			{id: "greed", name: "Greed", desc: "+15 loot luck", luck: 15, col: 0xf0c030}
		];
		public static function findBoon(id:String):Object {
			for each (var b:Object in DEEP_BOONS) if (b.id == id) return b;
			return null;
		}
		/** The stats a run's boons add. */
		public static function deepBonus(boons:Array):Object {
			var out:Object = {};
			for each (var id:String in boons || []) {
				var b:Object = findBoon(id);
				if (b && b.st) for (var k:String in b.st) out[k] = (out[k] || 0) + b.st[k];
			}
			return out;
		}
		/** Loot luck from a run's boons. */
		public static function deepBoonLuck(boons:Array):int {
			var n:int = 0;
			for each (var id:String in boons || []) { var b:Object = findBoon(id); if (b && b.luck) n += b.luck; }
			return n;
		}

		/** The first 4 dungeons are the ones realm events drop. */
		public static const EVENT_DUNGEONS:int = 4;

		public static function dungeonIndex(id:String):int {
			for (var i:int = 0; i < DUNGEONS.length; i++) if (DUNGEONS[i].id == id) return i;
			return -1;
		}
		public static const DUNGEON_DROP_CHANCE:Number = 0.7;

		/**
		 * Skill tree: five branches (constellations), each four tiers deep. A tier
		 * opens once enough points are spent in its branch (SKILL_TIER_REQ), and
		 * the better the skill the more each rank costs (SKILL_COSTS by tier; the
		 * capstones set their own). Capstones also need level 20. You get a point
		 * per level, then at level 20 one per skillPointXp(n) XP, which grows with
		 * every point earned that way. The server counts points the same way
		 * (skillSpent), so a changed game can't spend more than it has.
		 */
		public static const SKILL_BRANCHES:Array = [
			{name: "Might", col: 0xff6a50, desc: "Damage and critical hits"},
			{name: "Guard", col: 0x60a8ff, desc: "Health, defense and survival"},
			{name: "Fortune", col: 0xffd040, desc: "Loot, luck and gambling"},
			{name: "Arcana", col: 0xc080ff, desc: "Mana and abilities"},
			{name: "Hunt", col: 0x6ae08a, desc: "Speed, aim and the big prey"}
		];
		/** Points per rank by tier (0-2); capstones (tier 3) use their own cost. */
		public static const SKILL_COSTS:Array = [1, 2, 3, 6];
		/** Points spent in the branch before a tier opens. */
		public static const SKILL_TIER_REQ:Array = [0, 4, 12, 22];
		public static const SKILLS:Array = [
			// ---- Might
			{id: "brutality", b: 0, t: 0, name: "Brutality", desc: "+2% damage", max: 5},
			{id: "precision", b: 0, t: 0, name: "Precision", desc: "+2% crit chance", max: 5},
			{id: "ferocity", b: 0, t: 1, name: "Ferocity", desc: "+0.05x crit damage", max: 5},
			{id: "honed", b: 0, t: 1, name: "Honed Edge", desc: "+2 Attack", max: 5},
			{id: "executioner", b: 0, t: 2, name: "Executioner", desc: "+8% damage to monsters under 30% HP", max: 3},
			{id: "overwhelm", b: 0, t: 2, name: "Overwhelm", desc: "+2 Might", max: 3},
			{id: "bloodlust", b: 0, t: 3, name: "Bloodlust", desc: "Every kill gives +6% damage for 5s, stacking up to 5 times", max: 1, cap: true, cost: 6},
			// ---- Guard
			{id: "vigor", b: 1, t: 0, name: "Vigor", desc: "+40 max HP", max: 5},
			{id: "bulwark", b: 1, t: 0, name: "Bulwark", desc: "+4 Defense", max: 5},
			{id: "aegis", b: 1, t: 1, name: "Aegis", desc: "+5 Warding", max: 5},
			{id: "leech", b: 1, t: 1, name: "Leech", desc: "+1 HP per hit", max: 5},
			{id: "stoneskin", b: 1, t: 2, name: "Stoneskin", desc: "+3 Defense and +25 max HP", max: 3},
			{id: "secondwind", b: 1, t: 2, name: "Second Wind", desc: "Health potions heal 25% more", max: 3},
			{id: "laststand", b: 1, t: 3, name: "Last Stand", desc: "Once every 3 minutes, a killing blow leaves you at 1 HP and untouchable for 2s instead", max: 1, cap: true, cost: 6},
			// ---- Fortune
			{id: "fortune", b: 2, t: 0, name: "Prosperity", desc: "+5 Luck (better loot)", max: 5},
			{id: "luckystar", b: 2, t: 0, name: "Lucky Star", desc: "+4 Luck", max: 5},
			{id: "scavenger", b: 2, t: 1, name: "Scavenger", desc: "+8% gold from monsters", max: 3},
			{id: "favor", b: 2, t: 1, name: "Fortune's Favor", desc: "+3 Focus and +3 Luck", max: 5},
			{id: "treasure", b: 2, t: 2, name: "Treasure Hunter", desc: "+8 Luck", max: 3},
			{id: "goldrush", b: 2, t: 2, name: "Gold Rush", desc: "+10% gold from monsters", max: 3},
			{id: "highstakes", b: 2, t: 3, name: "High Stakes", desc: "Every loot bag: 50% doubled, 50% gone. Toggle it any time.", max: 1, cap: true, cost: 5},
			// ---- Arcana
			{id: "manafont", b: 3, t: 0, name: "Mana Font", desc: "+30 max MP (Arcane Surge turns it into damage)", max: 5},
			{id: "insight", b: 3, t: 0, name: "Insight", desc: "+3 Wisdom", max: 5},
			{id: "arcane", b: 3, t: 1, name: "Arcane Flow", desc: "-6% ability MP cost", max: 5},
			{id: "channeling", b: 3, t: 1, name: "Channeling", desc: "Abilities recharge 4% faster", max: 5},
			{id: "overflow", b: 3, t: 2, name: "Overflow", desc: "+4 Wisdom and +20 max MP", max: 3},
			{id: "clarity", b: 3, t: 2, name: "Clarity", desc: "+3 MP for every kill, and +3% damage while above 75% MP", max: 3},
			{id: "arcanesurge", b: 3, t: 3, name: "Arcane Surge", desc: "+1% damage for every 20 max MP (up to +30%), and every 4th ability cast costs no MP", max: 1, cap: true, cost: 6},
			// ---- Hunt
			{id: "swiftness", b: 4, t: 0, name: "Swiftness", desc: "+4 Speed", max: 5},
			{id: "keeneye", b: 4, t: 0, name: "Keen Eye", desc: "+3 Dexterity", max: 5},
			{id: "predator", b: 4, t: 1, name: "Predator", desc: "+3% damage to bosses", max: 5},
			{id: "relentless", b: 4, t: 1, name: "Relentless", desc: "+2 Dexterity and +2 Speed", max: 5},
			{id: "ambush", b: 4, t: 2, name: "Ambush", desc: "+10% damage to monsters at full health", max: 3},
			{id: "tenacity", b: 4, t: 2, name: "Tenacity", desc: "+4 Vitality", max: 3},
			{id: "apex", b: 4, t: 3, name: "Apex Predator", desc: "Critical hits on bosses deal +15% more", max: 1, cap: true, cost: 6}
		];
		public static const SKILL_STATS:Object = {vigor: {hp: 40}, bulwark: {def: 4}, aegis: {prt: 5}, swiftness: {spd: 4}, fortune: {frt: 5},
			honed: {att: 2}, overwhelm: {mgt: 2}, stoneskin: {def: 3, hp: 25}, luckystar: {luc: 4}, favor: {luc: 3, frt: 3}, treasure: {frt: 8},
			manafont: {mp: 30}, insight: {wis: 3}, overflow: {wis: 4, mp: 20}, keeneye: {dex: 3}, relentless: {dex: 2, spd: 2}, tenacity: {vit: 4}};

		public static function skill(id:String):Object {
			for each (var s:Object in SKILLS) if (s.id == id) return s;
			return null;
		}

		/** Points one rank of this skill costs. */
		public static function skillCost(sk:Object):int { return sk.cost ? int(sk.cost) : int(SKILL_COSTS[int(sk.t)]); }

		/** Points spent on these skills ({id: ranks}); in branch b only, if b >= 0. Unknown ids cost 1 a rank. */
		public static function skillSpent(skills:Object, b:int = -1):int {
			var n:int = 0;
			if (!skills) return 0;
			for (var id:String in skills) {
				var r:int = Math.max(0, int(skills[id]));
				var sk:Object = skill(id);
				if (b >= 0 && (!sk || sk.b != b)) continue;
				n += r * (sk ? skillCost(sk) : 1);
			}
			return n;
		}

		public static const XP_PER_SKILL_POINT:int = 1000;
		/** XP for the next level-20 skill point after already earning n of them. */
		public static function skillPointXp(n:int):int { return XP_PER_SKILL_POINT + Math.max(0, n) * 300; }

		/**
		 * Daily quests: 3 are picked each day (UTC), the same for everyone. ev is what
		 * counts toward it (the server counts these from its own kills, so they can't be
		 * faked); {boss} is filled in with the day's event boss.
		 */
		public static const QUESTS:Array = [
			{id: "kills", ev: "kills", text: "Slay 80 monsters", goal: 80, gold: 300, onrane: 0},
			{id: "godkills", ev: "godkills", text: "Slay 30 Godlands monsters", goal: 30, gold: 0, onrane: 3},
			{id: "events", ev: "events", text: "Defeat 2 realm event bosses", goal: 2, gold: 500, onrane: 2},
			{id: "boss", ev: "event", text: "Defeat {boss}", goal: 1, gold: 600, onrane: 3},
			{id: "pieces", ev: "pieces", text: "Break 8 set-piece wards, menders or hazards", goal: 8, gold: 400, onrane: 2},
			{id: "fast", ev: "fastevent", text: "Defeat an event boss in under 90 seconds", goal: 1, gold: 700, onrane: 4},
			{id: "elites", ev: "elites", text: "Slay 5 elite monsters", goal: 5, gold: 400, onrane: 2},
			{id: "dungeon", ev: "dungeon", text: "Clear a dungeon", goal: 1, gold: 200, onrane: 4},
			{id: "elder", ev: "elder", text: "Defeat the Dark Elder", goal: 1, gold: 1000, onrane: 8}
		];
		/** Weekly quests: one a week (weeks start on Monday, UTC), with a bigger reward. */
		public static const WEEKLY_QUESTS:Array = [
			{id: "w_events", ev: "events", text: "Defeat 15 realm event bosses", goal: 15, gold: 3000, onrane: 15},
			{id: "w_party", ev: "partyevent", text: "Defeat 6 event bosses with at least one other player", goal: 6, gold: 2500, onrane: 15},
			{id: "w_record", ev: "record", text: "Set a top-5 time on the Records board", goal: 1, gold: 3000, onrane: 20},
			{id: "w_dungeons", ev: "dungeon", text: "Clear 8 dungeons", goal: 8, gold: 2500, onrane: 20},
			{id: "w_pieces", ev: "pieces", text: "Break 40 set-piece wards, menders or hazards", goal: 40, gold: 2500, onrane: 15}
		];

		/** A number from a text, then a simple random sequence from it (the same on the server). */
		private static function questSeed(key:String):Number {
			var h:Number = 7;
			for (var i:int = 0; i < key.length; i++) h = (h * 31 + key.charCodeAt(i)) % 2147483647;
			return h || 1;
		}
		private static function questNext(h:Number):Number { return (h * 16807) % 2147483647; }

		/** The day's 3 quests for everyone: [{id, arg}] (arg: the event boss for "Defeat {boss}"). */
		public static function dailyQuests(day:String):Array {
			var h:Number = questSeed("d" + day);
			var pool:Array = QUESTS.concat(), out:Array = [];
			for (var k:int = 0; k < 3; k++) {
				h = questNext(h);
				var q:Object = pool.splice(int(h % pool.length), 1)[0];
				var arg:String = "";
				if (q.ev == "event") { h = questNext(h); arg = EVENTS[int(h % EVENTS.length)]; }
				out.push({id: q.id, arg: arg});
			}
			return out;
		}

		/** The week's quest: {id, arg}. */
		public static function weeklyQuest(week:String):Object {
			var h:Number = questNext(questSeed("w" + week));
			return {id: WEEKLY_QUESTS[int(h % WEEKLY_QUESTS.length)].id, arg: ""};
		}

		/** A quest's wording, with the day's boss filled in. */
		public static function questText(q:Object, arg:String):String {
			var t:String = q.text;
			if (t.indexOf("{boss}") >= 0) t = t.split("{boss}").join(arg && ENEMIES[arg] ? ENEMIES[arg].name : "the day's event boss");
			return t;
		}

		/** Account achievements: counted from the same events as quests, rewarded once. */
		public static const ACHIEVEMENTS:Array = [
			{id: "first_blood", ev: "kills", goal: 1, name: "First Blood", desc: "Slay a monster", gold: 50, onrane: 0},
			{id: "slayer", ev: "kills", goal: 1000, name: "Slayer", desc: "Slay 1,000 monsters", gold: 1000, onrane: 2},
			{id: "exterminator", ev: "kills", goal: 10000, name: "Exterminator", desc: "Slay 10,000 monsters", gold: 5000, onrane: 20},
			{id: "god_hunter", ev: "godkills", goal: 500, name: "God Hunter", desc: "Slay 500 Godlands monsters", gold: 1500, onrane: 5},
			{id: "event_1", ev: "events", goal: 1, name: "Event Horizon", desc: "Defeat a realm event boss", gold: 300, onrane: 1},
			{id: "event_25", ev: "events", goal: 25, name: "Champion of the Realm", desc: "Defeat 25 realm event bosses", gold: 2500, onrane: 10},
			{id: "dungeon_1", ev: "dungeon", goal: 1, name: "Delver", desc: "Clear a dungeon", gold: 300, onrane: 2},
			{id: "dungeon_20", ev: "dungeon", goal: 20, name: "Dungeon Master", desc: "Clear 20 dungeons", gold: 3000, onrane: 15},
			{id: "treasure", ev: "treasure", goal: 5, name: "Treasure Hunter", desc: "Open 5 treasure chests", gold: 1000, onrane: 3},
			{id: "elder_1", ev: "elder", goal: 1, name: "Elder Slayer", desc: "Defeat the Dark Elder", gold: 2000, onrane: 10},
			{id: "elder_10", ev: "elder", goal: 10, name: "Bane of Azrakor", desc: "Defeat the Dark Elder 10 times", gold: 10000, onrane: 40},
			{id: "legend", ev: "level20", goal: 1, name: "Legend", desc: "Reach level 20", gold: 500, onrane: 0},
			{id: "maxed", ev: "maxed", goal: 1, name: "Perfection", desc: "Max all 11 stats on a character", gold: 5000, onrane: 20},
			{id: "lucky", ev: "rare", goal: 50, name: "Lucky", desc: "Find 50 purple-or-better loot bags", gold: 1500, onrane: 5},
			{id: "legendary", ev: "legendary", goal: 1, name: "Shining Light", desc: "Obtain a Starforged or Primordial item", gold: 1000, onrane: 5},
			{id: "pet", ev: "pet", goal: 1, name: "Best Friend", desc: "Hatch a pet", gold: 200, onrane: 0}
		];

		public static function quest(id:String):Object {
			for each (var q:Object in QUESTS) if (q.id == id) return q;
			for each (q in WEEKLY_QUESTS) if (q.id == id) return q;
			return null;
		}

		// ---- loot -------------------------------------------------------
		/** fortune: % loot boost from gear (Fortune stat). */
		/**
		 * Gear drops for every class, like RotMG: half the time it's for your own
		 * class, otherwise for any class (to trade, store or sell).
		 */
		private static function lootClass(cls:Object):Object {
			if (Math.random() < 0.5) return cls;
			return CLASSES[CLASS_ORDER[int(Math.random() * CLASS_ORDER.length)]];
		}

		/** The class of the character looking at tooltips (kept up to date by the game). */
		public static var viewerClass:String = "";

		/** Class names that can equip an item (every class for rings). */
		public static function usableBy(item:Object):Array {
			var out:Array = [];
			for each (var id:String in CLASS_ORDER) if (canUse(item, id)) out.push(CLASSES[id].name);
			return out;
		}

		public static function canUse(item:Object, clsId:String):Boolean {
			var c:Object = CLASSES[clsId];
			if (!item || !c) return true;
			switch (item.kind) {
				case "weapon": return item.sub == c.weapon;
				case "ability": return item.sub == c.abilityType;
				case "armor": return item.sub == c.armor;
			}
			return true;
		}

		/** A boss's own unique items: each one rolls separately. */
		private static function rollUniques(def:Object, items:Array, boost:Number):void {
			if (!def.uniques) return;
			// the item ladder's bosses: each item rolled on its own, a UT 1 in 50 whatever your luck, a Legendary
			// 1 in 100 that luck can nudge (rare is at most +40%)
			if (def.planned) {
				for each (var pid:String in def.uniques) {
					var pr:String = Uniques.rarityOf(pid);
					if (Math.random() < Uniques.CHANCE[pr] * (pr == "ut" ? 1 : boost)) items.push(Uniques.make(pid));
				}
				return;
			}
			// late-game items are meant to be hunted for (each unique the boss carries rolls on its own)
			var c:Number = def.uchance || (def.raid ? 0.07 : def.final || def.finale ? 0.07 : def.dtier >= 5 ? 0.05 : def.dungeon ? 0.035 : 0.025);
			for each (var id:String in def.uniques) if (Math.random() < c * boost) items.push(Uniques.make(id));
		}

		public static function rollLoot(def:Object, zone:int, cls:Object, fortune:int):Array {
			// (the Endless Abyss's chests have their own tables)
			if (def.abyssChest) return deepChest(def.abyssChest, cls, fortune);
			var items:Array = [];
			var boost:Number = 1 + fortune / 100;
			// luck helps a lot with ordinary drops but only a little with the rarest ones (at most +40%)
			var rare:Number = 1 + Math.min(160, Math.max(0, fortune)) / 400;
			var slot:int;
			rollUniques(def, items, rare);
			Godly.roll(def, items, rare);
			rollKey(def, items, boost);
			var ex:Array = bossExtras(def);
			if (Math.random() < ex[0] * rare) items.push(makeStone());
			// cursed gear: a bit rarer than runes
			if (Math.random() < ex[1] * 0.35 * rare) items.push(makeCursed(lootClass(cls)));
			if (def.raid) {
				// raid bosses: the best loot in the game
				// (named gear only from its own list above: the rest is top-tier gear)
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, null));
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, null));
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				return items;
			}
			if (def.final || def.finale) {
				// the Dark Elder: fabled gear, a shot at legendaries and relics
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, null));
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, null));
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				return items;
			}
			if (def.treasure) {
				// treasure room chest: a coin flip for a Bonded piece for your class (else top-tier gear), plus potions
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, null));
				for (var tp:int = 0; tp < 3; tp++) items.push(makePotion("stat", randomStat()));
				items.push(makePotion("hp"));
				items.push(makePotion("mp"));
				return items;
			}
			if (def.dungeon && def.dtier >= 5) {
				// hard multi-boss dungeons: the best loot outside the Dark Elder
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, null));
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, null));
				for (var hp2:int = 0; hp2 < 3; hp2++) items.push(makePotion("stat", randomStat()));
				return items;
			}
			if (def.dungeon && def.dtier != undefined && def.dtier < 3) {
				// low-level dungeon boss: good tiered gear, a shot at a Runed item
				var dt:int = def.dtier;
				for (var di:int = 0; di < 2; di++) {
					slot = int(Math.random() * 4);
					items.push(slot == 3 ? makeRing(randomStat(), Math.min(5, 2 + dt)) : makeForSlot(lootClass(cls), slot, 3 + dt + (Math.random() < 0.3 ? 1 : 0), null));
				}
				if (dt >= 1 && Math.random() < 0.5) items.push(makePotion("stat", randomStat()));
				if (dt >= 2) items.push(makePotion("stat", randomStat()));
				items.push(makePotion("hp"));
				return items;
			}
			if (def.dungeon) {
				// (Bonded gear is earned: a good chance, not a sure thing; else strong tiered gear)
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), Math.random() < 0.5 ? 7 : 6, null));
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				return items;
			}
			if (def.ai == "boss") {
				// realm event: Runed or Bonded piece, sometimes Starforged
				slot = int(Math.random() * 4);
				items.push(makeForSlot(lootClass(cls), slot, Math.random() < 0.3 ? 7 : 6, null));
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("hp"));
				return items;
			}
			if (def.drop <= 0) return items;
			if (Math.random() < 0.14) items.push(makePotion("hp"));
			if (Math.random() < 0.09) items.push(makePotion("mp"));
			if (Math.random() < def.drop * boost) {
				var tier:int = ZONE_TIER[Math.min(4, zone)] + (Math.random() < 0.35 ? 1 : 0) + (Math.random() < 0.06 ? 1 : 0);
				if (tier > 7) tier = 7;
				var roll:Number = Math.random();
				var lc:Object = lootClass(cls);
				if (roll < 0.4) items.push(makeWeapon(lc.weapon, tier, null, ""));
				else if (roll < 0.55) items.push(makeAbility(lc.abilityType, Math.min(6, tier), null, randomAbility(lc.abilityType)));
				else if (roll < 0.82) items.push(makeArmor(lc.armor, tier));
				else items.push(makeRing(randomStat(), Math.min(5, int(tier * 0.7))));
			}
			var statChance:Number = zone == 4 ? 0.07 : zone == 3 ? 0.03 : zone == 2 ? 0.01 : 0;
			if (Math.random() < statChance * boost) items.push(makePotion("stat", randomStat()));
			return items;
		}

		/** Star Shards' only source: the last boss of a multi-boss dungeon, 1 in 150 for each player there. */
		public static const SHARD_CHANCE:Number = 1 / 150;
		/** Whether this kill can give a Star Shard (kingsLeft: the other kings still standing, for the Tomb). */
		public static function shardKill(def:Object, kingsLeft:int):Boolean {
			return def && def.shard && !(def.trio && kingsLeft > 0);
		}

		public static function randomStat():String {
			return STATS[int(Math.random() * STATS.length)];
		}

		/** Bag colour by best item: brown < purple < cyan < white (UT/ST) < red (FB) < gold (LG) < teal (AR). */
		public static function bagColor(items:Array):String {
			var rank:int = 0;
			for each (var it:Object in items) {
				var r:int = 0;
				if (it.rarity == "gd") r = 7;
				else if (it.rarity == "ar") r = 6;
				else if (it.rarity == "lg" || it.rarity == "sf") r = 5;
				else if (it.rarity == "fb" || it.curse) r = 4;
				else if (it.rarity || it.kind == "key") r = 3;
				else if (it.tier >= 6 || it.kind == "material" || it.kind == "stone" || it.kind == "rune") r = 2;
				else if (it.tier >= 4 || it.kind == "stat" || (it.kind == "ring" && it.tier >= 3)) r = 1;
				if (r > rank) rank = r;
			}
			return ["bag_brown", "bag_purple", "bag_cyan", "bag_white", "bag_fabled", "bag_legendary", "bag_relic", "bag_godly"][rank];
		}
	}
}
