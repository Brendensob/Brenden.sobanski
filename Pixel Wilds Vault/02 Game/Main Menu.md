---
tags: [game, menu]
---
# Main Menu

Laid out like Brenden's 2026-10-20 recording of the real game (see [[PSG2 Screenshot Notes]]).

![[menu_title.png]]

## Title
- The **Pixel Wilds** logo in the middle.
- **Play** and **Options** stacked at the bottom left.
- A green **Invite a friend!** at the bottom right. It shows the game's link with a **Copy link** button.
- **Options**: Sound on/off and Back. (The original also has Support, language, Rate and music. We have no music yet.)

## Select a character
![[menu_select_character.png]]

- Three rows, one per save slot: the character's face, name, and kind plus day.
- A **red X** left of a full slot deletes it, after a "Delete ...? This can't be undone." Yes / No.
- An empty slot says **New character**. Tap it to make one (see [[Characters]]).
- **Menu** at the bottom left goes back to the title.

## After picking a character
![[menu_mode.png]]

- **Single Player**, **Multiplayer** and **Back**, stacked at the bottom left, like the original.
- Multiplayer opens Friends (see [[Multiplayer]]).

## Leaving a game
![[menu_save_and_leave.png]]

- "Save and leave game" in the compass menu (or the bag's menu tab) asks **"Save and Leave Game?" Yes / No**, like the original.
- Yes saves and goes back to **Select a character**.

In code: `_refresh_title()`, `_slot_row()` and the `leave` panel in `hud.gd`.
