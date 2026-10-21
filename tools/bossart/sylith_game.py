"""
Sylith the Frost Wyrm, drawn on the game's own grid (4 screen pixels a cell,
flat 3-tone materials, the outline added by the game) after the user's art in
ref/sylith.webp (their sheet: ref/sylith_sheet.webp): a crystal dragon facing
right, one great wing raised behind her, the other hanging at her side, a crest
of ice spikes down her neck, pale belly plates, a coiled spiked tail and claws
of white ice. sylith.py animates this picture.
"""
from canvas import Canvas

W, H = 44, 40
PAL = {
    # scales (base, light, dark)
    'B': 0x2446b0, 'b': 0x4880e4, 'N': 0x0b1140,
    # wing membrane (base, light, dark)
    'S': 0x6cb8ff, 's': 0xb0deff, 'm': 0x3a7ce0,
    # ice: crest, spikes, claws (base, tip)
    'I': 0xb8e0ff, 'W': 0xf2faff,
    # belly plates (base, shade)
    'P': 0xc8d6f4, 'p': 0x8696cc,
    # her eye
    'E': 0x9ff4ff,
}


def shard(c, x, y, dx, dy, w=1.2, col='I', tip='W'):
    """An ice spike from (x, y) pointing along (dx, dy), w cells wide at its base."""
    import math
    ln = math.hypot(dx, dy) or 1
    nx, ny = -dy / ln * w, dx / ln * w
    c.poly([(x + nx, y + ny), (x - nx, y - ny), (x + dx, y + dy)], col)
    c.put(x + dx, y + dy, tip)


def design():
    c = Canvas(W, H)
    # ---- the far wing, hanging down her right side: dark membrane, jagged hem
    c.poly([(31, 14), (38, 9), (42, 13), (44, 21), (43, 30), (41, 25), (40, 32), (38, 26), (36, 30), (34, 22)], 'm')
    # ---- the near wing, raised high behind her
    c.poly([(19, 18), (12, 4), (15, 0), (18, 5), (21, 0), (24, 11), (22, 17), (17, 25), (15, 20), (12, 27), (10, 21),
            (6, 26), (6, 19), (1, 21), (4, 13), (8, 7)], 'm')
    # pale crystal panels between the fingers, catching the light
    for pts in ([(18, 16), (13, 5), (15, 2), (18, 8)], [(19, 15), (20, 3), (23, 11), (21, 16)],
                [(17, 17), (9, 9), (6, 15), (14, 19)], [(15, 19), (5, 16), (4, 20), (11, 22)],
                [(32, 15), (39, 12), (42, 18), (36, 20)], [(34, 20), (42, 20), (42, 27), (38, 23)]):
        c.poly(pts, 'S')
    c.shade('S', 's', 'S')
    # bone struts out to each tip
    for a, b in (((19, 17), (12, 4)), ((19, 17), (15, 0)), ((20, 16), (21, 0)), ((19, 17), (4, 13)), ((19, 17), (8, 7)),
                 ((19, 18), (1, 21)), ((31, 15), (38, 9)), ((31, 15), (44, 21)), ((31, 16), (43, 30))):
        c.line(a[0], a[1], b[0], b[1], 'I')
    for x, y in ((12, 4), (15, 0), (21, 0), (4, 13), (1, 21), (38, 9), (44, 21)):
        c.put(x, y, 'W')
    # ---- the coiled tail, behind her legs
    c.ring(9, 32, 6, 4.5, 'B', width=3)
    c.line(14, 30, 19, 28, 'B', w=3)
    c.rect(3, 34, 9, 37, '.', only='B')     # the coil opens at the bottom-left
    c.line(4, 33, 1, 37, 'B', w=2)
    # ---- body, neck and a long angular head facing right (a dark rim first, so she stands off her wings)
    c.ellipse(24, 26, 10.5, 8, 'N')
    c.poly([(24, 22), (27, 12), (32, 7), (37, 9), (35, 17), (32, 24)], 'N')
    c.ellipse(24, 26, 9.5, 7, 'B')
    c.poly([(25, 22), (28, 13), (32, 8), (36, 10), (34, 16), (31, 23)], 'B')
    c.poly([(30, 9), (35, 5), (40, 6), (43, 9), (44, 12), (40, 13), (36, 16), (31, 14)], 'B')
    c.poly([(17, 28), (23, 28), (23, 35), (20, 37), (16, 36)], 'B')     # hind leg
    c.poly([(29, 27), (35, 27), (36, 35), (33, 37), (29, 35)], 'B')     # foreleg
    c.shade('B', 'b', 'N')
    # scales glinting on her flank
    for x, y in ((18, 24), (22, 22), (20, 28), (25, 27), (16, 30), (27, 31)):
        c.put(x, y, 'b'); c.put(x + 1, y, 'b')
    # ---- pale belly plates down her throat and chest
    for i, y in enumerate(range(15, 32, 2)):
        x = int(33 - i * 0.6)
        c.rect(x - 1, y, x + 1, y, 'P')
        c.rect(x - 1, y + 1, x + 1, y + 1, 'p')
    # ---- head details: a heavy brow over a glowing eye, the jaw, fangs
    c.line(34, 7, 40, 7, 'b')
    c.rect(37, 8, 38, 9, 'N'); c.put(37, 9, 'E'); c.put(38, 9, 'W')
    c.line(36, 12, 44, 11, 'N')
    for x in (38, 40, 42):
        c.put(x, 12, 'W')
    c.put(44, 9, 'b')
    # ---- the crest: ice shards swept back from her head and down her spine
    for (x, y, dx, dy, w) in ((36, 6, -1, -7, 1.8), (33, 7, -4, -7, 1.8), (30, 11, -6, -5, 1.7), (28, 16, -6, -3, 1.5),
                              (40, 6, 2, -5, 1.4), (22, 20, -3, -5, 1.4), (17, 21, -4, -3, 1.2)):
        shard(c, x, y, dx, dy, w)
        shard(c, x, y, dx * 0.6, dy * 0.6, w * 0.45, col='W', tip='W')   # a bright core down each shard
    # spikes along the tail
    for (x, y, dx, dy) in ((6, 28, -1, -3), (11, 28, 1, -3), (3, 31, -3, -1), (15, 33, 2, 2)):
        shard(c, x, y, dx, dy, 0.8)
    # ---- claws of white ice
    for x in (16, 18, 20, 30, 32, 34):
        c.put(x, 38, 'W'); c.put(x, 37, 'I')
    return c


if __name__ == '__main__':
    import sys
    from PIL import Image
    c = design()
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    px = im.load()
    for y, row in enumerate(c.rows()):
        for x, ch in enumerate(row):
            if ch != '.':
                v = PAL[ch]
                px[x, y] = ((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)
    im.save(sys.argv[1])
