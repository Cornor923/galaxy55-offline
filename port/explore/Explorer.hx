import Ui;
import ExpData;
import ExpRoom;

/** Entidad del mapa (Entity.hx del original): posicion, velocidad y viaje hacia un objetivo. */
class ExpEntity {
	public var x = 0.;
	public var y = 0.;
	public var dx = 0.1;
	public var dy = 0.1;
	public var rotation = 0.;
	public var scale = 1.;
	public var speed = 0.19;
	public var zoom = 0.;
	public var target : { x : Float, y : Float };
	public var onArrive : Void -> Void;
	public var onArriveDist = 0;
	public var dataId = -1;

	public function new() {}

	public inline function getAngleRad() return (dx == 0 && dy == 0) ? rotation * Math.PI / 180 : Math.atan2(dy, dx);
	public inline function getScreenSpeed() return Math.sqrt(dx * dx + dy * dy);
	public inline function getTargetDist() return target == null ? 0. : Math.sqrt((target.x - x) * (target.x - x) + (target.y - y) * (target.y - y));

	/** Entity.update */
	public function update( tmod : Float ) {
		var d = target == null ? 0. : getTargetDist();
		if( target != null ) {
			var max = 3 * speed;
			var ang = Math.atan2(target.y - y, target.x - x);
			var s = d * (0.01 + 0.001 * speed);
			if( s < -max ) s = -max;
			if( s > max ) s = max;
			dx += Math.cos(ang) * s;
			dy += Math.sin(ang) * s;
		}
		x += dx * tmod;
		y += dy * tmod;
		dx *= Math.pow(0.83, tmod);
		dy *= Math.pow(0.83, tmod);
		if( target != null ) {
			if( d <= onArriveDist && onArrive != null ) {
				var cb = onArrive;
				onArrive = null;
				cb();
			}
			if( target != null && d <= 1 && getScreenSpeed() <= 0.1 ) {
				x = target.x;
				y = target.y;
				target = null;
				dx = 0;
				dy = 0;
				var cb = onArrive;
				onArrive = null;
				if( cb != null ) cb();
			}
		}
		if( Math.abs(dx) <= 0.001 ) dx = 0;
		if( Math.abs(dy) <= 0.001 ) dy = 0;
	}
}

/** Un objeto pulsable del mapa: sistema (en el sector) o planeta (en el sistema solar). */
private class Spot {
	public var e = new ExpEntity();
	public var obj : h2d.Object;
	public var half = 20.;
	public var system : ExpSystem;
	public var planet : ExpPlanet;
	public function new() {}
}

/** Una escena del mapa: una habitacion (fondos con paralaje) y sus capas ya como imagenes. */
private class View {
	public var room : ExpRoom;
	public var root : h2d.Object;
	public var layers : Array<{ l : ExpLayer, b : h2d.Bitmap }> = [];
	public var viewX = 0.;
	public var viewY = 0.;
	public function new() {}
}

/**
 * Mapa del explorador (Manager.hx del original): vista del sector y de cada sistema solar, con la nave, el viaje con clic y la
 * ventana de cada planeta. Se dibuja en un lienzo de 900x450 que se escala a la ventana.
 */
class Explorer extends h2d.Object {
	public static inline var VW = 900;
	public static inline var VH = 450;

	public var infos(default, null) : ExpInfos;
	/** el jugador ha pedido volver a la nave */
	public dynamic function onExit() {}
	/** el jugador quiere aterrizar en un planeta */
	public dynamic function onLand( p : ExpPlanet, s : ExpSystem ) {}
	/** la nave ha cambiado de sitio en el mapa: [0, x, y] sector, [1, sistema], [2, planeta] (para guardarlo) */
	public dynamic function onPos( pos : Array<Int> ) {}

	var content : h2d.Object;
	var bgBmp : h2d.Bitmap;
	var sector : View;
	var solar : View;
	var solarStars : View;
	var current : View;
	var inSolar = false;
	var curSystem : ExpSystem;
	var tiles : h2d.Tile;
	var ship = new ExpEntity();
	var shipObj : h2d.Graphics;
	var shipBmp : h2d.Bitmap;
	var shipTiles : Array<h2d.Tile>;
	var shipFrames : Array<flash.display.BitmapData>;
	var shipWorld : h2d.Object;
	var cursor : h2d.Graphics;
	var cursorE = new ExpEntity();
	var cursorAlpha = 1.;
	var cursorRot = 0.;
	var worldSector : h2d.Object;
	var worldSolar : h2d.Object;
	var sectorSpots : Array<Spot> = [];
	var solarSpots : Array<Spot> = [];
	var targetSpot : Spot;
	var down : Spot;
	var downOnBg = false;
	var fade : h2d.Bitmap;
	var fadeAlpha = 1.;
	var fadeDir = 0;
	var fadeCb : Void -> Void;
	var locked = false;
	var burn : h2d.Bitmap;
	var overlay : h2d.Object;
	var popText : h2d.Text;
	var popTime = 0.;
	// ventana de planeta
	var win : h2d.Object;
	var winSpot : Spot;
	var winButtons : Array<{ o : h2d.Interactive, g : h2d.Graphics, cb : Void -> Void }> = [];
	var zoomT = 0.;
	var zoomGoal = 0.;
	var scanProgress = -1.;
	var scanPlanet : ExpPlanet;
	var scanBar : h2d.Graphics;

