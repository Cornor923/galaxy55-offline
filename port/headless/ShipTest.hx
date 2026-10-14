import Common;

/** Prueba de la nave por defecto: la descomprime y cuenta sus bloques. */
class ShipTest {
	static function main() {
		var data : haxe.io.Bytes = Const.DEFAULT_SHIP;
		Sys.println("comprimida: " + data.length + " bytes");
		var raw = haxe.zip.Uncompress.run(data);
		var sx = raw.get(0), sy = raw.get(1), sz = raw.get(2);
		Sys.println("tamano: " + sx + " x " + sy + " x " + sz + "  bytes: " + raw.length + " (esperado " + (3 + sx * sy * sz * 2) + ")");
		var counts = new Map<Int, Int>();
		var pos = 3;
		var entry = null;
		for( y in 0...sy )
			for( x in 0...sx )
				for( z in 0...sz ) {
					var bid = raw.get(pos) | (raw.get(pos + 1) << 8);
					pos += 2;
					if( bid == 0 ) continue;
					counts.set(bid, (counts.exists(bid) ? counts.get(bid) : 0) + 1);
					if( bid == Type.enumIndex(BShipEntry) ) entry = x + "," + y + "," + z;
				}
		var out = [];
		for( k in counts.keys() ) out.push(Block.all[k].k + "=" + counts.get(k));
		Sys.println(out.join("  "));
		Sys.println("teletransportador (BShipEntry) en: " + entry);
	}
}
