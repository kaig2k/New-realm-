"""
Vorgath the Siege Warlord, after the design sheet: black plate with gold trim,
a crimson tabard and tattered cape, a gold-crowned great-helm with burning red
eyes, a spiked mace in one hand and a tower shield with a red sword in the other.

Unlike the other bosses he has an animation for each of his attacks. Each one is
its own sprite ("siege_warlord_swing" and so on, frames 0..n-1) that the game
plays through when he uses that attack (Bosses.as: anim on the attack, seq on
the boss). The plain "siege_warlord" sprite keeps the usual six frames for the
wiki, the Oracle and anything else that shows a boss.
"""
import math
from canvas import Canvas

W, H = 84, 89
CX = 42          # the middle of his body
FOOT = 72        # where his boots stand (in drawing space; OY is added on the canvas)
OY = 16          # headroom above him for the crown and a raised mace


class VCanvas(Canvas):
    """Draws everything OY pixels lower, so poses can reach above y=0."""
    def __init__(self):
        Canvas.__init__(self, W, H)

    def put(self, x, y, c, only=None):
        Canvas.put(self, x, y + OY, c, only)

    def get(self, x, y):
        return Canvas.get(self, int(round(x)), int(round(y)) + OY)

PAL = {
    # black plate (base, light, dark)
    'A': 0x2c3046, 'a': 0x4e5674, 'd': 0x12131e,
    # gold trim
    'G': 0xc89838, 'g': 0xf4d47a, 'o': 0x7a5420,
    # crimson cloth
    'C': 0xa8141e, 'c': 0xe0323a, 'k': 0x4c070c,
    # red glow: eyes, the emblem, his rage
    'R': 0xff2a2a, 'W': 0xffe0d0,
    # slashes, spikes and runes (bright and dim)
    'E': 0xff3a48, 'e': 0x9a0e1c, 'F': 0xff7a50,
    # smoke
    's': 0x4a1016,
}


def h32(*a):
    v = 2166136261
    for x in a:
        v = ((v ^ (int(x) & 0xffffffff)) * 16777619) & 0xffffffff
    return v


def pose(**k):
    p = dict(bx=0, by=0, lean=0, stride=0, crouch=0, t=0, blow=0, eyes='R',
             hand=None, head=None, glow=False, shield=(0, 0), shield_up=0, arms_up=False,
             helm_tilt=0, kneel=0)
    p.update(k)
    return p


# ------------------------------------------------------------------ the parts
def cape(c, p):
    """The tattered crimson cape behind him (blow > 0: streaming out to the left)."""
    x0, y0 = CX + p['bx'] + p['lean'], 22 + p['by']
    t, bl = p['t'], p['blow']
    wv = [math.sin(t * 1.7 + i) * 1.6 for i in range(8)]
    bottom = FOOT - 2 + p['crouch'] // 2
    left, right = 14 - bl * 2, 70 - bl
    pts = [(x0 - 13, y0), (x0 + 13, y0),
           (right + wv[0], bottom - 14 - bl * 2),
           (right - 2 + wv[1], bottom - 2 - bl),
           (right - 8, bottom - 7 - bl), (right - 12 + wv[2], bottom + 1 - bl),
           (CX + 4, bottom - 6), (CX - 2 + wv[3], bottom + 1),
           (left + 14, bottom - 6), (left + 8 + wv[4], bottom + 1 - bl),
           (left + 2, bottom - 5 - bl), (left - 2 + wv[5], bottom - 12 - bl * 3)]
    c.poly(pts, 'C')
    # rips and folds
    for i, fx in enumerate((left + 10, CX - 12, CX + 12, right - 8)):
        c.line(fx, y0 + 12, fx + wv[i] - bl, bottom - 4, 'k')
    c.shade('C', 'c', 'k')
    if bl:
        # tatters torn off behind him
        for i in range(5):
            x = left - 4 - i * 3 - (t * 2) % 3
            y = y0 + 10 + i * 6
            c.line(x, y, x + 3, y + 1, 'C', 2)


