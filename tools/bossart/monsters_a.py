"""
Eldmere's regular monsters, batch A (dwarves, goblins, orcs, brutes and oddities).
Same style as designs.py: shapes, then shade(base, light, dark) per material,
then details. 16x16 for normal monsters, 18-20 for big ones; all at scale 3.
Every design(t) returns a Canvas for idle frame t (0 or 1). Sprites face right.
"""
import math
from canvas import Canvas


# ----------------------------------------------------------------- Dwarf Axeman (16x16)
def dwarf(t):
    c = Canvas(16, 16)
    b = t  # breathing bob of the upper body
    # stocky legs and boots
    c.rect(4, 12, 6, 15, 'P'); c.rect(8, 12, 10, 15, 'P')
    c.shade('P', 'p', 'k')
    c.rect(3, 14, 6, 15, 'L'); c.rect(8, 14, 11, 15, 'L')
    # broad red tunic under a mail shirt
    c.rect(3, 7 + b, 11, 12, 'T')
    c.shade('T', 't', 'r')
    c.line(3, 11, 11, 11, 'L'); c.put(7, 11, 'Y')
    # head and horned helm
    c.rect(5, 4 + b, 9, 6 + b, 'S')
    c.rect(4, 2 + b, 10, 4 + b, 'H')
    c.shade('H', 'h', 'd')
    c.put(3, 2 + b, 'W'); c.put(2, 1 + b, 'W'); c.put(11, 2 + b, 'W'); c.put(12, 1 + b, 'W')
    c.put(7, 2 + b, 'Y')
    c.put(6, 5 + b, 'K'); c.put(8, 5 + b, 'K')
    # big braided orange beard
    c.poly([(4, 6 + b), (11, 6 + b), (9, 11 + b), (7, 12 + b), (5, 11 + b)], 'B')
    c.shade('B', 'b', 'o')
    c.put(6, 10 + b, 'Y'); c.put(9, 10 + b, 'Y')
    c.put(8, 6 + b, 'S')
    # big axe on the right: haft and a crescent blade
    c.line(12, 14, 13, 2 + b, 'O')
    c.poly([(13, 2 + b), (16, 1 + b), (16, 8 + b), (13, 7 + b)], 'A')
    c.shade('A', 'a', 'z')
    c.line(12, 9, 11, 9, 'S')
    c.put(11, 9 + b, 'S')
    return c


DWARF_PAL = {'P': 0x5a4030, 'p': 0x7a5a40, 'k': 0x2a1a10, 'L': 0x3a2410, 'T': 0x903a20, 't': 0xc05a30, 'r': 0x5a1e10,
             'Y': 0xf0c030, 'S': 0xe8b088, 'H': 0x8a8a96, 'h': 0xc8c8d4, 'd': 0x4a4a56, 'W': 0xf0e8d0, 'K': 0x101010,
             'B': 0xc04a20, 'b': 0xf07a40, 'o': 0x7a2a10, 'O': 0x6a4020, 'A': 0xb0b8c4, 'a': 0xf0f4ff, 'z': 0x5a6070}


# ----------------------------------------------------------------- Dwarf King (20x20)
def dwarf_king(t):
    c = Canvas(20, 20)
    b = t
    # golden armoured legs
    c.rect(5, 15, 8, 19, 'G'); c.rect(11, 15, 14, 19, 'G')
    c.shade('G', 'g', 'd')
    c.rect(4, 18, 8, 19, 'k'); c.rect(11, 18, 15, 19, 'k')
    # royal purple cape behind
    c.poly([(3, 8 + b), (15, 8 + b), (17, 18), (2, 18)], 'C')
    c.shade('C', 'c', 'v')
    # golden breastplate
    c.rect(4, 8 + b, 14, 15, 'G')
    c.ellipse(4, 9 + b, 2, 1.5, 'G'); c.ellipse(14, 9 + b, 2, 1.5, 'G')
    c.shade('G', 'g', 'd')
    c.line(4, 14, 14, 14, 'd'); c.put(9, 14, 'R')
    # face
    c.rect(6, 4 + b, 12, 7 + b, 'S')
    c.shade('S', 's', 'n')
    c.put(7, 6 + b, 'K'); c.put(10, 6 + b, 'K')
    c.line(6, 5 + b, 12, 5 + b, 'n')
    # crown
    c.rect(5, 2 + b, 13, 3 + b, 'G')
    for x in (5, 7, 9, 11, 13):
        c.put(x, 1 + b, 'G')
    c.shade('G', 'g', 'd')
    c.put(9, 2 + b, 'R'); c.put(6, 3 + b, 'E'); c.put(12, 3 + b, 'E')
    # long white beard down to the belt, forked
    c.poly([(5, 7 + b), (13, 7 + b), (12, 13 + b), (10, 16 + b), (9, 14 + b), (8, 16 + b), (6, 13 + b)], 'B')
    c.shade('B', 'b', 'w')
    c.put(9, 7 + b, 'S')
    c.put(8, 11 + b, 'G'); c.put(10, 11 + b, 'G')
    # war hammer held up on the right
    c.line(16, 18, 16, 4 + b, 'O')
    c.rect(14, 1 + b, 19, 5 + b, 'H')
    c.shade('H', 'h', 'z')
    c.put(16, 3 + b, 'R')
    c.line(14, 10 + b, 16, 10 + b, 'S')
    return c


