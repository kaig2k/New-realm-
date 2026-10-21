"""
The realm's event bosses, modelled in solids and rendered to shaded pixel art (sdfart.py),
each keeping the look it had: the Cube Overlord, Vorgath the Ember Titan, the Hollow King,
the Phantom Regent, Nekhret the Sand Sphinx, the Lord of the Sunken Lands, the Tide Hermit
and the Skull Shrine. Each gives two idle frames (a breath, a flicker of its glow); animate.py
makes the rest. build.py uses these in place of the older flat drawings in designs.py.
"""
import math
from sdfart import Model, fur, rough, folds, scales, vnoise

LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'


def g(ramp, **k):
    d = {'ramp': ramp}
    d.update(k)
    return d


GLOW = lambda *c: {'ramp': list(c), 'glow': True}


# ---------------------------------------------------------------- the Cube Overlord
CUBE = {
    'top': g([0x4a1048, 0x7a1a78, 0xb02aa8, 0xd84ad0, 0xf088ec], gamma=1.0),
    'side': g([0x24082a, 0x3e0e44, 0x5e1866, 0x82248a]),
    'dark': g([0x12041a, 0x200830, 0x320c46]),
    'eye': GLOW(0x30c0e0, 0x80f0ff, 0xffffff),
    'pupil': g([0x05020a, 0x0c0414]),
    'shard': g([0x5a1460, 0x9a2aa0, 0xd060d0, 0xf8b0f8], spec=0.6),
}


def cube_overlord(t):
    m = Model(52, 52)
    bob = t
    # orbiting shards behind
    for k in range(4):
        a = k * math.pi / 2 + 0.4 + t * 0.25
        x, y = 26 + math.cos(a) * 22, 26 + math.sin(a) * 9 - bob
        if math.sin(a) < 0:
            m.sphere((x, y, -16), 2.6, 'shard', 1.0, 1.0, 1.0)
    # the cube: three faces (top, left, right) for an isometric block
    cx, cy = 26, 26 - bob
    top = [(cx, cy - 18), (cx + 16, cy - 9), (cx, cy), (cx - 16, cy - 9)]
    left = [(cx - 16, cy - 9), (cx, cy), (cx, cy + 19), (cx - 16, cy + 10)]
    right = [(cx, cy), (cx + 16, cy - 9), (cx + 16, cy + 10), (cx, cy + 19)]
    m.membrane(top, 0, 'top', (-0.3, -0.85), rough(0.06))
    m.membrane(left, 0, 'top', (-0.85, 0.15), rough(0.06))
    m.membrane(right, 0, 'side', (0.8, 0.2), rough(0.05))
    # glowing seams on its faces
    m.capsule((cx - 8, cy - 4.5, 1), (cx - 8, cy + 14.5, 1), 0.5, 0.5, 'eye')
    m.capsule((cx + 8, cy - 4.5, 1), (cx + 8, cy + 14.5, 1), 0.5, 0.5, 'eye')
    # the eye on the front edge
    m.sphere((cx, cy + 6, 4), 5.2, 'dark', 1.0, 0.85, 0.6)
    m.sphere((cx, cy + 6, 6.5), 3.6, 'eye', 1.0, 0.85, 0.6)
    m.sphere((cx, cy + 6, 8.6), 1.6, 'pupil', 0.8, 1.2, 0.5)
    for k in range(4):
        a = k * math.pi / 2 + 0.4 + t * 0.25
        x, y = 26 + math.cos(a) * 22, 26 + math.sin(a) * 9 - bob
        if math.sin(a) >= 0:
            m.sphere((x, y, 16), 2.6, 'shard')
    return m, CUBE


# ---------------------------------------------------------------- Vorgath the Ember Titan
TITAN = {
    'rock': g([0x140a06, 0x24140c, 0x3a2214, 0x54321e, 0x70462a, 0x8e5c38], spec=0.05),
    'far': g([0x0e0704, 0x1a0e08, 0x281610]),
    'horn': g([0x4a4034, 0x7a6c58, 0xa89a80, 0xd4c8ac]),
    'lava': GLOW(0xa02a08, 0xff6010, 0xffa040, 0xffe0a0),
    'core': GLOW(0xff7010, 0xffc050, 0xfff0c0),
}


