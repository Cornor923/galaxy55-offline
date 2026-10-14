package mt.flash;

class Key {

#if (flash9 || cpp)
	static var fl_initDone = false;
	static var kcodes = new Array<Null<Int>>();

	static var ktime = 0;
	// pulsaciones recientes (fotograma en que se pulsaron); ver isToggled
	static var fresh = new Array<Null<Int>>();

	public static function init() {
		var stage = flash.Lib.current.stage;
		if (fl_initDone) {
			stage.removeEventListener(flash.events.Event.ENTER_FRAME,onEnterFrame);
			stage.addEventListener(flash.events.Event.ENTER_FRAME,onEnterFrame);
			return;
		}
		fl_initDone = true;
		
		
		#if !haxe3
		stage.addEventListener(flash.events.KeyboardEvent.KEY_DOWN,callback(onKey,true));
		stage.addEventListener(flash.events.KeyboardEvent.KEY_UP, callback(onKey, false));
		#else
		stage.addEventListener(flash.events.KeyboardEvent.KEY_DOWN,onKey.bind(true));
		stage.addEventListener(flash.events.KeyboardEvent.KEY_UP, onKey.bind(false));
		#end
		
		stage.addEventListener(flash.events.Event.DEACTIVATE,function(_) { kcodes = new Array(); fresh = new Array(); });
		stage.addEventListener(flash.events.Event.ENTER_FRAME,onEnterFrame);
	}
	
	static function onEnterFrame(_) {
		ktime++;
	}

	static function onKey( down, e : flash.events.KeyboardEvent ) {
		event(e.keyCode, down);
	}

	public static function event( code, down ) {
		// ignora las repeticiones automaticas del teclado: solo cuenta la pulsacion inicial
		if( down && kcodes[code] == null )
			fresh[code] = ktime;
		kcodes[code] = down ? ktime : null;
		// release Ctrl when Alt pressed (AltGr generates Ctrl+Alt)
		if( code == 18 && !down )
			kcodes[17] = null;
	}


	public static function isDown(c) {
		return kcodes[c] != null;
	}

	/**
		true una sola vez por pulsacion. El original comparaba con el fotograma exacto (kcodes[c] == ktime),
		pero ktime sube antes de que el juego lea la tecla y casi nunca coincidia (F, F9, H, T, TAB, R, numeros...).
	*/
	public static function isToggled(c) {
		var f = fresh[c];
		if( f == null )
			return false;
		fresh[c] = null;
		return ktime - f <= 3;
	}

#else

	static var kcodes = new Array<Bool>();

	public static function enableForWmode() {
		flash.Key.addListener({
			onKeyUp : function() {
				kcodes[flash.Key.getCode()] = false;
			},
			onKeyDown : function() {
				kcodes[flash.Key.getCode()] = true;
			},
		});
	}

	public static function isDown(c) {
		return kcodes[c];
	}
	static function event(k,down) {

		kcodes[k] = down;
	}

#end

#if flash
	public static function enableJSKeys(objName:String) {
		try {
			flash.external.ExternalInterface.addCallback("onKeyEvent",#if !flash9 null,#end event);
			var r : Null<Bool> = flash.external.ExternalInterface.call("function() { var fla = window.document['"+objName+"']; if( fla == null ) return false; document.onkeydown = function(e) { if( e == null ) e = window.event; fla.onKeyEvent(e.keyCode,true); }; document.onkeyup = function(e) { if( e == null ) e = window.event; fla.onKeyEvent(e.keyCode,false); }; return true; }");
			if( r == null ) r = false;
			return r;
		} catch( e : Dynamic ) {
			return false;
		}
	}
#end

}
