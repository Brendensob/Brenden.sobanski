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
