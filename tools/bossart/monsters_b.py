"""
Eldmere's regular monsters, batch B: bandits, pirates, the undead, guards and
temple beasts. Same kit and style as designs.py (shapes, then shade() per
material, then details), but small: 16x16 for ordinary monsters, up to 20x20
for the big ones. Every design faces right; the game adds the outline.
MONSTERS lists (sprite_name, function, palette, scale).
"""
import math
from canvas import Canvas


# ----------------------------------------------------------------- Bandit: hooded thief, masked, short sword
def bandit(t):
    c = Canvas(16, 16)
    b = t  # a breathing bob of the upper body
    # legs and boots
    c.rect(5, 12, 6, 15, 'L'); c.rect(8, 12, 9, 15, 'L')
    c.rect(4, 15, 6, 15, 'K'); c.rect(8, 15, 10, 15, 'K')
    # cloak and pointed hood
    c.poly([(4, 6 + b), (10, 6 + b), (11, 13), (3, 13)], 'H')
    c.ellipse(7, 4 + b, 2.6, 2.6, 'H')
    c.poly([(5, 2 + b), (2, 7 + b), (5, 6 + b)], 'H')
    c.shade('H', 'h', 'k')
    # face in the hood: eyes over a dark mask
    c.rect(7, 3 + b, 9, 4 + b, 'S')
    c.rect(7, 5 + b, 9, 5 + b, 'M')
    c.put(8, 4 + b, 'E'); c.put(9, 4 + b, 'E')
    c.put(9, 3 + b, 'h')
    # belt with a pouch
    c.line(4, 10 + b, 10, 10 + b, 'B')
    c.put(7, 10 + b, 'Y')
    c.rect(4, 11 + b, 5, 12 + b, 'B')
    # arm holding a short sword out front
    c.line(9, 7 + b, 11, 9 + b, 'k', 1)
    c.put(11, 9 + b, 'S')
    c.line(12, 8 + b, 15, 5 + b, 'W')
    c.put(15, 5 + b, 'w')
    c.put(12, 9 + b, 'B'); c.put(11, 8 + b, 'B')
    return c


BANDIT_PAL = {'H': 0x404040, 'h': 0x666666, 'k': 0x1e1e1e, 'S': 0xd8a880, 'M': 0x2a2a2a, 'E': 0xffffff,
              'L': 0x4a3828, 'K': 0x1a1210, 'B': 0x7a4a22, 'Y': 0xe0c040, 'W': 0xc8d0d8, 'w': 0xffffff}


# ----------------------------------------------------------------- Bandit Leader: wide hat, red scarf, crossbow, long coat
def bandit_leader(t):
    c = Canvas(16, 16)
    # boots
    c.rect(5, 13, 6, 15, 'K'); c.rect(8, 13, 9, 15, 'K'); c.put(10, 15, 'K')
    # long coat to the shins, split at the front
    c.poly([(4, 6), (10, 6), (11, 14), (3, 14)], 'C')
    c.shade('C', 'c', 'k')
    c.line(8, 9, 8, 14, 'k')
    c.line(4, 10, 10, 10, 'B'); c.put(8, 10, 'Y')
    # face
    c.ellipse(7.5, 4, 2, 2, 'S')
    c.put(9, 4, 'E')
    c.line(6, 5, 9, 5, 'D')  # stubble
    # a wide-brimmed hat
    c.line(3, 2, 12, 2, 'T')
    c.rect(5, 0 + 1, 9, 1, 'T')
    c.line(5, 1, 9, 1, 'T')
    c.put(5, 2, 't'); c.put(6, 1, 't'); c.put(7, 1, 't')
    c.line(5, 2, 9, 2, 'D')  # hat band
    c.line(3, 2, 4, 2, 't')
    # red scarf at the neck, tail fluttering behind
    c.line(5, 6, 9, 6, 'R')
    c.line(5, 6, 2, 8 + t, 'R')
    c.put(1, 8 + t, 'r'); c.put(6, 6, 'r')
    # crossbow levelled forward
    c.line(9, 8, 15, 8, 'O')
    c.line(14, 6, 14, 10, 'O')
    c.put(13, 5, 'O'); c.put(13, 11, 'O')
    c.put(15, 7, 'W')
    c.line(9, 8, 10, 9, 'S')
    return c


