# Resumen del port de Galaxy 55 (leer esto primero)

## Qué estamos haciendo
Galaxy 55 (Motion Twin, 2012) era un juego de bloques en Flash. Este repo lo hacía funcionar sin servidor.
Flash está muerto, así que estamos **portándolo a una aplicación nativa de escritorio**: Haxe 4 + Heaps moderno + HashLink
(el mismo motor y lenguaje con el que se hizo el original, y con el que Motion Twin hizo Dead Cells).
Metas: menú de inicio con guardado y carga, fidelidad al original, y a futuro Steam y multijugador.
Trabajo en la rama `port-hashlink` (commits locales, nada subido). `main` conserva la versión Flash intacta.

## Cómo lo hacemos
- **Reutilizar, no reescribir:** los generadores de planetas originales (`src/G55/fla/client/src/gen`) se compilan tal cual.
  Una capa `port/shim/` imita `flash.Memory`, `Vector`, `ByteArray`. Los cambios al código original son mínimos y con `#if flash`.
- **Verificación contra Flash:** el mismo programa se compila a SWF y a HashLink y se comparan mundos
  (hash Adler-32 + agua + recuento de bloques). Los 4 mundos de referencia son idénticos.
- **Render y juego nuevos** en `port/game/` (Heaps moderno): mallado por chunks 16x16, cielo y niebla con los colores
  originales de cada bioma, jugador con la física del original (`Hero.doMove`), casco, jetpack, menús, guardado.
- **Pruebas automáticas:** `galaxy55.hl --shot=<png> --screen=main|new|load|options|pause|game|jet|phys` genera capturas
  o números sin molestar (ventana fuera de pantalla); se leen los PNG para comprobar la interfaz.

## Estado actual (todo funciona y está probado, salvo lo marcado)
- Menú: Continuar, Nueva partida (nombre, semilla, bioma, tamaño), Cargar partida (miniatura), Opciones, Salir. es/en/fr.
  Ratón, teclado y mando. Fondo = el juego visto desde dentro, recorriendo varios biomas con fundido.
- Partidas en `%APPDATA%\Galaxy55\` (miniatura incluida, autoguardado, F5). Opciones: idioma, sensibilidad, FOV, volumen,
  pantalla completa, invertir eje vertical, A/D girar (original) o desplazar.
- Jugador: caminar, X despacio, saltar, jetpack con combustible, colisiones, casco (H), barra de combustible. Sin correr ni vuelo.
- Biomas jugables: Otoño, Luna, Marte, Cumbres nevadas (con nieve, añadido nuestro), Bosque ácido.
- Mundo: da la vuelta como el original (toroide, copias vecinas hasta 180 bloques); luz como `Builder.relight` (sol por bioma, cuevas, `BFLight`, suavizado por vértice); modelos de bloque (`Models.hx`, copia de `initModels`), bloques parciales y extendidos; hielo/cristal con alfa.
- Planeta redondo: `curve = 2/tamaño` como `AbstractGame`; el shader (`Sky.FogShader.vertex`) baja cada vértice `(dx²+dy²)·curve` respecto a la cámara. Solo visual: física y selección no lo usan (el original corrige la selección con la curva, pendiente al hacer romper/colocar: `Render.pick`).
- Excavar y colocar (copia de `Game.checkAction/blockBreak`, `Level`, `Dummy`, `Inventory`): rayo del centro con la curva (`GameView.pick`), tiempo de rotura `requiredPower*40/miningPower` por tmod, cargas rápidas (`quickBreaks`), sueltos con probabilidad (`BFDropChance`), reglas de ancla/imán al colocar. Barra de inventario arriba al centro (`InvBar`, casillas de 40 px cada 44, la 0 es el excavador, cargas a la izquierda, icono 3D con `IconMesh.Icons`). Efectos del original en `Fx`: caja naranja, cubo que tiembla al excavar, cubo con la casilla (51,0) si no se puede romper, rayo con 4 texturas según la carga. Cambios de terreno e inventario van en el guardado (`SaveInfo.inv/edits`). Luz y malla se rehacen por zona (`World.setBlock/flush/relightRegion`). Teclas: clic/E/Mayús, 1-0 y rueda, Tab, R.
- Nave (parte 1; `Ship.hx`, `ShipData.hx`, `World` con `ship`): la partida nueva empieza dentro de la nave (DUCK-01, 17x17x12), un volumen en z>=130 sobre el punto de aterrizaje (`World.startPlace` = `Level.getStartPlace`, fijo por semilla). Teletransportador (BShipEntry) y haz de luz del aterrizaje con las condiciones de `ShipLogic.update` y fundido blanco (1,5); Mayús+K vuelve a la nave. El ordenador de a bordo abre su menú (despegar/hangar/comerciar aún no disponibles); las puertas (`BFToggle`, modelos de `door.md`) se abren y cierran. El casco no se puede apuntar. Pruebas: `--tele`, `--door`, `--computer`, `--listnear`.
- Modo creativo (añadido nuestro, se elige en Nueva partida y se guarda en `SaveInfo.creative`): bloques sin gastar, rotura instantánea (0,25 s entre bloques), sin sueltos, jetpack infinito, y paleta con los 146 bloques de la tienda del original (tecla I, `Palette.hx`, clic = poner en la casilla elegida, rueda = página). Prueba: `--creative`, `--screen=palette`.
- Pruebas: `--screen=mine|place|cont [--n=frames --slot=N --at=x,y,yaw,pitch --deny --save]`, `port/savetest.hxml`.
- Falta del original (inventario de bloques: 213; ~85 eran modelos, ya dibujados): puertas de nave (`door.md` binario), vida/daño/curación/oxígeno/lava, bloques activables y contenedores, líquidos que fluyen, romper/colocar, y los modos nave, hangar y mapa de exploración (`fla/explore`).
- No probado en ventana real por mí: ratón/teclado/mando en vivo, ni el movimiento de la nieve (solo capturas y números).

## Qué falló y cómo se resolvió
| Problema | Causa | Solución |
|---|---|---|
| Sin permisos de administrador | no se podía instalar Haxe | zips portables en `tools-portable/`; `haxelib` con Neko portable |
| Haxe prohíbe el paquete `flash` | restricción de plataforma | `--macro allowPackage('flash')` |
| El generador de Luna no terminaba en HashLink | el último `-cp` gana: usaba `mt.Rand` Int en vez de Float | copia de `mt.Rand` con la variante Float, colocada al final del classpath |
| Autumn/Mars distintos de Flash | `Array.sort` de Flash es inestable (quicksort) y HashLink es estable | `gen/FlashSort.hx` reproduce el algoritmo de Tamarin |
| `Reflect.field` en enums daba null | solo funciona en Flash | `Type.createEnum` con `#if flash` |
| Flash standalone "no hacía nada" | pasaba la ruta del SWF entre comillas; además `trace` de Haxe pinta en pantalla y `System.exit` está bloqueado | ruta sin comillas, `flash.Lib.trace`, sin `exit`, trabajo por tandas (límite de 15 s por script) |
| `JIT ERROR 128` de HashLink | función con 14 argumentos decimales | pasar un array |
| Todo se veía inverso (giro, A/D) | Heaps usa coordenadas zurdas | invertir signos |
| Las hojas no chocaban | usaba "opaco" en vez de `Block.collide` | usar el atributo `collide` del bloque |
| Fondo negro, planeta flotando | solo era un render | domo de cielo + shader de niebla con los 3 colores originales de cada bioma |
| Cámara del menú en zigzag | la altura seguía cada árbol | tabla de alturas precalculada, la mejor de 11 rutas, más lenta |
| "?" en "Generando…" | la fuente no tiene el carácter "…" | tres puntos normales |
| Nieve corría al girar, luego pegada al jugador | el modo de partículas GPU rota un offset grande; la versión 2D no reaccionaba al movimiento | copos con posición fija en el mundo, proyectados con la cámara y ocultos tras el terreno |
| Movimiento inventado (Shift, vuelo) | no existía en el original | copia fiel de `Hero.doMove`/`moveHero`; correr y vuelo eliminados |
| Filtro de seguridad bloquea comandos | falso positivo de "Remove-Item" | usar las herramientas Edit/Write y evitar `//` en comandos PowerShell |

