---
tags: [session]
---
# 2026-11-07: Houses, villagers, monsters and progression

**Asked:** "now do the same for houses villagers and monsters test out the progression make sure players can actually develop good at grasslands while having fun and progress to better areas"

![[art_houses_people_monsters.png]]

**Art:**
- **Houses:** cartoon cottages with shingled roofs, chimneys, framed windows with flower boxes, an arched door and a stone base.
- **Faces:**
  - the orange "beak" (a 3-pixel mouth poking out past the chin) is now a small mouth inside the face;
  - blush on people's cheeks;
  - a shine on the hair.
- **Monsters and characters:** four-tone shading (lit top, shaded bottom, darker right edge) and a shine.

**Progression:** a new journey test plays a fresh character through the goal card with real fights and gathering (see [[Testing#Journey test]]).

| Run | What it showed | Change |
|---|---|---|
| 1 | Fainted on the first two trips; 10 Jellies at 34 min; goal card stuck on "10 Iron Bars" for 2.5 h | Card shows the first goal not done; health back 1/4 s after 6 s; easy monsters at the entrance |
| 2–3 | No early faints, but 50 Jellies ≈ 3 h; worlds empty out; bag full every trip | More Slimes; monsters come back; bot stores and trashes like a player (the Slime and respawn changes were later replaced by Brenden's PR #41 versions) |
| 5 | About 5 Jellies per 10 min | Copper Pickaxe and Grasslands 2 before 50 Jellies (Jelly drops 1–2 was tried, then dropped for Brenden's Jelly 30%) |
| 6 | Grasslands 2 at 54 min, Golden Night 108, Grasslands 3 112, Blue Night 151, one faint | — |

**Tests:**
- Full autotest: 0 failures.
- Data audit: 0 hard errors.
- Progression audit: 0 softlocked.

**Then Brenden asked:** "when i put a portal down people can go in 1 at a time and it wont take everyone same with leaving put a 20 secv timer and then  it takes everyoine back if there not back alr and if someones in a portal then it says someones in the current portal"

![[portal_countdown.png]]

- **Portals in a room take one player at a time.** The others see a message and a countdown ("Everyone goes to Grasslands 1 in 20"), and get the portal on their town street too.
- **After 20 seconds** whoever hasn't gone through is taken along. Leaving works the same way.
- **During the countdown** another portal says "Someone's in the current portal".
- **Two-player test:**
  - the host goes alone and the friend is taken after the countdown;
  - the friend goes first on their own copy, a second portal is refused, and the host joins after the countdown;
  - the friend goes home alone and the host follows.
  - 0 failures on both sides.

**Then Brenden asked:** "make it so mulitplew players can pick up the samne drop when standing by it this doesnt include bosses but it includes breakable loot and normal mobs but only if the players are right next to eachother. fix the death thing to what i told you to do before. and dont make every player go to the portal players can stay in town if they want. but make them leave if in the portal and someone leaves"

![[portal_street.png]]

- **Shared drops:** players right next to whoever picks up a monster's or broken thing's drop get the same drop (not boss drops).
- **Portals:** going in no longer pulls anyone. You can stay in town and see the portal on your street. Leaving a world still takes everyone in that world after 20 seconds.
- **The death thing:** the faint screen checks out at three window shapes. Asked Brenden which death thing he meant (see [[Open Questions]]).
- **Two-player test:**
  - the friend stays in town, then walks through the portal;
  - a shared Rock drop picked up next to the friend reaches the friend;
  - leaving with the countdown and the busy portal still work.
  - 0 failures.

**Next:** Brenden plays the Grasslands and says if it feels right. 
