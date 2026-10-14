/** Ajustes del jugador, guardados en %APPDATA%\Galaxy55\settings.json */
class Settings {

	public static var lang = "es";
	public static var mouseSens = 1.0;
	public static var fov = 70;
	public static var volume = 80;
	public static var fullscreen = false;
	public static var invertY = false;

	public static function dir() : String {
		var base = Sys.getEnv("GALAXY55_DATA");
		if( base == null || base == "" ) base = Sys.getEnv("APPDATA");
		if( base == null || base == "" ) base = Sys.getEnv("HOME");
		if( base == null || base == "" ) base = ".";
		var d = base + "/Galaxy55";
		if( !sys.FileSystem.exists(d) ) sys.FileSystem.createDirectory(d);
		return d;
	}

	public static function load() {
		var path = dir() + "/settings.json";
		if( !sys.FileSystem.exists(path) ) return;
		try {
			var o : Dynamic = haxe.Json.parse(sys.io.File.getContent(path));
			if( o.lang != null ) lang = o.lang;
			if( o.mouseSens != null ) mouseSens = o.mouseSens;
			if( o.fov != null ) fov = o.fov;
			if( o.volume != null ) volume = o.volume;
			if( o.fullscreen != null ) fullscreen = o.fullscreen;
			if( o.invertY != null ) invertY = o.invertY;
		} catch( e : Dynamic ) {}
		Lang.setCode(lang);
	}

	public static function save() {
		var o = { lang : lang, mouseSens : mouseSens, fov : fov, volume : volume, fullscreen : fullscreen, invertY : invertY };
		try sys.io.File.saveContent(dir() + "/settings.json", haxe.Json.stringify(o, null, "  ")) catch( e : Dynamic ) {}
	}
}
