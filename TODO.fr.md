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
3. **Hangar** (fait, à tester davantage). Vitesse du vaisseau : l'original ne comptait que les moteurs dont la sortie était
   libre ; le port les compte tous.
4. **Corriger les bugs** de [`BUGS.fr.md`](BUGS.fr.md).
5. **Eau :** texture animée. L'eau qui s'écoule est faite (`port/game/WorldProcess.hx`, le `Process.hx` d'origine) : la mer
   remplit tout jusqu'à son niveau ; les cascades et l'eau posée par le joueur baissent à chaque pas. À décider :
   lave + eau = basalte (voir [`IDEAS.fr.md`](IDEAS.fr.md)).
6. Option de qualité pour les PC lents.
7. Vie, dégâts, oxygène et lave ; plus de blocs activables ; Cité morte et Shed.
8. Distribution : installateur, et évaluer SDL/DirectX.
9. À évaluer : **version web** (Heaps → JS/WebGL) pour Eternaltwin, multijoueur et Steam (voir [`IDEAS.fr.md`](IDEAS.fr.md)).
