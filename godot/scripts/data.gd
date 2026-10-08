extends Node
## Everything the game is made of: items, recipes, smithing, smelting, monsters,
## worlds, villagers, quests, shops, chests and pets.
##
## Numbers (monster health and damage, weapon attack and speed, armor stats,
## combination success rates, smelting times, tool hits, day length, survival
## rewards) follow the fan wikis for Pixel Survival Game 2. Distinctive names,
## characters and all art are this game's own. Drop chances the wikis don't list
## are estimates and are marked "est." where they matter.

const TILE := 16
const DAY_LENGTH := 216.0 # one full day in seconds
const ARENA_BOSS_TIME := 180.0 # bosses arrive 3 minutes into an arena

# ---------------------------------------------------------------- items
# type: material, food, weapon, staff, bow, ammo, axe, pick, helmet, armor, shield,
#       ring, pet, egg, seed, place, book, scroll, key, token
# gear stats: atk, def, mag, hp, mp, st
# weapons: dmg (attack), spd (seconds per swing), reach (px), kb (knockback)
# tools: tier 1 wooden, 2 copper, 3 iron, 4 gold, 5 erbium
var ITEMS := {}

func _item(id: String, name: String, type: String, sell: int, desc: String, extra: Dictionary = {}) -> void:
	var d := {"name": name, "type": type, "sell": sell, "desc": desc}
	d.merge(extra)
	ITEMS[id] = d

func _init() -> void:
	_items_materials()
	_items_consumables()
	_items_weapons()
	_items_gear()
	_items_misc()

func _items_materials() -> void:
	var m := [
		["wood", "Wood", 1, "Chopped from trees."], ["branch", "Branch", 1, "Falls from trees."],
		["rock", "Rock", 1, "Mined from stones."], ["coal", "Coal", 3, "Fuel for the furnaces."],
		["scarab", "Scarab", 2, "A shiny beetle."], ["stink_bug", "Stink Bug", 3, "Smells exactly how you'd expect."],
		["honey_bug", "Honey Bug", 4, "A sweet little bug."], ["fire_bug", "Fire Bug", 4, "Warm to the touch."],
		["power_bug", "Power Bug", 30, "A rare, strong bug."], ["armor_bug", "Armor Bug", 30, "A rare, tough bug."],
		["hero_bug", "Hero Bug", 120, "A very rare bug of legend."],
		["jelly", "Jelly", 2, "Wobbly goo from slimes."], ["bone", "Bone", 2, "Dropped by many monsters."],
		["sticky_balls", "Sticky Balls", 6, "Jelly that stuck together."], ["sticky_bones", "Sticky Bones", 8, "Bones coated in goo."],
		["snowball", "Snowball", 3, "Somehow never melts."],
		["herb", "Herb", 1, "A common healing plant."], ["antidote_herb", "Antidote Herb", 3, "Cures poison when brewed."],
		["plant_roots", "Plant Roots", 2, "Dug up from plants."], ["old_roots", "Old Roots", 8, "Very old roots."],
		["legendary_roots", "Legendary Roots", 80, "Roots of legend."], ["blue_moon", "Blue Moon", 6, "A pale blue flower."],
		["crystal", "Crystal", 10, "A clear crystal."], ["fire_crystal", "Fire Crystal", 20, "A crystal full of fire."],
		["water_crystal", "Water Crystal", 20, "A crystal full of water."], ["earth_crystal", "Earth Crystal", 20, "A crystal full of earth."],
		["dark_crystal", "Dark Crystal", 20, "A crystal full of darkness."], ["evil_crystal", "Evil Crystal", 80, "It hums quietly."],
		["small_evil_crystal", "Small Evil Crystal", 30, "A shard of something bad."],
		["catalyst", "Catalyst", 15, "Helps hard combinations along."], ["dongle", "Dongle", 25, "A strange little gadget."],
		["dust", "Dust", 1, "What a failed combination leaves behind."],
		["monster_hide", "Monster Hide", 5, "Rough hide."], ["monster_leather", "Monster Leather", 12, "Tanned monster hide."],
		["harden_leather", "Hardened Leather", 25, "Leather made tough."], ["monster_shell", "Monster Shell", 5, "A hard shell."],
		["monster_scale", "Monster Scale", 5, "A shiny scale."], ["monster_horn", "Monster Horn", 6, "A sharp horn."],
		["linen", "Linen", 10, "Woven from roots."], ["wood_board", "Wood Board", 3, "A flat plank."],
		["nail", "Nail", 2, "Holds things together."], ["blue_wood", "Blue Wood", 15, "Wood from blue trees. Needs a gold axe."],
		["apple", "Apple", 15, "Looks delicious, but it's for crafting."], ["evil_apple", "Evil Apple", 300, "Don't eat it."],
		["living_flame", "Living Flame", 60, "A flame that won't go out. Smelted from fire crystals."],
		["copper_ore", "Copper Ore", 3, "Smelt 5 with 1 coal for a copper bar."], ["iron_ore", "Iron Ore", 5, "Smelt 5 with 1 coal for an iron bar."],
		["silver_ore", "Silver Ore", 8, "Smelt 5 with 1 coal for a silver bar."], ["gold_ore", "Gold Ore", 12, "Smelt 5 with 1 coal for a gold bar."],
		["erbium", "Erbium", 40, "A rare ore. Smelt 5 with 1 coal for an erbium bar."], ["volcanic_ore", "Volcanic Ore", 400, "Extremely rare ore."],
		["copper_bar", "Copper Bar", 18, "Smelted copper."], ["iron_bar", "Iron Bar", 30, "Smelted iron."],
		["silver_bar", "Silver Bar", 45, "Smelted silver."], ["gold_bar", "Gold Bar", 70, "Smelted gold."],
		["erbium_bar", "Erbium Bar", 220, "Smelted erbium."], ["volcanic_bar", "Volcanic Bar", 2200, "Smelted volcanic ore."],
		["light_bar", "Light Bar", 400, "Water crystals and silver, smelted."], ["dark_bar", "Dark Bar", 450, "Dark crystals and gold, smelted."],
		["hell_bar", "Hell Bar", 900, "Earth crystals and erbium, smelted."], ["evil_bar", "Evil Bar", 2000, "The strongest common metal."],
		["em_stone", "Em Stone", 500, "A green gem stone."], ["ruby_stone", "Ruby Stone", 500, "A red gem stone."],
		["sapphire_stone", "Sapphire Stone", 500, "A blue gem stone."],
	]
	for r in m:
		_item(r[0], r[1], "material", r[2], r[3])

func _items_consumables() -> void:
	var f := [
		["small_potion", "Small Potion", 3, {"heal": 3}], ["potion", "Potion", 6, {"heal": 6}],
		["medium_potion", "Medium Potion", 12, {"heal": 15}], ["big_potion", "Big Potion", 25, {"heal": 35}],
		["small_mana_potion", "Small Mana Potion", 3, {"mana": 3}], ["mana_potion", "Mana Potion", 6, {"mana": 6}],
		["medium_mana_potion", "Medium Mana Potion", 12, {"mana": 15}], ["big_mana_potion", "Big Mana Potion", 25, {"mana": 35}],
		["rejuvenate_potion", "Rejuvenate Potion", 15, {"heal": 6, "mana": 6, "stamina": 6}],
		["medium_rejuvenate_potion", "Medium Rejuvenate Potion", 30, {"heal": 15, "mana": 15, "stamina": 15}],
		["big_rejuvenate_potion", "Big Rejuvenate Potion", 60, {"heal": 35, "mana": 35, "stamina": 35}],
		["antidote", "Antidote", 8, {"cure": "poison"}], ["fatigue_potion", "Fatigue Potion", 8, {"cure": "fatigue"}],
		["pretzel", "Pretzel", 20, {"heal": 2}], ["holy_banana", "Holy Banana", 40, {"heal": 10, "stamina": 10}],
	]
	for r in f:
		var desc := ""
		var e: Dictionary = r[3]
		if e.has("heal"): desc += "Restores %d health. " % e.heal
		if e.has("mana"): desc += "Restores %d mana. " % e.mana
		if e.has("stamina"): desc += "Restores %d stamina. " % e.stamina
		if e.has("cure"): desc += "Cures %s. " % e.cure
		if r[0] == "pretzel": desc += "The Furnace Warden would love one."
		_item(r[0], r[1], "food", r[2], desc.strip_edges(), e)

