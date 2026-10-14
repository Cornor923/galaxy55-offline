import Common;

/**
	Prueba de viabilidad del render nativo: genera un planeta con los generadores originales,
	construye la geometria de las caras visibles por chunks de 16x16 (igual que el original)
	y la dibuja con Heaps moderno sobre HashLink.

	Uso: hl render.hl [semilla] [bioma] [tamano_en_chunks_de_128] [captura.png]
	Si se indica captura.png guarda una imagen y sale (sin necesidad de mirar la ventana).
**/
class RenderMain extends hxd.App {

	static inline var CSIZE = 16;
	static inline var ZBITS = 7;
	static inline var HEIGHT = 128;
	static inline var TE = 0.999;

	var seed = 1234;
	var biomeName = "BIAutumn";
	var sizeChunks = 1;
	var shotPath : String = null;

	var gen : gen.DetailsGenerator;
	var world : haxe.io.Bytes;
	var size : Int;
	var atlas : h3d.mat.Texture;
	var frames = 0;
	var faces = 0;
	var shotDone = false;

	override function init() {
		var args = Sys.args();
		if( args.length > 0 ) seed = Std.parseInt(args[0]);
		if( args.length > 1 ) biomeName = args[1];
		if( args.length > 2 ) sizeChunks = Std.parseInt(args[2]);
		if( args.length > 3 ) shotPath = args[3];

		var t0 = haxe.Timer.stamp();
		generate();
		var t1 = haxe.Timer.stamp();

		var png = sys.io.File.getBytes("src/G55/fla/client/gfx/texture.png");
		atlas = hxd.res.Any.fromBytes("texture.png", png).toTexture();
		atlas.filter = Nearest;
		atlas.mipMap = None;

		var meshes = 0;
		for( cy in 0...size >> 4 )
			for( cx in 0...size >> 4 )
				if( buildChunk(cx, cy) ) meshes++;
		var t2 = haxe.Timer.stamp();
		Sys.println('seed=$seed biome=$biomeName size=$size generar=${Std.int((t1 - t0) * 1000)}ms mallar=${Std.int((t2 - t1) * 1000)}ms chunks=$meshes caras=$faces');

		var c = s3d.camera;
		c.zNear = 1;
		c.zFar = 1500;
		c.fovY = 60;
		c.pos.set(size * 0.5, -size * 0.25, 125);
		c.target.set(size * 0.5, size * 0.55, 30);
		engine.backgroundColor = 0x6FA8DC;
	}

	function generate() {
		var biome : BiomeKind = Type.createEnum(BiomeKind, biomeName);
		size = sizeChunks << Const.BITS;
		gen = new gen.DetailsGenerator(size, seed);
		var bd = Data.getBiome(biome);
		gen.alloc(bd.water);
		gen.alloc(BMinIron);
		gen.alloc(BMinAluminium);
		for( s in bd.soils ) gen.alloc(s);
		gen.startGenerate(biome);
		while( gen.process(1000000) ) {}
		world = gen.getBytes().b;
	}

	inline function voxel( x : Int, y : Int, z : Int ) : Int {
		if( x < 0 ) x += size else if( x >= size ) x -= size;
		if( y < 0 ) y += size else if( y >= size ) y -= size;
		if( z < 0 ) return 1;
		if( z >= HEIGHT ) return 0;
		return world.get(((x + y * size) << ZBITS) | z);
	}

	/** true si la cara contra este voxel se ve (aire o bloque que deja pasar la luz) */
	inline function open( x : Int, y : Int, z : Int ) : Bool {
		var id = voxel(x, y, z);
		return id == 0 || gen.btrans[id];
	}

