---
tags: [project, decisions]
---
# Decision Log

Newest first. Each entry gives the decision, why, and where it came from.

## 2026-11-11 (instant revive, the host passes the room on)
*Brenden: "When someone dies make sure it's able to rez them right away. ... make sure when someone leaves as the host it doesn't end the game and just passes it down"*
- **Touching a friend's gravestone revives them right away.** No more standing by it for 3.5 seconds, and it works from the moment they fall.
- **When the host leaves, the room passes to the player who joined first.** Nobody goes to the title screen: every player stays on their map, where they stood, and the new host's game takes over that map as it was (same monsters, trees, drops, arena or Survival progress). The others get back into the new host's room by themselves. Why the first to join: it's predictable, and it's what the online server already knows.
- **Everyone who was in the room may rejoin the new host for a minute, friends or not.** Rooms are friends-only, and the guests might not be friends with each other.
- **A fainted player gets back up when the host changes**, because their gravestone lived on the old host's game. Simpler and kinder than sending them home.
- **The live server must be redeployed** for the hand-over; the deploy workflow does this when its secret is set.

## 2026-11-11 (moving items is dragging)
*Brenden: "when moving a item to your trash just let the player drag it and get rid of the move button make everything movable dragging"*
- **The Move button is gone.** Items move only by dragging.
- **The trash takes drags** from the bag, hotbar, gear slots and Banka's backpack. The item still drops on the ground in front of you, as the old trash did. Tapping the trash explains it.
- **Every slot that holds an item takes drags:** combine slots I to III and the scroll slot, and "You give" in a trade.
- **Kept:** tapping an item to see its card and Use, Equip, Read, Become and Hold; tapping a stack at Banka to send it across; tapping items on the combine page. These are quick, not "move" buttons.

