package input;

import flash.ui.GameInput;
import flash.ui.GameInputDevice;
import flash.events.GameInputEvent;

/**
	Soporte de mando (añadido nuestro, no estaba en el juego original).
	Usa flash.ui.GameInput (Flash Player 11.8+). Mapa por defecto: mando tipo Xbox en Windows.
	Los índices de MAP se calibran con el panel de depuración (tecla F): muestra cada control con su valor.
**/
class Pad
{
	// nombres de control -> función. Se buscan por id ("AXIS_0", "BUTTON_4"...).
	public static var MAP = {
		lx : "AXIS_0", ly : "AXIS_1", rx : "AXIS_2", ry : "AXIS_3",
		// calibrado con el mando del usuario (los gatillos llegan como botones); start = 13 es deducido, no medido
		a : "BUTTON_4", b : "BUTTON_5", x : "BUTTON_6", y : "BUTTON_7",
		lb : "BUTTON_8", rb : "BUTTON_9",
		lt : "BUTTON_10", rt : "BUTTON_11",
		back : "BUTTON_12", start : "BUTTON_13",
		l3 : "BUTTON_14", r3 : "BUTTON_15",
		up : "BUTTON_16", down : "BUTTON_17", left : "BUTTON_18", right : "BUTTON_19",
	};

	var game : Null<Game>;
	var gi : GameInput;
	var dev : GameInputDevice;
	var ctl : Hash<flash.ui.GameInputControl>;
	var prev : Hash<Bool>;

	public var connected(default, null) : Bool;
	public var supported(default, null) : Bool;
	/** segundos desde la última vez que se usó el mando (para dejar el ratón en paz) */
	public var idle(default, null) : Float = 999.;

	// estado listo para usar por Game
	public var moveX = 0.;   // -1 izquierda .. 1 derecha
	public var moveY = 0.;   // 1 adelante .. -1 atrás
	public var lookX = 0.;
	public var lookY = 0.;
	public var jump = false;
	public var action = false;
	public var slow = false;
	public var breaking = false;
	public var placing = false;

	public function new( g : Null<Game> ) {
		game = g;
		ctl = new Hash();
		prev = new Hash();
		supported = false;
		#if nopad
		return;
		#end
		try {
			supported = GameInput.isSupported;
			if( !supported ) return;
			gi = new GameInput();
			gi.addEventListener(GameInputEvent.DEVICE_ADDED, onAddedHandler);
			gi.addEventListener(GameInputEvent.DEVICE_REMOVED, onRemovedHandler);
			if( GameInput.numDevices > 0 ) pick(GameInput.getDeviceAt(0));
		} catch( e : Dynamic ) { supported = false; }
	}

	public function dispose() {
		onAdded = null;
		onRemoved = null;
		if( gi != null ) {
			try gi.removeEventListener(GameInputEvent.DEVICE_ADDED, onAddedHandler) catch( e : Dynamic ) {}
			try gi.removeEventListener(GameInputEvent.DEVICE_REMOVED, onRemovedHandler) catch( e : Dynamic ) {}
		}
		gi = null;
		dev = null;
		connected = false;
		ctl = new Hash();
		game = null;
	}

	var onAdded : Dynamic;
	var onRemoved : Dynamic;
	function onAddedHandler( e : GameInputEvent ) { pick(e.device); }
	function onRemovedHandler( e : GameInputEvent ) { if( e.device == dev ) unpick(); }

	function pick( d : GameInputDevice ) {
		if( d == null || dev != null ) return;
		dev = d;
		dev.enabled = true;
		ctl = new Hash();
		for( i in 0...dev.numControls ) {
			var c = dev.getControlAt(i);
			ctl.set(c.id, c);
		}
		connected = true;
	}

	function unpick() {
		dev = null;
		connected = false;
		ctl = new Hash();
		moveX = moveY = lookX = lookY = 0;
		jump = action = slow = breaking = placing = false;
	}

	public function val( name : String ) : Float {
		var c = ctl.get(name);
		return c == null ? 0. : c.value;
	}

