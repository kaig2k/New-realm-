"""
The realm's monsters, shaded from solids like the bosses (they used to be flat 16x16 drawings that
looked poor next to them): the beach (pirates, snakes, scorpions, crabs, slimes), the lowlands (goblins,
hobbits, bandits, wolves), the midlands (orcs, gazers, spiders), the highlands (golems, harpies, dwarves,
elves, ogres, minotaurs) and the Godlands (medusa, djinn, ent, beholder, lich, the gods). Small: about
22-30 pixels a side (they're drawn at 3x), two frames each (animate.py makes their walk and attack).
"""
import math
from sdfart import Model, rough, folds, scales, fur, vnoise
from shaded_kit import g, glow, robe, torso, arm, held, legs, head, eyes, hood, crown, staff, wing, flame, designs, sheet, \
    chest, plate, pauldron, rock, spike

VOID = g([0x040306, 0x0a080e])
SKIN = g([0x7a5640, 0xb4846a, 0xe0b498])
PALE = g([0x8a6a58, 0xc49a80, 0xf0c8a8])
STEEL = g([0x3a4250, 0x6a7686, 0xa8b4c4, 0xe8f0ff], spec=0.9)
WOOD = g([0x3a240e, 0x5e3c1a, 0x8a5e2e])
LEATHER = g([0x2e1c0e, 0x4a2e16, 0x6e4626, 0x946436])
GOLD = g([0x5a420c, 0x9a7418, 0xd8a830, 0xffe080], spec=0.7)
BONE = g([0x6c6450, 0x9e967c, 0xcac4a8, 0xece8d4])


def M(**k):
    """Materials, with a few every model may use."""
    d = {'void': VOID, 'steel': STEEL, 'wood': WOOD, 'leather': LEATHER, 'gold': GOLD, 'bone': BONE}
    d.update(k)
    return d


def biped(m, cx, top, foot, w, body, legmat, armmat, skin, headr, hand_mat=None, belly=None):
    """A small person: legs, a body from top to the hips, two arms; returns the head's centre (y)."""
    hips = top + (foot - top) * 0.52
    legs(m, cx, hips - 1, foot, w * 0.42, w * 0.38, legmat)
    m.capsule((cx, top, 1), (cx, hips + 1, 1), w, w * 0.9, body, rough(0.05))
    if belly:
        m.capsule((cx, hips - 1.5, w * 0.8), (cx + 0.1, hips - 1.4, w * 0.8), w * 0.95, w * 0.95, belly)
    for s in (-1, 1):
        arm(m, (cx + s * w * 0.9, top + 1, 1.5), (cx + s * (w + 1.6), top + 4.5, 2.5), (cx + s * (w + 1.2), top + 7.5, 4), w * 0.36, armmat,
            hand_mat or skin, w * 0.34)
    return top - headr + 0.5


# ================================================================== the beach
def pirate(t, coat=0x7a1a1a, captain=False):
    c = coat
    mm = M(skin=SKIN, shirt=g([0x6a6a60, 0xa8a89a, 0xe8e8dc]), coat=g([c >> 2 & 0x3f3f3f, c, min(0xffffff, c + 0x302020)]),
           pants=g([0x141820, 0x242c3c, 0x384660]), hat=g([0x0a0a0c, 0x18181e, 0x2a2a34]), eye=glow(0x101010, 0x303030))
    m = Model(26, 30)
    hy = biped(m, 13, 13, 29, 4.0, 'coat' if captain else 'shirt', 'pants', 'coat' if captain else 'shirt', 'skin', 4.2)
    m.capsule((9.5, 18.5, 4.5), (16.5, 18.5, 4.5), 0.8, 0.8, 'leather')                      # belt
    m.sphere((13, 18.5, 5.4), 0.8, 'gold')
    held(m, 'R')                                                                              # a cutlass
    m.capsule((18.5, 21, 6), (24, 14 - t, 6), 0.8, 0.35, 'steel')
    m.capsule((17.5, 21.5, 6.5), (19.5, 20, 6.5), 0.7, 0.7, 'gold')
    m.part(None)
    head(m, 13, hy, 4.2, 'skin')
    eyes(m, 13, int(hy), 1.6, 6, 'eye')
    m.capsule((10.2, hy - 0.6, 7), (15.8, hy - 1.6, 7), 0.4, 0.4, 'hat')                    # an eye-patch's string
    if captain:
        m.sphere((13, hy - 3.2, 3), 7.0, 'hat', 1.0, 0.32, 0.8)                              # a tricorne
        m.sphere((13, hy - 4.6, 3), 3.8, 'hat', 1.15, 0.7, 0.8)
        m.capsule((7, hy - 3.2, 6), (19, hy - 3.2, 6), 0.45, 0.45, 'gold')
        m.capsule((10, hy + 2.6, 6.5), (16, hy + 2.6, 6.5), 1.0, 1.0, 'hat')                 # a black beard
    else:
        m.sphere((13, hy - 2.6, 3.5), 4.3, 'coat', 1.0, 0.55, 1.0)                           # a bandana
        m.capsule((16.5, hy - 2, 2), (19, hy + 1, 2), 0.7, 0.4, 'coat')
    m.part(None)
    return m, mm


