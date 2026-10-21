"""
Raid and finale bosses, shaded from solids (sdfart.py, shaded_kit.py), each keeping the look it
had: the Starfall Vault's Ignis, Archivist and Sovereign, Astraeon, the Sentinel, the Void Dragon,
the Zealot, the Phoenix, the Galecaller, the Witch, the Gearmind, the Colossus, the Matron and
the Kraken.
"""
import math
from sdfart import Model, rough, folds, scales, fur, vnoise
from shaded_kit import g, glow, robe, torso, arm, legs, head, eyes, hood, crown, staff, wing, flame, designs, sheet

VOID = g([0x040306, 0x0a080e])
BONE = g([0x3e3828, 0x6c6450, 0x9e967c, 0xcac4a8, 0xece8d4], spec=0.2)
SKIN = g([0x7a5644, 0xb08470, 0xdcb09a])


def lava_cracks(mat, into, seed=13, k=0.02):
    def f(x, y, h):
        if h[2] != mat:
            return None
        v = vnoise((x + vnoise(x * 0.2, y * 0.2, seed + 1) * 5) * 0.2, y * 0.2, seed)
        return into if abs(v - 0.5) < k and h[1][2] > 0.4 else None
    return f


def ignis(t):
    M = {'plate': g([0x0c0604, 0x1a0c08, 0x2a140c, 0x3e1e12, 0x582c1a], spec=0.5), 'lava': glow(0xc03008, 0xff7a20, 0xffc060, base=0.15),
         'fire': glow(0xd04010, 0xff9030, 0xffe0a0, base=0.1), 'horn': g([0x1a1410, 0x342a20, 0x544636])}
    m = Model(54, 58)
    R = rough(0.08, 0.3, 61)
    legs(m, 27, 36, 56, 5, 4.2, 'plate')
    torso(m, 27, 18, 36, 8.5, 'plate', R)
    m.sphere((27, 25, 9.5), 2.6 + t * 0.2, 'lava')
    for s in (-1, 1):
        m.sphere((27 + s * 10, 18, 2), 5, 'plate', 1.1, 0.9, 1, R)
        flame(m, 27 + s * 10, 15, 8, 4, ('fire', 'lava'), z=4, t=t)
        arm(m, (27 + s * 11, 20, 3), (27 + s * 14, 29, 5), (27 + s * 13, 35, 7), 3.0, 'plate', 'lava', 2.4)
    m.sphere((27, 10, 3), 5.6, 'plate', 0.95, 1.05, 1, R)
    m.capsule((23, 10.5, 8.4), (31, 10.5, 8.4), 0.8, 0.8, 'lava')
    for s in (-1, 1):
        m.chain([(27 + s * 4, 6, 4), (27 + s * 9, 3, 4), (27 + s * 10, -0.5, 4)], [1.6, 1.0, 0.3], 'horn')
    m.paint(lava_cracks('plate', 'lava', 63))
    return m, M


