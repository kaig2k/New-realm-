"""
What the finales (Bosses.finales, Lairs.as) ask of you besides their masters: the drowned souls that
drift to Nerezza's throne, Gearmind's power cores and the Rift Crystals that drag Vael'thrax down.
Two frames each (they pulse).
"""
import math
from sdfart import Model, rough
from shaded_kit import g, glow, designs, sheet, spike, rock

VOID = g([0x040306, 0x0a080e])


def drowned_soul(t):
    """A drowned sailor's ghost: a hooded wisp of sea-glass light trailing weed and water."""
    M = {'shroud': glow(0x0e4a6a, 0x2a90b8, 0x70d8f0, base=0.3), 'light': glow(0x80f0ff, 0xe0ffff, 0xffffff, base=0.5),
         'weed': g([0x0e2a1c, 0x1a4a2c, 0x2c6a3c]), 'void': VOID}
    m = Model(22, 28)
    bob = t * 1.0
    m.chain([(11, 6 + bob, 0), (11, 14 + bob, 0), (12.5, 21 + bob, 0), (10, 26, 0)], [5.0, 5.4, 3.4, 0.8], 'shroud', rough(0.05))
    m.sphere((11, 7 + bob, 2), 4.2, 'shroud', 1.0, 1.05, 1.0)                     # the hood
    m.sphere((11, 8.8 + bob, 5.6), 2.6, 'void', 0.95, 1.3, 0.6)                   # the dark under it
    m.mark(9.8, 8 + bob, 'light'); m.mark(12.2, 8 + bob, 'light')                 # two pale eyes in it
    m.mark(11, 11 + bob, 'shroud')
    for s in (-1, 1):
        m.capsule((11 + s * 4, 12 + bob, 1), (11 + s * 7, 16 + bob - t, 2), 1.2, 0.6, 'shroud')    # drifting sleeves
    for x, y in ((8, 15), (14, 18), (10, 21)):
        m.capsule((x, y + bob, 4), (x + 1, y + 4 + bob, 4), 0.6, 0.3, 'weed')
    m.sphere((11, 14 + bob, 4), 1.2 + t * 0.3, 'light')                           # the soul she wants
    return m, M


def power_core(t):
    """A brass-caged core of crackling light on a cogwheel plinth."""
    M = {'brass': g([0x3a2808, 0x6a4c12, 0xa87c20, 0xe0b040, 0xfff0a0], spec=0.7), 'iron': g([0x16161c, 0x26262e, 0x3a3a46, 0x5a5a68], spec=0.5),
         'core': glow(0x0c3a70, 0x2080c8, 0x60d0ff, 0xc0f4ff, base=0.15), 'spark': glow(0xffffff, 0xffffff)}
    m = Model(28, 34)
    # the plinth: a toothed wheel lying flat
    m.sphere((14, 29, 0), 11, 'iron', 1.0, 0.32, 0.6)
    for k in range(10):
        a = k * math.pi / 5 + t * 0.3
        m.sphere((14 + math.cos(a) * 11.5, 29 + math.sin(a) * 3.6, 1), 1.4, 'iron')
    # the core in its cage
    m.sphere((14, 16, 2), 6.6 + t * 0.4, 'core')
    m.sphere((14, 16, 6), 2.0 + t * 0.5, 'spark')
    for k in range(4):
        x = 14 + (k - 1.5) * 4.4
        bow = 7.6 - abs(k - 1.5) * 1.6
        m.chain([(x * 0.6 + 14 * 0.4, 6, 5), (x, 16, 5 + bow * 0.2), (x * 0.6 + 14 * 0.4, 26, 5)], [0.9, 1.0, 0.9], 'brass')
    m.capsule((7, 6, 4), (21, 6, 4), 1.6, 1.6, 'brass')
    m.capsule((6, 26, 4), (22, 26, 4), 1.8, 1.8, 'brass')
    spike(m, (14, 5), (14, 0.5), 1.4, 5, 'brass')
    for k in range(3):                                                               # sparks leaping in it
        a = k * 2.1 + t * 1.3
        m.mark(int(14 + math.cos(a) * 4), int(16 + math.sin(a) * 4), 'spark')
    return m, M


def rift_crystal(t):
    """A shard of the rift torn up through the island stone, the void pouring out of its heart."""
    M = {'cr': g([0x1a0a2e, 0x3a1868, 0x6a30b0, 0xa860f0, 0xe0b8ff], facet=7, spec=0.9), 'stone': g([0x0e0a12, 0x1c1622, 0x2c2436, 0x40364c]),
         'void': glow(0x6010a0, 0xd040ff, 0xffffff, base=0.3)}
    m = Model(26, 36)
    rock(m, 13, 31, 9, 1, 'stone', 3, sides=8, squash=0.4)
    spike(m, (13, 31), (13, 2), 5.6, 3, 'cr')
    spike(m, (9, 31), (4, 12), 3.2, 2, 'cr')
    spike(m, (17, 31), (22, 15), 3.0, 2, 'cr')
    m.sphere((13, 18, 6), 2.4 + t * 0.6, 'void')                                    # the rift inside it
    m.capsule((13, 12, 6), (13, 24, 6), 0.6, 0.6, 'void')
    return m, M


PROPS = [('drowned_soul', drowned_soul), ('power_core', power_core), ('rift_crystal', rift_crystal)]


def all_designs():
    return designs(PROPS)


if __name__ == '__main__':
    import sys
    sheet(PROPS, sys.argv[1], 6)
