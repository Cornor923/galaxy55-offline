import Common;

/**
 * Cambios del port a las reglas de los bloques del original (src/G55/com/Block.hx no se toca).
 * Se aplican una vez al arrancar.
 */
@:access(Block)
class PortRules {

	/**
	 * Hierbas de decoracion y estalactitas de hielo: en el original llevan BFDetail y no se pueden apuntar ni romper.
	 * Aqui se rompen y, siguiendo la logica del juego, dan su "materia" con una probabilidad:
	 * - hierbas -> hierba alta (BHighHerb1) un 33 %, como las plantas recogibles (BAcidHerb*: matter BHighHerb1, BFDropChance(33));
	 * - estalactitas de hielo -> hielo (BIce) un 7 %, como el hielo negro (BBlackIce: matter BIce, BFDropChance(7));
	 * - restos de las plantas de cargas -> nada (para no sacar cargas sin fin).
	 * Siguen sin chocar y conservan BFDetail (se dibujan igual): solo cambia que se pueden apuntar (PCanPick) y lo que dan.
	 */
	static var BREAKABLE : Array<{ k : BlockKind, drop : BlockKind, chance : Int }> = [
		{ k : BAutumnHerbs1, drop : BHighHerb1, chance : 33 },
		{ k : BAutumnHerbs2, drop : BHighHerb1, chance : 33 },
		{ k : BTreeHerbs, drop : BHighHerb1, chance : 33 },
		{ k : BMoonHerbs1, drop : BHighHerb1, chance : 33 },
		{ k : BMoonHerbs2, drop : BHighHerb1, chance : 33 },
		{ k : BWinterHerb1, drop : BHighHerb1, chance : 33 },
		{ k : BWinterHerb2, drop : BHighHerb1, chance : 33 },
		{ k : BWinterHerb3, drop : BHighHerb1, chance : 33 },
		{ k : BMarsHerb1, drop : BHighHerb1, chance : 33 },
		{ k : BMarsHerb2, drop : BHighHerb1, chance : 33 },
		{ k : BMarsHerb3, drop : BHighHerb1, chance : 33 },
		{ k : BIceStalactite1, drop : BIce, chance : 7 },
		{ k : BIceStalactite2, drop : BIce, chance : 7 },
		{ k : BBonusHerb1, drop : null, chance : 0 },
		{ k : BBonusHerb2, drop : null, chance : 0 },
		{ k : BBonusMediumRemain, drop : null, chance : 0 },
	];

	static var done = false;

	public static function apply() {
		if( done ) return;
		done = true;
		// el monticulo de nieve con una planta escondida (BWinterHidden) brillaba con luz propia y sombreado 1.5-2.0: con su
		// textura casi blanca saturaba a blanco puro. Se dibuja como la nieve normal (BWinterSoilCover) y sin luz propia.
		var hidden = Block.get(BWinterHidden), snow = Block.get(BWinterSoilCover);
		hidden.shadeX = snow.shadeX;
		hidden.shadeY = snow.shadeY;
		hidden.shadeUp = snow.shadeUp;
		hidden.shadeDown = snow.shadeDown;
		hidden.special = null;
		for( r in BREAKABLE ) {
			var b = Block.get(r.k);
			b.props.set(PCanPick);
			if( r.drop == null ) {
				b.drop = null;
			} else {
				b.drop = Block.get(r.drop);
				b.dropCount = 1;
				b.flags.push(BFDropChance(r.chance));
			}
		}
	}
}