DKING_PAL = {'G': 0xd8a820, 'g': 0xfff070, 'd': 0x7a5a10, 'k': 0x3a2410, 'C': 0x5a2080, 'c': 0x8a40b0, 'v': 0x2a0a40,
             'R': 0xe02030, 'E': 0x30c0ff, 'S': 0xe8b088, 's': 0xf8d0b0, 'n': 0xa06a48, 'K': 0x101010,
             'B': 0xe8e8f0, 'b': 0xffffff, 'w': 0xa0a0b4, 'O': 0x6a4020, 'H': 0x9aa0b0, 'h': 0xe0e4f0, 'z': 0x4a4e5a}


# ----------------------------------------------------------------- Goblin (16x16)
def goblin(t):
    c = Canvas(16, 16)
    b = t
    # skinny legs
    c.line(6, 12, 5, 15, 'G'); c.line(9, 12, 10, 15, 'G')
    # ragged brown tunic
    c.poly([(5, 8 + b), (10, 8 + b), (11, 13), (4, 13)], 'R')
    c.shade('R', 'r', 'k')
    c.put(5, 13, '.'); c.put(8, 13, '.')
    c.put(6, 10, 'k')
    # big head and huge pointed ears
    c.ellipse(7.5, 5 + b, 3, 2.6, 'G')
    c.poly([(5, 4 + b), (1, 2 + b), (5, 6 + b)], 'G')
    c.poly([(10, 4 + b), (15, 2 + b), (10, 6 + b)], 'G')
    c.shade('G', 'g', 'd')
    c.put(2, 3 + b, 'p'); c.put(13, 3 + b, 'p')
    # beady yellow eyes, toothy grin
    c.put(7, 5 + b, 'E'); c.put(9, 5 + b, 'E')
    if t:
        c.put(7, 5 + b, 'd')
    c.line(7, 7 + b, 9, 7 + b, 'W')
    # arms; a dagger in the right hand
    c.line(5, 9 + b, 3, 11, 'G')
    c.line(10, 9 + b, 12, 10, 'G')
    c.put(12, 10, 'O')
    c.line(13, 9, 15, 7, 'S')
    c.put(13, 9, 's')
    return c


GOBLIN_PAL = {'G': 0x6ab040, 'g': 0xa0e070, 'd': 0x2e5a1a, 'p': 0xd08a8a, 'R': 0x7a5a3a, 'r': 0xa07a50, 'k': 0x3a2410,
              'E': 0xffe020, 'W': 0xf0f0e0, 'O': 0x5a3a20, 'S': 0xd0d8e0, 's': 0x8a90a0}


# ----------------------------------------------------------------- Goblin Chieftain (16x16)
def goblin_chief(t):
    c = Canvas(16, 16)
    b = t
    # legs and a fur kilt
    c.rect(5, 12, 6, 15, 'G'); c.rect(9, 12, 10, 15, 'G')
    c.rect(4, 11, 11, 13, 'F')
    c.shade('F', 'f', 'k')
    # bulkier green body, red war paint stripes
    c.ellipse(7.5, 9 + b * 0.5, 3.6, 2.8, 'G')
    # head and ears
    c.ellipse(7.5, 5 + b, 2.8, 2.3, 'G')
    c.poly([(5, 4 + b), (2, 3 + b), (5, 6 + b)], 'G')
    c.poly([(10, 4 + b), (13, 3 + b), (10, 6 + b)], 'G')
    c.shade('G', 'g', 'd')
    c.line(5, 8, 9, 11, 'R'); c.line(6, 4 + b, 9, 4 + b, 'R')
    c.put(7, 5 + b, 'E'); c.put(9, 5 + b, 'E')
    c.put(8, 7 + b, 'W'); c.put(10, 7 + b, 'W')
    # bone headdress: fanned bones and a skull
    for i, x in enumerate((4, 6, 8, 10, 12)):
        top = 1 if i in (1, 2, 3) else 2
        c.line(x, top + b, 7.5 + (x - 7.5) * 0.4, 3 + b, 'B')
    c.put(8, 3 + b, 'b'); c.put(7, 3 + b, 'b')
    c.put(6, 1 + b, 'R'); c.put(10, 1 + b, 'R')
    # spiked club on the right
    c.line(11, 10 + b, 13, 6, 'O')
    c.ellipse(14, 4, 1.5, 2.2, 'O')
    c.shade('O', 'o', 'k')
    c.put(15, 2, 'B'); c.put(12, 3, 'B'); c.put(15, 5, 'B')
    c.line(4, 9 + b, 3, 12, 'G')
    return c


