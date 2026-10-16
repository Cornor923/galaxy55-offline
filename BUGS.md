# Known bugs (native version)

[Español: `ERRORES.md`](ERRORES.md)

If you find one that is not listed, open an *issue* with what you were doing and, if possible, a screenshot.
Fixed ones are moved to the bottom. Technical details are in [`port/RESUMEN.md`](port/RESUMEN.md) (Spanish).

## Open

| # | Where | What happens |
|---|---|---|
| 4 | Lighting | **Non-square blocks** (half blocks, models...) are lit differently from their neighbours. |
| 8 | Winter | **Spruce leaves** drop material; in the original they may not. |
| 10 | Rendering | Dropped **crystals** (charges) look too wide. |
| 11 | Rendering | **Layer 0** (bedrock) seen from below looks like a flat plane. |
| 12 | Water | Water **does not flow**, and it freezes when touching ice (not yet confirmed whether the original does that). |

## Fixed

- v0.2 (change from the original): snow mounds hiding a plant (`BWinterHidden`) look like regular snow, without their own glow.
- v0.2: deleting a saved game from the menu (Delete button, then pick the save; the confirmation no longer opens twice).
- v0.2: it no longer snows inside the ship.
- v0.2: the map no longer freezes when entering a system (it is generated in the background while you travel).
- v0.2 (change from the original): when entering a planet the camera zooms into it instead of fading to black, and the name shows only once.
- v0.2: the cascade source can be removed (targeting now works as in the original).
- v0.2: particles when breaking a block; dropped blocks spin at the original speed.
- v0.2: Dead city can be chosen in New game (Shed not yet).
- v0.2 (change from the original): planet curvature is 60 % of the original one (it was too noticeable, especially on small planets).
- v0.2: the selected block is shown in the hand.
- v0.2: star map with the original animations: entering and leaving a system (zoom, hyperspace, flashes; leaving lets you cross the ring and ejects you a moment later), scanning (fade, name and bar) and landing; common background with maelstrom.
- v0.2 (change from the original): the synthesizer always uses up the blocks placed in its area.
- v0.2 (change from the original): ground herbs and ice stalactites can be broken; they give tall grass (33 %) or ice (7 %), like the original's plants and black ice.

- Appearing "in the sky" when entering the synthesizer (not seen again).
- Synthesizer blocks duplicating when placed.
- Black screen when taking off to the star map.
- Returning from a planet left the ship outside its galaxy (now it returns next to the planet).
