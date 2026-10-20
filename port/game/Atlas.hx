import Common;

/**
 * Atlas de texturas con los mismos parches que Render.init() del original:
 * - BFColor: los bloques sin textura reciben una casilla del final del atlas (4095, 4094, ...) rellena con su color.
 * - BFAlpha: se multiplica la opacidad de las casillas del bloque (una vez por casilla distinta).
 * Los bloques liquidos con BFAlpha usan la misma cascada de opacidad que el original.
 */
class Atlas {

	static inline var LIQUID_ALPHA = 0.55;
	static var patched = false;

	/** pixeles del ultimo atlas construido: para apuntar a las plantas por lo que se ve (GameView.modelHit) */
	public static var pixels(default, null) : hxd.Pixels;

	public static function build( png : haxe.io.Bytes ) : h3d.mat.Texture {
		var pix = hxd.res.Any.fromBytes("texture.png", png).toImage().getPixels();
		if( !patched ) {
			patched = true;
			patch(pix);
		} else
			patch(pix, true);
		pix.convert(RGBA); // DirectX no acepta BGRA
		pixels = pix;
		var t = h3d.mat.Texture.fromPixels(pix);
		t.filter = Nearest;
		t.mipMap = None;
		return t;
	}

	static function fillTile( pix : hxd.Pixels, tile : Int, argb : Int ) {
		var tx = (tile & 63) << 5, ty = (tile >> 6) << 5;
		for( y in 0...32 )
			for( x in 0...32 )
				pix.setPixel(tx + x, ty + y, argb);
	}

	static function scaleTile( pix : hxd.Pixels, b : Block, alpha : Float ) {
		var done = [];
		for( t in [b.tu, b.td, b.tlr] ) {
			if( t < 0 || t > 4095 || done.indexOf(t) >= 0 ) continue;
			done.push(t);
			var tx = (t & 63) << 5, ty = (t >> 6) << 5;
			for( y in 0...32 )
				for( x in 0...32 ) {
					var c = pix.getPixel(tx + x, ty + y);
					var a = Std.int((c >>> 24) * alpha);
					pix.setPixel(tx + x, ty + y, (a << 24) | (c & 0xFFFFFF));
				}
		}
	}

	/** Si ya se asignaron las casillas de color (segunda vez), solo se repinta el atlas nuevo con las mismas casillas. */
	/**
	 * Texturas de los bloques de la nave nodriza (anadido del port): versiones en gris de casillas del original,
	 * pintadas en casillas vacias del atlas (las que indica DataGen para BMother*).
	 */
	static function motherTiles( pix : hxd.Pixels ) {
		inline function tileOf( k : BlockKind ) return Block.get(k).tlr;
		var jobs = [
			{ dst : tileOf(BMotherHull), src : tileOf(BShedWall), k : 1.25, add : 8 },
			{ dst : tileOf(BMotherPanel), src : tileOf(BShipHull), k : 0.95, add : 0 },
			{ dst : tileOf(BMotherDark), src : tileOf(BShedWall), k : 0.6, add : 18 }, // gris oscuro como la pizarra profunda de Minecraft (antes se veia negro)
		];
		// blindaje amarillo y negro (para franjas de peligro): el mismo metal del casco, teñido
		var tints = [
			{ dst : tileOf(BMotherYellow), r : 1.0, g : 0.78, b : 0.08, k : 1.15, add : 40 },
			{ dst : tileOf(BMotherBlack), r : 1.0, g : 1.0, b : 1.04, k : 0.28, add : 6 },
		];
		var src = tileOf(BShipHull);
		for( t in tints ) {
			var sx = (src & 63) << 5, sy = (src >> 6) << 5;
			var dx = (t.dst & 63) << 5, dy = (t.dst >> 6) << 5;
			for( y in 0...32 )
				for( x in 0...32 ) {
					var c = pix.getPixel(sx + x, sy + y);
					var l = (((c >> 16) & 0xFF) * 0.3 + ((c >> 8) & 0xFF) * 0.59 + (c & 0xFF) * 0.11) * t.k + t.add;
					inline function ch( v : Float ) return Std.int(Math.max(0, Math.min(255, v)));
					pix.setPixel(dx + x, dy + y, 0xFF000000 | (ch(l * t.r) << 16) | (ch(l * t.g) << 8) | ch(l * t.b));
				}
		}
		// campo de fuerza de los hangares (añadido del port): deja pasar las naves pero no el vacio. Azul translucido con
		// rayos laser horizontales; las lineas son solo horizontales para que no se vean juntas de bloque
		var ft = tileOf(BMotherField);
		var fx0 = (ft & 63) << 5, fy0 = (ft >> 6) << 5;
		for( y in 0...32 )
			for( x in 0...32 ) {
				var c = switch( y & 7 ) {
					case 0: 0xC8B4F0FF;            // rayo
					case 1, 7: 0x7050C8FF;         // halo del rayo
					default: 0x302878E0;           // campo
				};
				pix.setPixel(fx0 + x, fy0 + y, c);
			}
		for( j in jobs ) {
			var sx = (j.src & 63) << 5, sy = (j.src >> 6) << 5;
			var dx = (j.dst & 63) << 5, dy = (j.dst >> 6) << 5;
			for( y in 0...32 )
				for( x in 0...32 ) {
					var c = pix.getPixel(sx + x, sy + y);
					var r = (c >> 16) & 0xFF, g = (c >> 8) & 0xFF, b = c & 0xFF;
					var l = Std.int(Math.min(255, (r * 0.3 + g * 0.59 + b * 0.11) * j.k + j.add));
					// un toque azulado, como el metal de las naves
					var lb = Std.int(Math.min(255, l * 1.06));
					pix.setPixel(dx + x, dy + y, 0xFF000000 | (l << 16) | (l << 8) | lb);
				}
		}
	}

	static function patch( pix : hxd.Pixels, again = false ) {
		motherTiles(pix);
		// el original empieza en 4095, que coincide con el valor "sin textura" (0xFFF) del mallador y dejaba invisible el primer bloque
		var lastTex = 4094;
		for( b in Block.all )
			for( f in b.flags )
				switch( f ) {
				case BFAlpha(alpha):
					if( b.hasFlag(BFLiquid) )
						alpha = switch( b.k ) {
							case BCascadeSource: 0.70;
							case BCascadeFall: 0.58;
							case BCascadeFall2: 0.46;
							case BCascadeFall3: 0.34;
							case BCascadeFall4: 0.22;
							default: LIQUID_ALPHA;
						};
					scaleTile(pix, b, alpha);
				case BFColor(color, _):
					var use = false;
					if( b.tlr == 0xFFF || (again && b.tlr <= 4095 && b.tlr > 4000) ) use = true;
					if( b.tu == 0xFFF || (again && b.tu <= 4095 && b.tu > 4000) ) use = true;
					if( b.td == 0xFFF || (again && b.td <= 4095 && b.td > 4000) ) use = true;
					if( use ) {
						if( b.tlr == 0xFFF ) b.tlr = lastTex;
						if( b.tu == 0xFFF ) b.tu = lastTex;
						if( b.td == 0xFFF ) b.td = lastTex;
						fillTile(pix, lastTex, 0xFF000000 | color);
						lastTex--;
					}
				default:
				}
	}
}
