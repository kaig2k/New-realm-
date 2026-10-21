"""
The lairs' masters (Lairs.as), modelled like the other shaded bosses and rigged for posed.py: the
Tesseract, Kragg the Forgemaster, Glacia, the Hollow Prince, Rendmaw, Ankhamun, Admiral Brine,
Pearlmaw, Ossarion, the Quarry Heart, Ignaria, the three Crone sisters and the Leviathan; and the
canopic jar that keeps Ankhamun's heart.
"""
import math
from sdfart import Model, rough, folds, scales, fur, vnoise
from shaded_kit import (g, glow, robe, torso, arm, held, legs, head, eyes, hood, crown, staff, wing, flame, designs, sheet,
                        chest, plate, pauldron, rock, spike)

VOID = g([0x040306, 0x0a080e])
SKIN = g([0x7a5640, 0xb4846a, 0xe0b498])


# ---------------------------------------------------------------- the Tesseract
def tesseract(t):
    M = {'edge': glow(0x8030d0, 0xc060ff, 0xf0c0ff, base=0.2), 'face': g([0x4a1048, 0x7a1a78, 0xb02aa8, 0xd84ad0, 0xf088ec], gamma=1.0),
         'side': g([0x24082a, 0x3e0e44, 0x5e1866, 0x82248a]), 'core': glow(0xc040ff, 0xff90ff, 0xffffff, base=0.3), 'eye': glow(0xff60ff, 0xffffff)}
    m = Model(58, 58)
    cx, cy = 29, 28

    def cube(s, a, z0, tilt=0.42):
        """The 8 corners of a cube of half-size s turned by a, seen from a little above."""
        pts = []
        for x in (-1, 1):
            for y in (-1, 1):
                for z in (-1, 1):
                    rx = x * math.cos(a) - z * math.sin(a)
                    rz = x * math.sin(a) + z * math.cos(a)
                    pts.append((cx + rx * s, cy + y * s * 0.86 - rz * s * tilt, z0 + rz * s))
        return pts
    edges = [(0, 1), (2, 3), (4, 5), (6, 7), (0, 2), (1, 3), (4, 6), (5, 7), (0, 4), (1, 5), (2, 6), (3, 7)]
    # the outer frame: a cage of light that turns slowly (the rig spins it a little more)
    m.part('hem0', (cx, cy))
    for a_, b_ in edges:
        P = cube(20, 0.5 + t * 0.12, -2)
        m.capsule(P[a_], P[b_], 1.1, 1.1, 'edge')
    # the inner cube: solid, three faces like the Overlord's own, a burning eye on its edge
    m.part('head', (cx, cy + 10))
    c2, h = cy + 1, 13
    top = [(cx, c2 - h), (cx + h, c2 - h * 0.5), (cx, c2), (cx - h, c2 - h * 0.5)]
    left = [(cx - h, c2 - h * 0.5), (cx, c2), (cx, c2 + h * 1.05), (cx - h, c2 + h * 0.55)]
    right = [(cx, c2), (cx + h, c2 - h * 0.5), (cx + h, c2 + h * 0.55), (cx, c2 + h * 1.05)]
    m.membrane(top, 14, 'face', (-0.3, -0.85), rough(0.05))
    m.membrane(left, 14, 'face', (-0.85, 0.15), rough(0.05))
    m.membrane(right, 14, 'side', (0.8, 0.2), rough(0.05))
    for q0, q1 in ((top[0], top[1]), (top[1], top[2]), (top[2], top[3]), (top[3], top[0]), (left[2], top[2]), (left[0], left[3]), (right[1], right[2]), (left[3], left[2]), (right[3], right[2])):
        m.capsule((q0[0], q0[1], 15), (q1[0], q1[1], 15), 0.55, 0.55, 'edge')
    cy = c2 + 3
    m.sphere((cx, cy + 1, 22), 3.4 + t * 0.3, 'core')
    m.mark(cx - 1, cy + 1, 'eye', 2, 1)
    m.anchor('cast', (cx, cy + 1)); m.anchor('handR', (cx + 20, cy)); m.anchor('handL', (cx - 20, cy))
    m.part(None)
    return m, M


