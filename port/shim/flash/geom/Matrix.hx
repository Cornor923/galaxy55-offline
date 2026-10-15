package flash.geom;

class Matrix {
	public var a : Float;
	public var b : Float;
	public var c : Float;
	public var d : Float;
	public var tx : Float;
	public var ty : Float;
	public function new( a = 1., b = 0., c = 0., d = 1., tx = 0., ty = 0. ) {
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		this.tx = tx;
		this.ty = ty;
	}
	public function clone() return new Matrix(a, b, c, d, tx, ty);
	public function identity() {
		a = d = 1;
		b = c = tx = ty = 0;
	}
	public function translate( dx : Float, dy : Float ) {
		tx += dx;
		ty += dy;
	}
	public function scale( sx : Float, sy : Float ) {
		a *= sx;
		b *= sy;
		c *= sx;
		d *= sy;
		tx *= sx;
		ty *= sy;
	}
	public function rotate( angle : Float ) {
		var cs = Math.cos(angle), sn = Math.sin(angle);
		var na = a * cs - b * sn, nb = a * sn + b * cs;
		var nc = c * cs - d * sn, nd = c * sn + d * cs;
		var ntx = tx * cs - ty * sn, nty = tx * sn + ty * cs;
		a = na;
		b = nb;
		c = nc;
		d = nd;
		tx = ntx;
		ty = nty;
	}
	/** this = this * m (primero esta matriz, luego m), como en Flash */
	public function concat( m : Matrix ) {
		var na = a * m.a + b * m.c, nb = a * m.b + b * m.d;
		var nc = c * m.a + d * m.c, nd = c * m.b + d * m.d;
		var ntx = tx * m.a + ty * m.c + m.tx, nty = tx * m.b + ty * m.d + m.ty;
		a = na;
		b = nb;
		c = nc;
		d = nd;
		tx = ntx;
		ty = nty;
	}
	public function invert() {
		var det = a * d - b * c;
		if( det == 0 ) {
			identity();
			return;
		}
		var na = d / det, nb = -b / det, nc = -c / det, nd = a / det;
		var ntx = -(na * tx + nc * ty), nty = -(nb * tx + nd * ty);
		a = na;
		b = nb;
		c = nc;
		d = nd;
		tx = ntx;
		ty = nty;
	}
	public inline function transformX( x : Float, y : Float ) return a * x + c * y + tx;
	public inline function transformY( x : Float, y : Float ) return b * x + d * y + ty;
	public function transformPoint( p : Point ) return new Point(transformX(p.x, p.y), transformY(p.x, p.y));
}
