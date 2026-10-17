## Galaxy 55 (offline) v0.3 — port nativo para Windows (y Linux/macOS con HashLink)

Port **no oficial** de Galaxy 55 (Motion Twin, 2012) a una aplicación nativa (Haxe + Heaps + HashLink). Sin Flash, sin navegador y sin servidor.

**Cómo jugar (Windows):** descomprime la carpeta entera y haz doble clic en `jugar.bat`. Si no abre (equipos sin OpenGL 3.2 o máquinas virtuales), usa `jugar_dx.bat`, la versión DirectX. No hay que instalar nada. Las partidas se guardan en `%APPDATA%\Galaxy55\`.
**Linux y macOS:** zip aparte; necesita HashLink 1.16 instalado (ver su `LEEME.txt`).

### Novedades de la v0.3
- **Nave nodriza:** se entra desde el ordenador de tu nave. Tu nave aparece aparcada en tu plaza del hangar, hay campos de fuerza láser, un robot comerciante con su tienda en el túnel de entrada y un cielo de espacio profundo (Vía Láctea, nebulosas, miles de estrellas). Se vuelve con el ordenador de tu nave aparcada. La nave nodriza no se puede romper.
- **Sonido:** los efectos del original (pasos, salto, aterrizaje, jetpack, láser, romper y recoger bloques).
- **Mando:** cofres, tienda, paleta creativa y cambio de casilla.
- **Versión DirectX** (`jugar_dx.bat`) además de la de OpenGL.
- **Nombres de los bloques** completos en español, inglés y francés.
- Punto de mira fijo; los cofres se rompen manteniendo el láser; en creativo, copiar el bloque apuntado y dos bloques nuevos (blindaje amarillo y negro).
- Arreglos reportados por **Sekhmet** (¡gracias!): dentro de un líquido la pantalla toma su color, no nieva bajo el agua, el agua tiene caras laterales, el hielo sumergido, textos del mapa traducidos y nombres franceses originales de los biomas.
- El juego ya no se congela al arrancar y hay menos tirones al romper o poner bloques.

### Qué falta o falla
- Agua que fluye, vida/oxígeno/lava, el robot comerciante viajando por el mapa de estrellas.
- Lista completa de errores conocidos: `ERRORES.md` (español) / `BUGS.md` (inglés) en el repositorio.
- **El formato de las partidas puede cambiar entre versiones.**

---

## Galaxy 55 (offline) v0.3 — native port for Windows (and Linux/macOS with HashLink)

**Unofficial** port of Galaxy 55 (Motion Twin, 2012) to a native application (Haxe + Heaps + HashLink). No Flash, no browser and no server.

**How to play (Windows):** unzip the whole folder and double-click `jugar.bat`. If it doesn't open (PCs without OpenGL 3.2 or virtual machines), use `jugar_dx.bat`, the DirectX build. Nothing to install. Saves go to `%APPDATA%\Galaxy55\`.
**Linux and macOS:** separate zip; it needs HashLink 1.16 installed (see its `LEEME.txt`).

### New in v0.3
- **Mothership:** you enter it from your ship's computer. Your ship is parked in your bay of the hangar, there are laser force fields, a merchant robot with its shop in the entrance tunnel and a deep space sky (Milky Way, nebulae, thousands of stars). You go back with the computer of your parked ship. The mothership can't be broken.
- **Sound:** the original effects (footsteps, jump, landing, jetpack, laser, breaking and picking up blocks).
- **Gamepad:** chests, shop, creative palette and slot switching.
- **DirectX build** (`jugar_dx.bat`) besides the OpenGL one.
- **Block names** complete in Spanish, English and French.
- Fixed crosshair; chests break when you hold the laser; in creative, copy the targeted block and two new blocks (yellow and black plating).
- Fixes reported by **Sekhmet** (thank you!): inside a liquid the screen takes its colour, no snow under water, water has side faces, submerged ice, star map texts translated and the original French biome names.
- The game no longer freezes at startup and there are fewer hitches when breaking or placing blocks.

### Missing or broken
- Flowing water, health/oxygen/lava, the merchant robot travelling on the star map.
- Full list of known bugs: `BUGS.md` (English) / `ERRORES.md` (Spanish) in the repository.
- **The save format may change between versions.**

### Licencia / License
Código y datos de Galaxy 55 © Motion Twin, **CC BY-NC-SA 4.0**. Este port es una obra derivada bajo la misma licencia: uso no comercial y con crédito. Ver `LICENSE` y `NOTICE`.
