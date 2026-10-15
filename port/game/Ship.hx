import Common;

/**
 * La nave del jugador (ShipLogic del original). Es un volumen de bloques colgado sobre el planeta, desde z = 130, centrado sobre el
 * punto de aterrizaje. Se baja al planeta pisando el teletransportador (BShipEntry) y se vuelve entrando en el haz de luz que marca
 * el punto de aterrizaje.
 */
class Ship {

	/** aterrizaje en el planeta */
	public var x(default, null) : Int;
	public var y(default, null) : Int;
	/** altura del suelo en el punto de aterrizaje (Ship.z) */
	public var z(default, null) = 0;
	/** posicion del jugador al aparecer en la nave (encima del teletransportador), en coordenadas del planeta */
	public var start(default, null) : { x : Int, y : Int, z : Int };
	public var world(default, null) : World;
	/** zonas de los sintetizadores: lo unico de la nave donde se pueden poner y quitar bloques */
	public var crafts(default, null) : Array<ShipData.CraftArea>;

	/** true si la posicion (en coordenadas del planeta) esta en la zona libre sobre una losa de ensamblaje (CraftPoint.inside) */
	public function inCraft( wx : Int, wy : Int, wz : Int ) : Bool {
		if( wz < World.SHIP_Z ) return false;
		var s = planet.size;
		var lx = (wx - planet.shipDX) % s, ly = (wy - planet.shipDY) % s;
		if( lx < 0 ) lx += s;
		if( ly < 0 ) ly += s;
		var lz = wz - World.SHIP_Z;
		for( c in crafts )
			if( c.inside(lx, ly, lz) ) return true;
		return false;
	}

	var planet : World;
	var beam : h3d.scene.Mesh;
	var beamUv : h3d.shader.UVDelta;
	var time = 0.;
	var needRecal = true;

	public function new( planet : World, atlas : h3d.mat.Texture, parent : h3d.scene.Object, ?edits : Array<Int> ) {
		this.planet = planet;
		var data = ShipData.load(Const.DEFAULT_SHIP);
		crafts = data.crafts;
		// el sitio de aterrizaje es fijo para cada planeta (misma semilla = mismo sitio), como en Game.placeShip
		var p = planet.startPlace(new mt.Rand(planet.seed ^ 0x5A17));
		x = p != null ? p.x : 14;
		y = p != null ? p.y : 12;
		start = { x : data.entry.x, y : data.entry.y, z : data.entry.z + 1 + World.SHIP_Z };
		var dx = x - start.x, dy = y - start.y;
		world = new World(planet.seed, planet.biomeName, 1, parent, atlas, false, edits, data, planet.sky);
		var guard = 0;
		while( !world.isReady() && guard++ < 1000 ) world.step(1000);
		planet.ship = world;
		planet.shipDX = dx;
		planet.shipDY = dy;
		world.root.setPosition(dx, dy, World.SHIP_Z);
		// el punto de aparicion del jugador, ya en coordenadas del planeta
		start = { x : x, y : y, z : start.z };
		recalDock();
		buildBeam(planet);
	}

	/** altura del suelo bajo la nave (ShipLogic.update: needRecal) */
	public function recalDock() {
		var zz = World.HEIGHT - 1;
		while( zz > 0 && !planet.collidePoint(x + 0.5, y + 0.5, zz) ) zz--;
		z = zz + 1;
		needRecal = false;
		updateBeam();
	}

	// ---------------------------------------------------------------- haz de luz del punto de aterrizaje

