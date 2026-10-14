# Novedades

## Versión 0.2 — 14 de octubre de 2026

Primera versión con el código **completo y compilable** en el repositorio (antes solo había parches), y
con mucho trabajo de jugabilidad. Los tres `.swf` (es / en / fr) se generan con `build.bat` y salen
idénticos a los de `release/`.

### Cambios que ves al jugar

**Viajar entre planetas (antes se rompía enseguida)**
- Ya se puede ir y volver entre planetas sin cerrar el juego. Antes aparecían `Error #1000 out of memory` y
  `Error #3691` a los pocos viajes, y los bloques parpadeaban.
- Los planetas aparecen **sin explorar**: hay que **escanearlos** y el mapa muestra un contador naranja con los
  planetas libres de cada sistema (como en el tráiler de 2012). El escaneo ya no tarda medio minuto.
- Apareces **dentro de tu nave**, y la nave aterriza en **un punto fijo por planeta** (distinto en cada uno).
- Al despegar, el mapa estelar empieza junto al planeta del que sales y dibuja tu nave editada.
- Los cambios del terreno se guardan **por planeta** mientras el juego está abierto (antes se borraban al cambiar).
- Tamaños de planeta pequeño / normal / grande (128 / 256 / 384).

**Mando** (tipo Xbox, calibrado con un mando real): moverse, mirar, romper (RT), colocar (LT), jetpack, inventario,
casco, campo de visión, cursor en el mapa estelar y menús.

**Sonido** activado (el código publicado lo traía apagado).

**Tienda ESCorp local** (añadido nuestro): vender lo que llevas y comprar piezas de nave con créditos.
**Ordenador de a bordo** con cuatro opciones: despegar, modificar la nave, comerciar, detener.

**Hangar** de 17×17×14 (antes 17×17×12), según la Twinpedia.

**Agua:** el agua de los lagos y la cascada tienen transparencia; la cascada se degrada según baja.

**Otros:** poner/quitar el casco (H o Select), teclas de depuración F9/F8 y comandos de chat `/despegar` y `/hangar`.

### Arreglos del port
- Fugas de memoria y de recursos de la tarjeta gráfica al cambiar de planeta.
- Las teclas de una sola pulsación (F, H, T, TAB, R, 1–9...) casi nunca se detectaban.
- Los parches de textura se reaplicaban en cada planeta y degradaban el agua y el cristal.
- Posible bucle de reconstrucción de chunks por el nivel del mar (blindado; **no confirmado** como causa).
- Acentos rotos en los nombres de bloques al compilar en Windows.

### Para quien programa
- `src/`, `libs/` (con Heaps y `format` de 2012 y sus licencias), `stubs/`, `tools/`, `data/`.
- Registro de depuración opcional en `flashlog.txt` (ver README), con memoria y cambios de pantalla.

## Versión 0.1 — 13 de octubre de 2026
Primera subida: parches contra el código de Motion Twin, modo local, mapa estelar, nombres oficiales es/en.
