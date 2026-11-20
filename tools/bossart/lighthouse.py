"""
The Drowned Lighthouse (Lairs.as): its three wardens, the twins Ebb and Flow, and the Keeper in the
lamp room; and the storm lanterns the Lamplighter fights beside. Modelled like the other shaded bosses.

The Lamplighter: a thin hunched figure in an oilskin coat and a sou'wester, a long lighting pole
with a hook in one hand and a smoking lamp in the other, its face lost in shadow but for two embers.
Ebb and Flow: two water spirits, one deep blue and one sea-green, each a swirl of wave rising into
a body with no legs, a pale mask of a face.
The Bulwark: a hulking diver in a brass helmet and riveted plate, a great tower shield before it.
The Drowned Keeper: the old lighthouse keeper grown into the lamp: a robed giant crusted with
barnacles and weed, a lantern for a head with the great light burning inside, a ring of lenses.
"""
import math
from sdfart import Model, rough, folds, vnoise
from shaded_kit import g, glow, robe, torso, arm, held, legs, head, eyes, staff, designs, sheet, chest, plate, pauldron, spike

VOID = g([0x040306, 0x0a080e])
OIL = g([0x3a3008, 0x5e4e10, 0x8a7418, 0xb89c2a, 0xdcc048], spec=0.6)      # a yellow oilskin
OIL_D = g([0x1e1a08, 0x34300e, 0x524a16])
POLE = g([0x1e140a, 0x34241a, 0x523a24])
IRON = g([0x14181e, 0x262e38, 0x3e4a58, 0x5e6e80], spec=0.7)
BRASS = g([0x4a3008, 0x86581a, 0xc48a30, 0xf0c060, 0xfff0b0], spec=0.9)
FLAME = glow(0xff7010, 0xffc040, 0xfff0a0, 0xffffff, base=0.35)
EMBER = glow(0xff4010, 0xffb040, 0xfff0c0)
WEED = g([0x0e2a14, 0x1a4422, 0x2a6234, 0x3e8048])
BARN = g([0x4a4a40, 0x7a786a, 0xaeaa96, 0xd8d4c0])
GLASS = glow(0x3a6878, 0x80c8d8, 0xd0f4ff, base=0.25)


