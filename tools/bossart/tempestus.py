"""
Tempestus, Heart of the Storm, after the design sheet ("The storm is not a
force, it is my heart."): a tall hooded storm-lord in a long navy cloak trimmed
with violet, spiked silver-lavender pauldrons, a single burning eye in the dark
of the hood and a great ring of storm-light behind the head, crackling.

Like the Dark Elder (elder.py, whose drawing tools it borrows) it has an
animation for each of its attacks: void slash, spread, heavy lightning strike,
dash and teleport, the storm's radius, divine storm rain, its guard when it
shields itself, and its death.
"""
import math
import elder as E
from elder import VCanvas, W, H, CX, FOOT, h32

PAL = {
    # the cloak (base, light, dark)
    'K': 0x1c1c4a, 'k': 0x34348e, 'n': 0x0a0a22,
    # its inner lining
    'T': 0x3a2070, 't': 0x6440b4, 'u': 0x180c34,
    # silver-lavender plate
    'S': 0x8a88c8, 's': 0xd4d2fa, 'z': 0x3a3872,
    # storm-light: violet, pale, electric blue, white
    'P': 0xa060ff, 'p': 0xe2ccff, 'V': 0x4048e0, 'W': 0xffffff,
    # the dark of the hood
    'X': 0x04020c,
    # enraged storm-fire
    'F': 0x8070ff, 'f': 0xe0e0ff,
}


def pose(**k):
    p = dict(t=0, bx=0, by=0, lean=0, stride=0, arm='rest', arm2='rest', eye='P', glow=False, halo=1.0, crouch=0, blow=0)
    p.update(k)
    return p


def bolt(c, x0, y0, x1, y1, seed, col='P', core='W', width=1.4, jag=3.0):
    """A jagged bolt of lightning from (x0, y0) to (x1, y1)."""
    n = max(4, int(math.hypot(x1 - x0, y1 - y0) / 4))
    pts = [(x0, y0)]
    for i in range(1, n):
        f = i / n
        hv = h32(seed, i)
        off = ((hv % 1000) / 1000 - 0.5) * 2 * jag
        px, py = -(y1 - y0), x1 - x0
        L = math.hypot(px, py) or 1
        pts.append((x0 + (x1 - x0) * f + px / L * off, y0 + (y1 - y0) * f + py / L * off))
    pts.append((x1, y1))
    for (a, b) in zip(pts, pts[1:]):
        c.line(a[0], a[1], b[0], b[1], col, width + 1)
    for (a, b) in zip(pts, pts[1:]):
        c.line(a[0], a[1], b[0], b[1], core)


# ------------------------------------------------------------------ the parts
def halo(c, p):
    """The ring of storm-light behind its head, spiked, a star at its top."""
    bx, by = CX + p['bx'] + p['lean'], p['by'] + p['crouch']
    r = 14 * p['halo']
    cy = 14 + by
    c.ring(bx, cy, r, r, 'V', 1.6)
    c.ring(bx, cy, r - 1, r - 1, 'P', 1)
    for k in range(8):
        a = k * math.pi / 4 + p['t'] * 0.1
        ln = 5 if k % 2 == 0 else 3
        c.line(bx + math.cos(a) * r, cy + math.sin(a) * r, bx + math.cos(a) * (r + ln), cy + math.sin(a) * (r + ln), 'P')
    # the star at its crown
    c.poly([(bx, cy - r - 9), (bx + 2, cy - r - 2), (bx, cy - r + 1), (bx - 2, cy - r - 2)], 'p')
    c.put(bx, cy - r - 3, 'W')
    if p['glow']:
        c.ring(bx, cy, r + 3, r + 3, 'p', 1)


def cloak(c, p):
    bx, by = CX + p['bx'], p['by'] + p['crouch']
    t, bl, ln = p['t'], p['blow'], p['lean']
    hem = FOOT - 1
    # the long cloak behind it, streaming back when it moves
    pts = [(bx - 10 + ln, 24 + by), (bx + 10 + ln, 24 + by), (bx + 18 - bl, hem - 6), (bx + 14 + math.sin(t) * 2 - bl * 2, hem),
           (bx + 7 - bl, hem - 4), (bx + 2 - bl, hem + 1), (bx - 4 - bl * 2, hem - 4), (bx - 10 - bl * 3, hem + 1),
           (bx - 16 + math.sin(t + 1) * 2 - bl * 4, hem - 2), (bx - 19 - bl * 3, hem - 9)]
    c.poly(pts, 'K')
    for dx in (-12, -6, 6, 12):
        c.line(bx + dx * 0.5 + ln, 34 + by, bx + dx - bl * 2, hem - 5, 'n')
    c.shade('K', 'k', 'n')
    # violet trim down the edges
    c.line(bx - 9 + ln, 26 + by, bx - 17 - bl * 3, hem - 8, 'P')
    c.line(bx + 9 + ln, 26 + by, bx + 17 - bl, hem - 7, 'P')