func _items_weapons() -> void:
	# [id, name, attack, seconds per swing, reach, knockback, sell, desc]
	var w := [
		["fist", "Fist", 1, 0.5, 14, false, 0, ""],
		["sword_cast", "Sword Cast", 3, 0.5, 16, true, 10, "A short practice blade."],
		["copper_sword_cast", "Copper Sword Cast", 4, 0.5, 16, true, 20, "Part of the Combo Sword."],
		["iron_sword_cast", "Iron Sword Cast", 4, 0.5, 16, true, 20, "Part of the Combo Sword, and of the Hell Sword."],
		["gold_sword_cast", "Gold Sword Cast", 4, 0.5, 16, true, 20, "Part of the Combo Sword."],
		["torch_weapon", "Torch", 5, 1.0, 22, true, 1, "Long reach, slow swing."],
		["timber_club", "Timber Club", 5, 0.75, 18, true, 15, "A heavy wooden club."],
		["short_blade", "Short Blade", 5, 0.45, 16, true, 20, "Small but quick. Slimes sometimes drop it."],
		["gilded_blade", "Gilded Blade", 6, 0.5, 18, true, 30, "A short blade with a gold finish."],
		["azure_blade", "Azure Blade", 9, 0.55, 20, true, 45, "A blue steel blade."],
		["fire_brand", "Fire Brand", 13, 0.55, 20, true, 45, "Warm to hold."],
		["violet_edge", "Violet Edge", 19, 0.55, 20, true, 60, "A purple-glinting sword."],
		["plunger", "Plunger", 4, 0.4, 16, true, 10, "For the bravest of plumbers."],
		["knights_blade", "Knight's Blade", 15, 0.6, 22, true, 70, "A proper knight's sword."],
		["kings_mace", "King's Mace", 27, 0.55, 22, true, 120, "Heavy and royal."],
		["excalibur", "Excalibur", 23, 0.9, 24, true, 120, "Slow, but long and strong."],
		["poison_ivy", "Poison Ivy", 31, 0.6, 22, true, 160, "A thorny green blade."],
		["holy_knight", "Holy Knight", 34, 0.5, 22, true, 200, "Shines with holy light."],
		["hellfire_blade", "Hellfire Blade", 38, 0.6, 24, true, 220, "Burns everything it touches."],
		["combo_sword", "Combo Sword", 14, 0.65, 18, true, 80, "Three casts forged into one."],
		["moon_blade", "Moon Blade", 17, 0.65, 22, true, 150, "A crescent-shaped blade."],
		["moon_blade_2", "Moon Blade II", 30, 0.65, 22, true, 300, "Sharper under moonlight."],
		["moon_blade_3", "Moon Blade III", 55, 0.65, 24, true, 600, "Brighter than the moon."],
		["glow_blade_blue", "Glow Blade (Blue)", 19, 0.5, 22, true, 150, "Emits a glowing blue light."],
		["glow_blade_red", "Glow Blade (Red)", 19, 0.5, 22, true, 150, "Emits a glowing red light."],
		["glow_blade_green", "Glow Blade (Green)", 21, 0.5, 22, true, 170, "Emits a glowing green light."],
		["glow_blade_pink", "Glow Blade (Pink)", 21, 0.5, 22, true, 170, "Emits a glowing pink light."],
		["long_sword", "Long Sword", 20, 0.6, 28, true, 150, "Long reach."],
		["golden_long_sword", "Golden Long Sword", 28, 0.6, 28, true, 300, "Long reach, golden edge."],
		["pole_axe", "Pole Axe", 15, 1.0, 26, true, 25, "A slow, heavy axe on a pole. Also chops trees.", {"axe": 2}],
		["twin_sun", "Twin Sun", 14, 0.55, 22, true, 300, "Two suns on one hilt."],
		["devil_spike", "Devil Spike", 45, 0.9, 26, true, 500, "A wicked spiked weapon."],
		["hell_sword", "Hell Sword", 105, 0.55, 26, true, 1500, "Forged from evil itself."],
	]
	for r in w:
		var extra := {"dmg": r[2], "spd": r[3], "reach": r[4], "kb": r[5]}
		if r.size() > 8:
			extra.merge(r[8])
		_item(r[0], r[1], "weapon", r[6], r[7], extra)
	# magic, uses mana
	_item("magic_wand", "Magic Wand", "staff", 25, "Shoots a magic bolt. Uses 1 mana.", {"dmg": 6, "spd": 0.6, "mana_cost": 1, "color": "a77ee0"})
	_item("staff_cast", "Staff Cast", "staff", 10, "A plain staff. Shoots a weak bolt.", {"dmg": 3, "spd": 0.6, "mana_cost": 1, "color": "c8b89a"})
	_item("fire_staff", "Fire Staff", "staff", 120, "Shoots fireballs. Uses 2 mana.", {"dmg": 25, "spd": 0.7, "mana_cost": 2, "color": "f2a33a"})
	_item("hallow_staff", "Hallow Staff", "staff", 80, "Shoots ghostly bolts. Uses 2 mana.", {"dmg": 21, "spd": 1.0, "mana_cost": 2, "color": "8affc8"})
	_item("healing_staff", "Healing Staff", "staff", 80, "Uses 3 mana to heal you for 6.", {"heal": 6, "spd": 1.0, "mana_cost": 3, "color": "5cbf3f"})
	_item("healing_staff_2", "Healing Staff II", "staff", 200, "Uses 4 mana to heal you for 12.", {"heal": 12, "spd": 1.0, "mana_cost": 4, "color": "5cbf3f"})
	_item("healing_staff_3", "Healing Staff III", "staff", 400, "Uses 5 mana to heal you for 20.", {"heal": 20, "spd": 1.0, "mana_cost": 5, "color": "5cbf3f"})
	# ranged, uses arrows
	_item("weak_bow", "Weak Bow", "bow", 15, "Shoots arrows.", {"dmg": 4, "spd": 0.7})
	_item("bow", "Bow", "bow", 40, "Shoots arrows.", {"dmg": 9, "spd": 0.65})
	_item("steel_bow", "Steel Bow", "bow", 120, "Shoots arrows hard.", {"dmg": 18, "spd": 0.6})
	_item("arrow", "Arrow", "ammo", 1, "Ammunition for bows.")
	# tools
	var t := [
		["wooden_axe", "Wooden Axe", "axe", 1, 1], ["copper_axe", "Copper Axe", "axe", 2, 2], ["iron_axe", "Iron Axe", "axe", 3, 3],
		["gold_axe", "Gold Axe", "axe", 4, 4], ["wooden_pick", "Wooden Pick", "pick", 1, 1], ["copper_pick", "Copper Pickaxe", "pick", 2, 2],
		["iron_pick", "Iron Pickaxe", "pick", 3, 3], ["gold_pick", "Gold Pickaxe", "pick", 4, 4], ["erbium_pick", "Erbium Pickaxe", "pick", 4, 5],
	]
	for r in t:
		var what: String = "chop trees" if r[2] == "axe" else "mine rocks and ores"
		_item(r[0], r[1], r[2], 25 if r[4] > 1 else 0, "Used to %s. Tier %d." % [what, r[4]], {"dmg": r[3], "spd": 0.5, "reach": 16, "kb": false, "tier": r[4]})

func _gear(id: String, name: String, type: String, s: Array, sell: int, desc: String = "") -> void:
	# s = [atk, def, mag, hp, mp, st]
	var stats := {"atk": s[0], "def": s[1], "mag": s[2], "hp": s[3], "mp": s[4], "st": s[5]}
	var parts := []
	for k in ["atk", "def", "mag", "hp", "mp", "st"]:
		if stats[k] != 0:
			parts.append("%s +%d" % [{"atk": "Attack", "def": "Defense", "mag": "Magic", "hp": "Health", "mp": "Mana", "st": "Stamina"}[k], stats[k]])
	_item(id, name, type, sell, (desc + " " if desc != "" else "") + ", ".join(parts) + ".", {"stats": stats})

func _items_gear() -> void:
	# helmets
	_gear("wooden_helmet", "Wooden Helmet", "helmet", [0, 1, 0, 0, 0, 0], 10)
	_gear("copper_helmet", "Copper Helmet", "helmet", [0, 3, 0, 2, 0, 0], 40)
	_gear("brass_helmet", "Brass Helmet", "helmet", [0, 4, 0, 4, 0, 0], 80)
	_gear("pumpkin_hat", "Pumpkin Hat", "helmet", [4, 4, 4, 4, 0, 0], 150)
	_gear("fear_helmet", "Fear Helmet", "helmet", [0, 7, 0, 7, 0, 0], 300)
	_gear("fear_helmet_2", "Fear Helmet II", "helmet", [0, 15, 0, 15, 5, 0], 900)
	_gear("hell_helmet", "Hell Helmet", "helmet", [0, 4, 0, 7, 7, 0], 300)
	_gear("hell_helmet_2", "Hell Helmet II", "helmet", [0, 5, 0, 7, 10, 10], 900)
	_gear("witch_helmet", "Witch Helmet", "helmet", [0, 5, 5, 5, 5, 0], 300)
	_gear("witch_helmet_2", "Witch Helmet II", "helmet", [0, 7, 5, 10, 10, 0], 900)
	_gear("spectre_hood", "Spectre Hood", "helmet", [3, 12, 3, 5, 5, 2], 1200, "Rare Ghost Lord drop.")
	# armor
	_gear("wooden_armor", "Wooden Armor", "armor", [0, 2, 0, 2, 0, 0], 15)
	_gear("stone_armor", "Stone Armor", "armor", [0, 3, 0, 5, 0, 0], 30)
	_gear("leather_armor", "Leather Armor", "armor", [0, 2, 0, 5, 0, 1], 40)
	_gear("tough_leather_armor", "Tough Leather Armor", "armor", [0, 3, 0, 8, 0, 1], 70)
	_gear("copper_armor", "Copper Armor", "armor", [0, 4, 0, 4, 0, 0], 60)
	_gear("iron_armor", "Iron Armor", "armor", [0, 4, 0, 8, 0, 0], 100)
	_gear("golden_armor", "Golden Armor", "armor", [0, 5, 0, 13, 0, 2], 200)
	_gear("silver_armor", "Silver Armor", "armor", [0, 1, 0, 3, 8, 0], 150)
	_gear("jelly_armor", "Jelly Armor", "armor", [0, 0, 1, 4, 7, 0], 120)
	_gear("linen_armor", "Linen Armor", "armor", [0, 2, 0, 6, 0, 4], 120)
	_gear("blood_diamond_armor", "Blood Diamond Armor", "armor", [0, 5, 0, 15, 0, 0], 300)
	_gear("chainmail", "Chainmail", "armor", [0, 15, 0, 5, 0, 0], 300)
	_gear("golden_knight_armor", "Golden Knight Armor", "armor", [0, 8, 0, 12, 0, 0], 350)
	_gear("ivory_armor", "Ivory Armor", "armor", [0, 10, 0, 10, 0, 0], 450)
	_gear("scale_armor", "Scale Armor", "armor", [0, 4, 0, 10, 6, 0], 400)
	_gear("seer_armor", "Seer Armor", "armor", [0, 0, 0, 10, 10, 0], 400)
	_gear("jade_armor", "Jade Armor", "armor", [0, 14, 0, 14, 0, 0], 900)
	_gear("sandy_armor", "Sandy Armor", "armor", [0, 18, 0, 10, 0, 0], 900)
	_gear("sage_armor", "Sage Armor", "armor", [0, 0, 0, 14, 14, 0], 900)
	_gear("lavish_armor", "Lavish Armor", "armor", [0, 3, 0, 25, 0, 0], 900)
	_gear("hell_armor", "Hell Armor", "armor", [0, 26, 0, 10, 10, 0], 3000)
	_gear("rooster_dress", "Rooster Dress", "armor", [0, 7, 0, 6, 5, 5], 300)
	_gear("dark_armor", "Dark Armor", "armor", [0, 12, 0, 12, 4, 0], 800)
	# shields
	_gear("wooden_shield", "Wooden Shield", "shield", [0, 1, 0, 1, 0, 0], 10)
	_gear("leather_shield", "Leather Shield", "shield", [0, 2, 0, 0, 0, 0], 25)
	_gear("copper_shield", "Copper Shield", "shield", [0, 4, 0, 0, 0, 0], 50)
	_gear("hard_shield", "Hard Shield", "shield", [0, 1, 0, 3, 0, 0], 50)
	_gear("iron_shield", "Iron Shield", "shield", [0, 5, 0, 2, 0, 1], 90)
	_gear("dark_shield", "Dark Shield", "shield", [0, 3, 0, 5, 0, 0], 150)
	_gear("knight_shield", "Knight Shield", "shield", [0, 3, 0, 4, 0, 1], 180)
	_gear("blue_shield", "Blue Shield", "shield", [0, 0, 0, 10, 0, 2], 200)
	_gear("evil_shield", "Evil Shield", "shield", [0, 4, 0, 4, 0, 4], 250)
	_gear("tank_shield", "Tank Shield", "shield", [0, 8, 0, 0, 0, 4], 300)
	_gear("gold_shield", "Gold Shield", "shield", [0, 6, 0, 6, 0, 0], 300)
	_gear("faceguard", "Faceguard", "shield", [0, 3, 0, 2, 0, 0], 60)
	_gear("copper_faceguard", "Copper Faceguard", "shield", [0, 4, 0, 4, 0, 1], 120)
	# rings (two ring slots)
	_gear("silver_ring", "Silver Ring", "ring", [1, 1, 0, 1, 0, 0], 80)
	_gear("gold_ring", "Gold Ring", "ring", [1, 0, 1, 0, 1, 0], 80)
	_gear("jade_ring", "Jade Ring", "ring", [0, 0, 0, 3, 0, 3], 150)
	_gear("ruby_silver_ring", "Ruby Silver Ring", "ring", [0, 1, 0, 5, 0, 0], 200)
	_gear("orb_gold_ring", "Orb Gold Ring", "ring", [0, 0, 1, 0, 5, 0], 200)
	_gear("armor_ring", "Armor Ring I", "ring", [0, 3, 0, 0, 0, 0], 150)
	_gear("armor_ring_2", "Armor Ring II", "ring", [0, 6, 0, 0, 0, 0], 400)
	_gear("armor_ring_3", "Armor Ring III", "ring", [0, 10, 0, 0, 0, 0], 900)
	_gear("armor_ring_4", "Armor Ring IV", "ring", [0, 15, 0, 0, 0, 0], 2000)
	_gear("ring_of_attack", "Ring of Attack", "ring", [8, 0, 0, 0, 0, 0], 2000)
	_gear("ring_of_magic", "Ring of Magic", "ring", [0, 0, 8, 0, 0, 0], 2000)

