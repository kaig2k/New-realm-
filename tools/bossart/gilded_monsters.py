"""
The realm's regular monsters, gilded: drawn on the heroes' own pixel (5px, a small grid of chunky pixels), in deep
jewel colours with gold trim and glowing eyes, shaded light and dark per colour exactly as the Gilded heroes are
(heroes_polished.polish). Their attack is a pose (a crouch, then a lunge), with no glow or flash.

Each design faces right. Z is gold, E eyes, S skin (the heroes' skin tone), B boots; other capitals are materials
(lit and shaded automatically), lower case a material's own dark.

    python3 tools/bossart/gilded_monsters.py sheet.png        every monster beside a gilded hero
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from canvas import Canvas
import heroes_polished as hp

Z = 0xe0b040
SCALE = 5

D = {}


def m(name, rows, pal):
    D[name] = (rows, pal)


# ------------------------------------------------------------------ people
m('bandit', ["..HHHH...", ".HHHHHH..", ".HSESEH.W", ".MMMMMM.W", "CCCZZCCSZ", ".CCCCCC..", ".LLZZLL..", ".LL..LL..",
             ".BB..BB.."],
  {'H': 0x7a2a2a, 'M': 0x2a2a34, 'C': 0x6a4a2a, 'L': 0x3a2a1a, 'W': 0xd8d8e8, 'E': 0x101010, 'S': 1, 'B': 0x2a1a10})
m('bandit_leader', ["...HHHF..", "..HHHHHF.", "HHHHHHHHH", ".HSESEH.W", ".MMMMMM.W", "RRRZZRRSZ", "RRRZZRR..",
                    ".LLZZLL..", ".LL..LL..", ".BB..BB.."],
  {'H': 0x3a2a3a, 'F': 0xe03040, 'M': 0x2a2a34, 'R': 0x9a1a2a, 'L': 0x3a2a1a, 'W': 0xd8d8e8, 'E': 0x101010, 'S': 1,
   'B': 0x2a1a10})
m('cultist', ["...RR....", "..RRRR...", ".RRRRRR..", ".RkEkER..", ".RRkkRR.W", "RRRZZRRSW", ".RRZZRR.Z", ".RRRRRR..",
              "RRRRRRRR.", ".BB..BB.."],
  {'R': 0x9a1a2a, 'k': 0x1a0a10, 'E': 0xffe040, 'W': 0xd8d8e8, 'S': 1, 'B': 0x1a1010})
m('dwarf', ["..HHHH..A", ".HHZZHH.A", ".HSESEH.W", ".RRRRRR.W", "CRRRRRRSW", "CCRRRRC.W", "CCCZZCC..", ".CC..CC..",
            ".BB..BB.."],
  {'H': 0xa0a0b0, 'R': 0xc84a20, 'C': 0x2a4a9a, 'A': 0xc0c8d8, 'W': 0x8a5a2a, 'E': 0x101010, 'S': 1, 'B': 0x2a1a10})
m('dwarf_king', ["..Z.Z.Z..AA", "..ZZZZZ..AA", "..SESES...L", ".YYYYYYY..L", "PPYYYYYPPSL", "PPPYYYPPP.L",
                 "PPPPZPPPP..", "PPPZZZPPP..", ".PPPPPPP...", ".PP...PP...", ".BB...BB..."],
  {'Y': 0xf0ecd8, 'P': 0x6a2a9a, 'A': 0xc0c8d8, 'L': 0x8a5a2a, 'E': 0x101010, 'S': 1, 'B': 0x2a1a10})
m('elf', ["..GGGG.W.", ".GGGGGG.W", "SGSESEG.W", "..SSSS..W", "GGGZZGGSW", ".GGZZGG.W", ".GGGGGG.W", ".LL..LL..",
          ".BB..BB.."],
  {'G': 0x2a7a4a, 'L': 0x5a4a2a, 'W': 0x8a5a2a, 'E': 0x101010, 'S': 1, 'B': 0x3a2a14})
m('hobbit', ["..HHHH..", ".HHHHHH.", ".HSESEH.", "..SSSS..", "GGGZZGGS", ".GGGGGG.", "..S..S..", ".SS..SS."],
  {'H': 0x6a3a1a, 'G': 0x3a7a3a, 'E': 0x101010, 'S': 1})
m('pirate', ["..RRRR...", ".RRRRRRR.", "..SESE..A", "..SSSS..A", "TRTRTRTSZ", ".TRTRTR..", ".LLZZLL..", ".LL..LL..",
             ".BB..BB.."],
  {'R': 0xc02a2a, 'T': 0xf0ecf0, 'L': 0x2a3a6a, 'A': 0xc0c8d8, 'E': 0x101010, 'S': 1, 'B': 0x2a1a10})
m('pirate_brawler', ["...SSSS...", "..SSSSSS..", "..SESSES..", "..SSmmSS..", "SSTTTTTTSS", "SS.TTTT.SS", "ZZ.TZZT.ZZ",
                     "...LLLL...", "...L..L...", "..BB..BB.."],
  {'T': 0x2a4a9a, 'm': 0x8a3a2a, 'L': 0x3a2a1a, 'E': 0x101010, 'S': 1, 'B': 0x2a1a10})
m('pirate_captain', ["..KKKKK...", "KKKZKKKKK.", "..SESES..A", "..SSSSS..A", "RRRZZZRRSA", ".RRRZRRR..", ".RRRZRRR..",
                     "..LL.LL...", "..LL.LL...", "..BB.BB..."],
  {'K': 0x2a2a34, 'R': 0x9a1a2a, 'L': 0xe8e0d0, 'A': 0xc0c8d8, 'E': 0x101010, 'S': 1, 'B': 0x1a1a1a})
m('royal_guard', ["...RR...A", "..HHHH.AA", ".HHHHHH.L", ".HEhEhH.L", "ZTTZZTTSL", ".TTZZTT.L", ".TTTTTT.L", ".GG..GG..",
                  ".BB..BB.."],
  {'R': 0xe03040, 'H': 0xd8d8e4, 'h': 0x7a7a8a, 'T': 0xb02a3a, 'G': 0xa0a0b0, 'A': 0xc0c8d8, 'L': 0x6a4a2a,
   'E': 0x101010, 'B': 0x2a2a30})
m('siege_soldier', ["..HHHH..A", ".HHHHHH.L", ".HEhEhHQQ", ".hHHHHhQQ", "MMMZZMMQQ", ".MMMMMMQQ", ".MMZZMMQQ", ".GG..GG..",
                    ".GG..GG..", ".BB..BB.."],
  {'H': 0x9a9aa8, 'h': 0x5a5a68, 'M': 0x7a7a88, 'Q': 0xb02a3a, 'G': 0x5a5a68, 'A': 0xc0c8d8, 'L': 0x6a4a2a,
   'E': 0x101010, 'B': 0x2a2a30})
m('star_guard', ["...ZZ...Z", "..HHHH..A", ".HHHHHH.L", ".HEEEEH.L", "ZHHHHHHSL", ".TTZZTT.L", ".TTTTTT.L", ".TZTTZT..",
                 ".GG..GG..", ".BB..BB.."],
  {'H': 0x3a4ab0, 'T': 0x2a2a7a, 'G': 0x8a8aa0, 'A': 0xd8e0ff, 'L': 0x6a5a8a, 'E': 0x80e0ff, 'S': 1, 'B': 0x1a1a2a})

# ------------------------------------------------------------------ greenskins and brutes
m('goblin', ["G.GGGG.G.", ".GGGGGG..", ".GEGGEG.W", "..GmmG..W", ".LLLLLLGZ", ".LLZZLL..", "..L..L...", ".BB..BB.."],
  {'G': 0x5aa03a, 'm': 0x2a1a0a, 'L': 0x6a4a2a, 'W': 0xd8d8e8, 'E': 0xffe040, 'B': 0x2a1a10})
m('goblin_chief', ["..ZWZWZ..", "G.GGGG.G.", ".GGGGGG.K", ".GEGGEG.K", "..GmmG..K", "RRRZZRRGZ", ".RRRRRR..",
                   ".RRZZRR..", "..L..L...", ".BB..BB.."],
  {'G': 0x5aa03a, 'm': 0x2a1a0a, 'R': 0x9a2a2a, 'K': 0x6a4a2a, 'W': 0xf0e8d0, 'L': 0x6a4a2a, 'E': 0xffe040,
   'B': 0x2a1a10})
m('loot_goblin', [".KKKK....", "KKZKKK...", "KKKKKKGGG", "KKKZKKGEG", "KKKKKKGGG", ".KKKKGGG.", "..ZZ.LLL.", "....L..L.",
                  "...BB.BB."],
  {'K': 0x8a6a3a, 'G': 0x5aa03a, 'L': 0x6a4a2a, 'E': 0xffe040, 'B': 0x2a1a10})
m('orc', ["..GGGG...", ".GGGGGG.A", ".GEGGEG.A", ".GmWWmG.L", "MMMZZMMGL", ".MMMMMM.L", ".MMZZMM..", ".LL..LL..",
          ".BB..BB.."],
  {'G': 0x4a8a3a, 'm': 0x1a2a10, 'W': 0xf0ecd8, 'M': 0x6a6a7a, 'A': 0xc0c8d8, 'L': 0x5a3a1a, 'E': 0xff4030,
   'B': 0x2a1a10})
m('war_orc', ["..H.H.H..A", "..HHHHH.AA", ".GHEHEHG.L", ".GGmWmGG.L", "MMMMZMMMGL", "MMMMMMMM.L", "M.MZZZM..L",
              "..MMMMM...", "..LL.LL...", "..BB.BB..."],
  {'H': 0x5a5a6a, 'G': 0x4a8a3a, 'm': 0x1a2a10, 'W': 0xf0ecd8, 'M': 0x7a2a2a, 'A': 0xc0c8d8, 'L': 0x5a3a1a,
   'E': 0xff4030, 'B': 0x2a1a10})
m('orc_king', ["..Z.Z.Z...W", "..ZZZZZ...W", ".GGGGGGG..W", ".GEGGGEG..W", ".GmWGWmG..W", "RMMMZMMMRZZ", "RMMMMMMMRG.",
               "RMMZZZMMR..", "R.MMMMM.R..", "..LL.LL....", "..BB.BB...."],
  {'G': 0x4a8a3a, 'm': 0x1a2a10, 'W': 0xd8d8e8, 'M': 0x8a8a9a, 'R': 0x9a1a2a, 'L': 0x5a3a1a, 'E': 0xff4030,
   'B': 0x2a1a10})
m('ogre', ["...OOOO....", "..OOOOOO.KK", "..OEOOEO.KK", "..OOmmOO..K", ".LLOOOOLL.K", "OOLLLLLLOOK", "OO.LZZL.OO.",
           "OO.LLLL.OO.", "...LLLL....", "...OO.OO...", "..BBB.BBB.."],
  {'O': 0xb8a070, 'm': 0x3a1a0a, 'L': 0x6a4a2a, 'K': 0x5a3a1a, 'E': 0xffe040, 'B': 0x2a1a10})
m('minotaur', ["HH.....HH.A", ".HHMMMHH.AA", "..MEMEM...L", "..MMMMM...L", "..MMZMM...L", "MMMMMMMMMML", "MM.MMMMM..L",
               "MM.MZZMM...", "...MMMMM...", "...MM.MM...", "..BB...BB.."],
  {'H': 0xf0e0c0, 'M': 0x7a4a2a, 'A': 0xc0c8d8, 'L': 0x6a4a2a, 'E': 0xff3030, 'B': 0x2a1a1a})

# ------------------------------------------------------------------ the dead and the dark
m('skeleton', ["..WWWW...", ".WWWWWW..", ".WEWWEW.A", "..WkWkW.A", "...WW...A", "WWWWWWWWZ", "..WkWkW..", "...WWW...",
               "..W..W...", ".WW..WW.."],
  {'W': 0xe8e0c8, 'k': 0x3a3428, 'A': 0xc0c8d8, 'E': 0xff3030})
m('bone_thrall', ["..WWWW...", ".WWWWWW..", ".WEWWEW..", "..WkWkW..", "..RRRR..A", "WRWRRWRWA", ".RRZZRR.A",
                  ".RRRRRR..", "..W..W...", ".WW..WW.."],
  {'W': 0xe8e0c8, 'k': 0x3a3428, 'R': 0x7a1a2a, 'A': 0xc0c8d8, 'E': 0xff3030})
m('lich', ["..Z.Z.Z..G", "..ZZZZZ.GG", "..WEWEW..L", "..WkWkW..L", ".RRRRRRR.L", "RRRZZZRRWL", ".RRRZRRR.L",
           ".RRRRRRR.L", "RRRRRRRRR.", ".RR...RR.."],
  {'R': 0x2a2a5a, 'W': 0xe8e0c8, 'k': 0x2a2a2a, 'G': 0x60e0ff, 'L': 0x6a5a4a, 'E': 0x60e0ff})
m('ghost', ["..GGGG..", ".GGGGGG.", "GGEGGEGG", "GGEGGEGG", "GGGGGGGG", "GGGmmGGG", "GGGGGGGG", "GG.GG.GG", "G...G..G"],
  {'G': 0xe0e8ff, 'm': 0x4a4a8a, 'E': 0x2a2a5a})
m('ghost_god', ["...Z.Z.Z...", "...ZZZZZ...", "..GGGGGGG..", ".GGGGGGGGG.", ".GGEGGGEGG.", "GGGEGGGEGGG", "GGGGGGGGGGG",
                "GGGGmmmGGGG", "GGGGGGGGGGG", "GG.GGG.GGG.", "G...G...G.."],
  {'G': 0xc8d0ff, 'm': 0x3a3a6a, 'E': 0x60e0ff})
m('grave_wraith', ["...WWW.AA", "..WWWWW.A", ".WkEkEW.L", ".WkkkkW.L", "WWWWWWWWL", ".WWWWWW.L", ".WWWWWW.L", "..WWWWW..",
                   "...WWWW..", "....WW..."],
  {'W': 0x3a4a8a, 'k': 0x0a0a1a, 'A': 0xc0c8d8, 'L': 0x6a5a4a, 'E': 0x60e0ff})
m('shade', ["...KKK...", "..KKKKK..", ".KKEKEKK.", ".KKKKKKK.", "KKKKKKKKK", "K.KKKKK.K", "..KKKKK..", "..KKKK...",
            "...KK.K..", "....K...."],
  {'K': 0x5a3a9a, 'E': 0xe0f0ff})

# ------------------------------------------------------------------ demons and spirits
m('demon', [".H.......H.", ".HH.....HH.", "..HRRRRRH..", "..RERRRER..", "..RRmmmRR..", "RRRRRRRRRRR", "RR.RRZRR.RR",
            "RR.RRRRR.RR", "KK.RRRRR.KK", "...RR.RR...", "..KKK.KKK.."],
  {'H': 0xf0e0c0, 'R': 0xc0302a, 'm': 0x3a0a0a, 'K': 0x2a1a1a, 'E': 0xffe040})
m('lesser_demon', ["H.......H", ".H.RRR.H.", "..RRRRR..", "W.RERER.W", "WWRRRRRWW", "W.RRZRR.W", "..RRRRR..", "..R...R..",
                   ".KK...KK."],
  {'H': 0xf0e0c0, 'R': 0xa02a4a, 'W': 0x5a1030, 'K': 0x2a1a1a, 'E': 0xffe040})
m('imp', ["..R..R..Z", "..RRRR.ZZ", "W.RERE..L", "WWRRRRWRL", "W.RRRR..L", "..RRRR...", "..R..R...", ".RR..RR.."],
  {'R': 0xd0402a, 'W': 0x6a1a1a, 'L': 0x8a5a2a, 'E': 0xffe040})
m('djinn', ["...WWW...", "..WWZWW..", "..JJJJJ..", "..JEJEJ..", "..JJJJJ..", "ZJJJJJJJZ", ".JJJJJJJ.", "..JJJJJ..", "...JJJ...",
            "....JJ...", "....J...."],
  {'W': 0xf0f0f0, 'J': 0x3a6ad0, 'E': 0xfff060})
m('sprite', ["W..HH..W", "WW.SE.WW", "WWWFFWWW", ".WWFFWW.", "...FF...", "...F.F.."],
  {'W': 0xa8f0c0, 'H': 0x5ad040, 'F': 0x3aa060, 'E': 0x101010, 'S': 1})
m('sprite_god', ["WW..Z.Z..WW", "WWW.ZZZ.WWW", "WWW.HHH.WWW", ".WW.SES.WW.", "..WWSSSWW..", "...FFFFF...", "..FFZZZFF..",
                 "..FFFFFFF..", ".FFFFFFFFF.", "...S...S..."],
  {'W': 0xf0b0e0, 'H': 0xf0d070, 'F': 0xe060b0, 'E': 0x101010, 'S': 1})
m('mothling', ["W.A...A.W", "WW.AYA.WW", "WWWWYWWWW", "WEWWYWWEW", "WWW.Y.WWW", ".WW.Y.WW.", "....Y...."],
  {'W': 0xd8c8a0, 'Y': 0x5a4a3a, 'A': 0x5a4a3a, 'E': 0x7a3ab0})
m('medusa', ["N.N.N.N..", "NNNNNNNN.", ".NZZZZN..", ".NFEFEN..", "..FFFF...", "VVVZZVVF.", ".VVVVVV..", "..TTTT...",
             "...TTTT..", "..TTT.TT."],
  {'N': 0x3a9a4a, 'F': 0xa8d890, 'V': 0x6a2a8a, 'T': 0x2a7a5a, 'E': 0xffe040})
m('harpy', ["W..HHH..W", "WW.SES.WW", "WWWSSSWWW", ".WWFFFWW.", "..WFFFW..", "...FFF...", "...Z.Z...", "..ZZ.ZZ.."],
  {'W': 0x8a5a3a, 'H': 0x5a2a1a, 'F': 0xc8a070, 'E': 0x101010, 'S': 1})
m('gale_harpy', ["WW..HHH..WW", "WWW.SES.WWW", ".WWWSSSWWW.", "..WWFFFWW..", "...WFFFW...", "....FFF....", "....Z.Z....",
                 "...ZZ.ZZ..."],
  {'W': 0x6aa8e0, 'H': 0xf0f0f0, 'F': 0xe8e8f0, 'E': 0x101010, 'S': 1})

# ------------------------------------------------------------------ beasts
m('wolf', ["......H.H.", "H.....HHHH", "HH...HHEHN", ".HHHHHHHH.", ".HHHHHHH..", ".HH.HH.HH.", ".H..H..H.."],
  {'H': 0x6a6a7a, 'N': 0x101010, 'E': 0xffe040})
m('blood_hound', ["......HH..", "H....HHEHH", "HH..HHHHHN", ".HHHHZZHH.", ".HHHHHHH..", ".HH.HH.HH.", ".H..H..H.."],
  {'H': 0x9a1a24, 'N': 0x101010, 'E': 0xffe040})
m('crab', ["RR.....RR", "RRR...RRR", ".R.E.E.R.", ".RRRRRRR.", "RRRRRRRRR", ".RrrrrrR.", "R.R...R.R"],
  {'R': 0xd8402a, 'r': 0x8a2014, 'E': 0x101010})
m('scorpion', [".TTT......", "T...T.....", "T....Z....", "TT........", ".TTTTTTCC.", "TTTTTTTTEC", ".T.T.T.CC."],
  {'T': 0xc0702a, 'C': 0xa0501a, 'E': 0x101010})
m('temple_scorpion', ["..TTT......", ".T...T.....", ".T....Z....", ".TT........", "..TTTTTTTCC", ".TTTTTTTTEC",
                      "TTTTTTTTCC.", ".T.T.T.T..."],
  {'T': 0xd0a030, 'C': 0xa07a20, 'E': 0xe03040})
m('snake', ["....NNN.", "...NNNEN", "...NN..T", "NN..NN..", ".NZNZN..", "..NN...."],
  {'N': 0xb09a30, 'T': 0xe03040, 'E': 0x101010})
m('great_snake', ["......NNN..", ".....NNENN.", ".....NNNNNT", "..NNN.NN...", ".NNZNNNN...", "NN..NNZNN..", "NZ.....NNN.",
                  "NNN..NNNZN.", ".NNNNNN...."],
  {'N': 0x3a8a3a, 'T': 0xe03040, 'E': 0xffe040})
m('spider', ["K...KK...K", ".K.KKKK.K.", "..KKKKKKE.", "KKKKRKKKKE", "..KKKKKK..", ".K.KKKK.K.", "K...KK...K"],
  {'K': 0x3a2a4a, 'R': 0xe03040, 'E': 0xe03040})
m('spiderling', ["K.KKK.K", ".KKKKE.", "KKKKKKK", ".KKKKK.", "K.K.K.K"], {'K': 0x3a2a4a, 'E': 0xe03040})
m('spider_queen', ["....Z.Z.Z..", "K...ZZZZZ..", ".K.KKKKKK.K", "..KKEKKEKK.", "KKKKKKKKKKK", "..KKKRKKK..", ".K.KRRRKK.K",
                   "K..KKRKKK..", "..K.....K.."],
  {'K': 0x4a2a5a, 'R': 0xe03040, 'E': 0xffe040})
m('cloud_serpent', [".......Z.Z.", "......CCCC.", "......CECCW", "..CCC.CCC..", ".CCCCCCC...", "CC..CCC....", "C.....CCC..",
                    "CC......CC."],
  {'C': 0x7ab8f0, 'W': 0xf0f0ff, 'E': 0xffe040})
m('kraken_tentacle', ["....PP.", "...PP.P", "...PP..", "..PP...", "..PP...", "..PPP..", "...PP..", "..PPP..", ".WWPPWW",
                      "WWWWWWW"],
  {'P': 0xc04a8a, 'W': 0xa8e0f0})
m('clam_cannon', ["..PPPPP..", ".PpPpPpP.", "PPPPPPPPP", "mEmQQmEmm", "PPPPPPPPP", ".PpPpPpP.", "..PPPPP.."],
  {'P': 0xe07a9a, 'p': 0xa04060, 'm': 0x3a0a1a, 'Q': 0xfff0c0, 'E': 0xffe040})

# ------------------------------------------------------------------ slimes, stone and magic
m('green_slime', ["...GG...", "..GGGG..", ".GWGGWG.", ".GEGGEG.", "GGGGGGGG", "GGGGGGGG", ".GGGGGG."],
  {'G': 0x50c040, 'W': 0xf0fff0, 'E': 0x101010})
m('slime', ["....LL..", "...L....", "...GG...", "..GGGG..", ".GWGGWG.", ".GEGGEG.", "GGGGGGGG", ".GGGGGG."],
  {'G': 0x3ab0a0, 'L': 0x5ad040, 'W': 0xf0fff0, 'E': 0x101010})
m('slime_god', ["...Z.Z.Z...", "...ZZZZZ...", "....PPP....", "..PPPPPPP..", ".PPWPPPWPP.", ".PPEPPPEPP.", "PPPPPPPPPPP",
                "PPPPmmmPPPP", "PPPPPPPPPPP", ".PPPPPPPPP."],
  {'P': 0x7a3ac0, 'm': 0x2a0a4a, 'W': 0xf0f0ff, 'E': 0x101010})
m('cubelet', ["ZPPPPPZ", "PPPPPPP", "PPGGGPP", "PPGEGPP", "PPGGGPP", "PPPPPPP", "ZPPPPPZ"],
  {'P': 0x7a3ab0, 'G': 0x60e0ff, 'E': 0x101010})
m('beholder', [".T..T..T.", "..T.T.T..", "..PPPPP..", ".PPWWWPP.", "PPWIIIWPP", "PPWIEIWPP", "PPPWWWPPP", ".PPmmmPP.",
               "..PWPWP.."],
  {'T': 0x9a4ab0, 'P': 0x7a2a9a, 'W': 0xf0f0f0, 'I': 0xe03040, 'm': 0x2a0a2a, 'E': 0x101010})
m('gazer', ["..P.P.P..", ".PPPPPPP.", "PPWWWWWPP", "PWWIIIWWP", "PWWIEIWWP", "PWWIIIWWP", "PPWWWWWPP", ".PPPPPPP.",
            "..P.P.P.."],
  {'P': 0x7a2a9a, 'W': 0xf0f0f0, 'I': 0x50d050, 'E': 0x101010})
m('golem', ["...RRRR...", "..RRRRRR..", "..RERRER..", "RRRRRRRRRR", "RRRRGGRRRR", "RR.RGGR.RR", "RR.RRRR.RR", "...RRRR...",
            "..RR..RR..", "..RR..RR.."],
  {'R': 0x8a8a9a, 'G': 0x60e0ff, 'E': 0x60e0ff})
m('thunder_golem', ["...RRRRR...", "..RRRRRRR..", "..RRERERR..", "RRRRRRRRRRR", "RRRYRRRYRRR", "RR.RRYRR.RR", "RR.RYRRR.RR",
                    "YY.RRRRR.YY", "...RR.RR...", "..RRR.RRR.."],
  {'R': 0x3a3a5a, 'Y': 0xf0e040, 'E': 0x80e0ff})
m('ent', ["..LLLLLL..", ".LLLLLLLL.", "LLLLLLLLLL", ".LLLLLLLL.", "...TTTT...", "..TETTET..", "..TTmmTT..", "T.TTTTTT.T",
          "TTTTTTTTTT", "..TTTTTT..", ".TT.TT.TT."],
  {'L': 0x3a8a3a, 'T': 0x6a4a2a, 'm': 0x2a1a0a, 'E': 0xffe040})

NAMES = sorted(D)
TONES = '0123456789!#$%&*+-:;<=>?@^~'


def polish(g, pal):
    """heroes_polished.polish, for one frame, with single-character tone names however many colours there are."""
    count = {}
    for r in g:
        for ch in r: count[ch] = count.get(ch, 0) + 1
    free = iter(c for c in TONES if c not in pal)
    tones, plan = {}, []
    for base in [k for k in pal if k.isupper() and k not in 'SEB' and count.get(k, 0) >= hp.MIN_PIXELS]:
        lt = next(free); tones[lt] = (base, hp.LIGHT)
        dark = base.lower() if base.lower() in pal else None
        if not dark:
            dark = next(free); tones[dark] = (base, -hp.DARK)
        plan.append((base, lt, dark))
    c = Canvas(len(g[0]), len(g))
    c.g = [list(r) for r in g]
    for base, lt, dark in plan:
        c.shade(base, lt, dark)
    return [c.rows()], tones


def build(name):
    """(the six frames, the palette): idle, a breath, two steps, then the attack's crouch and lunge."""
    rows, pal = D[name]
    w = max(len(r) for r in rows)
    assert all(len(r) == w for r in rows), (name, [len(r) for r in rows])
    pal = dict(pal)
    if pal.get('S') == 1: pal['S'] = hp.SKIN
    pal.setdefault('Z', Z)
    # a blank row on top (room to breathe and stretch) and a column either side (room to lean and lunge)
    g = ['.' * (w + 2)] + ['.' + r + '.' for r in rows]
    (shaded,), tones = polish(g, pal)
    pal = hp.palette(pal, tones)
    from animate import lift, lean, squash, stretch

    def shift(r, dx):
        return ['.' * dx + x[:-dx] if dx > 0 else x[-dx:] + '.' * -dx for x in r]
    f = [shaded, lift(shaded), lean(shaded, 1), lift(lean(shaded, -1)), squash(shaded), shift(stretch(shaded), 1)]
    return f, pal


def designs():
    """For build.py: (name, fn(t, pose) -> Canvas, palette, scale)."""
    out = []
    for n in NAMES:
        frames, pal = build(n)

        def fn(t, pose, frames=frames):
            r = frames[{'idle': 0, 'move': 2, 'attack': 4}[pose] + t]
            c = Canvas(len(r[0]), len(r))
            c.g = [list(x) for x in r]
            return c
        out.append((n, fn, pal, SCALE))
    return out


if __name__ == '__main__':
    from canvas import preview
    import heroes_gilded
    hero = heroes_gilded.hp.build()['knight']
    out = [('(knight)', hero[0][:1], hp.palette(hero[2], hero[1]))]
    for n in NAMES:
        f, p = build(n)
        out.append((n, [f[0]], p))
    preview(out, sys.argv[1] if len(sys.argv) > 1 else '/tmp/gilded_monsters.png', SCALE)
