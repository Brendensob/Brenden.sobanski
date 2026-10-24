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

It checks joining, following through portals, drops, chat, **emotes**, walls, trading and leaving.

## Server checks
`python3 server/test_server.py`

## Data audit
```
cd godot
<godot> --headless --path . -s tools/data_audit.gd
```
It checks every id in every table, works out which items can be obtained by playing, and lists items with no use, rare spawns and money loops. It exits with an error if any reference is broken. Run it after changing `data.gd`.

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

## Only the systems checks
`AT_SYSTEMS=1` runs only `systems_check()`, about a minute instead of 12. It covers rewards on a full bag, shops, gear, ammo, mana, keys, furnaces, quests, walls, tool tiers, the token shop, cures, characters and saving.
