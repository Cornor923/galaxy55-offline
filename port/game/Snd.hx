/** Efectos de sonido, copia de Sfx.hx del original (mismos .wav de src/G55/fla/client/sfx, mismo volumen general 0.3).
    Busca res/sfx_<nombre>.wav (paquete portatil) o la carpeta del repositorio. Si no hay audio, no suena y sigue. */
class Snd {
	public static var VOLUME = 0.3;
	static var cache = new Map<String, hxd.res.Sound>();
	static var broken = false;

	static function get( name : String ) : hxd.res.Sound {
		var s = cache.get(name);
		if( s != null || cache.exists(name) ) return s;
		try {
			var p = "res/sfx_" + name + ".wav";
			if( !sys.FileSystem.exists(p) ) p = "src/G55/fla/client/sfx/" + name + ".wav";
			s = hxd.res.Any.fromBytes(name + ".wav", sys.io.File.getBytes(p)).toSound();
		} catch( e : Dynamic ) s = null;
		cache.set(name, s);
		return s;
	}

	public static function play( name : String, vol = 1.0, loop = false ) : hxd.snd.Channel {
		if( broken ) return null;
		var s = get(name);
		if( s == null ) return null;
		try return s.play(loop, vol * VOLUME) catch( e : Dynamic ) {
			broken = true;
			return null;
		}
	}
}