def body(c, p):
    bx, by, ln, s = CX + p['bx'], p['by'] + p['crouch'], p['lean'], p['stride']
    # armoured legs between the cloak's halves
    for side, dx in ((-1, -s), (1, s)):
        lx = bx + side * 4 + dx
        c.poly([(lx - 2.5, 50 + by), (lx + 2.5, 50 + by), (lx + 2 + side, FOOT - 3), (lx - 2 + side, FOOT - 3)], 'S')
        c.rect(lx - 3 + side, FOOT - 3, lx + 3 + side, FOOT - 1, 'z')
    c.shade('S', 's', 'z')
    # the inner robe: violet lining and a glowing seam
    c.poly([(bx - 7 + ln, 26 + by), (bx + 7 + ln, 26 + by), (bx + 6, 52 + by), (bx - 6, 52 + by)], 'T')
    c.shade('T', 't', 'u')
    c.line(bx + ln, 30 + by, bx, 52 + by, 'P')
    c.poly([(bx + ln, 34 + by), (bx + 2 + ln, 38 + by), (bx + ln, 42 + by), (bx - 2 + ln, 38 + by)], 'p')
    # a belt of plate
    c.rect(bx - 7, 44 + by, bx + 7, 46 + by, 'S')
    c.put(bx, 45 + by, 'P')


def pauldrons(c, p):
    bx, by, ln = CX + p['bx'] + p['lean'], p['by'] + p['crouch'], p['lean']
    for sgn in (-1, 1):
        c.poly([(bx + sgn * 6, 23 + by), (bx + sgn * 17, 25 + by), (bx + sgn * 14, 32 + by), (bx + sgn * 7, 31 + by)], 'S')
        # spikes sweeping up and out
        c.poly([(bx + sgn * 12, 25 + by), (bx + sgn * 21, 13 + by), (bx + sgn * 16, 25 + by)], 'S')
        c.poly([(bx + sgn * 8, 24 + by), (bx + sgn * 12, 16 + by), (bx + sgn * 11, 24 + by)], 'S')
        c.put(bx + sgn * 21, 13 + by, 'p')
        c.line(bx + sgn * 8, 28 + by, bx + sgn * 15, 29 + by, 'P')
    c.shade('S', 's', 'z')


def hood(c, p):
    bx, by = CX + p['bx'] + p['lean'], p['by'] + p['crouch']
    c.poly([(bx, 4 + by), (bx + 7, 11 + by), (bx + 8, 21 + by), (bx + 5, 27 + by), (bx - 5, 27 + by), (bx - 8, 21 + by), (bx - 7, 11 + by)], 'K')
    c.shade('K', 'k', 'n')
    c.line(bx - 7, 11 + by, bx, 4 + by, 's')
    c.line(bx, 4 + by, bx + 7, 11 + by, 'S')
    c.poly([(bx, 10 + by), (bx + 5, 16 + by), (bx + 4, 25 + by), (bx - 4, 25 + by), (bx - 5, 16 + by)], 'X')
    # the single burning eye
    eye = p['eye']
    c.ellipse(bx, 17 + by, 2.4, 2.4, eye)
    c.ellipse(bx, 17 + by, 1.2, 1.2, 'p' if eye != 'V' else 'V')
    if eye != 'V':
        c.put(bx, 17 + by, 'W')


def arm(c, p, side, mode):
    """An arm in its sleeve, a gauntlet crackling at the end."""
    if mode == 'rest':
        return None
    bx, by, ln = CX + p['bx'] + p['lean'], p['by'] + p['crouch'], p['lean']
    ends = {
        'forward': (bx + side * 26, 32 + by), 'back': (bx - side * 6, 40 + by), 'up': (bx + side * 16, 2 + by),
        'out': (bx + side * 28, 26 + by), 'down': (bx + side * 20, 54 + by), 'high': (bx + side * 22, 10 + by),
    }
    hx, hy = ends[mode]
    c.line(bx + side * 11, 28 + by, hx, hy, 'K', 4.5)
    c.shade('K', 'k', 'n')
    c.ellipse(hx, hy, 2.4, 2.4, 'S')
    c.put(hx, hy, 'p' if p['glow'] else 'P')
    return hx, hy


