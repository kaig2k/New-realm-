"""
Nerezza, the Tide Empress, redrawn on the game's own grid (4 screen pixels a
cell, flat 3-tone materials, the outline added by the game) after the user's
art in ref/nerezza.jpg: the tall coral crown, the pale face framed in dark
hair, the spiked pauldrons and teal bodice, one hand raised with a swirling
orb of sea, the other on her curling trident-staff, the long gown and the
flowing cape of sea-glass blue. nerezza.py animates this picture.
"""
from canvas import Canvas

W, H = 46, 52
PAL = {
    # skin (cool, pale)
    'S': 0x9ea8d8, 's': 0xd2dcfa, 'q': 0x6a76b4,
    # hair and dark armour (navy)
    'N': 0x22307a, 'n': 0x3a52a8, 'm': 0x0e1440,
    # teal bodice and gown panels
    'T': 0x1f6e9e, 't': 0x46a8d8, 'u': 0x123f66,
    # ice: crown, staff, trims
    'I': 0x7cc8ff, 'i': 0xe0f6ff, 'j': 0x3a76d0,
    # the cape: sea-glass blue with violet in its folds
    'C': 0x4a6ed0, 'c': 0x8eb2ff, 'v': 0x5844b4,
    # the gown
    'G': 0x172a64, 'g': 0x2a4a96, 'h': 0x0b1236,
    # gems and highlights
    'W': 0xffffff,
}


class _Down(Canvas):
    """Draws everything 2 cells lower, so the crown can reach above y=0 of the drawing."""
    def put(self, x, y, c, only=None):
        Canvas.put(self, x, y + 2, c, only)

    def get(self, x, y):
        return Canvas.get(self, int(round(x)), int(round(y)) + 2)


