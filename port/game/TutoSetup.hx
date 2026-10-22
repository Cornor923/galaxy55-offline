import Common;
import SaveData.SaveInfo;

/**
 * Partida nueva de aventura y preparacion del tutorial (anadido del port; el original empezaba en el espacio, sin tutorial):
 * - newGame: la partida empieza en el espacio, en el sistema 0, con el inventario vacio (SaveData.create en aventura). Con tutorial, el planeta 0 del
 *   sistema es Terres Rouges pequeno; sin el, el sistema es el aleatorio de ExpOffline y la ESCorp envia las cargas.
 * - la nave del tutorial tiene dos agujeros en el techo, encima de las losas del sintetizador (HOLES). Se quitan con shipEdits
 *   y no en el plano: la zona del sintetizador se mide en el plano y llegaria hasta el agujero (se taparia desde dentro).
 * - seedPlanet: al primer aterrizaje se ponen cerca de la nave los citronox viejos, el etherium y la bauxita del tutorial.
 * - skip: la partida queda como sin tutorial (planeta y nave de serie, inventario vacio mas el envio de la ESCorp).
 */
class TutoSetup {

	/** planeta del tutorial: el 0 del sistema 0 */
	public static inline var PLANET = 0;
	/** agujeros del casco (x, y, z en el plano de la nave de serie): el techo encima de las losas del sintetizador */
	public static var HOLES = [[4, 7, 4], [5, 7, 4]];
	/** cargas azules y amarillas que envia la ESCorp al acabar o pasar el tutorial */
	public static inline var GIFT = 30;

	public static function newGame( name : String, seed : Int, tutorial : Bool ) : SaveInfo {
		var start = tutorial ? { seed : seed, biome : "BIAutumn", size : 1 } : null;
		var p = ExpData.ExpOffline.make(seed, start).systems[0].planets[PLANET];
		var info = SaveData.create(name, p.seed, p.biome, p.size);
		info.tutorial = tutorial;
		info.uni = { seed : seed, planetId : PLANET, pos : [1, 0], start : { seed : p.seed, biome : p.biome, size : p.size }, planets : [], space : true };
		if( tutorial ) {
			info.tuto = { step : 0 };
			info.shipEdits = holeEdits();
		} else
			grant(info.inv);
		return info;
	}

	/** el envio de la ESCorp */
	public static function grant( inv : Protocol.InventoryInfos ) {
		var i = new Inv(inv);
		i.addCharge(CBlue, GIFT);
		i.addCharge(CYellow, GIFT);
	}

	/** la partida como si se hubiera empezado sin tutorial: se vuelve al espacio, junto al planeta del tutorial */
	public static function skip( info : SaveInfo ) {
		var uni = info.uni;
		info.tuto = null;
		info.inv = Inv.empty();
		grant(info.inv);
		info.shipData = null;
		info.shipEdits = [];
		info.edits = [];
		uni.planets = uni.planets.filter(function(p) return p.id != PLANET);
		if( info.chests != null ) info.chests = info.chests.filter(function(c) return !StringTools.startsWith(c.key, "p" + PLANET + ":"));
		uni.planetId = PLANET;
		uni.pos = [1, 0];
		uni.space = true;
		uni.ship = null;
		info.seed = uni.start.seed;
		info.biome = uni.start.biome;
		info.sizeChunks = uni.start.size;
		info.px = info.py = info.pz = -1;
		info.life = 100;
	}

	// ---------------------------------------------------------------- agujeros de la nave

	/** shipEdits que quitan los bloques de HOLES (claves de World.setBlock en el volumen de la nave, bloque 0 = aire) */
	public static function holeEdits() : Array<Int> {
		var out = [];
		for( c in shipCells() ) {
			out.push(((c.x + c.y * Const.SIZE) << World.ZBITS) | c.z);
			out.push(0);
		}
		return out;
	}

	/** celdas de HOLES en el volumen de la nave (ShipData.load: centrada, 1 de margen abajo) */
	public static function shipCells() : Array<{ x : Int, y : Int, z : Int }> {
		var d = ShipData.load(Const.DEFAULT_SHIP);
		var dx = (Const.SIZE - d.sx) >> 1, dy = (Const.SIZE - d.sy) >> 1;
		return [for( h in HOLES ) { x : h[0] + dx, y : h[1] + dy, z : h[2] + 1 }];
	}

