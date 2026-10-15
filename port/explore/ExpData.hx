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

class ExpOffline {
	static var BIOMES = ["BIAutumn", "BIMars", "BIMoon", "BIWinterPeaks"];

	static function generateSystem( id : Int, seed : Int, status : ExpSystemStatus ) : ExpSystem {
		var rseed = new mt.Rand(seed);
		var s : ExpSystem = {
			id : id,
			seed : seed,
			name : "System " + id,
			planets : [],
			x : 20 + id * 3,
			y : 25,
			status : status,
		};
		switch( status ) {
		case SOpen:
			for( i in 0...rseed.random(3) + 2 ) {
				var biome = BIOMES[rseed.random(BIOMES.length)];
				s.planets.push({
					id : i,
					seed : seed + i,
					size : rseed.random(4) + 1,
					distance : i,
					name : "Planet " + i,
					status : PUnexplored,
					gas : false,
					biome : biome,
				});
			}
		case SLocked(_):
		}
		return s;
	}

	/** Main.getInfos del original: un sector de 50x50 con 10 sistemas, un tercio bloqueados (1500) */
	public static function make( seed : Int ) : ExpInfos {
		var d : ExpInfos = {
			sector : { id : 0, seed : seed, width : 50, height : 50, name : "Sector 0" },
			systems : [],
			shipPos : PInSector(30, 30),
			energy : 100,
			freeLicense : true,
		};
		var rseed = new mt.Rand(seed);
		for( i in 0...10 ) {
			var status = rseed.random(100) < 33 ? SLocked(1500) : SOpen;
			d.systems.push(generateSystem(i, seed + i, status));
		}
		rseed.initSeed(seed);
		for( s in d.systems ) {
			s.x += rseed.random(2);
			s.y += rseed.random(20);
		}
		return d;
	}
}
