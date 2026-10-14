import Common;

typedef ShipCell = { var x : Int; var y : Int; var z : Int; var id : Int; }

typedef ShipDataInfo = {
	/** tamano de la nave en bloques */
	var sx : Int;
	var sy : Int;
	var sz : Int;
	/** bloques ya colocados dentro del volumen de 128x128x128 de la nave (centrados, 1 de margen abajo), como ShipLogic.init */
	var cells : Array<ShipCell>;
	/** celda del teletransportador (BShipEntry) en ese volumen; el jugador aparece encima */
	var entry : { x : Int, y : Int, z : Int };
}

/** Datos de una nave: bytes comprimidos con zlib = sx, sy, sz y, por cada y, x, z, el indice del bloque en 2 bytes. */
class ShipData {

	public static function load( compressed : haxe.io.Bytes ) : ShipDataInfo {
		var raw = haxe.zip.Uncompress.run(compressed);
		var sx = raw.get(0), sy = raw.get(1), sz = raw.get(2);
		var dx = (Const.SIZE - sx) >> 1, dy = (Const.SIZE - sy) >> 1, dz = 1;
		var cells = [];
		var entry = null;
		var pos = 3;
		for( y in 0...sy )
			for( x in 0...sx )
				for( z in 0...sz ) {
					var bid = raw.get(pos) | (raw.get(pos + 1) << 8);
					pos += 2;
					if( bid == 0 ) continue;
					var c = { x : x + dx, y : y + dy, z : z + dz, id : bid };
					cells.push(c);
					if( bid == Type.enumIndex(BShipEntry) ) entry = { x : c.x, y : c.y, z : c.z };
				}
		return { sx : sx, sy : sy, sz : sz, cells : cells, entry : entry };
	}
}