def legs(c, p):
    s, cr, kn = p['stride'], p['crouch'], p['kneel']
    top = 50 + p['by'] + cr // 2
    for side, dx in ((-1, -s), (1, s)):
        lx = CX + side * 8 + dx + p['bx'] // 2
        knee_y = top + 8 + cr // 3
        if kn and side == -1:
            # down on one knee: the thigh forward, the shin flat on the ground
            c.poly([(lx - 4, top), (lx + 4, top), (lx + 8, FOOT - 6), (lx, FOOT - 6)], 'A')
            c.rect(lx - 8, FOOT - 5, lx + 6, FOOT - 1, 'A')
            continue
        c.poly([(lx - 4, top), (lx + 4, top), (lx + 4 + side, knee_y), (lx - 4 + side, knee_y)], 'A')
        c.poly([(lx - 4 + side, knee_y), (lx + 4 + side, knee_y), (lx + 5 + side, FOOT - 4), (lx - 4 + side, FOOT - 4)], 'A')
        # knee cop and the boot
        c.ellipse(lx + side, knee_y, 4, 2.6, 'G')
        c.put(lx + side, knee_y, 'o')
        c.rect(lx - 5 + side, FOOT - 5, lx + 6 + side, FOOT - 1, 'A')
        c.rect(lx - 5 + side + (side > 0) * 7, FOOT - 3, lx + 1 + side + (side > 0) * 5, FOOT - 1, 'G')
    c.shade('A', 'a', 'd')


