"""
A tiny 3D-to-pixel-art kit for Eldmere's bosses.

A boss is modelled as a set of solid shapes (spheres, capsules that taper, and flat
membranes for wings and capes), each with a material. Every pixel finds the nearest
surface toward the viewer, takes its normal, and is lit from the top-left (a key
light, a cool rim light from behind, ambient occlusion from nearby shapes, and the
material's own texture: scales, fur, cloth folds). The light is then snapped onto
the material's few hand-picked tones with a little ordered dithering where tones
meet, so the result is shaded pixel art with real volume. An outline and glow
(emissive) materials finish it.

    m = Model(64, 64)
    m.sphere((32, 30, 0), 12, 'hide')
    m.capsule((20, 40, 0), (14, 60, 4), 5, 3, 'hide')
    img = m.render(MATERIALS)
"""
import math
from PIL import Image

BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
LIGHT = (-0.55, -0.62, 0.56)        # from the top-left, toward the viewer
RIM = (0.7, 0.1, -0.7)              # from behind and to the right


def norm(v):
    l = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) or 1
    return (v[0] / l, v[1] / l, v[2] / l)


L = norm(LIGHT)
R_ = norm(RIM)


def hash2(x, y, s=0):
    h = (int(x) * 374761393 + int(y) * 668265263 + s * 2147483647) & 0xffffffff
    h = (h ^ (h >> 13)) * 1274126177 & 0xffffffff
    return (h ^ (h >> 16)) / 0xffffffff


def vnoise(x, y, s=0):
    xi, yi = math.floor(x), math.floor(y)
    fx, fy = x - xi, y - yi
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = hash2(xi, yi, s), hash2(xi + 1, yi, s)
    c, d = hash2(xi, yi + 1, s), hash2(xi + 1, yi + 1, s)
    return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy


# ---- the rig's affine maps (a, b, c, d, e, f): x' = a x + b y + c, y' = d x + e y + f
POSE = {}       # set by posed.py before a model is built: part -> (degrees, dx, dy); 'all' -> (degrees, dx, dy, pivot)
PAD = 0         # room round the model (posed frames: raised arms and weapons)


def _turn(deg, pivot, dx=0, dy=0):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    px, py = pivot[0], pivot[1]
    return (c, -s, px - c * px + s * py + dx, s, c, py - s * px - c * py + dy)


def _mul(f, g):
    """f after g."""
    return (f[0] * g[0] + f[1] * g[3], f[0] * g[1] + f[1] * g[4], f[0] * g[2] + f[1] * g[5] + f[2],
            f[3] * g[0] + f[4] * g[3], f[3] * g[1] + f[4] * g[4], f[3] * g[2] + f[4] * g[5] + f[5])


def _inv(f):
    det = f[0] * f[4] - f[1] * f[3]
    a, b, d, e = f[4] / det, -f[1] / det, -f[3] / det, f[0] / det
    return (a, b, -(a * f[2] + b * f[5]), d, e, -(d * f[2] + e * f[5]))