def pirate_brawler(t):
    mm = M(skin=g([0x6a4430, 0xa06a4c, 0xd09670]), pants=g([0x141820, 0x242c3c, 0x384660]), sash=g([0x6a1010, 0xa82020, 0xe04040]), beard=g([0x0a0806, 0x1a140e, 0x2e2418]),
           eye=glow(0x101010, 0x303030))
    m = Model(28, 30)
    hy = biped(m, 14, 12, 29, 5.2, 'skin', 'pants', 'skin', 'skin', 3.8)
    m.capsule((9, 18.5, 5.4), (19, 18.5, 5.4), 1.2, 1.2, 'sash')
    for s in (-1, 1):                                                                         # fists like hams
        m.sphere((14 + s * 6.5, 19.5 - t, 6), 2.2, 'skin')
    head(m, 14, hy - 0.5, 3.8, 'skin')
    eyes(m, 14, int(hy) - 1, 1.4, 6, 'eye')
    m.sphere((14, hy - 3, 3.5), 4.0, 'sash', 1.0, 0.5, 1.0)                                  # a red bandana
    m.capsule((17, hy - 2.5, 2), (19.5, hy, 2), 0.7, 0.4, 'sash')
    m.capsule((11.5, hy + 2, 6), (16.5, hy + 2, 6), 1.2, 1.2, 'beard')                      # a black beard
    m.capsule((14, hy + 2.5, 6.5), (14, hy + 4.5, 6.5), 1.6, 0.6, 'beard')
    m.part(None)
    return m, mm


def snake(t, big=False):
    body = g([0x2a4a10, 0x4a7a1c, 0x78b030, 0xb8e070]) if not big else g([0x3a2a0a, 0x6a5018, 0xa07c2c, 0xd8b058])
    mm = M(body=body, belly=g([0x8a8050, 0xc8b878, 0xf0e4b0]), eye=glow(0xa01010, 0xff4040), tongue=g([0xa01020, 0xe03040]))
    W, H = (30, 22) if big else (26, 18)
    m = Model(W, H)
    pts = []
    for k in range(9):
        a = k / 8
        pts.append((3 + a * (W - 9), H - 4 - math.sin(a * math.pi * 2 + t * 0.8) * 2.2 - a * (H * 0.3), 1))
    m.chain(pts, [1.6 + a * 0.3 for a in [k / 8 for k in range(9)]][:-1] + [2.4], 'body', scales(0.08, 1.4))
    hx, hy = pts[-1][0] + 2, pts[-1][1] - 2
    m.sphere((hx, hy, 2), 3.2 if big else 2.7, 'body', 1.3, 0.9, 1, scales(0.08, 1.2))
    m.mark(int(hx + 1), int(hy - 1), 'eye')
    m.capsule((hx + 3.4, hy + 0.6, 3), (hx + 5.5 - t, hy + 1.2, 3), 0.3, 0.2, 'tongue')
    return m, mm


def scorpion(t):
    mm = M(shell=g([0x3a1c08, 0x6a3a14, 0xa06424, 0xd89c4c], spec=0.6), eye=glow(0x400000, 0xff3030))
    m = Model(28, 22)
    m.sphere((12, 15, 2), 6.0, 'shell', 1.2, 0.75, 1, rough(0.05))
    for k in range(3):                                                                       # legs
        for s in (-1, 1):
            x = 8 + k * 4
            m.capsule((x, 16, 0), (x - 2 + k, 20.5, 0), 0.7, 0.5, 'shell')
    for s in (-1, 1):                                                                         # pincers
        m.capsule((17, 15 + s * 1.5, 3), (22, 16 + s * 2.5, 4), 1.1, 1.0, 'shell')
        m.sphere((23.5, 16 + s * 2.5, 4.5), 1.7, 'shell', 1.3, 0.8, 1)
    tail = [(7, 14, 3), (3.5, 10, 4), (4, 5, 5), (8, 2.5 + t * 0.6, 6)]
    m.chain(tail, [1.8, 1.5, 1.2, 0.9], 'shell')
    spike(m, (8, 3), (11.5, 4.5 + t), 0.8, 6.5, 'shell')
    m.mark(16, 13, 'eye'); m.mark(16, 15, 'eye')
    return m, mm


def crab(t):
    mm = M(shell=g([0x5a0e08, 0x9a2414, 0xd8462a, 0xff8a60], spec=0.6), eye=glow(0x101010, 0x303030))
    m = Model(28, 22)
    m.sphere((14, 14, 2), 7.0, 'shell', 1.25, 0.7, 1, rough(0.04))
    for k in range(3):
        for s in (-1, 1):
            m.capsule((14 + s * (4 + k * 2), 16, 0), (14 + s * (7 + k * 2.2), 21, 0), 0.7, 0.5, 'shell')
    for s in (-1, 1):
        m.capsule((14 + s * 7, 12, 3), (14 + s * 10, 8 - t * s, 4), 1.1, 1.0, 'shell')
        m.sphere((14 + s * 10.5, 6.5 - t * s, 4.5), 2.4, 'shell', 1.0, 0.85, 1)
        m.capsule((14 + s * 2, 10, 4), (14 + s * 2.5, 7, 4), 0.4, 0.4, 'shell')
        m.sphere((14 + s * 2.5, 6.6, 4.5), 1.0, 'eye')
    return m, mm


def slime(t, col=(0x0a3a7a, 0x2a6ad0, 0x6aa8ff, 0xd0e8ff), big=False, crown_on=False):
    mm = M(gel=g(list(col), spec=0.9), core=glow(col[1], col[3]), eye=g([0x050510, 0x050510]), white=g([0xffffff, 0xffffff]))
    W, H = (34, 30) if big else (24, 20)
    m = Model(W, H)
    cx, base = W / 2, H - 2
    r = (W / 2 - 2) * (1 + t * 0.05)
    m.sphere((cx, base - r * 0.55, 1), r, 'gel', 1.0, 0.62 - t * 0.04, 0.9)
    m.sphere((cx - r * 0.3, base - r * 0.75, r * 0.5), r * 0.22, 'core')                    # a gleam
    for ex in (cx - r * 0.3, cx + r * 0.3):                                                  # two round eyes
        m.mark(int(ex), int(base - r * 0.6), 'white', 2, 2)
        m.mark(int(ex) + 1, int(base - r * 0.6) + 1, 'eye', 1, 1)
    if crown_on:
        crown(m, cx, base - r * 1.15, r * 0.45, 'gold', spikes=5, tall=4, z=4)
    return m, mm


