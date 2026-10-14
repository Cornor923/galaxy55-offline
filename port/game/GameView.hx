import Common;
import SaveData.SaveInfo;

/**
	Una partida en curso: el jugador en primera persona sobre un World.

	La fisica es una copia fiel de ent/Hero.hx y Game.moveHero del juego original: misma gravedad,
	salto, jetpack, sondas de colision de pies, cabeza y paredes, velocidades y unidad de tiempo
	(tmod: 1 unidad = 1/32 s). No hay boton de correr: en el original solo existe caminar despacio (X).
**/
class GameView {

	/** unidades de tiempo del juego (mt.Timer.wantedFPS) */
	static inline var FPS = 32.;
	/** altura de los ojos (Hero.viewZ) */
	public static inline var VIEW_Z = 1.5;

	public var world(default, null) : World;
	public var info(default, null) : SaveInfo;

	// posicion y vista (Hero.x/y/z, angle, angleZ)
	public var px = 0.;
	public var py = 0.;
	public var pz = 0.;
	public var yaw = 0.;
	public var pitch = 0.;
	public var playSeconds = 0.;

	// estado fisico (Hero)
	public var gravity = 0.;
	public var maxGravity = 0.9;
	/** combustible del jetpack, de 0 a 1 (Hero.jetpack) */
	public var jetpack = 0.;
	public var swimming = false;
	public var standingBlock : Block;
	/** true mientras el jetpack empuja (para el brillo del casco) */
	public var thrusting(default, null) = false;
	/** true si el raton gobierna la vista; si no, los cursores giran (Game.drag.active) */
	public var mouseLook = true;

	// vaiven del casco y de la camara (Game.walkBobbing, bobbingX, bobbingY)
	public var walking = false;
	public var walkBobbing = 0.;
	public var bobX = 0.;
	public var bobY = 0.;
	public var turnSpeed = 0.;

	var pushPower = 0.;
	var walkingSlow = false;
	var oldSpeedX = 0.;
	var oldSpeedY = 0.;
	var stun = 0.;

	public inline function onGround() return standingBlock != null;
	var s3d : h3d.scene.Scene;

	public function new( s3d : h3d.scene.Scene, world : World, info : SaveInfo ) {
		this.s3d = s3d;
		this.world = world;
		this.info = info;
		playSeconds = info.playSeconds;
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
		info.fly = false;
		info.playSeconds = playSeconds;
		return info;
	}

	/** Mirar con el raton: mismos divisores que Game (lookLock: 260 en horizontal, 360 en vertical). */
	public function look( dx : Float, dy : Float ) {
		yaw += dx * Settings.mouseSens / 260.0;
		pitch -= dy * Settings.mouseSens / 360.0 * (Settings.invertY ? -1 : 1);
		clampPitch();
	}

	inline function clampPitch() {
		var amax = Math.PI / 2.01;
		if( pitch < -amax ) pitch = -amax;
		else if( pitch > amax ) pitch = amax;
	}

	inline function collide( x : Float, y : Float, z : Float ) : Bool {
		return world.collidePoint(x, y, z);
	}

	inline function clampPos( v : Float ) : Float {
		var s = world.size;
		return v < 0.5 ? 0.5 : (v > s - 0.5 ? s - 0.5 : v);
	}

	inline function onWater() return inWater(0.01);

	function inWater( ?dz : Float ) : Bool {
		if( dz == null ) dz = VIEW_Z;
		var b = world.block(Math.floor(px), Math.floor(py), Std.int(pz + dz));
		return b != null && b.hasFlag(BFLiquid);
	}

	// ---------------------------------------------------------------- bucle de entrada (Game.moveHero)

