---
tags: [game, movement]
---
# Movement and Jumping

- **Jump (B):** a fast launch about 2.9 blocks high (~46 px) in about 0.2 s, with one full flip. Gravity halves near the top for a smooth peak. About 0.63 s in the air.
- **Air jumps:** press B again in the air. **Each air jump costs 1 point of the green (stamina) bar**, so a full bar means many extra jumps.
- **Falling:** faster than the first version (Brenden asked for it), capped at 120 px/s.
- **Thin ledges:** jump up through them from below.

| Constant (player.gd) | Value |
|---|---|
| JUMP | −490 |
| RISE_GRAVITY | 2900 |
| APEX_SPEED | 80 (gravity halved below this) |
| FALL_GRAVITY | 1100 |
| MAX_FALL | 120 |
| AIR_JUMP_COST | 1 stamina |

History: multi-jumps were added in PR #3, and the jump was made smoother and a little higher in PR #13.
