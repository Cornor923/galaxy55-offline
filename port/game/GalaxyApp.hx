import Ui;
import SaveData.SaveInfo;

enum State {
	Boot;
	Menu;
	Loading;
	Playing;
	Paused;
}

/** Fila de la lista de partidas guardadas: miniatura, nombre y datos. */
class SaveRow extends Widget {
	public var info(default, null) : SaveInfo;

	public function new( parent : h2d.Object, info : SaveInfo ) {
		super(parent, 960, 104);
		this.info = info;
		label.visible = false;
		var tb = SaveData.thumb(info.id);
		var thumb : h2d.Tile = null;
		if( tb != null ) {
			try thumb = hxd.res.Any.fromBytes("t.png", tb).toTile() catch( e : Dynamic ) {}
		}
		if( thumb != null ) {
			var bm = new h2d.Bitmap(thumb, this);
			bm.x = 8;
			bm.y = 7;
			bm.scaleX = 160 / thumb.width;
			bm.scaleY = 90 / thumb.height;
		} else {
			var ph = new h2d.Graphics(this);
			Theme.rect(ph, 8, 7, 160, 90, 0xFFFFFF, 0.07);
		}
		Theme.text(this, info.name, 2.4, Theme.TEXT, 190, 10);
		var biome = Lang.t("biome." + info.biome);
		var size = 128 * info.sizeChunks;
		Theme.text(this, biome + "  ·  " + size + "x" + size + "  ·  " + Lang.t("seed") + " " + info.seed + (info.creative == true ? "  ·  " + Lang.t("mode.creative") : ""), 1.7, Theme.CYAN, 190, 48);
		Theme.text(this, Lang.t("played") + " " + Lang.duration(info.playSeconds) + "   " + Lang.t("saved") + " " + Lang.date(info.saved), 1.5, Theme.DIM, 190, 74);
	}
}

/** Pantalla de partidas guardadas con desplazamiento. */
class LoadScreen extends Screen {
	public var rows = new Array<SaveRow>();
	public var top = 0;
	public static inline var VISIBLE = 4;
	var baseY = 150.;

	override function setFocus( i : Int ) {
		super.setFocus(i);
		if( i >= 0 && i < rows.length ) {
			if( i < top ) top = i;
			if( i >= top + VISIBLE ) top = i - VISIBLE + 1;
			layout();
		}
	}

	public function layout() {
		for( i in 0...rows.length ) {
			var r = rows[i];
			var vis = i >= top && i < top + VISIBLE;
			r.visible = vis;
			r.y = baseY + (i - top) * 112;
		}
	}
}

class GalaxyApp extends hxd.App {

	static inline var W = 1280;
	static inline var H = 720;
	static var BIOMES = ["BIAutumn", "BIMoon", "BIMars", "BIWinterPeaks", "BIAcidForest"];

	var state : State = Boot;
	var atlas : h3d.mat.Texture;
	var bgWorlds = new Array<World>();
	var bgQueue = new Array<String>();
	var bgBuilding : World;
	var bgIndex = 0;
	var bgTimer = 0.;
	var bgFade = 0;
	var bgFadeT = 0.;
	var bgCamZ = -1.;
	var bgPhase = 0.;
	var bgAlt = new Array<Float>();
	var bgCx = 64.;
	var bgCy = 64.;
	var bgR = 38.;
	var snow : Snow;
	var loadWorld : World;
	var loadInfo : SaveInfo;
	var game : GameView;
	var pad : hxd.Pad;

	var ui : h2d.Object;
	var dim : h2d.Bitmap;
	var screens = new Map<String, Screen>();
	var current : Screen;
	var currentName = "";
	var overlayDecor : h2d.Object;
	var bar : h2d.Graphics;
	var barText : h2d.Text;
	var hud : h2d.Text;
	var jetGlow : h2d.Bitmap;
	var jetBar : h2d.Graphics;
	var invBar : InvBar;
	var cross : h2d.Graphics;

	// casco (Game.hudOn, render.hud[H_HELMET]): posicion en pixeles de la imagen de 1024x1024
	var helmet : h2d.Bitmap;
	var helmetOn = true;
	var helmetX = -20.;
	var helmetY = -190.;
	var helmetSeq = new Array<{ wait : Bool, to : Float, dur : Float, easeIn : Bool }>();
	var helmetT = 0.;
	var helmetFrom = 0.;
	var helmetOnDone : Void -> Void;
	var toast : h2d.Text;
	var toastTime = 0.;
	var orbit = 0.;
	var autosaveTimer = 0.;
	var frames = 0;
	var captured = false;

	// pruebas automaticas (captura de pantalla)
	var shotPath : String = null;
	var shotScreen = "main";
	var shotFrames = 30;
	var demoSaves = false;
	var shotBiome : String = null;
	var shotCont = false;
	var shotN = 20;
	var shotSlot = 2;
	var shotAt : Array<Float> = null; // --at=x,y,yaw[,pitch,z]: coloca al jugador para la captura

	// formulario de nueva partida
	var nName : TextField;
	var nSeed : TextField;
	var nBiome : Selector;
	var nSize : Selector;
	var nMode : Selector;
	var palette : Palette;
	var paletteOpen = false;

