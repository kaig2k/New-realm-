"""
Dungeon bosses, shaded from solids (sdfart.py, shaded_kit.py), each keeping the look it had:
the Moon Queen, Glacius the Frost Warden, the Shattered Seraph, Kael'zar the Blood Knight,
Morwyn the Hex Queen, the Star Prince, Captain Saltbeard, Mother Mothwing and Arachnia.
"""
import math
from sdfart import Model, rough, folds, scales, fur, vnoise
from shaded_kit import g, glow, robe, torso, arm, held, legs, head, eyes, hood, crown, staff, wing, flame, designs, sheet

VOID = g([0x040306, 0x0a080e])
SKIN = g([0x7a5644, 0xb08470, 0xdcb09a])


def moon_queen(t):
    M = {'robe': g([0x080c24, 0x10183e, 0x1a265e, 0x283a82, 0x3a52a8]), 'star': glow(0xa0b0ff, 0xe0e8ff, 0xffffff),
         'hair': g([0x7a80a0, 0xaab0cc, 0xd4d8ec, 0xf2f4ff], gamma=1.0), 'skin': g([0x8a8aa4, 0xc0c2d8, 0xe8e8f6]),
         'moon': glow(0x8a90c0, 0xd0d6f0, 0xffffff, base=0.3), 'eye': g([0x1a1a3a, 0x30306a])}
    m = Model(52, 56)
    m.sphere((14, 14, -8), 9, 'moon', 1, 1, 0.3)                 # the crescent moon behind her
    m.sphere((17, 12, -6), 7.6, 'robe', 1, 1, 0.3)
    robe(m, 27, 20, 54, 5.5, 13, 'robe', tatter=False, seed=31)
    torso(m, 27, 18, 30, 4.8, 'robe')

    def stars(x, y, h):
        return 'star' if h[2] == 'robe' and vnoise(x * 0.9, y * 0.9, 3) > 0.86 else None
    m.paint(stars)
    m.capsule((27, 9, 0), (27, 34, -1), 5.2, 3.0, 'hair')         # long hair falling behind
    arm(m, (22, 20, 3), (20, 27, 4), (22, 32, 6), 1.7, 'robe', 'skin', 1.3)
    arm(m, (32, 20, 3), (37, 24, 5), (42, 21, 7), 1.7, 'robe', 'skin', 1.3)
    held(m, 'R')
    m.sphere((45, 20 - t * 0.3, 8), 2.4, 'star')                  # a star in her outstretched hand
    m.anchor('cast', (45, 20))
    head(m, 27, 13, 4.2, 'skin')
    m.capsule((22.5, 10, 6.5), (31.5, 10, 6.5), 1.4, 1.4, 'hair')
    eyes(m, 27, 13.2, 1.5, 7.8, 'eye', 0.45)
    return m, M




def shattered_seraph(t):
    M = {'robe': g([0x7a7280, 0xa8a0b0, 0xd0c8d8, 0xeee8f4, 0xffffff], gamma=1.1), 'crack': glow(0xc02080, 0xff60b0, 0xffb0e0, base=0.25),
         'wing': g([0x8a5a7a, 0xb87aa0, 0xe0a8c8, 0xfcd4ea], gamma=1.0), 'skin': g([0x8a7a7a, 0xc0acac, 0xe8d6d6]),
         'halo': glow(0xc09020, 0xffd860, 0xfff4c0), 'hair': g([0xa08a5a, 0xd0b880, 0xf4e0b0]), 'eye': g([0x4a0828, 0x9a1458])}
    m = Model(60, 54)
    for s in (-1, 1):                                             # broken wings: a few feathers left
        root = (30 + s * 4, 18)
        wing(m, root, (s * 0.9, -0.35), 22, 'wing', 'wing', -4, n=4, droop=0.45, side=s)
    m.part(None)
    robe(m, 30, 22, 52, 5, 10, 'robe', tatter=True, seed=41)
    torso(m, 30, 19, 30, 4.4, 'robe')

    def cracks(x, y, h):
        if h[2] not in ('robe', 'wing'):
            return None
        v = vnoise((x + vnoise(x * 0.2, y * 0.2, 5) * 5) * 0.18, y * 0.16, 31)
        return 'crack' if abs(v - 0.5) < 0.02 else None
    m.paint(cracks)
    for s in (-1, 1):
        arm(m, (30 + s * 4.5, 20, 3), (30 + s * 6, 27, 4), (30 + s * 5, 32, 6), 1.5, 'robe', 'skin', 1.1)
    head(m, 30, 13, 3.9, 'skin')
    m.sphere((30, 10.5, 2), 4.4, 'hair', 1.05, 0.9, 1)
    eyes(m, 30, 13, 1.4, 7.4, 'eye', 0.45)
    # a cracked, tilted halo
    m.sphere((31, 4.5, 2), 5, 'halo', 1.0, 0.3, 0.4)
    m.membrane([(30, 3), (33, 3), (32, 6.5)], 4, 'skin')
    return m, M




