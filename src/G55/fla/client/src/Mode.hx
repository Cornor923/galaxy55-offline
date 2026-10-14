import Common;
import Protocol;

private class FakeConnection implements haxe.remoting.Connection {
	public function new() {
	}
	public function resolve( name : String ) : haxe.remoting.Connection {
		return this;
	}
	public function call(args:Array<Dynamic>) : Dynamic {
		return null;
	}
}

class Mode {
	
	public static var LOCAL = false;
	
	var cnx : haxe.remoting.Connection;
	var askCallback : Bool -> Void;
	var inventoryMode : Bool;
	public var lock : Bool;//locks update loop of client
	public var api : net.Api;
	public var root : flash.display.Sprite;
	public var engine : h3d.Engine;
	public var disposed : Bool;
	var listeners : Array<{ t : flash.events.IEventDispatcher, type : String, f : Dynamic }>;
	
	/** registra un listener para poder quitarlo al cambiar de modo */
	public function listen( t : flash.events.IEventDispatcher, type : String, f : Dynamic ) {
		if( listeners == null ) listeners = [];
		listeners.push({ t : t, type : type, f : f });
		t.addEventListener(type, f);
	}
	
	/** apaga el modo: quita listeners y la capa de dibujo (para pasar a otro modo sin cerrar el juego) */
	public function dispose() {
		if( disposed ) return;
		disposed = true;
		lock = true;
		if( listeners != null )
			for( l in listeners )
				try l.t.removeEventListener(l.type, l.f) catch( e : Dynamic ) {}
		listeners = null;
		try if( root.parent != null ) root.parent.removeChild(root) catch( e : Dynamic ) {}
	}
	
	public function new(root, engine, api) {
		this.root = root;
		this.engine = engine;
		this.api = api;
		api.onCommand = onCommand;
		var ctx = new haxe.remoting.Context();
		var api : Dynamic = getJsApi();
		api._cmd = function(data:String) {
			var t = new tools.Codec();
			onCommand(t.unserialize(StringTools.urlDecode(data)));
		};
		api._askAnswer = function(b) {
			var cb = askCallback;
			askCallback = null;
			cb(b);
		};
		ctx.addObject('api',api);
		if( LOCAL ) cnx = new FakeConnection();
		else cnx = haxe.remoting.ExternalConnection.jsConnect('cnx', ctx).api;
	}
	
	public function getJsApi() : Dynamic {
		return {};
	}
	
	public function onChunk( x : Int, y : Int, bytes : haxe.io.Bytes ) {
	}

	public function showHelpTip( ?tid : String, ?p : { } ) {
		if( tid == null ) cnx.showHelpTip.call([]) else cnx.showHelpTip.call([getText(tid, p)]);
	}
	
	function ask( txt : String, callb : Bool -> Void ) {
		if( LOCAL )
			haxe.Timer.delay(callb.bind(true), 1000);
		else {
			askCallback = callb;
			cnx.ask.call([txt]);
		}
	}
	
