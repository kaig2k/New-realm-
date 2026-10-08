"""
Eldmere's boss designs. Each design(t) draws frame t (0 or 1, the idle
animation) and returns a Canvas; DESIGNS lists (name, function, palette,
scale). Sizes are 32x32 (some bigger): the game draws them at `scale`
pixels per cell, so a 32x32 boss at scale 4 is 128 pixels across.
"""
import math
from canvas import Canvas


# ----------------------------------------------------------------- Ignis, Warden of Embers
def ignis(t):
    c = Canvas(32, 32)
    # a cape of embers behind him, darker at the hem, licking flames at the edge
    c.poly([(8, 11), (24, 11), (27, 29), (16, 30), (5, 29)], 'C')
    c.shade('C', 'c', 'k')
    for i in range(7):
        x = 5 + i * 3.6
        h = 3 + (i * 7 + t * 3) % 4
        c.line(x, 29, x + (0.5 if (i + t) % 2 else -0.5), 29 + h * 0.6, 'F')
    # legs and armoured skirt
    c.rect(11, 23, 14, 29, 'A'); c.rect(18, 23, 21, 29, 'A')
    c.rect(10, 29, 14, 30, 'A'); c.rect(18, 29, 22, 30, 'A')
    c.poly([(9, 19), (23, 19), (24, 25), (8, 25)], 'A')
    # chest, pauldrons, gauntlets
    c.poly([(9, 11), (23, 11), (22, 20), (10, 20)], 'A')
    c.ellipse(8, 12, 4, 3, 'A'); c.ellipse(24, 12, 4, 3, 'A')
    c.rect(5, 14, 7, 20, 'A'); c.rect(25, 14, 27, 20, 'A')
    # helm with swept horns
    c.ellipse(16, 7, 5, 5, 'A')
    c.poly([(11, 5), (7, 1), (8, 0), (13, 3)], 'A')
    c.poly([(21, 5), (25, 1), (24, 0), (19, 3)], 'A')
    c.shade('A', 'a', 'd')
    # molten seams
    for (x0, y0, x1, y1) in [(12, 13, 14, 18), (20, 13, 18, 18), (11, 21, 13, 24), (21, 21, 19, 24), (6, 11, 9, 12), (26, 11, 23, 12), (12, 26, 12, 28), (20, 26, 20, 28)]:
        c.line(x0, y0, x1, y1, 'M')
    # a burning heart in the chest
    c.ellipse(16, 15, 2.2, 2.2, 'M')
    c.ellipse(16, 15, 1.2, 1.2, 'm')
    c.put(16, 15 - t, 'E')
    # visor slit, glowing
    c.rect(13, 7, 19, 8, 'k'); c.rect(14, 7, 18, 7, 'M'); c.put(14 + t, 7, 'E'); c.put(18 - t, 7, 'E')
    # flames streaming from the helm
    for i, h in enumerate([2, 4, 6, 4, 2]):
        x = 14 + i
        c.line(x, 2, x - 1 + t, 2 - h * 0.5, 'F' if i % 2 else 'f')
    # the blade: held down at his right side, burning along its length
    c.line(26, 20, 30, 31, 'S', 2)
    c.line(26, 20, 29, 29, 's', 1)
    c.line(24, 19, 28, 18, 'a', 1)   # crossguard
    c.line(26, 19, 25, 16, 'd', 1)   # grip
    for i in range(5):
        c.put(28 + (i + t) % 2, 21 + i * 2, 'f')
        c.put(30 - (i + t) % 2, 22 + i * 2, 'F')
    # embers drifting up
    for i in range(4):
        c.put(4 + i * 8 + t, 3 + (i * 5 + t * 2) % 6, 'f')
    return c


IGNIS_PAL = {'A': 0x4e3c3a, 'a': 0x806c64, 'd': 0x2a1c1c, 'M': 0xff6a18, 'm': 0xffd060, 'E': 0xfff6c0,
             'F': 0xff8a20, 'f': 0xffe070, 'S': 0xffe6b0, 's': 0xff7a28, 'C': 0xa02810, 'c': 0xd84a18, 'k': 0x4a0e08}


# ----------------------------------------------------------------- The Drowned Archivist
def archivist(t):
    c = Canvas(32, 32)
    bob = t
    # tattered robe, hunched, floating (no legs): a long fraying hem
    c.poly([(9, 10 + bob), (23, 10 + bob), (27, 27), (24, 30), (21, 27), (18, 31), (14, 27), (11, 30), (6, 27)], 'R')
    c.shade('R', 'r', 'q')
    # hood and the hunched back
    c.ellipse(16, 8 + bob, 7, 6, 'R')
    c.ellipse(16, 9 + bob, 4, 4, 'K')
    c.shade('R', 'r', 'q')
    # pale drowned face, two glowing eyes, a beard of tentacles
    c.ellipse(16, 9 + bob, 3, 3, 'P')
    c.put(15, 9 + bob, 'E'); c.put(17, 9 + bob, 'E')
    for i, dx in enumerate([-2, -1, 0, 1, 2]):
        L = 4 + (i + t) % 2
        for k in range(L):
            c.put(16 + dx + math.sin(k * 1.3 + i + t) * 0.8, 12 + bob + k, 'T' if k < L - 1 else 'p')
    # barnacles and kelp on the robe
    for (x, y) in [(10, 16), (22, 14), (12, 23), (21, 22), (17, 25), (8, 21)]:
        c.put(x, y + (bob if y < 20 else 0), 'B')
    for i in range(3):
        c.line(10 + i * 6, 27, 11 + i * 6 + t, 20, 'G')
    # the great open book held in front, its pages glowing
    c.poly([(9, 15 + bob), (16, 17 + bob), (23, 15 + bob), (23, 21 + bob), (16, 23 + bob), (9, 21 + bob)], 'O')
    c.line(16, 17 + bob, 16, 23 + bob, 'o')
    for k in range(3):
        c.line(11, 17 + k * 1.5 + bob, 14, 18 + k * 1.5 + bob, 'W')
        c.line(18, 18 + k * 1.5 + bob, 21, 17 + k * 1.5 + bob, 'W')
    c.rect(8, 15 + bob, 8, 21 + bob, 'o'); c.rect(24, 15 + bob, 24, 21 + bob, 'o')
    # hands gripping the book
    c.ellipse(8, 19 + bob, 1.4, 1.4, 'P'); c.ellipse(24, 19 + bob, 1.4, 1.4, 'P')
    # a lantern hanging from the hood, with a ghost light
    c.line(23, 5 + bob, 27, 3 + bob, 'o')
    c.line(27, 3 + bob, 27, 6 + bob, 'o')
    c.rect(26, 6 + bob, 28, 8 + bob, 'o')
    c.put(27, 7 + bob, 'L' if t else 'E')
    # floating runes of light
    for i in range(4):
        a = i * math.pi / 2 + t * 0.6
        c.put(16 + math.cos(a) * 13, 17 + math.sin(a) * 9, 'L')
    return c


ARCHIVIST_PAL = {'R': 0x2e5a5a, 'r': 0x4a8a84, 'q': 0x163030, 'K': 0x0a1414, 'P': 0xc8e8d8, 'E': 0x40ffd0,
                 'T': 0x5a9a7a, 'p': 0x8ad0a8, 'B': 0xd8d0b8, 'G': 0x3a7a3a, 'O': 0xe8dcb8, 'o': 0x6a4a2a,
                 'W': 0x60f0d0, 'L': 0xa0fff0}


# ----------------------------------------------------------------- Morvath the Bone Sovereign
def sovereign(t):
    c = Canvas(32, 32)
    # the bone throne behind him: a tall rounded back crowned with spikes and skulls
    c.poly([(6, 28), (6, 9), (9, 5), (16, 3), (23, 5), (26, 9), (26, 28)], 'T')
    for x, h in [(6, 6), (9, 8), (12, 6), (20, 6), (23, 8), (26, 6)]:
        c.poly([(x - 1, 9), (x, 9 - h), (x + 1, 9)], 'T')
    c.rect(3, 25, 29, 30, 'T')
    c.shade('T', 't', 'u')
    for (x, y) in [(6, 13), (26, 13), (6, 20), (26, 20)]:
        c.ellipse(x, y, 1.6, 1.4, 'B'); c.put(x - 1, y, 'K'); c.put(x + 1, y, 'K')
    for x in range(4, 29, 4):
        c.put(x, 27, 'u'); c.put(x + 1, 28, 'u')
    # robe of rotted purple
    c.poly([(10, 14), (22, 14), (25, 29), (7, 29)], 'P')
    c.shade('P', 'p', 'q')
    # ribcage showing through
    for k in range(4):
        c.line(12, 16 + k * 2, 15, 17 + k * 2, 'B')
        c.line(20, 16 + k * 2, 17, 17 + k * 2, 'B')
    c.line(16, 15, 16, 24, 'B')
    # arms on the throne's armrests, bony hands
    c.line(10, 15, 6, 22, 'P', 2); c.line(22, 15, 26, 22, 'P', 2)
    c.ellipse(6, 23, 1.5, 1.2, 'B'); c.ellipse(26, 23, 1.5, 1.2, 'B')
    # skull head with a tall crown
    c.ellipse(16, 10, 4, 4, 'B')
    c.rect(14, 13, 18, 14, 'B')
    c.shade('B', 'W', 'b')
    c.rect(14, 9, 15, 10, 'K'); c.rect(17, 9, 18, 10, 'K')
    c.put(14, 9, 'E' if t == 0 else 'e'); c.put(18, 9, 'E' if t == 0 else 'e')
    for x in (14, 16, 18):
        c.put(x, 13, 'K')
    c.poly([(11, 7), (21, 7), (22, 1), (19, 4), (16, 0), (13, 4), (10, 1)], 'Y')
    c.shade('Y', 'y', 'z')
    c.put(16, 4, 'R'); c.put(13, 5, 'G'); c.put(19, 5, 'G')
    # a soul-fire staff in his right hand
    c.line(27, 28, 27, 4, 'b', 1)
    c.ellipse(27, 3, 2, 2, 'G')
    c.put(27, 3, 'E')
    for i in range(3):
        c.put(27 + (i - 1) * 2, 0 + (i + t) % 2, 'e')
    return c


SOVEREIGN_PAL = {'T': 0x7a6e5a, 't': 0xb0a488, 'u': 0x3a3226, 'K': 0x140a14, 'B': 0xe8e0c8, 'W': 0xffffff, 'b': 0x9a9078,
                 'P': 0x5a1a4a, 'p': 0x8a3070, 'q': 0x2a0824, 'E': 0xd080ff, 'e': 0x8040e0, 'Y': 0xd0a030, 'y': 0xffe070,
                 'z': 0x806010, 'R': 0xff3050, 'G': 0xb060ff}


# ----------------------------------------------------------------- Astraeon, the Fallen Star (40x40)
def astraeon(t):
    c = Canvas(40, 40)
    cx, cy = 20, 19
    # rotating halo of starlight
    for i in range(28):
        a = i * math.pi / 14 + t * math.pi / 28
        c.put(cx + math.cos(a) * 18, cy + math.sin(a) * 16, 'W' if i % 7 == 0 else 'H')
    # eight-pointed star body
    pts = []
    for i in range(16):
        a = i * math.pi / 8 - math.pi / 2
        r = 15 if i % 2 == 0 else 6
        if i % 4 == 2:
            r = 10
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    c.poly(pts, 'G')
    c.shade('G', 'g', 'o')
    # an inner star, brighter
    pts2 = []
    for i in range(8):
        a = i * math.pi / 4 - math.pi / 2 + math.pi / 8
        r = 8 if i % 2 == 0 else 4
        pts2.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    c.poly(pts2, 'g')
    # the face: a calm mask in the heart of the star
    c.ellipse(cx, cy, 4, 4.5, 'M')
    c.shade('M', 'W', 'm')
    c.rect(cx - 2, cy - 1, cx - 1, cy - 1, 'E'); c.rect(cx + 1, cy - 1, cx + 2, cy - 1, 'E')
    c.put(cx, cy + 2, 'm')
    # crown of light above
    for i, h in enumerate([2, 4, 2]):
        c.line(cx - 2 + i * 2, cy - 5, cx - 2 + i * 2, cy - 5 - h - t, 'W')
    # shards orbiting
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4 + t * 0.4
        x, y = cx + math.cos(a) * 13, cy + math.sin(a) * 12
        c.poly([(x, y - 2), (x + 1, y), (x, y + 2), (x - 1, y)], 'S')
    # falling star dust beneath
    for i in range(6):
        c.put(cx - 6 + i * 2.4, 36 + ((i + t) % 3), 'g' if i % 2 else 'W')
    return c


