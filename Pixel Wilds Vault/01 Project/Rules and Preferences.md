---
tags: [project, rules]
---
# Rules and Preferences

Claude follows these every session. They come from Brenden's own instructions; the date each one was given is in [[Decision Log]].

## Sources
- ✅ Use the **PSG2 wiki**: pixelsurvivalgame.fandom.com.
- ✅ Use the **official PSG2 trailer**.
- ✅ Use **Brenden's screenshots and recordings** (see [[PSG2 Screenshot Notes]]).
- ❌ **Don't use the App Store** listing as a source.
- ❌ **Don't use the "2.o" wiki** (pixelsurvivalgame2o.fandom.com). It's a different game (Pixel Survival Game 2.o). Things taken from it, like the first version of Banka, were removed.
- ❌ Don't decompile or copy the original game (APK, sprites, sounds). It's copyrighted.
- If something isn't published, estimate it and write it down in [[Numbers and Estimates]].

## Workflow
- Develop on branch `claude/festive-cannon-1habiq`.
- After every change:
  1. run the tests (see [[Testing]]);
  2. commit and push;
  3. open a PR into `main`;
  4. **merge it**. Brenden asked for this ("do it for me").
- Brenden plays through the desktop shortcut (it pulls `main`) or the web build. A change isn't "done" for him until it's merged.
- Show screenshots of what changed.
- **Update this vault with every change** ([[Decision Log]], [[Changelog]], the affected game notes, and a note in `05 Sessions`), in the same PR, and merge it. Brenden watches the vault live in Obsidian; the Obsidian Git plugin pulls `main` every ~2 minutes.

## Talking with Brenden
- Brenden writes short, quick messages with typos. Read for intent.
- He often sends screenshots or screen recordings of the real game. Treat them as the most exact reference there is.
- Keep replies plain and short. Explain what changed in game terms, not code terms.
- Ask only what he can answer, like a character's name or what something does in the real game.

## Design preferences seen so far
- Closer to the real game is always better: layout, sizes, order of NPCs, HUD placement.
- He likes things "exactly like the game" but welcomes a **cartoon twist** in the art.
- He wants to make money from the game: keep the [[Currencies and Gem Shop|Gem Shop]].
- Pixel Town should be **small and closed in**, like his sketch (see [[Pixel Town]]).
- Combat should feel like the trailer: small knockback, numbers popping up (see [[Combat]]).

## Examples

### Sources: right and wrong
| Situation | ✅ Do | ❌ Don't |
|---|---|---|
| Need a storage NPC | Build it from Brenden's screenshot: 6 backpack tabs, a 5 × 6 grid (PR #15) | Copy "Banka" from the 2.o wiki. That was done in PR #13 and removed in PR #14 |
| Need Hell 3 | Note that PSG2 has no Hell 3 | Add Hell 3 because the 2.o wiki lists it |
| Need a drop rate | Use the wiki's number if there is one (Slime ≈ 20%), otherwise estimate and log it in [[Numbers and Estimates]] | Decompile the APK to find the real number |
| Need a HUD layout | Use the trailer or Brenden's screenshot (gems by the clock, PR #15) | Use App Store screenshots |
| Need emote art | Draw our own in `art.gd` (PR #17) | Copy the original's emote images |

### Reading Brenden's messages
| He wrote | It meant | What was done |
|---|---|---|
| "make the sides symetrical" | Pixel Town's left and right halves should mirror | PR #10 |
| "Where the inventory npc and make the lap layout way closer to the actual one it's too big" | Add the storage NPC, and shrink the town map | PR #13 |
| "Call her banka the spiky hair sells stuff" | The storage girl is Banka, and the spiky blond NPC is the seller (the Merchant) | PR #16 |
| "keep the gem shop I wanna make money from this too" | Keep gems; plan real-money sales | [[Monetization]] |
| "Redo the art style with a twist of cartoon ish and what's on the screen right now" (plus a screenshot) | A cartoon finish, and add every HUD part visible in the screenshot | PR #17 |
| "How to play" | Where to open the game, plus the controls | Answer only, no code |

### One full change, start to finish
1. Brenden sends a screenshot: "make the town like this".
2. Read [[Pixel Town]] and [[PSG2 Screenshot Notes]], and merge `main`.
3. Change `level.gd`, then run the autotest (0 failures) and look at its screenshots.
4. Update the vault:
   - [[Pixel Town]];
   - [[Decision Log]] (with his words);
   - [[Changelog]] (a new row);
   - a session note;
   - if `data.gd` changed, run the data export (see [[Game Data]]).
5. Commit, push, open a PR, merge.
6. Reply in a few lines with a screenshot, and ask only what he can answer.

### Reply style
- ✅ "Banka is in. Hit her to open 6 backpacks. PR: …"
- ❌ "Refactored `GS._move_stack` to merge stacks before…" (that's code talk; keep it in game terms)