def hex_queen(t):
    M = {'robe': g([0x0a080e, 0x16121e, 0x221c2e, 0x322a42, 0x463c5c]), 'hex': glow(0x2a9a20, 0x60e040, 0xc0ff90, base=0.15),
         'skin': g([0x4a6a50, 0x7a9a80, 0xaac8ae]), 'antler': g([0x2a2018, 0x4a3a2a, 0x6e5a42, 0x96806a]),
         'wood': g([0x1e140c, 0x342416, 0x4c3622]), 'eye': glow(0x40c020, 0xa0ff80)}
    m = Model(52, 58)
    robe(m, 26, 20, 56, 5.5, 13, 'robe', tatter=True, seed=51)
    m.capsule((26, 28, 11), (26, 55, 13.5), 2.4, 4.0, 'hex', folds(0.1, 2.4, 6))   # her glowing gown panel
    torso(m, 26, 18, 30, 4.8, 'robe')
    arm(m, (21, 20, 3), (17, 26, 5), (15, 21, 7), 1.6, 'robe', 'skin', 1.2)
    arm(m, (31, 20, 3), (35, 27, 5), (37, 31, 7), 1.6, 'robe', 'skin', 1.2)
    held(m, 'R')
    m.capsule((38, 8, 7), (38, 56, 7), 0.9, 0.9, 'wood')
    m.sphere((38, 6 - t * 0.3, 8.5), 2.2, 'hex')
    m.anchor('cast', (38, 6))
    m.part(None)
    for k in range(4):                                            # hex orbs circling her
        a = k * math.pi / 2 + t * 0.4
        m.sphere((26 + math.cos(a) * 20, 30 + math.sin(a) * 8, 10), 1.4, 'hex')
    m.part('head', (26, 17.6))
    hood(m, 26, 12, 6, 'robe', 'robe')
    head(m, 26, 13, 3.6, 'skin', z=5)
    eyes(m, 26, 13, 1.4, 8.0, 'eye', 0.5)
    for s in (-1, 1):                                             # antlers rising from her hood
        m.chain([(26 + s * 3, 7, 3), (26 + s * 6, 2, 3), (26 + s * 9, -1, 3)], [1.1, 0.8, 0.3], 'antler')
        m.capsule((26 + s * 5.5, 3, 3), (26 + s * 4, -1, 3), 0.6, 0.25, 'antler')
    m.part(None)
    return m, M


def star_prince(t):
    M = {'cloak': g([0x1a0a30, 0x2c1250, 0x421c72, 0x5c2a96, 0x7a40bc]), 'star': glow(0xd0b040, 0xfff0a0, 0xffffff),
         'tunic': g([0x3a2a5a, 0x5a4282, 0x7c60a8]), 'skin': SKIN, 'hair': g([0x8a6a18, 0xc8a030, 0xf0d464]),
         'steel': g([0x5a6474, 0x8e9aac, 0xc8d4e8, 0xffffff], spec=0.9), 'gold': g([0x6a4a10, 0xaa7c1e, 0xe8b438]), 'eye': g([0x1a2a5a, 0x2a4a8a])}
    m = Model(52, 56)
    m.membrane([(14, 17), (36, 17), (42, 52), (8, 52)], -7, 'cloak', (0, -0.1), folds(0.12, 3.6, 8))

    def stars(x, y, h):
        return 'star' if h[2] == 'cloak' and vnoise(x * 0.8, y * 0.8, 9) > 0.86 else None
    m.paint(stars)
    legs(m, 25, 34, 54, 3.6, 3.0, 'tunic')
    torso(m, 25, 18, 34, 5.5, 'tunic')
    m.capsule((20, 21, 7), (30, 30, 7), 0.8, 0.8, 'gold')        # a gold sash
    arm(m, (19, 20, 3), (16, 27, 5), (18, 32, 7), 2.0, 'tunic', 'skin', 1.5)
    arm(m, (31, 20, 3), (35, 25, 5), (38, 21, 7), 2.0, 'tunic', 'skin', 1.5)
    held(m, 'R')
    m.capsule((39, 20, 8), (47, 4, 8), 1.1, 0.4, 'steel')        # his sword raised
    m.capsule((36.5, 21.5, 8.5), (41.5, 18.5, 8.5), 0.8, 0.8, 'gold')
    m.anchor('strike', (47, 4))
    head(m, 25, 12, 4.2, 'skin')
    m.sphere((25, 9.5, 2), 4.8, 'hair', 1.05, 0.85, 1)
    eyes(m, 25, 12.4, 1.8, 7.6, 'eye', 0.45)
    crown(m, 25, 8.2, 3, 'gold', spikes=3, tall=2, z=6, gem='star')
    m.part(None)
    return m, M