func _items_misc() -> void:
	_item("survival_book", "Survival Book", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "survival"})
	_item("combo_book_1", "Combo Book I", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "combo1"})
	_item("combo_book_2", "Combo Book II", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "combo2"})
	_item("combo_book_3", "Combo Book III", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "combo3"})
	_item("combo_book_4", "Combo Book IV", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "combo4"})
	_item("combo_book_5", "Combo Book V", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "combo5"})
	_item("combination_scroll", "Combination Scroll", "scroll", 100, "Put it in the scroll slot for +35% success. Used up.")
	_item("silver_key", "Silver Key", "key", 0, "Opens a Silver Chest in Pixel Village.")
	_item("golden_key", "Golden Key", "key", 0, "Opens a Golden Chest in Pixel Village.")
	_item("master_key", "Master Key", "key", 0, "Opens the Master Chest in Pixel Village.")
	_item("survival_token", "Survival Token", "token", 0, "Earned by surviving nights in Survival Grasslands. Trade them with the Miner.")
	_item("green_seeds", "Magic Seeds (Green)", "seed", 20, "Plant in the soil behind the rock wall. Grows in 6 minutes.", {"grow": 360})
	_item("red_seeds", "Magic Seeds (Red)", "seed", 60, "Plant in the soil behind the rock wall. Grows in 1 hour.", {"grow": 3600})
	_item("golden_seeds", "Magic Seeds (Golden)", "seed", 150, "Plant in the soil behind the rock wall. Grows in 3 hours.", {"grow": 10800})
	var eggs := [["green_egg", "Monster Egg (Green)"], ["pink_egg", "Monster Egg (Pink)"], ["purple_egg", "Monster Egg (Purple)"],
		["red_egg", "Monster Egg (Red)"], ["queen_egg", "Queen Egg"], ["king_egg", "King Egg"]]
	for e in eggs:
		_item(e[0], e[1], "egg", 50, "Hatch it in the Incubator in Pixel Village.")
	for p in PETS:
		var d: Dictionary = PETS[p]
		var parts := []
		if d.get("dmg", 0) > 0: parts.append("hits nearby monsters for %d" % d.dmg)
		if d.get("hp", 0) > 0: parts.append("restores %d health" % d.hp)
		if d.get("mp", 0) > 0: parts.append("restores %d mana" % d.mp)
		if d.get("st", 0) > 0: parts.append("restores %d stamina" % d.st)
		_item(p, d.name, "pet", 0, "A pet. Every %d seconds it %s. Equip it in the pet slot." % [d.every, " and ".join(parts)])
	# things you can place
	_item("wood_wall", "Wood Wall", "place", 2, "Blocks monsters. Place it in front of you.", {"hp": 60})
	_item("stone_wall", "Stone Wall", "place", 4, "A stronger wall.", {"hp": 150})
	_item("wooden_spikes", "Wooden Spikes", "place", 4, "Hurts monsters that walk over them.", {"trap": 5})
	_item("work_station", "Work Station", "place", 10, "Lets you use the blacksmith's recipes wherever you place it.")
	_item("campfire", "Campfire", "place", 10, "Slowly heals you while you stand near it.")
	_item("torch", "Torch Stand", "place", 2, "Lights up the night.")

# ---------------------------------------------------------------- pets
var PETS := {
	"pet_snowball": {"name": "Snowball", "every": 12, "dmg": 6, "look": "snowball"},
	"pet_waterball": {"name": "Waterball", "every": 12, "mp": 1, "look": "waterball"},
	"pet_fireball": {"name": "Fireball", "every": 12, "hp": 1, "look": "fireball"},
	"pet_goldball": {"name": "Goldball", "every": 12, "st": 1, "look": "goldball"},
	"pet_trex": {"name": "Little T-Rex", "every": 10, "hp": 1, "look": "trex"},
	"pet_shell": {"name": "Shell Crawler", "every": 10, "dmg": 10, "look": "shell"},
	"pet_chicklet": {"name": "Chicklet", "every": 10, "hp": 1, "mp": 1, "st": 1, "look": "chicklet"},
	"pet_ufo": {"name": "UFO", "every": 8, "dmg": 15, "hp": 1, "mp": 1, "look": "ufo"},
	"pet_phantom": {"name": "Phantom", "every": 6, "dmg": 18, "mp": 1, "st": 1, "look": "phantom"},
	"pet_eye": {"name": "Mrs. Eye", "every": 8, "dmg": 36, "hp": 1, "st": 1, "look": "eyeball"},
	"pet_hand": {"name": "Mr. Hand", "every": 8, "dmg": 36, "hp": 1, "st": 1, "look": "hand"},
}
# what hatches from each egg (equal chance)
var EGG_PETS := {
	"green_egg": ["pet_snowball", "pet_shell"], "pink_egg": ["pet_fireball", "pet_waterball", "pet_goldball"],
	"purple_egg": ["pet_ufo", "pet_phantom"], "red_egg": ["pet_trex", "pet_chicklet"],
	"queen_egg": ["pet_eye"], "king_egg": ["pet_hand"],
}
const HATCH_TIME := 300.0

# ---------------------------------------------------------------- combining
# Put 2 or 3 items in the combination slots. "rate" is the base success chance.
# Having the recipe's book in your bag adds 50%, a Combination Scroll adds 35%.
# A failed or unknown combination uses one of each item and gives Dust.
var RECIPES := [
	# Survival Book
	{"in": ["wood", "branch"], "out": "wood_board", "rate": 95, "book": "survival"},
	{"in": ["rock", "scarab"], "out": "nail", "rate": 95, "book": "survival"},
	{"in": ["wood_board", "nail"], "out": "wooden_spikes", "rate": 90, "book": "survival"},
	{"in": ["wood", "rock"], "out": "wood_wall", "rate": 90, "book": "survival"},
	{"in": ["wood_board", "rock"], "out": "work_station", "rate": 90, "book": "survival"},
	{"in": ["copper_ore", "crystal"], "out": "iron_ore", "rate": -25, "book": "survival"},
	{"in": ["wood", "fire_crystal", "coal"], "out": "torch", "rate": 15, "book": "survival"},
	# Combo Book I
	{"in": ["honey_bug", "herb"], "out": "pretzel", "rate": 5, "book": "combo1"},
	{"in": ["jelly", "bone"], "out": "wooden_axe", "rate": 65, "book": "combo1"},
	{"in": ["wood", "bone"], "out": "wooden_pick", "rate": 65, "book": "combo1"},
	{"in": ["herb", "plant_roots"], "out": "potion", "rate": 45, "book": "combo1"},
	{"in": ["potion", "crystal"], "out": "medium_potion", "rate": 40, "book": "combo1"},
	{"in": ["medium_potion", "fire_bug"], "out": "big_potion", "rate": 35, "book": "combo1"},
	{"in": ["potion", "mana_potion"], "out": "rejuvenate_potion", "rate": 40, "book": "combo1"},
	{"in": ["medium_potion", "medium_mana_potion"], "out": "medium_rejuvenate_potion", "rate": 35, "book": "combo1"},
	{"in": ["big_potion", "big_mana_potion"], "out": "big_rejuvenate_potion", "rate": 30, "book": "combo1"},
	{"in": ["herb", "blue_moon"], "out": "mana_potion", "rate": 65, "book": "combo1"},
	{"in": ["mana_potion", "crystal"], "out": "medium_mana_potion", "rate": 60, "book": "combo1"},
	{"in": ["medium_mana_potion", "fire_bug"], "out": "big_mana_potion", "rate": 55, "book": "combo1"},
	{"in": ["herb", "antidote_herb"], "out": "antidote", "rate": 65, "book": "combo1"},
	{"in": ["bone", "stink_bug"], "out": "fatigue_potion", "rate": 60, "book": "combo1"},
	{"in": ["monster_scale", "branch"], "out": "herb", "rate": 60, "book": "combo1"},
	{"in": ["jelly", "fire_crystal"], "out": "sticky_balls", "rate": 25, "book": "combo1"},
	{"in": ["copper_ore", "wood"], "out": "arrow", "n": 5, "rate": 40, "book": "combo1"},
	# Combo Book II
	{"in": ["honey_bug", "branch", "potion"], "out": "holy_banana", "rate": -10, "book": "combo2"},
	{"in": ["wood_board", "iron_bar", "monster_leather"], "out": "faceguard", "rate": -10, "book": "combo2"},
	{"in": ["apple", "staff_cast", "copper_ore"], "out": "hallow_staff", "rate": -40, "book": "combo2"},
	{"in": ["scarab", "crystal"], "out": "catalyst", "rate": 25, "book": "combo2"},
	{"in": ["honey_bug", "monster_shell"], "out": "crystal", "rate": 40, "book": "combo2"},
	{"in": ["bone", "sticky_balls"], "out": "sticky_bones", "rate": 25, "book": "combo2"},
	{"in": ["monster_hide", "sticky_balls"], "out": "monster_leather", "rate": 25, "book": "combo2"},
	{"in": ["scarab", "fire_crystal"], "out": "fire_bug", "rate": 20, "book": "combo2"},
	{"in": ["scarab", "jelly"], "out": "honey_bug", "rate": 45, "book": "combo2"},
	{"in": ["scarab", "sticky_bones"], "out": "stink_bug", "rate": 30, "book": "combo2"},
	# Combo Book III
	{"in": ["magic_wand", "fire_crystal", "fire_brand"], "out": "fire_staff", "rate": 15, "book": "combo3"},
	{"in": ["healing_staff", "apple", "small_evil_crystal"], "out": "healing_staff_2", "rate": -50, "book": "combo3"},
	{"in": ["fire_crystal", "hero_bug", "glow_blade_blue"], "out": "glow_blade_red", "rate": 15, "book": "combo3"},
	{"in": ["earth_crystal", "hero_bug", "glow_blade_red"], "out": "glow_blade_green", "rate": 15, "book": "combo3"},
	{"in": ["water_crystal", "hero_bug", "glow_blade_red"], "out": "glow_blade_pink", "rate": 15, "book": "combo3"},
	{"in": ["silver_ring", "gold_ring", "apple"], "out": "armor_ring", "rate": 0, "book": "combo3"},
	{"in": ["gold_bar", "iron_bar", "copper_bar"], "out": "pole_axe", "rate": -45, "book": "combo3"},
	{"in": ["plant_roots", "scarab"], "out": "linen", "rate": 25, "book": "combo3"},
	{"in": ["monster_leather", "scarab"], "out": "harden_leather", "rate": 25, "book": "combo3"},
	{"in": ["catalyst", "fire_bug"], "out": "dongle", "rate": 25, "book": "combo3"},
	{"in": ["crystal", "dust"], "out": "dark_crystal", "rate": 35, "book": "combo3"},
	{"in": ["crystal", "old_roots"], "out": "earth_crystal", "rate": 35, "book": "combo3"},
	{"in": ["crystal", "monster_hide"], "out": "fire_crystal", "rate": 35, "book": "combo3"},
	{"in": ["crystal", "blue_moon"], "out": "water_crystal", "rate": 35, "book": "combo3"},
	{"in": ["small_evil_crystal", "crystal", "dark_crystal"], "out": "evil_crystal", "rate": -45, "book": "combo3"},
	{"in": ["silver_bar", "fire_crystal", "catalyst"], "out": "ruby_stone", "rate": -35, "book": "combo3"},
	# Combo Book IV
	{"in": ["healing_staff_2", "living_flame", "evil_crystal"], "out": "healing_staff_3", "rate": -55, "book": "combo4"},
	{"in": ["gold_ring", "big_mana_potion", "catalyst"], "out": "orb_gold_ring", "rate": -5, "book": "combo4"},
	{"in": ["silver_ring", "big_potion", "catalyst"], "out": "ruby_silver_ring", "rate": -5, "book": "combo4"},
	{"in": ["armor_ring", "erbium_bar", "power_bug"], "out": "armor_ring_2", "rate": -35, "book": "combo4"},
	{"in": ["scarab", "iron_bar", "catalyst"], "out": "armor_bug", "rate": -55, "book": "combo4"},
	{"in": ["scarab", "gold_bar", "catalyst"], "out": "power_bug", "rate": -35, "book": "combo4"},
	{"in": ["iron_ore", "honey_bug", "dust"], "out": "gold_ore", "rate": -45, "book": "combo4"},
	{"in": ["iron_ore", "scarab", "dust"], "out": "silver_ore", "rate": -45, "book": "combo4"},
	{"in": ["jelly", "apple", "old_roots"], "out": "rooster_dress", "rate": -40, "book": "combo4"},
	# Combo Book V
	{"in": ["evil_apple", "iron_sword_cast", "evil_bar"], "out": "hell_sword", "rate": -75, "book": "combo5"},
	{"in": ["armor_ring_2", "evil_crystal", "hero_bug"], "out": "armor_ring_3", "rate": -55, "book": "combo5"},
	{"in": ["power_bug", "armor_bug", "catalyst"], "out": "hero_bug", "rate": -65, "book": "combo5"},
	{"in": ["gold_ore", "dust", "stink_bug"], "out": "erbium", "rate": -45, "book": "combo5"},
	{"in": ["moon_blade", "gold_bar", "em_stone"], "out": "moon_blade_2", "rate": -75, "book": "combo5"},
	{"in": ["moon_blade_2", "erbium_bar", "em_stone"], "out": "moon_blade_3", "rate": -75, "book": "combo5"},
	{"in": ["ruby_stone", "em_stone", "power_bug"], "out": "ring_of_attack", "rate": -10, "book": "combo5"},
	{"in": ["ruby_stone", "sapphire_stone", "armor_bug"], "out": "ring_of_magic", "rate": -10, "book": "combo5"},
]
const BOOK_ITEM := {"survival": "survival_book", "combo1": "combo_book_1", "combo2": "combo_book_2",
	"combo3": "combo_book_3", "combo4": "combo_book_4", "combo5": "combo_book_5"}
