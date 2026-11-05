---
tags: [data, generated]
---
# World Data

> [!info] Made from the game
> Written by `godot/tools/vault_export.gd` from `scripts/data.gd`. Don't edit it here: change the game and run the export again.

Monsters: each one's share of the spawns (a world places its *count* monsters, or keeps up to *cap* in an arena). A rare one like King at 0.3 weight is a small share, not zero. ×1.5 hp / ×6.3 hit are that world's health and damage multipliers.

| World | id | Kind | Theme | Next | Monsters (share of spawns) | Bosses (arena) | Resources (share) |
|---|---|---|---|---|---|---|---|
| Pixel Town | `town` | town | grass |  |  |  |  |
| Grasslands 1 | `grass_1` | explore | grass | grass_2 | Slime 56.2%, Fira 18.8%, Mummy 12.5%, Shelly 12.5% |  | tree 35%, stone 20%, copper 15%, plant_yellow 10%, plant_pink 10%, pot 10% |
| Grasslands 2 | `grass_2` | explore | grass | grass_3 | Slime 42.1%, Fira 15.8%, Mummy 10.5%, Shelly 10.5%, Octopus 15.8%, Stone 5.3% |  | tree 28.6%, stone 19.0%, copper 14.3%, iron 9.5%, plant_yellow 9.5%, plant_pink 9.5%, pot 9.5% |
| Grasslands 3 | `grass_3` | explore | grass |  | Slime 31.2%, Octopus 12.5%, Rexy 12.5%, Dark Rexy 6.2%, Dark Slime 12.5%, Mantis 12.5%, Zombie 12.5% |  | tree 28.6%, stone 14.3%, copper 14.3%, iron 9.5%, gold 4.8%, plant_yellow 9.5%, plant_pink 9.5%, pot 9.5% |
| Darklands 1 | `dark_1` | explore | dark | dark_2 | Dark Slime 26.3%, Mantis 21.1%, Zombie 15.8%, UFO 15.8%, Worm 10.5%, Rexy 5.3%, Hand 5.3% |  | tree 25%, blue_tree 12.5%, copper 18.8%, silver 12.5%, iron 12.5%, gold 12.5%, erbium_rock 6.2% |
| Darklands 2 | `dark_2` | explore | dark |  | Dark Slime 20%, Mantis 20%, Zombie 15%, UFO 15%, Worm 15%, Rexy 5%, Hand 10% |  | tree 18.8%, blue_tree 12.5%, copper 12.5%, silver 18.8%, iron 12.5%, gold 12.5%, erbium_rock 12.5% |
| Hell 1 | `hell_1` | explore | hell | hell_2 | Mantis 22.9%, Worm 17.1%, Wizard 17.1%, Shadow 17.1%, Eyeball 11.4%, Hand 11.4% ×4.75 hit, King 1.7%, Queen 1.1% |  | vase 25%, iron 16.7%, silver 16.7%, gold 16.7%, erbium_rock 25% |
| Hell 2 | `hell_2` | explore | hell |  | Eyeball 23.6%, Shadow 23.6% ×1.7 hit, Ghast 23.6%, Hand 23.6% ×6.5 hit, Queen 1.6%, Queen 0.79% ×1.25 hp ×1.47 hit, Queen 0.79% ×1.5 hp ×1.55 hit, Dark Rexy 2.4% ×6.3 hit |  | vase 21.4%, iron 14.3%, silver 14.3%, gold 21.4%, erbium_rock 28.6% |
| Ice Cavern | `ice_cavern` | explore | ice |  | Tornado 14.9%, Tsunami 22.3%, Ice Bat 22.3%, Cloud 22.3%, Butterfly 14.9%, Queen 2.2% ×1.5 hp ×1.55 hit, Butterfly Boss 1.1% |  | ice_rock 40%, silver 20%, gold 20%, erbium_rock 20% |
| Grasslands Arena | `grass_arena` | arena | grass |  | Slime 50% ×1.23 hp, Fira 16.7% ×1.67 hp, Mummy 16.7%, Shelly 16.7% | Rexy, Hand |  |
| Darklands Arena | `dark_arena` | arena | dark |  | Dark Slime 21.4%, Mantis 21.4%, Zombie 14.3%, UFO 14.3%, Worm 14.3%, Octopus 14.3% ×2 hp ×1.5 hit | Dark Rexy, Hand, King |  |
| Hell Arena | `hell_arena` | arena | hell |  | Mantis 25% ×2 hp ×1.5 hit, Worm 16.7% ×1.2 hp ×1.3 hit, Wizard 16.7% ×1.2 hp ×1.3 hit, Shadow 16.7% ×1.2 hp ×1.3 hit, Eyeball 8.3% ×1.1 hp ×1.3 hit, Hand 16.7% ×0.5 hp ×5.5 hit | King, Queen |  |
| Dream Arena | `dream_arena` | arena | dream |  | Mantis 18.2%, Shadow 18.2% ×1.7 hit, Worm 18.2% ×1.6 hit, Eyeball 9.1% ×1.5 hit, Wizard 18.2% ×1.5 hit, Hand 18.2% ×0.45 hp ×8 hit | King, Queen, Butterfly Boss |  |
| Ghost Arena | `ghost_arena` | arena | ghost |  | Ghost 60%, Ghost 40% | Ghost Boss |  |
| Modina Ruins | `modina_ruins` | explore | modina |  | Shadow 19.0% ×1.7 hit, Ghast 19.0% ×1.17 hp, Eyeball 12.7% ×1.05 hp ×0.93 hit, Wizard 12.7%, Golden Slug 19.0%, Phantom Butterfly 12.7%, Dark Rexy 1.9% ×36 hp ×6.3 hit, Queen 1.9% ×1.5 hp ×1.55 hit, Modina 0.95% |  | vase 21.4%, iron 14.3%, silver 21.4%, gold 21.4%, erbium_rock 21.4% |
| Nightmare Valley | `nightmare_valley` | explore | nightmare |  | Wizard 12.9%, Golden Slug 12.9%, Phantom Butterfly 12.9%, Demon Eye 19.3%, Demon Angel 19.3%, Demon Bat 19.3%, Queen 1.6% ×1.5 hp ×1.55 hit, Modina 0.64%, Butterfly Boss 0.64%, Doom 0.64% |  | vase 25%, silver 16.7%, gold 16.7%, erbium_rock 25%, volcanic_rock 16.7% |
| Forbidden City | `forbidden_city` | explore | forbidden |  | Wizard 12.9%, An An 19.4%, Ji Ji 19.4%, He He 12.9%, Raven 19.4%, Demon Bat 12.9%, Queen 1.3% ×1.5 hp ×1.55 hit, Modina 0.65%, Butterfly Boss 0.65%, Fortune Boss 0.65% |  | vase 25%, silver 16.7%, gold 16.7%, erbium_rock 25%, volcanic_rock 16.7% |
| Snow Valley | `snow_valley` | explore | snow |  | Wizard 14.9% ×2.6 hp ×4.9 hit, Grinch 22.3%, Snow Turtle 22.3%, Lich 14.9%, Fairy 22.3%, Queen 1.5% ×1.75 hp ×1.55 hit, Modina 2 0.74%, Fortune Boss 0.59%, Evil Santa 0.59% |  | ice_rock 27.3%, silver 18.2%, gold 18.2%, erbium_rock 27.3%, volcanic_rock 9.1% |
| Tomb of Makara | `tomb_of_makara` | explore | tomb |  | Worm 21.9%, UFO 21.9%, Sand Mantis 21.9%, Tombstone 21.9%, Vampire 7.3%, Dark Rexy 2.2% ×47.6 hp ×6.3 hit, King 2.2% ×3 hp ×3 hit, Makara 0.87% |  | vase 23.1%, stone 15.4%, gold 15.4%, erbium_rock 15.4%, volcanic_rock 7.7%, sandnite_rock 23.1% |
| Mushroom Valley | `mushroom_valley` | arena | mushroom |  | Golden Slug 57.1% ×1.2 hit, Phantom Butterfly 42.9% | Modina |  |
| Fruit Loop | `fruit_loop` | arena | fruit |  | Mango 18.2%, Cherry 27.3%, Pineapple 27.3%, Strawberry 27.3% | Pineapple Killer |  |
| Eggcellence | `eggcellence` | arena | egg |  | Cracked Egg 25%, Cracked Egg 16.7%, Cracked Egg 16.7%, Flying Egg Clutch 16.7%, Chick 16.7%, Giant Chick 8.3% | Harakattu |  |
| Survival Grasslands | `survival` | survival | grass |  |  |  |  |

