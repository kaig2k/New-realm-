"""
The heroes, polished: the classic 8x8 drawings exactly as they were, each colour lit along its top-left
edges and shaded along its bottom-right ones, and a warmer skin. The light and shade are digits
worked out from the class's letters (TONES), so every skin and dye still recolours them, light and
shade included (Sprites.retone works them out again in the game).

    python3 tools/bossart/heroes_polished.py preview.png    every class, plain and in each skin
    python3 tools/bossart/heroes_polished.py --as3          the AS3 for Sprites.as
"""
import sys, os, re
sys.path.insert(0, os.path.dirname(__file__))
from canvas import Canvas

ROOT = os.path.join(os.path.dirname(__file__), '..', '..')
SKIN = 0xf0c898          # warmer than the old 0xf5dc72 yellow
LIGHT, DARK = 0.38, 0.68  # how much lighter the lit edge is, how much darker the shaded one
MIN_PIXELS = 4           # (a colour smaller than this, a hilt or a gem, keeps its one colour)

CONST = {'wizard': 'WIZARD', 'archer': 'ARCHER', 'knight': 'KNIGHT', 'priest': 'PRIEST', 'rogue': 'ROGUE', 'warrior': 'WARRIOR',
         'necromancer': 'NECRO', 'huntress': 'HUNTRESS', 'bard': 'BARD', 'alchemist': 'ALCHEMIST', 'chronomancer': 'CHRONO'}


def tint(c, t):
    r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    return (int(r + (255 - r) * t) << 16) | (int(g + (255 - g) * t) << 8) | int(b + (255 - b) * t)


def shade(c, f):
    r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    return (min(255, int(r * f)) << 16) | (min(255, int(g * f)) << 8) | min(255, int(b * f))


def source():
    """The original drawings and palettes, from Sprites.as as it was before any redraw (git: the classic heroes)."""
    import subprocess
    src = subprocess.run(['git', '-C', ROOT, 'show', '84a68ff:src/realm/Sprites.as'], capture_output=True, text=True).stdout
    out = {}
    for cls, const in CONST.items():
        m = re.search(r'private static const ' + const + r':Array = \[\n(.*?)\]\];', src, re.S)
        frames = [re.findall(r'"([^"]*)"', f) for f in re.findall(r'\[([^\[\]]*)\]', m.group(1) + ']')]
        p = re.search(r'\t\t\t' + cls + r': \[' + const + r', \{([^}]*)\}\]', src).group(1)
        pal = {k: int(v, 16) for k, v in re.findall(r'(\w): 0x([0-9a-fA-F]{6})', p)}
        out[cls] = (frames, pal)
    return out


def polish(frames, pal):
    """Shades each frame; returns (frames, tones) where tones = {digit: (letter, +light / -dark)}."""
    count = {}
    for f in frames:
        for r in f:
            for ch in r:
                count[ch] = count.get(ch, 0) + 1
    tones, n = {}, 0
    plan = []
    for base in [k for k in pal if k.isupper() and k not in 'SEB' and count.get(k, 0) >= MIN_PIXELS * len(frames)]:
        lt = str(n); n += 1
        tones[lt] = (base, LIGHT)
        dark = base.lower() if base.lower() in pal else None
        if not dark:
            dark = str(n); n += 1
            tones[dark] = (base, -DARK)
        plan.append((base, lt, dark))
    out = []
    for f in frames:
        c = Canvas(len(f[0]), len(f))
        c.g = [list(r) for r in f]
        for base, lt, dark in plan:
            c.shade(base, lt, dark)
        out.append(c.rows())
    return out, tones


def palette(pal, tones, over=None):
    p = dict(pal)
    p['S'] = SKIN if 'S' in p and (not over or 'S' not in over) else p.get('S')
    if over:
        p.update(over)
    for k, (base, a) in tones.items():
        p[k] = tint(p[base], a) if a >= 0 else shade(p[base], -a)
    return {k: v for k, v in p.items() if v is not None}


def build():
    return {cls: polish(*fp) + (fp[1],) for cls, fp in source().items()}


def as3():
    arrays, defs, tones_out = [], [], []
    for cls, (frames, tones, pal) in build().items():
        arrays.append((CONST[cls], '[\n' + ',\n'.join('\t\t\t[' + ', '.join('"%s"' % r for r in f) + ']' for f in frames) + ']'))
        p = palette(pal, tones)
        defs.append((cls, '[%s, {%s}]' % (CONST[cls], ', '.join(('%s' if k.isalpha() else '"%s"') % k + ': 0x%06x' % v for k, v in p.items()))))
        tones_out.append('\t\t\t%s: {%s}' % (cls, ', '.join('"%s": ["%s", %s]' % (k, b, a) for k, (b, a) in tones.items())))
    return arrays, defs, ',\n'.join(tones_out)


if __name__ == '__main__' and '--as3' in sys.argv:
    import json
    a, d, t = as3()
    print(json.dumps({'arrays': a, 'defs': d, 'tones': t}))
    sys.exit(0)

if __name__ == '__main__':
    from canvas import preview
    sys.path.insert(0, os.path.dirname(__file__))
    skins = {}
    dsrc = open(os.path.join(ROOT, 'src', 'realm', 'Data.as')).read()
    for cls in CONST:
        blk = re.search(r'\t\t\t' + cls + r': \[(\{id:.*?)\],?\n', dsrc)
        skins[cls] = [{k: int(v, 16) for k, v in re.findall(r'(\w): 0x([0-9a-fA-F]{6})', p)} for p in re.findall(r'pal: \{([^}]*)\}', blk.group(1))] if blk else []
    out = []
    for cls, (frames, tones, pal) in build().items():
        out.append((cls, frames, palette(pal, tones)))
        for sk in skins[cls]:
            out.append(('', frames[:1], palette(pal, tones, sk)))
    preview(out, sys.argv[1] if len(sys.argv) > 1 else '/tmp/heroes_polished.png', 8)
