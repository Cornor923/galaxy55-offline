"""Lector minimo de mundos de Minecraft (Anvil, 1.16+ / 1.18+): devuelve los bloques no-aire como (x, y, z, nombre)."""
import struct, zlib, gzip, os, sys, io, collections, pickle

def nbt(buf):
    f = io.BytesIO(buf)
    def rd(n): return f.read(n)
    def payload(t):
        if t == 1: return struct.unpack('>b', rd(1))[0]
        if t == 2: return struct.unpack('>h', rd(2))[0]
        if t == 3: return struct.unpack('>i', rd(4))[0]
        if t == 4: return struct.unpack('>q', rd(8))[0]
        if t == 5: return struct.unpack('>f', rd(4))[0]
        if t == 6: return struct.unpack('>d', rd(8))[0]
        if t == 7:
            n = struct.unpack('>i', rd(4))[0]; return rd(n)
        if t == 8:
            n = struct.unpack('>H', rd(2))[0]; return rd(n).decode('utf-8', 'replace')
        if t == 9:
            et = rd(1)[0]; n = struct.unpack('>i', rd(4))[0]
            return [payload(et) for _ in range(n)]
        if t == 10:
            d = {}
            while True:
                tt = rd(1)[0]
                if tt == 0: return d
                nl = struct.unpack('>H', rd(2))[0]; name = rd(nl).decode('utf-8', 'replace')
                d[name] = payload(tt)
        if t == 11:
            n = struct.unpack('>i', rd(4))[0]; return list(struct.unpack('>%di' % n, rd(4 * n)))
        if t == 12:
            n = struct.unpack('>i', rd(4))[0]; return list(struct.unpack('>%dq' % n, rd(8 * n)))
        raise Exception('tag %d' % t)
    t = rd(1)[0]
    nl = struct.unpack('>H', rd(2))[0]; rd(nl)
    return payload(t)

def chunks(path):
    data = open(path, 'rb').read()
    if len(data) < 8192: return
    for i in range(1024):
        off = int.from_bytes(data[i*4:i*4+3], 'big'); cnt = data[i*4+3]
        if off == 0: continue
        p = off * 4096
        ln = struct.unpack('>i', data[p:p+4])[0]; comp = data[p+4]
        raw = data[p+5:p+4+ln]
        raw = zlib.decompress(raw) if comp == 2 else gzip.decompress(raw)
        yield nbt(raw)

def blocks(world):
    out = []
    reg = os.path.join(world, 'region')
    for fn in os.listdir(reg):
        if not fn.endswith('.mca'): continue
        for c in chunks(os.path.join(reg, fn)):
            lvl = c.get('Level', c)
            cx, cz = lvl['xPos'], lvl['zPos']
            secs = lvl.get('sections', lvl.get('Sections', []))
            for s in secs:
                sy = s['Y']
                if 'block_states' in s:
                    pal = s['block_states'].get('palette', []); dat = s['block_states'].get('data')
                else:
                    pal = s.get('Palette', []); dat = s.get('BlockStates')
                if not pal: continue
                names = [p['Name'] for p in pal]
                if dat is None:
                    if names[0].endswith(':air'): continue
                    idx = [0] * 4096
                else:
                    bits = max(4, (len(names) - 1).bit_length())
                    per = 64 // bits; mask = (1 << bits) - 1
                    idx = []
                    for v in dat:
                        v &= (1 << 64) - 1
                        for k in range(per):
                            idx.append((v >> (k * bits)) & mask)
                            if len(idx) == 4096: break
                        if len(idx) == 4096: break
                for i, pi in enumerate(idx):
                    n = names[pi] if pi < len(names) else 'minecraft:air'
                    if n.endswith(':air') or n.endswith('cave_air') or n.endswith('void_air'): continue
                    y = i >> 8; z = (i >> 4) & 15; x = i & 15
                    out.append((cx * 16 + x, sy * 16 + y, cz * 16 + z, n.split(':')[1]))
    return out

if __name__ == '__main__':
    b = blocks(sys.argv[1])
    pickle.dump(b, open(sys.argv[2], 'wb'))
    cnt = collections.Counter(n for _, _, _, n in b)
    print('bloques', len(b))
    for n, k in cnt.most_common(80): print(k, n)
    ys = collections.Counter(y for _, y, _, _ in b)
    print('por altura', sorted(ys.items())[:12], '...', sorted(ys.items())[-6:])
