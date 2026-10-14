package flash;

class Lib {
	public static function getTimer() : Int return Std.int(haxe.Timer.stamp() * 1000);
}