	override function init() {
		for( a in Sys.args() ) {
			if( StringTools.startsWith(a, "--shot=") ) shotPath = a.substr(7);
			else if( StringTools.startsWith(a, "--screen=") ) shotScreen = a.substr(9);
			else if( StringTools.startsWith(a, "--frames=") ) shotFrames = Std.parseInt(a.substr(9));
			else if( a == "--demo-saves" ) demoSaves = true;
			else if( StringTools.startsWith(a, "--n=") ) shotN = Std.parseInt(a.substr(4));
			else if( StringTools.startsWith(a, "--slot=") ) shotSlot = Std.parseInt(a.substr(7));
			else if( StringTools.startsWith(a, "--at=") ) shotAt = a.substr(5).split(",").map(Std.parseFloat);
			else if( StringTools.startsWith(a, "--bgbiome=") ) shotBiome = a.substr(10);
			else if( StringTools.startsWith(a, "--lang=") ) Lang.setCode(a.substr(7));
		}
		Theme.init();
		Settings.load();
		if( shotPath != null ) {
			for( a in Sys.args() ) if( StringTools.startsWith(a, "--lang=") ) { Settings.lang = a.substr(7); Lang.setCode(Settings.lang); }
		}

		var win = hxd.Window.getInstance();
		win.title = "Galaxy 55 (offline)";
		win.onClose = function() {
			if( state == Playing || state == Paused ) saveGame(false);
			return true;
		};
		if( Settings.fullscreen && shotPath == null ) win.displayMode = Borderless;
		else win.resize(W, H);

		s2d.scaleMode = LetterBox(W, H);
		engine.backgroundColor = 0xFF05070D;

		var png = sys.io.File.getBytes("src/G55/fla/client/gfx/texture.png");
		// atlas con los parches del original (colores planos BFColor, opacidades BFAlpha)
		atlas = Atlas.build(png);

		dim = new h2d.Bitmap(h2d.Tile.fromColor(0x000000, W, H, 0.0), s2d);
		snow = new Snow(s2d);
		ui = new h2d.Object(s2d);
		// brillo del jetpack (hud_jetpack.png del original) y barra de combustible
		var ht = hxd.res.Any.fromBytes("hud.png", sys.io.File.getBytes("src/G55/fla/client/gfx/hud.png")).toTile();
		helmet = new h2d.Bitmap(ht, s2d);
		helmet.visible = false;
		var jt = hxd.res.Any.fromBytes("hud_jetpack.png", sys.io.File.getBytes("src/G55/fla/client/gfx/hud_jetpack.png")).toTile();
		jetGlow = new h2d.Bitmap(jt, s2d);
		jetGlow.visible = false;
		jetBar = new h2d.Graphics(s2d);
		jetBar.x = Std.int(W * 0.5 - 175);
		jetBar.y = H - 25;
		jetBar.alpha = 0.9;
		jetBar.visible = false;
		// mira cian que aparece al excavar (Interface.cross: lineas de 7 px, alfa 0.4)
		cross = new h2d.Graphics(s2d);
		cross.lineStyle(1, 0x00FFFF, 1);
		cross.moveTo(0, -7);
		cross.lineTo(0, 7);
		cross.moveTo(-7, 0);
		cross.lineTo(7, 0);
		cross.x = Std.int(W * 0.5);
		cross.y = Std.int(H * 0.5);
		cross.alpha = 0.4;
		cross.visible = false;
		hxd.Window.getInstance().addEventTarget(onWindowEvent);
		hud = Theme.text(s2d, "", 1.8, 0xFFFFFF, 14, 74);
		hud.dropShadow = { dx : 1, dy : 1, color : 0, alpha : 0.9 };
		hud.visible = false;
		toast = Theme.text(s2d, "", 2.4, Theme.ACCENT, 0, 640);
		toast.dropShadow = { dx : 2, dy : 2, color : 0, alpha : 0.9 };
		toast.visible = false;

		if( demoSaves ) makeDemoSaves();

		// el planeta que gira de fondo del menu
		bgStart();
		showLoading(Lang.t("loading"));

		hxd.Pad.wait(function(p) pad = p);
	}

	// ---------------------------------------------------------------- utilidades de pantalla

	function clearUi() {
		ui.removeChildren();
		screens = new Map();
		current = null;
		currentName = "";
	}

	function gradientPanel( parent : h2d.Object, w : Int ) {
		var g = new h2d.Graphics(parent);
		// franjas sin solapar (una por cada 4 px) para que el degradado no muestre rayas
		var n = Std.int(w / 4);
		for( i in 0...n ) {
			var f = i / n;
			var a = 0.9 * (1 - f * f);
			Theme.rect(g, i * 4, 0, 4, H, Theme.BG, a);
		}
		Theme.rect(g, 0, 0, 4, H, Theme.ACCENT, 0.9);
	}

	function titleBlock( parent : h2d.Object, x : Float, y : Float, scale : Float ) {
		var shadow = Theme.text(parent, "GALAXY", scale, 0x000000, x + 4, y + 4);
		shadow.alpha = 0.5;
		Theme.text(parent, "GALAXY", scale, 0xFFFFFF, x, y);
		var t55 = Theme.text(parent, "55", scale, Theme.ACCENT, x + 6 * 8 * scale * 1.04 + 8, y);
		Theme.text(parent, Lang.t("subtitle"), scale * 0.2, Theme.DIM, x + 6, y + 13 * scale + 8);
	}

	function hint( parent : h2d.Object, x : Float, y : Float ) {
		Theme.text(parent, Lang.t("hint.menu"), 1.5, Theme.DIM, x, y);
	}

	function panelFor( w : Int, h : Int, title : String ) : Screen {
		var s = new Screen(ui);
		var bg = new h2d.Graphics(s);
		var x = (W - w) * 0.5, y = (H - h) * 0.5;
		Theme.rect(bg, 0, 0, W, H, 0x000000, 0.35);
		Theme.rect(bg, x, y, w, h, Theme.PANEL, 0.94);
		Theme.rect(bg, x, y, w, 4, Theme.ACCENT);
		Theme.rect(bg, x, y + h - 1, w, 1, 0xFFFFFF, 0.1);
		var t = Theme.text(s, title, 3.2, Theme.TEXT, 0, y + 28);
		t.x = (W - t.textWidth * t.scaleX) * 0.5;
		return s;
	}

	function show( name : String ) {
		if( current != null ) current.visible = false;
		var s = screens.get(name);
		if( s == null ) {
			s = switch( name ) {
				case "main": buildMain();
				case "new": buildNew();
				case "load": buildLoad();
				case "options": buildOptions();
				case "pause": buildPause();
				default: null;
			}
			screens.set(name, s);
		}
		current = s;
		currentName = name;
		s.visible = true;
		s.active = true;
		s.firstEnabled();
	}

	/** Reconstruye todos los menus (al cambiar de idioma). */
	function rebuildScreens( stay : String ) {
		var again = state == Menu || state == Paused;
		clearUi();
		if( again ) show(stay);
	}

	// ---------------------------------------------------------------- pantallas

	function buildMain() : Screen {
		var s = new Screen(ui);
		gradientPanel(s, 900);
		titleBlock(s, 110, 80, 7.5);
		var saves = SaveData.list();
		var y = 300.;
		var cont = new Button(s, Lang.t("continue"));
		cont.enabled = saves.length > 0;
		cont.onActivate = function() if( saves.length > 0 ) startGame(saves[0]);
		s.add(cont, 110, y);
		var nw = new Button(s, Lang.t("new"));
		nw.onActivate = function() show("new");
		s.add(nw, 110, y + 64);
		var ld = new Button(s, Lang.t("load"));
		ld.enabled = saves.length > 0;
		ld.onActivate = function() { show("load"); }
		s.add(ld, 110, y + 128);
		var op = new Button(s, Lang.t("options"));
		op.onActivate = function() show("options");
		s.add(op, 110, y + 192);
		var q = new Button(s, Lang.t("quit"));
		q.onActivate = function() quit();
		s.add(q, 110, y + 256);
		if( saves.length > 0 ) {
			var l = saves[0];
			Theme.text(s, Lang.t("continue") + ": " + l.name + "  ·  " + Lang.duration(l.playSeconds), 1.5, Theme.DIM, 112, y + 330);
		}
		hint(s, 110, 676);
		Theme.text(s, "v0.3 · port nativo", 1.4, Theme.DISABLED, W - 190, 690);
		s.onBack = null;
		return s;
	}