	public function new( parent : h2d.Object, infos : ExpInfos, ?frames : Array<flash.display.BitmapData> ) {
		super(parent);
		this.infos = infos;
		content = new h2d.Object(this);
		bgBmp = new h2d.Bitmap(h2d.Tile.fromColor(0), content);

		// graficos del explorador
		var png = hxd.res.Any.fromBytes("tiles.png", Res.exploreBytes("tiles.png")).toImage();
		var px = png.getPixels();
		px.convert(BGRA);
		ExpRoom.tiles = new flash.display.BitmapData(px.width, px.height, true, 0);
		for( i in 0...px.width * px.height ) ExpRoom.tiles.px[i] = px.bytes.getInt32(i * 4);
		var img = hxd.res.Any.fromBytes("tiles.png", Res.exploreBytes("tiles.png")).toTile();
		img.getTexture().filter = Nearest;
		tiles = img;

		// sector
		sector = makeView(new ExpRoom(infos.sector.seed, VW, VH));
		sector.room.generateSectorBackground(infos.sector.width, infos.sector.height);
		buildLayers(sector);
		worldSector = new h2d.Object(content);
		for( si in infos.systems ) addSystem(si);

		// nave y cursor
		shipWorld = new h2d.Object(content);
		shipObj = new h2d.Graphics(shipWorld);
		shipObj.lineStyle(1, 0x495776, 0.8);
		shipObj.beginFill(0xACB6CC, 1);
		shipObj.moveTo(-8, -5);
		shipObj.lineTo(8, 0);
		shipObj.lineTo(-8, 5);
		shipObj.endFill();
		if( frames != null && frames.length > 0 ) {
			shipTiles = [];
			shipFrames = frames;
			for( bd in frames ) shipTiles.push(bmpTile(bd, true).center());
			shipBmp = new h2d.Bitmap(shipTiles[0], shipWorld);
			shipBmp.setScale(128 / frames[0].width);
			shipObj.visible = false;
		}
		cursor = new h2d.Graphics(shipWorld);
		cursor.lineStyle(3, 0xC8D9F2, 1);
		var w = 8.;
		cursor.moveTo(-w, 0);
		for( i in 1...9 ) cursor.lineTo(-Math.cos(i / 8 * Math.PI / 2) * w, -Math.sin(i / 8 * Math.PI / 2) * w);
		cursor.moveTo(w, 0);
		for( i in 1...9 ) cursor.lineTo(Math.cos(i / 8 * Math.PI / 2) * w, Math.sin(i / 8 * Math.PI / 2) * w);

		// calor del sol (burn)
		burn = new h2d.Bitmap(h2d.Tile.fromColor(0xFFFFFF, VW, VH), content);
		burn.blendMode = Add;
		burn.visible = false;

		// bordes oscuros (initBorders)
		var bpx = hxd.Pixels.alloc(VW, VH, BGRA);
		for( y in 0...VH )
			for( x in 0...VW ) {
				var d = Math.min(Math.min(x, VW - 1 - x), Math.min(y, VH - 1 - y));
				var a = Math.max(0, 1 - d / 30);
				bpx.bytes.setInt32((x + y * VW) * 4, (Std.int(a * a * 0.9 * 255) << 24));
			}
		var btex = new h3d.mat.Texture(VW, VH);
		btex.uploadPixels(bpx);
		new h2d.Bitmap(h2d.Tile.fromTexture(btex), content);

		// lineas de barrido (Buffer.makeScanline): una linea oscura cada 3 pixeles
		var spx = hxd.Pixels.alloc(1, VH, BGRA);
		for( y in 0...VH ) spx.bytes.setInt32(y * 4, (y % 3 == 2) ? (Std.int(0.22 * 255) << 24) : 0);
		var stex = new h3d.mat.Texture(1, VH);
		stex.uploadPixels(spx);
		var scan = new h2d.Bitmap(h2d.Tile.fromTexture(stex), content);
		scan.scaleX = VW;

		overlay = new h2d.Object(content);
		popText = Theme.text(overlay, "", 4., 0xFFFFFF, 0, 0);
		popText.dropShadow = { dx : 1, dy : 2, color : 0, alpha : 0.8 };
		popText.visible = false;

		fade = new h2d.Bitmap(h2d.Tile.fromColor(0x000000, VW, VH), content);

		// posicion inicial de la nave
		current = sector;
		setBg(sector.room.bgColor);
		switch( infos.shipPos ) {
		case PInSector(x, y):
			var pt = sector.room.gridToMap(x, y);
			ship.x = pt.x;
			ship.y = pt.y;
		default:
			ship.x = sector.room.center.x;
			ship.y = sector.room.center.y;
		}
		sector.viewX = ship.x;
		sector.viewY = ship.y;
		ship.speed = shipSpeed();
		// la nave estaba en un sistema o junto a un planeta (Manager.start)
		switch( infos.shipPos ) {
		case PPlanet(id):
			for( si in infos.systems )
				for( p in si.planets )
					if( p.id == id ) {
						buildSolar(si, 0, id);
						popString(si.name);
					}
		case PInSystem(id):
			for( si in infos.systems )
				if( si.id == id ) {
					buildSolar(si, 0, -1);
					popString(si.name);
				}
		default:
		}
		layout();
		update(0);
		fadeIn(); // entrada suave desde negro (initMask)
	}

