# To do (native version)

[Español: `PENDIENTES.md`](PENDIENTES.md) · [Français : `TODO.fr.md`](TODO.fr.md)

Roughly in order. What is already done is in [`CHANGELOG.en.md`](CHANGELOG.en.md); bugs are in [`BUGS.md`](BUGS.md); ideas
for later (fuel, unlocking systems, equipment, multiplayer…) are in [`IDEAS.en.md`](IDEAS.en.md). Technical details of each
item are in [`port/RESUMEN.md`](port/RESUMEN.md) (Spanish).

1. **Improve the space mode** so that travel and the ship's speed matter. What to do is chosen from
   [`IDEAS.en.md`](IDEAS.en.md) ("Space travel" section); for now, fuel is the favourite.
2. **Star map:** check whether anything is missing from the running-engine particles. The original transitions, the common
   background with its whirlpool, jump particles, reactor flash, GPS arrows and the merchant robot are done.
3. **Hangar** (done, needs more testing). Ship speed: the original only counted engines with a free exhaust; the port
   counts all of them.
4. **Fix the bugs** in [`BUGS.md`](BUGS.md).
5. **Water:** animated texture. Flowing water is done (`port/game/WorldProcess.hx`, the original `Process.hx`): the sea fills
   completely up to its level; cascades and player-placed water get lower at each step. To decide: lava + water = basalt
   (see [`IDEAS.en.md`](IDEAS.en.md)).
6. Quality option for slow PCs.
7. Health, damage, oxygen and lava; more activatable blocks; Dead City and Shed.
8. Packaging: installer, and evaluate SDL/DirectX.
9. To evaluate: **web version** (Heaps to JS/WebGL) for Eternaltwin, multiplayer and Steam (see [`IDEAS.en.md`](IDEAS.en.md)).
