#!/usr/bin/env python3
import re, glob

G = '/home/claude/build/G55'
L = '/home/claude/WebGamesArchives'


def rd(p): return open(p, encoding='utf8', errors='surrogateescape').read()
def wr(p, s): open(p, 'w', encoding='utf8', errors='surrogateescape').write(s)
def rw(p, fn):
    s = rd(p); n = fn(s)
    if n != s: wr(p, n); return True
    return False


def split_args(s):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([{": depth += 1
        elif ch in ")]}": depth -= 1
        if ch == "," and depth == 0: out.append(cur); cur = ""
        else: cur += ch
    out.append(cur); return out


def fix_calls(src, name, nargs_list, fn):
    """Find `name(`...`)` calls, split args, call fn(args)->args."""
    out, i, n = "", 0, 0
    pat = re.compile(r'\b' + re.escape(name) + r'\(')
    while True:
        m = pat.search(src, i)
        if not m: out += src[i:]; break
        j, depth = m.end(), 1
        while depth:
            c = src[j]
            if c in "([{": depth += 1
            elif c in ")]}": depth -= 1
            j += 1
        inner = src[m.end():j-1]
        args = split_args(inner)
        if len(args) in nargs_list:
            new = fn(args)
            if new is not None:
                out += src[i:m.end()] + ",".join(new) + ")"; i = j; n += 1; continue
        out += src[i:m.end()]; i = m.end()
    return out, n


total = {}
# --- explore/client: lineStyle skip of pixelHinting, perlinNoise skip channelOptions, gradient colors
for f in glob.glob(G + '/fla/**/*.hx', recursive=True):
    s = rd(f); o = s
    s = re.sub(r'(lineStyle\([^()]*?,[^()]*?,[^()]*?),(\s*)(flash\.display\.LineScaleMode)', r'\1,\2false,\2\3', s)
    def perlin(args):
        if len(args) in (7, 8) and args[6].strip() in ('true', 'false'):
            return args[:6] + [' 7'] + args[6:]
    s, n = fix_calls(s, 'perlinNoise', (7, 8), perlin)
    total['perlinNoise'] = total.get('perlinNoise', 0) + n
    s = re.sub(r'(beginGradientFill\(\s*flash\.display\.GradientType\.\w+,\s*)colors,', r'\1cast colors,', s)
    if s != o: wr(f, s)

# --- Generator.gen(density, function)  ->  gen(density, 100, function)
for f in glob.glob(G + '/fla/client/src/gen/*.hx'):
    rw(f, lambda s: re.sub(r'\bgen\(([\d.]+),\s*function\(\)', r'gen(\1, 100, function()', s))

# --- Game.hx
rw(G + '/fla/client/src/Game.hx', lambda s: s.replace('flags.init();', 'flags = new haxe.EnumFlags<UserFlags>();')
   .replace('mt.gx.ListEx.snd(', 'mt.gx.ListEx.removeAll('))
# --- EditShip.hx switch with computed cases -> guards
rw(G + '/fla/client/src/EditShip.hx', lambda s: re.sub(r'case Type\.enumIndex\((\w+)\):', r'case _ if( b == Type.enumIndex(\1) ):', s))
# --- Macro.hx
rw(G + '/com/Macro.hx', lambda s: s.replace('readUInt30()', 'readInt32()'))
# --- libs
rw(L + '/libs-haxe2/mt/gx/math/Vec2.hx', lambda s: s.replace('Std.format("Vec2($x,$y)")', "'Vec2($x,$y)'"))
rw(L + '/libs-haxe2/mt/gx/LambdaEx.hx', lambda s: s.replace('Lambda.has(infer, x , eqFunc)', 'Lambda.exists(infer, function(y) return eqFunc(x, y))'))
rw(L + '/libs-haxe3/mt/Timer.hx', lambda s: s if 'function restore' in s else s.replace('public inline static function resume() {', 'public inline static function restore() { resume(); }\n\n\tpublic inline static function resume() {'))
rw(L + '/libs-haxe2/mt/deepnight/Color.hx', lambda s: s if 'function addAlphaChannel' in s else s.replace('public static inline function getChannelMask(', 'public static inline function addAlphaChannel(rgb:Int, a:Int) : Int { return (a << 24) | (rgb & 0xFFFFFF); }\n\n\tpublic static inline function getChannelMask(', 1))
rw('/home/claude/build/stubs/tora/Protocol.hx', lambda s: s if 'close' in s else s.replace('public function new() {}', 'public function new() {}\n\tpublic function close() {}'))


# --- properties with custom accessor names -> get/set + get_x / set_x
def fix_props(path):
    s = rd(path); o = s
    for m in list(re.finditer(r'var\s+(\w+)\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)', s)):
        name, g, st = m.groups()
        newg, news = g, st
        if g not in ('default', 'null', 'never', 'dynamic', 'get'): newg = 'get'
        if st not in ('default', 'null', 'never', 'dynamic', 'set'): news = 'set'
        if (newg, news) == (g, st): continue
        s = s.replace(m.group(0), m.group(0).replace('(%s,' % g, '(%s,' % newg, 1) if False else
                      'var %s(%s, %s)' % (name, newg, news))
        if newg == 'get':
            s = re.sub(r'\b' + re.escape(g) + r'\b(?=\s*\()', 'get_' + name, s)
        if news == 'set':
            s = re.sub(r'\b' + re.escape(st) + r'\b(?=\s*\()', 'set_' + name, s)
    if s != o: wr(path, s); return True


for p in (G + '/fla/client/src/fx/Load.hx', G + '/fla/client/src/ent/Hero.hx', L + '/libs-haxe2/mt/deepnight/Buffer.hx'):
    print('props', p.split('/')[-1], fix_props(p))
print(total)
