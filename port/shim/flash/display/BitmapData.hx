package flash.display;

import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Matrix;
import flash.geom.ColorTransform;
import flash.filters.*;
import haxe.ds.Vector;
import flash.display.Graphics.GShape;

/**
 * BitmapData por software (ARGB sin premultiplicar). Implementa lo que usan el generador de planetas (getVector/setVector)
 * y el explorador (ruido, Perlin, filtros, mezcla). Los resultados se parecen a los de Flash pero no son identicos pixel a pixel.
 */
class BitmapData {
	public var width(default, null) : Int;
	public var height(default, null) : Int;
	public var transparent(default, null) : Bool;
	public var rect : Rectangle;
	public var px : Vector<Int>;

	public function new( w : Int, h : Int, ?transparent = true, ?color = 0xFFFFFFFF ) {
		width = w;
		height = h;
		this.transparent = transparent;
		rect = new Rectangle(0, 0, w, h);
		px = new Vector<Int>(w * h);
		var c = transparent ? color : (color | 0xFF000000);
		if( c != 0 ) for( i in 0...w * h ) px[i] = c;
	}

	public function dispose() {
		px = null;
		width = height = 0;
		rect = new Rectangle(0, 0, 0, 0);
	}

	public function clone() : BitmapData {
		var b = new BitmapData(width, height, transparent, 0);
		Vector.blit(px, 0, b.px, 0, width * height);
		return b;
	}

	public function getVector( r : Rectangle ) : flash.Vector<UInt> {
		var w = Std.int(r.width), h = Std.int(r.height);
		var v = new flash.Vector<UInt>(w * h);
		var i = 0;
		for( y in 0...h )
			for( x in 0...w )
				v[i++] = getPixel32(Std.int(r.x) + x, Std.int(r.y) + y);
		return v;
	}

	public function setVector( r : Rectangle, v : flash.Vector<UInt> ) {
		var w = Std.int(r.width), h = Std.int(r.height);
		var i = 0;
		for( y in 0...h )
			for( x in 0...w )
				setPixel32(Std.int(r.x) + x, Std.int(r.y) + y, v[i++]);
	}

	// ------------------------------------------------------------------ pixeles

	public inline function getPixel32( x : Int, y : Int ) : UInt {
		if( x < 0 || y < 0 || x >= width || y >= height ) return 0;
		return px[x + y * width];
	}

	public inline function getPixel( x : Int, y : Int ) : UInt {
		if( x < 0 || y < 0 || x >= width || y >= height ) return 0;
		return px[x + y * width] & 0xFFFFFF;
	}

	public inline function setPixel32( x : Int, y : Int, c : UInt ) {
		if( x < 0 || y < 0 || x >= width || y >= height ) return;
		px[x + y * width] = transparent ? c : (c | 0xFF000000);
	}

	public inline function setPixel( x : Int, y : Int, c : UInt ) {
		if( x < 0 || y < 0 || x >= width || y >= height ) return;
		px[x + y * width] = (px[x + y * width] & 0xFF000000) | (c & 0xFFFFFF);
	}

	public function fillRect( r : Rectangle, color : UInt ) {
		var x0 = Std.int(Math.max(0, r.x)), y0 = Std.int(Math.max(0, r.y));
		var x1 = Std.int(Math.min(width, r.x + r.width)), y1 = Std.int(Math.min(height, r.y + r.height));
		var c = transparent ? color : (color | 0xFF000000);
		for( y in y0...y1 )
			for( x in x0...x1 )
				px[x + y * width] = c;
	}

	// ------------------------------------------------------------------ mezcla

	static inline function clamp255( v : Float ) : Int return v < 0 ? 0 : (v > 255 ? 255 : Std.int(v));

	/** src sobre dst, ambos ARGB sin premultiplicar */
	public static function over( dst : Int, src : Int ) : Int {
		var sa = (src >>> 24) & 0xFF;
		if( sa == 255 ) return src;
		if( sa == 0 ) return dst;
		var da = (dst >>> 24) & 0xFF;
		if( da == 0 ) return src;
		var fa = sa / 255, fd = da / 255 * (1 - fa);
		var oa = fa + fd;
		var r = (((src >> 16) & 0xFF) * fa + ((dst >> 16) & 0xFF) * fd) / oa;
		var g = (((src >> 8) & 0xFF) * fa + ((dst >> 8) & 0xFF) * fd) / oa;
		var b = ((src & 0xFF) * fa + (dst & 0xFF) * fd) / oa;
		return (clamp255(oa * 255 + 0.5) << 24) | (clamp255(r + 0.5) << 16) | (clamp255(g + 0.5) << 8) | clamp255(b + 0.5);
	}