def design():
    c = _Down(W, H)
    # ---- the cape: flowing out behind her, its hem rippling into wisps
    c.poly([(18, 15), (13, 20), (8, 27), (4, 34), (1, 41), (0, 46), (2, 47), (4, 45), (6, 47), (9, 45), (12, 47), (14, 42), (16, 33), (18, 24)], 'C')
    c.poly([(28, 15), (33, 20), (38, 27), (42, 34), (45, 41), (45, 46), (43, 47), (41, 45), (39, 47), (36, 45), (33, 47), (31, 42), (29, 33), (28, 24)], 'C')
    c.shade('C', 'c', 'v')
    # long folds sweeping down
    for a, b in (((13, 22), (8, 40)), ((16, 24), (12, 44)), ((33, 22), (38, 40)), ((30, 24), (34, 44))):
        c.line(a[0], a[1], b[0], b[1], 'v', only='Cc')
    for a, b in (((10, 26), (4, 40)), ((36, 26), (42, 40))):
        c.line(a[0], a[1], b[0], b[1], 'c', only='Cv')
    # sea droplets shed from its edge
    for x, y in ((0, 38), (2, 32), (45, 37), (44, 31)):
        c.put(x, y, 'c')
    # ---- the gown: a long bell from the waist
    c.poly([(19, 26), (27, 26), (31, 34), (34, 42), (36, 49), (10, 49), (12, 42), (15, 34)], 'G')
    c.shade('G', 'g', 'h')
    c.poly([(21, 27), (25, 27), (27, 38), (28, 49), (18, 49), (19, 38)], 'T')
    c.shade('T', 't', 'u')
    c.line(23, 28, 23, 48, 'I')
    for y in (32, 38, 44):
        c.put(23, y, 'i'); c.put(22, y + 1, 'j'); c.put(24, y + 1, 'j')
    for x in (13, 16, 30, 33):
        c.put(x, 46, 'j'); c.put(x, 47, 'j')
    # ---- the bodice, a gem at the waist
    c.poly([(19, 15), (27, 15), (28, 21), (26, 27), (20, 27), (18, 21)], 'T')
    c.shade('T', 't', 'u')
    c.rect(20, 24, 26, 25, 'N')
    c.put(23, 24, 'I'); c.put(23, 25, 'i')
    c.poly([(21, 15), (25, 15), (23, 18)], 'S')
    c.put(23, 20, 'I'); c.put(22, 21, 'j'); c.put(24, 21, 'j')
    # ---- spiked pauldrons
    c.poly([(15, 14), (20, 13), (20, 18), (16, 18)], 'N')
    c.poly([(26, 13), (31, 14), (30, 18), (26, 18)], 'N')
    c.shade('N', 'n', 'm')
    for x0, y0, x1, y1 in ((16, 14, 14, 11), (18, 13, 17, 10), (30, 14, 32, 11), (28, 13, 29, 10)):
        c.line(x0, y0, x1, y1, 'I')
        c.put(x1, y1, 'i')
    # ---- left arm raised: a dark sleeve, a pale hand, an orb of sea
    c.line(16, 17, 12, 21, 'N', w=2.2)
    c.line(12, 21, 10, 15, 'm', w=2.2)
    c.line(11, 20, 9, 15, 'N')
    c.rect(8, 13, 10, 14, 'S'); c.put(8, 13, 's')
    c.ellipse(9, 9, 2.4, 2.4, 'I')
    c.put(9, 8, 'i'); c.put(8, 9, 'W')
    c.ring(9, 9, 4, 4, 'c')
    for x, y in ((4, 6), (14, 6), (5, 12), (13, 12), (9, 3)):
        c.put(x, y, 'i')
    # ---- right arm down to the staff
    c.line(30, 17, 33, 22, 'N', w=2.2)
    c.line(33, 22, 34, 24, 'm', w=2)
    # ---- the trident-staff: a long shaft, an orb, curling prongs, water winding round it
    c.line(38, 10, 34, 47, 'j')
    c.line(39, 10, 35, 47, 'I')
    c.ellipse(39, 9, 2, 2, 'I'); c.put(39, 8, 'i'); c.put(38, 9, 'W')
    c.line(39, 7, 39, -1, 'I'); c.put(39, -1, 'i')
    c.line(37, 8, 35, 4, 'I'); c.line(35, 4, 36, 0, 'I'); c.put(36, 0, 'i')
    c.line(41, 8, 43, 4, 'I'); c.line(43, 4, 42, 0, 'I'); c.put(42, 0, 'i')
    c.line(36, 13, 41, 16, 'c'); c.line(41, 16, 37, 20, 'c'); c.line(37, 20, 40, 24, 'c')
    c.rect(34, 24, 36, 26, 'S'); c.put(34, 24, 's')
    # ---- head: dark hair falling past her shoulders, a pale face
    c.ellipse(23, 9, 5.2, 5.6, 'N')
    c.poly([(18, 8), (16, 17), (19, 17), (20, 11)], 'N')
    c.poly([(28, 8), (30, 17), (27, 17), (26, 11)], 'N')
    c.shade('N', 'n', 'm')
    c.ellipse(23, 10, 3.0, 3.6, 'S')
    # lit from above, glowing eyes, a little shadow under the chin
    c.rect(21, 8, 25, 8, 's', only='S')
    c.put(22, 10, 'I'); c.put(24, 10, 'I')   # eyes that glow like the sea
    c.put(22, 9, 'q'); c.put(24, 9, 'q')
    c.put(23, 13, 'q', only='S')
    c.rect(20, 7, 26, 7, 'N')               # her fringe
    c.put(20, 8, 'N'); c.put(26, 8, 'N')
    # ---- the tall coral crown: five spikes, a gem at its heart
    c.poly([(18, 6), (28, 6), (28, 3), (27, 4), (26, 0), (25, 3), (23, -2), (21, 3), (20, 0), (19, 4), (18, 3)], 'I')
    c.shade('I', 'i', 'j')
    c.put(23, 3, 'W'); c.put(23, 4, 'j'); c.put(22, 4, 'j'); c.put(24, 4, 'j')
    c.put(17, 4, 'I'); c.put(16, 2, 'i'); c.put(29, 4, 'I'); c.put(30, 2, 'i')
    return c


if __name__ == '__main__':
    import sys
    from PIL import Image
    c = design()
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0)); px = im.load()
    for y, row in enumerate(c.rows()):
        for x, ch in enumerate(row):
            if ch != '.':
                v = PAL[ch]; px[x, y] = ((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)
    im.save(sys.argv[1])
