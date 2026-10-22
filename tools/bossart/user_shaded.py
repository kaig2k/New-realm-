"""
The five bosses first drawn from the user's own sheets (vorgath.py, elder.py, herald.py, tempestus.py,
vesper.py), rebuilt shaded from solids like every other boss so they share the posed animations
(posed.py) and the look: Vorgath the Siege Warlord, Azrakor the Dark Elder, the Abyssal Herald,
Tempestus and Archon Vesper. Their designs are kept: the shapes, the colours, what they hold.
"""
import math
from sdfart import Model, rough, folds, scales, fur, vnoise
from shaded_kit import g, glow, robe, torso, arm, held, legs, head, eyes, hood, crown, staff, wing, flame, designs, sheet, \
    chest, plate, pauldron, rock, spike

VOID = g([0x040306, 0x0a080e])


# ---------------------------------------------------------------- Vorgath the Siege Warlord
def vorgath(t):
    """A black-armoured warlord: gold trim, a gold crown on his great helm, eyes burning red through its slit,
    a red tabard and cape; a spiked flail in one hand, a black kite shield with a red cross in the other."""
    M = {'iron': g([0x07070a, 0x121218, 0x1e1e28, 0x30303e, 0x484858], facet=7, spec=0.6),
         'gold': g([0x5a3e0a, 0x9a7014, 0xd4a42c, 0xffe080], spec=0.8), 'red': g([0x3a0408, 0x660a10, 0x941820, 0xc02a30]),
         'eye': glow(0xa00000, 0xff3020, 0xffc0a0, base=0.2), 'void': VOID, 'chain': g([0x2a2a30, 0x55555e, 0x8a8a96], spec=0.8)}
    m = Model(68, 68)
    cx = 34
    # the cape behind him, falling to the ground in points
    m.slab([(cx - 11, 21), (cx + 11, 21), (cx + 17, 62), (cx - 17, 62)], -8, 2.0, 'red', folds(0.12, 3.4, 4))
    for k in range(4):
        spike(m, (cx - 12 + k * 8, 61), (cx - 13 + k * 8.6, 67), 2.8, -8, 'red')
    legs(m, cx, 42, 66, 5.4, 4.2, 'iron')
    for s in (-1, 1):
        plate(m, (cx + s * 5.6, 50), (cx + s * 5.8, 56), 3.4, 3.0, 5, 'gold', bevel=1.0)     # gold knee-guards
    chest(m, cx, 22, 44, 12.5, 10, 3, 'iron', bevel=3.0)
    m.capsule((cx - 6.5, 25, 9.2), (cx + 6.5, 25, 9.2), 0.8, 0.8, 'gold')
    m.capsule((cx, 27, 10.2), (cx, 50, 10), 3.0, 3.8, 'red', folds(0.08, 3, 6), cut=52)     # the tabard
    m.capsule((cx - 6, 41, 10.5), (cx + 6, 41, 10.5), 1.4, 1.4, 'gold')                   # a gold belt
    m.sphere((cx, 41, 12), 1.6, 'gold')
    for s in (-1, 1):
        pauldron(m, cx + s * 13, 23, 7.5, 5.5, 5, 'iron', s, bevel=2.0)
        m.capsule((cx + s * 7, 20, 8.5), (cx + s * 19.5, 21.5, 8.5), 0.7, 0.7, 'gold')     # gold rims on them
        for k in range(3):
            spike(m, (cx + s * (10 + k * 3.5), 18.5), (cx + s * (10.5 + k * 3.5), 14.5 - (k == 1)), 1.0, 7, 'gold')
        arm(m, (cx + s * 13, 26, 4), (cx + s * 17, 34, 6), (cx + s * 16, 41, 8), 3.4, 'iron', 'iron', 3.2)
    held(m, 'R')                                                                               # the flail
    m.capsule((cx + 16, 41, 10), (cx + 19, 47, 10), 1.0, 1.0, 'iron')
    m.chain([(cx + 19, 47, 10), (cx + 23, 50 + t, 10), (cx + 27, 49 + t, 10)], [0.5, 0.5, 0.5], 'chain')
    m.sphere((cx + 28.5, 49 + t, 10), 4.2, 'iron', 1, 1, 1, rough(0.05))
    for k in range(8):
        a = k * math.pi / 4
        spike(m, (cx + 28.5 + math.cos(a) * 3.6, 49 + t + math.sin(a) * 3.6), (cx + 28.5 + math.cos(a) * 6.2, 49 + t + math.sin(a) * 6.2), 1.0, 11, 'gold')
    m.anchor('strike', (cx + 28, 49))
    m.part(None)
    held(m, 'L')                                                                               # the kite shield
    m.slab([(cx - 25, 28), (cx - 13, 28), (cx - 13, 46), (cx - 19, 54), (cx - 25, 46)], 11, 1.6, 'iron')
    m.capsule((cx - 25, 28, 12.5), (cx - 13, 28, 12.5), 0.8, 0.8, 'gold')
    m.capsule((cx - 19, 31, 13), (cx - 19, 49, 13), 1.2, 1.2, 'red')                      # its red cross
    m.capsule((cx - 23, 37, 13), (cx - 15, 37, 13), 1.2, 1.2, 'red')
    m.part(None)
    head(m, cx, 13, 6.4, 'iron')                                                              # the great helm
    plate(m, (cx, 7), (cx, 19), 6.4, 6.0, 7, 'iron', bevel=1.8)
    m.capsule((cx - 4, 13.5, 12.6), (cx + 4, 13.5, 12.6), 0.9, 0.9, 'void')                 # its slit, eyes burning in it
    m.mark(cx - 2, 13, 'eye', 2, 1); m.mark(cx + 1, 13, 'eye', 2, 1)
    m.capsule((cx, 15, 12.8), (cx, 18.5, 12.8), 0.5, 0.5, 'void')
    crown(m, cx, 6.5, 6.0, 'gold', spikes=7, tall=4.6, z=8, gem='red')
    m.part(None)
    return m, M


