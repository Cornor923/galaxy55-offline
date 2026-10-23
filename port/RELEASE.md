## Galaxy 55 (offline) v0.5 — port nativo para Windows (y Linux/macOS con HashLink)

Port **no oficial** de Galaxy 55 (Motion Twin, 2012) a una aplicación nativa (Haxe + Heaps + HashLink). Sin Flash, sin navegador y sin servidor.

**Cómo jugar (Windows):** descomprime la carpeta entera y haz doble clic en `jugar.bat`. Si no abre (equipos sin OpenGL 3.2 o máquinas virtuales), usa `jugar_dx.bat`, la versión DirectX. No hay que instalar nada. Las partidas se guardan en `%APPDATA%\Galaxy55\`.
**Linux y macOS:** zip aparte; necesita HashLink 1.16 instalado (ver su `LEEME.txt`).

### Novedades de la v0.5
- **Menú de inicio nuevo**: Continuar abre la lista de partidas (jugar, renombrar, borrar); Nueva partida pide nombre, semilla y modo (Creativo: bioma y tamaño; Aventura: tutorial sí/no).
- **Tutorial guiado** (añadido del port): las partidas de aventura nuevas empiezan en el espacio con el inventario vacío, como el original. Se puede saltar.
- Más del original: la cámara y el HUD tiemblan al romper bloques y al aterrizar; el **turbo minero** funciona; recuperas vida en tu nave; la **bomba exótica** explota; Mayús+K funde a blanco y te devuelve a la nave.
- Bajo el agua: campo de visión más estrecho y cielo del color del líquido; el nivel del mar baja al inundar huecos.
- Gráficos como el original: cielo estrellado en los planetas, mipmaps (el paisaje lejano ya no parpadea), marco de selección, bloques soltados, iconos y barra de carga.
- F2 guarda una captura sin el HUD; F muestra u oculta las coordenadas y los FPS.
- Hangar: soportes que funcionan, sin líquidos ni bomba, sin daño, puertas abiertas que ya no cuentan como agujero.
- Arreglos de **Cornor923** (¡gracias!, PR 17-59, también autor de casi todo lo anterior): oxígeno en creativo, hielo junto al agua, paleta creativa, tras morir te quedas en la nave, intercambios guardados en la nave nodriza, nave del mapa y más.

Todo en el [CHANGELOG](../CHANGELOG.md).

### Qué falta o falla
- Dar más uso a la velocidad en el viaje espacial (ideas en `IDEAS.md`), y más bloques activables.
- Lista completa de errores conocidos: `ERRORES.md` (español) / `BUGS.md` (inglés) / `BUGS.fr.md` (francés) en el repositorio.
- **El formato de las partidas puede cambiar entre versiones.**

---

## Galaxy 55 (offline) v0.5 — native port for Windows (and Linux/macOS with HashLink)

**Unofficial** port of Galaxy 55 (Motion Twin, 2012) to a native application (Haxe + Heaps + HashLink). No Flash, no browser and no server.

**How to play (Windows):** unzip the whole folder and double-click `jugar.bat`. If it doesn't open (PCs without OpenGL 3.2 or virtual machines), use `jugar_dx.bat`, the DirectX build. Nothing to install. Saves go to `%APPDATA%\Galaxy55\`.
**Linux and macOS:** separate zip; it needs HashLink 1.16 installed (see its `LEEME.txt`).

### New in v0.5
- **New start menu**: Continue opens the saved games list (play, rename, delete); New game asks for name, seed and mode (Creative: biome and size; Adventure: tutorial yes/no).
- **Guided tutorial** (port addition): new adventure games start in space with an empty inventory, like the original. It can be skipped.
- More from the original: the camera and the HUD shake when blocks break and when you land; the **mining turbo** works; you regain life in your ship; the **ancient bomb** explodes; Shift+K fades to white and takes you back to the ship.
- Under water: a narrower field of view and a sky the colour of the liquid; the sea level drops when flooding holes.
- Graphics like the original: starry sky on planets, mipmaps (the far landscape no longer flickers), selection frame, dropped blocks, icons and loading bar.
- F2 saves a screenshot without the HUD; F shows or hides the coordinates and FPS.
- Hangar: working supports, no liquids or bomb, no damage, open doors no longer count as holes.
- Fixes by **Cornor923** (thank you!, PRs 17-59, who also made almost everything above): oxygen in creative, ice next to water, creative palette, you stay in the ship after dying, trades saved in the mothership, the map's ship and more.

Everything in the [CHANGELOG](../CHANGELOG.en.md).

### Missing or broken
- Giving ship speed more use in space travel (ideas in `IDEAS.en.md`), and more activatable blocks.
- Full list of known bugs: `BUGS.md` (English) / `BUGS.fr.md` (French) / `ERRORES.md` (Spanish) in the repository.
- **The save format may change between versions.**

---

## Galaxy 55 (offline) v0.5 — portage natif pour Windows (et Linux/macOS avec HashLink)

Portage **non officiel** de Galaxy 55 (Motion Twin, 2012) en application native (Haxe + Heaps + HashLink). Sans Flash, sans navigateur et sans serveur.

**Comment jouer (Windows) :** décompresse tout le dossier et double-clique sur `jugar.bat`. S'il ne s'ouvre pas (PC sans OpenGL 3.2 ou machines virtuelles), utilise `jugar_dx.bat`, la version DirectX. Rien à installer. Les parties sont enregistrées dans `%APPDATA%\Galaxy55\`.
**Linux et macOS :** zip séparé ; il faut HashLink 1.16 installé (voir son `LEEME.txt`).

### Nouveautés de la v0.5
- **Nouveau menu de démarrage** : Continuer ouvre la liste des parties (jouer, renommer, supprimer) ; Nouvelle partie demande le nom, la graine et le mode (Créatif : biome et taille ; Aventure : tutoriel oui/non).
- **Tutoriel guidé** (ajout du port) : les nouvelles parties aventure commencent dans l'espace avec l'inventaire vide, comme l'original. On peut le passer.
- Encore de l'original : la caméra et le HUD tremblent quand un bloc casse et à l'atterrissage ; le **turbo minier** fonctionne ; tu récupères de la vie dans ton vaisseau ; la **bombe antique** explose ; Maj+K fait un fondu blanc et te ramène au vaisseau.
- Sous l'eau : champ de vision plus étroit et ciel de la couleur du liquide ; le niveau de la mer baisse en inondant les trous.
- Graphismes comme l'original : ciel étoilé sur les planètes, mipmaps (le paysage lointain ne scintille plus), cadre de sélection, blocs lâchés, icônes et barre de chargement.
- F2 enregistre une capture sans le HUD ; F affiche ou cache les coordonnées et les FPS.
- Hangar : supports qui fonctionnent, sans liquides ni bombe, sans dégâts, les portes ouvertes ne comptent plus comme des trous.
- Corrections de **Cornor923** (merci !, PR 17-59, auteur aussi de presque tout ce qui précède) : oxygène en créatif, glace près de l'eau, palette créative, on reste dans le vaisseau après la mort, échanges sauvés dans le vaisseau-mère, vaisseau de la carte et plus encore.

Tout est dans le [CHANGELOG](../CHANGELOG.fr.md).

### Ce qui manque ou ne marche pas
- Donner plus d'usage à la vitesse dans le voyage spatial (idées dans `IDEAS.fr.md`), et plus de blocs activables.
- Liste complète des bugs connus : `BUGS.fr.md` (français) / `BUGS.md` (anglais) / `ERRORES.md` (espagnol) dans le dépôt.
- **Le format des sauvegardes peut changer d'une version à l'autre.**

### Licencia / License / Licence
Código y datos de Galaxy 55 © Motion Twin, **CC BY-NC-SA 4.0**. Este port es una obra derivada bajo la misma licencia: uso no comercial y con crédito. Ver `LICENSE` y `NOTICE`.
