"""
The lairs' portals (Lairs.as): each realm boss's dungeon has a gate of its own, a swirling vortex
in a frame built from what the lair is (a cage of light, an ice arch, a ribcage, a skull's open jaw...).
Four frames each, the vortex turning (portal_<lair id>; Game draws them for those dungeons).
"""
import math
from sdfart import Model, rough, folds, vnoise
from shaded_kit import g, glow, spike, rock, LETTERS

FRAMES = 4
W, H = 34, 40
CX, CY = 17, 21


def vortex(m, rx, ry, a, b, t, z=0):
    """An oval of swirling light (two tones spiralling in), turned by t (0..1 over the animation)."""
    m.sphere((CX, CY, z), 1.0, a, rx, ry, 0.2)

    def swirl(x, y, h):
        if h[2] != a:
            return None
        dx, dy = (x - CX) / rx, (y - CY) / ry
        r, ang = math.hypot(dx, dy), math.atan2(dy, dx)
        return b if (ang / (2 * math.pi) * 3 + r * 2.2 - t * 3) % 1.0 < 0.38 else None
    m.paint(swirl)
    m.sphere((CX, CY, z + 1), 1.0, 'heart', rx * 0.28, ry * 0.28, 0.3)


def cage(t):
    M = {'v1': glow(0x6020b0, 0xa050ff, base=0.25), 'v2': glow(0xd090ff, 0xffffff, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'edge': glow(0x9040e0, 0xd080ff, 0xffe0ff, base=0.3)}
    m = Model(W, H)
    vortex(m, 10, 13, 'v1', 'v2', t)
    for (x0, y0), (x1, y1) in (((5, 6), (29, 6)), ((5, 36), (29, 36)), ((5, 6), (5, 36)), ((29, 6), (29, 36)), ((5, 6), (11, 2)), ((29, 6), (23, 2)), ((11, 2), (23, 2))):
        m.capsule((x0, y0, 3), (x1, y1, 3), 1.0, 1.0, 'edge')
    return m, M


def forge(t):
    M = {'v1': glow(0xa02a08, 0xff6010, base=0.2), 'v2': glow(0xffb040, 0xfff0a0, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'stone': g([0x0e0a0c, 0x1a1418, 0x2a2228, 0x3c323a], facet=8), 'lava': glow(0xa02a08, 0xff6010, 0xffb040, base=0.15)}
    m = Model(W, H)
    vortex(m, 10, 13, 'v1', 'v2', t)
    for s in (-1, 1):
        m.block(CX + s * 13 - 3, 6, CX + s * 13 + 3, 38, 2, 1.6, 'stone', rough(0.08, 0.3, 3))
    m.slab([(2, 8), (32, 8), (28, 1), (6, 1)], 3, 1.6, 'stone')
    for x in (8, 17, 26):
        m.capsule((x, 8, 5), (x + 0.5, 12 + (x % 3) + t * 2, 5), 0.7, 0.4, 'lava')
    return m, M


def ice_arch(t):
    M = {'v1': glow(0x2a70c0, 0x60b0ff, base=0.25), 'v2': glow(0xc0f0ff, 0xffffff, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'ice': g([0x3e7aa8, 0x5c9ccc, 0x86c0e8, 0xb8e2ff, 0xffffff], facet=8, spec=0.8)}
    m = Model(W, H)
    vortex(m, 10, 13, 'v1', 'v2', t)
    for k in range(9):
        a = math.pi + k * math.pi / 8
        x, y = CX + math.cos(a) * 14, 22 + math.sin(a) * 18
        spike(m, (x, y), (CX + math.cos(a) * 18, 22 + math.sin(a) * 22), 1.8, 3, 'ice')
    for s in (-1, 1):
        rock(m, CX + s * 13, 34, 4, 3, 'ice', 7 + s, sides=6)
    return m, M


def crown_arch(t):
    M = {'v1': glow(0x1a7a2a, 0x40e060, base=0.25), 'v2': glow(0xb0ffc0, 0xffffff, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'bone': g([0x6c6450, 0x9e967c, 0xcac4a8, 0xece8d4]), 'gold': g([0x5a420c, 0x9a7418, 0xd8a830, 0xffe080], spec=0.6)}
    m = Model(W, H)
    vortex(m, 10, 13, 'v1', 'v2', t)
    for s in (-1, 1):
        m.capsule((CX + s * 12, 38, 2), (CX + s * 12, 10, 2), 2.4, 2.0, 'bone')
    m.capsule((CX - 12, 10, 2), (CX + 12, 10, 2), 2.0, 2.0, 'bone')
    m.capsule((CX - 8, 6, 4), (CX + 8, 6, 4), 1.2, 1.2, 'gold')
    for k in range(5):
        x = CX - 8 + k * 4
        m.capsule((x, 6, 4.5), (x, 1 if k == 2 else 2.6, 4.5), 1.0, 0.3, 'gold')
    return m, M


def ribcage(t):
    M = {'v1': glow(0x900810, 0xe02030, base=0.2), 'v2': glow(0xff8080, 0xffe0e0, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'bone': g([0x6a5e48, 0x9a8e70, 0xcac0a0, 0xece6d0])}
    m = Model(W, H)
    vortex(m, 9, 13, 'v1', 'v2', t)
    m.capsule((CX, 4, 3), (CX, 38, 3), 1.0, 1.0, 'bone')
    for k in range(5):
        y = 8 + k * 6
        for s in (-1, 1):
            m.chain([(CX, y, 3), (CX + s * 10, y + 1, 3), (CX + s * 13, y + 5, 2)], [1.0, 1.1, 0.6], 'bone')
    return m, M


def mirror(t):
    M = {'v1': glow(0x5a2aa0, 0x9a6aff, base=0.25), 'v2': glow(0xe0d0ff, 0xffffff, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'gold': g([0x5a420c, 0x9a7418, 0xd8a830, 0xffe080], spec=0.7)}
    m = Model(W, H)
    vortex(m, 11, 15, 'v1', 'v2', t)
    for k in range(24):
        a = k * math.pi / 12
        a2 = (k + 1) * math.pi / 12
        m.capsule((CX + math.cos(a) * 12.5, CY + math.sin(a) * 16.5, 3), (CX + math.cos(a2) * 12.5, CY + math.sin(a2) * 16.5, 3), 1.3, 1.3, 'gold')
    for s in (-1, 1):
        m.sphere((CX + s * 12.5, CY, 4), 1.8, 'gold')
    m.sphere((CX, CY - 17, 4), 2.2, 'gold')
    return m, M


def tomb_door(t):
    M = {'v1': glow(0xa07010, 0xffc040, base=0.25), 'v2': glow(0xfff0a0, 0xffffff, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'stone': g([0x5a4626, 0x846a3c, 0xae8e54, 0xd4b474], facet=8), 'blue': g([0x163276, 0x2450aa, 0x3a74d8]),
         'gold': g([0x6a4808, 0xa87812, 0xe0b028, 0xfff09a], spec=0.7)}
    m = Model(W, H)
    m.slab([(1, 39), (33, 39), (25, 2), (9, 2)], 0, 2.4, 'stone', rough(0.06, 0.3, 9))
    vortex(m, 8, 12, 'v1', 'v2', t, z=4)
    m.slab([(10, 6), (24, 6), (23, 8.5), (11, 8.5)], 4, 0.6, 'gold')
    m.mark(16, 4, 'blue', 2, 1)
    return m, M


def anchor_ring(t):
    M = {'v1': glow(0x1a6a7a, 0x30c0c0, base=0.25), 'v2': glow(0xa0fff0, 0xffffff, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'iron': g([0x2a1a10, 0x4a2c18, 0x6a4024, 0x8a5a34], facet=8), 'weed': g([0x0e2a14, 0x1a4422, 0x2a6234])}
    m = Model(W, H)
    vortex(m, 10, 13, 'v1', 'v2', t)
    for k in range(18):
        a, a2 = k * math.pi / 9, (k + 1) * math.pi / 9
        m.capsule((CX + math.cos(a) * 13, CY + math.sin(a) * 16, 3), (CX + math.cos(a2) * 13, CY + math.sin(a2) * 16, 3), 1.2, 1.2, 'iron')
    m.capsule((CX, 1, 5), (CX, 9, 5), 1.0, 1.0, 'iron')
    m.chain([(CX - 7, 38, 5), (CX - 4, 40, 5), (CX + 4, 40, 5), (CX + 7, 38, 5)], [1.0, 1.0, 1.0, 1.0], 'iron')
    for k in range(4):
        m.capsule((CX - 12 + k * 8, 33, 4.5), (CX - 13 + k * 8, 39, 4.5), 0.8, 0.4, 'weed')
    return m, M


def coral_ring(t):
    M = {'v1': glow(0x10807a, 0x30d8c0, base=0.25), 'v2': glow(0xc0fff4, 0xffffff, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'coral': g([0x7a1a3a, 0xb02a5a, 0xe0508a, 0xff8ab4]), 'shell': g([0x6e5068, 0x96708e, 0xc09ab4, 0xecc8d4])}
    m = Model(W, H)
    vortex(m, 10, 13, 'v1', 'v2', t)
    for k in range(10):
        a = math.pi * 0.9 + k * math.pi * 1.2 / 9
        x, y = CX + math.cos(a) * 13, CY + math.sin(a) * 16
        m.chain([(x, y, 3), (x + math.cos(a) * 3, y + math.sin(a) * 3, 3), (x + math.cos(a + 0.4) * 5, y + math.sin(a + 0.4) * 5, 3)], [1.5, 1.0, 0.4], 'coral')
    m.sphere((CX, 36, 4), 5, 'shell', 1.3, 0.6, 1)
    for s in (-1, 1):
        m.sphere((CX + s * 12, 33, 3), 3.4, 'coral', 1, 1, 1)
    return m, M


def skull_maw(t):
    M = {'v1': glow(0x6a20c0, 0xb070ff, base=0.25), 'v2': glow(0xe8d0ff, 0xffffff, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'bone': g([0x4a4436, 0x7c7460, 0xaea68c, 0xd8d2b8, 0xf2eedc]), 'void': g([0x050308, 0x0c0812])}
    m = Model(W, H)
    m.sphere((CX, 12, 0), 14, 'bone', 1.05, 0.8, 0.8, rough(0.05))
    for s in (-1, 1):
        m.sphere((CX + s * 6, 10, 9), 3.2, 'void', 1, 1.1, 0.5)
        m.mark(CX + s * 6, 10, 'v2')
    vortex(m, 8, 9, 'v1', 'v2', t, z=10)
    for k in range(6):
        m.capsule((CX - 7.5 + k * 3, 20, 13), (CX - 7.5 + k * 3, 23, 13), 1.0, 0.6, 'bone')
        m.capsule((CX - 7.5 + k * 3, 34, 13), (CX - 7.5 + k * 3, 31, 13), 1.0, 0.6, 'bone')
    m.capsule((CX - 10, 36, 6), (CX + 10, 36, 6), 2.6, 2.6, 'bone')
    return m, M


def obsidian_gate(t):
    M = {'v1': glow(0x4a2aa0, 0x9060ff, base=0.25), 'v2': glow(0xd0b0ff, 0xffffff, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'rock': g([0x08060c, 0x120e18, 0x1e1828, 0x2c2440, 0x3e3458], facet=8, spec=0.5), 'crystal': g([0x6a40c0, 0x9a6aff, 0xd0b0ff], facet=8, spec=0.8)}
    m = Model(W, H)
    vortex(m, 9, 14, 'v1', 'v2', t)
    for s in (-1, 1):
        m.slab([(CX + s * 9, 39), (CX + s * 16, 39), (CX + s * 14, 2), (CX + s * 9, 8)], 2, 2.0, 'rock')
        spike(m, (CX + s * 13, 8), (CX + s * 15, -1), 1.6, 5, 'crystal')
    return m, M


def flame_ring(t):
    M = {'v1': glow(0xa02006, 0xff6010, base=0.2), 'v2': glow(0xffd060, 0xfff4c0, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'out': glow(0xa02006, 0xe04a10, 0xff8a20, 0xffc050, base=0.05)}
    m = Model(W, H)
    vortex(m, 10, 13, 'v1', 'v2', t)
    for k in range(14):
        a = k * math.pi * 2 / 14
        x, y = CX + math.cos(a) * 13, CY + math.sin(a) * 16
        ln = 4 + ((k + int(t * 4)) % 3)
        m.capsule((x, y, 3), (x + math.cos(a - 0.6) * ln, y + math.sin(a - 0.6) * ln - 1, 3), 1.8, 0.3, 'out')
    return m, M


def tree_arch(t):
    M = {'v1': glow(0x2a9a20, 0x60e040, base=0.25), 'v2': glow(0xc0ff90, 0xffffff, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'wood': g([0x1e140c, 0x342416, 0x4c3622, 0x6a4c30]), 'hex': glow(0x40c020, 0xa0ff80)}
    m = Model(W, H)
    vortex(m, 10, 13, 'v1', 'v2', t)
    for s in (-1, 1):
        m.chain([(CX + s * 11, 39, 2), (CX + s * 13, 28, 2), (CX + s * 11, 16, 2), (CX + s * 6, 6, 2), (CX + s * 1, 3, 2)], [3.0, 2.6, 2.2, 1.6, 1.0], 'wood')
        m.chain([(CX + s * 12, 18, 2.5), (CX + s * 16, 12, 2.5), (CX + s * 17, 6, 2.5)], [1.0, 0.7, 0.3], 'wood')
    for x, y in ((CX - 12, 30), (CX + 11, 22), (CX - 7, 9)):
        m.mark(x, y, 'hex')
    return m, M


def tentacle_ring(t):
    M = {'v1': glow(0x4a1a8a, 0x8040c0, base=0.25), 'v2': glow(0xd0a0ff, 0xffffff, base=0.4), 'heart': glow(0xffffff, 0xffffff),
         'skin': g([0x1e0a26, 0x34123e, 0x4e1c5a, 0x6c2a7c, 0x8e3ca0], spec=0.4), 'water': g([0x0a2a5a, 0x1a4a8a, 0x3a74b8, 0x80b8e8], spec=0.6)}
    m = Model(W, H)
    m.sphere((CX, 37, -2), 16, 'water', 1.0, 0.18, 0.5)
    vortex(m, 10, 13, 'v1', 'v2', t)
    for s in (-1, 1):
        for k in range(2):
            x0 = CX + s * (10 + k * 4)
            m.chain([(x0, 38, 2), (x0 + s * 2, 26, 2), (x0 - s * 1, 14, 2), (x0 - s * 6, 6 + k * 3, 2)], [2.6, 2.2, 1.6, 0.6], 'skin')
    return m, M


PORTALS = {'tesseract': cage, 'titan_forge': forge, 'wyrm_cradle': ice_arch, 'hollow_court': crown_arch, 'bone_pit': ribcage,
           'phantom_court': mirror, 'tomb_of_riddles': tomb_door, 'drowned_keep': anchor_ring, 'coral_grotto': coral_ring,
           'ossuary': skull_maw, 'obsidian_quarry': obsidian_gate, 'ashen_aerie': flame_ring, 'hexwood': tree_arch, 'krakens_maw': tentacle_ring}


def sequences(scale=3):
    """[(portal_<id>, frames, palette, scale)]."""
    out = []
    for lid, fn in PORTALS.items():
        rev, pal, frames = {}, {}, []
        for k in range(FRAMES):
            m, mats = fn(k / FRAMES)
            img = m.render(mats)
            px = img.load()
            rows = []
            for y in range(img.height):
                r = []
                for x in range(img.width):
                    q = px[x, y]
                    if q[3] < 128:
                        r.append('.')
                        continue
                    v = (q[0] << 16) | (q[1] << 8) | q[2]
                    if v not in rev:
                        assert len(rev) < len(LETTERS), lid + ': too many colours'
                        rev[v] = LETTERS[len(rev)]
                        pal[rev[v]] = v
                    r.append(rev[v])
                rows.append(''.join(r))
            frames.append(rows)
        out.append(('portal_' + lid, frames, pal, scale))
    return out


if __name__ == '__main__':
    import sys
    from PIL import Image
    sc = 4
    ims = [[fn(k / FRAMES)[0].render(fn(k / FRAMES)[1]) for k in range(FRAMES)] for fn in PORTALS.values()]
    s = Image.new('RGBA', (len(ims) * (W * sc + 8) + 8, FRAMES * (H * sc + 8) + 8), (40, 42, 36, 255))
    for i, fr in enumerate(ims):
        for k, im in enumerate(fr):
            s.alpha_composite(im.resize((W * sc, H * sc), Image.NEAREST), (8 + i * (W * sc + 8), 8 + k * (H * sc + 8)))
    s.convert('RGB').save(sys.argv[1])