def ember_titan(t):
    m = Model(54, 56)
    R = rough(0.12, 0.3, 3)
    # legs
    for s in (-1, 1):
        m.capsule((27 + s * 6, 38, -2), (27 + s * 7, 50, 0), 5, 4.4, 'rock', R)
        m.sphere((27 + s * 7.5, 51.5, 1), 4.8, 'rock', 1.2, 0.55, 1.1, R)
    # torso: a great slab of a chest
    m.sphere((27, 27, 0), 13, 'rock', 1.05, 0.95, 0.85, R)
    m.sphere((27, 14, 0), 7, 'rock', 1.5, 0.7, 0.85, R)
    # arms hanging, fists of molten rock
    for s in (-1, 1):
        m.sphere((27 + s * 14, 18, 3), 6, 'rock', 1, 1, 1, R)
        m.capsule((27 + s * 16, 21, 4), (27 + s * 19, 34, 6), 4.6, 4.0, 'rock', R)
        m.sphere((27 + s * 19.5, 38.5 + t * 0.5, 7), 4.6, 'rock', 1, 1, 1, R)
        m.sphere((27 + s * 19.5, 39.5 + t * 0.5, 9), 3.0, 'lava')
    # head sunk between the shoulders, horns, burning eyes
    m.sphere((27, 11, 6), 5.6, 'rock', 1.1, 0.9, 1, R)
    for s in (-1, 1):
        m.chain([(27 + s * 4, 8, 7), (27 + s * 10, 4, 6), (27 + s * 14, 0.6, 5)], [1.8, 1.2, 0.4], 'horn')
        m.sphere((27 + s * 2.4, 11, 11.4), 1.0, 'core')
    # the molten core in his chest
    m.sphere((27, 26, 11.5), 3.0 + t * 0.3, 'core', 1, 1.2, 0.5)

    def cracks(x, y, h):
        if h[2] != 'rock':
            return None
        v = vnoise((x + vnoise(x * 0.2, y * 0.2, 2) * 5) * 0.2, y * 0.2, 13)
        return 'lava' if abs(v - 0.5) < 0.016 and h[1][2] > 0.5 else None
    m.paint(cracks)
    return m, TITAN


# ---------------------------------------------------------------- the Hollow King
HOLLOW = {
    'robe': g([0x0e0618, 0x1a0c2c, 0x281444, 0x3a1e60, 0x522c80]),
    'trim': g([0x5a4010, 0x9a7020, 0xd8a830, 0xffe080], spec=0.6),
    'void': g([0x020104, 0x06030a]),
    'eye': GLOW(0x40c020, 0x90ff60, 0xe0ffc0),
    'staff': g([0x1e1a22, 0x3a3440, 0x5c5664, 0x847e8c], spec=0.3),
    'gem': GLOW(0x30a020, 0x80f060, 0xd8ffc0),
}


def hollow_king(t):
    m = Model(48, 56)
    F = folds(0.14, 3.2, 3)
    # the robe, wide and tattered at the floor
    m.capsule((24, 18, 0), (24, 48, 0), 6, 15, 'robe', F)
    m.sphere((24, 49, 0), 15, 'robe', 1, 0.28, 1, F)
    for k in range(7):
        m.capsule((11 + k * 4.3, 50, 4), (11 + k * 4.3, 54 - (k % 2) * 2, 4), 1.6, 0.6, 'robe')
    # gold trim down the front
    m.capsule((24, 20, 7), (24, 52, 14), 0.9, 1.2, 'trim')
    m.capsule((17, 19, 6), (31, 19, 6), 1.0, 1.0, 'trim')
    # the hood: an empty dark face
    m.sphere((24, 12, 2), 8, 'robe', 1, 1.05, 1, F)
    m.sphere((24, 13.5, 6.5), 5, 'void', 0.95, 1.1, 0.6)
    m.sphere((22, 13, 9.6), 0.9, 'eye'); m.sphere((26, 13, 9.6), 0.9, 'eye')
    # the crown
    m.capsule((17.5, 5.5, 4), (30.5, 5.5, 4), 1.6, 1.6, 'trim')
    for x in (18, 21, 24, 27, 30):
        m.capsule((x, 5, 4.5), (x, 1.5 if x == 24 else 2.8, 4.5), 1.0, 0.4, 'trim')
    # the arm and the staff, a green gem at its head
    m.capsule((32, 20, 5), (37, 30, 7), 2.6, 2.2, 'robe')
    m.capsule((39, 6, 6), (39, 52, 6), 0.9, 0.9, 'staff')
    m.sphere((38.6, 30, 9), 1.8, 'robe')
    m.sphere((39, 4.4, 7), 2.4 + t * 0.2, 'gem')
    return m, HOLLOW


