import Common;
import World.MeshBuf;

/**
 * Geometria suelta de un bloque (iconos del inventario y objetos que caen al romper).
 * Cada cara usa la textura del atlas y el sombreado fijo por cara del original (sqrt de shadeX/shadeY/shadeUp/shadeDown).
 */
class IconMesh {

	static inline var TE = 0.999;

	/** caja parcial en curso (x1, y1, x2, y2, z2): sus caras muestran un recorte de la casilla, como en el mundo */
	static var rb : Array<Float> = null;
	/** con las 6 caras: primero las de atras (-x, +y, abajo), para mezclar bien las translucidas sin escribir profundidad */
	static var backFirst = false;

	static function quad( m : MeshBuf, p : Array<Float>, tile : Int, shade : Float, face = -1 ) {
		if( tile < 0 || tile >= 0xFFF ) return;
		var tx = tile & 63, ty = tile >> 6;
		var u0 = tx / 64 + (1 - TE) / 128, v0 = ty / 64 + (1 - TE) / 128;
		var u1 = u0 + TE / 64, v1 = v0 + TE / 64;
		var b = m.pts.length;
		for( k in 0...4 ) m.pts.push(new h3d.col.Point(p[k * 3], p[k * 3 + 1], p[k * 3 + 2]));
		if( face >= 0 && rb != null ) {
			for( k in 0...4 ) {
				var px = p[k * 3], py = p[k * 3 + 1], pz = p[k * 3 + 2];
				var u : Float, v : Float;
				switch( face ) {
				case 0, 1: u = py - rb[1]; v = rb[2] - px;
				case 2: u = py - rb[1]; v = rb[4] - pz;
				case 3: u = rb[3] - py; v = rb[4] - pz;
				case 4: u = rb[2] - px; v = rb[4] - pz;
				default: u = px - rb[0]; v = rb[4] - pz;
				}
				m.uvs.push(new h3d.prim.UV((tx + u * TE) / 64, (ty + v * TE) / 64));
			}
		} else {
			m.uvs.push(new h3d.prim.UV(u0, v1));
			m.uvs.push(new h3d.prim.UV(u1, v1));
			m.uvs.push(new h3d.prim.UV(u1, v0));
			m.uvs.push(new h3d.prim.UV(u0, v0));
		}
		for( i in 0...4 ) m.cols.push(new h3d.col.Point(shade, shade, shade));
		m.idx.push(b); m.idx.push(b + 1); m.idx.push(b + 2);
		m.idx.push(b); m.idx.push(b + 2); m.idx.push(b + 3);
	}

	/** caja con una textura por cara; all=false solo dibuja las 3 caras que ve la camara isometrica (+x, -y, +z) */
	static function box( m : MeshBuf, b : Block, x1 : Float, y1 : Float, z1 : Float, x2 : Float, y2 : Float, z2 : Float, all : Bool, red = false ) {
		var su = Math.sqrt(b.shadeUp), sd = Math.sqrt(b.shadeDown), sx = Math.sqrt(b.shadeX), sy = Math.sqrt(b.shadeY);
		var tu = b.tu, td = b.td, tlr = b.tlr;
		if( b.type == BTExtended ) {
			quad(m, [x1, y1, z2, x2, y1, z2, x2, y2, z2, x1, y2, z2], b.tu & 0xFFF, su);
			quad(m, [x2, y1, z1, x2, y2, z1, x2, y2, z2, x2, y1, z2], b.tlr >> 12, sx);
			quad(m, [x1, y1, z1, x2, y1, z1, x2, y1, z2, x1, y1, z2], b.tu >> 12, sy);
			if( all ) {
				quad(m, [x1, y2, z1, x2, y2, z1, x2, y1, z1, x1, y1, z1], b.td & 0xFFF, sd);
				quad(m, [x1, y2, z1, x1, y1, z1, x1, y1, z2, x1, y2, z2], b.tlr & 0xFFF, sx);
				quad(m, [x2, y2, z1, x1, y2, z1, x1, y2, z2, x2, y2, z2], b.td >> 12, sy);
			}
			return;
		}
		rb = red ? [x1, y1, x2, y2, z2] : null;
		var back = function() {
			quad(m, [x1, y2, z1, x2, y2, z1, x2, y1, z1, x1, y1, z1], td, sd, 1);
			quad(m, [x1, y2, z1, x1, y1, z1, x1, y1, z2, x1, y2, z2], tlr, sx, 2);
			quad(m, [x2, y2, z1, x1, y2, z1, x1, y2, z2, x2, y2, z2], tlr, sy, 5);
		};
		if( all && backFirst ) back();
		quad(m, [x1, y1, z2, x2, y1, z2, x2, y2, z2, x1, y2, z2], tu, su, 0);
		quad(m, [x2, y1, z1, x2, y2, z1, x2, y2, z2, x2, y1, z2], tlr, sx, 3);
		quad(m, [x1, y1, z1, x2, y1, z1, x2, y1, z2, x1, y1, z2], tlr, sy, 4);
		if( all && !backFirst ) back();
		rb = null;
	}