	function randomSeed() : Int return 1 + Std.random(999999);

	function buildNew() : Screen {
		var s = panelFor(760, 640, Lang.t("newgame.title"));
		var x = (W - 560) * 0.5;
		nName = new TextField(s, Lang.t("name"), "Planeta " + (1 + SaveData.list().length));
		nSeed = new TextField(s, Lang.t("seed"), "" + randomSeed());
		nSeed.numeric = true;
		nSeed.maxLen = 9;
		var names = [Lang.t("biome.random")];
		for( b in BIOMES ) names.push(Lang.t("biome." + b));
		nBiome = new Selector(s, Lang.t("biome"), names);
		nSize = new Selector(s, Lang.t("size"), [Lang.t("size.small"), Lang.t("size.normal"), Lang.t("size.large")]);
		nSize.index = 0;
		nMode = new Selector(s, Lang.t("mode"), [Lang.t("mode.adventure"), Lang.t("mode.creative")]);
		var create = new Button(s, Lang.t("create"), 560);
		var back = new Button(s, Lang.t("back"), 560);
		var y = 190.;
		s.add(nName, x, y);
		s.add(nSeed, x, y + 66);
		s.add(nBiome, x, y + 132);
		s.add(nSize, x, y + 198);
		s.add(nMode, x, y + 264);
		s.add(create, x, y + 346);
		s.add(back, x, y + 412);
		create.onActivate = function() {
			var seed = Std.parseInt(nSeed.text);
			if( seed == null || seed <= 0 ) seed = randomSeed();
			var biome = nBiome.index == 0 ? BIOMES[seed % BIOMES.length] : BIOMES[nBiome.index - 1];
			var name = StringTools.trim(nName.text);
			if( name == "" ) name = "Planeta";
			var info = SaveData.create(name, seed, biome, nSize.index + 1);
			info.creative = nMode.index == 1;
			startGame(info);
		};
		back.onActivate = function() show("main");
		s.onBack = function() show("main");
		hint(s, (W - 600) * 0.5 + 50, 692);
		return s;
	}

	function buildLoad() : Screen {
		var s = new LoadScreen(ui);
		var bg = new h2d.Graphics(s);
		Theme.rect(bg, 0, 0, W, H, 0x000000, 0.4);
		Theme.rect(bg, 150, 60, 980, 600, Theme.PANEL, 0.94);
		Theme.rect(bg, 150, 60, 980, 4, Theme.ACCENT);
		var t = Theme.text(s, Lang.t("load.title"), 3.2, Theme.TEXT, 0, 82);
		t.x = (W - t.textWidth * t.scaleX) * 0.5;
		var saves = SaveData.list();
		var confirmBox : Screen = null;
		for( info in saves ) {
			var row = new SaveRow(s, info);
			s.rows.push(row);
			s.add(row, 160, 150);
			var inf = info;
			row.onActivate = function() startGame(inf);
		}
		s.layout();
		var del = new Button(s, Lang.t("delete"), 300, 48);
		var back = new Button(s, Lang.t("back"), 300, 48);
		s.add(del, 640 - 310, 598);
		s.add(back, 640 + 10, 598);
		var doDelete = function() {
			if( s.focus < s.rows.length ) askDelete(s, s.rows[s.focus].info);
		};
		del.onActivate = doDelete;
		back.onActivate = function() { show("main"); }
		s.onBack = function() show("main");
		if( saves.length == 0 ) {
			var n = Theme.text(s, Lang.t("nosaves"), 2.2, Theme.DIM, 0, 320);
			n.x = (W - n.textWidth * n.scaleX) * 0.5;
			del.enabled = false;
		}
		return s;
	}

	/** ventana de confirmacion para borrar una partida */
	function askDelete( parent : LoadScreen, info : SaveInfo ) {
		parent.active = false;
		var m = new Screen(ui);
		var bg = new h2d.Graphics(m);
		Theme.rect(bg, 0, 0, W, H, 0x000000, 0.55);
		Theme.rect(bg, 390, 250, 500, 220, Theme.PANEL, 1);
		Theme.rect(bg, 390, 250, 500, 4, Theme.DANGER);
		var t = Theme.text(m, Lang.t("delete.ask"), 2.4, Theme.TEXT, 0, 280);
		t.x = (W - t.textWidth * t.scaleX) * 0.5;
		var n = Theme.text(m, info.name, 2.0, Theme.CYAN, 0, 325);
		n.x = (W - n.textWidth * n.scaleX) * 0.5;
		var no = new Button(m, Lang.t("no"), 210, 52);
		var yes = new Button(m, Lang.t("yes"), 210, 52);
		m.add(no, 410, 390);
		m.add(yes, 640 + 10, 390);
		m.setFocus(0);
		var close = function() {
			m.remove();
			parent.active = true;
		};
		no.onActivate = close;
		m.onBack = close;
		yes.onActivate = function() {
			SaveData.delete(info.id);
			m.remove();
			screens.remove("load");
			screens.remove("main");
			parent.remove();
			if( SaveData.list().length == 0 ) show("main") else show("load");
		};
		// el modal se actualiza desde update()
		modal = m;
	}
	var modal : Screen;

