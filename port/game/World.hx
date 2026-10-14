import Common;

/** Geometria acumulada de un chunk para un material. */
class MeshBuf {
	public var pts = new Array<h3d.col.Point>();
	public var uvs = new Array<h3d.prim.UV>();
	public var cols = new Array<h3d.col.Point>();
	public var idx = new hxd.IndexBuffer();
	public function new() {}
}

/**
	Un planeta: lo genera con los generadores originales y construye su geometria.
	Se carga por tandas (step) para poder mostrar una barra de progreso sin congelar la ventana.
**/
class World {

	public static inline var CSIZE = 16;
	public static inline var ZBITS = 7;
	public static inline var HEIGHT = 128;
	static inline var TE = 0.999;

	public var seed(default, null) : Int;
	public var biomeName(default, null) : String;
	public var size(default, null) : Int;
	public var faces(default, null) = 0;
	public var failed(default, null) = false;
	public var progress(default, null) = 0.;
	public var root(default, null) : h3d.scene.Object;
	public var sky(default, null) : Sky;
	var gen : gen.DetailsGenerator;
	var bytes : haxe.io.Bytes;
	var atlas : h3d.mat.Texture;
	var phase = 0;
	var chunk = 0;
	var meshes = new Array<h3d.scene.Mesh>();
	static inline var VIEW_RADIUS = 180.;
	var meshExtra = new Array<Array<h3d.scene.Mesh>>();
	var meshCx = new Array<Float>();
	var meshCy = new Array<Float>();
	var curCx = 0.;
	var curCy = 0.;
	var wrapX = -1e9;
	var wrapY = -1e9;
	var genStarted : Float;

	// luz (Builder.relight del original): 0..15 por celda; LBASE = 10 equivale a luz plena
	public static inline var LBASE = 10;
	static inline var NOLIGHT = 8; // enumIndex(BTReduced): a partir de aqui el bloque no deja pasar la luz
	var light : haxe.io.Bytes;
	var idTag : Array<Int>;
	var sunP : Float;
	var sunF : Float;

	public function new( seed : Int, biomeName : String, sizeChunks : Int, parent : h3d.scene.Object, atlas : h3d.mat.Texture, menuFog = false ) {
		this.seed = seed;
		this.biomeName = biomeName;
		this.atlas = atlas;
		size = sizeChunks << Const.BITS;
		root = new h3d.scene.Object(parent);
		var biome : BiomeKind = Type.createEnum(BiomeKind, biomeName);
		sky = new Sky(root, biome, menuFog);
		sky.fog.curve = 2.0 / size; // curvatura del planeta, igual que AbstractGame: curve = 2 / totalSize
		gen = new gen.DetailsGenerator(size, seed);
		var bd = Data.getBiome(biome);
		sunP = bd.sunPower;
		sunF = bd.sunFalloff == null ? 1 : bd.sunFalloff;
		gen.alloc(bd.water);
		gen.alloc(BMinIron);
		gen.alloc(BMinAluminium);
		for( s in bd.soils ) gen.alloc(s);
		gen.startGenerate(biome);
		// como Builder.init: los modelos sin BFSize usan su propia caja para las colisiones
		for( b in Block.all )
			if( b.model != null && b.size == null ) b.size = Models.get(b.model).box;
		genStarted = haxe.Timer.stamp();
	}

	public inline function isReady() return phase >= 2;

	/** Avanza la carga durante budgetMs milisegundos; devuelve el progreso de 0 a 1. */
	public function step( budgetMs : Float ) : Float {
		var t0 = haxe.Timer.stamp();
		if( phase == 0 ) {
			if( !gen.process(Std.int(budgetMs)) ) {
				bytes = gen.getBytes().b;
				computeLight();
				phase = 1;
			}
			return progress = (phase == 0 ? gen.progress * 0.75 : 0.75);
		}
		if( phase == 1 ) {
			var n = size >> 4;
			while( chunk < n * n ) {
				buildChunk(chunk % n, Std.int(chunk / n));
				chunk++;
				if( (haxe.Timer.stamp() - t0) * 1000 >= budgetMs ) break;
			}
			if( chunk >= n * n ) phase = 2;
			return progress = 0.75 + 0.25 * chunk / (n * n);
		}
		return progress = 1;
	}

