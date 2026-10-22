# Pendientes (versión nativa)

[English: `TODO.md`](TODO.md) · [Français : `TODO.fr.md`](TODO.fr.md)

Orden aproximado. Lo ya hecho está en [`CHANGELOG.md`](CHANGELOG.md); los fallos, en [`ERRORES.md`](ERRORES.md); las ideas
para más adelante (combustible, desbloquear sistemas, equipo, multijugador…), en [`IDEAS.md`](IDEAS.md). Los detalles
técnicos de cada punto están en [`port/RESUMEN.md`](port/RESUMEN.md).

1. **Mejorar el modo espacial** para que el viaje y la velocidad de la nave importen. Qué hacer se elige de
   [`IDEAS.md`](IDEAS.md) (sección "Viaje espacial"); por ahora, la favorita es el combustible.
2. **Mapa de estrellas:** comprobar si falta algo de las partículas del motor en marcha. Ya están las transiciones del
   original, el fondo común con remolino, las partículas del salto, el destello de los reactores, las flechas GPS y el
   robot comerciante.
3. **Hangar** (hecho, falta probarlo a fondo). La velocidad en el mapa cuenta todos los motores, como el original (el mensaje del
   hangar solo cuenta los de salida libre, también como el original).
4. **Arreglar los errores** de [`ERRORES.md`](ERRORES.md).
5. **Agua:** por decidir lava + agua = basalto (ver [`IDEAS.md`](IDEAS.md)). Ya están el agua que fluye y las olas del original.
6. Opción de calidad para PC lentas (ya se pueden quitar las olas del agua).
7. Más bloques activables (la bomba antigua ya explota, PR 34); Ciudad Muerta.
8. Empaquetado: instalador, y evaluar SDL/DirectX.
9. A evaluar: **versión web** (Heaps → JS/WebGL) para Eternaltwin, multijugador y Steam (ver [`IDEAS.md`](IDEAS.md)).