LEADER_PAL = {'C': 0x6a1a1a, 'c': 0x9a2a26, 'k': 0x2e0808, 'K': 0x1a1010, 'S': 0xd8a880, 'E': 0x101010,
              'D': 0x8a6a50, 'T': 0x3a2a1e, 't': 0x5a4430, 'R': 0xe02828, 'r': 0xff6040, 'B': 0x2a1a10,
              'Y': 0xf0c040, 'O': 0x8a5a2a, 'W': 0xe0e8f0}


# ----------------------------------------------------------------- Dark Elf Archer: purple skin, white hair, longbow drawn
def elf(t):
    c = Canvas(16, 16)
    # slim legs in dark boots
    c.rect(5, 11, 5, 14, 'q'); c.rect(8, 11, 8, 14, 'q')
    c.rect(4, 15, 5, 15, 'K'); c.rect(8, 15, 9, 15, 'K')
    # long white hair streaming down the back
    c.poly([(4, 2), (6, 1), (5, 5), (5.5, 9 + t), (3.5, 10 + t), (3, 4)], 'H')
    c.shade('H', 'h', 'i')
    # fitted tunic with a gold belt and short skirt
    c.poly([(5, 6), (9, 6), (10, 11), (4, 11)], 'P')
    c.shade('P', 'p', 'q')
    c.line(4, 9, 9, 9, 'G')
    # face, swept white fringe, long pointed ear
    c.ellipse(7.3, 3.6, 1.8, 2, 'V')
    c.shade('V', 'v', 'u')
    c.line(5, 1, 8, 1, 'H'); c.put(5, 2, 'H'); c.put(6, 2, 'h')
    c.put(4, 3, 'v'); c.put(3, 2, 'v')
    c.put(8, 3, 'E')
    # drawing arm back to the string, bow arm forward
    c.line(8, 7, 13, 7, 'V')
    # the longbow: a tall arc on the right
    c.line(13, 2, 14, 4, 'O'); c.line(14, 4, 14, 10, 'O'); c.line(14, 10, 13, 12, 'O')
    c.line(13, 2, 10, 7, 'w'); c.line(10, 7, 13, 12, 'w')
    # arrow nocked, its head glowing
    c.line(10, 7, 15, 7, 'O')
    c.put(15, 7, 'A' if t == 0 else 'a')
    c.put(10, 6, 'A')
    return c


ELF_PAL = {'K': 0x140818, 'P': 0x40204a, 'p': 0x6a3a7a, 'q': 0x1e0a24, 'G': 0xc0a040, 'H': 0xf0f0ff, 'h': 0xffffff,
           'i': 0xa8a8c8, 'V': 0x9a70c0, 'v': 0xc0a0e0, 'u': 0x6a4890, 'E': 0xff4060, 'O': 0x6a4020,
           'w': 0xd0d0d0, 'A': 0x60ff90, 'a': 0xb0ffd0}


# ----------------------------------------------------------------- Pirate: small scrappy deckhand, bandana, eyepatch, cutlass
def pirate(t):
    c = Canvas(16, 16)
    b = t
    # bare feet / short legs
    c.rect(5, 13, 6, 15, 'L'); c.rect(8, 13, 9, 15, 'L')
    c.put(4, 15, 'S'); c.put(10, 15, 'S')
    # striped shirt
    c.rect(4, 8 + b, 9, 12, 'W')
    for y in (9, 11):
        c.line(4, y + b, 9, y + b, 'R')
    c.line(4, 12, 9, 12, 'B')
    # head and bandana with knot tails
    c.ellipse(7, 5.5 + b, 2.2, 2.2, 'S')
    c.shade('S', 's', 'd')
    c.line(5, 4 + b, 9, 4 + b, 'R'); c.line(5, 3 + b, 8, 3 + b, 'R')
    c.put(6, 3 + b, 'r'); c.put(7, 3 + b, 'r')
    c.put(4, 4 + b, 'R'); c.put(3, 5 + b + t, 'R'); c.put(3, 6 + b, 'r')
    # eyepatch and grin
    c.put(8, 5 + b, 'K'); c.line(6, 4 + b, 8, 5 + b, 'K')
    c.put(9, 5 + b, 'E')
    c.put(8, 7 + b, 'd'); c.put(9, 7 + b, 'W')
    # cutlass held high
    c.line(9, 9 + b, 11, 8 + b, 'S')
    c.put(11, 9 + b, 'Y'); c.put(12, 8 + b, 'Y')
    c.line(12, 7 + b, 13, 4 + b, 'M'); c.line(13, 4 + b, 15, 2 + b, 'M')
    c.put(13, 3 + b, 'm')
    return c


