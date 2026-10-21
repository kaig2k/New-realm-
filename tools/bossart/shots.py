"""
The bosses' own shots: small drawings (pointing right, the way they fly) tinted by each attack's
colour like the game's other shots. Letters: C the attack's colour, a its shade, W its light tint,
H pale grey, K near-black, I/i iron, G gold, S wood, B/b bone. Writes src/realm/BossShots.as.
Each posed boss fires its first shot from its strikes and its second from its casts (Bosses.POSED_SHOTS).
"""
import os

SHOTS = {
    'cube_shard': ["...aW...", "..aCWW..", ".aCCCWW.", "aaCCCCWH", ".aaCCCW.", "..aaCC..", "...aa...", "........"],
    'cube_eye': ["........", "..aCCa..", ".aCWWCa.", "aCWKKWCa", "aCWKKWCa", ".aCWWCa.", "..aCCa..", "........"],
    'magma': ["..iIIi..", ".iICCIi.", "iICWWCIi", "iCWHHWCi", "iICWWCIi", ".iICCIi.", "..iIIi..", "........"],
    'ember': ["........", "a...CC..", ".aaCWWC.", "aaCWHHWC", ".aaCWWC.", "a...CC..", "........", "........"],
    'skull': ["..BBBB..", ".BBBBBB.", "BBBBBBBb", "BCKBBCKb", "BBBKKBBb", ".bBBBBb.", "..BbBb..", "...b.b.."],
    'crownlet': ["........", "G..G..G.", "GG.GG.GG", "GGGGGGGG", "GCGGCGGC", "GGGGGGGG", "........", "........"],
    'mask': ["..CWWC..", ".CWWWWC.", "CWKWWKWC", "CWKWWKWC", "CWWWWWWC", ".CWKKWC.", "..CWWC..", "...CC..."],
    'phantom': ["........", "a...CWW.", ".aaCWWWW", "aaCWKWKW", ".aaCWWWW", "a...CWW.", "........", "........"],
    'scarab': ["........", "G.G..G..", ".aCCCGG.", "aCWCCCGG", "aCCCCCGG", ".aCCCGG.", "G.G..G..", "........"],
    'ankh': ["..GGG...", ".G...G..", ".G...G..", "..GGG...", "GGGCGGG.", "...G....", "...G....", "...G...."],
    'anchor': ["......I.", ".....III", ".i....II", "iIIIIIII", ".i....II", ".....III", "......I.", "........"],
    'bubble': ["..CCCC..", ".C.WW.C.", "C.W...aC", "C.....aC", "C.....aC", "C....aaC", ".CaaaaC.", "..CCCC.."],
    'claw': ["........", "....CCC.", "..aCCWCC", ".aCC....", ".aCC....", "..aCCWCC", "....CCC.", "........"],
    'shell': ["........", "..aCCa..", ".aCWWCa.", "aCWaaWC.", "aCWaWCaa", ".aCWCCa.", "..aaaa..", "........"],
    'skullfire': ["........", "C..BBBB.", ".CBBBBBb", "CCBKBBKb", ".CBBBBBb", "C..bBbB.", "........", "........"],
    'candle': ["........", "...CC...", "aaCWWC..", "aCWHHWCC", "aaCWWC..", "...CC...", "........", "........"],
    'boulder': ["..iiii..", ".iiIiii.", "iiCiiIii", "iiiCCiIi", "iIiiiCii", ".iiIiii.", "..iiii..", "........"],
    'voidshard': ["........", "...CW...", "..CKKW..", ".CKKKKW.", "aCKKKKWH", ".aCKKW..", "..aCC...", "........"],
    'feather': ["........", "....CCW.", "..CCWWWW", "HHHHHHHH", "..aaCCCW", "....aaC.", "........", "........"],
    'pflame': ["C.......", ".aC.CCW.", "..aCWWWW", "aaCWHHWW", "..aCWWWW", ".aC.CCW.", "C.......", "........"],
    'potion': ["...SS...", "...HH...", "..HCCH..", ".HCCWCH.", ".HCCCCH.", ".HaCCaH.", "..HHHH..", "........"],
    'hex': ["..CCCC..", ".Ca..aC.", "C.aWWa.C", "C.WaaW.C", "C.aWWa.C", ".Ca..aC.", "..CCCC..", "........"],
    'ink': ["........", ".a..KKK.", "..aKKKKK", "aaKKCKKK", "..aKKKKK", ".a..KKK.", "........", "........"],
}


def write():
    for n, rows in SHOTS.items():
        assert len(rows) == 8 and all(len(r) == 8 for r in rows), n
        assert all(c in '.CaWHKIiGSBb' for r in rows for c in r), n
    body = ',\n'.join('\t\t\t%s: [%s]' % (n, ', '.join('"%s"' % r for r in rows)) for n, rows in SHOTS.items())
    src = '''package realm {
	/**
	 * The bosses' own shots (tools/bossart/shots.py): drawings pointing the way they fly, tinted by
	 * each attack's colour (see Sprites.projectile). Generated: edit them there.
	 */
	public class BossShots {
		public static const SHAPES:Object = {
''' + body + '''
		};
	}
}
'''
    root = os.path.join(os.path.dirname(__file__), '..', '..')
    open(os.path.join(root, 'src', 'realm', 'BossShots.as'), 'w').write(src)


if __name__ == '__main__':
    write()
    print('wrote', len(SHOTS), 'shots')