	static function addBlend( dst : Int, src : Int ) : Int {
		var sa = ((src >>> 24) & 0xFF) / 255;
		if( sa == 0 ) return dst;
		var da = (dst >>> 24) & 0xFF;
		var r = ((dst >> 16) & 0xFF) + ((src >> 16) & 0xFF) * sa;
		var g = ((dst >> 8) & 0xFF) + ((src >> 8) & 0xFF) * sa;
		var b = (dst & 0xFF) + (src & 0xFF) * sa;
		var a = Math.max(da, sa * 255);
		return (clamp255(a) << 24) | (clamp255(r) << 16) | (clamp255(g) << 8) | clamp255(b);
	}

	static function blendPix( mode : BlendMode, dst : Int, src : Int ) : Int {
		return switch( mode ) {
			case ADD: addBlend(dst, src);
			case ERASE:
				var sa = ((src >>> 24) & 0xFF) / 255;
				var da = ((dst >>> 24) & 0xFF) * (1 - sa);
				(clamp255(da + 0.5) << 24) | (dst & 0xFFFFFF);
			case MULTIPLY:
				var sa = ((src >>> 24) & 0xFF) / 255;
				var m = function( s : Int, d : Int ) return clamp255(d * (1 - sa) + (s * d / 255) * sa);
				((dst >>> 24) << 24) | (m((src >> 16) & 0xFF, (dst >> 16) & 0xFF) << 16) | (m((src >> 8) & 0xFF, (dst >> 8) & 0xFF) << 8) | m(src & 0xFF, dst & 0xFF);
			case SCREEN:
				var sa = ((src >>> 24) & 0xFF) / 255;
				var m = function( s : Int, d : Int ) return clamp255(d + (255 - d) * s / 255 * sa);
				((dst >>> 24) << 24) | (m((src >> 16) & 0xFF, (dst >> 16) & 0xFF) << 16) | (m((src >> 8) & 0xFF, (dst >> 8) & 0xFF) << 8) | m(src & 0xFF, dst & 0xFF);
			default: over(dst, src);
		}
	}

	static inline function applyCT( c : Int, ct : ColorTransform ) : Int {
		var a = clamp255(((c >>> 24) & 0xFF) * ct.alphaMultiplier + ct.alphaOffset);
		var r = clamp255(((c >> 16) & 0xFF) * ct.redMultiplier + ct.redOffset);
		var g = clamp255(((c >> 8) & 0xFF) * ct.greenMultiplier + ct.greenOffset);
		var b = clamp255((c & 0xFF) * ct.blueMultiplier + ct.blueOffset);
		return (a << 24) | (r << 16) | (g << 8) | b;
	}

	public function colorTransform( r : Rectangle, ct : ColorTransform ) {
		var x0 = Std.int(Math.max(0, r.x)), y0 = Std.int(Math.max(0, r.y));
		var x1 = Std.int(Math.min(width, r.x + r.width)), y1 = Std.int(Math.min(height, r.y + r.height));
		for( y in y0...y1 )
			for( x in x0...x1 ) {
				var i = x + y * width;
				var c = applyCT(px[i], ct);
				px[i] = transparent ? c : (c | 0xFF000000);
			}
	}

	public function copyPixels( src : BitmapData, srcRect : Rectangle, dest : Point, ?alphaBitmap : BitmapData, ?alphaPoint : Point, mergeAlpha = false ) {
		var sx0 = Std.int(srcRect.x), sy0 = Std.int(srcRect.y), sw = Std.int(srcRect.width), sh = Std.int(srcRect.height);
		var dx0 = Std.int(dest.x), dy0 = Std.int(dest.y);
		var ax = alphaPoint != null ? Std.int(alphaPoint.x) : 0, ay = alphaPoint != null ? Std.int(alphaPoint.y) : 0;
		for( y in 0...sh ) {
			var dy = dy0 + y;
			if( dy < 0 || dy >= height ) continue;
			for( x in 0...sw ) {
				var dx = dx0 + x;
				if( dx < 0 || dx >= width ) continue;
				var s = src.getPixel32(sx0 + x, sy0 + y);
				if( alphaBitmap != null ) {
					var aa = (alphaBitmap.getPixel32(ax + x, ay + y) >>> 24) & 0xFF;
					var sa = (s >>> 24) & 0xFF;
					s = (Std.int(sa * aa / 255) << 24) | (s & 0xFFFFFF);
				}
				var i = dx + dy * width;
				var o = (mergeAlpha || !src.transparent) && src.transparent ? over(px[i], s) : s;
				if( mergeAlpha ) o = over(px[i], s) else o = s;
				px[i] = transparent ? o : (o | 0xFF000000);
			}
		}
	}

