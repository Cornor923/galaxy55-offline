/** Safe wrapper: ExternalInterface throws when there is no web page (standalone player). */
class ExtI {
	public static function ok() : Bool {
		return try flash.external.ExternalInterface.available catch( e : Dynamic ) false;
	}
	public static function addCallback( name : String, f : Dynamic ) : Void {
		if( !ok() ) return;
		try flash.external.ExternalInterface.addCallback(name, f) catch( e : Dynamic ) {}
	}
	public static function call( name : String, ?a : Dynamic, ?b : Dynamic, ?c : Dynamic, ?d : Dynamic, ?e : Dynamic ) : Dynamic {
		if( !ok() ) return null;
		var args : Array<Dynamic> = [name];
		for( x in [a, b, c, d, e] ) if( x != null ) args.push(x);
		return try Reflect.callMethod(flash.external.ExternalInterface, untyped flash.external.ExternalInterface["call"], args) catch( ex : Dynamic ) null;
	}
}