	public function dispose() {
		sky.dispose();		for( m in meshes ) {
			m.remove();
			m.primitive.dispose();
		}
		for( ex in meshExtra )
			if( ex != null )
				for( c in ex ) if( c != null ) c.remove();
		meshExtra = [];
		meshes = [];
		meshCx = [];
		meshCy = [];
		root.remove();
	}

	// ---------------------------------------------------------------- consulta de bloques

	public inline function voxel( x : Int, y : Int, z : Int ) : Int {
		if( x < 0 ) x += size else if( x >= size ) x -= size;
		if( y < 0 ) y += size else if( y >= size ) y -= size;
		if( z < 0 ) return 1;
		if( z >= HEIGHT ) return 0;
		return bytes.get(((x + y * size) << ZBITS) | z);
	}

	/** true si la cara contra este voxel se ve (aire o bloque que deja pasar la luz) */
	inline function open( x : Int, y : Int, z : Int ) : Bool {
		var id = voxel(x, y, z);
		return id == 0 || tagOf(id) != BTFull;
	}

	/** como Builder.hx del original: los bloques con alfa (hielo, cristal) dejan ver las caras de lo que hay detras */
	inline function openAlpha( x : Int, y : Int, z : Int ) : Bool {
		var id = voxel(x, y, z);
		if( id == 0 ) return true;
		var t = tagOf(id);
		return t != BTFull && t != BTAlpha;
	}

	/** tipo de bloque a efectos de mallado (las hojas sin BFNoOptimize cuentan como bloque lleno, igual que el original) */
	function tagOf( id : Int ) : BlockType {
		var b = gen.blocks[id];
		if( b.type == BTTransp && !b.hasFlag(BFNoOptimize) ) return BTFull;
		return b.type;
	}

	/** bloque con el que se choca: usa el atributo collide del original (hojas si, agua y detalles no) */
	public inline function solid( x : Int, y : Int, z : Int ) : Bool {
		var id = voxel(x, y, z);
		if( id == 0 ) return false;
		var b = gen.blocks[id];
		return b != null && b.collide;
	}

	/** suelo opaco (para elegir el punto de aparicion) */
	public inline function opaque( x : Int, y : Int, z : Int ) : Bool {
		var id = voxel(x, y, z);
		return id != 0 && !gen.btrans[id];
	}

	/** bloque en una celda (null si es aire) */
	public function block( x : Int, y : Int, z : Int ) : Block {
		var id = voxel(x, y, z);
		return id <= 0 ? null : gen.blocks[id];
	}

	/** Igual que Level.collide del original: consulta de un punto, con la caja de los bloques parciales. */
	public function collidePoint( x : Float, y : Float, z : Float ) : Bool {
		var ix = Math.floor(x), iy = Math.floor(y), iz = Std.int(z);
		if( z < 0 || iz >= HEIGHT ) return false;
		var id = voxel(ix, iy, iz);
		if( id == 0 ) return false;
		var b = gen.blocks[id];
		if( b == null || !b.collide ) return false;
		if( b.size == null ) return true;
		var fz = z - iz;
		return fz >= b.size.z1 && fz < b.size.z2;
	}

	/** altura de la superficie mas alta con colision (incluye copas de arboles) */
	public function topCollide( x : Int, y : Int ) : Int {
		var z = HEIGHT - 1;
		while( z > 1 && !solid(x, y, z) ) z--;
		return z + 1;
	}

	/** celdas libres de colision a partir de z (cabe el jugador: 3 bloques de alto) */
	function free( x : Int, y : Int, z : Int ) : Bool {
		for( k in 0...3 ) {
			var id = voxel(x, y, z + k);
			if( id != 0 && gen.blocks[id].collide ) return false;
		}
		return true;
	}

