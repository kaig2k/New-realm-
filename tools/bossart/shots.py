"""
The weapons' shots: a projectile of its own for every tier of every weapon (Data.SIGS),
16x16, pointing right (the game turns it to the way it flies). Drawn in colour slots so a
weapon's own colour fills them: C its colour, a darker, W lighter; H white, K the void's
black, G gold, I steel, i bright steel, S wood. Rarity weapons fire their type's tier-7
shot in their rarity's colour.

    python3 tools/bossart/shots.py            writes src/realm/WeaponShots.as
    python3 tools/bossart/shots.py out.png    and a contact sheet
"""
import math
import os
import sys
from canvas import Canvas

N = 16
M = 7.5   # the middle


def cv():
    return Canvas(N, N)


def tail(c, x0, x1, y, w0, w1, ch='a'):
    """A tapering streak from x0 (thin) to x1 (wide)."""
    for x in range(int(x0), int(x1) + 1):
        f = (x - x0) / max(1, x1 - x0)
        w = w0 + (w1 - w0) * f
        c.line(x, y - w / 2, x, y + w / 2, ch)


def orb(c, x, y, r, core='W', ring='C', dark='a'):
    c.ellipse(x, y, r + 1, r + 1, dark)
    c.ellipse(x, y, r, r, ring)
    c.ellipse(x - 0.5, y - 0.5, r * 0.55, r * 0.55, core)


def star(c, x, y, r, ch='C', core='H'):
    for k in range(5):
        a = -math.pi / 2 + k * 2 * math.pi / 5
        c.line(x, y, x + math.cos(a) * r, y + math.sin(a) * r, ch, 2)
    c.ellipse(x, y, 1.6, 1.6, core)


def crescent(c, x, y, r, w, ch='C', edge='W', inner='a'):
    for i in range(60):
        f = i / 59
        th = (f - 0.5) * 2.4
        wd = w * math.sin(f * math.pi)
        for k in range(int(wd * 2) + 1):
            rr = r - k * 0.5
            c.put(x + math.cos(th) * rr, y + math.sin(th) * rr, edge if k == 0 else (inner if k > wd * 1.6 else ch))


def arrow(c, shaft='S', head='I', fletch='C', y=M, x0=1, x1=12, barb=False):
    c.line(x0, y, x1, y, shaft)
    c.poly([(x1, y - 2.5), (x1 + 3.5, y), (x1, y + 2.5)], head)
    c.line(x1 - 1, y - 2.5, x1 - 1, y + 2.5, 'a') if barb else None
    c.line(x0, y - 2, x0 + 3, y, fletch)
    c.line(x0, y + 2, x0 + 3, y, fletch)
    c.line(x0 + 1, y - 2, x0 + 4, y, fletch)
    c.line(x0 + 1, y + 2, x0 + 4, y, fletch)


def blade(c, x0, x1, y, w, ch='I', edge='i', grip=True):
    c.poly([(x0, y - w), (x1 - 2, y - w), (x1 + 1, y), (x1 - 2, y + w), (x0, y + w)], ch)
    c.line(x0, y - w, x1 - 2, y - w, edge)
    if grip:
        c.line(x0 - 1, y - w - 1.5, x0 - 1, y + w + 1.5, 'G')
        c.line(x0 - 4, y, x0 - 1, y, 'S')


