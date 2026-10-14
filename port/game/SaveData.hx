/** Datos de una partida guardada. Los cambios de terreno, inventario y creditos se anadiran aqui. */
typedef SaveInfo = {
	var version : Int;
	var id : String;
	var name : String;
	var seed : Int;
	var biome : String;
	var sizeChunks : Int;
	var created : Float;
	var saved : Float;
	var playSeconds : Float;
	var px : Float;
	var py : Float;
	var pz : Float;
	var yaw : Float;
	var pitch : Float;
	var fly : Bool;
	/** inventario (null = el inicial del original) */
	@:optional var inv : Protocol.InventoryInfos;
	/** cambios del terreno: pares [celda, bloque global] */
	@:optional var edits : Array<Int>;
	/** modo creativo: bloques sin limite, rotura instantanea y jetpack infinito (no existe en el original) */
	@:optional var creative : Bool;
}

/** Guardado en disco: %APPDATA%\Galaxy55\saves\<id>.json (+ <id>.png con la miniatura). */
class SaveData {

	public static inline var VERSION = 1;

	public static function dir() : String {
		var d = Settings.dir() + "/saves";
		if( !sys.FileSystem.exists(d) ) sys.FileSystem.createDirectory(d);
		return d;
	}

	public static function newId() : String {
		var d = Date.now();
		var p = function(n : Int) return StringTools.lpad("" + n, "0", 2);
		return d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate()) + "_" + p(d.getHours()) + p(d.getMinutes()) + p(d.getSeconds()) + "_" + Std.random(1000);
	}

	public static function create( name : String, seed : Int, biome : String, sizeChunks : Int ) : SaveInfo {
		var now = Date.now().getTime();
		return {
			version : VERSION, id : newId(), name : name, seed : seed, biome : biome, sizeChunks : sizeChunks,
			created : now, saved : now, playSeconds : 0, px : -1, py : -1, pz : -1, yaw : 0, pitch : 0, fly : false, inv : Inv.defaults(), edits : [], creative : false,
		};
	}

	/** inventario guardado; si falta o esta mal formado se usa el inicial */
	static function readInv( o : Dynamic ) : Protocol.InventoryInfos {
		try {
			if( o == null || o.t == null ) return Inv.defaults();
			var inv : Protocol.InventoryInfos = { maxWeight : o.maxWeight != null ? o.maxWeight : 64, t : [], charges : [] };
			for( s in (o.t : Array<Dynamic>) )
				inv.t.push(s == null ? null : { k : Std.int(s.k), n : Std.int(s.n) });
			if( o.charges != null )
				for( c in (o.charges : Array<Dynamic>) )
					inv.charges.push({ c : Std.int(c.c), n : Std.int(c.n) });
			return inv;
		} catch( e : Dynamic ) {
			return Inv.defaults();
		}
	}

	public static function jsonPath( id : String ) return dir() + "/" + id + ".json";
	public static function thumbPath( id : String ) return dir() + "/" + id + ".png";

	public static function list() : Array<SaveInfo> {
		var out = [];
		for( f in sys.FileSystem.readDirectory(dir()) ) {
			if( !StringTools.endsWith(f, ".json") ) continue;
			var info = read(f.substr(0, f.length - 5));
			if( info != null ) out.push(info);
		}
		out.sort(function(a, b) return a.saved < b.saved ? 1 : (a.saved > b.saved ? -1 : 0));
		return out;
	}

	public static function read( id : String ) : SaveInfo {
		try {
			var o : Dynamic = haxe.Json.parse(sys.io.File.getContent(jsonPath(id)));
			if( o.version == null || o.seed == null || o.biome == null ) return null;
			return {
				version : o.version, id : id, name : o.name != null ? o.name : id, seed : o.seed, biome : o.biome,
				sizeChunks : o.sizeChunks != null ? o.sizeChunks : 1,
				created : o.created != null ? o.created : 0, saved : o.saved != null ? o.saved : 0,
				playSeconds : o.playSeconds != null ? o.playSeconds : 0,
				px : o.px != null ? o.px : -1, py : o.py != null ? o.py : -1, pz : o.pz != null ? o.pz : -1,
				yaw : o.yaw != null ? o.yaw : 0, pitch : o.pitch != null ? o.pitch : 0, fly : o.fly == true,
					creative : o.creative == true, inv : readInv(o.inv), edits : o.edits != null ? [for( v in (o.edits : Array<Dynamic>) ) Std.int(v)] : [],
			};
		} catch( e : Dynamic ) {
			return null;
		}
	}

	/** Escribe la partida; se guarda primero a un archivo temporal para no corromperla si falla a medias. */
	public static function write( info : SaveInfo, thumbPng : haxe.io.Bytes ) : Bool {
		try {
			info.saved = Date.now().getTime();
			var path = jsonPath(info.id);
			sys.io.File.saveContent(path + ".tmp", haxe.Json.stringify(info, null, "  "));
			if( sys.FileSystem.exists(path) ) sys.FileSystem.deleteFile(path);
			sys.FileSystem.rename(path + ".tmp", path);
			if( thumbPng != null ) sys.io.File.saveBytes(thumbPath(info.id), thumbPng);
			return true;
		} catch( e : Dynamic ) {
			return false;
		}
	}

	public static function delete( id : String ) {
		try {
			if( sys.FileSystem.exists(jsonPath(id)) ) sys.FileSystem.deleteFile(jsonPath(id));
			if( sys.FileSystem.exists(thumbPath(id)) ) sys.FileSystem.deleteFile(thumbPath(id));
		} catch( e : Dynamic ) {}
	}

	public static function thumb( id : String ) : haxe.io.Bytes {
		var p = thumbPath(id);
		return sys.FileSystem.exists(p) ? sys.io.File.getBytes(p) : null;
	}
}