# ================================================================== the lowlands
def goblin(t, chief=False):
    mm = M(skin=g([0x2a4a10, 0x4a7a1c, 0x78b030, 0xb0e070]), rag=g([0x3a2a14, 0x5e4422, 0x846232]), eye=glow(0xa06000, 0xffd040))
    m = Model(26, 26)
    hy = biped(m, 13, 13, 25, 3.4, 'rag', 'skin', 'skin', 'skin', 4.0)
    held(m, 'R')
    if chief:
        m.capsule((17.5, 19, 6), (22, 7 - t, 6), 0.7, 0.7, 'wood')                           # a spear
        spike(m, (22, 7.5 - t), (23.2, 3 - t), 1.2, 6.5, 'steel')
    else:
        m.capsule((17.5, 19, 6), (21, 12 - t, 6), 0.8, 0.4, 'steel')                          # a knife
    m.part(None)
    head(m, 13, hy, 4.0, 'skin')
    for s in (-1, 1):                                                                         # big pointed ears
        spike(m, (13 + s * 3, hy - 0.5), (13 + s * 7.5, hy - 2.5), 1.3, 4, 'skin')
    eyes(m, 13, int(hy), 1.5, 6, 'eye')
    if chief:
        crown(m, 13, hy - 3.5, 3.2, 'bone', spikes=4, tall=2.5, z=5)
    m.part(None)
    return m, mm


def hobbit(t):
    mm = M(skin=PALE, vest=g([0x2a4a1a, 0x3e6a26, 0x5e9038]), shirt=g([0x8a8070, 0xc0b8a0, 0xeee8d8]), hair=g([0x3a2410, 0x5e3c1c, 0x86582c]),
           pants=g([0x3a2a1a, 0x5a4026, 0x7a5a38]), eye=glow(0x101010, 0x302010))
    m = Model(22, 24)
    hy = biped(m, 11, 12, 23, 3.4, 'vest', 'pants', 'shirt', 'skin', 3.8)
    for s in (-1, 1):                                                                         # hairy bare feet
        m.sphere((11 + s * 2.2, 22, 2.5), 1.8, 'hair', 1.3, 0.6, 1)
    held(m, 'R')
    m.capsule((15.5, 18, 6), (19, 13 - t, 6), 0.6, 0.6, 'wood')                              # a sling-stick
    m.part(None)
    head(m, 11, hy, 3.8, 'skin')
    m.sphere((11, hy - 1.6, 2.5), 4.2, 'hair', 1.05, 0.8, 0.9, fur(0.08, 3))                 # curls
    eyes(m, 11, int(hy) + 1, 1.4, 6, 'eye')
    m.part(None)
    return m, mm


def bandit(t, leader=False):
    mm = M(skin=SKIN, cloak=g([0x1a1410, 0x2e2418, 0x463624, 0x5e4a32]), mask=g([0x2a0a0a, 0x4a1212, 0x6e1c1c]),
           pants=g([0x141418, 0x24242c, 0x383844]), eye=glow(0x404000, 0xffff80))
    m = Model(26, 30)
    hy = biped(m, 13, 13, 29, 4.0, 'cloak', 'pants', 'cloak', 'skin', 4.0)
    m.capsule((13, 13, -1), (13, 27, -1), 4.2, 6.2, 'cloak', folds(0.1, 3, 5), cut=27)       # the cloak behind
    held(m, 'R')
    m.capsule((18.5, 20, 6), (23, 13 - t, 6), 0.7, 0.35, 'steel')                             # a dagger
    m.part(None)
    if leader:
        held(m, 'L')
        m.capsule((7.5, 20, 6), (3.5, 13 + t, 6), 0.7, 0.35, 'steel')                       # and another
        m.part(None)
    head(m, 13, hy, 4.0, 'skin')
    hood(m, 13, hy - 0.5, 4.8, 'cloak', 'void')
    m.capsule((10, hy + 1.6, 7), (16, hy + 1.6, 7), 1.2, 1.2, 'mask')                       # a scarf over the face
    eyes(m, 13, int(hy) - 1, 1.5, 6, 'eye')
    if leader:
        m.sphere((13, hy - 4.6, 3), 6.4, 'mask', 1.0, 0.3, 0.8)                              # a wide hat
        m.sphere((13, hy - 6, 3), 3.4, 'mask', 1.1, 0.75, 0.8)
    m.part(None)
    return m, mm


def wolf(t):
    mm = M(fur=g([0x2a2a30, 0x4a4a56, 0x76768a, 0xb0b0c4]), eye=glow(0x806000, 0xffe040), nose=g([0x060608, 0x101014]))
    m = Model(30, 22)
    m.capsule((8, 11, 1), (20, 11, 1), 4.2, 4.6, 'fur', fur(0.1, 3))                          # body
    for x, s in ((9, -1), (11, 1), (19, -1), (21, 1)):                                        # legs, striding
        m.capsule((x, 13, 0.5 * s), (x + s * (1.2 - t * 2.4), 20, 0.5 * s), 1.2, 0.9, 'fur')
    m.chain([(5, 9, 0), (2.5, 6 - t, 0), (1.5, 3.5 - t, 0)], [1.8, 1.4, 0.8], 'fur', fur(0.1, 2))  # tail
    m.sphere((24, 8, 2), 3.6, 'fur', 1.0, 0.95, 1, fur(0.08, 2))                              # head
    m.capsule((26, 9.5, 2.5), (29, 10.5, 3), 1.8, 1.2, 'fur')                                 # muzzle
    m.sphere((29.2, 10.2, 3.5), 0.8, 'nose')
    spike(m, (22.5, 5.5), (21.5, 1.5), 1.2, 3, 'fur')
    spike(m, (25, 5.5), (25.5, 1.5), 1.2, 3, 'fur')
    m.mark(25, 7, 'eye')
    return m, mm


