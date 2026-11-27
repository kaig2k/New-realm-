"""
Hero design concepts on the game's own 8x8 grid (idle frame only), shaded the way heroes_polished.py shades
them, beside today's heroes. Three directions:
  A  Hooded wanderers: dark cloaks and hoods, faces in shadow, glowing eyes (sits with the grim boss art)
  B  Gilded heroes: Eldmere's violet, deep jewel colours and gold trim, a crest or hat that reads at a glance
  C  Bold silhouettes: bigger gear (staff orb, tower shield, longbow, tome), strong shapes that read in a crowd

    python3 tools/bossart/hero_concepts.py out.png
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image, ImageDraw, ImageFont
import heroes_polished as hp

SKIN, EYE, BOOT = 0xf0c898, 0x101010, 0x2a2a30
GLOW_C, GLOW_Y, GLOW_R = 0x70f0ff, 0xffe070, 0xff5040

D = {
    'wizard': {
        'A': (["...KK..G", "..KKKK.Y", ".KkEkEK.", "..kkkk.Y", "KKKTTKKY", ".KKTTKKY", ".KKKKKK.", "..B..B.."],
              {'K': 0x3a2a5a, 'k': 0x0c0814, 'E': GLOW_C, 'T': 0xc8a040, 'Y': 0x8a6a2a, 'G': 0x70f0ff, 'B': BOOT}),
        'B': (["....PG..", "...PPP..", ".YYYYYY.", "..SESE.Y", ".PPSSPPY", "PPPYYPPG", ".PPPPPPY", ".YY..YY."],
              {'P': 0x5a2a9a, 'p': 0x341460, 'Y': 0xe0b040, 'S': SKIN, 'E': EYE, 'G': 0x60e0ff}),
        'C': (["..RRR..O", ".RRRRr.O", ".RSESr.Y", ".WWWWW.Y", "RRWWWRRS", ".RRWRRRY", ".RRRRRR.", "..B..B.."],
              {'R': 0xc0303a, 'r': 0x801820, 'S': SKIN, 'E': EYE, 'W': 0xe8e8f0, 'O': 0xffa020, 'Y': 0x8a6a2a, 'B': BOOT}),
    },
    'knight': {
        'A': (["..KKKK..", ".KKKKKK.", ".KEkEkKW", ".KKKKKKW", "CCMMMMmW", "CQCMMmSA", "CCMMMMm.", "..B..B.."],
              {'K': 0x3a3e48, 'k': 0x101216, 'E': GLOW_R, 'C': 0x701828, 'Q': 0xc8a040, 'M': 0x4a505c, 'm': 0x2a2e36,
               'S': SKIN, 'W': 0xc0c8d8, 'A': 0x8a6a2a, 'B': BOOT}),
        'B': (["...RR...", "..HHHH..", ".HHYYHH.", ".HEhEhHW", "YKMYYMmW", "KQKMMmSA", "KKMYYMm.", "..B..B.."],
              {'R': 0xd03040, 'H': 0xd8d8e4, 'h': 0x8a8a9a, 'Y': 0xe0b040, 'E': EYE, 'K': 0x4a3a8a, 'Q': 0xe0b040,
               'M': 0xb8bccc, 'm': 0x6a6e80, 'S': SKIN, 'W': 0xf0f0ff, 'A': 0xc89030, 'B': BOOT}),
        'C': (["H.HHHH.H", ".HHHHHH.", ".HEhEhHW", "QQHHHHhW", "QAQMMMmW", "QQQMMmSW", ".QMMMMm.", "..B..B.."],
              {'H': 0xc8c8d0, 'h': 0x7a7a86, 'E': EYE, 'Q': 0x3a64c8, 'A': 0xe0b040, 'M': 0xa8acbc, 'm': 0x5a5e70,
               'S': SKIN, 'W': 0xf0f0ff, 'B': BOOT}),
    },
    'archer': {
        'A': (["...GG..W", "..GGGg.W", ".GkEkEg.", "..kkkk.W", "gGLLLLgW", ".gLllLgW", ".gGGGGg.", "..B..B.."],
              {'G': 0x3e5a3a, 'g': 0x22341e, 'k': 0x0c100a, 'E': GLOW_Y, 'L': 0x5a4a32, 'l': 0x3a2e1e, 'W': 0x9a7a4a, 'B': BOOT}),
        'B': ([".R.GGg.W", "..GGGGgW", ".gSESEg.", "..SSSS.W", "YLLLLLYS", ".gLYYLgW", ".gLLLLg.", "..B..B.."],
              {'R': 0xe03040, 'G': 0x2e8a4a, 'g': 0x185a2a, 'S': SKIN, 'E': EYE, 'Y': 0xe0b040, 'L': 0x2a6a3a,
               'W': 0xc08a40, 'B': BOOT}),
        'C': (["..GGG.W.", ".GGGGg.W", "QgSESEgW", "QgSSSS.W", "QLLLLLgW", ".gLllL.W", ".gLLLLW.", "..B..B.."],
              {'G': 0x3a9a3a, 'g': 0x1e5a1e, 'S': SKIN, 'E': EYE, 'Q': 0x8a5a2a, 'L': 0x9a7a3a, 'l': 0x6a5222,
               'W': 0xd8a050, 'B': BOOT}),
    },
    'priest': {
        'A': (["...WW...", "..WWWw..", ".WkEkEw.", "..kkkk.Y", "WWWYYWWL", ".wWYYWwY", ".wWWWWw.", "..B..B.."],
              {'W': 0x8a8a98, 'w': 0x50505e, 'k': 0x0c0c12, 'E': GLOW_Y, 'Y': 0xc8a040, 'L': 0xfff0a0, 'B': BOOT}),
        'B': (["..YYYY..", "...WW...", "..SESE..", "..SSSS.Y", "WWWYYWWS", ".WWYYWWY", ".WYYYYW.", "..B..B.."],
              {'Y': 0xf0c850, 'W': 0xf0eef8, 'S': SKIN, 'E': EYE, 'B': BOOT}),
        'C': (["..WWWW..", ".WWYYWW.", ".WSESEW.", ".WSSSSW.", "WWWYWWBB", ".WWYWWBB", ".WWYWWW.", "..K..K.."],
              {'W': 0xf0eef8, 'Y': 0xe0b040, 'S': SKIN, 'E': EYE, 'B': 0x8a3a2a, 'K': BOOT}),
    },
    'rogue': {
        'A': (["..KKKK..", ".KKKKKk.", ".KkEkEk.", ".RRRRRR.", "KKKKKKKA", ".KKRKKKA", ".KKKKKK.", "..B..B.."],
              {'K': 0x2a2a34, 'k': 0x0a0a0e, 'E': GLOW_R, 'R': 0x9a1a2a, 'A': 0xc0c8d8, 'B': BOOT}),
        'B': (["....R...", "..PPPP..", ".PPPPPPY", ".pSESEp.", "PPYPPYPA", ".PPYYPpA", ".PPPPPP.", "..B..B.."],
              {'R': 0xe03040, 'P': 0x6a2a8a, 'p': 0x3a1450, 'Y': 0xe0b040, 'S': SKIN, 'E': EYE, 'A': 0xd8e0f0, 'B': BOOT}),
        'C': (["..PPPP..", ".PPPPPp.", "APSESEpA", "A.SSSS.A", "APPPPPPS", ".PPKKPp.", ".PPPPPp.", "..B..B.."],
              {'P': 0x5a3a7a, 'p': 0x341e4a, 'S': SKIN, 'E': EYE, 'A': 0xd8e0f0, 'K': 0x2a2a30, 'B': BOOT}),
    },
}
STYLE = {'A': 'A  Hooded wanderers', 'B': 'B  Gilded heroes', 'C': 'C  Bold silhouettes'}

# ---- more directions
MORE = {
    'wizard': {
        'D': (["...TT..O", "..TTTT.Y", ".tSESEt.", "..SSSS.Y", "TTTBBTTY", ".tTBBTtY", ".tTTTTt.", "..K..K.."],
              {'T': 0x2a7a7a, 't': 0x14484a, 'S': SKIN, 'E': EYE, 'B': 0xc89a40, 'O': 0xffd070, 'Y': 0x6a5030, 'K': BOOT}),
        'E': (["...NN..*", "..NNNN.Y", ".nSESEn.", "..SSSS.Y", "NN*NN*NS", ".nNN*NnY", ".nNNNNn.", "..K..K.."],
              {'N': 0x22285a, 'n': 0x10123a, '*': 0xfff0a0, 'S': SKIN, 'E': EYE, 'Y': 0xb8c8ff, 'K': BOOT}),
        'F': (["..O..O..", ".OOOOOO.", ".OEOOEOY", "..OYYO.Y", "RRRWWRRS", ".rRWWRrY", ".rRRRRr.", "..B..B.."],
              {'O': 0x8a6a4a, 'E': 0xffd040, 'Y': 0xe0a040, 'R': 0x6a3a8a, 'r': 0x3a1e50, 'W': 0xd8c8a8, 'S': SKIN, 'B': BOOT}),
    },
    'knight': {
        'D': (["..BBBB..", ".BBGGBB.", ".BGEGEBW", ".BBBBBBW", "TTMMMMmW", "TQTMMmSA", "TTMMMMm.", "..K..K.."],
              {'B': 0xc89a40, 'G': 0x9ad0d0, 'E': 0x1a3a40, 'T': 0x2a6a6a, 'Q': 0xc89a40, 'M': 0x5a6a70, 'm': 0x343e44,
               'S': SKIN, 'W': 0xc0c8d8, 'A': 0x6a5030, 'K': BOOT}),
        'E': (["..NNNN..", ".NN**NN.", ".NEnEnNW", ".nNNNNnW", "**MMMMmW", "N*NMMmSA", "NNMMMMm.", "..K..K.."],
              {'N': 0x2a3070, 'n': 0x141838, '*': 0xfff0a0, 'E': 0x80c8ff, 'M': 0x8a90b8, 'm': 0x4a4e70,
               'S': SKIN, 'W': 0xe0e8ff, 'A': 0xc8a040, 'K': BOOT}),
        'F': ([".G....G.", ".GGGGGG.", ".GEGGEGW", "..GYYG.W", "KKMMMMmW", "KQKMMmSA", "KKMMMMm.", "..B..B.."],
              {'G': 0x7a7a84, 'E': 0xffd040, 'Y': 0x2a2a30, 'K': 0x5a3a2a, 'Q': 0xc8a040, 'M': 0xa0a4b0, 'm': 0x5a5e6a,
               'S': SKIN, 'W': 0xe0e8f0, 'A': 0x8a6a2a, 'B': BOOT}),
    },
    'archer': {
        'D': (["...OO..W", "..OOOo.W", ".oSESEo.", "..SSSS.W", "oTTTTToW", ".oTBBToW", ".oTTTTo.", "..K..K.."],
              {'O': 0xd8a830, 'o': 0x8a6a18, 'S': SKIN, 'E': EYE, 'T': 0x2a6a6a, 'B': 0xc89a40, 'W': 0x8a6a3a, 'K': BOOT}),
        'E': (["...NN..W", "..NN*N.W", ".nSESEn.", "..SSSS.W", "nNNNNNnW", ".nN**NnW", ".nNNNNn.", "..K..K.."],
              {'N': 0x2a3070, 'n': 0x141838, '*': 0xfff0a0, 'S': SKIN, 'E': EYE, 'W': 0xb8c8ff, 'K': BOOT}),
        'F': ([".F....F.", ".FFFFFF.", ".FEFFEFW", "..FWWF.W", "gLLLLLgW", ".gLllLgW", ".gLLLLg.", "..B..B.."],
              {'F': 0xd86a2a, 'E': 0x101010, 'W': 0xf0e8d8, 'g': 0x22341e, 'L': 0x3e5a3a, 'l': 0x22341e, 'B': BOOT}),
    },
    'priest': {
        'D': (["..OOOO..", "..oOOo..", "..SESE..", "..SSSS.Y", "OOOBBOOL", ".oOBBOoY", ".oOOOOo.", "..K..K.."],
              {'O': 0xd8a830, 'o': 0x8a6a18, 'S': SKIN, 'E': EYE, 'B': 0x2a6a6a, 'Y': 0x8a6a3a, 'L': 0xfff0a0, 'K': BOOT}),
        'E': (["..*..*..", "...WW...", "..SESE..", "..SSSS.*", "WWW**WWS", ".WW**WWY", ".WWWWWW.", "..K..K.."],
              {'*': 0xfff0a0, 'W': 0xd8d8f8, 'S': SKIN, 'E': EYE, 'Y': 0x8a90c8, 'K': BOOT}),
        'F': ([".W....W.", ".WWWWWW.", ".WEWWEWY", "..WYYW.Y", "WWWYYWWS", ".wWYYWwY", ".wWWWWw.", "..B..B.."],
              {'W': 0xf0eef8, 'w': 0xa0a0b0, 'E': 0x3a6ac8, 'Y': 0xe0b040, 'S': SKIN, 'B': BOOT}),
    },
    'rogue': {
        'D': (["..TTTT..", ".TTTTTt.", ".tSESEt.", ".OOOOOO.", "TTTTTTTA", ".TTOTTTA", ".TTTTTT.", "..K..K.."],
              {'T': 0x2a4a4a, 't': 0x142828, 'S': SKIN, 'E': EYE, 'O': 0xd8a830, 'A': 0xc0c8d8, 'K': BOOT}),
        'E': (["..NNNN..", ".NNNNNn.", ".nE*nEn.", ".nnnnnn.", "NNN*NNNA", ".NN*NNNA", ".NNNNNN.", "..K..K.."],
              {'N': 0x22285a, 'n': 0x0c0e24, 'E': 0x80c8ff, '*': 0xfff0a0, 'A': 0xe0e8ff, 'K': BOOT}),
        'F': ([".P....P.", ".PPPPPP.", ".PEPPEPA", "..PWWP.A", "KKKKKKKS", ".KKRKKK.", ".KKKKKK.", "..B..B.."],
              {'P': 0x3a3a44, 'E': 0x70ff70, 'W': 0xe8e8f0, 'K': 0x2a2a34, 'R': 0x9a1a2a, 'A': 0xc0c8d8, 'S': SKIN, 'B': BOOT}),
    },
}
for c in MORE: D[c].update(MORE[c])
STYLE.update({'D': 'D  Sea-worn', 'E': 'E  Starfall', 'F': 'F  Beast masks'})



def render(rows, pal, scale):
    im = Image.new('RGBA', (8 * scale, 8 * scale), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == '.' or ch not in pal: continue
            c = pal[ch]
            d.rectangle((x * scale, y * scale, x * scale + scale - 1, y * scale + scale - 1), fill=((c >> 16) & 255, (c >> 8) & 255, c & 255, 255))
    return im


def shaded(rows, pal):
    frames, tones = hp.polish([rows], pal)
    return frames[0], hp.palette(pal, tones)


def sheet(path, which='ABC'):
    classes = list(D)
    cur = hp.source()
    S, GAP = 14, 30
    cw = 8 * S + GAP
    W, H = 260 + len(classes) * cw, 70 + (len(which) + 1) * (8 * S + 46)
    out = Image.new('RGB', (W, H), (26, 20, 40))
    d = ImageDraw.Draw(out)
    fb = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 18)
    fs = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 15)
    for i, c in enumerate(classes):
        d.text((260 + i * cw + 4, 20), c.capitalize(), font=fb, fill=(240, 220, 160))
    rows_l = [('Today', None)] + [(STYLE[k], k) for k in which]
    for j, (label, k) in enumerate(rows_l):
        y = 60 + j * (8 * S + 46)
        d.rectangle((0, y - 8, W, y + 8 * S + 26), fill=(34, 26, 52) if j % 2 else (26, 20, 40))
        d.text((16, y + 8 * S // 2 - 10), label, font=fb, fill=(230, 230, 240))
        for i, c in enumerate(classes):
            if k is None:
                fr, pal = cur[c]
                rows, p = shaded(fr[0], pal)
            else:
                rows, p = shaded(*D[c][k])
            out.paste(render(rows, p, S), (260 + i * cw, y), render(rows, p, S))
            # and at its real in-game size beside it
            small = render(rows, p, 5)
            out.paste(small, (260 + i * cw + 8 * S - 40, y + 8 * S + 2), small)
    out.save(path)


if __name__ == '__main__':
    sheet(sys.argv[1] if len(sys.argv) > 1 else '/tmp/hero_concepts.png', sys.argv[2] if len(sys.argv) > 2 else 'ABC')