	function buildOptions() : Screen {
		var s = panelFor(860, 620, Lang.t("options.title"));
		var x = (W - 660) * 0.5;
		var y = 140.;
		var lang = new Selector(s, Lang.t("language"), Lang.LABELS, 660);
		lang.index = Lang.cur;
		var sens = new Slider(s, Lang.t("sens"), 0.2, 3.0, 0.1, 660);sens.decimals = 1;
		sens.value = Settings.mouseSens;
		var fov = new Slider(s, Lang.t("fov"), 60, 110, 5, 660);
		fov.value = Settings.fov;
		var vol = new Slider(s, Lang.t("volume"), 0, 100, 5, 660);
		vol.value = Settings.volume;
		var full = new Selector(s, Lang.t("fullscreen"), [Lang.t("off"), Lang.t("on")], 660);
		full.index = Settings.fullscreen ? 1 : 0;
		var inv = new Selector(s, Lang.t("invert"), [Lang.t("off"), Lang.t("on")], 660);
		inv.index = Settings.invertY ? 1 : 0;
		var tk = new Selector(s, Lang.t("turnkeys"), [Lang.t("turnkeys.strafe"), Lang.t("turnkeys.turn")], 660);
		tk.index = Settings.turnKeys ? 1 : 0;
		var back = new Button(s, Lang.t("back"), 660);
		s.add(lang, x, y);
		s.add(sens, x, y + 60);
		s.add(fov, x, y + 120);
		s.add(vol, x, y + 180);
		s.add(full, x, y + 240);
		s.add(inv, x, y + 300);
		s.add(tk, x, y + 360);
		s.add(back, x, y + 440);
		var origin = state == Paused ? "pause" : "main";
		lang.onChange = function(i) {
			Settings.lang = Lang.CODES[i];
			Lang.setCode(Settings.lang);
			Settings.save();
			rebuildScreens("options");
		};
		sens.onChange = function(v) Settings.mouseSens = v;
		fov.onChange = function(v) Settings.fov = Std.int(v);
		vol.onChange = function(v) Settings.volume = Std.int(v);
		full.onChange = function(i) {
			Settings.fullscreen = i == 1;
			hxd.Window.getInstance().displayMode = Settings.fullscreen ? Borderless : Windowed;
		};
		inv.onChange = function(i) Settings.invertY = i == 1;
		tk.onChange = function(i) Settings.turnKeys = i == 1;
		var leave = function() {
			Settings.save();
			show(state == Paused ? "pause" : "main");
		};
		back.onActivate = leave;
		s.onBack = leave;
		return s;
	}

	function buildPause() : Screen {
		var s = panelFor(560, 520, Lang.t("pause.title"));
		var x = (W - 460) * 0.5;
		var y = 215.;
		var res = new Button(s, Lang.t("resume"));
		var sv = new Button(s, Lang.t("save"));
		var op = new Button(s, Lang.t("options"));
		var mm = new Button(s, Lang.t("mainmenu"));
		var q = new Button(s, Lang.t("quit"));
		s.add(res, x, y);
		s.add(sv, x, y + 62);
		s.add(op, x, y + 124);
		s.add(mm, x, y + 186);
		s.add(q, x, y + 248);
		res.onActivate = function() resume();
		sv.onActivate = function() saveGame(true);
		op.onActivate = function() show("options");
		mm.onActivate = function() toMainMenu();
		q.onActivate = function() {
			saveGame(false);
			quit();
		};
		s.onBack = function() resume();
		return s;
	}

	// ---------------------------------------------------------------- carga con progreso

	function showLoading( msg : String ) {
		ui.removeChildren();
		screens = new Map();
		current = null;
		var s = new Screen(ui);
		var bg = new h2d.Graphics(s);
		Theme.rect(bg, 0, 0, W, H, Theme.BG, 0.82);
		titleBlock(s, 110, 80, 7.5);
		barText = Theme.text(s, msg, 2.2, Theme.TEXT, 110, 520);
		bar = new h2d.Graphics(s);
		overlayDecor = s;
		setProgress(0);
	}

	function setProgress( p : Float ) {
		if( bar == null ) return;
		bar.clear();
		Theme.rect(bar, 110, 566, 700, 10, 0xFFFFFF, 0.12);
		Theme.rect(bar, 110, 566, 700 * p, 10, Theme.ACCENT);
	}

	// ---------------------------------------------------------------- flujo del juego

	function startGame( info : SaveInfo ) {
		state = Loading;
		clearUi();
		hud.visible = false;
		loadInfo = info;
		loadWorld = new World(info.seed, info.biome, info.sizeChunks, s3d, atlas, false, info.edits);
		loadWorld.root.visible = false;
		showLoading(Lang.t("loading"));
	}

	function finishLoading() {
		bgDisposeAll();
		loadWorld.root.visible = true;
		if( shotPath != null ) {
			Sys.println("mundo " + loadWorld.biomeName + ": " + loadWorld.faces + " caras, spawn z=" + loadWorld.spawnPoint().z);
			Sys.println(loadWorld.debugStats());
		}
		game = new GameView(s3d, loadWorld, loadInfo, atlas);
		invBar = new InvBar(s2d, game.inv, atlas, W);
		loadWorld = null;
		ui.removeChildren();
		bar = null;
		state = Playing;
		hud.visible = true;
		autosaveTimer = 0;
		captureMouse(true);
		if( loadInfo.px < 0 ) {
			// partida nueva: se crea el archivo enseguida para que aparezca en la lista
			saveGame(false);
		}
	}

	function resume() {
		current = null;
		ui.removeChildren();
		screens = new Map();
		dim.tile = h2d.Tile.fromColor(0x000000, W, H, 0.0);
		game.releaseAction();
		state = Playing;
		hud.visible = true;
		captureMouse(true);
	}

	var pausedThisFrame = false;

	function pause() {
		state = Paused;
		captureMouse(false);
		hud.visible = false;
		show("pause");
	}

	function toMainMenu() {
		saveGame(false);
		closePalette();
		game.dispose();
		if( invBar != null ) {
			invBar.remove();
			invBar = null;
		}
		game.world.dispose();
		game = null;
		ui.removeChildren();
		screens = new Map();
		bgStart();
		hud.visible = false;
		state = Menu;
		show("main");
	}

	function quit() {
		hxd.System.exit();
	}

	function captureMouse( on : Bool ) {
		captured = on;
		if( game != null ) game.mouseLook = on;
		hxd.Window.getInstance().mouseMode = on ? Relative(onMouse, true) : Absolute;
	}

	/** rueda del raton: cambia de casilla (en el original, bajar la rueda pasa a la siguiente); con la paleta abierta, de pagina */
	function onWindowEvent( e : hxd.Event ) {
		if( e.kind != EWheel || game == null || state != Playing ) return;
		if( paletteOpen && palette != null ) palette.scroll(e.wheelDelta);
		else game.scrollInventory(e.wheelDelta > 0 ? -1 : 1);
	}

	function openPalette() {
		if( paletteOpen || game == null || !game.creative ) return;
		palette = new Palette(s2d, atlas);
		palette.onPick = function(b) game.setSlot(b);
		paletteOpen = true;
		captureMouse(false);
	}

	function closePalette() {
		if( palette != null ) {
			palette.remove();
			palette = null;
		}
		paletteOpen = false;
		if( game != null && state == Playing ) {
			captureMouse(true);
			game.releaseAction();
		}
	}

	function onMouse( e : hxd.Event ) {
		if( game != null && state == Playing ) game.look(e.relX, e.relY);
	}

	// ---------------------------------------------------------------- guardado

