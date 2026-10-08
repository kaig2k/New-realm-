"""
Eldmere monster sprites, batch C: eyes, slimes, spiders, snakes, ghosts,
sprites, demons and the Thunder Golem. Each design(t) draws idle frame t
(0 or 1) and returns a Canvas; MONSTERS lists (name, function, palette, scale).
Normal monsters are 16x16, big ones up to 20x20, all drawn at scale 3.
They face right; the game adds the black outline itself.
"""
import math
from canvas import Canvas


# ----------------------------------------------------------------- Beholder (20x20)
def beholder(t):
    c = Canvas(20, 20)
    b = t
    # eye-stalks, waving
    tips = [(4, 3), (8, 1), (13, 1), (17, 3)]
    for i, (x, y) in enumerate(tips):
        sway = 1 if (i + t) % 2 else 0
        c.line(10 + (x - 10) * 0.35, 6 + b, x + sway, y + 1 + b, 'S')
    c.ellipse(10, 11 + b, 7.6, 6.9, 'R')
    c.shade('R', 'r', 'k')
    for i, (x, y) in enumerate(tips):
        sway = 1 if (i + t) % 2 else 0
        c.rect(x + sway - 1, y + b, x + sway, y + b + 1, 'W')
        c.put(x + sway, y + b + 1, 'K')
    # the great central eye
    c.ellipse(11.5, 9 + b, 3.8, 3.1, 'W')
    c.ellipse(12.5, 9 + b, 2, 2.1, 'Y')
    c.ellipse(12.8, 9 + b, 1, 1.1, 'y')
    c.rect(13, 8 + b, 13, 10 + b, 'K')
    c.put(11, 8 + b, 'w')
    # lid shadow
    c.line(8, 6 + b, 15, 6 + b, 'k')
    # toothy maw
    c.ellipse(11, 15 + b, 4.6, 1.6, 'K')
    for x in range(7, 16, 2):
        c.put(x, 14 + b, 'T')
    for x in range(8, 15, 2):
        c.put(x, 16 + b, 'T')
    return c


BEHOLDER_PAL = {'R': 0xb02020, 'r': 0xe04a3a, 'k': 0x5a0a10, 'S': 0x8a1a1a, 'W': 0xf8f0e0, 'w': 0xffffff,
                'K': 0x1a0408, 'Y': 0x60e040, 'y': 0xc0ff80, 'T': 0xf0e8c8}


# ----------------------------------------------------------------- Gazer (16x16)
def gazer(t):
    c = Canvas(16, 16)
    b = t
    up = -2 if t else 0
    # bat wings, scalloped
    left = [(6, 6 + b), (2, 2 + up + b), (0, 4 + up + b), (0, 8 + b), (1, 7 + b), (2, 9 + b), (3, 8 + b), (4, 10 + b), (6, 9 + b)]
    c.poly(left, 'M')
    c.poly([(15 - x, y) for x, y in left], 'M')
    c.shade('M', 'm', 'n')
    c.line(5, 6 + b, 2, 2 + up + b, 'n'); c.line(10, 6 + b, 13, 2 + up + b, 'n')
    # round body, a little horn
    c.ellipse(7.5, 7 + b, 3.7, 3.7, 'P')
    c.put(9, 2 + b, 'P'); c.put(10, 3 + b, 'P')
    c.shade('P', 'p', 'q')
    # one big eye, cat pupil
    c.ellipse(8.3, 7 + b, 2.4, 2.3, 'W')
    c.ellipse(8.8, 7 + b, 1.3, 1.5, 'Y')
    c.line(9, 6 + b, 9, 8 + b, 'K')
    # dangling tail
    c.line(7, 10 + b, 6, 13 + b, 'q')
    c.put(5, 14 + b, 'p')
    return c


GAZER_PAL = {'P': 0x9040a0, 'p': 0xc070d0, 'q': 0x4a1a5a, 'M': 0x6a2a7a, 'm': 0x9a5aaa, 'n': 0x3a103e,
             'W': 0xfff8f0, 'Y': 0xffc020, 'K': 0x14040e}


