"""
The world's props, NPCs and loot bags, redrawn at twice the detail of their old drawings: trees, rocks,
pillars, ruins, crates, chests, shrines, tents, fires, braziers, crystals, bags, graves and the Nexus's
NPCs. Each keeps its old palette letters, because the game recolours these drawings into dozens of
others (Sprites.recolor: the set pieces' pillars and braziers, the pylons and obelisks made from the
crystal, the raid table and Abyss chest made from the chest, every loot bag); the shading tones it
adds are digits worked out from those letters (TONES: Sprites.retone does it in the game).

    python3 tools/bossart/props.py preview.png     a sheet of them, with some of the game's recolours
    python3 tools/bossart/props.py --as3           the AS3 for Sprites.as
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from canvas import Canvas
from heroes import tint, shade


def blob(c, cx, cy, rx, ry, mat):
    c.ellipse(cx, cy, rx, ry, mat)


# ---------------------------------------------------------------- trees
def tree():
    c = Canvas(24, 24)
    c.rect(10, 15, 13, 23, 'T'); c.rect(9, 22, 14, 23, 'T'); c.put(8, 23, 't'); c.put(15, 23, 't')
    c.line(13, 15, 13, 23, 't')
    for cx, cy, r in ((12, 8, 7.5), (6.5, 12, 5), (17.5, 12, 5), (12, 13, 6), (8, 5.5, 4), (16, 5.5, 4)):
        blob(c, cx, cy, r, r * 0.9, 'G')
    c.shade('G', 'L', 'g')
    for x, y in ((9, 4), (14, 6), (6, 10), (11, 9), (17, 10), (13, 12)):          # sunlit leaf clusters
        c.put(x, y, 'L'); c.put(x + 1, y, '1')
    for x, y in ((9, 14), (15, 15), (12, 16), (6, 15)):
        c.put(x, y, 'g')
    return c


def pine():
    c = Canvas(24, 26)
    c.rect(10, 21, 13, 25, 'T'); c.line(13, 21, 13, 25, 't')
    for k, (y, w) in enumerate(((2, 3), (6, 5), (10, 7), (14, 9), (18, 10.5))):
        c.poly([(12 - w, y + 5), (12 + w, y + 5), (12, y - 2)], 'G')
    c.shade('G', 'L', 'g')
    for k, y in enumerate((7, 11, 15, 19, 23)):                                     # the dark undersides of each tier
        for x in range(12 - (3 + k * 2), 12 + (3 + k * 2) + 1, 2):
            if c.get(x, y - 1) != '.':
                c.put(x, y - 1, 'g')
    c.put(12, 0, 'L')
    return c


def palm():
    c = Canvas(24, 26)
    pts = [(10, 25), (10.5, 20), (11.5, 15), (13, 10), (13.5, 7)]
    for a, b in zip(pts, pts[1:]):
        c.line(a[0], a[1], b[0], b[1], 'T', 2)
    for k in range(3, 24, 3):
        c.put(10 + (25 - k) * 0.12, k, 't')
    for ang, ln, droop in ((-2.8, 10, 3), (-2.2, 9, 1), (-0.9, 9, 1), (-0.3, 10, 3), (0.3, 8, 5), (2.9, 8, 5)):
        x0, y0 = 13.5, 6.5
        prev = (x0, y0)
        for s in range(1, ln + 1):
            x = x0 + math.cos(ang) * s
            y = y0 + math.sin(ang) * s + droop * (s / ln) ** 2
            c.line(prev[0], prev[1], x, y, 'G', 2 if s < ln - 2 else 1)
            prev = (x, y)
    c.shade('G', 'L', 'g')
    blob(c, 12.5, 8, 1.2, 1.0, 'T'); blob(c, 14.5, 8.5, 1.2, 1.0, 't')             # coconuts
    return c


def deadtree():
    c = Canvas(24, 26)
    c.line(11, 25, 11, 12, 'W', 3); c.line(11, 13, 7, 6, 'W', 2); c.line(12, 12, 17, 4, 'W', 2)
    c.line(7, 7, 3, 4, 'W'); c.line(8, 8, 5, 10, 'W'); c.line(16, 6, 20, 5, 'W'); c.line(15, 8, 19, 10, 'W')
    c.line(17, 4, 18, 1, 'W'); c.line(7, 6, 6, 2, 'W'); c.line(3, 4, 1, 2, 'W'); c.line(20, 5, 22, 3, 'W')
    c.line(9, 25, 6, 25, 'W'); c.line(13, 25, 16, 25, 'W')
    c.shade('W', '1', 'w')
    return c


# ---------------------------------------------------------------- stone
def rock():
    c = Canvas(18, 12)
    blob(c, 9, 7.5, 8, 4.2, 'K'); blob(c, 7.5, 5, 5, 4, 'K'); blob(c, 12, 6.5, 3.5, 3, 'K')
    c.shade('K', 'L', 'd')
    c.line(9, 3, 10, 7, 'k'); c.put(5, 8, 'k'); c.put(13, 9, 'k')
    c.put(6, 3, 'L'); c.put(7, 3, 'L')
    return c


def boulder():
    c = Canvas(22, 14)
    blob(c, 11, 8, 10, 5.5, 'K'); blob(c, 9, 5.5, 6, 4.5, 'K'); blob(c, 15, 8, 5, 4.5, 'K')
    c.shade('K', 'L', 'd')
    c.line(12, 4, 13, 8, 'k'); c.line(13, 8, 11, 11, 'k'); c.put(6, 9, 'k'); c.put(17, 6, 'k')
    return c


def pillar():
    c = Canvas(16, 22)
    c.rect(1, 2, 14, 3, 'L'); c.rect(3, 0, 12, 1, 'L'); c.put(2, 1, 'L')
    c.rect(3, 4, 12, 17, 'S')
    for x in (5, 8, 11):                                                            # its fluting
        c.line(x, 5, x, 16, 's')
    c.shade('S', '1', 's')
    c.rect(1, 18, 14, 19, 'L'); c.rect(0, 20, 15, 21, 'l')
    c.shade('L', '2', 'l')
    return c


def ruinwall():
    c = Canvas(16, 14)
    c.rect(0, 5, 15, 13, 'S')
    c.rect(2, 2, 6, 4, 'S'); c.rect(3, 0, 5, 1, 'S'); c.rect(11, 3, 14, 4, 'S')    # the broken top
    for y in (5, 9):
        c.line(0, y, 15, y, 'l')
    for x, y0 in ((4, 5), (11, 5), (7, 9), (14, 9), (1, 9)):                       # the mortar
        c.line(x, y0, x, y0 + 3, 'l')
    c.shade('S', 'L', 'l')
    c.rect(0, 13, 15, 13, 'l')
    return c


# ---------------------------------------------------------------- wood and treasure
def crate():
    c = Canvas(16, 16)
    c.rect(0, 0, 15, 15, 'C')
    c.shade('C', '1', '2')
    for k in range(16):                                                              # the frame and the cross-brace
        c.put(k, 0, 'K'); c.put(k, 15, 'K'); c.put(0, k, 'K'); c.put(15, k, 'K')
        c.put(1, k, 'K'); c.put(14, k, 'K')
    c.line(2, 2, 13, 13, 'K', 2); c.line(13, 2, 2, 13, 'K', 1)
    for y in (5, 10):
        c.line(2, y, 13, y, '2')
    return c


def chest():
    c = Canvas(16, 16)
    c.rect(1, 4, 14, 8, 'C'); c.rect(2, 2, 13, 3, 'C')                              # the lid
    c.rect(1, 9, 14, 15, 'C')                                                       # the box
    c.shade('C', '1', 'c')
    c.rect(1, 8, 14, 8, 'K'); c.rect(1, 15, 14, 15, 'K')
    for x in (1, 14):
        c.line(x, 2, x, 15, 'K')
    for x in (4, 11):                                                               # gold bands
        c.line(x, 2, x, 15, 'Y')
    c.rect(6, 7, 9, 11, 'Y'); c.rect(7, 9, 8, 10, 'K')                              # the lock
    c.shade('Y', '3', 'y')
    return c


def bag():
    """A loot sack: round and full at the bottom, gathered and tied at the neck, its cloth flaring above the tie."""
    c = Canvas(16, 16)
    c.ellipse(8, 10.5, 6.8, 5.2, 'C')
    c.poly([(5, 7), (11, 7), (10, 5), (6, 5)], 'C')                                 # the gathered neck
    c.poly([(4, 1), (12, 1), (10, 4), (6, 4)], 'C')                                 # the cloth above the tie
    c.shade('C', '1', 'c')
    c.line(5, 4, 11, 4, 'K'); c.put(12, 5, 'K'); c.put(12, 6, 'K')                  # the cord, its end hanging
    c.line(6, 8, 5, 11, 'c'); c.line(10, 8, 11, 11, 'c')                            # folds
    c.ellipse(8, 11, 1.8, 1.5, 'D')                                                 # a patch
    c.put(4, 9, '1'); c.put(5, 8, '1')
    return c


def grave():
    c = Canvas(16, 16)
    c.rect(3, 3, 12, 13, 'G'); c.ellipse(7.5, 3, 4.5, 3, 'G')
    c.shade('G', '1', 'g')
    c.line(7, 4, 7, 10, 'D'); c.line(5, 6, 9, 6, 'D'); c.line(8, 4, 8, 10, 'D')     # the cross
    c.rect(0, 14, 15, 15, 'M'); c.put(2, 13, 'M'); c.put(13, 13, 'M'); c.put(5, 13, 'M')
    return c


# ---------------------------------------------------------------- fire and magic
def campfire(f=0):
    c = Canvas(16, 14)
    c.line(2, 12, 13, 9, 'K', 2); c.line(2, 9, 13, 12, 'k', 2)                       # crossed logs
    c.put(1, 13, 'k'); c.put(14, 13, 'K')
    sway = 1 if f else 0
    c.poly([(4, 10), (12, 10), (10 + sway, 3), (8 + sway, 0), (6, 4)], 'F')
    c.poly([(6, 10), (10, 10), (9 + sway, 4), (8, 2), (7, 5)], 'Y')
    c.ellipse(8, 8.5, 1.5, 1.6, 'W')
    c.put(4 - sway, 2, 'Y'); c.put(12 + sway, 4, 'F')                                # sparks
    return c


def brazier(f=0):
    c = Canvas(16, 16)
    c.rect(2, 7, 13, 9, 'S'); c.rect(1, 6, 14, 6, 'S')                              # the bowl
    c.rect(6, 10, 9, 13, 'S'); c.rect(4, 14, 11, 15, 'S')                           # stem and foot
    c.shade('S', '1', 's')
    c.rect(4, 10, 11, 10, 's')
    sway = 1 if f else 0
    c.poly([(3, 6), (12, 6), (10 + sway, 1), (8 + sway, -1), (5, 2)], 'F')
    c.poly([(5, 6), (10, 6), (9 + sway, 2), (7, 3)], 'Y')
    c.ellipse(7.5, 5, 1.2, 1, 'W')
    return c


def crystal():
    c = Canvas(16, 16)
    c.rect(3, 13, 12, 15, 'S'); c.rect(2, 15, 13, 15, 'S')                          # its stone footing
    c.poly([(5, 13), (11, 13), (12, 6), (8, 0), (4, 6)], 'C')                       # the main shard
    c.poly([(1, 13), (5, 13), (4, 7), (2, 5)], 'C')                                 # small shards beside it
    c.poly([(11, 13), (15, 13), (14, 8), (12, 7)], 'C')
    c.shade('C', 'W', 'c', 'D')
    c.line(8, 1, 8, 12, 'c')                                                        # its facet edge
    c.line(7, 2, 5, 7, 'W'); c.put(6, 3, '1')
    return c


def shrine():
    c = Canvas(16, 20)
    c.rect(1, 18, 14, 19, 's'); c.rect(2, 16, 13, 17, 'S')                          # the steps
    c.rect(6, 8, 9, 15, 'S'); c.rect(4, 8, 11, 9, 'S'); c.rect(5, 14, 10, 15, 'S')  # the pedestal
    c.shade('S', '1', 's')
    c.ellipse(7.5, 4, 3.8, 3.8, 'O')                                                # the glowing orb
    c.shade('O', 'H', 'o')
    c.put(6, 2, 'H'); c.put(6, 3, 'H'); c.put(5, 3, '2')
    for x, y in ((2, 1), (13, 3), (1, 6), (14, 0)):                                 # motes rising from it
        c.put(x, y, 'O')
    return c


def tent():
    c = Canvas(18, 16)
    c.poly([(0, 15), (17, 15), (9, 0)], 'C')
    c.shade('C', '1', 'c')
    c.poly([(7, 15), (11, 15), (9, 6)], 'D')                                        # the open flap
    c.line(9, 0, 0, 15, 'K'); c.line(9, 0, 17, 15, 'K'); c.line(9, 0, 9, 5, 'K')
    c.put(9, 0, 'K'); c.put(8, 0, 'K'); c.put(10, 0, 'K')
    return c


def humanoid():
    """The Nexus's NPCs (the merchant, the keysmith, the fame keeper): a robed townsfolk at 16x16."""
    c = Canvas(16, 16)
    c.rect(6, 13, 7, 15, 'L'); c.rect(9, 13, 10, 15, 'L')
    for y in range(8, 14):
        k = (y - 8) / 5
        c.rect(5 - int(k * 1.2), y, 10 + int(k * 1.2), y, 'B')
    c.rect(5, 11, 10, 11, 'A')                                                      # a sash
    c.shade('B', '1', 'b')
    c.poly([(4, 7), (11, 7), (10, 1), (6, 1)], 'H')                                 # hood
    c.rect(6, 4, 9, 6, 'S'); c.put(7, 5, 'E'); c.put(9, 5, 'E')
    c.shade('H', '2', 'h')
    c.rect(11, 9, 12, 10, 'S'); c.line(12, 6, 12, 8, 'W'); c.put(12, 5, 'A')        # a hand holding a lantern
    return c


