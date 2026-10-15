import flash.display.BitmapData;

/** Prueba sin pantalla: genera el fondo de un sector y guarda una imagen. hl exptest.hl [semilla] [salida.png] */
class ExpTest {
	static function main() {
		var args = Sys.args();
		var seed = args.length > 0 ? Std.parseInt(args[0]) : 253725;
		var path = args.length > 1 ? args[1] : "port/out/exp_sector.png";
		var t0 = haxe.Timer.stamp();
		var room = new ExpRoom(seed);
		room.generateSectorBackground();
		Sys.println("generado en " + Std.int((haxe.Timer.stamp() - t0) * 1000) + " ms, capas=" + room.layers.length + " bg=" + StringTools.hex(room.bgColor, 6) + " estrellas=" + StringTools.hex(room.starColor, 6));
		var out = new BitmapData(900, 450, false, 0);
		// fondo en degradado como Manager.setBg (colores capados)
		var col = mt.deepnight.Color.capBrightnessInt(room.bgColor, 0.3);
		var dark = mt.deepnight.Color.brightnessInt(col, -0.2);
		for( y in 0...450 ) {
			var c = mt.deepnight.Color.interpolateInt(col, dark, y / 449);
			out.fillRect(new flash.geom.Rectangle(0, y, 900, 1), c | 0xFF000000);
		}
		var only = args.length > 2 ? args[2] : "";
		if( only != "" ) room.layers = room.layers.filter(function(l) return only == "stars" ? (l.repeat && !l.additive) : only == "clouds" ? (l.repeat && l.additive) : !l.repeat);
		room.compose(out, room.center.x, room.center.y);
		sys.io.File.saveBytes(path, BmpPng.encode(out));
		Sys.println("guardado " + path);
	}
}
