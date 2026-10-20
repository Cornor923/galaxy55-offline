# Bugs connus (version native)

[Español : `ERRORES.md`](ERRORES.md) · [English: `BUGS.md`](BUGS.md)

Si tu en trouves un qui n'est pas dans la liste, ouvre une *issue* avec ce que tu faisais et, si possible, une capture d'écran.
Les bugs corrigés sont déplacés à la fin. Les détails techniques sont dans [`port/RESUMEN.md`](port/RESUMEN.md) (en espagnol).

## Ouverts

| # | Où | Ce qui se passe |
|---|---|---|
| 4 | Éclairage | **À vérifier en jouant :** les blocs partiels (plaques, fer, coffres…) prennent maintenant la lumière de chaque coin dans les cellules voisines, comme l'original (`Builder.addCustomQuad`) ; avant, toute la face avait une seule lumière. Les modèles utilisaient déjà la lumière de l'original. |
| 8 | Hiver | Les **feuilles d'épicéa** donnent du matériau ; dans l'original, peut-être pas. |
| 10 | Rendu | Les **cristaux** tombés (charges) paraissent trop larges. |
| 14 | Eau | **(À corriger ?)** Quand on ouvre une grotte à côté de la mer, l'eau entre et la remplit d'un coup à la même hauteur que la mer, sans baisser en avançant. C'est ce que fait l'original (la mer remplit tout ce qui est sous son niveau) et ce qu'a demandé Cornor923, mais ça paraît peu naturel. Alternative : que la mer descende par paliers comme la cascade (voir [`IDEAS.fr.md`](IDEAS.fr.md)). En parler avec Cornor923 avant de le changer. |

## Corrigés

- Prochaine version : le menu utilise une seule petite planète de fond (avant, trois grandes qui changeaient toutes les 22 s) : plus de saccades pendant leur génération ; il reste un arrêt d'environ 0,4 s au début, quand la planète est dessinée pour la première fois (#13). La cascade ne gèle pas à côté de la glace, seulement avec le congélateur, comme l'original (#12, vérifié).
- Prochaine version (signalés par **Sekhmet**, merci !) : l'eau s'écoule (`WorldProcess.hx`, le `Process.hx` d'origine) ; on peut poser des blocs sous l'eau ; il ne neige plus sous un toit ni dans les grottes ; la glace ne laisse plus de bloc en la cassant (comme l'original) ; raccourcis clavier (Tab creuse et 1–0 sont les 10 cases ; la dernière n'avait pas de touche).
- Prochaine version : le bloc tenu en main ne tremble plus en marchant ; la surbrillance de la palette du mode créatif ne reste plus collée.
- Prochaine version : le jeu fonctionne aussi avec DirectX (`port/game_dx.hxml`), utile là où OpenGL 3.2 manque (par ex. les machines virtuelles).
- Prochaine version : la couche 0 (roche mère) est dessinée, comme dans l'original : le fond d'un trou creusé jusqu'à elle ne laisse plus voir le vide et le ciel sous la planète.
- Prochaine version : le synthétiseur utilise d'abord les blocs de l'inventaire, comme l'original : tant que l'inventaire les a tous, les blocs posés dans sa zone restent comme modèle et on peut fabriquer la même recette encore et encore ; s'il en manque un, ce sont les blocs posés qui sont consommés (le changement de la v0.2 est annulé).
- v0.3 (trouvés et signalés par **Sekhmet**, merci !) : les sables mouvants et l'eau ne paraissent plus transparents de l'intérieur (voile et brouillard de la couleur du liquide, comme l'original) ; il ne neige plus sous l'eau ; l'eau a des faces latérales et de fond ; la glace immergée reste derrière l'eau ; les textes de la carte stellaire suivent la langue choisie.

- v0.2 (changement par rapport à l'original) : les monticules de neige qui cachent une plante (`BWinterHidden`) ressemblent à la neige normale, sans lueur propre.
- v0.2 : supprimer une partie depuis le menu (bouton Supprimer, puis choisir la partie ; la confirmation ne s'ouvre plus deux fois).
- v0.2 : il ne neige plus dans le vaisseau.
- v0.2 : la carte ne se bloque plus en entrant dans un système (il est généré en arrière-plan pendant le voyage).
- v0.2 (changement par rapport à l'original) : en entrant sur une planète, la caméra s'en approche au lieu d'un fondu au noir, et le nom ne s'affiche qu'une fois.
- v0.2 : on peut retirer la source de cascade (on la vise comme dans l'original).
- v0.2 : des particules quand on casse un bloc ; les blocs tombés tournent à la vitesse de l'original.
- v0.2 : la Cité morte peut être choisie dans Nouvelle partie (Shed pas encore).
- v0.2 (changement par rapport à l'original) : la courbure de la planète vaut 60 % de celle de l'original (elle se voyait trop, surtout sur les petites planètes).
- v0.2 : le bloc choisi se voit dans la main.
- v0.2 : carte stellaire avec les animations d'origine : entrer dans un système et en sortir (zoom, hyperespace, éclats ; la sortie laisse passer l'anneau et t'éjecte un peu plus tard), scanner (fondu, nom et barre) et atterrir ; fond commun avec tourbillon.
- v0.2 (changement par rapport à l'original) : le synthétiseur consomme toujours les blocs posés dans sa zone.
- v0.2 (changement par rapport à l'original) : les herbes du sol et les stalactites de glace se cassent ; elles donnent de l'herbe haute (33 %) ou de la glace (7 %), comme les plantes et la glace noire de l'original.

- Apparaître « dans le ciel » en entrant dans le synthétiseur (pas revu depuis).
- Les blocs du synthétiseur se dupliquaient quand on les posait.
- Écran noir au décollage vers la carte stellaire.
- Revenir d'une planète laissait le vaisseau hors de sa galaxie (il revient maintenant à côté de la planète).
