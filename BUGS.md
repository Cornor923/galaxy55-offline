# Known bugs (native version)

[Español: `ERRORES.md`](ERRORES.md)

If you find one that is not listed, open an *issue* with what you were doing and, if possible, a screenshot.
Fixed ones are moved to the bottom. Technical details are in [`port/RESUMEN.md`](port/RESUMEN.md) (Spanish).

## Open

| # | Where | What happens |
|---|---|---|
| 4 | Lighting | **Non-square blocks** (half blocks, models...) are lit differently from their neighbours. |
| 7 | Winter | There are **plain white blocks** without texture. |
| 8 | Winter | **Spruce leaves** drop material; in the original they may not. |
| 9 | Rendering | The planet **curvature** is stronger than it should be. |
| 10 | Rendering | Dropped **crystals** (charges) look too wide. |
| 11 | Rendering | **Layer 0** (bedrock) seen from below looks like a flat plane. |
| 12 | Water | Water **does not flow**, and it freezes when touching ice (not yet confirmed whether the original does that). |
| 13 | Star map | **Entering and leaving a solar system** and **landing** are a simple fade, not the original animations; leaving the system is too fast (the original lets you pass the last orbit and ejects you later). |

## Fixed

- v0.2: deleting a saved game from the menu.
- v0.2: the cascade source can be removed (targeting now works as in the original).
- v0.2: particles when breaking a block; dropped blocks spin at the original speed.
- v0.2: Dead city can be chosen in New game (Shed not yet).
- v0.2: the selected block is shown in the hand.
- v0.2 (change from the original): the synthesizer always uses up the blocks placed in its area.
- v0.2 (change from the original): ground herbs and ice stalactites can be broken; they give tall grass (33 %) or ice (7 %), like the original's plants and black ice.

- Appearing "in the sky" when entering the synthesizer (not seen again).
- Synthesizer blocks duplicating when placed.
- Black screen when taking off to the star map.
- Returning from a planet left the ship outside its galaxy (now it returns next to the planet).