	function captureThumb() : haxe.io.Bytes {
		try {
			game.updateCamera();
			var w = engine.width, h = engine.height;
			var tex = new h3d.mat.Texture(w, h, [Target]);
			tex.depthBuffer = new h3d.mat.Texture(w, h, [Target], Depth24Stencil8);
			engine.pushTarget(tex);
			engine.clear(0xFF6FA8DC, 1, 0);
			s3d.render(engine);
			engine.popTarget();
			var px = tex.capturePixels();
			var tw = 320, th = 180;
			var out = hxd.Pixels.alloc(tw, th, px.format);
			for( y in 0...th )
				for( x in 0...tw )
					out.setPixel(x, y, px.getPixel(Std.int(x * w / tw), Std.int(y * h / th)));
			var bytes = out.toPNG();
			tex.depthBuffer.dispose();
			tex.dispose();
			return bytes;
		} catch( e : Dynamic ) {
			return null;
		}
	}

	function saveGame( notify : Bool ) {
		if( game == null ) return;
		var ok = SaveData.write(game.toInfo(), captureThumb());
		if( notify ) showToast(ok ? Lang.t("saved.ok") : "ERROR");
	}

	/** Quitar o poner el casco (tecla H), con las mismas animaciones que Game.update del original. */
	function toggleHelmet() {
		if( helmetSeq.length > 0 ) return;
		if( helmetOn ) {
			helmetOn = false;
			helmetSeq = [{ wait : false, to : -210, dur : 0.1, easeIn : false }, { wait : true, to : 0, dur : 0.3, easeIn : false }, { wait : false, to : -1024, dur : 0.7, easeIn : true }];
			helmetOnDone = function() helmet.visible = false;
		} else {
			helmet.visible = true;
			helmetSeq = [{ wait : false, to : -250, dur : 0.5, easeIn : true }, { wait : true, to : 0, dur : 0.1, easeIn : false }, { wait : false, to : -190, dur : 0.8, easeIn : true }];
			helmetOnDone = function() helmetOn = true;
		}
		helmetT = 0;
		helmetFrom = helmetY;
	}

	function updateHelmet( dt : Float, p : GameView ) {
		if( helmetSeq.length > 0 ) {
			var s = helmetSeq[0];
			helmetT += dt;
			if( s.wait ) {
				if( helmetT >= s.dur ) {
					helmetSeq.shift();
					helmetT = 0;
					helmetFrom = helmetY;
				}
			} else {
				var f = Math.min(1, helmetT / s.dur);
				var e = s.easeIn ? f * f : 1 - (1 - f) * (1 - f);
				helmetY = helmetFrom + (s.to - helmetFrom) * e;
				if( f >= 1 ) {
					helmetSeq.shift();
					helmetT = 0;
					helmetFrom = helmetY;
				}
			}
			if( helmetSeq.length == 0 && helmetOnDone != null ) {
				var f = helmetOnDone;
				helmetOnDone = null;
				f();
			}
		}
		// casco puesto: sigue el vaiven de la camara
		if( helmetOn && helmetSeq.length == 0 ) {
			helmetX = -20 + p.bobX;
			helmetY = -190 + Math.cos(p.walkBobbing) * 2 + p.bobY;
		}
	}

	/** Coloca el casco y el brillo del jetpack cubriendo toda la ventana (escala del original: ancho/974, alto/624). */
	function layoutHelmet() {
		var ww = engine.width, wh = engine.height;
		var scale = Math.min(ww / W, wh / H);
		var visW = ww / scale, visH = wh / scale;
		var offX = (W - visW) * 0.5, offY = (H - visH) * 0.5;
		var sx = visW / 974, sy = visH / 624;
		for( b in [helmet, jetGlow] ) {
			b.scaleX = sx;
			b.scaleY = sy;
			b.x = offX + helmetX * sx;
			b.y = offY + helmetY * sy;
		}
		jetBar.setScale(1 / scale);
		jetBar.x = offX + (visW - 350 / scale) * 0.5;
		jetBar.y = offY + visH - 25 / scale;
	}

	/** Barra de combustible y brillo del jetpack, como Interface.updateJetpack y el HUD del original. */
	function updateJetHud( p : GameView ) {
		var ratio = 1 - p.jetpack;
		if( ratio <= 0 ) {
			jetBar.visible = false;
		} else {
			if( ratio > 1 ) ratio = 1;
			jetBar.visible = true;
			jetBar.clear();
			jetBar.beginFill(0x000000, 0.3);
			jetBar.drawRect(0, 0, 350, 4);
			var col = ratio >= 0.8 ? 0xFD5C17 : (ratio >= 0.6 ? 0xFFA428 : 0xFFD900);
			jetBar.beginFill(col, 1);
			jetBar.drawRect(0, 0, ratio * 350, 4);
			jetBar.endFill();
		}
		// el brillo solo se ve con el casco puesto (Hero.hx: if game.hudOn)
		jetGlow.visible = p.thrusting && helmetOn;
		if( jetGlow.visible ) jetGlow.alpha = 0.3 + Math.random() * 0.7;
	}

	function showToast( msg : String ) {
		toast.text = msg;
		toast.x = (W - toast.textWidth * toast.scaleX) * 0.5;
		toast.visible = true;
		toast.alpha = 1;
		toastTime = 2.2;
	}

	function makeDemoSaves() {
		var names = ["Base Alfa", "Cráter del Norte", "Mundo helado"];
		var biomes = ["BIAutumn", "BIMoon", "BIWinterPeaks"];
		for( i in 0...3 ) {
			var info = SaveData.create(names[i], 1000 + i * 77, biomes[i], 1 + (i % 2));
			info.playSeconds = 900 + i * 4100;
			info.saved = Date.now().getTime() - i * 86400000.0 * 1.3;
			SaveData.write(info, null);
			info.saved = Date.now().getTime() - i * 86400000.0 * 1.3;
			sys.io.File.saveContent(SaveData.jsonPath(info.id), haxe.Json.stringify(info, null, "  "));
		}
	}

	// ---------------------------------------------------------------- bucle principal

