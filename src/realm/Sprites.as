package realm {
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	/**
	 * All art is defined here as tiny text-based pixel grids, then scaled up
	 * with a black outline -- the classic chunky 8x8 look.
	 */
	public class Sprites {
		public static const SCALE:int = 4;
		private static var cache:Object = {};

		// ---- templates -------------------------------------------------
		private static const ROBE:Array = [
			"...HH...",
			"..HHHH..",
			".HHHHHH.",
			"..SEES..",
			"..SSSS.W",
			".BBBBBBW",
			".BBBBBBW",
			"..L..L.W"];
		private static const ARCHER:Array = [
			"..HHHH..",
			".HHHHHH.",
			".HSEESH.",
			"..SSSS..",
			"W.BBBB..",
			"WBBBBBB.",
			"W.BBBB..",
			"..L..L.."];
		private static const KNIGHT:Array = [
			"..HHHH..",
			".HHHHHH.",
			".HEHHEH.",
			".HHHHHH.",
			"BBBBBBBW",
			"BBBBBBBW",
			".BBBBB.W",
			"..L..L.."];
		private static const PRIEST:Array = [
			"..HHHH..",
			".HSSSSH.",
			".HSEESH.",
			"..SSSS..",
			"WBBYYBB.",
			"WBYYYYB.",
			"W.BYYB..",
			"..L..L.."];
		private static const SNAKE:Array = [
			"........",
			"....GGG.",
			"...GEGG.",
			"...GG...",
			"..GG....",
			".GG..GG.",
			".GGGGGG.",
			"........"];
		private static const CRAB:Array = [
			"C......C",
			"CC....CC",
			".C.EE.C.",
			"..CCCC..",
			".CCCCCC.",
			"CCCCCCCC",
			".C.CC.C.",
			"C......C"];
		private static const BLOB:Array = [
			"..BBBB..",
			".BBBBBB.",
			"BBWWWWBB",
			"BBWEEWBB",
			"BBWEEWBB",
			"BBWWWWBB",
			".BBBBBB.",
			"..BBBB.."];
		private static const DJINN:Array = [
			"..CCCC..",
			".CCCCCC.",
			".CECCEC.",
			".CCCCCC.",
			"..CCCC..",
			"...CC...",
			"..CC....",
			".CC....."];
		private static const ENT:Array = [
			".GGGGGG.",
			"GGGGGGGG",
			"GGEGGEGG",
			"GGGGGGGG",
			".GGTTGG.",
			"...TT...",
			"..TTTT..",
			".TT..TT."];
		private static const MEDUSA:Array = [
			"G.G..G.G",
			".GGGGGG.",
			"GGSSSSGG",
			".GSEESG.",
			"..SSSS..",
			".BBBBBB.",
			"..BBBB..",
			".BBBBBB."];
		private static const CUBELET:Array = [
			"........",
			".PPPPPP.",
			".PQQQQP.",
			".PQEEQP.",
			".PQEEQP.",
			".PQQQQP.",
			".PPPPPP.",
			"........"];
		private static const BOSS:Array = [
			"...Y...YY...Y...",
			"...YY.YYYY.YY...",
			"...YYYYYYYYYY...",
			"..PPPPPPPPPPPP..",
			".PPQQQQQQQQQQPP.",
			".PQQQQQQQQQQQQP.",
			".PQQWWWWWWWWQQP.",
			".PQWWWWEEWWWWQP.",
			".PQWWWEEEEWWWQP.",
			".PQWWWWEEWWWWQP.",
			".PQQWWWWWWWWQQP.",
			".PQQQQQQQQQQQQP.",
			".PQQQRRRRRRQQQP.",
			".PPQQQQQQQQQQPP.",
			"..PPPPPPPPPPPP..",
			"...P..P..P..P..."];
		private static const BAG:Array = [
			"...KK...",
			"..K..K..",
			"..CCCC..",
			".CCCCCC.",
			"CCCDCCCC",
			"CCCCCCCC",
			".CCCCCC.",
			"........"];

		// item icons
		private static const I_STAFF:Array = [
			"......TT",
			".....TLT",
			"....TTT.",
			"...W....",
			"..W.....",
			".W......",
			"W.......",
			"........"];
		private static const I_BOW:Array = [
			"...WW...",
			"....WS..",
			".....WS.",
			"..TTTWTT",
			".....WS.",
			".....WS.",
			"....WS..",
			"...WW..."];
		private static const I_SWORD:Array = [
			".......T",
			"......TT",
			".....TT.",
			"....TT..",
			".GGTT...",
			"..GG....",
			".W.G....",
			"W......."];
		private static const I_WAND:Array = [
			"......TT",
			".....TLT",
			"......T.",
			".....W..",
			"....W...",
			"...W....",
			"..W.....",
			"........"];
		private static const I_ARMOR:Array = [
			".TT..TT.",
			"TAAAAAAT",
			"TAAAAAAT",
			".AAAAAA.",
			".AATTAA.",
			".AAAAAA.",
			".TTTTTT.",
			"........"];
		private static const I_POT:Array = [
			"...WW...",
			"...GG...",
			"..PPPP..",
			".PPPPPP.",
			".PLPPPP.",
			".PPPPPP.",
			"..PPPP..",
			"........"];

		public static const TIER_COLORS:Array = [0x8a8a8a, 0xb08d57, 0xd0d0d0, 0x5aa0e0, 0x50c050, 0xe0c040, 0xe06030, 0xb050e0, 0xffffff];

		private static const DEFS:Object = {
			wizard: [ROBE, {H: 0x3050c8, S: 0xf0c8a0, E: 0x101010, B: 0x2840a0, L: 0x403020, W: 0x8a5a2a}],
			archer: [ARCHER, {H: 0x2f7a2f, S: 0xf0c8a0, E: 0x101010, B: 0x3f8f3f, L: 0x5a4020, W: 0xa07040}],
			knight: [KNIGHT, {H: 0xb0b0b8, E: 0x101010, B: 0x8a8a96, L: 0x404048, W: 0xe0e0f0}],
			priest: [PRIEST, {H: 0xf0f0f0, S: 0xf0c8a0, E: 0x101010, B: 0xe8e8e8, Y: 0xf0c030, L: 0x705030, W: 0xd0a030}],
			pirate: [ARCHER, {H: 0xc02020, S: 0xe0b890, E: 0x101010, B: 0x5050a0, L: 0x302010, W: 0xb0b0b0}],
			snake: [SNAKE, {G: 0xc8b040, E: 0xff2020}],
			crab: [CRAB, {C: 0xe05030, E: 0x101010}],
			goblin: [KNIGHT, {H: 0x6ab040, E: 0xffe020, B: 0x705030, L: 0x403020, W: 0x909090}],
			hobbit: [ROBE, {H: 0x8040a0, S: 0xe8c098, E: 0x101010, B: 0x6a3090, L: 0x403020, W: 0x50c0ff}],
			bandit: [ARCHER, {H: 0x303030, S: 0xd0a880, E: 0xff3030, B: 0x404040, L: 0x202020, W: 0xa0a0a0}],
			orc: [KNIGHT, {H: 0x3a7a3a, E: 0xff3030, B: 0x6a4a2a, L: 0x302010, W: 0xc0c0c0}],
			elf: [ARCHER, {H: 0x40204a, S: 0x9070c0, E: 0xffffff, B: 0x302040, L: 0x201028, W: 0xd0a0ff}],
			gazer: [BLOB, {B: 0x9040a0, W: 0xffffff, E: 0x202020}],
			medusa: [MEDUSA, {G: 0x40c040, S: 0xc0e0a0, E: 0xff2020, B: 0x806020}],
			djinn: [DJINN, {C: 0x50a0ff, E: 0xffffff}],
			ent: [ENT, {G: 0x3a8a2a, E: 0xffe040, T: 0x6a4423}],
			beholder: [BLOB, {B: 0xb02020, W: 0xffe0a0, E: 0x101010}],
			cubelet: [CUBELET, {P: 0x501880, Q: 0x9040e0, E: 0xff4040}],
			boss: [BOSS, {Y: 0xf0c020, P: 0x401070, Q: 0x7a30c0, W: 0xffffff, E: 0xff2020, R: 0xc02040}],
			bag_brown: [BAG, {K: 0x502a10, C: 0x8a5a2a, D: 0x5a3a1a}],
			bag_purple: [BAG, {K: 0x401060, C: 0xa040d0, D: 0x6a2090}],
			bag_cyan: [BAG, {K: 0x105060, C: 0x30c0e0, D: 0x1a8098}],
			bag_white: [BAG, {K: 0x808080, C: 0xffffff, D: 0xc0c0c0}]
		};

		public static function get(name:String, flip:Boolean = false):BitmapData {
			var key:String = flip ? name + "#f" : name;
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			if (flip) {
				var src:BitmapData = get(name);
				bd = new BitmapData(src.width, src.height, true, 0);
				var m:Matrix = new Matrix(-1, 0, 0, 1, src.width, 0);
				bd.draw(src, m);
			} else {
				var d:Array = DEFS[name] || DEFS["cubelet"];
				bd = fromRows(d[0], d[1], SCALE);
			}
			cache[key] = bd;
			return bd;
		}

		/** Red-tinted version used for the hit flash. */
		public static function hit(name:String, flip:Boolean = false):BitmapData {
			var key:String = name + (flip ? "#f" : "") + "#hit";
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			bd = get(name, flip).clone();
			bd.colorTransform(bd.rect, new ColorTransform(0.6, 0.6, 0.6, 1, 120, 40, 40, 0));
			cache[key] = bd;
			return bd;
		}

		public static function fromRows(rows:Array, pal:Object, scale:int):BitmapData {
			var h:int = rows.length;
			var w:int = String(rows[0]).length;
			var bd:BitmapData = new BitmapData((w + 2) * scale, (h + 2) * scale, true, 0);
			var r:Rectangle = new Rectangle(0, 0, scale, scale);
			var x:int, y:int, dx:int, dy:int, ch:String;
			// outline pass
			for (y = 0; y < h; y++) {
				for (x = 0; x < w; x++) {
					ch = String(rows[y]).charAt(x);
					if (ch == "." || pal[ch] == undefined) continue;
					for (dy = -1; dy <= 1; dy++) {
						for (dx = -1; dx <= 1; dx++) {
							r.x = (x + 1 + dx) * scale;
							r.y = (y + 1 + dy) * scale;
							bd.fillRect(r, 0xff000000);
						}
					}
				}
			}
			// colour pass
			for (y = 0; y < h; y++) {
				for (x = 0; x < w; x++) {
					ch = String(rows[y]).charAt(x);
					if (ch == "." || pal[ch] == undefined) continue;
					r.x = (x + 1) * scale;
					r.y = (y + 1) * scale;
					bd.fillRect(r, 0xff000000 | uint(pal[ch]));
				}
			}
			return bd;
		}

		public static function bullet(color:uint, radius:int):BitmapData {
			if (radius < 3) radius = 3;
			var key:String = "b" + color + "_" + radius;
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			var s:Shape = new Shape();
			s.graphics.beginFill(0x000000, 0.9);
			s.graphics.drawCircle(radius + 1, radius + 1, radius + 1);
			s.graphics.beginFill(color);
			s.graphics.drawCircle(radius + 1, radius + 1, radius);
			s.graphics.beginFill(0xffffff, 0.85);
			s.graphics.drawCircle(radius + 1, radius + 1, radius * 0.45);
			s.graphics.endFill();
			bd = new BitmapData(radius * 2 + 2, radius * 2 + 2, true, 0);
			bd.draw(s);
			cache[key] = bd;
			return bd;
		}

		public static function spark(color:uint):BitmapData {
			var key:String = "sp" + color;
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			bd = new BitmapData(5, 5, true, 0xff000000);
			bd.fillRect(new Rectangle(1, 1, 3, 3), 0xff000000 | color);
			cache[key] = bd;
			return bd;
		}

		/** Icon for an inventory item (40x40). */
		public static function icon(item:Object):BitmapData {
			var key:String = "icon_" + item.kind + "_" + (item.sub || "") + "_" + item.tier;
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			var tc:uint = TIER_COLORS[Math.min(item.tier, 8)];
			var rows:Array, pal:Object;
			switch (item.kind) {
				case "weapon":
					rows = item.sub == "staff" ? I_STAFF : item.sub == "bow" ? I_BOW : item.sub == "sword" ? I_SWORD : I_WAND;
					pal = {T: tc, L: 0xffffff, W: 0x8a5a2a, S: 0xe0e0e0, G: 0xd0a030};
					break;
				case "armor":
					rows = I_ARMOR;
					pal = {T: tc, A: item.sub == "heavy" ? 0x9090a0 : item.sub == "leather" ? 0x8a5a2a : 0x4050b0};
					break;
				default:
					rows = I_POT;
					pal = {W: 0x8a5a2a, G: 0xc0c0c0, L: 0xffffff, P: item.color || 0xff3030};
			}
			bd = fromRows(rows, pal, SCALE);
			cache[key] = bd;
			return bd;
		}
	}
}
