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

*Last update: 2026-10-24, the polish pass (see [[2026-10-24 Polish pass phase 1]] and [[2026-10-24 Polish pass phases 2-5]]). The full audit was on 2026-10-22 ([[2026-10-22 Full game audit]]).*

## Game data
| System | Status | Notes |
|---|---|---|
| Every id in every table points to something real | ✅ | `data_audit.gd`: 0 broken references |
| No softlocks under the real gates | ✅ | `progression_audit.gd`: tool tiers, furnace gate, Survival access, the 3 town walls, books and scrolls, and stamina gates all enforced. 0 softlocked items; the deepest chains take 7 rounds |
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
| Using each item type | ✅ | All 22 usable types are tested (coin and gem are currencies, not bag items) |
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
| Monster AI (walk, fly, charge, accel, wizard, stone) | ✅ | All six movement types tested. Bosses use these, with no attack patterns of their own (PSG2's aren't documented) |
| Monster drops | ✅ | 25 slimes drop only their own table |
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
| Magic soils and seeds | ✅ | Plant, not before it's ripe, three things, soil freed |
| Every combination, Crafter recipe and smelt | ✅ | 173 combinations, 163 Crafter recipes and 14 bars, each run through the game's own functions |
| Told when a timer finishes | ✅ | "Your Copper Bar is ready in the furnace", wherever you are |

## Economy
| System | Status | Notes |
|---|---|---|
| Buying (and not without the money) | ✅ | |
| Selling at the item's price | ✅ | |
| Gem Shop and gems for coins | ✅ | |
| Miner's Survival Token shop | ✅ | |
| Every shop item | ✅ | All 45 items in all shops and the Gem Shop, bought for exactly their price |
| Device-clock cheating (furnaces, daily chests) | ✅ | Steady in-game clock, server time when online, no rewinding a save. Offline, a clock moved forward *while the game is closed* still counts once (see [[Known Issues]]) |

## Quests and progression
| System | Status | Notes |
|---|---|---|
| Quest order, rewards, unlocks | ✅ | All 75 quests, in order, take their items and pay |
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
| Bad fields in a save can't crash loading | ✅ | A deliberately broken save loads and keeps what's good |
| Older saves load (missing fields get defaults) | ✅ | |
| A running smelt and egg survive save and load | ✅ | |
| Quit to the menu and play again keeps everything | ✅ | |

## Multiplayer
| System | Status | Notes |
|---|---|---|
| Rooms, joining, shared world, chat, emotes, trading | ✅ | Two-player test (over the WebSocket relay since 2026-10-27) |
| Online on phones (web build) | 🟡 | WebSocket relay and CORS done and tested against the local server; needs the Render server deployed, then a real phone test |
| Server wipe recovery | ✅ | Games restore their name and friends (`/restore`); server tests |
| Town walls in a room | ✅ | A wall anyone in the room opened is open for everyone. The unlock is saved for the breaker. Two-player tested (rock wall, Torch wall, rebuild, leave) |

## UI and feel
| System | Status | Notes |
|---|---|---|
| HUD, menus and panels like PSG2 | ✅ | |
| Damage numbers and death puffs | ✅ | |
| Low-health warning | ✅ | The health bar's border pulses red under 25% |
| HUD at different window shapes | ✅ | 16:9, 21:9, 4:3 and portrait 3:4: nothing off screen, no overlapping buttons |
| Sounds | ✅ | 33 effects, with a repeat limit |
| Music | ✅ | 7 original synthesized loops; switches by place, boss and night |
| Sound and Music volume | ✅ | Off to 100% in 25% steps, saved |
| Dark screen edges in caves | ✅ | Dark worlds and deep caves; under the HUD; tested at 3 window shapes |
| Character switch confirmation | ✅ | Cancel and Become tested |

## Phase 2 review: every system, A to E
**A** complete and working · **B** implemented but incomplete · **C** in the data but not connected · **D** missing · **E** blocked on unknown PSG2 facts