	public function copyChannel( src : BitmapData, srcRect : Rectangle, dest : Point, srcChannel : Int, destChannel : Int ) {
		var sx0 = Std.int(srcRect.x), sy0 = Std.int(srcRect.y), sw = Std.int(srcRect.width), sh = Std.int(srcRect.height);
		var dx0 = Std.int(dest.x), dy0 = Std.int(dest.y);
		var ss = shiftOf(srcChannel), ds = shiftOf(destChannel);
		for( y in 0...sh ) {
			var dy = dy0 + y;
			if( dy < 0 || dy >= height ) continue;
			for( x in 0...sw ) {
				var dx = dx0 + x;
				if( dx < 0 || dx >= width ) continue;
				var v = (src.getPixel32(sx0 + x, sy0 + y) >> ss) & 0xFF;
				var i = dx + dy * width;
				px[i] = (px[i] & ~(0xFF << ds)) | (v << ds);
			}
		}
	}

	static inline function shiftOf( ch : Int ) return ch == 1 ? 16 : (ch == 2 ? 8 : (ch == 4 ? 0 : 24));

	public function threshold( src : BitmapData, srcRect : Rectangle, dest : Point, operation : String, thr : UInt, color : UInt = 0, mask : UInt = 0xFFFFFFFF, copySource = false ) : Int {
		var n = 0;
		var sx0 = Std.int(srcRect.x), sy0 = Std.int(srcRect.y), sw = Std.int(srcRect.width), sh = Std.int(srcRect.height);
		var dx0 = Std.int(dest.x), dy0 = Std.int(dest.y);
		var t = thr & mask;
		for( y in 0...sh )
			for( x in 0...sw ) {
				var dx = dx0 + x, dy = dy0 + y;
				if( dx < 0 || dy < 0 || dx >= width || dy >= height ) continue;
				var s = src.getPixel32(sx0 + x, sy0 + y);
				var v : UInt = s & mask;
				var ok = switch( operation ) {
					case "<": v < t;
					case "<=": v <= t;
					case ">": v > t;
					case ">=": v >= t;
					case "==": v == t;
					case "!=": v != t;
					default: false;
				}
				if( ok ) {
					setPixel32(dx, dy, color);
					n++;
				} else if( copySource )
					setPixel32(dx, dy, s);
			}
		return n;
	}

	// ------------------------------------------------------------------ ruido

	public function noise( randomSeed : Int, low = 0, high = 255, channelOptions = 7, grayScale = false ) {
		var s = (randomSeed * 1103515245 + 12345) & 0x7FFFFFFF;
		if( s == 0 ) s = 1;
		inline function rnd() {
			s = (s * 1103515245 + 12345) & 0x7FFFFFFF;
			return (s >> 8) & 0xFFFF;
		}
		var range = high - low + 1;
		for( i in 0...width * height ) {
			var r = low + rnd() % range, g = low + rnd() % range, b = low + rnd() % range, a = (channelOptions & 8) != 0 ? low + rnd() % range : 255;
			if( grayScale ) g = b = r;
			if( (channelOptions & 1) == 0 ) r = 0;
			if( (channelOptions & 2) == 0 ) g = 0;
			if( (channelOptions & 4) == 0 ) b = 0;
			px[i] = transparent ? ((a << 24) | (r << 16) | (g << 8) | b) : (0xFF000000 | (r << 16) | (g << 8) | b);
		}
	}

	static inline function hash( x : Int, y : Int, seed : Int ) : Int {
		var h = x * 374761393 + y * 668265263 + seed * 1274126177;
		h = (h ^ (h >>> 13)) * 1274126177;
		return h ^ (h >>> 16);
	}