	/** Const.shipSpeed(motores, peso): motores y bloques de la nave por defecto */
	function shipSpeed() : Float {
		var data = ShipData.load(Common.Const.DEFAULT_SHIP);
		var engines = 0;
		for( c in data.cells ) if( c.id == Type.enumIndex(Common.BlockKind.BShipEngine) ) engines++;
		return Common.Const.shipSpeed(engines, data.cells.length);
	}

	// ---------------------------------------------------------------- imagenes y fondo

	function bmpTile( bd : flash.display.BitmapData, linear = false, premultiply = false ) : h2d.Tile {
		var px = hxd.Pixels.alloc(bd.width, bd.height, BGRA);
		for( i in 0...bd.width * bd.height ) {
			var c = bd.px[i];
			if( premultiply ) {
				// la mezcla SCREEN de Heaps espera el color ya multiplicado por el alfa
				var a = (c >>> 24) & 0xFF;
				c = (a << 24) | (Std.int(((c >> 16) & 0xFF) * a / 255) << 16) | (Std.int(((c >> 8) & 0xFF) * a / 255) << 8) | Std.int((c & 0xFF) * a / 255);
			}
			px.bytes.setInt32(i * 4, c);
		}
		var tex = new h3d.mat.Texture(bd.width, bd.height);
		tex.uploadPixels(px);
		tex.filter = linear ? Linear : Nearest;
		return h2d.Tile.fromTexture(tex);
	}

	function makeView( room : ExpRoom ) : View {
		var v = new View();
		v.room = room;
		v.root = new h2d.Object(content);
		return v;
	}

	function buildLayers( v : View ) {
		for( l in v.room.layers ) {
			var b = new h2d.Bitmap(bmpTile(l.bd, false, l.screen), v.root);
			b.blendMode = l.screen ? Screen : (l.additive ? Add : Alpha);
			v.layers.push({ l : l, b : b });
		}
		v.layers.sort(function(a, b) return Reflect.compare(a.l.z, b.l.z));
		for( o in v.layers ) v.root.addChild(o.b);
	}

	function disposeView( v : View ) {
		if( v == null ) return;
		for( o in v.layers ) o.b.tile.getTexture().dispose();
		v.root.remove();
	}

	function setBg( col : Int ) {
		// Manager.setBg: se limita el brillo y el degradado va hacia un tono mas oscuro
		col = mt.deepnight.Color.capBrightnessInt(col, 0.3);
		var dark = mt.deepnight.Color.brightnessInt(col, -0.2);
		var px = hxd.Pixels.alloc(1, VH, BGRA);
		for( y in 0...VH ) px.bytes.setInt32(y * 4, 0xFF000000 | mt.deepnight.Color.interpolateInt(col, dark, y / (VH - 1)));
		var tex = new h3d.mat.Texture(1, VH);
		tex.uploadPixels(px);
		bgBmp.tile = h2d.Tile.fromTexture(tex);
		bgBmp.scaleX = VW;
	}

	function frame( i : Int, size = 32 ) : h2d.Tile return tiles.sub(i * size, 32, size, size, -size * 0.5, -size * 0.5);

	function label( parent : h2d.Object, str : String, scale : Float, col : Int ) {
		var t = Theme.text(parent, str, scale, col, 0, 0);
		t.dropShadow = { dx : 1, dy : 1, color : 0x0D1118, alpha : 1 };
		return t;
	}

	// ---------------------------------------------------------------- sector

