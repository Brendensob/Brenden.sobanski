---
tags: [project, checklist]
---
# Completion Checklist

The living list of every system and how finished it is. It's updated after each audit or change. "Tested" means a check in the autotest or the two-player test proves it (see [[Testing]]).

| Status | Meaning |
|---|---|
| ✅ | Complete and tested |
| 🟡 | Implemented, not covered by a test |
| 🟠 | Partly implemented |
| ⛔ | Missing |
| 🔒 | Blocked: needs data we don't have (see [[Known Issues]]) |

*Last audit: 2026-10-22, from `tools/data_audit.gd` plus a full read of the code paths. See [[2026-10-22 Full game audit]].*

## Game data
| System | Status | Notes |
|---|---|---|
| Every id in every table points to something real | ✅ | `data_audit.gd`: 0 broken references |
| Every item can be obtained by playing | 🔒 | 564 of 567. **Blood Long Sword, Stone Wall, Torch Stand**: researched in the wiki's own page source on 2026-10-24, still no source. Proposals are waiting for Brenden's OK (see [[Open Questions]]) |
| Every material has a use | ✅ | 3 are only for selling (Snowball, Fortune Nugget, Eggency) |
| Every monster spawns somewhere | ✅ | 70 of 70 |
| No shop money loops | ✅ | Every shop price is above the sell price |
| Every combination is possible | ✅ | 94 need their book in the bag. Negative wiki rates are meant to be raised by the book (+50) and a scroll (+35) |
| World Data rare spawns | ✅ | Weights under 1 (King 0.3 and so on) are rare spawns, not zero. The export now shows each spawn's share |

## Items and inventory
| System | Status | Notes |
|---|---|---|
| Stacking (wiki stack sizes) | ✅ | |
| Rewards never lost when the bag is full | ✅ | Chests, the Crafter, quests, combining, harvests, survival tokens, trades and multiplayer pickups drop the overflow at your feet |
| Using each item type (24 types) | 🟡 | Food, gear, books, characters, throws, staffs, bows, placeables. Keys, eggs, seeds, scrolls and tokens explain where to use them |
| Equipment: 6 slots and stat sums | ✅ | Helmet test, and the earlier ring tests |
| Banka's storage (6 × 30) | ✅ | |
| Drag-and-drop, stack splitting, sorting | ⛔ | Tap to move works. PSG2 is tap-based too, so this is optional |
| Item tooltips and descriptions | 🟡 | Every item has a description and stats line |
| Item rarity colours | ⛔ | PSG2 has none that we know of |

## Combat
| System | Status | Notes |
|---|---|---|
| Melee damage, crits, cooldowns | ✅ | |
| No hits through walls | ✅ | Swings and pets check for walls |
| Bows, cannons and ammo | ✅ | One ammo per shot; stops when empty |
| Staffs and mana | ✅ | Healing staffs don't waste mana at full health |
| Defense and 0-damage blocks | ✅ | |
| Status effects (poison, fatigue, slow, cold) and cures | ✅ | The Antidote cure and Jade Ring immunity are tested |
| Knockback, hit stun, hit feedback | ✅ | About a tile of push, a short daze with no touch damage, hit spark and squash (2026-10-24) |
| Monster AI (walk, fly, charge, hop, accel) | 🟡 | |
| Bosses in all 8 arenas | ✅ | Arrive at 3 minutes |
| Fainting and respawn | ✅ | Nothing is lost when you faint |

## Gathering and crafting
| System | Status | Notes |
|---|---|---|
| Resources: tool tier, hits, drops | ✅ | Gold needs an Iron Pickaxe; better tools take fewer hits |
| Combining: chance, book, scroll, Dust on fail | ✅ | |
| Crafter recipes | ✅ | Copper Axe and the Hell Armor line are tested |
| Smelting: cost, timer, collect once | ✅ | |
| Incubator and pets | ✅ | |
| Magic soils and seeds | 🟡 | |

## Economy
| System | Status | Notes |
|---|---|---|
| Buying (and not without the money) | ✅ | |
| Selling at the item's price | ✅ | |
| Gem Shop and gems for coins | ✅ | |
| Miner's Survival Token shop | ✅ | |
| Device-clock cheating (furnaces, daily chests) | ✅ | Steady in-game clock, server time when online, no rewinding a save. Offline, a clock moved forward *while the game is closed* still counts once (see [[Known Issues]]) |

## Quests and progression
| System | Status | Notes |
|---|---|---|
| Quest order, rewards, unlocks | ✅ | Brutus, Pretzel, Miffie, Jumpie, ninjas and robots |
| Rewards paid once | ✅ | |
| Miffie's daily bounty | ✅ | |
| World access | ✅ | All worlds are open at the Gatekeeper, as in PSG2 (the wiki lists no locks). Survival needs Brutus' quest, the Tomb 8 stamina, and **Snow Valley 12 stamina** (wiki) |
| Characters: swapping keeps the old one | ✅ | The bonus weapon comes once |

## Saving
| System | Status | Notes |
|---|---|---|
| Bag, storage, gear, coins, gems, flags, quests, furnaces, incubator, soils | ✅ | Round trip tested |
| Safe writes (temp file and backup) | ✅ | |
| A damaged save falls back to its backup and is kept aside | ✅ | |
| Bad fields in a save can't crash loading | 🟡 | |
| Older saves load (missing fields get defaults) | 🟡 | |

## Multiplayer
| System | Status | Notes |
|---|---|---|
| Rooms, joining, shared world, chat, emotes, trading | ✅ | Two-player test |
| Town walls in a room | ✅ | A wall anyone in the room opened is open for everyone. The unlock is saved for the breaker. Two-player tested (rock wall, Torch wall, rebuild, leave) |

## UI and feel
| System | Status | Notes |
|---|---|---|
| HUD, menus and panels like PSG2 | ✅ | |
| Damage numbers and death puffs | ✅ | |
| Sounds | ✅ | 33 effects, with a repeat limit |
| Music | ✅ | 7 original synthesized loops; switches by place, boss and night |
| Sound and Music volume | ✅ | Off to 100% in 25% steps, saved |
| Dark screen edges in caves | ✅ | Dark worlds and deep caves; under the HUD; tested at 3 window shapes |
| Character switch confirmation | ✅ | Cancel and Become tested |
