# To do (native version)

[Español: `PENDIENTES.md`](PENDIENTES.md) · [Français : `TODO.fr.md`](TODO.fr.md)

Roughly in order. What is already done is in [`CHANGELOG.en.md`](CHANGELOG.en.md); bugs are in [`BUGS.md`](BUGS.md); ideas
for later (fuel, unlocking systems, equipment, multiplayer…) are in [`IDEAS.en.md`](IDEAS.en.md). Technical details of each
item are in [`port/RESUMEN.md`](port/RESUMEN.md) (Spanish).

1. **Improve the space mode** so that travel and the ship's speed matter. What to do is chosen from
   [`IDEAS.en.md`](IDEAS.en.md) ("Space travel" section); for now, fuel is the favourite.
2. **Star map:** check whether anything is missing from the running-engine particles. The original transitions, the common
   background with its whirlpool, jump particles, reactor flash, GPS arrows and the merchant robot are done.
3. **Hangar** (done, needs more testing). Speed on the map counts all engines, like the original (the hangar message only
   counts the ones with a free exhaust, also like the original).
4. **Fix the bugs** in [`BUGS.md`](BUGS.md).
5. **Water:** to decide: lava + water = basalt (see [`IDEAS.en.md`](IDEAS.en.md)). Flowing water and the original's waves are done.
6. Quality option for slow PCs (water waves can already be turned off).
7. More activatable blocks (e.g. the ancient bomb, which also hurts in the original); Dead City and Shed.
8. Packaging: installer, and evaluate SDL/DirectX.
9. To evaluate: **web version** (Heaps to JS/WebGL) for Eternaltwin, multiplayer and Steam (see [`IDEAS.en.md`](IDEAS.en.md)).
