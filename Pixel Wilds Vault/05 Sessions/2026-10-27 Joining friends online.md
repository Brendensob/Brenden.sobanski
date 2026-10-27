---
tags: [session]
---
# 2026-10-27: Joining friends online

**Asked:** "make it so i can join friends had trouble with that" (part of a bigger message; other parts went to other threads).

**Why it failed:**
- The game pointed at an online server on `127.0.0.1`, which is only ever your own computer, so nobody could find anyone else.
- The phone/web build can't open the raw connection the room relay used, so even with a server, phones couldn't join.

**Done:**
- The room relay is now a WebSocket on the server's main port (`/relay`). Every version of the game uses it, so phones host and join like computers. See [[Online Server]].
- The server answers the browser's CORS check and uses the `$PORT` a web host gives it.
- `render.yaml` hosts the server free on Render. The game points at `https://pixel-wilds-brendensob.onrender.com`; `godot/server.txt` or `?server=` in the web link can point elsewhere.
- The game waits up to 75 s on its first call, for a sleeping free server to wake.
- Games restore their name and friends when the server has been wiped (`/restore`). A friendship counts only once both sides are back.
- Tests: server tests (8, including a WebSocket room, a big map message, CORS and restore), two-player test over the WebSocket relay (0 failures), autotest.

**Decisions:** see [[Decision Log]] 2026-10-27.

**Later the same day:** Brenden deployed it. The server answers at https://pixel-wilds-brendensob.onrender.com: server time, the browser's CORS check and the WebSocket handshake on `/relay` all work.

**Next:**
- A real phone-to-phone test.