# ----------------------------------------------------------------- Big Green Slime (16x16)
def green_slime(t):
    c = Canvas(16, 16)
    s = t  # squash
    c.ellipse(7.5, 10 + s * 0.5, 7 + s * 0.4, 5.6 - s * 0.6, 'G')
    c.rect(1, 13, 14, 15, 'G')
    c.shade('G', 'g', 'd')
    c.line(1, 15, 14, 15, 'd')
    # swallowed bone, tilted
    c.line(3, 13, 7, 11, 'B')
    c.put(2, 13, 'B'); c.put(3, 14, 'B'); c.put(7, 10, 'B'); c.put(8, 11, 'B')
    # bubbles rising
    for (x, y) in [(5, 8), (11, 12), (9, 13), (4, 10)]:
        c.put(x, y - t, 'b')
    c.put(6, 6 + s, 'b')
    # glossy highlight
    c.put(4, 6 + s, 'h'); c.put(3, 7 + s, 'h')
    # eyes
    c.rect(9, 8 + s, 9, 9 + s, 'K'); c.rect(12, 8 + s, 12, 9 + s, 'K')
    c.put(9, 8 + s, 'h'); c.put(12, 8 + s, 'h')
    return c


GREEN_SLIME_PAL = {'G': 0x40b030, 'g': 0x80e060, 'd': 0x1e6a18, 'B': 0xf0ead0, 'b': 0xb0f0a0, 'h': 0xffffff,
                   'K': 0x0e2a0a}


# ----------------------------------------------------------------- Sea Slime (16x16, small)
def slime(t):
    c = Canvas(16, 16)
    s = t
    c.ellipse(8, 12 + s * 0.4, 5 + s * 0.4, 3.6 - s * 0.4, 'T')
    c.rect(3, 14, 13, 15, 'T')
    c.shade('T', 't', 'd')
    # seaweed sprig
    sw = 1 if t else 0
    c.line(6, 9 + s, 5 + sw, 6, 'S')
    c.line(5 + sw, 6, 6 + sw, 4, 'S')
    c.put(4 + sw, 7, 's'); c.put(7 + sw, 5, 's')
    # a little scallop shell
    c.rect(9, 8 + s, 11, 8 + s, 'C')
    c.rect(9, 7 + s, 11, 7 + s, 'C')
    c.put(10, 6 + s, 'C')
    c.put(10, 7 + s, 'c'); c.put(10, 8 + s, 'c')
    # eyes
    c.put(8, 11, 'K'); c.put(11, 11, 'K')
    c.put(5, 10 + s, 'h')
    return c


SEA_SLIME_PAL = {'T': 0x48b88a, 't': 0x8ae8b8, 'd': 0x1e6a50, 'S': 0x2a7a2a, 's': 0x5ac040, 'C': 0xffa090,
                 'c': 0xd0605a, 'K': 0x0a2a20, 'h': 0xe8fff4}


# ----------------------------------------------------------------- Slime God (20x20)
def slime_god(t):
    c = Canvas(20, 20)
    c.ellipse(10, 10, 7, 6.5, 'P')
    c.poly([(3, 10), (17, 10), (19, 19), (1, 19)], 'P')
    # drips down the flanks
    c.line(2, 14, 1, 17, 'P'); c.line(18, 13, 19, 16 + t, 'P')
    c.shade('P', 'p', 'q')
    c.line(1, 19, 19, 19, 'q')
    # dripping crown
    c.rect(6, 3, 14, 4, 'Y')
    for x in (6, 10, 14):
        c.line(x, 3, x, 1, 'Y')
    c.put(8, 2, 'Y'); c.put(12, 2, 'Y')
    c.line(6, 4, 14, 4, 'y')
    c.put(10, 3, 'R'); c.put(7, 3, 'B'); c.put(13, 3, 'B')
    c.put(6, 1, 'G'); c.put(10, 1, 'G'); c.put(14, 1, 'G')
    for (x, l) in [(8, 1), (12, 2), (9, 1)]:
        c.line(x, 4, x, 4 + l + t, 'p')
    # many eyes
    for (x, y, big) in [(8, 8, 1), (13, 8, 1), (5, 12, 0), (16, 12, 0), (11, 11, 0), (7, 16, 0), (14, 16, 0)]:
        if big:
            c.rect(x - 1, y - 1, x, y, 'W')
            c.put(x, y, 'K')
            if t:
                c.line(x - 1, y - 1, x, y - 1, 'q')
        else:
            c.put(x, y, 'W'); c.put(x, y + 1, 'K')
    # grin
    c.line(7, 14, 14, 14, 'K')
    c.put(6, 13, 'K'); c.put(15, 13, 'K')
    c.put(5, 7, 'h'); c.put(4, 8, 'h')
    return c