	function buildBeam( planet : World ) {
		var segs = 6;
		var pts = [], uvs = [], idx = new hxd.IndexBuffer();
		for( i in 0...segs ) {
			var a0 = i * Math.PI * 2 / segs, a1 = (i + 1) * Math.PI * 2 / segs;
			var r = 0.48;
			var b = pts.length;
			pts.push(new h3d.col.Point(Math.cos(a0) * r, Math.sin(a0) * r, 0));
			pts.push(new h3d.col.Point(Math.cos(a1) * r, Math.sin(a1) * r, 0));
			pts.push(new h3d.col.Point(Math.cos(a1) * r, Math.sin(a1) * r, 1));
			pts.push(new h3d.col.Point(Math.cos(a0) * r, Math.sin(a0) * r, 1));
			uvs.push(new h3d.prim.UV(i / segs, 1));
			uvs.push(new h3d.prim.UV((i + 1) / segs, 1));
			uvs.push(new h3d.prim.UV((i + 1) / segs, 0));
			uvs.push(new h3d.prim.UV(i / segs, 0));
			idx.push(b); idx.push(b + 1); idx.push(b + 2);
			idx.push(b); idx.push(b + 2); idx.push(b + 3);
		}
		var poly = new h3d.prim.Polygon(pts, idx);
		poly.uvs = uvs;
		var tex = hxd.res.Any.fromBytes("ship_halo.png", Res.bytes("ship_halo.png")).toTexture();
		tex.wrap = Repeat;
		tex.filter = Linear;
		var mat = h3d.mat.Material.create(tex);
		mat.shadows = false;
		mat.mainPass.enableLights = false;
		mat.mainPass.culling = None;
		mat.blendMode = Add;
		mat.mainPass.depthWrite = false;
		mat.mainPass.setPassName("alpha");
		mat.color.set(1, 1, 1, 0.5);
		beamUv = new h3d.shader.UVDelta();
		beamUv.uvScale.set(segs / 3, 1);
		mat.mainPass.addShader(beamUv);
		mat.mainPass.addShader(planet.sky.fog);
		beam = new h3d.scene.Mesh(poly, mat, planet.root);
		updateBeam();
	}

	function updateBeam() {
		if( beam == null ) return;
		var h = start.z - z;
		beam.setPosition(x + 0.5, y + 0.5, z);
		beam.scaleZ = h > 0 ? h : 0.01;
	}

	public function dispose() {
		if( beam != null ) beam.remove();
		beam = null;
	}

	// ---------------------------------------------------------------- teletransporte (ShipLogic.update)

	public function update( g : GameView, tmod : Float ) {
		time += tmod;
		world.flush();
		if( needRecal ) recalDock();
		beamUv.uvDelta.set(time / 100, 0);

		var s = planet.size;
		var ddx = g.wrapDist(x + 0.5 - g.px), ddy = g.wrapDist(y + 0.5 - g.py);
		var d = Math.sqrt(ddx * ddx + ddy * ddy);
		var onShipEntry = g.pz > Const.SIZE && g.standingBlock == Block.all[Type.enumIndex(BShipEntry)];
		if( d < 0.6 && g.pz >= z && (g.pz <= Const.SIZE || onShipEntry) ) {
			if( g.enteringShip >= 0 && g.standingBlock != null ) {
				g.enteringShip += tmod * 0.05;
				if( g.enteringShip >= 1.5 ) g.gotoShip(!onShipEntry);
			}
		} else {
			g.enteringShip -= tmod * 0.1;
			if( g.enteringShip < 0 ) g.enteringShip = 0;
		}
	}

	// ---------------------------------------------------------------- sintetizador (ShipLogic.craft / activateBlock)

	/** zona de sintetizador que contiene esa posicion del planeta, con la posicion relativa a la zona */
	function areaAt( wx : Int, wy : Int, wz : Int ) : { c : ShipData.CraftArea, x : Int, y : Int, z : Int } {
		if( wz < World.SHIP_Z ) return null;
		var s = planet.size;
		var lx = (wx - planet.shipDX) % s, ly = (wy - planet.shipDY) % s;
		if( lx < 0 ) lx += s;
		if( ly < 0 ) ly += s;
		var lz = wz - World.SHIP_Z;
		for( c in crafts )
			if( c.inside(lx, ly, lz) ) return { c : c, x : lx, y : ly, z : lz };
		return null;
	}

	/** al cargar una partida: los bloques que ya hay en las zonas vuelven a contar para el sintetizador */
	public function initCrafts( g : GameView ) {
		for( c in crafts ) {
			for( dx in 0...c.w )
				for( dy in 0...c.h )
					for( dz in 0...c.heights[dx][dy] ) {
						var b = world.block(c.x + dx, c.y + dy, c.z + dz);
						if( b != null ) c.engine.add(b, dx, dy, dz);
					}
			checkCraft(c, g);
		}
	}

