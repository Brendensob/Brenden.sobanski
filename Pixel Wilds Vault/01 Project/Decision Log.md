---
tags: [project, decisions]
---
# Decision Log

Newest first. Each entry gives the decision, why, and where it came from.

## 2026-10-27 (ground and walls remodel)
- **The ground is drawn like a professional tileset.** Each tile checks its neighbours, so it gets grass caps, outlined and shaded sides, rounded corners and shaded ceilings with roots. *Brenden: "Remodel everything especially the walls around the map like a professional designer would"*
- **The walls around the map are mossy stone walls.** They carry on up past the top of the map, so they never stop in mid-air. Cave worlds have bedrock at the bottom. Pixel Town gets a stone frame, stone-brick room walls and a stone-brick basement.
- **The dark worlds' back walls are brick with moss.** This comes from Brenden's Darklands recording ("dark crisscross brick walls with mossy edges", [[PSG2 Screenshot Notes]]). The tomb gets sandstone blocks and the icy worlds get ice blocks.
- **Jump-through ledges are wooden planks underground**, so they're easy to tell apart from solid ground.
- **The backdrops were redrawn:** better mountains, and a tree line instead of round blobs.
- **No map layouts changed**; only how they look. Characters, monsters, houses and the HUD weren't part of this pass.

## 2026-10-27 (multiplayer menu)
- **Pressing Multiplayer opens its own screen.** It shows the character's name in green and says the name is yours and belongs to this character. Under that are buttons for Friends, Find Public Game and Host Public Game. *Brenden: "when clicked multiplayer make sure player knows they own the name and that's the name of that character they own and there a button for friends list ... and there's also a button for find public or host public".*
- **Friends have a round light:** red when offline, green when online, and green with a Join button when they're in a game. *Brenden: "a blank circle that's red if offline or green if online and green with a join button if in game".*
- **Public games:** Host Public Game opens a room that anyone can join from Find Public Game. A normal host still means friends only. The server decides who may join.
- **Faint screen fixed:** the Wake Up button now sits under the text instead of over the tip. *Brenden: "Make the menu when death fixed".*

## 2026-10-27 (solid progression)
- **Fights are checked by playing them.** A new fight test has a bot fight two monsters at once in every world up to Hell, with the gear you can have by then. Before the changes it lost to Shellys in Grasslands 1 with the starter kit, to Octopuses in Grasslands 2, and to Dark Slimes, Worms and UFOs after that. *Brenden: "make the game progression solid test it and make sure fights arnt impossible and players know what to do".*
- **Starting health 10 instead of 5, and 1 second of safety after a hit instead of 0.6.** Both were our own numbers, not the wiki's. With 5 health a Mummy's 3 left one hit before fainting, and an Octopus's 5 was an instant faint.
- **The starter Sword Cast hits a little harder** (attack 4, was 3), so a brand-new character beats a Shelly plus another monster 7 times in 8 instead of about half the time. The coordinator's brief allowed changing starter damage for this.
- **Potions heal more:** Small 5, Potion 12, Medium 25, Big 60 (were 3, 6, 15, 35). Potion strength was always an estimate; with more health the old ones barely helped.
- **Flying monsters stay knocked back longer** (1 s instead of 0.4 s), so you can fight a UFO.
- **No wiki monster number was changed.** The UFO really hits 15 in the Darklands (wiki), so it stays the toughest common monster there: with iron gear the bot beats one UFO 7 times in 8, but a UFO plus another monster only about a third of the time.
- **A goal card shows what to do next**, with progress and a tap for how, from "Visit the Grasslands" to "Enter Hell", then Miffie's quests. See [[Goals and Guidance]].
- **World cards say how dangerous a world is for your gear** (Easy, Fair, Hard, Deadly), and the faint screen gives one tip.
- Drop rates were not touched (Brenden sets those).

## 2026-10-27 (cleaner cartoon look)
- **The art goes further toward cartoon, but stays pixel art.** Big sprites are smoothed (Scale2x/Scale3x) instead of blown up, and get bold outlines; shadows, glows, clouds and a hazy far mountain range add depth. *Brenden: "make all graohics way cleaner looking more cartoon ish ... give certain things good depth affect and color and use bettere models for anything that may feel off make pop up menus cleangood looking and not annoying"* This answers the open question about how far the cartoon look should go.
- **Menus are rounded cartoon boxes** that pop in over a dimmed game and close with a tap outside. Messages are small bubbles that count up instead of piling up, and clear when a menu opens. Same orange colours as before, so it still reads like PSG2.
- **A and B are round buttons**, ◀ ▶ are rounded pads with arrows. Same places on screen as before.
- **Not changed here:** progression, joining friends and the new characters are other pieces of the same request, handled separately.

