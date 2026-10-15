"""
Archon Vesper, Architect of Void-Time, after the design sheet ("My designs
encompass eternity; your fate is a mere footnote."): a knight in crimson plate
edged with gold, a tall horned helm with a burning visor, great crimson wings
of feathers swept up behind him, a long cape, a red gem burning in his chest,
and his void-lance: a golden spear whose head is a twisted spiral of red light.
He guards behind a tall crimson kite shield.

Like Tempestus (tempestus.py) he borrows the Dark Elder's drawing tools and has
an animation for each of his attacks: the void-lance strike, his ranged orbs,
the gravity well, the void dash, the temporal cascade, the blood brand, his
summoning of the Conclave, his guard and his death.

python3 tools/bossart/vesper.py out.png draws a contact sheet of every animation.
"""
import math
import sys
import elder as E
from elder import VCanvas, W, H, CX, FOOT, h32

PAL = {
    # crimson plate (base, light, dark)
    'K': 0x8c1424, 'k': 0xd03448, 'n': 0x3a0610,
    # the cape: a deep crimson (its own, so the plate stands out against it)
    'R': 0x4e0814, 'r': 0x80142a, 'y': 0x22030a,
    # cloth: the tabard and the wings' feathers
    'C': 0x9a1428, 'c': 0xe04058, 'd': 0x4a0812,
    # gold
    'G': 0xd8a838, 'g': 0xffe490, 'o': 0x6e4c12,
    # dark steel under the plate
    'M': 0x3e2a32, 'm': 0x6e5260, 'q': 0x1a0e14,
    # the void's red light (the Elder's tools draw with these letters)
    'P': 0xff2a3a, 'p': 0xffa8b0, 'V': 0x8a0818, 'W': 0xfff2ea,
    'X': 0x140004,
    # enraged fire
    'F': 0xff3a48, 'f': 0xffd8d0,
}


def pose(**k):
    p = dict(t=0, bx=0, by=0, lean=0, stride=0, lance='rest', hand='rest', eye='P', glow=False,
             wings=1.0, flap=0.0, crouch=0, blow=0, shield=False, gem='P')
    p.update(k)
    return p


# ------------------------------------------------------------------ the parts
def feather(c, x0, y0, ang, ln, wd, col, tip=None):
    ex, ey = x0 + math.cos(ang) * ln, y0 + math.sin(ang) * ln
    px, py = -math.sin(ang) * wd, math.cos(ang) * wd
    c.poly([(x0 - px * 0.5, y0 - py * 0.5), (x0 + px * 0.5, y0 + py * 0.5), (ex + px * 0.35 + math.cos(ang) * -2, ey + py * 0.35 + math.sin(ang) * -2),
            (ex, ey), (ex - px * 0.35 + math.cos(ang) * -2, ey - py * 0.35 + math.sin(ang) * -2)], col)
    if tip:
        c.put(ex, ey, tip)


def wings(c, p):
    """Great feathered wings swept up behind him: long primaries fanning up and out, coverts layered over them."""
    s = p['wings']
    if s <= 0:
        return
    bx, by, fl = CX + p['bx'] + p['lean'], p['by'] + p['crouch'], p['flap']
    for sgn in (-1, 1):
        sx, sy = bx + sgn * 7, 27 + by
        # primaries: from nearly straight up to out and down
        for k in range(8):
            f = k / 7
            a = -math.pi / 2 + sgn * (0.22 + f * 1.15 - fl * 0.25 * (1 - f))
            ln = (46 - f * 16) * s
            feather(c, sx + sgn * f * 3, sy - 2 + f * 5, a, ln, 5.5, 'C', 'G' if k < 5 else None)
        # coverts: shorter, brighter, over the bases
        for k in range(6):
            f = k / 5
            a = -math.pi / 2 + sgn * (0.4 + f * 1.05 - fl * 0.2)
            feather(c, sx, sy, a, (22 - f * 6) * s, 5, 'c')
    c.shade('C', 'c', 'd')
    # the spines of the feathers
    for sgn in (-1, 1):
        sx, sy = bx + sgn * 7, 27 + by
        for k in range(0, 8, 2):
            f = k / 7
            a = -math.pi / 2 + sgn * (0.22 + f * 1.15 - fl * 0.25 * (1 - f))
            ln = (42 - f * 16) * s
            c.line(sx + sgn * f * 3, sy - 2 + f * 5, sx + sgn * f * 3 + math.cos(a) * ln, sy - 2 + f * 5 + math.sin(a) * ln, 'd')


