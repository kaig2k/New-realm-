"""
Halloween in the realm: the Pumpkin King, a world boss that rises every ten minutes (server.js
hallowTick), and his jack-o'-lanterns. Modelled like the other shaded bosses (sdfart.py) and
rigged for posed.py.

The Pumpkin King: a tall scarecrow lord in a tattered black coat trimmed in orange, straw at his
cuffs and collar, a great carved pumpkin for a head that burns from inside, a scythe in his right
hand and a lantern of green witch-fire in his left.
"""
import math
from sdfart import Model, rough, folds
from shaded_kit import g, glow, robe, arm, held, legs, designs, sheet, flame

PUMPKIN = g([0x5a1e04, 0x8a3608, 0xc4560c, 0xec7a18, 0xffa040], spec=0.35)
RIB = g([0x3a1404, 0x5c2206, 0x84340a])
CARVE = glow(0xc04000, 0xff9020, 0xffe060, 0xfffbd0, base=0.45)
STEM = g([0x1c2a0e, 0x2e4416, 0x48641e])
COAT = g([0x0a0612, 0x160c22, 0x241436, 0x34204c, 0x48306a], gamma=1.1)
TRIM = g([0x6a2a04, 0xa84a0a, 0xe07418, 0xffa040])
STRAW = g([0x6a5014, 0xa8862a, 0xd8b440, 0xf4dc80])
SHAFT = g([0x1e140c, 0x34241a, 0x4e3828, 0x6a4e38])
BLADE = g([0x2a2a34, 0x4e4e5c, 0x8a8a9c, 0xc8c8d8, 0xf0f0ff], spec=0.8)
WITCH = glow(0x1a6010, 0x40c020, 0x9aff60, 0xe8ffc8, base=0.35)
IRON = g([0x141418, 0x26262e, 0x3c3c48], spec=0.4)
BOOT = g([0x0c0808, 0x1a1210, 0x2a1e1a])


def _pumpkin(m, cx, cy, r, z, t, grin=True):
    """A pumpkin: lobes side by side, ribs between them, a stem, and a face carved into it, lit from inside."""
    for k, (dx, s) in enumerate(((-0.62, 0.62), (0.62, 0.62), (-0.32, 0.8), (0.32, 0.8), (0, 0.86))):
        m.sphere((cx + dx * r * 0.9, cy, z + (0.2 if abs(dx) > 0.5 else 0.6) * r), r * s, 'pumpkin', 1.0, 1.0, 0.9)
    for dx in (-0.47, 0, 0.47):
        m.capsule((cx + dx * r, cy - r * 0.78, z + r * 0.9), (cx + dx * r, cy + r * 0.78, z + r * 0.9), 0.35, 0.35, 'rib')
    m.capsule((cx, cy - r * 0.7, z + 0.3 * r), (cx + 1.5, cy - r * 1.2, z + 0.3 * r), r * 0.16, r * 0.1, 'stem')
    # the carved face: two triangle eyes and a jagged grin, burning from within
    fz = z + r * 1.45
    for s in (-1, 1):
        ex = cx + s * r * 0.36
        m.membrane([(ex - r * 0.2, cy - r * 0.08), (ex + r * 0.2, cy - r * 0.08), (ex + s * r * 0.04, cy - r * 0.42)], fz, 'carve')
    m.membrane([(cx - r * 0.1, cy + r * 0.02), (cx + r * 0.1, cy + r * 0.02), (cx, cy - r * 0.16)], fz, 'carve')
    if grin:
        w, top, bot = r * 0.6, cy + r * 0.2, cy + r * 0.56 + t * 0.4
        pts = [(cx - w, top)]
        for k in range(1, 6):
            x = cx - w + k * w * 2 / 6
            pts.append((x, top + (r * 0.12 if k % 2 else 0)))
        pts.append((cx + w, top))
        pts.append((cx + w * 0.7, bot))
        for k in range(5, 0, -1):
            x = cx - w * 0.7 + k * w * 1.4 / 6
            pts.append((x, bot - (r * 0.12 if k % 2 else 0)))
        pts.append((cx - w * 0.7, bot))
        m.membrane(pts, fz, 'carve')