def pirate_king(t):
    M = {'coat': g([0x080c1e, 0x101836, 0x1a2652, 0x26386e, 0x34508e]), 'gold': g([0x5a420c, 0x9a7418, 0xd8a830, 0xffe080], spec=0.6),
         'beard': g([0x5a5a5e, 0x8a8a90, 0xbcbcc2, 0xe4e4e8]), 'skin': SKIN, 'hat': g([0x060608, 0x101014, 0x1c1c22, 0x2c2c34]),
         'bone': g([0xa8a490, 0xe8e4d0]), 'steel': g([0x5a6474, 0x8e9aac, 0xd0dae8], spec=0.9), 'wood': g([0x2a1a0e, 0x4a3018, 0x6c4826]),
         'boot': g([0x1a1008, 0x2e1c10, 0x44301c]), 'patch': VOID, 'eye': g([0x1a1208, 0x2e2010])}
    m = Model(52, 56)
    m.part('legL', (21, 36))
    m.capsule((21, 36, 0), (20, 52, 1), 3.6, 3.0, 'boot')        # one boot
    m.sphere((20, 53.5, 2), 3.4, 'boot', 1.3, 0.55, 1.1)
    m.part('legR', (29, 36))
    m.capsule((29, 36, 0), (30, 52, 1), 1.4, 1.0, 'wood')        # one peg leg
    m.part(None)
    m.capsule((25, 20, 0), (25, 40, 0), 7.5, 9.5, 'coat', folds(0.1, 3.4, 12))
    m.capsule((18, 21, 8.5), (18, 40, 9.5), 0.7, 0.7, 'gold')
    m.capsule((32, 21, 8.5), (32, 40, 9.5), 0.7, 0.7, 'gold')
    m.capsule((17, 33, 9.6), (33, 33, 9.6), 0.9, 0.9, 'gold')    # his belt
    arm(m, (17, 21, 3), (13, 29, 5), (16, 34, 7), 2.4, 'coat', 'skin', 1.6)
    arm(m, (33, 21, 3), (38, 26, 5), (40, 21, 7), 2.4, 'coat', 'skin', 1.6)
    held(m, 'R')
    m.capsule((41, 20, 8), (47, 6, 8), 1.0, 0.5, 'steel')        # a cutlass
    m.capsule((38.6, 21.6, 8.6), (43, 19, 8.6), 0.8, 0.8, 'gold')
    m.anchor('strike', (47, 6))
    head(m, 25, 13, 4.6, 'skin')
    m.capsule((25, 17.5, 7.8), (25, 26, 8.5), 3.8, 1.2, 'beard')   # a big grey beard
    m.sphere((23, 12.6, 9.6), 1.2, 'patch')                      # eye patch
    m.capsule((20, 10, 8.6), (29.5, 14, 8.6), 0.35, 0.35, 'patch')
    eyes(m, 27.5, 12.8, 0, 7.8, 'eye', 0.5)
    # a black tricorn with a skull on it
    m.sphere((25, 8, 3), 8.5, 'hat', 1.0, 0.28, 1)
    m.sphere((25, 6, 3), 5, 'hat', 1.0, 0.6, 1)
    m.capsule((17, 8.5, 8), (33, 8.5, 8), 0.6, 0.6, 'gold')
    m.sphere((25, 5.4, 8.2), 1.5, 'bone')
    m.part(None)
    return m, M