# ---------------------------------------------------------------- Azrakor the Dark Elder
def elder(t):
    """A towering hooded figure: a pale grey pointed hood over a face of void with a violet crystal burning in
    it, robes of the deepest violet with a glowing seam, tendrils of the void out of his back, and void orbs
    circling him."""
    M = {'robe': g([0x0a0612, 0x140c22, 0x1e1234, 0x2c1a4a, 0x3c2462]), 'hood': g([0x3a3644, 0x5e5a6c, 0x8a869a, 0xb8b4c8], facet=8),
         'void': VOID, 'crystal': glow(0x6010c0, 0xb050ff, 0xffe0ff, base=0.25), 'seam': glow(0x6a20c0, 0xc070ff, base=0.3),
         'tendril': g([0x08040e, 0x160a24, 0x26123c, 0x3a1c58]), 'orb': VOID, 'rim': glow(0x7020d0, 0xd090ff, base=0.3)}
    m = Model(70, 72)
    cx = 35
    for s in (-1, 1):                                                                          # tendrils out of his back
        for k in range(3):
            a = -0.4 - k * 0.45
            sx, sy = cx + s * 6, 26 + k * 4
            pts = [(sx, sy, -3)]
            for j in range(1, 5):
                pts.append((sx + s * j * 4.2, sy + math.sin(a) * j * 3.2 + math.sin(j * 1.3 + t + k) * 1.4, -3 - j * 0.3))
            m.chain(pts, [2.6, 2.2, 1.7, 1.1, 0.5], 'tendril')
    robe(m, cx, 24, 70, 8, 15, 'robe', seed=11)
    torso(m, cx, 24, 38, 7.5, 'robe')
    m.capsule((cx, 26, 9.4), (cx, 68, 12), 0.7, 0.9, 'seam')                                 # the glowing seam
    for k in range(4):
        m.sphere((cx, 32 + k * 9, 10.5 + k * 0.4), 1.2, 'seam')
    for s in (-1, 1):
        m.sphere((cx + s * 8, 24, 5), 4.4, 'hood', 1.1, 0.75, 1)                             # the hood's shoulders
        arm(m, (cx + s * 9, 26, 5), (cx + s * 12, 35, 7), (cx + s * 11, 42, 9), 2.6, 'robe', 'void', 2.0)
    head(m, cx, 16, 7.0, 'hood')
    m.capsule((cx, 14, 4), (cx, 1 + t * 0.5, 3), 6.0, 0.6, 'hood', folds(0.1, 3, 13))      # the hood's tall point
    m.sphere((cx, 18, 8.4), 4.8, 'void', 0.9, 1.25, 0.6)                                      # the void in it
    m.slab([(cx, 12.5), (cx + 2.0, 18), (cx, 23.5), (cx - 2.0, 18)], 13.5, 0.6, 'crystal')   # his crystal
    m.part(None)
    for k in range(4):                                                                         # void orbs about him
        a = k * math.pi / 2 + 0.6 + t * 0.4
        ox, oy = cx + math.cos(a) * 28, 40 + math.sin(a) * 22
        m.sphere((ox, oy, 14), 3.4, 'rim')
        m.sphere((ox, oy, 15.5), 2.4, 'orb')
    return m, M


