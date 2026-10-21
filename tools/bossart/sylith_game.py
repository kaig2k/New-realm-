"""
Sylith the Frost Wyrm, after the user's art and sheet (ref/sylith.webp, ref/sylith_sheet.webp),
modelled in solids and rendered to shaded pixel art (sdfart.py): a dragon in profile facing
right, a horned head with frost in its open jaws, an S-curved neck, a great bat wing raised over
her back (finger bones fanning out, membrane between them), four clawed legs and a long tail
ending in a spade. Dark ice-blue scales; icy cyan light only in her eye, jaws and spine tips.
sylith.py animates this picture.
"""
from sdfart import Model, scales, rough, folds, to_rows

W, H = 66, 58
MATS = {
    'hide': {'ramp': [0x080c18, 0x121c38, 0x1c2e5a, 0x284480, 0x3a60a8, 0x5a86cc], 'spec': 0.25},
    'far': {'ramp': [0x060914, 0x0c1428, 0x141f40, 0x1e2e5a]},
    'belly': {'ramp': [0x1e2640, 0x323e64, 0x4c5a86, 0x6e7caa, 0x93a2cc]},
    'wing': {'ramp': [0x070b16, 0x0d1428, 0x15203e, 0x1f3058, 0x2c4474], 'rimk': 0.7},
    'bone': {'ramp': [0x2a3858, 0x46608e, 0x6a8ac0, 0x9ab8e8], 'gamma': 1.0},
    'horn': {'ramp': [0x3a4256, 0x626e88, 0x95a4c0, 0xcfdcf2]},
    'glow': {'ramp': [0x1a90d0, 0x5ad0ff, 0xb8f4ff, 0xffffff], 'glow': True},
}


def wingshade(x, y, n):
    # the membrane darkens away from the arm (toward its trailing edge), with faint folds between the fingers
    import math
    d = abs((x - 31) * 0.6 + (y - 28) * -0.8) / 18          # rough distance from the arm's line
    return -0.28 * min(1.0, d) + 0.05 * math.sin((x * 0.9 + y * 0.5))


