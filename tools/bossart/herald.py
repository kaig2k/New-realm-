"""
The Abyssal Herald, after the design sheet: "the voice of the deep". A tall
hooded priest of the drowned dark in navy robes trimmed with glowing cyan, a
crown of black spines tipped with cyan crystal, a single cyan eye, a trident
staff blazing at its head, and tentacles coiling up round its robe from behind.

Like the Dark Elder (elder.py, whose drawing tools it borrows: the letters mean
the same things, in the deep's colours) it has an animation for each attack,
each its own sprite ("abyss_herald_barrage" and so on). Also its minion, the
little abyss spawn (a squid of the deep).
"""
import math
from canvas import Canvas
import elder as E
from elder import VCanvas, W, H, CX, FOOT, h32

PAL = {
    # robe (base, light, dark)
    'K': 0x1a2050, 'k': 0x34407c, 'n': 0x0a0e28,
    # tentacles
    'T': 0x1c2858, 't': 0x3a5aa0, 'u': 0x0c1230,
    # dark spined armour and crown
    'S': 0x3a4a78, 's': 0x7a90c8, 'z': 0x161e3e,
    # the deep's light: cyan, pale, deep blue, white
    'P': 0x30d8ff, 'p': 0xb8f6ff, 'V': 0x2050e0, 'W': 0xf0ffff,
    # the abyss itself
    'X': 0x02040e,
    # enraged fire (cold blue flame)
    'F': 0x40a0ff, 'f': 0xd0f4ff,
    # the trident's shaft
    'G': 0x5a6a90, 'g': 0x9aa8d0,
}


def pose(**k):
    p = dict(t=0, bx=0, by=0, wild=1.0, staff='hold', arm='rest', eye='P', glow=False, shrink=0, orbs=True, orb_r=1.0, orb_spin=0.0)
    p.update(k)
    return p


# ------------------------------------------------------------------ the parts
def tentacles(c, p):
    t, wild = p['t'], p['wild']
    bx, by = CX + p['bx'], p['by']
    # coiling up round the robe from behind: low and wide, curling at the tips
    spec = [(-2.9, 30, 7, -1), (-2.5, 34, 7.5, -1), (-0.25, 30, 7, 1), (-0.6, 34, 7.5, 1),
            (2.8, 26, 6.5, -1), (0.35, 26, 6.5, 1), (-3.0, 22, 5, -1), (-0.1, 22, 5, 1), (2.4, 20, 5, -1), (0.8, 20, 5, 1)]
    for k, (ang, ln, wd, side) in enumerate(spec):
        y0 = 58 + by + (k % 3) * 6
        E.tentacle(c, bx + side * 8, y0, ang, ln * (0.85 + 0.2 * wild), wd, t * 1.2 + k * 1.9, wild, curl=-side)
    if wild > 1.5:
        for side in (-1, 1):
            E.tentacle(c, bx + side * 10, 34 + by, -math.pi / 2 - side * 0.9, 24, 5, t * 1.6 + side, wild, curl=side)
    c.shade('T', 't', 'u')
    # cyan suckers glowing along their undersides
    for y in range(H):
        for x in range(W):
            if c.g[y][x] == 'u' and h32(x, y, 4) % 9 == 0:
                c.g[y][x] = 'P'


def robe(c, p):
    bx, by = CX + p['bx'], p['by']
    t = p['t']
    hem = FOOT - p['shrink']
    pts = [(bx - 9, 26 + by), (bx + 9, 26 + by), (bx + 15, hem - 8), (bx + 14 + math.sin(t) * 1.5, hem),
           (bx + 7, hem - 2), (bx + 2, hem + 1), (bx - 2, hem - 2), (bx - 7, hem + 1), (bx - 14 + math.sin(t + 1) * 1.5, hem), (bx - 15, hem - 8)]
    c.poly(pts, 'K')
    for dx in (-8, -3, 3, 8):
        c.line(bx + dx * 0.6, 36 + by, bx + dx, hem - 3, 'n')
    c.shade('K', 'k', 'n')
    # glowing cyan trim down the front and round the hem, and runes on it
    glow = 'p' if p['glow'] else 'P'
    for sgn in (-1, 1):
        c.line(bx + sgn * 3, 32 + by, bx + sgn * 5, hem - 3, 'V', 1.4)
        c.line(bx + sgn * 3, 33 + by, bx + sgn * 5, hem - 4, glow)
    for k in range(5):
        y = 42 + by + k * 8
        if y < hem - 4:
            c.put(bx, y, 'P'); c.put(bx - 1, y + 1, 'V'); c.put(bx + 1, y + 1, 'V')
    c.line(bx - 14, hem - 2, bx + 14, hem - 2, 'V')
    # a belt of dark plate
    c.rect(bx - 8, 40 + by, bx + 8, 41 + by, 'z')
    c.put(bx, 40 + by, 'P')