	static inline function fade( t : Float ) return t * t * t * (t * (t * 6 - 15) + 10);

	/** ruido de gradiente 2D periodico (px, py celdas por tile) */
	static function gradNoise( x : Float, y : Float, perX : Int, perY : Int, seed : Int ) : Float {
		var x0 = Math.floor(x), y0 = Math.floor(y);
		var fx = x - x0, fy = y - y0;
		var ix = Std.int(x0), iy = Std.int(y0);
		inline function g( cx : Int, cy : Int, dx : Float, dy : Float ) {
			var wx = ((cx % perX) + perX) % perX, wy = ((cy % perY) + perY) % perY;
			var h = hash(wx, wy, seed) & 0xFFFF;
			var a = h / 65536 * Math.PI * 2;
			return Math.cos(a) * dx + Math.sin(a) * dy;
		}
		var n00 = g(ix, iy, fx, fy), n10 = g(ix + 1, iy, fx - 1, fy);
		var n01 = g(ix, iy + 1, fx, fy - 1), n11 = g(ix + 1, iy + 1, fx - 1, fy - 1);
		var u = fade(fx), v = fade(fy);
		var a = n00 + (n10 - n00) * u, b = n01 + (n11 - n01) * u;
		return a + (b - a) * v;
	}

	public function perlinNoise( baseX : Float, baseY : Float, numOctaves : Int, randomSeed : Int, stitch : Bool, fractalNoise : Bool, channelOptions = 7, grayScale = false, ?offsets : Array<Point> ) {
		var chans = [for( c in 0...4 ) (channelOptions & (1 << c)) != 0];
		var vals = [for( c in 0...4 ) new Vector<Float>(width * height)];
		var nch = grayScale ? 1 : 4;
		for( c in 0...nch ) {
			if( !chans[c] ) continue;
			var out = vals[c];
			for( o in 0...numOctaves ) {
				var fx = (1 << o) / Math.max(1., baseX), fy = (1 << o) / Math.max(1., baseY);
				var perX = Std.int(Math.max(1, Math.round(width * fx))), perY = Std.int(Math.max(1, Math.round(height * fy)));
				fx = perX / width;
				fy = perY / height;
				var amp = 1. / (1 << o);
				var seed = randomSeed * 31 + c * 977 + o * 7919;
				for( y in 0...height )
					for( x in 0...width ) {
						var n = gradNoise(x * fx, y * fy, perX, perY, seed);
						out[x + y * width] += (fractalNoise ? n : Math.abs(n) * 2 - 0.5) * amp;
					}
			}
		}
		for( i in 0...width * height ) {
			var v = [0, 0, 0, 0];
			for( c in 0...4 ) {
				var src = (grayScale && c < 3) ? 0 : c;
				if( grayScale && c < 3 ) {
					v[c] = chans[0] ? clamp255((vals[0][i] * 0.5 + 0.5) * 255) : 0;
				} else if( chans[src] )
					v[c] = clamp255((vals[src][i] * 0.5 + 0.5) * 255);
				else
					v[c] = c == 3 ? 255 : 0;
			}
			if( grayScale ) v[3] = chans[3] ? clamp255((vals[3][i] * 0.5 + 0.5) * 255) : 255;
			if( grayScale && !chans[0] ) {
				// sin canal rojo: se usa el primero que haya
				for( c in 1...3 ) if( chans[c] ) {
					var g = clamp255((vals[c][i] * 0.5 + 0.5) * 255);
					v[0] = v[1] = v[2] = g;
					break;
				}
			}
			px[i] = transparent ? ((v[3] << 24) | (v[0] << 16) | (v[1] << 8) | v[2]) : (0xFF000000 | (v[0] << 16) | (v[1] << 8) | v[2]);
		}
	}

	// ------------------------------------------------------------------ filtros