# ---------------------------------------------------------------- Kragg the Forgemaster
def forgemaster(t):
    M = {'skin': g([0x5a2a18, 0x86422a, 0xb0603e, 0xd88a5e]), 'beard': g([0x2a1206, 0x4a220c, 0x6e3614, 0x94501e]),
         'leather': g([0x1e120a, 0x34200f, 0x4c3018, 0x664424]), 'iron': g([0x16161c, 0x2a2a34, 0x44444f, 0x62626e, 0x8a8a98], spec=0.6, facet=8),
         'hot': glow(0xa02a08, 0xff6010, 0xffb040, 0xfff0a0, base=0.2), 'gold': g([0x5a420c, 0x9a7418, 0xd8a830, 0xffe080], spec=0.6),
         'eye': glow(0xff8020, 0xffe0a0), 'wood': g([0x2a1a0e, 0x4a3018, 0x6c4826])}
    m = Model(62, 60)
    R = rough(0.06, 0.3, 61)
    legs(m, 31, 40, 58, 6, 4.4, 'leather')
    for s in (-1, 1):                                              # heavy iron boots
        m.part('legR' if s > 0 else 'legL', (31 + s * 6, 40))
        m.block(31 + s * 6.6 - 5, 53, 31 + s * 6.6 + 5, 58.5, 4, 1.5, 'iron')
    m.part(None)
    torso(m, 31, 20, 40, 11, 'skin', R)
    m.slab([(22, 26), (40, 26), (42, 44), (20, 44)], 9, 1.6, 'leather', folds(0.08, 3, 4))   # the smith's apron
    m.capsule((20, 33, 10), (42, 33, 10), 1.2, 1.2, 'iron')                                    # its belt
    m.block(28.5, 31, 33.5, 35, 11.5, 0.6, 'gold')
    for s in (-1, 1):
        arm(m, (31 + s * 11, 21, 4), (31 + s * 15, 30, 6), (31 + s * 14, 38, 8), 4.0, 'skin', 'skin', 3.2)
        m.part('arm' + ('R' if s > 0 else 'L'), (31 + s * 11, 21))
        m.capsule((31 + s * 14.4, 33, 9), (31 + s * 14, 36.5, 9.5), 3.4, 3.4, 'hot')              # bracers glowing from the forge
        m.sphere((31 + s * 12, 21, 6), 5.2, 'iron', 1.1, 0.8, 1)                                 # pauldrons
        m.part(None)
    # his hammer, in his right hand
    held(m, 'R')
    m.capsule((45, 14, 10), (45, 46, 10), 1.3, 1.3, 'wood')
    m.block(39, 6, 51, 16, 11, 2.2, 'iron')
    m.block(43.2, 9, 46.8, 13, 13.6, 0.6, 'hot')
    m.anchor('strike', (45, 10)); m.anchor('cast', (45, 10))
    m.part(None)
    head(m, 31, 13, 6.2, 'skin')
    m.capsule((31, 16, 9), (31, 30, 10), 6.0, 2.6, 'beard', fur(0.12))                         # a great braided beard
    for s in (-1, 1):
        m.capsule((31 + s * 3, 26, 11), (31 + s * 3, 33, 11), 1.2, 0.9, 'beard')
        m.sphere((31 + s * 3, 33.5, 11.5), 1.1, 'gold')
    eyes(m, 31, 12, 2.3, 9, 'eye', 0.8)
    m.sphere((31, 9, 4), 7, 'iron', 1.05, 0.62, 1.0)                                          # a horned iron helm
    for s in (-1, 1):
        m.chain([(31 + s * 6, 8, 5), (31 + s * 11, 4, 5), (31 + s * 12, -1, 4)], [1.8, 1.2, 0.4], 'gold')
    m.part(None)
    return m, M


# ---------------------------------------------------------------- Glacia, Mother of Wyrms
def glacia(t):
    M = {'hide': g([0x1a3a5a, 0x2a5a86, 0x3e7aac, 0x5c9ccc, 0x86c0e8, 0xc0e8ff], spec=0.4), 'wing': g([0x2a5a86, 0x4a86b4, 0x7ab4dc, 0xb8e0ff], rimk=0.7),
         'ice': g([0x5a8ab4, 0x8ec0e8, 0xd0ecff, 0xffffff], spec=0.8, facet=8), 'belly': g([0x8ab4d4, 0xbcd8ec, 0xe8f6ff]),
         'eye': glow(0x40a0ff, 0xc0f0ff, 0xffffff)}
    m = Model(66, 58)
    S = scales(2.4, 0.1)
    for s in (-1, 1):                                              # wings of ice, spread
        sh, wr = (33 + s * 6, 22, -4), (33 + s * 25, 5, -4)
        m.part('wingR' if s > 0 else 'wingL', sh[:2])
        m.anchor('hand' + ('R' if s > 0 else 'L'), wr[:2])
        m.capsule(sh, wr, 1.9, 1.1, 'ice')
        tips = [(33 + s * 32, 18), (33 + s * 29, 29), (33 + s * 20, 34)]
        m.membrane([(sh[0], sh[1]), (wr[0], wr[1]), tips[0], (33 + s * 27, 23), tips[1], (33 + s * 24, 29), tips[2], (33 + s * 9, 31)], -5, 'wing', (s * 0.3, -0.2))
        for tp in tips:
            m.capsule(wr, (tp[0], tp[1], -4.5), 0.9, 0.35, 'ice')
    m.part('tail', (33, 40))
    m.chain([(33, 40, 0), (40, 46, 1), (36, 52, 2), (27, 53, 2), (22, 49, 2)], [5, 4, 3, 2, 1], 'hide', S)
    m.part(None)
    for s in (-1, 1):                                              # her legs, folded beneath
        m.part('legR' if s > 0 else 'legL', (33 + s * 7, 38))
        m.capsule((33 + s * 7, 38, 4), (33 + s * 9, 49, 6), 3.4, 2.6, 'hide', S)
        for c in (-1, 0, 1):
            m.capsule((33 + s * 9 + c * 1.5, 49, 7), (33 + s * 9 + c * 2.2, 52.5, 8), 0.8, 0.3, 'ice')
    m.part(None)
    m.sphere((33, 31, 0), 10.5, 'hide', 1.0, 1.1, 0.9, S)
    m.capsule((33, 25, 9.5), (33, 39, 9), 3.0, 2.4, 'belly')
    for k in range(4):                                             # crystals along her back
        spike(m, (33 + (k - 1.5) * 4, 24 - abs(k - 1.5)), (33 + (k - 1.5) * 5.5, 16 - abs(k - 1.5) * 1.5), 1.4, -1, 'ice')
    m.part('head', (33, 23))
    m.chain([(33, 22, 2), (33, 16, 4), (33, 11, 6)], [5.4, 4.6, 4.0], 'hide', S)
    m.sphere((33, 8.5, 7), 5.2, 'hide', 1.05, 0.9, 1)
    m.capsule((33, 10.5, 8), (33, 16, 11.5), 2.8, 1.7, 'hide')
    eyes(m, 33, 7.6, 2.7, 9.5, 'eye', 0.8)
    m.capsule((31, 15.6, 12.8), (35, 15.6, 12.8), 0.5, 0.5, 'belly')
    for k in range(5):                                             # a crown of ice horns
        a = math.radians(-150 + k * 30)
        spike(m, (33 + math.cos(a) * 4, 6 + math.sin(a) * 2.5), (33 + math.cos(a) * 9, 4 + math.sin(a) * 7), 1.0, 9, 'ice')
    m.anchor('cast', (33, 16))
    m.part(None)
    return m, M


