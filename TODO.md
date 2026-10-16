# To do (native version)

[Español: `PENDIENTES.md`](PENDIENTES.md)

Roughly in order. What is already done is in [`CHANGELOG.en.md`](CHANGELOG.en.md); bugs are in [`BUGS.md`](BUGS.md);
technical details of each item are in [`port/RESUMEN.md`](port/RESUMEN.md) (Spanish).

1. **Star map:** the transitions are now the original ones (v0.2). Still missing: the ship's engine particles and the
   arrows (GPS) to active planets.
2. **Merchant robot** (in progress): dynamic trading is done (credits in the save, prices drop when you sell a lot and rise
   when scarce, stock refills; see `port/game/Market.hx`) and the shop window, for now opened from the ship's computer.
   Still to do: the robot travelling slowly on the map (and our ship's real speed from engines and weight), and the
   mothership: an empty "planet" with a space sky, our ship parked in one of its bays (the others for multiplayer) and the
   shop inside. Later, an offer board between players.
3. **Hangar:** edit and validate the ship (the edited ship will be shown on the map; its speed depends on engines and weight).
4. **Fix the bugs** in [`BUGS.md`](BUGS.md).
5. **Flowing water** (the original `Process.hx` logic) and animated texture.
6. Show the selected block in the hand; quality option for slow PCs.
7. **Sound**, health/damage/oxygen/lava, chests and activatable blocks, Dead City and Shed.
8. Packaging: installer, and evaluate SDL/DirectX.
9. To evaluate: **web version** (Heaps to JS/WebGL), **multiplayer** and Steam.
