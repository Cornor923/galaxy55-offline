/** Ayuda para pruebas: guarda un BitmapData (shim de Flash) como PNG. */
class BmpPng {
	public static function encode( bd : flash.display.BitmapData ) : haxe.io.Bytes {
		var n = bd.width * bd.height;
		var bgra = haxe.io.Bytes.alloc(n * 4);
		for( i in 0...n ) {
			var c = bd.px[i];
			bgra.set(i * 4, c & 0xFF);
			bgra.set(i * 4 + 1, (c >> 8) & 0xFF);
			bgra.set(i * 4 + 2, (c >> 16) & 0xFF);
			bgra.set(i * 4 + 3, (c >>> 24) & 0xFF);
		}
		var out = new haxe.io.BytesOutput();
		new format.png.Writer(out).write(format.png.Tools.build32BGRA(bd.width, bd.height, bgra));
		return out.getBytes();
	}
}