def cape(c, p):
    bx, by, bl, t = CX + p['bx'], p['by'] + p['crouch'], p['blow'], p['t']
    hem = FOOT
    c.poly([(bx - 10 + p['lean'], 26 + by), (bx + 10 + p['lean'], 26 + by), (bx + 15 - bl, hem - 6), (bx + 12 + math.sin(t) * 2 - bl * 2, hem),
            (bx + 4 - bl * 2, hem - 3), (bx - 5 - bl * 3, hem + 1), (bx - 13 + math.sin(t + 1) * 2 - bl * 4, hem - 2), (bx - 16 - bl * 3, hem - 8)], 'R')
    for dx in (-10, -4, 5, 11):
        c.line(bx + dx * 0.5, 34 + by, bx + dx - bl * 2, hem - 4, 'y')
    c.shade('R', 'r', 'y')


def legs(c, p):
    bx, by, s = CX + p['bx'], p['by'] + p['crouch'], p['stride']
    for side, dx in ((-1, -s), (1, s)):
        lx = bx + side * 5 + dx
        c.poly([(lx - 3, 54 + by), (lx + 3, 54 + by), (lx + 2.5 + side * 0.5, FOOT - 3), (lx - 2.5 + side * 0.5, FOOT - 3)], 'M')
        # crimson greaves, a gold knee and a pointed sabaton
        c.poly([(lx - 3.5, 63 + by), (lx + 3.5, 63 + by), (lx + 3 + side * 0.5, FOOT - 4), (lx - 3 + side * 0.5, FOOT - 4)], 'K')
        c.line(lx - 3, 70 + by, lx + 3, 70 + by, 'G')
        c.ellipse(lx, 62 + by, 2.6, 2, 'G')
        c.poly([(lx - 3 + side, FOOT - 4), (lx + 3 + side, FOOT - 4), (lx + 3 + side * 4, FOOT - 1), (lx - 3 + side, FOOT - 1)], 'G')
    c.shade('M', 'm', 'q')
    c.shade('K', 'k', 'n')


def body(c, p):
    bx, by, ln = CX + p['bx'], p['by'] + p['crouch'], p['lean']
    # the tabard: a crimson panel hanging between the legs, gold-edged
    c.poly([(bx - 4 + ln, 48 + by), (bx + 4 + ln, 48 + by), (bx + 4 - p['blow'], 72 + by), (bx, 76 + by), (bx - 4 - p['blow'], 72 + by)], 'C')
    c.shade('C', 'c', 'd')
    c.line(bx - 4 + ln, 48 + by, bx - 4 - p['blow'], 72 + by, 'G')
    c.line(bx + 4 + ln, 48 + by, bx + 4 - p['blow'], 72 + by, 'G')
    c.poly([(bx - 2, 58 + by), (bx + 2, 58 + by), (bx, 63 + by)], 'G')
    # faulds: plates over the hips
    c.poly([(bx - 11 + ln, 46 + by), (bx + 11 + ln, 46 + by), (bx + 13, 55 + by), (bx - 13, 55 + by)], 'K')
    c.line(bx - 13, 55 + by, bx + 13, 55 + by, 'G')
    c.line(bx - 12, 51 + by, bx + 12, 51 + by, 'n')
    # the breastplate, waisted, a burning gem set in it
    c.poly([(bx - 11 + ln, 27 + by), (bx + 11 + ln, 27 + by), (bx + 10 + ln, 38 + by), (bx + 7 + ln, 46 + by), (bx - 7 + ln, 46 + by), (bx - 10 + ln, 38 + by)], 'K')
    c.shade('K', 'k', 'n')
    c.line(bx - 10 + ln, 38 + by, bx + ln, 44 + by, 'G')
    c.line(bx + 10 + ln, 38 + by, bx + ln, 44 + by, 'G')
    c.line(bx + ln, 28 + by, bx + ln, 33 + by, 'G')
    gx, gy = bx + ln, 36 + by
    c.ellipse(gx, gy, 3.6, 3.6, 'G')
    c.ellipse(gx, gy, 2.4, 2.4, p['gem'])
    c.put(gx - 1, gy - 1, 'W')
    c.rect(bx - 9 + ln, 45 + by, bx + 9 + ln, 46 + by, 'G')