# ---------------------------------------------------------------- the Lamplighter
def lamplighter(t):
    """A drowned lamplighter: tall and gaunt in a sodden, tattered coat and hood, a pale drowned face
    with burning eyes, a long hooked pole with its lamp hung from the hook."""
    M = {'coat': g([0x060a0c, 0x0e1a1e, 0x182c30, 0x244044, 0x34585a]), 'coatd': g([0x040607, 0x0a1214, 0x121e22]),
         'pole': POLE, 'iron': IRON, 'brass': BRASS, 'flame': FLAME, 'ember': glow(0xff5010, 0xffc040, 0xfff4c0, base=0.4),
         'face': g([0x2a3a38, 0x4a605c, 0x6e8a84, 0x9ab4ac]), 'void': VOID, 'weed': WEED}
    m = Model(50, 60)
    cx = 22
    robe(m, cx, 24, 56, 5.5, 11, 'coat', tatter=True, seed=37)                   # the long coat, torn to ribbons at the hem
    torso(m, cx, 17, 34, 5.6, 'coat', folds(0.16, 2.6, 9))
    m.capsule((cx - 6, 18, 2), (cx + 6, 18, 2), 3.2, 3.2, 'coat')                # stooped, bony shoulders
    for k in range(4):                                                           # weed hanging off it, dripping
        x = cx - 7 + k * 4.5
        m.capsule((x, 30 + k % 2 * 6, 8), (x + 0.5, 37 + k % 2 * 8, 8), 0.6, 0.3, 'weed')
    # right arm: long and thin, gripping the pole high
    arm(m, (cx + 5, 19, 3), (cx + 10, 22, 5), (cx + 13, 16, 8), 1.6, 'coat', 'face', 1.3)
    held(m, 'R')
    staff(m, cx + 13.5, 2, 58, 'pole', z=8, r=0.75)
    m.chain([(cx + 13.5, 3, 8), (cx + 16, 0.6, 8.5), (cx + 19.5, 1.5, 8.5), (cx + 20.5, 5, 8.5)], [0.75, 0.7, 0.6, 0.5], 'iron')
    # the lamp hung from the hook, swinging
    sw = (t - 0.5) * 1.6
    m.capsule((cx + 20.5, 5, 8.5), (cx + 20.5 + sw, 9, 8.5), 0.3, 0.3, 'iron')
    m.capsule((cx + 20.5 + sw, 10, 8), (cx + 20.5 + sw, 15, 8), 2.4, 2.4, 'brass', cut=16)
    m.sphere((cx + 20.5 + sw, 12.5, 10.5), 1.8 + t * 0.3, 'flame', 0.8, 1.1, 1)
    for k in range(3):
        m.capsule((cx + 18.4 + sw + k * 2.1, 10, 10.4), (cx + 18.4 + sw + k * 2.1, 15, 10.4), 0.3, 0.3, 'iron')
    m.sphere((cx + 20.5 + sw, 9.4, 8.5), 2.6, 'brass', 1.0, 0.4, 1.0)
    m.anchor('strike', (cx + 20.5, 12))
    m.part(None)
    # left arm: hanging long, claw-fingered
    arm(m, (cx - 5, 19, 3), (cx - 9, 28, 5), (cx - 10, 36, 7), 1.6, 'coat', 'face', 1.2)
    for k in range(3):
        m.capsule((cx - 10 + (k - 1) * 0.9, 37, 7), (cx - 10 + (k - 1) * 1.6, 40.5, 7), 0.4, 0.25, 'face')
    m.anchor('cast', (cx - 10, 38))
    # the head: a deep hood, a pale drowned face sunk in it, eyes like coals
    m.part('head', (cx, 13))
    m.sphere((cx, 11, 3), 6.6, 'coat', 0.95, 1.15, 1.0)
    m.capsule((cx, 4, 2), (cx - 2, 0.5, 1), 2.6, 0.6, 'coat')                     # the hood's limp peak
    m.sphere((cx, 12.5, 6.6), 3.6, 'void', 1.0, 1.15, 0.55)
    m.sphere((cx, 13.5, 7.2), 2.5, 'face', 0.9, 1.15, 0.7)
    m.sphere((cx - 1.1, 12.6, 9.2), 0.75, 'void'); m.sphere((cx + 1.1, 12.6, 9.2), 0.75, 'void')
    eyes(m, cx, 12.6, 1.1, 9.8, 'ember', 0.45)
    m.capsule((cx - 0.8, 15.6, 9), (cx + 0.8, 15.6, 9), 0.3, 0.3, 'void')
    m.part(None)
    return m, M


# ---------------------------------------------------------------- Ebb and Flow
def tide(name, deep, mid, light, foam):
    """A water wraith rising out of a breaking wave: the wave curls round its base, a hunched body of
    dark water, long clawed arms dragging down, a hollow face and hair of streaming foam."""
    def fn(t):
        M = {'water': g([deep, mid, light, foam], spec=0.8), 'dark': g([0x020408, deep, mid]), 'foam': g([light, foam, 0xffffff], spec=0.6),
             'eye': glow(foam, 0xffffff, base=0.5), 'void': VOID}
        m = Model(48, 50)
        s = 1 if name == 'tide_ebb' else -1
        cx = 24
        # the wave it rises from: a wide swell, its crest curling over on one side
        m.sphere((cx, 44, 1), 13, 'water', 1.0, 0.36, 0.8)
        m.capsule((cx - 4 * s, 36, 2), (cx - 12 * s, 40, 3), 4.0, 2.0, 'water')
        m.chain([(cx - 12 * s, 40, 3), (cx - 16 * s, 36, 5), (cx - 14 * s, 32.5, 7), (cx - 11 * s, 34, 8)], [2.2, 1.8, 1.4, 1.0], 'foam')
        for k in range(5):
            m.sphere((cx - 10 + k * 5, 40.5 + (k % 2), 7.5), 1.1, 'foam')
        # the body: a column of water narrowing as it rises, leaning forward
        m.capsule((cx, 40, 3), (cx + s * 1.2, 16, 5), 7.0, 5.0, 'water')
        m.capsule((cx + s * 1.2, 19, 6), (cx + s * 1.5, 12, 6), 5.4, 4.4, 'water')
        for k in range(3):                                                    # ribs of dark water
            y = 20 + k * 3
            m.capsule((cx - 3.8 + s, y, 10.4), (cx + 3.8 + s, y + 0.6, 10.4), 0.4, 0.4, 'dark')
        # long arms dragging down, hands of three long claws
        for sd in (-1, 1):
            hy = 32 + (t if sd == s else -t)
            hx = cx + sd * 15
            m.chain([(cx + sd * 6, 14, 5), (cx + sd * 12, 20, 6), (hx, hy, 8)], [2.6, 2.1, 1.7], 'water')
            for c in range(3):
                m.capsule((hx, hy + 1, 8.5), (hx + (c - 1) * 1.8 + sd * 1.2, hy + 6, 9), 0.7, 0.2, 'foam')
        m.anchor('cast', (cx + 15, 32))
        # the head: hunched low between the shoulders, a hollow face
        hx = cx + s * 2
        m.sphere((hx, 9, 6), 4.6, 'water', 0.95, 1.05, 1.0)
        m.sphere((hx, 10, 9.2), 3.0, 'dark', 1.0, 1.15, 0.5)
        eyes(m, hx, 9.2, 1.4, 10.6, 'eye', 0.55)
        m.capsule((hx - 1, 12.8, 10.2), (hx + 1, 13.4, 10.2), 0.4, 0.5, 'void')
        for k in range(6):                                                    # foam hair streaming back
            a = -math.pi / 2 - s * (0.5 + k * 0.32)
            L = 7 + k * 1.1 + t
            m.capsule((hx, 6, 3), (hx + math.cos(a) * L, 6 + math.sin(a) * L * 0.45 + k * 1.1, 2), 1.6 - k * 0.15, 0.35, 'foam' if k % 2 else 'water')
        return m, M
    return fn


