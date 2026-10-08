# Pixel Wilds (Godot version)

A side-scrolling pixel survival crafting game built to play like Pixel Survival Game 2,
with its own art, names and characters, and nothing for sale.

## How to open it

1. Install **Godot 4.3** or newer from https://godotengine.org (free, no account needed).
2. Open Godot, click **Import**, and pick `project.godot` in this folder.
3. Press **F5** (or the ▶ button) to play.

## Controls

| | Keyboard | Phone |
|---|---|---|
| Move | A / D or arrow keys | ◀ ▶ buttons |
| Jump (B) | K, Space, W or Up | B button |
| Use what you hold (A) | J, X or Enter | A button |
| Bag and combining | E | Bag button |
| Pick hotbar slot | 1 to 5 | Tap the slot |
| Pause | Esc | II button |

A does whatever fits what you're holding: swing a weapon or tool, cast with a staff,
shoot a bow, eat or drink, place a wall or campfire, or read a book. Standing next to
a villager, portal, chest or furnace, A talks or uses it. Hold A to keep attacking.

## What's in it

**Worlds** (opened by the Portal Keeper in the village)
- Exploration: Grasslands 1–3, Darklands 1–2, Hell 1–2, Ice Cavern. Big generated maps with
  caves, pits and ledges. Monsters and resources are placed in advance. Deeper levels are
  reached through a purple portal hidden underground. Some levels have a daily Reward Chest.
- Arenas: Grasslands, Darklands, Hell, Dream and Ghost Arena. Monsters keep coming and the
  bosses arrive after 3 minutes.
- Survival Grasslands: a long corridor where monsters attack from both sides at night.
  Survive nights for Survival Tokens. Bosses every 6 days. Dying after day 7, 19 or 45
  gives a Silver, Golden or Master Key.

**Pixel Village**
- Portal Keeper (worlds), Gruff (Wood Wall quest: Survival Book and Survival Grasslands),
  Mira (a long questline), Furnace Warden (Pretzel quest: unlocks the furnaces),
  Smith (crafting gear from materials), Merchant, Tool Seller and Miner (token shop).
- Five furnaces that smelt over time, even while you're away.
- Silver, Golden and Master Chests opened with keys, an Incubator for monster eggs, and
  five magic seed soils behind a rock wall that needs a gold pickaxe (30 hits).

**Systems**
- Health, mana and stamina (red, blue, green). Attacks use stamina, staffs use mana.
- Gear: helmet, armor, shield, two rings and a pet, each with attack, defense, magic,
  health, mana and stamina.
- Combining: put 2 or 3 items in the combination slots. Every recipe has a base success
  chance. Having its Combo Book in your bag adds 50%, a Combination Scroll adds 35%.
  Failed or unknown combinations give Dust. Read a book to see its recipes.
- Tools: better axes and pickaxes take fewer hits, and some ores need a minimum tier.
- Status effects from monsters: poison, fatigue, slow and cold, each for 10 seconds.
- Pets regenerate health, mana or stamina, or attack nearby monsters.
- A full day lasts 216 seconds. The game saves on every map change and every 30 seconds.

## Where the numbers come from

Monster health and damage, weapon attack and speed, armor stats, combination success
rates, smelting recipes and times, tool hits, quest steps, day length and survival rewards
follow the community fan wikis for Pixel Survival Game 2
(pixelsurvivalgame.fandom.com and pixelsurvivalgame2o.fandom.com). Where the wikis don't
list something (most drop chances, potion strength, the solo boss fights), the values are
estimates. All of it lives in `scripts/data.gd`, so it's easy to adjust.

Names that belong to the original game, like characters and some unique items, were
replaced with new ones. Gems and the gem shop were left out on purpose.

## Files

| File | What it does |
|---|---|
| `scripts/data.gd` | Items, recipes, smithing, smelting, monsters, worlds, villagers, quests, shops, chests, pets |
| `scripts/art.gd` | All pixel art, drawn in code |
| `scripts/game_state.gd` | Inventory, equipment, stats and combat formulas, crafting rules, timers, saving, controls |
| `scripts/main.gd` | Map changes, day clock, fainting, title screen |
| `scripts/level.gd` | Builds each map: tiles, caves, background, monsters, stations, arena and survival rules |
| `scripts/player.gd` | Movement, attacking, magic, bows, eating, building, status effects |
| `scripts/mob.gd` | Monster and boss behaviour |
| `scripts/station.gd` | Furnaces, chests, incubator, soils, gate, sign |
| `scripts/hud.gd` | HUD, touch buttons and every menu |
| `tests/autotest.gd` | Plays through the game and saves screenshots |

Run the automatic test with `godot --path . -- --autotest` (add `--touch` to show the phone buttons).
Screenshots are saved to Godot's user data folder under `shots/`.

## Not built yet

- Online multiplayer and trading with other players (needs a server, or GodotSteam for Steam)
- Worlds after Ice Cavern and Ghost Arena (Modina Ruins, Nightmare Valley and later)
- Playable characters, cannons, and event items
- Phone app export (set it up from **Project → Export** in Godot)

Fonts: Pixelify Sans and Silkscreen, under the SIL Open Font License (see `fonts/`).