def archivist(t):
    M = {'robe': g([0x061a1c, 0x0c2a2e, 0x143e42, 0x1e585a, 0x2c7472]), 'hair': g([0x0a2a28, 0x164440, 0x24625c, 0x388a80]),
         'face': g([0x4a8a84, 0x7ab8ae, 0xa8e0d4]), 'glow': glow(0x20c0a0, 0x70ffe0, 0xd0fff4, base=0.15),
         'book': g([0x2a1a0c, 0x4a3018, 0x6c4826]), 'page': g([0xa8a088, 0xd8d0b8, 0xf6f0de]), 'wood': g([0x1e140c, 0x342416, 0x4c3622])}
    m = Model(50, 56)
    robe(m, 25, 18, 54, 6, 13, 'robe', tatter=True, seed=71)
    m.capsule((25, 8, -1), (25, 32, -2), 6, 4, 'hair')            # long hair down her back
    torso(m, 25, 17, 30, 5, 'robe')
    arm(m, (20, 19, 3), (17, 26, 5), (21, 29, 8), 1.8, 'robe', 'face', 1.3)
    arm(m, (30, 19, 3), (33, 26, 5), (29, 29, 8), 1.8, 'robe', 'face', 1.3)
    m.membrane([(18, 26), (25, 28), (32, 26), (31, 33), (25, 35), (19, 33)], 10, 'book', (0, -0.4))   # an open book
    m.membrane([(19.5, 27), (25, 29), (30.5, 27), (30, 32), (25, 33.5), (20, 32)], 10.5, 'page', (0, -0.4))
    for k in range(4):
        m.sphere((22 + k * 2, 30 - (k % 2), 12), 0.6, 'glow')     # glowing runes lifting off its pages
    m.capsule((39, 8, 6), (39, 54, 6), 0.9, 0.9, 'wood')          # a lantern on a crook
    m.capsule((39, 8, 6), (42, 6, 6), 0.8, 0.8, 'wood')
    m.sphere((42, 9.5 + t * 0.3, 7), 1.9, 'glow')
    head(m, 25, 11, 4.4, 'face')
    m.sphere((25, 8.6, 2.5), 5.2, 'hair', 1.05, 0.85, 1)
    eyes(m, 25, 11.4, 1.6, 7.6, 'glow', 0.6)
    return m, M


def sovereign(t):
    M = {'throne': g([0x2a2830, 0x403e48, 0x5a5664, 0x767284, 0x9490a4], spec=0.1), 'robe': g([0x1c0a24, 0x2e1238, 0x441c52, 0x5e2a70]),
         'bone': BONE, 'void': VOID, 'gold': g([0x5a420c, 0x9a7418, 0xd8a830, 0xffe080], spec=0.6),
         'gem': glow(0x8030d0, 0xc070ff, 0xf0d8ff), 'eye': glow(0x8030d0, 0xd0a0ff, base=0.1)}
    m = Model(54, 54)
    R = rough(0.06, 0.3, 81)
    # the throne: a high stone back and arms
    m.membrane([(10, 6), (44, 6), (46, 46), (8, 46)], -6, 'throne', (0, -0.1), R)
    for x in (10, 44):
        m.capsule((x, 6, -4), (x, 2, -4), 2.2, 1.2, 'throne')
    m.membrane([(6, 30), (48, 30), (50, 50), (4, 50)], 6, 'throne', (0, -0.7), R)
    # the skeleton king seated on it
    m.capsule((27, 18, 0), (27, 32, 2), 6.5, 7.5, 'robe', folds(0.1, 3, 5))
    for k in range(4):
        m.capsule((23, 20 + k * 2.4, 7.6), (31, 20 + k * 2.4, 7.6), 0.6, 0.6, 'bone')
    m.capsule((27, 19, 8.4), (27, 29, 8.4), 0.7, 0.7, 'bone')
    for s in (-1, 1):
        m.capsule((27 + s * 4, 32, 6), (27 + s * 5, 40, 9), 2.2, 1.8, 'robe')   # knees
        m.capsule((27 + s * 5, 40, 9), (27 + s * 5, 47, 10), 1.2, 1.0, 'bone')
        arm(m, (27 + s * 7, 19, 3), (27 + s * 10, 26, 5), (27 + s * 12, 31, 7), 1.6, 'robe', 'bone', 1.3)
    m.capsule((39, 10, 8), (39, 40, 8), 0.8, 0.8, 'gold')          # his sceptre
    m.sphere((39, 8.5 - t * 0.3, 9), 2.0, 'gem')
    head(m, 27, 12, 4.8, 'bone')
    eyes(m, 27, 12, 1.8, 7.6, 'void', 1.1)
    eyes(m, 27, 12.2, 1.8, 8.4, 'eye', 0.55)
    crown(m, 27, 7.6, 4, 'gold', spikes=5, tall=3, z=6, gem='gem')
    return m, M