# ---------------------------------------------------------------- the Hollow Prince
def hollow_prince(t):
    M = {'plate': g([0x1a2a1c, 0x2a4430, 0x3e6448, 0x5a8a66, 0x80b48a], spec=0.6, facet=8), 'cape': g([0x0e1410, 0x18241a, 0x243828, 0x34503a]),
         'wisp': g([0x2a6a3a, 0x4aa060, 0x80d890, 0xc0ffc8], gamma=1.0), 'face': g([0x6a8a70, 0x9ac0a0, 0xd0f0d4]),
         'gold': g([0x5a420c, 0x9a7418, 0xd8a830, 0xffe080], spec=0.6), 'blade': glow(0x30a040, 0x80ff90, 0xe0ffe8, base=0.25),
         'eye': glow(0x40e060, 0xc0ffc0), 'void': VOID}
    m = Model(52, 58)
    m.membrane([(15, 17), (37, 17), (43, 50), (34, 54), (26, 50), (18, 54), (9, 50)], -7, 'cape', (0, -0.1), folds(0.12, 3.4, 9))
    # no legs: he fades into a trail of green mist
    for k in range(5):
        m.part('hem%d' % (k % 2), (19 + k * 3.5, 38))
        m.capsule((19 + k * 3.5, 38, 2), (20 + k * 3.2 + (k - 2) * 0.8, 50 + (k % 2) * 3, 2), 3.0, 0.5, 'wisp')
    m.part(None)
    chest(m, 26, 18, 38, 8, 6, 3, 'plate', 2.4)
    m.capsule((20, 37, 4), (32, 37, 4), 1.0, 1.0, 'gold')
    for s in (-1, 1):
        arm(m, (26 + s * 8, 19, 4), (26 + s * 11, 27, 6), (26 + s * 10, 34, 8), 2.1, 'plate', 'plate', 1.7)
        m.part('arm' + ('R' if s > 0 else 'L'), (26 + s * 8, 19))
        pauldron(m, 26 + s * 8.5, 19, 5, 5, 7, 'plate', s, 2.0)
        m.part(None)
    held(m, 'R')                                                  # a sword of ghostfire
    m.slab([(35, 36), (37, 36), (37.6, 52), (36, 55), (34.4, 52)], 12, 0.8, 'blade')
    m.block(32, 34, 40, 36, 13, 0.5, 'gold')
    m.anchor('strike', (36, 52))
    m.part(None)
    head(m, 26, 11, 4.4, 'face')
    m.sphere((26, 12.5, 7.5), 3.2, 'void', 1.0, 0.7, 0.4)
    eyes(m, 26, 12, 1.6, 8, 'eye', 0.6)
    crown(m, 26, 7.4, 4.4, 'gold', spikes=5, tall=3.8, z=5, gem='eye')       # his father's crown, too big for him
    m.part(None)
    return m, M


# ---------------------------------------------------------------- Rendmaw, Alpha of the Brood
def rendmaw(t):
    M = {'hide': g([0x2a0604, 0x4a0c08, 0x6e140c, 0x96221a, 0xbc3a2a], spec=0.2), 'bone': g([0x6a5e48, 0x9a8e70, 0xcac0a0, 0xece6d0], facet=8),
         'maw': g([0x1a0204, 0x3a0608]), 'tooth': g([0xcac0a0, 0xfff8e8]), 'eye': glow(0xffa020, 0xffe080), 'fur': g([0x1a0806, 0x2e1008, 0x461a0e])}
    m = Model(66, 54)
    F = fur(0.12)
    # hind legs and haunches behind
    for s in (-1, 1):
        m.part('legR' if s > 0 else 'legL', (33 + s * 12, 34))
        m.sphere((33 + s * 13, 36, -3), 7, 'hide', 1, 0.9, 1, F)
        m.capsule((33 + s * 14, 40, -2), (33 + s * 16, 51, -1), 3.2, 2.4, 'hide', F)
    m.part(None)
    m.sphere((33, 28, 0), 13, 'hide', 1.25, 0.95, 0.9, F)                         # the hunched body
    for k in range(6):                                                             # bone spikes down its back
        a = math.radians(-160 + k * 28)
        spike(m, (33 + math.cos(a) * 11, 24 + math.sin(a) * 9), (33 + math.cos(a) * 18, 21 + math.sin(a) * 15), 1.6, 4, 'bone')
    # front legs: the rig's arms (they rear up and rake)
    for s in (-1, 1):
        S = 'R' if s > 0 else 'L'
        m.part('arm' + S, (33 + s * 10, 30))
        m.capsule((33 + s * 10, 30, 6), (33 + s * 12, 46, 8), 4.0, 3.0, 'hide', F)
        m.sphere((33 + s * 12.4, 48.5, 9), 3.4, 'hide', 1.2, 0.7, 1, F)
        for c in (-1, 0, 1):
            m.capsule((33 + s * 12.4 + c * 1.6, 50, 10), (33 + s * 12.4 + c * 2.0, 53, 10.5), 0.8, 0.3, 'bone')
        m.anchor('hand' + S, (33 + s * 12.4, 50))
    m.part('head', (33, 28))
    m.sphere((33, 30, 9), 7, 'hide', 1.15, 0.95, 1, F)                            # the head, low and forward
    m.capsule((27, 25, 11), (39, 25, 11), 2.2, 2.2, 'fur')                         # a heavy brow
    eyes(m, 33, 27, 3.2, 12, 'eye', 1.0)
    for s in (-1, 1):                                                              # tusks
        m.chain([(33 + s * 5, 33, 12), (33 + s * 9, 31, 12), (33 + s * 10, 27, 11)], [1.5, 1.0, 0.3], 'bone')
    m.part('jaw', (33, 32), 'head')
    m.sphere((33, 35.5, 12), 4.6, 'maw', 1.2, 0.6, 0.5)                           # the open maw
    for k in range(5):
        m.capsule((29.5 + k * 1.75, 33.4, 14), (29.5 + k * 1.75, 35, 14), 0.5, 0.15, 'tooth')
        m.capsule((30.4 + k * 1.75, 38.4, 14), (30.4 + k * 1.75, 37, 14), 0.5, 0.15, 'tooth')
    m.anchor('cast', (33, 35))
    m.part(None)
    return m, M


