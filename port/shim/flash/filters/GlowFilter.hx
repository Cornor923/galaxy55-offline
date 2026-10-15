package flash.filters;

class GlowFilter extends BitmapFilter {
	public var color : Int;
	public var alpha : Float;
	public var blurX : Float;
	public var blurY : Float;
	public var strength : Float;
	public var quality : Int;
	public var inner : Bool;
	public var knockout : Bool;
	public function new( color = 0xFF0000, alpha = 1., blurX = 6., blurY = 6., strength = 2., quality = 1, inner = false, knockout = false ) {
		super();
		this.color = color;
		this.alpha = alpha;
		this.blurX = blurX;
		this.blurY = blurY;
		this.strength = strength;
		this.quality = quality;
		this.inner = inner;
		this.knockout = knockout;
	}
}
