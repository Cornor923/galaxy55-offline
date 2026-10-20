# Idées (version native)

[Español : `IDEAS.md`](IDEAS.md) · [English: `IDEAS.en.md`](IDEAS.en.md)

Des idées pour plus tard : **rien de tout cela n'est décidé ni commencé**. Ce qui va être fait se trouve dans
[`TODO.fr.md`](TODO.fr.md). La règle du projet reste la même : rester fidèle à l'original et ne pas casser l'immersion.
Avant d'ajouter quelque chose de nouveau, on en parle avec la communauté.

## Voyage spatial

L'exploration spatiale reste : elle fait partie de l'identité du jeu (Cornor923). Des idées pour que le voyage et la vitesse
du vaisseau (moteurs et poids, comme dans l'original) comptent davantage :

- **Carburant** (la préférée de Pvie ; Cornor923 est contre : le joueur pourrait rester bloqué) : voyager sur la carte consomme de l'énergie selon la distance ; un vaisseau
  lourd consomme plus. On le recharge avec des cristaux (Citronox, Etherium). Cela ajoute de la stratégie sans faire du
  voyage une corvée.
- **Débloquer des systèmes** (de l'original) : un tiers des systèmes sont verrouillés et s'ouvraient en payant une licence
  (1500). Le port affiche le cadenas, mais le bouton ne fait encore rien.
- **Des planètes lointaines plus riches** (Cornor923) : plus on s'éloigne du système de départ, plus il y a de minerais rares.
  Les biomes d'origine ne changent pas, seule la quantité de minerai change.
- **Une planète « base »** (Cornor923).
- **Un robot marchand qui va plus loin :** il voyage plus loin et part parfois vers des systèmes lointains ; un vaisseau
  rapide le rattrape plus vite.
- **Des quêtes ou des points fixes dans l'espace** (Cornor923) : Galaxy 55 fait partie de l'univers d'Alphabounce, dont le
  but était de découvrir des planètes et la Terre. Une histoire qui pousse à aller de système en système donnerait un usage
  à la vitesse.
- **Des moteurs sur les planètes :** ils existent déjà dans l'original et dans le port (même générateur) : la capsule écrasée
  (`detCapsule`) contient 2 moteurs, de la coque, des câbles et du verre. Elle apparaît sur ~0,1 % des petites planètes,
  ~0,3 % des moyennes et ~1 % des grandes (trouvé par Cornor923). Idée : la rendre un peu plus fréquente, ou ajouter
  d'autres épaves.

Base dans le code (v0.4) : `port/game/Space.hx` reçoit le décollage, la distance parcourue sur la carte (enregistrée dans
la partie), les changements de système, l'atterrissage (et peut l'empêcher), le bouton du cadenas et l'amarrage au robot.
Pour l'instant il ne change rien au jeu : chacune de ces idées s'y branche.

## Eau et lave

- **Lave + eau (ou cascade) = basalte** (souvenir de Sekhmet, « basalte infini »). Le code du client d'origine ne le fait pas :
  la lave remplace seulement l'eau et le basalte ne vient que du congélateur. Le serveur, jamais publié, le faisait
  peut-être. **À décider.**
- **Le niveau de la mer baisse** en remplissant les trous (souvenir de Sekhmet de la 3e version des alphas : la mer s'étend
  et le niveau global baisse selon la proportion eau/espace, sans jamais monter). Pour l'instant, la mer remplit tout jusqu'à
  son niveau, comme le code d'origine.
- **Un seau pour prendre de l'eau ou de la lave :** écarté pour l'instant (Cornor923 n'est pas convaincu : la combinaison
  « le fait déjà »).

## Équipement du personnage

Un inventaire d'équipement à part (casque, combinaison, sac à dos, bottes…) avec des améliorations fabriquées ou achetées au
robot : grand sac à dos (plus de carburant de jetpack), turbo de jetpack, recharge rapide, bottes de saut, bottes
antidérapantes (glace), amortisseurs (quand il y aura des dégâts de chute), meilleur laser de minage, sac agrandi, lampe de
casque, aimant pour les blocs tombés, combinaison thermique ou réservoir d'oxygène (quand il y aura l'oxygène et les dégâts).

## Nouveau contenu

- **Contenu de Kube** (le jeu de blocs précédent de Motion Twin) sous forme de nouvelles planètes, sans toucher aux planètes
  d'origine (Cornor923).
- **Fossiles :** dans l'original, ils ne servaient à rien et demandaient le laser violet, très rare (Cornor923). Leur donner une utilité.

## Multijoueur et web

- **Version web sur Eternaltwin :** Biosha propose de l'héberger avec un serveur (PostgreSQL, Node/Rust/PHP, connexion OAuth).
  Il faut d'abord qu'elle fonctionne dans le navigateur pour un joueur, et il reste beaucoup à faire.
- **Vaisseaux des joueurs :** 17×17×14 au maximum (le hangar d'origine) ; ils se garent dans des baies (vaisseau mère, guildes).
- **Vaisseaux de guilde :** plus grands, avec un hangar partagé et des permissions pour casser des blocs. Ils ne se garent
  pas à l'intérieur : ils s'amarrent de l'extérieur avec des tubes d'amarrage.
- **Boutiques de joueurs :** des stands dans la zone de commerce du vaisseau mère ou un comptoir sur un vaisseau de guilde ;
  un tableau d'offres entre joueurs.
- Penser aux performances dans le navigateur (petits mondes fixes, maillages qui ne sont pas reconstruits, limite de joueurs visibles).
