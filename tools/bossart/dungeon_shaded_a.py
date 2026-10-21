"""
Dungeon bosses, shaded from solids (sdfart.py, shaded_kit.py), each keeping the look it had:
the Lich King, the Serpent Queen, the Cellar Sorcerer, the Tempest Seraph, the Crypt Warden,
the Furnace Warden, the Living Flame, the Archdemon, the Sprite Queen and the Sun King.
"""
import math
from sdfart import Model, rough, folds, scales, fur, vnoise
from shaded_kit import g, glow, robe, torso, arm, held, legs, head, eyes, hood, crown, staff, wing, flame, designs, sheet

BONE = g([0x3e3828, 0x6c6450, 0x9e967c, 0xcac4a8, 0xece8d4], spec=0.2)
VOID = g([0x040306, 0x0a080e])


def lich_king(t):
    M = {'robe': g([0x1c0406, 0x34080c, 0x520e14, 0x74161c, 0x9a2228]), 'trim': g([0x3a2a0c, 0x6a5018, 0xa48028, 0xd8b048], spec=0.5),
         'bone': BONE, 'void': VOID, 'crown': g([0x0a0a0e, 0x18181e, 0x2a2a34, 0x40404c], spec=0.5),
         'soul': glow(0x1a8a3a, 0x40e070, 0xa0ffc0, base=0.15), 'eye': glow(0x20a040, 0x70ff90, base=0.1)}
    m = Model(46, 56)
    robe(m, 23, 18, 54, 6.5, 15, 'robe', 'trim')
    torso(m, 23, 18, 30, 5.5, 'robe')
    for k in range(4):                                         # ribs showing through a torn chest
        m.capsule((19, 20 + k * 2.2, 6.6), (27, 20 + k * 2.2, 6.6), 0.55, 0.55, 'bone')
    m.capsule((23, 19, 7.2), (23, 29, 7.2), 0.7, 0.7, 'bone')
    m.sphere((23, 31.5 + t * 0.3, 8.5), 2.2, 'soul')           # the soul gem in his chest
    for s in (-1, 1):
        m.sphere((23 + s * 7, 18, 4), 3.2, 'robe')
        arm(m, (23 + s * 8, 19, 4), (23 + s * 11, 27, 6), (23 + s * 9, 33, 8), 2.0, 'robe', 'bone', 1.6)
        held(m, x=23 + s * 9)
        m.capsule((23 + s * 9, 34, 9), (23 + s * 10, 37, 9), 0.5, 0.3, 'bone')
        m.part(None)
    head(m, 23, 11, 5.2, 'bone')
    eyes(m, 23, 11, 2.0, 8.6, 'void', 1.1)
    eyes(m, 23, 11.2, 2.0, 9.3, 'eye', 0.5)
    m.capsule((21, 15, 10), (25, 15, 10), 0.5, 0.5, 'void')
    for k in range(7):                                         # a crown of black iron spikes
        x = 17.5 + k * 1.85
        m.capsule((x, 7, 5), (x + (k - 3) * 0.5, 1.5 - (k % 2) * 1.5, 5), 0.7, 0.2, 'crown')
    m.capsule((17.5, 7, 5.5), (28.5, 7, 5.5), 1.0, 1.0, 'crown')
    return m, M