def collar(c, p):
    """The high spined collar and shoulder plates."""
    bx, by = CX + p['bx'], p['by']
    for sgn in (-1, 1):
        c.poly([(bx + sgn * 5, 24 + by), (bx + sgn * 19, 27 + by), (bx + sgn * 16, 34 + by), (bx + sgn * 8, 36 + by)], 'S')
        for k in range(3):
            sx = bx + sgn * (9 + k * 4)
            c.poly([(sx - 1.4, 27 + by), (sx + sgn * 2, 18 + by + k * 2), (sx + 1.4, 27 + by)], 'S')
            c.put(sx + sgn * 2, 18 + by + k * 2, 'P')
        c.line(bx + sgn * 7, 30 + by, bx + sgn * 16, 31 + by, 'P')
    c.shade('S', 's', 'z')


def head(c, p):
    bx, by = CX + p['bx'], p['by']
    # the crown of black spines, crystal-tipped, the tallest in the middle
    for dx, hgt, lean in ((0, 22, 0), (-4, 15, -1), (4, 15, 1), (-8, 11, -2), (8, 11, 2), (-11, 7, -3), (11, 7, 3)):
        x0 = bx + dx
        c.poly([(x0 - 1.8, 10 + by), (x0 + lean, 10 + by - hgt), (x0 + 1.8, 10 + by)], 'S')
        c.put(x0 + lean, 10 + by - hgt, 'p')
        c.put(x0 + lean * 0.9, 11 + by - hgt, 'P')
    # the hood
    c.poly([(bx - 9, 9 + by), (bx + 9, 9 + by), (bx + 10, 20 + by), (bx + 7, 29 + by), (bx - 7, 29 + by), (bx - 10, 20 + by)], 'S')
    c.shade('S', 's', 'z')
    c.poly([(bx - 6, 12 + by), (bx + 6, 12 + by), (bx + 5, 26 + by), (bx, 29 + by), (bx - 5, 26 + by)], 'X')
    # one eye, a diamond of cold light
    eye = p['eye']
    c.poly([(bx, 15 + by), (bx + 2.6, 19 + by), (bx, 23 + by), (bx - 2.6, 19 + by)], eye)
    c.poly([(bx, 17 + by), (bx + 1.2, 19 + by), (bx, 21 + by), (bx - 1.2, 19 + by)], 'p' if eye != 'V' else 'V')
    if eye != 'V':
        c.put(bx, 19 + by, 'W')


def staff(c, p):
    """The trident in its right hand (held, raised, thrust forward or planted)."""
    bx, by = CX + p['bx'], p['by']
    mode = p['staff']
    if mode == 'none':
        return
    hx, hy = {'hold': (bx + 19, 46 + by), 'raise': (bx + 18, 30 + by), 'thrust': (bx + 24, 40 + by), 'plant': (bx + 18, 52 + by)}[mode]
    top = {'hold': (bx + 21, 6 + by), 'raise': (bx + 22, -2 + by), 'thrust': (bx + 44, 26 + by), 'plant': (bx + 20, 14 + by)}[mode]
    bot = {'hold': (bx + 17, FOOT - 2), 'raise': (bx + 16, 62 + by), 'thrust': (bx + 10, 52 + by), 'plant': (bx + 17, FOOT)}[mode]
    # arm to the hand
    c.line(bx + 12, 30 + by, hx, hy, 'K', 5)
    c.shade('K', 'k', 'n')
    c.line(bot[0], bot[1], top[0], top[1], 'G', 2)
    c.shade('G', 'g', 'z')
    # the trident head: three cyan prongs
    ax, ay = top[0] - bot[0], top[1] - bot[1]
    L = math.hypot(ax, ay) or 1
    ux, uy = ax / L, ay / L
    px, py = -uy, ux
    tx, ty = top
    c.line(tx - px * 4, ty - py * 4, tx + px * 4, ty + py * 4, 'P', 1.6)
    for k in (-1, 0, 1):
        sx, sy = tx + px * 4 * k, ty + py * 4 * k
        ln = 7 if k == 0 else 5
        c.line(sx, sy, sx + ux * ln, sy + uy * ln, 'P', 1.6)
        c.put(sx + ux * ln, sy + uy * ln, 'W')
    c.ellipse(tx, ty, 1.6, 1.6, 'p')
    if p['glow']:
        c.ring(tx + ux * 3, ty + uy * 3, 7, 7, 'P', 1)
    # its clawed hand round the shaft
    c.ellipse(hx, hy, 2.4, 2.4, 'S')
    c.put(hx, hy, 'P')


