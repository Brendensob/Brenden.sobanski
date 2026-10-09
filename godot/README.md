# Pixel Wilds (Godot version)

A side-scrolling pixel survival crafting game built to play like Pixel Survival Game 2:
the same items, recipes, characters, defense and drop tables (as the fan wikis list them),
with all art redrawn in code, and nothing for sale.

## How to open it

**On a Windows PC, the easy way:** open PowerShell (Start menu, type "PowerShell") and paste

```
irm https://raw.githubusercontent.com/Brendensob/Brenden.sobanski/main/setup-windows.ps1 | iex
```

It installs Git if needed, downloads Godot 4.3 and the game into a `PixelWilds` folder in
your user folder, adds a **Pixel Wilds** shortcut to the desktop and opens the game in Godot.
Press F5 to play. From then on, the desktop shortcut gets the newest version first.

**By hand:**

1. Install **Godot 4.3** or newer from https://godotengine.org (free, no account needed).
2. Open Godot, click **Import**, and pick `project.godot` in this folder.
3. Press **F5** (or the ▶ button) to play.

## Controls

| | Keyboard | Phone |
|---|---|---|
| Move | A / D or arrow keys | ◀ ▶ buttons |
| Jump (B) | K, Space, W or Up | B button |
| Use what you hold (A) | Click, J, X or Enter | A button |
| Bag and combining | E | Backpack (top right) |
| Pick hotbar slot | 1 to 5 | Tap the slot |
| Menu (save and leave) | Esc | Compass (right side) |
| Go back to town | | Bomb (right side, outside town) |

A does whatever fits what you're holding: swing a weapon or tool, cast with a staff,
shoot a bow, eat or drink, place a wall or campfire, or read a book. Like the original,
you talk to villagers and use portals, chests, furnaces, the incubator and the rest by
**hitting them**: face them and press A, and they open when your swing lands. Hold A to keep
attacking. Holding A while you open the bag turns on auto-attack until you press A again.

**Jumping and swinging, timed from the official trailer frame by frame.** B shoots you up
about two blocks in a tenth of a second while your character does one full flip, then you
float down slowly (about 0.8 seconds in the air). Press B again in the air to jump again:
each jump in the air uses one point of the green bar, so a full bar is that many extra jumps
(double, triple and up). Thin ledges can be jumped up through from below.

The red A, green B and grey arrow buttons show on every screen, like the original. On a
computer you can click them, and clicking anywhere in the world hits. A swing snaps the blade up, slams it down past level, holds it low for a moment and
brings it back; the body stays still.

**Sound.** 8-bit sound effects for swings, hits, chopping, mining, jumping, pickups, coins,
hurting, fainting, crafting, quests, portals and menus. They're made in code in the same
chiptune style; the original's sound files are Cobalt's and aren't copied. Turn sound off
or on from the Menu (compass button).

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

Every player who starts the game is the host of their own room: your world is your
room, and up to 3 friends can join it. To join a friend, pick **Join a Friend** on the
play menu (or **Friends** in the compass menu) and press **Join** next to their name.

- **Your IP stays private.** Players never connect to each other directly. All room
  traffic goes through the online server's relay, so nobody in a room (or anyone who
  isn't) can see another player's IP address. The friends list only says whether a
  friend is playing, never where from. Only the server's owner can see connections.
- **Only friends can join.** The relay checks the friends list on the server: someone
  who isn't your accepted friend can't get into your room. Rooms hold 4 players.
- **Names can't be faked.** Your name is tied to a secret key saved with your character,
  so nobody can join as you.
- Joining a friend closes your own room until you come back to your own world.

How rooms work, like the original's:
- Everyone keeps their own character, bag, gear, quests, furnaces, chests and seeds,
  saved on their own device.
- The host's game runs the shared world: the map, its monsters, trees and ores, drops,
  walls and the time of day. When anyone takes a portal or picks a world at the
  Gatekeeper, the whole room goes together.
- Monsters chase whoever is closest. Whoever grabs a drop first gets it. Survival
  Tokens go to everyone. Fainting in a room gets you back up at the start of the map.
  Survival keys for dying are single player only, as in the original.
- Tap **Chat..** under the bars (or press T) to talk to the room.
- Without the online server (or with an unclaimed name), you just play alone.

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

Names, friends lists and rooms need one small server that everyone's game talks to:
`server/pixel_server.py` (plain Python 3, nothing to install). It claims names, keeps
friends lists, and relays room traffic so players never see each other's IP.

1. Run it on a computer or cheap server that stays on: `python3 server/pixel_server.py --port 24566`
   (names and friends are saved to `names.json` next to it).
2. Open TCP ports 24566 (names and friends) and 24567 (room relay) to it.
3. In `scripts/online.gd`, set `ONLINE_SERVER` to `http://<its address>:24566` before
   sharing the game. (For testing: `godot --path . -- --server http://address:24566`.)

Without the server, single player still works; names just aren't checked online, the
friends list says it can't connect, and rooms don't open. Run its checks with `python3 server/test_server.py`.