def astraeon(t):
    M = {'star': glow(0xc08010, 0xffc030, 0xfff090, 0xffffff, base=0.15), 'face': g([0x9a7020, 0xd4a440, 0xfcd878]),
         'void': g([0x3a2008, 0x5a3410]), 'glint': glow(0x60a0ff, 0xc0e0ff, 0xffffff)}
    m = Model(56, 56)
    for k in range(8):                                             # eight points of light
        a = k * math.pi / 4 + t * 0.06
        ln = 26 if k % 2 == 0 else 17
        m.capsule((28, 28, 0), (28 + math.cos(a) * ln, 28 + math.sin(a) * ln, 0), 5.5 if k % 2 == 0 else 4, 0.4, 'star')
    m.sphere((28, 28, 2), 10, 'star', 1, 1, 0.9)
    m.sphere((28, 28, 6), 7, 'face', 1, 1.05, 0.8)
    eyes(m, 28, 27, 2.6, 9.6, 'void', 0.9)
    m.capsule((25.8, 32, 11.6), (30.2, 32, 11.6), 0.5, 0.5, 'void')
    for k in range(10):                                            # glints circling him
        a = k * math.pi / 5 + t * 0.3
        m.sphere((28 + math.cos(a) * 24, 28 + math.sin(a) * 24, 10), 0.8, 'glint')
    return m, M


def sentinel(t):
    M = {'steel': g([0x14181e, 0x222832, 0x343c4a, 0x4a5466, 0x68748a, 0x8e9ab0], spec=0.7), 'core': glow(0x2080d0, 0x60c0ff, 0xd0f0ff),
         'brass': g([0x5a420c, 0x9a7418, 0xd8a830, 0xffe080], spec=0.6), 'eye': glow(0xc0a010, 0xffe040, 0xffffa0)}
    m = Model(48, 54)
    R = rough(0.05, 0.3, 91)
    m.capsule((24, 34, 0), (24, 50 + t * 0.4, 0), 8, 0.6, 'steel', R)   # it floats on a tapering point
    m.sphere((24, 24, 0), 11, 'steel', 1.15, 0.85, 0.9, R)
    m.capsule((14, 26, 9), (34, 26, 9), 1.8, 1.8, 'core')         # a band of light round its middle
    for s in (-1, 1):
        m.sphere((24 + s * 14, 22, 2), 4.6, 'steel', 1, 1, 1, R)  # arms of armour
        m.capsule((24 + s * 15, 26, 3), (24 + s * 16, 34, 4), 2.6, 2.0, 'steel')
    m.sphere((24, 12, 2), 6, 'steel', 1.1, 0.9, 1, R)
    eyes(m, 24, 12, 2.2, 6.4, 'eye', 0.8)
    for s in (-1, 1):
        m.capsule((24 + s * 3, 7, 3), (24 + s * 4, 1.5, 3), 1.1, 0.4, 'brass')
    for k in range(2):
        m.sphere((24 + (k * 2 - 1) * 20, 8 + t, 6), 1.2, 'core')
    return m, M


