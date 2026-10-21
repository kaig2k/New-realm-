"""
Gorehorn the Behemoth, after the user's own art (ref/gorehorn.png, cleaned from their picture
ref/gorehorn.webp; their design sheet is ref/gorehorn_sheet.webp), redrawn on the game's grid
by gorehorn_game.py so he sits with the other bosses. His animations move it (a breath, a heavy gallop, rearing up, the
lean of a charge, the stagger of a stun) and lay his sheet's effects over and around it:
the horn slam's spike eruption, the charge's blood streak and dust, the spike barrage, the
ground pulse's rings, the blood spawn he calls, and his death. Past his rage his cracks burn
hotter (the rage palette: ember instead of blood).

Also his minion (the gore spawn), the bone stakes of his arena, and their broken stumps.

    python3 tools/bossart/gorehorn.py out.png   draws a contact sheet of every frame
"""
import math
import os
import sys
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
CW, CH = 120, 100          # the canvas: his picture plus room for spikes and dust round him
OX, OY = 26, 24            # where the picture sits in it
SCALE = 4                  # every frame is drawn at 2 canvas pixels a cell, then halved (chunk)

LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
# his own colours (the picture's palette), then the effects'
ART = [0x0a0508, 0x1c1018, 0x2e1e2c, 0x47313f, 0x664a56, 0x8a6a70, 0x7a5c4c, 0xb8987a, 0xe6cfa8,
       0x4a0810, 0x8c0c18, 0xd01420, 0xff3a2a]
import gorehorn_game
ART += [v for v in gorehorn_game.PAL.values() if v not in ART]
FX = {'hot': 0xff7a4a, 'glow': 0xffc890, 'white': 0xffffff, 'dust': 0x6a5a52, 'dustl': 0x9a8878, 'star': 0xffe070}
RED = [0x4a0810, 0x8c0c18, 0xd01420, 0xff3a2a]
# rage: the cracks burn ember-orange, a little brighter
RAGE = {0x4a0810: 0x7a1a08, 0x8c0c18: 0xc03010, 0xd01420: 0xff6020, 0xff3a2a: 0xffb040,
        0x6e0c14: 0x7a1a08, 0xd01c24: 0xff6020, 0xff5a3a: 0xffb040}