def sparks(c, t, n=8):
    for i in range(n):
        hv = h32(i, t, 31)
        x, y = 6 + hv % (W - 12), 2 + (hv >> 8) % 80
        if c.get(x, y) == '.' and c.get(x + 1, y) == '.':
            c.put(x, y, 'p')
            c.put(x + (1 if hv & 1 else -1), y + 1, 'P')


def tempest(p):
    c = VCanvas()
    halo(c, p)
    cloak(c, p)
    body(c, p)
    pauldrons(c, p)
    hood(c, p)
    hands = [arm(c, p, 1, p['arm']), arm(c, p, -1, p['arm2'])]
    c.hands = hands
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
    c = tempest(pose(t=t, by=b, halo=1.0 + (0.04 if t in (1, 2) else 0)))
    sparks(c, t, 7)
    return c


def move(t):
    b = [0, 1, 0, 0, 1, 0][t]
    s = [-2, -1, 1, 2, 1, -1][t]
    c = tempest(pose(t=t + 0.5, by=b, lean=2, stride=s, blow=1))
    for i in range(5):
        hv = h32(i, t, 7)
        y = 30 + hv % 44
        c.line(2 + (hv >> 6) % 8, y, 12 + (hv >> 9) % 8, y, 'V')
    return c


def slash(t):
    """Void slash: the arm drawn back, a sweep, and a crescent of storm-light left hanging."""
    modes = ['back', 'back', 'high', 'forward', 'forward', 'rest']
    c = tempest(pose(t=t, lean=[-1, -2, 0, 3, 3, 1][t], arm=modes[t], glow=t in (2, 3)))
    if t in (3, 4):
        # the crescent: thick in the middle, a white edge on its outside
        w = 8 if t == 3 else 4
        for i in range(120):
            f = i / 119
            a = -1.9 + f * 2.6
            wdt = w * math.sin(f * math.pi)
            for k in range(int(wdt * 2) + 1):
                rr = 30 - k * 0.5
                ch = 'W' if k <= 1 and wdt > 2 else ('P' if t == 3 else 'V')
                c.put(CX + 14 + math.cos(a) * rr, 38 + math.sin(a) * rr, ch)
    return c


def spread(t):
    """Ranged spread: orbs gather at the gauntlet and fan out."""
    c = tempest(pose(t=t, arm='forward' if t < 4 else 'rest', glow=t == 2))
    hx, hy = CX + 26, 32
    if t == 1:
        E.void_orb(c, hx + 3, hy - 2, 2.5)
    if t in (2, 3):
        d = 6 if t == 2 else 12
        for k in range(5):
            a = (k - 2) * 0.35
            E.void_orb(c, hx + 2 + math.cos(a) * d, hy - 2 + math.sin(a) * d * 1.6, 1.8)
    return c


def strike(t):
    """Heavy lightning strike: it raises its hand, the storm gathers, and a bolt falls."""
    c = tempest(pose(t=t, arm='up' if t in (1, 2, 3) else 'forward' if t == 4 else 'rest', glow=t >= 1, eye='W' if t in (3, 4) else 'P'))
    if t in (1, 2):
        E.void_orb(c, CX + 16, -2, 2 + t * 1.5, bright=t == 2)
    if t in (3, 4):
        x = 76 if t == 3 else 78
        bolt(c, x, -5, x - 2, FOOT, t * 7, 'P', 'W', 2 if t == 3 else 1.2, 4)
        bolt(c, x + 1, 20, x + 9, 34, t * 11, 'V', 'p', 0.6, 2)
        E.ground_ring(c, x, FOOT, 10, 2.4, runes=False)
    if t == 5:
        for i in range(6):
            c.put(70 + i * 3, FOOT - (i % 3), 'p')
    return c


def dash(t):
    """Dash and teleport: it streaks forward, steps into a ring of light, and streaks out."""
    if t == 4:
        c = VCanvas()
        c.ring(CX, 46, 10, 22, 'P', 1.6)
        c.ring(CX, 46, 7, 18, 'V', 1)
        c.ellipse(CX, 46, 3, 12, 'p')
        E.sparkles(c, t, 16)
        return c
    c = tempest(pose(t=t, lean=5, bx=4, stride=[-2, 2, -2, 2, 0, 2][t], blow=3, arm='forward', glow=True))
    for i in range(11):
        hv = h32(t, i, 13)
        y = 12 + hv % 64
        x = (hv >> 8) % 18
        c.line(x, y, x + 10 + (hv >> 4) % 10, y, 'P' if i % 3 else 'W')
    return c


