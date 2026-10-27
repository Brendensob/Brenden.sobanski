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
  - see [[#The ground and the map's walls (2026-10-27)]] for edges, corners and walls.
- **Damage numbers:** size 10 with a 4 px outline. They pop in at 1.7× and squash back.
- **Death bursts:** round puffs with a dark rim and a highlight, shrinking away.
- **Characters:** chibi (big head, two-dot eyes, stubby legs), drawn from text grids in `Art.LOOKS`.

## Cleaner cartoon look (2026-10-27)

![[clean_bosses.png]]

Brenden asked for "way cleaner", more cartoon-ish graphics with depth and colour (see [[2026-10-27 Cleaner cartoon look]]).
- **Big sprites are smoothed, not blown up.** Bosses, the big chicks and the big bag icons are enlarged with Scale2x/Scale3x (`Art.upscale()`), which rounds off the staircase edges. Big monsters are outlined *before* they're enlarged, so they keep a bold cartoon outline.
- **Soft shadows** sit under the player, friends, villagers, walking monsters and drops.
- **Glows:** portals breathe a soft glow in their colour; drops glow faintly; silver, gold, erbium, volcanic, ice and sandnite rocks twinkle in their own colour.
- **Sky depth:** puffy clouds, then a pale hazy far mountain range, then the mountains (sunny left faces, shaded right faces), then the hills.
- **Clean shapes** (the shadows, glows, clouds and touch buttons) are drawn smooth at 3–4× size and shown scaled down, so they stay sharp on a phone.

## The ground and the map's walls (2026-10-27)

![[ground_before_after.png]]

Brenden asked to *"remodel everything especially the walls around the map like a professional designer would"*. The ground used to be four flat tiles repeated, so map edges, steps and ceilings were plain cut-out blocks. It's now drawn like a tileset (`scripts/terrain.gd`):
- **Every tile looks at its neighbours.**
  - An open top gets a grass cap with a few tufts (sometimes a flower), or a lit lip on a cave floor.
  - An open side gets a dark outline, lit on the left and shaded on the right (light comes from the top left).
  - An open underside gets a shaded edge with lumps, roots or stone drips.
  - Outside corners are rounded off, and grass is shaded where a wall rises beside it.
- **The map's walls:**
  - the left and right edges are **mossy stone walls** that go on up past the top of the map, so they never end in mid-air;
  - the bottom of every cave world is **bedrock**;
  - Pixel Town's roof and outer walls are stone, its two room walls are **stone brick**, and the basement's back wall is stone brick.
- **Back walls in caves** get soft shadows next to the rock and are themed:

| Worlds | Back wall |
|---|---|
| Darklands, Hell, Ghost Arena, Modina Ruins, Nightmare Valley | Brick with moss under the ceilings (from Brenden's Darklands recording) |
| Tomb of Makara | Big sandstone blocks, some with a carved zig-zag |
| Ice Cavern, Snow Valley | Ice blocks with a shine |
| The rest | A dim rock face |

- **Ledges you jump up through** are wooden planks with brackets underground, and thin grassy platforms in the open (arenas).
- **Deadly walls** in the Tomb are dark red brick with glowing cracks and steel spikes on their open sides.
- **Depth:** a shader darkens the ground smoothly the deeper it is under the surface.
- **Dirt** is mostly calm colour, with 16 designs (8, each also flipped), so it doesn't look tiled; a pebble in one design in four.
- The look is baked once per map into 256 × 256 pictures, about 0.2 s per world. The map layout and collisions didn't change.

## Backdrops (2026-10-27)
- **Mountains:** a sunny left face and a shaded right face, a ragged ridge with a lit rim, creases, small snow caps with a zig-zag edge, and haze toward the bottom. The far range is paler.
- **Tree line** instead of round blobs: two rows of treetops (the back row darker), each lit along its top and speckled with leaves. It takes each world's colours, so dark worlds get dark forests.

## Palette
The theme colors for each world are in `Art.THEMES` (grass, dark, hell, ice, dream, modina, nightmare, forbidden, snow, mushroom, fruit, egg, tomb, ghost).

## Cave darkness

![[cave_dark.png]]

In the dark worlds, the screen fades to black away from the player, as in Brenden's Darklands video. This covers Darklands, Ghost Arena, Tomb, Modina Ruins and Nightmare Valley at 78%, and Hell at 60%. Deep underground in any explore world it builds up to 90%.

It's one full-screen shader (`shaders/cave_dark.gdshader`), drawn under the HUD so buttons and bars are never darkened. It measures in screen heights, so the clear circle stays round at any window shape (tested at 16:9, 21:9 and 4:3), and it eases in and out over about a second.

## Ideas not done yet
- Hand-redrawn Evil Santa and lion bosses (they are still simple shapes, now smoothed)
- Rainbow cape and wings
- See [[Roadmap]]