const BOOK_BONUS := 50
const SCROLL_BONUS := 35

func find_recipe(items: Array) -> Dictionary:
	var a := items.duplicate()
	a.sort()
	for r in RECIPES:
		var b: Array = r.in.duplicate()
		b.sort()
		if a == b:
			return r
	return {}

# ---------------------------------------------------------------- blacksmith
# Crafted by the Smith in Pixel Village (or at a Work Station). Always succeeds.
var SMITH := [
	# tools
	{"out": "copper_axe", "cost": {"copper_bar": 20, "wooden_axe": 1}},
	{"out": "iron_axe", "cost": {"iron_bar": 20, "copper_axe": 1}},
	{"out": "gold_axe", "cost": {"gold_bar": 20, "iron_axe": 1}},
	{"out": "copper_pick", "cost": {"copper_bar": 20, "wooden_pick": 1}},
	{"out": "iron_pick", "cost": {"iron_bar": 20, "copper_pick": 1}},
	{"out": "gold_pick", "cost": {"gold_bar": 20, "iron_pick": 1}},
	{"out": "erbium_pick", "cost": {"erbium_bar": 20, "gold_pick": 1}},
	# weapons
	{"out": "timber_club", "cost": {"wood": 25, "branch": 25, "copper_ore": 15}},
	{"out": "short_blade", "cost": {"copper_ore": 15, "rock": 25}},
	{"out": "gilded_blade", "cost": {"short_blade": 1, "copper_ore": 40, "rock": 25}},
	{"out": "azure_blade", "cost": {"gilded_blade": 1, "scarab": 50, "iron_bar": 15}},
	{"out": "fire_brand", "cost": {"azure_blade": 1, "fire_bug": 35, "fire_crystal": 35}},
	{"out": "violet_edge", "cost": {"azure_blade": 1, "jelly": 50, "stink_bug": 25}},
	{"out": "excalibur", "cost": {"violet_edge": 1, "monster_scale": 75, "monster_shell": 75}},
	{"out": "plunger", "cost": {"jelly": 15, "monster_shell": 5}},
	{"out": "knights_blade", "cost": {"timber_club": 1, "azure_blade": 1, "bone": 75}},
	{"out": "kings_mace", "cost": {"knights_blade": 1, "dongle": 25, "gold_bar": 50}},
	{"out": "holy_knight", "cost": {"kings_mace": 1, "gold_bar": 75, "crystal": 75}},
	{"out": "poison_ivy", "cost": {"excalibur": 1, "gold_bar": 75, "dark_crystal": 75}},
	{"out": "hellfire_blade", "cost": {"excalibur": 1, "gold_bar": 75, "fire_crystal": 75}},
	{"out": "combo_sword", "cost": {"copper_sword_cast": 1, "iron_sword_cast": 1, "gold_sword_cast": 1}},
	{"out": "staff_cast", "cost": {"wood": 50, "branch": 50, "copper_ore": 5}},
	{"out": "magic_wand", "cost": {"wood": 25, "branch": 25, "copper_ore": 25}},
	# helmets
	{"out": "wooden_helmet", "cost": {"wood_board": 25}},
	{"out": "copper_helmet", "cost": {"copper_bar": 25, "armor_bug": 5, "wooden_helmet": 1}},
	{"out": "brass_helmet", "cost": {"iron_bar": 25, "armor_bug": 5, "copper_helmet": 1}},
	{"out": "pumpkin_hat", "cost": {"gold_bar": 25, "armor_bug": 5, "silver_bar": 25}},
	{"out": "fear_helmet_2", "cost": {"dark_bar": 65, "fear_helmet": 1}},
	{"out": "hell_helmet_2", "cost": {"hell_bar": 65, "hell_helmet": 1}},
	{"out": "witch_helmet_2", "cost": {"light_bar": 65, "witch_helmet": 1}},
	# armor
	{"out": "wooden_armor", "cost": {"wood": 50}},
	{"out": "stone_armor", "cost": {"rock": 50, "wooden_armor": 1, "scarab": 50}},
	{"out": "leather_armor", "cost": {"monster_leather": 25, "wooden_armor": 1}},
	{"out": "tough_leather_armor", "cost": {"harden_leather": 25, "leather_armor": 1}},
	{"out": "copper_armor", "cost": {"copper_bar": 45, "stone_armor": 1}},
	{"out": "iron_armor", "cost": {"iron_bar": 45, "copper_armor": 1}},
	{"out": "golden_armor", "cost": {"gold_bar": 45, "copper_armor": 1}},
	{"out": "silver_armor", "cost": {"silver_bar": 45, "copper_armor": 1}},
	{"out": "jelly_armor", "cost": {"sticky_balls": 50, "tough_leather_armor": 1}},
	{"out": "linen_armor", "cost": {"linen": 75, "tough_leather_armor": 1}},
	{"out": "blood_diamond_armor", "cost": {"iron_armor": 1, "silver_bar": 25, "armor_bug": 10}},
	{"out": "chainmail", "cost": {"iron_armor": 1, "iron_bar": 35, "armor_bug": 10}},
	{"out": "golden_knight_armor", "cost": {"golden_armor": 1, "gold_bar": 35, "armor_bug": 10}},
	{"out": "ivory_armor", "cost": {"chainmail": 1, "dark_crystal": 75, "armor_bug": 10}},
	{"out": "scale_armor", "cost": {"linen_armor": 1, "monster_scale": 75, "armor_bug": 10}},
	{"out": "seer_armor", "cost": {"jelly_armor": 1, "monster_shell": 75, "armor_bug": 10}},
	{"out": "jade_armor", "cost": {"ivory_armor": 1, "erbium_bar": 75, "armor_bug": 35}},
	{"out": "sandy_armor", "cost": {"ivory_armor": 1, "erbium_bar": 75, "armor_bug": 35}},
	{"out": "sage_armor", "cost": {"seer_armor": 1, "erbium_bar": 75, "armor_bug": 75}},
	{"out": "lavish_armor", "cost": {"scale_armor": 1, "erbium_bar": 75, "armor_bug": 35}},
	{"out": "hell_armor", "cost": {"living_flame": 99, "legendary_roots": 99, "hero_bug": 50}},
	# shields
	{"out": "wooden_shield", "cost": {"wood": 40, "branch": 10}},
	{"out": "leather_shield", "cost": {"monster_leather": 15, "scarab": 10}},
	{"out": "copper_shield", "cost": {"copper_ore": 25, "leather_shield": 1}},
	{"out": "hard_shield", "cost": {"harden_leather": 10, "rock": 25, "leather_shield": 1}},
	{"out": "iron_shield", "cost": {"hard_shield": 1, "iron_bar": 15}},
	{"out": "dark_shield", "cost": {"wooden_shield": 1, "dark_crystal": 75, "iron_bar": 25}},
	{"out": "knight_shield", "cost": {"dark_shield": 1, "fire_bug": 35}},
	{"out": "blue_shield", "cost": {"iron_shield": 1, "water_crystal": 50}},
	{"out": "evil_shield", "cost": {"dark_shield": 1, "stink_bug": 50}},
	{"out": "tank_shield", "cost": {"knight_shield": 1, "iron_bar": 35}},
	{"out": "gold_shield", "cost": {"iron_shield": 1, "gold_bar": 35}},
	{"out": "copper_faceguard", "cost": {"faceguard": 1, "copper_bar": 25}},
]

