#!/usr/bin/env python3
"""
AS3 -> JavaScript converter for the game's shared logic.

The game is written in ActionScript 3. The server runs the same monsters,
maps and loot, so instead of keeping a second copy by hand this script
translates the classes the server needs (data tables, bosses, world
generation, monster AI) into one JavaScript file:

    python3 tools/as2js.py            writes server/sim/gen/game.js

It handles the subset of AS3 those classes use: classes with static and
instance members, typed locals (with AS3's int/uint truncation and default
values), for each loops, getters, closures, Vectors and Dictionaries.
Rendering members (BitmapData, Matrix...) are left out. Run it again after
changing any of the converted classes.
"""
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SRC = os.path.join(ROOT, 'src', 'realm')
OUT = os.path.join(ROOT, 'server', 'sim', 'gen', 'game.js')

# classes to convert, and members to leave out (rendering, client-only)
CLASSES = ['Data', 'Uniques', 'Godly', 'Bosses', 'World', 'Enemy']
SKIP = {
    'World': {'texture', 'mark', 'blade', 'shallow', 'render', 'chunk', 'drawGround', 'releaseGround', 'drawEdges',
              'reveal', 'minimap', 'seen', 'chunks', 'chunkOrder', 'drawMtx', 'target', 'offX', 'offY', 'trng',
              'MINI_COL', 'dropChunk', 'STONE_PAT', 'WALL_PAT', 'PLAZA_PAT', 'BRICK_PAT', 'MAX_CHUNKS'},
    'Enemy': {'sprite'},
    'Bosses': {'art', 'skins'},
}
# calls inside converted code that the server doesn't do (they become no-ops)
STATEMENT_DROPS = {
    'World': ['render();', 'seen = new BitmapData(N, N, true, 0);',
              # openGate: the minimap and drawn ground chunks are the client's
              'if (minimap) minimap.setPixel(x, y, MINI_COL[c.t]);',
              'for (var dy = __int(-1); dy <= 1; dy++) for (var dx = __int(-1); dx <= 1; dx++) dropChunk(__int((x + dx) / World.CHUNK), __int((y + dy) / World.CHUNK));'],
    'Bosses': ['art();', 'skins();'],
}

KEYWORDS = set('''break case catch class const continue default delete do else extends false finally for function if
implements import in instanceof interface internal is as new null override package private protected public return
static super switch this throw true try typeof var void while with each get set native final dynamic namespace
include use undefined NaN Infinity'''.split())
GLOBALS = set('''Math Object Array String Number Boolean int uint isNaN isFinite parseInt parseFloat Date RegExp Error
JSON trace undefined NaN Infinity arguments Vector Dictionary getTimer console'''.split())
MODIFIERS = {'public', 'private', 'protected', 'internal', 'static', 'override', 'final', 'native'}
INTLIKE = {'int', 'uint'}


# ------------------------------------------------------------------ tokens
class Tok:
    __slots__ = ('k', 'v')

    def __init__(self, k, v):
        self.k = k  # ws, com, str, re, num, id, p
        self.v = v

    def __repr__(self):
        return '%s:%r' % (self.k, self.v)


PUNCT = ['>>>=', '...', '===', '!==', '>>>', '<<=', '>>=', '&&=', '||=', '==', '!=', '<=', '>=', '&&', '||', '++', '--',
         '+=', '-=', '*=', '/=', '%=', '&=', '|=', '^=', '<<', '>>', '::', '.<']