# ================================================================== the midlands
def orc(t, king=False):
    mm = M(skin=g([0x1e3a10, 0x34601c, 0x50882c, 0x7cb44a]), mail=g([0x2a2a30, 0x4a4a56, 0x76768a]), cloth=g([0x3a0e0a, 0x6a1a12, 0x9a2a1c]),
           eye=glow(0x800000, 0xff4020), tusk=BONE)
    W, H = (32, 32) if king else (28, 28)
    m = Model(W, H)
    cx = W / 2
    hy = biped(m, cx, 13, H - 1, 5.0 if king else 4.4, 'mail', 'cloth', 'skin', 'skin', 4.4)
    held(m, 'R')
    if king:
        m.capsule((cx + 6, 22, 6), (cx + 11, 6 - t, 6), 1.0, 1.0, 'wood')                    # a great axe
        m.sphere((cx + 11, 7 - t, 6.5), 3.2, 'steel', 1.2, 0.5, 0.6)
    else:
        m.capsule((cx + 5.5, 21, 6), (cx + 10, 12 - t, 6), 1.2, 0.8, 'wood')                 # a club
        m.sphere((cx + 10, 11.5 - t, 6.5), 1.9, 'wood', 1, 1, 1, rough(0.1))
    m.part(None)
    head(m, cx, hy, 4.4, 'skin')
    eyes(m, cx, int(hy), 1.6, 6, 'eye')
    for s in (-1, 1):
        spike(m, (cx + s * 1.6, hy + 2.6), (cx + s * 2.2, hy + 0.2), 0.7, 7, 'tusk')
    if king:
        crown(m, cx, hy - 3.6, 3.6, 'gold', spikes=5, tall=3, z=5)
        for s in (-1, 1):
            pauldron(m, cx + s * 6, 14, 3.2, 2.4, 4, 'steel', s, bevel=1.0)
    m.part(None)
    return m, mm


def gazer(t, big=False):
    mm = M(flesh=g([0x3a0a2a, 0x6a1a4c, 0xa0347a, 0xd060aa]), white=g([0xa0a0a8, 0xd8d8e0, 0xffffff]), iris=glow(0x601000, 0xff8020),
           pupil=VOID, stalk=g([0x4a1238, 0x7a2a5e, 0xa8487e]))
    W = 32 if big else 24
    m = Model(W, W)
    cx, cy = W / 2, W / 2 + (1 if big else 0) - t
    r = W / 2 - (5 if big else 3.5)
    if big:                                                                                   # eye-stalks round its crown
        for k in range(7):
            a = -math.pi * 0.95 + k * math.pi * 0.95 / 6 - math.pi * 0.025
            tip = (cx + math.cos(a) * (r + 5), cy + math.sin(a) * (r + 5))
            m.chain([(cx + math.cos(a) * r * 0.8, cy + math.sin(a) * r * 0.8, 0), (tip[0], tip[1] + 1, 0)], [1.0, 0.7], 'stalk')
            m.sphere((tip[0], tip[1], 1), 1.3, 'white')
            m.mark(int(tip[0]), int(tip[1]), 'iris')
    m.sphere((cx, cy, 1), r, 'flesh', 1.0, 1.0, 1.0, rough(0.04))
    m.sphere((cx, cy, r * 0.75), r * 0.66, 'white')
    m.sphere((cx + 0.4, cy, r * 1.2), r * 0.36, 'iris')
    m.sphere((cx + 0.6, cy, r * 1.45), r * 0.17, 'pupil')
    if big:                                                                                   # a fanged maw below
        m.capsule((cx - 4, cy + r * 0.72, r * 0.6), (cx + 4, cy + r * 0.72, r * 0.6), 1.0, 1.0, 'void')
        for k in range(4):
            spike(m, (cx - 3 + k * 2, cy + r * 0.62), (cx - 3 + k * 2, cy + r * 0.9), 0.6, r, 'white')
    return m, mm


def spider(t, queen=False):
    mm = M(chitin=g([0x0a0a0e, 0x1c1c26, 0x343446, 0x5a5a74], spec=0.5), mark=g([0x6a0a0a, 0xb01818, 0xe83030]), eye=glow(0x800000, 0xff3030))
    W, H = (34, 26) if queen else (26, 20)
    m = Model(W, H)
    cx, cy = W / 2, H / 2 + 1
    rb = 6.4 if queen else 4.8
    for k in range(4):                                                                        # eight legs, jointed
        for s in (-1, 1):
            a = (k - 1.5) * 0.45
            kx, ky = cx + s * (rb + 2.5), cy - 3 + k * 2.2 + a
            fx = cx + s * (rb + 6.5 + (k % 2) * 1.2 * (1 - 2 * t))
            m.chain([(cx + s * 2, cy, 0), (kx, ky - 3, 1), (fx, H - 1.5, 0)], [0.9, 0.8, 0.5], 'chitin')
    m.sphere((cx - rb * 0.6, cy, 1), rb, 'chitin', 1.05, 0.9, 1)                              # abdomen
    m.sphere((cx - rb * 0.6, cy - 1, rb * 0.85), rb * 0.36, 'mark', 1, 1.4, 1)              # its red mark
    m.sphere((cx + rb * 0.6, cy + 0.5, 2), rb * 0.62, 'chitin')                             # head
    for k in range(3):
        m.mark(int(cx + rb * 0.6 + k - 1), int(cy - 0.5 + (k % 2)), 'eye')
    if queen:
        crown(m, cx + rb * 0.6, cy - rb * 0.55, 2.4, 'gold', spikes=3, tall=2.2, z=4)
    return m, mm