# ---------------------------------------------------------------- Ankhamun the Undying (and his canopic jars)
def pharaoh(t):
    M = {'wrap': g([0x5a4e3a, 0x8a7c60, 0xb4a684, 0xd8ccac, 0xf0e8d0]), 'seam': g([0x3a3226, 0x5a4e3a, 0x7a6c54, 0x9a8c70]), 'gold': g([0x6a4808, 0xa87812, 0xe0b028, 0xfff09a], spec=0.7),
         'blue': g([0x0c1a4a, 0x163276, 0x2450aa, 0x3a74d8]), 'void': VOID, 'eye': glow(0x20b0ff, 0x8ee8ff, 0xffffff),
         'staff': g([0x2a1a0c, 0x4a3018, 0x6c4826])}
    m = Model(52, 60)
    W = folds(0.16, 2.2, 21)
    legs(m, 26, 36, 58, 4, 3.0, 'wrap')
    robe(m, 26, 30, 50, 6, 9, 'wrap', tatter=True, seed=23)
    torso(m, 26, 18, 34, 6.4, 'wrap', W)

    def wraps(x, y, h):
        """Thin shadowed seams where the bandages overlap, winding round him."""
        if h[2] != 'wrap':
            return None
        return 'seam' if (y + x * 0.45 + vnoise(x * 0.2, y * 0.2, 5) * 2) % 3.2 < 0.75 else None
    m.paint(wraps)
    m.sphere((26, 21, 7), 7.6, 'gold', 1.0, 0.45, 0.7)                            # the broad collar
    for s in (-1, 1):
        arm(m, (26 + s * 7, 20, 3), (26 + s * 10, 28, 5), (26 + s * 8, 33, 8), 2.2, 'wrap', 'wrap', 1.6)
    staff(m, 36, 8, 56, 'staff', z=8, r=0.9)                                     # his crook
    m.chain([(36, 8, 8), (36, 4, 8.5), (39.5, 3.5, 8.5), (40.5, 6.5, 8.5)], [1.0, 1.0, 0.9, 0.7], 'gold')
    m.part(None)
    head(m, 26, 12, 4.4, 'wrap')
    m.capsule((26, 8, 1), (26, 16, 1), 6, 7.4, 'blue', cut=19)                    # the nemes headdress
    for s in (-1, 1):
        m.capsule((26 + s * 5.2, 13, 4), (26 + s * 5.8, 22, 4.5), 2.0, 1.8, 'blue', cut=23)

    def stripes(x, y, h):
        return 'gold' if h[2] == 'blue' and int(y / 1.8) % 2 == 0 else None
    m.paint(stripes)
    m.sphere((26, 12.5, 6), 4.2, 'wrap', 0.9, 1.1, 1.0)
    m.capsule((21, 8.6, 6.5), (31, 8.6, 6.5), 1.0, 1.0, 'gold')
    m.capsule((26, 8.2, 8), (26, 4.6, 8), 0.9, 0.4, 'gold')
    m.sphere((26, 13, 9.4), 2.6, 'void', 1.2, 0.5, 0.4)
    eyes(m, 26, 13, 1.6, 9, 'eye', 0.6)
    m.capsule((26, 17, 10), (26, 20.5, 9.5), 0.8, 0.6, 'gold')                    # the false beard
    m.part(None)
    return m, M


def canopic_jar(t):
    M = {'jar': g([0x5a4a30, 0x8a7450, 0xb8a078, 0xe0cca0], spec=0.3), 'gold': g([0x6a4808, 0xa87812, 0xe0b028, 0xfff09a], spec=0.7),
         'blue': g([0x163276, 0x2450aa, 0x3a74d8]), 'glow': glow(0x20b0ff, 0x8ee8ff, 0xffffff, base=0.25), 'void': VOID}
    m = Model(24, 30)
    m.sphere((12, 19, 0), 7.5, 'jar', 1.0, 1.1, 0.9, rough(0.05))
    m.capsule((12, 26, 0), (12, 28, 0), 5, 5.5, 'jar', cut=29)
    m.capsule((6, 16, 6), (18, 16, 6), 0.8, 0.8, 'gold')
    m.capsule((6.4, 22, 6), (17.6, 22, 6), 0.8, 0.8, 'blue')
    m.sphere((12, 19, 7), 1.8 + t * 0.2, 'glow')                                 # a heart glowing through it
    # the lid: a jackal's head
    m.sphere((12, 9, 2), 4.6, 'jar', 1.0, 0.9, 1)
    m.capsule((12, 9.5, 5), (12, 12, 7), 2.0, 1.2, 'jar')
    for s in (-1, 1):
        spike(m, (12 + s * 2.2, 6), (12 + s * 3.4, 1), 1.0, 5, 'gold')
    m.mark(10, 8, 'glow'); m.mark(13, 8, 'glow')
    return m, M


