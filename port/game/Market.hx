import Common;

/** Estado de una mercancia del comerciante: cuantas tiene y cuanto se le ha vendido o comprado ultimamente. */
typedef MarketItem = {
	/** clave: "b<indice de bloque>" o "c<indice de carga>" */
	var key : String;
	var stock : Int;
	/** presion: sube al venderle, baja al comprarle; vuelve a 0 con el tiempo */
	var pressure : Float;
}

/** Mercado guardado en la partida (todo es serializable a JSON, pensado para que un servidor pueda compartirlo luego). */
typedef MarketInfo = {
	/** segundos de juego del ultimo calculo (para que precios y existencias se recuperen con el tiempo) */
	var time : Float;
	var items : Array<MarketItem>;
}

/** Una mercancia tal como la ve la tienda. */
typedef Ware = {
	var key : String;
	var block : Block;
	/** carga (null = bloque) */
	var charge : Null<ChargeKind>;
	var base : Int;
}

/**
 * Comercio dinamico con el robot comerciante (anadido del port; el original tenia una tienda web con precios fijos).
 *
 * Reglas:
 * - Mercancias: los bloques con precio en los datos del original (los de la paleta creativa) y las cargas con precio.
 * - Comprar cuesta el precio base; vender da la mitad (como la tienda de la version Flash). Sobre eso:
 *   * la PRESION de cada mercancia sube 1 por cada REF unidades que le vendes y baja al comprarle. Con presion alta el
 *     robot paga menos y vende mas barato (hay mucho); con presion negativa, al reves. Se reduce a la mitad cada 10 min de juego;
 *   * las EXISTENCIAS: lo que le vendes lo guarda y lo que compras se lo quitas. Cada mercancia tiene un nivel normal
 *     (mas unidades cuanto mas barata) y se repone o se vende sola hacia el, 1 unidad por minuto de juego.
 *     Si quedan pocas, sube el precio de compra (hasta +50 %); sin existencias no se puede comprar.
 * - Los precios se calculan por unidad, asi que vender mucho de golpe baja el precio de las ultimas.
 */
class Market {

	public static inline var START_CREDITS = 500;
	static inline var REF = 20.;
	static inline var HALF_LIFE = 600.;
	static inline var RESTOCK = 60.;

	public static var wares(get, null) : Array<Ware>;
	static var byKey : Map<String, Ware>;

	static function get_wares() {
		if( wares == null ) {
			wares = [];
			byKey = new Map();
			for( b in Block.all ) {
				if( b.index <= 0 || b.basePrice == null || b.basePrice <= 0 || b.type == BTInvisible ) continue;
				var w : Ware = b.charge != null
					? { key : "c" + Type.enumIndex(b.charge), block : b, charge : b.charge, base : b.basePrice }
					: { key : "b" + b.index, block : b, charge : null, base : b.basePrice };
				if( byKey.exists(w.key) ) continue;
				wares.push(w);
				byKey.set(w.key, w);
			}
		}
		return wares;
	}

	public static function ware( key : String ) : Ware {
		get_wares();
		return byKey.get(key);
	}

	public static function wareOfBlock( b : Block ) : Ware return ware("b" + b.index);
	public static function wareOfCharge( c : ChargeKind ) : Ware return ware("c" + Type.enumIndex(c));

	/** existencias normales de una mercancia: mas cuanto mas barata, con algo de variacion fija por sector */
	public static function normalStock( w : Ware, seed : Int ) : Int {
		var h = (seed * 31 + w.key.length * 7 + w.base) & 0xFFFF;
		for( i in 0...w.key.length ) h = (h * 33 + w.key.charCodeAt(i)) & 0xFFFF;
		var n = Std.int(4000 / (w.base + 20));
		n = Std.int(n * (0.6 + (h % 100) / 125));
		return Std.int(Math.max(2, Math.min(64, n)));
	}

	public static function create( seed : Int ) : MarketInfo {
		return { time : 0, items : [for( w in wares ) { key : w.key, stock : normalStock(w, seed), pressure : 0. }] };
	}

	public var info(default, null) : MarketInfo;
	var seed : Int;
	var items = new Map<String, MarketItem>();

	public function new( info : MarketInfo, seed : Int ) {
		if( info == null ) info = create(seed);
		this.info = info;
		this.seed = seed;
		for( i in info.items ) items.set(i.key, i);
		for( w in wares )
			if( !items.exists(w.key) ) {
				var it = { key : w.key, stock : normalStock(w, seed), pressure : 0. };
				info.items.push(it);
				items.set(w.key, it);
			}
	}

	/** el tiempo de juego avanza: la presion se calma y las existencias vuelven a su nivel normal */
	public function advance( now : Float ) {
		var dt = now - info.time;
		if( dt <= 0 ) {
			info.time = now;
			return;
		}
		var k = Math.pow(0.5, dt / HALF_LIFE);
		var steps = Std.int(dt / RESTOCK);
		for( it in info.items ) {
			it.pressure *= k;
			if( Math.abs(it.pressure) < 0.01 ) it.pressure = 0;
			if( steps > 0 ) {
				var w = ware(it.key);
				if( w == null ) continue;
				var n = normalStock(w, seed);
				if( it.stock < n ) it.stock = Std.int(Math.min(n, it.stock + steps));
				else if( it.stock > n ) it.stock = Std.int(Math.max(n, it.stock - steps));
			}
		}
		// el resto de tiempo que no llego a un minuto se conserva
		info.time = steps > 0 ? info.time + steps * RESTOCK : info.time;
		if( dt > HALF_LIFE * 4 ) info.time = now;
	}

	public inline function item( w : Ware ) return items.get(w.key);

	/** lo que cuesta comprarle 1 unidad ahora */
	public function buyPrice( w : Ware ) : Int {
		var it = item(w);
		var n = normalStock(w, seed);
		var scarcity = Math.max(0, Math.min(1, 1 - it.stock / n));
		var f = Math.max(0.6, Math.min(1.6, 1 - 0.15 * it.pressure));
		return Std.int(Math.max(1, Math.round(w.base * (1 + 0.5 * scarcity) * f)));
	}

	/** lo que paga por 1 unidad ahora (siempre menos de lo que cuesta comprarla) */
	public function sellPrice( w : Ware ) : Int {
		var it = item(w);
		var f = Math.max(0.25, Math.min(1.2, 1 - 0.2 * it.pressure));
		var p = Std.int(Math.max(1, Math.round(w.base * 0.5 * f)));
		return Std.int(Math.min(p, Math.max(1, buyPrice(w) - 1)));
	}

	/** compra `n` unidades (o las que se puedan pagar); devuelve cuantas y lo que costaron */
	public function buy( w : Ware, n : Int, credits : Int ) : { n : Int, cost : Int } {
		var it = item(w);
		var done = 0, cost = 0;
		while( done < n && it.stock > 0 ) {
			var p = buyPrice(w);
			if( cost + p > credits ) break;
			cost += p;
			it.stock--;
			it.pressure -= 1 / REF;
			done++;
		}
		return { n : done, cost : cost };
	}

	/** vende `n` unidades; devuelve lo que cobraste */
	public function sell( w : Ware, n : Int ) : Int {
		var it = item(w);
		var gain = 0;
		for( i in 0...n ) {
			gain += sellPrice(w);
			it.stock++;
			it.pressure += 1 / REF;
		}
		return gain;
	}
}
