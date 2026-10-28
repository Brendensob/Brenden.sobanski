---
tags: [session]
---
# 2026-10-28: GitHub clean-up

**Asked:** "can you make my github way cleaner and better looking and organized"

**Done:**
- **README redone:** Play in your browser and Classic buttons, the Web build status badge, a contents list, a "Play it" table (phone, Windows PC, classic), the Godot version first, the classic version's features, controls and code layout folded into dropdowns, and a repo layout table.
- **Removed the stray `brenden.sobanski` file** (a two-line intro). That text belongs in a profile README.
- **Deleted the old top-down browser version:** `index.html`, `js/`, `css/`, the Web build step that copied it to `/classic/`, and its README section. *"theres 2 pixel wilds in i dont want the old one delete that"*
- **Took "no shop, no ads" out of the README tagline.** *"dont say no ads or no shop"*
- No Godot game code changed, so no game tests were needed.

**Decisions:** in [[Decision Log]].

**Next:**
- Brenden adds a description, website link and topics in the repo's About box (Claude can't change repo settings).
- Brenden creates a `Brendensob` repo for the profile README.
- Decide whether to delete the old merged `claude/...` branches and the `rewards-farmer` fork.
