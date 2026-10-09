'use strict';
// Items, recipes, world objects, creatures, pets and goals.
// Tweak numbers here to rebalance the game.

const ITEMS = {
  wood: { name: 'Wood', desc: 'Chopped from trees. An axe makes it much faster.' },
  stone: { name: 'Stone', desc: 'Broken off rocks. A pickaxe makes it much faster.' },
  fiber: { name: 'Plant Fiber', desc: 'Pulled from tall grass. Good for tying things together.' },
  berry: { name: 'Berries', desc: 'A quick snack from berry bushes.', food: { hunger: 10 } },
  meat: { name: 'Raw Meat', desc: 'Edible, barely. Cook it at a campfire.', food: { hunger: 12, hp: -5 } },
  cooked_meat: { name: 'Cooked Meat', desc: 'Filling and warm.', food: { hunger: 35, hp: 8 } },
  stew: { name: 'Hearty Stew', desc: 'The best meal in the wilds.', food: { hunger: 60, hp: 25 } },
  bandage: { name: 'Bandage', desc: 'Heals 35 health.', heal: 35 },
  gel: { name: 'Slime Gel', desc: 'Sticky and a little bit glowy.' },
  bone: { name: 'Bone', desc: 'Left behind by ghouls.' },
  silk: { name: 'Spider Silk', desc: 'Strong thread from rock spiders.' },
  fur: { name: 'Rabbit Fur', desc: 'Soft and warm.' },
  iron_ore: { name: 'Iron Ore', desc: 'Mined in the grey highlands. Smelt it at a campfire.' },
  iron_bar: { name: 'Iron Bar', desc: 'Smelted iron, ready to be made into gear.' },
  golem_heart: { name: 'Golem Heart', desc: 'Still warm. Dropped by the Stone Golem.' },
  egg_slime: { name: 'Slime Egg', desc: 'Something wobbly is inside. Use it to hatch a pet.', egg: 'slime' },
  egg_spider: { name: 'Spider Egg', desc: 'It twitches. Use it to hatch a pet.', egg: 'spider' },
  egg_golem: { name: 'Pebble Egg', desc: 'Heavy as a rock. Use it to hatch a mini golem.', egg: 'golem' },
  wood_sword: { name: 'Wooden Sword', desc: 'Better than fists.', tool: { kind: 'sword', dmg: 5 } },
  stone_sword: { name: 'Stone Sword', desc: 'Heavy and reliable.', tool: { kind: 'sword', dmg: 8 } },
  iron_sword: { name: 'Iron Sword', desc: 'Sharp enough for ghouls.', tool: { kind: 'sword', dmg: 13 } },
  heart_blade: { name: 'Heart Blade', desc: 'Forged around a golem heart. The strongest weapon.', tool: { kind: 'sword', dmg: 22 } },
  stone_axe: { name: 'Stone Axe', desc: 'Chops trees three times faster.', tool: { kind: 'axe', dmg: 4, power: 3 } },
  iron_axe: { name: 'Iron Axe', desc: 'Chops trees six times faster.', tool: { kind: 'axe', dmg: 6, power: 6 } },
  stone_pick: { name: 'Stone Pickaxe', desc: 'Mines rocks and iron.', tool: { kind: 'pick', dmg: 3, power: 3 } },
  iron_pick: { name: 'Iron Pickaxe', desc: 'Mines rocks and iron twice as fast.', tool: { kind: 'pick', dmg: 5, power: 6 } },
  fur_armor: { name: 'Fur Armor', desc: 'Takes 20% off every hit.', armor: 0.2 },
  bone_armor: { name: 'Bone Armor', desc: 'Takes 35% off every hit.', armor: 0.35 },
  iron_armor: { name: 'Iron Armor', desc: 'Takes 50% off every hit.', armor: 0.5 },
  wall: { name: 'Wood Wall', desc: 'Blocks monsters. Ghouls can break it.', place: 6 },
  stone_wall: { name: 'Stone Wall', desc: 'Twice as tough as wood.', place: 7 },
  campfire: { name: 'Campfire', desc: 'Light, cooking, and a safe place to wake up. Monsters will not appear near it.', place: 8 },
  torch: { name: 'Torch', desc: 'Lights up the dark. Hold it or place it.', place: 9 },
  spikes: { name: 'Spike Trap', desc: 'Hurts monsters that walk over it.', place: 10 },
  golem_idol: { name: 'Golem Idol', desc: 'Use it to wake the Stone Golem. Be ready.', summon: 'golem' },
};