GCHIEF_PAL = {'G': 0x58a030, 'g': 0x90d060, 'd': 0x264a14, 'F': 0x8a6a4a, 'f': 0xb89a70, 'k': 0x3a2410, 'R': 0xe02828,
              'E': 0xffe020, 'W': 0xf0f0e0, 'B': 0xf0e8d0, 'b': 0x101010, 'O': 0x7a4a24, 'o': 0xa87040}


# ----------------------------------------------------------------- Stone Golem (16x16)
def golem(t):
    c = Canvas(16, 16)
    b = t
    # blocky legs
    c.rect(3, 12, 6, 15, 'S'); c.rect(9, 12, 12, 15, 'S')
    # boulder body, wide shoulders
    c.rect(2, 5 + b, 13, 12, 'S')
    c.rect(0, 6 + b, 2, 9 + b, 'S'); c.rect(13, 6 + b, 15, 9 + b, 'S')
    # fists hanging low
    c.rect(0, 10 + b, 2, 13 + b, 'S'); c.rect(13, 10 + b, 15, 13 + b, 'S')
    # small head sunk between the shoulders
    c.rect(5, 2 + b, 10, 5 + b, 'S')
    c.shade('S', 's', 'd')
    # cracks
    c.line(4, 7 + b, 6, 9 + b, 'd'); c.line(11, 10, 12, 8 + b, 'd')
    c.put(7, 12, 'd'); c.put(8, 13, 'd')
    # moss on the shoulders and head
    for (x, y) in [(5, 2), (6, 2), (9, 2), (2, 5), (3, 5), (0, 6), (1, 6), (12, 5), (14, 6), (13, 6), (3, 12)]:
        c.put(x, y + (b if y < 12 else 0), 'M')
    c.put(4, 5 + b, 'm'); c.put(13, 7 + b, 'm')
    # glowing eyes and chest rune
    c.put(6, 4 + b, 'E'); c.put(9, 4 + b, 'E')
    r = 'E' if t else 'e'
    c.line(7, 7 + b, 7, 10 + b, r); c.put(8, 8 + b, r); c.put(6, 8 + b, r)
    c.put(1, 7 + b, 'e'); c.put(14, 11 + b, 'e')
    return c


GOLEM_PAL = {'S': 0x8a8a8a, 's': 0xbcbcb8, 'd': 0x4a4a50, 'M': 0x4a8a30, 'm': 0x7ac050, 'E': 0x60f0ff, 'e': 0x2aa0d0}


# ----------------------------------------------------------------- Ember Imp (16x16, hovering)
def imp(t):
    c = Canvas(16, 16)
    b = t  # hover bob
    # bat wings, flapping
    wy = 2 if t else 1
    c.poly([(6, 6 + b), (0, wy + b), (1, 5 + b), (0, 8 + b), (3, 8 + b), (6, 9 + b)], 'W')
    c.poly([(9, 6 + b), (14, wy + b), (14, 5 + b), (15, 8 + b), (12, 8 + b), (9, 9 + b)], 'W')
    c.shade('W', 'w', 'k')
    # curling tail with a spade tip
    c.line(6, 11 + b, 4, 13, 'R'); c.line(4, 13, 2, 13 - t, 'R')
    c.put(1, 12 - t, 'F'); c.put(1, 13 - t, 'F'); c.put(0, 12 - t, 'F')
    # small round body and head
    c.ellipse(7.5, 9 + b, 2.3, 2.6, 'R')
    c.ellipse(7.5, 5 + b, 2.6, 2.3, 'R')
    c.shade('R', 'r', 'd')
    c.put(7, 13, 'R'); c.put(9, 13, 'R'); c.put(6, 14, 'd'); c.put(9, 14, 'd')
    # horns and glowing eyes
    c.put(5, 2 + b, 'H'); c.put(10, 2 + b, 'H'); c.put(5, 3 + b, 'H'); c.put(10, 3 + b, 'H')
    c.put(7, 5 + b, 'Y'); c.put(9, 5 + b, 'Y')
    c.put(8, 7 + b, 'k')
    # trident on the right
    c.line(12, 14, 12, 3 + b, 'T')
    c.line(11, 3 + b, 13, 3 + b, 'T')
    c.put(11, 2 + b, 'T'); c.put(13, 2 + b, 'T'); c.put(12, 1 + b, 'T')
    c.line(9, 9 + b, 11, 9 + b, 'R')
    # sparks
    c.put(3 + t * 9, 14 - t * 13, 'Y')
    return c


