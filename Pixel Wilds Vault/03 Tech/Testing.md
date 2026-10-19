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
- It ends with `AUTOTEST DONE, 0 failures` and runs **137 checks** (2026-10-17).
- `AT_QUICK=1` stops early, after the town, jump and underground checks.
- Screenshots go to `~/.local/share/godot/app_userdata/Pixel Wilds/shots/`.

## Two-player network test
1. Start the server: `python3 server/pixel_server.py --port 24566 --data <tmp>/names.json`.
2. Run two copies: `-- --nettest host` and `-- --nettest client`.
3. Both must print `NETTEST ... DONE, 0 failures`.

It checks joining, following through portals, drops, chat, **emotes**, walls, trading and leaving.

## Server checks
`python3 server/test_server.py`

## Getting Godot in a fresh cloud container
Download `Godot_v4.3-stable_linux.x86_64.zip` from the godotengine GitHub releases (4.3-stable) and unzip it, for example to `/tmp/godot/`.