	static function model( m : MeshBuf, b : Block ) {
		var mk = b.model != null ? b.model : MCross;
		var md = Models.get(mk);
		var v = md.v;
		for( q in 0...Std.int(v.length / 24) ) {
			var sel = Std.int(v[q * 24 + 3]);
			var tile = !md.multi || sel == 0 ? b.tlr : (sel == 1 ? b.tu : b.td);
			if( tile < 0 || tile >= 0xFFF ) continue;
			var tx = tile & 63, ty = tile >> 6;
			var base = m.pts.length;
			for( k in 0...4 ) {
				var o = q * 24 + k * 6;
				var u = v[o + 3];
				var s = v[o + 5];
				m.pts.push(new h3d.col.Point(v[o], v[o + 1], v[o + 2]));
				m.uvs.push(new h3d.prim.UV(tx / 64 + (1 - TE) / 128 + (u - Std.int(u)), ty / 64 + (1 - TE) / 128 + v[o + 4]));
				m.cols.push(new h3d.col.Point(s, s, s));
			}
			m.idx.push(base); m.idx.push(base + 1); m.idx.push(base + 2);
			m.idx.push(base + 2); m.idx.push(base + 1); m.idx.push(base + 3);
		}
	}

	/** cubo unidad con una casilla del atlas en todas las caras (efecto de "no se puede romper") */
	public static function cube( tile : Int ) : h3d.prim.Polygon {
		var m = new MeshBuf();
		quad(m, [0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1], tile, 1);
		quad(m, [0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0], tile, 1);
		quad(m, [0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1], tile, 1);
		quad(m, [1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1], tile, 1);
		quad(m, [0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1], tile, 1);
		quad(m, [1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 1], tile, 1);
		var poly = new h3d.prim.Polygon(m.pts, m.idx);
		poly.addNormals(); // DirectX exige la entrada 'normal' del shader aunque no se use (OpenGL la descarta)
		poly.uvs = m.uvs;
		poly.colors = m.cols;
		return poly;
	}

	/**
	 * Malla de un bloque en la celda (0..1). all=true dibuja todas las caras (objetos sueltos);
	 * scale/centro: se reduce alrededor del centro de la celda.
	 */
	public static function polygon( b : Block, all : Bool, scale = 1.0, backFaces = false ) : h3d.prim.Polygon {
		backFirst = backFaces;
		var m = new MeshBuf();
		switch( b.type ) {
		case BTModel, BTModel2Side, BTSprite:
			model(m, b);
		case BTReduced:
			var s = b.size;
			if( s == null ) box(m, b, 0, 0, 0, 1, 1, 1, all) else box(m, b, s.x1, s.y1, s.z1, s.x2, s.y2, s.z2, all, true);
		case BTInvisible:
			return null;
		default:
			box(m, b, 0, 0, 0, 1, 1, 1, all);
		}
		backFirst = false;
		if( m.pts.length == 0 ) return null;
		if( scale != 1.0 )
			for( p in m.pts ) {
				p.x = 0.5 + (p.x - 0.5) * scale;
				p.y = 0.5 + (p.y - 0.5) * scale;
				p.z = 0.5 + (p.z - 0.5) * scale;
			}
		var poly = new h3d.prim.Polygon(m.pts, m.idx);
		poly.addNormals(); // DirectX exige la entrada 'normal' del shader aunque no se use (OpenGL la descarta)
		poly.uvs = m.uvs;
		poly.colors = m.cols;
		return poly;
	}
}

/** Iconos 3D de los bloques para el inventario (Render.renderBlock del original: vista isometrica). */
class Icons {

	static var cache = new Map<Int, h2d.Tile>();
	static var hiresCache = new Map<Int, h2d.Tile>();
	static var scene : h3d.scene.Scene;
	public static inline var SIZE = 90;
	/** iconos grandes (Base de datos ESCorp): 256 px con mipmaps, para dibujarlos lisos a cualquier tamano */
	public static inline var HIRES = 256;

	public static function get( b : Block, atlas : h3d.mat.Texture ) : h2d.Tile {
		var t = cache.get(b.index);
		if( t != null ) return t;
		t = h2d.Tile.fromTexture(render(b, atlas, SIZE));
		cache.set(b.index, t);
		return t;
	}

	/**
	 * Icono de HIRES px con mipmaps (anadido del port, Base de datos ESCorp). Dibujado con smooth = true se reduce o se agranda
	 * sin los pixeles desiguales de get() (90 px estirados con el filtro nearest de h2d).
	 */
	public static function hires( b : Block, atlas : h3d.mat.Texture ) : h2d.Tile {
		var t = hiresCache.get(b.index);
		if( t != null ) return t;
		var src = render(b, atlas, HIRES);
		var px = src.capturePixels();
		src.dispose();
		var tex = new h3d.mat.Texture(HIRES, HIRES, [MipMapped]);
		tex.uploadPixels(px);
		px.dispose();
		tex.filter = Linear;
		tex.mipMap = Linear;
		t = h2d.Tile.fromTexture(tex);
		hiresCache.set(b.index, t);
		return t;
	}