def radius(t):
    """The storm's radius: it gathers itself, a rune circle blazes, and lightning bursts up all round."""
    c = VCanvas()
    if t >= 1:
        rr = [0, 22, 30, 36, 40, 26][t]
        E.ground_ring(c, CX, FOOT, rr, rr * 0.2 + 2, rot=t * 0.3)
    merge(c, tempest(pose(t=t, crouch=3 if t in (1, 2) else 0, arm='down' if t in (1, 2) else 'out' if t in (3, 4) else 'rest',
                          arm2='down' if t in (1, 2) else 'out' if t in (3, 4) else 'rest', glow=t >= 2, eye='W' if t in (3, 4) else 'P')))
    if t in (3, 4):
        for k in range(10):
            a = k * math.pi / 5 + 0.3
            x = CX + math.cos(a) * 34
            y = FOOT + math.sin(a) * 6
            bolt(c, x, y - (14 if t == 3 else 22), x + 1, y, k + t * 17, 'P', 'W', 0.8, 2)
    return c


def rain(t):
    """Divine storm rain: both arms raised, columns of lightning fall all round it."""
    c = tempest(pose(t=t, arm='high' if 0 < t < 5 else 'rest', arm2='high' if 0 < t < 5 else 'rest', glow=t >= 2, eye='W' if t >= 3 else 'P'))
    if t >= 1:
        n = [0, 2, 4, 6, 8, 4][t]
        for k in range(n):
            x = [10, 82, 22, 70, 4, 88, 32, 60][k]
            top = 6 + (k % 3) * 6
            E.pillar(c, x, top, FOOT, 2 if t < 4 else 3)
    if t == 4:
        E.ground_ring(c, CX, FOOT, 42, 7, rot=0.4)
    return c


def guard(t):
    """Guard: it draws the storm round itself in a shell of light."""
    c = tempest(pose(t=t, arm='back', arm2='back', glow=True, crouch=1))
    r = [26, 30, 30, 27][t]
    c.ring(CX, 44, r, r * 1.15, 'P', 1.4)
    c.ring(CX, 44, r - 2, r * 1.15 - 2, 'V', 1)
    for k in range(8):
        a = k * math.pi / 4 + t * 0.4
        c.put(CX + math.cos(a) * r, 44 + math.sin(a) * r * 1.15, 'W')
    return c


def death(t):
    """It staggers, the halo breaks, it falls to its knees and comes apart into sparks."""
    if t <= 2:
        c = tempest(pose(t=t, by=t * 3, crouch=t * 4, halo=1.0 - t * 0.15, eye=['W', 'P', 'V'][t], arm='down', arm2='down'))
        for i in range(4 + t * 3):
            hv = h32(i, t, 3)
            x, y = 28 + hv % 36, 16 + (hv >> 6) % 50
            bolt(c, x, y, x + (hv >> 3) % 7 - 3, y + 6, hv, 'P', 'p', 0.4, 1)
        return c
    if t <= 4:
        return E.dissolve(tempest(pose(t=t, by=10, crouch=10, halo=0.6, eye='V', arm='down', arm2='down')), [0, 0, 0, 0.5, 0.22][t])
    c = VCanvas()
    if t == 5:
        E.void_orb(c, CX, 56, 5, bright=True)
        E.sparkles(c, t, 26)
    else:
        E.sparkles(c, t, 12)
    return c


SEQ = [
    ('idle', idle, 4), ('move', move, 6), ('slash', slash, 6), ('spread', spread, 5), ('strike', strike, 6), ('dash', dash, 6),
    ('radius', radius, 6), ('rain', rain, 6), ('guard', guard, 4), ('death', death, 7),
]


def sequences():
    out = []
    for name, fn, n in SEQ:
        out.append(('tempestus_' + name, [fn(t).rows() for t in range(n)], PAL, 4))
    out.append(('tempestus_ridle', [E.flames(tempest(pose(t=t, by=[0, 1, 1, 0][t], eye='W', glow=True, halo=1.08)), t).rows() for t in range(4)], PAL, 4))
    out.append(('tempestus_rmove', [E.flames(tempest(pose(t=t + 0.5, by=[0, 1, 0, 0, 1, 0][t], lean=2, stride=[-2, -1, 1, 2, 1, -1][t], blow=1, eye='W', glow=True)), t + 9).rows() for t in range(6)], PAL, 4))
    out.append(('tempestus', [idle(0).rows(), idle(2).rows(), move(0).rows(), move(3).rows(), strike(2).rows(), strike(3).rows()], PAL, 4))
    return out
