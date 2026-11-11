---
tags: [game, worlds]
---
# Worlds

![[world_cards.png]]

The Gatekeeper's menu is a row of **world cards**, in the order of Brenden's screenshots. Each card has a green title, a one-line description, a small map picture with a **danger badge** (Easy, Fair, Hard or Deadly for your gear, see [[Goals and Guidance]]) and **Activate** (or **Locked**).

The map picture is drawn like a little screenshot of the world (since 2026-10-29): its sky, clouds, mountains and hills, grassy ground with dark edges, darker caves, trees and ores, and a small purple portal where you arrive. Big worlds show their start, arenas and Survival their middle. In code: `level.gd` → `preview_image()`.

## Resources and spacing
Since 2026-11-11 explore worlds place about **0.8 resources per column**: 136 trees, rocks, ores, plants and pots in a 170-wide world (71 before), 120 in the Tomb of Makara. There is at least one empty tile between any two and two beside a tree, and none within a few tiles of where you arrive. Survival starts with 100 (70 before) and they keep 28 px apart (40 before). Harvested ones still grow back. *Brenden: "make there be more rec sources in the areas"*

The autotest prints the count for every world and fails if one has fewer than 0.6 per column.

![[2026-11-11-more-resources-grass_2.png]]

Before that (2026-11-04) it was 0.42 per column with two empty tiles between, because *Brenden: "how close everything is it just has that clutter feel"*. Monsters still start at least five tiles apart.

## Set aside for now (2026-11-05)
Everything past Hell is **set aside**, not deleted, so Grasslands to Hell can be perfected first. The Gatekeeper shows only cards 1 to 7. The 73 items only the later worlds give are hidden from the Crafter, the combination books, the furnaces, the shops, Miffie's Bounty Quest and the other quests. The game works out that list itself from where every item comes from, so it stays right when the data changes. Old saves keep any of those items they already have. To bring it all back, turn on `Data.set_later_open(true)` (or empty `Data.LATER_WORLDS`). The list is in [[World Data#Set aside for now]]. *Brenden: "hold everything past hell aside for now it takes a lot to get to that point anyway and I just want that perfected first"*

## Grasslands slimes (2026-11-05)
Grasslands 1 to 3 have more slimes: they're a bigger share of the monsters (Grasslands 1: 9 of 20 parts, was 6 of 13) and the worlds start with a few more monsters (40, 44 and 46). Slimes also **come back**: every 20 seconds (25 in Grasslands 3) a new one appears somewhere out of sight, while there are fewer than the map started with. Slimes drop Jelly 30% of the time (the wiki says about 20%). *"Make the jelly's have more spawns in grasslands ... Make jelly's slightly more common."*

| # | World | Card text |
|---|---|---|
| 1 | Grasslands | The land of the slimes. |
| 2 | Grassland Arena | Boss spawns in 3 minutes. |
| 3 | Survival Grasslands | Win treasure from surviving! |
| 4 | Darklands | Danger.. |
| 5 | Darklands Arena | Boss spawns in 3 minutes. |
| 6 | Hell | Hell welcomes you |
| 7 | Hell Arena | EPIC DANGER! |
| 8 | Dream Arena | |
| 9 | Ice Cavern | |
| 10 | Ghost Arena | |
| 11 | Modina Ruins | Poisonous ancient ruins, coloured **yellow** (was green, 2026-11-06) |
| 12 | Nightmare Valley | Nightmare starts here.. |
| 13 | Mushroom Valley | Prepare for some challenge! |
| 14 | Forbidden City | The lost ruins of Forbidden City |
| 15 | Fruit Loop | Fruit ninja needed! |
| 16 | Snow Valley | Weaklings, stay away! |
| 17 | Tomb of Makara | Ancient evil.. filled with treasures? |
| 18 | Eggcellence | To feast, or be feasted on. |

## Kinds
Every world is walled in by mossy stone at its left and right edges; cave worlds have bedrock at the bottom. Each world's cave back wall is themed (see [[Art Style]]).

- **Exploration:** Grasslands 1–3, Darklands 1–2, Hell 1–2, Ice Cavern, Modina Ruins, Nightmare Valley, Forbidden City, Snow Valley. Deeper levels are reached through a purple portal hidden underground.
- **Grasslands 1**: near the way in, on the surface, only Slimes and Firas are placed (since 2026-11-07), so a new player meets the easy ones first.
- **Arenas:** monsters keep coming, and the boss arrives after 3 minutes.
- **Grasslands Arena** (since 2026-11-05) is made for low-level players. **One boss** comes, a third of the time each: **Rexy** (270 health), the **Hand** (266) or the **Jelly King** (300). Rexy and the Hand hit at 30% of their wiki hit (they used to come together with 999 and 1,251 health). Bosses stagger for a moment when hit (at most once a second). In single player you get **one free revive** there: the first time you faint you get back up on the spot. See [[Combat#Grasslands Arena boss test]].
- **The Jelly King** is our own boss: a big pink slime whose gold crown has slipped half off his head. He hops after you like a slime. Every 3.5 to 5.5 seconds he squashes down (your warning), leaps high and slams into the ground, and a ripple of jelly rolls along the floor both ways. It hurts (3) if it reaches you on the ground, so **jump over it**. He touches for 2 and drops 5 to 10 Jelly (and sometimes Sticky Balls). *"make a big slime boss called jelly king with a half slipped off crown and he jumps high sometimes slams and you have to jump"*

![[jelly_king_slam.png]]
- **Survival Grasslands:**
  - the only place the **day counter** shows;
  - Survival Tokens for nights survived, and bosses every 6 days;
  - dying after day 7, 19 or 45 gives a Silver, Golden or Master Key.
- **Tomb of Makara:**
  - a maze of 11×11 rooms, and it costs 8 stamina to enter;
  - some walls are deadly;
  - monsters hit 40 harder when your defense is below 160.
- **Snow Valley** needs at least **12 stamina** to enter (wiki), and its monsters hit 40 harder below 160 defense.
- **No world locks:** every world is open at the Gatekeeper, as in PSG2. Stronger worlds are gated by how strong you are.

> [!important] There is no Hell 3 or Darklands 3 in PSG2
> Those are from the separate 2.o game. Don't add them.

In code: `Data.WORLD_CARDS` and the world definitions are in data.gd, and the map generators in level.gd.