# name in Sprites.as: (drawing const, fn or [frames], letters' base palette, tones, scale)
PROPS = {
    'TREE': (tree, {'tree': ({'g': 0x24561c, 'G': 0x3e8a2c, 'L': 0x6cc04a, 'T': 0x6b4423, 't': 0x442a14}, 3),
                    'startree': ({'g': 0x3a1e62, 'G': 0x6a3aa8, 'L': 0xb48aff, 'T': 0x2e2238, 't': 0x1a1222}, 3)}, {'1': ('L', 0.4)}),
    'PINE': (pine, {'pine': ({'g': 0x163c16, 'G': 0x2a6424, 'L': 0x4a9a3a, 'T': 0x5a3a1c, 't': 0x3a2410}, 3),
                    'starpine': ({'g': 0x2a1450, 'G': 0x55308e, 'L': 0x9a70e8, 'T': 0x2e2238, 't': 0x1a1222}, 3)}, {}),
    'PALM': (palm, {'palm': ({'G': 0x3a9a2a, 'L': 0x7ad060, 'T': 0x9a7040, 't': 0x6a4a28}, 3)}, {'g': ('G', -0.6)}),
    'DEADTREE': (deadtree, {'deadtree': ({'W': 0x6a5640, 'w': 0x3e3226}, 3)}, {'1': ('W', 0.3)}),
    'ROCK': (rock, {'rock': ({'k': 0x6a6a70, 'K': 0x8e8e96, 'L': 0xc0c0c8, 'd': 0x48484e}, 3)}, {}),
    'BOULDER': (boulder, {'boulder': ({'k': 0x4e4e54, 'K': 0x6a6a72, 'L': 0x9a9aa4, 'd': 0x34343a}, 3)}, {}),
    'PILLAR': (pillar, {'pillar': ({'L': 0xc8c8cc, 'l': 0x8a8a90, 'S': 0xa8a8b0, 's': 0x6a6a72}, 3)}, {'1': ('S', 0.35), '2': ('L', 0.4)}),
    'RUINWALL': (ruinwall, {'ruinwall': ({'L': 0xc8c8cc, 'S': 0xa0a0a8, 'l': 0x6a6a72}, 3)}, {}),
    'CRATE': (crate, {'crate': ({'K': 0x5a3a1a, 'C': 0xa0703a}, 3)}, {'1': ('C', 0.3), '2': ('C', -0.75)}),
    'CHEST': (chest, {'chest': ({'K': 0x4a2a10, 'C': 0x9a6a3a, 'c': 0x7a4a24, 'Y': 0xf0c030}, 3),
                      'chest_locked': ({'K': 0x2a2a30, 'C': 0x6a6a72, 'c': 0x4a4a52, 'Y': 0x9a9aa2}, 3)},
              {'1': ('C', 0.3), '3': ('Y', 0.45), 'y': ('Y', -0.65)}),
    'BAG': (bag, {'bag_brown': ({'K': 0x502a10, 'C': 0x9a6a3a, 'c': 0x6a4420, 'D': 0x5a3a1a}, 3),
                  'bag_purple': ({'K': 0x401060, 'C': 0xb050e0, 'c': 0x7a2aa8, 'D': 0x6a2090}, 3),
                  'bag_cyan': ({'K': 0x105060, 'C': 0x40d0f0, 'c': 0x1a90b0, 'D': 0x1a8098}, 3),
                  'bag_white': ({'K': 0x3a5a8a, 'C': 0xd8ecff, 'c': 0x9ac0e8, 'D': 0x7aa0d0}, 3),
                  'bag_fabled': ({'K': 0x4a1060, 'C': 0xc85cff, 'c': 0x8a30c0, 'D': 0x6a2090}, 3),
                  'bag_legendary': ({'K': 0x6a4a08, 'C': 0xffc23a, 'c': 0xc08a18, 'D': 0x9a6a10}, 3),
                  'bag_relic': ({'K': 0x601a08, 'C': 0xff5533, 'c': 0xc0301a, 'D': 0x8a2410}, 3)}, {'1': ('C', 0.4)}),
    'GRAVE': (grave, {'grave': ({'G': 0x9a9aa0, 'g': 0x6a6a70, 'D': 0x4a4a50, 'M': 0x3a6a2a}, 3)}, {'1': ('G', 0.35)}),
    'CAMPFIRE': ([campfire(0), campfire(1)], {'campfire': ({'Y': 0xffe040, 'F': 0xff6a20, 'W': 0xffffff, 'K': 0x5a3a1c, 'k': 0x3a2410}, 3)}, {}),
    'BRAZIER': ([brazier(0), brazier(1)], {'brazier': ({'Y': 0xffe040, 'F': 0xff7a20, 'W': 0xffffff, 'S': 0x6a6a72, 's': 0x44444a}, 3)}, {'1': ('S', 0.35)}),
    'CRYSTAL': (crystal, {'crystal': ({'W': 0xffd0e8, 'C': 0xff4080, 'c': 0xb01850, 'D': 0x600828, 'S': 0x3a1a2a}, 4)}, {'1': ('W', 0.5)}),
    'SHRINE': (shrine, {'shrine_might': ({'O': 0xff4040, 'o': 0xa01818, 'H': 0xffd0d0, 'S': 0xb0b0b8, 's': 0x6a6a72}, 3),
                        'shrine_haste': ({'O': 0x40e0ff, 'o': 0x1880a0, 'H': 0xd0f8ff, 'S': 0xb0b0b8, 's': 0x6a6a72}, 3),
                        'shrine_fortune': ({'O': 0xffd040, 'o': 0xa08010, 'H': 0xfff4c0, 'S': 0xb0b0b8, 's': 0x6a6a72}, 3),
                        'shrine_vigor': ({'O': 0x50e070, 'o': 0x208a38, 'H': 0xd0ffd8, 'S': 0xb0b0b8, 's': 0x6a6a72}, 3),
                        'shrine_arcana': ({'O': 0xb060ff, 'o': 0x6a28b0, 'H': 0xf0d8ff, 'S': 0xb0b0b8, 's': 0x6a6a72}, 3)},
               {'1': ('S', 0.35), '2': ('H', 0.6)}),
    'TENT': (tent, {'tent': ({'K': 0x3a2814, 'C': 0xb08a50, 'c': 0x806030, 'D': 0x2a1a0c}, 3)}, {'1': ('C', 0.3)}),
    'HUMANOID': (humanoid, {}, {'1': ('B', 0.3), '2': ('H', 0.3)}),
}