# ------------------------------------------------------------------ staff
def staff(t):
    c = cv()
    if t == 0:        # twin arcane bolt: a diamond with a short tail
        tail(c, 1, 8, M, 0.5, 3, 'a')
        c.poly([(7, M), (11, M - 3), (15, M), (11, M + 3)], 'C')
        c.poly([(9, M), (11, M - 1.5), (13, M), (11, M + 1.5)], 'W')
    elif t == 1:      # ember: a fireball, flames licking back
        for k, (dy, ln) in enumerate(((-2.5, 7), (0, 9), (2.5, 6))):
            tail(c, 1 + (9 - ln), 10, M + dy, 0.3, 2.2, 'a' if k != 1 else 'C')
        orb(c, 10.5, M, 3.3, core='H', ring='W', dark='C')
    elif t == 2:      # comet: a bright head and a long tail
        tail(c, 0, 10, M, 0.3, 4.5, 'a')
        tail(c, 4, 11, M, 0.3, 2.5, 'C')
        orb(c, 11.5, M, 2.6, core='H', ring='W', dark='C')
    elif t == 3:      # serpent: a weaving body with a head and fangs
        for x in range(1, 12):
            y = M + math.sin(x * 0.75) * 2.5
            c.ellipse(x, y, 1.3, 1.3, 'C' if x % 3 else 'a')
        c.ellipse(12.5, M + math.sin(12 * 0.75) * 2.5, 2.4, 2, 'C')
        c.put(13.5, M + math.sin(12 * 0.75) * 2.5 - 1, 'H')
        c.put(15, M + math.sin(12 * 0.75) * 2.5 + 1, 'W')
    elif t == 4:      # falling star: a five-point star trailing sparkles
        for k, x in enumerate((1, 4, 7)):
            c.put(x, M + (1 if k % 2 else -1), 'W')
        tail(c, 2, 9, M, 0.3, 2, 'a')
        star(c, 11, M, 4.4, 'C', 'H')
    elif t == 5:      # ruin orb: a black core in a cracked ring of power
        tail(c, 0, 6, M, 0.3, 3, 'a')
        orb(c, 10, M, 4, core='K', ring='C', dark='a')
        c.ellipse(10, M, 2.6, 2.6, 'K')
        for a in (0.4, 2.2, 4.0):
            c.line(10, M, 10 + math.cos(a) * 4.8, M + math.sin(a) * 4.8, 'W')
        c.put(9, M - 1, 'C')
    elif t == 6:      # nebula: a swirl of colour with a bright eye
        for i in range(40):
            f = i / 39
            a = f * 4 * math.pi
            r = 1 + f * 4.5
            c.put(10 + math.cos(a) * r, M + math.sin(a) * r * 0.8, 'C' if i % 3 else 'W')
        tail(c, 0, 5, M, 0.3, 3, 'a')
        c.ellipse(10, M, 1.5, 1.5, 'H')
    else:             # void rift: an upright tear blazing at its edges
        tail(c, 0, 6, M, 0.3, 4, 'a')
        c.poly([(11, 0.5), (14.5, M), (11, 15), (7.5, M)], 'C')
        c.poly([(11, 2.5), (13.2, M), (11, 13), (8.8, M)], 'K')
        c.line(11, 3.5, 11, 12, 'W')
        c.put(11, M, 'H')
    return c


# ------------------------------------------------------------------ bow
def bow(t):
    c = cv()
    if t == 0:
        arrow(c, fletch='a')
    elif t == 1:
        arrow(c, fletch='C')
        c.put(6, M - 1, 'W')
    elif t == 2:      # heavy hunting arrow: a broad head
        c.line(0, M, 11, M, 'S', 2)
        c.poly([(10, M - 4), (15.5, M), (10, M + 4), (11.5, M)], 'I')
        c.line(11, M - 3, 14.5, M, 'i')
        c.line(0, M - 3, 3, M, 'C', 1)
        c.line(0, M + 3, 3, M, 'C', 1)
    elif t == 3:      # gilded arrow: gold head and fletching
        arrow(c, shaft='S', head='G', fletch='G')
        c.put(13, M - 1, 'H')
    elif t == 4:      # thorn arrow: a green shaft bristling with thorns
        c.line(0, M, 12, M, 'C', 1.5)
        for x in range(2, 12, 3):
            c.line(x, M, x - 1.5, M - 2.5, 'a')
            c.line(x + 1, M, x - 0.5, M + 2.5, 'a')
        c.poly([(11, M - 3), (15.5, M), (11, M + 3)], 'W')
    elif t == 5:      # fey arrow: a glowing leaf and a trail of light
        tail(c, 0, 7, M, 0.3, 2, 'a')
        c.poly([(6, M), (10, M - 3.5), (15, M), (10, M + 3.5)], 'C')
        c.line(6, M, 15, M, 'W')
        c.put(11, M - 1, 'H')
    elif t == 6:      # blood arrow: a barbed red streak
        tail(c, 0, 9, M, 0.3, 2.5, 'a')
        c.line(3, M, 12, M, 'C', 1.5)
        c.poly([(11, M - 3.5), (15.5, M), (11, M + 3.5), (12.5, M)], 'C')
        c.line(12.5, M - 2, 15, M, 'W')
        c.put(5, M + 2, 'C')
        c.put(8, M - 2, 'C')
    else:             # star arrow: a comet of starlight
        tail(c, 0, 10, M, 0.3, 3.5, 'a')
        tail(c, 4, 11, M, 0.3, 1.5, 'W')
        star(c, 12, M, 3.6, 'C', 'H')
    return c


