"""
Gorehorn in Eldmere's boss style (ref/style/: small, dark, a few tones of
near-black, one glowing accent), after the user's art in ref/gorehorn.png:
a hulking, hunched brute with a great crescent of bone for a horn, a stub of a
second horn, bone claws, and red fury glowing through cracks in his hide and in
his eyes. Pixelled by hand; gorehorn.py animates this picture.
"""

PAL = {
    # hide: deepest, dark, mid, lit edge, rare highlight
    'K': 0x0e0b12, 'D': 0x1e1820, 'M': 0x30262f, 'L': 0x483a45, 'H': 0x62525c,
    # bone: shadow, base, lit
    'o': 0x5e5244, 'b': 0x9c8e76, 'B': 0xd2c6aa,
    # the red: dim, glowing, white-hot
    'r': 0x7a0e16, 'R': 0xd8242a, 'Y': 0xff7a54,
}

ROWS = [
    "..B..........................B..",
    "..bB........................Bb..",
    "...bB......................Bb...",
    "...obB....................Bbo...",
    "....obB..................Bbo....",
    ".....obBb..............bBbo.....",
    "......oobbb.DDDDDDDD.bbboo......",
    ".....DMMoobKDMMMMMMDKbooMMD.....",
    "...DLLMMMMDKMMLLLLMMKDMMMLLD....",
    "..DLMMMMMMDKDMMMMMMDKDMMMMMLD...",
    "..LMMMMMMMDKDYRDDRYDKDMMMMMMMD..",
    ".DLMMMrMMMDKDDDDDDDDKDMMMMrMMMD.",
    ".DMMMMMrMMDKKDDMMDDKDMMMrMMMMMD.",
    ".DMMMMMMMDDKDrRRrDKDDMMMMMMMMMD.",
    ".DDMMMMMDDDKbKrrKbKDDMMMMMMMMDD.",
    ".DDMMMMDDDDDBKKKKBDDDDMMMMMMDDD.",
    "..DDMMMDDKKKKKKKKKKKKKDDMMMMDDD.",
    "..DMMMMDKDDDDKKKKKKDDDDKDMMMMDD.",
    "..DMLMMDKDDDDKDDDDKDDDDKDMMMMDD.",
    "..DMMMMDKDMMDK....KDMMDKDMMMMRD.",
    "..DMMrMDKDMMDK....KDMMDKDMMMrMD.",
    "..DMMMrDKDMDDK....KDDMDKDMMMMMD.",
    "..DMMMMDKDDDK......KDDDKDMMMMDD.",
    "..DDMMMDKKKK........KKKKDMMMDDD.",
    "..DDDMMD................DMMDDDD.",
    "..KDDDDK................KDDDDDK.",
    "..bobobo................obobobo.",
]
W, H = 32, len(ROWS)


class _Pic:
    def __init__(self, rows):
        self._rows = rows

    def rows(self):
        return list(self._rows)


def design():
    assert all(len(r) == W for r in ROWS), [len(r) for r in ROWS]
    return _Pic(ROWS)


if __name__ == '__main__':
    import sys
    from PIL import Image
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    px = im.load()
    for y, row in enumerate(design().rows()):
        for x, ch in enumerate(row):
            if ch != '.':
                v = PAL[ch]
                px[x, y] = ((v >> 16) & 255, (v >> 8) & 255, v & 255, 255)
    im.save(sys.argv[1])
