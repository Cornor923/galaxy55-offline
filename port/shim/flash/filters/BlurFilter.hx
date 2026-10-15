package flash.filters;

class BlurFilter extends BitmapFilter {
	public var blurX : Float;
	public var blurY : Float;
	public var quality : Int;
	public function new( blurX = 4., blurY = 4., quality = 1 ) {
		super();
		this.blurX = blurX;
		this.blurY = blurY;
		this.quality = quality;
	}
}
