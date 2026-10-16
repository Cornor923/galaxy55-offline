"""
Convierte una construccion de un mundo de Minecraft (Anvil 1.16+) en un mundo de bloques de Galaxy 55 para la nave nodriza.
Uso: python -I port/tools/mc2g55.py <carpeta del mundo> <salida .bin>

Salida: 'G55M', ancho, largo, alto (uint16 LE), aparicion x, y, z (uint16 LE) y despues los indices de bloque (uint8, BlockKind
de src/G55/com/Common.hx) en orden z, y, x, todo comprimido con zlib. Los ejes: x de Minecraft -> x, z de Minecraft -> y (invertido
para no reflejar la nave), altura -> z.
"""
import sys, os, re, zlib, struct, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mcread

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')

def kinds():
    s = open(os.path.join(ROOT, 'src/G55/com/Common.hx'), encoding='utf-8').read()
    m = re.search(r'enum BlockKind \{(.*?)\n\}', s, re.S).group(1)
    names = [l.strip().rstrip(';') for l in m.split('\n') if l.strip() and not l.strip().startswith('//')]
    return {n: i for i, n in enumerate(names)}

# tabla: (fragmento del nombre de Minecraft, bloque de Galaxy 55); la primera que coincide gana. None = se ignora (detalles).
RULES = [
    # detalles que no tienen equivalente (se quitan)
    ('trapdoor', None), ('button', None), ('pressure_plate', None), ('redstone_wire', None), ('lever', None),
    ('repeater', None), ('comparator', None), ('banner', None), ('_bed', None), ('ladder', None), ('sign', None),
    ('torch', None), ('rail', None), ('carpet', None), ('piston_head', None), ('piston', 'BMotherPanel'), ('command_block', None), ('dispenser', None),
    ('hopper', None), ('tripwire', None), ('note_block', None), ('player_head', None), ('barrier', None),
    ('daylight', None), ('sea_pickle', None), ('seagrass', None), ('grass', None) if False else ('tall_grass', None),
    ('vine', None), ('anvil', None), ('grindstone', None), ('_door', None), ('fence_gate', None), ('lectern', None),
    ('campfire', None), ('chain', None), ('snow', None), ('slime', None), ('flower', None),
    # luces
    ('sea_lantern', 'BShedWallLight'), ('glowstone', 'BLamp'), ('redstone_lamp', 'BLamp'), ('lantern', 'BLamp'),
    ('end_rod', 'BLamp'), ('shroomlight', 'BLamp'),
    # cristal
    ('tinted_glass', 'BShipGlassBlack'), ('black_stained_glass', 'BShipGlassBlack'), ('glass', 'BShipGlass2'),
    ('iron_bars', 'BIronFence'),
    # metal y piedra de la nave
    ('quartz', 'BShipHull'), ('iron_block', 'BShipHull'), ('white_concrete', 'BShipHull'),
    ('stone_brick', 'BMotherHull'), ('chiseled_stone', 'BMotherHull'),
    ('deepslate_tile', 'BMotherDark'), ('deepslate_brick', 'BMotherDark'), ('deepslate', 'BMotherDark'),
    ('blackstone', 'BMotherDark'), ('basalt', 'BMotherDark'), ('netherite', 'BShipTubes'), ('coal_block', 'BShipTubes'),
    ('gray_concrete', 'BShipWire'), ('gray_wool', 'BShipWire'), ('black_wool', 'BShipTubes'), ('redstone_block', 'BRawRed'),
    ('andesite', 'BMotherPanel'), ('smooth_stone', 'BMotherPanel'), ('cobble', 'BMotherDark'), ('stone', 'BMotherPanel'),
    # colores
    ('yellow_terracotta', 'BAutumnStraw'), ('light_blue_terracotta', 'BBlueCrystalDense'), ('blue_terracotta', 'BMarsBlueRock'),
    # naturaleza (jardines)
    ('water', 'BWater'), ('grass_block', 'BSoilCover'), ('rooted_dirt', 'BSoil'), ('dirt', 'BSoil'), ('sand', 'BMoonSand'),
    ('leaves', 'BGreenLeaves'), ('_log', 'BWood'), ('planks', 'BWoodPlank'), ('_slab', 'BWoodPlank'), ('_stairs', 'BWoodPlank'),
    ('barrel', 'BWoodPlank'), ('crafting_table', 'BWoodPlank'), ('furnace', 'BShipComputer'), ('smoker', 'BShipComputer'),
    ('chest', 'BChest'),
]

