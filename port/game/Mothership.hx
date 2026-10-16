import Common;

/**
 * Nave nodriza del robot comerciante (anadido del port). Una nave enorme hecha con bloques de nave, con un gran hangar
 * abierto en un costado (como el de la Estrella de la Muerte) y bahias de aparcamiento dentro: en una esta tu nave y las
 * demas quedan para el multijugador. Al fondo del hangar esta el mostrador del robot.
 * El mismo modelo se usa en el mapa (fotogramas como los de tu nave) y como mundo para entrar.
 */
class Mothership {

	/** medidas (bloques) y posicion en el volumen de 128 */
	public static inline var LX = 120;
	public static inline var LY = 64;
	public static inline var LZ = 40;
	public static inline var X0 = 4;
	public static inline var Y0 = 32;
	public static inline var Z0 = 20;
	/** cubierta principal: de z 0 a DECK; la proa (+x) en punta */
	static inline var DECK = 22;
	static inline var HULL0 = 12;
	/** hangar: hueco interior abierto por el costado -y */
	public static inline var HX0 = 14;
	public static inline var HX1 = 79;
	public static inline var HY1 = 40;
	public static inline var HZ0 = 2;
	public static inline var HZ1 = 20;
	/** bahias: 3 a lo largo del hangar, de 19x19 (cabe la nave mas grande del hangar, 17x17x14) */
	public static inline var BAYS = 3;
	public static inline var BAY = 19;

	/** centro de la bahia i (coordenadas del volumen); z = encima del suelo */
	public static function bay( i : Int ) {
		var span = (HX1 - HX0) / BAYS;
		return { x : X0 + Std.int(HX0 + span * (i + 0.5)), y : Y0 + 2 + (BAY >> 1), z : Z0 + HZ0 };
	}

	/** media anchura de la cubierta en x (proa en punta) */
	static function halfWidth( x : Int ) : Float {
		if( x < HULL0 ) return 0;
		var f = (x - HULL0) / (LX - HULL0);
		return f < 0.55 ? LY * 0.5 : LY * 0.5 * (1 - (f - 0.55) / 0.45 * 0.92);
	}

	/** forma de la nave */
	static function shape( x : Int, y : Int, z : Int ) : Bool {
		var cy = LY * 0.5, dy = Math.abs(y + 0.5 - cy);
		// cubierta principal, con los bordes biselados abajo y arriba
		var hw = halfWidth(x);
		if( hw > 0 ) {
			var bevel = Math.min(z, DECK - 1 - z);
			if( z < DECK && dy <= hw - Math.max(0, 3 - bevel) ) return true;
		}
		// lomo central y torre de mando atras
		if( x >= HULL0 + 4 && x < LX - 22 && dy <= 8 - (z - DECK) && z >= DECK && z < DECK + 5 ) return true;
		if( x >= HULL0 + 4 && x < HULL0 + 18 && dy <= 6 && z >= DECK && z < DECK + 13 ) {
			if( z >= DECK + 10 ) return dy <= 9 && x >= HULL0 + 6 && x < HULL0 + 16; // puente, mas ancho
			return true;
		}
		// tres motores (cilindros) que salen por detras
		for( ey in [cy - 20, cy, cy + 20] ) {
			var ez = 11.5;
			var ddy = y + 0.5 - ey, ddz = z + 0.5 - ez;
			if( x < HULL0 + 10 && ddy * ddy + ddz * ddz <= (ey == cy ? 80 : 56) ) return true;
		}
		return false;
	}

	static var cache : ShipData.ShipDataInfo;

