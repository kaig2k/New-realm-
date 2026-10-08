package realm {
	/**
	 * Realm event set pieces: real structures laid into the map round an event
	 * boss when it appears (floors, walls, pillars, lava, water), and taken away
	 * again when it dies. The server lays them down too, so walls stop shots and
	 * bodies for everyone.
	 *
	 * Layouts are 21 x 21, centred on the boss:
	 *   ' ' leave the ground as it is     '-' ragged edge (floor on some tiles)
	 *   '.' floor   ',' second floor   ':' trim   '~' hazard (lava or water)
	 *   '#' wall    a b c  decorations (they block walking, not shots)
	 *   P  where a set-piece piece stands (ward, mender or hazard)
	 *   B  the boss
	 */
	public class SetPieces {
		public static const SIZE:int = 21;
		public static const HALF:int = 10;

		/** Decorations only set pieces use (World.OBJ_NAMES 20+). */
		public static const OBJ_FIRST:int = 20;

		/** Per style: tiles for . , : ~ and objects for a b c. */
		public static const STYLES:Object = {
			cube: {floor: World.METAL, alt: World.STONE, trim: World.FOUNTAIN, hz: World.FOUNTAIN, a: 20, b: 20, c: 20},
			lava: {floor: World.ASH, alt: World.OBSIDIAN, trim: World.LAVA, hz: World.LAVA, a: 7, b: 5, c: 4},
			frost: {floor: World.ICE, alt: World.PLAZA, trim: World.ICE, hz: World.WATER, a: 21, b: 22, c: 21},
			throne: {floor: World.PLAZA, alt: World.CARPET, trim: World.GOLD, hz: World.GOLD, a: 23, b: 19, c: 7},
			bone: {floor: World.SAND, alt: World.BONE, trim: World.BONE, hz: World.BONE, a: 13, b: 10, c: 12},
			ghost: {floor: World.SPECTRAL, alt: World.STONE, trim: World.STONE, hz: World.SPECTRAL, a: 11, b: 25, c: 24},
			sand: {floor: World.SANDSTONE, alt: World.SAND, trim: World.GOLD, hz: World.GOLD, a: 26, b: 3, c: 26},
			sunken: {floor: World.REEF, alt: World.RUIN, trim: World.RUIN, hz: World.WATER, a: 8, b: 27, c: 8},
			shell: {floor: World.SAND, alt: World.REEF, trim: World.REEF, hz: World.WATER, a: 3, b: 3, c: 28},
			skull: {floor: World.BONE, alt: World.BLOODSTONE, trim: World.BLOODSTONE, hz: World.BLOODSTONE, a: 29, b: 30, c: 11},
			obsidian: {floor: World.OBSIDIAN, alt: World.GOD, trim: World.LAVA, hz: World.LAVA, a: 31, b: 5, c: 4},
			fire: {floor: World.ASH, alt: World.BRICK, trim: World.LAVA, hz: World.LAVA, a: 7, b: 6, c: 7},
			hex: {floor: World.HEXSTONE, alt: World.DARK, trim: World.HEXSTONE, hz: World.HEXSTONE, a: 32, b: 6, c: 33},
			reef: {floor: World.REEF, alt: World.SAND, trim: World.SAND, hz: World.WATER, a: 27, b: 27, c: 4}
		};

		public static const LAYOUTS:Object = {
			cube: [
				"                     ",
				"    -------------    ",
				"  --.............--  ",
				"  -##.,,,,,,,,,.##-  ",
				" -.#a.,.......,.a#.- ",
				" -..,P,...:...,P,..- ",
				" -.,,,,...:...,,,,.- ",
				" -.,......:......,.- ",
				" -.,......:......,.- ",
				" -.,......,......,.- ",
				" -.,::::,,B,,::::,.- ",
				" -.,......,......,.- ",
				" -.,......:......,.- ",
				" -.,......:......,.- ",
				" -.,,,,...:...,,,,.- ",
				" -..,P,...:...,P,..- ",
				" -.#a.,.......,.a#.- ",
				"  -##.,,,,,,,,,.##-  ",
				"  --.............--  ",
				"    -------------    ",
				"                     "],
			lava: [
				"      ---------      ",
				"   ---.........---   ",
				"  -~~.....-.....~~-  ",
				"  -~~~..b...b..~~~-  ",
				" -..~~~.......~~~..- ",
				" -..,~P~.....~P~,..- ",
				" -.b..~~,...,~~..b.- ",
				" -.....~,...,~.....- ",
				" -.a.,,,.....,,,.a.- ",
				" -.....,.....,.....- ",
				" -..,.....B.....,..- ",
				" -.....,.....,.....- ",
				" -.a.,,,.....,,,.a.- ",
				" -.....~,...,~.....- ",
				" -.b..~~,...,~~..b.- ",
				" -..,~P~.....~P~,..- ",
				" -..~~~.......~~~..- ",
				"  -~~~..b...b..~~~-  ",
				"  -~~.....-.....~~-  ",
				"   ---.........---   ",
				"      ---------      "],
			frost: [
				"       -------       ",
				"     --.......--     ",
				"    -.....,.....-    ",
				"   -.b.,,,,,,,.b.-   ",
				"  -....,,.P.,,....-  ",
				"  -.a..,,,,,,,..a.-  ",
				" -.................- ",
				" -.b.............b.- ",
				" -.................- ",
				"-....,.........,....-",
				"-...,,,...B...,,,...-",
				"-....,.........,....-",
				"-...................-",
				" -.................- ",
				" -..,P,.......,P,..- ",
				" -..,,,.......,,,..- ",
				"  -.b...........b.-  ",
				"  -......a.a......-  ",
				"   -.............-   ",
				"    --.........--    ",
				"      ---------      "],
			throne: [
				"                     ",
				"  -----------------  ",
				" -#######...#######- ",
				" -#b.a.........a.b#- ",
				" -#.......:.......#- ",
				" -#..,P,..:..,P,..#- ",
				" -#.......:.......#- ",
				" -#a......:......a#- ",
				" -........:........- ",
				" -........:........- ",
				" -.:::::::B:::::::.- ",
				" -........:........- ",
				" -........:........- ",
				" -#a......:......a#- ",
				" -#.......:.......#- ",
				" -#..,P,..:..,P,..#- ",
				" -#.......:.......#- ",
				" -#b.a.........a.b#- ",
				" -#######...#######- ",
				"  -----------------  ",
				"                     "],
			bone: [
				"       -------       ",
				"     --,,,,,,,--     ",
				"    -,,,,,,,,,,,-    ",
				"   -,b,,c,.,c,,b,-   ",
				"  -,,,,...P...,,,,-  ",
				"  -,,,.........,,,-  ",
				" -,c,...........,c,- ",
				" -,,.............,,- ",
				" -,...............,- ",
				"-,,...............,,-",
				"-,a.......B.......a,-",
				"-,,...............,,-",
				"-,b...............b,-",
				" -,...............,- ",
				" -,,.P.........P.,,- ",
				" -,,,...........,,,- ",
				"  -,c,,.......,,c,-  ",
				"  -,,,,,,a,a,,,,,,-  ",
				"   -,,,,,,,,,,,,,-   ",
				"    --,,,,,,,,,--    ",
				"      ---------      "],
			ghost: [
				"     -----------     ",
				"   --...........--   ",
				"  -..a.........a..-  ",
				"  -.b....a.a....b.-  ",
				" -........,........- ",
				" -..a,P,.....,P,a..- ",
				" -.....,.....,.....- ",
				" -...a.........a...- ",
				" -.b.............b.- ",
				" -.................- ",
				" -,,,,,,,,B,,,,,,,,- ",
				" -.................- ",
				" -.b.............b.- ",
				" -...a.........a...- ",
				" -.....,.....,.....- ",
				" -..a,P,.....,P,a..- ",
				" -........,........- ",
				"  -.b....a.a....b.-  ",
				"  -..a.........a..-  ",
				"   --...........--   ",
				"     -----------     "],
			sand: [
				"                     ",
				"  -----------------  ",
				" -,,,,,,,,,,,,,,,,,- ",
				" -,a..a..a.a..a..a,- ",
				" -,.......:.......,- ",
				" -,a..P...:...P..a,- ",
				" -,.......:.......,- ",
				" -,a......:......a,- ",
				" -,......:::......,- ",
				" -,.......:.......,- ",
				" -,.::::::B::::::.,- ",
				" -,.......:.......,- ",
				" -,......:::......,- ",
				" -,a......:......a,- ",
				" -,.......:.......,- ",
				" -,a..P...:...P..a,- ",
				" -,.......:.......,- ",
				" -,a..a..a.a..a..a,- ",
				" -,,,,,,,,,,,,,,,,,- ",
				"  -----------------  ",
				"                     "],
			sunken: [
				"       ~~~~~~~       ",
				"     ~~-.....-~~     ",
				"    ~-.........-~    ",
				"   ~-.a.,,,,,.a.-~   ",
				"  ~-..,,,,P,,,,..-~  ",
				"  ~-..,,,,,,,,,..-~  ",
				" ~-.~~.........~~.-~ ",
				" ~-.~~.........~~.-~ ",
				" ~-...............-~ ",
				"~-....,.......,....-~",
				"~-.b..,...B...,..b.-~",
				"~-....,.......,....-~",
				"~-.................-~",
				" ~-...............-~ ",
				" ~-.,,P,.....,P,,.-~ ",
				" ~-.,,,~~...~~,,,.-~ ",
				"  ~-.a.~~...~~.a.-~  ",
				"  ~-.............-~  ",
				"   ~-.....b.....-~   ",
				"    ~~-.......-~~    ",
				"      ~~~~~~~~~      "],
			shell: [
				"      ---------      ",
				"    --,,,,,,,,,--    ",
				"  --,,,,,,,,,,,,,--  ",
				"  -,b,,,,...,,,,b,-  ",
				" -,,,c....~....c,,,- ",
				" -,,,.P..~~~..P.,,,- ",
				" -,,....~~.~~....,,- ",
				" -,,...~~...~~...,,- ",
				" -,,..~~.....~~..,,- ",
				" -,..~~.......~~..,- ",
				" -,..~....B....~..,- ",
				" -,..~~.......~~..,- ",
				" -,,..~~.....~~..,,- ",
				" -,,...~~...~~...,,- ",
				" -,,....~~.~~....,,- ",
				" -,,,.P..~~~..P.,,,- ",
				" -,,,c....~....c,,,- ",
				"  -,b,,,,...,,,,b,-  ",
				"  --,,,,,,,,,,,,,--  ",
				"    --,,,,,,,,,--    ",
				"      ---------      "],
			skull: [
				"                     ",
				"  -----------------  ",
				" -##.a.a.###.a.a.##- ",
				" -#...............#- ",
				" -....,,,,,,,,,....- ",
				" -a..,P,..:..,P,..a- ",
				" -...,,...:...,,...- ",
				" -a..,....:....,..a- ",
				" -...,....:....,...- ",
				" -#..,....:....,..#- ",
				" -#..,::::B::::,..#- ",
				" -#..,....:....,..#- ",
				" -...,....:....,...- ",
				" -a..,....:....,..a- ",
				" -...,,...:...,,...- ",
				" -a..,P,..:..,P,..a- ",
				" -....,,,,,,,,,....- ",
				" -#...............#- ",
				" -##.a.a.###.a.a.##- ",
				"  -----------------  ",
				"                     "],
			obsidian: [
				"      ---------      ",
				"   ---,,,,,,,,,---   ",
				"  -,,b,,,...,,,b,,-  ",
				"  -,~~,.......,~~,-  ",
				" -,,~~~.......~~~,,- ",
				" -,,,~P,.....,P~,,,- ",
				" -,a,.,,.....,,.,a,- ",
				" -,,......~......,,- ",
				" -,.......~.......,- ",
				" -,...............,- ",
				" -,...~~..B..~~...,- ",
				" -,...............,- ",
				" -,.......~.......,- ",
				" -,,......~......,,- ",
				" -,a,.,,.....,,.,a,- ",
				" -,,,~P,.....,P~,,,- ",
				" -,,~~~.......~~~,,- ",
				"  -,~~,.......,~~,-  ",
				"  -,,b,,,...,,,b,,-  ",
				"   ---,,,,,,,,,---   ",
				"      ---------      "],
			fire: [
				"       -------       ",
				"     --,,,,,,,--     ",
				"    -,,b,,,,,b,,-    ",
				"   -,,,..,,,..,,,-   ",
				"  -,~~..,,P,,..~~,-  ",
				"  -,~~...,,,...~~,-  ",
				" -,,......~......,,- ",
				" -,.......~.......,- ",
				" -,a.............a,- ",
				"-,,...............,,-",
				"-,,.......B.......,,-",
				"-,,...............,,-",
				"-,a.......~.......a,-",
				" -,.......~.......,- ",
				" -,,.P.........P.,,- ",
				" -,~~...........~~,- ",
				"  -~~,.........,~~-  ",
				"  -,b,,.......,,b,-  ",
				"   -,,,,,,,,,,,,,-   ",
				"    --,,,,,,,,,--    ",
				"      ---------      "],
			hex: [
				"     -----------     ",
				"   --,,,,,,,,,,,--   ",
				"  -,,b,,.....,,b,,-  ",
				"  -,b,.........,b,-  ",
				" -,,..:.......:..,,- ",
				" -,..:P:.....:P:..,- ",
				" -,...:.......:...,- ",
				" -,a.............a,- ",
				" -,...............,- ",
				" -,......:::......,- ",
				" -,......:B:......,- ",
				" -,......:::......,- ",
				" -,...............,- ",
				" -,a.............a,- ",
				" -,...:.......:...,- ",
				" -,..:P:.....:P:..,- ",
				" -,,..:.......:..,,- ",
				"  -,b,.........,b,-  ",
				"  -,,b,,.....,,b,,-  ",
				"   --,,,,,,,,,,,--   ",
				"     -----------     "],
			reef: [
				"     ~~~~~~~~~~~     ",
				"   ~~~----~----~~~   ",
				"  ~~-,,,,,-,,,,,-~~  ",
				"  ~-,b,,.....,,b,-~  ",
				" ~-,,,.........,,,-~ ",
				" ~-,,.P.......P.,,-~ ",
				" ~-,...~.....~...,-~ ",
				" ~-,..~~.....~~..,-~ ",
				" ~-,.............,-~ ",
				" ~-,.............,-~ ",
				" ~-,......B......,-~ ",
				" ~-,.............,-~ ",
				" ~-,.............,-~ ",
				" ~-,..~~.....~~..,-~ ",
				" ~-,...~.....~...,-~ ",
				" ~-,,.P.......P.,,-~ ",
				" ~-,,,.........,,,-~ ",
				"  ~-,b,,.....,,b,-~  ",
				"  ~~-,,,,,-,,,,,-~~  ",
				"   ~~~----~----~~~   ",
				"     ~~~~~~~~~~~     "]
		};

		/** The layout for an event boss, or null. */
		public static function layoutOf(id:String):Array {
			var sp:Object = Bosses.SETPIECES[id];
			return sp ? LAYOUTS[sp.style] : null;
		}

		/** True if the set piece can go down with its centre on tile (cx, cy): on land, clear of the haven, shrines and landmarks. */
		public static function fits(id:String, w:World, cx:int, cy:int):Boolean {
			var rows:Array = layoutOf(id);
			if (!rows) return true;
			if (w.siteAt(cx + 0.5, cy + 0.5, HALF + 1)) return false;
			var sea:int = 0, total:int = 0;
			for (var r:int = 0; r < SIZE; r++) {
				var row:String = rows[r];
				for (var c:int = 0; c < SIZE; c++) {
					if (row.charAt(c) == " ") continue;
					var x:int = cx - HALF + c, y:int = cy - HALF + r;
					if (x < 3 || y < 3 || x >= w.N - 3 || y >= w.N - 3) return false;
					var i:int = y * w.N + x;
					var t:int = w.tiles[i], z:int = w.zones[i], o:int = w.objs[i];
					if (t == World.VOID || t == World.WALL || z == World.SAFE_ZONE || z == World.NEXUS_ZONE) return false;
					if (o >= 14 && o <= 18) return false;
					total++;
					if (t == World.WATER && z < 0) sea++;
				}
			}
			return sea * 10 < total;
		}

		/**
		 * The tiles the set piece changes: {i, x, y, t, o, nt, no, d} where t/o are
		 * what was there, nt/no what goes down and d the distance from the centre.
		 */
		public static function plan(id:String, w:World, cx:int, cy:int):Array {
			var out:Array = [];
			var rows:Array = layoutOf(id);
			if (!rows) return out;
			var st:Object = STYLES[Bosses.SETPIECES[id].style];
			for (var r:int = 0; r < SIZE; r++) {
				var row:String = rows[r];
				for (var c:int = 0; c < SIZE; c++) {
					var ch:String = row.charAt(c);
					if (ch == " ") continue;
					// ragged edge: the same tiles every time, so the server and every player agree
					if (ch == "-" && (c * 7 + r * 13) % 10 >= 6) continue;
					var x:int = cx - HALF + c, y:int = cy - HALF + r;
					if (x < 1 || y < 1 || x >= w.N - 1 || y >= w.N - 1) continue;
					var i:int = y * w.N + x;
					var nt:int = st.floor, no:int = 0;
					if (ch == ",") nt = st.alt;
					else if (ch == ":") nt = st.trim;
					else if (ch == "~") nt = st.hz;
					else if (ch == "#") nt = World.WALL;
					else if (ch == "a") no = st.a;
					else if (ch == "b") no = st.b;
					else if (ch == "c") no = st.c;
					var dx:int = c - HALF, dy:int = r - HALF;
					out.push({i: i, x: x, y: y, t: w.tiles[i], o: w.objs[i], nt: nt, no: no, d: Math.sqrt(dx * dx + dy * dy), on: false});
				}
			}
			return out;
		}

		/** Lays down the planned tiles within `upto` of the centre (all of them by default). Returns how many changed. */
		public static function apply(w:World, cells:Array, upto:Number = 99):int {
			var n:int = 0;
			for each (var k:Object in cells) {
				if (k.on || k.d > upto) continue;
				k.on = true;
				w.tiles[k.i] = k.nt;
				w.objs[k.i] = k.no;
				n++;
			}
			return n;
		}

		/** Puts the ground back as it was, from `from` outwards (all of it by default). Returns how many changed. */
		public static function undo(w:World, cells:Array, from:Number = 0):int {
			var n:int = 0;
			for each (var k:Object in cells) {
				if (!k.on || k.d < from) continue;
				k.on = false;
				w.tiles[k.i] = k.t;
				w.objs[k.i] = k.o;
				n++;
			}
			return n;
		}

		/** Where the set-piece pieces stand (centre of each P tile). */
		public static function spots(id:String, cx:int, cy:int):Array {
			var out:Array = [];
			var rows:Array = layoutOf(id);
			if (!rows) return out;
			var prop:String = Bosses.SETPIECES[id].prop;
			for (var r:int = 0; r < SIZE; r++) {
				var row:String = rows[r];
				for (var c:int = 0; c < SIZE; c++) if (row.charAt(c) == "P") out.push({what: prop, x: cx - HALF + c + 0.5, y: cy - HALF + r + 0.5});
			}
			return out;
		}

		/** The decorations' pictures (the game's only). */
		public static function art():void {
			Sprites.recolor("sp_crystal_cube", "crystal", {W: 0xffe0ff, C: 0xc050ff, c: 0x7020b0, D: 0x3a1060, S: 0x283050}, 6);
			Sprites.recolor("sp_spike_ice", "crystal", {W: 0xffffff, C: 0xc8ecff, c: 0x80c0f0, D: 0x4a88c0, S: 0x9ccbe8}, 6);
			Sprites.recolor("sp_pillar_ice", "pillar", {L: 0xe8f8ff, l: 0x8ac0e0, S: 0xc0e4f8, s: 0x7aa8cc});
			Sprites.recolor("sp_pillar_gold", "pillar", {L: 0xfff0a0, l: 0xb88e24, S: 0xf0cc50, s: 0x9a7418});
			Sprites.recolor("sp_pillar_dark", "pillar", {L: 0x8a88b8, l: 0x3a3862, S: 0x5a5888, s: 0x2a2850});
			Sprites.recolor("sp_brazier_blue", "brazier", {Y: 0xe0f0ff, F: 0x6090ff, W: 0xffffff, S: 0x4a4a6a, s: 0x2a2a44});
			Sprites.recolor("sp_pillar_sand", "pillar", {L: 0xf8e0a8, l: 0xa47c48, S: 0xe0c088, s: 0x8a6a3c});
			Sprites.recolor("sp_coral", "crystal", {W: 0xffe0e8, C: 0xff7090, c: 0xd04060, D: 0x902040, S: 0x3c968c}, 6);
			Sprites.recolor("sp_shell", "nest", {W: 0xfff0f4, w: 0xffb0c0, S: 0xffe080, K: 0xe8c0c8, k: 0xb08890}, 5);
			Sprites.recolor("sp_skull", "skull", {W: 0xece4cc, E: 0x4a0a0a}, 5);
			Sprites.recolor("sp_brazier_purple", "brazier", {Y: 0xf0c0ff, F: 0xb060ff, W: 0xffffff, S: 0xd8ceb0, s: 0x8a8068});
			Sprites.recolor("sp_spire", "crystal", {W: 0xffa060, C: 0x3a2a40, c: 0x221a28, D: 0x100a12, S: 0x221a28}, 7);
			Sprites.recolor("sp_brazier_green", "brazier", {Y: 0xe0ffc0, F: 0x70e050, W: 0xffffff, S: 0x4a3256, s: 0x2a1c30});
			Sprites.recolor("sp_banner_hex", "banner", {S: 0x6a5a40, s: 0x3a3020, R: 0x4a2a6a, Y: 0x70e050});
		}
	}
}