def serpent_queen(t):
    M = {'skin': g([0x16301c, 0x245034, 0x387450, 0x52987a, 0x78bc9e]), 'tail': g([0x0a2414, 0x143a20, 0x20582e, 0x2e7840, 0x449a58], spec=0.3),
         'belly': g([0x5a5a26, 0x8a8a3a, 0xbcbc5c]), 'gold': g([0x5a420c, 0x9a7418, 0xd8a830, 0xffe080], spec=0.6),
         'eye': glow(0xc02020, 0xff6040, base=0.2), 'snake': g([0x0e2a12, 0x1c4824, 0x2e6a36, 0x4a8c50])}
    m = Model(54, 52)
    S = scales(2.2, 0.12)
    # the coiled serpent body
    m.sphere((27, 44, -2), 14, 'tail', 1.5, 0.42, 1, S)
    m.sphere((22, 40, 2), 9, 'tail', 1.4, 0.45, 1, S)
    m.chain([(8, 44, 4), (4, 40, 4), (6, 35, 5), (11, 33, 5)], [3.2, 2.6, 2.0, 1.2], 'tail', S)
    m.capsule((27, 30, 4), (27, 40, 6), 4.6, 6, 'tail', S)
    m.capsule((27, 33, 9.5), (27, 46, 10), 1.6, 2.4, 'belly')

    def spots(x, y, h):
        return 'gold' if h[2] == 'tail' and vnoise(x * 0.5, y * 0.5, 7) > 0.8 else None
    m.paint(spots)
    # her upper body
    torso(m, 27, 18, 30, 4.4, 'skin')
    m.capsule((23, 22, 6), (31, 22, 6), 0.9, 0.9, 'gold')
    for s in (-1, 1):
        arm(m, (27 + s * 5, 18, 3), (27 + s * 9, 24, 4), (27 + s * 11, 19, 6), 1.5, 'skin', 'skin', 1.3)
    head(m, 27, 11, 4.4, 'skin')
    eyes(m, 27, 11, 1.6, 7.9, 'eye', 0.55)
    # hair of snakes
    for k in range(7):
        a = -math.pi * 0.9 + k * math.pi * 0.8 / 6
        x0, y0 = 27 + math.cos(a) * 3.5, 9 + math.sin(a) * 3
        x1, y1 = 27 + math.cos(a) * 8, 7 + math.sin(a) * 6 - (t if k % 2 else -t) * 0.5
        m.capsule((x0, y0, 2), (x1, y1, 3), 1.2, 0.6, 'snake')
        m.sphere((x1, y1, 3.6), 0.9, 'snake')
    m.capsule((23.5, 6.5, 5), (30.5, 6.5, 5), 0.9, 0.9, 'gold')
    return m, M


def cellar_sorcerer(t):
    M = {'robe': g([0x0a1030, 0x141e52, 0x1e2e78, 0x2c44a0, 0x4062c8]), 'star': g([0x6a5a20, 0xc8b040, 0xfff0a0]),
         'beard': g([0x6a6a70, 0xa8a8b0, 0xd8d8e0, 0xf6f6fa]), 'skin': g([0x7a5040, 0xb07c60, 0xdcaa88]),
         'wood': g([0x2a1a0c, 0x4a3018, 0x6a4826]), 'orb': glow(0x60a0ff, 0xc0e0ff, 0xffffff),
         'p1': glow(0xd02060, 0xff70a0), 'p2': glow(0x20a040, 0x70ff90), 'p3': glow(0xa040e0, 0xd090ff), 'eye': g([0x101010, 0x202020])}
    m = Model(44, 58)
    robe(m, 21, 24, 56, 6, 13, 'robe', 'star', tatter=False)
    torso(m, 21, 22, 34, 5.5, 'robe')
    for k, mt in enumerate(('p1', 'p2', 'p3')):                 # potions on his belt
        m.sphere((16 + k * 4, 36, 9), 1.5, mt)
    arm(m, (15, 24, 4), (11, 30, 5), (13, 34, 7), 2.0, 'robe', 'skin', 1.4)
    arm(m, (27, 24, 4), (31, 30, 5), (33, 27, 7), 2.0, 'robe', 'skin', 1.4)
    staff(m, 34, 8, 56, 'wood', z=6, r=0.9)
    m.sphere((34, 6.5 - t * 0.3, 8), 2.4, 'orb')
    head(m, 21, 19, 4.2, 'skin')
    m.capsule((21, 23.5, 7.5), (21, 31, 8.5), 3.0, 1.0, 'beard')   # a long white beard
    m.capsule((18, 21.5, 8.2), (24, 21.5, 8.2), 0.8, 0.8, 'beard')
    eyes(m, 21, 19, 1.6, 7.9, 'eye', 0.5)
    # a tall pointed hat, a little crooked, with stars
    m.capsule((21, 15, 3), (23.5, -0.5, 2), 6.5, 0.4, 'robe')
    m.sphere((21, 15.5, 3), 8.2, 'robe', 1.0, 0.22, 1.0)
    for x, y in ((19, 10), (23, 6), (21, 13)):
        m.sphere((x, y, 7.2 - (y < 9) * 2), 0.7, 'star')
    return m, M


