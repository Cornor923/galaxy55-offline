import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.ColorTransform;
import mt.deepnight.Color;

/** Una capa con paralaje (ZLayer del original, sin la lista de visualizacion de Flash). */
class ExpLayer {
	public var bd : BitmapData;
	public var z : Float;
	public var repeat : Bool;
	public var scaleX : Float;
	public var scaleY : Float;
	public var xOffset = 0.;
	public var yOffset = 0.;
	/** se mezcla en aditivo (por defecto) o normal (las estrellas) */
	public var additive = true;
	public var alpha = 1.;
	public var hideZoom = false;
	public var texWid : Int;
	public var texHei : Int;

	public function new( room : ExpRoom, tex : BitmapData, z : Float, repeat = false, scaleX = 1., ?scaleY : Float ) {
		this.z = z;
		this.repeat = repeat;
		this.scaleX = scaleX;
		this.scaleY = scaleY == null ? scaleX : scaleY;
		texWid = tex.width;
		texHei = tex.height;
		if( repeat ) {
			// el original rellena un bitmap mayor que la pantalla con copias de la textura
			var w = Math.ceil(1 + room.viewW / texWid), h = Math.ceil(1 + room.viewH / texHei);
			bd = new BitmapData(texWid * w, texHei * h, true, 0);
			for( x in 0...w )
				for( y in 0...h )
					bd.copyPixels(tex, tex.rect, new Point(x * texWid, y * texHei));
			tex.dispose();
		} else
			bd = tex;
		room.layers.push(this);
	}
}

/**
 * Habitacion del explorador (Room.hx del original): genera los fondos de un sector. Las funciones de bitmaps (estrellas, nubes,
 * galaxias) son copia de las originales; solo cambia donde se dibuja el resultado.
 */
class ExpRoom {
	public static var STAR_COLORS = [0xE1BD7B, 0xF1B49E, 0xFFFFBB, 0xFFB0B0];
	public static var BG_COLORS = [0x368189, 0x326C89, 0x3D4285, 0xC16233, 0x77559F, 0xAB6FAC, 0x8B3F3F, 0x916339];
	public static var GALAXY_COLORS = [0xAB7154, 0xAA0000, 0xCC6133, 0xAD942C, 0x8A56A9, 0xBE4183, 0x314E79, 0x6480CA, 0x2D99AC];
	public static var GRID_WID = 32;

	public var seed : Int;
	public var rseed : mt.Rand;
	public var pt0 : Point;
	public var quality = 1.;
	public var viewW : Int;
	public var viewH : Int;
	public var width : Int;
	public var height : Int;
	public var center : Point;
	public var starColor : Int;
	public var bgColor : Int;
	public var galaxyColors : Array<Int>;
	public var layers : Array<ExpLayer> = [];

	public function new( s : Int, viewW = 900, viewH = 450 ) {
		seed = s;
		this.viewW = viewW;
		this.viewH = viewH;
		rseed = new mt.Rand(seed);
		rseed.initSeed(seed);
		pt0 = new Point(0, 0);
		setSize(2200, 2200);
		starColor = STAR_COLORS[rseed.random(STAR_COLORS.length)];
		bgColor = BG_COLORS[rseed.random(BG_COLORS.length)];
		initRandom();
	}

	function setSize( w : Int, h : Int ) {
		width = height = w;
		center = new Point(width * 0.5, height * 0.5);
	}

	function initRandom( ?seed2 = 0.0 ) {
		rseed.initSeed(seed + Std.int(seed2));
	}

	// ---------------------------------------------------------------- fondos

	function makeStarfield( bd : BitmapData, density : Float, wid : Int, margin : Int ) {
		var n = Std.int(density * 0.0015 * bd.width * bd.height * 1 / quality);
		for( i in 0...n )
			bd.fillRect(new Rectangle(margin + rseed.random(bd.width - margin * 2), margin + rseed.random(bd.height - margin * 2), wid, wid), Color.addAlphaChannel(0x808080, rseed.random(64) + 192));
	}

