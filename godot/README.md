# Pixel Wilds (Godot version)

A side-scrolling pixel survival crafting game built to play like Pixel Survival Game 2:
the same items, recipes, characters, defense and drop tables (as the fan wikis list them),
with all art redrawn in code, and nothing for sale.

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

**Worlds** (opened by the Gatekeeper in Pixel Town)
- Exploration: Grasslands 1–3, Darklands 1–2, Hell 1–2, Ice Cavern. Big generated maps with
  caves, pits and ledges. Monsters and resources are placed in advance. Deeper levels are
  reached through a purple portal hidden underground. Some levels have a daily Reward Chest.
- Arenas: Grasslands, Darklands, Hell, Dream and Ghost Arena. Monsters keep coming and the
  bosses arrive after 3 minutes.
- Survival Grasslands: a long corridor where monsters attack from both sides at night.
  Survive nights for Survival Tokens. Bosses every 6 days. Dying after day 7, 19 or 45
  gives a Silver, Golden or Master Key.

**Pixel Town**
- Gatekeeper (worlds), Brutus (Wood Wall quest: Survival Book and Survival Grasslands),
  Miffie (a long questline that also rewards Pirate, Bad Man and Soldier), GateKeeper
  (Pretzel quest: unlocks the furnaces), Crafter (gear from materials), Merchant, Plumber
  and Miner (token shop). Jumpie waits at the start of Grasslands 1.
- Five furnaces that smelt over time, even while you're away.
- Silver, Golden and Master Chests opened with keys, an Incubator for monster eggs, and
  five magic seed soils behind a rock wall that needs a gold pickaxe (30 hits).

**Characters**
- A new game starts as the Man in Suit or the Nurse.
- Cavemun, Pirate, The Spi, Bad Man, School Girl, Soldier, ChuChu, Drone and Dark Knight
  drop from monsters, bosses and chests. Use one to look like that character. Cavemun,
  Pirate and The Spi also give their weapon (Wood King, Golden Night, Blue Night).
- The Crafter turns characters into hats: Bear Head, Dark Night, Green Face, Soldier Helmet,
  SPY Mask, The Fly, Trooper Pro, Bad Mask, Chuu Hat, Pirate Hat, Cool Hat, Roman Hat and
  Storm Hat. Helmets and armor show on your character.

**Systems**
- Health, mana and stamina (red, blue, green). Attacks use stamina, staffs use mana.
- Defense works like the wiki's defense calculator: a monster hits for its attack
  (doubled on a critical) minus a random number from 0 to your defense, never below 1.
- Bows, Crazy Cannons and WaazooKaas each use their own ammo, made with Combo Book I.
  Snow Balls are thrown by hand.
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

Item, character, villager and monster names match the original. Characters based on
other companies' properties (Backstreet Boy, Sailor Moon, Iron Man) and the items that
need them were left out, and the Green Face uses School Girls in place of Backstreet Boys.
No sprites were copied: every sprite is drawn in code to look like the original's style.
Gems and the gem shop were left out on purpose.

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
- Event and gem-shop items, and characters from later updates (Ninja, the buns)
- Phone app export (set it up from **Project → Export** in Godot)

Fonts: Pixelify Sans and Silkscreen, under the SIL Open Font License (see `fonts/`).