	override function update( dt : Float ) {
		frames++;
		if( dt > 0.1 ) dt = 0.1;
		if( state != Playing ) {
			jetBar.visible = false;
			jetGlow.visible = false;
		}
		// el casco se ve jugando y en pausa; en los menus no
		if( game == null || (state != Playing && state != Paused) ) {
			helmet.visible = false;
			helmetOn = true;
			helmetSeq = [];
			helmetX = -20;
			helmetY = -190;
		}

		// planeta de fondo del menu
		if( state == Boot ) {
			bgUpdate(dt);
			var p = bgBuilding != null ? bgBuilding.progress : (bgWorlds.length > 0 ? 1.0 : 0.0);
			setProgress(p);
			if( bgWorlds.length > 0 ) {
				state = Menu;
				ui.removeChildren();
				bar = null;
				show(shotScreen == "load" || shotScreen == "options" || shotScreen == "new" ? shotScreen : "main");
			}
		}
		if( state == Menu || state == Loading ) {
			if( state == Menu ) bgUpdate(dt);
			bgCamera(dt);
		}

		if( state == Loading && loadWorld != null ) {
			var p = loadWorld.step(14);
			setProgress(p);
			if( barText != null ) barText.text = p < 0.75 ? Lang.t("loading") : Lang.t("loading.mesh");
			if( loadWorld.isReady() ) finishLoading();
		}

		if( state == Playing && game != null ) {
			var K = hxd.Key;
			if( paletteOpen ) {
				if( K.isPressed(K.ESCAPE) || K.isPressed(K.I) ) closePalette();
				game.updateCamera();
			} else if( game.creative && K.isPressed(K.I) ) {
				openPalette();
			} else if( K.isPressed(K.ESCAPE) || (pad != null && pad.isPressed(pad.config.start)) ) { pause(); pausedThisFrame = true; }
			else {
				game.update(dt, true, pad);
				game.updateCamera();
				if( K.isPressed(K.F5) ) saveGame(true);
				autosaveTimer += dt;
				if( autosaveTimer > 120 ) {
					autosaveTimer = 0;
					saveGame(true);
				}
				var p = game;
				hud.text = Std.int(p.px) + ", " + Std.int(p.py) + ", " + Std.int(p.pz) + "   " + Std.int(engine.fps) + " fps\n" + Lang.t("hud.help") + (p.creative ? "\n" + Lang.t("hud.creative") : "");
				if( K.isPressed(K.H) || (pad != null && pad.isPressed(pad.config.back)) ) toggleHelmet();
				if( !helmet.visible && helmetOn ) helmet.visible = true;
				updateHelmet(dt, p);
				layoutHelmet();
				updateJetHud(p);
					if( invBar != null ) invBar.update(dt);
			}
		} else if( state == Paused && game != null ) {
			game.updateCamera();
		}

		if( invBar != null ) invBar.visible = state == Playing || state == Paused;
		cross.visible = state == Playing && game != null && game.laserActive;

		if( modal != null && modal.parent != null ) modal.update(dt, pad);
		else {
			modal = null;
			if( current != null && state != Loading && state != Boot && !pausedThisFrame ) current.update(dt, pad);
			pausedThisFrame = false;
		}

		if( toastTime > 0 ) {
			toastTime -= dt;
			if( toastTime < 0.6 ) toast.alpha = Math.max(0, toastTime / 0.6);
			if( toastTime <= 0 ) toast.visible = false;
		}

		// nieve (solo bioma de invierno): copos fijos en el mundo
		var snowWorld : World = null;
		if( (state == Playing || state == Paused) && game != null )
			snowWorld = game.world;
		else if( (state == Menu || state == Loading) && bgIndex < bgWorlds.length )
			snowWorld = bgWorlds[bgIndex];
		snow.visible = snowWorld != null && snowWorld.biomeName == "BIWinterPeaks" && dim.alpha < 0.5;
		if( snow.visible ) {
			var ww = engine.width, wh = engine.height;
			var scale = Math.min(ww / W, wh / H);
			var visW = ww / scale, visH = wh / scale;
			snow.update(dt, s3d.camera, snowWorld, (W - visW) * 0.5, (H - visH) * 0.5, visW, visH);
		}

		testShot();
	}

	// ---------------------------------------------------------------- fondo del menu

	/** Empieza a construir, uno por uno, los planetas que se ven de fondo (cada uno de un bioma distinto). */
	function bgStart() {
		bgDisposeAll();
		bgQueue = BIOMES.copy();
		for( i in 0...bgQueue.length ) {
			var j = Std.random(bgQueue.length);
			var t = bgQueue[i];
			bgQueue[i] = bgQueue[j];
			bgQueue[j] = t;
		}
		if( shotBiome != null ) bgQueue = [shotBiome];
		bgIndex = 0;
		bgTimer = 0;
		bgFade = 0;
		bgCamZ = -1;
		dim.alpha = 0;
	}

	function bgDisposeAll() {
		for( w in bgWorlds ) w.dispose();
		bgWorlds = [];
		if( bgBuilding != null ) bgBuilding.dispose();
		bgBuilding = null;
		bgQueue = [];
		dim.alpha = 0;
	}

	function bgShow( i : Int ) {
		bgIndex = i;
		if( shotPath != null ) Sys.println("fondo del menu: " + bgWorlds[i].biomeName + " (" + bgWorlds.length + " planetas listos)");
		for( k in 0...bgWorlds.length ) bgWorlds[k].root.visible = (k == i);
		bgCamZ = -1;
		bgPhase = Math.random() * 6.28;
		bgComputeAlt(bgWorlds[i]);
	}

	/**
		Altura de la camara a lo largo de la ruta circular, calculada de una vez: maximo del relieve
		(copas incluidas) en una ventana que anticipa los obstaculos, y luego suavizada. Asi la camara
		va siempre por encima de todo, sin subir y bajar al pasar sobre cada arbol.
	**/
	function bgComputeAlt( w : World ) {
		// se prueban varias rutas y se elige la mas baja y llana (menos montanas por encima)
		var s = w.size;
		var cands = [[0.5, 0.5, 0.2], [0.5, 0.5, 0.3], [0.5, 0.5, 0.4], [0.4, 0.4, 0.2], [0.6, 0.4, 0.2], [0.4, 0.6, 0.2], [0.6, 0.6, 0.2], [0.4, 0.4, 0.3], [0.6, 0.4, 0.3], [0.4, 0.6, 0.3], [0.6, 0.6, 0.3]];
		var best : Array<Float> = null;
		var bestScore = 1e18;
		for( c in cands ) {
			var tab = bgPathAlt(w, s * c[0], s * c[1], s * c[2]);
			var total = 0., mx = 0.;
			for( i in 0...tab.length ) {
				total += Math.abs(tab[(i + 1) % tab.length] - tab[i]);
				if( tab[i] > mx ) mx = tab[i];
			}
			var score = 0.5 * mx + 2.5 * total;
			if( score < bestScore ) {
				bestScore = score;
				best = tab;
				bgCx = s * c[0];
				bgCy = s * c[1];
				bgR = s * c[2];
			}
		}
		bgAlt = best;
		if( shotPath != null ) {
			var lo = 1e9, hi = -1e9, maxStep = 0.;
			for( i in 0...bgAlt.length ) {
				if( bgAlt[i] < lo ) lo = bgAlt[i];
				if( bgAlt[i] > hi ) hi = bgAlt[i];
				var d = Math.abs(bgAlt[(i + 1) % bgAlt.length] - bgAlt[i]);
				if( d > maxStep ) maxStep = d;
			}
			var spacing = 2 * Math.PI * bgR / bgAlt.length;
			Sys.println("ruta de camara " + w.biomeName + ": radio " + Std.int(bgR) + ", altura " + Std.int(lo) + "-" + Std.int(hi) + ", pendiente maxima " + (Math.round(maxStep / spacing * 100) / 100));
		}
	}

