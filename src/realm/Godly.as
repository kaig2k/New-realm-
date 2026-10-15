package realm {
	/**
	 * Godly items: the rarest tier (1 in 1,000 per kill). Every class has a full
	 * four-piece Godly set (weapon, ability, armor, ring), 32 items in all with no
	 * duplicates, spread over the endgame, finale and raid bosses.
	 */
	public class Godly {
		public static const CHANCE:Number = 1 / 1000;

		/**
		 * Per class: set name, the four item names, weapon twist, set bonus, and what makes
		 * every drop of a piece the same: its four stats (focus, best first: each piece leads
		 * with a different one), its ring's stat and its ability.
		 */
		public static const SETS:Object = {
			wizard: {name: "Astral Archmage", items: ["Staff of the Endless Cosmos", "Grimoire of Creation", "Robes of the Astral Archmage", "Ring of Infinite Stars"],
				weapon: {shots: 4, arc: 20, passive: "shards", col: 0x80a0ff}, bonus: {mp: 150, att: 18, wis: 15, dex: 10, frt: 15},
				focus: ["att", "wis", "dex", "mgt"], ring: "att", ab: "lightning"},
			archer: {name: "Skypiercer", items: ["Skypiercer, Bow of Dawn", "Quiver of the Last Light", "Skypiercer Mantle", "Ring of the Falcon King"],
				weapon: {shots: 5, arc: 24, pierce: true, passive: "critical", col: 0xffe080}, bonus: {hp: 120, att: 15, dex: 18, spd: 10, frt: 15},
				focus: ["dex", "att", "luc", "spd"], ring: "dex", ab: "pierce"},
			knight: {name: "Aegis Eternal", items: ["Blade of the Eternal Oath", "The Unbroken Aegis", "Bastion Plate", "Ring of the Unyielding"],
				weapon: {shots: 3, arc: 30, pierce: true, passive: "lifesteal", col: 0xc0e0ff}, bonus: {hp: 250, def: 25, vit: 15, prt: 20, frt: 15},
				focus: ["vit", "prt", "att", "dex"], ring: "hp", ab: "bash"},
			priest: {name: "Seraphic", items: ["Wand of Seraphic Light", "Codex of Miracles", "Vestments of the Seraphim", "Halo Ring"],
				weapon: {shots: 3, arc: 16, motion: "wave", passive: "frost", col: 0xfff6c0}, bonus: {hp: 150, mp: 150, wis: 20, vit: 12, frt: 15},
				focus: ["wis", "vit", "att", "luc"], ring: "wis", ab: "smite"},
			rogue: {name: "Nightfall", items: ["Kris of the Eclipse", "Shroud of Nightfall", "Eclipse Hide", "Ring of Whispers"],
				weapon: {shots: 3, arc: 14, rate: 1.2, passive: "critical", col: 0x9a60ff}, bonus: {hp: 120, dex: 18, spd: 18, mgt: 15, frt: 15},
				focus: ["dex", "mgt", "spd", "att"], ring: "dex", ab: "knives"},
			warrior: {name: "Titanslayer", items: ["Titanslayer Greatsword", "Crown of the Warlord", "Titanforged Plate", "Ring of Rage"],
				weapon: {size: 6, pierce: true, passive: "rampage", col: 0xff6040}, bonus: {hp: 200, att: 20, vit: 15, mgt: 15, frt: 15},
				focus: ["att", "mgt", "vit", "prt"], ring: "att", ab: "whirlwind"},
			necromancer: {name: "Soulforge", items: ["Staff of a Thousand Souls", "Skull of the Lich Emperor", "Shroud of the Soulforge", "Ring of the Grave"],
				weapon: {shots: 2, parallel: true, pierce: true, motion: "wave", passive: "lifesteal", col: 0x60ffb0}, bonus: {mp: 150, att: 15, wis: 18, mgt: 12, frt: 15},
				focus: ["att", "wis", "mgt", "vit"], ring: "wis", ab: "raise"},
			huntress: {name: "Wildheart Eternal", items: ["Bow of the Wild Hunt", "Snare of the World Tree", "Hide of the Primal Beast", "Ring of the Pack"],
				weapon: {shots: 3, arc: 10, motion: "return", pierce: true, passive: "shards", col: 0x80ff60}, bonus: {hp: 150, att: 15, dex: 15, spd: 12, frt: 15},
				focus: ["att", "dex", "spd", "luc"], ring: "att", ab: "wolf"},
			bard: {name: "Choir Eternal", items: ["Harpstring of the Choir", "Lyre of the Last Verse", "Mantle of the Grand Chorus", "Ring of Perfect Pitch"],
				weapon: {shots: 3, arc: 14, motion: "wave", pierce: true, passive: "frost", col: 0xffe090}, bonus: {hp: 120, mp: 120, wis: 15, luc: 20, frt: 15},
				focus: ["wis", "luc", "att", "vit"], ring: "luc", ab: "requiem"},
			alchemist: {name: "Magnum Opus", items: ["Kris of Quicksilver", "Flask of the Great Work", "Apron of the Red Stone", "Ring of Transmutation"],
				weapon: {shots: 3, arc: 18, motion: "return", passive: "lifesteal", col: 0xff5a3a}, bonus: {hp: 160, dex: 15, vit: 18, mgt: 15, frt: 15},
				focus: ["vit", "dex", "mgt", "att"], ring: "vit", ab: "philbomb"},
			chronomancer: {name: "Endless Hour", items: ["Wand of the Endless Hour", "Hourglass of Eternity", "Robes of Stopped Time", "Ring of the Last Second"],
				weapon: {shots: 2, parallel: true, motion: "accel", passive: "critical", col: 0x80e0ff}, bonus: {mp: 160, att: 15, dex: 15, wis: 18, frt: 15},
				focus: ["wis", "dex", "att", "luc"], ring: "wis", ab: "timestop"}
		};

		/** What a piece's four focus stats are worth (its lead stat first), and every piece's Health and Luck. */
		public static const AMOUNTS:Array = [24, 20, 16, 14];
		public static const HP:int = 120, LUCK:int = 15;
		/** A Godly weapon deals this much more than a Primordial one of its type (before its Divine Wrath). */
		public static const POWER:Number = 1.35;
		/** The version of the fixed pieces: anything made before it is remade (upgrade). */
		public static const GV:int = 2;

		/**
		 * Divine Wrath: every EVERY-th volley (WRATH_SET with the full set on) a Godly weapon
		 * unleashes its class's own attack. pat: "ring" round you, "fan" toward the cursor or
		 * "aim" one shot that flies to the cursor and bursts there. mul: each shot's share of a
		 * weapon hit; boom: a burst where it ends; slam: a shockwave round you.
		 */
		public static const EVERY:int = 6, WRATH_SET:int = 4;
		public static const WRATH:Object = {
			wizard: {name: "Meteor", pat: "aim", n: 1, mul: 2, spd: 11, life: 0.9, boom: {r: 3, mul: 3}, desc: "a meteor falls where you aim and bursts in a huge blast"},
			archer: {name: "Sunbeam", pat: "fan", n: 5, arc: 5, mul: 1.5, spd: 24, life: 0.55, pc: true, desc: "five beams of dawn pierce everything in a line"},
			knight: {name: "Aegis Nova", pat: "ring", n: 12, mul: 1, spd: 11, life: 0.45, pc: true, desc: "a ring of twelve holy blades bursts from you"},
			priest: {name: "Seraph Stars", pat: "ring", n: 8, mul: 1.1, spd: 11, life: 1.1, mo: "seek", desc: "eight seraph lights hunt down the nearest foes"},
			rogue: {name: "Eclipse", pat: "fan", n: 7, arc: 14, mul: 1, spd: 17, life: 0.7, mo: "seek", desc: "seven eclipse knives fan out and seek their marks"},
			warrior: {name: "Titan Slam", pat: "ring", n: 10, mul: 1, spd: 10, life: 0.45, pc: true, slam: {r: 3, mul: 2}, desc: "you slam the ground: a shockwave and a ring of ten cleaves"},
			necromancer: {name: "Soulstorm", pat: "ring", n: 8, mul: 1.1, spd: 10, life: 1.2, mo: "seek", desc: "eight hungry souls tear loose and hunt your foes"},
			huntress: {name: "Wild Hunt", pat: "fan", n: 5, arc: 16, mul: 0.9, spd: 15, life: 0.8, pc: true, mo: "return", desc: "five thorns fly out and come back through everything"},
			bard: {name: "Crescendo", pat: "ring", n: 12, mul: 0.8, spd: 10, life: 0.7, pc: true, mo: "wave", desc: "a ring of twelve singing notes rolls outward"},
			alchemist: {name: "Transmute", pat: "fan", n: 3, arc: 22, mul: 1, spd: 12, life: 0.55, boom: {r: 1.8, mul: 1.4}, desc: "three red stones that burst into fire"},
			chronomancer: {name: "Stopped Time", pat: "ring", n: 10, mul: 1, spd: 5, life: 0.8, pc: true, mo: "accel", ac: 2.2, desc: "ten clock hands that race faster and faster"}
		};

		/** Which boss drops which piece: [class, slot] (slot 0 weapon, 1 ability, 2 armor, 3 ring). */
		public static const DROPS:Object = {
			elder: [["wizard", 0], ["necromancer", 1]],
			tide_empress: [["priest", 2], ["huntress", 0]],
			gearmind: [["knight", 2], ["warrior", 3]],
			void_dragon: [["rogue", 0], ["wizard", 3]],
			matron: [["priest", 1], ["necromancer", 2]],
			shattered_seraph: [["wizard", 1], ["priest", 3]],
			sun_king: [["knight", 0], ["knight", 1]],
			moon_queen: [["wizard", 2], ["huntress", 2]],
			star_prince: [["rogue", 1], ["archer", 3]],
			blood_knight: [["warrior", 2], ["warrior", 1]],
			hex_queen: [["rogue", 2], ["necromancer", 3]],
			frost_warden: [["archer", 2]],
			flame_warden: [["knight", 3]],
			zealot_a: [["rogue", 3]],
			sentinel_a: [["huntress", 3]],
			// the Starfall Vault's masters carry Eldmere's own classes' sets
			ignis: [["alchemist", 0], ["bard", 3]],
			archivist: [["chronomancer", 1], ["bard", 1]],
			sovereign: [["alchemist", 2], ["chronomancer", 3]],
			astraeon: [["chronomancer", 0], ["bard", 0], ["alchemist", 1]],
			galecaller: [["archer", 1], ["huntress", 1], ["bard", 2]],
			tempestus: [["archer", 0], ["priest", 0], ["chronomancer", 2]],
			archon: [["warrior", 0], ["necromancer", 0], ["alchemist", 3]]
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

		/** A class's Godly piece: the same every time it drops. */
		public static function make(cls:String, slot:int):Object {
			var st:Object = SETS[cls];
			var c:Object = Data.CLASSES[cls];
			var it:Object;
			if (slot == 0) it = Data.makeWeapon(c.weapon, 7, "gd", "");
			else if (slot == 1) it = Data.makeAbility(c.abilityType, 7, "gd", st.ab);
			else if (slot == 2) it = Data.makeArmor(c.armor, 7, "gd");
			else it = Data.makeRing(st.ring, 5, "gd");
			it.name = st.items[slot];
			it.set = "g_" + cls;
			it.gid = cls + slot;
			it.gv = GV;
			// its four stats, led by a different one on each piece (a weapon's "spd" is its bullet speed: Vitality instead)
			for (var i:int = 0; i < 4; i++) {
				var k:String = st.focus[(i + slot) % 4];
				if (k == "spd" && slot == 0) k = "vit";
				it[k] = (it[k] || 0) + AMOUNTS[i];
			}
			it.hp = (it.hp || 0) + HP;
			it.frt = LUCK;
			if (slot == 0) {
				var x:Object = st.weapon;
				if (x.shots) { it.shots = x.shots; it.parallel = x.parallel == true; }
				if (x.arc != undefined) it.arc = x.arc;
				if (x.rate) it.rate = x.rate;
				if (x.motion) it.motion = x.motion;
				if (x.pierce) it.pierce = true;
				if (x.size) it.size = x.size;
				if (x.col) it.col = x.col;
				it.passive = x.passive;
				// a set share of the damage: POWER times a Primordial weapon of its type, whatever its shots
				var ar:Object = Data.makeWeapon(c.weapon, 7, "ar", "");
				var dps:Number = (ar.dmin + ar.dmax) / 2 * ar.shots * ar.rate * POWER;
				var avg:Number = dps / (it.shots * it.rate);
				it.dmin = int(avg * 0.88);
				it.dmax = int(avg * 1.12);
				delete it.form;
			}
			return it;
		}

		/** Whether an item is an older Godly piece (random stats) to be remade as it is now. */
		public static function outdated(it:Object):Boolean {
			return it && it.gid && it.rarity == "gd" && int(it.gv) != GV && SETS[String(it.set).substr(2)] != null;
		}

		/** Remakes an older Godly piece the way it drops now (its id and anything else of its own kept). True if it changed. */
		public static function upgrade(it:Object):Boolean {
			if (!outdated(it)) return false;
			var cls:String = String(it.set).substr(2);
			var slot:int = int(String(it.gid).substr(cls.length));
			if (slot < 0 || slot > 3) return false;
			var fresh:Object = make(cls, slot);
			// (everything that makes an item what it is goes; its sid, lock and the like stay)
			for each (var k:String in ["kind", "sub", "ab", "tier", "rarity", "set", "passive", "form", "motion", "shots", "dmin", "dmax", "rate", "life",
					"arc", "parallel", "power", "pierce", "size", "shape", "col", "spd", "accel", "walls", "effect", "split", "boom", "name", "gv"].concat(Data.STATS).concat(Data.GEAR_STATS))
				delete it[k];
			for (k in fresh) it[k] = fresh[k];
			return true;
		}

		/** The class whose Godly set an item belongs to ("" for none). */
		public static function classOf(it:Object):String {
			return it && it.rarity == "gd" && it.set && String(it.set).indexOf("g_") == 0 ? String(it.set).substr(2) : "";
		}

		/** A Godly weapon's Divine Wrath (or null). */
		public static function wrathOf(w:Object):Object {
			return w && w.kind == "weapon" ? WRATH[classOf(w)] : null;
		}

		/**
		 * How much more a Godly weapon can deal than its shots alone, from its Divine Wrath: every
		 * wrath shot landing on one monster, at the full set's pace (the server's caps: Data.weaponExtra).
		 */
		public static function wrathExtra(w:Object):Number {
			var x:Object = wrathOf(w);
			if (!x) return 0;
			var hits:Number = x.n * x.mul * (x.mo == "return" ? 2 : 1) + (x.boom ? x.boom.mul * 3 * x.n : 0) + (x.slam ? x.slam.mul : 0);
			return hits / (WRATH_SET * Math.max(1, w.shots || 1));
		}

		/** The biggest single wrath hit, in weapon hits. */
		public static function wrathHit(w:Object):Number {
			var x:Object = wrathOf(w);
			if (!x) return 0;
			return Math.max(x.mul, x.boom ? x.boom.mul : 0, x.slam ? x.slam.mul : 0);
		}

		/** Rolls a boss's Godly pieces (each 1 in 1,000, a little better with Luck). */
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
			var s:String = "";
			var x:Object = wrathOf(it);
			if (x) s += "<font color='#ffd860'><b>Divine Wrath — " + x.name + ":</b></font> every " + EVERY + "th volley " + x.desc + " (every " + WRATH_SET + "th with the full set).\n";
			if (classOf(it)) s += "<font color='#ffd860'>Wearing it: a golden aura; the full set crowns you with a halo.</font>\n";
			return s + "<font color='#fff6e0'>Godly: 1 in 1,000" + (src ? " from " + src : "") + ". Every drop is the same: no bad rolls.</font>\n";
		}
	}
}