	function addSystem( si : ExpSystem ) {
		var pt = sector.room.gridToMap(si.x, si.y);
		var sp = new Spot();
		sp.system = si;
		sp.e.dataId = si.id;
		sp.e.x = pt.x;
		sp.e.y = pt.y;
		var obj = new h2d.Object(worldSector);
		sp.obj = obj;
		switch( si.status ) {
		case SLocked(_):
			new h2d.Bitmap(frame(2), obj);
			sp.half = 16 + 10;
		case SOpen:
			var unexp = 0, active = 0;
			for( p in si.planets ) {
				if( p.status == PUnexplored ) unexp++;
				if( p.status == PActive ) active++;
			}
			var icon = new h2d.Bitmap(frame(active > 0 ? 1 : 0), obj);
			icon.setScale(2);
			if( unexp > 0 ) {
				// el contador es hijo del icono en el original, por eso sale al doble de tamano
				var c = new h2d.Bitmap(tiles.sub(4 * 16, 0, 16, 16, -8, -8), icon);
				c.x = 7;
				c.y = 4;
				var t = Theme.text(c, "" + unexp, 0.8, 0xFFFFFF, -3, -5);
				t.dropShadow = { dx : 0, dy : 1, color : 0, alpha : 1 };
			}
			var name = label(obj, si.name, 1.1, 0xCCD6EC);
			name.y = 16;
			name.x = -Std.int(name.textWidth * name.scaleX * 0.5);
			sp.half = 32 + 15;
		}
		sectorSpots.push(sp);
	}

	// ---------------------------------------------------------------- sistema solar

	function gotoSolar( si : ExpSystem ) {
		locked = true;
		stopShip(true);
		closeWindow();
		var arrival = (180 + ship.rotation) * Math.PI / 180;
		fadeOut(function() {
			buildSolar(si, arrival, -1);
			onPos([1, si.id]);
			popString(si.name);
			locked = false;
			fadeIn();
		});
	}

	/** crea la vista del sistema; con planetId la nave aparece junto a ese planeta (al volver de aterrizar) */
	function buildSolar( si : ExpSystem, arrival : Float, planetId : Int ) {
		curSystem = si;
		sector.root.visible = false;
		worldSector.visible = false;
		disposeView(solar);
		disposeView(solarStars);
		for( s in solarSpots ) s.obj.remove();
		solarSpots = [];
		if( worldSolar != null ) worldSolar.remove();

		var room = new ExpRoom(si.seed, VW, VH);
		room.generateSolarSystem(si);
		solar = makeView(room);
		var stars = new ExpRoom(si.seed, VW, VH);
		stars.bgColor = room.bgColor;
		stars.generateSolarStars();
		solarStars = makeView(stars);
		buildLayers(solarStars);
		buildLayers(solar);
		content.addChildAt(solarStars.root, content.getChildIndex(sector.root) + 1);
		content.addChildAt(solar.root, content.getChildIndex(solarStars.root) + 1);
		worldSolar = new h2d.Object(content);
		content.addChildAt(worldSolar, content.getChildIndex(shipWorld));
		for( pv in room.planetViews ) addPlanet(pv);
		setBg(room.bgColor);

		room.entrance.x = room.center.x + Math.cos(arrival) * Math.min(250, room.exitDist - 10);
		room.entrance.y = room.center.y + Math.sin(arrival) * Math.min(250, room.exitDist - 10);
		var ex = room.entrance.x, ey = room.entrance.y;
		if( planetId >= 0 )
			for( pv in room.planetViews )
				if( pv.infos.id == planetId ) {
					ex = pv.x + 32;
					ey = pv.y;
				}
		solar.viewX = ex;
		solar.viewY = ey;
		solarStars.viewX = ex;
		solarStars.viewY = ey;
		for( o in solarStars.layers ) o.l.zoom = 10; // ANIM_SOLARSTAR_ZOOM
		current = solar;
		inSolar = true;
		ship.x = ex;
		ship.y = ey;
		ship.rotation = planetId >= 0 ? 180 : 180 + arrival * 180 / Math.PI;
		ship.dx = ship.dy = 0;
		cursorAlpha = 0;
	}

	function addPlanet( pv : ExpPlanetView ) {
		var sp = new Spot();
		sp.planet = pv.infos;
		sp.e.dataId = pv.infos.id;
		sp.e.x = pv.x;
		sp.e.y = pv.y;
		var obj = new h2d.Object(worldSolar);
		sp.obj = obj;
		var bmp = new h2d.Bitmap(bmpTile(pv.bd, true).center(), obj);
		bmp.setScale(pv.scale);
		if( pv.icon > 0 ) {
			var ic = new h2d.Bitmap(tiles.sub(pv.icon * 16, 0, 16, 16, -8, -8), obj);
			ic.x = pv.iconX;
			ic.y = pv.iconY;
		}
		if( pv.showName ) {
			var t = label(obj, pv.infos.name, 1.1, 0xFFFFFF);
			t.x = -Std.int(t.textWidth * t.scaleX * 0.5);
			t.y = Std.int(pv.bd.height * pv.scale * 0.3);
		}
		sp.half = pv.bd.width * pv.scale * 0.5 - 10;
		solarSpots.push(sp);
	}