def tokenize(src):
    toks = []
    i, n = 0, len(src)

    def last_sig():
        for t in reversed(toks):
            if t.k not in ('ws', 'com'):
                return t
        return None
    while i < n:
        c = src[i]
        if c in ' \t\r\n':
            j = i
            while j < n and src[j] in ' \t\r\n':
                j += 1
            toks.append(Tok('ws', src[i:j])); i = j; continue
        if src.startswith('//', i):
            j = src.find('\n', i)
            j = n if j < 0 else j
            toks.append(Tok('com', src[i:j])); i = j; continue
        if src.startswith('/*', i):
            j = src.find('*/', i + 2) + 2
            toks.append(Tok('com', src[i:j])); i = j; continue
        if c in '"\'':
            j = i + 1
            while src[j] != c:
                j += 2 if src[j] == '\\' else 1
            toks.append(Tok('str', src[i:j + 1])); i = j + 1; continue
        if c == '/':
            p = last_sig()
            if p is None or (p.k == 'p' and p.v not in (')', ']', '}')) or (p.k == 'id' and p.v in ('return', 'typeof', 'case', 'in')):
                j = i + 1
                cls = False
                while True:
                    ch = src[j]
                    if ch == '\\': j += 2; continue
                    if ch == '[': cls = True
                    elif ch == ']': cls = False
                    elif ch == '/' and not cls: break
                    j += 1
                j += 1
                while j < n and src[j].isalpha():
                    j += 1
                toks.append(Tok('re', src[i:j])); i = j; continue
        if c.isdigit() or (c == '.' and i + 1 < n and src[i + 1].isdigit()):
            m = re.match(r'0[xX][0-9a-fA-F]+|\d*\.?\d+(?:[eE][+-]?\d+)?', src[i:])
            toks.append(Tok('num', m.group(0))); i += len(m.group(0)); continue
        if c.isalpha() or c in '_$':
            m = re.match(r'[A-Za-z_$][A-Za-z0-9_$]*', src[i:])
            toks.append(Tok('id', m.group(0))); i += len(m.group(0)); continue
        for p in PUNCT:
            if src.startswith(p, i):
                toks.append(Tok('p', p)); i += len(p); break
        else:
            toks.append(Tok('p', c)); i += 1
    return toks


def sig(toks):
    """Indexes of significant tokens."""
    return [i for i, t in enumerate(toks) if t.k not in ('ws', 'com')]


def match_close(toks, i):
    """toks[i] is ( [ or {; returns the index of its partner."""
    pairs = {'(': ')', '[': ']', '{': '}'}
    o = toks[i].v
    c = pairs[o]
    d = 0
    for j in range(i, len(toks)):
        t = toks[j]
        if t.k != 'p':
            continue
        if t.v == o:
            d += 1
        elif t.v == c:
            d -= 1
            if d == 0:
                return j
    raise Exception('unbalanced ' + o)


def nxt(toks, i):
    j = i + 1
    while j < len(toks) and toks[j].k in ('ws', 'com'):
        j += 1
    return j


def prv(toks, i):
    j = i - 1
    while j >= 0 and toks[j].k in ('ws', 'com'):
        j -= 1
    return j


def read_type(toks, i):
    """At a type after ':' (toks[i] first type token); returns (type string, index after)."""
    t = toks[i].v
    j = i + 1
    if t == '*':
        return '*', j
    # Vector.<T>
    if t == 'Vector' and j < len(toks) and toks[j].v == '.<':
        d = 1
        k = j + 1
        while d:
            if toks[k].v in ('<', '.<'):
                d += 1
            elif toks[k].v == '>':
                d -= 1
            elif toks[k].v == '>>':
                d -= 2
            k += 1
        return 'Vector', k
    while j < len(toks) and toks[j].v == '.' and toks[j + 1].k == 'id':
        t += '.' + toks[j + 1].v
        j += 2
    return t, j


# ------------------------------------------------------------------ class parsing
class Member:
    def __init__(self):
        self.name = None
        self.static = False
        self.kind = None  # var, const, function, get, set
        self.type = None
        self.init = None  # token list
        self.params = []  # (name, type, default tokens, rest)
        self.ret = None
        self.body = None  # token list (inside braces)


