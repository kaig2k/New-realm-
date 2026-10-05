package realm {
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	/**
	 * All art lives here as tiny text pixel grids. They're scaled up and get
	 * a thin dark outline -- the RotMG look.
	 */
	public class Sprites {
		public static const SCALE:int = 5;
		public static const ROT_FRAMES:int = 32;
		private static const OUTLINE_COL:uint = 0xff0c0c0c;
		private static var cache:Object = {};

		// ================================================================ classes
		// Every class: [stand, walk, attack]. They face right.
		private static const WIZARD:Array = [
			["...RR..G", "..RRRr.Y", ".RRRRRrY", "..SSES.Y", ".WWWWWSY", "RRWWWRrY", "rRRRRRr.", ".BB..BB."],
			["...RR..G", "..RRRr.Y", ".RRRRRrY", "..SSES.Y", ".WWWWWSY", "RRWWWRrY", "rRRRRRr.", "BB...BB."],
			["...RR...", "..RRRr..", ".RRRRRr.", "..SSES.G", ".WWWWSYY", "RRWWWRr.", "rRRRRRr.", ".BB..BB."]];
		private static const ARCHER:Array = [
			["..GGGg..", ".GGGGGgW", ".GSSESgW", "..SSSS.W", ".LLLLLSW", ".LlGGLlW", ".LLLLLl.", ".BB..BB."],
			["..GGGg..", ".GGGGGgW", ".GSSESgW", "..SSSS.W", ".LLLLLSW", ".LlGGLlW", ".LLLLLl.", "BB...BB."],
			["..GGGg..", ".GGGGGg.", ".GSSESgW", "..SSSSSW", ".LLLLL.W", ".LlGGLlW", ".LLLLLl.", ".BB..BB."]];
		private static const KNIGHT:Array = [
			["..rHHH.W", ".HHHHHhW", ".HhEEhhW", ".hHHHHhW", "KKMMMMSA", "KQKMMmS.", "KKMMMMm.", ".BB..BB."],
			["..rHHH.W", ".HHHHHhW", ".HhEEhhW", ".hHHHHhW", "KKMMMMSA", "KQKMMmS.", "KKMMMMm.", "BB...BB."],
			["..rHHH..", ".HHHHHh.", ".HhEEhh.", ".hHHHHh.", "KKMMMMS.", "KQKMMmWW", "KKMMMMm.", ".BB..BB."]];
		private static const PRIEST:Array = [
			["..WWWw..", ".WWWWWw.", ".WSSESw.", "..SSSS.G", ".WWDWWSY", ".WDDDWwY", ".WWDWWw.", ".BB..BB."],
			["..WWWw..", ".WWWWWw.", ".WSSESw.", "..SSSS.G", ".WWDWWSY", ".WDDDWwY", ".WWDWWw.", "BB...BB."],
			["..WWWw..", ".WWWWWw.", ".WSSESwG", "..SSSSSY", ".WWDWW..", ".WDDDWw.", ".WWDWWw.", ".BB..BB."]];

		private static const ROGUE:Array = [
			["..PPPp..", ".PPPPPp.", ".PSSESp.", "..SSSS.W", ".KKKKKSW", ".KkKKkK.", ".KKKKKk.", ".BB..BB."],
			["..PPPp..", ".PPPPPp.", ".PSSESp.", "..SSSS.W", ".KKKKKSW", ".KkKKkK.", ".KKKKKk.", "BB...BB."],
			["..PPPp..", ".PPPPPp.", ".PSSESp.", "..SSSSWW", ".KKKKKS.", ".KkKKkK.", ".KKKKKk.", ".BB..BB."]];
		private static const WARRIOR:Array = [
			["Y.HHHH.W", "YHHHHHHW", ".HhEEhHW", ".hHHHHhW", "RRMMMMSA", "RRMMMmS.", ".RMMMMm.", ".BB..BB."],
			["Y.HHHH.W", "YHHHHHHW", ".HhEEhHW", ".hHHHHhW", "RRMMMMSA", "RRMMMmS.", ".RMMMMm.", "BB...BB."],
			["Y.HHHH..", "YHHHHHH.", ".HhEEhH.", ".hHHHHh.", "RRMMMMS.", "RRMMMmWW", ".RMMMMm.", ".BB..BB."]];
		private static const NECRO:Array = [
			["..DDDd.G", ".DDDDDdW", ".DSSESdW", "..SSSS.W", ".DDKDDSW", ".DKKKDdW", ".DDKDDd.", ".BB..BB."],
			["..DDDd.G", ".DDDDDdW", ".DSSESdW", "..SSSS.W", ".DDKDDSW", ".DKKKDdW", ".DDKDDd.", "BB...BB."],
			["..DDDd..", ".DDDDDd.", ".DSSESdG", "..SSSSSW", ".DDKDD..", ".DKKKDd.", ".DDKDDd.", ".BB..BB."]];
		private static const HUNTRESS:Array = [
			["..RRRr..", ".RRRRRrW", ".RSSESrW", "..SSSS.W", ".GGGGGSW", ".GgLGgGW", ".GGGGGg.", ".BB..BB."],
			["..RRRr..", ".RRRRRrW", ".RSSESrW", "..SSSS.W", ".GGGGGSW", ".GgLGgGW", ".GGGGGg.", "BB...BB."],
			["..RRRr..", ".RRRRRr.", ".RSSESrW", "..SSSSSW", ".GGGGG.W", ".GgLGgGW", ".GGGGGg.", ".BB..BB."]];

		// ================================================================ enemies
		private static const HUMANOID:Array = [["..HHHh..", ".HHHHHh.", ".HSSESh.", "..SSSS.W", ".BBBBBSW", ".BbABbBW", ".BBBBBb.", ".LL..LL."]];
		private static const BRUTE:Array = [["..hHHH..", ".hHHHHH.", ".hHHEHE.", ".hHHHHH.", "bBBBBBSW", "bBBABBSW", ".bBBBB.W", ".LL..LL."]];
		private static const MAGE:Array = [["...Hh...", "..HHHh.G", ".HHHHHhW", "..SSES.W", ".bBBBBSW", ".bBBABbW", "bBBBBBBb", ".LL..LL."]];
		private static const SNAKE:Array = [["........", "....GGg.", "...GEGGg", "...GGg..", "..GGg...", ".GGg.GGg", ".gGGGGg.", "........"]];
		private static const CRAB:Array = [["C......C", "Cc....cC", ".C.EE.C.", "..cCCc..", ".cCCCCc.", "cCCCCCCc", ".c.cc.c.", "c......c"]];
		private static const BLOB:Array = [["..bBBb..", ".bBBBBb.", "bBWWWWBb", "bBWEEWBb", "bBWEEWBb", "bBWWWWBb", ".bBBBBb.", "..bBBb.."]];
		private static const DJINN:Array = [["..cCCc..", ".cCCCCc.", ".cECCEc.", ".cCCCCc.", "..cCCc..", "...cC...", "..cC....", ".cC....."]];
		private static const ENT:Array = [[".gGGGGg.", "gGGLGGGg", "gGEGGEGg", "gGGGGGGg", ".gGTTGg.", "...TT...", "..tTTt..", ".tT..Tt."]];
		private static const MEDUSA:Array = [["G.G..G.G", ".gGGGGg.", "gGSSSSGg", ".gSEESg.", "..SSSS..", ".bBBBBb.", "..bBBb..", ".bBBBBb."]];
		private static const CUBELET:Array = [["........", ".pPPPPp.", ".PQQQQp.", ".PQEEQp.", ".PQEEQp.", ".PQQQQp.", ".pppppp.", "........"]];
		private static const BOSS:Array = [[
			"...Y...YY...Y...",
			"...YY.YYYY.YY...",
			"...YyYYYYYYyY...",
			"..pPPPPPPPPPPp..",
			".pPQQQQQQQQQQPp.",
			".PQQQQQQQQQQQQp.",
			".PQQWWWWWWWWQQp.",
			".PQWWWWEEWWWWQp.",
			".PQWWWEEEEWWWQp.",
			".PQWWWWEEWWWWQp.",
			".PQQWWWWWWWWQQp.",
			".PQQQQQQQQQQQQp.",
			".PQQQRRRRRRQQQp.",
			".pPQQQQQQQQQQPp.",
			"..pppppppppppp..",
			"...p..p..p..p..."]];

		private static const TITAN:Array = [[
			"....rrrrrrrr....",
			"...rRRRRRRRRr...",
			"..rRRYRRRRYRRr..",
			"..rRYYRRRRYYRr..",
			"..rRRRRRRRRRRr..",
			".rrRRRWWWWRRRrr.",
			"rRRrRRRRRRRRrRRr",
			"rRRrrRYRRYRrrRRr",
			"rRRr.rRRRRr.rRRr",
			"rYYr.rRYYRr.rYYr",
			".rr..rRRRRr..rr.",
			".....rRRRRr.....",
			"....rRRrrRRr....",
			"....rRRr.rRRr...",
			"...rYYRr.rRYYr..",
			"...rrrr...rrrr.."]];
		private static const WYRM:Array = [[
			"..W..........W..",
			"..WW........WW..",
			"...WCCCCCCCCW...",
			"..CCCCCCCCCCCC..",
			".CCcCCCCCCCCcCC.",
			".CcEECCCCCCEEcC.",
			".CCEECCCCCCEEcC.",
			".CCCCCCCCCCCCCC.",
			"..CCCcWWWWcCCC..",
			"..cCCWcWWcWCCc..",
			"...cCCCCCCCCc...",
			"....cCCCCCCc....",
			"..CC.cCCCCc.CC..",
			".CCCC.cCCc.CCCC.",
			"CCCc...cc...cCCC",
			"Cc............cC"]];
		private static const HOLLOWKING:Array = [[
			"....Y..YY..Y....",
			"....YYYYYYYY....",
			"....BBBBBBBB....",
			"...BBBBBBBBBB...",
			"...BBEEBBEEBB...",
			"...BBEEBBEEBB...",
			"....BBBBBBBB....",
			".....BTBTBB.....",
			"...PPBBBBBBPP...",
			"..PPPB.BB.BPPP..",
			"..PPPBBBBBBPPPG.",
			"..PPP.B..B.PPGG.",
			"..PPP.BBBB.PPPG.",
			"...PP.B..B.PP.G.",
			".....BB..BB...G.",
			"....BBB..BBB..G."]];
		private static const ELDER:Array = [[
			"......pppp......",
			".....pPPPPp.....",
			"....pPPPPPPp....",
			"...pPPPPPPPPp...",
			"...pPsSSSSsPp...",
			"...pPSEESEESp...",
			"...pPsSSSSsPp...",
			"..pPPPsSSsPPPp..",
			".pPPPPPPPPPPPPp.",
			"pPPGPPPPPPPPGPPp",
			"pPPGPPPAAPPPGPPp",
			".pPGPPPAAPPPGPp.",
			"..pGPPPPPPPPGp..",
			"...GpPPPPPPpG...",
			"...G.pP..Pp.G...",
			"...G.pp..pp.G..."]];

		// ================================================================ world objects
		private static const TREE:Array = [["..gGGg..", ".gGLGGg.", "gGGLGGGg", "gGGGGLGg", "gGLGGGGg", ".gGGGGg.", "..gggg..", "...TT...", "...TT...", "..tTTt.."]];
		private static const PINE:Array = [["...gg...", "..gGGg..", "..gLGg..", ".gGGLGg.", ".gGGGGg.", "gGLGGGGg", "gGGGGLGg", ".gggggg.", "...TT...", "..tTTt.."]];
		private static const PALM:Array = [["GG.GG.GG", ".GGLGG..", "G..TGG.G", "...T....", "...T....", "....T...", "....T...", "...tTt.."]];
		private static const ROCK:Array = [["..kKKk..", ".kKLKKk.", "kKLKKKKd", "kKKKKKdd", ".kkkkdd."]];
		private static const BOULDER:Array = [["..kKKKk.", ".kKLLKKk", "kKLKKKKd", "kKKKKKKd", "kKKKKKdd", ".kKKKddd", "..kdddd."]];
		private static const DEADTREE:Array = [["W..W..W.", ".W.W.W..", "..WWW...", "...W..W.", "...WWW..", "...W....", "...W....", "..WWW..."]];
		private static const BRAZIER:Array = [["..Y.F...", "...FYF..", "..FYWYF.", "..FYYF..", ".SSSSSS.", "..sSSs..", "...SS...", "..sSSs.."]];
		private static const CHEST:Array = [["........", ".KKKKKK.", "KCCCCCCK", "KCcYYcCK", "KKKKKKKK", "KCCYYCCK", "KCcCCcCK", "KKKKKKKK"]];
		private static const PORTAL:Array = ["..aaaa..", ".abbbba.", "abccccba", "abcddcba", "abcddcba", "abccccba", ".abbbba.", "..aaaa.."];
		private static const ANVIL:Array = [["...CC...", "..CWCc..", "........", "KKKKKKK.", "KkkkkkKK", ".KkkkK..", "..KkK...", "KKKKKKK."]];
		private static const QUESTBOARD:Array = [["WWWWWWWW", "WPPPPPPW", "WPLLLPPW", "WPPPPPPW", "WPLLLLPW", "WPPPPPPW", "WWWWWWWW", ".W....W."]];
		private static const WOLF:Array = [["......W.", ".....WWW", "WWWWWWEW", "WWWWWWWW", "wWWWWWW.", ".W.W.W.W", ".W.W.W.W", "........"]];
		private static const BAG:Array = [["...KK...", "..K..K..", "..CCCC..", ".CCCCCC.", "CCCDCCCc", "CCCCCCCc", ".cCCCCc.", "........"]];
		private static const GRAVE:Array = [["..GGGG..", ".GGGGGG.", ".GGDGGg.", ".GDDDGg.", ".GGDGGg.", ".GGDGGg.", ".GGGGGg.", "MMMMMMMM"]];

		// ================================================================ projectiles (point right)
		private static const P_ARROW:Array = ["........", "........", "F.....H.", "FFSSSSHH", "F.....H.", "........", "........", "........"];
		private static const P_BOLT:Array = ["........", "........", "..aaCC..", "aaCCWWC.", "aaCCWWC.", "..aaCC..", "........", "........"];
		private static const P_BLADE:Array = ["..aC....", "...aCW..", "....aCW.", "....aCW.", "....aCW.", "....aCW.", "...aCW..", "..aC...."];
		private static const P_ORB:Array = ["........", "...CC...", "..CWWC..", ".CWWWWC.", ".CWWWWC.", "..CWWC..", "...CC...", "........"];
		private static const P_STAR:Array = ["...C....", "...CC...", "C..Ca...", ".CCaWCCC", "CCCWaCC.", "...aC..C", "...CC...", "....C..."];
		private static const P_RING:Array = ["..CCCC..", ".CaaaaC.", "Ca....aC", "Ca....aC", "Ca....aC", "Ca....aC", ".CaaaaC.", "..CCCC.."];
		private static const P_DART:Array = ["........", "........", "...aC...", "aaaCWWC.", "aaaCWWC.", "...aC...", "........", "........"];
		private static const P_KNIFE:Array = ["........", "........", "........", "SSGHHHHL", "........", "........", "........", "........"];
		private static const PROJ:Object = {knife: P_KNIFE, arrow: P_ARROW, bolt: P_BOLT, blade: P_BLADE, orb: P_ORB, star: P_STAR, ring: P_RING, dart: P_DART};

		// ================================================================ item icons
		private static const I_STAFF:Array = ["......TT", ".....TLT", "....TTT.", "...W....", "..W.....", ".W......", "W.......", "........"];
		private static const I_BOW:Array = ["...WW...", "....WS..", ".....WS.", "..TTTWTT", ".....WS.", ".....WS.", "....WS..", "...WW..."];
		private static const I_SWORD:Array = [".......T", "......TL", ".....TL.", "....TL..", ".GGTL...", "..GG....", ".W.G....", "W......."];
		private static const I_WAND:Array = ["......TT", ".....TLT", "......T.", ".....W..", "....W...", "...W....", "..W.....", "........"];
		private static const I_ARMOR:Array = [".TT..TT.", "TAAAAAAT", "TAAaaAAT", ".AAAAAA.", ".AATTAA.", ".AAAAAA.", ".TTTTTT.", "........"];
		private static const I_POT:Array = ["...WW...", "...GG...", "..PPPP..", ".PPPPPP.", ".PLPPPP.", ".PPPPPp.", "..PPpp..", "........"];
		private static const I_SPELL:Array = ["..BBBB..", ".BWWWWB.", ".BWTTWB.", ".BWWWWB.", ".BWTTWB.", ".BWWWWB.", "..BBBB..", "........"];
		private static const I_QUIVER:Array = [".T.T.T..", ".W.W.W..", "BBBBBBB.", "BAAAAAB.", "BBTTTBB.", "BAAAAAB.", "BBBBBBB.", ".BBBBB.."];
		private static const I_SHIELD:Array = ["BBBBBBBB", "BAAAAAAB", "BAATTAAB", "BATTTTAB", "BAATTAAB", ".BAAAAB.", "..BAAB..", "...BB..."];
		private static const I_TOME:Array = [".BBBBBB.", "BAAAAAAW", "BAATTAAW", "BATTTTAW", "BAATTAAW", "BAAAAAAW", ".BBBBBBW", "........"];
		private static const I_RING:Array = ["...TT...", "..TLLT..", "..TTTT..", ".G....G.", "G......G", "G......G", ".G....G.", "..GGGG.."];
		private static const I_DAGGER:Array = ["......LT", ".....TL.", "....TL..", "...TL...", ".GGL....", "..GG....", ".W.G....", "W......."];
		private static const I_CLOAK:Array = ["..AAAA..", ".AAAAAA.", "AAaTTaAA", "AAaaaaAA", "AAAAAAAA", "AAaAAaAA", "AaAAAAaA", "a.aAAa.a"];
		private static const I_HELM:Array = ["..TTTT..", ".TAAAAT.", "TAAAAAAT", "TAaaaaAT", "TAa..aAT", "TAa..aAT", ".TA..AT.", "........"];
		private static const I_SKULLITEM:Array = ["..WWWW..", ".WWWWWW.", "WWTWWTWW", "WWTWWTWW", "WWWWWWWW", ".WWTTWW.", "..W..W..", "..WWWW.."];
		private static const I_TRAP:Array = ["T..T..T.", ".TAAAAT.", ".AAaaAA.", "TAaTTaAT", "TAaTTaAT", ".AAaaAA.", ".TAAAAT.", "T..T..T."];
		private static const I_SOR:Array = ["...CC...", "..CWCC..", ".CWCCCc.", ".CCCCcc.", ".CCCcc..", "..Ccc...", "...c....", "........"];
		private static const I_GOLD:Array = ["..YYYY..", ".YWYYYY.", "YWYYYYyY", "YYYyyYyY", "YYYyyYyY", "YYYYYYyY", ".YyyyyY.", "..YYYY.."];
		private static const I_ONRANE:Array = ["...PP...", "..PWPP..", ".PWPPPp.", "PPPPPppp", ".PPPppp.", "..Pppp..", "...pp...", "........"];
		private static const I_FAME:Array = ["...O....", "..OYO...", ".OYYO.O.", ".OYYYOO.", "OYYWYYO.", "OYWWWYO.", ".OYYYO..", "..OOO..."];
		private static const I_SKULL:Array = [".WWWWW..", "WWWWWWW.", "WEEWEEW.", "WEEWEEW.", "WWWEWWW.", ".WWWWW..", ".W.W.W..", "........"];

		public static const TIER_COLORS:Array = [0x9a9a9a, 0xb08d57, 0xd8d8d8, 0x5aa0e0, 0x50c050, 0xe0c040, 0xff7030, 0xc060ff, 0xff60ff];

		// name: [frames, palette, scale]
		private static const DEFS:Object = {
			wizard: [WIZARD, {R: 0xd42a2a, r: 0x8a1414, S: 0xf2c9a0, E: 0x101010, W: 0xf4f4f4, Y: 0xe0b030, G: 0x60e0ff, B: 0x3a2010}],
			archer: [ARCHER, {G: 0x3a9a3a, g: 0x226a22, S: 0xf2c9a0, E: 0x101010, L: 0x8a5a2a, l: 0x5a3a18, W: 0xc08040, B: 0x3a2a14}],
			knight: [KNIGHT, {r: 0xd02020, H: 0xd0d0d8, h: 0x8a8a96, E: 0x101010, K: 0xb02828, Q: 0xf0c030, M: 0xa8a8b4, m: 0x6a6a78, S: 0xc89030, A: 0xc89030, W: 0xf0f0ff, B: 0x2a2a30}],
			priest: [PRIEST, {W: 0xf4f4f4, w: 0xb8b8c4, S: 0xf2c9a0, E: 0x101010, D: 0x202020, G: 0x70e0ff, Y: 0xe0b030, B: 0x5a4030}],

			rogue: [ROGUE, {P: 0x5a2a7a, p: 0x341848, S: 0xf2c9a0, E: 0x101010, K: 0x3a3a44, k: 0x24242c, W: 0xd8d8e8, B: 0x1a1a1a}],
			warrior: [WARRIOR, {Y: 0xe8e0c0, H: 0xc0a060, h: 0x806a30, E: 0x101010, R: 0xb02020, M: 0xc83030, m: 0x802020, S: 0xc89030, A: 0xc89030, W: 0xf0f0ff, B: 0x2a1a10}],
			necromancer: [NECRO, {D: 0x2e2e36, d: 0x18181c, S: 0xd8c8b8, E: 0xff3030, K: 0x9a1a1a, G: 0xe8e0c8, W: 0x5a3a2a, B: 0x101010}],
			huntress: [HUNTRESS, {R: 0xd04a20, r: 0x8a2a10, S: 0xf2c9a0, E: 0x101010, G: 0x4a8a3a, g: 0x2e5a24, L: 0x8a5a2a, W: 0xc08040, B: 0x3a2a14}],
			titan: [TITAN, {r: 0x2a1610, R: 0x5a3020, Y: 0xff8a20, W: 0xffd040}, 5],
			wyrm: [WYRM, {C: 0x7ac8f0, c: 0x3a78b0, E: 0x1a2a6a, W: 0xf0f8ff}, 5],
			hollowking: [HOLLOWKING, {Y: 0xf0c030, B: 0xe8e0c8, E: 0x6aff4a, T: 0x2a2a2a, P: 0x4a1a6a, G: 0x9a7a40}, 5],
			elder: [ELDER, {p: 0x1e0c30, P: 0x3e1a62, S: 0xb8a8e0, s: 0x8a78b8, E: 0xff3060, G: 0xd8a830, A: 0x60ffe0}, 6],
			behemoth: [TITAN, {r: 0x1a3a10, R: 0x4a7a2a, Y: 0xc0ff60, W: 0xffffff}, 5],
			regent: [HOLLOWKING, {Y: 0xd0a0ff, B: 0x9a80c0, E: 0xff60c0, T: 0x201030, P: 0x301050, G: 0xc0a0ff}, 5],
			sorcerer: [ELDER, {p: 0x0c1a3a, P: 0x1a3a7a, S: 0xd0c0a8, s: 0xa09078, E: 0x60c0ff, G: 0x8a6a40, A: 0xff4040}, 6],
			warden: [HOLLOWKING, {Y: 0x8ad8ff, B: 0x9ab0c0, E: 0x40e0ff, T: 0x203040, P: 0x1a3a5a, G: 0x6a8aa0}, 5],
			pyrelord: [TITAN, {r: 0x401008, R: 0x8a2a10, Y: 0xffe040, W: 0xffffff}, 5],
			seraph: [WYRM, {C: 0xf8f0a0, c: 0xc0a030, E: 0x4060ff, W: 0xffffff}, 5],
			imp: [BRUTE, {H: 0xe05020, h: 0x902a10, E: 0xffe040, B: 0x5a2a14, b: 0x3a1a0c, A: 0xff9030, L: 0x2a140a, W: 0xffb040, S: 0xe05020}],
			skeleton: [HUMANOID, {H: 0xe8e0c8, h: 0xb0a890, S: 0xe8e0c8, E: 0x202020, B: 0xd0c8b0, b: 0x9a9280, A: 0x5a5a5a, L: 0xb0a890, W: 0xa0a0a0}],
			shade: [HUMANOID, {H: 0x3a1a5a, h: 0x200c34, S: 0x7a5aa8, E: 0xff3060, B: 0x2e1448, b: 0x1a0a2c, A: 0xa060ff, L: 0x100818, W: 0xc080ff}],
			merchant: [HUMANOID, {H: 0x2a7a4a, h: 0x1a5030, S: 0xf2c9a0, E: 0x101010, B: 0x2a8a5a, b: 0x1a5a3a, A: 0xf0c030, L: 0x3a2a14, W: 0xf0c030}],
			questboard: [QUESTBOARD, {W: 0x6a4423, P: 0xf0e0b0, L: 0x8a7a5a}, 6],
			slime: [BLOB, {B: 0x5ac040, b: 0x3a8a2a, W: 0x9aff7a, E: 0x103010}],
			wolf: [WOLF, {W: 0x8a8a92, w: 0x5a5a62, E: 0xff3030}],
			golem: [BRUTE, {H: 0x9a9aa0, h: 0x6a6a70, E: 0x60e0ff, B: 0x8a8a90, b: 0x5a5a60, A: 0x60e0ff, L: 0x4a4a50, W: 0x8a8a90, S: 0x9a9aa0}, 6],
			lich: [MAGE, {H: 0x3a1a5a, h: 0x200c34, S: 0xe8e0c8, E: 0x60e0ff, B: 0x1a1a24, b: 0x0c0c12, L: 0x0c0c12, W: 0x5a4a3a, G: 0x60ff90}, 6],
			anvil: [ANVIL, {C: 0xa060ff, W: 0xffffff, c: 0x6a30c0, K: 0x5a5a62, k: 0x3a3a40}, 6],
			gold: [[I_GOLD], {Y: 0xf0c030, y: 0xb08818, W: 0xfff0a0}, 3],
			onrane: [[I_ONRANE], {P: 0xc060ff, p: 0x7a28b8, W: 0xf0d0ff}, 3],
			pirate: [HUMANOID, {H: 0xd02828, h: 0x901818, S: 0xe0b890, E: 0x101010, B: 0x4a50a8, b: 0x323878, A: 0xd0b040, L: 0x2a1a10, W: 0xc0c0c0}],
			bandit: [HUMANOID, {H: 0x383838, h: 0x202020, S: 0xd0a880, E: 0xff3030, B: 0x484848, b: 0x2a2a2a, A: 0x8a5a2a, L: 0x1a1a1a, W: 0xc0c0c0}],
			elf: [HUMANOID, {H: 0x4a2858, h: 0x2a1438, S: 0x9a78c8, E: 0xffffff, B: 0x382448, b: 0x221430, A: 0xd0a0ff, L: 0x1a0c20, W: 0xd0a0ff}],
			goblin: [BRUTE, {H: 0x70b840, h: 0x4a8a28, E: 0xffe020, B: 0x7a5a32, b: 0x50381c, A: 0xd0b040, L: 0x3a2814, W: 0xa0a0a0, S: 0x70b840}],
			orc: [BRUTE, {H: 0x3a8a3a, h: 0x245a24, E: 0xff3030, B: 0x6a4a2a, b: 0x42301a, A: 0x9a9a9a, L: 0x2a1a10, W: 0xd0d0d0, S: 0x3a8a3a}],
			hobbit: [MAGE, {H: 0x8a48b0, h: 0x5a2878, S: 0xe8c098, E: 0x101010, B: 0x7038a0, b: 0x4a2070, L: 0x3a2814, W: 0x8a5a2a, G: 0x60d0ff}],
			snake: [SNAKE, {G: 0xd0b848, g: 0x8a7a28, E: 0xff2020}],
			crab: [CRAB, {C: 0xe85a34, c: 0xa03a1c, E: 0x101010}],
			gazer: [BLOB, {B: 0xa048b8, b: 0x682878, W: 0xffffff, E: 0x202020}, 6],
			medusa: [MEDUSA, {G: 0x48c848, g: 0x288a28, S: 0xc8e8a8, E: 0xff2020, B: 0x8a6a28, b: 0x5a4418}, 6],
			djinn: [DJINN, {C: 0x58a8ff, c: 0x2868c0, E: 0xffffff}, 6],
			ent: [ENT, {G: 0x3a9a2a, g: 0x226818, L: 0x5ac040, E: 0xffe040, T: 0x6a4423, t: 0x442a14}, 7],
			beholder: [BLOB, {B: 0xc02828, b: 0x781414, W: 0xffe8b0, E: 0x101010}, 6],
			cubelet: [CUBELET, {P: 0x6a28a8, p: 0x3a1060, Q: 0xa050f0, E: 0xff4040}],
			boss: [BOSS, {Y: 0xf8c828, y: 0xb08810, P: 0x5a1a98, p: 0x2e0a50, Q: 0x8a40d8, W: 0xffffff, E: 0xff2020, R: 0xd02848}, 6],

			tree: [TREE, {g: 0x2d6b22, G: 0x4a9a36, L: 0x6ec050, T: 0x6b4423, t: 0x442a14}],
			pine: [PINE, {g: 0x1a4418, G: 0x2a6424, L: 0x3e8434, T: 0x5a3a1c, t: 0x3a2410}],
			palm: [PALM, {G: 0x4aa83a, L: 0x7ad060, T: 0x9a7040, t: 0x6a4a28}],
			rock: [ROCK, {k: 0x6a6a6a, K: 0x8e8e8e, L: 0xb4b4b4, d: 0x4a4a4a}],
			boulder: [BOULDER, {k: 0x4a4a4e, K: 0x626268, L: 0x84848a, d: 0x2e2e32}],
			deadtree: [DEADTREE, {W: 0x5a4a3a}],
			brazier: [BRAZIER, {Y: 0xffe040, F: 0xff7a20, W: 0xffffff, S: 0x6a6a72, s: 0x44444a}],
			chest: [CHEST, {K: 0x4a2a10, C: 0x9a6a3a, c: 0x7a4a24, Y: 0xf0c030}, 6],
			bag_brown: [BAG, {K: 0x502a10, C: 0x9a6a3a, c: 0x6a4420, D: 0x5a3a1a}],
			bag_purple: [BAG, {K: 0x401060, C: 0xb050e0, c: 0x7a2aa8, D: 0x6a2090}],
			bag_cyan: [BAG, {K: 0x105060, C: 0x40d0f0, c: 0x1a90b0, D: 0x1a8098}],
			bag_white: [BAG, {K: 0x808080, C: 0xffffff, c: 0xc8c8c8, D: 0xc0c0c0}],
			bag_fabled: [BAG, {K: 0x601010, C: 0xe03838, c: 0xa02020, D: 0x801818}],
			bag_legendary: [BAG, {K: 0x6a5a10, C: 0xf0e040, c: 0xb0a020, D: 0x8a7a18}],
			bag_relic: [BAG, {K: 0x105a54, C: 0x40f0e0, c: 0x20a8a0, D: 0x188a84}],
			grave: [GRAVE, {G: 0x9a9aa0, g: 0x6a6a70, D: 0x4a4a50, M: 0x3a6a2a}],
			fame: [[I_FAME], {O: 0xd05010, Y: 0xff9a2e, W: 0xffe080}, 3],
			skull: [[I_SKULL], {W: 0xe8e8e8, E: 0x202020}, 3]
		};

		// ================================================================ API
		/** Animation frame `frame` of a sprite (0 stand, 1 walk, 2 attack). */
		public static function get(name:String, frame:int = 0, flip:Boolean = false):BitmapData {
			var d:Array = DEFS[name] || DEFS["cubelet"];
			var frames:Array = d[0];
			if (frame >= frames.length) frame = 0;
			var key:String = name + ":" + frame + (flip ? "f" : "");
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			if (flip) {
				var src:BitmapData = get(name, frame);
				bd = new BitmapData(src.width, src.height, true, 0);
				bd.draw(src, new Matrix(-1, 0, 0, 1, src.width, 0));
			} else {
				bd = build(frames[frame], d[1], d[2] || SCALE, 3);
			}
			cache[key] = bd;
			return bd;
		}

		/** Swirling portal: 4 animation frames made by cycling the palette. */
		public static function portal(color:uint, frame:int):BitmapData {
			frame = frame % 4;
			var key:String = "portal_" + color + "_" + frame;
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			var ring:Array = [shade(color, 0.45), shade(color, 0.75), color, tint(color, 0.6)];
			var keys:Array = ["a", "b", "c", "d"];
			var pal:Object = {};
			for (var i:int = 0; i < 4; i++) pal[keys[i]] = ring[(i + frame) % 4];
			bd = build(PORTAL, pal, 6, 3);
			cache[key] = bd;
			return bd;
		}

		/** Flashed version used when something gets hit. */
		public static function hit(name:String, frame:int = 0, flip:Boolean = false):BitmapData {
			var key:String = name + ":" + frame + (flip ? "f" : "") + ":hit";
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			bd = get(name, frame, flip).clone();
			bd.colorTransform(bd.rect, new ColorTransform(0.5, 0.5, 0.5, 1, 140, 60, 60, 0));
			cache[key] = bd;
			return bd;
		}

		/** Soft elliptical drop shadow. */
		public static function shadow(w:int):BitmapData {
			var key:String = "shadow" + w;
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			var h:int = Math.max(6, int(w * 0.32));
			var s:Shape = new Shape();
			s.graphics.beginFill(0x000000, 0.22);
			s.graphics.drawEllipse(0, 0, w, h);
			s.graphics.beginFill(0x000000, 0.18);
			s.graphics.drawEllipse(w * 0.15, h * 0.15, w * 0.7, h * 0.7);
			s.graphics.endFill();
			bd = new BitmapData(w, h, true, 0);
			bd.draw(s);
			cache[key] = bd;
			return bd;
		}

		/** Scales a pixel grid and adds an `outline`-px dark border. */
		public static function build(rows:Array, pal:Object, scale:int, outline:int):BitmapData {
			var h:int = rows.length;
			var w:int = String(rows[0]).length;
			var pad:int = outline;
			var bw:int = w * scale + pad * 2, bh:int = h * scale + pad * 2;
			var bd:BitmapData = new BitmapData(bw, bh, true, 0);
			var r:Rectangle = new Rectangle(0, 0, scale, scale);
			for (var y:int = 0; y < h; y++) {
				var row:String = rows[y];
				for (var x:int = 0; x < w; x++) {
					var ch:String = row.charAt(x);
					if (ch == "." || pal[ch] == undefined) continue;
					r.x = pad + x * scale;
					r.y = pad + y * scale;
					bd.fillRect(r, 0xff000000 | uint(pal[ch]));
				}
			}
			if (outline > 0) addOutline(bd, outline);
			return bd;
		}

		private static function addOutline(bd:BitmapData, passes:int):void {
			var w:int = bd.width, h:int = bd.height;
			var px:Vector.<uint> = bd.getVector(bd.rect);
			for (var p:int = 0; p < passes; p++) {
				var src:Vector.<uint> = px.concat();
				for (var y:int = 0; y < h; y++) {
					for (var x:int = 0; x < w; x++) {
						var i:int = y * w + x;
						if (src[i] != 0) continue;
						var hit:Boolean = false;
						for (var dy:int = -1; dy <= 1 && !hit; dy++) {
							var yy:int = y + dy;
							if (yy < 0 || yy >= h) continue;
							for (var dx:int = -1; dx <= 1; dx++) {
								var xx:int = x + dx;
								if (xx < 0 || xx >= w) continue;
								if (src[yy * w + xx] != 0) { hit = true; break; }
							}
						}
						// last pass of a 3px outline is soft, like RotMG's glow
						if (hit) px[i] = (passes >= 3 && p == passes - 1) ? 0x66000000 : OUTLINE_COL;
					}
				}
			}
			bd.setVector(bd.rect, px);
		}

		public static function shade(c:uint, f:Number):uint {
			var r:int = Math.min(255, ((c >> 16) & 255) * f);
			var g:int = Math.min(255, ((c >> 8) & 255) * f);
			var b:int = Math.min(255, (c & 255) * f);
			return (r << 16) | (g << 8) | b;
		}

		private static function tint(c:uint, t:Number):uint {
			var r:int = ((c >> 16) & 255) + (255 - ((c >> 16) & 255)) * t;
			var g:int = ((c >> 8) & 255) + (255 - ((c >> 8) & 255)) * t;
			var b:int = (c & 255) + (255 - (c & 255)) * t;
			return (r << 16) | (g << 8) | b;
		}

		/** Pre-rotated frames of a projectile shape (index by angle). */
		public static function projectile(shape:String, color:uint, scale:int):Vector.<BitmapData> {
			var key:String = "p_" + shape + "_" + color + "_" + scale;
			var frames:Vector.<BitmapData> = cache[key];
			if (frames) return frames;
			var rows:Array = PROJ[shape] || P_ORB;
			var pal:Object = {C: color, a: shade(color, 0.6), W: tint(color, 0.75), S: 0x8a5a2a, H: 0xe8e8e8, F: color};
			var base:BitmapData = build(rows, pal, scale, 1);
			var D:int = Math.ceil(Math.sqrt(base.width * base.width + base.height * base.height));
			frames = new Vector.<BitmapData>(ROT_FRAMES, true);
			var m:Matrix = new Matrix();
			for (var i:int = 0; i < ROT_FRAMES; i++) {
				var bd:BitmapData = new BitmapData(D, D, true, 0);
				m.identity();
				m.translate(-base.width / 2, -base.height / 2);
				m.rotate(i * Math.PI * 2 / ROT_FRAMES);
				m.translate(D / 2, D / 2);
				bd.draw(base, m, null, null, null, false);
				frames[i] = bd;
			}
			cache[key] = frames;
			return frames;
		}

		public static function frameFor(angle:Number):int {
			var f:int = Math.round(angle / (Math.PI * 2) * ROT_FRAMES) % ROT_FRAMES;
			return f < 0 ? f + ROT_FRAMES : f;
		}

		public static function spark(color:uint):BitmapData {
			var key:String = "sp" + color;
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			bd = new BitmapData(6, 6, true, OUTLINE_COL);
			bd.fillRect(new Rectangle(1, 1, 4, 4), 0xff000000 | color);
			cache[key] = bd;
			return bd;
		}

		/** Inventory icon (36x36). */
		public static function icon(item:Object):BitmapData {
			var key:String = "icon_" + item.kind + "_" + (item.sub || "") + "_" + item.tier + "_" + (item.rarity || "");
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			var tc:uint = item.rarity ? Data.RARITY_COLORS[item.rarity] : TIER_COLORS[Math.min(item.tier, 8)];
			var rows:Array, pal:Object;
			switch (item.kind) {
				case "weapon":
					rows = item.sub == "staff" ? I_STAFF : item.sub == "bow" ? I_BOW : item.sub == "sword" ? I_SWORD : item.sub == "dagger" ? I_DAGGER : I_WAND;
					pal = {T: tc, L: tint(tc, 0.6), W: 0x8a5a2a, S: 0xe0e0e0, G: 0xd0a030};
					break;
				case "armor":
					var ac:uint = item.sub == "heavy" ? 0x9090a0 : item.sub == "leather" ? 0x8a5a2a : 0x4050b0;
					rows = I_ARMOR;
					pal = {T: tc, A: ac, a: shade(ac, 0.7)};
					break;
				case "ability":
					var ab:Object = {spell: I_SPELL, quiver: I_QUIVER, shield: I_SHIELD, tome: I_TOME, cloak: I_CLOAK, helm: I_HELM, skull: I_SKULLITEM, trap: I_TRAP};
					rows = ab[item.sub] || I_TOME;
					var main:uint = item.sub == "shield" || item.sub == "helm" ? 0x8a8a96 : item.sub == "cloak" ? 0x4a2a6a : item.sub == "trap" ? 0x6a5a3a : 0x8a2a2a;
					pal = {T: tc, B: item.sub == "spell" ? 0x8a6a40 : 0x5a3a20, A: main, a: shade(main, 0.65), W: 0xf0e8d0};
					break;
				case "ring":
					rows = I_RING;
					pal = {T: Data.STAT_COLORS[item.sub], L: 0xffffff, G: item.tier >= 4 ? 0xf0c030 : 0xc0c0c8};
					break;
				case "material":
					rows = I_SOR;
					pal = {C: 0xa060ff, c: 0x6a30c0, W: 0xf0d8ff};
					break;
				default:
					rows = I_POT;
					pal = {W: 0x8a5a2a, G: 0xc8c8c8, L: 0xffffff, P: item.color || 0xff3030, p: shade(item.color || 0xff3030, 0.65)};
			}
			bd = build(rows, pal, 4, 2);
			cache[key] = bd;
			return bd;
		}
	}
}
