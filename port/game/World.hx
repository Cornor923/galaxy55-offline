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

	public function new( seed : Int, biomeName : String, sizeChunks : Int, parent : h3d.scene.Object, atlas : h3d.mat.Texture, menuFog = false ) {
		this.seed = seed;
		this.biomeName = biomeName;
		this.atlas = atlas;
		size = sizeChunks << Const.BITS;
		root = new h3d.scene.Object(parent);
		var biome : BiomeKind = Type.createEnum(BiomeKind, biomeName);
		sky = new Sky(root, biome, menuFog);		gen = new gen.DetailsGenerator(size, seed);
		var bd = Data.getBiome(biome);
		gen.alloc(bd.water);
		gen.alloc(BMinIron);
		gen.alloc(BMinAluminium);
		for( s in bd.soils ) gen.alloc(s);
		gen.startGenerate(biome);
		genStarted = haxe.Timer.stamp();
	}

	public inline function isReady() return phase >= 2;

	/** Avanza la carga durante budgetMs milisegundos; devuelve el progreso de 0 a 1. */
	public function step( budgetMs : Float ) : Float {
		var t0 = haxe.Timer.stamp();
		if( phase == 0 ) {
			if( !gen.process(Std.int(budgetMs)) ) {
				bytes = gen.getBytes().b;
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

	public function spawnPoint() : { x : Float, y : Float, z : Float } {
		var x = size >> 1, y = size >> 1;
		var z = HEIGHT - 1;
		while( z > 1 && !opaque(x, y, z) ) z--;
		return { x : x + 0.5, y : y + 0.5, z : z + 1.01 };
	}

	// ---------------------------------------------------------------- mallado

	function addQuad( m : MeshBuf, p : Array<Float>, tile : Int, shade : Float ) {
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
		for( i in 0...4 ) m.cols.push(new h3d.col.Point(shade, shade, shade));
		m.idx.push(b); m.idx.push(b + 1); m.idx.push(b + 2);
		m.idx.push(b); m.idx.push(b + 2); m.idx.push(b + 3);
		faces++;
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
					switch( b.type ) {
					case BTWater:
						// solo la superficie
						if( voxel(x, y, z + 1) == 0 )
							addQuad(waterBuf, [fx, fy, fz + 0.9, fx + 1, fy, fz + 0.9, fx + 1, fy + 1, fz + 0.9, fx, fy + 1, fz + 0.9], b.tu, su);
					case BTFull, BTAlpha, BTTransp:
						var m = b.type == BTFull ? solidBuf : alphaBuf;
						var al = b.type == BTAlpha;
						if( al ? openAlpha(x, y, z + 1) : open(x, y, z + 1) ) addQuad(m, [fx, fy, fz + 1, fx + 1, fy, fz + 1, fx + 1, fy + 1, fz + 1, fx, fy + 1, fz + 1], b.tu, su);
						if( al ? openAlpha(x, y, z - 1) : open(x, y, z - 1) ) addQuad(m, [fx, fy + 1, fz, fx + 1, fy + 1, fz, fx + 1, fy, fz, fx, fy, fz], b.td, sd);
						if( al ? openAlpha(x - 1, y, z) : open(x - 1, y, z) ) addQuad(m, [fx, fy + 1, fz, fx, fy, fz, fx, fy, fz + 1, fx, fy + 1, fz + 1], b.tlr, sx);
						if( al ? openAlpha(x + 1, y, z) : open(x + 1, y, z) ) addQuad(m, [fx + 1, fy, fz, fx + 1, fy + 1, fz, fx + 1, fy + 1, fz + 1, fx + 1, fy, fz + 1], b.tlr, sx);
						if( al ? openAlpha(x, y - 1, z) : open(x, y - 1, z) ) addQuad(m, [fx, fy, fz, fx + 1, fy, fz, fx + 1, fy, fz + 1, fx, fy, fz + 1], b.tlr, sy);
						if( al ? openAlpha(x, y + 1, z) : open(x, y + 1, z) ) addQuad(m, [fx + 1, fy + 1, fz, fx, fy + 1, fz, fx, fy + 1, fz + 1, fx + 1, fy + 1, fz + 1], b.tlr, sy);
					default:
					}
				}

		emitMesh(solidBuf, 0);
		emitMesh(alphaBuf, 1);
		emitMesh(waterBuf, 2);
	}
}
