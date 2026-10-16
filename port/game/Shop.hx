import Common;
import Ui;
import Market;
import IconMesh.Icons;

/**
 * Tienda del robot comerciante (anadido del port): a la izquierda lo que llevas (clic = vender), a la derecha lo que
 * tiene el robot (clic = comprar). Mayus + clic = 10 unidades. Los precios cambian con cada operacion (ver Market).
 */
class Shop extends h2d.Object {

	public var onClose : Void -> Void;
	/** se llama tras cada compra o venta con el saldo nuevo */
	public var onCredits : Int -> Void;

	static inline var CELL = 56;
	static inline var PX = 1280;
	static inline var PY = 720;
	static inline var RCOLS = 10;
	static inline var RROWS = 6;

	var atlas : h3d.mat.Texture;
	var market : Market;
	var inv : Inv;
	public var credits(default, null) : Int;
	var page = 0;
	var left : h2d.Object;
	var right : h2d.Object;
	var info : h2d.Text;
	var creditsText : h2d.Text;
	var pageText : h2d.Text;
	var hover : Ware;
	var hoverSell = false;

	public function new( parent : h2d.Object, atlas : h3d.mat.Texture, market : Market, inv : Inv, credits : Int ) {
		super(parent);
		this.atlas = atlas;
		this.market = market;
		this.inv = inv;
		this.credits = credits;

		var w = 1180, h = 600;
		var px = (PX - w) * 0.5, py = (PY - h) * 0.5;
		var bg = new h2d.Graphics(this);
		Theme.rect(bg, 0, 0, PX, PY, 0x000000, 0.55);
		Theme.rect(bg, px, py, w, h, Theme.PANEL, 0.96);
		Theme.rect(bg, px, py, w, 4, Theme.ACCENT);
		Theme.text(this, Lang.t("shop.title"), 2.6, Theme.TEXT, px + 24, py + 20);
		creditsText = Theme.text(this, "", 2.4, Theme.ACCENT, px + w - 330, py + 22);
		Theme.text(this, Lang.t("shop.yours"), 1.8, Theme.DIM, px + 24, py + 70);
		Theme.text(this, Lang.t("shop.robot"), 1.8, Theme.DIM, px + 470, py + 70);
		pageText = Theme.text(this, "", 1.6, Theme.DIM, px + w - 110, py + 70);
		info = Theme.text(this, "", 1.9, Theme.CYAN, px + 24, py + h - 70);
		Theme.text(this, Lang.t("shop.hint"), 1.4, Theme.DIM, px + 24, py + h - 36);
		var close = new h2d.Interactive(160, 36, this);
		close.x = px + w - 184;
		close.y = py + h - 52;
		var cg = new h2d.Graphics(close);
		Theme.rect(cg, 0, 0, 160, 36, 0xFFFFFF, 0.08);
		Theme.text(close, Lang.t("shop.close"), 1.8, Theme.TEXT, 30, 6);
		close.onClick = function(_) if( onClose != null ) onClose();
		left = new h2d.Object(this);
		left.x = px + 24;
		left.y = py + 100;
		right = new h2d.Object(this);
		right.x = px + 470;
		right.y = py + 100;
		refresh();
	}

	function pages() return Std.int((Market.wares.length + RCOLS * RROWS - 1) / (RCOLS * RROWS));

	public function scroll( delta : Float ) {
		page += delta > 0 ? 1 : -1;
		var n = pages();
		if( page < 0 ) page = n - 1;
		if( page >= n ) page = 0;
		refresh();
	}

	function refresh() {
		creditsText.text = Lang.t("shop.credits") + " " + credits;
		pageText.text = (page + 1) + " / " + pages();
		// lo que llevas: las casillas del inventario y las cargas
		left.removeChildren();
		var mine : Array<{ w : Ware, n : Int }> = [];
		for( s in inv.inv.t ) {
			if( s == null ) continue;
			var w = Market.wareOfBlock(Block.all[s.k]);
			if( w == null ) continue;
			var found = false;
			for( m in mine ) if( m.w == w ) { m.n += s.n; found = true; }
			if( !found ) mine.push({ w : w, n : s.n });
		}
		for( c in inv.inv.charges ) {
			if( c.n <= 0 ) continue;
			var w = Market.wareOfCharge(Type.createEnumIndex(ChargeKind, c.c));
			if( w != null ) mine.push({ w : w, n : c.n });
		}
		for( i in 0...mine.length ) {
			var m = mine[i];
			cell(left, (i % 7) * CELL, Std.int(i / 7) * (CELL + 18), m.w, m.n, market.sellPrice(m.w), true);
		}
		// lo que tiene el robot
		right.removeChildren();
		var per = RCOLS * RROWS;
		for( i in 0...per ) {
			var wi = page * per + i;
			if( wi >= Market.wares.length ) break;
			var w = Market.wares[wi];
			cell(right, (i % RCOLS) * CELL, Std.int(i / RCOLS) * (CELL + 18), w, market.item(w).stock, market.buyPrice(w), false);
		}
		showInfo();
	}

