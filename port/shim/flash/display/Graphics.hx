package flash.display;

enum GShape {
	GCircle( x : Float, y : Float, r : Float, color : Int, alpha : Float );
	GRect( x : Float, y : Float, w : Float, h : Float, color : Int, alpha : Float );
	GLine( x0 : Float, y0 : Float, x1 : Float, y1 : Float, width : Float, color : Int, alpha : Float );
}

/** Solo recuerda las formas; BitmapData.draw las dibuja. */
class Graphics {
	public var shapes : Array<GShape> = [];
	var fillColor = 0;
	var fillAlpha = 0.;
	var filling = false;
	var lineW = 0.;
	var lineColor = 0;
	var lineAlpha = 1.;
	var cx = 0.;
	var cy = 0.;

	public function new() {}

	public function clear() {
		shapes = [];
		filling = false;
		lineW = 0;
		cx = cy = 0;
	}
	public function beginFill( color : Int, alpha = 1. ) {
		fillColor = color;
		fillAlpha = alpha;
		filling = true;
	}
	public function endFill() filling = false;
	public function lineStyle( ?width : Float, color = 0, alpha = 1., ?pixelHinting : Bool, ?scaleMode : Dynamic, ?caps : Dynamic, ?joints : Dynamic, ?miter : Float ) {
		lineW = width == null ? 0 : width;
		lineColor = color;
		lineAlpha = alpha;
	}
	public function drawCircle( x : Float, y : Float, r : Float ) {
		if( filling ) shapes.push(GCircle(x, y, r, fillColor, fillAlpha));
		if( lineW > 0 ) {
			var n = Std.int(Math.max(12, r * 2));
			for( i in 0...n ) {
				var a0 = i / n * Math.PI * 2, a1 = (i + 1) / n * Math.PI * 2;
				shapes.push(GLine(x + Math.cos(a0) * r, y + Math.sin(a0) * r, x + Math.cos(a1) * r, y + Math.sin(a1) * r, lineW, lineColor, lineAlpha));
			}
		}
	}
	public function drawRect( x : Float, y : Float, w : Float, h : Float ) {
		if( filling ) shapes.push(GRect(x, y, w, h, fillColor, fillAlpha));
		if( lineW > 0 ) {
			shapes.push(GLine(x, y, x + w, y, lineW, lineColor, lineAlpha));
			shapes.push(GLine(x + w, y, x + w, y + h, lineW, lineColor, lineAlpha));
			shapes.push(GLine(x + w, y + h, x, y + h, lineW, lineColor, lineAlpha));
			shapes.push(GLine(x, y + h, x, y, lineW, lineColor, lineAlpha));
		}
	}
	public function moveTo( x : Float, y : Float ) {
		cx = x;
		cy = y;
	}
	public function lineTo( x : Float, y : Float ) {
		if( lineW > 0 ) shapes.push(GLine(cx, cy, x, y, lineW, lineColor, lineAlpha));
		cx = x;
		cy = y;
	}
	public function curveTo( ax : Float, ay : Float, x : Float, y : Float ) {
		var n = 8;
		var px = cx, py = cy;
		for( i in 1...n + 1 ) {
			var t = i / n, u = 1 - t;
			var qx = u * u * cx + 2 * u * t * ax + t * t * x, qy = u * u * cy + 2 * u * t * ay + t * t * y;
			if( lineW > 0 ) shapes.push(GLine(px, py, qx, qy, lineW, lineColor, lineAlpha));
			px = qx;
			py = qy;
		}
		cx = x;
		cy = y;
	}
}
