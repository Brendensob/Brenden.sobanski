---
tags: [session]
---
# 2026-10-24: Polish pass, phase 1

**Asked:** finish the known incomplete features:
1. music and audio;
2. cave darkness;
3. a character-switch confirmation;
4. the 3 unobtainable items;
5. town walls in multiplayer;
6. device-clock cheats.

**Done:**
1. **Music:** 7 original loops synthesized in code (`scripts/music.gd`), chosen by place, boss and night, with cross-fades.
   - New sounds: heal, equip, chest, smelt, and the night sting.
   - The same sound can't start twice within 45 ms.
   - Sound and Music volume buttons in Options and the compass menu.
2. **Cave darkness** (`shaders/cave_dark.gdshader`): dark worlds and deep caves, under the HUD, round at any window shape.
3. **"Become the X?"** dialog. Using the character you already are no longer wastes the item.
4. **Research only:** the wiki's own page source confirms the Blood Long Sword exists but gives no source. The Stone Wall has no recipe, and the Torch Stand doesn't appear in PSG2. Proposals are waiting in [[Open Questions]].
5. **Room-wide town walls:** open for everyone if anyone in the room opened them; the unlock is saved for the breaker.
6. **Game clock:** a steady timer, the server's time when reachable (new `/time`), and no rewinding a save.

**Tests added:** see [[Testing]] → "What the suites cover now". Each was run and passes. The results are in [[Completion Checklist]].

**Next:** phases 2–5: gap review, a full player-journey test, polish, more tests.