def left_arm(c, p):
    bx, by = CX + p['bx'], p['by']
    mode = p['arm']
    if mode == 'rest':
        return
    hx, hy = {'out': (bx - 30, 34 + by), 'up': (bx - 20, 4 + by), 'down': (bx - 24, 58 + by), 'in': (bx - 6, 44 + by)}[mode]
    c.line(bx - 12, 30 + by, hx, hy, 'K', 5)
    c.shade('K', 'k', 'n')
    for k in (-1, 0, 1):
        c.line(hx, hy, hx - 3 + k, hy - 2 + k * 2, 'S')
    c.ellipse(hx - 2, hy, 2.2, 2.2, 'P')
    c.put(hx - 2, hy, 'W')


def wisps(c, t, n=8):
    """Cold flame drifting off it."""
    for i in range(n):
        hv = h32(i, t, 21)
        x = 8 + hv % (W - 16)
        y = 6 + (hv >> 8) % 70
        if c.get(x, y) == '.' and c.get(x, y + 1) == '.':
            c.put(x, y, 'p'); c.put(x, y + 1, 'P')


def herald(p):
    c = VCanvas()
    tentacles(c, p)
    robe(c, p)
    collar(c, p)
    head(c, p)
    left_arm(c, p)
    staff(c, p)
    if p['orbs']:
        bx, by = CX + p['bx'], p['by']
        for k in range(3):
            a = k * math.pi * 2 / 3 + p['t'] * 0.4 + p['orb_spin']
            E.void_orb(c, bx - 4 + math.cos(a) * 30 * p['orb_r'], 40 + by + math.sin(a) * 20 * p['orb_r'], 2.6)
    return c


def merge(base, top):
    for y in range(H):
        for x in range(W):
            if top.g[y][x] != '.':
                base.g[y][x] = top.g[y][x]
    return base


# ------------------------------------------------------------------ the animations
def idle(t):
    b = [0, 1, 1, 0][t]
    c = herald(pose(t=t, by=b))
    wisps(c, t, 6)
    return c


def move(t):
    b = [0, 1, 2, 1, 0, -1][t]
    c = herald(pose(t=t + 0.5, by=b, bx=1, wild=1.3))
    for i in range(6):
        hv = h32(i, t, 5)
        x, y = 4 + hv % 14, 44 + (hv >> 8) % 36
        if c.get(x, y) == '.':
            c.put(x, y, 'p' if i % 2 else 'V')
    return c


def barrage(t):
    """Orb barrage: orbs gather at the trident's head and stream out in a line."""
    c = herald(pose(t=t, staff='thrust' if 0 < t < 5 else 'hold', glow=t in (2, 3, 4), eye='W' if t == 3 else 'P', orb_spin=t * 0.3))
    tx, ty = CX + 44, 26
    if t in (1, 2):
        E.void_orb(c, tx + 3, ty - 2, 1.5 + t, bright=t == 2)
    if t in (3, 4):
        for k in range(3):
            E.void_orb(c, tx + 2 + k * 9 - (t - 3) * 4, ty - 2, 2.2)
        c.line(tx, ty - 2, W - 1, ty - 2, 'V')
    return c


def rain(t):
    """Orb barrage (vertical): the trident raised, orbs fall and burst from the ground in columns."""
    c = herald(pose(t=t, staff='raise' if 0 < t < 4 else 'hold', arm='up' if 0 < t < 4 else 'rest', glow=t in (1, 2), eye='W' if t == 2 else 'P'))
    if t == 1:
        for x in (12, 80):
            E.void_orb(c, x, 4, 2.4)
    if t in (2, 3):
        for x, h in ((10, 52), (82, 52), (26, 40), (66, 40)):
            E.pillar(c, x, FOOT - h + (0 if t == 2 else 12), FOOT, 3 if t == 2 else 2)
            E.void_orb(c, x, FOOT - h + (0 if t == 2 else 12) - 3, 2.2)
    return c


