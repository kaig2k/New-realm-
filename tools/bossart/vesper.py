"""
Archon Vesper, the Crimson Dawn (a draft sheet, waiting on the user's word):
a gaunt blood-priest of the Crimson Conclave in a black and crimson robe hemmed
with gold, a great tattered bat-wing cape spread behind him, long white hair,
burning red eyes under a golden crown of thorns, and his staff, a golden rod
crowned with a crescent of blood cradling a red orb. Drops of blood drift round him.

Like Tempestus (tempestus.py) he borrows the Dark Elder's drawing tools and has
an animation for each of his attacks: the crescent volley, the crimson rite, the
blood geyser, the blood brand, his blood-mist blink, the summoning of the
Conclave, his guard when he shields himself, and his death.

python3 tools/bossart/vesper.py out.png draws the presentation sheet.
"""
import math
import sys
import elder as E
from elder import VCanvas, W, H, CX, FOOT, h32

PAL = {
    # the robe: black with a crimson cast (base, light, dark)
    'K': 0x2a0c16, 'k': 0x52182c, 'n': 0x10040a,
    # the cape / wings: crimson
    'C': 0x8a1028, 'c': 0xd02848, 'd': 0x4a0614,
    # gold trim, crown and staff
    'G': 0xd4a030, 'g': 0xffe080, 'o': 0x7a5410,
    # pale skin and white hair
    'H': 0xe8d8d8, 'h': 0xfff4f4, 'e': 0xa08890, 'L': 0xf0ecf4, 'l': 0xb8b0c8,
    # blood light (the Elder's tools draw with these letters)
    'P': 0xff2040, 'p': 0xffa0b0, 'V': 0x9a0820, 'W': 0xfff0f0,
    'X': 0x1a0004,
    # enraged blood-fire
    'F': 0xff3050, 'f': 0xffd0d8,
}


def pose(**k):
    p = dict(t=0, bx=0, by=0, lean=0, stride=0, staff='rest', hand='rest', eye='P', glow=False,
             wings=1.0, wing_up=0, crouch=0, blow=0, drops=True)
    p.update(k)
    return p


# ------------------------------------------------------------------ the parts
def wings(c, p):
    """The bat-wing cape: two great tattered sails behind him, ribbed with gold-tipped bones."""
    s = p['wings']
    if s <= 0:
        return
    bx, by, up = CX + p['bx'] + p['lean'], p['by'] + p['crouch'], p['wing_up']
    for sgn in (-1, 1):
        root = (bx + sgn * 5, 26 + by)
        tip = (bx + sgn * 44 * s, 6 + by - up)
        elbow = (bx + sgn * 26 * s, 12 + by - up * 0.6)
        # the scalloped trailing edge: points between the bones
        edge = [(bx + sgn * 42 * s, 30 + by - up * 0.4), (bx + sgn * 34 * s, 26 + by), (bx + sgn * 30 * s, 44 + by),
                (bx + sgn * 22 * s, 38 + by), (bx + sgn * 17 * s, 58 + by), (bx + sgn * 9, 50 + by)]
        c.poly([root, elbow, tip] + edge, 'C')
        c.shade('C', 'c', 'd')
        # the bones
        c.line(root[0], root[1], elbow[0], elbow[1], 'd', 2)
        c.line(elbow[0], elbow[1], tip[0], tip[1], 'd', 1.6)
        for (ex, ey) in edge[::2]:
            c.line(elbow[0], elbow[1], ex, ey, 'd')
        c.put(tip[0], tip[1] - 1, 'G')
        c.put(elbow[0], elbow[1] - 1, 'g')


