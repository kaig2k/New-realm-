"""
Gorehorn the Behemoth, after the user's art (ref/gorehorn.png), modelled in solids and
rendered to shaded pixel art (sdfart.py): a hulking brute on four limbs, his heavy head
low between massive furred shoulders, two great bone horns sweeping out and up, tusks,
bone claws, and red fury glowing in his eyes, his maw and the cracks of his hide.
gorehorn.py animates this picture.
"""
from sdfart import Model, fur, rough, vnoise, to_rows

W, H = 62, 54
MATS = {
    'hide': {'ramp': [0x0a080c, 0x161118, 0x241b24, 0x342732, 0x4a3844, 0x66505c], 'spec': 0.1},
    'far': {'ramp': [0x070609, 0x100c12, 0x1a141b, 0x261d26]},
    'face': {'ramp': [0x08060a, 0x130e14, 0x1e161e, 0x2c212b]},
    'bone': {'ramp': [0x3a3026, 0x6a5c4a, 0x9c8c72, 0xcabb9c, 0xece0c4], 'spec': 0.3},
    'glow': {'ramp': [0x8a0c14, 0xd8202a, 0xff6040, 0xffc090], 'glow': True},
    'crack': {'ramp': [0x5a0810, 0x9a1018, 0xd82028], 'glow': True},
}


def model():
    m = Model(W, H)
    F, F2 = fur(0.16, 3), fur(0.12, 9)
    # ---- hind legs, set back and in shadow
    m.capsule((22, 36, -6), (21, 47, -4), 5.0, 3.8, 'far')
    m.capsule((40, 36, -6), (41, 47, -4), 5.0, 3.8, 'far')
    # ---- the great body and its hump
    m.sphere((31, 27, 0), 15, 'hide', 1.2, 0.85, 0.9, F)
    m.sphere((31, 18, -2), 11, 'hide', 1.3, 0.7, 0.9, F2)
    # massive shoulders
    m.sphere((17, 23, 4), 9.5, 'hide', 1.0, 0.95, 1.0, F)
    m.sphere((45, 23, 4), 9.5, 'hide', 1.0, 0.95, 1.0, F)
    # ---- forelimbs: thick arms down to clawed fists planted on the ground
    for s in (-1, 1):
        x0 = 31 + s * 15
        m.capsule((x0, 27, 9), (x0 + s * 3, 39, 11), 5.4, 4.2, 'hide', F2)
        m.capsule((x0 + s * 3, 39, 11), (x0 + s * 2, 46, 12), 4.2, 3.8, 'hide', F2)
        m.sphere((x0 + s * 2, 47.5, 13), 4.0, 'hide', 1.3, 0.6, 1.0)
        for k in (-2, 0, 2):
            cx = x0 + s * 2 + k * 1.6
            m.capsule((cx, 48.5, 16), (cx + k * 0.3, 51.5, 16), 1.0, 0.4, 'bone')
    # ---- the head, low between his shoulders
    m.sphere((31, 25, 11), 7.6, 'face', 1.05, 0.95, 1.0, rough(0.08))
    m.sphere((31, 31, 15), 4.8, 'face', 1.25, 0.75, 1.0, rough(0.06))
    m.capsule((25, 21.5, 16.5), (37, 21.5, 16.5), 1.9, 1.9, 'hide')           # the heavy brow
    for ex in (27, 34):                                                     # eyes: under the brow, burning
        m.mark(ex - 1, 24, None, 4, 1)
        m.mark(ex, 25, 'glow', 2, 1)
    m.capsule((28.4, 33.6, 19.2), (33.6, 33.6, 19.2), 1.0, 1.0, 'glow')       # the maw
    for s in (-1, 1):
        m.capsule((31 + s * 3.5, 33.5, 19), (31 + s * 5, 29.5, 19.5), 1.1, 0.35, 'bone')   # tusks
    # ---- the horns: thick at his brow, sweeping out and up to points
    for s in (-1, 1):
        pts = [(31 + s * 6, 20, 12), (31 + s * 13, 15, 12), (31 + s * 17, 8, 11), (31 + s * 16, 2, 10)]
        m.chain(pts, [2.8, 2.2, 1.5, 0.5], 'bone')
    # ---- bone spikes along his hump
    for x, y, tx, ty in ((22, 12, 20, 6), (28, 10, 27, 4), (35, 10, 36, 4), (41, 12, 43, 6)):
        m.capsule((x, y, 3), (tx, ty, 3), 1.6, 0.4, 'bone')

    # ---- red cracks glowing through his hide
    def cracks(x, y, h):
        if h[2] not in ('hide',):
            return None
        wx = x + vnoise(x * 0.15, y * 0.15, 4) * 6
        v = vnoise(wx * 0.18, y * 0.2, 11)
        if abs(v - 0.5) < 0.014 and h[1][2] > 0.45:
            return 'crack'
        return None
    m.paint(cracks)
    return m


class _Pic:
    def __init__(self, rows):
        self._rows = rows

    def rows(self):
        return list(self._rows)


def image():
    img = model().render(MATS)
    # a crack pixel on its own reads as a speck: give it back to the hide around it
    crack = {((v >> 16) & 255, (v >> 8) & 255, v & 255) for v in MATS['crack']['ramp']}
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            if px[x, y][:3] not in crack:
                continue
            nb = [px[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1))
                  if 0 <= x + dx < img.width and 0 <= y + dy < img.height]
            if sum(1 for q in nb if q[:3] in crack) < 1:
                others = [q for q in nb if q[3] and q[:3] not in crack]
                if others:
                    px[x, y] = others[0]
    return img


_IMG = image()
ROWS, PAL = to_rows(_IMG)


def design():
    return _Pic(ROWS)


if __name__ == '__main__':
    import sys
    _IMG.save(sys.argv[1])
