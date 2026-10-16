import Common;
import Ui;
import IconMesh.Icons;

/**
 * Cantina de ESCorp (BChest, BFContainer(4)): cofre de 4 casillas, copiado de ent/Chest.hx del original.
 * Clic en una casilla para cogerla y clic en otra para dejarla: junta pilas iguales, mueve a una vacia o intercambia.
 * Mayus = la mitad, Ctrl = una. En el original el contenido lo guardaba el servidor; aqui va en la partida (SaveInfo.chests).
 */
class Chest extends h2d.Object {

	public var onClose : Void -> Void;

	static inline var CELL = 60;
	static inline var PX = 1280;
	static inline var PY = 720;

	var atlas : h3d.mat.Texture;
	var inv : Inv;
	var box : Protocol.BlockInventory;
	var maxWeight : Int;
	var grid : h2d.Object;
	var info : h2d.Text;
	/** casilla cogida: [0 = cofre / 1 = inventario, indice] */
	var cur : Array<Int>;

	public function new( parent : h2d.Object, atlas : h3d.mat.Texture, inv : Inv, box : Protocol.BlockInventory ) {
		super(parent);
		this.atlas = atlas;
		this.inv = inv;
		this.box = box;
		maxWeight = inv.inv.maxWeight;
		var w = 700, h = 330;
		var px = (PX - w) * 0.5, py = 120.;
		var bg = new h2d.Graphics(this);
		Theme.rect(bg, 0, 0, PX, PY, 0x000000, 0.45);
		Theme.rect(bg, px, py, w, h, Theme.PANEL, 0.96);
		Theme.rect(bg, px, py, w, 4, Theme.ACCENT);
		Theme.text(this, Block.get(BChest).getName(), 2.4, Theme.TEXT, px + 24, py + 18);
		Theme.text(this, Lang.t("chest.yours"), 1.6, Theme.DIM, px + 24, py + 150);
		info = Theme.text(this, Lang.t("chest.hint"), 1.4, Theme.DIM, px + 24, py + h - 34);
		var close = new h2d.Interactive(140, 34, this);
		close.x = px + w - 160;
		close.y = py + h - 46;
		var cg = new h2d.Graphics(close);
		Theme.rect(cg, 0, 0, 140, 34, 0xFFFFFF, 0.08);
		Theme.text(close, Lang.t("shop.close"), 1.7, Theme.TEXT, 26, 5);
		close.onClick = function(_) if( onClose != null ) onClose();
		grid = new h2d.Object(this);
		grid.x = px + 24;
		grid.y = py + 70;
		refresh();
	}

	function refresh() {
		grid.removeChildren();
		var w = 652;
		for( i in 0...box.length ) slot(0, i, (w - box.length * CELL) * 0.5 + i * CELL, 0, box[i]);
		for( i in 0...inv.inv.t.length ) slot(1, i, (w - inv.inv.t.length * CELL) * 0.5 + i * CELL, 110, inv.inv.t[i]);
	}

	function slot( side : Int, idx : Int, x : Float, y : Float, s : Null<{ k : Int, n : Int }> ) {
		var c = new h2d.Object(grid);
		c.x = x;
		c.y = y;
		var g = new h2d.Graphics(c);
		var sel = cur != null && cur[0] == side && cur[1] == idx;
		var draw = function(on : Bool) {
			g.clear();
			Theme.rect(g, 2, 2, CELL - 4, CELL - 4, sel || on ? Theme.ACCENT : 0xFFFFFF, sel ? 0.45 : (on ? 0.25 : 0.07));
		};
		draw(false);
		if( s != null ) {
			var b = Block.all[s.k];
			var bm = new h2d.Bitmap(Icons.get(b, atlas), c);
			bm.setScale(48 / Icons.SIZE);
			bm.x = 6;
			bm.y = 3;
			Theme.text(c, "" + s.n, 1.2, s.n >= b.getMax(maxWeight) ? 0xF08080 : Theme.TEXT, 5, CELL - 20);
		}
		var it = new h2d.Interactive(CELL - 4, CELL - 4, c);
		it.onOver = function(_) {
			draw(true);
			info.text = s == null ? Lang.t("chest.hint") : Block.all[s.k].getName() + " x" + s.n;
		};
		it.onOut = function(_) draw(false);
		it.onClick = function(_) click(side, idx);
	}

	inline function tab( side : Int ) return side == 0 ? box : inv.inv.t;

	/** Chest.checkSwap del original */
	public function click( side : Int, idx : Int ) {
		if( cur == null ) {
			if( tab(side)[idx] != null ) cur = [side, idx];
			refresh();
			return;
		}
		var src = tab(cur[0]), isrc = cur[1];
		var dst = tab(side), idst = idx;
		var bsrc = src[isrc], bdst = dst[idst];
		if( src == dst && isrc == idst ) {
			cur = null;
			refresh();
			return;
		}
		var split = hxd.Key.isDown(hxd.Key.SHIFT);
		var one = hxd.Key.isDown(hxd.Key.CTRL);
		var smax = one ? 1 : (split ? Math.ceil(bsrc.n * 0.5) : bsrc.n);
		if( bdst != null && bdst.k == bsrc.k ) {
			// juntar
			var max = Block.all[bdst.k].getMax(maxWeight);
			if( bdst.n >= max ) return;
			var n = max - bdst.n;
			if( n > smax ) n = smax;
			bdst.n += n;
			bsrc.n -= n;
			if( bsrc.n == 0 ) {
				src[isrc] = null;
				cur = null;
			}
		} else if( bdst == null ) {
			// mover o partir
			dst[idst] = { k : bsrc.k, n : smax };
			bsrc.n -= smax;
			if( bsrc.n == 0 ) {
				src[isrc] = null;
				cur = null;
			}
		} else {
			// intercambiar
			dst[idst] = bsrc;
			src[isrc] = bdst;
			cur = null;
		}
		inv.display();
		refresh();
	}
}