# ================================================================== the highlands
def golem(t):
    mm = M(stone=g([0x2a2622, 0x4a443c, 0x76705e, 0xa8a088], facet=7), dark=g([0x1a1714, 0x2e2a24, 0x48423a]), moss=g([0x1a3a10, 0x2e5a1c, 0x4a8030]),
           rune=glow(0x0a5a8a, 0x40c0ff, 0xc0f0ff))
    m = Model(30, 30)
    for s in (-1, 1):                                                                         # stumpy legs
        m.capsule((15 + s * 3.6, 21, 0), (15 + s * 4, 27, 0), 2.8, 2.6, 'dark', rough(0.08))
        m.sphere((15 + s * 4.2, 28, 1), 3.0, 'stone', 1.2, 0.5, 1)
    m.sphere((15, 15, 1), 8.0, 'stone', 1.05, 0.95, 0.8, rough(0.07, 0.4, 5))                 # one great boulder of a body
    for s in (-1, 1):
        m.sphere((15 + s * 8, 11, 2), 3.8, 'stone', 1, 0.9, 1, rough(0.08, 0.4, 7 + s))        # shoulders
        m.capsule((15 + s * 9.5, 13, 3), (15 + s * 10.5, 19 - t, 4), 2.4, 2.2, 'dark', rough(0.08))  # arms
        m.sphere((15 + s * 10.5, 20.5 - t, 4.5), 3.0, 'stone', 1, 0.95, 1, rough(0.08, 0.4, 11 + s))  # fists
    m.sphere((15, 6.5, 3), 3.4, 'stone', 1.1, 0.85, 1, rough(0.06))                           # a small head sunk in
    m.mark(13, 6, 'rune'); m.mark(17, 6, 'rune')
    for x, y in ((15, 13), (15, 14), (15, 15), (14, 14), (16, 14), (12, 17), (18, 17)):          # a rune carved in its chest
        m.mark(x, y, 'rune')

    def moss(x, y, h):
        return 'moss' if h[2] == 'stone' and vnoise(x * 0.45, y * 0.45, 5) > 0.86 and y < 12 else None
    m.paint(moss)
    return m, mm


def harpy(t):
    mm = M(skin=PALE, feather=g([0x3a2a1a, 0x6a4a2a, 0x9a7040, 0xc8a070]), hair=g([0x2a0e0a, 0x4a1c14, 0x6e2e20]), talon=BONE,
           eye=glow(0x806000, 0xffe040))
    m = Model(30, 26)
    for s in (-1, 1):
        wing(m, (15 + s * 3, 10), (s * 0.9, -0.4 + t * 0.5), 11, 'feather', 'feather', 0, n=4, droop=0.45, side=s)
    m.part(None)
    m.capsule((15, 10, 2), (15, 17, 2), 2.8, 2.2, 'feather', fur(0.1, 3))
    for s in (-1, 1):
        m.capsule((15 + s * 1.5, 17, 2), (15 + s * 2, 22, 3), 0.9, 0.7, 'talon')
        spike(m, (15 + s * 2, 22), (15 + s * 3.4, 24), 0.6, 3, 'talon')
    head(m, 15, 6.5, 3.2, 'skin')
    m.capsule((12, 5, 1), (11, 11, 0), 1.8, 1.0, 'hair')
    m.capsule((18, 5, 1), (19, 11, 0), 1.8, 1.0, 'hair')
    m.sphere((15, 4.5, 2), 3.4, 'hair', 1.05, 0.7, 0.9)
    eyes(m, 15, 7, 1.3, 6, 'eye')
    m.part(None)
    return m, mm


def dwarf(t, king=False):
    mm = M(skin=SKIN, beard=g([0x5a2a0e, 0x8a4418, 0xc06a2a]) if not king else g([0x7a7a80, 0xb0b0b8, 0xe8e8f0]),
           tunic=g([0x1a2a5a, 0x2a3e86, 0x3e5ab8]), boots=LEATHER, eye=glow(0x101010, 0x302010))
    W = 30 if king else 26
    m = Model(W, 28)
    cx = W / 2
    hy = biped(m, cx, 13, 27, 5.0 if king else 4.4, 'tunic', 'boots', 'tunic', 'skin', 3.8)
    if king:
        chest(m, cx, 12, 20, 5.4, 5.0, 4, 'steel', bevel=1.6)
    held(m, 'R')
    m.capsule((cx + 5, 21, 6), (cx + 8.5, 11 - t, 6), 0.8, 0.8, 'wood')                       # a hammer
    m.capsule((cx + 6.5, 10.5 - t, 6.5), (cx + 10.5, 11.5 - t, 6.5), 1.8, 1.8, 'steel')
    m.part(None)
    head(m, cx, hy, 3.8, 'skin')
    eyes(m, cx, int(hy) - 1, 1.4, 6, 'eye')
    m.capsule((cx, hy + 1.8, 5), (cx, hy + 7, 5.5), 3.4, 1.4, 'beard', fur(0.1, 2))         # the beard, to his belt
    m.sphere((cx, hy - 2.4, 3.5), 4.0, 'steel' if not king else 'gold', 1.0, 0.7, 1.0)     # helm
    if king:
        crown(m, cx, hy - 4.6, 3, 'gold', spikes=5, tall=2.4, z=5)
    else:
        for s in (-1, 1):
            spike(m, (cx + s * 3.6, hy - 2.6), (cx + s * 6, hy - 5.6), 0.9, 4, 'bone')      # horns on the helm
    m.part(None)
    return m, mm


