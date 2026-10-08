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
| Bag and combining | E | Backpack (top right) |
| Pick hotbar slot | 1 to 5 | Tap the slot |
| Menu (save and leave) | Esc | Compass (right side) |
| Go back to town | | Bomb (right side, outside town) |

A does whatever fits what you're holding: swing a weapon or tool, cast with a staff,
shoot a bow, eat or drink, place a wall or campfire, or read a book. Standing next to
a villager, portal, chest or furnace, A talks or uses it. Hold A to keep attacking.
Like the original, holding A while you open the bag turns on auto-attack until you press A again.

## Menus and screen, laid out like the original

- **Main menu:** Play, then three character slots (each shows the character, name and day,
  with Play and Delete). An empty slot creates a character: pick the Man in Suit or the
  Nurse and type a name (it starts as Player_ and nine numbers). Then Single Player or
  Multiplayer (online play isn't built yet).
- **Screen:** five peach hotbar slots top left (green border on the one you hold), the red,
  blue and green bars under them, the turning sky clock top centre with the day and your
  coins, the backpack, compass and bomb down the right side, grey ◀ ▶ bottom left and the
  red A above the green B bottom right. Your name shows in red above your head. Pickups
  show as "Wood obtained" under the clock. In town there's a Daily Free Gift button.
- **Bag:** the equipment column on the left with the trash and close buttons under it,
  the 5 x 5 bag (top row is the hotbar), the item box under it, and three tabs on the
  right: your character and stats, combining (big result slot, scroll slot, slots I, II,
  III and Combine), and the menu. Tapping items fills the green combination slot.
- **Crafter:** the same layout with weapon, helmet, armor, shield and ring tabs.
- **Day and night:** 216 seconds a day: 99 s of daytime, 45 s of sunset, 72 s of night, then
  straight back to morning. Coming into Pixel Town from the menu always starts in the morning.

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

**Pixel Town**, west to east
- Five magic seed soils behind the rock wall (break it with a gold pickaxe), the Miner
  (seeds and keys for Survival Tokens) and Brutus (Wood Wall quest: Survival Book and
  Survival Grasslands) next to it.
- The Incubator and the Silver, Golden and Master keg chests, each with a signboard
  showing its egg or key.
- The Gatekeeper in the middle (opens portals), Miffie to his right (her 27 quests in the
  original's order), the Merchant in the red hat (Combo Book II for 1,500), the Plumber
  (tools) and the Crafter.
- Up top, the green GateKeeper guards the furnaces (Pretzel quest). Five furnaces with
  signboards; a bubble with the bar pops up when one is done.
- Jumpie, the girl who looks like Miffie, is in Grasslands 1 (10 Jellies for a Pixel Coin).
  The GateKeeper turns up in Hell 2 missing his mask: bring a Green Face and he sells Em
  Stones for 92,500 coins.

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
- The game saves on every map change and every 30 seconds, into the character's slot.

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
Gems and the gem shop were left out on purpose: quests that gave gems give that many
Silver Keys instead.

The screen layout, bag, combining panel, Crafter tabs, sky clock, furnace row and chest
signboards follow the game's official trailer and App Store screenshots. The main menu's
three character slots and character creation follow the wiki; the exact look of the
original's menu screens isn't documented anywhere I could find, so those screens are a
best match.

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
| `scripts/hud.gd` | HUD, touch buttons, the bag, the Crafter, the main menu and every other menu |
| `tests/autotest.gd` | Plays through the game and saves screenshots |

Run the automatic test with `godot --path . -- --autotest` (add `--touch` to show the phone buttons).
Screenshots are saved to Godot's user data folder under `shots/`.

## Not built yet

- Online multiplayer and trading with other players (needs a server, or GodotSteam for Steam)
- Worlds after Ice Cavern and Ghost Arena (Modina Ruins, Nightmare Valley and later)
- Event and gem-shop items, and characters from later updates (Ninja, the buns)
- Phone app export (set it up from **Project → Export** in Godot)

Fonts: Pixelify Sans and Silkscreen, under the SIL Open Font License (see `fonts/`).
