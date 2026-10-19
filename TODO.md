# To do (native version)

[Español: `PENDIENTES.md`](PENDIENTES.md)

Roughly in order. What is already done is in [`CHANGELOG.en.md`](CHANGELOG.en.md); bugs are in [`BUGS.md`](BUGS.md);
technical details of each item are in [`port/RESUMEN.md`](port/RESUMEN.md) (Spanish).

1. **Star map:** the transitions are now the original ones (v0.2). The jump particles, the reactor flash and the
   arrows (GPS) to visited planets are done. Still missing: the "common room" (whirlpool); check whether anything is missing
   from the running-engine particles.
2. **Merchant robot** (in progress): dynamic trading is done (credits in the save, prices drop when you sell a lot and rise
   when scarce, stock refills; see `port/game/Market.hx`) and the shop window, for now opened from the ship's computer.
   Still to do: the robot travelling slowly on the map (and our ship's real speed from engines and weight), and the
   mothership: an empty "planet" with a space sky, our ship parked in one of its bays (the others for multiplayer) and the
   shop inside. Later, an offer board between players.
3. **Hangar** (done, needs more testing): shed and validation copied from the original; entered from the computer. The edited ship is used on the planet and on the map. Still to do: the robot travelling on the map with each ship's real speed.
3b. **Player equipment** (port addition, after the hangar): a separate equipment inventory (helmet, suit, backpack,
   boots...) with upgrades crafted or bought from the robot. Examples: bigger jetpack tank, jetpack turbo, fast refuel,
   jump boots, anti-slip boots (ice), shock absorbers (fall damage), better digger, bigger bag, helmet lamp,
   magnet (pick up drops from farther), thermal suit / oxygen tank (once health and oxygen exist).
4. **Fix the bugs** in [`BUGS.md`](BUGS.md).
5. **Flowing water** (the original `Process.hx` logic) and animated texture; idea: a bucket to pick up water or lava (recipe to be decided). See Sekhmet's notes on cascades, lava and sea level in `PENDIENTES.md` point 5.
6. Quality option for slow PCs (the selected block has been shown in the hand since v0.2).
7. Health/damage/oxygen/lava, more activatable blocks, Dead City and Shed (sound and chests have been done since v0.3).
8. Packaging: installer, and evaluate SDL/DirectX.
9. To evaluate: **web version** (Heaps to JS/WebGL), **multiplayer** and Steam.
