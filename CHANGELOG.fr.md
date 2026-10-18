# Nouveautés (version native)

[Español : `CHANGELOG.md`](CHANGELOG.md) · [English: `CHANGELOG.en.md`](CHANGELOG.en.md)

## v0.3.1 — pre-release
- Options : synchronisation verticale (VSync) et limite d'images par seconde (30, 60, 120, 144, 240 ou illimité).
- Corrections de **Cornor923** (merci !) : le voile des liquides et les fonds des menus couvrent les fenêtres plus larges
  que 16:9, plus de taches sombres à travers la glace, la tête ne rentre plus dans les kubes en tombant ou en flottant,
  `jugar.bat` utilise `hlw.exe` (sans console) s'il est présent, et un README en français.

## v0.3 — pre-release
- Hangar : refais ton vaisseau kube par kube, comme dans l'original ; on sort par le téléporteur pour l'enregistrer.
- Boutique : achète et vends des kubes contre des crédits, auprès du robot marchand.
- Son : les 12 effets de l'original (pas, saut, atterrissage, chute violente, jetpack, laser, casser et ramasser des kubes).
- Viseur fixe au centre de l'écran.
- Noms des kubes complets en espagnol, anglais et français (avant, ils sortaient en espagnol ou mélangés).
- Cantines : une pression les ouvre et maintenir le laser les casse (leur contenu tombe par terre). Dans ton vaisseau,
  l'ordinateur et les portes ne se cassent pas.
- Créatif : palette à la manette (R3), copier le kube visé (L3 ou clic du milieu) et deux nouveaux kubes, blindage jaune
  et noir, pour des bandes de danger.
- Vaisseau-mère : ciel d'espace profond (Voie lactée, nébuleuses, des milliers d'étoiles et des galaxies lointaines),
  places avec des bordures à bandes de danger et un éditeur (`editar_nodriza.bat`).
- Moins d'à-coups en cassant ou en posant des kubes, surtout dans le vaisseau-mère.
- Le rayon du téléporteur du vaisseau ne disparaît plus dans le brouillard de l'hiver.
- Corrections signalées par Sekhmet (merci !) : dans un liquide, l'écran et le brouillard prennent sa couleur, comme dans
  l'original (le sable mouvant ne paraît plus transparent) ; il ne neige plus sous l'eau ; l'eau a des faces latérales ;
  la glace immergée reste derrière l'eau ; textes de la carte stellaire traduits.
- Noms français originaux des biomes (Terres Rouges, Rocaille sombre, Sables arides), retrouvés par Sekhmet sur
  l'ancienne Twinpedia.
- Version DirectX en option (`haxe port\game_dx.hxml`, `jugar_dx.bat`), en plus de la version OpenGL.
- Vaisseau-mère : incassable, mieux éclairé, portes fermées, champs de force laser sur les hangars, 10 places marquées,
  ton vaisseau garé à la tienne (tu apparais dedans et son ordinateur te ramène), et une boutique avec un robot marchand
  animé dans le tunnel d'entrée.
- Manette : cantines, boutique et changement de case (LB/RB).
- Le jeu ne se fige plus quelques secondes au démarrage.
- `jugar.bat` fonctionne même si le PATH contient des dossiers avec des parenthèses.

## v0.2 — pre-release
- Carte stellaire avec les animations de l'original (entrée et sortie d'un système, hyperespace, flashs, attente du
  serveur), fond commun avec tourbillon ; les systèmes sont générés en arrière-plan, donc plus de blocage.
- Kube tenu en main et éclats en cassant, copiés de l'original.
- Cité morte au choix dans Nouvelle partie.
- Corrections : supprimer des parties, retirer la source de cascade du vaisseau, rotation des kubes lâchés, neige dans
  le vaisseau.
- Changements par rapport à l'original : le synthétiseur utilise les kubes de sa zone ; herbes et stalactites cassables ;
  courbure à 60 % ; les monticules de neige qui cachent une plante ressemblent à de la neige ; la caméra zoome sur la
  planète en y entrant.

## v0.1 — pre-release
Première version native publiée : menus et parties enregistrées, planètes identiques à celles de Flash,
creuser/poser/jetpack, mode créatif, vaisseau (téléporteur, portes, synthétiseur avec les recettes de l'original,
ordinateur), carte stellaire (secteur, systèmes, scan et atterrissage ; l'univers fait partie de la partie enregistrée)
et un paquet portable avec `jugar.bat`. Bugs connus : [`BUGS.md`](BUGS.md) (anglais).

L'ancienne version Flash a son propre historique dans [`docs/flash/CHANGELOG_flash.md`](docs/flash/CHANGELOG_flash.md) (espagnol).
