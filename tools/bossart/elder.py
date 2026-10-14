"""
Azrakor the Dark Elder, after the design sheet: a towering robed thing in a
pointed silver hood with one burning vertical eye where a face should be,
silver shoulder blades, glowing purple seams and gems down its robe, a mass of
tentacles writhing behind it and void orbs circling it.

Like Vorgath (vorgath.py) it has an animation for each of its attacks, each its
own sprite ("elder_blast" and so on) that the game plays when it uses that
attack. "elder" keeps the usual six frames for the wiki and anything else that
shows a boss; the old drawing lives on as "elder_classic" (the Archon and the
Abyssal Herald are recoloured from it).
"""
import math
from canvas import Canvas

W, H = 92, 96
CX = 46          # the middle of its body
FOOT = 86        # where its robe meets the ground (drawing space)
OY = 6           # headroom above for the curling tentacles

PAL = {
    # the robe (base, light, dark)
    'K': 0x1c1236, 'k': 0x3a2868, 'n': 0x0a0616,
    # tentacles
    'T': 0x2c1e52, 't': 0x54409a, 'u': 0x120a26,
    # silver hood and shoulder blades
    'S': 0x8c88ae, 's': 0xd0cce8, 'z': 0x4a4670,
    # the void's light
    'P': 0xb040ff, 'p': 0xe4a8ff, 'V': 0x6a22b4, 'W': 0xfff0ff,
    # the void itself
    'X': 0x06000c,
    # enraged fire
    'F': 0xc860ff, 'f': 0xf2d4ff,
}


def h32(*a):
    v = 2166136261
    for x in a:
        v = ((v ^ (int(x) & 0xffffffff)) * 16777619) & 0xffffffff
    return v


class VCanvas(Canvas):
    """Draws everything OY pixels lower, so poses can reach above y=0."""
    def __init__(self):
        Canvas.__init__(self, W, H)

    def put(self, x, y, c, only=None):
        Canvas.put(self, x, y + OY, c, only)

    def get(self, x, y):
        return Canvas.get(self, int(round(x)), int(round(y)) + OY)


def pose(**k):
    p = dict(t=0, bx=0, by=0, wild=1.0, arms='robe', hand=None, orb=0, orbs=True, orb_r=1.0, orb_spin=0.0,
             eye='P', glow=False, fade=0.0, shrink=0)
    p.update(k)
    return p


# ------------------------------------------------------------------ the parts
def tentacle(c, x0, y0, ang, length, wid, phase, wild, curl=1):
    """A tentacle from (x0, y0): a wavering line that thins to a curling tip."""
    x, y = x0, y0
    n = 14
    pts = []
    for i in range(n + 1):
        f = i / n
        a = ang + math.sin(phase + f * 4.2) * 0.45 * wild * f + curl * f * f * 1.4
        pts.append((x, y, wid * (1 - f * 0.8)))
        x += math.cos(a) * length / n
        y += math.sin(a) * length / n
    for i in range(len(pts) - 1):
        (xa, ya, wa), (xb, yb, wb) = pts[i], pts[i + 1]
        c.line(xa, ya, xb, yb, 'T', max(1, (wa + wb) / 2))
    # suckers along it
    for i in range(2, n - 2, 3):
        c.put(pts[i][0], pts[i][1], 'V')
    return pts[-1]


