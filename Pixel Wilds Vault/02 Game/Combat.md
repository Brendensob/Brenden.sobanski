---
tags: [game, combat]
---
# Combat

Matched to the PSG2 trailer (PR #11, 2026-10-10).

- **Your hits:** a random number from **atk + 1 to atk + weapon damage**. Critical hits are yellow.
- **Monster hits:** `max(0, hit − random(0 … your defense))`. Defense can soak a whole hit to **0**, as in the trailer.
- **Knockback:** a knockback weapon throws a monster back about a tile (≈16 px: KNOCK_SPEED 160, slowing by 800/s). Heavy monsters and bosses don't move. Monsters barely push you (KNOCKBACK 60). Changed 2026-10-24: the old 7 px nudge made the Grasslands too hard for a starter (see [[Decision Log]]).
- **Your health:** every character starts with **10 health** (5 before 2026-10-27), plus what their character and gear add.
- **Safe after a hit:** for **1 second** after you're hurt nothing can hurt you again (0.6 s before 2026-10-27). You blink while it lasts.
- **Potions:** Small Potion heals 5, Potion 12, Medium 25, Big 60 (raised 2026-10-27; these were always our estimates).
- **Flying monsters tumble longer:** a knockback hit leaves a flying monster knocked about for 0.7 s instead of 0.4 s, since it has nothing to land on.
- **Hit stun:** every hit dazes an ordinary monster. It stops for a moment (0.4 s after knockback, 0.3 s without) and **can't hurt you by touch while dazed**. A hit also stops a Mummy's charge.
- **Bounce off:** a monster that touches you bounces back a little instead of sitting on you.
- **Hit feel:** a tiny freeze (0.06 s) when a blow lands, a white spark, the monster squashes, and the screen shakes a little.
- **Tap buffer:** tapping A during a swing is remembered for 0.2 s and swings as soon as it can, so quick taps on a phone aren't lost.
- **Reach:** a swing also hits a monster standing on top of you.
- **Damage numbers:** big and white with a thick dark outline. They pop in large and squash back to size, and quick hits fan out side by side. Grey "0" for blocked hits.
- **Deaths:** monsters burst into round outlined puffs in their own main color.
- **Swing:** the blade snaps up, slams down past level, holds low for a moment, then comes back. The body stays still. Hold A to keep attacking.
- **Ranged:** bows, cannons and WaazooKaas each use their own ammo. Staffs use mana.
- **Walls:** swings and pets can't hit monsters on the other side of a wall (thin ledges don't block).
- **Healing staffs** don't cast, or spend mana, at full health.
- **Status effects:** poison, fatigue, slow and cold, each for 10 s. Most Hell monsters can poison you.

## Can you win? (the fight test)
`tests/fight_test.gd` plays real fights with a bot that walks up and holds A, against **two monsters at once** (one in front, one from behind), with the gear you'd have by then. See [[Testing#Fight test]] and [[Goals and Guidance]].

| Place | Gear by then | Result |
|---|---|---|
| Grasslands 1 | starter Sword Cast, 3 Small Potions | every monster beaten |
| Grasslands 1 | Gradius, wooden helmet, armor, shield | every monster beaten |
| Grasslands 2 | Golden Night, Stone Armor | every monster beaten, Octopuses too |
| Grasslands 3 | Golden Night, copper gear | every common monster beaten |
| Darklands 1 | Blue Night, iron gear | every common monster beaten; UFOs about half the time |
| Darklands 2 | Kings Mace, gold gear | every common monster beaten; UFOs about half the time |
| Hell 1 | Kings Mace, Chainmail, Fear Helmet | not yet: Hell wants Hell-tier gear |

Hands, Dark Rexy and arena bosses are listed but don't count: they're mini-bosses.

Code: `GS.roll_attack` and the damage formula in game_state.gd, `take_damage`, `can_knock` and `_hit_fx` in mob.gd, `_do_hit` and the tap buffer in player.gd, numbers in fx.gd.