# ---------------------------------------------------------------- the Phantom Regent
REGENT = {
    'shroud': g([0x2a2248, 0x433a6e, 0x6458a0, 0x8a7ec8, 0xb4aaea, 0xdcd6ff], gamma=1.1),
    'face': g([0x8a8aa8, 0xc0c0dc, 0xecebff]),
    'void': g([0x0c0818, 0x18122c]),
    'crown': g([0x6a4a12, 0xa47a1e, 0xe0b030, 0xfff0a0], spec=0.6),
    'wisp': GLOW(0x8a70e0, 0xc0b0ff, 0xf4f0ff),
    'eye': GLOW(0x9a6aff, 0xe0d0ff, 0xffffff),
}


def phantom_regent(t):
    m = Model(48, 54)
    F = folds(0.1, 3.6, 7)
    # a shroud that thins into wisps instead of feet
    m.capsule((24, 20, 0), (24, 40, 0), 7.5, 12, 'shroud', F)
    for k in range(6):
        x = 14 + k * 4 + (t if k % 2 else -t) * 0.6
        m.capsule((x, 40, 2), (x + (k - 2.5) * 0.8, 48 + (k % 3) * 2, 2), 2.6, 0.5, 'shroud')
    # arms: one reaching out with a sceptre
    m.capsule((16, 22, 4), (9, 30, 6), 3, 2, 'shroud', F)
    m.capsule((32, 22, 4), (38, 27, 6), 3, 2, 'shroud', F)
    m.capsule((39, 10, 7), (39, 40, 7), 0.8, 0.8, 'crown')
    for x in (37, 39, 41):
        m.capsule((x, 10, 7.5), (x, 6, 7.5), 0.6, 0.3, 'crown')
    # a pale mask of a face under the hood
    m.sphere((24, 13, 1), 8, 'shroud', 1, 1, 1, F)
    m.sphere((24, 14, 7.5), 5.0, 'face', 0.9, 1.1, 0.9)
    m.sphere((22, 13.5, 11.6), 1.0, 'void'); m.sphere((26, 13.5, 11.6), 1.0, 'void')
    m.sphere((22, 13.6, 12.4), 0.45, 'eye'); m.sphere((26, 13.6, 12.4), 0.45, 'eye')
    m.capsule((18.5, 5, 6), (29.5, 5, 6), 1.2, 1.2, 'crown')
    for x in (19, 22, 24, 26, 29):
        m.capsule((x, 4.6, 6.5), (x, 1 if x == 24 else 2.2, 6.5), 0.8, 0.3, 'crown')
    # wisps of its glow drifting round it
    for k in range(5):
        a = k * 1.3 + t * 0.6
        m.sphere((24 + math.cos(a) * 19, 30 + math.sin(a) * 14, 10), 0.9, 'wisp')
    return m, REGENT


# ---------------------------------------------------------------- Nekhret the Sand Sphinx
SPHINX = {
    'body': g([0x3a2410, 0x5c3a1a, 0x845628, 0xae7a3a, 0xd4a052, 0xecc47a], spec=0.08),
    'stone': g([0x2a1a0c, 0x44301a, 0x624826]),
    'gold': g([0x6a4808, 0xa87812, 0xe0b028, 0xfff09a], spec=0.7),
    'blue': g([0x0c1a4a, 0x163276, 0x2450aa, 0x3a74d8]),
    'eye': GLOW(0x2ab0ff, 0x8ee8ff, 0xffffff),
}