def tone(pal, spec):
    base, amt = spec
    return tint(pal[base], amt) if amt >= 0 else shade(pal[base], -amt)


def palette(base, tones):
    pal = dict(base)
    for k, spec in tones.items():
        if spec[0] in pal:
            pal[k] = tone(pal, spec)
    return pal


def frames(key):
    fn = PROPS[key][0]
    return [fr.rows() for fr in fn] if isinstance(fn, list) else [fn().rows()]


def as3():
    arrays, defs, tones_out = [], [], []
    for key, (fn, names, tones) in PROPS.items():
        fr = frames(key)
        arrays.append((key, '[' + ', '.join('[' + ', '.join('"%s"' % r for r in f) + ']' for f in fr) + ']'))
        for name, (pal, sc) in names.items():
            defs.append((name, '[%s, {%s}, %d]' % (key, ', '.join('%s: 0x%06x' % (k if k.isalpha() else '"%s"' % k, v) for k, v in palette(pal, tones).items()), sc)))
        tones_out.append((key, '{' + ', '.join('"%s": ["%s", %s]' % (k, b, a) for k, (b, a) in tones.items()) + '}'))
    return arrays, defs, tones_out


if __name__ == '__main__' and '--as3' in sys.argv:
    import json
    a, d, t = as3()
    print(json.dumps({'arrays': a, 'defs': d, 'tones': t}))
    sys.exit(0)