def body(c, p):
    bx, by, ln = CX + p['bx'], p['by'] + p['crouch'], p['lean']
    top = 24 + by
    # hip plates (faulds) with gold rims
    c.poly([(bx - 13, top + 21), (bx + 13, top + 21), (bx + 15, top + 31), (bx - 15, top + 31)], 'A')
    for x in (bx - 14, bx - 7, bx + 7, bx + 14):
        c.line(x, top + 22, x + (1 if x > bx else -1), top + 31, 'G')
    # the crimson tabard, with its jagged hem
    hem = top + 40 - p['crouch'] // 2
    c.poly([(bx - 5 + ln, top + 6), (bx + 5 + ln, top + 6), (bx + 5, hem - 3), (bx + 3, hem), (bx + 1, hem - 3),
            (bx, hem + 1), (bx - 1, hem - 3), (bx - 3, hem), (bx - 5, hem - 3)], 'C')
    c.shade('C', 'c', 'k')
    # the chest plate
    c.poly([(bx - 13 + ln, top), (bx + 13 + ln, top), (bx + 12 + ln // 2, top + 21), (bx - 12 + ln // 2, top + 21)], 'A')
    c.shade('A', 'a', 'd')
    # tabard over the chest: a horned demon's face, the warlord's sigil
    c.poly([(bx - 6 + ln, top + 7), (bx + 6 + ln, top + 7), (bx + 4 + ln, top + 20), (bx + ln, top + 24), (bx - 4 + ln, top + 20)], 'C')
    c.line(bx - 6 + ln, top + 6, bx - 9 + ln, top + 2, 'c', 2)
    c.line(bx + 6 + ln, top + 6, bx + 9 + ln, top + 2, 'c', 2)
    c.put(bx - 2 + ln, top + 12, p['eyes']); c.put(bx + 2 + ln, top + 12, p['eyes'])
    c.line(bx - 3 + ln, top + 16, bx + 3 + ln, top + 16, 'k')
    for x in range(bx - 2 + ln, bx + 3 + ln, 2):
        c.put(x, top + 17, 'g')
    # gold filigree on the plate
    for sgn in (-1, 1):
        c.line(bx + sgn * 8 + ln, top + 3, bx + sgn * 11 + ln, top + 10, 'G')
        c.line(bx + sgn * 11 + ln, top + 10, bx + sgn * 8 + ln, top + 16, 'G')
        c.put(bx + sgn * 9 + ln, top + 13, 'g')
    # a gold belt with a red jewel
    c.rect(bx - 13, top + 21, bx + 13, top + 22, 'G')
    c.rect(bx - 1, top + 20, bx + 1, top + 23, 'g')
    c.put(bx, top + 21, 'R')


def pauldron(c, x, y, p):
    c.ellipse(x, y, 9, 7, 'A')
    c.shade('A', 'a', 'd')
    c.ring(x, y + 1, 8.5, 6.5, 'G', 1)
    c.line(x - 7, y + 4, x + 7, y + 4, 'C')
    for k in (-1, 0, 1):
        sx = x + k * 5
        c.poly([(sx - 1.6, y - 4 + abs(k)), (sx, y - 11 + abs(k) * 2), (sx + 1.6, y - 4 + abs(k))], 'G')
        c.put(sx, y - 9 + abs(k) * 2, 'g')


def helm(c, p):
    x, y = CX + p['bx'] + p['lean'] + p['helm_tilt'], 16 + p['by'] + p['crouch']
    # crimson plumes either side (the tufts on his crown)
    for sgn in (-1, 1):
        c.poly([(x + sgn * 6, y - 1), (x + sgn * 10, y - 9), (x + sgn * 8, y - 2), (x + sgn * 11, y - 4), (x + sgn * 8, y + 3)], 'C')
    c.ellipse(x, y, 7, 7.5, 'A')
    c.shade('A', 'a', 'd')
    # the crown: a gold band and five points
    c.rect(x - 7, y - 5, x + 7, y - 4, 'G')
    for dx, hgt in ((0, 14), (-4, 9), (4, 9), (-7, 6), (7, 6)):
        c.poly([(x + dx - 1.5, y - 4), (x + dx, y - 4 - hgt), (x + dx + 1.5, y - 4)], 'G')
        c.put(x + dx, y - 5 - hgt // 2, 'g')
    c.put(x, y - 9, 'R')
    # the visor: a red slit with two burning eyes
    c.rect(x - 5, y, x + 5, y + 1, 'k')
    c.put(x - 3, y, p['eyes']); c.put(x - 2, y, p['eyes'])
    c.put(x + 2, y, p['eyes']); c.put(x + 3, y, p['eyes'])
    # gold cheek guards and a jaw plate
    c.line(x - 6, y + 2, x - 3, y + 7, 'G')
    c.line(x + 6, y + 2, x + 3, y + 7, 'G')
    c.line(x, y + 2, x, y + 6, 'o')


def shield(c, p):
    ox, oy = p['shield']
    x0, y0 = CX + 12 + p['bx'] + ox, 30 + p['by'] + p['crouch'] + oy - p['shield_up']
    w, h = 14, 30
    c.poly([(x0, y0 + 2), (x0 + w / 2, y0 - 1), (x0 + w, y0 + 2), (x0 + w, y0 + h - 6), (x0 + w / 2, y0 + h), (x0, y0 + h - 6)], 'G')
    c.poly([(x0 + 2, y0 + 3), (x0 + w / 2, y0 + 1), (x0 + w - 2, y0 + 3), (x0 + w - 2, y0 + h - 7), (x0 + w / 2, y0 + h - 2), (x0 + 2, y0 + h - 7)], 'A')
    c.shade('A', 'a', 'd')
    c.line(x0 + 1, y0 + 3, x0 + 1, y0 + h - 7, 'g')
    # the red sword on it
    mx = x0 + w / 2
    c.line(mx, y0 + 5, mx, y0 + h - 5, 'R', 1.6)
    c.line(mx - 4, y0 + 10, mx + 4, y0 + 10, 'R', 1.4)
    c.ellipse(mx, y0 + 6, 1.5, 1.5, 'c')
    c.put(mx, y0 + h - 4, 'c')
    # gold studs
    for (sx, sy) in ((x0 + 3, y0 + 4), (x0 + w - 3, y0 + 4), (x0 + 3, y0 + h - 8), (x0 + w - 3, y0 + h - 8)):
        c.put(sx, sy, 'g')


def mace_head(c, x, y, glow=False, r=6.5):
    """The great morning star: an iron ball, a red band and gold spikes."""
    for k in range(8):
        a = k * math.pi / 4 + 0.2
        c.line(x + math.cos(a) * (r - 1), y + math.sin(a) * (r - 1), x + math.cos(a) * (r + 3.5), y + math.sin(a) * (r + 3.5), 'G', 1.6)
        c.put(x + math.cos(a) * (r + 3.5), y + math.sin(a) * (r + 3.5), 'g')
    c.ellipse(x, y, r, r, 'A')
    c.shade('A', 'a', 'd')
    c.line(x - r + 1, y + 1, x + r - 1, y - 1, 'R' if glow else 'C', 1.4)
    for (dx, dy) in ((-2, -2), (2, 2), (2, -3)):
        c.put(x + dx, y + dy, 'g')
    if glow:
        c.ring(x, y, r + 5, r + 5, 'E', 1)


def mace_arm(c, p):
    hx, hy = p['hand']
    shx, shy = CX - 14 + p['bx'] + p['lean'], 28 + p['by'] + p['crouch']
    # the arm (shoulder to gauntlet)
    c.line(shx, shy, hx, hy, 'A', 5)
    c.shade('A', 'a', 'd')


def mace(c, p):
    hx, hy = p['hand']
    c.ellipse(hx, hy, 3, 3, 'G')
    c.put(hx, hy, 'o')
    if p['head']:
        mx, my = p['head']
        c.line(hx, hy, mx, my, 'o', 2)
        c.line(hx - (mx - hx) * 0.15, hy - (my - hy) * 0.15, hx, hy, 'G', 2)
        mace_head(c, mx, my, p['glow'])


def shield_arm(c, p):
    shx, shy = CX + 14 + p['bx'] + p['lean'], 28 + p['by'] + p['crouch']
    ox, oy = p['shield']
    c.line(shx, shy, CX + 18 + p['bx'] + ox, 40 + p['by'] + p['crouch'] + oy - p['shield_up'], 'A', 5)
    c.shade('A', 'a', 'd')


def embers(c, t, n=6, col='E'):
    for i in range(n):
        x = (7 + i * 13 + t * 5) % W
        y = (34 + i * 9 - t * 5) % 44 + 4
        if c.get(x, y) == '.':
            c.put(x, y, col)


def warlord(p, mace_front=True):
    c = VCanvas()
    cape(c, p)
    if not mace_front and p['hand']:
        mace(c, p)
    legs(c, p)
    body(c, p)
    shield_arm(c, p)
    if p['hand']:
        mace_arm(c, p)
    pauldron(c, CX - 14 + p['bx'] + p['lean'], 25 + p['by'] + p['crouch'], p)
    pauldron(c, CX + 14 + p['bx'] + p['lean'], 25 + p['by'] + p['crouch'], p)
    helm(c, p)
    shield(c, p)
    if mace_front and p['hand']:
        mace(c, p)
    return c


# ------------------------------------------------------------------ effects
def crescent(c, cx, cy, r, a0, a1, width, col='E', inner='W'):
    """A slash: an arc from angle a0 to a1, thickest in the middle."""
    n = int(abs(a1 - a0) * r * 1.5) + 2
    for i in range(n + 1):
        f = i / n
        a = a0 + (a1 - a0) * f
        wdt = width * math.sin(f * math.pi)
        for k in range(int(wdt) + 1):
            rr = r - k * 0.8
            c.put(cx + math.cos(a) * rr, cy + math.sin(a) * rr, inner if k == 0 and wdt > 2 else col)


def spikes(c, x, y, n, hgt, spread, seed, col='E'):
    """A cluster of crystal spikes bursting out of the ground."""
    for i in range(n):
        hv = h32(seed, i)
        dx = (i - (n - 1) / 2) * spread + (hv % 3) - 1
        hh = hgt * (0.55 + (hv >> 4) % 45 / 100) * (1.25 if i == n // 2 else 1)
        bx = x + dx
        lean = ((hv >> 9) % 5 - 2) * 0.6
        c.poly([(bx - 1.6, y), (bx + lean, y - hh), (bx + 1.6, y)], col)
        c.line(bx, y - 1, bx + lean * 0.8, y - hh * 0.8, 'W' if hh > 6 else 'F')


def ground_ring(c, cx, cy, rx, ry, col='E', runes=True, rot=0):
    c.ring(cx, cy, rx, ry, col, 1.2)
    c.ring(cx, cy, rx * 0.72, ry * 0.72, 'e', 1)
    if runes:
        for k in range(8):
            a = k * math.pi / 4 + rot
            c.line(cx + math.cos(a) * rx * 0.72, cy + math.sin(a) * ry * 0.72, cx + math.cos(a) * rx, cy + math.sin(a) * ry, col)
            c.put(cx + math.cos(a + 0.4) * rx * 0.86, cy + math.sin(a + 0.4) * ry * 0.86, 'W')


def streaks(c, t, n=9, x0=0, x1=30):
    for i in range(n):
        hv = h32(t, i, 7)
        y = 14 + hv % 54
        ln = 8 + (hv >> 8) % 16
        x = x0 + (hv >> 3) % max(1, x1 - x0)
        c.line(x, y, min(x + ln, x1 + 10), y, 'E' if i % 3 else 'W')


def flames(c, t, strength=1.0):
    """Enraged: tongues of red fire licking up from every top edge of him."""
    src = [row[:] for row in c.g]
    for x in range(W):
        for y in range(1, H):
            if src[y][x] != '.' and src[y - 1][x] == '.' and src[y][x] not in 'EeFWs':
                hv = h32(x, y, t)
                if hv % 2:
                    continue
                hgt = int((3 + hv % 6) * strength)
                for k in range(1, hgt + 1):
                    yy = y - k
                    xx = x + (1 if (hv >> (k + 3)) & 1 and k > 1 else 0)
                    if 0 <= xx < W and 0 <= yy < H and c.g[yy][xx] == '.':
                        c.g[yy][xx] = 'W' if k == 1 else 'F' if k < hgt * 0.6 else 'E'
    return c


def hot(c):
    """Rage: the eyes and the sigil burn white, the cape's dark folds glow."""
    for y in range(H):
        for x in range(W):
            if c.g[y][x] == 'R':
                c.g[y][x] = 'W'
            elif c.g[y][x] == 'k' and (x + y) % 3 == 0:
                c.g[y][x] = 'e'
    return c


# ------------------------------------------------------------------ the animations
def idle(t):
    b = [0, 1, 1, 0][t]
    p = pose(by=b, t=t, hand=(22, 46 + b), head=(14, 28 + b), shield=(0, b))
    c = warlord(p)
    embers(c, t)
    return c


def move(t):
    s = [-3, -1, 2, 3, 1, -2][t]
    b = [0, 1, 0, 0, 1, 0][t]
    p = pose(by=b, stride=s, lean=1, t=t, hand=(22, 46 + b - s // 2), head=(13, 30 + b - s), shield=(1, b))
    c = warlord(p)
    embers(c, t, 4)
    return c


def swing(t):
    """Mace swing: wind up behind him, a great sweep, the crescent left in the air."""
    k = [
        dict(bx=-2, lean=-2, hand=(18, 22), head=(10, 8), glow=True, mf=False),
        dict(bx=0, lean=0, hand=(30, 18), head=(36, 4), glow=True, mf=False),
        dict(bx=3, lean=3, hand=(58, 44), head=(70, 44), glow=False, mf=True),
        dict(bx=3, lean=2, hand=(56, 48), head=(66, 56), glow=False, mf=True),
        dict(bx=1, lean=1, hand=(24, 46), head=(15, 32), glow=False, mf=True),
    ][t]
    p = pose(bx=k['bx'], lean=k['lean'], t=t, hand=k['hand'], head=k['head'], glow=k['glow'])
    c = warlord(p, k['mf'])
    if t == 2:
        crescent(c, 44, 40, 34, -2.4, 0.5, 6)
    elif t == 3:
        crescent(c, 44, 40, 34, -1.4, 0.7, 4, 'e', 'E')
    return c


def smash(t):
    """Mace smash: overhead, then down into the ground and the earth erupts."""
    k = [
        dict(by=-2, hand=(32, 2), head=(36, -10), glow=False, cr=0),
        dict(by=-3, hand=(32, 0), head=(36, -12), glow=True, cr=0),
        dict(by=4, hand=(20, 54), head=(14, 66), glow=True, cr=4),
        dict(by=4, hand=(20, 54), head=(14, 66), glow=False, cr=4),
        dict(by=3, hand=(20, 54), head=(14, 66), glow=False, cr=3),
        dict(by=1, hand=(24, 48), head=(16, 34), glow=False, cr=0),
    ][t]
    p = pose(by=k['by'], crouch=k['cr'], t=t, hand=k['hand'], head=k['head'], glow=k['glow'], shield=(-2, 0))
    c = warlord(p, True)
    if t == 2:
        ground_ring(c, 16, 71, 16, 3.5, runes=False)
        spikes(c, 16, 72, 5, 10, 4, 1)
    elif t == 3:
        spikes(c, 16, 72, 8, 18, 3.4, 2)
        for (x, y) in ((2, 58), (34, 60), (8, 46), (30, 48)):
            c.put(x, y, 'F')
    elif t == 4:
        spikes(c, 16, 72, 7, 7, 4, 3, 'e')
        for i in range(6):
            c.ellipse(4 + i * 5, 64 - (i % 2) * 3, 2.4, 1.7, 's')
    return c


def bash(t):
    """Shield bash: the shield pulled in, then driven forward behind a red arc."""
    k = [
        dict(bx=-2, lean=-2, sh=(-3, 0)),
        dict(bx=4, lean=3, sh=(8, -1)),
        dict(bx=4, lean=3, sh=(8, -1)),
        dict(bx=1, lean=1, sh=(2, 0)),
    ][t]
    p = pose(bx=k['bx'], lean=k['lean'], t=t, hand=(22 + k['bx'], 46), head=(14 + k['bx'], 32), shield=k['sh'])
    c = warlord(p)
    if t == 1:
        crescent(c, 58, 44, 24, -1.2, 1.2, 6)
    elif t == 2:
        crescent(c, 62, 44, 22, -0.9, 0.9, 3, 'e', 'E')
    return c


def barrage(t):
    """Spike barrage: the mace held high and glowing, spikes flung up, then bursting from the ground."""
    k = [
        dict(hand=(26, 8), head=(22, -4), glow=False, by=0),
        dict(hand=(26, 6), head=(22, -7), glow=True, by=-1),
        dict(hand=(26, 6), head=(22, -7), glow=True, by=-1),
        dict(hand=(24, 44), head=(16, 30), glow=False, by=1),
        dict(hand=(24, 44), head=(16, 30), glow=False, by=1),
        dict(hand=(22, 46), head=(14, 30), glow=False, by=0),
    ][t]
    p = pose(by=k['by'], t=t, hand=k['hand'], head=k['head'], glow=k['glow'], eyes='W' if t in (1, 2) else 'R')
    c = warlord(p)
    if t == 1:
        for i, (x, y) in enumerate(((10, -6), (34, -10), (14, -14))):
            c.poly([(x - 1, y + 4), (x, y), (x + 1, y + 4)], 'E')
    if t == 2:
        for i in range(7):
            x = 6 + i * 11
            y = -12 + (i % 3) * 4
            c.poly([(x - 1.2, y + 5), (x, y), (x + 1.2, y + 5)], 'E')
            c.put(x, y + 1, 'W')
    if t in (3, 4):
        hgt = 10 if t == 3 else 14
        for gx in (10, 26, 58, 74):
            spikes(c, gx, 72, 3, hgt - (gx % 3) * 2, 2.5, gx + t)
    return c


def warcry(t):
    """War cry: arms flung wide, a rune circle blazes under him and spikes ring out."""
    k = [
        dict(by=1, cr=1, hand=(22, 44), head=(14, 32), sh=(0, 0), su=0, tilt=0),
        dict(by=-1, cr=0, hand=(14, 22), head=(8, 10), sh=(4, 0), su=8, tilt=0),
        dict(by=-2, cr=0, hand=(12, 20), head=(6, 8), sh=(5, 0), su=10, tilt=0),
        dict(by=-2, cr=0, hand=(12, 20), head=(6, 8), sh=(5, 0), su=10, tilt=0),
        dict(by=0, cr=0, hand=(22, 46), head=(14, 32), sh=(0, 0), su=0, tilt=0),
    ][t]
    p = pose(by=k['by'], crouch=k['cr'], t=t, hand=k['hand'], head=k['head'], shield=k['sh'], shield_up=k['su'],
             eyes='W' if t in (1, 2, 3) else 'R', glow=t in (2, 3))
    c = VCanvas()
    if t >= 2:
        ground_ring(c, CX, 70, 38, 6, rot=t * 0.2)
    body_c = warlord(p)
    for y in range(H):
        for x in range(W):
            if body_c.g[y][x] != '.':
                c.g[y][x] = body_c.g[y][x]
    if t == 1:
        for i in range(10):
            a = i * math.pi / 5
            c.put(CX + math.cos(a) * 30, 40 + math.sin(a) * 24, 'E')
    if t == 2:
        for gx in (6, 22, 62, 78):
            spikes(c, gx, 71, 2, 8, 2.5, gx)
    if t == 3:
        for gx in (4, 16, 28, 56, 68, 80):
            spikes(c, gx, 71, 3, 13, 2.2, gx + 9)
        if t == 3:
            hot(c)
    return c


def charge(t):
    """Dash: he leans in and barrels forward, mace first, a red streak behind him."""
    s = [-2, 2, -2, 2][t]
    p = pose(bx=6, lean=5, stride=s, t=t, blow=3, hand=(62, 40), head=(74, 36), glow=t in (1, 2), shield=(2, 0))
    c = warlord(p)
    streaks(c, t, 10, 0, 26)
    return c


def death(t):
    """He staggers, falls to a knee, and crumbles into smoke and embers."""
    c = VCanvas()
    if t <= 2:
        k = [dict(bx=-3, by=2, cr=0, kn=0, hand=(22, 52), head=(12, 62)),
             dict(bx=-2, by=6, cr=6, kn=1, hand=(26, 58), head=(14, 66)),
             dict(bx=-1, by=10, cr=10, kn=1, hand=(30, 64), head=(16, 68))][t]
        p = pose(bx=k['bx'], by=k['by'], crouch=k['cr'], kneel=k['kn'], t=t, hand=k['hand'], head=k['head'],
                 eyes='R' if t < 2 else 'e', shield=(2, 6 + t * 4), helm_tilt=t)
        c = warlord(p, False)
        # cracks of red light running through the armour
        for i in range(3 + t * 3):
            hv = h32(i, t, 5)
            x, y = 28 + hv % 28, 20 + (hv >> 6) % 34
            c.line(x, y, x + (hv >> 3) % 5 - 2, y + 3, 'R')
        return c
    # fallen: a heap of armour, then smoke, then a few embers
    if t <= 4:
        c.ellipse(CX, 66, 22, 5, 'C')
        c.shade('C', 'c', 'k')
        c.ellipse(CX - 4, 63, 12, 5, 'A')
        c.ellipse(CX + 10, 64, 7, 4, 'A')
        c.shade('A', 'a', 'd')
        c.ellipse(CX - 14, 61, 6, 5, 'A')   # the helm
        c.rect(CX - 20, 57, CX - 9, 58, 'G')
        mace_head(c, CX + 22, 66, False, 4.5)
        if t == 4:
            for i in range(10):
                hv = h32(i, 77)
                c.ellipse(16 + hv % 52, 46 + (hv >> 5) % 18, 3 + hv % 3, 2.4, 's')
        return c
    for i in range(18 if t == 5 else 9):
        hv = h32(i, t)
        x, y = 10 + hv % 64, 30 + (hv >> 7) % 40
        if t == 5 and i < 8:
            c.ellipse(x, y, 3, 2, 's')
        else:
            c.put(x, y, 'E' if i % 2 else 'F')
    return c


SEQ = [
    ('idle', idle, 4), ('move', move, 6), ('swing', swing, 5), ('smash', smash, 6), ('bash', bash, 4),
    ('barrage', barrage, 6), ('warcry', warcry, 5), ('charge', charge, 4), ('death', death, 7),
]


def sequences():
    """[(sprite name, [frame rows], palette, scale)]: one sprite per animation, plus the enraged idle and move."""
    out = []
    for name, fn, n in SEQ:
        out.append(('siege_warlord_' + name, [fn(t).rows() for t in range(n)], PAL, 4))
    out.append(('siege_warlord_ridle', [flames(hot(idle(t)), t).rows() for t in range(4)], PAL, 4))
    out.append(('siege_warlord_rmove', [flames(hot(move(t)), t + 9).rows() for t in range(6)], PAL, 4))
    # the plain sprite: idle, move, and the smash's wind-up and blow
    base = [idle(0).rows(), idle(2).rows(), move(0).rows(), move(3).rows(), smash(1).rows(), smash(3).rows()]
    out.append(('siege_warlord', base, PAL, 4))
    return out
