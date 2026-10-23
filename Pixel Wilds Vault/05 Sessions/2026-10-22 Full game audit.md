---
tags: [session]
---
# 2026-10-22: Full game audit

**Asked:** a full audit and completion pass: understand the whole project, make all the data drive real gameplay, check progression, combat, inventory, economy and saving, and test everything.

**Inspected:**
- every script;
- all data tables (567 items, 70 monsters, 23 worlds, 173 combinations, 163 Crafter recipes, smelting, resources, shops, chests and seeds, 75 quests, characters, pets);
- the autotest (143 checks before, 170 after).

A helper read every code path for bugs and exploits.

**Found and fixed:**
- **Lost rewards:** a full bag silently deleted rewards from chests, the Crafter, quests, combining, harvests and the character weapon. Now the overflow drops at your feet (`GS.give`).
- **Saves:** a damaged save showed up as an empty slot, so making a character there overwrote it, and a crash mid-save could wipe a slot. Saves now go through a temp file with a backup, and loading checks every field.
- **Walls:** swings and pets hit monsters through walls.
- **Characters:** becoming a character destroyed the old one.
- **Smaller fixes:**
  - healing staffs wasted mana at full health;
  - the Wall Hammer could be earned twice;
  - multiplayer pickups could lose part of a stack.
- **From the wiki:**
  - the Nightmare Long Sword is now in the Master Chest;
  - Snow Valley needs 12 stamina.
- **World Data export:** it showed rare spawns as ×0. It now shows each monster's share of the spawns.

**Checked and fine:**
- no broken ids;
- no money loops;
- every monster spawns;
- quests can't pay twice;
- furnaces collect once;
- keys are required;
- ammo and mana are spent correctly.

**Tests:** the new `systems_check` in the autotest covers rewards on a full bag, shop buying and selling, gear stats, bows and staffs, keys, furnaces, quests paying once, walls, tool tiers, the Miner's token shop, the Antidote, character swapping, a save round trip and damaged-save recovery: 27 checks. Each check was also run with the fix removed, to make sure it fails without it.

**Results:** full autotest: 170 checks, 0 failures. Two-player test (host and client): 0 failures. Data audit: 0 hard errors.

**Next:** see [[Completion Checklist]]. The biggest gaps:
- music;
- dark cave edges;
- a source for the 3 unobtainable items;
- a confirmation before switching character;
- the Combination Scroll on unknown recipes (is it used up in PSG2?).