def robe(c, p):
    bx, by, ln, s, bl = CX + p['bx'], p['by'] + p['crouch'], p['lean'], p['stride'], p['blow']
    hem = FOOT - 1
    c.poly([(bx - 11 + ln, 25 + by), (bx + 11 + ln, 25 + by), (bx + 19 - bl, hem - 2), (bx + 12 + s - bl, hem + 1),
            (bx + 3 - bl, hem - 1), (bx - 7 - s - bl * 2, hem + 1), (bx - 18 - bl * 2, hem - 1)], 'K')
    for dx in (-12, -6, 6, 12):
        c.line(bx + dx * 0.4 + ln, 40 + by, bx + dx - bl, hem - 3, 'n')
    # crimson panels either side of the gold
    c.poly([(bx - 3 + ln, 30 + by), (bx + 3 + ln, 30 + by), (bx + 6 - bl, hem - 2), (bx - 5 - bl, hem - 2)], 'C')
    c.shade('K', 'k', 'n')
    # gold down the front and along the hem
    c.line(bx + ln, 28 + by, bx + 1 - bl, hem, 'G')
    c.line(bx - 18 - bl * 2, hem - 1, bx + 19 - bl, hem - 2, 'G')
    c.line(bx - 17 - bl * 2, hem - 3, bx + 18 - bl, hem - 4, 'o')
    for y in range(34, 80, 9):
        c.put(bx + ln * (1 - (y - 28) / 60), y + by, 'g')
    # a crimson sash at the waist, its ends hanging
    c.rect(bx - 10, 44 + by, bx + 10, 46 + by, 'G')
    c.rect(bx - 10, 45 + by, bx + 10, 45 + by, 'o')
    c.line(bx + 3, 46 + by, bx + 5 - bl, 58 + by, 'C', 2)
    c.put(bx, 45 + by, 'P')


def collar(c, p):
    """A high golden collar, flaring up behind his head like a sunburst."""
    bx, by = CX + p['bx'] + p['lean'], p['by'] + p['crouch']
    for k in range(7):
        a = math.pi + (k + 0.5) * math.pi / 7
        c.poly([(bx + math.cos(a) * 5, 24 + by + math.sin(a) * 3), (bx + math.cos(a) * 13, 22 + by + math.sin(a) * 10),
                (bx + math.cos(a + 0.18) * 6, 24 + by + math.sin(a + 0.18) * 3)], 'G')
    c.shade('G', 'g', 'o')
    # the shoulders: dark plate with gold rims
    for sgn in (-1, 1):
        c.ellipse(bx + sgn * 11, 27 + by, 6, 3.5, 'K')
        c.line(bx + sgn * 6, 24 + by, bx + sgn * 16, 27 + by, 'G')
        c.put(bx + sgn * 16, 28 + by, 'g')


def hair(c, p):
    """Long white hair, falling behind his shoulders (drawn before the robe and collar)."""
    bx, by, bl = CX + p['bx'] + p['lean'], p['by'] + p['crouch'], p['blow']
    c.poly([(bx - 6, 8 + by), (bx + 6, 8 + by), (bx + 8, 16 + by), (bx + 9 - bl, 30 + by), (bx + 6 - bl * 2, 38 + by),
            (bx - 6 - bl * 2, 38 + by), (bx - 9 - bl * 2, 30 + by), (bx - 8, 16 + by)], 'L')
    c.shade('L', 'l', 'l')
    for dx in (-5, -2, 2, 5):
        c.line(bx + dx, 18 + by, bx + dx * 1.3 - bl * 2, 37 + by, 'l')


def head(c, p):
    bx, by = CX + p['bx'] + p['lean'], p['by'] + p['crouch']
    # the gaunt face, sharp cheekbones and chin, hair parted over the brow
    c.poly([(bx - 5, 10 + by), (bx + 5, 10 + by), (bx + 5, 17 + by), (bx + 2, 23 + by), (bx - 2, 23 + by), (bx - 5, 17 + by)], 'H')
    c.shade('H', 'h', 'e')
    c.line(bx - 4, 18 + by, bx - 2, 21 + by, 'e')
    c.line(bx + 4, 18 + by, bx + 2, 21 + by, 'e')
    c.poly([(bx - 6, 9 + by), (bx, 10 + by), (bx - 5, 14 + by)], 'L')
    c.poly([(bx + 6, 9 + by), (bx, 10 + by), (bx + 5, 14 + by)], 'L')
    # burning eyes under a heavy brow, a thin dark mouth
    eye = p['eye']
    for sgn in (-1, 1):
        c.line(bx + sgn * 1, 14 + by, bx + sgn * 4, 13 + by, 'e')
        c.put(bx + sgn * 2, 15 + by, eye)
        c.put(bx + sgn * 3, 15 + by, eye)
    c.line(bx - 1, 21 + by, bx + 1, 21 + by, 'V')
    # the golden crown of thorns, a blood-red gem in its middle
    c.rect(bx - 6, 8 + by, bx + 6, 9 + by, 'G')
    for dx, ht in ((-6, 4), (-3, 6), (0, 9), (3, 6), (6, 4)):
        c.line(bx + dx, 8 + by, bx + dx * 1.3, 8 + by - ht, 'G')
    c.put(bx, -1 + by, 'g')
    c.put(bx, 8 + by, 'P')


