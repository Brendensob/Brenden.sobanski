extends Node
## Everything the game is made of: items, recipes, monsters, maps, NPCs and quests.
## Change numbers here to rebalance the game.
##
## Where the fan wikis for the original game list a number (for example the grassland
## slime's 13 HP, 1 damage and 20% drop chances), that number is used here.

const TILE := 16

# ---------------------------------------------------------------- items
# type: material, food, weapon, axe, pick, wand, armor, helmet, shield, ring, place, book, key
var ITEMS := {
	"wood": {"name": "Wood", "type": "material", "sell": 1, "desc": "Chopped from trees with an axe."},
	"stone": {"name": "Stone", "type": "material", "sell": 1, "desc": "Mined from rocks with a pickaxe."},
	"herb": {"name": "Herb", "type": "material", "sell": 1, "desc": "A common plant. Two herbs make a bandage."},
	"fiber": {"name": "Plant Fiber", "type": "material", "sell": 1, "desc": "Tough strands from bushes and trees."},
	"jelly": {"name": "Jelly", "type": "material", "sell": 2, "desc": "Wobbly goo left behind by slimes."},
	"bone": {"name": "Bone", "type": "material", "sell": 2, "desc": "Dropped by slimes and the undead."},
	"scarab": {"name": "Scarab", "type": "material", "sell": 3, "desc": "A shiny beetle. Slimes swallow them."},
	"snowball": {"name": "Snowball", "type": "material", "sell": 2, "desc": "Somehow still frozen."},
	"stinger": {"name": "Stinger", "type": "material", "sell": 3, "desc": "Pulled from a bee."},
	"leather": {"name": "Leather", "type": "material", "sell": 4, "desc": "Tanned boar hide."},
	"coal": {"name": "Coal", "type": "material", "sell": 3, "desc": "Fuel for the furnace. Found in rocks."},
	"iron_ore": {"name": "Iron Ore", "type": "material", "sell": 4, "desc": "Smelt it with coal at the furnace."},
	"iron_bar": {"name": "Iron Bar", "type": "material", "sell": 10, "desc": "Ready for iron gear."},
	"gold_ore": {"name": "Gold Ore", "type": "material", "sell": 8, "desc": "Smelt it with coal at the furnace."},
	"gold_bar": {"name": "Gold Bar", "type": "material", "sell": 20, "desc": "Soft, heavy and valuable."},
	"bat_wing": {"name": "Bat Wing", "type": "material", "sell": 6, "desc": "Leathery and thin."},
	"ectoplasm": {"name": "Ectoplasm", "type": "material", "sell": 8, "desc": "Cold, glowing slime from the Darklands."},
	"ember": {"name": "Ember", "type": "material", "sell": 12, "desc": "A coal that never goes out."},
	"obsidian": {"name": "Obsidian", "type": "material", "sell": 15, "desc": "Volcanic glass. Needs a gold pickaxe."},
	"king_jelly": {"name": "Royal Jelly", "type": "material", "sell": 40, "desc": "Always dropped by the Slime King."},
	"dark_flesh": {"name": "Dark Flesh", "type": "material", "sell": 80, "desc": "Always dropped by the Gloom Eye."},
	"fire_essence": {"name": "Fire Essence", "type": "material", "sell": 150, "desc": "Always dropped by the Cinder Lord."},
	"dust": {"name": "Dust", "type": "material", "sell": 1, "desc": "What's left when a combination fails. Two can make a crystal."},
	"crystal": {"name": "Crystal", "type": "material", "sell": 10, "desc": "Used to make lair keys and rings."},

	"mushroom": {"name": "Mushroom", "type": "food", "sell": 2, "heal": 1, "desc": "Restores 1 health."},
	"bandage": {"name": "Bandage", "type": "food", "sell": 3, "heal": 2, "desc": "Restores 2 health."},
	"honey_beetle": {"name": "Honey Beetle", "type": "food", "sell": 6, "heal": 3, "desc": "Sweet and crunchy. Restores 3 health."},
	"honey_bun": {"name": "Honey Bun", "type": "food", "sell": 15, "heal": 8, "desc": "Old Hollis would love one of these. Restores 8 health."},
	"ice_jelly": {"name": "Ice Jelly", "type": "food", "sell": 5, "stamina": 99, "desc": "Refills your stamina."},
	"mana_potion": {"name": "Mana Potion", "type": "food", "sell": 8, "mana": 99, "desc": "Refills your mana."},

	"wood_club": {"name": "Wooden Club", "type": "weapon", "sell": 2, "dmg": 3, "desc": "Your trusty starter club."},
	"stone_sword": {"name": "Stone Sword", "type": "weapon", "sell": 6, "dmg": 5, "desc": "Heavy, blunt and reliable."},
	"rusty_blade": {"name": "Rusty Blade", "type": "weapon", "sell": 30, "dmg": 9, "desc": "A rare find inside grassland slimes."},
	"iron_sword": {"name": "Iron Sword", "type": "weapon", "sell": 25, "dmg": 14, "desc": "Sharp enough for the Slime King."},
	"jelly_hammer": {"name": "Jelly Hammer", "type": "weapon", "sell": 60, "dmg": 22, "desc": "Bouncy, but it hits hard."},
	"gold_sword": {"name": "Gold Sword", "type": "weapon", "sell": 60, "dmg": 28, "desc": "Shiny and strong."},
	"dark_blade": {"name": "Dark Blade", "type": "weapon", "sell": 150, "dmg": 45, "desc": "Forged with the Gloom Eye's flesh."},
	"cinder_blade": {"name": "Cinder Blade", "type": "weapon", "sell": 400, "dmg": 90, "desc": "The strongest blade in the wilds."},
	"fire_wand": {"name": "Fire Wand", "type": "wand", "sell": 80, "dmg": 30, "mana_cost": 1, "desc": "Shoots fireballs. Uses 1 mana."},

	"wood_axe": {"name": "Wooden Axe", "type": "axe", "sell": 2, "dmg": 1, "power": 1, "desc": "Chops trees."},
	"stone_axe": {"name": "Stone Axe", "type": "axe", "sell": 6, "dmg": 2, "power": 2, "desc": "Chops trees twice as fast."},
	"iron_axe": {"name": "Iron Axe", "type": "axe", "sell": 25, "dmg": 4, "power": 3, "desc": "Chops trees three times as fast."},
	"wood_pick": {"name": "Wooden Pickaxe", "type": "pick", "sell": 2, "dmg": 1, "power": 1, "desc": "Mines rocks."},
	"stone_pick": {"name": "Stone Pickaxe", "type": "pick", "sell": 6, "dmg": 2, "power": 2, "desc": "Mines rocks and iron."},
	"iron_pick": {"name": "Iron Pickaxe", "type": "pick", "sell": 25, "dmg": 4, "power": 3, "desc": "Mines gold."},
	"gold_pick": {"name": "Gold Pickaxe", "type": "pick", "sell": 60, "dmg": 6, "power": 4, "desc": "Mines obsidian."},

	"leather_armor": {"name": "Leather Armor", "type": "armor", "sell": 15, "hp": 5, "desc": "+5 max health."},
	"iron_armor": {"name": "Iron Armor", "type": "armor", "sell": 40, "hp": 15, "desc": "+15 max health."},
	"gold_armor": {"name": "Gold Armor", "type": "armor", "sell": 90, "hp": 35, "desc": "+35 max health."},
	"obsidian_armor": {"name": "Obsidian Armor", "type": "armor", "sell": 200, "hp": 70, "def": 3, "desc": "+70 max health, blocks 3 damage per hit."},
	"leather_cap": {"name": "Leather Cap", "type": "helmet", "sell": 10, "hp": 3, "desc": "+3 max health."},
	"iron_helmet": {"name": "Iron Helmet", "type": "helmet", "sell": 30, "hp": 8, "desc": "+8 max health."},
	"gold_helmet": {"name": "Gold Helmet", "type": "helmet", "sell": 70, "hp": 18, "desc": "+18 max health."},
	"jelly_crown": {"name": "Jelly Crown", "type": "helmet", "sell": 80, "hp": 10, "mana": 2, "desc": "+10 max health, +2 max mana. Rare Slime King drop."},
	"wood_shield": {"name": "Wooden Shield", "type": "shield", "sell": 8, "hp": 2, "def": 1, "desc": "+2 max health, blocks 1 damage per hit."},
	"iron_shield": {"name": "Iron Shield", "type": "shield", "sell": 35, "hp": 6, "def": 2, "desc": "+6 max health, blocks 2 damage per hit."},
	"dark_shield": {"name": "Dark Shield", "type": "shield", "sell": 150, "hp": 15, "def": 5, "desc": "+15 max health, blocks 5 damage per hit. Rare Gloom Eye drop."},
	"stamina_ring": {"name": "Stamina Ring", "type": "ring", "sell": 40, "stamina": 3, "desc": "+3 max stamina."},
	"mana_ring": {"name": "Mana Ring", "type": "ring", "sell": 40, "mana": 3, "desc": "+3 max mana."},
	"power_ring": {"name": "Power Ring", "type": "ring", "sell": 120, "bonus_dmg": 5, "desc": "+5 damage on every hit."},

	"wood_wall": {"name": "Wood Wall", "type": "place", "sell": 2, "hp": 40, "desc": "Blocks monsters. Place it in front of you."},
	"stone_wall": {"name": "Stone Wall", "type": "place", "sell": 3, "hp": 100, "desc": "A sturdier wall."},
	"torch": {"name": "Torch", "type": "place", "sell": 2, "desc": "Lights up the night."},

	"survival_book": {"name": "Survival Book", "type": "book", "sell": 0, "bonus": 50, "tier": 1, "desc": "Keep it in your bag: +50% chance on basic combinations."},
	"combo_book_1": {"name": "Combination Book I", "type": "book", "sell": 0, "bonus": 30, "tier": 2, "desc": "Keep it in your bag: +30% chance on iron and key combinations."},
	"combo_book_2": {"name": "Combination Book II", "type": "book", "sell": 0, "bonus": 30, "tier": 3, "desc": "Keep it in your bag: +30% chance on gold combinations."},
	"combo_book_3": {"name": "Combination Book III", "type": "book", "sell": 0, "bonus": 30, "tier": 4, "desc": "Keep it in your bag: +30% chance on legendary combinations."},

	"grass_key": {"name": "Grassland Key", "type": "key", "sell": 0, "desc": "Opens the Slime King's lair. Used up on entry."},
	"dark_key": {"name": "Darkland Key", "type": "key", "sell": 0, "desc": "Opens the Gloom Eye's lair. Used up on entry."},
	"hell_key": {"name": "Hell Key", "type": "key", "sell": 0, "desc": "Opens the Cinder Lord's lair. Used up on entry."},
}

