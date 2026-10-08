# Pixel Wilds

A free browser survival-crafting game inspired by the mobile classics, without the pay-to-win.
There is no shop, no premium currency, no keys and no ads. Everything is earned by playing.

## Play

Open `index.html` in any modern browser. No install or build step is needed.
Your island saves automatically in the browser.

To play on your phone, turn on GitHub Pages for this repo
(Settings → Pages → Deploy from branch → pick the branch and `/ (root)`), then open the link it gives you.

## What's in it

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

## Controls

| | Keyboard and mouse | Touch |
|---|---|---|
| Move | WASD or arrow keys | Drag on the left side |
| Hit, eat, or place what you hold | Space, or click | A button, or tap the right side |
| Pick hotbar slot | 1–8, or the mouse wheel | Tap the hotbar |
| Bag and crafting | E | Bag button |
| Pause | Esc | Pause button |

## Code layout

| File | What it does |
|---|---|
| `js/data.js` | Items, recipes, creatures, pets and goals. Change numbers here to rebalance |
| `js/sprites.js` | All pixel art, drawn from text grids (one letter = one pixel) |
| `js/world.js` | Island generation and the tile map |
| `js/game.js` | Game loop, combat, AI, crafting, saving and drawing |
| `js/ui.js` | HUD, bag, crafting screen and menus |
| `js/input.js` | Keyboard, mouse and touch input |

All art and code here are original.
