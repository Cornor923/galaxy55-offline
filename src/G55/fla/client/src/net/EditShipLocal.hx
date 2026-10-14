package net;

import Common;
import Protocol;

/** Hangar en local: sin servidor. Guardar/salir devuelve al juego (planeta) y conserva la nave en memoria. */
class EditShipLocal extends EditShip {

	public function new( inf : EditShipInfos ) {
		super(null, inf);
	}

	override public function isOffline() {
		return false;
	}

	override function saveShip() {
		// el original lo volcaba a un campo HTML (solo depuracion)
	}

	override function send( a : ClientAction, ?onResult : Dynamic -> Void ) {
		switch( a ) {
		case CSaveShip(_, _):
			Main.onShipSaved(getShipData(), null);
			Main.goGame();
			return;
		case CReturnGame:
			Main.goGame();
			return;
		default:
		}
		super.send(a, onResult);
	}

}