def void_dragon(t):
    M = {'hide': g([0x0c0618, 0x180c2c, 0x261446, 0x381e64, 0x502e88, 0x7048b0], spec=0.3), 'wing': g([0x0a0412, 0x140a24, 0x221238, 0x321c52], rimk=0.7),
         'bone': g([0x3a2a5a, 0x5a4488, 0x8466b8]), 'glow': glow(0xa040e0, 0xe070ff, 0xffd0ff, base=0.15),
         'horn': g([0x5a5070, 0x8a80a4, 0xc0b8d8])}
    m = Model(64, 54)
    S = scales(2.3, 0.1)
    for s in (-1, 1):                                              # great spread wings
        sh, wr = (32 + s * 5, 20, -4), (32 + s * 24, 6, -4)
        m.capsule(sh, wr, 1.8, 1.1, 'bone')
        tips = [(32 + s * 31, 16), (32 + s * 29, 27), (32 + s * 21, 32)]
        m.membrane([(sh[0], sh[1]), (wr[0], wr[1]), tips[0], (32 + s * 26, 21), tips[1], (32 + s * 23, 27), tips[2], (32 + s * 9, 30)], -5, 'wing', (s * 0.3, -0.2))
        for tp in tips:
            m.capsule(wr, (tp[0], tp[1], -4.5), 0.9, 0.35, 'bone')
    m.chain([(32, 38, 0), (36, 44, 1), (30, 49, 2), (24, 46, 2), (22, 51, 2)], [4.5, 3.6, 2.8, 2.0, 1.2], 'hide', S)   # tail
    m.sphere((32, 28, 0), 9.5, 'hide', 1.0, 1.1, 0.9, S)
    m.capsule((32, 23, 8.8), (32, 36, 8.6), 2.6, 2.0, 'bone')     # belly plates
    m.chain([(32, 20, 2), (32, 14, 4), (32, 10, 6)], [5, 4.2, 3.6], 'hide', S)   # neck
    m.sphere((32, 8, 7), 4.8, 'hide', 1.05, 0.9, 1)
    m.capsule((32, 10, 8), (32, 15, 11), 2.6, 1.6, 'hide')        # snout toward us
    eyes(m, 32, 7.4, 2.6, 9.4, 'glow', 0.8)
    m.capsule((30, 15, 12.4), (34, 15, 12.4), 0.6, 0.6, 'glow')
    for s in (-1, 1):
        m.chain([(32 + s * 3, 5, 5), (32 + s * 6, 1.5, 4), (32 + s * 7, -0.5, 3)], [1.3, 0.8, 0.3], 'horn')
    return m, M


def zealot(t):
    M = {'robe': g([0x1e0406, 0x34080c, 0x500e14, 0x701820, 0x922430]), 'void': VOID, 'eye': glow(0xd0a010, 0xffe040, base=0.1),
         'trim': g([0x5a420c, 0x9a7418, 0xd8a830]), 'steel': g([0x5a6474, 0x8e9aac, 0xd0dae8], spec=0.9), 'skin': SKIN}
    m = Model(44, 54)
    robe(m, 22, 18, 52, 6, 12, 'robe', 'trim', tatter=True, seed=101)
    torso(m, 22, 17, 30, 5.5, 'robe')
    for s in (-1, 1):
        arm(m, (22 + s * 6, 19, 3), (22 + s * 10, 23, 5), (22 + s * 13, 18, 7), 1.8, 'robe', 'skin', 1.3)
        m.capsule((22 + s * 13, 17, 8), (22 + s * 14, 11, 8), 0.8, 0.3, 'steel')   # a curved knife in each hand
    # a tall pointed hood
    m.capsule((22, 12, 1), (22, -0.5, 0), 7, 0.6, 'robe', folds(0.1, 3, 7))
    m.sphere((22, 14, 4), 5, 'void', 0.95, 1.1, 0.7)
    eyes(m, 22, 13.6, 1.7, 6.6, 'eye', 0.6)
    return m, M


def phoenix(t):
    M = {'out': glow(0xa02006, 0xe04a10, 0xff8a20, 0xffc050, base=0.05), 'in': glow(0xff9a30, 0xffd060, 0xfff4c0, base=0.2),
         'beak': g([0x8a5a10, 0xd09a28, 0xffd060]), 'eye': g([0x200802, 0x401006])}
    m = Model(64, 54)
    flap = t * 2
    for s in (-1, 1):                                              # wings of flame, feather by feather
        for k in range(6):
            a = -0.35 - k * 0.16
            x0, y0 = 32 + s * 5, 20
            ln = 26 - k * 2
            m.capsule((x0, y0 + k * 1.2, -2 - k * 0.2), (x0 + s * math.cos(a) * ln, y0 + math.sin(a) * ln * 0.6 + k * 3 - flap, -2 - k * 0.2), 2.6, 0.4, 'out')
    for k in range(5):                                             # tail plumes
        m.capsule((32, 34, 0), (32 + (k - 2) * 4, 52 - abs(k - 2) * 2, 0), 2.4, 0.4, 'out')
    m.sphere((32, 26, 2), 7.5, 'out', 0.9, 1.25, 0.9)
    m.sphere((32, 26, 5), 5, 'in', 0.9, 1.2, 0.8)
    m.sphere((32, 13, 5), 4.4, 'out', 1, 1, 1)
    m.capsule((32, 14, 9), (32, 18, 9.5), 1.4, 0.3, 'beak')
    eyes(m, 32, 12.4, 2.0, 7.6, 'eye', 0.7)
    for k in range(3):
        m.capsule((32 + (k - 1) * 2, 10, 5), (32 + (k - 1) * 4, 3 - (k == 1) * 2, 5), 1.0, 0.3, 'out')   # crest
    return m, M