def pauldrons(c, p):
    bx, by = CX + p['bx'] + p['lean'], p['by'] + p['crouch']
    for sgn in (-1, 1):
        # three layered plates, each gold-rimmed, the top one sweeping up into a point
        for k, (w, y) in enumerate(((10, 31), (11, 28), (12, 25))):
            c.poly([(bx + sgn * 7, y - 2 + by), (bx + sgn * (7 + w), y - 1 + by), (bx + sgn * (8 + w), y + 3 + by), (bx + sgn * 8, y + 4 + by)], 'K')
        c.poly([(bx + sgn * 14, 23 + by), (bx + sgn * 22, 14 + by), (bx + sgn * 19, 25 + by)], 'K')
        c.shade('K', 'k', 'n')
        for y in (27, 30, 34):
            c.line(bx + sgn * 8, y + by, bx + sgn * 19, y + 1 + by, 'G')
        c.put(bx + sgn * 22, 14 + by, 'g')


def helm(c, p):
    bx, by = CX + p['bx'] + p['lean'], p['by'] + p['crouch']
    # horns sweeping up and out, and a blade of a crest between them
    for sgn in (-1, 1):
        c.poly([(bx + sgn * 4, 12 + by), (bx + sgn * 8, 7 + by), (bx + sgn * 15, -5 + by), (bx + sgn * 11, 9 + by), (bx + sgn * 6, 15 + by)], 'G')
        c.poly([(bx + sgn * 6, 16 + by), (bx + sgn * 10, 14 + by), (bx + sgn * 14, 8 + by), (bx + sgn * 11, 17 + by)], 'G')
    c.poly([(bx - 2, 9 + by), (bx, -6 + by), (bx + 2, 9 + by)], 'G')
    c.shade('G', 'g', 'o')
    # the helm itself
    c.poly([(bx - 6, 8 + by), (bx + 6, 8 + by), (bx + 8, 14 + by), (bx + 7, 23 + by), (bx + 3, 26 + by), (bx - 3, 26 + by), (bx - 7, 23 + by), (bx - 8, 14 + by)], 'K')
    c.shade('K', 'k', 'n')
    c.poly([(bx - 7, 18 + by), (bx - 3, 19 + by), (bx - 3, 25 + by), (bx - 6, 23 + by)], 'M')
    c.poly([(bx + 7, 18 + by), (bx + 3, 19 + by), (bx + 3, 25 + by), (bx + 6, 23 + by)], 'M')
    c.line(bx - 6, 8 + by, bx - 8, 14 + by, 'G')
    c.line(bx + 6, 8 + by, bx + 8, 14 + by, 'G')
    c.line(bx, 9 + by, bx, 14 + by, 'G')
    # the visor: a T of burning light
    eye = p['eye']
    c.rect(bx - 5, 16 + by, bx + 5, 17 + by, 'X')
    c.rect(bx - 1, 17 + by, bx + 1, 23 + by, 'X')
    c.line(bx - 4, 16 + by, bx + 4, 16 + by, eye)
    c.put(bx, 18 + by, eye)
    # a gold gorget
    c.poly([(bx - 7, 24 + by), (bx + 7, 24 + by), (bx + 6, 28 + by), (bx - 6, 28 + by)], 'G')
    c.shade('G', 'g', 'o')