## 2026-10-27
- **Every character shows on Create a character; most start locked.** The PSG2 wiki says new characters can only be the Man in Suit or the Nurse at first, and the rest are unlocked by quests, the Gem Shop, Master Chests or the Daily Gift. So all 18 characters are tiles on the screen, locked ones darkened with a padlock and a line saying how to get them. *Brenden: "theres only man in suit and nurse add all the others with some being locked behind gems or other tasks".*
- **Unlocks are for the whole device, not one save.** Owning a character in any save unlocks it for good. A locked one can also be unlocked right on the screen with gems from your saved character that has the most.
- **Tasks:** Miffie's three character quests come from the wiki (Pirate, Bad Man, Soldier). The others are ours: arena clears and Survival Grasslands days, chosen to match each character's gem tier. The Buns, Ninja and Iron Bot stay Gem Shop or chest only. See [[Characters]].
- **Starting as a character with a weapon gives that weapon**, the same as becoming it from the bag.
- **Rooms go over a WebSocket, so phones can join friends.** Brenden plays on his phone in the web build, and browsers can't open the raw connection the relay used, so joining never worked there. The relay now runs as a WebSocket on the server's main port, for every version of the game. *Brenden: "make it so i can join friends had trouble with that".*
- **The server is hosted free on Render**, set up by `render.yaml` with one Deploy click. It gives https (which the web game needs) and redeploys on every merge. Chosen because it needs no card and no server to look after. The cost is that it sleeps when nobody plays and has no saved disk.
- **Games put themselves back on a wiped server.** Each character keeps its name key and friends list, and restores them when the server doesn't know it. A friendship counts only when both sides restore it.

## 2026-10-24
- **Stronger knockback and a hit stun, so the Grasslands are fair for a new character.** The starter Sword Cast does 2–4 a hit, so a Mummy (45 HP) or Shelly (50 HP) takes about 15 hits, while they hit back for 3 and 2 on 5 HP. With the old 7 px push they came right back and traded hits. Now a knockback hit throws a monster about a tile, every hit dazes it so it can't hurt you by touch for a moment, and monsters bounce off you. Health and damage numbers from the wiki were not changed. *Brenden: "its really hard to kill things in grasslands at a starter make the kockback better and the whole cobat better".* This replaces the 2026-10-10 "small knockback from the trailer" rule.
- **Hits feel heavier:** a tiny freeze, a spark, a squash and a small screen shake. A tap of A during a swing is remembered, for phone play.

## 2026-10-20
- **The menus follow Brenden's recording of the real game.** He sent a 52-second recording with no text. It showed the title (Play and Options at the bottom left, green Invite a friend!), Options, "Select a character" rows with red X buttons, Single Player / Multiplayer / Back, and "Save and Leave Game?" Yes / No. All of these were copied in layout (not art). See [[Main Menu]].
- **Villagers call out when you walk up to them**, like in the recording: the Gatekeeper "Where do you wish to go?", Brutus "Looking for the Book of Survival?", the Miner "aghh..". Their name shows the rest of the time, so quests still say who to find.
- **The title no longer says "Nothing to buy, ever."** That stopped being true when the [[Currencies and Gem Shop|Gem Shop]] came in.

## 2026-10-24 (phases 2 to 5 of the polish pass)
- **The progression is checked with the real gates:** `tools/progression_audit.gd` finds 0 softlocks.
- **Every recipe, Crafter item, smelt, shop item and quest in the data is now played by the autotest.**
- **You're told when a smelt, egg or crop is done**, wherever you are.
- **Low health makes the health bar's border pulse red.**
- **Music without threads:** on the web build (threads off), tracks are made a small piece per frame, the needed one first, so the browser never freezes and the music still plays.
- **Not done, on purpose:**
  - item rarity colours (PSG2 has none we know of);
  - drag-and-drop (PSG2 is tap-based);
  - boss attack patterns (not documented).

