import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
# the screenshots the cards are made from (promo/shots: taken in the real game at 1100 x 640, the roster from
# tools/realmview's roster mode; see promo/shots/README)
R = os.path.join(os.path.dirname(__file__), '..', '..', 'promo', 'shots') + '/'
OUT = '/home/user/New-realm-/promo/'
os.makedirs(OUT, exist_ok=True)
FB = '/home/user/New-realm-/assets/fonts/SourceSansPro-Bold.ttf'
FS = '/home/user/New-realm-/assets/fonts/SourceSansPro-Semibold.ttf'
# the Eldmere logo: the pixel castle over the name band (pixel art: scaled without smoothing)
LOGO = Image.open('/home/user/New-realm-/assets/branding/eldmere_logo_castle.png').convert('RGBA')
GOLD, CREAM, MUTED = (255, 205, 70), (238, 230, 255), (190, 170, 215)
W, H = 1920, 1080

def font(path, size): return ImageFont.truetype(path, size)

def background():
    bg = Image.new('RGBA', (W, H), (14, 10, 22, 255))
    g = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(g)
    for r in range(900, 0, -15):
        d.ellipse((W * 0.7 - r * 1.4, H * 0.45 - r, W * 0.7 + r * 1.4, H * 0.45 + r), fill=(80, 34, 120, 5))
    bg.alpha_composite(g)
    return bg

def logo(w):
    return LOGO.resize((w, int(LOGO.height * w / LOGO.width)), Image.NEAREST)

def shadowed(d, xy, text, f, fill, shadow=(0, 0, 0, 200), off=3):
    d.text((xy[0] + off, xy[1] + off), text, font=f, fill=shadow)
    d.text(xy, text, font=f, fill=fill)

def wrap(d, text, f, width):
    out, line = [], ''
    for w in text.split():
        t = (line + ' ' + w).strip()
        if d.textlength(t, font=f) > width and line: out.append(line); line = w
        else: line = t
    if line: out.append(line)
    return out

def shot(name, box=(0, 0, 1100, 640)):
    return Image.open(R + name).convert('RGBA').crop(box)

