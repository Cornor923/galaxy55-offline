# Traspaso para seguir en otra PC (2026-10-16)

Léelo entero antes de tocar nada. Lo escribió Claude para el Claude de la otra PC. El usuario es **Pvie** (Pv1E en GitHub): habla español,
quiere respuestas cortas y sin emojis, y que se **copie el original de Motion Twin, sin inventar**. Lo que añadimos nosotros se marca como
"cambio del port" o "añadido del port".

## Dónde está todo
- Repo: https://github.com/Pv1E/galaxy55-offline. Las ramas `main` y `port-hashlink` van iguales: se sube con
  `git push origin HEAD:main HEAD:port-hashlink`. Licencia CC BY-NC-SA 4.0.
- Resumen técnico largo del port: `port/RESUMEN.md`.
- Lista de lo que falta: `PENDIENTES.md` / `TODO.md`.
- Errores conocidos: `ERRORES.md` / `BUGS.md`.
- Novedades: `CHANGELOG.md`.
- El zip trae también `claude-memoria/`, la memoria de Claude de la PC anterior: preferencias del usuario y datos del entorno.
  Cópiala a la carpeta de memoria del proyecto en la nueva PC si quieres que se cargue sola.
- `nave-hades-atlas-2-0.zip`: el mapa de Minecraft con la nave nodriza. La hizo un amigo de Pvie, que dio permiso y no pide créditos.

## Entorno
- Haxe 4.3.7 + Heaps (rama main) + HashLink 1.16. Compilar: `haxe port\game.hxml` → `port\out\galaxy55.hl`. Jugar: `port\jugar.bat`.
- En la PC anterior las herramientas eran portables (`tools-portable\env.ps1`). En otra PC, instala Haxe/HashLink y las librerías
  siguiendo `port/README.md`.
- Banco de pruebas: `powershell -File port/dev/devrun.ps1 -Script port/dev/<script>.txt -Data <carpeta vacía> [-Extra "--creative"]`.
  Las órdenes de los scripts están en `port/game/Dev.hx`: `ship`, `tp`, `look`, `set`, `shot`, `print`, `shop`, `buy`/`sell`,
  `hangar`, `hangarexit`, `mothership`, `chestclick`, `settop`...
  Las capturas quedan en `port/out/`. `port/dev/sheet.ps1` las junta en una hoja.
- Normas del usuario:
  - nunca capturas de toda la pantalla;
  - no bajar la calidad visual por la PC lenta de desarrollo (no tiene GPU ni audio);
  - el usuario hace los inicios de sesión;
  - confirmar antes de publicar nada (releases, Discord).

## Hecho en esta sesión (después de la v0.2)
1. **Tienda del robot** (`Market.hx`, `Shop.hx`):
   - créditos en la partida (empiezas con 500); precios propios del port por rareza (en los datos del original casi todo valía 100);
   - el robot **nunca se queda sin nada**;
   - comprar mucho sube el precio, con tope x2 y compartido en el sector (pensado para el multijugador);
   - vender mucho de lo mismo baja lo que te pagan hasta 0, y esa bajada es **personal**; con precio 0 avisa
     "el robot ya tiene demasiado de esto";
   - todo se recupera a la mitad cada 10 min de juego;
   - la ventana muestra todas las casillas del inventario;
   - de momento se abre desde el ordenador → "Comerciar".
2. **Luz:** las caras de bloques reducidos (hierro) que tocaban otro bloque opaco salían negras. Arreglado en `World.addQuadL`.
3. **Bloques que no devolvían nada al romperlos** (BFNoDrop): turbo minero, tornillos, lámpara de minero, nitrógeno, hielo,
   roca helada, tinte muerto. Ahora se recuperan (`PortRules.hx`).
4. **Cantina de ESCorp = cofre de 4 casillas**, copiado de `ent/Chest.hx` (`Chest.hx`):
   - clic coge/deja, Mayús la mitad, Ctrl una;
   - se guarda en la partida (`chests`); al romperla suelta lo que tenía.
