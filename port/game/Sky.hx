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

	var liquidCol : Null<Int> = null;
	var dryK = 0.;

	/** como Game.getEffects del original: con la camara dentro de un liquido con BFColor, la niebla toma su color y se espesa (col null = fuera) */
	public function setLiquid( col : Null<Int>, power : Float ) {
		if( col == null ) {
			if( liquidCol != null ) {
				fog.c0 = rgb(cols[0]);
				fog.c1 = rgb(cols[1]);
				fog.c2 = rgb(cols[2]);
				fog.fogK = dryK;
				liquidCol = null;
			}
			return;
		}
		if( liquidCol == null ) dryK = fog.fogK;
		liquidCol = col;
		fog.c0 = rgb(col);
		fog.c1 = rgb(col);
		fog.c2 = rgb(col);
		fog.fogK = 0.01 * power;
	}

	public function setVisible( v : Bool ) {
		root.visible = v;
	}

	// ---------------------------------------------------------------- espacio (nave nodriza, anadido del port)

	var space : h3d.scene.Object;
	var shooting : Array<{ m : h3d.scene.Mesh, t : Float, life : Float, dx : Float, dy : Float, dz : Float }>;
	var nextShoot = 2.;

	/** cielo de espacio abierto: nebulosas de colores, galaxias que giran despacio, estrellas de colores y estrellas fugaces */
	public function makeSpace() {
		fog.fogK = 0.0025;
		space = new h3d.scene.Object(root);
		var rnd = new hxd.Rand(5555);
		var cols = [0x6A3FD0, 0xD04F9A, 0x2F8FD8, 0x38C0A8, 0xE07A3A];
		// nebulosas: manchas grandes y suaves
		var neb = nebulaTex(256, rnd);
		for( i in 0...7 ) billboard(space, neb, dirRand(rnd), 220 + rnd.rand() * 200, cols[i % cols.length], 0.55, rnd.rand() * 6.28);
		// galaxias espirales
		var gal = galaxyTex(256, rnd);
		for( i in 0...5 ) billboard(space, gal, dirRand(rnd), 60 + rnd.rand() * 70, cols[(i + 2) % cols.length] | 0x303030, 0.9, rnd.rand() * 6.28);
		// estrellas de colores (las blancas ya estan en buildStars)
		if( stars != null ) {
			var poly = Std.downcast(stars.primitive, h3d.prim.Polygon);
			if( poly != null ) {
				for( i in 0...poly.colors.length >> 2 ) {
					var c = rnd.random(5) == 0 ? rgb(cols[rnd.random(cols.length)]) : null;
					if( c == null ) continue;
					for( j in 0...4 ) {
						var p = poly.colors[i * 4 + j];
						p.set(p.x * (0.5 + c.x), p.y * (0.5 + c.y), p.z * (0.5 + c.z));
					}
				}
				poly.dispose();
			}
		}
		shooting = [];
	}

	static function dirRand( rnd : hxd.Rand ) {
		var z = rnd.srand() * 0.9;
		var a = rnd.rand() * Math.PI * 2;
		var r = Math.sqrt(1 - z * z);
		return new h3d.col.Point(Math.cos(a) * r, Math.sin(a) * r, z);
	}

	function billboard( parent : h3d.scene.Object, tex : h3d.mat.Texture, d : h3d.col.Point, size : Float, color : Int, alpha : Float, rot : Float ) {
		var R = 600.;
		var ux = -d.y, uy = d.x, uz = 0.;
		var ul = Math.sqrt(ux * ux + uy * uy);
		if( ul < 1e-4 ) { ux = 1; uy = 0; ul = 1; }
		ux /= ul; uy /= ul;
		var vx = d.y * uz - d.z * uy, vy = d.z * ux - d.x * uz, vz = d.x * uy - d.y * ux;
		var c = Math.cos(rot), s = Math.sin(rot);
		var ax = ux * c + vx * s, ay = uy * c + vy * s, az = uz * c + vz * s;
		var bx = vx * c - ux * s, by = vy * c - uy * s, bz = vz * c - uz * s;
		var h = size * 0.5;
		var cx = d.x * R, cy = d.y * R, cz = d.z * R;
		var pts = [
			new h3d.col.Point(cx - ax * h - bx * h, cy - ay * h - by * h, cz - az * h - bz * h),
			new h3d.col.Point(cx + ax * h - bx * h, cy + ay * h - by * h, cz + az * h - bz * h),
			new h3d.col.Point(cx + ax * h + bx * h, cy + ay * h + by * h, cz + az * h + bz * h),
			new h3d.col.Point(cx - ax * h + bx * h, cy - ay * h + by * h, cz - az * h + bz * h),
		];
		var idx = new hxd.IndexBuffer();
		for( i in [0, 1, 2, 0, 2, 3] ) idx.push(i);
		var poly = new h3d.prim.Polygon(pts, idx);
		poly.addNormals(); // DirectX exige la entrada 'normal' del shader aunque no se use (OpenGL la descarta)
		poly.uvs = [new h3d.prim.UV(0, 0), new h3d.prim.UV(1, 0), new h3d.prim.UV(1, 1), new h3d.prim.UV(0, 1)];
		var mat = h3d.mat.Material.create(tex);
		mat.shadows = false;
		mat.mainPass.enableLights = false;
		mat.mainPass.culling = None;
		mat.mainPass.depthWrite = false;
		mat.blendMode = Add;
		var col = rgb(color);
		mat.color.set(col.x * alpha, col.y * alpha, col.z * alpha, 1);
		return new h3d.scene.Mesh(poly, mat, parent);
	}

	/** mancha de nebulosa: varias gotas suaves superpuestas */
	static function nebulaTex( n : Int, rnd : hxd.Rand ) {
		var acc = new haxe.ds.Vector<Float>(n * n);
		for( i in 0...n * n ) acc[i] = 0;
		for( k in 0...26 ) {
			var cx = n * (0.3 + rnd.rand() * 0.4), cy = n * (0.3 + rnd.rand() * 0.4), r = n * (0.08 + rnd.rand() * 0.2);
			for( y in 0...n ) for( x in 0...n ) {
				var dx = (x - cx) / r, dy = (y - cy) / r;
				var d = dx * dx + dy * dy;
				if( d < 1 ) acc[x + y * n] += (1 - d) * (1 - d) * 0.25;
			}
		}
		return toTex(acc, n);
	}

	/** galaxia espiral: brazos de puntos y un nucleo brillante */
	static function galaxyTex( n : Int, rnd : hxd.Rand ) {
		var acc = new haxe.ds.Vector<Float>(n * n);
		for( i in 0...n * n ) acc[i] = 0;
		var c = n * 0.5;
		for( k in 0...9000 ) {
			var arm = rnd.random(2) * Math.PI;
			var t = Math.pow(rnd.rand(), 0.7);
			var a = arm + t * 7 + rnd.srand() * 0.35;
			var rr = t * n * 0.45;
			var x = Std.int(c + Math.cos(a) * rr), y = Std.int(c + Math.sin(a) * rr * 0.55);
			if( x >= 1 && y >= 1 && x < n - 1 && y < n - 1 ) {
				acc[x + y * n] += 0.18;
				acc[x + 1 + y * n] += 0.06;
				acc[x + (y + 1) * n] += 0.06;
			}
		}
		for( y in 0...n ) for( x in 0...n ) {
			var dx = (x - c) / (n * 0.12), dy = (y - c) / (n * 0.07);
			var d = dx * dx + dy * dy;
			if( d < 1 ) acc[x + y * n] += (1 - d) * 1.2;
		}
		return toTex(acc, n);
	}

	static function toTex( acc : haxe.ds.Vector<Float>, n : Int ) {
		var px = hxd.Pixels.alloc(n, n, BGRA);
		for( y in 0...n ) for( x in 0...n ) {
			// borde suave para que no se vea el cuadrado
			var ex = Math.min(x, n - 1 - x) / (n * 0.15), ey = Math.min(y, n - 1 - y) / (n * 0.15);
			var edge = Math.min(1, Math.min(ex, ey));
			var v = Math.min(1, acc[x + y * n]) * edge;
			var b = Std.int(v * 255);
			px.setPixel(x, y, 0xFF000000 | (b << 16) | (b << 8) | b);
		}
		px.convert(RGBA); // DirectX no acepta BGRA
		var t = h3d.mat.Texture.fromPixels(px);
		t.filter = Linear;
		return t;
	}

	/** gira el cielo de espacio muy despacio y lanza estrellas fugaces de vez en cuando */
	public function update( dt : Float ) {
		if( space == null ) return;
		space.rotate(0, 0, dt * 0.004);
		nextShoot -= dt;
		if( nextShoot <= 0 ) {
			nextShoot = 1.5 + Math.random() * 4;
			var d = dirRand(new hxd.Rand(Std.random(100000)));
			if( d.z < 0.05 ) d.z = Math.abs(d.z) + 0.15;
			var tex = h3d.mat.Texture.fromColor(0xFFFFFF);
			var len = 40.;
			var dir = new h3d.col.Point(Math.random() - 0.5, Math.random() - 0.5, -0.3);
			dir.normalize();
			var R = 560.;
			var p0 = new h3d.col.Point(d.x * R, d.y * R, d.z * R);
			var pts = [p0.clone(), p0.clone(), new h3d.col.Point(p0.x - dir.x * len, p0.y - dir.y * len, p0.z - dir.z * len + 1.2), new h3d.col.Point(p0.x - dir.x * len, p0.y - dir.y * len, p0.z - dir.z * len)];
			pts[1].z += 1.6;
			var idx = new hxd.IndexBuffer();
			for( i in [0, 1, 2, 0, 2, 3] ) idx.push(i);
			var poly = new h3d.prim.Polygon(pts, idx);
			poly.addNormals(); // DirectX exige la entrada 'normal' del shader aunque no se use (OpenGL la descarta)
			poly.colors = [new h3d.col.Point(1, 1, 1), new h3d.col.Point(1, 1, 1), new h3d.col.Point(0, 0, 0), new h3d.col.Point(0, 0, 0)];
			poly.uvs = [new h3d.prim.UV(0, 0), new h3d.prim.UV(1, 0), new h3d.prim.UV(1, 1), new h3d.prim.UV(0, 1)];
			var mat = h3d.mat.Material.create(tex);
			mat.shadows = false;
			mat.mainPass.enableLights = false;
			mat.mainPass.culling = None;
			mat.mainPass.depthWrite = false;
			mat.blendMode = Add;
			mat.mainPass.addShader(new h3d.shader.VertexColor());
			var m = new h3d.scene.Mesh(poly, mat, root);
			shooting.push({ m : m, t : 0., life : 0.9, dx : dir.x * 520, dy : dir.y * 520, dz : dir.z * 520 });
		}
		for( s in shooting.copy() ) {
			s.t += dt;
			s.m.x += s.dx * dt;
			s.m.y += s.dy * dt;
			s.m.z += s.dz * dt;
			s.m.material.color.a = 1 - s.t / s.life;
			s.m.material.color.set(1 - s.t / s.life, 1 - s.t / s.life, 1 - s.t / s.life, 1);
			if( s.t >= s.life ) {
				s.m.remove();
				s.m.primitive.dispose();
				shooting.remove(s);
			}
		}
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
		poly.addNormals(); // DirectX exige la entrada 'normal' del shader aunque no se use (OpenGL la descarta)
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
		poly.addNormals(); // DirectX exige la entrada 'normal' del shader aunque no se use (OpenGL la descarta)
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