	public function initStars( density : Float ) {
		initRandom();
		var w = 450;
		var zmin = 0.1;
		var zmax = 0.4;
		var n = Math.ceil(6 * quality);
		var zeds = [];
		for( i in 0...n )
			zeds.push(Math.round((zmin + (i / (n - 1)) * (zmax - zmin)) * 100) / 100);
		for( z in zeds ) {
			var sf = new BitmapData(w, w, true, 0x0);
			makeStarfield(sf, density * (0.1 + 1 - z / zmax), Math.round(2 * z / zmax), 4);
			var l = new ExpLayer(this, sf, z, true);
			l.additive = false;
			var bd = l.bd;
			bd.colorTransform(bd.rect, new ColorTransform(1, 1, 1, z / (zmax * 1.3)));
			var c = Color.interpolateInt(bgColor, starColor, z / zmax);
			bd.applyFilter(bd, bd.rect, pt0, Color.getColorizeMatrixFilter(c, 1, 0));
			bd.applyFilter(bd, bd.rect, pt0, new flash.filters.GlowFilter(c, 1, 2, 2, 2, 2));
			bd.applyFilter(bd, bd.rect, pt0, new flash.filters.GlowFilter(c, z / zmax, 8, 8, 2, 2));
		}
	}

	public function initClouds( col : Int, zeds : Array<Float> ) {
		initRandom(col);
		var w = Std.int(200 + 250 * 1 / 1);
		var noise = new BitmapData(w, w, true, 0x0);
		noise.noise(1, 0x60, 0xb0, 7, true);
		noise.colorTransform(noise.rect, new ColorTransform(1, 1, 1, 0.15 + rseed.rand() * 0.15));
		for( z in zeds ) {
			var perlin = new BitmapData(w, w, true, 0x0);
			var pw = Std.int(w * 0.2 + w * 0.3 * z);
			perlin.perlinNoise(pw, pw, 2, rseed.random(99999), true, true, 1, true);
			perlin.draw(noise, null, new ColorTransform(1, 1, 1, 0.3));
			var cut = 0.5;
			var thr = Color.rgbaToInt({ r : Std.int(255 * cut), g : 0, b : 0, a : 255 });
			perlin.threshold(perlin, perlin.rect, pt0, "<=", thr, 0x0, 0xffff0000, true);
			perlin.colorTransform(perlin.rect, new ColorTransform(1, 1, 1, 1, -255 * cut, -255 * cut, -255 * cut));
			var f = Color.getColorizeMatrixFilter(col, 0.5, 0);
			perlin.applyFilter(perlin, perlin.rect, new Point(0, 0), f);
			new ExpLayer(this, perlin, z, true);
		}
		noise.dispose();
	}

	function safePerlinSeed( rseed : mt.Rand ) {
		var bug = [346, 514, 1155, 1519, 1690, 1977, 2327, 2337, 2399, 2860, 2999, 3099, 4777, 4952, 5673, 6265, 7185, 7259, 7371, 7383, 7717, 7847, 8032, 8350, 8676, 8963, 8997, 9080, 9403, 9615, 9685];
		var h = new Map<Int, Bool>();
		for( b in bug ) h.set(b, true);
		var s = rseed.random(9999);
		while( h.exists(s) ) s = rseed.random(9999);
		return s;
	}

