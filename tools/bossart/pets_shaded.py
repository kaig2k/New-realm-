"""
The pets, shaded from solids like the monsters (they were 8x8 drawings): six species and each one's
two Adult paths (Data.PET_SKILLS), small and cute, drawn at 2x so a pet stays smaller than its hero.
Pet skins wash every colour (Sprites.cosmeticDef) and an Ascended pet is its form, brighter, so any
palette works.

    python3 tools/bossart/pets_shaded.py preview.png
"""
import math
from sdfart import Model, rough, fur
from shaded_kit import g, glow, designs, sheet, spike

EYE_BLACK = g([0x08080c, 0x14141c])
SHINE = g([0xd0d8ff, 0xffffff])
GOLD = g([0x7a5a10, 0xc89a28, 0xffe070, 0xfff8c8], spec=0.8)
STONE = g([0x3a3832, 0x5e5a50, 0x8a8476, 0xb8b2a2])


def eyes2(m, x, y, gap, mat='eye', big=False):
    """Two bright pet eyes, with a glint."""
    for ex in (x, x + gap):
        m.mark(int(ex), int(y), mat, 2 if big else 1, 2 if big else 1)
        m.mark(int(ex), int(y), 'shine', 1, 1)


# ---------------------------------------------------------------- the pup: Treasure Hound / Warhound
def pup(t, furc=(0x6a4a20, 0x9a7036, 0xc89a5a, 0xecc890), collar=None, spikes=False, eye='eye', grin=False):
    mm = {'fur': g(list(furc)), 'nose': EYE_BLACK, 'eye': EYE_BLACK, 'shine': SHINE, 'red': glow(0x800000, 0xff3030),
          'collar': collar or GOLD, 'teeth': g([0xc8c8c8, 0xffffff])}
    m = Model(22, 18)
    m.capsule((7, 11, 1), (13, 11.5, 1), 3.6, 3.8, 'fur', fur(0.1, 2))                      # body
    for x, s in ((8, -1), (12.5, 1)):                                                      # front and back legs
        m.capsule((x, 13, 2), (x + s * (0.6 - t), 16.5, 2), 1.3, 1.1, 'fur')
    m.chain([(5, 10, 0), (3, 7 - t, 0), (3.5, 5 - t, 0)], [1.3, 1.1, 0.7], 'fur')             # wagging tail
    m.sphere((15.5, 7.5, 3), 4, 'fur', 1.0, 0.95, 1, fur(0.08, 2))                            # head
    m.capsule((17.5, 9, 3.5), (20, 9.5, 4), 1.9, 1.4, 'fur')                                  # muzzle
    m.sphere((20.3, 9, 4.5), 0.8, 'nose')
    m.chain([(13.5, 5, 3), (12, 7, 3), (12, 9.5, 3)], [1.5, 1.3, 0.9], 'fur')                 # floppy ear
    if spikes:
        spike(m, (14.5, 4.2), (13.5, 0.5), 1.1, 3, 'fur'); spike(m, (17, 4.2), (17.5, 0.5), 1.1, 3, 'fur')
    if collar is not None or spikes:
        m.capsule((13.5, 11, 4), (17, 11.5, 4), 0.9, 0.9, 'collar')
        if spikes:
            for x in (14, 15.5, 17):
                spike(m, (x, 11.5), (x, 13.5), 0.5, 5, 'teeth')
        else:
            m.sphere((15.5, 12.3, 5), 0.9, 'collar')                                           # the tag
    if grin:
        m.mark(18, 11, 'teeth', 2, 1)
    m.mark(16, 7, eye, 1, 2)
    m.mark(16, 7, 'shine', 1, 1)
    return m, mm