def framed(img, scale):
    im = img.resize((int(img.width * scale), int(img.height * scale)), Image.LANCZOS)
    f = Image.new('RGBA', (im.width + 12, im.height + 12), (0, 0, 0, 0))
    d = ImageDraw.Draw(f)
    d.rectangle((0, 0, f.width - 1, f.height - 1), fill=(255, 77, 255, 255))
    d.rectangle((4, 4, f.width - 5, f.height - 5), fill=(30, 20, 40, 255))
    f.alpha_composite(im, (6, 6))
    # drop shadow
    sh = Image.new('RGBA', (f.width + 60, f.height + 60), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rectangle((30, 40, f.width + 30, f.height + 40), fill=(0, 0, 0, 170))
    sh = sh.filter(ImageFilter.GaussianBlur(14))
    sh.alpha_composite(f, (30, 30))
    return sh

def side_card(path, img, scale, head, body, bullets=None):
    bg = background()
    fr = framed(img, scale)
    bg.alpha_composite(fr, (10, (H - fr.height) // 2))
    x0 = fr.width + 10
    tw = W - x0 - 70
    d = ImageDraw.Draw(bg)
    lg = logo(min(399, tw))
    bg.alpha_composite(lg, (x0 + (tw - lg.width) // 2, 70))
    y = 70 + lg.height + 40
    fh = font(FB, 60)
    for line in wrap(d, head, fh, tw):
        shadowed(d, (x0, y), line, fh, GOLD); y += 68
    y += 14
    fb = font(FS, 32)
    for line in wrap(d, body, fb, tw):
        d.text((x0, y), line, font=fb, fill=CREAM); y += 42
    if bullets:
        y += 16
        for b in bullets:
            for i, line in enumerate(wrap(d, b, fb, tw - 34)):
                if i == 0: d.ellipse((x0 + 4, y + 14, x0 + 18, y + 28), fill=GOLD)
                d.text((x0 + 34, y), line, font=fb, fill=MUTED); y += 42
            y += 6
    bg.convert('RGB').save(OUT + path, quality=95)

def hero_card(path, img, head, sub):
    bg = img.resize((W, int(img.height * W / img.width)), Image.LANCZOS).crop((0, 0, W, H))
    bg = bg.convert('RGBA')
    shade = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(shade)
    for i in range(520):
        a = int(255 * min(1, (i / 380)) ** 1.2)
        d.line((0, H - 520 + i, W, H - 520 + i), fill=(10, 6, 18, a))
    bg.alpha_composite(shade)
    lg = logo(532)
    bg.alpha_composite(lg, (70, H - lg.height - 60))
    d = ImageDraw.Draw(bg)
    fh, fs = font(FB, 72), font(FS, 36)
    x = 70 + lg.width + 60
    shadowed(d, (x, H - 250), head, fh, GOLD, off=4)
    y = H - 160
    for line in wrap(d, sub, fs, W - x - 70):
        shadowed(d, (x, y), line, fs, CREAM); y += 46
    bg.convert('RGB').save(OUT + path, quality=95)

def roster_card(path):
    """Every boss's sprite as the game draws it (tools/realmview roster pages: 12 a page on a magenta backdrop)."""
    import glob
    sprites = []
    for f in sorted(glob.glob(R + 'roster_*.png')):
        pg = Image.open(f).convert('RGBA')
        px = pg.load()
        for y in range(pg.height):
            for x in range(pg.width):
                r, g, b, a = px[x, y]
                if r > 240 and g < 20 and b > 240: px[x, y] = (0, 0, 0, 0)
        for k in range(12):
            cell = pg.crop(((k % 4) * 240, (k // 4) * 213, (k % 4) * 240 + 240, (k // 4) * 213 + 213))
            bb = cell.getbbox()
            if bb: sprites.append(cell.crop(bb))
    bg = background()
    d = ImageDraw.Draw(bg)
    lg = logo(266)
    bg.alpha_composite(lg, (60, 40))
    fh, fs = font(FB, 76), font(FS, 36)
    # (how many bosses the game has, as the website counts them: some share a drawing)
    import subprocess
    n = int(subprocess.run(['node', '-e', "const { Data } = require('./server/sim/gen/game'); require('./server/sim/worldsim'); console.log(Object.values(Data.ENEMIES).filter((d) => d.ai === 'boss' && d.spr && !d.prop && !d.stageFoe).length)"],
                           cwd=os.path.join(os.path.dirname(__file__), '..', '..'), capture_output=True, text=True).stdout.strip() or 80)
    shadowed(d, (420, 70), str(n // 5 * 5) + '+ bosses, drawn by hand.', fh, GOLD, off=4)
    d.text((424, 170), str(len(sprites)) + ' designs, each with its own attacks, phases, arena and loot.', font=fs, fill=CREAM)
    cols, top = 12, 260
    rows = (len(sprites) + cols - 1) // cols
    cw, ch = (W - 80) // cols, (H - top - 30) // rows
    for i, s in enumerate(sprites):
        k = min(1.4, (cw - 6) / s.width, (ch - 6) / s.height)
        s = s.resize((max(1, int(s.width * k)), max(1, int(s.height * k))), Image.NEAREST)
        bg.alpha_composite(s, (40 + (i % cols) * cw + (cw - s.width) // 2, top + (i // cols) * ch + (ch - s.height)))
    bg.convert('RGB').save(OUT + path, quality=95)


def collage(path, names, head, sub):
    bg = background()
    d = ImageDraw.Draw(bg)
    lg = logo(266)
    bg.alpha_composite(lg, (60, 30))
    shadowed(d, (360, 50), head, font(FB, 70), GOLD, off=4)
    d.text((364, 140), sub, font=font(FS, 34), fill=CREAM)
    cw, chh = 900, 400
    for i, n in enumerate(names):
        im = shot(n, (0, 0, 1100, int(1100 * (chh - 12) / (cw - 12)))).resize((cw - 12, chh - 12), Image.LANCZOS)
        f = Image.new('RGBA', (cw, chh), (255, 77, 255, 255))
        f.alpha_composite(im, (6, 6))
        bg.alpha_composite(f, (40 + (i % 2) * (cw + 40), 250 + (i // 2) * (chh + 20)))
    bg.convert('RGB').save(OUT + path, quality=95)

def run_all():
    roster_card('eldmere_bosses.png')
    hero_card('eldmere_hero.png', shot('fight_titan_0.png', (0, 0, 1100, 619)), 'Dodge. Loot. Survive.',
              'A bullet-hell MMO inspired by Realm of the Mad God: 80+ hand-drawn bosses, raids, guilds and monthly seasons.')
    side_card('eldmere_events.png', shot('fight_kraken_2.png'), 1.15, 'Realm events that reshape the world',
              'When an event boss rises, the land around it turns into its arena. Up to three rise at once.',
              ['Wards that shield the boss, menders that heal it', 'Phases with new attacks and arena shifts',
               'Fastest kills go on the Records board'])
    side_card('eldmere_lighthouse.png', shot('lighthouse.png'), 1.15, 'Some bosses you beat with the room',
              'In the Drowned Lighthouse, every fight has a rule of its own.',
              ['The Lamplighter can only be hurt in lantern light', 'Ebb and Flow shield each other: pull them apart',
               'Get behind the Bulwark\'s shield; hide from the Keeper\'s wave'])
    collage('eldmere_bosses_fight.png', ['fight_witch_0.png', 'fight_phoenix_2.png', 'fight_sphinx_2.png', 'fight_wrecker_0.png'],
            'Every boss fights differently', 'Telegraphed blasts, bullet storms, summons and arenas of their own. Learn them, or fall.')

if __name__ == '__main__':
    run_all()
