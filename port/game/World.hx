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

	/**
	 * Curvatura del planeta. El original usa curve = 2 / totalSize (AbstractGame); el port la reduce (CURVE_K) porque se notaba
	 * demasiado. Se usa en el dibujo (Sky.FogShader) y al apuntar (GameView.pick), que tienen que coincidir.
	 */
	public static inline var CURVE_K = 0.6;
	public static inline function curve( size : Int ) : Float return CURVE_K * 2.0 / size;
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
	var lightIdx : Array<Int>;
	var lightInfos : Array<{ p : Int, f : Float, pw : Float }>;
	var mask : haxe.io.Bytes;
	var useMask = false;
	/** cambios del jugador sobre el terreno: celda -> indice global de bloque (0 = aire); se guardan con la partida */
	public var editMap = new Map<Int, Int>();
	var savedEdits : Array<Int>;
	var chunkMeshes : Array<Array<Int>>;
	var curList : Array<Int>;
	var immediate = new Array<Int>();
	var pendingRelight = new Array<Int>();
	var lightChunks = new Array<Int>();

	// la nave (ShipLogic/Level.extra del original): un volumen de 128x128x128 colgado sobre el planeta, desde z = SHIP_Z
	public static inline var SHIP_Z = 130;
	/** la nave de este planeta (solo en el mundo del planeta) */
	public var ship : World;
	/** desplazamiento (x, y) de la nave respecto al planeta: celda de la nave + desplazamiento = posicion en el planeta */
	public var shipDX = 0;
	public var shipDY = 0;
	/** true en el mundo de la nave: no da la vuelta y usa el cielo del planeta */
	public var isShip(default, null) = false;
	/** altura desde la que entra el sol (-1 = desde arriba del todo); el hangar la pone bajo el techo (EditShip: planet.lightHeight) */
	public var lightTop = -1;
	var wraps = true;
	var ownSky = true;

	public function new( seed : Int, biomeName : String, sizeChunks : Int, parent : h3d.scene.Object, atlas : h3d.mat.Texture, menuFog = false, ?savedEdits : Array<Int>, ?shipData : ShipData.ShipDataInfo, ?sharedSky : Sky ) {
		this.savedEdits = savedEdits;
		this.seed = seed;
		this.biomeName = biomeName;
		this.atlas = atlas;
		size = sizeChunks << Const.BITS;
		chunkMeshes = [for( i in 0...sizeChunks * sizeChunks * 64 ) null];
		root = new h3d.scene.Object(parent);
		var biome : BiomeKind = Type.createEnum(BiomeKind, biomeName);
		// la nave comparte el cielo (niebla y curvatura) del planeta
		if( sharedSky != null ) {
			sky = sharedSky;
			ownSky = false;
		} else {
			sky = new Sky(root, biome, menuFog);
			sky.fog.curve = curve(size);
		}
		gen = new gen.DetailsGenerator(size, seed);
		var bd = Data.getBiome(biome);
		sunP = bd.sunPower;
		sunF = bd.sunFalloff == null ? 1 : bd.sunFalloff;
		gen.alloc(bd.water);
		gen.alloc(BMinIron);
		gen.alloc(BMinAluminium);
		for( s in bd.soils ) gen.alloc(s);
		if( shipData == null ) gen.startGenerate(biome);
		else initShip(shipData);
		// como Builder.init: los modelos sin BFSize usan su propia caja para las colisiones
		for( b in Block.all )
			if( b.model != null && b.size == null ) b.size = Models.get(b.model).box;
		genStarted = haxe.Timer.stamp();
	}

	public inline function isReady() return phase >= 2;

	/** Avanza la carga durante budgetMs milisegundos; devuelve el progreso de 0 a 1. */
	public function step( budgetMs : Float ) : Float {
		var t0 = haxe.Timer.stamp();
		if( phase == 0 && isShip ) {
			applySaved();
			computeLight();
			phase = 1;
			return progress = 0.75;
		}
		if( phase == 0 ) {
			if( !gen.process(Std.int(budgetMs)) ) {
				bytes = gen.getBytes().b;
				initLightTables();
				applySaved();
				var tl = haxe.Timer.stamp();
				computeLight();
				if( Sys.args().indexOf("--lighttime") >= 0 ) Sys.println("luz " + size + ": " + Std.int((haxe.Timer.stamp() - tl) * 1000) + " ms");
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
		if( ship != null ) ship.dispose();
		if( ownSky ) sky.dispose();
		for( m in meshes ) {
			if( m == null ) continue;
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

	/** Builder.isTransparentNot(p, BTWater) del original: ni bloque lleno ni agua (el aire cuenta como abierto) */
	inline function waterOpen( x : Int, y : Int, z : Int ) : Bool {
		var id = voxel(x, y, z);
		if( id == 0 ) return z > 0;
		var t = tagOf(id);
		return t != BTFull && t != BTWater;
	}

	/** tipo de bloque a efectos de mallado (las hojas sin BFNoOptimize cuentan como bloque lleno, igual que el original) */
	function tagOf( id : Int ) : BlockType {
		var b = gen.blocks[id];
		// con tarjeta grafica el original NO trata las hojas como bloques llenos (solo el modo por software lo hacia):
		// asi las caras que hay detras de una hoja se dibujan y se ven a traves de sus huecos transparentes
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
		if( z >= SHIP_Z ) return shipBlock(x, y, z);
		var id = voxel(x, y, z);
		return id <= 0 ? null : gen.blocks[id];
	}

	/** Igual que Level.collide del original: consulta de un punto, con la caja de los bloques parciales. */
	public function collidePoint( x : Float, y : Float, z : Float ) : Bool {
		if( z >= SHIP_Z ) {
			if( ship == null ) return false;
			var lx = shipLocal(x, shipDX), ly = shipLocal(y, shipDY);
			if( lx >= ship.size || ly >= ship.size ) return false;
			return ship.collidePoint(lx, ly, z - SHIP_Z);
		}
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
		if( z >= SHIP_Z && ship != null ) {
			var lx = Std.int(shipLocal(x, shipDX)), ly = Std.int(shipLocal(y, shipDY));
			return lx >= ship.size || ly >= ship.size ? 0 : ship.lightAt(lx, ly, z - SHIP_Z);
		}
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
		var top = lightTop >= 0 ? lightTop : HEIGHT - 1;
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
		if( light.get(q) < l && idTag[bytes.get(q)] < NOLIGHT && (!useMask || mask.get(q >> ZBITS) != 0) ) {
			light.set(q, l);
			next.push(q);
		}
	}

	// ---------------------------------------------------------------- nave

	function initShip( d : ShipData.ShipDataInfo ) {
		isShip = true;
		wraps = false;
		bytes = haxe.io.Bytes.alloc(size * size * HEIGHT);
		initLightTables();
		for( c in d.cells )
			bytes.set(((c.x + c.y * size) << ZBITS) | c.z, localId(Block.all[c.id]));
	}

	/** coordenada de la nave que corresponde a una del planeta (el planeta da la vuelta) */
	function shipLocal( v : Float, d : Int ) : Float {
		var l = (v - d) % size;
		if( l < 0 ) l += size;
		return l;
	}

	function shipBlock( x : Int, y : Int, z : Int ) : Block {
		if( ship == null ) return null;
		var lx = Std.int(shipLocal(x, shipDX)), ly = Std.int(shipLocal(y, shipDY));
		if( lx >= ship.size || ly >= ship.size ) return null;
		return ship.block(lx, ly, z - SHIP_Z);
	}

	/** Level.getStartPlace del original: un sitio de tierra llana fuera del agua donde aterriza la nave (fijo por semilla) */
	public function startPlace( rnd : mt.Rand ) : { x : Int, y : Int, z : Int } {
		var biome : BiomeKind = Type.createEnum(BiomeKind, biomeName);
		var binf = Data.getBiome(biome);
		var water = gen.getWaterInfos().level;
		var soil = Block.get(binf.soils[1]);
		var through = new Map<Int, Bool>();
		for( b in binf.startThrough ) through.set(Block.get(b).index, true);
		var ntry = 10000;
		while( --ntry > 0 ) {
			var x = rnd.random(size - 2) + 1;
			var y = rnd.random(size - 2) + 1;
			var z = HEIGHT - 1;
			while( z > water ) {
				var b = block(x, y, z);
				if( b != null && !through.exists(b.index) ) break;
				z--;
			}
			if( z <= water ) continue;
			if( !block(x, y, z).isSame(soil) ) continue;
			z++;
			if( !freePlace(x, y, z) ) continue;
			return { x : x, y : y, z : z };
		}
		return null;
	}

	/** casi plano: pocos huecos alrededor (Level.freePlace) */
	function freePlace( x : Int, y : Int, z : Int ) : Bool {
		var count = 0;
		for( dx in -1...2 )
			for( dy in -1...2 )
				if( block(x + dx, y + dy, z) != null ) count++;
		z--;
		for( dx in -1...2 )
			for( dy in -1...2 )
				if( block(x + dx, y + dy, z) == null ) count++;
		return count < 3;
	}

	// ---------------------------------------------------------------- edicion

	inline function wrapC( v : Int ) : Int {
		return v < 0 ? v + size : (v >= size ? v - size : v);
	}

	function initLightTables() {
		idTag = [];
		lightIdx = [];
		lightInfos = [];
		for( i in 0...gen.blocks.length ) registerId(i);
	}

	/** tablas de tipo y de luz de un id local de bloque */
	function registerId( id : Int ) {
		while( idTag.length <= id ) idTag.push(0);
		while( lightIdx.length <= id ) lightIdx.push(-1);
		var b = gen.blocks[id];
		idTag[id] = b == null ? 0 : Type.enumIndex(b.type);
		lightIdx[id] = -1;
		if( b != null && b.special != null )
			switch( b.special ) {
			case BFLight(p, f):
				var ip = Std.int(p);
				if( ip > 15 ) ip = 15;
				lightIdx[id] = lightInfos.length;
				lightInfos.push({ p : ip, f : f == null ? 1.0 : f, pw : p });
			default:
			}
	}

	/** id local (de este planeta) de un bloque global; lo da de alta si el mundo no lo tenia */
	public function localId( b : Block ) : Int {
		if( b == null ) return 0;
		var id = gen.alloc(b.k);
		for( i in idTag.length...gen.blocks.length ) registerId(i);
		return id > 255 ? 0 : id;
	}

	function applySaved() {
		if( savedEdits == null ) return;
		var i = 0;
		while( i + 1 < savedEdits.length ) {
			var key = savedEdits[i], gi = savedEdits[i + 1];
			i += 2;
			var b = gi == 0 ? null : Block.all[gi];
			bytes.set(key, localId(b));
			editMap.set(key, gi);
		}
		savedEdits = null;
	}

	/** cambios para guardar: pares [celda, bloque, celda, bloque, ...] */
	public function editsFlat() : Array<Int> {
		var out = [];
		for( k in editMap.keys() ) {
			out.push(k);
			out.push(editMap.get(k));
		}
		return out;
	}

	/** Cambia un bloque (null = aire). El trozo se rehace al momento; la luz y los vecinos, en los siguientes fotogramas. */
	public function setBlock( x : Int, y : Int, z : Int, b : Block ) : Void {
		if( z >= SHIP_Z ) {
			// la nave tiene su propio volumen
			if( ship != null ) ship.setBlock(Std.int(shipLocal(x, shipDX)), Std.int(shipLocal(y, shipDY)), z - SHIP_Z, b);
			return;
		}
		x = wrapC(x);
		y = wrapC(y);
		if( z < 1 || z >= HEIGHT - 1 ) return;
		var key = ((x + y * size) << ZBITS) | z;
		bytes.set(key, localId(b));
		editMap.set(key, b == null ? 0 : b.index);
		var n = size >> 4;
		for( dy in -1...2 )
			for( dx in -1...2 ) {
				var c = wrapC(x + dx) >> 4, d = wrapC(y + dy) >> 4;
				var id = c + d * n;
				if( immediate.indexOf(id) < 0 ) immediate.push(id);
			}
		pendingRelight.push(key);
	}

	/** Procesa lo pendiente tras editar: trozos inmediatos, una zona de luz y unos pocos trozos por fotograma. */
	public function flush() {
		var n = size >> 4;
		while( immediate.length > 0 ) {
			var id = immediate.pop();
			buildChunk(id % n, Std.int(id / n));
		}
		if( pendingRelight.length > 0 ) {
			var key = pendingRelight.shift();
			var col = key >> ZBITS;
			var x = col % size, y = Std.int(col / size);
			relightRegion(x, y, 12);
			// los trozos que cubre la zona (esquinas y centro incluidos)
			for( cy in (y - 12) >> 4...((y + 12) >> 4) + 1 )
				for( cx in (x - 12) >> 4...((x + 12) >> 4) + 1 ) {
					var wx = cx < 0 ? cx + n : (cx >= n ? cx - n : cx);
					var wy = cy < 0 ? cy + n : (cy >= n ? cy - n : cy);
					var id = wx + wy * n;
					if( lightChunks.indexOf(id) < 0 ) lightChunks.push(id);
				}
		}
		var k = 0;
		while( lightChunks.length > 0 && k < 2 ) {
			var id = lightChunks.shift();
			buildChunk(id % n, Std.int(id / n));
			k++;
		}
	}

	public inline function hasPending() : Bool {
		return immediate.length > 0 || pendingRelight.length > 0 || lightChunks.length > 0;
	}

	/** Recalcula la luz de una zona (radio rIn) usando las fuentes de una zona mayor, como el original pero local. */
	function relightRegion( cx : Int, cy : Int, rIn : Int ) {
		var rOut = rIn + 16;
		if( rOut * 2 + 1 >= size ) {
			computeLight();
			return;
		}
		var span = rOut * 2 + 1;
		if( mask == null ) mask = haxe.io.Bytes.alloc(size * size);
		var saved = haxe.io.Bytes.alloc(span * span * HEIGHT);
		var cols = new Array<Int>();
		for( dy in -rOut...rOut + 1 )
			for( dx in -rOut...rOut + 1 ) {
				var col = wrapC(cx + dx) + wrapC(cy + dy) * size;
				cols.push(col);
				mask.set(col, 1);
			}
		for( i in 0...cols.length ) {
			var base = cols[i] << ZBITS;
			saved.blit(i * HEIGHT, light, base, HEIGHT);
			light.fill(base, HEIGHT, 0);
		}
		useMask = true;
		var lmax = Std.int(sunP);
		var lsun = Std.int(sunP - sunF);
		if( lsun < 0 ) lsun = 0;
		var seeds = new Array<Int>();
		for( col in cols ) sunColumn(col, lmax, lsun, seeds);
		flood(seeds, sunP - sunF * 2, sunF);
		for( col in cols ) {
			var base = col << ZBITS;
			for( z in 1...HEIGHT ) {
				var p = base | z;
				var li = lightIdx[bytes.get(p)];
				if( li < 0 ) continue;
				var info = lightInfos[li];
				if( light.get(p) >= info.p ) continue;
				light.set(p, info.p);
				flood([p], info.pw - info.f, info.f);
			}
		}
		useMask = false;
		for( i in 0...cols.length ) {
			var dx = i % span - rOut, dy = Std.int(i / span) - rOut;
			if( dx > rIn || dx < -rIn || dy > rIn || dy < -rIn )
				light.blit(cols[i] << ZBITS, saved, i * HEIGHT, HEIGHT);
			mask.set(cols[i], 0);
		}
	}

	/** luz de sol de una columna (misma logica que computeLight, para una zona) */
	function sunColumn( col : Int, lmax : Int, lsun : Int, seeds : Array<Int> ) {
		var x = col % size, y = Std.int(col / size);
		var base = col << ZBITS;
		var cxm = x == 0 ? col + size - 1 : col - 1;
		var cym = y == 0 ? col + size * (size - 1) : col - size;
		var okx = !useMask || mask.get(cxm) != 0;
		var oky = !useMask || mask.get(cym) != 0;
		var z = lightTop >= 0 ? lightTop : HEIGHT - 1;
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
			if( okx ) {
				var q = (cxm << ZBITS) | z;
				if( light.get(q) == 0 && idTag[bytes.get(q)] < NOLIGHT ) {
					light.set(q, lsun);
					seeds.push(q);
				}
			}
			if( oky ) {
				var q = (cym << ZBITS) | z;
				if( light.get(q) == 0 && idTag[bytes.get(q)] < NOLIGHT ) {
					light.set(q, lsun);
					seeds.push(q);
				}
			}
			z--;
		}
		while( z > 0 ) {
			var p = base | z;
			if( idTag[bytes.get(p)] < NOLIGHT && ((okx && isSunAir((cxm << ZBITS) | z, lmax)) || (oky && isSunAir((cym << ZBITS) | z, lmax))) ) {
				light.set(p, lsun);
				seeds.push(p);
			}
			z--;
		}
	}

	// ---------------------------------------------------------------- mallado

	var shv = [0., 0., 0., 0.];
	var redFace = -1;
	var redB : Array<Float>;

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
			var l : Float = lightAt(cx + ox, cy + oy, cz + oz);
			// cambio del port: si al lado hay otro bloque que no deja pasar la luz (p. ej. dos hierros juntos), la cara
			// salia negra; se usa la luz mas alta alrededor del bloque
			if( l == 0 ) {
				l = (Math.max(Math.max(lightAt(cx + 1, cy, cz), lightAt(cx - 1, cy, cz)), Math.max(Math.max(lightAt(cx, cy + 1, cz), lightAt(cx, cy - 1, cz)), Math.max(lightAt(cx, cy, cz + 1), lightAt(cx, cy, cz - 1)))));
			}
			l = l * shade / LBASE;
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
		if( redFace >= 0 ) {
			// bloque parcial (BTReduced): como Builder.addCustomQuad, la cara muestra un RECORTE de la casilla del tamano de la cara
			// (en bloques), desde su esquina superior izquierda, en vez de la casilla entera estirada
			for( k in 0...4 ) {
				var px = p[k * 3], py = p[k * 3 + 1], pz = p[k * 3 + 2];
				var u : Float, v : Float;
				switch( redFace ) {
				case 0, 1: u = py - redB[1]; v = redB[2] - px;
				case 2: u = py - redB[1]; v = redB[4] - pz;
				case 3: u = redB[3] - py; v = redB[4] - pz;
				case 4: u = redB[2] - px; v = redB[4] - pz;
				default: u = px - redB[0]; v = redB[4] - pz;
				}
				m.uvs.push(new h3d.prim.UV((tx + u * TE) / 64, (ty + v * TE) / 64));
			}
			redFace = -1;
		} else {
		m.uvs.push(new h3d.prim.UV(u0, v1));
		m.uvs.push(new h3d.prim.UV(u1, v1));
		m.uvs.push(new h3d.prim.UV(u1, v0));
		m.uvs.push(new h3d.prim.UV(u0, v0));
		}
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
			// orden del original (Render.hx: BTWater antes que BTAlpha): se dibujan despues del agua, asi el hielo sumergido queda detras de ella
			mat.blendMode = Alpha;
			mat.mainPass.depthWrite = false;
			mat.mainPass.setPassName("additive");
		} else if( kind == 2 ) {
			// agua: translucida; escribe profundidad como la primera pasada del original (water0)
			mat.blendMode = Alpha;
			mat.color.a = 0.6;
			mat.mainPass.depthWrite = true;
			mat.mainPass.setPassName("alpha");
		}
		if( kind == 3 ) {
			// pasada opaca de los pixeles solidos (marcos del cristal, bordes del hielo): escribe profundidad, asi las caras lejanas
			// no se pintan encima de las cercanas (la pasada translucida no puede ordenar triangulos)
			var cut = h3d.mat.Material.create(atlas);
			cut.shadows = false;
			cut.mainPass.enableLights = false;
			cut.mainPass.culling = None;
			cut.mainPass.addShader(new h3d.shader.VertexColor());
			cut.mainPass.addShader(sky.fog);
			cut.textureShader.killAlpha = true;
			cut.textureShader.killAlphaThreshold = 0.9;
			meshes.push(new h3d.scene.Mesh(poly, cut, root));
			if( curList != null ) curList.push(meshes.length - 1);
			meshCx.push(curCx);
			meshCy.push(curCy);
		}
		meshes.push(new h3d.scene.Mesh(poly, mat, root));
		if( curList != null ) curList.push(meshes.length - 1);
		meshCx.push(curCx);
		meshCy.push(curCy);
	}

	/**
	 * El planeta da la vuelta como en el original (AbstractGame.real/realDist): cada chunk se dibuja en la copia
	 * mas cercana a la camara, asi no hay borde del mundo y el horizonte sigue siendo terreno.
	 */
	public function updateWrap( x : Float, y : Float ) {
		if( !wraps || (x == wrapX && y == wrapY) ) return;
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
			if( m == null ) continue;
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
		// si el trozo ya existia (edicion), se quitan sus mallas antiguas
		var cid = cx + cy * (size >> 4);
		var old = chunkMeshes[cid];
		if( old != null )
			for( i in old ) {
				var om = meshes[i];
				if( om == null ) continue;
				var ex = i < meshExtra.length ? meshExtra[i] : null;
				if( ex != null ) {
					for( c in ex ) if( c != null ) c.remove();
					meshExtra[i] = null;
				}
				om.remove();
				om.primitive.dispose();
				meshes[i] = null;
			}
		curList = [];
		chunkMeshes[cid] = curList;
		wrapX = -1e9;
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
						// Builder.hx del original: cada cara contra un vecino que no es lleno ni agua (isTransparentNot(p, BTWater))
						var top = voxel(x, y, z + 1) == 0;
						var h = top ? fz + 0.9 : fz + 1;
						if( top || waterOpen(x, y, z + 1) )
							addQuadL(waterBuf, [fx, fy, h, fx + 1, fy, h, fx + 1, fy + 1, h, fx, fy + 1, h], b.tu, su, neg, 0, 0, 1, x, y, z);
						if( waterOpen(x, y, z - 1) ) addQuadL(waterBuf, [fx, fy + 1, fz, fx + 1, fy + 1, fz, fx + 1, fy, fz, fx, fy, fz], b.td, sd, neg, 0, 0, -1, x, y, z);
						if( waterOpen(x - 1, y, z) ) addQuadL(waterBuf, [fx, fy + 1, fz, fx, fy, fz, fx, fy, h, fx, fy + 1, h], b.tlr, sx, neg, -1, 0, 0, x, y, z);
						if( waterOpen(x + 1, y, z) ) addQuadL(waterBuf, [fx + 1, fy, fz, fx + 1, fy + 1, fz, fx + 1, fy + 1, h, fx + 1, fy, h], b.tlr, sx, neg, 1, 0, 0, x, y, z);
						if( waterOpen(x, y - 1, z) ) addQuadL(waterBuf, [fx, fy, fz, fx + 1, fy, fz, fx + 1, fy, h, fx, fy, h], b.tlr, sy, neg, 0, -1, 0, x, y, z);
						if( waterOpen(x, y + 1, z) ) addQuadL(waterBuf, [fx + 1, fy + 1, fz, fx, fy + 1, fz, fx, fy + 1, h, fx + 1, fy + 1, h], b.tlr, sy, neg, 0, 1, 0, x, y, z);
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
							redB = [x1, y1, x2, y2, z2];
							if( s.z2 < 1 || open(x, y, z + 1) ) { redFace = 0; addQuadL(alphaBuf, [x1, y1, z2, x2, y1, z2, x2, y2, z2, x1, y2, z2], b.tu, su, neg, 0, 0, 1, x, y, z, true); }
							if( s.z1 > 0 || open(x, y, z - 1) ) { redFace = 1; addQuadL(alphaBuf, [x1, y2, z1, x2, y2, z1, x2, y1, z1, x1, y1, z1], b.td, sd, neg, 0, 0, -1, x, y, z, true); }
							if( s.x1 > 0 || open(x - 1, y, z) ) { redFace = 2; addQuadL(alphaBuf, [x1, y2, z1, x1, y1, z1, x1, y1, z2, x1, y2, z2], b.tlr, sx, neg, -1, 0, 0, x, y, z, true); }
							if( s.x2 < 1 || open(x + 1, y, z) ) { redFace = 3; addQuadL(alphaBuf, [x2, y1, z1, x2, y2, z1, x2, y2, z2, x2, y1, z2], b.tlr, sx, neg, 1, 0, 0, x, y, z, true); }
							if( s.y1 > 0 || open(x, y - 1, z) ) { redFace = 4; addQuadL(alphaBuf, [x1, y1, z1, x2, y1, z1, x2, y1, z2, x1, y1, z2], b.tlr, sy, neg, 0, -1, 0, x, y, z, true); }
							if( s.y2 < 1 || open(x, y + 1, z) ) { redFace = 5; addQuadL(alphaBuf, [x2, y2, z1, x1, y2, z1, x1, y2, z2, x2, y2, z2], b.tlr, sy, neg, 0, 1, 0, x, y, z, true); }
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