# ------------------------------------------------------------------ sword
def sword(t):
    c = cv()
    if t == 0:        # a short slash
        crescent(c, 3, M, 9, 2.0, 'C', 'W', 'a')
    elif t == 1:      # a broad slash
        crescent(c, 2, M, 10.5, 3.2, 'C', 'W', 'a')
    elif t == 2:      # a thin, quick slash
        crescent(c, 4, M, 9.5, 1.5, 'C', 'H', 'a')
        c.put(6, M, 'W')
    elif t == 3:      # a thrust of light along a blade
        tail(c, 0, 8, M, 0.3, 2, 'a')
        blade(c, 5, 14, M, 1.6, 'C', 'H', grip=False)
    elif t == 4:      # a full crescent
        crescent(c, 1, M, 12, 3.6, 'C', 'H', 'a')
    elif t == 5:      # a flaming crescent, embers off its back
        crescent(c, 1, M, 12, 3.8, 'C', 'H', 'a')
        for (x, y) in ((4, 2), (3, 13), (6, 4), (6, 11), (2, M)):
            c.put(x, y, 'W')
    elif t == 6:      # a crystal cut: faceted shards in an arc
        for k in range(5):
            a = (k - 2) * 0.45
            x, y = 6 + math.cos(a) * 6, M + math.sin(a) * 6.5
            c.poly([(x - 1.5, y), (x, y - 2.2), (x + 2.6, y), (x, y + 2.2)], 'C')
            c.put(x + 0.5, y - 0.5, 'H')
        c.line(3, M, 6, M, 'a')
    else:             # sunforged: a golden crescent throwing rays
        crescent(c, 1, M, 12, 3.6, 'C', 'H', 'a')
        for k in range(5):
            a = (k - 2) * 0.5
            c.line(10 + math.cos(a) * 3, M + math.sin(a) * 4, 10 + math.cos(a) * 6, M + math.sin(a) * 7, 'G')
    return c


# ------------------------------------------------------------------ wand
def wand(t):
    c = cv()
    if t == 0:
        tail(c, 2, 8, M, 0.3, 2, 'a')
        orb(c, 11, M, 2.8)
    elif t == 1:      # ember
        for dy, ln in ((-2, 6), (0, 8), (2, 5)):
            tail(c, 10 - ln, 10, M + dy, 0.3, 2, 'a')
        orb(c, 11, M, 3, core='H', ring='W', dark='C')
    elif t == 2:      # grave-light: a little skull-shaped wisp
        tail(c, 0, 8, M, 0.3, 3, 'a')
        c.ellipse(11, M - 0.5, 3.5, 3.2, 'C')
        c.put(10, M - 1, 'K')
        c.put(12, M - 1, 'K')
        c.line(10, M + 2, 12, M + 2, 'a')
    elif t == 3:      # tide orb: rings of ripples round it
        orb(c, 10, M, 3)
        c.ring(10, M, 5.5, 5.5, 'C', 1)
        c.ring(10, M, 7, 7, 'a', 1)
    elif t == 4:      # shadow: a dark orb with tendrils
        for k in range(5):
            a = math.pi + (k - 2) * 0.4
            c.line(10, M, 10 + math.cos(a) * 9, M + math.sin(a) * 5, 'a')
        orb(c, 10, M, 3.3, core='C', ring='K', dark='a')
        c.put(11, M - 1, 'W')
    elif t == 5:      # ward star: a four-point star
        tail(c, 0, 6, M, 0.3, 2, 'a')
        for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            c.poly([(10.5, M), (10.5 + dx * 5 + dy * 1.5, M + dy * 5 + dx * 1.5), (10.5 + dx * 5 - dy * 1.5, M + dy * 5 - dx * 1.5)], 'C')
        c.ellipse(10.5, M, 1.5, 1.5, 'H')
    elif t == 6:      # holy orb under a halo
        tail(c, 0, 7, M, 0.3, 2.5, 'a')
        orb(c, 10.5, M + 1, 3.2, core='H', ring='W', dark='C')
        c.ring(10.5, M - 3.5, 3.2, 1.2, 'G', 1)
    else:             # radiance: a big eight-point star blazing
        for k in range(8):
            a = k * math.pi / 4
            r = 7 if k % 2 == 0 else 4
            c.line(9, M, 9 + math.cos(a) * r, M + math.sin(a) * r, 'C' if k % 2 else 'W', 2 if k % 2 == 0 else 1)
        c.ellipse(9, M, 2.4, 2.4, 'H')
    return c


