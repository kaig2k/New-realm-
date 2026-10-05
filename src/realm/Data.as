package realm {
	/**
	 * Game balance: classes, enemies, items and loot tables.
	 * Modelled on the Valor private server: 11 maxable stats (vanilla 8 +
	 * Might, Luck, Protection), Fortune from gear, and the T / UT / ST /
	 * FB / LG / AR item tiers.
	 */
	public class Data {
		public static const STATS:Array = ["hp", "mp", "att", "def", "spd", "dex", "vit", "wis", "mgt", "luc", "prt"];
		/** Stats that only come from gear. */
		public static const GEAR_STATS:Array = ["frt"];
		public static const STAT_NAMES:Object = {hp: "Life", mp: "Mana", att: "Attack", def: "Defense", spd: "Speed", dex: "Dexterity", vit: "Vitality",
			wis: "Wisdom", mgt: "Might", luc: "Luck", prt: "Protection", frt: "Fortune"};
		public static const STAT_SHORT:Object = {hp: "HP", mp: "MP", att: "ATT", def: "DEF", spd: "SPD", dex: "DEX", vit: "VIT", wis: "WIS",
			mgt: "MGT", luc: "LUC", prt: "PRT", frt: "FRT"};
		public static const STAT_COLORS:Object = {hp: 0xff70b0, mp: 0x5080ff, att: 0xa040e0, def: 0x303030, spd: 0x40c040, dex: 0xff9020, vit: 0xd02020,
			wis: 0x40e0e0, mgt: 0xff5a2a, luc: 0x3ae07a, prt: 0xe8e8f0, frt: 0xf0c030};

		// base = level 1, l20 = level 20, max = "11/11" caps (numbers from the Valor wiki)
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
		// Tiered items are T0..T7. Special rarities (Valor): UT, ST (set), FB (fabled), LG (legendary), AR (ancient relic).
		public static const RARITIES:Array = ["ut", "st", "fb", "lg", "ar"];
		public static const RARITY_NAMES:Object = {ut: "Untiered", st: "Set", fb: "Fabled", lg: "Legendary", ar: "Ancient Relic"};
		public static const RARITY_COLORS:Object = {ut: 0xb070ff, st: 0xff9a2e, fb: 0xff4a4a, lg: 0xd8e040, ar: 0x40e8d8};
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
		private static const UT_PREFIX:Array = ["Cursed", "Ember-Wrought", "Frostbound", "Bloodsworn", "Stormcaller's", "Gravewarden's", "Sunken", "Hollow"];
		private static const LG_PREFIX:Array = ["Starforged", "Eternal", "Abyssal", "Sovereign", "Radiant", "Phantom", "Verdant", "Celestial"];
		private static const AR_SUFFIX:Array = ["of the First Light", "of Aeons", "of the Void Tide", "of the Shattered Sun"];
		public static const FB_SOURCE:String = "Dark Elder's";
		public static const SET_NAME:String = "Valorous";

		/** Legendary / relic passives. */
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

		/** Bonus for wearing all 4 pieces of a set. */
		public static const SET_BONUS:Object = {hp: 80, att: 10, def: 10, dex: 10, frt: 10};

		public static function makeWeapon(sub:String, tier:int, rarity:String = null):Object {
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
			return enchant(w, rarity);
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
			return {kind: "material", sub: "sor", tier: 0, name: "Sor Crystal"};
		}

		/** Gear for one of a class's 4 slots. */
		public static function makeForSlot(cls:Object, slot:int, tier:int, rarity:String):Object {
			switch (slot) {
				case 0: return makeWeapon(cls.weapon, tier, rarity);
				case 1: return makeAbility(cls.abilityType, tier, rarity);
				case 2: return makeArmor(cls.armor, tier, rarity);
			}
			return makeRing(randomStat(), Math.min(5, tier), rarity);
		}

		/** Turn an item into a Legendary of the same kind (Sor Forge). */
		public static function forgeLegendary(item:Object, cls:Object):Object {
			switch (item.kind) {
				case "weapon": return makeWeapon(item.sub, 7, "lg");
				case "ability": return makeAbility(item.sub, 6, "lg");
				case "armor": return makeArmor(item.sub, 7, "lg");
				case "ring": return makeRing(item.sub, 5, "lg");
			}
			return item;
		}

		public static function isGear(item:Object):Boolean {
			return item && (item.kind == "weapon" || item.kind == "armor" || item.kind == "ability" || item.kind == "ring");
		}

		/** "T3", "UT", "LG"... or "" for consumables. */
		public static function tierLabel(item:Object):String {
			if (!item) return "";
			if (item.rarity) return String(item.rarity).toUpperCase();
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

		/** Tooltip body text (HTML). */
		public static function describe(item:Object):String {
			if (!item) return "";
			var s:String = "";
			if (item.rarity) s += "<font color='" + Ui.hex(RARITY_COLORS[item.rarity]) + "'>" + RARITY_NAMES[item.rarity] + "</font>\n";
			switch (item.kind) {
				case "weapon":
					s += "Damage: " + item.dmin + "-" + item.dmax + "\n";
					if (item.shots > 1) s += "Shots: " + item.shots + "\n";
					s += "Range: " + (item.spd * item.life).toFixed(1) + " tiles\n";
					if (item.pierce) s += "Shots hit multiple targets\n";
					if (item.rate != 1) s += "Rate of fire: " + Math.round(item.rate * 100) + "%\n";
					break;
				case "armor":
					break;
				case "ability":
					s += "Ability power: " + Math.round(item.power * 100) + "%\n";
					break;
				case "hp": s += "Restores 100 HP\n"; break;
				case "mp": s += "Restores 100 MP\n"; break;
				case "stat": s += "Permanently raises " + STAT_NAMES[item.sub] + "\n"; break;
				case "material": s += "Crafting material for the Sor Forge.\nForge: UT/ST/FB item + Sor Crystal + 100 Onrane = Legendary\n"; break;
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
			if (item.set) s += "<font color='#ff9a2e'>" + item.set + " Set (4 pieces): +80 HP, +10 ATT/DEF/DEX, +10 Fortune</font>\n";
			s += "<font color='#888888'>Sells for " + sellValue(item) + " gold</font>\n";
			return s;
		}

		// ---- enemies ----------------------------------------------------
		// ai: chase (close to `keep`), orbit (circle at `keep`), wander, charge, boss
		// attacks: p = aimed | ring | spiral | summon ; arc in degrees ; spd tiles/s ; life seconds
		public static const ENEMIES:Object = {
			pirate: {name: "Pirate", spr: "pirate", hp: 30, def: 0, spd: 1.6, xp: 5, ai: "chase", keep: 3, drop: 0.12, col: 0xc02020,
				attacks: [{p: "aimed", n: 1, spd: 6, life: 1.0, dmg: 8, cd: 1.3, r: 0.15, col: 0xffffff}]},
			snake: {name: "Sand Snake", spr: "snake", hp: 22, def: 0, spd: 2.2, xp: 4, ai: "orbit", keep: 3, drop: 0.1, col: 0xc8b040,
				attacks: [{p: "aimed", n: 1, spd: 7, life: 0.8, dmg: 6, cd: 0.9, r: 0.12, col: 0x80ff80}]},
			crab: {name: "Shore Crab", spr: "crab", hp: 50, def: 2, spd: 1.0, xp: 7, ai: "wander", drop: 0.15, col: 0xe05030,
				attacks: [{p: "ring", n: 6, rot: 30, spd: 4, life: 1.3, dmg: 10, cd: 2.0, r: 0.2, col: 0xe08030, shape: "ring"}]},

			goblin: {name: "Goblin", spr: "goblin", hp: 90, def: 2, spd: 2.4, xp: 12, ai: "chase", keep: 1.5, drop: 0.16, col: 0x6ab040,
				attacks: [{p: "aimed", n: 2, arc: 15, spd: 7, life: 0.6, dmg: 12, cd: 1.0, r: 0.15, col: 0xc0ff60}]},
			hobbit: {name: "Hobbit Mage", spr: "hobbit", hp: 70, def: 0, spd: 1.6, xp: 12, ai: "orbit", keep: 4, drop: 0.16, col: 0x8040a0,
				attacks: [{p: "aimed", n: 3, arc: 30, spd: 6, life: 1.1, dmg: 14, cd: 1.4, r: 0.15, col: 0x66ccff}]},
			bandit: {name: "Bandit", spr: "bandit", hp: 120, def: 3, spd: 1.8, xp: 15, ai: "charge", keep: 2, drop: 0.18, col: 0x404040,
				attacks: [{p: "aimed", n: 1, spd: 9, life: 0.8, dmg: 20, cd: 1.0, r: 0.17, col: 0xff6060}]},

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

			// ---- realm events (Valor-style) -------------------------------------
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
				gold: 420, onrane: 5,
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
			imp: {name: "Ember Imp", spr: "imp", hp: 300, def: 5, spd: 3.0, xp: 15, ai: "chase", keep: 1, drop: 0, col: 0xff6020,
				attacks: [{p: "aimed", n: 2, arc: 20, spd: 8, life: 0.9, dmg: 35, cd: 0.8, r: 0.16, col: 0xff8030}]},
			skeleton: {name: "Bone Soldier", spr: "skeleton", hp: 350, def: 8, spd: 2.4, xp: 15, ai: "chase", keep: 1.5, drop: 0, col: 0xe8e0c0,
				attacks: [{p: "aimed", n: 1, spd: 10, life: 0.9, dmg: 45, cd: 0.9, r: 0.18, col: 0xe8e0c0, shape: "dart"}]},
			shade: {name: "Elder's Shade", spr: "shade", hp: 600, def: 10, spd: 3.0, xp: 20, ai: "orbit", keep: 4, drop: 0, col: 0x8040c0,
				attacks: [{p: "aimed", n: 3, arc: 24, spd: 9, life: 1.2, dmg: 50, cd: 1.1, r: 0.18, col: 0xc080ff, shape: "dart", eff: "confused"}]}
		};

		/** Which enemies spawn in each zone: 0 beach, 1 lowlands, 2 midlands, 3 godlands. */
		public static const ZONE_SPAWNS:Array = [
			["pirate", "pirate", "snake", "crab"],
			["goblin", "hobbit", "bandit", "goblin"],
			["orc", "elf", "gazer", "orc"],
			["medusa", "djinn", "ent", "beholder"]
		];
		public static const ZONE_NAMES:Array = ["Shore", "Lowlands", "Midlands", "Godlands", "Safe Haven", "Nexus", "Dark Elder's Chamber", "Dungeon"];
		public static const REALM_NAMES:Array = ["Medusa", "Djinn", "Beholder", "Ent", "Gazer", "Cyclops", "Lich", "Hydra", "Sphinx", "Ogre", "Kraken", "Wraith", "Basilisk", "Harpy", "Golem"];

		/** Realm events in the order they can appear; each realm needs EVENTS_PER_REALM of them killed. */
		public static const EVENTS:Array = ["ev_cube", "ev_titan", "ev_wyrm", "ev_king", "ev_behemoth", "ev_regent"];
		public static const EVENTS_PER_REALM:int = 6;
		public static const OVERLORD:String = "Azrakor the Dark Elder";

		/** Dungeons dropped by realm events (Valor-style): floor tile, minions and boss. */
		public static const DUNGEONS:Array = [
			{name: "Sunken Crypt", color: 0x6ad0ff, floor: 9, accent: 4, mobs: ["skeleton", "skeleton", "shade", "gazer"], boss: "warden"},
			{name: "Ember Depths", color: 0xff6020, floor: 6, accent: 7, mobs: ["imp", "imp", "orc", "goblin"], boss: "pyrelord"},
			{name: "Storm Spire", color: 0xf0e040, floor: 13, accent: 14, mobs: ["djinn", "elf", "elf", "hobbit"], boss: "seraph"},
			{name: "Forgotten Cellar", color: 0x6090ff, floor: 4, accent: 9, mobs: ["bandit", "hobbit", "gazer", "elf"], boss: "sorcerer"}
		];
		public static const DUNGEON_DROP_CHANCE:Number = 0.7;

		/** Skill tree (Valor "Ascension"): unlocked at level 20 with 11/11 stats. */
		public static const SKILLS:Array = [
			{id: "brutality", name: "Brutality", desc: "+5% damage", max: 5},
			{id: "precision", name: "Precision", desc: "+2% crit chance", max: 5},
			{id: "ferocity", name: "Ferocity", desc: "+0.1x crit damage", max: 5},
			{id: "vigor", name: "Vigor", desc: "+40 max HP", max: 5},
			{id: "bulwark", name: "Bulwark", desc: "+4 Defense", max: 5},
			{id: "aegis", name: "Aegis", desc: "+5 Protection", max: 5},
			{id: "swiftness", name: "Swiftness", desc: "+4 Speed", max: 5},
			{id: "leech", name: "Leech", desc: "+1 HP per hit", max: 5},
			{id: "fortune", name: "Prosperity", desc: "+5 Fortune", max: 5}
		];
		public static const SKILL_STATS:Object = {vigor: {hp: 40}, bulwark: {def: 4}, aegis: {prt: 5}, swiftness: {spd: 4}, fortune: {frt: 5}};
		public static const XP_PER_SKILL_POINT:int = 600;

		/** Daily quests (Valor's daily contracts / battle pass missions); 3 are picked per day. */
		public static const QUESTS:Array = [
			{id: "kills", text: "Slay 60 monsters", goal: 60, gold: 300, onrane: 0},
			{id: "godkills", text: "Slay 25 Godlands monsters", goal: 25, gold: 0, onrane: 3},
			{id: "events", text: "Defeat 2 realm event bosses", goal: 2, gold: 500, onrane: 2},
			{id: "dungeon", text: "Clear a dungeon", goal: 1, gold: 200, onrane: 4},
			{id: "pots", text: "Drink 3 stat potions", goal: 3, gold: 400, onrane: 0},
			{id: "rare", text: "Find 2 purple-or-better loot bags", goal: 2, gold: 300, onrane: 1},
			{id: "elder", text: "Defeat the Dark Elder", goal: 1, gold: 1000, onrane: 8}
		];

		public static function quest(id:String):Object {
			for each (var q:Object in QUESTS) if (q.id == id) return q;
			return null;
		}

		// ---- loot -------------------------------------------------------
		/** fortune: % loot boost from gear (Valor's Fortune stat). */
		public static function rollLoot(def:Object, zone:int, cls:Object, fortune:int):Array {
			var items:Array = [];
			var boost:Number = 1 + fortune / 100;
			var slot:int;
			if (def.final) {
				// the Dark Elder: fabled gear, a shot at legendaries and relics
				items.push(makeForSlot(cls, int(Math.random() * 4), 7, "fb"));
				items.push(makeForSlot(cls, int(Math.random() * 4), 7, "fb"));
				if (Math.random() < 0.3 * boost) items.push(makeForSlot(cls, int(Math.random() * 4), 7, "lg"));
				if (Math.random() < 0.05 * boost) items.push(makeForSlot(cls, int(Math.random() * 4), 7, "ar"));
				items.push(makeSor());
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				return items;
			}
			if (def.dungeon) {
				items.push(makeForSlot(cls, int(Math.random() * 4), 7, Math.random() < 0.5 ? "st" : "ut"));
				if (Math.random() < 0.1 * boost) items.push(makeForSlot(cls, int(Math.random() * 4), 7, "lg"));
				if (Math.random() < 0.3 * boost) items.push(makeSor());
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				return items;
			}
			if (def.ai == "boss") {
				// realm event: UT or set piece, sometimes a legendary
				slot = int(Math.random() * 4);
				items.push(makeForSlot(cls, slot, 7, Math.random() < 0.4 ? "st" : "ut"));
				if (Math.random() < 0.08 * boost) items.push(makeForSlot(cls, int(Math.random() * 4), 7, "lg"));
				if (Math.random() < 0.35 * boost) items.push(makeSor());
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("hp"));
				return items;
			}
			if (def.drop <= 0) return items;
			if (Math.random() < 0.14) items.push(makePotion("hp"));
			if (Math.random() < 0.09) items.push(makePotion("mp"));
			if (Math.random() < def.drop * boost) {
				var tier:int = zone * 2 + (Math.random() < 0.35 ? 1 : 0) + (Math.random() < 0.06 ? 1 : 0);
				if (tier > 7) tier = 7;
				var roll:Number = Math.random();
				if (roll < 0.4) items.push(makeWeapon(cls.weapon, tier));
				else if (roll < 0.55) items.push(makeAbility(cls.abilityType, Math.min(6, tier)));
				else if (roll < 0.82) items.push(makeArmor(cls.armor, tier));
				else items.push(makeRing(randomStat(), Math.min(5, int(tier * 0.7))));
			}
			if (zone == 3 && Math.random() < 0.006 * boost) items.push(makeForSlot(cls, int(Math.random() * 4), 7, "ut"));
			var statChance:Number = zone == 3 ? 0.07 : zone == 2 ? 0.015 : 0;
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
