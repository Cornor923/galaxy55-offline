package exp;
import ExploreProtocol;

// Datos de sector/sistemas generados localmente (sustituye al servidor de Motion Twin)
class OfflineData {

	#if lang_en
	static var SYS = "System"; static var SEC = "Sector";
	static var BNAMES = [ "Autumn", "Winter peaks", "Mars", "Moon", "Acid forest" ];
	static var TX = { loading : "Loading...", land : "Land", scan : "Scan", unlock : "Unlock", nolic : "No license", welcome : "Welcome" };
	#elseif lang_fr
	static var SYS = "Système"; static var SEC = "Secteur";
	static var BNAMES = [ "Automne", "Pics enneigés", "Mars", "Lune", "Forêt acide" ];
	static var TX = { loading : "Chargement...", land : "Atterrir", scan : "Scanner cette planète", unlock : "Débloquer", nolic : "Pas de licence", welcome : "Bienvenue" };
	#else
	static var SYS = "Sistema"; static var SEC = "Sector";
	static var BNAMES = [ "Otono", "Picos nevados", "Marte", "Luna", "Bosque acido" ];
	static var TX = { loading : "Cargando...", land : "Aterrizar", scan : "Escanear", unlock : "Desbloquear", nolic : "Sin licencia", welcome : "Bienvenido" };
	#end
	static var NAMES = ["Aldebar","Brume","Cyrene","Dorian","Eskel","Fenris","Galata","Hespera","Ikaros","Jovan","Kestrel","Lumen"];

	static inline var TEST_SIZE = 0; // para pruebas: forzar un tamaño (0 = aleatorio)

	static function generateSolarSystem( id : Int, seed : Int ) : SystemInfos {
		var rseed = new mt.Rand(seed);
		var infos : SystemInfos = {
			id : id,
			seed : seed,
			name : SYS + " " + NAMES[id % NAMES.length],
			planets : new Array(),
			x : 20 + id * 3,
			y : 25,
			status : SystemStatus.SOpen,
		}
		// mismos pesos (proba) que los biomas del juego; BIDeadCity tiene proba 0 (no sale al azar)
		var biomes = [ Common.BiomeKind.BIAutumn, Common.BiomeKind.BIWinterPeaks, Common.BiomeKind.BIMars, Common.BiomeKind.BIMoon, Common.BiomeKind.BIAcidForest ];
		var bweights = [ 100, 100, 80, 80, 50 ];
		var bnames = BNAMES;
		var btotal = 0;
		for( w in bweights ) btotal += w;
		for( i in 0...rseed.random(3) + 2 ) {
			var roll = rseed.random(btotal);
			var bi = 0;
			while( roll >= bweights[bi] ) { roll -= bweights[bi]; bi++; }
			var p : SystemPlanetInfos = {
				id : id * 10 + i, // único en todo el sector (el mapa busca el sistema de un planeta por este id)
				seed : seed + i,
				size : TEST_SIZE > 0 ? TEST_SIZE : [1, 2, 2, 3][rseed.random(4)], // pequeña 128, normal 256 (más habitual), grande 384
				distance : i,
				name : infos.name + " " + (i + 1),
				status : SystemPlanetStatus.PUnexplored, // como el original: hay que "escanear" el planeta antes de bajar
				kind : SystemPlanetKind.SPlanet,
				biome : biomes[bi],
				bname : bnames[bi],
			}
			infos.planets.push(p);
		}
		return infos;
	}

	public static function getInfos() : ExploreInfos {
		var seed = 1 + Std.random(999998);
		var h = new Hash<String>();
		h.set("loading", TX.loading);
		h.set("land", TX.land);
		h.set("scan", TX.scan);
		h.set("unlockSystem", TX.unlock);
		h.set("noLicense", TX.nolic);
		h.set("welcome", TX.welcome);
		var d : ExploreInfos = {
			url : null,
			ship : { data : null, pos : ShipPosition.PInSector(30, 30), energy : 100 },
			sector : { id : 0, seed : seed, width : 50, height : 50, name : SEC + " " + seed },
			systems : new Array(),
			holes : new Array(),
			freeLicense : true,
			texts : h,
		}
		var rseed = new mt.Rand(seed);
		for( i in 0...10 )
			d.systems.push(generateSolarSystem(i, seed + i));
		rseed.initSeed(seed);
		for( s in d.systems ) {
			s.x += rseed.random(2);
			s.y += rseed.random(20);
		}
		return d;
	}
}
