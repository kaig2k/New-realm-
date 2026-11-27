"""
The heroes, gilded: Eldmere's violet, deep jewel colours and gold trim, and something on top that names the class
at a glance (a wizard's brimmed hat, a knight's plume, an archer's feather, a priest's halo...). Same 8x8 grid,
same three frames (idle, walk, attack), and each class keeps its letters, so every skin and dye still recolours
the same parts. Z is the gold trim (no skin touches it). Shaded as heroes_polished.py shades them.

    python3 tools/bossart/heroes_gilded.py preview.png     every class, and its skins
    python3 tools/bossart/heroes_gilded.py --as3           the AS3 for Sprites.as
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
import heroes_polished as hp

Z = 0xe0b040
WALK = '.B....B.'

# idle and attack frames (the walk is the idle with its legs apart), and the palette
DESIGNS = {
    'wizard': ((["...RR..G", "..RRRr.Y", ".ZZZZZZ.", "..SESE.Y", "RRRZZRRS", ".rRZZRrY", ".ZRRRRZ.", "..B..B.."],
                ["...RR...", "..RRRr..", ".ZZZZZZ.", "..SESE.G", "RRRZZRSY", ".rRZZRY.", ".ZRRRRZ.", "..B..B.."]),
               {'R': 0x6a2ab0, 'r': 0x3a1468, 'S': 0xf0c898, 'E': 0x101010, 'Y': 0x8a5a2a, 'G': 0x60e0ff, 'B': 0x2a1a10}),
    'archer': (([".H.GGg.W", "..GGGGgW", ".gSESEg.", "..SSSS.W", "ZLLLLLZS", ".gLZZLgW", ".gLLLLg.", "..B..B.."],
                [".H.GGg..", "..GGGGg.", ".gSESEgW", "..SSSSW.", "ZLLLLLSW", ".gLZZLW.", ".gLLLLg.", "..B..B.."]),
               {'H': 0xe03040, 'G': 0x2e8a4a, 'g': 0x185a2a, 'S': 0xf0c898, 'E': 0x101010, 'L': 0x6a4a2a, 'l': 0x4a321a,
                'W': 0xc08a40, 'B': 0x3a2a14}),
    'knight': ((["...rr...", "..HHHH..", ".HHZZHH.", ".HEhEhHW", "ZKMZZMmW", "KQKMMmSA", "KKMZZMm.", "..B..B.."],
                ["...rr...", "..HHHH..", ".HHZZHH.", ".HEhEhH.", "ZKMZZMm.", "KQKMMmSW", "KKMZZMmW", "..B..B.."]),
               {'r': 0xd03040, 'H': 0xd8d8e4, 'h': 0x8a8a9a, 'E': 0x101010, 'K': 0x3a3aa0, 'Q': 0xf0c840, 'M': 0xb8bccc,
                'm': 0x6a6e80, 'S': 0xf0c898, 'A': 0xc89030, 'W': 0xf0f0ff, 'B': 0x2a2a30}),
    'priest': ((["..YYYY.G", "...WW..Y", "..SESE.Y", "..SSSS.Y", "wWWYYWwS", ".WWYYWwY", ".wYYYYw.", "..B..B.."],
                ["..YYYY..", "...WW...", "..SESE..", "..SSSS.G", "wWWYYWSY", ".WWYYWY.", ".wYYYYw.", "..B..B.."]),
               {'W': 0xf4f2fa, 'w': 0xb0aec8, 'S': 0xf0c898, 'E': 0x101010, 'Y': 0xf0c850, 'G': 0x70e0ff, 'B': 0x5a4030}),
    'rogue': ((["....R...", "..PPPP..", ".PPPPPPZ", ".pSESEp.", "kKZKKZkS", ".kKPPKkW", ".kKKKKk.", "..B..B.."],
               ["....R...", "..PPPP..", ".PPPPPPZ", ".pSESEp.", "kKZKKZSW", ".kKPPKW.", ".kKKKKk.", "..B..B.."]),
              {'R': 0xe03040, 'P': 0x5a2a8a, 'p': 0x341450, 'S': 0xf0c898, 'E': 0x101010, 'K': 0x3a3248, 'k': 0x221c2e,
               'W': 0xd8d8e8, 'B': 0x1a1a1a}),
    'warrior': ((["Y.HHHH.Y", "YHHZZHHY", ".HEhEhH.", ".hHHHHhW", "RRMZZMmW", "RMMMMmSA", ".RMZZMm.", "..B..B.."],
                 ["Y.HHHH.Y", "YHHZZHHY", ".HEhEhH.", ".hHHHHh.", "RRMZZMm.", "RMMMMmSW", ".RMZZMmW", "..B..B.."]),
                {'Y': 0xf0e8c8, 'H': 0xc8a860, 'h': 0x806a30, 'E': 0x101010, 'R': 0x9a1a2a, 'M': 0xc03040, 'm': 0x7a1a24,
                 'S': 0xf0c898, 'A': 0xc89030, 'W': 0xf0f0ff, 'B': 0x2a1a10}),
    'necromancer': ((["..DDDd.G", ".DZDDZdW", ".dSESEd.", "..SSSS.W", "dDDKDDdS", ".dKKKDdW", ".dZDDZd.", "..B..B.."],
                     ["..DDDd..", ".DZDDZd.", ".dSESEd.", "..SSSS.G", "dDDKDDSW", ".dKKKDW.", ".dZDDZd.", "..B..B.."]),
                    {'D': 0x2a2440, 'd': 0x141024, 'S': 0xd8d0c0, 'E': 0xff3030, 'K': 0x9a1a3a, 'G': 0xe8e0c8, 'W': 0x5a3a2a,
                     'B': 0x101010}),
    'huntress': ((["..RRRr.W", ".RZZZZrW", "RrSESErW", "R.SSSS.W", "gGGZGGgS", ".gGLLGgW", ".gGGGGg.", "..B..B.."],
                  ["..RRRr..", ".RZZZZr.", "RrSESErW", "R.SSSSW.", "gGGZGGSW", ".gGLLGW.", ".gGGGGg.", "..B..B.."]),
                 {'R': 0xc84a20, 'r': 0x7a2a10, 'S': 0xf0c898, 'E': 0x101010, 'G': 0x2a6a4a, 'g': 0x184a30, 'L': 0x8a5a2a,
                  'W': 0xc08040, 'B': 0x3a2a14}),
    'bard': ((["..VVVH..", ".ZZZZZhH", ".vSESEv.", "..SSSS.L", "vVVZVVvS", ".vVLLVvL", ".vVVVVv.", "..B..B.."],
              ["..VVVH..", ".ZZZZZhH", ".vSESEvL", "..SSSSL.", "vVVZVVSL", ".vVLLVL.", ".vVVVVv.", "..B..B.."]),
             {'V': 0x2a4ab0, 'v': 0x16286a, 'H': 0xe03040, 'h': 0x901a24, 'S': 0xf0c898, 'E': 0x101010, 'L': 0xe0b040,
              'B': 0x5a3a1a}),
    'alchemist': ((["..AAAa..", ".AGZZGa.", ".aSESEa.", "..SSSS.F", "aAMMMMaS", ".aMZZMaF", ".aAAAAa.", "..B..B.."],
                   ["..AAAa.F", ".AGZZGaF", ".aSESEa.", "..SSSSS.", "aAMMMMS.", ".aMZZMa.", ".aAAAAa.", "..B..B.."]),
                  {'A': 0x2a6a6a, 'a': 0x163e40, 'G': 0x80ffe0, 'M': 0xc8a878, 'S': 0xf0c898, 'E': 0x101010, 'F': 0x70ff50,
                   'B': 0x3a2a14}),
    'chronomancer': (([".TTTTt.O", "TZZZZZtY", ".tSESEt.", "..SSSS.Y", "tTTYTTtS", ".tTYYTtO", ".ZTTTTZ.", "..B..B.."],
                      [".TTTTt..", "TZZZZZt.", ".tSESEtO", "..SSSSYY", "tTTYTTSO", ".tTYYTt.", ".ZTTTTZ.", "..B..B.."]),
                     {'T': 0x2a2a7a, 't': 0x14143e, 'Y': 0xf0c040, 'O': 0x80e0ff, 'S': 0xf0c898, 'E': 0x101010, 'B': 0x1a1a2a}),
}


def source():
    out = {}
    for cls, ((idle, attack), pal) in DESIGNS.items():
        walk = idle[:7] + [WALK]
        p = dict(pal); p['Z'] = Z
        out[cls] = ([idle, walk, attack], p)
    return out


# heroes_polished does the shading and the AS3: it reads its drawings from here instead
hp.source = source

if __name__ == '__main__' and '--as3' in sys.argv:
    a, d, t = hp.as3()
    print(json.dumps({'arrays': a, 'defs': d, 'tones': t}))
    sys.exit(0)

if __name__ == '__main__':
    import re
    from canvas import preview
    dsrc = open(os.path.join(hp.ROOT, 'src', 'realm', 'Data.as')).read()
    sk = dsrc[dsrc.index('public static const SKINS'):]
    sk = sk[:sk.index('\n\t\t};')]
    out = []
    for cls, (frames, tones, pal) in hp.build().items():
        out.append((cls, frames, hp.palette(pal, tones)))
        blk = sk[sk.index('\t\t\t' + cls + ': ['):]
        blk = blk[:blk.index('}}]') + 2]
        for line in re.findall(r'\{id: .*?\}\}', blk):
            over = {k: int(v, 16) for k, v in re.findall(r'"?([\w@#%&])"?: 0x([0-9a-fA-F]{6})', line[line.index('pal:'):])}
            f0 = list(frames[0])
            head = re.search(r'head: \[([^\]]*)\]', line)
            if head:
                for y, m in enumerate(re.findall(r'"([^"]*)"', head.group(1))):
                    f0[y] = ''.join(f0[y][x] if c == '_' else c for x, c in enumerate(m))
            out.append((re.search(r'name: "([^"]*)"', line).group(1) if head else '', [f0], hp.palette(pal, tones, over)))
    preview(out, sys.argv[1] if len(sys.argv) > 1 else '/tmp/heroes_gilded.png', 8)