| System | | Notes |
|---|---|---|
| Main menu and character selection | A | Slots, create with all 18 characters (locked ones show how to unlock; tasks, owning one, gems tested), delete with confirm, Single/Multiplayer |
| World selection and transitions | A | Gatekeeper cards, portals, all 23 worlds load, return to town |
| Movement and combat feedback | A | Jumps, knockback, hit stun, numbers, low-health pulse |
| Monster behaviour and bosses | B / E | Six movement types work, and every arena boss arrives. Bosses have no attack patterns of their own: PSG2's aren't documented |
| Mining, chopping, resources | A | Tool tiers and hits |
| Inventory, equipment, item management | A / D | Everything works by tapping. No drag-and-drop, split or sort (PSG2 is tap-based) |
| Crafting, combining, smelting | A | Every recipe tested |
| Shops, currencies, merchants | A | Every shop item tested |
| Chests, keys, loot, rare drops | A / E | Works; most drop chances are estimates (unpublished) |
| Quests and NPC dialogue | A | All 75 |
| Pets and character progression | A | Hatching, pet effects, switching with confirmation |
| Survival mechanics and stamina | A | Nights, tokens, keys, stamina gates for the Tomb and Snow Valley |
| Town building and storage | A / E | Banka's storage, walls, Wood Wall and campfire. Stone Wall and Torch Stand are blocked (E) |
| Multiplayer sync | A | Two-player test: world, pickups, monsters, walls, trading, chat, emotes, server time |
| Saving, loading, recovery | A | Backups, damaged and old saves, interrupted timers |
| Death, respawn, item recovery | A | Nothing is lost on fainting |
| Settings, audio, interface scaling | A | Sound and Music volume; HUD tested at 4 window shapes |
| Music | A | 7 original loops; made a piece at a time on the web build |

## Final report: polish pass, 2026-10-24
**1. Features completed:**
- music: 7 loops, plus Sound and Music volume;
- new sounds: heal, equip, chest, smelt, the night sting;
- the sound repeat limit;
- cave darkness;
- the character-switch confirmation;
- room-wide town walls;
- a cheat-proof game clock with server time;
- "ready" notices for furnaces, eggs and soils;
- the low-health warning;
- music built a piece at a time where there are no threads (web);
- `progression_audit.gd`.

**2. Bugs fixed:**
- using the character you already are wasted the item;
- town walls differed between players in a room;
- changing the device clock sped up timers and reset dailies;
- the web build would have had no music, because threads are off there.

**3. Tests added (all pass):**
- music: tracks, picking and volume;
- the repeat limit;
- the piece-at-a-time music build;
- darkness at 3 window shapes;
- the switch dialog: Cancel, Become, already that character;
- the clock: device ahead, set back, server time;
- monster AI for all 6 types;
- monster drops;
- mining;
- potions and a pet's effect;
- all 22 item types;
- soils;
- a smelt and an egg across save and load;
- the "ready" notice;
- quit and play again;
- damaged and old saves;
- the HUD at 4 window shapes;
- all 173 combinations, 163 Crafter recipes, 14 smelts, 45 shop items and 75 quests;
- the two-player test: server time and wall sync (rock wall, Torch wall, rebuild, leaving).

**4. Totals:**
- autotest: **219 checks, 0 failures** (170 before this pass);
- two-player test: **52 checks, 0 failures**;
- server tests: 5, OK;
- data audit: 0 hard errors;
- progression audit: 0 softlocks.

**5. Multiplayer tests:**
- host and friend through the real relay server;
- the rock wall the friend broke opens in the host's town;
- the rebuilt town keeps it;
- the Torch wall syncs and stays the friend's unlock;
- the host's own wall comes back after the friend leaves;
- server time is used;
- plus the earlier pickups, monsters, trees, walls, chat, emotes and trading.

**6. Still incomplete:**
- bosses' own attack patterns;
- drag-and-drop, sort and split;
- the collection book and stat icons (from the recording);
- the rainbow cape cosmetics;
- the 3 items waiting for approval;
- public rooms;
- the Steam build;
- hosting the online server (setup ready, waiting on one Deploy click on Render).

**7. Not verifiable from PSG2 sources:**
- drop rates;
- character stats (from 2.o);
- boss attack patterns;
- whether town walls are shared in rooms;
- whether a scroll is used up on an unknown combination;
- PSG2's offline timer behaviour;
- which night gives the Wall Hammer;
- sources for the Blood Long Sword, Stone Wall and Torch Stand.

**8. Temporary assets and dependencies:** none. All art, sound and music are made in code, and the fonts are under the OFL. The online server address is `https://pixel-wilds-brendensob.onrender.com` (set 2026-10-27); it works once the Render service is deployed.

**9. Performance and save risks:**
- Music building takes about 2 s of a background thread at start. On the web it's sliced at about 3 ms per frame, which is untested in a real browser.
- Without a reachable server, a clock moved forward *while the game is closed* still counts once.
- Saves keep one backup (the save before last).

**10. Next three:**
1. Brenden's decision on the 3 items.
2. Host the online server, so trusted time and rooms work for everyone.
3. Bosses' own attack patterns, from the trailer and his videos.
