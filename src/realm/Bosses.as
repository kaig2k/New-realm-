package realm {
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
		private static function boss(id:String, fields:Object, uniques:Array = null):void {
			var d:Object = Data.ENEMIES[id];
			if (!d) d = Data.ENEMIES[id] = {ai: "boss", r: 0.9, drop: 1, aggro: 14, range: 14, def: 20, spd: 1.4, xp: 1500};
			for (var k:String in fields) d[k] = fields[k];
			if (uniques) {
				d.uniques = uniques;
				for each (var u:String in uniques) Uniques.source[u] = d.name;
			}
		}

		private static function mob(id:String, fields:Object):void {
			Data.ENEMIES[id] = o({ai: "chase", keep: 2, drop: 0, r: 0.4, def: 5, spd: 2, xp: 20}, fields);
		}

		public static function init():void {
			if (done) return;
			done = true;
			art();
			minions();
			lowDungeons();
			midDungeons();
			events();
			hardDungeons();
			finales();
			raids();
		}

		// ------------------------------------------------------------ art for new bosses
		private static function art():void {
			Sprites.recolor("colossus", "titan", {R: 0x2a2a34, r: 0x141418, Y: 0xc070ff, L: 0x8030ff}, 6);
			Sprites.recolor("phoenix", "seraph", {Y: 0xffd040, W: 0xff8030, S: 0xffe0a0, E: 0x601000, G: 0xff4010, g: 0xa02008}, 6);
			Sprites.recolor("witch", "lich_king", {Y: 0x80ff60, B: 0x3a2a4a, E: 0xc0ff40, R: 0xff60ff, T: 0x2a2a2a, P: 0x2a6a2a, p: 0x143a14, G: 0xff80ff}, 5);
			Sprites.recolor("kraken", "hermit", {S: 0x6a3a8a, s: 0x3a1a5a, C: 0xff6080, c: 0xa02040, E: 0xffe040, W: 0xffffff}, 6);
			Sprites.recolor("tide_empress", "serpent_queen", {Y: 0x80f0ff, G: 0x1a6aa0, g: 0x0a3a60, S: 0xa0e0ff, E: 0x101010, P: 0x2ac0c0, p: 0x1a7070}, 6);
			Sprites.recolor("gearmind", "boss", {Y: 0xc0a060, y: 0x806030, Q: 0x60e0ff, P: 0x6a6a72, p: 0x3a3a42, W: 0xffffff, E: 0x40ff80, K: 0x101010}, 6);
			Sprites.recolor("void_dragon", "wyrm", {C: 0x4a2a7a, c: 0x1a0a2a, W: 0xc080ff, w: 0x8040c0, E: 0xff40ff, K: 0xffffff}, 7);
			Sprites.recolor("matron", "regent", {Y: 0xff4040, y: 0xa01010, C: 0x6a0a1a, c: 0x3a0008, Q: 0xffd0d0, E: 0xff2020, W: 0xffa0a0, M: 0x8a2030, m: 0x5a1020}, 6);
			Sprites.recolor("archon", "elder", {H: 0xffe0e0, h: 0xa08080, P: 0x8a0a2a, p: 0x4a0414, Q: 0xffd040, K: 0x100004, E: 0xff2040, W: 0xffd0e0, O: 0xff6080}, 7);
			Sprites.recolor("zealot", "sorcerer", {H: 0xa01828, h: 0x5a0a14, S: 0xf5dc72, E: 0x101010, W: 0xf0f0f0, R: 0xc02030, r: 0x6a0a18, O: 0xff8080, o: 0xffffff}, 4);
			Sprites.recolor("galecaller", "seraph", {Y: 0x80ffff, W: 0xd0f0ff, S: 0xf5dc72, E: 0x2040a0, G: 0x60a0ff, g: 0x3060c0}, 5);
			Sprites.recolor("tempestus", "wyrm", {C: 0x80b0ff, c: 0x4060c0, W: 0xffff80, w: 0xc0c060, E: 0xffffff, K: 0xffff00}, 7);
			Sprites.recolor("raidtable", "chest", {K: 0x2a0810, C: 0xa01830, c: 0x6a0a1c, Y: 0xffd040}, 6);
			Sprites.recolor("sentinel", "warden", {H: 0xe0e080, h: 0x8a8a40, E: 0xffff40, G: 0xffffff, A: 0x203050, M: 0x6080c0, m: 0x304070, L: 0xffff60, l: 0xd0d0d0}, 4);
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
				P(1, {move: "wander", attacks: [aim(3, 26, 6, 35, 0.8, 0x60e060, {motion: "wave"}), ring(12, 13, 4, 30, 2.0, 0x2a9a6a, {eff: "slowed"})]}),
				P(0.66, {say: "Ssslither... and die.", shield: 2, move: "orbit",
					attacks: [spiral(2, 23, 5.5, 32, 0.12, 0x80ff80, {motion: "wave"}), summon("great_snake", 2, 8, 4)]}),
				P(0.33, {say: "The pit hungers!", move: "chase", speed: 1.3,
					attacks: [wall(11, 6, 40, 2.0, 0x40c040, {eff: "bleeding"}), aim(7, 70, 7, 35, 1.3, 0xa0ffa0)]})
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
				P(1, {move: "orbit", attacks: [spiral(3, 19, 7, 50, 0.12, 0xfff060, {shape: "dart"})]}),
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
				P(1, {move: "chase", attacks: [aim(5, 40, 8, 70, 0.9, 0xff6020), rain(4, 3, 80, 2.4, 0xff3010, {burst: 6})]}),
				P(0.66, {say: "Kneel before the Abyss!", shield: 2, summon: [{what: "lesser_demon", n: 3}], move: "charge", speed: 1.4,
					attacks: [flower(20, 9, 5.5, 65, 1.0, 0xff8040), aim(1, 0, 11, 110, 0.8, 0xffe040, {shape: "blade", r: 0.3, eff: "armorbroken"})]}),
				P(0.3, {say: "I AM THE ABYSS!", banner: "Malgoroth rages!", move: "center",
					attacks: [spiral(6, 13, 6.5, 65, 0.1, 0xff4020), nova(2.5, 1.2, 120, 2.2, 0xff2010, {burst: 12}), wall(15, 5.5, 80, 2.8, 0xffb030)]})
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

			boss("ev_wyrm", {phases: [
				P(1, {move: "orbit", speed: 1.3, attacks: [spiral(5, 9, 6.5, 50, 0.16, 0x8ad8ff, {eff: "slowed"})]}),
				P(0.66, {say: "Freeze, little warm thing.", move: "teleport",
					attacks: [aim(9, 90, 7, 60, 0.9, 0xe0f4ff, {motion: "wave"}), ring(16, 11, 3.5, 55, 1.6, 0x40a0ff, {motion: "accel", accel: 0.8})]}),
				P(0.33, {say: "WINTER COMES!", banner: "Blizzard!", shield: 2, move: "center",
					attacks: [rain(10, 7, 70, 1.8, 0xc0ecff, {delay: 1.0, eff: "slowed"}), spiral(8, -7, 5.5, 60, 0.14, 0xc0ecff)]})
			]}, ["frostfang", "wyrmscale"]);

			boss("ev_king", {phases: [
				P(1, {move: "wander", attacks: [aim(3, 20, 8, 70, 1.0, 0x9aff7a, {eff: "bleeding"}), summon("skeleton", 2, 6, 6)]}),
				P(0.66, {say: "My court rises!", summon: [{what: "skeleton", n: 4}], shield: 2, move: "center",
					attacks: [ring(20, 9, 4.5, 55, 1.0, 0x6aff4a), wall(11, 5, 70, 2.2, 0xe8e0c8)]}),
				P(0.33, {say: "I am the hollow crown!", move: "chase",
					attacks: [spiral(4, 14, 6, 65, 0.12, 0x9aff7a), nova(2, 1.0, 100, 2.2, 0x6aff4a, {burst: 8, eff: "bleeding"})]})
			]}, ["hollow_crown", "kings_ransom"]);

			boss("ev_behemoth", {phases: [
				P(1, {move: "charge", attacks: [aim(7, 70, 7, 70, 1.2, 0x9aff5a, {eff: "bleeding"})]}),
				P(0.66, {say: "*THUNDEROUS ROAR*", shield: 1.5, summon: [{what: "orc", n: 3}], move: "charge", speed: 1.3,
					attacks: [ring(20, 9, 5, 60, 0.9, 0x6ac040), wall(13, 6, 75, 2.4, 0x9aff5a)]}),
				P(0.33, {say: "*STAMPEDE*", banner: "Gorehorn stampedes!", move: "charge", speed: 1.8,
					attacks: [spiral(4, 21, 7, 65, 0.1, 0xc0ff60), aim(3, 30, 10, 90, 0.8, 0xffffff, {shape: "blade", eff: "armorbroken"})]})
			]}, ["gorehorn_bow", "behemoth_hide"]);

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
				P(1, {move: "still", attacks: [ring(18, 10, 4, 55, 1.2, 0x2a9a8a), aim(1, 0, 10, 80, 0.8, 0xe0ff80)]}),
				P(0.6, {say: "Leave my shore!", shield: 3, move: "still", summon: [{what: "crab", n: 4}],
					attacks: [flower(24, 7.5, 4.5, 60, 0.9, 0x40e0c0, {motion: "return"})]}),
				P(0.3, {say: "*the shell cracks*", banner: "The Hermit emerges!", move: "chase", speed: 1.5,
					attacks: [spiral(6, 15, 6.5, 65, 0.1, 0xe0ff80), rain(4, 3, 90, 2.2, 0x2a9a8a)]})
			]}, ["tidecaller", "hermit_shell"]);

			boss("ev_shrine", {phases: [
				P(1, {move: "still", attacks: [spiral(4, 11, 5.5, 60, 0.13, 0xff8a20), aim(3, 20, 9, 75, 1.2, 0xffe040)]}),
				P(0.66, {say: "THE SHRINE DEMANDS TRIBUTE", shield: 3, summon: [{what: "skeleton", n: 4}], move: "still",
					attacks: [flower(20, 9, 5, 65, 0.9, 0xff2020), rain(5, 5, 90, 2.2, 0xff8a20, {burst: 6})]}),
				P(0.33, {say: "BURN IN ITS FLAMES", move: "still", every: 3,
					cycle: [[spiral(8, 9, 6, 65, 0.1, 0xff8a20)], [spiral(8, -9, 6, 65, 0.1, 0xffe040)], [wall(17, 5, 80, 1, 0xff2020, {hole: 2})]]})
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

		// ------------------------------------------------------------ hard dungeons
		private static function hardDungeons():void {
			boss("sun_king", {phases: [
				P(1, {move: "wander", attacks: [flower(16, 11, 5, 70, 1.0, 0xffb020), aim(3, 20, 9, 80, 1.0, 0xffe060)]}),
				P(0.5, {say: "Kneel before the noon sun!", shield: 1.5, move: "center",
					attacks: [spiral(6, 8, 6, 70, 0.12, 0xffd040), nova(2.5, 1.2, 120, 2.6, 0xff9020, {burst: 10})]})
			]}, ["solar_crown", "sunfire_staff"]);
			boss("moon_queen", {phases: [
				P(1, {move: "orbit", attacks: [aim(5, 50, 7, 70, 1.0, 0xb0c0ff, {motion: "wave"}), ring(16, 11, 4, 65, 1.4, 0x8a9aff, {motion: "return"})]}),
				P(0.5, {say: "The night is mine.", move: "teleport",
					attacks: [spiral(4, -14, 6, 70, 0.12, 0xd0d8ff), rain(5, 4, 100, 2.4, 0x6a7ac0, {eff: "slowed"})]})
			]}, ["moonlight_bow", "lunar_robe"]);
			boss("star_prince", {phases: [
				P(1, {move: "teleport", attacks: [aim(3, 30, 9, 75, 0.8, 0xd080ff, {shape: "star"}), aim(1, 0, 6, 80, 1.6, 0xfff060, {motion: "home"})]}),
				P(0.5, {say: "Watch the stars fall!", move: "orbit",
					attacks: [rain(8, 6, 90, 2, 0xc070ff, {burst: 4}), spiral(3, 23, 7, 70, 0.1, 0xfff060)]})
			]}, ["starfall_dagger", "astral_cloak"]);
			boss("frost_warden", {phases: [
				P(1, {move: "wander", attacks: [spiral(4, 10, 5, 70, 0.14, 0x80e0ff, {eff: "slowed"}), aim(1, 0, 12, 110, 0.9, 0xffffff, {shape: "blade", r: 0.3})]}),
				P(0.5, {say: "The cold takes everything.", shield: 2, move: "center",
					attacks: [wall(15, 4.5, 90, 1.8, 0xc0e8ff, {eff: "slowed"}), rain(5, 5, 100, 2.4, 0x80f0ff)]})
			]}, ["glacial_plate", "icicle_ring"]);
			boss("flame_warden", {phases: [
				P(1, {move: "chase", attacks: [aim(5, 50, 8, 75, 1.0, 0xff6020), ring(12, 15, 4, 70, 1.5, 0xffb020, {split: {n: 4, spd: 4, life: 0.8, dmg: 45}, life: 1.4})]}),
				P(0.5, {say: "Burn with your friend!", shield: 2, move: "charge",
					attacks: [spiral(5, 13, 6, 75, 0.12, 0xff6020), nova(2.2, 1, 110, 2.2, 0xff3010, {burst: 8})]})
			]}, ["flamewarden_blade", "ember_ring"]);
			boss("shattered_seraph", {phases: [
				P(1, {move: "orbit", attacks: [spiral(4, 12, 6, 70, 0.12, 0xff60c0), aim(3, 24, 10, 90, 1.0, 0xffffff, {shape: "blade"})]}),
				P(0.75, {say: "You broke the seal... now see what you freed.", shield: 2.5, summon: [{what: "sprite_god", n: 2}], move: "center",
					attacks: [flower(24, 7.5, 5, 75, 0.9, 0xff60c0), wall(17, 5, 90, 2.2, 0xd8d0e8)]}),
				P(0.45, {say: "SHATTER!", banner: "The Seraph shatters!", move: "teleport",
					attacks: [rain(9, 7, 110, 1.8, 0xff2060, {burst: 6}), spiral(6, -9, 6.5, 75, 0.11, 0xd8d0e8)]}),
				P(0.15, {say: "I... will not... fade!", shield: 2, move: "center", every: 3,
					cycle: [[flower(30, 6, 6, 80, 0.6, 0xff60c0)], [aim(9, 120, 9, 90, 0.5, 0xffffff, {shape: "blade", waves: 3, gap: 0.2})]]})
			]}, ["shardwing_bow", "seraph_halo"]);
			boss("blood_knight", {phases: [
				P(1, {move: "charge", speed: 1.3, attacks: [aim(3, 30, 9, 85, 0.9, 0xd02030, {eff: "bleeding"}), wall(9, 6, 80, 2.4, 0xff4040)]}),
				P(0.5, {say: "Your blood will feed my blade!", shield: 1.5, move: "chase", speed: 1.5,
					attacks: [spiral(4, 17, 6.5, 80, 0.11, 0xff4040), nova(2, 0.9, 120, 2, 0xd02030, {burst: 8, eff: "bleeding"})]})
			]}, ["bloodletter", "sanguine_plate"]);
			boss("hex_queen", {phases: [
				P(1, {move: "teleport", attacks: [aim(3, 30, 7, 75, 1.0, 0x80ff60, {motion: "home", eff: "confused"}), rain(4, 4, 90, 2.6, 0xd060ff)]}),
				P(0.5, {say: "A curse on all your houses!", shield: 2, move: "orbit",
					attacks: [flower(20, 9, 5, 75, 1.0, 0x80ff60, {split: {n: 4, spd: 4, life: 0.9, dmg: 45}, life: 1.5}), wall(13, 5, 90, 2.2, 0xd060ff, {eff: "slowed"})]})
			]}, ["hexweave_robe", "cursed_skull"]);
		}

		// ------------------------------------------------------------ realm finales
		/** Where a closing realm sends everyone: one of these, picked per realm. */
		public static const FINALES:Array = ["citadel", "drowned_throne", "clockwork_foundry", "void_rift"];

		private static function finales():void {
			// Azrakor (the Citadel's master) keeps his crystal phase and gets a fuller script
			boss("elder", {phases: [
				P(1, {move: "orbit", attacks: [spiral(4, 12, 5.5, 60, 0.12, 0xc060ff), aim(3, 18, 10, 80, 1.2, 0xffe060, {shape: "blade"})]}),
				P(0.75, {say: "You amuse me. Let us see you dance.", shield: 2, move: "center", every: 5,
					cycle: [[ring(32, 5.6, 4.5, 65, 1.0, 0xe02040), aim(7, 60, 8, 70, 1.3, 0xffffff, {eff: "confused"})],
						[wall(17, 5, 85, 1.5, 0xa040ff, {hole: 2}), summon("shade", 2, 8, 6)]]}),
				P(0.45, {move: "still",
					attacks: [rain(6, 6, 100, 2.4, 0xff4080, {burst: 6}), ring(12, 15, 3, 60, 2.0, 0xa040ff)]}),
				P(0.2, {say: "ENOUGH! I will end you myself!", banner: "Azrakor's true power!", shield: 2, move: "teleport",
					attacks: [spiral(6, -10, 6, 70, 0.1, 0xff40a0), aim(1, 0, 14, 130, 0.6, 0xffe060, {shape: "blade", eff: "armorbroken", r: 0.32}),
						nova(3, 1.3, 140, 3.2, 0xc060ff, {burst: 16})]})
			]}, ["elder_scepter", "crown_of_azrakor"]);

			boss("tide_empress", {name: "Nerezza, the Tide Empress", spr: "tide_empress", hp: 40000, def: 30, spd: 1.6, xp: 5000, col: 0x40d0ff,
				gold: 1500, onrane: 15, dungeon: true, dtier: 5, finale: true, aggro: 18, range: 16, phases: [
				P(1, {say: "You dare enter my throne room?", move: "orbit",
					attacks: [aim(5, 50, 7, 70, 1.0, 0x40d0ff, {motion: "wave"}), ring(18, 10, 4, 65, 1.6, 0x2ac0c0)]}),
				P(0.75, {say: "Rise, children of the deep!", shield: 2.5, summon: [{what: "tide_spawn", n: 4}], move: "center",
					attacks: [wall(19, 4, 85, 1.8, 0x60c0ff, {hole: 3, motion: "wave"}), summon("tide_spawn", 1, 9, 5)]}),
				P(0.5, {say: "The tide turns!", banner: "The throne room floods!", move: "teleport", every: 5,
					cycle: [[flower(24, 7.5, 5, 75, 0.9, 0x80f0ff, {motion: "return"})], [rain(9, 7, 110, 1.8, 0x40a0ff, {burst: 6})]]}),
				P(0.2, {say: "DROWN!", shield: 2, move: "orbit", speed: 1.4,
					attacks: [spiral(8, 9, 6, 80, 0.1, 0xa0e0ff, {motion: "wave"}), nova(3, 1.3, 140, 2.8, 0x2ac0c0, {burst: 16}), aim(3, 16, 11, 100, 0.8, 0xffffff, {shape: "blade"})]})
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
					cycle: [[spiral(6, 13, 6.5, 80, 0.1, 0xc080ff)], [rain(10, 7, 120, 1.8, 0xd040ff, {burst: 6})], [flower(30, 6, 5.5, 80, 0.7, 0xff40ff)]]}),
				P(0.2, {say: "I AM ETERNAL!", shield: 3, move: "orbit", speed: 1.4,
					attacks: [spiral(8, -11, 7, 85, 0.09, 0xff40ff), nova(3.5, 1.4, 160, 2.6, 0xd040ff, {burst: 20}), aim(5, 30, 11, 110, 1.0, 0xffffff, {shape: "blade", waves: 3, gap: 0.2})]})
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
		public static const RAIDS:Array = [
			{id: "conclave", name: "The Crimson Conclave", color: 0xff3050, key: "conclave_key", cost: 60,
				stages: [["zealot_a", "zealot_b"], ["matron"], ["archon"]],
				intro: "The Conclave's blood rites have begun. Stop them."},
			{id: "storm", name: "Heart of the Storm", color: 0x80ffff, key: "storm_key", cost: 60,
				stages: [["sentinel_a", "sentinel_b", "sentinel_c"], ["galecaller"], ["tempestus"]],
				intro: "Climb into the eye of the storm."}
		];

		private static function raids():void {
			var raid:Object = {gold: 800, onrane: 10, raid: true, aggro: 20, range: 16};
			boss("zealot_a", o({name: "Zealot of Blood", spr: "zealot", hp: 18000, def: 22, spd: 2, xp: 1500, col: 0xd02030, phases: [
				P(1, {move: "orbit", attacks: [aim(3, 24, 8, 70, 0.9, 0xff3040, {eff: "bleeding"}), ring(12, 15, 4, 60, 1.6, 0xd02030)]}),
				P(0.5, {say: "For the Archon!", shield: 1.5, move: "chase", attacks: [spiral(3, 23, 6, 70, 0.12, 0xff3040)]})
			]}, raid));
			boss("zealot_b", o({name: "Zealot of Bone", spr: "zealot", hp: 18000, def: 22, spd: 2, xp: 1500, col: 0xe8e0c8, phases: [
				P(1, {move: "orbit", attacks: [wall(9, 5, 70, 2, 0xe8e0c8), aim(1, 0, 6, 80, 1.4, 0xffffff, {motion: "home"})]}),
				P(0.5, {say: "Bones to dust!", shield: 1.5, move: "teleport", attacks: [rain(5, 4, 90, 2.2, 0xe8e0c8)]})
			]}, raid));
			boss("matron", o({name: "Matron Sanguine", spr: "matron", hp: 38000, def: 26, spd: 1.6, xp: 3000, col: 0xff4040, phases: [
				P(1, {say: "My zealots! You will pay in blood.", move: "orbit",
					attacks: [flower(20, 9, 5, 75, 1.0, 0xff4040), aim(5, 40, 8, 75, 1.0, 0xffa0a0, {eff: "bleeding"})]}),
				P(0.6, {say: "Acolytes, to me!", shield: 2.5, summon: [{what: "blood_acolyte", n: 4}], move: "center", every: 4,
					cycle: [[wall(19, 5, 85, 1.4, 0xd02030, {hole: 3})], [rain(7, 6, 100, 1.8, 0xff2020, {burst: 6})]]}),
				P(0.25, {say: "Drink deep!", banner: "The Matron feasts!", move: "chase", speed: 1.3,
					attacks: [spiral(6, 13, 6.5, 80, 0.1, 0xff4040), nova(3, 1.2, 140, 2.4, 0xd02030, {burst: 14, eff: "bleeding"})]})
			]}, raid), ["blood_chalice"]);
			boss("archon", o({name: "Archon Vesper", spr: "archon", hp: 60000, def: 32, spd: 1.6, xp: 6000, col: 0xff3060, gold: 2000, onrane: 25, phases: [
				P(1, {say: "So you are the ones who silenced my Matron.", move: "orbit",
					attacks: [spiral(4, 12, 6, 75, 0.12, 0xff3060), aim(3, 18, 10, 90, 1.0, 0xffd040, {shape: "blade"})]}),
				P(0.8, {say: "Witness the crimson rite!", shield: 3, move: "center", every: 4,
					cycle: [[flower(32, 5.6, 5, 80, 0.7, 0xff3060)], [wall(21, 5, 90, 1.3, 0xffd0e0, {hole: 2, waves: 2, gap: 0.6})], [rain(10, 7, 120, 1.6, 0xff2040, {burst: 6})]]}),
				P(0.55, {say: "Blood for the blood god!", banner: "Vesper calls the Conclave!", summon: [{what: "blood_acolyte", n: 6}], move: "teleport",
					attacks: [spiral(6, -11, 6.5, 80, 0.1, 0xff6080), aim(1, 0, 7, 100, 1.2, 0xff2040, {motion: "home", r: 0.3}), summon("blood_acolyte", 2, 9, 8)]}),
				P(0.25, {say: "I AM THE CRIMSON DAWN!", shield: 3, move: "orbit", speed: 1.5,
					attacks: [spiral(8, 9, 7, 90, 0.09, 0xff3060, {motion: "wave"}), nova(4, 1.5, 180, 2.4, 0xff2040, {burst: 24}),
						aim(9, 100, 9, 100, 1.2, 0xffffff, {shape: "blade", waves: 3, gap: 0.2})]})
			]}, raid), ["vesper_staff", "crimson_crown"]);

			for each (var sid:String in ["sentinel_a", "sentinel_b", "sentinel_c"]) {
				boss(sid, o({name: "Thunder Sentinel", spr: "sentinel", hp: 14000, def: 24, spd: 1.8, xp: 1200, col: 0xffff60, phases: [
					P(1, {move: sid == "sentinel_b" ? "orbit" : "wander", attacks: [aim(1, 0, 14, 90, 0.8, 0xffffff, {shape: "blade", eff: "paralyzed"}), ring(10, 18, 5, 60, 1.6, 0xffff60)]}),
					P(0.4, {say: "*crackles*", shield: 1, move: "chase", attacks: [spiral(2, 37, 7, 70, 0.1, 0xffff80)]})
				]}, raid));
			}
			boss("galecaller", o({name: "Galecaller Ysra", spr: "galecaller", hp: 36000, def: 24, spd: 2.6, xp: 3000, col: 0x80ffff, phases: [
				P(1, {say: "The winds obey me.", move: "orbit", speed: 1.3,
					attacks: [aim(5, 50, 8, 75, 0.9, 0x80ffff, {motion: "wave"}), ring(16, 11, 4, 65, 1.4, 0xd0f0ff, {motion: "return"})]}),
				P(0.6, {say: "Wisps, scatter them!", shield: 2, summon: [{what: "storm_wisp", n: 4}], move: "teleport",
					attacks: [wall(19, 6, 85, 1.6, 0x60a0ff, {hole: 3}), aim(3, 30, 6, 80, 1.6, 0x80ffff, {motion: "home"})]}),
				P(0.25, {say: "HURRICANE!", banner: "A hurricane forms!", move: "center",
					attacks: [spiral(8, 7, 6, 80, 0.1, 0xd0f0ff, {motion: "accel", accel: 0.4}), rain(8, 6, 110, 1.8, 0x80ffff, {burst: 6})]})
			]}, raid), ["galecaller_bow"]);
			boss("tempestus", o({name: "Tempestus, Heart of the Storm", spr: "tempestus", hp: 62000, def: 30, spd: 2.0, xp: 6000, col: 0xffff60, gold: 2000, onrane: 25, r: 1.1, phases: [
				P(1, {say: "SO. YOU CLIMBED MY STORM.", move: "orbit",
					attacks: [spiral(3, 23, 7, 75, 0.1, 0xffff60), aim(1, 0, 15, 110, 0.7, 0xffffff, {shape: "blade", eff: "paralyzed", r: 0.3})]}),
				P(0.8, {say: "THUNDER!", shield: 3, move: "center", every: 3.5,
					cycle: [[rain(10, 7, 120, 1.3, 0xffff80, {delay: 0.9})], [flower(30, 6, 6, 85, 0.6, 0x80b0ff)], [wall(21, 6, 90, 1.1, 0xffff60, {hole: 2})]]}),
				P(0.5, {say: "LIGHTNING!", banner: "The storm's eye opens!", summon: [{what: "storm_wisp", n: 6}], move: "teleport",
					attacks: [spiral(6, 15, 7, 85, 0.09, 0xffff80, {motion: "wave"}), nova(3, 1.1, 150, 2.2, 0xffff60, {burst: 16, eff: "paralyzed"})]}),
				P(0.2, {say: "I AM THE STORM ETERNAL!", shield: 3, move: "orbit", speed: 1.6,
					attacks: [spiral(10, 9, 7, 90, 0.09, 0xffffff), aim(7, 60, 10, 100, 0.9, 0x80ffff, {shape: "blade", waves: 3, gap: 0.15}),
						rain(8, 6, 130, 1.6, 0xffff60, {burst: 8})]})
			]}, raid), ["heart_of_storm", "stormbreaker"]);
		}
	}
}
