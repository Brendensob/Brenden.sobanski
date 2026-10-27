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

## Server checks
`python3 server/test_server.py`: names, friends, the raw relay, a room over the WebSocket relay (including a split message and a big map), the browser's CORS check, and restoring names after a wipe.

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

## Only the ground art checks
`AT_LOOK=1` runs only `look_check()` (also part of the full run). It builds every world, checks each builds in under 3 s with stone at its edges, and saves screenshots of every world's surface (`70_<world>`), a cave spot (`71_<world>_cave`) and Pixel Town upstairs, in the basement and at the west wall (`72`–`74`).

## Only the systems checks
`AT_SYSTEMS=1` runs only `systems_check()`, about a minute instead of 12. It covers rewards on a full bag, shops, gear, ammo, mana, keys, furnaces, quests, walls, tool tiers, the token shop, cures, characters and saving.