# ---------------------------------------------------------------- furnaces
# Hold the main ingredient and use a furnace. Times are in seconds.
var SMELT := [
	{"out": "copper_bar", "main": "copper_ore", "cost": {"copper_ore": 5, "coal": 1}, "time": 20},
	{"out": "iron_bar", "main": "iron_ore", "cost": {"iron_ore": 5, "coal": 1}, "time": 45},
	{"out": "silver_bar", "main": "silver_ore", "cost": {"silver_ore": 5, "coal": 1}, "time": 75},
	{"out": "gold_bar", "main": "gold_ore", "cost": {"gold_ore": 5, "coal": 1}, "time": 120},
	{"out": "erbium_bar", "main": "erbium", "cost": {"erbium": 5, "coal": 1}, "time": 1200},
	{"out": "volcanic_bar", "main": "volcanic_ore", "cost": {"volcanic_ore": 5, "coal": 1}, "time": 7200},
	{"out": "light_bar", "main": "water_crystal", "cost": {"water_crystal": 5, "silver_bar": 5, "coal": 1}, "time": 2700},
	{"out": "dark_bar", "main": "dark_crystal", "cost": {"dark_crystal": 5, "gold_bar": 5, "coal": 1}, "time": 2700},
	{"out": "hell_bar", "main": "earth_crystal", "cost": {"earth_crystal": 5, "erbium_bar": 5, "coal": 1}, "time": 2700},
	{"out": "evil_bar", "main": "green_egg", "cost": {"green_egg": 1, "light_bar": 1, "dark_bar": 1, "hell_bar": 1, "coal": 1}, "time": 3600},
	{"out": "living_flame", "main": "fire_crystal", "cost": {"fire_crystal": 5, "fire_bug": 1}, "time": 3600},
]
const FURNACES := 5

# ---------------------------------------------------------------- harvesting
# hits: how many hits it takes with the weakest tool that works (min tier).
# Each better tool tier takes one hit less (two for erbium), never below 2.
var NODES := {
	"tree": {"tool": "axe", "min": 1, "hits": 8, "drops": [["wood", 0.95, 1, 3], ["branch", 0.7, 1, 2]], "color": "3e9a3a"},
	"blue_tree": {"tool": "axe", "min": 4, "hits": 5, "drops": [["blue_wood", 1.0, 1, 2], ["scarab", 0.3, 1, 1]], "color": "7b4fb8"},
	"plant_yellow": {"tool": "pick", "min": 1, "hits": 8, "drops": [["herb", 0.8, 1, 2], ["plant_roots", 0.4, 1, 1], ["old_roots", 0.12, 1, 1], ["legendary_roots", 0.01, 1, 1], ["antidote_herb", 0.25, 1, 1]], "color": "f2cf5b"},
	"plant_pink": {"tool": "pick", "min": 1, "hits": 8, "drops": [["herb", 0.8, 1, 2], ["plant_roots", 0.4, 1, 1], ["old_roots", 0.12, 1, 1], ["blue_moon", 0.25, 1, 1], ["antidote_herb", 0.25, 1, 1]], "color": "e06a9a"},
	"pot": {"tool": "pick", "min": 1, "hits": 8, "drops": [["scarab", 0.4, 1, 2], ["stink_bug", 0.25, 1, 1], ["honey_bug", 0.25, 1, 1], ["fire_bug", 0.2, 1, 1], ["power_bug", 0.02, 1, 1], ["armor_bug", 0.02, 1, 1], ["hero_bug", 0.004, 1, 1], ["short_blade", 0.01, 1, 1]], "color": "c8865a"},
	"vase": {"tool": "pick", "min": 1, "hits": 8, "drops": [["scarab", 0.4, 1, 2], ["stink_bug", 0.3, 1, 1], ["honey_bug", 0.3, 1, 1], ["fire_bug", 0.3, 1, 1], ["power_bug", 0.03, 1, 1], ["armor_bug", 0.03, 1, 1], ["hero_bug", 0.006, 1, 1]], "color": "7b4fb8"},
	"stone": {"tool": "pick", "min": 1, "hits": 8, "drops": [["rock", 1.0, 1, 3], ["scarab", 0.25, 1, 1], ["coal", 0.3, 1, 1]], "color": "8a9099"},
	"copper": {"tool": "pick", "min": 1, "hits": 8, "drops": [["copper_ore", 1.0, 1, 2], ["stink_bug", 0.15, 1, 1], ["coal", 0.35, 1, 1]], "color": "e8864a"},
	"iron": {"tool": "pick", "min": 2, "hits": 7, "drops": [["iron_ore", 1.0, 1, 2], ["fire_bug", 0.15, 1, 1], ["coal", 0.35, 1, 1]], "color": "8ab0d8"},
	"silver": {"tool": "pick", "min": 2, "hits": 7, "drops": [["silver_ore", 1.0, 1, 2], ["coal", 0.35, 1, 1], ["honey_bug", 0.15, 1, 1]], "color": "e3ebf5"},
	"gold": {"tool": "pick", "min": 3, "hits": 6, "drops": [["gold_ore", 1.0, 1, 2], ["coal", 0.35, 1, 1], ["hero_bug", 0.01, 1, 1]], "color": "f2cf5b"},
	"erbium_rock": {"tool": "pick", "min": 4, "hits": 10, "step": 2, "drops": [["erbium", 1.0, 1, 1], ["gold_ore", 0.3, 1, 1], ["silver_ore", 0.3, 1, 1], ["coal", 0.3, 1, 1]], "color": "c83a6a"},
	"ice_rock": {"tool": "pick", "min": 3, "hits": 6, "drops": [["water_crystal", 0.3, 1, 1], ["silver_ore", 0.6, 1, 1], ["crystal", 0.4, 1, 1]], "color": "a6e6f2"},
	"rock_wall": {"tool": "pick", "min": 4, "hits": 30, "step": 0, "drops": [], "color": "8a9099", "wall": true},
}

func hits_needed(node: String, tier: int) -> int:
	var d: Dictionary = NODES[node]
	if tier < int(d.min):
		return -1
	var step: int = d.get("step", 1)
	return maxi(2, int(d.hits) - (tier - int(d.min)) * step)

# ---------------------------------------------------------------- monsters
# ai: walk (constant speed), accel (gains speed in one direction), charge (rushes,
# then stops for a few seconds), fly (flies at increasing speed), wizard (keeps
# distance and shoots), stone (moves up and down, can't be hurt)
# jump: jumps when close. through: passes through walls. heavy: no knockback.
# status: [effect, chance] applied on hit. drops: [item, chance, min, max]
var MOBS := {}

func _mob(id: String, name: String, look: String, hp: Array, dmg: int, ai: String, drops: Array, extra: Dictionary = {}) -> void:
	var d := {"name": name, "look": look, "hp": hp, "dmg": dmg, "ai": ai, "drops": drops, "speed": 34.0}
	d.merge(extra, true)
	MOBS[id] = d

func _ready() -> void:
	_build_mobs()

