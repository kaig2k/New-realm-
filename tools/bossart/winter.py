"""
Winter in the realm: Grimsnow the Snow Tyrant, a world boss that comes every ten minutes in
December (server.js seasonalTick), and his snowlings. Modelled like the other shaded bosses
(sdfart.py) and rigged for posed.py.

Grimsnow: a hulking snowman three snowballs high, cracked and dirty with old ice, a crown of
icicles frozen to his head, coal eyes burning a cold blue, a jagged coal grin and a crooked
carrot nose, a red-and-green scarf whipping off his neck. His right arm (a gnarled black branch)
swings a great club of ice; his left holds an orb of swirling frost.
"""
import math
from sdfart import Model, rough
from shaded_kit import g, glow, designs, sheet

SNOW = g([0x5a7090, 0x8aa4c4, 0xb8cce4, 0xdce8f6, 0xf6faff], spec=0.25)
DIRT = g([0x404a5c, 0x5c6a80, 0x7c8ca4])
ICE = g([0x1c4a7a, 0x3a7ab8, 0x70b4e8, 0xb4e2ff, 0xf0faff], spec=0.9)
COAL = g([0x08080c, 0x14141c, 0x24242e, 0x3a3a48], spec=0.6)
FROST = glow(0x0c2c80, 0x2070e0, 0x50b0ff, 0xb0e8ff, base=0.3)
SCARF_R = g([0x5a0a10, 0x9a1a20, 0xd03838, 0xf06a5a])
SCARF_G = g([0x0c3a1a, 0x18602c, 0x2a8a40, 0x52b464])
CARROT = g([0x7a2a04, 0xb84a0a, 0xf07a18, 0xffa848])
TWIG = g([0x140c08, 0x2a1c12, 0x44301e, 0x5e4430])


def _scarf(m, cx, y, w, t, z=7):
    """A striped scarf round the neck, one end whipping out to the side in the wind."""
    for k in range(7):
        x0 = cx - w + k * (2 * w) / 7
        m.capsule((x0, y, z), (x0 + 2 * w / 7, y + 0.4, z), 2.0, 2.0, 'scarf_r' if k % 2 else 'scarf_g')
    tail = [(cx + w * 0.6, y + 1, z + 1)]
    for k in range(1, 5):
        tail.append((cx + w * 0.6 + k * 2.6, y + 2 + k * 2.2 + math.sin(t * math.tau + k) * 0.8, z + 1))
    for k in range(len(tail) - 1):
        m.capsule(tail[k], tail[k + 1], 1.9 - k * 0.1, 1.8 - k * 0.1, 'scarf_r' if k % 2 else 'scarf_g')