	function buildChunk( cx : Int, cy : Int ) : Bool {
		var pts = new Array<h3d.col.Point>();
		var uvs = new Array<h3d.prim.UV>();
		var cols = new Array<h3d.col.Point>();
		var idx = new hxd.IndexBuffer();

		function quad( p : Array<Float>, tile : Int, shade : Float ) {
			if( tile < 0 || tile >= 0xFFF ) return;
			var tx = tile & 63, ty = tile >> 6;
			var u0 = tx / 64 + (1 - TE) / 128, v0 = ty / 64 + (1 - TE) / 128;
			var u1 = u0 + TE / 64, v1 = v0 + TE / 64;
			var b = pts.length;
			pts.push(new h3d.col.Point(p[0], p[1], p[2]));
			pts.push(new h3d.col.Point(p[3], p[4], p[5]));
			pts.push(new h3d.col.Point(p[6], p[7], p[8]));
			pts.push(new h3d.col.Point(p[9], p[10], p[11]));
			uvs.push(new h3d.prim.UV(u0, v1));
			uvs.push(new h3d.prim.UV(u1, v1));
			uvs.push(new h3d.prim.UV(u1, v0));
			uvs.push(new h3d.prim.UV(u0, v0));
			for( i in 0...4 ) cols.push(new h3d.col.Point(shade, shade, shade));
			idx.push(b); idx.push(b + 1); idx.push(b + 2);
			idx.push(b); idx.push(b + 2); idx.push(b + 3);
			faces++;
		}

		for( y in cy * CSIZE...(cy + 1) * CSIZE )
			for( x in cx * CSIZE...(cx + 1) * CSIZE )
				for( z in 1...HEIGHT ) {
					var id = voxel(x, y, z);
					if( id == 0 ) continue;
					var b = gen.blocks[id];
					if( b == null || b.type != BTFull ) continue;
					var su = Math.sqrt(b.shadeUp), sd = Math.sqrt(b.shadeDown);
					var sx = Math.sqrt(b.shadeX), sy = Math.sqrt(b.shadeY);
					var fx = x, fy = y, fz = z;
					// arriba
					if( open(x, y, z + 1) ) quad([fx, fy, fz + 1, fx + 1, fy, fz + 1, fx + 1, fy + 1, fz + 1, fx, fy + 1, fz + 1], b.tu, su);
					// abajo
					if( open(x, y, z - 1) ) quad([fx, fy + 1, fz, fx + 1, fy + 1, fz, fx + 1, fy, fz, fx, fy, fz], b.td, sd);
					// -x / +x
					if( open(x - 1, y, z) ) quad([fx, fy + 1, fz, fx, fy, fz, fx, fy, fz + 1, fx, fy + 1, fz + 1], b.tlr, sx);
					if( open(x + 1, y, z) ) quad([fx + 1, fy, fz, fx + 1, fy + 1, fz, fx + 1, fy + 1, fz + 1, fx + 1, fy, fz + 1], b.tlr, sx);
					// -y / +y
					if( open(x, y - 1, z) ) quad([fx, fy, fz, fx + 1, fy, fz, fx + 1, fy, fz + 1, fx, fy, fz + 1], b.tlr, sy);
					if( open(x, y + 1, z) ) quad([fx + 1, fy + 1, fz, fx, fy + 1, fz, fx, fy + 1, fz + 1, fx + 1, fy + 1, fz + 1], b.tlr, sy);
				}

		if( pts.length == 0 ) return false;
		var poly = new h3d.prim.Polygon(pts, idx);
		poly.uvs = uvs;
		poly.colors = cols;
		var mat = h3d.mat.Material.create(atlas);
		mat.shadows = false;
		mat.mainPass.enableLights = false;
		mat.mainPass.culling = None;
		mat.mainPass.addShader(new h3d.shader.VertexColor());
		new h3d.scene.Mesh(poly, mat, s3d);
		return true;
	}

	override function update( dt : Float ) {
		frames++;
		if( shotPath != null && frames == 4 && !shotDone ) {
			shotDone = true;
			var w = engine.width, h = engine.height;
			var tex = new h3d.mat.Texture(w, h, [Target]);
			tex.depthBuffer = new h3d.mat.Texture(w, h, [Target], Depth24Stencil8);
			engine.pushTarget(tex);
			engine.clear(0x6FA8DC, 1, 0);
			s3d.render(engine);
			engine.popTarget();
			var px = tex.capturePixels();
			sys.io.File.saveBytes(shotPath, px.toPNG());
			Sys.println("captura guardada: " + shotPath);
			Sys.exit(0);
		}
	}

	static function main() {
		new RenderMain();
	}
}