DECKHAND_PAL = {'S': 0xd8a070, 's': 0xf0c898, 'd': 0x9a6040, 'R': 0xc02020, 'r': 0xf05040, 'W': 0xf0f0e8,
                'L': 0x3a3a5a, 'B': 0x5a3a1a, 'K': 0x101010, 'E': 0x202020, 'Y': 0xe0b030, 'M': 0xc8d0d8,
                'm': 0xffffff}


# ----------------------------------------------------------------- Pirate Captain: red coat, feathered tricorn, flintlock
def pirate_captain(t):
    c = Canvas(16, 16)
    # boots
    c.rect(5, 12, 6, 15, 'K'); c.rect(8, 12, 9, 15, 'K'); c.put(10, 15, 'K'); c.put(4, 15, 'K')
    # long red coat with gold trim and tails
    c.poly([(4, 6), (10, 6), (11, 13), (8, 13), (7, 11), (6, 13), (3, 13)], 'C')
    c.shade('C', 'c', 'k')
    c.line(7, 7, 7, 10, 'W')  # shirt front
    c.put(8, 8, 'Y'); c.put(8, 10, 'Y')
    c.line(3, 10, 10, 10, 'B'); c.put(6, 10, 'Y')
    # face with a black beard
    c.ellipse(7.5, 4, 1.8, 1.8, 'S')
    c.put(9, 4, 'E')
    c.line(6, 5, 9, 5, 'D'); c.put(7, 6, 'D'); c.put(8, 6, 'D')
    # tricorn hat, gold edge, a plume curling back
    c.poly([(3.5, 3), (12, 3), (10, 1), (5, 1)], 'T')
    c.line(4, 3, 11, 3, 'Y')
    c.put(7, 2, 'W')
    c.line(5, 1, 2, 0 + 1, 'F')
    c.put(1, 2 + t, 'F'); c.put(2, 1, 'f'); c.put(3, 1, 'f')
    # flintlock pistol aimed forward
    c.line(9, 7, 11, 8, 'c')
    c.put(11, 8, 'S')
    c.line(12, 7, 15, 7, 'G')
    c.put(12, 8, 'O'); c.put(12, 9, 'O')
    c.put(13, 6, 'Y')
    if t:
        c.put(15, 6, 'w')
    return c


CAPTAIN_PAL = {'C': 0xb02020, 'c': 0xe04030, 'k': 0x5a0a0a, 'K': 0x1a1210, 'W': 0xf0f0e8, 'Y': 0xf0c030,
               'B': 0x2a1a10, 'S': 0xe0b088, 'E': 0x101010, 'D': 0x20181a, 'T': 0x1a1a24, 'F': 0xf8f8ff,
               'f': 0x80d0ff, 'G': 0x8a8a96, 'O': 0x6a4020, 'w': 0xffe080}


# ----------------------------------------------------------------- Elder's Shade: floating wraith of purple smoke
def shade(t):
    c = Canvas(16, 16)
    b = t
    # wispy tail trailing down into nothing
    c.poly([(4, 8 + b), (11, 8 + b), (10, 12), (7, 15), (8, 12), (5, 13), (6, 11), (3, 13)], 'P')
    # smoky hooded body
    c.ellipse(7.5, 6 + b, 4, 4, 'P')
    c.ellipse(7.5, 3 + b, 3, 2.5, 'P')
    # grasping smoke arms
    c.line(10, 7 + b, 14, 9 + b - t, 'P', 2)
    c.line(5, 7 + b, 1, 10 + b, 'P', 1.5)
    c.shade('P', 'p', 'q')
    # the void under the hood, eyes burning
    c.ellipse(8.5, 4.5 + b, 2, 1.5, 'K')
    c.put(8, 4 + b, 'E'); c.put(10, 4 + b, 'E')
    c.put(9, 5 + b, 'K')
    # claw tips
    c.put(15, 9 + b - t, 'p'); c.put(15, 10 + b - t, 'q')
    # drifting motes
    c.put(2 + t, 14, 'p'); c.put(12, 13 - t, 'p'); c.put(10, 15, 'q')
    return c


SHADE_PAL = {'P': 0x8040c0, 'p': 0xb070f0, 'q': 0x3a1a60, 'K': 0x12041e, 'E': 0xfff060}


