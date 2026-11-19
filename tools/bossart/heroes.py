"""
The heroes, redrawn at 16x16 (they were 8x8): every class in three frames (standing, a step, the
attack), facing right, in the same palette letters as before so every skin and dye still recolours
them (Data.SKINS, Data.DYES). Shading adds tones the old drawings didn't have; those are digits, each
worked out from one of the class's letters (TONES below), so a skin that recolours a robe recolours
its light and shadow too (Sprites.retone does it in the game).

    python3 tools/bossart/heroes.py preview.png      a sheet of every hero, plain and in each skin
    python3 tools/bossart/heroes.py --as3            the AS3 for Sprites.as (frames, palettes, TONES)
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from canvas import Canvas

W = H = 16


def tint(c, t):
    r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    return (int(r + (255 - r) * t) << 16) | (int(g + (255 - g) * t) << 8) | int(b + (255 - b) * t)


def shade(c, f):
    r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    return (min(255, int(r * f)) << 16) | (min(255, int(g * f)) << 8) | min(255, int(b * f))


def tone(pal, spec):
    """A derived tone: (letter, +t) is the letter tinted toward white by t, (letter, -f) shaded to f."""
    base, amt = spec
    c = pal[base]
    return tint(c, amt) if amt >= 0 else shade(c, -amt)


# ---------------------------------------------------------------- the body every hero shares
def legs(c, f, mat='B', x0=6, y0=13):
    """Two legs and boots: apart on the stride frame."""
    if f == 1:
        c.rect(x0 - 1, y0, x0, 15, mat); c.rect(x0 + 3, y0, x0 + 4, 15, mat)
    else:
        c.rect(x0, y0, x0 + 1, 15, mat); c.rect(x0 + 3, y0, x0 + 4, 15, mat)


def face(c, x0=6, y0=5, w=4, h=3, eyes=True, skin='S'):
    c.rect(x0, y0, x0 + w - 1, y0 + h - 1, skin)
    if eyes:
        c.put(x0 + 1, y0 + 1, 'E'); c.put(x0 + w - 1, y0 + 1, 'E')


def robe(c, top, mat, dark, x0=4, x1=11, bottom=13, flare=1):
    """A robe from the shoulders (y=top) to the shins, widening by `flare` toward the hem."""
    for y in range(top, bottom + 1):
        k = (y - top) / max(1, bottom - top)
        a, b = x0 - int(round(flare * k)), x1 + int(round(flare * k))
        c.rect(a, y, b, y, mat)
    c.rect(x0 - flare, bottom, x1 + flare, bottom, dark)


def finish(c, light, mat, dark):
    """Light the edges of a material facing the top-left, darken the far ones (Canvas.shade)."""
    c.shade(mat, light, dark)


# ---------------------------------------------------------------- the classes
def wizard(f):
    c = Canvas(W, H)
    legs(c, f)
    robe(c, 8, 'R', 'r', 5, 10, 13, 2)
    c.rect(7, 8, 8, 12, 'W')                                  # the robe's white front
    # the pointed hat, its tip flopping back
    c.poly([(3, 6), (12, 6), (9, 0), (7, 0)], 'R')
    c.put(6, 0, 'R'); c.put(5, 1, 'r')
    c.rect(3, 5, 12, 5, 'r')                                  # its brim
    face(c, 6, 6, 4, 2)
    c.rect(6, 8, 9, 9, 'W'); c.put(7, 10, 'W'); c.put(8, 10, 'W')   # a white beard
    finish(c, '1', 'R', 'r')
    # the staff and its glowing gem, held out front (raised on the attack)
    sx = 13 if f != 2 else 14
    top = 2 if f != 2 else 0
    c.line(sx, top + 2, sx, 15 if f != 2 else 12, 'Y')
    c.ellipse(sx, top + 1, 1.2, 1.2, 'G'); c.put(sx, top + 1, '2')
    c.rect(11, 9, 12, 9, 'S') if f != 2 else c.rect(12, 8, 13, 8, 'S')    # the hand on it
    return c


def knight(f):
    c = Canvas(W, H)
    legs(c, f)
    c.rect(5, 8, 10, 12, 'M')                                 # armour
    c.rect(4, 8, 4, 10, 'm'); c.rect(11, 8, 11, 10, 'm')
    c.rect(5, 12, 10, 12, 'm')                                # the belt
    c.put(7, 12, 'A'); c.put(8, 12, 'A')
    finish(c, '3', 'M', 'm')
    # the great helm, a red plume, a visor slit
    c.rect(5, 2, 10, 7, 'H')
    c.rect(6, 1, 9, 1, 'H')
    c.rect(6, 4, 10, 4, 'h'); c.put(8, 4, 'E'); c.put(10, 4, 'E')
    c.line(7, 0, 4, 2, 'r'); c.put(3, 3, 'r'); c.put(8, 0, 'r')
    c.shade('H', '1', 'h')
    # the shield on its arm (in front), the sword out on the attack
    c.rect(1, 8, 4, 12, 'K'); c.rect(2, 13, 3, 13, 'K')
    c.line(2, 9, 2, 11, 'Q'); c.put(1, 10, 'Q'); c.put(3, 10, 'Q')
    c.shade('K', '2', 'k')
    if f == 2:
        c.line(11, 9, 15, 5, 'W'); c.put(11, 10, 'A'); c.put(10, 9, 'A'); c.put(12, 10, 'S')
    else:
        c.line(12, 3, 12, 10, 'W'); c.rect(11, 10, 13, 10, 'A'); c.put(12, 11, 'S')
    return c


def archer(f):
    c = Canvas(W, H)
    legs(c, f)
    # the cloak behind, the leather tunic, the hood
    c.poly([(3, 6), (10, 6), (11, 13), (2, 13)], 'g')
    c.rect(5, 8, 10, 12, 'L')
    c.rect(5, 11, 10, 11, 'l')
    finish(c, '2', 'L', 'l')
    c.poly([(4, 7), (11, 7), (10, 1), (6, 1)], 'G')
    c.put(5, 2, 'G'); c.put(4, 4, 'G')
    face(c, 6, 4, 4, 3)
    c.shade('G', '1', 'g')
    # the bow, drawn on the attack
    if f == 2:
        c.line(13, 2, 15, 6, 'W'); c.line(15, 6, 15, 9, 'W'); c.line(15, 9, 13, 13, 'W')
        c.line(13, 3, 11, 8, 'Y'); c.line(11, 8, 13, 12, 'Y')
        c.line(11, 8, 15, 8, 'Y'); c.put(11, 8, 'S')
    else:
        c.line(12, 2, 14, 6, 'W'); c.line(14, 6, 14, 10, 'W'); c.line(14, 10, 12, 14, 'W')
        c.line(12, 3, 12, 13, 'Y'); c.put(13, 8, 'S')
    return c


def priest(f):
    c = Canvas(W, H)
    legs(c, f)
    robe(c, 7, 'W', 'w', 5, 10, 13, 2)
    c.rect(7, 8, 8, 13, 'Y')                                  # the gold stole
    c.put(6, 9, 'Y'); c.put(9, 9, 'Y')
    c.poly([(4, 7), (11, 7), (10, 1), (6, 1)], 'W')           # the hood
    face(c, 6, 4, 4, 3)
    c.shade('W', '1', 'w')
    # a halo
    c.line(6, 0, 9, 0, 'Y')
    # the wand
    if f == 2:
        c.line(11, 8, 14, 4, 'Y'); c.ellipse(14.5, 3.5, 1, 1, 'G'); c.put(11, 9, 'S')
    else:
        c.line(12, 6, 12, 11, 'Y'); c.ellipse(12, 5, 1, 1, 'G'); c.put(12, 10, 'S')
    return c


def rogue(f):
    c = Canvas(W, H)
    legs(c, f)
    c.rect(5, 8, 10, 12, 'K')                                 # the dark leathers
    c.rect(5, 10, 10, 10, 'k')                                # a belt
    c.rect(7, 11, 8, 12, 'P')
    finish(c, '2', 'K', 'k')
    c.poly([(3, 9), (4, 7), (11, 7), (12, 9), (11, 12), (4, 12)], 'P', only='.')   # the cape behind
    c.poly([(4, 7), (11, 7), (10, 1), (6, 1)], 'P')           # the hood, pulled low
    c.put(5, 2, 'P'); c.put(11, 3, 'p')
    face(c, 6, 4, 4, 2)
    c.rect(6, 6, 9, 6, 'K')                                   # a mask over the mouth
    c.shade('P', '1', 'p')
    if f == 2:
        c.line(11, 9, 15, 7, 'W'); c.put(11, 10, 'S')
    else:
        c.line(12, 7, 12, 10, 'W'); c.put(12, 11, 'S'); c.put(13, 11, 'k')
    return c


def warrior(f):
    c = Canvas(W, H)
    legs(c, f)
    c.poly([(3, 8), (12, 8), (13, 13), (2, 13)], 'R')         # the red cape behind
    c.rect(5, 8, 10, 12, 'M')                                 # the armour
    c.rect(5, 12, 10, 12, 'm'); c.put(7, 12, 'A'); c.put(8, 12, 'A')
    c.shade('M', '3', 'm')
    c.shade('R', '4', 'r')
    # the horned helm over a bearded face
    c.rect(5, 1, 10, 4, 'H')
    c.rect(6, 0, 9, 0, 'H')
    c.rect(5, 4, 10, 4, 'h')                                  # its rim
    c.shade('H', '1', 'h')
    c.rect(6, 5, 9, 7, 'S'); c.put(7, 5, 'E'); c.put(9, 5, 'E')
    c.put(8, 4, 'h'); c.put(8, 5, 'h')                        # the nose guard
    c.rect(6, 7, 9, 7, 'h'); c.put(7, 8, 'h'); c.put(8, 8, 'h')   # a beard
    c.line(4, 2, 2, 0, 'Y'); c.put(4, 3, 'Y'); c.line(11, 2, 13, 0, 'Y'); c.put(11, 3, 'Y')
    # a great sword
    if f == 2:
        c.line(11, 9, 15, 3, 'W'); c.line(10, 10, 12, 8, 'A'); c.put(11, 10, 'S')
    else:
        c.line(13, 1, 13, 10, 'W'); c.rect(12, 10, 14, 10, 'A'); c.put(13, 11, 'S')
    return c


def necromancer(f):
    c = Canvas(W, H)
    legs(c, f)
    robe(c, 7, 'D', 'd', 5, 10, 13, 2)
    c.rect(7, 8, 8, 13, 'K')                                  # the blood-red sash
    c.poly([(4, 7), (11, 7), (10, 1), (6, 1)], 'D')           # the deep hood
    c.put(5, 2, 'D')
    c.rect(6, 4, 9, 6, 'd'); c.put(7, 5, 'E'); c.put(9, 5, 'E')   # a face in shadow, eyes glowing
    c.shade('D', '1', 'd')
    # a staff topped with a skull
    sx = 13 if f != 2 else 14
    c.line(sx, 3, sx, 15 if f != 2 else 12, 'W')
    c.rect(sx - 1, 0, sx + 1, 2, 'G'); c.put(sx - 1, 1, 'd'); c.put(sx + 1, 1, 'd')
    c.put(12, 9, 'S') if f != 2 else c.put(13, 8, 'S')
    return c


def huntress(f):
    c = Canvas(W, H)
    legs(c, f)
    # long red hair down her back
    c.rect(4, 2, 6, 10, 'R'); c.put(3, 9, 'R'); c.put(3, 10, 'r')
    c.rect(5, 8, 10, 12, 'G')                                 # the green tunic
    c.rect(5, 11, 10, 11, 'L')
    finish(c, '2', 'G', 'g')
    c.rect(6, 2, 10, 3, 'R'); c.put(7, 1, 'R'); c.put(9, 1, 'R')   # her fringe
    face(c, 6, 4, 4, 3)
    c.shade('R', '1', 'r')
    if f == 2:
        c.line(13, 2, 15, 6, 'W'); c.line(15, 6, 15, 9, 'W'); c.line(15, 9, 13, 13, 'W')
        c.line(13, 3, 11, 8, 'Y'); c.line(11, 8, 13, 12, 'Y'); c.line(11, 8, 15, 8, 'Y'); c.put(11, 8, 'S')
    else:
        c.line(12, 2, 14, 6, 'W'); c.line(14, 6, 14, 10, 'W'); c.line(14, 10, 12, 14, 'W')
        c.line(12, 3, 12, 13, 'Y'); c.put(13, 8, 'S')
    return c


def bard(f):
    c = Canvas(W, H)
    legs(c, f)
    c.rect(5, 8, 10, 12, 'V')                                 # the doublet
    c.line(5, 8, 10, 12, 'v'); c.line(10, 8, 5, 12, 'v')      # its slashed pattern
    c.rect(5, 12, 10, 12, 'v')
    finish(c, '2', 'V', 'v')
    # a feathered cap at a jaunty angle
    c.rect(4, 3, 10, 4, 'V'); c.rect(5, 2, 9, 2, 'V')
    c.line(9, 2, 13, 0, 'H'); c.line(10, 3, 14, 1, 'h')
    face(c, 6, 5, 4, 3)
    c.shade('V', '1', 'v')
    # the lyre, gold: two curling arms, a crossbar, a sound box and three strings
    lx, ly = (11, 5) if f != 2 else (11, 3)
    c.put(lx, ly, 'L'); c.line(lx, ly + 1, lx + 1, ly + 5, 'L')
    c.put(lx + 4, ly, 'L'); c.line(lx + 4, ly + 1, lx + 3, ly + 5, 'L')
    c.line(lx, ly + 1, lx + 4, ly + 1, 'L')
    c.rect(lx + 1, ly + 6, lx + 3, ly + 7, 'L')
    for x in (lx + 1, lx + 2, lx + 3):
        c.line(x, ly + 2, x, ly + 5, 'W', only='.')
    c.put(lx - 1, ly + 6, 'S')
    return c


def alchemist(f):
    c = Canvas(W, H)
    legs(c, f)
    c.rect(5, 8, 10, 12, 'A')                                 # the coat
    c.rect(6, 9, 9, 13, 'M')                                  # the leather apron
    c.put(6, 8, 'M'); c.put(9, 8, 'M')
    c.shade('A', '2', 'a')
    c.poly([(4, 7), (11, 7), (10, 1), (6, 1)], 'A')           # the hood
    face(c, 6, 4, 4, 3, eyes=False)
    c.rect(6, 4, 9, 4, 'a'); c.put(6, 4, 'G'); c.put(7, 4, 'G'); c.put(9, 4, 'G')   # goggles
    c.shade('A', '1', 'a')
    # a bubbling flask, thrown up on the attack
    fx, fy = (12, 8) if f != 2 else (13, 3)
    c.put(fx, fy, 'W'); c.rect(fx - 1, fy + 1, fx + 1, fy + 3, 'F'); c.put(fx, fy + 1, '3')
    c.put(fx + 1, fy - 1, 'F') if f == 2 else None
    c.put(11, 11, 'S') if f != 2 else c.put(11, 8, 'S')
    return c


def chronomancer(f):
    c = Canvas(W, H)
    legs(c, f)
    robe(c, 7, 'T', 't', 5, 10, 13, 2)
    c.rect(7, 8, 8, 13, 'Y')
    # a starry hood
    c.poly([(4, 7), (11, 7), (10, 1), (6, 1)], 'T')
    c.put(5, 2, 'T')
    face(c, 6, 4, 4, 3)
    c.shade('T', '1', 't')
    c.put(5, 9, 'O'); c.put(10, 11, 'O'); c.put(8, 2, 'O')    # stars
    # the golden hourglass
    hx, hy = (12, 7) if f != 2 else (13, 4)
    c.rect(hx - 1, hy, hx + 1, hy, 'Y'); c.rect(hx - 1, hy + 4, hx + 1, hy + 4, 'Y')
    c.put(hx - 1, hy + 1, 'O'); c.put(hx, hy + 1, 'O'); c.put(hx + 1, hy + 1, 'O'); c.put(hx, hy + 2, 'O')
    c.put(hx, hy + 3, 'W'); c.put(hx - 1, hy + 3, 'W'); c.put(hx + 1, hy + 3, 'W')
    c.put(hx - 1, hy + 5, 'S')
    return c


CLASSES = {
    'wizard': (wizard, {'R': 0xd03030, 'r': 0x8a1818, 'S': 0xf5dc72, 'E': 0x101010, 'W': 0xf4f4f4, 'Y': 0x8a5a2a, 'G': 0x60e0ff, 'B': 0x3a2010},
               {'1': ('R', 0.35), '2': ('G', 0.6)}),
    'knight': (knight, {'r': 0xd02020, 'H': 0xc8c8d0, 'h': 0x7a7a86, 'E': 0x101010, 'K': 0x3a5ad0, 'Q': 0xf0c030, 'M': 0xa8a8b4, 'm': 0x6a6a78,
                        'S': 0xf5dc72, 'A': 0xc89030, 'W': 0xf0f0ff, 'B': 0x2a2a30},
               {'1': ('H', 0.45), '2': ('K', 0.35), 'k': ('K', -0.6), '3': ('M', 0.4)}),
    'archer': (archer, {'G': 0x3a9a3a, 'g': 0x1e6a1e, 'S': 0xf5dc72, 'E': 0x101010, 'L': 0x8a5a2a, 'l': 0x5a3a18, 'W': 0xc08040, 'B': 0x3a2a14},
               {'1': ('G', 0.35), '2': ('L', 0.35), 'Y': ('W', 0.55)}),
    'priest': (priest, {'W': 0xf4f4f4, 'w': 0xa8a8b8, 'S': 0xf5dc72, 'E': 0x101010, 'Y': 0xe0b030, 'G': 0x70e0ff, 'B': 0x5a4030},
               {'1': ('W', 0.5)}),
    'rogue': (rogue, {'P': 0x6a2a8a, 'p': 0x3a1850, 'S': 0xf5dc72, 'E': 0x101010, 'K': 0x3a3a44, 'k': 0x22222a, 'W': 0xd8d8e8, 'B': 0x1a1a1a},
              {'1': ('P', 0.35), '2': ('K', 0.3)}),
    'warrior': (warrior, {'Y': 0xf0e0b0, 'H': 0xc0a060, 'h': 0x806a30, 'E': 0x101010, 'R': 0xb02020, 'M': 0xc83030, 'm': 0x802020, 'S': 0xf5dc72,
                          'A': 0xc89030, 'W': 0xf0f0ff, 'B': 0x2a1a10},
                {'1': ('H', 0.4), '3': ('M', 0.35), '4': ('R', 0.3), 'r': ('R', -0.6)}),
    'necromancer': (necromancer, {'D': 0x2e2e36, 'd': 0x18181c, 'S': 0xd8d0c0, 'E': 0xff3030, 'K': 0x9a1a1a, 'G': 0xe8e0c8, 'W': 0x5a3a2a, 'B': 0x101010},
                    {'1': ('D', 0.25)}),
    'huntress': (huntress, {'R': 0xd04a20, 'r': 0x8a2a10, 'S': 0xf5dc72, 'E': 0x101010, 'G': 0x4a8a3a, 'g': 0x2e5a24, 'L': 0x8a5a2a, 'W': 0xc08040, 'B': 0x3a2a14},
                 {'1': ('R', 0.35), '2': ('G', 0.35), 'Y': ('W', 0.55)}),
    'bard': (bard, {'V': 0x3a6ad0, 'v': 0x1e3a8a, 'H': 0xff4040, 'h': 0xa02020, 'S': 0xf5dc72, 'E': 0x101010, 'L': 0xe0b040, 'B': 0x5a3a1a},
             {'1': ('V', 0.35), '2': ('V', 0.2), 'W': ('L', 0.6)}),
    'alchemist': (alchemist, {'A': 0x2e7a6a, 'a': 0x184a40, 'G': 0x80ffe0, 'M': 0xc8a878, 'S': 0xf5dc72, 'E': 0x101010, 'F': 0x70ff50, 'B': 0x3a2a14},
                  {'1': ('A', 0.35), '2': ('A', 0.25), '3': ('F', 0.6), 'W': ('M', 0.4)}),
    'chronomancer': (chronomancer, {'T': 0x2a3a8a, 't': 0x141e4a, 'Y': 0xf0c040, 'O': 0x80e0ff, 'S': 0xf5dc72, 'E': 0x101010, 'B': 0x1a1a2a},
                     {'1': ('T', 0.35), 'W': ('Y', 0.6)}),
}

SKINS = {
    'wizard': [{'R': 0x3a7ad4, 'r': 0x1a4a8a, 'G': 0xffffff}, {'R': 0x2a2a34, 'r': 0x141418, 'Y': 0xa040ff, 'G': 0xff40a0}],
    'archer': [{'G': 0xc06a20, 'g': 0x8a4410}, {'G': 0x34343c, 'g': 0x1c1c22, 'W': 0xa0a0b0}],
    'knight': [{'H': 0xf0c840, 'h': 0xa88a20, 'M': 0xe0b030, 'm': 0x9a7818, 'K': 0x2a5ad0}, {'H': 0x3a3a44, 'h': 0x22222a, 'M': 0x2e2e38, 'm': 0x18181e, 'K': 0x7a1010, 'r': 0x5a0a0a}],
    'priest': [{'W': 0xfff0b0, 'w': 0xd8b860, 'G': 0xff9a20}, {'W': 0x2a2a34, 'w': 0x16161c, 'G': 0xff4040}],
    'rogue': [{'P': 0x9a1a1a, 'p': 0x5a0a0a}, {'P': 0xd8d8e8, 'p': 0x9a9aa8, 'K': 0xb8b8c8, 'k': 0x8a8a9a}],
    'warrior': [{'H': 0x8a8a92, 'h': 0x5a5a62, 'R': 0x2a5ad0, 'M': 0x3a6ae0, 'm': 0x1a3a8a}, {'R': 0x5a0a0a, 'M': 0x8a1010, 'm': 0x4a0808, 'Y': 0x2a2a2a}],
    'necromancer': [{'D': 0x2a4a6a, 'd': 0x142a40, 'E': 0x60e0ff, 'K': 0x2a8ad0}, {'D': 0x3a5a2a, 'd': 0x203a14, 'K': 0x6ad040, 'E': 0xffe040}],
    'huntress': [{'R': 0xe8f0ff, 'r': 0xa8b8d0, 'G': 0x6a8aa8, 'g': 0x4a6080}, {'R': 0x2a8a3a, 'r': 0x145a20, 'G': 0xc0a040, 'g': 0x8a7020}],
    'bard': [{'V': 0xd0302a, 'v': 0x8a1a14, 'H': 0xf0c030, 'h': 0xa08010}, {'V': 0x2a9ab0, 'v': 0x14606e, 'H': 0xc0f0ff, 'h': 0x70b0c0, 'L': 0xe0e8ff}],
    'alchemist': [{'A': 0x3a3a34, 'a': 0x22221e, 'G': 0x9aff40, 'M': 0x6a6a5a}, {'A': 0xa07a20, 'a': 0x6a4e10, 'G': 0xffe060, 'M': 0xfff0b0}],
    'chronomancer': [{'T': 0x4a2a7a, 't': 0x2a1448, 'Y': 0xff9ad8}, {'T': 0xe8e8f0, 't': 0xa8a8b8, 'Y': 0x40e0ff, 'O': 0x40e0ff}],
}


def palette(base, tones, over=None):
    pal = dict(base)
    if over:
        pal.update(over)
    for k, spec in tones.items():
        pal[k] = tone(pal, spec)
    return pal


def frames(cls):
    fn = CLASSES[cls][0]
    return [fn(f).rows() for f in range(3)]


CONST = {'wizard': 'WIZARD', 'archer': 'ARCHER', 'knight': 'KNIGHT', 'priest': 'PRIEST', 'rogue': 'ROGUE', 'warrior': 'WARRIOR',
         'necromancer': 'NECRO', 'huntress': 'HUNTRESS', 'bard': 'BARD', 'alchemist': 'ALCHEMIST', 'chronomancer': 'CHRONO'}


def as3():
    """The three blocks Sprites.as takes: the drawings, the DEFS lines and HERO_TONES."""
    arrays, defs, tones_out = [], [], []
    for cls, (fn, pal, tones) in CLASSES.items():
        fr = frames(cls)
        arrays.append('\t\tprivate static const %s:Array = [\n%s];' % (CONST[cls], ',\n'.join('\t\t\t[' + ', '.join('"%s"' % r for r in f) + ']' for f in fr)))
        p = palette(pal, tones)
        defs.append('\t\t\t%s: [%s, {%s}, 3],' % (cls, CONST[cls], ', '.join('"%s": 0x%06x' % (k, v) for k, v in p.items())))
        tones_out.append('\t\t\t%s: {%s}' % (cls, ', '.join('"%s": ["%s", %s]' % (k, b, a) for k, (b, a) in tones.items())))
    return '\n'.join(arrays), '\n'.join(defs), ',\n'.join(tones_out)


if __name__ == '__main__' and '--as3' in sys.argv:
    a, d, t = as3()
    print(a); print('----'); print(d); print('----'); print(t)
    sys.exit(0)

if __name__ == '__main__':
    from canvas import preview
    out = []
    for cls, (fn, pal, tones) in CLASSES.items():
        fr = frames(cls)
        for i, over in enumerate([None] + SKINS.get(cls, [])):
            p = palette(pal, tones, over)
            out.append((cls + ('' if i == 0 else ' skin %d' % i), [fr[0], fr[1], fr[2]] if i == 0 else [fr[0]], p))
    preview([(n, f, p) for n, f, p in out], sys.argv[1] if len(sys.argv) > 1 else '/tmp/heroes.png')