def staff_at(c, x0, y0, x1, y1, glow, open_=1.0):
    """His staff from the hand (x0, y0) to its head (x1, y1): a golden rod, a crescent of blood and its orb."""
    c.line(x0 - (x1 - x0) * 0.35, y0 - (y1 - y0) * 0.35, x1, y1, 'G', 2)
    c.line(x0 - (x1 - x0) * 0.35, y0 - (y1 - y0) * 0.35, x1, y1, 'o')
    a = math.atan2(y1 - y0, x1 - x0)
    cx, cy = x1 + math.cos(a) * 5, y1 + math.sin(a) * 5
    # the crescent, opening away from the hand
    for i in range(40):
        f = i / 39
        th = a + math.pi + (f - 0.5) * 2 * 2.3 * open_
        wd = 2.2 * math.sin(f * math.pi) + 0.6
        for k in range(int(wd * 2) + 1):
            r = 6 - k * 0.5
            c.put(cx + math.cos(th + math.pi) * r, cy + math.sin(th + math.pi) * r, 'P' if k else 'c')
    c.ellipse(cx, cy, 2.2, 2.2, 'V')
    c.put(cx - 0.6, cy - 0.6, 'W' if glow else 'p')
    if glow:
        c.ring(cx, cy, 8.5, 8.5, 'p', 1)
    return cx, cy


def arms(c, p):
    bx, by = CX + p['bx'] + p['lean'], p['by'] + p['crouch']
    # his staff hand (on the right)
    ends = {'rest': (bx + 13, 46), 'forward': (bx + 22, 32), 'up': (bx + 14, 20), 'swing': (bx + 20, 22),
            'down': (bx + 14, 52), 'plant': (bx + 15, 44), 'high': (bx + 20, 16), 'back': (bx + 15, 42)}
    hx, hy = ends[p['staff']]
    hy += by
    c.line(bx + 10, 28 + by, hx, hy, 'K', 4)
    c.shade('K', 'k', 'n')
    c.ellipse(hx, hy, 1.8, 1.8, 'H')
    heads = {'rest': (hx + 2, hy - 30), 'forward': (hx + 16, hy - 16), 'up': (hx + 9, hy - 17), 'swing': (hx + 18, hy + 2),
             'down': (hx + 8, hy + 22), 'plant': (hx + 1, hy - 32), 'high': (hx + 9, hy - 14), 'back': (hx + 17, hy - 22)}
    sx, sy = heads[p['staff']]
    head_pos = staff_at(c, hx, hy, sx, sy, p['glow'])
    # his other hand: long pale claws
    lends = {'rest': (bx - 12, 44), 'out': (bx - 26, 30), 'up': (bx - 14, 8), 'down': (bx - 16, 56), 'chest': (bx - 3, 34),
             'point': (bx - 30, 22)}
    lx, ly = lends[p['hand']]
    ly += by
    c.line(bx - 10, 28 + by, lx, ly, 'K', 4)
    c.shade('K', 'k', 'n')
    c.ellipse(lx, ly, 2, 2, 'H')
    a = math.atan2(ly - (28 + by), lx - (bx - 10))
    for k in (-0.5, 0, 0.5):
        c.line(lx, ly, lx + math.cos(a + k) * 4, ly + math.sin(a + k) * 4, 'e')
    c.hands = ((hx, hy), (lx, ly), head_pos)


