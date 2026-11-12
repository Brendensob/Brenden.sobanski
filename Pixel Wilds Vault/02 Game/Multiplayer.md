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
- **Portals take one player at a time** (since 2026-11-07). *Brenden: "when i put a portal down people can go in 1 at a time and it wont take everyone same with leaving put a 20 secv timer..."*, then "make it so mulitplew players can pick up the samne drop when standing by it this doesnt include bosses but it includes breakable loot and normal mobs but only if the players are right next to eachother. fix the death thing to what i told you to do before. and dont make every player go to the portal players can stay in town if they want. but make them leave if in the portal and someone leaves"

  ![[portal_street.png]]

  - **Going into a world** takes only you. Everyone is told "X went into the portal to Y", and players in town get the same portal on their street. **Nobody is pulled in**: you can stay in town as long as you like, or walk through to join.
  - **Leaving a world** (the Town portal, or on to the next world) takes you now. Everyone else **in that world** sees "X left for Y. Everyone here follows in 20 seconds." and a countdown, and is taken along when it ends unless they went first. Players elsewhere aren't affected.

  - **Someone's in the current portal:** while that countdown runs, a portal to anywhere else says "Someone's in the current portal (to Y). Wait until everyone has gone through."

  ![[portal_busy.png]]

  - **How it works:** the host runs the shared map. A guest who goes somewhere the host isn't gets their own copy of the same map (the room keeps one seed per world). When the host comes, everyone there shares the host's map and keeps their spot. Kills made on a copy aren't shared.
- **Off-screen markers** (since 2026-11-07): a friend on your map but off your screen shows as a small square in their own colour at the edge of the screen, with an arrow pointing their way and the first letters of their name. Grey with a cross while they're fainted, so you can find their gravestone. (This is usually called an off-screen indicator.)

  ![[offscreen_marker.png]]

- **Fainting in a room:** your gravestone stands in your place for everyone, and a friend who touches it revives you **right away** (since 2026-11-11) (see [[Combat#Fainting (single player, 2026-11-05)]]).
- **When the host leaves, the game goes on** (since 2026-11-11). *Brenden: "make sure when someone leaves as the host it doesn't end the game and just passes it down"*
  - The room passes to the player who **joined first**. They see "The host left. You're the host now, and the game goes on." Everyone else sees "The host left. Trio1 is the host now." (with the new host's name).
  - **Nobody is sent to the title screen or moved.** Each player stays on the map they were on, where they stood, with the same monsters, trees and drops. The new host's game now runs that map.
  - The others get back into the new host's room by themselves within a couple of seconds, friends or not (the online server lets in everyone who was in the room for a minute). Whoever is on the new host's map shares it again; anyone elsewhere keeps their own copy.
  - A public room stays public. A player who was fainted gets back up, since their gravestone was on the old host's game.
  - If the new host's room can't be reached for about 20 seconds, you keep playing in a room of your own.

  ![[host_passed_on.png]]

- **A dropped connection never ends your game** (since 2026-11-12). Every game opens its own room on the online server, even in single player, so a phone going to sleep, switching from Wi-Fi to data, or the server restarting used to send you to the title screen ("The room was closed."). Now you keep playing where you are. *Brenden: "randomly sometimes it kicks me out even in singleplayer"*
  - Your room reopens by itself in the background (after 2, 5, 10, 20, then every 30 seconds), still public if it was.
  - Alone, you don't see anything. With friends in the room, or as a guest, you see "Lost the connection. You keep playing; your room reopens when it's back." A guest's game takes over the map they're on, like when the host leaves.

- **Shared drops** (since 2026-11-07): when you pick up a drop from a normal monster or something you broke (trees, rocks, ores, plants, pots), every player standing **right next to you** (within 1.5 tiles) gets the same drop too. Boss drops aren't shared. The host checks who is close.
- **Town walls in a room:** each player has their own Pixel Town, built from their own unlocks. In a room, a wall (rock wall, Trading Center wall, stone wall to the basement) is open if **anyone in the room** has opened it, so everyone sees the same town. Breaking a wall opens it on everyone's screen at once. The unlock is saved only for the player who broke it. Others get their own wall back when they leave the room. (A design decision: PSG2's behaviour here isn't documented.)
- **Chat:** the Chat.. box under the bars, or press T. The last 4 messages stay on screen right under the box.
- **Emotes:** shown to everyone in the room (see [[Emotes]]).
- **Trading:** at the Trading Center tables in [[Pixel Town]]. Each side puts up to 6 stacks plus coins, and both press Ready.
- **Phones and browsers can play online** (since 2026-10-27): rooms go over a WebSocket, so the web build hosts and joins like the computer version. It needs the hosted [[Online Server]].

Code: `net.gd`, `relay_peer.gd`, `remote_player.gd`, `online.gd`. Tested by the two-player test (see [[Testing]]).