	static var TEXTS : Dynamic = #if lang_en {
		confirmKill : "Warning! You are returning to your ship without your equipment: you'll have to come back to your current location quickly if you wish to recover it!",
		no_recipe : "No result :-(",
		user_join : "%name% has joined the planet",
		user_leave : "%name% has left the planet",
		camera_link : "Camera view saved (%pos%)",
		camera_broken : "The camera is broken",
		ship_valid : "Valid ship - speed: %speed% PC/s",
		hull_hole : "The ship is not airtight: there is a hole in the hull.",
		access_computer : "The board computer cannot be used: one face must open to the inside.",
		access_craft : "The assembly slab is not accessible.",
		access_craft_computer : "The synthesizer is not accessible.",
		multiple_spawn : "There can be only one teleporter.",
		no_spawn : "The teleporter is missing.",
		no_spawn_air : "Leave 2 completely empty blocks above the teleporter.",
		no_spawn_light : "There is no light above the teleporter.",
		need_computer : "The board computer is missing.",
		need_craft : "An assembly slab is missing.",
		need_craft_computer : "The synthesizer is missing.",
		need_engine : "An engine is missing.",
		need_engine_out : "No engine faces the outside: its rear face must be free.",
		need_engines_min2 : "At least 2 well-placed engines are needed.",
		need_engines : "Too many blocks for your engines: add engines or remove blocks.",
		separate_part : "There are separate parts: all blocks must be connected.",
		exit_ship_no_save : "The ship is not valid: changes will not be saved. Leave?",
		menu_title : "BOARD COMPUTER",
		menu_takeoff : "[1]  Take off (star map)",
		menu_edit : "[2]  Modify the ship (hangar)",
		menu_close : "[3]  Stop",
		menu_trade : "[4]  Trade (ESCorp)",
		shop_title : "ESCorp Trade Center",
		shop_credits : "Credits",
		shop_sell : "SELL",
		shop_buy : "BUY",
		shop_none : "Nothing to sell.",
		shop_hint : "Up/Down: choose   Left/Right: switch   Enter: 1 unit   Shift+Enter: 10   Esc: leave",
		shop_hint_pad : "D-pad: choose   LB/RB: switch   A: 1 unit   X: 10   B: leave",
		shop_nocredits : "Not enough credits.",
		shop_full : "Inventory full.",
		hangar_help : "HANGAR - break/place blocks to rebuild your ship. Leave through the teleporter tiles to save.",
	} #elseif lang_fr {
		confirmKill : "Attention ! Tu retournes à ton vaisseau sans ton équipement : tu devras revenir vite à ta position actuelle si tu veux le récupérer.",
		no_recipe : "Aucun résultat :-(",
		user_join : "%name% a rejoint la planète",
		user_leave : "%name% a quitté la planète",
		camera_link : "Vue de caméra enregistrée (%pos%)",
		camera_broken : "La caméra est cassée",
		ship_valid : "Vaisseau valide - vitesse : %speed% PC/s",
		hull_hole : "Le vaisseau n'est pas étanche : il y a un trou dans la coque.",
		access_computer : "L'ordinateur de bord est inutilisable : une face doit donner sur l'intérieur.",
		access_craft : "La dalle d'assemblage n'est pas accessible.",
		access_craft_computer : "Le synthétiseur n'est pas accessible.",
		multiple_spawn : "Il ne peut y avoir qu'un seul téléporteur.",
		no_spawn : "Il manque le téléporteur.",
		no_spawn_air : "Laisse 2 kubes complètement vides au-dessus du téléporteur.",
		no_spawn_light : "Il n'y a pas de lumière au-dessus du téléporteur.",
		need_computer : "Il manque l'ordinateur de bord.",
		need_craft : "Il manque une dalle d'assemblage.",
		need_craft_computer : "Il manque le synthétiseur.",
		need_engine : "Il manque un moteur.",
		need_engine_out : "Aucun moteur ne donne sur l'extérieur : sa face arrière doit être libre.",
		need_engines_min2 : "Il faut au moins 2 moteurs bien placés.",
		need_engines : "Trop de kubes pour tes moteurs : ajoute des moteurs ou retire des kubes.",
		separate_part : "Il y a des parties séparées : tous les kubes doivent être reliés.",
		exit_ship_no_save : "Le vaisseau n'est pas valide : les modifications ne seront pas sauvegardées. Quitter ?",
		menu_title : "ORDINATEUR DE BORD",
		menu_takeoff : "[1]  Décoller (carte stellaire)",
		menu_edit : "[2]  Modifier le vaisseau (hangar)",
		menu_close : "[3]  Arrêter",
		menu_trade : "[4]  Commerce (ESCorp)",
		shop_title : "ESCorp Trade Center",
		shop_credits : "Crédits",
		shop_sell : "VENDRE",
		shop_buy : "ACHETER",
		shop_none : "Rien à vendre.",
		shop_hint : "Haut/Bas : choisir   Gauche/Droite : changer   Entrée : 1 unité   Maj+Entrée : 10   Échap : sortir",
		shop_hint_pad : "Croix : choisir   LB/RB : changer   A : 1 unité   X : 10   B : sortir",
		shop_nocredits : "Pas assez de crédits.",
		shop_full : "Inventaire plein.",
		hangar_help : "HANGAR - retire et pose des kubes pour refaire ton vaisseau. Sors par les téléporteurs pour sauvegarder.",
	} #else {
		confirmKill : "¡Atención! Vuelves a tu nave sin tu equipo: tendrás que regresar rápidamente a tu posición actual si quieres recuperarlo.",
		no_recipe : "Sin resultado :-(",
		user_join : "%name% se ha unido al planeta",
		user_leave : "%name% ha abandonado el planeta",
		camera_link : "Vista de cámara guardada (%pos%)",
		camera_broken : "La cámara está rota",
		ship_valid : "Nave válida - velocidad: %speed% PC/s",
		hull_hole : "La nave no es estanca: hay un agujero en el casco.",
		access_computer : "No se puede usar el ordenador de a bordo: una cara debe dar al interior.",
		access_craft : "No se puede acceder a la losa de ensamblaje.",
		access_craft_computer : "No se puede acceder al sintetizador.",
		multiple_spawn : "Solo puede haber un teletransportador.",
		no_spawn : "Falta el teletransportador.",
		no_spawn_air : "Deja 2 bloques completamente vacíos sobre el teletransportador.",
		no_spawn_light : "No hay luz sobre el teletransportador.",
		need_computer : "Falta el ordenador de a bordo.",
		need_craft : "Falta una losa de ensamblaje.",
		need_craft_computer : "Falta el sintetizador.",
		need_engine : "Falta un motor.",
		need_engine_out : "Ningún motor da al exterior: su cara trasera debe quedar libre.",
		need_engines_min2 : "Se necesitan al menos 2 motores bien colocados.",
		need_engines : "Demasiados bloques para tus motores: añade motores o quita bloques.",
		separate_part : "Hay partes separadas: todos los bloques deben estar unidos.",
		exit_ship_no_save : "La nave no es válida: los cambios no se guardarán. ¿Salir?",
		menu_title : "ORDENADOR DE A BORDO",
		menu_takeoff : "[1]  Despegar (mapa estelar)",
		menu_edit : "[2]  Modificar la nave (hangar)",
		menu_close : "[3]  Detener",
		menu_trade : "[4]  Comerciar (ESCorp)",
		shop_title : "ESCorp Trade Center",
		shop_credits : "Créditos",
		shop_sell : "VENDER",
		shop_buy : "COMPRAR",
		shop_none : "Nada que vender.",
		shop_hint : "Arriba/Abajo: elegir   Izq./Der.: cambiar   Intro: 1 unidad   Mayús+Intro: 10   Esc: salir",
		shop_hint_pad : "Cruceta: elegir   LB/RB: cambiar   A: 1 unidad   X: 10   B: salir",
		shop_nocredits : "No tienes créditos suficientes.",
		shop_full : "Inventario lleno.",
		hangar_help : "HANGAR - rompe y coloca bloques para rehacer tu nave. Sal por las casillas de teletransporte para guardar.",
	} #end;

	public function getText( tid : String, ?p : {} ) {
		var t = try cnx.getText.call([tid]) catch( e : Dynamic ) null;
		if( (t == null || t == "#"+tid) && Reflect.hasField(TEXTS, tid) )
			t = Reflect.field(TEXTS, tid);
		if( t == null || t == "#"+tid ) {
			t = "#" + tid;
			if( p != null ) t += Std.string(p);
		} else if( p != null ) {
			for( v in Reflect.fields(p) )
				t = t.split("%" + v.substr(1) + "%").join(Std.string(Reflect.field(p, v)));
		}
		return t;
	}
	
	public function onCommand(cmd:ServerAction) {
		switch( cmd ) {
		case SOk:
		case SRedir(url):
			api.disconnect();
			haxe.Timer.delay(function() flash.Lib.getURL(new flash.net.URLRequest(url), "_self"),500);
		case SChunk(x, y, bytes, cmp, diff):
			var b = bytes.getData();
			if( cmp ) b.uncompress();
			if( diff != null ) {
				var i = 0;
				var diff = diff.getData();
				var len : Int = diff.length;
				flash.Memory.select(b);
				while( i < len ) {
					var x = diff[i++];
					var y = diff[i++];
					var z = diff[i++];
					var block = diff[i++] | (diff[i++] << 8);
					flash.Memory.setI16( Const.addr(x,y,z) << 1, block );
				}
			}
			onChunk(x, y, haxe.io.Bytes.ofData(b));
		case SLoadModule(url,inv):
			lock = true;
			inventoryMode = inv;
			cnx.loadModule.call([url,inv]);
		case SExitModule:
			lock = false;
			inventoryMode = false;
			cnx.exitModule.call([]);
		case SMessage(msg, next):
			askCallback = function(_) onCommand(next);
			cnx.prompt.call([msg]);
		default:
			tools.Codec.displayError("UNHANDLED " + Std.string(cmd));
		}
	}
	
}