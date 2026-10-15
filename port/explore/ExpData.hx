/** Datos del explorador (ExploreProtocol.hx del original, sin Hash ni @:native) y el generador de datos sin servidor (Main.hx). */
typedef ExpSector = {
	var id : Int;
	var seed : Int;
	var width : Int;
	var height : Int;
	var name : String;
}

enum ExpSystemStatus {
	SLocked( cost : Int );
	SOpen;
}

enum ExpPlanetStatus {
	PUnexplored;
	PActive;
	PAbandonned;
	PInvited;
	PForbidden;
}

typedef ExpPlanet = {
	var id : Int;
	var seed : Int;
	var size : Int;
	var distance : Int;
	var name : String;
	var status : ExpPlanetStatus;
	var gas : Bool;
	var biome : String;
}

typedef ExpSystem = {
	var id : Int;
	var seed : Int;
	var name : String;
	var x : Int;
	var y : Int;
	var status : ExpSystemStatus;
	var planets : Array<ExpPlanet>;
}

enum ExpShipPos {
	PInSector( x : Int, y : Int );
	PInSystem( id : Int );
	PPlanet( id : Int );
}

typedef ExpInfos = {
	var sector : ExpSector;
	var systems : Array<ExpSystem>;
	var shipPos : ExpShipPos;
	var energy : Int;
	var freeLicense : Bool;
}

/** Datos de sector y sistemas generados en local (exp.OfflineData del original sin servidor): todos los sistemas abiertos y planetas sin explorar. */
class ExpOffline {
	static var SYS = "Sistema";
	static var SEC = "Sector";
	static var NAMES = ["Aldebar", "Brume", "Cyrene", "Dorian", "Eskel", "Fenris", "Galata", "Hespera", "Ikaros", "Jovan", "Kestrel", "Lumen"];
	static var BIOMES = ["BIAutumn", "BIWinterPeaks", "BIMars", "BIMoon", "BIAcidForest"];
	static var BWEIGHTS = [100, 100, 80, 80, 50];
	public static var BNAMES = ["Otono", "Picos nevados", "Marte", "Luna", "Bosque acido"];

	public static function biomeIndex( biome : String ) : Int {
		var i = BIOMES.indexOf(biome);
		return i < 0 ? 0 : i;
	}

	static function generateSystem( id : Int, seed : Int ) : ExpSystem {
		var rseed = new mt.Rand(seed);
		var s : ExpSystem = {
			id : id,
			seed : seed,
			name : SYS + " " + NAMES[id % NAMES.length],
			planets : [],
			x : 20 + id * 3,
			y : 25,
			status : SOpen,
		};
		var total = 0;
		for( w in BWEIGHTS ) total += w;
		for( i in 0...rseed.random(3) + 2 ) {
			var roll = rseed.random(total);
			var bi = 0;
			while( roll >= BWEIGHTS[bi] ) {
				roll -= BWEIGHTS[bi];
				bi++;
			}
			s.planets.push({
				id : id * 10 + i,
				seed : seed + i,
				size : [1, 2, 2, 3][rseed.random(4)], // pequena 128, normal 256, grande 384
				distance : i,
				name : s.name + " " + (i + 1),
				status : PUnexplored,
				gas : false,
				biome : BIOMES[bi],
			});
		}
		return s;
	}

	/**
	 * `start` sustituye al planeta 0 del sistema 0 (con el que empieza la partida), `visited` son los planetas ya pisados (activos)
	 * y `pos` donde esta la nave en el mapa.
	 */
	public static function make( seed : Int, ?start : { seed : Int, biome : String, size : Int }, ?visited : Array<Int>, ?pos : Array<Int> ) : ExpInfos {
		seed = 1 + Std.int(Math.abs(seed)) % 999998;
		var d : ExpInfos = {
			sector : { id : 0, seed : seed, width : 50, height : 50, name : SEC + " " + seed },
			systems : [],
			shipPos : PInSector(30, 30),
			energy : 100,
			freeLicense : true,
		};
		for( i in 0...10 ) d.systems.push(generateSystem(i, seed + i));
		var rseed = new mt.Rand(seed);
		rseed.initSeed(seed);
		for( s in d.systems ) {
			s.x += rseed.random(2);
			s.y += rseed.random(20);
		}
		if( start != null ) {
			var p = d.systems[0].planets[0];
			p.seed = start.seed;
			p.biome = start.biome;
			p.size = start.size;
		}
		if( visited != null )
			for( s in d.systems )
				for( p in s.planets )
					if( visited.indexOf(p.id) >= 0 ) p.status = PActive;
		if( pos != null && pos.length > 0 )
			d.shipPos = switch( pos[0] ) {
				case 1: PInSystem(pos[1]);
				case 2: PPlanet(pos[1]);
				default: PInSector(pos[1], pos[2]);
			};
		return d;
	}
}