## 2026-11-11 (more resources in the worlds)
*Brenden: "make there be more rec sources in the areas"*
- **Read as:** more trees, rocks, ores and plants in every world.
- **About twice as many:** 0.8 per column in explore worlds (136 in a normal world, was 71); Survival starts with 100 (was 70). See [[Worlds#Resources and spacing]].
- **Still not cluttered:** one empty tile between any two and two beside a tree (was two and three), and none where you arrive. This partly undoes the 2026-11-04 spacing, because Brenden now asks for more; monsters stay spread out as before.
- The world mix (which ores and trees each world has) didn't change.

## 2026-11-11 (every item obtainable)
*Brenden: "make sure every item is obtainable"*
- **The 3 items with no source now have one**, using the proposals that were waiting in [[Open Questions]]. His ask counts as the yes.
  - **Blood Long Sword:** in the Master Chest, as one of the wiki's "Long Swords" there. The Blood Long Sword Shield, which the wiki names in the Master Chest, joined it.
  - **Stone Wall:** a Survival Book combination, **Wood Wall + Rock** (90%). The proposal was Rock + Rock + Wood Wall, but the same stack can't go in two slots, so one Rock is used.
  - **Torch Stand:** kept, and made from **Torch + Wood** (90%) with the Survival Book. It isn't in PSG2; it's ours.
- **The data audit now fails** if any item has no source, so this can't slip back.
- **Past Hell stays set aside.** Brenden picked "Keep them set aside for now" on 2026-11-12; its 73 items come back when those worlds open.

## 2026-11-10 (every character redrawn)
*Brenden: "go study on whaqt works well for looks while keeping it pixelated i think all charecters should be redone and test everything out to make it works good"*
- **Studied first.** What pixel artists teach (Brandon James Greer, AdamCYounis, Slynyrd's Pixelblog, the Innkeep "eight ways" article, Pixnote): one light direction, short colour ramps that shift hue, few colours per part, a face that pops, outlines tinted by what they touch, a strong silhouette, and a walk that bobs. The list is in [[Art Style#What we learned about pixel art (2026-11-10)]].
- **All 44 people redrawn** on the same 12-wide grid, so hitboxes, hats, armour and the hand position didn't move: the 18 playable characters, the villagers, and the monsters shaped like people.
- **Shading is drawn by hand now** for people. The automatic rim and shine made small sprites noisy, so characters skip them.
- **Shadows shift toward blue-violet and lights toward yellow** everywhere (monsters, items, rocks, houses), instead of plain darker and lighter.
- **Outlines take the colour they touch** (very dark red around red, dark brown around skin), still dark enough to read on a phone.
- **Still pixelated:** big character pictures in menus are plain enlarged pixels now, not smoothed.
- **Movement:** a four-step walk with a bob, breathing while standing, a rise and a fall in the air, and the front arm reaching out to hold the item in your hand.
- **Trees** have a bushy crown and bark instead of a green ball on a stick.
- **Left alone:** the HUD and menus (Brenden, 2026-11-04), boss sizes, and held weapons.

## 2026-11-07 (no ghost, gem packs, drop tables, defense chip)
- **The ghost is gone.** *Brenden: "get rid of ghost thing"*. On your own the gravestone counts 10 s and you wake in Pixel Town; in a room friends still revive you at your gravestone (50 s).
- **Gems for real money** through Stripe Checkout. *Brenden: "make gems purchasable with real money"*. Stripe works on the web build and needs only a small check on our server; Steam or app-store purchases would need those stores. Prices (100/550/1,200/2,500 gems for $0.99/$4.99/$9.99/$19.99) are placeholders. Needs `STRIPE_SECRET_KEY` on Render, and the Stripe account needs an adult. See [[Monetization]].
- **Drop Tables page** in the Menu and in `06 Data/Drop Tables.md`. *Brenden: "make a drop table for every mob in the game that i can see so ik what to test n stuff"*
- **Defense can't block everything.** When defense soaks a whole hit, it's a coin flip whether you still take 1–2. *Brenden: "make it so you cant completly remove dmg from mobs with high def its just a 50 50 chance for them to hit you for 1-2"*

## 2026-11-07 (fainting bar, gravestones in rooms, off-screen markers)
- **This is "the death thing".** *Brenden: "make a gravestone for the dead player dont put a giant menu in his face just put it at the top the timer to despawn and go back to pixel town with a are you sure. you can get revived warning. but when playerds dead darken screen slightly for them and also have one of those things that show where players are when off the screen and the direction with a little square on the edge of youre screen for it. i forgot wehat its called check and make sure you do everything right. and publish right after"*
- **No big faint menu.** A small bar under the sky clock shows the countdown to Pixel Town and the buttons. Going home while a gravestone stands asks "Are you sure? You can still get revived." The tip shows once you're back in Pixel Town.
- **The screen darkens a little** while you're fainted, ghost included.
- **Gravestones in rooms:** friends see yours in your place and revive you by standing by it for 3.5 s (the same time as a ghost in single player). Giving up, or the stone crumbling after 50 s, takes only you home.
- **Off-screen markers** for friends: a coloured square with an arrow at the edge of the screen, grey with a cross if they're fainted.
- The single-player ghost and the Grasslands Arena's free revive (2026-11-05) are unchanged.

## 2026-11-07 (shared drops; portals don't pull you in)
- **Shared drops:** picking up a drop from a normal monster or a broken tree, rock, ore, plant or pot gives the same drop to every player right next to you (within 1.5 tiles). Boss drops (arena bosses, boss monsters) aren't shared. *Brenden: "make it so mulitplew players can pick up the samne drop when standing by it this doesnt include bosses but it includes breakable loot and normal mobs but only if the players are right next to eachother. fix the death thing to what i told you to do before. and dont make every player go to the portal players can stay in town if they want. but make them leave if in the portal and someone leaves"*
- **Going into a world no longer pulls anyone in.** Players can stay in town. The 20-second countdown is only for **leaving**: when someone leaves a world, everyone else in that world follows after 20 seconds.
- **"Fix the death thing to what I told you to do before":** the only earlier instruction in the notes is "Make the menu when death fixed" (the faint screen layout, fixed 2026-10-27). It checks out at computer, wide-phone and tall-phone shapes. Brenden answered with the next message (see the entry above).

## 2026-11-07 (portals one at a time in rooms)
- **A portal takes only the player who goes in.** The rest follow through the portal, or are taken along after 20 seconds. Leaving works the same way. *(Changed the same day: entering no longer pulls anyone in; see above.)* *Brenden: "when i put a portal down people can go in 1 at a time and it wont take everyone same with leaving put a 20 secv timer and then  it takes everyoine back if there not back alr and if someones in a portal then it says someones in the current portal"*
- **While someone is going through, other portals say "Someone's in the current portal"** and don't open, so the room never splits between two worlds.
- **The host still runs the shared map.** A guest who goes first plays a copy of the same map (the same seed) for up to 20 seconds, until the host arrives; then the copy is swapped for the host's map and the guest keeps their spot.
- Before, any portal or Gatekeeper pick moved the whole room at once.

## 2026-11-07 (houses, villagers, monsters, and the Grasslands progression)
- **Houses, villagers and monsters were redrawn like the ground** (see [[Art Style]]):
  - cartoon cottages for the houses;
  - a proper small mouth instead of the orange "beak" on every face, with blush and a hair shine;
  - four-tone shading and a shine on every monster. *Brenden: "now do the same for houses villagers and monsters test out the progression make sure players can actually develop good at grasslands while having fun and progress to better areas"*
- **The progression was playtested by a bot** that plays a new character through the goal card ([[Testing#Journey test]]). What it found and what changed:
  - **New players fainted on their first two trips** (in under 3 minutes). Fix: health comes back 1 every 4 s after 6 s out of a fight (was 1 every 12 s after 8 s), and Grasslands 1 only places Slimes and Firas near the way in.
  - **The goal card hid goals.** Doing a later goal early (the Copper Pickaxe) hid "50 Jellies" for good, and the card asked for "10 Iron Bars", which Miffie can't take before her Jelly and Copper quests. Fix: the card shows the first goal not done.
  - **50 Jellies was a 3-hour grind.** Brenden's own fix from 2026-11-05 covers most of it (Jelly 30%, more Slimes that come back; see below). On top of it, the goal card now puts the Copper Pickaxe and Grasslands 2 before the 50 Jellies, so Jellies pile up while you explore. (This session's own 1–2 Jellies per drop and general monster respawn were dropped in favour of his.)
- **No wiki number changed here:** monster health and damage, quest amounts.
- After the changes the bot reached Grasslands 2 at 54 minutes, Golden Night at 108 and Blue Night at 151, with one faint (two Rexys and a Dark Rexy in Grasslands 3).
## 2026-11-06 (clean text, crystals and ores, distinct weapons and armour)
*"Fix all these little bugs where the writing looks weird and double check to make sure there's nothing like that I need the game clean asf also make crystals better looking and thinner same with orders give them more detail and the armor and weopon a should be all diff in knockback and size and everything and look distinct from each other same with the armors and helms"*
- **The weird writing:** letters were snapped to the game's small 480×270 grid before being stretched to the screen, so gaps between letters came and went and outlines landed off their letters. Turned off vertex snapping (`snap_2d_vertices_to_pixel`; sprites still snap by position), letters are placed at quarter pixels without hinting, and outlines are about a fifth of the letter size (2 for most text, was 3). Dark coloured words (brown, orange, green, red) are lifted so they don't vanish into the black outline.
- **Double-checked:** every autotest screenshot of an open window now checks that no two pieces of writing overlap. It found the stats page's Coins line running into the tip below it, now fixed.
- **Read "orders" as ores.** Crystals are thin shards (a tall one and two short ones on a little rock) with a lit face, a dark face and a bright tip. Ore icons are a shaded rock with shiny faceted nuggets. In the world, ore rocks have shaded faces, cracks and lit nuggets, and ice and erbium rocks grow thin crystal shards.
- **Every weapon feels different:** knockback is a strength now, not on/off: slow, long, heavy weapons (axes, hammers, clubs, maces, spikes) push hardest, quick small blades (Fluorescents, Gradius, Pops, knives) the least, and each upgrade a touch more. **No weapon pushes weaker than before** (1, about a tile): the Grasslands Arena's balance test failed when the Gradius pushed less, so the light ones stay at 1 and the rest go up to 2.5. Lances, Modina swords and the others that had none still have none. The info card says "Reach N, light/medium/strong/huge knockback". These strengths are **our estimates** (PSG2's aren't published).
- **Every weapon is its own size in your hand,** from its reach and weight (0.9× for a Gradius up to 2.4× for a Long Lance), drawn from a smooth 4× copy so no size looks blocky. This replaces "reach 24+ is 2×".
- **Worn armour and helmets look like their icons:** armour adds its shoulders (pads, spikes, round), collar, belt with a gem buckle, chest pattern (plates, rivets, emblem, chain rings, scales, skull, snowflake, eye) and leg guards; robes and dresses get a skirt. Helmets take their icon's shape (dome, knight's visor, plume, horns, wings, crown, hood, mask, top hat, witch hat, robot, pumpkin and more). Upgrades add a gem.

## 2026-11-06 (hover cards and dragging items)
*"When hovering over items make it satisfying and show info and you can drag to move them anytime"*
- **Hover:** the icon pops up (1.2×, springy) and brightens with a quiet tick, and an info card shows the name, stats, description and sell price. Read "satisfying" as that pop, sound and a bounce when an item lands.
- **Drag anytime:** hotbar (even with the bag closed), bag, gear slots and Banka's backpacks. Same items stack; gear only drops on its own slot. Tapping and the Move button still work.

## 2026-11-06 (smooth text, chests you hit, yellow Modina Ruins, no days outside Survival)
*"There's ui bugs make the works on the screen non pixelated and js smooth white letters with black outline and when opening a chest there's not open you just it with your key and items shoot out also modi's ruins is yellow and don't show days for players that's a survival grasslands only"*
- **Smooth text:** all words use the round Fredoka font instead of pixel fonts, white with a black outline (coloured text keeps its colour). Read "words on the screen" as all text, menus and HUD included.
- **Chests have no Open window.** Hold the key and hit the chest: one key is used and the items shoot out of it as pickups. Not holding it gives a hint. The world reward chests pop open on a hit too.
- **Modina Ruins is yellow.** Read "modi's ruins is yellow" as "should be yellow": its sky, hills and ground went from poison green to gold.
- **No day count outside Survival Grasslands.** The HUD already showed days only there; the save-slot list also said "Day N", and that's gone.

## 2026-11-06 (plunger start, potion drops, PSG2 money, bigger bosses)
*"Make the starting weopon the plunger make sure potions can be dropped and other heals are obtainable make sure the money system is simaller certain Weapons are bigger and bosses are like way bigger in thre real game"*
- **Everyone starts with the Plunger** instead of the Sword Cast (the wiki calls it "probably the first weapon you'll ever use"). The Sword Cast still comes from Silver Chests.
- **Monsters drop potions.** Read "potions can be dropped" as monsters dropping them. Every Grasslands and Darklands monster can drop a Small Potion, and Grasslands Arena monsters drop Small Potions and Herbs. The chances (4% and 6%) are **placeholders for Brenden to set**.
- **Other heals:** the Grasslands Arena boss can now drop a Holy Banana (the wiki lists it for the Hand). Potions, Medium and Big Potions, Rejuvenate Potions, the Pretzel, the Campfire and Healing Staffs were already obtainable (the progression check confirms every one).
- **Money like PSG2, using the wiki's numbers:** Silver Chests can hold 1, 10, 11, 100 or 111 Pixel Coins; the Plumber sells the Pink Egg for 10,000 and the Green Egg for 20,000 (was 10,000); Brutus sells Copper Ore for 250; sell prices for Fira 1 (was 60), Gold and Erbium Pickaxes 50 (was 25), and the Gradius can't be sold. Coins stop at 99,999, the original's limit. Other prices were already the wiki's or stay our estimates. Gems stay the third currency.
- **Bosses are drawn twice as big:** King, Queen, Butterfly Boss, Ghost Boss, Doom and Makara, and Rexy, Dark Rexy and the Hand when they come as an arena's boss. Modina, Evil Santa, the Pineapple Killer, the Fortune Boss and Harakattu, already drawn big, grew by a third. The Jelly King stays as Brenden approved him. Their hit boxes grew with them.
- **Long weapons are drawn twice as big in your hand:** every weapon with reach 24 or more (long swords, Excalibur, pole axes, lances, Modina swords, Devil Spikes, the later Moon Blades and the like). Read "certain weapons" as the long ones, since those are the big ones in the original. Short swords, tools and the Plunger stay icon-sized.

## 2026-11-05 (one arena boss, the Jelly King)
- **The Grasslands Arena brings one boss, not two:** Rexy, the Hand or the new Jelly King, a third of the time each. Rexy and the Hand keep the lower health and hit from earlier today. *"Don't make rexy and hand come out together make it 33% chance for each"*
- **The Jelly King** is our own boss (not from PSG2): a big pink slime with his crown slipped half off. He hops after you, and every few seconds squashes down, leaps high and slams; jelly rolls along the ground both ways and hurts unless you jump it. 300 health, touch 2, slam 3, drops Jelly; all our estimates, set so wooden gear wins (bot test 4/4). Read "slams and you have to jump" as a ground shockwave you jump over. In multiplayer only the host's screen shows the waves for now. *"make a big slime boss called jelly king with a half slipped off crown and he jumps high sometimes slams and you have to jump"*

## 2026-11-05 (Grasslands polish, gravestone revive, past Hell set aside)
- **More slimes in the Grasslands, and more Jelly.** Slimes are a bigger share of the monsters in Grasslands 1 to 3 and the Grasslands Arena, the worlds start with a few more monsters, and slimes come back over time (one every 20 s, out of sight, up to the starting number). Slimes drop Jelly 30% of the time instead of the wiki's 20%. Read "jelly's" as both the slimes and their Jelly drop. *"Make the jelly's have more spawns in grasslands ... Make jelly's slightly more common."*
- **The Grasslands Arena boss is beatable at a low level.** Both bosses still come together, but with about a quarter of their old health (Rexy 999 → 270, Hand 1,251 → 266), 30% of their hit, and a short stagger when hit (at most once a second). A bot test played the real arena: before, no gear won; now wooden gear wins 7 in 8 and stone or copper gear 8 in 8. A player with no armor at all still loses. Monsters no longer pace on a ledge right above you. *"Make the boss for grasslands arena kill able for lower level players ... Have agents test the boss fight for grasslands arena and see if it works well."*
- **One free revive in the single-player Grasslands Arena:** the first faint gets you back up on the spot with full health. Read as "only this arena, only single player". *"make it 1 free revive for single player grasslands arena only"*
- **Gravestone revive in single player.** A slow fall, then a gravestone where you fell. The faint screen offers Respawn or Wake up in Pixel Town. Respawn makes you a ghost at the start of the map (can't hit or be hurt); stand by the gravestone for 3.5 s (a little timer counts down) within 50 s to get back up there with full health. Otherwise it crumbles and you wake in town. Read "standing close" as the player's own ghost walking back, since there's nobody else in single player. Not in Survival (fainting ends the run) or after the bomb button, and multiplayer is unchanged. *"When a player dies in single player they get a option to respawn only make it have a slow animation into a death and then a gravestone and players have 50 seconds to revive by standing close it for 3.5 sec anf it shows a little timer."*
- **The Crafter and the Gatekeeper stand 2.5 times further apart** (5 → 13 tiles), and **the opening above them is 2.5 times wider** (4 → 10 tiles). Read "the gap above" as the opening in the upper floor right over that space; the street-to-upstairs height stays the same so you can still jump up. The Master Chest moved to the east side of the opening. **You start in that gap**, just left of the portal. *"Make the gap between crafter and portal guy bigger like 2.5x bigger and same with the gap above. Make player spawn in the gap."*
- **Everything past Hell is set aside, not deleted.** The 11 later worlds leave the Gatekeeper's list, and the 73 items only they give leave the Crafter, the combination books, the furnaces, the shops and the quests. The game works out that list from where items come from. One switch (`Data.set_later_open(true)`) brings it all back. *"I think we should hold everything past hell aside for now ... all the items from those higher places can be put aside for now I'll let you deside how"*

## 2026-11-04 (roomier maps and an icon for every item)
- **The HUD and menus stay as they are.** Brenden first asked for a better layout, then said he meant the maps: *"i dont mean hud and menus keep them the same i mean the layout of the map and how close everything is it just has that clutter feel"*.
- **Pixel Town is a little wider (64 → 80 tiles) so nobody stands on top of anyone.** On the street every villager is about four tiles from the next, and the four houses stand in the gaps between them instead of behind them. The order is the same, the sides still mirror, and the portal is still in the exact middle under the opening. Upstairs, the chests and the incubator have more room, the trading tables are further apart, and the five furnaces are four tiles apart instead of three. The basement's ninjas and robots are six tiles apart. This keeps the town closed in; it's wider, not taller, because the 2026-10 "it's too big" was about the old big map.
- **Worlds have fewer, better-spaced resources.** About a quarter fewer trees, rocks and plants, with at least two empty tiles between any two (three beside a tree), none right where you arrive, and monsters start at least five tiles apart. In Survival, resources keep 40 px apart instead of 20.
- **Every item has its own icon** (567 items, 279 used to share one). Read "models for every item" as "a picture of its own". Weapons, staffs, bows, armour, helmets, shields and rings are drawn by `scripts/item_icons.gd`: each gets its own blade, tip, guard and pommel (or helmet shape, shield shape and emblem, ring stone...), chosen from its name so it never changes. Upgrades keep their family's shape and gain marks: 2 a gem in the guard, 3 a gem in the pommel, 4 a rune, 5 a sparkle, U gold trim. Potions get bigger bottles as they get bigger. Jr pets are drawn smaller than grown-up ones.
- *Brenden: "i need you to make the game look better wehile still having the pixel look i need models for every item ... dont make everything feel clutterd like it does now and have agents test that if possible"*

## 2026-11-04 (extra storage costs gems)
- **Banka's first backpack is free; each one after it costs gems,** unlocked in order (2, then 3, up to 6). Brenden: *"every storage after the first cost gems and gems cost reealy money"*.
- **50 gems per backpack is a placeholder.** The PSG2 wiki gives no price, so Brenden sets it (`BACKPACK_GEMS` in `game_state.gd`).
- **Old saves lose nothing:** a backpack that already holds items stays unlocked. Empty extra backpacks lock again.
- **Real-money gems are not in yet.** They need a payment account only Brenden can open (see [[Monetization]]). Gems for 2,500 coins stay until he decides.

## 2026-11-04 (who buys and who sells)
- **The spiky-haired Merchant only buys your items.** Her shop's left side says "Nothing for sale here", and the right side lists everything in your bag with a sell price.
- **The Plumber sells everything the Merchant used to,** on top of his tools: potions, Antidotes, Fatigue Potions, arrows, cannon balls, missiles, Wood Walls, the campfire, Combo Book II (1,500) and the Green Egg. Same prices. He doesn't buy.
- The Merchant is a girl. Read "mario" as the Plumber (red cap, blue overalls); he keeps the name Plumber.
- Hints now say Antidotes and Small Potions come from the Plumber.
- This replaces the 2026-10-17 reading that the spiky-haired NPC sells stuff.
- *Brenden: "spikey ahir girl buys things off you doesnt sell anything mario does"*

## 2026-11-04
- **The online server redeploys itself when its code changes.** Find Public Game showed "Unknown request." because the server on Render was still the 2026-10-27 morning version, from before public games were added: Render never redeployed it. A GitHub Action now calls Render's Deploy Hook on every server change, once the hook is saved as the `RENDER_DEPLOY_HOOK` secret. The game also says "The online server needs an update" instead of "Unknown request." *Brenden: "when i host a game and my friend clicks find game it only shows unkown request".*

## 2026-10-29 (portal area and world card maps)
- **The Gatekeeper's portal opens in the exact middle of Pixel Town, right under the middle of the opening you jump up through,** so the opening and the portal line up. Before, the portal stood half a tile left of the opening's middle.
- **The Crafter stands just left of the portal and the Gatekeeper just right of it,** each at the edge of the opening, the same distance away. The Crafter used to be at the east end of the street. The Plumber, Banka and the Merchant each moved one tile east, the sign one tile west, and the four houses now mirror around the middle.
- **The map pictures on the world cards are drawn like little screenshots:** sky with clouds, mountains and hills, grass tops, dark cartoon edges, darker caves, trees, ores, and the portal you arrive at. Big worlds show their start; arenas and Survival show the middle. They used to be one flat pixel per tile.
- Read "the created" as the Crafter and "portal character" as the Gatekeeper.
- *Brenden: "Make the maps look better on the portal screen put the created in the left side of the portal character on the other side of Ty e open area where the portal opens make the top opening where you jump up symmetrical to the bottom where you enter a portal"*

## 2026-10-28 (GitHub clean-up)
- **The README and GitHub description don't say "no shop, no ads".** *Brenden: "dont say no ads or no shop"*
- **The README leads with how to play:** big Play buttons, the Web build badge, then the Godot version (the main game) before the classic browser version, whose details are folded into dropdowns. *Brenden: "can you make my github way cleaner and better looking and organized"*
- **The one-line `brenden.sobanski` intro file is removed from the game repo.** Its text ("Im intrested in learning new things") goes in a profile README, which needs its own repo named `Brendensob`.
- **The old top-down browser version is deleted** (root `index.html`, `js/`, `css/`, and the `/classic/` page). Only the Godot game is left. It's still in the git history if it's ever wanted. *Brenden: "theres 2 pixel wilds in i dont want the old one delete that"*

## 2026-10-27 (buttons back to their old size)
- **The ◀ ▶, A and B buttons are back at the sizes and places they had before the cartoon pass:** ◀ ▶ 90 × 34 at the bottom left, A 68 × 34 above B 68 × 34 at the bottom right. They keep the cartoon finish (rounded corners, shine, sink when pressed), so A and B are rounded rectangles again, not circles. *Brenden: "Revert buttons to the same size as before"*
- This is also what his earlier "Keep the buttons how they were just for the movement and jump" meant. That was first read as "don't change them", which was wrong. The entry below is corrected.
- The AUTO switch moved to just above A.
- A test checks the four sizes.

## 2026-10-27 (auto hit and cartoon pixel look)
- **An auto-hit switch:** a little round button left of A (moved above A with the button revert). When it's on, the held weapon or tool swings by itself. It keeps going with the bag open (the bag doesn't pause the world then) and stays on through switching items. *Brenden: "Keep the buttons how they were just for the movement and jump also add a little circle button for auto hit to turn on and off so your sword swings automatically even while in inv and stays even while you switch items"*
- **Food and blocks are never auto-used**, so a potion or a stack of walls isn't wasted by mistake. The "staffs, bows and throwables too" part follows the original's hold-A trick, which already swung those.
- ~~The move and jump buttons stay exactly as they were.~~ Misread: he meant "put them back how they were". Done in the entry above.
- **Cartoon pixel look:** *Brenden: "I want a cartoon pixelish look"*. The ground now gets the same colour pop as the sprites (a little more saturation and brightness) and the same near-black outlines, so the world and the characters match.

## 2026-10-27 (ground and walls remodel)
- **The ground is drawn like a professional tileset.** Each tile checks its neighbours, so it gets grass caps, outlined and shaded sides, rounded corners and shaded ceilings with roots. *Brenden: "Remodel everything especially the walls around the map like a professional designer would"*
- **The walls around the map are mossy stone walls.** They carry on up past the top of the map, so they never stop in mid-air. Cave worlds have bedrock at the bottom. Pixel Town gets a stone frame, stone-brick room walls and a stone-brick basement.
- **The dark worlds' back walls are brick with moss.** This comes from Brenden's Darklands recording ("dark crisscross brick walls with mossy edges", [[PSG2 Screenshot Notes]]). The tomb gets sandstone blocks and the icy worlds get ice blocks.
- **Jump-through ledges are wooden planks underground**, so they're easy to tell apart from solid ground.
- **The backdrops were redrawn:** better mountains, and a tree line instead of round blobs.
- **No map layouts changed**; only how they look. Characters, monsters, houses and the HUD weren't part of this pass.

## 2026-10-27 (multiplayer menu)
- **Pressing Multiplayer opens its own screen.** It shows the character's name in green and says the name is yours and belongs to this character. Under that are buttons for Friends, Find Public Game and Host Public Game. *Brenden: "when clicked multiplayer make sure player knows they own the name and that's the name of that character they own and there a button for friends list ... and there's also a button for find public or host public".*
- **Friends have a round light:** red when offline, green when online, and green with a Join button when they're in a game. *Brenden: "a blank circle that's red if offline or green if online and green with a join button if in game".*
- **Public games:** Host Public Game opens a room that anyone can join from Find Public Game. A normal host still means friends only. The server decides who may join.
- **Faint screen fixed:** the Wake Up button now sits under the text instead of over the tip. *Brenden: "Make the menu when death fixed".*

## 2026-10-27 (solid progression)
- **Fights are checked by playing them.** A new fight test has a bot fight two monsters at once in every world up to Hell, with the gear you can have by then. Before the changes it lost to Shellys in Grasslands 1 with the starter kit, to Octopuses in Grasslands 2, and to Dark Slimes, Worms and UFOs after that. *Brenden: "make the game progression solid test it and make sure fights arnt impossible and players know what to do".*
- **Starting health 10 instead of 5, and 1 second of safety after a hit instead of 0.6.** Both were our own numbers, not the wiki's. With 5 health a Mummy's 3 left one hit before fainting, and an Octopus's 5 was an instant faint.
- **The starter Sword Cast hits a little harder** (attack 4, was 3), so a brand-new character beats a Shelly plus another monster 7 times in 8 instead of about half the time. The coordinator's brief allowed changing starter damage for this.
- **Potions heal more:** Small 5, Potion 12, Medium 25, Big 60 (were 3, 6, 15, 35). Potion strength was always an estimate; with more health the old ones barely helped.
- **Flying monsters stay knocked back longer** (1 s instead of 0.4 s), so you can fight a UFO.
- **No wiki monster number was changed.** The UFO really hits 15 in the Darklands (wiki), so it stays the toughest common monster there: with iron gear the bot beats one UFO 7 times in 8, but a UFO plus another monster only about a third of the time.
- **A goal card shows what to do next**, with progress and a tap for how, from "Visit the Grasslands" to "Enter Hell", then Miffie's quests. See [[Goals and Guidance]].
- **World cards say how dangerous a world is for your gear** (Easy, Fair, Hard, Deadly), and the faint screen gives one tip.
- Drop rates were not touched (Brenden sets those).

## 2026-10-27 (cleaner cartoon look)
- **The art goes further toward cartoon, but stays pixel art.** Big sprites are smoothed (Scale2x/Scale3x) instead of blown up, and get bold outlines; shadows, glows, clouds and a hazy far mountain range add depth. *Brenden: "make all graohics way cleaner looking more cartoon ish ... give certain things good depth affect and color and use bettere models for anything that may feel off make pop up menus cleangood looking and not annoying"* This answers the open question about how far the cartoon look should go.
- **Menus are rounded cartoon boxes** that pop in over a dimmed game and close with a tap outside. Messages are small bubbles that count up instead of piling up, and clear when a menu opens. Same orange colours as before, so it still reads like PSG2.
- **A and B are round buttons**, ◀ ▶ are rounded pads with arrows. Same places on screen as before. *(Sizes reverted 2026-10-27, see above.)*
- **Not changed here:** progression, joining friends and the new characters are other pieces of the same request, handled separately.

## 2026-10-27
- **Every character shows on Create a character; most start locked.** The PSG2 wiki says new characters can only be the Man in Suit or the Nurse at first, and the rest are unlocked by quests, the Gem Shop, Master Chests or the Daily Gift. So all 18 characters are tiles on the screen, locked ones darkened with a padlock and a line saying how to get them. *Brenden: "theres only man in suit and nurse add all the others with some being locked behind gems or other tasks".*
- **Unlocks are for the whole device, not one save.** Owning a character in any save unlocks it for good. A locked one can also be unlocked right on the screen with gems from your saved character that has the most.
- **Tasks:** Miffie's three character quests come from the wiki (Pirate, Bad Man, Soldier). The others are ours: arena clears and Survival Grasslands days, chosen to match each character's gem tier. The Buns, Ninja and Iron Bot stay Gem Shop or chest only. See [[Characters]].
- **Starting as a character with a weapon gives that weapon**, the same as becoming it from the bag.
- **Rooms go over a WebSocket, so phones can join friends.** Brenden plays on his phone in the web build, and browsers can't open the raw connection the relay used, so joining never worked there. The relay now runs as a WebSocket on the server's main port, for every version of the game. *Brenden: "make it so i can join friends had trouble with that".*
- **The server is hosted free on Render**, set up by `render.yaml` with one Deploy click. It gives https (which the web game needs) and redeploys on every merge. Chosen because it needs no card and no server to look after. The cost is that it sleeps when nobody plays and has no saved disk.
- **Games put themselves back on a wiped server.** Each character keeps its name key and friends list, and restores them when the server doesn't know it. A friendship counts only when both sides restore it.

## 2026-10-24
- **Stronger knockback and a hit stun, so the Grasslands are fair for a new character.** The starter Sword Cast does 2–4 a hit, so a Mummy (45 HP) or Shelly (50 HP) takes about 15 hits, while they hit back for 3 and 2 on 5 HP. With the old 7 px push they came right back and traded hits. Now a knockback hit throws a monster about a tile, every hit dazes it so it can't hurt you by touch for a moment, and monsters bounce off you. Health and damage numbers from the wiki were not changed. *Brenden: "its really hard to kill things in grasslands at a starter make the kockback better and the whole cobat better".* This replaces the 2026-10-10 "small knockback from the trailer" rule.
- **Hits feel heavier:** a tiny freeze, a spark, a squash and a small screen shake. A tap of A during a swing is remembered, for phone play.

## 2026-10-20
- **The menus follow Brenden's recording of the real game.** He sent a 52-second recording with no text. It showed the title (Play and Options at the bottom left, green Invite a friend!), Options, "Select a character" rows with red X buttons, Single Player / Multiplayer / Back, and "Save and Leave Game?" Yes / No. All of these were copied in layout (not art). See [[Main Menu]].
- **Villagers call out when you walk up to them**, like in the recording: the Gatekeeper "Where do you wish to go?", Brutus "Looking for the Book of Survival?", the Miner "aghh..". Their name shows the rest of the time, so quests still say who to find.
- **The title no longer says "Nothing to buy, ever."** That stopped being true when the [[Currencies and Gem Shop|Gem Shop]] came in.

## 2026-10-24 (phases 2 to 5 of the polish pass)
- **The progression is checked with the real gates:** `tools/progression_audit.gd` finds 0 softlocks.
- **Every recipe, Crafter item, smelt, shop item and quest in the data is now played by the autotest.**
- **You're told when a smelt, egg or crop is done**, wherever you are.
- **Low health makes the health bar's border pulse red.**
- **Music without threads:** on the web build (threads off), tracks are made a small piece per frame, the needed one first, so the browser never freezes and the music still plays.
- **Not done, on purpose:**
  - item rarity colours (PSG2 has none we know of);
  - drag-and-drop (PSG2 is tap-based);
  - boss attack patterns (not documented).

## 2026-10-24 (Phase 1 of the polish pass)
- **Music is original and synthesized in code.** There are seven loops: menu, town, field, cave, Hell, boss and Survival night. No audio files are used, so nothing needs a licence and nothing copies PSG2. **Sound and Music volume** are in Options and the compass menu.
- **Cave darkness** matches Brenden's Darklands video: dark worlds and deep caves fade the screen edges, drawn under the HUD.
- **Switching character asks first** and says what happens to the current character and gear.
- **The 3 items with no source stay unobtainable** until Brenden picks from the proposals in [[Open Questions]]. The wiki's own page source was searched; the findings are in [[Known Issues]].
- **Town walls in a room:** a wall anyone in the room opened is open for everyone; the unlock is saved for the breaker. *Brenden: "If one player breaks or changes a wall, every player in that town must see the same result."* Pixel Town stays personal (each player's own unlocks), because PSG2's behaviour isn't documented.
- **The game has its own clock:**
  - a steady timer while playing;
  - the online server's time when it can be reached (a new `/time` on the server);
  - never earlier than the last save.
  
  Time away still counts, so honest players lose nothing.

## 2026-10-22
- **A full audit of the game against its data.** `tools/data_audit.gd` checks every reference and works out which items can actually be obtained. The results are in [[Completion Checklist]]. *Brenden asked for a full game audit and completion.*
- **Nothing earned is ever lost.** A full bag drops rewards at your feet: chests, the Crafter, quests, combining, harvests, tokens, trades and multiplayer pickups. A survival key goes to Banka if the bag is full.
- **Saves are crash-safe.** Each save goes to a temp file first, and the previous save is kept as a backup. A damaged save loads from the backup and is kept aside, never deleted.
- **No world locks were invented.** The PSG2 wiki shows every world open at the Gatekeeper. Added the wiki's **12 stamina** rule for Snow Valley.
- **The Nightmare Long Sword drops from the Master Chest**, as the wiki's Chests page lists. The Blood Long Sword, Stone Wall and Torch Stand have no source on the wiki, so they stay unobtainable and are logged in [[Known Issues]].
- **Swinging and pets can't hit through walls.**
- **Becoming a character gives your old one back.** A character's weapon comes only the first time.
- **Healing staffs don't spend mana at full health.**

## 2026-10-19
- **The vault holds all the game's data, plus rules with examples.** Every table in `data.gd` (567 items, 70 monsters, recipes, drops, shops, chests, 75 quests) is exported to `06 Data` by `godot/tools/vault_export.gd`. [[Rules and Preferences]] got worked examples. *Brenden: "store all data in it rules and examples then send it".*
- **Update the vault with every change.** Brenden keeps Obsidian open. Every PR must update the vault, and the Obsidian Git plugin pulls it about every 2 minutes. *Brenden: "obsidan is open rn connec to it and update it everytime a change is made".* A cloud session can't reach his PC directly, so GitHub is the bridge.
- **Set up this Obsidian vault as the project memory**, plus a `CLAUDE.md` file that tells every Claude session to read the vault and keep it updated. *Brenden: "connect to obsidian and make an entire thing for this topic and use it to help memory".*
- **Brenden's own notes go in `My Notes`.** The desktop shortcut pushes that folder to GitHub so Claude can read it.

## 2026-10-17
- **Cartoon twist on the art**, plus the HUD from his screenshot and recording:
  - friend, chat and emote buttons;
  - the emote panel;
  - big damage numbers.
  
  *Brenden: "Redo the art style with a twist of cartoon ish and what's on the screen right now".* → PR #17
- **The storage girl is named Banka**, and **the spiky-haired blond NPC is the Merchant** (he sells stuff). *Brenden's answers.* → PR #16 (changed 2026-11-04: she only buys, the Plumber sells)
- **Keep the Gem Shop**: "I wanna make money from this too". See [[Monetization]].
- **The day counter shows only in Survival Grasslands**, and the Daily Free Gift was removed. *"The day counter and rewards for days is only in survival grasslands but no one really cares for it".* → PR #15
- **The HUD follows his screenshots:**
  - gems sit next to the clock;
  - storage is 6 backpacks of 30 slots in the bag screen;
  - the Gatekeeper shows world cards.
  
  → PR #15
- **Only the PSG2 wiki and the trailer count as sources**: "Don't use the App Store wiki and 2.o wiki is the wrong one". The first Banka (from the 2.o wiki) was removed. → PR #14
- **A smaller town and smoother, slightly higher jumps.** *"make the map layout way closer to the actual one it's too big".* → PR #13
- **Web build on GitHub Pages**, so the game plays on phones. → PR #12

## 2026-10-10
- **Combat closer to the original:**
  - damage is random from 1 up to the hit;
  - defense can soak a hit to 0;
  - knockback is small;
  - damage numbers are white.
  
  → PR #11

## 2026-10-09
- **Pixel Town follows Brenden's sketch:**
  - three floors, closed in;
  - an opening in the middle to jump up through;
  - the Gatekeeper right of the portal;
  - symmetrical sides;
  - faster falling.
  
  → PRs #8–#10
- **The research on drop rates and HP came up mostly empty.** Nobody has published PSG2's real drop rates, so they stay estimates. **There is no Hell 3 in PSG2** (it's from 2.o). → PR #4
- **More worlds, mouse clicks to hit, and multi-jumps paid with the green (stamina) bar.** → PR #3
- **Brenden edits and plays in Godot on his PC** with a one-line PowerShell setup and a desktop shortcut that pulls `main`. → PR #2
- **The game starts as a Godot clone of PSG2**:
  - hit NPCs and objects to interact;
  - a swing animation and synthesized sounds.
  
  → PR #1
- **Another Claude session added gems, the Gem Shop and character stats.** Brenden didn't object. → PRs #5–#7