# ------------------------------------------------------------------ dagger
def dagger(t):
    c = cv()
    if t == 0:
        blade(c, 6, 13, M, 1.2, 'I', 'i')
    elif t == 1:
        blade(c, 5, 14, M, 1.4, 'I', 'i')
        c.put(8, M, 'C')
    elif t == 2:
        blade(c, 5, 14, M, 1.6, 'i', 'H')
        c.line(5, M, 13, M, 'I')
    elif t == 3:      # a silver dirk spinning: a four-bladed star of steel
        for k in range(4):
            a = k * math.pi / 2 + 0.3
            # a curved blade: thick at the hub, swept to a point
            for j in range(8):
                f = j / 7
                r = 1.5 + f * 5.5
                b = a + f * 0.6
                c.ellipse(M + 0.5 + math.cos(b) * r, M + math.sin(b) * r, 1.4 * (1 - f) + 0.5, 1.4 * (1 - f) + 0.5, 'i' if j < 6 else 'H')
        c.ellipse(M + 0.5, M, 2, 2, 'I')
        c.ellipse(M + 0.5, M, 1, 1, 'C')
    elif t == 4:      # viper fang: a curved green fang dripping venom
        c.poly([(3, M - 3), (14, M - 0.5), (3, M + 2)], 'C')
        c.line(3, M - 3, 14, M - 0.5, 'W')
        c.put(9, M + 2, 'a')
        c.put(7, M + 3, 'a')
        c.line(1, M - 2, 3, M - 2, 'S')
    elif t == 5:      # agate kunai: a ringed handle and a leaf blade
        c.ring(2.5, M, 1.8, 1.8, 'G', 1)
        c.line(4, M, 7, M, 'S', 1.5)
        c.poly([(7, M), (10, M - 3), (15, M), (10, M + 3)], 'C')
        c.line(8, M, 14, M, 'W')
    elif t == 6:      # ghost knife: a pale blade fading into wisps
        tail(c, 0, 7, M, 0.3, 3, 'a')
        blade(c, 6, 14, M, 1.6, 'C', 'H', grip=False)
        c.put(4, M - 2, 'W')
        c.put(3, M + 2, 'W')
    else:             # dusk blade: a dark crescent knife with a violet edge
        tail(c, 0, 6, M, 0.3, 3, 'a')
        crescent(c, 4, M, 9, 2.6, 'K', 'C', 'a')
        c.put(12.5, M, 'W')
    return c


# ------------------------------------------------------------------ Godly
# Each class's Godly weapon fires a shot of its own: bigger (20x20), gold-rimmed and
# white-hot, in the set's colour. (Godly.SETS; Sprites.godlyShot)
G = 20
GM = 9.5


def gv():
    return Canvas(G, G)


def sparkle(c, x, y, ch='H', r=1):
    c.put(x, y, ch)
    for dx, dy in ((r, 0), (-r, 0), (0, r), (0, -r)):
        c.put(x + dx, y + dy, 'W' if ch == 'H' else ch)


