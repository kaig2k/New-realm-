"""
The armoured and stone bosses, rebuilt hard-edged (shaded_kit's chest/plate/pauldron/rock/spike on
sdfart's bevelled slabs, their materials snapped to flat facets): Vorgath the Ember Titan, the Lord
of the Sunken Lands, the Crypt Warden, the Furnace Warden, Glacius, Kael'zar the Blood Knight, Vault
Ignis, the Sentinel and the Colossus. Chiselled planes instead of balls.
"""
import math
from sdfart import Model, rough, folds, vnoise
from shaded_kit import (g, glow, eyes, flame, designs, sheet, chest, plate, pauldron, rock, spike)

VOID = g([0x040306, 0x0a080e])


def cracks(mat, into, seed, k=0.018):
    def f(x, y, h):
        if h[2] != mat:
            return None
        v = vnoise((x + vnoise(x * 0.2, y * 0.2, seed + 1) * 5) * 0.2, y * 0.2, seed)
        return into if abs(v - 0.5) < k and h[1][2] > 0.3 else None
    return f


def golem(m, mat, cx=27, w=13, fist=None, seed=1):
    """A hulking stone body: plated legs, a broad chiselled chest, rock shoulders, arms to heavy fists."""
    R = rough(0.08, 0.35, seed)
    for s in (-1, 1):
        m.part('legR' if s > 0 else 'legL', (cx + s * 6, 37))
        plate(m, (cx + s * 6, 37), (cx + s * 7, 50), 4.6, 4.0, 1, mat, 1.8, R)
        m.block(cx + s * 7 - 5, 49, cx + s * 7 + 5, 54, 3, 1.6, mat, R)
    m.part(None)
    chest(m, cx, 14, 39, w, w * 0.66, 3, mat, 4.0, R)
    m.block(cx - w * 0.55, 30, cx + w * 0.55, 38, 7.5, 2.0, mat, R)          # the plated belly
    for s in (-1, 1):
        m.part('armR' if s > 0 else 'armL', (cx + s * (w + 1), 18))
        rock(m, cx + s * (w + 1), 18, 7, 7, mat, seed + s * 3, sides=7, tex=R)
        plate(m, (cx + s * (w + 2), 22), (cx + s * (w + 5), 34), 4.4, 3.8, 6, mat, 1.8, R)
        rock(m, cx + s * (w + 5.5), 38, 5.4, 9, fist or mat, seed + s * 7, sides=6, tex=R)
        m.anchor('hand' + ('R' if s > 0 else 'L'), (cx + s * (w + 5.5), 38))
        m.hands['R' if s > 0 else 'L'] = (cx + s * (w + 5.5), 38)
    m.part('head', (cx, 14))
    m.slab([(cx - 5, 8), (cx - 3, 4), (cx + 3, 4), (cx + 5, 8), (cx + 4, 14), (cx - 4, 14)], 9, 2.2, mat, R)   # head
    m.anchor('cast', (cx, 9))
    m.part(None)