func _build_mobs() -> void:
	# Grasslands. Slime drops are from the wiki (about 20% each, 5.5% blade).
	_mob("slime", "Slime", "slime_pink", [13, 13], 1, "walk", [["bone", 0.2, 1, 1], ["jelly", 0.2, 1, 1], ["scarab", 0.2, 1, 1], ["snowball", 0.2, 1, 1], ["short_blade", 0.055, 1, 1], ["herb", 0.1, 1, 1]], {"speed": 30, "hop": true})
	_mob("wisp", "Flame Wisp", "wisp", [15, 15], 1, "fly", [["blue_moon", 0.12, 1, 1], ["crystal", 0.1, 1, 1], ["fire_crystal", 0.05, 1, 1], ["monster_hide", 0.15, 1, 1], ["wooden_armor", 0.02, 1, 1], ["wooden_helmet", 0.02, 1, 1]], {"speed": 40})
	_mob("mummy", "Mummy", "mummy", [45, 45], 3, "charge", [["bone", 0.25, 1, 1], ["blue_moon", 0.1, 1, 1], ["dark_crystal", 0.04, 1, 1], ["monster_hide", 0.15, 1, 1], ["wooden_helmet", 0.02, 1, 1]], {"speed": 30, "charge_wait": 3.0})
	_mob("shell", "Shell Crawler", "shell", [50, 50], 2, "accel", [["bone", 0.2, 1, 1], ["monster_shell", 0.25, 1, 1], ["monster_scale", 0.25, 1, 1], ["monster_horn", 0.1, 1, 1]], {"speed": 32})
	_mob("octopus", "Octopus", "octopus", [65, 65], 5, "accel", [["monster_horn", 0.2, 1, 1], ["herb", 0.2, 1, 1], ["monster_scale", 0.2, 1, 1], ["green_egg", 0.01, 1, 1]], {"jump": true})
	_mob("crusher", "Crusher Stone", "crusher", [999999, 999999], 1, "stone", [], {"invulnerable": true})
	_mob("trex", "T-Rex", "trex", [450, 450], 7, "charge", [["antidote", 0.15, 1, 1], ["silver_key", 0.03, 1, 1], ["old_roots", 0.1, 1, 1], ["red_egg", 0.01, 1, 1]], {"jump": true, "crit": 0.1, "speed": 36})
	_mob("dark_trex", "Dark T-Rex", "dark_trex", [1050, 1050], 9, "charge", [["herb", 0.3, 1, 2], ["mana_potion", 0.15, 1, 1], ["potion", 0.15, 1, 1]], {"jump": true, "crit": 0.1, "speed": 36, "coins": [20, 60]})
	# Darklands
	_mob("dark_slime", "Dark Slime", "slime_dark", [125, 150], 7, "walk", [["herb", 0.3, 1, 1], ["jelly", 0.15, 1, 1]], {"jump": true, "status": ["poison", 0.1]})
	_mob("mantis", "Mantis", "mantis", [118, 183], 4, "accel", [["antidote_herb", 0.25, 1, 1], ["stink_bug", 0.25, 1, 1]], {"jump": true, "fast_hits": true})
	_mob("zombie", "Zombie", "zombie", [75, 75], 5, "charge", [["plant_roots", 0.3, 1, 1]], {"jump": true, "status": ["fatigue", 0.1]})
	_mob("ufo", "UFO", "ufo", [65, 65], 15, "fly", [["potion", 0.15, 1, 1], ["antidote_herb", 0.2, 1, 1], ["purple_egg", 0.008, 1, 1]], {"crit": 0.1, "speed": 44})
	_mob("worm", "Worm", "worm", [300, 500], 17, "walk", [["mana_potion", 0.2, 1, 1], ["antidote_herb", 0.2, 1, 1]], {"crit": 0.1, "speed": 22, "status": ["poison", 0.15]})
	_mob("hand", "Giant Hand", "hand", [2214, 2214], 8, "accel", [["apple", 0.08, 1, 1], ["combo_book_3", 0.01, 1, 1], ["combo_book_4", 0.005, 1, 1], ["green_egg", 0.03, 1, 1], ["red_egg", 0.03, 1, 1], ["purple_egg", 0.02, 1, 1], ["knights_blade", 0.02, 1, 1], ["glow_blade_green", 0.01, 1, 1], ["combination_scroll", 0.05, 1, 1], ["silver_key", 0.08, 1, 1], ["golden_key", 0.03, 1, 1], ["legendary_roots", 0.03, 1, 1], ["bone", 0.4, 1, 3], ["sticky_bones", 0.15, 1, 1], ["dongle", 0.08, 1, 1], ["crystal", 0.3, 1, 2]], {"jump": true, "big_jump": true, "crit": 0.1, "speed": 38, "coins": [40, 120]})
	# Hell
	_mob("wizard", "Wizard", "wizard", [700, 800], 17, "wizard", [["crystal", 0.25, 1, 1], ["fire_crystal", 0.08, 1, 1], ["water_crystal", 0.08, 1, 1], ["earth_crystal", 0.08, 1, 1], ["dark_crystal", 0.08, 1, 1], ["potion", 0.12, 1, 1], ["mana_potion", 0.12, 1, 1]], {"speed": 24, "shoots": true})
	_mob("shadow", "Shadow", "shadow", [700, 1000], 27, "fly", [["dark_crystal", 0.1, 1, 1], ["small_evil_crystal", 0.03, 1, 1]], {"status": ["poison", 0.15]})
	_mob("eyeball", "Eyeball", "eyeball", [1800, 2000], 46, "accel", [["dark_crystal", 0.15, 1, 1], ["small_evil_crystal", 0.05, 1, 1]], {"jump": true, "crit": 0.1, "status": ["poison", 0.2]})
	_mob("phantom", "Phantom", "phantom", [1500, 1500], 42, "fly", [["small_evil_crystal", 0.06, 1, 1], ["purple_egg", 0.01, 1, 1]], {"through": true, "status": ["slow", 0.3]})
	_mob("king", "Eye King", "king", [10000, 10000], 29, "charge", [["pole_axe", 0.06, 1, 1], ["combo_book_3", 0.05, 1, 1], ["combo_book_4", 0.03, 1, 1], ["combo_book_5", 0.01, 1, 1], ["evil_apple", 0.03, 1, 1], ["silver_key", 0.25, 1, 1], ["golden_key", 0.12, 1, 1], ["king_egg", 0.03, 1, 1], ["golden_long_sword", 0.03, 1, 1], ["golden_armor", 0.04, 1, 1], ["combination_scroll", 0.15, 1, 1]], {"jump": true, "heavy": true, "boss": true, "speed": 30, "coins": [300, 600]})
	_mob("queen", "Eye Queen", "queen", [20000, 20000], 53, "charge", [["combo_book_3", 0.06, 1, 1], ["combo_book_4", 0.04, 1, 1], ["combo_book_5", 0.02, 1, 1], ["queen_egg", 0.05, 1, 1], ["armor_bug", 0.15, 1, 2], ["power_bug", 0.15, 1, 2], ["hero_bug", 0.03, 1, 1], ["evil_apple", 0.05, 1, 1], ["silver_key", 0.3, 1, 1], ["golden_key", 0.15, 1, 1], ["master_key", 0.03, 1, 1], ["green_seeds", 0.1, 1, 1], ["red_seeds", 0.05, 1, 1], ["golden_seeds", 0.02, 1, 1], ["fear_helmet", 0.03, 1, 1], ["hell_helmet", 0.03, 1, 1], ["witch_helmet", 0.03, 1, 1]], {"jump": true, "heavy": true, "boss": true, "speed": 32, "coins": [600, 1200]})
	# Ice Cavern
	_mob("tornado", "Tornado", "tornado", [8000, 8400], 57, "accel", [["erbium", 0.15, 1, 1], ["volcanic_ore", 0.01, 1, 1]], {"jump": true})
	_mob("tidal", "Tidal Spirit", "tidal", [4000, 4400], 81, "accel", [["queen_egg", 0.005, 1, 1], ["water_crystal", 0.2, 1, 1], ["antidote_herb", 0.2, 1, 1], ["potion", 0.15, 1, 1]], {"jump": true})
	_mob("ice_bat", "Ice Bat", "ice_bat", [2900, 2900], 57, "fly", [["purple_egg", 0.01, 1, 1], ["erbium", 0.1, 1, 1], ["potion", 0.15, 1, 1], ["monster_horn", 0.2, 1, 1]], {"launch": true, "speed": 50, "status": ["cold", 0.2]})
	_mob("cloud", "Storm Cloud", "cloud", [3000, 3000], 61, "fly", [["medium_potion", 0.12, 1, 1], ["water_crystal", 0.1, 1, 1]], {"speed": 36})
	_mob("butterfly", "Butterfly", "butterfly", [4200, 4200], 146, "fly", [["volcanic_ore", 0.01, 1, 1], ["erbium", 0.12, 1, 1], ["silver_ore", 0.2, 1, 1], ["gold_ore", 0.15, 1, 1]], {"speed": 46})
	_mob("empress", "Butterfly Empress", "empress", [72500, 72500], 141, "accel", [["em_stone", 0.06, 1, 1], ["ruby_stone", 0.06, 1, 1], ["sapphire_stone", 0.06, 1, 1], ["volcanic_ore", 0.15, 1, 2], ["herb", 0.5, 1, 3], ["monster_horn", 0.5, 1, 3], ["potion", 0.4, 1, 2], ["moon_blade", 0.05, 1, 1], ["moon_blade_2", 0.02, 1, 1], ["moon_blade_3", 0.01, 1, 1], ["master_key", 0.05, 1, 1]], {"jump": true, "heavy": true, "boss": true, "speed": 34, "coins": [2000, 4000]})
	# Ghost Arena
	_mob("ghost_1", "Wailing Ghost", "ghost_1", [2100, 2100], 68, "fly", [], {"through": true, "status": ["slow", 0.2]})
	_mob("ghost_2", "Grave Ghost", "ghost_2", [4100, 4100], 88, "fly", [], {"through": true, "status": ["slow", 0.2]})
	_mob("ghost_lord", "Ghost Lord", "ghost_lord", [85000, 85000], 135, "fly", [["spectre_hood", 0.05, 1, 1], ["silver_key", 0.4, 1, 1], ["armor_ring", 0.08, 1, 1], ["armor_ring_2", 0.05, 1, 1], ["armor_ring_3", 0.03, 1, 1], ["armor_ring_4", 0.01, 1, 1], ["ring_of_attack", 0.02, 1, 1], ["devil_spike", 0.04, 1, 1], ["twin_sun", 0.05, 1, 1], ["living_flame", 0.1, 1, 1], ["combo_book_3", 0.06, 1, 1], ["combo_book_4", 0.04, 1, 1], ["combo_book_5", 0.02, 1, 1], ["combination_scroll", 0.2, 1, 1], ["dark_shield", 0.05, 1, 1], ["volcanic_ore", 0.15, 1, 1], ["healing_staff", 0.05, 1, 1], ["queen_egg", 0.03, 1, 1]], {"through": true, "heavy": true, "boss": true, "speed": 40, "coins": [3000, 6000]})
	# Survival Grasslands only
	_mob("bat", "Giant Bat", "bat", [1300, 1300], 17, "fly", [["monster_hide", 0.2, 1, 1]], {"speed": 50})
	_mob("small_stone", "Small Stone", "small_stone", [1200, 1200], 14, "walk", [["rock", 0.5, 1, 3]], {"jump": true})
	_mob("farmland", "Farmland Creature", "farmland", [700, 700], 15, "walk", [["herb", 0.4, 1, 2], ["plant_roots", 0.3, 1, 1]], {})
	_mob("small_king", "Small King", "king", [1000, 1000], 17, "charge", [["silver_key", 0.05, 1, 1]], {"jump": true, "heavy": true, "scale": 0.6})
	_mob("golden_orb", "Golden Orb", "golden_orb", [800, 800], 14, "wizard", [["gold_ore", 0.2, 1, 1]], {"shoots": true, "speed": 20})