def elf(t):
    mm = M(skin=PALE, cloak=g([0x0e3a1a, 0x1a5a2a, 0x2e8040, 0x4aa85a]), hair=g([0x8a7020, 0xc8a840, 0xf0d870]), eye=glow(0x106040, 0x60ffb0))
    m = Model(24, 30)
    hy = biped(m, 12, 13, 29, 3.4, 'cloak', 'leather', 'cloak', 'skin', 3.6)
    m.capsule((12, 13, -1), (12, 27, -1), 3.8, 5.6, 'cloak', folds(0.1, 3, 7), cut=27)
    held(m, 'L')                                                                              # a longbow
    m.chain([(4.5, 9, 6), (2.5, 17, 6), (4.5, 25, 6)], [0.6, 0.7, 0.6], 'wood')
    m.capsule((4.5, 9, 6), (4.5 + t, 25, 6), 0.2, 0.2, 'bone')
    m.part(None)
    head(m, 12, hy, 3.6, 'skin')
    m.capsule((9, hy - 2, 2), (8.5, hy + 5, 1), 1.6, 1.2, 'hair')                             # long golden hair
    m.capsule((15, hy - 2, 2), (15.5, hy + 5, 1), 1.6, 1.2, 'hair')
    m.sphere((12, hy - 1.8, 2.5), 3.8, 'hair', 1.0, 0.7, 0.9)
    for s in (-1, 1):
        spike(m, (12 + s * 3, hy), (12 + s * 6, hy - 2), 0.8, 4, 'skin')
    eyes(m, 12, int(hy) + 1, 1.3, 6, 'eye')
    m.part(None)
    return m, mm


def ogre(t):
    mm = M(skin=g([0x4a3a1a, 0x7a6230, 0xa68a48, 0xd0b46a]), loin=LEATHER, eye=glow(0x600000, 0xff3020), tooth=BONE)
    m = Model(32, 32)
    legs(m, 16, 20, 31, 3.4, 3.0, 'skin')
    m.sphere((16, 17, 2), 8.0, 'skin', 1.05, 1.0, 0.9, rough(0.04))                          # a great gut
    m.capsule((10, 22, 5), (22, 22, 5), 1.6, 1.6, 'loin')
    for s in (-1, 1):
        arm(m, (16 + s * 7, 11, 2), (16 + s * 10.5, 17, 3), (16 + s * 10.5, 22, 4.5), 2.4, 'skin', 'skin', 2.2)
    held(m, 'R')
    m.chain([(26.5, 22, 6), (28, 14 - t, 6), (29, 7 - t, 6)], [1.2, 1.8, 2.4], 'wood', rough(0.1))  # a tree-trunk club
    m.part(None)
    head(m, 16, 7, 4.2, 'skin')
    eyes(m, 16, 6, 1.4, 6, 'eye')
    m.sphere((16, 10, 5.5), 2.2, 'skin', 1.5, 0.7, 0.7)
    spike(m, (14.5, 10.5), (14.2, 8.6), 0.6, 7.5, 'tooth')
    spike(m, (17.5, 10.5), (17.8, 8.6), 0.6, 7.5, 'tooth')
    m.part(None)
    return m, mm


def minotaur(t):
    mm = M(fur=g([0x2a160a, 0x4a2a14, 0x6e4220, 0x946038]), horn=g([0x8a8070, 0xc8c0a8, 0xf4f0e0]), eye=glow(0x800000, 0xff3020),
           ring=GOLD, loin=g([0x3a0e0a, 0x6a1a12, 0x9a2a1c]))
    m = Model(32, 32)
    hy = biped(m, 16, 13, 31, 5.4, 'fur', 'fur', 'fur', 'fur', 4.6)
    m.capsule((10.5, 20, 6), (21.5, 20, 6), 1.4, 1.4, 'loin')
    held(m, 'R')                                                                              # a double axe
    m.capsule((22, 22, 6), (25, 7 - t, 6), 0.8, 0.8, 'wood')
    for s in (-1, 1):
        m.sphere((25 + s * 2.4, 8 - t, 6.5), 2.6, 'steel', 0.6, 1.2, 0.5)
    m.part(None)
    head(m, 16, hy, 4.6, 'fur')
    m.capsule((16, hy + 1.5, 6), (16, hy + 3.4, 6.5), 2.4, 2.0, 'fur')                     # the bull's muzzle
    m.capsule((14.6, hy + 3.6, 8), (17.4, hy + 3.6, 8), 0.5, 0.5, 'ring')
    eyes(m, 16, int(hy) - 1, 2.0, 6, 'eye')
    for s in (-1, 1):
        m.chain([(16 + s * 3.5, hy - 2.5, 4), (16 + s * 7.5, hy - 3.5, 4), (16 + s * 8.5, hy - 7.5, 4)], [1.3, 0.9, 0.4], 'horn')
    m.part(None)
    return m, mm


