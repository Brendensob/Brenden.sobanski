---
tags: [game, combat]
---
# Combat

Matched to the PSG2 trailer (PR #11, 2026-10-10).

- **Your hits:** a random number from **atk + 1 to atk + weapon damage**. Critical hits are yellow.
- **Monster hits:** `max(0, hit − random(0 … your defense))`. Defense can soak a whole hit to **0**, as in the trailer.
- **Knockback strength (2026-11-06):** each weapon has its own strength (`kb` in data.gd, from `Data.weapon_knockback`): 0 for none, 1 at the least (about a tile, what every knockback weapon did before, so early fights stay balanced), up to 2.5. Slow, long and heavy weapons (axes, hammers, clubs, maces, spikes) push hardest; quick little blades (Fluorescents, Gradius, Pops, knives) the least; each upgrade a little more. The distance grows with the strength (1 ≈ a tile, 2 ≈ two) and stronger hits daze a little longer. The info card says light, medium, strong or huge. Our estimates.
- **Knockback:** a knockback weapon throws a monster back about a tile (≈16 px: KNOCK_SPEED 160, slowing by 800/s). Heavy monsters and bosses don't move. Monsters barely push you (KNOCKBACK 60). Changed 2026-10-24: the old 7 px nudge made the Grasslands too hard for a starter (see [[Decision Log]]).
- **Starter weapon:** the **Plunger** (attack 4, 0.4 s a swing), like PSG2, since 2026-11-06. Before that it was the Sword Cast (attack 4, 0.5 s).
- **Potions from monsters:** every Grasslands and Darklands monster can drop a Small Potion (4%, placeholder), Grasslands Arena monsters 6%, and the Grasslands Arena boss can drop a Holy Banana.
- **Bosses are big:** drawn twice the size of before (2026-11-06), with hit boxes to match. Every weapon has its own size in your hand (`size`, from reach and weight: 0.9× to 2.4×, 2026-11-06).
- **Your health:** every character starts with **10 health** (5 before 2026-10-27), plus what their character and gear add.
- **Health comes back** on its own: 1 every 4 seconds once you've gone 6 seconds without being hurt (1 every 12 s after 8 s before 2026-11-07). Ours, not the wiki's.
- **Safe after a hit:** for **1 second** after you're hurt nothing can hurt you again (0.6 s before 2026-10-27). You blink while it lasts.
- **Potions:** Small Potion heals 5, Potion 12, Medium 25, Big 60 (raised 2026-10-27; these were always our estimates).
- **Flying monsters tumble longer:** a knockback hit leaves a flying monster knocked about for 1 s instead of 0.4 s, since it has nothing to land on.
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
`tests/fight_test.gd` plays real fights with a bot that walks up and holds A, against **two monsters at once** (one in front, one from behind), with the gear you'd have by then. The toughest ones (Rexy, UFO, Darklands Worm) are fought one at a time. See [[Testing#Fight test]] and [[Goals and Guidance]].

| Place | Gear by then | Result |
|---|---|---|
| Grasslands 1 | starter Plunger (Sword Cast before 2026-11-06), 3 Small Potions | every monster beaten |
| Grasslands 1 | Gradius, wooden helmet, armor, shield | every monster beaten |
| Grasslands 2 | Golden Night, Stone Armor | every monster beaten, Octopuses too |
| Grasslands 3 | Golden Night, copper gear | every common monster beaten; Rexy one at a time |
| Darklands 1 | Blue Night, iron gear | every common monster beaten; a UFO or Worm one at a time (two UFOs at once usually win) |
| Darklands 2 | Kings Mace, gold gear | every common monster beaten; a UFO or Worm one at a time |
| Hell 1 | Kings Mace, Chainmail, Fear Helmet | not yet: Hell wants Hell-tier gear |

Hands, Dark Rexy and arena bosses are listed but don't count: they're mini-bosses.

## Grasslands Arena boss test
Since the second change on 2026-11-05 the arena brings one boss, so the test fights each one. 4 tries each, after the change:

| Gear | Rexy | Hand | Jelly King |
|---|---|---|---|
| Starter Sword Cast, no armor | 3/4 | 0/4 | 0/4 |
| Gradius + wooden set | 4/4 | 4/4 | 4/4 |
| Golden Night + Stone Armor | 4/4 | 4/4 | 4/4 |
| Golden Night + copper gear | 4/4 | 4/4 | 4/4 |

A fight takes about a minute (Rexy and the Jelly King) or a minute and a half (the Hand). The bot jumps the Jelly King's slam waves when one rolls toward it.

The first change on 2026-11-05, when both bosses still came together:
`tests/arena_test.gd` (`-- --arenatest`) plays the real Grasslands Arena in single player: the last 15 seconds of monsters, then Rexy and the Hand together, with the real free revive and potions when low. Brenden asked for the boss to be beatable by lower-level players (2026-11-05). Before the change no kit won, not even copper gear. After it (8 tries each):

| Gear | Wins | Average time | Free revive used |
|---|---|---|---|
| Starter Sword Cast, no armor | 0/8 | | 8/8 |
| Gradius + wooden helmet, armor, shield | 7/8 | 96 s | 4/8 |
| Golden Night + Stone Armor | 8/8 | 83 s | 0/8 |
| Golden Night + copper gear | 8/8 | 85 s | 0/8 |

The bare starter kit is too weak for two bosses at once; the goal card sends you to the arena after Grasslands 3, by when you have wooden or stone gear. The test also found Hands walking back and forth on a ledge right above you where nobody could reach; monsters that speed up now step off the ledge instead.

## Fainting (single player, 2026-11-05)
- **A slow fall:** you stagger, keel over, lie still a moment and fade. Your **gravestone** rises where you fell.
- **No menu in your face** (since 2026-11-07): a small bar at the top, under the sky clock, says what to do and counts down to Pixel Town ("Back to Pixel Town in 42"), with **Respawn as a ghost** and **Go to Pixel Town**. While your gravestone stands, Go to Pixel Town asks first: "Are you sure? You can still get revived." The world keeps going behind the bar, and **your screen is a little darker** until you're back up. Without a gravestone (Survival, the bomb, the arena after its free revive) the bar counts 10 seconds and then takes you home. The tip shows once you're back in Pixel Town.
- **Respawn** brings you back as a see-through **ghost** at the start of the map. A ghost can walk and jump but can't hit, pick things up or be hurt.
- The gravestone shows how long it has left (**50 seconds**). Stand by it for **3.5 seconds** and a little timer and bar count down over it; then you get back up right there with full health and 3 seconds of safety.
- After 50 seconds it crumbles and you wake up in Pixel Town (nothing is lost, as before).
- **Grasslands Arena:** one free revive instead: the first faint gets you straight back up on the spot. The second sends you home.
- No gravestone in **Survival** (fainting ends the run and gives its keys), or after the bomb button (you meant to go home).
- **Multiplayer** (since 2026-11-07): your gravestone rises too, and everyone in the room sees it in your place. A friend who stands by it for **3.5 seconds** (a bar fills over it) gets you back up right there. There's no ghost in a room. Going to Pixel Town (or the stone crumbling after 50 seconds) takes **only you** home; the room isn't pulled along.
- *Brenden (2026-11-07): "make a gravestone for the dead player dont put a giant menu in his face just put it at the top the timer to despawn and go back to pixel town with a are you sure. you can get revived warning. but when playerds dead darken screen slightly for them and also have one of those things that show where players are when off the screen and the direction with a little square on the edge of youre screen for it. i forgot wehat its called check and make sure you do everything right. and publish right after"*
- *Brenden: "When a player dies in single player they get a option to respawn only make it have a slow animation into a death and then a gravestone and players have 50 seconds to revive by standing close it for 3.5 sec and it shows a little timer"*

![[gravestone_timer.png]]
![[faint_bar.png]]

Code: `scripts/grave.gd`, `show_dead` and the faint bar in hud.gd, the gravestone and revive bar in remote_player.gd, `_slow_fall`, `become_ghost` and `revive_here` in player.gd, `player_died` and `ghost_respawn` in main.gd.

Code: `GS.roll_attack` and the damage formula in game_state.gd, `take_damage`, `can_knock` and `_hit_fx` in mob.gd, `_do_hit` and the tap buffer in player.gd, numbers in fx.gd.
