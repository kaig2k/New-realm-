"""
Real animation for the shaded bosses: each model tags its movable parts (m.part: the head,
the arms with whatever they hold, wings, legs, tails, the hem of a robe) and its anchors
(m.anchor: the hands, the head of a staff, a mouth). This file poses those parts frame by
frame and renders every frame through sdfart, so a boss breathes, walks, raises its staff,
swings its blade, calls its minions, braces behind a shield, and falls when it dies.

    idle 4 . move 6 . cast 5 . strike 5 . summon 5 . guard 4 . death 6

Its last phase plays the same frames in rage colours (recolours: no extra frames). The game
picks the animation from the attack (Bosses.posed): summons summon, aimed shots and walls
strike, everything else casts.
"""
import math, colorsys
import sdfart

LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
PAD = 14
SEQ = [('idle', 4), ('move', 6), ('cast', 5), ('strike', 5), ('summon', 5), ('guard', 4), ('death', 6)]


def _arms(p, raiseR, raiseL, upright=0.85):
    """Arms raised (degrees away from the body; negative tucks them in). What they hold (heldR/heldL:
    a staff, a sceptre) mostly stays upright in the hand."""
    p['armR'] = (-raiseR, 0, 0)
    p['armL'] = (raiseL, 0, 0)
    p['heldR'] = (raiseR * upright, 0, 0)
    p['heldL'] = (-raiseL * upright, 0, 0)


def pose(anim, k, spec):
    """The pose for frame k of an animation: part -> (degrees, dx, dy), and the effects to draw."""
    p, fx = {}, []
    fly = spec.get('fly', False)
    weapon = spec.get('weapon', 'armR')
    if anim == 'move' and spec.get('still'):
        anim, k = 'idle', k * 4 / 6          # (it never walks: it just keeps breathing)
    if anim == 'idle':
        ph = k / 4 * math.tau
        b = (1 - math.cos(ph)) / 2
        p['all'] = (0, 0, -(1.2 if fly else 0.6) * b)
        p['head'] = (math.sin(ph) * 2, 0, -0.4 * b)
        _arms(p, 3 * b, 3 * b)
        p['wingR'] = (-8 * b, 0, 0); p['wingL'] = (8 * b, 0, 0)
        p['hem0'] = (4 * math.sin(ph), 0, 0); p['hem1'] = (-4 * math.sin(ph), 0, 0)
        p['tail'] = (5 * math.sin(ph), 0, 0)
        p['jaw'] = (0, 0, 0.5 * b)
    elif anim == 'move':
        ph = k / 6 * math.tau
        s = math.sin(ph)
        if fly or not spec.get('legs', True):
            p['all'] = (3 + 2 * s, 0, -1.5 * abs(s) - (0.5 if fly else 0))
            p['hem0'] = (10 * s, 0, 0); p['hem1'] = (-10 * s, 0, 0)
        else:
            p['all'] = (3, 0, -1.0 * abs(s))
            p['legR'] = (-20 * s, 0, 0); p['legL'] = (20 * s, 0, 0)
            p['legR2'] = (20 * s, 0, 0); p['legL2'] = (-20 * s, 0, 0)
        p['wingR'] = (-16 * s, 0, 0); p['wingL'] = (16 * s, 0, 0)
        _arms(p, 10 * s, -10 * s)
        p['head'] = (2 * s, 0, 0)
        p['tail'] = (-10 * s, 0, 0)
    elif anim == 'cast':
        lift = (0.3, 0.8, 1.0, 0.6, 0.2)[k]
        one = spec.get('cast') == 'one'
        _arms(p, (80 if weapon == 'armR' or not one else 15) * lift, (80 if weapon == 'armL' or not one else 15) * lift)
        p['head'] = (-6 * lift, 0, -0.5 * lift)
        p['all'] = (-3 * lift, 0, -1.0 * lift)
        p['wingR'] = (-25 * lift, 0, 0); p['wingL'] = (25 * lift, 0, 0)
        p['jaw'] = (0, 0, 1.5 * lift)
        fx.append(('cast', (1.2, 2.2, 3.2, 2.4, 1.0)[k]))
    elif anim == 'strike':
        sw = (60, 120, -20, -60, 20)[k]          # the weapon arm: back over the head, then down through
        lean = (-2, -4, 5, 7, 2)[k]
        held = spec.get('held', 'blade')          # a blade swings with the arm; a staff is brought down like a club
        keep = 0.0 if held == 'blade' else 0.45
        if weapon == 'armL':
            p['armL'] = (sw, 0, 0); p['armR'] = (-10, 0, 0); p['heldL'] = (-sw * keep, 0, 0)
        else:
            p['armR'] = (-sw, 0, 0); p['armL'] = (10, 0, 0); p['heldR'] = (sw * keep, 0, 0)
        p['all'] = (lean, 0, (0, -0.5, 0.5, 0.8, 0)[k])
        p['head'] = (lean * 0.6, 0, 0)
        p['wingR'] = (-30 * (k < 2), 0, 0); p['wingL'] = (30 * (k < 2), 0, 0)
        p['tail'] = ((-15, -25, 20, 30, 5)[k], 0, 0)
        p['jaw'] = (0, 0, 1.5 * (k in (2, 3)))
        if k in (2, 3):
            fx.append(('strike', 2.0 if k == 2 else 1.2))
    elif anim == 'summon':
        lift = (0.4, 1.0, 1.0, 0.6, 0.2)[k]
        st = 70 if spec.get('held') == 'staff' else 110      # (a staff held high would leave the frame)
        _arms(p, (st if weapon == 'armR' else 110) * lift, (st if weapon == 'armL' else 110) * lift)
        p['head'] = (-8 * lift, 0, -0.5)
        p['all'] = (0, 0, -2.0 * lift)
        p['wingR'] = (-35 * lift, 0, 0); p['wingL'] = (35 * lift, 0, 0)
        p['jaw'] = (0, 0, 1.5 * lift)
        fx.append(('handR', (1.0, 2.2, 2.8, 2.0, 0.8)[k]))
        fx.append(('handL', (1.0, 2.2, 2.8, 2.0, 0.8)[k]))
    elif anim == 'guard':
        c = (0.6, 1.0, 1.0, 0.5)[k]
        _arms(p, -30 * c, -30 * c)
        p['all'] = (0, 0, 1.0 * c)
        p['head'] = (4 * c, 0, 0.8 * c)
        p['wingR'] = (30 * c, 0, 0); p['wingL'] = (-30 * c, 0, 0)
    elif anim == 'death':
        p['all'] = ((0, -4, -10, -18, -26, -32)[k] * (0.3 if spec.get('heavy') else 1), 0, (0, 1, 2, 3.5, 5, 6)[k])
        _arms(p, -20 * min(1, k / 3), -20 * min(1, k / 3))
        p['head'] = (12 * min(1, k / 3), 0, 1.5 * min(1, k / 3))
        p['wingR'] = (25 * min(1, k / 3), 0, 0); p['wingL'] = (-25 * min(1, k / 3), 0, 0)
    for keys, a in ((('armR', 'armL', 'heldR', 'heldL'), spec.get('arms', 1)), (('wingR', 'wingL'), spec.get('flap', 1))):
        for key in keys:
            if key in p:
                p[key] = (p[key][0] * a,) + tuple(p[key][1:])
    return p, fx


