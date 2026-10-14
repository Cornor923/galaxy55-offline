
typedef NameData = {
	var name : Null<String>;
}

class Names {
	
	public static var NAMES : Array<NameData> = #if lang_en NamesGen.EN #elseif lang_fr NamesGen.FR #else NamesGen.ES #end;

	#if neko
	static function getCacheFile(file) return Config.TPL + file
	#end
}