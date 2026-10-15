"""
Nerezza, the Tide Empress, from the user's own art (ref/nerezza.jpg): the sprite
IS that picture, cut from its background at its native pixel size (ref_cut.py)
and kept exactly as drawn. Her animations never redraw her: they move the
picture (a breath, the sway of her cape and gown, a lean as she glides) and lay
the sea's effects over and around it, after her design sheet: the trident blast,
the geysers, the tide slam, the seawardens she calls, her teleport, the ocean
explosion, the whirlpool, her guard, her death, and her second phase, where her
robes turn violet and she calls up waterspouts.

    python3 tools/bossart/nerezza.py out.png   draws a contact sheet of every frame
"""
import math
import os
import sys
import colorsys
from PIL import Image, ImageDraw
from ref_cut import cut

HERE = os.path.dirname(os.path.abspath(__file__))
BLOCK = 5.12               # screen pixels per pixel of the art
CW, CH = 196, 200          # the canvas: her picture plus room for the sea round her
OX, OY = 15, 16            # where the picture sits in it
SCALE = 2

# letters for the palette (no digits: the rows are run-length coded), effects first
LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%&*+-=?@^~'
FX = {
    'deep': 0x123a9a, 'water': 0x2f7cf0, 'light': 0x7cc8ff, 'foam': 0xd8f6ff, 'white': 0xffffff,
    'violet': 0x8a48f0, 'lilac': 0xc8a0ff, 'abyss': 0x081430,
}
N_ART = len(LETTERS) - len(FX)

_base = None


def base():
    """Her picture, quantised to the art's own colours: (RGBA image, palette {rgb: letter})."""
    global _base
    if _base:
        return _base
    im = cut(os.path.join(HERE, 'ref', 'nerezza.jpg'), BLOCK)
    alpha = im.getchannel('A')
    q = im.convert('RGB').quantize(colors=N_ART, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    pal = q.getpalette()[:N_ART * 3]
    rgb = q.convert('RGB')
    out = Image.new('RGBA', im.size, (0, 0, 0, 0))
    out.paste(rgb, mask=alpha)
    colours = {}
    for i in range(N_ART):
        c = (pal[i * 3], pal[i * 3 + 1], pal[i * 3 + 2])
        colours.setdefault(c, LETTERS[i])
    for k, (name, v) in enumerate(FX.items()):
        c = ((v >> 16) & 255, (v >> 8) & 255, v & 255)
        colours.setdefault(c, LETTERS[N_ART + k])
    _base = (out, colours)
    return _base


def fx(name):
    v = FX[name]
    return ((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)


# ------------------------------------------------------------------ the picture, moved
# landmarks in the picture (its own pixels): her raised hand's water, the staff's orb,
# the staff hand, her crown and the hem of her gown
HAND_ORB = (41, 42)
STAFF_ORB = (146, 35)
STAFF_HAND = (136, 85)
CROWN = (90, 6)
WAIST = 104


def her(dy=0, sway=0.0, lean=0.0, t=0.0):
    """Her picture on the canvas: dy lifts her, sway ripples the cape and gown below the waist, lean tilts her."""
    pic, _ = base()
    w, h = pic.size
    canvas = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    for y in range(h):
        row = pic.crop((0, y, w, y + 1))
        dx = 0.0
        if y > WAIST and sway:
            f = (y - WAIST) / (h - WAIST)
            dx += sway * f * math.sin(t + y * 0.09)
        if lean:
            dx += lean * (h - y) / h
        canvas.alpha_composite(row, (OX + int(round(dx)), OY + y - dy))
    return canvas


def at(p, dy=0):
    return (OX + p[0], OY + p[1] - dy)


def dissolve(img, keep, seed=1):
    """Breaks the picture into drops: keeps about `keep` of its pixels, the rest scatter as foam."""
    px = img.load()
    for y in range(CH):
        for x in range(CW):
            if px[x, y][3] == 0:
                continue
            hv = (x * 73856093 ^ y * 19349663 ^ seed * 83492791) & 0xffff
            if hv / 65536 >= keep:
                px[x, y] = fx('foam') if hv % 11 == 0 else (0, 0, 0, 0)
    return img


def over(img, layer):
    img.alpha_composite(layer)
    return img


# ------------------------------------------------------------------ the sea's effects
def layer():
    return Image.new('RGBA', (CW, CH), (0, 0, 0, 0))


def ring(d, cx, cy, rx, ry, col, width=1):
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), outline=col, width=width)