# ----------------------------------------------------------------- Bone Soldier: skeleton, rusty shield, spear
def skeleton(t):
    c = Canvas(16, 16)
    # thin leg bones and feet
    c.line(6, 11, 5, 15, 'B'); c.line(9, 11, 10, 15, 'B')
    c.put(4, 15, 'B'); c.put(11, 15, 'B')
    # pelvis and spine
    c.rect(5, 10, 9, 10, 'B')
    c.line(7, 6, 7, 10, 'b')
    # ribcage
    c.rect(5, 6, 9, 9, 'B')
    c.line(5, 7, 9, 7, 'K'); c.line(5, 9, 9, 9, 'K')
    c.line(7, 6, 7, 9, 'B')
    # skull
    c.ellipse(7.5, 3 + t * 0, 2.5, 2.2, 'B')
    c.shade('B', 'W', 'b')
    c.put(8, 3, 'K'); c.put(10, 3, 'K')
    if t == 0:
        c.put(8, 3, 'E')
    c.line(8, 5, 10, 5, 'b'); c.put(9, 5, 'K')
    # spear held upright on the right
    c.line(12, 2, 12, 15, 'O')
    c.poly([(11, 2), (12, -0.2), (13.2, 2)], 'I')
    c.put(12, 0 + 1, 'i')
    c.put(12, 3, 'R')
    c.line(9, 7, 11, 8, 'B'); c.put(12, 8, 'W')
    # rusty round shield in front of the body
    c.ellipse(4, 8.5, 2.6, 3, 'R')
    c.shade('R', 'r', 'd')
    c.put(4, 8, 'I'); c.put(4, 9, 'i')
    return c


BONE_SOLDIER_PAL = {'B': 0xe8e0c0, 'W': 0xfffff0, 'b': 0x9a9070, 'K': 0x1a1410, 'E': 0xff6020,
                    'O': 0x6a4a2a, 'I': 0x8a8a94, 'i': 0xd0d0d8, 'R': 0xa0542a, 'r': 0xd07a3a, 'd': 0x5a2a12}


# ----------------------------------------------------------------- Bone Thrall: hulking skeleton brute, eye fire, chains
def bone_thrall(t):
    c = Canvas(18, 18)
    b = t
    # stubby thick legs
    c.rect(5, 13, 7, 17, 'B'); c.rect(10, 13, 12, 17, 'B')
    c.rect(4, 17, 7, 17, 'B'); c.rect(10, 17, 13, 17, 'B')
    # massive hunched torso: huge ribcage
    c.ellipse(8.5, 9 + b, 5.5, 4.5, 'B')
    # pelvis
    c.rect(5, 12, 12, 13, 'B')
    # gorilla arms hanging to the knees, big fists
    c.line(4, 7 + b, 2, 13, 'B', 2.2)
    c.line(13, 7 + b, 15, 12, 'B', 2.2)
    c.ellipse(2, 14, 1.8, 1.6, 'B')
    c.ellipse(15.5, 13.5, 2, 1.8, 'B')
    # skull thrust forward, low between the shoulders
    c.ellipse(11, 4.5 + b, 3, 2.8, 'B')
    c.rect(11, 6 + b, 14, 7 + b, 'B')
    c.shade('B', 'W', 'b')
    # dark rib gaps
    for y in (8, 10):
        c.line(5, y + b, 11, y + b, 'K')
    c.line(8, 7 + b, 8, 11 + b, 'b')
    # eye sockets with red fire licking up and back
    c.rect(11, 4 + b, 13, 5 + b, 'K')
    c.put(12, 4 + b, 'F'); c.put(13, 4 + b, 'Y')
    c.put(12, 3 + b, 'F'); c.put(11, 2 + b - t, 'F'); c.put(10, 1 + b, 'f' if t else 'F')
    # jaw and teeth
    c.line(12, 7 + b, 14, 7 + b, 'K'); c.put(13, 7 + b, 'W'); c.put(14, 6 + b, 'W')
    # iron shackles and dragging chains
    c.rect(1, 12, 3, 12, 'I'); c.rect(14, 11, 16, 11, 'I')
    for i in range(3):
        c.put(1 - 0 + i * 0, 15 + i, 'C' if i % 2 else 'c')
    c.put(0, 15, 'C'); c.put(0, 16, 'c'); c.put(1, 17, 'C')
    c.put(17, 14, 'C'); c.put(17, 15, 'c'); c.put(17, 16, 'C'); c.put(16, 17, 'c')
    return c


THRALL_PAL = {'B': 0xe8e0c8, 'W': 0xfffff4, 'b': 0x8a8068, 'K': 0x1a0e0e, 'F': 0xff3020, 'f': 0xff8040,
              'Y': 0xffe060, 'I': 0x4a4a52, 'C': 0x7a7a86, 'c': 0xb0b0bc}


