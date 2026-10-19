# To do (native version)

[Español: `PENDIENTES.md`](PENDIENTES.md)

Roughly in order. What is already done is in [`CHANGELOG.en.md`](CHANGELOG.en.md); bugs are in [`BUGS.md`](BUGS.md);
technical details of each item are in [`port/RESUMEN.md`](port/RESUMEN.md) (Spanish).

1. **Star map:** the transitions are now the original ones (v0.2). The jump particles, the reactor flash and the
   arrows (GPS) to visited planets are done. Still missing: the "common room" (whirlpool); check whether anything is missing
   from the running-engine particles.
2. **Merchant robot** (done): dynamic trading (credits in the save, prices drop when you sell a lot and rise when scarce,
   stock refills; see `port/game/Market.hx`) and its ship on the map: it travels slowly between the sector's systems (orange
   GPS arrow); click it and it stops and waits, your ship flies at its speed (engines and weight from the hangar) and docking
   takes you into the mothership, with the shop and your ship parked. Later, an offer board between players.
3. **Hangar** (done, needs more testing): shed and validation copied from the original; entered from the computer. The edited ship is used on the planet and on the map.
3b. **Player equipment** (port addition, after the hangar): a separate equipment inventory (helmet, suit, backpack,
   boots...) with upgrades crafted or bought from the robot. Examples: bigger jetpack tank, jetpack turbo, fast refuel,
   jump boots, anti-slip boots (ice), shock absorbers (fall damage), better digger, bigger bag, helmet lamp,
   magnet (pick up drops from farther), thermal suit / oxygen tank (once health and oxygen exist).
4. **Fix the bugs** in [`BUGS.md`](BUGS.md).
5. **Flowing water** (done: `port/game/WorldProcess.hx`, the original `Process.hx`). The sea fills completely up to its level,
   like the original; cascades and player-placed water get lower at each step, with a sloped surface; lava stays as in the
   original (a solid block that goes through water). Still to do: animated texture. **To decide:** cascade (or water) + lava =
   basalt, as Sekhmet remembers; the original client code doesn't do it (maybe the unpublished server did). Bucket idea
   dropped for now. See Sekhmet's notes in `PENDIENTES.md` point 5.
6. Quality option for slow PCs (the selected block has been shown in the hand since v0.2).
7. Health/damage/oxygen/lava, more activatable blocks, Dead City and Shed (sound and chests have been done since v0.3).
8. Packaging: installer, and evaluate SDL/DirectX.
9. To evaluate: **web version** (Heaps to JS/WebGL), **multiplayer** and Steam. Eternaltwin (Biosha) offers to host it with
   a backend (PostgreSQL, Node/Rust/PHP, OAuth login): first, get the game running in a browser for one player.
10. **Ideas from Cornor923 for later** (space travel stays: it is part of the game's identity): richer distant planets, a
   "base" planet, Kube content as new planets (leaving the original ones untouched). Ship speed: the original only counted
   engines with a free exhaust; the port counts all of them.
