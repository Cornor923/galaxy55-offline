import Common;
import Protocol;
import ExploreProtocol;
import Mode;

@:bitmap("gfx/texture.png") class TilesBmp extends flash.display.BitmapData {}

class Main {
	
	static var SOFTWARE = false;
	static var START = Debug.getStartInfos();
	static var PLANET : PlanetInfos = {
		id : null,
		biome : START.biome,
		size : START.size,
		seed : START.seed,
		waterLevel : 0,
		waterFlood : 0,
		waterTotal : 0,
	};
	
	static var mode : Mode;
	static var engine : h3d.Engine;

	static function gameInfos() : GameInfos {
		var maxSlots = 10;
		var inv : InventoryInfos = {
			maxWeight : 64,
			t : [],
			charges : [],
		};
		//for( b in [BShipDoor, BShipHull, BShipGlass, BShipWire, BShipComputer, BShipEntry, BShipGlass2, BShipEngine, BShipPlate, BCrafter, BCrafterComputer] )
		//for( b in [BWood, BLamp, BBlueCrystalLight, BMoonLight] )
		//0xD2C8E6,0x877da2,0x4D4561
		for( b in [BLamp, BFreezer, BMinIron, BMinAluminium, BIron, BHealPlant, BCascadeSource, BBonusMedium, BChest] )
			inv.t.push( { k : Type.enumIndex(b), n : 50 } );
		for( c in [CYellow,CBlue,CPink,CBonus] )
			inv.charges.push( { c : Type.enumIndex(c), n : 30 } );
		while( inv.t.length < maxSlots )
			inv.t.push(null);
		if( savedInv != null ) inv = savedInv;
		return {
			planet : PLANET,
			inventory : inv,
			lastPos : null,
			debug : true,
			userId : null,
			userName : "Anonymous",
			offline : false,
			ship : { x : 14, y : 12, z : 34, data : shipData != null ? shipData : Const.DEFAULT_SHIP },
			crafts : null,
		};
	}
	
	static function randPlanet() : PlanetInfos {
		return {
			id : null,
			biome : START.biome,
			size : 2,//1 + Std.random(4),
			seed : Std.random(0x1000000) ^ Std.random(0x1000000) ^ Std.random(0x1000000),
			waterLevel : 0,
			waterFlood : 0,
			waterTotal : 0,
		};
	}
	
	static function getParam( v : String ) : String {
		return Reflect.field(flash.Lib.current.stage.loaderInfo.parameters, v);
	}
	
	// ---- estado de la sesion local (se conserva al cambiar de pantalla) ----
	public static var savedInv : InventoryInfos;
	/** créditos de la tienda ESCorp (añadido nuestro; solo duran mientras el juego esté abierto) */
	public static var credits : Int = 500;
	public static var shipData : haxe.io.Bytes;      // nave editada (comprimida), null = nave por defecto
	public static var curPlanet : PlanetInfos;
	/** punto de aterrizaje de la nave por planeta (semilla:bioma:tamaño), fijo mientras el juego esté abierto aunque el terreno cambie */
	public static var shipSpots = new Hash<{ x : Int, y : Int }>();       // planeta actual (para volver del hangar)
	static var disposeCur : Void -> Void;
	static var exploreInfos : ExploreProtocol.ExploreInfos;
	
	// seguimiento de fugas (depuración): referencias débiles, no impiden que el recolector libere el objeto
	static var tracked = new flash.utils.TypedDictionary<Dynamic, String>(true);
	public static function track( o : Dynamic, name : String ) {
		tracked.set(o, name);
	}
	public static function aliveReport() {
		try flash.system.System.gc() catch( e : Dynamic ) {}
		try flash.system.System.gc() catch( e : Dynamic ) {}
		var counts = new Hash<Int>();
		for( k in tracked ) {
			var n = tracked.get(k);
			counts.set(n, (counts.exists(n) ? counts.get(n) : 0) + 1);
		}
		var out = [];
		for( n in counts.keys() )
			out.push(n + "=" + counts.get(n));
		log("objetos vivos: " + out.join(", "));
	}

	/** escribe en flashlog.txt (solo si existe mm.cfg con TraceOutputFileEnable=1; ver README) */
	public static function log( s : String ) {
		flash.Lib.trace("[G55 " + Std.int(haxe.Timer.stamp() * 1000) % 1000000 + " | " + Std.int(flash.system.System.totalMemory / 1048576) + " MB] " + s);
	}

	/** cambia de pantalla (mapa / planeta / hangar) sin cerrar el juego */
	public static function switchTo( m : ClientMode ) {
		log("cambio de pantalla: " + Type.enumConstructor(m));
		haxe.Timer.delay(function() startMode(m), 30);
	}
	public static function goExplore() { switchTo(MExplore(null)); }
	public static function goEdit() { switchTo(MEditShip(null)); }
	public static function goGame() { switchTo(MGame(null)); }
	
	public static function onShipSaved( data : haxe.io.Bytes, inv : InventoryInfos ) {
		if( data != null ) shipData = data;
		if( inv != null ) savedInv = inv;
	}
	
	/** bloques de nave para el hangar (anadido nuestro: el original usaba lo que tuvieras en el inventario) */
	static function hangarInventory() : InventoryInfos {
		var inv : InventoryInfos = { maxWeight : 64, t : [], charges : [] };
		for( b in [BShipHull, BShipGlass, BShipDoor, BShipPlate, BShipLight, BShipWire, BShipTubes, BShipGlass2, BShipEngine, BShipComputer, BShipEntry, BCrafter, BCrafterComputer] )
			inv.t.push( { k : Type.enumIndex(b), n : 64 } );
		return inv;
	}
	
