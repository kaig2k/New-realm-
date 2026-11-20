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
from shaded_kit import g, glow, robe, torso, arm, held, legs, head, eyes, staff, designs, sheet, chest, plate, pauldron

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
    M = {'oil': OIL, 'oild': OIL_D, 'pole': POLE, 'iron': IRON, 'brass': BRASS, 'flame': FLAME, 'ember': EMBER, 'void': VOID,
         'smoke': g([0x2a3038, 0x48505c, 0x6c7680])}
    m = Model(48, 56)
    cx = 22
    legs(m, cx, 38, 54, 3.4, 2.4, 'oild')
    robe(m, cx, 26, 48, 6, 10, 'oil', tatter=True, seed=31)                     # the long oilskin, torn at the hem
    torso(m, cx, 18, 34, 6.2, 'oil', folds(0.14, 3.0, 9))
    m.capsule((cx - 1, 20, 8), (cx + 1, 44, 9.5), 0.5, 0.6, 'oild')             # the coat's seam
    for k in range(3):
        m.sphere((cx + 1.8, 24 + k * 6, 9), 0.8, 'brass')
    # right arm: the long lighting pole, a hook and a wick at its tip
    arm(m, (cx + 6, 20, 3), (cx + 10, 27, 5), (cx + 12, 32, 8), 2.0, 'oil', 'oild', 1.5)
    held(m, 'R')
    staff(m, cx + 13, 2, 50, 'pole', z=8, r=0.7)
    m.chain([(cx + 13, 3, 8), (cx + 15.5, 0.8, 8.5), (cx + 17.5, 2.4, 8.5), (cx + 17, 5, 8.5)], [0.7, 0.7, 0.6, 0.5], 'iron')
    m.sphere((cx + 13, 2, 9), 1.1 + t * 0.4, 'flame')
    m.anchor('strike', (cx + 13, 2))
    m.part(None)
    # left arm: the lamp, smoking
    arm(m, (cx - 6, 20, 3), (cx - 10, 28, 5), (cx - 11, 34, 8), 2.0, 'oil', 'oild', 1.5)
    held(m, 'L')
    m.capsule((cx - 11, 35, 8), (cx - 11, 37, 8), 0.4, 0.4, 'iron')
    m.capsule((cx - 11, 38, 7), (cx - 11, 44, 7), 2.6, 2.6, 'brass', cut=45)
    m.sphere((cx - 11, 41, 9.5), 1.8 + t * 0.3, 'flame', 0.8, 1.1, 1)
    for k in range(3):
        m.capsule((cx - 13.6 + k * 2.6, 38, 9.6), (cx - 13.6 + k * 2.6, 44, 9.6), 0.3, 0.3, 'iron')
    m.sphere((cx - 12 - t, 31 - t, 4), 1.6, 'smoke')
    m.sphere((cx - 13 - t, 27.5 - t, 3), 1.2, 'smoke')
    m.anchor('cast', (cx - 11, 41))
    m.part(None)
    # head: lost in a sou'wester, two embers for eyes
    head(m, cx, 13, 4.2, 'void')
    m.sphere((cx, 10, 3), 7.8, 'oil', 1.1, 0.42, 0.9)                         # the brim, wide at the back
    m.sphere((cx, 8, 3), 4.8, 'oil', 1.0, 0.8, 0.9)
    m.capsule((cx - 4, 12, 7.6), (cx + 4, 12, 7.6), 0.3, 0.3, 'oild')
    eyes(m, cx, 13.5, 1.6, 8, 'ember', 0.55)
    m.part(None)
    return m, M