ASTRAEON_PAL = {'H': 0x8a7ad0, 'W': 0xffffff, 'G': 0xf0c040, 'g': 0xfff0a0, 'o': 0xa07010, 'M': 0xfff4d8, 'm': 0xc8b080,
                'E': 0x2a1060, 'S': 0x9ad8ff}


DESIGNS = [
    ('vault_ignis', ignis, IGNIS_PAL, 4),
    ('vault_archivist', archivist, ARCHIVIST_PAL, 4),
    ('vault_sovereign', sovereign, SOVEREIGN_PAL, 4),
    ('astraeon', astraeon, ASTRAEON_PAL, 4),
]


# ----------------------------------------------------------------- Thunder Sentinel (a floating storm totem)
def sentinel(t):
    c = Canvas(28, 32)
    bob = t
    # stacked stone body, floating
    c.poly([(9, 8 + bob), (19, 8 + bob), (21, 24 + bob), (7, 24 + bob)], 'S')
    c.ellipse(14, 7 + bob, 6, 4, 'S')
    c.poly([(10, 24 + bob), (18, 24 + bob), (15, 28 + bob), (13, 28 + bob)], 'S')
    # floating stone arms
    c.poly([(2, 12 + bob), (6, 11 + bob), (6, 18 + bob), (3, 19 + bob)], 'S')
    c.poly([(26, 12 + bob), (22, 11 + bob), (22, 18 + bob), (25, 19 + bob)], 'S')
    c.shade('S', 's', 'd')
    # carved bands
    c.line(8, 13 + bob, 20, 13 + bob, 'd'); c.line(7, 20 + bob, 21, 20 + bob, 'd')
    # glowing rune eyes and a lightning core
    c.rect(11, 6 + bob, 12, 7 + bob, 'Y'); c.rect(16, 6 + bob, 17, 7 + bob, 'Y')
    c.ellipse(14, 16 + bob, 2.5, 2.5, 'L')
    c.put(14, 16 + bob, 'W')
    # lightning crackling between arms and core
    pts = [(5, 15), (8, 17 - t), (10, 15 + t), (12, 16)]
    for (a, b2) in zip(pts, pts[1:]):
        c.line(a[0], a[1] + bob, b2[0], b2[1] + bob, 'L')
    pts = [(23, 15), (20, 17 - t), (18, 15 + t), (16, 16)]
    for (a, b2) in zip(pts, pts[1:]):
        c.line(a[0], a[1] + bob, b2[0], b2[1] + bob, 'L')
    # rocks orbiting and a spark crown
    c.ellipse(4 + t, 4, 1.5, 1.2, 'S'); c.ellipse(24 - t, 3, 1.5, 1.2, 'S')
    for i in range(3):
        c.line(11 + i * 3, 3 + bob, 11 + i * 3 + (1 if (i + t) % 2 else -1), 0 + bob, 'Y')
    c.put(13, 31, 'L'); c.put(15, 30 - t, 'Y')
    return c


SENTINEL_PAL = {'S': 0x6a6a86, 's': 0x9a9ab8, 'd': 0x34344a, 'Y': 0xffff60, 'L': 0x80d0ff, 'W': 0xffffff}


# ----------------------------------------------------------------- The Void Dragon (wings spread, 40x32)
def void_dragon(t):
    c = Canvas(40, 32)
    flap = 2 if t else 0
    # wings: membranes with bony fingers, full of stars
    for side in (-1, 1):
        x0 = 20 + side * 5
        tip = (20 + side * 19, 3 + flap)
        c.poly([(x0, 10), tip, (20 + side * 17, 12 + flap), (20 + side * 18, 20), (20 + side * 13, 17), (20 + side * 11, 24), (x0, 18)], 'M')
        for f in range(3):
            c.line(x0, 11, 20 + side * (12 + f * 3), 4 + flap + f * 7, 'B')
    c.shade('M', 'm', 'v')
    for (x, y) in [(6, 9), (9, 14), (33, 8), (30, 15), (12, 10), (27, 11)]:
        c.put(x, y + (flap if y < 12 else 0), 'W')
    # long neck and horned head looking down at you
    c.poly([(16, 9), (24, 9), (23, 26), (17, 26)], 'D')
    c.ellipse(20, 8, 5, 4, 'D')
    c.poly([(16, 5), (13, 0), (17, 3)], 'B'); c.poly([(24, 5), (27, 0), (23, 3)], 'B')
    c.poly([(17, 10), (23, 10), (21, 14), (19, 14)], 'D')  # snout
    # tail curling below
    c.line(20, 26, 15, 30, 'D', 3); c.line(15, 30, 9, 29, 'D', 2); c.line(9, 29, 6, 26, 'D', 1)
    c.shade('D', 'd', 'k')
    # belly plates
    for k in range(5):
        c.line(18, 15 + k * 2, 22, 15 + k * 2, 'P')
    # eyes and the void breath glow
    c.put(18, 8, 'E'); c.put(22, 8, 'E')
    c.ellipse(20, 14, 1.2, 1, 'G' if t else 'E')
    return c


VOID_PAL = {'M': 0x4a2a7a, 'm': 0x7a50b0, 'v': 0x1e0e36, 'B': 0xd8c8ff, 'W': 0xffffff, 'D': 0x2a1a44, 'd': 0x5a3a88,
            'k': 0x0e0618, 'P': 0x8a5ac8, 'E': 0xff50ff, 'G': 0xffb0ff}


# ----------------------------------------------------------------- Tempestus, Heart of the Storm (40x36)
def tempestus(t):
    c = Canvas(40, 36)
    cx, cy = 20, 16
    # a churning storm cloud body
    for (x, y, r) in [(20, 16, 10), (11, 14, 6), (29, 14, 6), (14, 22, 6), (26, 22, 6), (20, 8, 6), (8, 20, 4), (32, 20, 4)]:
        c.ellipse(x + (t if x < 20 else -t) * 0.5, y, r, r * 0.85, 'C')
    c.shade('C', 'c', 'd')
    # the eye of the storm
    c.ellipse(cx, cy, 5, 4, 'd')
    c.ellipse(cx, cy, 3.5, 3, 'Y')
    c.ellipse(cx, cy, 1.5, 2.5, 'K')
    c.put(cx - 1, cy - 1, 'W')
    # swirling bands
    for i in range(10):
        a = i * 0.6 + t * 0.3
        r = 6 + i * 0.6
        c.put(cx + math.cos(a) * r, cy + math.sin(a) * r * 0.7, 'c')
    # lightning arms reaching down to the ground
    for side in (-1, 1):
        x, y = cx + side * 9, 22
        for k in range(5):
            nx, ny = x + side * (2 if (k + t) % 2 else -1), y + 2.5
            c.line(x, y, nx, ny, 'L', 2 if k < 2 else 1)
            x, y = nx, ny
        c.ellipse(x, y + 1, 2, 1, 'W')
    # rain
    for i in range(9):
        x = 8 + i * 3
        c.line(x - t, 27 + i % 3, x - 1 - t, 30 + i % 3, 'R')
    return c


TEMPEST_PAL = {'C': 0x5a6a9a, 'c': 0x9aaad8, 'd': 0x2a3458, 'Y': 0xfff060, 'K': 0x101020, 'W': 0xffffff,
               'L': 0xc0e8ff, 'R': 0x6a90d0}


# ----------------------------------------------------------------- Zealot of Blood (hooded, twin knives)
def zealot(t):
    c = Canvas(24, 28)
    # robe
    c.poly([(8, 9), (16, 9), (20, 26), (4, 26)], 'R')
    c.shade('R', 'r', 'k')
    c.line(12, 10, 12, 26, 'k')
    # a pointed hood casting the face in shadow
    c.poly([(7, 10), (12, -1), (17, 10)], 'R')
    c.ellipse(12, 8, 3, 3, 'R')
    c.shade('R', 'r', 'k')
    c.ellipse(12, 8, 2, 2, 'K')
    c.put(11, 8, 'E'); c.put(13, 8, 'E')
    # sash with a blood sigil
    c.line(7, 15, 17, 15, 'G')
    c.put(12, 15, 'Y')
    # arms out, curved knives dripping
    c.line(8, 11, 3, 15 - t, 'r', 2); c.line(16, 11, 21, 15 - t, 'r', 2)
    c.line(3, 15 - t, 1, 9 - t, 'S', 1); c.line(21, 15 - t, 23, 9 - t, 'S', 1)
    c.put(1, 10 - t, 's'); c.put(23, 10 - t, 's')
    c.put(2, 16 + t, 'B'); c.put(22, 17 - t, 'B')
    # blood pooling at the hem
    c.line(5, 27, 19, 27, 'B')
    return c


ZEALOT_PAL = {'R': 0x8a1020, 'r': 0xc02838, 'k': 0x3a0610, 'K': 0x120006, 'E': 0xffe040, 'G': 0xd0a040, 'Y': 0xff3040,
              'S': 0xe0e0e8, 's': 0xff4040, 'B': 0xb01020}


# ----------------------------------------------------------------- The Phoenix (wings of fire, 40x34)
def phoenix(t):
    c = Canvas(40, 34)
    up = -3 if t else 0
    for side in (-1, 1):
        # layered feathers fanning out
        for k in range(5):
            a = (-0.15 - k * 0.22) if side < 0 else (math.pi + 0.15 + k * 0.22)
            x0, y0 = 20 + side * 3, 13
            L = 17 - k * 1.5
            ex, ey = x0 - math.cos(a) * L * side * side, y0 + math.sin(a) * L * 0.6 + up * (1 - k * 0.15)
            ex = 20 + side * (6 + L)
            ey = 13 - (8 - k * 3) + up * (1 - k * 0.2)
            c.line(x0, y0, ex, ey, 'F' if k % 2 else 'O', 3)
            c.line(x0, y0, ex, ey, 'Y', 1)
    # body and long neck
    c.ellipse(20, 16, 4, 6, 'O')
    c.ellipse(20, 8, 2.5, 3, 'O')
    c.shade('O', 'Y', 'R')
    # crest of flame
    for i in range(4):
        c.line(19 + i * 0.7, 6, 17 + i * 1.5, 1 - (i + t) % 2, 'F')
    # beak and eye
    c.poly([(20, 9), (23, 10), (20, 11)], 'G')
    c.put(21, 8, 'K')
    # a long burning tail
    for k in range(4):
        x = 20 + (k - 1.5) * 2.5
        c.line(20, 21, x + (t if k % 2 else -t), 31, 'F' if k % 2 else 'O', 2)
        c.put(x, 32, 'Y')
    # sparks
    for i in range(5):
        c.put(6 + i * 7, 25 + (i + t) % 3 * 2, 'Y')
    return c


PHOENIX_PAL = {'F': 0xff4a10, 'O': 0xff9a20, 'Y': 0xffe070, 'R': 0xa02008, 'G': 0xffd040, 'K': 0x301000}


# ----------------------------------------------------------------- Galecaller Ysra (wind priestess, ribbons)
def galecaller(t):
    c = Canvas(30, 34)
    # flowing robe, wider at the hem, blown sideways
    c.poly([(11, 11), (19, 11), (24 + t, 31), (6 + t, 31)], 'R')
    c.shade('R', 'r', 'k')
    c.line(15, 12, 15 + t, 31, 'k')
    # wind ribbons spiralling around her
    for i in range(14):
        a = i * 0.45 + t * 0.5
        c.put(15 + math.cos(a) * (8 + i * 0.4), 18 + math.sin(a) * 4 - i * 0.6, 'W')
    for i in range(10):
        a = i * 0.5 + 3 + t * 0.5
        c.put(15 + math.cos(a) * 11, 24 + math.sin(a) * 3 - i * 0.3, 'w')
    # raised arms calling the wind
    c.line(11, 13, 6, 6 - t, 'r', 2); c.line(19, 13, 24, 6 - t, 'r', 2)
    c.ellipse(5, 5 - t, 1.3, 1.3, 'S'); c.ellipse(25, 5 - t, 1.3, 1.3, 'S')
    # head, a feathered headdress
    c.ellipse(15, 8, 3, 3.2, 'S')
    c.put(14, 8, 'E'); c.put(16, 8, 'E')
    for i, (dx, h) in enumerate([(-4, 5), (-2, 7), (0, 8), (2, 7), (4, 5)]):
        c.line(15 + dx * 0.6, 5, 15 + dx, 5 - h, 'F' if i % 2 else 'f', 1)
    c.line(12, 5, 18, 5, 'G')
    # a gem at her collar
    c.put(15, 12, 'G')
    return c


GALE_PAL = {'R': 0x3a7ab0, 'r': 0x70b0e8, 'k': 0x1a3a60, 'W': 0xe8fcff, 'w': 0x90d8ff, 'S': 0xf5dcb0, 'E': 0x2040a0,
            'F': 0xffffff, 'f': 0x90e0ff, 'G': 0x60ffff}