## Gatekeeper cards (in order)

| # | World | Text |
|---|---|---|
| 1 | Grasslands | The land of the slimes. |
| 2 | Grassland Arena | Boss spawns in 3 minutes. |
| 3 | Survival Grasslands | Win treasure from surviving! |
| 4 | Darklands | Danger.. |
| 5 | Darklands Arena | Boss spawns in 3 minutes. |
| 6 | Hell | Hell welcomes you |
| 7 | Hell Arena | EPIC DANGER! |
| 8 | Dream Arena |  *(set aside for now)* |
| 9 | Ice Cavern |  *(set aside for now)* |
| 10 | Ghost Arena |  *(set aside for now)* |
| 11 | Modina Ruins | Poisonous ancient ruins *(set aside for now)* |
| 12 | Nightmare Valley | Nightmare starts here.. *(set aside for now)* |
| 13 | Mushroom Valley | Prepare for some challenge! *(set aside for now)* |
| 14 | Forbidden City | The lost ruins of Forbidden City *(set aside for now)* |
| 15 | Fruit Loop | Fruit ninja needed! *(set aside for now)* |
| 16 | Snow Valley | Weaklings, stay away! *(set aside for now)* |
| 17 | Tomb of Makara | Ancient evil.. filled with treasures? *(set aside for now)* |
| 18 | Eggcellence | To feast, or be feasted on. *(set aside for now)* |