	public function update( realDt : Float, controls : Bool, pad : hxd.Pad ) {
		if( realDt > 0.1 ) realDt = 0.1;
		playSeconds += realDt;
		var tmod = realDt * FPS;
		var K = hxd.Key;

		var speed = 0., strafe = 0.;
		var useJetpack = false;
		walkingSlow = false;
		walking = false;
		if( controls ) {
			// A/D y flechas izquierda/derecha: en el original giran al personaje, con aceleracion
			// (Settings.turnKeys); por defecto se desplazan de lado
			var move = false;
			var turnMode = Settings.turnKeys;
			if( K.isDown(K.RIGHT) || K.isDown(K.D) || K.isDown(K.NUMPAD_6) ) {
				if( turnSpeed < 0 ) turnSpeed = 0;
				if( turnMode ) turnSpeed += 0.008 * tmod;
				else strafe += 0.15;
				move = true;
			}
			if( K.isDown(K.LEFT) || K.isDown(K.A) || K.isDown(K.Q) || K.isDown(K.NUMPAD_4) ) {
				if( turnSpeed > 0 ) turnSpeed = 0;
				if( turnMode ) turnSpeed -= 0.008 * tmod;
				else strafe -= 0.15;
				move = true;
			}
			if( !move ) turnSpeed *= Math.pow(0.6, tmod);
			var tmax = 0.06;
			if( turnSpeed < -tmax ) turnSpeed = -tmax;
			if( turnSpeed > tmax ) turnSpeed = tmax;
			var turn = turnSpeed;

			walkingSlow = K.isDown(K.X);
			if( K.isDown(K.UP) || K.isDown(K.W) || K.isDown(K.Z) || K.isDown(K.X) || K.isDown(K.NUMPAD_8) ) {
				speed += 0.15;
				walking = true;
			} else pushPower = 0.0;
			if( K.isDown(K.DOWN) || K.isDown(K.S) || K.isDown(K.NUMPAD_2) ) {
				speed -= 0.15;
				walking = true;
			}

			// mando: palanca izquierda mueve, derecha mira, A salta/jetpack, B camina despacio
			if( pad != null ) {
				var dead = 0.2;
				var lx = pad.xAxis, ly = pad.yAxis;
				if( Math.abs(lx) > dead ) { strafe += 0.15 * lx; walking = true; }
				if( Math.abs(ly) > dead ) { speed += -0.15 * ly; walking = true; }
				walkingSlow = walkingSlow || pad.isDown(pad.config.B);
				if( pad.isDown(pad.config.A) ) useJetpack = true;
				var rx = pad.rxAxis, ry = pad.ryAxis;
				if( Math.abs(rx) > dead ) yaw += rx * 0.054 * Settings.mouseSens * tmod;
				if( Math.abs(ry) > dead ) pitch -= ry * 0.036 * Settings.mouseSens * tmod * (Settings.invertY ? -1 : 1);
			}

			if( speed != 0 && strafe != 0 ) {
				var diag = 1 / Math.sqrt(2);
				speed *= diag;
				strafe *= diag;
			}
			if( swimming || onWater() ) {
				speed *= 0.6;
				strafe *= 0.6;
				turn *= 0.6;
			} else if( walkingSlow ) {
				speed *= 0.4;
				strafe *= 0.4;
				turn *= 0.4;
			}
			if( K.isDown(K.SPACE) || K.isDown(K.CTRL) ) useJetpack = true;
			yaw += turn;
			clampPitch();
		} else
			turnSpeed = 0;

		if( debugJet ) useJetpack = true;
		stepPhysics(tmod, speed, strafe, useJetpack);
		updateBobbing(realDt * 60);
	}

	/** solo para pruebas automaticas: mantiene el jetpack pulsado */
	public var debugJet = false;

	/** Un fotograma de fisica con varios pasos pequenos, como el original (tmod: 1 = 1/32 s). */
	public function stepPhysics( tmod : Float, speed : Float, strafe : Float, useJetpack : Bool ) {
		var k = Math.ceil(tmod * 10);
		var dt = tmod / k;
		thrusting = false;
		for( i in 0...k ) doMove(dt, speed, strafe, useJetpack);
	}

