import sys, os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
SP = '/tmp/claude-0/-home-user-New-realm-/9f4eb93a-970c-51e9-8f3f-c0f53d438025/scratchpad'
R = SP + '/ruf/'
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

def shot(name, box=(0, 0, 860, 640)):
    return Image.open(R + name).convert('RGBA').crop(box)

def framed(img, scale):
    im = img.resize((int(img.width * scale), int(img.height * scale)), Image.NEAREST)
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
    bg = img.resize((W, int(img.height * W / img.width)), Image.NEAREST).crop((0, 0, W, H))
    bg = bg.convert('RGBA')
    shade = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(shade)
    for i in range(420):
        a = int(230 * (i / 420) ** 1.4)
        d.line((0, H - 420 + i, W, H - 420 + i), fill=(10, 6, 18, a))
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
    sys.path.insert(0, '/home/user/New-realm-/tools/bossart')
    from designs import DESIGNS
    from animate import frames as animate
    def render(rows, pal, scale):
        h, w = len(rows), len(rows[0])
        img = Image.new('RGBA', (w * scale + 10, h * scale + 10), (0, 0, 0, 0))
        px = img.load()
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch == '.' or ch not in pal: continue
                c = pal[ch]
                for yy in range(scale):
                    for xx in range(scale):
                        px[5 + x * scale + xx, 5 + y * scale + yy] = ((c >> 16) & 255, (c >> 8) & 255, c & 255, 255)
        a = img.split()[3].filter(ImageFilter.MaxFilter(5))
        out = Image.new('RGBA', img.size, (0, 0, 0, 0))
        out.paste((8, 6, 12, 255), mask=a)
        out.alpha_composite(img)
        return out
    bg = background()
    d = ImageDraw.Draw(bg)
    lg = logo(266)
    bg.alpha_composite(lg, (60, 40))
    fh, fs = font(FB, 76), font(FS, 36)
    shadowed(d, (420, 70), str(len(DESIGNS)) + ' bosses. Every one drawn by hand.', fh, GOLD, off=4)
    d.text((424, 170), 'Each with its own attacks, phases, arena and loot, and animations for every move.', font=fs, fill=CREAM)
    sprites = [render(animate(fn, pal)[0][0], animate(fn, pal)[1], 4) for name, fn, pal, s in DESIGNS]
    cols, top = 10, 270
    cw, ch = (W - 80) // cols, (H - top - 30) // 5
    for i, s in enumerate(sprites):
        k = min(1.0, (cw - 8) / s.width, (ch - 8) / s.height)
        if k < 1: s = s.resize((int(s.width * k), int(s.height * k)), Image.NEAREST)
        bg.alpha_composite(s, (40 + (i % cols) * cw + (cw - s.width) // 2, top + (i // cols) * ch + (ch - s.height) // 2))
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
        im = shot(n, (0, 48, 860, 48 + int(860 * (chh - 12) / (cw - 12)))).resize((cw - 12, chh - 12), Image.NEAREST)
        f = Image.new('RGBA', (cw, chh), (255, 77, 255, 255))
        f.alpha_composite(im, (6, 6))
        bg.alpha_composite(f, (40 + (i % 2) * (cw + 40), 250 + (i // 2) * (chh + 20)))
    bg.convert('RGB').save(OUT + path, quality=95)

def run_all():
    roster_card('eldmere_bosses.png')
    hero_card('eldmere_hero.png', shot('pr_ev_titan_4.png', (0, 50, 860, 534)), 'Dodge. Loot. Survive.',
              'A bullet-hell MMO inspired by Realm of the Mad God: 47 hand-drawn bosses, raids, guilds and monthly seasons.')
    side_card('eldmere_events.png', shot('pr_ev_kraken_4.png'), 1.5, 'Realm events that reshape the world',
              'When an event boss rises, the land around it turns into its arena, and it changes again as the fight goes on.',
              ['Wards that shield the boss, menders that heal it', 'Phases with new attacks and arena shifts',
               'Fastest kills go on the Records board'])
    side_card('eldmere_classes.png', shot('md_menu.png', (20, 150, 1090, 530)), 1.18, '11 classes. 3 found only here.',
              'Bard, Alchemist and Chronomancer join the classic eight, each with three abilities to choose from.',
              ['Ironman and Hardcore modes for more luck', 'Skill trees, pets and cosmetics',
               'Godly sets, uniques and Starforged gear'])
    side_card('eldmere_guilds.png', shot('gh_maker.png'), 1.5, 'Build your guild a home',
              'Every guild gets its own Guild Hall in the Nexus: a shared bank, weekly goals, and banners you design yourselves.',
              ['Banner Maker: patterns, emblems, colours', 'Weekly guild goals and a guild ranking',
               'Your banner flies by every member\'s name'])
    collage('eldmere_bosses_fight.png', ['pr_ev_titan_1.png', 'pr_ev_wyrm_0.png', 'pr_ev_phoenix_4.png', 'pr_ev_behemoth_4.png'],
            'Every boss fights differently', 'Telegraphed blasts, bullet storms, summons and enrage phases. Learn them, or fall.')

run_all()