def model():
    m = Model(W, H)
    S, R = scales(2.4, 0.11), rough(0.08)
    # ---- the far wing, behind her back
    m.membrane([(38, 27), (44, 12), (50, 7), (48, 16), (49, 22), (44, 26)], -10, 'wing', (0.2, -0.4), folds(0.08, 3))
    m.capsule((38, 27, -9), (50, 7, -9), 1.4, 0.8, 'bone')
    # ---- far legs (in shadow)
    m.capsule((38, 38, -7), (37, 46, -7), 3.0, 2.4, 'far'); m.capsule((37, 46, -7), (38, 53, -7), 2.2, 1.8, 'far')
    m.capsule((24, 40, -7), (27, 47, -7), 3.0, 2.2, 'far'); m.capsule((27, 47, -7), (26, 53, -7), 2.0, 1.8, 'far')
    # ---- the tail: tapering, sweeping back and curling up into a spade
    m.chain([(18, 37, 0), (11, 41, -1), (6, 46, -1), (4, 51, 0), (8, 54, 1), (13, 53, 1)], [5.5, 4.4, 3.4, 2.6, 2.0, 1.5], 'hide', S)
    m.membrane([(12, 50), (18, 52), (14, 56)], 2, 'hide', (0.3, -0.4))
    # ---- body and chest
    m.sphere((29, 36, 0), 11, 'hide', 1.45, 0.82, 0.95, S)
    m.sphere((40, 33, 2), 8.2, 'hide', 1.0, 1.0, 1.0, S)
    m.sphere((33, 41, 3), 7.5, 'belly', 1.5, 0.45, 0.9, scales(2.0, 0.1))
    # ---- the neck, an S-curve up to the head, belly plates down its front
    m.chain([(42, 30, 2), (46, 23, 3), (47, 17, 3), (50, 12, 3)], [6.2, 5.0, 4.4, 4.0], 'hide', S)
    m.chain([(45, 33, 6), (49, 25, 6), (50, 19, 5.5), (53, 14, 5)], [2.6, 2.3, 2.0, 1.6], 'belly', scales(1.6, 0.12))
    # ---- the head: skull, a long snout, the jaw hanging open
    m.sphere((53, 9, 4), 5.0, 'hide', 1.25, 0.85, 1.0, R)
    m.capsule((55, 8.5, 4), (63, 10.5, 4), 3.4, 2.0, 'hide', R)
    m.capsule((54, 12.5, 3), (61, 15.5, 3), 2.2, 1.3, 'hide', R)
    m.capsule((56, 12.4, 7.5), (61, 13.8, 6), 1.1, 0.7, 'glow')         # frost in her jaws
    for x, y in ((58, 11.4), (60, 12), (57, 13.6)):
        m.sphere((x, y, 9), 0.7, 'horn')                                    # fangs
    m.sphere((55.5, 7.6, 10.5), 1.2, 'glow')                               # her eye
    m.capsule((52, 6.0, 9.5), (57.5, 5.8, 9.5), 1.0, 0.8, 'hide')           # the brow over it
    # horns sweeping back
    m.capsule((51, 5, 4), (44, 0.5, 3), 1.7, 0.4, 'horn')
    m.capsule((52, 6.5, 1), (46, 3.5, 0), 1.3, 0.3, 'horn')
    # ---- near legs: a coiled hind leg and a planted foreleg, with ice claws
    m.sphere((21, 39, 6), 6.8, 'hide', 0.95, 1.0, 0.9, S)
    m.capsule((22, 43, 7), (26, 49, 8), 3.2, 2.3, 'hide', S)
    m.capsule((26, 49, 8), (24, 53, 9), 2.2, 1.9, 'hide')
    m.capsule((41, 38, 7), (43, 46, 7), 3.6, 2.8, 'hide', S)
    m.capsule((43, 46, 7), (42, 52.5, 8), 2.6, 2.1, 'hide')
    for fx in (21.5, 24, 26.5, 39.5, 42, 44.5):
        m.capsule((fx, 53.5, 10), (fx + 0.8, 56, 10), 0.9, 0.4, 'horn')
    # ---- the near wing, raised high: arm bones, fingers fanning down-left, membrane between
    sh, el, wr = (31, 28, 9), (25, 16, 11), (17, 4, 11)
    tips = [(2, 9), (3, 20), (8, 29), (16, 33)]
    m.membrane([(31, 28), (25, 16), (17, 4), tips[0], (7, 14), tips[1], (8, 24), tips[2], (13, 30), tips[3], (24, 32)],
               9.5, 'wing', (-0.15, -0.35), wingshade)
    m.capsule(sh, el, 2.4, 1.9, 'bone'); m.capsule(el, wr, 1.9, 1.3, 'bone')
    for t in tips:
        m.capsule(wr, (t[0], t[1], 10.5), 1.1, 0.45, 'bone')
    m.capsule(wr, (15, 1, 11), 0.9, 0.3, 'horn')                            # the wrist claw
    # ---- spines down her neck and back, their tips lit with ice
    for (bx, by, tx, ty, z) in ((49, 12, 46, 8, 1), (47, 18, 43, 15, 1), (45, 24, 41, 22, 1), (38, 26, 36, 22, 1),
                                (32, 26, 30, 22, 0), (25, 27, 23, 23, 0), (18, 31, 15, 28, -1), (11, 37, 8, 35, -2)):
        m.capsule((bx, by, z + 4), (tx, ty, z + 4), 1.5, 0.35, 'horn')
        m.sphere((tx, ty, z + 6), 0.65, 'glow')
    return m


class _Pic:
    def __init__(self, rows):
        self._rows = rows

    def rows(self):
        return list(self._rows)


def image():
    return model().render(MATS)


_IMG = image()
ROWS, PAL = to_rows(_IMG)


def design():
    return _Pic(ROWS)


if __name__ == '__main__':
    import sys
    _IMG.save(sys.argv[1])
