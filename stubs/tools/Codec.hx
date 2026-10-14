package tools;

/** Offline stub: replaces Motion Twin's server codec. No network. */
class Codec {
	public function new() {}
	public function unserialize( s : String ) : Dynamic return haxe.Unserializer.run(s);

	public static function getData( name : String ) : Dynamic {
		var v : String = null;
		try v = Reflect.field(flash.Lib.current.stage.loaderInfo.parameters, name) catch( e : Dynamic ) {}
		if( v == null || v == "" ) return 654; // 654 = local/offline mode
		return haxe.Unserializer.run(v);
	}
	public static function displayError( e : Dynamic ) : Void { trace("ERROR: " + Std.string(e)); }
	public static function addObfuFields( e : Dynamic ) : Void {}
	public static function load( url : String, act : Dynamic, onData : Dynamic, ?onErr : Dynamic ) : Void {}
	public static function connect( url : String, act : Dynamic, onData : Dynamic, onErr : Dynamic ) : Dynamic return null;
	public static function send( proto : Dynamic, url : String, act : Dynamic ) : Void {}
}