# ---------------------------------------------------------------- the slime: Royal Jelly / Acid Ooze
def slime(t, col=(0x10407a, 0x2878c0, 0x50b8ff, 0xc0ecff), crown=False, acid=False):
    mm = {'jelly': g(list(col), spec=0.9), 'eye': EYE_BLACK, 'shine': SHINE, 'gold': GOLD,
          'gem': glow(0x800020, 0xff3060), 'drip': g(list(col[1:]), spec=0.9), 'bubble': g([0xd0ffb0, 0xf8fff0])}
    m = Model(20, 18)
    sq = 1 - t * 0.12
    m.sphere((10, 12.5 - (1 - sq) * 3, 2), 7.5, 'jelly', 1.0, 0.72 * sq, 1)                    # the blob
    m.sphere((7, 8.5, 6), 1.6, 'shine', 1.3, 0.7, 1)                                          # a glossy highlight
    if acid:
        for x, y, r in ((4, 15.5, 1.2), (15, 16, 1.0), (10, 17, 0.9)):
            m.capsule((x, y - 1, 3), (x, y + 0.5, 3), r, r * 0.6, 'drip')
        for x, y in ((13, 8), (6, 11)):
            m.sphere((x, y - t, 7), 0.9, 'bubble')
        for x in (5, 9, 13):
            spike(m, (x, 8 + abs(x - 9) * 0.4), (x + 0.5, 5 + abs(x - 9) * 0.4), 1.2, 3, 'jelly')
    if crown:
        m.capsule((7, 6.5, 4), (13, 6.5, 4), 0.8, 0.8, 'gold')
        for x in (7, 10, 13):
            spike(m, (x, 6.2), (x, 3.5 if x == 10 else 4.5), 0.9, 4, 'gold')
        m.sphere((10, 6.2, 5), 0.7, 'gem')
    eyes2(m, 7.5, 11, 4, big=True)
    return m, mm


# ---------------------------------------------------------------- the owl: Seer / Hunter Owl
def owl(t, feath=(0x3a2414, 0x6a4626, 0x9a6e44, 0xc8a070), belly=(0x9a8060, 0xd8c0a0, 0xf4e8d4), eye=None, gem=False, talons=False):
    mm = {'feath': g(list(feath)), 'belly': g(list(belly)), 'beak': GOLD, 'ring': g([0xc89a28, 0xffe070]),
          'eye': eye or EYE_BLACK, 'shine': SHINE, 'gem': glow(0x1060c0, 0x60d0ff, 0xe0ffff), 'claw': g([0x3a3020, 0x6a5a40])}
    m = Model(20, 20)
    m.sphere((10, 12, 1), 6, 'feath', 1.0, 1.05, 1)                                            # body
    m.sphere((10, 13.5, 4), 4, 'belly', 1.0, 1.1, 0.8)
    for s in (-1, 1):                                                                         # wings folded, flapping a little
        m.sphere((10 + s * 5.5, 12 + t * 0.6, 2), 2.4, 'feath', 0.8, 1.6, 1)
    m.sphere((10, 6.5, 3), 4.8, 'feath', 1.1, 0.95, 1)                                         # head
    for s in (-1, 1):
        spike(m, (10 + s * 3.2, 3.5), (10 + s * 4.2, 1.2), 1.3, 3, 'feath')                   # ear tufts
        m.sphere((10 + s * 2.1, 6.5, 6), 1.8, 'ring')                                         # the eye discs
    m.capsule((10, 8, 7), (10, 9.5, 7), 0.8, 0.3, 'beak')
    if gem:
        m.sphere((10, 4, 7), 0.8, 'gem')
    for s in (-1, 1):
        m.mark(int(10 + s * 2.1 - 0.5), 6, 'eye', 2, 2)
        m.mark(int(10 + s * 2.1 - 0.5), 6, 'shine', 1, 1)
    if talons:
        for x in (8, 12):
            m.capsule((x, 17.5, 3), (x, 19, 3), 0.6, 0.3, 'claw')
    return m, mm


