# Errores conocidos (versión nativa)

[English: `BUGS.md`](BUGS.md)

Si encuentras uno que no está aquí, abre un *issue* con lo que hacías y, si puedes, una captura.
Los que están **arreglados** se mueven al final. Los detalles técnicos están en [`port/RESUMEN.md`](port/RESUMEN.md).

## Abiertos

| # | Dónde | Qué pasa |
|---|---|---|
| 4 | Luz | Los bloques que **no son cuadrados** (medios bloques, modelos…) tienen la luz mal respecto a los vecinos. |
| 7 | Invierno | Hay **bloques blancos lisos** sin textura. |
| 8 | Invierno | Las **hojas del abeto** sueltan material; puede que en el original no. |
| 9 | Render | La **curvatura** del planeta se nota más de la cuenta. |
| 10 | Render | Los **cristales** sueltos (cargas) se ven demasiado anchos. |
| 11 | Render | La **capa 0** (roca madre) vista desde abajo se ve como un plano liso. |
| 12 | Agua | El agua **no fluye**, y se congela al tocar hielo (por confirmar si es lo esperado). |

## Arreglados

- v0.2: borrar una partida desde el menú.
- v0.2: la fuente de cascada se puede quitar (se apunta igual que en el original).
- v0.2: partículas al romper un bloque; los bloques sueltos giran a la velocidad del original.
- v0.2: Ciudad muerta se puede elegir en Nueva partida (Shed todavía no).
- v0.2: se ve el bloque elegido en la mano.
- v0.2: mapa de estrellas con las animaciones del original: entrar y salir de un sistema (zoom, hiperespacio, destellos; la salida deja pasar el anillo y te saca al rato), escanear (fundido, nombre y barra) y aterrizar; fondo común con remolino.
- v0.2 (cambio respecto al original): el sintetizador gasta siempre los bloques puestos en su zona.
- v0.2 (cambio respecto al original): las hierbas del suelo y las estalactitas de hielo se rompen; dan hierba alta (33 %) o hielo (7 %), como las plantas y el hielo negro del original.

- Aparecía «en el cielo» al entrar en el sintetizador (no se ha vuelto a ver).
- Los bloques del sintetizador se duplicaban al colocarlos.
- Pantalla en negro al despegar hacia el mapa de estrellas.
- Volver de un planeta dejaba la nave fuera de su galaxia (ahora vuelve junto al planeta).
