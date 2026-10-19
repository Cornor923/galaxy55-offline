import Common;
import SaveData.SaveInfo;

/** Bloque apuntado: (x,y,z) el bloque que se golpea, (tx,ty,tz) la celda libre delante de el, (hx,hy,hz) el punto de impacto. */
typedef Select = {
	var x : Int;
	var y : Int;
	var z : Int;
	var b : Block;
	var tx : Int;
	var ty : Int;
	var tz : Int;
	var hx : Float;
	var hy : Float;
	var hz : Float;
	var power : Float;
}

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
	/** colision de cabeza (cambio del port): puntos alrededor del centro y su radio, que cubre el plano cercano de la camara
	    (llega a unos 0.18 del ojo a 70 grados) */
	static inline var HEAD_POINTS = 8;
	static inline var HEAD_RADIUS = 0.2;

	public var world(default, null) : World;
	public var info(default, null) : SaveInfo;

	// posicion y vista (Hero.x/y/z, angle, angleZ)
	public var px = 0.;
	public var py = 0.;
	public var pz = 0.;
	public var yaw = 0.;
	public var pitch = 0.;
	public var playSeconds = 0.;

	// excavar y colocar (Game.checkAction)
	public var inv(default, null) : Inv;
	public var select : Select;
	public var laserActive = false;
	public var canBreak = true;
	public var laserCharge : Null<ChargeKind>;
	public var miningPower = 1.0;
	/** modo creativo (anadido nuestro): bloques sin limite, rotura instantanea y jetpack infinito */
	public var creative(default, null) = false;
	/** --editnodriza: la nave nodriza se puede editar (en creativo) y al salir se guarda en mothership.bin */
	public static var editMother = Sys.args().indexOf("--editnodriza") >= 0;
	var actionPause = 0.;
	var activatePending : Select;
	var actionWait = false;
	var armed = false;
	public var drops : Drops;
	var fx : Fx;
	var parts : Parts;
	var hand : Hand;
	/** Process.hx del original: agua y lava que fluyen, hierba, anclas... */
	public var process : WorldProcess;
	/** la nave: el jugador empieza dentro y baja al planeta por el teletransportador (Game.placeShip) */
	public var ship(default, null) : Ship;
	/** progreso del teletransporte (Hero.enteringShip): -1 = recien llegado, 0..1.5 = entrando; a 1.5 se transporta */
	public var enteringShip = -1.;

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

	public function new( s3d : h3d.scene.Scene, world : World, info : SaveInfo, atlas : h3d.mat.Texture ) {
		this.s3d = s3d;
		this.world = world;
		this.info = info;
		playSeconds = info.playSeconds;
		creative = info.creative == true || Sys.args().indexOf("--creative") >= 0 || (editMother && info.mothership == true);
		inv = new Inv(info.inv != null ? Inv.copy(info.inv) : Inv.defaults());
		// solo pruebas: --inv=BIron,BGlass,... llena el inventario con esos bloques
		for( a in Sys.args() )
			if( StringTools.startsWith(a, "--inv=") ) {
				inv.inv.t = [];
				for( nm in a.substr(6).split(",") )
					inv.inv.t.push({ k : Type.enumIndex(Type.createEnum(BlockKind, nm)), n : 5 });
				while( inv.inv.t.length < 10 ) inv.inv.t.push(null);
			}
		drops = new Drops(world, atlas);
		process = new WorldProcess(world, world.waterLevel(), (x, y, z, b) -> breakBlock(x, y, z, b, true));
		fx = new Fx(world, atlas);
		parts = new Parts(world, atlas);
		hand = new Hand(world, atlas);
		if( info.mothership == true ) {
			// nave nodriza del robot comerciante: se aparece en la primera bahia
			Mothership.data();
			var b = Mothership.spawnAt != null ? Mothership.spawnAt : Mothership.bay(0);
			px = b.x + 0.5;
			py = b.y + 0.5;
			pz = b.z;
			// sobre el teletransportador de tu nave, aparcada en tu plaza
			var s = Mothership.shipSpawn;
			if( s != null ) {
				px = s.x;
				py = s.y;
				pz = s.z;
			}
			yaw = Math.PI / 2;
			pitch = 0;
			// robots (añadido del port): el comerciante del puesto y los drones
			for( r in Mothership.robots ) {
				var drone = r.k >= 4;
				robots.push(new Robot(world, atlas, drone ? Robot.DRONE : Robot.MERCHANT, r.x + 0.5, r.y + 0.5, r.z, drone ? 0 : r.k * Math.PI / 2));
			}
			return;
		}
		if( info.hangar == true ) {
			// hangar (EditShip): el cobertizo con la nave; sin la nave colgada encima
			hangar = new Hangar(world);
			hangarCheck();
			var sp = Hangar.spawn();
			px = sp.x;
			py = sp.y;
			pz = sp.z;
			yaw = 0;
			pitch = -0.1;
			enteringShip = -1;
			return;
		}
		ship = new Ship(world, atlas, s3d, info.shipEdits, Hangar.currentShip(info));
		ship.initCrafts(this);
		if( info.px < 0 ) {
			// partida nueva: se empieza dentro de la nave, encima del teletransportador
			gotoShip(true);
			pitch = -0.25;
		} else {
			px = info.px;
			py = info.py;
			pz = info.pz;
			yaw = info.yaw;
			pitch = info.pitch;
		}
	}

	/** mercado del robot comerciante (se crea al abrir la tienda por primera vez) */
	public var market(get, null) : Market;
	function get_market() {
		if( market == null ) {
			if( info.credits == null ) info.credits = Market.START_CREDITS;
			market = new Market(info.market);
			info.market = market.info;
		}
		market.advance(playSeconds);
		return market;
	}

	/** hangar (null fuera de el) y lo que se avisa al salir */
	public var hangar(default, null) : Hangar;
	public var hangarValid(default, null) = false;
	public var hangarChanged(default, null) = false;
	public var onHangarExit : Void -> Void;
	var hangarTime = 0.;
	var hangarNext = 0.;

	/** EditShip.checkShip: valida la nave y lo dice en el mensaje de abajo */
	function hangarCheck() {
		hangarValid = hangar.check();
		hangarMsg = hangarValid ? Lang.t("hangar.ship_valid").split("%speed%").join("" + hangar.speed) : Lang.t("hangar." + hangar.error);
	}
	var hangarMsg = "";

	function hangarUpdate( tmod : Float ) {
		hangarTime += tmod;
		if( hangarTime >= hangarNext ) {
			hangarNext = hangarTime + 15;
			hangarCheck();
		}
		if( hangarValid && hangar.spawnCell != null && world.lightAt(hangar.spawnCell.x, hangar.spawnCell.y, hangar.spawnCell.z + 1) == 0 ) {
			hangarValid = false;
			hangarMsg = Lang.t("hangar.no_spawn_light");
		}
		message = hangarTime < 400 ? Lang.t("hangar.help") : hangarMsg;
		// salir por las casillas de teletransporte (EditShip.update)
		if( standingBlock != null && standingBlock.k == BShipEntry ) {
			if( enteringShip >= 0 ) {
				enteringShip += tmod * 0.03;
				if( enteringShip > 1 ) {
					enteringShip = -1;
					if( onHangarExit != null ) onHangarExit();
				}
			}
		} else {
			if( enteringShip > 0 ) enteringShip -= tmod * .1;
			if( enteringShip < 0 ) enteringShip = 0;
		}
	}

	/** la nave editada (comprimida) */
	public function hangarShip() return Hangar.shipBytes(world);

	/** Estado actual para guardar. */
	public function toInfo() : SaveInfo {
		info.px = px;
		info.py = py;
		info.pz = pz;
		info.yaw = yaw;
		info.pitch = pitch;
		info.fly = false;
		info.playSeconds = playSeconds;
		info.inv = Inv.copy(inv.inv);
		info.edits = world.editsFlat();
		if( ship != null ) info.shipEdits = ship.world.editsFlat();
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
		// el planeta da la vuelta (AbstractGame.real del original)
		return v < 0 ? v + s : (v >= s ? v - s : v);
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
		if( debugSpeed != 0 || debugStrafe != 0 ) {
			speed = debugSpeed;
			strafe = debugStrafe;
			walking = true;
		}
		stepPhysics(tmod, speed, strafe, useJetpack);
		updateBobbing(realDt * 60);
		if( hangar != null ) hangarUpdate(tmod);
		else if( ship != null ) {
			ship.update(this, tmod);
			message = ship.message(this);
		}
		if( debugDoorFrames > 0 && ++debugDoorFrames == 12 ) {
			// solo pruebas: abre la puerta de la nave que hay cerca del teletransportador
			if( Sys.args().indexOf("--computer") >= 0 ) onComputer();
			var dz = Std.int(ship.start.z);
			var db =world.block(ship.x - 3, ship.y + 3, dz);
			Sys.println("puerta: " + (db == null ? "ninguna" : db.k + " toggle=" + (db.toggle == null ? "null" : "" + db.toggle.k)));
			activateBlock(ship.x - 3, ship.y + 3, dz, db);
			var da = world.block(ship.x - 3, ship.y + 3, dz);
			Sys.println("despues: " + (da == null ? "ninguna" : "" + da.k));
		}
		if( debugCraft > 0 ) {
			// solo pruebas: pone bloques de madera en la primera zona de sintetizador y, con --craftgo, usa el ordenador
			debugCraft++;
			var c = ship.crafts[0];
			var bx = c.x + world.shipDX, by = c.y + world.shipDY, bz = c.z + World.SHIP_Z;
			if( debugCraft == 5 ) {
				world.setBlock(bx, by, bz, Block.get(BWood));
				ship.craft(bx, by, bz, Block.get(BWood), this);
				Sys.println("zona: " + c.curText + " receta=" + (c.curCraft != null));
			}
			if( debugCraft == 12 && Sys.args().indexOf("--craftgo") >= 0 ) {
				ship.activateCraft(c.out.x + world.shipDX, c.out.y + world.shipDY, c.out.z + World.SHIP_Z, this);
				Sys.println("fabricado; sueltos=" + drops.count() + " madera en inv=" + inv.hasBlocks(Block.get(BWood), 1));
			}
			if( debugCraft == 30 ) Sys.println("tras 60 frames: sueltos=" + drops.count() + " tablas en inv=" + inv.hasBlocks(Block.get(BWoodPlank), 1) + " zona=" + c.curText);
		}
		if( debugTele > 0 ) {
			// solo pruebas: se aparta del teletransportador y vuelve a el para probar el teletransporte
			debugTele++;
			if( debugTele == 6 ) enteringShip = 0; // como si se hubiera apartado y vuelto a pisar la plataforma
		}
		updateAction(tmod, controls, pad);
		if( hangar == null ) process.update(realDt);
		world.flush();
		drops.update(this, tmod);
		fx.update(this, realDt, tmod);
		parts.update(tmod, s3d.camera, px, py);
	}

	/** solo pruebas: recorre el rayo de la mira y cuenta la primera celda ocupada y por que se descarta */
	public function debugPick() : String {
		var cp = Math.cos(pitch);
		var dx = Math.cos(yaw) * cp, dy = Math.sin(yaw) * cp, dz = Math.sin(pitch);
		var ex = px, ey = py, ez = pz + VIEW_Z + Math.sin(walkBobbing) * 0.05;
		var curve = World.curve(world.size);
		var out = [];
		var t = 0.;
		var last = "";
		while( t < 7.0 ) {
			t += 0.02;
			var hx = dx * t, hy = dy * t;
			var x = ex + hx, y = ey + hy, z = ez + dz * t + (hx * hx + hy * hy) * curve;
			var ix = Math.floor(x), iy = Math.floor(y), iz = Math.floor(z);
			var b = world.block(ix, iy, iz);
			var s = b == null ? "" : "" + b.k;
			if( s != last && s != "" ) {
				out.push(s + "@" + ix + "," + iy + "," + iz + " t=" + Std.int(t * 100) / 100 + (blocking(b) ? "" : "(no bloquea)"));
			}
			last = s;
		}
		return "ojos=" + Std.int(ex * 100) / 100 + "," + Std.int(ey * 100) / 100 + "," + Std.int(ez * 100) / 100 + " yaw=" + yaw + " pitch=" + pitch + "  rayo: " + out.join("  ");
	}

	/** vuelve a exigir soltar el boton antes de actuar (al volver de un menu) */
	public function releaseAction() {
		armed = false;
		laserActive = false;
	}

	/** corta los sonidos en bucle (menus abiertos, pausa, salir) */
	public function stopSounds() {
		if( jetSound != null ) jetSound.stop();
		if( laserSound != null ) laserSound.stop();
		jetSound = laserSound = null;
	}

	public function dispose() {
		stopSounds();
		if( ship != null ) ship.dispose();
		fx.dispose();
		parts.dispose();
		hand.dispose();
		drops.dispose();
	}

	/** solo para pruebas automaticas: mantiene el jetpack pulsado */
	public var debugJet = false;
	/** solo para pruebas automaticas: mantiene pulsado el boton de excavar/colocar */
	public var debugAction = false;
	/** banco de pruebas (Dev): mantiene pulsado excavar/colocar */
	public var debugKey : String;
	public var debugSpeed = 0.;
	public var debugStrafe = 0.;
	public var debugTele = 0;
	public var debugCraft = Sys.args().indexOf("--craft") >= 0 ? 1 : 0;
	public var debugClick = Sys.args().indexOf("--click") >= 0 ? 1 : 0;
	public var debugDoorFrames = Sys.args().indexOf("--door") >= 0 || Sys.args().indexOf("--computer") >= 0 ? 1 : 0;
	/** solo para pruebas: finge que el bloque no se puede romper (para ver el efecto) */
	public var debugDeny = false;

	/** Un fotograma de fisica con varios pasos pequenos, como el original (tmod: 1 = 1/32 s). */
	public function stepPhysics( tmod : Float, speed : Float, strafe : Float, useJetpack : Bool ) {
		var k = Math.ceil(tmod * 10);
		var dt = tmod / k;
		thrusting = false;
		for( i in 0...k ) doMove(dt, speed, strafe, useJetpack);
		if( creative ) jetpack = 1;
		if( footCD > 0 ) footCD -= tmod;
		updateSounds();
	}

	/** sonidos de bucle del original: jetpack (Hero.update) y laser (Game.update) */
	var footCD = 0.;
	var jetSound : hxd.snd.Channel;
	var laserSound : hxd.snd.Channel;
	function updateSounds() {
		if( thrusting ) {
			if( jetSound == null ) {
				Snd.play("jetpackStart", 0.2);
				jetSound = Snd.play("jetpack", 0.07, true);
			}
		} else if( jetSound != null ) {
			jetSound.stop();
			jetSound = null;
		}
		if( laserActive && select != null ) {
			if( laserSound == null ) {
				Snd.play("lazerStart", 0.3);
				laserSound = Snd.play("lazer", 0.25, true);
			}
		} else if( laserSound != null ) {
			laserSound.stop();
			laserSound = null;
		}
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
		// cambio del port: tambien al caer o flotar con el jetpack (el original solo al subir) y con HEAD_POINTS puntos a HEAD_RADIUS
		// del centro (el original usaba los 3 de los pies, a 0.1). Si no, bajando de un salto o flotando junto al borde de un saliente,
		// la cabeza y la camara se metian de lado en el bloque: las sondas de las paredes no pasan de 1.3. Se empuja hacia abajo,
		// como al chocar subiendo, en vez de frenar el avance (frenarlo impedia saltar a un escalon bajo un techo bajo).
		if( !col ) {
			var d = VIEW_Z + 0.13;
			var recal = 0.;
			for( i in 0...HEAD_POINTS ) {
				var ha = a + i * Math.PI * 2 / HEAD_POINTS;
				var hx = px + Math.cos(ha) * HEAD_RADIUS, hy = py + Math.sin(ha) * HEAD_RADIUS;
				while( recal < 0.5 && collide(hx, hy, pz + d) ) {
					pz -= 0.01;
					recal += 0.01;
				}
			}
			if( gravity < 0 && recal > 0 && recal < 0.5 ) gravity = 0;
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
			if( feet != standingBlock ) {
				standingBlock = feet;
				if( gravity / maxGravity > 0.4 && !creative ) {
					Snd.play("landHard", 1.5);
					Snd.play("hit", 0.7);
				}
			}
			if( speed > 0 && footCD <= 0 && !swimming ) {
				footCD = 9;
				Snd.play(Std.random(100) < 70 ? "footstep1" : "footstep2", 0.3);
			}
			if( gravity > 0 ) {
				Snd.play("land");
				pushPower = 0;
				if( jetpack < 1 ) jetpack += 0.3;
				else if( gravity >= 0.25 ) bobY = 15; // aterrizaje fuerte
				else bobY = 5;
				gravity = 0;
			}
			if( useJetpack && stun <= 0 ) {
				gravity = -0.23; // salto
				Snd.play("jump", 0.5);
			}
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

	// ---------------------------------------------------------------- la nave

	/** distancia con signo en un planeta que da la vuelta (AbstractGame.realDist) */
	public function wrapDist( d : Float ) : Float {
		var s = world.size;
		d %= s;
		if( (d < 0 ? -d : d) > s * 0.5 ) d += d < 0 ? s : -s;
		return d;
	}

	/** Hero.gotoShip: aparece en la nave (encima del teletransportador) o en el suelo, bajo ella */
	public function gotoShip( inside : Bool ) {
		enteringShip = -1;
		if( ship == null ) {
			// en la nave nodriza (o el hangar) Mayus+K vuelve a tu nave
			if( onHangarExit != null && hangar == null ) onHangarExit();
			return;
		}
		px = ship.x + 0.5;
		py = ship.y + 0.5;
		pz = inside ? ship.start.z : ship.z;
		gravity = 0;
		oldSpeedX = oldSpeedY = 0;
		// se mira hacia donde no haya pared
		for( i in 0...4 ) {
			var a = i * Math.PI / 2;
			if( !collide(px + Math.cos(a), py + Math.sin(a), pz + 1.5) ) {
				yaw = a;
				break;
			}
		}
	}

	/** se llama al activar el ordenador de a bordo */
	public dynamic function onComputer() {}
	/** celda del ultimo ordenador activado (en la nave nodriza decide si es el del robot o el de tu nave) */
	public var lastComputer : { x : Int, y : Int, z : Int };

	/** en la nave nodriza: el ordenador del puesto del robot comerciante (cerca del robot), no el de tu nave */
	public function isRobotComputer() : Bool {
		var c = lastComputer;
		if( c == null ) return false;
		for( r in Mothership.robots )
			if( r.k < 4 && Math.abs(r.x - c.x) <= 4 && Math.abs(r.y - c.y) <= 4 && Math.abs(r.z - c.z) <= 2 ) return true;
		return false;
	}

	/** texto de recetas del sintetizador cercano (se muestra en pantalla) */
	public var message : String;
	public var messageRed = false;

	/** ShipLogic.activateBlock y Process.toggle: ordenador de a bordo y bloques que se abren o cierran (puertas) */
	public function activateBlock( x : Int, y : Int, z : Int, b : Block ) {
		if( b.activable != null ) {
			var ok = switch( b.activable ) {
				case WEverywhere: true;
				case WInShip: z >= World.SHIP_Z || info.mothership == true; // la nave nodriza cuenta como nave
				case WOnPlanet: z < World.SHIP_Z;
			};
			if( !ok ) return;
			switch( b.k ) {
			case BShipComputer: lastComputer = { x : x, y : y, z : z }; onComputer();
			case BCrafterComputer: if( ship != null ) ship.activateCraft(x, y, z, this);
			default:
				if( b.hasProp(PContainer) && onChest != null ) onChest(chestBox(x, y, z, b));
			}
		} else if( b.toggle != null ) {
			// Process.toggle: se cambia toda la columna del mismo bloque (una puerta mide varios bloques de alto)
			while( world.block(x, y, z - 1) == b ) z--;
			while( world.block(x, y, z) == b ) {
				world.setBlock(x, y, z, b.toggle);
				z++;
			}
		}
	}

	// ---------------------------------------------------------------- excavar y colocar

	inline function wrapI( v : Int ) : Int {
		var s = world.size;
		return v < 0 ? v + s : (v >= s ? v - s : v);
	}

	/** Render.doPick del original: se apunta a todo lo que tiene PCanPick (no lo quitan BFDetail ni BFNoPick: el agua no, la fuente de cascada si) */
	inline function blocking( b : Block ) : Bool {
		return b.hasProp(PCanPick);
	}

	/**
	 * Primer bloque que toca el rayo del centro de la pantalla (alcance 7). Igual que Render.pick del original, la altura
	 * se corrige con la curvatura del planeta (z + r2 * curve), porque lo que se ve esta curvado.
	 */
	function pick( hand : Block ) : Select {
		var cp = Math.cos(pitch);
		var dx = Math.cos(yaw) * cp, dy = Math.sin(yaw) * cp, dz = Math.sin(pitch);
		var ex = px, ey = py, ez = pz + VIEW_Z + Math.sin(walkBobbing) * 0.05;
		var curve = hangar != null ? 0. : World.curve(world.size);
		var lx = 0, ly = 0, lz = 0, have = false;
		var t = 0.;
		while( t < 7.0 ) {
			t += 0.02;
			var hx = dx * t, hy = dy * t;
			var x = ex + hx, y = ey + hy, z = ez + dz * t + (hx * hx + hy * hy) * curve;
			var ix = Math.floor(x), iy = Math.floor(y), iz = Math.floor(z);
			// (no se salta la misma celda: los bloques parciales solo cuentan si el rayo pasa por su caja)
			var b = world.block(ix, iy, iz);
			if( b != null && hand != null && b.hasFlag(BFLiquid) ) b = null; // con un bloque en la mano el agua no cuenta: se puede poner bajo el agua
			if( b != null && blocking(b) && (b.size == null || (x - ix >= b.size.x1 && x - ix <= b.size.x2 && y - iy >= b.size.y1 && y - iy <= b.size.y2 && z - iz >= b.size.z1 && z - iz <= b.size.z2)) ) {
				if( Dev.trace && iz >= World.SHIP_Z ) Sys.println("pick: toca " + b.k + "@" + ix + "," + iy + "," + iz + " antes=" + lx + "," + ly + "," + lz + " mano=" + (hand != null) + " enZona=" + ship.inCraft(lx, ly, lz));
				if( !have || (iz < 1 && hangar == null) ) return null;
				// hangar: solo dentro de la zona construible (EditShip.checkSelect); para poner basta con que el sitio lo este
				if( hangar != null && !Hangar.inZone(ix, iy, iz) && (hand == null || !Hangar.inZone(lx, ly, lz)) ) return null;
				// nave nodriza: no se rompe ni se construye; como en tu nave (ShipLogic.checkSelect), solo se apunta a lo que se activa
				if( info.mothership == true && !editMother && (hand != null || (b.activable == null && b.toggle == null && !b.hasProp(PContainer))) ) return null;
				if( iz >= World.SHIP_Z ) {
					// en la nave solo se puede apuntar a lo que se activa (puertas, ordenador); el casco no se toca (ShipLogic.checkSelect)
					if( hand == null ) {
						// mano vacia: se apunta a lo que se activa o a lo que se puso en una zona de sintetizador
						if( b.activable == null && b.toggle == null && !ship.inCraft(ix, iy, iz) ) return null;
					} else if( !ship.inCraft(lx, ly, lz) )
						return null; // con un bloque en la mano solo se puede poner dentro de esas zonas
				} else if( iz >= World.HEIGHT - 1 )
					return null;
				return { x : wrapI(ix), y : wrapI(iy), z : iz, b : b, tx : wrapI(lx), ty : wrapI(ly), tz : lz, hx : x, hy : y, hz : z, power : 0. };
			}
			lx = ix;
			ly = iy;
			lz = iz;
			have = true;
		}
		return null;
	}

	function updateAction( tmod : Float, controls : Bool, pad : hxd.Pad ) {
		var K = hxd.Key;
		var held = false, forceEmpty = false;
		if( controls ) {
			held = K.isDown(K.MOUSE_LEFT) || K.isDown(K.E) || K.isDown(K.SHIFT);
			if( pad != null ) {
				var rt = pad.isDown(pad.config.RT), lt = pad.isDown(pad.config.LT);
				if( rt || lt ) held = true;
				forceEmpty = rt && !lt;
				// como el mando de la version Flash (input/Pad.hx): RB / cruceta derecha = casilla siguiente,
				// LB / cruceta izquierda = anterior, Y = tirar el bloque elegido
				if( pad.isPressed(pad.config.RB) || pad.isPressed(pad.config.dpadRight) ) inv.scroll(-1);
				if( pad.isPressed(pad.config.LB) || pad.isPressed(pad.config.dpadLeft) ) inv.scroll(1);
				if( pad.isPressed(pad.config.Y) && inv.getCurrentBlock() != null ) dropCurrent();
				if( pad.isPressed(pad.config.analogClick) ) copyTarget();
			}
			if( hxd.Key.isPressed(hxd.Key.MOUSE_MIDDLE) ) copyTarget();
			// casillas: TAB = excavador, 1..9 y 0 = los 10 bloques. El original (Game.checkKeys) ponia el excavador tambien en 1
			// y dejaba la ultima casilla sin atajo; aqui se corrige a peticion de los jugadores
			for( i in 1...11 )
				if( K.isPressed(K.NUMBER_0 + (i % 10)) && inv.inv.t.length >= i ) inv.select(i);
			if( K.isPressed(K.TAB) ) inv.select(0);
			// Mayus + K: volver a la nave (Game.checkKeys)
			if( K.isDown(K.SHIFT) && K.isPressed(K.K) ) gotoShip(true);
			if( (K.isPressed(K.R) || K.isPressed(K.DELETE)) && inv.getCurrentBlock() != null ) dropCurrent();
		}
		if( debugAction || debugKey != null ) {
			held = true;
			armed = true;
		}
		if( debugClick > 0 ) {
			// solo pruebas: un clic completo (se pulsa 10 fotogramas y se suelta)
			debugClick++;
			held = debugClick > 8 && debugClick < 20;
		}
		var hand = forceEmpty ? null : inv.getCurrentBlock();
		if( !held ) {
			armed = true;
			actionWait = false;
		}
		laserActive = controls && held && armed && !actionWait;
		if( actionPause > 0 ) actionPause -= tmod;

		// seleccion (Game.update: no se puede apuntar a la propia celda ni a la de encima)
		var prev = select;
		var s = controls || select != null || debugAction ? pick(hand) : null;
		if( s != null ) {
			var cx = hand == null ? s.x : s.tx, cy = hand == null ? s.y : s.ty, cz = hand == null ? s.z : s.tz;
			if( cx == Std.int(px) && cy == Std.int(py) && (cz == Std.int(pz) || cz == Std.int(pz) + 1) ) s = null;
		}
		if( s != null && prev != null && prev.x == s.x && prev.y == s.y && prev.z == s.z && prev.b == s.b ) {
			// misma celda: se conserva lo acumulado
			prev.hx = s.hx;
			prev.hy = s.hy;
			prev.hz = s.hz;
			prev.tx = s.tx;
			prev.ty = s.ty;
			prev.tz = s.tz;
			s = prev;
		}
		select = s;

		if( !laserActive ) {
			if( activatePending != null ) {
				var a = activatePending;
				activatePending = null;
				if( a == select ) activateBlock(a.x, a.y, a.z, a.b);
			}
			if( select != null ) select.power = 0;
			return;
		}
		if( select == null ) return;
		if( hand == null ) mine(tmod) else place(hand);
	}

	/** Game.checkAction con la mano vacia: acumula potencia segun la dureza del bloque (requiredPower) y las cargas. */
	function mine( tmod : Float ) {
		var s = select;
		var b = s.b;
		// bloques que se activan (ordenador, puertas, cofres): al soltar el boton se activan (Game.checkToggle); si se
		// mantiene el laser hasta el final se rompen, como en el original (checkAction no los distingue)
		if( b.activable != null || b.toggle != null ) {
			if( s.power == 0 ) s.power = 1e-8;
			activatePending = s;
		}
		// en una zona de sintetizador se excava x4 y sin necesitar cargas (ShipLogic.checkSelect)
		var inCraft = hangar != null || (s.z >= World.SHIP_Z && ship.inCraft(s.x, s.y, s.z));
		var matter = b.matter;
		var req = b.requiredPower != null ? b.requiredPower : matter.requiredPower;
		if( req == null ) req = 1;
		// en creativo los bloques que se activan (ordenador, puertas, cofres) no se rompen de golpe: hay que mantener el laser
		var instant = creative && req > 0 && b.activable == null && b.toggle == null;
		var power = inCraft ? 4.0 : 1.0;
		laserCharge = null;
		if( !inCraft && matter.quickBreaks != null )
			for( c in matter.quickBreaks )
				if( inv.hasCharge(c.c) ) {
					power *= c.v;
					laserCharge = c.c;
					break;
				}
		if( creative ) laserCharge = null;
		if( req > 0 && (!matter.hasProp(PRequireCharge) || laserCharge != null || creative || inCraft) ) {
			canBreak = true;
			if( actionPause > 0 ) {
				if( s.power == 0 ) s.power = 1e-8;
				return;
			}
			s.power += instant ? 1 : miningPower * power / (req * 40);
		} else
			canBreak = false;
		if( debugDeny || (info.mothership == true && !editMother) ) canBreak = false;
		// en tu nave, ordenador y puertas solo se usan, no se rompen (ShipLogic.checkSelect: allowBreak = false)
		if( s.z >= World.SHIP_Z && !inCraft && (b.activable != null || b.toggle != null) ) canBreak = false; // la nave nodriza no se rompe
		actionPause = 1;
		if( s.power < 1 || !canBreak ) return;
		if( laserCharge != null ) inv.useCharge(laserCharge);
		activatePending = null;
		breakBlock(s.x, s.y, s.z, b);
		if( creative ) actionPause = 8;
		select = null;
	}

	/** Game.checkAction con un bloque en la mano: se coloca si algo lo sujeta (anclas e imanes). */
	function place( hand : Block ) {
		var s = select;
		var put = hand.getFlip(yaw);
		// en la nave solo se coloca dentro de las zonas de sintetizador (el casco se edita en el hangar) y alli no hace falta apoyo
		var inShip = s.tz >= World.SHIP_Z;
		if( inShip && !ship.inCraft(s.tx, s.ty, s.tz) ) return;
		var x = s.tx, y = s.ty, z = s.tz;
		var ok = false;
		var tmp : Block;
		if( !ok && hand.canPut(Up) && (tmp = world.block(x, y, z + 1)) != null && tmp.hasMagnet(Down) ) ok = true;
		if( !ok && hand.canPut(Down) && (tmp = world.block(x, y, z - 1)) != null && tmp.hasMagnet(Up) ) ok = true;
		if( !ok && hand.canPut(LeftRight) ) {
			if( (tmp = world.block(x + 1, y, z)) != null && tmp.hasMagnet(LeftRight) ) ok = true;
			else if( (tmp = world.block(x - 1, y, z)) != null && tmp.hasMagnet(LeftRight) ) ok = true;
			else if( (tmp = world.block(x, y - 1, z)) != null && tmp.hasMagnet(LeftRight) ) ok = true;
			else if( (tmp = world.block(x, y + 1, z)) != null && tmp.hasMagnet(LeftRight) ) ok = true;
		}
		if( inShip ) ok = true; // select.ignoreMagnets del original
		var here = world.block(x, y, z);
		if( here != null && !here.hasFlag(BFLiquid) ) return; // la celda ya esta ocupada (p. ej. por lo que se acaba de poner): no se gasta nada
		if( !ok || actionPause > 0 ) return;
		actionPause = creative ? 6 : 15;
		if( !creative && !inv.useCurrentBlock() ) return;
		// si era el ultimo bloque, hay que soltar el boton antes de seguir (evita excavar sin querer)
		if( inv.getCurrentBlock() == null ) actionWait = true;
		if( Dev.trace ) Sys.println("place en " + x + "," + y + "," + z + " sobre " + s.b.k + "@" + s.x + "," + s.y + "," + s.z + " antes=" + world.block(x, y, z));
		// el agua puesta por el jugador se extiende como la cascada (si no, inundaria como el mar)
		if( put.type == BTWater && !inShip && hangar == null ) world.setWater(x, y, z, put, WorldProcess.PLACED);
		else world.setBlock(x, y, z, put);
		if( !inShip && hangar == null ) process.onSet(x, y, z, here, put);
		if( inShip ) ship.craft(x, y, z, put, this);
		select = null;
	}

	/** Game.blockBreak: suelta lo que corresponda (con su probabilidad) y quita el bloque. */
	/** clave de una cantina: en la nave, coordenadas de la nave (se mueve de planeta en planeta); si no, planeta y celda */
	function chestKey( x : Int, y : Int, z : Int ) : String {
		if( z >= World.SHIP_Z )
			return "s:" + Std.int(@:privateAccess world.shipLocal(x, world.shipDX)) + "," + Std.int(@:privateAccess world.shipLocal(y, world.shipDY)) + "," + (z - World.SHIP_Z);
		return "p" + (info.uni != null ? info.uni.planetId : 0) + ":" + wrapI(x) + "," + wrapI(y) + "," + z;
	}

	/** contenido de la cantina (se crea vacia con las casillas de BFContainer) */
	public function chestBox( x : Int, y : Int, z : Int, b : Block ) : Protocol.BlockInventory {
		if( info.chests == null ) info.chests = [];
		var k = chestKey(x, y, z);
		for( c in info.chests ) if( c.key == k ) return c.t;
		var size = 4;
		for( f in b.flags ) switch( f ) { case BFContainer(s): size = s; default: }
		var c = { key : k, t : [for( i in 0...size ) null] };
		info.chests.push(c);
		return c.t;
	}

	/** al romper una cantina, lo que tenia sale suelto (cambio del port: el original no lo resolvia) */
	function breakChest( x : Int, y : Int, z : Int ) {
		if( info.chests == null ) return;
		var k = chestKey(x, y, z);
		for( c in info.chests )
			if( c.key == k ) {
				for( s in c.t ) if( s != null ) {
					var d = drops.add(x + 0.5, y + 0.5, z + 0.5, Block.all[s.k]);
					d.n = s.n;
				}
				info.chests.remove(c);
				return;
			}
	}

	public var onChest : Protocol.BlockInventory -> Void;

	public function breakBlock( x : Int, y : Int, z : Int, b : Block, isProcess = false ) {
		if( b.hasProp(PContainer) ) breakChest(x, y, z);
		var get = b.getDrop();
		if( get != null && !creative ) {
			var chance = b.getMain().getDropChance();
			for( i in 0...get.count ) {
				if( Std.random(100) >= chance ) continue;
				drops.add(x + 0.5, y + 0.5, z + 0.5, get.b);
			}
		}
		world.setBlock(x, y, z, null);
		parts.doBreak(x, y, z, b);
		if( !isProcess ) Snd.play("destroyBlock", 0.25);
		if( z >= World.SHIP_Z ) ship.craft(x, y, z, null, this);
		else if( hangar == null ) process.onSet(x, y, z, b, null);
	}

	/** bloque de una zona de sintetizador gastado en una receta: desaparece con su efecto de rotura */
	public function removeShipBlock( x : Int, y : Int, z : Int, b : Block ) {
		world.setBlock(x, y, z, null);
		parts.doBreak(x, y, z, b);
	}

	/** Game.dropCurrent: tira la pila de la casilla elegida delante del jugador. */
	function dropCurrent() {
		var index = inv.blockIndex - 1;
		var s = inv.drop(index);
		if( s == null || creative ) return; // en creativo tirar solo vacia la casilla
		var d = drops.add(px + Math.cos(yaw), py + Math.sin(yaw), pz + 1.2, Block.all[s.k]);
		d.n = s.n;
		d.vx = Math.cos(yaw) * 0.3;
		d.vy = Math.sin(yaw) * 0.3;
		d.active = false;
	}

	/** creativo: L3 o clic central copian el bloque apuntado a la casilla elegida (anadido del port) */
	function copyTarget() {
		if( !creative ) return;
		var s = pick(null);
		if( s != null && s.b != null ) setSlot(s.b);
	}

	/** Paleta creativa: pone el bloque en la casilla elegida (o en la primera libre si esta el excavador). */
	public function setSlot( b : Block ) {
		var idx = inv.blockIndex - 1;
		if( idx < 0 ) {
			idx = 0;
			for( i in 0...inv.inv.t.length )
				if( inv.inv.t[i] == null ) {
					idx = i;
					break;
				}
			inv.blockIndex = idx + 1;
		}
		inv.inv.t[idx] = { k : b.index, n : inv.maxBlock(b) };
		inv.display();
	}

	/** rueda del raton */
	public function scrollInventory( delta : Int ) {
		inv.scroll(delta);
	}

	// ---------------------------------------------------------------- camara

	/** robots de la nave nodriza (Robot.hx) */
	var robots : Array<Robot> = [];

	/** color y opacidad del velo de pantalla dentro de un liquido (Game.getEffects: fades), null fuera */
	public var liquidFade(default, null) : { a : Float, col : Int } = null;
	var liquidTime = 0.;

	/** Game.getEffects + Hero.inWaterBlock del original: el bloque en los ojos, si es liquido con BFColor(c, alpha), tine la pantalla y la niebla */
	function updateLiquidView( ez : Float ) {
		liquidTime += 1 / 60;
		liquidFade = null;
		var b = world.block(Math.floor(px), Math.floor(py), Std.int(ez));
		if( b != null && b.hasFlag(BFLiquid) )
			for( f in b.flags )
				switch( f ) {
				case BFColor(c, alpha):
					if( alpha == null ) alpha = 0.65;
					// el original suma ruido de Perlin a la densidad; aqui una oscilacion suave equivalente
					var power = 60 * alpha + Math.sin(liquidTime * 0.7 + px * 0.3) * 10;
					world.sky.setLiquid(c, power);
					var a = alpha + Math.sin(Math.PI * 2 * (liquidTime % 2.5) / 2.5) * 0.08;
					if( a > 0.999 ) a = 0.999;
					if( a < 0.3 ) a = 0.3;
					liquidFade = { a : a, col : c };
					return;
				default:
				}
		world.sky.setLiquid(null, 0);
	}

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
		world.sky.update(1 / 60);
		updateLiquidView(ez);
		for( r in robots ) r.update(1 / 60, px, py, pz);
		world.updateWrap(px, py);
		// la mano va pegada a la camara de este fotograma (antes usaba la del anterior y temblaba al andar)
		hand.update(inv.getCurrentBlock(), c, bobX, bobY);
	}
}