## Set aside for now

The Gatekeeper doesn't offer these worlds (`Data.LATER_WORLDS`, turned back on with `Data.set_later_open(true)`): Dream Arena, Ice Cavern, Ghost Arena, Modina Ruins, Nightmare Valley, Mushroom Valley, Forbidden City, Fruit Loop, Snow Valley, Tomb of Makara, Eggcellence.

The 73 items only they give are hidden from the Crafter, the combination books, the furnaces, the shops and the quests: An An, An An Jr, Blade of Emperor, Blue Blade, Bone of Makara, Combo Book U, Dark Heart, Dark Moon Blade, Dark Moon Blade U, Dragon Blade, Dragon Blade II, Dragon Blade III, Dragon Dress, Dragon Dress II, Dragon Handle, Dress of Lich King, Eggency, Emperor Dress III, Emperor Dress IV, Forbidden Bar, Forbidden Stone, Fortune Mask, Fortune Nugget, Ghost Hat, Hazard Wipe, He He, He He Jr, Heavy Ice Devil Sword II, Hell Armor IV, Hell Spike, Hell Spike II, Hell Spike III, Hell Sword Shield, Iron Fist V, Ji Ji, Ji Ji Jr, Long Lance, Long Lance II, Long Lance III, Missing Page U, Modina, Modina Dress, Modina Dress II, Modina Dress III, Modina Face, Modina II, Modina III, Modina IV, Modina Ring, Modina U, Moon Blade V, Ne Ne, Ne Ne Jr, Nightmare Blade II, Nightmare Blade III, Nightmare Blade IV, Nightmare Dress, Nightmare Dress II, Nightmare Helmet III, Nightmare Ingot, Nightmare Ore, Rainbow Pops, Red Dream Sword, Robo Mask, Robo Mask VIII, Sandnite Bar, Sandnite Ore, Santa Blade, Skin of Makara, Skull Dress IV, Sun Extractor, Treasure of Makara, Tsurugi V.