def orb(d, cx, cy, r, bright=False):
    d.ellipse((cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1), fill=fx('water'))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fx('light'))
    d.ellipse((cx - r * 0.45, cy - r * 0.45, cx + r * 0.2, cy + r * 0.2), fill=fx('white'))
    if bright:
        ring(d, cx, cy, r + 4, r + 4, fx('foam'))


def star(d, cx, cy, r):
    for k in range(8):
        a = k * math.pi / 4
        ln = r if k % 2 == 0 else r * 0.5
        d.line((cx, cy, cx + math.cos(a) * ln, cy + math.sin(a) * ln), fill=fx('foam') if k % 2 else fx('white'), width=1)
    d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=fx('white'))
    ring(d, cx, cy, r * 0.6, r * 0.6, fx('light'))


def droplets(d, t, n, seed, spread=(0, CW), top=10, bottom=CH - 20, col='light'):
    for i in range(n):
        hv = (i * 2654435761 + seed * 40503) & 0xffffffff
        x = spread[0] + hv % max(1, spread[1] - spread[0])
        y = top + ((hv >> 12) + int(t * 9)) % max(1, bottom - top)
        d.rectangle((x, y, x + 1, y + 2), fill=fx(col))
        d.point((x, y - 1), fill=fx('white'))


def geyser(d, x, base_y, ht, wd):
    """A column of water bursting up, a crown of spray at its head."""
    if ht <= 0:
        return
    top = base_y - ht
    d.rectangle((x - wd, top, x + wd, base_y), fill=fx('water'))
    d.rectangle((x - wd + 2, top, x + wd - 2, base_y), fill=fx('light'))
    d.line((x, top, x, base_y), fill=fx('foam'))
    for k in range(-2, 3):
        d.ellipse((x + k * 3 - 2, top - 3 - abs(k) * -1, x + k * 3 + 2, top + 1), fill=fx('foam'))
        d.point((x + k * 5, top - 6 + abs(k) * 2), fill=fx('white'))
    d.ellipse((x - wd - 6, base_y - 3, x + wd + 6, base_y + 3), outline=fx('light'))


def wave(d, x, base_y, ht, wd, facing=1):
    """A breaking wave: a long back rising to a crest that overhangs its hollow face and curls down, foam on its lip."""
    def P(fx_, fy):
        return (x + facing * fx_ * wd, base_y - fy * ht)
    body = [P(0, 0), P(0.12, 0.3), P(0.3, 0.68), P(0.5, 0.93), P(0.68, 1.0), P(0.85, 0.94), P(0.97, 0.78), P(1.0, 0.62),
            P(0.93, 0.56), P(0.86, 0.64), P(0.8, 0.55), P(0.76, 0.36), P(0.8, 0.14), P(0.9, 0)]
    d.polygon(body, fill=fx('water'))
    # the hollow under the lip
    d.polygon([P(0.79, 0.52), P(0.86, 0.6), P(0.9, 0.55), P(0.86, 0.36), P(0.82, 0.18), P(0.78, 0.32)], fill=fx('deep'))
    # lighter water up the back, and bands across it
    d.polygon([P(0.1, 0.0), P(0.22, 0.32), P(0.4, 0.66), P(0.58, 0.84), P(0.6, 0.6), P(0.5, 0.3), P(0.44, 0)], fill=fx('light'))
    for k in range(4):
        f = 0.2 + k * 0.14
        d.line([P(f, 0.05), P(f + 0.1, 0.5 + k * 0.08)], fill=fx('foam'))
    # foam along the lip and the curl, spray flying off
    d.line([P(0.45, 0.88), P(0.6, 0.99), P(0.74, 1.0), P(0.88, 0.93), P(0.98, 0.77), P(1.0, 0.63), P(0.94, 0.57)], fill=fx('white'), width=2)
    for i in range(10):
        sp = P(0.98 + (i % 4) * 0.04, 0.72 + ((i * 7) % 9) * 0.035)
        d.point(sp, fill=fx('white' if i % 2 else 'foam'))
    d.line([P(0.86, 0), P(1.05, 0)], fill=fx('foam'), width=2)


