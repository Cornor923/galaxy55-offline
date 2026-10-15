package flash.geom;

class Point {
	public var x : Float;
	public var y : Float;
	public function new( x = 0., y = 0. ) {
		this.x = x;
		this.y = y;
	}
	public function clone() return new Point(x, y);
	public var length(get, never) : Float;
	function get_length() return Math.sqrt(x * x + y * y);
	public static function distance( a : Point, b : Point ) : Float {
		var dx = a.x - b.x, dy = a.y - b.y;
		return Math.sqrt(dx * dx + dy * dy);
	}
}
