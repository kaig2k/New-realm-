"""
Nerezza, the Tide Empress, after the user's art (ref/nerezza.jpg), modelled in solids and
rendered to shaded pixel art (sdfart.py): a tall spiked crown, a pale face framed in dark
hair, spiked pauldrons, a teal bodice, a long gown flaring to the floor with a cape behind,
one hand raised with an orb of glowing sea and the other on her trident. nerezza.py
animates this picture.
"""
import math
from sdfart import Model, folds, rough, to_rows

W, H = 48, 66
MATS = {
    'gown': {'ramp': [0x070a16, 0x0e1428, 0x172040, 0x22305a, 0x30447a, 0x44609c]},
    'cape': {'ramp': [0x060814, 0x0c1226, 0x141e3c, 0x1e2c56, 0x2a3e72], 'rimk': 0.6},
    'teal': {'ramp': [0x08242c, 0x103a46, 0x185462, 0x247484, 0x3a98a8]},
    'armor': {'ramp': [0x0a0e1c, 0x162038, 0x243458, 0x3a5280, 0x6a88b8], 'spec': 0.5},
    'skin': {'ramp': [0x4a5068, 0x6e7690, 0x949cb6, 0xbcc4d8, 0xdee4f0], 'gamma': 1.1},
    'hair': {'ramp': [0x06080e, 0x0c1020, 0x141c34, 0x1e2a4a]},
    'ice': {'ramp': [0x2a5a78, 0x4a8cb0, 0x7cc4e0, 0xc4f0ff], 'spec': 0.5},
    'staff': {'ramp': [0x0a0c14, 0x181c2c, 0x283046, 0x3c4862]},
    'glow': {'ramp': [0x1898c0, 0x4ad8f0, 0xa8f6ff, 0xffffff], 'glow': True},
}


def model():
    m = Model(W, H)
    # ---- the cape behind her, flaring wide, its hem ragged
    hem = []
    for k in range(9):
        x = 4 + k * 5
        hem.append((x, 63 - (k % 2) * 3))
    m.membrane([(16, 17), (32, 17), (40, 34), (45, 50), (46, 62)] + hem[::-1] + [(2, 62), (3, 50), (8, 34)], -9, 'cape',
               (0.0, -0.2), folds(0.12, 3.4, 2))
    # ---- the gown: a long bell from the waist to the floor
    m.capsule((24, 29, 0), (24, 57, 0), 4.0, 12.5, 'gown', folds(0.14, 2.8, 5))
    m.sphere((24, 58, 0), 13, 'gown', 1.05, 0.3, 1.0, folds(0.14, 2.8, 5))
    m.capsule((24, 31, 11), (24, 60, 12.5), 1.6, 2.4, 'teal', folds(0.08, 2.2, 6))    # the teal panel down its front
    for y in (36, 43, 50, 57):
        m.sphere((24, y, 13.5 + (y - 31) * 0.05), 0.75, 'glow')                      # glowing studs on its seam
    # ---- the bodice and waist
    m.capsule((24, 18, 2), (24, 29, 2), 5.0, 3.6, 'armor', rough(0.05))
    m.capsule((24, 18.5, 6.4), (24, 28, 5.2), 2.0, 1.4, 'teal')
    m.capsule((19.5, 29.5, 6), (28.5, 29.5, 6), 1.3, 1.3, 'armor')           # belt
    m.sphere((24, 29.6, 8), 1.2, 'glow')                                      # its gem
    # ---- spiked pauldrons
    for s in (-1, 1):
        m.sphere((24 + s * 7.2, 17.5, 4), 3.6, 'armor', 1.1, 0.85, 1.0)
        m.capsule((24 + s * 7.5, 15, 4), (24 + s * 10, 10.5, 3), 1.2, 0.3, 'ice')
        m.capsule((24 + s * 9.5, 16.5, 4), (24 + s * 12.5, 13.5, 3), 1.0, 0.3, 'ice')
    # ---- her raised arm, the orb of sea in her hand
    m.capsule((17, 19, 4), (12, 23, 5), 2.1, 1.8, 'armor')
    m.capsule((12, 23, 5), (9.6, 15, 6), 1.8, 1.4, 'armor')
    m.sphere((9, 12.6, 7), 1.5, 'skin')
    m.sphere((8.5, 7.5, 8), 3.1, 'glow')
    for a in range(6):
        t = a * math.pi / 3
        m.sphere((8.5 + math.cos(t) * 5, 7.5 + math.sin(t) * 4.2, 9), 0.55, 'glow')
    # ---- the other arm, down to the trident
    m.capsule((31, 19, 4), (34, 26, 5), 2.1, 1.8, 'armor')
    m.capsule((34, 26, 5), (36, 30, 6), 1.8, 1.5, 'armor')
    # ---- the trident: a dark shaft, prongs of glowing sea
    m.capsule((37, 7, 3), (37, 64, 3), 0.9, 0.9, 'staff')
    m.sphere((36.6, 30.8, 7), 1.5, 'skin')                                    # her hand round it
    m.capsule((34, 6.5, 4), (40, 6.5, 4), 0.8, 0.8, 'staff')
    for x in (34, 37, 40):
        m.capsule((x, 6.5, 5), (x, 0.8 if x == 37 else 2.2, 5), 0.75, 0.35, 'glow')
    # ---- her hair, falling to her shoulders behind her head
    m.sphere((24, 10.5, 0), 6.2, 'hair', 1.0, 1.05, 1.0)
    m.capsule((19, 11, 2), (17.6, 20, 2), 2.8, 1.6, 'hair')
    m.capsule((29, 11, 2), (30.4, 20, 2), 2.8, 1.6, 'hair')
    # ---- her face
    m.sphere((24, 12, 4.5), 4.3, 'skin', 0.88, 1.08, 1.0)
    m.capsule((20.6, 8.6, 7.4), (27.4, 8.6, 7.4), 1.1, 1.1, 'hair')          # her fringe
    m.sphere((22.4, 11.8, 8.5), 0.62, 'glow'); m.sphere((25.6, 11.8, 8.5), 0.62, 'glow')   # eyes like the sea
    # ---- the tall crown: five spikes of sea-ice, a gem at its heart
    m.capsule((19.2, 7.2, 6), (28.8, 7.2, 6), 1.0, 1.0, 'ice')
    for x, top, lean in ((19.4, 3.0, -1.2), (21.7, 1.4, -0.5), (24, -0.8, 0), (26.3, 1.4, 0.5), (28.6, 3.0, 1.2)):
        m.capsule((x, 7.2, 6), (x + lean, top, 6), 0.95 if x == 24 else 0.75, 0.25, 'ice')
    m.sphere((24, 6.2, 8), 0.85, 'glow')
    return m


_cache = None


class _Pic:
    def __init__(self, rows):
        self._rows = rows

    def rows(self):
        return list(self._rows)


def image():
    global _cache
    if _cache is None:
        img = model().render(MATS)
        # the teal panel and its glowing seam down the front of her gown
        _cache = img
    return _cache


def design():
    return _Pic(to_rows(image())[0])


def palette():
    return to_rows(image())[1]


if __name__ == '__main__':
    import sys
    image().save(sys.argv[1])
