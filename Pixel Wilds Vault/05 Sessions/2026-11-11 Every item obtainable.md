---
tags: [session]
---
# 2026-11-11: Every item obtainable

**Asked:** "make sure every item is obtainable" (one part of a longer message; the revive, host hand-off, trash dragging and more resources are separate threads).

**Done:**
- Audited all 567 items with `data_audit.gd` and `progression_audit.gd`, and checked that the sources the audits assume in code (Wall Hammer on night 10, keys from Survival, reward chests in worlds, boss gems) really exist. 564 had a source; 3 didn't.
- **Blood Long Sword** (and the Blood Long Sword Shield) added to the Master Chest.
- **Stone Wall** = Wood Wall + Rock, **Torch Stand** = Torch + Wood, both 90% with the Survival Book.
- `data_audit.gd` now reports any item with no source as a hard error.
- Now 567 of 567 can be got; 0 softlocked.

**Decisions:** see [[Decision Log]] (2026-11-11).

**Next:** nothing. Brenden chose to keep the worlds past Hell (73 items) set aside for now (2026-11-12).