SLIME_GOD_PAL = {'P': 0x8040c0, 'p': 0xb070f0, 'q': 0x401870, 'Y': 0xf0c030, 'y': 0xa07010, 'R': 0xff3050,
                 'B': 0x40d0ff, 'G': 0xfff0a0, 'W': 0xfff0ff, 'K': 0x1a0a2a, 'h': 0xe8d0ff}


# ----------------------------------------------------------------- Forest Spider (16x16, top-ish view)
def spider(t):
    c = Canvas(16, 16)
    cy = 8.5
    # (attach, knee, foot) for the upper legs; the lower ones mirror them
    legs = [((11, 8), (13, 5), (15, 7)), ((10, 7), (11, 4), (13, 2)),
            ((9, 7), (7, 4), (6, 2)), ((8, 8), (4, 5), (2, 7))]
    for i, (a, k, f) in enumerate(legs):
        for up in (True, False):
            o = (1 if (i % 2) == (t if up else 1 - t) else 0)
            fy = lambda y: y if up else 17 - y
            kx = k[0] + (o if i < 2 else -o)
            c.line(a[0], fy(a[1]), kx, fy(k[1]), 'L')
            c.line(kx, fy(k[1]), f[0], fy(f[1]), 'L')
    c.ellipse(5, cy, 3.6, 3, 'S')
    c.ellipse(10.5, cy, 2.2, 2, 'S')
    c.shade('S', 's', 'd')
    # green markings on the abdomen
    c.line(3, 8, 6, 8, 'G'); c.line(3, 9, 6, 9, 'G')
    c.put(4, 7, 'G'); c.put(4, 10, 'G')
    # eyes and fangs
    c.put(12, 8, 'E'); c.put(12, 9, 'E'); c.put(11, 8, 'e')
    c.put(13, 8, 'F'); c.put(13, 9, 'F')
    return c


SPIDER_PAL = {'S': 0x3a2a3a, 's': 0x6a506a, 'd': 0x1e141e, 'L': 0x5a465a, 'G': 0x60d040, 'E': 0xb0ff60,
              'e': 0x60d040, 'F': 0xe0d8c0}


# ----------------------------------------------------------------- Spider Queen (20x20)
def spider_queen(t):
    c = Canvas(20, 20)
    o = t
    # legs arching high over the body, tipped with gold
    legs = [((10, 12), (3, 4 + o), (0, 19)), ((11, 12), (7, 3 - o), (5, 19)),
            ((13, 12), (16, 3 + o), (15, 19)), ((14, 12), (19, 5 - o), (19, 19))]
    for (a, k, f) in legs[:2]:
        c.line(a[0], a[1], k[0], k[1], 'N', 1.5); c.line(k[0], k[1], f[0], f[1], 'N')
    # big striped abdomen with a red hourglass
    c.ellipse(6, 12.5, 5.5, 4.6, 'Y')
    c.shade('Y', 'y', 'o')
    for x in (3, 6, 9):
        c.ellipse(x - 0.5, 12.5, 0.6, 4.2, 'N', only='Yyo')
    c.put(5, 10, 'R'); c.put(5, 11, 'R'); c.put(4, 10, 'R'); c.put(6, 10, 'R')
    for (a, k, f) in legs[2:]:
        c.line(a[0], a[1], k[0], k[1], 'N', 1.5); c.line(k[0], k[1], f[0], f[1], 'N')
    for (a, k, f) in legs:
        c.put(k[0], k[1], 'C'); c.put(f[0], f[1], 'C')
    # black head
    c.ellipse(13.5, 11, 3.2, 2.8, 'N')
    c.shade('N', 'n', 'm')
    # crown of spikes
    c.line(11, 8, 16, 8, 'C')
    for (x, h) in [(11, 2), (13.5, 3), (16, 2)]:
        c.line(x, 8, x, 8 - h, 'C')
    c.put(13.5, 7, 'c')
    # many red eyes
    for (x, y) in [(15, 10), (16, 10), (14, 11), (15, 11), (16, 11), (17, 12)]:
        c.put(x, y, 'R')
    c.put(16, 10, 'r')
    # fangs
    c.put(17, 13, 'F'); c.put(16, 14, 'F')
    return c


