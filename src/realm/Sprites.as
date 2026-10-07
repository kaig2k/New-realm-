package realm {
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * All art lives here as tiny text pixel grids. They're scaled up and get
	 * a thin dark outline -- the RotMG look.
	 */
	public class Sprites {
		public static const SCALE:int = 5;
		public static const ROT_FRAMES:int = 32;
		private static const OUTLINE_COL:uint = 0xff000000;
		private static var cache:Object = {};

		// ================================================================ classes
		// Every class: [stand, walk, attack]. They face right.
		// RotMG "lofi" style: big hooded head, pale face with two eyes, narrow shaded body,
		// 1px weapon at the side. Frames: stand, walk, attack.
		private static const WIZARD:Array = [
			["...RR..G", "..RRRr.Y", ".rSESEr.", "..SSSS.Y", "RRRWWRRS", ".rRWWRrY", ".rRRRRr.", "..B..B.."],
			["...RR..G", "..RRRr.Y", ".rSESEr.", "..SSSS.Y", "RRRWWRRS", ".rRWWRrY", ".rRRRRr.", ".B....B."],
			["...RR...", "..RRRr..", ".rSESEr.", "..SSSS.G", "RRRWWRSY", ".rRWWRY.", ".rRRRRr.", "..B..B.."]];
		private static const ARCHER:Array = [
			["..GGGg.W", ".GGGGGgW", ".gSESEg.", "..SSSS.W", "gLLLLLgS", ".gLllLgW", ".gLLLLg.", "..B..B.."],
			["..GGGg.W", ".GGGGGgW", ".gSESEg.", "..SSSS.W", "gLLLLLgS", ".gLllLgW", ".gLLLLg.", ".B....B."],
			["..GGGg..", ".GGGGGg.", ".gSESEgW", "..SSSSW.", "gLLLLLSW", ".gLllLW.", ".gLLLLg.", "..B..B.."]];
		private static const KNIGHT:Array = [
			["..HHHH..", ".HHrrHH.", ".HEhEhHW", ".hHHHHhW", "KKMMMMmW", "KQKMMmSA", "KKMMMMm.", "..B..B.."],
			["..HHHH..", ".HHrrHH.", ".HEhEhHW", ".hHHHHhW", "KKMMMMmW", "KQKMMmSA", "KKMMMMm.", ".B....B."],
			["..HHHH..", ".HHrrHH.", ".HEhEhH.", ".hHHHHh.", "KKMMMMm.", "KQKMMmSW", "KKMMMMmW", "..B..B.."]];
		private static const PRIEST:Array = [
			["..WWWw..", ".WWWWWwG", ".wSESEwY", "..SSSS.Y", "wWWYWWwS", ".wYYYWwY", ".wWYWWw.", "..B..B.."],
			["..WWWw..", ".WWWWWwG", ".wSESEwY", "..SSSS.Y", "wWWYWWwS", ".wYYYWwY", ".wWYWWw.", ".B....B."],
			["..WWWw..", ".WWWWWw.", ".wSESEw.", "..SSSS.G", "wWWYWWSY", ".wYYYWY.", ".wWYWWw.", "..B..B.."]];

		private static const ROGUE:Array = [
			["..PPPp..", ".PPPPPp.", ".pSESEp.", "..KKKK..", "kKKKKKkS", ".kKPPKkW", ".kKKKKk.", "..B..B.."],
			["..PPPp..", ".PPPPPp.", ".pSESEp.", "..KKKK..", "kKKKKKkS", ".kKPPKkW", ".kKKKKk.", ".B....B."],
			["..PPPp..", ".PPPPPp.", ".pSESEp.", "..KKKK..", "kKKKKKSW", ".kKPPKW.", ".kKKKKk.", "..B..B.."]];
		private static const WARRIOR:Array = [
			["Y.HHHH.Y", "YHHHHHHY", ".HEhEhH.", ".hHHHHhW", "RRMMMMmW", "RMMMMmSA", ".RMMMMm.", "..B..B.."],
			["Y.HHHH.Y", "YHHHHHHY", ".HEhEhH.", ".hHHHHhW", "RRMMMMmW", "RMMMMmSA", ".RMMMMm.", ".B....B."],
			["Y.HHHH.Y", "YHHHHHHY", ".HEhEhH.", ".hHHHHh.", "RRMMMMm.", "RMMMMmSW", ".RMMMMmW", "..B..B.."]];
		private static const NECRO:Array = [
			["..DDDd.G", ".DDDDDdW", ".dSESEd.", "..SSSS.W", "dDDKDDdS", ".dKKKDdW", ".dDKDDd.", "..B..B.."],
			["..DDDd.G", ".DDDDDdW", ".dSESEd.", "..SSSS.W", "dDDKDDdS", ".dKKKDdW", ".dDKDDd.", ".B....B."],
			["..DDDd..", ".DDDDDd.", ".dSESEd.", "..SSSS.G", "dDDKDDSW", ".dKKKDW.", ".dDKDDd.", "..B..B.."]];
		private static const HUNTRESS:Array = [
			["..RRRr.W", ".RRRRRrW", "RrSESErW", "R.SSSS.W", "gGGGGGgS", ".gGLLGgW", ".gGGGGg.", "..B..B.."],
			["..RRRr.W", ".RRRRRrW", "RrSESErW", "R.SSSS.W", "gGGGGGgS", ".gGLLGgW", ".gGGGGg.", ".B....B."],
			["..RRRr..", ".RRRRRr.", "RrSESErW", "R.SSSSW.", "gGGGGGSW", ".gGLLGW.", ".gGGGGg.", "..B..B.."]];

		// ================================================================ enemies
		private static const HUMANOID:Array = [["..HHHh..", ".HHHHHh.", ".hSESEh.", "..SSSS.W", "bBBBBBbS", ".bBAABbW", ".bBBBBb.", "..L..L.."]];
		private static const BRUTE:Array = [[".hHHHHh.", "hHHHHHHh", "hHEHHEHh", ".hHHHHh.", "bBBBBBBS", "bBBAABbW", ".bBBBBb.", ".LL..LL."]];
		private static const MAGE:Array = [["...HH..G", "..HHHh.W", ".hSESEhW", "..SSSS.W", "bBBBBBbS", "bBBABBbW", "bBBBBBBb", "..L..L.."]];
		private static const SNAKE:Array = [["........", "....GGg.", "...GEGGg", "...GGg..", "..GGg...", ".GGg.GGg", ".gGGGGg.", "........"]];
		private static const CRAB:Array = [["C......C", "Cc....cC", ".C.EE.C.", "..cCCc..", ".cCCCCc.", "cCCCCCCc", ".c.cc.c.", "c......c"]];
		private static const BLOB:Array = [["..bBBb..", ".bBBBBb.", "bBWWWWBb", "bBWEEWBb", "bBWEEWBb", "bBWWWWBb", ".bBBBBb.", "..bBBb.."]];
		private static const DJINN:Array = [["..cCCc..", ".cCCCCc.", ".cECCEc.", ".cCCCCc.", "..cCCc..", "...cC...", "..cC....", ".cC....."]];
		private static const ENT:Array = [[".gGGGGg.", "gGGLGGGg", "gGEGGEGg", "gGGGGGGg", ".gGTTGg.", "...TT...", "..tTTt..", ".tT..Tt."]];
		private static const MEDUSA:Array = [["G.G..G.G", ".gGGGGg.", "gGSSSSGg", ".gSEESg.", "..SSSS..", ".bBBBBb.", "..bBBb..", ".bBBBBb."]];
		private static const CUBELET:Array = [["........", ".pPPPPp.", ".PQQQQp.", ".PQEEQp.", ".PQEEQp.", ".PQQQQp.", ".pppppp.", "........"]];


		// ================================================================ world objects
		private static const TREE:Array = [["...gggggg...", ".ggGGGGGGgg.", "gGGGLGGLGGGg", "gGGLLGGLLGGg", "gGGGGGGGGGGg", "ggGGGGGGGGgg", "gGGGGggGGGGg", ".gGGggggGGg.", "..ggg..ggg..", ".....TT.....", ".....TT.....", "....tTTt...."]];
		private static const PINE:Array = [[".....gg.....", "....gGGg....", "....gLLg....", "...gGGGGg...", "..ggGLLGgg..", "...gGGGGg...", "..gGGGGGGg..", ".ggGGLLGGgg.", "..gGGGGGGg..", ".gGGGGGGGGg.", "ggggGGGGgggg", ".....TT.....", "....tTTt...."]];
		private static const PALM:Array = [["..GG....GG..", ".GLLG..GLLG.", "G...GGGG...G", "...GLLLLG...", "..G..TT..G..", ".G...T....G.", ".....T......", "......T.....", "......T.....", "......T.....", ".....tTt...."]];
		private static const ROCK:Array = [["...kKKk..", "..kKLLKk.", ".kKLKKKKd", "kKKKKKKdd", ".kkkkkdd."]];
		private static const BOULDER:Array = [["...kKKKk...", "..kKLLKKk..", ".kKLLKKKKd.", "kKKLKKKKKdd", "kKKKKKKKddd", ".kKKKKKdddd", "..kkkdddd.."]];
		private static const DEADTREE:Array = [["W....W..W...", ".W...W.W..W.", "..W..WW..W..", "...WWW..W...", "W...WW.W....", ".WW.WWW.....", "...WWW......", "....WW......", "....WW......", "....WW......", "...wWWw....."]];
		private static const PILLAR:Array = [[".L.LL...", "LLLLLLl.", ".SSSSs..", ".SLSSs..", ".SLSSs..", ".SLSSs..", ".SLSSs..", ".SLSSs..", ".SSSSs..", "LLLLLLl.", "sssssss."]];
		private static const BANNER:Array = [["SSSSSSSS", ".RRRRRR.", ".RYYYYR.", ".RYRRYR.", ".RRYYRR.", ".RYRRYR.", ".RRRRRR.", ".RR..RR.", ".R....R.", "...ss..."]];
		private static const CRATE:Array = [["KKKKKKKK", "KCCCCCCK", "KCKCCKCK", "KCCKKCCK", "KCCKKCCK", "KCKCCKCK", "KCCCCCCK", "KKKKKKKK"]];
		private static const SHRINE:Array = [["...OO...", "..OHOo..", "..OOOo..", "...oo...", "..SSSS..", "...ss...", "...SS...", "...ss...", ".SSSSSS.", "ssssssss"]];
		private static const TENT:Array = [["....K....", "...KCK...", "..KCCcK..", "..KCCcK..", ".KCCDccK.", ".KCCDDcK.", "KCCCDDccK", "KKKKDDKKK"]];
		private static const CAMPFIRE:Array = [["...Y....", "..YFY...", "..FYWF..", ".FYWYF..", "..FYF...", "KkKkKkK.", ".kKkKk.."]];
		private static const TOTEM:Array = [["R.KKKK.R", "RKEKKEKR", ".KKKKKK.", ".KkRRkK.", ".KKKKKK.", ".KEKKEK.", ".KKRRKK.", ".KkkkkK.", ".KKKKKK.", "..kkkk.."]];
		private static const RUINWALL:Array = [["..LL....", ".LLLLL..", "LSSlSSL.", "SSlSSSSl", "lSSSlSSl", "SSSlSSSS", "lllllllL"]];
		private static const BRAZIER:Array = [["..Y.F...", "...FYF..", "..FYWYF.", "..FYYF..", ".SSSSSS.", "..sSSs..", "...SS...", "..sSSs.."]];
		private static const CHEST:Array = [["........", ".KKKKKK.", "KCCCCCCK", "KCcYYcCK", "KKKKKKKK", "KCCYYCCK", "KCcCCcCK", "KKKKKKKK"]];
		private static const PORTAL:Array = ["..aaaa..", ".abbbba.", "abccccba", "abcddcba", "abcddcba", "abccccba", ".abbbba.", "..aaaa.."];
		private static const ANVIL:Array = [["...CC...", "..CWCc..", "........", "KKKKKKK.", "KkkkkkKK", ".KkkkK..", "..KkK...", "KKKKKKK."]];
		private static const QUESTBOARD:Array = [["WWWWWWWW", "WPPPPPPW", "WPLLLPPW", "WPPPPPPW", "WPLLLLPW", "WPPPPPPW", "WWWWWWWW", ".W....W."]];
		private static const WOLF:Array = [["......W.", ".....WWW", "WWWWWWEW", "WWWWWWWW", "wWWWWWW.", ".W.W.W.W", ".W.W.W.W", "........"]];
		private static const BAG:Array = [["...KK...", "..K..K..", "..CCCC..", ".CCCCCC.", "CCCDCCCc", "CCCCCCCc", ".cCCCCc.", "........"]];
		private static const CRYSTAL:Array = [["...WC...", "..WCCc..", ".WCCCcc.", ".CCCCcc.", ".CCCcccD", "..CccD..", "...cD...", "..SSSS.."]];
		private static const NEST:Array = [["...WW...", "..WWWw..", ".WWSWWw.", ".WWWWSw.", ".WSWWWw.", "..WWWw..", "KKKKKKKK", ".KkkkkK."]];
		private static const OWL:Array = [["..B..B..", ".BBBBBB.", "BWEBBEWB", "BBBYYBBB", ".BbBBbB.", ".BbbbbB.", "..BBBB..", "..Y..Y.."]];
		private static const DRAKE:Array = [["......R.", ".R..RRR.", "RRR.RERR", ".RRRRRRR", "..RRRrR.", "..RrrrR.", "..RR.RR.", "........"]];
		private static const WISP:Array = [["...WW...", "..WCCW..", ".WCEECW.", ".WCCCCW.", "..WCCW..", "...WC...", "....W...", "...W...."]];
		private static const SPIDER:Array = [["........", "B.B..B.B", ".B.BB.B.", "..BEEB..", "BBBBBBBB", "..BbbB..", ".B.BB.B.", "B......B"]];
		private static const SCORPION:Array = [["......T.", ".....T.T", "......T.", "C.....T.", "CC.SSTT.", ".SSESSS.", "SSSSSSS.", ".S.S.S.."]];
		private static const MOTH:Array = [["W......W", "WW.AA.WW", "WwWAAWwW", "WWWEEWWW", "WwWAAWwW", "WW.AA.WW", "W..AA..W", "...A.A.."]];
		private static const GHOST:Array = [["..WWWW..", ".WWWWWW.", "WWEWWEWW", "WWEWWEWW", "WWWWWWWW", "WWWwwWWW", "WWWWWWWW", "W.W.W.W."]];
		private static const DEMON:Array = [["H......H", "HH.RR.HH", ".RRRRRR.", ".RYRRYR.", ".RRRRRR.", "RRrRRrRR", ".RRrrRR.", ".RR..RR."]];
		private static const FAIRY:Array = [["W..CC..W", "WW.CC.WW", "WWCEECWW", "WwCCCCwW", "W.CCCC.W", "..CccC..", "..C..C..", "........"]];
		private static const BIRD:Array = [["...HH...", "W.HEEH.W", "WWHHHHWW", "WWWBBWWW", "W.BBBB.W", "..BBBB..", "...BB...", "..Y..Y.."]];
		// ================================================================ bosses (16x16, 2-frame idle)
		private static const BOSS_ELDER:Array = [
			["................", ".H............H.", ".HH....PP....HH.", "..hHPPPPPPPPHh..", "...PPPPPPPPPP...", "..PPPKKKKKKPPP..", "..PPKKEKKEKKPP..", "p.PPPKKKKKKPPP.p", "pp.QPPPPPPPPQ.pp", "ppp.QPPPPPPQ.ppp", "pppp.QPOOPQ.pppp", ".ppp.PQOOQP.ppp.", "..pp.PPQQPP.pp..", ".....PPPPPP.....", "....PPPPPPPP....", "...pPPPPPPPPp..."],
			["................", ".H............H.", ".HH....PP....HH.", "..hHPPPPPPPPHh..", "...PPPPPPPPPP...", "..PPPKKKKKKPPP..", "..PPKKWKKWKKPP..", "pp.PPKKKKKKPP.pp", "ppp.QPPPPPPQ.ppp", "pppp.QPPPPQ.pppp", "ppp..QPOOPQ..ppp", ".pp..PQOOQP..pp.", "..p..PPQQPP..p..", ".....PPPPPP.....", "....PPPPPPPP....", "...pPPPPPPPPp..."]];
		private static const BOSS_BOSS:Array = [
			["...Y...YY...Y...", "...YY.YYYY.YY...", "....yYYyyYYy....", "......QQQQ......", "....QQQQQQQQ....", "..QQQQQQQQQQQQ..", "PPQQQQQQQQQQQQpp", "PPPPQQQQQQQQpppp", "PPPPPPQQQQpppppp", "PPPPWWWWWWWWpppp", "PPPWWWEEEEWWWppp", "PPPWWEEKKEEWWppp", "PPPPWWEEEEWWpppp", "PPPPPPWWWWpppppp", "..PPPPPPpppppp..", "....PPPPpppp...."],
			["................", "...Y...YY...Y...", "...YY.YYYY.YY...", "......QQQQ......", "....QQQQQQQQ....", "..QQQQQQQQQQQQ..", "PPQQQQQQQQQQQQpp", "PPPPQQQQQQQQpppp", "PPPPPPQQQQpppppp", "PPPPWWWWWWWWpppp", "PPPWWEEEEWWWWppp", "PPPWEEKKEEWWWppp", "PPPPWEEEEWWWpppp", "PPPPPPWWWWpppppp", "..PPPPPPpppppp..", "....PPPPpppp...."]];
		private static const BOSS_TITAN:Array = [
			["................", ".....RRRRRR.....", "....RrrRRrrR....", "....rYrrrrYr....", "....rrrLLrrr....", ".RRR.rrrrrr.RRR.", "RRrrRRRrrRRRrrRR", "RrLrrrLrrLrrrLrR", "Rrr.rLrrrrLr.rrR", "rLr.rrrLLrrr.rLr", "rrr.rrrrrrrr.rrr", "YYY.Rrr..rrR.YYY", "YY..RrrRRrrR..YY", "....Rr....rR....", "...RRr....rRR...", "...rrr....rrr..."],
			["................", ".....RRRRRR.....", "....RrrRRrrR....", "....rYrrrrYr....", "....rrrYYrrr....", ".RRR.rrrrrr.RRR.", "RRrrRRRrrRRRrrRR", "RrYrrrYrrYrrrYrR", "Rrr.rYrrrrYr.rrR", "rYr.rrrYYrrr.rYr", "rrr.rrrrrrrr.rrr", "LLL.Rrr..rrR.LLL", "YY..RrrRRrrR..YY", "....Rr....rR....", "...RRr....rRR...", "...rrr....rrr..."]];
		private static const BOSS_WYRM:Array = [
			["..........CC....", ".........CCWC...", "........CCEcC...", "WW......cCCCCK..", "WwW......cCC....", "WwwW....CCc.....", ".WwwW..CCc..WWW.", "..WwwWCCCc.WwwW.", "...WwCCCCcWwwW..", "....CCcCCCCwW...", "...CCc.cCCCC....", "..CCc...cCCCc...", "..CCc..cCCCCC...", "...CCcCCCc.cCC..", "....cCCCc....cC.", "..............c."],
			["..........CC....", ".........CCWC...", "........CCEcC...", "........cCCCCK..", "WW.......cCC....", "WwWW....CCc..WW.", ".WwwW..CCc.WWwW.", "..WwwWCCCcWwwW..", "...WwCCCCcWwW...", "....CCcCCCCwW...", "...CCc.cCCCC....", "..CCc...cCCCc...", "..CCc..cCCCCC...", "...CCcCCCc.cCC..", "....cCCCc....cC.", "..............c."]];
		private static const BOSS_HOLLOWKING:Array = [
			["....Y.Y..Y.Y....", "....YYYYYYYY....", "....YGYYYYGY..GW", "....BBBBBBBB..Y.", "...BBBBBBBBBB.Y.", "...BEEBBBBEEB.Y.", "...BBBBTTBBBB.Y.", "....BTBTTBTB..Y.", "PP..PBBBBBBP..Y.", "PPPPPBTBBTBPPPY.", ".PPPPBBBBBBPPPY.", "..PPPPBPPBPPPPY.", "..PPPPPPPPPPPPY.", "...PPPPPPPPPP...", "...PP.PPPP.PP...", "...P..P..P..P..."],
			["....Y.Y..Y.Y....", "....YYYYYYYY....", "....YGYYYYGY..GW", "....BBBBBBBB..Y.", "...BBBBBBBBBB.Y.", "...BGGBBBBGGB.Y.", "...BBBBTTBBBB.Y.", "....BTBTTBTB..Y.", "PP..PBBBBBBP..Y.", "PPPPPBTBBTBPPPY.", ".PPPPBBBBBBPPPY.", "..PPPPBPPBPPPPY.", "..PPPPPPPPPPPPY.", "...PPPPPPPPPP...", "...PP.PPPP.PP...", "...P..P..P..P..."]];
		private static const BOSS_BEHEMOTH:Array = [
			["W..............W", "WW............WW", ".WW..GGGGGG..WW.", "..WGGGGGGGGGGW..", "...GgGGGGGGgG...", "..GGgEgGGgEgGG..", "..GGGgggggGGGG..", ".GGGTGgRRgGTGGG.", "GGGG.TgggT.GGGGG", "GGgGG..gg..GGgGG", "GgggGGGGGGGGgggG", "Ggg.GGgggggG.ggG", "gg..GgggggggG.gg", "....Ggg..ggG....", "...GGg....gGG...", "...ggg....ggg..."],
			["W..............W", "WW............WW", ".WW..GGGGGG..WW.", "..WGGGGGGGGGGW..", "...GgGGGGGGgG...", "..GGgEgGGgEgGG..", "..GGGgggggGGGG..", ".GGGTGgrrgGTGGG.", "GGGG.TgggT.GGGGG", "GGgGG..gg..GGgGG", "GgggGGGGGGGGgggG", "Ggg.GGgggggG.ggG", "gg..GgggggggG.gg", "....Ggg..ggG....", "..GGg......gGG..", "..ggg......ggg.."]];
		private static const BOSS_REGENT:Array = [
			["......YYYY......", ".....YyYYyY.....", "....CCCCCCCC....", "...CQQQQQQQQC...", "..C.QEQQQQEQ.C..", ".CC.QQQQQQQQ.CC.", "CCc..QQQQQQ..cCC", "Cc.cMMMMMMMMc.cC", "c..cMmMMMMmMc..c", "...cMMmMMmMMc...", "...cMMMMMMMMc...", "....MMMMMMMM....", ".....MMMMMM.....", "......MMMM......", ".......MM.......", "......M..M......"],
			["......YYYY......", ".....YyYYyY.....", "....CCCCCCCC....", "...CQQQQQQQQC...", "..C.QWQQQQWQ.C..", ".CC.QQQQQQQQ.CC.", "CCc..QQQQQQ..cCC", "Cc.cMMMMMMMMc.cC", "c..cMmMMMMmMc..c", "...cMMmMMmMMc...", "...cMMMMMMMMc...", "....MMMMMMMM....", ".....MMMMMM.....", ".....MM..MM.....", "......M..M......", ".......MM......."]];
		private static const BOSS_SPHINX:Array = [
			["...BYBYBY.......", "..BYBYBYBY......", "..YSSSSSSB......", "..BSESSESY......", "..YSSSSSSB......", "..BYSSSSYY......", "...BYSSYB.......", "....TTTTTTTTTT..", "...TTTTTTTTTTTT.", "..TTtTTTTTTTTTTt", "..TtTTTTTTTTTTt.", "..TT.TTTTTTTT...", "..TT..TT..TT.TT.", ".TTT.TTT.TTTTTT.", ".ttt.ttt.ttt.ttt", "................"],
			["...BYBYBY.......", "..BYBYBYBY......", "..YSSSSSSB......", "..BSWSSWSY......", "..YSSSSSSB......", "..BYSSSSYY......", "...BYSSYB.......", "....TTTTTTTTTT..", "...TTTTTTTTTTTT.", "..TTtTTTTTTTTTTt", "..TtTTTTTTTTTTt.", "..TT.TTTTTTTT...", "..TT..TT..TT.TT.", ".TTT.TTT.TTTTTT.", ".ttt.ttt.ttt.ttt", "................"]];
		private static const BOSS_SUNKEN_LORD:Array = [
			["..............W.", ".....SSSS....WWW", "....SsSSsS....W.", "....SEsSEs....W.", "....sSSSSs....W.", "..SSSssssSSS..W.", ".SSsSSBSSSsSS.W.", ".SsSSSSSBSSsSSH.", ".Ss.SSBSSSS.sHH.", ".Bs.SSSSBSS..W..", ".ss.SSSSSSS..W..", "....SSs.sSS..W..", "....SSs.sSS..W..", "...SSSs.sSSS.W..", "...sss...sss....", "................"],
			["..............W.", ".....SSSS....WWW", "....SsSSsS....W.", "....SGsSGs....W.", "....sSSSSs....W.", "..SSSssssSSS..W.", ".SSsSSBSSSsSS.W.", ".SsSSSSSBSSsSSH.", ".Ss.SSBSSSS.sHH.", ".Bs.SSSSBSS..W..", ".ss.SSSSSSS..W..", "....SSs.sSS..W..", "....SSs.sSS..W..", "...SSSs.sSSS.W..", "...sss...sss....", "................"]];
		private static const BOSS_HERMIT:Array = [
			[".....SSSSSS.....", "...SSsssssSS....", "..SsSSSSSSsSS...", ".SsSsssssSSsSS..", ".SsSsSSSsSSsSS..", ".SsSsSsSsSSsSS..", ".SsSssSsSSsSS...", ".SSsSSSsSSsSS...", "..SSsssSSsSSCC..", "...SSSSSSSSCECC.", "..CCCSSSSSCCCCCC", ".CCcCC...CcCCcC.", "CCc.Cc..cC.cC.cC", "Cc..c....c..c..c", "c...............", "................"],
			[".....SSSSSS.....", "...SSsssssSS....", "..SsSSSSSSsSS...", ".SsSsssssSSsSS..", ".SsSsSSSsSSsSS..", ".SsSsSsSsSSsSS..", ".SsSssSsSSsSS...", ".SSsSSSsSSsSS...", "..SSsssSSsSSCC..", "...SSSSSSSSCWCC.", "..CCCSSSSSCCCCCC", ".CCcCC...CcCCcC.", "CCc.Cc..cC.cC.C.", ".Cc.c....c..c.c.", "..c.............", "................"]];
		private static const BOSS_SHRINE:Array = [
			["F..............F", "FF....BBBB....FF", "YF...BBBBBB...FY", ".Y..BBBBBBBB..Y.", ".S..BEEBBEEB..S.", ".S..BEEBBEEB..S.", ".S..BBBbbBBB..S.", ".S...BBBBBB...S.", ".S...BTBTBT...S.", ".S....BBBB....S.", "AAAAAAAAAAAAAAAA", "AaaaaaaaaaaaaaaA", "A.RRRRRRRRRRRR.A", "A.R.R.R.R.R.R..A", "AAAAAAAAAAAAAAAA", "aaaaaaaaaaaaaaaa"],
			[".F............F.", "FF....BBBB....FF", "FY...BBBBBB...YF", ".Y..BBBBBBBB..Y.", ".S..BRRBBRRB..S.", ".S..BRRBBRRB..S.", ".S..BBBbbBBB..S.", ".S...BBBBBB...S.", ".S...BTBTBT...S.", ".S....BBBB....S.", "AAAAAAAAAAAAAAAA", "AaaaaaaaaaaaaaaA", "A.RRRRRRRRRRRR.A", "A.R.R.R.R.R.R..A", "AAAAAAAAAAAAAAAA", "aaaaaaaaaaaaaaaa"]];
		private static const BOSS_WARDEN:Array = [
			["......HHHH......", ".....HHHHHH.....", ".....HhHHhH.....", "....HhEhhEhH....", "....HHHHHHHH....", "..AAAMMMMMMAAA..", ".AAMMMMMMMMMM.l.", ".AMmMMmMMmMMm.l.", ".A.MMMmMMmMMMLLL", "...MMMMMMMMMMLLL", "...MmMMMMMMmMLLL", "...MMMMmmMMMM...", "...MM..MM..MM...", "...MM......MM...", "..MMM......MMM..", "..mmm......mmm.."],
			["......HHHH......", ".....HHHHHH.....", ".....HhHHhH.....", "....HhGhhGhH....", "....HHHHHHHH....", "..AAAMMMMMMAAA..", ".AAMMMMMMMMMM.l.", ".AMmMMmMMmMMm.l.", ".A.MMMmMMmMMMGGG", "...MMMMMMMMMMGGG", "...MmMMMMMMmMGGG", "...MMMMmmMMMM...", "...MM..MM..MM...", "...MM......MM...", "..MMM......MMM..", "..mmm......mmm.."]];
		private static const BOSS_PYRELORD:Array = [
			[".......FF.......", "......FFFF......", "..F..FYFFYF..F..", "..FF.FYYYYF.FF..", "...FFYYYYYYFF...", ".F.FYYWYYWYYF.F.", ".FFFYYKWWKYYFFF.", "..FYYYYYYYYYYF..", "F.FYYYKKKKYYYF.F", "FFFYYYYYYYYYYFFF", ".FRFYYYYYYYYFRF.", "..RRFYYYYYYFRR..", "...RRFFYYFFRR...", "....RRFFFFRR....", ".....RRRRRR.....", "......RRRR......"],
			["......F..F......", ".F...F.FF.F...F.", ".FF..FFYYFF..FF.", "..FF.FYYYYF.FF..", "...FFYYYYYYFF...", ".F.FYYWYYWYYF.F.", ".FFFYYKWWKYYFFF.", "..FYYYYYYYYYYF..", "F.FYYYKKKKYYYF.F", "FFFYYYYYYYYYYFFF", ".FRFYYYYYYYYFRF.", "..RRFYYYYYYFRR..", "...RRFFYYFFRR...", "....RRFFFFRR....", ".....RRRRRR.....", "......RRRR......"]];
		private static const BOSS_SERAPH:Array = [
			[".....YYYYYY.....", "....Y..YY..Y....", "W....SSSSSS....W", "WW...SESSES...WW", ".WW..SSSSSS..WW.", "WWWW.GGGGGG.WWWW", ".WWWWGGggGGWWWW.", "..WWWGGGGGGWWW..", "W..WWGgGGgGWW..W", "WW..WGGGGGGW..WW", ".WW..GGggGG..WW.", "..WW.GGGGGG.WW..", "....GGgGGgGG....", "....GGGGGGGG....", "...GGGgGGgGGG...", "...GGGGGGGGGG..."],
			[".....YYYYYY.....", "....Y..YY..Y....", ".W...SSSSSS...W.", "WWW..SESSES..WWW", ".WW..SSSSSS..WW.", "WWW..GGGGGG..WWW", "WWWWWGGggGGWWWWW", "..WWWGGGGGGWWW..", ".W.WWGgGGgGWW.W.", "WWW.WGGGGGGW.WWW", ".WW..GGggGG..WW.", "..WW.GGGGGG.WW..", "....GGgGGgGG....", "....GGGGGGGG....", "...GGGgGGgGGG...", "...GGGGGGGGGG..."]];
		private static const BOSS_SORCERER:Array = [
			[".......HH.......", "......HHHH......", "......HHHH......", ".....HHhhHH.....", "....HHHHHHHH....", "..hHHHHHHHHHHh..", "....SSSSSSSS....", "....SESSSSES....", "....WWWWWWWW....", "...RRWWWWWWRR...", "..RRrWWWWWWrRR..", "..RRRrWOOWrRRR..", "..RRRRROORRRRR..", "...RRRRRRRRRR...", "...RRrRRRRrRR...", "..rrrrrrrrrrrr.."],
			[".......HH.......", "......HHHH......", "......HHHH......", ".....HHhhHH.....", "....HHHHHHHH....", "..hHHHHHHHHHHh..", "....SSSSSSSS....", "....SESSSSES....", "....WWWWWWWW....", "...RRWWWWWWRR...", "..RRrWWWWWWrRR..", "..RRRrWooWrRRR..", "..RRRRRooRRRRR..", "...RRRRRRRRRR...", "...RRrRRRRrRR...", "..rrrrrrrrrrrr.."]];
		private static const BOSS_PIRATE_KING:Array = [
			["....KKKKKKKK....", "..KKKKWKKKKKKK..", ".KKKKKKKKKKKKKK.", "....SSSSSSSS....", "....SEESSEES....", "....SSSSSSSS....", "...BBBSSSSBBB...", "...BBBBBBBBBB...", "..RRBBBBBBBBRR..", ".RRRRBBBBBBRRRR.", "HRRRRRYYYYRRRRRC", ".H.RRRRRRRRRR.CC", "...RRRRRRRRRRC..", "...rrr....rrr...", "...LLL....LLL...", "...LLL....LLL..."],
			["....KKKKKKKK....", "..KKKKWKKKKKKK..", ".KKKKKKKKKKKKKK.", "....SSSSSSSS....", "....SEESSEES....", "....SSSSSSSS....", "...BBBSSSSBBB...", "...BBBBBBBBBB...", "..RRBBBBBBBBRR..", ".RRRRBBBBBBRRRRC", "HRRRRRYYYYRRRRR.", ".H.RRRRRRRRRR.CC", "...RRRRRRRRRRCC.", "...rrr....rrr...", "...LLL....LLL...", "...LLL....LLL..."]];
		private static const BOSS_MOTH:Array = [
			["WW.....AA.....WW", "WwW...A..A...WwW", "WwwW..AAAA..WwwW", "WwOwW.AEEA.WwOwW", "WwwwwWAAAAWwwwwW", ".WwwwwAAAAwwwwW.", "..WWwwAAAAwwWW..", "..WwwwAAAAwwwW..", ".WwOwwAAAAwwOwW.", ".WwwwWAAAAWwwwW.", "..WWW.AAAA.WWW..", "......A..A......", ".....A....A.....", "................", "................", "................"],
			["................", "WW.....AA.....WW", "WwW...A..A...WwW", "WwOW..AAAA..WOwW", "WwwwW.AEEA.WwwwW", ".WwwwwAAAAwwwwW.", "..WWwwAAAAwwWW..", "..WwwwAAAAwwwW..", ".WwOwwAAAAwwOwW.", ".WwwwWAAAAWwwwW.", ".WwWW.AAAA.WWwW.", "......A..A......", ".....A....A.....", "................", "................", "................"]];
		private static const BOSS_SERPENT_QUEEN:Array = [
			[".....Y.Y.Y......", ".....YYYYY......", "....GGGGGGG.....", "....GSESESG.....", "....gSSSSSg.....", "..SS.SSSSS.SS...", ".S..PPPPPPP..S..", ".S..PpPPPpP..S..", "....GGGGGGG.....", ".....GgGgGG.....", "......GGGGGG....", "....GGGGgGGGG...", "..GGGg.....GGG..", ".GGg....GGGGgG..", ".GGGGGGGGgg.....", "..gggggggg......"],
			[".....Y.Y.Y......", ".....YYYYY......", "....GGGGGGG.....", "....GSYSYSG.....", "....gSSSSSg.....", ".SSS.SSSSS.SSS..", "S...PPPPPPP...S.", "....PpPPPpP.....", "....GGGGGGG.....", ".....GgGgGG.....", "......GGGGGG....", "....GGGGgGGGG...", "..GGGg.....GGG..", ".GGg....GGGGgG..", ".GGGGGGGGgg.....", "..gggggggg......"]];
		private static const BOSS_BROODMOTHER:Array = [
			["................", "L..............L", ".L....BBBB....L.", ".L..BBBBBBBB..L.", "..L.BBBBBBBB.L..", "L..LBBRRRRBBL..L", ".L.LBRWRRWRBL.L.", "..LLBBRRRRBBLL..", "....BBBBBBBB....", "..LLbbBBBBbbLL..", ".L..bEEbbEEb..L.", "L..L.bbbbbb.L..L", "..L..L....L..L..", ".L...L....L...L.", "L...L......L...L", "................"],
			["................", "................", "L.....BBBB.....L", ".L..BBBBBBBB..L.", "..L.BBBBBBBB.L..", "L..LBBRRRRBBL..L", ".L.LBRWRRWRBL.L.", "..LLBBRRRRBBLL..", "....BBBBBBBB....", "..LLbbBBBBbbLL..", ".L..bEEbbEEb..L.", "L..L.bbbbbb.L..L", ".L...L....L...L.", "L....L....L....L", "....L......L....", "................"]];
		private static const BOSS_LICH_KING:Array = [
			["....Y.Y..Y.Y....", "....YYYYYYYY....", "....BBBBBBBB....", "...BBBBBBBBBB...", "...BEEBBBBEEB...", "...BBBBBBBBBB...", "....BTBTTBTB....", ".PP.PPPPPPPP.PP.", "PPPPPPPPPPPPPPPP", "Pp.PPPPPPPPPP.pP", "B..PpPPGGPPpP..B", "...PPPGGGGPPP...", "....PPPPPPPP....", ".....PPPPPP.....", "......PPPP......", ".......PP......."],
			["....Y.Y..Y.Y....", "....YYYYYYYY....", "....BBBBBBBB....", "...BBBBBBBBBB...", "...BRRBBBBRRB...", "...BBBBBBBBBB...", "....BTBTTBTB....", ".PP.PPPPPPPP.PP.", "PPPPPPPPPPPPPPPP", "Pp.PPPPPPPPPP.pP", "B..PpPPGGPPpP..B", "...PPPGGGGPPP...", "....PPPPPPPP....", "......PPPP......", ".......PP.......", "................"]];
		private static const BOSS_ARCHDEMON:Array = [
			["H..............H", "HH............HH", ".HH..RRRRRR..HH.", "..HHRRRRRRRRHH..", "W...RYRRRRYR...W", "WW..RRRRRRRR..WW", "WWW.RrrRRrrR.WWW", "WWWWRRRRRRRRWWWW", "WWWWRRRrrRRRWWWW", "WW.RRrRRRRrRR.WW", "W..RRRRRRRRRR..W", "...RRrRRRRrRR...", "....RRRRRRRR....", "....RR.RR.RR....", "...RRR....RRR...", "...rrr....rrr..."],
			["H..............H", "HH............HH", ".HH..RRRRRR..HH.", "..HHRRRRRRRRHH..", "....RFRRRRFR....", "W...RRRRRRRR...W", "WW..RrrRRrrR..WW", "WWW.RRRRRRRR.WWW", "WWWWRRRrrRRRWWWW", "WWWRRrRRRRrRRWWW", "WW.RRRRRRRRRR.WW", "...RRrRRRRrRR...", "....RRRRRRRR....", "....RR.RR.RR....", "...RRR....RRR...", "...rrr....rrr..."]];
		private static const BOSS_SPRITE_QUEEN:Array = [
			["......YYYY......", "W....YYYYYY....W", "WW...HHHHHH...WW", "WwW..HSSSSH..WwW", "WwwW.HESSEH.WwwW", ".WwwW.SSSS.WwwW.", "..WwwCCCCCCwwW..", "WW.WWCCCCCCWW.WW", "WwWW.CcCCcC.WWwW", ".WwW.CCCCCC.WwW.", "..WW.CCccCC.WW..", "....CCCCCCCC....", "...CCcCCCCcCC...", "...C...CC...C...", "................", "................"],
			["......YYYY......", ".....YYYYYY.....", "W....HHHHHH....W", "WW...HSSSSH...WW", "WwW..HESSEH..WwW", "WwwW..SSSS..WwwW", ".WwwWCCCCCCWwwW.", "..WWWCCCCCCWWW..", "WWWW.CcCCcC.WWWW", "WwW..CCCCCC..WwW", "..WW.CCccCC.WW..", "....CCCCCCCC....", "...CCcCCCCcCC...", "...C...CC...C...", "................", "................"]];
		// ================================================================ item icons (8x8: 4 tier designs + a rarity design)
		private static const ICON_SWORD:Array = [[".......H", "......HB", ".....HBb", "....HBb.", ".GGHBb..", "..GGb...", ".W.G....", "W......."], ["......HH", ".....HBB", "....HBBb", "...HBBb.", ".GHBBb..", ".GGGb...", ".WGG....", "P......."], [".......H", ".....HHB", "....HBBb", "...HBbb.", ".RGBb...", ".GRG....", ".WG.....", "W......."], [".....HHH", "....HBHB", "...HBHBb", "..HBHBb.", "GGBHBb..", ".GGBb...", ".WGG....", "PW......"], ["......RH", ".....HBR", "....HRBb", "...HBRb.", "GgHRBb..", ".GgRb...", ".WgG....", "R......."]];
		private static const ICON_DAGGER:Array = [[".......H", "......Hb", ".....Hb.", "....Hb..", "..GG....", "..G.....", ".W......", "W......."], ["......HH", ".....HBb", "....HBb.", "...HBb..", ".GGG....", "..G.....", ".W......", "W......."], [".......R", "......HB", ".....HBb", "....HBb.", "..RGb...", "..GG....", ".W.G....", "W......."], ["......HH", ".....HHB", "....HBBb", "...HBb..", "G.GBb...", ".GGG....", ".W.G....", "P......."], ["......RH", ".....RHB", "....RHBb", "...HBb..", "GgRBb...", ".GgG....", ".W.g....", "R......."]];
		private static const ICON_STAFF:Array = [[".....WW.", "....WWw.", "...W.w..", "...W....", "..W.....", "..W.....", ".W......", "W......."], ["....GRG.", "....RrR.", "....GwG.", "...W....", "..W.....", "..W.....", ".W......", "W......."], ["...G.G..", "...GRG..", "....RG..", "...Wg...", "..W.....", "..W.....", ".W......", "W......."], ["..GRRG..", "..RHRr..", "..GRrG..", "...gG...", "...W....", "..W.....", ".W......", "W......."], [".R.RR.R.", "..RHHR..", ".RHRRrR.", "..RrrR..", "...gG...", "..W.....", ".W......", "R......."]];
		private static const ICON_WAND:Array = [[".......H", "......B.", ".....W..", "....W...", "...W....", "..W.....", ".w......", "........"], ["......RR", "......RR", ".....G..", "....W...", "...W....", "..W.....", ".w......", "........"], ["....R.R.", ".....RR.", "....RHR.", ".....G..", "....W...", "...W....", "..w.....", ".w......"], [".....RRR", ".....RHR", ".....RRG", "....gG..", "...W....", "..W.....", ".W......", "w......."], ["...R.RR.", "....RHHR", "...RHRrR", ".R..RrR.", "....gG..", "...W....", "..W.....", ".R......"]];
		private static const ICON_BOW:Array = [["...WW...", "....W.S.", ".....WS.", ".....WS.", ".....WS.", ".....WS.", "....W.S.", "...WW..."], ["..WWW...", "....WWS.", ".....WS.", "..BBBGBB", ".....WS.", ".....WS.", "....WWS.", "..WWW..."], ["..GWW...", "...GWW.S", ".....WWS", "..BBBRBH", ".....WWS", "...GWW.S", "..GWW...", "........"], [".GGW....", "..GWW..S", "....WW.S", ".BBBRRBH", "....WW.S", "..GWW..S", ".GGW....", "........"], [".RRW....", "..RWW..S", "...RWW.S", ".BBRHRBH", "...RWW.S", "..RWW..S", ".RRW....", "........"]];
		private static const ICON_SPELL:Array = [["..BBBB..", ".BHHHHB.", ".BHRRHB.", ".BHHHHB.", ".BHRRHB.", ".BHHHHB.", "..BBBB..", "........"], [".RBBBBR.", "RBHHHHBR", ".BHRRHB.", ".BRHHRB.", ".BHRRHB.", "RBHHHHBR", ".RBBBBR.", "........"]];
		private static const ICON_QUIVER:Array = [[".H.H.H..", ".W.W.W..", "BBBBBBB.", "BbbbbbB.", "BBGGGBB.", "BbbbbbB.", "BBBBBBB.", ".BBBBB.."], ["RH.RH.R.", ".W.W.W..", "BBBBBBB.", "BRbbbRB.", "BBGRGBB.", "BRbbbRB.", "BBBBBBB.", ".BBBBB.."]];
		private static const ICON_SHIELD:Array = [["BBBBBBBB", "BHHHHHHb", "BHGGGGHb", "BHGHHGHb", "BHGGGGHb", ".BHHHHb.", "..BHHb..", "...Bb..."], ["GBBBBBBG", "BHRRRRHb", "BRHGGHRb", "BRGRRGRb", "BRHGGHRb", ".BRRRRb.", "..BHHb..", "...GG..."]];
		private static const ICON_TOME:Array = [[".BBBBBB.", "BbbbbbbW", "BbGGGbbW", "BbGHGbbW", "BbGGGbbW", "BbbbbbbW", ".BBBBBBW", "........"], [".GBBBBG.", "BbRRRbbW", "BRGHGRbW", "BRHRHRbW", "BRGHGRbW", "BbRRRbbW", ".GBBBBGW", "........"]];
		private static const ICON_CLOAK:Array = [["..BBBB..", ".BBBBBB.", "BBbGGbBB", "BBbbbbBB", "BBBBBBBB", "BBbBBbBB", "BbBBBBbB", "b.bBBb.b"], ["..BBBB..", ".BRBBRB.", "BBbGGbBB", "BRbbbbRB", "BBBRRBBB", "BBbBBbBB", "BRBBBBRB", "b.bBBb.b"]];
		private static const ICON_HELM:Array = [["...HH...", "..HBBH..", ".HBBBBb.", "HBBBBBBb", "BBbbbbBb", "BB.bb.Bb", ".B.bb.b.", "........"], ["R..HH..R", "RRHBBHRR", ".HBBBBb.", "HBGGGGBb", "BBbbbbBb", "BBRbbRBb", ".B.bb.b.", "........"]];
		private static const ICON_SKULL:Array = [["..HHHH..", ".HHHHHHb", "HHRHHRHb", "HHRHHRHb", "HHHHHHHb", ".HHbbHb.", "..H.H.b.", "..HbHb.."], [".RHHHHR.", ".HHHHHHb", "HHRHHRHb", "HRRHHRRb", "HHHHHHHb", ".HHbbHb.", "R.H.H.bR", "..HbHb.."]];
		private static const ICON_TRAP:Array = [["H..H..H.", ".HBBBBH.", ".BBbbBB.", "HBbGGbBH", "HBbGGbBH", ".BBbbBB.", ".HBBBBH.", "H..H..H."], ["R..R..R.", ".RBBBBR.", ".BBbbBB.", "RBbRRbBR", "RBbRRbBR", ".BBbbBB.", ".RBBBBR.", "R..R..R."]];
		private static const ICON_ROBE:Array = [[".BB..BB.", "BBBGGBBB", "bBBGGBBb", ".BBGGBB.", ".BBGGBB.", ".BBGGBB.", ".BBGGBB.", ".bBBBBb."], [".BB..BB.", "BBRGGRBB", "bBBGGBBb", ".BRGGRB.", ".BBGGBB.", ".BRGGRB.", ".BBGGBB.", ".bRBBRb."]];
		private static const ICON_LEATHER:Array = [[".BB..BB.", "BBBbbBBB", "bBBBBBBb", ".BGGGGB.", ".BBbbBB.", ".BBBBBB.", ".bBBBBb.", "........"], [".BB..BB.", "BBRbbRBB", "bBBBBBBb", ".BGRRGB.", ".BBbbBB.", ".BRBBRB.", ".bBBBBb.", "........"]];
		private static const ICON_HEAVY:Array = [["HH....HH", "BBHBBHBB", "bBBHHBBb", ".BBBBBB.", ".BbBBbB.", ".BBGGBB.", ".bBBBBb.", "........"], ["RH....HR", "BBHBBHBB", "bBRHHRBb", ".BBRRBB.", ".BbBBbB.", ".BBGGBB.", ".bRBBRb.", "........"]];
		private static const ICON_RING:Array = [["...RR...", "..RHrR..", "..RRrr..", ".G.gg.G.", "G......g", "G......g", ".G....g.", "..GGgg.."], ["..R.R...", ".RRHRR..", "..RrrR..", ".GG..GG.", "G......g", "G......g", ".G....g.", "..GGgg.."]];
		private static const ICON_POT:Array = [["...WW...", "..GGGG..", "...HG...", "..PHPP..", ".PHPPPp.", ".PPPPPp.", ".PPPPpp.", "..pppp.."]];
		private static const ICON_STATPOT:Array = [["...WW...", "...GG...", "..GHGG..", ".GPHPPG.", "GPPHPPpG", "GPPPPPpG", ".GPPPpG.", "..GGGG.."]];
		private static const ICON_SOR:Array = [["...CC...", "..CWCC..", ".CWCCCc.", "CWCCCCcc", ".CCCCcc.", "..CCcc..", "...cc...", "........"]];
		private static const ICON_TIERS:Array = [{B: 0x9a9aa2, b: 0x5a5a62, H: 0xd8d8e0, G: 0x8a6a3a, g: 0x5a4422, R: 0xa0a0a8, W: 0x8a5a2a, w: 0x5a3a18, P: 0x6a6a72, S: 0xd8d8d8}, {B: 0xb8c8dc, b: 0x6a7a90, H: 0xf0f8ff, G: 0xa8a8b4, g: 0x6a6a78, R: 0x60c0ff, W: 0x7a4a24, w: 0x4a2a10, P: 0x9a9aa8, S: 0xe8e8e8}, {B: 0xd8d8e8, b: 0x8a8aa0, H: 0xffffff, G: 0xf0c030, g: 0xa07810, R: 0xff4040, W: 0x6a3a1a, w: 0x3a2010, P: 0xf0c030, S: 0xf0f0f0}, {B: 0x9ad8f0, b: 0x4a8aa8, H: 0xf0ffff, G: 0x8040c0, g: 0x502080, R: 0x60ffd0, W: 0x3a2a4a, w: 0x201428, P: 0x8040c0, S: 0xf0ffff}];
		private static const ICON_ABIL:Object = {spell: [0x6a3a8a, 0xe8e0c8], quiver: [0x8a5a2a, 0xc0c0c0], shield: [0x5a6a9a, 0xd8d8e0], tome: [0x9a2a2a, 0xe8e0c8], cloak: [0x4a2a6a, 0xc8c8c8], helm: [0x9a9aa6, 0xe0e0e8], skull: [0x8a8070, 0xe8e0c8], trap: [0x5a5a62, 0xa0a0a8]};
		private static const ICON_ARMOR:Object = {robe: [0x3a5ab0, 0x6a3a9a, 0xa02a3a, 0x202034], leather: [0x8a5a2a, 0x6a4422, 0x4a5a2a, 0x2a2a2a], heavy: [0x9a9aa6, 0x7a8aa6, 0xc8a040, 0x5a6a8a]};
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
			wizard: [WIZARD, {R: 0xd03030, r: 0x8a1818, S: 0xf5dc72, E: 0x101010, W: 0xf4f4f4, Y: 0x8a5a2a, G: 0x60e0ff, B: 0x3a2010}],
			archer: [ARCHER, {G: 0x3a9a3a, g: 0x1e6a1e, S: 0xf5dc72, E: 0x101010, L: 0x8a5a2a, l: 0x5a3a18, W: 0xc08040, B: 0x3a2a14}],
			knight: [KNIGHT, {r: 0xd02020, H: 0xc8c8d0, h: 0x7a7a86, E: 0x101010, K: 0x3a5ad0, Q: 0xf0c030, M: 0xa8a8b4, m: 0x6a6a78, S: 0xf5dc72, A: 0xc89030, W: 0xf0f0ff, B: 0x2a2a30}],
			priest: [PRIEST, {W: 0xf4f4f4, w: 0xa8a8b8, S: 0xf5dc72, E: 0x101010, Y: 0xe0b030, G: 0x70e0ff, B: 0x5a4030}],

			rogue: [ROGUE, {P: 0x6a2a8a, p: 0x3a1850, S: 0xf5dc72, E: 0x101010, K: 0x3a3a44, k: 0x22222a, W: 0xd8d8e8, B: 0x1a1a1a}],
			warrior: [WARRIOR, {Y: 0xf0e0b0, H: 0xc0a060, h: 0x806a30, E: 0x101010, R: 0xb02020, M: 0xc83030, m: 0x802020, S: 0xf5dc72, A: 0xc89030, W: 0xf0f0ff, B: 0x2a1a10}],
			necromancer: [NECRO, {D: 0x2e2e36, d: 0x18181c, S: 0xd8d0c0, E: 0xff3030, K: 0x9a1a1a, G: 0xe8e0c8, W: 0x5a3a2a, B: 0x101010}],
			huntress: [HUNTRESS, {R: 0xd04a20, r: 0x8a2a10, S: 0xf5dc72, E: 0x101010, G: 0x4a8a3a, g: 0x2e5a24, L: 0x8a5a2a, W: 0xc08040, B: 0x3a2a14}],
			titan: [BOSS_TITAN, {R: 0x7a4a30, r: 0x3e2418, Y: 0xffd040, L: 0xff5a10}, 5],
			wyrm: [BOSS_WYRM, {C: 0x7ac8f0, c: 0x3a78b0, W: 0xe8f8ff, w: 0xa8d8f0, E: 0x1a2a6a, K: 0xffffff}, 5],
			hollowking: [BOSS_HOLLOWKING, {Y: 0xf0c030, G: 0x6aff4a, B: 0xe8e0c8, T: 0x9a9280, E: 0x2a2a2a, P: 0x4a1a6a, W: 0xffffff}, 5],
			elder: [BOSS_ELDER, {H: 0xd8d0c0, h: 0x8a8070, P: 0x5a2a8a, p: 0x2a0e40, Q: 0xe0b030, K: 0x120818, E: 0xff3040, W: 0xffd0e0, O: 0x60f0ff}, 6],
			behemoth: [BOSS_BEHEMOTH, {W: 0xe8e0c0, G: 0x5a9a38, g: 0x2e5a1c, E: 0xff3020, T: 0xffffff, R: 0xa02020, r: 0x601010}, 5],
			regent: [BOSS_REGENT, {Y: 0xf0d060, y: 0xa08020, C: 0x6a2aa8, c: 0x3a1060, Q: 0xd8d0ff, E: 0x6020a0, W: 0xff60c0, M: 0xa890e8, m: 0x7058c0}, 5],
			sorcerer: [BOSS_SORCERER, {H: 0x2a4ab0, h: 0x14286a, S: 0xf5dc72, E: 0x101010, W: 0xf0f0f0, R: 0x3a5ad0, r: 0x1a2a7a, O: 0x80f0ff, o: 0xffffff}, 5],
			warden: [BOSS_WARDEN, {H: 0x9ab0c0, h: 0x5a6a7a, E: 0x40e0ff, G: 0xc0ffff, A: 0x203040, M: 0x6a8aa0, m: 0x3a4a5a, L: 0x40c0ff, l: 0xb0b0b0}, 5],
			pyrelord: [BOSS_PYRELORD, {F: 0xff6010, Y: 0xffc030, W: 0xffffa0, K: 0x3a0800, R: 0xa01808}, 5],
			seraph: [BOSS_SERAPH, {Y: 0xfff060, W: 0xf8f8ff, S: 0xf5dc72, E: 0x2040a0, G: 0xe8d870, g: 0xb0a040}, 5],
			imp: [BRUTE, {H: 0xe05020, h: 0x902a10, E: 0xffe040, B: 0x5a2a14, b: 0x3a1a0c, A: 0xff9030, L: 0x2a140a, W: 0xffb040, S: 0xe05020}],
			skeleton: [HUMANOID, {H: 0xe8e0c8, h: 0xb0a890, S: 0xe8e0c8, E: 0x202020, B: 0xd0c8b0, b: 0x9a9280, A: 0x5a5a5a, L: 0xb0a890, W: 0xa0a0a0}],
			shade: [HUMANOID, {H: 0x3a1a5a, h: 0x200c34, S: 0x7a5aa8, E: 0xff3060, B: 0x2e1448, b: 0x1a0a2c, A: 0xa060ff, L: 0x100818, W: 0xc080ff}],
			famekeeper: [HUMANOID, {H: 0xd06010, h: 0x8a3a08, S: 0xf5dc72, E: 0x101010, B: 0xff9a2e, b: 0xb06010, A: 0xffe080, L: 0x3a2014, W: 0xffe080}],
			merchant: [HUMANOID, {H: 0x2a7a4a, h: 0x1a5030, S: 0xf5dc72, E: 0x101010, B: 0x2a8a5a, b: 0x1a5a3a, A: 0xf0c030, L: 0x3a2a14, W: 0xf0c030}],
			questboard: [QUESTBOARD, {W: 0x6a4423, P: 0xf0e0b0, L: 0x8a7a5a}, 6],
			slime: [BLOB, {B: 0x5ac040, b: 0x3a8a2a, W: 0x9aff7a, E: 0x103010}],
			wolf: [WOLF, {W: 0x8a8a92, w: 0x5a5a62, E: 0xff3030}],
			golem: [BRUTE, {H: 0x9a9aa0, h: 0x6a6a70, E: 0x60e0ff, B: 0x8a8a90, b: 0x5a5a60, A: 0x60e0ff, L: 0x4a4a50, W: 0x8a8a90, S: 0x9a9aa0}, 6],
			lich: [MAGE, {H: 0x3a1a5a, h: 0x200c34, S: 0xe8e0c8, E: 0x60e0ff, B: 0x1a1a24, b: 0x0c0c12, L: 0x0c0c12, W: 0x5a4a3a, G: 0x60ff90}, 6],
			anvil: [ANVIL, {C: 0xa060ff, W: 0xffffff, c: 0x6a30c0, K: 0x5a5a62, k: 0x3a3a40}, 6],
			gold: [[I_GOLD], {Y: 0xf0c030, y: 0xb08818, W: 0xfff0a0}, 3],
			onrane: [[I_ONRANE], {P: 0xc060ff, p: 0x7a28b8, W: 0xf0d0ff}, 3],
			pirate: [HUMANOID, {H: 0xd02828, h: 0x901818, S: 0xecd070, E: 0x101010, B: 0x4a50a8, b: 0x323878, A: 0xd0b040, L: 0x2a1a10, W: 0xc0c0c0}],
			bandit: [HUMANOID, {H: 0x383838, h: 0x202020, S: 0xe0c060, E: 0xff3030, B: 0x484848, b: 0x2a2a2a, A: 0x8a5a2a, L: 0x1a1a1a, W: 0xc0c0c0}],
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
			boss: [BOSS_BOSS, {Y: 0xf8c828, y: 0xb08810, Q: 0xa860f0, P: 0x6a28b8, p: 0x3a1068, W: 0xffffff, E: 0xff2040, K: 0x200008}, 5],

			tree: [TREE, {g: 0x24561c, G: 0x3e8a2c, L: 0x6cc04a, T: 0x6b4423, t: 0x442a14}],
			pine: [PINE, {g: 0x163c16, G: 0x2a6424, L: 0x4a9a3a, T: 0x5a3a1c, t: 0x3a2410}],
			palm: [PALM, {G: 0x3a9a2a, L: 0x7ad060, T: 0x9a7040, t: 0x6a4a28}],
			rock: [ROCK, {k: 0x6a6a70, K: 0x8e8e96, L: 0xc0c0c8, d: 0x48484e}],
			boulder: [BOULDER, {k: 0x4e4e54, K: 0x6a6a72, L: 0x9a9aa4, d: 0x34343a}],
			pillar: [PILLAR, {L: 0xc8c8cc, l: 0x8a8a90, S: 0xa8a8b0, s: 0x6a6a72}],
			ruinwall: [RUINWALL, {L: 0xc8c8cc, S: 0xa0a0a8, l: 0x6a6a72}],
			crate: [CRATE, {K: 0x5a3a1a, C: 0xa0703a}],
			banner: [BANNER, {S: 0xc8a050, s: 0x8a6a30, R: 0x8a1a2a, Y: 0xf0c030}],
			chest_locked: [CHEST, {K: 0x2a2a30, C: 0x6a6a72, c: 0x4a4a52, Y: 0x9a9aa2}, 6],
			mimic: [CHEST, {K: 0x3a0a0a, C: 0x9a1a1a, c: 0x6a0a0a, Y: 0xffffff}, 6],
			shrine_might: [SHRINE, {O: 0xff4040, o: 0xa01818, H: 0xffd0d0, S: 0xb0b0b8, s: 0x6a6a72}],
			shrine_haste: [SHRINE, {O: 0x40e0ff, o: 0x1880a0, H: 0xd0f8ff, S: 0xb0b0b8, s: 0x6a6a72}],
			shrine_fortune: [SHRINE, {O: 0xffd040, o: 0xa08010, H: 0xfff4c0, S: 0xb0b0b8, s: 0x6a6a72}],
			shrine_vigor: [SHRINE, {O: 0x50e070, o: 0x208a38, H: 0xd0ffd8, S: 0xb0b0b8, s: 0x6a6a72}],
			shrine_arcana: [SHRINE, {O: 0xb060ff, o: 0x6a28b0, H: 0xf0d8ff, S: 0xb0b0b8, s: 0x6a6a72}],
			tent: [TENT, {K: 0x3a2814, C: 0xb08a50, c: 0x806030, D: 0x2a1a0c}],
			campfire: [CAMPFIRE, {Y: 0xffe040, F: 0xff6a20, W: 0xffffff, K: 0x5a3a1c, k: 0x3a2410}],
			totem: [TOTEM, {K: 0x7a5230, k: 0x4a3018, E: 0xffe040, R: 0xc03020}],
			deadtree: [DEADTREE, {W: 0x6a5640, w: 0x3e3226}],
			brazier: [BRAZIER, {Y: 0xffe040, F: 0xff7a20, W: 0xffffff, S: 0x6a6a72, s: 0x44444a}],
			crystal: [CRYSTAL, {W: 0xffd0e8, C: 0xff4080, c: 0xb01850, D: 0x600828, S: 0x3a1a2a}, 7],
			nest: [NEST, {W: 0xf4ecd8, w: 0xc8b890, S: 0x60c0ff, K: 0x7a5a2a, k: 0x4a3418}, 6],
			pet_pup: [WOLF, {W: 0xc89a5a, w: 0x8a6430, E: 0x101010}, 4],
			pet_slime: [BLOB, {B: 0x50b8ff, b: 0x2878c0, W: 0xc0ecff, E: 0x102040}, 4],
			pet_owl: [OWL, {B: 0x8a6a4a, b: 0x5a4430, W: 0xffffff, E: 0x101010, Y: 0xf0c030}, 4],
			pet_drake: [DRAKE, {R: 0xe85a24, r: 0xffb040, E: 0xffff60}, 4],
			pet_wisp: [WISP, {W: 0xe0fff8, C: 0x60f0d0, E: 0x105048}, 4],
			pet_golem: [BRUTE, {H: 0x9a9aa0, h: 0x6a6a70, E: 0x60ff90, B: 0x8a8a90, b: 0x5a5a60, A: 0x60ff90, L: 0x4a4a50, W: 0x8a8a90, S: 0x9a9aa0}, 4],
			// ---- realm monsters (biome leaders are drawn bigger)
			pirate_brawler: [BRUTE, {H: 0x2a2a6a, h: 0x1a1a4a, E: 0x101010, B: 0xe0e0e0, b: 0xc02020, A: 0x8a5a2a, L: 0x3a2a14, W: 0xc0c0c0, S: 0xecd070}],
			pirate_captain: [HUMANOID, {H: 0x1a1a1a, h: 0x0a0a0a, S: 0xecd070, E: 0x101010, B: 0xb02020, b: 0x701010, A: 0xf0c030, L: 0x2a1a10, W: 0xf0c030}, 6],
			pirate_king: [BOSS_PIRATE_KING, {K: 0x1a1a1a, W: 0xffffff, S: 0xf5dc72, E: 0x101010, B: 0x6a3a1a, R: 0x2a2a6a, r: 0x14143a, Y: 0xf0c030, H: 0xc0c0c0, C: 0xe0e0e0, L: 0x3a2a14}, 5],
			scorpion: [SCORPION, {C: 0xb04020, S: 0xd06030, T: 0x8a2a10, E: 0x101010}],
			green_slime: [BLOB, {B: 0x40b030, b: 0x207018, W: 0x9aff7a, E: 0x103010}, 6],
			goblin_chief: [BRUTE, {H: 0x58a030, h: 0x3a7020, E: 0xff3030, B: 0x8a2a2a, b: 0x5a1a1a, A: 0xf0c030, L: 0x3a2814, W: 0xd0d0d0, S: 0x58a030}, 6],
			bandit_leader: [HUMANOID, {H: 0x6a1a1a, h: 0x3a0a0a, S: 0xe0c060, E: 0xff3030, B: 0x2a2a2a, b: 0x141414, A: 0xf0c030, L: 0x1a1a1a, W: 0xe0e0e0}, 6],
			orc_king: [BRUTE, {H: 0x2a6a2a, h: 0x1a4a1a, E: 0xffe020, B: 0x8a6a2a, b: 0x5a4418, A: 0xf0c030, L: 0x2a1a10, W: 0xe0e0e0, S: 0x2a6a2a}, 7],
			spider: [SPIDER, {B: 0x3a2a3a, b: 0xc02020, E: 0xff3030}],
			spider_queen: [SPIDER, {B: 0x2a1a2a, b: 0xe0c020, E: 0xff3030}, 7],
			broodmother: [BOSS_BROODMOTHER, {B: 0x5a3050, b: 0x341a30, L: 0x7a5068, R: 0xa01818, W: 0xe8e0c8, E: 0xff3030}, 5],
			great_snake: [SNAKE, {G: 0x3a8a3a, g: 0x1a5a1a, E: 0xffe020}, 6],
			harpy: [BIRD, {H: 0xe0c0a0, E: 0xff3030, W: 0x8a6a4a, B: 0x6a4a30, Y: 0xf0c030}],
			dwarf: [BRUTE, {H: 0xc04a20, h: 0x8a3010, E: 0x101010, B: 0x6a6a72, b: 0x4a4a52, A: 0xf0c030, L: 0x3a2814, W: 0xc0c0c0, S: 0xf0c8a0}],
			dwarf_king: [BRUTE, {H: 0xf0c030, h: 0xc08a10, E: 0x101010, B: 0x8a2a8a, b: 0x5a1a5a, A: 0xf0c030, L: 0x3a2814, W: 0xffffff, S: 0xf0c8a0}, 6],
			ogre: [BRUTE, {H: 0xa08a5a, h: 0x7a6a40, E: 0xff3030, B: 0x6a4a2a, b: 0x4a3418, A: 0x9a9a9a, L: 0x3a2814, W: 0x8a6a4a, S: 0xa08a5a}, 7],
			minotaur: [BRUTE, {H: 0x6a3a1a, h: 0x4a2410, E: 0xff3030, B: 0x8a5a2a, b: 0x5a3a18, A: 0xe0e0e0, L: 0x2a1a10, W: 0xe0e0e0, S: 0x6a3a1a}, 6],
			ghost_god: [GHOST, {W: 0xe8f0ff, w: 0x9ab0d0, E: 0x203060}, 6],
			ghost: [GHOST, {W: 0xc8d8f0, w: 0x8aa0c0, E: 0x203060}, 4],
			demon: [DEMON, {H: 0xe0e0e0, R: 0xd02020, r: 0x8a1010, Y: 0xffe040}, 6],
			lesser_demon: [DEMON, {H: 0xc0c0c0, R: 0xa02828, r: 0x6a1414, Y: 0xffe040}, 4],
			archdemon: [BOSS_ARCHDEMON, {H: 0xd0d0d0, R: 0x8a1030, r: 0x4a0818, Y: 0xffe040, F: 0xff6020, W: 0x6a2034}, 5],
			sprite_god: [FAIRY, {W: 0xc0f0ff, w: 0x80c0e0, C: 0xff80d0, c: 0xc04090, E: 0x101010}, 6],
			sprite: [FAIRY, {W: 0xe0ffe0, w: 0xa0e0a0, C: 0x80e080, c: 0x40a040, E: 0x101010}, 4],
			sprite_queen: [BOSS_SPRITE_QUEEN, {Y: 0xfff0a0, W: 0xc0f0ff, w: 0x80c0e0, H: 0xffc0e0, S: 0xf5dc72, E: 0x101010, C: 0xff60c0, c: 0xc02080}, 5],
			slime_god: [BLOB, {B: 0x8040c0, b: 0x502080, W: 0xd0a0ff, E: 0x200a30}, 7],
			moth: [BOSS_MOTH, {W: 0xe0d8a0, w: 0xa09060, O: 0xff8040, A: 0x6a5030, E: 0xff3030}, 5],
			mothling: [MOTH, {W: 0xc8c090, w: 0x8a8050, A: 0x5a4428, E: 0xff3030}, 4],
			serpent_queen: [BOSS_SERPENT_QUEEN, {Y: 0xf0c030, G: 0x2a9a6a, g: 0x14583c, S: 0xa0e0c0, E: 0x101010, P: 0x6a2a8a, p: 0x401a5a}, 5],
			lich_king: [BOSS_LICH_KING, {Y: 0xc0c0d0, B: 0xe8e0c8, E: 0x60e0ff, R: 0xff4060, T: 0x6a6a6a, P: 0x46306a, p: 0x281a40, G: 0x40ff90}, 5],
			sphinx: [BOSS_SPHINX, {B: 0x2a5ad0, Y: 0xf0c030, S: 0xe8c070, E: 0x2040c0, W: 0x40e0ff, T: 0xd8b060, t: 0x9a7a38}, 5],
			sunken_lord: [BOSS_SUNKEN_LORD, {S: 0x6a8aa0, s: 0x3a5060, B: 0xd0d8c0, E: 0x60e0ff, G: 0xd0ffff, W: 0xc8a040, H: 0x8a6a2a}, 5],
			hermit: [BOSS_HERMIT, {S: 0xe8d8b0, s: 0xa08a60, C: 0x2a9a8a, c: 0x14584e, E: 0xe0ff80, W: 0xffffff}, 5],
			shrine: [BOSS_SHRINE, {F: 0xff8a20, Y: 0xffe040, B: 0xe8e0c8, b: 0x8a8070, E: 0x200808, R: 0xff2020, T: 0x5a5040, S: 0x6a6a72, A: 0x8a8a92, a: 0x4a4a52}, 5],
			// ---- hard multi-boss dungeons (recoloured boss designs)
			sun_king: [BOSS_HOLLOWKING, {Y: 0xffe060, G: 0xff9020, B: 0xf0c060, T: 0xa07020, E: 0x401000, P: 0xc04010, W: 0xffffff}, 5],
			moon_queen: [BOSS_SERPENT_QUEEN, {Y: 0xe0e8ff, G: 0x6a7ac0, g: 0x3a4a80, S: 0xd0d8f0, E: 0x101030, P: 0x2a3a8a, p: 0x1a2458}, 5],
			star_prince: [BOSS_SORCERER, {H: 0x6a2aa8, h: 0x3a1468, S: 0xf5dc72, E: 0x101010, W: 0xfff0a0, R: 0x8a3ac8, r: 0x4a1a70, O: 0xfff060, o: 0xffffff}, 5],
			frost_warden: [BOSS_WARDEN, {H: 0xc0e8ff, h: 0x6a9ac0, E: 0x60e0ff, G: 0xffffff, A: 0x20304a, M: 0x8ab8e0, m: 0x4a6a90, L: 0x80f0ff, l: 0xd0d0d0}, 5],
			flame_warden: [BOSS_WARDEN, {H: 0x8a4a30, h: 0x4a2010, E: 0xffb020, G: 0xffff80, A: 0x3a1008, M: 0xb04a20, m: 0x6a2410, L: 0xff6020, l: 0xb0b0b0}, 5],
			shattered_seraph: [BOSS_SERAPH, {Y: 0xff60c0, W: 0x7a6a9a, S: 0xd8d0e8, E: 0xff2060, G: 0x4a3a6a, g: 0x2a1e44}, 6],
			blood_knight: [BOSS_SUNKEN_LORD, {S: 0x8a1a2a, s: 0x4a0a14, B: 0x3a3a3a, E: 0xff4040, G: 0xffa0a0, W: 0xd0d0d8, H: 0x5a5a5a}, 5],
			hex_queen: [BOSS_LICH_KING, {Y: 0x60ff90, B: 0xc8e8c0, E: 0x80ff60, R: 0xff60ff, T: 0x4a6a4a, P: 0x2a4a2a, p: 0x142a14, G: 0xd060ff}, 5],
			chest: [CHEST, {K: 0x4a2a10, C: 0x9a6a3a, c: 0x7a4a24, Y: 0xf0c030}, 6],
			bag_brown: [BAG, {K: 0x502a10, C: 0x9a6a3a, c: 0x6a4420, D: 0x5a3a1a}],
			bag_purple: [BAG, {K: 0x401060, C: 0xb050e0, c: 0x7a2aa8, D: 0x6a2090}],
			bag_cyan: [BAG, {K: 0x105060, C: 0x40d0f0, c: 0x1a90b0, D: 0x1a8098}],
			bag_white: [BAG, {K: 0x3a5a8a, C: 0xd8ecff, c: 0x9ac0e8, D: 0x7aa0d0}],
			bag_fabled: [BAG, {K: 0x4a1060, C: 0xc85cff, c: 0x8a30c0, D: 0x6a2090}],
			bag_legendary: [BAG, {K: 0x6a4a08, C: 0xffc23a, c: 0xc08a18, D: 0x9a6a10}],
			bag_relic: [BAG, {K: 0x601a08, C: 0xff5533, c: 0xc0301a, D: 0x8a2410}],
			grave: [GRAVE, {G: 0x9a9aa0, g: 0x6a6a70, D: 0x4a4a50, M: 0x3a6a2a}],
			fame: [[I_FAME], {O: 0xd05010, Y: 0xff9a2e, W: 0xffe080}, 3],
			skull: [[I_SKULL], {W: 0xe8e8e8, E: 0x202020}, 3]
		};

		// ================================================================ API
		/** Registers `name` as `base`'s design with a new palette (new bosses reuse boss art). */
		public static function recolor(name:String, base:String, pal:Object, scale:int = 0):void {
			var d:Array = DEFS[base];
			if (d) DEFS[name] = [d[0], pal, scale || d[2]];
		}

		/** Animation frame `frame` of a sprite (0 stand, 1 walk, 2 attack). */
		public static function get(name:String, frame:int = 0, flip:Boolean = false):BitmapData {
			var d:Array = DEFS[name] || skinDef(name) || DEFS["cubelet"];
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
				bd = build(frames[frame], d[1], d[2] || SCALE, 2);
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
		/** Builds (once) the sprite definition for a class skin: the class frames with a recoloured palette. */
		private static function skinDef(name:String):Array {
			var f:Object = Data.findSkin(name);
			if (!f) return null;
			var base:Array = DEFS[f.base];
			var pal:Object = {};
			var k:String;
			for (k in base[1]) pal[k] = base[1][k];
			for (k in f.skin.pal) pal[k] = f.skin.pal[k];
			return DEFS[name] = [base[0], pal, base[2]];
		}

		/** Red-hot tint used while a boss is enraged. */
		public static function rage(name:String, frame:int = 0, flip:Boolean = false):BitmapData {
			var key:String = name + ":" + frame + (flip ? "f" : "") + ":rage";
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			bd = get(name, frame, flip).clone();
			bd.colorTransform(bd.rect, new ColorTransform(1, 0.55, 0.55, 1, 70, 0, 0, 0));
			cache[key] = bd;
			return bd;
		}

		public static function hit(name:String, frame:int = 0, flip:Boolean = false):BitmapData {
			var key:String = name + ":" + frame + (flip ? "f" : "") + ":hit";
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			bd = get(name, frame, flip).clone();
			bd.colorTransform(bd.rect, new ColorTransform(0.5, 0.5, 0.5, 1, 140, 60, 60, 0));
			cache[key] = bd;
			return bd;
		}

		/** A class hero carved in stone (Nexus statues). */
		public static function statue(name:String):BitmapData {
			var key:String = name + ":statue";
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			var src:BitmapData = get(name, 0, false);
			bd = src.clone();
			var px:Vector.<uint> = bd.getVector(bd.rect);
			for (var i:int = 0; i < px.length; i++) {
				var c:uint = px[i];
				if ((c >>> 24) == 0) continue;
				// greyscale, warmed a little like old marble
				var l:int = ((c >> 16 & 255) * 0.3 + (c >> 8 & 255) * 0.59 + (c & 255) * 0.11);
				l = 70 + l * 0.6;
				px[i] = (c & 0xff000000) | (Math.min(255, l + 12) << 16) | (Math.min(255, l + 8) << 8) | l;
			}
			bd.setVector(bd.rect, px);
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

		public static function tint(c:uint, t:Number):uint {
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

		/** Soft glowing dot without an outline (trails, dust, sparkles). */
		public static function glow(color:uint):BitmapData {
			var key:String = "gl" + color;
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			bd = new BitmapData(6, 6, true, 0);
			bd.fillRect(new Rectangle(1, 0, 4, 6), 0x55000000 | color);
			bd.fillRect(new Rectangle(0, 1, 6, 4), 0x55000000 | color);
			bd.fillRect(new Rectangle(1, 1, 4, 4), 0xaa000000 | color);
			bd.fillRect(new Rectangle(2, 2, 2, 2), 0xff000000 | Sprites.shade(color, 1.25));
			cache[key] = bd;
			return bd;
		}

		/** Inventory icon (36x36). */
		public static function icon(item:Object):BitmapData {
			var key:String = "icon_" + ItemArt.identity(item) + "_" + item.kind + "_" + (item.sub || "");
			var bd:BitmapData = cache[key];
			if (bd) return bd;
			var rar:String = item.rarity;
			var rc:uint = rar ? Data.RARITY_COLORS[rar] : 0;
			// gear and stat potions: every item has its own drawing (ItemArt)
			var art:Object = ItemArt.art(item);
			if (art) {
				bd = build(art.rows, art.pal, 4, 2);
				if (rar == "gd") bd = godlyFrame(bd);
				else if (rar) bd = glowEdge(bd, rc);
				cache[key] = bd;
				return bd;
			}
			var band:int = Math.max(0, Math.min(3, int((item.tier || 0) / 2)));
			var rows:Array, pal:Object;
			switch (item.kind) {
				case "weapon":
					var designs:Array = {sword: ICON_SWORD, dagger: ICON_DAGGER, staff: ICON_STAFF, wand: ICON_WAND, bow: ICON_BOW}[item.sub] || ICON_WAND;
					rows = designs[rar ? 4 : band];
					pal = rar ? rarityPal(rc, rar) : ICON_TIERS[band];
					break;
				case "ability":
					var ad:Array = {spell: ICON_SPELL, quiver: ICON_QUIVER, shield: ICON_SHIELD, tome: ICON_TOME, cloak: ICON_CLOAK,
						helm: ICON_HELM, skull: ICON_SKULL, trap: ICON_TRAP}[item.sub] || ICON_TOME;
					rows = ad[rar ? 1 : 0];
					var ab:Array = ICON_ABIL[item.sub] || [0x8a2a2a, 0xe8e0c8];
					if (item.sub == "skull") pal = {H: ab[1], b: shade(ab[1], 0.6), B: ab[0], R: band ? ICON_TIERS[band].R : 0x202020};
					else pal = {B: ab[0], b: shade(ab[0], 0.6), H: ab[1], G: ICON_TIERS[band].G, W: 0xe8e0c8, R: ICON_TIERS[band].R};
					if (rar) { pal.R = rc; pal.G = 0xf0c030; }
					break;
				case "armor":
					var ad2:Array = {robe: ICON_ROBE, leather: ICON_LEATHER, heavy: ICON_HEAVY}[item.sub] || ICON_ROBE;
					rows = ad2[rar ? 1 : 0];
					var ac:uint = (ICON_ARMOR[item.sub] || ICON_ARMOR.robe)[band];
					pal = {B: ac, b: shade(ac, 0.6), H: shade(ac, 1.5), G: ICON_TIERS[band].G, R: ICON_TIERS[band].R};
					if (rar) pal = {B: shade(rc, 0.75), b: shade(rc, 0.45), H: shade(rc, 1.2), G: 0xf0c030, R: rc};
					break;
				case "ring":
					var gem:uint = rar ? rc : Data.STAT_COLORS[item.sub];
					rows = ICON_RING[rar ? 1 : 0];
					pal = {R: gem, r: shade(gem, 0.6), H: 0xffffff, G: rar || item.tier >= 4 ? 0xf0c030 : 0xc0c0c8, g: rar || item.tier >= 4 ? 0xa07810 : 0x7a7a82};
					break;
				case "material":
					rows = ICON_SOR[0];
					pal = {C: 0xa060ff, c: 0x6a30c0, W: 0xf0d8ff};
					break;
				case "stat":
					var sc:uint = Data.STAT_COLORS[item.sub] || 0xa040e0;
					rows = ICON_STATPOT[0];
					pal = {W: 0x8a5a2a, G: 0xd8d8e0, H: 0xffffff, P: sc, p: shade(sc, 0.6)};
					break;
				default:
					var pc:uint = item.color || (item.kind == "mp" ? 0x4060ff : 0xe03030);
					rows = ICON_POT[0];
					pal = {W: 0x8a5a2a, G: 0xc8c8d0, H: 0xffffff, P: pc, p: shade(pc, 0.6)};
			}
			bd = build(rows, pal, 4, 2);
			if (rar) bd = glowEdge(bd, rc);
			cache[key] = bd;
			return bd;
		}

		private static function rarityPal(c:uint, rar:String):Object {
			return {B: rar == "lg" ? 0xf0f0d0 : c, b: shade(c, 0.55), H: 0xffffff, G: 0xf0c030, g: 0xa07810, R: c, r: shade(c, 0.6),
				W: 0x3a2a3a, w: 0x1a1018, P: c, S: 0xffffff};
		}

		/**
		 * Godly frame: the dark outline, then a solid off-white border, then a
		 * soft warm glow fading out around it.
		 */
		private static function godlyFrame(src:BitmapData):BitmapData {
			var w:int = src.width + 8, h:int = src.height + 8;
			var bd:BitmapData = new BitmapData(w, h, true, 0);
			bd.copyPixels(src, src.rect, new Point(4, 4));
			var px:Vector.<uint> = bd.getVector(bd.rect);
			// solid border, then three glow passes getting fainter
			var cols:Array = [0xfffff6e0, 0xfffff6e0, 0xb0fff0d0, 0x60ffe8c0, 0x28ffe0b0];
			for (var pass:int = 0; pass < cols.length; pass++) {
				var copy:Vector.<uint> = px.concat();
				for (var y:int = 1; y < h - 1; y++) {
					for (var x:int = 1; x < w - 1; x++) {
						var i:int = y * w + x;
						if (copy[i] != 0) continue;
						// the first passes hug the shape tightly (incl. diagonals) so the border is crisp
						var hit:Boolean = copy[i - 1] != 0 || copy[i + 1] != 0 || copy[i - w] != 0 || copy[i + w] != 0;
						if (!hit && pass < 2) hit = copy[i - w - 1] != 0 || copy[i - w + 1] != 0 || copy[i + w - 1] != 0 || copy[i + w + 1] != 0;
						if (hit) px[i] = uint(cols[pass]);
					}
				}
			}
			bd.setVector(bd.rect, px);
			return bd;
		}

		/** Adds a soft coloured glow around an icon (rare items). */
		private static function glowEdge(src:BitmapData, col:uint):BitmapData {
			var w:int = src.width + 4, h:int = src.height + 4;
			var bd:BitmapData = new BitmapData(w, h, true, 0);
			bd.copyPixels(src, src.rect, new Point(2, 2));
			var px:Vector.<uint> = bd.getVector(bd.rect);
			for (var pass:int = 0; pass < 2; pass++) {
				var copy:Vector.<uint> = px.concat();
				var a:uint = pass == 0 ? 0xb0 : 0x50;
				for (var y:int = 1; y < h - 1; y++) {
					for (var x:int = 1; x < w - 1; x++) {
						var i:int = y * w + x;
						if (copy[i] != 0) continue;
						if (copy[i - 1] != 0 || copy[i + 1] != 0 || copy[i - w] != 0 || copy[i + w] != 0) px[i] = (a << 24) | col;
					}
				}
			}
			bd.setVector(bd.rect, px);
			return bd;
		}

	}
}
