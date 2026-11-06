---
tags: [game, town]
---
# Pixel Town

Small and closed in on all sides (a roof on top), with three floors. Since 2026-10-27 the roof and outer walls are drawn as mossy stone, the two room walls as stone brick, and the basement has a stone-brick back wall and a cobbled floor (see [[Art Style]]). The layout comes from Brenden's sketch (2026-10-09) and his screenshots (2026-10-17). In code it's `level.gd` → the town generator. The map is **80 × 28 tiles** (64 until 2026-11-04, when it was widened so the villagers aren't crowded).

## Up top (west → east)
- **Trading Center**: a closed room behind a wooden wall. Burn the wall with a Torch. Inside are the Trader and two trading tables (see [[Multiplayer]]).
- **Incubator**, and the **Silver, Golden and Master** chests, each with a signboard. **Chests have no window** (2026-11-06): hold the right key and hit the chest, and it pops open with the items shooting out for you to pick up. The reward chests deep in worlds pop open the same way (no key, once a day).

![[chest_burst_2026-11-06.png]]
- **Furnace room**: mirrors the Trading Center. The green GateKeeper's gate is its door (the Pretzel quest).
- The way up from the street is an **opening in the exact middle**, 10 tiles wide (4 before 2026-11-05). Jump up through it: a jump plus two jumps in the air.
- The Master Chest and its sign stand just east of the opening, since the wider opening took the floor they stood on.

## The street (west → east)
1. Magic soils in a cave behind a rock wall (break it with a gold pickaxe)
2. Miner, then Brutus
3. Miffie (yellow dress)
4. The sign
5. The open space under the opening: the **Crafter** on its left, the **portal** in the exact middle (right under the opening's middle, so the two line up), and the **Gatekeeper** on its right, mirroring the Crafter. They stand **13 tiles apart** (5 before 2026-11-05). **You start here**, in the gap just left of the portal.
6. Plumber (sells) → **Banka** (storage) → **Merchant** (spiky blond hair, buys)

![[portal_area.png]]

That order matches Brenden's screenshot (Plumber, Banka, then the spiky-haired seller). The Crafter moved from the east end to beside the portal on 2026-10-29, when Brenden asked for it. The four houses mirror around the middle. See [[NPCs]].

## The basement
- A massive stone wall at the east end of the street blocks the way down. Smash it with the Wall Hammer, earned by surviving 10 nights in Survival Grasslands (the night number is a guess).
- The ninjas Nini, Nana and Nina upgrade the Tsurugi. The robots FC 9912, TT 1001 and 2219 OOP upgrade the Iron Fist.

## Tuning history
1. Three floors, from the sketch.
2. Closed in, with the middle opening; faster falling.
3. Symmetrical sides.
4. Smaller ("it's too big").
5. Portal lined up under the opening, with the Crafter and Gatekeeper on either side (2026-10-29).
6. Roomier (2026-11-04): 80 tiles wide, villagers about four tiles apart, houses in the gaps between them, furnaces four tiles apart. *"it just has that clutter feel"*

![[roomy_town_street.png]]

7. Wider portal area (2026-11-05): the Crafter and Gatekeeper 2.5 times further apart, the opening above 2.5 times wider, and you start in the gap. *"Make the gap between crafter and portal guy bigger like 2.5x bigger and same with the gap above. Make player spawn in the gap."*

![[wide_portal_area.png]]

See [[Decision Log]].