# ---------------------------------------------------------------- the Bulwark
def bulwark(t):
    """A drowned knight of the harbour wall: rusted iron diving plate, a narrow-slitted helm with a
    cold light behind it, a huge tower shield bearing an anchor."""
    M = {'iron': g([0x0c0e10, 0x1c2024, 0x30363c, 0x4a525a, 0x6a747c], spec=0.6), 'rust': g([0x2a1006, 0x4a2210, 0x6e3818, 0x8e5228]),
         'brass': g([0x3a2608, 0x6a4a14, 0x9a7024, 0xc89a40], spec=0.8), 'eye': glow(0x2080ff, 0x90e0ff, 0xffffff, base=0.45),
         'void': VOID, 'barn': BARN, 'weed': WEED, 'shield': g([0x0a0c0e, 0x181c20, 0x2a3036, 0x404a52, 0x5a666e], spec=0.5)}
    m = Model(58, 60)
    cx = 25
    legs(m, cx, 38, 57, 4.6, 4.4, 'iron')
    for sd in (-1, 1):
        m.sphere((cx + sd * 4.6, 55, 7), 3.8, 'iron', 1.15, 0.6, 1.2)
    chest(m, cx, 17, 40, 12.5, 9, 4, 'iron', bevel=3.2)
    plate(m, (cx, 19), (cx, 37), 8.5, 6, 8, 'iron', bevel=2.0)
    m.capsule((cx - 9, 27, 10.4), (cx + 9, 27, 10.4), 0.6, 0.6, 'brass')          # brass bands round the plate
    m.capsule((cx - 8, 34, 10.4), (cx + 8, 34, 10.4), 0.6, 0.6, 'brass')
    for sd in (-1, 1):
        pauldron(m, cx + sd * 12, 19, 7, 5, 6, 'iron', sd)
        for k in range(3):
            spike(m, (cx + sd * (9 + k * 3), 15.5), (cx + sd * (9.6 + k * 3.4), 10.5 - k), 1.0, 7, 'iron')
    arm(m, (cx - 11, 21, 4), (cx - 15, 29, 5), (cx - 13, 36, 8), 3.2, 'iron', 'iron', 2.6)
    m.anchor('cast', (cx - 13, 36))

    def decay(x, y, h):
        if h[2] not in ('iron',):
            return None
        v = vnoise(x * 0.4, y * 0.4, 17)
        return 'rust' if 0.55 < v < 0.68 else 'barn' if v > 0.9 else 'weed' if v < 0.08 else None
    m.paint(decay)
    # the helm: a heavy iron dome sunk between the shoulders, one narrow lit slit
    m.part('head', (cx, 13))
    m.sphere((cx, 11, 4), 7.0, 'iron', 1.0, 1.05, 1.0, rough(0.06))
    m.capsule((cx - 4.2, 11.5, 10.6), (cx + 4.2, 11.5, 10.6), 1.0, 1.0, 'void')
    m.capsule((cx - 3.2, 11.5, 11.2), (cx + 3.2, 11.5, 11.2), 0.45, 0.45, 'eye')
    m.capsule((cx, 4.5, 9), (cx, 17, 10.5), 0.7, 0.9, 'brass')                    # a crest down the middle
    for sd in (-1, 1):
        m.sphere((cx + sd * 6.6, 13, 7), 1.4, 'brass')
    m.part(None)
    # the tower shield: taller than it is, an anchor wrought on it, its rim spiked
    m.part('armR', (cx + 10, 21))
    m.block(cx + 7, 14, cx + 23, 54, 13, 2.2, 'shield')
    m.capsule((cx + 7.4, 14.5, 15.6), (cx + 22.6, 14.5, 15.6), 0.7, 0.7, 'brass')
    m.capsule((cx + 7.4, 53.5, 15.6), (cx + 22.6, 53.5, 15.6), 0.7, 0.7, 'brass')
    ax = cx + 15
    m.capsule((ax, 22, 16.4), (ax, 44, 16.4), 1.0, 1.0, 'rust')                  # the anchor
    m.capsule((ax - 4, 25, 16.4), (ax + 4, 25, 16.4), 0.8, 0.8, 'rust')
    m.sphere((ax, 20.5, 16.4), 1.6, 'rust', 1, 1, 0.5)
    m.chain([(ax - 5.5, 40, 16.4), (ax - 3.5, 44, 16.4), (ax, 45.5, 16.4), (ax + 3.5, 44, 16.4), (ax + 5.5, 40, 16.4)], [0.8] * 5, 'rust')
    for y in (20, 34, 48):
        spike(m, (cx + 23, y), (cx + 26, y - 1), 0.9, 13, 'iron')
    m.anchor('strike', (ax, 14))
    m.part(None)
    return m, M