	function gotoSector() {
		locked = true;
		stopShip(true);
		closeWindow();
		var heading = ship.rotation;
		var from = curSystem;
		fadeOut(function() {
			for( s in solarSpots ) s.obj.remove();
			solarSpots = [];
			disposeView(solar);
			disposeView(solarStars);
			solar = null;
			solarStars = null;
			if( worldSolar != null ) worldSolar.remove();
			worldSolar = null;
			sector.root.visible = true;
			worldSector.visible = true;
			current = sector;
			inSolar = false;
			setBg(sector.room.bgColor);
			var pt = sector.room.gridToMap(from.x, from.y);
			ship.x = pt.x;
			ship.y = pt.y;
			ship.rotation = heading;
			ship.dx = ship.dy = 0;
			sector.viewX = ship.x;
			sector.viewY = ship.y;
			curSystem = null;
			burn.visible = false;
			onPos([0, from.x, from.y]);
			locked = false;
			fadeIn();
		});
	}

	// ---------------------------------------------------------------- transiciones, texto y ventana

	function fadeOut( cb : Void -> Void ) {
		fadeDir = 1;
		fadeCb = cb;
		fade.visible = true;
	}

	function fadeIn() {
		fadeDir = -1;
		fadeCb = null;
		fade.visible = true;
	}

	/** Manager.popString: nombre grande que aparece y se desvanece */
	function popString( s : String ) {
		popText.text = s;
		popText.x = Std.int(VW * 0.5 - popText.textWidth * popText.scaleX * 0.5);
		popText.y = Std.int(VH * 0.25);
		popText.visible = true;
		popText.alpha = 0;
		popTime = 0.0001;
	}

	function closeWindow() {
		if( win != null ) {
			win.remove();
			win = null;
		}
		winButtons = [];
		winSpot = null;
		zoomGoal = 0;
	}

	/** Manager.setWindow + addButton: barra superior con el nombre, barra inferior con el boton */
	function openWindow( sp : Spot, title : String, subtitle : String, buttonLabel : String, cb : Void -> Void ) {
		closeWindow();
		winSpot = sp;
		win = new h2d.Object(content);
		var col = 0x726DBC;
		var dark = mt.deepnight.Color.capBrightnessInt(col, 0.2);
		var top = new h2d.Bitmap(h2d.Tile.fromColor(dark, VW, 70, 0.6), win);
		var t = label(top, title, 4., 0xFFFFFF);
		t.x = Std.int(VW * 0.5 - t.textWidth * t.scaleX * 0.5);
		t.y = 14;
		if( subtitle != null ) {
			var st = label(win, subtitle, 1.6, 0xFFFFFF);
			st.x = Std.int(VW * 0.5 - st.textWidth * st.scaleX * 0.5);
			st.y = 76;
		}
		var bottom = new h2d.Bitmap(h2d.Tile.fromColor(dark, VW, 70, 0.6), win);
		bottom.y = VH - 70;
		if( buttonLabel != null ) addButton(buttonLabel, cb);
		zoomGoal = 0.6;
	}

	function addButton( text : String, cb : Void -> Void ) {
		var w = Math.max(128, text.length * 14);
		var col = 0x18E7DC;
		var g = new h2d.Graphics(win);
		g.beginFill(col, 0.3);
		g.drawRect(0, 0, w, 24);
		g.endFill();
		g.lineStyle(1, col, 1);
		g.drawRect(0, 0, w, 24);
		g.x = Std.int(VW * 0.5 - w * 0.5);
		g.y = VH - 70;
		var t = label(g, text, 1.4, 0xFFFFFF);
		t.x = Std.int(w * 0.5 - t.textWidth * t.scaleX * 0.5);
		t.y = 4;
		var it = new h2d.Interactive(w, 24, g);
		it.onOver = function(_) g.alpha = 1.0;
		it.onOut = function(_) g.alpha = 0.8;
		g.alpha = 0.8;
		it.onClick = function(_) {
			g.alpha = 0.5;
			cb();
		};
		winButtons.push({ o : it, g : g, cb : cb });
	}

	// ---------------------------------------------------------------- viaje

	function stopShip( brake = false ) {
		if( brake ) ship.dx = ship.dy = 0;
		targetSpot = null;
		ship.target = null;
	}