IMP_PAL = {'R': 0xff6020, 'r': 0xffa050, 'd': 0x9a2a08, 'W': 0xa02010, 'w': 0xd04020, 'k': 0x4a0a04, 'F': 0xffd040,
           'H': 0x2a1a14, 'Y': 0xfff060, 'T': 0x3a3a44}


# ----------------------------------------------------------------- Minotaur (20x20)
def minotaur(t):
    c = Canvas(20, 20)
    b = t
    # hooved legs
    c.rect(5, 14, 7, 18, 'F'); c.rect(11, 14, 13, 18, 'F')
    c.shade('F', 'f', 'd')
    c.rect(4, 18, 7, 19, 'K'); c.rect(11, 18, 14, 19, 'K')
    # leather kilt
    c.rect(4, 12, 14, 14, 'L')
    c.shade('L', 'l', 'k')
    c.put(9, 12, 'G')
    # massive furred torso
    c.poly([(2, 6 + b), (16, 6 + b), (14, 12), (4, 12)], 'F')
    c.ellipse(9, 7 + b, 6, 2.5, 'F')
    # arm forward to the axe
    c.line(15, 7 + b, 16, 11, 'F', 2)
    c.line(3, 7 + b, 2, 12, 'F', 2)
    # bull head, snout to the right
    c.ellipse(10, 4 + b, 3, 2.6, 'F')
    c.rect(11, 4 + b, 14, 7 + b, 'F')
    c.shade('F', 'f', 'd')
    c.rect(12, 5 + b, 14, 7 + b, 'M')
    c.put(14, 5 + b, 'K')
    # horns curving up
    c.line(8, 3 + b, 5, 2 + b, 'H'); c.put(4, 1 + b, 'h'); c.put(5, 1 + b, 'H')
    c.line(11, 2 + b, 13, 1 + b, 'H'); c.put(14, 0 + b, 'h') if b else c.put(14, 1, 'h')
    c.put(10, 4 + b, 'E')
    # brass nose ring
    c.put(14, 8 + b, 'G'); c.put(13, 8 + b, 'G')
    # double-bladed axe
    c.line(17, 19, 17, 3, 'O')
    c.poly([(17, 3), (19.9, 1), (19.9, 9), (17, 7)], 'A')
    c.poly([(17, 3), (14.8, 1.5), (14.8, 7.5), (17, 7)], 'A', only='.')
    c.shade('A', 'a', 'z')
    c.put(17, 5, 'O')
    c.put(16, 11, 'f')
    return c


MINO_PAL = {'F': 0x6a3a1a, 'f': 0x9a5a30, 'd': 0x341a0a, 'K': 0x140a06, 'L': 0x3a2a1a, 'l': 0x5a4430, 'k': 0x1a1008,
            'G': 0xf0c030, 'M': 0xc89070, 'H': 0xe8dcc0, 'h': 0xfffff0, 'E': 0xff3020, 'O': 0x4a3020,
            'A': 0xa8b0bc, 'a': 0xf0f4ff, 'z': 0x50566a}


# ----------------------------------------------------------------- Ogre (20x20)
def ogre(t):
    c = Canvas(20, 20)
    b = t  # breathing: the upper body heaves
    # short thick legs, wide apart
    c.rect(4, 15, 7, 19, 'S'); c.rect(11, 15, 14, 19, 'S')
    # hunched mountain of shoulders
    c.ellipse(9, 6.5 + b, 7, 2.4, 'S')
    # long dangling left arm, a ham-sized fist
    c.line(3, 6 + b, 2, 13, 'S', 2.6)
    c.ellipse(2, 14, 1.6, 1.5, 'S')
    # tiny head perched on top
    c.ellipse(10, 3 + b, 2.1, 1.9, 'S')
    c.rect(9, 4 + b, 12, 5 + b, 'S')
    c.shade('S', 's', 'd')
    # a huge round belly bulging out in front
    c.ellipse(9.5, 11.5, 5.6, 4.3, 'B')
    c.shade('B', 'b', 'd')
    c.put(10, 12, 'd')
    # face: beady red eyes, a heavy brow, an underbite with tusks
    c.line(9, 2 + b, 12, 2 + b, 'd')
    c.put(10, 3 + b, 'E'); c.put(12, 3 + b, 'E')
    c.put(10, 5 + b, 'W'); c.put(12, 5 + b, 'W'); c.put(11, 5 + b, 'K')
    # hide loincloth with a rope belt
    c.rect(5, 15, 13, 16, 'L'); c.poly([(7, 16), (11, 16), (10, 18), (8, 18)], 'L')
    c.shade('L', 'l', 'k')
    c.line(5, 15, 13, 15, 'R')
    # a tree-trunk club, thick and knotted, hoisted on the right
    c.line(16, 13, 17, 4 + b, 'C', 2.6)
    c.ellipse(17, 3.5 + b, 2.4, 2.6, 'C')
    c.shade('C', 'c', 'k')
    c.put(18, 4 + b, 'k'); c.put(16, 8 + b, 'k')
    c.put(19, 6 + b, 'G'); c.put(15, 2 + b, 'G'); c.put(16, 1 + b, 'G')
    # right arm gripping the club
    c.line(15, 6 + b, 16, 10, 'S', 2.4)
    c.shade('S', 's', 'd')
    c.rect(15, 11, 17, 12, 's')
    return c


