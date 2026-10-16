## Galaxy 55 (offline) v0.2 — port nativo para Windows

Port **no oficial** de Galaxy 55 (Motion Twin, 2012) a una aplicación nativa para Windows (Haxe + Heaps + HashLink). Sin Flash, sin navegador y sin servidor.

**Cómo jugar:** descomprime la carpeta entera y haz doble clic en `jugar.bat`. No hay que instalar nada. Comprueba que la carpeta `res/` queda junto a `galaxy55.hl`. Las partidas se guardan en `%APPDATA%\Galaxy55\`.

### Novedades de la v0.2
- **Mapa de estrellas con las animaciones del original:** entrar y salir de un sistema (zoom, hiperespacio, destellos), fondo común con remolino. Ya no se congela al entrar en un sistema.
- **El bloque elegido se ve en la mano**, y al romper un bloque saltan **partículas** como en el original.
- **Ciudad muerta** se puede elegir en Nueva partida.
- Arreglado: borrar partidas desde el menú, quitar la fuente de cascada en la nave, el giro de los bloques sueltos, la nieve dentro de la nave.
- Cambios respecto al original: el sintetizador gasta siempre los bloques de su zona; las hierbas y estalactitas se rompen (dan hierba alta o hielo); la curvatura del planeta es más suave; los montículos de nieve con planta escondida se ven como la nieve; al entrar en un planeta la cámara se acerca a él.

### Qué falta o falla
- Tienda, hangar, agua que fluye, sonido, vida/oxígeno/lava; reactores y flechas del mapa.
- Lista completa de errores conocidos: `ERRORES.md` (español) / `BUGS.md` (inglés) en el repositorio.
- **El formato de las partidas puede cambiar entre versiones.**

---

**English:** unofficial native Windows port of Motion Twin's Galaxy 55 (2012). Unzip the whole folder and run `jugar.bat` (the `res/` folder must sit next to `galaxy55.hl`). New in v0.2: the original star-map animations, the held block in the hand, break particles, Dead city selectable, and several fixes. Known bugs: `BUGS.md`.

### Licencia / License
Código y datos de Galaxy 55 © Motion Twin, **CC BY-NC-SA 4.0**. Este port es una obra derivada bajo la misma licencia: uso no comercial y con crédito. Ver `LICENSE` y `NOTICE`.