# ----------------------------------------------------------------- The Bog Witch (hat, cauldron, crooked staff)
def witch(t):
    c = Canvas(32, 34)
    # her body: a ragged shawl over a long dress
    c.poly([(10, 13), (22, 13), (25, 27), (7, 27)], 'P')
    for i in range(6):
        c.poly([(7 + i * 3, 26), (9 + i * 3, 26), (8 + i * 3, 29 - (i % 2))], 'P')
    c.shade('P', 'p', 'q')
    # bony arm stirring the pot with a ladle
    c.line(12, 15, 9, 21, 'S', 1.5)
    c.line(9, 21, 12 + t, 25, 'W', 1)
    # face beneath the brim: green skin, hooked nose, a wicked grin
    c.ellipse(16, 11, 3.2, 3.2, 'S')
    c.poly([(17, 11), (21, 13), (17, 12)], 'S')
    c.shade('S', 's', 'z')
    c.put(15, 10, 'E'); c.put(18, 10, 'E')
    c.line(14, 13, 17, 13, 'n')
    # wild grey hair under the hat
    for i in range(5):
        c.line(12 - i * 0.3, 8, 10 - i * 0.6, 14 + i, 'H')
        c.line(20 + i * 0.3, 8, 22 + i * 0.6, 14 + i, 'H')
    # the great crooked hat
    c.poly([(7, 8), (25, 8), (20, 6), (17, 1), (13, -1), (14, 3), (12, 6)], 'P')
    c.line(8, 8, 24, 8, 'P')
    c.shade('P', 'p', 'q')
    c.line(12, 7, 20, 7, 'Y')
    c.put(16, 7, 'G')
    # the cauldron in front, bubbling green
    c.ellipse(16, 29, 7, 4.5, 'K')
    c.shade('K', 'k', 'n')
    c.ellipse(16, 25.5, 6.5, 1.3, 'G')
    for i in range(4):
        c.ellipse(12 + i * 2.8, 24.5 - ((i + t) % 2), 0.9, 0.9, 'g')
    for i in range(4):
        c.put(20 + math.sin(i * 1.4 + t) * 1.5, 22 - i * 2, 'g')
    # crooked staff with a skull lantern
    c.line(28, 32, 27, 6, 'W', 1)
    c.ellipse(27, 5, 1.7, 1.7, 'B')
    c.put(26, 5, 'g' if t else 'E')
    return c


WITCH_PAL = {'K': 0x2a2a30, 'k': 0x50505a, 'n': 0x101014, 'G': 0x80ff40, 'g': 0xc0ff80, 'P': 0x3a2a5a, 'p': 0x6a4a90,
             'q': 0x1a1028, 'S': 0x8ab060, 'E': 0xffff40, 'H': 0x404850, 'Y': 0xc0ff40, 'W': 0x6a4a2a, 'B': 0xe8e0c8}


# ----------------------------------------------------------------- The Gearmind (clockwork construct)
def gearmind(t):
    c = Canvas(34, 32)
    # a great gear behind it, turning
    teeth = 12
    for i in range(teeth):
        a = i * 2 * math.pi / teeth + t * math.pi / teeth
        c.ellipse(17 + math.cos(a) * 13, 13 + math.sin(a) * 11, 1.8, 1.8, 'B')
    c.ellipse(17, 13, 12, 10, 'B')
    c.ellipse(17, 13, 8, 6.5, 'b')
    c.shade('B', 'Y', 'y')
    # body: a riveted boiler
    c.ellipse(17, 16, 7, 8, 'P')
    c.shade('P', 'Q', 'p')
    for (x, y) in [(12, 11), (22, 11), (11, 18), (23, 18), (17, 23)]:
        c.put(x, y, 'Y')
    # one great lens eye
    c.ellipse(17, 13, 3.5, 3.5, 'K')
    c.ellipse(17, 13, 2.5, 2.5, 'E')
    c.put(16, 12, 'W')
    c.put(17 + (1 if t else -1), 14, 'e')
    # piston arms with claws
    for side in (-1, 1):
        c.line(17 + side * 7, 17, 17 + side * 13, 22 + t, 'P', 2)
        c.line(17 + side * 13, 22 + t, 17 + side * 14, 27, 'p', 2)
        c.line(17 + side * 14, 27, 17 + side * 12, 30, 'Q', 1)
        c.line(17 + side * 14, 27, 17 + side * 16, 30, 'Q', 1)
    # legs and a vent of steam
    c.rect(13, 23, 15, 29, 'p'); c.rect(19, 23, 21, 29, 'p')
    c.rect(11, 29, 15, 30, 'P'); c.rect(19, 29, 23, 30, 'P')
    for i in range(3):
        c.put(17 + (i - 1) * 2, 2 - (i + t) % 2, 'W')
    c.rect(16, 3, 18, 5, 'p')
    return c


GEAR_PAL = {'B': 0xb08a40, 'b': 0x6a5020, 'Y': 0xf0d070, 'y': 0x5a3a10, 'P': 0x6a6a74, 'Q': 0xa0a0ac, 'p': 0x3a3a44,
            'K': 0x101010, 'E': 0x40ff80, 'e': 0xc0ffd0, 'W': 0xe8f0f0}


# ----------------------------------------------------------------- The Obsidian Colossus (huge, 40x40)
def colossus(t):
    c = Canvas(40, 40)
    # massive legs
    c.poly([(11, 26), (18, 26), (17, 38), (9, 38)], 'R')
    c.poly([(22, 26), (29, 26), (31, 38), (23, 38)], 'R')
    # torso, broad and blocky
    c.poly([(8, 11), (32, 11), (30, 27), (10, 27)], 'R')
    # huge fists, one raised
    c.poly([(2, 12), (8, 11), (9, 25), (3, 27)], 'R')
    c.poly([(32, 11 - t * 2), (38, 12 - t * 2), (37, 26 - t * 2), (31, 25 - t * 2)], 'R')
    c.rect(1, 25, 9, 31, 'R'); c.rect(31, 24 - t * 2, 39, 30 - t * 2, 'R')
    # a small head sunk between the shoulders
    c.poly([(15, 4), (25, 4), (26, 12), (14, 12)], 'R')
    c.shade('R', 'r', 'd')
    # glowing rune cracks
    for (x0, y0, x1, y1) in [(12, 14, 17, 21), (28, 14, 23, 21), (20, 18, 20, 26), (13, 29, 15, 35), (27, 29, 25, 35), (4, 16, 6, 22), (35, 15 - t * 2, 34, 21 - t * 2)]:
        c.line(x0, y0, x1, y1, 'L')
    c.ellipse(20, 17, 2.5, 2.5, 'L')
    c.ellipse(20, 17, 1.2, 1.2, 'W')
    # eyes, a heavy brow
    c.line(15, 7, 25, 7, 'd')
    c.rect(16, 8, 18, 8, 'Y'); c.rect(22, 8, 24, 8, 'Y')
    # rubble falling
    for i in range(4):
        c.put(6 + i * 9, 38 + (i + t) % 2, 'r')
    return c


COLOSSUS_PAL = {'R': 0x2a2a34, 'r': 0x56566a, 'd': 0x101016, 'L': 0x9a40ff, 'W': 0xe8c8ff, 'Y': 0xd080ff}


# ----------------------------------------------------------------- Archon Vesper (dark winged lord)
def archon(t):
    c = Canvas(36, 34)
    up = -2 if t else 0
    # great dark wings
    for side in (-1, 1):
        c.poly([(18 + side * 4, 10), (18 + side * 17, 2 + up), (18 + side * 16, 10 + up), (18 + side * 17, 18), (18 + side * 12, 16), (18 + side * 11, 24), (18 + side * 4, 18)], 'W')
        for f in range(4):
            c.line(18 + side * 5, 12 + f, 18 + side * (12 + f), 4 + f * 5 + up * (1 - f * 0.25), 'w')
    c.shade('W', 'w', 'k')
    # armoured robe
    c.poly([(13, 10), (23, 10), (26, 32), (10, 32)], 'P')
    c.shade('P', 'p', 'q')
    c.poly([(15, 14), (21, 14), (18, 22)], 'G')
    c.put(18, 16, 'R')
    # helm with a blood-red halo
    c.ellipse(18, 7, 3.5, 4, 'H')
    c.shade('H', 'h', 'q')
    c.rect(16, 7, 20, 7, 'K'); c.put(17, 7, 'E'); c.put(19, 7, 'E')
    c.ring(18, 3, 6, 2, 'R', 1)
    # a long spear of light
    c.line(29, 32, 29, 2, 'G', 1)
    c.poly([(29, 0), (31, 4), (29, 6), (27, 4)], 'R')
    c.line(23, 13, 29, 14, 'p', 2)
    return c


ARCHON_PAL = {'W': 0x2a0a18, 'w': 0x6a1030, 'k': 0x0e0206, 'P': 0x8a0a2a, 'p': 0xc02040, 'q': 0x3a0412, 'G': 0xffd040,
              'R': 0xff2040, 'H': 0xd8c8c8, 'h': 0xffffff, 'K': 0x100004, 'E': 0xff4060}


# ----------------------------------------------------------------- Matron Sanguine (blood queen)
def matron(t):
    c = Canvas(32, 34)
    # an enormous collar fanning behind her head
    for i in range(9):
        a = math.pi + i * math.pi / 8
        c.line(16, 11, 16 + math.cos(a) * 13, 11 + math.sin(a) * 10, 'C', 2)
    c.ellipse(16, 9, 8, 6, 'C')
    c.shade('C', 'c', 'k')
    # a sweeping gown, wide at the floor
    c.poly([(11, 12), (21, 12), (29, 32), (3, 32)], 'M')
    c.shade('M', 'm', 'k')
    for k in range(4):
        c.line(6 + k * 6, 32, 11 + k * 3, 16, 'm')
    c.line(9, 32, 23, 32, 'k')
    # pale face, red eyes, a crown of thorns
    c.ellipse(16, 9, 3, 3.5, 'Q')
    c.put(15, 9, 'E'); c.put(17, 9, 'E')
    c.put(16, 11, 'E')
    for i in range(5):
        c.line(13 + i * 1.5, 5, 13 + i * 1.5, 3 - (i % 2) * 2, 'Y')
    # holding up a chalice of blood
    c.line(21, 14, 25, 9, 'Q', 1)
    c.poly([(23, 6), (28, 6), (26, 9), (25, 9)], 'Y')
    c.line(25, 9, 25, 11, 'Y')
    c.line(24, 6, 27, 6, 'E')
    for i in range(3):
        c.put(25 + i - 1, 4 - (i + t) % 2, 'E')
    # drops of blood falling from the hem
    for i in range(4):
        c.put(6 + i * 7, 33 - (i + t) % 2, 'E')
    return c


MATRON_PAL = {'C': 0x6a0a1a, 'c': 0xa01830, 'k': 0x2a0008, 'M': 0x8a1020, 'm': 0xc03040, 'Q': 0xffd8d0, 'E': 0xff2020,
              'Y': 0xffc040}


# ----------------------------------------------------------------- The Tide Empress (mer-queen, trident)
def tide_empress(t):
    c = Canvas(32, 34)
    # a coiling fish tail
    c.line(16, 18, 13, 26, 'T', 6)
    c.line(13, 26, 18, 31, 'T', 4)
    c.poly([(18, 30), (25, 27 + t), (23, 33), (19, 32)], 'F')
    c.poly([(18, 30), (13, 34), (16, 34)], 'F')
    c.shade('T', 't', 'd')
    for k in range(5):
        c.put(14 + (k % 2), 20 + k * 2, 't')
    # body and arms
    c.ellipse(16, 14, 4, 5, 'S')
    c.shade('S', 's', 'z')
    c.line(13, 12, 7, 17, 'S', 2)
    c.line(19, 12, 24, 8, 'S', 2)
    # shell top and pearls
    c.ellipse(14, 14, 1.5, 1.2, 'P'); c.ellipse(18, 14, 1.5, 1.2, 'P')
    c.line(12, 17, 20, 17, 'W')
    # flowing sea-green hair and a coral crown
    c.ellipse(16, 6, 4, 4, 'S')
    for i in range(6):
        c.line(12 + i * 1.6, 4, 9 + i * 2.6 + t, 14 + (i % 2) * 2, 'H', 1)
    c.put(15, 6, 'E'); c.put(17, 6, 'E')
    for i, h in enumerate([2, 4, 3, 4, 2]):
        c.line(13 + i * 1.5, 2, 13 + i * 1.5 + (1 if i % 2 else 0), 2 - h, 'C')
    # the trident
    c.line(25, 32, 25, 2, 'Y', 1)
    for dx in (-2, 0, 2):
        c.line(25 + dx, 4, 25 + dx, 0, 'Y')
    c.line(23, 4, 27, 4, 'Y')
    # bubbles
    for i in range(4):
        c.ring(5 + i * 3, 25 - ((i + t) % 3) * 3, 1, 1, 'W', 0.8)
    return c