def lance_at(c, x0, y0, ang, ln, glow=False):
    """The void-lance held at (x0, y0) pointing at ang: a gold shaft with a ring near its head and a twisted spiral point."""
    ca, sa = math.cos(ang), math.sin(ang)
    bxx, byy = x0 - ca * ln * 0.3, y0 - sa * ln * 0.3
    hx, hy = x0 + ca * ln * 0.7, y0 + sa * ln * 0.7
    c.line(bxx, byy, hx, hy, 'G', 2)
    c.line(bxx, byy, hx, hy, 'o')
    c.put(bxx - ca, byy - sa, 'g')
    # the ring and its prongs
    rx, ry = hx - ca * 2, hy - sa * 2
    c.ring(rx, ry, 3.2, 3.2, 'G', 1)
    for k in (-1, 1):
        c.line(rx, ry, rx + ca * 4 - sa * 4 * k, ry + sa * 4 + ca * 4 * k, 'G')
    # the spiral head: crimson twisted with light, coming to a point
    L = 13
    for i in range(L * 3):
        f = i / (L * 3)
        w = 2.6 * (1 - f)
        tw = math.sin(f * 18)
        x, y = hx + ca * f * L, hy + sa * f * L
        c.put(x - sa * w * tw, y + ca * w * tw, 'P')
        c.put(x + sa * w * tw, y - ca * w * tw, 'V')
    c.line(hx, hy, hx + ca * L, hy + sa * L, 'p' if not glow else 'W')
    tip = (hx + ca * (L + 2), hy + sa * (L + 2))
    c.put(tip[0], tip[1], 'W')
    if glow:
        c.ring(hx + ca * L * 0.5, hy + sa * L * 0.5, 9, 9, 'p', 1)
    return tip


def arms(c, p):
    bx, by = CX + p['bx'] + p['lean'], p['by'] + p['crouch']
    # the lance arm (right): hand position and lance angle for each pose
    poses = {'rest': ((bx + 16, 44), -math.pi / 2 - 0.08, 64), 'back': ((bx + 7, 38), -0.1, 50),
             'thrust': ((bx + 26, 36), 0.0, 60), 'up': ((bx + 16, 14), -math.pi / 2 + 0.25, 56), 'plant': ((bx + 16, 46), -math.pi / 2, 66),
             'high': ((bx + 18, 16), -0.6, 56), 'down': ((bx + 14, 54), 0.9, 52), 'level': ((bx + 22, 38), -0.15, 58)}
    (hx, hy), ang, ln = poses[p['lance']]
    hy += 0
    c.line(bx + 11, 30 + by, hx, hy + by, 'K', 4.5)
    c.shade('K', 'k', 'n')
    c.ellipse(hx, hy + by, 2.4, 2.4, 'G')
    tip = lance_at(c, hx, hy + by, ang, ln, p['glow'])
    # the other hand: open, a ball of red light in it when casting
    lends = {'rest': (bx - 15, 46), 'out': (bx - 26, 32), 'up': (bx - 15, 10), 'chest': (bx - 4, 38), 'point': (bx - 30, 24),
             'down': (bx - 17, 56), 'shield': (bx - 14, 40)}
    lx, ly = lends[p['hand']]
    c.line(bx - 11, 30 + by, lx, ly + by, 'K', 4.5)
    c.shade('K', 'k', 'n')
    c.ellipse(lx, ly + by, 2.4, 2.4, 'G')
    c.hands = ((hx, hy + by), (lx, ly + by), tip)


