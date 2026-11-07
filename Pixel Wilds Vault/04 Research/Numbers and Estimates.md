---
tags: [research, numbers]
---
# Numbers and Estimates

All game numbers live in `godot/scripts/data.gd`.

## From the PSG2 wiki (as measured by players)
- **Darklands:** Slimes 125–130 HP, Worms 358–362, Rexy 462.
- **Hell 1:** Mantis 250–300, Hands 900–1,100.
- **Hell 2:** Shadows 1,400, Hands 2,000, Dark Rexy 50,000, Queens level 1–3.
- **Later worlds:** monster damage and boss health, plus the attack and speed of the Modina, Long Lance, Nightmare Blade, Hell Spike, Hazard Wipe and Santa Blade.
- **Money (2026-11-06):** Silver Chest coins (1, 10, 11, 100 or 111), Pink Egg 10,000 and Green Egg 20,000, Copper Ore 250 at Brutus, Wooden and Copper tools 250 at the Plumber, Combo Book II 1,500, Em Stone 92,500, the 99,999 coin limit, and the sell prices the wiki gives (Copper Ore 3, axes and Copper/Iron Pickaxes 25, Gold/Erbium Pickaxes 50, sword casts 20, Pole Axe 25, Blue Night and Fire Brand 45, Devilween 100, Torch and Fira 1, Gradius and wooden tools can't be sold).
- Weapon attack and speed, armor stats, combination success rates, smelting, tool hits, quests, day length and survival rewards.
- Defense works like the wiki's defense calculator.

## Estimates (change them freely)
- **Small Potion drops** (2026-11-06): 4% from every Grasslands and Darklands monster, 6% from Grasslands Arena monsters, Holy Banana 5% from the Grasslands Arena boss. Placeholders: Brenden sets drop rates.
- **Boss and weapon sizes** (2026-11-06): bosses twice as big, long weapons (reach 24+) twice as big in hand. Brenden: "bosses are like way bigger in the real game".
- Most **drop chances**. Only the Slime's (~20%) is known. Brenden raised the slime's **Jelly** to 30% on 2026-11-05 ("slightly more common"); its other drops stay at the wiki's 20%.
- **Jelly King** (our own boss, 2026-11-05): 300 health, touch 2, slam wave 3, jumps every 3.5 to 5.5 s, drops 5 to 10 Jelly and Sticky Balls 25%.
- **Grasslands Arena bosses** (2026-11-05, Brenden's ask): Rexy ×0.6 health and ×0.3 hit, Hand ×0.12 health and ×0.3 hit, with a short stagger when hit. They were ×2.22 and ×0.565 health at full hit, our reading of the wiki's arena numbers.
- Potion strength (Small 5, Potion 12, Medium 25, Big 60 since 2026-10-27) and the solo boss fights.
- **Starting health 10** and **1 s of safety after a hit** (2026-10-27, tuned with the fight test so the Grasslands are winnable from the start).
- Health the wiki leaves as "?", and Doom's health.
- Tomb of Makara monster health.
- Shield and upgrade numbers the wiki lists without values.
- **Character stats** (taken from the 2.o game, see [[Known Issues]]).
- Gem Shop prices for seeds and scrolls, and **2,500 coins per gem**.
- The Wall Hammer coming from **night 10**.
- Boss gem drops (1–2, rarely).

## Pacing changes from the journey test (2026-11-07)
| Number | Was | Now | Why |
|---|---|---|---|
| Health coming back out of a fight | 1 per 12 s after 8 s | 1 per 4 s after 6 s | new players fainted on their first trips |

The journey test also found the Jelly grind; that was fixed the same week from Brenden's own request (Jelly 30%, more Slimes that come back, PR #41).