def godly(cls):
    c = gv()
    if cls == 'wizard':        # a cosmic star: eight gold points round a white heart, a trail of stars
        tail(c, 0, 10, GM, 0.3, 5, 'a')
        for k, x in enumerate((1, 4, 7)):
            sparkle(c, x, GM + (2.5 if k % 2 else -2.5), 'W')
        for k in range(8):
            a = k * math.pi / 4
            r = 7 if k % 2 == 0 else 4.5
            c.line(13, GM, 13 + math.cos(a) * r, GM + math.sin(a) * r, 'G' if k % 2 == 0 else 'C', 2)
        c.ellipse(13, GM, 3, 3, 'C')
        c.ellipse(13, GM, 2, 2, 'W')
        c.ellipse(12.6, GM - 0.4, 1, 1, 'H')
    elif cls == 'archer':      # the dawn arrow: a long ray of light behind a winged gold head
        tail(c, 0, 12, GM, 0.3, 3.5, 'a')
        tail(c, 3, 13, GM, 0.3, 1.8, 'W')
        c.poly([(12, GM - 4.5), (19.5, GM), (12, GM + 4.5), (14, GM)], 'G')
        c.poly([(13.5, GM - 2), (17.5, GM), (13.5, GM + 2)], 'H')
        for dy in (-1, 1):
            c.line(9, GM + dy * 6, 13, GM + dy * 2, 'C', 2)
            c.line(8, GM + dy * 7, 11, GM + dy * 4, 'W')
    elif cls == 'knight':      # the oath blade: a broad holy blade with gold wings at its guard
        tail(c, 0, 6, GM, 0.3, 4, 'a')
        c.poly([(6, GM - 3), (16, GM - 3), (19.5, GM), (16, GM + 3), (6, GM + 3)], 'i')
        c.line(6, GM - 3, 16, GM - 3, 'H')
        c.line(7, GM, 17, GM, 'C')
        c.poly([(4, GM - 8), (7, GM - 3), (5, GM - 3)], 'G')
        c.poly([(4, GM + 8), (7, GM + 3), (5, GM + 3)], 'G')
        c.line(5, GM - 3, 5, GM + 3, 'G', 2)
        c.ellipse(5, GM, 1.2, 1.2, 'C')
    elif cls == 'priest':      # seraph light: a radiant orb in a gold halo, feathered wings behind
        for dy in (-1, 1):
            for k in range(4):
                c.line(4 + k * 1.5, GM + dy * (3 + k * 1.4), 10, GM + dy * 1.5, 'W' if k % 2 else 'C', 1)
        tail(c, 0, 7, GM, 0.3, 3, 'a')
        c.ring(13, GM, 5.5, 5.5, 'G', 1.2)
        c.ellipse(13, GM, 3.6, 3.6, 'W')
        c.ellipse(13, GM, 2, 2, 'H')
        for a in range(0, 360, 45):
            r = math.radians(a)
            c.put(13 + math.cos(r) * 7.5, GM + math.sin(r) * 7.5, 'H')
    elif cls == 'rogue':       # the eclipse kris: a wavy black blade edged in gold before a dark sun
        c.ellipse(5, GM, 4.5, 4.5, 'a')
        c.ring(5, GM, 4.5, 4.5, 'G', 1)
        c.ellipse(5.8, GM, 3, 3, 'K')
        for x in range(7, 19):
            y = GM + math.sin(x * 0.9) * 1.2
            w = 2.6 * (1 - (x - 7) / 13) + 0.6
            c.line(x, y - w, x, y + w, 'C')
            c.put(x, y - w, 'G')
            c.put(x, y + w, 'a')
            c.put(x, y, 'W')
        c.put(19, GM + math.sin(19 * 0.9) * 1.2, 'H')
    elif cls == 'warrior':     # the titan cleave: a huge crescent of fire with a white-hot gold edge
        for i in range(90):
            f = i / 89
            th = (f - 0.5) * 2.6
            wd = 4.5 * math.sin(f * math.pi)
            for k in range(int(wd * 2) + 1):
                rr = 9 - k * 0.5
                ch = 'H' if k == 0 else 'G' if k == 1 else ('a' if k > wd * 1.5 else 'C')
                c.put(7 + math.cos(th) * rr, GM + math.sin(th) * rr, ch)
        for dy in (-4, 0, 4):
            tail(c, 2, 11, GM + dy, 0.3, 1.6, 'a' if dy else 'C')
    elif cls == 'necromancer': # a soul: a pale skull in green flame, wisps streaming behind
        for k, dy in enumerate((-3, 0, 3)):
            for x in range(0, 11):
                y = GM + dy * (x / 10) + math.sin(x * 0.8 + k * 2) * 1.2
                c.put(x, y, 'a' if x < 5 else 'C')
        c.ellipse(13.5, GM, 5, 5, 'C')
        c.ellipse(14, GM - 0.5, 3.6, 3.4, 'i')
        c.rect(12.5, GM + 2.5, 16, GM + 4, 'i')
        c.put(13, GM - 0.5, 'K'); c.put(12.5, GM - 0.5, 'K')
        c.put(15.5, GM - 0.5, 'K'); c.put(16, GM - 0.5, 'K')
        c.put(14.5, GM + 1.5, 'a')
        c.put(13, GM + 4, 'a'); c.put(15, GM + 4, 'a')
        c.ring(14, GM, 5, 5, 'G', 0.6)
    elif cls == 'huntress':    # the wild thorn: a leaf-bladed spear wound with a living vine
        c.line(0, GM, 12, GM, 'S', 2)
        for x in range(0, 13):
            c.put(x, GM + math.sin(x * 1.1) * 2, 'C')
            if x % 4 == 1:
                c.ellipse(x, GM + math.sin(x * 1.1) * 2 + 1.5, 1, 1, 'W')
        c.poly([(11, GM), (14, GM - 4), (19.5, GM), (14, GM + 4)], 'C')
        c.line(11, GM, 19, GM, 'G')
        c.poly([(13, GM - 2), (17, GM), (13, GM + 2)], 'W', only='C')
        c.put(18.5, GM, 'H')
    elif cls == 'bard':        # a golden note riding a ringing wave of sound
        for x in range(0, 13):
            for k, amp in enumerate((3.5, 2)):
                c.put(x, GM + math.sin(x * 0.7 + k) * amp * (x / 12), 'C' if k == 0 else 'a')
        c.ellipse(13, GM + 4, 3, 2.3, 'G')
        c.ellipse(12.5, GM + 3.5, 1.2, 0.8, 'H')
        c.line(15.5, GM + 4, 15.5, GM - 6, 'G', 1.5)
        c.poly([(15.5, GM - 6), (19.5, GM - 3), (19, GM - 1), (15.5, GM - 3.5)], 'G')
        c.ring(13, GM + 4, 4.5, 3.6, 'W', 0.5)
    elif cls == 'alchemist':   # the philosopher's stone: a blood-red gem in a gold transmutation ring
        tail(c, 0, 8, GM, 0.3, 4, 'a')
        c.ring(12, GM, 7, 7, 'G', 0.9)
        c.poly([(12, GM - 7), (18, GM + 3.5), (6, GM + 3.5)], 'a')
        c.poly([(12, GM - 4.5), (16, GM + 2.5), (8, GM + 2.5)], 'C')
        c.poly([(12, GM - 4.5), (13.5, GM + 0), (10.5, GM)], 'W')
        c.put(11.5, GM - 2.5, 'H')
        for a in (90, 210, 330):
            r = math.radians(a)
            c.put(12 + math.cos(r) * 7, GM + math.sin(r) * 7, 'H')
    else:                      # chronomancer: a clock face, gold rim, hands at the last second
        for k in range(3):
            c.ring(6 - k * 2.5, GM, 4.5 - k, 4.5 - k, 'a' if k else 'C', 0.6)
        c.ellipse(12, GM, 7, 7, 'G')
        c.ellipse(12, GM, 6, 6, 'W')
        c.ellipse(12, GM, 4.6, 4.6, 'C')
        for h in range(12):
            r = h * math.pi / 6
            c.put(12 + math.cos(r) * 5.3, GM + math.sin(r) * 5.3, 'H' if h % 3 == 0 else 'a')
        c.line(12, GM, 12, GM - 4, 'H')
        c.line(12, GM, 15, GM + 1.5, 'G')
        c.put(12, GM, 'K')
    return c