def parse_class(src, cname):
    toks = tokenize(src)
    # find "class Name"
    ci = None
    for i, t in enumerate(toks):
        if t.k == 'id' and t.v == 'class' and toks[nxt(toks, i)].v == cname:
            ci = i
            break
    ob = ci
    while toks[ob].v != '{':
        ob += 1
    cb = match_close(toks, ob)
    members = []
    i = ob + 1
    mods = set()
    while i < cb:
        t = toks[i]
        if t.k in ('ws', 'com') or t.v == ';':
            i += 1
            continue
        if t.k == 'id' and t.v in MODIFIERS:
            mods.add(t.v)
            i += 1
            continue
        if t.k == 'id' and t.v in ('var', 'const'):
            # one or more declarators until ;
            j = nxt(toks, i)
            while True:
                m = Member()
                m.kind = t.v
                m.static = 'static' in mods
                m.name = toks[j].v
                j = nxt(toks, j)
                if toks[j].v == ':':
                    m.type, j = read_type(toks, nxt(toks, j))
                    j = nxt(toks, j - 1) if toks[j].k in ('ws', 'com') else j
                if toks[j].v == '=':
                    s = nxt(toks, j)
                    e = s
                    d = 0
                    while True:
                        v = toks[e].v if toks[e].k == 'p' else None
                        if v in ('(', '[', '{'):
                            d += 1
                        elif v in (')', ']', '}'):
                            d -= 1
                        elif d == 0 and v in (',', ';'):
                            break
                        e += 1
                    m.init = toks[s:e]
                    j = e
                members.append(m)
                if toks[j].v == ',':
                    j = nxt(toks, j)
                    continue
                break
            i = j + 1
            mods = set()
            continue
        if t.k == 'id' and t.v == 'function':
            m = Member()
            m.static = 'static' in mods
            m.kind = 'function'
            j = nxt(toks, i)
            if toks[j].v in ('get', 'set') and toks[nxt(toks, j)].k == 'id':
                m.kind = toks[j].v
                j = nxt(toks, j)
            m.name = toks[j].v
            j = nxt(toks, j)
            pe = match_close(toks, j)
            m.params = parse_params(toks[j + 1:pe])
            j = nxt(toks, pe)
            if toks[j].v == ':':
                m.ret, j = read_type(toks, nxt(toks, j))
                while toks[j].k in ('ws', 'com'):
                    j += 1
            be = match_close(toks, j)
            m.body = toks[j + 1:be]
            members.append(m)
            i = be + 1
            mods = set()
            continue
        raise Exception('%s: unexpected %r near %r' % (cname, t, ''.join(x.v for x in toks[i:i + 20])))
    return members


def parse_params(ptoks):
    params = []
    i = 0
    cur = None
    s = [t for t in ptoks]
    while i < len(s):
        t = s[i]
        if t.k in ('ws', 'com') or t.v == ',':
            i += 1
            continue
        rest = False
        if t.v == '...':
            rest = True
            i = nxt(s, i) if i + 1 < len(s) else i + 1
            t = s[i]
        name = t.v
        typ = None
        dflt = None
        i = nxt(s, i) if i + 1 < len(s) else len(s)
        if i < len(s) and s[i].v == ':':
            typ, i = read_type(s, nxt(s, i))
            while i < len(s) and s[i].k in ('ws', 'com'):
                i += 1
        if i < len(s) and s[i].v == '=':
            a = nxt(s, i)
            e = a
            d = 0
            while e < len(s):
                v = s[e].v if s[e].k == 'p' else None
                if v in ('(', '[', '{'):
                    d += 1
                elif v in (')', ']', '}'):
                    d -= 1
                elif d == 0 and v == ',':
                    break
                e += 1
            dflt = s[a:e]
            i = e
        params.append((name, typ, dflt, rest))
    return params


# ------------------------------------------------------------------ body conversion
def default_for(typ):
    if typ in INTLIKE:
        return '0'
    if typ == 'Number':
        return 'NaN'
    if typ == 'Boolean':
        return 'false'
    if typ in (None, '*'):
        return 'undefined'
    return 'null'


def coerce(typ, expr):
    if typ == 'int':
        return '__int(' + expr + ')'
    if typ == 'uint':
        return '__uint(' + expr + ')'
    return expr


class Ctx:
    def __init__(self, cname, members, all_classes):
        self.cname = cname
        self.inst = {m.name: m for m in members if not m.static}
        self.stat = {m.name: m for m in members if m.static}
        self.all = all_classes


def collect_locals(toks):
    """Names declared with var/const in this function body (not in nested functions), with types."""
    locs = {}
    dicts = set()
    i = 0
    while i < len(toks):
        t = toks[i]
        if t.k == 'id' and t.v == 'function':
            # skip nested function entirely
            j = i
            while toks[j].v != '{':
                j += 1
            i = match_close(toks, j) + 1
            continue
        if t.k == 'id' and t.v in ('var', 'const'):
            j = nxt(toks, i)
            while True:
                name = toks[j].v
                j2 = nxt(toks, j)
                typ = None
                if toks[j2].v == ':':
                    typ, j2 = read_type(toks, nxt(toks, j2))
                locs[name] = typ
                if typ == 'Dictionary':
                    dicts.add(name)
                # skip initializer to a comma at depth 0 to find more declarators
                k = j2
                d = 0
                while k < len(toks):
                    v = toks[k].v if toks[k].k == 'p' else None
                    if v in ('(', '[', '{'):
                        d += 1
                    elif v in (')', ']', '}'):
                        if d == 0:
                            break
                        d -= 1
                    elif d == 0 and v in (';',):
                        break
                    elif d == 0 and v == ',':
                        break
                    elif d == 0 and toks[k].k == 'id' and toks[k].v == 'in':
                        break
                    k += 1
                if k < len(toks) and toks[k].v == ',':
                    j = nxt(toks, k)
                    continue
                break
            i = j + 1
            continue
        i += 1
    return locs, dicts