# ---------------------------------------------------------------- Admiral Brine
def admiral(t):
    M = {'coat': g([0x081428, 0x0e2040, 0x16305e, 0x22467e, 0x30609e]), 'gold': g([0x5a420c, 0x9a7418, 0xd8a830, 0xffe080], spec=0.6),
         'skin': g([0x3a5a50, 0x5a8072, 0x86a898, 0xb0ccbe]), 'hat': g([0x060608, 0x101016, 0x1c1c24, 0x2c2c36]),
         'weed': g([0x0e2a14, 0x1a4422, 0x2a6234]), 'barn': g([0x5a5a4c, 0x8a8a74, 0xbab8a0]), 'steel': g([0x5a6474, 0x8e9aac, 0xd0dae8, 0xffffff], spec=0.9),
         'eye': glow(0x20d0c0, 0xa0fff0), 'boot': g([0x0a0806, 0x1a140e, 0x2e2418])}
    m = Model(54, 60)
    legs(m, 26, 38, 58, 3.8, 3.2, 'boot')
    m.capsule((26, 20, 0), (26, 44, 0), 7.5, 10.5, 'coat', folds(0.1, 3.2, 14), cut=46)    # a long admiral's coat
    for s in (-1, 1):
        m.capsule((26 + s * 3.4, 21, 8.2), (26 + s * 4.5, 44, 9.6), 0.6, 0.6, 'gold')        # its gold piping
        for k in range(3):
            m.sphere((26 + s * 2.2, 25 + k * 4, 8.6), 0.7, 'gold')
    m.capsule((18, 32, 9.4), (34, 32, 9.4), 1.0, 1.0, 'hat')

    def sea(x, y, h):
        """Barnacles and weed grown over him in the deep."""
        if h[2] not in ('coat', 'hat'):
            return None
        v = vnoise(x * 0.4, y * 0.4, 31)
        return 'barn' if v > 0.84 else 'weed' if v < 0.12 else None
    m.paint(sea)
    for s in (-1, 1):
        arm(m, (26 + s * 7, 21, 3), (26 + s * 11, 29, 5), (26 + s * 10, 35, 8), 2.4, 'coat', 'skin', 1.6)
        m.part('arm' + ('R' if s > 0 else 'L'), (26 + s * 7, 21))
        m.sphere((26 + s * 8, 20.5, 5), 3.4, 'gold', 1.3, 0.6, 1)                             # epaulettes
        for k in range(4):
            m.capsule((26 + s * (6 + k * 1.2), 22, 6), (26 + s * (6 + k * 1.2), 24.5, 6), 0.35, 0.3, 'gold')
        m.part(None)
    held(m, 'R')                                                                              # his sabre
    m.capsule((37, 35, 9), (46, 20, 9), 0.9, 0.4, 'steel')
    m.capsule((35, 36.5, 9.5), (38.6, 33, 9.5), 0.8, 0.8, 'gold')
    m.anchor('strike', (46, 20))
    m.part(None)
    head(m, 26, 13, 4.6, 'skin')
    eyes(m, 26, 13, 1.8, 8, 'eye', 0.6)
    m.capsule((22, 16.4, 8.4), (30, 16.4, 8.4), 0.9, 0.9, 'weed')                              # a beard of weed
    m.capsule((26, 16.5, 8.6), (26, 21, 8.6), 1.8, 0.6, 'weed')
    m.sphere((26, 8.2, 3), 9.5, 'hat', 1.0, 0.3, 0.8)                                          # a bicorne
    m.sphere((26, 6.2, 3), 5.4, 'hat', 1.2, 0.62, 0.8)
    m.capsule((17, 8.6, 6), (35, 8.6, 6), 0.6, 0.6, 'gold')
    m.sphere((26, 6, 6.5), 1.4, 'gold')
    m.part(None)
    return m, M


# ---------------------------------------------------------------- Pearlmaw
def pearlmaw(t):
    M = {'shell': g([0x2a1e2a, 0x4a3448, 0x6e5068, 0x96708e, 0xc09ab4], spec=0.3), 'inner': g([0x8a6a7a, 0xc09aaa, 0xecc8d4, 0xffeef4], spec=0.5),
         'crab': g([0x0e2a2a, 0x184442, 0x24605c, 0x348680, 0x4cae9e], spec=0.4), 'claw': g([0x14403c, 0x226660, 0x349488, 0x5cc0ae], spec=0.6),
         'pearl': glow(0xc0d0e8, 0xf0f4ff, 0xffffff, base=0.35), 'eye': glow(0x203018, 0xd0f040, 0xf8ff9a)}
    m = Model(66, 54)
    # the great clam behind it, open: the upper half thrown back, the lower half a bowl
    m.part('hem0', (33, 30))
    m.sphere((33, 16, -6), 18, 'shell', 1.15, 0.62, 0.35, rough(0.05))

    def ridges(x, y, h):
        if h[2] != 'shell':
            return None
        a = math.atan2(y - 30, x - 33)
        return 'inner' if (a * 9) % 1.0 < 0.12 else None
    m.paint(ridges)
    m.part(None)
    m.sphere((33, 30, -3), 17, 'inner', 1.1, 0.5, 0.35)
    m.sphere((33, 26, 6), 5.2 + t * 0.3, 'pearl')                                   # the pearl, glowing
    # the crab in the clam: legs, body, eyestalks, two great claws (its arms)
    for k in range(3):
        for s in (-1, 1):
            m.part('legR' if (k + (s > 0)) % 2 else 'legL', (33 + s * 7, 38))
            m.capsule((33 + s * (7 + k * 2), 38 + k, 6), (33 + s * (14 + k * 3), 47 + k * 1.5, 7), 1.6, 1.0, 'crab')
    m.part(None)
    m.sphere((33, 38, 8), 9, 'crab', 1.2, 0.7, 1, rough(0.05))
    m.part('head', (33, 34))
    for s in (-1, 1):
        m.capsule((33 + s * 3, 33, 10), (33 + s * 4, 26 - t * 0.5, 11), 0.8, 0.6, 'crab')
        m.sphere((33 + s * 4, 25.4 - t * 0.5, 11.6), 1.6, 'eye')
    m.anchor('cast', (33, 26))
    for s in (-1, 1):
        S = 'R' if s > 0 else 'L'
        m.part('arm' + S, (33 + s * 9, 37))
        m.capsule((33 + s * 9, 37, 11), (33 + s * 17, 33, 13), 2.8, 2.6, 'claw')
        m.sphere((33 + s * 21, 30.5, 14), 4.8, 'claw', 1.2, 0.9, 1)
        m.capsule((33 + s * 21, 27, 15), (33 + s * 25, 22, 15), 1.7, 0.6, 'claw')
        m.capsule((33 + s * 23, 31, 15), (33 + s * 27, 28, 15), 1.4, 0.5, 'claw')
        m.anchor('hand' + S, (33 + s * 24, 26))
    m.part(None)
    return m, M