# ---------------------------------------------------------------- the Abyssal Herald
def herald(t):
    """The Herald of the deep: navy robes with seams of cyan light, a crown of black spines, one cyan eye in a
    face of void, tentacles coiling from under its hem, a pale trident, and abyssal orbs ringed in cyan."""
    M = {'robe': g([0x050a18, 0x0a1428, 0x101e3c, 0x182a52, 0x22386a]), 'seam': glow(0x0a6a9a, 0x30d0ff, 0xc0f8ff, base=0.3),
         'spine': g([0x060a14, 0x0e1626, 0x1a2640, 0x2a3a5c], facet=7), 'void': VOID, 'eye': glow(0x0a8aba, 0x60e8ff, 0xffffff, base=0.2),
         'tent': g([0x08101e, 0x122036, 0x1e3250, 0x2c466c]), 'pale': g([0x5a7090, 0x8aa4c4, 0xc0d8f0, 0xffffff], spec=0.8), 'rim': glow(0x0a8aba, 0x60e8ff, base=0.3)}
    m = Model(70, 72)
    cx = 33
    for s in (-1, 1):                                                                          # tentacles from under its hem
        for k in range(2):
            sx = cx + s * (8 + k * 5)
            m.chain([(sx, 58, 2), (sx + s * 6, 61 - t, 2), (sx + s * 11, 57 - k * 3, 2), (sx + s * 13, 51 - k * 4 + t, 2)],
                    [2.4, 1.8, 1.2, 0.5], 'tent')
    robe(m, cx, 22, 68, 8, 13, 'robe', seed=17)
    torso(m, cx, 22, 36, 7.5, 'robe')
    for s in (-1, 0, 1):                                                                       # seams of light
        m.capsule((cx + s * 4, 25, 8.6), (cx + s * 6, 66, 11), 0.5, 0.6, 'seam')
    for k in range(4):
        m.sphere((cx, 30 + k * 9, 10), 1.0, 'seam')
    for s in (-1, 1):
        for k in range(3):                                                                     # spines on its shoulders
            spike(m, (cx + s * (6 + k * 2.6), 22), (cx + s * (8 + k * 3.4), 14 - k), 1.2, 6, 'spine')
        arm(m, (cx + s * 8.5, 24, 5), (cx + s * 12, 33, 7), (cx + s * 11, 40, 9), 2.5, 'robe', 'spine', 1.9)
    staff(m, cx + 13, 6, 66, 'pale', z=10, r=0.8)                                              # the trident
    for k in (-1, 0, 1):
        m.capsule((cx + 13 + k * 2.6, 7, 10.5), (cx + 13 + k * 2.6, 1.5 + (k == 0) * -1, 10.5), 0.5, 0.3, 'pale')
    m.capsule((cx + 10.4, 7, 10.5), (cx + 15.6, 7, 10.5), 0.5, 0.5, 'pale')
    m.part(None)
    head(m, cx, 14, 6.4, 'robe')
    m.sphere((cx, 15, 8), 4.8, 'void', 0.95, 1.15, 0.6)
    m.sphere((cx, 14, 11), 1.6, 'eye')                                                         # its one eye
    for k in range(7):                                                                         # its crown of spines
        x = cx - 6 + k * 2
        spike(m, (x, 9), (x + (k - 3) * 0.6, 2 - (k % 2) * 2.5), 1.0, 6, 'spine')
    m.part(None)
    for k in range(3):                                                                         # orbs of the abyss
        a = k * 2.1 + 0.4 + t * 0.4
        ox, oy = cx + math.cos(a) * 27, 38 + math.sin(a) * 20
        m.sphere((ox, oy, 14), 3.0, 'rim')
        m.sphere((ox, oy, 15.5), 2.1, 'void')
    return m, M


