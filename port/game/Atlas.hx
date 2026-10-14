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

	public static function build( png : haxe.io.Bytes ) : h3d.mat.Texture {
		var pix = hxd.res.Any.fromBytes("texture.png", png).toImage().getPixels();
		if( !patched ) {
			patched = true;
			patch(pix);
		} else
			patch(pix, true);
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
	static function patch( pix : hxd.Pixels, again = false ) {
		var lastTex = 4095;
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