GODLY = ['wizard', 'archer', 'knight', 'priest', 'rogue', 'warrior', 'necromancer', 'huntress', 'bard', 'alchemist', 'chronomancer']


KINDS = [('staff', staff), ('bow', bow), ('sword', sword), ('wand', wand), ('dagger', dagger)]


def designs():
    return {sub: [fn(t).rows() for t in range(8)] for sub, fn in KINDS}


def as3(d):
    gl = ['\t\t\t' + k + ': [' + ', '.join('"' + r + '"' for r in godly(k).rows()) + ']' for k in GODLY]
    lines = []
    for sub, rows in d.items():
        lines.append('\t\t\t' + sub + ': [' + ', '.join('[' + ', '.join('"' + r + '"' for r in f) + ']' for f in rows) + ']')
    return '''package realm {
	/**
	 * The weapons' own shots (tools/bossart/shots.py): a projectile for every tier of every
	 * weapon, 16x16 and pointing right, in colour slots the weapon's colour fills
	 * (Sprites.weaponShot). Generated: edit them there, not here.
	 */
	public class WeaponShots {
		public static const SHOTS:Object = {
''' + ',\n'.join(lines) + '''
		};
		/** Each class's Godly weapon's shot (20x20). */
		public static const GODLY:Object = {
''' + ',\n'.join(gl) + '''
		};
	}
}
'''