# ---------------------------------------------------------------- Tempestus, Heart of the Storm
def tempestus(t):
    """A hooded storm-lord: a tall pointed hood of deep navy under a ring of violet storm-light, a face of void
    with one white-violet eye, silver spikes on his shoulders, a long cape split behind, and grey-armoured legs."""
    M = {'cloak': g([0x060818, 0x0c1028, 0x141a3e, 0x1e2658, 0x2a3474]), 'silver': g([0x4a4a5e, 0x7a7a94, 0xb0b0cc, 0xe8e8ff], spec=0.9, facet=7),
         'void': VOID, 'eye': glow(0x8040ff, 0xe0c0ff, 0xffffff, base=0.25), 'halo': glow(0x5a20c0, 0xa060ff, 0xe0c8ff, base=0.3),
         'seam': glow(0x5a20c0, 0xa070ff, base=0.3), 'leg': g([0x2a2a3a, 0x48485e, 0x6e6e88, 0x9a9ab4], spec=0.6)}
    m = Model(64, 76)
    cx = 32
    # the halo of storm-light behind his hood
    for k in range(28):
        a, a2 = k * math.pi / 14, (k + 1) * math.pi / 14
        m.capsule((cx + math.cos(a) * 15, 16 + math.sin(a) * 15, -6), (cx + math.cos(a2) * 15, 16 + math.sin(a2) * 15, -6), 0.8, 0.8, 'halo')
    m.sphere((cx, 1 + t * 0.6, 2), 1.6, 'halo')                                               # a spark at its crown
    legs(m, cx, 50, 74, 3.2, 2.8, 'leg')
    for s in (-1, 1):                                                                          # the cape, split in two behind
        m.capsule((cx + s * 4, 24, -3), (cx + s * 10, 70, -3), 6, 7.5, 'cloak', folds(0.1, 3, 5 + s), cut=71)
    torso(m, cx, 24, 52, 7.8, 'cloak')
    m.capsule((cx, 28, 9), (cx, 50, 8.5), 0.6, 0.6, 'seam')
    m.sphere((cx, 36, 9.5), 1.4, 'eye')
    m.capsule((cx - 6, 48, 8), (cx + 6, 48, 8), 1.0, 1.0, 'silver')                           # a silver belt
    for s in (-1, 1):
        pauldron(m, cx + s * 9, 25, 5.0, 3.6, 6, 'silver', s, bevel=1.6)
        for k in range(2):
            spike(m, (cx + s * (8 + k * 3.5), 22.5), (cx + s * (13 + k * 4), 15 - k * 2), 1.4, 7, 'silver')
        arm(m, (cx + s * 9, 27, 5), (cx + s * 12, 36, 7), (cx + s * 11, 43, 9), 2.4, 'cloak', 'silver', 1.8)
    head(m, cx, 16, 6.6, 'cloak')
    m.capsule((cx, 14, 4), (cx, 4, 3.5), 6.0, 0.8, 'cloak')                                  # the hood's point
    m.sphere((cx, 18, 8.2), 4.6, 'void', 0.9, 1.25, 0.6)
    m.sphere((cx, 17.5, 11), 1.5, 'eye')
    m.part(None)
    return m, M


