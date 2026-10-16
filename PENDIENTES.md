# Pendientes (versión nativa)

[English: `TODO.md`](TODO.md)

Orden aproximado. Lo ya hecho está en [`CHANGELOG.md`](CHANGELOG.md); los fallos, en [`ERRORES.md`](ERRORES.md);
los detalles técnicos de cada punto, en [`port/RESUMEN.md`](port/RESUMEN.md).

1. **Mapa de estrellas:** las transiciones ya son las del original (v0.2). Faltan las partículas de los reactores de la nave
   y las flechas (GPS) hacia los planetas activos.
2. **Robot comerciante** (en curso): hecho el comercio dinámico (créditos en la partida, precios que bajan si vendes mucho
   y suben si escasea, existencias que se reponen; ver `port/game/Market.hx`) y la ventana de tienda, de momento desde el
   ordenador de la nave. Falta: el robot viajando despacio por el mapa (y la velocidad real de nuestra nave según motores y
   peso), y la nave nodriza: un "planeta" vacío con cielo de espacio, con nuestra nave aparcada en una de sus bahías (las
   otras, para el multijugador) y la tienda dentro. Más adelante, un tablón de ofertas entre jugadores.
3. **Hangar** (hecho, falta probarlo a fondo): cobertizo y validación copiados del original; se entra desde el ordenador. La nave editada se usa en el planeta y en el mapa. Falta: el robot que viaja por el mapa con la velocidad real de cada nave.
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
4. **Arreglar los errores** de [`ERRORES.md`](ERRORES.md).
5. **Agua que fluye** (lógica de `Process.hx` del original) y textura animada.
6. Ver el bloque elegido en la mano; opción de calidad para PC lentas.
7. Sonido, vida/daño/oxígeno/lava, cofres y bloques activables, Ciudad Muerta y Shed.
8. Empaquetado: instalador, y evaluar SDL/DirectX.
9. A evaluar: **versión web** (Heaps → JS/WebGL), **multijugador** y Steam.