# ---------------------------------------------------------------- worlds
# kind: town, explore, arena, survival
# mobs: [mob, weight, hp multiplier, damage multiplier]
var WORLDS := {
	"town": {"name": "Pixel Village", "kind": "town", "theme": "grass"},
	"grass_1": {"name": "Grasslands 1", "kind": "explore", "theme": "grass", "next": "grass_2", "count": 34,
		"mobs": [["slime", 6], ["wisp", 3], ["mummy", 2], ["shell", 2]],
		"nodes": [["tree", 7], ["stone", 4], ["copper", 3], ["plant_yellow", 2], ["plant_pink", 2], ["pot", 2]]},
	"grass_2": {"name": "Grasslands 2", "kind": "explore", "theme": "grass", "next": "grass_3", "count": 40,
		"mobs": [["slime", 5], ["wisp", 3], ["mummy", 2], ["shell", 2], ["octopus", 3], ["crusher", 1]],
		"nodes": [["tree", 6], ["stone", 4], ["copper", 3], ["iron", 2], ["plant_yellow", 2], ["plant_pink", 2], ["pot", 2]]},
	"grass_3": {"name": "Grasslands 3", "kind": "explore", "theme": "grass", "count": 44, "chest": true,
		"mobs": [["slime", 3], ["octopus", 2], ["trex", 2], ["dark_trex", 1], ["dark_slime", 2], ["mantis", 2], ["zombie", 2]],
		"nodes": [["tree", 6], ["stone", 3], ["copper", 3], ["iron", 2], ["gold", 1], ["plant_yellow", 2], ["plant_pink", 2], ["pot", 2]]},
	"dark_1": {"name": "Darklands 1", "kind": "explore", "theme": "dark", "next": "dark_2", "count": 40,
		"mobs": [["dark_slime", 5], ["mantis", 4], ["zombie", 3], ["ufo", 3], ["worm", 2], ["trex", 1], ["hand", 1]],
		"nodes": [["tree", 4], ["blue_tree", 2], ["copper", 3], ["silver", 2], ["iron", 2], ["gold", 2], ["erbium_rock", 1]]},
	"dark_2": {"name": "Darklands 2", "kind": "explore", "theme": "dark", "count": 46, "chest": true, "mult": 1.5,
		"mobs": [["dark_slime", 4], ["mantis", 4], ["zombie", 3], ["ufo", 3], ["worm", 3], ["trex", 1], ["hand", 2]],
		"nodes": [["tree", 3], ["blue_tree", 2], ["copper", 2], ["silver", 3], ["iron", 2], ["gold", 2], ["erbium_rock", 2]]},
	"hell_1": {"name": "Hell 1", "kind": "explore", "theme": "hell", "next": "hell_2", "count": 44, "chest": true,
		"mobs": [["mantis", 4, 2.0], ["worm", 3], ["wizard", 3], ["shadow", 3], ["eyeball", 2], ["hand", 2, 0.45, 4.75], ["king", 0.3], ["queen", 0.2]],
		"nodes": [["vase", 3], ["iron", 2], ["silver", 2], ["gold", 2], ["erbium_rock", 3]]},
	"hell_2": {"name": "Hell 2", "kind": "explore", "theme": "hell", "count": 46, "chest": true,
		"mobs": [["eyeball", 3], ["shadow", 3, 1.6, 1.7], ["phantom", 3], ["hand", 3, 0.9, 6.5], ["queen", 0.4], ["dark_trex", 0.3, 47.6, 6.3]],
		"nodes": [["vase", 3], ["iron", 2], ["silver", 2], ["gold", 3], ["erbium_rock", 4]]},
	"ice_cavern": {"name": "Ice Cavern", "kind": "explore", "theme": "ice", "count": 40,
		"mobs": [["tornado", 2], ["tidal", 3], ["ice_bat", 3], ["cloud", 3], ["butterfly", 2], ["queen", 0.3, 1.5, 1.55], ["empress", 0.15]],
		"nodes": [["ice_rock", 4], ["silver", 2], ["gold", 2], ["erbium_rock", 2]]},
	"grass_arena": {"name": "Grasslands Arena", "kind": "arena", "theme": "grass", "cap": 8,
		"mobs": [["slime", 4, 1.23], ["wisp", 2, 1.67], ["mummy", 2], ["shell", 2]],
		"bosses": [["trex", 2.22, 1.0], ["hand", 0.565, 1.0]],
		"boss_drops": [["combo_book_2", 0.06, 1, 1], ["combo_book_3", 0.02, 1, 1], ["iron_sword_cast", 0.1, 1, 1], ["silver_key", 0.25, 1, 1], ["small_mana_potion", 0.3, 1, 2], ["small_potion", 0.3, 1, 2], ["wooden_helmet", 0.1, 1, 1], ["moon_blade", 0.02, 1, 1], ["weak_bow", 0.06, 1, 1], ["bow", 0.04, 1, 1], ["faceguard", 0.05, 1, 1], ["crystal", 0.3, 1, 2], ["jade_ring", 0.02, 1, 1], ["big_rejuvenate_potion", 0.05, 1, 1]]},
	"dark_arena": {"name": "Darklands Arena", "kind": "arena", "theme": "dark", "cap": 9,
		"mobs": [["dark_slime", 3], ["mantis", 3], ["zombie", 2], ["ufo", 2], ["worm", 2], ["octopus", 2, 2.0, 1.5]],
		"bosses": [["dark_trex", 4.76, 1.78], ["hand", 2.26, 1.75], ["king", 0.5, 0.52]], "bosses_pick": 2,
		"boss_drops": [["small_potion", 0.3, 1, 2], ["silver_key", 0.3, 1, 1], ["golden_key", 0.08, 1, 1], ["excalibur", 0.03, 1, 1], ["combination_scroll", 0.1, 1, 1], ["combo_book_3", 0.04, 1, 1], ["big_rejuvenate_potion", 0.06, 1, 1], ["bow", 0.05, 1, 1], ["copper_sword_cast", 0.08, 1, 1], ["gold_sword_cast", 0.06, 1, 1], ["green_seeds", 0.1, 1, 1], ["jade_ring", 0.04, 1, 1], ["armor_ring", 0.04, 1, 1], ["crystal", 0.3, 1, 3], ["pole_axe", 0.04, 1, 1], ["healing_staff", 0.03, 1, 1], ["rooster_dress", 0.03, 1, 1], ["copper_helmet", 0.06, 1, 1], ["golden_armor", 0.03, 1, 1], ["magic_wand", 0.05, 1, 1]]},
	"hell_arena": {"name": "Hell Arena", "kind": "arena", "theme": "hell", "cap": 9,
		"mobs": [["mantis", 3, 2.0, 1.5], ["worm", 2, 1.2, 1.3], ["wizard", 2, 1.2, 1.3], ["shadow", 2, 1.2, 1.3], ["eyeball", 1, 1.1, 1.3], ["hand", 2, 0.5, 5.5]],
		"bosses": [["king", 2.0, 1.48], ["queen", 1.25, 1.47]],
		"boss_drops": [["fire_crystal", 0.2, 1, 2], ["earth_crystal", 0.2, 1, 2], ["dark_crystal", 0.2, 1, 2], ["medium_mana_potion", 0.2, 1, 1], ["rejuvenate_potion", 0.2, 1, 1], ["healing_staff_2", 0.02, 1, 1], ["combo_book_4", 0.05, 1, 1], ["combo_book_5", 0.02, 1, 1], ["master_key", 0.06, 1, 1], ["sapphire_stone", 0.03, 1, 1], ["moon_blade_3", 0.01, 1, 1], ["fear_helmet", 0.05, 1, 1], ["hell_helmet", 0.05, 1, 1], ["dark_shield", 0.06, 1, 1], ["dark_armor", 0.04, 1, 1], ["jelly_armor", 0.05, 1, 1], ["golden_armor", 0.05, 1, 1], ["sandy_armor", 0.02, 1, 1], ["knight_shield", 0.1, 1, 1]]},
	"dream_arena": {"name": "Dream Arena", "kind": "arena", "theme": "dream", "cap": 10,
		"mobs": [["mantis", 2], ["shadow", 2, 1.0, 1.7], ["worm", 2, 1.0, 1.6], ["eyeball", 1, 1.0, 1.5], ["wizard", 2, 1.0, 1.5], ["hand", 2, 0.45, 8.0]],
		"bosses": [["king", 2.0, 1.48], ["queen", 1.25, 1.47], ["empress", 0.93, 0.74]], "bosses_pick": 2,
		"boss_drops": [["silver_key", 0.3, 1, 1], ["golden_key", 0.15, 1, 1], ["master_key", 0.06, 1, 1], ["glow_blade_blue", 0.04, 1, 1], ["bow", 0.05, 1, 1], ["big_rejuvenate_potion", 0.1, 1, 1], ["devil_spike", 0.02, 1, 1], ["volcanic_ore", 0.1, 1, 1], ["em_stone", 0.04, 1, 1], ["ruby_stone", 0.04, 1, 1], ["sapphire_stone", 0.04, 1, 1]]},
	"ghost_arena": {"name": "Ghost Arena", "kind": "arena", "theme": "ghost", "cap": 8,
		"mobs": [["ghost_1", 3], ["ghost_2", 2]],
		"bosses": [["ghost_lord", 1.0, 1.0]],
		"boss_drops": []},
	"survival": {"name": "Survival Grasslands", "kind": "survival", "theme": "grass", "needs": "survival_access"},
}
# The Portal Keeper offers these. Deeper levels are reached through portals inside each world.
const WORLD_MENU := [["Exploration", ["grass_1", "dark_1", "hell_1", "ice_cavern"]],
	["Arena", ["grass_arena", "dark_arena", "hell_arena", "dream_arena", "ghost_arena"]],
	["Survival", ["survival"]]]

# Survival Grasslands: which monsters can show up from which day.
var SURVIVAL_WAVES := [
	[1, ["slime", "slime", "slime", "wisp", "shell", "mummy"]],
	[5, ["dark_slime", "mantis", "zombie", "ufo", "phantom"]],
	[14, ["small_king"]],
	[16, ["wizard", "golden_orb", "trex", "bat", "small_stone"]],
	[21, ["farmland"]],
	[25, ["eyeball", "shadow"]],
]
const SURVIVAL_BOSSES := ["dark_trex", "hand", "king", "queen"]

func survival_tokens(day: int) -> int:
	if day <= 1: return 0
	if day <= 4: return 1
	if day <= 10: return 2
	if day <= 28: return 3
	if day <= 40: return 4
	return 5

# ---------------------------------------------------------------- village
var NPCS := {
	"keeper": {"name": "Portal Keeper", "look": "keeper", "talk": "Where to? Pick a world and I'll open a portal."},
	"gruff": {"name": "Gruff", "look": "gruff", "talk": "Out here by the rock wall it's quiet. Bring me proof you can build and I'll show you the survival fields."},
	"mira": {"name": "Mira", "look": "mira", "talk": "I always need things collected. Help me and I'll make it worth your while!"},
	"warden": {"name": "Furnace Warden", "look": "warden", "talk": "Nobody gets to the furnaces on an empty stomach. Mine, I mean."},
	"smith": {"name": "Smith", "look": "smith", "talk": "Bring me materials and I'll forge anything on my list. No luck needed."},
	"merchant": {"name": "Merchant", "look": "merchant", "talk": "Buying and selling, best prices in the village!"},
	"tools": {"name": "Tool Seller", "look": "tools", "talk": "Lost your tools? I've got spares."},
	"miner": {"name": "Miner", "look": "miner", "talk": "Survival Tokens! I'll trade seeds and keys for them."},
}

# Quests are done in order per villager.
var QUESTS := [
	{"id": "gruff_1", "npc": "gruff", "need": {"wood_wall": 1}, "reward": {"survival_book": 1}, "unlock": "survival_access",
		"text": "Make a Wood Wall (Wood + Rock in the combination slots) and give it to me. You'll get the Survival Book and the way into Survival Grasslands."},
	{"id": "warden_1", "npc": "warden", "need": {"pretzel": 1}, "reward": {}, "unlock": "furnaces",
		"text": "Bring me a Pretzel (Honey Bug + Herb, much easier with Combo Book I) and I'll open the gate to the furnaces."},
	{"id": "mira_1", "npc": "mira", "need": {"jelly": 10}, "reward": {"combo_book_1": 1}, "text": "Could you bring me 10 Jellies? Slimes in the Grasslands drop them."},
	{"id": "mira_2", "npc": "mira", "need": {"jelly": 50}, "reward": {"combo_book_2": 1}, "text": "More jelly! 50 this time."},
	{"id": "mira_3", "npc": "mira", "need": {"copper_bar": 5}, "reward": {"gilded_blade": 1}, "text": "Bring me 5 Copper Bars from the furnace."},
	{"id": "mira_4", "npc": "mira", "need": {"iron_bar": 5}, "reward": {"azure_blade": 1}, "text": "Now 5 Iron Bars, please."},
	{"id": "mira_5", "npc": "mira", "need": {"nail": 50}, "reward": {"silver_key": 2}, "text": "I need 50 Nails."},
	{"id": "mira_6", "npc": "mira", "need": {"gilded_blade": 1}, "reward": {"silver_key": 2, "combination_scroll": 1}, "text": "Could I have a Gilded Blade?"},
	{"id": "mira_7", "npc": "mira", "need": {"catalyst": 10}, "reward": {"golden_key": 1}, "text": "10 Catalysts, please."},
	{"id": "mira_8", "npc": "mira", "need": {"crystal": 10}, "reward": {"brass_helmet": 1}, "text": "Bring me 10 Crystals."},
	{"id": "mira_9", "npc": "mira", "need": {"scarab": 99}, "reward": {"combination_scroll": 2}, "text": "99 Scarabs. I know, I know."},
	{"id": "mira_10", "npc": "mira", "need": {"stink_bug": 99}, "reward": {"golden_key": 1}, "text": "99 Stink Bugs. Hold your nose."},
	{"id": "mira_11", "npc": "mira", "need": {"honey_bug": 99}, "reward": {"combination_scroll": 3}, "text": "99 Honey Bugs."},
	{"id": "mira_12", "npc": "mira", "need": {"fire_bug": 99}, "reward": {"golden_key": 2}, "text": "99 Fire Bugs."},
	{"id": "mira_13", "npc": "mira", "need": {"gold_shield": 1}, "reward": {"master_key": 1}, "text": "I'd love a Gold Shield."},
	{"id": "mira_14", "npc": "mira", "need": {"dust": 999}, "reward": {"master_key": 2}, "text": "Dust! I need 999 Dust."},
	{"id": "mira_15", "npc": "mira", "need": {"silver_bar": 25}, "reward": {"master_key": 1}, "text": "25 Silver Bars."},
	{"id": "mira_16", "npc": "mira", "need": {"jelly": 99}, "reward": {"pumpkin_hat": 1}, "text": "99 Jellies, for old times' sake."},
	{"id": "mira_17", "npc": "mira", "need": {"living_flame": 10}, "reward": {"pink_egg": 1, "red_egg": 1}, "text": "10 Living Flames from the furnace."},
	{"id": "mira_18", "npc": "mira", "need": {"fire_bug": 99}, "reward": {"combo_book_3": 1}, "text": "99 more Fire Bugs and you'll get Combo Book III."},
	{"id": "mira_19", "npc": "mira", "need": {"gold_bar": 50}, "reward": {"master_key": 3}, "text": "50 Gold Bars."},
	{"id": "mira_20", "npc": "mira", "need": {"erbium_bar": 50}, "reward": {"master_key": 3, "combo_book_4": 1}, "text": "50 Erbium Bars."},
	{"id": "mira_21", "npc": "mira", "need": {"dark_bar": 50}, "reward": {"master_key": 3}, "text": "50 Dark Bars."},
	{"id": "mira_22", "npc": "mira", "need": {"light_bar": 50}, "reward": {"master_key": 3}, "text": "50 Light Bars."},
	{"id": "mira_23", "npc": "mira", "need": {"hell_bar": 50}, "reward": {"master_key": 3, "combo_book_5": 1}, "text": "50 Hell Bars."},
]

