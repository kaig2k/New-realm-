"""
Body plans for shaded bosses (on sdfart.py): a robed caster, an armoured figure, wings,
a staff, a crown, a flame. Each adds solids to a Model; a boss is a body plan plus its own
details. Also designs(), which turns a list of models into designs.py-style entries.
"""
import math
from sdfart import folds, rough

LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'


def g(ramp, **k):
    d = {'ramp': list(ramp)}
    d.update(k)
    return d


def glow(*c, base=0.2):
    return {'ramp': list(c), 'glow': True, 'glow0': base}


# ---------------------------------------------------------------- body plans
def robe(m, cx, top, hem, w0, w1, mat, trim=None, tatter=True, seed=3):
    """A robe or gown from the shoulders (y=top, half-width w0) to the floor (y=hem, half-width w1)."""
    F = folds(0.14, 3.0, seed)
    m.capsule((cx, top, 0), (cx, hem - 2, 0), w0, w1, mat, F)
    m.sphere((cx, hem - 1, 0), w1, mat, 1.0, 0.28, 1.0, F)
    if tatter:
        n = int(w1 * 2 / 4) + 1
        for k in range(n):
            x = cx - w1 + 2 + k * (w1 * 2 - 4) / max(1, n - 1)
            m.capsule((x, hem - 1, w1 * 0.3), (x, hem + 2 - (k % 2) * 2, w1 * 0.3), 1.6, 0.5, mat)
    if trim:
        m.capsule((cx, top + 2, w0 + 0.5), (cx, hem - 1, w1 + 0.5), 0.8, 1.1, trim)


def torso(m, cx, top, bottom, w, mat, tex=None):
    m.capsule((cx, top, 1), (cx, bottom, 1), w, w * 0.8, mat, tex or rough(0.06))


def arm(m, sh, el, hand, r, mat, hand_mat=None, hand_r=None):
    m.capsule(sh, el, r, r * 0.85, mat)
    m.capsule(el, hand, r * 0.85, r * 0.7, mat)
    if hand_mat:
        m.sphere((hand[0], hand[1], hand[2] + 0.5), hand_r or r * 0.8, hand_mat)


def legs(m, cx, top, bottom, gap, r, mat, foot=True):
    for s in (-1, 1):
        m.capsule((cx + s * gap, top, 0), (cx + s * (gap + 0.6), bottom - 2, 1), r, r * 0.8, mat)
        if foot:
            m.sphere((cx + s * (gap + 0.8), bottom - 1, 2), r * 0.95, mat, 1.25, 0.55, 1.1)


def head(m, cx, cy, r, mat, z=4):
    m.sphere((cx, cy, z), r, mat, 0.92, 1.05, 1.0)


def eyes(m, cx, cy, gap, z, mat, r=0.65):
    # (a little proud of the face, so the head's own curve never swallows them; never smaller than a pixel)
    r = max(r, 0.72)
    m.sphere((cx - gap, cy, z + 1.8), r, mat)
    m.sphere((cx + gap, cy, z + 1.8), r, mat)


def hood(m, cx, cy, r, mat, void):
    m.sphere((cx, cy, 1), r, mat, 1.0, 1.05, 1.0, folds(0.1, 3, 9))
    m.sphere((cx, cy + 1.5, r * 0.55), r * 0.62, void, 0.95, 1.1, 0.6)


def crown(m, cx, y, w, mat, spikes=5, tall=3.5, z=6, gem=None):
    m.capsule((cx - w, y, z), (cx + w, y, z), 1.1, 1.1, mat)
    for k in range(spikes):
        x = cx - w + k * (2 * w) / max(1, spikes - 1)
        mid = 1 - abs(k - (spikes - 1) / 2) / max(1, (spikes - 1) / 2)
        m.capsule((x, y - 0.5, z + 0.3), (x, y - tall * (0.6 + 0.4 * mid), z + 0.3), 0.8, 0.25, mat)
    if gem:
        m.sphere((cx, y - 0.6, z + 1.4), 0.9, gem)


def staff(m, x, top, bottom, mat, z=6, r=0.9):
    m.capsule((x, top, z), (x, bottom, z), r, r, mat)


def wing(m, root, tip_dir, span, mat, bone, z, feathers=True, n=5, droop=0.5, side=1):
    """A wing from root, spreading toward tip_dir (dx, dy normalised), span long."""
    dx, dy = tip_dir
    tip = (root[0] + dx * span, root[1] + dy * span)
    m.capsule((root[0], root[1], z + 0.5), (tip[0], tip[1], z + 0.5), 1.6, 0.6, bone)
    pts = [root, tip]
    for k in range(n):
        t = 1 - k / n
        bx, by = root[0] + dx * span * t, root[1] + dy * span * t
        ln = span * (0.55 + 0.35 * t) * droop + 3
        fx, fy = bx + (-dy * side * 0.25) * ln * 0.3, by + ln
        if feathers:
            m.capsule((bx, by, z - 0.2 * k), (fx, fy, z - 0.2 * k), 2.4 - k * 0.15, 0.7, mat)
        pts.append((fx, fy))
    pts.append((root[0], root[1] + 4))
    return pts


