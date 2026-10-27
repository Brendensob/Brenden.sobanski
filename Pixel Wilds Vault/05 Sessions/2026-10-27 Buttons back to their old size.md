---
tags: [session]
---
# 2026-10-27: Buttons back to their old size

**Asked:** "Revert buttons to the same size as before"

![[buttons_old_size.png]]

**Done:**
- The cartoon pass (PR #30) had shrunk the touch buttons:
  - A and B became 44 px circles;
  - ◀ ▶ became 76 × 36 pads.
- They're back at their old sizes and places:
  - ◀ ▶ 90 × 34 at the bottom left;
  - red A 68 × 34 above green B 68 × 34 at the bottom right.
- They keep the cartoon finish: rounded corners, a shine, a shadow, and they sink when pressed.
- The little round AUTO switch moved to just above A.
- Brenden's earlier "Keep the buttons how they were just for the movement and jump" meant this same revert. It was first read as "leave them alone"; [[Decision Log]] is corrected.

**Tests:**
- New check: "the move, A and B buttons keep their old sizes".
- The HUD-fit check passes at 4 window shapes, with the AUTO switch.
- Full autotest: 0 failures.

**Next:** waiting on Brenden.
