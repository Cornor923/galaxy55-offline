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
	public var target : { x : Float, y : Float };
	public var onArrive : Void -> Void;
	public var onArriveDist = 0;
	public var dataId = -1;
	public var name : String;

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
			if( d <= 1 && getScreenSpeed() <= 0.1 ) {
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

private typedef SysView = { e : ExpEntity, info : ExpSystem, obj : h2d.Object, half : Float };

/**
 * Mapa del explorador (Manager.hx del original): vista del sector con sus sistemas, la nave y el viaje con clic.
 * Se dibuja en un lienzo de 900x450 que se escala a la ventana.
 */
class Explorer extends h2d.Object {
	public static inline var VW = 900;
	public static inline var VH = 450;

	public var infos(default, null) : ExpInfos;
	public var room(default, null) : ExpRoom;
	/** el jugador ha pedido volver a la nave */
	public dynamic function onExit() {}
	/** el jugador ha llegado a un sistema abierto (de momento solo se avisa) */
	public dynamic function onSystem( s : ExpSystem ) {}

	var content : h2d.Object;
	var bgBmp : h2d.Bitmap;
	var layerObjs : Array<{ l : ExpLayer, b : h2d.Bitmap }> = [];
	var world : h2d.Object;
	var tiles : h2d.Tile;
	var ship = new ExpEntity();
	var shipObj : h2d.Graphics;
	var shipBmp : h2d.Bitmap;
	var shipTiles : Array<h2d.Tile>;
	var shipFrames : Array<flash.display.BitmapData>;
	var cursor : h2d.Graphics;
	var cursorE = new ExpEntity();
	var cursorAlpha = 1.;
	var systems : Array<SysView> = [];
	var viewX = 0.;
	var viewY = 0.;
	var targetObject : SysView;
	var down : SysView;
	var downOnBg = false;
	var tipText : h2d.Text;
	var fade : h2d.Graphics;
	var fadeAlpha = 1.;
	var locked = false;

	public function new( parent : h2d.Object, infos : ExpInfos, ?frames : Array<flash.display.BitmapData> ) {
		super(parent);
		this.infos = infos;
		content = new h2d.Object(this);

		// sector
		room = new ExpRoom(infos.sector.seed, VW, VH);
		room.generateSectorBackground(infos.sector.width, infos.sector.height);

		bgBmp = new h2d.Bitmap(h2d.Tile.fromColor(0), content);
		setBg(room.bgColor);

		for( l in room.layers ) {
			var px = hxd.Pixels.alloc(l.bd.width, l.bd.height, BGRA);
			for( i in 0...l.bd.width * l.bd.height ) px.bytes.setInt32(i * 4, l.bd.px[i]);
			var tex = new h3d.mat.Texture(l.bd.width, l.bd.height);
			tex.uploadPixels(px);
			tex.filter = Nearest;
			var b = new h2d.Bitmap(h2d.Tile.fromTexture(tex), content);
			b.blendMode = l.additive ? Add : Alpha;
			b.alpha = l.alpha;
			layerObjs.push({ l : l, b : b });
		}
		layerObjs.sort(function(a, b) return Reflect.compare(a.l.z, b.l.z));
		for( o in layerObjs ) content.addChild(o.b); // reordena

		world = new h2d.Object(content);
		var img = hxd.res.Any.fromBytes("tiles.png", Res.exploreBytes("tiles.png")).toTile();
		img.getTexture().filter = Nearest;
		tiles = img;
		for( si in infos.systems ) addSystem(si);

		// nave y cursor
		shipObj = new h2d.Graphics(world);
		shipObj.lineStyle(1, 0x495776, 0.8);
		shipObj.beginFill(0xACB6CC, 1);
		shipObj.moveTo(-8, -5);
		shipObj.lineTo(8, 0);
		shipObj.lineTo(-8, 5);
		shipObj.endFill();
		if( frames != null && frames.length > 0 ) {
			// la nave del jugador: fotogramas renderizados desde arriba (SHIP_FRAMES = 32; se muestran a 128 px como en el original)
			shipTiles = [];
			shipFrames = frames;
			for( bd in frames ) {
				var px = hxd.Pixels.alloc(bd.width, bd.height, BGRA);
				for( i in 0...bd.width * bd.height ) px.bytes.setInt32(i * 4, bd.px[i]);
				var tex = new h3d.mat.Texture(bd.width, bd.height);
				tex.uploadPixels(px);
				tex.filter = Linear;
				shipTiles.push(h2d.Tile.fromTexture(tex).center());
			}
			shipBmp = new h2d.Bitmap(shipTiles[0], world);
			shipBmp.setScale(128 / frames[0].width);
			shipObj.visible = false;
		}
		cursor = new h2d.Graphics(world);
		cursor.lineStyle(3, 0xC8D9F2, 1);
		var w = 8.;
		cursor.moveTo(-w, 0);
		for( i in 1...9 ) cursor.lineTo(-Math.cos(i / 8 * Math.PI / 2) * w, -Math.sin(i / 8 * Math.PI / 2) * w);
		cursor.moveTo(w, 0);
		for( i in 1...9 ) cursor.lineTo(Math.cos(i / 8 * Math.PI / 2) * w, Math.sin(i / 8 * Math.PI / 2) * w);

		tipText = Theme.text(content, "", 1.3, 0xB0FA05, 0, 0);
		tipText.dropShadow = { dx : 1, dy : 1, color : 0, alpha : 0.9 };
		tipText.visible = false;

		// bordes oscuros (initBorders): degradado de negro hacia dentro en los cuatro lados
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

		fade = new h2d.Graphics(content);
		fade.beginFill(0x000000, 1);
		fade.drawRect(0, 0, VW, VH);
		fade.endFill();

		// posicion inicial de la nave
		switch( infos.shipPos ) {
		case PInSector(x, y):
			var pt = room.gridToMap(x, y);
			ship.x = pt.x;
			ship.y = pt.y;
		default:
			ship.x = room.center.x;
			ship.y = room.center.y;
		}
		viewX = ship.x;
		viewY = ship.y;
		ship.speed = shipSpeed();
		layout();
		update(0);
	}

	/** Const.shipSpeed(motores, peso): motores y bloques de la nave por defecto */
	function shipSpeed() : Float {
		var data = ShipData.load(Common.Const.DEFAULT_SHIP);
		var engines = 0;
		for( c in data.cells ) if( c.id == Type.enumIndex(Common.BlockKind.BShipEngine) ) engines++;
		return Common.Const.shipSpeed(engines, data.cells.length);
	}

	// ---------------------------------------------------------------- fondo y entidades

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

	function addSystem( si : ExpSystem ) {
		var pt = room.gridToMap(si.x, si.y);
		var e = new ExpEntity();
		e.dataId = si.id;
		e.x = pt.x;
		e.y = pt.y;
		e.name = si.name;
		var obj = new h2d.Object(world);
		var half : Float;
		switch( si.status ) {
		case SLocked(_):
			new h2d.Bitmap(frame(2), obj);
			half = 16 + 10;
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
			var name = Theme.text(obj, si.name, 1.1, 0xCCD6EC, 0, 16);
			name.dropShadow = { dx : 1, dy : 1, color : 0x0D1118, alpha : 1 };
			name.x = -Std.int(name.textWidth * name.scaleX * 0.5);
			half = 32 + 15;
		}
		systems.push({ e : e, info : si, obj : obj, half : half });
	}

	// ---------------------------------------------------------------- viaje

	function stopShip( brake = false ) {
		if( brake ) ship.dx = ship.dy = 0;
		targetObject = null;
		ship.target = null;
		tipText.visible = false;
	}

	/** Manager.moveShip: hacia un sistema o hacia un punto libre */
	public function moveShip( ?sv : SysView, ?pt : { x : Float, y : Float } ) {
		stopShip();
		if( sv != null ) {
			targetObject = sv;
			ship.target = { x : sv.e.x, y : sv.e.y };
			cursorAlpha = 1;
			cursorE.scale = 4;
			switch( sv.info.status ) {
			case SOpen:
				ship.onArriveDist = 0;
				ship.onArrive = function() onReachSystem(sv);
			case SLocked(cost):
				ship.onArriveDist = 30;
				ship.onArrive = function() {
					tipText.text = sv.info.name + " (" + sv.info.x + "," + sv.info.y + ")  -  " + cost;
					tipText.visible = true;
				};
			}
		}
		if( pt != null ) {
			var x = Math.max(0, Math.min(room.width - 1, pt.x));
			var y = Math.max(0, Math.min(room.height - 1, pt.y));
			ship.onArrive = null;
			targetObject = null;
			ship.target = { x : x, y : y };
			cursorE.x = x;
			cursorE.y = y;
			cursorE.scale = 1.5;
			cursorAlpha = 1;
		}
	}

	function onReachSystem( sv : SysView ) {
		onSystem(sv.info);
	}

	// ---------------------------------------------------------------- bucle

	var cursorRot = 0.;

	function mouseInMap() : { x : Float, y : Float } {
		var p = new h2d.col.Point(getScene().mouseX, getScene().mouseY);
		content.globalToLocal(p);
		return { x : p.x - VW * 0.5 + viewX, y : p.y - VH * 0.5 + viewY };
	}

	function hit( pt : { x : Float, y : Float } ) : SysView {
		for( sv in systems )
			if( Math.abs(pt.x - sv.e.x) <= sv.half && Math.abs(pt.y - sv.e.y) <= sv.half ) return sv;
		return null;
	}

	/** solo pruebas (banco de pruebas Dev) */
	public function devClickSystem( id : Int ) {
		for( sv in systems ) if( sv.info.id == id ) moveShip(sv);
	}
	/** solo pruebas: hoja con los primeros fotogramas de la nave */
	public function devDumpShip( path : String ) {
		if( shipFrames == null ) return;
		var n = 8, w = shipFrames[0].width;
		var sheet = new flash.display.BitmapData(w * n, w, true, 0xFF404060);
		for( i in 0...n ) sheet.copyPixels(shipFrames[i * 4], shipFrames[i * 4].rect, new flash.geom.Point(i * w, 0), null, null, true);
		sys.io.File.saveBytes(path, BmpPng.encode(sheet));
	}
	public function devClickPoint( x : Float, y : Float ) moveShip(null, { x : x, y : y });
	public function devInfo() : String {
		var s = "nave=" + Std.int(ship.x) + "," + Std.int(ship.y) + " vel=" + Std.int(ship.getScreenSpeed() * 100) / 100 + " camara=" + Std.int(viewX) + "," + Std.int(viewY) + " velocidadNave=" + ship.speed;
		for( sv in systems ) s += "
  sistema " + sv.info.id + " en " + Std.int(sv.e.x) + "," + Std.int(sv.e.y) + " " + sv.info.status;
		return s;
	}

	public function layout() {
		var s = getScene();
		var w = s != null ? s.width : 1280., h = s != null ? s.height : 720.;
		// el lienzo cubre la pantalla (se recorta un poco por los lados si no es 2:1)
		var k = Math.max(w / VW, h / VH);
		content.setScale(k);
		content.x = (w - VW * k) * 0.5;
		content.y = (h - VH * k) * 0.5;
	}

	public function update( dt : Float ) {
		var tmod = dt * 30;
		if( getScene() != null ) layout();

		// entrada: clic en un sistema o en un punto libre (Manager.onMouseDown / onMouseUp)
		if( !locked && getScene() != null ) {
			var K = hxd.Key;
			var m = mouseInMap();
			if( K.isPressed(K.MOUSE_LEFT) ) {
				down = hit(m);
				downOnBg = down == null;
			}
			if( K.isReleased(K.MOUSE_LEFT) ) {
				var h = hit(m);
				if( h != null && h == down ) moveShip(h);
				else if( h == null && downOnBg ) moveShip(null, m);
				down = null;
			}
			if( K.isPressed(K.ESCAPE) ) onExit();
		}

		ship.update(tmod);
		if( ship.getScreenSpeed() > 0.3 ) ship.rotation = ship.getAngleRad() * 180 / Math.PI;

		// cursor
		if( ship.target != null ) {
			cursorE.x = ship.target.x;
			cursorE.y = ship.target.y;
		}
		var d = ship.getTargetDist();
		if( targetObject == null && d < 25 && cursorAlpha > 0 ) cursorAlpha -= 0.1 * tmod;
		if( d >= 25 && cursorAlpha < 1 ) cursorAlpha += 0.1 * tmod;
		if( cursorAlpha < 0 ) cursorAlpha = 0;
		if( cursorE.scale > 1.5 ) cursorE.scale += (1.5 - cursorE.scale) * Math.min(1, 0.25 * tmod);
		cursorRot += 7 * tmod;
		if( cursorRot >= 360 ) cursorRot -= 360;

		// camara (Manager.main: scrolling)
		var spd = 1 - Math.pow(0.9, tmod);
		viewX += (ship.x - viewX) * spd;
		viewY += (ship.y - viewY) * spd;

		// capas con paralaje (ZLayer.update)
		for( o in layerObjs ) {
			var l = o.l;
			var z = l.z;
			var x = VW * 0.5 * (1 - z) - l.texWid * 0.5 + (VW * 0.5 + l.xOffset - viewX) * z;
			var y = VH * 0.5 * (1 - z) - l.texHei * 0.5 + (VH * 0.5 + l.yOffset - viewY) * z;
			if( l.repeat ) {
				while( x > 0 ) x -= l.texWid;
				while( x + l.texWid < 0 ) x += l.texWid;
				while( y > 0 ) y -= l.texHei;
				while( y + l.texHei < 0 ) y += l.texHei;
				o.b.setPosition(Math.round(x), Math.round(y));
			} else {
				o.b.setScale(l.scaleX);
				o.b.setPosition(Math.round(x + l.bd.width * 0.5 * (1 - l.scaleX)), Math.round(y + l.bd.height * 0.5 * (1 - l.scaleY)));
			}
		}

		// entidades: pantalla = centro + (posicion - camara)
		world.setPosition(Std.int(VW * 0.5 - viewX), Std.int(VH * 0.5 - viewY));
		for( sv in systems ) sv.obj.setPosition(Std.int(sv.e.x), Std.int(sv.e.y));
		shipObj.setPosition(Std.int(ship.x), Std.int(ship.y));
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
			shipBmp.setPosition(Std.int(ship.x), Std.int(ship.y));
		}
		cursor.setPosition(Std.int(cursorE.x), Std.int(cursorE.y));
		cursor.rotation = cursorRot * Math.PI / 180;
		cursor.setScale(Math.max(1, cursorE.scale));
		cursor.alpha = Math.max(0, Math.min(1, cursorAlpha));
		if( targetObject != null ) {
			tipText.x = targetObject.e.x - viewX + VW * 0.5 + 20;
			tipText.y = targetObject.e.y - viewY + VH * 0.5 - 10;
		}
		tipText.x = Std.int(VW * 0.5 + (ship.target != null ? ship.target.x : ship.x) - viewX + 20);
		tipText.y = Std.int(VH * 0.5 + (ship.target != null ? ship.target.y : ship.y) - viewY - 10);

		// entrada suave desde negro (initMask)
		if( fadeAlpha > 0 ) {
			fadeAlpha = Math.max(0, fadeAlpha - dt / 1.0);
			fade.alpha = fadeAlpha;
			fade.visible = fadeAlpha > 0;
		}
	}

	public function dispose() {
		for( o in layerObjs ) o.b.tile.getTexture().dispose();
		remove();
	}
}
