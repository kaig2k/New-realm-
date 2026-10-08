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
