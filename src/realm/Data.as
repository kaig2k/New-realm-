package realm {
	/** Game balance: classes, enemies, items and loot tables. */
	public class Data {
		public static const STATS:Array = ["hp", "mp", "att", "def", "spd", "dex", "vit", "wis"];
		public static const STAT_NAMES:Object = {hp: "Life", mp: "Mana", att: "Attack", def: "Defense", spd: "Speed", dex: "Dexterity", vit: "Vitality", wis: "Wisdom"};
		public static const STAT_COLORS:Object = {hp: 0xff70b0, mp: 0x5080ff, att: 0xa040e0, def: 0x303030, spd: 0x40c040, dex: 0xff9020, vit: 0xd02020, wis: 0x40e0e0};

		public static const CLASSES:Object = {
			wizard: {
				id: "wizard", name: "Wizard", weapon: "staff", armor: "robe",
				desc: "Fragile but deadly. Fires twin bolts and blasts crowds with Spell Bomb.",
				base: {hp: 100, mp: 100, att: 12, def: 0, spd: 10, dex: 15, vit: 10, wis: 12},
				grow: {hp: 22, mp: 8, att: 2, def: 0, spd: 1, dex: 2, vit: 1, wis: 1.5},
				max: {hp: 670, mp: 385, att: 75, def: 25, spd: 50, dex: 75, vit: 40, wis: 60},
				ability: {name: "Spell Bomb", cost: 30, desc: "Ring of 20 bolts at the cursor."}
			},
			archer: {
				id: "archer", name: "Archer", weapon: "bow", armor: "leather",
				desc: "Piercing arrows hit every foe in a line. Quiver shot slows enemies.",
				base: {hp: 130, mp: 100, att: 12, def: 0, spd: 12, dex: 12, vit: 12, wis: 10},
				grow: {hp: 26, mp: 6, att: 2, def: 0.5, spd: 1, dex: 1.5, vit: 1.5, wis: 1},
				max: {hp: 700, mp: 252, att: 75, def: 25, spd: 50, dex: 50, vit: 40, wis: 50},
				ability: {name: "Quiver", cost: 25, desc: "Huge piercing arrow that slows."}
			},
			knight: {
				id: "knight", name: "Knight", weapon: "sword", armor: "heavy",
				desc: "Armoured juggernaut. Short-range sword, Shield Bash stuns nearby foes.",
				base: {hp: 200, mp: 100, att: 15, def: 0, spd: 7, dex: 10, vit: 10, wis: 10},
				grow: {hp: 30, mp: 5, att: 2, def: 1, spd: 0.8, dex: 1, vit: 2, wis: 0.5},
				max: {hp: 770, mp: 252, att: 50, def: 40, spd: 50, dex: 50, vit: 75, wis: 50},
				ability: {name: "Shield Bash", cost: 30, desc: "Stuns enemies near you."}
			},
			priest: {
				id: "priest", name: "Priest", weapon: "wand", armor: "robe",
				desc: "Steady wand fire and the Holy Tome, a big self-heal with a holy burst.",
				base: {hp: 100, mp: 100, att: 12, def: 0, spd: 12, dex: 12, vit: 10, wis: 15},
				grow: {hp: 22, mp: 8, att: 1.5, def: 0, spd: 1.5, dex: 1.5, vit: 1, wis: 2},
				max: {hp: 670, mp: 385, att: 50, def: 25, spd: 55, dex: 55, vit: 40, wis: 75},
				ability: {name: "Holy Tome", cost: 35, desc: "Heal yourself and burst holy light."}
			}
		};
		public static const CLASS_ORDER:Array = ["wizard", "archer", "knight", "priest"];

		public static const WEAPON_NAMES:Object = {
			staff: ["Twig Staff", "Ember Staff", "Comet Staff", "Serpent Staff", "Starfall Staff", "Ruin Staff", "Nebula Staff", "Staff of the Void", "Overlord's Scepter"],
			bow: ["Short Bow", "Twin Bow", "Hunter's Bow", "Gilded Bow", "Thornwood Bow", "Fey Bow", "Bloodstring Bow", "Bow of Distant Stars", "Cubic Longbow"],
			sword: ["Rusty Sword", "Broad Sword", "Saber", "Long Sword", "Falchion", "Flame Blade", "Crystal Blade", "Sunforged Blade", "Cube Cleaver"],
			wand: ["Bone Wand", "Ember Wand", "Grave Wand", "Deep Wand", "Shadow Wand", "Warden's Wand", "Penance Wand", "Wand of Radiance", "Wand of Endless Light"]
		};
		public static const ARMOR_NAMES:Object = {
			robe: ["Cloth Robe", "Apprentice Robe", "Silk Robe", "Mystic Robe", "Star Robe", "Ether Robe", "Archmage Robe", "Robe of the Void", "Overlord's Mantle"],
			leather: ["Leather Vest", "Studded Vest", "Hunter's Hide", "Ranger Leather", "Drake Hide", "Wyvern Hide", "Hydra Hide", "Leviathan Hide", "Cube Hide"],
			heavy: ["Chainmail", "Ring Mail", "Scale Armor", "Plate Mail", "Steel Plate", "Mithril Plate", "Dragonscale Plate", "Titan Plate", "Overlord's Bulwark"]
		};

		public static function makeWeapon(sub:String, tier:int):Object {
			var t:int = tier;
			var w:Object = {kind: "weapon", sub: sub, tier: tier, name: WEAPON_NAMES[sub][tier], shots: 1, arc: 0, parallel: false, pierce: false, rate: 1};
			switch (sub) {
				case "staff":
					w.dmin = 14 + 7 * t; w.dmax = 22 + 9 * t; w.shots = 2; w.parallel = true;
					w.spd = 13; w.life = 0.6; w.col = 0xd060ff;
					break;
				case "bow":
					w.dmin = 12 + 6 * t; w.dmax = 22 + 8 * t; w.shots = t < 3 ? 1 : (t < 6 ? 2 : 3); w.arc = 9;
					w.spd = 15; w.life = 0.52; w.pierce = true; w.col = 0xffe080;
					break;
				case "sword":
					w.dmin = 34 + 11 * t; w.dmax = 52 + 15 * t;
					w.spd = 11; w.life = 0.34; w.col = 0xd0e8ff;
					break;
				default:
					w.dmin = 22 + 8 * t; w.dmax = 36 + 10 * t;
					w.spd = 16; w.life = 0.56; w.col = 0xfff0a0;
			}
			if (tier >= 8) { // unique drops from the Overlord
				w.col = 0xff50ff;
				if (sub == "staff") { w.shots = 3; w.parallel = true; }
				else if (sub == "bow") { w.shots = 4; w.arc = 10; }
				else if (sub == "sword") { w.shots = 2; w.arc = 12; w.pierce = true; }
				else { w.pierce = true; w.rate = 1.2; }
			}
			return w;
		}

		public static function makeArmor(sub:String, tier:int):Object {
			var bonus:int = sub == "heavy" ? 3 + 4 * tier : sub == "leather" ? 2 + 3 * tier : 1 + 2 * tier;
			var a:Object = {kind: "armor", sub: sub, tier: tier, name: ARMOR_NAMES[sub][tier], def: bonus};
			if (sub == "robe") a.mp = 10 + 8 * tier;
			if (sub == "leather") a.dex = Math.floor(tier / 2);
			return a;
		}

		public static function makePotion(kind:String, stat:String = null):Object {
			if (kind == "hp") return {kind: "hp", tier: 0, name: "Health Potion", color: 0xff3030};
			if (kind == "mp") return {kind: "mp", tier: 0, name: "Magic Potion", color: 0x3060ff};
			return {kind: "stat", sub: stat, tier: 0, name: "Potion of " + STAT_NAMES[stat], color: STAT_COLORS[stat]};
		}

		public static function describe(item:Object):String {
			if (!item) return "";
			var s:String = "<b>" + item.name + "</b>";
			if (item.tier >= 8) s += "  <font color='#ff70ff'>UT</font>";
			else if (item.kind == "weapon" || item.kind == "armor") s += "  <font color='#aaaaaa'>T" + item.tier + "</font>";
			s += "\n";
			switch (item.kind) {
				case "weapon":
					s += "Damage: " + item.dmin + "-" + item.dmax + "\n";
					if (item.shots > 1) s += "Shots: " + item.shots + "\n";
					s += "Range: " + (item.spd * item.life).toFixed(1) + " tiles\n";
					if (item.pierce) s += "Shots pierce enemies\n";
					if (item.rate != 1) s += "Rate of fire: " + Math.round(item.rate * 100) + "%\n";
					break;
				case "armor":
					s += "+" + item.def + " Defense\n";
					if (item.mp) s += "+" + item.mp + " Max MP\n";
					if (item.dex) s += "+" + item.dex + " Dexterity\n";
					break;
				case "hp": s += "Restores 100 HP\n"; break;
				case "mp": s += "Restores 100 MP\n"; break;
				case "stat": s += "Permanently raises " + STAT_NAMES[item.sub] + "\n"; break;
			}
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
				attacks: [{p: "ring", n: 6, rot: 30, spd: 4, life: 1.3, dmg: 10, cd: 2.0, r: 0.15, col: 0xffa040}]},

			goblin: {name: "Goblin", spr: "goblin", hp: 90, def: 2, spd: 2.4, xp: 12, ai: "chase", keep: 1.5, drop: 0.16, col: 0x6ab040,
				attacks: [{p: "aimed", n: 2, arc: 15, spd: 7, life: 0.6, dmg: 12, cd: 1.0, r: 0.15, col: 0xc0ff60}]},
			hobbit: {name: "Hobbit Mage", spr: "hobbit", hp: 70, def: 0, spd: 1.6, xp: 12, ai: "orbit", keep: 4, drop: 0.16, col: 0x8040a0,
				attacks: [{p: "aimed", n: 3, arc: 30, spd: 6, life: 1.1, dmg: 14, cd: 1.4, r: 0.15, col: 0x66ccff}]},
			bandit: {name: "Bandit", spr: "bandit", hp: 120, def: 3, spd: 1.8, xp: 15, ai: "charge", keep: 2, drop: 0.18, col: 0x404040,
				attacks: [{p: "aimed", n: 1, spd: 9, life: 0.8, dmg: 20, cd: 1.0, r: 0.17, col: 0xff6060}]},

			orc: {name: "Orc Warrior", spr: "orc", hp: 260, def: 4, spd: 2.6, xp: 30, ai: "chase", keep: 1, drop: 0.2, col: 0x3a7a3a,
				attacks: [{p: "aimed", n: 3, arc: 40, spd: 8, life: 0.5, dmg: 30, cd: 0.8, r: 0.18, col: 0xff5050}]},
			elf: {name: "Dark Elf Archer", spr: "elf", hp: 180, def: 2, spd: 2.0, xp: 30, ai: "orbit", keep: 5, drop: 0.2, col: 0x40204a,
				attacks: [{p: "aimed", n: 1, spd: 12, life: 0.7, dmg: 28, cd: 1.0, r: 0.14, col: 0xd0a0ff},
					{p: "aimed", n: 3, arc: 20, spd: 9, life: 0.8, dmg: 22, cd: 2.5, r: 0.14, col: 0xd0a0ff}]},
			gazer: {name: "Gazer", spr: "gazer", hp: 320, def: 6, spd: 1.2, xp: 34, ai: "wander", drop: 0.22, col: 0x9040a0,
				attacks: [{p: "ring", n: 8, rot: 22, spd: 5, life: 1.5, dmg: 24, cd: 1.6, r: 0.18, col: 0xff80ff}]},

			medusa: {name: "Medusa", spr: "medusa", hp: 900, def: 10, spd: 1.6, xp: 70, ai: "orbit", keep: 5, drop: 0.3, col: 0x40c040,
				attacks: [{p: "ring", n: 12, rot: 15, spd: 5, life: 1.6, dmg: 45, cd: 2.0, r: 0.2, col: 0x60ff60},
					{p: "aimed", n: 1, spd: 9, life: 1.0, dmg: 60, cd: 1.2, r: 0.25, col: 0xffff60}]},
			djinn: {name: "Djinn", spr: "djinn", hp: 700, def: 8, spd: 2.8, xp: 65, ai: "orbit", keep: 4, drop: 0.3, col: 0x50a0ff,
				attacks: [{p: "spiral", n: 4, rot: 13, spd: 6, life: 1.4, dmg: 35, cd: 0.18, r: 0.16, col: 0x60c0ff}]},
			ent: {name: "Ent Ancient", spr: "ent", hp: 1500, def: 20, spd: 0.8, xp: 90, ai: "chase", keep: 2, drop: 0.35, col: 0x3a8a2a,
				attacks: [{p: "aimed", n: 5, arc: 60, spd: 6, life: 1.2, dmg: 50, cd: 1.5, r: 0.22, col: 0x99ff44}]},
			beholder: {name: "Beholder", spr: "beholder", hp: 1100, def: 12, spd: 1.4, xp: 80, ai: "wander", drop: 0.32, col: 0xb02020,
				attacks: [{p: "ring", n: 16, rot: 11, spd: 4.5, life: 2.0, dmg: 40, cd: 2.6, r: 0.18, col: 0xff3030},
					{p: "aimed", n: 2, arc: 10, spd: 10, life: 1.0, dmg: 55, cd: 1.3, r: 0.2, col: 0xffe0a0}]},

			cubelet: {name: "Cubelet", spr: "cubelet", hp: 150, def: 5, spd: 3.2, xp: 10, ai: "chase", keep: 0.5, drop: 0, col: 0x9040e0,
				attacks: [{p: "aimed", n: 1, spd: 8, life: 1.0, dmg: 30, cd: 0.7, r: 0.15, col: 0xc080ff}]},

			boss: {name: "Cube Overlord", spr: "boss", hp: 15000, def: 25, spd: 1.2, xp: 2500, ai: "boss", r: 0.9, aggro: 14, range: 14, drop: 1, col: 0x7a30c0,
				phases: [
					[{p: "spiral", n: 4, rot: 11, spd: 5.5, life: 2.4, dmg: 55, cd: 0.14, r: 0.2, col: 0xff40ff},
						{p: "aimed", n: 3, arc: 24, spd: 9, life: 1.5, dmg: 70, cd: 1.4, r: 0.25, col: 0xffffff}],
					[{p: "ring", n: 24, rot: 7.5, spd: 4.5, life: 2.8, dmg: 60, cd: 1.1, r: 0.22, col: 0x40e0ff},
						{p: "aimed", n: 1, spd: 12, life: 1.2, dmg: 90, cd: 0.6, r: 0.3, col: 0xff4040},
						{p: "summon", n: 2, cd: 6, what: "cubelet"}],
					[{p: "spiral", n: 6, rot: -9, spd: 6, life: 2.2, dmg: 60, cd: 0.12, r: 0.2, col: 0xffff40},
						{p: "aimed", n: 7, arc: 70, spd: 8, life: 1.6, dmg: 65, cd: 1.0, r: 0.22, col: 0xff8040}]
				]}
		};

		/** Which enemies spawn in each zone: 0 beach, 1 lowlands, 2 midlands, 3 godlands. */
		public static const ZONE_SPAWNS:Array = [
			["pirate", "pirate", "snake", "crab"],
			["goblin", "hobbit", "bandit", "goblin"],
			["orc", "elf", "gazer", "orc"],
			["medusa", "djinn", "ent", "beholder"]
		];
		public static const ZONE_NAMES:Array = ["Shore", "Lowlands", "Midlands", "Godlands", "Safe Haven"];

		// ---- loot -------------------------------------------------------
		public static function rollLoot(def:Object, zone:int, cls:Object):Array {
			var items:Array = [];
			if (def.ai == "boss") {
				items.push(makeWeapon(cls.weapon, 8));
				if (Math.random() < 0.5) items.push(makeArmor(cls.armor, 8));
				else items.push(makeArmor(cls.armor, 7));
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", randomStat()));
				items.push(makePotion("stat", "hp"));
				items.push(makePotion("hp"));
				items.push(makePotion("mp"));
				return items;
			}
			if (def.drop <= 0) return items;
			if (Math.random() < 0.14) items.push(makePotion("hp"));
			if (Math.random() < 0.09) items.push(makePotion("mp"));
			if (Math.random() < def.drop) {
				var tier:int = zone * 2 + (Math.random() < 0.35 ? 1 : 0) + (Math.random() < 0.06 ? 1 : 0);
				if (tier > 7) tier = 7;
				if (Math.random() < 0.55) items.push(makeWeapon(cls.weapon, tier));
				else items.push(makeArmor(cls.armor, tier));
			}
			var statChance:Number = zone == 3 ? 0.07 : zone == 2 ? 0.015 : 0;
			if (Math.random() < statChance) items.push(makePotion("stat", randomStat()));
			return items;
		}

		public static function randomStat():String {
			return STATS[int(Math.random() * STATS.length)];
		}

		public static function bagColor(items:Array):String {
			var best:String = "bag_brown";
			for each (var it:Object in items) {
				if (it.tier >= 8) return "bag_white";
				if (it.tier >= 6) best = "bag_cyan";
				else if ((it.tier >= 4 || it.kind == "stat") && best == "bag_brown") best = "bag_purple";
			}
			return best;
		}
	}
}