def shield(c, p):
    """The tall kite shield, held before him: crimson, gold-rimmed, a burning sigil in its middle."""
    bx, by = CX + p['bx'] + p['lean'] - 10, p['by'] + p['crouch']
    pts = [(bx - 11, 26 + by), (bx + 11, 26 + by), (bx + 11, 52 + by), (bx, 76 + by), (bx - 11, 52 + by)]
    c.poly(pts, 'K')
    c.shade('K', 'k', 'n')
    for a, b in zip(pts, pts[1:] + pts[:1]):
        c.line(a[0], a[1], b[0], b[1], 'G', 1.5)
    c.line(bx, 28 + by, bx, 72 + by, 'G')
    c.line(bx - 9, 40 + by, bx + 9, 40 + by, 'G')
    c.ellipse(bx, 40 + by, 4, 4, 'G')
    c.ellipse(bx, 40 + by, 2.6, 2.6, 'P')
    c.put(bx - 1, 39 + by, 'W')


def archon(p):
    c = VCanvas()
    wings(c, p)
    cape(c, p)
    legs(c, p)
    body(c, p)
    pauldrons(c, p)
    helm(c, p)
    arms(c, p)
    if p['shield']:
        shield(c, p)
    return c


def merge(base, top):
    for y in range(H):
        for x in range(W):
            if top.g[y][x] != '.':
                base.g[y][x] = top.g[y][x]
    return base


# ------------------------------------------------------------------ effects
def orb(c, x, y, r, bright=False):
    c.ellipse(x, y, r + 1.2, r + 1.2, 'P')
    c.ellipse(x, y, r, r, 'V')
    c.ellipse(x, y, r * 0.5, r * 0.5, 'p')
    c.put(x, y, 'W')
    if bright:
        c.ring(x, y, r + 3.2, r + 3.2, 'p', 1)


def burst_star(c, x, y, r):
    for k in range(8):
        a = k * math.pi / 4
        ln = r if k % 2 == 0 else r * 0.55
        c.line(x, y, x + math.cos(a) * ln, y + math.sin(a) * ln, 'P' if k % 2 else 'p')
    c.ellipse(x, y, 2, 2, 'W')
    c.ring(x, y, r * 0.6, r * 0.6, 'P', 1)


def crescent(c, x, y, r, w, ang, col='P', edge='W'):
    for i in range(70):
        f = i / 69
        th = ang + (f - 0.5) * 2.6
        wd = w * math.sin(f * math.pi)
        for k in range(int(wd * 2) + 1):
            rr = r - k * 0.5
            c.put(x + math.cos(th) * rr, y + math.sin(th) * rr, edge if k == 0 and wd > 1.5 else col)


def vortex(c, x, base, ht, wd, t):
    """The gravity well: a funnel of red light spinning up out of a ring on the ground."""
    E.ground_ring(c, x, base, wd + 4, (wd + 4) * 0.25, 'P', 'V', rot=t * 0.5)
    n = 7
    for k in range(n):
        f = k / (n - 1)
        y = base - f * ht
        rx = wd * (0.25 + f * 0.85)
        c.ring(x, y, rx, rx * 0.25, 'P' if k % 2 else 'V', 1.2)
        a = t * 1.3 + k * 0.9
        c.put(x + math.cos(a) * rx, y + math.sin(a) * rx * 0.25, 'W')
    c.ellipse(x, base, 2, 1, 'W')


def clock(c, x, y, r, hand):
    """A clock face of red light (the temporal cascade marks where it will fall)."""
    c.ring(x, y, r, r * 0.45, 'P', 1.2)
    c.ring(x, y, r * 0.75, r * 0.34, 'V', 1)
    for k in range(12):
        a = k * math.pi / 6
        c.put(x + math.cos(a) * r * 0.88, y + math.sin(a) * r * 0.4, 'p' if k % 3 else 'W')
    c.line(x, y, x + math.cos(hand) * r * 0.7, y + math.sin(hand) * r * 0.32, 'W')


