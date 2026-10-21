"""
Gorehorn redrawn on the game's own grid (4 screen pixels a cell, flat 3-tone
materials, the outline added by the game), after the user's art in
ref/gorehorn.png: the hunched charcoal bull, the great bone crescent of a horn,
the spikes along his back, the bone claws and the red cracks that glow through
his hide. gorehorn.py animates this picture.
"""
from canvas import Canvas

W, H = 34, 34
PAL = {
    # hide (base, light, dark, deepest)
    'B': 0x3a2832, 'b': 0x5c4552, 'k': 0x22161e, 'K': 0x140c12,
    # bone (base, light, dark)
    'H': 0xdcc39a, 'h': 0xfaecc8, 'o': 0x9c7c5a,
    # the red cracks (base, bright, dark) and his eyes
    'R': 0xd01c24, 'r': 0xff5a3a, 'd': 0x6e0c14, 'E': 0xffd860,
}


def design():
    c = Canvas(W, H)
    # ---- the hulking body: a high hump falling to broad shoulders, haunches behind
    c.poly([(2, 20), (3, 14), (6, 9), (11, 5), (17, 3), (23, 4), (28, 7), (32, 12), (33, 18), (32, 23), (24, 24), (10, 24), (2, 24)], 'B')
    # back legs, half hidden behind the front ones (darker: further away)
    c.rect(12, 22, 15, 29, 'k')
    c.rect(19, 22, 22, 29, 'k')
    # front legs: thick, splayed
    c.poly([(2, 19), (10, 19), (11, 25), (10, 31), (2, 31), (1, 25)], 'B')
    c.poly([(23, 19), (32, 18), (33, 25), (32, 31), (24, 31), (23, 25)], 'B')
    c.shade('B', 'b', 'k', 'K')
    # fur clumps catching the light along the hump
    for x, y in ((9, 8), (13, 6), (20, 5), (26, 8), (30, 12)):
        c.put(x, y, 'b'); c.put(x + 1, y, 'b')
    # where the front legs meet the chest
    c.line(10, 21, 11, 30, 'K'); c.line(23, 21, 23, 30, 'K')
    # ---- the head: low and forward, out between his front legs
    head = [(7, 13), (12, 11), (17, 12), (19, 16), (18, 22), (16, 26), (10, 26), (8, 22), (6, 17)]
    # a dark rim first, so the head stands off his chest
    c.poly([(x + (x - 12.5) * 0.14, y + (y - 18) * 0.12) for x, y in head], 'K')
    c.poly(head, 'B')
    c.shade('B', 'b', 'k')
    # the face plane catches the light
    c.rect(11, 18, 14, 20, 'b', only='Bk')
    # brow ridge over deep eye sockets
    c.line(7, 15, 18, 15, 'b')
    c.rect(8, 16, 10, 17, 'K'); c.rect(15, 16, 17, 17, 'K')
    c.put(9, 17, 'E'); c.put(16, 17, 'E'); c.put(9, 16, 'r'); c.put(16, 16, 'r')
    # the maw: red inside, bone tusks curling up from the jaw
    c.rect(10, 22, 15, 24, 'd'); c.rect(11, 23, 14, 23, 'R')
    c.line(9, 24, 8, 21, 'H'); c.put(8, 20, 'h')
    c.line(16, 24, 17, 21, 'H'); c.put(17, 20, 'h')
    for x in (11, 13): c.put(x, 22, 'h')
    # ---- the great horn: thick at his brow, a bone crescent round his right side, tip curling in
    c.poly([(14, 12), (16, 8), (19, 5), (23, 5), (26, 7), (28, 11), (28, 16), (26, 20), (23, 22), (20, 22), (22, 19), (24, 16), (24, 12), (22, 9), (19, 9), (17, 12)], 'H')
    c.shade('H', 'h', 'o')
    c.line(17, 11, 20, 8, 'o')          # ridges on the horn
    c.line(25, 12, 25, 15, 'h')
    # the small left horn by his shoulder
    c.poly([(0, 12), (4, 12), (6, 15), (3, 16)], 'H')
    c.put(0, 12, 'h'); c.put(1, 12, 'h'); c.put(5, 15, 'o')
    # ---- spikes along his back
    for (x, y, h) in ((5, 10, 3), (9, 6, 4), (13, 4, 4), (29, 8, 4), (32, 13, 3)):
        c.poly([(x - 1.2, y + 1), (x + 1.2, y + 1), (x, y - h + 1)], 'H')
        c.put(x, y - h + 1, 'h')
        c.put(x + 1, y + 1, 'o')
    # ---- bone claws
    for x in (2, 4, 6, 8, 25, 27, 29, 31):
        c.put(x, 32, 'H'); c.put(x, 31, 'o')
    for x in (13, 20):
        c.put(x, 30, 'o')
    # ---- red cracks glowing through the hide
    cracks = [((4, 11), (6, 14), (5, 18)), ((29, 14), (31, 17), (30, 21)), ((3, 22), (5, 26), (4, 29)),
              ((27, 22), (29, 25), (28, 29)), ((7, 8), (9, 10)), ((30, 9), (31, 11))]
    for cr in cracks:
        for a, b in zip(cr, cr[1:]):
            c.line(a[0], a[1], b[0], b[1], 'R', only='Bbk')
    for x, y in ((6, 14), (31, 17), (5, 26), (29, 25)):
        c.put(x, y, 'r', only='R')
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
