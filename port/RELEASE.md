## Galaxy 55 (offline) v0.3.1 — port nativo para Windows (y Linux/macOS con HashLink)

Port **no oficial** de Galaxy 55 (Motion Twin, 2012) a una aplicación nativa (Haxe + Heaps + HashLink). Sin Flash, sin navegador y sin servidor.

**Cómo jugar (Windows):** descomprime la carpeta entera y haz doble clic en `jugar.bat`. Si no abre (equipos sin OpenGL 3.2 o máquinas virtuales), usa `jugar_dx.bat`, la versión DirectX. No hay que instalar nada. Las partidas se guardan en `%APPDATA%\Galaxy55\`.
**Linux y macOS:** zip aparte; necesita HashLink 1.16 instalado (ver su `LEEME.txt`).

### Novedades de la v0.3.1
- **Opciones:** sincronización vertical (VSync) y límite de FPS (30, 60, 120, 144, 240 o sin límite).
- **Sin consola negra:** el juego se abre sin la ventana de consola vacía (`hlw.exe`).
- Arreglos de **Cornor923** (¡gracias!): el velo del agua y los fondos de los menús cubren ventanas más anchas que 16:9, sin manchas oscuras a través del hielo, la cabeza ya no se mete en los bloques al caer o flotar con el jetpack, y README en francés.

Todo lo de la v0.3 (nave nodriza, hangar, tienda, sonido, mando, versión DirectX...) está en el [CHANGELOG](../CHANGELOG.md).

### Qué falta o falla
- Agua que fluye, vida/oxígeno/lava, el robot comerciante viajando por el mapa de estrellas.
- Lista completa de errores conocidos: `ERRORES.md` (español) / `BUGS.md` (inglés) en el repositorio.
- **El formato de las partidas puede cambiar entre versiones.**

---

## Galaxy 55 (offline) v0.3.1 — native port for Windows (and Linux/macOS with HashLink)

**Unofficial** port of Galaxy 55 (Motion Twin, 2012) to a native application (Haxe + Heaps + HashLink). No Flash, no browser and no server.

**How to play (Windows):** unzip the whole folder and double-click `jugar.bat`. If it doesn't open (PCs without OpenGL 3.2 or virtual machines), use `jugar_dx.bat`, the DirectX build. Nothing to install. Saves go to `%APPDATA%\Galaxy55\`.
**Linux and macOS:** separate zip; it needs HashLink 1.16 installed (see its `LEEME.txt`).

### New in v0.3.1
- **Options:** vertical sync (VSync) and FPS limit (30, 60, 120, 144, 240 or unlimited).
- **No black console:** the game opens without the empty console window (`hlw.exe`).
- Fixes by **Cornor923** (thank you!): the liquid veil and menu backgrounds cover windows wider than 16:9, no dark patches through ice, the head no longer clips into blocks when falling or hovering with the jetpack, and a French README.

Everything from v0.3 (mothership, hangar, shop, sound, gamepad, DirectX build...) is in the [CHANGELOG](../CHANGELOG.en.md).

### Missing or broken
- Flowing water, health/oxygen/lava, the merchant robot travelling on the star map.
- Full list of known bugs: `BUGS.md` (English) / `ERRORES.md` (Spanish) in the repository.
- **The save format may change between versions.**

### Licencia / License
Código y datos de Galaxy 55 © Motion Twin, **CC BY-NC-SA 4.0**. Este port es una obra derivada bajo la misma licencia: uso no comercial y con crédito. Ver `LICENSE` y `NOTICE`.