def sigil(c, x, y, s, glow=False):
    """The blood brand: a diamond with a drop of blood inside it."""
    c.poly([(x, y - 7 * s), (x + 5 * s, y), (x, y + 7 * s), (x - 5 * s, y)], 'P')
    c.poly([(x, y - 5 * s), (x + 3.4 * s, y), (x, y + 5 * s), (x - 3.4 * s, y)], 'V')
    c.ellipse(x, y + 1 * s, 1.6 * s, 1.8 * s, 'P')
    c.put(x, y - 1.5 * s, 'P')
    if glow:
        c.ring(x, y, 9 * s, 9 * s, 'p', 1)


# ------------------------------------------------------------------ the animations
def idle(t):
    b = [0, 1, 1, 0][t]
    return archon(pose(t=t, by=b, flap=[0, 0.3, 0.5, 0.2][t], gem='P' if t % 2 == 0 else 'p'))


def move(t):
    b = [0, 1, 0, 0, 1, 0][t]
    s = [-2, -1, 1, 2, 1, -1][t]
    return archon(pose(t=t + 0.5, by=b, lean=2, stride=s, blow=1, wings=0.92, flap=[0.6, 0.2, -0.1, 0.1, 0.5, 0.8][t], lance='level'))


def lance_strike(t):
    """Void-lance strike: he draws the lance back, drives it forward, and a crescent of void-light tears off its point."""
    modes = ['back', 'back', 'level', 'thrust', 'thrust', 'rest']
    c = archon(pose(t=t, lean=[-1, -3, 0, 4, 3, 0][t], lance=modes[t], glow=t in (2, 3), stride=[0, -1, 1, 2, 2, 0][t], flap=[0, 0.5, 0.2, -0.3, -0.2, 0][t]))
    tx, ty = c.hands[2]
    if t == 3:
        crescent(c, min(tx + 4, W - 10), ty, 8, 3.2, 0, 'P', 'W')
    if t == 4:
        crescent(c, W - 9, ty, 7, 2.6, 0, 'P', 'W')
        for i in range(5):
            c.put(tx - 6 - i * 3, ty + (i % 2) * 2 - 1, 'p')
    return c


def ranged(t):
    """Ranged attack: an orb of void-light gathers at the lance's head, he looses it, and it bursts into a star."""
    c = archon(pose(t=t, lance='level' if t in (1, 2, 3) else 'rest', hand='out' if t in (2, 3, 4) else 'rest', glow=t in (1, 2)))
    tx, ty = c.hands[2]
    lx, ly = c.hands[1]
    if t == 1:
        orb(c, tx, ty, 2)
    if t == 2:
        orb(c, tx, ty, 3.2, bright=True)
        orb(c, lx - 3, ly, 1.8)
    if t == 3:
        orb(c, min(tx + 8, W - 6), ty, 2.4)
        orb(c, lx - 10, ly - 2, 2.2)
    if t == 4:
        burst_star(c, 10, 20, 8)
        burst_star(c, W - 10, 26, 7)
    return c


def gravity(t):
    """Gravity well: he plants the lance, a ring of light opens on the ground before him and a funnel spins up out of it."""
    c = VCanvas()
    if t >= 2:
        vortex(c, 16, FOOT - 1, [0, 0, 14, 30, 44, 36][t], [0, 0, 5, 8, 10, 9][t], t)
    if t == 1:
        E.ground_ring(c, CX, FOOT, 26, 4, 'P', 'V', rot=0.2)
    merge(c, archon(pose(t=t, lance='plant' if t >= 1 else 'rest', hand='out' if t >= 2 else 'rest', glow=t >= 1, crouch=2 if t == 1 else 0,
                         eye='W' if t in (3, 4) else 'P')))
    if t >= 3:
        vortex(c, 16, FOOT - 1, [0, 0, 14, 30, 44, 36][t], [0, 0, 5, 8, 10, 9][t], t)
    return c


