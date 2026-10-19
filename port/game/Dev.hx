import Common;

/**
 * Banco de pruebas (solo para desarrollo): ejecuta un guion de ordenes sobre una partida nueva, sin ventana a la vista ni teclado.
 *   hl galaxy55.hl --script=guion.txt [--bgbiome=BIAutumn] [--creative]
 * Una orden por linea, "#" = comentario. Las coordenadas son del planeta salvo las de `tpl`, `setl` y `lookl` (locales a la nave).
 *   wait N                  esperar N actualizaciones
 *   tp x y z [yaw pitch]    colocar al jugador (z = "top" pone sobre el suelo)
 *   tpl x y z [yaw pitch]   igual, con coordenadas locales de la nave
 *   look yaw pitch          orientar la camara
 *   lookat x y z            mirar a ese punto (planeta)    lookl x y z   (nave)
 *   ship | planet           ir a la nave / bajar al planeta
 *   slot N                  elegir casilla (0 = excavador)
 *   give Bloque [n]         meter n bloques (50) en el inventario
 *   set x y z Bloque|none   poner o quitar un bloque (como si el jugador lo hubiera hecho); setl = locales de la nave
 *   activate x y z          activar el bloque de esa celda (puertas, ordenadores); activatel = local
 *   synth N                 usar el ordenador del sintetizador N
 *   jet 1|0                 mantener Espacio (salto y jetpack)
 *   explore                 abrir el mapa de estrellas (explorador); expsys N / expgo x y / expinfo lo manejan
 *   walk avance [lado]      andar (1 = adelante, -1 = atras; 0 0 para parar)
 *   key NOMBRE / unkey      pulsar y soltar una accion: dig, place, jump
 *   print inv|pos|zones|drops|msg|block x y z|select|ship|map [z]
 *   shop / shopclose        abrir y cerrar la tienda del robot;  buy|sell Bloque n   comprar o vender (print credits)
 *   shot nombre             captura en port/out/nombre.png
 *   quit
 */
class Dev {

	static var shoreX = 0;
	static var shoreY = 0;

	/** mensajes de seguimiento del juego (orden `trace`) */
	public static var trace = false;
	var lines : Array<String>;
	var pc = 0;
	var waiting = 0;

	public function new( path : String ) {
		lines = sys.io.File.getContent(path).split("\n").map(StringTools.trim).filter(function(l) return l != "" && l.charAt(0) != "#");
	}

	static function bk( name : String ) : Block {
		var k = Type.createEnum(BlockKind, name);
		return Block.get(k);
	}

	static function f( s : String ) return Std.parseFloat(s);

