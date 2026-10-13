# Galaxy 55 — versión offline recompilada

Galaxy 55 fue un juego web de Flash (alpha, 2012) de **Motion Twin**: exploración espacial, planetas
generados al azar y un sistema de bloques/crafteo en 3D. Cerró y su servidor ya no existe.

Este proyecto recompila el cliente 3D a partir del código fuente que Motion Twin publicó en
[motion-twin/WebGamesArchives](https://github.com/motion-twin/WebGamesArchives) para que arranque
**sin servidor**, en modo local.

> **Estado: sin probar a fondo.** Compila sin errores y un usuario confirmó que arranca y se puede
> caminar por un planeta, pero no todo se ha comprobado. No hay guardado, cuentas, multijugador ni
> editor de nave.

## Jugar

Descarga `release/Galaxy55_offline.swf` (español) o `release/Galaxy55_offline_en.swf` (inglés) y ábrelo con
**Adobe Flash Player standalone (projector)**. Ruffle no sirve: el juego usa Stage3D.
Controles y detalles en `release/LEEME.txt`.

## Qué cambia respecto al original

- Portado de Haxe 2 a **Haxe 3.4.7** (`-swf-version 11.2`).
- Modo local: se quitó el servidor, el antitrampas y las llamadas a JavaScript; los planetas se generan en el equipo.
- Mapa estelar (el "explorador" original) con sector y sistemas generados localmente; desde él se aterriza en un planeta.
- Datos de bloques/biomas regenerados desde `data.ods` (la macro `ods.Data` original no se publicó).
- Nombres de bloques **oficiales** en español e inglés, descifrados de los clientes originales
  (`client_es.swf` / `client_en.swf` de Wayback Machine). Ver `tools/g55dec.py`.
- Añadidos: cámara con el ratón bloqueado (clic = pantalla completa, Esc = salir), campo de visión más ancho
  (teclas M/N), clic izquierdo como acción, ordenador de la nave que recuerda cómo volver al mapa.

## Estructura

- `patches/galaxy55-source.patch` — cambios sobre `Galaxy55/` del repositorio de Motion Twin.
- `patches/libs-motion-twin.patch` — cambios menores sobre `libs-haxe2` y `libs-haxe3`.
- `build/` — `client.hxml`, `client_en.hxml`, *stubs* y scripts de portado/generación de datos.
- `tools/` — desensamblador de ABC (`abcdis.py`), descifrador de recursos (`g55dec.py`), parser de serialización Haxe (`hxser.py`).
- `data/` — datos extraídos (hoja de bloques, nombres es/en).
- `release/` — SWF compilados y `LEEME.txt`.

## Compilar (resumen)

1. Clona `motion-twin/WebGamesArchives` (commit `8b8e2f2`) y aplica `patches/libs-motion-twin.patch`.
2. Copia `Galaxy55/` a una carpeta de trabajo y aplica `patches/galaxy55-source.patch`.
3. Obtén Heaps en el commit `787f6e88` (2012-11-30) y la librería `format` en `b505801` (2012-11-14);
   en `format/png/Reader.hx` pon `checkCRC = false`, y en `h3d/impl/Macros.hx` envuelve los manejadores de error con `Context.error`.
4. Ajusta las rutas absolutas de `build/*.hxml` y ejecuta **Haxe 3.4.7**: `haxe client.hxml` (o `client_en.hxml`).

Los scripts usan rutas de la máquina donde se prepararon (`/home/claude/...`); hay que adaptarlas.

## Licencia y créditos

El código y los datos originales son de **Motion Twin** y se publicaron bajo
[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Esta versión modificada se comparte
bajo la **misma licencia**: **sin uso comercial**, con atribución a Motion Twin y compartiendo igual.
No está afiliada ni respaldada por Motion Twin. Los clientes originales descargados de Wayback Machine no se incluyen.

---

## English summary

Recompiled offline build of Motion Twin's cancelled 2012 Flash alpha *Galaxy 55*, built from their
public source archive with a local stand-in for the dead server (planets, star map, block names in
English/Spanish). Run the SWF in Adobe Flash Player standalone (Ruffle doesn't support Stage3D).
Mostly untested; no saving or multiplayer. CC BY-NC-SA 4.0, non-commercial, credit to Motion Twin.