def tentacles(c, p):
    t, wild = p['t'], p['wild']
    bx, by = CX + p['bx'], p['by']
    # a dark mass of them behind it
    c.ellipse(bx, 40 + by, 20, 22, 'T')
    # fourteen writhing out to the sides, up and down, thick at the root
    spec = [(-2.6, 30, 7, -1), (-2.2, 34, 7.5, -1), (-1.0, 30, 7, 1), (-0.5, 34, 7.5, 1),
            (-2.95, 28, 6, -1), (-0.15, 28, 6, 1), (2.6, 26, 6, -1), (0.5, 26, 6, 1),
            (-1.9, 26, 6, -1), (-1.25, 26, 6, 1), (2.2, 30, 6.5, -1), (0.9, 30, 6.5, 1), (2.9, 22, 5, -1), (0.2, 22, 5, 1)]
    for k, (ang, ln, wd, side) in enumerate(spec):
        y0 = 30 + by + (k % 3) * 6
        tentacle(c, bx + side * 7, y0, ang, ln * (0.9 + 0.15 * wild), wd, t * 1.3 + k * 1.7, wild, curl=side)
    for side in (-1, 1):
        tentacle(c, bx + side * 5, 16 + by, -math.pi / 2 - side * 0.45, 20 + 3 * wild, 4, t * 1.5 + side, wild, curl=side)
    c.shade('T', 't', 'u')


def robe(c, p):
    bx, by = CX + p['bx'], p['by']
    t = p['t']
    hem = FOOT - p['shrink']
    # the robe, its hem trailing off into wisps
    pts = [(bx - 10, 26 + by), (bx + 10, 26 + by), (bx + 17, hem - 6), (bx + 15 + math.sin(t) * 1.5, hem),
           (bx + 9, hem - 3), (bx + 4, hem + 1), (bx, hem - 3), (bx - 4, hem + 1), (bx - 9, hem - 3),
           (bx - 15 + math.sin(t + 1) * 1.5, hem), (bx - 17, hem - 6)]
    c.poly(pts, 'K')
    # folds
    for dx in (-9, -4, 4, 9):
        c.line(bx + dx * 0.6, 34 + by, bx + dx, hem - 4, 'n')
    c.shade('K', 'k', 'n')
    # the glowing seam and its gems
    glow = 'p' if p['glow'] else 'P'
    c.line(bx, 32 + by, bx, hem - 4, 'V', 1.4)
    c.line(bx, 34 + by, bx, hem - 6, glow)
    for gy, r in ((44, 3.4), (60, 2.6), (74, 2)):
        y = gy + by
        c.poly([(bx, y - r * 1.6), (bx + r, y), (bx, y + r * 1.6), (bx - r, y)], 'P')
        c.put(bx, y, 'W')
    # side seams
    for sgn in (-1, 1):
        c.line(bx + sgn * 6, 36 + by, bx + sgn * 12, hem - 8, 'V')
    # silver belt plates
    c.rect(bx - 9, 40 + by, bx + 9, 41 + by, 'z')


def shoulders(c, p):
    bx, by = CX + p['bx'], p['by']
    for sgn in (-1, 1):
        c.poly([(bx + sgn * 6, 24 + by), (bx + sgn * 23, 28 + by), (bx + sgn * 18, 33 + by), (bx + sgn * 9, 36 + by)], 'S')
        c.line(bx + sgn * 8, 26 + by, bx + sgn * 20, 29 + by, 's')
        c.put(bx + sgn * 14, 30 + by, 'P')
    c.shade('S', 's', 'z')


def hood(c, p):
    bx, by = CX + p['bx'], p['by']
    # the pointed silver cowl
    c.poly([(bx, 2 + by), (bx + 8, 12 + by), (bx + 11, 22 + by), (bx + 8, 31 + by), (bx - 8, 31 + by), (bx - 11, 22 + by), (bx - 8, 12 + by)], 'S')
    c.shade('S', 's', 'z')
    c.line(bx, 3 + by, bx, 9 + by, 's')
    # the dark where a face should be
    c.poly([(bx, 10 + by), (bx + 6, 18 + by), (bx + 5, 28 + by), (bx, 31 + by), (bx - 5, 28 + by), (bx - 6, 18 + by)], 'X')
    # the eye: one great vertical slit of violet light
    eye = p['eye']
    c.ellipse(bx, 20 + by, 2.6, 7, eye)
    c.ellipse(bx, 20 + by, 1.2, 5, 'p' if eye != 'V' else 'V')
    if eye != 'V':
        c.line(bx, 15 + by, bx, 25 + by, 'W')
    # a gem on the brow
    c.put(bx, 9 + by, 'P'); c.put(bx, 8 + by, 'p')


