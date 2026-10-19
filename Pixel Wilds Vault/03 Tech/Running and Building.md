---
tags: [tech, build]
---
# Running and Building

## Brenden's PC (Windows)
- **One-time setup:** paste in PowerShell:
  `irm https://raw.githubusercontent.com/Brendensob/Brenden.sobanski/main/setup-windows.ps1 | iex`
  It installs Git and Godot 4.3, clones the repo into `%USERPROFILE%\PixelWilds\Brenden.sobanski` and makes a **Pixel Wilds** desktop shortcut.
- **Each time:** the shortcut runs `Open Pixel Wilds.bat`, which:
  1. pulls `main`;
  2. sends `Pixel Wilds Vault/My Notes` up to GitHub;
  3. opens Godot. Press **F5** to play.

## Obsidian
The vault (`Pixel Wilds Vault/`) is opened in Obsidian with **Open folder as vault**. The **Obsidian Git** plugin pulls `main` every 2 minutes, so Claude's updates show up live. Its auto-commit stays off. See [[How to use this vault]].

## Web (phones too)
- https://brendensob.github.io/Brenden.sobanski/ is rebuilt by the **Web build** GitHub Action on every push to `main`.
- The old top-down game is at `/classic/`.

## Exports
`godot/export_presets.cfg` has Windows, Linux and Web presets. Built copies are in `build/`.
