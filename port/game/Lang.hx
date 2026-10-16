/** Textos del juego en español, inglés y francés (los tres idiomas del original). */
class Lang {

	public static var CODES = ["es", "en", "fr"];
	public static var LABELS = ["Español", "English", "Français"];
	public static var cur = 0;

	// clave => [es, en, fr]
	static var T : Map<String, Array<String>> = [
		"subtitle" => ["VERSIÓN OFFLINE", "OFFLINE VERSION", "VERSION HORS LIGNE"],
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
		"shop.title" => ["Robot comerciante", "Merchant robot", "Robot marchand"],
		"shop.yours" => ["Lo que llevas (clic: vender)", "Your items (click: sell)", "Ton inventaire (clic : vendre)"],
		"shop.robot" => ["Lo que vende el robot (clic: comprar)", "Robot's stock (click: buy)", "Stock du robot (clic : acheter)"],
		"shop.hint" => ["Mayús + clic: 10 unidades. Rueda: página. Los precios cambian según lo que se compra y se vende.", "Shift + click: 10 units. Wheel: page. Prices change with what is bought and sold.", "Maj + clic : 10 unités. Molette : page. Les prix changent selon ce qui est acheté et vendu."],
		"shop.close" => ["Cerrar", "Close", "Fermer"],
		"shop.credits" => ["Créditos:", "Credits:", "Crédits :"],
		"shop.buy" => ["comprar", "buy", "acheter"],
		"shop.sell" => ["vender", "sell", "vendre"],
		"chest.yours" => ["Tu inventario", "Your inventory", "Ton inventaire"],
		"chest.hint" => ["Clic: coger y dejar. Mayús: la mitad. Ctrl: una.", "Click: pick up and drop. Shift: half. Ctrl: one.", "Clic : prendre et poser. Maj : la moitié. Ctrl : un."],
		"hangar.ship_valid" => ["Nave válida - velocidad: %speed% PC/s", "Valid ship - speed: %speed% PC/s", "Vaisseau valide - vitesse : %speed% PC/s"],
		"hangar.hull_hole" => ["La nave no es estanca: hay un agujero en el casco.", "The ship is not airtight: there is a hole in the hull.", "Le vaisseau n'est pas étanche : il y a un trou dans la coque."],
		"hangar.access_computer" => ["No se puede usar el ordenador de a bordo: una cara debe dar al interior.", "The board computer cannot be used: one face must open to the inside.", "L'ordinateur de bord est inutilisable : une face doit donner sur l'intérieur."],
		"hangar.access_craft" => ["No se puede acceder a la losa de ensamblaje.", "The assembly slab is not accessible.", "La dalle d'assemblage n'est pas accessible."],
		"hangar.access_craft_computer" => ["No se puede acceder al sintetizador.", "The synthesizer is not accessible.", "Le synthétiseur n'est pas accessible."],
		"hangar.multiple_spawn" => ["Solo puede haber un teletransportador.", "There can be only one teleporter.", "Il ne peut y avoir qu'un seul téléporteur."],
		"hangar.no_spawn" => ["Falta el teletransportador.", "The teleporter is missing.", "Il manque le téléporteur."],
		"hangar.no_spawn_air" => ["Deja 2 bloques completamente vacíos sobre el teletransportador.", "Leave 2 completely empty blocks above the teleporter.", "Laisse 2 kubes complètement vides au-dessus du téléporteur."],
		"hangar.no_spawn_light" => ["No hay luz sobre el teletransportador.", "There is no light above the teleporter.", "Il n'y a pas de lumière au-dessus du téléporteur."],
		"hangar.need_computer" => ["Falta el ordenador de a bordo.", "The board computer is missing.", "Il manque l'ordinateur de bord."],
		"hangar.need_craft" => ["Falta una losa de ensamblaje.", "An assembly slab is missing.", "Il manque une dalle d'assemblage."],
		"hangar.need_craft_computer" => ["Falta el sintetizador.", "The synthesizer is missing.", "Il manque le synthétiseur."],
		"hangar.need_engine" => ["Falta un motor.", "An engine is missing.", "Il manque un moteur."],
		"hangar.need_engine_out" => ["Ningún motor da al exterior: su cara trasera debe quedar libre.", "No engine faces the outside: its rear face must be free.", "Aucun moteur ne donne sur l'extérieur : sa face arrière doit être libre."],
		"hangar.need_engines_min2" => ["Se necesitan al menos 2 motores bien colocados.", "At least 2 well-placed engines are needed.", "Il faut au moins 2 moteurs bien placés."],
		"hangar.need_engines" => ["Demasiados bloques para tus motores: añade motores o quita bloques.", "Too many blocks for your engines: add engines or remove blocks.", "Trop de kubes pour tes moteurs : ajoute des moteurs ou retire des kubes."],
		"hangar.separate_part" => ["Hay partes separadas: todos los bloques deben estar unidos.", "There are separate parts: all blocks must be connected.", "Il y a des parties séparées : tous les kubes doivent être reliés."],
		"hangar.exit_ship_no_save" => ["La nave no es válida: los cambios no se guardarán. ¿Salir?", "The ship is not valid: changes will not be saved. Leave?", "Le vaisseau n'est pas valide : les modifications ne seront pas sauvegardées. Quitter ?"],
		"hangar.help" => ["HANGAR - rompe y coloca bloques para rehacer tu nave. Sal por las casillas de teletransporte para guardar.", "HANGAR - break/place blocks to rebuild your ship. Leave through the teleporter tiles to save.", "HANGAR - retire et pose des kubes pour refaire ton vaisseau. Sors par les téléporteurs pour sauvegarder."],
		"shop.nosale" => ["el robot no compra esto", "the robot does not buy this", "le robot n'achete pas ca"],
		"shop.full" => ["el robot ya tiene demasiado de esto, vuelve mas tarde", "the robot has too much of this, come back later", "le robot en a trop, reviens plus tard"],
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
		"delete.pick" => ["Elige la partida que quieres borrar", "Choose the save to delete", "Choisis la partie à supprimer"],
		"delete.cancel" => ["Cancelar", "Cancel", "Annuler"],
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
		"biome.BIDeadCity" => ["Ciudad muerta", "Dead city", "Cité morte"],
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
