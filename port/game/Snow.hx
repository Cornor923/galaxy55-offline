import h2d.SpriteBatch;

/**
	Nieve en pantalla (anadido de este port: el juego original no la tiene).

	Son copos 2D que caen por la pantalla en varias capas de profundidad. Cuando la camara gira, los
	copos se desplazan como si estuvieran fijos en el mundo (compensan el giro de yaw y pitch), asi no
	"corren" al mover el raton. Se dibuja debajo de los menus y del HUD.
**/
class Snow {

	static inline var N = 320;

	var batch : SpriteBatch;
	var els = new Array<BatchElement>();
	var depth = new Array<Float>();
	var phase = new Array<Float>();
	var freq = new Array<Float>();
	var w : Float;
	var h : Float;
	var prevYaw = 0.;
	var prevPitch = 0.;
	var started = false;

	public var visible(get, set) : Bool;

	public function new( parent : h2d.Object, w : Int, h : Int ) {
		this.w = w;
		this.h = h;
		batch = new SpriteBatch(h2d.Tile.fromColor(0xFFFFFF, 1, 1), parent);
		batch.hasRotationScale = true;
		batch.visible = false;
		for( i in 0...N ) {
			var e = new BatchElement(batch.tile);
			// capas: abundantes y pequenas al fondo, pocas y grandes delante
			var d = Math.pow(Math.random(), 1.6);
			depth.push(d);
			phase.push(Math.random() * 6.28);
			freq.push(0.5 + Math.random() * 1.0);
			e.x = Math.random() * w;
			e.y = Math.random() * h;
			var s = 2 + 6 * d;
			e.scaleX = s;
			e.scaleY = s;
			e.alpha = 0.5 + 0.5 * d;
			batch.add(e);
			els.push(e);
		}
	}

	function get_visible() return batch.visible;

	function set_visible( v : Bool ) {
		if( v && !batch.visible ) started = false;
		return batch.visible = v;
	}

	/** yaw/pitch en radianes (de la camara), fovY en grados. */
	public function update( dt : Float, yaw : Float, pitch : Float, fovY : Float ) {
		if( !batch.visible ) return;
		var dyaw = 0., dpitch = 0.;
		if( started ) {
			dyaw = yaw - prevYaw;
			while( dyaw > Math.PI ) dyaw -= Math.PI * 2;
			while( dyaw < -Math.PI ) dyaw += Math.PI * 2;
			dpitch = pitch - prevPitch;
		}
		started = true;
		prevYaw = yaw;
		prevPitch = pitch;

		// pixeles por radian en el centro de la pantalla
		var f = (h * 0.5) / Math.tan(fovY * Math.PI / 360);
		var sx = -dyaw * f;
		var sy = dpitch * f;
		for( i in 0...N ) {
			var e = els[i];
			var d = depth[i];
			phase[i] += dt * freq[i];
			e.x += sx + Math.sin(phase[i]) * (10 + 22 * d) * dt;
			e.y += sy + (45 + 150 * d) * dt;
			// al salir por un borde reaparece por el opuesto
			if( e.y > h + 8 ) {
				e.y -= h + 16;
				e.x = Math.random() * w;
			} else if( e.y < -8 ) {
				e.y += h + 16;
				e.x = Math.random() * w;
			}
			if( e.x > w + 8 ) e.x -= w + 16;
			else if( e.x < -8 ) e.x += w + 16;
		}
	}

	public function dispose() {
		batch.remove();
	}
}
