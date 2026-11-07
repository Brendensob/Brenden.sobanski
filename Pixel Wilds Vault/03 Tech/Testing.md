---
tags: [tech, testing]
---
# Testing

Run both before every merge.

## Autotest (plays through the whole game)
```
cd godot
xvfb-run -a <godot> --path . --resolution 960x540 -- --autotest --touch
```
- It ends with `AUTOTEST DONE, 0 failures` and runs **137 checks** (2026-10-17), plus 6 menu and greeting checks (2026-10-20).
- `AT_QUICK=1` stops early, after the town, jump and underground checks.
- **Writing check (2026-11-06):** every screenshot taken while a window is open also checks that no two pieces of writing in it overlap (labels by their real text size, buttons by their caption). A failure names the screenshot, the window and both texts. The title logo's two lines are allowed to touch.
- Screenshots go to `~/.local/share/godot/app_userdata/Pixel Wilds/shots/`.

## Two-player network test
1. Start the server: `python3 server/pixel_server.py --port 24566 --data <tmp>/names.json`.
2. Run two copies: `-- --nettest host` and `-- --nettest client`.
3. Both must print `NETTEST ... DONE, 0 failures`.

Both copies talk to `http://127.0.0.1:24566` by default (the real game uses the hosted server), and rooms go through the WebSocket relay, the same path phones use.

It checks joining, following through portals, drops, chat, **emotes**, walls, trading and leaving.

## Fight test
```
cd godot
<godot> --headless --path . --fixed-fps 60 -- --fighttest
```
- A bot fights **two monsters at once** in every world from Grasslands 1 to Hell 1, with the gear you can make before getting there, 6 times each. It uses the real player, monster AI, knockback, daze and the world's health and damage. It drinks a potion under 40% health.
- Monsters have to be beaten 3 times in 4. "Tough" ones (Rexy in Grasslands 3, the Darklands UFO and Worm) are fought one at a time. Mini-bosses are only printed.
- It also checks that no world on the normal path says **Deadly** on its card with that gear.
- Ends with `FIGHTTEST DONE, 0 failures` and a table. It takes about 20 minutes; `FIGHT_ONLY=grass_1,dark_1` picks worlds, `FIGHT_MOB=ufo` one monster, `FIGHT_TRIALS=n` the tries, `PACK=1` or `PACK=3` the pack size. Run a few at once with different `FIGHT_ONLY` to go faster.

## Journey test
```
cd godot
<godot> --headless --path . --fixed-fps 60 -- --journeytest
```
- A bot plays a **brand-new character through the goal card**:
  - it picks a world from the goal, clears it with real fights, real swings at trees and rocks, and real drops;
  - after Jellies it goes for Slimes, after bars for ore;
  - at most 10 minutes per trip; with a full bag it throws away junk.
