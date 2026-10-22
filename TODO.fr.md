# À faire (version native)

[Español : `PENDIENTES.md`](PENDIENTES.md) · [English: `TODO.md`](TODO.md)

Ordre approximatif. Ce qui est déjà fait se trouve dans [`CHANGELOG.fr.md`](CHANGELOG.fr.md) ; les bugs, dans
[`BUGS.fr.md`](BUGS.fr.md) ; les idées pour plus tard (carburant, déblocage des systèmes, équipement, multijoueur…), dans
[`IDEAS.fr.md`](IDEAS.fr.md). Les détails techniques de chaque point sont dans [`port/RESUMEN.md`](port/RESUMEN.md) (en espagnol).

1. **Améliorer le mode spatial** pour que le voyage et la vitesse du vaisseau comptent. Ce qu'on fera sera choisi dans
   [`IDEAS.fr.md`](IDEAS.fr.md) (section « Voyage spatial ») ; pour l'instant, le carburant est l'idée préférée.
2. **Carte stellaire :** vérifier s'il manque quelque chose aux particules des moteurs en marche. Les transitions d'origine,
   le fond commun avec son tourbillon, les particules du saut, l'éclat des réacteurs, les flèches GPS et le robot marchand
   sont faits.
3. **Hangar** (fait, à tester davantage). La vitesse sur la carte compte tous les moteurs, comme l'original (le message du
   hangar ne compte que ceux dont la sortie est libre, comme l'original aussi).
4. **Corriger les bugs** de [`BUGS.fr.md`](BUGS.fr.md).
5. **Eau :** à décider : lave + eau = basalte (voir [`IDEAS.fr.md`](IDEAS.fr.md)). L'eau qui s'écoule et les vagues de l'original sont faites.
6. Option de qualité pour les PC lents (on peut déjà désactiver les vagues de l'eau).
7. Plus de blocs activables (p. ex. la bombe antique, qui blesse aussi dans l'original) ; Cité morte.
8. Distribution : installateur, et évaluer SDL/DirectX.
9. À évaluer : **version web** (Heaps → JS/WebGL) pour Eternaltwin, multijoueur et Steam (voir [`IDEAS.fr.md`](IDEAS.fr.md)).
