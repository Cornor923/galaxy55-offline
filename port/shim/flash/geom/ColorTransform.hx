package flash.geom;

class ColorTransform {
	public var redMultiplier : Float;
	public var greenMultiplier : Float;
	public var blueMultiplier : Float;
	public var alphaMultiplier : Float;
	public var redOffset : Float;
	public var greenOffset : Float;
	public var blueOffset : Float;
	public var alphaOffset : Float;
	public function new( rm = 1., gm = 1., bm = 1., am = 1., ro = 0., go = 0., bo = 0., ao = 0. ) {
		redMultiplier = rm;
		greenMultiplier = gm;
		blueMultiplier = bm;
		alphaMultiplier = am;
		redOffset = ro;
		greenOffset = go;
		blueOffset = bo;
		alphaOffset = ao;
	}
	public var color(get, set) : Int;
	function get_color() return (Std.int(redOffset) << 16) | (Std.int(greenOffset) << 8) | Std.int(blueOffset);
	function set_color( c : Int ) {
		redMultiplier = greenMultiplier = blueMultiplier = 0;
		redOffset = (c >> 16) & 0xFF;
		greenOffset = (c >> 8) & 0xFF;
		blueOffset = c & 0xFF;
		return c;
	}
	public function isIdentity() return redMultiplier == 1 && greenMultiplier == 1 && blueMultiplier == 1 && alphaMultiplier == 1 && redOffset == 0 && greenOffset == 0 && blueOffset == 0 && alphaOffset == 0;
}