OGRE_PAL = {'S': 0xa08a5a, 's': 0xc8b480, 'd': 0x5a4a2a, 'B': 0xb8a070, 'b': 0xdcc898, 'E': 0xff3020, 'W': 0xf0f0e0,
            'K': 0x2a1a0e, 'L': 0x6a4a30, 'l': 0x8a6a48, 'k': 0x2a1a0e, 'R': 0xc0a060, 'C': 0x6a4420, 'c': 0x9a6a38,
            'G': 0x4a9a30}


# ----------------------------------------------------------------- Orc Warrior (16x16)
def orc(t):
    c = Canvas(16, 16)
    b = t
    # legs and boots
    c.rect(4, 12, 6, 15, 'L'); c.rect(9, 12, 11, 15, 'L')
    c.shade('L', 'l', 'k')
    # leather armour over a green torso
    c.rect(3, 6 + b, 12, 12, 'G')
    c.shade('G', 'g', 'd')
    c.rect(4, 7 + b, 11, 11, 'L')
    c.shade('L', 'l', 'k')
    c.line(4, 7 + b, 11, 11, 'k')
    c.put(7, 11, 'M'); c.put(8, 11, 'M')
    c.rect(2, 6 + b, 4, 7 + b, 'M'); c.rect(11, 6 + b, 13, 7 + b, 'M')
    # head with a heavy jaw and tusks
    c.rect(5, 2 + b, 10, 6 + b, 'G')
    c.shade('G', 'g', 'd')
    c.line(5, 2 + b, 10, 2 + b, 'H')
    c.put(7, 4 + b, 'E'); c.put(9, 4 + b, 'E')
    c.put(6, 6 + b, 'W'); c.put(10, 6 + b, 'W'); c.put(6, 5 + b, 'W'); c.put(10, 5 + b, 'W')
    # arm and a broad cleaver
    c.line(12, 8 + b, 13, 10, 'G')
    c.line(13, 11, 13, 9, 'O')
    c.poly([(12, 9), (15.9, 3 + b), (15.9, 8 + b), (13, 9)], 'A')
    c.rect(13, 2 + b, 15, 8 + b, 'A', only='.')
    c.shade('A', 'a', 'z')
    c.put(14, 4 + b, 'z')
    c.line(3, 8 + b, 2, 11, 'G')
    return c


ORC_PAL = {'G': 0x3a7a3a, 'g': 0x6aaa5a, 'd': 0x1a3a1a, 'L': 0x6a4a2a, 'l': 0x8a6a40, 'k': 0x2a1a0e, 'M': 0x8a8a96,
           'H': 0x101010, 'E': 0xffe020, 'W': 0xf0ead0, 'O': 0x4a3020, 'A': 0xa8b0bc, 'a': 0xe8eef8, 'z': 0x50566a}


# ----------------------------------------------------------------- Orc King (20x20)
def orc_king(t):
    c = Canvas(20, 20)
    b = t
    # fur cloak swaying behind
    c.poly([(3, 6 + b), (14, 6 + b), (15, 19), (1 - t, 19)], 'C')
    c.shade('C', 'c', 'k')
    for x in range(2, 15, 3):
        c.put(x - t, 19, '.')
    # iron-armoured legs
    c.rect(5, 15, 7, 19, 'I'); c.rect(10, 15, 12, 19, 'I')
    # torso in black iron, a fur mantle
    c.rect(4, 7 + b, 13, 15, 'I')
    c.shade('I', 'i', 'z')
    c.line(4, 13, 13, 13, 'L'); c.put(8, 13, 'R')
    c.ellipse(8.5, 7 + b, 6, 1.8, 'F')
    c.shade('F', 'f', 'k')
    # head
    c.rect(6, 3 + b, 11, 7 + b, 'G')
    c.shade('G', 'g', 'd')
    c.put(8, 5 + b, 'E'); c.put(10, 5 + b, 'E')
    c.put(7, 7 + b, 'W'); c.put(11, 7 + b, 'W'); c.put(7, 6 + b, 'W'); c.put(11, 6 + b, 'W')
    # spiked iron crown
    c.rect(6, 2 + b, 11, 3 + b, 'I')
    for x in (6, 8, 10, 11):
        c.put(x, 1 + b, 'I')
    c.put(9, 0 + b, 'i') if b else c.put(8, 1, 'I')
    c.shade('I', 'i', 'z')
    c.put(8, 2 + b, 'R')
    # greatsword raised on the right
    c.line(13, 10 + b, 15, 11, 'G', 1.5)
    c.line(16, 12, 16, 2, 'S', 1)
    c.line(17, 11, 17, 2, 's')
    c.put(16, 1, 's')
    c.line(14, 12, 18, 12, 'Y')
    c.line(16, 13, 16, 15, 'L')
    c.put(16, 16, 'Y')
    return c


