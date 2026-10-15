package flash.filters;

class DisplacementMapFilter extends BitmapFilter {
	public var mapBitmap : flash.display.BitmapData;
	public var mapPoint : flash.geom.Point;
	public var componentX : Int;
	public var componentY : Int;
	public var scaleX : Float;
	public var scaleY : Float;
	public var mode : String;
	public var color : Int;
	public var alpha : Float;
	public function new( mapBitmap : flash.display.BitmapData, mapPoint : flash.geom.Point, componentX = 0, componentY = 0, scaleX = 0., scaleY = 0., ?mode : String, color = 0, alpha = 0. ) {
		super();
		this.mapBitmap = mapBitmap;
		this.mapPoint = mapPoint;
		this.componentX = componentX;
		this.componentY = componentY;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
		this.mode = mode != null ? mode : "wrap";
		this.color = color;
		this.alpha = alpha;
	}
}