	public function makeGalaxyCloud( size : Float ) {
		var w = Math.ceil(500 * size);
		var h = Math.ceil(500 * size);
		var disp = Std.int(size * (rseed.random(64) + 64));

		// base
		var galaxy = new BitmapData(w, h, true, 0x0);
		var s = safePerlinSeed(rseed);
		var pw = size * (rseed.random(32) + 16);
		galaxy.perlinNoise(pw, pw, 3, s, false, true, 7, true);
		var distort = new BitmapData(w, h, false, 0xffffff);
		var pw = size * (rseed.random(16) + 32);
		distort.perlinNoise(pw, pw, 1, safePerlinSeed(rseed), false, true, 7, true);
		galaxy.applyFilter(galaxy, galaxy.rect, new Point(0, 0), new flash.filters.DisplacementMapFilter(distort, pt0, flash.display.BitmapDataChannel.RED, flash.display.BitmapDataChannel.RED, rseed.random(32), rseed.random(32), flash.filters.DisplacementMapFilterMode.WRAP));
		distort.dispose();

		// mascara de base
		var mask = new BitmapData(w, h, true, 0x0);
		var sp = new flash.display.Sprite();
		var g = sp.graphics;
		var blur = Std.int(size * (rseed.random(48) + 16));
		var margin = Std.int(0.5 * (blur + disp));
		for( i in 0...Math.ceil(size * 15) ) {
			g.clear();
			g.beginFill(0xffffff, 0.2 + rseed.rand() * 0.8);
			var r = Math.ceil(size * (rseed.random(16) + 32));
			g.drawCircle(margin + r + rseed.random(mask.width - r * 2 - margin * 2), margin + r + rseed.random(mask.height - r * 2 - margin * 2), r);
			mask.draw(sp);
		}
		mask.applyFilter(mask, mask.rect, pt0, new flash.filters.BlurFilter(blur, blur, 2));

		// distorsion
		var distort = new BitmapData(w, h, false, 0xffffff);
		var pw = size * (rseed.random(16) + 32);
		distort.perlinNoise(pw, pw, 1, safePerlinSeed(rseed), false, true, 7, true);
		mask.applyFilter(mask, mask.rect, new Point(0, 0), new flash.filters.DisplacementMapFilter(distort, pt0, flash.display.BitmapDataChannel.RED, flash.display.BitmapDataChannel.RED, disp, disp, flash.filters.DisplacementMapFilterMode.WRAP));
		distort.dispose();

		// enmascarado
		galaxy.copyChannel(mask, mask.rect, pt0, flash.display.BitmapDataChannel.ALPHA, flash.display.BitmapDataChannel.ALPHA);
		mask.dispose();

		// ruido
		var noise = new BitmapData(w, h, true, 0x0);
		noise.noise(1, 0x60, 0xb0, 7, true);
		noise.colorTransform(noise.rect, new ColorTransform(1, 1, 1, 0.15 + rseed.rand() * 0.15));
		galaxy.copyPixels(noise, galaxy.rect, pt0, galaxy, pt0, true);
		noise.dispose();

		var gcol = galaxyColors.splice(rseed.random(galaxyColors.length), 1)[0];
		galaxy.applyFilter(galaxy, galaxy.rect, pt0, Color.getColorizeMatrixFilter(gcol, 0.6, 0.4));
		return galaxy;
	}

	/** fondo del sector: estrellas, nubes y tres capas de galaxia (Room.generateSector, parte de fondos) */
	public function generateSectorBackground( widthCells = 50, heightCells = 50 ) {
		setSize(widthCells * GRID_WID, heightCells * GRID_WID);
		initStars(1);
		initClouds(bgColor, [0.7, 0.4]);
		initRandom();
		galaxyColors = GALAXY_COLORS.copy();
		var size = quality * 0.8 + 0.2;
		var scale = rseed.rand() * 1 + 1.25;
		scale += 1 / size - 1;
		for( z in [1, 0.75, 0.65] ) {
			var g = makeGalaxyCloud(size + rseed.rand() * 0.3);
			g.colorTransform(g.rect, new ColorTransform(1, 1, 1, 0.6 + (1 - quality) * 0.3));
			var l = new ExpLayer(this, g, z, false, scale);
			l.xOffset = center.x;
			l.yOffset = center.y;
		}
	}

	// ---------------------------------------------------------------- composicion (ZLayer.update + snapshot) para pruebas

	/** dibuja las capas como se verian con la camara en (vx, vy) */
	public function compose( out : BitmapData, vx : Float, vy : Float ) {
		var sorted = layers.copy();
		sorted.sort(function(a, b) return Reflect.compare(a.z, b.z));
		for( l in sorted ) {
			var z = l.z;
			var x = viewW * 0.5 * (1 - z) - l.texWid * 0.5 + (viewW * 0.5 + l.xOffset - vx) * z;
			var y = viewH * 0.5 * (1 - z) - l.texHei * 0.5 + (viewH * 0.5 + l.yOffset - vy) * z;
			var m = new flash.geom.Matrix();
			if( l.repeat ) {
				while( x > 0 ) x -= l.texWid;
				while( x + l.texWid < 0 ) x += l.texWid;
				while( y > 0 ) y -= l.texHei;
				while( y + l.texHei < 0 ) y += l.texHei;
				m.translate(Math.round(x), Math.round(y));
			} else {
				// escala alrededor del centro del bitmap, como en ZLayer
				m.translate(-l.bd.width * 0.5, -l.bd.height * 0.5);
				m.scale(l.scaleX, l.scaleY);
				m.translate(l.bd.width * 0.5, l.bd.height * 0.5);
				m.translate(Math.round(x), Math.round(y));
			}
			out.draw(l.bd, m, null, l.additive ? flash.display.BlendMode.ADD : flash.display.BlendMode.NORMAL);
		}
	}
}