## 2026-10-24 (Phase 1 of the polish pass)
- **Music is original and synthesized in code.** There are seven loops: menu, town, field, cave, Hell, boss and Survival night. No audio files are used, so nothing needs a licence and nothing copies PSG2. **Sound and Music volume** are in Options and the compass menu.
- **Cave darkness** matches Brenden's Darklands video: dark worlds and deep caves fade the screen edges, drawn under the HUD.
- **Switching character asks first** and says what happens to the current character and gear.
- **The 3 items with no source stay unobtainable** until Brenden picks from the proposals in [[Open Questions]]. The wiki's own page source was searched; the findings are in [[Known Issues]].
- **Town walls in a room:** a wall anyone in the room opened is open for everyone; the unlock is saved for the breaker. *Brenden: "If one player breaks or changes a wall, every player in that town must see the same result."* Pixel Town stays personal (each player's own unlocks), because PSG2's behaviour isn't documented.
- **The game has its own clock:**
  - a steady timer while playing;
  - the online server's time when it can be reached (a new `/time` on the server);
  - never earlier than the last save.
  
  Time away still counts, so honest players lose nothing.

## 2026-10-22
- **A full audit of the game against its data.** `tools/data_audit.gd` checks every reference and works out which items can actually be obtained. The results are in [[Completion Checklist]]. *Brenden asked for a full game audit and completion.*
- **Nothing earned is ever lost.** A full bag drops rewards at your feet: chests, the Crafter, quests, combining, harvests, tokens, trades and multiplayer pickups. A survival key goes to Banka if the bag is full.
- **Saves are crash-safe.** Each save goes to a temp file first, and the previous save is kept as a backup. A damaged save loads from the backup and is kept aside, never deleted.
- **No world locks were invented.** The PSG2 wiki shows every world open at the Gatekeeper. Added the wiki's **12 stamina** rule for Snow Valley.
- **The Nightmare Long Sword drops from the Master Chest**, as the wiki's Chests page lists. The Blood Long Sword, Stone Wall and Torch Stand have no source on the wiki, so they stay unobtainable and are logged in [[Known Issues]].
- **Swinging and pets can't hit through walls.**
- **Becoming a character gives your old one back.** A character's weapon comes only the first time.
- **Healing staffs don't spend mana at full health.**

## 2026-10-19
- **The vault holds all the game's data, plus rules with examples.** Every table in `data.gd` (567 items, 70 monsters, recipes, drops, shops, chests, 75 quests) is exported to `06 Data` by `godot/tools/vault_export.gd`. [[Rules and Preferences]] got worked examples. *Brenden: "store all data in it rules and examples then send it".*
- **Update the vault with every change.** Brenden keeps Obsidian open. Every PR must update the vault, and the Obsidian Git plugin pulls it about every 2 minutes. *Brenden: "obsidan is open rn connec to it and update it everytime a change is made".* A cloud session can't reach his PC directly, so GitHub is the bridge.
- **Set up this Obsidian vault as the project memory**, plus a `CLAUDE.md` file that tells every Claude session to read the vault and keep it updated. *Brenden: "connect to obsidian and make an entire thing for this topic and use it to help memory".*
- **Brenden's own notes go in `My Notes`.** The desktop shortcut pushes that folder to GitHub so Claude can read it.

## 2026-10-17
- **Cartoon twist on the art**, plus the HUD from his screenshot and recording:
  - friend, chat and emote buttons;
  - the emote panel;
  - big damage numbers.
  
  *Brenden: "Redo the art style with a twist of cartoon ish and what's on the screen right now".* → PR #17
- **The storage girl is named Banka**, and **the spiky-haired blond NPC is the Merchant** (he sells stuff). *Brenden's answers.* → PR #16
- **Keep the Gem Shop**: "I wanna make money from this too". See [[Monetization]].
- **The day counter shows only in Survival Grasslands**, and the Daily Free Gift was removed. *"The day counter and rewards for days is only in survival grasslands but no one really cares for it".* → PR #15
- **The HUD follows his screenshots:**
  - gems sit next to the clock;
  - storage is 6 backpacks of 30 slots in the bag screen;
  - the Gatekeeper shows world cards.
  
  → PR #15
- **Only the PSG2 wiki and the trailer count as sources**: "Don't use the App Store wiki and 2.o wiki is the wrong one". The first Banka (from the 2.o wiki) was removed. → PR #14
- **A smaller town and smoother, slightly higher jumps.** *"make the map layout way closer to the actual one it's too big".* → PR #13
- **Web build on GitHub Pages**, so the game plays on phones. → PR #12

## 2026-10-10
- **Combat closer to the original:**
  - damage is random from 1 up to the hit;
  - defense can soak a hit to 0;
  - knockback is small;
  - damage numbers are white.
  
  → PR #11

## 2026-10-09
- **Pixel Town follows Brenden's sketch:**
  - three floors, closed in;
  - an opening in the middle to jump up through;
  - the Gatekeeper right of the portal;
  - symmetrical sides;
  - faster falling.
  
  → PRs #8–#10
- **The research on drop rates and HP came up mostly empty.** Nobody has published PSG2's real drop rates, so they stay estimates. **There is no Hell 3 in PSG2** (it's from 2.o). → PR #4
- **More worlds, mouse clicks to hit, and multi-jumps paid with the green (stamina) bar.** → PR #3
- **Brenden edits and plays in Godot on his PC** with a one-line PowerShell setup and a desktop shortcut that pulls `main`. → PR #2
- **The game starts as a Godot clone of PSG2**:
  - hit NPCs and objects to interact;
  - a swing animation and synthesized sounds.
  
  → PR #1
- **Another Claude session added gems, the Gem Shop and character stats.** Brenden didn't object. → PRs #5–#7