const STACK := 99
const UNSTACKABLE := ["weapon", "axe", "pick", "wand", "armor", "helmet", "shield", "ring", "book", "key"]
const EQUIP_SLOTS := ["helmet", "armor", "shield", "ring"]

# ---------------------------------------------------------------- crafting
# Two items go into the combination panel. Each recipe has a base success chance.
# Books in your bag add to the chance of recipes of their tier. A failed combination
# uses up both items and gives you Dust, like the original game.
var RECIPES := [
	# tier 0: always works
	{"a": "wood", "b": "wood", "out": "wood_wall", "n": 2, "chance": 100, "tier": 0},
	{"a": "stone", "b": "stone", "out": "stone_wall", "n": 1, "chance": 100, "tier": 0},
	{"a": "herb", "b": "herb", "out": "bandage", "n": 1, "chance": 100, "tier": 0},
	{"a": "wood", "b": "jelly", "out": "torch", "n": 2, "chance": 100, "tier": 0},
	{"a": "dust", "b": "dust", "out": "crystal", "n": 1, "chance": 50, "tier": 0},
	# furnace: stand next to the furnace in town
	{"a": "iron_ore", "b": "coal", "out": "iron_bar", "n": 1, "chance": 100, "tier": 0, "station": "furnace"},
	{"a": "gold_ore", "b": "coal", "out": "gold_bar", "n": 1, "chance": 100, "tier": 0, "station": "furnace"},
	# tier 1: Survival Book
	{"a": "scarab", "b": "jelly", "out": "honey_beetle", "n": 1, "chance": 45, "tier": 1},
	{"a": "wood", "b": "stone", "out": "stone_sword", "n": 1, "chance": 50, "tier": 1},
	{"a": "stone", "b": "fiber", "out": "stone_axe", "n": 1, "chance": 50, "tier": 1},
	{"a": "stone", "b": "bone", "out": "stone_pick", "n": 1, "chance": 50, "tier": 1},
	{"a": "snowball", "b": "jelly", "out": "ice_jelly", "n": 1, "chance": 50, "tier": 1},
	{"a": "mushroom", "b": "herb", "out": "mana_potion", "n": 1, "chance": 40, "tier": 1},
	{"a": "leather", "b": "fiber", "out": "leather_armor", "n": 1, "chance": 40, "tier": 1},
	{"a": "leather", "b": "leather", "out": "leather_cap", "n": 1, "chance": 40, "tier": 1},
	{"a": "wood", "b": "leather", "out": "wood_shield", "n": 1, "chance": 40, "tier": 1},
	# tier 2: Combination Book I
	{"a": "honey_beetle", "b": "herb", "out": "honey_bun", "n": 1, "chance": 40, "tier": 2},
	{"a": "iron_bar", "b": "wood", "out": "iron_sword", "n": 1, "chance": 40, "tier": 2},
	{"a": "iron_bar", "b": "iron_bar", "out": "iron_armor", "n": 1, "chance": 35, "tier": 2},
	{"a": "iron_bar", "b": "leather", "out": "iron_helmet", "n": 1, "chance": 35, "tier": 2},
	{"a": "iron_bar", "b": "wood_shield", "out": "iron_shield", "n": 1, "chance": 35, "tier": 2},
	{"a": "iron_bar", "b": "stone", "out": "iron_pick", "n": 1, "chance": 40, "tier": 2},
	{"a": "iron_bar", "b": "fiber", "out": "iron_axe", "n": 1, "chance": 40, "tier": 2},
	{"a": "crystal", "b": "scarab", "out": "grass_key", "n": 1, "chance": 40, "tier": 2},
	{"a": "crystal", "b": "stinger", "out": "stamina_ring", "n": 1, "chance": 30, "tier": 2},
	{"a": "crystal", "b": "bat_wing", "out": "mana_ring", "n": 1, "chance": 30, "tier": 2},
	# tier 3: Combination Book II
	{"a": "king_jelly", "b": "iron_bar", "out": "jelly_hammer", "n": 1, "chance": 35, "tier": 3},
	{"a": "gold_bar", "b": "wood", "out": "gold_sword", "n": 1, "chance": 35, "tier": 3},
	{"a": "gold_bar", "b": "gold_bar", "out": "gold_armor", "n": 1, "chance": 30, "tier": 3},
	{"a": "gold_bar", "b": "leather", "out": "gold_helmet", "n": 1, "chance": 30, "tier": 3},
	{"a": "gold_bar", "b": "stone", "out": "gold_pick", "n": 1, "chance": 35, "tier": 3},
	{"a": "crystal", "b": "ectoplasm", "out": "dark_key", "n": 1, "chance": 35, "tier": 3},
	{"a": "ember", "b": "wood", "out": "fire_wand", "n": 1, "chance": 30, "tier": 3},
	# tier 4: Combination Book III
	{"a": "dark_flesh", "b": "gold_bar", "out": "dark_blade", "n": 1, "chance": 30, "tier": 4},
	{"a": "obsidian", "b": "gold_bar", "out": "obsidian_armor", "n": 1, "chance": 25, "tier": 4},
	{"a": "crystal", "b": "ember", "out": "hell_key", "n": 1, "chance": 30, "tier": 4},
	{"a": "crystal", "b": "iron_bar", "out": "power_ring", "n": 1, "chance": 25, "tier": 4},
	{"a": "fire_essence", "b": "obsidian", "out": "cinder_blade", "n": 1, "chance": 25, "tier": 4},
]

