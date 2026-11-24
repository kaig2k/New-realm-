"""
The realm's regular monsters in the chunky style of the heroes: the 16x16 drawings of monsters_a/b/c.py and
designs.py (shaded light and dark per colour, like the polished heroes), brought back over their detailed
versions, and new ones in the same style for the monsters that never had one. Bosses keep their detailed art.

    python3 tools/bossart/chunky_monsters.py sheet.png     every chunky monster beside a hero
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from canvas import Canvas


# ----------------------------------------------------------------- Scorpion
def scorpion(t):
    c = Canvas(16, 16)
    # segmented tail curling up over the back to a stinger
    for i, (x, y) in enumerate([(4, 11), (3, 9), (3, 7), (4, 5), (6, 4)]):
        c.ellipse(x, y - (t if i > 2 else 0), 1.3, 1.1, 'B')
    c.ellipse(9, 11, 4, 2.2, 'B')
    c.ellipse(13, 10.5, 1.8, 1.6, 'B')
    c.shade('B', 'b', 'd')
    c.put(7, 4 - t, 'S'); c.put(8, 5 - t, 'S')
    # claws reaching forward
    c.line(13, 11, 15, 9, 'B'); c.line(13, 12, 15, 13, 'B')
    c.put(15, 8, 'b'); c.put(15, 14, 'b')
    # legs
    for x in (7, 9, 11):
        c.line(x, 12, x - 1, 14 + (t if x == 9 else 0), 'd')
    c.put(14, 10, 'E')
    return c


SCORPION_PAL = {'B': 0xa0602a, 'b': 0xd8904a, 'd': 0x5a3010, 'S': 0xffe080, 'E': 0x101010}


# ----------------------------------------------------------------- Crab
def crab(t):
    c = Canvas(16, 16)
    c.ellipse(8, 10, 5, 3, 'R')
    c.shade('R', 'r', 'd')
    # big claws raised, one snapping
    for s in (-1, 1):
        c.line(8 + s * 4, 9, 8 + s * 6, 6, 'R')
        c.ellipse(8 + s * 6.3, 5 - t * (s > 0), 1.6, 1.3, 'R')
        c.put(int(8 + s * 6.5), 3 - t * (s > 0), 'r')
    c.shade('R', 'r', 'd')
    # legs
    for x in (4, 6, 10, 12):
        c.line(x, 12, x + (-1 if x < 8 else 1), 14, 'd')
    # eyes on stalks
    c.line(6, 7, 6, 5, 'd'); c.line(10, 7, 10, 5, 'd')
    c.put(6, 4, 'W'); c.put(10, 4, 'W'); c.put(6, 5, 'K'); c.put(10, 5, 'K')
    return c


CRAB_PAL = {'R': 0xc83a24, 'r': 0xf07a50, 'd': 0x6a1a10, 'W': 0xf0f0f0, 'K': 0x101010}


# ----------------------------------------------------------------- Wolf
def wolf(t):
    c = Canvas(16, 16)
    c.ellipse(7, 9, 5, 2.6, 'G')
    c.ellipse(12.5, 7, 2.4, 2, 'G')
    c.poly([(13, 7), (16, 8), (13, 9)], 'G')
    c.shade('G', 'g', 'd')
    c.put(12, 4, 'G'); c.put(13, 4, 'G'); c.put(12, 5, 'd')
    c.line(2, 8, 0, 6 - t, 'G')
    for x, o in ((4, t), (6, 1 - t), (9, 1 - t), (11, t)):
        c.line(x, 11, x - o, 14, 'd')
    c.line(5, 10, 10, 10, 'W')
    c.put(13, 6, 'E'); c.put(15, 8, 'K')
    return c


WOLF_PAL = {'G': 0x6a6a72, 'g': 0x9a9aa4, 'd': 0x34343a, 'W': 0xb8b8c0, 'E': 0xffd030, 'K': 0x101010}


# ----------------------------------------------------------------- Harpy
def harpy(t):
    c = Canvas(16, 16)
    # wings spread, beating
    for s in (-1, 1):
        c.poly([(8, 7), (8 + s * 7, 2 + t * 2), (8 + s * 7, 7 + t), (8 + s * 3, 10)], 'F')
    c.shade('F', 'f', 'd')
    for s in (-1, 1):
        c.line(8 + s * 3, 6 + t, 8 + s * 6, 4 + t * 2, 'd')
    # body and taloned legs
    c.ellipse(8, 9, 2, 3, 'S')
    c.shade('S', 's', 'k')
    c.line(7, 12, 6, 14, 'Y'); c.line(9, 12, 10, 14, 'Y')
    # head with wild hair
    c.ellipse(8, 4.5, 1.8, 1.8, 'S')
    c.rect(6, 2, 10, 3, 'H'); c.put(5, 4, 'H'); c.put(11, 4, 'H')
    c.put(7, 5, 'E'); c.put(9, 5, 'E')
    return c


HARPY_PAL = {'F': 0x8a5a3a, 'f': 0xc08a5a, 'd': 0x4a2a1a, 'S': 0xd8a888, 's': 0xf0c8a8, 'k': 0x8a5a48,
             'Y': 0xe0b030, 'H': 0x3a2418, 'E': 0xff3020}


# ----------------------------------------------------------------- Medusa
def medusa(t):
    c = Canvas(16, 16)
    # a serpent's tail coiled below
    c.ellipse(8, 13.5, 5, 1.8, 'T')
    c.ellipse(9, 11, 3, 1.6, 'T')
    c.shade('T', 't', 'd')
    # body
    c.rect(6, 6, 10, 10, 'S')
    c.shade('S', 's', 'k')
    c.line(6, 8, 10, 8, 'Y')
    # arms
    c.line(5, 7, 4, 10, 'S'); c.line(11, 7, 12, 10, 'S')
    # head and a crown of snakes
    c.ellipse(8, 4, 2, 2, 'S')
    for x, h in ((5, 1), (6, 0), (8, 0), (10, 0), (11, 1)):
        c.line(x, 3, x + (1 if t else -1) * (x % 2), h, 'T')
        c.put(x + (1 if t else -1) * (x % 2), h, 't')
    c.put(7, 4, 'E'); c.put(9, 4, 'E')
    return c


MEDUSA_PAL = {'T': 0x3a7a3a, 't': 0x6ab05a, 'd': 0x1a3a1a, 'S': 0x8ab894, 's': 0xb4dcbc, 'k': 0x4a6a52,
              'Y': 0xe0c040, 'E': 0xffe040}


# ----------------------------------------------------------------- Djinn
def djinn(t):
    c = Canvas(16, 16)
    # a wisp of smoke for legs
    c.poly([(6, 9), (10, 9), (9, 12), (7, 14 + t), (6, 15)], 'B')
    c.ellipse(8, 7, 4, 3, 'B')
    c.shade('B', 'b', 'd')
    # crossed arms with gold bands
    c.line(4, 7, 12, 7, 'b')
    c.put(5, 7, 'Y'); c.put(11, 7, 'Y')
    # head, a turban with a gem
    c.ellipse(8, 3.5, 2, 2, 'B')
    c.shade('B', 'b', 'd')
    c.rect(6, 1, 10, 2, 'W'); c.put(8, 1, 'R')
    c.put(7, 4, 'E'); c.put(9, 4, 'E')
    c.line(7, 5, 9, 5, 'K')
    return c


DJINN_PAL = {'B': 0x3a6ae0, 'b': 0x70a0ff, 'd': 0x1a2a80, 'Y': 0xf0c040, 'W': 0xf0f0f8, 'R': 0xe02040,
             'E': 0xffffff, 'K': 0x101040}


# ----------------------------------------------------------------- Ent
def ent(t):
    c = Canvas(16, 16)
    # a crown of leaves
    c.ellipse(8, 4, 6, 3.5, 'L')
    c.shade('L', 'l', 'g')
    # a gnarled trunk body with root legs
    c.rect(5, 6, 11, 13, 'W')
    c.shade('W', 'w', 'd')
    c.line(5, 13, 4, 15, 'd'); c.line(11, 13, 12, 15, 'd'); c.line(8, 13, 8, 15, 'd')
    # branch arms
    c.line(5, 8, 2, 6 - t, 'w'); c.line(11, 8, 14, 6 + t, 'w')
    c.put(1, 5 - t, 'L'); c.put(15, 5 + t, 'L')
    # a face in the bark
    c.put(6, 8, 'E'); c.put(10, 8, 'E')
    c.line(7, 11, 9, 11, 'K')
    return c


ENT_PAL = {'L': 0x3a7a2a, 'l': 0x6aaa44, 'g': 0x1e4a16, 'W': 0x6a4a2a, 'w': 0x9a7040, 'd': 0x3a2410,
           'E': 0xffd030, 'K': 0x1a1008}


# ----------------------------------------------------------------- Cubelet
def cubelet(t):
    c = Canvas(16, 16)
    y = 2 - t
    # a cube, square on: a light top face, a front face, a dark side face, bright edges
    c.poly([(4, y + 3), (7, y), (14, y), (11, y + 3)], 'T')
    c.rect(4, y + 3, 10, y + 10, 'L')
    c.poly([(11, y + 3), (14, y), (14, y + 7), (11, y + 10)], 'D')
    c.line(4, y + 3, 11, y + 3, 'H'); c.line(11, y + 3, 11, y + 10, 'H'); c.line(11, y + 3, 14, y, 'H')
    # one glowing eye
    c.rect(6, y + 5, 8, y + 7, 'K'); c.put(7, y + 6, 'E')
    c.ellipse(9, 14.5, 4, 0.8, 'S')
    return c


CUBELET_PAL = {'T': 0xd088ff, 'L': 0x9040d0, 'D': 0x4a1880, 'H': 0xf8d8ff, 'E': 0x60ffff, 'K': 0x1a0a30, 'S': 0x1a1020}


# ----------------------------------------------------------------- Mothling
def mothling(t):
    c = Canvas(16, 16)
    for s in (-1, 1):
        c.ellipse(8 + s * 4, 6 - t, 3.2, 2.6, 'W')
        c.ellipse(8 + s * 3.5, 10, 2.4, 2, 'W')
    c.shade('W', 'w', 'd')
    for s in (-1, 1):
        c.put(8 + s * 4, 6 - t, 'O'); c.put(8 + s * 3, 10, 'O')
    c.ellipse(8, 8, 1.2, 4, 'B')
    c.line(7, 3, 6, 1, 'B'); c.line(9, 3, 10, 1, 'B')
    c.put(7, 5, 'E'); c.put(9, 5, 'E')
    return c


MOTHLING_PAL = {'W': 0xc8b88a, 'w': 0xeee0b4, 'd': 0x7a6a48, 'O': 0x5a4a8a, 'B': 0x4a3a2a, 'E': 0xff9030}


# ----------------------------------------------------------------- Siege Soldier
def siege_soldier(t):
    c = Canvas(16, 16)
    c.rect(5, 12, 6, 15, 'L'); c.rect(9, 12, 10, 15, 'L')
    c.rect(4, 7, 11, 12, 'A')
    c.shade('A', 'a', 'd')
    c.line(4, 9, 11, 9, 'R')
    c.ellipse(7.5, 4.5, 2.4, 2.4, 'A')
    c.shade('A', 'a', 'd')
    c.line(5, 5, 10, 5, 'K'); c.put(8, 5, 'E')
    c.line(7, 1, 8, 1, 'R'); c.put(7, 2, 'R')
    # a spear and a round shield
    c.line(13, 15, 13, 1 - t, 'W'); c.put(13, 0, 'a')
    c.ellipse(3, 10, 1.6, 2.2, 'R'); c.put(3, 10, 'Y')
    return c


SIEGE_SOLDIER_PAL = {'L': 0x2a2a30, 'A': 0x6a6a76, 'a': 0xa0a0ac, 'd': 0x34343c, 'R': 0x8a2010, 'K': 0x101014,
                     'E': 0xff7010, 'W': 0x6a4a2a, 'Y': 0xf0b030}


# ----------------------------------------------------------------- Spiderling
def spiderling(t):
    c = Canvas(16, 16)
    for i, (x, k) in enumerate(((6, 4), (8, 6), (10, 10), (11, 12))):
        o = (i + t) % 2
        c.line(8, 10, k, 7 - o, 'L'); c.line(k, 7 - o, x - 3 + i * 2, 13, 'L')
    c.ellipse(7, 10, 2.6, 2.2, 'S')
    c.ellipse(10.5, 10, 1.6, 1.4, 'S')
    c.shade('S', 's', 'd')
    c.put(11, 9, 'E'); c.put(12, 10, 'E')
    return c


SPIDERLING_PAL = {'S': 0x3a2a3a, 's': 0x6a506a, 'd': 0x1e141e, 'L': 0x5a465a, 'E': 0xff3030}


# ----------------------------------------------------------------- Kraken tentacle
def kraken_tentacle(t):
    c = Canvas(16, 16)
    c.ellipse(8, 14, 5, 1.6, 'F')
    pts = [(8, 14), (9, 11), (8 - t, 8), (9 - t, 5), (11 - t, 3), (12 - t, 4)]
    for i in range(len(pts) - 1):
        c.line(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], 'P', 2.4 - i * 0.35)
    c.shade('P', 'p', 'd')
    for (x, y) in pts[1:4]:
        c.put(x + 1, y, 'S')
    return c


KRAKEN_TENTACLE_PAL = {'F': 0xd8f0f4, 'P': 0xc0507a, 'p': 0xf08aa8, 'd': 0x6a2040, 'S': 0xffd0dc}


# ----------------------------------------------------------------- Clam cannon
def clam_cannon(t):
    c = Canvas(16, 16)
    # the bottom shell, and the top one opening to fire
    c.ellipse(8, 11, 6, 3, 'S')
    c.poly([(2, 9), (14, 9), (12, 4 + t), (4, 4 + t)], 'S')
    c.shade('S', 's', 'd')
    for x in (5, 8, 11):
        c.line(x, 5 + t, x, 8, 'd')
    c.rect(4, 9, 12, 9, 'K')
    c.ellipse(8, 9, 1.4, 0.8, 'P')
    return c


CLAM_CANNON_PAL = {'S': 0xd88aa0, 's': 0xf8c0d0, 'd': 0x8a4a5a, 'K': 0x2a1418, 'P': 0xf8f8ff}


# ----------------------------------------------------------------- Demon (monsters_c's drawing, in reds: it read as a white goat)
from monsters_c import demon
DEMON_PAL = {'W': 0xa0201c, 'w': 0xe04a30, 'v': 0x4a0a0a, 'R': 0xffb030, 'r': 0x6a2a08, 'E': 0xffe040,
             'K': 0x140606, 'F': 0xf0e0c0}


NEW = [('demon', demon, DEMON_PAL, 3), ('scorpion', scorpion, SCORPION_PAL, 3), ('crab', crab, CRAB_PAL, 3), ('wolf', wolf, WOLF_PAL, 3),
       ('harpy', harpy, HARPY_PAL, 3), ('medusa', medusa, MEDUSA_PAL, 3), ('djinn', djinn, DJINN_PAL, 3),
       ('ent', ent, ENT_PAL, 3), ('cubelet', cubelet, CUBELET_PAL, 3), ('mothling', mothling, MOTHLING_PAL, 3),
       ('siege_soldier', siege_soldier, SIEGE_SOLDIER_PAL, 3), ('spiderling', spiderling, SPIDERLING_PAL, 3),
       ('kraken_tentacle', kraken_tentacle, KRAKEN_TENTACLE_PAL, 3), ('clam_cannon', clam_cannon, CLAM_CANNON_PAL, 3)]


# the regular monsters drawn chunky (a boss sharing one keeps a detailed copy: golem -> golem_big)
NAMES = ['bandit', 'bandit_leader', 'beholder', 'blood_hound', 'bone_thrall', 'clam_cannon', 'cloud_serpent', 'crab', 'cubelet', 'cultist', 'demon', 'djinn', 'dwarf', 'dwarf_king', 'elf', 'ent', 'gale_harpy', 'gazer', 'ghost', 'ghost_god', 'goblin', 'goblin_chief', 'golem', 'grave_wraith', 'great_snake', 'green_slime', 'harpy', 'hobbit', 'imp', 'kraken_tentacle', 'lesser_demon', 'lich', 'loot_goblin', 'medusa', 'minotaur', 'mothling', 'ogre', 'orc', 'orc_king', 'pirate', 'pirate_brawler', 'pirate_captain', 'royal_guard', 'scorpion', 'shade', 'siege_soldier', 'skeleton', 'slime', 'slime_god', 'snake', 'spider', 'spider_queen', 'spiderling', 'sprite', 'sprite_god', 'star_guard', 'temple_scorpion', 'thunder_golem', 'war_orc', 'wolf']


def designs(names):
    """The chunky design for each of these monster sprites: an old one if it was drawn, else a new one."""
    from monsters_a import MONSTERS as MA
    from monsters_b import MONSTERS as MB
    from monsters_c import MONSTERS as MC
    from designs import DESIGNS
    old = {d[0]: d for d in DESIGNS + MA + MB + MC}
    new = {d[0]: d for d in NEW}
    return [new.get(n) or old[n] for n in names if n in new or n in old]


if __name__ == '__main__':
    from canvas import preview
    from animate import frames as animate
    out = []
    for name, fn, pal, sc in NEW:
        fr, p = animate(fn, pal)
        out.append((name, fr, p))
    preview(out, sys.argv[1] if len(sys.argv) > 1 else '/tmp/chunky.png', 6)