ORCK_PAL = {'C': 0x6a4a30, 'c': 0x9a7a54, 'k': 0x2a1a0e, 'I': 0x3e4048, 'i': 0x7a7e88, 'z': 0x18181e, 'L': 0x5a3a20,
            'R': 0xe02020, 'F': 0x8a7a64, 'f': 0xc0b090, 'G': 0x2a6a2a, 'g': 0x5a9a4a, 'd': 0x123a12, 'E': 0xff3020,
            'W': 0xf0ead0, 'S': 0xc8d0dc, 's': 0x80889a, 'Y': 0xf0c030}


# ----------------------------------------------------------------- Pirate Brawler (16x16)
def pirate_brawler(t):
    c = Canvas(16, 16)
    b = t
    # baggy trousers and bare feet
    c.rect(4, 11, 7, 14, 'T'); c.rect(9, 11, 11, 14, 'T')
    c.shade('T', 't', 'k')
    c.rect(4, 15, 6, 15, 'S'); c.rect(9, 15, 11, 15, 'S')
    # striped shirt
    c.rect(4, 6 + b, 11, 11, 'W')
    for y in range(7 + b, 12, 2):
        c.line(4, y, 11, y, 'N')
    c.put(11, 6 + b, 'w'); c.line(11, 7 + b, 11, 10, 'w', only='W')
    c.line(4, 11, 11, 11, 'L')
    # head with a stubbly jaw
    c.rect(5, 2 + b, 10, 5 + b, 'S')
    c.shade('S', 's', 'n')
    c.line(6, 5 + b, 10, 5 + b, 'n')
    c.put(8, 3 + b, 'K'); c.put(10, 3 + b, 'K')
    # red bandana with a knot
    c.rect(5, 1 + b, 10, 2 + b, 'R')
    c.put(4, 2 + b, 'R'); c.put(3, 3 + b, 'R'); c.put(3, 2 + t + b - t, 'r')
    c.line(5, 1 + b, 9, 1 + b, 'r')
    # big fists up, brass knuckles: guard pose
    c.line(11, 7 + b, 13, 9, 'S', 1)
    c.rect(13, 7, 15, 9, 'S'); c.line(13, 7, 15, 7, 'Y')
    c.line(4, 7 + b, 3, 9, 'S', 1)
    c.rect(1, 9 - t, 3, 11 - t, 'S'); c.line(1, 9 - t, 3, 9 - t, 'Y')
    return c


BRAWLER_PAL = {'T': 0x2a2a6a, 't': 0x4a4aa0, 'k': 0x10102a, 'W': 0xf0f0f0, 'w': 0xa8a8b8, 'N': 0x2a2a6a,
               'L': 0x3a2410, 'S': 0xd8a078, 's': 0xf0c8a0, 'n': 0x8a5a3a, 'K': 0x101010, 'R': 0xe02020,
               'r': 0xff6060, 'Y': 0xf0c030}