def whirl(d, cx, cy, r, t, front, col='light'):
    """A whirlpool round her: rings turning, drawn in two halves (behind her and in front)."""
    for k in range(4):
        rx = r * (1 - k * 0.2)
        ry = rx * 0.3
        a0 = 0 if front else 180
        d.arc((cx - rx, cy - ry, cx + rx, cy + ry), a0 + t * 40 + k * 25, a0 + 180 + t * 40 + k * 25, fill=fx(col if k % 2 else 'water'), width=2)
    if front:
        for k in range(6):
            a = t * 0.8 + k * math.pi / 3
            d.ellipse((cx + math.cos(a) * r - 1, cy + math.sin(a) * r * 0.3 - 1, cx + math.cos(a) * r + 1, cy + math.sin(a) * r * 0.3 + 1), fill=fx('white'))


def spout(d, cx, base_y, ht, t, col='lilac'):
    """A waterspout: a ragged funnel of spinning water, narrow at the floor and wide at the top, spray flung off it."""
    if ht <= 0:
        return
    for k in range(int(ht)):
        f = k / ht
        y = base_y - k
        w = 2 + f * f * 16 + ((k * 7 + int(t * 5)) % 5) * 0.6
        ox = math.sin(t * 0.9 + f * 6) * 5 * f
        for xx in range(int(cx + ox - w), int(cx + ox + w) + 1):
            u = (xx - cx - ox) / max(w, 1)
            # slanted bands winding round it, darker at its sides
            band = int(k * 0.35 + u * 5 + t * 3) % 5
            c = ('water', 'violet', col, 'violet', 'deep')[band] if abs(u) < 0.8 else 'deep'
            d.point((xx, y), fill=fx(c))
        d.point((cx + ox - w, y), fill=fx(col))
        if (k + int(t * 3)) % 9 == 0:
            d.point((cx + ox + w * 0.4, y), fill=fx('white'))
    for i in range(10):
        f = ((i * 0.37 + t * 0.11) % 1)
        y = base_y - f * ht
        w = 2 + f * f * 16
        d.point((cx + (w + 4 + i % 3) * (1 if i % 2 else -1), y - 2), fill=fx('foam'))
    d.ellipse((cx - 10, base_y - 2, cx + 10, base_y + 2), outline=fx('foam'))


def seawarden(d, x, base_y, ht):
    """A seawarden rising from the water: a merfolk shape, a head, a fin."""
    if ht <= 4:
        return
    d.ellipse((x - 5, base_y - ht, x + 5, base_y - ht + 10), fill=fx('water'))
    d.polygon([(x - 6, base_y - ht + 8), (x + 6, base_y - ht + 8), (x + 4, base_y), (x - 4, base_y)], fill=fx('deep'))
    d.point((x - 2, base_y - ht + 4), fill=fx('white'))
    d.point((x + 2, base_y - ht + 4), fill=fx('white'))
    d.polygon([(x, base_y - ht - 4), (x + 3, base_y - ht + 2), (x - 3, base_y - ht + 2)], fill=fx('light'))


FEET = OY + 178


# ------------------------------------------------------------------ the animations
def idle(t):
    dy = [0, 0, 1, 1, 1, 0][t]
    img = her(dy, sway=1.2, t=t * 1.05)
    d = ImageDraw.Draw(img)
    hx, hy = at(HAND_ORB, dy)
    if t in (2, 3):
        ring(d, hx, hy, 8, 8, fx('light'))
    sx, sy = at(STAFF_ORB, dy)
    if t in (1, 2, 3):
        ring(d, sx, sy, 7 + (t == 2), 7 + (t == 2), fx('foam'))
    return img


def move(t):
    dy = [0, 1, 2, 1, 0, 1][t]
    img = her(dy, sway=3.0, lean=4.0, t=t * 1.05 + 0.5)
    d = ImageDraw.Draw(img)
    droplets(d, t, 8, 5, spread=(2, 40), top=FEET - 60, bottom=FEET)
    for i in range(4):
        y = FEET - 6 - i * 4
        d.line((4 + i * 3, y, 22 + i * 4 + (t % 2) * 3, y), fill=fx('light'))
    return img