	/** Game.updateInterface: el original lo ejecuta una vez por fotograma (60 por segundo). */
	function updateBobbing( frames : Float ) {
		if( walking && onGround() && !stunnedLock() )
			walkBobbing += (inWater() ? 0.05 : 0.2) * frames;
		else
			walkBobbing = 0;
		if( !onGround() ) bobY = -gravity * 30;
		bobX += -turnSpeed * 300 * frames;
		if( bobX < -20 ) bobX = -20;
		if( bobX > 20 ) bobX = 20;
		if( bobY < -15 ) bobY = -15;
		if( bobY > 15 ) bobY = 15;
		var decay = Math.pow(0.92, frames);
		bobX *= decay;
		bobY *= decay;
	}

	inline function stunnedLock() return false;

	// ---------------------------------------------------------------- fisica (Hero.doMove)

	function doMove( dt : Float, speed : Float, strafe : Float, useJetpack : Bool ) {
		if( stun > 0 ) stun -= dt;

		var waterBlock = world.block(Math.floor(px), Math.floor(py), Std.int(pz + 0.1));
		if( waterBlock != null && !waterBlock.hasFlag(BFLiquid) ) waterBlock = null;
		if( waterBlock != null && waterBlock.k == BMarsQuickSand ) {
			dt *= 0.3;
			speed *= 0.6;
			strafe *= 0.6;
		}

		swimming = inWater();

		pz -= gravity * dt;

		// angulo con el desplazamiento lateral
		var a = yaw;
		if( speed != 0 || strafe != 0 ) {
			var s = Math.sqrt(speed * speed + strafe * strafe);
			a += Math.atan2(strafe / s, speed / s);
			speed = s;
		}

		// puntos de los pies
		var fx = new Array<Float>(), fy = new Array<Float>();
		for( da in [0., Math.PI * 2 / 3, -Math.PI * 2 / 3] ) {
			fx.push(px + Math.cos(a + da) * 0.1);
			fy.push(py + Math.sin(a + da) * 0.1);
		}

		// colision de pies
		var col = false;
		for( i in 0...3 )
			if( collide(fx[i], fy[i], pz - 0.01) ) {
				col = true;
				break;
			}

		// colision de cabeza
		if( gravity < 0 && !col ) {
			var d = VIEW_Z + 0.13;
			var recal = 0.;
			for( i in 0...3 )
				while( recal < 0.5 && collide(fx[i], fy[i], pz + d) ) {
					pz -= 0.01;
					recal += 0.01;
				}
			if( recal > 0 && recal < 0.5 ) gravity = 0;
		}

		if( useJetpack && swimming ) {
			if( gravity > -0.1 ) gravity -= 0.03 * dt;
			useJetpack = false;
		}

		var jconsume = 0.02;
		if( !col ) {
			standingBlock = null;
			if( useJetpack ) {
				if( jetpack > 0 ) {
					thrusting = true;
					jetpack -= jconsume * dt;
					if( gravity > -0.05 )
						gravity += -(0.025 / Math.pow(1 + Math.abs(gravity), 2)) * dt; // cayendo
					else
						gravity += -0.005 * dt; // subiendo
				}
			} else {
				if( swimming ) jetpack += jconsume * 0.7 * dt;
				else jetpack += jconsume * 0.2 * dt;
			}
			if( swimming ) {
				gravity += 0.005 * dt;
				if( gravity > 0.07 ) gravity *= Math.pow(0.95, dt);
			} else {
				gravity += 0.014 * dt;
				if( gravity > maxGravity ) gravity = maxGravity;
			}
		} else {
			// recolocar los pies sobre el suelo (resolucion de 1/32)
			if( gravity >= 0 ) {
				var h = Std.int(pz * 32) / 32;
				while( true ) {
					var found = false;
					for( i in 0...3 )
						if( collide(fx[i], fy[i], h) ) {
							found = true;
							break;
						}
					if( !found ) break;
					h += 1 / 32;
				}
				pz = h;
			}
			if( jetpack < 1 ) jetpack += jconsume * 7 * dt;
			var feet : Block;
			if( collide(px, py, pz - 0.02) )
				feet = world.block(Math.floor(px), Math.floor(py), Std.int(pz - 0.02));
			else
				feet = null;
			if( feet == null )
				for( i in 0...3 )
					if( collide(fx[i], fy[i], pz - 0.02) ) {
						feet = world.block(Math.floor(fx[i]), Math.floor(fy[i]), Std.int(pz - 0.02));
						break;
					}
			if( feet != standingBlock ) standingBlock = feet;
			if( gravity > 0 ) {
				pushPower = 0;
				if( jetpack < 1 ) jetpack += 0.3;
				else if( gravity >= 0.25 ) bobY = 15; // aterrizaje fuerte
				else bobY = 5;
				gravity = 0;
			}
			if( useJetpack && stun <= 0 ) gravity = -0.23; // salto
		}

		if( jetpack > 1 ) jetpack = 1;

		// movimiento
		var dist = speed * dt;
		var ox = px, oy = py;

		if( standingBlock != null )
			for( f in standingBlock.flags )
				switch( f ) {
				case BFJump(p):
					if( gravity >= 0 ) gravity = -p;
				default:
				}

		if( standingBlock != null && standingBlock.hasFlag(BFSlippy) ) {
			var p = Math.pow(0.96, dt);
			dist *= 0.005;
			oldSpeedX *= p;
			oldSpeedY *= p;
			oldSpeedX += dist * Math.cos(a);
			oldSpeedY += dist * Math.sin(a);
			dist = Math.sqrt(oldSpeedX * oldSpeedX + oldSpeedY * oldSpeedY);
			a = Math.atan2(oldSpeedY, oldSpeedX);
		} else {
			oldSpeedX = dist * Math.cos(a);
			oldSpeedY = dist * Math.sin(a);
		}
		px += oldSpeedX;
		py += oldSpeedY;

		// permitir pequenas correcciones
		if( dist == 0 ) dist = 0.01;

		// recolocar contra las paredes
		var old = pushPower;
		var dzs = swimming ? [0., 0.5, 0.9] : (walkingSlow ? [-0.2, 0., 0.5, 1., 1.3] : [0., 0.5, 1., 1.3]);
		for( dz in dzs ) {
			var qz = pz + dz;
			var recal = 20;
			while( --recal > 0 ) {
				var r = false;
				for( k in 0...16 ) {
					var a2 = a + ((k & 1) * 2 - 0.99) * (k >> 1) * Math.PI / 8;
					var px2 = px + Math.cos(a2) * 0.45, py2 = py + Math.sin(a2) * 0.45;
					if( collide(px2, py2, qz) == (dz < 0) ) continue;
					px -= Math.cos(a2) * dist / 20;
					py -= Math.sin(a2) * dist / 20;
					pushPower += dist / 20;
					r = true;
				}
				if( !r ) break;
			}
		}

		ox -= px;
		oy -= py;
		dist = Math.sqrt(ox * ox + oy * oy);

		px = clampPos(px);
		py = clampPos(py);

		if( walkingSlow || pushPower == old || dist > speed * dt * 0.5 ) pushPower = 0;
	}

	// ---------------------------------------------------------------- camara

	public function updateCamera() {
		var cp = Math.cos(pitch);
		var c = s3d.camera;
		var ez = pz + VIEW_Z + Math.sin(walkBobbing) * 0.05;
		c.fovY = Settings.fov;
		c.zNear = 0.1;
		c.zFar = 1500;
		c.pos.set(px, py, ez);
		c.target.set(px + Math.cos(yaw) * cp, py + Math.sin(yaw) * cp, ez + Math.sin(pitch));
		c.up.set(0, 0, 1);
		world.sky.follow(px, py, ez);
	}
}