	public function down( name : String ) : Bool {
		var c = ctl.get(name);
		return c != null && c.value > 0.5;
	}

	/** true solo en el fotograma en que se pulsa */
	public function pressed( name : String ) : Bool {
		var d = down(name);
		var was = prev.exists(name) && prev.get(name);
		prev.set(name, d);
		return d && !was;
	}

	public static inline function dead( v : Float, z : Float ) : Float {
		var a = Math.abs(v);
		if( a < z ) return 0.;
		var s = (a - z) / (1 - z);
		return v < 0 ? -s : s;
	}

	/** texto con todos los controles que no están en reposo (para calibrar) */
	public function debugText() : String {
		if( !supported ) return "mando: GameInput no disponible";
		if( !connected ) return "mando: no detectado";
		var out = ["mando: " + dev.name];
		for( id in ctl.keys() ) {
			var c = ctl.get(id);
			if( Math.abs(c.value) > 0.05 ) out.push("  " + id + " = " + Std.int(c.value * 100) / 100);
		}
		return out.join("\n");
	}

	public function update( dt : Float ) {
		if( !connected ) return;
		var g = game;
		var lx = dead(val(MAP.lx), 0.22), ly = dead(val(MAP.ly), 0.22);
		var rx = dead(val(MAP.rx), 0.18), ry = dead(val(MAP.ry), 0.18);
		var d = ctl.get(MAP.ly);
		// en Flash el eje Y de la palanca suele venir con arriba = +1; si fuera al revés se invierte aquí
		moveX = lx;
		moveY = ly;
		lookX = rx;
		lookY = ry;
		jump = down(MAP.a);
		// RT / X = romper (y usar ordenador, puertas...), LT = colocar el bloque seleccionado
		breaking = down(MAP.rt) || down(MAP.x);
		placing = down(MAP.lt) &&g.interf != null && g.interf.getCurrentBlock() != null;
		action = breaking || placing;
		slow = down(MAP.b);

		var used = lx != 0 || ly != 0 || rx != 0 || ry != 0 || jump || action || slow;

		if( g.menuOpen ) {
			if( pressed(MAP.a) ) g.menuChoose(1);
			else if( pressed(MAP.x) ) g.menuChoose(2);
			else if( pressed(MAP.y) ) g.menuChoose(4);
			else if( pressed(MAP.b) || pressed(MAP.back) ) g.menuChoose(3);
			moveX = moveY = lookX = lookY = 0;
			jump = action = slow = breaking = placing = false;
		} else if( g.shopOpen ) {
			// tienda de la ESCorp: cruceta elegir, LB/RB cambiar pestaña, A = 1 unidad, X = 10, B = salir
			if( pressed(MAP.up) ) g.shopMove(-1);
			if( pressed(MAP.down) ) g.shopMove(1);
			if( pressed(MAP.lb) || pressed(MAP.left) ) g.shopTabMove(0);
			if( pressed(MAP.rb) || pressed(MAP.right) ) g.shopTabMove(1);
			if( pressed(MAP.a) ) g.shopAct(false);
			if( pressed(MAP.x) ) g.shopAct(true);
			if( pressed(MAP.b) || pressed(MAP.back) ) g.closeShop();
			moveX = moveY = lookX = lookY = 0;
			jump = action = slow = breaking = placing = false;
		} else {
			if( pressed(MAP.rb) || pressed(MAP.right) ) { g.interf.scrollInventory(-1); used = true; }
			if( pressed(MAP.lb) || pressed(MAP.left) ) { g.interf.scrollInventory(1); used = true; }
			if( pressed(MAP.y) ) { g.dropCurrent(); used = true; }
			if( pressed(MAP.l3) ) { g.render.changeFov(4); used = true; }
			if( pressed(MAP.r3) ) { g.render.changeFov(-4); used = true; }
			if( pressed(MAP.back) ) { g.padHelmet = true; used = true; }
			if( pressed(MAP.start) ) { g.toggleFullScreenLook(); used = true; }
		}

		if( used ) idle = 0 else idle += dt;
	}
}