def dash(t):
    """Void dash and teleport: he streaks forward in a trail of light, comes apart, steps through a rift and out."""
    if t == 3:
        c = VCanvas()
        # the rift: an upright oval of red light
        c.ring(CX, 48, 9, 24, 'P', 1.8)
        c.ring(CX, 48, 6, 19, 'V', 1)
        c.ellipse(CX, 48, 3, 14, 'p')
        E.sparkles(c, t, 14)
        return c
    if t == 2:
        return E.dissolve(archon(pose(t=t, lean=5, bx=4, lance='level', blow=3, wings=0.8, flap=-0.4)), 0.45)
    c = archon(pose(t=t, lean=5 if t < 5 else 2, bx=4 if t < 5 else 0, stride=[-2, 2, 0, 0, -2, 0][t], blow=3 if t < 5 else 1,
                    lance='level', wings=0.85, flap=-0.4, glow=t in (1, 4)))
    for i in range(10 if t in (0, 1, 4) else 0):
        hv = h32(t, i, 13)
        y = 10 + hv % 66
        x = (hv >> 8) % 16
        c.line(x, y, x + 9 + (hv >> 4) % 10, y, 'P' if i % 3 else 'W')
    return c


def cascade(t):
    """Temporal cascade: he raises the lance, clock faces of light open on the ground all round, and columns fall on them."""
    c = VCanvas()
    spots = [(12, FOOT - 3), (80, FOOT - 3), (26, FOOT + 2), (66, FOOT + 2), (4, FOOT + 4), (88, FOOT + 4)]
    n = [0, 0, 2, 4, 6, 6][t]
    for k in range(n):
        x, y = spots[k]
        clock(c, x, y, 7, t * 0.9 + k)
    merge(c, archon(pose(t=t, lance='up' if t >= 1 else 'rest', hand='up' if t >= 2 else 'rest', glow=t >= 1, eye='W' if t >= 3 else 'P', flap=0.6 if t >= 2 else 0)))
    if t in (1, 2):
        # the hours turning over his head
        clock(c, CX + 18, 6, 9, t * 1.4)
    if t >= 4:
        for k in range(6 if t == 4 else 4):
            x, y = spots[k]
            E.pillar(c, x, 4 + (k % 3) * 8, y, 2 if t == 4 else 3)
    return c


def brand(t):
    """The blood brand: he points, the sigil forms in his hand and flies to its mark."""
    c = archon(pose(t=t, hand='point' if t in (2, 3, 4) else 'chest' if t == 1 else 'rest', eye='W' if t in (2, 3) else 'P',
                    glow=t in (1, 2, 3), lean=[0, 0, -2, -2, -1, 0][t]))
    lx, ly = c.hands[1]
    if t == 1:
        sigil(c, lx - 2, ly - 8, 0.6)
    if t == 2:
        sigil(c, lx - 4, ly - 10, 0.9, glow=True)
    if t == 3:
        sigil(c, 10, 12, 1.0, glow=True)
        c.line(lx - 2, ly - 2, 14, 16, 'P')
    if t == 4:
        c.ring(12, FOOT - 2, 11, 3.2, 'P', 1.4)
        c.ring(12, FOOT - 2, 7, 2, 'V', 1)
        sigil(c, 12, 40, 0.8)
    return c


def summon(t):
    """He calls the Conclave: the lance raised, rifts open at his sides and his acolytes step out of them."""
    c = archon(pose(t=t, lance='up' if t >= 1 else 'rest', hand='out' if t >= 2 else 'rest', glow=t >= 1, flap=[0, 0.4, 0.7, 0.7, 0.3][t]))
    if t >= 2:
        for x in (8, 84):
            c.ring(x, 66, 5, 16, 'P', 1.4)
            c.ellipse(x, 66, 2.5, 12, 'V')
            if t >= 3:
                ht = 14 if t == 3 else 22
                c.poly([(x - 5, FOOT), (x + 5, FOOT), (x + 4, FOOT - ht + 6), (x, FOOT - ht), (x - 4, FOOT - ht + 6)], 'M')
                c.shade('M', 'm', 'q')
                c.put(x - 1, FOOT - ht + 5, 'P')
                c.put(x + 2, FOOT - ht + 5, 'P')
    return c