# ---------------------------------------------------------------- Ossarion the Bone Lord
def ossarion(t):
    M = {'bone': g([0x4a4436, 0x7c7460, 0xaea68c, 0xd8d2b8, 0xf2eedc], spec=0.15), 'cloak': g([0x0e0814, 0x1a1024, 0x2a1a3a, 0x3e2854]),
         'soul': glow(0x6a20c0, 0xb070ff, 0xe8d0ff, base=0.2), 'void': VOID, 'iron': g([0x1a1a20, 0x34343e, 0x56566a, 0x8a8a9e], spec=0.6),
         'eye': glow(0x8a40ff, 0xe0c0ff)}
    m = Model(62, 62)
    m.membrane([(18, 18), (44, 18), (50, 56), (40, 60), (31, 56), (22, 60), (12, 56)], -7, 'cloak', (0, -0.1), folds(0.12, 3.6, 11))
    legs(m, 31, 40, 60, 4.6, 2.0, 'bone')
    m.capsule((31, 20, 1), (31, 40, 1), 1.6, 1.6, 'bone')                                   # the spine
    for k in range(5):                                                                     # a cage of ribs, soulfire inside
        y = 22 + k * 3.2
        for s in (-1, 1):
            m.chain([(31, y, 3), (31 + s * 6, y + 1, 6), (31 + s * 8, y + 3.5, 5)], [0.9, 0.8, 0.6], 'bone')
    m.sphere((31, 29, 4), 4.4 + t * 0.3, 'soul')
    m.sphere((31, 41, 3), 6, 'bone', 1.2, 0.5, 0.8)                                         # the pelvis
    for s in (-1, 1):
        m.sphere((31 + s * 9, 20, 4), 4, 'bone', 1.1, 0.8, 1)
        arm(m, (31 + s * 10, 20, 4), (31 + s * 13, 29, 6), (31 + s * 12, 37, 8), 1.5, 'bone', 'bone', 1.6)
    # his scythe
    held(m, 'R')
    m.capsule((44, 8, 10), (44, 58, 10), 1.0, 1.0, 'iron')
    m.chain([(44, 8, 11), (38, 4, 11), (30, 4, 11), (24, 8, 11)], [1.8, 1.6, 1.2, 0.3], 'iron')
    m.anchor('strike', (26, 7))
    m.part(None)
    head(m, 31, 12, 6.2, 'bone')
    m.sphere((31, 17.5, 7), 4.2, 'bone', 1.0, 0.5, 0.9)                                     # the jaw
    for s in (-1, 1):
        m.sphere((31 + s * 2.6, 11.5, 9.5), 1.9, 'void', 1, 1.1, 0.5)
    eyes(m, 31, 11.6, 2.6, 10, 'eye', 0.8)
    for k in range(5):
        m.capsule((28 + k * 1.5, 16.2, 10.5), (28 + k * 1.5, 18, 10.5), 0.5, 0.5, 'bone')
    crown(m, 31, 7, 5, 'iron', spikes=7, tall=4, z=6, gem='soul')
    m.part(None)
    return m, M


# ---------------------------------------------------------------- the Quarry Heart
def quarry_heart(t):
    from angular_shaded import golem, cracks
    M = {'rock': g([0x08060c, 0x120e18, 0x1e1828, 0x2c2440, 0x3e3458, 0x544874], facet=8, spec=0.4),
         'crystal': g([0x4a2a8a, 0x6a40c0, 0x9a6aff, 0xd0b0ff], facet=8, spec=0.8), 'core': glow(0x9060ff, 0xd0a0ff, 0xffffff, base=0.25)}
    m = Model(62, 60)
    golem(m, 'rock', 31, 15, seed=171)
    for s in (-1, 1):                                                                      # crystals grown from his shoulders and back
        m.part('arm' + ('R' if s > 0 else 'L'), (31 + s * 16, 18))
        for k in range(3):
            spike(m, (31 + s * (13 + k * 3), 16 - k), (31 + s * (15 + k * 4), 4 - k * 2), 1.8 - k * 0.3, 10, 'crystal')
    m.part(None)
    m.slab([(25, 18), (37, 18), (39, 28), (31, 33), (23, 28)], 10, 2.4, 'crystal')         # the heart in his chest, cut glass
    m.sphere((31, 24.5, 13), 3.6 + t * 0.3, 'core')
    m.part('head', (31, 14))
    m.capsule((27, 9.5, 12), (35, 9.5, 12), 0.9, 0.9, 'core')
    m.anchor('cast', (31, 24))
    m.part(None)
    m.paint(cracks('rock', 'core', 177, 0.016))
    return m, M