def sand_sphinx(t):
    m = Model(64, 44)
    R = rough(0.08, 0.3, 5)
    # lying down: a long lion body, paws stretched forward (to the right)
    m.sphere((26, 30, 0), 14, 'body', 1.4, 0.62, 0.9, R)
    m.sphere((12, 30, -2), 8, 'body', 1.0, 0.8, 1.0, R)                 # haunch
    m.capsule((36, 36, 5), (54, 38, 6), 3.4, 3.0, 'body', R)            # forepaws
    m.capsule((36, 37, -4), (52, 39, -4), 3.2, 2.8, 'stone')
    m.sphere((55, 38.4, 7), 3.4, 'body', 1.3, 0.7, 1, R)
    # tail curled at its side
    m.chain([(6, 32, 4), (2, 36, 5), (6, 40, 6), (12, 40, 6)], [1.6, 1.4, 1.2, 1.0], 'body')
    # the chest rising to a pharaoh's head
    m.sphere((40, 24, 3), 8, 'body', 1, 1.1, 0.9, R)
    # the headdress: striped blue and gold, falling to the shoulders
    m.capsule((44, 10, 2), (44, 26, 2), 7, 8.5, 'blue')

    def stripes(x, y, h):
        if h[2] == 'blue' and int(y / 2.2) % 2 == 0:
            return 'gold'
        return None
    m.paint(stripes)
    m.sphere((44, 13.5, 9), 5.2, 'body', 0.95, 1.05, 0.8, R)            # face
    m.capsule((38.6, 8.5, 6.5), (49.4, 8.5, 6.5), 1.3, 1.3, 'gold')     # the headband
    m.capsule((44, 8.2, 7.4), (44, 4 + t * 0.3, 7.4), 1.0, 0.5, 'gold') # the cobra on its brow
    m.capsule((38.6, 8.5, 9.5), (49.4, 8.5, 9.5), 1.3, 1.3, 'gold')     # the headband, in front
    m.sphere((42, 12.8, 13.2), 0.85, 'eye'); m.sphere((46, 12.8, 13.2), 0.85, 'eye')
    m.capsule((44, 18, 13), (44, 22.5, 12), 0.9, 0.6, 'gold')           # the beard
    return m, SPHINX


# ---------------------------------------------------------------- the Lord of the Sunken Lands
SUNKEN = {
    'armor': g([0x0a1616, 0x142626, 0x203a3a, 0x2e5250, 0x426e6a, 0x5e8c86], spec=0.4),
    'weed': g([0x0e2414, 0x1a3c22, 0x2a5a32]),
    'barn': g([0x4a4a3c, 0x7a7862, 0xaaa88c]),
    'rust': g([0x2a1a10, 0x4a2c18, 0x6a4024]),
    'eye': GLOW(0xd06010, 0xffa040, 0xffe0a0),
}


def sunken_lord(t):
    m = Model(50, 58)
    R = rough(0.1, 0.3, 9)
    for s in (-1, 1):
        m.capsule((25 + s * 5, 36, -1), (25 + s * 6, 52, 1), 4.4, 3.6, 'armor', R)
        m.sphere((25 + s * 6.4, 53.5, 2), 4, 'armor', 1.2, 0.55, 1.1, R)
    m.sphere((25, 28, 0), 11, 'armor', 0.95, 1.05, 0.85, R)
    for s in (-1, 1):
        m.sphere((25 + s * 11, 18, 2), 5.4, 'armor', 1.1, 0.9, 1, R)    # pauldrons
        m.capsule((25 + s * 12, 21, 3), (25 + s * 14, 34, 5), 3.4, 3.0, 'armor', R)
    # the helm: a closed visor with one burning slit
    m.sphere((25, 11, 3), 6.4, 'armor', 0.95, 1.1, 1, R)
    m.capsule((21.5, 11.5, 9.2), (28.5, 11.5, 9.2), 0.7, 0.7, 'eye')
    m.capsule((25, 4.4, 5), (25, -0.5, 4), 1.4, 0.4, 'armor')           # crest
    # the anchor it carries
    m.capsule((41, 8, 7), (41, 50, 7), 1.1, 1.1, 'rust')
    m.capsule((36, 12, 7), (46, 12, 7), 0.9, 0.9, 'rust')
    m.chain([(34, 44, 7), (37, 50, 7.5), (41, 52, 8), (45, 50, 7.5), (48, 44, 7)], [1.2, 1.3, 1.4, 1.3, 1.2], 'rust')
    m.sphere((40.5, 34, 9), 2.6, 'armor')                               # its hand on the shaft

    def growth(x, y, h):
        if h[2] != 'armor':
            return None
        v = vnoise(x * 0.35, y * 0.35, 21)
        if v > 0.78:
            return 'barn'
        if v < 0.16:
            return 'weed'
        return None
    m.paint(growth)
    return m, SUNKEN


