package flash.utils;

/** Haxe 2 compatibility: typed Dictionary (keys are objects). Weak keys are ignored. */
abstract TypedDictionary<K,V>(haxe.ds.ObjectMap<Dynamic,V>) {
	public inline function new( ?weakKeys : Bool ) this = new haxe.ds.ObjectMap<Dynamic,V>();
	public inline function set( k : K, v : V ) : Void this.set(k, v);
	public inline function get( k : K ) : Null<V> return this.get(k);
	public inline function exists( k : K ) : Bool return this.exists(k);
	public inline function delete( k : K ) : Void this.remove(k);
	public inline function iterator() : Iterator<K> return cast this.keys();
	public inline function keys() : Iterator<K> return cast this.keys();
}