	public function applyFilter( src : BitmapData, srcRect : Rectangle, dest : Point, filter : BitmapFilter ) {
		var sx0 = Std.int(srcRect.x), sy0 = Std.int(srcRect.y), sw = Std.int(srcRect.width), sh = Std.int(srcRect.height);
		var tmp = new BitmapData(sw, sh, true, 0);
		for( y in 0...sh )
			for( x in 0...sw )
				tmp.px[x + y * sw] = src.getPixel32(sx0 + x, sy0 + y);
		var out : BitmapData = null;
		if( Std.isOfType(filter, ColorMatrixFilter) ) out = filterMatrix(tmp, cast filter);
		else if( Std.isOfType(filter, BlurFilter) ) out = filterBlur(tmp, cast filter);
		else if( Std.isOfType(filter, GlowFilter) ) out = filterGlow(tmp, cast filter);
		else if( Std.isOfType(filter, DropShadowFilter) ) out = filterShadow(tmp, cast filter);
		else if( Std.isOfType(filter, DisplacementMapFilter) ) out = filterDisplace(tmp, cast filter);
		else out = tmp;
		var dx0 = Std.int(dest.x), dy0 = Std.int(dest.y);
		for( y in 0...sh )
			for( x in 0...sw ) {
				var dx = dx0 + x, dy = dy0 + y;
				if( dx < 0 || dy < 0 || dx >= width || dy >= height ) continue;
				var c = out.px[x + y * sw];
				px[dx + dy * width] = transparent ? c : (c | 0xFF000000);
			}
	}

	static function filterMatrix( b : BitmapData, f : ColorMatrixFilter ) : BitmapData {
		var m = f.matrix;
		for( i in 0...b.width * b.height ) {
			var c = b.px[i];
			var a = (c >>> 24) & 0xFF, r = (c >> 16) & 0xFF, g = (c >> 8) & 0xFF, bl = c & 0xFF;
			var nr = clamp255(m[0] * r + m[1] * g + m[2] * bl + m[3] * a + m[4]);
			var ng = clamp255(m[5] * r + m[6] * g + m[7] * bl + m[8] * a + m[9]);
			var nb = clamp255(m[10] * r + m[11] * g + m[12] * bl + m[13] * a + m[14]);
			var na = clamp255(m[15] * r + m[16] * g + m[17] * bl + m[18] * a + m[19]);
			b.px[i] = (na << 24) | (nr << 16) | (ng << 8) | nb;
		}
		return b;
	}

	/** desenfoque de caja sobre un plano de floats (relleno de ceros fuera) */
	static function boxBlur( plane : Vector<Float>, w : Int, h : Int, bx : Float, by : Float, quality : Int ) {
		var tmp = new Vector<Float>(Std.int(Math.max(w, h)));
		for( q in 0...Std.int(Math.max(1, quality)) ) {
			var kx = Std.int(Math.max(1, Math.round(bx)));
			if( kx > 1 ) for( y in 0...h ) {
				var sum = 0.;
				var lo = -(kx >> 1), hi = lo + kx - 1;
				for( x in 0...w ) tmp[x] = plane[x + y * w];
				for( x in lo...hi + 1 ) if( x >= 0 && x < w ) sum += tmp[x];
				// ventana [x+lo, x+hi]
				sum = 0;
				for( i in lo...hi + 1 ) if( i >= 0 && i < w ) sum += tmp[i];
				for( x in 0...w ) {
					plane[x + y * w] = sum / kx;
					var rm = x + lo, ad = x + hi + 1;
					if( rm >= 0 && rm < w ) sum -= tmp[rm];
					if( ad >= 0 && ad < w ) sum += tmp[ad];
				}
			}
			var ky = Std.int(Math.max(1, Math.round(by)));
			if( ky > 1 ) for( x in 0...w ) {
				var lo = -(ky >> 1), hi = lo + ky - 1;
				for( y in 0...h ) tmp[y] = plane[x + y * w];
				var sum = 0.;
				for( i in lo...hi + 1 ) if( i >= 0 && i < h ) sum += tmp[i];
				for( y in 0...h ) {
					plane[x + y * w] = sum / ky;
					var rm = y + lo, ad = y + hi + 1;
					if( rm >= 0 && rm < h ) sum -= tmp[rm];
					if( ad >= 0 && ad < h ) sum += tmp[ad];
				}
			}
		}
	}

