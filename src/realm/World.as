package realm {
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	/**
	 * A round island realm: shore on the rim, more dangerous toward the
	 * godlands in the centre, with brick ruins and lava scattered inland.
	 * Ground is rendered in 8px-per-tile chunks as you approach them (scaled 5x in game);
	 * trees and rocks are separate objects drawn y-sorted with the entities.
	 */
	public class World {
		/** Map size in tiles: realms are big islands, other worlds use the default. */
		public static const DEFAULT_N:int = 200;
		public static const REALM_N:int = 512;
		/** Ground chunks are CHUNK x CHUNK tiles, rendered when first seen. */
		public static const CHUNK:int = 32;
		/** Most chunks a world keeps rendered at once (each is 256x256 pixels). */
		private static const MAX_CHUNKS:int = 72;
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
		public static const OBJ_NAMES:Array = [null, "tree", "pine", "palm", "rock", "boulder", "deadtree", "brazier", "pillar", "ruinwall", "tent", "grave", "campfire", "totem",
			"shrine_might", "shrine_haste", "shrine_fortune", "shrine_vigor", "shrine_arcana", "banner"];
		/** Shrine kinds, in the order of their objects (14-18). */
		public static const SHRINES:Array = ["might", "haste", "fortune", "vigor", "arcana"];
		public static const NEXUS_ZONE:int = 5;

		public static const MINI_COL:Array = [0x2b4ea0, 0xd6bc7a, 0x4e8c2f, 0x35602a, 0x46464a, 0xd0d0d0, 0x9c6236, 0xc0301a,
			0x000000, 0x5c5c64, 0xa0a0a8, 0x9a2020, 0x3a8ad8, 0xdcdcdc, 0xa01c1c, 0x77733c, 0x9a9080, 0x8a5a2e, 0x8e8e96];
		private static const STONE_PAT:Array = ["hhhmHHHm", "hSSmHSSm", "hSSmHSSm", "mmmmmmmm", "HHmhhhmH", "SSmhSSmS", "SSmhSSmS", "mmmmmmmm"];
		private static const WALL_PAT:Array = ["LLLLLLLL", "LTTdLTTd", "LTTdLTTd", "dddddddd", "TdLTTdLT", "TdLTTdLT", "FFFFFFFF", "ffffffff"];

		private static const PLAZA_PAT:Array = ["LLLMMLLL", "LLMLLMLL", "LMLDDLML", "MLDLLDLM", "MLDLLDLM", "LMLDDLML", "LLMLLMLL", "LLLMMLLL"];
		private static const BRICK_PAT:Array = ["hhhaHHHb", "hAAaHBBb", "hAAaHBBb", "aaaabbbb", "HHHbhhha", "HBBbhAAa", "HBBbhAAa", "bbbbaaaa"];

		public var tiles:Vector.<int>;
		public var objs:Vector.<int>;
		public var zones:Vector.<int>;
		/** Rendered ground chunks by index, plus the order they were last used in. */
		private var chunks:Object = {};
		private var chunkOrder:Array = [];
		private var drawMtx:Matrix = new Matrix();
		/** The bitmap a chunk is being drawn into, and its pixel offset. */
		private var target:BitmapData;
		private var offX:int, offY:int;
		/** Per-tile random state for ground textures (independent of the map seed). */
		private var trng:uint = 1;
		/**
		 * Realm landmarks: {x, y, r, kind, name, zone, boss, guards, color,
		 * cleared, active, found}. Each one is guarded until its leader falls.
		 */
		public var sites:Array = [];
		/** Realm shrines: {x, y, kind, cd} (cd = seconds until it can bless you again, kept per player). */
		public var shrines:Array = [];
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
		/**
		 * Raids: gates[k] are the cells sealing the way past stage k ({i, t}:
		 * tile index and the floor it becomes); stageSpots[k] are where that
		 * stage's bosses stand; mobRooms are {x, y, w, h, n} rooms of guards.
		 */
		public var gates:Array = [];
		public var stageSpots:Array = [];
		public var mobRooms:Array = [];
		/** Dungeon side room holding a treasure chest (or null). */
		public var treasure:Object;
		public var theme:Object;

		private var noise:Vector.<Number>;
		private var noiseW:int;
		private const CELL:int = 10;
		/** Extra noise layers for the realm: {v, w, cell}. */
		private var layers:Array;

		/**
		 * Identifies the world for other players: "nexus", "realm:Name:seed",
		 * "dg:index:seed"; worlds nobody else can enter get a unique "solo:" key.
		 */
		public var key:String = "";
		/** Map seed (0 = random). */
		public var seed:uint = 0;
		/** Online: monsters by network id. */
		public var eById:Object = {};
		/** Online: spawns the world's monsters once we know we're its host. */
		public var pendingPopulate:Function;
		/** Raid arenas: the raid, its current stage and the countdown to the next. */
		public var raid:Object;
		public var raidStage:int = -1;
		public var raidT:Number = 0;
		/** Seeded generator state: the same seed builds the same map for everyone. */
		private var seedState:uint = 0;

		/** Random 0..1 from the seed (or Math.random when there is no seed). */
		private function rnd():Number {
			if (seedState == 0) return Math.random();
			// xorshift32
			seedState ^= seedState << 13;
			seedState ^= seedState >>> 17;
			seedState ^= seedState << 5;
			return (seedState >>> 0) / 4294967296;
		}

		public function World(kind:String = "realm", name:String = "", theme:Object = null, seed:uint = 0) {
			seedState = seed;
			this.seed = seed;
			this.kind = kind;
			this.name = name;
			this.theme = theme;
			N = kind == "realm" ? REALM_N : DEFAULT_N;
			tiles = new Vector.<int>(N * N, true);
			objs = new Vector.<int>(N * N, true);
			zones = new Vector.<int>(N * N, true);
			if (kind == "nexus") generateNexus();
			else if (kind == "vault") generateVault();
			else if (kind == "arena") generateArena();
			else if (kind == "custom") generateCustom();
			else if (kind == "dungeon") generateDungeon(theme);
			else generate();
			render();
			seen = new BitmapData(N, N, true, 0);
		}

		// ------------------------------------------------------------ generation
		private function makeNoise():void {
			noiseW = int(N / CELL) + 2;
			noise = new Vector.<Number>(noiseW * noiseW, true);
			for (var i:int = 0; i < noise.length; i++) noise[i] = rnd();
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
			for (var i:int = 0; i < v.length; i++) v[i] = rnd();
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
			var big:Number = N / 320;
			layers = [layer(int(40 * big)), layer(int(16 * big)), layer(6), layer(30), layer(12), layer(5), layer(24), layer(9), layer(4)];
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
			var rivers:int = int(4 * big + 1.5);
			for (k = 0; k < rivers; k++) {
				a = rnd() * Math.PI * 2;
				px = cx + Math.cos(a) * R * 0.35;
				py = cy + Math.sin(a) * R * 0.35;
				var wig:Number = 0;
				for (step = 0; step < N * 2; step++) {
					wig += (rnd() - 0.5) * 0.5;
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
			var roads:int = int(6 * big + 0.5);
			var off:Number = rnd() * Math.PI * 2;
			for (k = 0; k < roads; k++) {
				a = off + k * Math.PI * 2 / roads + (rnd() - 0.5) * 0.4;
				var rr:Number = R * 0.08;
				var turn:Number = 0;
				for (step = 0; step < N; step++) {
					turn += (rnd() - 0.5) * 0.08;
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
					var r:Number = rnd(), f:Number = fbm(6, x, y), o:int = 0;
					if (z == SHORE_ZONE) o = r < 0.012 ? 3 : r < 0.018 ? 4 : 0;
					else if (z == LOW_ZONE) o = r < (f > 0.66 ? 0.06 : 0.01) ? 1 : r < 0.016 ? 4 : 0;
					else if (z == MID_ZONE) o = r < (f > 0.6 ? 0.09 : 0.015) ? (rnd() < 0.6 ? 2 : 1) : r < 0.024 ? 4 : 0;
					else if (z == HIGH_ZONE) o = r < (f > 0.64 ? 0.045 : 0.01) ? 2 : r < 0.028 ? 5 : r < 0.034 ? 6 : 0;
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
			for (y = hy - 5; y > hy - 90 && y > 0; y--) {
				if (y < hy - 8 && (tiles[y * N + hx] == ROAD || tiles[y * N + hx + 1] == ROAD)) break;
				for (dx = 0; dx <= 1; dx++) {
					i = y * N + hx + dx;
					if (zones[i] < 0) continue;
					objs[i] = 0;
					tiles[i] = tiles[i] == WATER || tiles[i] == BRIDGE ? BRIDGE : ROAD;
				}
			}
			makeSites(hx, hy);
			makeShrines(hx, hy);
		}

		/** Shrines scattered inland: touch one for a minute-long blessing. */
		private function makeShrines(hx:int, hy:int):void {
			var want:int = int(N / 40);
			for (var tries:int = 0; tries < 2000 && shrines.length < want; tries++) {
				var x:int = 12 + int(rnd() * (N - 24)), y:int = 12 + int(rnd() * (N - 24));
				var z:int = zones[y * N + x];
				if (z < LOW_ZONE || z > GOD_ZONE || tiles[y * N + x] == WATER) continue;
				if ((x - hx) * (x - hx) + (y - hy) * (y - hy) < 30 * 30 || siteAt(x, y, 6)) continue;
				var ok:Boolean = true;
				for each (var o:Object in shrines) if ((o.x - x) * (o.x - x) + (o.y - y) * (o.y - y) < 40 * 40) { ok = false; break; }
				if (!ok) continue;
				var k:int = int(rnd() * SHRINES.length);
				// a small paved clearing around the pedestal
				for (var dy:int = -2; dy <= 2; dy++) for (var dx:int = -2; dx <= 2; dx++) {
					var i:int = (y + dy) * N + x + dx;
					if (dx * dx + dy * dy <= 5 && tiles[i] != WATER) { objs[i] = 0; tiles[i] = RUIN; }
				}
				objs[y * N + x] = 14 + k;
				shrines.push({x: x + 0.5, y: y + 0.5, kind: SHRINES[k], cd: 0});
			}
		}

		/**
		 * Landmarks spread over the realm: camps, groves, halls and temples,
		 * each held by a leader and its band until someone clears it.
		 */
		private function makeSites(hx:int, hy:int):void {
			var per:int = Math.max(2, int(N / 110));
			for (var k:int = 0; k < Data.SITES.length; k++) {
				var def:Object = Data.SITES[k];
				var placed:int = 0;
				for (var tries:int = 0; tries < 400 && placed < per; tries++) {
					var x:int = 16 + int(rnd() * (N - 32)), y:int = 16 + int(rnd() * (N - 32));
					var i:int = y * N + x;
					if (zones[i] != def.zone || tiles[i] == WATER) continue;
					if ((x - hx) * (x - hx) + (y - hy) * (y - hy) < 40 * 40) continue;
					var ok:Boolean = true;
					// the Godlands are small, so their sites may sit closer together
					var gap:int = def.zone == GOD_ZONE ? 24 : 36;
					for each (var o:Object in sites) {
						if ((o.x - x) * (o.x - x) + (o.y - y) * (o.y - y) < gap * gap) { ok = false; break; }
					}
					// mostly dry ground
					var wet:int = 0;
					for (var dy:int = -def.r; dy <= def.r; dy += 2) for (var dx:int = -def.r; dx <= def.r; dx += 2) {
						var j:int = (y + dy) * N + x + dx;
						if (tiles[j] == WATER || zones[j] < 0 || zones[j] == SAFE_ZONE) wet++;
					}
					if (!ok || wet > 4) continue;
					buildSite(def, x, y);
					sites.push({x: x + 0.5, y: y + 0.5, r: def.r, kind: def.id, name: def.name, zone: def.zone, boss: def.boss,
						guards: def.guards, n: def.n, color: def.color, cleared: false, active: false, found: false});
					placed++;
				}
			}
		}

		/** Lays out a landmark's ground and scenery. */
		private function buildSite(def:Object, cx:int, cy:int):void {
			var r:int = def.r;
			for (var y:int = cy - r - 1; y <= cy + r + 1; y++) {
				for (var x:int = cx - r - 1; x <= cx + r + 1; x++) {
					var dx:int = x - cx, dy:int = y - cy;
					var d:Number = Math.sqrt(dx * dx + dy * dy);
					if (d > r + 0.5) continue;
					var i:int = y * N + x;
					if (tiles[i] == WATER && d > r - 2) continue;
					objs[i] = 0;
					var edge:Boolean = d > r - 1.2;
					if (def.floor >= 0) tiles[i] = def.floor;
					if (def.inner >= 0 && d < r * 0.35) tiles[i] = def.inner;
					// a broken ring of the site's scenery, with gaps to walk through
					if (edge && def.wall && rnd() < def.wallChance && Math.abs(dy) > 1 && Math.abs(dx) > 1) objs[i] = def.wall;
					else if (!edge && def.prop && d > 2.5 && rnd() < def.propChance) objs[i] = def.prop;
				}
			}
			// the centrepiece (a campfire, an altar...)
			if (def.centre) objs[cy * N + cx] = def.centre;
			if (def.pillars) for each (var c:Array in [[-1, -1], [1, -1], [-1, 1], [1, 1]]) {
				var pi:int = (cy + c[1] * int(r * 0.6)) * N + cx + c[0] * int(r * 0.6);
				objs[pi] = def.pillars;
			}
		}

		/** The landmark at (x, y), or null. */
		public function siteAt(x:Number, y:Number, extra:Number = 0):Object {
			for each (var s:Object in sites) {
				var dx:Number = s.x - x, dy:Number = s.y - y, rr:Number = s.r + extra;
				if (dx * dx + dy * dy < rr * rr) return s;
			}
			return null;
		}

		/**
		 * The Nexus: a great walled hall. The Realm Gate (portals) runs along the
		 * north wall; the healing fountain sits in a round plaza ringed by class
		 * statues and four gardens; the vault portal, Fame Store and Pet Yard are in
		 * the west wing, the Starforge and Raid Table in the east, and the
		 * Marketplace and Quest Board by the south entrance.
		 */
		private function generateNexus():void {
			var x:int, y:int, i:int, d:Number;
			for (i = 0; i < N * N; i++) { tiles[i] = VOID; zones[i] = -1; objs[i] = 0; }
			var x0:int = 66, x1:int = 134, y0:int = 64, y1:int = 128;
			for (y = y0; y <= y1; y++) {
				for (x = x0; x <= x1; x++) {
					i = y * N + x;
					zones[i] = NEXUS_ZONE;
					tiles[i] = (x == x0 || x == x1 || y == y0 || y == y1) ? WALL : STONE;
				}
			}
			// the Realm Gate: a carpeted dais along the north wall, pillars between the portals
			fillN(80, 65, 41, 10, CARPET);
			fillN(80, 75, 41, 1, RUIN);
			for (x = 82; x <= 118; x += 6) objs[66 * N + x] = 8;
			objs[70 * N + 78] = 7; objs[70 * N + 122] = 7;
			// avenues: gate to plaza to the south entrance, and out to both wings
			fillN(99, 76, 3, 52, CARPET);
			fillN(67, 97, 66, 3, CARPET);
			// the round plaza with the healing fountain
			for (y = 85; y <= 111; y++) {
				for (x = 87; x <= 113; x++) {
					d = Math.sqrt((x - 100) * (x - 100) + (y - 98) * (y - 98));
					i = y * N + x;
					if (d <= 3) tiles[i] = FOUNTAIN;
					else if (d <= 5.6 && d > 4.4) tiles[i] = CARPET;
					else if (d <= 12.5) tiles[i] = PLAZA;
				}
			}
			for each (var br:Array in [[89, 87], [111, 87], [89, 109], [111, 109]]) objs[br[1] * N + br[0]] = 7;
			// four gardens with trees and a little pond
			for each (var gd:Array in [[78, 82], [122, 82], [78, 114], [122, 114]]) {
				fillN(gd[0] - 4, gd[1] - 3, 9, 7, GRASS);
				fillN(gd[0] - 1, gd[1], 3, 2, WATER);
				objs[(gd[1] - 2) * N + gd[0] - 3] = 1;
				objs[(gd[1] - 2) * N + gd[0] + 3] = 2;
				objs[(gd[1] + 2) * N + gd[0] - 3] = 2;
				objs[(gd[1] + 2) * N + gd[0] + 3] = 1;
			}
			// west wing: a gold-trimmed alcove around the vault portal
			fillN(67, 93, 7, 11, CARPET);
			objs[94 * N + 68] = 8; objs[102 * N + 68] = 8;
			// east wing: a brick workshop floor for the Starforge and Raid Table
			fillN(124, 87, 10, 21, BRICK);
			fillN(124, 97, 10, 3, CARPET);
			// south entrance hall
			fillN(84, 117, 33, 10, RUIN);
			fillN(99, 117, 3, 10, CARPET);
			// banners along the walls
			for each (var bn:Array in [[70, 65], [76, 65], [124, 65], [130, 65], [67, 108], [133, 108], [67, 88], [133, 88]]) objs[bn[1] * N + bn[0]] = 19;
			for each (var lp:Array in [[84, 118], [116, 118], [70, 122], [130, 122]]) objs[lp[1] * N + lp[0]] = 7;
			spawnX = 100.5;
			spawnY = 124.5;
		}

		/** Your vault: a private treasury of chests (see Game.enterVault). */
		private function generateVault():void {
			var x:int, y:int, i:int;
			for (i = 0; i < N * N; i++) { tiles[i] = VOID; zones[i] = -1; objs[i] = 0; }
			for (y = 86; y <= 114; y++) {
				for (x = 86; x <= 114; x++) {
					i = y * N + x;
					zones[i] = NEXUS_ZONE;
					tiles[i] = (x == 86 || x == 114 || y == 86 || y == 114) ? WALL : STONE;
				}
			}
			fillN(88, 90, 25, 13, CARPET);
			fillN(89, 91, 23, 11, PLAZA);
			fillN(99, 102, 3, 12, CARPET);
			for each (var p:Array in [[88, 88], [112, 88], [88, 104], [112, 104]]) objs[p[1] * N + p[0]] = 8;
			for each (var b:Array in [[90, 88], [110, 88], [90, 112], [110, 112]]) objs[b[1] * N + b[0]] = 7;
			for each (var bn:Array in [[96, 87], [104, 87]]) objs[bn[1] * N + bn[0]] = 19;
			spawnX = 100.5;
			spawnY = 109.5;
		}

		/** Fills a rectangle of the hub maps with one tile. */
		private function fillN(x0:int, y0:int, w:int, h:int, t:int):void {
			for (var y:int = y0; y < y0 + h; y++) for (var x:int = x0; x < x0 + w; x++) {
				var i:int = y * N + x;
				tiles[i] = t;
				objs[i] = 0;
			}
		}

		/**
		 * A dungeon: a chain of rooms carved northward from the entrance and joined
		 * by corridors, with walls around everything and the boss in the last room.
		 */
		private function generateDungeon(th:Object):void {
			var x:int, y:int, i:int;
			for (i = 0; i < N * N; i++) { tiles[i] = VOID; zones[i] = -1; objs[i] = 0; }
			var floor:int = th.floor, accent:int = th.accent;
			// each dungeon has its own layout style
			switch (th.layout) {
				case "cave": layoutCave(th, floor, accent); break;
				case "grid": layoutGrid(th, floor, accent); break;
				case "islands": layoutIslands(th, floor, accent); break;
				case "ring": layoutRing(th, floor, accent); break;
				case "maze": layoutMaze(th, floor, accent); break;
				case "conclave": layoutConclave(th); break;
				case "spire": layoutSpire(th); break;
				default: layoutRooms(th, floor, accent);
			}
			if (th.hazard) addHazards(th.hazard);
			// a hidden treasure room off one of the middle rooms
			for (var tries:int = 0; tries < 12 && !treasure && !th.raid; tries++) {
				var base:Object = rooms[1 + int(rnd() * (rooms.length - 2))];
				var side:int = rnd() < 0.5 ? -1 : 1;
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
			// walls wherever floor meets the void (islands float over the abyss instead)
			if (th.layout != "islands" && th.layout != "spire") for (y = 1; y < N - 1; y++) {
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
			spawnY = rooms[0].y + 0.5 + Math.max(0, Math.min(2, int(rooms[0].h / 2) - 1));
		}

		/** Classic: a chain of rectangular rooms joined by corridors. */
		private function layoutRooms(th:Object, floor:int, accent:int):void {
			var cx:int = 100, cy:int = 175;
			var count:int = th.small ? 4 + int(rnd() * 2) : 6 + int(rnd() * 2);
			var prev:Object = null;
			for (var k:int = 0; k < count; k++) {
				var boss:Boolean = k == count - 1;
				var w:int = boss ? 23 : 9 + int(rnd() * 5);
				var h:int = boss ? 19 : 8 + int(rnd() * 4);
				var room:Object = {x: cx, y: cy, w: w, h: h};
				carve(cx - int(w / 2), cy - int(h / 2), w, h, floor);
				// accent pattern in the middle of bigger rooms (lava pools, carpets...)
				if (!boss && k > 0 && rnd() < 0.6) carve(cx - 1, cy - 1, 3, 3, accent);
				if (prev) corridor(prev.x, prev.y, cx, cy, floor);
				rooms.push(room);
				prev = room;
				// next room: mostly north, drifting east/west
				var dir:Number = rnd();
				if (dir < 0.25 && cx > 50) cx -= 16 + int(rnd() * 4);
				else if (dir < 0.5 && cx < 150) cx += 16 + int(rnd() * 4);
				else cy -= 17 + int(rnd() * 3);
				if (k == count - 2) { cy -= 4; }
				if (cy < 25) cy = 25;
			}
		}

		/** Caverns: lumpy round chambers joined by winding tunnels. */
		private function layoutCave(th:Object, floor:int, accent:int):void {
			var cx:int = 100, cy:int = 178;
			var count:int = th.small ? 4 + int(rnd() * 2) : 6 + int(rnd() * 2);
			var prev:Object = null;
			for (var k:int = 0; k < count; k++) {
				var boss:Boolean = k == count - 1;
				var r:Number = boss ? 12.5 : 5 + rnd() * 2.5;
				blob(cx, cy, r, floor);
				if (!boss && k > 0 && rnd() < 0.5) blob(cx + int(rnd() * 4) - 2, cy + int(rnd() * 4) - 2, 1.6, accent);
				if (prev) tunnel(prev.x, prev.y, cx, cy, floor);
				var room:Object = {x: cx, y: cy, w: int(r * 1.6), h: int(r * 1.6)};
				rooms.push(room);
				prev = room;
				var a:Number = -Math.PI / 2 + (rnd() - 0.5) * 1.6;
				var d:Number = 17 + rnd() * 4;
				cx = Math.max(25, Math.min(N - 25, cx + int(Math.cos(a) * d)));
				cy = Math.max(22, cy + int(Math.sin(a) * d));
			}
		}

		/** Pillared halls on a grid, joined by long straight corridors. */
		private function layoutGrid(th:Object, floor:int, accent:int):void {
			var cols:int = 3, rowsN:int = th.small ? 2 : 3;
			var gx:int = 68, gy:int = 170, step:int = 20;
			// snake through the grid from bottom-left to the top
			var order:Array = [];
			for (var row:int = 0; row < rowsN; row++) {
				for (var c:int = 0; c < cols; c++) order.push([row % 2 == 0 ? c : cols - 1 - c, row]);
			}
			var prev:Object = null;
			for (var k:int = 0; k < order.length; k++) {
				var cx:int = gx + order[k][0] * step, cy:int = gy - order[k][1] * step;
				var w:int = 11, h:int = 11;
				carve(cx - 5, cy - 5, w, h, floor);
				// pillars for cover
				for each (var pp:Array in [[-3, -3], [3, -3], [-3, 3], [3, 3]]) if (k > 0) tiles[(cy + pp[1]) * N + cx + pp[0]] = WALL;
				if (k > 0 && rnd() < 0.5) carve(cx - 1, cy - 1, 3, 3, accent);
				if (prev) corridor(prev.x, prev.y, cx, cy, floor);
				var room:Object = {x: cx, y: cy, w: w, h: h};
				rooms.push(room);
				prev = room;
			}
			// the boss hall above the grid
			var bx:int = prev.x, by:int = gy - rowsN * step - 6;
			carve(bx - 12, by - 10, 25, 21, floor);
			for each (var bp:Array in [[-8, -6], [8, -6], [-8, 6], [8, 6]]) tiles[(by + bp[1]) * N + bx + bp[0]] = WALL;
			carve(bx - 2, by - 2, 5, 5, accent);
			corridor(prev.x, prev.y, bx, by, floor);
			rooms.push({x: bx, y: by, w: 25, h: 21});
		}

		/** Floating platforms over the abyss, joined by narrow bridges. */
		private function layoutIslands(th:Object, floor:int, accent:int):void {
			var cx:int = 100, cy:int = 178;
			var count:int = th.small ? 5 : 7;
			var prev:Object = null;
			for (var k:int = 0; k < count; k++) {
				var boss:Boolean = k == count - 1;
				var r:Number = boss ? 13 : k == 0 ? 5 : 4.5 + rnd() * 2;
				blob(cx, cy, r, floor);
				if (!boss && k > 0) blob(cx, cy, 1.5, accent);
				if (prev) bridge(prev.x, prev.y, cx, cy);
				var room:Object = {x: cx, y: cy, w: int(r * 1.5), h: int(r * 1.5)};
				rooms.push(room);
				prev = room;
				var a:Number = -Math.PI / 2 + (rnd() - 0.5) * 2;
				var d:Number = 18 + rnd() * 5;
				cx = Math.max(25, Math.min(N - 25, cx + int(Math.cos(a) * d)));
				cy = Math.max(22, cy + int(Math.sin(a) * d));
			}
		}

		/** Chambers around a great ring, with the boss waiting in the centre. */
		private function layoutRing(th:Object, floor:int, accent:int):void {
			var ccx:int = 100, ccy:int = 100, R:int = 38;
			var n:int = th.small ? 5 : 7;
			var prev:Object = null, first:Object;
			for (var k:int = 0; k < n; k++) {
				var a:Number = Math.PI / 2 + k * Math.PI * 2 / n;
				var cx:int = ccx + int(Math.cos(a) * R), cy:int = ccy + int(Math.sin(a) * R);
				blob(cx, cy, 5.5, floor);
				if (k > 0 && rnd() < 0.6) blob(cx, cy, 1.6, accent);
				if (prev) arc(prev.x, prev.y, cx, cy, ccx, ccy, floor);
				var room:Object = {x: cx, y: cy, w: 9, h: 9};
				rooms.push(room);
				if (!first) first = room;
				prev = room;
			}
			// the inner sanctum, reached from the last chamber
			blob(ccx, ccy, 13.5, floor);
			blob(ccx, ccy, 3, accent);
			corridor(prev.x, prev.y, ccx, ccy, floor);
			rooms.push({x: ccx, y: ccy, w: 24, h: 24});
		}

		/** A real labyrinth: twisting 3-wide passages, the boss beyond its far corner. */
		private function layoutMaze(th:Object, floor:int, accent:int):void {
			var W:int = th.small ? 9 : 11, H:int = th.small ? 9 : 11, cell:int = 5;
			var x0:int = 100 - int(W * cell / 2), y0:int = 120 - int(H * cell / 2);
			var seen:Array = [];
			for (var i:int = 0; i < W * H; i++) seen.push(false);
			var stack:Array = [[0, H - 1]];
			seen[(H - 1) * W] = true;
			var dirs:Array = [[1, 0], [-1, 0], [0, 1], [0, -1]];
			carve(x0 + 1, y0 + (H - 1) * cell + 1, 3, 3, floor);
			while (stack.length) {
				var cur:Array = stack[stack.length - 1];
				var opts:Array = [];
				for each (var d:Array in dirs) {
					var nx:int = cur[0] + d[0], ny:int = cur[1] + d[1];
					if (nx >= 0 && ny >= 0 && nx < W && ny < H && !seen[ny * W + nx]) opts.push([nx, ny]);
				}
				if (!opts.length) { stack.pop(); continue; }
				var nxt:Array = opts[int(rnd() * opts.length)];
				seen[nxt[1] * W + nxt[0]] = true;
				// knock through the wall between the two cells
				var ax:int = x0 + cur[0] * cell + 1, ay:int = y0 + cur[1] * cell + 1;
				var bx:int = x0 + nxt[0] * cell + 1, by:int = y0 + nxt[1] * cell + 1;
				carve(Math.min(ax, bx), Math.min(ay, by), Math.abs(ax - bx) + 3, Math.abs(ay - by) + 3, floor);
				stack.push(nxt);
			}
			// a few loops so it isn't a single path
			for (var lp:int = 0; lp < W; lp++) {
				var lx:int = x0 + int(rnd() * (W - 1)) * cell + 1, ly:int = y0 + int(rnd() * H) * cell + 1;
				carve(lx, ly, cell + 3, 3, floor);
			}
			var sx:int = x0 + 2, sy:int = y0 + (H - 1) * cell + 2;
			rooms.push({x: sx, y: sy, w: 3, h: 3});
			// clearings for monsters scattered through the maze
			for (var k:int = 0; k < (th.small ? 5 : 7); k++) {
				var mx:int = x0 + int(rnd() * W) * cell + 2, my:int = y0 + int(rnd() * H) * cell + 2;
				carve(mx - 2, my - 2, 5, 5, floor);
				if (rnd() < 0.4) carve(mx, my, 1, 1, accent);
				rooms.push({x: mx, y: my, w: 5, h: 5});
			}
			// the boss lair past the far corner
			var ex:int = x0 + (W - 1) * cell + 2, ey:int = y0 + 2;
			var lx2:int = ex + 18, ly2:int = ey - 4;
			carve(lx2 - 11, ly2 - 9, 23, 19, floor);
			carve(lx2 - 1, ly2 - 1, 3, 3, accent);
			corridor(ex, ey, lx2, ly2, floor);
			rooms.push({x: lx2, y: ly2, w: 23, h: 19});
		}

		// ------------------------------------------------------------ raids
		/** A rectangular room centred on (cx, cy). */
		private function hall(cx:int, cy:int, w:int, h:int, t:int):Object {
			carve(cx - int(w / 2), cy - int(h / 2), w, h, t);
			return {x: cx, y: cy, w: w, h: h};
		}

		/** Seals rows y0..y1 of a 3-wide north-south corridor at x as gate k. */
		private function gateRows(k:int, x:int, y0:int, y1:int, seal:int):void {
			while (gates.length <= k) gates.push([]);
			for (var y:int = y0; y <= y1; y++) for (var dx:int = -1; dx <= 1; dx++) {
				var i:int = y * N + x + dx;
				gates[k].push({i: i, t: tiles[i]});
				tiles[i] = seal;
			}
		}

		/**
		 * The Crimson Conclave: a blood cathedral. Narthex, a pillared nave with
		 * crypts, two chapels where the Zealots wait, the Matron's sanctum, and
		 * Archon Vesper's altar. Each sealed door opens when a stage falls.
		 */
		private function layoutConclave(th:Object):void {
			var x:int, y:int, i:int;
			rooms.push(hall(100, 184, 11, 9, STONE));
			corridor(100, 184, 100, 170, STONE);
			var nave:Object = hall(100, 157, 15, 29, STONE);
			carve(99, 143, 3, 29, CARPET);
			for (y = 146; y <= 168; y += 5) { objs[y * N + 95] = 8; objs[y * N + 105] = 8; }
			pool(96, 151, 1.4); pool(104, 163, 1.4); pool(104, 149, 1.1);
			// crypts off the nave
			var wc:Object = hall(80, 160, 9, 9, STONE), ec:Object = hall(120, 160, 9, 9, STONE);
			corridor(93, 160, 80, 160, STONE); corridor(107, 160, 120, 160, STONE);
			for each (var c:Object in [wc, ec]) for (var g:int = 0; g < 5; g++) objs[(c.y - 3 + (g % 2) * 6) * N + c.x - 3 + int(g / 2) * 3] = 11;
			// the Zealots' chapels
			var wch:Object = hall(72, 140, 17, 13, BLOODSTONE), ech:Object = hall(128, 140, 17, 13, BLOODSTONE);
			carve(73, 139, 3, 3, CARPET); carve(125, 139, 3, 3, CARPET);
			corridor(93, 145, 74, 145, STONE); corridor(107, 145, 126, 145, STONE);
			for each (c in [wch, ech]) { objs[(c.y - 4) * N + c.x - 5] = 7; objs[(c.y - 4) * N + c.x + 5] = 7; }
			// the Matron's sanctum, behind the first seal
			corridor(100, 143, 100, 119, STONE);
			gateRows(0, 100, 133, 134, WALL);
			var sanct:Object = hall(100, 112, 25, 17, BLOODSTONE);
			pool(93, 107, 1.5); pool(107, 107, 1.5); pool(93, 117, 1.5); pool(107, 117, 1.5);
			for each (var b:Array in [[91, 105], [109, 105], [91, 119], [109, 119]]) objs[b[1] * N + b[0]] = 7;
			// Archon Vesper's altar, behind the second seal
			corridor(100, 105, 100, 83, STONE);
			gateRows(1, 100, 94, 95, WALL);
			var altar:Object = hall(100, 72, 25, 23, BLOODSTONE);
			carve(90, 63, 21, 19, ARENA);
			carve(99, 72, 3, 12, CARPET);
			carve(97, 66, 7, 5, CARPET);
			for each (var p:Array in [[91, 64], [109, 64], [91, 80], [109, 80], [95, 61], [105, 61]]) objs[p[1] * N + p[0]] = 8;
			for each (b in [[89, 62], [111, 62], [89, 82], [111, 82]]) objs[b[1] * N + b[0]] = 7;
			rooms.push(nave, wc, ec, wch, ech, sanct, altar);
			stageSpots = [[[72.5, 139.5], [128.5, 139.5]], [[100.5, 110.5]], [[100.5, 68.5]]];
			mobRooms = [{x: 100, y: 157, w: 13, h: 26, n: 11}, {x: 80, y: 160, w: 7, h: 7, n: 5}, {x: 120, y: 160, w: 7, h: 7, n: 5},
				{x: 74, y: 141, w: 10, h: 7, n: 3}, {x: 126, y: 141, w: 10, h: 7, n: 3}, {x: 100, y: 114, w: 15, h: 10, n: 6}];
		}

		/** A pool of blood (burns like lava). */
		private function pool(cx:int, cy:int, r:Number):void {
			for (var y:int = -2; y <= 2; y++) for (var x:int = -2; x <= 2; x++) {
				var i:int = (cy + y) * N + cx + x;
				if (x * x + y * y <= r * r && tiles[i] != VOID && tiles[i] != WALL && tiles[i] != CARPET) { tiles[i] = LAVA; objs[i] = 0; }
			}
		}

		/**
		 * Heart of the Storm: islands climbing through the clouds. Three pylon
		 * islands hold the Thunder Sentinels; when they fall a bridge forms to
		 * the Galecaller's terrace, then another to the eye of the storm.
		 */
		private function layoutSpire(th:Object):void {
			var F:int = th.floor, A:int = th.accent;
			var isl:Array = [[100, 184, 6], [100, 163, 6.5], [79, 150, 5.5], [121, 150, 5.5], [60, 128, 6.5], [100, 136, 6.5], [140, 128, 6.5]];
			for each (var d:Array in isl) blob(d[0], d[1], d[2], F);
			for each (var s:Array in [[100, 163], [79, 150], [121, 150]]) blob(s[0], s[1], 1.5, A);
			bridge(100, 184, 100, 163); bridge(100, 163, 79, 150); bridge(100, 163, 121, 150);
			bridge(79, 150, 60, 128); bridge(100, 163, 100, 136); bridge(121, 150, 140, 128);
			// pylons around each Sentinel
			for each (var py:Array in [[60, 128], [100, 136], [140, 128]])
				for each (var o:Array in [[-3, -3], [3, -3], [-3, 3], [3, 3]]) objs[(py[1] + o[1]) * N + py[0] + o[0]] = 8;
			// the Galecaller's terrace and the eye, joined by bridges that only form later
			blob(100, 104, 10.5, F);
			blob(100, 104, 2, A);
			blob(100, 66, 12, F);
			blob(100, 66, 4, PLAZA);
			for each (var e:Array in [[90, 58], [110, 58], [90, 74], [110, 74]]) objs[e[1] * N + e[0]] = 8;
			gateBridge(0, 100, 132, 100, 108);
			gateBridge(1, 100, 99, 100, 72);
			for each (d in isl) rooms.push({x: d[0], y: d[1], w: int(d[2] * 1.5), h: int(d[2] * 1.5)});
			rooms.push({x: 100, y: 104, w: 12, h: 12}, {x: 100, y: 66, w: 18, h: 18});
			stageSpots = [[[60.5, 127.5], [140.5, 127.5], [100.5, 135.5]], [[100.5, 104.5]], [[100.5, 64.5]]];
			mobRooms = [{x: 100, y: 163, w: 9, h: 9, n: 8}, {x: 79, y: 150, w: 7, h: 7, n: 5}, {x: 121, y: 150, w: 7, h: 7, n: 5},
				{x: 60, y: 128, w: 8, h: 8, n: 3}, {x: 140, y: 128, w: 8, h: 8, n: 3}, {x: 100, y: 136, w: 8, h: 8, n: 3}, {x: 100, y: 104, w: 11, h: 11, n: 6}];
		}

		/** A 2-wide bridge that is missing (open sky) until gate k opens. */
		private function gateBridge(k:int, x0:int, y0:int, x1:int, y1:int):void {
			while (gates.length <= k) gates.push([]);
			var steps:int = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0));
			for (var n:int = 0; n <= steps; n++) {
				var x:int = x0 + Math.round((x1 - x0) * n / steps), y:int = y0 + Math.round((y1 - y0) * n / steps);
				for (var oy:int = 0; oy < 2; oy++) for (var ox:int = 0; ox < 2; ox++) {
					var i:int = (y + oy) * N + x + ox;
					if (tiles[i] == VOID) gates[k].push({i: i, t: BRIDGE});
				}
			}
		}

		/** Opens raid gate k: the sealed cells become floor (and are redrawn). */
		public function openGate(k:int):Boolean {
			var list:Array = gates[k];
			if (!list || !list.length) return false;
			for each (var c:Object in list) {
				tiles[c.i] = c.t;
				zones[c.i] = DUNGEON_ZONE;
				var x:int = c.i % N, y:int = int(c.i / N);
				if (minimap) minimap.setPixel(x, y, MINI_COL[c.t]);
				for (var dy:int = -1; dy <= 1; dy++) for (var dx:int = -1; dx <= 1; dx++) dropChunk(int((x + dx) / CHUNK), int((y + dy) / CHUNK));
			}
			gates[k] = [];
			return true;
		}

		private function dropChunk(cx:int, cy:int):void {
			var k:int = cy * 1024 + cx;
			var bd:BitmapData = chunks[k];
			if (!bd) return;
			bd.dispose();
			delete chunks[k];
			chunkOrder.splice(chunkOrder.indexOf(k), 1);
		}

		/** A rough disc of floor. */
		private function blob(cx:int, cy:int, r:Number, t:int):void {
			var ri:int = Math.ceil(r) + 2;
			var wob:Array = [];
			for (var k:int = 0; k < 12; k++) wob.push(0.82 + rnd() * 0.3);
			for (var y:int = -ri; y <= ri; y++) {
				for (var x:int = -ri; x <= ri; x++) {
					var a:Number = Math.atan2(y, x);
					var f:Number = wob[int((a + Math.PI) / (Math.PI * 2) * 12) % 12];
					if (x * x + y * y <= r * r * f * f) carve(cx + x, cy + y, 1, 1, t);
				}
			}
		}

		/** A winding 3-wide tunnel. */
		private function tunnel(x0:int, y0:int, x1:int, y1:int, t:int):void {
			var x:Number = x0, y:Number = y0;
			for (var n:int = 0; n < 400; n++) {
				carve(int(x) - 1, int(y) - 1, 3, 3, t);
				var dx:Number = x1 - x, dy:Number = y1 - y;
				var d:Number = Math.sqrt(dx * dx + dy * dy);
				if (d < 1.5) break;
				var a:Number = Math.atan2(dy, dx) + (rnd() - 0.5) * 1.4;
				x += Math.cos(a); y += Math.sin(a);
			}
		}

		/** A 2-wide bridge over the abyss. */
		private function bridge(x0:int, y0:int, x1:int, y1:int):void {
			var steps:int = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0));
			for (var k:int = 0; k <= steps; k++) {
				var x:int = x0 + Math.round((x1 - x0) * k / steps), y:int = y0 + Math.round((y1 - y0) * k / steps);
				for (var oy:int = 0; oy < 2; oy++) for (var ox:int = 0; ox < 2; ox++) {
					var i:int = (y + oy) * N + x + ox;
					if (tiles[i] == VOID) { tiles[i] = BRIDGE; zones[i] = DUNGEON_ZONE; }
				}
			}
		}

		/** A curved passage along the ring between two chambers. */
		private function arc(x0:int, y0:int, x1:int, y1:int, cx:int, cy:int, t:int):void {
			var a0:Number = Math.atan2(y0 - cy, x0 - cx), a1:Number = Math.atan2(y1 - cy, x1 - cx);
			while (a1 < a0) a1 += Math.PI * 2;
			var R:Number = Math.sqrt((x0 - cx) * (x0 - cx) + (y0 - cy) * (y0 - cy));
			for (var a:Number = a0; a <= a1; a += 0.02) carve(cx + int(Math.cos(a) * R) - 1, cy + int(Math.sin(a) * R) - 1, 3, 3, t);
		}

		/** Lava pools or flooded patches in the middle rooms. */
		private function addHazards(kind:String):void {
			var t:int = kind == "lava" ? LAVA : WATER;
			for (var k:int = 1; k < rooms.length - 1; k++) {
				var rm:Object = rooms[k];
				if (rnd() < 0.35 || rm.w < 6) continue;
				var n:int = 1 + int(rnd() * 2);
				for (var j:int = 0; j < n; j++) {
					var px:int = rm.x + int((rnd() - 0.5) * (rm.w - 4)), py:int = rm.y + int((rnd() - 0.5) * (rm.h - 4));
					var r:Number = 1.2 + rnd() * 1.4;
					for (var y:int = -2; y <= 2; y++) for (var x:int = -2; x <= 2; x++) {
						var i:int = (py + y) * N + px + x;
						if (x * x + y * y <= r * r && tiles[i] != VOID && tiles[i] != WALL && tiles[i] != BRIDGE) tiles[i] = t;
					}
				}
			}
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
		/** A boss arena drawn in the Map Builder: {w, h, tiles, objs, spawn: [x, y], boss: [x, y]}. */
		public static var customMap:Object;
		/** Where the custom map's top-left corner lands in the world. */
		public var mapX:int = 0, mapY:int = 0;

		private function generateCustom():void {
			var m:Object = customMap;
			var i:int;
			for (i = 0; i < N * N; i++) { tiles[i] = VOID; zones[i] = -1; objs[i] = 0; }
			mapX = int((N - m.w) / 2);
			mapY = int((N - m.h) / 2);
			for (var y:int = 0; y < m.h; y++) {
				for (var x:int = 0; x < m.w; x++) {
					var t:int = int(m.tiles[y * m.w + x]);
					i = (mapY + y) * N + mapX + x;
					tiles[i] = t;
					objs[i] = int(m.objs[y * m.w + x]);
					zones[i] = t == VOID ? -1 : ARENA_ZONE;
				}
			}
			spawnX = mapX + m.spawn[0] + 0.5;
			spawnY = mapY + m.spawn[1] + 0.5;
		}

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
			var count:int = kind == "realm" ? int(30 * (N / 320) * (N / 320)) : 26;
			for (var k:int = 0; k < count; k++) {
				var cx:int = 0, cy:int = 0, z:int = -1;
				for (var tries:int = 0; tries < 50; tries++) {
					cx = 20 + int(rnd() * (N - 40));
					cy = 20 + int(rnd() * (N - 40));
					z = zones[cy * N + cx];
					if (z >= MID_ZONE && z <= GOD_ZONE) break;
				}
				if (z < MID_ZONE || z > GOD_ZONE) continue;
				var rw:int = 3 + int(rnd() * 5), rh:int = 3 + int(rnd() * 5);
				var lavaDir:int = rnd() < 0.5 ? 1 : -1;
				var lava:Boolean = z == GOD_ZONE && rnd() < 0.75;
				for (var y:int = cy - rh - 1; y <= cy + rh + 1; y++) {
					for (var x:int = cx - rw - 1; x <= cx + rw + 1; x++) {
						var nx:Number = (x - cx) / rw, ny:Number = (y - cy) / rh;
						// blocky, stair-stepped outline like RotMG ruins
						var edge:Number = nx * nx + ny * ny + (rnd() - 0.5) * 0.25;
						if (edge > 1) continue;
						var i:int = y * N + x;
						if (tiles[i] == WATER || tiles[i] == ROAD || tiles[i] == BRIDGE) continue;
						objs[i] = 0;
						var diag:Number = Math.abs((x - cx) - lavaDir * (y - cy));
						tiles[i] = lava && diag < 1.6 ? LAVA : RUIN;
						// broken walls around the rim, pillars at the corners
						if (edge > 0.72 && tiles[i] == RUIN && rnd() < 0.3) objs[i] = 9;
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
			trng = uint(tx * 73856093 ^ ty * 19349663 ^ t * 83492791) | 1;
			for (y = 0; y < PX; y++) {
				for (x = 0; x < PX; x++) {
					i = y * PX + x;
					trng ^= trng << 13; trng ^= trng >>> 17; trng ^= trng << 5;
					r = (trng >>> 0) / 4294967296;
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

		/** Builds the minimap; the ground itself is drawn chunk by chunk in drawGround. */
		private function render():void {
			minimap = new BitmapData(N, N, false, 0);
			minimap.lock();
			for (var y:int = 0; y < N; y++) {
				for (var x:int = 0; x < N; x++) {
					var i:int = y * N + x;
					var mc:uint = MINI_COL[tiles[i]];
					if (objs[i] == 1 || objs[i] == 2) mc = 0x1e4a18;
					else if (objs[i] == 4 || objs[i] == 5) mc = 0x7a7a7a;
					minimap.setPixel(x, y, mc);
				}
			}
			minimap.unlock();
		}

		private function chunk(cx:int, cy:int):BitmapData {
			var k:int = cy * 1024 + cx;
			var bd:BitmapData = chunks[k];
			if (bd) {
				var at:int = chunkOrder.indexOf(k);
				if (at < chunkOrder.length - 1) { chunkOrder.splice(at, 1); chunkOrder.push(k); }
				return bd;
			}
			while (chunkOrder.length >= MAX_CHUNKS) {
				var old:int = chunkOrder.shift();
				BitmapData(chunks[old]).dispose();
				delete chunks[old];
			}
			bd = new BitmapData(CHUNK * PX, CHUNK * PX, false, 0);
			target = bd;
			offX = cx * CHUNK * PX;
			offY = cy * CHUNK * PX;
			var r:Rectangle = new Rectangle(0, 0, PX, PX);
			bd.lock();
			var x1:int = Math.min(N, (cx + 1) * CHUNK), y1:int = Math.min(N, (cy + 1) * CHUNK);
			for (var y:int = cy * CHUNK; y < y1; y++) {
				for (var x:int = cx * CHUNK; x < x1; x++) {
					var t:int = tiles[y * N + x];
					r.x = x * PX - offX;
					r.y = y * PX - offY;
					bd.setVector(r, texture(t, x, y));
					drawEdges(x, y, t);
				}
			}
			bd.unlock();
			target = null;
			chunks[k] = bd;
			chunkOrder.push(k);
			return bd;
		}

		/**
		 * Draws the ground within `reach` tiles of (vx, vy) into `out`. mtx maps
		 * ground pixels (8 per tile) to the screen, rotation and zoom included.
		 */
		public function drawGround(out:BitmapData, mtx:Matrix, vx:Number, vy:Number, reach:Number):void {
			var c0:int = Math.max(0, int((vx - reach) / CHUNK)), c1:int = Math.min(int((N - 1) / CHUNK), int((vx + reach) / CHUNK));
			var r0:int = Math.max(0, int((vy - reach) / CHUNK)), r1:int = Math.min(int((N - 1) / CHUNK), int((vy + reach) / CHUNK));
			for (var cy:int = r0; cy <= r1; cy++) {
				for (var cx:int = c0; cx <= c1; cx++) {
					drawMtx.identity();
					drawMtx.translate(cx * CHUNK * PX, cy * CHUNK * PX);
					drawMtx.concat(mtx);
					out.draw(chunk(cx, cy), drawMtx, null, null, null, false);
				}
			}
		}

		/** Frees the rendered ground (it is redrawn when you come back). */
		public function releaseGround():void {
			for each (var bd:BitmapData in chunks) bd.dispose();
			chunks = {};
			chunkOrder = [];
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
			var px:int = x * PX - offX, py:int = y * PX - offY;
			var bitmap:BitmapData = target;
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

		/** Walls stop every shot, yours and the monsters' (trees and rocks don't). */
		public function blocksShot(x:Number, y:Number):Boolean {
			if (x < 0 || y < 0 || x >= N || y >= N) return true;
			var t:int = tiles[int(y) * N + int(x)];
			return t == WALL || t == VOID;
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
