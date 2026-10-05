package realm {
	import flash.display.BitmapData;
	import flash.geom.Rectangle;

	/**
	 * A round island realm: shore on the rim, more dangerous toward the
	 * godlands in the centre, with brick ruins and lava scattered inland.
	 * Ground is rendered once to an 8px-per-tile bitmap (scaled 5x in game);
	 * trees and rocks are separate objects drawn y-sorted with the entities.
	 */
	public class World {
		public static const N:int = 200;
		public static const PX:int = 8;

		public static const WATER:int = 0, SAND:int = 1, GRASS:int = 2, DARK:int = 3, GOD:int = 4, PLAZA:int = 5, BRICK:int = 6, LAVA:int = 7;
		public static const VOID:int = 8, STONE:int = 9, WALL:int = 10, CARPET:int = 11, FOUNTAIN:int = 12, ARENA:int = 13, BLOODSTONE:int = 14;
		public static const ARENA_ZONE:int = 6;
		public static const DUNGEON_ZONE:int = 7;
		public static const OBJ_NAMES:Array = [null, "tree", "pine", "palm", "rock", "boulder", "deadtree", "brazier"];
		public static const NEXUS_ZONE:int = 5;

		private static const MINI_COL:Array = [0x2b4ea0, 0xd6bc7a, 0x4e8c2f, 0x35602a, 0x46464a, 0xd0d0d0, 0x9c6236, 0xc0301a,
			0x000000, 0x5c5c64, 0xa0a0a8, 0x9a2020, 0x3a8ad8, 0xdcdcdc, 0xa01c1c];
		private static const STONE_PAT:Array = ["hhhmHHHm", "hSSmHSSm", "hSSmHSSm", "mmmmmmmm", "HHmhhhmH", "SSmhSSmS", "SSmhSSmS", "mmmmmmmm"];
		private static const WALL_PAT:Array = ["LLLLLLLL", "LTTdLTTd", "LTTdLTTd", "dddddddd", "TdLTTdLT", "TdLTTdLT", "FFFFFFFF", "ffffffff"];

		private static const PLAZA_PAT:Array = ["LLLMMLLL", "LLMLLMLL", "LMLDDLML", "MLDLLDLM", "MLDLLDLM", "LMLDDLML", "LLMLLMLL", "LLLMMLLL"];
		private static const BRICK_PAT:Array = ["hhhaHHHb", "hAAaHBBb", "hAAaHBBb", "aaaabbbb", "HHHbhhha", "HBBbhAAa", "HBBbhAAa", "bbbbaaaa"];

		public var tiles:Vector.<int> = new Vector.<int>(N * N, true);
		public var objs:Vector.<int> = new Vector.<int>(N * N, true);
		public var zones:Vector.<int> = new Vector.<int>(N * N, true);
		public var bitmap:BitmapData;
		public var minimap:BitmapData;
		public var seen:BitmapData;
		public var spawnX:Number;
		public var spawnY:Number;

		/** "realm" or "nexus". */
		public var kind:String;
		public var name:String;
		// per-world game state, so a realm keeps its monsters, loot and boss while you're away
		public var enemies:Vector.<Enemy> = new Vector.<Enemy>();
		public var bags:Vector.<LootBag> = new Vector.<LootBag>();
		public var boss:Enemy;
		public var killsToBoss:int = 40;
		public var bossGoal:int = 40;
		public var closeT:Number = 0;
		public var closed:Boolean = false;
		// realm events (Valor): announced bosses; clear them all to face the Dark Elder
		public var eventsDone:int = 0;
		public var eventT:Number = 25;
		public var nextEvent:int = 0;
		/** Portals standing in this world: {x, y, kind, idx, color, label, life}. */
		public var portals:Array = [];
		/** Dungeon rooms {x, y, w, h}; the last one is the boss room. */
		public var rooms:Array = [];
		public var theme:Object;

		private var noise:Vector.<Number>;
		private var noiseW:int;
		private const CELL:int = 10;

		public function World(kind:String = "realm", name:String = "", theme:Object = null) {
			this.kind = kind;
			this.name = name;
			this.theme = theme;
			if (kind == "nexus") generateNexus();
			else if (kind == "arena") generateArena();
			else if (kind == "dungeon") generateDungeon(theme);
			else generate();
			render();
			seen = new BitmapData(N, N, true, 0);
		}

		// ------------------------------------------------------------ generation
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
			var x:int, y:int, i:int, d:Number, z:int, t:int, r:Number, o:int;
			for (y = 0; y < N; y++) {
				for (x = 0; x < N; x++) {
					i = y * N + x;
					d = Math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / R + (sample(x, y) - 0.5) * 0.2;
					if (d > 1) { t = WATER; z = -1; }
					else if (d > 0.77) { t = SAND; z = 0; }
					else if (d > 0.58) { t = GRASS; z = 1; }
					else if (d > 0.33) { t = DARK; z = 2; }
					else { t = GOD; z = 3; }
					tiles[i] = t;
					zones[i] = z;
					r = Math.random();
					o = 0;
					if (z == 0 && r < 0.008) o = 3;
					else if (z == 0 && r < 0.016) o = 4;
					else if (z == 1 && r < 0.035) o = 1;
					else if (z == 1 && r < 0.042) o = 4;
					else if (z == 2 && r < 0.06) o = 2;
					else if (z == 2 && r < 0.072) o = 1;
					else if (z == 3 && r < 0.035) o = 5;
					else if (z == 3 && r < 0.05) o = 6;
					objs[i] = o;
				}
			}
			makeRuins();

			// safe haven on the southern shore
			x = int(cx);
			for (y = N - 1; y > 0; y--) if (tiles[y * N + x] != WATER) break;
			spawnX = x + 0.5;
			spawnY = y - 6 + 0.5;
			var px:int = int(spawnX), py:int = int(spawnY);
			for (var dy:int = -6; dy <= 6; dy++) {
				for (var dx:int = -6; dx <= 6; dx++) {
					var tx:int = px + dx, ty:int = py + dy;
					if (tx < 0 || ty < 0 || tx >= N || ty >= N) continue;
					i = ty * N + tx;
					if (Math.abs(dx) <= 4 && Math.abs(dy) <= 4) { tiles[i] = PLAZA; zones[i] = 4; objs[i] = 0; }
					else if (tiles[i] != WATER) objs[i] = 0;
				}
			}
		}

		/**
		 * The Nexus: a walled stone hall with a healing fountain, a red carpet
		 * cross, braziers, realm portals to the north and the vault to the west.
		 */
		private function generateNexus():void {
			var x:int, y:int, i:int;
			for (i = 0; i < N * N; i++) { tiles[i] = VOID; zones[i] = -1; objs[i] = 0; }
			var x0:int = 78, x1:int = 122, y0:int = 82, y1:int = 116;
			for (y = y0; y <= y1; y++) {
				for (x = x0; x <= x1; x++) {
					i = y * N + x;
					zones[i] = NEXUS_ZONE;
					tiles[i] = (x == x0 || x == x1 || y == y0 || y == y1) ? WALL : STONE;
				}
			}
			// pillars
			var pillars:Array = [[83, 87], [117, 87], [83, 111], [117, 111], [92, 93], [108, 93], [92, 107], [108, 107]];
			for each (var pp:Array in pillars) tiles[pp[1] * N + pp[0]] = WALL;
			// carpets: north-south and east-west
			for (y = 88; y <= 115; y++) for (x = 99; x <= 101; x++) tiles[y * N + x] = CARPET;
			for (x = 82; x <= 118; x++) for (y = 99; y <= 101; y++) tiles[y * N + x] = CARPET;
			// portal alcove along the north wall
			for (x = 86; x <= 114; x++) for (y = 83; y <= 87; y++) tiles[y * N + x] = CARPET;
			// healing fountain
			for (y = 96; y <= 104; y++) {
				for (x = 96; x <= 104; x++) {
					var d:Number = Math.sqrt((x - 100) * (x - 100) + (y - 100) * (y - 100));
					if (d <= 2.9) tiles[y * N + x] = FOUNTAIN;
				}
			}
			// braziers
			var lights:Array = [[95, 95], [105, 95], [95, 105], [105, 105], [80, 84], [120, 84], [80, 114], [120, 114], [97, 113], [103, 113]];
			for each (var lp:Array in lights) objs[lp[1] * N + lp[0]] = 7;
			spawnX = 100.5;
			spawnY = 110.5;
		}

		/**
		 * A dungeon: a chain of rooms carved northward from the entrance and joined
		 * by corridors, with walls around everything and the boss in the last room.
		 */
		private function generateDungeon(th:Object):void {
			var x:int, y:int, i:int;
			for (i = 0; i < N * N; i++) { tiles[i] = VOID; zones[i] = -1; objs[i] = 0; }
			var floor:int = th.floor, accent:int = th.accent;
			var cx:int = 100, cy:int = 175;
			var count:int = 6 + int(Math.random() * 2);
			var prev:Object = null;
			for (var k:int = 0; k < count; k++) {
				var boss:Boolean = k == count - 1;
				var w:int = boss ? 17 : 9 + int(Math.random() * 5);
				var h:int = boss ? 15 : 8 + int(Math.random() * 4);
				var room:Object = {x: cx, y: cy, w: w, h: h};
				carve(cx - int(w / 2), cy - int(h / 2), w, h, floor);
				// accent pattern in the middle of bigger rooms (lava pools, carpets...)
				if (!boss && k > 0 && Math.random() < 0.6) carve(cx - 1, cy - 1, 3, 3, accent);
				if (prev) corridor(prev.x, prev.y, cx, cy, floor);
				rooms.push(room);
				prev = room;
				// next room: mostly north, drifting east/west
				var dir:Number = Math.random();
				if (dir < 0.25 && cx > 50) cx -= 16 + int(Math.random() * 4);
				else if (dir < 0.5 && cx < 150) cx += 16 + int(Math.random() * 4);
				else cy -= 17 + int(Math.random() * 3);
				if (k == count - 2) { cy -= 4; }
				if (cy < 25) cy = 25;
			}
			// walls wherever floor meets the void
			for (y = 1; y < N - 1; y++) {
				for (x = 1; x < N - 1; x++) {
					i = y * N + x;
					if (tiles[i] != VOID) continue;
					for (var dy:int = -1; dy <= 1; dy++) {
						for (var dx:int = -1; dx <= 1; dx++) {
							var t:int = tiles[(y + dy) * N + x + dx];
							if (t != VOID && t != WALL) { tiles[i] = WALL; zones[i] = DUNGEON_ZONE; }
						}
					}
				}
			}
			spawnX = rooms[0].x + 0.5;
			spawnY = rooms[0].y + 2.5;
		}

		private function carve(x0:int, y0:int, w:int, h:int, t:int):void {
			for (var y:int = y0; y < y0 + h; y++) {
				for (var x:int = x0; x < x0 + w; x++) {
					if (x < 2 || y < 2 || x >= N - 2 || y >= N - 2) continue;
					tiles[y * N + x] = t;
					zones[y * N + x] = DUNGEON_ZONE;
				}
			}
		}

		/** L-shaped corridor, 3 tiles wide. */
		private function corridor(x0:int, y0:int, x1:int, y1:int, t:int):void {
			var x:int, y:int;
			for (x = Math.min(x0, x1); x <= Math.max(x0, x1); x++) carve(x - 1, y0 - 1, 3, 3, t);
			for (y = Math.min(y0, y1); y <= Math.max(y0, y1); y++) carve(x1 - 1, y - 1, 3, 3, t);
		}

		/** The Dark Elder's chamber: white patterned floor ringed by red striped stone. */
		private function generateArena():void {
			var x:int, y:int, i:int;
			for (i = 0; i < N * N; i++) { tiles[i] = VOID; zones[i] = -1; objs[i] = 0; }
			var x0:int = 84, x1:int = 116, y0:int = 82, y1:int = 118;
			for (y = y0; y <= y1; y++) {
				for (x = x0; x <= x1; x++) {
					i = y * N + x;
					zones[i] = ARENA_ZONE;
					var edge:int = Math.min(Math.min(x - x0, x1 - x), Math.min(y - y0, y1 - y));
					tiles[i] = edge == 0 ? WALL : edge <= 3 ? BLOODSTONE : ARENA;
				}
			}
			// a band of bloodstone across the hall, like a throne-room runner
			for (y = 97; y <= 99; y++) for (x = x0 + 1; x < x1; x++) tiles[y * N + x] = BLOODSTONE;
			for each (var pp:Array in [[91, 90], [109, 90], [91, 108], [109, 108]]) tiles[pp[1] * N + pp[0]] = WALL;
			for each (var lp:Array in [[88, 86], [112, 86], [88, 114], [112, 114]]) objs[lp[1] * N + lp[0]] = 7;
			spawnX = 100.5;
			spawnY = 113.5;
		}

		/** Brick ruins in the midlands and godlands; godland ruins have lava rivers. */
		private function makeRuins():void {
			for (var k:int = 0; k < 26; k++) {
				var cx:int = 0, cy:int = 0, z:int = -1;
				for (var tries:int = 0; tries < 50; tries++) {
					cx = 20 + int(Math.random() * (N - 40));
					cy = 20 + int(Math.random() * (N - 40));
					z = zones[cy * N + cx];
					if (z >= 2) break;
				}
				if (z < 2) continue;
				var rw:int = 3 + int(Math.random() * 5), rh:int = 3 + int(Math.random() * 5);
				var lavaDir:int = Math.random() < 0.5 ? 1 : -1;
				var lava:Boolean = z == 3 && Math.random() < 0.75;
				for (var y:int = cy - rh - 1; y <= cy + rh + 1; y++) {
					for (var x:int = cx - rw - 1; x <= cx + rw + 1; x++) {
						var nx:Number = (x - cx) / rw, ny:Number = (y - cy) / rh;
						// blocky, stair-stepped outline like RotMG ruins
						var edge:Number = nx * nx + ny * ny + (Math.random() - 0.5) * 0.25;
						if (edge > 1) continue;
						var i:int = y * N + x;
						if (tiles[i] == WATER) continue;
						objs[i] = 0;
						var diag:Number = Math.abs((x - cx) - lavaDir * (y - cy));
						tiles[i] = lava && diag < 1.6 ? LAVA : BRICK;
					}
				}
			}
		}

		// ------------------------------------------------------------ textures
		private function texture(t:int, tx:int, ty:int):Vector.<uint> {
			var v:Vector.<uint> = new Vector.<uint>(PX * PX, true);
			var x:int, y:int, i:int, r:Number, c:uint;
			for (y = 0; y < PX; y++) {
				for (x = 0; x < PX; x++) {
					i = y * PX + x;
					r = Math.random();
					var gx:int = tx * PX + x, gy:int = ty * PX + y;
					switch (t) {
						case WATER:
							c = 0x2b4ea0;
							var wv:int = (gx + int(sample(gx / PX, gy / PX) * 12)) % 7;
							if (gy % 3 == 0 && wv < 2) c = 0x4470c4;
							else if (r < 0.06) c = 0x24438c;
							break;
						case SAND:
							c = r < 0.10 ? 0xcdb272 : r < 0.18 ? 0xe0c88a : r < 0.2 ? 0xc4a868 : 0xd6bc7a;
							break;
						case GRASS:
							c = r < 0.12 ? 0x458230 : r < 0.2 ? 0x579a38 : r < 0.215 ? 0x68ac44 : 0x4e8c2f;
							break;
						case DARK:
							c = r < 0.14 ? 0x2e5525 : r < 0.22 ? 0x3e6b31 : r < 0.24 ? 0x5a4a32 : 0x35602a;
							break;
						case GOD:
							// diagonal streaky dark stone
							var s:int = (gx - gy + 400 + int(sample(gx / PX, gy / PX) * 8)) % 4;
							c = r < 0.08 ? 0x323235 : s == 0 && r < 0.6 ? 0x3a3a3d : s == 2 && r < 0.4 ? 0x4e4e52 : 0x434346;
							break;
						case PLAZA:
							var ch:String = String(PLAZA_PAT[y]).charAt(x);
							c = ch == "L" ? 0xdadada : ch == "M" ? 0xbcbcbc : 0xa6a6a6;
							if (r < 0.06) c = 0xd0d0d0;
							break;
						case BRICK:
							var bc:String = String(BRICK_PAT[y]).charAt(x);
							c = bc == "A" ? 0xa86a3c : bc == "a" ? 0x7c4a28 : bc == "h" ? 0xc4874f : bc == "B" ? 0x8a5230 : bc == "H" ? 0xa0663c : 0x643a1e;
							if (r < 0.15) c = Sprites.shade(c, 0.93);
							break;
						case VOID:
							c = 0x000000;
							break;
						case STONE:
							var sc:String = String(STONE_PAT[y]).charAt(x);
							c = sc == "S" ? 0x5c5c64 : sc == "H" ? 0x707078 : sc == "h" ? 0x68686f : 0x404046;
							if (r < 0.12 && sc != "m") c = Sprites.shade(c, 0.92);
							break;
						case WALL:
							var wc:String = String(WALL_PAT[y]).charAt(x);
							c = wc == "L" ? 0xc4c4cc : wc == "T" ? 0xa4a4ac : wc == "d" ? 0x7a7a82 : wc == "F" ? 0x55555c : 0x3a3a40;
							break;
						case CARPET:
							c = r < 0.08 ? 0x7a1616 : ((gx + gy) % 4 == 0 && r < 0.5) ? 0xa82828 : 0x8c1c1c;
							break;
						case FOUNTAIN:
							c = r < 0.06 ? 0xb0e8ff : (gx * 3 + gy * 5) % 9 == 0 ? 0x5aa8f0 : 0x3a86d4;
							break;
						case ARENA:
							var ac:String = String(PLAZA_PAT[y]).charAt(x);
							c = ac == "L" ? 0xe4e4e4 : ac == "M" ? 0xd0d0d0 : 0xbebebe;
							if (r < 0.05) c = 0xdadada;
							break;
						case BLOODSTONE:
							var bs:int = (gx + gy) & 3;
							c = bs == 0 ? 0x7a1010 : bs == 1 ? 0xc02a2a : 0xa01c1c;
							if (r < 0.06) c = 0xd04040;
							break;
						case LAVA:
							var ls:int = (gx + gy) & 3;
							c = ls == 0 ? 0x8a1a0e : ls == 1 ? 0xe04a22 : 0xc0301a;
							if (r < 0.05) c = 0xff8a30;
							break;
					}
					v[i] = 0xff000000 | c;
				}
			}
			return v;
		}

		private function render():void {
			bitmap = new BitmapData(N * PX, N * PX, false, 0);
			minimap = new BitmapData(N, N, false, 0);
			var r:Rectangle = new Rectangle(0, 0, PX, PX);
			bitmap.lock();
			for (var y:int = 0; y < N; y++) {
				for (var x:int = 0; x < N; x++) {
					var i:int = y * N + x;
					var t:int = tiles[i];
					r.x = x * PX;
					r.y = y * PX;
					bitmap.setVector(r, texture(t, x, y));
					drawEdges(x, y, t);
					var mc:uint = MINI_COL[t];
					if (objs[i] == 1 || objs[i] == 2) mc = 0x1e4a18;
					else if (objs[i] == 4 || objs[i] == 5) mc = 0x7a7a7a;
					minimap.setPixel(x, y, mc);
				}
			}
			bitmap.unlock();
		}

		/** Light borders where ruins / haven / water meet other ground (the RotMG tile edge look). */
		private function drawEdges(x:int, y:int, t:int):void {
			var col:uint, dark:uint;
			if (t == BRICK || t == LAVA) { col = 0xb8ab98; dark = 0x2a2a2a; }
			else if (t == PLAZA) { col = 0x8c8c8c; dark = 0x5a5a5a; }
			else if (t == WATER) { col = 0x7aa0e0; dark = 0x2b4ea0; }
			else if (t == CARPET) { col = 0xd8a830; dark = 0x8a6a18; }
			else if (t == FOUNTAIN) { col = 0xd0d0d8; dark = 0x8a8a92; }
			else if (t == ARENA) { col = 0x9a9a9a; dark = 0x6a6a6a; }
			else return;
			var px:int = x * PX, py:int = y * PX;
			var same:Function = function(nt:int):Boolean {
				if (t == BRICK || t == LAVA) return nt == BRICK || nt == LAVA;
				return nt == t;
			};
			if (!same(tileAtI(x, y - 1))) bitmap.fillRect(new Rectangle(px, py, PX, 1), col);
			if (!same(tileAtI(x - 1, y))) bitmap.fillRect(new Rectangle(px, py, 1, PX), col);
			if (!same(tileAtI(x + 1, y))) bitmap.fillRect(new Rectangle(px + PX - 1, py, 1, PX), col);
			if (!same(tileAtI(x, y + 1))) {
				bitmap.fillRect(new Rectangle(px, py + PX - 1, PX, 1), col);
				if (t != WATER) bitmap.fillRect(new Rectangle(px, py + PX - 2, PX, 1), Sprites.shade(col, 0.8));
			}
		}

		private function tileAtI(x:int, y:int):int {
			if (x < 0 || y < 0 || x >= N || y >= N) return WATER;
			return tiles[y * N + x];
		}

		/** Reveal the minimap around (x, y). */
		public function reveal(x:Number, y:Number, radius:int):void {
			var cx:int = int(x), cy:int = int(y);
			seen.lock();
			for (var dy:int = -radius; dy <= radius; dy++) {
				for (var dx:int = -radius; dx <= radius; dx++) {
					if (dx * dx + dy * dy > radius * radius) continue;
					var tx:int = cx + dx, ty:int = cy + dy;
					if (tx < 0 || ty < 0 || tx >= N || ty >= N) continue;
					seen.setPixel32(tx, ty, 0xff000000 | minimap.getPixel(tx, ty));
				}
			}
			seen.unlock();
		}

		// ------------------------------------------------------------ queries
		public function tileAt(x:Number, y:Number):int {
			if (x < 0 || y < 0 || x >= N || y >= N) return WATER;
			return tiles[int(y) * N + int(x)];
		}

		public function objAt(tx:int, ty:int):int {
			if (tx < 0 || ty < 0 || tx >= N || ty >= N) return 0;
			return objs[ty * N + tx];
		}

		public function zoneAt(x:Number, y:Number):int {
			if (x < 0 || y < 0 || x >= N || y >= N) return -1;
			return zones[int(y) * N + int(x)];
		}

		public function walkable(x:Number, y:Number):Boolean {
			if (x < 0 || y < 0 || x >= N || y >= N) return false;
			var i:int = int(y) * N + int(x);
			var t:int = tiles[i];
			return t != WATER && t != VOID && t != WALL && objs[i] == 0;
		}

		public function isSafe(x:Number, y:Number):Boolean {
			var z:int = zoneAt(x, y);
			return z == 4 || z == NEXUS_ZONE;
		}

		/** True if a body of half-size r fits at (x, y). Enemies may not enter the safe haven. */
		public function canStand(x:Number, y:Number, r:Number, enemy:Boolean):Boolean {
			if (!walkable(x - r, y - r) || !walkable(x + r, y - r) || !walkable(x - r, y + r) || !walkable(x + r, y + r)) return false;
			if (enemy && (isSafe(x - r, y - r) || isSafe(x + r, y + r) || isSafe(x + r, y - r) || isSafe(x - r, y + r))) return false;
			return true;
		}
	}
}
