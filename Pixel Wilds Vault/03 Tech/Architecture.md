---
tags: [tech]
---
# Architecture

Godot **4.3**, renderer `gl_compatibility`.
- Viewport 480 × 270, camera zoom 2, tile size 16 px.
- **Autoloads:** `Data`, `Art`, `GS` (game_state), `Net`, `Online`, `Sfx`.

| File (`godot/`) | What it does |
|---|---|
| `scripts/data.gd` | Items, recipes, monsters, worlds, NPCs, shops, chests, pets, `WORLD_CARDS`, `EMOTES` |
| `scripts/art.gd` | All pixel art in code: characters, monsters, icons, tiles, UI, emotes, the cartoon finish |
| `scripts/game_state.gd` | Inventory, storage, equipment, stats, combat formulas, saving |
| `scripts/main.gd` | Map changes, day clock, fainting, title screen, network signal wiring |
| `scripts/level.gd` | Builds every map (town, explore, arena, survival, maze), puppets, numbers, emotes |
| `scripts/player.gd` | Movement, jumps, swinging, magic, bows, eating, building |
| `scripts/mob.gd` | Monsters and bosses |
| `scripts/npc.gd` | Villagers, "New stocked items!" callout |
| `scripts/station.gd` | Furnaces, chests, incubator, soils, gate, sign |
| `scripts/hud.gd` | HUD, touch buttons, bag, storage, Crafter, menus, chat, friends, emotes, world cards |
| `scripts/fx.gd` | Damage numbers and death puffs |
| `scripts/emote.gd` | The emote bubble over a head |
| `scripts/net.gd` | Rooms, world sync, chat, emotes, trading |
| `scripts/relay_peer.gd` | Room traffic through the relay |
| `scripts/remote_player.gd` | Other players on your screen |
| `scripts/online.gd` | Names, friends, who's online |
| `scripts/sfx.gd` | Synthesized sounds |
| `server/pixel_server.py` | The online server (see [[Online Server]]) |
| `tests/autotest.gd`, `tests/net_test.gd` | See [[Testing]] |
| `tools/data_audit.gd` | Checks the data: broken ids, unobtainable items, dead ends, money loops |
| `tools/vault_export.gd` | Writes every data table to the vault's `06 Data` notes |

## Level grid values
`0` empty · `1` solid · `2` one-way ledge · `3` deadly (Tomb of Makara)

## Town constants (level.gd)
`TOWN_W 64`, `TOWN_CEIL 3`, `TOWN_TOP 12`, `TOWN_MID 18`, `TOWN_BASE 24`, `TOWN_ROOM 16`, `TOWN_OPENING [30,34]`, `TOWN_PORTAL (31,17)`, `TOWN_HOLE 57`.
