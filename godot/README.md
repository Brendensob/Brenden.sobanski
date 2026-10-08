# Pixel Wilds (Godot version)

A side-scrolling pixel survival crafting game, built to play like the classic
mobile pixel survival games. It has its own art and characters, and nothing
is for sale.

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

A does whatever fits what you're holding: swing a weapon, chop with an axe,
mine with a pickaxe, eat food, place a wall or torch, or talk to someone you're
standing next to.

## How it plays

- **Pixel Village** is the hub. Talk to the villagers for quests, sell and buy at Tilly's,
  smelt ore at the furnace once Old Hollis lights it, and use the World portal to travel.
- **Three zones**: Grasslands, Darklands and Hell. Each has 8 levels and a boss lair.
  Reach the right edge of a level to unlock the next one.
- **Lairs** need a key (Crystal + a zone material), and the key is used up each visit.
  Beating the Slime King opens the Darklands; beating the Gloom Eye opens Hell.
- **Combining**: put two items in the Combine slots. Every recipe has a success chance.
  Books in your bag raise the chance, and a failed combination gives Dust.
  Two Dust can become a Crystal.
- **Health, mana, stamina** (red, blue, green): swinging uses stamina, the Fire Wand uses mana,
  and armor raises your maximum health.
- **Day and night**: nights are darker and bring more monsters. Walls block monsters and
  torches light the way.
- **Fainting** sends you back to the village with everything still in your bag.
- The game saves on every map change and every 30 seconds.

## Changing the game

Almost everything lives in `scripts/data.gd`: items, recipes and their chances, monster
health, damage and drop rates, zones, villagers and quests. Grassland slimes use the numbers
listed on the fan wikis (13 HP, 1 damage, 20% Bone/Jelly/Scarab/Snowball, 5.5% rare blade).

| File | What it does |
|---|---|
| `scripts/data.gd` | All game data |
| `scripts/art.gd` | All pixel art, drawn in code |
| `scripts/game_state.gd` | Inventory, stats, quests, saving, controls |
| `scripts/main.gd` | Map changes, day clock, fainting, title screen |
| `scripts/level.gd` | Builds each map: ground, background, trees, portals, monster spawns |
| `scripts/player.gd` | Movement, jumping, swinging, eating, building |
| `scripts/mob.gd` | Monster and boss behaviour |
| `scripts/hud.gd` | HUD, touch buttons and every menu |
| `tests/autotest.gd` | Plays through the game and saves screenshots |

Run the automatic test with `godot --path . -- --autotest` (add `--touch` to show the phone buttons).
Screenshots are saved to Godot's user data folder under `shots/`.

## Not built yet

- Online multiplayer and trading with other players (needs a server)
- The Survival Zone map
- Phone app export (set it up from **Project → Export** in Godot)

Fonts: Pixelify Sans and Silkscreen, under the SIL Open Font License (see `fonts/`).