	static function filterBlur( b : BitmapData, f : BlurFilter ) : BitmapData {
		var w = b.width, h = b.height, n = w * h;
		var pa = new Vector<Float>(n), pr = new Vector<Float>(n), pg = new Vector<Float>(n), pb = new Vector<Float>(n);
		for( i in 0...n ) {
			var c = b.px[i];
			var a = ((c >>> 24) & 0xFF) / 255;
			pa[i] = a;
			pr[i] = ((c >> 16) & 0xFF) * a;
			pg[i] = ((c >> 8) & 0xFF) * a;
			pb[i] = (c & 0xFF) * a;
		}
		for( p in [pa, pr, pg, pb] ) boxBlur(p, w, h, f.blurX, f.blurY, f.quality);
		for( i in 0...n ) {
			var a = pa[i];
			if( a <= 0.0001 ) {
				b.px[i] = 0;
				continue;
			}
			b.px[i] = (clamp255(a * 255 + 0.5) << 24) | (clamp255(pr[i] / a + 0.5) << 16) | (clamp255(pg[i] / a + 0.5) << 8) | clamp255(pb[i] / a + 0.5);
		}
		return b;
	}

	static function glowCommon( b : BitmapData, color : Int, alpha : Float, blurX : Float, blurY : Float, strength : Float, quality : Int, inner : Bool, knockout : Bool, dx : Int, dy : Int, hide : Bool ) : BitmapData {
		var w = b.width, h = b.height, n = w * h;
		var plane = new Vector<Float>(n);
		for( y in 0...h )
			for( x in 0...w ) {
				var sx = x - dx, sy = y - dy;
				var a = (sx < 0 || sy < 0 || sx >= w || sy >= h) ? 0. : ((b.px[sx + sy * w] >>> 24) & 0xFF) / 255;
				plane[x + y * w] = inner ? 1 - a : a;
			}
		boxBlur(plane, w, h, blurX, blurY, quality);
		var cr = (color >> 16) & 0xFF, cg = (color >> 8) & 0xFF, cb = color & 0xFF;
		var out = new BitmapData(w, h, true, 0);
		for( i in 0...n ) {
			var s = b.px[i];
			var sa = (s >>> 24) & 0xFF;
			var ga = Math.min(1., plane[i] * strength) * alpha;
			if( inner ) {
				// el brillo solo cae dentro de la forma
				var g = (clamp255(ga * sa + 0.5) << 24) | (cr << 16) | (cg << 8) | cb;
				var base = (sa << 24) | (s & 0xFFFFFF);
				out.px[i] = knockout ? g : over(base, g);
			} else {
				var g = (clamp255(ga * 255 + 0.5) << 24) | (cr << 16) | (cg << 8) | cb;
				if( knockout ) out.px[i] = sa == 0 ? g : over(g, (clamp255(0) << 24));
				else out.px[i] = hide ? g : over(g, s);
			}
		}
		return out;
	}

	static function filterGlow( b : BitmapData, f : GlowFilter ) : BitmapData
		return glowCommon(b, f.color, f.alpha, f.blurX, f.blurY, f.strength, f.quality, f.inner, f.knockout, 0, 0, false);

	static function filterShadow( b : BitmapData, f : DropShadowFilter ) : BitmapData {
		var a = f.angle * Math.PI / 180;
		return glowCommon(b, f.color, f.alpha, f.blurX, f.blurY, f.strength, f.quality, f.inner, f.knockout, Math.round(Math.cos(a) * f.distance), Math.round(Math.sin(a) * f.distance), f.hideObject);
	}

	static function filterDisplace( b : BitmapData, f : DisplacementMapFilter ) : BitmapData {
		var w = b.width, h = b.height;
		var out = new BitmapData(w, h, true, 0);
		var m = f.mapBitmap;
		var mx = Std.int(f.mapPoint.x), my = Std.int(f.mapPoint.y);
		var sx = shiftOf(f.componentX), sy = shiftOf(f.componentY);
		var wrap = f.mode == "wrap";
		for( y in 0...h )
			for( x in 0...w ) {
				var mc = m.getPixel32(x - mx, y - my);
				var vx = (mc >> sx) & 0xFF, vy = (mc >> sy) & 0xFF;
				var ox = Math.floor(x + (vx - 128) * f.scaleX / 256), oy = Math.floor(y + (vy - 128) * f.scaleY / 256);
				if( wrap ) {
					ox = ((ox % w) + w) % w;
					oy = ((oy % h) + h) % h;
				} else if( ox < 0 || oy < 0 || ox >= w || oy >= h ) {
					out.px[x + y * w] = b.px[x + y * w];
					continue;
				}
				out.px[x + y * w] = b.px[ox + oy * w];
			}
		return out;
	}

