import zlib, struct, sys
d = open(sys.argv[1], 'rb').read()
body = zlib.decompress(d[8:]) if d[:3] == b'CWS' else d[8:]
nb = body[0] >> 3; pos = (5 + nb * 4 + 7) // 8 + 4
abcs = []
while pos < len(body):
    h = struct.unpack('<H', body[pos:pos+2])[0]; t = h >> 6; l = h & 63; pos += 2
    if l == 63: l = struct.unpack('<I', body[pos:pos+4])[0]; pos += 4
    if t in (72, 82):
        data = body[pos:pos+l]
        if t == 82:
            e = data.index(b'\0', 4); data = data[e+1:]
        else:
            pass
        abcs.append(data if t == 72 else data)
    pos += l
def parse(b):
    p = [0]
    def u30():
        r = 0; s = 0
        while True:
            x = b[p[0]]; p[0] += 1
            r |= (x & 0x7f) << s; s += 7
            if not x & 0x80: return r
    p[0] = 4
    for _ in range(max(u30()-1, 0)): u30()
    for _ in range(max(u30()-1, 0)): u30()
    for _ in range(max(u30()-1, 0)): p[0] += 8
    strs = [""]
    for _ in range(max(u30()-1, 0)):
        n = u30(); strs.append(b[p[0]:p[0]+n].decode('utf8', 'replace')); p[0] += n
    nss = [0]
    for _ in range(max(u30()-1, 0)):
        k = b[p[0]]; p[0] += 1; nss.append(strs[u30()])
    for _ in range(max(u30()-1, 0)):
        for _ in range(u30()): u30()
    mn = [None]
    for _ in range(max(u30()-1, 0)):
        k = b[p[0]]; p[0] += 1
        if k in (7, 13): ns = u30(); nm = u30(); mn.append((nss[ns], strs[nm]))
        elif k in (0xf, 0x10): nm = u30(); mn.append(("", strs[nm]))
        elif k in (0x11, 0x12): mn.append(None)
        elif k in (9, 0xe): nm = u30(); u30(); mn.append(("", strs[nm]))
        elif k == 0x1b: u30(); mn.append(None)
        elif k == 0x1d:
            u30()
            for _ in range(u30()): u30()
            mn.append(None)
        else: mn.append(None)
    for _ in range(u30()):  # methods
        pc = u30(); u30()
        for _ in range(pc): u30()
        u30(); fl = b[p[0]]; p[0] += 1
        if fl & 8:
            for _ in range(u30()):
                u30(); p[0] += 1
        if fl & 0x80:
            for _ in range(pc): u30()
    for _ in range(u30()):  # metadata
        u30()
        n = u30()
        for _ in range(n): u30()
        for _ in range(n): u30()
    cc = u30(); names = []
    for _ in range(cc):
        nm = u30(); sup = u30(); fl = b[p[0]]; p[0] += 1
        if fl & 8: u30()
        for _ in range(u30()): u30()
        u30()
        for _ in range(u30()):
            u30(); k = b[p[0]]; p[0] += 1; kind = k & 0xf
            if kind in (0, 6): u30(); u30(); vi = u30(); 
            if kind in (0, 6) and vi: p[0] += 1
            elif kind in (1, 2, 3): u30(); u30()
            elif kind in (4, 5): u30(); u30()
            if k & 0x40:
                for _ in range(u30()): u30()
        names.append(mn[nm])
    return names
for a in abcs:
    try:
        ns = parse(a)
        print(len(ns), "clases:")
        for n in sorted(x for x in ns if x): print("  " + (n[0] + "." if n[0] else "") + n[1])
    except Exception as e:
        print("error parseando ABC:", e)
