"""
The raids' objectives: what stands between one boss and the next.
  blood_altar: the Crimson Conclave's blood rite (a black stone altar brimming
               with blood, candles and a skull, a red glow over it).
  storm_rod:   Heart of the Storm's lightning rods (an iron spire on a stone
               base, its coils crackling, a ball of lightning at its tip).
Two frames each (the glow or the arcs flicker).
"""
from canvas import Canvas


def blood_altar(t):
    c = Canvas(30, 30)
    # the stone block and its steps
    c.rect(4, 22, 25, 27, 'A')
    c.rect(7, 13, 22, 22, 'A')
    c.shade('A', 'a', 'd')
    c.line(7, 17, 22, 17, 'd')
    # blood brimming over the top and running down the sides
    c.ellipse(14.5, 13, 8, 2.6, 'R')
    c.ellipse(14.5, 13, 5, 1.4, 'r')
    for x, ln in ((9, 6), (13, 9), (18, 5), (21, 7)):
        c.line(x, 14, x, 14 + ln, 'R')
    # a skull set in the front
    c.ellipse(14.5, 19.5, 2.2, 1.8, 'B')
    c.put(13.5, 19.5, 'd'); c.put(15.5, 19.5, 'd')
    # candles, the flames flickering
    for x in (5, 24):
        c.rect(x, 17, x + 1, 22, 'B')
        c.put(x, 16 - t, 'F'); c.put(x + 1, 16 - t, 'F'); c.put(x, 15 - t, 'W')
    # the rite's glow over it
    for k, (x, y) in enumerate(((8, 6), (14, 3), (21, 6), (11, 9), (18, 9))):
        if (k + t) % 2 == 0:
            c.put(x, y, 'R')
    return c


ALTAR_PAL = {'A': 0x3a3038, 'a': 0x625460, 'd': 0x1a1418, 'R': 0xd8102a, 'r': 0xff5060, 'B': 0xe0d8c0,
             'F': 0xffa040, 'W': 0xfff0b0}


def storm_rod(t):
    c = Canvas(26, 36)
    # the stone base
    c.rect(5, 30, 20, 34, 'A')
    c.rect(8, 27, 17, 30, 'A')
    c.shade('A', 'a', 'd')
    # the iron spire, banded with copper coils
    c.poly([(11, 27), (14, 27), (13.5, 6), (11.5, 6)], 'I')
    c.shade('I', 'i', 'd')
    for y in range(9, 26, 4):
        c.line(10, y, 15, y + 1, 'G')
    # the ball of lightning at its tip
    c.ellipse(12.5, 4, 3.4, 3.4, 'C')
    c.ellipse(12.5, 4, 1.6, 1.6, 'W')
    # arcs crackling off it (they jump each frame)
    arcs = [((9, 3), (4, 7), (6, 11)), ((16, 3), (21, 6), (19, 10))] if t else [((9, 5), (3, 4), (5, 9)), ((16, 5), (22, 9), (20, 13))]
    for a, b, d in arcs:
        c.line(a[0], a[1], b[0], b[1], 'C')
        c.line(b[0], b[1], d[0], d[1], 'C')
    return c


ROD_PAL = {'A': 0x50566a, 'a': 0x8a90a8, 'd': 0x22242e, 'I': 0x4a5060, 'i': 0x8a92a8, 'G': 0xd08a40,
           'C': 0x80ffff, 'W': 0xffffff}


PROPS = [('blood_altar', blood_altar, ALTAR_PAL, 3), ('storm_rod', storm_rod, ROD_PAL, 3)]
