# Novedades (versión nativa)

[English: `CHANGELOG.en.md`](CHANGELOG.en.md)

## En desarrollo
- Opciones: sincronización vertical (VSync) y límite de FPS (30, 60, 120, 144, 240 o sin límite).
- Arreglos de **Cornor923** (¡gracias!): el velo del agua y los fondos de los menús cubren ventanas más anchas que 16:9,
  sin manchas oscuras a través del hielo, la cabeza ya no se mete en los bloques al caer o flotar, `jugar.bat` usa
  `hlw.exe` (sin consola) si está, y README en francés.

## v0.3 — pre-release
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
