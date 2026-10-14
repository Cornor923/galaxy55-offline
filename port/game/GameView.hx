import SaveData.SaveInfo;

/** Una partida en curso: jugador en primera persona sobre un World. */
class GameView {

	static inline var EYE = 1.62;
	static inline var RADIUS = 0.3;
	static inline var BODY = 1.8;

	public var world(default, null) : World;
	public var info(default, null) : SaveInfo;
	public var px = 0.;
	public var py = 0.;
	public var pz = 0.;
	public var yaw = 0.;
	public var pitch = 0.;
	public var fly = false;
	public var playSeconds = 0.;

	var vz = 0.;
	var onGround = false;
	var s3d : h3d.scene.Scene;

	public function new( s3d : h3d.scene.Scene, world : World, info : SaveInfo ) {
		this.s3d = s3d;
		this.world = world;
		this.info = info;
		playSeconds = info.playSeconds;
		fly = info.fly;
		if( info.px < 0 ) {
			var s = world.spawnPoint();
			px = s.x;
			py = s.y;
			pz = s.z;
			yaw = Math.PI * 0.25;
			pitch = -0.25;
		} else {
			px = info.px;
			py = info.py;
			pz = info.pz;
			yaw = info.yaw;
			pitch = info.pitch;
		}
	}

	/** Estado actual para guardar. */
	public function toInfo() : SaveInfo {
		info.px = px;
		info.py = py;
		info.pz = pz;
		info.yaw = yaw;
		info.pitch = pitch;
		info.fly = fly;
		info.playSeconds = playSeconds;
		return info;
	}

	public function look( dx : Float, dy : Float ) {
		var k = 0.0025 * Settings.mouseSens;
		yaw += dx * k;
		pitch -= dy * k * (Settings.invertY ? -1 : 1);
		clampPitch();
	}

	inline function clampPitch() {
		if( pitch > 1.5 ) pitch = 1.5;
		if( pitch < -1.5 ) pitch = -1.5;
	}

	function collides( x : Float, y : Float, z : Float ) : Bool {
		var x0 = Math.floor(x - RADIUS), x1 = Math.floor(x + RADIUS);
		var y0 = Math.floor(y - RADIUS), y1 = Math.floor(y + RADIUS);
		var z0 = Math.floor(z), z1 = Math.floor(z + BODY);
		for( ix in x0...x1 + 1 )
			for( iy in y0...y1 + 1 )
				for( iz in z0...z1 + 1 )
					if( world.solid(ix, iy, iz) ) return true;
		return false;
	}

	/** mueve en un eje con colision; devuelve true si choco */
	function moveAxis( dx : Float, dy : Float, dz : Float ) : Bool {
		if( dx == 0 && dy == 0 && dz == 0 ) return false;
		var steps = Std.int(Math.max(1, Math.ceil(Math.max(Math.abs(dx), Math.max(Math.abs(dy), Math.abs(dz))) / 0.25)));
		var sx = dx / steps, sy = dy / steps, sz = dz / steps;
		for( i in 0...steps ) {
			var nx = px + sx, ny = py + sy, nz = pz + sz;
			if( collides(nx, ny, nz) ) return true;
			px = nx;
			py = ny;
			pz = nz;
		}
		return false;
	}

	inline function clampPos( v : Float ) : Float {
		var s = world.size;
		return v < RADIUS ? RADIUS : (v > s - RADIUS ? s - RADIUS : v);
	}

	public function update( dt : Float, controls : Bool, pad : hxd.Pad ) {
		if( dt > 0.05 ) dt = 0.05;
		playSeconds += dt;
		var K = hxd.Key;
		var fwd = 0., side = 0.;
		var run = false, jump = false, down = false;
		if( controls ) {
			if( K.isPressed(K.F) || (pad != null && pad.isPressed(pad.config.Y)) ) {
				fly = !fly;
				vz = 0;
			}
			if( K.isDown(K.W) || K.isDown(K.UP) ) fwd += 1;
			if( K.isDown(K.S) || K.isDown(K.DOWN) ) fwd -= 1;
			if( K.isDown(K.D) ) side += 1;
			if( K.isDown(K.A) ) side -= 1;
			run = K.isDown(K.SHIFT) || K.isDown(K.CTRL);
			jump = K.isDown(K.SPACE);
			down = K.isDown(K.SHIFT);
			if( pad != null ) {
				var dead = 0.2;
				if( Math.abs(pad.xAxis) > dead ) side += pad.xAxis;
				if( Math.abs(pad.yAxis) > dead ) fwd -= pad.yAxis;
				if( Math.abs(pad.rxAxis) > dead ) yaw += pad.rxAxis * 2.5 * Settings.mouseSens * dt;
				if( Math.abs(pad.ryAxis) > dead ) pitch -= pad.ryAxis * 2.0 * Settings.mouseSens * dt * (Settings.invertY ? -1 : 1);
				if( pad.isDown(pad.config.A) ) jump = true;
				if( pad.isDown(pad.config.LB) ) down = true;
				if( pad.isDown(pad.config.RB) ) jump = true;
				if( pad.isDown(pad.config.analogClick) ) run = true;
			}
			clampPitch();
		}

		var cy = Math.cos(yaw), sy = Math.sin(yaw);
		if( fly ) {
			var speed = run ? 36 : 14;
			var cp = Math.cos(pitch), sp = Math.sin(pitch);
			moveAxis((cy * cp * fwd - sy * side) * speed * dt, 0, 0);
			moveAxis(0, (sy * cp * fwd + cy * side) * speed * dt, 0);
			moveAxis(0, 0, (sp * fwd + (jump ? 1 : 0) - (down ? 1 : 0)) * speed * dt);
		} else {
			var speed = run ? 9 : 5.5;
			var len = Math.sqrt(fwd * fwd + side * side);
			if( len > 1 ) {
				fwd /= len;
				side /= len;
			}
			if( jump && onGround ) {
				vz = 8.5;
				onGround = false;
			}
			vz -= 28 * dt;
			if( vz < -60 ) vz = -60;
			moveAxis((cy * fwd - sy * side) * speed * dt, 0, 0);
			moveAxis(0, (sy * fwd + cy * side) * speed * dt, 0);
			var hitZ = moveAxis(0, 0, vz * dt);
			onGround = hitZ && vz < 0;
			if( hitZ ) vz = 0;
		}
		px = clampPos(px);
		py = clampPos(py);
	}

	public function updateCamera() {
		var cp = Math.cos(pitch);
		var c = s3d.camera;
		var ez = pz + EYE;
		c.fovY = Settings.fov;
		c.zNear = 0.1;
		c.zFar = 1500;
		c.pos.set(px, py, ez);
		c.target.set(px + Math.cos(yaw) * cp, py + Math.sin(yaw) * cp, ez + Math.sin(pitch));
		c.up.set(0, 0, 1);
		world.sky.follow(px, py, ez);
	}
}