	static function render( b : Block, atlas : h3d.mat.Texture, size : Int ) : h3d.mat.Texture {
		// iconos grandes (Base de datos ESCorp) de bloques translucidos: alfa bien acumulado y sin el contorno por dentro (ver abajo)
		var translucent = size != SIZE && (b.type == BTAlpha || b.type == BTWater);
		// los bloques translucidos dibujan sus 6 caras: se ve a traves el cubo entero (en los grandes, las de atras primero)
		var poly = IconMesh.polygon(b, b.type == BTAlpha, 1.0, translucent);
		// IconShader del original: tshade = shade < 1 ? shade * shade : shade (las caras de los lados, mas oscuras que en el mundo)
		if( poly != null )
			for( c in poly.colors )
				if( c.x < 1 ) {
					c.x *= c.x;
					c.y *= c.y;
					c.z *= c.z;
				}
		var tex = new h3d.mat.Texture(size, size, [Target]);
		tex.filter = Linear;
		if( poly != null ) {
			var engine = h3d.Engine.getCurrent();
			if( scene == null ) scene = new h3d.scene.Scene();
			var mat = h3d.mat.Material.create(atlas);
			mat.shadows = false;
			mat.mainPass.enableLights = false;
			mat.mainPass.culling = None;
			mat.mainPass.addShader(new h3d.shader.VertexColor());
			if( b.type == BTAlpha || b.type == BTWater ) {
				// cristal, hielo, agua: se ven translucidos, no solo sus marcos (el original los dibuja con alfa)
				mat.blendMode = Alpha;
				if( translucent ) {
					// el blend Alpha de Heaps usa SrcAlpha tambien para el alfa: sobre el fondo vacio queda a * a (casi invisible) y
					// el color premultiplicado (oscuro). Aqui el alfa se suma como debe (One, OneMinusSrcAlpha) y el color se
					// despremultiplica al leerlo; sin escribir profundidad y con las caras de atras dibujadas antes que las de delante
					mat.mainPass.blendAlphaSrc = One;
					mat.mainPass.blendAlphaDst = OneMinusSrcAlpha;
					mat.mainPass.depthWrite = false;
				}
			} else {
				mat.textureShader.killAlpha = true;
				mat.textureShader.killAlphaThreshold = 0.5;
			}
			var mesh = new h3d.scene.Mesh(poly, mat, scene);
			var cam = scene.camera;
			// vista isometrica aproximada: perspectiva con angulo muy estrecho, desde +x, -y y arriba
			cam.orthoBounds = null;
			cam.fovY = 18;
			cam.screenRatio = 1;
			cam.zNear = 0.5;
			cam.zFar = 30;
			cam.target.set(0.5, 0.5, 0.5);
			cam.pos.set(0.5 + 4.1, 0.5 - 4.1, 0.5 + 3.4);
			cam.up.set(0, 0, 1);
			engine.pushTarget(tex);
			engine.clear(0x00000000, 1, 0);
			scene.render(engine);
			engine.popTarget();
			// Render.renderBlock: contorno negro, GlowFilter(0x0, 1, 2, 2, 1) sobre el icono de 45 px; aqui es de 90 px:
			// 5 en lugar de 4 porque la caja del shim solo esta centrada con un tamano impar (a otro tamano, lo mismo en proporcion)
			var blur = size == SIZE ? 5 : (Std.int(5 * size / SIZE) | 1);
			var px = tex.capturePixels();
			px.convert(BGRA);
			var bd = new flash.display.BitmapData(size, size, true, 0);
			for( k in 0...size * size ) bd.px[k] = px.bytes.getInt32(k * 4);
			if( translucent ) for( k in 0...size * size ) bd.px[k] = unpremultiply(bd.px[k]);
			var shape = translucent ? bd.px.copy() : null;
			bd.applyFilter(bd, bd.rect, new flash.geom.Point(0, 0), new flash.filters.GlowFilter(0x0, 1, blur, blur, 1));
			// el contorno negro va alrededor, no detras de las caras translucidas (las oscurecia): donde hay bloque queda el bloque
			if( translucent ) for( k in 0...size * size ) if( (shape[k] >>> 24) > 0 ) bd.px[k] = shape[k];
			for( k in 0...size * size ) px.bytes.setInt32(k * 4, bd.px[k]);
			tex.uploadPixels(px);
			px.dispose();
			if( Sys.args().indexOf("--dumpicons") >= 0 )
				sys.io.File.saveBytes("port/out/icon_" + b.k + (size == SIZE ? "" : "_" + size) + ".png", tex.capturePixels().toPNG());
			mesh.remove();
			poly.dispose();
		}
		return tex;
	}

	/** ARGB con el color premultiplicado por el alfa -> color normal */
	static function unpremultiply( c : Int ) : Int {
		var a = (c >>> 24) & 0xFF;
		if( a == 0 || a == 0xFF ) return c;
		inline function ch( v : Int ) return Std.int(Math.min(255, v * 255 / a));
		return (a << 24) | (ch((c >> 16) & 0xFF) << 16) | (ch((c >> 8) & 0xFF) << 8) | ch(c & 0xFF);
	}
}