def knight(m, mat, cx=26, seed=1):
    """A plated figure: greaves, a breastplate, faulds, pauldrons, plated arms, a helm."""
    R = rough(0.05, 0.3, seed)
    for s in (-1, 1):
        m.part('legR' if s > 0 else 'legL', (cx + s * 4.5, 36))
        plate(m, (cx + s * 4.5, 36), (cx + s * 5, 52), 3.6, 3.0, 1, mat, 1.5, R)
        m.block(cx + s * 5 - 4, 51, cx + s * 5 + 4, 55, 3, 1.4, mat, R)
    m.part(None)
    chest(m, cx, 16, 34, 9, 6.5, 3, mat, 3.0, R)
    m.slab([(cx - 7, 33), (cx + 7, 33), (cx + 8, 40), (cx - 8, 40)], 4, 1.6, mat, R)   # faulds
    for s in (-1, 1):
        m.part('armR' if s > 0 else 'armL', (cx + s * 9, 18))
        pauldron(m, cx + s * 9, 17.5, 6, 6, 7, mat, s, 2.2, R)
        plate(m, (cx + s * 11, 21), (cx + s * 13, 30), 2.8, 2.4, 5, mat, 1.4, R)
        plate(m, (cx + s * 13, 30), (cx + s * 12, 36), 2.4, 2.6, 6, mat, 1.4, R)
        m.anchor('hand' + ('R' if s > 0 else 'L'), (cx + s * 12, 36))
        m.hands['R' if s > 0 else 'L'] = (cx + s * 12, 36)
    m.part('head', (cx, 15))
    m.anchor('cast', (cx, 9))
    m.slab([(cx - 5, 6), (cx - 3, 2.5), (cx + 3, 2.5), (cx + 5, 6), (cx + 5, 13), (cx + 2, 15), (cx - 2, 15), (cx - 5, 13)], 8, 2.0, mat, R)   # helm
    m.part(None)


def ember_titan(t):
    M = {'rock': g([0x140a06, 0x24140c, 0x3a2214, 0x54321e, 0x70462a, 0x8e5c38], facet=8),
         'horn': g([0x4a4034, 0x7a6c58, 0xa89a80, 0xd4c8ac], facet=8), 'lava': glow(0xa02a08, 0xff6010, 0xffa040, 0xffe0a0, base=0.15),
         'core': glow(0xff7010, 0xffc050, 0xfff0c0)}
    m = Model(56, 58)
    golem(m, 'rock', 28, 13, seed=3)
    for s in (-1, 1):
        m.part('armR' if s > 0 else 'armL', (28 + s * 14, 18))
        m.sphere((28 + s * 18.5, 39 + t * 0.4, 13), 2.6, 'lava')              # molten fists
        m.part('head', (28, 14))
        spike(m, (28 + s * 4, 6), (28 + s * 13, 0.5), 1.6, 11, 'horn')
        m.sphere((28 + s * 2.2, 10, 12.4), 0.9, 'core')
    m.part(None)
    m.sphere((28, 24, 9.5), 3.0 + t * 0.3, 'core', 1, 1.2, 0.5)
    m.paint(cracks('rock', 'lava', 13))
    return m, M


def colossus(t):
    M = {'rock': g([0x060608, 0x0e0e14, 0x18181f, 0x24242e, 0x343444, 0x48485c], facet=8, spec=0.3),
         'glow': glow(0x6020c0, 0xa050ff, 0xe0c0ff, base=0.15)}
    m = Model(62, 58)
    golem(m, 'rock', 31, 16, seed=131)
    m.part('head', (31, 14))
    m.capsule((27, 10, 12.2), (35, 10, 12.2), 0.8, 0.8, 'glow')
    m.part(None)
    m.sphere((31, 24, 9.6), 2.8 + t * 0.2, 'glow')
    m.paint(cracks('rock', 'glow', 133, 0.014))
    return m, M


def frost_warden(t):
    M = {'ice': g([0x1a3a5a, 0x2a5a82, 0x3e7aa8, 0x5c9ccc, 0x86c0e8, 0xb8e2ff], facet=8, spec=0.5),
         'core': glow(0x40a0ff, 0xa0e0ff, 0xffffff), 'haft': g([0x2a3440, 0x48566a, 0x6a7c94], facet=8),
         'blade': g([0x5a7a98, 0x9ac0e0, 0xe0f4ff], spec=0.8, facet=8)}
    m = Model(58, 60)
    golem(m, 'ice', 27, 12, seed=23)
    for s in (-1, 1):
        m.part('armR' if s > 0 else 'armL', (27 + s * 13, 18))
        for k in range(3):                                                    # crystal spikes on his shoulders
            spike(m, (27 + s * (11 + k * 2.6), 15), (27 + s * (12 + k * 3), 6 - k), 1.5, 9, 'ice')
    m.part(None)
    m.sphere((27, 24, 10), 3.0 + t * 0.2, 'core')
    m.part('heldR', (44.5, 38), 'armR')
    m.capsule((48, 4, 11), (48, 58, 11), 1.0, 1.0, 'haft')                   # a great axe
    m.slab([(48, 6), (56, 2), (57, 15), (48, 12)], 12, 1.4, 'blade')
    m.part('head', (27, 14))
    eyes(m, 27, 9.6, 2.0, 9.4, 'core', 0.7)
    for x in (23, 27, 31):
        spike(m, (x, 5), (x, 0.5 if x == 27 else 2), 1.2, 11, 'ice')
    m.part(None)
    return m, M