	/** Tabla de alturas (180 muestras) para una ruta circular. */
	function bgPathAlt( w : World, cx : Float, cy : Float, r : Float ) : Array<Float> {
		var M = 180;
		var raw = new Array<Float>();
		for( i in 0...M ) {
			var a = i / M * Math.PI * 2;
			var x = Std.int(cx + Math.cos(a) * r), y = Std.int(cy + Math.sin(a) * r);
			var top = 0;
			for( dx in -3...4 )
				for( dy in -3...4 ) {
					var hh = w.topCollide(x + dx * 2, y + dy * 2);
					if( hh > top ) top = hh;
				}
			raw.push(top);
		}
		var cur = new Array<Float>();
		for( i in 0...M ) {
			var m = 0.;
			for( k in -24...25 ) {
				var v = raw[(i + k + M * 2) % M];
				if( v > m ) m = v;
			}
			cur.push(m);
		}
		for( pass in 0...3 ) {
			var next = new Array<Float>();
			for( i in 0...M ) {
				var sum = 0.;
				for( k in -12...13 ) sum += cur[(i + k + M * 2) % M];
				next.push(sum / 25);
			}
			cur = next;
		}
		return [for( v in cur ) v + 9];
	}

	function bgUpdate( dt : Float ) {
		// construir el siguiente planeta de fondo (hasta 3 listos a la vez)
		if( bgBuilding == null && bgWorlds.length < 3 && bgQueue.length > 0 ) {
			var b = bgQueue.shift();
			bgBuilding = new World(Std.random(100000), b, 2, s3d, atlas, true);
			bgBuilding.root.visible = false;
		}
		if( bgBuilding != null ) {
			bgBuilding.step(state == Boot ? 14 : 6);
			if( bgBuilding.isReady() ) {
				bgWorlds.push(bgBuilding);
				bgBuilding = null;
				if( bgWorlds.length == 1 ) bgShow(0);
			}
		}
		if( bgWorlds.length < 2 ) return;

		// cambio de planeta con fundido a negro
		if( bgFade == 0 ) {
			bgTimer += dt;
			if( bgTimer > 22 ) {
				bgFade = 1;
				bgFadeT = 0;
			}
		} else {
			bgFadeT += dt / 0.8;
			if( bgFade == 1 ) {
				dim.alpha = Math.min(1, bgFadeT);
				if( bgFadeT >= 1 ) {
					bgShow((bgIndex + 1) % bgWorlds.length);
					bgFade = 2;
					bgFadeT = 0;
				}
			} else {
				dim.alpha = Math.max(0, 1 - bgFadeT);
				if( bgFadeT >= 1 ) {
					bgFade = 0;
					bgTimer = 0;
					dim.alpha = 0;
				}
			}
		}
	}

	/** Recorrido lento a baja altura por el terreno, mirando al horizonte, como se ve en el juego. */
	function bgCamera( dt : Float ) {
		if( bgIndex >= bgWorlds.length ) return;
		var w = bgWorlds[bgIndex];
		if( !w.isReady() ) return;
		if( bgAlt.length == 0 ) return;
		// velocidad lenta y constante (unos 2.5 bloques por segundo)
		bgPhase += dt * 0.065;
		var s = w.size;
		var x = bgCx + Math.cos(bgPhase) * bgR, y = bgCy + Math.sin(bgPhase) * bgR;
		// altura interpolada de la tabla precalculada
		var f = bgPhase / (Math.PI * 2);
		f -= Math.floor(f);
		var fi = f * bgAlt.length;
		var i0 = Std.int(fi) % bgAlt.length, i1 = (i0 + 1) % bgAlt.length;
		var t = fi - Std.int(fi);
		bgCamZ = bgAlt[i0] * (1 - t) + bgAlt[i1] * t;
		var yaw = bgPhase + Math.PI * 0.5 + 0.5;
		var pitch = -0.65; // el planeta es redondo: hay que mirar mas abajo para ver el terreno
		var c = s3d.camera;
		c.fovY = 65;
		c.zNear = 0.2;
		c.zFar = 1500;
		c.pos.set(x, y, bgCamZ);
		c.target.set(x + Math.cos(yaw) * Math.cos(pitch), y + Math.sin(yaw) * Math.cos(pitch), bgCamZ + Math.sin(pitch));
		c.up.set(0, 0, 1);
		w.sky.follow(x, y, bgCamZ);
		w.updateWrap(x, y);
	}

	// ---------------------------------------------------------------- pruebas automaticas

	var shotStage = 0;