TIDE_PAL = {'T': 0x1a8ac0, 't': 0x50c8f0, 'd': 0x0a3a60, 'F': 0x80e8ff, 'S': 0x9ae0d0, 's': 0xd0fff0, 'z': 0x4a8a80,
            'P': 0xff80c0, 'W': 0xe8ffff, 'H': 0x2ac0a0, 'E': 0x101040, 'C': 0xff6080, 'Y': 0xffd060}


# ----------------------------------------------------------------- The Reef Kraken (40x36)
def kraken(t):
    c = Canvas(40, 36)
    # tentacles spread wide, curling at the tips
    for i in range(8):
        a = math.pi * (0.05 + i * 0.13)
        x0, y0 = 20, 16
        x, y = x0, y0
        w = 4
        for k in range(10):
            wob = math.sin(k * 0.8 + i + t * 1.5) * 0.6
            nx = x + math.cos(a + wob * 0.4) * 2.2
            ny = y + math.sin(a + wob * 0.4) * 2
            c.line(x, y, nx, ny, 'T', max(1, w))
            x, y = nx, ny
            w -= 0.35
            a += 0.08 * (1 if i < 4 else -1)
        c.ellipse(x, y, 1.2, 1.2, 'T')
    c.shade('T', 't', 'd')
    # suckers
    for i in range(8):
        a = math.pi * (0.05 + i * 0.13)
        c.put(20 + math.cos(a) * 8, 16 + math.sin(a) * 7, 'P')
    # the great bulbous head
    c.ellipse(20, 11, 9, 10, 'H')
    c.shade('H', 'h', 'k')
    for (x, y) in [(15, 6), (24, 5), (21, 9), (17, 12), (25, 13)]:
        c.put(x, y, 'P')
    # huge eyes, slit pupils
    for x in (15, 25):
        c.ellipse(x, 15, 2.5, 2, 'Y')
        c.line(x, 14, x, 16, 'K')
    # a beak
    c.poly([(19, 18), (21, 18), (20, 20)], 'B')
    return c


KRAKEN_PAL = {'T': 0x9a2a6a, 't': 0xd04a8a, 'd': 0x4a0a30, 'P': 0xffb0d0, 'H': 0x7a1a5a, 'h': 0xb0347a, 'k': 0x34061e,
              'Y': 0xffe040, 'K': 0x101010, 'B': 0x2a1a10}


DESIGNS += [
    ('sentinel', sentinel, SENTINEL_PAL, 4),
    ('void_dragon', void_dragon, VOID_PAL, 4),
    ('tempestus', tempestus, TEMPEST_PAL, 4),
    ('zealot', zealot, ZEALOT_PAL, 4),
    ('phoenix', phoenix, PHOENIX_PAL, 4),
    ('galecaller', galecaller, GALE_PAL, 4),
    ('witch', witch, WITCH_PAL, 4),
    ('gearmind', gearmind, GEAR_PAL, 4),
    ('colossus', colossus, COLOSSUS_PAL, 4),
    ('archon', archon, ARCHON_PAL, 4),
    ('matron', matron, MATRON_PAL, 4),
    ('tide_empress', tide_empress, TIDE_PAL, 4),
    ('kraken', kraken, KRAKEN_PAL, 4),
]


# ================================================================= realm event bosses and the Dark Elder
# ----------------------------------------------------------------- Cube Overlord
def cube_overlord(t):
    c = Canvas(34, 34)
    cx, cy = 17, 16
    # an isometric cube, faces lit differently
    top = [(cx, cy - 11), (cx + 10, cy - 6), (cx, cy - 1), (cx - 10, cy - 6)]
    left = [(cx - 10, cy - 6), (cx, cy - 1), (cx, cy + 11), (cx - 10, cy + 6)]
    right = [(cx + 10, cy - 6), (cx, cy - 1), (cx, cy + 11), (cx + 10, cy + 6)]
    c.poly(top, 'Q'); c.poly(left, 'P'); c.poly(right, 'p')
    # glowing circuit lines
    for k in range(3):
        c.line(cx - 8 + k * 3, cy - 3 + k * 1.5, cx - 8 + k * 3, cy + 4 + k * 1.5, 'L')
        c.line(cx + 2 + k * 3, cy + 3 - k * 1.5 + 3, cx + 2 + k * 3, cy - 3 - k * 1.5 + 6, 'L')
    # the great eye on its front edge
    c.ellipse(cx, cy + 3, 3, 2.5, 'W')
    c.ellipse(cx + (1 if t else -1), cy + 3, 1.3, 1.6, 'K')
    # a crown of floating cubes
    for i in range(6):
        a = i * math.pi / 3 + t * math.pi / 6
        x, y = cx + math.cos(a) * 15, cy + math.sin(a) * 13
        c.poly([(x, y - 2), (x + 2, y - 1), (x, y), (x - 2, y - 1)], 'Q')
        c.poly([(x - 2, y - 1), (x, y), (x, y + 2), (x - 2, y + 1)], 'P')
        c.poly([(x + 2, y - 1), (x, y), (x, y + 2), (x + 2, y + 1)], 'p')
    return c


CUBE_PAL = {'Q': 0xffa0ff, 'P': 0xd040e0, 'p': 0x7a1a90, 'L': 0x60f0ff, 'W': 0xffffff, 'K': 0x200030}


# ----------------------------------------------------------------- Vorgath the Ember Titan
def ember_titan(t):
    c = Canvas(36, 36)
    # thick legs of cooling rock
    c.poly([(10, 24), (17, 24), (16, 34), (8, 34)], 'R'); c.poly([(19, 24), (26, 24), (28, 34), (20, 34)], 'R')
    # a hunched rocky torso
    c.ellipse(18, 17, 11, 9, 'R')
    # huge arms, magma fists
    c.line(8, 13, 3, 25, 'R', 5); c.line(28, 13, 33, 25 - t, 'R', 5)
    c.ellipse(3, 27, 3, 3, 'M'); c.ellipse(33, 27 - t, 3, 3, 'M')
    # head with curling horns
    c.ellipse(18, 8, 5, 4.5, 'R')
    c.line(13, 6, 9, 1, 'B', 2); c.line(9, 1, 11, -1, 'B', 1)
    c.line(23, 6, 27, 1, 'B', 2); c.line(27, 1, 25, -1, 'B', 1)
    c.shade('R', 'r', 'd')
    # lava running through cracks
    for (x0, y0, x1, y1) in [(12, 13, 16, 20), (24, 12, 21, 19), (18, 18, 18, 24), (11, 26, 12, 32), (24, 26, 26, 32), (6, 16, 4, 22), (30, 16, 32, 22)]:
        c.line(x0, y0, x1, y1, 'L')
    c.ellipse(18, 15, 2.5, 2, 'L'); c.ellipse(18, 15, 1.2, 1, 'Y')
    # burning eyes and a mouth of fire
    c.rect(15, 7, 16, 8, 'Y'); c.rect(20, 7, 21, 8, 'Y')
    c.line(16, 11, 20, 11, 'L')
    # lava dripping from the fists
    c.put(3, 31 + t, 'L'); c.put(33, 31, 'L'); c.put(2, 33 - t, 'Y')
    return c


TITAN_PAL = {'R': 0x6a3a26, 'r': 0x9a5a3a, 'd': 0x2e160c, 'B': 0xd8c8a8, 'M': 0xff7020, 'L': 0xff5a10, 'Y': 0xffd040}


# ----------------------------------------------------------------- Sylith the Frost Wyrm
def frost_wyrm(t):
    c = Canvas(38, 34)
    # coiled serpent body, two loops
    pts = []
    for i in range(60):
        a = i * 0.21
        r = 12 - i * 0.12
        pts.append((19 + math.cos(a + t * 0.15) * r, 21 + math.sin(a + t * 0.15) * r * 0.55))
    for (a, b) in zip(pts, pts[1:]):
        c.line(a[0], a[1], b[0], b[1], 'C', 5 - (pts.index(a) / 20))
    # rising neck and head
    c.line(19, 20, 22, 9, 'C', 4)
    c.ellipse(23, 7, 5, 3.5, 'C')
    c.poly([(26, 6), (33, 8), (26, 9)], 'C')  # snout
    c.shade('C', 'W', 'c')
    # icicle spines along the neck and coils
    for i in range(0, 60, 6):
        x, y = pts[i]
        c.line(x, y - 2, x + 0.5, y - 5, 'I')
    for k in range(4):
        c.line(19 + k, 15 - k * 2, 17 + k, 12 - k * 2, 'I')
    # horns of ice
    c.line(21, 4, 17, 0, 'I', 1); c.line(24, 4, 23, -1, 'I', 1)
    # eye, frost breath
    c.put(25, 6, 'E')
    for i in range(5):
        c.put(34 + i * 0.8, 8 + (i % 2) - t, 'F')
    # snowflakes
    for (x, y) in [(4, 4), (8, 12), (33, 28), (3, 26)]:
        c.put(x + t, y, 'F')
    return c


WYRM_PAL = {'C': 0x7ac8f0, 'W': 0xe8f8ff, 'c': 0x2a6aa0, 'I': 0xd0f4ff, 'E': 0x1a2a6a, 'F': 0xffffff}


# ----------------------------------------------------------------- The Hollow King
def hollow_king(t):
    c = Canvas(32, 34)
    bob = t
    # tattered royal robe, empty and floating
    c.poly([(9, 12 + bob), (23, 12 + bob), (27, 30), (23, 33), (19, 30), (16, 33), (13, 30), (9, 33), (5, 30)], 'P')
    c.shade('P', 'p', 'k')
    c.line(16, 13 + bob, 16, 30, 'Y')
    # gold trim and a chain of office
    c.line(9, 12 + bob, 23, 12 + bob, 'Y')
    for i in range(5):
        c.put(11 + i * 2.5, 15 + bob + abs(i - 2) * 0.6, 'Y')
    # an empty hood with ghost-fire eyes
    c.ellipse(16, 8 + bob, 5, 5, 'P')
    c.shade('P', 'p', 'k')
    c.ellipse(16, 9 + bob, 3, 3, 'K')
    c.put(15, 9 + bob, 'G'); c.put(17, 9 + bob, 'G')
    # a crown hovering above, too big for anyone
    c.poly([(10, 4 + bob), (22, 4 + bob), (22, 0 + bob), (20, 2 + bob), (18, -1 + bob), (16, 1 + bob), (14, -1 + bob), (12, 2 + bob), (10, 0 + bob)], 'Y')
    c.shade('Y', 'y', 'z')
    c.put(16, 2 + bob, 'G')
    # gauntlets and a sceptre of green flame
    c.ellipse(7, 18 + bob, 1.6, 1.6, 'A'); c.ellipse(25, 18 + bob, 1.6, 1.6, 'A')
    c.line(25, 18 + bob, 27, 4 + bob, 'A', 1)
    c.ellipse(27, 3 + bob, 1.5, 1.8, 'G')
    c.put(27, 1 - t + bob, 'g')
    for i in range(4):
        c.put(6 + i * 7, 33 - (i + t) % 2, 'g')
    return c


HOLLOW_PAL = {'P': 0x4a1a6a, 'p': 0x7a3a9a, 'k': 0x1e0830, 'Y': 0xf0c030, 'y': 0xfff090, 'z': 0x8a6010, 'K': 0x080410,
              'G': 0x6aff4a, 'g': 0xc0ff9a, 'A': 0x9a9aa6}


# ----------------------------------------------------------------- Gorehorn the Behemoth
def behemoth(t):
    c = Canvas(38, 32)
    # a massive armoured beast, head on, lowering its horn
    c.ellipse(19, 17, 15, 10, 'G')
    # legs like pillars
    for x in (7, 13, 25, 31):
        c.rect(x - 2, 23, x + 2, 30 - (t if x in (13, 25) else 0), 'G')
    c.shade('G', 'g', 'd')
    # armour plates on the back
    for i in range(5):
        c.ellipse(9 + i * 5, 9, 3, 2.5, 'A')
    c.shade('A', 'a', 'd')
    # the head and the great horn
    c.ellipse(19, 18, 7, 6, 'H')
    c.shade('H', 'h', 'd')
    c.poly([(16, 16), (22, 16), (19, 3 - t)], 'B')
    c.poly([(19, 16), (22, 16), (19, 3 - t)], 'b')
    c.poly([(12, 15), (9, 11), (14, 13)], 'B'); c.poly([(26, 15), (29, 11), (24, 13)], 'B')
    # small furious eyes and steaming nostrils
    c.put(16, 19, 'E'); c.put(22, 19, 'E')
    c.put(17, 22, 'K'); c.put(21, 22, 'K')
    for i in range(3):
        c.put(15 - i - t, 23 + i, 'S'); c.put(23 + i + t, 23 + i, 'S')
    return c