def mothwing(t):
    M = {'wing': g([0x5a4a32, 0x86704e, 0xb09a72, 0xd4c09a, 0xeee0c0], gamma=1.0), 'spot': g([0x1a3a5a, 0x2e5c86, 0x5a8ab4]),
         'ring': g([0x2a2018, 0x4a3a2a]), 'body': g([0x2a2014, 0x4a3a24, 0x6e5a3a, 0x947c56], spec=0.1),
         'fur': g([0x8a7a5a, 0xb8a684, 0xe0d0b0]), 'eye': glow(0x206090, 0x60b0e0, 0xc0e8ff)}
    m = Model(62, 52)
    flap = t * 1.5
    for s in (-1, 1):
        m.part('wingR' if s > 0 else 'wingL', (31 + s * 3, 22))
        m.sphere((31 + s * 13, 18 - flap, -3), 12, 'wing', 1.05, 0.8, 0.25, folds(0.05, 2.8, 3))
        m.sphere((31 + s * 11, 34, -4), 8.5, 'wing', 1.0, 0.85, 0.25)
        m.sphere((31 + s * 15, 17 - flap, -0.6), 4.2, 'ring', 1, 1, 0.3)
        m.sphere((31 + s * 15, 17 - flap, 0.2), 3.0, 'spot', 1, 1, 0.3)
        m.sphere((31 + s * 11, 35, -1.8), 2.6, 'spot', 1, 1, 0.3)
    m.part(None)
    m.capsule((31, 14, 4), (31, 40, 3), 3.6, 1.6, 'body', fur(0.1))
    m.sphere((31, 17, 5.5), 4.2, 'fur', 1.1, 0.9, 1)
    m.part('head', (31, 14))
    m.sphere((31, 10, 5), 3.6, 'body', 1, 1, 1)
    m.anchor('cast', (31, 10)); m.anchor('handR', (46, 17)); m.anchor('handL', (16, 17))
    eyes(m, 31, 10, 2.0, 6.5, 'eye', 1.0)
    for s in (-1, 1):                                             # feathery antennae
        m.chain([(31 + s * 1.5, 7, 5), (31 + s * 5, 2, 5), (31 + s * 9, 0.5, 5)], [0.6, 0.5, 0.3], 'body')
    m.part(None)
    for k in range(6):                                            # dust falling from her wings
        m.sphere((18 + k * 5, 46 + (k % 2) * 3 - t, 6), 0.7, 'fur')
    return m, M


def broodmother(t):
    M = {'body': g([0x0a0608, 0x160c10, 0x24141a, 0x341e26, 0x4a2c36], spec=0.5), 'red': glow(0xa00a14, 0xff2a30, 0xff9090, base=0.15),
         'leg': g([0x0e080a, 0x1c1014, 0x2c1c22, 0x40282e]), 'fang': g([0x8a8070, 0xd0c8b0]), 'egg': g([0x8a8070, 0xc8c0a8, 0xf0ead8])}
    m = Model(62, 50)
    for s in (-1, 1):                                             # eight jointed legs
        for k in range(4):
            sx, sy = 31 + s * 6, 22 + k * 2.5
            kx, ky = 31 + s * (16 + k * 1.5), 10 + k * 5
            fx2, fy2 = 31 + s * (24 + k * 1.2), 30 + k * 4.5
            S = 'R' if s > 0 else 'L'
            # (the front pair are its arms: they rear up to strike; the rest walk in alternation)
            m.part('arm' + S if k == 0 else ('legR' if (k + (s > 0)) % 2 else 'legL'), (sx, sy))
            if k == 0:
                m.anchor('hand' + S, (fx2, fy2))
            m.capsule((sx, sy, 2 - k), (kx, ky, 2 - k), 1.6, 1.2, 'leg')
            m.capsule((kx, ky, 2 - k), (fx2, fy2, 2 - k), 1.2, 0.5, 'leg')
    m.part(None)
    m.sphere((31, 30, 0), 13, 'body', 1.1, 0.9, 0.9, rough(0.06))   # the abdomen
    m.capsule((31, 24, 11), (31, 30, 12), 1.4, 2.4, 'red')       # the red hourglass
    m.capsule((31, 34, 12), (31, 30, 12), 1.4, 2.4, 'red')
    m.part('head', (31, 22))
    m.sphere((31, 16, 6), 7, 'body', 1.1, 0.8, 1)                 # head and thorax
    m.anchor('cast', (31, 14))
    for k, (ex, ey) in enumerate(((28, 13), (34, 13), (26.5, 15), (35.5, 15))):
        m.sphere((ex, ey, 12), 0.9 if k < 2 else 0.6, 'red')
    m.part('jaw', (31, 20), 'head')
    for s in (-1, 1):
        m.capsule((31 + s * 2, 20, 11), (31 + s * 1.5, 24, 12), 0.9, 0.3, 'fang')
    m.part(None)
    for x in (10, 52):                                            # egg sacs
        m.sphere((x, 44, 4), 3.2, 'egg', 1, 0.9, 1)
    return m, M


MODELS = [('moon_queen', moon_queen), ('shattered_seraph', shattered_seraph),
          ('hex_queen', hex_queen), ('star_prince', star_prince), ('pirate_king', pirate_king),
          ('moth', mothwing), ('broodmother', broodmother)]


def all_designs():
    return designs(MODELS)


if __name__ == '__main__':
    import sys
    sheet(MODELS[:5], sys.argv[1])
    sheet(MODELS[5:], sys.argv[2])


# how each moves (posed.py)
RIG = {
    'moon_queen': {'legs': False, 'cast': 'one'}, 'shattered_seraph': {'fly': True}, 'hex_queen': {'legs': False, 'cast': 'one', 'held': 'staff'},
    'star_prince': {}, 'pirate_king': {}, 'moth': {'fly': True, 'legs': False, 'arms': 0, 'flap': 2.2}, 'broodmother': {'arms': 0.6, 'heavy': True},
}