	/** Manager.moveShip: hacia un objeto del mapa o hacia un punto libre */
	function moveShip( ?sp : Spot, ?pt : { x : Float, y : Float } ) {
		stopShip();
		if( win != null && (sp == null || sp != winSpot) ) closeWindow();
		if( sp != null ) {
			targetSpot = sp;
			ship.target = { x : sp.e.x, y : sp.e.y };
			cursorAlpha = 1;
			cursorE.scale = 4;
			if( !inSolar ) {
				switch( sp.system.status ) {
				case SOpen:
					ship.onArriveDist = 0;
					ship.onArrive = function() onReachSystem(sp);
				case SLocked(cost):
					ship.onArriveDist = 30;
					ship.onArrive = function() {
						if( winSpot != sp ) openWindow(sp, sp.system.name, sp.system.x + "," + sp.system.y, "" + cost, function() {});
					};
				}
			} else {
				var p = sp.planet;
				ship.onArriveDist = 30;
				ship.onArrive = function() {
					if( winSpot == sp ) return;
					var bname = ExpOffline.BNAMES[ExpOffline.biomeIndex(p.biome)];
					switch( p.status ) {
					case PUnexplored:
						openWindow(sp, p.name, bname, "Escanear", function() startScan(p));
					case PActive, PInvited:
						openWindow(sp, p.name, bname, "Aterrizar", function() onLand(p, curSystem));
					case PAbandonned, PForbidden:
						openWindow(sp, p.name, bname, null, function() {});
					}
				};
			}
		}
		if( pt != null ) {
			var room = current.room;
			var x = Math.max(0, Math.min(room.width - 1, pt.x));
			var y = Math.max(0, Math.min(room.height - 1, pt.y));
			ship.onArrive = null;
			targetSpot = null;
			ship.target = { x : x, y : y };
			cursorE.x = x;
			cursorE.y = y;
			cursorE.scale = 1.5;
			cursorAlpha = 1;
		}
	}

	function onReachSystem( sp : Spot ) {
		locked = true;
		gotoSolar(sp.system);
	}

	/** ServerCall.startGeneratePlanet en modo local: una barra breve y se aterriza */
	function startScan( p : ExpPlanet ) {
		closeWindow();
		locked = true;
		scanPlanet = p;
		scanProgress = 0;
		scanBar = new h2d.Graphics(content);
	}

	// ---------------------------------------------------------------- bucle

	function mouseInMap() : { x : Float, y : Float } {
		var p = new h2d.col.Point(getScene().mouseX, getScene().mouseY);
		content.globalToLocal(p);
		return { x : p.x - VW * 0.5 + current.viewX, y : p.y - VH * 0.5 + current.viewY };
	}

	function hit( pt : { x : Float, y : Float } ) : Spot {
		var list = inSolar ? solarSpots : sectorSpots;
		for( sp in list )
			if( Math.abs(pt.x - sp.e.x) <= sp.half && Math.abs(pt.y - sp.e.y) <= sp.half ) return sp;
		return null;
	}

	public function layout() {
		var s = getScene();
		var w = s != null ? s.width : 1280., h = s != null ? s.height : 720.;
		var k = Math.max(w / VW, h / VH);
		content.setScale(k);
		content.x = (w - VW * k) * 0.5;
		content.y = (h - VH * k) * 0.5;
	}

	/** ZLayer.update: posicion y escala de cada capa segun la camara y el zoom */
	function updateLayers( v : View, vx : Float, vy : Float, zoomAdd : Float ) {
		for( o in v.layers ) {
			var l = o.l;
			var z = l.z;
			var zoom = (l.zoom + zoomAdd) * z * z;
			var s = 1 + zoom * z;
			var x = VW * 0.5 * (1 - z) - l.texWid * 0.5 + (VW * 0.5 + l.xOffset - vx) * z;
			var y = VH * 0.5 * (1 - z) - l.texHei * 0.5 + (VH * 0.5 + l.yOffset - vy) * z;
			var tx = -VW * 0.5 * s + VW * 0.5 + x * (zoom * z) + x;
			var ty = -VH * 0.5 * s + VH * 0.5 + y * (zoom * z) + y;
			if( l.repeat ) {
				while( tx > 0 ) tx -= l.texWid * s;
				while( tx + l.texWid * s < 0 ) tx += l.texWid * s;
				while( ty > 0 ) ty -= l.texHei * s;
				while( ty + l.texHei * s < 0 ) ty += l.texHei * s;
				o.b.setScale(s);
				o.b.setPosition(Math.round(tx), Math.round(ty));
			} else {
				// la imagen se escala primero alrededor de su centro (escala propia de la capa) y despues se aplica el zoom
				var ox = l.bd.width * 0.5 * (1 - l.scaleX), oy = l.bd.height * 0.5 * (1 - l.scaleY);
				var px = tx + ox * s, py = ty + oy * s;
				o.b.setScale(l.scaleX * s);
				if( l.snap ) o.b.setPosition(Math.round(px), Math.round(py)) else o.b.setPosition(px, py);
			}
		}
	}

	/** posicion en pantalla de algo del mundo, con zoom (Entity.update) */
	inline function screenX( x : Float, vx : Float, zoom : Float ) {
		var xm = VW * 0.5 + x - vx;
		return VW * 0.5 + (xm - VW * 0.5) * (1 + zoom);
	}

