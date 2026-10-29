---
tags: [game, worlds]
---
# Worlds

![[world_cards.png]]

The Gatekeeper's menu is a row of **world cards**, in the order of Brenden's screenshots. Each card has a green title, a one-line description, a small map picture with a **danger badge** (Easy, Fair, Hard or Deadly for your gear, see [[Goals and Guidance]]) and **Activate** (or **Locked**).

The map picture is drawn like a little screenshot of the world (since 2026-10-29): its sky, clouds, mountains and hills, grassy ground with dark edges, darker caves, trees and ores, and a small purple portal where you arrive. Big worlds show their start, arenas and Survival their middle. In code: `level.gd` → `preview_image()`.

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
| 11 | Modina Ruins | Poisonous ancient ruins |
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
- **Arenas:** monsters keep coming, and the boss arrives after 3 minutes.
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