if __name__ == '__main__':
    d = designs()
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
    open(os.path.join(root, 'src', 'realm', 'WeaponShots.as'), 'w').write(as3(d))
    print('wrote WeaponShots.as')
    if len(sys.argv) > 1:
        from PIL import Image, ImageDraw
        cols = {'staff': 0xc070ff, 'bow': 0xffd040, 'sword': 0xff7020, 'wand': 0x80d0ff, 'dagger': 0x9040c0}
        S = 6
        sheet = Image.new('RGB', (8 * (N * S + 10) + 70, 5 * (N * S + 10)), (30, 34, 40))
        dr = ImageDraw.Draw(sheet)
        for r, (sub, rows) in enumerate(d.items()):
            col = cols[sub]
            def sh(v, f):
                return tuple(int(((v >> s) & 255) * f) for s in (16, 8, 0))
            pal = {'C': sh(col, 1), 'a': sh(col, 0.55), 'W': tuple(min(255, int(x + (255 - x) * 0.7)) for x in sh(col, 1)), 'H': (255, 255, 255),
                   'K': (16, 6, 28), 'G': (255, 216, 96), 'I': (160, 168, 184), 'i': (224, 232, 240), 'S': (138, 90, 42)}
            dr.text((4, r * (N * S + 10) + 40), sub, fill=(255, 255, 255))
            for t, f in enumerate(rows):
                for y, row in enumerate(f):
                    for x, ch in enumerate(row):
                        if ch in pal:
                            X, Y = 70 + t * (N * S + 10) + x * S, r * (N * S + 10) + 5 + y * S
                            dr.rectangle((X, Y, X + S - 1, Y + S - 1), fill=pal[ch])
        gcols = {'wizard': 0x80a0ff, 'archer': 0xffe080, 'knight': 0xc0e0ff, 'priest': 0xfff6c0, 'rogue': 0x9a60ff, 'warrior': 0xff6040,
                 'necromancer': 0x60ffb0, 'huntress': 0x80ff60, 'bard': 0xffe090, 'alchemist': 0xff5a3a, 'chronomancer': 0x80e0ff}
        S2 = 8
        gs = Image.new('RGB', (len(GODLY) * (G * S2 + 10), G * S2 + 10), (30, 34, 40))
        gd = ImageDraw.Draw(gs)
        for i, k in enumerate(GODLY):
            col = gcols[k]
            def sh(v, f):
                return tuple(int(((v >> s) & 255) * f) for s in (16, 8, 0))
            pal = {'C': sh(col, 1), 'a': sh(col, 0.55), 'W': tuple(min(255, int(x + (255 - x) * 0.7)) for x in sh(col, 1)), 'H': (255, 255, 255),
                   'K': (16, 6, 28), 'G': (255, 216, 96), 'I': (160, 168, 184), 'i': (224, 232, 240), 'S': (138, 90, 42)}
            for y, row in enumerate(godly(k).rows()):
                for x, ch in enumerate(row):
                    if ch in pal:
                        X, Y = 5 + i * (G * S2 + 10) + x * S2, 5 + y * S2
                        gd.rectangle((X, Y, X + S2 - 1, Y + S2 - 1), fill=pal[ch])
        gs.save(sys.argv[1].replace('.png', '_godly.png'))
        sheet.save(sys.argv[1])
