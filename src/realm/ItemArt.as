package realm {
	import flash.display.BitmapData;

	/**
	 * Inventory art: every item has its own 8x8 sprite.
	 *  - Tiered gear: each weapon tier is its own drawing; ability, armor and
	 *    ring tiers combine their own shape, emblem and colours.
	 *  - Named gear (uniques, Godly, class sets, Starforged, Eldritch...): a
	 *    look picked from the item's identity, so the same item always looks
	 *    the same and different items look different.
	 *
	 * Weapon keys: H highlight, B blade/metal, b shade, G guard, g guard shade,
	 * R gem, r gem shade, W grip/wood, w grip shade, P pommel, S bowstring.
	 */
	public class ItemArt {
		// ------------------------------------------------------------ weapons (8 tiers + 2 special shapes each)
		public static const SWORD:Array = [
			["........", "........", "......H.", ".....Hb.", "....Hb..", "..GHb...", "..WG....", ".W......"],
			["......HH", ".....HBB", "....HBBb", "...HBBb.", ".GHBBb..", "..GGb...", ".WG.....", "W......."],
			[".......H", "......HB", "......Bb", ".....HB.", "..G.HB..", "...GBb..", "..WG....", ".W......"],
			[".......H", "......HB", ".....HB.", "....HB..", "G..HB...", ".GHB....", "..WG....", ".W.G...."],
			[".....HHH", "....HBBB", "...HBBb.", "...HBb..", ".GHBb...", "..Gb....", ".WGG....", "P......."],
			["......RH", ".....RHB", "....HBRb", "...RHBb.", ".GHBRb..", "..GGb...", ".WG.....", "P......."],
			["......RR", ".....RHR", "....RHRr", "...RHRr.", ".GRHr...", "..GGr...", ".WG.....", "P......."],
			[".....GHH", "....HBBH", "...HBBBb", "..HBBBb.", "GGHBBb..", ".GRGb...", ".WGG....", "PW......"],
			["....HHHH", "...HBBBB", "..HBBBBb", "..HBBbb.", "RGHBb...", ".GRb....", ".WG.....", "W......."],
			[".......H", "......HR", ".....HBR", "....HRb.", "...HRb..", "GGHRb...", ".WGG....", "P.G....."]
		];
		public static const DAGGER:Array = [
			["........", "........", "........", "......H.", ".....Hb.", "...GHb..", "...WG...", "..W....."],
			["........", "........", ".......H", "......Hb", ".....Hb.", "...GHb..", "..WG....", ".W......"],
			["........", "........", "......HH", ".....HBb", "....HBb.", "..GHBb..", "..WG....", ".W......"],
			["........", ".......H", "......Hb", ".....Hb.", "..G.Hb..", "...GH...", "..WG....", ".P......"],
			["........", "......RH", ".....HBb", "....HB..", "....Bb..", "..GHb...", "..WG....", ".W......"],
			["........", ".......H", "......HB", ".....HBb", "....HBb.", "..RGb...", "..WG....", ".W......"],
			["........", "......RH", ".....RHB", "....RHB.", "...RHB..", "..GRB...", "..WG....", ".P......"],
			["........", ".......H", "......HB", ".....bB.", "....HB..", "..GBb...", "..WGR...", ".P......"],
			["........", "......HH", ".....HBb", ".....Bb.", "....HB..", ".GGHb...", "..WRG...", ".P......"],
			["........", ".......H", "......HB", ".....HbB", "....HBb.", "..GHbB..", "..WG....", ".W......"]
		];
		public static const STAFF:Array = [
			[".....WG.", "....W.g.", "...W....", "...W....", "..W.....", "..W.....", ".W......", "W......."],
			["....RR..", "....Rr..", "...W....", "...W....", "..W.....", "..W.....", ".W......", "W......."],
			["...HRR..", "....RRr.", "....Wr..", "...W....", "..W.....", "..W.....", ".W......", "W......."],
			["...GGG..", "...GRG..", "....GW..", "...WG...", "..W.....", "..W.....", ".W......", "W......."],
			["...H.H..", "....R...", "...HRH..", "....W...", "...W....", "..W.....", ".W......", "W......."],
			["..G..G..", "..GRRG..", "...GG...", "...W....", "..W.....", "..W.....", ".W......", "W......."],
			["..RRR...", ".RHRRr..", ".RRRrr..", "..rrW...", "...W....", "..W.....", ".W......", "W......."],
			[".G...G..", ".GG.GG..", "..GRG...", "...G....", "...W....", "..W.....", ".W......", "W......."],
			["G.RR.G..", "GGRHRGG.", "..RrR...", "...G....", "...W....", "..W.....", ".W......", "W......."],
			["...R.R..", "..RHRR..", "..RRHr..", "...Rr...", "...W....", "..W.....", ".W......", "W......."]
		];
		public static const WAND:Array = [
			["........", "......HH", "......H.", ".....W..", "....W...", "...W....", "..w.....", "........"],
			["........", "......R.", ".....RR.", ".....W..", "....W...", "...W....", "..w.....", "........"],
			["......HH", "......Hb", ".....W..", "....W...", "...W....", "..W.....", ".w......", "........"],
			[".....GRG", ".....RHR", ".....GRG", "....W...", "...W....", "..W.....", ".w......", "........"],
			["....R.R.", ".....RR.", ".....RG.", "....W...", "...W....", "..W.....", ".w......", "........"],
			["......GG", ".....G.G", ".....GR.", "....W...", "...W....", "..W.....", ".w......", "........"],
			["......G.", ".....GRG", "......G.", ".....W..", "....W...", "...W....", "..W.....", ".w......"],
			["....H.H.", ".....R..", "....HRH.", ".....W..", "....W...", "...W....", "..W.....", ".w......"],
			["....RRR.", "...RHHRr", "...RHRr.", "...rWr..", "...W....", "..W.....", ".w......", "........"],
			["....GG..", "......G.", "......G.", ".....GR.", "....W...", "...W....", "..W.....", ".w......"]
		];
		public static const BOW:Array = [
			["........", "...WW...", "....W.S.", ".....WS.", ".....WS.", "....W.S.", "...WW...", "........"],
			["..WW....", "...WW.S.", ".....WS.", ".....WS.", ".....WS.", ".....WS.", "...WW.S.", "..WW...."],
			["..WWW...", "....WWS.", ".....WS.", "..BBBGBH", ".....WS.", ".....WS.", "....WWS.", "..WWW..."],
			["..GW....", "...WW.S.", "....WW.S", "....WW.S", "....WW.S", "....WW.S", "...WW.S.", "..GW...."],
			["..WWR...", "..R.WWS.", ".....WS.", ".....WS.", ".....WS.", ".....WS.", "..R.WWS.", "..WWR..."],
			[".GG.....", "..GWW.S.", "....WW.S", ".....W.S", ".....W.S", "....WW.S", "..GWW.S.", ".GG....."],
			["..WW....", "...WWR..", "....WWR.", ".....WR.", ".....WR.", "....WWR.", "...WWR..", "..WW...."],
			[".GW.....", "..GWW.S.", "...RWW.S", "....GW.S", "....GW.S", "...RWW.S", "..GWW.S.", ".GW....."],
			[".RW.....", "..RWW..S", "...RWW.S", ".BBBRRBH", "...RWW.S", "..RWW..S", ".RW.....", "........"],
			["GG......", ".GWW..S.", "...WW..S", "....W.HS", "....W.HS", "...WW..S", ".GWW..S.", "GG......"]
		];

		// ------------------------------------------------------------ abilities: 3 shapes each, emblem at {x, y} (null = none)
		public static const ABILITY:Object = {
			spell: [
				[["..BBBB..", ".BHHHHB.", "BHHHHHHB", "BHHHHHHb", "BHHHHHHb", "BHHHHHHb", ".BHHHHb.", "..bbbb.."], 2, 2],
				[["GB......", "BWBBBBB.", ".BWWWWWB", ".BWWWWWb", ".BWWWWWb", ".BWWWWWb", "..BBBBWB", "......BG"], 2, 2],
				[["..HBBB..", ".HBBBBB.", ".BBBBBBb", ".BBBBBBb", ".bBBBBbb", "..bbbb..", "..GGGG..", ".GggggG."], 2, 1]
			],
			quiver: [
				[[".H.H.H..", ".W.W.W..", "BBBBBBB.", "BbbbbbB.", "BbbbbbB.", "BbbbbbB.", "BBBBBBB.", ".BBBBB.."], 2, 2],
				[["....H.H.", "...W.W.H", "..BBBBW.", ".BbbbbB.", ".BbbbbB.", "BbbbbB..", "BBBBBB..", ".BB....."], 1, 2],
				[["H.H.H...", "W.W.W.G.", "BBBBBGB.", "BbbbGbB.", "BbbGbbB.", "BbGbbbB.", "BGBBBBB.", ".BBBBB.."], 1, 3]
			],
			shield: [
				[["BBBBBBBB", "BHHHHHHb", "BHHHHHHb", "BHHHHHHb", "BHHHHHHb", ".BHHHHb.", "..BHHb..", "...Bb..."], 2, 1],
				[["..BBBB..", ".BHHHHb.", "BHHHHHHb", "BHHHHHHb", "BHHHHHHb", "BHHHHHHb", ".BHHHHb.", "..bbbb.."], 2, 2],
				[["GGGGGGGG", "GHHHHHHG", "GHHHHHHG", ".GHHHHG.", ".GHHHHG.", "..GHHG..", "..GHHG..", "...GG..."], 2, 1]
			],
			tome: [
				[[".BBBBBB.", "BbbbbbbW", "BbbbbbbW", "BbbbbbbW", "BbbbbbbW", "BbbbbbbW", ".BBBBBBW", "........"], 2, 2],
				[["GBBBBBB.", "GbbbbbbW", "GbbbbbbW", "GbbbbbbW", "GbbbbbbW", "GbbbbbbW", "GBBBBBBW", ".GGGGGG."], 3, 2],
				[[".B....B.", "BWWBBWWB", "BWWWBWWB", "BWWWBWWB", "BWWWBWWB", "BWWWBWWB", "BBBBBBBB", ".b....b."], 2, 2]
			],
			cloak: [
				[["..BBBB..", ".BBBBBB.", "BBbGGbBB", "BBbbbbBB", "BBBBBBBB", "BBbBBbBB", "BbBBBBbB", "b.bBBb.b"], 2, 3],
				[["...BB...", "..BbbB..", ".BbHHbB.", ".BBbbBB.", "BBBBBBBB", "BBBBBBBB", "BbBBBBbB", "bb.bb.bb"], 2, 4],
				[["B......B", "BB.BB.BB", "BBBBBBBB", ".BBGGBB.", ".BBBBBB.", "..BBBB..", "..BbbB..", "...bb..."], 2, 2]
			],
			helm: [
				[["...HH...", "..HBBH..", ".HBBBBb.", "HBBBBBBb", "BBbbbbBb", "BB.bb.Bb", ".B.bb.b.", "........"], 2, 1],
				[["G......G", "GG.HH.GG", ".GHBBHG.", ".HBBBBb.", "HBBBBBBb", "BBbbbbBb", "BB.bb.Bb", ".B....b."], 2, 2],
				[["..RRRR..", "...RR...", "..HBBH..", ".HBBBBb.", "HBBBBBBb", "BbbbbbbB", "Bb.bb.bB", ".B....B."], 2, 3]
			],
			skull: [
				[["..HHHH..", ".HHHHHHb", "HHRHHRHb", "HHRHHRHb", "HHHHHHHb", ".HHbbHb.", "..H.H.b.", "..HbHb.."], 2, -2],
				[["G......G", ".G.HH.G.", "..HHHH..", ".HRHHRH.", ".HRHHRHb", ".HHHHHHb", "..HbbH..", "..H.Hb.."], 2, -1],
				[["G.G.G.G.", "GGGGGGG.", ".HHHHHH.", "HHRHHRHb", "HHRHHRHb", "HHHHHHHb", ".HHbbHb.", "..HbHb.."], -1, 0]
			],
			trap: [
				[["H..H..H.", ".HBBBBH.", ".BBbbBB.", "HBbbbbBH", "HBbbbbBH", ".BBbbBB.", ".HBBBBH.", "H..H..H."], 2, 2],
				[["..H..H..", ".HBBBBH.", "HBbbbbBH", ".BbbbbB.", ".BbbbbB.", "HBbbbbBH", ".HBBBBH.", "..H..H.."], 2, 2],
				[["HH.HH.HH", "BBBBBBBB", "bBbbbbBb", "..bbbb..", "..bbbb..", "bBbbbbBb", "BBBBBBBB", "HH.HH.HH"], 2, 2]
			]
		};

		// ------------------------------------------------------------ armor: 3 shapes each
		public static const ARMOR:Object = {
			robe: [
				[[".BB..BB.", "BBBGGBBB", "bBBGGBBb", ".BBGGBB.", ".BBGGBB.", ".BBGGBB.", ".BBGGBB.", ".bBBBBb."], 2, 2],
				[["..BBBB..", ".BbbbbB.", "BBbHHbBB", "bBBGGBBb", ".BBGGBB.", ".BBBBBB.", ".BBBBBB.", "BBBBBBBB"], 2, 4],
				[["GG....GG", "GBBGGBBG", "bBBBBBBb", ".BBBBBB.", ".BBBBBB.", ".BBGGBB.", ".BBBBBB.", ".GGGGGG."], 2, 2]
			],
			leather: [
				[[".BB..BB.", "BBBbbBBB", "bBBBBBBb", ".BGGGGB.", ".BBbbBB.", ".BBBBBB.", ".bBBBBb.", "........"], 2, 1],
				[[".BB..BB.", "BBBbbBBB", "bBBGGBBb", ".BBbbBB.", ".BBGGBB.", ".BBbbBB.", ".BBBBBB.", ".b....b."], 2, 2],
				[["HH....HH", "BBBbbBBB", "bBBBBBBb", ".BBBBBB.", ".BGGGGB.", ".BBBBBB.", ".bBBBBb.", "........"], 2, 1]
			],
			heavy: [
				[["HH....HH", "BBHBBHBB", "bBBHHBBb", ".BBBBBB.", ".BbBBbB.", ".BBGGBB.", ".bBBBBb.", "........"], 2, 2],
				[["HHH..HHH", "BBBHHBBB", "bBBBBBBb", "bBBBBBBb", ".BBBBBB.", ".GGGGGG.", ".BBbbBB.", ".BB..BB."], 2, 1],
				[["H.H..H.H", "HBH..HBH", "BBBHHBBB", "bBBBBBBb", ".BBBBBB.", ".BGGGGB.", ".BbBBbB.", ".bb..bb."], 2, 2]
			]
		};

		/** 4x4 emblems stamped onto abilities and armor; 0 = none (plain first tier). */
		public static const EMBLEMS:Array = [
			null,
			["....", ".RR.", ".Rr.", "...."],
			[".RR.", "R..R", "R..R", ".RR."],
			["R..R", ".RR.", ".RR.", "R..R"],
			["R..R", "RRRR", ".RR.", "...."],
			["....", ".RR.", "RHrR", ".RR."],
			["R..R", "RRRR", "RrrR", "RRRR"],
			["R..R", ".GG.", ".GG.", "R..R"],
			["RR..", "R.RR", "RR.R", "..RR"],
			[".R..", ".RR.", "RrRR", "RrrR"],
			["...R", "..R.", ".R..", "R..."],
			["R.R.", ".R.R", "R.R.", ".R.R"]
		];

		// ------------------------------------------------------------ rings: band G/g, gem R/r, shine H
		public static const RING:Array = [
			["...RR...", "..RHrR..", "..RRrr..", ".G.gg.G.", "G......g", "G......g", ".G....g.", "..GGgg.."],
			["..R.R...", ".RRHRR..", "..RrrR..", ".GG..GG.", "G......g", "G......g", ".G....g.", "..GGgg.."],
			["...RR...", "..RHRr..", "..GRrG..", ".GG..gg.", "GG....gg", "GG....gg", ".GG..gg.", "..GGgg.."],
			["..RRRR..", ".RHHRr..", ".RRRrr..", "..RrrG..", ".G....g.", "G......g", ".G....g.", "..GGgg.."],
			[".RR..RR.", ".RHGGHr.", "..GGGG..", ".G....g.", "G......g", "G......g", ".G....g.", "..GGgg.."],
			["G.R.R.G.", "GGRHRGG.", ".GRrRG..", ".G....g.", "G......g", "G......g", ".G....g.", "..GGgg.."],
			["..GGG...", ".GRG.g..", "..GG..g.", ".G....g.", "G......g", "G......g", ".G....g.", "..GGgg.."],
			["...H....", "..RRR...", ".HRHRH..", "..RRR...", ".G.H..g.", "G......g", ".G....g.", "..GGgg.."]
		];

		/** Stat potion bottles (each stat gets a shape and its colour). */
		public static const BOTTLES:Array = [
			["...WW...", "...GG...", "..GHGG..", ".GPHPPG.", "GPPHPPpG", "GPPPPPpG", ".GPPPpG.", "..GGGG.."],
			["...WW...", "...GG...", "...PP...", "..PHPP..", "..PHPP..", ".PPPPPp.", ".PPPPpp.", "..pppp.."],
			["...WW...", "...GG...", "..PPPP..", ".PHPPPp.", "PHPPPPpp", "PPPPPPpp", ".PPPPpp.", "..pppp.."],
			["...WW...", "...GG...", "...PP...", "..PHPp..", ".PHPPPp.", "PHPPPPpp", "PPPPPPpp", "pppppppp"]
		];

		// ------------------------------------------------------------ colours
		/** Weapon colours per tier: rusty, iron, steel, silver, viper, flame, crystal, sunforged. */
		public static const TIER_PAL:Array = [
			{B: 0x8a7a6a, b: 0x5a4a3a, H: 0xb0a090, G: 0x6a5a3a, g: 0x4a3a22, R: 0x9a6a4a, r: 0x6a4a2a, W: 0x7a5030, w: 0x4a3018, P: 0x6a6a6a, S: 0xd0d0d0},
			{B: 0x9a9aa2, b: 0x5a5a62, H: 0xd8d8e0, G: 0x8a6a3a, g: 0x5a4422, R: 0xc04040, r: 0x802020, W: 0x8a5a2a, w: 0x5a3a18, P: 0x7a7a82, S: 0xd8d8d8},
			{B: 0xa8b8cc, b: 0x627088, H: 0xeef4ff, G: 0xa8a8b4, g: 0x6a6a78, R: 0x40a0ff, r: 0x2060b0, W: 0x6a4a2a, w: 0x40280f, P: 0x9a9aa8, S: 0xe8e8e8},
			{B: 0xd0d0dc, b: 0x8a8aa0, H: 0xffffff, G: 0x60a0e0, g: 0x3a6aa0, R: 0x60e0ff, r: 0x2890b0, W: 0x4a3a5a, w: 0x2a2038, P: 0xb0b0c0, S: 0xf0f0f0},
			{B: 0x9ad08a, b: 0x4a8a3a, H: 0xe0ffd0, G: 0x3a6a2a, g: 0x244a1a, R: 0xe0e040, r: 0xa0a020, W: 0x5a4a2a, w: 0x3a2a14, P: 0x3a6a2a, S: 0xd0ffc0},
			{B: 0xe0c0b0, b: 0xa05a40, H: 0xfff0e0, G: 0xc04020, g: 0x802010, R: 0xff7020, r: 0xc03a10, W: 0x5a2a1a, w: 0x3a140a, P: 0xc04020, S: 0xffd0a0},
			{B: 0xb0e8ff, b: 0x5a90c0, H: 0xffffff, G: 0x8040c0, g: 0x502080, R: 0xc070ff, r: 0x7a30c0, W: 0x3a2a4a, w: 0x201428, P: 0x8040c0, S: 0xe0f0ff},
			{B: 0xfff0c0, b: 0xc0a050, H: 0xffffff, G: 0xf0c030, g: 0xa07810, R: 0xff4040, r: 0xa02020, W: 0x6a3a1a, w: 0x3a2010, P: 0xf0c030, S: 0xfff0a0}
		];
		/** Ability base colours [main, light] by type. */
		private static const ABIL_COL:Object = {spell: [0x6a3a8a, 0xe8e0c8], quiver: [0x8a5a2a, 0xc0c0c0], shield: [0x5a6a9a, 0xd8d8e0], tome: [0x9a2a2a, 0xe8e0c8],
			cloak: [0x4a2a6a, 0xc8c8c8], helm: [0x9a9aa6, 0xe0e0e8], skull: [0x8a8070, 0xe8e0c8], trap: [0x5a5a62, 0xa0a0a8]};
		/** Armor colours per tier. */
		private static const ARMOR_COL:Object = {
			robe: [0x7a6a5a, 0x3a5ab0, 0x5a3a9a, 0x2a7a8a, 0x3a3aa0, 0x8a2a6a, 0xa02a3a, 0x202034],
			leather: [0x8a5a2a, 0x7a4a22, 0x6a6a2a, 0x4a6a2a, 0x8a3a2a, 0x2a6a5a, 0x5a2a5a, 0x2a3a4a],
			heavy: [0x8a8a92, 0x9a8a72, 0x7a8aa6, 0xa0a8b8, 0x6a7a9a, 0x8ab0d0, 0xa04030, 0xc8a040]
		};
		/** Trim colours named items pick from: gold, silver, obsidian, bone, copper, jade. */
		private static const ACCENTS:Array = [0xf0c030, 0xd0d0e0, 0x3a3a4a, 0xe8e0c8, 0xd08040, 0x40c080];
		/** Second colours named items pick from. */
		private static const HUES:Array = [0xff4040, 0x40a0ff, 0x60ff90, 0xffe040, 0xc060ff, 0xff8020, 0x40f0f0, 0xff60c0, 0xffffff, 0x202020];
		/** Main colours for uniques: crimson, azure, leaf, gold, violet, ember, teal, rose, pearl, umber, slate, onyx, moss, ice. */
		private static const UNIQUE_COLS:Array = [0xd04040, 0x4090f0, 0x50c060, 0xf0c040, 0xa060e0, 0xff8030, 0x30c0c0, 0xff70b0, 0xe8e8f0,
			0x8a6a4a, 0x6a7a8a, 0x3a3a4a, 0x7a9a3a, 0xa0e0ff];
		private static const GRIPS:Array = [0x5a3a1a, 0x2a2a3a, 0x4a1a2a, 0x1a3a3a, 0x3a2a14, 0x2a1a3a];

		/** Who an item is: its tier for plain gear, or its name/id for named gear. */
		public static function identity(it:Object):String {
			if (it.gid) return "g:" + it.gid;
			if (it.uid) return "u:" + it.uid;
			if (it.set) return "s:" + it.set + ":" + it.sub;
			if (it.rarity) return "n:" + it.rarity + ":" + it.name;
			return "t:" + it.kind + ":" + it.sub + ":" + it.tier;
		}

		private static function hash(s:String):uint {
			var h:uint = 2166136261;
			for (var i:int = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = uint(h * 16777619); }
			return h;
		}

		private static function mix(a:uint, b:uint, t:Number):uint {
			var r:int = ((a >> 16) & 255) * (1 - t) + ((b >> 16) & 255) * t;
			var g:int = ((a >> 8) & 255) * (1 - t) + ((b >> 8) & 255) * t;
			var bl:int = (a & 255) * (1 - t) + (b & 255) * t;
			return (r << 16) | (g << 8) | bl;
		}

		/** A named item's colours: its main colour plus trim and accents from its identity. */
		private static function namedPal(main:uint, h:uint):Object {
			var acc:uint = ACCENTS[h % ACCENTS.length];
			var hue:uint = HUES[(h >>> 4) % HUES.length];
			if (hue == main) hue = HUES[((h >>> 4) + 1) % HUES.length];
			var grip:uint = GRIPS[(h >>> 8) % GRIPS.length];
			return {B: main, b: Sprites.shade(main, 0.55), H: Sprites.tint(main, 0.6), G: acc, g: Sprites.shade(acc, 0.6),
				R: hue, r: Sprites.shade(hue, 0.6), W: grip, w: Sprites.shade(grip, 0.6), P: acc, S: Sprites.tint(main, 0.7)};
		}

		/** The item's main colour for named gear. */
		private static function mainColour(it:Object, h:uint):uint {
			var rc:uint = Data.RARITY_COLORS[it.rarity] || 0xffffff;
			if (it.col && it.kind == "weapon") return mix(it.col, rc, 0.15);
			// uniques come in every colour; the rarity glow still marks them as Runed
			if (it.uid) return UNIQUE_COLS[(h >>> 12) % UNIQUE_COLS.length];
			// otherwise lean the rarity colour toward a hue of its own
			return mix(rc, HUES[(h >>> 12) % 8], 0.35);
		}

		/** Copies rows and stamps an emblem at (ex, ey), only onto the drawing itself. */
		private static function stamp(rows:Array, emblem:Array, ex:int, ey:int):Array {
			if (!emblem || ex < -10) return rows;
			var out:Array = rows.concat();
			for (var y:int = 0; y < emblem.length; y++) {
				var ry:int = ey + y;
				if (ry < 0 || ry >= out.length) continue;
				var row:String = out[ry];
				var er:String = emblem[y];
				for (var x:int = 0; x < er.length; x++) {
					var rx:int = ex + x;
					var c:String = er.charAt(x);
					if (c == "." || rx < 0 || rx >= row.length || row.charAt(rx) == ".") continue;
					row = row.substr(0, rx) + c + row.substr(rx + 1);
				}
				out[ry] = row;
			}
			return out;
		}

		/** The 8x8 drawing and colours for a piece of gear, or null for other items. */
		public static function art(it:Object):Object {
			var named:Boolean = it.rarity != null && it.rarity != undefined;
			var id:String = identity(it);
			var h:uint = hash(id);
			var t:int = Math.max(0, Math.min(7, int(it.tier || 0)));
			var pal:Object, rows:Array, shape:Array, e:int;
			switch (it.kind) {
				case "weapon":
					var set:Array = {sword: SWORD, dagger: DAGGER, staff: STAFF, wand: WAND, bow: BOW}[it.sub] || WAND;
					// named weapons use the grander shapes (tiers 3-7 and the two specials)
					rows = named ? set[3 + h % 7] : set[t];
					pal = named ? namedPal(mainColour(it, h), h) : TIER_PAL[t];
					if (named && it.rarity == "lg") pal.B = 0xf8f4e0;
					// staves, wands and bows are mostly shaft: colour it with the item
					if (named && it.sub != "sword" && it.sub != "dagger") { pal.W = Sprites.shade(pal.B, 0.8); pal.w = Sprites.shade(pal.B, 0.5); }
					return {rows: rows, pal: pal};
				case "ability":
					var ab:Array = ABILITY[it.sub] || ABILITY.tome;
					t = Math.min(6, t);
					shape = named ? ab[h % 3] : ab[t < 2 ? 0 : t < 4 ? 1 : 2];
					e = named ? 1 + (h >>> 3) % (EMBLEMS.length - 1) : t;
					rows = stamp(shape[0], EMBLEMS[e], shape[1], shape[2]);
					if (named) pal = namedPal(mainColour(it, h), h);
					else {
						var ac:Array = ABIL_COL[it.sub] || [0x8a2a2a, 0xe8e0c8];
						var base:uint = Sprites.shade(ac[0], 0.85 + t * 0.07);
						var tp:Object = TIER_PAL[Math.min(7, t + 1)];
						pal = {B: base, b: Sprites.shade(base, 0.6), H: ac[1], G: tp.G, g: tp.g, W: 0xe8e0c8, R: tp.R, r: tp.r};
					}
					if (it.sub == "skull") { pal.H = named ? Sprites.tint(pal.B, 0.75) : ac[1]; pal.b = Sprites.shade(pal.H, 0.6); }
					return {rows: rows, pal: pal};
				case "armor":
					var ar:Array = ARMOR[it.sub] || ARMOR.robe;
					shape = named ? ar[h % 3] : ar[t < 3 ? 0 : t < 6 ? 1 : 2];
					e = named ? 1 + (h >>> 3) % (EMBLEMS.length - 1) : t;
					rows = stamp(shape[0], EMBLEMS[e], shape[1], shape[2]);
					if (named) pal = namedPal(mainColour(it, h), h);
					else {
						var col:uint = (ARMOR_COL[it.sub] || ARMOR_COL.robe)[t];
						var tp2:Object = TIER_PAL[t];
						pal = {B: col, b: Sprites.shade(col, 0.6), H: Sprites.tint(col, 0.35), G: tp2.G, g: tp2.g, R: tp2.R, r: tp2.r};
					}
					return {rows: rows, pal: pal};
				case "ring":
					var gem:uint = named ? mainColour(it, h) : Data.STAT_COLORS[it.sub] || 0xffffff;
					rows = RING[named ? h % RING.length : Math.min(5, t)];
					var band:uint = named ? ACCENTS[h % ACCENTS.length] : t >= 5 ? 0xd8f0ff : t >= 3 ? 0xf0c030 : t >= 1 ? 0xc0c0c8 : 0x9a7a5a;
					if (band == 0x3a3a4a) band = 0x6a6a7a;
					return {rows: rows, pal: {R: gem, r: Sprites.shade(gem, 0.6), H: 0xffffff, G: band, g: Sprites.shade(band, 0.62)}};
				case "stat":
					var sc:uint = Data.STAT_COLORS[it.sub] || 0xa040e0;
					var keys:Array = ["hp", "mp", "att", "def", "spd", "dex", "vit", "wis", "mgt", "luc", "prt", "frt"];
					var bi:int = Math.max(0, keys.indexOf(it.sub)) % BOTTLES.length;
					return {rows: BOTTLES[bi], pal: {W: 0x8a5a2a, G: 0xd8d8e0, H: 0xffffff, P: sc, p: Sprites.shade(sc, 0.6)}};
			}
			return null;
		}
	}
}
