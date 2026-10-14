# Galaxy 55 — versión offline recompilada

Galaxy 55 fue un juego web de Flash (alpha, 2012) de **Motion Twin**: exploración espacial, planetas
generados al azar y un sistema de bloques ("kubes") y crafteo en 3D. Se cerró y su servidor ya no existe.

Este proyecto recompila el cliente 3D a partir del código fuente que Motion Twin publicó en
[motion-twin/WebGamesArchives](https://github.com/motion-twin/WebGamesArchives) para que funcione
**sin servidor**, en modo local, y le añade cosas para poder jugarlo hoy (mando, sonido, tienda...).

> **Estado:** se juega. Probado por una persona en Windows con Flash Player 32: mapa estelar, aterrizar en
> planetas, minar y construir, ordenador de a bordo, hangar, viajar entre planetas y tienda.
> **No hay** cuentas, licencias ni multijugador (dependían del servidor de Motion Twin).
> Cada función dice abajo si es del original, deducida de una fuente, o **añadido nuestro**.

## Jugar

1. Descarga `release/Galaxy55_offline.swf` (español), `Galaxy55_offline_en.swf` (inglés) o
   `Galaxy55_offline_fr.swf` (francés).
2. Ábrelo con **Adobe Flash Player standalone (projector)**. Ruffle **no** sirve: el juego usa Stage3D.
   Hace falta una tarjeta gráfica con aceleración 3D.
3. Controles y detalles: `release/LEEME.txt` (es), `release/LISEZMOI.txt` (fr).

## Qué hay (y de dónde sale)

**Del juego original (código de Motion Twin, portado a Haxe 3.4.7 / Flash 11.8):**
cliente 3D, generación de planetas y biomas, bloques y recetas, láser y cargas, hangar con sus reglas,
mapa estelar, nombres de bloques oficiales (es/en/fr, descifrados de los clientes originales).

**Reconstruido sin el servidor:**
modo local (planetas generados en tu equipo), datos de bloques regenerados desde `data.ods`
(la macro original no se publicó), sector y sistemas aleatorios con los 5 tipos de planeta y sus
probabilidades originales.

**Deducido de fuentes** (Twinpedia, tráiler de 2012; ver `docs/`):
planetas por escanear con el contador naranja de planetas libres por sistema; tamaños de planeta
128/256/384; hangar construible de 17×17×14; textos de las opciones del ordenador.

**Añadido nuestro (no estaba en el original):**
- Soporte de **mando** (tipo Xbox): moverse/mirar, romper (RT) y colocar (LT), jetpack, inventario, casco,
  campo de visión, cursor virtual en el mapa estelar y menús. Ver `release/LEEME.txt`.
- **Sonido** activado (en el código publicado venía desactivado).
- **Menú del ordenador de a bordo** (Despegar / Modificar la nave / Comerciar / Detener). El original era
  HTML en la web y no se conserva: su aspecto es invención nuestra.
- **Tienda ESCorp local**: vender lo que llevas (50 % del precio base) y comprar piezas de nave. El original
  era un panel web con servidor; aquí usa los precios base de los datos del juego. Créditos solo en memoria.
- Cámara con el ratón bloqueado a pantalla completa, y campo de visión ajustable.
- La nave **aparece siempre en el mismo sitio de cada planeta** (distinto entre planetas) y empiezas dentro.
- Al despegar, el mapa estelar empieza junto al planeta del que sales, y dibuja tu nave editada.
- Los cambios del terreno se guardan **por planeta** mientras el juego está abierto.
- Hangar con 64 unidades de cada pieza de nave para construir libremente.
- Agua con transparencia (lagos 65 %) y **cascada con degradado**.
- Teclas de depuración: F9 (despegar), F8 (tienda), F (panel de FPS/mando), y comandos de chat
  `/despegar` y `/hangar`. El juego anota en `flashlog.txt` (si existe `mm.cfg`, ver abajo).

**Arreglos de errores del port (importantes si viajas entre planetas):**
- Fugas de memoria y de recursos de la tarjeta gráfica al cambiar de planeta (el original era una página
  nueva por planeta). Antes se llegaba a `Error #1000 out of memory` y `Error #3691` en pocos viajes.
- Las teclas de una sola pulsación (F, H, T, TAB, R, números, Esc...) casi nunca se detectaban.
- Los parches de transparencia de la textura se volvían a aplicar en cada planeta y degradaban el agua.
- Posible bucle de reconstrucción de chunks por el nivel del mar (blindado; **no confirmado** que fuera la causa).
- Acentos rotos en los nombres de bloques al compilar en Windows.

## Lo que NO está probado

- Comprar en la tienda y usar la tienda con mando; la opción Y del menú con mando.
- La tienda y los menús en inglés y francés (arrancan, pero no los recorrí).
- Que la nave editada se conserve tras salir y volver al hangar (en memoria; se pierde al cerrar el juego).
- Planetas pequeños (128) más allá de aterrizar en uno y mirar el suelo.
- Que los parpadeos de bloques que vio un jugador estén resueltos: lo más probable es que fueran la falta de
  memoria gráfica, pero no se reprodujeron.
- Aún quedan unos 27 MB sin liberar por viaje entre planetas (probado hasta 6 viajes seguidos).

## Estructura

```
src/            código del juego (Haxe): com/ (compartido), fla/client, fla/explore (mapa estelar), fla/engine
libs/           librerías: Motion Twin (libs-haxe2/3), Heaps (MIT) y format (BSD-2), cada una con su licencia
stubs/          clases vacías que sustituyen servidor, antitrampas y llamadas a JavaScript
tools/          desensamblador ABC, descifrador de recursos, generadores de datos (Python 3)
data/           nombres oficiales es/en/fr y volcado de la hoja de datos
release/        los tres .swf compilados y los LEEME
docs/           notas de la investigación (fuentes, qué se sabe y qué no)
client*.hxml    configuración de compilación;  build.bat / build.sh compilan las tres versiones
```

## Compilar

Necesitas **Haxe 3.4.7** (otra versión no sirve) y **Python 3**; las librerías ya vienen en `libs/`
(ver `libs/LEEME.txt`). Ejecuta `build.bat` (Windows) o `./build.sh`. Salen `out/client.swf` (es), `client_en.swf` y `client_fr.swf`.
En Windows hay que definir `HAXE_STD_PATH` apuntando a la carpeta `std` de Haxe.

**Registro de depuración (opcional):** crea `%USERPROFILE%\mm.cfg` con
`ErrorReportingEnable=1` y `TraceOutputFileEnable=1`; el reproductor *debug* escribirá
`%APPDATA%\Macromedia\Flash Player\Logs\flashlog.txt` (con memoria en uso, cambios de pantalla...).

## Licencia y créditos

El código, los gráficos y los datos originales son de **Motion Twin** y se publicaron bajo
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Esta versión modificada se comparte
bajo la **misma licencia**: **sin uso comercial**, con atribución a Motion Twin y compartiendo igual.
No está afiliada ni respaldada por Motion Twin. Los clientes originales descargados de Wayback Machine no se
incluyen. Gracias a la comunidad de Eternaltwin por conservar documentación y capturas.

---

## English summary

Offline build of Motion Twin's cancelled 2012 Flash alpha *Galaxy 55*, recompiled from their public source
archive with a local stand-in for the dead server. Adds gamepad support, sound, a local trade shop, a board
computer menu, per-planet saved terrain, and many fixes for travelling between planets (memory/GPU leaks, keyboard
toggles, texture patches). Languages: Spanish, English, French (`release/`). Run the SWF in **Adobe Flash Player
standalone** (Ruffle doesn't support Stage3D). Build with Haxe 3.4.7 + Python 3; the 2012-era Heaps (MIT) and
format (BSD-2) libraries are included under `libs/` with their licenses. Features are labelled in the Spanish text above as original,
source-derived, or **our own additions**; the "not tested" list is honest. CC BY-NC-SA 4.0, non-commercial,
credit to Motion Twin.
