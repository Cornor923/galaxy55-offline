# Port nativo (Haxe 4 + Heaps + HashLink)

[English: `README.md`](README.md)

Esta carpeta contiene el port del juego a una aplicación de escritorio nativa, sin Flash. Es trabajo en curso (con errores
conocidos, ver `ERRORES.md` en la raíz); el juego original en Flash sigue intacto en `src/`, `libs/` y `release/`, y también en la rama `flash`.

## Jugar

Compila (ver abajo) y haz doble clic en `jugar.bat`. Abre el menú de inicio: Continuar, Nueva partida, Cargar partida, Opciones y Salir.
En Nueva partida eliges nombre, semilla, bioma, tamaño y modo: **Aventura** (como el original) o **Creativo** (añadido nuestro).
Las partidas y los ajustes se guardan en `%APPDATA%\Galaxy55\` (se puede cambiar con la variable `GALAXY55_DATA`).
El formato de las partidas puede cambiar entre versiones: no cuentes con que las de hoy sirvan siempre.

## Controles

Son los del juego original (el movimiento y la física son una copia de `ent/Hero.hx` y `Game.moveHero`).

| Acción | Teclas |
|---|---|
| Moverse | W/Z/↑ avanzar, S/↓ retroceder, A/D y ←/→ de lado (en Opciones pueden girar, como en el original) |
| Mirar | ratón (o mando) |
| Saltar y jetpack | Espacio o Ctrl; en el aire, jetpack (gasta combustible, se recarga en el suelo) |
| Caminar despacio | X |
| Casco | H quita o pone el casco |
| Excavar o colocar | clic izquierdo, E o Mayús (mantener). Con la mano vacía excava; con un bloque, lo coloca si algo lo sujeta |
| Elegir casilla | 1–0 o la rueda del ratón; Tab = excavador (mano vacía) |
| Tirar la pila elegida | R o Supr |
| Activar (ordenador de a bordo, puertas) | apuntar y pulsar y soltar |
| Volver a la nave | Mayús+K, o entrar en el haz de luz del aterrizaje |
| Creativo: paleta de bloques | I (clic = poner el bloque en la casilla elegida, rueda = página) |
| Pausa | Esc |
| Guardado rápido | F5 |

No hay botón de correr, como en el original. Mando: palanca izquierda mueve, derecha mira, A salta y jetpack, B camina despacio,
RT excava, LT coloca, RB/LB o cruceta derecha/izquierda cambian de casilla, Y tira el bloque, Back casco, Start pausa. Menús: flechas/Intro/Esc, ratón o mando.

## Compilar

Hace falta (Windows):
1. **Haxe 4.3.x** (https://haxe.org/download/) y **HashLink 1.16** para Windows (https://github.com/HaxeFoundation/hashlink/releases).
   Pon las carpetas en el `PATH`; `haxe` y `hl` deben funcionar en una terminal.
2. Librerías de Haxe:

       haxelib install format
       haxelib git heaps https://github.com/HeapsIO/heaps
       haxelib git hashlink https://github.com/HaxeFoundation/hashlink
       haxelib dev hlsdl <carpeta-donde-clonaste-hashlink>/libs/sdl

   (`hlsdl` necesita el código de HashLink: clona ese repositorio y apunta `haxelib dev` a su carpeta `libs/sdl`.)
   Así se montó en el equipo de desarrollo (Heaps de la rama principal, HashLink 1.16, sin permisos de administrador). **No está probado desde cero en otro equipo**: si algo falla, abre un *issue*.
3. Desde la raíz del repositorio:

       haxe port\game.hxml          juego completo con menús   (-> port\out\galaxy55.hl)
       haxe port\render.hxml        prueba técnica de render   (-> port\out\render.hl)
       haxe port\headless.hxml      generador de planetas sin pantalla, HashLink
       haxe port\headless_flash.hxml  el mismo programa para Flash (referencia)

`jugar.bat` busca `hl` en el `PATH`; si lo tienes en otra carpeta, define la variable `HL` con su ruta antes de ejecutarlo.

### Versión DirectX (opcional)

Para equipos sin OpenGL 3.2 (por ejemplo, máquinas virtuales con la GPU compartida) hay una versión DirectX 11:

       haxelib dev hldx <carpeta-donde-clonaste-hashlink>/libs/directx
       haxe port\game_dx.hxml       (-> port\out\galaxy55_dx.hl, se abre con jugar_dx.bat)

Problema conocido: si la fuente de `hldx` es más nueva que tu `directx.hdll` (binario de HashLink 1.16 + hashlink de git),
cambiar el modo de pantalla falla con "Primitive or library is missing". Se arregla en `libs/directx/dx/Window.hx`,
`set_displayMode`: envolver el cuerpo en `try { ... } catch( e : Dynamic ) { winSetFullscreen(win, mode != Windowed); }`.
Con un `hldx` de la misma versión que tu HashLink no pasa.
El juego busca los gráficos del original en `res\` (paquete portátil) o, si no existe, en `src\G55\fla\client\gfx\`; la variable `GALAXY55_RES` fuerza otra carpeta.

## Qué hay

- `game/` el juego: menús (`GalaxyApp`, `Ui`), idiomas (`Lang`), ajustes (`Settings`), partidas (`SaveData`), planeta, luz y mallado (`World`),
  modelos de bloque (`Models`), cielo y niebla (`Sky`), nieve (`Snow`), jugador, excavar y colocar (`GameView`), inventario (`Inv`, `InvBar`, `Palette`),
  efectos y sueltos (`Fx`, `Drops`) y la nave (`Ship`, `ShipData`).
- `shim/` capa de compatibilidad `flash.*` para que los generadores originales compilen en HashLink.
- `headless/` programas de verificación: los mundos son idénticos a los de Flash (hash Adler-32, agua y bloques); también leen la nave y el guardado.

## Diferencias con el original

- El cielo, el degradado y la niebla usan los colores originales de cada bioma. Las estrellas son de este port.
- La nieve del bioma de invierno es un añadido de este port: el original no la tiene.
- El modo creativo y su paleta son un añadido de este port.
- El menú del ordenador de a bordo tiene un aspecto propio, como en la versión Flash (el original era una página web).
- Todavía faltan: recetas del sintetizador, tienda, hangar, mapa de exploración, agua que fluye, sonido y ver el bloque en la mano.
  Lista completa en `PENDIENTES.md` y `ERRORES.md` (raíz del repositorio).
