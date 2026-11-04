import Ui;
import Common;
import Kubindex.KubState;
import KubData.KubCat;

/**
 * Ficha de un kube en el Kubindex: imagen (oscurecida si solo se ha localizado), nombre, donde encontrarlo y, una vez
 * recuperado, lo que da al minarlo, la carga que pide, cuantos se han puesto y roto y sus recetas (las que lo fabrican y las
 * que lo usan; lo que no se conoce sale como sombra con "???").
 */
class KubDetail extends h2d.Object {

	public var box(default, null) : KubScroll;
	var panel : DatabasePanel;
	var w : Int;
	var cy = 0.;

	public function new( panel : DatabasePanel, parent : h2d.Object, w : Int, h : Int ) {
		super(parent);
		this.panel = panel;
		this.w = w;
		box = new KubScroll(this, w, h);
	}

	public function show( e : Block ) {
		box.clear();
		cy = 0;
		if( e == null ) {
			line(KubText.get("kub.choose"), 1.5, Theme.DIM);
			box.done();
			return;
		}
		var info = panel.info, d = KubData.get();
		var st = Kubindex.state(info, e);
		var o = box.content;
		var g = new h2d.Graphics(o);
		Theme.rect(g, 0, 0, 104, 104, 0xFFFFFF, 0.06);
		KubDraw.icon(o, e, st, 96, panel.atlas).setPosition(4, 4);
		var n = Theme.text(o, e.getName(), 2.1, Theme.TEXT, 118, 4);
		n.maxWidth = (w - 126) / n.scaleX;
		var sy = 8 + n.textHeight * n.scaleY;
		Theme.text(o, KubText.get(st == Got ? "kub.status.got" : "kub.status.seen"), 1.35, st == Got ? Theme.CYAN : Theme.DIM, 118, sy);
		var tags = [for( c in [CPlanet, CAnomaly, CComet, CCraft, CSpecial] ) if( d.has(e, c) ) KubText.get(tagKey(c))];
		Theme.text(o, tags.join("  ·  "), 1.2, Theme.ACCENT, 118, sy + 24);
		cy = 116;
		header(KubText.get("kub.where"));
		for( l in d.placeLines(info, e) ) line(l, 1.3, Theme.TEXT);
		if( st != Got ) {
			cy += 8;
			line(KubText.get("kub.locked"), 1.3, Theme.DIM);
			box.contentH = cy;
			box.done();
			return;
		}
		cy += 6;
		// las cargas que da al minarlo (citronox viejo, plantas...)
		var drop = e.getDrop();
		if( drop != null && drop.b.charge != null ) line(KubText.get("kub.drop.charge").split("%n%").join("" + drop.count).split("%c%").join(drop.b.getName()), 1.3, Theme.TEXT);
		var c = d.chargeFor(e);
		if( c != null ) line(KubText.get("kub.charge").split("%n%").join(KubDraw.chargeName(c)), 1.3, Theme.TEXT);
		var s = Kubindex.stat(info, e, false);
		line(KubText.get("kub.stats").split("%p%").join("" + (s == null ? 0 : s.p)).split("%b%").join("" + (s == null ? 0 : s.b)), 1.3, Theme.TEXT);
		recipes(KubText.get("kub.made"), d.recipesMaking(e));
		recipes(KubText.get("kub.uses"), d.recipesUsing(e));
		box.contentH = cy;
		box.done();
	}

	static function tagKey( c : KubCat ) : String {
		return switch( c ) {
			case CPlanet: "kub.tag.planet";
			case CAnomaly: "kub.tag.anomaly";
			case CComet: "kub.tag.comet";
			case CCraft: "kub.tag.craft";
			case CSpecial: "kub.tag.special";
		}
	}

	function header( s : String ) {
		cy += 4;
		Theme.text(box.content, s, 1.6, Theme.ACCENT, 0, cy);
		cy += 26;
	}

	function line( s : String, scale : Float, col : Int ) {
		var t = Theme.text(box.content, s, scale, col, 0, cy);
		t.maxWidth = (w - 10) / scale;
		cy += t.textHeight * scale + 6;
	}

	function recipes( title : String, list : Array<CraftRule> ) {
		if( list.length == 0 ) return;
		header(title);
		for( r in list ) {
			var o = new h2d.Object(box.content);
			o.y = cy;
			KubDraw.recipe(o, r, panel.info, panel.atlas, panel.pick, box);
			cy += KubDraw.RECIPE_H;
		}
	}
}