def tempest_seraph(t):
    M = {'robe': g([0x5a4808, 0x8a7010, 0xc0a020, 0xe8cc40, 0xfff080], gamma=1.1), 'skin': g([0x8a6a50, 0xc0987a, 0xe8c4a4]),
         'wing': g([0x8a8270, 0xb4ac98, 0xd8d2be, 0xf4f0e2], gamma=1.0), 'halo': glow(0xd0a020, 0xffe060, 0xfff8c0),
         'blade': g([0x5a6878, 0x8ea0b4, 0xc8d8ec, 0xffffff], spec=0.8), 'hair': g([0x6a5018, 0xa07c28, 0xd4ac48]), 'eye': glow(0x2080e0, 0x80c0ff)}
    m = Model(64, 54)
    for s in (-1, 1):                                          # great wings, each with a sword along it
        root = (32 + s * 4, 18)
        d = (s * 0.86, -0.5)
        wing(m, root, d, 26, 'wing', 'wing', -4, n=6, droop=0.55, side=s)
        m.capsule((32 + s * 9, 14, -2), (32 + s * 26, 3, -2), 0.8, 0.5, 'blade')
        m.anchor('hand' + ('R' if s > 0 else 'L') + 'w', (32 + s * 26, 3))
    m.part(None)
    robe(m, 32, 22, 52, 5.5, 11, 'robe', tatter=False)
    torso(m, 32, 19, 30, 4.6, 'robe')
    for s in (-1, 1):
        arm(m, (32 + s * 5, 20, 4), (32 + s * 7, 27, 5), (32 + s * 5, 32, 7), 1.6, 'robe', 'skin', 1.2)
    head(m, 32, 13, 4.0, 'skin')
    m.sphere((32, 10.5, 2), 4.6, 'hair', 1.05, 0.9, 1)
    eyes(m, 32, 13, 1.5, 7.6, 'eye', 0.45)
    m.sphere((32, 4.5, 3), 5.5, 'halo', 1.0, 0.32, 0.4)
    return m, M






def living_flame(t):
    M = {'out': glow(0x8a1806, 0xd03a0a, 0xff7a1a, 0xffb040, base=0.05), 'in': glow(0xff8a20, 0xffc050, 0xfff0b0, base=0.2),
         'void': g([0x2a0402, 0x4a0a04]), 'tooth': g([0xd0b080, 0xfff0d0])}
    m = Model(50, 54)
    for k in range(9):                                         # tongues of flame licking up and out
        a = -math.pi / 2 + (k - 4) * 0.33
        ln = 20 - abs(k - 4) * 2 + ((k + t) % 2) * 2
        m.part('hem%d' % (k % 2) if k not in (1, 7) else ('armL' if k == 1 else 'armR'), (25, 30))
        m.capsule((25, 30, 0), (25 + math.cos(a) * ln, 30 + math.sin(a) * ln, 0), 5.5 - abs(k - 4) * 0.4, 0.4, 'out')
    m.part(None)
    m.sphere((25, 32, 2), 14, 'out', 1.0, 0.95, 0.9)
    m.sphere((25, 31, 6), 10, 'in', 1.0, 1.0, 0.8)
    m.anchor('cast', (25, 36)); m.anchor('handL', (12, 16)); m.anchor('handR', (38, 16))
    # its face: blazing eyes and a jagged grin
    for s in (-1, 1):
        m.sphere((25 + s * 4.5, 27, 15.5), 2.0, 'void', 1.1, 0.8, 0.5)
    m.part('jaw', (25, 34))
    m.sphere((25, 36.5, 15), 5.4, 'void', 1.25, 0.6, 0.5)
    for k in range(5):
        m.part(None)
        m.capsule((20 + k * 2.5, 33.5, 17.1), (20 + k * 2.5, 35.5, 17.1), 0.6, 0.2, 'tooth')
        m.part('jaw', (25, 34))
        m.capsule((21.2 + k * 2.5, 39.8, 16.9), (21.2 + k * 2.5, 38, 16.9), 0.6, 0.2, 'tooth')
    m.part(None)
    for k in range(6):                                         # embers flying off it
        a = k * 1.1 + t
        m.sphere((25 + math.cos(a) * 20, 30 + math.sin(a) * 18, 14), 0.8, 'in')
    return m, M


