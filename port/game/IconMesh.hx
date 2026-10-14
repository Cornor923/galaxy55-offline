import Common;
import World.MeshBuf;

/**
 * Geometria suelta de un bloque (iconos del inventario y objetos que caen al romper).
 * Cada cara usa la textura del atlas y el sombreado fijo por cara del original (sqrt de shadeX/shadeY/shadeUp/shadeDown).
 */
class IconMesh {

	static inline var TE = 0.999;

	static function quad( m : MeshBuf, p : Array<Float>, tile : Int, shade : Float ) {
		if( tile < 0 || tile >= 0xFFF ) return;
		var tx = tile & 63, ty = tile >> 6;
		var u0 = tx / 64 + (1 - TE) / 128, v0 = ty / 64 + (1 - TE) / 128;
		var u1 = u0 + TE / 64, v1 = v0 + TE / 64;
		var b = m.pts.length;
		for( k in 0...4 ) m.pts.push(new h3d.col.Point(p[k * 3], p[k * 3 + 1], p[k * 3 + 2]));
		m.uvs.push(new h3d.prim.UV(u0, v1));
		m.uvs.push(new h3d.prim.UV(u1, v1));
		m.uvs.push(new h3d.prim.UV(u1, v0));
		m.uvs.push(new h3d.prim.UV(u0, v0));
		for( i in 0...4 ) m.cols.push(new h3d.col.Point(shade, shade, shade));
		m.idx.push(b); m.idx.push(b + 1); m.idx.push(b + 2);
		m.idx.push(b); m.idx.push(b + 2); m.idx.push(b + 3);
	}

	/** caja con una textura por cara; all=false solo dibuja las 3 caras que ve la camara isometrica (+x, -y, +z) */
	static function box( m : MeshBuf, b : Block, x1 : Float, y1 : Float, z1 : Float, x2 : Float, y2 : Float, z2 : Float, all : Bool ) {
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
		quad(m, [x1, y1, z2, x2, y1, z2, x2, y2, z2, x1, y2, z2], tu, su);
		quad(m, [x2, y1, z1, x2, y2, z1, x2, y2, z2, x2, y1, z2], tlr, sx);
		quad(m, [x1, y1, z1, x2, y1, z1, x2, y1, z2, x1, y1, z2], tlr, sy);
		if( all ) {
			quad(m, [x1, y2, z1, x2, y2, z1, x2, y1, z1, x1, y1, z1], td, sd);
			quad(m, [x1, y2, z1, x1, y1, z1, x1, y1, z2, x1, y2, z2], tlr, sx);
			quad(m, [x2, y2, z1, x1, y2, z1, x1, y2, z2, x2, y2, z2], tlr, sy);
		}
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
		poly.uvs = m.uvs;
		poly.colors = m.cols;
		return poly;
	}

	/**
	 * Malla de un bloque en la celda (0..1). all=true dibuja todas las caras (objetos sueltos);
	 * scale/centro: se reduce alrededor del centro de la celda.
	 */
	public static function polygon( b : Block, all : Bool, scale = 1.0 ) : h3d.prim.Polygon {
		var m = new MeshBuf();
		switch( b.type ) {
		case BTModel, BTModel2Side, BTSprite:
			model(m, b);
		case BTReduced:
			var s = b.size;
			if( s == null ) box(m, b, 0, 0, 0, 1, 1, 1, all) else box(m, b, s.x1, s.y1, s.z1, s.x2, s.y2, s.z2, all);
		case BTInvisible, BTWater:
			return null;
		default:
			box(m, b, 0, 0, 0, 1, 1, 1, all);
		}
		if( m.pts.length == 0 ) return null;
		if( scale != 1.0 )
			for( p in m.pts ) {
				p.x = 0.5 + (p.x - 0.5) * scale;
				p.y = 0.5 + (p.y - 0.5) * scale;
				p.z = 0.5 + (p.z - 0.5) * scale;
			}
		var poly = new h3d.prim.Polygon(m.pts, m.idx);
		poly.uvs = m.uvs;
		poly.colors = m.cols;
		return poly;
	}
}

/** Iconos 3D de los bloques para el inventario (Render.renderBlock del original: vista isometrica). */
class Icons {

	static var cache = new Map<Int, h2d.Tile>();
	static var scene : h3d.scene.Scene;
	public static inline var SIZE = 90;

	public static function get( b : Block, atlas : h3d.mat.Texture ) : h2d.Tile {
		var t = cache.get(b.index);
		if( t != null ) return t;
		var poly = IconMesh.polygon(b, false);
		var tex = new h3d.mat.Texture(SIZE, SIZE, [Target]);
		tex.filter = Linear;
		if( poly != null ) {
			var engine = h3d.Engine.getCurrent();
			if( scene == null ) scene = new h3d.scene.Scene();
			var mat = h3d.mat.Material.create(atlas);
			mat.shadows = false;
			mat.mainPass.enableLights = false;
			mat.mainPass.culling = None;
			mat.mainPass.addShader(new h3d.shader.VertexColor());
			mat.textureShader.killAlpha = true;
			mat.textureShader.killAlphaThreshold = 0.5;
			var mesh = new h3d.scene.Mesh(poly, mat, scene);
			var cam = scene.camera;
			cam.orthoBounds = h3d.col.Bounds.fromValues(-0.95, -0.95, 0.1, 0.95, 0.95, 20);
			cam.target.set(0.5, 0.5, 0.5);
			cam.pos.set(0.5 + 5, 0.5 - 5, 0.5 + 4.1);
			cam.up.set(0, 0, 1);
			engine.pushTarget(tex);
			engine.clear(0x00000000, 1, 0);
			scene.render(engine);
			engine.popTarget();
			mesh.remove();
			poly.dispose();
		}
		t = h2d.Tile.fromTexture(tex);
		cache.set(b.index, t);
		return t;
	}
}