def summon(t):
    """Summon: it calls, and little spawn of the deep swim up out of a ring of light."""
    c = VCanvas()
    if t >= 1:
        E.ground_ring(c, CX, FOOT, 40, 7, rot=t * 0.3)
    merge(c, herald(pose(t=t, arm='out' if 0 < t < 4 else 'rest', staff='plant' if 0 < t < 4 else 'hold', glow=t >= 2, eye='W' if t == 2 else 'P')))
    if t >= 2:
        s = [0, 0, 0.6, 1.0, 1.0][t]
        for x in (10, 82, 22, 70):
            spawn_body(c, x, FOOT - 6, s, t)
    return c


def slam(t):
    """Tentacle slam: great tentacles burst from the deep at its feet and come down."""
    c = herald(pose(t=t, wild=1.8, arm='down' if t in (1, 2, 3) else 'rest', staff='plant' if t in (1, 2, 3) else 'hold'))
    if t == 1:
        for x in (12, 80):
            E.rising_tentacle(c, x, FOOT, 18, 0.2 if x > CX else -0.2, t)
    if t == 2:
        for x in (12, 80):
            E.rising_tentacle(c, x, FOOT, 44, 0.15 if x > CX else -0.15, t)
    if t == 3:
        for x in (12, 80):
            E.rising_tentacle(c, x, FOOT, 36, 0.95 if x > CX else -0.95, t)
            E.ground_ring(c, x + (14 if x > CX else -14), FOOT, 10, 2.5, runes=False)
    if t == 4:
        for x in (12, 80):
            E.rising_tentacle(c, x, FOOT, 10, 0.4 if x > CX else -0.4, t)
    c.shade('T', 't', 'u')
    return c


def teleport(t):
    """Teleport: it bursts into a star of cold light, gone, and flares back."""
    if t in (0, 5):
        c = herald(pose(t=t, glow=True))
        wisps(c, t, 18)
        return c
    if t == 1:
        return E.dissolve(herald(pose(t=t, glow=True)), 0.5)
    c = VCanvas()
    r = [0, 0, 10, 16, 8][t]
    # a four-pointed star of light
    c.poly([(CX, 46 - r * 2), (CX + 3, 46), (CX, 46 + r * 2), (CX - 3, 46)], 'P')
    c.poly([(CX - r * 2, 46), (CX, 43), (CX + r * 2, 46), (CX, 49)], 'P')
    c.ellipse(CX, 46, 3, 3, 'W')
    c.ring(CX, 46, r + 4, r + 4, 'V', 1)
    E.sparkles(c, t, 22)
    return c


def spread(t):
    """Ranged spread: a fan of orbs from the trident."""
    c = herald(pose(t=t, staff='thrust' if t < 4 else 'hold', glow=t == 2, orb_spin=t * 0.4))
    tx, ty = CX + 44, 26
    if t == 1:
        E.void_orb(c, tx + 2, ty - 1, 2.4)
    if t in (2, 3):
        d = 6 if t == 2 else 12
        for k in range(5):
            a = (k - 2) * 0.35
            E.void_orb(c, tx - 2 + math.cos(a) * d, ty - 1 + math.sin(a) * d * 1.6, 1.8)
    return c


def explode(t):
    """Void explosion: it plants the trident and a ring of the deep bursts out, crystals with it."""
    c = VCanvas()
    if t >= 2:
        rr = [0, 0, 18, 32, 42][t]
        E.ground_ring(c, CX, FOOT, rr, rr * 0.2 + 2, rot=t * 0.4)
        for k in range(10):
            a = k * math.pi / 5 + 0.2
            x, y = CX + math.cos(a) * rr * 0.8, FOOT + math.sin(a) * (rr * 0.16 + 1)
            c.poly([(x - 1.5, y), (x, y - 5 - (k % 3) * 2), (x + 1.5, y)], 'P')
    merge(c, herald(pose(t=t, staff='plant' if t in (1, 2, 3) else 'hold', arm='out' if t in (2, 3) else 'rest', glow=t >= 1,
                        eye='W' if t in (2, 3) else 'P', orb_r=1.0 + (0.3 if t in (2, 3) else 0))))
    return c


def gravity(t):
    """Gravity pull: rings spiral in round its feet and the orbs are drawn close."""
    c = VCanvas()
    for k in range(3):
        rr = (34 - k * 9) - t * 3
        if rr > 4:
            c.ring(CX, FOOT - 2, rr, rr * 0.28, 'P' if k == 0 else 'V', 1)
    merge(c, herald(pose(t=t, arm='in' if t in (1, 2, 3) else 'rest', glow=True, orb_r=1.0 - t * 0.14, orb_spin=t * 0.7)))
    for i in range(16):
        a = i * math.pi / 8 + t * 0.5
        r = 44 - ((i * 7 + t * 9) % 30)
        x, y = CX + math.cos(a) * r, 46 + math.sin(a) * r * 0.8
        if c.get(x, y) == '.':
            c.put(x, y, 'p')
    return c


