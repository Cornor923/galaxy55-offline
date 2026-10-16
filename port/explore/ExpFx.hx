/** Curvas de mt.deepnight.Tweenie (las que usa el explorador) */
enum ExpEase {
	TLinear;
	TEase;
	TEaseIn;
	TEaseOut;
	TBurnIn;
}

class ExpTween {
	public var obj : Dynamic;
	public var field : String;
	public var from : Float;
	public var to : Float;
	public var ln = 0.;
	public var speed : Float;
	public var ease : ExpEase;
	public var onUpdateT : Float -> Void;
	public var onEnd : Void -> Void;
	public function new() {}
}

/**
 * Copia de mt.deepnight.Tweenie: un valor va de su estado actual a `to` en `ms` milisegundos (a 30 fotogramas por segundo,
 * como el original) con una curva de Bezier. Crear otro sobre la misma variable sustituye al anterior.
 * `delay` sustituye a los haxe.Timer.delay del original.
 */
class ExpTweens {
	var list : Array<ExpTween> = [];
	var delays : Array<{ t : Float, cb : Void -> Void }> = [];

	public function new() {}

	static inline function bezier( t : Float, p0 : Float, p1 : Float, p2 : Float, p3 : Float ) {
		return (1 - t) * (1 - t) * (1 - t) * p0 + 3 * t * (1 - t) * (1 - t) * p1 + 3 * t * t * (1 - t) * p2 + t * t * t * p3;
	}

	static function interp( e : ExpEase, t : Float ) : Float {
		return switch( e ) {
		case TLinear: t;
		case TEase: bezier(t, 0, 0, 1, 1);
		case TEaseIn: bezier(t, 0, 0, 0.5, 1);
		case TEaseOut: bezier(t, 0, 0.5, 1, 1);
		case TBurnIn: bezier(t, 0, 1, 1, 1);
		}
	}

	public function create( obj : Dynamic, field : String, to : Float, ?ease : ExpEase, ms = 250. ) : ExpTween {
		if( ease == null ) ease = TEase;
		var found : ExpEase = null;
		for( t in list.copy() )
			if( t.obj == obj && t.field == field ) {
				found = t.ease;
				list.remove(t);
			}
		if( found != null && ease == TEase && (found == TEase || found == TEaseOut) ) ease = TEaseOut;
		var t = new ExpTween();
		t.obj = obj;
		t.field = field;
		t.from = Reflect.getProperty(obj, field);
		t.to = to;
		t.ease = ease;
		t.speed = 1 / (ms * 30 / 1000);
		if( t.from == t.to ) t.ln = 1;
		list.push(t);
		return t;
	}

	public function delay( ms : Float, cb : Void -> Void ) {
		delays.push({ t : ms, cb : cb });
	}

	public function terminate( obj : Dynamic, ?field : String ) {
		for( t in list.copy() )
			if( t.obj == obj && (field == null || t.field == field) ) finish(t);
	}

	function finish( t : ExpTween ) {
		list.remove(t);
		Reflect.setProperty(t.obj, t.field, t.from + (t.to - t.from) * interp(t.ease, 1));
		if( t.onUpdateT != null ) t.onUpdateT(1);
		if( t.onEnd != null ) {
			var cb = t.onEnd;
			t.onEnd = null;
			cb();
		}
	}

	public function update( tmod : Float ) {
		var ms = tmod * 1000 / 30;
		for( d in delays.copy() ) {
			d.t -= ms;
			if( d.t <= 0 ) {
				delays.remove(d);
				d.cb();
			}
		}
		for( t in list.copy() ) {
			if( list.indexOf(t) < 0 ) continue;
			t.ln += t.speed * tmod;
			if( t.ln < 1 ) {
				Reflect.setProperty(t.obj, t.field, t.from + interp(t.ease, t.ln) * (t.to - t.from));
				if( t.onUpdateT != null ) t.onUpdateT(t.ln);
			} else
				finish(t);
		}
	}

	public function clear() {
		list = [];
		delays = [];
	}
}

/**
 * Copia de mt.deepnight.Particle (lo que usa el explorador): velocidad, friccion, vida en fotogramas; al acabar la vida se
 * desvanece (alfa -0.1 por fotograma) y desaparece. Los GlowFilter del original se imitan con un halo suave aditivo.
 */
class ExpPart extends h2d.Object {
	public static var ALL : Array<ExpPart> = [];
	static var glowTex : h3d.mat.Texture;

	public var dx = 0.;
	public var dy = 0.;
	public var gx = 0.;
	public var gy = 0.;
	public var frictX = 0.95;
	public var frictY = 0.97;
	public var rlife : Float;
	public var maxLife : Float;
	public var onUpdate : Void -> Void;
	public var rx : Float;
	public var ry : Float;

	public function new( parent : h2d.Object, x : Float, y : Float ) {
		super(parent);
		rx = x;
		ry = y;
		this.x = x;
		this.y = y;
		frictX = 0.95 + Std.random(40) / 1000;
		setLife(32 + Std.random(32));
		ALL.push(this);
	}

	public function setLife( l : Float ) {
		if( l < 0 ) l = 0;
		rlife = l;
		maxLife = l;
	}

	public inline function time() return 1 - (rlife + alpha) / (maxLife + 1);
	public inline function getSpeed() return Math.sqrt(dx * dx + dy * dy);

