"""
The Godly rings' inventory icons, cut from the ring sheet (one row of 11 under
their names): each ring is lifted off the dark grid and fitted, as drawn, into a
34x34 icon (the game adds the outline and Godly frame).

    python3 tools/godlyart/cut_rings.py tools/godlyart/rings_sheet.png assets/godly
"""
import sys
from PIL import Image
from collections import deque
src = Image.open(sys.argv[1]).convert('RGB')
out = sys.argv[2]
names = 'wizard archer knight priest rogue warrior necromancer huntress bard alchemist chronomancer'.split()
# the columns: between the names' centres (the first ring's sparkles reach a little to the right)
cx = [83, 205, 287, 362, 437, 511, 601, 692, 782, 881, 973]
edges = [0] + [(cx[i] + cx[i + 1]) // 2 for i in range(10)] + [src.size[0]]
edges[1] = 160
Y0, Y1 = 188, 334   # the rings themselves (the first ring's tall shower of stars above is left out)


def bglike(p, haze=False):
    r, g, b = p
    # the sheet's grid and the rings' shadows: dark slate, never purple (less green than red) or green (more green than blue)
    if r + g + b < 30:
        return True
    if haze:
        # (the first ring's stars sit in a soft navy haze: that goes too, the stars stay)
        return r < 55 and g < 70 and b < 100 and b - r >= 6
    return g >= r - 3 and b - g >= 6 and 6 <= b - r <= 32 and b < 80


for i, n in enumerate(names):
    hz = n == 'wizard'
    im = src.crop((edges[i], Y0, edges[i + 1], Y1))
    w, h = im.size
    px = im.load()
    bg = [[False] * w for _ in range(h)]
    q = deque([(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)] + [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)])
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or bg[y][x] or not bglike(px[x, y], hz):
            continue
        bg[y][x] = True
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    # the hole in the ring, and other pockets of background it closes in
    seen = [[False] * w for _ in range(h)]
    for sy in range(h):
        for sx in range(w):
            if bg[sy][sx] or seen[sy][sx] or not bglike(px[sx, sy], hz):
                continue
            comp = []
            q2 = deque([(sx, sy)])
            seen[sy][sx] = True
            while q2:
                x, y = q2.popleft()
                comp.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and not bg[ny][nx] and bglike(px[nx, ny], hz):
                        seen[ny][nx] = True
                        q2.append((nx, ny))
            if len(comp) > 40:
                for x, y in comp:
                    bg[y][x] = True
    # specks of shadow left on their own (not the first ring: its stars are specks)
    if not hz:
        keep = [[False] * w for _ in range(h)]
        for sy in range(h):
            for sx in range(w):
                if bg[sy][sx] or keep[sy][sx]:
                    continue
                comp = []
                q3 = deque([(sx, sy)])
                keep[sy][sx] = True
                while q3:
                    x, y = q3.popleft()
                    comp.append((x, y))
                    for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1), (x + 1, y + 1), (x - 1, y - 1), (x + 1, y - 1), (x - 1, y + 1)):
                        if 0 <= nx < w and 0 <= ny < h and not keep[ny][nx] and not bg[ny][nx]:
                            keep[ny][nx] = True
                            q3.append((nx, ny))
                if len(comp) < 60:
                    for x, y in comp:
                        bg[y][x] = True
    rgba = Image.new('RGBA', (w, h))
    o = rgba.load()
    for y in range(h):
        for x in range(w):
            o[x, y] = (0, 0, 0, 0) if bg[y][x] else px[x, y] + (255,)
    rgba = rgba.crop(rgba.getbbox())
    if len(sys.argv) > 3:
        rgba.save(f'{out}/ring_{n}_full.png')
    S = 34
    cw, ch = rgba.size
    k = S / max(cw, ch)
    nw, nh = max(1, round(cw * k)), max(1, round(ch * k))
    small = rgba.resize((nw, nh), Image.LANCZOS)
    sp = small.load()
    for y in range(nh):
        for x in range(nw):
            r, g, b, a = sp[x, y]
            sp[x, y] = (r, g, b, 255) if a >= 110 else (0, 0, 0, 0)
    icon = Image.new('RGBA', (S, S))
    icon.paste(small, ((S - nw) // 2, (S - nh) // 2))
    icon.save(f'{out}/ring_{n}.png')
    print(n, rgba.size)