def arms(c, p):
    """Sleeves reaching out (forward: its right side; up; spread), with clawed silver hands."""
    if p['arms'] == 'robe':
        return
    bx, by = CX + p['bx'], p['by']
    ends = {
        'forward': [(-1, (bx - 16, 40 + by)), (1, (bx + 30, 34 + by))],
        'up': [(-1, (bx - 22, 6 + by)), (1, (bx + 22, 6 + by))],
        'spread': [(-1, (bx - 32, 30 + by)), (1, (bx + 32, 30 + by))],
        'together': [(-1, (bx - 6, 46 + by)), (1, (bx + 6, 46 + by))],
        'down': [(-1, (bx - 26, 56 + by)), (1, (bx + 26, 56 + by))],
    }[p['arms']]
    for sgn, (hx, hy) in ends:
        c.line(bx + sgn * 12, 30 + by, hx, hy, 'K', 5)
        c.shade('K', 'k', 'n')
        for k in (-1, 0, 1):
            c.line(hx, hy, hx + sgn * 3 + k, hy - 2 + k * 2, 'S')
        c.put(hx, hy, 'p' if p['glow'] else 'P')
    return ends


def void_orb(c, x, y, r=3.0, bright=False):
    c.ellipse(x, y, r + 1.2, r + 1.2, 'P')
    c.ellipse(x, y, r, r, 'X')
    c.put(x - r * 0.5, y - r * 0.5, 'p' if not bright else 'W')
    if bright:
        c.ring(x, y, r + 3, r + 3, 'p', 1)


def orbs(c, p):
    if not p['orbs']:
        return
    t = p['t']
    bx, by = CX + p['bx'], p['by']
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4 + t * 0.35 + p['orb_spin']
        x = bx + math.cos(a) * 36 * p['orb_r']
        y = 46 + by + math.sin(a) * 26 * p['orb_r']
        void_orb(c, x, y, 3.0)


def sparkles(c, t, n=8):
    for i in range(n):
        hv = h32(i, t, 3)
        x, y = hv % W, (hv >> 8) % 80 + 2
        if c.get(x, y) == '.':
            c.put(x, y, 'p' if i % 3 else 'W')


def elder(p, draw_orbs=True):
    c = VCanvas()
    tentacles(c, p)
    robe(c, p)
    shoulders(c, p)
    hood(c, p)
    arms(c, p)
    if draw_orbs:
        orbs(c, p)
    return c


# ------------------------------------------------------------------ effects
def ground_ring(c, cx, cy, rx, ry, col='P', inner='V', rot=0, runes=True):
    c.ring(cx, cy, rx, ry, col, 1.2)
    c.ring(cx, cy, rx * 0.7, ry * 0.7, inner, 1)
    if runes:
        for k in range(10):
            a = k * math.pi / 5 + rot
            c.put(cx + math.cos(a) * rx * 0.85, cy + math.sin(a) * ry * 0.85, 'W')


def pillar(c, x, top, bottom, wid=3):
    c.rect(x - wid, top, x + wid, bottom, 'V')
    c.rect(x - wid + 1, top, x + wid - 1, bottom, 'P')
    c.line(x, top, x, bottom, 'W')
    c.ellipse(x, bottom, wid + 4, 2, 'P')


def rising_tentacle(c, x, base, height, lean, t):
    tentacle(c, x, base, -math.pi / 2 + lean, height, 5, t, 0.5, curl=1 if lean > 0 else -1)
    c.shade('T', 't', 'u')
    c.ellipse(x, base, 6, 1.6, 'P')


def dissolve(c, keep):
    """Breaks the drawing into drifting motes: keeps about `keep` of its pixels."""
    for y in range(H):
        for x in range(W):
            if c.g[y][x] != '.' and (h32(x, y, 11) % 100) >= keep * 100:
                c.g[y][x] = '.' if (h32(x, y) % 7) else 'p'
    return c