	public function spawnPoint(): { x : Float, y : Float, z : Float } {
		// busca en espiral desde el centro una columna cuyo punto mas alto sea suelo firme (no hojas ni modelos)
		var cx = size >> 1, cy = size >> 1;
		for( r in 0...40 )
			for( dy in -r...r + 1 )
				for( dx in -r...r + 1 ) {
					if( Math.abs(dx) != r && Math.abs(dy) != r ) continue;
					var x = cx + dx, y = cy + dy;
					var top = topCollide(x, y) - 1;
					var b = block(x, y, top);
					if( b != null && b.type == BTFull && !b.hasFlag(BFIsLava) && free(x, y, top + 1) )
						return { x : x + 0.5, y : y + 0.5, z : top + 1.01 };
				}
		var x = cx, y = cy;
		var z = HEIGHT - 1;
		while( z > 1 && !opaque(x, y, z) ) z--;
		return { x : x + 0.5, y : y + 0.5, z : z + 1.01 };
	}

	// ---------------------------------------------------------------- luz

	/** diagnostico: recuento de celdas por bloque y tipo (solo para pruebas) */
	public function debugStats() : String {
		var counts = new Map<Int, Int>();
		for( i in 0...bytes.length ) {
			var id = bytes.get(i);
			if( id != 0 ) counts.set(id, (counts.exists(id) ? counts.get(id) : 0) + 1);
		}
		var s = "";
		for( id in counts.keys() ) {
			var b = gen.blocks[id];
			s += id + ":" + (b == null ? "null" : Std.string(b.k) + "/" + Std.string(b.type)) + "=" + counts.get(id) + " ";
		}
		return s;
	}

	/** luz de una celda (el mundo da la vuelta; por encima del techo es luz de sol plena) */
	public function lightAt( x : Int, y : Int, z : Int ) : Int {
		if( z < 0 ) return 0;
		if( z >= HEIGHT ) return Std.int(sunP);
		if( x < 0 ) x += size else if( x >= size ) x -= size;
		if( y < 0 ) y += size else if( y >= size ) y -= size;
		return light.get(((x + y * size) << ZBITS) | z);
	}

