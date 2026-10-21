"""
The realm's event bosses, modelled in solids and rendered to shaded pixel art (sdfart.py),
each keeping the look it had: the Cube Overlord, Vorgath the Ember Titan, the Hollow King,
the Phantom Regent, Nekhret the Sand Sphinx, the Lord of the Sunken Lands, the Tide Hermit
and the Skull Shrine. Each gives two idle frames (a breath, a flicker of its glow); animate.py
makes the rest. build.py uses these in place of the older flat drawings in designs.py.
"""
import math
from sdfart import Model, fur, rough, folds, scales, vnoise
from shaded_kit import wing

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
    m.anchor('cast', (cx, cy + 6)); m.anchor('handR', (cx + 16, cy)); m.anchor('handL', (cx - 16, cy))
    for k in range(4):
        a = k * math.pi / 2 + 0.4 + t * 0.25
        x, y = 26 + math.cos(a) * 22, 26 + math.sin(a) * 9 - bob
        if math.sin(a) >= 0:
            m.sphere((x, y, 16), 2.6, 'shard')
    return m, CUBE


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
    m.capsule((24, 18, 0), (24, 58, 0), 6, 16, 'robe', F, cut=50)
    m.sphere((24, 49.4, 0.5), 14.6, 'robe', 1, 0.16, 1, F)
    for k in range(7):
        m.part('hem%d' % (k % 2), (11 + k * 4.3, 50))
        m.capsule((11 + k * 4.3, 50, 4), (11 + k * 4.3, 54 - (k % 2) * 2, 4), 1.6, 0.6, 'robe')
    m.part(None)
    # gold trim down the front
    m.capsule((24, 20, 7), (24, 52, 14), 0.9, 1.2, 'trim')
    m.capsule((17, 19, 6), (31, 19, 6), 1.0, 1.0, 'trim')
    # the hood: an empty dark face
    m.part('head', (24, 19))
    m.sphere((24, 12, 2), 8, 'robe', 1, 1.05, 1, F)
    m.sphere((24, 13, 8.2), 4.6, 'void', 0.95, 1.0, 0.45)
    m.mark(22, 13, 'eye'); m.mark(26, 13, 'eye')                       # eyes burning in the dark of the hood
    # the crown
    m.capsule((17.5, 5.5, 4), (30.5, 5.5, 4), 1.6, 1.6, 'trim')
    for x in (18, 21, 24, 27, 30):
        m.capsule((x, 5, 4.5), (x, 1.5 if x == 24 else 2.8, 4.5), 1.0, 0.4, 'trim')
    # the arm and the staff, a green gem at its head
    m.part('armR', (32, 20))
    m.capsule((32, 20, 5), (37, 30, 7), 2.6, 2.2, 'robe')
    m.sphere((38.6, 30, 9), 1.8, 'robe')
    m.anchor('handR', (38.6, 30))
    m.part('heldR', (38.6, 30), 'armR')
    m.capsule((39, 6, 6), (39, 52, 6), 0.9, 0.9, 'staff')
    m.sphere((39, 4.4, 7), 2.4 + t * 0.2, 'gem')
    m.anchor('cast', (39, 4.4))
    m.part('armL', (16, 20))
    m.capsule((16, 20, 5), (12, 29, 6), 2.6, 2.0, 'robe')
    m.sphere((12, 30, 7), 1.6, 'robe')
    m.anchor('handL', (12, 30))
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
        m.part('hem%d' % (k % 2), (x, 40))
        m.capsule((x, 40, 2), (x + (k - 2.5) * 0.8, 48 + (k % 3) * 2, 2), 2.6, 0.5, 'shroud')
    # arms: one reaching out with a sceptre
    m.part('armL', (16, 22))
    m.capsule((16, 22, 4), (9, 30, 6), 3, 2, 'shroud', F)
    m.anchor('handL', (9, 30))
    m.part('armR', (32, 22))
    m.capsule((32, 22, 4), (38, 27, 6), 3, 2, 'shroud', F)
    m.anchor('handR', (38, 27))
    m.part('heldR', (38, 27), 'armR')
    m.capsule((39, 10, 7), (39, 40, 7), 0.8, 0.8, 'crown')
    for x in (37, 39, 41):
        m.capsule((x, 10, 7.5), (x, 6, 7.5), 0.6, 0.3, 'crown')
    m.anchor('cast', (39, 7))
    # a pale mask of a face under the hood
    m.part('head', (24, 21))
    m.sphere((24, 13, 1), 8, 'shroud', 1, 1, 1, F)
    m.sphere((24, 14, 7.5), 5.0, 'face', 0.9, 1.1, 0.9)
    m.sphere((22, 13.5, 11.6), 1.0, 'void'); m.sphere((26, 13.5, 11.6), 1.0, 'void')
    m.mark(22, 14, 'eye'); m.mark(26, 14, 'eye')
    m.capsule((18.5, 5, 6), (29.5, 5, 6), 1.2, 1.2, 'crown')
    for x in (19, 22, 24, 26, 29):
        m.capsule((x, 4.6, 6.5), (x, 1 if x == 24 else 2.2, 6.5), 0.8, 0.3, 'crown')
    # wisps of its glow drifting round it
    m.part(None)
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
    """Seated upright like a temple guardian, facing you: a lion's body on straight forelegs, great
    falcon wings raised behind, a pharaoh's striped headdress and a broad gold collar."""
    M = dict(SPHINX)
    M['wing'] = g([0x4a3418, 0x7a5a2c, 0xa8844a, 0xd2b070, 0xf0d8a0])
    M['tip'] = g([0x0c1a4a, 0x163276, 0x2450aa, 0x3a74d8])
    M['claw'] = g([0x2a1a0c, 0x4a3420, 0x6a5030])
    m = Model(64, 60)
    R = rough(0.08, 0.3, 5)
    # great falcon wings raised behind it: a gold leading edge, feathers hanging from it, lapis at the tips
    for sd in (-1, 1):
        root = (32 + sd * 7, 25)
        pts = wing(m, root, (sd * 0.72, -0.69), 31, 'wing', 'gold', -6, n=7, droop=0.62, side=sd)
        m.membrane(pts, -7.5, 'wing', (sd * 0.25, -0.2), R)
        m.anchor('hand' + ('R' if sd > 0 else 'L') + 'w', (root[0] + sd * 22, 3))

    def tips(x, y, h):
        if h[2] == 'wing' and abs(x - 32) > 20 and int((y + abs(x - 32) * 0.4) / 2.5) % 3 == 0:
            return 'tip'
        return None
    m.paint(tips)
    # haunches either side, the body sitting up between them
    m.part(None)
    for sd in (-1, 1):
        m.sphere((32 + sd * 10, 49, -1), 8.0, 'body', 1.05, 0.72, 0.8, R)     # haunches
        m.sphere((32 + sd * 14, 55.5, 2), 3.8, 'body', 1.35, 0.5, 1.0, R)      # the hind paws
    m.capsule((32, 28, 1), (32, 46, 2), 8.5, 9.5, 'body', R, cut=56)
    m.part('tail', (40, 52))
    m.chain([(40, 53, 6), (46, 57, 7), (52, 56, 7), (55, 52, 7)], [1.6, 1.4, 1.1, 0.8], 'body')
    m.sphere((55.5, 50.5, 7.5), 1.6, 'claw')
    # straight forelegs to big paws (the rig's arms: they rise to swipe)
    for sd in (-1, 1):
        S = 'R' if sd > 0 else 'L'
        m.part('arm' + S, (32 + sd * 5.5, 32))
        m.capsule((32 + sd * 5.5, 32, 6), (32 + sd * 5.5, 53, 8), 3.0, 2.6, 'body', R)
        m.sphere((32 + sd * 5.5, 55, 9.5), 3.2, 'body', 1.15, 0.7, 1.0, R)
        for c in (-1, 0, 1):
            m.mark(32 + sd * 5.5 + c * 1.6, 56, 'claw')
        m.anchor('hand' + S, (32 + sd * 5.5, 55))
    m.part(None)
    # a broad collar of gold and lapis on its chest
    m.sphere((32, 27.5, 6), 8.5, 'gold', 1.0, 0.5, 0.7)

    def collar(x, y, h):
        if h[2] == 'gold' and 23 < y < 32 and abs(x - 32) > 1:
            d = math.hypot(x - 32, (y - 23) * 1.6)
            return 'blue' if int(d / 2.2) % 2 else None
        return None
    m.paint(collar)
    # the head: a striped headdress falling to the shoulders, a calm face, the cobra on its brow
    m.part('head', (32, 26))
    m.capsule((32, 10, 1), (32, 17, 1), 6.2, 7.6, 'blue', cut=21)
    for sd in (-1, 1):
        m.capsule((32 + sd * 5.6, 14, 4), (32 + sd * 6.2, 24, 4.5), 2.3, 2.0, 'blue', cut=25)

    def stripes(x, y, h):
        if h[2] == 'blue' and int(y / 1.8) % 2 == 0:
            return 'gold'
        return None
    m.paint(stripes)
    m.sphere((32, 15, 7), 4.6, 'body', 0.9, 1.1, 1.1, R)                    # the face
    m.capsule((27, 10, 7), (37, 10, 7), 1.1, 1.1, 'gold')                   # the headband
    m.capsule((32, 9, 9.5), (32, 5 + t * 0.3, 9.5), 1.0, 0.5, 'gold')       # the cobra
    m.sphere((32, 4.6 + t * 0.3, 9.8), 1.1, 'gold', 1.2, 0.8, 1)
    for ex in (30, 34):
        m.mark(ex - 1, 13, None, 3, 1)
        m.mark(ex, 14, 'eye')
    m.mark(31, 17.5, None, 3, 1)                                            # the mouth's shadow
    m.capsule((32, 19.5, 11), (32, 23, 10.5), 0.9, 0.7, 'gold')             # the beard
    m.anchor('cast', (32, 5))
    m.part(None)
    return m, M


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
        m.part('legR' if k % 2 else 'legL', (x, 38))
        m.capsule((x, 38, 6), (x + 4, 47, 7), 1.6, 1.0, 'crab')
    m.part(None)
    m.sphere((40, 34, 6), 8, 'crab', 1.1, 0.8, 1, rough(0.05))
    m.part('head', (43, 31))
    for s, ex in ((0, 41), (1, 46)):
        m.capsule((ex, 30, 8), (ex + 1, 22 - t * 0.5, 9), 0.8, 0.6, 'crab')
        m.sphere((ex + 1, 21.4 - t * 0.5, 9.6), 1.6, 'eye')
    m.anchor('cast', (44, 21))
    m.part('armR', (44, 36))
    m.capsule((44, 36, 10), (51, 32, 12), 2.6, 2.4, 'claw')
    m.sphere((53, 29.5, 13), 4.6, 'claw', 1.2, 0.9, 1)
    m.capsule((53, 26, 14), (57, 22, 14), 1.6, 0.6, 'claw')
    m.anchor('handR', (54, 27))
    m.part('armL', (36, 37))
    m.capsule((36, 37, 11), (40, 43, 12), 2.2, 2.0, 'claw')
    m.sphere((42, 45, 12.5), 3.4, 'claw', 1.2, 0.8, 1)
    m.anchor('handL', (42, 45))
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
    m.part('head', (29, 34))
    m.sphere((29, 18, 6), 12, 'bone', 1.05, 0.95, 0.9, rough(0.05))
    m.part('jaw', (29, 26), 'head')
    m.sphere((29, 28, 9), 7.5, 'bone', 1.0, 0.55, 0.8)                  # jaw
    m.part('head', (29, 34))
    for s in (-1, 1):
        m.sphere((29 + s * 5, 17, 15.5), 3.4, 'void', 1, 1.1, 0.5)
        m.sphere((29 + s * 5, 17.4, 17), 1.2 + t * 0.15, 'eye')
    m.sphere((29, 23, 16.6), 1.4, 'void', 0.9, 1.2, 0.4)               # the nose
    m.anchor('cast', (29, 17)); m.anchor('handR', (34, 17)); m.anchor('handL', (24, 17))
    m.part('jaw', (29, 26), 'head')
    for k in range(6):
        m.capsule((24 + k * 2, 28.4, 15.6), (24 + k * 2, 30.6, 15.6), 0.7, 0.7, 'bone')
    m.capsule((22, 29.5, 16.4), (36, 29.5, 16.4), 0.4, 0.4, 'void')
    # candles with purple flames at its corners
    for x in (8, 15, 43, 50):
        m.part(None)
        m.capsule((x, 30, 8), (x, 24, 8), 1.5, 1.4, 'wax')
        m.part('hem%d' % (x % 2), (x, 23))
        m.sphere((x, 21.0 - (t if x % 2 else 0) * 0.5, 10), 1.9, 'flame', 0.8, 1.5, 1)
        m.capsule((x, 20, 11), (x + (0.6 if t else -0.6), 16.5, 11), 1.0, 0.3, 'flame')
    return m, SHRINE


MODELS = [
    ('boss', cube_overlord), ('hollowking', hollow_king), ('regent', phantom_regent),
    ('sphinx', sand_sphinx), ('hermit', tide_hermit), ('shrine', skull_shrine),
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


# how each boss moves (posed.py): which hand holds what, whether it walks or floats
RIG = {
    'boss': {'fly': True, 'arms': 0},
    'hollowking': {'legs': False, 'cast': 'one', 'held': 'staff'},
    'regent': {'fly': True, 'cast': 'one', 'held': 'staff'},
    'sphinx': {'legs': False, 'arms': 0.5, 'flap': 1.3, 'heavy': True},
    'hermit': {'legs': True, 'arms': 0.5, 'heavy': True},
    'shrine': {'legs': False, 'still': True, 'heavy': True},
}
