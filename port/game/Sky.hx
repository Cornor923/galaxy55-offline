import Common;

/**
	Niebla como en el original: los bloques lejanos se mezclan con el color del cielo, que es un
	degradado vertical de 3 colores por bioma (Data.getBiome(...).fog). El color del cielo depende
	de la elevacion del rayo de vista, asi la niebla del horizonte coincide con el fondo.
**/
class FogShader extends hxsl.Shader {
	static var SRC = {
		@global var camera : {
			var position : Vec3;
				var viewProj : Mat4;
		};
		var transformedPosition : Vec3;
		var projectedPosition : Vec4;
		var pixelColor : Vec4;
		@param var c0 : Vec3;
		@param var c1 : Vec3;
		@param var c2 : Vec3;
		@param var fogK : Float;
			@param var curve : Float;

			// el planeta es redondo: como en el original (Shaders.hx: fpos.z -= (dx*dx + dy*dy) * cam.w) cada vertice baja
			// con el cuadrado de su distancia horizontal a la camara; curve = 2 / tamano del planeta
			function vertex() {
				var d = transformedPosition.xy - camera.position.xy;
				projectedPosition = vec4(transformedPosition.x, transformedPosition.y, transformedPosition.z - dot(d, d) * curve, 1.0) * camera.viewProj;
			}

		function skyAt( e : Float ) : Vec3 {
			var h = clamp(0.65 - 0.5 * e, 0.0, 1.0);
			var t = clamp(h * 3.0 - 0.5, 0.0, 2.0);
			var a = clamp(t, 0.0, 1.0);
			var b = clamp(t - 1.0, 0.0, 1.0);
			return mix(mix(c0, c1, a), c2, b);
		}

		function fragment() {
			var d = normalize(transformedPosition - camera.position);
			var e = asin(clamp(d.z, -1.0, 1.0));
			var f = clamp(1.0 - (projectedPosition.w - 10.0) * fogK, 0.0, 1.0);
			pixelColor.rgb = mix(skyAt(e), pixelColor.rgb, f);
		}
	};
}

/** Cielo de un planeta: degradado, estrellas y parametros de niebla. */
class Sky {

	public var fog(default, null) : FogShader;
	public var root(default, null) : h3d.scene.Object;
	var cols : Array<Int>;
	var stars : h3d.scene.Mesh;
	var dome : h3d.scene.Mesh;
	var starAlpha : Float;

	/** menuFog: niebla suave para el fondo del menu (se ve mas planeta). */
	public function new( parent : h3d.scene.Object, biome : BiomeKind, menuFog : Bool ) {
		var bd = Data.getBiome(biome);
		cols = bd.fog.copy();
		while( cols.length < 3 ) cols.push(cols[cols.length - 1]);
		root = new h3d.scene.Object(parent);

		fog = new FogShader();
		fog.c0 = rgb(cols[0]);
		fog.c1 = rgb(cols[1]);
		fog.c2 = rgb(cols[2]);
		var k = 0.01 * bd.fogPower;
		// niebla mas suave en el menu para dejar ver el relieve lejano
		fog.fogK = menuFog ? Math.min(k, 0.0065) : k;
		// como el original: con niebla muy densa las estrellas se desvanecen
		starAlpha = Math.max(0, 1 - Math.pow(bd.fogPower - 1, 2) / 10);

		buildDome();
		buildStars();
	}

	/** Mueve el cielo con la camara. */
	public function follow( x : Float, y : Float, z : Float ) {
		root.setPosition(x, y, z);
	}

	public function setVisible( v : Bool ) {
		root.visible = v;
	}

	public function dispose() {
		dome.primitive.dispose();
		if( stars != null ) stars.primitive.dispose();
		root.remove();
	}

	// ---------------------------------------------------------------- colores

	static function rgb( c : Int ) : h3d.Vector {
		return new h3d.Vector(((c >> 16) & 0xFF) / 255, ((c >> 8) & 0xFF) / 255, (c & 0xFF) / 255);
	}

	/** Mismo degradado que el shader: color del cielo para una elevacion e (radianes). */
	function skyAt( e : Float ) : h3d.col.Point {
		var h = Math.max(0, Math.min(1, 0.65 - 0.5 * e));
		var t = Math.max(0, Math.min(2, h * 3 - 0.5));
		var a = Math.min(1, t), b = Math.max(0, t - 1);
		var c0 = rgb(cols[0]), c1 = rgb(cols[1]), c2 = rgb(cols[2]);
		var r = ((c0.x + (c1.x - c0.x) * a) * (1 - b)) + c2.x * b;
		var g = ((c0.y + (c1.y - c0.y) * a) * (1 - b)) + c2.y * b;
		var bl = ((c0.z + (c1.z - c0.z) * a) * (1 - b)) + c2.z * b;
		return new h3d.col.Point(r, g, bl);
	}