Nobody needs to set up their router: every player's game only connects out to the
server. Steam later: the room connection is its own small piece (`relay_peer.gd`), so a
Steam build can swap in Steam's relay (GodotSteam) the same way.

## What's in it

**Worlds** (opened by the Gatekeeper in Pixel Town)
- Exploration: Grasslands 1–3, Darklands 1–2, Hell 1–2, Ice Cavern, Modina Ruins, Nightmare
  Valley, Forbidden City and Snow Valley. Big generated maps with
  caves, pits and ledges. Monsters and resources are placed in advance. Deeper levels are
  reached through a purple portal hidden underground. Some levels have a daily Reward Chest.
- Arenas: Grasslands, Darklands, Hell, Dream and Ghost Arena, Mushroom Valley, Fruit Loop and
  Eggcellence. Monsters keep coming and the bosses arrive after 3 minutes.
- The later worlds have the original's monsters and bosses: Golden Slugs, Phantom
  Butterflies and Modina in Modina Ruins; Demon Eyes, Demon Angels, Demon Bats and Doom in
  Nightmare Valley; An An, Ji Ji, He He, Ravens and the Fortune Boss in the Forbidden City;
  Grinches, Snow Turtles, Liches, Fairies, Modina 2 and Evil Santa in Snow Valley; the fruits and
  the Pineapple Killer in Fruit Loop; the cracked eggs, chicks and Harakattu in Eggcellence.
  Their exclusive drops are in too: Blue Blades, Nightmare Ore and Ingots, Dark Hearts,
  Forbidden Stones, Honey and Eggency, plus Modina swords and dresses, Long Lances, Hell
  Spikes (which also mine), Nightmare Blades, Hazard Wipe and the Santa Blade. Volcanic rock
  shows up in the late worlds. In Snow Valley monsters hit 40 harder below 160 defense, and
  in Eggcellence they always do.
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
- Far east, past the furnaces, a massive stone wall. Survive 10 nights in Survival
  Grasslands to earn the Wall Hammer, then smash it: stone steps lead down to a hall under
  the hill where the ninjas (Nini, Nana, Nina) sharpen the Tsurugi up to Tsurugi IV and the
  robots (FC 9912, TT 1001, 2219 OOP) upgrade the Iron Fist staff up to Iron Fist IV, each
  with the original's quest chain.
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
estimates. For the later worlds, monster damage, boss health and the Modina, Long Lance,
Nightmare Blade, Hell Spike, Hazard Wipe and Santa Blade attack and speed are the wiki's;
health the wiki leaves as "?", drop chances, Doom's health and most upgrade recipes are
guesses. All of it lives in `scripts/data.gd`, so it's easy to adjust.

A search for better numbers (fan wikis, forums, GitHub, posted datamines) found that nobody
has published the original's real drop rates; the wikis only list drops as "Rare" or
"Uncommon", apart from the Slime's (about 20% each). So drop chances are still estimates.
Health and damage now follow the wikis' measured values where they exist: Darklands Slimes
125–130, Worms 358–362 and Rexy 462; Hell 1 Mantis 250–300 and Hands 900–1,100; Hell 2
Shadows 1,400, Hands 2,000, Dark Rexy 50,000 and Queens from level 1 to 3. In Hell every
monster except Wizards and bosses can poison you, and arena monsters drop the arena's own
small loot. There is no Hell 3 or Darklands 3 in Pixel Survival Game 2; those are from the
separate Pixel Survival Game 2.o.

Item, character, villager and monster names match the original. Characters based on
other companies' properties (Backstreet Boy, Sailor Moon) and the items that need them
were left out, Iron Man is the Iron Bot here, and the Green Face uses School Girls in place
of Backstreet Boys. The Ninja and Iron Bot were gem-shop characters in the original; here
they come out of Master Chests. The wiki doesn't say which night gives the Wall Hammer, so
night 10 is a guess.
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
| `scripts/relay_peer.gd` | Sends room traffic through the server's relay so IPs stay private |
| `scripts/sfx.gd` | Every sound effect, made in code when the game starts |
| `scripts/remote_player.gd` | How other players in the room appear on your screen |
| `scripts/online.gd` | Talks to the online server: claiming names, friends, who's online |
| `server/pixel_server.py` | The online server: names, friends lists and the room relay |
| `tests/autotest.gd` | Plays through the game and saves screenshots |
| `tests/net_test.gd` | Two copies of the game play together over the network |

Run the automatic test with `godot --path . -- --autotest` (add `--touch` to show the phone buttons).
Screenshots are saved to Godot's user data folder under `shots/`.
To test multiplayer, start the online server and two copies: `godot --path . -- --nettest host`
and `godot --path . -- --nettest client`.

## Not built yet

- Public rooms for strangers (rooms are friends-only)
- Tomb of Makara (the wiki has nothing on it yet)
- Event and gem-shop items, and characters from later updates (the buns)
- Phone app export (set it up from **Project → Export** in Godot)

Fonts: Pixelify Sans and Silkscreen, under the SIL Open Font License (see `fonts/`).