const TIER_BOOK := {1: "survival_book", 2: "combo_book_1", 3: "combo_book_2", 4: "combo_book_3"}

func find_recipe(a: String, b: String) -> Dictionary:
	for r in RECIPES:
		if (r.a == a and r.b == b) or (r.a == b and r.b == a):
			return r
	return {}

# ---------------------------------------------------------------- harvestable things
# need: which tool type, min: minimum tool power. drops: [item, chance, min, max]
var NODES := {
	"tree": {"hp": 4, "need": "axe", "min": 1, "drops": [["wood", 1.0, 1, 2], ["fiber", 0.3, 1, 1]]},
	"dead_tree": {"hp": 6, "need": "axe", "min": 1, "drops": [["wood", 1.0, 1, 2], ["fiber", 0.2, 1, 1]]},
	"ash_tree": {"hp": 9, "need": "axe", "min": 2, "drops": [["wood", 1.0, 2, 3], ["ember", 0.08, 1, 1]]},
	"rock": {"hp": 5, "need": "pick", "min": 1, "drops": [["stone", 1.0, 1, 2], ["coal", 0.2, 1, 1]]},
	"iron_rock": {"hp": 8, "need": "pick", "min": 2, "drops": [["iron_ore", 1.0, 1, 1], ["coal", 0.35, 1, 1]]},
	"gold_rock": {"hp": 12, "need": "pick", "min": 3, "drops": [["gold_ore", 1.0, 1, 1], ["coal", 0.4, 1, 1]]},
	"obsidian_rock": {"hp": 18, "need": "pick", "min": 4, "drops": [["obsidian", 1.0, 1, 1], ["coal", 0.4, 1, 1]]},
	"bush": {"hp": 1, "need": "", "min": 0, "drops": [["herb", 1.0, 1, 1], ["fiber", 0.5, 1, 1], ["scarab", 0.1, 1, 1]]},
	"mushrooms": {"hp": 1, "need": "", "min": 0, "drops": [["mushroom", 1.0, 1, 2], ["herb", 0.3, 1, 1]]},
}

