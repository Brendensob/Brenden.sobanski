---
tags: [game, art]
---
# Art Style

**Pixel art with a cartoon twist** (Brenden, 2026-10-17). Every sprite is drawn **in code** (`scripts/art.gd`). No image files are copied from the original.

![[cartoon_worlds.png]]

## The rules the code applies
- **Outline:** every sprite gets a 1 px dark outline (`#1b1a24`).
- **Cartoon finish** (`Art.cartoon()`, run inside `outline()`):
  - colors get 15% more saturation and 5% more brightness;
  - top edges get a light rim (+22%), bottom edges a shadow (−22%);
  - left edges are lighter (+10%) and right edges darker (−12%);
  - very dark pixels (eyes, details) are left alone.
- **Grass:**
  - a dark line on top with a bright rim under it;
  - **round scallops** hanging into the dirt, with a dark edge;
  - ledges get a dark top line.
- **Damage numbers:** size 10 with a 4 px outline. They pop in at 1.7× and squash back.
- **Death bursts:** round puffs with a dark rim and a highlight, shrinking away.
- **Characters:** chibi (big head, two-dot eyes, stubby legs), drawn from text grids in `Art.LOOKS`.

## Palette
The theme colors for each world are in `Art.THEMES` (grass, dark, hell, ice, dream, modina, nightmare, forbidden, snow, mushroom, fruit, egg, tomb, ghost).

## Cave darkness

![[cave_dark.png]]

In the dark worlds, the screen fades to black away from the player, as in Brenden's Darklands video. This covers Darklands, Ghost Arena, Tomb, Modina Ruins and Nightmare Valley at 78%, and Hell at 60%. Deep underground in any explore world it builds up to 90%.

It's one full-screen shader (`shaders/cave_dark.gdshader`), drawn under the HUD so buttons and bars are never darkened. It measures in screen heights, so the clear circle stays round at any window shape (tested at 16:9, 21:9 and 4:3), and it eases in and out over about a second.

## Ideas not done yet
- Rainbow cape and wings
- See [[Roadmap]]
