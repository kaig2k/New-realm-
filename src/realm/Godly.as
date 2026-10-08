package realm {
	/**
	 * Godly items: the rarest tier (1 in 3,000 per kill). Every class has a full
	 * four-piece Godly set (weapon, ability, armor, ring), 32 items in all with no
	 * duplicates, spread over the endgame, finale and raid bosses.
	 */
	public class Godly {
		public static const CHANCE:Number = 1 / 3000;

		/** Per class: set name, the four item names, weapon twist and set bonus. */
		public static const SETS:Object = {
			wizard: {name: "Astral Archmage", items: ["Staff of the Endless Cosmos", "Grimoire of Creation", "Robes of the Astral Archmage", "Ring of Infinite Stars"],
				weapon: {shots: 4, arc: 20, passive: "shards", col: 0x80a0ff}, bonus: {mp: 150, att: 18, wis: 15, dex: 10, frt: 15}},
			archer: {name: "Skypiercer", items: ["Skypiercer, Bow of Dawn", "Quiver of the Last Light", "Skypiercer Mantle", "Ring of the Falcon King"],
				weapon: {shots: 5, arc: 24, pierce: true, passive: "critical", col: 0xffe080}, bonus: {hp: 120, att: 15, dex: 18, spd: 10, frt: 15}},
			knight: {name: "Aegis Eternal", items: ["Blade of the Eternal Oath", "The Unbroken Aegis", "Bastion Plate", "Ring of the Unyielding"],
				weapon: {shots: 3, arc: 30, pierce: true, passive: "lifesteal", col: 0xc0e0ff}, bonus: {hp: 250, def: 25, vit: 15, prt: 20, frt: 15}},
			priest: {name: "Seraphic", items: ["Wand of Seraphic Light", "Codex of Miracles", "Vestments of the Seraphim", "Halo Ring"],
				weapon: {shots: 3, arc: 16, motion: "wave", passive: "frost", col: 0xfff6c0}, bonus: {hp: 150, mp: 150, wis: 20, vit: 12, frt: 15}},
			rogue: {name: "Nightfall", items: ["Kris of the Eclipse", "Shroud of Nightfall", "Eclipse Hide", "Ring of Whispers"],
				weapon: {shots: 3, arc: 14, rate: 1.2, passive: "critical", col: 0x9a60ff}, bonus: {hp: 120, dex: 18, spd: 18, mgt: 15, frt: 15}},
			warrior: {name: "Titanslayer", items: ["Titanslayer Greatsword", "Crown of the Warlord", "Titanforged Plate", "Ring of Rage"],
				weapon: {mult: 2, size: 6, pierce: true, passive: "rampage", col: 0xff6040}, bonus: {hp: 200, att: 20, vit: 15, mgt: 15, frt: 15}},
			necromancer: {name: "Soulforge", items: ["Staff of a Thousand Souls", "Skull of the Lich Emperor", "Shroud of the Soulforge", "Ring of the Grave"],
				weapon: {shots: 2, parallel: true, pierce: true, motion: "wave", passive: "lifesteal", col: 0x60ffb0}, bonus: {mp: 150, att: 15, wis: 18, mgt: 12, frt: 15}},
			huntress: {name: "Wildheart Eternal", items: ["Bow of the Wild Hunt", "Snare of the World Tree", "Hide of the Primal Beast", "Ring of the Pack"],
				weapon: {shots: 3, arc: 10, motion: "return", pierce: true, passive: "shards", col: 0x80ff60}, bonus: {hp: 150, att: 15, dex: 15, spd: 12, frt: 15}}
		};

		/** Which boss drops which piece: [class, slot] (slot 0 weapon, 1 ability, 2 armor, 3 ring). */
		public static const DROPS:Object = {
			elder: [["wizard", 0], ["necromancer", 1]],
			tide_empress: [["priest", 2], ["huntress", 0]],
			gearmind: [["knight", 2], ["warrior", 3]],
			void_dragon: [["rogue", 0], ["wizard", 3]],
			archon: [["warrior", 0], ["necromancer", 0]],
			tempestus: [["archer", 0], ["priest", 0]],
			matron: [["priest", 1], ["necromancer", 2]],
			galecaller: [["archer", 1], ["huntress", 1]],
			shattered_seraph: [["wizard", 1], ["priest", 3]],
			sun_king: [["knight", 0], ["knight", 1]],
			moon_queen: [["wizard", 2], ["huntress", 2]],
			star_prince: [["rogue", 1], ["archer", 3]],
			blood_knight: [["warrior", 2], ["warrior", 1]],
			hex_queen: [["rogue", 2], ["necromancer", 3]],
			frost_warden: [["archer", 2]],
			flame_warden: [["knight", 3]],
			zealot_a: [["rogue", 3]],
			sentinel_a: [["huntress", 3]]
		};

		/** Boss name for each piece (for tooltips and the wiki). */
		public static var source:Object = {};

		public static function init():void {
			for (var cls:String in SETS) {
				var st:Object = SETS[cls];
				Data.SETS["g_" + cls] = {name: st.name, bonus: st.bonus};
			}
			for (var b:String in DROPS) {
				var def:Object = Data.ENEMIES[b];
				if (!def) continue;
				def.godly = DROPS[b];
				for each (var d:Array in DROPS[b]) source[d[0] + d[1]] = def.name;
			}
		}

		public static function make(cls:String, slot:int):Object {
			var st:Object = SETS[cls];
			var c:Object = Data.CLASSES[cls];
			var it:Object = slot == 0 ? Data.makeWeapon(c.weapon, 7, "gd", "") : Data.makeForSlot(c, slot, 7, "gd");
			it.name = st.items[slot];
			it.set = "g_" + cls;
			it.gid = cls + slot;
			if (slot == 0) {
				var x:Object = st.weapon;
				if (x.shots) { it.shots = x.shots; it.parallel = x.parallel == true; }
				if (x.arc != undefined) it.arc = x.arc;
				if (x.rate) it.rate = x.rate;
				if (x.motion) it.motion = x.motion;
				if (x.pierce) it.pierce = true;
				if (x.size) it.size = x.size;
				if (x.col) it.col = x.col;
				if (x.passive) it.passive = x.passive;
				var mult:Number = x.mult || (x.shots ? Math.max(0.6, 1.6 / Math.sqrt(x.shots)) : 1);
				it.dmin = int(it.dmin * mult);
				it.dmax = int(it.dmax * mult);
				delete it.form;
			}
			return it;
		}

		/** Rolls a boss's Godly pieces (each 1 in 3,000, a little better with Bounty). */
		public static function roll(def:Object, items:Array, boost:Number):void {
			if (!def.godly) return;
			// one roll a kill, however many Godly items the boss can drop (then which one)
			if (def.godly.length && Math.random() < CHANCE * boost) {
				var d:Array = def.godly[int(Math.random() * def.godly.length)];
				items.push(make(d[0], d[1]));
			}
		}

		public static function describe(it:Object):String {
			var src:String = source[it.gid];
			return "<font color='#fff6e0'>Godly: 1 in 3,000" + (src ? " from " + src : "") + ".</font>\n";
		}
	}
}
