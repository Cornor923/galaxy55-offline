package flash.filters;

class DropShadowFilter extends BitmapFilter {
	public var distance : Float;
	public var angle : Float;
	public var color : Int;
	public var alpha : Float;
	public var blurX : Float;
	public var blurY : Float;
	public var strength : Float;
	public var quality : Int;
	public var inner : Bool;
	public var knockout : Bool;
	public var hideObject : Bool;
	public function new( distance = 4., angle = 45., color = 0, alpha = 1., blurX = 4., blurY = 4., strength = 1., quality = 1, inner = false, knockout = false, hideObject = false ) {
		super();
		this.distance = distance;
		this.angle = angle;
		this.color = color;
		this.alpha = alpha;
		this.blurX = blurX;
		this.blurY = blurY;
		this.strength = strength;
		this.quality = quality;
		this.inner = inner;
		this.knockout = knockout;
		this.hideObject = hideObject;
	}
}