# ---------------------------------------------------------------- the Tide Hermit
HERMIT = {
    'shell': g([0x3a2a1e, 0x5e4430, 0x86644a, 0xae8a68, 0xd4b28e, 0xecd2b0], spec=0.2),
    'band': g([0x5a2420, 0x8a3a30, 0xb85a44]),
    'crab': g([0x0e2a2a, 0x184442, 0x24605c, 0x348680, 0x4cae9e], spec=0.4),
    'claw': g([0x14403c, 0x226660, 0x349488, 0x5cc0ae], spec=0.6),
    'eye': GLOW(0x203018, 0xd0f040, 0xf8ff9a),
}


def tide_hermit(t):
    m = Model(58, 50)
    # the great spiral shell
    m.sphere((24, 24, 0), 17, 'shell', 1.05, 0.95, 0.9, rough(0.06))
    m.sphere((18, 18, 6), 9, 'shell', 1, 1, 1)
    m.sphere((14, 14, 11), 4.5, 'shell', 1, 1, 1)

    def spiral(x, y, h):
        if h[2] != 'shell':
            return None
        dx, dy = x - 16, y - 16
        r, a = math.hypot(dx, dy), math.atan2(dy, dx)
        v = (r - a * 3.2) % 7.0
        return 'band' if v < 1.4 else None
    m.paint(spiral)
    # the crab coming out of it: legs, body, eyestalks, two great claws
    for k in range(3):
        x = 30 + k * 5
        m.capsule((x, 38, 6), (x + 4, 47, 7), 1.6, 1.0, 'crab')
    m.sphere((40, 34, 6), 8, 'crab', 1.1, 0.8, 1, rough(0.05))
    for s, ex in ((0, 41), (1, 46)):
        m.capsule((ex, 30, 8), (ex + 1, 22 - t * 0.5, 9), 0.8, 0.6, 'crab')
        m.sphere((ex + 1, 21.4 - t * 0.5, 9.6), 1.6, 'eye')
    m.capsule((44, 36, 10), (51, 32, 12), 2.6, 2.4, 'claw')
    m.sphere((53, 29.5, 13), 4.6, 'claw', 1.2, 0.9, 1)
    m.capsule((53, 26, 14), (57, 22, 14), 1.6, 0.6, 'claw')
    m.capsule((36, 37, 11), (40, 43, 12), 2.2, 2.0, 'claw')
    m.sphere((42, 45, 12.5), 3.4, 'claw', 1.2, 0.8, 1)
    return m, HERMIT


# ---------------------------------------------------------------- the Skull Shrine
SHRINE = {
    'stone': g([0x14121a, 0x24202c, 0x363042, 0x4a4458, 0x625c72], spec=0.05),
    'bone': g([0x4a4436, 0x7c7460, 0xaea68c, 0xd8d2b8, 0xf2eedc], spec=0.15),
    'void': g([0x050308, 0x0c0812]),
    'flame': dict(GLOW(0x5a20b0, 0x9a58ff, 0xd0a8ff, 0xf4e8ff), glow0=0.0),
    'eye': dict(GLOW(0x6a20c0, 0xb070ff, 0xe8d0ff), glow0=0.05),
    'wax': g([0x8a8070, 0xc0b8a0, 0xece4cc]),
}


