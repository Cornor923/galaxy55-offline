/** Textos del juego en español, inglés y francés (los tres idiomas del original). */
class Lang {

	public static var CODES = ["es", "en", "fr"];
	public static var LABELS = ["Español", "English", "Français"];
	public static var cur = 0;

	// clave => [es, en, fr]
	static var T : Map<String, Array<String>> = [
		"subtitle" => ["VERSIÓN OFFLINE · ALFA", "OFFLINE VERSION · ALPHA", "VERSION HORS LIGNE · ALPHA"],
		"continue" => ["Continuar", "Continue", "Continuer"],
		"new" => ["Nueva partida", "New game", "Nouvelle partie"],
		"load" => ["Cargar partida", "Load game", "Charger une partie"],
		"options" => ["Opciones", "Options", "Options"],
		"quit" => ["Salir", "Quit", "Quitter"],
		"back" => ["Volver", "Back", "Retour"],
		"create" => ["Crear planeta", "Create planet", "Créer la planète"],
		"name" => ["Nombre", "Name", "Nom"],
		"seed" => ["Semilla", "Seed", "Graine"],
		"seed.random" => ["Aleatoria", "Random", "Aléatoire"],
		"biome" => ["Bioma", "Biome", "Biome"],
		"size" => ["Tamaño", "Size", "Taille"],
		"size.small" => ["Pequeño (128)", "Small (128)", "Petit (128)"],
		"size.normal" => ["Normal (256)", "Normal (256)", "Normal (256)"],
		"computer.title" => ["ORDENADOR DE A BORDO", "BOARD COMPUTER", "ORDINATEUR DE BORD"],
		"computer.takeoff" => ["Despegar (mapa de estrellas)", "Take off (star map)", "Décoller (carte stellaire)"],
		"computer.edit" => ["Modificar la nave (hangar)", "Modify the ship (hangar)", "Modifier le vaisseau (hangar)"],
		"computer.trade" => ["Comerciar (ESCorp)", "Trade (ESCorp)", "Commercer (ESCorp)"],
		"computer.close" => ["Cerrar", "Close", "Fermer"],
		"explore.loading" => ["Generando el mapa de estrellas...", "Generating the star map...", "Génération de la carte stellaire..."],
		"computer.soon" => ["Todavia no esta disponible en esta version", "Not available in this version yet", "Pas encore disponible dans cette version"],
		"mode" => ["Modo", "Mode", "Mode"],
		"mode.adventure" => ["Aventura (original)", "Adventure (original)", "Aventure (original)"],
		"mode.creative" => ["Creativo", "Creative", "Créatif"],
		"palette.title" => ["Bloques (modo creativo)", "Blocks (creative mode)", "Blocs (mode créatif)"],
		"palette.hint" => ["Clic: poner en la casilla elegida   Rueda: cambiar de pagina   I / Esc: cerrar", "Click: put in the selected slot   Wheel: change page   I / Esc: close", "Clic : mettre dans la case choisie   Molette : changer de page   I / Échap : fermer"],
		"hud.creative" => ["Creativo: I abre la paleta de bloques", "Creative: I opens the block palette", "Créatif : I ouvre la palette de blocs"],
		"size.large" => ["Grande (384)", "Large (384)", "Grand (384)"],
		"newgame.title" => ["NUEVA PARTIDA", "NEW GAME", "NOUVELLE PARTIE"],
		"load.title" => ["CARGAR PARTIDA", "LOAD GAME", "CHARGER UNE PARTIE"],
		"options.title" => ["OPCIONES", "OPTIONS", "OPTIONS"],
		"pause.title" => ["PAUSA", "PAUSED", "PAUSE"],
		"nosaves" => ["No hay partidas guardadas", "No saved games", "Aucune partie sauvegardée"],
		"delete" => ["Borrar", "Delete", "Supprimer"],
		"delete.ask" => ["¿Borrar esta partida?", "Delete this save?", "Supprimer cette partie ?"],
		"yes" => ["Sí", "Yes", "Oui"],
		"no" => ["No", "No", "Non"],
		"played" => ["Jugado", "Played", "Temps de jeu"],
		"saved" => ["Guardado", "Saved", "Sauvegardé"],
		"language" => ["Idioma", "Language", "Langue"],
		"sens" => ["Sensibilidad del ratón", "Mouse sensitivity", "Sensibilité de la souris"],
		"fov" => ["Campo de visión", "Field of view", "Champ de vision"],
		"volume" => ["Volumen", "Volume", "Volume"],
		"fullscreen" => ["Pantalla completa", "Fullscreen", "Plein écran"],
		"invert" => ["Invertir eje vertical", "Invert vertical axis", "Inverser l'axe vertical"],
		"turnkeys" => ["Teclas A/D y flechas", "A/D and arrow keys", "Touches A/D et flèches"],
		"turnkeys.strafe" => ["Desplazarse de lado", "Strafe", "Se déplacer de côté"],
		"turnkeys.turn" => ["Girar (como el original)", "Turn (like the original)", "Tourner (comme l'original)"],
		"on" => ["Sí", "On", "Oui"],
		"off" => ["No", "Off", "Non"],
		"resume" => ["Reanudar", "Resume", "Reprendre"],
		"save" => ["Guardar partida", "Save game", "Sauvegarder"],
		"saved.ok" => ["Partida guardada", "Game saved", "Partie sauvegardée"],
		"mainmenu" => ["Menú principal", "Main menu", "Menu principal"],
		"loading" => ["Generando el planeta...", "Generating the planet...", "Génération de la planète..."],
		"loading.mesh" => ["Construyendo el terreno...", "Building the terrain...", "Construction du terrain..."],
		"hint.menu" => ["Flechas: elegir     Intro: aceptar     Esc: volver", "Arrows: select     Enter: accept     Esc: back", "Fleches : choisir     Entree : valider     Echap : retour"],
		"hud.help" => ["WASD mover   Espacio saltar y jetpack   X caminar despacio   H casco   Esc pausa\nClic / E / Mayus excavar o colocar   1-0 / rueda elegir casilla   Tab excavador   R tirar   Mayus+K volver a la nave", "WASD move   Space jump and jetpack   X walk slowly   H helmet   Esc pause\nClick / E / Shift dig or place   1-0 / wheel pick slot   Tab digger   R drop   Shift+K back to ship", "WASD bouger   Espace sauter et jetpack   X marcher lentement   H casque   Échap pause\nClic / E / Maj creuser ou poser   1-0 / molette choisir   Tab pelle   R jeter   Maj+K retour au vaisseau"],
		"craft.norecipe" => ["Sin resultado :-(", "No result :-(", "Aucun résultat :-("],
		"mode.walk" => ["CAMINAR", "WALK", "MARCHE"],
		"mode.fly" => ["VUELO", "FLY", "VOL"],
		"gen.error" => ["No se pudo generar este planeta", "This planet could not be generated", "Impossible de générer cette planète"],
		"biome.BIAutumn" => ["Otoño", "Autumn", "Automne"],
		"biome.BIMoon" => ["Luna", "Moon", "Lune"],
		"biome.BIMars" => ["Marte", "Mars", "Mars"],
		"biome.BIWinterPeaks" => ["Cumbres nevadas", "Winter peaks", "Sommets enneigés"],
		"biome.BIAcidForest" => ["Bosque ácido", "Acid forest", "Forêt acide"],
		"biome.random" => ["Aleatorio", "Random", "Aléatoire"],
	];

	public static function t( key : String ) : String {
		var a = T.get(key);
		if( a == null ) return key;
		return a[cur];
	}

	public static function setCode( code : String ) {
		var i = CODES.indexOf(code);
		cur = i < 0 ? 0 : i;
	}

	public static function code() : String return CODES[cur];

	/** 1h 05m / 12m 30s */
	public static function duration( secs : Float ) : String {
		var s = Std.int(secs);
		var h = Std.int(s / 3600), m = Std.int((s % 3600) / 60);
		if( h > 0 ) return h + "h " + StringTools.lpad("" + m, "0", 2) + "m";
		return m + "m " + StringTools.lpad("" + (s % 60), "0", 2) + "s";
	}

	public static function date( ms : Float ) : String {
		var d = Date.fromTime(ms);
		var p = function(n : Int) return StringTools.lpad("" + n, "0", 2);
		return p(d.getDate()) + "/" + p(d.getMonth() + 1) + "/" + d.getFullYear() + " " + p(d.getHours()) + ":" + p(d.getMinutes());
	}
}