def flames(c, t, strength=1.0):
    """Enraged: violet fire licking up from every top edge of it."""
    src = [row[:] for row in c.g]
    for x in range(W):
        for y in range(1, H):
            if src[y][x] != '.' and src[y - 1][x] == '.' and src[y][x] not in 'Ffp':
                hv = h32(x, y, t)
                if hv % 2:
                    continue
                hgt = int((3 + hv % 6) * strength)
                for k in range(1, hgt + 1):
                    yy, xx = y - k, x + (1 if (hv >> (k + 3)) & 1 and k > 1 else 0)
                    if 0 <= xx < W and 0 <= yy < H and c.g[yy][xx] == '.':
                        c.g[yy][xx] = 'f' if k == 1 else 'F' if k < hgt * 0.6 else 'V'
    return c


def rift_shape(c, x, y, rx, ry):
    """An eye-shaped tear in the world."""
    pts = []
    for i in range(24):
        a = i * math.pi * 2 / 24
        pts.append((x + math.cos(a) * rx * (abs(math.cos(a)) ** 0.3), y + math.sin(a) * ry))
    c.poly([(x, y - ry - 2), (x + rx, y), (x, y + ry + 2), (x - rx, y)], 'P')
    c.poly([(x, y - ry), (x + rx - 2, y), (x, y + ry), (x - rx + 2, y)], 'X')
    c.line(x, y - ry + 3, x, y + ry - 3, 'V')
    c.ellipse(x, y, 1.4, ry * 0.4, 'p')


# ------------------------------------------------------------------ the animations
def idle(t):
    b = [0, 1, 1, 0][t]
    c = elder(pose(t=t, by=b))
    sparkles(c, t, 6)
    return c


def move(t):
    b = [0, 1, 2, 1, 0, -1][t]
    c = elder(pose(t=t + 0.5, by=b, bx=1, wild=1.3))
    # a trail of void motes behind it
    for i in range(6):
        hv = h32(i, t, 5)
        x, y = 4 + hv % 14, 40 + (hv >> 8) % 40
        if c.get(x, y) == '.':
            c.put(x, y, 'p' if i % 2 else 'V')
    return c


def blast(t):
    """Void blast: an orb gathers in its outstretched hand and is hurled."""
    k = [(0, 0), (1, 2.5), (2, 4.5), (3, 6), (4, 0), (5, 0)][t]
    c = elder(pose(t=t, arms='forward' if t < 5 else 'robe', glow=t in (2, 3), eye='W' if t == 3 else 'P', orb_spin=t * 0.2))
    hx, hy = CX + 30, 34
    if 1 <= t <= 3:
        void_orb(c, hx + 4, hy - 4, k[1], bright=t == 3)
        for i in range(6):
            a = i * math.pi / 3 + t
            c.put(hx + 4 + math.cos(a) * (k[1] + 6), hy - 4 + math.sin(a) * (k[1] + 6), 'p')
    if t == 4:
        # loosed: a streak to the edge
        c.line(hx, hy - 4, W - 1, hy - 4, 'P', 3)
        c.line(hx, hy - 4, W - 1, hy - 4, 'W')
    return c


def pillars(t):
    """Void blast (vertical): arms raised, columns of violet light burst from the ground."""
    c = elder(pose(t=t, arms='up' if 0 < t < 4 else 'robe', glow=t in (2, 3), eye='W' if t == 2 else 'P'))
    if t in (2, 3):
        for x, h in ((10, 50), (82, 50), (24, 38), (68, 38)):
            pillar(c, x, FOOT - h + (0 if t == 2 else 10), FOOT, 3 if t == 2 else 2)
    if t == 1:
        for x in (10, 24, 68, 82):
            c.ellipse(x, FOOT, 5, 1.5, 'V')
    return c


