import Common;
import Ui;
import IconMesh.Icons;

/**
 * Paleta del modo creativo (anadido nuestro): todos los bloques que el original vendia en la tienda (los que tienen precio),
 * en una cuadricula con paginas. Un clic pone el bloque en la casilla elegida del inventario.
 */
class Palette extends h2d.Object {

	public var onPick : Block -> Void;

	static inline var COLS = 14;
	static inline var ROWS = 8;
	static inline var CELL = 56;
	static inline var PX = 1280;
	static inline var PY = 720;

	var atlas : h3d.mat.Texture;
	var blocks = new Array<Block>();
	var page = 0;
	var grid : h2d.Object;
	var info : h2d.Text;
	var pageText : h2d.Text;
	var x0 : Float;
	var y0 : Float;

	public function new( parent : h2d.Object, atlas : h3d.mat.Texture ) {
		super(parent);
		this.atlas = atlas;
		for( b in Block.all )
			if( b.index > 0 && b.basePrice != null && b.charge == null && b.type != BTInvisible )
				blocks.push(b);

		var w = COLS * CELL + 40, h = ROWS * CELL + 150;
		var px = (PX - w) * 0.5, py = (PY - h) * 0.5;
		x0 = px + 20;
		y0 = py + 70;
		var bg = new h2d.Graphics(this);
		Theme.rect(bg, 0, 0, PX, PY, 0x000000, 0.5);
		Theme.rect(bg, px, py, w, h, Theme.PANEL, 0.96);
		Theme.rect(bg, px, py, w, 4, Theme.ACCENT);
		var t = Theme.text(this, Lang.t("palette.title"), 2.6, Theme.TEXT, px + 24, py + 22);
		pageText = Theme.text(this, "", 1.8, Theme.DIM, px + w - 150, py + 30);
		info = Theme.text(this, "", 2.0, Theme.CYAN, px + 24, py + h - 66);
		Theme.text(this, Lang.t("palette.hint"), 1.5, Theme.DIM, px + 24, py + h - 34);
		grid = new h2d.Object(this);
		show();
	}

	function pages() return Std.int((blocks.length + COLS * ROWS - 1) / (COLS * ROWS));

	public function scroll( delta : Float ) {
		page += delta > 0 ? 1 : -1;
		var n = pages();
		if( page < 0 ) page = n - 1;
		if( page >= n ) page = 0;
		show();
	}

	function show() {
		grid.removeChildren();
		pageText.text = (page + 1) + " / " + pages();
		var per = COLS * ROWS;
		for( i in 0...per ) {
			var bi = page * per + i;
			if( bi >= blocks.length ) break;
			var b = blocks[bi];
			var cx = x0 + (i % COLS) * CELL, cy = y0 + Std.int(i / COLS) * CELL;
			var cell = new h2d.Object(grid);
			cell.x = cx;
			cell.y = cy;
			var g = new h2d.Graphics(cell);
			Theme.rect(g, 1, 1, CELL - 2, CELL - 2, 0xFFFFFF, 0.06);
			var bm = new h2d.Bitmap(Icons.get(b, atlas), cell);
			bm.setScale(48 / Icons.SIZE);
			bm.x = 4;
			bm.y = 4;
			var it = new h2d.Interactive(CELL - 2, CELL - 2, cell);
			it.onOver = function(_) {
				g.clear();
				Theme.rect(g, 1, 1, CELL - 2, CELL - 2, Theme.ACCENT, 0.3);
				info.text = b.getName();
			};
			it.onOut = function(_) {
				g.clear();
				Theme.rect(g, 1, 1, CELL - 2, CELL - 2, 0xFFFFFF, 0.06);
			};
			it.onClick = function(_) {
				if( onPick != null ) onPick(b);
			};
		}
	}
}
