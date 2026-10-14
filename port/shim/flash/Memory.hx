package flash;

/** Emulacion de flash.Memory (memoria rapida de Flash) sobre haxe.io.Bytes. Little-endian como Flash. */
class Memory {
	static var cur : haxe.io.Bytes;

	public static function select( ba : flash.utils.ByteArray ) {
		cur = ba == null ? null : ba.b;
	}
	public static inline function getByte( a : Int ) : Int return cur.get(a);
	public static inline function setByte( a : Int, v : Int ) cur.set(a, v & 0xFF);
	public static inline function getUI16( a : Int ) : Int return cur.getUInt16(a);
	public static inline function getI32( a : Int ) : Int return cur.getInt32(a);
	public static inline function setI32( a : Int, v : Int ) cur.setInt32(a, v);
	public static inline function getFloat( a : Int ) : Float return cur.getFloat(a);
	public static inline function setFloat( a : Int, v : Float ) cur.setFloat(a, v);
	public static inline function getDouble( a : Int ) : Float return cur.getDouble(a);
	public static inline function setDouble( a : Int, v : Float ) cur.setDouble(a, v);
}