# ---------------------------------------------------------------- monsters
# ai: hopper (hops along), walker, charger (rushes you), flyer
# drops: [item, chance, min, max]. hp is [min, max].
var MOBS := {
	"slime": {"name": "Slime", "hp": [13, 13], "dmg": 1, "speed": 30, "ai": "hopper", "sprite": "slime", "aggro": 110, "coins": [1, 2],
		"drops": [["bone", 0.2, 1, 1], ["jelly", 0.2, 1, 1], ["scarab", 0.2, 1, 1], ["snowball", 0.2, 1, 1], ["rusty_blade", 0.055, 1, 1]]},
	"bee": {"name": "Bee", "hp": [10, 10], "dmg": 1, "speed": 38, "ai": "flyer", "sprite": "bee", "aggro": 120, "coins": [1, 2],
		"drops": [["stinger", 0.5, 1, 1], ["jelly", 0.1, 1, 1]]},
	"shroom": {"name": "Shroom", "hp": [20, 20], "dmg": 1, "speed": 22, "ai": "walker", "sprite": "shroom", "aggro": 90, "coins": [2, 3],
		"drops": [["mushroom", 0.5, 1, 1], ["herb", 0.3, 1, 1]]},
	"boar": {"name": "Boar", "hp": [35, 35], "dmg": 2, "speed": 34, "ai": "charger", "sprite": "boar", "aggro": 130, "coins": [3, 5],
		"drops": [["leather", 0.6, 1, 1], ["bone", 0.3, 1, 1]]},
	"dark_slime": {"name": "Dark Slime", "hp": [125, 150], "dmg": 7, "speed": 34, "ai": "hopper", "jump_close": true, "sprite": "dark_slime", "aggro": 120, "coins": [8, 12],
		"drops": [["herb", 0.5, 1, 1], ["jelly", 0.4, 1, 2], ["ectoplasm", 0.1, 1, 1]]},
	"bat": {"name": "Bat", "hp": [90, 90], "dmg": 6, "speed": 48, "ai": "flyer", "sprite": "bat", "aggro": 140, "coins": [8, 12],
		"drops": [["bat_wing", 0.5, 1, 1]]},
	"zombie": {"name": "Zombie", "hp": [180, 180], "dmg": 8, "speed": 22, "ai": "walker", "sprite": "zombie", "aggro": 120, "coins": [10, 15],
		"drops": [["ectoplasm", 0.4, 1, 1], ["bone", 0.4, 1, 2], ["leather", 0.2, 1, 1]]},
	"skeleton": {"name": "Skeleton", "hp": [200, 200], "dmg": 9, "speed": 30, "ai": "walker", "jump_close": true, "sprite": "skeleton", "aggro": 130, "coins": [12, 18],
		"drops": [["bone", 0.8, 1, 2], ["gold_ore", 0.15, 1, 1]]},
	"magma_slime": {"name": "Magma Slime", "hp": [400, 400], "dmg": 15, "speed": 36, "ai": "hopper", "jump_close": true, "sprite": "magma_slime", "aggro": 130, "coins": [25, 35],
		"drops": [["ember", 0.5, 1, 1], ["jelly", 0.3, 1, 2]]},
	"imp": {"name": "Imp", "hp": [300, 300], "dmg": 14, "speed": 52, "ai": "flyer", "sprite": "imp", "aggro": 150, "coins": [25, 35],
		"drops": [["ember", 0.6, 1, 1], ["bat_wing", 0.2, 1, 1]]},
	"hell_knight": {"name": "Hell Knight", "hp": [600, 600], "dmg": 20, "speed": 30, "ai": "charger", "sprite": "hell_knight", "aggro": 140, "coins": [40, 60],
		"drops": [["obsidian", 0.4, 1, 1], ["gold_bar", 0.2, 1, 1]]},

	# Bosses heal over time, and ten times faster when nobody is fighting them.
	"slime_king": {"name": "Slime King", "boss": true, "hp": [600, 600], "dmg": 3, "speed": 40, "ai": "hopper", "jump_close": true, "sprite": "slime_king",
		"aggro": 400, "coins": [100, 140], "regen": 2.0, "summon": "slime", "no_knockback": true,
		"drops": [["king_jelly", 1.0, 1, 1], ["combo_book_2", 0.5, 1, 1], ["jelly_crown", 0.3, 1, 1], ["jelly", 1.0, 3, 6]]},
	"gloom_eye": {"name": "Gloom Eye", "boss": true, "hp": [2000, 2000], "dmg": 10, "speed": 40, "ai": "flyer", "shoots": true, "sprite": "gloom_eye",
		"aggro": 400, "coins": [300, 400], "regen": 6.0, "summon": "bat", "no_knockback": true,
		"drops": [["dark_flesh", 1.0, 1, 1], ["combo_book_3", 0.5, 1, 1], ["dark_shield", 0.3, 1, 1], ["ectoplasm", 1.0, 2, 4]]},
	"cinder_lord": {"name": "Cinder Lord", "boss": true, "hp": [5000, 5000], "dmg": 25, "speed": 34, "ai": "charger", "jump_close": true, "sprite": "cinder_lord",
		"aggro": 400, "coins": [800, 1000], "regen": 12.0, "summon": "imp", "no_knockback": true,
		"drops": [["fire_essence", 1.0, 1, 1], ["obsidian", 1.0, 2, 4], ["power_ring", 0.25, 1, 1]]},
}