# ---------------------------------------------------------------- the drake: Inferno Wyrm / Ash Guardian
def drake(t, scale=(0x6a1a08, 0xb03a10, 0xe8682a, 0xffa860), wing=(0x8a2a10, 0xd0602a, 0xffa860), flame=False, armour=False):
    mm = {'scale': g(list(scale), spec=0.5), 'wing': g(list(wing)), 'belly': g([0xc88a30, 0xf0c060, 0xfff0b0]),
          'horn': g([0x5a4a30, 0xd8c8a0]), 'eye': glow(0x806000, 0xffe040), 'shine': SHINE,
          'fire': glow(0xc02000, 0xff7020, 0xffe060, 0xfffff0), 'plate': STONE, 'crack': glow(0x802000, 0xff8020)}
    m = Model(22, 20)
    for s, z in ((-1, -1), (1, 4)):                                                           # wings, beating
        a = -0.5 - t * 0.6
        m.membrane([(9, 9), (9 + s * 2 - 6 * math.cos(a), 9 + 6 * math.sin(a)), (5 + s, 12)], z, 'wing', (0.2, -0.3))
    m.capsule((8, 13, 2), (13, 13.5, 2), 3.2, 3.4, 'scale')                                    # body
    m.sphere((11, 14.5, 5), 2.2, 'belly', 1.2, 0.8, 0.7)
    for x in (9, 13):
        m.capsule((x, 15, 3), (x, 17.5, 3), 1.1, 0.9, 'scale')
    m.chain([(5, 14, 1), (2.5, 13 - t, 1), (1.5, 10 - t, 1)], [1.6, 1.1, 0.6], 'scale')        # tail
    if flame:
        m.sphere((1.5, 9 - t, 2), 1.4, 'fire', 0.8, 1.3, 1)
    m.sphere((15.5, 8.5, 4), 3.2, 'scale', 1.1, 0.95, 1)                                       # head
    m.capsule((17, 9.5, 4.5), (19.8, 10, 5), 1.7, 1.2, 'scale')                                # snout
    spike(m, (14.5, 6), (12.5, 3), 0.9, 4, 'horn'); spike(m, (16.5, 6), (16, 2.8), 0.9, 4, 'horn')
    if armour:
        for x, y in ((9, 11), (12, 11)):
            m.sphere((x, y, 4.5), 1.6, 'plate', 1.1, 0.8, 0.6)
        m.mark(10, 12, 'crack', 1, 1); m.mark(13, 13, 'crack', 1, 1)
    if flame:
        m.sphere((20.5, 10.5, 5), 0.9, 'fire')
    m.mark(16, 8, 'eye', 1, 1)
    return m, mm


# ---------------------------------------------------------------- the wisp: Arcane Wisp / Storm Wisp
def wisp(t, core=(0x1a6a8a, 0x40c0e0, 0xa8f4ff, 0xffffff), spark=None, crystal=False, bolts=False):
    # (a coloured body with a bright heart, not one glare of white, so its face and colour read)
    mm = {'core': g([core[0], core[1], core[2]], spec=0.6), 'heart': glow(core[1], core[2], core[3], base=0.5), 'eye': EYE_BLACK, 'shine': SHINE,
          'spark': glow(*(spark or core[1:]), base=0.5), 'crystal': g([0x4a1a8a, 0x8a4ad0, 0xd0a0ff, 0xf8e8ff], spec=1.0),
          'bolt': glow(0xa08000, 0xffe040, 0xffffd0)}
    m = Model(18, 20)
    bob = math.sin(t * math.pi) * 0.8
    m.sphere((9, 11 + bob, 3), 4.6, 'core')                                                   # the flame's body
    for k in range(3):                                                                         # its flickering top
        x = 7 + k * 2
        m.capsule((x, 8 + bob, 3), (x + (k - 1) * 0.6, 3 + abs(k - 1) * 2 + bob - t, 3), 1.6 - abs(k - 1) * 0.4, 0.3, 'core')
    m.capsule((8, 15 + bob, 2), (7, 18.5 + bob, 2), 1.4, 0.3, 'core')                          # its trailing tail
    m.sphere((8, 10 + bob, 5.5), 2.2, 'heart', 1.1, 0.9, 0.6)                                    # its bright heart
    if crystal:
        for a in (0.4, 2.5, 4.4):
            x, y = 9 + math.cos(a + t) * 7, 11 + math.sin(a + t) * 4
            spike(m, (x, y + 1.2), (x, y - 1.6), 0.9, 6, 'crystal')
    if bolts:
        for x0, y0 in ((2, 6), (15, 13)):
            m.chain([(x0, y0, 6), (x0 + 1, y0 + 1.5, 6), (x0 - 0.5, y0 + 2.5, 6), (x0 + 0.5, y0 + 4, 6)], [0.5, 0.5, 0.5, 0.3], 'bolt')
    for k, (x, y) in enumerate(((3, 4), (15, 6), (2, 15))):
        m.mark(x, int(y + bob * (1 if k % 2 else -1)), 'spark', 1, 1)
    eyes2(m, 6, int(11 + bob), 4)
    return m, mm