# ---------------------------------------------------------------- the Drowned Keeper
def drowned_keeper(t):
    """The keeper grown into his light: a hunched giant in a sodden cloak, anchor chains hanging off
    him, and for a head an iron lamp cage, its great lens burning inside."""
    M = {'robe': g([0x04080c, 0x0a1620, 0x122636, 0x1c3a50, 0x2a5270]), 'weed': WEED, 'barn': BARN,
         'iron': g([0x0a0c0e, 0x181c20, 0x2c3238, 0x464e56, 0x646e78], spec=0.6), 'brass': g([0x3a2608, 0x6a4a14, 0x9a7024, 0xd0a448], spec=0.8),
         'light': glow(0x803000, 0xe07010, 0xffb030, 0xffe890, base=0.35), 
         'skin': g([0x1a2a2a, 0x2e4644, 0x4a6662, 0x6e8c86]), 'void': VOID}
    m = Model(68, 70)
    cx = 34
    robe(m, cx, 30, 66, 10, 18, 'robe', tatter=True, seed=41)
    torso(m, cx, 22, 42, 11, 'robe', folds(0.12, 3.4, 13))
    m.capsule((cx - 11, 24, 2), (cx + 11, 24, 2), 5, 5, 'robe')                    # a great hunched back of shoulders

    def crust(x, y, h):
        if h[2] != 'robe':
            return None
        v = vnoise(x * 0.35, y * 0.35, 43)
        if v > 0.9:
            return 'barn'
        return 'weed' if (v < 0.2 and (x + y * 0.2) % 4 < 2) else None
    m.paint(crust)
    # anchor chains slung over it and trailing to the floor
    for sd in (-1, 1):
        pts = [(cx + sd * (6 + k * 1.6), 24 + k * 5, 10.5 + k * 0.2) for k in range(8)]
        m.chain(pts, [0.9] * 8, 'iron')
        for x, y, z in pts[1::2]:
            m.sphere((x, y, z + 0.4), 1.2, 'iron', 1, 0.7, 0.6)
    # long arms, huge drowned hands with claws
    for sd in (-1, 1):
        hy = 46 + (t if sd > 0 else -t)
        arm(m, (cx + sd * 11, 25, 3), (cx + sd * 18, 36, 5), (cx + sd * 17, hy, 9), 3.4, 'robe', 'skin', 3.0)
        for c in range(4):
            m.capsule((cx + sd * 17 + (c - 1.5) * 1.4, hy + 2, 10), (cx + sd * 17 + (c - 1.5) * 2.0, hy + 6, 10), 0.6, 0.2, 'skin')
    m.anchor('cast', (cx - 17, 46))
    m.anchor('strike', (cx + 17, 46))
    # the head: an iron lamp cage, its lens burning
    m.part('head', (cx, 18))
    m.capsule((cx, 22, 4), (cx, 24, 4), 7, 8, 'iron', cut=25)                      # the gallery rail round its neck
    for k in range(7):
        x = cx - 7 + k * 2.33
        m.capsule((x, 20, 9), (x, 23.5, 9), 0.35, 0.35, 'iron')
    m.capsule((cx - 8, 20, 9), (cx + 8, 20, 9), 0.45, 0.45, 'iron')
    m.capsule((cx, 8, 3), (cx, 19, 3), 5.8, 5.8, 'void')                           # the lamp room, dark but for the lens
    m.sphere((cx, 13.5, 8.6), 3.6 + t * 0.4, 'light', 1.0, 1.25, 0.6)
    for k in range(3):
        x = cx - 5 + k * 5
        m.capsule((x, 7.5, 12), (x, 19.5, 12), 0.7, 0.7, 'iron')
    m.sphere((cx, 7, 4), 7.0, 'iron', 1.0, 0.5, 0.9)                              # the cap, a vane on top
    m.sphere((cx, 5, 4), 3.4, 'brass', 1.0, 0.7, 0.9)
    m.capsule((cx, 3, 6), (cx, -2, 6), 0.7, 0.3, 'brass')
    m.capsule((cx, -1, 6), (cx + 4, -1.5, 6), 0.5, 0.3, 'brass')
    m.part(None)
    return m, M