# ---------------------------------------------------------------- the Pumpkin King
def pumpkin_king(t):
    M = {'pumpkin': PUMPKIN, 'rib': RIB, 'carve': CARVE, 'stem': STEM, 'coat': COAT, 'trim': TRIM, 'straw': STRAW,
         'shaft': SHAFT, 'blade': BLADE, 'witch': WITCH, 'iron': IRON, 'boot': BOOT,
         'flame': glow(0xc03000, 0xff8020, 0xffd060, base=0.3)}
    m = Model(64, 70)
    cx = 30
    # the coat, long and tattered, a split up the front showing his boots
    legs(m, cx, 44, 66, 3.4, 2.6, 'boot')
    robe(m, cx, 22, 58, 7, 15, 'coat', trim='trim', seed=11)
    m.capsule((cx, 40, 9), (cx, 58, 13), 0.9, 1.6, 'boot')                                      # the split in the coat
    # straw bursting from the collar and the cuffs
    for k in range(7):
        a = -1.2 + k * 0.4
        m.capsule((cx + math.sin(a) * 6, 22, 5), (cx + math.sin(a) * 9.5, 19 - math.cos(a) * 1.5, 6), 0.7, 0.3, 'straw')
    # a belt and a buckle
    m.capsule((cx - 9, 36, 7), (cx + 9, 36, 7), 1.1, 1.1, 'iron')
    m.sphere((cx, 36, 8.5), 1.6, 'trim', 1.2, 1.0, 0.6)
    # right arm: the scythe, held high, its blade curving out over his head
    arm(m, (cx + 7, 24, 4), (cx + 13, 31, 6), (cx + 16, 36, 9), 2.6, 'coat', 'straw', 1.8)
    held(m, 'R')
    m.capsule((cx + 18, 15, 9), (cx + 15, 62, 9), 0.9, 0.9, 'shaft')
    # the blade: a long crescent curving out and down from the top of the shaft
    pts = [(cx + 18 + 18 * math.sin(a), 20 - 8 * math.cos(a) + a * 3.0, 11) for a in [k * 0.22 for k in range(9)]]
    m.chain(pts, [2.0, 2.3, 2.3, 2.1, 1.8, 1.5, 1.1, 0.7, 0.3], 'blade')
    m.anchor('strike', (cx + 35, 21))
    m.part(None)
    # left arm: the lantern of witch-fire
    arm(m, (cx - 7, 24, 4), (cx - 12, 31, 6), (cx - 13, 38, 9), 2.6, 'coat', 'straw', 1.8)
    held(m, 'L')
    m.capsule((cx - 13, 38, 9), (cx - 13, 41, 9), 0.4, 0.4, 'iron')
    m.capsule((cx - 16, 42, 9), (cx - 10, 42, 9), 0.8, 0.8, 'iron')
    m.capsule((cx - 16, 49, 9), (cx - 10, 49, 9), 0.9, 0.9, 'iron')
    m.sphere((cx - 13, 45.5, 9.5), 3.1 + t * 0.3, 'witch', 0.95, 1.15, 0.9)
    for x in (-16, -10):
        m.capsule((cx + x, 42, 10), (cx + x, 49, 10), 0.35, 0.35, 'iron')
    m.anchor('cast', (cx - 13, 45.5))
    m.part(None)
    # the head: a great carved pumpkin, burning inside, flames licking out of its top
    m.part('head', (cx, 21))
    _pumpkin(m, cx, 13, 9.5, 4, t)
    m.part('hem0', (cx, 4))
    flame(m, cx + 0.5, 6, 6 + t, 4, ('flame', 'carve'), z=6, t=t)
    m.anchor('mouth', (cx, 17))
    m.part(None)
    return m, M


# ---------------------------------------------------------------- the jack-o'-lantern
def jack_lantern(t):
    M = {'pumpkin': PUMPKIN, 'rib': RIB, 'carve': CARVE, 'stem': STEM, 'leaf': g([0x16300a, 0x2a5414, 0x44801e])}
    m = Model(24, 24)
    # it hops: squashed on the ground, then up
    y = 13 - t * 1.5
    _pumpkin(m, 12, y, 7.4, 2, t)
    m.capsule((14, y - 6.6, 4), (18, y - 8.5, 4), 0.9, 0.4, 'leaf')
    return m, M


MODELS = [('pumpkin_king', pumpkin_king), ('jack_lantern', jack_lantern)]
RIG = {
    'pumpkin_king': {'held': 'blade', 'cast': 'one', 'heavy': True},
    'jack_lantern': {'legs': False, 'arms': 0, 'still': True},
}


def all_designs():
    return designs(MODELS)


if __name__ == '__main__':
    import sys
    sheet(MODELS, sys.argv[1], 5)
