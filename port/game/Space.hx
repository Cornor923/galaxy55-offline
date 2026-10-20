import SaveData.UniInfo;
import ExpData;

/**
 * Viaje espacial: lo que pasa mientras la partida esta en el espacio (despegue, viaje por el mapa, sistemas, aterrizaje,
 * robot comerciante). Es la base del port para las ideas del viaje espacial de IDEAS.md: combustible, desbloquear sistemas,
 * misiones o puntos fijos, robot que se aleja, planetas lejanos mas ricos. En el cliente original no habia nada de esto.
 *
 * Por ahora no cambia el juego: solo lleva la cuenta de lo recorrido. Lo que haya que guardar va en UniInfo (SaveData), en
 * campos opcionales, para que las partidas antiguas sigan cargando. GalaxyApp crea uno cada vez que se abre el mapa.
 */
class Space {

	public var uni(default, null) : UniInfo;

	public function new( uni : UniInfo ) {
		this.uni = uni;
		if( uni.traveled == null ) uni.traveled = 0;
	}

	/** al despegar, con el planeta ya descargado (no al abrir el mapa desde una partida guardada en el espacio) */
	public function takeoff() {}

	/** la nave ha avanzado `dist` en el mapa (en el sector, o dentro de un sistema si `inSystem`): aqui iria el gasto de combustible */
	public function travel( dist : Float, inSystem : Bool ) {
		uni.traveled += dist;
	}

	/** la nave ha entrado en un sistema o ha salido al sector: [0, x, y] o [1, sistema], como UniInfo.pos */
	public function moved( pos : Array<Int> ) {}

	/** antes de aterrizar en un planeta (al pulsar Aterrizar o Escanear): false = no se puede */
	public function canLand( p : ExpPlanet ) : Bool {
		return true;
	}

	/** al aterrizar, antes de cargar el planeta */
	public function land( p : ExpPlanet ) {}

	/** boton del candado de un sistema cerrado (en el original se abria pagando la licencia): aun no hace nada */
	public function unlock( s : ExpSystem ) {}

	/** al acoplarse al robot comerciante, antes de entrar en su nave */
	public function dock() {}
}
