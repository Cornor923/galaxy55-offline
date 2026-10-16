# Galaxy 55 — versión offline (port nativo para Windows)

**Galaxy 55** fue un juego web de Flash (2012) de **Motion Twin**: exploración espacial, planetas generados al azar y
un sistema de bloques con crafteo en 3D. Se cerró y su servidor ya no existe. Este proyecto lo porta a una
**aplicación de escritorio nativa para Windows** (Haxe 4 + Heaps + HashLink), sin Flash y sin servidor, partiendo del
código que Motion Twin publicó en [WebGamesArchives](https://github.com/motion-twin/WebGamesArchives).
El objetivo es ser fiel al original; lo que añadimos está marcado como tal.

> Es un trabajo en curso, no una versión final.

## Dónde está cada cosa

| Quiero… | Mira |
|---|---|
| **Jugar sin compilar** | [pre-release v0.1](../../releases/tag/v0.1): descarga el zip, descomprímelo y abre `jugar.bat` |
| **Controles y cómo compilar** | [`port/LEEME.md`](port/LEEME.md) |
| **Ver o avisar de errores** | [`ERRORES.md`](ERRORES.md) (lista de fallos conocidos; para avisar de uno nuevo, abre un *issue*) |
| **Saber qué falta por hacer** | [`PENDIENTES.md`](PENDIENTES.md) |
| **Ver qué cambió** | [`CHANGELOG.md`](CHANGELOG.md) |
| **Notas técnicas del desarrollo** | [`port/RESUMEN.md`](port/RESUMEN.md) |
| **La versión Flash (archivada)** | [`docs/flash/README_flash.md`](docs/flash/README_flash.md), rama [`flash`](../../tree/flash), etiqueta [`flash-version`](../../tree/flash-version) |

## Jugar en 3 pasos

1. Descarga el zip de la [pre-release v0.1](../../releases/tag/v0.1) y **descomprímelo entero** (con todas sus carpetas).
2. Comprueba que hay una carpeta **`res/`** junto a `galaxy55.hl` (con `texture.png`, `lazer.png`... dentro). Si en vez de eso ves
   archivos sueltos llamados `res	exture.png`, la extracción falló: vuelve a descomprimir con otro programa.
3. Windows: doble clic en `jugar.bat`. Otros sistemas: usa una compilación de [HashLink](https://github.com/HaxeFoundation/hashlink) para tu plataforma,
   copia `galaxy55.hl` como `hlboot.dat` en su carpeta, pon ahí `res/` y ejecuta `hl`. (Un jugador lo ha hecho funcionar en Linux así; no lo hemos probado nosotros.)
   El idioma (español, inglés, francés) se cambia en Opciones.

## Errores conocidos (resumen)

Lista completa y numerada en [`ERRORES.md`](ERRORES.md). Los principales:
- Borrar una partida desde el menú no funciona.
- Fallos de luz en bloques no cuadrados; bloques blancos y hojas de abeto raras en invierno; curvatura del planeta exagerada.
- Al romper un bloque no hay partículas; no se pueden romper las cosas colgadas ni las plantas del suelo.
- En la nave: no se puede quitar la fuente de cascada y el sintetizador no gasta los bloques puestos.
- Mapa de estrellas: entrada, salida y aterrizaje son un fundido simple, no las animaciones del original.
- El agua no fluye. Faltan la tienda, el hangar y el sonido.

**¿Has encontrado otro?** Cuéntalo en un *issue* de GitHub o por Discord, con lo que hacías y una captura si puedes.

## Qué funciona hoy

Menú de inicio, partidas guardadas, planetas idénticos a los del original (verificado por hash contra Flash),
excavar y colocar, jetpack, modo creativo (añadido nuestro), la nave con teletransportador, puertas, sintetizador con las
recetas del original y ordenador de a bordo, y el **mapa de estrellas** (sector, sistemas solares, escaneo y aterrizaje).
Faltan la tienda, el hangar, sonido, agua que fluye y las animaciones exactas de viaje del mapa; ver [`PENDIENTES.md`](PENDIENTES.md).

## Estructura del repositorio

```
port/           EL PORT NATIVO (lo activo)
  game/         el juego        explore/  mapa de estrellas     shim/  capa flash.* para los generadores originales
  headless/     verificación    dev/      banco de pruebas      LEEME.md, RESUMEN.md, RELEASE.md, jugar.bat
docs/flash/     documentación de la versión Flash (README, novedades y pendientes de entonces)
docs/           notas de la investigación (fuentes, Twinpedia, Discord)
src/ libs/ stubs/ tools/ data/ release/ client*.hxml build.*   código original (Motion Twin) y versión Flash
```

## Licencia y créditos

El código, los gráficos y los datos originales son de **Motion Twin**, publicados bajo
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Esta versión modificada se comparte bajo la
**misma licencia**: sin uso comercial, con atribución a Motion Twin y compartiendo igual. No está afiliada ni respaldada
por Motion Twin. Gracias a la comunidad de Eternaltwin por conservar documentación y capturas.

## English

Native Windows port (Haxe 4 + Heaps + HashLink) of Motion Twin's 2012 Flash game *Galaxy 55*, running offline with no
server, built from their public source archive. Work in progress. Download: [release v0.1](../../releases/tag/v0.1).
Unzip the whole package: the `res/` folder must sit next to `galaxy55.hl` (otherwise: "Can't read res/texture.png"). Other platforms: grab a HashLink build, rename `galaxy55.hl` to `hlboot.dat`, add `res/`, run `hl`. Language: Options menu. Known bugs (Spanish table): [`ERRORES.md`](ERRORES.md) · roadmap: [`PENDIENTES.md`](PENDIENTES.md) · Flash version (archived):
[`docs/flash/`](docs/flash/README_flash.md). CC BY-NC-SA 4.0, non-commercial, credit to Motion Twin.
