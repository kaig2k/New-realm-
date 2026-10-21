"""
Sylith the Frost Wyrm in Eldmere's boss style (ref/style/: small, dark, a few
tones, one glowing accent), after the user's art and sheet (ref/sylith.webp,
ref/sylith_sheet.webp). A classic dragon in profile, facing right: a horned head
with an open jaw full of frost, an S-curved neck, a great bat wing raised over
her back (finger bones fanning out, the membrane scalloped between them), four
clawed legs and a long tail ending in a spade. Icy cyan light only in her eye,
her jaws, the tips of her horns and spines, and her claws. sylith.py animates it.
"""
import math
from canvas import Canvas

W, H = 46, 36
PAL = {
    # scales: deepest, dark, mid, lit edge, rare highlight
    'K': 0x080c16, 'D': 0x141e36, 'M': 0x24365e, 'L': 0x3a5890, 'H': 0x6a8cc8,
    # wing membrane (dark, lit near the arm)
    'w': 0x111a30, 'v': 0x1e2c4e,
    # belly plates (base, lit)
    'p': 0x3a4a6e, 'P': 0x5a6e98,
    # horns and claws (bone-ice)
    'h': 0x8ea4c8,
    # the ice glow: deep, bright, white-hot
    'c': 0x2aa8e0, 'C': 0x9ceeff, 'W': 0xffffff,
}


def tri(c, a, b, tip, col):
    c.poly([a, b, tip], col)


def design():
    c = Canvas(W, H)
    # ---- the far wing: just its top edge showing behind her back
    c.poly([(24, 15), (28, 9), (31, 8), (29, 13), (27, 16)], 'w')
    c.line(24, 15, 30, 8, 'D')
    # ---- the near wing, raised high: the arm (shoulder -> elbow -> wrist), then fingers fanning down-left
    shoulder, elbow, wrist = (22, 16), (20, 9), (15, 2)
    tips = [(1, 5), (2, 12), (5, 17), (11, 19)]
    # membrane: between the arm and each finger, with scalloped (concave) edges between the tips
    c.poly([shoulder, elbow, wrist, tips[0], (5, 8), tips[1], (6, 14), tips[2], (10, 17), tips[3], (16, 18)], 'w')
    c.poly([shoulder, elbow, wrist, (9, 6), (12, 12), (16, 16)], 'v')
    # the bones
    c.line(shoulder[0], shoulder[1], elbow[0], elbow[1], 'M', w=2)
    c.line(elbow[0], elbow[1], wrist[0], wrist[1], 'M', w=2)
    for tp in tips:
        c.line(wrist[0], wrist[1], tp[0], tp[1], 'L')
    c.put(wrist[0], wrist[1] - 1, 'h'); c.put(wrist[0] - 1, wrist[1] - 1, 'C')     # the wrist claw
    # ---- the tail: from her rump, sweeping back and down, then curling up into a spade
    c.line(15, 23, 9, 27, 'D', w=4)
    c.line(9, 27, 4, 27, 'D', w=3)
    c.line(4, 27, 2, 23, 'D', w=2)
    tri(c, (0, 23), (5, 22), (2, 18), 'M')                                     # the spade
    c.put(2, 19, 'C')
    c.line(13, 23, 8, 26, 'M')                                                 # its lit top
    # ---- the body: a deep chest and a long belly
    c.ellipse(22, 22, 9, 5.5, 'K')
    c.ellipse(22, 21.5, 8.2, 4.8, 'M')
    c.ellipse(22, 24, 7, 2.5, 'D', only='M')                                   # the underside in shadow
    # ---- legs: the far pair darker, the near pair in front
    c.poly([(16, 24), (19, 24), (19, 31), (17, 32), (15, 31)], 'D')            # far hind leg
    c.poly([(26, 24), (28, 24), (29, 31), (26, 32)], 'D')                      # far foreleg
    c.poly([(13, 21), (19, 22), (20, 27), (18, 30), (20, 33), (15, 33), (15, 29), (12, 25)], 'M')   # near hind leg
    c.line(14, 23, 17, 23, 'L')
    c.poly([(28, 22), (31, 22), (32, 27), (31, 31), (33, 33), (28, 33), (28, 29)], 'M')             # near foreleg
    c.line(29, 23, 31, 23, 'L')
    # ---- the neck: an S-curve up from her chest to the head
    for i in range(9):
        t = i / 8
        x = 28 + t * 7 + math.sin(t * math.pi) * 2
        y = 19 - t * 11
        c.ellipse(x, y, 2.6, 2.4, 'M')
    for i in range(7):                                                          # belly plates down her throat
        t = i / 6
        x = 29.5 + t * 6 + math.sin(t * math.pi) * 2
        y = 20 - t * 10
        c.put(int(x) + 2, int(y), 'P' if i % 2 else 'p')
    # ---- the head: a long wedge of a snout, the jaw open
    c.poly([(33, 5), (37, 3), (41, 4), (45, 7), (44, 9), (39, 9), (35, 11), (32, 9)], 'M')        # skull and upper jaw
    c.poly([(35, 11), (39, 10), (44, 11), (42, 13), (37, 13)], 'D')                                # lower jaw, hanging open
    c.line(39, 10, 44, 10, 'c')                                                                    # frost in her jaws
    c.put(42, 10, 'C')
    c.put(41, 9, 'W'); c.put(43, 9, 'W'); c.put(40, 11, 'h'); c.put(42, 12, 'h')                   # fangs
    c.line(34, 5, 41, 4, 'L')                                                                      # light along the top of her head
    c.put(39, 6, 'C'); c.put(40, 6, 'W'); c.put(38, 6, 'c')                                        # her eye
    c.line(37, 5, 41, 5, 'K')                                                                      # the brow over it
    c.put(44, 7, 'K')                                                                              # nostril
    # horns sweeping back from her head
    c.line(35, 4, 31, 0, 'h'); c.put(31, 0, 'C')
    c.line(34, 6, 29, 3, 'h'); c.put(29, 3, 'C')
    # ---- spines down her neck and back
    for x, y in ((33, 10), (31, 13), (30, 16), (26, 16), (22, 16), (18, 17), (14, 19)):
        tri(c, (x - 1, y + 1), (x + 1, y + 1), (x - 1, y - 2), 'D')
        c.put(x - 1, y - 2, 'c')
    # ---- light along her back, a little
    for x, y in ((17, 18), (18, 17), (20, 17), (23, 17), (25, 17), (27, 17)):
        c.put(x, y, 'L')
    c.put(21, 17, 'H')
    # ---- claws of ice
    for x in (15, 17, 19, 28, 30, 32):
        c.put(x, 34, 'C')
    for x in (16, 18, 29, 31):
        c.put(x, 34, 'h')
    return c


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