def galecaller(t):
    M = {'robe': g([0x0e2244, 0x18366a, 0x244e90, 0x346cb8, 0x4a8cd8]), 'skin': g([0x8a8a9a, 0xc0c2d4, 0xe8eaf6]),
         'ice': g([0x5a8ab4, 0x8ec0e8, 0xd0ecff, 0xffffff], spec=0.7), 'wind': glow(0x6ab0e0, 0xc0e8ff, 0xffffff, base=0.2),
         'eye': glow(0x2060c0, 0x80c0ff), 'hair': g([0x6a80a0, 0x9ab0cc, 0xd0e0f4])}
    m = Model(52, 56)
    robe(m, 26, 20, 54, 5, 12, 'robe', 'ice', tatter=False, seed=111)
    torso(m, 26, 18, 30, 4.6, 'robe')
    for s in (-1, 1):                                              # both arms raised, calling the wind
        arm(m, (26 + s * 5, 19, 3), (26 + s * 10, 15, 5), (26 + s * 13, 8, 7), 1.6, 'robe', 'skin', 1.2)
    for k in range(8):
        a = k * 0.8 + t * 0.5
        r = 18 + (k % 3) * 3
        m.capsule((26 + math.cos(a) * r, 30 + math.sin(a) * r * 0.6, 10), (26 + math.cos(a + 0.35) * r, 30 + math.sin(a + 0.35) * r * 0.6, 10), 0.5, 0.3, 'wind')
    head(m, 26, 12, 4.0, 'skin')
    m.sphere((26, 10, 2), 4.6, 'hair', 1.05, 0.9, 1)
    eyes(m, 26, 12.4, 1.5, 7.4, 'eye', 0.5)
    crown(m, 26, 8, 3.5, 'ice', spikes=5, tall=4.5, z=5)
    return m, M


def witch(t):
    M = {'robe': g([0x0e0816, 0x1a1028, 0x28183e, 0x3a2456, 0x52346e]), 'skin': g([0x2a4a20, 0x4a7034, 0x6e9a50]),
         'pot': g([0x0a0a0c, 0x18181e, 0x2a2a32, 0x40404a], spec=0.5), 'brew': glow(0x40b020, 0x90ff50, 0xe0ffb0, base=0.15),
         'wood': g([0x2a1a0c, 0x4a3018, 0x6c4826]), 'eye': glow(0xc0d020, 0xf8ff80), 'straw': g([0x6a5a2a, 0xa89040, 0xd8c060])}
    m = Model(50, 58)
    robe(m, 24, 20, 44, 5.5, 10, 'robe', tatter=True, seed=121)
    torso(m, 24, 18, 30, 4.8, 'robe')
    arm(m, (19, 20, 3), (16, 27, 6), (20, 32, 9), 1.7, 'robe', 'skin', 1.3)
    arm(m, (29, 20, 3), (33, 26, 5), (36, 22, 7), 1.7, 'robe', 'skin', 1.3)
    m.capsule((37, 8, 6), (37, 54, 6), 0.9, 0.9, 'wood')           # her broom-staff
    for k in range(5):
        m.capsule((37, 50, 7), (35 + k, 56, 7), 0.6, 0.4, 'straw')
    m.sphere((24, 48, 6), 10, 'pot', 1.1, 0.75, 1)                 # the cauldron, bubbling
    m.sphere((24, 41, 9.5), 8.2, 'brew', 1.05, 0.25, 0.6)
    for k in range(4):
        m.sphere((19 + k * 3.4, 39 - (k + t) % 2 * 1.6, 12), 1.0, 'brew')
    head(m, 24, 12, 4.0, 'skin')
    m.capsule((24, 13, 7.6), (25.8, 15.5, 8.5), 0.9, 0.5, 'skin')  # a long nose
    eyes(m, 24, 11.4, 1.5, 7.4, 'eye', 0.55)
    m.sphere((24, 8.5, 2.5), 9, 'robe', 1.0, 0.24, 1.0)            # her hat: a wide brim, a crooked peak
    m.capsule((24, 8, 2.5), (27, -0.5, 1.5), 4.2, 0.4, 'robe')
    return m, M


