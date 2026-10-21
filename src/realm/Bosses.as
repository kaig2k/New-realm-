package realm {
	import flash.utils.Dictionary;

	/**
	 * Every boss fight: phase scripts, new bosses and their unique drops.
	 * Bosses.init() runs once at start-up and fills Data.ENEMIES / Data.DUNGEONS.
	 * Phase format and attack patterns are documented in Enemy.as.
	 */
	public class Bosses {
		private static var done:Boolean = false;

		// ------------------------------------------------------------ pattern helpers
		private static function o(base:Object, extra:Object):Object {
			if (extra) for (var k:String in extra) base[k] = extra[k];
			return base;
		}
		private static function aim(n:int, arc:Number, spd:Number, dmg:int, cd:Number, col:uint, x:Object = null):Object {
			return o({p: "aimed", n: n, arc: arc, spd: spd, life: 11 / spd, dmg: dmg, cd: cd, r: 0.22, col: col}, x);
		}
		private static function ring(n:int, rot:Number, spd:Number, dmg:int, cd:Number, col:uint, x:Object = null):Object {
			return o({p: "ring", n: n, rot: rot, spd: spd, life: 11 / spd, dmg: dmg, cd: cd, r: 0.22, col: col, shape: "ring"}, x);
		}
		private static function spiral(n:int, rot:Number, spd:Number, dmg:int, cd:Number, col:uint, x:Object = null):Object {
			return o({p: "spiral", n: n, rot: rot, spd: spd, life: 11 / spd, dmg: dmg, cd: cd, r: 0.2, col: col, shape: "star"}, x);
		}
		private static function flower(n:int, rot:Number, spd:Number, dmg:int, cd:Number, col:uint, x:Object = null):Object {
			return o({p: "flower", n: n, rot: rot, spd: spd, life: 11 / spd, dmg: dmg, cd: cd, r: 0.22, col: col, shape: "orb"}, x);
		}
		private static function wall(n:int, spd:Number, dmg:int, cd:Number, col:uint, x:Object = null):Object {
			return o({p: "wall", n: n, spd: spd, life: 13 / spd, dmg: dmg, cd: cd, r: 0.25, col: col, hole: 2, shape: "blade"}, x);
		}
		private static function nova(radius:Number, delay:Number, dmg:int, cd:Number, col:uint, x:Object = null):Object {
			return o({p: "nova", radius: radius, delay: delay, dmg: dmg, cd: cd, col: col, r: 0.22, burst: 8, bspd: 4, blife: 1.4}, x);
		}
		private static function rain(n:int, spread:Number, dmg:int, cd:Number, col:uint, x:Object = null):Object {
			return o({p: "rain", n: n, spread: spread, radius: 1.2, delay: 1.1, dmg: dmg, cd: cd, col: col, r: 0.2, burst: 0}, x);
		}
		private static function summon(what:String, n:int, cd:Number, max:int = 6):Object {
			return {p: "summon", what: what, n: n, cd: cd, max: max};
		}
		private static function P(hp:Number, x:Object):Object { return o({hp: hp}, x); }

		/** Adds or replaces fields of a boss (new bosses get sensible defaults). */
		/**
		 * Each raid's final boss carries a Primordial unique for many item types (between them, one for
		 * every weapon, armor, ability and ring there is), so each one rolls rarer than other uniques.
		 */
		public static const PRIMORDIAL_CHANCE:Number = 0.025;

		private static function boss(id:String, fields:Object, uniques:Array = null):void {
			var d:Object = Data.ENEMIES[id];
			if (!d) d = Data.ENEMIES[id] = {ai: "boss", r: 0.9, drop: 1, aggro: 14, range: 14, def: 20, spd: 1.4, xp: 1500};
			for (var k:String in fields) d[k] = fields[k];
			if (uniques) {
				d.uniques = uniques;
				for each (var u:String in uniques) { Uniques.source[u] = d.name; Uniques.bossOf[u] = id; }
			}
		}

		private static function mob(id:String, fields:Object):void {
			Data.ENEMIES[id] = o({ai: "chase", keep: 2, drop: 0, r: 0.4, def: 5, spd: 2, xp: 20}, fields);
		}

		/**
		 * Monster families fight in their own way:
		 * goblins throw spinning daggers that fly back to them, slimes burst into
		 * smaller slimes when they die, spiders spit webs that stick to the ground
		 * and slow you, ghosts drift (and shoot) through walls, and golems slam the
		 * ground in a shockwave you can see coming.
		 */
		private static function families():void {
			var E:Object = Data.ENEMIES;
			// the small slimes a slime splits into
			mob("slimelet", {name: "Slimelet", spr: "slimelet", hp: 14, def: 0, spd: 2.0, xp: 3, keep: 1, r: 0.28, col: 0x9aff7a,
				attacks: [aim(1, 0, 6, 5, 1.3, 0x9aff7a, {life: 0.6, r: 0.12, shape: "orb"})]});
			mob("green_slimelet", {name: "Green Slimelet", spr: "green_slimelet", hp: 45, def: 1, spd: 1.9, xp: 6, keep: 1, r: 0.32, col: 0x80e060,
				attacks: [aim(2, 20, 6, 9, 1.3, 0x9aff7a, {life: 0.7, r: 0.13, shape: "orb"})]});
			mob("ooze", {name: "Godly Ooze", spr: "ooze", hp: 420, def: 8, spd: 2.2, xp: 20, keep: 1.5, r: 0.38, col: 0xb070f0,
				attacks: [ring(6, 30, 4, 30, 1.6, 0xd0a0ff, {life: 1.2, r: 0.16, eff: "slowed"})]});
			E.slime.splits = {what: "slimelet", n: 2};
			E.green_slime.splits = {what: "green_slimelet", n: 3};
			E.slime_god.splits = {what: "ooze", n: 3};
			for (var id:String in E) {
				var d:Object = E[id];
				if (d.ai == "boss" || d.prop || d.crate) continue;
				var spr:String = d.spr;
				var list:Array = d.attacks;
				if (!list) continue;
				var top:int = 0;
				for each (var a0:Object in list) if (a0.dmg > top) top = a0.dmg;
				if (spr == "goblin" || spr == "goblin_chief") {
					// a spinning dagger thrown out that comes back
					list.push(aim(spr == "goblin" ? 1 : 3, 30, 7, int(top * 1.15), 2.4, 0xd8d8e0,
						{life: 1.1, r: 0.16, shape: "blade", spin: true, motion: "return", name: "spinning dagger", sfx: "toss"}));
				} else if (spr == "spider" || spr == "spider_queen") {
					// web spit: lands where you stand and stays sticky for a while
					list.push({p: "nova", reach: 8, radius: spr == "spider" ? 1.3 : 2, delay: 0.8, dmg: int(top * 0.5), cd: spr == "spider" ? 3.6 : 3,
						col: 0xe8e8f0, eff: "slowed", web: 4, name: "sticky web", sfx: "spit", land: "splat"});
				} else if (spr == "ghost" || spr == "ghost_god" || spr == "shade") {
					d.ghostly = true;
					for each (var ga:Object in list) if (ga.p != "summon") { ga.ghost = true; ga.sfx = "wail"; ga.sfxGap = 2.5; if (!ga.name) ga.name = "spectral " + Enemy.attackName(ga); }
				} else if (spr == "golem" || spr == "ogre") {
					// the ring becomes a ground slam: a warning circle, then the shockwave
					for (var gi:int = 0; gi < list.length; gi++) {
						var r0:Object = list[gi];
						if (r0.p != "ring") continue;
						list[gi] = {p: "nova", reach: 0, radius: 2.4, delay: 0.9, dmg: int(r0.dmg * 1.3), cd: r0.cd + 0.8, col: r0.col,
							burst: r0.n, bspd: r0.spd, blife: r0.life, name: "ground slam", land: "slam"};
					}
				}
			}
		}

		public static function init():void {
			if (done) return;
			done = true;
			art();
			minions();
			lowDungeons();
			midDungeons();
			events();
			siege();
			deep();
			hardDungeons();
			finales();
			raids();
			setPieces();
			families();
			harden();
			fair();
			Godly.init();
			skins();
		}

		/**
		 * Every boss must be dodgeable: no teleporting on top of you, gaps you
		 * can actually fit through, bullets you can react to. Hard, never unfair.
		 */
		private static function fair():void {
			for (var id:String in Data.ENEMIES) {
				var d:Object = Data.ENEMIES[id];
				if (d.ai != "boss") continue;
				var seen:Dictionary = new Dictionary();
				for each (var ph:Object in d.phases) {
					if (ph is Array) { fairList(ph as Array, seen); continue; }
					// bosses circle their arena instead of blinking around it
					if (ph.move == "teleport" || ph.move == "blink") ph.move = "orbit";
					if (ph.attacks) fairList(ph.attacks, seen);
					for each (var cl:Array in ph.cycle || []) fairList(cl, seen);
				}
			}
		}

		private static function fairList(list:Array, seen:Dictionary):void {
			for each (var a:Object in list) {
				if (!a || seen[a] || a.p == "summon") continue;
				seen[a] = true;
				// rings and flowers leave lanes to slip through
				if ((a.p == "ring" || a.p == "flower") && a.n > 28) a.n = 28;
				if (a.p == "spiral" && a.n > 10) a.n = 10;
				// walls always have a gap at least three bullets wide
				if (a.p == "wall" && (a.hole || 0) < 3) a.hole = 3;
				// fast enough to be scary, slow enough to see coming
				if (a.spd > 12) { a.spd = 12; a.life = 11 / 12; }
				if (a.motion == "home" && a.spd > 7) a.spd = 7;
				// a breath between volleys
				var floor:Number = a.p == "spiral" ? 0.08 : a.p == "aimed" ? 0.25 : 0.5;
				if (a.cd < floor) a.cd = floor;
				if (a.waves && a.gap && a.gap < 0.15) a.gap = 0.15;
			}
		}

		/**
		 * Endgame bosses (hard dungeons, finales, raids) hit harder, shoot faster
		 * and have much more health. Online they also scale with the players
		 * fighting them (see Game.scaleBosses).
		 */
		private static function harden():void {
			for (var id:String in Data.ENEMIES) {
				var d:Object = Data.ENEMIES[id];
				if (d.ai != "boss") continue;
				// every boss gets tougher with more people fighting it (WorldSim.scaleBosses)
				d.scales = true;
				var endgame:Boolean = d.raid || d.finale || d.final || d.dtier >= 5;
				if (!endgame) continue;
				// raids are the hardest fights in the game
				d.hp = int(d.hp * (d.raid ? 2.6 : 1.9));
				d.def = (d.def || 0) + (d.raid ? 14 : 10);
				var dm:Number = d.raid ? 1.5 : 1.35;
				var done:Dictionary = new Dictionary();
				for each (var ph:Object in d.phases) {
					var lists:Array = ph is Array ? [ph] : (ph.cycle || []).concat(ph.attacks ? [ph.attacks] : []);
					for each (var list:Array in lists) for each (var a:Object in list) {
						if (done[a] || a.p == "summon") continue;
						done[a] = true;
						a.dmg = int(a.dmg * dm);
						a.cd = a.cd * (a.cd < 0.3 ? 0.9 : 0.8);
						if (a.n && (a.p == "ring" || a.p == "flower")) a.n = int(a.n * 1.2);
						if (a.split && a.split.dmg) a.split.dmg = int(a.split.dmg * dm);
					}
				}
			}
		}

		/** Pop-culture style skins (original designs, recoloured class sprites). */
		private static function skins():void {
			var S:Object = Data.SKINS;
			S.wizard.push({id: "wizard_space", name: "Space Wizard", cost: 1500, pal: {R: 0x1a1a5a, r: 0x0a0a2a, Y: 0xc0c0d0, G: 0xff60ff, W: 0xa0e0ff}},
				{id: "wizard_vampire", name: "Vampire Lord", cost: 2500, pal: {R: 0x2a0a12, r: 0x14040a, S: 0xe8e0e8, E: 0xff2020, W: 0x8a0a1a, G: 0xff2040, Y: 0x3a3a3a}});
			S.archer.push({id: "archer_cyber", name: "Cyber Ranger", cost: 1500, pal: {G: 0x20e0ff, g: 0x1080a0, L: 0x2a2a34, l: 0x14141a, W: 0xff40c0, B: 0x0a0a10}},
				{id: "archer_outlaw", name: "Outlaw", cost: 2500, pal: {G: 0xa06a3a, g: 0x6a4020, L: 0x3a2a1a, l: 0x201408, W: 0x5a3a20}});
			S.knight.push({id: "knight_trooper", name: "Star Trooper", cost: 1500, pal: {H: 0xf4f4f8, h: 0xa0a0b0, M: 0xe8e8f0, m: 0x8a8a98, K: 0x101014, r: 0x2a2a30, Q: 0x303038, E: 0x101010}},
				{id: "knight_mecha", name: "Mecha Pilot", cost: 2500, pal: {H: 0x3a6ad0, h: 0x1a3a8a, M: 0xd03030, m: 0x8a1818, K: 0xffd040, Q: 0xffd040, E: 0x60ffff}});
			S.priest.push({id: "priest_idol", name: "Pop Idol", cost: 1500, pal: {W: 0xff8ad8, w: 0xc04a9a, Y: 0xffffff, G: 0x60e0ff}},
				{id: "priest_medic", name: "Wasteland Medic", cost: 2500, pal: {W: 0x8a8a6a, w: 0x5a5a40, Y: 0xd03030, G: 0x80ff60, B: 0x3a3020}});
			S.rogue.push({id: "rogue_ninja", name: "Ninja", cost: 1500, pal: {P: 0x14141a, p: 0x08080a, K: 0x22222a, k: 0x101014, W: 0xd02020, E: 0xffffff}},
				{id: "rogue_thief", name: "Phantom Thief", cost: 2500, pal: {P: 0x1a1a3a, p: 0x0a0a20, K: 0xf0f0f0, k: 0xb0b0c0, W: 0xd02040}});
			S.warrior.push({id: "warrior_barbarian", name: "Barbarian King", cost: 1500, pal: {H: 0xc08040, h: 0x8a5020, R: 0x2a6a2a, M: 0x8a6a3a, m: 0x5a4020, Y: 0xffd040}},
				{id: "warrior_gladiator", name: "Galactic Gladiator", cost: 2500, pal: {H: 0xe0e0f0, h: 0x9090a0, R: 0x6a2ad0, M: 0x40e0ff, m: 0x2080a0, Y: 0xffffff}});
			S.necromancer.push({id: "necro_zombie", name: "Zombie King", cost: 1500, pal: {D: 0x3a5a3a, d: 0x203a20, S: 0x8ab07a, E: 0xffe040, K: 0x6a1a6a, G: 0xd0c8a0}},
				{id: "necro_reaper", name: "Grim Reaper", cost: 2500, pal: {D: 0x0c0c10, d: 0x040406, S: 0xe8e8e8, E: 0x60e0ff, K: 0x404048, G: 0xc0c0c8}});
			S.huntress.push({id: "huntress_explorer", name: "Tomb Explorer", cost: 1500, pal: {R: 0x5a8ac0, r: 0x3a5a80, G: 0x8a6a3a, g: 0x5a4020}},
				{id: "huntress_neon", name: "Neon Hunter", cost: 2500, pal: {R: 0xff40c0, r: 0xa02080, G: 0x20e0ff, g: 0x1080a0, L: 0x2a2a34, W: 0xffff60}});
		}

		// ------------------------------------------------------------ art for new bosses
		// ------------------------------------------------------------ realm event set pieces
		/**
		 * Every realm event boss arrives with its own arena: a themed ground the
		 * game draws (style), and pieces the boss's host spawns around it:
		 *   ward    the boss can't be hurt while any of them stands
		 *   mend    each heals the boss (a fraction of its health per second)
		 *   hazard  turrets with their own attacks (smash them to calm the arena)
		 * All of it goes when the boss dies. hint is told to players when it appears.
		 */
		public static const SETPIECES:Object = {
			ev_cube: {style: "cube", prop: "cube_pylon", n: 4, r: 5.5, ward: true, hint: "Four Cube Pylons shield the Overlord. Destroy them to break the shield!"},
			ev_titan: {style: "lava", prop: "lava_vent", n: 4, r: 5.5, hint: "Lava vents erupt around the Titan. Smash them to cool the arena."},
			ev_wyrm: {style: "frost", prop: "ice_obelisk", n: 3, r: 5.5, hint: "Sylith's breath frosts the ground before it comes: get out of its path! Her ice obelisks keep healing her. Shatter them!"},
			ev_king: {style: "throne", prop: "royal_effigy", n: 4, r: 5.5, ward: true, hint: "The Hollow King's royal effigies make him untouchable. Topple them!"},
			ev_behemoth: {style: "bone", prop: "bone_stake", n: 6, r: 6.5, hint: "Gorehorn charges down a lane of red spikes: get out of it! Bait him into a bone stake and he's floored, open to every blow."},
			ev_regent: {style: "ghost", prop: "spectral_candle", n: 4, r: 5.5, ward: true, hint: "Spectral candles bind the Regent to this world. Snuff them out to hurt him!"},
			ev_sphinx: {style: "sand", prop: "sun_obelisk", n: 4, r: 6, hint: "Sun obelisks sweep the sands with light. Topple them to make the fight easier."},
			ev_lord: {style: "sunken", prop: "tidal_shrine", n: 3, r: 5.5, hint: "Tidal shrines pour the sea back into the Lord. Destroy them!"},
			ev_hermit: {style: "shell", prop: "clam_cannon", n: 4, r: 5.5, hint: "Clam cannons guard the Hermit's beach. Crack them open to stop the barrage."},
			ev_shrine: {style: "skull", prop: "bone_brazier", n: 4, r: 5.5, ward: true, hint: "Bone braziers feed the Skull Shrine. Douse all four to break its ward!"},
			ev_colossus: {style: "obsidian", prop: "obsidian_spire", n: 4, r: 6, hint: "Obsidian spires fire on anyone near the Colossus. Shatter them to make room."},
			ev_phoenix: {style: "fire", prop: "ember_nest", n: 3, r: 5.5, hint: "Ember nests rekindle Pyraxis. Smother them before the flames heal it whole!"},
			ev_witch: {style: "hex", prop: "hex_cauldron", n: 4, r: 5.5, ward: true, hint: "Mother Hexis brews her protection in four cauldrons. Smash them all!"},
			ev_kraken: {style: "reef", prop: "kraken_tentacle", n: 4, r: 5.5, hint: "The Kraken's tentacles lash out from the reef. Sever them to calm the waters."},
			// the Realm Siege: Vorgath's war camp, raised in the Godlands
			siege_warlord: {style: "siege", prop: "siege_ballista", n: 4, r: 6.5, hint: "Vorgath's war camp rises around him! Four siege ballistas guard it: break them and his guard storms out of the tents. Stay out of the trenches, and off the outer camp when it burns!"},
			// the Crimson Conclave and Heart of the Storm: their bosses' arenas change as they weaken
			matron: {style: "blood", prop: "blood_altar", n: 0, r: 6, hint: "The Matron's sanctum runs with blood: its channels will overflow, then its edges drown. Keep to the bone dais!"},
			archon: {style: "sanctum", prop: "blood_altar", n: 0, r: 6, hint: "Archon Vesper's altar answers him: its runes will bleed, then the floor floods. The golden circle is safe ground. Whoever he brands in blood must leave the group before it bursts."},
			galecaller: {style: "gale", prop: "storm_rod", n: 0, r: 6, hint: "The Galecaller's terrace will charge with lightning: off the runes when they crackle, and away from the edge!"},
			tempestus: {style: "storm", prop: "storm_rod", n: 0, r: 6, hint: "The eye of the storm closes as Tempestus weakens: its arms crackle, then its edge, and at the end only its heart is safe."},
			// the Starfall Vault (a raid): each chamber is a set piece of its own
			ignis: {style: "fire", prop: "ember_nest", n: 3, r: 5.5, hint: "Ember nests feed Ignis. Smother them, or he burns forever!"},
			archivist: {style: "sunken", prop: "tidal_shrine", n: 3, r: 5.5, hint: "The tidal shrines keep the Archivist whole. Break them before the archive floods!"},
			sovereign: {style: "skull", prop: "bone_brazier", n: 4, r: 5.5, ward: true, hint: "Four bone braziers shield the Sovereign. Douse them all to reach him!"},
			astraeon: {style: "star", prop: "star_pylon", n: 4, r: 6, ward: true, hint: "Astraeon draws power from four star pylons. Shatter them, then survive the Star Throne! When he eclipses the sky, watch the light of his falling stars."}
		};

		/** Where a boss's set-piece pieces stand: the P tiles of its layout (x, y is the boss's tile centre). */
		public static function setPieceSpots(id:String, x:Number, y:Number, w:World):Array {
			return SetPieces.spots(id, int(x), int(y));
		}

		private static function setPieces():void {
			var still:Object = {ai: "still", spd: 0, r: 0.6, aggro: 13, range: 12, drop: 0, xp: 90, keep: 0, prop: true};
			// wards: the boss is immune while one stands
			mob("cube_pylon", o(o({}, still), {name: "Cube Pylon", spr: "cube_pylon", hp: 2400, def: 14, col: 0xff60ff, ward: true,
				attacks: [ring(6, 30, 4, 45, 1.6, 0xff60ff, {shape: "star"})]}));
			mob("royal_effigy", o(o({}, still), {name: "Royal Effigy", spr: "royal_effigy", hp: 2400, def: 16, col: 0xffd060, ward: true,
				attacks: [aim(3, 20, 8, 50, 1.5, 0xffd060)]}));
			mob("spectral_candle", o(o({}, still), {name: "Spectral Candle", spr: "spectral_candle", hp: 2000, def: 10, col: 0x90c0ff, ward: true,
				attacks: [spiral(2, 17, 4, 40, 0.5, 0x90c0ff)]}));
			mob("bone_brazier", o(o({}, still), {name: "Bone Brazier", spr: "bone_brazier", hp: 2400, def: 14, col: 0xb060ff, ward: true,
				attacks: [ring(8, 22, 4.5, 45, 1.8, 0xb060ff)]}));
			mob("hex_cauldron", o(o({}, still), {name: "Hex Cauldron", spr: "hex_cauldron", hp: 2200, def: 12, col: 0x70e050, ward: true,
				attacks: [aim(1, 0, 6, 55, 1.4, 0x70e050, {eff: "slowed", r: 0.3})]}));
			// menders: heal the boss while they stand
			mob("ice_obelisk", o(o({}, still), {name: "Ice Obelisk", spr: "ice_obelisk", hp: 2600, def: 14, col: 0x9ad8ff, mend: 0.006,
				attacks: [spiral(2, 13, 4, 40, 0.6, 0x9ad8ff, {eff: "slowed"})]}));
			// Gorehorn's bone stakes: nothing breaks them, but a charging Gorehorn that rams one is floored (Enemy.stakeStun)
			mob("bone_stake", o(o({}, still), {name: "Bone Stake", spr: "bone_stake", hp: 99999, def: 99, col: 0xe6cfa8, stake: true, invuln: true, xp: 0, aggro: 0, range: 0, attacks: []}));
			mob("war_drum", o(o({}, still), {name: "War Drum", spr: "war_drum", hp: 2600, def: 16, col: 0xe8d0a0, mend: 0.006,
				attacks: [ring(10, 18, 3.5, 45, 2.2, 0xe8d0a0, {shape: "ring"})]}));
			mob("tidal_shrine", o(o({}, still), {name: "Tidal Shrine", spr: "tidal_shrine", hp: 2600, def: 14, col: 0x40d0c0, mend: 0.006,
				attacks: [aim(5, 60, 6, 40, 2, 0x40d0c0, {motion: "wave"})]}));
			mob("ember_nest", o(o({}, still), {name: "Ember Nest", spr: "ember_nest", hp: 2400, def: 12, col: 0xff8030, mend: 0.008,
				attacks: [rain(2, 3, 55, 3, 0xff8030)]}));
			// hazards: turrets with their own attacks
			mob("lava_vent", o(o({}, still), {name: "Lava Vent", spr: "lava_vent", hp: 3000, def: 18, col: 0xff6020,
				attacks: [ring(12, 15, 5, 55, 2.4, 0xff6020), nova(2, 1.2, 70, 4.5, 0xff8030, {burst: 6})]}));
			mob("sun_obelisk", o(o({}, still), {name: "Sun Obelisk", spr: "sun_obelisk", hp: 3000, def: 18, col: 0xffe080,
				attacks: [spiral(3, 9, 6, 45, 0.25, 0xffe080, {shape: "blade"})]}));
			mob("clam_cannon", o(o({}, still), {name: "Clam Cannon", spr: "clam_cannon", hp: 2800, def: 16, col: 0xffb0c0,
				attacks: [aim(4, 30, 8, 50, 1.6, 0xffe0f0, {waves: 2, gap: 0.25})]}));
			mob("obsidian_spire", o(o({}, still), {name: "Obsidian Spire", spr: "obsidian_spire", hp: 3200, def: 22, col: 0xff7030,
				attacks: [aim(1, 0, 10, 70, 0.9, 0xff7030, {shape: "blade", r: 0.28}), ring(8, 0, 4, 50, 3, 0x402030)]}));
			mob("kraken_tentacle", o(o({}, still), {name: "Kraken Tentacle", spr: "kraken_tentacle", hp: 2800, def: 14, col: 0xff80a0,
				attacks: [aim(3, 25, 7, 50, 1.3, 0xff80a0, {motion: "wave"})]}));
			// reinforcements that come out when an arena changes (SetPieces.PHASES)
			mob("cube_shard", {name: "Cube Shard", spr: "cube_shard", hp: 1400, def: 14, spd: 3.2, xp: 90, col: 0xff60ff, ai: "orbit", keep: 4,
				attacks: [aim(2, 16, 9, 60, 1.1, 0xff60ff, {shape: "star"})]});
			mob("royal_guard", {name: "Royal Guard", spr: "royal_guard", hp: 2400, def: 22, spd: 2.4, xp: 120, col: 0xffd060, keep: 2,
				attacks: [aim(3, 24, 8, 70, 1.3, 0xffd060, {shape: "blade"}), ring(8, 0, 4.5, 50, 3, 0xe8e0c0)]});
			mob("grave_wraith", {name: "Grave Wraith", spr: "grave_wraith", hp: 1600, def: 10, spd: 3, xp: 100, col: 0x90c0ff, ai: "orbit", keep: 5,
				attacks: [aim(1, 0, 7, 75, 1, 0x90c0ff, {eff: "slowed", motion: "wave"})]});
			mob("war_orc", {name: "Gorehorn's Warrior", spr: "war_orc", hp: 2200, def: 20, spd: 2.6, xp: 110, col: 0xff6040, keep: 1.5,
				attacks: [aim(4, 40, 8, 65, 1.4, 0xe8d0a0), aim(1, 0, 10, 90, 2.4, 0xff6040, {eff: "bleeding"})]});
			mob("temple_scorpion", {name: "Temple Scorpion", spr: "temple_scorpion", hp: 1200, def: 16, spd: 3.6, xp: 90, col: 0xffe080, keep: 1,
				attacks: [aim(2, 20, 10, 55, 0.9, 0xc0ff60, {eff: "slowed"})]});
			mob("star_pylon", o(o({}, still), {name: "Star Pylon", spr: "star_pylon", hp: 4000, def: 22, col: 0xffd060, ward: true,
				attacks: [ring(8, 22, 5, 80, 1.6, 0xffd060, {shape: "star"}), aim(2, 14, 9, 70, 1.2, 0xfff0a0)]}));
			mob("star_guard", {name: "Star Guard", spr: "star_guard", hp: 3600, def: 26, spd: 2.6, xp: 160, col: 0xffd060, keep: 2,
				attacks: [aim(3, 22, 9, 85, 1.2, 0xfff0a0, {shape: "blade"}), ring(10, 0, 5, 70, 2.6, 0xffd060, {shape: "star"})]});
			for (var id:String in SETPIECES) Data.ENEMIES[id].setpiece = SETPIECES[id];
		}

		private static function art():void {
			SetPieces.art();
			// the Starfall Vault
			Sprites.recolor("star_pylon", "crystal", {W: 0xffffff, C: 0xffd060, c: 0xb08020, D: 0x5a3a08, S: 0x34325a}, 6);
			Sprites.recolor("star_guard", "bandit", {H: 0xe8e0ff, h: 0x8a80c0, S: 0xfff4d0, E: 0xffd060, B: 0x5a50a0, b: 0x34306a, A: 0xffd060, L: 0x2a2850, W: 0xfff6a0});
			Sprites.recolor("vault_ignis", "flame_warden", {H: 0xffb040, h: 0xa04010, E: 0xffffff, G: 0xffffa0, A: 0x2a0800, M: 0xff6a20, m: 0x8a2a10, L: 0xffe060, l: 0xd0d0d0});
			Sprites.recolor("vault_archivist", "sunken_lord_flat", {S: 0x3a7a8a, s: 0x1a4050, B: 0xe8f0d8, E: 0x40ffd0, G: 0xa0fff0, W: 0x60c0a0, H: 0x2a6a5a});
			Sprites.recolor("vault_sovereign", "lich_king", {Y: 0xe8e0c8, B: 0xe8e0c8, E: 0xc060ff, R: 0x9a2030, T: 0x4a4050, P: 0x6a1a2a, p: 0x3a0a14, G: 0xb060ff});
			Sprites.recolor("astraeon", "star_prince", {H: 0xf0c840, h: 0x9a7020, S: 0xfff4d0, E: 0x2a1060, W: 0xffffff, R: 0xd0a030, r: 0x6a4a10, O: 0xfff6a0, o: 0xffffff}, 6);
			Sprites.recolor("cube_shard", "cubelet", {P: 0xff60ff, p: 0xa020c0, Q: 0xffc0ff, E: 0x46c0e8});
			Sprites.recolor("royal_guard", "bandit", {H: 0xd8b050, h: 0x8a6a20, S: 0xe8e0c0, E: 0x40c0ff, B: 0xc8c8d0, b: 0x8a8a96, A: 0x8a1a2a, L: 0x5a5a66, W: 0xffe080});
			Sprites.recolor("grave_wraith", "ghost", {W: 0x9ab0ff, w: 0x5a6aa8, E: 0xffffff}, 4);
			Sprites.recolor("war_orc", "orc", {H: 0x7a9a3a, h: 0x4a6a24, E: 0xffe040, B: 0xc8a878, b: 0x8a6a40, A: 0xe8e0c8, L: 0x3a2410, W: 0xe8e0c8, S: 0x7a9a3a});
			Sprites.recolor("temple_scorpion", "scorpion", {C: 0xd8b060, S: 0xf0d090, T: 0x9a7030, E: 0x60ff40});
			// realm event set-piece pieces
			Sprites.recolor("cube_pylon", "crystal", {W: 0xffe0ff, C: 0xff60ff, c: 0xa020c0, D: 0x50106a, S: 0x2a1a3a}, 6);
			Sprites.recolor("royal_effigy", "pillar", {L: 0xffe080, l: 0xb08a30, S: 0xd8b050, s: 0x806020});
			Sprites.recolor("spectral_candle", "brazier", {Y: 0xe0f0ff, F: 0x80b0ff, W: 0xffffff, S: 0x6a7a9a, s: 0x3a4a6a});
			Sprites.recolor("bone_brazier", "brazier", {Y: 0xf0c0ff, F: 0xb060ff, W: 0xffffff, S: 0xe8e0c8, s: 0xa09880});
			Sprites.recolor("hex_cauldron", "campfire", {Y: 0xc0ff80, F: 0x60d040, W: 0xe0ffd0, K: 0x2a2a30, k: 0x18181c});
			Sprites.recolor("ice_obelisk", "crystal", {W: 0xffffff, C: 0x9ad8ff, c: 0x4a90d0, D: 0x204a80, S: 0x1a2a3a}, 6);
			Sprites.recolor("war_drum", "totem", {K: 0xc8a878, k: 0x8a6a40, E: 0xff4020, R: 0xe8e0c8});
			Sprites.recolor("tidal_shrine", "crystal", {W: 0xd0fff8, C: 0x40d0c0, c: 0x188a80, D: 0x0a4a48, S: 0x10282a}, 6);
			Sprites.recolor("ember_nest", "nest", {W: 0xffe080, w: 0xff9030, S: 0xff4010, K: 0x5a2a10, k: 0x3a1808}, 6);
			Sprites.recolor("lava_vent", "brazier", {Y: 0xffe060, F: 0xff4010, W: 0xffffff, S: 0x3a2a2a, s: 0x1e1414});
			Sprites.recolor("sun_obelisk", "pillar", {L: 0xf0d8a0, l: 0xb09060, S: 0xd8bc80, s: 0x907048});
			Sprites.recolor("clam_cannon", "totem", {K: 0xffb0c0, k: 0xc07080, E: 0xffffff, R: 0x60c0ff});
			Sprites.recolor("obsidian_spire", "crystal", {W: 0xffa060, C: 0x302030, c: 0x1a101a, D: 0x0a060a, S: 0xff6020}, 7);
			Sprites.recolor("kraken_tentacle", "totem", {K: 0xff80a0, k: 0xb04060, E: 0xffe0f0, R: 0x8a2040});
			Sprites.recolor("loot_goblin", "goblin", {H: 0x70b840, h: 0x4a8a28, E: 0xffe020, B: 0xc8962a, b: 0x8a6418, A: 0xffe060, L: 0x5a3a14, W: 0xffe060, S: 0x70b840});
			// raid monsters
			Sprites.recolor("cultist", "bandit", {H: 0x8a0a1a, h: 0x5a0610, S: 0xe8d0c0, E: 0xffe040, B: 0xa01428, b: 0x6a0a18, A: 0xf0c030, L: 0x2a0408, W: 0xff3040});
			Sprites.recolor("bone_thrall", "skeleton", {H: 0xe8e0c8, h: 0xa09880, S: 0xe8e0c8, E: 0xff2020, B: 0x8a1a1a, b: 0x5a0a0a, A: 0xd02030, L: 0xb0a890, W: 0xe8e0c8});
			Sprites.recolor("blood_hound", "wolf", {W: 0x9a1a24, w: 0x5a0a10, E: 0xffe040});
			Sprites.recolor("gale_harpy", "harpy", {H: 0xd8f0ff, E: 0x2040ff, W: 0x6ab0e0, B: 0x3a7ab0, Y: 0xffff80});
			Sprites.recolor("thunder_golem", "golem", {H: 0x6a6a8a, h: 0x40405a, E: 0xffff60, B: 0x5a5a7a, b: 0x3a3a50, A: 0xffff60, L: 0x2a2a3a, W: 0x5a5a7a, S: 0x6a6a8a}, 6);
			Sprites.recolor("cloud_serpent", "great_snake", {G: 0xe8f4ff, g: 0x8ab0d0, E: 0x40c0ff}, 6);
			Sprites.recolor("colossus", "titan_flat", {R: 0x2a2a34, r: 0x141418, Y: 0xc070ff, L: 0x8030ff}, 6);
			Sprites.recolor("phoenix", "seraph", {Y: 0xffd040, W: 0xff8030, S: 0xffe0a0, E: 0x601000, G: 0xff4010, g: 0xa02008}, 6);
			Sprites.recolor("witch", "lich_king", {Y: 0x80ff60, B: 0x3a2a4a, E: 0xc0ff40, R: 0xff60ff, T: 0x2a2a2a, P: 0x2a6a2a, p: 0x143a14, G: 0xff80ff}, 5);
			Sprites.recolor("kraken", "hermit_flat", {S: 0x6a3a8a, s: 0x3a1a5a, C: 0xff6080, c: 0xa02040, E: 0xffe040, W: 0xffffff}, 6);
			Sprites.recolor("gearmind", "boss_flat", {Y: 0xc0a060, y: 0x806030, Q: 0x60e0ff, P: 0x6a6a72, p: 0x3a3a42, W: 0xffffff, E: 0x40ff80, K: 0x101010}, 6);
			Sprites.recolor("void_dragon", "wyrm", {C: 0x4a2a7a, c: 0x1a0a2a, W: 0xc080ff, w: 0x8040c0, E: 0xff40ff, K: 0xffffff}, 7);
			Sprites.recolor("matron", "regent_flat", {Y: 0xff4040, y: 0xa01010, C: 0x6a0a1a, c: 0x3a0008, Q: 0xffd0d0, E: 0xff2020, W: 0xffa0a0, M: 0x8a2030, m: 0x5a1020}, 6);
			Sprites.recolor("zealot", "sorcerer", {H: 0xa01828, h: 0x5a0a14, S: 0xf5dc72, E: 0x101010, W: 0xf0f0f0, R: 0xc02030, r: 0x6a0a18, O: 0xff8080, o: 0xffffff}, 4);
			Sprites.recolor("galecaller", "seraph", {Y: 0x80ffff, W: 0xd0f0ff, S: 0xf5dc72, E: 0x2040a0, G: 0x60a0ff, g: 0x3060c0}, 5);
			Sprites.recolor("bag_godly", "bag_relic", {K: 0x8a6a20, C: 0xfff6e0, c: 0xd8c8a0, D: 0xf2cc6a});
			Sprites.recolor("raidtable", "chest", {K: 0x2a0810, C: 0xa01830, c: 0x6a0a1c, Y: 0xffd040}, 6);
			Sprites.recolor("sentinel", "warden", {H: 0xe0e080, h: 0x8a8a40, E: 0xffff40, G: 0xffffff, A: 0x203050, M: 0x6080c0, m: 0x304070, L: 0xffff60, l: 0xd0d0d0}, 4);
			// the Endless Abyss
			Sprites.recolor("abyss_chest", "chest", {K: 0x1a0a2a, C: 0x8040c0, c: 0x4a1a7a, Y: 0xff80ff}, 6);
			// the Godlands Spires (guild territory)
			Sprites.recolor("godspire", "crystal", {W: 0xffffff, C: 0xd8e8ff, c: 0x8aa0c8, D: 0x4a5a7a, S: 0x7fd8ff}, 9);
			// the Realm Siege
			// (Vorgath and his ballistas have designs of their own: BossArt)
			Sprites.recolor("siege_soldier", "bandit", {H: 0x7a7a86, h: 0x4a4a56, S: 0xd8c0a0, E: 0xff6010, B: 0x5a1a10, b: 0x3a0a06, A: 0xffa020, L: 0x2a2a30, W: 0xc0c0d0});
			// every boss its own design (tools/bossart), drawn over the recoloured stand-ins above
			BossArt.register();
		}

		private static function minions():void {
			mob("gear_drone", {name: "Gear Drone", spr: "cubelet", hp: 900, def: 12, spd: 3, xp: 60, col: 0xc0a060, keep: 3,
				attacks: [aim(3, 30, 8, 60, 1.2, 0xffd060, {shape: "star"})]});
			mob("tide_spawn", {name: "Tidespawn", spr: "slime", hp: 1100, def: 10, spd: 2.2, xp: 60, col: 0x40a0ff,
				attacks: [ring(8, 22, 4.5, 55, 1.6, 0x60c0ff)]});
			mob("void_wisp", {name: "Void Wisp", spr: "shade", hp: 800, def: 8, spd: 3.4, xp: 60, col: 0xc040ff, ai: "orbit", keep: 4,
				attacks: [aim(1, 0, 9, 70, 0.9, 0xff40ff, {motion: "home"})]});
			mob("blood_acolyte", {name: "Blood Acolyte", spr: "imp", hp: 1400, def: 10, spd: 2.6, xp: 80, col: 0xd02030,
				attacks: [aim(3, 24, 8, 70, 1.1, 0xff3040, {eff: "bleeding"})]});
			// breakable crates, and the Mimics that hide among them
			mob("crate", {name: "Crate", spr: "crate", hp: 260, def: 0, spd: 0, xp: 4, col: 0xa0703a, ai: "still", aggro: 0, range: 0, r: 0.45, attacks: [], crate: true});
			mob("mimic", {name: "Mimic", spr: "mimic", hp: 2400, def: 12, spd: 3.4, xp: 260, col: 0xc02020, ai: "chase", keep: 1.5, aggro: 12, drop: 0.9, mimic: true,
				attacks: [ring(10, 18, 5, 60, 1.6, 0xffd040), aim(3, 30, 8, 70, 1.1, 0xff4040)]});
			// a rare thief that runs from you with a sack of loot (see Game.updateGoblin)
			mob("loot_goblin", {name: "Treasure Goblin", spr: "loot_goblin", hp: 1500, def: 8, spd: 5, xp: 300, col: 0xf0c030, ai: "flee", aggro: 11,
				attacks: [], goblin: true, gold: 120});
			// raid guards: the toughest ordinary monsters in the game
			mob("crimson_cultist", {name: "Crimson Cultist", spr: "cultist", hp: 3000, def: 18, spd: 2.4, xp: 160, col: 0xa01428, ai: "orbit", keep: 5,
				attacks: [aim(3, 20, 8.5, 90, 1.0, 0xff3040, {eff: "bleeding"}), ring(8, 22, 4.5, 75, 2.4, 0xd02030)]});
			mob("bone_thrall", {name: "Bone Thrall", spr: "bone_thrall", hp: 4200, def: 26, spd: 1.8, xp: 180, col: 0xe8e0c8, keep: 2.5,
				attacks: [aim(5, 50, 7, 85, 1.3, 0xe8e0c8, {shape: "blade"}), aim(1, 0, 6, 100, 2.2, 0xff4040, {motion: "home", r: 0.28})]});
			mob("blood_hound", {name: "Blood Hound", spr: "blood_hound", hp: 2000, def: 12, spd: 4.4, xp: 120, col: 0x9a1a24, keep: 1,
				attacks: [aim(1, 0, 11, 95, 0.6, 0xff3040, {eff: "bleeding"}), ring(6, 30, 5, 65, 1.8, 0xd02030)]});
			mob("gale_harpy", {name: "Gale Harpy", spr: "gale_harpy", hp: 2400, def: 12, spd: 4, xp: 140, col: 0x6ab0e0, ai: "orbit", keep: 4.5,
				attacks: [aim(3, 30, 9.5, 85, 0.9, 0x80ffff, {motion: "wave"})]});
			mob("thunder_golem", {name: "Thunder Golem", spr: "thunder_golem", hp: 5200, def: 30, spd: 1.4, xp: 200, col: 0xffff60, keep: 2,
				attacks: [ring(12, 15, 5, 90, 1.9, 0xffff60, {eff: "paralyzed"}), aim(1, 0, 13, 110, 1.4, 0xffffff, {shape: "blade"})]});
			mob("cloud_serpent", {name: "Cloud Serpent", spr: "cloud_serpent", hp: 3000, def: 14, spd: 2.8, xp: 150, col: 0xd0f0ff, ai: "orbit", keep: 4,
				attacks: [spiral(2, 40, 6.5, 80, 0.22, 0xe8f4ff), aim(3, 40, 7, 80, 1.6, 0x40c0ff)]});
			mob("storm_wisp", {name: "Storm Wisp", spr: "sprite", hp: 1000, def: 8, spd: 3.6, xp: 70, col: 0xffff60, ai: "orbit", keep: 3.5,
				attacks: [spiral(2, 30, 7, 60, 0.35, 0xffff80)]});
		}

		// ------------------------------------------------------------ easy dungeons
		private static function lowDungeons():void {
			boss("cove_boss", {hp: 2600, phases: [
				P(1, {move: "wander", attacks: [aim(3, 22, 7, 18, 1.0, 0x303030, {shape: "orb", r: 0.26}), ring(8, 15, 4, 14, 2.4, 0xe0b060)]}),
				P(0.6, {say: "All hands! Fire the broadside!", shield: 1.5, move: "center",
					attacks: [wall(9, 5, 20, 2.2, 0x303030, {shape: "orb"}), summon("pirate", 2, 6, 5)]}),
				P(0.25, {say: "Ye'll be sleepin' with the fishes!", banner: "Saltbeard is furious!", move: "chase", speed: 1.4,
					attacks: [aim(5, 60, 7, 20, 1.4, 0x303030, {shape: "orb", waves: 3, gap: 0.25}), rain(4, 3, 30, 3, 0xff8030)]})
			]}, ["saltbeard_cutlass", "parrot_charm", "powder_keg"]);

			boss("moth_boss", {hp: 4500, phases: [
				P(1, {move: "orbit", attacks: [flower(10, 9, 4.5, 25, 1.2, 0xe0d8a0), aim(1, 0, 6, 30, 1.6, 0xff8040, {motion: "home", r: 0.26})]}),
				P(0.66, {say: "My children... feast!", summon: [{what: "mothling", n: 4}], move: "orbit",
					attacks: [spiral(3, 17, 5, 22, 0.16, 0xc8c090, {eff: "slowed"}), summon("mothling", 2, 7, 6)]}),
				P(0.33, {say: "Into the light, little ones!", shield: 2, move: "teleport",
					attacks: [flower(16, 7, 5, 28, 1.0, 0xfff0a0), rain(5, 4, 35, 2.6, 0xff8040)]})
			]}, ["lantern_wand", "mothwing_cloak", "dustveil_robe"]);

			boss("serpent_boss", {hp: 6500, phases: [
				P(1, {move: "wander", attacks: [aim(3, 26, 6, 40, 0.75, 0x60e060, {motion: "wave"}), ring(12, 13, 4, 34, 1.5, 0x2a9a6a, {eff: "slowed"})]}),
				P(0.66, {say: "Ssslither... and die.", shield: 2, move: "orbit",
					attacks: [spiral(3, 23, 5.5, 36, 0.12, 0x80ff80, {motion: "wave"}), summon("great_snake", 2, 8, 4)]}),
				P(0.33, {say: "The pit hungers!", move: "chase", speed: 1.3,
					attacks: [wall(11, 6, 45, 1.6, 0x40c040, {eff: "bleeding"}), aim(7, 70, 7, 40, 1.1, 0xa0ffa0)]})
			]}, ["fang_of_ssythra", "venom_quiver", "scaled_hide"]);

			boss("spider_boss", {hp: 7000, phases: [
				P(1, {move: "wander", attacks: [ring(16, 11, 2.5, 30, 1.6, 0xe0e0e0, {motion: "accel", accel: 0.9, life: 3}),
					aim(1, 0, 9, 40, 2.0, 0xffffff, {eff: "paralyzed", r: 0.28})]}),
				P(0.6, {say: "Into my web!", summon: [{what: "spider", n: 4}], move: "center",
					attacks: [rain(6, 4, 40, 2.6, 0xd0c040, {burst: 6, bspd: 3.5, eff: "slowed"}), summon("spider", 2, 6, 8)]}),
				P(0.3, {say: "I will wrap you in silk!", shield: 1.5, move: "charge", speed: 1.6,
					attacks: [flower(20, 9, 5, 35, 1.0, 0xff3030), aim(3, 20, 9, 38, 1.5, 0xffffff, {waves: 4, gap: 0.15})]})
			]}, ["widowmaker", "silkspinner", "chitin_mail"]);
		}

		// ------------------------------------------------------------ endgame dungeons
		private static function midDungeons():void {
			boss("warden", {hp: 11000, phases: [
				P(1, {move: "wander", attacks: [aim(5, 50, 7, 55, 1.0, 0x6ad0ff, {shape: "star", eff: "paralyzed"}), summon("skeleton", 2, 7, 6)]}),
				P(0.7, {say: "The crypt keeps its dead.", shield: 2.5, move: "center", every: 5,
					cycle: [[ring(20, 9, 4.5, 55, 1.0, 0x9ae8ff), aim(1, 0, 12, 90, 0.7, 0xffffff, {shape: "blade", r: 0.3})],
						[wall(13, 5, 70, 1.6, 0x6ad0ff, {waves: 2, gap: 0.6})]]}),
				P(0.35, {banner: "The Warden awakens!", say: "Join them.", move: "chase",
					attacks: [spiral(5, 12, 6, 60, 0.13, 0x6ad0ff), nova(2, 1.1, 90, 2.5, 0x40e0ff, {burst: 10})]})
			]}, ["wardens_lantern", "cryptkeeper_blade", "gravebind_ring"]);

			boss("pyrelord", {hp: 12000, phases: [
				P(1, {move: "wander", attacks: [rain(5, 4, 70, 3, 0xff6010, {burst: 6}), aim(3, 24, 9, 60, 0.9, 0xffd040)]}),
				P(0.66, {say: "BURN!", shield: 2, move: "orbit",
					attacks: [spiral(4, -15, 6, 60, 0.12, 0xff4010), aim(3, 30, 6, 70, 1.6, 0xffb030, {split: {n: 8, spd: 5, life: 1.2, dmg: 45}, life: 1.2, r: 0.3})]}),
				P(0.3, {say: "The depths erupt!", banner: "Ignaar ignites!", move: "still",
					attacks: [flower(30, 6, 5, 60, 1.0, 0xffd040), rain(8, 6, 80, 2.4, 0xff3010, {burst: 4})]})
			]}, ["emberheart_staff", "magma_plate", "cinder_ring"]);

			boss("seraph", {hp: 10000, phases: [
				P(1, {move: "orbit", attacks: [spiral(3, 19, 7, 55, 0.12, 0xfff060, {shape: "dart"}), aim(3, 30, 9, 70, 1.1, 0xffffff, {shape: "blade", name: "gale blades"})]}),
				P(0.66, {say: "Feel the storm!", move: "teleport",
					attacks: [aim(1, 0, 15, 100, 0.5, 0xffffff, {shape: "blade", eff: "paralyzed", r: 0.3}), wall(15, 6, 60, 1.8, 0xd0d0ff)]}),
				P(0.33, {say: "Thunder answers me!", shield: 2, move: "center", every: 4,
					cycle: [[flower(24, 11, 6, 60, 0.8, 0xfff060)], [rain(7, 5, 80, 1.5, 0xffff80, {delay: 0.9})]]})
			]}, ["stormcall_bow", "tempest_quiver", "thunderhide"]);

			boss("sorcerer", {hp: 11000, phases: [
				P(1, {move: "teleport", attacks: [aim(3, 12, 10, 45, 0.35, 0x4080ff), aim(5, 60, 7, 55, 1.4, 0xffffff, {eff: "confused"})]}),
				P(0.66, {say: "Which one of me is real?", summon: [{what: "hobbit", n: 3}], move: "orbit",
					attacks: [aim(2, 40, 6, 60, 1.2, 0x80c0ff, {motion: "home", r: 0.26}), ring(14, 13, 5, 50, 0.9, 0xff4040)]}),
				P(0.33, {say: "Enough tricks.", shield: 2, move: "center",
					attacks: [aim(3, 10, 12, 120, 0.9, 0x2040c0, {shape: "blade", r: 0.3}), spiral(4, 16, 6, 55, 0.14, 0x80c0ff, {eff: "paralyzed"}),
						nova(1.8, 1, 90, 3, 0x6080ff)]})
			]}, ["illusionist_wand", "mirror_cloak", "arcane_vestments"]);

			boss("lich_boss", {hp: 13000, phases: [
				P(1, {move: "wander", attacks: [aim(3, 20, 6, 60, 1.0, 0x40ff90, {motion: "home"}), summon("skeleton", 2, 6, 6)]}),
				P(0.66, {say: "Rise, my servants!", shield: 3, summon: [{what: "lich", n: 2}], move: "center",
					attacks: [ring(24, 7.5, 4, 55, 1.2, 0xff4060), rain(4, 3, 80, 2.6, 0x40ff90, {burst: 6})]}),
				P(0.33, {say: "Death is only the beginning!", banner: "Septorius unleashes the dead!", move: "orbit",
					attacks: [spiral(6, -10, 6, 60, 0.11, 0x60e0ff), wall(13, 5, 75, 2.2, 0xe8e0c8, {waves: 2, gap: 0.5}), summon("ghost", 2, 8, 6)]})
			]}, ["phylactery", "soulreaper", "deathshroud"]);

			boss("demon_boss", {hp: 14000, phases: [
				P(1, {move: "chase", speed: 0.8, attacks: [aim(5, 56, 7.5, 70, 1.1, 0xff6020), rain(4, 3, 80, 2.4, 0xff3010, {burst: 6})]}),
				P(0.66, {say: "Kneel before the Abyss!", shield: 2, summon: [{what: "lesser_demon", n: 3}], move: "charge", speed: 1.4,
					attacks: [flower(20, 9, 5.5, 65, 1.0, 0xff8040), aim(1, 0, 11, 110, 0.8, 0xffe040, {shape: "blade", r: 0.3, eff: "armorbroken"})]}),
				P(0.3, {say: "I AM THE ABYSS!", banner: "Malgoroth rages!", move: "center",
					attacks: [spiral(5, 13, 6, 65, 0.12, 0xff4020), nova(2.5, 1.2, 120, 2.4, 0xff2010, {burst: 8}), wall(15, 5.5, 80, 2.8, 0xffb030, {hole: 3})]})
			]}, ["hellfire_blade", "infernal_helm", "brimstone_ring"]);

			boss("sprite_boss", {hp: 11000, phases: [
				P(1, {move: "orbit", speed: 1.3, attacks: [flower(12, 13, 6, 45, 0.7, 0xff80d0), aim(3, 30, 9, 50, 0.8, 0x80ffd0)]}),
				P(0.6, {say: "Dance with me!", move: "teleport", summon: [{what: "sprite", n: 4}],
					attacks: [spiral(4, 23, 7, 50, 0.1, 0xc0f0ff), aim(1, 0, 7, 60, 1.2, 0xff60c0, {motion: "home"})]}),
				P(0.25, {say: "A rainbow just for you!", shield: 2, move: "center", every: 3.5,
					cycle: [[flower(18, 10, 6, 55, 0.6, 0xff60c0)], [flower(18, -10, 6, 55, 0.6, 0x60c0ff)], [flower(18, 10, 6, 55, 0.6, 0xc0ff60)]]})
			]}, ["prismatic_wand", "fae_quiver", "pixie_ring"]);
		}

		// ------------------------------------------------------------ realm events
		private static function events():void {
			boss("ev_cube", {phases: [
				P(1, {move: "orbit", attacks: [spiral(4, 11, 5.5, 55, 0.14, 0xff40ff), aim(3, 24, 9, 70, 1.4, 0xf0d040, {shape: "blade"})]}),
				P(0.66, {say: "Cubes! Defend your master!", shield: 2, summon: [{what: "cubelet", n: 4}], move: "center",
					attacks: [wall(12, 5, 65, 1.6, 0xc080ff, {shape: "star"}), summon("cubelet", 2, 6, 8)]}),
				P(0.33, {say: "CUBE!", banner: "The Cube Overlord is unstable!", move: "teleport",
					attacks: [spiral(6, -9, 6, 60, 0.12, 0xffff40), flower(16, 11, 5, 65, 1.0, 0xff40ff, {split: {n: 4, spd: 4, life: 1, dmg: 40}, life: 1.4})]})
			]}, ["cube_core", "cubic_staff"]);

			boss("ev_titan", {phases: [
				P(1, {move: "wander", attacks: [aim(5, 50, 7, 65, 1.1, 0xff7020), rain(3, 3, 80, 2.8, 0xffb030, {burst: 6})]}),
				P(0.66, {say: "The earth itself burns!", shield: 2, move: "still",
					attacks: [wall(15, 4.5, 70, 1.8, 0xff5020, {hole: 3}), summon("imp", 3, 7, 6)]}),
				P(0.33, {say: "CRUMBLE!", move: "charge", speed: 1.4,
					attacks: [ring(30, 6, 5, 70, 0.9, 0xffd040), aim(3, 16, 11, 95, 0.7, 0xff3010, {shape: "blade", r: 0.3}), nova(2.5, 1.2, 110, 3, 0xff6010, {burst: 10})]})
			]}, ["titanbreaker", "ember_mantle"]);

			// Sylith the Frost Wyrm, from the user's own art and design sheet (tools/bossart/sylith.py draws her on the
			// game's grid): she circles her frozen arena breathing cones of frost (marked on the ground first: get out
			// of the line), flicks frost spikes, fires ice lances, lashes her tail at anyone close, calls ice wolves,
			// buries the arena in an ice storm and dives on you from the sky. Her ice obelisks heal her: break them
			boss("ev_wyrm", {name: "Sylith the Frost Wyrm", spr: "sylith", hp: 75000, def: 24, spd: 2.0, r: 1.1, col: S_ICE,
				seq: {idle: 4, move: 6, breath: 6, spikes: 5, lance: 5, tail: 5, storm: 6, summon: 5, fly: 6, guard: 4, death: 7, ridle: 4, rmove: 6},
				rageAt: 2, rageAll: true, phases: [
				P(1, {say: "*a breath of frost rolls over the ground*", move: "orbit",
					attacks: [syBreath(85, 5.0, 5), sySpikes(5, 65, 1.6), syLance(115, 3.4), syTail(100, 4.0)]}),
				P(0.66, {say: "Run, little warm things. My pack is hungry.", banner: "Sylith calls her pack!", shield: 2,
					summon: [{what: "ice_wolf", n: 3}], move: "orbit",
					attacks: [syBreath(90, 4.4, 6), syStorm(10, 80, 6.5), sySpikes(6, 70, 1.5), syLance(120, 3.0), syTail(105, 3.6), sySummon(2, 12)]}),
				P(0.33, {say: "WINTER ETERNAL!", banner: "The ice storm rages!", shield: 1.5, move: "chase", speed: 1.25,
					attacks: [syBreath(100, 3.6, 7), syStorm(12, 85, 5.5), syLance(125, 2.6, 3), syDive(130, 4.5), sySpikes(7, 75, 1.4), syTail(110, 3.2)]})
			]}, ["frostfang", "wyrmscale"]);
			// her pack: wolves of living ice that run you down and bite with frost
			mob("ice_wolf", {name: "Ice Wolf", spr: "ice_wolf", hp: 1300, def: 10, spd: 3.8, xp: 60, r: 0.45, keep: 1.2, col: S_ICE, aggro: 14, range: 8,
				attacks: [aim(1, 0, 8, 55, 1.1, S_ICE, {shape: "blade", r: 0.22, name: "frost bite"})]});

			boss("ev_king", {phases: [
				P(1, {move: "wander", attacks: [aim(3, 20, 8, 70, 1.0, 0x9aff7a, {eff: "bleeding"}), summon("skeleton", 2, 6, 6)]}),
				P(0.66, {say: "My court rises!", summon: [{what: "skeleton", n: 4}], shield: 2, move: "center",
					attacks: [ring(20, 9, 4.5, 55, 1.0, 0x6aff4a), wall(11, 5, 70, 2.2, 0xe8e0c8)]}),
				P(0.33, {say: "I am the hollow crown!", move: "chase",
					attacks: [spiral(4, 14, 6, 65, 0.12, 0x9aff7a), nova(2, 1.0, 100, 2.2, 0x6aff4a, {burst: 8, eff: "bleeding"})]})
			]}, ["hollow_crown", "kings_ransom"]);

			// Gorehorn the Behemoth, from the user's own art and design sheet (tools/bossart/gorehorn.py keeps it as drawn):
			// he hunts you round his arena. Every charge marks its lane in red spikes first: step out of it, and bait him
			// into one of his arena's bone stakes to floor him (stunned and open to every blow)
			boss("ev_behemoth", {name: "Gorehorn the Behemoth", spr: "gorehorn", hp: 80000, def: 28, spd: 1.7, r: 1.2, col: G_RED,
				seq: {idle: 4, move: 6, slam: 6, charge: 6, barrage: 5, pulse: 6, summon: 5, stun: 4, guard: 4, death: 7, ridle: 4, rmove: 6},
				rageAt: 2, rageAll: true, stakeStun: 2.6, phases: [
				P(1, {say: "*a low, hungry growl*", move: "chase",
					attacks: [ghCharge(110, 4.4), ghSlam(100, 3.0), ghBarrage(10, 60, 2.2), ghSpikes(3, 70, 1.4)]}),
				P(0.66, {say: "*THUNDEROUS ROAR*", banner: "Gorehorn calls his brood!", shield: 2, summon: [{what: "gore_spawn", n: 3}], move: "chase",
					attacks: [ghCharge(115, 3.8), ghPulse(110, 5.5), ghBarrage(12, 65, 2.0), ghSpikes(3, 75, 1.3), ghSummon(2, 11)]}),
				P(0.33, {say: "*the cracks in his hide blaze*", banner: "Gorehorn stampedes!", shield: 1.5, move: "chase", speed: 1.4,
					attacks: [ghCharge(125, 2.8), ghSlam(115, 3.2), ghPulse(115, 5.0), ghBarrage(14, 70, 1.9), ghSpikes(5, 80, 1.2)]})
			]}, ["gorehorn_bow", "behemoth_hide"]);
			// his brood: blood-and-bone whelps that rush you and spit spikes
			mob("gore_spawn", {name: "Gore Spawn", spr: "gore_spawn", hp: 1400, def: 10, spd: 3.2, xp: 60, r: 0.45, keep: 1.5, col: G_RED, aggro: 14, range: 9,
				attacks: [aim(1, 0, 8, 55, 1.2, G_RED, {shape: "spike", r: 0.22})]});

			boss("ev_regent", {phases: [
				P(1, {move: "teleport", attacks: [spiral(6, 8, 5, 50, 0.15, 0xc090ff), aim(1, 0, 11, 80, 0.9, 0xffffff, {eff: "confused"})]}),
				P(0.66, {say: "My phantoms will guide you... to your grave.", summon: [{what: "shade", n: 3}], move: "orbit",
					attacks: [aim(3, 40, 6, 65, 1.3, 0x8040c0, {motion: "home"}), ring(16, 11, 4, 60, 1.3, 0x8040c0, {motion: "return"})]}),
				P(0.33, {say: "Bow before the Regent!", shield: 2, move: "teleport",
					attacks: [spiral(8, -6, 6, 60, 0.12, 0xe0b0ff), wall(13, 5, 75, 2, 0xff60c0, {eff: "slowed"})]})
			]}, ["regents_scepter", "phantom_veil"]);

			boss("ev_sphinx", {phases: [
				P(1, {move: "still", attacks: [flower(16, 10, 5, 60, 1.0, 0xe8c070), aim(3, 16, 9, 75, 1.0, 0x40e0ff)]}),
				P(0.66, {say: "Answer my riddle... or perish.", shield: 2.5, move: "center", every: 4,
					cycle: [[wall(15, 5, 75, 1.4, 0xf0c030, {hole: 2})], [rain(6, 5, 85, 1.6, 0x40e0ff, {burst: 6})]]}),
				P(0.33, {say: "Wrong answer.", banner: "The Sphinx unleashes the sands!", move: "orbit",
					attacks: [spiral(4, 17, 6, 65, 0.11, 0xf0c030), nova(3, 1.4, 120, 3, 0xe8c070, {burst: 14})]})
			]}, ["riddle_tome", "sandglass_ring"]);

			boss("ev_lord", {phases: [
				P(1, {move: "wander", attacks: [aim(5, 40, 6, 70, 1.0, 0x60e0ff, {motion: "wave"}), ring(14, 13, 4, 60, 1.8, 0x6a8aa0)]}),
				P(0.66, {say: "The tide rises!", shield: 2, summon: [{what: "slime", n: 3}], move: "center",
					attacks: [wall(17, 4, 70, 1.7, 0x40a0ff, {hole: 3, motion: "wave"})]}),
				P(0.33, {say: "Drown with my kingdom!", move: "chase",
					attacks: [spiral(5, 12, 6, 65, 0.13, 0xd0ffff), rain(5, 4, 90, 2.2, 0x60e0ff, {burst: 8})]})
			]}, ["sunken_trident", "drowned_plate"]);

			boss("ev_hermit", {phases: [
				P(1, {move: "still", attacks: [ring(18, 10, 4.5, 60, 1.1, 0x2a9a8a), aim(3, 22, 9, 75, 0.9, 0xe0ff80, {name: "shell shot"})]}),
				P(0.6, {say: "Leave my shore!", shield: 3, move: "still", summon: [{what: "crab", n: 4}],
					attacks: [flower(24, 7.5, 4.5, 60, 0.9, 0x40e0c0, {motion: "return"}), rain(4, 3, 85, 2.4, 0x2a9a8a, {name: "tide spout"})]}),
				P(0.3, {say: "*the shell cracks*", banner: "The Hermit emerges!", move: "chase", speed: 1.5,
					attacks: [spiral(6, 15, 6.5, 65, 0.1, 0xe0ff80), rain(4, 3, 90, 2.2, 0x2a9a8a)]})
			]}, ["tidecaller", "hermit_shell"]);

			boss("ev_shrine", {phases: [
				P(1, {move: "still", attacks: [spiral(4, 11, 5.5, 60, 0.13, 0xff8a20), aim(3, 20, 9, 75, 1.2, 0xffe040)]}),
				P(0.66, {say: "THE SHRINE DEMANDS TRIBUTE", shield: 3, summon: [{what: "skeleton", n: 4}], move: "still",
					attacks: [flower(20, 9, 5, 65, 0.9, 0xff2020), rain(5, 5, 90, 2.2, 0xff8a20, {burst: 6})]}),
				P(0.33, {say: "BURN IN ITS FLAMES", move: "still", every: 3,
					cycle: [[spiral(6, 9, 5.5, 65, 0.12, 0xff8a20)], [spiral(6, -9, 5.5, 65, 0.12, 0xffe040)], [wall(17, 5, 80, 1.2, 0xff2020, {hole: 3})]]})
			]}, ["skullforge", "shrineflame"]);

			// ---- new realm events
			boss("ev_colossus", {name: "The Obsidian Colossus", spr: "colossus", hp: 16000, def: 34, spd: 0.9, xp: 1900, col: 0xb060ff,
				gold: 500, onrane: 5, r: 1.0, phases: [
				P(1, {move: "wander", attacks: [aim(3, 20, 8, 80, 1.0, 0xc070ff, {shape: "blade", r: 0.3}), nova(2.5, 1.3, 110, 3, 0x8030ff, {burst: 12})]}),
				P(0.66, {say: "*the ground shakes*", shield: 2.5, move: "still",
					attacks: [wall(19, 4.5, 80, 1.8, 0xb060ff, {hole: 3}), rain(4, 4, 90, 3, 0x8030ff)]}),
				P(0.33, {say: "*cracks glow with violet fire*", banner: "The Colossus cracks open!", move: "chase", speed: 1.4,
					attacks: [spiral(6, 9, 6, 70, 0.12, 0xc070ff), flower(20, 9, 5, 75, 1.2, 0xff80ff)]})
			]}, ["obsidian_maul", "colossus_core"]);

			boss("ev_phoenix", {name: "Pyraxis the Phoenix", spr: "phoenix", hp: 12000, def: 18, spd: 2.4, xp: 1800, col: 0xffa030,
				gold: 480, onrane: 5, phases: [
				P(1, {move: "orbit", speed: 1.4, attacks: [spiral(3, 23, 7, 55, 0.12, 0xffd040), aim(5, 50, 8, 60, 1.2, 0xff6020, {motion: "wave"})]}),
				P(0.5, {say: "From the ashes...", banner: "The Phoenix is reborn!", shield: 3, move: "center",
					attacks: [flower(24, 7.5, 5, 65, 0.9, 0xffa030), rain(6, 5, 85, 2, 0xff4010, {burst: 6})]}),
				P(0.2, {say: "...I RISE!", move: "teleport", attacks: [spiral(8, 11, 7, 70, 0.1, 0xffe080), nova(2.5, 1, 110, 2.4, 0xff6010, {burst: 12})]})
			]}, ["phoenix_quill", "rebirth_tome"]);

			boss("ev_witch", {name: "Mother Hexis", spr: "witch", hp: 12500, def: 20, spd: 1.6, xp: 1800, col: 0x80ff60,
				gold: 480, onrane: 5, phases: [
				P(1, {move: "teleport", attacks: [aim(3, 30, 7, 65, 1.0, 0x80ff60, {motion: "home", eff: "slowed"}), rain(3, 3, 80, 2.6, 0xff80ff)]}),
				P(0.66, {say: "Into the cauldron with you!", shield: 2, summon: [{what: "ghost", n: 3}], move: "center",
					attacks: [flower(18, 10, 4.5, 60, 1.1, 0xc0ff40, {split: {n: 5, spd: 4, life: 1, dmg: 40}, life: 1.6}), aim(1, 0, 10, 90, 0.9, 0xff60ff, {eff: "confused"})]}),
				P(0.33, {say: "Hex! Hex! HEX!", move: "orbit",
					attacks: [spiral(5, 13, 6, 65, 0.12, 0x80ff60), wall(13, 5, 80, 2.2, 0xff80ff, {eff: "armorbroken"})]})
			]}, ["hexbound_wand", "witchs_brew"]);

			boss("ev_kraken", {name: "The Reef Kraken", spr: "kraken", hp: 15000, def: 26, spd: 1.0, xp: 1900, col: 0xff6080,
				gold: 500, onrane: 5, r: 1.0, phases: [
				P(1, {move: "still", attacks: [ring(8, 22, 4, 65, 0.7, 0xff6080, {motion: "wave"}), aim(1, 0, 9, 90, 1.0, 0x6a3a8a, {r: 0.3})]}),
				P(0.66, {say: "*tentacles burst from the water*", shield: 2, summon: [{what: "slime", n: 4}], move: "still",
					attacks: [flower(16, 11, 4, 65, 1.0, 0xff80a0, {motion: "return"}), rain(5, 5, 90, 2.4, 0x40a0ff, {burst: 6})]}),
				P(0.3, {say: "*the Kraken thrashes*", banner: "The Kraken is enraged!", move: "wander",
					attacks: [spiral(8, 11, 6, 70, 0.11, 0xff6080), wall(17, 5, 80, 2, 0x6a3a8a, {hole: 3, motion: "wave"})]})
			]}, ["krakens_grasp", "abyssal_mail"]);
			for each (var ev:String in ["ev_colossus", "ev_phoenix", "ev_witch", "ev_kraken"]) Data.EVENTS.push(ev);
		}

		// ---- Vorgath's attacks, after his design sheet (each with its own animation)
		private static const V_RED:uint = 0xff2a3a, V_GOLD:uint = 0xd8a030;
		// Mace Swing: a wide sweep of crimson crescents in front of him
		private static function vSwing(dmg:int, cd:Number, n:int = 7):Object {
			// (crescents a hand apart: a gap to step into between each)
			return aim(Math.min(n, 5), 120, 8.5, dmg, cd, V_RED, {shape: "crescent", r: 0.36, life: 1.1, anim: "swing", animMs: 85, name: "mace swing"});
		}
		// Mace Smash: overhead and down, the ground erupts in spikes where you stood and shards fly
		private static function vSmash(dmg:int, cd:Number, radius:Number = 3.4, delay:Number = 1.0):Object {
			return nova(radius, delay, dmg, cd, V_RED, {burst: 16, bspd: 5.5, blife: 1.4, land: "slam", radius: radius, fx: "spikes", shape: "spike",
				anim: "smash", animMs: 110, animHit: 2, animHold: delay, name: "mace smash"});
		}
		// Shield Bash: a wall of shield-crescents driven at you (a gap to slip through), it knocks the wind out of you
		private static function vBash(dmg:int, cd:Number):Object {
			return wall(9, 9.5, dmg, cd, V_RED, {shape: "crescent", r: 0.4, life: 1.2, hole: 2, eff: "slowed", anim: "bash", animMs: 100, name: "shield bash"});
		}
		// Flail Throw: the morning star hurled at you, and it comes back
		private static function vFlail(dmg:int, cd:Number, n:int = 1):Object {
			return aim(n, 26, 9, dmg, cd, V_GOLD, {shape: "mace", r: 0.5, life: 1.6, motion: "return", anim: "swing", animMs: 85, name: "thrown morning star"});
		}
		// Spike Barrage: spikes flung into the sky rain down around you and burst out of the ground
		private static function vBarrage(n:int, dmg:int, cd:Number):Object {
			return rain(n, 5.5, dmg, cd, V_RED, {radius: 1.5, delay: 1.0, stagger: 0.07, burst: 5, bspd: 4.5, blife: 0.9, fx: "spikes", shape: "spike",
				anim: "barrage", animMs: 110, animHit: 3, animHold: 1.0, name: "spike barrage"});
		}
		// War spears: a volley of thrown spears
		private static function vSpears(n:int, dmg:int, cd:Number):Object {
			return aim(n, 44, 11, dmg, cd, 0xff5060, {shape: "spear", r: 0.26, waves: 2, gap: 0.2, anim: "swing", animMs: 70, name: "war spear volley"});
		}
		// War Cry: a rune circle blazes around him, get out before it bursts into spikes and a ring of crescents
		private static function vWarcry(dmg:int, cd:Number, radius:Number = 5.5):Object {
			return nova(radius, 1.4, dmg, cd, V_RED, {reach: 0.01, marker: "rune", radius: radius, burst: 24, bspd: 6, blife: 1.6, fx: "spikes", land: "slam",
				shape: "crescent", eff: "armorbroken", anim: "warcry", animMs: 130, animHit: 3, animHold: 1.4, name: "war cry"});
		}
		// Dash / Charge: crescents loosed ahead, and he barrels after them
		private static function vCharge(dmg:int, cd:Number):Object {
			return aim(5, 50, 10, dmg, cd, V_RED, {shape: "crescent", r: 0.4, life: 1.0, dash: 0.55, dashSpd: 10, anim: "charge", animMs: 140, name: "warlord's charge"});
		}

		// ------------------------------------------------------------ Gorehorn the Behemoth (his sheet's five attacks)
		private static const G_RED:uint = 0xd01420, G_HOT:uint = 0xff3a2a, G_BONE:uint = 0xe6cfa8;
		// Charge: he paws the ground and his lane bursts into red spikes a moment after he thunders down it
		private static function ghCharge(dmg:int, cd:Number):Object {
			return rain(8, 0, dmg, cd, G_HOT, {line: true, step: 1.15, radius: 1.05, delay: 1.15, stagger: 0.085, fx: "spikes", shape: "spike", land: "slam",
				burst: 2, bspd: 4, blife: 0.6, wind: 0.95, dash: 0.62, dashSpd: 14, anim: "charge", animMs: 110, animHit: 3, animHold: 0.95, name: "gore charge"});
		}
		// Horn Slam: he rears back and drives his horn into the ground in front of him; spikes erupt there
		private static function ghSlam(dmg:int, cd:Number):Object {
			return nova(3.0, 0.9, dmg, cd, G_RED, {reach: 3.5, burst: 10, bspd: 5, blife: 1.0, fx: "spikes", shape: "spike", land: "slam",
				anim: "slam", animMs: 110, animHit: 3, animHold: 0.9, name: "horn slam"});
		}
		// Spike Barrage: the spikes on his back fly out in every direction
		private static function ghBarrage(n:int, dmg:int, cd:Number):Object {
			return ring(n, 13, 6, dmg, cd, G_BONE, {shape: "spike", r: 0.26, life: 1.8, anim: "barrage", animMs: 100, animHit: 3, name: "spike barrage"});
		}
		// Ground Pulse: he stamps; a rune ring blazes round him, then bursts into a ring of spikes
		private static function ghPulse(dmg:int, cd:Number):Object {
			return nova(4.6, 1.3, dmg, cd, G_HOT, {reach: 0.01, marker: "rune", radius: 4.6, burst: 18, bspd: 5.5, blife: 1.4, fx: "spikes", shape: "spike", land: "slam",
				anim: "pulse", animMs: 110, animHit: 2, animHold: 1.3, name: "ground pulse"});
		}
		// Horn Spikes: a fan of bone spikes flicked at you between his big moves
		private static function ghSpikes(n:int, dmg:int, cd:Number):Object {
			return aim(n, 14 * n, 9.5, dmg, cd, G_BONE, {shape: "spike", r: 0.26, life: 1.1, name: "horn spikes"});
		}
		// Summon: gore spawn claw out of pools of blood at his sides
		private static function ghSummon(n:int, cd:Number):Object {
			return o(summon("gore_spawn", n, cd, 5), {anim: "summon", animMs: 130});
		}

		// ------------------------------------------------------------ Sylith the Frost Wyrm (her sheet's attacks)
		// (her arena is pale ice: her telegraphs and breath are a deep blue so they read on it)
		private static const S_ICE:uint = 0x9ad8ff, S_WHITE:uint = 0xe8f8ff, S_DEEP:uint = 0x2a5ad8, S_BREATH:uint = 0x3a8cff;
		// Ice Breath: she rears back and the cone's path frosts over on the ground, then she pours out a sweeping cone
		private static function syBreath(dmg:int, cd:Number, waves:int):Object {
			return aim(9, 46, 8.5, dmg, cd, S_BREATH, {life: 1.35, shape: "blade", r: 0.24, eff: "slowed", waves: waves, gap: 0.14, wrot: 4,
				lead: 1.0, leadN: 6, leadStep: 1.7, leadCol: S_DEEP, anim: "breath", animMs: 110, animHit: 3, animHold: 1.0, name: "ice breath"});
		}
		// Frost Spikes: shards bristle along her crest and fly out in a wide spread
		private static function sySpikes(n:int, dmg:int, cd:Number):Object {
			return aim(n, 70, 9, dmg, cd, S_WHITE, {shape: "spike", r: 0.24, life: 1.2, anim: "spikes", animMs: 100, animHit: 3, name: "frost spikes"});
		}
		// Ice Lance: frost gathers in her jaws, its line marked on the ground, then a fast lance streaks along it
		private static function syLance(dmg:int, cd:Number, n:int = 1):Object {
			return aim(n, 20, 16, dmg, cd, S_WHITE, {life: 1.0, shape: "blade", r: 0.34, lead: 0.75, leadN: 8, leadStep: 1.6, leadCol: S_DEEP,
				anim: "lance", animMs: 100, animHit: 3, animHold: 0.75, name: "ice lance"});
		}
		// Tail Swipe: a frosty arc round her; anyone too close is struck, and shards scatter from it
		private static function syTail(dmg:int, cd:Number):Object {
			return nova(3.4, 0.75, dmg, cd, S_DEEP, {reach: 0.01, burst: 12, bspd: 5, blife: 0.9, shape: "blade", fx: "frost",
				anim: "tail", animMs: 110, animHit: 3, animHold: 0.75, name: "tail swipe"});
		}
		// Ice Storm: a blizzard whirls round her, ice crashing down all over the arena
		private static function syStorm(n:int, dmg:int, cd:Number):Object {
			return rain(n, 7, dmg, cd, S_DEEP, {reach: 0.01, radius: 1.5, delay: 1.2, stagger: 0.16, eff: "slowed", burst: 4, bspd: 3.5, blife: 0.7,
				shape: "star", marker: "star", anim: "storm", animMs: 120, animHit: 2, animHold: 1.2, name: "ice storm"});
		}
		// Summon: ice wolves rise from the frost at her sides
		private static function sySummon(n:int, cd:Number):Object {
			return o(summon("ice_wolf", n, cd, 5), {anim: "summon", animMs: 130});
		}
		// Dive: she rises on her wings and crashes down where you stand in a burst of ice
		private static function syDive(dmg:int, cd:Number):Object {
			return nova(2.8, 1.4, dmg, cd, S_DEEP, {reach: 10, marker: "rune", burst: 14, bspd: 5.5, blife: 1.2, shape: "blade", land: "slam",
				anim: "fly", animMs: 130, animHit: 4, animHold: 1.4, name: "frost dive"});
		}

		// ------------------------------------------------------------ the Realm Siege
		/**
		 * The Realm Siege (server.js starts one every couple of hours): a warlord
		 * marches on the Godlands with soldiers at his back. He grows with every
		 * player fighting him, and leaves if he isn't beaten in 15 minutes. Loot
		 * follows how much of the fight was yours; the top damage dealer is the MVP.
		 */
		private static function siege():void {
			mob("siege_soldier", {name: "Siege Soldier", spr: "siege_soldier", hp: 5200, def: 30, spd: 2.6, xp: 160, col: 0xffa020, keep: 2,
				attacks: [aim(3, 24, 8, 90, 1.3, 0xd8d0c0, {shape: "blade"}), aim(1, 0, 6, 110, 2.6, 0xff6010, {motion: "home", r: 0.28})]});
			// his war camp's ballistas: heavy burning bolts at whoever comes near, and fire-pots lobbed into the camp
			mob("siege_ballista", {ai: "still", spd: 0, r: 0.8, aggro: 16, range: 15, drop: 0, xp: 200, keep: 0, prop: true,
				name: "Siege Ballista", spr: "siege_ballista", hp: 14000, def: 34, col: 0xff7a1a,
				attacks: [aim(1, 0, 15, 165, 1.3, 0xe8dcc0, {shape: "blade", r: 0.34, life: 1.3}),
					rain(3, 5, 120, 3.2, 0xff5010, {burst: 6, radius: 1.6})]});
			// Vorgath: five phases, his camp burning around him as he weakens (SetPieces "siege").
			// Every attack has its own animation (tools/bossart/vorgath.py): anim names it, animHit is
			// the frame the blow lands on, held until animHold seconds (when a telegraphed blast goes off).
			boss("siege_warlord", {name: "Vorgath the Siege Warlord", spr: "siege_warlord", hp: 600000, def: 48, spd: 0.9, xp: 9000, col: V_RED,
				gold: 3000, onrane: 25, r: 1.8, siege: true, scales: true, aggro: 22, range: 20,
				seq: {idle: 4, move: 6, swing: 5, smash: 6, bash: 4, barrage: 6, warcry: 5, charge: 4, death: 7, ridle: 4, rmove: 6}, rageAt: 3, phases: [
				// the March: he comes on swinging, smashing and bashing
				P(1, {move: "chase", speed: 0.9, attacks: [vSwing(150, 2.2), vSmash(175, 3.6), vBash(130, 4.4), vFlail(160, 5.2)]}),
				// Siege Engines: he plants himself, and the sky fills with spikes and spears
				P(0.8, {say: "SIEGE ENGINES! LOOSE!", banner: "The bombardment begins!", shield: 4, move: "still", summon: [{what: "siege_soldier", n: 4}],
					attacks: [vBarrage(10, 155, 2.6), vSpears(5, 125, 2.2), vWarcry(190, 7)]}),
				// the Warlord's Charge: he dashes through the camp, crescents ahead of him
				P(0.6, {say: "I HAVE BROKEN A HUNDRED GATES!", banner: "Vorgath charges!", move: "chase", speed: 1.4,
					attacks: [vCharge(160, 3.2), vSwing(150, 2.6, 9), vSmash(180, 4.2, 3.6), vFlail(160, 4.8, 2)]}),
				// the Camp Burns: enraged and wreathed in fire, every weapon in turn
				P(0.35, {say: "BURN IT ALL! LEAVE NOTHING STANDING!", banner: "THE CAMP BURNS! VORGATH IS ENRAGED!", shield: 3, move: "orbit", speed: 1.2,
					summon: [{what: "siege_soldier", n: 5}], every: 3.2, cycle: [
						[vBarrage(12, 160, 1.6), vSpears(7, 130, 1.4)],
						[vWarcry(210, 3.2, 6), vFlail(170, 1.6, 3)],
						[vSwing(160, 1.6, 9), vSmash(190, 2.0, 3.8, 1.0)],
						[vBash(140, 1.3), vCharge(170, 1.6)]]}),
				// the Last Stand: faster, everything at once
				P(0.12, {say: "VORGATH... DOES NOT... FALL!", banner: "THE LAST STAND!", move: "chase", speed: 1.5,
					attacks: [vSwing(170, 1.6, 11), vSmash(210, 2.6, 4.2, 0.85), vCharge(180, 4.0), vWarcry(230, 6.5, 6.5), vBarrage(8, 165, 3.4),
						spiral(5, 9, 7, 140, 0.15, V_RED, {shape: "spike"})]})
			]}, ["siegebreaker", "warlords_banner", "rampart_plate"]);
		}

		/** The Endless Abyss's boss on every 10th wave (its uniques come from the Abyss's chests). */
		// ---- the Abyssal Herald's attacks, after its design sheet (each with its own animation)
		private static const H_CYAN:uint = 0x30d8ff, H_PALE:uint = 0xb8f6ff, H_DEEP:uint = 0x2050e0;
		// Orb Barrage: a stream of orbs from the trident, one after another down a line
		private static function hBarrage(dmg:int, cd:Number, waves:int = 5):Object {
			return aim(1, 0, 9, dmg, cd, H_CYAN, {shape: "voidorb", r: 0.34, life: 1.6, waves: waves, gap: 0.12, anim: "barrage", animMs: 100, name: "orb barrage"});
		}
		// Orb Barrage (vertical): orbs fall from above and burst out of the ground in columns
		private static function hRain(n:int, dmg:int, cd:Number):Object {
			return rain(n, 5, dmg, cd, H_CYAN, {radius: 1.3, delay: 0.9, stagger: 0.1, fx: "pillar", burst: 4, bspd: 4, blife: 0.8, shape: "voidorb",
				anim: "rain", animMs: 120, animHit: 2, animHold: 0.9, name: "falling orbs"});
		}
		// Tentacle Slam: the deep's tentacles burst up in a line toward you
		private static function hSlam(dmg:int, cd:Number):Object {
			return rain(6, 0, dmg, cd, H_DEEP, {line: true, step: 1.7, radius: 1.4, delay: 0.7, stagger: 0.14, fx: "tentacles",
				burst: 3, bspd: 4, blife: 0.8, shape: "wisp", anim: "slam", animMs: 120, animHit: 2, animHold: 0.7, name: "tentacle slam"});
		}
		// Ranged Spread: a fan of orbs
		private static function hSpread(n:int, dmg:int, cd:Number):Object {
			return aim(n, 76, 7.5, dmg, cd, H_CYAN, {shape: "voidorb", r: 0.3, anim: "spread", animMs: 100, name: "orb spread"});
		}
		// Void Explosion: it plants the trident, a ring blazes round it, then the deep bursts out
		private static function hExplode(dmg:int, cd:Number, radius:Number):Object {
			return nova(radius, 1.3, dmg, cd, H_CYAN, {reach: 0.01, marker: "rune", radius: radius, burst: 18, bspd: 5.5, blife: 1.5, shape: "spike", fx: "spikes",
				anim: "explode", animMs: 130, animHit: 2, animHold: 1.3, name: "abyssal burst"});
		}
		// Gravity Pull: a ring of orbs round you falling inward (they slow you)
		private static function hGravity(n:int, dmg:int, cd:Number):Object {
			return o({p: "implode", n: n, rot: 15, spd: 3.2, radius: 5.5, life: 5.5 / 3.2, dmg: dmg, cd: cd, r: 0.26, col: H_PALE, shape: "voidorb", eff: "slowed"},
				{anim: "gravity", animMs: 150, name: "the deep's pull"});
		}
		// Teleport: a star of cold light, and it's somewhere else (leaving a ring of sparks)
		private static function hTeleport(cd:Number):Object {
			return ring(10, 18, 4, 55, cd, H_PALE, {shape: "star", life: 2.0, blink: 6, anim: "teleport", animMs: 110, name: "the Herald's step"});
		}
		// Summon Minions: spawn of the deep swim up out of a ring of light
		private static function hSummon(n:int, cd:Number):Object {
			return o(summon("abyss_spawn", n, cd, 6), {anim: "summon", animMs: 130});
		}
		// Phase 2: a column of the deep tears open, drifts at you and bursts
		private static function hRift(dmg:int, cd:Number):Object {
			return aim(1, 0, 3.5, dmg, cd, H_CYAN, {shape: "rift", r: 0.6, life: 2.6, split: {n: 16, spd: 5.5, life: 1.4, dmg: int(dmg / 2)},
				anim: "rift", animMs: 130, name: "abyssal rift"});
		}

		/** The Endless Abyss's boss on every 10th wave (its uniques come from the Abyss's chests). */
		private static function deep():void {
			// its spawn of the deep: little squids that drift round you and spit
			mob("abyss_spawn", {name: "Spawn of the Deep", spr: "abyss_spawn", hp: 900, def: 12, spd: 3.0, xp: 30, ai: "orbit", keep: 4, col: H_CYAN,
				attacks: [aim(1, 0, 7, 50, 1.4, H_CYAN, {shape: "voidorb", r: 0.22})]});
			boss("abyss_herald", {name: "The Abyssal Herald", spr: "abyss_herald", hp: 18000, def: 26, spd: 1.4, xp: 2400, col: H_CYAN,
				gold: 600, onrane: 6, r: 1.0, scales: true,
				seq: {idle: 4, move: 6, barrage: 6, rain: 5, summon: 5, slam: 5, teleport: 6, spread: 5, explode: 5, gravity: 5, rift: 5, death: 7, ridle: 4, rmove: 6},
				rageAt: 2, phases: [
				// it does not speak; it calls
				P(1, {move: "orbit", attacks: [hBarrage(85, 2.2), hSpread(7, 70, 1.6), hSlam(100, 4.6), hTeleport(9)]}),
				P(0.6, {say: "...Deeper. Always deeper.", shield: 2.5, summon: [{what: "abyss_spawn", n: 4}], move: "center", every: 5,
					cycle: [[hRain(8, 95, 1.8), hSpread(9, 70, 1.4)],
						[hGravity(14, 75, 3.2), hBarrage(85, 2.0)],
						[hExplode(120, 4.0, 5.5), hSummon(2, 8)]]}),
				P(0.3, {say: "THE ABYSS STARES BACK", banner: "The Herald calls the deep! It is enraged!", move: "orbit", speed: 1.3,
					attacks: [hRift(115, 3.4), hGravity(16, 80, 4.2), hSlam(110, 2.6), hRain(10, 100, 2.2), hTeleport(5),
						spiral(6, -10, 6.5, 80, 0.1, H_PALE, {shape: "voidorb"})]})
			]}, ["voidrend", "abyssal_crown", "depthstone"]);
		}

		// ------------------------------------------------------------ hard dungeons
		private static function hardDungeons():void {
			boss("sun_king", {phases: [
				P(1, {move: "wander", attacks: [flower(16, 11, 5, 70, 1.0, 0xffb020), aim(3, 20, 9, 80, 1.0, 0xffe060)]}),
				P(0.5, {say: "Kneel before the noon sun!", shield: 1.5, move: "center",
					attacks: [spiral(5, 8, 6, 70, 0.13, 0xffd040), nova(2.5, 1.3, 120, 2.6, 0xff9020, {burst: 8})]})
			]}, ["solar_crown", "sunfire_staff"]);
			boss("moon_queen", {phases: [
				P(1, {move: "orbit", attacks: [aim(5, 64, 7, 70, 1.15, 0xb0c0ff, {motion: "wave"}), ring(16, 11, 4, 65, 1.4, 0x8a9aff, {motion: "return"})]}),
				P(0.5, {say: "The night is mine.", move: "teleport",
					attacks: [spiral(4, -14, 6, 70, 0.12, 0xd0d8ff), rain(5, 4, 100, 2.4, 0x6a7ac0, {eff: "slowed"})]})
			]}, ["moonlight_bow", "lunar_robe"]);
			boss("star_prince", {phases: [
				P(1, {move: "teleport", attacks: [aim(3, 30, 9, 75, 0.8, 0xd080ff, {shape: "star"}), aim(1, 0, 6, 80, 1.6, 0xfff060, {motion: "home"})]}),
				P(0.5, {say: "Watch the stars fall!", move: "orbit",
					attacks: [rain(8, 6, 90, 2, 0xc070ff, {burst: 4}), spiral(3, 23, 7, 70, 0.1, 0xfff060)]})
			]}, ["starfall_dagger", "astral_cloak"]);
			boss("frost_warden", {phases: [
				P(1, {move: "wander", attacks: [spiral(4, 10, 5, 70, 0.14, 0x80e0ff, {eff: "slowed"}), aim(1, 0, 10, 110, 1.1, 0xffffff, {shape: "blade", r: 0.3}),
					ring(10, 18, 3.5, 60, 2.4, 0xc0e8ff, {name: "frost ring"})]}),
				P(0.5, {say: "The cold takes everything.", shield: 2, move: "center",
					attacks: [wall(15, 4.5, 90, 2.2, 0xc0e8ff, {hole: 3, eff: "slowed"}), rain(5, 5, 85, 2.6, 0x80f0ff, {delay: 1.3})]})
			]}, ["glacial_plate", "icicle_ring"]);
			boss("flame_warden", {phases: [
				P(1, {move: "wander", attacks: [aim(4, 60, 8, 75, 1.2, 0xff6020), ring(10, 15, 4, 65, 2.0, 0xffb020, {split: {n: 3, spd: 3.5, life: 0.7, dmg: 40}, life: 1.4})]}),
				P(0.5, {say: "Burn with your friend!", shield: 2, move: "charge",
					attacks: [spiral(4, 13, 5.5, 70, 0.14, 0xff6020), nova(2.2, 1.3, 95, 2.7, 0xff3010, {burst: 5, bspd: 3.5})]})
			]}, ["flamewarden_blade", "ember_ring"]);
			boss("shattered_seraph", {phases: [
				P(1, {move: "orbit", attacks: [spiral(4, 12, 6, 70, 0.12, 0xff60c0), aim(3, 24, 10, 90, 1.0, 0xffffff, {shape: "blade"})]}),
				P(0.75, {say: "You broke the seal... now see what you freed.", shield: 2.5, summon: [{what: "sprite_god", n: 2}], move: "center",
					attacks: [flower(24, 7.5, 5, 75, 0.9, 0xff60c0), wall(17, 5, 90, 2.4, 0xd8d0e8, {hole: 3})]}),
				P(0.45, {say: "SHATTER!", banner: "The Seraph shatters!", move: "teleport",
					attacks: [rain(7, 7, 110, 2.0, 0xff2060, {burst: 4}), spiral(5, -9, 6, 75, 0.13, 0xd8d0e8)]}),
				P(0.15, {say: "I... will not... fade!", shield: 2, move: "center", every: 3,
					cycle: [[flower(24, 6, 6, 80, 0.75, 0xff60c0)], [aim(7, 120, 9, 90, 0.8, 0xffffff, {shape: "blade", waves: 2, gap: 0.3})]]})
			]}, ["shardwing_bow", "seraph_halo"]);
			boss("blood_knight", {phases: [
				P(1, {move: "charge", speed: 1.3, attacks: [aim(3, 30, 9, 85, 0.9, 0xd02030, {eff: "bleeding"}), wall(9, 6, 80, 2.4, 0xff4040)]}),
				P(0.5, {say: "Your blood will feed my blade!", shield: 1.5, move: "chase", speed: 1.5,
					attacks: [spiral(4, 17, 6.5, 80, 0.12, 0xff4040), nova(1.8, 1.3, 115, 2.5, 0xd02030, {burst: 5, bspd: 3.5, eff: "bleeding"})]})
			]}, ["bloodletter", "sanguine_plate"]);
			boss("hex_queen", {phases: [
				P(1, {move: "teleport", attacks: [aim(3, 30, 7, 75, 1.2, 0x80ff60, {motion: "home", eff: "confused"}), rain(4, 4, 90, 2.6, 0xd060ff),
					ring(12, 14, 3.5, 60, 2.2, 0xd060ff, {name: "hex ring"})]}),
				P(0.5, {say: "A curse on all your houses!", shield: 2, move: "orbit",
					attacks: [flower(16, 9, 5, 75, 1.2, 0x80ff60, {split: {n: 3, spd: 3.5, life: 0.8, dmg: 40}, life: 1.5}), wall(13, 5, 90, 2.4, 0xd060ff, {hole: 3, eff: "slowed"})]})
			]}, ["hexweave_robe", "cursed_skull"]);
		}

		// ---- the Dark Elder's attacks, after his design sheet (each with its own animation)
		private static const E_VOID:uint = 0xb040ff, E_LIGHT:uint = 0xe0a0ff;
		// Void Blast: an orb gathered in his hand and hurled, bursting into shards
		private static function eBlast(dmg:int, cd:Number):Object {
			return aim(1, 0, 6.5, dmg, cd, E_VOID, {shape: "voidorb", r: 0.5, life: 1.8, split: {n: 10, spd: 5, life: 1.2, dmg: int(dmg / 2)},
				anim: "blast", animMs: 110, name: "void blast"});
		}
		// Void Blast (vertical): columns of void light burst from the ground round you
		private static function ePillars(n:int, dmg:int, cd:Number):Object {
			return rain(n, 5, dmg, cd, E_VOID, {radius: 1.3, delay: 0.9, stagger: 0.1, fx: "pillar",
				anim: "pillars", animMs: 120, animHit: 2, animHold: 0.9, name: "void pillars"});
		}
		// Tentacle Slam: a line of tentacles bursting out of the ground toward you
		private static function eSlam(dmg:int, cd:Number):Object {
			return rain(6, 0, dmg, cd, 0x8a50ff, {line: true, step: 1.7, radius: 1.4, delay: 0.7, stagger: 0.14, fx: "tentacles",
				burst: 3, bspd: 4, blife: 0.8, shape: "wisp", anim: "slam", animMs: 120, animHit: 2, animHold: 0.7, name: "tentacle slam"});
		}
		// Ranged Spread: a fan of void orbs
		private static function eSpread(n:int, dmg:int, cd:Number):Object {
			return aim(n, 80, 7.5, dmg, cd, E_VOID, {shape: "voidorb", r: 0.3, anim: "spread", animMs: 100, name: "void spread"});
		}
		// Void Explosion: a rune circle round him, then the void bursts out of it
		private static function eExplode(dmg:int, cd:Number, radius:Number):Object {
			return nova(radius, 1.3, dmg, cd, E_VOID, {reach: 0.01, marker: "rune", radius: radius, burst: 20, bspd: 5.5, blife: 1.6, shape: "voidorb", fx: "pillar",
				anim: "explode", animMs: 130, animHit: 2, animHold: 1.3, name: "void explosion"});
		}
		// Gravity Pull: a ring of orbs appears round you and falls inward (it slows you)
		private static function eGravity(n:int, dmg:int, cd:Number):Object {
			return o({p: "implode", n: n, rot: 15, spd: 3.2, radius: 5.5, life: 5.5 / 3.2, dmg: dmg, cd: cd, r: 0.26, col: E_LIGHT, shape: "voidorb", eff: "slowed"},
				{anim: "gravity", animMs: 150, name: "gravity well"});
		}
		// Teleport: he comes apart, leaving a ring of motes behind, and pours back out elsewhere
		private static function eTeleport(cd:Number):Object {
			return ring(12, 15, 4, 60, cd, E_LIGHT, {shape: "orb", life: 2.2, blink: 6, anim: "teleport", animMs: 110, name: "void step"});
		}
		// Summon Minions: shades rise from a ring on the ground
		private static function eSummon(n:int, cd:Number):Object {
			return o(summon("shade", n, cd, 6), {anim: "summon", animMs: 130});
		}
		// Phase 2: he tears the world open, and the rift drifts at you and bursts
		private static function eRift(dmg:int, cd:Number):Object {
			return aim(1, 0, 3.5, dmg, cd, 0xd080ff, {shape: "rift", r: 0.6, life: 2.6, split: {n: 16, spd: 5.5, life: 1.4, dmg: int(dmg / 2)},
				anim: "rift", animMs: 130, name: "void rift"});
		}

		// The Elder's survival patterns (he can't be hurt while they run): curtains with narrow gaps
		// and lattices that need small, exact steps rather than running away
		// two spirals turning against each other: a moving lattice to thread
		private static function eLattice(spd:Number, cd:Number):Array {
			return [spiral(5, 9, spd, 80, cd, E_VOID, {shape: "voidorb", r: 0.24, name: "void lattice"}),
				spiral(5, -11, spd * 0.85, 80, cd * 1.15, E_LIGHT, {shape: "orb", name: "void lattice"})];
		}
		// a wall of orbs marching at you with a single gap, and slow rings to weave between
		private static function eCurtain(n:int, cd:Number):Array {
			return [wall(n, 4.4, 95, cd, E_VOID, {hole: 2, spacing: 0.62, shape: "voidorb", r: 0.26, name: "void curtain", anim: "spread", animMs: 90}),
				ring(22, 8, 2.8, 70, cd * 1.35, E_LIGHT, {shape: "orb", life: 4.5, name: "void ripple"})];
		}
		// a flower of slow orbs while gravity wells close round you
		private static function eCollapse(n:int, cd:Number):Array {
			return [flower(n, 7, 4.0, 80, cd, E_VOID, {shape: "voidorb", life: 3.2, name: "void bloom"}), eGravity(18, 80, cd * 2.4)];
		}

		// ------------------------------------------------------------ realm finales
		/** Where a closing realm sends everyone: one of these, picked per realm. */
		public static const FINALES:Array = ["citadel", "drowned_throne", "clockwork_foundry", "void_rift"];

		private static function finales():void {
			// Azrakor, after his design sheet: every attack has its own animation (tools/bossart/elder.py).
			// He keeps his crystal phase (the third), and burns with the void in the last (rageAt).
			boss("elder", {seq: {idle: 4, move: 6, blast: 6, pillars: 5, slam: 5, summon: 5, teleport: 6, spread: 5, explode: 5, gravity: 5, rift: 5, death: 7, ridle: 4, rmove: 6},
				rageAt: 3, col: E_VOID, phases: [
				P(1, {move: "orbit", attacks: [eBlast(110, 2.4), eSpread(7, 70, 1.6), eSlam(120, 4.5), eTeleport(9)]}),
				P(0.75, {say: "You amuse me. Let us see you dance.", banner: "SURVIVE! The Elder can't be hurt: dodge!", shield: 1.5, move: "center", every: 5,
					survive: 14, dodgeEvery: 4.7, dodge: [eLattice(3.9, 0.14), eCurtain(25, 0.95), eCollapse(26, 0.8)],
					cycle: [[ePillars(8, 100, 1.6), eSpread(9, 70, 1.4)],
						[eGravity(14, 75, 3.2), eBlast(110, 2.0)],
						[eSlam(120, 1.6), eSummon(2, 8)]]}),
				P(0.45, {move: "still", attacks: [eExplode(150, 4.5, 6), ePillars(6, 100, 2.2), eSpread(7, 70, 1.8)]}),
				P(0.2, {say: "ENOUGH! THE VOID WILL HAVE YOU!", banner: "The Dark Elder awakens! SURVIVE the void!", shield: 1.5, move: "orbit", speed: 1.3,
					survive: 18, dodgeEvery: 4.5, dodge: [eLattice(4.4, 0.12), eCurtain(27, 0.8).concat([ePillars(5, 110, 2.2)]),
						eCollapse(30, 0.7), eLattice(4.0, 0.12).concat(eCurtain(25, 1.3).slice(0, 1))],
					attacks: [eRift(130, 3.5), eGravity(18, 85, 4), eSlam(130, 2.4), ePillars(10, 110, 2.0), eTeleport(5),
						spiral(6, -10, 6, 70, 0.1, E_LIGHT, {shape: "voidorb"})]})
			]}, ["elder_scepter", "crown_of_azrakor"]);

			// Nerezza, the Tide Empress, from the user's own art (tools/bossart/nerezza.py keeps it as drawn):
			// an animation for every attack on her sheet, and her robes turn violet when she rages
			boss("tide_empress", {name: "Nerezza, the Tide Empress", spr: "tide_empress", hp: 40000, def: 30, spd: 1.6, xp: 5000, col: N_BLUE,
				gold: 1500, onrane: 15, dungeon: true, dtier: 5, finale: true, aggro: 18, range: 16, r: 1.2,
				seq: {idle: 6, move: 6, trident: 5, geyser: 6, slam: 6, summon: 5, teleport: 6, explode: 6, whirlpool: 6, spout: 6, guard: 4, death: 7, ridle: 4, rmove: 6},
				rageAt: 3, rageAll: true, phases: [
				P(1, {say: "You dare enter my throne room?", move: "orbit",
					attacks: [nTrident(5, 70, 1.4), nGeyser(5, 100, 3.6), nTeleport(9)]}),
				P(0.75, {say: "Rise, children of the deep!", shield: 2.5, summon: [{what: "tide_spawn", n: 4}], move: "center", every: 4.5,
					cycle: [[nSlam(85, 1.8), nTrident(3, 70, 1.2)], [nWhirl(16, 80, 3.0), nGeyser(7, 105, 2.0)], [nSummon(1, 9), nExplode(140, 3.6, 5.5)]]}),
				P(0.5, {say: "The tide turns!", banner: "The throne room floods!", move: "teleport",
					attacks: [nGeyser(9, 110, 1.8), nSlam(90, 2.4), nTeleport(6), flower(24, 7.5, 5, 75, 0.9, N_LIGHT, {motion: "return", shape: "orb"})]}),
				P(0.2, {say: "The sea is my voice. And you are but a ripple.", banner: "Nerezza's fury turns the sea violet!", shield: 2, move: "orbit", speed: 1.4,
					attacks: [spiral(5, 9, 6, 80, 0.12, N_VIOLET, {motion: "wave", shape: "orb"}), nSpout(110, 2.6), nExplode(150, 3.0, 6), nWhirl(18, 90, 3.6), nTrident(7, 90, 1.0)]})
			]}, ["tidebreaker", "empress_coral"]);

			boss("gearmind", {name: "Gearmind Omega", spr: "gearmind", hp: 42000, def: 38, spd: 1.0, xp: 5000, col: 0xffd060,
				gold: 1500, onrane: 15, dungeon: true, dtier: 5, finale: true, aggro: 18, range: 16, phases: [
				P(1, {say: "INTRUDERS DETECTED. PURGING.", move: "still",
					attacks: [spiral(4, 15, 6, 65, 0.12, 0xffd060), aim(3, 12, 10, 80, 1.0, 0x60e0ff, {shape: "blade"})]}),
				P(0.75, {say: "DEPLOYING DRONES.", shield: 3, summon: [{what: "gear_drone", n: 4}], move: "still", every: 4,
					cycle: [[wall(21, 5, 85, 1.2, 0xc0a060, {hole: 3})], [ring(36, 5, 4.5, 75, 0.9, 0x60e0ff)]]}),
				P(0.45, {say: "OVERCLOCKING.", banner: "Gearmind overclocks!", move: "orbit", speed: 1.5,
					attacks: [spiral(6, 21, 7, 75, 0.09, 0xffd060, {motion: "accel", accel: 0.5}), rain(6, 6, 110, 2.2, 0xff6020)]}),
				P(0.15, {say: "CRITICAL ERROR. SELF-DESTRUCT IMMINENT.", shield: 2, move: "chase",
					attacks: [flower(30, 6, 6, 85, 0.6, 0xff4020), nova(3.5, 1.5, 160, 2.5, 0xff3010, {burst: 20})]})
			]}, ["gearblade", "cogwork_plate"]);

			boss("void_dragon", {name: "Vael'thrax the Void Dragon", spr: "void_dragon", hp: 46000, def: 34, spd: 2.0, xp: 5500, col: 0xd040ff,
				gold: 1700, onrane: 18, dungeon: true, dtier: 5, finale: true, aggro: 20, range: 18, r: 1.1, phases: [
				P(1, {say: "Another morsel falls into the rift.", move: "orbit",
					attacks: [aim(7, 70, 8, 75, 1.0, 0xd040ff), aim(1, 0, 6, 90, 1.5, 0xff40ff, {motion: "home", r: 0.3})]}),
				P(0.75, {say: "Feel the void's breath!", shield: 2, move: "center",
					attacks: [wall(21, 5, 90, 1.6, 0x8040c0, {hole: 2, waves: 2, gap: 0.5}), summon("void_wisp", 2, 7, 6)]}),
				P(0.5, {say: "The stars go dark.", banner: "The rift tears open!", move: "teleport", every: 4,
					cycle: [[spiral(5, 13, 6, 80, 0.12, 0xc080ff)], [rain(8, 7, 120, 2.0, 0xd040ff, {burst: 5})], [flower(24, 6, 5.5, 80, 0.8, 0xff40ff)]]}),
				P(0.2, {say: "I AM ETERNAL!", shield: 3, move: "orbit", speed: 1.4,
					attacks: [spiral(5, -11, 6.5, 85, 0.12, 0xff40ff), nova(3.5, 1.5, 160, 2.8, 0xd040ff, {burst: 14}), aim(5, 30, 11, 110, 1.0, 0xffffff, {shape: "blade", waves: 3, gap: 0.2})]})
			]}, ["voidfang", "dragonscale"]);

			var D:Array = Data.DUNGEONS;
			D.push({id: "drowned_throne", name: "The Drowned Throne", color: 0x40d0ff, floor: 9, accent: 0, tier: 4, hard: 1.5, layout: "cave", hazard: "water",
				mobs: ["slime", "tide_spawn", "great_snake", "medusa"], boss: "tide_empress"});
			D.push({id: "clockwork_foundry", name: "The Clockwork Foundry", color: 0xffd060, floor: 6, accent: 13, tier: 4, hard: 1.5, layout: "grid", hazard: "lava",
				mobs: ["golem", "gear_drone", "dwarf", "cubelet"], boss: "gearmind"});
			D.push({id: "void_rift", name: "The Void Rift", color: 0xd040ff, floor: 14, accent: 8, tier: 4, hard: 1.6, layout: "islands",
				mobs: ["shade", "void_wisp", "lesser_demon", "ghost"], boss: "void_dragon"});
		}

		// ------------------------------------------------------------ raids
		/** Raids: opened from the Nexus Raid Table, three boss stages in one arena. */
		/**
		 * The Starfall Vault changes every week (Monday, UTC): one of these rules for
		 * everything inside, with its own board of fastest clears. week: days since
		 * 1970 plus 3, over 7 (the server's quest week).
		 */
		public static const VAULT_TWISTS:Array = [
			{id: "quick", name: "Quickened Sands", desc: "Everything in the Vault attacks 25% faster.", rate: 1.25},
			{id: "stone", name: "Stoneskin Masters", desc: "The four masters have 40% more health.", masterHp: 1.4},
			{id: "swarm", name: "Swarming Halls", desc: "Twice the guards in the alcoves, and they hit 15% harder.", guards: 2, guardDmg: 1.15},
			{id: "fleet", name: "Fleet Masters", desc: "The masters move 35% faster.", masterSpd: 1.35},
			{id: "glass", name: "Glass Vault", desc: "Everything has 30% less health but hits 40% harder.", hp: 0.7, dmg: 1.4},
			{id: "escort", name: "Honour Guard", desc: "Each master wakes with four guards at its side.", escort: 4}
		];
		public static function vaultTwist(week:int):Object { return VAULT_TWISTS[((week % VAULT_TWISTS.length) + VAULT_TWISTS.length) % VAULT_TWISTS.length]; }
		/** Applies the week's twist to a monster in the Vault (master: one of the four masters). */
		public static function twistEnemy(e:Enemy, tw:Object, master:Boolean):void {
			if (!tw || !e) return;
			if (tw.rate) e.rateMult *= tw.rate;
			if (tw.hp) { e.maxHp *= tw.hp; e.hp = e.maxHp; }
			if (tw.dmg) e.dmgMult *= tw.dmg;
			if (master && tw.masterHp) { e.maxHp *= tw.masterHp; e.hp = e.maxHp; }
			if (master && tw.masterSpd) e.spdMult *= tw.masterSpd;
			if (!master && tw.guardDmg) e.dmgMult *= tw.guardDmg;
		}

		// ---- Tempestus's attacks, after his design sheet (each with its own animation)
		private static const T_VIOLET:uint = 0xa060ff, T_PALE:uint = 0xe2ccff, T_BLUE:uint = 0x4048e0;
		// Void Slash: a great crescent of storm-light swept in front of him
		private static function tSlash(dmg:int, cd:Number):Object {
			return aim(9, 120, 8.5, dmg, cd, T_VIOLET, {shape: "crescent", r: 0.42, life: 1.1, anim: "slash", animMs: 85, name: "void slash"});
		}
		// Spread: a fan of storm orbs
		private static function tSpread(n:int, dmg:int, cd:Number):Object {
			return aim(n, 76, 7.5, dmg, cd, T_VIOLET, {shape: "voidorb", r: 0.3, anim: "spread", animMs: 100, name: "storm orbs"});
		}
		// Heavy Lightning Strike: he raises his hand and a great bolt falls where you stood
		private static function tStrike(dmg:int, cd:Number):Object {
			return nova(2.6, 1.1, dmg, cd, T_PALE, {burst: 10, bspd: 5, blife: 1.0, shape: "bolt", fx: "pillar", eff: "paralyzed",
				anim: "strike", animMs: 110, animHit: 3, animHold: 1.1, name: "heavy lightning strike"});
		}
		// Chain Lightning (his own): strikes you, then jumps to whoever stands near you, and on
		private static function tChain(jumps:int, dmg:int, cd:Number):Object {
			return {p: "chain", n: jumps, jump: 4.5, radius: 1.3, delay: 0.9, stagger: 0.22, dmg: dmg, cd: cd, r: 0.22, col: T_PALE, fx: "pillar",
				burst: 0, eff: "paralyzed", anim: "strike", animMs: 110, animHit: 3, animHold: 0.9, name: "chain lightning"};
		}
		// Dash: storm-light loosed ahead and he streaks after it
		private static function tDash(dmg:int, cd:Number):Object {
			return aim(5, 50, 10, dmg, cd, T_VIOLET, {shape: "crescent", r: 0.38, life: 1.0, dash: 0.5, dashSpd: 11, anim: "dash", animMs: 100, name: "storm dash"});
		}
		// Teleport: through a ring of light, and out somewhere else
		private static function tBlink(cd:Number):Object {
			return ring(10, 18, 4, 60, cd, T_PALE, {shape: "star", life: 2.0, blink: 6, anim: "dash", animMs: 100, name: "storm step"});
		}
		// The storm's radius: a rune circle round him, then lightning bursts up out of it
		private static function tRadius(dmg:int, cd:Number, radius:Number):Object {
			return nova(radius, 1.3, dmg, cd, T_VIOLET, {reach: 0.01, marker: "rune", radius: radius, burst: 20, bspd: 6, blife: 1.4, shape: "bolt", fx: "pillar", eff: "paralyzed",
				anim: "radius", animMs: 120, animHit: 3, animHold: 1.3, name: "the storm's radius"});
		}
		// Divine Storm Rain: columns of lightning falling all round you
		private static function tRain(n:int, dmg:int, cd:Number):Object {
			return rain(n, 5.5, dmg, cd, T_PALE, {radius: 1.3, delay: 1.0, stagger: 0.08, fx: "pillar", burst: 0,
				anim: "rain", animMs: 110, animHit: 3, animHold: 1.0, name: "divine storm rain"});
		}
		// The eye's pull: a ring of storm orbs closing in on you
		private static function tPull(n:int, dmg:int, cd:Number):Object {
			return o({p: "implode", n: n, rot: 15, spd: 3.2, radius: 5.5, life: 5.5 / 3.2, dmg: dmg, cd: cd, r: 0.26, col: T_PALE, shape: "voidorb", eff: "slowed"},
				{anim: "radius", animMs: 140, name: "the eye's pull"});
		}

		// ---- the raids' attack kit (shared by every raid boss)
		/** Blasts marching out in a line from the boss toward you (fx: what bursts up: spikes, a pillar, tentacles). */
		private static function lineRain(n:int, dmg:int, cd:Number, col:uint, fx:String, x:Object = null):Object {
			return rain(n, 0, dmg, cd, col, o({line: true, step: 1.7, radius: 1.3, delay: 0.7, stagger: 0.13, fx: fx, burst: 3, bspd: 4, blife: 0.8}, x));
		}
		/** Columns bursting out of the ground round you. */
		private static function pillars(n:int, dmg:int, cd:Number, col:uint, x:Object = null):Object {
			return rain(n, 5, dmg, cd, col, o({radius: 1.3, delay: 0.9, stagger: 0.1, fx: "pillar", name: "pillar"}, x));
		}
		/** A ring of shots round you that falls inward. */
		private static function pull(n:int, dmg:int, cd:Number, col:uint, x:Object = null):Object {
			var a:Object = o({p: "implode", n: n, rot: 15, spd: 3.2, radius: 5.5, dmg: dmg, cd: cd, r: 0.26, col: col, shape: "orb", name: "pull"}, x);
			a.life = a.radius / a.spd;
			return a;
		}
		/** A rune circle round the boss, then it bursts (get out of it). */
		private static function selfNova(radius:Number, delay:Number, dmg:int, cd:Number, col:uint, x:Object = null):Object {
			return nova(radius, delay, dmg, cd, col, o({reach: 0.01, marker: "rune", radius: radius, burst: 16, bspd: 5.5, blife: 1.5, name: "rite"}, x));
		}
		// ---- Nerezza's attacks, after her design sheet (each with its own animation)
		private static const N_BLUE:uint = 0x40a8ff, N_LIGHT:uint = 0xa8e4ff, N_VIOLET:uint = 0xb070ff;
		// Trident Blast: orbs of water hurled from her staff, bursting into spray
		private static function nTrident(n:int, dmg:int, cd:Number):Object {
			return aim(n, 40, 8.5, dmg, cd, N_BLUE, {shape: "orb", r: 0.3, life: 1.3, split: {n: 6, spd: 4.5, life: 0.7, dmg: int(dmg / 2)},
				anim: "trident", animMs: 100, animHit: 3, name: "trident blast"});
		}
		// Trident Blast (vertical): geysers burst up through the floor where you stand
		private static function nGeyser(n:int, dmg:int, cd:Number):Object {
			return rain(n, 6, dmg, cd, N_LIGHT, {radius: 1.4, delay: 1.0, stagger: 0.1, fx: "pillar", burst: 4, bspd: 4, blife: 0.7,
				anim: "geyser", animMs: 110, animHit: 3, animHold: 1.0, name: "geyser"});
		}
		// Tide Slam: a wave rolls at you, a gap in it to slip through
		private static function nSlam(dmg:int, cd:Number):Object {
			return wall(17, 5, dmg, cd, N_BLUE, {hole: 3, motion: "wave", shape: "crescent", r: 0.3, anim: "slam", animMs: 100, animHit: 3, name: "tide slam"});
		}
		// Summon Seawardens: they climb out of arches of water at her sides
		private static function nSummon(n:int, cd:Number):Object {
			return o(summon("tide_spawn", n, cd, 6), {anim: "summon", animMs: 130});
		}
		// Teleport: she runs to water and pours back out elsewhere, a ring of spray left behind
		private static function nTeleport(cd:Number):Object {
			return ring(12, 15, 4, 60, cd, N_LIGHT, {shape: "orb", life: 2.0, blink: 6, anim: "teleport", animMs: 100, name: "tidal step"});
		}
		// Ocean Explosion: the sea gathers round her, then bursts up in a crown of water
		private static function nExplode(dmg:int, cd:Number, radius:Number):Object {
			return nova(radius, 1.3, dmg, cd, N_BLUE, {reach: 0.01, marker: "rune", radius: radius, burst: 20, bspd: 5.5, blife: 1.5, shape: "orb", fx: "pillar",
				anim: "explode", animMs: 120, animHit: 3, animHold: 1.3, name: "ocean explosion"});
		}
		// Gravity Pull: a whirlpool's ring of water closing in on you (it slows you)
		private static function nWhirl(n:int, dmg:int, cd:Number):Object {
			return o({p: "implode", n: n, rot: 15, spd: 3.2, radius: 5.5, life: 5.5 / 3.2, dmg: dmg, cd: cd, r: 0.26, col: N_LIGHT, shape: "orb", eff: "slowed"},
				{anim: "whirlpool", animMs: 130, name: "whirlpool"});
		}
		// Her second phase: slow waterspouts wandering out across the room
		private static function nSpout(dmg:int, cd:Number):Object {
			return aim(4, 100, 3.4, dmg, cd, N_VIOLET, {shape: "orb", r: 0.55, life: 3.4, motion: "wave", anim: "spout", animMs: 110, animHit: 3, name: "waterspout"});
		}

		// ---- Archon Vesper's attacks, after his design sheet (each with its own animation)
		private static const A_RED:uint = 0xff2a3a, A_PALE:uint = 0xffa8b0;
		// Void-Lance Strike: he drives the lance forward and crescents of void-light tear off its point
		private static function aLance(dmg:int, cd:Number):Object {
			return aim(3, 26, 9.5, dmg, cd, A_RED, {shape: "crescent", r: 0.42, life: 1.2, anim: "lance", animMs: 85, animHit: 3, animHold: 0.3, name: "void-lance strike"});
		}
		// ...and the lance hurled ahead of him as he charges after it
		private static function aLanceDash(dmg:int, cd:Number):Object {
			return aim(1, 0, 13, dmg, cd, A_PALE, {shape: "spear", r: 0.4, life: 1.0, dash: 0.45, dashSpd: 12, anim: "lance", animMs: 80, animHit: 3, name: "void-lance charge"});
		}
		// Ranged Attack: orbs of void-light loosed from the lance's head, bursting into stars
		private static function aRanged(n:int, dmg:int, cd:Number):Object {
			return aim(n, 64, 7.5, dmg, cd, A_RED, {shape: "voidorb", r: 0.3, life: 1.3, split: {n: 6, spd: 4.5, life: 0.8, dmg: int(dmg / 2)},
				anim: "ranged", animMs: 100, animHit: 3, name: "void orbs"});
		}
		// Gravity Well: a ring of orbs round you that falls inward (it slows you)
		private static function aGravity(n:int, dmg:int, cd:Number):Object {
			return o({p: "implode", n: n, rot: 15, spd: 3.2, radius: 5.5, life: 5.5 / 3.2, dmg: dmg, cd: cd, r: 0.26, col: A_PALE, shape: "voidorb", eff: "slowed"},
				{anim: "gravity", animMs: 130, name: "gravity well"});
		}
		// Void Dash: crescents loosed ahead and he streaks after them
		private static function aDash(dmg:int, cd:Number):Object {
			return aim(5, 50, 10, dmg, cd, A_RED, {shape: "crescent", r: 0.38, life: 1.0, dash: 0.5, dashSpd: 11, anim: "dash", animMs: 100, name: "void dash"});
		}
		// Teleport: through a rift, and out somewhere else
		private static function aBlink(cd:Number):Object {
			return ring(10, 18, 4, 60, cd, A_PALE, {shape: "star", life: 2.0, blink: 6, anim: "dash", animMs: 100, name: "void step"});
		}
		// Temporal Cascade: clock faces open on the ground round you, then columns of red light fall on them
		private static function aCascade(n:int, dmg:int, cd:Number):Object {
			return rain(n, 6, dmg, cd, A_RED, {radius: 1.4, delay: 1.4, stagger: 0.12, marker: "clock", fx: "pillar", burst: 4, bspd: 4, blife: 0.8, shape: "star",
				anim: "cascade", animMs: 110, animHit: 3, animHold: 1.4, name: "temporal cascade"});
		}
		// Summon the Conclave: acolytes step out of rifts at his sides
		private static function aSummon(n:int, cd:Number):Object {
			return o(summon("blood_acolyte", n, cd, 8), {anim: "summon", animMs: 130});
		}
		/** Archon Vesper's blood brand: n players marked; it bursts on whoever stands with them (Enemy "brand"). */
		private static function bloodBrand(n:int, dmg:int, cd:Number, x:Object = null):Object {
			return o({p: "brand", n: n, dmg: dmg, cd: cd, radius: 3.6, delay: 4.5, col: 0xff1838, eff: "bleeding", name: "the blood brand"}, x);
		}
		/** Astraeon's eclipse: dur seconds of darkness, lit only by waves of falling stars (Enemy "eclipse"). */
		private static function eclipse(dur:Number, stars:int, dmg:int, cd:Number, x:Object = null):Object {
			return o({p: "eclipse", dur: dur, stars: stars, gap: 1.3, spread: 9, radius: 1.6, delay: 1.2, dmg: dmg, cd: cd, col: 0xffe080,
				burst: 6, bspd: 4.5, blife: 0.9, fx: "pillar", shape: "star", name: "a falling star"}, x);
		}
		/** The boss vanishes and reappears nearby, leaving a ring of shots behind. */
		private static function blinkRing(cd:Number, col:uint):Object {
			return ring(10, 18, 4, 60, cd, col, {shape: "star", life: 2.0, blink: 6, name: "blink"});
		}
		/** Shots loosed ahead, and the boss lunges after them. */
		private static function dashAt(dmg:int, cd:Number, col:uint, x:Object = null):Object {
			return aim(5, 50, 10, dmg, cd, col, o({shape: "crescent", r: 0.38, life: 1.0, dash: 0.5, dashSpd: 10, name: "charge"}, x));
		}

		/**
		 * Heroic raids (two keys of the raid at the Raid Table): its bosses tougher and
		 * fiercer, its guards too, and better loot (luck on every boss, see worldsim
		 * dropLoot). Every raid has a weekly first clear of its own on each difficulty.
		 */
		public static const HEROIC:Object = {hp: 1.6, dmg: 1.25, rate: 1.1, guardHp: 1.5, guardDmg: 1.2, luck: 60};

		/** Makes a raid monster heroic (its boss or one of its guards). */
		public static function heroicEnemy(e:Enemy, boss:Boolean, th:Object = null):void {
			if (!e) return;
			// (a raid's theme can make its Heroic tougher still: the Starfall Vault's heroicHp)
			e.maxHp *= (boss ? HEROIC.hp : HEROIC.guardHp) * (th && th.heroicHp ? Number(th.heroicHp) : 1);
			e.hp = e.maxHp;
			e.dmgMult *= boss ? HEROIC.dmg : HEROIC.guardDmg;
			if (boss) e.rateMult *= HEROIC.rate;
		}

		/** A raid's name as its portal and banners show it. */
		public static function raidName(i:int, heroic:Boolean):String {
			var rd:Object = RAIDS[i];
			return rd ? (heroic ? "Heroic " : "") + rd.name : "";
		}

		public static const RAIDS:Array = [
			{id: "conclave", name: "The Crimson Conclave", color: 0xff3050,
				stages: [["zealot_a", "zealot_b"], ["blood_altar", "blood_altar", "blood_altar", "blood_altar"], ["matron"], ["archon"]],
				places: ["the Zealots' chapels", "the Blood Rite", "the Matron's sanctum", "the Archon's altar"],
				intro: "The Conclave's blood rites have begun. Slay both Zealots in their chapels (together: kill one and the other drinks its blood) to break the first seal. " +
					"Then break the four Blood Altars that keep the Matron's rite. Beware the blood pools.",
				theme: {id: "conclave", name: "The Crimson Conclave", color: 0xff3050, floor: 9, accent: 14, tier: 4, hard: 2.2, raid: true, layout: "conclave",
					mobs: ["crimson_cultist", "crimson_cultist", "bone_thrall", "blood_hound", "blood_acolyte"]}},
			{id: "storm", name: "Heart of the Storm", color: 0x80ffff,
				stages: [["sentinel_a", "sentinel_b", "sentinel_c"], ["storm_rod", "storm_rod", "storm_rod"], ["galecaller"], ["tempestus"]],
				places: ["the three pylons", "the Lightning Rods", "the Galecaller's terrace", "the eye of the storm"],
				intro: "Climb into the eye of the storm. Destroy the three Thunder Sentinels on their pylons (each one that falls charges the others) to raise the first bridge. " +
					"Then break the Lightning Rods on the terrace to call the Galecaller down. Keep moving: lightning strikes where you stand.",
				theme: {id: "storm", name: "Heart of the Storm", color: 0x80ffff, floor: 13, accent: 0, tier: 4, hard: 2.2, raid: true, layout: "spire",
					mobs: ["gale_harpy", "gale_harpy", "thunder_golem", "cloud_serpent", "storm_wisp"]}},
			{id: "starfall", name: "The Starfall Vault", color: 0xffd060, takeover: true, twists: true,
				stages: [["ignis"], ["archivist"], ["sovereign"], ["astraeon"]],
				places: ["the Hall of Embers", "the Drowned Archive", "the Bone Crypt", "the Star Throne"],
				intro: "Deep beneath Eldmere lies the vault where a star fell. Four masters guard it, and each one remakes the whole vault in its own image when it wakes: break what feeds it, and mind the floor.",
				theme: {id: "starfall", name: "The Starfall Vault", color: 0xffd060, floor: 9, accent: 26, tier: 5, hard: 2.4, raid: true, heroicHp: 1.6, layout: "starfall",
					mobs: ["royal_guard", "grave_wraith", "cube_shard", "temple_scorpion", "bone_thrall"]}}
		];

		private static function raids():void {
			var raid:Object = {gold: 800, onrane: 10, raid: true, aggro: 20, range: 16};
			// the raids' objectives (a stage of their own: it ends when they're all broken, see stageFoe)
			mob("blood_altar", {ai: "still", spd: 0, r: 0.8, aggro: 16, range: 14, drop: 0, xp: 300, keep: 0, prop: true, stageFoe: true,
				name: "Blood Altar", spr: "blood_altar", hp: 40000, def: 30, col: 0xd8102a,
				attacks: [ring(10, 18, 4.2, 80, 1.7, 0xd8102a, {shape: "orb", eff: "bleeding"}),
					rain(4, 3.5, 95, 2.6, 0xff3040, {radius: 1.4, delay: 1.1, fx: "spikes", name: "blood geyser"}),
					spiral(2, 21, 5, 70, 0.16, 0xff3040, {shape: "orb", name: "bleeding spiral"})]});
			mob("storm_rod", {ai: "still", spd: 0, r: 0.8, aggro: 16, range: 15, drop: 0, xp: 300, keep: 0, prop: true, stageFoe: true,
				name: "Lightning Rod", spr: "storm_rod", hp: 45000, def: 32, col: 0x80ffff,
				attacks: [aim(1, 0, 13, 90, 1.0, 0xe0ffff, {shape: "bolt", r: 0.26, eff: "paralyzed", name: "chain lightning"}),
					rain(4, 5, 100, 2.4, 0x80ffff, {radius: 1.3, delay: 1.0, fx: "pillar", name: "lightning strike"}),
					ring(12, 15, 4.5, 75, 1.9, 0xe0ffff, {shape: "bolt", name: "static ring"})]});
			// ---- the Crimson Conclave: blood rising out of the floor, bones and bleeding blades
			boss("zealot_a", o({bond: "The surviving Zealot drinks its twin's blood! It heals and rages!", name: "Zealot of Blood", spr: "zealot", hp: 18000, def: 22, spd: 2, xp: 1500, col: 0xd02030, phases: [
				P(1, {move: "orbit", attacks: [aim(3, 24, 8, 70, 0.9, 0xff3040, {eff: "bleeding", shape: "crescent", r: 0.3}),
					lineRain(5, 85, 3.2, 0xff2030, "spikes", {name: "blood geyser"}), ring(12, 15, 4, 60, 1.6, 0xd02030)]}),
				P(0.5, {say: "For the Archon!", shield: 1.5, move: "chase",
					attacks: [dashAt(85, 3.4, 0xff3040, {eff: "bleeding"}), selfNova(3.6, 1.1, 110, 4.2, 0xd02030, {fx: "spikes", burst: 10, shape: "spike"}),
						spiral(3, 23, 6, 70, 0.12, 0xff3040)]})
			]}, raid));
			boss("zealot_b", o({bond: "The surviving Zealot drinks its twin's blood! It heals and rages!", name: "Zealot of Bone", spr: "zealot", hp: 18000, def: 22, spd: 2, xp: 1500, col: 0xe8e0c8, phases: [
				P(1, {move: "orbit", attacks: [wall(9, 5, 70, 2, 0xe8e0c8, {shape: "spike"}), aim(1, 0, 6, 80, 1.4, 0xffffff, {motion: "home", shape: "soul"}),
					rain(4, 4, 90, 3.0, 0xe8e0c8, {fx: "spikes", radius: 1.3, name: "bone spikes"})]}),
				P(0.5, {say: "Bones to dust!", shield: 1.5, move: "orbit",
					attacks: [blinkRing(5, 0xe8e0c8), pull(12, 70, 3.6, 0xe8e0c8, {shape: "spike", name: "the grave's pull"}), rain(5, 4, 90, 2.2, 0xe8e0c8)]})
			]}, raid));
			boss("matron", o({name: "Matron Sanguine", spr: "matron", hp: 38000, def: 26, spd: 1.6, xp: 3000, col: 0xff4040, phases: [
				P(1, {say: "My zealots! You will pay in blood.", move: "orbit",
					attacks: [flower(20, 9, 5, 75, 1.0, 0xff4040), aim(5, 40, 8, 75, 1.0, 0xffa0a0, {eff: "bleeding", shape: "crescent", r: 0.3}),
						lineRain(6, 95, 3.6, 0xff2030, "spikes", {name: "blood geyser"})]}),
				P(0.6, {say: "Acolytes, to me!", shield: 2.5, summon: [{what: "blood_acolyte", n: 4}], move: "center", every: 4,
					cycle: [[pull(16, 80, 1.8, 0xff4040, {eff: "bleeding", name: "the Matron's thirst"})],
						[rain(7, 6, 100, 1.8, 0xff2020, {burst: 6, fx: "spikes"})],
						[wall(19, 5, 85, 1.4, 0xd02030, {hole: 3, shape: "crescent"})]]}),
				P(0.25, {say: "Drink deep!", banner: "The Matron feasts!", move: "chase", speed: 1.3,
					attacks: [spiral(6, 13, 6.5, 80, 0.1, 0xff4040), selfNova(5, 1.3, 150, 4.4, 0xd02030, {burst: 18, eff: "bleeding", fx: "spikes", shape: "spike", name: "the blood rite"}),
						dashAt(100, 4.2, 0xff4040)]})
			]}, raid), ["blood_chalice"]);
			// Archon Vesper, Architect of Void-Time, after his design sheet: every attack has its own animation
			// (tools/bossart/vesper.py); he guards behind his kite shield while a phase's shield holds, and brands
			// one of you in blood (two at the end) who has to leave the group before it bursts
			boss("archon", o({name: "Archon Vesper", spr: "archon", uchance: PRIMORDIAL_CHANCE, hp: 60000, def: 32, spd: 1.6, xp: 6000, col: A_RED, gold: 2000, onrane: 25, r: 1.1,
				seq: {idle: 4, move: 6, lance: 6, ranged: 5, gravity: 6, dash: 6, cascade: 6, brand: 5, summon: 5, guard: 4, death: 7, ridle: 4, rmove: 6}, rageAt: 3, phases: [
				P(1, {say: "My designs encompass eternity; your fate is a mere footnote.", move: "orbit",
					attacks: [aLance(90, 2.4), aRanged(5, 70, 1.9), aCascade(6, 105, 3.8)]}),
				P(0.8, {say: "Every second you breathe, I have already written.", shield: 3, move: "center", every: 4,
					cycle: [[aGravity(16, 80, 3.0), aRanged(7, 70, 1.4)],
						[aCascade(10, 115, 1.6), aLance(95, 1.8)],
						[bloodBrand(1, 160, 4, {anim: "brand", animMs: 110, animHit: 3}), aDash(95, 2.2)]]}),
				P(0.55, {say: "The Conclave answers its Architect!", banner: "Vesper calls the Conclave!", summon: [{what: "blood_acolyte", n: 6}], move: "orbit",
					attacks: [spiral(5, -11, 6, 80, 0.12, A_PALE, {shape: "voidorb"}), aBlink(6), aGravity(18, 90, 4.0), aSummon(2, 9),
						bloodBrand(1, 180, 9, {anim: "brand", animMs: 110, animHit: 3}), aLanceDash(110, 4.6)]}),
				P(0.25, {say: "TIME ITSELF ENDS AT MY WORD!", banner: "The Architect unmakes the hour!", shield: 3, move: "orbit", speed: 1.5,
					attacks: [spiral(5, 9, 6.5, 90, 0.12, A_RED, {motion: "wave", shape: "voidorb"}), aCascade(14, 130, 2.2), aLance(110, 1.6),
						aRanged(9, 90, 1.7), aDash(110, 3.0), bloodBrand(2, 200, 8.5, {name: "the crimson brand", anim: "brand", animMs: 110, animHit: 3})]})
			]}, raid), ["vesper_staff", "crimson_crown", "vesper_kiss", "bloodsworn_bulwark", "red_mass_codex", "first_zealot_skull", "vesper_shroud", "heartblood_signet", "unbleeding_ring", "archon_brand"]);

			// ---- Heart of the Storm: lightning out of the sky, winds that drag you, bolts that stun
			for each (var sid:String in ["sentinel_a", "sentinel_b", "sentinel_c"]) {
				boss(sid, o({bond: "A Sentinel falls! Its charge surges into the others!", name: "Thunder Sentinel", spr: "sentinel", hp: 14000, def: 24, spd: 1.8, xp: 1200, col: 0xffff60, phases: [
					P(1, {move: sid == "sentinel_b" ? "orbit" : "wander", attacks: [aim(1, 0, 13, 90, 0.8, 0xffffff, {shape: "bolt", eff: "paralyzed", r: 0.26}),
						ring(10, 18, 5, 60, 1.6, 0xffff60), pillars(3, 95, 3.6, 0xffff60, {name: "lightning strike"})]}),
					P(0.4, {say: "*crackles*", shield: 1, move: "chase", attacks: [spiral(2, 37, 7, 70, 0.1, 0xffff80), dashAt(85, 4.0, 0xffff60, {shape: "bolt"})]})
				]}, raid));
			}
			boss("galecaller", o({name: "Galecaller Ysra", spr: "galecaller", hp: 36000, def: 24, spd: 2.6, xp: 3000, col: 0x80ffff, phases: [
				P(1, {say: "The winds obey me.", move: "orbit", speed: 1.3,
					attacks: [aim(5, 50, 8, 75, 0.9, 0x80ffff, {motion: "wave", shape: "spear"}), ring(16, 11, 4, 65, 1.4, 0xd0f0ff, {motion: "return"}),
						lineRain(6, 90, 3.4, 0x80ffff, "pillar", {name: "cyclone"}), blinkRing(8, 0xd0f0ff)]}),
				P(0.6, {say: "Wisps, scatter them!", shield: 2, summon: [{what: "storm_wisp", n: 4}], move: "orbit",
					attacks: [wall(19, 6, 85, 1.6, 0x60a0ff, {hole: 3}), aim(3, 30, 6, 80, 1.6, 0x80ffff, {motion: "home"}),
						pull(16, 80, 3.4, 0xd0f0ff, {eff: "slowed", name: "the gale's pull"})]}),
				P(0.25, {say: "HURRICANE!", banner: "A hurricane forms!", move: "center",
					attacks: [spiral(8, 7, 6, 80, 0.1, 0xd0f0ff, {motion: "accel", accel: 0.4}), pull(20, 90, 3.0, 0x80ffff, {radius: 6.5, eff: "slowed", name: "the hurricane"}),
						rain(8, 6, 110, 1.8, 0x80ffff, {burst: 6, fx: "pillar"})]})
			]}, raid), ["galecaller_bow"]);
			// Tempestus, after his design sheet: every attack has its own animation (tools/bossart/tempestus.py),
			// he guards behind a shell of storm-light while a phase's shield holds, and his chain lightning
			// jumps from one player to the next if they stand close together
			boss("tempestus", o({name: "Tempestus, Heart of the Storm", spr: "tempestus", uchance: PRIMORDIAL_CHANCE, hp: 62000, def: 30, spd: 2.0, xp: 6000, col: T_VIOLET, gold: 2000, onrane: 25, r: 1.1,
				seq: {idle: 4, move: 6, slash: 6, spread: 5, strike: 6, dash: 6, radius: 6, rain: 6, guard: 4, death: 7, ridle: 4, rmove: 6}, rageAt: 3, phases: [
				P(1, {say: "SO. YOU CLIMBED MY STORM.", move: "orbit",
					attacks: [tSlash(90, 2.4), tSpread(7, 70, 1.6), tStrike(130, 3.8), tChain(3, 110, 5.0)]}),
				P(0.8, {say: "THUNDER!", shield: 3, move: "center", every: 3.5,
					cycle: [[tRain(10, 115, 1.4), tSpread(9, 70, 1.4)],
						[tRadius(150, 3.0, 5.5), tChain(4, 115, 2.4)],
						[tStrike(140, 1.4), flower(24, 6, 6, 85, 0.75, T_BLUE)]]}),
				P(0.5, {say: "LIGHTNING!", banner: "The storm's eye opens!", summon: [{what: "storm_wisp", n: 6}], move: "orbit",
					attacks: [tDash(100, 3.6), tBlink(6), tPull(18, 90, 4.2), tChain(5, 120, 4.4), spiral(5, 15, 6.5, 85, 0.12, T_PALE, {motion: "wave", shape: "voidorb"})]}),
				P(0.2, {say: "I AM THE STORM ETERNAL!", banner: "THE STORM IS MY HEART!", shield: 3, move: "orbit", speed: 1.6,
					attacks: [tRain(12, 125, 2.0), tChain(6, 130, 3.2), tSlash(110, 1.6), tRadius(170, 3.4, 6.5), spiral(6, 9, 6.5, 90, 0.12, T_PALE, {shape: "voidorb"})]})
			]}, raid), ["heart_of_storm", "stormbreaker", "tempest_eye", "stormweave_jerkin", "rolling_thunder", "squall_crown", "cyclone_snare", "galeband", "stormwall_ring", "lightning_rod"]);

			// ---- the Starfall Vault: four chambers, each a set piece that changes as you fight
			boss("ignis", o({name: "Ignis, Warden of Embers", spr: "vault_ignis", hp: 30000, def: 24, spd: 1.6, xp: 3000, col: 0xffb040, phases: [
				P(1, {say: "Who disturbs the vault?", move: "orbit",
					attacks: [aim(3, 26, 8, 80, 0.9, 0xffb040, {shape: "fire"}), ring(14, 13, 4.5, 70, 1.8, 0xff6020, {shape: "fire"}),
						pillars(5, 100, 3.2, 0xff7020, {name: "fire column"})]}),
				P(0.6, {say: "Burn!", shield: 2, move: "chase",
					attacks: [spiral(4, 17, 6, 80, 0.12, 0xffe060, {shape: "fire"}), dashAt(95, 3.6, 0xffb040, {shape: "fire", name: "blazing charge"}),
						rain(5, 4, 100, 2, 0xff7020, {burst: 6, fx: "spikes"})]}),
				P(0.25, {say: "THE EMBERS RISE!", banner: "Ignis blazes!", move: "center",
					attacks: [flower(24, 7, 5.5, 85, 0.8, 0xffb040, {shape: "fire"}), selfNova(5, 1.2, 150, 3.4, 0xff6020, {burst: 16, shape: "fire", fx: "pillar", name: "ember burst"}),
						lineRain(6, 110, 2.6, 0xff7020, "pillar", {name: "fire column"})]})
			]}, raid), ["ignis_brand", "everburning_flask"]);
			boss("archivist", o({name: "The Drowned Archivist", spr: "vault_archivist", hp: 32000, def: 24, spd: 1.4, xp: 3000, col: 0x40ffd0, phases: [
				P(1, {say: "Silence in the archive.", move: "orbit",
					attacks: [aim(5, 50, 7, 75, 1.1, 0x40ffd0, {motion: "wave"}), ring(12, 0, 4, 70, 2, 0xa0fff0, {motion: "return"}),
						pull(14, 75, 3.8, 0x40ffd0, {eff: "slowed", name: "the whirlpool"})]}),
				P(0.6, {say: "Overdue. All of you.", shield: 2, move: "orbit", summon: [{what: "grave_wraith", n: 3}],
					attacks: [wall(15, 5, 85, 1.8, 0x40ffd0, {hole: 3}), aim(1, 0, 6, 95, 1.4, 0xffffff, {motion: "home", eff: "slowed"}), blinkRing(7, 0xa0fff0)]}),
				P(0.3, {say: "Let the tide take the pages!", move: "center",
					attacks: [spiral(6, 13, 6, 80, 0.1, 0x60c0a0, {motion: "wave"}), lineRain(7, 110, 2.2, 0x40ffd0, "pillar", {name: "geyser"}),
						rain(6, 5, 110, 2, 0x40ffd0, {fx: "pillar"})]})
			]}, raid), ["drowned_codex", "siren_lyre"]);
			boss("sovereign", o({name: "Morvath the Bone Sovereign", spr: "vault_sovereign", hp: 34000, def: 28, spd: 1.3, xp: 3200, col: 0xc060ff, phases: [
				P(1, {say: "Kneel before the Sovereign.", move: "orbit",
					attacks: [aim(4, 30, 8, 85, 1.0, 0xe8e0c8, {shape: "blade"}), ring(16, 11, 4, 75, 1.7, 0xc060ff),
						lineRain(6, 100, 3.4, 0xe8e0c8, "spikes", {name: "bone spikes"})]}),
				P(0.55, {say: "Rise, my thralls!", shield: 2.5, summon: [{what: "bone_thrall", n: 2}], move: "chase",
					attacks: [spiral(4, -19, 6.5, 85, 0.12, 0xc060ff), aim(1, 0, 7, 110, 1.3, 0xff4060, {motion: "home", eff: "bleeding", r: 0.3}),
						selfNova(4.5, 1.3, 140, 4.0, 0xc060ff, {burst: 14, shape: "soul", fx: "spikes", name: "the Sovereign's decree"})]}),
				P(0.25, {say: "BONE AND BLOOD!", banner: "The crypt awakens!", move: "orbit",
					attacks: [flower(28, 6, 6, 90, 0.7, 0xe8e0c8), rain(8, 6, 120, 1.8, 0xc060ff, {burst: 8, fx: "spikes"}),
						pull(16, 95, 3.4, 0xc060ff, {shape: "soul", name: "soul drain"})]})
			]}, raid), ["sovereign_signet"]);
			boss("astraeon", o({name: "Astraeon, the Fallen Star", spr: "astraeon", uchance: PRIMORDIAL_CHANCE, hp: 72000, def: 32, spd: 1.8, xp: 7000, col: 0xffd060, gold: 2500, onrane: 30, r: 1.1, phases: [
				P(1, {say: "I fell so that you could rise. Now I will fall upon you.", move: "orbit",
					attacks: [spiral(4, 12, 6.5, 80, 0.13, 0xffd060, {shape: "star"}), aim(5, 40, 10, 95, 1.2, 0xffffff, {shape: "crescent", r: 0.3}),
						pillars(6, 115, 3.0, 0xffe080, {name: "starfall"})]}),
				P(0.75, {say: "Guards of the throne!", shield: 3, move: "center", every: 4,
					cycle: [[flower(24, 5.6, 5.5, 85, 0.85, 0xffd060)], [wall(21, 5.5, 95, 1.4, 0xfff0a0, {hole: 3, waves: 2, gap: 0.7})],
						[rain(10, 7, 130, 1.6, 0xffb040, {burst: 6, fx: "pillar"}), lineRain(7, 120, 1.6, 0xffe080, "pillar", {name: "falling stars"})]]}),
				P(0.5, {say: "Feel the heat of a dying star!", banner: "Starfire!", move: "orbit",
					attacks: [spiral(4, -11, 6, 90, 0.13, 0xffe080, {motion: "wave"}), selfNova(5.5, 1.4, 180, 3.2, 0xffb040, {burst: 14, shape: "star", fx: "pillar", name: "supernova"}),
						blinkRing(6, 0xfff0a0), pull(18, 100, 4.0, 0xffd060, {shape: "star", name: "the star's gravity"}), eclipse(10, 4, 140, 24)]}),
				P(0.25, {say: "I AM THE LIGHT THAT ENDS!", shield: 3, move: "orbit", speed: 1.5,
					attacks: [spiral(5, 9, 6.5, 95, 0.12, 0xffffff, {shape: "star"}), aim(7, 100, 9, 100, 1.3, 0xffd060, {shape: "crescent", waves: 2, gap: 0.3}),
						selfNova(6, 1.5, 200, 2.8, 0xffe080, {burst: 16, shape: "star", fx: "pillar", name: "supernova"}), lineRain(8, 130, 2.0, 0xffe080, "pillar", {name: "falling stars"}), eclipse(12, 5, 160, 20)]})
			]}, raid), ["starfall_staff", "fallen_star_mantle", "hourglass_fallen_star", "seventh_star_wand", "falling_sky_spell", "star_throne_aegis", "liquid_starlight", "lyre_of_spheres", "starwell_ring", "eye_of_astraeon", "comets_tail"]);
		}
	}
}