def archdemon(t):
    M = {'skin': g([0x2a0604, 0x4a0c08, 0x6e140c, 0x961e14, 0xbc3020, 0xdc4a32], spec=0.3), 'wing': g([0x140404, 0x260808, 0x3a0c0c, 0x521414], rimk=0.6),
         'horn': g([0x1a1410, 0x342a20, 0x544636, 0x7a6a54]), 'iron': g([0x1a1a1e, 0x343440, 0x56566a], spec=0.5),
         'eye': glow(0xd0a010, 0xffe050, base=0.2), 'fire': glow(0xff6010, 0xffc040)}
    m = Model(64, 58)
    for s in (-1, 1):                                          # bat wings
        sh, wr = (32 + s * 5, 18, -3), (32 + s * 26, 4, -3)
        m.part('wingR' if s > 0 else 'wingL', sh[:2])
        m.capsule(sh, wr, 1.6, 1.0, 'horn')
        tips = [(32 + s * 30, 16), (32 + s * 27, 26), (32 + s * 19, 30)]
        m.membrane([(sh[0], sh[1]), (wr[0], wr[1]), tips[0], (32 + s * 25, 20), tips[1], (32 + s * 21, 25), tips[2], (32 + s * 8, 28)], -4, 'wing', (s * 0.3, -0.2))
        for tp in tips:
            m.capsule(wr, (tp[0], tp[1], -3.5), 0.8, 0.3, 'horn')
    m.part('tail', (28, 40))
    m.chain([(28, 40, -2), (20, 46, -1), (14, 50, 0), (10, 47, 0)], [2.0, 1.6, 1.2, 0.6], 'skin')   # tail
    m.part(None)
    legs(m, 32, 36, 56, 4.5, 3.8, 'skin')
    torso(m, 32, 18, 36, 8, 'skin', rough(0.08))
    for s in (-1, 1):
        m.sphere((32 + s * 9, 19, 2), 4.4, 'skin')
        arm(m, (32 + s * 10, 20, 3), (32 + s * 13, 29, 5), (32 + s * 12, 35, 7), 2.8, 'skin', 'skin', 2.4)
    staff(m, 44, 4, 54, 'iron', z=8, r=0.9)                     # a trident
    for x in (41, 44, 47):
        m.capsule((x, 6, 8.5), (x, 1, 8.5), 0.7, 0.3, 'iron')
    m.capsule((41, 6, 8.5), (47, 6, 8.5), 0.7, 0.7, 'iron')
    m.part('head', (32, 17))
    m.anchor('cast', (32, 14.5))
    m.sphere((32, 11, 4), 5.6, 'skin', 0.95, 1.0, 1, rough(0.06))
    eyes(m, 32, 11, 2.5, 9.0, 'eye', 1.0)
    m.capsule((29, 14.5, 10.4), (35, 14.5, 10.4), 0.5, 0.5, 'fire')
    for s in (-1, 1):
        m.chain([(32 + s * 4, 7, 5), (32 + s * 8, 3, 5), (32 + s * 7, -0.5, 4)], [1.6, 1.1, 0.3], 'horn')
    m.part(None)
    return m, M


def sprite_queen(t):
    M = {'wing': g([0x8a2a6a, 0xc04a98, 0xe878c4, 0xffb0e4], gamma=1.0), 'spot': g([0x3a8ab0, 0x6ac4e8, 0xb0ecff]),
         'dress': g([0x7a1a5a, 0xb02a84, 0xe050b0, 0xff88d4]), 'skin': g([0x9a7468, 0xd0a494, 0xf4d0c0]),
         'hair': g([0x8a6a18, 0xc8a030, 0xf0d060]), 'glow': glow(0xff90e0, 0xffe0f8, 0xffffff), 'eye': g([0x2a1a3a, 0x4a2a6a])}
    m = Model(56, 50)
    for s in (-1, 1):                                          # butterfly wings, upper and lower
        m.part('wingR' if s > 0 else 'wingL', (28 + s * 2, 22))
        m.sphere((28 + s * 12, 16, -4), 10, 'wing', 1.0, 0.85, 0.3)
        m.sphere((28 + s * 10, 31, -5), 7, 'wing', 1.0, 0.9, 0.3)
        m.sphere((28 + s * 14, 15, -0.8), 3.2, 'spot', 1, 1, 0.3)
        m.sphere((28 + s * 11, 32, -2.5), 2.2, 'spot', 1, 1, 0.3)
    m.part(None)
    robe(m, 28, 24, 44, 3.5, 8, 'dress', tatter=True, seed=21)
    torso(m, 28, 21, 29, 3.2, 'dress')
    for s in (-1, 1):
        arm(m, (28 + s * 3.5, 21, 3), (28 + s * 6, 26, 4), (28 + s * 8, 22, 5), 1.0, 'skin', 'skin', 0.9)
    held(m, 'R')
    m.sphere((36, 20.5 - t * 0.3, 6.5), 1.6, 'glow')            # a spark on her fingertip
    m.anchor('cast', (36, 20.5))
    head(m, 28, 15, 3.6, 'skin')
    m.sphere((28, 13, 1.5), 4.4, 'hair', 1.05, 0.95, 1)
    eyes(m, 28, 15.2, 1.4, 6.9, 'eye', 0.5)
    crown(m, 28, 10.6, 3, 'hair', spikes=3, tall=2.5, z=4)
    m.part(None)
    for k in range(6):
        a = k * 1.05 + t * 0.5
        m.sphere((28 + math.cos(a) * 22, 26 + math.sin(a) * 16, 8), 0.6, 'glow')
    return m, M


