---
tags: [project, changelog]
---
# Changelog

Every merged pull request on https://github.com/Brendensob/Brenden.sobanski. Newest first.

| PR | Date | What changed |
|---|---|---|
| #52 | 2026-11-11 | Touching a fainted friend's gravestone revives them right away; when the host leaves, the room passes to the player who joined first and the game goes on for everyone on the same maps (the others rejoin by themselves); three-player test |
| #50 | 2026-11-11 | Moving items is dragging only: no Move button; drag onto the trash to throw away (bag, hotbar, gear, Banka); drag into the combine slots, the scroll slot and a trade offer, and back out |
| #51 | 2026-11-11 | About twice as many trees, rocks, ores and plants in every world (136 instead of 71); Survival starts with 100 instead of 70; autotest checks every world has plenty |
| #49 | 2026-11-11 | Every item can be got: Blood Long Sword (and its shield) in the Master Chest, Stone Wall = Wood Wall + Rock and Torch Stand = Torch + Wood with the Survival Book; the data audit fails on any item with no source |
| #48 | 2026-11-10 | Every character, villager and person-shaped monster redrawn (new faces with big eyes, hand-placed shading, hair shine, clothes details); four-step walk, breathing, rise and fall frames, the arm holds your item; shadows and lights shift hue on every sprite; outlines tinted by what they touch; bushy trees; big character pictures stay pixelated |
| #47 | 2026-11-07 | Fainting: a gravestone and a small bar at the top (countdown, are-you-sure, darker screen), friends revive you at your gravestone in a room, off-screen markers for friends. Shared drops for players right next to each other (not boss drops). Portals in a room take one player at a time; nobody is pulled in, but leaving a world takes everyone in it after 20 seconds; "Someone's in the current portal" while it runs. Cartoon cottages for houses; faces get a small mouth (no more orange beak), blush and hair shine; four-tone shading and a shine on every monster. Progression: journey test bot; faster health out of fights; easy monsters at the Grasslands 1 entrance; goal card shows the first goal not done; Copper Pickaxe and Grasslands 2 before 50 Jellies. No more ghost; gem packs for real money (Stripe, switched on with a key on the server); Drop Tables page in the Menu; a fully blocked monster hit still does 1–2 half the time |
| #46 | 2026-11-06 | Clean text (no more letters drifting or outlines landing off them; thinner outlines; dark words brightened; every screenshot checks no writing overlaps); thin crystal shards and detailed ores (icons and rocks); knockback strength and hand size per weapon; worn armour and helmets look like their icons |
| #45 | 2026-11-06 | Hovering an item pops it up with a tick and shows an info card; drag items anywhere (hotbar, bag, gear, Banka's backpacks), same items stack |
| #44 | 2026-11-06 | Smooth Fredoka text, white with a black outline; chests open by hitting them with the key held, loot shoots out (no window); Modina Ruins yellow; no day count on the save slots |
| #43 | 2026-11-06 | Start with the Plunger; monsters drop Small Potions (placeholder chances) and the Grasslands Arena boss a Holy Banana; PSG2 money from the wiki (chest coins 1/10/11/100/111, Pink Egg 10k, Green Egg 20k, Copper Ore 250 at Brutus, wiki sell prices, 99,999 coin cap); bosses drawn twice as big; long weapons drawn twice as big in hand |
| #42 | 2026-11-05 | Grasslands Arena brings one boss (Rexy, Hand or the new Jelly King, a third each); the Jelly King hops, leaps high and slams, sending jelly along the ground you jump over; arena test fights each boss |
| #41 | 2026-11-05 | More slimes in the Grasslands (and they come back), Jelly 30%; Grasslands Arena bosses beatable at a low level (checked by the new `arena_test.gd`) with one free revive in single player; gravestone revive in single player (slow fall, ghost, 3.5 s by the stone within 50 s); Crafter and Gatekeeper 13 tiles apart, opening 10 wide, you start in the gap; everything past Hell set aside (11 worlds, 73 items hidden, nothing deleted) |
| #40 | 2026-11-04 | Roomier maps: Pixel Town 80 tiles wide with villagers about four tiles apart and houses in the gaps, more room upstairs and in the basement; worlds with fewer, spaced-out resources and monsters. Every one of the 567 items has its own icon (`item_icons.gd`, checked by the autotest and `tools/icon_audit.gd`) |
| #39 | 2026-11-04 | Banka's first backpack is free; backpacks 2 to 6 unlock in order for 50 gems each (placeholder); old saves keep any backpack with items in it |
| #38 | 2026-11-04 | Shop roles: the spiky-haired Merchant only buys your items; the Plumber sells everything (tools plus the Merchant's old stock); hints point to the Plumber |
| #37 | 2026-11-04 | Find Public Game: the online server redeploys when its code changes, and a clear message when it's out of date |
| #36 | 2026-10-29 | Portal right under the middle of the town's opening; the Crafter left of it and the Gatekeeper right of it; world card maps drawn like little screenshots (sky, clouds, mountains, grass, caves, trees, ores, arrival portal) |
| #35 | 2026-10-28 | README tagline no longer says "no shop, no ads" |
| #34 | 2026-10-28 | README redone: play buttons and build badge at the top, contents, the Godot version first, classic version details folded away, repo layout table; stray `brenden.sobanski` intro file removed (it moves to a profile README); the old top-down browser version removed from the repo and from `/classic/` on the website |
| #33 | 2026-10-27 | ◀ ▶, A and B back to their old sizes and places (90 × 34 and 68 × 34), keeping the cartoon finish; AUTO switch moved above A |
| #32 | 2026-10-27 | Auto-hit button (swings by itself, even with the bag open; stays on through switching items; Q on a keyboard); the ground gets the sprites' cartoon colour pop and outlines. Ground and walls remodel: tiles with grass caps, outlined sides, rounded corners and rooty ceilings; mossy stone walls at the map edges, bedrock, Pixel Town's stone frame and brick basement; brick, sandstone and ice back walls; plank ledges; spiked deadly walls; smooth depth shading; new mountains and tree line |
| #31 | 2026-10-27 | Faint screen fixed (button under the text); Multiplayer screen with the name you own, Friends, Find and Host Public Game; red/green friend lights with Join; public rooms on the server; tomb test tries both sides of a deadly wall |
| #30 | 2026-10-27 | Solid progression: a fight test that plays every world up to Hell, starter sword attack 4, starting health 10, 1 s of safety after a hit, stronger potions, flying monsters tumble longer; a goal card that says what to do next, danger badges on world cards, a tip when you faint |
| #29 | 2026-10-27 | All 18 characters on Create a character: locked ones show how to unlock them (Miffie quests, arena clears, Survival days, owning one, or gems from a save) |
| #28 | 2026-10-27 | Cleaner cartoon look: rounded menus that pop in over a dimmed game and close with a tap outside, message bubbles that count up, round A/B buttons, rounded bars, smooth big bosses and icons, shadows, portal/drop/ore glows, clouds and hazy far mountains |
| #27 | 2026-10-27 | Vault: the online server is live on Render |
| #26 | 2026-10-27 | Joining friends: rooms over a WebSocket so phones can host and join, the online server set up for free hosting on Render (`render.yaml`), names and friends restored after a server wipe |
| #25 | 2026-10-24 | Progression audit (0 softlocks), tests for every recipe, Crafter item, smelt, shop item and quest, monster AI, item types, damaged and old saves, HUD at 4 window shapes; ready notices, low-health pulse, music for the web build |
| #24 | 2026-10-24 | Music (7 synthesized loops) and volume settings, new sounds, cave darkness, character-switch confirmation, room-wide town walls, a cheat-proof game clock with server time |
| #23 | 2026-10-24 | Combat: knockback about a tile, hit stun (no touch damage while dazed), monsters bounce off you, hit freeze/spark/squash, tap buffer for phones |
| #22 | 2026-10-22 | Full game audit: data checker, completion checklist, rewards never lost on a full bag, crash-safe saves with backup, no hits through walls, character swap keeps the old one, Snow Valley needs 12 stamina, Nightmare Long Sword in the Master Chest |
| #21 | 2026-10-20 | Menus like the real game: title, Options, Invite a friend, Select a character, Single/Multiplayer, Save and Leave Game?; villagers call out when you're near |
| #20 | 2026-10-19 | Vault: `06 Data` with every game table exported from `data.gd`, and rules with examples |
| #19 | 2026-10-19 | Vault: live updates through the Obsidian Git plugin; rule to update the vault with every change |
| #18 | 2026-10-19 | This Obsidian vault, `CLAUDE.md`, and My Notes sync in the desktop shortcut |
| #17 | 2026-10-17 | Cartoon art twist (shading, wavy grass, big damage numbers, puff bursts), friend/chat/emote buttons, 21 emotes synced online |
| #16 | 2026-10-17 | Storage girl named Banka; the Merchant gets spiky blond hair; street order Plumber → Banka → Merchant → Crafter |
| #15 | 2026-10-17 | From his screenshots: gems by the clock, day counter only in Survival, Daily Gift removed, Banka's 6×30 storage, Gatekeeper world cards with map previews, "New stocked items!", Miffie in yellow |
| #14 | 2026-10-17 | Removed the first Banka and storage (taken from the wrong wiki) |
| #13 | 2026-10-17 | Banka's storage (first try), a smaller Pixel Town, smoother and higher jumps |
| #12 | 2026-10-17 | Web build on GitHub Pages, playable on phones |
| #11 | 2026-10-10 | Combat closer to the original: random damage, 0-damage blocks, small knockback, white damage numbers, color bursts |
| #10 | 2026-10-09 | Pixel Town's sides made symmetrical |
| #9 | 2026-10-09 | Pixel Town closed in; jump up through the middle opening; faster falling |
| #8 | 2026-10-09 | Pixel Town on three floors, from Brenden's sketch |
| #7 | 2026-10-09 | Gems, the Gem Shop and every character's stats (another session) |
| #6 | 2026-10-09 | The rest of PSG2's content (another session) |
| #5 | 2026-10-09 | The Crafter's full recipe list (another session) |
| #4 | 2026-10-09 | Darklands and Hell numbers matched to the wiki |
| #3 | 2026-10-09 | New worlds, click to hit, multi-jumps |
| #2 | 2026-10-09 | One-line Windows setup and desktop shortcut |
| #1 | 2026-10-09 | Pixel Wilds: the Godot game (swing, sounds, hit to interact, town, multiplayer, trading) |

> [!note] Keep this up to date
> Add a row for every merged PR, in the same PR.