# ----------------------------------------------------------------- Gorehorn's Warrior (18x18 berserker)
def war_orc(t):
    c = Canvas(18, 18)
    b = t
    # wide stance, bare legs, spiked boots
    c.line(6, 13, 4, 17, 'G', 2); c.line(11, 13, 13, 17, 'G', 2)
    c.rect(2, 17, 5, 17, 'K'); c.rect(12, 17, 15, 17, 'K')
    # bare, hulking torso
    c.poly([(3, 6 + b), (14, 6 + b), (12, 13), (5, 13)], 'G')
    # arms raised high, an axe in each fist
    c.line(4, 7 + b, 2, 3 + b, 'G', 2)
    c.line(13, 7 + b, 15, 3 + b, 'G', 2)
    # head
    c.rect(6, 3 + b, 11, 6 + b, 'G')
    c.shade('G', 'g', 'd')
    # red war paint: a hand print and slashes
    c.line(5, 8 + b, 7, 11, 'R'); c.line(12, 8 + b, 10, 11, 'R')
    c.line(6, 4 + b, 11, 4 + b, 'R')
    c.put(8, 4 + b, 'E'); c.put(10, 4 + b, 'E')
    c.put(7, 6 + b, 'W'); c.put(11, 6 + b, 'W')
    # bone-horned helm
    c.rect(6, 2 + b, 11, 2 + b, 'I')
    c.line(6, 2 + b, 4, 1, 'H'); c.line(11, 2 + b, 13, 1, 'H')
    c.put(3, 1, 'H'); c.put(14, 1, 'H')
    # loin wrap
    c.rect(5, 12, 12, 13, 'L'); c.put(8, 12, 'R')
    # two axes held up (frame 1 lowers them: a roar)
    for (hx, dx) in ((2, -1), (15, 1)):
        c.line(hx, 3 + b, hx, 10 + b, 'O')
        bx = hx + dx
        c.rect(min(bx, bx + dx), 1 + b, max(bx, bx + dx), 4 + b, 'A')
        c.put(hx, 1 + b, 'A')
    c.shade('A', 'a', 'z')
    c.put(1, 2 + b, 'R'); c.put(16, 3 + b, 'R')
    return c


WARORC_PAL = {'G': 0x5a8a3a, 'g': 0x8aba60, 'd': 0x2a4a1a, 'R': 0xff3020, 'E': 0xffe040, 'W': 0xf0ead0,
              'I': 0x3a3a44, 'H': 0xe8dcc0, 'K': 0x2a1a10, 'L': 0x8a2a1a, 'O': 0x4a3020,
              'A': 0xb0b8c4, 'a': 0xf0f4ff, 'z': 0x50566a}


# ----------------------------------------------------------------- Treasure Goblin (16x16)
def loot_goblin(t):
    c = Canvas(16, 16)
    b = t
    # huge gold-stuffed sack over the shoulder, behind
    c.ellipse(5, 7, 4.6, 4.8, 'B')
    c.shade('B', 'b', 'k')
    c.line(3, 2, 7, 2, 'R')
    c.put(5, 1, 'Y'); c.put(3, 4, 'Y'); c.put(6, 3, 'y')
    c.put(2, 8, 'k'); c.put(6, 10, 'k')
    # goblin body hunched forward, to the right
    c.line(9, 12, 8, 15, 'G'); c.line(11, 12, 12, 15, 'G')
    c.poly([(8, 7 + b), (12, 7 + b), (13, 12), (8, 12)], 'V')
    c.shade('V', 'v', 'n')
    c.ellipse(11.5, 5 + b, 2.4, 2.2, 'G')
    c.poly([(13, 4 + b), (15.9, 2 + b), (13, 6 + b)], 'G')
    c.poly([(10, 4 + b), (8, 2 + b), (10, 5 + b)], 'G', only='.')
    c.shade('G', 'g', 'd')
    c.put(12, 5 + b, 'E'); c.put(14, 5 + b, 'E')
    c.put(13, 7 + b, 'W')
    # arm gripping the sack's neck
    c.line(9, 8 + b, 7, 3, 'G')
    # coins spilling from a hole, falling
    c.put(2, 12, 'Y'); c.put(1, 14 - t, 'Y'); c.put(3, 15, 'y'); c.put(5, 15, 'Y')
    c.put(0, 11 + t * 2, 'Y'); c.put(4, 13 + t, 'y')
    return c


LOOT_PAL = {'B': 0x9a7040, 'b': 0xc89a60, 'k': 0x4a3018, 'R': 0xa02020, 'Y': 0xffe040, 'y': 0xd09a10, 'G': 0x6ab040,
            'g': 0xa0e070, 'd': 0x2e5a1a, 'V': 0x6a2a8a, 'v': 0x9a4ac0, 'n': 0x32104a, 'E': 0xffe020, 'W': 0xf0f0e0}