def expr_end(toks, s):
    """End index (exclusive) of an expression starting at s: stops at ; , or an unmatched closer at depth 0."""
    d = 0
    e = s
    while e < len(toks):
        t = toks[e]
        if t.k == 'p':
            if t.v in ('(', '[', '{'):
                d += 1
            elif t.v in (')', ']', '}'):
                if d == 0:
                    return e
                d -= 1
            elif d == 0 and t.v in (';', ','):
                return e
        e += 1
    return e


def convert_body(toks, ctx, scopes, ret_type, in_static):
    """Converts a function body (token list, braces excluded). scopes: list of dicts name->type (outer first)."""
    locs, dicts = collect_locals(toks)
    scopes = scopes + [locs]
    dict_names = set(dicts)
    for sc in scopes:
        for k, v in sc.items():
            if v == 'Dictionary':
                dict_names.add(k)
    out = []
    i = 0
    brace = []  # stack of 'obj' / 'blk' for { we are inside
    paren_for_each = []  # stack: depth markers for 'for each' rewrite
    n = len(toks)

    def lookup(name):
        for sc in reversed(scopes):
            if name in sc:
                return sc[name]
        return None

    def is_local(name):
        return any(name in sc for sc in scopes)

    def member_type(name):
        if is_local(name):
            return lookup(name)
        if name in ctx.inst and not in_static:
            return ctx.inst[name].type
        if name in ctx.stat:
            return ctx.stat[name].type
        return None

    def ref(name):
        """JS for a bare identifier."""
        if is_local(name):
            return name
        if name in ctx.inst and not in_static:
            return 'this.' + name
        if name in ctx.stat:
            return ctx.cname + '.' + name
        return name

    while i < n:
        t = toks[i]
        if t.k == 'com':
            i += 1
            continue
        if t.k == 'ws':
            out.append(t.v)
            i += 1
            continue
        p = prv(toks, i)
        pv = toks[p].v if p >= 0 else None
        pk = toks[p].k if p >= 0 else None
        if t.k == 'p' and t.v == '{':
            obj = pv in ('(', ',', '=', ':', '?', '[', 'return', '||', '&&', '!', '+') and not (pv == ')')
            brace.append('obj' if obj else 'blk')
            out.append('{')
            i += 1
            continue
        if t.k == 'p' and t.v == '}':
            if brace:
                brace.pop()
            out.append('}')
            i += 1
            continue
        if t.k == 'id':
            v = t.v
            after_dot = pv == '.'
            if after_dot:
                out.append(v)
                i += 1
                continue
            nj = nxt(toks, i)
            nv = toks[nj].v if nj < n else None
            # object literal key
            if brace and brace[-1] == 'obj' and nv == ':' and pv in ('{', ','):
                out.append(v)
                i += 1
                continue
            if v in ('var', 'const'):
                # declarators
                out.append('var')
                j = nxt(toks, i)
                first = True
                while True:
                    name = toks[j].v
                    j2 = nxt(toks, j)
                    typ = None
                    if toks[j2].v == ':':
                        typ, j2 = read_type(toks, nxt(toks, j2))
                        while j2 < n and toks[j2].k in ('ws', 'com'):
                            j2 += 1
                    out.append((' ' if first else ', ') + name)
                    first = False
                    if j2 < n and toks[j2].v == '=':
                        s = nxt(toks, j2)
                        e = expr_end(toks, s)
                        sub = convert_expr(toks[s:e], ctx, scopes, in_static, dict_names)
                        if typ == 'Dictionary':
                            sub = 'new Map()'
                        out.append(' = ' + coerce(typ, sub))
                        j = e
                    else:
                        j = j2
                        if j < n and toks[j].k == 'id' and toks[j].v in ('in', 'of'):
                            out.append(' ')
                            break
                        out.append(' = ' + default_for(typ))
                    if j < n and toks[j].v == ',':
                        j = nxt(toks, j)
                        continue
                    break
                i = j
                continue
            if v == 'for' and nv == 'each':
                # for each (var x:T in coll) -> for (var x of __vals(coll))
                po = nxt(toks, nj)
                pc = match_close(toks, po)
                inner = toks[po + 1:pc]
                k = 0
                d = 0
                while k < len(inner):
                    tk = inner[k]
                    if tk.k == 'p' and tk.v in '([{':
                        d += 1
                    elif tk.k == 'p' and tk.v in ')]}':
                        d -= 1
                    elif d == 0 and tk.k == 'id' and tk.v == 'in':
                        break
                    k += 1
                left = convert_body(inner[:k], ctx, scopes, None, in_static) if False else None
                # left side: "var x:T" or "x"
                lt = [x for x in inner[:k] if x.k not in ('ws', 'com')]
                if lt[0].v == 'var':
                    name = lt[1].v
                    lhs = 'var ' + name
                else:
                    name = lt[0].v
                    lhs = ref(name)
                coll = convert_expr(inner[k + 1:], ctx, scopes, in_static, dict_names)
                out.append('for (' + lhs + ' of __vals(' + coll + '))')
                i = pc + 1
                continue
            if v == 'function':
                # nested function expression -> arrow function (keeps the method's this)
                j = nxt(toks, i)
                fname = None
                if toks[j].k == 'id':
                    fname = toks[j].v
                    j = nxt(toks, j)
                pe = match_close(toks, j)
                params = parse_params(toks[j + 1:pe])
                j = nxt(toks, pe)
                rt = None
                if toks[j].v == ':':
                    rt, j = read_type(toks, nxt(toks, j))
                    while toks[j].k in ('ws', 'com'):
                        j += 1
                be = match_close(toks, j)
                pscope = {pn: pt for (pn, pt, pd, pr) in params}
                body = convert_body(toks[j + 1:be], ctx, scopes + [pscope], rt, in_static)
                ps = param_list(params, ctx, scopes, in_static, dict_names)
                pre = param_coercions(params)
                code = '(' + ps + ') => {' + pre + body + '}'
                if fname:
                    code = 'var ' + fname + ' = ' + code + ';'
                out.append(code)
                i = be + 1
                continue
            if v == 'return' and ret_type in INTLIKE:
                s = nxt(toks, i)
                if toks[s].v != ';':
                    e = expr_end(toks, s)
                    out.append('return ' + coerce(ret_type, convert_expr(toks[s:e], ctx, scopes, in_static, dict_names)))
                    i = e
                    continue
            # assignment to an int/uint name (or this.name)
            if v not in KEYWORDS and nv in ('=', '+=', '-=', '*=', '/=', '%=', '<<=', '>>=', '>>>=', '&=', '|=', '^='):
                typ = member_type(v)
                if typ == 'Vector':
                    typ = None
                if typ in INTLIKE:
                    s = nxt(toks, nj)
                    e = expr_end(toks, s)
                    rhs = convert_expr(toks[s:e], ctx, scopes, in_static, dict_names)
                    target = ref(v)
                    if nv == '=':
                        out.append(target + ' = ' + coerce(typ, rhs))
                    else:
                        out.append(target + ' = ' + coerce(typ, target + ' ' + nv[:-1] + ' (' + rhs + ')'))
                    i = e
                    continue
            if v == 'this' and nv == '.':
                mj = nxt(toks, nj)
                mname = toks[mj].v
                aj = nxt(toks, mj)
                av = toks[aj].v if aj < n else None
                m = ctx.inst.get(mname)
                if m and m.type in INTLIKE and av in ('=', '+=', '-=', '*=', '/=', '%=', '<<=', '>>=', '>>>=', '&=', '|=', '^='):
                    s = nxt(toks, aj)
                    e = expr_end(toks, s)
                    rhs = convert_expr(toks[s:e], ctx, scopes, in_static, dict_names)
                    target = 'this.' + mname
                    if av == '=':
                        out.append(target + ' = ' + coerce(m.type, rhs))
                    else:
                        out.append(target + ' = ' + coerce(m.type, target + ' ' + av[:-1] + ' (' + rhs + ')'))
                    i = e
                    continue
            # Dictionary access d[k] / d[k] = v
            if v in dict_names and nv == '[':
                ce = match_close(toks, nj)
                key = convert_expr(toks[nj + 1:ce], ctx, scopes, in_static, dict_names)
                aj = nxt(toks, ce)
                if aj < n and toks[aj].v == '=' :
                    s = nxt(toks, aj)
                    e = expr_end(toks, s)
                    out.append(v + '.set(' + key + ', ' + convert_expr(toks[s:e], ctx, scopes, in_static, dict_names) + ')')
                    i = e
                else:
                    out.append(v + '.get(' + key + ')')
                    i = ce + 1
                continue
            out.append(rewrite_id(toks, i, ctx, scopes, in_static, ref))
            i = advance_id(toks, i)
            continue
        if t.k == 'p' and t.v == ':' :
            # type annotation in "catch (e:Error)" or leftover; strip ": Type" only after catch params
            out.append(':')
            i += 1
            continue
        out.append(t.v)
        i += 1
    return ''.join(out)


