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
3. **Hangar:** editar y validar la nave (la editada se verá en el mapa; su velocidad depende de motores y peso).
4. **Arreglar los errores** de [`ERRORES.md`](ERRORES.md).
5. **Agua que fluye** (lógica de `Process.hx` del original) y textura animada.
6. Ver el bloque elegido en la mano; opción de calidad para PC lentas.
7. Sonido, vida/daño/oxígeno/lava, cofres y bloques activables, Ciudad Muerta y Shed.
8. Empaquetado: instalador, y evaluar SDL/DirectX.
9. A evaluar: **versión web** (Heaps → JS/WebGL), **multijugador** y Steam.