# ---------------------------------------------------------------- the golem: Bastion / Boulder
def golem(t, stone=(0x3a3832, 0x5e5a50, 0x8a8476, 0xb8b2a2), eye=(0x0a6a3a, 0x40ff90), moss=False, shield=False):
    mm = {'stone': g(list(stone)), 'eye': glow(*eye), 'moss': g([0x2a4a14, 0x4a7a24, 0x7ab040]),
          'shield': g([0x1a3a7a, 0x3a6ad0, 0x8ab0ff], spec=0.7), 'rim': GOLD, 'shine': SHINE}
    m = Model(20, 20)
    R = rough(0.12, 0.45, 9)
    for x, s in ((7.5, -1), (12.5, 1)):                                                        # stubby legs
        m.capsule((x, 14, 1), (x + s * 0.3, 18 - t * 0.5 * s, 1), 1.8, 1.6, 'stone', R)
    m.sphere((10, 11, 2), 5.2, 'stone', 1.05, 0.95, 1, R)                                      # the boulder body
    for s in (-1, 1):                                                                         # arms of stacked stones
        m.sphere((10 + s * 6, 11 + t * 0.5, 3), 2.2, 'stone', 1, 1.2, 1, R)
        m.sphere((10 + s * 6.5, 14 + t * 0.5, 3), 1.8, 'stone', 1, 1, 1, R)
    m.sphere((10, 5, 3), 3.3, 'stone', 1.1, 0.9, 1, R)                                         # head
    if moss:
        for x, y in ((7, 7.5), (12.5, 8), (10, 2.5), (4.5, 10)):
            m.sphere((x, y, 6), 1.3, 'moss', 1.4, 0.6, 1)
    if shield:
        m.sphere((15.5, 12, 6), 2.8, 'shield', 0.8, 1.1, 0.6)
        m.capsule((15.5, 9.5, 7), (15.5, 14.5, 7), 0.4, 0.4, 'rim')
    m.mark(8, 5, 'eye', 1, 1); m.mark(11, 5, 'eye', 1, 1)
    return m, mm


MODELS = [
    ('pet_pup', pup), ('pet_pup_a', lambda t: pup(t, (0x6a4a20, 0xa07a3a, 0xd8b070, 0xfff0c8), collar=GOLD)),
    ('pet_pup_b', lambda t: pup(t, (0x1e1e24, 0x34343e, 0x5a5a66, 0x8a8a98), spikes=True, eye='red', grin=True)),
    ('pet_slime', slime), ('pet_slime_a', lambda t: slime(t, (0x8a1050, 0xd04090, 0xff80c0, 0xffd8ee), crown=True)),
    ('pet_slime_b', lambda t: slime(t, (0x1a4a08, 0x3a8a18, 0x70e030, 0xd0ff90), acid=True)),
    ('pet_owl', owl), ('pet_owl_a', lambda t: owl(t, (0x7a8aa0, 0xb8c8dc, 0xe8f0fa, 0xffffff), (0xa8b8cc, 0xe0eaf6, 0xffffff),
                                                  eye=glow(0x1060c0, 0x60d0ff), gem=True)),
    ('pet_owl_b', lambda t: owl(t, (0x14100c, 0x2a2018, 0x46362a, 0x6a5440), (0x4a3a2a, 0x7a644c, 0xa08a6a),
                                eye=glow(0x800000, 0xff3030), talons=True)),
    ('pet_drake', drake), ('pet_drake_a', lambda t: drake(t, (0x5a0a04, 0xa01808, 0xe03a14, 0xff8040), (0x6a0a04, 0xc03010, 0xff7030), flame=True)),
    ('pet_drake_b', lambda t: drake(t, (0x2a2a2e, 0x46464e, 0x6e6e78, 0xa0a0a8), (0x3a3a40, 0x5e5e66, 0x8a8a92), armour=True)),
    ('pet_wisp', wisp), ('pet_wisp_a', lambda t: wisp(t, (0x4a1a8a, 0x9a50e0, 0xd8a8ff, 0xffffff), crystal=True)),
    ('pet_wisp_b', lambda t: wisp(t, (0x1a3a8a, 0x3a80e0, 0xa0d8ff, 0xffffff), (0xc0a000, 0xffe040, 0xffffff), bolts=True)),
    ('pet_golem', golem), ('pet_golem_a', lambda t: golem(t, (0x40444e, 0x666c7a, 0x9098aa, 0xc4cad8), (0x1060c0, 0x60d0ff), shield=True)),
    ('pet_golem_b', lambda t: golem(t, (0x3a2a1a, 0x5e4630, 0x8a6a4a, 0xb4946e), (0xa04000, 0xff9020), moss=True)),
]


def all_designs():
    return designs(MODELS, scale=2)


if __name__ == '__main__':
    import sys
    sheet(MODELS, sys.argv[1], 5)