# ================================================================== the Godlands
def medusa(t):
    mm = M(skin=g([0x2a4a3a, 0x467a5e, 0x6aa884, 0x9ad4b0]), scale=g([0x0e3a2a, 0x1a5a3e, 0x2e8058], spec=0.6), gold=GOLD,
           eye=glow(0xa06000, 0xffe040), snake=g([0x1a4a10, 0x2e7a1c, 0x58b038]))
    m = Model(28, 30)
    m.chain([(14, 16, 0), (16, 22, 0), (12, 27, 0), (18, 28.5, 0), (24, 27, 0)], [3.6, 3.4, 2.6, 1.8, 0.8], 'scale', scales(0.08, 1.4))  # a serpent's tail
    m.capsule((14, 10, 1), (14, 17, 1), 3.4, 3.0, 'skin')
    m.capsule((11, 11.5, 4.5), (17, 11.5, 4.5), 1.0, 1.0, 'gold')
    for s in (-1, 1):
        arm(m, (14 + s * 3.2, 11, 1.5), (14 + s * 5.5, 14, 2.5), (14 + s * 6, 17 - t * s, 4), 1.1, 'skin', 'skin', 1.0)
    head(m, 14, 6.5, 3.4, 'skin')
    for k in range(7):                                                                        # her hair of snakes
        a = -math.pi + k * math.pi / 6
        x0, y0 = 14 + math.cos(a) * 3, 6 + math.sin(a) * 3
        m.chain([(x0, y0, 2), (x0 + math.cos(a) * 3, y0 + math.sin(a) * 3 - 1, 2), (x0 + math.cos(a) * 4.5 + (t if k % 2 else -t), y0 + math.sin(a) * 4.5 - 2.5, 2)],
                [0.9, 0.7, 0.8], 'snake')
    eyes(m, 14, 7, 1.4, 6, 'eye')
    m.part(None)
    return m, mm


def djinn(t):
    mm = M(skin=g([0x1a2a7a, 0x2a44b0, 0x4a6ae0, 0x90b0ff]), smoke=glow(0x1a2a7a, 0x4a6ae0, 0xa0c0ff, base=0.3), gold=GOLD,
           cloth=g([0x6a0a3a, 0x9a1456, 0xd02a7a]), eye=glow(0xa06000, 0xffff80))
    m = Model(28, 32)
    m.chain([(14, 18, 0), (13, 24, 0), (16, 28, 0), (14 + t, 31, 0)], [3.6, 2.6, 1.6, 0.6], 'smoke')   # a tail of smoke
    m.capsule((14, 9, 1), (14, 18, 1), 4.6, 3.6, 'skin', rough(0.04))
    m.capsule((10, 16.5, 4.6), (18, 16.5, 4.6), 1.6, 1.6, 'cloth')
    for s in (-1, 1):
        arm(m, (14 + s * 4.4, 10, 1.5), (14 + s * 8, 12, 2.5), (14 + s * 7.5, 16 - t, 4), 1.5, 'skin', 'skin', 1.3)
        m.sphere((14 + s * 7.5, 13.5, 4.5), 1.0, 'gold', 1.4, 0.5, 1)                        # bracers
    head(m, 14, 5, 3.4, 'skin')
    m.sphere((14, 2.6, 3), 3.8, 'cloth', 1.0, 0.65, 0.9)                                      # a turban
    m.sphere((14, 1.8, 6.5), 0.9, 'gold')
    eyes(m, 14, 5, 1.3, 6, 'eye')
    m.capsule((14, 7.5, 6), (14, 10, 6), 0.8, 0.3, 'void')                                    # a forked beard
    m.part(None)
    return m, mm


def ent(t):
    mm = M(bark=g([0x1e140a, 0x3a2614, 0x5a3e22, 0x7e5a34], facet=8), leaf=g([0x0e3a10, 0x1a5a1c, 0x2e842c, 0x56b040]),
           eye=glow(0x408000, 0xd0ff60))
    m = Model(32, 34)
    for s in (-1, 1):                                                                         # root feet
        m.chain([(16 + s * 2, 26, 0), (16 + s * 5, 31, 0), (16 + s * 8, 33, 0)], [2.4, 1.6, 0.8], 'bark')
    m.capsule((16, 12, 1), (16, 28, 1), 4.6, 5.4, 'bark', rough(0.1, 0.4, 3))
    for s in (-1, 1):                                                                         # branch arms
        m.chain([(16 + s * 4, 15, 2), (16 + s * 9, 13 - t, 3), (16 + s * 12, 8 - t, 3)], [1.6, 1.2, 0.6], 'bark')
        m.sphere((16 + s * 12, 7 - t, 2), 3.2, 'leaf', 1, 0.9, 1, rough(0.12, 0.3, 5))
    m.sphere((16, 7, 0), 8.0, 'leaf', 1.15, 0.85, 0.9, rough(0.14, 0.3, 9))                  # its crown of leaves
    m.mark(14, 17, 'eye'); m.mark(18, 17, 'eye')
    m.capsule((14, 21, 6), (18, 21, 6), 0.6, 0.6, 'void')
    return m, mm


def beholder(t):
    return gazer(t, big=True)


def lich(t):
    mm = M(robe=g([0x14081e, 0x261038, 0x3e1a5a, 0x5a2a80]), trim=GOLD, skull=BONE, eye=glow(0x0a6a2a, 0x40ff80, 0xe0ffe0),
           orb=glow(0x0a6a2a, 0x40ff80, 0xffffff))
    m = Model(28, 32)
    robe(m, 14, 11, 31, 4.2, 7.4, 'robe', trim='trim', seed=4)
    for s in (-1, 1):
        arm(m, (14 + s * 4, 12, 1.5), (14 + s * 7, 16, 3), (14 + s * 7, 20, 5), 1.4, 'robe', 'skull', 1.0)
    staff(m, 21, 4 - t, 30, 'bone', z=6, r=0.6)
    m.sphere((21, 3.5 - t, 6.5), 1.8, 'orb')
    m.part(None)
    head(m, 14, 8, 3.4, 'skull')
    hood(m, 14, 7.2, 4.4, 'robe', 'void')
    m.sphere((14, 8.6, 5), 2.6, 'skull', 0.95, 1.0, 0.6)
    eyes(m, 14, 8, 1.2, 6, 'eye')
    crown(m, 14, 3.4, 3.2, 'trim', spikes=5, tall=2.4, z=4)
    m.part(None)
    return m, mm


