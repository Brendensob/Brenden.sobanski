---
tags: [game, guidance]
---
# Goals and Guidance

Added 2026-10-27 so a new player always knows what to do next. Brenden asked that "players know what to do".

## The goal card
![[goal_card.png]]

- A small dark card under the bars (top left) says the **goal** and how far along you are, like "Bring Miffie 10 Jellies 3/10".
- **Tap it** for how to do it (where to go, who to hit, what to combine).
- When a goal is done, "Goal done! Next: …" shows under the clock.
- It hides while the emote panel or a boss bar is up.
- The card shows the **first goal not done yet** (since 2026-11-07). Before that it showed the first goal after the last one done, so doing a later goal early hid an earlier one for good. That made "Bring Miffie 10 Iron Bars" show while Miffie still wanted 50 Jellies, since her quests come in order.
- After the list, it follows **Miffie's next quest**.

| # | Goal | Done when |
|---|---|---|
| 1 | Visit the Grasslands | you've been to Grasslands 1 |
| 2 | Bring Miffie 10 Jellies | her quest 1 |
| 3 | Make Wooden Armor | you wear any armor |
| 4 | Give Brutus a Wood Wall | his quest (opens Survival) |
| 5 | Bring the furnace GateKeeper a Pretzel | his quest (opens the furnaces) |
| 6 | Make a Copper Pickaxe | a tier 2 pickaxe in the bag |
| 7 | Find the portal to Grasslands 2 | been there |
| 8 | Bring Miffie 50 Jellies | her quest 2 |
| 9 | Bring Miffie 10 Copper Bars | her quest 3 (Golden Night) |
| 10 | Reach Grasslands 3 | been there |
| 11 | Bring Miffie 10 Iron Bars | her quest 4 (Blue Night) |
| 12 | Clear the Grassland Arena | beat its boss |
| 13 | Survive 7 days in Survival Grasslands | best day 7 |
| 14 | Explore the Darklands | been there |
| 15 | Reach Darklands 2 | been there |
| 16 | Clear the Darklands Arena | beat its bosses |
| 17 | Enter Hell | been there |

## Pacing, from the journey test (2026-11-07)
`tests/journey_test.gd` plays a new character through this list: real fights, chopping and mining, quests, crafting and smelting (see [[Testing#Journey test]]). With this session's changes (and its own Jelly fix, later replaced by Brenden's Jelly 30% and returning Slimes from PR #41), a run reached:

| Minute | Goal |
|---|---|
| 10 | Visit the Grasslands, 10 Jellies, Wood Wall |
| 22 | Pretzel (furnaces open) |
| 33 | Wooden Armor |
| 44 | Copper Pickaxe |
| 54 | Grasslands 2 |
| 98 | 50 Jellies |
| 108 | 10 Copper Bars (Golden Night) |
| 112 | Grasslands 3 |
| 151 | 10 Iron Bars (Blue Night) |

Real players walk and look around more than the bot, so expect longer. Before the changes the first two trips ended in fainting within 3 minutes, the first 10 Jellies took 34–50 minutes, and the bot got stuck on the goal card's "10 Iron Bars" for over two hours.

## Danger on the world cards
![[world_danger.png]]

Each Gatekeeper card has a badge in the corner of its picture: **Easy**, **Fair**, **Hard** or **Deadly**, worked out from *your* gear right now. It compares the hits you need to beat each common monster with the hits it needs to make you faint (flying monsters count double, charging ones much less, because a hit stops a charge). Mini-bosses that take over 150 hits, like the Hand, don't count: walk away from those. The limits were matched to the [[Testing#Fight test|fight test]].

| Gear | Grasslands 1 | Grasslands 2 | Grasslands 3 | Darklands 1 | Darklands 2 | Hell 1 |
|---|---|---|---|---|---|---|
| Starter | Fair | | | | | Deadly |
| Wood | Easy | | | | | |
| Stone Armor + Golden Night | | Fair | | | | |
| Copper | | | Fair | | | |
| Iron + Blue Night | | | | Hard | | |
| Gold + Kings Mace | | | | | Hard | |
| Chainmail + Fear Helmet | | | | | | Deadly |

## Tip when you faint
The faint screen adds one tip: wear armor, then a helmet and shield, then carry potions, then "this place is Hard for your gear".

In code: `Data.GOALS`, `GS.current_goal`, `GS.world_danger` and `GS.fight_score` (game_state.gd), `refresh_goal` and the card badge in hud.gd, `faint_tip` in main.gd.