- **In town** it hands in quests, combines (Wood Wall, Pretzel, boards, potions), crafts upgrades at the Crafter, smelts in the furnaces (counted in game time), stores the rest with Banka and wears what's better.
- **Walking** between things is counted at walking speed instead of played out, so real players take longer.
- It prints every goal and upgrade with the minute it happened, time spent fighting, harvesting, walking and in town, faints, and the longest stretch with nothing new.
- It checks that every goal up to "Clear the Grassland Arena" is reached.
- `JOURNEY_MINUTES=n` sets the most game time (240). 150 game minutes take about 50 minutes to run.
## Grasslands Arena test
```
cd godot
<godot> --headless --path . --fixed-fps 60 -- --arenatest
```
- A bot plays the real Grasslands Arena in single player: the last 15 seconds of monsters, then Rexy and the Hand together, with the real free revive. It drinks a potion under 40% health and backs off when a boss is above it, so the boss comes down.
- Wooden, stone and copper gear must win 3 times in 4; the bare starter kit is only printed. `ARENA_TRIALS=n` sets the tries (8), `ARENA_KITS=wood,stone` picks kits. About 4 minutes. Ends with `ARENATEST DONE, 0 failures`. Results are in [[Combat#Grasslands Arena boss test]].

## Server checks
`python3 server/test_server.py`: names, friends, the raw relay, a room over the WebSocket relay (including a split message and a big map), the browser's CORS check, and restoring names after a wipe.

## Icon audit
```
cd godot
<godot> --headless --path . -s tools/icon_audit.gd
```
Lists items that share an icon and exits with an error if any do. `AUDIT_SHEET=/path/sheet.png` also saves a picture of every icon.

## Data audit
```
cd godot
<godot> --headless --path . -s tools/data_audit.gd
```
It checks every id in every table, works out which items can be obtained by playing, and lists items with no use, rare spawns and money loops. It exits with an error if any reference is broken. Run it after changing `data.gd`.

## Progression audit
```
cd godot
<godot> --headless --path . -s tools/progression_audit.gd
```
It plays the progression on paper with the real gates: tool tiers, the furnace gate, Survival access, the rock, Torch and hammer walls, books and scrolls, and the stamina for the Tomb and Snow Valley. It prints when each milestone opens and every softlocked item, and exits with an error if anything is softlocked.

## Vault data export
After any change to `scripts/data.gd`, run:
```
cd godot
<godot> --headless --path . -s tools/vault_export.gd
```
It rewrites the notes in `Pixel Wilds Vault/06 Data`.

## Getting Godot in a fresh cloud container
Download `Godot_v4.3-stable_linux.x86_64.zip` from the godotengine GitHub releases (4.3-stable) and unzip it, for example to `/tmp/godot/`.

## What the suites cover now
- **Autotest:**
  - music (7 tracks loop and aren't silent; the right one per place);
  - volume settings and the sound repeat limit;
  - cave darkness (dark worlds, deep caves, under the HUD, 3 window shapes);
  - the switch dialog (Cancel, Become, already that character);
  - the game clock (device clock ahead, set back, server time).
- **Two-player test:**
  - portals: the host goes in alone and the friend stays in town, sees the portal on their street and walks in; a shared drop picked up next to the friend reaches the friend; the friend leaves first on their own copy, a second portal says someone's in the current portal, the host is taken along after the countdown; the friend goes home alone;
  - server time;
  - a friend's broken rock wall opens in the host's town;
  - the rebuilt town keeps it;
  - the Torch wall syncs;
  - the host's own wall comes back after the friend leaves.
- **Server tests:** `/time`.

## Phases 2 to 5 checks (in `gameplay_check` and `content_check`)
- **Monsters:** all 6 movement types; drops come only from the monster's own table.
- **Items:** mining, potions, a pet's effect, all 22 item types, soils.
- **Saving:**
  - a smelt and an egg across save and load;
  - quit to the menu and play again;
  - damaged and old saves.
- **The "ready" notice.**
- **The HUD at 4 window shapes.**
- **All the content:** every combination, Crafter recipe, smelt, shop item and quest.

## Only the menu and auto-hit checks
`AT_MENUS=1` runs the faint screen and Multiplayer screen checks, then `auto_hit_check()` (also part of the full run): the AUTO button lights up, keeps swinging with the bag open, stays on through A and item switches, turns off with the button and back on with Q, and is saved.

## Only the ground art checks
`AT_LOOK=1` runs only `look_check()` (also part of the full run). It builds every world, checks each builds in under 3 s with stone at its edges, and saves screenshots of every world's surface (`70_<world>`), a cave spot (`71_<world>_cave`) and Pixel Town upstairs, in the basement and at the west wall (`72`–`74`), the whole street a screen at a time (`75`), and three spots along the surface of five worlds (`76`). It also checks that every item has its own icon and that the villagers on the street stand at least two tiles apart.

## Only the systems checks
`AT_SYSTEMS=1` runs only `systems_check()`, about a minute instead of 12. It covers rewards on a full bag, shops, gear, ammo, mana, keys, furnaces, quests, walls, tool tiers, the token shop, cures, characters and saving.
