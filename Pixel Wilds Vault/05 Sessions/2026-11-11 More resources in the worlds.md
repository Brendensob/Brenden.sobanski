---
tags: [session]
---
# 2026-11-11: More resources in the worlds

**Asked:** *Brenden: "make there be more rec sources in the areas"*

**Done:**
- Every explore world now has about twice as many trees, rocks, ores, plants and pots: 136 in a normal world (71 before), 120 in the Tomb of Makara. They stand one tile apart (two beside a tree). See [[Worlds#Resources and spacing]].
- Survival starts with 100 resources (70 before), 28 px apart.
- Autotest prints each world's count and fails below 0.6 per column; new screenshots `20r_grass_2`, `20r_dark_1`, `20r_snow_valley`.
- Autotest: 0 failures. Two-player test: 0 failures on both sides.

![[2026-11-11-more-resources-grass_2.png]]
![[2026-11-11-more-resources-snow_valley.png]]

**Decisions:** in [[Decision Log]] under 2026-11-11.

**Next:**
- If it feels too busy now, the number to turn down is the 0.8 in `level.gd` (`_populate_explore`).