// Recipes are found by putting their ingredient types in the mixing pot.
// Amounts do not matter for discovery, only which ingredients are in the pot.
const RECIPES = [
  { out: 'wood_sword', cost: { wood: 3, fiber: 1 } },
  { out: 'stone_axe', cost: { wood: 2, stone: 2, fiber: 1 } },
  { out: 'stone_pick', cost: { wood: 2, stone: 3, fiber: 1 } },
  { out: 'stone_sword', cost: { wood: 1, stone: 4, fiber: 2 } },
  { out: 'wall', n: 2, cost: { wood: 4 } },
  { out: 'stone_wall', n: 2, cost: { stone: 4 } },
  { out: 'campfire', cost: { wood: 5, stone: 3 } },
  { out: 'torch', n: 2, cost: { wood: 1, gel: 1 } },
  { out: 'bandage', n: 2, cost: { fiber: 3, gel: 1 } },
  { out: 'cooked_meat', cost: { meat: 1 }, near: 'campfire' },
  { out: 'stew', cost: { meat: 1, berry: 3 }, near: 'campfire' },
  { out: 'fur_armor', cost: { fur: 4, fiber: 3 } },
  { out: 'spikes', n: 2, cost: { wood: 3, bone: 2 } },
  { out: 'bone_armor', cost: { bone: 6, silk: 3 } },
  { out: 'iron_bar', cost: { iron_ore: 2, wood: 1 }, near: 'campfire' },
  { out: 'iron_sword', cost: { iron_bar: 3, wood: 1 } },
  { out: 'iron_axe', cost: { iron_bar: 2, wood: 2 } },
  { out: 'iron_pick', cost: { iron_bar: 3, wood: 2 } },
  { out: 'iron_armor', cost: { iron_bar: 6, fur: 2 } },
  { out: 'golem_idol', cost: { stone: 10, gel: 3, bone: 3 } },
  { out: 'heart_blade', cost: { golem_heart: 1, iron_bar: 4 } },
];
for (const r of RECIPES) r.key = Object.keys(r.cost).sort().join('+');

// World objects. The index is the code stored in the map.
const OBJ = [
  null,
  { id: 'tree', name: 'Tree', sprite: 'tree', hp: 8, solid: true, need: 'axe', drops: [['wood', 2, 3], ['fiber', 0, 1]], color: '#3f8a3c' },
  { id: 'rock', name: 'Rock', sprite: 'rock', hp: 10, solid: true, need: 'pick', drops: [['stone', 2, 3]], color: '#8a8f98' },
  { id: 'iron', name: 'Iron Rock', sprite: 'iron_rock', hp: 16, solid: true, need: 'pick', hard: true, drops: [['iron_ore', 1, 2], ['stone', 0, 1]], color: '#9fb0c8' },
  { id: 'bush', name: 'Berry Bush', sprite: 'bush', hp: 2, solid: false, drops: [['berry', 1, 3], ['fiber', 0, 1]], color: '#c8413a' },
  { id: 'grass', name: 'Tall Grass', sprite: 'tallgrass', hp: 1, solid: false, flat: true, drops: [['fiber', 1, 2]], color: '#67b54a' },
  { id: 'wall', name: 'Wood Wall', sprite: 'wall', hp: 30, solid: true, placed: true, drops: [['wall', 1, 1]], color: '#a8703f' },
  { id: 'stone_wall', name: 'Stone Wall', sprite: 'stone_wall', hp: 60, solid: true, placed: true, drops: [['stone_wall', 1, 1]], color: '#c2c6cc' },
  { id: 'campfire', name: 'Campfire', sprite: 'campfire', hp: 20, solid: true, placed: true, light: 6.5, drops: [['campfire', 1, 1]], color: '#ea8a33' },
  { id: 'torch', name: 'Torch', sprite: 'torch', hp: 3, solid: false, placed: true, light: 4.5, drops: [['torch', 1, 1]], color: '#f2cf5b' },
  { id: 'spikes', name: 'Spike Trap', sprite: 'spikes', hp: 25, solid: false, placed: true, flat: true, trap: 7, drops: [['spikes', 1, 1]], color: '#e3ebf5' },
];
const NATURAL_MAX = 5; // codes 1..5 grow back on their own