# ---------------------------------------------------------------- maps
# Each zone has 8 levels and a boss lair, like the original.
# mobs: [mob, first level it appears]. nodes: [node, first level, weight].
var ZONES := {
	"grass": {"name": "Grasslands", "boss": "slime_king", "key": "grass_key", "unlock_after": "",
		"sky": [Color("6fb6dc"), Color("bfe3ee")], "mount": Color("5a8c8a"), "snow": Color("e8f2f2"), "hills": Color("3f8a52"),
		"top": Color("5cbf3f"), "top2": Color("3e9a2e"), "dirt": Color("8a5a32"), "dirt2": Color("6e4426"),
		"mobs": [["slime", 1], ["bee", 2], ["shroom", 3], ["boar", 5]],
		"nodes": [["tree", 1, 5], ["rock", 1, 3], ["bush", 1, 3], ["iron_rock", 4, 1]]},
	"dark": {"name": "Darklands", "boss": "gloom_eye", "key": "dark_key", "unlock_after": "slime_king",
		"sky": [Color("2a2340"), Color("5a4a6e")], "mount": Color("4a3e6a"), "snow": Color("9a8ab0"), "hills": Color("2e2a3e"),
		"top": Color("6a5a8a"), "top2": Color("4a3e66"), "dirt": Color("3e3040"), "dirt2": Color("2c2230"),
		"mobs": [["dark_slime", 1], ["bat", 2], ["zombie", 3], ["skeleton", 5]],
		"nodes": [["dead_tree", 1, 4], ["rock", 1, 3], ["mushrooms", 1, 2], ["iron_rock", 1, 1], ["gold_rock", 3, 1]]},
	"hell": {"name": "Hell", "boss": "cinder_lord", "key": "hell_key", "unlock_after": "gloom_eye",
		"sky": [Color("4a1414"), Color("a8402a")], "mount": Color("5a1e1a"), "snow": Color("f2a33a"), "hills": Color("3a1210"),
		"top": Color("a83a22"), "top2": Color("7a2416"), "dirt": Color("3a1a16"), "dirt2": Color("2a100e"),
		"mobs": [["magma_slime", 1], ["imp", 2], ["hell_knight", 4]],
		"nodes": [["ash_tree", 1, 3], ["rock", 1, 2], ["gold_rock", 1, 1], ["obsidian_rock", 2, 2]]},
}
const ZONE_ORDER := ["grass", "dark", "hell"]
const LEVELS_PER_ZONE := 8

