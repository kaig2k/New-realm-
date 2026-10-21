"""
Nerezza, the Tide Empress, in Eldmere's boss style (ref/style/: small, dark,
a few tones, one glowing accent), after the user's art in ref/nerezza.jpg:
a tall spiked crown, a pale face in shadow, a dark gown flaring to a ragged
hem, a cape behind her, one hand raised with an orb of glowing sea and the
other on her trident. Sea-cyan is her one accent. Pixelled by hand, row by
row (each row is a list of runs); nerezza.py animates this picture.
"""

PAL = {
    # navy cloth: deepest, dark, mid, lit edge, rare highlight
    'K': 0x0a0d18, 'D': 0x151c30, 'M': 0x24304a, 'L': 0x38506e, 'H': 0x5a7898,
    # her skin, cold and pale (shadow, lit)
    's': 0x7a88a2, 'S': 0xb4c0d4,
    # teal panels down her gown
    't': 0x173f4c, 'T': 0x24687a,
    # the sea's glow: deep, bright, white-hot
    'c': 0x1aa8c0, 'C': 0x8ef0ff, 'W': 0xf0ffff,
}

W, H = 32, 46

# (y, x0, x1, colour): later runs paint over earlier ones
RUNS = [
    # ---- the cape, behind everything: from her shoulders out to a ragged hem
    *[(y, 15 - (y - 12) // 2 - 3, 16 + (y - 12) // 2 + 3, 'D') for y in range(12, 42)],
    *[(y, 15 - (y - 12) // 2 - 3, 15 - (y - 12) // 2 - 2, 'K') for y in range(14, 42)],
    *[(y, 16 + (y - 12) // 2 + 2, 16 + (y - 12) // 2 + 3, 'K') for y in range(14, 42)],
    (42, 1, 2, 'D'), (42, 5, 6, 'D'), (43, 2, 2, 'K'), (42, 25, 26, 'D'), (42, 29, 30, 'D'), (43, 29, 29, 'K'),
    # ---- the gown: narrow at the waist, flaring to the hem
    *[(y, 15 - (y - 20) // 3 - 3, 16 + (y - 20) // 3 + 3, 'M') for y in range(20, 44)],
    *[(y, 16 + (y - 20) // 3 + 1, 16 + (y - 20) // 3 + 3, 'D') for y in range(22, 44)],   # its shadowed side
    *[(y, 15 - (y - 20) // 3 - 3, 15 - (y - 20) // 3 - 3, 'L') for y in range(22, 40)],   # its lit edge
    # the teal panel down the front, with a glowing seam
    *[(y, 14 - (y - 22) // 6, 17 + (y - 22) // 6, 't') for y in range(22, 44)],
    *[(y, 15, 16, 'T') for y in range(23, 44)],
    (27, 15, 16, 'c'), (33, 15, 16, 'c'), (39, 15, 16, 'c'),
    # the ragged hem
    (44, 8, 9, 'M'), (44, 12, 13, 'M'), (44, 15, 16, 'T'), (44, 19, 20, 'M'), (44, 23, 24, 'D'),
    (45, 9, 9, 'D'), (45, 15, 16, 't'), (45, 22, 22, 'K'),
    # ---- the bodice and waist
    *[(y, 12, 19, 'M') for y in range(14, 21)],
    *[(y, 18, 19, 'D') for y in range(15, 21)],
    (14, 12, 13, 'L'), (15, 12, 12, 'L'),
    *[(y, 14, 17, 'T') for y in range(16, 20)],
    (17, 15, 16, 't'), (20, 13, 18, 'K'), (20, 15, 16, 'c'),          # belt and its gem
    (14, 14, 17, 's'), (15, 15, 16, 's'),                              # the neckline
    # ---- spiked pauldrons
    (12, 9, 12, 'M'), (13, 8, 12, 'M'), (14, 9, 11, 'D'), (11, 9, 9, 'L'), (10, 8, 8, 'L'), (12, 9, 9, 'L'),
    (12, 19, 22, 'M'), (13, 19, 23, 'D'), (14, 20, 22, 'D'), (11, 22, 22, 'L'), (10, 23, 23, 'M'),
    # ---- her raised arm (her right, our left): up from the shoulder to the orb
    (14, 7, 9, 'M'), (15, 6, 8, 'M'), (16, 5, 7, 'D'), (15, 5, 5, 'D'),
    (14, 5, 6, 'D'), (13, 5, 6, 'M'), (12, 5, 6, 'M'), (11, 5, 6, 's'), (10, 5, 6, 'S'),
    # the orb of sea above her hand, glowing
    (6, 5, 6, 'c'), (7, 4, 7, 'c'), (8, 4, 7, 'C'), (9, 5, 6, 'c'), (7, 5, 5, 'W'), (8, 5, 6, 'W'),
    (5, 3, 3, 'c'), (6, 8, 8, 'c'), (10, 3, 3, 'c'), (4, 7, 7, 'C'),
    # ---- the other arm, down to the trident
    (15, 21, 23, 'D'), (16, 22, 24, 'D'), (17, 23, 25, 'M'), (18, 24, 25, 'D'), (19, 24, 26, 's'), (20, 25, 26, 'S'),
    # ---- the trident: a dark shaft, glowing prongs
    *[(y, 26, 26, 'K') for y in range(4, 45)],
    *[(y, 27, 27, 'D') for y in range(5, 45)],
    (3, 24, 29, 'K'), (3, 25, 28, 'D'),
    (0, 24, 24, 'c'), (1, 24, 24, 'c'), (2, 24, 24, 'c'),
    (0, 26, 27, 'C'), (1, 26, 27, 'c'), (2, 26, 27, 'c'),
    (0, 29, 29, 'c'), (1, 29, 29, 'c'), (2, 29, 29, 'c'),
    (4, 26, 27, 'c'),
    # ---- head: hair falling to her shoulders, a pale face in shadow
    (5, 12, 19, 'D'), (6, 11, 20, 'D'), (7, 11, 20, 'D'), (8, 11, 20, 'D'), (9, 11, 20, 'D'), (10, 11, 20, 'D'),
    (11, 11, 12, 'D'), (11, 19, 20, 'D'), (12, 11, 12, 'K'), (12, 19, 20, 'K'), (13, 11, 11, 'K'), (13, 20, 20, 'K'),
    (7, 13, 18, 'S'), (8, 13, 18, 'S'), (9, 13, 18, 's'), (10, 14, 17, 's'), (11, 14, 17, 's'),
    (7, 13, 13, 'K'), (7, 18, 18, 'K'),                                # shadow at the edges of her crown
    (8, 14, 14, 'C'), (8, 17, 17, 'C'),                                # eyes, glowing like the sea
    (10, 15, 16, 'D'),                                                 # mouth
    # ---- the tall spiked crown
    (6, 12, 19, 'M'), (5, 12, 19, 'L'), (6, 15, 16, 'c'),
    (4, 12, 12, 'M'), (3, 12, 12, 'L'), (4, 14, 14, 'M'), (2, 14, 14, 'M'), (3, 14, 14, 'L'),
    (4, 15, 16, 'M'), (3, 15, 16, 'M'), (2, 15, 16, 'L'), (1, 15, 16, 'L'), (0, 15, 16, 'H'),
    (4, 17, 17, 'M'), (2, 17, 17, 'M'), (3, 17, 17, 'L'), (4, 19, 19, 'M'), (3, 19, 19, 'L'),
    (1, 15, 16, 'c'),
]


class _Pic:
    def __init__(self, rows):
        self._rows = rows

    def rows(self):
        return list(self._rows)


def design():
    g = [['.'] * W for _ in range(H)]
    for y, x0, x1, col in RUNS:
        for x in range(max(0, x0), min(W - 1, x1) + 1):
            if 0 <= y < H:
                g[y][x] = col
    return _Pic([''.join(r) for r in g])


if __name__ == '__main__':
    import sys
    from PIL import Image
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    px = im.load()
    for y, row in enumerate(design().rows()):
        for x, ch in enumerate(row):
            if ch != '.':
                v = PAL[ch]
                px[x, y] = ((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)
    im.save(sys.argv[1])