# ----------------------------------------------------------------- Star Guard: celestial knight, star shield, glowing visor
def star_guard(t):
    c = Canvas(18, 18)
    # violet cape behind, swaying
    c.poly([(6, 6), (11, 6), (12, 16), (4 - t, 16)], 'V')
    c.shade('V', 'v', 'u')
    # armoured legs
    c.rect(6, 12, 7, 17, 'G'); c.rect(10, 12, 11, 17, 'G')
    c.rect(5, 17, 7, 17, 'G'); c.rect(10, 17, 12, 17, 'G')
    # breastplate and pauldrons
    c.poly([(5, 6), (12, 6), (11, 12), (6, 12)], 'G')
    c.ellipse(5, 6.5, 1.8, 1.5, 'G'); c.ellipse(12.5, 6.5, 1.8, 1.5, 'G')
    # helm
    c.ellipse(9, 3.5, 2.8, 2.8, 'G')
    c.shade('G', 'g', 'o')
    # glowing visor slit
    c.line(9, 3, 11, 3, 'L'); c.put(11, 3, 'W' if t else 'L')
    c.put(9, 0 + 1, 'g')
    # violet tabard strip
    c.line(8, 8, 8, 12, 'V'); c.line(9, 8, 9, 12, 'v')
    # a star crest atop the helm
    c.put(9, 0, '.')
    c.put(8, 1, 'S')
    # lance-sword on the right
    c.line(13, 8, 14, 9, 'G')
    c.line(15, 10, 15, 1, 'M'); c.put(15, 0 + 1, 'W')
    c.line(14, 9, 16, 9, 'o'); c.put(15, 10, 'o')
    # big kite shield on the left with a star emblem
    c.poly([(0.5, 5.5), (6.5, 5.5), (6.5, 11), (3.5, 15), (0.5, 11)], 'G')
    c.shade('G', 'g', 'o')
    c.poly([(1.5, 6.5), (5.5, 6.5), (5.5, 10.5), (3.5, 13.5), (1.5, 10.5)], 'U')
    sx, sy = 3.5, 9
    for (dx, dy) in [(0, -2), (0, -1), (-1, 0), (0, 0), (1, 0), (0, 1), (-1, 2), (1, 2)]:
        c.put(sx + dx, sy + dy, 'S')
    c.put(sx, sy, 'W' if t else 'S')
    # twinkling stars nearby
    c.put(16 if t else 0, 15 if t else 3, 'S')
    return c


STAR_PAL = {'G': 0xffd060, 'g': 0xfff0b0, 'o': 0xa07820, 'V': 0x6a3ac0, 'v': 0x9a6ae8, 'u': 0x2e1660,
            'U': 0x4a2aa8, 'L': 0x80f0ff, 'W': 0xffffff, 'S': 0xffffc0, 'M': 0xd8e0f0}


# ----------------------------------------------------------------- Royal Guard: plumed helm, halberd, gold and red tabard
def royal_guard(t):
    c = Canvas(16, 16)
    # legs in gold greaves
    c.rect(5, 12, 6, 15, 'G'); c.rect(8, 12, 9, 15, 'G')
    c.put(4, 15, 'G'); c.put(10, 15, 'G')
    # body armour
    c.poly([(4, 6), (10, 6), (10, 12), (4, 12)], 'G')
    c.ellipse(4, 6.5, 1.5, 1.2, 'G'); c.ellipse(10, 6.5, 1.5, 1.2, 'G')
    # helm with a nose guard
    c.ellipse(7, 3.5, 2.3, 2.3, 'G')
    c.shade('G', 'g', 'o')
    c.rect(8, 3, 9, 4, 'S'); c.put(9, 3, 'E')
    c.put(7, 4, 'o')
    # red plume sweeping back
    c.line(8, 1, 4, 1, 'P'); c.line(5, 1, 2, 3 + t, 'P'); c.put(2, 4 + t, 'R')
    c.put(3, 2 + t, 'R'); c.put(7, 1, 'p'); c.put(6, 1, 'p')
    # red tabard with a gold stripe
    c.rect(5, 7, 9, 13, 'R')
    c.shade('R', 'r', 'k')
    c.line(7, 7, 7, 13, 'Y')
    c.line(5, 10, 9, 10, 'Y')
    # halberd on the right
    c.line(12, 1, 12, 15, 'O')
    c.put(12, 0, '.')
    c.put(12, 1, 'M')
    c.poly([(13, 2), (15, 1.5), (15.5, 5), (13, 4)], 'M')
    c.put(15, 2, 'm'); c.put(11, 3, 'M')
    c.line(10, 8, 11, 8, 'G'); c.put(12, 8, 'g')
    return c