def _accent(mats):
    """The boss's own glow, for its spell effects."""
    for want in ('fx', 'gem', 'orb', 'eye', 'glow', 'core', 'flame', 'fire'):
        if want in mats and mats[want].get('glow'):
            return mats[want]
    for m in mats.values():
        if m.get('glow'):
            return m
    return {'ramp': [0x8060c0, 0xc0a0ff, 0xffffff], 'glow': True}


def frame(fn, anim, k, spec):
    """Render one posed frame: an RGBA image."""
    p, fx = pose(anim, k, spec)
    sdfart.POSE, sdfart.PAD = p, PAD
    try:
        m, mats = fn(k % 2)
    finally:
        sdfart.POSE, sdfart.PAD = {}, 0
    if fx:
        mats = dict(mats)
        mats['fx_'] = dict(_accent(mats), glow0=0.25)
        for at, r in fx:
            q = m.anchors.get(at) or m.anchors.get('handR') or m.anchors.get('cast')
            if not q:
                continue
            # (anchors are already posed: these go straight onto the model)
            m.shapes.append(('ell', (q[0], q[1], 40), (r, r, r), 'fx_', None, (1, 0, 0, 0, 1, 0)))
            # sparks drawn in toward it as it gathers
            for j in range(3):
                a = j * 2.1 + k * 0.9
                d = r + 2.5
                m.shapes.append(('mark', q[0] + math.cos(a) * d, q[1] + math.sin(a) * d, 'fx_', 1, 1))
    img = m.render(mats)
    if anim == 'death' and k >= 3:
        img = _dissolve(img, (0.25, 0.55, 0.85)[k - 3], k)
    return img


