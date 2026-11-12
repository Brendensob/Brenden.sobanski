---
tags: [session]
---
# 2026-11-12: Auto-hit jumps and kick-outs

**Asked:** "When I auto hit the jump drains fix it and randomly sometimes it kicks me out even in singleplayer"

**Done:**
- Swings are free: auto-hit no longer empties the green bar, so air jumps keep working ([[Movement and Jumping]], [[Combat]]). Autotest: 2 s of auto-hit leaves the bar full.
- A dropped online connection no longer sends you to the title, in single player or in a room. You keep playing, and your room reopens by itself ([[Multiplayer]]). The two-player test drops the host's connection and checks both.
- The game also saves whenever you switch away from it, in case the phone browser drops the page.
- Single-player autotest, two-player and three-player tests all pass.

**Decisions:** see [[Decision Log]] (2026-11-12).

**Next:** if Brenden still gets kicked, ask what he sees right before (the title screen, a message, or a white page reloading).