	inline function screenY( y : Float, vy : Float, zoom : Float ) {
		var ym = VH * 0.5 + y - vy;
		return VH * 0.5 + (ym - VH * 0.5) * (1 + zoom);
	}

	public function update( dt : Float ) {
		var tmod = dt * 30;
		if( getScene() != null ) layout();

		// entrada: clic en un objeto o en un punto libre (Manager.onMouseDown / onMouseUp)
		if( !locked && getScene() != null ) {
			var K = hxd.Key;
			var m = mouseInMap();
			var overButton = false;
			for( b in winButtons ) if( b.o.isOver() ) overButton = true;
			if( K.isPressed(K.MOUSE_LEFT) && !overButton ) {
				down = hit(m);
				downOnBg = down == null;
			}
			if( K.isReleased(K.MOUSE_LEFT) && !overButton ) {
				var h = hit(m);
				if( h != null && h == down ) moveShip(h);
				else if( h == null && downOnBg ) moveShip(null, m);
				down = null;
			}
			if( K.isPressed(K.ESCAPE) ) {
				if( win != null ) {
					closeWindow();
					targetSpot = null;
				} else onExit();
			}
		}

		// barra de escaneo del planeta
		if( scanProgress >= 0 ) {
			scanProgress += dt / 0.8;
			scanBar.clear();
			scanBar.beginFill(0xFFFFFF, 0.15);
			scanBar.drawRect(VW * 0.5 - 150, VH * 0.5, 300, 6);
			scanBar.beginFill(0x18E7DC, 1);
			scanBar.drawRect(VW * 0.5 - 150, VH * 0.5, 300 * Math.min(1, scanProgress), 6);
			scanBar.endFill();
			if( scanProgress >= 1 ) {
				scanProgress = -1;
				scanBar.remove();
				onLand(scanPlanet, curSystem);
			}
		}

		ship.update(tmod);
		if( ship.getScreenSpeed() > 0.3 ) ship.rotation = ship.getAngleRad() * 180 / Math.PI;

		// salida del sistema solar por los bordes (Manager.main)
		if( inSolar && !locked && win == null ) {
			var room = solar.room;
			var d = Math.sqrt((ship.x - room.center.x) * (ship.x - room.center.x) + (ship.y - room.center.y) * (ship.y - room.center.y));
			if( ship.target != null ) {
				var td = Math.sqrt((ship.target.x - room.center.x) * (ship.target.x - room.center.x) + (ship.target.y - room.center.y) * (ship.target.y - room.center.y));
				if( d >= room.exitDist - 30 && td >= room.exitDist ) gotoSector();
			}
			if( !locked && d >= room.exitDist ) stopShip();
		}

		// cursor
		if( ship.target != null ) {
			cursorE.x = ship.target.x;
			cursorE.y = ship.target.y;
		}
		var d = ship.getTargetDist();
		if( targetSpot == null && d < 25 && cursorAlpha > 0 ) cursorAlpha -= 0.1 * tmod;
		if( d >= 25 && cursorAlpha < 1 ) cursorAlpha += 0.1 * tmod;
		if( cursorAlpha < 0 ) cursorAlpha = 0;
		if( cursorE.scale > 1.5 ) cursorE.scale += (1.5 - cursorE.scale) * Math.min(1, 0.25 * tmod);
		cursorRot += 7 * tmod;
		if( cursorRot >= 360 ) cursorRot -= 360;

		// zoom de la ventana (setZoom: 0.6 con la ventana abierta)
		zoomT += (zoomGoal - zoomT) * Math.min(1, 0.12 * tmod);

		// camara (Manager.main: scrolling)
		var spd = 1 - Math.pow(0.9, tmod);
		current.viewX += (ship.x - current.viewX) * spd;
		current.viewY += (ship.y - current.viewY) * spd;
		if( inSolar ) {
			solarStars.viewX = current.viewX;
			solarStars.viewY = current.viewY;
		}

		// capas con paralaje
		updateLayers(sector, sector.viewX, sector.viewY, inSolar ? 0 : zoomT);
		if( inSolar ) {
			updateLayers(solarStars, solarStars.viewX, solarStars.viewY, 0);
			updateLayers(solar, solar.viewX, solar.viewY, zoomT);
		}

		// objetos: pantalla = centro + (posicion - camara), con zoom
		var vx = current.viewX, vy = current.viewY;
		var list = inSolar ? solarSpots : sectorSpots;
		for( sp in list ) {
			sp.obj.setPosition(Std.int(screenX(sp.e.x, vx, zoomT)), Std.int(screenY(sp.e.y, vy, zoomT)));
			sp.obj.setScale(1 + zoomT);
		}
		var sx = Std.int(screenX(ship.x, vx, zoomT)), sy = Std.int(screenY(ship.y, vy, zoomT));
		shipObj.setPosition(sx, sy);
		shipObj.rotation = ship.rotation * Math.PI / 180;
		if( shipBmp != null ) {
			// Manager.main: fotograma segun el rumbo y el resto como giro suave
			var n = shipTiles.length;
			var r = 1 - ((360 + 90 + ship.rotation) % 360) / 360;
			var f = Math.floor((n - 1) * r);
			if( f < 0 ) f = 0;
			if( f > n - 1 ) f = n - 1;
			var delta = n * r - f;
			shipBmp.tile = shipTiles[f];
			shipBmp.rotation = -delta * (360 / n) * Math.PI / 180;
			shipBmp.setPosition(sx, sy);
		}
		cursor.setPosition(Std.int(screenX(cursorE.x, vx, zoomT)), Std.int(screenY(cursorE.y, vy, zoomT)));
		cursor.rotation = cursorRot * Math.PI / 180;
		cursor.setScale(Math.max(1, cursorE.scale) * (1 + zoomT));
		cursor.alpha = Math.max(0, Math.min(1, cursorAlpha));

		// calor del sol (burn)
		if( inSolar ) {
			var room = solar.room;
			var r = 1 - Math.sqrt((ship.x - room.center.x) * (ship.x - room.center.x) + (ship.y - room.center.y) * (ship.y - room.center.y)) / 140;
			if( r > 0 ) {
				var c = mt.deepnight.Color.interpolateInt(room.sunColor, 0xF46800, 0.3);
				burn.color.set(((c >> 16) & 0xFF) / 255, ((c >> 8) & 0xFF) / 255, (c & 0xFF) / 255, 1);
				burn.alpha = Math.min(r, 0.9) + Math.random() * r * 0.1;
			}
			burn.visible = r > 0;
		}

		// texto grande
		if( popTime > 0 ) {
			popTime += dt;
			popText.alpha = popTime < 0.5 ? popTime / 0.5 : (popTime < 1.6 ? 1 : Math.max(0, 1 - (popTime - 1.6) / 1.6));
			if( popTime > 3.2 ) {
				popTime = 0;
				popText.visible = false;
			}
		}

		// transicion de pantalla (fundido a negro)
		if( fadeDir != 0 ) {
			fadeAlpha += fadeDir * dt / 0.4;
			if( fadeAlpha >= 1 ) {
				fadeAlpha = 1;
				fadeDir = 0;
				var cb = fadeCb;
				fadeCb = null;
				if( cb != null ) cb();
			} else if( fadeAlpha <= 0 ) {
				fadeAlpha = 0;
				fadeDir = 0;
			}
		}
		fade.alpha = fadeAlpha;
		fade.visible = fadeAlpha > 0;
	}