ROYAL_PAL = {'P': 0xf8f0f0, 'p': 0xb8b0c0, 'G': 0xffd060, 'g': 0xfff0b0, 'o': 0x9a7020, 'R': 0xc02030, 'r': 0xf04a50, 'k': 0x6a0a14,
             'Y': 0xffe070, 'S': 0xe0b088, 'E': 0x101010, 'O': 0x6a4020, 'M': 0xc8d0d8, 'm': 0xffffff}


# ----------------------------------------------------------------- Crimson Cultist: red robe, ritual knife, glowing sigil
def cultist(t):
    c = Canvas(16, 16)
    # floor-length robe, flaring at the hem
    c.poly([(5, 5), (10, 5), (12, 15.5), (2, 15.5)], 'R')
    # tall pointed hood
    c.poly([(4, 6), (5.5, 1), (7.5, 1), (10, 6)], 'R')
    c.ellipse(7, 4, 2.5, 2.3, 'R')
    c.shade('R', 'r', 'k')
    # faceless dark opening, two glowing eyes
    c.rect(7, 3, 9, 5, 'K')
    c.put(8, 4, 'E'); c.put(9, 4, 'E')
    # robe fold and hem trim
    c.line(5, 15, 11, 15, 'k')
    c.line(3, 15, 11, 15, 'G')
    # sigil glowing on the chest
    c.put(6, 8, 'Y'); c.put(8, 8, 'Y'); c.put(7, 7, 'Y'); c.put(7, 9, 'Y')
    c.put(7, 8, 'W' if t else 'Y')
    if t:
        c.put(5, 8, 'O'); c.put(9, 8, 'O'); c.put(7, 6, 'O'); c.put(7, 10, 'O')
    # rope belt
    c.line(4, 11, 10, 11, 'G')
    # arm raising a curved ritual knife
    c.line(9, 7, 12, 5, 'r', 1)
    c.put(12, 5, 'S')
    c.line(12, 4, 13, 1, 'M'); c.put(14, 1, 'M'); c.put(13, 2, 'm')
    c.put(12, 6 + t, 'B')
    return c


CULTIST_PAL = {'R': 0xa01428, 'r': 0xd02a40, 'k': 0x4a0612, 'K': 0x0e0004, 'E': 0xffd040, 'G': 0xc09040,
               'Y': 0xff8a20, 'O': 0xff4a10, 'W': 0xfff8c0, 'S': 0xe8c0a0, 'M': 0xd8d8e0, 'm': 0xffffff,
               'B': 0xff2030}


# ----------------------------------------------------------------- Hobbit Mage: tiny halfling, pointy hat, wand, big feet
def hobbit(t):
    c = Canvas(16, 16)
    b = t
    # huge hairy feet
    c.rect(3, 14, 6, 15, 'F'); c.rect(8, 14, 11, 15, 'F')
    c.put(4, 14, 'f'); c.put(9, 14, 'f')
    c.line(3, 15, 6, 15, 'd'); c.line(8, 15, 11, 15, 'd')
    # little legs and green vest over a purple cloak
    c.rect(5, 12, 5, 13, 'N'); c.rect(9, 12, 9, 13, 'N')
    c.poly([(4, 8 + b), (10, 8 + b), (11, 12), (3, 12)], 'P')
    c.shade('P', 'p', 'q')
    c.rect(6, 8 + b, 8, 11, 'V')
    c.put(7, 9 + b, 'Y')
    # round face, curly hair
    c.ellipse(7, 6.5 + b, 2.2, 1.8, 'S')
    c.put(8, 6 + b, 'E'); c.put(9, 7 + b, 's')
    c.put(5, 7 + b, 'N'); c.put(5, 6 + b, 'N')
    # tall floppy pointed hat
    c.poly([(3, 5.5 + b), (11, 5.5 + b), (8, 3 + b), (6, 0.5 + b), (5, 3 + b)], 'P')
    c.put(5 - t, 1 + b, 'P')
    c.shade('P', 'p', 'q')
    c.line(4, 5 + b, 10, 5 + b, 'Y')
    # stubby arm and wand with a sparkle
    c.line(10, 9 + b, 12, 8 + b, 'P')
    c.line(12, 8 + b, 14, 5 + b, 'O')
    c.put(14, 4 + b, 'W')
    c.put(15, 4 + b, 'L'); c.put(14, 3 + b, 'L'); c.put(13, 4 + b, 'L')
    if t:
        c.put(15, 2, 'L')
    else:
        c.put(12, 2, 'L')
    return c


