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
		/** Map size in tiles: realms are big islands, other worlds use the default. */
		public static const DEFAULT_N:int = 200;
		public static const REALM_N:int = 320;
		public var N:int = DEFAULT_N;
		public static const PX:int = 8;

		public static const WATER:int = 0, SAND:int = 1, GRASS:int = 2, DARK:int = 3, GOD:int = 4, PLAZA:int = 5, BRICK:int = 6, LAVA:int = 7;
		public static const VOID:int = 8, STONE:int = 9, WALL:int = 10, CARPET:int = 11, FOUNTAIN:int = 12, ARENA:int = 13, BLOODSTONE:int = 14;
		public static const HIGH:int = 15, ROAD:int = 16, BRIDGE:int = 17, RUIN:int = 18;
		/** Realm biomes, from the coast inwards (RotMG order). */
		public static const SHORE_ZONE:int = 0, LOW_ZONE:int = 1, MID_ZONE:int = 2, HIGH_ZONE:int = 3, GOD_ZONE:int = 4;
		public static const SAFE_ZONE:int = 9;
		public static const ARENA_ZONE:int = 6;
		public static const DUNGEON_ZONE:int = 7;
		public static const OBJ_NAMES:Array = [null, "tree", "pine", "palm", "rock", "boulder", "deadtree", "brazier", "pillar", "ruinwall"];
		public static const NEXUS_ZONE:int = 5;

		private static const MINI_COL:Array = [0x2b4ea0, 0xd6bc7a, 0x4e8c2f, 0x35602a, 0x46464a, 0xd0d0d0, 0x9c6236, 0xc0301a,
			0x000000, 0x5c5c64, 0xa0a0a8, 0x9a2020, 0x3a8ad8, 0xdcdcdc, 0xa01c1c, 0x77733c, 0x9a9080, 0x8a5a2e, 0x8e8e96];
		private static const STONE_PAT:Array = ["hhhmHHHm", "hSSmHSSm", "hSSmHSSm", "mmmmmmmm", "HHmhhhmH", "SSmhSSmS", "SSmhSSmS", "mmmmmmmm"];
		private static const WALL_PAT:Array = ["LLLLLLLL", "LTTdLTTd", "LTTdLTTd", "dddddddd", "TdLTTdLT", "TdLTTdLT", "FFFFFFFF", "ffffffff"];

		private static const PLAZA_PAT:Array = ["LLLMMLLL", "LLMLLMLL", "LMLDDLML", "MLDLLDLM", "MLDLLDLM", "LMLDDLML", "LLMLLMLL", "LLLMMLLL"];
		private static const BRICK_PAT:Array = ["hhhaHHHb", "hAAaHBBb", "hAAaHBBb", "aaaabbbb", "HHHbhhha", "HBBbhAAa", "HBBbhAAa", "bbbbaaaa"];

		public var tiles:Vector.<int>;
		public var objs:Vector.<int>;
		public var zones:Vector.<int>;
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
		// realm events: announced bosses; clear them all to face the Dark Elder
		public var eventsDone:int = 0;
		public var eventT:Number = 25;
		public var nextEvent:int = 0;
		public var recentEvents:Array;
		/** Portals standing in this world: {x, y, kind, idx, color, label, life}. */
		public var portals:Array = [];
		/** Dungeon rooms {x, y, w, h}; the last one is the boss room. */
		public var rooms:Array = [];
		/** Dungeon side room holding a treasure chest (or null). */
		public var treasure:Object;
		public var theme:Object;

		private var noise:Vector.<Number>;
		private var noiseW:int;
		private const CELL:int = 10;
		/** Extra noise layers for the realm: {v, w, cell}. */
		private var layers:Array;

		public function World(kind:String = "realm", name:String = "", theme:Object = null) {
			this.kind = kind;
			this.name = name;
			this.theme = theme;
			N = kind == "realm" ? REALM_N : DEFAULT_N;
			tiles = new Vector.<int>(N * N, true);
			objs = new Vector.<int>(N * N, true);
			zones = new Vector.<int>(N * N, true);
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

		private function layer(cell:int):Object {
			var w:int = int(N / cell) + 2;
			var v:Vector.<Number> = new Vector.<Number>(w * w, true);
			for (var i:int = 0; i < v.length; i++) v[i] = Math.random();
			return {v: v, w: w, cell: cell};
		}

		private function lsample(l:Object, x:Number, y:Number):Number {
			var gx:Number = x / l.cell, gy:Number = y / l.cell;
			var ix:int = int(gx), iy:int = int(gy);
			var fx:Number = gx - ix, fy:Number = gy - iy;
			fx = fx * fx * (3 - 2 * fx);
			fy = fy * fy * (3 - 2 * fy);
			var v:Vector.<Number> = l.v, w:int = l.w;
			var a:Number = v[iy * w + ix], b:Number = v[iy * w + ix + 1];
			var c:Number = v[(iy + 1) * w + ix], d:Number = v[(iy + 1) * w + ix + 1];
			return (a + (b - a) * fx) * (1 - fy) + (c + (d - c) * fx) * fy;
		}

		/** Fractal noise from three layers starting at `base`. */
		private function fbm(base:int, x:Number, y:Number):Number {
			return lsample(layers[base], x, y) * 0.55 + lsample(layers[base + 1], x, y) * 0.3 + lsample(layers[base + 2], x, y) * 0.15;
		}

		/**
		 * A RotMG-style realm: a big island with Beach, Lowlands, Midlands, Highlands and the
		 * Godlands in the middle, plus lakes, rivers running to the sea and cobblestone roads.
		 */
		private function generate():void {
			makeNoise();
			// 0-2 coast/biome warp, 3-5 lakes, 6-8 forests
			layers = [layer(40), layer(16), layer(6), layer(30), layer(12), layer(5), layer(24), layer(9), layer(4)];
			var cx:Number = N / 2, cy:Number = N / 2, R:Number = N / 2 - 8;
			var x:int, y:int, i:int, d:Number, z:int, t:int;
			var dist:Vector.<Number> = new Vector.<Number>(N * N, true);
			for (y = 0; y < N; y++) {
				for (x = 0; x < N; x++) {
					i = y * N + x;
					d = Math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy)) / R + (fbm(0, x, y) - 0.5) * 0.42;
					dist[i] = d;
					if (d > 1) { t = WATER; z = -1; }
					else if (d > 0.88) { t = SAND; z = SHORE_ZONE; }
					else if (d > 0.68) { t = GRASS; z = LOW_ZONE; }
					else if (d > 0.48) { t = DARK; z = MID_ZONE; }
					else if (d > 0.3) { t = HIGH; z = HIGH_ZONE; }
					else { t = GOD; z = GOD_ZONE; }
					// lakes inland
					if (z >= LOW_ZONE && d > 0.12 && fbm(3, x, y) > 0.73) { t = WATER; }
					tiles[i] = t;
					zones[i] = z;
					objs[i] = 0;
				}
			}
			// rivers: wander from the highlands down to the sea
			var k:int, a:Number, px:Number, py:Number, step:int;
			for (k = 0; k < 4; k++) {
				a = Math.random() * Math.PI * 2;
				px = cx + Math.cos(a) * R * 0.35;
				py = cy + Math.sin(a) * R * 0.35;
				var wig:Number = 0;
				for (step = 0; step < N * 2; step++) {
					wig += (Math.random() - 0.5) * 0.5;
					wig *= 0.9;
					var out:Number = Math.atan2(py - cy, px - cx) + wig;
					px += Math.cos(out);
					py += Math.sin(out);
					if (px < 2 || py < 2 || px >= N - 2 || py >= N - 2) break;
					var wide:int = step > 30 ? 1 : 0;
					for (var ry:int = -wide; ry <= wide + 1; ry++) {
						for (var rx:int = -wide; rx <= wide + 1; rx++) {
							i = (int(py) + ry) * N + int(px) + rx;
							tiles[i] = WATER;
						}
					}
					if (dist[int(py) * N + int(px)] > 1.02) break;
				}
			}
			// roads: from the Godlands out to the beach, with bridges over water
			var roads:int = 6;
			var off:Number = Math.random() * Math.PI * 2;
			for (k = 0; k < roads; k++) {
				a = off + k * Math.PI * 2 / roads + (Math.random() - 0.5) * 0.4;
				var rr:Number = R * 0.08;
				var turn:Number = 0;
				for (step = 0; step < N; step++) {
					turn += (Math.random() - 0.5) * 0.08;
					turn *= 0.92;
					a += turn * 0.2;
					rr += 1;
					px = cx + Math.cos(a) * rr;
					py = cy + Math.sin(a) * rr;
					if (px < 2 || py < 2 || px >= N - 2 || py >= N - 2) break;
					if (dist[int(py) * N + int(px)] > 0.95) break;
					for (ry = 0; ry <= 1; ry++) {
						for (rx = 0; rx <= 1; rx++) {
							i = (int(py) + ry) * N + int(px) + rx;
							if (zones[i] < 0) continue;
							tiles[i] = tiles[i] == WATER || tiles[i] == BRIDGE ? BRIDGE : ROAD;
						}
					}
				}
			}
			// scenery: sparse trees in the lowlands, forests in the midlands, rocks up high
			for (y = 0; y < N; y++) {
				for (x = 0; x < N; x++) {
					i = y * N + x;
					t = tiles[i];
					z = zones[i];
					if (t == WATER || t == ROAD || t == BRIDGE || z < 0) continue;
					var r:Number = Math.random(), f:Number = fbm(6, x, y), o:int = 0;
					if (z == SHORE_ZONE) o = r < 0.012 ? 3 : r < 0.018 ? 4 : 0;
					else if (z == LOW_ZONE) o = r < (f > 0.62 ? 0.14 : 0.025) ? 1 : r < 0.03 ? 4 : 0;
					else if (z == MID_ZONE) o = r < (f > 0.55 ? 0.22 : 0.04) ? (Math.random() < 0.6 ? 2 : 1) : r < 0.05 ? 4 : 0;
					else if (z == HIGH_ZONE) o = r < (f > 0.6 ? 0.1 : 0.025) ? 2 : r < 0.045 ? 5 : r < 0.055 ? 6 : 0;
					else o = r < 0.035 ? 5 : r < 0.05 ? 6 : 0;
					objs[i] = o;
				}
			}
			makeRuins();

			// safe haven on the southern beach
			x = int(cx);
			for (y = N - 1; y > 0; y--) if (zones[y * N + x] >= 0 && tiles[y * N + x] != WATER) break;
			spawnX = x + 0.5;
			spawnY = y - 6 + 0.5;
			var hx:int = int(spawnX), hy:int = int(spawnY);
			for (var dy:int = -6; dy <= 6; dy++) {
				for (var dx:int = -6; dx <= 6; dx++) {
					var tx:int = hx + dx, ty:int = hy + dy;
					if (tx < 0 || ty < 0 || tx >= N || ty >= N) continue;
					i = ty * N + tx;
					if (Math.abs(dx) <= 4 && Math.abs(dy) <= 4) { tiles[i] = PLAZA; zones[i] = SAFE_ZONE; objs[i] = 0; }
					else { objs[i] = 0; if (tiles[i] == WATER && zones[i] >= 0) tiles[i] = SAND; }
				}
			}
			// a road from the haven north until it meets one of the realm roads
			for (y = hy - 5; y > hy - 60 && y > 0; y--) {
				if (y < hy - 8 && (tiles[y * N + hx] == ROAD || tiles[y * N + hx + 1] == ROAD)) break;
				for (dx = 0; dx <= 1; dx++) {
					i = y * N + hx + dx;
					if (zones[i] < 0) continue;
					objs[i] = 0;
					tiles[i] = tiles[i] == WATER || tiles[i] == BRIDGE ? BRIDGE : ROAD;
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
			var count:int = th.small ? 4 + int(Math.random() * 2) : 6 + int(Math.random() * 2);
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
			// a hidden treasure room off one of the middle rooms
			for (var tries:int = 0; tries < 12 && !treasure; tries++) {
				var base:Object = rooms[1 + int(Math.random() * (rooms.length - 2))];
				var side:int = Math.random() < 0.5 ? -1 : 1;
				var tx:int = base.x + side * (int(base.w / 2) + 8), ty:int = base.y;
				var free:Boolean = tx > 12 && tx < N - 12;
				for each (var o:Object in rooms) {
					if (Math.abs(o.x - tx) < o.w / 2 + 6 && Math.abs(o.y - ty) < o.h / 2 + 6) free = false;
				}
				if (!free) continue;
				carve(tx - 3, ty - 3, 7, 7, floor);
				carve(tx - 1, ty - 1, 3, 3, CARPET);
				corridor(base.x, base.y, tx, ty, floor);
				treasure = {x: tx, y: ty, w: 7, h: 7};
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
			for (var k:int = 0; k < (kind == "realm" ? 30 : 26); k++) {
				var cx:int = 0, cy:int = 0, z:int = -1;
				for (var tries:int = 0; tries < 50; tries++) {
					cx = 20 + int(Math.random() * (N - 40));
					cy = 20 + int(Math.random() * (N - 40));
					z = zones[cy * N + cx];
					if (z >= MID_ZONE && z <= GOD_ZONE) break;
				}
				if (z < MID_ZONE || z > GOD_ZONE) continue;
				var rw:int = 3 + int(Math.random() * 5), rh:int = 3 + int(Math.random() * 5);
				var lavaDir:int = Math.random() < 0.5 ? 1 : -1;
				var lava:Boolean = z == GOD_ZONE && Math.random() < 0.75;
				for (var y:int = cy - rh - 1; y <= cy + rh + 1; y++) {
					for (var x:int = cx - rw - 1; x <= cx + rw + 1; x++) {
						var nx:Number = (x - cx) / rw, ny:Number = (y - cy) / rh;
						// blocky, stair-stepped outline like RotMG ruins
						var edge:Number = nx * nx + ny * ny + (Math.random() - 0.5) * 0.25;
						if (edge > 1) continue;
						var i:int = y * N + x;
						if (tiles[i] == WATER || tiles[i] == ROAD || tiles[i] == BRIDGE) continue;
						objs[i] = 0;
						var diag:Number = Math.abs((x - cx) - lavaDir * (y - cy));
						tiles[i] = lava && diag < 1.6 ? LAVA : RUIN;
						// broken walls around the rim, pillars at the corners
						if (edge > 0.72 && tiles[i] == RUIN && Math.random() < 0.3) objs[i] = 9;
					}
				}
				for each (var c:Array in [[-1, -1], [1, -1], [-1, 1], [1, 1]]) {
					var pi:int = (cy + c[1] * (rh - 1)) * N + cx + c[0] * (rw - 1);
					if (tiles[pi] == RUIN) objs[pi] = 8;
				}
			}
		}

		// ------------------------------------------------------------ textures
		private function texture(t:int, tx:int, ty:int):Vector.<uint> {
			var v:Vector.<uint> = new Vector.<uint>(PX * PX, true);
			var x:int, y:int, i:int, r:Number, c:uint;
			var shal:Boolean = t == WATER && shallow(tx, ty);
			var hs:int = ((tx * 7349 + ty * 3613) ^ (tx * ty)) & 255;
			for (y = 0; y < PX; y++) {
				for (x = 0; x < PX; x++) {
					i = y * PX + x;
					r = Math.random();
					var gx:int = tx * PX + x, gy:int = ty * PX + y;
					switch (t) {
						case WATER:
							// RotMG-style water: flat blue with diagonal wave dashes
							var wd:int = (gx + gy * 2 + hs) % 12;
							c = shal ? (wd < 2 && gy % 4 == 0 ? 0x6a98e8 : 0x3a6ac0) : (wd < 2 && gy % 4 == 0 ? 0x4a78d0 : 0x2a52a8);
							break;
						case SAND:
							// flat sand with a few darker grains
							c = mark(gx, gy, 9, hs) ? 0xc9ae6c : mark(gx + 3, gy + 5, 13, hs) ? 0xeed8a0 : 0xdfc68a;
							break;
						case GRASS:
							// flat lowland grass with small two-pixel blades
							c = blade(gx, gy, hs) ? 0x6aaa3c : blade(gx + 4, gy + 2, hs + 7) ? 0x3f7a22 : 0x529230;
							break;
						case HIGH:
							// dry highland grass
							c = blade(gx, gy, hs) ? 0x95914c : blade(gx + 4, gy + 2, hs + 7) ? 0x5c5a2a : 0x7a773a;
							break;
						case ROAD:
							var rc:String = String(STONE_PAT[y]).charAt(x);
							c = rc == "S" ? 0x9a9080 : rc == "H" ? 0xaaa090 : rc == "h" ? 0x8e8676 : 0x5e574c;
							if (r < 0.1 && rc != "m") c = Sprites.shade(c, 0.92);
							break;
						case RUIN:
							// grey flagstones of an old ruin
							var fc:String = String(PLAZA_PAT[(y + 4) % PX]).charAt((x + (ty & 1) * 4) % PX);
							c = fc == "L" ? 0x9a9aa2 : fc == "M" ? 0x84848c : 0x6e6e76;
							if (mark(gx, gy, 9, hs)) c = 0x5c5c64;
							break;
						case BRIDGE:
							c = y % 4 == 3 ? 0x4a2e16 : (x == 0 || x == PX - 1) ? 0x5a3a1c : r < 0.15 ? 0x7a4e26 : 0x8a5a2e;
							break;
						case DARK:
							c = blade(gx, gy, hs) ? 0x447a2c : blade(gx + 4, gy + 2, hs + 7) ? 0x24481a : 0x31612a;
							break;
						case GOD:
							// Godlands rock: dark grey with short cracks
							c = mark(gx, gy, 7, hs) || mark(gx + 1, gy, 7, hs) ? 0x2e2e30 : mark(gx + 2, gy + 4, 11, hs) ? 0x5a5a5e : 0x434346;
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

		/** Sparse, regular texture marks (instead of per-pixel noise). */
		private static function mark(gx:int, gy:int, every:int, seed:int):Boolean {
			return ((gx * 5 + gy * 3 + seed) % every) == 0 && ((gx + gy * 7 + seed) % 3) == 0;
		}

		/** Little vertical grass blades two pixels tall. */
		private static function blade(gx:int, gy:int, seed:int):Boolean {
			var cx:int = gx + ((gy >> 1) * 5 + seed) % 7;
			return (cx % 7) == 0 && ((gy >> 1) + seed) % 3 == 0;
		}

		/** Water next to land is drawn lighter, like RotMG's shallows. */
		private function shallow(tx:int, ty:int):Boolean {
			if (kind != "realm") return false;
			for (var dy:int = -1; dy <= 1; dy++) {
				for (var dx:int = -1; dx <= 1; dx++) {
					var nt:int = tileAtI(tx + dx, ty + dy);
					if (nt != WATER) return true;
				}
			}
			return false;
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
			if (t == BRICK || t == LAVA || t == RUIN) { col = 0xc0c0c8; dark = 0x2a2a2a; }
			else if (t == PLAZA) { col = 0x8c8c8c; dark = 0x5a5a5a; }
			else if (t == WATER) { col = 0x7aa0e0; dark = 0x2b4ea0; }
			else if (t == ROAD) { col = 0x6e665a; dark = 0x4a443a; }
			else if (t == BRIDGE) { col = 0x3a220e; dark = 0x2a1808; }
			else if (t == CARPET) { col = 0xd8a830; dark = 0x8a6a18; }
			else if (t == FOUNTAIN) { col = 0xd0d0d8; dark = 0x8a8a92; }
			else if (t == ARENA) { col = 0x9a9a9a; dark = 0x6a6a6a; }
			else return;
			var px:int = x * PX, py:int = y * PX;
			var same:Function = function(nt:int):Boolean {
				if (t == BRICK || t == LAVA || t == RUIN) return nt == BRICK || nt == LAVA || nt == RUIN;
				if (t == ROAD || t == BRIDGE) return nt == ROAD || nt == BRIDGE;
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
			// lakes and rivers can be waded through (slowly); the open sea cannot
			return (t != WATER || zones[i] >= 0) && t != VOID && t != WALL && objs[i] == 0;
		}

		/** Wading through water halves your speed. */
		public function inWater(x:Number, y:Number):Boolean {
			return tileAt(x, y) == WATER;
		}

		public function isSafe(x:Number, y:Number):Boolean {
			var z:int = zoneAt(x, y);
			return z == SAFE_ZONE || z == NEXUS_ZONE;
		}

		/** True if a body of half-size r fits at (x, y). Enemies may not enter the safe haven. */
		public function canStand(x:Number, y:Number, r:Number, enemy:Boolean):Boolean {
			if (!walkable(x - r, y - r) || !walkable(x + r, y - r) || !walkable(x - r, y + r) || !walkable(x + r, y + r)) return false;
			if (enemy && (isSafe(x - r, y - r) || isSafe(x + r, y + r) || isSafe(x + r, y - r) || isSafe(x - r, y + r))) return false;
			return true;
		}
	}
}
