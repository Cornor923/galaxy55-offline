# Página web original del juego (galaxy55.com/play, captura Wayback del 15-dic-2012)

- `galaxy55_play_page_wayback_2012-12-15.html.txt`: HTML de la página que alojaba el swf (versión inglesa). Contiene los textos
  `div#_<id>` que el cliente pedía con `getText` (confirmKill, no_recipe, user_join, user_leave, camera_link) y la ayuda de
  controles que se mostraba debajo del juego (modos "Classic Controls" y "Mouse Controls").
- `app.js_...txt`: JavaScript (Haxe->JS) de la página. Clases: `App` (puente con el swf: lockBar, setControls, ask, getText,
  loadModule/exitModule, showHelpTip, toggleFullScreen), `Craft` (panel HTML de recetas/inventario, hablaba con `/craft`),
  `Slots`/`Trade` (panel de la tienda ESCorp). Los paneles "módulo" los pedía el servidor (`SLoadModule(url, inventory)`) y se
  mostraban encima del juego; el menú del ordenador de a bordo era uno de ellos y **su HTML no se conserva**.
- Controles que mostraba la página (inglés): Mouse Controls = mover el ratón para girar, clic izquierdo recoge/coloca, "saltas
  automáticamente al empujar contra una pared". Classic = clic izquierdo mantenido para girar; E o CAPS recoge/coloca; WASD/flechas;
  Espacio o Control = jetpack; rueda = elegir; F2 captura; Enter pantalla completa; H casco. Notas: "limitado por Flash: sin
  control del botón derecho ni captura del cursor; Flash 11.2 debería reducir estas limitaciones" (de ahí nuestro bloqueo de ratón).
