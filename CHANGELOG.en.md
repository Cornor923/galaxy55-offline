# Changelog (native version)

[Español: `CHANGELOG.md`](CHANGELOG.md) · [Français : `CHANGELOG.fr.md`](CHANGELOG.fr.md)

## v0.3.1 — pre-release
- Options: vertical sync (VSync) and FPS limit (30, 60, 120, 144, 240 or unlimited).
- Fixes by **Cornor923** (thank you!): the liquid veil and menu backgrounds cover windows wider than 16:9, no dark
  patches through ice, the head no longer clips into blocks when falling or hovering, `jugar.bat` uses `hlw.exe` (no
  console) when present, and a French README.

## v0.3 — pre-release
- Hangar: rebuild your ship block by block, like in the original; leave through the teleporter to save it.
- Shop: buy and sell blocks for credits, with the merchant robot.
- Sound: the 12 original effects (footsteps, jump, landing, hard fall, jetpack, laser, breaking and picking up blocks).
- Fixed crosshair in the centre of the screen.
- Complete block names in Spanish, English and French (they used to show in Spanish or mixed).
- Chests: a tap opens them and holding the laser breaks them (their contents drop). In your ship, the computer and the
  doors can't be broken.
- Creative: palette with the gamepad (R3), copy the targeted block (L3 or middle click) and two new blocks, yellow and
  black plating, for hazard stripes.
- Mothership: deep space sky (Milky Way, nebulae, thousands of stars and distant galaxies), bays with hazard-stripe
  borders and an editor (`editar_nodriza.bat`).
- Fewer hitches when breaking or placing blocks, especially in the mothership.
- The ship teleport beam no longer disappears in the winter fog.
- Fixes reported by Sekhmet (thank you!): inside a liquid the screen and fog take its colour, like the original
  (quicksand no longer looks transparent); no snow under water; water has side faces; submerged ice stays behind the
  water; star map texts translated.
- Original French biome names (Terres Rouges, Rocaille sombre, Sables arides), found by Sekhmet on the old Twinpedia.
- Optional DirectX build (`haxe port\game_dx.hxml`, `jugar_dx.bat`), besides the OpenGL one.
- Mothership: unbreakable, better lit, doors closed, laser force fields on the hangars, 10 marked bays, your ship
  parked in yours (you spawn inside and its computer takes you back), and a shop with an animated merchant robot in
  the entrance tunnel.
- Gamepad: chests, shop and slot switching (LB/RB).
- The game no longer freezes for a few seconds at startup.
- `jugar.bat` works even when the PATH has folders with parentheses.

## v0.2 — pre-release
- Star map with the original animations (entering and leaving a system, hyperspace, flashes, server wait), common
  background with maelstrom; systems are generated in the background so it no longer freezes.
- Held block in the hand and break particles, copied from the original.
- Dead city selectable in New game.
- Fixes: deleting saves, removing the cascade source on the ship, dropped block spin, snow inside the ship.
- Changes from the original: the synthesizer uses the blocks in its area; breakable herbs and stalactites; curvature at
  60 %; snow mounds hiding a plant look like snow; camera zooms into the planet when entering.

## v0.1 — pre-release
First published native version: menus and saved games, planets identical to the Flash ones, digging/placing/jetpack,
creative mode, ship (teleporter, doors, synthesizer with the original recipes, computer), star map
(sector, systems, scanning and landing; the universe is part of the saved game) and a portable package with `jugar.bat`.
Known bugs: [`BUGS.md`](BUGS.md).

The earlier Flash version has its own changelog in [`docs/flash/CHANGELOG_flash.md`](docs/flash/CHANGELOG_flash.md) (Spanish).