def rift(t):
    """Phase 2: a column of the deep tears open beside it."""
    c = herald(pose(t=t, wild=2.0, arm='out' if 0 < t < 4 else 'rest', staff='raise' if 0 < t < 4 else 'hold', eye='W', glow=True))
    sizes = [0, 4, 10, 14, 6]
    if sizes[t]:
        E.rift_shape(c, CX - 32, 50, sizes[t] * 0.7, sizes[t] * 2.2)
    return c


def death(t):
    """It shudders, its eye goes dark, the tentacles drag it down and the deep closes over it."""
    if t <= 2:
        c = herald(pose(t=t, wild=2.2 - t * 0.4, eye=['W', 'P', 'V'][t], by=t * 3, shrink=t * 3, staff='hold' if t < 2 else 'none'))
        for i in range(4 + t * 4):
            hv = h32(i, t, 9)
            x, y = 30 + hv % 32, 20 + (hv >> 6) % 50
            c.line(x, y, x + (hv >> 3) % 5 - 2, y + 4, 'p')
        return c
    if t <= 4:
        return E.dissolve(herald(pose(t=t, by=8 + (t - 3) * 6, shrink=8, eye='V', wild=0.6, staff='none')), [0, 0, 0, 0.5, 0.25][t])
    c = VCanvas()
    if t == 5:
        E.void_orb(c, CX, 52, 6, bright=True)
        E.sparkles(c, t, 24)
    else:
        E.void_orb(c, CX, 52, 2)
        E.sparkles(c, t, 10)
    return c


# ------------------------------------------------------------------ its minion
def spawn_body(c, x, y, s, t):
    """A little squid of the deep: a hooded bell with one cyan eye, tentacles trailing."""
    if s <= 0:
        return
    r = 5 * s
    c.ellipse(x, y - r * 0.6, r, r * 0.9, 'T')
    for k in (-2, -1, 0, 1, 2):
        c.line(x + k * r * 0.35, y, x + k * r * 0.45 + math.sin(t + k) * 1.2, y + r * 1.2, 'T', 1.2)
    c.shade('T', 't', 'u')
    c.put(x, y - r * 0.6, 'P'); c.put(x, y - r * 0.6 - 1, 'p')


def abyss_spawn(t):
    c = Canvas(16, 18)
    x, y = 8, 9 + (1 if t else 0)
    c.ellipse(x, y - 3, 5, 4.6, 'T')
    for k in (-2, -1, 0, 1, 2):
        c.line(x + k * 1.6, y + 1, x + k * 2.1 + (1 if (t + k) % 2 else -1), y + 7, 'T', 1.2)
    c.shade('T', 't', 'u')
    c.put(x - 1, y - 3, 'P'); c.put(x + 1, y - 3, 'P'); c.put(x, y - 5, 'p')
    for k in (-1, 1):
        c.put(x + k * 3, y + 6, 'P')
    return c


SEQ = [
    ('idle', idle, 4), ('move', move, 6), ('barrage', barrage, 6), ('rain', rain, 5), ('summon', summon, 5), ('slam', slam, 5),
    ('teleport', teleport, 6), ('spread', spread, 5), ('explode', explode, 5), ('gravity', gravity, 5), ('rift', rift, 5), ('death', death, 7),
]


def sequences():
    out = []
    for name, fn, n in SEQ:
        out.append(('abyss_herald_' + name, [fn(t).rows() for t in range(n)], PAL, 4))
    out.append(('abyss_herald_ridle', [E.flames(herald(pose(t=t, by=[0, 1, 1, 0][t], wild=2.0, eye='W', glow=True)), t).rows() for t in range(4)], PAL, 4))
    out.append(('abyss_herald_rmove', [E.flames(herald(pose(t=t + 0.5, by=[0, 1, 2, 1, 0, -1][t], bx=1, wild=2.2, eye='W', glow=True)), t + 9).rows() for t in range(6)], PAL, 4))
    out.append(('abyss_herald', [idle(0).rows(), idle(2).rows(), move(0).rows(), move(3).rows(), barrage(2).rows(), barrage(3).rows()], PAL, 4))
    out.append(('abyss_spawn', [abyss_spawn(0).rows(), abyss_spawn(1).rows()], PAL, 4))
    return out