# Shops: what each villager sells, and for how many coins (or tokens).
var SHOPS := {
	"merchant": {"title": "Merchant", "sells": [["combo_book_2", 1500], ["small_potion", 15], ["small_mana_potion", 15], ["antidote", 40], ["fatigue_potion", 40], ["arrow", 2], ["wood_wall", 10], ["campfire", 60], ["green_egg", 10000]], "buys": true},
	"tools": {"title": "Tool Seller", "sells": [["wooden_axe", 250], ["wooden_pick", 250], ["copper_ore", 250]], "buys": true},
	"gruff": {"title": "Gruff's Wares", "sells": [["wood", 5], ["rock", 5], ["branch", 5]], "buys": false},
	"miner": {"title": "Miner (Survival Tokens)", "currency": "survival_token", "sells": [["green_seeds", 15], ["red_seeds", 45], ["silver_key", 10], ["golden_key", 35], ["master_key", 100]], "buys": false},
}

# ---------------------------------------------------------------- chests
var CHESTS := {
	"silver": {"name": "Silver Chest", "key": "silver_key", "rolls": 2, "loot": [
		["wood", 5, 10], ["rock", 5, 10], ["branch", 5, 10], ["coal", 4, 8], ["scarab", 4, 8], ["stink_bug", 3, 5], ["fire_bug", 3, 5], ["honey_bug", 3, 5],
		["power_bug", 1, 1, 0.3], ["armor_bug", 1, 1, 0.3], ["hero_bug", 1, 1, 0.05], ["crystal", 2, 4], ["fire_crystal", 1, 2], ["water_crystal", 1, 2],
		["earth_crystal", 1, 2], ["dark_crystal", 1, 2], ["copper_ore", 5, 10], ["copper_bar", 1, 3], ["iron_ore", 3, 6], ["iron_bar", 1, 3],
		["silver_ore", 2, 5], ["silver_bar", 1, 2], ["gold_ore", 1, 3], ["gold_bar", 1, 1], ["erbium", 1, 1, 0.3], ["catalyst", 1, 3], ["herb", 3, 6],
		["dongle", 1, 2], ["antidote_herb", 2, 4], ["blue_moon", 2, 4], ["monster_hide", 2, 4], ["monster_shell", 2, 4], ["monster_scale", 2, 4],
		["monster_leather", 1, 3], ["harden_leather", 1, 1, 0.3], ["monster_horn", 2, 4], ["bone", 3, 6], ["linen", 1, 3], ["sticky_bones", 1, 3],
		["sticky_balls", 1, 3], ["plant_roots", 2, 4], ["old_roots", 1, 2], ["legendary_roots", 1, 1, 0.05], ["green_seeds", 1, 1, 0.3], ["red_seeds", 1, 1, 0.1],
		["small_potion", 1, 3], ["potion", 1, 2], ["medium_potion", 1, 1], ["small_mana_potion", 1, 3], ["mana_potion", 1, 2], ["antidote", 1, 2], ["fatigue_potion", 1, 2],
		["timber_club", 1, 1], ["short_blade", 1, 1], ["gilded_blade", 1, 1], ["azure_blade", 1, 1, 0.6], ["fire_brand", 1, 1, 0.4], ["violet_edge", 1, 1, 0.3],
		["plunger", 1, 1], ["knights_blade", 1, 1, 0.15], ["glow_blade_blue", 1, 1, 0.1], ["long_sword", 1, 1, 0.3], ["moon_blade", 1, 1, 0.1],
		["sword_cast", 1, 1], ["copper_sword_cast", 1, 1], ["iron_sword_cast", 1, 1], ["gold_sword_cast", 1, 1], ["weak_bow", 1, 1], ["bow", 1, 1, 0.5],
		["staff_cast", 1, 1], ["magic_wand", 1, 1], ["wooden_helmet", 1, 1], ["copper_helmet", 1, 1, 0.3], ["wooden_armor", 1, 1], ["stone_armor", 1, 1],
		["leather_armor", 1, 1], ["copper_armor", 1, 1], ["iron_armor", 1, 1, 0.5], ["wooden_shield", 1, 1], ["leather_shield", 1, 1], ["copper_shield", 1, 1],
		["hard_shield", 1, 1], ["faceguard", 1, 1], ["silver_ring", 1, 1, 0.3], ["gold_ring", 1, 1, 0.3], ["armor_ring", 1, 1, 0.2],
		["combination_scroll", 1, 1, 0.3], ["silver_key", 1, 1, 0.3], ["golden_key", 1, 1, 0.1], ["survival_token", 1, 3], ["green_egg", 1, 1, 0.1]]},
	"golden": {"name": "Golden Chest", "key": "golden_key", "rolls": 2, "loot": [
		["timber_club", 1, 1], ["gilded_blade", 1, 1], ["azure_blade", 1, 1], ["fire_brand", 1, 1], ["violet_edge", 1, 1], ["excalibur", 1, 1],
		["bow", 1, 1], ["long_sword", 1, 1], ["plunger", 1, 1], ["magic_wand", 1, 1], ["fire_staff", 1, 1, 0.5], ["knights_blade", 1, 1],
		["kings_mace", 1, 1, 0.3], ["moon_blade", 1, 1, 0.3], ["poison_ivy", 1, 1, 0.3], ["glow_blade_red", 1, 1], ["glow_blade_blue", 1, 1],
		["golden_long_sword", 1, 1, 0.5], ["pole_axe", 1, 1], ["leather_shield", 1, 1], ["copper_shield", 1, 1], ["knight_shield", 1, 1], ["hard_shield", 1, 1],
		["dark_shield", 1, 1], ["blue_shield", 1, 1], ["faceguard", 1, 1], ["copper_faceguard", 1, 1], ["tank_shield", 1, 1, 0.3], ["iron_shield", 1, 1, 0.3],
		["stone_armor", 1, 1], ["silver_armor", 1, 1], ["copper_armor", 1, 1], ["linen_armor", 1, 1], ["leather_armor", 1, 1], ["jelly_armor", 1, 1],
		["iron_armor", 1, 1], ["golden_armor", 1, 1], ["tough_leather_armor", 1, 1, 0.3], ["silver_ring", 1, 1], ["gold_ring", 1, 1], ["armor_ring", 1, 1],
		["jade_ring", 1, 1], ["holy_banana", 1, 2], ["evil_shield", 1, 1, 0.3], ["pink_egg", 1, 1], ["green_egg", 1, 1], ["staff_cast", 1, 1],
		["healing_staff", 1, 1, 0.3], ["healing_staff_2", 1, 1, 0.1], ["combination_scroll", 1, 2]]},
	"master": {"name": "Master Chest", "key": "master_key", "rolls": 1, "loot": [
		["pole_axe", 1, 1], ["combo_sword", 1, 1], ["moon_blade", 1, 1], ["moon_blade_2", 1, 1], ["moon_blade_3", 1, 1], ["twin_sun", 1, 1],
		["devil_spike", 1, 1], ["golden_long_sword", 1, 1], ["copper_faceguard", 1, 1], ["tank_shield", 1, 1], ["iron_armor", 1, 1], ["golden_armor", 1, 1],
		["gold_shield", 1, 1], ["blue_shield", 1, 1], ["armor_ring_2", 1, 1], ["armor_ring_3", 1, 1], ["jade_ring", 1, 1], ["blood_diamond_armor", 1, 1],
		["seer_armor", 1, 1], ["ivory_armor", 1, 1], ["scale_armor", 1, 1], ["copper_helmet", 1, 1], ["brass_helmet", 1, 1], ["fear_helmet", 1, 1],
		["fear_helmet_2", 1, 1], ["hell_helmet", 1, 1], ["hell_helmet_2", 1, 1], ["witch_helmet", 1, 1], ["witch_helmet_2", 1, 1], ["golden_seeds", 1, 1],
		["healing_staff", 1, 1], ["healing_staff_2", 1, 1], ["healing_staff_3", 1, 1], ["sapphire_stone", 1, 1], ["em_stone", 1, 1], ["green_egg", 1, 1], ["gold_sword_cast", 1, 1]]},
}
var REWARD_CHEST := "silver" # chests found inside worlds use the silver loot table

var SEED_LOOT := {
	"green_seeds": [["green_seeds", 1, 2], ["big_potion", 1, 1], ["big_rejuvenate_potion", 1, 1], ["silver_key", 1, 1], ["golden_key", 1, 1, 0.3], ["survival_token", 1, 3], ["silver_ore", 3, 6]],
	"red_seeds": [["red_seeds", 1, 1], ["green_seeds", 1, 3], ["golden_key", 1, 1], ["silver_key", 1, 2], ["gold_ore", 3, 6], ["erbium", 1, 3], ["master_key", 1, 1, 0.2]],
	"golden_seeds": [["golden_seeds", 1, 1, 0.3], ["red_seeds", 1, 2], ["master_key", 1, 1], ["golden_key", 1, 2], ["erbium", 3, 6], ["volcanic_ore", 1, 1, 0.3]],
}

func pick_loot(table: Array) -> Array:
	# entries: [item, min, max, weight=1]
	var total := 0.0
	for e in table:
		total += e[3] if e.size() > 3 else 1.0
	var r := randf() * total
	for e in table:
		r -= e[3] if e.size() > 3 else 1.0
		if r <= 0:
			return [e[0], randi_range(e[1], e[2])]
	return [table[0][0], 1]
