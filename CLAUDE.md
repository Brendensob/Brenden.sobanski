# Pixel Wilds: instructions for Claude

This repo holds **Pixel Wilds**, a Godot 4.3 game (in `godot/`) that plays like Pixel Survival Game 2. The owner is Brenden.

## Memory: the Obsidian vault
The project memory is the Obsidian vault in `Pixel Wilds Vault/`. Brenden reads it in Obsidian.

**At the start of every session, read:**
1. `Pixel Wilds Vault/Home.md`
2. `Pixel Wilds Vault/01 Project/Rules and Preferences.md`: sources, workflow, how to talk with Brenden
3. `Pixel Wilds Vault/01 Project/Open Questions.md` and `Roadmap.md`
4. Everything in `Pixel Wilds Vault/My Notes/`: Brenden's own notes, ideas and requests. **Never edit this folder.** Fold what it says into the other notes.
5. The game notes in `02 Game/` that touch the task.

**With every change, in the same PR, update** (Brenden keeps Obsidian open, and the Obsidian Git plugin pulls `main` every ~2 minutes, so merge promptly):
- `01 Project/Decision Log.md`: what was decided, why, and Brenden's words.
- `01 Project/Changelog.md`: one row per merged PR.
- The game or tech notes the change affects, so they keep describing the game as it is.
- A new session note in `05 Sessions/` (copy `Templates/Session Log.md`).
- `Open Questions.md`, `Known Issues.md` and `Roadmap.md` when they change.
- If `godot/scripts/data.gd` changed: from `godot/`, run `<godot> --headless --path . -s tools/data_audit.gd` (it must report 0 hard errors), then `-s tools/vault_export.gd`, which rewrites `06 Data`.
- `01 Project/Completion Checklist.md`: update the status of any system you change or test.

Vault style: plain Markdown with `[[wikilinks]]` between notes, short sections, tables for lists. Our own screenshots go in `attachments/`. Never add the original game's images.

## Rules (details in the vault)
- **Sources:** the PSG2 wiki (pixelsurvivalgame.fandom.com), the official trailer, and Brenden's screenshots and videos. **Never** the App Store or the 2.o wiki (pixelsurvivalgame2o.fandom.com). Never decompile or copy the original game.
- **Branch:** `claude/festive-cannon-1habiq`. After each change: run the tests, commit, push, open a PR into `main`, **and merge it**. Brenden asked for every change to be merged.
- First merge `main` in: Brenden's `My Notes` commits arrive there from his PC.
- No model names in commits, PRs or code.
- Show Brenden screenshots of visible changes. Keep replies short and in game terms.

## Tests (see `03 Tech/Testing.md`)
```
cd godot
xvfb-run -a <godot 4.3> --path . --resolution 960x540 -- --autotest --touch   # must end "0 failures"
```
For the two-player test, start `server/pixel_server.py`, then run `-- --nettest host` and `-- --nettest client`.
