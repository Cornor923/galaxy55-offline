package flash.geom;

class Rectangle {
	public var x : Float;
	public var y : Float;
	public var width : Float;
	public var height : Float;
	public function new( x = 0., y = 0., w = 0., h = 0. ) {
		this.x = x;
		this.y = y;
		width = w;
		height = h;
	}
	public function clone() return new Rectangle(x, y, width, height);
	public var left(get, never) : Float;
	public var top(get, never) : Float;
	public var right(get, never) : Float;
	public var bottom(get, never) : Float;
	function get_left() return x;
	function get_top() return y;
	function get_right() return x + width;
	function get_bottom() return y + height;
	public function contains( px : Float, py : Float ) return px >= x && py >= y && px < x + width && py < y + height;
}