5. **Hangar** (`Hangar.hx`, copia de `EditShip` y `net/EditShip.initLevel`):
   - cobertizo, zona de 17x17x14 y validación completa con los mensajes del original;
   - se entra desde ordenador → "Modificar la nave" y se sale pisando las casillas de teletransporte;
   - la nave editada se guarda (`shipData` en base64) y la usan el planeta y el mapa;
   - en el hangar se usan los bloques del inventario.
6. **Opciones:** "Ayuda en pantalla" activable; la primera vez que se abre el juego se elige el idioma.
7. **Nave nodriza:**
   - Pvie no quiso mis diseños generados. Ahora es la **nave Hades**, importada de Minecraft a escala 1:1
     (113x347x63, mundo de 384x384).
   - Conversor: `port/tools/mc2g55.py` (+ `mcread.py`), que lee mundos Anvil 1.16+.
     Uso: `python -I port/tools/mc2g55.py "<carpeta del mundo>" src/G55/fla/client/gfx/mothership.bin`.
     La tabla de bloques está en el script.
   - Bloques nuevos del port, añadidos AL FINAL de `BlockKind` (en `Common.hx` y `DataGen.hx`): `BMotherHull`, `BMotherPanel`,
     `BMotherDark`. Sus texturas grises se generan en `Atlas.motherTiles`.
   - Cielo de espacio con nebulosas, galaxias que giran, estrellas de colores y estrellas fugaces (`Sky.makeSpace`).
   - Se visita desde ordenador → "Visitar la nave nodriza (prueba)"; Mayús+K vuelve. Nada se guarda dentro.
   - `Mothership.hx` conserva el diseño generado antiguo como reserva, si no hay `mothership.bin`.

## Lo siguiente (orden acordado)
1. **Pvie está construyendo en Minecraft el hangar y la zona de comercio dentro de la Hades:**
   - 3 bahías de al menos 19x19 y 18 de alto (caben las naves del hangar, como máximo 17x17x14), y puestos de comercio;
   - marcas: **bloque de esmeralda** en el centro de cada bahía y **bloque de diamante** en el mostrador del robot.
   Cuando mande el zip nuevo: convertir, leer esas marcas en el conversor (guardarlas en el .bin), aparcar la nave del jugador
   en una bahía, poner el robot y abrir la tienda en el mostrador. Las otras bahías quedan para el multijugador.
2. **El robot en el mapa:**
   - uno por sector, que viaja **despacio** entre sistemas (es comerciante);
   - icono con la forma de la Hades, renderizado como `Ship.captureFrames`; seguirlo con clic; al alcanzarlo, salto a la nave nodriza;
   - la velocidad de nuestra nave sale de la nave real (`Explorer.shipBytes` ya existe, pero la fórmula del mapa es aproximada:
     usar la del hangar, `Hangar.check().speed`);
   - ojo: `Ship.captureFrames` todavía centra la cámara con `DEFAULT_SHIP`; debería usar la nave actual.
3. Después: equipo del personaje (mejoras de jetpack, botas, etc.; lista de ejemplos en `PENDIENTES.md` 3b).

## Ideas de multijugador de Pvie (apuntadas en PENDIENTES 3c)
- Naves de jugador de como máximo 17x17x14, que aparcan en bahías.
- Naves de gremio grandes, con hangar compartido y permisos, que **se acoplan por fuera con tubos**.
- Tiendas de jugadores en los puestos de la nodriza.
- Servidores = **"Galaxias"** (20–50 jugadores cada una); empezar por Galaxias privadas para amigos.
- Cuidar el rendimiento en el navegador.

## Avisos
- El mensaje de validez del hangar puede ir un cambio por detrás (se comprueba cada 15 tmod).
- Las piezas de nave están a la venta en la tienda (ya sirven para el hangar).
- No probado con ratón real: la tienda, el cofre, el hangar y la ventana del idioma inicial (solo con el banco de pruebas).