def slam(t):
    """Tentacle slam: tentacles burst from the ground at its feet and come crashing down."""
    c = elder(pose(t=t, wild=1.8, arms='down' if t in (1, 2, 3) else 'robe'))
    if t == 1:
        for x in (14, 78):
            rising_tentacle(c, x, FOOT, 16, 0.2 if x > CX else -0.2, t)
    if t == 2:
        for x in (14, 78):
            rising_tentacle(c, x, FOOT, 40, 0.15 if x > CX else -0.15, t)
    if t == 3:
        for x in (14, 78):
            rising_tentacle(c, x, FOOT, 34, 0.9 if x > CX else -0.9, t)
            ground_ring(c, x + (14 if x > CX else -14), FOOT, 10, 2.5, runes=False)
    if t == 4:
        for x in (14, 78):
            rising_tentacle(c, x, FOOT, 10, 0.4 if x > CX else -0.4, t)
    return c


def summon(t):
    """Summon: arms spread, a ring on the ground, and hooded shades rise from it."""
    c = VCanvas()
    if t >= 1:
        ground_ring(c, CX, FOOT, 40, 7, rot=t * 0.3)
    body = elder(pose(t=t, arms='spread' if 0 < t < 4 else 'robe', glow=t >= 2, eye='W' if t == 2 else 'P'))
    for y in range(H):
        for x in range(W):
            if body.g[y][x] != '.':
                c.g[y][x] = body.g[y][x]
    if t >= 2:
        hgt = [0, 0, 6, 11, 11][t]
        for x in (10, 82, 22, 70):
            c.poly([(x, FOOT - hgt), (x + 4, FOOT - hgt + 4), (x + 4, FOOT), (x - 4, FOOT), (x - 4, FOOT - hgt + 4)], 'K')
            c.put(x - 1, FOOT - hgt + 3, 'P'); c.put(x + 1, FOOT - hgt + 3, 'P')
    return c


def teleport(t):
    """Teleport: it comes apart into motes, a rift swallows them, and it pours back out."""
    if t in (0, 5):
        c = elder(pose(t=t, glow=True))
        sparkles(c, t, 18)
        return c
    if t == 1:
        return dissolve(elder(pose(t=t, glow=True)), 0.55)
    if t == 2:
        c = dissolve(elder(pose(t=t)), 0.18)
        rift_shape(c, CX, 46, 6, 22)
        return c
    if t == 3:
        c = VCanvas()
        for k in range(3):
            c.ring(CX, 50, 14 + k * 7, 6 + k * 3, 'P' if k == 0 else 'V', 1)
        rift_shape(c, CX, 46, 4, 18)
        sparkles(c, t, 20)
        return c
    c = dissolve(elder(pose(t=t, glow=True)), 0.6)
    rift_shape(c, CX, 46, 3, 14)
    return c


def spread(t):
    """Ranged spread: a fan of void orbs flung from its hand."""
    c = elder(pose(t=t, arms='forward' if t < 4 else 'robe', glow=t == 2, orb_spin=t * 0.4))
    hx, hy = CX + 30, 34
    if t == 1:
        void_orb(c, hx + 3, hy - 3, 2.5)
    if t in (2, 3):
        d = 6 if t == 2 else 12
        for k in range(5):
            a = (k - 2) * 0.35
            void_orb(c, hx + 3 + math.cos(a) * d, hy - 3 + math.sin(a) * d * 1.6, 1.8)
    return c


def explode(t):
    """Void explosion: it gathers itself, then a ring of the void bursts out round it."""
    c = VCanvas()
    if t >= 2:
        rr = [0, 0, 18, 32, 42][t]
        ground_ring(c, CX, FOOT, rr, rr * 0.2 + 2, rot=t * 0.4)
    body = elder(pose(t=t, arms='together' if t == 1 else 'spread' if t in (2, 3) else 'robe', glow=t >= 1,
                      eye='W' if t in (2, 3) else 'P', orb_r=1.0 + (0.25 if t in (2, 3) else 0)))
    for y in range(H):
        for x in range(W):
            if body.g[y][x] != '.':
                c.g[y][x] = body.g[y][x]
    if t == 3:
        for k in range(12):
            a = k * math.pi / 6
            c.line(CX + math.cos(a) * 30, 46 + math.sin(a) * 30, CX + math.cos(a) * 40, 46 + math.sin(a) * 40, 'p')
    return c


