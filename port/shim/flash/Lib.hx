package flash;

class Lib {
	/** milisegundos desde que arranco el programa, como en Flash (antes eran desde 1970 y no cabian en un Int: el
	 * generador de planetas no veia pasar el tiempo y generaba el planeta entero de golpe, congelando la pantalla) */
	static var start = haxe.Timer.stamp();
	public static function getTimer() : Int return Std.int((haxe.Timer.stamp() - start) * 1000);
}