def _dissolve(img, f, seed):
    """Death: the body breaks apart into motes, the last of them bright."""
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            if not px[x, y][3]:
                continue
            h = sdfart.hash2(x, y, 11)
            if h < f:
                px[x, y] = (0, 0, 0, 0)
            elif h < f + 0.06:
                c = px[x, y]
                px[x, y] = (min(255, c[0] + 90), min(255, c[1] + 90), min(255, c[2] + 90), 255)
    return img


def rage(v):
    """A colour in the boss's rage: its glows turn to fire, the rest darkens toward blood."""
    r, g, b = ((v >> 16) & 255) / 255, ((v >> 8) & 255) / 255, (v & 255) / 255
    h, s, val = colorsys.rgb_to_hsv(r, g, b)
    if s > 0.45 and val > 0.7:
        r, g, b = colorsys.hsv_to_rgb(0.03 + 0.07 * val, max(s, 0.75), val)
    else:
        k = 0.28
        r, g, b = r * (1 - k) + val * k * 1.25, g * (1 - k) + val * k * 0.3, b * (1 - k) + val * k * 0.25
    c = lambda x: max(0, min(255, int(x * 255)))
    return (c(r) << 16) | (c(g) << 8) | c(b)


def sequences(name, fn, spec, scale=3):
    """Every animation of one boss: [(sprite name, frames as rows, palette, scale)] and its rage recolours."""
    imgs = {anim: [frame(fn, anim, k, spec) for k in range(n)] for anim, n in SEQ}
    # trim the spare room evenly (every frame the same size, the body where it always is)
    boxes = [im.getbbox() for a in imgs.values() for im in a if im.getbbox()]
    W, H = imgs['idle'][0].size
    mx = max(0, min(min(b[0] for b in boxes), min(W - b[2] for b in boxes)) - 1)
    my = max(0, min(min(b[1] for b in boxes), min(H - b[3] for b in boxes)) - 1)
    imgs = {a: [im.crop((mx, my, W - mx, H - my)) for im in v] for a, v in imgs.items()}
    rev, pal = {}, {}
    out = []
    for anim, n in SEQ:
        frames = []
        for im in imgs[anim]:
            px = im.load()
            rows = []
            for y in range(im.height):
                r = []
                for x in range(im.width):
                    q = px[x, y]
                    if q[3] < 128:
                        r.append('.')
                        continue
                    v = (q[0] << 16) | (q[1] << 8) | q[2]
                    if v not in rev:
                        assert len(rev) < len(LETTERS), name + ': too many colours'
                        rev[v] = LETTERS[len(rev)]
                        pal[rev[v]] = v
                    r.append(rev[v])
                rows.append(''.join(r))
            frames.append(rows)
        out.append((name + '_' + anim, frames, pal, scale))
    rp = {k: rage(v) for k, v in pal.items()}
    rec = [(name + '_ridle', name + '_idle', rp), (name + '_rmove', name + '_move', rp)]
    rec += [(name + '_' + anim + '_r', name + '_' + anim, rp) for anim, n in SEQ if anim not in ('idle', 'move', 'death')]
    return out, rec, imgs


def sheet(entries, path, sc=3):
    """A preview: a block per boss, a row per animation."""
    from PIL import Image
    rows = [[imgs[anim] for anim, n in SEQ] for name, imgs in entries]
    fw = max(im.width for r in rows for a in r for im in a) * sc + 4
    fh = max(im.height for r in rows for a in r for im in a) * sc + 4
    cols = max(n for a, n in SEQ)
    per = (len(entries) + 1) // 2 if len(entries) > 3 else len(entries)
    blocks = [rows[i:i + per] for i in range(0, len(rows), per)]
    W = len(blocks) * (cols * fw + 24) + 8
    H = max(len(b) for b in blocks) * len(SEQ) * fh + 8
    s = Image.new('RGBA', (W, H), (150, 146, 142, 255))
    for bi, b in enumerate(blocks):
        for ri, r in enumerate(b):
            for ai, frames in enumerate(r):
                for k, im in enumerate(frames):
                    z = im.resize((im.width * sc, im.height * sc), Image.NEAREST)
                    s.alpha_composite(z, (8 + bi * (cols * fw + 24) + k * fw, 8 + (ri * len(SEQ) + ai) * fh))
    s.convert('RGB').save(path)