BEHEMOTH_PAL = {'G': 0x5a9a38, 'g': 0x8ac860, 'd': 0x223a14, 'A': 0x7a6a50, 'a': 0xb0a080, 'H': 0x4a8a2c, 'h': 0x7ab850,
                'B': 0xf0e8d0, 'b': 0xb0a080, 'E': 0xff3020, 'K': 0x101010, 'S': 0xe0e0e0}


# ----------------------------------------------------------------- The Phantom Regent
def phantom_regent(t):
    c = Canvas(30, 34)
    bob = t
    # a ghostly body that fades into wisps
    c.poly([(9, 12 + bob), (21, 12 + bob), (24, 24 + bob), (20, 31), (17, 27 + bob), (14, 32), (11, 27 + bob), (7, 30), (6, 24 + bob)], 'M')
    c.shade('M', 'm', 'v')
    # a regal coat with a tall collar
    c.poly([(8, 7 + bob), (11, 12 + bob), (9, 14 + bob)], 'C'); c.poly([(22, 7 + bob), (19, 12 + bob), (21, 14 + bob)], 'C')
    c.line(15, 12 + bob, 15, 22 + bob, 'C')
    for k in range(3):
        c.put(15, 14 + k * 3 + bob, 'Y')
    # pale translucent face, hollow eyes, a powdered wig
    c.ellipse(15, 8 + bob, 3.5, 4, 'Q')
    c.ellipse(15, 5 + bob, 5, 2.5, 'W')
    c.ellipse(11, 8 + bob, 1.5, 2, 'W'); c.ellipse(19, 8 + bob, 1.5, 2, 'W')
    c.put(14, 9 + bob, 'E'); c.put(16, 9 + bob, 'E')
    # a small crown and a candelabra held out
    c.line(13, 2 + bob, 17, 2 + bob, 'Y'); c.put(13, 1 + bob, 'Y'); c.put(15, 0 + bob, 'Y'); c.put(17, 1 + bob, 'Y')
    c.line(22, 16 + bob, 26, 13 + bob, 'M', 1)
    c.line(24, 12 + bob, 28, 12 + bob, 'Y'); c.line(26, 12 + bob, 26, 15 + bob, 'Y')
    for x in (24, 26, 28):
        c.put(x, 11 + bob, 'F'); c.put(x, 10 + bob - ((x + t) % 2), 'f')
    return c


REGENT_PAL = {'M': 0x8a6ad0, 'm': 0xc0a8ff, 'v': 0x3a2a70, 'C': 0x4a2a8a, 'Y': 0xe0c060, 'Q': 0xe8e0ff, 'W': 0xf0f0ff,
              'E': 0x3a1a6a, 'F': 0xb070ff, 'f': 0xe0c0ff}


# ----------------------------------------------------------------- Nekhret the Sand Sphinx (lying, side view)
def sand_sphinx(t):
    c = Canvas(40, 30)
    # the long lion body, lying down
    c.ellipse(22, 20, 14, 6, 'T')
    c.rect(10, 22, 34, 26, 'T')
    # forepaws stretched forward
    c.rect(3, 23, 14, 26, 'T')
    c.ellipse(4, 25, 2.5, 1.8, 'T')
    # tail curled on the back
    c.line(35, 18, 38, 13, 'T', 1.5); c.ellipse(38, 12, 1.2, 1.2, 'T')
    c.shade('T', 't', 'd')
    # the head in a striped nemes headdress
    c.poly([(5, 6), (17, 6), (19, 18), (3, 18)], 'N')
    for k in range(5):
        c.line(5 + k * 0.2, 8 + k * 2, 18 - k * 0.2, 8 + k * 2, 'B')
    c.ellipse(11, 11, 4, 4.5, 'S')
    c.shade('S', 's', 'z')
    c.put(9, 10, 'E'); c.put(13, 10, 'E')
    c.line(10, 14, 12, 14, 'z')
    # cobra crown and false beard
    c.poly([(10, 6), (12, 6), (11, 2 - t)], 'Y')
    c.rect(10, 16, 12, 19, 'B')
    # hieroglyph stripes on the flank, and drifting sand
    for i in range(4):
        c.put(20 + i * 3, 21, 'B'); c.put(21 + i * 3, 23, 'Y')
    for i in range(5):
        c.put(2 + i * 8 + t, 28 - (i % 2), 't')
    return c


SPHINX_PAL = {'T': 0xc8a050, 't': 0xf0d090, 'd': 0x7a5a24, 'N': 0xf0c030, 'B': 0x2a4ab0, 'S': 0xd8b070, 's': 0xf8e0b0,
              'z': 0x8a6a34, 'E': 0x40e0ff, 'Y': 0xffe060}


# ----------------------------------------------------------------- Lord of the Sunken Lands (drowned knight, anchor)
def sunken_lord(t):
    c = Canvas(32, 34)
    # barnacled plate armour, slumped
    c.poly([(9, 12), (23, 12), (24, 25), (8, 25)], 'S')
    c.ellipse(8, 13, 3.5, 3, 'S'); c.ellipse(24, 13, 3.5, 3, 'S')
    c.rect(10, 25, 14, 32, 'S'); c.rect(18, 25, 22, 32, 'S')
    # great helm, streaming kelp
    c.ellipse(16, 7, 5, 5.5, 'S')
    c.shade('S', 's', 'd')
    c.rect(13, 7, 19, 8, 'K')
    c.put(14, 7, 'G'); c.put(18, 7, 'G')
    for i in range(5):
        c.line(11 + i * 2.5, 3, 10 + i * 3 + t, 14 + i % 2 * 3, 'W')
    # barnacles and starfish on the armour
    for (x, y) in [(10, 15), (21, 17), (13, 22), (20, 27), (6, 12), (25, 14)]:
        c.put(x, y, 'B')
    c.put(18, 20, 'O'); c.put(17, 20, 'O'); c.put(19, 20, 'O'); c.put(18, 19, 'O'); c.put(18, 21, 'O')
    # the anchor he swings as a weapon
    c.line(28, 4, 28, 28, 'A', 2)
    c.ellipse(28, 3, 2, 2, 'A'); c.ellipse(28, 3, 0.8, 0.8, 'K')
    c.line(24, 27, 32, 27, 'A', 2)
    c.line(24, 27, 24, 24, 'A', 1); c.line(32, 27, 32, 24, 'A', 1)
    c.line(23, 13, 27, 10, 'S', 2)
    # water dripping
    for i in range(3):
        c.put(10 + i * 6, 33 - (i + t) % 2, 'G')
    return c


SUNKEN_PAL = {'S': 0x4a6a7a, 's': 0x7a9aa8, 'd': 0x1e3038, 'K': 0x081014, 'G': 0x60f0e0, 'W': 0x3a8a4a, 'B': 0xe8e0c8,
              'O': 0xff8040, 'A': 0x5a5a62}


# ----------------------------------------------------------------- The Tide Hermit (giant hermit crab)
def tide_hermit(t):
    c = Canvas(38, 32)
    # a huge spiral shell
    c.ellipse(22, 13, 12, 11, 'S')
    c.shade('S', 's', 'd')
    for i in range(40):
        a = i * 0.32
        r = 10 - i * 0.24
        c.put(22 + math.cos(a) * r, 13 + math.sin(a) * r * 0.9, 'd')
    for (x, y) in [(14, 6), (30, 8), (27, 20), (16, 19)]:
        c.put(x, y, 'B')
    c.ellipse(17, 4, 2, 1.5, 'C')  # coral growing on it
    c.line(17, 4, 15, 0, 'C'); c.line(17, 4, 19, 1, 'C')
    # the crab peeking out: eyes on stalks, big claws
    c.ellipse(10, 21, 6, 4, 'R')
    c.line(8, 17, 7, 12 + t, 'R'); c.line(12, 17, 13, 12 + t, 'R')
    c.put(7, 11 + t, 'E'); c.put(13, 11 + t, 'E')
    c.ellipse(4, 18 - t, 4, 3, 'R'); c.poly([(1, 16 - t), (-1, 13 - t), (3, 15 - t)], 'R')
    c.ellipse(15, 26, 4, 3, 'R'); c.poly([(18, 25), (21, 22), (19, 26)], 'R')
    for x in (6, 9, 12):
        c.line(x, 24, x - 2, 29, 'R', 1)
    c.shade('R', 'r', 'k')
    # bubbles
    for i in range(3):
        c.ring(3 + i * 2, 8 - ((i + t) % 3) * 2, 0.8, 0.8, 'W', 0.7)
    return c


HERMIT_PAL = {'S': 0xd8b8a0, 's': 0xf8e8d8, 'd': 0x8a6a5a, 'B': 0x9a8a7a, 'C': 0xff6080, 'R': 0x2a9a8a, 'r': 0x5ad0b8,
              'k': 0x0e4a40, 'E': 0x101010, 'W': 0xd0f8ff}


# ----------------------------------------------------------------- The Skull Shrine (a stationary altar)
def skull_shrine(t):
    c = Canvas(36, 32)
    # stepped altar
    c.rect(2, 26, 33, 31, 'A'); c.rect(5, 22, 30, 26, 'A')
    c.shade('A', 'a', 'd')
    for x in range(4, 33, 4):
        c.put(x, 28, 'd')
    # a pile of skulls
    for (x, y, r) in [(9, 21, 2.5), (14, 21, 2.5), (22, 21, 2.5), (27, 21, 2.5), (11, 18, 2.3), (25, 18, 2.3)]:
        c.ellipse(x, y, r, r * 0.9, 'B')
    c.shade('B', 'W', 'b')
    for (x, y) in [(9, 21), (14, 21), (22, 21), (27, 21), (11, 18), (25, 18)]:
        c.put(x - 1, y, 'K'); c.put(x + 1, y, 'K')
    # the great skull at the top
    c.ellipse(18, 11, 7, 7, 'B')
    c.rect(14, 16, 22, 19, 'B')
    c.shade('B', 'W', 'b')
    c.ellipse(15, 11, 2, 2.2, 'K'); c.ellipse(21, 11, 2, 2.2, 'K')
    c.put(15, 11, 'R' if t else 'r'); c.put(21, 11, 'R' if t else 'r')
    c.poly([(18, 13), (17, 15), (19, 15)], 'K')
    for x in range(15, 22, 2):
        c.put(x, 18, 'K')
    # candles flickering on both sides
    for x in (4, 31):
        c.rect(x - 1, 14, x + 1, 22, 'W')
        c.put(x, 13, 'F'); c.put(x + (1 if t else -1), 12, 'f')
    # purple soul-fire above
    for i in range(5):
        c.put(14 + i * 2, 3 - (i + t) % 2 * 2, 'P')
    return c


SHRINE_PAL = {'A': 0x5a5048, 'a': 0x8a8070, 'd': 0x2a241e, 'B': 0xd8d0b8, 'W': 0xfffff0, 'b': 0x8a8268, 'K': 0x14080e,
              'R': 0xff2030, 'r': 0xa01020, 'F': 0xffb040, 'f': 0xfff0a0, 'P': 0xc060ff}


# ----------------------------------------------------------------- Azrakor the Dark Elder (40x40)
def dark_elder(t):
    c = Canvas(40, 40)
    # a vast cloak of the void, the hem dissolving
    c.poly([(12, 12), (28, 12), (36, 34), (30, 39), (26, 35), (20, 39), (14, 35), (10, 39), (4, 34)], 'K')
    c.shade('K', 'k', 'n')
    for (x, y) in [(10, 28), (16, 32), (25, 30), (31, 27), (19, 24), (13, 20), (27, 20)]:
        c.put(x, y, 'S')
    # ornate robe inside the cloak
    c.poly([(15, 13), (25, 13), (27, 34), (13, 34)], 'P')
    c.shade('P', 'p', 'q')
    c.line(20, 14, 20, 33, 'Q')
    for k in range(4):
        c.put(20, 16 + k * 4, 'O')
    # arms raised, channelling
    c.line(14, 15, 7, 9 - t, 'P', 2); c.line(26, 15, 33, 9 - t, 'P', 2)
    c.ellipse(6, 8 - t, 2.5, 2.5, 'O'); c.ellipse(34, 8 - t, 2.5, 2.5, 'O')
    c.put(6, 8 - t, 'W'); c.put(34, 8 - t, 'W')
    # horned hood, a face of eyes
    c.ellipse(20, 9, 5.5, 6, 'P')
    c.line(15, 6, 10, 0, 'H', 2); c.line(10, 0, 8, 1, 'H', 1)
    c.line(25, 6, 30, 0, 'H', 2); c.line(30, 0, 32, 1, 'H', 1)
    c.shade('P', 'p', 'q')
    c.ellipse(20, 10, 3.5, 4, 'n')
    for (x, y) in [(18, 9), (22, 9), (20, 11), (19, 13), (21, 13)]:
        c.put(x, y, 'E')
    c.put(20, 7, 'W' if t else 'E')
    # crystals of the abyss orbiting
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4 + t * 0.3
        x, y = 20 + math.cos(a) * 17, 22 + math.sin(a) * 15
        c.poly([(x, y - 3), (x + 1.5, y), (x, y + 3), (x - 1.5, y)], 'O')
    return c


