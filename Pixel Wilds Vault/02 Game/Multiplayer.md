---
tags: [game, multiplayer]
---
# Multiplayer

- **The Multiplayer screen:** your character's name, that it's yours, and Friends, Find Public Game, Host Public Game and Back.
- **Friends list:** each friend has a round light:
  - red: offline;
  - green: online;
  - green with **Join**: in a game you can join.
- **Public games:** **Host Public Game** opens your room as public. It's listed under **Find Public Game** with its player count, and anyone can join. Single Player keeps your room friends-only.
- **Rooms:** your world is your room. Up to 3 friends can join (4 players total).
- **Friends only:** the relay checks the friends list on the server.
- **IPs stay private:** all room traffic goes through the [[Online Server]] relay.
- **Names:** each name can be taken once. It's tied to a secret key saved with the character.
- **Shared world:** the host's game runs the map, monsters, drops and time. Everyone keeps their own bag and gear.
- **Town walls in a room:** each player has their own Pixel Town, built from their own unlocks. In a room, a wall (rock wall, Trading Center wall, stone wall to the basement) is open if **anyone in the room** has opened it, so everyone sees the same town. Breaking a wall opens it on everyone's screen at once. The unlock is saved only for the player who broke it. Others get their own wall back when they leave the room. (A design decision: PSG2's behaviour here isn't documented.)
- **Chat:** the Chat.. box under the bars, or press T.
- **Emotes:** shown to everyone in the room (see [[Emotes]]).
- **Trading:** at the Trading Center tables in [[Pixel Town]]. Each side puts up to 6 stacks plus coins, and both press Ready.
- **Phones and browsers can play online** (since 2026-10-27): rooms go over a WebSocket, so the web build hosts and joins like the computer version. It needs the hosted [[Online Server]].

Code: `net.gd`, `relay_peer.gd`, `remote_player.gd`, `online.gd`. Tested by the two-player test (see [[Testing]]).
