---
tags: [game, npcs]
---
# NPCs

You talk to an NPC by **hitting** them (face them and press A), like the original.

| NPC | Where | Look | Does |
|---|---|---|---|
| Gatekeeper | Right of the portal | Purple hat | Opens a world portal from the world cards (see [[Worlds]]) |
| Miffie | Street | Black hair, **yellow dress** | 27 quests in the original's order, then a daily bounty |
| Brutus | Street | Red hair | Wood Wall quest → Survival Book and Survival Grasslands; sells wood, rock and branches |
| Miner | Street | Blond | Seeds and keys for Survival Tokens |
| Plumber | Street | Red cap, blue overalls | Sells tools; calls "New stocked items!" |
| **Banka** | Street | Blonde pigtails, pink dress | **Storage**: 6 backpacks × 30 slots (see [[Bag and Storage]]) |
| **Merchant** | Street | **Spiky blond hair**, grey shirt | Combo Book II for 1,500, potions, ammo, walls, campfire, Green Egg |
| Crafter | Street, east | Brown | Makes weapons, tools, helmets, armor, shields and rings (see [[Crafting and Combining]]) |
| Trader | Trading Center | Green cap | Trading between players |
| GateKeeper (gate) | Furnace room | Green face | The Pretzel quest opens the furnace room |
| GateKeeper (Hell 2) | Hell 2 | Missing his mask | Bring a Green Face, and he sells Em Stones for 92,500 |
| Jumpie | Grasslands 1 | Looks like Miffie | 10 Jellies → a Pixel Coin |
| Nini, Nana, Nina | Basement | Ninjas | Tsurugi upgrades up to IV |
| FC 9912, TT 1001, 2219 OOP | Basement | Robots | Iron Fist upgrades up to IV |

Every shopkeeper now and then shows **"New stocked items!"** over their head.

Walk up to some villagers and their name turns into a greeting, as in Brenden's 2026-10-20 recording:

| NPC | Says |
|---|---|
| Gatekeeper | "Where do you wish to go?" |
| Brutus | "Looking for the Book of Survival?" |
| Miner | "aghh.." |

The greetings are the `greet` field in `Data.NPCS`.

In code, NPCs are defined in `Data.NPCS` (data.gd), their looks in `Art.LOOKS` (art.gd) and their shops in `Data.SHOPS`.
