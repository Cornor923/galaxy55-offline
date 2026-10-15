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
 *   key NOMBRE / unkey      pulsar y soltar una accion: dig, place, jump
 *   print inv|pos|zones|drops|msg|block x y z|select|ship|map [z]
 *   shot nombre             captura en port/out/nombre.png
 *   quit
 */
class Dev {

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
				case "activate", "activatel":
					var l = a[0] == "activatel";
					var x = Std.parseInt(a[1]) + (l ? sdx : 0), y = Std.parseInt(a[2]) + (l ? sdy : 0), z = Std.parseInt(a[3]) + (l ? sz : 0);
					var b = w.block(x, y, z);
					Sys.println("activar " + x + "," + y + "," + z + ": " + (b == null ? "nada" : "" + b.k));
					if( b != null ) g.activateBlock(x, y, z, b);
				case "synth":
					var c = g.ship.crafts[Std.parseInt(a[1])];
					g.ship.activateCraft(c.out.x + sdx, c.out.y + sdy, c.out.z + sz, g);
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
