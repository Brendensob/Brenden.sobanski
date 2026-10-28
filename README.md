<div align="center">

# 🌲 Pixel Wilds

**A free side-scrolling pixel survival-crafting game, inspired by Pixel Survival Game 2, without the pay-to-win.**
No shop, no premium currency, no keys and no ads. Everything is earned by playing.

[![Play in your browser](https://img.shields.io/badge/▶_Play-in_your_browser-2ea44f?style=for-the-badge)](https://brendensob.github.io/Brenden.sobanski/)

[![Web build](https://github.com/Brendensob/Brenden.sobanski/actions/workflows/pages.yml/badge.svg)](https://github.com/Brendensob/Brenden.sobanski/actions/workflows/pages.yml)
![Godot 4.3](https://img.shields.io/badge/Godot-4.3-478cbf?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-355570)

</div>

## Contents

- [Play it](#play-it)
- [About the game](#about-the-game)
- [Project notes (Obsidian)](#project-notes-obsidian)
- [Repo layout](#repo-layout)

## Play it

| Where | How |
|---|---|
| **Phone or any browser** | Open https://brendensob.github.io/Brenden.sobanski/ and turn the phone sideways |
| **Windows PC** | Paste the one-line setup from [`godot/README.md`](godot/README.md#how-to-open-it) into PowerShell, then use the **Pixel Wilds** desktop shortcut |

Every change merged to `main` is rebuilt and published by the **Web build** action.

## About the game

The game lives in [`godot/`](godot/): a side-scroller that plays like Pixel Survival Game 2, with
the same kinds of items, recipes, characters, defense and drops, all art redrawn in code, and online
play with friends through a small relay server ([`godot/server/`](godot/server/), deployed on Render
by [`render.yaml`](render.yaml)).

Full details, controls and tests are in [`godot/README.md`](godot/README.md).

## Project notes (Obsidian)

`Pixel Wilds Vault/` is an Obsidian vault with the project's memory: the rules and decisions, every
change, how each part of the game works, research notes and the roadmap.

Open the folder in Obsidian with **Open folder as vault**. Put your own notes in `My Notes`.
`CLAUDE.md` tells Claude to read the vault at the start of each session and keep it updated.

## Repo layout

| Path | What it is |
|---|---|
| [`godot/`](godot/) | The Godot 4.3 game, its tests, tools and online server |
| [`Pixel Wilds Vault/`](Pixel%20Wilds%20Vault/) | Project notes for Obsidian |
| `setup-windows.ps1`, `Open Pixel Wilds.bat` | One-line Windows setup and the desktop shortcut it makes |
| [`render.yaml`](render.yaml) | Deploys the online server on Render |
| [`.github/workflows/pages.yml`](.github/workflows/pages.yml) | Builds the web version and publishes it to GitHub Pages |

---

All art and code here are original. Made by [Brenden Sobanski](https://github.com/Brendensob).