def rgb(v):
    return ((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)


COLOURS = {}
for i, v in enumerate(ART + list(FX.values())):
    COLOURS.setdefault(rgb(v)[:3], LETTERS[i])


def fx(name):
    return rgb(FX[name])


_pic = None


def pic():
    global _pic
    if _pic is None:
        # the game-grid drawing, each cell 2x2 canvas pixels
        c = gorehorn_game.design()
        im = Image.new('RGBA', (gorehorn_game.W, gorehorn_game.H), (0, 0, 0, 0))
        px = im.load()
        for y, row in enumerate(c.rows()):
            for x, ch in enumerate(row):
                if ch != '.':
                    px[x, y] = rgb(gorehorn_game.PAL[ch])
        _pic = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
    return _pic


PW, PH = 68, 68
EYES = (25, 34)            # between his eyes (picture pixels)
HORN = (50, 24)            # the great horn's curve
FEET = OY + 65             # where his claws meet the ground, on the canvas


def him(dy=0, lean=0.0, sway=0.0, t=0.0, squash=0):
    """His picture on the canvas: dy lifts him, lean tips his top forward (+) or back (-),
    sway rocks his body side to side, squash crouches him (drops the top rows down)."""
    p = pic()
    canvas = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    for y in range(PH):
        row = p.crop((0, y, PW, y + 1))
        up = (PH - y) / PH
        dx = lean * up + sway * up * math.sin(t)
        yy = y
        if squash and y < PH - 12:
            yy = y + int(squash * (1 - y / (PH - 12)))
        canvas.alpha_composite(row, (OX + int(round(dx)), OY + yy - dy))
    return canvas


def at(p, dy=0, lean=0.0):
    return (OX + p[0] + int(lean * (PH - p[1]) / PH), OY + p[1] - dy)


def layer():
    return Image.new('RGBA', (CW, CH), (0, 0, 0, 0))


def under(img, base):
    """Draws `img` (effects behind him) and puts him over it."""
    img.alpha_composite(base)
    return img


# ------------------------------------------------------------------ effects
def spike(d, x, base_y, h, w=3, col='hot'):
    """A bone spike bursting from the ground: dark rim, red core, pale tip."""
    if h <= 0:
        return
    d.polygon([(x - w, base_y), (x + w, base_y), (x, base_y - h)], fill=rgb(0x4a0810))
    d.polygon([(x - w + 1, base_y), (x + w - 1, base_y), (x, base_y - h + 1)], fill=rgb(0xd01420))
    d.line((x, base_y - h + 1, x, base_y - max(1, h // 2)), fill=fx(col))
    d.point((x, base_y - h), fill=fx('glow'))


def crack(d, x, y, n, t, col='hot'):
    """Glowing cracks spreading through the ground from a point."""
    for k in range(n):
        a = k * math.pi * 2 / n + t * 0.3
        ln = 6 + (k * 7) % 9
        px, py = x, y
        for s in range(3):
            nx, ny = px + math.cos(a + (s - 1) * 0.5) * ln / 3, py + math.sin(a + (s - 1) * 0.5) * ln / 6
            d.line((px, py, nx, ny), fill=rgb(0xd01420) if s else fx(col))
            px, py = nx, ny


def dust(d, cx, cy, t, n=6, spread=14, light=False):
    for k in range(n):
        a = k * 2.399 + t * 0.7
        r = spread * (0.4 + ((k * 37 + t * 11) % 10) / 16)
        x, y = cx + math.cos(a) * r, cy + math.sin(a) * r * 0.35
        s = 1 + (k + t) % 3
        d.ellipse((x - s, y - s, x + s, y + s), fill=fx('dustl' if light or k % 2 else 'dust'))


def ring(d, cx, cy, rx, ry, col, width=1):
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), outline=col, width=width)


def streak(d, y0, y1, t):
    """Motion lines behind a charge."""
    for k in range(6):
        y = y0 + (y1 - y0) * k / 5
        ln = 10 + (k * 13 + t * 7) % 18
        d.line((2, y, 2 + ln, y), fill=fx('hot') if k % 2 else rgb(0xd01420))


def flying_spike(d, x, y, a, ln=7):
    x2, y2 = x + math.cos(a) * ln, y + math.sin(a) * ln
    d.line((x, y, x2, y2), fill=rgb(0xd01420), width=2)
    d.line((x + math.cos(a) * ln * 0.4, y + math.sin(a) * ln * 0.4, x2, y2), fill=fx('hot'))
    d.point((x2, y2), fill=fx('glow'))


def stars(d, cx, cy, t):
    for k in range(3):
        a = t * 1.3 + k * math.pi * 2 / 3
        x, y = cx + math.cos(a) * 10, cy + math.sin(a) * 3
        d.line((x - 2, y, x + 2, y), fill=fx('star'))
        d.line((x, y - 2, x, y + 2), fill=fx('star'))


def spawn_blob(d, x, base_y, h):
    """A gore spawn clawing out of a blood pool: a red lump with two bone horns."""
    d.ellipse((x - 7, base_y - 2, x + 7, base_y + 2), fill=rgb(0x4a0810))
    if h <= 0:
        return
    d.ellipse((x - 5, base_y - h, x + 5, base_y), fill=rgb(0x8c0c18))
    d.ellipse((x - 4, base_y - h + 1, x + 3, base_y - 2), fill=rgb(0xd01420))
    d.line((x - 4, base_y - h + 2, x - 6, base_y - h - 2), fill=rgb(0xe6cfa8))
    d.line((x + 4, base_y - h + 2, x + 6, base_y - h - 2), fill=rgb(0xe6cfa8))
    d.point((x - 1, base_y - h + 4), fill=fx('glow'))
    d.point((x + 2, base_y - h + 4), fill=fx('glow'))


def eye_glow(d, dy=0, lean=0.0, r=4):
    ex, ey = at(EYES, dy, lean)
    ring(d, ex, ey, r, r * 0.6, fx('hot'))


# ------------------------------------------------------------------ his animations
def idle(t):
    dy = [0, 0, 1, 1][t]
    img = him(dy, sway=0.6, t=t * 1.4)
    if t == 2:
        d = ImageDraw.Draw(img)
        ex, ey = at(EYES, dy)
        d.point((ex - 2, ey), fill=fx('glow'))
        d.point((ex + 3, ey), fill=fx('glow'))
    return img


def move(t):
    dy = [0, 2, 3, 1, 0, 2][t]
    base = him(dy, lean=[1, 2, 1, -1, -2, -1][t], sway=1.2, t=t * 1.05)
    img = layer()
    d = ImageDraw.Draw(img)
    dust(d, CW // 2, FEET, t, n=5, spread=26)
    return under(img, base)


def slam(t):
    """Horn Slam: he rears back, then drives his horn into the ground and it erupts in spikes."""
    dy = [0, 5, 8, -2, -2, 0][t]
    lean = [0, -3, -4, 4, 3, 1][t]
    base = him(dy, lean=lean, squash=[0, 0, 0, 3, 2, 0][t])
    img = layer()
    d = ImageDraw.Draw(img)
    if t >= 3:
        hts = [0, 0, 0, 16, 26, 14][t]
        for k, x in enumerate([16, 30, 46, 62, 78, 94, 106]):
            spike(d, x, FEET + 3 - (k % 2) * 3, hts - abs(k - 3) * 3, 3 + (k % 2))
        crack(d, CW // 2, FEET + 1, 7, t)
        dust(d, CW // 2, FEET, t, n=8, spread=40, light=True)
    img = under(img, base)
    if t in (1, 2):
        eye_glow(ImageDraw.Draw(img), dy, lean, 3 + t)
    return img


def charge(t):
    """Charge: he paws the ground (eyes blazing), then thunders forward in a streak of blood."""
    if t < 3:
        dy = [1, 3, 2][t]
        base = him(dy, lean=[2, 4, 5][t], squash=[0, 2, 3][t])
        img = layer()
        d = ImageDraw.Draw(img)
        dust(d, CW // 2 + 14, FEET, t, n=4 + t * 2, spread=12 + t * 4, light=True)
        crack(d, CW // 2 + 14, FEET + 1, 3 + t, t)
        img = under(img, base)
        eye_glow(ImageDraw.Draw(img), dy, [2, 4, 5][t], 3 + t)
        return img
    base = him([2, 3, 2][t - 3], lean=7, squash=2)
    img = layer()
    d = ImageDraw.Draw(img)
    streak(d, OY + 18, FEET - 4, t)
    dust(d, 14, FEET, t, n=8, spread=18)
    img = under(img, base)
    d = ImageDraw.Draw(img)
    ex, ey = at(EYES, 2, 7)
    d.line((ex, ey, ex - 14, ey), fill=fx('hot'))
    return img


def barrage(t):
    """Spike Barrage: he hunches, his back's spikes bristle, then fly out in every direction."""
    dy = [0, -1, -2, 1, 0][t]
    img = him(dy, squash=[0, 2, 3, 0, 0][t])
    d = ImageDraw.Draw(img)
    cx, cy = OX + PW // 2, OY + 26 - dy
    if t in (1, 2):
        ring(d, cx, cy, 20 + t * 4, 14 + t * 3, fx('hot'))
    if t >= 3:
        for k in range(10):
            a = k * math.pi * 2 / 10 + (t - 3) * 0.2
            r = 30 + (t - 3) * 14
            flying_spike(d, cx + math.cos(a) * r, cy + math.sin(a) * r * 0.75, a, 7)
    return img


def pulse(t):
    """Ground Pulse: he stamps and a ring of spikes bursts out from his body, spreading."""
    dy = [0, 3, -2, -1, 0, 0][t]
    base = him(dy, squash=[0, 0, 3, 2, 1, 0][t])
    img = layer()
    d = ImageDraw.Draw(img)
    cx, cy = CW // 2, FEET - 2
    if t >= 2:
        r = 14 + (t - 2) * 13
        ring(d, cx, cy, r, r * 0.35, fx('hot'), 2)
        ring(d, cx, cy, r - 4, (r - 4) * 0.35, rgb(0xd01420))
        for k in range(12):
            a = k * math.pi * 2 / 12
            spike(d, int(cx + math.cos(a) * r), int(cy + math.sin(a) * r * 0.35), 7 - (t - 2), 2)
    img = under(img, base)
    if t == 1:
        eye_glow(ImageDraw.Draw(img), dy, 0, 4)
    return img


def summon(t):
    """Summon: he roars blood into the ground and gore spawn claw up beside him."""
    dy = [0, -2, -3, -2, 0][t]
    base = him(dy, lean=[0, -2, -3, -2, 0][t])
    img = layer()
    d = ImageDraw.Draw(img)
    for x in (12, CW - 12):
        spawn_blob(d, x, FEET, [0, 0, 5, 9, 11][t])
    img = under(img, base)
    if t in (1, 2, 3):
        d = ImageDraw.Draw(img)
        ex, ey = at(EYES, dy, -2)
        for k in range(4):
            ln = 4 + t * 3
            d.line((ex - 10 - k * 2, ey - 6 + k * 4, ex - 10 - k * 2 - ln, ey - 8 + k * 5), fill=fx('hot'))
    return img


def stun(t):
    """Stunned: he slammed into a bone stake and reels, seeing stars."""
    base = him([1, 2, 1, 2][t], lean=[-2, 2, -2, 2][t], squash=1)
    img = base
    d = ImageDraw.Draw(img)
    ex, ey = at(EYES, 1)
    stars(d, ex + 6, ey - 26, t)
    return img


def guard(t):
    """Roar: a new phase. He rears up and bellows, a red ring of fury round him."""
    dy = [0, 4, 6, 4][t]
    img = him(dy, lean=[0, -3, -4, -3][t])
    d = ImageDraw.Draw(img)
    ring(d, CW // 2, FEET - 30, 44 + t * 2, 34 + t * 2, fx('hot'))
    ring(d, CW // 2, FEET - 30, 40 + t * 2, 30 + t * 2, rgb(0xd01420))
    ex, ey = at(EYES, dy, -4)
    for k in range(5):
        d.line((ex - 6 - k * 3, ey - 8 + k * 4, ex - 14 - k * 4 - t * 2, ey - 10 + k * 5), fill=fx('glow') if k % 2 else fx('hot'))
    return img


def death(t):
    """He collapses: sinks, crumbles to bone and blood, and a last ring of spikes bursts out."""
    keep = [1.0, 1.0, 0.85, 0.65, 0.45, 0.25, 0.0][t]
    base = him(-[0, 3, 6, 9, 12, 14, 14][t], lean=[0, 2, 4, 5, 5, 5, 5][t])
    px = base.load()
    for y in range(CH):
        for x in range(CW):
            if px[x, y][3] == 0:
                continue
            hv = (x * 73856093 ^ y * 19349663 ^ 7 * 83492791) & 0xffff
            if hv / 65536 >= keep:
                px[x, y] = rgb(0xd01420) if hv % 9 == 0 else (0, 0, 0, 0)
    img = layer()
    d = ImageDraw.Draw(img)
    if t >= 3:
        for k, x in enumerate([22, 38, 54, 70, 86, 100]):
            spike(d, x, FEET + 2, [0, 0, 0, 10, 18, 14, 8][t] - abs(k - 2.5) * 2, 3)
        d.ellipse((CW // 2 - 30, FEET - 3, CW // 2 + 30, FEET + 3), fill=rgb(0x4a0810))
    return under(img, base)


# ------------------------------------------------------------------ his minion and his arena's stakes
def gore_spawn(t):
    img = Image.new('RGBA', (24, 20), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    b = 18 - (t % 2)
    d.ellipse((3, b - 12, 21, b), fill=rgb(0x4a0810))
    d.ellipse((4, b - 11, 20, b - 1), fill=rgb(0x8c0c18))
    d.ellipse((6, b - 10, 16, b - 4), fill=rgb(0xd01420))
    d.line((6, b - 10, 3, b - 15), fill=rgb(0xe6cfa8), width=2)
    d.line((18, b - 10, 21, b - 15), fill=rgb(0xe6cfa8), width=2)
    d.point((9, b - 7), fill=fx('glow'))
    d.point((14, b - 7), fill=fx('glow'))
    d.line((8, b - 3, 16, b - 3), fill=rgb(0x0a0508))
    for k in (6, 10, 14, 18):
        d.line((k, b - 1, k + (1 if t else -1), b + 1), fill=rgb(0x4a0810))
    return img


def bone_stake(broken):
    img = Image.new('RGBA', (16, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if broken:
        d.polygon([(3, 31), (13, 31), (12, 22), (9, 25), (7, 21), (4, 24)], fill=rgb(0xb8987a))
        d.line((5, 30, 6, 23), fill=rgb(0xe6cfa8))
        d.point((8, 26), fill=rgb(0xd01420))
        d.ellipse((1, 29, 15, 32), fill=rgb(0x4a0810))
        return img
    d.polygon([(4, 31), (12, 31), (10, 4), (8, 0), (6, 4)], fill=rgb(0xb8987a))
    d.polygon([(5, 31), (9, 31), (8, 2), (7, 4)], fill=rgb(0xe6cfa8))
    for y in (10, 18, 25):
        d.line((5, y, 11, y), fill=rgb(0x7a5c4c))
    d.line((9, 7, 10, 14), fill=rgb(0xd01420))
    d.ellipse((2, 29, 14, 32), fill=rgb(0x4a0810))
    return img


SEQ = [('idle', idle, 4), ('move', move, 6), ('slam', slam, 6), ('charge', charge, 6), ('barrage', barrage, 5),
       ('pulse', pulse, 6), ('summon', summon, 5), ('stun', stun, 4), ('guard', guard, 4), ('death', death, 7)]


def chunk(img):
    """Halves a frame: each 2x2 block becomes one cell of its most common colour (if at least half is drawn),
    so his frames and their effects keep the game's chunky grid."""
    w, h = img.size
    px = img.load()
    out = Image.new('RGBA', (w // 2, h // 2), (0, 0, 0, 0))
    op = out.load()
    for y in range(h // 2):
        for x in range(w // 2):
            seen = {}
            for dy in (0, 1):
                for dx in (0, 1):
                    p = px[x * 2 + dx, y * 2 + dy]
                    if p[3] >= 128:
                        k = nearest(p)
                        seen[k] = seen.get(k, 0) + 1
            if sum(seen.values()) >= 2:
                k = max(seen, key=lambda c: seen[c])
                op[x, y] = k + (255,)
    return out


def rows(img):
    img = chunk(img)
    px = img.load()
    out = []
    for y in range(img.size[1]):
        r = []
        for x in range(img.size[0]):
            p = px[x, y]
            r.append('.' if p[3] < 128 else COLOURS[nearest(p)])
        out.append(''.join(r))
    return out


_near = {}


def nearest(p):
    """Every colour drawn is one of the palette's (effects are drawn in them; this only guards the edges)."""
    k = p[:3]
    if k in COLOURS:
        return k
    if k not in _near:
        _near[k] = min(COLOURS, key=lambda c: sum((a - b) ** 2 for a, b in zip(c, k)))
    return _near[k]


def pal(rage=False):
    out = {}
    for c, letter in COLOURS.items():
        v = (c[0] << 16) | (c[1] << 8) | c[2]
        out[letter] = RAGE.get(v, v) if rage else v
    return out


def sequences():
    p, rp = pal(), pal(True)
    out = []
    for name, fn, n in SEQ:
        out.append(('gorehorn_' + name, [rows(fn(t)) for t in range(n)], p, SCALE))
    out.append(('gorehorn_ridle', [rows(idle(t)) for t in range(4)], rp, SCALE))
    out.append(('gorehorn_rmove', [rows(move(t)) for t in range(6)], rp, SCALE))
    out.append(('gorehorn', [rows(f) for f in (idle(0), idle(2), move(1), move(4), slam(3), charge(4))], p, SCALE))
    out.append(('gore_spawn', [rows(gore_spawn(t)) for t in range(2)], p, SCALE))
    out.append(('bone_stake', [rows(bone_stake(False)), rows(bone_stake(False))], p, SCALE))
    out.append(('bone_stake_broken', [rows(bone_stake(True)), rows(bone_stake(True))], p, SCALE))
    return out


def recolors():
    """His attacks in his rage colours: the same frames, the ember palette."""
    rp = pal(True)
    return [('gorehorn_' + name + '_r', 'gorehorn_' + name, rp) for name, fn, n in SEQ]


if __name__ == '__main__':
    seqs = sequences()
    frames = [(n, f, p) for n, fr, p, s in seqs for f in fr]
    cols = 6
    cw, ch = CW * 2 + 8, CH * 2 + 20
    sheet = Image.new('RGB', (cols * cw, ((len(frames) + cols - 1) // cols) * ch), (34, 30, 40))
    d = ImageDraw.Draw(sheet)
    for i, (n, f, p) in enumerate(frames):
        h, w = len(f), len(f[0])
        im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        px = im.load()
        for y, row in enumerate(f):
            for x, c in enumerate(row):
                if c != '.':
                    px[x, y] = rgb(p[c])
        im = im.resize((w * 2, h * 2), Image.NEAREST)
        x, y = (i % cols) * cw, (i // cols) * ch
        sheet.paste(im, (x + 4, y + 16), im)
        d.text((x + 4, y + 2), n, fill=(230, 220, 220))
    sheet.save(sys.argv[1] if len(sys.argv) > 1 else 'gorehorn.png')