	/**
	 * Copia de Builder.relight/processLight para todo el planeta: la luz de sol llena el aire hasta el primer bloque,
	 * se cuela de lado bajo los voladizos y se propaga por las cuevas con la caida de cada bioma;
	 * despues cada bloque luminoso (BFLight) ilumina su entorno.
	 */
	function computeLight() {
		var n = size * size * HEIGHT;
		light = haxe.io.Bytes.alloc(n);
		idTag = [for( b in gen.blocks ) b == null ? 0 : Type.enumIndex(b.type)];
		var lmax = Std.int(sunP);
		var lsun = Std.int(sunP - sunF);
		if( lsun < 0 ) lsun = 0;
		var seeds = new Array<Int>();
		var top = HEIGHT - 1;
		for( y in 0...size )
			for( x in 0...size ) {
				var col = x + y * size;
				var base = col << ZBITS;
				var cxm = x == 0 ? col + size - 1 : col - 1;
				var cym = y == 0 ? col + size * (size - 1) : col - size;
				var z = top;
				while( z >= 0 ) {
					var p = base | z;
					var t = idTag[bytes.get(p)];
					if( t != 0 ) {
						if( t < NOLIGHT ) {
							light.set(p, lsun);
							seeds.push(p);
						}
						break;
					}
					light.set(p, lmax);
					// la luz se cuela hacia los vecinos -x e -y que aun no la tienen
					var q = (cxm << ZBITS) | z;
					if( light.get(q) == 0 && idTag[bytes.get(q)] < NOLIGHT ) {
						light.set(q, lsun);
						seeds.push(q);
					}
					q = (cym << ZBITS) | z;
					if( light.get(q) == 0 && idTag[bytes.get(q)] < NOLIGHT ) {
						light.set(q, lsun);
						seeds.push(q);
					}
					z--;
				}
				// bajo el primer bloque: aire/bloques con luz directa a su lado
				while( z > 0 ) {
					var p = base | z;
					if( idTag[bytes.get(p)] < NOLIGHT && (isSunAir((cxm << ZBITS) | z, lmax) || isSunAir((cym << ZBITS) | z, lmax)) ) {
						light.set(p, lsun);
						seeds.push(p);
					}
					z--;
				}
			}
		flood(seeds, sunP - sunF * 2, sunF);

		// bloques luminosos
		var infos = new Array<{ p : Int, f : Float }>();
		var lightIdx = [for( b in gen.blocks ) -1];
		for( i in 0...gen.blocks.length ) {
			var b = gen.blocks[i];
			if( b == null || b.special == null ) continue;
			switch( b.special ) {
			case BFLight(p, f):
				var ip = Std.int(p);
				if( ip > 15 ) ip = 15;
				lightIdx[i] = infos.length;
				infos.push({ p : ip, f : f == null ? 1.0 : f });
			default:
			}
		}
		if( infos.length > 0 ) {
			var powers = [for( b in gen.blocks ) 0.];
			for( i in 0...gen.blocks.length ) {
				var b = gen.blocks[i];
				if( b == null || b.special == null ) continue;
				switch( b.special ) {
				case BFLight(p, _): powers[i] = p;
				default:
				}
			}
			for( p in 0...n ) {
				var id = bytes.get(p);
				var li = lightIdx[id];
				if( li < 0 ) continue;
				var info = infos[li];
				if( light.get(p) >= info.p ) continue;
				light.set(p, info.p);
				flood([p], powers[id] - info.f, info.f);
			}
		}
	}

	inline function isSunAir( p : Int, lmax : Int ) : Bool {
		return light.get(p) == lmax && idTag[bytes.get(p)] == 0;
	}

	/** onda expansiva: cada anillo baja la luz en delta (Builder.processLight) */
	function flood( seeds : Array<Int>, lvalue : Float, delta : Float ) {
		var cur = seeds;
		var sz = size;
		while( true ) {
			var l = Std.int(lvalue);
			if( l > 15 ) l = 15;
			if( l <= 0 || cur.length == 0 ) break;
			var next = new Array<Int>();
			for( p in cur ) {
				var z = p & (HEIGHT - 1);
				var col = p >> ZBITS;
				var x = col % sz;
				var y = Std.int(col / sz);
				var c = x == 0 ? col + sz - 1 : col - 1;
				spread((c << ZBITS) | z, l, next);
				c = x == sz - 1 ? col - (sz - 1) : col + 1;
				spread((c << ZBITS) | z, l, next);
				c = y == 0 ? col + sz * (sz - 1) : col - sz;
				spread((c << ZBITS) | z, l, next);
				c = y == sz - 1 ? col - sz * (sz - 1) : col + sz;
				spread((c << ZBITS) | z, l, next);
				if( z > 0 ) spread(p - 1, l, next);
				if( z < HEIGHT - 1 ) spread(p + 1, l, next);
			}
			cur = next;
			lvalue -= delta;
		}
	}

	inline function spread( q : Int, l : Int, next : Array<Int> ) {
		if( light.get(q) < l && idTag[bytes.get(q)] < NOLIGHT ) {
			light.set(q, l);
			next.push(q);
		}
	}

	// ---------------------------------------------------------------- mallado

	var shv = [0., 0., 0., 0.];

	function addQuad( m : MeshBuf, p : Array<Float>, tile : Int, shade : Float ) {
		shv[0] = shv[1] = shv[2] = shv[3] = shade;
		addQuad4(m, p, tile);
	}