func level_name(id: String) -> String:
	if id == "town":
		return "Pixel Village"
	var parts := id.split("_")
	var z: Dictionary = ZONES[parts[0]]
	if parts[1] == "lair":
		return "%s Lair" % MOBS[z.boss].name
	return "%s %s" % [z.name, parts[1]]

# ---------------------------------------------------------------- town
var NPCS := [
	{"id": "pip", "name": "Pip", "x": 9, "look": "pip", "talk": "Welcome to Pixel Village! The portal on the right takes you out into the wilds. Come back here whenever you need to sell, smelt or rest."},
	{"id": "tilly", "name": "Tilly", "x": 17, "look": "tilly", "shop": true, "talk": "Buying or selling? I pay fair coin for anything you find out there."},
	{"id": "hollis", "name": "Old Hollis", "x": 25, "look": "hollis", "talk": "My old furnace hasn't been lit in years. I'd fire it up again for something sweet."},
	{"id": "bram", "name": "Bram", "x": 33, "look": "bram", "talk": "Iron, gold, obsidian. Bring me good metal and I'll make it worth your while."},
	{"id": "moss", "name": "Moss", "x": 41, "look": "moss", "talk": "Each zone has eight levels and a lair at the end. Lairs need a key, and the key gets used up when you go in."},
]

