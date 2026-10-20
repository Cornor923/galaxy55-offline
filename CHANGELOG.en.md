# Changelog (native version)

[Español: `CHANGELOG.md`](CHANGELOG.md) · [Français : `CHANGELOG.fr.md`](CHANGELOG.fr.md)

## Next version
- **Health and oxygen**, like the original: hard falls, lava, acid water, burning coal and acid herbs hurt; under water
  your oxygen runs out and then you drown; quicksand drowns you too; the healing plant and box heal. Health and oxygen bars
  at the bottom (only shown when not full) and a red or blue flash. When you die you go back to the ship with full health,
  without losing anything. No damage in creative mode.
- Options split into sections (General, Controls, Graphics, Interface): it no longer fitted on one screen.
- Plants and other models: you aim at what you see (their leaves, not the whole cell); with several plants together it is now easy to break the one you look at (port change).
- **Water waves**, the original's; they can be turned off in Options.
- Partial blocks (plates, iron, chests…): per-corner light like the original.
- Menu: a single small background planet; no more stutter while it is generated.
- **Flowing water** (the original `Process.hx`): the sea fills what you dig next to it up to its level; cascades and lava fall,
  spread and disappear without a source; grass gets covered and uncovered; anchored blocks and details break when their
  support is removed. Cascades and the water you place get lower at each step, with a sloped surface (port addition).
- **Merchant robot on the star map:** it travels between the sector's systems; click it and it stops and waits for you, and
  docking takes you into its ship (the mothership), with the shop. Leaving brings you back to the map.
- The original **GPS arrows** on the map: they point to the planets you visited (and their systems) and to the robot (in orange).
- Options: a shadow of the block you are about to place and the name of the targeted block (small, bottom right); both can be turned off.
- Creative mode: the four waters (normal, dark, acid and winter) are in the palette.
- Fixes by **Cornor923** (thank you!): the bedrock (layer 0) is drawn and you can build on it; the main menu sticks to the
  edges on wide windows; the synthesizer uses the inventory's blocks first and keeps the area as a template (like the
  original); the game runs as `galaxy55.exe`, with its icon (Discord no longer says "Half-Life"); water and ice are drawn in
  the right order; blocks can no longer be placed inside a cascade source or quicksand; shop, chest, palette and map
  backgrounds cover the whole window; centered labels on the map buttons, clear of the Close button; names for many blocks
  that had none (snowy variants, charges, plants, bonus crystals).
- The block in the hand no longer shakes when walking.
- Fixes reported by Sekhmet (thank you!): key shortcuts (Tab digs and 1-0 are the 10 slots), blocks can be placed underwater,
  no snow under a roof or in caves, ice no longer drops a block when broken, a shadow of the block about to be placed, the name
  of the targeted block, and the freezer freezes nearby water and lava again.
- Linux: the zips use `/` in paths (they used to extract files with `\`); Linux steps from Sekhmet in the zip's `LEEME`.

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
