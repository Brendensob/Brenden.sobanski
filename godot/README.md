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
  Multiplayer.
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

## Playing with friends

Pick a character slot, then **Multiplayer**:

- **Create Room**: you're the host. The game shows the address your friends type in
  (it's also in the compass menu). Up to 4 players.
- **Join Room**: type the host's address and press Join Room.

How it works, like the original's rooms:
- Everyone keeps their own character, bag, gear, quests, furnaces, chests and seeds,
  saved on their own device.
- The host's game runs the shared world: the map, its monsters, trees and ores, drops,
  walls and the time of day. When anyone takes a portal or picks a world at the
  Gatekeeper, the whole room goes together.
- Monsters chase whoever is closest. Whoever grabs a drop first gets it. Survival
  Tokens go to everyone. Fainting in a room gets you back up at the start of the map.
  Survival keys for dying are single player only, as in the original.
- Tap **Chat..** under the bars (or press T) to talk to the room.

**Trading.** Up and to the left behind the chests in Pixel Town is the Trading Center,
on a ledge you reach by two steps next to the Gatekeeper. An old wooden wall blocks it:
hold a **Torch** (Wood + Fire Crystal + Coal, in the Survival Book) and hit the wall to
burn it down. Inside are the Trader and two trading tables. In a room, stand at a table,
pick a friend who's also in Pixel Town, and when they accept:
- tap items in your bag to put them up (up to 6 stacks) and add coins,
- both press **Ready**; the trade happens only when both are ready, and changing an
  offer un-readies both sides. Both games confirm the trade before any items move.

**Names and friends.** Each name can only be taken once. When you make a character the
game claims the name on the online server; if someone has it, pick another. Your other
character slots can't reuse it either, and a room won't let in two players with the
same name. Deleting a character frees its name. Open **Friends** from the play menu or the
compass menu to add friends by name, accept requests, see who's online, and **Join** a
friend's room straight from the list. You can also add the players in your room from the
compass menu. A character made while the server couldn't be reached can claim its name
later in Friends.

### The online server

Unique names and friends lists need one small server that everyone's game talks to:
`server/pixel_server.py` (plain Python 3, nothing to install).

1. Run it on a computer or cheap server that stays on: `python3 server/pixel_server.py --port 24566`
   (names and friends are saved to `names.json` next to it).
2. Open TCP port 24566 to it.
3. In `scripts/online.gd`, set `ONLINE_SERVER` to `http://<its address>:24566` before
   sharing the game. (For testing: `godot --path . -- --server http://address:24566`.)

Without the server, everything else still works; names just aren't checked online and
the friends list says it can't connect. Run its checks with `python3 server/test_server.py`.

Connecting:
- **Same Wi-Fi:** use the address the host sees (like 192.168.1.5).
- **Over the internet:** the host forwards UDP port 24565 on their router to their
  computer, then friends use the host's public IP. Or, with no router setup, everyone
  installs the same free VPN app (Tailscale, ZeroTier or Radmin VPN), joins one network,
  and uses the host's address in that app.
- **Steam later:** the networking uses Godot's standard multiplayer system, so a Steam
  build can switch to Steam's own connections (GodotSteam) and join through friend
  invites without changing the rest of the game.

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
| `scripts/hud.gd` | HUD, touch buttons, the bag, the Crafter, the main menu, chat and every other menu |
| `scripts/net.gd` | Multiplayer rooms: hosting, joining, and keeping everyone's world in step |
| `scripts/remote_player.gd` | How other players in the room appear on your screen |
| `scripts/online.gd` | Talks to the online server: claiming names, friends, who's online |
| `server/pixel_server.py` | The online server for names and friends lists |
| `tests/autotest.gd` | Plays through the game and saves screenshots |
| `tests/net_test.gd` | Two copies of the game play together over the network |

Run the automatic test with `godot --path . -- --autotest` (add `--touch` to show the phone buttons).
Screenshots are saved to Godot's user data folder under `shots/`.
To test multiplayer, start the online server and two copies: `godot --path . -- --nettest host`
and `godot --path . -- --nettest client`.

## Not built yet

- Joining a stranger's room without an address (friends can join from the friends list)
- Worlds after Ice Cavern and Ghost Arena (Modina Ruins, Nightmare Valley and later)
- Event and gem-shop items, and characters from later updates (Ninja, the buns)
- Phone app export (set it up from **Project → Export** in Godot)

Fonts: Pixelify Sans and Silkscreen, under the SIL Open Font License (see `fonts/`).
