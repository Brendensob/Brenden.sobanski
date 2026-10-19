---
tags: [tech, server]
---
# Online Server

`godot/server/pixel_server.py` is plain Python 3 with nothing to install. It does three things:
- claims names;
- keeps friends lists (saved to `names.json`);
- relays room traffic, so players never see each other's IP.

- **Ports:** TCP 24566 (names and friends), 24567 (room relay).
- **Pointing the game at it:** set `ONLINE_SERVER` in `scripts/online.gd`, or use `-- --server http://address:24566` for testing.
- **Not hosted anywhere yet.** See [[Roadmap]].
- **For Steam:** swap `relay_peer.gd` for Steam's relay (GodotSteam).
