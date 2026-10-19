---
tags: [game, emotes, social]
---
# Emotes

Added 2026-10-17 (PR #17), from Brenden's PSG2 screenshot.

- The smiley button right of the bars opens a 7 × 3 panel under the chat box.
- Tap an emote and it **pops up over your head for 3 seconds**, then fades. A new one replaces the old.
- **Everyone in your room sees it** (the `Net.emote` rpc).

Order, matching the screenshot:

| Row 1 | angry, grin, bomb, sleepy, poop, laugh, shock |
|---|---|
| Row 2 | thumbs up, cry, salute, devil, rose, ghost, gift |
| Row 3 | lips, heart, wave, ← ↑ → ↓ |

All 21 are drawn in code by us (`Art.emote_img`), not copied from the original.

Code: `Data.EMOTES`, `Art.emote()`, `scripts/emote.gd` (the bubble), `Level.show_emote`, and `Hud.use_emote` / `toggle_emotes`.
