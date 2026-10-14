# Hallazgos del Discord de Eternaltwin (#g55) y de las búsquedas

- Export del canal (Discrub, 808 mensajes 2020-2026) analizado. Nombres de usuarios no se incluyen aquí.
- `client_ship.swf` (subido por el usuario toad06 el 1-ene-2023): "versión un poco trasteada para integrar la nave en la demo" + otra planeta por defecto. No es oficial; mismo cliente, 5 métodos y 1 cadena distintos, nombres en francés.
- Los últimos swf oficiales son client_en / client_fr de Motion Twin (v17-32 de data.galaxy55.com idénticos). La demo se describe como "alfa 1, un solo planeta, sin guardado" por la comunidad; el código (editor, mapa, licencias) parece nivel alfa 3 sin servidor.
- Repo GitLab eternaltwin/galaxy55/galaxy55: solo un esqueleto de servidor TypeScript (planet service getPlayersOnPlanet). Sin juego.
- Repo GitHub AlexandreVolts/G55 (MIT): prototipo BabylonJS de ~740 líneas, 1 planeta. Sin nada del original.
- Heaps (motor Haxe) nació de G55 según comentarios.
- Ideas de la comunidad: hacer un servidor para G55 ("faudrait qu'on fasse un serveur"), reversar la generación de planetas (booti386), "la gen" pasarla al servidor como Kube.
- El usuario NO quiere vender el juego; idea: usar online de Steam solo como transporte multijugador (requeriría AppID y envoltorio nativo; alternativa: servidor propio).
