"""
A tiny pixel-art kit for Eldmere's bosses.

Sprites are grids of palette letters ('.' is empty), exactly what the game's
Sprites.build() draws (it adds the black outline itself). Bosses are drawn
with shapes, then shaded by material: every material has a base letter plus
a light and a dark letter, and shade() lights the edges facing the top-left
and darkens the ones facing away, so big sprites read as solid forms.
"""
import math


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.g = [['.'] * w for _ in range(h)]

    # ---------------------------------------------------------------- basics
    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.g[y][x]
        return '.'

    def put(self, x, y, c, only=None):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            if only is None or self.g[y][x] in only:
                self.g[y][x] = c

    def rect(self, x0, y0, x1, y1, c, only=None):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                self.put(x, y, c, only)

    def ellipse(self, cx, cy, rx, ry, c, only=None):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                dx, dy = (x - cx) / max(rx, 0.01), (y - cy) / max(ry, 0.01)
                if dx * dx + dy * dy <= 1.0:
                    self.put(x, y, c, only)

    def ring(self, cx, cy, rx, ry, c, width=1.0):
        for y in range(int(cy - ry) - 2, int(cy + ry) + 3):
            for x in range(int(cx - rx) - 2, int(cx + rx) + 3):
                d = math.hypot((x - cx) / max(rx, 0.01), (y - cy) / max(ry, 0.01))
                if abs(d - 1) * min(rx, ry) <= width / 2:
                    self.put(x, y, c)

    def line(self, x0, y0, x1, y1, c, w=1, only=None):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(n + 1):
            t = i / n
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            if w <= 1:
                self.put(x, y, c, only)
            else:
                self.ellipse(x, y, w / 2, w / 2, c, only)

    def poly(self, pts, c, only=None):
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            yc = y + 0.5
            xs = []
            for i in range(len(pts)):
                (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % len(pts)]
                if (y0 <= yc < y1) or (y1 <= yc < y0):
                    xs.append(x0 + (yc - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for a, b in zip(xs[0::2], xs[1::2]):
                for x in range(int(math.ceil(a - 0.5)), int(math.floor(b - 0.5)) + 1):
                    self.put(x, y, c, only)

    def mirror(self):
        """Copies the left half onto the right (symmetric bosses)."""
        for y in range(self.h):
            for x in range(self.w // 2):
                self.g[y][self.w - 1 - x] = self.g[y][x]

    def replace(self, a, b):
        for y in range(self.h):
            for x in range(self.w):
                if self.g[y][x] == a:
                    self.g[y][x] = b

    # ---------------------------------------------------------------- shading
    def shade(self, base, light, dark, deep=None):
        """Lights pixels of `base` whose top-left neighbours aren't base, darkens the bottom-right ones."""
        src = [row[:] for row in self.g]
        def isb(x, y):
            return 0 <= x < self.w and 0 <= y < self.h and src[y][x] in (base, light, dark) + ((deep,) if deep else ())
        for y in range(self.h):
            for x in range(self.w):
                if src[y][x] != base:
                    continue
                up, left = isb(x, y - 1), isb(x - 1, y)
                down, right = isb(x, y + 1), isb(x + 1, y)
                if not up or (not left and isb(x, y + 1)):
                    self.g[y][x] = light
                elif not down or not right:
                    self.g[y][x] = dark
                    if deep and (not down and not right):
                        self.g[y][x] = deep

    def gradient(self, base, dark, cx, cy, r, only_frac=0.55):
        """Darkens `base` pixels far from (cx, cy): a soft round form."""
        for y in range(self.h):
            for x in range(self.w):
                if self.g[y][x] == base and math.hypot(x - cx, y - cy) > r * only_frac:
                    if (x + y) % 2 == 0 or math.hypot(x - cx, y - cy) > r * 0.85:
                        self.g[y][x] = dark

    def rows(self):
        return [''.join(r) for r in self.g]


def preview(designs, path, scale=4):
    """designs: [(name, [frames rows], palette)] -> one contact-sheet PNG (outline added like the game)."""
    from PIL import Image
    cells = []
    for name, frames, pal in designs:
        for fr in frames:
            h, w = len(fr), len(fr[0])
            img = Image.new('RGBA', (w * scale + 4, h * scale + 4), (0, 0, 0, 0))
            px = img.load()
            for y, row in enumerate(fr):
                for x, ch in enumerate(row):
                    if ch == '.' or ch not in pal:
                        continue
                    c = pal[ch]
                    for yy in range(scale):
                        for xx in range(scale):
                            px[2 + x * scale + xx, 2 + y * scale + yy] = ((c >> 16) & 255, (c >> 8) & 255, c & 255, 255)
            # black outline, 2px, like Sprites.addOutline
            out = img.copy()
            op = out.load()
            for y in range(img.height):
                for x in range(img.width):
                    if px[x, y][3]:
                        continue
                    near = any(0 <= x + dx < img.width and 0 <= y + dy < img.height and px[x + dx, y + dy][3]
                               for dx in (-2, -1, 0, 1, 2) for dy in (-2, -1, 0, 1, 2) if abs(dx) + abs(dy) <= 2)
                    if near:
                        op[x, y] = (0, 0, 0, 255)
            cells.append((name, out))
    pad = 10
    cw = max(c[1].width for c in cells) + pad
    ch = max(c[1].height for c in cells) + pad + 14
    cols = 6
    rows = (len(cells) + cols - 1) // cols
    sheet = Image.new('RGBA', (cols * cw, rows * ch), (58, 74, 52, 255))
    from PIL import ImageDraw
    d = ImageDraw.Draw(sheet)
    for i, (name, im) in enumerate(cells):
        x, y = (i % cols) * cw, (i // cols) * ch
        sheet.alpha_composite(im, (x + (cw - im.width) // 2, y + 14 + (ch - 14 - im.height) // 2))
        d.text((x + 4, y + 2), name, fill=(255, 255, 255, 255))
    sheet.save(path)