SPIDER_QUEEN_PAL = {'Y': 0xe0c020, 'y': 0xfff070, 'o': 0x8a6a08, 'N': 0x2a2228, 'n': 0x504650, 'm': 0x100a10,
                    'R': 0xff2020, 'r': 0xffa0a0, 'C': 0xffd040, 'c': 0xff4060, 'F': 0xf0e8d0}


# ----------------------------------------------------------------- Sand Snake (16x16, small)
def snake(t):
    c = Canvas(16, 16)
    c.ellipse(7, 13, 5.5, 2.4, 'T')
    c.ellipse(7.5, 11, 3.6, 1.8, 'T')
    # neck rising to the head
    c.line(9, 11, 11, 7, 'T', 2)
    c.ellipse(12, 6, 2, 1.5, 'T')
    c.shade('T', 't', 'd')
    # coil seams and diamond markings
    c.line(4, 12, 10, 12, 'd')
    for x in (3, 6, 9):
        c.put(x, 14, 'p')
    c.put(6, 10, 'p'); c.put(10, 9, 'p')
    # rattle
    c.put(1, 12, 'R'); c.put(1, 11, 'r'); c.put(0, 10 - t, 'R')
    # eye and forked tongue
    c.put(12, 5, 'K')
    if t:
        c.line(14, 7, 15, 7, 'X'); c.put(15, 8, 'X')
    else:
        c.put(14, 7, 'X')
    return c


SNAKE_PAL = {'T': 0xc8b040, 't': 0xf0e080, 'd': 0x7a6a20, 'p': 0x8a5a20, 'R': 0xe8d8b0, 'r': 0xa09070,
             'K': 0x1a1008, 'X': 0xff3040}


# ----------------------------------------------------------------- Swamp Serpent (16x16, raised cobra)
def great_snake(t):
    c = Canvas(16, 16)
    sx = t
    c.ellipse(7, 14, 6.5, 1.8, 'G')
    c.line(4, 13, 6 + sx, 10, 'G', 3)
    c.line(6 + sx, 10, 8 + sx, 7, 'G', 3)
    c.shade('G', 'g', 'd')
    c.line(2, 15, 12, 15, 'd')
    # belly scales
    c.line(6, 13, 7 + sx, 10, 'B')
    # flared hood with spectacle marks
    c.ellipse(8.5 + sx, 5.5, 3.6, 4, 'H')
    c.shade('H', 'h', 'd')
    c.ellipse(9.5 + sx, 6, 1.4, 2.2, 'B')
    c.put(7 + sx, 4, 'M'); c.put(7 + sx, 5, 'M'); c.put(11 + sx, 4, 'M'); c.put(11 + sx, 5, 'M')
    # head jutting right
    c.ellipse(11.5 + sx, 2.5, 2, 1.3, 'G')
    c.shade('G', 'g', 'd')
    c.put(12 + sx, 2, 'E')
    # tongue
    c.put(14 + sx, 3, 'X'); c.put(15, 3 + t, 'X')
    return c


GREAT_SNAKE_PAL = {'G': 0x3a8a3a, 'g': 0x6ac060, 'd': 0x1a4a1a, 'H': 0x2e7a40, 'h': 0x5aa868, 'M': 0xd8c050,
                   'B': 0xb8c870, 'E': 0xffe020, 'X': 0xff3030}


# ----------------------------------------------------------------- Cloud Serpent (18x18)
def cloud_serpent(t):
    c = Canvas(18, 18)
    w = t
    # a long S-shaped body, thickening from tail tip to neck
    pts = [(1, 3), (1.5, 6 + w * 0.5), (3.5, 10), (6.5, 12 - w), (9.5, 12 - w), (11.5, 10), (12.5, 7), (13.5, 5)]
    for i, (a, b2) in enumerate(zip(pts, pts[1:])):
        c.line(a[0], a[1], b2[0], b2[1], 'B', 1.2 + i * 0.3)
    # dragon head
    c.ellipse(14.5, 4, 2.2, 1.7, 'B')
    c.rect(15, 4, 17, 5, 'B')
    c.shade('B', 'b', 'c')
    c.line(16, 5, 17, 5, 'c')
    # pale fins along the spine, a flowing mane
    for (x, y) in [(2, 9), (5, 10 - w), (9, 10 - w), (13, 8)]:
        c.put(x, y, 'F')
    c.line(13, 3, 11, 3 + w, 'F'); c.put(10, 4 + w, 'F')
    # golden horn and long whiskers
    c.line(14, 2, 13, 1, 'G'); c.put(15, 2, 'G')
    c.line(17, 6, 17, 8 + w, 'G')
    c.line(15, 6, 13, 7 + w, 'G')
    c.put(15, 4, 'E')
    # cloud puffs wreathing the coils
    for (x, y, r) in [(2, 15, 1.6), (4.5, 14.5, 2), (7, 15.5, 1.5), (12.5, 15, 1.6), (15, 14.5 - w * 0.5, 1.9),
                      (6, 9.5, 1.2)]:
        c.ellipse(x, y, r, r * 0.8, 'W')
    c.shade('W', 'W', 'w')
    return c