# ----------------------------------------------------------------- Blood Hound (16x16, side view)
def blood_hound(t):
    c = Canvas(16, 16)
    b = t  # panting: head dips
    # legs: sturdy, hind pair angled back
    c.line(2, 10, 1, 15, 'H', 1.6); c.line(5, 11, 5, 15, 'H', 1.2)
    c.line(10, 11, 10, 15, 'H', 1.6); c.line(12, 11, 13, 15, 'H', 1.2)
    # lean body with a deep chest
    c.ellipse(6, 9.5, 5, 2.7, 'H')
    c.ellipse(10, 9.5, 2.7, 3.1, 'H')
    # whip tail raised
    c.line(1, 8, 0, 4 + t, 'H')
    # thick neck, head low and forward
    c.line(10, 8, 12, 5 + b, 'H', 2.5)
    c.ellipse(12.5, 5 + b, 2, 1.7, 'H')
    c.rect(13, 5 + b, 15, 6 + b, 'H')
    c.shade('H', 'h', 'd')
    # swept-back ear
    c.line(11, 4 + b, 9, 3 + b, 'd'); c.put(10, 3 + b, 'd')
    # muzzle: black nose, white fangs
    c.put(15, 5 + b, 'K')
    c.put(14, 7 + b, 'W'); c.put(15, 7 + b, 'd')
    # glowing eye
    c.put(13, 4 + b, 'E')
    # spiked iron collar
    c.line(11, 6 + b, 11, 8 + b, 'C'); c.put(12, 8 + b, 'C')
    c.put(10, 6 + b, 'S'); c.put(10, 8 + b, 'S')
    # ribs on the flank
    c.put(7, 9, 'd'); c.put(8, 10, 'd'); c.put(6, 10, 'd')
    # blood dripping from the jaw
    c.put(14, 8 + b + t, 'B')
    return c


HOUND_PAL = {'H': 0x9a1a24, 'h': 0xd04048, 'd': 0x4a080e, 'K': 0x101010, 'W': 0xf0ead0, 'E': 0xffe040,
             'C': 0x3a3a44, 'S': 0xd0d8e0, 'B': 0xff3040}


# ----------------------------------------------------------------- Cube Shard (16x16, floating)
def cube_shard(t):
    c = Canvas(16, 16)
    b = t  # hover bob
    # a crisp isometric cube, column by column: top face, then left and right faces
    for x in range(2, 13):
        d = abs(x - 7)
        top, mid, bot = 2 + round(d * 0.6), 8 - round(d * 0.6), 13 - round(d * 0.6)
        for y in range(top, bot + 1):
            if y < mid:
                ch = 'T'
            elif x < 7:
                ch = 'L'
            elif x > 7:
                ch = 'R'
            else:
                ch = 'P'
            c.put(x, y + b, ch)
        c.put(x, top + b, 'P')
        if x != 7:
            c.put(x, mid + b, 'P' if x < 7 else 'T')
        c.put(x, bot + b, 'D' if x > 6 else 'R')
    # the corner has sheared off: a jagged notch, the shard floating free
    for (x, y) in [(11, 4), (12, 4), (12, 5), (12, 6), (11, 5), (10, 4)]:
        c.put(x, y + b, '.')
    c.put(10, 5 + b, 'P'); c.put(11, 6 + b, 'T')
    c.put(14, 2 - t + 1, 'T'); c.put(15, 2 - t + 1, 'L'); c.put(14, 3 - t + 1, 'R')
    # a glowing crack down the dark face
    c.line(9, 9 + b, 10, 11 + b, 'G'); c.put(11, 12 + b, 'G')
    # one great eye on the left face, blinking on frame 1
    if t:
        c.line(3, 9 + b, 6, 10 + b, 'D')
    else:
        c.rect(3, 8 + b, 5, 10 + b, 'W')
        c.put(6, 9 + b, 'W'); c.put(6, 10 + b, 'W')
        c.put(4, 9 + b, 'E'); c.put(5, 9 + b, 'K'); c.put(5, 10 + b, 'E')
    # splinters drifting below
    c.put(3, 15 - t, 'P'); c.put(12, 15 - t, 'L')
    return c


CUBE_PAL = {'T': 0xff9cff, 'L': 0xe040e0, 'R': 0xa02aa0, 'D': 0x4a0a4a, 'P': 0xffe0ff, 'W': 0xffffff, 'E': 0x30ffe0,
            'K': 0x101010, 'G': 0x60ffff}


MONSTERS = [
    ('dwarf', dwarf, DWARF_PAL, 3),
    ('dwarf_king', dwarf_king, DKING_PAL, 3),
    ('goblin', goblin, GOBLIN_PAL, 3),
    ('goblin_chief', goblin_chief, GCHIEF_PAL, 3),
    ('golem', golem, GOLEM_PAL, 3),
    ('imp', imp, IMP_PAL, 3),
    ('minotaur', minotaur, MINO_PAL, 3),
    ('ogre', ogre, OGRE_PAL, 3),
    ('orc', orc, ORC_PAL, 3),
    ('orc_king', orc_king, ORCK_PAL, 3),
    ('pirate_brawler', pirate_brawler, BRAWLER_PAL, 3),
    ('war_orc', war_orc, WARORC_PAL, 3),
    ('loot_goblin', loot_goblin, LOOT_PAL, 3),
    ('blood_hound', blood_hound, HOUND_PAL, 3),
    ('cube_shard', cube_shard, CUBE_PAL, 3),
]
