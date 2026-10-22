import Common;

/** Prueba del guardado: escribe una partida con inventario y cambios de terreno y la vuelve a leer. */
class SaveTest {
	static function main() {
		// creativo: empieza con el inventario inicial del original (en aventura estaria vacio)
		var info = SaveData.create("Prueba guardado", 42, "BIMoon", 2, true);
		info.inv.t[0].n = 7;
		info.inv.t[9] = { k : Type.enumIndex(BWood), n : 3 };
		info.inv.charges[1].n = 12;
		info.edits = [12345, 0, 67890, Type.enumIndex(BLamp)];
		var ok = SaveData.write(info, null);
		var back = SaveData.read(info.id);
		Sys.println("escrito: " + ok);
		Sys.println("nombre: " + back.name + " semilla: " + back.seed + " bioma: " + back.biome + " tamano: " + back.sizeChunks);
		Sys.println("inventario[0]=" + back.inv.t[0].k + "x" + back.inv.t[0].n + " (esperado " + Type.enumIndex(BLamp) + "x7)");
		Sys.println("inventario[9]=" + back.inv.t[9].k + "x" + back.inv.t[9].n + " (esperado " + Type.enumIndex(BWood) + "x3)");
		Sys.println("cargas[1]=" + back.inv.charges[1].c + "x" + back.inv.charges[1].n + " (esperado 1x12)");
		Sys.println("ediciones=" + back.edits.join(",") + " (esperado 12345,0,67890," + Type.enumIndex(BLamp) + ")");
		SaveData.delete(info.id);
	}
}