CLOUD_SERPENT_PAL = {'B': 0xb0dcf8, 'b': 0xe4f6ff, 'c': 0x6a9ad0, 'F': 0x90c8f0, 'G': 0xf0d070, 'E': 0x2050e0,
                     'W': 0xf4f8ff, 'w': 0xa8b4d8}


# ----------------------------------------------------------------- Lost Soul (16x16)
def ghost(t):
    c = Canvas(16, 16)
    b = t
    c.ellipse(8.5, 6 + b, 4.6, 4.6, 'W')
    c.rect(4, 6 + b, 13, 10 + b, 'W')
    # wispy tail sweeping back
    c.poly([(4, 10 + b), (13, 10 + b), (11, 13 + b), (7, 14), (3, 15), (2, 13 + b)], 'W')
    c.put(12, 12 + b, 'W')
    c.shade('W', 'w', 'v')
    # little arm
    c.put(13, 9 + b, 'w'); c.put(14, 10 + b, 'w')
    # sad face
    c.rect(8, 6 + b, 8, 7 + b, 'K'); c.rect(11, 6 + b, 11, 7 + b, 'K')
    c.put(7, 5 + b, 'v'); c.put(12, 5 + b, 'v')
    c.put(9, 10 + b, 'K'); c.put(10, 9 + b, 'K'); c.put(11, 10 + b, 'K')
    c.put(8, 8 + b + t, 'T')
    return c


GHOST_PAL = {'W': 0xc8d8f0, 'w': 0xf0f8ff, 'v': 0x7a88b0, 'K': 0x1a1a30, 'T': 0x60b0ff}


# ----------------------------------------------------------------- Ghost God (20x20)
def ghost_god(t):
    c = Canvas(20, 20)
    b = t
    c.ellipse(10, 8 + b, 6, 5.5, 'W')
    c.poly([(4, 8 + b), (16, 8 + b), (15, 15 + b), (11, 18), (6, 19), (3, 17 + b)], 'W')
    c.shade('W', 'w', 'v')
    # ghostly clawed hands raised at the sides
    for (hx, hy, s) in [(2, 10 - b, -1), (17.5, 9 + b, 1)]:
        c.line(hx - s * 2, hy + 3, hx, hy, 'H', 1.6)
        c.ellipse(hx, hy, 1.3, 1.2, 'H')
        c.line(hx - 1, hy - 1, hx - 1 + s * 0.5, hy - 3, 'H')
        c.line(hx, hy - 1, hx + s * 0.5, hy - 4, 'H')
        c.line(hx + 1, hy - 1, hx + 1 + s, hy - 3, 'H')
        c.shade('H', 'h', 'v')
    # crown
    c.rect(6, 3 + b, 14, 4 + b, 'Y')
    for x in (6, 9, 11, 14):
        c.line(x, 3 + b, x, 1 + b, 'Y')
    c.line(6, 4 + b, 14, 4 + b, 'y')
    c.put(10, 3 + b, 'R'); c.put(7, 3 + b, 'E'); c.put(13, 3 + b, 'E')
    # glowing eyes, wailing mouth
    c.rect(8, 7 + b, 9, 8 + b, 'K'); c.rect(12, 7 + b, 13, 8 + b, 'K')
    c.put(9, 7 + b, 'E'); c.put(13, 7 + b, 'E')
    c.ellipse(11, 11 + b, 1.4, 1.6 + t * 0.5, 'K')
    return c


GHOST_GOD_PAL = {'W': 0xc8d8f0, 'w': 0xf4faff, 'v': 0x6a74a8, 'H': 0xa8b8e8, 'h': 0xe0ecff, 'Y': 0xf0c840,
                 'y': 0xa07a20, 'R': 0xa040ff, 'E': 0x60ffe0, 'K': 0x14102a}