	// ------------------------------------------------------------------ dibujar

	public function draw( source : Dynamic, ?matrix : Matrix, ?ct : ColorTransform, ?blendMode : BlendMode, ?clipRect : Rectangle, smoothing = false ) {
		var m = matrix != null ? matrix.clone() : new Matrix();
		var mode = blendMode != null ? blendMode : BlendMode.NORMAL;
		if( Std.isOfType(source, BitmapData) ) drawBitmap(cast source, m, ct, mode, smoothing);
		else if( Std.isOfType(source, Sprite) ) drawSprite(cast source, m, ct, mode, 1);
	}

	function put( x : Int, y : Int, c : Int, mode : BlendMode ) {
		var i = x + y * width;
		var o = blendPix(mode, px[i], c);
		px[i] = transparent ? o : (o | 0xFF000000);
	}

	function drawBitmap( src : BitmapData, m : Matrix, ct : ColorTransform, mode : BlendMode, smoothing : Bool ) {
		var inv = m.clone();
		inv.invert();
		// caja de destino
		var xs = [m.transformX(0, 0), m.transformX(src.width, 0), m.transformX(0, src.height), m.transformX(src.width, src.height)];
		var ys = [m.transformY(0, 0), m.transformY(src.width, 0), m.transformY(0, src.height), m.transformY(src.width, src.height)];
		var x0 = Std.int(Math.max(0, Math.floor(Math.min(Math.min(xs[0], xs[1]), Math.min(xs[2], xs[3]))))), x1 = Std.int(Math.min(width, Math.ceil(Math.max(Math.max(xs[0], xs[1]), Math.max(xs[2], xs[3])))));
		var y0 = Std.int(Math.max(0, Math.floor(Math.min(Math.min(ys[0], ys[1]), Math.min(ys[2], ys[3]))))), y1 = Std.int(Math.min(height, Math.ceil(Math.max(Math.max(ys[0], ys[1]), Math.max(ys[2], ys[3])))));
		var simple = m.a == 1 && m.d == 1 && m.b == 0 && m.c == 0;
		for( y in y0...y1 )
			for( x in x0...x1 ) {
				var u = inv.transformX(x + 0.5, y + 0.5), v = inv.transformY(x + 0.5, y + 0.5);
				var ix = Math.floor(u), iy = Math.floor(v);
				if( ix < 0 || iy < 0 || ix >= src.width || iy >= src.height ) continue;
				var c = src.px[ix + iy * src.width];
				if( ct != null ) c = applyCT(c, ct);
				if( !src.transparent ) c |= 0xFF000000;
				put(x, y, c, mode);
			}
	}

	function drawSprite( s : Sprite, parent : Matrix, ct : ColorTransform, mode : BlendMode, alpha : Float ) {
		if( !s.visible ) return;
		var m = new Matrix();
		m.scale(s.scaleX, s.scaleY);
		m.rotate(s.rotation * Math.PI / 180);
		m.translate(s.x, s.y);
		m.concat(parent);
		var al = alpha * s.alpha;
		var md = s.blendMode != BlendMode.NORMAL ? s.blendMode : mode;
		for( sh in s.graphics.shapes ) drawShape(sh, m, ct, md, al);
		for( c in s.children ) drawSprite(c, m, ct, md, al);
	}

	function shade( color : Int, a : Float, ct : ColorTransform ) : Int {
		var c = (clamp255(a * 255 + 0.5) << 24) | (color & 0xFFFFFF);
		return ct != null ? applyCT(c, ct) : c;
	}