def drops(c, p):
    """Drops of blood drifting round him."""
    if not p['drops']:
        return
    t = p['t']
    bx, by = CX + p['bx'], p['by']
    for k in range(5):
        a = k * math.pi * 2 / 5 + t * 0.3
        x = bx + math.cos(a) * 30
        y = 50 + by + math.sin(a) * 20
        c.ellipse(x, y, 1.6, 1.6, 'P')
        c.put(x, y - 2, 'P')
        c.put(x - 0.5, y - 0.5, 'p')


def vesper(p):
    c = VCanvas()
    wings(c, p)
    hair(c, p)
    robe(c, p)
    collar(c, p)
    head(c, p)
    arms(c, p)
    drops(c, p)
    return c


def merge(base, top):
    for y in range(H):
        for x in range(W):
            if top.g[y][x] != '.':
                base.g[y][x] = top.g[y][x]
    return base


def crescent(c, x, y, r, w, ang, col='P', edge='W'):
    """A thrown blood crescent, its open side trailing."""
    for i in range(60):
        f = i / 59
        th = ang + (f - 0.5) * 2.6
        wd = w * math.sin(f * math.pi)
        for k in range(int(wd * 2) + 1):
            rr = r - k * 0.5
            c.put(x + math.cos(th) * rr, y + math.sin(th) * rr, edge if k == 0 and wd > 1.5 else col)


def spike(c, x, base, ht, lean=0.0):
    """A spike of blood bursting up out of the ground."""
    c.poly([(x - 2.5, base), (x + 2.5, base), (x + lean, base - ht)], 'P')
    c.line(x - 1, base - 1, x + lean * 0.8, base - ht + 2, 'p')
    c.ellipse(x, base, 5, 1.4, 'V')


def sigil(c, x, y, s, glow=False):
    """The blood brand: a diamond with a drop of blood inside it."""
    c.poly([(x, y - 7 * s), (x + 5 * s, y), (x, y + 7 * s), (x - 5 * s, y)], 'P')
    c.poly([(x, y - 5 * s), (x + 3.4 * s, y), (x, y + 5 * s), (x - 3.4 * s, y)], 'V')
    c.ellipse(x, y + 1 * s, 1.6 * s, 1.8 * s, 'P')
    c.put(x, y - 1.5 * s, 'P')
    if glow:
        c.ring(x, y, 9 * s, 9 * s, 'p', 1)


def bat(c, x, y, t):
    up = (t % 2) * 2
    c.ellipse(x, y, 1.6, 1.4, 'X')
    for sgn in (-1, 1):
        c.poly([(x + sgn, y), (x + sgn * 6, y - 2 - up), (x + sgn * 5, y + 1), (x + sgn * 3, y + 2 - up * 0.5)], 'd')
    c.put(x, y, 'P')


# ------------------------------------------------------------------ the animations
def idle(t):
    b = [0, 1, 1, 0][t]
    return vesper(pose(t=t, by=b, wing_up=[0, 1, 2, 1][t], hand='chest' if t in (1, 2) else 'rest'))


def move(t):
    b = [0, 1, 0, 0, 1, 0][t]
    s = [-2, -1, 1, 2, 1, -1][t]
    return vesper(pose(t=t + 0.5, by=b, lean=2, stride=s, blow=1, wings=0.9, wing_up=[2, 0, -1, 0, 2, 3][t]))


def crescent_anim(t):
    """Crescent volley: the staff drawn back, swept forward, and crescents of blood flung out."""
    modes = ['back', 'back', 'up', 'swing', 'forward', 'rest']
    c = vesper(pose(t=t, lean=[-1, -2, 0, 3, 2, 0][t], staff=modes[t], glow=t in (2, 3), wing_up=[0, 2, 4, 0, -1, 0][t]))
    if t in (3, 4):
        d = 0 if t == 3 else 6
        for k in (-1, 0, 1):
            crescent(c, CX + 34 + d - abs(k) * 4, 36 + k * 14, 6, 2.4, k * 0.2, 'P', 'W')
    if t == 2:
        c.ring(c.hands[2][0], c.hands[2][1], 10, 10, 'P', 1)
    return c


