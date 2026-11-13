---
tags: [session]
---
# 2026-11-13: Boss loot for each player and the Game House

**Asked:** *"fix drops make boss drops local per player make house on left a minigame room you can player very 2.5 hours and get gems or other rewards from by doing minigames like the mairo mini game where you smack the tiles and try to match stuff to get rewards or you match the bad ones and lose"*

**Done:**
- Boss loot is rolled for every player on the map; each player's drops are only theirs (`level.boss_loot`, `Net.boss_loot`). Arena rewards land at each player's own feet instead of the host's.
- A friend's pickup that got no answer from the host asks again after 2 s instead of sticking; your own drops are kept when your game takes over the map from a host who left.
- The west house in [[Pixel Town]] is the Game House: Tile Match once every 2.5 hours, prizes are placeholders (`match_game.gd`).
- Tests: the autotest checks the Jelly King's loot is yours alone, Tile Match's rules, the window, the prizes and the saved wait; the two-player test checks host and friend each get their own boss loot.

![[game_house_2026-11-13.png]]
![[tile_match_2026-11-13.png]]

**Decisions:** see [[Decision Log]] (2026-11-13).

**Next:** Brenden sets the prizes and misses ([[Open Questions]]); more minigames for the house if he wants them.