def flame(m, cx, base, h, w, mats, z=6, t=0):
    """Tongues of fire rising from base: mats = (outer, inner)."""
    outer, inner = mats
    for k in range(5):
        a = (k - 2) / 2
        x = cx + a * w * 0.6
        top = base - h * (1 - abs(a) * 0.45) - (t if k % 2 else -t) * 0.6
        m.capsule((x, base, z), (x + a * 1.5, top, z), w * 0.42 * (1 - abs(a) * 0.3), 0.3, outer)
    m.capsule((cx, base, z + 1.5), (cx, base - h * 0.6, z + 1.5), w * 0.32, 0.3, inner)


# ---------------------------------------------------------------- to designs
def designs(models, scale=3):
    """models: [(name, fn(t) -> (Model, mats))] -> [(name, frame_fn, palette, scale)]."""
    from PIL import Image
    out = []
    for name, fn in models:
        rows_t, rev, pal = [], {}, {}
        for t in (0, 1):
            m, mats = fn(t)
            img = m.render(mats)
            im = Image.new('RGBA', (img.width + 4, img.height + 4), (0, 0, 0, 0))
            im.alpha_composite(img, (2, 2))
            px = im.load()
            rows = []
            for y in range(im.height):
                r = []
                for x in range(im.width):
                    p = px[x, y]
                    if p[3] < 128:
                        r.append('.')
                        continue
                    v = (p[0] << 16) | (p[1] << 8) | p[2]
                    if v not in rev:
                        assert len(rev) < len(LETTERS), name + ': too many colours'
                        rev[v] = LETTERS[len(rev)]
                        pal[rev[v]] = v
                    r.append(rev[v])
                rows.append(''.join(r))
            rows_t.append(rows)
        out.append((name, _framer(rows_t), pal, scale))
    return out


class _Pic:
    def __init__(self, rows):
        self.r = rows

    def rows(self):
        return list(self.r)


def _framer(rows_t):
    # (one argument only: animate.py passes a pose to drawings that take two)
    def frame(t):
        return _Pic(rows_t[t % 2])
    return frame


def sheet(models, path, sc=5):
    from PIL import Image
    ims = []
    for name, fn in models:
        m, mats = fn(0)
        ims.append(m.render(mats))
    W = sum(i.width * sc + 16 for i in ims) + 16
    H = max(i.height * sc for i in ims) + 32
    s = Image.new('RGBA', (W, H), (150, 146, 142, 255))
    x = 16
    for im in ims:
        z = im.resize((im.width * sc, im.height * sc), Image.NEAREST)
        s.alpha_composite(z, (x, H - z.height - 16))
        x += z.width + 16
    s.convert('RGB').save(path)


# ---------------------------------------------------------------- hard-edged pieces (armour, rock, ice)
def chest(m, cx, top, bottom, wtop, wbot, z, mat, bevel=3.0, tex=None):
    """A breastplate or a slab of a chest: broad at the shoulders, narrower at the waist, chiselled edges."""
    m.slab([(cx - wtop, top + 2), (cx - wtop + 2, top), (cx + wtop - 2, top), (cx + wtop, top + 2),
            (cx + wbot, bottom), (cx, bottom + 1.5), (cx - wbot, bottom)], z, bevel, mat, tex)


def plate(m, a, b, wa, wb, z, mat, bevel=1.6, tex=None):
    """An armoured limb: a straight-sided plate from a (half-width wa) to b (half-width wb)."""
    import math as _m
    dx, dy = b[0] - a[0], b[1] - a[1]
    l = _m.hypot(dx, dy) or 1
    px, py = -dy / l, dx / l
    m.slab([(a[0] + px * wa, a[1] + py * wa), (b[0] + px * wb, b[1] + py * wb),
            (b[0] - px * wb, b[1] - py * wb), (a[0] - px * wa, a[1] - py * wa)], z, bevel, mat, tex)


def pauldron(m, cx, cy, w, h, z, mat, side, bevel=2.0, tex=None):
    """A shoulder guard: an angular shell sloping down and out."""
    m.slab([(cx - w * 0.6 * side, cy - h * 0.5), (cx + w * 0.5 * side, cy - h * 0.6), (cx + w * side, cy + h * 0.2),
            (cx + w * 0.8 * side, cy + h * 0.6), (cx - w * 0.6 * side, cy + h * 0.5)], z, bevel, mat, tex)


def rock(m, cx, cy, r, z, mat, seed=1, sides=7, bevel=None, squash=1.0, tex=None):
    """A jagged chunk of rock or ice: an irregular polygon with chiselled faces."""
    import math as _m
    from sdfart import hash2
    pts = []
    for k in range(sides):
        a = k * _m.pi * 2 / sides + hash2(k, seed) * 0.5
        rr = r * (0.78 + 0.3 * hash2(seed, k))
        pts.append((cx + _m.cos(a) * rr, cy + _m.sin(a) * rr * squash))
    m.slab(pts, z, bevel or r * 0.45, mat, tex, height=r * 0.6)


def spike(m, base, tip, w, z, mat, bevel=1.0):
    """A hard triangular spike or horn."""
    import math as _m
    dx, dy = tip[0] - base[0], tip[1] - base[1]
    l = _m.hypot(dx, dy) or 1
    px, py = -dy / l * w, dx / l * w
    m.slab([(base[0] + px, base[1] + py), tip, (base[0] - px, base[1] - py)], z, bevel, mat)