# ----------------------------------------------------------------- Grave Wraith (16x16)
def grave_wraith(t):
    c = Canvas(16, 16)
    # scythe shaft behind
    c.line(13, 15, 12, 3, 'H')
    # hooded, ragged robe
    c.poly([(7, 2), (11, 4), (12, 9), (13, 15), (2, 15), (4, 8), (4, 5)], 'B')
    c.shade('B', 'b', 'd')
    for x in range(2, 14, 2):
        c.put(x + t, 15, '.')
    # dark hood opening and glowing eyes
    c.ellipse(8.5, 6.5, 2, 2.2, 'K')
    c.put(8, 6, 'E'); c.put(10, 6, 'E')
    if t:
        c.put(8, 6, 'e'); c.put(10, 6, 'e')
    # bony hand on the shaft
    c.put(12, 9, 'W'); c.put(11, 9, 'b')
    # big scythe blade sweeping left over the hood
    c.line(13, 2, 9, 1, 'S'); c.line(9, 1, 5, 2, 'S'); c.line(5, 2, 3, 4, 'S')
    c.line(12, 3, 9, 2, 's'); c.line(9, 2, 7, 2, 's')
    c.put(13, 1, 's')
    return c


WRAITH_PAL = {'B': 0x4a70c0, 'e': 0x60c0ff, 'b': 0x90c0ff, 'd': 0x1e2e6a, 'K': 0x0a0a1e, 'E': 0xa0fff0, 'W': 0xf0f0e0,
              'H': 0x5a4030, 'S': 0xd0dae8, 's': 0x8a9ab0}


# ----------------------------------------------------------------- Sprite (16x16, tiny)
def sprite(t):
    c = Canvas(16, 16)
    b = t
    # two leaf wings fluttering behind
    c.poly([(7, 7 + b), (4, 2 + b + t), (1, 3 + b + t), (3, 6 + b), (6, 8 + b)], 'L')
    c.poly([(7, 9 + b), (2, 9 + b - t), (1, 12 + b - t), (4, 12 + b), (7, 10 + b)], 'L')
    c.shade('L', 'l', 'n')
    c.line(6, 7 + b, 3, 3 + b + t, 'n'); c.line(6, 9 + b, 2, 11 + b - t, 'n')
    # glowing round head and petal dress
    c.ellipse(10, 5 + b, 2.2, 2.2, 'S')
    c.poly([(8, 8 + b), (11, 8 + b), (13, 12 + b), (7, 12 + b)], 'D')
    c.shade('D', 'S', 'G')
    c.shade('S', 'g', 'G')
    # arms reaching forward with a spark
    c.line(11, 9 + b, 13, 8 + b, 'S')
    c.put(14, 7 + b - t, 'g')
    # leafy hair, eyes
    c.line(8, 3 + b, 11, 2 + b, 'n'); c.put(8, 4 + b, 'n')
    c.put(10, 5 + b, 'K'); c.put(12, 5 + b, 'K')
    # legs and sparkle trail
    c.put(9, 13 + b, 'S'); c.put(11, 13 + b, 'S')
    c.put(6, 14 - t, 'g')
    return c


SPRITE_PAL = {'S': 0xc8ffb0, 'D': 0x9ae890, 'g': 0xffffff, 'G': 0x80e080, 'L': 0x50b040, 'l': 0x90e070, 'n': 0x206a20,
              'K': 0x1a4a1a}


# ----------------------------------------------------------------- Sprite God (20x20)
def sprite_god(t):
    c = Canvas(20, 20)
    f = t
    # four gossamer wings
    up = [(9, 7), (3, 1 + f), (1, 3 + f), (2, 6), (8, 9)]
    lo = [(9, 10), (3, 11 - f), (2, 15 - f), (5, 15 - f), (9, 12)]
    for pts in (up, lo):
        c.poly(pts, 'V')
        c.poly([(19 - x, y) for x, y in pts], 'V')
    c.shade('V', 'v', 'u')
    # halo
    c.ring(10, 1.5, 3, 0.8, 'Y', 0.9)
    # flowing gown
    c.poly([(8, 8), (12, 8), (15, 19), (5, 19)], 'P')
    c.shade('P', 'p', 'q')
    c.line(8, 12, 12, 12, 'Y'); c.put(10, 12, 'W')
    # long hair framing the face
    c.ellipse(10, 5, 2.8, 2.6, 'H')
    c.poly([(7, 5), (8, 5), (8, 10), (7, 10)], 'H')
    c.shade('H', 'h', 'q')
    c.ellipse(10.5, 5.5, 1.7, 1.8, 'S')
    c.put(10, 5, 'E'); c.put(12, 5, 'E')
    # arms raised, a radiant orb
    c.line(9, 9, 6, 11 - f, 'S'); c.line(12, 9, 15, 8 - f, 'S')
    c.put(16, 7 - f, 'W'); c.put(17, 7 - f, 'Y'); c.put(16, 6 - f, 'Y'); c.put(16, 8 - f, 'Y')
    # sparkles
    c.put(1, 9 - f, 'W'); c.put(18, 15 + f, 'W'); c.put(2, 18, 'Y')
    return c