# ---------------------------------------------------------------- Ignaria, Mother of Phoenixes
def ignaria(t):
    M = {'out': glow(0xa02006, 0xe04a10, 0xff8a20, 0xffc050, base=0.05), 'in': glow(0xff9a30, 0xffd060, 0xfff4c0, base=0.2),
         'skin': g([0x8a3a1a, 0xc06a3a, 0xf0a060]), 'gold': g([0x6a4808, 0xa87812, 0xe0b028, 0xfff09a], spec=0.7), 'eye': glow(0xffffff, 0xffffff)}
    m = Model(68, 60)
    for s in (-1, 1):                                                                      # great wings of flame
        m.part('wing' + ('R' if s > 0 else 'L'), (34 + s * 5, 20))
        for k in range(7):
            a = -0.25 - k * 0.17
            x0, y0 = 34 + s * 5, 20
            ln = 30 - k * 2.2
            m.capsule((x0, y0 + k, -3 - k * 0.2), (x0 + s * math.cos(a) * ln, y0 + math.sin(a) * ln * 0.75 + k * 3.2, -3 - k * 0.2), 2.8, 0.4, 'out')
        m.anchor('hand' + ('R' if s > 0 else 'L'), (34 + s * 30, 8))
    m.part(None)
    # a gown of fire
    for k in range(6):
        m.part('hem%d' % (k % 2), (27 + k * 2.8, 38))
        m.capsule((27 + k * 2.8, 36, 2), (25 + k * 3.6, 56 - abs(k - 2.5) * 1.5, 2), 3.2, 0.5, 'out')
    m.part(None)
    m.capsule((34, 22, 3), (34, 40, 3), 4.4, 6.5, 'out')
    m.capsule((34, 24, 6), (34, 38, 6.5), 2.6, 3.8, 'in')
    torso(m, 34, 19, 28, 3.8, 'skin')
    m.sphere((34, 21, 6.5), 4.2, 'gold', 1.0, 0.45, 0.7)                                    # a gold collar
    for s in (-1, 1):
        arm(m, (34 + s * 4, 20, 3), (34 + s * 8, 25, 5), (34 + s * 11, 21, 7), 1.4, 'skin', 'skin', 1.1)
    head(m, 34, 13, 3.8, 'skin')
    eyes(m, 34, 13, 1.5, 8, 'eye', 0.5)
    for k in range(5):                                                                     # hair of fire, a crest of flame
        a = math.radians(-150 + k * 30)
        m.capsule((34 + math.cos(a) * 3, 11 + math.sin(a) * 3, 3), (34 + math.cos(a) * 7, 8 + math.sin(a) * 8, 2), 1.5, 0.3, 'out')
    crown(m, 34, 9.6, 3, 'gold', spikes=3, tall=2.5, z=6)
    m.part(None)
    return m, M


# ---------------------------------------------------------------- the Crone sisters (Mother Hexis's)
CRONES = {
    'crone_bramble': {'robe': [0x0e1a0a, 0x1a2e12, 0x2a461c, 0x3c6028], 'skin': [0x4a5a2a, 0x6e844a, 0x94ac6a], 'mark': (0x40a020, 0x9aff6a), 'item': 'thorn'},
    'crone_bog': {'robe': [0x08161a, 0x0e262c, 0x183c42, 0x26545a], 'skin': [0x3a5a50, 0x5a8072, 0x86a898], 'mark': (0x20a080, 0x80ffe0), 'item': 'ladle'},
    'crone_ash': {'robe': [0x1a0a06, 0x2e120a, 0x461c10, 0x642a18], 'skin': [0x5a4a40, 0x84705e, 0xb09884], 'mark': (0xd04010, 0xffb040), 'item': 'torch'},
}


def crone(name):
    C = CRONES[name]

    def model(t):
        M = {'robe': g(C['robe']), 'skin': g(C['skin']), 'hair': g([0x6a6a6a, 0x9a9a9a, 0xcacaca, 0xeeeeee]),
             'wood': g([0x2a1a0c, 0x4a3018, 0x6c4826]), 'mark': glow(*C['mark'], base=0.2), 'eye': glow(*C['mark'])}
        m = Model(48, 56)
        robe(m, 24, 22, 54, 5, 11, 'robe', tatter=True, seed=hash(name) % 97)
        torso(m, 24, 20, 32, 4.6, 'robe')
        m.sphere((24, 21, -1), 6, 'robe', 1.1, 0.8, 1)                                      # a hunched back
        arm(m, (19, 21, 3), (16, 28, 5), (18, 33, 8), 1.6, 'robe', 'skin', 1.3)
        arm(m, (29, 21, 3), (33, 27, 5), (35, 23, 7), 1.6, 'robe', 'skin', 1.3)
        held(m, 'R')
        if C['item'] == 'thorn':
            m.chain([(36, 54, 6), (36, 30, 7), (37, 14, 7), (35, 8, 7)], [1.0, 1.0, 0.9, 0.5], 'wood')
            for k in range(5):
                m.capsule((36.5, 14 + k * 7, 7.5), (38.5 + (k % 2) * -4, 12 + k * 7, 7.5), 0.4, 0.15, 'mark')
            m.anchor('cast', (35, 8))
        elif C['item'] == 'ladle':
            m.capsule((36, 18, 7), (38, 44, 7), 0.7, 0.7, 'wood')
            m.sphere((38.4, 46, 7.5), 2.4, 'wood', 1, 0.6, 1)
            m.sphere((38.4, 45.4, 8.6), 1.6, 'mark', 1, 0.4, 1)
            m.anchor('cast', (38, 45))
        else:
            m.capsule((36, 28, 7), (36, 12, 7), 0.9, 0.7, 'wood')
            m.sphere((36, 10, 8), 2.2 + t * 0.2, 'mark', 0.9, 1.3, 1)
            m.anchor('cast', (36, 9))
        m.part(None)
        head(m, 24, 13, 4.2, 'skin')
        m.capsule((24, 13.5, 7.6), (26.5, 17, 8.8), 1.0, 0.4, 'skin')                        # a hooked nose
        eyes(m, 24, 12.4, 1.6, 7.4, 'eye', 0.55)
        m.capsule((24, 11, 1), (24, 30, -1), 5.4, 3.2, 'hair')                               # long grey hair
        hood(m, 24, 11.5, 6.2, 'robe', 'robe')
        m.part(None)
        return m, M
    return model