FACING = {'north': (0, 0, -1), 'south': (0, 0, 1), 'east': (1, 0, 0), 'west': (-1, 0, 0), 'up': (0, 1, 0), 'down': (0, -1, 0)}

def open_piston_doors(blocks):
    """El mundo se guardo con las puertas de piston cerradas (piston pegajoso extendido empujando un cristal). Se abren como al
    retraerse en Minecraft: el bloque empujado vuelve al sitio de la cabeza y su casilla queda libre."""
    at = {(b[0], b[1], b[2]): i for i, b in enumerate(blocks)}
    gone = set(); moved = {}
    for b in blocks:
        if b[3] != 'piston_head': continue
        d = FACING.get(b[4].get('facing'))
        if d is None: continue
        head = (b[0], b[1], b[2])
        front = (b[0] + d[0], b[1] + d[1], b[2] + d[2])
        gone.add(at[head])
        if b[4].get('type') == 'sticky' and front in at:
            j = at[front]
            gone.add(j)
            moved[head] = blocks[j]
    out = [b for i, b in enumerate(blocks) if i not in gone]
    for (x, y, z), b in moved.items():
        out.append((x, y, z, b[3], b[4]))
    print('puertas de piston abiertas:', len(moved))
    return out

def special(n, pr):
    """Bloques que dependen de sus propiedades. Devuelve el bloque de Galaxy 55, '' para quitarlo o None para usar RULES."""
    if n.endswith('trapdoor'):
        # rejillas de suelo y techo: cerradas arriba ocupan la parte alta (el suelo queda a la misma altura), abajo como placa
        if pr.get('open') == 'true': return ''
        return 'BMotherPanel' if pr.get('half') == 'top' else 'BShipPlate'
    if n.endswith('_door'):
        # puertas de la nave del original (bloque de 1 de alto que se abre al usarlo, BFToggle): una por cada mitad de la de Minecraft
        f = pr.get('facing')
        return 'BShipDoorY' if f in ('north', 'south') else 'BShipDoor'
    return None

def main(world, out):
    K = kinds()
    blocks = open_piston_doors(mcread.blocks(world, True))
    xs = [b[0] for b in blocks]; zs = [b[2] for b in blocks]; ys = [b[1] for b in blocks]
    x0, x1, z0, z1, y0, y1 = min(xs), max(xs), min(zs), max(zs), min(ys), max(ys)
    W, L, H = x1 - x0 + 1, z1 - z0 + 1, y1 - y0 + 1
    grid = bytearray(W * L * H)
    miss = collections.Counter()
    cache = {}
    for (x, y, z, n, pr) in blocks:
        sp = special(n, pr)
        if sp is not None:
            if sp:
                grid[(x - x0) + (z1 - z) * W + (y - y0) * W * L] = K[sp]
            continue
        if n not in cache:
            g = 'skip'
            for frag, tgt in RULES:
                if frag in n:
                    g = tgt
                    break
            cache[n] = g
        g = cache[n]
        if g == 'skip':
            miss[n] += 1
            continue
        if g is None: continue
        gx, gy, gz = x - x0, (z1 - z), y - y0
        grid[gx + gy * W + gz * W * L] = K[g]
    # aparicion: donde estaba el jugador
    sx, sy, sz = W // 2, L // 2, H
    pd = os.path.join(world, 'playerdata')
    for fn in os.listdir(pd):
        if fn.endswith('.dat'):
            import gzip
            p = mcread.nbt(gzip.decompress(open(os.path.join(pd, fn), 'rb').read()))['Pos']
            sx, sy, sz = int(p[0]) - x0, z1 - int(p[2]), int(p[1]) - y0
            break
    sx, sy, sz = [max(0, min(v, m - 1)) for v, m in ((sx, W), (sy, L), (sz, H))]
    head = b'G55M' + struct.pack('<6H', W, L, H, sx, sy, sz)
    open(out, 'wb').write(head + zlib.compress(bytes(grid), 9))
    print('medidas', W, L, H, 'aparicion', sx, sy, sz, 'bloques', sum(1 for v in grid if v))
    print('sin traducir:', miss.most_common(30))

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