def skull_shrine(t):
    m = Model(58, 50)
    R = rough(0.1, 0.35, 4)
    # a stepped stone altar
    m.membrane([(4, 36), (54, 36), (56, 48), (2, 48)], 0, 'stone', (0, 0.6), R)
    m.membrane([(8, 30), (50, 30), (52, 37), (6, 37)], 2, 'stone', (0, -0.6), R)
    m.membrane([(6, 37), (52, 37), (54, 40), (4, 40)], 2.5, 'stone', (0, 0.9), R)
    # the great skull on it
    m.sphere((29, 18, 6), 12, 'bone', 1.05, 0.95, 0.9, rough(0.05))
    m.sphere((29, 28, 9), 7.5, 'bone', 1.0, 0.55, 0.8)                  # jaw
    for s in (-1, 1):
        m.sphere((29 + s * 5, 17, 15.5), 3.4, 'void', 1, 1.1, 0.5)
        m.sphere((29 + s * 5, 17.4, 17), 1.2 + t * 0.15, 'eye')
    m.sphere((29, 23, 16.6), 1.4, 'void', 0.9, 1.2, 0.4)               # the nose
    for k in range(6):
        m.capsule((24 + k * 2, 28.4, 15.6), (24 + k * 2, 30.6, 15.6), 0.7, 0.7, 'bone')
    m.capsule((22, 29.5, 16.4), (36, 29.5, 16.4), 0.4, 0.4, 'void')
    # candles with purple flames at its corners
    for x in (8, 15, 43, 50):
        m.capsule((x, 30, 8), (x, 24, 8), 1.5, 1.4, 'wax')
        m.sphere((x, 21.0 - (t if x % 2 else 0) * 0.5, 10), 1.9, 'flame', 0.8, 1.5, 1)
        m.capsule((x, 20, 11), (x + (0.6 if t else -0.6), 16.5, 11), 1.0, 0.3, 'flame')
    return m, SHRINE


MODELS = [
    ('boss', cube_overlord), ('titan', ember_titan), ('hollowking', hollow_king), ('regent', phantom_regent),
    ('sphinx', sand_sphinx), ('sunken_lord', sunken_lord), ('hermit', tide_hermit), ('shrine', skull_shrine),
]


def render(fn, t):
    m, mats = fn(t)
    img = m.render(mats)
    # a little room round it (animate.py draws auras and rays just outside the body)
    from PIL import Image
    out = Image.new('RGBA', (img.width + 4, img.height + 4), (0, 0, 0, 0))
    out.alpha_composite(img, (2, 2))
    return out


def _framer(rows_t, Pic):
    # (one argument only: animate.py passes a pose to drawings that take two)
    def frame(t):
        return Pic(rows_t[t % 2])
    return frame


def designs():
    """[(name, fn(t) -> object with rows(), palette, scale)] in designs.py's form."""
    out = []
    for name, fn in MODELS:
        imgs = [render(fn, 0), render(fn, 1)]
        rev, pal = {}, {}
        rows_t = []
        for im in imgs:
            px = im.load()
            rows = []
            for y in range(im.height):
                r = []
                for x in range(im.width):
                    p = px[x, y]
                    if p[3] < 128:
                        r.append('.')
                        continue
                    v = (p[0] << 16) | (p[1] << 8) | p[2]
                    if v not in rev:
                        assert len(rev) < len(LETTERS), name + ': too many colours'
                        rev[v] = LETTERS[len(rev)]
                        pal[rev[v]] = v
                    r.append(rev[v])
                rows.append(''.join(r))
            rows_t.append(rows)

        class Pic:
            def __init__(self, rows):
                self.r = rows

            def rows(self):
                return list(self.r)

        out.append((name, _framer(rows_t, Pic), pal, 3))
    return out


if __name__ == '__main__':
    import sys
    from PIL import Image
    ims = [render(fn, 0) for _, fn in MODELS]
    sc = 5
    W = sum(i.width * sc + 20 for i in ims) + 20
    H = max(i.height * sc for i in ims) + 40
    sheet = Image.new('RGBA', (W, H), (150, 146, 142, 255))
    x = 20
    for im in ims:
        z = im.resize((im.width * sc, im.height * sc), Image.NEAREST)
        sheet.alpha_composite(z, (x, H - z.height - 20))
        x += z.width + 20
    sheet.convert('RGB').save(sys.argv[1])