	/** Prueba numerica de la fisica: reposo, salto, jetpack, caida libre y caminata (1 fotograma = tmod 1). */
	function physTest() {
		var g = game;
		function run( n : Int, speed : Float, strafe : Float, jet : Bool ) {
			for( i in 0...n ) g.stepPhysics(1.0, speed, strafe, jet);
		}
		function f( v : Float ) return "" + Math.round(v * 1000) / 1000;
		run(80, 0, 0, false);
		var z0 = g.pz;
		Sys.println("reposo: z=" + f(z0) + " gravedad=" + f(g.gravity) + " combustible=" + f(g.jetpack) + " enSuelo=" + g.onGround());

		// salto: una pulsacion de un fotograma
		g.stepPhysics(1.0, 0, 0, true);
		var zmax = g.pz, frames = 1;
		for( i in 0...120 ) {
			g.stepPhysics(1.0, 0, 0, false);
			if( g.pz > zmax ) zmax = g.pz;
			frames++;
			if( g.onGround() ) break;
		}
		Sys.println("salto simple: altura maxima=" + f(zmax - z0) + " bloques, duracion=" + frames + " fotogramas (" + f(frames / 32) + " s). Formula 0.23^2/(2*0.014)=" + f(0.23 * 0.23 / (2 * 0.014)));

		// jetpack: espacio mantenido 90 fotogramas
		run(40, 0, 0, false);
		z0 = g.pz;
		var fuel0 = g.jetpack;
		zmax = z0;
		var fuelEnd = 0., tEmpty = -1;
		for( i in 0...90 ) {
			g.stepPhysics(1.0, 0, 0, true);
			if( g.pz > zmax ) zmax = g.pz;
			if( tEmpty < 0 && g.jetpack <= 0 ) tEmpty = i;
		}
		fuelEnd = g.jetpack;
		Sys.println("jetpack mantenido 90 fotogramas: altura maxima=" + f(zmax - z0) + " combustible " + f(fuel0) + " -> " + f(fuelEnd) + (tEmpty >= 0 ? ", se agota en el fotograma " + tEmpty : ""));
		// caer
		var maxG = 0., n = 0;
		while( !g.onGround() && n < 600 ) {
			g.stepPhysics(1.0, 0, 0, false);
			if( g.gravity > maxG ) maxG = g.gravity;
			n++;
		}
		Sys.println("aterriza tras " + n + " fotogramas, gravedad maxima alcanzada=" + f(maxG));

		// caida libre desde 25 bloques
		run(40, 0, 0, false);
		var zs = g.pz;
		g.pz += 25;
		g.gravity = 0;
		g.standingBlock = null;
		maxG = 0;
		n = 0;
		while( !g.onGround() && n < 600 ) {
			g.stepPhysics(1.0, 0, 0, false);
			if( g.gravity > maxG ) maxG = g.gravity;
			n++;
		}
		Sys.println("caida de 25 bloques: " + n + " fotogramas (" + f(n / 32) + " s), gravedad maxima=" + f(maxG) + " (tope 0.9), aterriza en z=" + f(g.pz) + " (suelo " + f(zs) + ")");

		// caminar: 32 fotogramas = 1 segundo, hacia una direccion libre
		var bestDist = -1., bestMode = "";
		for( mode in ["normal", "despacio"] ) {
			run(30, 0, 0, false);
			var x0 = g.px, y0 = g.py;
			var sp = mode == "normal" ? 0.15 : 0.15 * 0.4;
			run(32, sp, 0, false);
			var d = Math.sqrt((g.px - x0) * (g.px - x0) + (g.py - y0) * (g.py - y0));
			Sys.println("caminar " + mode + " 1 s: recorre " + f(d) + " bloques (esperado " + f(sp * 32) + " si no hay obstaculos)");
		}
		// no atraviesa paredes: empuja 200 fotogramas contra lo que haya delante
		var x1 = g.px, y1 = g.py;
		run(200, 0.15, 0, false);
		var tot = Math.sqrt((g.px - x1) * (g.px - x1) + (g.py - y1) * (g.py - y1));
		Sys.println("200 fotogramas hacia delante: recorre " + f(tot) + " bloques (sin atravesar el terreno: z=" + f(g.pz) + ")");
	}

	function testShot() {
		if( shotPath == null ) return;
		// menus: esperar a que el planeta de fondo este listo y sacar la captura
		if( state == Menu && shotStage == 0 && frames > shotFrames ) {
			if( shotScreen == "game" || shotScreen == "pause" || shotScreen == "phys" || shotScreen == "jet" || shotScreen == "mine" || shotScreen == "place" || shotScreen == "cont" || shotScreen == "palette" ) {
				shotStage = 1;
				if( shotScreen == "cont" ) {
					// carga la partida mas reciente (prueba de guardado)
					shotCont = true;
					shotScreen = "mine";
				}
				var info = shotCont ? SaveData.list()[0] : SaveData.create("Prueba", 1234, shotBiome != null ? shotBiome : "BIAutumn", 1);
				startGame(info);
				return;
			}
			capture(shotPath);
		}
		if( state == Playing && shotStage == 1 ) {
			shotStage = 2;
			if( shotAt != null && shotAt.length >= 3 ) {
				game.px = shotAt[0];
				game.py = shotAt[1];
				game.yaw = shotAt[2];
				if( shotAt.length > 3 ) game.pitch = shotAt[3];
				game.pz = shotAt.length > 4 ? shotAt[4] : game.world.topCollide(Std.int(game.px), Std.int(game.py)) + 0.01;
			}
			if( shotScreen == "phys" ) {
				physTest();
				Sys.exit(0);
			}
			if( shotScreen == "jet" ) {
				game.debugJet = true;
				shotFrames = frames + 45;
				return;
			}
			if( shotScreen == "mine" || shotScreen == "place" ) {
				game.inv.select(shotScreen == "mine" ? 0 : shotSlot);
				game.debugAction = !shotCont;
				game.debugDeny = Sys.args().indexOf("--deny") >= 0;
				shotFrames = frames + shotN;
				return;
			}
			if( shotScreen == "palette" ) {
				openPalette();
				shotFrames = frames + 8;
				return;
			}
			if( shotScreen == "pause" ) {
				pause();
				shotFrames = frames + 6;
			} else
				shotFrames = frames + 6;
		}
		if( shotStage == 2 && frames > shotFrames && (state == Playing || state == Paused) ) {
			if( Sys.args().indexOf("--listnear") >= 0 ) {
				// solo pruebas: bloques no cubicos a menos de 10 bloques del jugador
				var w = game.world;
				var out = [];
				for( dz in -6...7 )
					for( dy in -10...11 )
						for( dx in -10...11 ) {
							var b = w.block(Std.int(game.px) + dx, Std.int(game.py) + dy, Std.int(game.pz) + dz);
							if( b != null && b.type != BTFull && b.type != BTTransp && b.type != BTWater && b.type != BTModel2Side )
								out.push(b.k + "/" + b.type + "@" + dx + "," + dy + "," + dz);
						}
				Sys.println("cerca: " + out.join("  "));
			}
			if( shotScreen == "mine" || shotScreen == "place" ) {
				if( Sys.args().indexOf("--save") >= 0 ) saveGame(false);
				var n = 0;
				var cells = [];
				for( k in game.world.editMap.keys() ) {
					n++;
					var col = k >> 7;
					cells.push((col % game.world.size) + "," + Std.int(col / game.world.size) + "," + (k & 127));
				}
				if( cells.length > 0 ) Sys.println("celdas: " + cells.join("  "));
				var items = [for( s in game.inv.inv.t ) s == null ? "-" : Block.all[s.k].k + "x" + s.n];
				Sys.println("ediciones: " + n + "  inventario: " + items.join(" ") + "  select: " + (game.select == null ? "ninguno" : game.select.b.k + " poder=" + game.select.power));
			}
			capture(shotPath);
		}
	}

	function capture( path : String ) {
		var w = engine.width, h = engine.height;
		var tex = new h3d.mat.Texture(w, h, [Target]);
		tex.depthBuffer = new h3d.mat.Texture(w, h, [Target], Depth24Stencil8);
		engine.pushTarget(tex);
		engine.clear(0xFF05070D, 1, 0);
		s3d.render(engine);
		s2d.render(engine);
		engine.popTarget();
		sys.io.File.saveBytes(path, tex.capturePixels().toPNG());
		Sys.println("captura guardada: " + path);
		Sys.exit(0);
	}

	static function main() {
		new GalaxyApp();
	}
}