def advance_id(toks, i):
    t = toks[i]
    nj = nxt(toks, i)
    if t.v == 'new' and toks[nj].v == 'Vector':
        # new Vector.<T>(args)
        _, k = read_type(toks, nj)
        while toks[k].k in ('ws', 'com'):
            k += 1
        if toks[k].v == '(':
            return match_close(toks, k) + 1
        return k
    if t.v == 'new' and toks[nj].v == 'Dictionary':
        k = nxt(toks, nj)
        return match_close(toks, k) + 1
    if t.v in ('int', 'uint', 'Number', 'String', 'Boolean') and toks[nj].v == '.':
        return nxt(toks, nxt(toks, nj)) if toks[nxt(toks, nj)].v in ('MAX_VALUE', 'MIN_VALUE', 'NaN') else i + 1
    if t.v == 'is' or t.v == 'as':
        return nxt(toks, nj)  # skip the type name
    return i + 1


def rewrite_id(toks, i, ctx, scopes, in_static, ref):
    t = toks[i]
    v = t.v
    nj = nxt(toks, i)
    nv = toks[nj].v if nj < len(toks) else None
    if v == 'new' and nv == 'Vector':
        _, k = read_type(toks, nj)
        while toks[k].k in ('ws', 'com'):
            k += 1
        if toks[k].v == '(':
            ce = match_close(toks, k)
            args = convert_expr(toks[k + 1:ce], ctx, scopes, in_static, set())
            return '__vec(' + args + ')'
        return '[]'
    if v == 'new' and nv == 'Dictionary':
        return 'new Map()'
    if v == 'int' and nv == '(':
        return '__int'
    if v == 'uint' and nv == '(':
        return '__uint'
    if v in ('int', 'uint', 'Number') and nv == '.':
        mm = toks[nxt(toks, nj)].v
        return {('int', 'MAX_VALUE'): '2147483647', ('int', 'MIN_VALUE'): '-2147483648', ('uint', 'MAX_VALUE'): '4294967295',
                ('Number', 'MAX_VALUE'): 'Number.MAX_VALUE', ('Number', 'NaN'): 'NaN', ('Number', 'MIN_VALUE'): 'Number.MIN_VALUE'}.get((v, mm), v + '.' + mm)
    if v == 'is':
        typ = toks[nj].v
        return {'Array': ' instanceof Array', 'Number': ' __isNum ', 'String': ' __isStr '}.get(typ, ' instanceof ' + typ)
    if v == 'as':
        return ''
    if v == 'trace':
        return 'console.log'
    if v == 'getTimer':
        return '__getTimer'
    if v in KEYWORDS or v in GLOBALS:
        return v
    # a method referenced without calling it keeps its object
    if v in ctx.inst and not in_static and ctx.inst[v].kind == 'function' and nv != '(' and not any(v in sc for sc in scopes):
        return 'this.' + v + '.bind(this)'
    return ref(v)


