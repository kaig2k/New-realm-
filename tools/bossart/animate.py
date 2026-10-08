"""
Turns a boss's two idle drawings into its full animation: two idle frames, two
moving frames (leaning into a stride) and two attack frames (a crouched
wind-up wrapped in an aura of the boss's own colour, then a stretched strike
that flashes bright and throws rays). A design can draw its own poses instead
by taking a second argument (pose: 'idle', 'move' or 'attack').
"""
import colorsys, inspect

SPARE = '0123456789!#$%&*+-:;<=>?@^_~'


def accent(pal):
    """The boss's signature colour: its most vivid bright tone."""
    def score(c):
        r, g, b = ((c >> 16) & 255) / 255, ((c >> 8) & 255) / 255, (c & 255) / 255
        h, s, v = colorsys.rgb_to_hsv(r, g, b)
        return s * v + v * 0.3
    return max(pal.values(), key=score)


def brighten(c, t=0.3):
    r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    return (int(r + (255 - r) * t) << 16) | (int(g + (255 - g) * t) << 8) | int(b + (255 - b) * t)


def lean(rows, dx):
    h = len(rows)
    out = []
    for y, r in enumerate(rows):
        k = dx * (2 if y < h * 0.3 else 1 if y < h * 0.6 else 0)
        if k > 0:
            r = '.' * k + r[:-k]
        elif k < 0:
            r = r[-k:] + '.' * (-k)
        out.append(r)
    return out


def lift(rows, n=1):
    if all(ch == '.' for r in rows[:n] for ch in r):
        return rows[n:] + ['.' * len(rows[0])] * n
    return rows


def squash(rows):
    h = len(rows)
    m = int(h * 0.62)
    return ['.' * len(rows[0])] + rows[:m] + rows[m + 1:]


def stretch(rows):
    h = len(rows)
    m = int(h * 0.45)
    if not all(ch == '.' for ch in rows[0]):
        return rows
    return rows[1:m + 1] + [rows[m]] + rows[m + 1:]


def aura(rows, ch, t):
    """Pixels just outside the body, in a flickering checker."""
    h, w = len(rows), len(rows[0])
    g = [list(r) for r in rows]
    for y in range(h):
        for x in range(w):
            if rows[y][x] != '.':
                continue
            near = any(0 <= y + dy < h and 0 <= x + dx < w and rows[y + dy][x + dx] != '.'
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)))
            if near:
                g[y][x] = ch
    return [''.join(r) for r in g]


def rays(rows, ch):
    """Short strokes thrown out from the body's centre to the edges."""
    h, w = len(rows), len(rows[0])
    g = [list(r) for r in rows]
    cx, cy = w / 2, h / 2
    for k in range(8):
        import math
        a = k * math.pi / 4 + math.pi / 8
        for r in range(int(min(w, h) * 0.42), int(min(w, h) * 0.5)):
            x, y = int(cx + math.cos(a) * r), int(cy + math.sin(a) * r)
            if 0 <= x < w and 0 <= y < h and g[y][x] == '.':
                g[y][x] = ch
    return [''.join(r) for r in g]


def frames(fn, pal):
    """[idle0, idle1, move0, move1, attack0, attack1] and the palette (with the flash colours added)."""
    pal = dict(pal)
    if len(inspect.signature(fn).parameters) >= 2:
        return [fn(t, p).rows() for p in ('idle', 'move', 'attack') for t in (0, 1)], pal
    i0, i1 = fn(0).rows(), fn(1).rows()
    free = [c for c in SPARE if c not in pal]
    glow = free.pop(0)
    pal[glow] = brighten(accent(pal), 0.25)
    # the strike: every colour flashes brighter (each letter gets a bright twin)
    flash = {}
    for k in list(pal.keys()):
        if k == glow or not free:
            continue
        flash[k] = free.pop(0)
        pal[flash[k]] = brighten(pal[k], 0.16)
    strike = [''.join(flash.get(ch, ch) for ch in r) for r in stretch(i0)]
    return [
        i0, i1,
        lean(i0, 1), lift(lean(i1, -1)),
        aura(squash(i0), glow, 0),
        rays(aura(strike, glow, 1), glow),
    ], pal
