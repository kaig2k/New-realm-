package realm {
	/**
	 * Game balance: classes, enemies, items and loot tables.
	 * New Realm's systems: 11 maxable stats (the classic 8 +
	 * Fury, Focus, Warding), Bounty from gear, and the T0-T7 / RN / BD /
	 * EL / SF / PR item rarities.
	 */
	public class Data {
		public static const STATS:Array = ["hp", "mp", "att", "def", "spd", "dex", "vit", "wis", "mgt", "luc", "prt"];
		/** Stats that only come from gear. */
		public static const GEAR_STATS:Array = ["frt"];
		public static const STAT_NAMES:Object = {hp: "Life", mp: "Mana", att: "Attack", def: "Defense", spd: "Speed", dex: "Dexterity", vit: "Vitality",
			wis: "Wisdom", mgt: "Fury", luc: "Focus", prt: "Warding", frt: "Bounty"};
		public static const STAT_SHORT:Object = {hp: "HP", mp: "MP", att: "ATT", def: "DEF", spd: "SPD", dex: "DEX", vit: "VIT", wis: "WIS",
			mgt: "FUR", luc: "FOC", prt: "WRD", frt: "BNT"};
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
				ability: {name: "Spell", cost: 30, desc: "Ring of 20 bolts at the cursor."}
			},
			archer: {
				id: "archer", name: "Archer", weapon: "bow", armor: "leather", abilityType: "quiver",
				desc: "Piercing arrows from long range. Quiver arrows slow their target.",
				base: {hp: 130, mp: 100, att: 12, def: 0, spd: 12, dex: 12, vit: 12, wis: 10, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 630, mp: 200, att: 42, def: 0, spd: 32, dex: 32, vit: 22, wis: 30, mgt: 12, luc: 12, prt: 4},
				max: {hp: 680, mp: 252, att: 75, def: 25, spd: 50, dex: 50, vit: 40, wis: 50, mgt: 80, luc: 40, prt: 25},
				ability: {name: "Quiver", cost: 25, desc: "Huge piercing arrow that slows."}
			},
			knight: {
				id: "knight", name: "Knight", weapon: "sword", armor: "heavy", abilityType: "shield",
				desc: "The tank. Huge HP and Defense; the Shield stuns everything nearby.",
				base: {hp: 210, mp: 100, att: 15, def: 0, spd: 7, dex: 10, vit: 10, wis: 10, mgt: 5, luc: 2, prt: 4},
				l20: {hp: 710, mp: 200, att: 45, def: 0, spd: 27, dex: 30, vit: 40, wis: 30, mgt: 5, luc: 2, prt: 14},
				max: {hp: 950, mp: 252, att: 50, def: 40, spd: 50, dex: 50, vit: 75, wis: 50, mgt: 50, luc: 35, prt: 40},
				ability: {name: "Shield", cost: 30, desc: "Stuns enemies near you."}
			},
			priest: {
				id: "priest", name: "Priest", weapon: "wand", armor: "robe", abilityType: "tome",
				desc: "Support with real damage. The Tome heals and bursts holy light.",
				base: {hp: 80, mp: 100, att: 15, def: 0, spd: 12, dex: 13, vit: 10, wis: 15, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 580, mp: 300, att: 35, def: 0, spd: 42, dex: 33, vit: 20, wis: 45, mgt: 12, luc: 2, prt: 14},
				max: {hp: 630, mp: 385, att: 65, def: 25, spd: 55, dex: 65, vit: 40, wis: 75, mgt: 50, luc: 70, prt: 60},
				ability: {name: "Tome", cost: 35, desc: "Heal yourself and burst holy light."}
			},
			rogue: {
				id: "rogue", name: "Rogue", weapon: "dagger", armor: "leather", abilityType: "cloak",
				desc: "Fast medium-range daggers. The Cloak turns you invisible.",
				base: {hp: 110, mp: 100, att: 10, def: 0, spd: 15, dex: 15, vit: 15, wis: 13, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 610, mp: 200, att: 30, def: 0, spd: 45, dex: 45, vit: 25, wis: 33, mgt: 22, luc: 22, prt: 4},
				max: {hp: 680, mp: 252, att: 55, def: 25, spd: 75, dex: 75, vit: 40, wis: 55, mgt: 60, luc: 75, prt: 25},
				ability: {name: "Cloak", cost: 30, desc: "Invisible for 3s: enemies lose you."}
			},
			warrior: {
				id: "warrior", name: "Warrior", weapon: "sword", armor: "heavy", abilityType: "helm",
				desc: "Melee bruiser. The Helm sends you berserk: faster attacks and speed.",
				base: {hp: 180, mp: 100, att: 15, def: 0, spd: 7, dex: 10, vit: 10, wis: 10, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 680, mp: 200, att: 45, def: 0, spd: 27, dex: 30, vit: 40, wis: 30, mgt: 2, luc: 2, prt: 4},
				max: {hp: 730, mp: 385, att: 75, def: 25, spd: 50, dex: 50, vit: 75, wis: 50, mgt: 50, luc: 10, prt: 25},
				ability: {name: "Helm", cost: 35, desc: "Berserk for 5s: +50% fire rate, +speed."}
			},
			necromancer: {
				id: "necromancer", name: "Necromancer", weapon: "staff", armor: "robe", abilityType: "skull",
				desc: "Dark caster. The Skull blasts an area and drains life from it.",
				base: {hp: 100, mp: 100, att: 15, def: 0, spd: 12, dex: 12, vit: 10, wis: 15, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 600, mp: 300, att: 45, def: 0, spd: 32, dex: 42, vit: 20, wis: 40, mgt: 12, luc: 12, prt: 4},
				max: {hp: 650, mp: 385, att: 70, def: 25, spd: 50, dex: 60, vit: 40, wis: 75, mgt: 40, luc: 40, prt: 30},
				ability: {name: "Skull", cost: 30, desc: "Area blast at the cursor that heals you."}
			},
			huntress: {
				id: "huntress", name: "Huntress", weapon: "bow", armor: "leather", abilityType: "trap",
				desc: "Archer of the wilds. Traps explode into slowing shards.",
				base: {hp: 130, mp: 100, att: 12, def: 0, spd: 12, dex: 12, vit: 12, wis: 10, mgt: 2, luc: 2, prt: 4},
				l20: {hp: 630, mp: 200, att: 42, def: 0, spd: 32, dex: 32, vit: 22, wis: 30, mgt: 12, luc: 12, prt: 4},
				max: {hp: 680, mp: 252, att: 75, def: 25, spd: 50, dex: 50, vit: 40, wis: 50, mgt: 60, luc: 50, prt: 25},
				ability: {name: "Trap", cost: 25, desc: "Thrown trap bursts into slowing shards."}
			}
		};
		public static const CLASS_ORDER:Array = ["wizard", "archer", "knight", "priest", "rogue", "warrior", "necromancer", "huntress"];

		/** Per-level growth, derived from the level 1 and level 20 stat tables. */
		public static function grow(cls:Object, s:String):Number {
			return (cls.l20[s] - cls.base[s]) / 19;
		}

		// ---- item tiers -------------------------------------------------
		// Tiered items are T0..T7. New Realm's special rarities, from common to rarest:
		// Runed (RN), Bonded (BD, class sets), Eldritch (EL, the Dark Elder), Starforged (SF, forged), Primordial (PR).
		// The short ids (ut, st, fb, lg, ar) are only save-file keys and never shown to players.
		public static const RARITIES:Array = ["ut", "st", "fb", "lg", "ar"];
		public static const RARITY_NAMES:Object = {ut: "Runed", st: "Bonded", fb: "Eldritch", lg: "Starforged", ar: "Primordial"};
		public static const RARITY_LABELS:Object = {ut: "RN", st: "BD", fb: "EL", lg: "SF", ar: "PR"};
		public static const RARITY_COLORS:Object = {ut: 0x6aa8ff, st: 0x4ee08a, fb: 0xc85cff, lg: 0xffc23a, ar: 0xff5533};
		/** Effective tier used for item stats. */
		private static const RARITY_POWER:Object = {ut: 8, st: 8.5, fb: 9.5, lg: 11, ar: 12.5};

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
			trap: ["Snare Trap", "Spike Trap", "Thorn Trap", "Barbed Trap", "Hunter's Trap", "Trap of Vines", "Trap of the Wild"]
		};
		/** Nouns used to name special-rarity items. */
		private static const NOUNS:Object = {staff: "Staff", bow: "Longbow", sword: "Greatsword", wand: "Wand", dagger: "Kris",
			spell: "Grimoire", quiver: "Quiver", shield: "Aegis", tome: "Codex", cloak: "Shroud", helm: "Crown", skull: "Skull", trap: "Snare",
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
			var n:int = rarity == "ut" ? 1 : rarity == "st" ? 1 : rarity == "fb" ? 2 : rarity == "lg" ? 2 : 3;
			var amt:int = rarity == "ut" ? 5 : rarity == "st" ? 6 : rarity == "fb" ? 8 : rarity == "lg" ? 10 : 15;
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
			huntress: {name: "Wildheart's", bonus: {hp: 60, att: 10, dex: 10, spd: 10, luc: 10, frt: 10}}
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
			if (b.frt) parts.push("+" + b.frt + " Bounty");
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
			return Math.random() < 0.5 ? "" : pick(FORM_IDS);
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
					w.spd *= 0.55; w.life *= 1.7; w.pierce = true; mul = 1.35; w.size = (w.size || 3) + 1;
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

		public static function makeAbility(sub:String, tier:int, rarity:String = null):Object {
			var t:Number = rarity ? RARITY_POWER[rarity] : tier;
			var a:Object = {kind: "ability", sub: sub, tier: rarity ? 8 : tier, name: ABILITY_NAMES[sub][Math.min(tier, 6)], power: 1 + t * 0.18};
			return enchant(a, rarity);
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

		public static function makeSor():Object {
			return {kind: "material", sub: "sor", tier: 0, name: "Star Shard"};
		}

		/** Gear for one of a class's 4 slots. */
		public static function makeForSlot(cls:Object, slot:int, tier:int, rarity:String):Object {
			switch (slot) {
				case 0: return classSet(makeWeapon(cls.weapon, tier, rarity, "?"), cls);
				case 1: return classSet(makeAbility(cls.abilityType, tier, rarity), cls);
				case 2: return classSet(makeArmor(cls.armor, tier, rarity), cls);
			}
			return classSet(makeRing(randomStat(), Math.min(5, tier), rarity), cls);
		}

		/** Re-tag a generic set item as a piece of the class's own set. */
		private static function classSet(item:Object, cls:Object):Object {
			if (item.rarity == "st" && SETS[cls.id]) {
				item.set = cls.id;
				item.name = SETS[cls.id].name + " " + (NOUNS[item.sub] || "Relic");
			}
			return item;
		}

		/** Turn an item into a Starforged item of the same kind (Starforge). */
		public static function forgeLegendary(item:Object, cls:Object):Object {
			switch (item.kind) {
				case "weapon": return makeWeapon(item.sub, 7, "lg", item.form || "?");
				case "ability": return makeAbility(item.sub, 6, "lg");
				case "armor": return makeArmor(item.sub, 7, "lg");
				case "ring": return makeRing(item.sub, 5, "lg");
			}
			return item;
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
			return 0xffffff;
		}

		/** Gold value when selling at the marketplace. */
		public static function sellValue(item:Object):int {
			if (!item) return 0;
			if (item.rarity) return {ut: 400, st: 600, fb: 1500, lg: 3000, ar: 8000}[item.rarity];
			switch (item.kind) {
				case "stat": return 250;
				case "material": return 300;
				case "hp": case "mp": return 20;
			}
			return 10 + item.tier * item.tier * 12;
		}

		/** Level used for the numbers in ability tooltips (the game keeps it up to date). */
		public static var viewerLevel:int = 1;

		/** What an ability does, with its numbers at your level. */
		public static function abilityText(item:Object):String {
			var lv:int = viewerLevel, pw:Number = item.power;
			var cost:int = 0;
			for each (var c:Object in CLASSES) if (c.abilityType == item.sub) cost = c.ability.cost;
			var t:String;
			switch (item.sub) {
				case "spell": t = "Fires a ring of 20 bolts where you aim (up to 9 tiles away). Each bolt deals " + int((55 + lv * 7) * pw) + " damage."; break;
				case "quiver": t = "Fires one huge arrow that pierces everything in its path for " + int((100 + lv * 12) * pw) + " damage and slows enemies for 3s."; break;
				case "shield": t = "Stuns enemies within 3.5 tiles for " + (2.5 * Math.sqrt(pw)).toFixed(1) + "s and throws 12 blades around you (" + int((40 + lv * 5) * pw) + " damage each)."; break;
				case "tome": t = "Heals you for " + int((80 + lv * 8) * pw) + " HP and bursts 10 orbs of holy light around you (" + int((30 + lv * 4) * pw) + " damage each). Works in the Nexus too."; break;
				case "cloak": t = "Turns you invisible for " + (3 * Math.sqrt(pw)).toFixed(1) + "s: monsters lose track of you and stop shooting at you."; break;
				case "helm": t = "Sends you berserk for " + (5 * Math.sqrt(pw)).toFixed(1) + "s: +50% fire rate and +25% movement speed."; break;
				case "skull": t = "Blasts a 3-tile area where you aim for " + int((70 + lv * 8) * pw) + " damage and heals you 20 HP plus 15 per enemy hit."; break;
				case "trap": t = "Throws a trap where you aim. It arms, then bursts into slowing shards for " + int((60 + lv * 7) * pw) + " damage."; break;
				default: return "";
			}
			return "<font color='#e8e0a0'>" + t + "</font>\n<font color='#9a9aaa'>Costs " + cost + " MP. Press SPACE to use.</font>";
		}

		/** Tooltip body text (HTML). */
		public static function describe(item:Object):String {
			if (!item) return "";
			var s:String = "";
			if (item.rarity) s += "<font color='" + Ui.hex(RARITY_COLORS[item.rarity]) + "'>" + RARITY_NAMES[item.rarity] + "</font>\n";
			switch (item.kind) {
				case "weapon":
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
				case "material": s += "Crafting material for the Starforge.\nForge: Runed, Bonded or Eldritch item + Star Shard + 100 Aether = Starforged\n"; break;
			}
			if (isGear(item)) {
				var on:String = "";
				for each (var k:String in STATS.concat(GEAR_STATS)) {
					if (item[k]) on += "  +" + item[k] + " " + STAT_NAMES[k] + "\n";
				}
				if (on) s += "On equip:\n" + on;
			}
			if (item.passive) {
				var p:Object = PASSIVES[item.passive];
				s += "<font color='#d8e040'>" + p.name + ":</font> " + p.desc + "\n";
			}
			if (item.uid) s += Uniques.describe(item);
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
			elder: {name: "Azrakor the Dark Elder", spr: "elder", hp: 32000, def: 30, spd: 1.4, xp: 5000, ai: "boss", r: 0.9, aggro: 20, range: 18, drop: 1, col: 0xa040ff,
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
				gold: 150, onrane: 3, attacks: []}
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
				{id: "huntress_jungle", name: "Jungle Huntress", cost: 1000, pal: {R: 0x2a8a3a, r: 0x145a20, G: 0xc0a040, g: 0x8a7020}}]
		};

		/** Skin definition by id, with its base class id, or null. */
		public static function findSkin(id:String):Object {
			for (var cls:String in SKINS) {
				for each (var sk:Object in SKINS[cls]) if (sk.id == id) return {base: cls, skin: sk};
			}
			return null;
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
		public static const PET_FEED_PRICE:int = 200;
		public static const PET_FEED_XP:int = 20;

		public static function hatchPet():Object {
			var sp:Object = pick(PET_SPECIES);
			var r:Number = Math.random();
			return {species: sp.id, name: sp.name, rarity: r < 0.1 ? "legendary" : r < 0.4 ? "rare" : "common", level: 1, xp: 0};
		}

		public static function petXpNeeded(level:int):int { return 8 + level * 2; }
		/** HP and MP the pet heals every 3 seconds. */
		public static function petHeal(pet:Object):int { return int(4 + pet.level * 1.2); }
		public static function petMagic(pet:Object):int { return int(1 + pet.level * 0.4); }

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

		/** Realm events; each realm needs EVENTS_PER_REALM of them killed. */
		public static const EVENTS:Array = ["ev_cube", "ev_titan", "ev_wyrm", "ev_king", "ev_behemoth", "ev_regent", "ev_sphinx", "ev_lord", "ev_hermit", "ev_shrine"];
		public static const EVENTS_PER_REALM:int = 6;
		public static const OVERLORD:String = "Azrakor the Dark Elder";

		/**
		 * Dungeons. Event bosses drop the endgame ones; realm monsters drop
		 * their own (`portal` on the enemy). tier: mob strength and loot, 0 (beach) .. 4 (godlands).
		 */
		public static const DUNGEONS:Array = [
			{id: "crypt", layout: "cave", hazard: "water", dark: true, name: "Sunken Crypt", color: 0x6ad0ff, floor: 9, accent: 4, tier: 4, mobs: ["skeleton", "skeleton", "shade", "gazer"], boss: "warden"},
			{id: "depths", layout: "cave", hazard: "lava", name: "Ember Depths", color: 0xff6020, floor: 6, accent: 7, tier: 4, mobs: ["imp", "imp", "orc", "goblin"], boss: "pyrelord"},
			{id: "spire", layout: "islands", name: "Storm Spire", color: 0xf0e040, floor: 13, accent: 14, tier: 4, mobs: ["djinn", "elf", "elf", "hobbit"], boss: "seraph"},
			{id: "cellar", layout: "grid", dark: true, name: "Forgotten Cellar", color: 0x6090ff, floor: 4, accent: 9, tier: 4, mobs: ["bandit", "hobbit", "gazer", "elf"], boss: "sorcerer"},
			{id: "pirate_cove", layout: "cave", hazard: "water", name: "Pirate Cove", color: 0xe0b060, floor: 1, accent: 16, tier: 0, small: true, mobs: ["pirate", "pirate", "pirate_brawler", "scorpion"], boss: "cove_boss"},
			{id: "forest_maze", layout: "maze", name: "Forest Maze", color: 0x40c040, floor: 2, accent: 3, tier: 1, small: true, mobs: ["green_slime", "wolf", "goblin", "hobbit"], boss: "moth_boss"},
			{id: "snake_pit", layout: "ring", hazard: "water", name: "Snake Pit", color: 0x60d060, floor: 6, accent: 1, tier: 2, mobs: ["great_snake", "snake", "great_snake", "spider"], boss: "serpent_boss"},
			{id: "spider_den", layout: "maze", dark: true, name: "Spider Den", color: 0xd0c040, floor: 3, accent: 4, tier: 2, mobs: ["spider", "spider", "spider", "great_snake"], boss: "spider_boss"},
			{id: "undead_lair", layout: "grid", dark: true, name: "Undead Lair", color: 0x9ab0d0, floor: 4, accent: 6, tier: 4, mobs: ["skeleton", "ghost", "shade", "skeleton"], boss: "lich_boss"},
			{id: "abyss", layout: "islands", hazard: "lava", name: "Abyss of Demons", color: 0xff3020, floor: 6, accent: 7, tier: 4, mobs: ["imp", "lesser_demon", "imp", "lesser_demon"], boss: "demon_boss"},
			// ---- hard multi-boss dungeons: elite monsters (hard = health/damage multiplier)
			{id: "tomb", layout: "grid", name: "Tomb of the Three Kings", color: 0xffc040, floor: 1, accent: 6, tier: 4, hard: 1.5,
				mobs: ["scorpion", "great_snake", "lesser_demon", "ghost"], trio: ["sun_king", "moon_queen", "star_prince"]},
			{id: "sanctum", layout: "ring", name: "The Shattered Sanctum", color: 0xff80d0, floor: 13, accent: 5, tier: 4, hard: 1.6,
				mobs: ["sprite", "ghost", "lich", "djinn"], guardians: ["frost_warden", "flame_warden"], boss: "shattered_seraph"},
			{id: "citadel", name: "Azrakor's Citadel", color: 0xc060ff, floor: 9, accent: 14, tier: 4, hard: 1.7,
				mobs: ["shade", "lesser_demon", "skeleton", "lich"], guardians: ["blood_knight", "hex_queen"], toElder: true},
			{id: "sprite_world", layout: "islands", name: "Sprite World", color: 0xff80d0, floor: 13, accent: 5, tier: 4, mobs: ["sprite", "sprite", "sprite_god", "sprite"], boss: "sprite_boss"}
		];
		/** The first 4 dungeons are the ones realm events drop. */
		public static const EVENT_DUNGEONS:int = 4;

		public static function dungeonIndex(id:String):int {
			for (var i:int = 0; i < DUNGEONS.length; i++) if (DUNGEONS[i].id == id) return i;
			return -1;
		}
		public static const DUNGEON_DROP_CHANCE:Number = 0.7;

		/** Skill tree ("Awakening"): unlocked at level 20 with 11/11 stats. */
		public static const SKILLS:Array = [
			{id: "brutality", name: "Brutality", desc: "+5% damage", max: 5},
			{id: "precision", name: "Precision", desc: "+2% crit chance", max: 5},
			{id: "ferocity", name: "Ferocity", desc: "+0.1x crit damage", max: 5},
			{id: "vigor", name: "Vigor", desc: "+40 max HP", max: 5},
			{id: "bulwark", name: "Bulwark", desc: "+4 Defense", max: 5},
			{id: "aegis", name: "Aegis", desc: "+5 Warding", max: 5},
			{id: "swiftness", name: "Swiftness", desc: "+4 Speed", max: 5},
			{id: "leech", name: "Leech", desc: "+1 HP per hit", max: 5},
			{id: "fortune", name: "Prosperity", desc: "+5 Bounty", max: 5}
		];
		public static const SKILL_STATS:Object = {vigor: {hp: 40}, bulwark: {def: 4}, aegis: {prt: 5}, swiftness: {spd: 4}, fortune: {frt: 5}};
		public static const XP_PER_SKILL_POINT:int = 600;

		/** Daily quests (daily contracts / battle pass missions); 3 are picked per day. */
		public static const QUESTS:Array = [
			{id: "kills", text: "Slay 60 monsters", goal: 60, gold: 300, onrane: 0},
			{id: "godkills", text: "Slay 25 Godlands monsters", goal: 25, gold: 0, onrane: 3},
			{id: "events", text: "Defeat 2 realm event bosses", goal: 2, gold: 500, onrane: 2},
			{id: "dungeon", text: "Clear a dungeon", goal: 1, gold: 200, onrane: 4},
			{id: "pots", text: "Drink 3 stat potions", goal: 3, gold: 400, onrane: 0},
			{id: "rare", text: "Find 2 purple-or-better loot bags", goal: 2, gold: 300, onrane: 1},
			{id: "elder", text: "Defeat the Dark Elder", goal: 1, gold: 1000, onrane: 8}
		];

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
			var c:Number = def.uchance || (def.raid ? 0.3 : def.final || def.finale ? 0.25 : def.dtier >= 5 ? 0.2 : def.dungeon ? 0.16 : 0.12);
			for each (var id:String in def.uniques) if (Math.random() < c * boost) items.push(Uniques.make(id));
		}

		public static function rollLoot(def:Object, zone:int, cls:Object, fortune:int):Array {
			var items:Array = [];
			var boost:Number = 1 + fortune / 100;
			var slot:int;
			rollUniques(def, items, boost);
			if (def.raid) {
				// raid bosses: the best loot in the game
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, Math.random() < 0.5 ? "fb" : "st"));
				if (Math.random() < 0.15 * boost) items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "lg"));
				if (Math.random() < 0.03 * boost) items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "ar"));
				if (Math.random() < 0.2 * boost) items.push(makeSor());
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				return items;
			}
			if (def.final || def.finale) {
				// the Dark Elder: fabled gear, a shot at legendaries and relics
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "fb"));
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "fb"));
				if (Math.random() < 0.3 * boost) items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "lg"));
				if (Math.random() < 0.05 * boost) items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "ar"));
				if (Math.random() < 0.35 * boost) items.push(makeSor());
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				return items;
			}
			if (def.treasure) {
				// treasure room chest: a set piece for your class plus potions
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "st"));
				if (Math.random() < 0.06 * boost) items.push(makeSor());
				for (var tp:int = 0; tp < 3; tp++) items.push(makePotion("stat", randomStat()));
				items.push(makePotion("hp"));
				items.push(makePotion("mp"));
				return items;
			}
			if (def.dungeon && def.dtier >= 5) {
				// hard multi-boss dungeons: the best loot outside the Dark Elder
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "st"));
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, Math.random() < 0.35 ? "fb" : "st"));
				if (Math.random() < (def.sealed ? 0.35 : 0.15) * boost) items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "lg"));
				if (Math.random() < (def.sealed ? 0.06 : 0.02) * boost) items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "ar"));
				if (Math.random() < 0.15 * boost) items.push(makeSor());
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
				items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "st"));
				if (Math.random() < 0.1 * boost) items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "lg"));
				if (Math.random() < 0.06 * boost) items.push(makeSor());
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				return items;
			}
			if (def.ai == "boss") {
				// realm event: Runed or Bonded piece, sometimes Starforged
				slot = int(Math.random() * 4);
				items.push(makeForSlot(lootClass(cls), slot, Math.random() < 0.3 ? 7 : 6, Math.random() < 0.25 ? "st" : null));
				if (Math.random() < 0.08 * boost) items.push(makeForSlot(lootClass(cls), int(Math.random() * 4), 7, "lg"));
				if (Math.random() < 0.05 * boost) items.push(makeSor());
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
				if (roll < 0.4) items.push(makeWeapon(lc.weapon, tier, null, "?"));
				else if (roll < 0.55) items.push(makeAbility(lc.abilityType, Math.min(6, tier)));
				else if (roll < 0.82) items.push(makeArmor(lc.armor, tier));
				else items.push(makeRing(randomStat(), Math.min(5, int(tier * 0.7))));
			}
			var statChance:Number = zone == 4 ? 0.07 : zone == 3 ? 0.03 : zone == 2 ? 0.01 : 0;
			if (Math.random() < statChance * boost) items.push(makePotion("stat", randomStat()));
			return items;
		}

		public static function randomStat():String {
			return STATS[int(Math.random() * STATS.length)];
		}

		/** Bag colour by best item: brown < purple < cyan < white (UT/ST) < red (FB) < gold (LG) < teal (AR). */
		public static function bagColor(items:Array):String {
			var rank:int = 0;
			for each (var it:Object in items) {
				var r:int = 0;
				if (it.rarity == "ar") r = 6;
				else if (it.rarity == "lg") r = 5;
				else if (it.rarity == "fb") r = 4;
				else if (it.rarity) r = 3;
				else if (it.tier >= 6 || it.kind == "material") r = 2;
				else if (it.tier >= 4 || it.kind == "stat" || (it.kind == "ring" && it.tier >= 3)) r = 1;
				if (r > rank) rank = r;
			}
			return ["bag_brown", "bag_purple", "bag_cyan", "bag_white", "bag_fabled", "bag_legendary", "bag_relic"][rank];
		}
	}
}