	/** una orden por actualizacion; devuelve true al terminar */
	public function tick( app : GalaxyApp, g : GameView ) : Bool {
		if( waiting > 0 ) {
			waiting--;
			return false;
		}
		while( pc < lines.length ) {
			var l = lines[pc++];
			var a = l.split(" ").filter(function(s) return s != "");
			var w = g.world;
			var sdx = w.shipDX, sdy = w.shipDY, sz = World.SHIP_Z;
			try {
				switch( a[0] ) {
				case "wait":
					waiting = Std.parseInt(a[1]);
					return false;
				case "tp", "tpl":
					var l = a[0] == "tpl";
					g.px = f(a[1]) + (l ? sdx : 0);
					g.py = f(a[2]) + (l ? sdy : 0);
					g.pz = a[3] == "top" ? w.topCollide(Std.int(g.px), Std.int(g.py)) + 0.01 : f(a[3]) + (l ? sz : 0);
					if( a.length > 5 ) {
						g.yaw = f(a[4]);
						g.pitch = f(a[5]);
					}
				case "look":
					g.yaw = f(a[1]);
					g.pitch = f(a[2]);
				case "lookat", "lookl":
					var l = a[0] == "lookl";
					var dx = f(a[1]) + (l ? sdx : 0) - g.px, dy = f(a[2]) + (l ? sdy : 0) - g.py, dz = f(a[3]) + (l ? sz : 0) - (g.pz + GameView.VIEW_Z);
					g.yaw = Math.atan2(dy, dx);
					g.pitch = Math.atan2(dz, Math.sqrt(dx * dx + dy * dy));
				case "ship": g.gotoShip(true);
				case "planet": g.gotoShip(false);
				case "slot": g.inv.select(Std.parseInt(a[1]));
				case "give":
					var b = bk(a[1]);
					g.inv.addBlocks(b, a.length > 2 ? Std.parseInt(a[2]) : 50);
				case "set", "setl":
					var l = a[0] == "setl";
					var x = Std.parseInt(a[1]) + (l ? sdx : 0), y = Std.parseInt(a[2]) + (l ? sdy : 0), z = Std.parseInt(a[3]) + (l ? sz : 0);
					var b = a[4] == "none" ? null : bk(a[4]);
					w.setBlock(x, y, z, b);
					if( z >= sz ) g.ship.craft(x, y, z, b, g);
				case "setp", "breakp":
					// setp X Y Z BLOQUE / breakp X Y Z: como al jugar (avisa a Process: agua, lava, hierba, anclas)
					var x = Std.parseInt(a[1]), y = Std.parseInt(a[2]);
					var z = StringTools.startsWith(a[3], "top") ? w.topCollide(x, y) + (a[3].length > 3 ? Std.parseInt(a[3].substr(3)) : 0) : Std.parseInt(a[3]);
					var old = w.block(x, y, z);
					if( a[0] == "breakp" ) {
						if( old != null ) g.breakBlock(x, y, z, old);
					} else {
						var nb = a[4] == "none" ? null : bk(a[4]);
						w.setBlock(x, y, z, nb);
						g.process.onSet(x, y, z, old, nb);
					}
					Sys.println(a[0] + " " + x + "," + y + "," + z + " antes=" + (old == null ? "aire" : "" + old.k));
				case "shore":
					// shore: busca una orilla (agua al nivel del mar con roca o tierra al lado) y pone ahi al jugador mirando al agua
					var wl = w.waterLevel(), found = false;
					for( y in 0...w.size ) {
						for( x in 0...w.size ) {
							var b = w.block(x, y, wl - 1);
							if( b == null || b.type != BTWater ) continue;
							var s = w.block(x + 1, y, wl - 1);
							if( s == null || !s.collide || w.block(x + 1, y, wl + 1) != null ) continue;
							g.px = x + 1.5; g.py = y + 0.5; g.pz = w.topCollide(x + 1, y) + 0.01;
							g.yaw = Math.PI; g.pitch = -0.6;
							shoreX = x; shoreY = y;
							Sys.println("shore agua=" + x + "," + y + "," + (wl - 1) + " suelo=" + (x + 1) + " top=" + Std.int(g.pz) + " mar=" + wl);
							found = true;
							break;
						}
						if( found ) break;
					}
					if( !found ) {
						var hist = new Map<Int, Int>();
						for( y in 0...w.size ) for( x in 0...w.size ) for( z in 1...World.HEIGHT ) {
							var b = w.block(x, y, z);
							if( b != null && b.type == BTWater ) { var c = hist.get(z); hist.set(z, c == null ? 1 : c + 1); }
						}
						Sys.println("shore: no hay orilla; mar=" + wl + " bioma=" + w.biomeName + " agua por altura=" + [for( k in hist.keys() ) k + ":" + hist.get(k)].join(" "));
					}
				case "shoredig":
					// shoredig N: zanja de N bloques tierra adentro desde la orilla, de la superficie hasta 2 bajo el mar
					var wl = w.waterLevel();
					for( i in 1...Std.parseInt(a[1]) + 1 ) {
						var x = shoreX + i, y = shoreY;
						var z = w.topCollide(x, y);
						while( z >= wl - 2 ) {
							var old = w.block(x, y, z);
							if( old != null ) g.breakBlock(x, y, z, old);
							z--;
						}
					}
				case "shorecount":
					var n = 0;
					for( i in 1...Std.parseInt(a[1]) + 1 )
						for( z in 1...World.HEIGHT ) {
							var b = w.block(shoreX + i, shoreY, z);
							if( b != null && b.type == BTWater ) n++;
						}
					Sys.println("agua en la zanja: " + n);
				case "count":
					// count BLOQUE X1 Y1 X2 Y2: cuantos hay en esa zona (todas las alturas)
					var kb = bk(a[1]), n = 0;
					for( x in Std.parseInt(a[2])...Std.parseInt(a[4]) + 1 )
						for( y in Std.parseInt(a[3])...Std.parseInt(a[5]) + 1 )
							for( z in 1...World.HEIGHT )
								if( w.block(x, y, z) == kb ) n++;
					Sys.println("count " + a[1] + " = " + n);
				case "fillt":
					// fillt x1 y1 x2 y2 dz1 dz2 BLOQUE: rellena un prisma; dz es la altura sobre el suelo de (x1, y1)
					var base = w.topCollide(Std.parseInt(a[1]), Std.parseInt(a[2]));
					var bb = a[7] == "none" ? null : bk(a[7]);
					for( x in Std.parseInt(a[1])...Std.parseInt(a[3]) + 1 )
						for( y in Std.parseInt(a[2])...Std.parseInt(a[4]) + 1 )
							for( z in base + Std.parseInt(a[5])...base + Std.parseInt(a[6]) + 1 )
								w.setBlock(x, y, z, bb);
				case "activate", "activatel":
					var l = a[0] == "activatel";
					var x = Std.parseInt(a[1]) + (l ? sdx : 0), y = Std.parseInt(a[2]) + (l ? sdy : 0), z = Std.parseInt(a[3]) + (l ? sz : 0);
					var b = w.block(x, y, z);
					Sys.println("activar " + x + "," + y + "," + z + ": " + (b == null ? "nada" : "" + b.k));
					if( b != null ) g.activateBlock(x, y, z, b);
				case "synth":
					var c = g.ship.crafts[Std.parseInt(a[1])];
					g.ship.activateCraft(c.out.x + sdx, c.out.y + sdy, c.out.z + sz, g);
				case "explore": app.startExplorer();
				case "expsys": app.explorer.devClickSystem(Std.parseInt(a[1]));
				case "expplanet": app.explorer.devClickPlanet(Std.parseInt(a[1]));
				case "expbutton": app.explorer.devPressButton();
				case "expgo": app.explorer.devClickPoint(f(a[1]), f(a[2]));
				case "expship": app.explorer.devDumpShip("port/out/" + a[1] + ".png");
				case "expinfo": Sys.println(app.explorer.devInfo());
				case "walk":
					g.debugSpeed = f(a[1]) * 0.15;
					g.debugStrafe = a.length > 2 ? f(a[2]) * 0.15 : 0;
				case "jet": g.debugJet = a[1] == "1";
				case "trace": trace = true;
				case "shop": app.openShop();
				case "screen": @:privateAccess app.show(a[1]);
				case "maxfps": Settings.maxFps = Std.parseInt(a[1]);
				case "fps": Sys.println("fps " + Std.int(hxd.Timer.fps()));
				case "hangar": app.startHangar();
				case "mothership": app.startMothership();
				case "settop":
					// pone un bloque encima del primero que haya en la columna (para probar el hangar)
					var x = Std.parseInt(a[1]), y = Std.parseInt(a[2]), z = 14;
					while( z > 0 && w.block(x, y, z) == null ) z--;
					w.setBlock(x, y, z + 1, bk(a[3]));
					Sys.println("settop " + x + "," + y + "," + (z + 1));
				case "hangarexit": if( g.onHangarExit != null ) g.onHangarExit();
				case "chestclick": if( app.chest != null ) app.chest.click(Std.parseInt(a[1]), Std.parseInt(a[2]));
				case "shopclose": if( app.shop != null ) @:privateAccess app.closeShop();
				case "shopnav": if( app.shop != null ) app.shop.devNav(Std.parseInt(a[1]), Std.parseInt(a[2]), a[3] == "a");
				case "buy", "sell":
					// buy CLAVE n / sell CLAVE n (clave de Market: b<bloque> o c<carga>; o el nombre del bloque, p.ej. BWood)
					var w = Market.ware(a[1]);
					if( w == null ) w = Market.wareOfBlock(bk(a[1]));
					if( app.shop != null ) { if( a[0] == "buy" ) app.shop.doBuy(w, Std.parseInt(a[2])) else app.shop.doSell(w, Std.parseInt(a[2])); }
					Sys.println(a[0] + " " + w.block.k + " x" + a[2] + " -> creditos=" + g.info.credits + " compra=" + g.market.buyPrice(w) + " venta=" + g.market.sellPrice(w));
				case "key": g.debugKey = a[1];
				case "unkey": g.debugKey = null;
				case "print": print(a, g);
				case "shot":
					app.capture("port/out/" + a[1] + ".png", false);
				case "quit":
					return true;
				default:
					Sys.println("orden desconocida: " + l);
				}
			} catch( e : Dynamic ) {
				Sys.println("ERROR en '" + l + "': " + e);
			}
			// tras cada orden se deja pasar una actualizacion para que el juego la procese
			return false;
		}
		return true;
	}