def furnace_warden(t):
    M = {'iron': g([0x1a0806, 0x2e100a, 0x481a10, 0x642818, 0x863a24, 0xa8543a], facet=8, spec=0.4), 'grill': g([0x0a0404, 0x180808]),
         'fire': glow(0xc03010, 0xff7a20, 0xffc060, 0xfff0c0, base=0.15), 'horn': g([0x2a1a14, 0x4a3024, 0x6e4a36], facet=8)}
    m = Model(56, 58)
    golem(m, 'iron', 28, 13, seed=17)
    m.block(21, 19, 35, 31, 9, 1.0, 'grill')                                  # the furnace door in his chest
    for k in range(4):
        m.block(22.5 + k * 3.4, 20.5, 24 + k * 3.4, 29.5, 11.5, 0.5, 'fire')
    for s in (-1, 1):
        m.part('armR' if s > 0 else 'armL', (28 + s * 14, 18))
        flame(m, 28 + s * 18.5, 36, 7, 4, ('fire', 'fire'), z=14, t=t)
        m.part('head', (28, 14))
        spike(m, (28 + s * 4, 6), (28 + s * 10, 0.5), 1.4, 11, 'horn')
    m.part(None)
    m.capsule((24, 10, 11.6), (32, 10, 11.6), 0.9, 0.9, 'fire')
    return m, M


def ignis(t):
    M = {'plate': g([0x0c0604, 0x1a0c08, 0x2a140c, 0x3e1e12, 0x582c1a], facet=8, spec=0.5), 'lava': glow(0xc03008, 0xff7a20, 0xffc060, base=0.15),
         'fire': glow(0xd04010, 0xff9030, 0xffe0a0, base=0.1), 'horn': g([0x1a1410, 0x342a20, 0x544636], facet=8)}
    m = Model(54, 58)
    knight(m, 'plate', 27, seed=61)
    m.sphere((27, 23, 8.5), 2.6 + t * 0.2, 'lava')
    for s in (-1, 1):
        m.part('armR' if s > 0 else 'armL', (27 + s * 9, 18))
        flame(m, 27 + s * 9, 14, 8, 4, ('fire', 'lava'), z=11, t=t)
        m.part('head', (27, 15))
        spike(m, (27 + s * 4, 4), (27 + s * 11, -0.5), 1.4, 10, 'horn')
    m.capsule((23.5, 9.5, 10.5), (30.5, 9.5, 10.5), 0.8, 0.8, 'lava')
    m.part(None)
    m.paint(cracks('plate', 'lava', 63, 0.02))
    return m, M