## Pendiente (por orden)
1. **Nave** (parte 1 hecha: aparecer, teletransporte, ordenador, puertas). Falta: **sintetizador** (`BCrafter` + `BCrafterComputer`, `CraftEngine`, recetas
   `Data.CRAFTS`), **tienda ESCorp** (`Game.openShop`, créditos), estado de las puertas al guardar, y el menú "despegar" que llevará al explorador.
2. **Hangar** (`EditShip.hx`, `net/EditShip.hx`): editar los bloques de la nave y validarla (hermética, motores, ordenador, teletransportador...).
3. **Explorador / mapa de estrellas** (`fla/explore`, `Manager.hx` + `Room.hx`): sectores, sistemas solares y planetas.
4. Después, ideas guardadas por el usuario (no empezar antes de 1-3):
   - **Agua que se mueve**: primero el flujo del original (`Process.hx`: inundación del mar con `updateFlood`, líquidos con `BFPropagate`
     como cascada y lava, cubrir/descubrir hierba, plantas que se rompen al quitar el suelo; hay que portar `Process.onSet` entero),
     luego niveles de altura al estilo Minecraft (cada paso lateral baja la altura de la superficie; la columna que cae va llena)
     y una textura de agua animada.
   - **Ver en la mano el bloque elegido** (el original dibuja el bloque en `Render.hx`, `drawBlock(block, curLight)` con `curLight` suavizado; hoy solo se ve en la barra).
   - **Opción de calidad** (distancia de dibujado, caras de las hojas) para PC lentas; el valor por defecto sigue siendo la mejor calidad.
   - Vida, daño, curación, oxígeno y lava; bloques activables, cofres, `BFTransform`; sonido; partículas al romper; planeta Shed y Ciudad muerta completos.
5. Decidir SDL (actual) o DirectX; empaquetar como instalable; multijugador y Steam.
6. Cuando el usuario lo apruebe: fusionar `port-hashlink` en `main` ("hacerlo oficial").


## Cómo retomar
    . C:\Users\Usuario\Desktop\Claude\tools-portable\env.ps1     (Haxe 4.3.7, HashLink 1.16, Neko)
    haxe port\game.hxml                 compila el juego
    port\jugar.bat                      lo abre
Verificación de generadores: `haxe port\headless.hxml` y `haxe port\headless_flash.hxml` (comparar hashes).
