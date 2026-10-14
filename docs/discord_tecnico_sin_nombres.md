# Extractos técnicos del Discord (#g55 de Eternaltwin), sin nombres de usuario

Fechas aproximadas (mensajes citados o resumidos fielmente; original en francés/inglés/español).

## Los swf y de dónde salen
- 21-may-2022: alguien recupera los "últimos swf disponibles en el sitio de Motion Twin" (`client_en.swf`, `client_fr.swf`, de data.galaxy55.com) y comparte una clave de 32 caracteres (hex) del cliente; otro dice que puede "desofuscar" si hace falta. Se comparten también `client_fr2.swf` y `galaxy55-deobfu-deobfu-deobfu.swf` (variantes ofuscadas/desofuscadas del mismo cliente, ~1,59 MB).
- 24-nov-2020: un miembro tiene `galaxy55.swf` local (1,59 MB) porque "no se ve el swf en el git".
- 27-jul-2020: preocupación porque en Wayback la página de juego "se deteriora cada vez más"; enlace de referencia: web.archive.org/web/20121020090057/https://galaxy55.com/play .
- 1-ene-2023: `client_ship.swf` = "versión un poco trasteada para integrar la nave en la demo", y "cambio de la planeta por defecto" (captura g55.png, que no está en el export).
- La demo públicamente jugable se describe (abril 2022) como "la alfa, la versión demo del juego. Muy básica: un planeta, sin guardado". Otro: "puedes jugar la primerísima versión del juego (sin editor de nave, etc.)" desde el repo/GitLab.

## El servidor
- 21-may-2022: "es el servidor del juego, como play.kube.muxxu.com". "Para interactuar de verdad hay que cargar la página web para que genere la clave, imposible". "Tampoco es que necesitemos realmente el servidor... todo está en el cliente" (se refiere a la generación del mundo).
- 23-jun-2022: "Aunque los servidores sigan potencialmente arriba, no vamos a poder hacer nada con ellos".
- 3-ene-2023: "Habría que hacer un servidor para G55"; "adaptar el cliente a web sería un infierno, pero un servidor es factible"; otro: "no creo que sea mucho más difícil que Kube".
- 11-jun-2023: "solo la generación, y pasarla al servidor como en Kube".
- 2-sep-2022: "Heaps (heaps.io) existe gracias a G55"; "el código fuente es inutilizable, incluso para compilar en flash" (opinión de un miembro; nosotros lo recompilamos tras portar de Haxe 2 a 3.4.7).

## Generación de planetas
- 24-nov-2020: se vio una clase `_Generator` en el código; hay un truco para generar 3D desde ruido 2D (suma y medias de ruidos). "Los 50 filtros que usan para la gen".
- 23-jun-2022: "el efecto de curvatura es completamente artificial"; "la planeta de partida de la alfa 1 era un cuadrado de 256, daba la vuelta en ~5 min".
- Ideas de la comunidad: reversar la generación (un miembro se ofreció), usar un shader de "curva del mundo".

## Proyectos de recreación
- GitHub AlexandreVolts/G55 (MIT): prototipo BabylonJS + Express/socket.io, ~740 líneas, 1 planeta "Red Planet", Diamond-Square. Sin nada del original.
- GitLab eternaltwin/galaxy55/galaxy55: esqueleto de servidor TypeScript/Angular, solo `getPlayersOnPlanet`.
- Otros intentos mencionados: TerraNova en C (abortado), una prueba en BabylonJS.

## Recuerdos de jugadores (lore/funciones)
- Había naves, agregados que cubrían planetas, "proyecto Eclipse" (comunidad).
- Una explosión de sonido al dejar que el agua de una planeta se propague en una cueva; se preguntó si el kube "bombe antique" explotaba al contacto con el agua (sin respuesta clara).
- Entrada del "ESCorp Trade Center" (interfaz de venta web) mostrada en capturas.
- Guía en español de un jugador: galaxy55.webnode.es ; vídeo tributo en español en YouTube (PolloFrancesMC).
- Tráiler de 2012 (Deepnight Games, YouTube XRQ6XE6K-wQ): "juego cancelado".
- Otros juegos mencionados como parecidos: StarMade, Elite Dangerous, No Man's Sky, SpaceCraft.