	/**
	 * Cara con la luz del original (Builder.addQuad): cada vertice promedia la luz de las 4 celdas que lo rodean
	 * en el plano exterior de la cara, multiplicada por la sombra de la cara. Con BFNoShade (neg) no depende de la luz.
	 * (cx,cy,cz) es la celda del bloque y (ox,oy,oz) la normal de la cara; uniform usa solo la celda exterior.
	 */
	function addQuadL( m : MeshBuf, p : Array<Float>, tile : Int, shade : Float, neg : Bool, ox : Int, oy : Int, oz : Int, cx : Int, cy : Int, cz : Int, uniform = false ) {
		if( tile < 0 || tile >= 0xFFF ) return;
		if( neg ) {
			shv[0] = shv[1] = shv[2] = shv[3] = shade;
		} else if( uniform ) {
			var l = lightAt(cx + ox, cy + oy, cz + oz) * shade / LBASE;
			shv[0] = shv[1] = shv[2] = shv[3] = l;
		} else {
			var nx = cx + ox, ny = cy + oy, nz = cz + oz;
			for( k in 0...4 ) {
				var vx = Std.int(p[k * 3]), vy = Std.int(p[k * 3 + 1]), vz = Std.int(p[k * 3 + 2]);
				var s = 0;
				for( a in 0...2 )
					for( b in 0...2 ) {
						if( ox != 0 ) s += lightAt(nx, vy - a, vz - b);
						else if( oy != 0 ) s += lightAt(vx - a, ny, vz - b);
						else s += lightAt(vx - a, vy - b, nz);
					}
				shv[k] = s * shade * (0.25 / LBASE);
			}
		}
		addQuad4(m, p, tile);
	}

	function addQuad4( m : MeshBuf, p : Array<Float>, tile : Int ) {
		if( tile < 0 || tile >= 0xFFF ) return;
		var tx = tile & 63, ty = tile >> 6;
		var u0 = tx / 64 + (1 - TE) / 128, v0 = ty / 64 + (1 - TE) / 128;
		var u1 = u0 + TE / 64, v1 = v0 + TE / 64;
		var b = m.pts.length;
		m.pts.push(new h3d.col.Point(p[0], p[1], p[2]));
		m.pts.push(new h3d.col.Point(p[3], p[4], p[5]));
		m.pts.push(new h3d.col.Point(p[6], p[7], p[8]));
		m.pts.push(new h3d.col.Point(p[9], p[10], p[11]));
		m.uvs.push(new h3d.prim.UV(u0, v1));
		m.uvs.push(new h3d.prim.UV(u1, v1));
		m.uvs.push(new h3d.prim.UV(u1, v0));
		m.uvs.push(new h3d.prim.UV(u0, v0));
		for( i in 0...4 ) m.cols.push(new h3d.col.Point(shv[i], shv[i], shv[i]));
		// la diagonal se elige segun la luz para evitar costuras raras
		if( shv[0] + shv[2] >= shv[1] + shv[3] ) {
			m.idx.push(b); m.idx.push(b + 1); m.idx.push(b + 2);
			m.idx.push(b); m.idx.push(b + 2); m.idx.push(b + 3);
		} else {
			m.idx.push(b + 1); m.idx.push(b + 2); m.idx.push(b + 3);
			m.idx.push(b + 1); m.idx.push(b + 3); m.idx.push(b);
		}
		faces++;
	}