	function cell( parent : h2d.Object, x : Float, y : Float, w : Ware, n : Int, price : Int, sell : Bool ) {
		var c = new h2d.Object(parent);
		c.x = x;
		c.y = y;
		var g = new h2d.Graphics(c);
		var empty = n <= 0;
		var draw = function(on : Bool) {
			g.clear();
			Theme.rect(g, 1, 1, CELL - 2, CELL - 2, on ? Theme.ACCENT : 0xFFFFFF, on ? 0.3 : 0.06);
		};
		draw(false);
		var bm = new h2d.Bitmap(Icons.get(w.block, atlas), c);
		bm.setScale(44 / Icons.SIZE);
		bm.x = 6;
		bm.y = 4;
		if( empty ) bm.alpha = 0.3;
		Theme.text(c, "" + n, 1.2, empty ? Theme.DIM : Theme.TEXT, 3, CELL - 20);
		Theme.text(c, "" + price, 1.2, sell ? Theme.CYAN : Theme.ACCENT, 3, CELL + 1);
		var it = new h2d.Interactive(CELL - 2, CELL - 2, c);
		it.enableRightButton = true;
		it.onOver = function(_) {
			draw(true);
			hover = w;
			hoverSell = sell;
			showInfo();
		};
		it.onOut = function(_) draw(false);
		it.onClick = function(e) {
			var k = hxd.Key.isDown(hxd.Key.SHIFT) ? 10 : 1;
			if( sell ) doSell(w, k) else doBuy(w, k);
		};
	}

	function showInfo() {
		if( hover == null ) {
			info.text = "";
			return;
		}
		var w = hover;
		var name = w.block.getName();
		info.text = name + "   " + Lang.t("shop.buy") + " " + market.buyPrice(w) + "   " + Lang.t("shop.sell") + " " + market.sellPrice(w)
			+ "   " + Lang.t("shop.stock") + " " + market.item(w).stock;
	}

	/** compra hasta `n`, limitado por los creditos, las existencias y el sitio del inventario */
	public function doBuy( w : Ware, n : Int ) {
		var room = 0;
		if( w.charge != null ) {
			var have = 0;
			for( c in inv.inv.charges ) if( c.c == Type.enumIndex(w.charge) ) have = c.n;
			room = Std.int(Math.max(0, Data.getCharge(w.charge).max - have));
		} else {
			// sitio que queda para ese bloque (pilas a medias y casillas libres)
			var max = w.block.getMax(inv.inv.maxWeight);
			for( s in inv.inv.t ) {
				if( s == null ) room += max;
				else if( s.k == w.block.index ) room += Std.int(Math.max(0, max - s.n));
			}
		}
		var r = market.buy(w, Std.int(Math.min(n, room)), credits);
		if( r.n <= 0 ) return;
		credits -= r.cost;
		if( w.charge != null ) inv.addCharge(w.charge, r.n) else inv.addBlocks(w.block, r.n);
		if( onCredits != null ) onCredits(credits);
		refresh();
	}

	public function doSell( w : Ware, n : Int ) {
		var have = 0;
		if( w.charge != null ) {
			for( c in inv.inv.charges ) if( c.c == Type.enumIndex(w.charge) ) have = c.n;
		} else
			for( s in inv.inv.t ) if( s != null && s.k == w.block.index ) have += s.n;
		n = Std.int(Math.min(n, have));
		if( n <= 0 ) return;
		if( w.charge != null ) {
			for( c in inv.inv.charges ) if( c.c == Type.enumIndex(w.charge) ) c.n -= n;
			inv.display();
		} else
			inv.useBlocks(w.block, n);
		credits += market.sell(w, n);
		if( onCredits != null ) onCredits(credits);
		refresh();
	}
}