SPRITE_GOD_PAL = {'V': 0xd8d0ff, 'v': 0xf8f4ff, 'u': 0x9a88d8, 'P': 0xff80d0, 'p': 0xffc0e8, 'q': 0xb03a90,
                  'S': 0xffe0d0, 's': 0xffffff, 'z': 0xd0a090, 'H': 0xff50b0, 'h': 0xff90d0, 'E': 0x6a1a5a, 'Y': 0xffe060,
                  'W': 0xffffff}


# ----------------------------------------------------------------- White Demon (20x20)
def demon(t):
    c = Canvas(20, 20)
    b = t
    # legs, digitigrade
    c.line(8, 13, 7, 16, 'W', 2.2); c.line(7, 16, 8, 19, 'W', 1.6)
    c.line(12, 13, 13, 16, 'W', 2.2); c.line(13, 16, 12, 19, 'W', 1.6)
    # hulking torso and shoulders
    c.ellipse(10, 10 + b * 0.5, 5.5, 4, 'W')
    c.ellipse(4.5, 8 + b, 2.2, 2, 'W'); c.ellipse(15.5, 8 + b, 2.2, 2, 'W')
    # long arms
    c.line(4, 9 + b, 3, 14 + b, 'W', 2); c.line(16, 9 + b, 17, 14 + b, 'W', 2)
    # head hunched forward between the shoulders
    c.ellipse(12, 5 + b, 2.8, 2.6, 'W')
    c.shade('W', 'w', 'v')
    # loincloth
    c.rect(8, 13, 12, 14, 'K')
    c.put(10, 15, 'K')
    # big curling horns
    c.line(10, 3 + b, 8, 2 + b, 'R'); c.line(8, 2 + b, 7, 4 + b, 'R'); c.put(6, 4 + b, 'r')
    c.line(14, 3 + b, 16, 1 + b, 'R'); c.put(17, 1 + b, 'r'); c.put(16, 2 + b, 'R')
    # brow, red eyes, fanged mouth
    c.line(11, 4 + b, 14, 4 + b, 'v')
    c.put(12, 5 + b, 'E'); c.put(14, 5 + b, 'E')
    c.line(12, 7 + b, 14, 7 + b, 'K'); c.put(13, 7 + b, 'F')
    # claws
    for (x, y) in [(2, 15), (3, 16), (4, 15), (16, 15), (17, 16), (18, 15)]:
        c.put(x, y + b, 'R')
    c.put(6, 19, 'R'); c.put(13, 19, 'R')
    # chest scar
    c.line(8, 9 + b, 10, 11 + b, 'v')
    return c


DEMON_PAL = {'W': 0xe4dcdc, 'w': 0xffffff, 'v': 0x9a8a92, 'R': 0xd02020, 'r': 0x6a0a0a, 'E': 0xff2020,
             'K': 0x2a1418, 'F': 0xffffff}


# ----------------------------------------------------------------- Lesser Demon (16x16)
def lesser_demon(t):
    c = Canvas(16, 16)
    f = t
    # small bat wing
    c.poly([(8, 8), (5, 2 - f + 1), (1, 3 - f + 1), (2, 5), (3, 5), (4, 7), (6, 9)], 'M')
    c.shade('M', 'm', 'n')
    c.line(7, 8, 4, 3 - f + 1, 'n')
    # spiked tail curling back
    c.line(5, 12, 2, 13, 'R'); c.line(2, 13, 1, 10 + f, 'R')
    # hunched body, bent legs
    c.ellipse(7.5, 10.5, 3.5, 2.8, 'R')
    c.line(6, 12, 5, 15, 'R'); c.line(9, 12, 10, 15, 'R')
    c.put(4, 15, 'R'); c.put(11, 15, 'R')
    # head low and forward
    c.ellipse(11.5, 8, 2.4, 2.2, 'R')
    # arm reaching with claws
    c.line(10, 11, 13, 12, 'R')
    c.shade('R', 'r', 'd')
    c.poly([(0, 10 + f), (2, 10 + f), (1, 7 + f)], 'B')
    c.put(14, 12, 'B'); c.put(14, 13, 'B')
    # horns
    c.put(10, 5, 'B'); c.put(10, 4, 'B'); c.put(13, 5, 'B'); c.put(14, 4, 'B')
    # eyes and grin
    c.put(12, 7, 'Y'); c.put(13, 7, 'Y')
    c.line(12, 9, 13, 9, 'K')
    return c


