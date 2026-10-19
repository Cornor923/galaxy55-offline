# Pendientes (versión nativa)

[English: `TODO.md`](TODO.md)

Orden aproximado. Lo ya hecho está en [`CHANGELOG.md`](CHANGELOG.md); los fallos, en [`ERRORES.md`](ERRORES.md);
los detalles técnicos de cada punto, en [`port/RESUMEN.md`](port/RESUMEN.md).

1. **Mapa de estrellas:** las transiciones ya son las del original (v0.2). Hechas las partículas del salto, el destello
   de los reactores y las flechas (GPS) hacia los planetas visitados. Falta la "common room" (remolino); comprobar si falta
   algo de las partículas del motor en marcha.
2. **Robot comerciante** (hecho): comercio dinámico (créditos en la partida, precios que bajan si vendes mucho y suben si
   escasea, existencias que se reponen; ver `port/game/Market.hx`) y su nave por el mapa: viaja despacio entre los sistemas
   del sector (flecha GPS naranja); al pulsarlo se para y te espera, tu nave va a su velocidad (motores y peso del hangar) y
   al acoplarte entras en la nave nodriza, con la tienda y tu nave aparcada. Más adelante, un tablón de ofertas entre jugadores.
3. **Hangar** (hecho, falta probarlo a fondo): cobertizo y validación copiados del original; se entra desde el ordenador. La nave editada se usa en el planeta y en el mapa.
3b. **Equipo del personaje** (añadido del port, después del hangar): un inventario de equipo aparte (casco, traje,
   mochila, botas...) con mejoras que se fabrican o se compran al robot. Ejemplos:
   - Mochila de gran capacidad: jetpack con más combustible.
   - Turbo de jetpack: sube más rápido.
   - Recarga rápida: el combustible vuelve antes al tocar el suelo.
   - Botas de salto: salto más alto (como el bloque saltador, pero llevado puesto).
   - Botas antideslizantes: no resbalar en el hielo.
   - Amortiguadores: menos daño por caída (cuando haya vida/daño).
   - Excavador mejorado: rompe más rápido (como el turbo minero, pero personal).
   - Bolsa ampliada: más peso por casilla o más casillas.
   - Linterna de casco: luz alrededor del jugador en cuevas.
   - Imán: los bloques sueltos llegan desde más lejos.
   - Traje térmico / tanque de oxígeno: aguantar lava, frío o el vacío (cuando haya oxígeno/daño).
3c. **Ideas para el multijugador** (de Pvie, para más adelante):
   - Naves de jugador: como máximo 17×17×14 (el hangar del original); aparcan dentro de bahías (nave nodriza, gremios).
   - Naves de gremio: más grandes, con hangar compartido y permisos de quién puede romper bloques. No aparcan dentro:
     se acoplan desde fuera con tubos de acoplamiento.
   - Tiendas de jugadores: puestos en la zona de comercio de la nave nodriza (ya diseñada) o un mostrador en la nave de un gremio.
   - Cuidar el rendimiento en el navegador (mundos pequeños y fijos, mallas que no se rehacen, límite de jugadores visibles).
4. **Arreglar los errores** de [`ERRORES.md`](ERRORES.md).
5. **Agua que fluye** (hecho: `port/game/WorldProcess.hx`, el `Process.hx` del original). El mar llena por completo hasta su
   nivel, como el original; la cascada y el agua puesta por el jugador bajan de altura en cada paso, con la superficie
   inclinada; la lava sigue como el original (bloque sólido que atraviesa el agua). Falta: textura animada.
   Recuerdos de Sekhmet (comprobar con el código original antes de copiar):
   - la cascada no se congelaba junto al hielo; sustituía el agua si se ponía dentro y hacía de barrera (refugios bajo el agua con una cascada de puerta);
   - **pendiente de decidir:** cascada (o agua) + lava = basalto sólido (basalto infinito). El código del cliente original no
     lo hace (la lava solo reemplaza el agua; el basalto solo sale del congelador): quizá era del servidor, que no se publicó;
   - el mar pasó por 3 versiones en las alfas: estático; se extiende sin bajar de nivel; se extiende y el nivel global del planeta baja según la proporción agua/espacio (nunca sube).
   - Idea descartada por ahora: un cubo para coger agua o lava (a Cornor923 no le convence: el traje "ya lo hace").
6. Opción de calidad para PC lentas (el bloque elegido ya se ve en la mano desde la v0.2).
7. Vida/daño/oxígeno/lava, más bloques activables, Ciudad Muerta y Shed (el sonido y los cofres ya están desde la v0.3).
8. Empaquetado: instalador, y evaluar SDL/DirectX.
9. A evaluar: **versión web** (Heaps → JS/WebGL), **multijugador** y Steam. Eternaltwin (Biosha) ofrece alojarla con
   servidor (PostgreSQL, Node/Rust/PHP, entrada con OAuth): primero, que el juego funcione en el navegador para un jugador.
10. **Ideas de Cornor923 para más adelante** (la exploración espacial se queda: es parte de la identidad del juego):
   planetas lejanos más ricos en recursos, un planeta "base", contenido de Kube como planetas nuevos (sin tocar los
   originales). Velocidad de la nave: el original solo contaba los motores con la salida libre; el port cuenta todos.