	/** hangar durante el tutorial: la nave con sus agujeros (el hangar se hace con el plano, sin los shipEdits) */
	public static function holed( info : SaveInfo, d : ShipData.ShipDataInfo ) : ShipData.ShipDataInfo {
		if( info.tuto == null || info.shipData != null ) return d;
		var holes = hangarCells();
		d.cells = d.cells.filter(function(c) return !Lambda.exists(holes, function(h) return h.x == c.x && h.y == c.y && h.z == c.z));
		return d;
	}

	/** celdas de HOLES en el hangar */
	public static function hangarCells() : Array<{ x : Int, y : Int, z : Int }> {
		var d = ShipData.load(Const.DEFAULT_SHIP);
		return [for( h in HOLES ) Hangar.shipCell(h[0], h[1], h[2], d.sx, d.sy)];
	}

	// ---------------------------------------------------------------- bloques del tutorial en el planeta

	/**
	 * Al primer aterrizaje: 4 citronox viejos a 9-15 bloques de la nave, 3 fragmentos de etherium azul a 19-23 y una veta de
	 * bauxita de 2x2 a unos 30. Se ponen con setBlock (son cambios del planeta: pasar el tutorial los quita) y se guardan en
	 * tuto.spots para seguirlos.
	 */
	public static function seedPlanet( g : GameView ) {
		var t = g.info.tuto;
		if( t == null || t.spots != null || g.ship == null ) return;
		var w = g.world, sx = g.ship.x, sy = g.ship.y, gz = Std.int(g.ship.z) - 1;
		var spots = [];
		inline function put( x : Int, y : Int, z : Int, k : BlockKind ) {
			x = wrap(w, x);
			y = wrap(w, y);
			w.setBlock(x, y, z, Block.get(k));
			for( v in [x, y, z, Type.enumIndex(k)] ) spots.push(v);
		}
		for( i in 0...4 ) {
			var s = ground(w, sx, sy, gz, i * Math.PI / 2 + 0.4, 9 + i * 2);
			put(s.x, s.y, s.z + 1, BYellowCrystalLight);
		}
		for( i in 0...3 ) {
			var s = ground(w, sx, sy, gz, i * 2.1 + 1.2, 19 + i * 2);
			put(s.x, s.y, s.z + 1, BBlueCrystalLight);
		}
		var s = ground(w, sx, sy, gz, 2.6, 30);
		for( dx in 0...2 )
			for( dy in 0...2 ) {
				var z = top(w, s.x + dx, s.y + dy);
				if( z > 0 ) put(s.x + dx, s.y + dy, z, BMinAluminium);
			}
		t.spots = spots;
	}

	static inline function wrap( w : World, v : Int ) return ((v % w.size) + w.size) % w.size;

	/** el bloque macizo mas alto de la columna (-1 si hay liquido encima o un tronco) */
	static function top( w : World, x : Int, y : Int ) : Int {
		var z = World.HEIGHT - 2;
		while( z > 0 ) {
			var b = w.block(wrap(w, x), wrap(w, y), z);
			if( b != null ) {
				if( b.hasProp(PLiquid) || b.k == BWood ) return -1;
				if( b.type == BTFull ) return z;
			}
			z--;
		}
		return -1;
	}

	/** suelo seco y despejado cerca del punto (angulo a, distancia d) de la nave, a una altura parecida a la suya */
	static function ground( w : World, sx : Int, sy : Int, gz : Int, a : Float, d : Float ) : { x : Int, y : Int, z : Int } {
		var x0 = sx + Math.round(Math.cos(a) * d), y0 = sy + Math.round(Math.sin(a) * d);
		inline function free( x : Int, y : Int, z : Int ) {
			var b = w.block(wrap(w, x), wrap(w, y), z);
			return b == null || b.hasFlag(BFDetail);
		}
		for( r in 0...10 )
			for( dx in -r...r + 1 )
				for( dy in -r...r + 1 ) {
					if( Math.abs(dx) != r && Math.abs(dy) != r ) continue;
					var x = x0 + dx, y = y0 + dy;
					var z = top(w, x, y);
					if( z > 0 && Math.abs(z - gz) <= 8 && free(x, y, z + 1) && free(x, y, z + 2) ) return { x : x, y : y, z : z };
				}
		var z = top(w, x0, y0);
		return { x : x0, y : y0, z : z > 0 ? z : gz };
	}
}
