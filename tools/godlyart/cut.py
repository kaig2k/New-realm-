"""
The Godly weapons' inventory icons, cut from the sheet the art was drawn on
(weapons_sheet.webp): each weapon is lifted off its dark grid background and
fitted, as drawn, into a 34x34 icon (the game adds the outline and Godly frame).

    python3 tools/godlyart/cut.py tools/godlyart/weapons_sheet.webp assets/godly
    python3 tools/godlyart/cut.py tools/godlyart/armor_sheet.webp assets/godly armor_ precise
        (the Grand Chorus lyre from the same sheet without "precise": the gaps between its strings)
    python3 tools/godlyart/cut.py tools/godlyart/abilities_sheet.webp assets/godly ability_ [precise]
        (precise for the Grimoire, Shroud, Crown, Snare and Hourglass; the rest without it)
"""
import sys
from PIL import Image
from collections import deque
src = Image.open(sys.argv[1]).convert('RGB')
out = sys.argv[2]
# (a sheet of armour or abilities: their icons are named armor_<class>.png, ability_<class>.png)
PREFIX = sys.argv[3] if len(sys.argv) > 3 else ''
R1 = (92, 326); R2 = (432, 668); R3 = (773, 1002)
C4 = [(13, 242), (269, 498), (525, 754), (781, 1010)]
C3 = [(14, 275), (377, 636), (739, 981)]
cells = [('wizard', C4[0], R1), ('archer', C4[1], R1), ('knight', C4[2], R1), ('priest', C4[3], R1),
         ('rogue', C4[0], R2), ('warrior', C4[1], R2), ('necromancer', C4[2], R2), ('huntress', C4[3], R2),
         ('bard', C3[0], R3), ('alchemist', C3[1], R3), ('chronomancer', C3[2], R3)]
# "precise" (4th argument): only the sheet's own navy and its grid lines count as background, for
# art that is itself dark (a black silhouette, a night-sky robe): near-black stays, and nothing
# the shape encloses is cleared
PRECISE = len(sys.argv) > 4 and sys.argv[4] == 'precise'


def bglike(p):
    if PRECISE:
        r, g, b = p
        return 55 <= r + g + b <= 175 and 24 <= b - r <= 42 and 0 <= g - r <= 13 and b - g >= 18
    return bglike_loose(p)


def bglike_loose(p):
    r, g, b = p
    return (b >= r + 10 and r < 75 and g < 85 and b < 120) or (r + g + b < 40)
for name, (x0, x1), (y0, y1) in cells:
    im = src.crop((x0, y0, x1, y1))
    w, h = im.size
    px = im.load()
    bg = [[False] * w for _ in range(h)]
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or bg[y][x] or not bglike(px[x, y]):
            continue
        bg[y][x] = True
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    # pockets of background the shape closes in (inside a bow's string, a harp's frame): big ones go too
    seen = [[False] * w for _ in range(h)]
    for sy in range(h):
        for sx in range(w):
            if bg[sy][sx] or seen[sy][sx] or not bglike(px[sx, sy]):
                continue
            comp = []; q2 = deque([(sx, sy)]); seen[sy][sx] = True
            while q2:
                x, y = q2.popleft(); comp.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and not bg[ny][nx] and bglike(px[nx, ny]):
                        seen[ny][nx] = True; q2.append((nx, ny))
            if len(comp) > 250 and not PRECISE:
                for x, y in comp: bg[y][x] = True
    rgba = Image.new('RGBA', (w, h))
    o = rgba.load()
    for y in range(h):
        for x in range(w):
            o[x, y] = (0, 0, 0, 0) if bg[y][x] else px[x, y] + (255,)
    bb = rgba.getbbox()
    rgba = rgba.crop(bb)
    rgba.save(f'{out}/{PREFIX}{name}_full.png')
    # fit into 34x34 (the icon is 36 with its outline)
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
    icon.save(f'{out}/{PREFIX}{name}.png')
    print(name, bb, rgba.size)