def rite(t):
    """The crimson rite: he plants his staff, a rune circle opens and columns of blood burst up all round."""
    c = VCanvas()
    if t >= 1:
        rr = [0, 18, 28, 36, 40, 26][t]
        E.ground_ring(c, CX, FOOT, rr, rr * 0.2 + 2, 'P', 'V', rot=t * 0.35)
    merge(c, vesper(pose(t=t, crouch=2 if t in (1, 2) else 0, staff='plant' if t >= 1 else 'rest', hand='out' if t in (3, 4) else 'chest',
                         glow=t >= 2, eye='W' if t in (3, 4) else 'P', wing_up=4 if t in (3, 4) else 0)))
    if t in (3, 4):
        for k in range(8):
            a = k * math.pi / 4 + 0.4
            x = CX + math.cos(a) * 36
            y = FOOT + math.sin(a) * 6
            E.pillar(c, x, y - (16 if t == 3 else 26), y, 2)
    return c


def geyser(t):
    """Blood geyser: he drives his claws toward the ground and spikes of blood erupt in a line."""
    c = vesper(pose(t=t, lean=[0, 1, 2, 2, 1, 0][t], hand='down' if t in (1, 2, 3, 4) else 'rest', crouch=[0, 2, 3, 2, 1, 0][t],
                    staff='back' if t in (1, 2, 3) else 'rest', glow=t in (2, 3)))
    n = [0, 0, 2, 4, 5, 2][t]
    for k in range(n):
        x = CX - 22 - k * 9 + (0 if t < 5 else 4)
        if x < 2:
            break
        spike(c, x, FOOT, [10, 14, 18, 16, 12][k % 5] * (0.6 if t == 5 else 1), lean=-1)
    if t == 1:
        c.ellipse(CX - 16, 64, 3, 3, 'P')
    return c