def gearmind(t):
    M = {'brass': g([0x3a2808, 0x5e4210, 0x8a6418, 0xb88a26, 0xe0b440, 0xffe080], spec=0.7), 'iron': g([0x16181e, 0x262a32, 0x3a3e4a, 0x545a68], spec=0.6),
         'eye': glow(0x20a040, 0x60ff90, 0xd0ffe0), 'void': VOID}
    m = Model(54, 52)
    for s in (-1, 1):                                              # spidery mechanical legs
        for k in range(2):
            m.capsule((27 + s * 8, 30 + k * 4, -2), (27 + s * (18 + k * 3), 38 + k * 2, -2), 1.4, 1.0, 'iron')
            m.capsule((27 + s * (18 + k * 3), 38 + k * 2, -2), (27 + s * (20 + k * 3), 48, -1), 1.0, 0.5, 'iron')
    m.sphere((27, 25, 0), 14, 'brass', 1, 1, 0.5, rough(0.04))     # the great gear
    for k in range(12):
        a = k * math.pi / 6 + t * 0.12
        m.capsule((27 + math.cos(a) * 13, 25 + math.sin(a) * 13, 1), (27 + math.cos(a) * 17, 25 + math.sin(a) * 17, 1), 2.0, 1.8, 'brass')
    m.sphere((27, 25, 5), 9, 'iron', 1, 1, 0.5)
    m.sphere((27, 25, 8), 5.4, 'void', 1, 1, 0.5)
    m.sphere((27, 25, 10), 4, 'eye', 1, 1, 0.6)
    m.sphere((27, 25, 12.4), 1.4, 'void', 0.8, 1.2, 0.5)
    return m, M


def colossus(t):
    M = {'rock': g([0x060608, 0x0e0e14, 0x18181f, 0x24242e, 0x343444, 0x48485c], spec=0.4), 'glow': glow(0x6020c0, 0xa050ff, 0xe0c0ff, base=0.15)}
    m = Model(62, 56)
    R = rough(0.12, 0.3, 131)
    legs(m, 31, 38, 54, 7, 5.5, 'rock')
    m.sphere((31, 26, 0), 15, 'rock', 1.2, 0.95, 0.85, R)
    for s in (-1, 1):
        m.sphere((31 + s * 17, 20, 3), 7.5, 'rock', 1, 1, 1, R)
        m.capsule((31 + s * 19, 24, 4), (31 + s * 21, 38, 6), 5.6, 4.8, 'rock', R)
        m.sphere((31 + s * 21, 41, 7), 5.6, 'rock', 1, 0.9, 1, R)
    m.sphere((31, 11, 4), 6, 'rock', 1.2, 0.8, 1, R)
    m.capsule((27, 11.5, 9.2), (35, 11.5, 9.2), 0.8, 0.8, 'glow')
    m.sphere((31, 25, 12), 2.8 + t * 0.2, 'glow')
    m.paint(lava_cracks('rock', 'glow', 133, 0.016))
    return m, M


