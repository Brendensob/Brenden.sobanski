---
tags: [project, issues]
---
# Known Issues

- **Character stats come from the 2.o game.** `godot/README.md` says the characters' stats follow Pixel Survival Game 2.o, because PSG2's were never published. Brenden said 2.o is the wrong game. Swap them for PSG2 numbers if any turn up. Until then they stay as estimates.
- **The README credits the 2.o wiki and the App Store** in "Where the numbers come from". That text predates the [[Rules and Preferences|sources rule]]. New work must not use those sources.
- **Three item sources are our guesses** (2026-11-11, see [[Decision Log]]): the Blood Long Sword in the Master Chest (the wiki only says "Long Swords"), the Stone Wall from Wood Wall + Rock (the wiki says the Survival Book makes it but gives no recipe), and the Torch Stand from Torch + Wood (not in PSG2).
- **The Nightmare Long Sword Shield** is on the wiki's Master Chest list but isn't in our items: its stats aren't known.
- **Offline clock change while the game is closed:** with no server reachable, moving the clock forward *before starting the game* still counts once, the same as real time away. Changes while playing do nothing, and moving it back can't rewind. With the server reachable, its time is used.
- **A Combination Scroll is used up even on an unknown combination.** It's unknown whether PSG2 does this.
- **UFOs stay tough in the Darklands.** They hit 15 (wiki) and fly. With Blue Night and iron gear the fight test beats one UFO 7 times in 8, but a UFO plus another monster only about a third of the time. Better defense or armor helps most.
- **Arena bosses and mini-bosses are slow fights** past the Grasslands. The Grasslands Arena was made beatable for low-level players on 2026-11-05 (see [[Combat#Grasslands Arena boss test]]), but a player with no armor at all still loses to both bosses at once. Hands in the Darklands are too strong to fight early; they're optional.
- **The Jelly King's slam waves only show on the host's screen** in multiplayer, and only hurt the host. Single player is fine.
- **Everything past Hell is set aside** (2026-11-05), not finished or deleted: the later worlds and their 73 items are hidden until Grasslands to Hell are perfected (see [[Worlds#Set aside for now (2026-11-05)]]). The data and progression audits still check the whole game, set-aside parts included.
- **Most drop rates are estimates.** Nobody has published them. See [[Numbers and Estimates]].
- **The player blinks right after entering a map.** That's on purpose: a short safe time. In screenshots it can look like the player is missing.
- **The hosted server can fall behind the game** unless the `RENDER_DEPLOY_HOOK` secret is set (see [[Online Server]]). Public games need the server from 2026-10-27 afternoon or later.
- **The free online server sleeps.** After 15 minutes with nobody online, the first player waits about a minute for it to wake. Its saved names can be wiped on a restart; games put themselves back automatically (see [[Online Server]]).
- **Our emotes are our own drawings**, not the original's, to avoid copying its art.
- **The autotest's Tomb of Makara check can fail once in a while** ("0 deadly tiles"): seen once on 2026-11-11 and it passed on the next run. The tomb layout probably comes out without deadly walls on some runs. Not looked into yet.
