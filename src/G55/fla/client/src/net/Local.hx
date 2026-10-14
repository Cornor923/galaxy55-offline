package net;

import Common;
import Protocol;

class Local extends Offline {
	
	var saving : Bool;
	var waterId : Int;
	var floodFlag : Bool;
	var lastReduce : Float = 0.;
	var diffPrefix : String;
	
	public function new(planet) {
		super(planet);
		
		waterId = Type.enumIndex(Data.getBiome(planet.biome).water);
		
		// cambios guardados por planeta (antes solo cabía uno: al entrar a otro planeta se borraban los del anterior)
		diffPrefix = "d" + haxe.Md5.encode(Type.enumIndex(planet.biome)+":"+planet.seed+":"+planet.size).substr(0, 12) + "_";
		for( x in 0...planet.size ) {
			for( y in 0...planet.size ) {
				var diff : flash.utils.ByteArray = null;
				if( save != null )
					diff = Reflect.field(save.data, diffPrefix + x + "_" + y);
				if( diff != null )
					chunks[x][y].diff = diff;
			}
		}
	}
	
	override function preventSave() {
		return false;
	}

	override function processBlock(x, y, z, bid, old) {
		super.processBlock(x, y, z, bid, old);
		if( bid == waterId ) {
			planet.waterFlood++;
			// protecciones (añadido nuestro): sin ellas, un planeta con poca agua o una capa sin agua cumplía la condición
			// en cada bloque de agua y reconstruía TODOS los chunks varias veces por segundo (miles de chunks por minuto)
			if( !closed && !floodFlag && planet.waterLevel > 1 && planet.waterTotal > 0
				&& haxe.Timer.stamp() - lastReduce > 10
				&& planet.waterFlood >= planet.waterTotal / planet.waterLevel ) {
				floodFlag = true;
				haxe.Timer.delay(reduceWater, 1);
			}
		}
	}
	
	function reduceWater() {
		if( closed || chunks == null ) return;
		lastReduce = haxe.Timer.stamp();
		var w = 0;
		var twater = Type.enumIndex(BWater);
		for( x in 0...planet.size )
			for( y in 0...planet.size ) {
				var t = chunks[x][y].t;
				flash.Memory.select(t.getData());
				var z = planet.waterLevel;
				for( x in 0...Const.SIZE )
					for( y in 0...Const.SIZE ) {
						var addr = Const.addr(x, y, z) << 1;
						if( flash.Memory.getUI16(addr) == twater )
							w++;
					}
			}
		planet.waterLevel--;
		planet.waterFlood = w == 0 ? 0 : planet.waterFlood - w; // si la capa no tenía agua el contador no bajaba y volvía a disparar
		if( planet.waterFlood < 0 ) planet.waterFlood = 0;
		Main.log("reduceWater: nivel del mar=" + planet.waterLevel + " agua contada=" + w + " flood=" + planet.waterFlood + " total=" + planet.waterTotal);
//		trace("REDUCE " + planet.waterLevel+ "("+w+")");
		floodFlag = false;
		onCommand(SReduceWater);
	}
	
	override function setBlock(x, y, z, bid) {
		super.setBlock(x, y, z, bid);
		if( !saving ) {
			saving = true;
			haxe.Timer.delay(doSaveChunks, 1);
		}
	}
	
	function doSaveChunks() {
		saving = false;
		for( x in 0...planet.size )
			for( y in 0...planet.size ) {
				var c = chunks[x][y];
				if( !c.dirty ) continue;
				c.dirty = false;
				save.setProperty(diffPrefix + x + "_" + y, c.diff);
			}
		flush();
	}
	
	override function clearLocalChanges() {
		for( x in 0...planet.size )
			for( y in 0...planet.size ) {
				var c = chunks[x][y];
				if( c.diff.length == 0 ) continue;
				c.diff = new flash.utils.ByteArray();
				c.dirty = true;
				requestChunk(x, y);
			}
		doSaveChunks();
	}
	
	override public function dispose() {
		// guarda lo pendiente antes de soltar el terreno
		try doSaveChunks() catch( e : Dynamic ) {}
		super.dispose();
	}

	override function getKey() {
		// una posicion guardada por planeta (antes todos compartian "#null")
		return "#L" + planet.seed + ":" + Type.enumIndex(planet.biome) + ":" + planet.size;
	}
	
	public override function send( act : ClientAction, ?onResult : Dynamic -> Void ) {
		switch( act ) {
		case CEnterSpace:
			Main.goExplore();
			return;
		case CEditShip:
			Main.goEdit();
			return;
		case CTalk( msg ):
			// comandos de depuración (añadido nuestro), se escriben en el chat con la tecla T
			switch( StringTools.trim(msg).toLowerCase() ) {
			case "/despegar", "/takeoff":
				Main.log("comando de chat: " + msg);
				Main.goExplore();
				return;
			case "/hangar":
				Main.log("comando de chat: " + msg);
				Main.goEdit();
				return;
			default:
			}
			haxe.Timer.delay( function() onData( STalk( 0, msg) ), 100);
		case CGetProperties(x, y, z):
			haxe.Timer.delay(function() {
				var p : BlockProperties = {
					id : -1,
					max : 64,
					content : [ { k : Block.get(BLamp).index, n : 60 }, null, null, null],
				};
				onData( SResult(p) );
			},1000);
		default:
		}
		super.send( act, onResult);
	}
}