def crypt_warden(t):
    M = {'iron': g([0x0c0e12, 0x181c24, 0x262c38, 0x384050, 0x50586c, 0x707a90], facet=8, spec=0.6),
         'shield': g([0x14161c, 0x22262e, 0x343a46, 0x4a5262], facet=8, spec=0.4), 'void': VOID,
         'eye': glow(0x1a70c0, 0x40b0ff, 0xc0e8ff, base=0.15), 'lamp': glow(0x2060a0, 0x60c0ff, 0xd0f0ff), 'chain': g([0x2a2a30, 0x4a4a54, 0x70707c])}
    m = Model(50, 60)
    knight(m, 'iron', 27, seed=11)
    m.part('heldR', (39, 36), 'armR')
    m.capsule((40, 37, 9), (40, 41, 9), 0.4, 0.4, 'chain')
    m.sphere((40, 43.5 + t * 0.3, 9.5), 2.2, 'lamp')                          # a lantern in his fist
    m.anchor('cast', (40, 43.5))
    m.part('heldL', (15, 36), 'armL')
    m.slab([(3, 19), (17, 18), (18, 44), (10, 51), (2, 44)], 11, 2.0, 'shield', rough(0.06))   # a tower shield
    m.block(9.5, 20, 11.5, 48, 13.5, 0.6, 'iron')
    m.block(4, 31, 17, 33, 13.5, 0.6, 'iron')
    m.part('head', (27, 15))
    m.block(22.5, 8.5, 31.5, 10.5, 10.5, 0.5, 'void')                         # the visor slit
    eyes(m, 27, 9.5, 2.0, 9.6, 'eye', 0.7)
    spike(m, (27, 3), (27, -1), 1.0, 9, 'iron')
    m.part(None)
    return m, M


def blood_knight(t):
    M = {'armor': g([0x08080c, 0x121218, 0x1c1c26, 0x2a2a38, 0x3e3e52, 0x5a5a72], facet=8, spec=0.7),
         'cape': g([0x2a0408, 0x46080e, 0x680e16, 0x8e1a22, 0xb02a30]), 'red': glow(0xa00810, 0xff2a30, 0xff9090, base=0.2),
         'steel': g([0x4a5260, 0x7c8698, 0xb4bed0, 0xeef2ff], spec=0.9, facet=8), 'gold': g([0x5a420c, 0x9a7418, 0xd8a830], facet=8)}
    m = Model(54, 60)
    m.membrane([(14, 17), (38, 17), (46, 54), (38, 57), (27, 54), (16, 57), (8, 54)], -8, 'cape', (0, -0.15), folds(0.12, 3.5, 4))
    knight(m, 'armor', 27, seed=37)
    m.block(26, 20, 28, 30, 9, 0.6, 'red')                                    # a red cross on his breastplate
    m.block(23, 23.5, 31, 25.5, 9, 0.6, 'red')
    m.part('heldR', (36, 34), 'armR')
    m.slab([(25.6, 36), (28.4, 36), (28.4, 54), (27, 58), (25.6, 54)], 14, 0.8, 'steel')   # a greatsword, point down
    m.block(21, 34, 33, 36, 15, 0.6, 'gold')
    m.block(26, 28, 28, 34, 15, 0.6, 'cape')
    m.part('head', (27, 15))
    m.block(22.5, 8.5, 31.5, 10.5, 10.5, 0.5, 'red')                          # the burning visor
    for s in (-1, 1):
        m.part('head', (27, 15))
        spike(m, (27 + s * 4, 4), (27 + s * 10, -0.5), 1.4, 10, 'armor')
        m.part('armR' if s > 0 else 'armL', (27 + s * 9, 18))
        spike(m, (27 + s * 9, 14.5), (27 + s * 13, 9), 1.2, 10, 'armor')
    m.part(None)
    return m, M


