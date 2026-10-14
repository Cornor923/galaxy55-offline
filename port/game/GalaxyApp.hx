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
		Theme.text(this, biome + "  ·  " + size + "x" + size + "  ·  " + Lang.t("seed") + " " + info.seed, 1.7, Theme.CYAN, 190, 48);
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

	// formulario de nueva partida
	var nName : TextField;
	var nSeed : TextField;
	var nBiome : Selector;
	var nSize : Selector;

	override function init() {
		for( a in Sys.args() ) {
			if( StringTools.startsWith(a, "--shot=") ) shotPath = a.substr(7);
			else if( StringTools.startsWith(a, "--screen=") ) shotScreen = a.substr(9);
			else if( StringTools.startsWith(a, "--frames=") ) shotFrames = Std.parseInt(a.substr(9));
			else if( a == "--demo-saves" ) demoSaves = true;
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
		atlas = hxd.res.Any.fromBytes("texture.png", png).toTexture();
		atlas.filter = Nearest;
		atlas.mipMap = None;

		dim = new h2d.Bitmap(h2d.Tile.fromColor(0x000000, W, H, 0.0), s2d);
		ui = new h2d.Object(s2d);
		hud = Theme.text(s2d, "", 1.8, 0xFFFFFF, 14, 10);
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
		var s = panelFor(760, 560, Lang.t("newgame.title"));
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
		var create = new Button(s, Lang.t("create"), 560);
		var back = new Button(s, Lang.t("back"), 560);
		var y = 190.;
		s.add(nName, x, y);
		s.add(nSeed, x, y + 66);
		s.add(nBiome, x, y + 132);
		s.add(nSize, x, y + 198);
		s.add(create, x, y + 280);
		s.add(back, x, y + 346);
		create.onActivate = function() {
			var seed = Std.parseInt(nSeed.text);
			if( seed == null || seed <= 0 ) seed = randomSeed();
			var biome = nBiome.index == 0 ? BIOMES[seed % BIOMES.length] : BIOMES[nBiome.index - 1];
			var name = StringTools.trim(nName.text);
			if( name == "" ) name = "Planeta";
			startGame(SaveData.create(name, seed, biome, nSize.index + 1));
		};
		back.onActivate = function() show("main");
		s.onBack = function() show("main");
		hint(s, (W - 600) * 0.5 + 50, 640);
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
		var s = panelFor(860, 560, Lang.t("options.title"));
		var x = (W - 660) * 0.5;
		var y = 175.;
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
		var back = new Button(s, Lang.t("back"), 660);
		s.add(lang, x, y);
		s.add(sens, x, y + 60);
		s.add(fov, x, y + 120);
		s.add(vol, x, y + 180);
		s.add(full, x, y + 240);
		s.add(inv, x, y + 300);
		s.add(back, x, y + 380);
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
		loadWorld = new World(info.seed, info.biome, info.sizeChunks, s3d, atlas);
		loadWorld.root.visible = false;
		showLoading(Lang.t("loading"));
	}

	function finishLoading() {
		bgDisposeAll();
		loadWorld.root.visible = true;
		game = new GameView(s3d, loadWorld, loadInfo);
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
		state = Playing;
		hud.visible = true;
		captureMouse(true);
	}

	function pause() {
		state = Paused;
		captureMouse(false);
		hud.visible = false;
		show("pause");
	}

	function toMainMenu() {
		saveGame(false);
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
		hxd.Window.getInstance().mouseMode = on ? Relative(onMouse, true) : Absolute;
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
			if( K.isPressed(K.ESCAPE) || (pad != null && pad.isPressed(pad.config.start)) ) pause();
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
				hud.text = Lang.t(p.fly ? "mode.fly" : "mode.walk") + "   " + Std.int(p.px) + ", " + Std.int(p.py) + ", " + Std.int(p.pz) + "   " + Std.int(engine.fps) + " fps\n" + Lang.t("hud.help");
			}
		} else if( state == Paused && game != null ) {
			game.updateCamera();
		}

		if( modal != null && modal.parent != null ) modal.update(dt, pad);
		else {
			modal = null;
			if( current != null && state != Loading && state != Boot ) current.update(dt, pad);
		}

		if( toastTime > 0 ) {
			toastTime -= dt;
			if( toastTime < 0.6 ) toast.alpha = Math.max(0, toastTime / 0.6);
			if( toastTime <= 0 ) toast.visible = false;
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
	}

	function bgUpdate( dt : Float ) {
		// construir el siguiente planeta de fondo (hasta 3 listos a la vez)
		if( bgBuilding == null && bgWorlds.length < 3 && bgQueue.length > 0 ) {
			var b = bgQueue.shift();
			bgBuilding = new World(Std.random(100000), b, 1, s3d, atlas, true);
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
		bgPhase += dt * 0.11;
		var s = w.size;
		var cx = s * 0.5, cy = s * 0.5, r = s * 0.3;
		var x = cx + Math.cos(bgPhase) * r, y = cy + Math.sin(bgPhase) * r;
		// altura: por encima de lo mas alto en los alrededores (copas incluidas)
		var top = 0;
		for( dx in -2...3 )
			for( dy in -2...3 ) {
				var h = w.topCollide(Std.int(x) + dx * 2, Std.int(y) + dy * 2);
				if( h > top ) top = h;
			}
		var target = top + 8.0;
		if( bgCamZ < 0 ) bgCamZ = target;
		bgCamZ += (target - bgCamZ) * Math.min(1, dt * 1.6);
		var yaw = bgPhase + Math.PI * 0.5 + 0.5;
		var pitch = -0.17;
		var c = s3d.camera;
		c.fovY = 65;
		c.zNear = 0.2;
		c.zFar = 1500;
		c.pos.set(x, y, bgCamZ);
		c.target.set(x + Math.cos(yaw) * Math.cos(pitch), y + Math.sin(yaw) * Math.cos(pitch), bgCamZ + Math.sin(pitch));
		c.up.set(0, 0, 1);
		w.sky.follow(x, y, bgCamZ);
	}

	// ---------------------------------------------------------------- pruebas automaticas

	var shotStage = 0;

	function testShot() {
		if( shotPath == null ) return;
		// menus: esperar a que el planeta de fondo este listo y sacar la captura
		if( state == Menu && shotStage == 0 && frames > shotFrames ) {
			if( shotScreen == "game" || shotScreen == "pause" ) {
				shotStage = 1;
				var info = SaveData.create("Prueba", 1234, shotBiome != null ? shotBiome : "BIAutumn", 1);
				startGame(info);
				return;
			}
			capture(shotPath);
		}
		if( state == Playing && shotStage == 1 ) {
			shotStage = 2;
			if( shotScreen == "pause" ) {
				pause();
				shotFrames = frames + 6;
			} else
				shotFrames = frames + 6;
		}
		if( shotStage == 2 && frames > shotFrames && (state == Playing || state == Paused) ) {
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
