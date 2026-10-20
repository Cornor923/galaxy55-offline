# Ideas (native version)

[Español: `IDEAS.md`](IDEAS.md) · [Français : `IDEAS.fr.md`](IDEAS.fr.md)

Ideas for later: **none of this is decided or started**. What will be done is in [`TODO.md`](TODO.md). The project rule is
still to stay faithful to the original and not break immersion: before adding something new, we talk with the community.

## Space travel

Space exploration stays: it is part of the game's identity (Cornor923). Ideas to make travel and the ship's speed (engines
and weight, like in the original) matter more:

- **Fuel** (Pvie's favourite; Cornor923 is against it: the player could get stranded): travelling on the map uses energy according to the distance; a heavy ship uses more.
  It is refilled with crystals (Citronox, Etherium). It adds strategy without turning travel into a chore.
- **Unlocking systems** (from the original): a third of the systems are locked and were opened by paying for a licence
  (1500). The port shows the padlock, but the button does nothing yet.
- **Richer distant planets** (Cornor923): the further from the starting system, the more rare ores. The original biomes stay
  untouched, only the amount of ore changes.
- **A "base" planet** (Cornor923).
- **A merchant robot that wanders further:** it travels further and sometimes goes to distant systems; a fast ship catches it sooner.
- **Quests or fixed points in space** (Cornor923): Galaxy 55 belongs to the Alphabounce universe, whose goal was to discover
  planets and Earth. A story that invites you to go from system to system would give speed a use.
- **Engines on planets:** they already exist in the original and in the port (same generator): the crashed capsule
  (`detCapsule`) holds 2 engines, hull, wires and glass. It appears on ~0.1% of small planets, ~0.3% of medium ones and ~1%
  of large ones (found by Cornor923). Idea: make it a bit more common, or add other ship wrecks.

## Water and lava

- **Lava + water (or cascade) = basalt** (Sekhmet's memory, "infinite basalt"). The original client code doesn't do it: lava
  only replaces water and basalt only comes from the freezer. Maybe the unpublished server did it. **To be decided.**
- **The sea level drops** when filling holes (Sekhmet's memory of the 3rd alpha version: the sea spreads and the global level
  drops with the water/space ratio, never rises). Right now the sea fills everything up to its level, like the original code.
- **A bucket to pick up water or lava:** dropped for now (Cornor923 isn't keen: the spacesuit "already does it").

## Player equipment

A separate equipment inventory (helmet, suit, backpack, boots…) with upgrades crafted or bought from the robot: bigger
backpack (more jetpack fuel), jetpack turbo, fast refuel, jump boots, anti-slip boots (ice), shock absorbers (once there is
fall damage), better digger, bigger bag, helmet lamp, magnet for dropped blocks, thermal suit or oxygen tank (once oxygen and
damage exist).

## New content

- **Kube content** (Motion Twin's earlier block game) as new planets, leaving the original ones untouched (Cornor923).
- **Fossils:** in the original they were useless and needed the purple laser, which is very rare (Cornor923). Give them a use.

## Multiplayer and web

- **Web version on Eternaltwin:** Biosha offers to host it with a backend (PostgreSQL, Node/Rust/PHP, OAuth login). First it
  has to run in a browser for one player, and there is still a lot to do.
- **Player ships:** at most 17×17×14 (the original hangar); they park inside bays (mothership, guilds).
- **Guild ships:** bigger, with a shared hangar and permissions for who can break blocks. They don't park inside: they dock
  from outside with docking tubes.
- **Player shops:** stalls in the mothership's trade area or a counter on a guild ship; an offer board between players.
- Keep browser performance in mind (small fixed worlds, meshes that aren't rebuilt, a limit on visible players).
