import mt.flash.Key;
import mt.deepnight.Tweenie;
import Common;
import Protocol;
import r3d.AbstractGame;

private typedef K = flash.ui.Keyboard;
@:file("gfx/hud.png") class BmpHud extends h3d.mat.PngBytes { }
@:file("gfx/hud_jetpack.png") class BmpHudJetpack extends h3d.mat.PngBytes { }
@:file("gfx/lazer.png") class BmpLazer extends h3d.mat.PngBytes { }
@:file("gfx/lazer2.png") class BmpLazer2 extends h3d.mat.PngBytes { }
@:file("gfx/lazer3.png") class BmpLazer3 extends h3d.mat.PngBytes { }
@:file("gfx/lazer4.png") class BmpLazer4 extends h3d.mat.PngBytes { }
@:file("gfx/ship_halo.png") class BmpShipHalo extends h3d.mat.PngBytes { }

@:file("gfx/cone.png") class BmpCone extends h3d.mat.PngBytes { }
//@:bitmap("gfx/skyTexture.png") class BmpSkyTexture extends flash.display.BitmapData { }



@:publicFields class Game extends Mode {
	
	static inline var H_HELMET = 0;
	static inline var H_JETPACK = 1;
	
	var tw : Tweenie;
	
	var debug : Debug;
	var level : Level;
	var process : Process;
	var render : r3d.Render;
	var needRedraw : Bool;
	var select : Selection;
	var interf : Interface;
	var walkBobbing : Float;
	var bobbingX : Float;
	var bobbingY : Float;
	var shake : Float;
	var turnSpeed : Float;
	
	var controlType : Controls;
	var oldControls : Controls;
	
	var mouseOut : Bool;
	var hudOn : Bool;
	var actionKeys : Bool;
	var laser : { c : ChargeKind, active : Bool, wait : Bool, canBreak : Bool};
	
	var loadAnim : Null<fx.Load>;
	var loadCpt : Float;
	var tmodSave : Float;
	
	var drag : { x : Int, y : Int, az : Float, dx : Int, dy : Int, active : Bool };
	var fadeFX : { t : Float, col : Int, speed : Float, dz : Float, done : Void -> Void, getAlpha:Null<Float->Float> };
	var fullScreen : Bool;
	var fullScreenInteractiveAllowed : Bool;
	var lookLock : Bool;
	var lookDX : Float = 0.;
	var lookDY : Float = 0.;
	var mouseHeld : Bool;
	var softLook : Bool;
	var softPX : Float = 0.;
	var softPY : Float = 0.;
	var showFPS : flash.text.TextField;
	var padTf : flash.text.TextField;
	var padHelmet : Bool;
	var shipPending : Bool;
	var logTime : Float = 0.;
	var chunksReceived : Int = 0;
	
	var hero : ent.Hero;
	var clones : Array<ent.OnlineHero>;
	var smoothMouse	: {x:Float,y:Float};
	
	var laserSound	: Null<flash.media.SoundChannel>;
	
	var infos : GameInfos;
	var planet : r3d.AbstractGame.PlanetData;
	var time : Float;
	var dummies : List<ent.Dummy>;
	var onAction : Void -> Void;
	var ship : ShipLogic;
	var agame : r3d.AbstractGame;

	var perlin : gen.FPerlin;
	
	var userMap : IntHash<String>;
	var realTime : net.RealTime<ent.OnlineHero>;
	var cloneTex : h3d.mat.PngBytes;
	
	var inClassic : input.Classic;
	var inMouse : input.Mouse;
	var inMouseLock : input.MouseLock;
	var inPad : input.Pad;

	public function new(root, engine, api, infos ) {
		super(root, engine, api);
		inst = this;
		Main.track(this, "Game"); Main.track(api, "Api");
		
		tw = new Tweenie();
		
		mt.fx.Fx.DEFAULT_MANAGER = new mt.fx.Manager();
		
		laser = { c : null, active : false, wait : false, canBreak : true};
		time = 0;
		this.infos = infos;
		this.planet = new r3d.AbstractGame.PlanetData(infos.planet);
		
		var psize = infos.planet.size;
		this.level = new Level(psize);
		Main.track(level, "Level");
		dummies = new List();
		userMap = new IntHash();
		process = new Process(this);
		hero = new ent.Hero();
		clones = [];
		walkBobbing = 0;
		bobbingX = 0;
		bobbingY = 0;
		shake = 0;
		turnSpeed = 0;
		mouseOut = true;
		hudOn = true;
		actionKeys = true;
		smoothMouse = { x:root.mouseX, y:root.mouseY };
		
		perlin = new gen.FPerlin(0);
		perlin.size = planet.totalSize;
		perlin.init(planet.id, 0, 0, 0);
		
		if( infos.ship != null ) {
			ship = new ShipLogic(this);
			ship.init();
			if( infos.crafts != null ) {
				var extra = level.extra;
				infos.crafts.reverse(); // minor fix in case of overlaps
				for( c in infos.crafts ) {
					var x = (c.addr >> Const.X) & Const.MASK;
					var y = (c.addr >> Const.Y) & Const.MASK;
					var z = (c.addr >> Const.Z) & Const.ZMASK;
					var b = Block.all[c.bid];
					if( ship.addCraft( x, y, z, b ) )
						level.set(x + extra.posX, y + extra.posY, z + extra.posZ, b);
				}
			}
		}
		
		var pos = api.getPosition(infos.lastPos);
		hero.x = pos.x % planet.totalSize;
		hero.y = pos.y % planet.totalSize;
		hero.z = pos.z;
		hero.angle = pos.a;
		hero.angleZ = pos.az;
		hero.life = pos.life;
		controlType = pos.mouseCtrl?MOUSE:CLASSIC;
		cnx.setControls.call([controlType==MOUSE]);
	
		if( infos.lastPos != null && infos.lastPos.flags.has(ReturnToShip) )
			hero.gotoShip(true);
		
		if( pos.flags.has(Flying) )
			hero.cheating = true;
		if( pos.flags.has(Invincible) )
			hero.invincible = true;

		engine.debug = infos.debug;
		agame = new r3d.AbstractGame(level, engine, planet, new flash.display.Sprite(),
		{
			shipDockBitmap:BmpShipHalo,
			laserBitmaps:[BmpLazer,BmpLazer2,BmpLazer3,BmpLazer4],
		});
		agame.getEffects = getEffects;
		agame.needRedraw = function() this.needRedraw = true;
		agame.loadChunk = function(x, y) this.api.requestChunk(x, y);
		agame.makeField = Interface.newTextField.bind(12);
		render = new r3d.Render(agame);
		
		api.onSetBlock = function(x, y, z, b) {
			var b = Block.all[b];
			level.set(x, y, z, b);
			render.builder.updateKube(x, y, z, b);
		};
		api.onCancelInventory = function(b, i, add) {
			interf.cancelBlock(Block.all[b],i,add);
		};
		
		lock = true;
		listen(root, flash.events.Event.ENTER_FRAME, function(_) update());
		
		// añadido nuestro: en modo local la nave aterriza en un punto distinto por planeta y el jugador empieza dentro de ella;
		// hace falta todo el terreno cargado para elegir el punto
		shipPending = ship != null && Std.is(api, net.Local);
		if( shipPending ) {
			for( cx in 0...infos.planet.size )
				for( cy in 0...infos.planet.size )
					api.requestChunk(cx, cy);
		} else
			api.requestChunk(Std.int(hero.x) >> Const.BITS, Std.int(hero.y) >> Const.BITS);
		cnx.lockBar.call([]);
		
		loadAnim = new fx.Load();
		root.addChild(loadAnim);
		loadCpt = 0;
		
		debug = new Debug(this);
		
		cloneTex = new BmpCone();
		userMap.set( infos.userId, infos.userName );
		userMap.set( 0, "ESBot" );
		
		inClassic =  new input.Classic(this);
		inMouse =  new input.Mouse(this);
		inMouseLock =  new input.MouseLock(this);
		inPad = new input.Pad(this);
	}
	
	/** true mientras se juega con el mando: la mira es el centro de la pantalla y se ignora el ratón */
	public inline function padAiming() return inPad != null && inPad.connected && inPad.idle < 4.;
	/** bloque en la mano; con el mando, RT (romper) sin LT lo trata como mano vacía */
	function handBlock() {
		if( padAiming() && inPad.breaking && !inPad.placing ) return null;
		return interf.getCurrentBlock();
	}
	public inline function mouseControls() return controlType == MOUSE;
	public inline function ctrlMouseLock() return controlType == MOUSE_LOCK;
	
	function getEffects(px:Float,py:Float,pz:Float) : r3d.AbstractGame.GameEffects {
		var fades = new Array<{ a : Float, col : Int }>();
		var fogPower = planet.biome.fogPower;
		var fogColors = planet.biome.fog.copy();
		for( i in 0...fogColors.length )
			fogColors[i] |= 0xFF000000;
			
		if( fadeFX != null )
			if( fadeFX.getAlpha!=null )
				fades.push({a:fadeFX.getAlpha(fadeFX.t), col:fadeFX.col});
			else
				fades.push({a:fadeFX.t, col:fadeFX.col});
		if( hero.enteringShip > 0 )
			fades.push( { a : hero.enteringShip, col : 0xFFFFFF } );
			
		var inWater = hero.inWaterBlock;
		if( inWater != null ) {
			for( f in inWater.flags )
				switch( f ) {
				case BFColor(c, alpha):
					if( alpha == null ) alpha = 0.65;
					var s = perlin.initScale(1 / 16);
					perlin.select();
					fogPower = 60*alpha + perlin.gradient3DAt((px + time) * s, py * s, pz * s) * 10;
					fogColors = [0xFF000000 | c, 0xFF000000 | c, 0xFF000000 | c];
					alpha += Math.sin(Math.PI*2*(time%2.5)/2.5) * 0.08;
					if( alpha>1 ) alpha = 1;
					if( alpha<0.3 ) alpha = 0.3;
					fades.push({ a : alpha, col : c });
					break;
				default:
				}
		}
		return {
			time : time,
			fades : fades,
			fogPower : fogPower,
			fogColors : fogColors,
			dummies : cast dummies,
			inWater : inWater != null && inWater.type == BTWater,
			select : select,
			bobbing : { x : bobbingX, y : bobbingY },
			currentBlock : interf.getCurrentBlock(),
			laser : select != null && select.b != null && laser.active ? laser : null,
			shipDock : ship != null && ship.start != null ? { x : ship.x, y : ship.y, z : ship.z, h : ship.start.z - ship.z } : null,
			skyBoxAlpha : 1 - Math.pow(fogPower - 1, 2) / 10,
			entities : cast (realTime == null ? clones : realTime.entities),
		};
	}
	
	function init() {
		var stage = flash.Lib.current.stage;
		
		loadAnim.parent.removeChild(loadAnim);
		loadAnim = null;
		
		interf = new Interface(this, infos.inventory, agame.softHudContext);
		Log.add("Init");
		
		var pos = infos.lastPos;
		if( pos != null && pos.flags.has(CameraMode) ) {
			var b = level.get(Std.int(pos.x), Std.int(pos.y), Std.int(pos.z));
			if( b == null || b.k != BCamera ) {
				var b = new flash.display.BitmapData(stage.stageWidth >> 2, stage.stageHeight >> 2, false, 0);
				var bmp = new flash.display.Bitmap(b);
				bmp.scaleX = bmp.scaleY = 4;
				root.addChild(bmp);
				var frame = 0;
				var pixels = b.getPixels(b.rect);
				showHelpTip("camera_broken");
				listen(root, flash.events.Event.ENTER_FRAME, function(_) {
					if( frame++ % 2 == 0 )
						b.noise(Std.random(0x1000000), 0, 255, 0, true);
				});
				return;
			} else {
				process.onActivate(Std.int(pos.x), Std.int(pos.y), Std.int(pos.z), b);
				controlType = MOUSE;
				hero.angleSpeed = 0.3;
				onAction = null;
			}
		} else if( !hero.cheating )
			hero.recallZ(Std.int(hero.z));
		
		render.init();
		render.initHud(new BmpHud(), H_HELMET).visible = hudOn;
		render.initHud(new BmpHudJetpack(), H_JETPACK).visible = false;
		
		var size = 1024;
		var skyBmp = new flash.display.BitmapData(size, size, true, 0);
		//for( i in 0...(size * size) >> 7 ) {
		for( i in 0...Std.int(size * size * 0.003) ) {
			var x = Std.random(size);
			var y = Std.random(size);
			//var k = Std.random(200) + 32;
			var k = 255;
			skyBmp.setPixel32(x, y, (k << 24) | 0xFFFFFF);
		}
		//var tex = new BmpSkyTexture(0,0);
		//for( x in 0...Std.int(1024/64) ) {
			//var m = new flash.geom.Matrix();
			//m.translate(x*64,512);
			//skyBmp.draw(tex, m);
		//}
		var skyBitmaps = [];
		for( i in 0...6 )
			skyBitmaps.push(skyBmp);
		render.initSky(skyBitmaps);
		skyBmp.dispose();
		
		
		interf.display();
			
		showFPS = new flash.text.TextField();
		showFPS.width = 200;
		showFPS.mouseEnabled = false;
		showFPS.visible = false;
		showFPS.textColor = 0xFFFFFF;
		showFPS.x = 10;
		showFPS.y = 10;
		showFPS.filters = [new flash.filters.GlowFilter(0, 1, 2, 2, 10)];
		root.addChild(showFPS);

		// panel de calibración del mando (temporal): muestra los controles activos
		padTf = new flash.text.TextField();
		padTf.width = 300; padTf.height = 400;
		padTf.mouseEnabled = false;
		padTf.textColor = 0xFFFF00;
		padTf.x = 10; padTf.y = 120;
		padTf.filters = [new flash.filters.GlowFilter(0, 1, 2, 2, 10)];
		root.addChild(padTf);
				
		needRedraw = true;
		lock = false;
		onResize();

		if( !engine.hardware ) cnx.toggle.call(["#warnsoft"]);
		
		hero.doMove(0, 0, 0, false);
		if( (hero.onWater() || hero.inWater()) && api.isOffline() ) {
			var p = level.getStartPlace(api.planet);
			if( p != null ) {
				hero.x = p.x + 0.5;
				hero.y = p.y + 0.5;
				hero.z = p.z;
			}
		}
		
		update();
		listen(root.stage, flash.events.MouseEvent.MOUSE_DOWN,click.bind(false));
		listen(root.stage, flash.events.MouseEvent.MOUSE_UP, click.bind(true));
		listen(root.stage, flash.events.MouseEvent.MOUSE_DOWN, function(_) mouseHeld = true);
		listen(root.stage, flash.events.MouseEvent.MOUSE_UP, function(_) mouseHeld = false);
		listen(root.stage, flash.events.Event.DEACTIVATE, function(_) setSoftLook(false));
		listen(root.stage, flash.events.Event.MOUSE_LEAVE, function(e) mouseOut = true);
		listen(root.stage, flash.events.MouseEvent.MOUSE_MOVE, function(e) mouseOut = false);
		listen(root.stage, flash.events.MouseEvent.MOUSE_MOVE, function(e:flash.events.MouseEvent) {
			if( lookLock ) { lookDX += untyped e.movementX; lookDY += untyped e.movementY; }
		});
		listen(root.stage, flash.events.FullScreenEvent.FULL_SCREEN, function(e:flash.events.FullScreenEvent) {
			fullScreen = e.fullScreen;
			if( e.fullScreen ) setSoftLook(false);
			setLookLock(e.fullScreen);
		});
		listen(root.stage, flash.events.Event.RESIZE, function(_) haxe.Timer.delay(onResize, 1));
		
		if( hero.life <= 0 )
			hero.hit(0); // check life
		
		// si venimos de otro modo ya en pantalla completa, recupera el bloqueo del ratón
		try if( Std.string(root.stage.displayState) == "fullScreenInteractive" ) setLookLock(true) catch( e : Dynamic ) {}
		
		/*
		listen(root.stage,  flash.events.FullScreenEvent.FULL_SCREEN_INTERACTIVE_ACCEPTED , function(e)
			fullScreenInteractiveAllowed = true;
		);*/
	}

	// ---- menu del ordenador de a bordo (antes era HTML en la web) ----
	var menuMC : flash.display.Sprite;
	var menuOpen : Bool;
	
	public function openComputerMenu() {
		if( menuOpen || disposed ) return;
		menuOpen = true;
		actionKeys = false;
		var tf = new flash.text.TextField();
		tf.selectable = false;
		tf.multiline = true;
		tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
		tf.defaultTextFormat = new flash.text.TextFormat("_sans", 18, 0xFFFFFF, true);
		var menuText = getText("menu_title") + "\n\n" + getText("menu_takeoff") + "\n" + getText("menu_edit") + "\n" + getText("menu_trade") + "\n" + getText("menu_close");
		// con mando conectado y en uso se muestran sus botones en vez de los números del teclado
		if( inPad.connected )
			menuText = StringTools.replace(StringTools.replace(StringTools.replace(StringTools.replace(menuText, "[1]", "[A]"), "[2]", "[X]"), "[3]", "[B]"), "[4]", "[Y]");
		tf.text = menuText;
		var pad = 18;
		menuMC = new flash.display.Sprite();
		menuMC.mouseEnabled = false;
		menuMC.mouseChildren = false;
		tf.x = pad; tf.y = pad;
		menuMC.graphics.beginFill(0x08121C, 0.88);
		menuMC.graphics.lineStyle(2, 0x7DC9F7, 0.9);
		menuMC.graphics.drawRoundRect(0, 0, tf.width + pad * 2, tf.height + pad * 2, 12, 12);
		menuMC.graphics.endFill();
		menuMC.addChild(tf);
		var st = root.stage;
		menuMC.x = (st.stageWidth - menuMC.width) * 0.5;
		menuMC.y = (st.stageHeight - menuMC.height) * 0.4;
		root.addChild(menuMC);
		listen(st, flash.events.KeyboardEvent.KEY_DOWN, onMenuKey);
	}
	
	function closeComputerMenu() {
		if( !menuOpen ) return;
		menuOpen = false;
		if( menuMC != null && menuMC.parent != null ) menuMC.parent.removeChild(menuMC);
		menuMC = null;
		try root.stage.removeEventListener(flash.events.KeyboardEvent.KEY_DOWN, onMenuKey) catch( e : Dynamic ) {}
		haxe.Timer.delay(function() if( !shopOpen && !disposed ) actionKeys = true, 250);
	}

	function onMenuKey( e : flash.events.KeyboardEvent ) {
		if( !menuOpen ) return;
		switch( e.keyCode ) {
		case 49, 97: menuChoose(1);
		case 50, 98: menuChoose(2);
		case 52, 100: menuChoose(4);
		case 51, 99, 27, 8: menuChoose(3); // 3, Esc, Backspace
		}
	}

	public function menuChoose( n : Int ) {
		if( !menuOpen ) return;
		closeComputerMenu();
		switch( n ) {
		case 1: api.send(CEnterSpace);
		case 2: api.send(CEditShip);
		case 4: openShop();
		default:
		}
	}

	// ---- tienda de la ESCorp (añadido nuestro): el original era un panel web con servidor y precios de mercado ----
	// Se vende lo que llevas en el inventario a la mitad del precio base, y se compran piezas de nave al precio base.
	static var SELL_RATE = 0.5;
	static var BUY_LIST = [BShipHull, BShipPlate, BShipWire, BShipTubes, BShipGlass, BShipGlass2, BShipDoor, BShipLight, BShipEngine, BShipComputer, BShipEntry, BCrafter, BCrafterComputer];
	var shopMC : flash.display.Sprite;
	var shopTf : flash.text.TextField;
	public var shopOpen : Bool;
	var shopTab : Int; // 0 = vender, 1 = comprar
	var shopSel : Int;
	var shopMsg : String;

	public function openShop() {
		if( shopOpen || disposed ) return;
		shopOpen = true;
		actionKeys = false;
		shopTab = 0;
		shopSel = 0;
		shopMsg = null;
		shopMC = new flash.display.Sprite();
		shopMC.mouseEnabled = false;
		shopMC.mouseChildren = false;
		shopTf = new flash.text.TextField();
		shopTf.selectable = false;
		shopTf.multiline = true;
		shopTf.autoSize = flash.text.TextFieldAutoSize.LEFT;
		shopTf.defaultTextFormat = new flash.text.TextFormat("_typewriter", 15, 0xFFFFFF, true);
		shopTf.x = 18; shopTf.y = 18;
		shopMC.addChild(shopTf);
		root.addChild(shopMC);
		listen(root.stage, flash.events.KeyboardEvent.KEY_DOWN, onShopKey);
		shopRedraw();
	}

	public function closeShop() {
		if( !shopOpen ) return;
		shopOpen = false;
		if( shopMC != null && shopMC.parent != null ) shopMC.parent.removeChild(shopMC);
		shopMC = null;
		try root.stage.removeEventListener(flash.events.KeyboardEvent.KEY_DOWN, onShopKey) catch( e : Dynamic ) {}
		haxe.Timer.delay(function() if( !shopOpen && !menuOpen && !disposed ) actionKeys = true, 250);
	}

	function shopItems() : Array<{ b : Block, n : Int, price : Int }> {
		var out : Array<{ b : Block, n : Int, price : Int }> = [];
		if( shopTab == 0 ) {
			var total = new IntHash<Int>();
			var order = [];
			for( s in interf.inv.t ) {
				if( s == null ) continue;
				var b = Block.all[s.k];
				if( b.basePrice == null || b.basePrice <= 0 || b.charge != null ) continue;
				if( !total.exists(s.k) ) { total.set(s.k, 0); order.push(s.k); }
				total.set(s.k, total.get(s.k) + s.n);
			}
			for( k in order ) {
				var b = Block.all[k];
				var p = Std.int(b.basePrice * SELL_RATE);
				if( p < 1 ) p = 1;
				out.push({ b : b, n : total.get(k), price : p });
			}
		} else {
			for( k in BUY_LIST ) {
				var b = Block.get(k);
				out.push({ b : b, n : -1, price : b.basePrice == null ? 100 : b.basePrice });
			}
		}
		return out;
	}

	function shopRedraw() {
		var items = shopItems();
		if( shopSel >= items.length ) shopSel = items.length - 1;
		if( shopSel < 0 ) shopSel = 0;
		var lines = [];
		lines.push(getText("shop_title") + "      " + getText("shop_credits") + ": " + Main.credits);
		lines.push("");
		lines.push((shopTab == 0 ? "[ " : "  ") + getText("shop_sell") + (shopTab == 0 ? " ]" : "  ") + "     " + (shopTab == 1 ? "[ " : "  ") + getText("shop_buy") + (shopTab == 1 ? " ]" : "  "));
		lines.push("");
		if( items.length == 0 )
			lines.push("   " + getText("shop_none"));
		for( i in 0...items.length ) {
			var it = items[i];
			var qty = it.n >= 0 ? "x" + it.n : "";
			lines.push((i == shopSel ? " > " : "   ") + StringTools.rpad(it.b.getName(), " ", 26) + StringTools.rpad(qty, " ", 7) + it.price + " cr");
		}
		lines.push("");
		lines.push(getText(inPad.connected ? "shop_hint_pad" : "shop_hint"));
		if( shopMsg != null ) lines.push(shopMsg);
		shopTf.text = lines.join("\n");
		var g = shopMC.graphics;
		g.clear();
		g.beginFill(0x08121C, 0.92);
		g.lineStyle(2, 0x7DC9F7, 0.9);
		g.drawRoundRect(0, 0, shopTf.width + 36, shopTf.height + 36, 12, 12);
		g.endFill();
		var st = root.stage;
		shopMC.x = Std.int((st.stageWidth - shopMC.width) * 0.5);
		shopMC.y = Std.int((st.stageHeight - shopMC.height) * 0.5);
	}

	function onShopKey( e : flash.events.KeyboardEvent ) {
		if( !shopOpen ) return;
		switch( e.keyCode ) {
		case 38, 87: shopMove(-1);
		case 40, 83: shopMove(1);
		case 37, 65: shopTabMove(0);
		case 39, 68: shopTabMove(1);
		case 13, 69, 32: shopAct(e.shiftKey);
		case 27, 8: closeShop();
		}
	}

	public function shopMove( d : Int ) {
		shopSel += d;
		shopMsg = null;
		shopRedraw();
	}

	public function shopTabMove( tab : Int ) {
		if( shopTab == tab ) return;
		shopTab = tab;
		shopSel = 0;
		shopMsg = null;
		shopRedraw();
	}

	public function shopAct( many : Bool ) {
		var items = shopItems();
		var it = items[shopSel];
		if( it == null ) return;
		var qty = many ? 10 : 1;
		shopMsg = null;
		if( shopTab == 0 ) {
			if( qty > it.n ) qty = it.n;
			if( qty > 0 && interf.useBlocks(it.b, qty) ) {
				Main.credits += qty * it.price;
				Sfx.play(Sfx.LIB.pickupBlock, 0.4);
			}
		} else {
			var can = Std.int(Main.credits / it.price);
			if( qty > can ) qty = can;
			if( qty <= 0 )
				shopMsg = getText("shop_nocredits");
			else {
				var added = interf.addBlocks(it.b, qty);
				if( added <= 0 )
					shopMsg = getText("shop_full");
				else {
					Main.credits -= added * it.price;
					Sfx.play(Sfx.LIB.pickupBlock, 0.4);
				}
			}
		}
		shopRedraw();
	}
	
	/**
		Suelta lo grande del planeta (terreno, generador, buffers) y corta las referencias cruzadas.
		Aunque algo siga atando el objeto Game a una referencia estática, el terreno ya no se queda en memoria:
		sin esto cada viaje entre planetas dejaba ~150 MB sin liberar hasta agotar la memoria de Flash.
	*/
	function releaseMemory() {
		try {
			for( row in level.cells )
				for( c in row ) {
					c.t = null; c.tags = null; c.specials = null; c.light = null;
				}
			var e = level.extra;
			e.t = null; e.tags = null; e.specials = null; e.light = null;
		} catch( e : Dynamic ) {}
		try {
			agame.getEffects = null;
			agame.needRedraw = function() {};
			agame.loadChunk = function(x, y) {};
			agame.render = null;
			agame.level = null;
		} catch( e : Dynamic ) {}
		try {
			api.onSetBlock = null;
			api.onCancelInventory = null;
		} catch( e : Dynamic ) {}
		perlin = null;
		dummies = null;
		clones = null;
		realTime = null;
		select = null;
		process = null;
		interf = null;
		hero = null;
		ship = null;
		render = null;
		level = null;
		agame = null;
	}

	override public function dispose() {
		if( disposed ) return;
		if( !Std.is(this, EditShip) ) try Main.savedInv = interf.inv catch( e : Dynamic ) {}
		try setLookLock(false) catch( e : Dynamic ) {}
		try setSoftLook(false) catch( e : Dynamic ) {}
		try flash.ui.Mouse.show() catch( e : Dynamic ) {}
		try render.dispose() catch( e : Dynamic ) {}
		try api.dispose() catch( e : Dynamic ) {}
		try inPad.dispose() catch( e : Dynamic ) {}
		super.dispose();
		if( inst == this ) inst = null;
		releaseMemory();
	}

	override public function getJsApi():Dynamic {
		return {
			_controls : function(b:Bool) {
				setControls(b);
			},
			_exit : function() {
				//onCommand(SExitModule);
				api.send( CReturnGame );
			},
			_editShip : function() {
				if( lock )
					api.send(CEditShip);
			},
			_enterSpace : function() {
				if( lock )
					api.send(CEnterSpace);
			},
			_returnShip : function() {
				if( ship != null )
					ask('confirmKill', function(b) if( b ) returnToShip(true));
			},
		}
	}
	
	function setControls(b) {
		
		if ( b )
			controlType = MOUSE;
		else
			controlType = CLASSIC;
		
		if( controlType != MOUSE )
			interf.showDeadZone(null);
	}
	
	override function onChunk(x,y,bytes:haxe.io.Bytes) {
		if( disposed ) return;
		chunksReceived++;
		level.add(x, y, bytes.getData());
		process.onInitLevel(x, y);
		var size = 1 << (Const.BITS - r3d.Builder.CELL);
		var csize = 1 << r3d.Builder.CELL;
		var dx = x << Const.BITS;
		var dy = y << Const.BITS;
		for( x in -1...size + 1 )
			for( y in -1...size + 1 )
				render.builder.invalidate(real(dx + x * csize), real(dy + y * csize), 0);
		if( shipPending ) {
			for( cx in 0...infos.planet.size )
				for( cy in 0...infos.planet.size )
					if( level.cells[cx][cy].t == null )
						return;
			shipPending = false;
			placeShip();
		}
		if( interf == null )
			init();
		needRedraw = true;
		if( ship != null && ship.x >> Const.BITS == x && ship.y >> Const.BITS == y )
			ship.recalDock();
	}

	/** elige el punto de aterrizaje de la nave (fijo por planeta, según su semilla) y coloca al jugador dentro */
	function placeShip() {
		var key = infos.planet.seed + ":" + Type.enumIndex(infos.planet.biome) + ":" + infos.planet.size;
		var p : { x : Int, y : Int } = Main.shipSpots.get(key);
		if( p == null ) {
			p = level.getStartPlace(infos.planet, new mt.Rand(infos.planet.seed ^ 0x5A17));
			if( p != null ) Main.shipSpots.set(key, { x : p.x, y : p.y });
		}
		if( p != null )
			ship.moveTo(p.x, p.y);
		hero.gotoShip(true);
		Main.log("nave colocada en x=" + ship.x + " y=" + ship.y + (p == null ? " (sin punto válido, posición por defecto)" : ""));
	}

	function onResize() {
		var stage = flash.Lib.current.stage;
		var width = stage.stageWidth, height = stage.stageHeight;
		if( inventoryMode ) {
			var invHeight = 150;
			height += invHeight;
			flash.Lib.current.y = stage.stage3Ds[0].y = -invHeight;
		} else
			flash.Lib.current.y = stage.stage3Ds[0].y = 0;
		if( width <= 1 && height <= 1 )
			return;
		if( width != engine.width || height != engine.height )
			engine.resize(width, height);
		interf.resize(width,height);
		render.resize(width, height);
	}

	function setSoftLook( on : Bool ) {
		if( softLook == on ) return;
		softLook = on;
		drag = null;
		interf.setCross(false);
		lookDX = 0.; lookDY = 0.;
		softPX = root.stage.mouseX; softPY = root.stage.mouseY;
		if( on ) flash.ui.Mouse.hide(); else if( !lookLock ) flash.ui.Mouse.show();
	}

	function setLookLock( on : Bool ) {
		lookLock = on;
		lookDX = 0.;
		lookDY = 0.;
		try { untyped root.stage.mouseLock = on; } catch( e : Dynamic ) { lookLock = false; }
		if( lookLock ) flash.ui.Mouse.hide(); else flash.ui.Mouse.show();
	}

	function enterLockedFullScreen() {
		var st = root.stage;
		try {
			if( st.displayState == flash.display.StageDisplayState.NORMAL )
				untyped st.displayState = "fullScreenInteractive";
		} catch( e : Dynamic ) { setSoftLook(true); }
	}

	function toggleFullScreenLook() {
		var st = root.stage;
		try {
			if( st.displayState == flash.display.StageDisplayState.NORMAL )
				untyped st.displayState = "fullScreenInteractive";
			else
				st.displayState = flash.display.StageDisplayState.NORMAL;
		} catch( e : Dynamic ) { setLookLock(false); }
	}

	function mouseLock(b) {
		interf.lockButtons(b);
		if( b ) flash.ui.Mouse.hide(); else flash.ui.Mouse.show();
		//try root.stage.mouseLock = b catch( e : Dynamic ) {}
	}

	public function returnToShip(manual) {
		if( hero.lock || lock )
			return;
		hero.lock = true;
		fadeFX = { t:0., speed : 2., dz : manual ? -0.5 : 0.8, col : manual ? 0xFFFFFF : 0xFF0000, getAlpha:null, done : function() {
			if( api.isOffline() ) {
				hero.lock = false;
				hero.life = 100;
				hero.oxygen = 100;
				hero.gotoShip(true);
				fadeFX = null;
			} else {
				lock = true;
				hero.lock = false;
				hero.gravity = 0;
				tmodSave = mt.Timer.calc_tmod;
				api.send(CReturnShip(manual, hero.x, hero.y, hero.z));
			}
		}};
	}
	
	function click(up, event) {
		if( !lookLock ) {
			if( softLook ) { if( up ) drag = null; else drag = null; return; }
			if( !up ) { enterLockedFullScreen(); return; }
		}
		
		if( up ) {
			var old = drag;
			if( mouseControls() ) {
				if( interf.getCurrentBlock() != null )
					checkAction();
				checkToggle();
			}
			drag = null;
			if( select != null ) select.power = 0;
			interf.setCross(false);
			if( old != null && old.active )
				mouseLock(false);
			else if( mouseControls() && onAction != null )
				onAction();
		} else {
			drag = {
				x : Std.int(smoothMouse.x),
				y : Std.int(smoothMouse.y),
				dx : 0,
				dy : 0,
				az : 0.,
				active : false,
			};
		}
	}
	
	function checkToggle() {
		if( select != null && select.b != null && (laser.active || select.power > 0) ) {
			if( select.b.activable != null ) {
				var f = switch( select.b.activable ) {
				case WEverywhere: true;
				case WInShip: select.z >= Const.SHIP_Z;
				case WOnPlanet: select.z < Const.SHIP_Z;
				}
				if( f ) {
					if( ship != null && select.z >= Const.SHIP_Z )
						ship.activateBlock(select.x, select.y, select.z, select.b);
					else
						process.onActivate(select.x, select.y, select.z, select.b);
				}
				select.power = 0;
			} else if( select.b.toggle != null ) {
				process.toggle(real(select.x), real(select.y), select.z, select.b);
				select.power = 0;
			} else {
				select.power -= 0.01 * mt.Timer.tmod;
				if( select.power < 0 )
					select.power = 0;
			}
		}
	}
	
	function getMiningPower() {
		return hero.miningPower;
	}
	
	function checkAction() {
		
		if( lock || select == null || !actionKeys )
			return;

		if( api.isWaiting() ) {
			hero.actionPause = 0.1;
			return;
		}
		
		var s = select;
		var x = real(s.x), y = real(s.y), z = s.z;

		var block = handBlock();
		var put = block, get = s.b;
		if( put != null )
			put = put.getFlip(hero.angle);
		
		if( block == null ) {
			var power = select.powerFactor;
			laser.c = null;
			var matter = s.b.matter;
			var reqPower = s.b.requiredPower == null ? matter.requiredPower : s.b.requiredPower;
			if( reqPower == null ) reqPower = 1;
			
			if( s.requireCharge && matter.quickBreaks != null )
				for( c in matter.quickBreaks )
					if( interf.hasCharge(c.c) ) {
						power *= c.v;
						laser.c = c.c;
						break;
					}
			if( reqPower > 0 && (!matter.hasProp(PRequireCharge) || !s.requireCharge || laser.c != null) ) {
				laser.canBreak = select.allowBreak;
				if( hero.actionPause > 0 || !select.allowBreak ) {
					if( select.power == 0 ) select.power = 1e-8;
					return;
				}
				select.power += getMiningPower()*power / (reqPower * 40);
			} else
				laser.canBreak = false;
			hero.actionPause = 1;
			needRedraw = true;
			if( select.power < 1 )
				return;
		} else {
			var ok = false, tmp;
			if( !ok && (s.ignoreMagnets || block.canPut(Up)) && (tmp = level.get(x,y,z+1)) != null && tmp.hasMagnet(Down) )
				ok = true;
			if( !ok && (s.ignoreMagnets || block.canPut(Down)) && (tmp = level.get(x, y, z - 1)) != null && tmp.hasMagnet(Up) )
				ok = true;
			if( !ok && (s.ignoreMagnets || block.canPut(LeftRight)) ) {
				if( (tmp = level.get(x + 1, y, z)) != null && tmp.hasMagnet(LeftRight) )
					ok = true;
				else if( (tmp = level.get(x - 1, y, z)) != null && tmp.hasMagnet(LeftRight) )
					ok = true;
				else if( (tmp = level.get(x, y - 1, z)) != null && tmp.hasMagnet(LeftRight) )
					ok  = true;
				else if( (tmp = level.get(x, y + 1, z)) != null && tmp.hasMagnet(LeftRight) )
					ok  = true;
			}
			if( !ok || hero.actionPause > 0)
				return;
			hero.actionPause = 15;
			if( !interf.useCurrentBlock() )
				return;
			// our last block ? wait until release
			if( interf.getCurrentBlock() == null ) {
				laser.active = false;
				laser.wait = true;
			}
		}
		
		if( block == null ) {
			if( laser.c != null )
				interf.useCharge(laser.c);
			blockBreak(x, y, z, select.b);
		} else {
			var old = level.get(x, y, z);
			level.set(x, y, z, put);
			render.builder.updateKube(x, y, z, put);
			if( z >= Const.SHIP_Z ) {
				ship.craft(x, y, z, put);
			} else {
				api.putBlock(x, y, z, put.index, interf.blockIndex - 1);
				process.onSet(x, y, z, old, put);
			}
			needRedraw = true;
		}
		select = null;
	}
	
	public function blockBreak( x : Int, y : Int, z : Int, b:Block, isProcess = false ) {
		shake += 0.05*Math.random();
		var get = b.getDrop();
		if( get != null ) {
			var c = b.getMain().getDropChance();
			for( i in 0...get.count ) {
				if( Std.random(100) >= c )
					continue;
				var b = get.b;
				var d = new ent.Dummy(x + 0.5, y + 0.5, z + 0.5, b);
				Sfx.play(Sfx.LIB.destroyBlock, 0.25);
				d.get = function() {
					var index = interf.addBlock(b);
					if( index >= 0 ) {
						//interf.bump(index);
						api.getDummy(b.index, index);
						Sfx.play(Sfx.LIB.pickupBlock, 0.3);
						return false;
					}
					return true;
				};
				dummies.push(d);
			}
		}
		level.set(x, y, z, null);
		render.builder.updateKube(x, y, z, null);
		if( z >= Const.SHIP_Z )
			ship.craft(x, y, z, null);
		else {
			api.breakBlock(x, y, z, b.index, isProcess);
			process.onSet(x, y, z, b, null);
			if( ship != null && x == ship.x && y == ship.y )
				ship.recalDock();
		}
		if( get != null || !b.hasProp(PLiquid) )
			render.parts.doBreak(x, y, z, b);
		needRedraw = true;
	}

	public function getDefaultDummyTime() {
		return 180.;
	}
	
	public inline function real(p) {
		return agame.real(p);
	}

	public inline function realDist(p) {
		return agame.realDist(p);
	}
	
	function checkSelect() {
	}
	
	function moveHero() {
		
		// basic controls
		hero.recalAngleZ = false;
		var speed = 0.;
		var move = false, strafe = 0., turn = 0., zacc = 0.;
		if( Key.isDown(K.RIGHT) || Key.isDown("D".code) || Key.isDown(K.NUMPAD_6) ) {
			if( turnSpeed<0 ) turnSpeed = 0;
			if( drag != null && drag.active )
				strafe += 0.15;
			else
				turnSpeed += 0.008 * mt.Timer.tmod;
			move = true;
		}
		if( Key.isDown(K.LEFT) || Key.isDown("A".code) || Key.isDown("Q".code) || Key.isDown(K.NUMPAD_4) ) {
			if( turnSpeed>0 ) turnSpeed = 0;
			if( drag != null && drag.active )
				strafe -= 0.15;
			else
				turnSpeed -= 0.008 * mt.Timer.tmod;
			move = true;
		}
		
		if( !move ) turnSpeed *= Math.pow(0.6, mt.Timer.tmod);
		var max = 0.06;
		if( turnSpeed<-max ) turnSpeed = -max;
		if ( turnSpeed > max ) turnSpeed = max;
		
		turn = turnSpeed;
		hero.walking = false;
		hero.walkingSlow = Key.isDown("X".code);
		
		if( Key.isDown(K.UP) || Key.isDown("W".code) || Key.isDown("Z".code) || Key.isDown("X".code) || Key.isDown(K.NUMPAD_8) ) {
			speed += 0.15;
			move = true;
			hero.walking = true;
		} else
			hero.pushPower = 0.0;
		if( Key.isDown(K.DOWN) || Key.isDown("S".code) || Key.isDown(K.NUMPAD_2) ) {
			speed -= 0.15;
			move = true;
			hero.walking = true;
		}
		
		// mando (añadido): palanca izquierda = moverse, gatillo izquierdo = caminar despacio
		if( inPad.connected && (inPad.moveX != 0 || inPad.moveY != 0) ) {
			speed += 0.15 * inPad.moveY;
			strafe += 0.15 * inPad.moveX;
			move = true;
			hero.walking = true;
			hero.walkingSlow = hero.walkingSlow || inPad.slow;
		}

		if( speed != 0 && strafe != 0 ) {
			var diag = 1 / Math.sqrt(2);
			speed *= diag;
			strafe *= diag;
		}

		if( hero.swimming || hero.onWater() ) {
			speed *= 0.6;
			strafe *= 0.6;
			turn *= 0.6;
		}
		else if( hero.walkingSlow ) {
			speed *= 0.4;
			strafe *= 0.4;
			turn *= 0.4;
		}
	
		var useJetpack = actionKeys && (Key.isDown(K.SPACE) || Key.isDown(K.CONTROL) || inPad.jump);
		if( hero.cheating && !infos.debug )
			hero.cheating = false;
			
		var k = Math.ceil(mt.Timer.tmod * 10);
		var dt = mt.Timer.tmod / k;
		if( hero.gravity != 0 )
			move = true;
		// speedup
		if( hero.cheating && hero.z > 30 ) {
			speed *= hero.z / 30;
			strafe *= hero.z / 30;
		}
		if( hero.lock ) {
			speed = 0;
			strafe = 0;
			turnSpeed = 0;
			useJetpack = false;
		} else
			hero.angle += turn;
		for( i in 0...k ) {
			hero.doMove(dt, speed, strafe, useJetpack);
			for( d in dummies )
				if( !d.update(dt) )
					dummies.remove(d);
		}
			
		if( hero.updateAngleView() || hero.gravity != 0 )
			move = true;
			
		return move;
	}
	
	var inputSkip = false;
	
	public function dropCurrent() {
		if( interf.getCurrentBlock() == null ) return;
			var index = interf.blockIndex - 1;
			var drop = interf.drop(index);
			var block = Block.all[drop.k];
			var d = new ent.Dummy(hero.x, hero.y, hero.z + 1.2, block);

			d.vx = Math.cos(hero.angle) * 0.3;
			d.vy = Math.sin(hero.angle) * 0.3;
			d.x += Math.cos(hero.angle);
			d.y += Math.sin(hero.angle);
			d.active = false;
			d.canGet = function() {
				return d.id != null && interf.canAddBlock(block);
			};
			d.onActive = function() {
				if( d.id != null )
					api.send(CSetLootPos(d.id, d.x, d.y, d.z));
			};
			d.get = function() {
				var count = interf.addBlocks(block, drop.n);
				drop.n -= count;
				if( count > 0 ) {
					//interf.bump(index);
					Sfx.play(Sfx.LIB.pickupBlock, 0.3);
					api.send( CPickLoot(d.id, [ { k : Type.enumIndex(LKBlock), v : block.index, n : count } ]), function(ok)
					{
						if (!ok)
						{
							drop.n += count;
							dummies.remove( d ) ;
							dummies.add( d );
						}
					});
				}
				return drop.n > 0;
			};
			dummies.push(d);
			if( api.isOffline() )
				d.id = 0;
			api.send(CDrop(index,d.x,d.y,d.z),function(i) {
				d.id = i;
				if( d.active ) d.onActive();
			});
	}
	
	
	function checkKeys() {
		
		var actionKey = Key.isDown("E".code) || Key.isDown(K.SHIFT) || inPad.action ||((lookLock || softLook) && mouseHeld) || (controlType==MOUSE && interf.getCurrentBlock() == null && drag != null && !drag.active);
		if( hero.lock ) {
			if( actionKey && onAction != null ) onAction();
			return;
		}
		
		if ( Key.isToggled( "T".code ))
		{
			hero.lock = true;
			interf.debugLog.visible = true;
			interf.chatInput(function(msg) {
				hero.lock = false;
				interf.debugLog.visible = false;
				msg = StringTools.trim(msg);
				if( msg != "" && !~/^t+$/.match(msg) )
					api.send(CTalk(msg));
				inputSkip = true;
			});
			return;
		}
		
		if ( inputSkip )
		{
			inputSkip = false; return;
		}
		
		if( Key.isToggled("F".code) )
			showFPS.visible = !showFPS.visible;

		// depuración (añadido nuestro): F9 = despegar sin ir al ordenador
		if( infos.debug && Key.isToggled(K.F8) && ship != null )
			openShop(); // depuración: abre la tienda sin pasar por el ordenador
		if( infos.debug && Key.isToggled(K.F9) && ship != null ) {
			Main.log("F9: despegar");
			api.send(CEnterSpace);
		}

		// campo de visión (añadido): M / RePág / NumPad+ = más ancho, N / AvPág / NumPad- = más cerrado
		if( Key.isToggled("M".code) || Key.isToggled(K.PAGE_UP) || Key.isToggled(K.NUMPAD_ADD) ) render.changeFov(4);
		if( Key.isToggled("N".code) || Key.isToggled(K.PAGE_DOWN) || Key.isToggled(K.NUMPAD_SUBTRACT) ) render.changeFov(-4);
			
		if ( Key.isToggled(K.ESCAPE) )
		{
			setSoftLook(false);
			cnx.setFullScreen.call([false]);
			fullScreen = false;
			fullScreen = false;
		}
		else if ( Key.isToggled(K.F11) || Key.isToggled(K.ENTER) )
		{
			toggleFullScreenLook();
		}
		else if ( Key.isToggled(K.F12) && fullScreenInteractiveAllowed )
		{
			cnx.setFullScreen.call([null]);
			fullScreen = !fullScreen;
			if ( fullScreen)
			{
				oldControls =  controlType;
				controlType = MOUSE_LOCK;
			}
			else
			{
				controlType = oldControls;
				oldControls = null;
			}
		}
			
		
		// interactive keys
			
		if( Key.isToggled(K.TAB) )
			interf.select(0);
		
		var helmetKey = Key.isToggled("H".code) || padHelmet;
		padHelmet = false;
		if( helmetKey && !tw.exists(render.hud, "y") ) {
			var helmet = render.hud[H_HELMET];
			var yOn = -190 * helmet.scaleY;
			var yOff = -1024 * helmet.scaleY;
			if( hudOn ) {
				tw.create( helmet, "y", -210 * helmet.scaleY, TEaseOut, 100 ).onEnd = function() {
					haxe.Timer.delay(function() {
						tw.create( helmet, "y", -1024 * helmet.scaleY, TEaseIn, 700 ).onEnd = function() {
							helmet.visible = false;
						}
					}, 300);
				}
				hudOn = false;
			}
			else {
				helmet.visible = true;
				tw.create( helmet, "y", -250 * helmet.scaleY, TEaseIn, 500 ).onEnd = function() {
					haxe.Timer.delay(function() {
						tw.create( helmet, "y", -190 * helmet.scaleY, TEaseIn, 800 ).onEnd = function() {
							hudOn = true;
						}
					}, 100);
				}
			}
		}
		if( Key.isToggled(K.NUMPAD_MULTIPLY) ) {
			setControls(!mouseControls());
			cnx.setControls.call([mouseControls()]);
		}
		
		if( ((Key.isToggled("R".code) && !Key.isDown(K.CONTROL)) || Key.isToggled(K.DELETE)) && interf.getCurrentBlock() != null )
			dropCurrent();
		
		if( infos.debug ) {
			if( Key.isToggled("J".code) ) {
				hero.cheating = !hero.cheating;
				if( !hero.cheating ) hero.gravity = 0.1;
			}
			
			if( Key.isToggled("I".code) && Key.isDown(K.CONTROL) ) {
				var blocks = Type.allEnums(BlockKind);
				var count = 0;
				blocks.shift(); // empty
				function next(_) {
					haxe.Log.clear();
					var b = blocks.shift();
					if( b == null ) {
						haxe.Log.trace("DONE", null);
						return;
					}
					var b = Block.get(b);
					var bmp = render.renderBlock(b, 45);
					var png = format.png.Tools.build32BE(bmp.width, bmp.height, haxe.io.Bytes.ofData(bmp.getPixels(bmp.rect)));
					var bytes = new haxe.io.BytesOutput();
					new format.png.Writer(bytes).write(png);
					api.send(CBlockIcon(b.index, bytes.getBytes()), next);
					haxe.Log.trace(blocks.length + " blocks left", null);
				}
				next(null);
			}
		}
		
		if( Key.isToggled("K".code) && Key.isDown(K.SHIFT) && ship != null )
			returnToShip(true);
				
		for( i in 0...10 )
			if( Key.isToggled(K.NUMBER_0 + ((i + 1) % 10)) && infos.inventory.t.length >= i )
				interf.select(i);
				
		if( actionKey ) {
			if( onAction != null )
				onAction();
			if( !laser.wait )
				laser.active = true;
		} else {
			checkToggle();
			laser.active = false;
			laser.wait = false;
		}
	}
	
	function updateInterface() {
		if( hero.walking && hero.onGround() && !hero.lock ) {
			if( hero.inWater() )
				walkBobbing+=0.05
			else
				if( hero.walkingSlow )
					walkBobbing+=0.2;
				else
					walkBobbing+=0.2;
		}
		else
			walkBobbing = 0;
			
		if( !hero.onGround() )
			bobbingY = -hero.gravity*30;
		bobbingX += -turnSpeed*300;
		var max = 20;
		if( bobbingX<-max ) bobbingX = -max;
		if( bobbingX>max) bobbingX = max;
		var max = 15;
		if( bobbingY<-max ) bobbingY = -max;
		if( bobbingY>max) bobbingY = max;
		if( hudOn ) {
			var helmet = render.hud[H_HELMET];
			var hjet = render.hud[H_JETPACK];
			helmet.x = (-20 + bobbingX ) * helmet.scaleX;
			helmet.y = ( -190 + Math.cos(walkBobbing) * 2 + bobbingY) * helmet.scaleY;
			interf.warnMC.x = helmet.x + 100 * helmet.scaleX;
			interf.warnMC.y = helmet.y + 320 * helmet.scaleY;
			interf.statusMC.x = helmet.x + 100 * helmet.scaleX;
			interf.statusMC.y = helmet.y + 650 * helmet.scaleY - interf.statusMC.height;
			hjet.x = helmet.x;
			hjet.y = helmet.y;
		} else {
			interf.warnMC.x = Std.int(engine.width*0.5 - interf.warnText.textWidth*0.5);
			interf.warnMC.y = 50;
			//interf.warnMC.x = 5;
			//interf.warnMC.y = engine.height - (interf.warnText.height + 5);
		}
		interf.statusMC.alpha = Math.abs(Math.sin(time * 5));
		if( interf.warnAnim )
			interf.warnMC.alpha = Math.abs(Math.sin(time * 5));
		interf.update();
		bobbingX*=0.92;
		bobbingY *= 0.92;
	}
	
	function update() {
		if( disposed ) return;
		var old = mt.Timer.calc_tmod;
		mt.Timer.update();
		if( mt.Timer.deltaT > 0.25 )
			mt.Timer.calc_tmod = old;
		time += mt.Timer.deltaT;
		
		tw.update(mt.Timer.tmod);
		
		if( (drag==null || !drag.active) || controlType==MOUSE )
			smoothMouse = { x:root.mouseX, y:root.mouseY }
		else {
			var factor = 1 - Math.pow(0.65, mt.Timer.tmod);
			smoothMouse = {
				x : smoothMouse.x + ( root.mouseX-smoothMouse.x )*factor,
				y : smoothMouse.y + ( root.mouseY-smoothMouse.y )*factor,
			}
		}
		
		if( loadAnim != null ) {
			var v = loadAnim.progress + 0.1;
			if( v > 1 ) v--;
			loadAnim.progress = v;
			loadAnim.center();
		}
		
		if( lock )
			return;
			
		if( process.update(mt.Timer.deltaT) )
			needRedraw = true;

		inPad.update(mt.Timer.deltaT);
		if( padTf != null ) padTf.visible = showFPS.visible;
		if( padTf != null && padTf.visible ) padTf.text = inPad.debugText();
		var move = moveHero();
		if( actionKeys )
			checkKeys();
		hero.update(mt.Timer.tmod);
		
		if( showFPS.visible )
			needRedraw = true;

		// log periódico (cada ~5 s) para detectar reconstrucciones de chunks sin fin
		logTime += mt.Timer.deltaT;
		if( logTime > 5 ) {
			logTime = 0;
			Main.log("chunks reconstruidos=" + render.rebuiltCount + " chunks recibidos=" + chunksReceived);
		}

		if( fadeFX != null ) {
			fadeFX.t += mt.Timer.tmod * fadeFX.speed / 200;
			move = true;
			needRedraw = true;
			if( fadeFX.t > 1.0 || fadeFX.t < 0. ) {
				var done = fadeFX.done;
				fadeFX = null;
				done();
				return;
			}
		}

		if( softLook && !lookLock ) {
			// ratón "capturado" en ventana: movimiento relativo + empuje continuo en los bordes
			var st = root.stage;
			var w = st.stageWidth, h = st.stageHeight;
			var mx = Math.max(0, Math.min(w, st.mouseX));
			var my = Math.max(0, Math.min(h, st.mouseY));
			lookDX += mx - softPX;
			lookDY += my - softPY;
			softPX = mx; softPY = my;
			var mgx = w * 0.08, mgy = h * 0.08;
			var ex = 0., ey = 0.;
			if( mx < mgx ) ex = -(mgx - mx) / mgx; else if( mx > w - mgx ) ex = (mx - (w - mgx)) / mgx;
			if( my < mgy ) ey = -(mgy - my) / mgy; else if( my > h - mgy ) ey = (my - (h - mgy)) / mgy;
			if( mouseOut ) {
				if( mx <= 1 ) ex = -1; else if( mx >= w - 1 ) ex = 1;
				if( my <= 1 ) ey = -1; else if( my >= h - 1 ) ey = 1;
			}
			lookDX += ex * 14 * mt.Timer.tmod;
			lookDY += ey * 14 * mt.Timer.tmod;
		}

		if( (lookLock || softLook) && (lookDX != 0 || lookDY != 0) ) {
			hero.recalAngleZ = false;
			hero.angle += lookDX * hero.angleSpeed / (lookLock ? 260.0 : 130.0);
			hero.angleZ -= lookDY * hero.angleSpeed / (lookLock ? 360.0 : 180.0);
			var amaxL = Math.PI / 2.01;
			if( hero.angleZ < -amaxL ) hero.angleZ = -amaxL;
			else if( hero.angleZ > amaxL ) hero.angleZ = amaxL;
			lookDX = 0.;
			lookDY = 0.;
			move = true;
		}

		// mando (añadido): palanca derecha = mirar
		if( inPad.connected && (inPad.lookX != 0 || inPad.lookY != 0) && !hero.lock ) {
			hero.recalAngleZ = false;
			hero.angle += inPad.lookX * 0.054 * hero.angleSpeed * mt.Timer.tmod;
			hero.angleZ += inPad.lookY * 0.036 * hero.angleSpeed * mt.Timer.tmod;
			var amaxP = Math.PI / 2.01;
			if( hero.angleZ < -amaxP ) hero.angleZ = -amaxP;
			else if( hero.angleZ > amaxP ) hero.angleZ = amaxP;
			move = true;
		}

		if( drag != null && !lookLock && !softLook ) {
			var dx = Std.int(smoothMouse.x - drag.x);
			var dy = Std.int(smoothMouse.y - drag.y);
			if( !drag.active && !mouseControls() ) {
				//drag.active = Math.sqrt(dx*dx+dy*dy) > 18 || moveWalk;
				drag.active = true;
				if( drag.active ) {
					interf.setCross(true);
					mouseLock(true);
					drag.az = hero.angleZ;
				}
			}
			if( drag.active ) {
				if( !mouseControls() )
					flash.ui.Mouse.hide();
				hero.recalAngleZ = false;
				drag.x += dx;
				if( !hero.lock ) {
					bobbingX -= dx * 0.7;
					bobbingY -= (dy - drag.dy) * 0.3;
				}
				hero.angle += dx * hero.angleSpeed / 130.0;
				hero.angleZ = drag.az - dy * hero.angleSpeed / 180.0;
				var amax = Math.PI / 2.01;
				if( hero.angleZ < -amax )
					hero.angleZ = -amax;
				else if( hero.angleZ > amax )
					hero.angleZ = amax;
				if( dx != drag.dx || dy != drag.dy ) {
					move = true;
					drag.dx = dx;
					drag.dy = dy;
				}
			}
		}
		
		// Tremblements
		if( shake>0 ) {
			shake-=0.01*mt.Timer.tmod;
			if( shake>1.5 )
				shake = 1.5;
			if( shake<0 )
				shake = 0;
		}
		
		interf.updateShake(shake);
		interf.updateOxygen(hero.oxygen/100);
		interf.updateLife(hero.life/100);
		interf.updateJetpack(1-hero.jetpack);
		
		// save position
		var flags : haxe.EnumFlags<UserFlags>;
		flags = new haxe.EnumFlags<UserFlags>();
		if( hero.cheating ) flags.set(Flying);
		if( hero.invincible ) flags.set(Invincible);
		if( !(hero.lock || hero.swimming) && (hero.standingBlock != null || hero.cheating) )
			api.savePosition( { x : hero.x, y : hero.y, z : hero.z, a : hero.angle, az : hero.angleZ, life : hero.life, flags : flags, mouseCtrl:mouseControls() } );
			
		// point of view
		var px = agame.realFloat(hero.x - Math.cos(hero.angle) * 0.1);
		var py = agame.realFloat(hero.y - Math.sin(hero.angle) * 0.1);
		var pz = hero.z + hero.viewZ + Math.random()*0.4*shake*(Std.random(2)*2-1);
		if( planet.animWater != null ) {
			var anim = planet.animWater;
			if( hero.onWater() || hero.inWater() ) {
				var dz = Math.sin(px * anim.width + time * anim.speed) * Math.cos(py * anim.width + time * anim.speed) * anim.scale * 0.5;
				pz -= dz;
			}
			needRedraw = true;
		}
		
		var r = {viewAngle:0.};
		switch(controlType)
		{
			case MOUSE:
				var d = { };
				if( !lookLock && !softLook && !padAiming() ) inMouse.update();
			case CLASSIC:
				inClassic.update();
			case MOUSE_LOCK:
				if( !lookLock && !softLook ) inMouseLock.update();
		}
			
		updateInterface();
		
		if( ship != null )
			ship.update();
		
		var fov = 1.0;
		if( hero.inWater(true) )
			fov *= 0.8;
		render.setPos(px, py, pz + Math.sin(walkBobbing) * 0.05, hero.angle, hero.angleZ, fov);
		
		// update particles
		render.parts.update(mt.Timer.tmod);
		
		// update selection
		var prev = select;
		var mx, my;
		if( (drag != null && drag.active) || padAiming() ) {
			mx = root.stage.stageWidth>>1;
			my = root.stage.stageHeight>>1;
		} else {
			mx = Std.int(smoothMouse.x);
			my = Std.int(smoothMouse.y);
		}
		var handBlock = handBlock();
		select = render.pick(mx, my, handBlock, 7);
		if( hero.stun>0 || hero.lock )
			select = null;
		// prevent putting blocks under water if they can be erased by this water
		if( select != null && hero.inWaterBlock != null && select.b == null && (process.canPropagate(hero.inWaterBlock,handBlock) || handBlock.k == BFreezer) )
			select = null;
		if( select != null ) {
			var ix = Std.int(hero.x), iy = Std.int(hero.y), iz = Std.int(hero.z);
			if( select.x == ix && select.y == iy && (select.z == iz || select.z == iz + 1) )
				select = null;
			else if( select.z >= Const.ZSIZE-1 ) {
				if( ship == null || !ship.checkSelect() )
					select = null;
			}
			checkSelect();
		}
		if( (prev == null) != (select == null) || (select != null && (prev.x != select.x || prev.y != select.y || prev.z != select.z || prev.b != select.b)) )
			needRedraw = true;
		else if( select != null ) {
			// only update previous in order to keep all accumulators
			var s = select;
			select = prev;
			select.dir = s.dir;
			select.pt = s.pt;
		}

		// activate laser (only after selection updated)
		if( laser.active ) {
			checkAction();
			// generate parts
			if( select != null && select.b != null && (laser.canBreak || !select.allowBreak) ) {
				if( (select.b.activable != null || select.b.toggle != null) && select.power < 0.15 )
					laser.active = false;
				else if( (select.power > 0 && Std.random(2) == 0) || (select.power <= 0 && Std.random(6) == 0) )
					render.parts.doBreakParts(select.pt, select.dir, select.b,select);
			}
		}

		// laser sound
		if( laser.active && select != null ) {
			if( laserSound==null ) {
				Sfx.play(Sfx.LIB.lazerStart,0.3);
				laserSound = Sfx.play(Sfx.LIB.lazer, 0.25, 99999);
			}
		} else if( laserSound != null ) {
			laserSound.stop();
			laserSound = null;
		}
		
		// move other heroes
		if( realTime != null )
			for( e in realTime.entities )
			{
				e.update(mt.Timer.tmod);
				if ( e.select != null && e.select.laser != null && e.select.laser != -1)
				{
					var to = new h3d.Point(  e.select.x, e.select.y, e.select.z);
					var from = new h3d.Point( e.x, e.y, e.z);
							
					render.parts.doBreakParts(to, to.sub(from).toVector(), Block.get( Type.createEnumIndex(BlockKind, e.select.btype)), select);
				}
			}
			
		for( c in clones )
			c.update(mt.Timer.tmod);
		
		// redraw
		if( move || needRedraw ) {
			needRedraw = false;
			if( engine.begin() ) {
				render.render();
				engine.end();
			}
		}
		
		if( showFPS.visible )  {
			var a = hero.angle % (Math.PI * 2);
			if( a < 0 ) a += Math.PI * 2;
			var stats = engine.mem.stats();
			var infos = [
				engine.drawCalls + " draws",
				render.rebuiltCount+" chunks built (avg "+(Std.int(render.rebuiltTime*100/render.rebuiltCount)/100)+"ms)",
				"x=" + (Std.int(hero.x * 10) / 10) + " y=" + (Std.int(hero.y * 10) / 10) + " z=" + (Std.int(hero.z * 10) / 10) + " a=" + Std.int(a * 180 / Math.PI) + "°",
				stats.bufferCount+" buffers "+(stats.totalMemory>>20)+" MB ("+(Std.int(stats.freeMemory*1000.0/stats.totalMemory)/10)+"% free)",
			];
			if( select != null && select.b != null && this.infos.debug )
				infos.push(select.b.getName());
			showFPS.text = engine.driverName()+" "+Std.int(engine.drawTriangles/1000) + ".KTri @" + (Std.int(mt.Timer.fps()*10)/10) + " fps\n"+infos.join("\n");
		}
		
		var stats = {
			fps : Std.int(mt.Timer.fps() * 10) / 10,
			chunkTime : Std.int(render.rebuiltTime * 100 / render.rebuiltCount) / 100,
			soft : !engine.hardware,
			multi : realTime != null && realTime.isConnected(),
		};
		api.setStats(stats);
		
		if( realTime != null )
			realTime.sync(getNetState());
	}
	
	function getNetState() : net.RealTime.State {
		return {
			x : hero.x,
			y : hero.y,
			z : hero.z,
			g : hero.gravity,
			a : hero.angle,
			az : hero.angleZ,
			select : select == null ? null
			: { x : select.pt.x,
				y : select.pt.y,
				z : select.pt.z,
				laser : laser.active ? (laser.c == null ? -1 : Type.enumIndex(laser.c)) : null,
				bx: select.x,
				by: select.y,
				bz: select.z,
				btype: (select.b == null) ? 0 : select.b.index,
			},
		};
	}

	override function onCommand(c) {
		switch( c ) {
		case SReduceWater:
			var total = 0;
			for( cx in 0...infos.planet.size )
				for( cy in 0...infos.planet.size ) {
					var c = level.cells[cx][cy];
					if( c.t == null ) continue;
					c.tags = null;
					var z = planet.waterLevel;
					var bwater = Type.enumIndex(planet.biome.water);
					flash.Memory.select(c.t);
					for( x in 0...Const.SIZE )
						for( y in 0...Const.SIZE ) {
							var addr = Const.addr(x, y, z) << 1;
							if( flash.Memory.getUI16(addr) == bwater )
								flash.Memory.setI16(addr, 0);
							for( z in 0...z-1 )
								if( flash.Memory.getUI16(Const.addr(x, y, z) << 1) == bwater )
									total++;
						}
				}
			for( c in render.builder.level.cells )
				c.dirty = true;
			planet.waterLevel--;
//			trace("REDUCED " + planet.waterLevel + " (TOT=" + total + ")");
		case SExitModule:
			super.onCommand(c);
			lock = false;
			if( !Math.isNaN(tmodSave) )
				mt.Timer.calc_tmod = tmodSave;
			fadeFX = null;
			hero.enteringShip = -1;
			api.forcePosSave();
		case SSetInventory(inv):
			interf.inv = inv;
			interf.display();
		case SSetPos(p):
			hero.x = p.x;
			hero.y = p.y;
			hero.z = p.z;
			hero.angle = p.a;
			hero.angleZ = p.az;
			hero.life = p.life;
		case SChanges(cx, cy, data):
			var p = 0;
			while( p < data.length ) {
				var x = data.get(p++) + (cx << Const.BITS);
				var y = data.get(p++) + (cy << Const.BITS);
				var z = data.get(p++);
				var bid = data.get(p++) | (data.get(p++) << 8);
				var b =  bid == 0 ? null : Block.all[bid];
				level.set(x, y, z, b);
				render.builder.updateKube(x, y, z, b);
			}
		case SGotoShip:
			lock = false;
			hero.gotoShip();
			
		case SDeleteLoot( id ):
			var nb = mt.gx.ListEx.removeAll(dummies, function(d) return d.id == id );
			Log.debug("loot #" + id + " removed "+nb);
			
		case SAddLoot(id, loot):
			for( d in dummies )
				if( d.id == id ) {
					dummies.remove(d);
					break;
				}
			var ct = [];
			var lkind = Type.allEnums(LootKind);
			var d = new ent.Dummy(loot.x, loot.y, loot.z, Block.all[loot.k]);
			
			Log.debug("[SRV] added loot #" + id );
			
			d.id = id;
			d.time = loot.time * 30.;
			d.canGet = function() {
				for( c in loot.content )
					switch( lkind[c.k] ) {
					case LKBlock:
						if( interf.canAddBlock(Block.all[c.v]) )
							return true;
					case LKCharge:
						if( interf.canCharge(Type.createEnumIndex(ChargeKind, c.v)) )
							return true;
					}
				return false;
			};
			d.get = function() {
				var p = [];
				for( c in loot.content.copy() ) {
					var n = switch( lkind[c.k] ) {
					case LKBlock: interf.addBlocks(Block.all[c.v], c.n);
					case LKCharge: interf.addCharge(Type.createEnumIndex(ChargeKind, c.v), c.n);
					}
					if( n > 0 ) {
						p.push( { k : c.k, v : c.v, n : n } );
						c.n -= n;
						if( c.n == 0 ) loot.content.remove(c);
					}
				}
				if( p.length > 0 )
					api.send(CPickLoot(id, p), function(ok)
					{
						if (!ok)
						{
							for ( v in p )
								loot.content.push( v );
							dummies.remove( d ) ;
							dummies.add( d );
						}
					});
				return loot.content.length > 0;
			};
			dummies.push(d);
		case SUserJoin(uid, name):
			userMap.set(uid, name);
			Log.add(name + "#" + uid + " joined");
			interf.addChatEntry(getText("user_join", { _name : name }), true, 0x808080 );
			
		case SUserLeave(uid):
			var name = userMap.get(uid);
			if( name == null ) name = "???";
			userMap.remove(uid);
			Log.add(name + "#" + uid + " left");
			interf.addChatEntry(getText("user_leave", { _name : name } ), true, 0x808080 );
			
		case SConnect(url):
			if( interf == null ) {
				haxe.Timer.delay(onCommand.bind(c), 500);
				return;
			}
			if( realTime == null ) {
				var me = new ent.OnlineHero(this, { id : null, uid : infos.userId, name : infos.userName, camera : infos.lastPos != null && infos.lastPos.flags.has(CameraMode) }, getNetState());
				realTime = new net.RealTime(url, infos.planet.id, me, function(i,s) return new ent.OnlineHero(this,i,s));
			}

		case STalk( uid, msg ):
			var u = userMap.get( uid );
			var l = u + " > " + msg;
			
			interf.addChatEntry( l );
		default:
			super.onCommand(c);
		}
	}
	
	static var inst : Game;

}
