# Novedades (versión nativa)

[English: `CHANGELOG.en.md`](CHANGELOG.en.md) · [Français : `CHANGELOG.fr.md`](CHANGELOG.fr.md)

## Próxima versión
- **Agua que fluye** (el `Process.hx` del original): el mar llena lo que cavas a su lado hasta su nivel; la cascada y la lava
  caen y se extienden y desaparecen sin fuente; la hierba se cubre y descubre; lo anclado y los detalles se rompen al quitar
  su apoyo. La cascada y el agua que pones bajan de altura en cada paso, con la superficie inclinada (añadido del port).
- **Robot comerciante en el mapa de estrellas:** viaja entre los sistemas del sector; al pulsarlo se para y te espera, y al
  acoplarte entras en su nave (la nave nodriza), con la tienda. Al salir vuelves al mapa.
- **Flechas GPS** del original en el mapa: apuntan a los planetas que visitaste (y a sus sistemas) y al robot (en naranja).
- Opciones: sombra del bloque que vas a poner y nombre del bloque apuntado (pequeño, abajo a la derecha); los dos se pueden quitar.
- Modo creativo: las cuatro aguas (normal, oscura, ácida y de invierno) están en la paleta.
- Arreglos de **Cornor923** (¡gracias!): la roca madre (capa 0) se dibuja y se puede construir encima; el menú principal se
  pega a los bordes en ventanas anchas; el sintetizador gasta primero los bloques del inventario y deja la zona como plantilla
  (como el original); el juego se abre como `galaxy55.exe`, con su icono (Discord ya no dice "Half-Life"); el agua y el hielo
  se dibujan en el orden correcto; ya no se ponen bloques dentro de una fuente de cascada ni en arenas movedizas; los fondos
  de la tienda, el cofre, la paleta y el mapa tapan toda la ventana; textos centrados en los botones del mapa y sin pisar el
  botón Cerrar; nombres para muchos bloques que no lo tenían (variantes con nieve, cargas, plantas, cristales de bonus).
- El bloque en la mano ya no tiembla al andar.
- Arreglos reportados por Sekhmet (¡gracias!): atajos de teclado (Tab excava y 1-0 son las 10 casillas), se pueden poner
  bloques bajo el agua, no nieva bajo techo ni en cuevas, el hielo ya no suelta un bloque al romperlo, sombra del bloque que
  se va a poner, nombre del bloque apuntado y el congelador vuelve a congelar el agua y la lava cercanas.
- Linux: los zips usan `/` en las rutas (antes salían archivos con `\`); pasos de Linux de Sekhmet en el `LEEME` del zip.

## v0.3.1 — pre-release
- Opciones: sincronización vertical (VSync) y límite de FPS (30, 60, 120, 144, 240 o sin límite).
- Arreglos de **Cornor923** (¡gracias!): el velo del agua y los fondos de los menús cubren ventanas más anchas que 16:9,
  sin manchas oscuras a través del hielo, la cabeza ya no se mete en los bloques al caer o flotar, `jugar.bat` usa
  `hlw.exe` (sin consola) si está, y README en francés.

## v0.3 — pre-release
- Hangar: rehaz tu nave bloque a bloque, como en el original; se sale por el teletransportador para guardarla.
- Tienda: compra y vende bloques con créditos, al robot comerciante.
- Sonido: los 12 efectos del original (pasos, salto, aterrizaje, caída fuerte, jetpack, láser, romper y recoger bloques).
- Punto de mira fijo en el centro de la pantalla.
- Nombres de los bloques completos en español, inglés y francés (antes salían en español o mezclados).
- Cofres: un toque los abre y mantener el láser los rompe (lo que tenían cae al suelo). En tu nave, el ordenador y las
  puertas no se rompen.
- Creativo: paleta con mando (R3), copiar el bloque apuntado (L3 o clic central) y dos bloques nuevos, blindaje
  amarillo y negro, para franjas de peligro.
- Nave nodriza: cielo de espacio profundo (Vía Láctea, nebulosas, miles de estrellas y galaxias lejanas), plazas con
  borde de franjas de peligro y editor (`editar_nodriza.bat`).
- Menos tirones al romper o poner bloques, sobre todo en la nave nodriza.
- El rayo del teletransporte a la nave ya no desaparece con la niebla del invierno.
- Arreglos reportados por Sekhmet (¡gracias!): dentro de un líquido la pantalla y la niebla toman su color, como en el
  original (la arena movediza ya no parece transparente); no nieva bajo el agua; el agua tiene caras laterales; el hielo
  sumergido queda detrás del agua; textos del mapa de estrellas traducidos.
- Nombres originales de los biomas en francés (Terres Rouges, Rocaille sombre, Sables arides), encontrados por Sekhmet
  en la antigua Twinpedia.
- Versión DirectX opcional (`haxe port\game_dx.hxml`, `jugar_dx.bat`), además de la de OpenGL.
- Nave nodriza: indestructible, mejor iluminada, puertas cerradas, campos de fuerza láser en los hangares, 10 plazas
  marcadas, tu nave aparcada en la tuya (apareces dentro y su ordenador te devuelve), y una tienda con un robot
  comerciante animado en el túnel de entrada.
- Mando: cofres, tienda y cambio de casilla (LB/RB).
- El juego ya no se congela unos segundos al arrancar.
- `jugar.bat` funciona aunque el PATH tenga carpetas con paréntesis.

## v0.2 — pre-release
- Mapa de estrellas con las animaciones del original (entrar y salir de un sistema, hiperespacio, destellos, espera del
  servidor), fondo común con remolino; el sistema se genera en segundo plano y ya no se congela.
- Bloque elegido en la mano y partículas al romper, copiados del original.
- Ciudad muerta elegible en Nueva partida.
- Arreglos: borrar partida, quitar la fuente de cascada en la nave, giro de los sueltos, nieve dentro de la nave.
- Cambios respecto al original: el sintetizador gasta los bloques de su zona; hierbas y estalactitas rompibles; curvatura
  al 60 %; montículos de nieve con planta escondida como la nieve; acercamiento al planeta al entrar.

## v0.1 — pre-release
Primera versión nativa publicada: menús y partidas guardadas, planetas idénticos a los de Flash, excavar/colocar/jetpack,
modo creativo, nave (teletransportador, puertas, sintetizador con recetas originales, ordenador), mapa de estrellas
(sector, sistemas, escaneo y aterrizaje; el universo forma parte de la partida) y paquete portátil con `jugar.bat`.
Fallos conocidos: [`ERRORES.md`](ERRORES.md).

La versión Flash anterior tiene sus propias novedades en [`docs/flash/CHANGELOG_flash.md`](docs/flash/CHANGELOG_flash.md).