	static function startMode( m : ClientMode ) {
		if( disposeCur != null ) {
			var d = disposeCur;
			disposeCur = null;
			try d() catch( e : Dynamic ) log("ERROR al cerrar la pantalla anterior: " + Std.string(e));
			try flash.system.System.gc() catch( e : Dynamic ) {}
			log("pantalla anterior cerrada");
			haxe.Timer.delay(aliveReport, 4000);
		}
		var root = new flash.display.MovieClip();
		flash.Lib.current.addChild(root);
		switch( m ) {
		case MGame(inf):
			if( inf == null ) {
				inf = gameInfos();
				if( curPlanet != null ) inf.planet = curPlanet;
			}
			curPlanet = inf.planet;
			var api = if( inf.offline )
				new net.Offline(inf.planet)
			else if( inf.planet.id == null )
				new net.Local(inf.planet)
			else {
				var url = getParam("url");
				var sid = getParam("sid");
				var sender : net.Sender;
				if( sid != null && sid != "" ) {
					var visible = !(inf.lastPos != null && inf.lastPos.flags.has(CameraMode));
					sender = new net.ToraSender(url, inf.planet.id, visible);
				} else
					sender = new net.HttpSender(url);
				new net.Server(sender,inf.planet);
			}
			var g = new Game(root, engine, api, inf);
			disposeCur = function() g.dispose();
		case MEditShip(inf):
			if( inf == null ) {
				var gi = gameInfos();
				inf = {
					inventory : hangarInventory(),
					debug : true,
					size : { x : 17, y : 17, z : 14 }, // zona construible 17x17x14 (Twinpedia, "Modifier le vaisseau" y "Données mathématiques")
					ship : gi.ship.data,
				};
			}
			var api = new net.EditShipLocal(inf);
			var e = new EditShip(root, engine, api, inf);
			disposeCur = function() e.dispose();
		case MExplore(inf):
			if( inf == null ) {
				if( exploreInfos == null ) exploreInfos = exp.OfflineData.getInfos();
				inf = exploreInfos;
			}
			exp.Manager.onLand = function(p) {
				// al despegar, el mapa empieza junto a este planeta (no en la posición inicial del sector)
				inf.ship.pos = ShipPosition.PPlanet(p.id);
				if( shipData != null ) inf.ship.data = shipData; // el mapa dibuja la nave editada
				log("aterrizar: planeta id=" + p.id + " semilla=" + p.seed + " tamaño=" + p.size + " bioma=" + Std.string(p.biome));
				var ginf = gameInfos();
				ginf.planet = {
					id : null, biome : p.biome, size : p.size < 1 ? 1 : (p.size > 3 ? 3 : p.size),
					seed : p.seed, waterLevel : 0, waterFlood : 0, waterTotal : 0,
				};
				curPlanet = ginf.planet;
				startMode(MGame(ginf));
			};
			var explore = new exp.Manager(root, inf, false);
			disposeCur = function() {
				explore.dispose();
				if( root.parent != null ) root.parent.removeChild(root);
			};
		}
	}
	
	static function main() {
		mt.Timer.maxDeltaTime = 10;
		mt.Timer.tmod_factor = 0.98;
		haxe.Log.setColor(0xFF0000);
		
		if( !flash.system.Capabilities.isDebugger )
			flash.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(flash.events.UncaughtErrorEvent.UNCAUGHT_ERROR, function(e:flash.events.UncaughtErrorEvent) {
				tools.Codec.displayError(e.error);
				e.preventDefault();
			});
		
		var data = new flash.utils.ByteArray();
		data.length = 1024;
		try flash.Memory.select(data) catch( e : Dynamic ) {
			haxe.Log.trace("Flash Player 11.2 Beta can't run this game : please use 11.1");
			return;
		}
		
		var k : Dynamic = try tools.Codec.getData("data") catch( e : Dynamic ) { tools.Codec.displayError(e); return; };
		if( k != 654 ) {
			START.mode = k;
			Data.TEXTURE = new TilesBmp(0, 0);
		} else {
			Data.TEXTURE = new TilesBmp(0, 0);
			Mode.LOCAL = true;
		}

		var domain = flash.Lib.current.loaderInfo.url.split("/")[2];
		if( domain.substr(0,5) == "data." )
			flash.system.Security.allowDomain(domain.substr(5));
		
		if( Data.TEXTURE == null ) {
			var l = new flash.display.Loader();
			l.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_) init(l.content));
			l.load(new flash.net.URLRequest("gfx/texture.png"),new flash.system.LoaderContext(true,new flash.system.ApplicationDomain()));
		}
		
		engine = new h3d.Engine(0, 0, !SOFTWARE);
		engine.backgroundColor = 0x130200;
		engine.onReady = init.bind(null);
		engine.init();
	}
	
	static function init(content:Dynamic) {

		if( content != null ) {
			var bmp = flash.Lib.as(content, flash.display.Bitmap);
			Data.TEXTURE = bmp.bitmapData;
		}
		
		if( Data.TEXTURE == null || !engine.isReady() )
			return;
			
		startMode(START.mode);
		mt.flash.Key.init();
		mt.flash.Key.enableJSKeys("client");
		tools.Codec.addObfuFields(ClientAction);
		tools.Codec.addObfuFields(ExploreAction);
	}
	
}