# ---------------------------------------------------------------- Ebb and Flow
def tide(name, deep, mid, light, foam):
    def fn(t):
        M = {'water': g([deep, mid, light, foam], spec=0.8), 'foam': g([light, foam, 0xffffff], spec=0.6),
             'mask': g([0x8a9aa4, 0xb8c8d0, 0xe8f4f8], spec=0.5), 'eye': glow(deep, foam, 0xffffff), 'void': VOID}
        m = Model(40, 46)
        cx = 20
        # a swirl of wave rising into a body: rings that narrow upward and lean with the tide
        sway = 1.2 if name == 'tide_ebb' else -1.2
        for k in range(6):
            y = 42 - k * 4.4
            w = 9.5 - k * 0.9
            off = math.sin(k * 0.9 + t * 1.6) * sway
            m.sphere((cx + off, y, k * 0.6), w, 'water', 1.0, 0.42, 0.8)
        for k in range(5):                                                   # foam curling off the crest of each ring
            a = k * 1.3 + t
            m.capsule((cx + math.cos(a) * 8, 40 - k * 4.4, 6), (cx + math.cos(a) * 10, 38 - k * 4.4, 6.5), 0.9, 0.3, 'foam')
        torso(m, cx, 14, 24, 5.4, 'water')
        for s in (-1, 1):                                                    # arms of water, ending in curling waves
            m.chain([(cx + s * 5, 16, 4), (cx + s * 10, 20, 5), (cx + s * 13, 16 - t, 6), (cx + s * 12, 12 - t, 6.5)],
                    [2.0, 1.7, 1.3, 0.8], 'water')
            m.sphere((cx + s * 12, 12 - t, 7), 1.2, 'foam')
        m.anchor('cast', (cx + 12, 12))
        head(m, cx, 9, 4.4, 'water')
        m.sphere((cx, 9.5, 6.8), 3.4, 'mask', 0.95, 1.15, 0.6)                # a pale mask
        eyes(m, cx, 9, 1.5, 8.5, 'eye', 0.6)
        m.capsule((cx - 1.2, 12.4, 8.6), (cx + 1.2, 12.4, 8.6), 0.3, 0.3, 'void')
        for k in range(5):                                                   # hair streaming back like spray
            a = math.pi + (k - 2) * 0.35
            m.capsule((cx, 6, 3), (cx + math.cos(a) * 2 + sway * 2, 1 + abs(k - 2) * 0.8, 2), 1.2, 0.4, 'foam' if k % 2 else 'water')
        return m, M
    return fn


# ---------------------------------------------------------------- the Bulwark
def bulwark(t):
    M = {'brass': BRASS, 'iron': IRON, 'glass': GLASS, 'barn': BARN, 'weed': WEED, 'eye': glow(0x30a0ff, 0xa0e0ff, 0xffffff),
         'suit': g([0x1a2228, 0x2c3a44, 0x445866, 0x5e7888]), 'shield': g([0x1c242c, 0x34424e, 0x506270, 0x748a9a], spec=0.6)}
    m = Model(56, 58)
    cx = 26
    legs(m, cx, 38, 56, 4.4, 4.0, 'suit')
    for s in (-1, 1):
        m.sphere((cx + s * 4.4, 54, 7), 3.6, 'iron', 1.1, 0.6, 1.2)            # lead boots
    chest(m, cx, 18, 40, 11, 9, 4, 'suit', bevel=3.0)
    plate(m, (cx, 20), (cx, 36), 7.5, 6, 8, 'brass', bevel=1.8)              # the breastplate
    for k in range(4):
        for s in (-1, 1):
            m.sphere((cx + s * 6.2, 22 + k * 4, 10.2), 0.6, 'iron')           # its rivets
    for s in (-1, 1):
        pauldron(m, cx + s * 11, 20, 6, 4.4, 6, 'brass', s)
    arm(m, (cx - 10, 21, 4), (cx - 14, 29, 5), (cx - 12, 35, 8), 3.0, 'suit', 'iron', 2.2)
    m.anchor('cast', (cx - 12, 35))

    def growth(x, y, h):
        if h[2] not in ('suit', 'brass'):
            return None
        v = vnoise(x * 0.45, y * 0.45, 17)
        return 'barn' if v > 0.86 else 'weed' if v < 0.1 else None
    m.paint(growth)
    # the diving helmet: a brass dome with a round glass port, the light of its eyes behind it
    m.part('head', (cx, 14))
    m.sphere((cx, 11, 4), 8.0, 'brass', 1.0, 0.95, 1.0)
    m.sphere((cx, 12, 10.5), 4.2, 'glass', 1.0, 1.0, 0.4)
    m.capsule((cx - 4.6, 12, 11.4), (cx + 4.6, 12, 11.4), 0.45, 0.45, 'iron')
    m.capsule((cx, 7.4, 11.4), (cx, 16.6, 11.4), 0.45, 0.45, 'iron')
    eyes(m, cx, 12, 1.6, 12, 'eye', 0.5)
    for s in (-1, 1):
        m.sphere((cx + s * 7.4, 12, 6), 1.8, 'brass')
    m.part(None)
    # the tower shield, held before it in the right hand
    m.part('armR', (cx + 10, 21))
    m.block(cx + 6, 18, cx + 20, 50, 13, 2.0, 'shield')
    m.capsule((cx + 13, 19, 15.5), (cx + 13, 49, 15.5), 0.8, 0.8, 'brass')
    m.capsule((cx + 6.5, 30, 15.5), (cx + 19.5, 30, 15.5), 0.8, 0.8, 'brass')
    for y in (21, 47):
        for x in (8, 18):
            m.sphere((cx + x, y, 15.2), 0.7, 'iron')
    m.anchor('strike', (cx + 13, 18))
    m.part(None)
    return m, M


