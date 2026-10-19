---
tags: [game, multiplayer]
---
# Multiplayer

- **Rooms:** your world is your room. Up to 3 friends can join (4 players total).
- **Friends only:** the relay checks the friends list on the server.
- **IPs stay private:** all room traffic goes through the [[Online Server]] relay.
- **Names:** each name can be taken once. It's tied to a secret key saved with the character.
- **Shared world:** the host's game runs the map, monsters, drops and time. Everyone keeps their own bag and gear.
- **Chat:** the Chat.. box under the bars, or press T.
- **Emotes:** shown to everyone in the room (see [[Emotes]]).
- **Trading:** at the Trading Center tables in [[Pixel Town]]. Each side puts up to 6 stacks plus coins, and both press Ready.
- The browser version can't go online yet; single player works there.

Code: `net.gd`, `relay_peer.gd`, `remote_player.gd`, `online.gd`. Tested by the two-player test (see [[Testing]]).