HOBBIT_PAL = {'P': 0x8040a0, 'p': 0xb070d0, 'q': 0x3e1a54, 'F': 0xd8a070, 'f': 0x6a4020, 'd': 0x9a6a40,
              'N': 0x6a4020, 'V': 0x3a8a3a, 'Y': 0xf0c040, 'S': 0xf0c8a0, 's': 0xff9a9a, 'E': 0x101010,
              'O': 0x8a5a2a, 'W': 0xffffff, 'L': 0x80ffff}


# ----------------------------------------------------------------- Lich: floating skeletal mage, cyan soul-fire, orb
def lich(t):
    c = Canvas(20, 20)
    b = t
    # tattered robe, ragged hem drifting above the ground
    c.poly([(6, 7 + b), (13, 7 + b), (15.5, 17), (14, 20), (12.5, 17.5), (10, 20), (8.5, 17.5), (6.5, 20), (5, 17.5), (3.5, 19)], 'R')
    c.shade('R', 'r', 'k')
    c.line(9.5, 9 + b, 9.5, 17, 'k')
    # a mantle with a cyan clasp
    c.ellipse(9.5, 7.5 + b, 4.5, 1.6, 'M')
    c.shade('M', 'm', 'k')
    c.put(10, 8 + b, 'C')
    # ribs showing at the chest
    c.line(9, 10 + b, 10, 10 + b, 'b'); c.line(9, 12 + b, 10, 12 + b, 'b')
    # soul-fire burning off the crown of the skull
    for i, (x, h) in enumerate([(7, 2), (8.5, 3), (10, 3.5), (11.5, 2.5)]):
        c.line(x, 3 + b, x - 1, max(1, 3 + b - h + ((i + t) % 2)), 'C' if i % 2 else 'c')
    # skull
    c.ellipse(9.8, 4.5 + b, 2.6, 2.6, 'B')
    c.shade('B', 'W', 'b')
    c.rect(10, 4 + b, 12, 4 + b, 'K')
    c.put(11, 4 + b, 'C'); c.put(12, 4 + b, 'c')
    c.line(10, 6 + b, 12, 6 + b, 'K'); c.put(11, 6 + b, 'W')
    # bony arm holding a soul orb out front
    c.line(13, 9 + b, 15, 10 + b, 'R', 1)
    c.line(15, 10 + b, 16, 10 + b, 'B')
    c.ellipse(17, 8.5 + b, 1.8, 1.8, 'C')
    c.put(16.5, 8 + b, 'W'); c.put(17, 9 + b, 'c')
    # a staff of bone in the other hand
    c.line(4, 3, 3, 18, 'b')
    c.put(4, 2, 'B'); c.put(3, 1, 'B'); c.put(5, 1, 'B')
    c.put(4, 1, 'C' if t else 'c')
    c.line(6, 9 + b, 4, 10 + b, 'B')
    # stray soul-sparks
    c.put(17 - t, 15 - t, 'c'); c.put(1, 6 + t, 'c')
    return c


LICH_B_PAL = {'R': 0x34485c, 'r': 0x5a7e92, 'k': 0x121e2a, 'M': 0x3a4a5a, 'm': 0x6a8a9a, 'B': 0xe0dcc8,
              'W': 0xffffff, 'b': 0x8a8670, 'K': 0x061014, 'C': 0x60e0ff, 'c': 0xc0f8ff}


# ----------------------------------------------------------------- Temple Scorpion: golden armoured scorpion, raised stinger
def temple_scorpion(t):
    c = Canvas(16, 16)
    # legs: four pairs splayed beneath
    for i, x in enumerate((3, 5, 7, 9)):
        c.line(x + 1, 11, x, 13, 'g')
        c.line(x, 13, x - 1 + (i % 2), 15, 'g')
    # segmented body
    c.ellipse(7, 10, 5, 2.2, 'A')
    c.ellipse(11, 10, 2.5, 2, 'A')
    # tail arching up and over the back
    pts = [(3, 10), (1.5, 7), (2, 4), (4, 2), (7, 1.5 + t * 0.5)]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        c.line(x0, y0, x1, y1, 'A', 2.2)
    c.shade('A', 'a', 'd')
    # turquoise inlays on the plates
    for x in (5, 8):
        c.put(x, 9, 'T')
    c.put(2, 6, 'T')
    # stinger poised over the head
    c.put(8, 2 + t, 'S'); c.put(9, 3 + t, 'S'); c.put(9, 4 + t, 's')
    # pincers reaching forward
    c.line(12, 10, 13, 8, 'A'); c.line(12, 11, 14, 12, 'A')
    c.ellipse(14, 7.5, 1.3, 1.1, 'a'); c.put(15, 7 - t, 'a'); c.put(15, 8, 'd')
    c.ellipse(14.5, 12, 1.3, 1, 'a'); c.put(15, 13 + t, 'a')
    # eyes
    c.put(12, 9, 'E'); c.put(13, 10, 'E')
    return c