# ---------------------------------------------------------------- the Drowned Keeper
def drowned_keeper(t):
    M = {'robe': g([0x0a1a24, 0x12283a, 0x1c3e56, 0x2a5876, 0x3c7896]), 'weed': WEED, 'barn': BARN, 'iron': IRON, 'brass': BRASS,
         'glass': g([0x1a3440, 0x2c5868, 0x4a8496, 0x7ab4c4], spec=0.9), 'light': glow(0xffa020, 0xffe070, 0xffffff, base=0.45), 'beam': glow(0xffd860, 0xfff4b0, base=0.5),
         'skin': g([0x2a4a48, 0x48706a, 0x6e968e]), 'void': VOID}
    m = Model(66, 66)
    cx = 33
    robe(m, cx, 28, 62, 9, 16, 'robe', tatter=True, seed=41)
    torso(m, cx, 22, 40, 9.5, 'robe', folds(0.12, 3.4, 13))

    def crust(x, y, h):
        """Barnacles and long weed where the sea has had it for three hundred years."""
        if h[2] != 'robe':
            return None
        v = vnoise(x * 0.35, y * 0.35, 43)
        if v > 0.8:
            return 'barn'
        return 'weed' if (v < 0.22 and (x + y * 0.2) % 4 < 2) else None
    m.paint(crust)
    for s in (-1, 1):                                                        # great arms, hands of grey-green skin
        arm(m, (cx + s * 9, 24, 3), (cx + s * 16, 34, 5), (cx + s * 15, 42, 9), 3.2, 'robe', 'skin', 2.6)
        for k in range(3):
            m.capsule((cx + s * (12 + k * 1.6), 30 + k * 3, 7), (cx + s * (12.5 + k * 1.6), 37 + k * 3, 7), 0.5, 0.3, 'weed')
    m.anchor('cast', (cx - 15, 42))
    m.anchor('strike', (cx + 15, 42))
    # the head: a lighthouse lantern, iron cage and brass cap, the great light inside
    m.part('head', (cx, 18))
    m.capsule((cx, 21, 4), (cx, 23, 4), 6.5, 7.5, 'iron', cut=24)             # the gallery round its neck
    m.capsule((cx - 8, 21, 8), (cx + 8, 21, 8), 0.6, 0.6, 'brass')
    m.capsule((cx, 8, 4), (cx, 19, 4), 5.6, 5.6, 'glass')                      # the lamp room's windows
    m.sphere((cx, 13.5, 9), 3.6 + t * 0.5, 'light')
    for k in range(5):
        x = cx - 5 + k * 2.5
        m.capsule((x, 8, 9.4), (x, 19, 9.6), 0.45, 0.45, 'iron')
    m.sphere((cx, 7, 4), 6.2, 'brass', 1.0, 0.5, 0.9)                         # the cap
    m.capsule((cx, 3, 6), (cx, 0.5, 6), 1.0, 0.4, 'brass')
    # a beam of light swinging out of the lamp room (to the right, then the left)
    side = 1 if t == 0 else -1
    m.capsule((cx + side * 6, 13.5, 10), (cx + side * 18, 10 + t * 3, 10), 1.2, 3.8, 'beam')
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
