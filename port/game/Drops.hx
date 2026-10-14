import Common;

class Drop {
	public var x : Float;
	public var y : Float;
	public var z : Float;
	public var vx : Float;
	public var vy : Float;
	public var vz = 0.;
	/** cantidad (una pila entera al tirarla con R) */
	public var n = 1;
	public var block : Block;
	/** vida restante en unidades de 30 tmod (Dummy.time: 180 al soltarlo) */
	public var time = 180.;
	public var active = true;
	public var light = 0.;
	public var obj : h3d.scene.Object;
	public var mat : h3d.mat.Material;

	public function new( x : Float, y : Float, z : Float, b : Block ) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.block = b;
		vx = (Std.random(2) * 2 - 1) * Math.random() * 0.04;
		vy = (Std.random(2) * 2 - 1) * Math.random() * 0.04;
	}
}

/**
 * Bloques sueltos al romper (ent/Dummy.hx del original): caen con la misma fisica, se acercan al jugador
 * cuando esta a menos de 1.5 bloques y se recogen a menos de 0.4 si cabe en el inventario.
 */
class Drops {

	var list = new Array<Drop>();
	var world : World;
	var atlas : h3d.mat.Texture;

	public function new( world : World, atlas : h3d.mat.Texture ) {
		this.world = world;
		this.atlas = atlas;
	}

	public function add( x : Float, y : Float, z : Float, b : Block ) : Drop {
		var d = new Drop(x, y, z, b);
		var poly = IconMesh.polygon(b, true, b.type == BTFull || b.type == BTReduced || b.type == BTExtended ? 0.38 : 0.6);
		if( poly != null ) {
			var mat = h3d.mat.Material.create(atlas);
			mat.shadows = false;
			mat.mainPass.enableLights = false;
			mat.mainPass.culling = None;
			mat.mainPass.addShader(new h3d.shader.VertexColor());
			mat.mainPass.addShader(world.sky.fog);
			mat.textureShader.killAlpha = true;
			mat.textureShader.killAlphaThreshold = 0.5;
			d.mat = mat;
			d.obj = new h3d.scene.Object(world.root);
			var m = new h3d.scene.Mesh(poly, mat, d.obj);
			m.setPosition(-0.5, -0.5, -0.5);
		}
		d.light = world.lightAt(Std.int(x), Std.int(y), Std.int(z)) / World.LBASE;
		list.push(d);
		return d;
	}

	public function count() return list.length;

	inline function collide( x : Float, y : Float, z : Float ) return world.collidePoint(x, y, z);

	inline function dist( a : Float, ref : Float ) : Float {
		var s = world.size;
		var d = (a - ref) % s;
		if( d < 0 ) d += s;
		if( d > s * 0.5 ) d -= s;
		return d;
	}

	public function update( g : GameView, tmod : Float ) {
		var dt = tmod;
		var i = 0;
		while( i < list.length ) {
			var d = list[i];
			d.time -= dt / 30;
			// fisica (Dummy.updatePos)
			if( !collide(d.x, d.y, d.z - 0.01) )
				d.vz -= 0.01 * dt;
			else {
				d.active = true;
				if( d.vz < 0 ) d.vz *= Math.pow(0.3, dt);
				var r = 0;
				while( r < 20 && (collide(d.x, d.y, d.z - 0.01) || collide(d.x, d.y, d.z + 0.3)) ) {
					d.z += 0.01 * dt;
					r++;
				}
			}
			d.x += d.vx * dt;
			d.y += d.vy * dt;
			if( collide(d.x, d.y, d.z) ) {
				d.x -= d.vx * dt;
				d.y -= d.vy * dt;
				d.vx *= -0.6;
				d.vy *= -0.6;
			}
			d.z += d.vz * dt;
			var p = Math.pow(0.93, dt);
			d.vx *= p;
			d.vy *= p;
			d.vz *= p;
			if( d.x < 0 ) d.x += world.size else if( d.x >= world.size ) d.x -= world.size;
			if( d.y < 0 ) d.y += world.size else if( d.y >= world.size ) d.y -= world.size;

			// luz suavizada
			var tl = world.lightAt(Std.int(d.x), Std.int(d.y), Std.int(d.z)) / World.LBASE;
			d.light = d.light * 0.95 + tl * 0.05;

			// recogida (Dummy.update)
			var dx = dist(g.px, d.x), dy = dist(g.py, d.y);
			var h = GameView.VIEW_Z * 0.5;
			var dz = (g.pz + h) - d.z;
			if( Math.abs(dz) > h ) {
				if( dz < 0 ) dz += h else dz -= h;
			} else
				dz = 0;
			var dd = Math.sqrt(dx * dx + dy * dy + dz * dz);
			var picked = false;
			if( dd < 1.5 && d.active && g.inv.canAddBlock(d.block) ) {
				var s = 0.2 * dt / (dd * dd + 1e-6);
				d.x += dx * s;
				d.y += dy * s;
				d.z += dz * s;
				if( dd < 0.4 ) {
					if( d.n <= 1 ) picked = g.inv.addBlock(d.block) >= 0;
					else {
						var c = g.inv.addBlocks(d.block, d.n);
						d.n -= c;
						picked = d.n <= 0;
					}
				}
			}
			if( picked || d.time <= 0 ) {
				if( d.obj != null ) {
					for( c in d.obj.getMeshes() ) c.primitive.dispose();
					d.obj.remove();
				}
				list.splice(i, 1);
				continue;
			}
			if( d.obj != null ) {
				var s = world.size;
				d.obj.setPosition(d.x + s * Math.round((g.px - d.x) / s), d.y + s * Math.round((g.py - d.y) / s), d.z + 0.2 + Math.sin(d.time * 7) * 0.04);
				d.obj.setRotation(0, 0, d.time * 6);
				var l = Math.min(1.3, d.light);
				d.mat.color.set(l, l, l, 1);
			}
			i++;
		}
	}

	public function dispose() {
		for( d in list )
			if( d.obj != null ) {
				for( c in d.obj.getMeshes() ) c.primitive.dispose();
				d.obj.remove();
			}
		list = [];
	}
}
