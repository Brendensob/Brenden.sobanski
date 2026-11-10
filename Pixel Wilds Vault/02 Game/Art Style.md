---
tags: [game, art]
---
# Art Style

**Pixel art with a cartoon twist** (Brenden, 2026-10-17). Every sprite is drawn **in code** (`scripts/art.gd`). No image files are copied from the original.

![[cartoon_worlds.png]]

## The rules the code applies
- **Outline:** every sprite gets a 1 px dark outline, tinted by the colour it touches (2026-11-10; it was flat `#1b1a24`).
- **Cartoon finish** (`Art.cartoon()`, run inside `outline()`):
  - colors get 15% more saturation and 5% more brightness;
  - top edges get a light rim, bottom edges a shadow;
  - left edges are lighter and right edges darker;
  - lights and shadows shift hue (2026-11-10), they aren't just lighter and darker;
  - very dark pixels (eyes, details) are left alone.
- **Grass:**
  - a dark line on top with a bright rim under it;
  - **round scallops** hanging into the dirt, with a dark edge;
  - see [[#The ground and the map's walls (2026-10-27)]] for edges, corners and walls.
- **Text (2026-11-06):** every word on screen is smooth, not pixelated: the round **Fredoka** font (OFL), in **white with a black outline**. Coloured text (names, damage numbers, warnings) keeps its colour with the same outline. Names and numbers in the world use a copy drawn 8× finer so the camera's zoom doesn't make them blocky. The old pixel fonts (Pixelify Sans, Silkscreen) are no longer used. *"make the words on the screen non pixelated and js smooth white letters with black outline"*

![[smooth_text_2026-11-06.png]]

- **Clean text (2026-11-06):** letters are placed at quarter pixels without hinting and are no longer snapped to the 480×270 grid (`snap_2d_vertices_to_pixel` off), so gaps between letters stay even and outlines sit on their letters. Outlines are a fifth of the letter size (`Art.outline_for`: 2 for most text). Dark coloured words are brightened to read on the black outline. The autotest checks every open window for overlapping writing.
- **Crystals and ores (2026-11-06):** crystals are thin shards on a small rock, ores a shaded rock with shiny faceted nuggets. Ore rocks in the world have shaded faces, cracks and lit nuggets; ice and erbium rocks grow thin crystal shards (`Art.nugget`, `Art.shard`).
- **Worn gear (2026-11-06):** armour and helmets on your character take the shapes of their icons (`ItemIcons.armor_parts` and `ItemIcons.helmet_kind` are shared), so no two look like the same piece in another colour.
- **Held weapons (2026-11-06):** drawn from a smooth 4× copy of the icon at the weapon's own size.

![[clean_text_gear_2026-11-06.png]]

- **Damage numbers:** size 10 with a 2 px outline. They pop in at 1.7× and squash back.
- **Death bursts:** round puffs with a dark rim and a highlight, shrinking away.
- **Characters:** chibi, redrawn 2026-11-10. See [[#Characters (2026-11-10)]].

## Characters (2026-11-10)

![[characters_redrawn_2026-11-10.png]]

*Brenden: "go study on whaqt works well for looks while keeping it pixelated i think all charecters should be redone"*
- **Same size as before** (12 wide: a 9-row head, a 5-row body, 3 rows of legs, 4 spare rows on top for hats), so hitboxes, helmets and armour still fit.
- **Face:** big 2 × 2 eyes with a white glint, a small mouth, blush on people. The head is centred over the body.
- **Shading by hand,** lit from the top left: a shine on the hair, a lit shoulder, the right arm and leg in shadow. Characters skip the automatic rim and shine (`cartoon()` and `volume()`), which were noisy at this size.
- **Each has its own details:** the suit's lapels and tie, the Pirate's striped shirt and eyepatch, Cavemun's spotted pelt, Banka's pigtails with red ties, the Plumber's moustache and overalls, the Miner's hard hat with a lamp, robots with a visor and lit eyes, ninjas in hoods.
- **Frames:** `stand`, `idle` (breathing: head and body sink a pixel, feet stay put), `walk0`–`walk3` (stride, pass, stride, pass, with a bob), `jump` (legs tucked) and `fall`. Holding an item stretches the front arm out to its grip.

![[character_frames_2026-11-10.png]]

- **Big pictures** (create screen, bag) are the same pixels enlarged, not smoothed.
- In code: `Art.HEADS`, `Art.BODIES`, `Art.LEGS`, `Art.FRAME_DEF` and `Art.LOOKS` (each look: colours, `head`, `over` for hair and hats, `wear` for clothes, hidden under armour).

## What we learned about pixel art (2026-11-10)
From Brandon James Greer and AdamCYounis on YouTube, Slynyrd's Pixelblog, the Innkeep "eight ways to improve your pixel art characters" article and Pixnote:

| Lesson | What the game does |
|---|---|
| Shift the hue along a ramp: shadows cooler, lights warmer | `Art.shade()`: shadows drift to blue-violet and gain colour, lights drift to yellow. Used by every sprite's finish |
| One light direction, no "pillow" shading | Top left for everything |
| Two or three colours per part, 6 to 12 per character | Base, shadow and highlight for hair, skin, clothes, legs and shoes |
| Make the face pop | The brightest part, with the darkest eyes |
| Tint the outline, never pure black | `Art.ink()`: each outline pixel is a very dark copy of the colour it touches |
| A clear silhouette | Hats, hair, ears and capes change the outline |
| A walk needs contact and passing poses and a 1-pixel bob | Four frames at 10 a second |
| Don't mix pixel sizes | Enlarged characters keep square pixels |

![[tree_before_after_2026-11-10.png]]

- **Trees (2026-11-10):** a crown of leaf clumps, lit on the top left and shaded underneath, on a trunk with bark and roots.

## Cleaner cartoon look (2026-10-27)

![[clean_bosses.png]]

Brenden asked for "way cleaner", more cartoon-ish graphics with depth and colour (see [[2026-10-27 Cleaner cartoon look]]).
- **Bosses are big, like PSG2** (2026-11-06): drawn twice as big as ordinary monsters' scale (the King and Queen are about four times your height). Rexy, Dark Rexy and the Hand are twice as big when they come as an arena's boss. Weapons have their own size in your hand (see Held weapons above).
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

## Houses, villagers and monsters (2026-11-07)

![[art_houses_people_monsters.png]]

*Brenden: "now do the same for houses villagers and monsters test out the progression make sure players can actually develop good at grasslands while having fun and progress to better areas"*
- **Houses** are little cartoon cottages:
  - a shingled roof with eaves, a ridge cap and a round attic window;
  - a brick chimney;
  - wooden siding between corner posts, with shade under the eaves;
  - framed windows with a shine and flower boxes;
  - an arched door with a brass knob and a stone step, and a stone foundation.
- **Villagers' faces:**
  - the mouth used to be 3 bright orange pixels poking out past the chin, like a beak. Now it's a small dark-red mouth inside the face;
  - people get a touch of blush on the cheeks. Masks, robots, mummies and zombies don't;
  - hair gets a small shine.
- **Shading** (`Art.volume()`), for every monster, pet and character:
  - the top quarter of the body is lit and the bottom third shaded;
  - the right edge is a little darker;
  - a small shine sits up on the top left;
  - eyes and very dark or white details are left alone. With the cartoon rim on top, that's four tones, so they look round instead of flat.
- `look_check()` saves sheets of every monster (`75_monsters`, close-up `78_common_monsters`), every villager (`76_villagers`) and the houses (`77_houses`).
## Item icons (2026-11-04)

![[item_icons_sheet.png]]

Every one of the 567 items has its own icon, still on the 10 × 10 grid with the outline and cartoon finish. Brenden: *"i need models for every item"*.
- Materials, food, books, keys, seeds, eggs and placeables use the templates in `Art.ICON_GRIDS`, now with no two alike (gems in their own colours, a small shard for the Small Evil Crystal, spotted eggs for the event eggs, a torch stand for the placeable Torch).
- Potions grow with their size: vial, bottle, flask, jug.
- Weapons, staffs, bows, cannons, ammo, armour, helmets, shields and rings are drawn by `scripts/item_icons.gd` from their name: blade length, tip (point, clip, fork, hook, round), width, curve, teeth, guard (bar, cross, crescent, disc, wings), pommel; helmet shape (dome, visor, crest, horns, wings, hats, hood, masks, animal heads); shield shape (heater, round, kite, tower, buckler) and emblem; ring stone (heart, drop, flame, skull, shield...). Themed ones have their own shapes: candy canes, lollipops, Christmas trees, carrots, ice pops, the ninja star, the twin blades.
- **Upgrades keep the family's shape** and gain marks: 2 a gem in the guard, 3 a gem in the pommel, 4 a rune, 5 a sparkle, U gold trim and two sparkles.
- Pets use their own sprite; Jr pets are drawn smaller.
- `tools/icon_audit.gd` lists any items that share a picture (and `AUDIT_SHEET=file.png` saves a sheet of every icon). The autotest checks it too.

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