ELDER_PAL = {'K': 0x120818, 'k': 0x2e1a3e, 'n': 0x05020a, 'S': 0xc0a0ff, 'P': 0x5a2a8a, 'p': 0x8a50c0, 'q': 0x2a0e40,
             'Q': 0xe0b030, 'O': 0x60f0ff, 'W': 0xffffff, 'H': 0xd8d0c0, 'E': 0xff3040}


DESIGNS += [
    ('boss', cube_overlord, CUBE_PAL, 4),
    ('titan', ember_titan, TITAN_PAL, 4),
    ('wyrm', frost_wyrm, WYRM_PAL, 4),
    ('hollowking', hollow_king, HOLLOW_PAL, 4),
    ('behemoth', behemoth, BEHEMOTH_PAL, 4),
    ('regent', phantom_regent, REGENT_PAL, 4),
    ('sphinx', sand_sphinx, SPHINX_PAL, 4),
    ('sunken_lord', sunken_lord, SUNKEN_PAL, 4),
    ('hermit', tide_hermit, HERMIT_PAL, 4),
    ('shrine', skull_shrine, SHRINE_PAL, 4),
    ('elder', dark_elder, ELDER_PAL, 4),
]


# ================================================================= dungeon and finale bosses
def lich(t):
    c = Canvas(32, 34)
    bob = t
    c.poly([(9, 11 + bob), (23, 11 + bob), (27, 30), (22, 33), (16, 30), (10, 33), (5, 30)], 'R')
    c.shade('R', 'r', 'k')
    c.line(16, 12 + bob, 16, 30, 'Y')
    # ribs showing at the chest
    for k in range(3):
        c.line(13, 14 + k * 2 + bob, 15, 15 + k * 2 + bob, 'B'); c.line(19, 14 + k * 2 + bob, 17, 15 + k * 2 + bob, 'B')
    # skull with a crown of iron spikes
    c.ellipse(16, 7 + bob, 4, 4, 'B')
    c.shade('B', 'W', 'b')
    c.rect(14, 6 + bob, 15, 7 + bob, 'K'); c.rect(17, 6 + bob, 18, 7 + bob, 'K')
    c.put(14, 6 + bob, 'E'); c.put(18, 6 + bob, 'E')
    for x in range(11, 22, 2):
        c.line(x, 4 + bob, x + (x - 16) * 0.2, 0 + bob, 'I')
    # skeletal hands raised, a phylactery orb between them
    c.line(10, 13 + bob, 5, 17 + bob, 'B', 1); c.line(22, 13 + bob, 27, 17 + bob, 'B', 1)
    c.ellipse(16, 22 + bob, 2.5, 2.5, 'G')
    c.put(15, 21 + bob, 'W')
    # spellbooks orbiting
    for i in range(3):
        a = i * 2.1 + t * 0.5
        x, y = 16 + math.cos(a) * 13, 17 + math.sin(a) * 9
        c.rect(x - 1.5, y - 1, x + 1.5, y + 1, 'O'); c.put(x, y, 'G')
    return c


LICH_PAL = {'R': 0x8a1a2a, 'r': 0xc0304a, 'k': 0x3a0610, 'Y': 0xe0b040, 'B': 0xe8e0c8, 'W': 0xffffff, 'b': 0x9a9078,
            'K': 0x100808, 'E': 0xff4060, 'I': 0x5a5a66, 'G': 0x60ff90, 'O': 0x5a3a2a}


def naga(t):
    c = Canvas(34, 34)
    # coiled snake tail
    for i in range(40):
        a = i * 0.25 + t * 0.2
        r = 11 - i * 0.18
        c.ellipse(17 + math.cos(a) * r, 26 + math.sin(a) * r * 0.4, 3 - i * 0.04, 2.5 - i * 0.03, 'T')
    c.shade('T', 't', 'd')
    for i in range(0, 40, 5):
        a = i * 0.25 + t * 0.2
        r = 11 - i * 0.18
        c.put(17 + math.cos(a) * r, 26 + math.sin(a) * r * 0.4, 'Y')
    # a woman's torso rising from the coils
    c.ellipse(17, 16, 4, 6, 'S')
    c.shade('S', 's', 'z')
    c.line(13, 13, 8, 18 - t, 'S', 1.5); c.line(21, 13, 26, 18 - t, 'S', 1.5)
    c.line(14, 16, 20, 16, 'Y')
    # face, and hair of living snakes
    c.ellipse(17, 7, 3.2, 3.5, 'S')
    c.put(16, 7, 'E'); c.put(18, 7, 'E')
    for i in range(7):
        a = math.pi + i * math.pi / 6
        ex, ey = 17 + math.cos(a) * 8, 6 + math.sin(a) * 6
        c.line(17 + math.cos(a) * 3, 6 + math.sin(a) * 3, ex, ey + ((i + t) % 2), 'T', 1.5)
        c.put(ex, ey + ((i + t) % 2), 'E')
    # golden circlet
    c.line(14, 4, 20, 4, 'Y')
    return c


NAGA_PAL = {'T': 0x2a9a6a, 't': 0x5ad09a, 'd': 0x0e4a30, 'Y': 0xf0d040, 'S': 0x9ad0a0, 's': 0xd0f0d0, 'z': 0x4a8a5a,
            'E': 0xff3020}


def cellar_sorcerer(t):
    c = Canvas(30, 34)
    # long robe with patched hem
    c.poly([(9, 13), (21, 13), (24, 32), (6, 32)], 'R')
    c.shade('R', 'r', 'k')
    c.rect(10, 26, 12, 28, 'r'); c.rect(18, 22, 20, 24, 'k')
    c.line(9, 20, 21, 20, 'L')  # belt
    for x in (11, 15, 19):
        c.rect(x, 21, x + 1, 23, 'P' if x != 15 else 'G')  # potions
    # bearded face and the tallest hat
    c.ellipse(15, 10, 3, 3, 'S')
    c.put(14, 9, 'E'); c.put(16, 9, 'E')
    c.poly([(12, 11), (18, 11), (16, 20), (15, 21), (14, 20)], 'W')  # beard
    c.poly([(9, 8), (21, 8), (17, 5), (15, -1 + t), (13, 5)], 'R')
    c.shade('R', 'r', 'k')
    for (x, y) in [(14, 4), (16, 6), (13, 6)]:
        c.put(x, y, 'L')
    # a gnarled staff with a candle on top
    c.line(25, 33, 24, 5, 'O', 1)
    c.rect(23, 2, 25, 4, 'W'); c.put(24, 1, 'F'); c.put(24 + (1 if t else -1), 0, 'f')
    c.line(19, 15, 24, 14, 'R', 2)
    # a floating spark
    c.put(5, 10 - t, 'L'); c.put(4, 16 + t, 'G')
    return c


SORC_PAL = {'R': 0x2a4a9a, 'r': 0x5a7ad0, 'k': 0x14204a, 'L': 0xffe060, 'P': 0xd040c0, 'G': 0x40e060, 'S': 0xf0c8a0,
            'E': 0x101010, 'W': 0xe8e8f0, 'O': 0x6a4a2a, 'F': 0xffb040, 'f': 0xfff0a0}


def tempest_seraph(t):
    c = Canvas(38, 34)
    up = -2 if t else 0
    # six wings, three to a side
    for side in (-1, 1):
        for k in range(3):
            ex, ey = 19 + side * (16 - k * 2), 4 + k * 8 + up * (1 if k == 0 else 0.5)
            c.poly([(19 + side * 3, 12 + k * 3), (ex, ey), (19 + side * (11 - k * 2), 16 + k * 4)], 'W')
            c.line(19 + side * 3, 12 + k * 3, ex, ey, 'w')
    # robe and body
    c.poly([(15, 12), (23, 12), (25, 30), (13, 30)], 'G')
    c.shade('G', 'g', 'k')
    # face, halo of lightning
    c.ellipse(19, 8, 3, 3.3, 'S')
    c.put(18, 8, 'E'); c.put(20, 8, 'E')
    c.ring(19, 3, 5, 1.5, 'Y', 1)
    # lightning crackling from raised hands
    c.line(15, 14, 11, 9, 'S', 1); c.line(23, 14, 27, 9, 'S', 1)
    for side in (-1, 1):
        x, y = 19 + side * 8, 8
        for k in range(4):
            nx, ny = x + side * (1 + (k + t) % 2), y - 2
            c.line(x, y, nx, ny, 'L')
            x, y = nx, ny
    return c


SERAPH_PAL = {'W': 0xf8f4d0, 'w': 0xc8c090, 'G': 0xf0e040, 'g': 0xfff8a0, 'k': 0x8a7a10, 'S': 0xf5dcb0, 'E': 0x2040a0,
              'Y': 0xffff80, 'L': 0xc0e8ff}


def crypt_warden(t):
    c = Canvas(30, 34)
    # tall armoured guardian
    c.poly([(10, 11), (20, 11), (21, 24), (9, 24)], 'A')
    c.ellipse(9, 12, 3, 2.5, 'A'); c.ellipse(21, 12, 3, 2.5, 'A')
    c.rect(10, 24, 13, 32, 'A'); c.rect(17, 24, 20, 32, 'A')
    c.ellipse(15, 6, 4.5, 5, 'A')
    c.shade('A', 'a', 'd')
    # a visor like a tomb door, cold light inside
    c.rect(13, 5, 17, 8, 'K')
    c.line(15, 5, 15, 8, 'd')
    c.put(14, 6, 'G'); c.put(16, 6, 'G')
    # a tower shield carved with a skull
    c.rect(1, 12, 8, 28, 'S')
    c.shade('S', 's', 'd')
    c.ellipse(4.5, 18, 2, 2, 'B')
    c.put(4, 18, 'K'); c.put(5, 18, 'K')
    # a lantern of spirit-light held out
    c.line(21, 14, 26, 18, 'A', 2)
    c.line(26, 18, 26, 21, 'd')
    c.rect(25, 21, 27, 24, 'd')
    c.put(26, 22, 'G' if t else 'g'); c.put(26, 23, 'g')
    # chains and frost mist
    c.line(10, 19, 20, 21, 'a')
    for i in range(4):
        c.put(8 + i * 5 + t, 33, 'g')
    return c


WARDEN_PAL = {'A': 0x4a5a6a, 'a': 0x7a8a9a, 'd': 0x1e2630, 'K': 0x080c10, 'G': 0x6ad0ff, 'g': 0xb0f0ff, 'S': 0x6a6a72,
              's': 0x9a9aa4, 'B': 0xe8e0c8}


def furnace_warden(t):
    c = Canvas(34, 34)
    # a brick furnace golem, its chest a burning grate
    c.poly([(8, 9), (26, 9), (27, 26), (7, 26)], 'B')
    c.rect(9, 26, 14, 32, 'B'); c.rect(20, 26, 25, 32, 'B')
    c.ellipse(17, 6, 5, 4, 'B')
    c.shade('B', 'b', 'd')
    for y in range(11, 26, 3):
        for x in range(9 + (y % 2) * 2, 26, 4):
            c.put(x, y, 'd')
    # the grate with fire behind it
    c.rect(12, 13, 22, 21, 'F')
    c.ellipse(17, 17, 3, 2.5, 'Y')
    for x in range(12, 23, 2):
        c.line(x, 13, x, 21, 'K')
    # chimney horns smoking
    c.rect(11, 1, 12, 4, 'B'); c.rect(22, 1, 23, 4, 'B')
    c.put(11 + t, 0, 'S'); c.put(23 - t, 0, 'S')
    c.rect(15, 5, 19, 6, 'F')
    # arms swinging burning flails
    c.line(8, 11, 3, 19, 'B', 3); c.line(26, 11, 31, 19, 'B', 3)
    c.line(3, 19, 2 + t * 2, 26, 'C', 1); c.line(31, 19, 32 - t * 2, 26, 'C', 1)
    c.ellipse(2 + t * 2, 27, 2, 2, 'F'); c.ellipse(32 - t * 2, 27, 2, 2, 'F')
    c.put(2 + t * 2, 27, 'Y'); c.put(32 - t * 2, 27, 'Y')
    return c


