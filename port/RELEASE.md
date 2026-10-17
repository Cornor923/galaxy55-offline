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

**English:** unofficial native port of Motion Twin's Galaxy 55 (2012). Windows: unzip the whole folder and run `jugar.bat` (OpenGL) or `jugar_dx.bat` (DirectX, for PCs without OpenGL 3.2 or virtual machines). Linux/macOS: separate zip, needs HashLink 1.16. New in v0.3: the mothership (your parked ship, laser force fields, a merchant robot shop, deep space sky), sound effects, gamepad support for chests/shop/palette, a DirectX build, complete block names in three languages, and fixes reported by Sekhmet (thank you!). Known bugs: `BUGS.md`.

### Licencia / License
Código y datos de Galaxy 55 © Motion Twin, **CC BY-NC-SA 4.0**. Este port es una obra derivada bajo la misma licencia: uso no comercial y con crédito. Ver `LICENSE` y `NOTICE`.