	function drawShape( sh : GShape, m : Matrix, ct : ColorTransform, mode : BlendMode, al : Float ) {
		switch( sh ) {
		case GCircle(cx, cy, r, color, a):
			var sc = Math.sqrt(Math.abs(m.a * m.d - m.b * m.c));
			var px0 = m.transformX(cx, cy), py0 = m.transformY(cx, cy), rr = r * sc;
			var x0 = Std.int(Math.max(0, Math.floor(px0 - rr - 1))), x1 = Std.int(Math.min(width, Math.ceil(px0 + rr + 1)));
			var y0 = Std.int(Math.max(0, Math.floor(py0 - rr - 1))), y1 = Std.int(Math.min(height, Math.ceil(py0 + rr + 1)));
			for( y in y0...y1 )
				for( x in x0...x1 ) {
					var d = Math.sqrt((x + 0.5 - px0) * (x + 0.5 - px0) + (y + 0.5 - py0) * (y + 0.5 - py0));
					var cov = rr - d + 0.5;
					if( cov <= 0 ) continue;
					if( cov > 1 ) cov = 1;
					put(x, y, shade(color, a * al * cov, ct), mode);
				}
		case GRect(rx, ry, rw, rh, color, a):
			var inv = m.clone();
			inv.invert();
			var xs = [m.transformX(rx, ry), m.transformX(rx + rw, ry), m.transformX(rx, ry + rh), m.transformX(rx + rw, ry + rh)];
			var ys = [m.transformY(rx, ry), m.transformY(rx + rw, ry), m.transformY(rx, ry + rh), m.transformY(rx + rw, ry + rh)];
			var x0 = Std.int(Math.max(0, Math.floor(Math.min(Math.min(xs[0], xs[1]), Math.min(xs[2], xs[3]))))), x1 = Std.int(Math.min(width, Math.ceil(Math.max(Math.max(xs[0], xs[1]), Math.max(xs[2], xs[3])))));
			var y0 = Std.int(Math.max(0, Math.floor(Math.min(Math.min(ys[0], ys[1]), Math.min(ys[2], ys[3]))))), y1 = Std.int(Math.min(height, Math.ceil(Math.max(Math.max(ys[0], ys[1]), Math.max(ys[2], ys[3])))));
			for( y in y0...y1 )
				for( x in x0...x1 ) {
					var u = inv.transformX(x + 0.5, y + 0.5), v = inv.transformY(x + 0.5, y + 0.5);
					if( u < rx || v < ry || u >= rx + rw || v >= ry + rh ) continue;
					put(x, y, shade(color, a * al, ct), mode);
				}
		case GLine(x0, y0, x1, y1, lw, color, a):
			var ax = m.transformX(x0, y0), ay = m.transformY(x0, y0), bx = m.transformX(x1, y1), by = m.transformY(x1, y1);
			var sc = Math.sqrt(Math.abs(m.a * m.d - m.b * m.c));
			var half = Math.max(0.5, lw * sc * 0.5);
			var minx = Std.int(Math.max(0, Math.floor(Math.min(ax, bx) - half - 1))), maxx = Std.int(Math.min(width, Math.ceil(Math.max(ax, bx) + half + 1)));
			var miny = Std.int(Math.max(0, Math.floor(Math.min(ay, by) - half - 1))), maxy = Std.int(Math.min(height, Math.ceil(Math.max(ay, by) + half + 1)));
			var dx = bx - ax, dy = by - ay;
			var l2 = dx * dx + dy * dy;
			for( y in miny...maxy )
				for( x in minx...maxx ) {
					var t = l2 == 0 ? 0 : ((x + 0.5 - ax) * dx + (y + 0.5 - ay) * dy) / l2;
					t = t < 0 ? 0 : (t > 1 ? 1 : t);
					var qx = ax + dx * t, qy = ay + dy * t;
					var d = Math.sqrt((x + 0.5 - qx) * (x + 0.5 - qx) + (y + 0.5 - qy) * (y + 0.5 - qy));
					var cov = half - d + 0.5;
					if( cov <= 0 ) continue;
					if( cov > 1 ) cov = 1;
					put(x, y, shade(color, a * al * cov, ct), mode);
				}
		}
	}

	/** no se usa: solo para que compile Color.hx de deepnight */
	public function compare( o : BitmapData ) : Dynamic return 0;

	/** bytes ARGB de un rectangulo (uno por posicion) */
	public function getPixels( r : Rectangle ) : Vector<Int> {
		var w = Std.int(r.width), h = Std.int(r.height);
		var v = new Vector<Int>(w * h * 4);
		var i = 0;
		for( y in 0...h )
			for( x in 0...w ) {
				var c = getPixel32(Std.int(r.x) + x, Std.int(r.y) + y);
				v[i++] = (c >>> 24) & 0xFF;
				v[i++] = (c >> 16) & 0xFF;
				v[i++] = (c >> 8) & 0xFF;
				v[i++] = c & 0xFF;
			}
		return v;
	}

	public function setPixels( r : Rectangle, v : Dynamic ) {}
}