	// ---------------------------------------------------------------- geometria

	function buildDome() {
		var R = 700.;
		var seg = 40;
		var pts = new Array<h3d.col.Point>();
		var cl = new Array<h3d.col.Point>();
		var idx = new hxd.IndexBuffer();
		// anillos mas densos donde cambia el color (alrededor del horizonte)
		var elev = [-1.57];
		var e = -1.2;
		while( e < 1.2 ) {
			elev.push(e);
			e += 0.07;
		}
		elev.push(1.57);
		for( ring in 0...elev.length ) {
			var el = elev[ring];
			var c = skyAt(el);
			for( s in 0...seg ) {
				var a = s / seg * Math.PI * 2;
				pts.push(new h3d.col.Point(Math.cos(a) * Math.cos(el) * R, Math.sin(a) * Math.cos(el) * R, Math.sin(el) * R));
				cl.push(c);
			}
		}
		for( ring in 0...elev.length - 1 )
			for( s in 0...seg ) {
				var a = ring * seg + s, b = ring * seg + (s + 1) % seg;
				var c = (ring + 1) * seg + s, d = (ring + 1) * seg + (s + 1) % seg;
				idx.push(a); idx.push(b); idx.push(c);
				idx.push(b); idx.push(d); idx.push(c);
			}
		var poly = new h3d.prim.Polygon(pts, idx);
		poly.colors = cl;
		var mat = h3d.mat.Material.create();
		mat.shadows = false;
		mat.mainPass.enableLights = false;
		mat.mainPass.culling = None;
		mat.mainPass.depthWrite = false;
		mat.mainPass.addShader(new h3d.shader.VertexColor());
		dome = new h3d.scene.Mesh(poly, mat, root);
	}

	function buildStars() {
		if( starAlpha <= 0.02 ) return;
		var R = 650.;
		var n = 1800;
		var pts = new Array<h3d.col.Point>();
		var cl = new Array<h3d.col.Point>();
		var idx = new hxd.IndexBuffer();
		var rnd = new hxd.Rand(55);
		for( i in 0...n ) {
			// direccion uniforme sobre la esfera
			var z = rnd.srand();
			var a = rnd.rand() * Math.PI * 2;
			var r = Math.sqrt(1 - z * z);
			var dx = Math.cos(a) * r, dy = Math.sin(a) * r, dz = z;
			// base ortonormal tangente
			var ux = -dy, uy = dx, uz = 0.;
			var ul = Math.sqrt(ux * ux + uy * uy);
			if( ul < 1e-4 ) { ux = 1; uy = 0; ul = 1; }
			ux /= ul; uy /= ul;
			var vx = dy * uz - dz * uy, vy = dz * ux - dx * uz, vz = dx * uy - dy * ux;
			var s = 0.9 + rnd.rand() * 0.9;
			var b = pts.length;
			var cx = dx * R, cy = dy * R, cz = dz * R;
			pts.push(new h3d.col.Point(cx - ux * s - vx * s, cy - uy * s - vy * s, cz - uz * s - vz * s));
			pts.push(new h3d.col.Point(cx + ux * s - vx * s, cy + uy * s - vy * s, cz + uz * s - vz * s));
			pts.push(new h3d.col.Point(cx + ux * s + vx * s, cy + uy * s + vy * s, cz + uz * s + vz * s));
			pts.push(new h3d.col.Point(cx - ux * s + vx * s, cy - uy * s + vy * s, cz - uz * s + vz * s));
			var k = starAlpha * (0.55 + rnd.rand() * 0.45);
			for( j in 0...4 ) cl.push(new h3d.col.Point(k, k, k));
			idx.push(b); idx.push(b + 1); idx.push(b + 2);
			idx.push(b); idx.push(b + 2); idx.push(b + 3);
		}
		var poly = new h3d.prim.Polygon(pts, idx);
		poly.colors = cl;
		var mat = h3d.mat.Material.create();
		mat.shadows = false;
		mat.mainPass.enableLights = false;
		mat.mainPass.culling = None;
		mat.mainPass.depthWrite = false;
		// las estrellas se suman al cielo
		mat.blendMode = Add;
		mat.mainPass.addShader(new h3d.shader.VertexColor());
		stars = new h3d.scene.Mesh(poly, mat, root);
	}
}