# Quests are handed out in order by each NPC.
var QUESTS := [
	{"id": "q_wall", "npc": "pip", "text": "Make a Wood Wall in the combination panel (Wood + Wood) and bring it to me.",
		"need": {"wood_wall": 1}, "reward": {"survival_book": 1, "bandage": 2}, "coins": 10},
	{"id": "q_jelly", "npc": "pip", "text": "Slimes in the Grasslands drop Jelly. Bring me 3.",
		"need": {"jelly": 3}, "reward": {"combo_book_1": 1}, "coins": 20},
	{"id": "q_bun", "npc": "hollis", "text": "Bring me a Honey Bun (Honey Beetle + Herb) and I'll light the furnace for you.",
		"need": {"honey_bun": 1}, "reward": {}, "coins": 30, "unlock": "furnace"},
	{"id": "q_iron", "npc": "bram", "text": "Smelt Iron Ore with Coal at the furnace. Bring me 3 Iron Bars.",
		"need": {"iron_bar": 3}, "reward": {"iron_helmet": 1, "crystal": 2}, "coins": 40},
	{"id": "q_king", "npc": "moss", "text": "Defeat the Slime King in the Grassland lair. Crystal + Scarab makes the key.",
		"need": {}, "boss": "slime_king", "reward": {"crystal": 3}, "coins": 100},
	{"id": "q_gold", "npc": "bram", "text": "The Darklands have gold. Bring me 3 Gold Bars.",
		"need": {"gold_bar": 3}, "reward": {"gold_pick": 1}, "coins": 120},
	{"id": "q_eye", "npc": "moss", "text": "Defeat the Gloom Eye in the Darkland lair.",
		"need": {}, "boss": "gloom_eye", "reward": {"crystal": 5}, "coins": 300},
	{"id": "q_cinder", "npc": "moss", "text": "Defeat the Cinder Lord in the depths of Hell.",
		"need": {}, "boss": "cinder_lord", "reward": {"crystal": 10}, "coins": 1000},
]

# Tilly's shop. Prices are in coins, earned by selling and from monsters.
var SHOP := ["bandage", "torch", "wood_wall", "mana_potion", "ice_jelly", "wood_shield", "leather_armor", "stone_pick", "stone_axe"]
const BUY_MULT := 4

func buy_price(id: String) -> int:
	return max(4, int(ITEMS[id].sell) * BUY_MULT)