	// ---------------------------------------------------------------- pruebas (banco de pruebas Dev)

	public function devClickSystem( id : Int ) {
		if( inSolar ) return;
		for( sp in sectorSpots ) if( sp.system.id == id ) moveShip(sp);
	}

	public function devClickPlanet( id : Int ) {
		if( !inSolar ) return;
		for( sp in solarSpots ) if( sp.planet.id == id ) moveShip(sp);
	}

	public function devPressButton() {
		if( winButtons.length > 0 ) winButtons[0].cb();
	}

	public function devClickPoint( x : Float, y : Float ) moveShip(null, { x : x, y : y });

	public function devInfo() : String {
		var s = (inSolar ? "SISTEMA SOLAR " + curSystem.name : "SECTOR") + " nave=" + Std.int(ship.x) + "," + Std.int(ship.y) + " vel=" + Std.int(ship.getScreenSpeed() * 100) / 100
			+ " camara=" + Std.int(current.viewX) + "," + Std.int(current.viewY) + " bloqueado=" + locked + " ventana=" + (win != null);
		var list = inSolar ? solarSpots : sectorSpots;
		for( sp in list )
			s += "\n  " + (sp.system != null ? "sistema " + sp.system.id + " " + sp.system.name : "planeta " + sp.planet.id + " " + sp.planet.name + " " + sp.planet.biome + " tam=" + sp.planet.size) + " en " + Std.int(sp.e.x) + "," + Std.int(sp.e.y);
		return s;
	}

	/** solo pruebas: hoja con los primeros fotogramas de la nave */
	public function devDumpShip( path : String ) {
		if( shipFrames == null ) return;
		var n = 8, w = shipFrames[0].width;
		var sheet = new flash.display.BitmapData(w * n, w, true, 0xFF404060);
		for( i in 0...n ) sheet.copyPixels(shipFrames[i * 4], shipFrames[i * 4].rect, new flash.geom.Point(i * w, 0), null, null, true);
		sys.io.File.saveBytes(path, BmpPng.encode(sheet));
	}

	public function dispose() {
		disposeView(sector);
		disposeView(solar);
		disposeView(solarStars);
		remove();
	}
}