	/** Particle.drawBox, con un halo del color del GlowFilter (null = sin halo) */
	public function drawBox( w : Float, h : Float, col : Int, a = 1.0, ?glow : Int, glowSize = 8. ) {
		removeChildren();
		if( glow != null ) {
			var g = new h2d.Bitmap(h2d.Tile.fromTexture(glowTexture()), this);
			g.blendMode = Add;
			g.color.set(((glow >> 16) & 0xFF) / 255, ((glow >> 8) & 0xFF) / 255, (glow & 0xFF) / 255, 1);
			g.scaleX = (w + glowSize * 2) / 32;
			g.scaleY = (h + glowSize * 2) / 32;
			g.x = -Std.int(w / 2) - glowSize;
			g.y = -Std.int(h / 2) - glowSize;
		}
		var b = new h2d.Bitmap(h2d.Tile.fromColor(col, Std.int(Math.max(1, w)), Std.int(Math.max(1, h)), a), this);
		b.blendMode = Add;
		b.x = -Std.int(w / 2);
		b.y = -Std.int(h / 2);
	}

	/** linea de 1 pixel de largo `len` desde el origen (graphics.lineTo(len, 0) con LineScaleMode.NONE) */
	public function drawLine( len : Float, col : Int, ?glow : Int ) {
		removeChildren();
		if( glow != null ) {
			var g = new h2d.Bitmap(h2d.Tile.fromTexture(glowTexture()), this);
			g.blendMode = Add;
			g.color.set(((glow >> 16) & 0xFF) / 255, ((glow >> 8) & 0xFF) / 255, (glow & 0xFF) / 255, 1);
			g.scaleX = (len + 8) / 32;
			g.scaleY = 9 / 32;
			g.x = -4;
			g.y = -4.5;
		}
		var b = new h2d.Bitmap(h2d.Tile.fromColor(col, 1, 1, 1), this);
		b.blendMode = Add;
		b.scaleX = len;
		b.y = -0.5;
	}

	/** halo: un cuadrado con borde suave, que se estira a la caja */
	static function glowTexture() {
		if( glowTex != null ) return glowTex;
		var px = hxd.Pixels.alloc(32, 32, BGRA);
		for( y in 0...32 )
			for( x in 0...32 ) {
				var fx = Math.min(x + 0.5, 32 - x - 0.5) / 16, fy = Math.min(y + 0.5, 32 - y - 0.5) / 16;
				var a = Math.pow(Math.min(1, fx * 1.6) * Math.min(1, fy * 1.6), 1.5) * 0.85;
				px.bytes.setInt32((x + y * 32) * 4, (Std.int(a * 255) << 24) | 0xFFFFFF);
			}
		glowTex = new h3d.mat.Texture(32, 32);
		glowTex.uploadPixels(px);
		glowTex.filter = Linear;
		return glowTex;
	}

	/** Particle.update */
	public static function updateAll( tmod : Float ) {
		var i = 0;
		while( i < ALL.length ) {
			var p = ALL[i];
			p.dx += tmod * p.gx;
			p.dy += tmod * p.gy;
			p.dx *= Math.pow(p.frictX, tmod);
			p.dy *= Math.pow(p.frictY, tmod);
			p.rx += tmod * p.dx;
			p.ry += tmod * p.dy;
			p.x = p.rx;
			p.y = p.ry;
			p.rlife -= tmod;
			if( p.rlife <= 0 ) p.alpha -= 0.1 * tmod;
			if( p.rlife <= 0 && p.alpha <= 0 ) {
				p.remove();
				ALL.splice(i, 1);
			} else {
				if( p.onUpdate != null ) p.onUpdate();
				i++;
			}
		}
	}

	public static function clearAll() {
		for( p in ALL ) p.remove();
		ALL = [];
	}
}

/** Manager.novaFx: circulo blanco con brillo interior del color de los reactores y bordes desenfocados */
class ExpNova {
	static var cache = new Map<Int, h3d.mat.Texture>();

	public static function tile( radius : Int, glow : Int ) : h2d.Tile {
		var tex = cache.get(radius);
		if( tex == null ) {
			var m = 8, w = radius * 2 + m * 2;
			var px = hxd.Pixels.alloc(w, w, BGRA);
			var gr = (glow >> 16) & 0xFF, gg = (glow >> 8) & 0xFF, gb = glow & 0xFF;
			for( y in 0...w )
				for( x in 0...w ) {
					var d = Math.sqrt((x + 0.5 - w * 0.5) * (x + 0.5 - w * 0.5) + (y + 0.5 - w * 0.5) * (y + 0.5 - w * 0.5));
					// borde desenfocado (BlurFilter 4) y brillo interior de 16 px (GlowFilter interior)
					var a = Math.max(0, Math.min(1, (radius + 2 - d) / 4));
					var k = Math.max(0, Math.min(1, (d - (radius - 16)) / 16));
					var r = Std.int(255 + (gr - 255) * k), g = Std.int(255 + (gg - 255) * k), b = Std.int(255 + (gb - 255) * k);
					px.bytes.setInt32((x + y * w) * 4, (Std.int(a * 255) << 24) | (r << 16) | (g << 8) | b);
				}
			tex = new h3d.mat.Texture(w, w);
			tex.uploadPixels(px);
			tex.filter = Linear;
			cache.set(radius, tex);
		}
		return h2d.Tile.fromTexture(tex).center();
	}
}