def brand(t):
    """The blood brand: his hand points, the sigil forms in his palm and flies to its mark."""
    c = vesper(pose(t=t, hand='point' if t in (2, 3, 4) else 'chest' if t == 1 else 'rest', eye='W' if t in (2, 3) else 'P',
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
        # the mark lands: a beating ring on the ground where its carrier stands
        c.ring(12, FOOT - 2, 11, 3.2, 'P', 1.4)
        c.ring(12, FOOT - 2, 7, 2, 'V', 1)
        sigil(c, 12, 40, 0.8)
    return c


def blink(t):
    """Blood-mist blink: he folds his wings round himself, bursts into a swarm of bats, and pours back out."""
    if t in (2, 3):
        c = VCanvas()
        for i in range(10 if t == 2 else 7):
            hv = h32(i, t, 5)
            spread = 30 if t == 2 else 40
            bat(c, CX + (hv % (spread * 2)) - spread, 20 + (hv >> 8) % 50, t + i)
        c.ellipse(CX, FOOT, 14 if t == 2 else 8, 2.4, 'V')
        return c
    if t == 1:
        c = vesper(pose(t=t, wings=0.45, wing_up=-6, hand='chest', staff='back', crouch=2))
        E.sparkles(c, t, 10)
        return c
    if t == 4:
        c = E.dissolve(vesper(pose(t=t, wings=0.6, hand='chest', staff='back')), 0.55)
        for i in range(4):
            hv = h32(i, t, 9)
            bat(c, CX - 30 + hv % 60, 14 + (hv >> 7) % 30, i)
        return c
    return vesper(pose(t=t, wing_up=[0, 0, 0, 0, 0, 5][t], wings=1.05 if t == 5 else 1.0))


def summon(t):
    """Summoning the Conclave: the staff raised high, pools of blood open and his acolytes rise from them."""
    c = vesper(pose(t=t, staff='high' if t >= 1 else 'rest', hand='out' if t >= 2 else 'rest', glow=t >= 1, wing_up=[0, 3, 5, 5, 2][t]))
    if t >= 2:
        for x in (10, 82):
            c.ellipse(x, FOOT, 8, 2.2, 'V')
            c.ellipse(x, FOOT, 5, 1.2, 'P')
            if t >= 3:
                ht = 14 if t == 3 else 24
                # a hooded acolyte rising out of the pool
                c.poly([(x - 6, FOOT), (x + 6, FOOT), (x + 4, FOOT - ht + 6), (x, FOOT - ht), (x - 4, FOOT - ht + 6)], 'K')
                c.shade('K', 'k', 'n')
                c.line(x - 5, FOOT - 2, x + 5, FOOT - 2, 'C')
                c.put(x - 1, FOOT - ht + 5, 'P')
                c.put(x + 2, FOOT - ht + 5, 'P')
    if t == 1:
        E.sparkles(c, t, 8)
    return c


def guard(t):
    """Guard: his wings close round him like a shell and a skin of blood hardens over them."""
    c = vesper(pose(t=t, wings=0.55, wing_up=-4, hand='chest', staff='plant', glow=True, drops=False))
    r = [24, 28, 28, 25][t]
    c.ring(CX, 46, r, r * 1.2, 'P', 1.4)
    c.ring(CX, 46, r - 2, r * 1.2 - 2, 'V', 1)
    for k in range(8):
        a = k * math.pi / 4 + t * 0.4
        c.put(CX + math.cos(a) * r, 46 + math.sin(a) * r * 1.2, 'W')
    return c


def death(t):
    """He staggers, his crown falls, he sinks to his knees and comes apart into blood and bats."""
    if t <= 2:
        c = vesper(pose(t=t, by=t * 3, crouch=t * 4, wings=1 - t * 0.2, wing_up=-t * 3, eye=['W', 'P', 'V'][t],
                        staff='down', hand='down', drops=t == 0))
        for i in range(3 + t * 3):
            hv = h32(i, t, 3)
            c.ellipse(28 + hv % 36, 30 + (hv >> 6) % 50, 1.2, 1.6, 'P')
        return c
    if t <= 4:
        c = E.dissolve(vesper(pose(t=t, by=10, crouch=10, wings=0.5, wing_up=-8, eye='V', staff='down', hand='down', drops=False)),
                       [0, 0, 0, 0.5, 0.22][t])
        for i in range(3 if t == 3 else 6):
            hv = h32(i, t, 9)
            bat(c, 10 + hv % 72, 10 + (hv >> 7) % 40, i)
        return c
    c = VCanvas()
    c.ellipse(CX, FOOT, 22 if t == 5 else 26, 3.2, 'V')
    c.ellipse(CX, FOOT, 14 if t == 5 else 18, 1.8, 'P')
    # his crown, left lying in the blood
    c.rect(CX - 5, FOOT - 3, CX + 5, FOOT - 2, 'G')
    for dx in (-4, 0, 4):
        c.line(CX + dx, FOOT - 3, CX + dx * 1.2, FOOT - 6, 'G')
    if t == 5:
        E.sparkles(c, t, 14)
    return c


SEQ = [
    ('idle', idle, 4), ('move', move, 6), ('crescent', crescent_anim, 6), ('rite', rite, 6), ('geyser', geyser, 6),
    ('brand', brand, 6), ('blink', blink, 6), ('summon', summon, 5), ('guard', guard, 4), ('death', death, 7),
]

TITLES = {
    'idle': 'Idle', 'move': 'Move', 'crescent': 'Crescent Volley', 'rite': 'The Crimson Rite', 'geyser': 'Blood Geyser',
    'brand': 'Blood Brand', 'blink': 'Blood-Mist Blink', 'summon': 'Summon the Conclave', 'guard': 'Guard (phase shield)',
    'death': 'Death', 'ridle': 'Enraged Idle', 'rmove': 'Enraged Move',
}


def ridle(t):
    return E.flames(vesper(pose(t=t, by=[0, 1, 1, 0][t], eye='W', glow=True, wing_up=[2, 4, 5, 3][t])), t)


def rmove(t):
    return E.flames(vesper(pose(t=t + 0.5, by=[0, 1, 0, 0, 1, 0][t], lean=2, stride=[-2, -1, 1, 2, 1, -1][t], blow=1, eye='W', glow=True)), t + 9)


def sequences():
    out = []
    for name, fn, n in SEQ:
        out.append(('vesper_' + name, [fn(t).rows() for t in range(n)], PAL, 4))
    out.append(('vesper_ridle', [ridle(t).rows() for t in range(4)], PAL, 4))
    out.append(('vesper_rmove', [rmove(t).rows() for t in range(6)], PAL, 4))
    out.append(('vesper', [idle(0).rows(), idle(2).rows(), move(0).rows(), move(3).rows(), rite(3).rows(), crescent_anim(3).rows()], PAL, 4))
    return out


# ------------------------------------------------------------------ the presentation sheet
def render(rows, scale):
    """One frame as the game draws it: palette colours, scaled up, a 2px black outline."""
    from PIL import Image
    h, w = len(rows), len(rows[0])
    img = Image.new('RGBA', (w * scale + 4, h * scale + 4), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == '.' or ch not in PAL:
                continue
            col = PAL[ch]
            for yy in range(scale):
                for xx in range(scale):
                    px[2 + x * scale + xx, 2 + y * scale + yy] = ((col >> 16) & 255, (col >> 8) & 255, col & 255, 255)
    out = img.copy()
    op = out.load()
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y][3]:
                continue
            if any(0 <= x + dx < img.width and 0 <= y + dy < img.height and px[x + dx, y + dy][3]
                   for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2) if abs(dx) + abs(dy) <= 2):
                op[x, y] = (0, 0, 0, 255)
    return out


def sheet(path, scale=2):
    from PIL import Image, ImageDraw, ImageFont
    seqs = [(n, fn, k) for n, fn, k in SEQ] + [('ridle', ridle, 4), ('rmove', rmove, 6)]
    def font(sz):
        for f in ('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', '/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf'):
            try:
                return ImageFont.truetype(f, sz)
            except OSError:
                pass
        return ImageFont.load_default()
    fw, fh = W * scale + 4, H * scale + 4
    label_w, pad, top = 210, 8, 190
    cols = max(k for _, _, k in seqs)
    width = label_w + cols * (fw + pad) + pad
    height = top + len(seqs) * (fh + pad) + pad + 40
    img = Image.new('RGBA', (width, height), (24, 10, 16, 255))
    d = ImageDraw.Draw(img)
    # the title, his portrait and his palette
    port = render(idle(0).rows(), 2)
    img.alpha_composite(port, (12, 0))
    d.text((label_w + 10, 18), 'ARCHON VESPER', fill=(255, 64, 90), font=font(40))
    d.text((label_w + 12, 66), 'The Crimson Dawn  -  last boss of the Crimson Conclave', fill=(230, 210, 215), font=font(18))
    d.text((label_w + 12, 92), '"So you are the ones who silenced my Matron."', fill=(212, 160, 48), font=font(16))
    sw = [('robe', 'K'), ('wings', 'C'), ('gold', 'G'), ('skin', 'H'), ('hair', 'L'), ('blood', 'P'), ('blood light', 'p')]
    for i, (nm, ch) in enumerate(sw):
        x = label_w + 12 + i * 92
        col = PAL[ch]
        d.rectangle((x, 126, x + 22, 148), fill=((col >> 16) & 255, (col >> 8) & 255, col & 255), outline=(0, 0, 0))
        d.text((x + 28, 130), nm, fill=(200, 190, 195), font=font(12))
    for r, (name, fn, n) in enumerate(seqs):
        y = top + r * (fh + pad)
        d.rectangle((0, y - 2, width, y + fh + 2), fill=(36, 14, 22) if r % 2 else (28, 10, 18))
        d.text((12, y + fh // 2 - 18), TITLES[name], fill=(255, 200, 210), font=font(17))
        d.text((12, y + fh // 2 + 6), str(n) + ' frames', fill=(150, 120, 130), font=font(12))
        for t in range(n):
            fr = render(fn(t).rows(), scale)
            img.alpha_composite(fr, (label_w + pad + t * (fw + pad), y))
    d.text((12, height - 30), 'Eldmere  -  draft for approval: tools/bossart/vesper.py', fill=(140, 110, 120), font=font(12))
    img.save(path)


if __name__ == '__main__':
    sheet(sys.argv[1] if len(sys.argv) > 1 else 'vesper_sheet.png')