# ---------------------------------------------------------------- Grimsnow
def snow_tyrant(t):
    M = {'snow': SNOW, 'dirt': DIRT, 'ice': ICE, 'coal': COAL, 'frost': FROST, 'scarf_r': SCARF_R, 'scarf_g': SCARF_G,
         'carrot': CARROT, 'twig': TWIG}
    m = Model(64, 70)
    cx = 31
    R = rough(0.08, 0.3, 21)
    # the body: two great snowballs, the bottom one dirty where it drags on the ground
    m.sphere((cx, 54, 2), 15, 'snow', 1.0, 0.9, 1.0, R)
    m.sphere((cx, 64, 6), 13, 'dirt', 1.05, 0.25, 0.9, R)
    m.sphere((cx, 35, 4), 11.5, 'snow', 1.0, 0.95, 1.0, R)
    # coal buttons down his front
    for y in (30, 36, 42, 50):
        m.sphere((cx, y, 15.5 if y < 46 else 16.5), 1.4, 'coal')
    # right arm: a gnarled branch swinging a great club of ice
    m.part('armR', (cx + 10, 30))
    m.chain([(cx + 10, 30, 6), (cx + 16, 27, 7), (cx + 21, 24, 8)], [1.3, 1.1, 0.9], 'twig')
    m.capsule((cx + 16, 27, 7), (cx + 18, 31, 7), 0.6, 0.3, 'twig')                 # a twig off the branch
    m.anchor('handR', (cx + 21, 24))
    m.hands['R'] = (cx + 21, 24)
    m.part('heldR', (cx + 21, 24), 'armR')
    m.capsule((cx + 21, 27, 9), (cx + 23, 6, 9), 1.6, 3.4, 'ice')                   # the club: thick at the top
    for k in range(4):
        a = -0.9 + k * 0.6
        m.capsule((cx + 23, 9 + k * 4, 9), (cx + 23 + math.cos(a) * 4.5, 9 + k * 4 + math.sin(a) * 2, 9.5), 1.0, 0.2, 'ice')
    m.anchor('strike', (cx + 23, 5))
    m.part(None)
    # left arm: a branch holding up an orb of swirling frost
    m.part('armL', (cx - 10, 30))
    m.chain([(cx - 10, 30, 6), (cx - 16, 31, 7), (cx - 20, 36, 8)], [1.3, 1.1, 0.9], 'twig')
    for dx, dy in ((-2, 3), (0, 3.5), (2, 3)):
        m.capsule((cx - 20, 36, 8), (cx - 20 + dx, 36 + dy, 8.5), 0.5, 0.25, 'twig')
    m.anchor('handL', (cx - 20, 36))
    m.hands['L'] = (cx - 20, 36)
    m.part('heldL', (cx - 20, 36), 'armL')
    m.sphere((cx - 20, 40.5, 10), 3.4 + t * 0.3, 'frost')
    m.anchor('cast', (cx - 20, 40.5))
    m.part(None)
    _scarf(m, cx, 24, 9.5, t)
    # the head: a cracked snowball with coal eyes burning blue, a coal grin, a carrot nose and a crown of icicles
    m.part('head', (cx, 22))
    m.sphere((cx, 14, 4), 8.6, 'snow', 1.0, 0.95, 1.0, R)
    for s in (-1, 1):
        m.sphere((cx + s * 3.2, 12, 11.5), 1.7, 'coal', 1.0, 0.8, 0.6)
        m.mark(int(round(cx + s * 3.2)) - (1 if s < 0 else 0), 12, 'frost', 1, 1)
        # a scowl of frozen brow over each eye
        m.capsule((cx + s * 5.2, 9, 11.5), (cx + s * 1.4, 10.3, 12), 0.8, 0.6, 'ice')
    for k in range(6):
        a = math.pi * (0.2 + 0.6 * k / 5)
        m.sphere((cx - math.cos(a) * 5, 15.5 + math.sin(a) * 2.4, 11.5), 0.9, 'coal')
    m.capsule((cx + 0.5, 14, 12), (cx + 5.5, 15.5, 14), 1.4, 0.3, 'carrot')
    # the crown: icicles frozen on, the middle ones tallest
    for k in range(7):
        x = cx - 6.5 + k * 13 / 6
        mid = 1 - abs(k - 3) / 3
        m.capsule((x, 7.5 - mid * 0.6, 6), (x + (k - 3) * 0.4, 1 - mid * 5.5, 6.5), 1.2, 0.25, 'ice')
    m.anchor('mouth', (cx, 16))
    m.part(None)
    return m, M


# ---------------------------------------------------------------- the snowling
def snowling(t):
    M = {'snow': SNOW, 'coal': COAL, 'twig': TWIG, 'frost': FROST, 'scarf_r': SCARF_R}
    m = Model(24, 24)
    # it hops: squashed on the ground, then up
    y = 14 - t * 1.5
    m.sphere((12, y + 3, 2), 6.4, 'snow', 1.0, 0.85, 1.0)
    m.sphere((12, y - 4, 4), 4.6, 'snow')
    m.capsule((8, y - 0.5, 6), (16, y - 0.5, 6), 1.2, 1.2, 'scarf_r')
    for s in (-1, 1):
        m.capsule((12 + s * 5, y + 1, 4), (12 + s * 9, y - 2, 4), 0.6, 0.3, 'twig')
        m.mark(12 + (1 if s > 0 else -2), int(y - 4), 'coal', 1, 1)
    m.mark(11, int(y - 2), 'coal', 2, 1)
    return m, M


MODELS = [('snow_tyrant', snow_tyrant), ('snowling', snowling)]
RIG = {
    'snow_tyrant': {'held': 'staff', 'cast': 'one', 'heavy': True, 'legs': False},
    'snowling': {'legs': False, 'arms': 0, 'still': True},
}


def all_designs():
    return designs(MODELS)


if __name__ == '__main__':
    import sys
    sheet(MODELS, sys.argv[1], 5)