# ---------------------------------------------------------------- the Leviathan
def leviathan(t):
    M = {'hide': g([0x10081e, 0x1e0e36, 0x2e1650, 0x42206e, 0x5a2e90, 0x7a44b4], spec=0.4), 'belly': g([0x5a4a8a, 0x8a78b8, 0xbcaee0]),
         'fin': g([0x2a1050, 0x46207a, 0x6a38a8], rimk=0.7), 'water': g([0x0a2a5a, 0x1a4a8a, 0x3a74b8, 0x80b8e8], spec=0.6),
         'tooth': g([0xcac0a0, 0xfff8e8]), 'maw': VOID, 'eye': glow(0xc0a010, 0xffe040, 0xffffa0)}
    m = Model(64, 60)
    S = scales(2.4, 0.1)
    # the sea it rises from
    m.sphere((32, 54, -4), 26, 'water', 1.0, 0.18, 0.5)

    def foam(x, y, h):
        return 'belly' if h[2] == 'water' and vnoise(x * 0.5, y * 1.4, 11) > 0.72 else None
    m.paint(foam)
    # coils breaking the water behind it
    for s, x0 in ((-1, 14), (1, 50)):
        m.part('arm' + ('R' if s > 0 else 'L'), (x0, 50))
        m.chain([(x0 - 5, 52, -2), (x0 - 2, 42, -1), (x0 + 3, 40, -1), (x0 + 6, 50, -2)], [3.4, 4.0, 4.0, 3.4], 'hide', S)
        m.anchor('hand' + ('R' if s > 0 else 'L'), (x0, 41))
    m.part(None)
    # the long neck rising, fins along it
    m.chain([(32, 54, 0), (30, 44, 1), (34, 34, 3), (32, 24, 5)], [7, 6.5, 6, 5.4], 'hide', S)
    m.capsule((32, 50, 7), (32, 26, 9), 2.6, 2.4, 'belly')
    for k in range(4):
        y = 46 - k * 7
        m.membrane([(33 - 5, y), (33 - 11, y - 6), (33 - 6, y - 3)], -2, 'fin', (-0.4, -0.2))
        m.membrane([(31 + 5, y), (31 + 11, y - 6), (31 + 6, y - 3)], -2, 'fin', (0.4, -0.2))
    m.part('head', (32, 24))
    m.sphere((32, 16, 6), 7.4, 'hide', 1.1, 0.9, 1, S)
    m.capsule((32, 18, 8), (32, 24, 12), 4.2, 2.6, 'hide')                                 # its snout, toward you
    m.sphere((32, 22.5, 12), 3.4, 'maw', 1.2, 0.6, 0.5)
    for k in range(4):
        m.capsule((29.5 + k * 1.7, 20.8, 13.6), (29.5 + k * 1.7, 22.4, 13.6), 0.5, 0.15, 'tooth')
    eyes(m, 32, 14, 3.2, 10, 'eye', 1.0)
    for s in (-1, 1):                                                                      # finned crest
        m.membrane([(32 + s * 5, 12), (32 + s * 14, 4), (32 + s * 10, 13)], 3, 'fin', (s * 0.4, -0.3))
    m.anchor('cast', (32, 22))
    m.part(None)
    return m, M


MODELS = [('tesseract', tesseract), ('forgemaster', forgemaster), ('glacia', glacia), ('hollow_prince', hollow_prince),
          ('rendmaw', rendmaw), ('pharaoh', pharaoh), ('admiral', admiral), ('pearlmaw', pearlmaw), ('ossarion', ossarion),
          ('quarry_heart', quarry_heart), ('ignaria', ignaria), ('crone_bramble', crone('crone_bramble')), ('crone_bog', crone('crone_bog')),
          ('crone_ash', crone('crone_ash')), ('leviathan', leviathan)]
PROPS = [('canopic_jar', canopic_jar)]

RIG = {
    'tesseract': {'fly': True, 'arms': 0, 'heavy': True}, 'forgemaster': {'held': 'blade', 'heavy': True},
    'glacia': {'fly': True, 'arms': 0, 'flap': 1.5}, 'hollow_prince': {'legs': False},
    'rendmaw': {'arms': 0.6, 'heavy': True}, 'pharaoh': {'cast': 'one', 'held': 'staff'},
    'admiral': {}, 'pearlmaw': {'arms': 0.5, 'heavy': True}, 'ossarion': {'held': 'staff', 'heavy': True},
    'quarry_heart': {'heavy': True}, 'ignaria': {'fly': True, 'flap': 1.6}, 'crone_bramble': {'legs': False, 'cast': 'one', 'held': 'staff'},
    'crone_bog': {'legs': False, 'cast': 'one', 'held': 'staff'}, 'crone_ash': {'legs': False, 'cast': 'one', 'held': 'staff'},
    'leviathan': {'legs': False, 'arms': 0.4, 'still': True, 'heavy': True},
}


def all_designs():
    return designs(MODELS + PROPS)


if __name__ == '__main__':
    import sys
    sheet(MODELS + PROPS, sys.argv[1], 4)