LESSER_DEMON_PAL = {'R': 0xa02828, 'r': 0xd04a3a, 'd': 0x501010, 'M': 0x6a1818, 'm': 0x9a3030, 'n': 0x300808,
                    'B': 0xe8d8b0, 'Y': 0xffe040, 'K': 0x1a0404}


# ----------------------------------------------------------------- Thunder Golem (18x18)
def thunder_golem(t):
    c = Canvas(18, 18)
    # legs
    c.rect(5, 13, 7, 17, 'S'); c.rect(10, 13, 12, 17, 'S')
    # torso
    c.poly([(4, 5), (13, 5), (12, 13), (5, 13)], 'S')
    # boulder arms
    c.ellipse(3, 7, 2, 2, 'S'); c.ellipse(14, 7, 2, 2, 'S')
    c.rect(1, 8, 3, 12, 'S'); c.rect(14, 8, 16, 12, 'S')
    c.ellipse(2, 13, 1.8, 1.6, 'S'); c.ellipse(15, 13, 1.8, 1.6, 'S')
    # small head
    c.rect(7, 2, 10, 4, 'S')
    c.shade('S', 's', 'd')
    # lightning cracks
    c.line(5, 7, 6, 9, 'Y'); c.line(6, 9, 5, 11, 'Y')
    c.line(13, 8, 12, 10, 'Y')
    c.line(2, 9, 3, 11, 'Y'); c.line(15, 9, 14, 11, 'Y')
    c.put(6, 15, 'Y'); c.put(11, 14, 'Y')
    # storm core
    c.ellipse(9, 9, 1.8, 1.8, 'L')
    c.put(9, 9, 'W')
    c.put(8, 3, 'Y'); c.put(10, 3, 'Y')
    # arcs crackling over the head and fists
    if t:
        c.line(5, 1, 6, 3, 'Y'); c.line(13, 1, 12, 3, 'Y')
        c.put(0, 15, 'Y')
    else:
        c.line(6, 1, 5, 3, 'Y'); c.line(12, 1, 13, 3, 'Y')
        c.put(17, 15, 'Y')
    return c


THUNDER_GOLEM_PAL = {'S': 0x4a5062, 's': 0x7a849a, 'd': 0x22262e, 'Y': 0xffff60, 'L': 0x60d0ff, 'W': 0xffffff}


MONSTERS = [
    ('beholder', beholder, BEHOLDER_PAL, 3),
    ('gazer', gazer, GAZER_PAL, 3),
    ('green_slime', green_slime, GREEN_SLIME_PAL, 3),
    ('slime', slime, SEA_SLIME_PAL, 3),
    ('slime_god', slime_god, SLIME_GOD_PAL, 3),
    ('spider', spider, SPIDER_PAL, 3),
    ('spider_queen', spider_queen, SPIDER_QUEEN_PAL, 3),
    ('snake', snake, SNAKE_PAL, 3),
    ('great_snake', great_snake, GREAT_SNAKE_PAL, 3),
    ('cloud_serpent', cloud_serpent, CLOUD_SERPENT_PAL, 3),
    ('ghost', ghost, GHOST_PAL, 3),
    ('ghost_god', ghost_god, GHOST_GOD_PAL, 3),
    ('grave_wraith', grave_wraith, WRAITH_PAL, 3),
    ('sprite', sprite, SPRITE_PAL, 3),
    ('sprite_god', sprite_god, SPRITE_GOD_PAL, 3),
    ('demon', demon, DEMON_PAL, 3),
    ('lesser_demon', lesser_demon, LESSER_DEMON_PAL, 3),
    ('thunder_golem', thunder_golem, THUNDER_GOLEM_PAL, 3),
]
