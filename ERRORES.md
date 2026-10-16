# Errores conocidos (versión nativa)

Si encuentras uno que no está aquí, abre un *issue* con lo que hacías y, si puedes, una captura.
Los que están **arreglados** se mueven al final. Los detalles técnicos están en [`port/RESUMEN.md`](port/RESUMEN.md).

## Abiertos

| # | Dónde | Qué pasa |
|---|---|---|
| 1 | Partidas | **Borrar una partida desde el menú no funciona.** |
| 2 | Nave | El bloque de **fuente de cascada** puesto en la nave no se puede quitar. |
| 3 | Nave | Al fabricar en el **sintetizador** no desaparecen los bloques puestos en la zona (se gasta el inventario si tienes esos bloques, como en el original; falta decidir si cambiarlo). |
| 4 | Luz | Los bloques que **no son cuadrados** (medios bloques, modelos…) tienen la luz mal respecto a los vecinos. |
| 5 | Excavar | Al romper un bloque **no hay animación de partículas** y el bloque suelto **gira demasiado rápido**. |
| 6 | Excavar | No se pueden romper las cosas **colgadas** (estalactitas, enredaderas) ni las **plantas del suelo**. |
| 7 | Invierno | Hay **bloques blancos lisos** sin textura. |
| 8 | Invierno | Las **hojas del abeto** sueltan material; puede que en el original no. |
| 9 | Render | La **curvatura** del planeta se nota más de la cuenta. |
| 10 | Render | Los **cristales** sueltos (cargas) se ven demasiado anchos. |
| 11 | Render | La **capa 0** (roca madre) vista desde abajo se ve como un plano liso. |
| 12 | Agua | El agua **no fluye**, y se congela al tocar hielo (por confirmar si es lo esperado). |
| 13 | Mapa de estrellas | La **entrada y salida del sistema solar** y el **aterrizaje** son un simple fundido, no las animaciones del original; la salida del sistema es demasiado rápida (el original deja pasar la última órbita y te saca después). |
| 14 | Mundo | **Ciudad Muerta** y **Shed** no se pueden elegir aún (el generador existe y es idéntico al original). |
| 15 | General | **No hay sonido**, no se ve el bloque elegido en la mano, no hay tienda ni hangar. |

## Arreglados

- Aparecía «en el cielo» al entrar en el sintetizador (no se ha vuelto a ver).
- Los bloques del sintetizador se duplicaban al colocarlos.
- Pantalla en negro al despegar hacia el mapa de estrellas.
- Volver de un planeta dejaba la nave fuera de su galaxia (ahora vuelve junto al planeta).
