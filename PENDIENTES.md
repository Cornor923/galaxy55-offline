# Pendientes

Lo que **falta arreglar**, lo que **falta comprobar** y lo que **se podría añadir**. Si algo de aquí te interesa
o tienes información, abre un *issue*.

## Falta arreglar

- **No hay partida guardada (lo más importante que falta):** al cerrar el juego se pierde todo. El sector se genera
  al azar en cada arranque, así que no puedes volver a un planeta anterior, y la nave editada, el inventario y los
  créditos solo viven mientras el juego está abierto.
- **Fuga de memoria pequeña:** quedan unos **27 MB sin liberar por cada viaje** entre planetas (los objetos
  `Game`, `Level`, `Generator` y `Api` siguen vivos y no se ha encontrado qué los retiene). Tras muchísimos viajes
  seguidos conviene reiniciar el juego.
- **Parpadeo de bloques:** un jugador lo vio tras varios viajes. Lo más probable es que fuera falta de memoria
  de la tarjeta gráfica (ya mitigado), pero **no se pudo reproducir**, así que no está confirmado que esté resuelto.
- **Bucle de chunks:** se vio una subida a ~20 000 chunks reconstruidos en menos de un minuto. Se blindó el cálculo
  del nivel del mar como posible causa, pero **no se confirmó**. Si te pasa, pulsa **F** (panel de FPS) y guarda `flashlog.txt`.
- **Heaps y `format`:** no se pudieron comparar con sus commits de 2012; puede haber más diferencias que las dos
  anotadas en `libs/LEEME.txt`.

## Falta comprobar (compila, pero nadie lo ha visto)

- **Comprar** en la tienda, y la tienda entera **con mando**; la opción Y del menú del ordenador.
- Menús y tienda en **inglés y francés** (arrancan, pero no se recorrieron).
- Que la **nave editada se conserve** al salir del hangar y volver a entrar.
- Planetas **pequeños (128)** más allá de aterrizar y mirar el suelo.
- Mando de otras marcas: los botones se calibraron con uno solo.
- Agua de los lagos con la transparencia nueva (el efecto exacto no se verificó en pantalla).

## Se podría añadir

- Guardar nave, créditos y mundo **en disco** (ahora solo en memoria).
- **Ciudad Muerta** como planeta especial (existe en el código con probabilidad 0).
- Las **cargas violeta y verde** de la alfa 3 (por verificar que existen en el código).
- La **miniatura de la nave** en el mapa estelar.
- Los paneles web originales **Craft** (recetas) y **Trade** (tienda) con su lógica (`app.js`), si se consigue su aspecto.
- **Licencias** de planetas (máximo 3) como en el original, si se quiere más fiel.
- **Multijugador:** el protocolo está en el cliente, pero haría falta escribir un servidor.

## Necesitamos información

- **El aspecto original del menú del ordenador de a bordo y del ESCorp Trade Center.** Eran HTML servido por la web y
  no se conserva. El menú y la tienda actuales son **invención nuestra**. Cualquier captura o vídeo ayuda.
- Las imágenes de la Twinpedia (el enlace a un zip de ~180 MB del Discord ya no funciona).
- Si algo se veía o se comportaba distinto en el juego original, dínoslo.
