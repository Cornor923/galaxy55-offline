package flash.filters;

class ColorMatrixFilter extends BitmapFilter {
	public var matrix : Array<Float>;
	public function new( ?matrix : Array<Float> ) {
		super();
		this.matrix = matrix != null ? matrix : [1., 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
	}
}
