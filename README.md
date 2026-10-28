<div align="center">

# 🌲 Pixel Wilds

**A free pixel survival-crafting game, inspired by the mobile classics, without the pay-to-win.**
No shop, no premium currency, no keys and no ads. Everything is earned by playing.

[![Play in your browser](https://img.shields.io/badge/▶_Play-in_your_browser-2ea44f?style=for-the-badge)](https://brendensob.github.io/Brenden.sobanski/)
[![Classic version](https://img.shields.io/badge/Classic-top--down_version-555?style=for-the-badge)](https://brendensob.github.io/Brenden.sobanski/classic/)

[![Web build](https://github.com/Brendensob/Brenden.sobanski/actions/workflows/pages.yml/badge.svg)](https://github.com/Brendensob/Brenden.sobanski/actions/workflows/pages.yml)
![Godot 4.3](https://img.shields.io/badge/Godot-4.3-478cbf?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-355570)

</div>

## Contents

- [Play it](#play-it)
- [The Godot version](#the-godot-version)
- [The classic browser version](#the-classic-browser-version)
- [Project notes (Obsidian)](#project-notes-obsidian)
- [Repo layout](#repo-layout)

## Play it

| Where | How |
|---|---|
| **Phone or any browser** | Open https://brendensob.github.io/Brenden.sobanski/ and turn the phone sideways |
| **Windows PC** | Paste the one-line setup from [`godot/README.md`](godot/README.md#how-to-open-it) into PowerShell, then use the **Pixel Wilds** desktop shortcut |
| **Classic top-down version** | https://brendensob.github.io/Brenden.sobanski/classic/, or open `index.html` |

Every change merged to `main` is rebuilt and published by the **Web build** action.

## The Godot version

The main game, in [`godot/`](godot/): a side-scroller that plays like Pixel Survival Game 2, with
the same kinds of items, recipes, characters, defense and drops, all art redrawn in code, and online
play with friends through a small relay server ([`godot/server/`](godot/server/), deployed on Render
by [`render.yaml`](render.yaml)).

Full details, controls and tests are in [`godot/README.md`](godot/README.md).

## The classic browser version

The first version: a top-down game in plain JavaScript. No install or build step; your island saves
automatically in the browser.

<details>
<summary><b>What's in it</b></summary>

- A randomly generated island with grassland, forest, beaches and rocky highlands
- Day and night: monsters come out after dark, and campfires keep them away
- Health and hunger
- **Mixing pot crafting**: recipes are secret until you discover them by mixing ingredients, then they go in your recipe book
- 21 recipes: tools, weapons, armor, walls, torches, spike traps, food and more
- Monsters: slimes, ghouls, rock spiders, and the Stone Golem boss (with a health bar) every 4th night
- Pets: monsters sometimes drop eggs, which hatch into a buddy that fights with you
- Goals that teach you the game as you go
- Arena mode: endless waves with a best-wave record
- Keyboard, mouse and touch controls

</details>

<details>
<summary><b>Controls</b></summary>

| | Keyboard and mouse | Touch |
|---|---|---|
| Move | WASD or arrow keys | Drag on the left side |
| Hit, eat, or place what you hold | Space, or click | A button, or tap the right side |
| Pick hotbar slot | 1–8, or the mouse wheel | Tap the hotbar |
| Bag and crafting | E | Bag button |
| Pause | Esc | Pause button |

</details>

<details>
<summary><b>Code layout</b></summary>

| File | What it does |
|---|---|
| `js/data.js` | Items, recipes, creatures, pets and goals. Change numbers here to rebalance |
| `js/sprites.js` | All pixel art, drawn from text grids (one letter = one pixel) |
| `js/world.js` | Island generation and the tile map |
| `js/game.js` | Game loop, combat, AI, crafting, saving and drawing |
| `js/ui.js` | HUD, bag, crafting screen and menus |
| `js/input.js` | Keyboard, mouse and touch input |

</details>

## Project notes (Obsidian)

`Pixel Wilds Vault/` is an Obsidian vault with the project's memory: the rules and decisions, every
change, how each part of the game works, research notes and the roadmap.

Open the folder in Obsidian with **Open folder as vault**. Put your own notes in `My Notes`.
`CLAUDE.md` tells Claude to read the vault at the start of each session and keep it updated.

## Repo layout

| Path | What it is |
|---|---|
| [`godot/`](godot/) | The Godot 4.3 game, its tests, tools and online server |
| `index.html`, [`js/`](js/), [`css/`](css/) | The classic top-down browser version |
| [`Pixel Wilds Vault/`](Pixel%20Wilds%20Vault/) | Project notes for Obsidian |
| `setup-windows.ps1`, `Open Pixel Wilds.bat` | One-line Windows setup and the desktop shortcut it makes |
| [`render.yaml`](render.yaml) | Deploys the online server on Render |
| [`.github/workflows/pages.yml`](.github/workflows/pages.yml) | Builds the web version and publishes it to GitHub Pages |

---

All art and code here are original. Made by [Brenden Sobanski](https://github.com/Brendensob).