def trident(t):
    """Trident blast: the staff's orb swells, then orbs of water are hurled ahead and burst."""
    img = her([0, 0, 1, 1, 0, 0][t], sway=1.5, lean=[0, -1, -2, 2, 1, 0][t], t=t)
    d = ImageDraw.Draw(img)
    sx, sy = at(STAFF_ORB)
    if t in (1, 2):
        ring(d, sx, sy, 6 + t * 3, 6 + t * 3, fx('foam'))
        ring(d, sx, sy, 3 + t * 3, 3 + t * 3, fx('light'))
    if t == 3:
        for k in range(3):
            ox, oy = sx + 12 + k * 13, sy + 8 + k * 9
            d.line((ox - 10, oy - 4, ox, oy), fill=fx('light'), width=2)
            orb(d, ox, oy, 5 - k)
    if t == 4:
        orb(d, CW - 22, sy + 40, 5, bright=True)
        star(d, CW - 12, sy + 62, 13)
    return img


def geysers(t):
    """Trident blast (vertical): she calls the sea up through the floor in columns round her."""
    img = layer()
    d = ImageDraw.Draw(img)
    hts = [0, 0, 26, 60, 90, 40][t]
    xs = [16, 182, 36, 162]
    for k, x in enumerate(xs):
        if t >= 2:
            geyser(d, x, FEET + 2 - (k // 2) * 6, hts * (1 - (k // 2) * 0.25), 4)
    over(img, her([0, 1, 1, 0, 0, 0][t], sway=1.5, t=t))
    d = ImageDraw.Draw(img)
    sx, sy = at(STAFF_ORB)
    if t in (1, 2, 3):
        ring(d, sx, sy, 10, 10, fx('white'))
    if t == 1:
        ring(d, CW // 2, FEET, 70, 8, fx('light'))
    return img


def slam(t):
    """Tide slam: the sea rears up beside her and crashes forward in a great wave."""
    img = her([0, 1, 1, 0, 0, 0][t], sway=2, lean=[0, -2, -3, 3, 2, 0][t], t=t)
    d = ImageDraw.Draw(img)
    sx, sy = at(STAFF_ORB)
    if t in (1, 2):
        ring(d, sx, sy, 9, 9, fx('foam'))
    if t == 2:
        wave(d, 108, FEET, 40, 50, 1)
    if t == 3:
        wave(d, 118, FEET, 62, 72, 1)
    if t == 4:
        wave(d, 130, FEET, 44, 64, 1)
        droplets(d, t, 14, 9, spread=(120, CW), top=FEET - 70, bottom=FEET)
    if t == 5:
        for k in range(8):
            d.ellipse((132 + k * 7, FEET - 3 - (k % 2) * 2, 138 + k * 7, FEET + 1), fill=fx('foam'))
    return img


def summon(t):
    """Summon seawardens: arches of water rise at her sides and her wardens climb out of them."""
    img = layer()
    d = ImageDraw.Draw(img)
    for x, sgn in ((20, 1), (176, -1)):
        if t >= 1:
            ht = [0, 30, 54, 54, 40][t]
            d.arc((x - 18, FEET - ht, x + 18, FEET + ht), 180, 360, fill=fx('water'), width=4)
            d.arc((x - 15, FEET - ht + 3, x + 15, FEET + ht), 180, 360, fill=fx('light'), width=1)
        if t >= 3:
            seawarden(d, x, FEET, [0, 0, 0, 16, 28][t])
    over(img, her([0, 1, 1, 0, 0][t], sway=1.5, t=t))
    d = ImageDraw.Draw(img)
    if t in (1, 2):
        hx, hy = at(HAND_ORB)
        ring(d, hx, hy, 10, 10, fx('foam'))
    return img


def teleport(t):
    """Teleport: she runs to water, swirls away into a ripple, and pours back out somewhere else."""
    if t == 3:
        img = layer()
        d = ImageDraw.Draw(img)
        for k in range(3):
            ring(d, CW // 2, FEET - 4, 20 + k * 14, 4 + k * 3, fx('light' if k % 2 else 'foam'))
        star(d, CW // 2, FEET - 60, 12)
        droplets(d, t, 16, 3, spread=(50, 146), top=40, bottom=FEET - 10, col='foam')
        return img
    img = her(0, sway=1.5, t=t)
    keep = [1.0, 0.75, 0.35, 0, 0.5, 1.0][t]
    if keep < 1:
        dissolve(img, keep, seed=t)
    d = ImageDraw.Draw(img)
    if t in (1, 2, 4):
        ring(d, CW // 2, FEET - 2, 50, 6, fx('light'))
        droplets(d, t, 12, 7, spread=(30, 166), top=30, bottom=FEET - 10, col='foam')
    if t == 5:
        ring(d, CW // 2, FEET - 2, 40, 5, fx('foam'))
    return img


def explode(t):
    """Ocean explosion: the sea gathers at her feet, then bursts up all round her in a crown of water."""
    back = layer()
    d = ImageDraw.Draw(back)
    if t >= 3:
        ht = [0, 0, 0, 70, 96, 50][t]
        for k in range(9):
            a = math.pi + k * math.pi / 8
            x = CW // 2 + math.cos(a) * 88
            geyser(d, x, FEET - 8 + math.sin(a) * 6, ht * (0.6 + 0.4 * abs(math.sin(a))), 3)
    img = over(back, her([0, 1, 2, 1, 0, 0][t], sway=2 if t < 3 else 3, t=t))
    d = ImageDraw.Draw(img)
    if t in (1, 2):
        r = [0, 40, 70][t]
        ring(d, CW // 2, FEET, r, r * 0.12 + 2, fx('light'), 2)
        ring(d, CW // 2, FEET, r * 0.7, r * 0.09 + 1, fx('foam'))
    if t >= 3:
        for k in range(9):
            a = k * math.pi / 8
            x = CW // 2 + math.cos(a) * 88
            geyser(d, x, FEET + 4 + math.sin(a) * 6, [0, 0, 0, 50, 76, 36][t] * (0.6 + 0.4 * abs(math.sin(a))), 3)
    if t == 5:
        droplets(d, t, 24, 4, top=20, bottom=FEET, col='foam')
    return img


def whirlpool(t):
    """Gravity pull: a whirlpool opens round her and drags everything in."""
    r = [0, 46, 72, 92, 92, 70][t]
    img = layer()
    d = ImageDraw.Draw(img)
    if r:
        whirl(d, CW // 2, FEET - 4, r, t, front=False)
    over(img, her([0, 0, 1, 1, 1, 0][t], sway=2.5, t=t * 1.3))
    d = ImageDraw.Draw(img)
    if r:
        whirl(d, CW // 2, FEET - 4, r, t, front=True)
    if t in (3, 4):
        for k in range(8):
            a = t * 0.9 + k * math.pi / 4
            x, y = CW // 2 + math.cos(a) * (r + 6), FEET - 30 + math.sin(a) * 26
            d.ellipse((x - 2, y - 2, x + 2, y + 2), fill=fx('light'))
    return img


def guard(t):
    """Guard: she draws the sea round herself in a shell of water while her shield holds."""
    img = her([0, 1, 1, 0][t], sway=1.2, t=t)
    d = ImageDraw.Draw(img)
    r = [84, 90, 90, 86][t]
    ring(d, CW // 2, OY + 92, r, r * 1.08, fx('light'), 2)
    ring(d, CW // 2, OY + 92, r - 4, r * 1.08 - 4, fx('foam'))
    for k in range(10):
        a = k * math.pi / 5 + t * 0.4
        d.point((CW // 2 + math.cos(a) * r, OY + 92 + math.sin(a) * r * 1.08), fill=fx('white'))
    return img


def death(t):
    """She loses her form: the sea pours out of her, she dissolves into water and is gone in a ring of bubbles."""
    if t <= 4:
        img = her([0, 2, 4, 6, 8][t], sway=3, t=t)
        keep = [1.0, 0.85, 0.6, 0.35, 0.15][t]
        if keep < 1:
            dissolve(img, keep, seed=t + 20)
        d = ImageDraw.Draw(img)
        if t >= 1:
            whirl(d, CW // 2, FEET - 4, 40 + t * 10, t, front=True, col='foam')
            droplets(d, t, 10 + t * 4, 11, spread=(30, 166), top=20, bottom=FEET, col='light')
        return img
    img = layer()
    d = ImageDraw.Draw(img)
    for k in range(14):
        a = k * math.pi / 7 + t
        r = 30 if t == 5 else 46
        x, y = CW // 2 + math.cos(a) * r, FEET - 40 + math.sin(a) * r * 0.6
        d.ellipse((x - 2, y - 2, x + 2, y + 2), outline=fx('foam'))
    ring(d, CW // 2, FEET, 40 if t == 5 else 30, 5, fx('light'))
    return img


def spout_attack(t):
    """Her second phase: waterspouts called up beside her."""
    img = layer()
    d = ImageDraw.Draw(img)
    ht = [0, 40, 90, 140, 140, 80][t]
    for x in (18, 178):
        if ht:
            spout(d, x, FEET, ht, t, col='lilac')
    return over(img, her([0, 1, 1, 0, 0, 0][t], sway=2, t=t))


# her second phase: the same picture, her robes and the sea's light turned to violet
def violet(colours):
    """Her palette with the blues and teals turned violet: {letter: colour}."""
    out = {}
    for (r, g, b), letter in colours.items():
        h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        if s > 0.18 and 0.42 < h < 0.75 and l < 0.8:
            h = (h + 0.16) % 1.0
            s = min(1, s * 1.1)
        rr, gg, bb = colorsys.hls_to_rgb(h, l, s)
        out[letter] = (int(rr * 255) << 16) | (int(gg * 255) << 8) | int(bb * 255)
    return out


def rage_idle(t):
    img = her([0, 1, 1, 0][t], sway=2, t=t * 1.4)
    d = ImageDraw.Draw(img)
    droplets(d, t, 10, 13, top=10, bottom=FEET, col='lilac')
    return img


def rage_move(t):
    return move(t)


SEQ = [
    ('idle', idle, 6), ('move', move, 6), ('trident', trident, 5), ('geyser', geysers, 6), ('slam', slam, 6), ('summon', summon, 5),
    ('teleport', teleport, 6), ('explode', explode, 6), ('whirlpool', whirlpool, 6), ('spout', spout_attack, 6), ('guard', guard, 4),
    ('death', death, 7),
]


def rows(img, colours):
    """An image of exact palette colours -> rows of letters ('.' for nothing)."""
    px = img.load()
    out = []
    for y in range(CH):
        r = []
        for x in range(CW):
            p = px[x, y]
            r.append('.' if p[3] == 0 else colours[(p[0], p[1], p[2])])
        out.append(''.join(r))
    return out


def pal_of(colours):
    return {letter: (r << 16) | (g << 8) | b for (r, g, b), letter in colours.items()}


def sequences():
    _, colours = base()
    pal = pal_of(colours)
    vpal = violet(colours)
    out = []
    for name, fn, n in SEQ:
        p = vpal if name == 'spout' else pal
        out.append(('tide_empress_' + name, [rows(fn(t), colours) for t in range(n)], p, SCALE))
    out.append(('tide_empress_ridle', [rows(rage_idle(t), colours) for t in range(4)], vpal, SCALE))
    out.append(('tide_empress_rmove', [rows(rage_move(t), colours) for t in range(6)], vpal, SCALE))
    out.append(('tide_empress', [rows(f, colours) for f in (idle(0), idle(2), move(0), move(3), trident(3), explode(4))], pal, SCALE))
    return out


def recolors():
    """Her attacks in her rage colours: the same frames with the violet palette (no second copy of the pixels)."""
    _, colours = base()
    vpal = violet(colours)
    return [('tide_empress_' + name + '_r', 'tide_empress_' + name, vpal) for name, fn, n in SEQ]


if __name__ == '__main__':
    seqs = sequences()
    frames = [(n, f, p) for n, fr, p, s in seqs for f in fr]
    cols = 6
    cw, ch = CW * 2 + 8, CH * 2 + 20
    sheet = Image.new('RGB', (cols * cw, ((len(frames) + cols - 1) // cols) * ch), (20, 28, 48))
    d = ImageDraw.Draw(sheet)
    for i, (n, f, p) in enumerate(frames):
        im = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
        px = im.load()
        for y, row in enumerate(f):
            for x, c in enumerate(row):
                if c != '.':
                    v = p[c]
                    px[x, y] = ((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)
        im = im.resize((CW * 2, CH * 2), Image.NEAREST)
        x, y = (i % cols) * cw, (i // cols) * ch
        sheet.paste(im, (x + 4, y + 16), im)
        d.text((x + 4, y + 2), n, fill=(220, 230, 255))
    sheet.save(sys.argv[1] if len(sys.argv) > 1 else 'nerezza.png')