	/** se ha puesto (b) o quitado (null) un bloque en el planeta: si cae en una zona, el sintetizador lo recuerda */
	public function craft( wx : Int, wy : Int, wz : Int, b : Block, g : GameView ) {
		var a = areaAt(wx, wy, wz);
		if( a == null ) return;
		if( b == null ) a.c.engine.remove(a.x - a.c.x, a.y - a.c.y, a.z - a.c.z)
		else a.c.engine.add(b, a.x - a.c.x, a.y - a.c.y, a.z - a.c.z);
		checkCraft(a.c, g);
	}

	function outPos( c : ShipData.CraftArea ) {
		return { x : c.out.x + planet.shipDX + 0.5, y : c.out.y + planet.shipDY + 0.5, z : c.out.z + World.SHIP_Z + 0.25 };
	}

	function checkCraft( c : ShipData.CraftArea, g : GameView ) {
		var r = c.engine.checkAll();
		c.curCraft = r;
		if( c.preview != null ) {
			g.drops.remove(c.preview);
			c.preview = null;
		}
		if( r != null && c.out != null ) {
			var p = outPos(c);
			var d = g.drops.add(p.x, p.y, p.z, Block.get(r.out));
			d.fixed = true;
			d.active = false;
			c.preview = d;
		}
		var text = [];
		var bl = c.engine.getBlocks(false);
		for( b in bl ) text.push(b.n + "x " + b.b.getName());
		if( bl.length > 0 )
			text.push(" = " + (r != null ? (r.count != null && r.count > 1 ? r.count + " x " : "") + Block.get(r.out).getName() : Lang.t("craft.norecipe")));
		c.curText = text.length == 0 ? null : text.join("
");
	}

	/** texto de las recetas cercanas (ShipLogic.checkHero); null si no hay ninguna cerca */
	public function message( g : GameView ) : String {
		if( g.pz < World.SHIP_Z ) return null;
		for( c in crafts ) {
			if( c.curText == null ) continue;
			var dx = g.wrapDist(c.x + planet.shipDX + c.w * 0.5 - g.px);
			var dy = g.wrapDist(c.y + planet.shipDY + c.h * 0.5 - g.py);
			var dz = c.z + World.SHIP_Z - g.pz;
			if( Math.sqrt(dx * dx + dy * dy + dz * dz) < Math.max(c.w, c.h) * 0.5 + 3 ) {
				g.messageRed = c.curCraft == null;
				return c.curText;
			}
		}
		return null;
	}

	/** ordenador del sintetizador: fabrica la receta con los bloques del inventario o, si faltan, con los puestos en la zona */
	public function activateCraft( wx : Int, wy : Int, wz : Int, g : GameView ) {
		var s = planet.size;
		var lx = (wx - planet.shipDX) % s, ly = (wy - planet.shipDY) % s;
		if( lx < 0 ) lx += s;
		if( ly < 0 ) ly += s;
		var lz = wz - World.SHIP_Z;
		var c : ShipData.CraftArea = null;
		for( cc in crafts )
			if( cc.out != null && cc.out.x == lx && cc.out.y == ly && cc.out.z == lz ) {
				c = cc;
				break;
			}
		if( c == null || c.curCraft == null ) return;
		var cur = c.curCraft;
		var blocks = c.engine.getBlocks(true);
		var hasInv = true;
		for( b in blocks )
			if( !g.inv.hasBlocks(b.b, b.n) ) {
				hasInv = false;
				break;
			}
		var out = Block.get(cur.out);
		var n = cur.count != null ? cur.count : 1;
		var p = outPos(c);
		for( i in 0...n ) {
			var d = g.drops.add(p.x, p.y, p.z, out);
			d.delay = 30;
		}
		if( hasInv ) {
			if( !g.creative )
				for( b in blocks ) g.inv.useBlocks(b.b, b.n);
		} else {
			c.engine.clear();
			g.drops.remove(c.preview);
			c.preview = null;
			c.curCraft = null;
			c.curText = null;
			for( b in blocks )
				for( q in b.pos ) {
					var x = c.x + q.x + planet.shipDX, y = c.y + q.y + planet.shipDY, z = c.z + q.z + World.SHIP_Z;
					g.removeShipBlock(x, y, z, b.b);
				}
		}
	}
}