	/** modelos de Builder.hx (plantas en cruz, planos, columnas, cajas): se copia la geometria del original */
	function addModel( m : MeshBuf, b : Block, x : Int, y : Int, z : Int ) {
		var mk = b.model != null ? b.model : MCross;
		var md = Models.get(mk);
		var v = md.v;
		var n = Std.int(v.length / 24);
		// los modelos usan la luz de su propia celda (Builder: getLight(p) / LBASE)
		var lt = lightAt(x, y, z) / LBASE;
		for( q in 0...n ) {
			var sel = Std.int(v[q * 24 + 3]);
			var tile = !md.multi || sel == 0 ? b.tlr : (sel == 1 ? b.tu : b.td);
			if( tile < 0 || tile >= 0xFFF ) continue;
			var tx = tile & 63, ty = tile >> 6;
			var base = m.pts.length;
			for( k in 0...4 ) {
				var o = q * 24 + k * 6;
				var u = v[o + 3];
				var s = v[o + 5] * lt;
				m.pts.push(new h3d.col.Point(x + v[o], y + v[o + 1], z + v[o + 2]));
				m.uvs.push(new h3d.prim.UV(tx / 64 + (1 - TE) / 128 + (u - Std.int(u)), ty / 64 + (1 - TE) / 128 + v[o + 4]));
				m.cols.push(new h3d.col.Point(s, s, s));
			}
			m.idx.push(base); m.idx.push(base + 1); m.idx.push(base + 2);
			m.idx.push(base + 2); m.idx.push(base + 1); m.idx.push(base + 3);
			faces++;
		}
	}

	function emitMesh( m : MeshBuf, kind : Int ) {
		if( m.pts.length == 0 ) return;
		var poly = new h3d.prim.Polygon(m.pts, m.idx);
		poly.uvs = m.uvs;
		poly.colors = m.cols;
		var mat = h3d.mat.Material.create(atlas);
		mat.shadows = false;
		mat.mainPass.enableLights = false;
		mat.mainPass.culling = None;
		mat.mainPass.addShader(new h3d.shader.VertexColor());
		mat.mainPass.addShader(sky.fog);
		if( kind == 1 ) {
			// bloques con alfa (hojas): se descartan los pixeles transparentes
			mat.textureShader.killAlpha = true;
			mat.textureShader.killAlphaThreshold = 0.5;
		} else if( kind == 3 ) {
			// hielo, cristal, liquidos con alfa: mezcla con el alfa de la propia textura (el original usa AlphaShader)
			mat.blendMode = Alpha;
			mat.mainPass.depthWrite = false;
			mat.mainPass.setPassName("alpha");
		} else if( kind == 2 ) {
			// agua: translucida y sin escribir profundidad
			mat.blendMode = Alpha;
			mat.color.a = 0.6;
			mat.mainPass.depthWrite = false;
			mat.mainPass.setPassName("alpha");
		}
		meshes.push(new h3d.scene.Mesh(poly, mat, root));
		meshCx.push(curCx);
		meshCy.push(curCy);
	}

	/**
	 * El planeta da la vuelta como en el original (AbstractGame.real/realDist): cada chunk se dibuja en la copia
	 * mas cercana a la camara, asi no hay borde del mundo y el horizonte sigue siendo terreno.
	 */
	public function updateWrap( x : Float, y : Float ) {
		if( x == wrapX && y == wrapY ) return;
		wrapX = x;
		wrapY = y;
		var s = size;
		var r = VIEW_RADIUS + CSIZE;
		var r2 = r * r;
		// con el mundo mas pequeno que el alcance de la niebla hacen falta copias vecinas
		var extra = s * 0.5 < VIEW_RADIUS;
		if( extra && meshExtra.length < meshes.length )
			while( meshExtra.length < meshes.length ) meshExtra.push(null);
		for( i in 0...meshes.length ) {
			var m = meshes[i];
			var bx = Math.round((x - meshCx[i]) / s), by = Math.round((y - meshCy[i]) / s);
			m.x = s * bx;
			m.y = s * by;
			if( !extra ) continue;
			var ex = meshExtra[i];
			var k = 0;
			for( oy in -1...2 )
				for( ox in -1...2 ) {
					if( ox == 0 && oy == 0 ) continue;
					var dx = meshCx[i] + s * (bx + ox) - x, dy = meshCy[i] + s * (by + oy) - y;
					var show = dx * dx + dy * dy < r2;
					var c = ex != null ? ex[k] : null;
					if( show && c == null ) {
						if( ex == null ) ex = meshExtra[i] = [for( _ in 0...8 ) null];
						c = ex[k] = new h3d.scene.Mesh(m.primitive, m.material, root);
					}
					if( c != null ) {
						c.visible = show;
						c.x = s * (bx + ox);
						c.y = s * (by + oy);
					}
					k++;
				}
		}
	}

