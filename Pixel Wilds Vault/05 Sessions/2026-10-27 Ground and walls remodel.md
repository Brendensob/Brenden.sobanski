---
tags: [session]
---
# 2026-10-27: Ground and walls remodel

**Asked:** "Remodel everything especially the walls around the map like a professional designer would"

![[ground_before_after.png]]
![[ground_worlds.png]]

**Done:**
- **The ground** (`scripts/terrain.gd`) is drawn like a tileset. Each tile looks at its neighbours:
  - grass caps with tufts and the odd flower;
  - outlined sides, lit on the left and shaded on the right;
  - rounded outside corners;
  - shaded ceilings with lumps, roots and drips.
- **The walls around the map:**
  - mossy stone walls at the left and right edges, carrying on up past the top of the map;
  - bedrock at the bottom of cave worlds;
  - Pixel Town gets a stone frame, stone-brick room walls, and a stone-brick basement with a cobbled floor.
- **Back walls:**
  - brick with moss in the dark worlds (from Brenden's Darklands recording);
  - sandstone in the Tomb;
  - ice in the icy worlds;
  - a dim rock face elsewhere;
  - soft shadows next to the rock everywhere.
- **Ledges and deadly walls:**
  - plank ledges with brackets underground;
  - thin grassy platforms in the arenas;
  - red-brick deadly walls with steel spikes.
- **Depth:** the ground darkens smoothly the deeper it goes (a shader).
- **Backdrops:** new mountains (lit and shaded faces, small zig-zag snow caps, haze) and a tree line instead of round blobs.
- **Speed:** each map's ground is baked once, in about 0.2 s.

**Tests:**
- New `look_check()` (`AT_LOOK=1`, also in the full run) builds every world. It checks each builds in under 3 s with stone at its edges, and saves screenshots of each world's surface and caves.
- Full autotest: 0 failures.

**Decisions:** see [[Decision Log]] (2026-10-27, ground and walls remodel).

**Next:** if Brenden likes it, the same pass for houses, villagers and monsters.