FURNACE_PAL = {'B': 0x8a3a2a, 'b': 0xb85a40, 'd': 0x3a140e, 'F': 0xff6020, 'Y': 0xffe060, 'K': 0x1a0a08, 'S': 0x9a9a9a,
               'C': 0x5a5a62}


def living_flame(t):
    c = Canvas(34, 36)
    # a towering flame with a demon's face, tongues of fire rising
    c.ellipse(17, 22, 11, 11, 'R')
    c.ellipse(17, 17, 9, 10, 'F')
    for i in range(7):
        x = 6 + i * 3.6
        h = 10 + ((i * 5 + t * 3) % 7)
        c.poly([(x - 2.5, 18), (x + (1 if (i + t) % 2 else -1), 18 - h), (x + 2.5, 18)], 'F' if i % 2 else 'R')
    c.ellipse(17, 20, 6, 6, 'Y')
    c.ellipse(17, 22, 3, 3, 'W')
    # the face: slanted eyes and a grin of black
    c.poly([(11, 15), (15, 16), (15, 17), (11, 17)], 'K'); c.poly([(23, 15), (19, 16), (19, 17), (23, 17)], 'K')
    c.put(13, 16, 'W'); c.put(21, 16, 'W')
    c.poly([(12, 22), (22, 22), (20, 26), (14, 26)], 'K')
    for x in range(13, 22, 2):
        c.put(x, 22, 'W')
    # embers spiralling
    for i in range(6):
        a = i * 1.05 + t * 0.5
        c.put(17 + math.cos(a) * 15, 20 + math.sin(a) * 13, 'Y')
    return c


FLAME_PAL = {'R': 0xc02008, 'F': 0xff6a10, 'Y': 0xffd040, 'W': 0xfff8d0, 'K': 0x200400}


def saltbeard(t):
    c = Canvas(32, 34)
    # long coat
    c.poly([(9, 12), (23, 12), (25, 28), (7, 28)], 'C')
    c.shade('C', 'c', 'k')
    c.line(16, 13, 16, 27, 'Y')
    c.line(9, 19, 23, 19, 'L')
    c.put(16, 19, 'Y')
    # legs: one boot, one peg
    c.rect(11, 28, 14, 32, 'L'); c.rect(10, 31, 14, 32, 'L')
    c.rect(19, 28, 20, 32, 'O')
    # face, eyepatch, great beard
    c.ellipse(16, 9, 3.5, 3.5, 'S')
    c.put(15, 8, 'K'); c.line(13, 7, 19, 9, 'K'); c.put(18, 8, 'E')
    c.poly([(12, 10), (20, 10), (18, 16), (16, 17), (14, 16)], 'B')
    c.shade('B', 'b', 'k')
    # tricorn hat with a skull
    c.poly([(8, 6), (24, 6), (21, 2), (16, 1), (11, 2)], 'K')
    c.line(9, 6, 23, 6, 'Y')
    c.ellipse(16, 4, 1.3, 1, 'W')
    # cutlass raised, hook hand
    c.line(23, 14, 27, 11, 'C', 2)
    c.line(27, 11, 31, 2 + t, 'W', 1)
    c.line(26, 12, 28, 12, 'Y')
    c.line(9, 14, 5, 18, 'C', 2)
    c.ring(4, 19, 1.3, 1.3, 'W', 0.8)
    # a parrot on his shoulder
    c.ellipse(10, 9 - t, 1.6, 2, 'P'); c.put(9, 8 - t, 'Y'); c.put(10, 11 - t, 'G')
    return c


PIRATE_PAL = {'C': 0x2a2a6a, 'c': 0x4a4aa0, 'k': 0x10102a, 'Y': 0xf0c030, 'L': 0x3a2410, 'O': 0x8a5a2a, 'S': 0xe0b890,
              'K': 0x101014, 'E': 0x40a0ff, 'B': 0xe8e8f0, 'b': 0xa0a0b0, 'W': 0xe0e0e8, 'P': 0xff3030, 'G': 0x30c040}


def mothwing(t):
    c = Canvas(40, 32)
    up = -2 if t else 0
    # four broad patterned wings
    for side in (-1, 1):
        c.poly([(20, 12), (20 + side * 18, 3 + up), (20 + side * 19, 14 + up), (20 + side * 3, 16)], 'W')
        c.poly([(20, 16), (20 + side * 15, 18), (20 + side * 13, 28), (20 + side * 3, 20)], 'W')
        # eye spots
        c.ellipse(20 + side * 12, 10 + up * 0.6, 3, 2.5, 'O')
        c.ellipse(20 + side * 12, 10 + up * 0.6, 1.5, 1.2, 'K')
        c.ellipse(20 + side * 9, 22, 2, 1.8, 'O')
    c.shade('W', 'w', 'd')
    for side in (-1, 1):
        for k in range(3):
            c.line(20 + side * 3, 13, 20 + side * (8 + k * 4), 4 + k * 4 + up, 'd')
    # fuzzy body, feathered antennae, big dark eyes
    c.ellipse(20, 15, 2.5, 8, 'F')
    c.shade('F', 'f', 'd')
    c.ellipse(20, 7, 3, 2.5, 'F')
    c.put(18, 7, 'K'); c.put(22, 7, 'K')
    c.line(19, 5, 15, 0, 'f', 1); c.line(21, 5, 25, 0, 'f', 1)
    # glowing dust falling
    for i in range(5):
        c.put(10 + i * 5, 29 + (i + t) % 3, 'G')
    return c


MOTH_PAL = {'W': 0xd8c890, 'w': 0xf8f0c0, 'd': 0x6a5a30, 'O': 0x5a8ab0, 'K': 0x101018, 'F': 0xb0a070, 'f': 0xe8e0b0,
            'G': 0xf0ffa0}


def broodmother(t):
    c = Canvas(38, 34)
    # eight legs, jointed
    for side in (-1, 1):
        for k in range(4):
            x0, y0 = 19 + side * 3, 14 + k * 2
            kx, ky = 19 + side * (9 + k), 6 + k * 5 + (t if k % 2 else -t)
            ex, ey = 19 + side * (15 + k * 0.5), 14 + k * 5 + (t if k % 2 else -t)
            c.line(x0, y0, kx, ky, 'B', 2)
            c.line(kx, ky, ex, ey, 'B', 1)
    # abdomen with an hourglass mark, and the head
    c.ellipse(19, 22, 8, 8, 'B')
    c.ellipse(19, 11, 5, 4, 'B')
    c.shade('B', 'b', 'k')
    c.poly([(17, 18), (21, 18), (19, 22)], 'R'); c.poly([(17, 26), (21, 26), (19, 22)], 'R')
    # a cluster of red eyes and fangs
    for (x, y) in [(17, 10), (21, 10), (18, 9), (20, 9), (16, 11), (22, 11)]:
        c.put(x, y, 'E')
    c.line(17, 14, 17, 16, 'W'); c.line(21, 14, 21, 16, 'W')
    # egg sacs and webbing
    for (x, y) in [(5, 30), (33, 29)]:
        c.ellipse(x, y, 2.5, 2, 'G'); c.put(x, y, 'W')
    c.line(19, 30, 19, 34, 'W')
    return c


BROOD_PAL = {'B': 0x2a1a24, 'b': 0x5a3a4a, 'k': 0x0e060a, 'R': 0xff3030, 'E': 0xff5050, 'W': 0xe8e8e8, 'G': 0xe8e0b0}


def archdemon(t):
    c = Canvas(38, 36)
    up = -2 if t else 0
    # bat wings
    for side in (-1, 1):
        c.poly([(19 + side * 4, 10), (19 + side * 18, 2 + up), (19 + side * 16, 8 + up), (19 + side * 18, 16), (19 + side * 13, 14), (19 + side * 12, 21), (19 + side * 5, 17)], 'W')
        for f in range(3):
            c.line(19 + side * 4, 10, 19 + side * (13 + f * 2), 3 + f * 6 + up, 'w')
    c.shade('W', 'w', 'k')
    # a muscular red body, hooves
    c.ellipse(19, 17, 7, 8, 'R')
    c.rect(14, 24, 17, 32, 'R'); c.rect(21, 24, 24, 32, 'R')
    c.shade('R', 'r', 'd')
    c.rect(13, 32, 17, 34, 'K'); c.rect(21, 32, 25, 34, 'K')
    c.line(13, 23, 25, 23, 'K')
    # goat horns and burning eyes
    c.ellipse(19, 8, 4.5, 4, 'R')
    c.shade('R', 'r', 'd')
    c.line(15, 6, 10, 2, 'H', 2); c.line(10, 2, 9, 5, 'H', 1)
    c.line(23, 6, 28, 2, 'H', 2); c.line(28, 2, 29, 5, 'H', 1)
    c.put(17, 8, 'Y'); c.put(21, 8, 'Y')
    c.line(17, 11, 21, 11, 'K')
    # a burning trident
    c.line(31, 34, 31, 4, 'K', 1)
    for dx in (-2, 0, 2):
        c.line(31 + dx, 5, 31 + dx, 1, 'F')
    c.line(29, 5, 33, 5, 'F')
    c.line(25, 15, 31, 16, 'R', 2)
    # a tail with a spade tip
    c.line(16, 25, 8, 30, 'R', 1); c.poly([(8, 29), (5, 30), (8, 32)], 'R')
    return c


DEMON_PAL = {'W': 0x3a0a0a, 'w': 0x7a1a1a, 'k': 0x140202, 'R': 0xc02818, 'r': 0xf05030, 'd': 0x5a0a06, 'K': 0x1a0a0a,
             'H': 0x2a2a2a, 'Y': 0xffe040, 'F': 0xff8020}


def sprite_queen(t):
    c = Canvas(34, 32)
    up = -2 if t else 0
    # glittering butterfly wings
    for side in (-1, 1):
        c.ellipse(17 + side * 8, 10 + up, 8, 7, 'W')
        c.ellipse(17 + side * 7, 21, 6, 5, 'W')
        c.ellipse(17 + side * 9, 10 + up, 3.5, 3, 'P')
        c.ellipse(17 + side * 7, 21, 2.5, 2, 'B')
    c.shade('W', 'w', 'v')
    # a tiny glowing figure in a petal dress
    c.poly([(14, 15), (20, 15), (23, 25), (11, 25)], 'P')
    for i in range(4):
        c.poly([(11 + i * 3, 24), (14 + i * 3, 24), (12.5 + i * 3, 28)], 'P')
    c.shade('P', 'p', 'v')
    c.ellipse(17, 11, 2.5, 2.8, 'S')
    c.put(16, 11, 'E'); c.put(18, 11, 'E')
    c.line(14, 9, 20, 9, 'Y')
    for x in (15, 17, 19):
        c.put(x, 8, 'Y')
    # a wand with a star, sparkles everywhere
    c.line(21, 16, 26, 11, 'Y', 1)
    c.put(27, 10, 'W'); c.put(26, 10, 'Y'); c.put(28, 10, 'Y'); c.put(27, 9, 'Y'); c.put(27, 11, 'Y')
    for i in range(8):
        a = i * 0.8 + t * 0.4
        c.put(17 + math.cos(a) * 15, 16 + math.sin(a) * 13, 'Y' if i % 2 else 'W')
    return c


SPRITEQ_PAL = {'W': 0xffb0e8, 'w': 0xfff0ff, 'v': 0xa04090, 'P': 0xff60c0, 'p': 0xffa0e0, 'B': 0x80e0ff, 'S': 0xfff0e0,
               'E': 0x6a2060, 'Y': 0xffff90}


def sun_king(t):
    c = Canvas(34, 34)
    # a blazing sun disc behind him
    c.ellipse(17, 10, 10, 10, 'O')
    for i in range(16):
        a = i * math.pi / 8 + t * math.pi / 16
        c.line(17 + math.cos(a) * 10, 10 + math.sin(a) * 10, 17 + math.cos(a) * 15, 10 + math.sin(a) * 15, 'Y' if i % 2 else 'O', 1)
    c.ellipse(17, 10, 8, 8, 'Y')
    # golden armour and white robes
    c.poly([(11, 13), (23, 13), (26, 32), (8, 32)], 'W')
    c.shade('W', 'W', 'w')
    c.poly([(11, 13), (23, 13), (22, 22), (12, 22)], 'G')
    c.shade('G', 'g', 'k')
    c.ellipse(17, 17, 2, 2, 'R')
    # face and crown of rays
    c.ellipse(17, 9, 3.2, 3.5, 'S')
    c.put(16, 9, 'E'); c.put(18, 9, 'E')
    for i in range(5):
        c.line(14 + i * 1.5, 5, 13 + i * 2, 1, 'G')
    # a sceptre topped with a sun
    c.line(27, 32, 27, 8, 'G', 1)
    c.ellipse(27, 6, 2, 2, 'O'); c.put(27, 6, 'W')
    c.line(22, 16, 27, 17, 'W', 2)
    return c


