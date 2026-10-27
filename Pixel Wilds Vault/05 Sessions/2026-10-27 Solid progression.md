---
tags: [session]
---
# 2026-10-27: Solid progression

**Asked:** "make the game progression solid test it and make sure fights arnt impossible and players know what to do" (part of a bigger message; the cartoon look, joining friends and characters were done in other pieces the same day).

**Done:**
- **Fight test** (`tests/fight_test.gd`): a bot fights two monsters at once in every world from Grasslands 1 to Hell 1, with the gear you can make before getting there. See [[Testing#Fight test]].
- What it found before any change: the starter lost to Shellys in Grasslands 1, Octopuses beat wood gear in Grasslands 2, and Dark Slimes, Worms and UFOs beat the gear you'd have after that.
- **Fixes:** Sword Cast attack 4 (was 3), starting health 10 (was 5), 1 s of safety after a hit (was 0.6), potions heal 5 / 12 / 25 / 60, flying monsters tumble longer when hit. No wiki monster number changed. See [[Combat]].
- **After:** every common monster in the Grasslands and Darklands is beaten in at least 3 of 4 pair fights. The toughest (Rexy, UFO, Darklands Worm, all wiki numbers) are beaten one at a time; two at once still usually win. Hell 1 still needs Hell-tier gear.
- **Goal card** on the HUD: what to do next, with progress, tap for how. 17 goals, then Miffie's quests. See [[Goals and Guidance]].
- **Danger badge** on every world card (Easy, Fair, Hard, Deadly for your gear), matched to the fight results.
- **A tip on the faint screen** (wear armor, carry potions, this place is Hard for your gear).
- Fixed: a new character kept the last one's best Survival day until the game was restarted.

**Decisions:** see [[Decision Log]] (2026-10-27, solid progression).

**Next:** Brenden plays the Grasslands on his phone and says if it feels right. If Hell should be reachable sooner, the next lever is Hell gear recipes or the Hell monsters' health.