	function print( a : Array<String>, g : GameView ) {
		var w = g.world;
		switch( a[1] ) {
		case "names":
			// nombres de unos bloques en los tres idiomas
			var cur = Lang.cur;
			for( k in a.slice(2) ) {
				var b = bk(k);
				var s = [];
				for( i in 0...3 ) { Lang.setCode(Lang.CODES[i]); s.push(b.getName()); }
				Sys.println(k + ": " + s.join(" | "));
			}
			Lang.setCode(Lang.CODES[cur]);
		case "lightsum":
			// suma de la luz en un cubo (x y z radio): para comprobar que tras editar y deshacer queda igual
			var x = Std.parseInt(a[2]), y = Std.parseInt(a[3]), z = Std.parseInt(a[4]), r = Std.parseInt(a[5]);
			var s = 0, dark = 0;
			for( dz in -r...r + 1 ) for( dy in -r...r + 1 ) for( dx in -r...r + 1 ) {
				var v = @:privateAccess w.lightAt(x + dx, y + dy, z + dz);
				s += v;
				if( v == 0 && w.block(x + dx, y + dy, z + dz) == null ) dark++;
			}
			Sys.println("luz " + s + " huecos a oscuras " + dark);
		case "credits":
			Sys.println("creditos: " + g.info.credits);
		case "hangar":
			Sys.println("hangar: " + (g.hangar == null ? "no" : "valida=" + g.hangarValid + " error=" + g.hangar.error + " velocidad=" + g.hangar.speed) + " mensaje=" + g.message);
		case "wares":
			for( m in Market.wares ) Sys.println("ware " + m.block.k + " " + m.base);
		case "inv":
			Sys.println("inv: " + [for( s in g.inv.inv.t ) s == null ? "-" : Block.all[s.k].k + "x" + s.n].join(" ") + "  casilla=" + g.inv.blockIndex);
		case "pos":
			Sys.println("pos: " + g.px + "," + g.py + "," + g.pz + "  yaw=" + g.yaw + " pitch=" + g.pitch + "  suelo=" + (g.standingBlock == null ? "-" : "" + g.standingBlock.k));
		case "zones":
			for( i in 0...g.ship.crafts.length ) {
				var c = g.ship.crafts[i];
				Sys.println("zona " + i + " (local): x=" + c.x + ".." + (c.x + c.w - 1) + " y=" + c.y + ".." + (c.y + c.h - 1) + " z=" + c.z + " alto=" + c.zSize
					+ (c.out == null ? "" : "  ordenador=" + c.out.x + "," + c.out.y + "," + c.out.z) + "  receta=" + (c.curCraft == null ? "-" : "" + c.curCraft.out));
			}
			Sys.println("nave: entrada local de salida en planeta=" + g.ship.start.x + "," + g.ship.start.y + "," + g.ship.start.z + "  desplazamiento=" + w.shipDX + "," + w.shipDY);
		case "map":
			// corte horizontal de la nave a la altura local z (por defecto la del jugador): letra = inicial del bloque, '.' = aire, '@' = jugador
			var z = a.length > 2 ? Std.parseInt(a[2]) : Std.int(g.pz) - World.SHIP_Z;
			var ox = Std.int(g.px) - w.shipDX, oy = Std.int(g.py) - w.shipDY;
			Sys.println("corte local z=" + z + "  (x " + (ox - 12) + ".." + (ox + 12) + ", y hacia abajo " + (oy - 8) + ".." + (oy + 8) + ")");
			for( dy in -8...9 ) {
				var row = "";
				for( dx in -12...13 ) {
					var b = w.block(ox + dx + w.shipDX, oy + dy + w.shipDY, z + World.SHIP_Z);
					row += dx == 0 && dy == 0 ? "@" : (b == null ? "." : "" + ("" + b.k).charAt(1));
				}
				Sys.println(row);
			}
		case "cells":
			// bloques de la zona 0 del sintetizador (locales de la nave)
			var c = g.ship.crafts[0];
			var out = [];
			for( dx in 0...c.w ) for( dy in 0...c.h ) for( dz in 0...c.heights[dx][dy] ) {
				var b = w.block(c.x + dx + w.shipDX, c.y + dy + w.shipDY, c.z + dz + World.SHIP_Z);
				if( b != null ) out.push(b.k + "@" + (c.x + dx) + "," + (c.y + dy) + "," + (c.z + dz));
			}
			Sys.println("celdas de la zona: " + out.join("  ") + "   texto: " + c.curText);
		case "hit": Sys.println(g.debugPick());
		case "drops": Sys.println("sueltos: " + g.drops.count());
		case "msg": Sys.println("mensaje: " + g.message);
		case "block":
			var b = w.block(Std.parseInt(a[2]), Std.parseInt(a[3]), Std.parseInt(a[4]));
			Sys.println("bloque: " + (b == null ? "nada" : "" + b.k));
		case "select": Sys.println("select: " + (g.select == null ? "ninguno" : g.select.b.k + " @" + g.select.x + "," + g.select.y + "," + g.select.z + " poder=" + g.select.power));
		case "ship": Sys.println("nave en " + g.ship.x + "," + g.ship.y + " suelo z=" + g.ship.z);
		default: Sys.println("print desconocido: " + a[1]);
		}
	}
}
