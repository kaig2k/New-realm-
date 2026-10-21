"""
Sylith the Frost Wyrm, after the user's own art and design sheet (ref/sylith.webp,
ref/sylith_sheet.webp), drawn on the game's grid by sylith_game.py. Her animations
move that picture (a breath, a prowl, rearing back, rising into the air) and lay her
sheet's effects over and around it: the ice breath, the frost spike spread, the ice
lance, the tail swipe, the ice storm, the ice wolves she calls, her dive and her
death. Past her rage her scales darken to midnight and her eye burns white.

Also her minions, the ice wolves.

    python3 tools/bossart/sylith.py out.png   draws a contact sheet of every frame
"""
import math
import sys
from PIL import Image, ImageDraw
import sylith_game

CW, CH = 120, 100          # the canvas (2 pixels a cell): her picture plus room round her
OX, OY = 16, 14            # where the picture sits in it
SCALE = 4                  # every frame is drawn at 2 canvas pixels a cell, then halved (chunk)

LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
ART = list(sylith_game.PAL.values())
FX = {'frost': 0x9ad8ff, 'white': 0xffffff, 'deep': 0x3a7ce0, 'glow': 0xd8f4ff, 'shadow': 0x0e1838,
      'wolf': 0xa8c8f0, 'wolfd': 0x5a78b8, 'wolfe': 0x40e8ff}
# rage: her scales darken to midnight, her wings and eye blaze
RAGE = {0x2446b0: 0x2a1c8a, 0x4880e4: 0x5a48d8, 0x0b1140: 0x0c0630, 0x9ff4ff: 0xffffff,
        0x62aef8: 0x8ad0ff, 0x6cb8ff: 0x8ad0ff, 0x3a7ce0: 0x4a64e8}


def rgb(v):
    return ((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)


COLOURS = {}
for i, v in enumerate(ART + list(FX.values())):
    COLOURS.setdefault(rgb(v)[:3], LETTERS[i])


def fx(name):
    return rgb(FX[name])


_pic = None


def pic():
    """Her drawing, each cell 2x2 canvas pixels."""
    global _pic
    if _pic is None:
        c = sylith_game.design()
        im = Image.new('RGBA', (sylith_game.W, sylith_game.H), (0, 0, 0, 0))
        px = im.load()
        for y, row in enumerate(c.rows()):
            for x, ch in enumerate(row):
                if ch != '.':
                    px[x, y] = rgb(sylith_game.PAL[ch])
        _pic = im.resize((im.width * 2, im.height * 2), Image.NEAREST)
    return _pic


PW, PH = sylith_game.W * 2, sylith_game.H * 2
MOUTH = (86, 22)           # the tip of her snout (picture pixels)
EYE = (75, 19)
TAIL = (4, 72)             # the tip of her tail
FEET = OY + 77             # where her claws meet the ground, on the canvas


def her(dy=0, lean=0.0, sway=0.0, t=0.0, squash=0):
    """Her picture on the canvas: dy lifts her, lean tips her top forward (+, toward her snout) or back,
    sway ripples her wings, squash crouches her."""
    p = pic()
    canvas = Image.new('RGBA', (CW, CH), (0, 0, 0, 0))
    for y in range(PH):
        row = p.crop((0, y, PW, y + 1))
        up = (PH - y) / PH
        dx = lean * up + (sway * math.sin(t + y * 0.12) if y < 52 else 0)
        yy = y
        if squash and y < PH - 10:
            yy = y + int(squash * (1 - y / (PH - 10)))
        canvas.alpha_composite(row, (OX + int(round(dx)), OY + yy - dy))
    return canvas


def at(p, dy=0, lean=0.0):
    return (OX + p[0] + int(lean * (PH - p[1]) / PH), OY + p[1] - dy)


def layer():
    return Image.new('RGBA', (CW, CH), (0, 0, 0, 0))


def under(img, base):
    img.alpha_composite(base)
    return img


# ------------------------------------------------------------------ effects
def ring(d, cx, cy, rx, ry, col, width=1):
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), outline=col, width=width)


