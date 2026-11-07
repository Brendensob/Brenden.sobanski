---
tags: [session]
---
# 2026-11-06: Clean text, ores and distinct gear

**Asked:** *"Fix all these little bugs where the writing looks weird and double check to make sure there's nothing like that I need the game clean asf also make crystals better looking and thinner same with orders give them more detail and the armor and weopon a should be all diff in knockback and size and everything and look distinct from each other same with the armors and helms"*

**Done:**
- Found why the writing looked weird: letters were snapped to the small game grid before being stretched to the screen. Fixed that, thinned the outlines and brightened dark words. See [[Art Style]].
- Added a check to every autotest screenshot of an open window: no two pieces of writing may overlap. It caught the stats page's Coins line hitting the tip, now fixed.
- Thin crystal shards and detailed ore icons; ore rocks with cracks and shiny nuggets; ice and erbium rocks grow crystals.
- Knockback strength and hand size per weapon ([[Combat]]); the info card shows reach and knockback.
- Worn armour and helmets take their icons' shapes.

**Decisions:** in [[Decision Log]] (2026-11-06, clean text).

**Next:** Brenden checks the text on his phone. The knockback strengths are estimates he can tune in `Data.weapon_knockback`.

![[clean_text_gear_2026-11-06.png]]