class Model:
    """Shapes in screen space: x right, y down, z toward the viewer (pixels)."""

    def __init__(self, w, h):
        # (posed frames, posed.py: room round the body for raised arms, and the pose itself)
        self.w0, self.h0 = w, h
        self.pad = PAD
        self.w, self.h = w + 2 * PAD, h + 2 * PAD
        self.pose = POSE
        self.shapes = []
        self.anchors = {}
        self.part(None)

    # ---- the rig: parts that a pose turns round their joints
    def part(self, name, pivot=(0, 0), parent=None):
        """Shapes from here on belong to a movable part (an arm, the head, a wing); a pose (POSE) turns it
        round pivot and shifts it. A part with a parent (a staff in a hand) moves with it too. part(None)
        goes back to the body. Every part also follows 'all'."""
        if not hasattr(self, '_local'):
            self._local, self.hands = {}, {}
        self.cur = (name, pivot, parent)
        f = (1, 0, 0, 0, 1, 0)
        p = self.pose.get(name) if name else None
        if p:
            f = _turn(p[0], pivot, p[1] if len(p) > 1 else 0, p[2] if len(p) > 2 else 0)
        if parent:
            f = _mul(self._local.get(parent, (1, 0, 0, 0, 1, 0)), f)
        if name:
            self._local[name] = f
        a = self.pose.get('all')
        if a:
            f = _mul(_turn(a[0], a[3] if len(a) > 3 else (self.w0 / 2, self.h0), a[1], a[2]), f)
        self._f = _mul((1, 0, self.pad, 0, 1, self.pad), f)
        self._fi = _inv(self._f)

    def _p(self, q):
        f = self._f
        return (f[0] * q[0] + f[1] * q[1] + f[2], f[3] * q[0] + f[4] * q[1] + f[5]) + tuple(q[2:])

    def _t(self, tex):
        """A texture that stays put on its part as the part moves."""
        if not tex or self._fi == (1, 0, 0, 0, 1, 0):
            return tex
        fi = self._fi
        return lambda x, y, n: tex(fi[0] * x + fi[1] * y + fi[2], fi[3] * x + fi[4] * y + fi[5], n)

    def anchor(self, name, q):
        """Remember where a point of the current part ends up (a hand, a mouth): posed.py puts effects there."""
        self.anchors[name] = self._p(q)

    # ---- solids: each returns, for a pixel (x, y), the front surface depth z and its normal
    def sphere(self, c, r, mat, sx=1.0, sy=1.0, sz=1.0, tex=None):
        """An ellipsoid centred at c with radii r*sx, r*sy, r*sz."""
        self.shapes.append(('ell', self._p(c), (r * sx, r * sy, r * sz), mat, self._t(tex), self._fi))

    def capsule(self, a, b, ra, rb, mat, tex=None, cut=None):
        """A tapered capsule from a (radius ra) to b (radius rb). cut: nothing below this y (a flat hem)."""
        if cut is not None:
            cut = self._p((b[0], cut))[1]
        self.shapes.append(('cap', self._p(a), self._p(b), ra, rb, mat, self._t(tex), cut, self._fi))

    def chain(self, pts, radii, mat, tex=None):
        """Capsules through a list of points, the radius easing along them."""
        for i in range(len(pts) - 1):
            self.capsule(pts[i], pts[i + 1], radii[i], radii[i + 1], mat, tex)

    def membrane(self, pts, z, mat, tilt=(0.0, 0.0), tex=None):
        """A flat polygon (a wing, a cape) at depth z, its normal tilted by tilt (nx, ny)."""
        self.shapes.append(('mem', [self._p(q) for q in pts], z, mat, tilt, self._t(tex), self._fi))

    def slab(self, pts, z, bevel, mat, tex=None, height=None):
        """A hard-edged solid: the polygon pts, its face at depth z, its edges bevelled over `bevel` pixels
        (chiselled, not round). height raises the face (default: the bevel)."""
        self.shapes.append(('slab', [self._p(q) for q in pts], z, bevel, mat, self._t(tex), height if height is not None else bevel, self._fi))

    def block(self, x0, y0, x1, y1, z, bevel, mat, tex=None):
        """A bevelled rectangle (a breastplate, a stone block)."""
        self.slab([(x0, y0), (x1, y0), (x1, y1), (x0, y1)], z, bevel, mat, tex)

    def mark(self, x, y, mat, w=1, h=1):
        """A crisp mark painted on the finished surface (an eye, a glint): w x h pixels at (x, y),
        in the material's brightest tone (mat=None darkens what is there: a shadow, a brow)."""
        x, y = self._p((x, y))
        self.shapes.append(('mark', x, y, mat, w, h))

    def paint(self, fn):
        """A last pass: fn(x, y, hit) -> material name or None, for markings drawn on the surface."""
        self.shapes.append(('paint', fn))

    # ---- hits
    @staticmethod
    def _ell(x, y, c, r):
        dx, dy = (x - c[0]) / r[0], (y - c[1]) / r[1]
        q = 1 - dx * dx - dy * dy
        if q < 0:
            return None
        dz = math.sqrt(q)
        z = c[2] + dz * r[2]
        n = norm((dx / r[0], dy / r[1], dz / r[2]))
        return z, n

    @staticmethod
    def _cap(x, y, a, b, ra, rb):
        # nearest point on the segment in screen space, then a sphere of the eased radius there
        ax, ay, az = a
        bx, by, bz = b
        vx, vy = bx - ax, by - ay
        ll = vx * vx + vy * vy
        best = None
        # sample along the segment: the front-most of the swept spheres
        steps = max(2, int(math.sqrt(ll) * 1.5) + 2)
        for i in range(steps + 1):
            t = i / steps
            cx, cy, cz = ax + vx * t, ay + vy * t, az + (bz - az) * t
            r = ra + (rb - ra) * t
            dx, dy = x - cx, y - cy
            q = r * r - dx * dx - dy * dy
            if q < 0:
                continue
            dz = math.sqrt(q)
            z = cz + dz
            if best is None or z > best[0]:
                best = (z, norm((dx, dy, dz)))
        return best

    @staticmethod
    def _inside(x, y, pts):
        ins = False
        j = len(pts) - 1
        for i in range(len(pts)):
            xi, yi = pts[i]
            xj, yj = pts[j]
            if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi + 1e-9) + xi:
                ins = not ins
            j = i
        return ins

    @staticmethod
    def _edge(x, y, pts):
        """(distance to the polygon's nearest edge, outward direction from it)."""
        best, bd = (0.0, 0.0), 1e9
        for i in range(len(pts)):
            ax, ay = pts[i]
            bx, by = pts[(i + 1) % len(pts)]
            vx, vy = bx - ax, by - ay
            ll = vx * vx + vy * vy or 1e-9
            t = max(0.0, min(1.0, ((x - ax) * vx + (y - ay) * vy) / ll))
            cx, cy = ax + vx * t, ay + vy * t
            d = math.hypot(x - cx, y - cy)
            if d < bd:
                bd = d
                l = math.hypot(vy, -vx) or 1
                best = (vy / l, -vx / l)
        return bd, best

    def hit(self, x, y):
        best = None
        for s in self.shapes:
            if s[0] == 'ell':
                r = self._ell(x, y, s[1], s[2])
                if r and (best is None or r[0] > best[0]):
                    best = (r[0], r[1], s[3], s[4], s[-1])
            elif s[0] == 'cap':
                if s[7] is not None and y > s[7]:
                    continue
                r = self._cap(x, y, s[1], s[2], s[3], s[4])
                if r and (best is None or r[0] > best[0]):
                    best = (r[0], r[1], s[5], s[6], s[-1])
            elif s[0] == 'slab':
                pts, z0, bev, mat, tex, hgt = s[1], s[2], s[3], s[4], s[5], s[6]
                if self._inside(x, y, pts):
                    d, (ex, ey) = self._edge(x, y, pts)
                    # (outward: make sure the normal points away from the inside)
                    if self._inside(x + ex * 0.6, y + ey * 0.6, pts):
                        ex, ey = -ex, -ey
                    if d < bev:
                        f = 1 - d / bev
                        n = norm((ex * (0.55 + f), ey * (0.55 + f), 0.6))
                        z = z0 + hgt * d / bev
                    else:
                        n = (0.0, 0.0, 1.0)
                        z = z0 + hgt
                    if best is None or z > best[0]:
                        best = (z, n, mat, tex, s[-1])
            elif s[0] == 'mem':
                if self._inside(x, y, s[1]) and (best is None or s[2] > best[0]):
                    n = norm((s[4][0], s[4][1], 1))
                    best = (s[2], n, s[3], s[5], s[-1])
        return best

    # ---- render
    def render(self, mats, outline=0x07060c, ss=2):
        """mats: name -> {'ramp': [darkest..lightest colours], 'glow': bool, 'spec': 0..1, 'rough': 0..1}."""
        W, H = self.w, self.h
        depth = [[None] * W for _ in range(H)]
        for y in range(H):
            for x in range(W):
                depth[y][x] = self.hit(x + 0.5, y + 0.5)
        paints = [s[1] for s in self.shapes if s[0] == 'paint']
        img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        px = img.load()
        for y in range(H):
            for x in range(W):
                h = depth[y][x]
                if not h:
                    continue
                z, n, mat, tex, fi = h
                # (paints see the surface where it was drawn, so markings ride along on a moving part)
                lx, ly = fi[0] * x + fi[1] * y + fi[2], fi[3] * x + fi[4] * y + fi[5]
                for fn in paints:
                    m2 = fn(lx, ly, h)
                    if m2:
                        mat = m2
                m = mats[mat]
                ramp = m['ramp']
                if not m.get('glow') and not m.get('smooth'):
                    # planes: the surface direction pulled toward a few facets (sharper for armour and
                    # rock, which name facet=8; everything else gets a lighter touch, between round and flat)
                    k = m.get('facet', 12)
                    blend = m.get('facetk', 0.6 if 'facet' in m else 0.4)
                    a = math.atan2(n[1], n[0])
                    a = round(a / (math.pi * 2 / k)) * (math.pi * 2 / k)
                    tilt = min((0.97, 0.8, 0.58, 0.32), key=lambda c: abs(c - n[2]))
                    r = math.sqrt(max(0.0, 1 - tilt * tilt))
                    fn_ = (math.cos(a) * r, math.sin(a) * r, tilt)
                    n = norm((n[0] + (fn_[0] - n[0]) * blend, n[1] + (fn_[1] - n[1]) * blend, n[2] + (fn_[2] - n[2]) * blend))
                if m.get('glow'):
                    # emissive: brightest at its heart
                    v = m.get('glow0', 0.3) + 0.62 * n[2]
                else:
                    diff = max(0.0, n[0] * L[0] + n[1] * L[1] + n[2] * L[2])
                    rim = max(0.0, n[0] * R_[0] + n[1] * R_[1] + n[2] * R_[2]) ** 2 * m.get('rimk', 0.35)
                    # ambient occlusion: darker where a nearer surface overhangs close by
                    ao = 0
                    for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2), (-2, -2), (2, 2)):
                        q = depth[y + dy][x + dx] if 0 <= x + dx < W and 0 <= y + dy < H else None
                        if q and q[0] > z + 1.5:
                            ao += 1
                    v = (0.06 + 0.86 * diff) ** m.get('gamma', 1.35) + rim - ao * 0.08
                    spec = m.get('spec', 0)
                    if spec:
                        hv = norm((L[0], L[1], L[2] + 1))
                        v += spec * max(0.0, n[0] * hv[0] + n[1] * hv[1] + n[2] * hv[2]) ** 24
                    if tex:
                        v += tex(x, y, n)
                v = max(0.0, min(0.999, v))
                k = v * len(ramp)
                i = int(k)
                # dither only right at the seam between two tones
                if m.get('dither', True) and k - i > 0.72 and i + 1 < len(ramp) and BAYER[y % 4][x % 4] < 6:
                    i += 1
                c = ramp[min(i, len(ramp) - 1)]
                px[x, y] = ((c >> 16) & 255, (c >> 8) & 255, c & 255, 255)
        # marks: eyes and glints, crisp single pixels on the finished surface
        for sh in self.shapes:
            if sh[0] != 'mark':
                continue
            _, mx, my, mmat, mw, mh = sh
            for yy in range(int(round(my)), int(round(my)) + mh):
                for xx in range(int(round(mx)), int(round(mx)) + mw):
                    if not (0 <= xx < W and 0 <= yy < H) or not px[xx, yy][3]:
                        continue
                    if mmat is None:
                        p0 = px[xx, yy]
                        px[xx, yy] = (int(p0[0] * 0.45), int(p0[1] * 0.45), int(p0[2] * 0.45), 255)
                    else:
                        ramp = mats[mmat]['ramp']
                        c = ramp[-2] if mats[mmat].get('glow') and len(ramp) > 2 else ramp[-1]
                        px[xx, yy] = ((c >> 16) & 255, (c >> 8) & 255, c & 255, 255)
        # no outer outline (the game draws a thin black one round every sprite); only a soft seam where a
        # nearer part overlaps a farther one: the farther part's second-darkest tone, not black
        out = img.copy()
        op = out.load()
        for y in range(H):
            for x in range(W):
                if not px[x, y][3]:
                    continue
                h = depth[y][x]
                for dx, dy in ((1, 0), (0, 1), (-1, 0), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if not (0 <= xx < W and 0 <= yy < H):
                        continue
                    q = depth[yy][xx]
                    if q and h and q[0] < h[0] - 6 and not mats[q[2]].get('glow') and not mats[h[2]].get('glow'):
                        ramp = mats[q[2]]['ramp']
                        c = ramp[1 if len(ramp) > 2 else 0]
                        op[xx, yy] = ((c >> 16) & 255, (c >> 8) & 255, c & 255, 255)
        return out


# ---- textures: functions (x, y, normal) -> a small light offset
def scales(size=3.0, k=0.12, seed=1):
    def f(x, y, n):
        row = int(y / size)
        xx = x / size + (row % 2) * 0.5
        fx, fy = xx - math.floor(xx), y / size - row
        edge = min(fx, 1 - fx, fy)
        return -k if edge < 0.16 else k * 0.4 * (fy < 0.4)
    return f


def fur(k=0.14, seed=3):
    def f(x, y, n):
        v = vnoise(x * 0.5, y * 0.22, seed)
        return (v - 0.5) * 2 * k
    return f


def folds(k=0.16, period=4.0, seed=5):
    def f(x, y, n):
        w = math.sin((x + vnoise(x * 0.1, y * 0.08, seed) * 6) / period * math.pi * 2)
        return w * k
    return f


def rough(k=0.1, scale=0.35, seed=7):
    def f(x, y, n):
        return (vnoise(x * scale, y * scale, seed) - 0.5) * 2 * k
    return f


def to_rows(img, letters='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%&*+-=?@^~'):
    """(No digits: BossArt run-length codes its rows.)"""
    """An image -> (rows of letters, palette {letter: colour})."""
    px = img.load()
    pal, rev, rows = {}, {}, []
    for y in range(img.height):
        r = []
        for x in range(img.width):
            p = px[x, y]
            if p[3] < 128:
                r.append('.')
                continue
            v = (p[0] << 16) | (p[1] << 8) | p[2]
            if v not in rev:
                rev[v] = letters[len(rev)]
                pal[rev[v]] = v
            r.append(rev[v])
        rows.append(''.join(r))
    return rows, pal
