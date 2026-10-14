package flash;

abstract Vector<T>(Array<T>) {
	public var length(get, never) : Int;
	public inline function new( ?len : Int = 0, ?fixed : Bool ) {
		this = [];
		for( i in 0...len ) this.push(cast 0);
	}
	inline function get_length() return this.length;
	@:arrayAccess inline function get( i : Int ) : T return this[i];
	@:arrayAccess inline function set( i : Int, v : T ) : T return this[i] = v;
	public inline function push( v : T ) return this.push(v);
	public inline function copy() : Vector<T> return cast this.copy();
	public inline function iterator() return this.iterator();
}
