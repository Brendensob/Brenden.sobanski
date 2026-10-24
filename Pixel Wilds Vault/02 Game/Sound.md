---
tags: [game, sound]
---
# Sound

Every sound is **synthesized in code** when the game starts (`scripts/sfx.gd`): 8-bit square, triangle, saw and noise blips. There are no sound files, and none of the original's sounds are used.

Sounds:
- **fighting:** swing, hit, crit, mob_die, hurt, die, shoot, cast, boom;
- **gathering:** chop, mine, hammer, burn, break, thud, place;
- **moving:** jump, portal;
- **getting things:** pickup, coin, eat, craft, quest, fail;
- **menus:** click, tap, open, close, night.

New in 2026-10-24: **heal** (potions and healing staffs), **equip**, **chest** (opening a keyed chest), **smelt** (starting a furnace), and the **night** sting at nightfall in Survival Grasslands.

The same sound can't start twice within 45 ms, so fast hits never stack into one loud blast.

## Music
Seven original chiptune loops are composed and synthesized in code (`scripts/music.gd`) in a background thread when the game starts. There are no music files. Each loop is 16 bars, with a lead, a triangle bass, a quiet arpeggio and noise drums.

| Track | Plays |
|---|---|
| menu | Title and menus |
| town | Pixel Town |
| field | Grasslands, Ice Cavern, arenas before the boss, Survival by day, the bright worlds |
| cave | Darklands, Ghost Arena, Tomb, Modina Ruins, Nightmare Valley, and underground in any explore world |
| hell | Hell 1 and 2, Hell Arena |
| boss | Whenever a boss is up |
| danger | Survival Grasslands at night |

Tracks cross-fade over about a second.

## Volume
**Sound** and **Music** buttons in the compass menu and in **Options** on the title. Each tap steps Off → 25% → 50% → 75% → 100%. Both are saved in `user://settings.cfg`.

None of this copies the original's music or sounds.
