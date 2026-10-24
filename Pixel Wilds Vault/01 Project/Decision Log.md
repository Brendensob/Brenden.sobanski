---
tags: [project, decisions]
---
# Decision Log

Newest first. Each entry gives the decision, why, and where it came from.

## 2026-10-24
- **Stronger knockback and a hit stun, so the Grasslands are fair for a new character.** The starter Sword Cast does 2–4 a hit, so a Mummy (45 HP) or Shelly (50 HP) takes about 15 hits, while they hit back for 3 and 2 on 5 HP. With the old 7 px push they came right back and traded hits. Now a knockback hit throws a monster about a tile, every hit dazes it so it can't hurt you by touch for a moment, and monsters bounce off you. Health and damage numbers from the wiki were not changed. *Brenden: "its really hard to kill things in grasslands at a starter make the kockback better and the whole cobat better".* This replaces the 2026-10-10 "small knockback from the trailer" rule.
- **Hits feel heavier:** a tiny freeze, a spark, a squash and a small screen shake. A tap of A during a swing is remembered, for phone play.

## 2026-10-20
- **The menus follow Brenden's recording of the real game.** He sent a 52-second recording with no text. It showed the title (Play and Options at the bottom left, green Invite a friend!), Options, "Select a character" rows with red X buttons, Single Player / Multiplayer / Back, and "Save and Leave Game?" Yes / No. All of these were copied in layout (not art). See [[Main Menu]].
- **Villagers call out when you walk up to them**, like in the recording: the Gatekeeper "Where do you wish to go?", Brutus "Looking for the Book of Survival?", the Miner "aghh..". Their name shows the rest of the time, so quests still say who to find.
- **The title no longer says "Nothing to buy, ever."** That stopped being true when the [[Currencies and Gem Shop|Gem Shop]] came in.

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