def convert_expr(toks, ctx, scopes, in_static, dict_names):
    return convert_body(toks, ctx, scopes[:-1] + [scopes[-1]] if scopes else scopes, None, in_static) if toks else ''


def param_list(params, ctx, scopes, in_static, dict_names):
    out = []
    for (name, typ, dflt, rest) in params:
        s = ('...' if rest else '') + name
        if dflt:
            s += ' = ' + convert_expr(dflt, ctx, scopes, in_static, dict_names)
        out.append(s)
    return ', '.join(out)


def param_coercions(params):
    out = ''
    for (name, typ, dflt, rest) in params:
        if typ in INTLIKE and not rest:
            out += ' ' + name + ' = ' + coerce(typ, name) + ';'
    return out


# ------------------------------------------------------------------ class emission
DROP_LINE = re.compile(r'^.*(\bnew BitmapData\b|\bthis\.render\(\);|\bBosses\.(art|skins)\(\);).*$', re.M)


def emit_class(cname, src, all_classes):
    members = parse_class(src, cname)
    skip = SKIP.get(cname, set())
    members = [m for m in members if m.name not in skip]
    ctx = Ctx(cname, members, all_classes)
    lines = ['class ' + cname + ' {']
    inst_fields = [m for m in members if not m.static and m.kind in ('var', 'const')]
    ctor = next((m for m in members if m.kind == 'function' and m.name == cname), None)
    # constructor: instance field defaults, then the AS3 constructor body
    params = ctor.params if ctor else []
    pscope = {pn: pt for (pn, pt, pd, pr) in params}
    init = ''
    for f in inst_fields:
        if f.init:
            init += '\t\tthis.' + f.name + ' = ' + coerce(f.type, convert_body(f.init, ctx, [{}], None, False).strip()) + ';\n'
        else:
            init += '\t\tthis.' + f.name + ' = ' + default_for(f.type) + ';\n'
    body = convert_body(ctor.body, ctx, [pscope], None, False) if ctor else ''
    for d in STATEMENT_DROPS.get(cname, []):
        body = body.replace(d.replace('render();', 'this.render();').replace('seen = new', 'this.seen = new'), '')
        body = body.replace(d, '')
    body = DROP_LINE.sub('', body)
    lines.append('\tconstructor(' + param_list(params, ctx, [pscope], False, set()) + ') {' + param_coercions(params) + '\n' + init + body + '\n\t}')
    for m in members:
        if m.kind in ('var', 'const') or (m.kind == 'function' and m.name == cname):
            continue
        pscope = {pn: pt for (pn, pt, pd, pr) in m.params}
        body = convert_body(m.body, ctx, [pscope], m.ret, m.static)
        for d in STATEMENT_DROPS.get(cname, []):
            body = body.replace(cname + '.' + d, '').replace('this.' + d, '').replace(d, '')
        body = DROP_LINE.sub('', body)
        head = ('static ' if m.static else '') + ('get ' if m.kind == 'get' else 'set ' if m.kind == 'set' else '') + m.name
        lines.append('\t' + head + '(' + param_list(m.params, ctx, [pscope], m.static, set()) + ') {' + param_coercions(m.params) + body + '}')
    lines.append('}')
    statics = []
    for f in members:
        if f.static and f.kind in ('var', 'const'):
            val = coerce(f.type, convert_body(f.init, ctx, [{}], None, True).strip()) if f.init else default_for(f.type)
            statics.append((f.name, val))
    return '\n'.join(lines), statics


def main():
    srcs = {c: open(os.path.join(SRC, c + '.as')).read() for c in CLASSES}
    out = ['// GENERATED by tools/as2js.py from src/realm/*.as - do not edit; edit the .as files and run it again.',
           "'use strict';", "const { __int, __uint, __vec, __vals, __isNum, __isStr, __getTimer, Sprites, Ui, Sfx, Save, Projectile, Game, Player } = require('../shims');", '']
    statics = []
    for c in CLASSES:
        code, st = emit_class(c, srcs[c], CLASSES)
        out.append(code)
        out.append('')
        statics.append((c, st))
    # static fields: classes in order (Data first; later classes may read earlier ones)
    for c, st in statics:
        for name, val in st:
            out.append(c + '.' + name + ' = ' + val + ';')
    out.append('')
    out.append('module.exports = { ' + ', '.join(CLASSES) + ' };')
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, 'w').write('\n'.join(out) + '\n')
    print('wrote', os.path.relpath(OUT, ROOT))


if __name__ == '__main__':
    main()