const CREATURES = {
  rabbit: { name: 'Rabbit', hp: 6, speed: 2.8, dmg: 0, passive: true, r: 0.28, drops: [['meat', 1, 1], ['fur', 1, 1]] },
  slime: { name: 'Slime', hp: 10, speed: 1.4, dmg: 6, atkCd: 1.0, aggro: 6, hop: true, r: 0.3, drops: [['gel', 1, 2]], egg: ['egg_slime', 0.07] },
  ghoul: { name: 'Ghoul', hp: 24, speed: 1.8, dmg: 10, atkCd: 1.1, aggro: 9, nocturnal: true, breaker: true, r: 0.3, drops: [['bone', 1, 2]] },
  spider: { name: 'Rock Spider', hp: 14, speed: 2.5, dmg: 7, atkCd: 0.9, aggro: 7, r: 0.3, drops: [['silk', 1, 2]], egg: ['egg_spider', 0.07] },
  golem: { name: 'Stone Golem', hp: 320, speed: 1.15, dmg: 18, atkCd: 1.4, aggro: 22, boss: true, breaker: true, scale: 1.5, r: 0.7, drops: [['golem_heart', 1, 1], ['stone', 6, 10], ['iron_ore', 3, 5]], egg: ['egg_golem', 0.5] },
};

const PETS = {
  slime: { name: 'Slime buddy', hp: 45, dmg: 4, speed: 3.6, sprite: 'slime', scale: 0.8 },
  spider: { name: 'Spider buddy', hp: 45, dmg: 7, speed: 4.2, sprite: 'spider', scale: 0.85 },
  golem: { name: 'Pebble', hp: 150, dmg: 14, speed: 3.4, sprite: 'golem', scale: 0.75 },
};

// The goal list doubles as the tutorial.
const GOALS = [
  { text: 'Punch trees to gather 5 Wood', done: g => g.inv.count('wood') >= 5 || g.discovered.has('wood_sword'), reward: [['berry', 3]] },
  { text: 'Pull tall grass for 2 Plant Fiber', done: g => g.inv.count('fiber') >= 2 || g.discovered.has('wood_sword') },
  { text: 'Open your bag and mix Wood + Fiber in the pot', done: g => g.discovered.has('wood_sword') },
  { text: 'Make a Stone Axe or Stone Pickaxe', done: g => g.discovered.has('stone_axe') || g.discovered.has('stone_pick'), reward: [['bandage', 2]] },
  { text: 'Build a Campfire before dark', done: g => g.flags.campfire },
  { text: 'Hunt a rabbit and cook its meat', done: g => g.discovered.has('cooked_meat'), reward: [['torch', 2]] },
  { text: 'Survive your first night', done: g => g.day >= 2, reward: [['cooked_meat', 3]] },
  { text: 'Make some armor', done: g => g.discovered.has('fur_armor') || g.discovered.has('bone_armor') || g.discovered.has('iron_armor') },
  { text: 'Hatch a pet from a monster egg', done: g => !!g.pet },
  { text: 'Smelt an Iron Bar at a campfire', done: g => g.discovered.has('iron_bar'), reward: [['iron_ore', 4]] },
  { text: 'Defeat the Stone Golem (it wakes every 4th night)', done: g => g.flags.golem },
  { text: 'Forge the Heart Blade', done: g => g.discovered.has('heart_blade') },
];
