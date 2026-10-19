# Port natif (Haxe 4 + Heaps + HashLink)

[Español : `LEEME.md`](LEEME.md) · [English: `README.md`](README.md)

Ce dossier contient le portage du jeu en application de bureau native, sans Flash. C'est un travail en cours (avec des bugs
connus, voir `BUGS.fr.md` à la racine du dépôt) ; le jeu Flash d'origine reste intact dans `src/`, `libs/` et `release/`, et dans la branche `flash`.

## Jouer

Compile-le (voir plus bas) et double-clique sur `jugar.bat`, ou télécharge le zip portable depuis la
[release](../../../releases/tag/v0.3.1). Le menu de démarrage propose Continuer, Nouvelle partie, Charger une partie, Options et Quitter.
Dans Nouvelle partie, tu choisis le nom, la graine, le biome, la taille et le mode : **Aventure** (comme dans l'original) ou **Créatif** (notre ajout).
Les parties et les réglages sont enregistrés dans `%APPDATA%\Galaxy55\` (modifiable avec la variable d'environnement `GALAXY55_DATA`).
Le format des sauvegardes peut changer d'une version à l'autre : ne compte pas sur le fait que les parties d'aujourd'hui fonctionnent toujours.

## Commandes

Ce sont celles du jeu original (le déplacement et la physique sont copiés de `ent/Hero.hx` et `Game.moveHero`).

| Action | Touches |
|---|---|
| Se déplacer | W/Z/↑ avancer, S/↓ reculer, A/D et ←/→ de côté (dans les Options, elles peuvent faire tourner, comme dans l'original) |
| Regarder | souris (ou manette) |
| Sauter et jetpack | Espace ou Ctrl ; en l'air, jetpack (consomme du carburant, se recharge au sol) |
| Marcher lentement | X |
| Casque | H l'enlève ou le remet |
| Creuser ou poser | clic gauche, E ou Maj (maintenir). Main vide : tu creuses ; avec un bloc, tu le poses si quelque chose le soutient |
| Choisir une case | 1–0 ou molette de la souris ; Tab = laser de minage (main vide) |
| Jeter la pile choisie | R ou Suppr |
| Activer (ordinateur de bord, portes) | viser, appuyer et relâcher |
| Retourner au vaisseau | Maj+K, ou entrer dans le rayon de lumière d'atterrissage |
| Créatif : palette de blocs | I (clic = mettre le bloc dans la case choisie, molette = page) |
| Pause | Échap |
| Sauvegarde rapide | F5 |

Il n'y a pas de touche pour courir, comme dans l'original. Manette : stick gauche pour se déplacer, stick droit pour regarder,
A saute et jetpack, B marche lentement, RT creuse, LT pose, RB/LB ou croix droite/gauche changent de case, Y jette, Back casque,
Start pause. Menus : flèches/Entrée/Échap, souris ou manette.

## Compiler

Il faut (Windows) :
1. **Haxe 4.3.x** (https://haxe.org/download/) et **HashLink 1.16** pour Windows (https://github.com/HaxeFoundation/hashlink/releases).
   Ajoute les dossiers au `PATH` ; `haxe` et `hl` doivent fonctionner dans un terminal.
2. Les bibliothèques Haxe :

       haxelib install format
       haxelib git heaps https://github.com/HeapsIO/heaps
       haxelib git hashlink https://github.com/HaxeFoundation/hashlink
       haxelib dev hlsdl <dossier-où-tu-as-cloné-hashlink>/libs/sdl

   (`hlsdl` a besoin des sources de HashLink : clone ce dépôt et fais pointer `haxelib dev` vers son dossier `libs/sdl`.)
   C'est ainsi qu'est configurée la machine de développement (Heaps de la branche principale, HashLink 1.16, sans droits
   d'administrateur). **Ce n'a pas été testé depuis zéro sur une autre machine** : si quelque chose échoue, ouvre une *issue*.
3. Depuis la racine du dépôt :

       haxe port\game.hxml          jeu complet avec les menus   (-> port\out\galaxy55.hl)
       haxe port\render.hxml        test technique du rendu      (-> port\out\render.hl)
       haxe port\headless.hxml      générateur de planètes sans écran, HashLink
       haxe port\headless_flash.hxml  le même programme pour Flash (référence)

`jugar.bat` cherche `hl` dans le `PATH` ; s'il est ailleurs, indique d'abord son chemin dans la variable `HL`.

### Version DirectX (optionnelle)

Pour les machines sans OpenGL 3.2 (par exemple des machines virtuelles avec un GPU partagé), il existe une version DirectX 11 :

       haxelib dev hldx <dossier-où-tu-as-cloné-hashlink>/libs/directx
       haxe port\game_dx.hxml       (-> port\out\galaxy55_dx.hl, à lancer avec jugar_dx.bat)

Problème connu : si les sources de `hldx` sont plus récentes que ton `directx.hdll` (binaire de HashLink 1.16 + hashlink de git),
changer le mode d'affichage échoue avec « Primitive or library is missing ». Corrige-le dans `libs/directx/dx/Window.hx`,
`set_displayMode` : entoure le corps de `try { ... } catch( e : Dynamic ) { winSetFullscreen(win, mode != Windowed); }`. Utiliser
un `hldx` qui correspond à ta version de HashLink évite le problème.
Le jeu cherche les graphismes d'origine dans `res\` (paquet portable) ou, à défaut, dans `src\G55\fla\client\gfx\` ; la variable `GALAXY55_RES` impose un autre dossier.

### Autres plateformes

Procure-toi une version de HashLink pour ta plateforme, copie `galaxy55.hl` dans son dossier sous le nom `hlboot.dat`, place le
dossier `res/` à côté et lance `hl`. Un joueur l'a fait fonctionner ainsi sous Linux ; nous ne l'avons pas testé.

## Contenu du dossier

- `game/` le jeu : menus (`GalaxyApp`, `Ui`), langues (`Lang`), réglages (`Settings`), sauvegardes (`SaveData`), planète, lumière et
  maillage (`World`), écoulement de l'eau (`WorldProcess`), modèles de blocs (`Models`), ciel et brouillard (`Sky`), neige (`Snow`),
  joueur, creuser et poser (`GameView`), inventaire (`Inv`, `InvBar`, `Palette`), effets et objets tombés (`Fx`, `Drops`) et le
  vaisseau (`Ship`, `ShipData`).
- `explore/` la carte stellaire (`Explorer`, avec le robot marchand et les flèches GPS).
- `shim/` couche de compatibilité `flash.*` pour que les générateurs d'origine compilent en HashLink.
- `headless/` programmes de vérification : les mondes sont identiques à ceux de Flash (empreinte Adler-32, eau et blocs) ; ils lisent aussi le vaisseau et les sauvegardes.

## Différences avec l'original

- Le ciel, le dégradé et le brouillard utilisent les couleurs d'origine de chaque biome. Les étoiles sont celles du port.
- La neige du biome d'hiver est un ajout du port : l'original ne l'a pas.
- Le mode créatif et sa palette sont un ajout du port.
- Le menu de l'ordinateur de bord a son propre style, comme dans la version Flash (l'original était une page web).
- La boutique du robot marchand (dans l'original, c'était un panneau web), son vaisseau sur la carte stellaire et la flèche
  GPS orange qui le désigne sont des ajouts du port.
- Les cascades et l'eau posée par le joueur baissent à chaque pas, avec une surface inclinée : ajout du port. La mer remplit
  les trous jusqu'à son niveau, comme l'original.
- Options ajoutées : ombre du bloc que tu vas poser et nom du bloc visé.
- Ce qui manque est dans `TODO.fr.md`, les bugs dans `BUGS.fr.md` et les idées pour plus tard dans `IDEAS.fr.md` (racine du dépôt).