def shard(d, x, y, a, ln=7, col='frost'):
    """A flying ice shard pointing along a."""
    x2, y2 = x + math.cos(a) * ln, y + math.sin(a) * ln
    d.line((x, y, x2, y2), fill=fx(col), width=2)
    d.point((x2, y2), fill=fx('white'))


def flake(d, x, y, s=2, col='white'):
    d.line((x - s, y, x + s, y), fill=fx(col))
    d.line((x, y - s, x, y + s), fill=fx(col))
    if s > 1:
        d.point((x - 1, y - 1), fill=fx('frost'))
        d.point((x + 1, y + 1), fill=fx('frost'))


def mist(d, cx, cy, t, n=6, spread=12):
    for k in range(n):
        a = k * 2.399 + t * 0.8
        r = spread * (0.4 + ((k * 37 + t * 11) % 10) / 16)
        x, y = cx + math.cos(a) * r, cy + math.sin(a) * r * 0.4
        s = 1 + (k + t) % 2
        d.ellipse((x - s, y - s, x + s, y + s), fill=fx('glow' if k % 2 else 'frost'))


def shadow(d, w=34):
    d.ellipse((CW // 2 - w, FEET - 3, CW // 2 + w, FEET + 3), fill=fx('shadow'))


def wolf(d, x, base_y, h):
    """An ice wolf forming out of the frost (h: how far it has risen)."""
    if h <= 0:
        return
    top = base_y - max(h, 7)
    d.ellipse((x - 7, top + 2, x + 6, base_y - 2), fill=fx('wolfd'))
    d.ellipse((x - 6, top + 2, x + 4, base_y - 4), fill=fx('wolf'))
    d.polygon([(x + 3, top), (x + 8, top + 2), (x + 9, top + 5), (x + 4, top + 6)], fill=fx('wolf'))
    d.point((x + 6, top + 3), fill=fx('wolfe'))
    d.line((x + 3, top - 2, x + 4, top + 1), fill=fx('white'))


# ------------------------------------------------------------------ her animations
def idle(t):
    dy = [0, 1, 1, 0][t]
    img = her(dy, sway=0.8, t=t * 1.5)
    if t in (1, 2):
        d = ImageDraw.Draw(img)
        mx, my = at(MOUTH, dy)
        d.point((mx + 2, my - 1 - t), fill=fx('glow'))
        d.point((mx + 4, my - 2 - t), fill=fx('frost'))
    return img


def move(t):
    dy = [0, 2, 3, 1, 0, 2][t]
    base = her(dy, lean=[1, 2, 1, -1, -2, -1][t], sway=1.5, t=t * 1.1)
    img = layer()
    d = ImageDraw.Draw(img)
    shadow(d)
    mist(d, CW // 2, FEET, t, n=4, spread=24)
    return under(img, base)


def breath(t):
    """Ice Breath: she rears back, frost gathering in her jaws, then pours out a cone of freezing breath."""
    dy = [0, 2, 4, 1, 1, 0][t]
    lean = [0, -3, -5, 4, 4, 2][t]
    img = her(dy, lean=lean)
    d = ImageDraw.Draw(img)
    mx, my = at(MOUTH, dy, lean)
    if t in (1, 2):
        ring(d, mx, my, 2 + t * 2, 2 + t * 2, fx('frost'))
        d.point((mx, my), fill=fx('white'))
    if t >= 3:
        reach = [0, 0, 0, 22, 30, 26][t]
        for k in range(14):
            f = (k * 37 % 100) / 100
            a = (f - 0.5) * 0.7
            r = 3 + ((k * 13 + t * 7) % reach)
            x, y = mx + math.cos(a) * r, my + math.sin(a) * r
            flake(d, x, y, 1 + (k % 2), 'white' if k % 3 == 0 else 'frost')
        d.line((mx, my, mx + reach, my - 2), fill=fx('glow'), width=2)
    return img


def spikes(t):
    """Frost Spikes: she hunches, shards bristle along her crest, then fly out in a wide spread."""
    dy = [0, -1, -2, 1, 0][t]
    img = her(dy, squash=[0, 2, 3, 0, 0][t])
    d = ImageDraw.Draw(img)
    mx, my = at(MOUTH, dy)
    if t in (1, 2):
        for k in range(5):
            x, y = OX + 40 + k * 8, OY + 6 - dy - (k % 2) * 3
            d.line((x, y, x - 2, y - 4 - t * 2), fill=fx('white'))
    if t >= 3:
        for k in range(6):
            a = (k / 5 - 0.5) * 1.3
            r = 8 + (t - 3) * 12
            shard(d, mx + math.cos(a) * r, my + math.sin(a) * r, a, 7)
    return img


def lance(t):
    """Ice Lance: frost spirals to a point in her jaws, then a lance of ice streaks out in a line."""
    dy = [0, 1, 2, 0, 0][t]
    lean = [0, -2, -3, 3, 1][t]
    img = her(dy, lean=lean)
    d = ImageDraw.Draw(img)
    mx, my = at(MOUTH, dy, lean)
    if t in (1, 2):
        for k in range(6):
            a = k * math.pi / 3 + t
            r = 8 - t * 2
            d.point((mx + 3 + math.cos(a) * r, my + math.sin(a) * r), fill=fx('glow'))
        d.ellipse((mx + 1, my - 2, mx + 5, my + 2), fill=fx('white'))
    if t >= 3:
        ln = [0, 0, 0, 30, 34][t]
        d.line((mx, my, min(CW - 1, mx + ln), my), fill=fx('frost'), width=3)
        d.line((mx, my, min(CW - 1, mx + ln), my), fill=fx('white'), width=1)
        for k in range(4):
            flake(d, mx + 6 + k * 7, my + (2 if k % 2 else -3), 1, 'glow')
    return img


def tail(t):
    """Tail Swipe: she coils, then lashes her spiked tail round in a frosty arc."""
    dy = [0, 1, 0, 0, 0][t]
    img = her(dy, lean=[0, 2, 3, -3, -1][t], squash=[0, 1, 2, 0, 0][t])
    d = ImageDraw.Draw(img)
    tx, ty = at(TAIL, dy)
    if t >= 2:
        r = [0, 0, 18, 26, 30][t]
        d.arc((CW // 2 - r - 10, FEET - 14 - r // 3, CW // 2 + r - 10, FEET + 4 + r // 4), 120, 260, fill=fx('frost'), width=2)
        d.arc((CW // 2 - r - 12, FEET - 12 - r // 3, CW // 2 + r - 12, FEET + 2 + r // 4), 130, 250, fill=fx('white'), width=1)
        for k in range(3):
            flake(d, tx - 2 - k * 6, ty + 4 - k * 5, 1)
    return img


def storm(t):
    """Ice Storm: she spreads her wings and a blizzard whirls round her, snow driving in a ring."""
    dy = [0, 2, 3, 3, 2, 0][t]
    img = layer()
    d = ImageDraw.Draw(img)
    cx, cy = CW // 2, FEET - 4
    r = 26 + t * 4
    ring(d, cx, cy, r, r * 0.3, fx('frost'))
    base = her(dy, sway=2.2, t=t * 1.6)
    img = under(img, base)
    d = ImageDraw.Draw(img)
    for k in range(16):
        a = k * math.pi * 2 / 16 + t * 0.5
        rr = 14 + (k * 7 + t * 5) % 40
        flake(d, cx + math.cos(a) * rr, cy - 18 + math.sin(a) * rr * 0.6, 1 + (k % 3 == 0), 'white' if k % 2 else 'glow')
    return img


def summon(t):
    """Summon: she roars, frost spreading over the ground, and ice wolves rise at her sides."""
    dy = [0, -2, -3, -2, 0][t]
    lean = [0, -2, -3, -2, 0][t]
    base = her(dy, lean=lean)
    img = layer()
    d = ImageDraw.Draw(img)
    for x in (12, CW - 14):
        ring(d, x, FEET, 9, 3, fx('frost'))
        wolf(d, x, FEET, [0, 0, 5, 9, 11][t])
    img = under(img, base)
    if t in (1, 2, 3):
        d = ImageDraw.Draw(img)
        mx, my = at(MOUTH, dy, lean)
        for k in range(4):
            ln = 4 + t * 3
            d.line((mx + 2 + k * 2, my - 6 + k * 4, mx + 2 + k * 2 + ln, my - 8 + k * 5), fill=fx('glow') if k % 2 else fx('frost'))
    return img


def fly(t):
    """Dive: she beats her wings and rises, her shadow on the ground beneath, then crashes down in a burst of ice."""
    dy = [2, 8, 14, 18, 2, -1][t]
    base = her(dy, sway=3 * (t < 4), t=t * 2.2)
    img = layer()
    d = ImageDraw.Draw(img)
    shadow(d, 34 - min(dy, 16))
    if t == 4 or t == 5:
        ring(d, CW // 2, FEET - 2, 40 + t * 3, 9, fx('frost'), 2)
        for k in range(10):
            a = k * math.pi * 2 / 10
            shard(d, CW // 2 + math.cos(a) * 36, FEET - 2 + math.sin(a) * 8, a - math.pi / 2 * 0.3, 6)
        mist(d, CW // 2, FEET, t, n=8, spread=34)
    return under(img, base)


def guard(t):
    """Roar: a new phase. She rears up, wings wide, frost blazing in a ring round her."""
    dy = [0, 4, 6, 4][t]
    img = her(dy, lean=[0, -3, -4, -3][t], sway=1.5, t=t)
    d = ImageDraw.Draw(img)
    ring(d, CW // 2, FEET - 28, 46 + t * 2, 34 + t * 2, fx('frost'))
    ring(d, CW // 2, FEET - 28, 42 + t * 2, 30 + t * 2, fx('deep'))
    mx, my = at(MOUTH, dy, -4)
    for k in range(5):
        d.line((mx + 3 + k * 2, my - 6 + k * 3, mx + 10 + k * 3 + t * 2, my - 8 + k * 4), fill=fx('glow') if k % 2 else fx('white'))
    return img


def death(t):
    """She shatters: cracks of light run through her, she sinks, and bursts into a storm of ice shards."""
    keep = [1.0, 1.0, 0.85, 0.6, 0.35, 0.15, 0.0][t]
    base = her(-[0, 2, 4, 6, 8, 9, 9][t], lean=[0, 2, 3, 4, 4, 4, 4][t])
    px = base.load()
    for y in range(CH):
        for x in range(CW):
            if px[x, y][3] == 0:
                continue
            hv = (x * 73856093 ^ y * 19349663 ^ 7 * 83492791) & 0xffff
            if hv / 65536 >= keep:
                px[x, y] = fx('white') if hv % 7 == 0 else (0, 0, 0, 0)
    img = layer()
    d = ImageDraw.Draw(img)
    if t >= 3:
        for k in range(12):
            a = k * math.pi * 2 / 12 + 0.2
            r = 12 + (t - 3) * 12
            shard(d, CW // 2 + math.cos(a) * r, FEET - 24 + math.sin(a) * r * 0.6, a, 6, 'frost' if k % 2 else 'white')
        ring(d, CW // 2, FEET, 30, 4, fx('frost'))
    return under(img, base)


# ------------------------------------------------------------------ her ice wolves
def ice_wolf(t):
    img = Image.new('RGBA', (28, 22), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    b = 19 - (t % 2)
    # body, head (facing right), ears, tail and legs
    d.ellipse((3, b - 10, 20, b - 3), fill=fx('wolfd'))
    d.ellipse((4, b - 10, 18, b - 5), fill=fx('wolf'))
    d.polygon([(16, b - 12), (23, b - 10), (26, b - 7), (22, b - 5), (16, b - 6)], fill=fx('wolf'))
    d.line((18, b - 13, 19, b - 11), fill=fx('white'))
    d.line((20, b - 13, 21, b - 11), fill=fx('white'))
    d.point((22, b - 9), fill=fx('wolfe'))
    d.line((3, b - 8, 0, b - 11 - (t % 2)), fill=fx('wolf'), width=2)
    for k, x in enumerate((6, 9, 14, 17)):
        d.line((x, b - 4, x + (1 if (k + t) % 2 else -1), b), fill=fx('wolfd'), width=2)
    for x in (7, 11, 15):
        d.point((x, b - 9), fill=fx('white'))
    return img


# ------------------------------------------------------------------ to the game's letters
SEQ = [('idle', idle, 4), ('move', move, 6), ('breath', breath, 6), ('spikes', spikes, 5), ('lance', lance, 5),
       ('tail', tail, 5), ('storm', storm, 6), ('summon', summon, 5), ('fly', fly, 6), ('guard', guard, 4), ('death', death, 7)]

_near = {}


def nearest(p):
    k = p[:3]
    if k in COLOURS:
        return k
    if k not in _near:
        _near[k] = min(COLOURS, key=lambda c: sum((a - b) ** 2 for a, b in zip(c, k)))
    return _near[k]


def chunk(img):
    """Halves a frame: each 2x2 block becomes one cell of its most common colour (if at least half is drawn),
    so her frames and their effects keep the game's chunky grid."""
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
                op[x, y] = max(seen, key=lambda c: seen[c]) + (255,)
    return out


def rows(img):
    img = chunk(img)
    px = img.load()
    out = []
    for y in range(img.size[1]):
        out.append(''.join('.' if px[x, y][3] < 128 else COLOURS[nearest(px[x, y])] for x in range(img.size[0])))
    return out


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
        out.append(('sylith_' + name, [rows(fn(t)) for t in range(n)], p, SCALE))
    out.append(('sylith_ridle', [rows(idle(t)) for t in range(4)], rp, SCALE))
    out.append(('sylith_rmove', [rows(move(t)) for t in range(6)], rp, SCALE))
    out.append(('sylith', [rows(f) for f in (idle(0), idle(2), move(1), move(4), breath(4), spikes(4))], p, SCALE))
    out.append(('ice_wolf', [rows(ice_wolf(t)) for t in range(2)], p, SCALE))
    return out


def recolors():
    """Her attacks in her rage colours: the same frames, the midnight palette."""
    rp = pal(True)
    return [('sylith_' + name + '_r', 'sylith_' + name, rp) for name, fn, n in SEQ]


if __name__ == '__main__':
    seqs = sequences()
    frames = [(n, f, p) for n, fr, p, s in seqs for f in fr]
    cols = 6
    cw, ch = CW * 2 + 8, CH * 2 + 20
    sheet = Image.new('RGB', (cols * cw, ((len(frames) + cols - 1) // cols) * ch), (24, 30, 44))
    d = ImageDraw.Draw(sheet)
    for i, (n, f, p) in enumerate(frames):
        h, w = len(f), len(f[0])
        im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        px = im.load()
        for y, row in enumerate(f):
            for x, c in enumerate(row):
                if c != '.':
                    px[x, y] = rgb(p[c])
        im = im.resize((w * 4, h * 4), Image.NEAREST)
        x, y = (i % cols) * cw, (i // cols) * ch
        sheet.paste(im, (x + 4, y + 16), im)
        d.text((x + 4, y + 2), n, fill=(230, 230, 240))
    sheet.save(sys.argv[1] if len(sys.argv) > 1 else 'sylith.png')