if __name__ == '__main__':
    from canvas import preview
    out = []
    for key, (fn, names, tones) in PROPS.items():
        fr = frames(key)
        for name, (pal, sc) in names.items():
            out.append((name, fr, palette(pal, tones)))
    # some of the game's recolours (Bosses.as, SetPieces.as)
    rc = [('CRYSTAL', {'W': 0xffffff, 'C': 0x9ad8ff, 'c': 0x4a90d0, 'D': 0x204a80, 'S': 0x1a2a3a}), ('PILLAR', {'L': 0xfff0a0, 'l': 0xb88e24, 'S': 0xf0cc50, 's': 0x9a7418}),
          ('BRAZIER', {'Y': 0xe0f0ff, 'F': 0x6090ff, 'W': 0xffffff, 'S': 0x4a4a6a, 's': 0x2a2a44}), ('CHEST', {'K': 0x2a0810, 'C': 0xa01830, 'c': 0x6a0a1c, 'Y': 0xffd040}),
          ('HUMANOID', {'H': 0x2a7a4a, 'h': 0x1a5030, 'S': 0xf5dc72, 'E': 0x101010, 'B': 0x2a8a5a, 'b': 0x1a5a3a, 'A': 0xf0c030, 'L': 0x3a2a14, 'W': 0xf0c030}),
          ('HUMANOID', {'H': 0xd06010, 'h': 0x8a3a08, 'S': 0xf5dc72, 'E': 0x101010, 'B': 0xff9a2e, 'b': 0xb06010, 'A': 0xffe080, 'L': 0x3a2014, 'W': 0xffe080})]
    for key, pal in rc:
        out.append((key.lower() + ' recolour', frames(key)[:1], palette(pal, PROPS[key][2])))
    preview(out, sys.argv[1] if len(sys.argv) > 1 else '/tmp/props.png', 4)
