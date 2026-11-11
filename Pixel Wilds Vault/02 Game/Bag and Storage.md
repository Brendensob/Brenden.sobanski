---
tags: [game, bag, storage]
---
# Bag and Storage

![[storage.png]]

## Bag
- The equipment column is on the left (helmet, armor, shield, two rings, pet), with trash and close under it.
- The 5 × 5 bag: its top row is the hotbar.
- Three tabs on the right:
  - **character and stats**, which also shows your coins;
  - **combining** (result slot, scroll slot, slots I, II and III, Combine);
  - **menu**.

## Hovering and dragging items (2026-11-06)
- **Hover** over any item (hotbar, bag, gear, backpack): its icon pops up and brightens with a soft tick, and a dark card beside it shows the name, its attack or stats or healing, what it does, and its sell price.
- **Drag** any item to move it, any time, even with the bag closed (along the hotbar). Drop it on another slot to swap, on the same item to stack, on the matching gear slot to wear it, from a gear slot back to a bag slot to take it off, and in and out of Banka's open backpack. A drop where it doesn't fit leaves it where it was. The slot it lands in bounces.
- On a phone, dragging works with a finger too. Tapping an item still shows its card and its Use, Equip, Read, Become and Hold buttons.
- *"When hovering over items make it satisfying and show info and you can drag to move them anytime"*

## Moving is dragging only (2026-11-11)
- The **Move** button is gone. To move an item, drag it.
- **Trash:** drag an item onto the trash can (from the bag, the hotbar, a gear slot or Banka's backpack) and it drops on the ground in front of you. Tapping the trash says how.
- **Combining:** drag items from the bag onto slots I, II and III, or a Combination Scroll onto the scroll slot. Drag an item out of a slot back to the bag to take it out. Tapping still works too.
- **Trading:** drag items from your bag onto "You give", and drag them back off to take them out.
- *"when moving a item to your trash just let the player drag it and get rid of the move button make everything movable dragging"*

![[drag_to_trash_2026-11-11.png]]

![[hover_card_2026-11-06.png]]

## A full bag never loses anything
Rewards that don't fit drop at your feet as your own pickup. In multiplayer only you can pick them up. That covers chests, the Crafter, quests, combining, seed harvests, Survival Tokens, trades and room pickups. A survival key earned while fainting goes to Banka's storage if the bag is full.

## Storage (Banka)
- Hit **Banka** on the street (see [[NPCs]]) and the bag opens in storage mode.
- **6 backpack tabs**, each a **5 × 6 grid** (30 slots), like Brenden's screenshot.
- **The first backpack is free. Each one after it costs gems** (50 each for now, a placeholder for Brenden to set), unlocked in order. A locked tab shows a padlock; tap it for an **Unlock** button, or **Get gems** if you're short. Nothing can be put in a locked backpack.
- Old saves keep every backpack that already has items in it.
- Tap an item in your bag to put it in the open backpack. Tap it in the backpack to take it back. Stacks merge where they can.
- Saved with the character (`GS.storage`).

History:
1. The first storage (PR #13) came from the 2.o wiki and was removed (PR #14).
2. It was rebuilt from Brenden's screenshot (PR #15).
3. It was named Banka on his word (PR #16).
4. Backpacks 2 to 6 cost gems, as Brenden asked (2026-11-04).