	public static function data() : ShipData.ShipDataInfo {
		if( cache != null ) return cache;
		var solid = new haxe.ds.Vector<Bool>(LX * LY * LZ);
		inline function id( x : Int, y : Int, z : Int ) return x + y * LX + z * LX * LY;
		inline function isSolid( x : Int, y : Int, z : Int ) return x >= 0 && y >= 0 && z >= 0 && x < LX && y < LY && z < LZ && solid[id(x, y, z)];
		for( x in 0...LX )
			for( y in 0...LY )
				for( z in 0...LZ )
					solid[id(x, y, z)] = shape(x, y, z);
		// el hangar: un hueco abierto por el costado -y
		for( x in HX0...HX1 )
			for( y in 0...HY1 )
				for( z in HZ0...HZ1 )
					solid[id(x, y, z)] = false;
		var cells = new Map<Int, BlockKind>();
		inline function put( x : Int, y : Int, z : Int, b : BlockKind ) cells.set(id(x, y, z), b);
		// casco: las celdas solidas que tocan el exterior o el hangar (la nave es hueca)
		for( x in 0...LX )
			for( y in 0...LY )
				for( z in 0...LZ ) {
					if( !solid[id(x, y, z)] ) continue;
					if( isSolid(x - 1, y, z) && isSolid(x + 1, y, z) && isSolid(x, y - 1, z) && isSolid(x, y + 1, z) && isSolid(x, y, z - 1) && isSolid(x, y, z + 1) ) continue;
					var b = BShipHull;
					var side = !isSolid(x, y - 1, z) || !isSolid(x, y + 1, z);
					var top = !isSolid(x, y, z + 1);
					// ventanas en franjas en los costados; paneles alternos arriba; lineas de luz en los bordes
					if( side && !top && z % 5 == 3 && x % 3 != 0 ) b = BShipGlass2;
					else if( top && (Std.int(x / 6) + Std.int(y / 6)) % 2 == 0 ) b = BShipPlate;
					else if( side && z % 5 == 0 ) b = BShipPlate;
					if( top && x % 8 == 0 && y % 8 == 4 ) b = BShipLight;
					put(x, y, z, b);
				}
		// motores: la cara trasera (-x), en rejilla
		for( y in 0...LY )
			for( z in 0...LZ ) {
				var x = 0;
				while( x < LX && !solid[id(x, y, z)] ) x++;
				if( x < LX && x < HULL0 ) put(x, y, z, BShipEngine);
			}
		// hangar: suelo de placas con el borde de luces, techo con luces y la barrera del borde (cristal en el suelo)
		for( x in HX0...HX1 )
			for( y in 0...HY1 ) {
				if( !isSolid(x, y, HZ0 - 1) ) continue;
				put(x, y, HZ0 - 1, BShipPlate);
				if( isSolid(x, y, HZ1) ) put(x, y, HZ1, x % 4 == 2 && y % 4 == 2 ? BShipLight : BShipPlate);
			}
		for( x in HX0...HX1 )
			for( z in HZ0...HZ1 )
				if( x % 4 == 1 && (z == HZ0 + 3 || z == HZ1 - 2) ) put(x, HY1, z, BShedWallLight);
		for( i in 0...BAYS ) {
			var c = bay(i);
			var bx = c.x - X0, by = c.y - Y0;
			for( dx in -(BAY >> 1)...(BAY >> 1) + 1 )
				for( dy in -(BAY >> 1)...(BAY >> 1) + 1 ) {
					var edge = Math.abs(dx) == BAY >> 1 || Math.abs(dy) == BAY >> 1;
					if( edge && (dx + dy) % 2 == 0 ) put(bx + dx, by + dy, HZ0 - 1, BShipLight);
					else if( edge ) put(bx + dx, by + dy, HZ0 - 1, BShedGroundArrow);
				}
		}
		// zona de comercio al fondo del hangar: el mostrador del robot en el centro y puestos a los lados
		// (para las tiendas de jugadores en el multijugador), con toldos de colores
		var awn = [BStainRed, BStainOrange, BStainGreen, BStainPurple, BStainWhite, BStainRed];
		var stalls = 7, sw = 7;
		var sx0 = ((HX0 + HX1) >> 1) - ((stalls * (sw + 1)) >> 1);
		var cy0 = HY1 - 7;
		for( i in 0...stalls ) {
			var x0 = sx0 + i * (sw + 1);
			var robot = i == stalls >> 1;
			for( dx in 0...sw ) {
				put(x0 + dx, cy0, HZ0, robot ? BShipComputer : BShipPlate);
				for( dy in 1...6 ) put(x0 + dx, cy0 + dy, HZ0 + 5, robot ? BShipLight : awn[i % awn.length]);
			}
			// postes
			for( dz in 0...5 ) {
				put(x0, cy0, HZ0 + dz, BShipTubes);
				put(x0 + sw - 1, cy0, HZ0 + dz, BShipTubes);
			}
			if( !robot ) put(x0 + (sw >> 1), cy0 + 3, HZ0 + 4, BShipLight);
		}
		// contenedores de carga encima (es un comerciante)
		var colors = [BStainRed, BStainOrange, BStainGreen, BStainPurple, BStainWhite];
		var k = 0;
		for( gx in 0...5 )
			for( gy in 0...3 ) {
				var x0 = 30 + gx * 10, y0 = 14 + gy * 12;
				var top = LZ - 1;
				while( top > 0 && !isSolid(x0 + 2, y0 + 2, top) ) top--;
				if( top <= 0 || (gx + gy) % 2 == 1 ) continue;
				var col = colors[k++ % colors.length];
				for( dx in 0...6 ) for( dy in 0...4 ) for( dz in 1...4 ) put(x0 + dx, y0 + dy, top + dz, col);
			}
		var out = [];
		for( key => b in cells ) {
			var x = key % LX, y = Std.int(key / LX) % LY, z = Std.int(key / (LX * LY));
			out.push({ x : X0 + x, y : Y0 + y, z : Z0 + z, id : Type.enumIndex(b) });
		}
		return cache = { sx : Const.SIZE, sy : Const.SIZE, sz : Z0 + LZ + 4, cells : out, entry : null, crafts : [] };
	}
}