	function buildChunk( cx : Int, cy : Int ) {
		var solidBuf = new MeshBuf();
		var alphaBuf = new MeshBuf();
		var waterBuf = new MeshBuf();
		var blendBuf = new MeshBuf();
		curCx = cx * CSIZE + CSIZE * 0.5;
		curCy = cy * CSIZE + CSIZE * 0.5;

		for( y in cy * CSIZE...(cy + 1) * CSIZE )
			for( x in cx * CSIZE...(cx + 1) * CSIZE )
				for( z in 1...HEIGHT ) {
					var id = voxel(x, y, z);
					if( id == 0 ) continue;
					var b = gen.blocks[id];
					if( b == null ) continue;
					var su = Math.sqrt(b.shadeUp), sd = Math.sqrt(b.shadeDown);
					var sx = Math.sqrt(b.shadeX), sy = Math.sqrt(b.shadeY);
					var fx = x, fy = y, fz = z;
					var neg = b.hasFlag(BFNoShade);
					switch( b.type ) {
					case BTWater:
						// solo la superficie
						if( voxel(x, y, z + 1) == 0 )
							addQuadL(waterBuf, [fx, fy, fz + 0.9, fx + 1, fy, fz + 0.9, fx + 1, fy + 1, fz + 0.9, fx, fy + 1, fz + 0.9], b.tu, su, neg, 0, 0, 1, x, y, z);
					case BTFull, BTAlpha, BTTransp:
						var m = b.type == BTFull ? solidBuf : (b.type == BTAlpha ? blendBuf : alphaBuf);
						var al = b.type == BTAlpha;
						if( al ? openAlpha(x, y, z + 1) : open(x, y, z + 1) ) addQuadL(m, [fx, fy, fz + 1, fx + 1, fy, fz + 1, fx + 1, fy + 1, fz + 1, fx, fy + 1, fz + 1], b.tu, su, neg, 0, 0, 1, x, y, z);
						if( al ? openAlpha(x, y, z - 1) : open(x, y, z - 1) ) addQuadL(m, [fx, fy + 1, fz, fx + 1, fy + 1, fz, fx + 1, fy, fz, fx, fy, fz], b.td, sd, neg, 0, 0, -1, x, y, z);
						if( al ? openAlpha(x - 1, y, z) : open(x - 1, y, z) ) addQuadL(m, [fx, fy + 1, fz, fx, fy, fz, fx, fy, fz + 1, fx, fy + 1, fz + 1], b.tlr, sx, neg, -1, 0, 0, x, y, z);
						if( al ? openAlpha(x + 1, y, z) : open(x + 1, y, z) ) addQuadL(m, [fx + 1, fy, fz, fx + 1, fy + 1, fz, fx + 1, fy + 1, fz + 1, fx + 1, fy, fz + 1], b.tlr, sx, neg, 1, 0, 0, x, y, z);
						if( al ? openAlpha(x, y - 1, z) : open(x, y - 1, z) ) addQuadL(m, [fx, fy, fz, fx + 1, fy, fz, fx + 1, fy, fz + 1, fx, fy, fz + 1], b.tlr, sy, neg, 0, -1, 0, x, y, z);
						if( al ? openAlpha(x, y + 1, z) : open(x, y + 1, z) ) addQuadL(m, [fx + 1, fy + 1, fz, fx, fy + 1, fz, fx, fy + 1, fz + 1, fx + 1, fy + 1, fz + 1], b.tlr, sy, neg, 0, 1, 0, x, y, z);
					case BTModel, BTModel2Side, BTSprite:
						addModel(alphaBuf, b, fx, fy, fz);
					case BTReduced:
						if( b.size != null ) {
							// igual que el original: las caras de un bloque parcial se ven si no tapan todo el lado o si el vecino es transparente
							var s = b.size;
							var x1 = fx + s.x1, y1 = fy + s.y1, z1 = fz + s.z1, x2 = fx + s.x2, y2 = fy + s.y2, z2 = fz + s.z2;
							if( s.z2 < 1 || open(x, y, z + 1) ) addQuadL(alphaBuf, [x1, y1, z2, x2, y1, z2, x2, y2, z2, x1, y2, z2], b.tu, su, neg, 0, 0, 1, x, y, z, true);
							if( s.z1 > 0 || open(x, y, z - 1) ) addQuadL(alphaBuf, [x1, y2, z1, x2, y2, z1, x2, y1, z1, x1, y1, z1], b.td, sd, neg, 0, 0, -1, x, y, z, true);
							if( s.x1 > 0 || open(x - 1, y, z) ) addQuadL(alphaBuf, [x1, y2, z1, x1, y1, z1, x1, y1, z2, x1, y2, z2], b.tlr, sx, neg, -1, 0, 0, x, y, z, true);
							if( s.x2 < 1 || open(x + 1, y, z) ) addQuadL(alphaBuf, [x2, y1, z1, x2, y2, z1, x2, y2, z2, x2, y1, z2], b.tlr, sx, neg, 1, 0, 0, x, y, z, true);
							if( s.y1 > 0 || open(x, y - 1, z) ) addQuadL(alphaBuf, [x1, y1, z1, x2, y1, z1, x2, y1, z2, x1, y1, z2], b.tlr, sy, neg, 0, -1, 0, x, y, z, true);
							if( s.y2 < 1 || open(x, y + 1, z) ) addQuadL(alphaBuf, [x2, y2, z1, x1, y2, z1, x1, y2, z2, x2, y2, z2], b.tlr, sy, neg, 0, 1, 0, x, y, z, true);
						}
					case BTExtended:
						// caras con texturas distintas empaquetadas de a 12 bits (BFTextures)
						if( open(x, y, z + 1) ) addQuadL(alphaBuf, [fx, fy, fz + 1, fx + 1, fy, fz + 1, fx + 1, fy + 1, fz + 1, fx, fy + 1, fz + 1], b.tu & 0xFFF, su, neg, 0, 0, 1, x, y, z);
						if( open(x, y, z - 1) ) addQuadL(alphaBuf, [fx, fy + 1, fz, fx + 1, fy + 1, fz, fx + 1, fy, fz, fx, fy, fz], b.td & 0xFFF, sd, neg, 0, 0, -1, x, y, z);
						if( open(x - 1, y, z) ) addQuadL(alphaBuf, [fx, fy + 1, fz, fx, fy, fz, fx, fy, fz + 1, fx, fy + 1, fz + 1], b.tlr & 0xFFF, sx, neg, -1, 0, 0, x, y, z);
						if( open(x + 1, y, z) ) addQuadL(alphaBuf, [fx + 1, fy, fz, fx + 1, fy + 1, fz, fx + 1, fy + 1, fz + 1, fx + 1, fy, fz + 1], b.tlr >> 12, sx, neg, 1, 0, 0, x, y, z);
						if( open(x, y - 1, z) ) addQuadL(alphaBuf, [fx, fy, fz, fx + 1, fy, fz, fx + 1, fy, fz + 1, fx, fy, fz + 1], b.tu >> 12, sy, neg, 0, -1, 0, x, y, z);
						if( open(x, y + 1, z) ) addQuadL(alphaBuf, [fx + 1, fy + 1, fz, fx, fy + 1, fz, fx, fy + 1, fz + 1, fx + 1, fy + 1, fz + 1], b.td >> 12, sy, neg, 0, 1, 0, x, y, z);
					default:
					}
				}

		emitMesh(solidBuf, 0);
		emitMesh(alphaBuf, 1);
		emitMesh(waterBuf, 2);
		emitMesh(blendBuf, 3);
	}
}
