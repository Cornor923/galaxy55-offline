import Ui;
import Common;

/**
 * Pestana Recetas: las recetas descubiertas (se recupero uno de sus kubes), en dos columnas, con cuantas veces se han fabricado.
 * Clic en una ficha conocida: su ficha en el Kubindex.
 */
class KubRecipesView extends KubView {

	static inline var COL_W = 570;
	static inline var ROW_H = KubDraw.RECIPE_H + 8;

	var list : KubScroll;

	override function refresh() {
		removeChildren();
		var info = panel.info;
		var known = [for( r in Data.CRAFT ) if( Kubindex.recipeKnown(info, r) ) r];
		Theme.text(this, KubText.get("rc.count").split("%n%").join("" + known.length).split("%t%").join("" + Data.CRAFT.length), 1.6, Theme.TEXT, 0, 0);
		list = new KubScroll(this, DatabasePanel.CW, DatabasePanel.CH - 34);
		list.y = 34;
		if( known.length == 0 ) Theme.text(list.content, KubText.get("rc.empty"), 1.5, Theme.DIM, 0, 8);
		for( i in 0...known.length ) {
			var r = known[i];
			var o = new h2d.Object(list.content);
			o.setPosition((i % 2) * COL_W, Std.int(i / 2) * ROW_H);
			var g = new h2d.Graphics(o);
			Theme.rect(g, -4, -2, COL_W - 12, ROW_H - 4, 0xFFFFFF, 0.04);
			var w = KubDraw.recipe(o, r, info, panel.atlas, panel.pick, list);
			var n = Kubindex.craftCount(info, r);
			var t = Theme.text(o, n > 0 ? KubText.get("rc.made").split("%n%").join("" + n) : KubText.get("rc.never"), 1.1, n > 0 ? Theme.CYAN : Theme.DISABLED, w + 4, 36);
			t.maxWidth = (COL_W - w - 24) / t.scaleX;
		}
		list.contentH = Math.ceil(known.length / 2) * ROW_H;
		list.done();
	}

	override function nav( dx : Int, dy : Int ) list.scroll(dy != 0 ? dy : dx);

	override function scroll( delta : Float ) list.scroll(delta);
}
