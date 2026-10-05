package realm {
	import flash.display.BitmapData;
	import flash.geom.Rectangle;

	/**
	 * A round island realm: shore on the rim, getting more dangerous toward
	 * the godlands in the centre. Stored as a tile grid; rendered once to an
	 * 8px-per-tile bitmap that the game scales up 4x.
	 */
	public class World {
		public static const N:int = 200;
		public static const PX:int = 8;

		public static const WATER:int = 0, SAND:int = 1, GRASS:int = 2, DARK:int = 3, GOD:int = 4, PLAZA:int = 5, TREE:int = 6, ROCK:int = 7;
		private static const BASE:Array = [0x2a5fa8, 0xd9c38a, 0x5ca33f, 0x3c7a30, 0x6e6480, 0x9c9c9c];
		private static const SHADE_A:Array = [0x3b74bf, 0xcbb27a, 0x4f9436, 0x336b29, 0x5f5671, 0x8a8a8a];
		private static const SHADE_B:Array = [0x2456a0, 0xe6d39c, 0x6ab24a, 0x478a3a, 0x7d7390, 0xaaaaaa];

		private static const TREE_PAT:Array = [
			"..gggg..",
			".gGgggg.",
			"gGggggGg",
			"ggggGggg",
			".gggggg.",
			"..gTTg..",
			"...TT...",
			"...TT..."];
		private static const ROCK_PAT:Array = [
			"........",
			"..kkkk..",
			".kKKkkk.",
			"kKkkkkkk",
			"kkkkkkdk",
			"kkkkkddk",
			".kkdddk.",
			"........"];

		public var tiles:Vector.<int> = new Vector.<int>(N * N, true);
		public var zones:Vector.<int> = new Vector.<int>(N * N, true);
		public var ground:Vector.<int> = new Vector.<int>(N * N, true);
		public var bitmap:BitmapData;
		public var minimap:BitmapData;
		public var spawnX:Number;
		public var spawnY:Number;

		private var noise:Vector.<Number>;
		private var noiseW:int;
		private const CELL:int = 10;

		public function World() {
			generate();
			render();
		}

		private function makeNoise():void {
			noiseW = int(N / CELL) + 2;
			noise = new Vector.<Number>(noiseW * noiseW, true);
			for (var i:int = 0; i < noise.length; i++) noise[i] = Math.random();
		}

		private function sample(x:Number, y:Number):Number {
			var gx:Number = x / CELL, gy:Number = y / CELL;
			var ix:int = int(gx), iy:int = int(gy);
			var fx:Number = gx - ix, fy:Number = gy - iy;
			fx = fx * fx * (3 - 2 * fx);
			fy = fy * fy * (3 - 2 * fy);
			var a:Number = noise[iy * noiseW + ix], b:Number = noise[iy * noiseW + ix + 1];
			var c:Number = noise[(iy + 1) * noiseW + ix], d:Number = noise[(iy + 1) * noiseW + ix + 1];
			return (a + (b - a) * fx) * (1 - fy) + (c + (d - c) * fx) * fy;
		}

		private function generate():void {
			makeNoise();
			var cx:Number = N / 2, cy:Number = N / 2, R:Number = N / 2 - 6;
			var x:int, y:int, i:int, d:Number, z:int, t:int, r:Number;
			for (y = 0; y < N; y++) {
				for (x = 0; x < N; x++) {
					i = y * N + x;
					d = Math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / R + (sample(x, y) - 0.5) * 0.2;
					if (d > 1) { t = WATER; z = -1; }
					else if (d > 0.8) { t = SAND; z = 0; }
					else if (d > 0.6) { t = GRASS; z = 1; }
					else if (d > 0.33) { t = DARK; z = 2; }
					else { t = GOD; z = 3; }
					ground[i] = t;
					zones[i] = z;
					r = Math.random();
					if (z == 0 && r < 0.012) t = ROCK;
					else if (z == 1 && r < 0.04) t = TREE;
					else if (z == 2 && r < 0.075) t = TREE;
					else if (z == 3 && r < 0.05) t = ROCK;
					tiles[i] = t;
				}
			}
			// find the shore at the bottom of the island for the safe haven
			x = int(cx);
			for (y = N - 1; y > 0; y--) if (tiles[y * N + x] != WATER) break;
			spawnX = x + 0.5;
			spawnY = y - 3 + 0.5;
			var px:int = int(spawnX), py:int = int(spawnY);
			for (var dy:int = -5; dy <= 5; dy++) {
				for (var dx:int = -5; dx <= 5; dx++) {
					var tx:int = px + dx, ty:int = py + dy;
					if (tx < 0 || ty < 0 || tx >= N || ty >= N) continue;
					d = Math.sqrt(dx * dx + dy * dy);
					i = ty * N + tx;
					if (d <= 4.2) { tiles[i] = PLAZA; ground[i] = PLAZA; zones[i] = 4; }
					else if (d <= 5.5 && tiles[i] != WATER) { tiles[i] = ground[i]; }
				}
			}
		}

		private function render():void {
			bitmap = new BitmapData(N * PX, N * PX, false, 0);
			minimap = new BitmapData(N, N, false, 0);
			var r:Rectangle = new Rectangle(0, 0, PX, PX);
			var p:Rectangle = new Rectangle(0, 0, 1, 1);
			bitmap.lock();
			for (var y:int = 0; y < N; y++) {
				for (var x:int = 0; x < N; x++) {
					var i:int = y * N + x;
					var g:int = ground[i];
					r.x = x * PX; r.y = y * PX;
					bitmap.fillRect(r, BASE[g]);
					// speckles
					var n:int = g == PLAZA ? 0 : 6;
					for (var k:int = 0; k < n; k++) {
						p.x = r.x + int(Math.random() * PX);
						p.y = r.y + int(Math.random() * PX);
						bitmap.fillRect(p, Math.random() < 0.5 ? SHADE_A[g] : SHADE_B[g]);
					}
					if (g == PLAZA) {
						bitmap.fillRect(new Rectangle(r.x, r.y, PX, 1), SHADE_A[g]);
						bitmap.fillRect(new Rectangle(r.x, r.y, 1, PX), SHADE_A[g]);
						bitmap.fillRect(new Rectangle(r.x + 1, r.y + 1, PX - 2, 1), SHADE_B[g]);
					}
					var t:int = tiles[i];
					var mc:uint = BASE[g];
					if (t == TREE) { stamp(TREE_PAT, x, y, {g: 0x2d6b22, G: 0x4f9a3a, T: 0x6b4423}); mc = 0x24561b; }
					else if (t == ROCK) { stamp(ROCK_PAT, x, y, {k: 0x8a8a8a, K: 0xb0b0b0, d: 0x5a5a5a}); mc = 0x808080; }
					minimap.setPixel(x, y, mc);
				}
			}
			bitmap.unlock();
		}

		private function stamp(pat:Array, tx:int, ty:int, pal:Object):void {
			var p:Rectangle = new Rectangle(0, 0, 1, 1);
			for (var y:int = 0; y < PX; y++) {
				for (var x:int = 0; x < PX; x++) {
					var ch:String = String(pat[y]).charAt(x);
					if (ch == ".") continue;
					p.x = tx * PX + x; p.y = ty * PX + y;
					bitmap.fillRect(p, pal[ch]);
				}
			}
		}

		public function tileAt(x:Number, y:Number):int {
			if (x < 0 || y < 0 || x >= N || y >= N) return WATER;
			return tiles[int(y) * N + int(x)];
		}

		public function zoneAt(x:Number, y:Number):int {
			if (x < 0 || y < 0 || x >= N || y >= N) return -1;
			return zones[int(y) * N + int(x)];
		}

		public function walkable(x:Number, y:Number):Boolean {
			var t:int = tileAt(x, y);
			return t != WATER && t != TREE && t != ROCK;
		}

		public function isSafe(x:Number, y:Number):Boolean {
			return tileAt(x, y) == PLAZA;
		}

		/** True if a body of half-size r fits at (x, y). Enemies may not enter the safe haven. */
		public function canStand(x:Number, y:Number, r:Number, enemy:Boolean):Boolean {
			if (!walkable(x - r, y - r) || !walkable(x + r, y - r) || !walkable(x - r, y + r) || !walkable(x + r, y + r)) return false;
			if (enemy && (isSafe(x - r, y - r) || isSafe(x + r, y + r) || isSafe(x + r, y - r) || isSafe(x - r, y + r))) return false;
			return true;
		}
	}
}