def guard(t):
    """Guard and hit reaction: he braces behind his kite shield, wings drawn in, and the void flares off it."""
    c = archon(pose(t=t, shield=True, hand='shield', lance='rest', wings=0.8, flap=-0.5, crouch=[1, 2, 2, 1][t], lean=[0, -1, -1, 0][t]))
    if t in (1, 2):
        for k in range(6):
            a = -math.pi / 2 + (k - 2.5) * 0.45
            x, y = CX - 22 + math.cos(a + math.pi) * (3 + t * 3), 46 + math.sin(a) * 14
            c.put(x, y, 'p' if k % 2 else 'W')
        c.ring(CX - 10, 48, 15 + t * 2, 26 + t * 2, 'P', 1)
    return c


def death(t):
    """He falls to a knee on his lance, the void bursts out of his chest, and he comes apart into a crack of red light."""
    if t <= 2:
        c = archon(pose(t=t, by=t * 3, crouch=t * 4, wings=1 - t * 0.18, flap=-t * 0.4, eye=['W', 'P', 'V'][t], lance='plant', hand='down',
                        gem=['W', 'P', 'V'][t]))
        if t >= 1:
            burst_star(c, CX, 36 + t * 7, 6 + t * 3)
        return c
    if t <= 4:
        return E.dissolve(archon(pose(t=t, by=10, crouch=10, wings=0.6, flap=-1, eye='V', lance='plant', hand='down', gem='V')), [0, 0, 0, 0.5, 0.22][t])
    c = VCanvas()
    # a crack of red light left in the floor
    pts = [(CX - 26, FOOT), (CX - 14, FOOT - 2), (CX - 8, FOOT + 1), (CX, FOOT - 3), (CX + 9, FOOT), (CX + 16, FOOT - 2), (CX + 26, FOOT)]
    for a, b in zip(pts, pts[1:]):
        c.line(a[0], a[1], b[0], b[1], 'P', 2 if t == 5 else 1.4)
        c.line(a[0], a[1], b[0], b[1], 'W')
    if t == 5:
        E.sparkles(c, t, 22)
    else:
        E.sparkles(c, t, 8)
    return c


SEQ = [
    ('idle', idle, 4), ('move', move, 6), ('lance', lance_strike, 6), ('ranged', ranged, 5), ('gravity', gravity, 6), ('dash', dash, 6),
    ('cascade', cascade, 6), ('brand', brand, 5), ('summon', summon, 5), ('guard', guard, 4), ('death', death, 7),
]


def ridle(t):
    return E.flames(archon(pose(t=t, by=[0, 1, 1, 0][t], eye='W', glow=True, gem='W', flap=[0.3, 0.6, 0.8, 0.5][t])), t)


def rmove(t):
    return E.flames(archon(pose(t=t + 0.5, by=[0, 1, 0, 0, 1, 0][t], lean=2, stride=[-2, -1, 1, 2, 1, -1][t], blow=1, eye='W', glow=True,
                                gem='W', lance='level', wings=0.92)), t + 9)


def sequences():
    out = []
    for name, fn, n in SEQ:
        out.append(('archon_' + name, [fn(t).rows() for t in range(n)], PAL, 4))
    out.append(('archon_ridle', [ridle(t).rows() for t in range(4)], PAL, 4))
    out.append(('archon_rmove', [rmove(t).rows() for t in range(6)], PAL, 4))
    out.append(('archon', [idle(0).rows(), idle(2).rows(), move(0).rows(), move(3).rows(), lance_strike(3).rows(), cascade(4).rows()], PAL, 4))
    return out


if __name__ == '__main__':
    from canvas import preview
    preview([(n, f, p) for n, f, p, s in sequences()], sys.argv[1] if len(sys.argv) > 1 else 'archon.png', scale=2)