def sunken_lord(t):
    M = {'armor': g([0x0a1616, 0x142626, 0x203a3a, 0x2e5250, 0x426e6a, 0x5e8c86], facet=8, spec=0.4), 'weed': g([0x0e2414, 0x1a3c22, 0x2a5a32]),
         'barn': g([0x4a4a3c, 0x7a7862, 0xaaa88c]), 'rust': g([0x2a1a10, 0x4a2c18, 0x6a4024], facet=8), 'eye': glow(0xd06010, 0xffa040, 0xffe0a0)}
    m = Model(52, 60)
    knight(m, 'armor', 25, seed=9)
    m.part('head', (25, 15))
    m.block(20.5, 8.5, 29.5, 10.5, 10.5, 0.5, 'eye')                          # one burning slit in the helm
    spike(m, (25, 3), (25, -1.5), 1.4, 9, 'armor')
    m.part('heldR', (37, 34), 'armR')
    m.capsule((43, 8, 11), (43, 52, 11), 1.1, 1.1, 'rust')                    # the anchor
    m.capsule((37, 34, 9), (43, 34, 11), 1.3, 1.1, 'armor')                    # (the gauntlet on its shaft)
    m.block(38, 11, 48, 13, 11.5, 0.6, 'rust')
    m.chain([(36, 46, 11), (39, 52, 11.5), (43, 54, 12), (47, 52, 11.5), (50, 46, 11)], [1.2, 1.3, 1.4, 1.3, 1.2], 'rust')
    m.part(None)

    def growth(x, y, h):
        if h[2] != 'armor':
            return None
        v = vnoise(x * 0.35, y * 0.35, 21)
        return 'barn' if v > 0.8 else 'weed' if v < 0.15 else None
    m.paint(growth)
    return m, M


def sentinel(t):
    M = {'steel': g([0x14181e, 0x222832, 0x343c4a, 0x4a5466, 0x68748a, 0x8e9ab0], facet=8, spec=0.6), 'core': glow(0x2080d0, 0x60c0ff, 0xd0f0ff),
         'brass': g([0x5a420c, 0x9a7418, 0xd8a830, 0xffe080], facet=8, spec=0.6), 'eye': glow(0xc0a010, 0xffe040, 0xffffa0)}
    m = Model(50, 56)
    R = rough(0.05, 0.3, 91)
    m.slab([(14, 32), (36, 32), (25, 52 + t * 0.4)], 2, 3.0, 'steel', R)       # it floats on a point
    chest(m, 25, 14, 34, 12, 10, 4, 'steel', 3.5, R)
    m.block(13, 24, 37, 27, 9, 0.8, 'core')                                  # a band of light round its middle
    for s in (-1, 1):
        S = 'R' if s > 0 else 'L'
        m.part('arm' + S, (25 + s * 13, 18))
        pauldron(m, 25 + s * 13, 18, 6, 7, 7, 'steel', s, 2.2, R)
        plate(m, (25 + s * 15, 23), (25 + s * 16, 34), 2.8, 2.2, 6, 'steel', 1.4, R)
        m.anchor('hand' + S, (25 + s * 16, 34))
        m.part('head', (25, 14))
        spike(m, (25 + s * 3, 7), (25 + s * 4.5, 0.5), 1.2, 10, 'brass')
        m.part('wing' + S, (25 + s * 13, 18))
        m.sphere((25 + s * 21, 8 + t, 10), 1.2, 'core')
    m.part('head', (25, 14))
    m.slab([(20, 8), (30, 8), (31, 14), (19, 14)], 8, 1.8, 'steel', R)
    eyes(m, 25, 11, 2.2, 8.6, 'eye', 0.8)
    m.anchor('cast', (25, 11))
    m.part(None)
    return m, M


MODELS = [('titan', ember_titan), ('colossus', colossus), ('frost_warden', frost_warden), ('flame_warden', furnace_warden),
          ('vault_ignis', ignis), ('warden', crypt_warden), ('blood_knight', blood_knight), ('sunken_lord', sunken_lord),
          ('sentinel', sentinel)]


def all_designs():
    return designs(MODELS)


if __name__ == '__main__':
    import sys
    sheet(MODELS[:5], sys.argv[1], sc=4)
    sheet(MODELS[5:], sys.argv[2], sc=4)


# how each moves (posed.py)
RIG = {
    'titan': {'heavy': True}, 'colossus': {'heavy': True}, 'frost_warden': {'heavy': True},
    'flame_warden': {'heavy': True}, 'vault_ignis': {}, 'warden': {}, 'blood_knight': {},
    'sunken_lord': {'held': 'staff'}, 'sentinel': {'fly': True},
}
