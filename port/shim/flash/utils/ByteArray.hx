package flash.utils;

class ByteArray {
	public var b : haxe.io.Bytes;
	public var position : Int = 0;
	public var length(get, set) : Int;
	public function new() b = haxe.io.Bytes.alloc(0);
	function get_length() return b.length;
	function set_length( n : Int ) {
		if( n != b.length ) {
			var nb = haxe.io.Bytes.alloc(n);
			nb.blit(0, b, 0, n < b.length ? n : b.length);
			b = nb;
		}
		return n;
	}
	public function writeBytes( src : ByteArray, offset = 0, len = 0 ) {
		if( len == 0 ) len = src.length - offset;
		var old = length;
		length = old + len;
		b.blit(old, src.b, offset, len);
	}
}
