"""
Cuts a boss out of the user's own art (a pixel-art picture on a fake checkerboard
background) at its native pixel size, so the game sprite keeps the art exactly.
    cut(path, block) -> RGBA image, one pixel per pixel of the art
"""
from PIL import Image
import colorsys


def _bg(c):
    l = (max(c) + min(c)) / 510
    return l > 0.80 and (max(c) - min(c)) < 30


def cut(path, block, min_hole=1500):
    im = Image.open(path).convert('RGB')
    W, H = im.size
    px = im.load()
    lab = bytearray(W * H)   # 1 = background
    seen = bytearray(W * H)
    for sy in range(H):
        for sx in range(W):
            if seen[sy * W + sx] or not _bg(px[sx, sy]):
                continue
            # one connected patch of background-coloured pixels
            comp, st, edge = [], [(sx, sy)], False
            seen[sy * W + sx] = 1
            while st:
                x, y = st.pop()
                comp.append(y * W + x)
                if x == 0 or y == 0 or x == W - 1 or y == H - 1:
                    edge = True
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < W and 0 <= ny < H and not seen[ny * W + nx] and _bg(px[nx, ny]):
                        seen[ny * W + nx] = 1
                        st.append((nx, ny))
            # the background touches the edge, or is a big enclosed hole (a small pale patch is a highlight)
            if edge or len(comp) >= min_hole:
                for i in comp:
                    lab[i] = 1
    mask = Image.frombytes('L', (W, H), bytes(0 if v else 255 for v in lab))
    bb = mask.getbbox()
    rgb = Image.new('RGB', (W, H))
    rgb.paste(im, mask=mask)
    rgb, mask = rgb.crop(bb), mask.crop(bb)
    w, h = round(rgb.width / block), round(rgb.height / block)
    a = mask.resize((w, h), Image.BOX).load()
    rs = rgb.resize((w, h), Image.BOX).load()
    out = Image.new('RGBA', (w, h))
    op = out.load()
    for y in range(h):
        for x in range(w):
            A = a[x, y]
            if A < 110:
                continue
            r, g, b = rs[x, y]
            k = 255 / A
            op[x, y] = (min(255, int(r * k)), min(255, int(g * k)), min(255, int(b * k)), 255)
    return out
