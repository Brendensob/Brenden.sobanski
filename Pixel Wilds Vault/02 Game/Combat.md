---
tags: [game, combat]
---
# Combat

Matched to the PSG2 trailer (PR #11, 2026-10-10).

- **Your hits:** a random number from **atk + 1 to atk + weapon damage**. Critical hits are yellow.
- **Monster hits:** `max(0, hit − random(0 … your defense))`. Defense can soak a whole hit to **0**, as in the trailer.
- **Knockback:** small, about 7 px (KNOCK_SPEED 90 for 0.12 s). Heavy monsters and bosses don't move. Monsters barely push you (KNOCKBACK 60).
- **Damage numbers:** big and white with a thick dark outline. They pop in large and squash back to size, and quick hits fan out side by side. Grey "0" for blocked hits.
- **Deaths:** monsters burst into round outlined puffs in their own main color.
- **Swing:** the blade snaps up, slams down past level, holds low for a moment, then comes back. The body stays still. Hold A to keep attacking.
- **Ranged:** bows, cannons and WaazooKaas each use their own ammo. Staffs use mana.
- **Status effects:** poison, fatigue, slow and cold, each for 10 s. Most Hell monsters can poison you.

Code: `GS.roll_attack` and the damage formula in game_state.gd, `take_damage` in mob.gd, numbers in fx.gd.
