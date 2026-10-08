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
			reef: {floor: World.REEF, alt: World.SAND, trim: World.SAND, hz: World.WATER, a: 27, b: 27, c: 4},
			star: {floor: World.SPECTRAL, alt: World.OBSIDIAN, trim: World.GOLD, hz: World.LAVA, a: 23, b: 7, c: 23}
		};

		public static const LAYOUTS:Object = {
			star: [
				"                     ",
				"  -----------------  ",
				" -####....:....####- ",
				" -#a,,,,,,,,,,,,,a#- ",
				" -#,,...........,,#- ",
				" -.,.P.~.....~.P.,.- ",
				" -.,...~.....~...,.- ",
				" -.,.~~~..:..~~~.,.- ",
				" -.,......:......,.- ",
				" -..b.....:.....b..- ",
				" -.,,:::::B:::::,,.- ",
				" -..b.....:.....b..- ",
				" -.,......:......,.- ",
				" -.,.~~~..:..~~~.,.- ",
				" -.,...~.....~...,.- ",
				" -.,.P.~.....~.P.,.- ",
				" -#,,...........,,#- ",
				" -#a,,,,,,,,,,,,,a#- ",
				" -####....:....####- ",
				"  -----------------  ",
				"                     "],
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
					out.push({i: i, x: x, y: y, t: w.tiles[i], o: w.objs[i], nt: nt, no: no, d: Math.sqrt(dx * dx + dy * dy), on: false, ch: ch, c: c, r: r});
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

		// ------------------------------------------------------------ phases
		/** Seconds the floor flashes before a phase changes the arena. */
		public static const WARN:Number = 2.5;
		/** A phase starts at 30% health ("low"), below its own health fraction ("hp", at), or once every set-piece piece is broken ("broken"). */
		public static const LOW:Number = 0.3;

		/**
		 * How each arena changes during the fight. when: "broken" or "low".
		 * sel picks the tiles: walls ('#'), widen (next to the hazard), ring (a <= distance < b,
		 * plus any tiles marked in chars), char (tiles marked ch). to: floor, hz (the style's
		 * hazard), water or hexfire; objects on those tiles go. spawn/n: monsters that come
		 * out of the changed tiles. col: the warning flash. msg: told to everyone.
		 */
		public static const PHASES:Object = {
			cube: [{when: "broken", sel: "walls", to: "floor", spawn: "cube_shard", n: 4, col: 0xff60ff,
				msg: "The pylons fall and the Cube's walls collapse! Cubelets pour through the gaps!"}],
			lava: [{when: "low", sel: "widen", to: "hz", col: 0xff5010,
				msg: "Vorgath roars and the lava channels spill over!"}],
			frost: [{when: "low", sel: "ring", a: 7.5, b: 99, to: "water", col: 0x9ad8ff,
				msg: "The ice cracks! The edge of the court gives way to freezing water."}],
			throne: [{when: "broken", sel: "walls", to: "floor", spawn: "royal_guard", n: 4, col: 0xffd060,
				msg: "The effigies topple and the throne room's walls crumble! The King's guard storms in!"}],
			bone: [{when: "low", sel: "char", ch: "b", to: "floor", spawn: "war_orc", n: 3, col: 0xff6040,
				msg: "Gorehorn bellows for his warband! Orcs burst out of the tents!"}],
			ghost: [{when: "broken", sel: "char", ch: "a", to: "floor", spawn: "grave_wraith", n: 4, col: 0x90c0ff,
				msg: "The candles die and the graves split open! The Regent's dead rise!"}],
			sand: [{when: "low", sel: "char", ch: "a", to: "floor", spawn: "temple_scorpion", n: 4, col: 0xffe080,
				msg: "The temple pillars topple! Scorpions swarm from the rubble!"}],
			sunken: [{when: "low", sel: "ring", a: 6.5, b: 99, to: "water", col: 0x40d0c0,
				msg: "The Lord calls the sea home! The water floods in from every side!"}],
			shell: [{when: "low", sel: "char", ch: ",", to: "water", col: 0x60c0ff,
				msg: "The tide comes in! The reef sinks under the waves."}],
			skull: [{when: "broken", sel: "walls", to: "floor", spawn: "bone_thrall", n: 4, col: 0xb060ff,
				msg: "The braziers gutter out and the shrine's walls fall! Bone thralls claw their way in!"},
				{when: "low", sel: "char", ch: ",", to: "hz", col: 0xff3030,
				msg: "The blood in the shrine's floor begins to boil!"}],
			obsidian: [{when: "low", sel: "widen", to: "hz", col: 0xff7030,
				msg: "The Colossus cracks the ground open! Lava wells up between the plates!"}],
			fire: [{when: "low", sel: "char", ch: ",", to: "hz", col: 0xffa040,
				msg: "Pyraxis sets the nest ablaze! A ring of fire closes around the arena!"}],
			hex: [{when: "low", sel: "ring", a: 4.5, b: 5.6, chars: ":", to: "hexfire", col: 0x70e050,
				msg: "Mother Hexis speaks the last words! The runes burn anyone standing on them!"}],
			reef: [{when: "low", sel: "ring", a: 6.5, b: 99, to: "water", col: 0x40a0ff,
				msg: "The Kraken drags the reef under! The water floods inward!"}],
			// the Star Throne changes three times as Astraeon weakens
			star: [{when: "hp", at: 0.75, sel: "walls", to: "floor", spawn: "star_guard", n: 4, col: 0xffd060,
				msg: "The throne room's walls shatter! Star Guards pour in!"},
				{when: "hp", at: 0.5, sel: "ring", a: 4.5, b: 6.5, to: "hz", col: 0xffb040,
				msg: "A ring of starfire ignites around Astraeon!"},
				{when: "hp", at: 0.25, sel: "ring", a: 8.5, b: 99, to: "hz", col: 0xff6020,
				msg: "The edges of the throne burn away! Stay close to the fallen star!"}]
		};

		/** The phases of an event boss's arena (may be empty). */
		public static function phasesOf(id:String):Array {
			var sp:Object = Bosses.SETPIECES[id];
			return sp && PHASES[sp.style] ? PHASES[sp.style] : [];
		}

		/** The phase that should start now for boss e (mask = phases done or under way), or -1. */
		public static function trigger(e:Enemy, mask:int):int {
			var ph:Array = phasesOf(e.defId);
			for (var k:int = 0; k < ph.length; k++) {
				if (mask & (1 << k)) continue;
				if (ph[k].when == "low" && e.hp > 0 && e.hp < e.maxHp * LOW) return k;
				if (ph[k].when == "hp" && e.hp > 0 && e.hp < e.maxHp * ph[k].at) return k;
				if (ph[k].when == "broken" && e.props && e.props.length) {
					var left:Boolean = false;
					for each (var p:Enemy in e.props) if (!p.dead) { left = true; break; }
					if (!left) return k;
				}
			}
			return -1;
		}

		/** The planned tiles phase k changes (from plan()'s list). */
		public static function phaseCells(id:String, cells:Array, k:int):Array {
			var ph:Object = phasesOf(id)[k];
			var out:Array = [];
			if (!ph) return out;
			var rows:Array = layoutOf(id);
			for each (var q:Object in cells) {
				var ch:String = q.ch, hit:Boolean = false;
				if (ph.sel == "walls") hit = ch == "#";
				else if (ph.sel == "char") hit = ch == ph.ch;
				else if (ph.sel == "ring") hit = ch != "#" && ch != "P" && ch != "B" && ((q.d >= ph.a && q.d < ph.b) || (ph.chars && String(ph.chars).indexOf(ch) >= 0));
				else if (ph.sel == "widen") {
					if (ch != "~" && ch != "#" && ch != "P" && ch != "B" && q.d >= 2.5)
						hit = at(rows, q.c - 1, q.r) == "~" || at(rows, q.c + 1, q.r) == "~" || at(rows, q.c, q.r - 1) == "~" || at(rows, q.c, q.r + 1) == "~";
				}
				if (hit) out.push(q);
			}
			return out;
		}

		private static function at(rows:Array, c:int, r:int):String {
			if (c < 0 || r < 0 || r >= rows.length || c >= String(rows[r]).length) return " ";
			return String(rows[r]).charAt(c);
		}

		/** Changes the arena for phase k: what each chosen tile becomes, laid down now if it's already up. Returns the tiles. */
		public static function applyPhase(w:World, id:String, cells:Array, k:int):Array {
			var ph:Object = phasesOf(id)[k];
			var sel:Array = phaseCells(id, cells, k);
			if (!ph) return sel;
			var st:Object = STYLES[Bosses.SETPIECES[id].style];
			var nt:int = ph.to == "hz" ? st.hz : ph.to == "water" ? World.WATER : ph.to == "hexfire" ? World.HEXFIRE : st.floor;
			for each (var q:Object in sel) {
				q.nt = nt;
				q.no = 0;
				if (q.on) { w.tiles[q.i] = nt; w.objs[q.i] = 0; }
			}
			return sel;
		}

		/** Where phase k's monsters come out: n of its tiles, spread evenly. */
		public static function spawnSpots(sel:Array, n:int):Array {
			var out:Array = [];
			if (!sel.length || n <= 0) return out;
			for (var j:int = 0; j < n; j++) {
				var q:Object = sel[int((j + 0.5) * sel.length / n) % sel.length];
				out.push({x: q.x + 0.5, y: q.y + 0.5});
			}
			return out;
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
