import Common;

/** una cara de la escalera: su caja en la celda (0..1) y su lado (World: 0 arriba, 1 abajo, 2 -x, 3 +x, 4 -y, 5 +y) */
typedef StairFace = {
	var x1 : Float;
	var y1 : Float;
	var z1 : Float;
	var x2 : Float;
	var y2 : Float;
	var z2 : Float;
	var f : Int;
	/** en el borde de la celda: solo se ve si el vecino de ese lado deja verla (World.open); si no, por dentro (siempre) */
	var edge : Bool;
}

/**
 * Escalera (anadido del port, BFStair): una dalle entera abajo y, encima, la mitad de la celda del lado del respaldo. Son 4
 * bloques seguidos, uno por giro (Block.stair): el respaldo esta en Block.WALL_DX/WALL_DY[giro] desde el centro de la celda.
 * - Se dibuja con sus caras (faces): cada una muestra su trozo de la casilla, como si fuera la de un bloque entero, asi una
 *   escalera junto a un muro del mismo material casa con el.
 * - Choca, se apunta y se pisa por sus dos cajas (inside): se sube andando en dos medios pasos (GameView.canStepOn), como una
 *   dalle y luego un bloque entero; de lado, contra el respaldo, no.
 * - Al ponerla, el respaldo va contra el bloque apuntado de lado o, apuntando a un suelo o a un techo, del lado al que mira el
 *   jugador: el escalon queda siempre hacia el (GameView.placedBlock).
 */
class Stair {

	/** normal de cada lado (como los indices de StairFace.f) */
	public static var FACE_DX = [0, 0, -1, 1, 0, 0];
	public static var FACE_DY = [0, 0, 0, 0, -1, 1];
	public static var FACE_DZ = [1, -1, 0, 0, 0, 0];

	/** un cuarto de vuelta (de +y hacia -x, como Block.WALL_DX/WALL_DY): lado de una cara tras girarla */
	static var TURN_FACE = [0, 1, 4, 5, 3, 2];

	static var cache : Array<Array<StairFace>> = [];

	/** las caras de la escalera con el respaldo en el giro turn */
	public static function faces( turn : Int ) : Array<StairFace> {
		turn &= 3;
		var c = cache[turn];
		if( c != null ) return c;
		// giro 0: respaldo en +y, escalon en -y
		var low = [0., 0., 0., 1., 1., 0.5], high = [0., 0.5, 0.5, 1., 1., 1.], step = [0., 0., 0., 1., 0.5, 0.5], all = [0., 0., 0., 1., 1., 1.];
		var list = [
			face(low, 1, true),
			face(step, 0, false), // la huella del escalon
			face(high, 0, true),
			face(high, 4, false), // la contrahuella
			face(low, 4, true),
			face(all, 5, true), // el respaldo, entero
			face(low, 2, true), face(high, 2, true),
			face(low, 3, true), face(high, 3, true),
		];
		for( t in 0...turn ) list = [for( f in list ) rotate(f)];
		cache[turn] = list;
		return list;
	}

	static function face( b : Array<Float>, f : Int, edge : Bool ) : StairFace {
		return { x1 : b[0], y1 : b[1], z1 : b[2], x2 : b[3], y2 : b[4], z2 : b[5], f : f, edge : edge };
	}

	/** un cuarto de vuelta alrededor del centro de la celda: (x, y) -> (1 - y, x) */
	static function rotate( f : StairFace ) : StairFace {
		return { x1 : 1 - f.y2, y1 : f.x1, z1 : f.z1, x2 : 1 - f.y1, y2 : f.x2, z2 : f.z2, f : TURN_FACE[f.f], edge : f.edge };
	}

	/** true si el punto (fx, fy, fz) de la celda (0..1) esta dentro de la escalera con el respaldo en el giro turn */
	public static function inside( turn : Int, fx : Float, fy : Float, fz : Float ) : Bool {
		if( fz < 0 || fz >= 1 || fx < 0 || fx >= 1 || fy < 0 || fy >= 1 ) return false;
		if( fz < 0.5 ) return true;
		return switch( turn & 3 ) {
			case 0: fy >= 0.5;
			case 1: fx < 0.5;
			case 2: fy < 0.5;
			default: fx >= 0.5;
		}
	}

	/** giro con el respaldo en (dx, dy) desde la celda (un solo eje); -1 si no es un lado */
	public static function turnFor( dx : Int, dy : Int ) : Int {
		for( t in 0...4 )
			if( Block.WALL_DX[t] == dx && Block.WALL_DY[t] == dy ) return t;
		return -1;
	}

	/** giro con el respaldo hacia donde mira el jugador (su eje mas cercano): el escalon queda de su lado */
	public static function turnFromYaw( yaw : Float ) : Int {
		var cx = Math.cos(yaw), cy = Math.sin(yaw);
		if( Math.abs(cx) >= Math.abs(cy) ) return turnFor(cx > 0 ? 1 : -1, 0);
		return turnFor(0, cy > 0 ? 1 : -1);
	}
}