def ghost_god(t):
    mm = M(shroud=glow(0x2a2a5a, 0x6a6ab0, 0xc8c8ff, base=0.35), eye=glow(0x400000, 0xff2020), crown=GOLD)
    m = Model(30, 32)
    bob = t
    m.chain([(15, 8 + bob, 0), (15, 18 + bob, 0), (17, 26 + bob, 0), (13, 31, 0)], [6.6, 7.2, 4.2, 1.0], 'shroud', rough(0.05))
    for s in (-1, 1):
        m.chain([(15 + s * 5, 14 + bob, 1), (15 + s * 10, 18 + bob - t, 2), (15 + s * 12, 22 + bob, 2)], [2.0, 1.4, 0.6], 'shroud')
    m.sphere((15, 10 + bob, 5.5), 3.6, 'void', 0.95, 1.2, 0.6)
    m.mark(13, int(9 + bob), 'eye'); m.mark(17, int(9 + bob), 'eye')
    crown(m, 15, 3.6 + bob, 4, 'crown', spikes=5, tall=3, z=4)
    return m, mm


def demon(t):
    mm = M(skin=g([0x3a0606, 0x6a0e0a, 0xa01e12, 0xd8402a]), horn=g([0x0a0806, 0x1e1810, 0x3a3020]), wingm=g([0x1e0404, 0x3a0a08, 0x5a1410]),
           eye=glow(0x806000, 0xffe040), fire=glow(0xa02a00, 0xff8a20, 0xfff0a0))
    m = Model(34, 32)
    for s in (-1, 1):
        wing(m, (17 + s * 3, 11), (s * 0.85, -0.5 + t * 0.4), 12, 'wingm', 'horn', -1, n=4, droop=0.4, side=s)
    m.part(None)
    hy = biped(m, 17, 12, 31, 5.0, 'skin', 'skin', 'skin', 'skin', 4.2)
    held(m, 'R')                                                                              # a flaming trident
    m.capsule((23, 22, 6), (26, 5 - t, 6), 0.7, 0.7, 'horn')
    for k in (-1, 0, 1):
        spike(m, (26 + k * 1.6, 6 - t), (26 + k * 2.2, 2.4 - t - (k == 0)), 0.6, 6.5, 'fire')
    m.part(None)
    head(m, 17, hy, 4.2, 'skin')
    eyes(m, 17, int(hy), 1.6, 6, 'eye')
    for s in (-1, 1):
        m.chain([(17 + s * 3, hy - 2.5, 4), (17 + s * 6, hy - 4.5, 4), (17 + s * 5.5, hy - 8, 4)], [1.2, 0.8, 0.3], 'horn')
    m.part(None)
    return m, mm


def sprite_god(t):
    mm = M(light=glow(0xa02a8a, 0xff70d0, 0xffd0f4, 0xffffff, base=0.3), wingc=glow(0x4a3aa0, 0x9a8ae0, 0xe0dcff, base=0.3), crown=GOLD)
    m = Model(30, 28)
    for s in (-1, 1):
        for k in (0, 1):
            m.sphere((15 + s * (7 + k * 2), 10 + k * 7 - t * (1 - k), 0), 6.0 - k * 1.8, 'wingc', 0.8, 1.1 - k * 0.2, 0.3)
    m.sphere((15, 14, 2), 5.0 + t * 0.4, 'light')
    m.sphere((15, 14, 6), 2.4, 'light')
    crown(m, 15, 8, 3, 'crown', spikes=5, tall=2.6, z=5)
    return m, mm


def slime_god(t):
    return slime(t, col=(0x0a4a1a, 0x1e8a3a, 0x5ad070, 0xd0ffd8), big=True, crown_on=True)


MODELS = [
    ('pirate', pirate), ('pirate_brawler', pirate_brawler), ('pirate_captain', lambda t: pirate(t, 0x1a2a6a, captain=True)),
    ('snake', snake), ('great_snake', lambda t: snake(t, big=True)), ('scorpion', scorpion), ('crab', crab),
    ('slime', slime), ('green_slime', lambda t: slime(t, col=(0x0a4a1a, 0x1e8a3a, 0x5ad070, 0xd0ffd8))),
    ('goblin', goblin), ('goblin_chief', lambda t: goblin(t, chief=True)), ('hobbit', hobbit),
    ('bandit', bandit), ('bandit_leader', lambda t: bandit(t, leader=True)), ('wolf', wolf),
    ('orc', orc), ('orc_king', lambda t: orc(t, king=True)), ('gazer', gazer), ('spider', spider),
    ('spider_queen', lambda t: spider(t, queen=True)),
    ('golem', golem), ('harpy', harpy), ('dwarf', dwarf), ('dwarf_king', lambda t: dwarf(t, king=True)), ('elf', elf),
    ('ogre', ogre), ('minotaur', minotaur),
    ('medusa', medusa), ('djinn', djinn), ('ent', ent), ('beholder', beholder), ('lich', lich), ('ghost_god', ghost_god),
    ('demon', demon), ('sprite_god', sprite_god), ('slime_god', slime_god),
]


def all_designs():
    return designs(MODELS)


if __name__ == '__main__':
    import sys
    sheet(MODELS, sys.argv[1], 4)