def matron(t):
    M = {'robe': g([0x1a0204, 0x300408, 0x4c0810, 0x6c101a, 0x902028]), 'skin': g([0x8a6a6a, 0xc09c9a, 0xe8c8c4]),
         'gold': g([0x5a1a0c, 0x9a3a18, 0xd86a30, 0xffa060], spec=0.5), 'blood': glow(0x900810, 0xe02030, 0xff8080, base=0.15),
         'hair': g([0x1a0406, 0x30080c, 0x4a1016]), 'eye': glow(0xc01020, 0xff4040)}
    m = Model(54, 56)
    robe(m, 27, 18, 54, 6, 15, 'robe', 'gold', tatter=True, seed=141)
    torso(m, 27, 17, 30, 5.2, 'robe')
    for s in (-1, 1):                                              # a high collar like wings
        m.membrane([(27 + s * 4, 18), (27 + s * 14, 6), (27 + s * 13, 18)], 1, 'robe', (s * 0.5, -0.3))
        arm(m, (27 + s * 5, 19, 3), (27 + s * 9, 25, 5), (27 + s * 11, 20, 7), 1.7, 'robe', 'skin', 1.3)
    m.sphere((38.5, 18 - t * 0.3, 8.5), 1.8, 'blood')              # a drop of blood held in her palm
    m.capsule((27, 9, -1), (27, 26, -2), 5, 3.4, 'hair')
    head(m, 27, 12, 4.2, 'skin')
    eyes(m, 27, 12.4, 1.6, 7.8, 'eye', 0.55)
    crown(m, 27, 8, 3.6, 'gold', spikes=5, tall=3.5, z=6, gem='blood')
    for k in range(5):
        m.sphere((14 + k * 6.5, 50 + (k % 2) * 2, 12), 0.8, 'blood')
    return m, M


def kraken(t):
    M = {'skin': g([0x1e0a26, 0x34123e, 0x4e1c5a, 0x6c2a7c, 0x8e3ca0, 0xb058c4], spec=0.4), 'sucker': g([0x8a5a8a, 0xc08ac0, 0xe8b8e8]),
         'eye': glow(0xc0a010, 0xffe040, 0xffffa0), 'pupil': VOID}
    m = Model(62, 54)
    for k in range(8):                                             # eight tentacles, curling
        side = -1 if k < 4 else 1
        j = k % 4
        x0 = 31 + side * (2 + j * 2.5)
        pts = [(x0, 30, 2), (x0 + side * (6 + j * 3), 38 + j, 3), (x0 + side * (10 + j * 4), 46 - j, 3 + j * 0.2), (x0 + side * (8 + j * 5), 51 - j * 2 + t * (1 if k % 2 else -1), 3)]
        m.chain(pts, [3.4, 2.6, 1.8, 0.8], 'skin')
    m.sphere((31, 18, 0), 13, 'skin', 1, 1.15, 0.9, rough(0.06))   # the great mantle
    m.sphere((31, 28, 4), 9, 'skin', 1.1, 0.6, 0.9)
    for s in (-1, 1):
        m.sphere((31 + s * 5.5, 24, 10), 3.2, 'eye', 1.1, 0.9, 0.6)
        m.sphere((31 + s * 5.5, 24, 12.2), 1.4, 'pupil', 0.6, 1.3, 0.5)

    def suckers(x, y, h):
        return 'sucker' if h[2] == 'skin' and y > 34 and vnoise(x * 0.8, y * 0.8, 3) > 0.8 else None
    m.paint(suckers)
    return m, M


MODELS = [('vault_ignis', ignis), ('vault_archivist', archivist), ('vault_sovereign', sovereign), ('astraeon', astraeon),
          ('sentinel', sentinel), ('void_dragon', void_dragon), ('zealot', zealot), ('phoenix', phoenix), ('galecaller', galecaller),
          ('witch', witch), ('gearmind', gearmind), ('colossus', colossus), ('matron', matron), ('kraken', kraken)]


def all_designs():
    return designs(MODELS)


if __name__ == '__main__':
    import sys
    sheet(MODELS[:7], sys.argv[1])
    sheet(MODELS[7:], sys.argv[2])