def gravity(t):
    """Gravity pull: rings spiral in round its feet and everything is drawn toward it."""
    c = VCanvas()
    for k in range(3):
        rr = (34 - k * 9) - t * 3
        if rr > 4:
            c.ring(CX, FOOT - 2, rr, rr * 0.28, 'P' if k == 0 else 'V', 1)
    body = elder(pose(t=t, arms='together' if t in (1, 2, 3) else 'robe', glow=True, orb_r=1.0 - t * 0.12, orb_spin=t * 0.6))
    for y in range(H):
        for x in range(W):
            if body.g[y][x] != '.':
                c.g[y][x] = body.g[y][x]
    # motes drawn inward
    for i in range(16):
        a = i * math.pi / 8 + t * 0.5
        r = 44 - ((i * 7 + t * 9) % 30)
        x, y = CX + math.cos(a) * r, 46 + math.sin(a) * r * 0.8
        if c.get(x, y) == '.':
            c.put(x, y, 'p')
    return c


def rift(t):
    """Phase 2: it tears the world open, a great eye-shaped rift in front of it."""
    c = elder(pose(t=t, wild=2.0, arms='spread' if 0 < t < 4 else 'robe', eye='W', glow=True))
    sizes = [0, 4, 10, 14, 6]
    if sizes[t]:
        rift_shape(c, CX + 34, 50, sizes[t] * 0.7, sizes[t] * 2.2)
    return c


def death(t):
    """It shudders, the eye gutters out, it unravels into motes and the void swallows the last of it."""
    if t <= 2:
        c = elder(pose(t=t, wild=2.2 - t * 0.4, eye=['W', 'P', 'V'][t], by=t * 3, shrink=t * 3))
        for i in range(4 + t * 4):
            hv = h32(i, t, 9)
            x, y = 30 + hv % 32, 20 + (hv >> 6) % 50
            c.line(x, y, x + (hv >> 3) % 5 - 2, y + 4, 'p')
        return c
    if t <= 4:
        return dissolve(elder(pose(t=t, by=8, shrink=8, eye='V', wild=0.6)), [0, 0, 0, 0.5, 0.25][t])
    c = VCanvas()
    if t == 5:
        void_orb(c, CX, 48, 6, bright=True)
        sparkles(c, t, 24)
    else:
        void_orb(c, CX, 48, 2)
        sparkles(c, t, 10)
    return c


SEQ = [
    ('idle', idle, 4), ('move', move, 6), ('blast', blast, 6), ('pillars', pillars, 5), ('slam', slam, 5),
    ('summon', summon, 5), ('teleport', teleport, 6), ('spread', spread, 5), ('explode', explode, 5),
    ('gravity', gravity, 5), ('rift', rift, 5), ('death', death, 7),
]


def sequences():
    """[(sprite name, [frame rows], palette, scale)]: one sprite per animation, plus the enraged idle and move."""
    out = []
    for name, fn, n in SEQ:
        out.append(('elder_' + name, [fn(t).rows() for t in range(n)], PAL, 4))

    def rage(fn, t):
        c = fn(t)
        # wilder, burning
        return flames(c, t + 3)
    out.append(('elder_ridle', [flames(elder(pose(t=t, by=[0, 1, 1, 0][t], wild=2.0, eye='W', glow=True)), t).rows() for t in range(4)], PAL, 4))
    out.append(('elder_rmove', [flames(elder(pose(t=t + 0.5, by=[0, 1, 2, 1, 0, -1][t], bx=1, wild=2.2, eye='W', glow=True)), t + 9).rows() for t in range(6)], PAL, 4))
    base = [idle(0).rows(), idle(2).rows(), move(0).rows(), move(3).rows(), blast(2).rows(), blast(3).rows()]
    out.append(('elder', base, PAL, 4))
    return out
