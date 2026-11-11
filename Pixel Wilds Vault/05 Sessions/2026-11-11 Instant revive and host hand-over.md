---
tags: [session]
---
# 2026-11-11: Instant revive and host hand-over

**Asked:** *"When someone dies make sure it's able to rez them right away. ... make sure when someone leaves as the host it doesn't end the game and just passes it down."* (The rest of that message, about items, dragging to the trash and more resources, was done in other sessions.)

**Done:**
- Touching a friend's gravestone revives them right away (it was 3.5 seconds of standing by it). See [[Combat#Fainting (single player, 2026-11-05)]].
- When the host leaves, the player who joined first becomes the host and the game goes on for everyone on the same maps. The others rejoin by themselves. See [[Multiplayer]].
- Online server: passes the room on and lets the old room's players into the new host's room for a minute. A game now reads the server's last message even when the connection closes right after it.
- Tests: server tests for the hand-over (with three players), the two-player test checks the touch revive and the host leaving, and a new three-player test (`--nettest trio0/1/2`). See [[Testing]].

![[host_passed_on.png]]
![[host_passed_on_trio.png]]

**Decisions:** in [[Decision Log]] (2026-11-11).

**Next:** check the live server picked up the change (see [[Online Server]]); a real phone test with three players.