SCORPION_PAL = {'A': 0xffe080, 'a': 0xfff4c0, 'd': 0xa07a20, 'g': 0xb08a30, 'T': 0x30d0c0, 'S': 0xc02040,
                's': 0xff6080, 'E': 0x200000}


# ----------------------------------------------------------------- Gale Harpy: bird-woman, blue feathered wings spread, talons
def gale_harpy(t):
    c = Canvas(20, 20)
    up = -1 if t else 0
    # wings spread wide, feathered trailing edge
    for side in (-1, 1):
        x0 = 10 + side * 2
        c.poly([(x0, 6), (10 + side * 9.5, 2.5 + up), (10 + side * 9.5, 5.5 + up), (10 + side * 8, 10 + up * 0.5),
                (10 + side * 5, 11), (x0, 10)], 'B')
        for k in range(3):
            c.put(10 + side * (5 + k * 1.5), 11 + up * 0.4 - k * 0.6 + 1, 'B')
    c.shade('B', 'b', 'k')
    for side in (-1, 1):
        c.line(10 + side * 3, 7, 10 + side * 9, 3 + up, 'b')
        c.line(10 + side * 4, 9, 10 + side * 8, 8 + up * 0.5, 'k')
    # slender body with a feathered skirt
    c.ellipse(10, 9, 2, 3, 'S')
    c.shade('S', 's', 'd')
    c.poly([(7.5, 11), (12.5, 11), (13, 15), (7, 15)], 'F')
    c.shade('F', 'f', 'k')
    # head, wild sky-blue hair, sharp eyes
    c.ellipse(10.5, 4.5, 1.8, 1.9, 'S')
    c.poly([(8, 2.5), (11, 2), (11, 3.5), (9, 4), (8.5, 8), (7, 7)], 'H')
    c.put(7, 8 + t, 'H')
    c.put(11, 4, 'E'); c.put(12, 5, 'O')
    # scaly legs and hooked talons
    c.line(9, 15, 8.5, 17, 'O'); c.line(11, 15, 11.5, 17, 'O')
    c.line(7, 18, 9, 18, 'O'); c.line(11, 18, 13, 18, 'O')
    c.put(7, 19, 'K'); c.put(13, 19, 'K'); c.put(9, 19, 'K'); c.put(11, 19, 'K')
    # gusts
    c.put(2, 14 - t, 'w'); c.put(3, 14 - t, 'w'); c.put(16, 15 + t, 'w'); c.put(17, 15 + t, 'w')
    return c


HARPY_PAL = {'B': 0x6ab0e0, 'b': 0xa8dcff, 'k': 0x2a5a8a, 'S': 0xe8c8a8, 's': 0xfff0d8, 'd': 0xb08a70,
             'F': 0x4a8ac0, 'f': 0x80c0f0, 'H': 0xe8f8ff, 'E': 0xffd020, 'O': 0xe0a020, 'K': 0x202020,
             'w': 0xe0f8ff}


MONSTERS = [
    ('bandit', bandit, BANDIT_PAL, 3),
    ('bandit_leader', bandit_leader, LEADER_PAL, 3),
    ('elf', elf, ELF_PAL, 3),
    ('pirate', pirate, DECKHAND_PAL, 3),
    ('pirate_captain', pirate_captain, CAPTAIN_PAL, 3),
    ('shade', shade, SHADE_PAL, 3),
    ('skeleton', skeleton, BONE_SOLDIER_PAL, 3),
    ('bone_thrall', bone_thrall, THRALL_PAL, 3),
    ('star_guard', star_guard, STAR_PAL, 3),
    ('royal_guard', royal_guard, ROYAL_PAL, 3),
    ('cultist', cultist, CULTIST_PAL, 3),
    ('hobbit', hobbit, HOBBIT_PAL, 3),
    ('lich', lich, LICH_B_PAL, 3),
    ('temple_scorpion', temple_scorpion, SCORPION_PAL, 3),
    ('gale_harpy', gale_harpy, HARPY_PAL, 3),
]