SUNK_PAL = {'O': 0xffa020, 'Y': 0xffe060, 'W': 0xfffaf0, 'w': 0xd8d0b8, 'G': 0xf0c030, 'g': 0xfff0a0, 'k': 0x8a6010,
            'R': 0xff4020, 'S': 0xe8b880, 'E': 0x3a2010}


def moon_queen(t):
    c = Canvas(32, 34)
    # a crescent moon behind her
    c.ellipse(16, 10, 10, 10, 'M')
    c.ellipse(20, 8, 9, 9, '.')
    # a starry gown, wide at the hem
    c.poly([(12, 12), (20, 12), (27, 32), (5, 32)], 'G')
    c.shade('G', 'g', 'k')
    for (x, y) in [(10, 26), (14, 22), (19, 27), (22, 23), (16, 30), (8, 30), (24, 30)]:
        c.put(x, y, 'S' if (x + y + t) % 2 else 'W')
    # pale face, silver hair streaming down
    c.ellipse(16, 8, 3, 3.5, 'Q')
    c.put(15, 8, 'E'); c.put(17, 8, 'E')
    for i in range(6):
        c.line(13 + i * 1.2, 6, 11 + i * 2, 18 + (i % 2) * 3, 'H')
    c.ellipse(16, 8, 3, 3.5, 'Q', only=('H',))
    # a crescent tiara
    c.ring(16, 4, 3, 1.5, 'S', 0.8)
    # an orb of moonlight in her palm
    c.line(20, 14, 25, 16, 'Q', 1)
    c.ellipse(26, 15, 2, 2, 'W'); c.put(26 + t, 15, 'S')
    return c


MOON_PAL = {'M': 0xc8d0ff, 'G': 0x3a4a9a, 'g': 0x6a7ad0, 'k': 0x141a4a, 'S': 0xe0e8ff, 'W': 0xffffff, 'Q': 0xf4dcd0,
            'E': 0x3a4aa0, 'H': 0x8a98d0}


def frost_giant(t):
    c = Canvas(34, 34)
    # an ice golem in crystal armour
    c.poly([(9, 10), (25, 10), (26, 25), (8, 25)], 'I')
    c.ellipse(8, 11, 4, 3, 'I'); c.ellipse(26, 11, 4, 3, 'I')
    c.rect(10, 25, 14, 32, 'I'); c.rect(20, 25, 24, 32, 'I')
    c.ellipse(17, 6, 5, 4.5, 'I')
    c.shade('I', 'i', 'd')
    # crystal spikes growing from the shoulders and back
    for (x, y, h) in [(5, 9, 6), (8, 8, 8), (26, 8, 8), (29, 9, 6), (14, 3, 4), (20, 3, 4)]:
        c.poly([(x - 1, y), (x, y - h), (x + 1, y)], 'C')
    # a blue core and icy eyes
    c.ellipse(17, 17, 3, 3, 'B'); c.ellipse(17, 17, 1.5, 1.5, 'W')
    c.put(15, 6, 'W'); c.put(19, 6, 'W')
    # a great frost axe
    c.line(28, 33, 28, 6, 'H', 1)
    c.poly([(28, 6), (33, 3), (33, 13), (28, 11)], 'C')
    c.line(24, 14, 28, 16, 'I', 2)
    # snow drifting
    for i in range(5):
        c.put(3 + i * 7 + t, 2 + (i * 4 + t) % 9, 'W')
    return c


FROSTG_PAL = {'I': 0x80b8e0, 'i': 0xd0f0ff, 'd': 0x2a5a8a, 'C': 0xe0f8ff, 'B': 0x40a0ff, 'W': 0xffffff, 'H': 0x6a5a4a}


def shattered_seraph(t):
    c = Canvas(36, 34)
    up = -1 if t else 0
    # broken wings: shards of crystal held in the shape of wings, with gaps
    for side in (-1, 1):
        for k in range(6):
            x = 18 + side * (5 + k * 2.4)
            y = 8 + k * 1.2 + up * (k % 2)
            c.poly([(x, y - 3), (x + side * 1.5, y + 1), (x, y + 6 - k * 0.5), (x - side * 1, y + 1)], 'C' if k % 2 else 'c')
    # a cracked, kneeling figure in white
    c.poly([(14, 12), (22, 12), (25, 30), (11, 30)], 'W')
    c.shade('W', 'W', 'w')
    for (x0, y0, x1, y1) in [(15, 14, 18, 20), (21, 16, 19, 24), (13, 24, 16, 28)]:
        c.line(x0, y0, x1, y1, 'P')
    c.ellipse(18, 8, 3, 3.3, 'Q')
    c.line(17, 6, 19, 10, 'P')
    c.put(17, 8, 'E'); c.put(19, 8, 'E')
    # a broken halo, half of it floating away
    c.ring(18, 3, 4, 1.4, 'Y', 1)
    for x in range(18, 23):
        c.put(x + 2, 2 - t, '.')
    c.line(22, 1 - t, 24, 0 - t, 'Y')
    # tears of light
    c.put(17, 10 + t, 'P'); c.put(19, 11 - t, 'P')
    return c


SHATTER_PAL = {'C': 0xff80d0, 'c': 0xffc0f0, 'W': 0xf8f0ff, 'w': 0xc0b0d8, 'P': 0xff60c0, 'Q': 0xffe8f0, 'E': 0x8a2070,
               'Y': 0xffe080}


def blood_knight(t):
    c = Canvas(32, 34)
    # tattered crimson cape
    c.poly([(8, 11), (24, 11), (27, 31), (23, 29), (19, 33), (14, 29), (9, 33), (5, 30)], 'C')
    c.shade('C', 'c', 'k')
    # dark plate armour
    c.poly([(10, 11), (22, 11), (21, 23), (11, 23)], 'A')
    c.ellipse(9, 12, 3.5, 3, 'A'); c.ellipse(23, 12, 3.5, 3, 'A')
    c.rect(11, 23, 14, 31, 'A'); c.rect(18, 23, 21, 31, 'A')
    # a horned great helm
    c.ellipse(16, 6, 4.5, 5, 'A')
    c.poly([(12, 4), (8, -1), (13, 2)], 'A'); c.poly([(20, 4), (24, -1), (19, 2)], 'A')
    c.shade('A', 'a', 'd')
    c.rect(13, 6, 19, 6, 'R'); c.put(14, 6, 'E'); c.put(18, 6, 'E')
    # blood runes on the plate
    c.line(16, 13, 16, 20, 'R'); c.line(13, 16, 19, 16, 'R')
    # a vast greatsword planted before him, both hands on the hilt
    c.line(16, 33, 16, 18, 'S', 3)
    c.line(16, 33, 16, 18, 's', 1)
    c.line(12, 18, 20, 18, 'Y', 1)
    c.ellipse(16, 16, 1.5, 1.5, 'R')
    c.line(11, 14, 15, 17, 'A', 2); c.line(21, 14, 17, 17, 'A', 2)
    # dripping blood
    c.put(15, 24 + t, 'R'); c.put(17, 28 - t, 'R')
    return c


BLOODK_PAL = {'C': 0x8a0a14, 'c': 0xc02030, 'k': 0x3a0208, 'A': 0x2a2a34, 'a': 0x5a5a6a, 'd': 0x101016, 'R': 0xff2030,
              'E': 0xff6060, 'S': 0xb0b0c0, 's': 0xffffff, 'Y': 0xc0a040}


def hex_queen(t):
    c = Canvas(32, 34)
    # an elegant gown of black and venom green
    c.poly([(12, 12), (20, 12), (26, 32), (6, 32)], 'D')
    c.shade('D', 'd', 'k')
    c.poly([(14, 13), (18, 13), (21, 32), (11, 32)], 'G')
    c.shade('G', 'g', 'k')
    # a crown of antlers
    c.ellipse(16, 8, 3, 3.5, 'S')
    c.put(15, 8, 'E'); c.put(17, 8, 'E')
    for side in (-1, 1):
        c.line(16 + side * 2, 5, 16 + side * 7, 0, 'A', 1)
        c.line(16 + side * 4, 3, 16 + side * 4, 0, 'A', 1)
        c.line(16 + side * 6, 1, 16 + side * 8, 2, 'A', 1)
    # hex runes circling her, cursed orbs
    for i in range(6):
        a = i * math.pi / 3 + t * math.pi / 6
        x, y = 16 + math.cos(a) * 13, 18 + math.sin(a) * 10
        c.ring(x, y, 1.4, 1.4, 'G', 0.8)
        c.put(x, y, 'g')
    # a twisted staff with a green eye
    c.line(25, 33, 24, 7, 'A', 1)
    c.ellipse(24, 6, 2, 2, 'G'); c.put(24, 6, 'K')
    c.line(19, 14, 24, 13, 'D', 2)
    return c


HEXQ_PAL = {'D': 0x2a1a34, 'd': 0x4a3a5a, 'k': 0x0e0614, 'G': 0x50d040, 'g': 0xb0ff90, 'S': 0xd8e8c8, 'E': 0x40ff40,
            'A': 0x4a3a2a, 'K': 0x101010}


def star_prince(t):
    c = Canvas(32, 34)
    # a cape full of stars, billowing
    c.poly([(9, 11), (23, 11), (28 + t, 32), (4 - t, 32)], 'C')
    c.shade('C', 'c', 'k')
    for (x, y) in [(8, 28), (12, 22), (20, 26), (24, 30), (16, 30), (6, 20), (26, 20)]:
        c.put(x, y, 'W' if (x + t) % 2 else 'Y')
    # a fitted violet tunic, a sash
    c.poly([(12, 11), (20, 11), (20, 22), (12, 22)], 'T')
    c.shade('T', 't', 'k')
    c.line(12, 12, 20, 21, 'Y')
    c.rect(12, 22, 14, 31, 'T'); c.rect(18, 22, 20, 31, 'T')
    c.rect(11, 30, 14, 31, 'k'); c.rect(18, 30, 21, 31, 'k')
    # a young face, a circlet with a star
    c.ellipse(16, 7, 3.2, 3.5, 'S')
    c.put(15, 7, 'E'); c.put(17, 7, 'E')
    c.poly([(12, 5), (20, 5), (19, 2), (13, 2)], 'H')
    c.line(13, 4, 19, 4, 'Y')
    c.put(16, 3, 'W')
    # a slender rapier of light
    c.line(21, 15, 30, 6 - t, 'W', 1)
    c.line(20, 14, 22, 16, 'Y')
    return c


STARP_PAL = {'C': 0x2a1a5a, 'c': 0x5a3aa0, 'k': 0x0e0628, 'W': 0xffffff, 'Y': 0xffe060, 'T': 0x8a40d0, 't': 0xc070ff,
             'S': 0xf5dcb0, 'E': 0x3a1a6a, 'H': 0xe8c870}


DESIGNS += [
    ('lich_king', lich, LICH_PAL, 4),
    ('serpent_queen', naga, NAGA_PAL, 4),
    ('sorcerer', cellar_sorcerer, SORC_PAL, 4),
    ('seraph', tempest_seraph, SERAPH_PAL, 4),
    ('warden', crypt_warden, WARDEN_PAL, 4),
    ('flame_warden', furnace_warden, FURNACE_PAL, 4),
    ('pyrelord', living_flame, FLAME_PAL, 4),
    ('pirate_king', saltbeard, PIRATE_PAL, 4),
    ('moth', mothwing, MOTH_PAL, 4),
    ('broodmother', broodmother, BROOD_PAL, 4),
    ('archdemon', archdemon, DEMON_PAL, 4),
    ('sprite_queen', sprite_queen, SPRITEQ_PAL, 4),
    ('sun_king', sun_king, SUNK_PAL, 4),
    ('moon_queen', moon_queen, MOON_PAL, 4),
    ('frost_warden', frost_giant, FROSTG_PAL, 4),
    ('shattered_seraph', shattered_seraph, SHATTER_PAL, 4),
    ('blood_knight', blood_knight, BLOODK_PAL, 4),
    ('hex_queen', hex_queen, HEXQ_PAL, 4),
    ('star_prince', star_prince, STARP_PAL, 4),
]
