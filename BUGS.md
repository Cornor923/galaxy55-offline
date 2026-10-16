# Known bugs (native version)

[Español: `ERRORES.md`](ERRORES.md)

If you find one that is not listed, open an *issue* with what you were doing and, if possible, a screenshot.
Fixed ones are moved to the bottom. Technical details are in [`port/RESUMEN.md`](port/RESUMEN.md) (Spanish).

## Open

| # | Where | What happens |
|---|---|---|
| 1 | Saves | **Deleting a saved game from the menu does not work.** |
| 2 | Ship | The **cascade source** block placed on the ship cannot be removed. |
| 3 | Ship | Crafting in the **synthesizer** does not remove the blocks placed in its area (the inventory is used if you have those blocks, as in the original; whether to change this is undecided). |
| 4 | Lighting | **Non-square blocks** (half blocks, models...) are lit differently from their neighbours. |
| 5 | Digging | No **break particles** when a block is destroyed, and the dropped block **spins too fast**. |
| 6 | Digging | **Hanging things** (stalactites, vines) and **ground plants** cannot be broken. |
| 7 | Winter | There are **plain white blocks** without texture. |
| 8 | Winter | **Spruce leaves** drop material; in the original they may not. |
| 9 | Rendering | The planet **curvature** is stronger than it should be. |
| 10 | Rendering | Dropped **crystals** (charges) look too wide. |
| 11 | Rendering | **Layer 0** (bedrock) seen from below looks like a flat plane. |
| 12 | Water | Water **does not flow**, and it freezes when touching ice (not yet confirmed whether the original does that). |
| 13 | Star map | **Entering and leaving a solar system** and **landing** are a simple fade, not the original animations; leaving the system is too fast (the original lets you pass the last orbit and ejects you later). |
| 14 | World | **Dead City** and **Shed** cannot be chosen yet (their generator exists and is identical to the original). |
| 15 | General | The held block is not shown in the hand. |

## Fixed

- Appearing "in the sky" when entering the synthesizer (not seen again).
- Synthesizer blocks duplicating when placed.
- Black screen when taking off to the star map.
- Returning from a planet left the ship outside its galaxy (now it returns next to the planet).