# ---------------------------------------------------------------- storm lanterns
def lantern(lit):
    def fn(t):
        M = {'iron': IRON, 'brass': BRASS, 'glass': GLASS if not lit else g([0x6a3a10, 0xa8661c, 0xe0a040, 0xffd890], spec=0.8),
             'flame': FLAME, 'dark': g([0x1a1c22, 0x2c3038, 0x40464e]), 'post': g([0x1a1410, 0x2e241a, 0x463624])}
        m = Model(22, 34)
        cx = 11
        m.capsule((cx, 22, 2), (cx, 32, 2), 1.4, 1.8, 'post')                  # a short iron post
        m.sphere((cx, 32, 2), 4.0, 'iron', 1.1, 0.5, 1.0)
        m.capsule((cx, 10, 4), (cx, 20, 4), 4.2, 4.2, 'glass' if lit else 'dark')
        if lit:
            m.sphere((cx, 15.5, 8), 2.2 + t * 0.4, 'flame', 0.8, 1.2, 1)
        for k in range(3):
            m.capsule((cx - 3.4 + k * 3.4, 10, 8.2), (cx - 3.4 + k * 3.4, 20, 8.2), 0.4, 0.4, 'iron')
        m.capsule((cx, 21, 3), (cx, 22, 3), 4.8, 4.8, 'brass', cut=23)
        m.sphere((cx, 9, 4), 4.8, 'brass', 1.0, 0.45, 1.0)
        m.capsule((cx, 5.5, 5), (cx, 3, 5), 1.2, 0.6, 'iron')
        m.chain([(cx - 2, 3, 5), (cx, 1, 5), (cx + 2, 3, 5)], [0.4, 0.4, 0.4], 'iron')
        return m, M
    return fn


MODELS = [('lamplighter', lamplighter), ('tide_ebb', tide('tide_ebb', 0x0a2a6a, 0x1a58b8, 0x50a0f0, 0xb8e4ff)),
          ('tide_flow', tide('tide_flow', 0x0a4a48, 0x188a7c, 0x40d0b4, 0xb8fff0)), ('bulwark', bulwark), ('drowned_keeper', drowned_keeper),
          ('storm_lantern', lantern(False)), ('storm_lantern_lit', lantern(True))]


def all_designs():
    return designs(MODELS)


if __name__ == '__main__':
    import sys
    sheet(MODELS, sys.argv[1] if len(sys.argv) > 1 else '/tmp/lighthouse.png', 5)
