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


class Model:
    """Shapes in screen space: x right, y down, z toward the viewer (pixels)."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.shapes = []

    # ---- solids: each returns, for a pixel (x, y), the front surface depth z and its normal
    def sphere(self, c, r, mat, sx=1.0, sy=1.0, sz=1.0, tex=None):
        """An ellipsoid centred at c with radii r*sx, r*sy, r*sz."""
        self.shapes.append(('ell', c, (r * sx, r * sy, r * sz), mat, tex))

    def capsule(self, a, b, ra, rb, mat, tex=None):
        """A tapered capsule from a (radius ra) to b (radius rb)."""
        self.shapes.append(('cap', a, b, ra, rb, mat, tex))

    def chain(self, pts, radii, mat, tex=None):
        """Capsules through a list of points, the radius easing along them."""
        for i in range(len(pts) - 1):
            self.capsule(pts[i], pts[i + 1], radii[i], radii[i + 1], mat, tex)

    def membrane(self, pts, z, mat, tilt=(0.0, 0.0), tex=None):
        """A flat polygon (a wing, a cape) at depth z, its normal tilted by tilt (nx, ny)."""
        self.shapes.append(('mem', pts, z, mat, tilt, tex))

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

    def hit(self, x, y):
        best = None
        for s in self.shapes:
            if s[0] == 'ell':
                r = self._ell(x, y, s[1], s[2])
                if r and (best is None or r[0] > best[0]):
                    best = (r[0], r[1], s[3], s[4])
            elif s[0] == 'cap':
                r = self._cap(x, y, s[1], s[2], s[3], s[4])
                if r and (best is None or r[0] > best[0]):
                    best = (r[0], r[1], s[5], s[6])
            elif s[0] == 'mem':
                if self._inside(x, y, s[1]) and (best is None or s[2] > best[0]):
                    n = norm((s[4][0], s[4][1], 1))
                    best = (s[2], n, s[3], s[5])
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
                z, n, mat, tex = h
                for fn in paints:
                    m2 = fn(x, y, h)
                    if m2:
                        mat = m2
                m = mats[mat]
                ramp = m['ramp']
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
        # an outline: the darkest tone where the silhouette meets nothing, and between depths that jump
        out = img.copy()
        op = out.load()
        oc = ((outline >> 16) & 255, (outline >> 8) & 255, outline & 255, 255)
        for y in range(H):
            for x in range(W):
                if px[x, y][3]:
                    h = depth[y][x]
                    for dx, dy in ((1, 0), (0, 1)):
                        q = depth[y + dy][x + dx] if x + dx < W and y + dy < H else None
                        if q and h and abs(q[0] - h[0]) > 6 and q[0] < h[0] and not mats[q[2]].get('glow'):
                            op[x + dx, y + dy] = oc
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if 0 <= x + dx < W and 0 <= y + dy < H and px[x + dx, y + dy][3]:
                        op[x, y] = oc
                        break
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