def sun_king(t):
    M = {'robe': g([0x6a5a48, 0x9a8a72, 0xc8b89c, 0xece0c8, 0xfff8ec], gamma=1.1), 'gold': g([0x5a3e08, 0x9a6e12, 0xd8a426, 0xffd860], spec=0.7),
         'sun': glow(0xe08010, 0xffc030, 0xfff090, base=0.25), 'skin': g([0x7a5640, 0xb4846a, 0xe0b498]),
         'gem': glow(0xc01010, 0xff4040, 0xffa0a0), 'eye': g([0x1a1208, 0x2a1e10])}
    m = Model(54, 58)
    for k in range(14):                                        # a halo of sun rays behind him
        a = k * math.pi * 2 / 14 + t * 0.1
        ln = 18 if k % 2 else 14
        m.capsule((27 + math.cos(a) * 8, 15 + math.sin(a) * 8, -6), (27 + math.cos(a) * ln, 15 + math.sin(a) * ln, -6), 1.4, 0.3, 'sun')
    m.sphere((27, 15, -6), 9, 'sun', 1, 1, 0.3)
    robe(m, 27, 22, 56, 6.5, 14, 'robe', 'gold', tatter=False)
    torso(m, 27, 20, 34, 6.5, 'gold')
    m.sphere((27, 27, 8.5), 2.4, 'gem')
    for s in (-1, 1):
        m.sphere((27 + s * 7, 21, 3), 3.4, 'gold')
        arm(m, (27 + s * 8, 22, 3), (27 + s * 11, 30, 5), (27 + s * 9, 35, 7), 2.2, 'robe', 'skin', 1.6)
    staff(m, 37, 10, 56, 'gold', z=8, r=0.9)
    m.sphere((37, 8 - t * 0.3, 9), 2.4, 'sun')
    head(m, 27, 15, 4.6, 'skin')
    eyes(m, 27, 15, 1.7, 8.4, 'eye', 0.5)
    crown(m, 27, 10.5, 4, 'gold', spikes=5, tall=3.5, z=6, gem='gem')
    return m, M


MODELS = [('lich_king', lich_king), ('serpent_queen', serpent_queen), ('sorcerer', cellar_sorcerer), ('seraph', tempest_seraph),
          ('pyrelord', living_flame), ('archdemon', archdemon),
          ('sprite_queen', sprite_queen), ('sun_king', sun_king)]


def all_designs():
    return designs(MODELS)


if __name__ == '__main__':
    import sys
    sheet(MODELS[:5], sys.argv[1])
    sheet(MODELS[5:], sys.argv[2])


# how each moves (posed.py)
RIG = {
    'lich_king': {'legs': False}, 'serpent_queen': {'legs': False}, 'sorcerer': {'legs': False, 'cast': 'one', 'held': 'staff'},
    'seraph': {'fly': True, 'flap': 1.4}, 'pyrelord': {'fly': True, 'arms': 0.5}, 'archdemon': {'flap': 1.3, 'held': 'staff'},
    'sprite_queen': {'fly': True, 'flap': 1.6}, 'sun_king': {'legs': False, 'cast': 'one', 'held': 'staff'},
}
