# Port nativo (Haxe 4 + Heaps + HashLink)

Esta carpeta contiene el port del juego a una aplicación de escritorio nativa, sin Flash. Es trabajo en curso
en la rama `port-hashlink`; el juego original en Flash sigue intacto en `src/`, `libs/` y `release/`.

## Jugar

Doble clic en `jugar.bat`. Abre el menú de inicio: Continuar, Nueva partida, Cargar partida, Opciones y Salir.
Las partidas y los ajustes se guardan en `%APPDATA%\Galaxy55\` (se puede cambiar con la variable `GALAXY55_DATA`).

Controles (los del juego original; el movimiento y la fisica son una copia de ent/Hero.hx y Game.moveHero):
W/Z/flecha arriba avanzar, S/flecha abajo retroceder, A/D y flechas izquierda/derecha desplazarse de lado (en Opciones se puede elegir que giren, como en el original), ratón mirar,
Espacio o Ctrl saltar y, en el aire, jetpack (gasta combustible y se recarga en el suelo), X caminar despacio,
H quitar o poner el casco, Esc pausa, F5 guardado rápido. No hay botón de correr, como en el original.
Mando: palanca izquierda mueve, derecha mira, A salta y jetpack, B camina despacio, Back casco, Start pausa.
Menús: flechas/Intro/Esc, ratón o mando.

## Compilar

Requiere Haxe 4.3, HashLink 1.16 y las librerías `heaps`, `hlsdl` y `format` (ver `tools-portable` en la
documentación de la sesión). Desde la raíz del repo:

    haxe port\game.hxml          juego completo con menús   (-> port\out\galaxy55.hl)
    haxe port\render.hxml        prueba técnica de render   (-> port\out\render.hl)
    haxe port\headless.hxml      generador de planetas sin pantalla, HashLink
    haxe port\headless_flash.hxml  el mismo programa para Flash (referencia)

## Qué hay

- `game/` el juego: menús (`GalaxyApp`, `Ui`), idiomas (`Lang`), ajustes (`Settings`), partidas (`SaveData`),
  planeta y mallado (`World`), cielo y niebla (`Sky`), nieve (`Snow`) y jugador (`GameView`).
- `shim/` capa de compatibilidad `flash.*` para que los generadores originales compilen en HashLink.
- `headless/` programa de verificación: los mundos son idénticos a los de Flash (hash Adler-32, agua y bloques).

## Diferencias con el original

- El cielo, el degradado y la niebla usan los colores originales de cada bioma. Las estrellas son de este port.
- La nieve del bioma de invierno es un añadido de este port: el original no la tiene. Los copos están fijos en el mundo y se ocultan detrás del terreno.
- Todavía faltan: modelos (plantas, cristales), romper y colocar bloques, sonido, tienda y nave.