# ---------------------------------------------------------------- Archon Vesper
def vesper(t):
    """The crimson Archon: armour of deep red edged in gold, a great fan of crimson blades spread behind him like
    wings, a helm with a T-slit, a red gem burning in his chest, and a gold spear."""
    M = {'red': g([0x2a0408, 0x4e0a10, 0x7a1018, 0xa81c24, 0xd0343a], facet=7, spec=0.5), 'gold': g([0x5a3e0a, 0x9a7014, 0xd4a42c, 0xffe080], spec=0.8),
         'blade': g([0x3a060a, 0x6a0e14, 0x9a1a22, 0xc8303a, 0xf05a60], facet=6, spec=0.6), 'void': VOID,
         'gem': glow(0xa00010, 0xff3040, 0xffd0d0, base=0.25), 'web': g([0x1a0204, 0x2e0408, 0x48080e])}
    m = Model(76, 74)
    cx = 38
    for s in (-1, 1):                                                                          # the fan of blades behind him, like wings
        for k in range(7):
            a = -math.pi / 2 + s * (0.35 + k * 0.2)
            ln = 34 - abs(k - 2) * 2.6
            bx, by = cx + s * 5, 24
            if k < 6:                                                                          # the dark web between the blades
                a2 = -math.pi / 2 + s * (0.35 + (k + 1) * 0.2)
                ln2 = 34 - abs(k + 1 - 2) * 2.6
                m.slab([(bx, by), (bx + math.cos(a) * ln * 0.8, by + math.sin(a) * ln * 0.6), (bx + math.cos(a2) * ln2 * 0.8, by + math.sin(a2) * ln2 * 0.6)],
                       -7, 0.8, 'web')
            spike(m, (bx + math.cos(a) * 4, by + math.sin(a) * 4), (bx + math.cos(a) * ln, by + math.sin(a) * ln * 0.75 - t * 0.6),
                  4.2 - k * 0.2, -4 - k * 0.3, 'blade')
            m.capsule((bx + math.cos(a) * 6, by + math.sin(a) * 6 * 0.75, -3.5 - k * 0.3), (bx + math.cos(a) * (ln - 6), by + math.sin(a) * (ln - 6) * 0.75, -3.5 - k * 0.3),
                      0.35, 0.25, 'gold')                                                     # a gold vein down each
    legs(m, cx, 46, 72, 4.6, 3.8, 'red')
    for s in (-1, 1):
        plate(m, (cx + s * 4.8, 56), (cx + s * 5, 70), 3.6, 3.4, 5, 'red', bevel=1.4)
    m.capsule((cx, 40, 1), (cx, 60, 1), 9, 11, 'red', folds(0.06, 3, 21), cut=60)          # a skirt of plates
    for k in range(3):
        m.capsule((cx - 10 + k * 0.4, 46 + k * 5, 9.5), (cx + 10 - k * 0.4, 46 + k * 5, 9.5), 0.6, 0.6, 'gold')
    chest(m, cx, 22, 44, 11, 9, 3, 'red', bevel=3.0)
    m.capsule((cx - 8, 30, 9), (cx, 36, 10.5), 0.8, 0.8, 'gold')                              # gold chevrons
    m.capsule((cx + 8, 30, 9), (cx, 36, 10.5), 0.8, 0.8, 'gold')
    m.sphere((cx, 33, 11.5), 2.4, 'gem')                                                      # the red gem
    for s in (-1, 1):
        pauldron(m, cx + s * 11.5, 23, 6.5, 4.6, 5, 'red', s, bevel=2.0)
        m.capsule((cx + s * 6, 20.5, 8.5), (cx + s * 17, 22, 8.5), 0.7, 0.7, 'gold')
        arm(m, (cx + s * 11, 26, 4), (cx + s * 14, 34, 6), (cx + s * 13, 41, 8), 3.0, 'red', 'gold', 2.4)
    held(m, 'R')                                                                               # the gold spear
    m.capsule((cx + 13, 70, 10), (cx + 18, 2 + t, 10), 0.8, 0.8, 'gold')
    spike(m, (cx + 17.6, 6 + t), (cx + 18.6, -2 + t), 2.0, 11, 'gold')
    m.anchor('strike', (cx + 18, 0))
    m.part(None)
    head(m, cx, 14, 6.4, 'red')
    plate(m, (cx, 8), (cx, 20), 6.2, 5.8, 7, 'red', bevel=1.8)                               # the helm
    m.capsule((cx - 4, 13, 12.6), (cx + 4, 13, 12.6), 0.8, 0.8, 'void')                      # its T-slit
    m.capsule((cx, 13, 12.8), (cx, 18, 12.8), 0.8, 0.8, 'void')
    spike(m, (cx, 8), (cx, 1), 1.6, 9, 'gold')                                                # a gold crest
    m.capsule((cx - 6, 9, 11), (cx + 6, 9, 11), 0.6, 0.6, 'gold')
    m.part(None)
    return m, M


MODELS = [('siege_warlord', vorgath), ('elder', elder), ('abyss_herald', herald), ('tempestus', tempestus), ('archon', vesper)]
RIG = {
    'siege_warlord': {'heavy': True, 'held': 'blade'}, 'elder': {'legs': False, 'cast': 'two'}, 'abyss_herald': {'legs': False, 'held': 'staff', 'cast': 'one'},
    'tempestus': {'cast': 'two'}, 'archon': {'held': 'staff', 'flap': 1.0},
}


def all_designs():
    return designs(MODELS)


if __name__ == '__main__':
    import sys
    sheet(MODELS, sys.argv[1], 3)
