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
		["living_flame", "Fira", 60, "A living flame. Smelted from fire crystals."],
		["copper_ore", "Copper Ore", 3, "Smelt 5 with 1 coal for a copper bar."], ["iron_ore", "Iron Ore", 5, "Smelt 5 with 1 coal for an iron bar."],
		["silver_ore", "Silver Ore", 8, "Smelt 5 with 1 coal for a silver bar."], ["gold_ore", "Gold Ore", 12, "Smelt 5 with 1 coal for a gold bar."],
		["erbium", "Erbium", 40, "A rare ore. Smelt 5 with 1 coal for an erbium bar."], ["volcanic_ore", "Volcanic Ore", 400, "Extremely rare ore."],
		["copper_bar", "Copper Bar", 18, "Smelted copper."], ["iron_bar", "Iron Bar", 30, "Smelted iron."],
		["silver_bar", "Silver Bar", 45, "Smelted silver."], ["gold_bar", "Gold Bar", 70, "Smelted gold."],
		["erbium_bar", "Erbium Bar", 220, "Smelted erbium."], ["volcanic_bar", "Volcanic Bar", 2200, "Smelted volcanic ore."],
		["light_bar", "Light Bar", 400, "Water crystals and silver, smelted."], ["dark_bar", "Dark Bar", 450, "Dark crystals and gold, smelted."],
		["hell_bar", "Hell Bar", 900, "Earth crystals and erbium, smelted."], ["evil_bar", "Evil Bar", 2000, "The strongest common metal."],
		["em_stone", "Em Stone", 500, "A green gem stone."], ["dark_stone", "Dark Stone", 1500, "A black stone. Used for Hell, Emperor, Skull and Dragon gear."],
		["sky_stone", "Sky Stone", 4000, "A pale blue stone. Used for the Emperor Dress IV."],
		["dragon_spine", "Dragon Spine", 4000, "A spine from a dragon. Used for the Nightmare Dress II."], ["ruby_stone", "Ruby Stone", 500, "A red gem stone."],
		["sapphire_stone", "Sapphire Stone", 500, "A blue gem stone."],
		# from the later worlds
		["blue_blade", "Blue Blade", 800, "A blue blade from Modina Ruins. Used for Modina gear."],
		["nightmare_ore", "Nightmare Ore", 600, "Only found in Nightmare Valley. Smelt into Nightmare Ingots."],
		["nightmare_ingot", "Nightmare Ingot", 3000, "Smelted nightmare ore, for nightmare gear."],
		["dark_heart", "Dark Heart", 5000, "Extremely rare. Nightmare Valley's demons sometimes drop one."],
		["forbidden_stone", "Forbidden Stone", 8000, "Only found in the Forbidden City."],
		["fortune_nugget", "Fortune Nugget", 1500, "A lucky golden nugget from the Fortune Boss."],
		["honey", "Honey", 300, "Only found in Fruit Loop."],
		["eggency", "Eggency", 500, "Only found in Eggcellence."],
		["topaz_stone", "Topaz Stone", 500, "A yellow gem stone. The Butterfly Boss and the Tomb of Makara drop it."],
		["blue_board", "Blue Board", 60, "A plank of blue wood. Used for the Robo Mask II and the Icy Bow."],
		["mooncake", "Mooncake", 200, "A Mid-Autumn treat. Used for the Moon Hats."],
		["forbidden_bar", "Forbidden Bar", 9000, "Blue Wood, Evil, Volcanic and Nightmare metal smelted together."],
		["dragon_handle", "Dragon Handle", 6000, "The grip of a Dragon Blade."],
		["sandnite_ore", "Sandnite Ore", 600, "Only found in the Tomb of Makara. Smelt 5 with 1 coal for a Sandnite Bar."],
		["sandnite_bar", "Sandnite Bar", 3000, "Smelted sandnite."],
		["bone_of_makara", "Bone of Makara", 8000, "Makara drops it."],
		["skin_of_makara", "Skin of Makara", 8000, "Makara drops it."],
		["treasure_of_makara", "Treasure of Makara", 12000, "Makara drops it."],
		["missing_page", "Missing Page", 2000, "A page torn out of a combo book. With Combo Book Z it makes Combo Book ZX."],
		["missing_page_u", "Missing Page U", 5000, "With Combo Book Z it makes Combo Book U."],
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
		if r[0] == "pretzel": desc += "The GateKeeper would love one."
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
		["timber_club", "Wood King", 5, 0.75, 18, true, 15, "A heavy wooden club."],
		["short_blade", "Gradius", 5, 0.45, 16, true, 20, "Small but quick. Slimes sometimes drop it. Used to craft Golden Night."],
		["gilded_blade", "Golden Night", 6, 0.5, 18, true, 30, "A short blade with a gold finish."],
		["azure_blade", "Blue Night", 9, 0.55, 20, true, 45, "A blue steel blade."],
		["fire_brand", "Fire Brand", 13, 0.55, 20, true, 45, "Warm to hold."],
		["violet_edge", "Purple Mist", 19, 0.55, 20, true, 60, "A purple-glinting sword."],
		["plunger", "Plunger", 4, 0.4, 16, true, 10, "Wielded only by the master poopers."],
		["unlawful", "Unlawful", 13, 0.55, 18, true, 45, "A plunger made into something worse."],
		["knights_blade", "Knights Mantle", 15, 0.6, 22, true, 70, "A proper knight's sword."],
		["kings_mace", "Kings Mace", 27, 0.55, 22, true, 120, "Heavy and royal."],
		["excalibur", "Excalibur", 23, 0.9, 24, true, 120, "Slow, but long and strong."],
		["poison_ivy", "Poison Ivy", 31, 0.6, 22, true, 160, "A thorny green blade."],
		["holy_knight", "Holy Knight", 34, 0.5, 22, true, 200, "Shines with holy light."],
		["hellfire_blade", "Fires Devil", 38, 0.6, 24, true, 220, "Burns everything it touches."],
		["combo_sword", "Combo Sword", 14, 0.65, 18, true, 80, "Three casts forged into one."],
		["moon_blade", "Moon Blade", 17, 0.65, 22, true, 150, "A crescent-shaped blade."],
		["moon_blade_2", "Moon Blade II", 34, 0.65, 22, true, 300, "Sharper under moonlight."],
		["moon_blade_3", "Moon Blade III", 73, 0.65, 24, true, 600, "Brighter than the moon."],
		["glow_blade_blue", "Blue Fluorescent", 19, 0.5, 22, true, 150, "Emits a glowing blue light."],
		["glow_blade_red", "Red Fluorescent", 19, 0.5, 22, true, 150, "Emits a glowing red light."],
		["glow_blade_green", "Green Fluorescent", 21, 0.5, 22, true, 170, "Emits a glowing green light."],
		["glow_blade_pink", "Pink Fluorescent", 21, 0.5, 22, true, 170, "Emits a glowing pink light."],
		["long_sword", "Long Sword", 10, 0.65, 28, true, 150, "Long reach."],
		["golden_long_sword", "Golden Long Sword", 17, 0.6, 28, true, 300, "Long reach, golden edge."],
		["pole_axe", "Pole Axe", 15, 1.0, 26, true, 25, "A slow, heavy axe on a pole. Also chops trees.", {"axe": 2}],
		["sky_pole_axe", "Sky Pole Axe", 28, 1.0, 26, true, 60, "The next Pole Axe. Also chops trees.", {"axe": 3}],
		["volcan_axe", "Volcan Axe", 86, 1.0, 22, true, 300, "Slow, with strong knockback. Also chops trees, blue ones too.", {"axe": 4}],
		["twin_sun", "Twin Sun", 14, 0.55, 22, true, 300, "Two suns on one hilt."],
		["devil_spike", "Devil Spike", 45, 0.9, 26, true, 500, "A wicked spiked weapon."],
		["hell_sword", "Hell Sword", 105, 0.55, 26, true, 1500, "Forged from evil itself."],
		["wall_hammer", "Wall Hammer", 9, 0.55, 30, true, 0, "Used to destroy massive walls..? A Survival Grasslands reward."],
		["tsurugi", "Tsurugi", 33, 0.55, 22, true, 0, "The Ninja's sword. The ninjas under Pixel Town can sharpen it."],
		["tsurugi_2", "Tsurugi II", 67, 0.55, 22, true, 0, "Sharpened by Nini."],
		["tsurugi_3", "Tsurugi III", 128, 0.55, 24, true, 0, "Sharpened by Nana."],
		["tsurugi_4", "Tsurugi IV", 178, 0.55, 24, true, 0, "Sharpened by Nina."],
		# the later worlds
		["modina_1", "Modina", 32, 0.6, 24, false, 300, "One of Modina's four swords."],
		["modina_2", "Modina II", 58, 0.6, 24, false, 600, "One of Modina's four swords."],
		["modina_3", "Modina III", 85, 0.6, 24, false, 1200, "One of Modina's four swords."],
		["modina_4", "Modina IV", 124, 0.6, 26, false, 2400, "One of Modina's four swords."],
		["long_lance", "Long Lance", 52, 0.7, 32, false, 400, "Golden Slugs carry these around."],
		["long_lance_2", "Long Lance II", 69, 0.6, 32, false, 800, "A longer, sharper lance."],
		["long_lance_3", "Long Lance III", 110, 0.55, 34, false, 1600, "The best of the lances."],
		["hell_spike", "Hell Spike", 119, 0.5, 24, false, 2000, "Fast, no knockback, and it mines like a gold pickaxe.", {"pick": 4}],
		["hell_spike_2", "Hell Spike II", 139, 0.5, 24, false, 4000, "Mines volcanic rock too.", {"pick": 5}],
		["hell_spike_3", "Hell Spike III", 159, 0.5, 24, false, 8000, "The last Hell Spike.", {"pick": 5}],
		["hazard_wipe", "Hazard Wipe", 110, 0.65, 26, true, 1500, "Modina sometimes drops it."],
		["nightmare_long_sword", "Nightmare Long Sword", 128, 0.6, 30, true, 2500, "Long reach, nightmare edge."],
		["nightmare_blade", "Nightmare Blade", 136, 0.55, 26, true, 3000, "Doom guards it in Nightmare Valley."],
		["nightmare_blade_2", "Nightmare Blade II", 167, 0.55, 26, true, 6000, "Sharpened with Dark Hearts."],
		["nightmare_blade_3", "Nightmare Blade III", 196, 0.55, 28, true, 12000, "The darkest blade."],
		["santa_blade", "Santa Blade", 191, 0.65, 26, true, 5000, "Evil Santa's blade."],
		# the rest of the wiki's weapons table (attack and speed from the wiki)
		["yellow_fluorescent", "Yellow Fluorescent", 33, 0.5, 22, true, 300, "The strongest Fluorescent."],
		["sapphire_long_sword", "Sapphire Long Sword", 26, 0.55, 28, true, 600, "Long reach, sapphire edge."],
		["blood_long_sword", "Blood Long Sword", 52, 0.5, 28, true, 1200, "Long reach, blood-red edge."],
		["refined_combo_sword", "Refined Combo Sword", 33, 0.65, 18, true, 300, "The Combo Sword, refined."],
		["ice_sword", "Ice Sword", 45, 0.65, 16, true, 600, "Short, but cold."],
		["ice_devil_sword", "Ice Devil Sword", 115, 0.5, 22, true, 3000, "A frozen devil's blade."],
		["heavy_ice_devil_sword", "Heavy Ice Devil Sword", 225, 0.9, 26, true, 6000, "Slow and enormous."],
		["heavy_ice_devil_sword_2", "Heavy Ice Devil Sword II", 266, 0.9, 26, true, 12000, "Slower, bigger, colder."],
		["volcan_sword", "Volcan Sword", 53, 0.65, 22, true, 1500, "A blade forged in lava."],
		["volcan_longsword", "Volcan LongSword", 98, 0.6, 28, true, 3000, "The Volcan Sword, longer."],
		["volcan_longsword_u", "Volcan LongSword U", 98, 0.55, 28, true, 6000, "Rewritten by Combo Book U: faster."],
		["nightmare_long_sword_u", "Nightmare Long Sword U", 125, 0.55, 30, true, 6000, "Rewritten by Combo Book U: faster."],
		["hell_sword_2", "Hell Sword II", 116, 0.55, 26, true, 3000, "The Hell Sword, sharpened with a Dark Stone."],
		["hell_sword_u", "Hell Sword U", 116, 0.5, 26, true, 6000, "Rewritten by Combo Book U: faster."],
		["evil_axe", "Evil Axe", 200, 1.0, 24, true, 4000, "Slow, with strong knockback. Also chops trees, blue ones too.", {"axe": 4}],
		["evil_axe_2", "Evil Axe II", 215, 1.0, 24, true, 8000, "Slow, with strong knockback. Also chops trees, blue ones too.", {"axe": 4}],
		["evil_axe_u", "Evil Axe U", 218, 1.0, 24, true, 12000, "Rewritten by Combo Book U. Also chops trees.", {"axe": 4}],
		["hell_pole_axe", "Hell Pole Axe", 67, 1.0, 26, true, 600, "The next Sky Pole Axe. Also chops trees.", {"axe": 4}],
		["rainbow_sword", "Rainbow Sword", 145, 0.5, 24, true, 6000, "Every color at once."],
		["rainbow_sword_u", "Rainbow Sword U", 151, 0.5, 24, true, 12000, "Rewritten by Combo Book U."],
		["twin_sun_2", "Twin Sun II", 30, 0.55, 22, true, 600, "Two brighter suns."],
		["twin_sun_3", "Twin Sun III", 65, 0.55, 22, true, 1200, "Two blazing suns."],
		["twin_sun_4", "Twin Sun IV", 160, 0.55, 24, true, 4000, "Two suns at full strength."],
		["twin_sun_u", "Twin Sun U", 160, 0.5, 24, true, 8000, "Rewritten by Combo Book U: faster."],
		["devil_spike_2", "Devil Spike II", 90, 0.8, 26, true, 1500, "A wickeder spike."],
		["devil_spike_3", "Devil Spike III", 200, 0.7, 26, true, 5000, "The wickedest spike."],
		["devil_spike_u", "Devil Spike U", 200, 0.65, 26, true, 9000, "Rewritten by Combo Book U: faster."],
		["modina_u", "Modina U", 124, 0.55, 26, false, 5000, "Rewritten by Combo Book U: faster."],
		["rolva", "Rolva", 37, 0.5, 18, true, 300, "Short reach, quick hits. Hands sometimes drop it."],
		["devilween", "Devilween", 175, 0.5, 24, false, 100, "One of the best weapons there is."],
		["nightmare_blade_4", "Nightmare Blade IV", 204, 0.55, 28, true, 20000, "Darker still, with Makara's bones in it."],
		["moon_blade_4", "Moon Blade IV", 109, 0.65, 24, true, 1200, "Mid Autumn Edition."],
		["moon_blade_5", "Moon Blade V", 121, 0.65, 24, true, 2400, "Mid Autumn Edition."],
		["dark_moon_blade", "Dark Moon Blade", 135, 0.6, 24, true, 5000, "A moon blade with a Forbidden Stone in it."],
		["dark_moon_blade_u", "Dark Moon Blade U", 135, 0.55, 24, true, 9000, "Rewritten by Combo Book U: faster."],
		["moonclipse", "Moonclipse", 23, 0.65, 22, true, 300, "Mid Autumn Edition."],
		["moonclipse_2", "Moonclipse II", 40, 0.65, 22, true, 600, "Mid Autumn Edition."],
		["moonclipse_3", "Moonclipse III", 83, 0.65, 24, true, 1200, "Mid Autumn Edition."],
		["moonclipse_4", "Moonclipse IV", 115, 0.65, 24, true, 2400, "Mid Autumn Edition."],
		["moonclipse_5", "Moonclipse V", 122, 0.65, 24, true, 4800, "Mid Autumn Edition."],
		["candy_stick_red", "Candy Stick (Red)", 38, 0.55, 22, true, 300, "Merry Christmas!"],
		["candy_stick_green", "Candy Stick (Green)", 38, 0.55, 22, true, 300, "Merry Christmas!"],
		["giant_candy", "Giant Candy", 123, 0.55, 26, false, 3000, "Three candies in one."],
		["giant_snow_ball", "Giant Snow Ball", 16, 0.7, 20, true, 200, "Merry Christmas!"],
		["firecracker_blade", "Firecracker Blade", 17, 0.6, 22, true, 200, "Goes off with a bang."],
		["firecracker_blade_2", "Firecracker Blade II", 83, 0.55, 22, true, 2000, "A bigger bang."],
		["ninja_star", "Ninja Star", 29, 0.55, 16, true, 400, "A star-shaped blade."],
		["tsurugi_5", "Tsurugi V", 188, 0.55, 24, true, 0, "Sharpened by the Ninja Master."],
		["chocolate_sword", "Chocolate Sword", 105, 0.55, 22, true, 2000, "Don't eat it."],
		["red_dream_sword", "Red Dream Sword", 120, 0.65, 24, true, 3000, "Evil Santa sometimes drops it."],
		["blade_of_emperor", "Blade of Emperor", 135, 0.65, 26, false, 5000, "Makara sometimes drops it."],
		["evil_shadow_blade", "Evil Shadow Blade", 172, 0.75, 26, true, 6000, "Slow and heavy."],
		["evil_shadow_blade_u", "Evil Shadow Blade U", 172, 0.7, 26, true, 9000, "Rewritten by Combo Book U: faster."],
		["red_moon_soul_blade", "Red moon Soul Blade", 160, 0.7, 26, true, 6000, "A red moon's soul."],
		["red_moon_soul_blade_u", "Red moon Soul Blade U", 160, 0.65, 26, true, 9000, "Rewritten by Combo Book U: faster."],
		["frost_moon_blade", "Frost Moon Blade", 149, 0.65, 24, true, 6000, "A frozen moon."],
		["frost_moon_blade_u", "Frost Moon Blade U", 149, 0.6, 24, true, 9000, "Rewritten by Combo Book U: faster."],
		["shadow_moon_blade", "Shadow Moon Blade", 137, 0.6, 24, true, 6000, "A moon in shadow."],
		["shadow_moon_blade_u", "Shadow Moon Blade U", 137, 0.55, 24, true, 9000, "Rewritten by Combo Book U: faster."],
		["blood_moon_soul_blade", "Blood Moon Soul Blade", 125, 0.55, 24, true, 6000, "A blood moon's soul."],
		["blood_moon_soul_blade_u", "Blood Moon Soul Blade U", 125, 0.5, 24, true, 9000, "Rewritten by Combo Book U: faster."],
		["pumpkin_saber_a", "Pumpkin Saber A", 25, 0.7, 22, true, 300, "Happy Halloween!"],
		["pumpkin_saber_b", "Pumpkin Saber B", 50, 0.7, 22, true, 600, "Happy Halloween!"],
		["pumpkin_saber_c", "Pumpkin Saber C", 75, 0.7, 24, true, 1200, "Happy Halloween!"],
		["pumpkin_saber", "Pumpkin Saber", 150, 0.7, 24, true, 4000, "Happy Halloween!"],
		["christmas_tree", "Christmas Tree", 21, 0.55, 22, true, 300, "Merry Christmas!"],
		["christmas_tree_2", "Christmas Tree II", 42, 0.55, 22, true, 600, "Merry Christmas!"],
		["christmas_tree_3", "Christmas Tree III", 73, 0.55, 24, true, 1200, "Merry Christmas!"],
		["christmas_tree_4", "Christmas Tree IV", 124, 0.55, 24, true, 3000, "Merry Christmas!"],
		["ultimate_tree", "Ultimate Tree", 66, 0.65, 24, true, 2000, "A Christmas Tree, made ultimate."],
		["dragon_blade", "Dragon Blade", 77, 0.6, 26, true, 3000, "A blade on a Dragon Handle."],
		["dragon_blade_2", "Dragon Blade II", 123, 0.6, 26, true, 6000, "A sharper Dragon Blade."],
		["dragon_blade_3", "Dragon Blade III", 212, 0.6, 28, true, 12000, "The Dragon Blade, with Makara's treasure in it."],
		["king_carrot", "King Carrot", 34, 0.6, 22, true, 400, "Happy Easter!"],
		["crazy_carrot", "Crazy Carrot", 68, 0.55, 22, true, 1200, "Happy Easter!"],
		["popstick", "Popstick", 55, 0.5, 20, true, 500, "A popsicle on a stick."],
		["chocolate_pops", "Chocolate Pops", 76, 0.5, 20, true, 1000, "A chocolate popsicle."],
		["red_bean_pops", "Red Bean Pops", 99, 0.5, 20, true, 2000, "A red bean popsicle."],
		["rocket_pops", "Rocket Pops", 123, 0.5, 20, true, 3000, "A rocket popsicle."],
		["rainbow_pops", "Rainbow Pops", 131, 0.5, 20, true, 4000, "A rainbow popsicle."],
		["sun_extractor", "Sun Extractor", 82, 0.5, 22, true, 2000, "Pulls the heat out of the sun."],
		["moon_knifes", "Moon Knifes", 148, 0.55, 22, true, 5000, "Two moon-shaped knives."],
		["moon_edge", "Moon Edge", 140, 0.5, 22, true, 5000, "The edge of the moon."],
		["ultimate_santa_blade", "Ultimate Santa Blade", 241, 0.65, 26, true, 15000, "Evil Santa's blade, made ultimate."],
		["ultimate_candy", "Ultimate Candy", 186, 0.65, 26, true, 10000, "A Giant Candy, made ultimate."],
	]
	for r in w:
		var extra := {"dmg": r[2], "spd": r[3], "reach": r[4], "kb": r[5]}
		if r.size() > 8:
			extra.merge(r[8])
		_item(r[0], r[1], "weapon", r[6], r[7], extra)
	# magic, uses mana
	_item("magic_wand", "Magic Wand", "staff", 25, "Shoots a magic bolt.", {"dmg": 3, "spd": 1.0, "mana_cost": 1, "color": "a77ee0"})
	_item("staff_cast", "Staff Cast", "staff", 10, "A plain staff. Shoots a weak bolt.", {"dmg": 2, "spd": 0.75, "mana_cost": 1, "color": "c8b89a"})
	_item("fire_staff", "Fire Staff", "staff", 120, "Shoots fireballs. Uses 2 mana.", {"dmg": 18, "spd": 0.75, "mana_cost": 2, "color": "f2a33a"})
	_item("hallow_staff", "Hallow Staff", "staff", 80, "Shoots ghostly bolts. Uses 2 mana.", {"dmg": 21, "spd": 1.0, "mana_cost": 2, "color": "8affc8"})
	_item("blue_staff", "Blue Staff", "staff", 200, "Uses mana.", {"dmg": 21, "spd": 0.75, "mana_cost": 2, "color": "6b8ff0"})
	_item("golden_staff", "Golden Staff", "staff", 400, "Uses mana.", {"dmg": 25, "spd": 0.75, "mana_cost": 2, "color": "f2cf5b"})
	_item("candy_staff", "Candy Staff", "staff", 300, "Merry Christmas! Uses mana.", {"dmg": 21, "spd": 0.75, "mana_cost": 2, "color": "6bc8f0"})
	_item("holy_staff", "Holy Staff", "staff", 1500, "Uses mana.", {"dmg": 51, "spd": 0.75, "mana_cost": 3, "color": "f2efe6"})
	_item("ruby_staff", "Ruby Staff", "staff", 3000, "Uses 4 mana.", {"dmg": 84, "spd": 1.0, "mana_cost": 4, "color": "d8433a"})
	_item("ruby_staff_2", "Ruby Staff II", "staff", 6000, "Uses 6 mana.", {"dmg": 144, "spd": 1.0, "mana_cost": 6, "color": "ff6a5a"})
	_item("sapphire_staff", "Sapphire Staff", "staff", 2500, "Uses 3 mana.", {"dmg": 65, "spd": 1.0, "mana_cost": 3, "color": "3b5dc9"})
	_item("pistol", "Pistol", "staff", 40, "Old looking range weapon. Needs no mana.", {"dmg": 4, "spd": 0.75, "mana_cost": 0, "color": "f2cf5b"})
	_item("laser_gun", "Laser Gun", "staff", 150, "Laser firing device, origin unknown. Needs no mana.", {"dmg": 7, "spd": 0.6, "mana_cost": 0, "color": "f06a5a"})
	_item("green_laser_gun", "Green Laser Gun", "staff", 300, "Laser firing device, origin unknown. Needs no mana.", {"dmg": 12, "spd": 0.75, "mana_cost": 0, "color": "7cf06a"})
	_item("blue_laser_gun", "Blue Laser Gun", "staff", 500, "Laser firing device, origin unknown. Needs no mana.", {"dmg": 17, "spd": 0.75, "mana_cost": 0, "color": "6bc8f0"})
	# healing staffs heal everyone near you (wiki numbers)
	for h in [["healing_staff", "Healing Staff", 1, 5, 80], ["healing_staff_2", "Healing Staff II", 2, 10, 200], ["healing_staff_3", "Healing Staff III", 2, 15, 400],
			["healing_staff_4", "Healing Staff IV", 3, 22, 800], ["healing_staff_5", "Healing Staff V", 3, 26, 1600], ["healing_staff_6", "Healing Staff VI", 4, 31, 3200],
			["lucky_special", "Lucky Special", 3, 31, 3200]]:
		_item(h[0], h[1], "staff", h[4], "Uses %d mana to heal you for %d." % [h[2], h[3]], {"heal": h[3], "spd": 1.0, "mana_cost": h[2], "color": "5cbf3f"})
	# the Iron Bot's fist fires bolts and uses mana (wiki numbers)
	_item("iron_fist", "Iron Fist", "staff", 0, "The Iron Bot's fist. Uses 1 mana. The robots under Pixel Town can upgrade it.", {"dmg": 39, "spd": 0.55, "mana_cost": 1, "color": "f2a33a"})
	_item("iron_fist_2", "Iron Fist II", "staff", 0, "Upgraded by FC 9912. Uses 2 mana.", {"dmg": 81, "spd": 0.55, "mana_cost": 2, "color": "f2a33a"})
	_item("iron_fist_3", "Iron Fist III", "staff", 0, "Upgraded by TT 1001. Uses 3 mana.", {"dmg": 137, "spd": 0.55, "mana_cost": 3, "color": "f2cf5b"})
	_item("iron_fist_4", "Iron Fist IV", "staff", 0, "Upgraded by 2219 OOP. Uses 5 mana.", {"dmg": 231, "spd": 0.55, "mana_cost": 5, "color": "ff6a3a"})
	_item("iron_fist_5", "Iron Fist V", "staff", 0, "Upgraded by the Robot Master. Uses 5 mana.", {"dmg": 262, "spd": 0.55, "mana_cost": 5, "color": "e3ebf5"})
	# ranged, uses arrows
	_item("weak_bow", "Weak Bow", "bow", 15, "Uses arrows.", {"dmg": 13, "spd": 0.65, "ammo": "arrow"})
	_item("bow", "Bow", "bow", 40, "Uses arrows.", {"dmg": 19, "spd": 0.65, "ammo": "arrow"})
	_item("steel_bow", "Steel Bow", "bow", 120, "Slow, uses arrows.", {"dmg": 64, "spd": 1.95, "ammo": "arrow"})
	_item("fira_bow", "Fira Bow", "bow", 400, "Uses arrows.", {"dmg": 26, "spd": 0.65, "ammo": "arrow"})
	_item("icy_bow", "Icy Bow", "bow", 600, "Slow, uses arrows.", {"dmg": 77, "spd": 1.8, "ammo": "arrow"})
	_item("magnum_bow", "Magmum Bow", "bow", 2000, "Uses arrows.", {"dmg": 67, "spd": 0.7, "ammo": "arrow"})
	_item("jade_bow", "Jade Bow", "bow", 3000, "Slow, uses arrows.", {"dmg": 272, "spd": 3.0, "ammo": "arrow"})
	_item("snow_maker", "Snow Maker", "bow", 300, "Merry Christmas! Shoots Snow Balls.", {"dmg": 19, "spd": 0.65, "ammo": "snow_ball"})
	_item("arrow", "Arrow", "ammo", 1, "Ammunition for bows.")
	# cannons: slow, heavy shots that use their own ammo
	var cannons := [
		["crazy_cannon_1", "Crazy Cannon I", 39, 2.5, "cc_ball_1"], ["crazy_cannon_2", "Crazy Cannon II", 78, 2.0, "cc_ball_2"],
		["crazy_cannon_3", "Crazy Cannon III", 102, 1.5, "cc_ball_3"], ["waazookaa_1", "WaazooKaa I", 72, 3.0, "wk_missile_1"],
		["waazookaa_2", "WaazooKaa II", 89, 2.5, "wk_missile_2"], ["waazookaa_3", "WaazooKaa III", 144, 2.0, "wk_missile_3"],
		["devil_cannon", "Devil Cannon", 255, 2.0, "devil_cannon_ball"], ["devil_cannon_2", "Devil Cannon II", 330, 2.0, "devil_cannon_ball"],
		["devil_cannon_3", "Devil Cannon III", 405, 2.0, "devil_cannon_ball"],
	]
	for c in cannons:
		var ammo_name := "Crazy Cannon balls" if c[0].begins_with("crazy") else ("Devil Cannon Balls" if c[0].begins_with("devil") else "WaazooKaa missiles")
		_item(c[0], c[1], "bow", 200, "Slow, uses %s." % ammo_name,
			{"dmg": c[2], "spd": c[3], "ammo": c[4], "cannon": true})
	for a in [["cc_ball_1", "Crazy Cannon I Balls"], ["cc_ball_2", "Crazy Cannon II Balls"], ["cc_ball_3", "Crazy Cannon III Balls"],
			["wk_missile_1", "WaazooKaa I Missiles"], ["wk_missile_2", "WaazooKaa II Missiles"], ["wk_missile_3", "WaazooKaa III Missiles"],
			["devil_cannon_ball", "Devil Cannon Balls"]]:
		_item(a[0], a[1], "ammo", 3, "Ammunition for the %s." % a[1].rsplit(" ", true, 1)[0])
	_item("snow_ball", "Snow Ball", "throw", 2, "Hold it and press A to throw it.", {"dmg": 8, "spd": 0.5})
	# tools
	var t := [
		["wooden_axe", "Wooden Axe", "axe", 1, 1], ["copper_axe", "Copper Axe", "axe", 2, 2], ["iron_axe", "Iron Axe", "axe", 3, 3],
		["gold_axe", "Gold Axe", "axe", 4, 4], ["wooden_pick", "Wooden Pick", "pick", 1, 1], ["copper_pick", "Copper Pickaxe", "pick", 2, 2],
		["iron_pick", "Iron Pickaxe", "pick", 3, 3], ["gold_pick", "Gold Pickaxe", "pick", 4, 4], ["erbium_pick", "Erbium Pickaxe", "pick", 4, 5],
	]
	for r in t:
		var what: String = "chop trees" if r[2] == "axe" else "mine rocks and ores"
		_item(r[0], r[1], r[2], 25 if r[4] > 1 else 0, "Used to %s. Tier %d." % [what, r[4]], {"dmg": r[3], "spd": 0.5, "reach": 16, "kb": false, "tier": r[4]})

## extra: "regen" [stat, amount, every seconds] for rings that slowly restore
## health or mana, "immune" for a status it stops (the Jade Ring and poison).
func _gear(id: String, name: String, type: String, s: Array, sell: int, desc: String = "", extra: Dictionary = {}) -> void:
	# s = [atk, def, mag, hp, mp, st]
	var stats := {"atk": s[0], "def": s[1], "mag": s[2], "hp": s[3], "mp": s[4], "st": s[5]}
	var parts := []
	for k in ["atk", "def", "mag", "hp", "mp", "st"]:
		if stats[k] != 0:
			parts.append("%s +%d" % [{"atk": "Attack", "def": "Defense", "mag": "Magic", "hp": "Health", "mp": "Mana", "st": "Stamina"}[k], stats[k]])
	if extra.has("regen"):
		parts.append("restores %d %s every %d seconds" % [extra.regen[1], {"hp": "health", "mp": "mana"}[extra.regen[0]], extra.regen[2]])
	if extra.has("immune"):
		parts.append("can't be poisoned" if extra.immune == "poison" else "immune to " + extra.immune)
	var text := ", ".join(parts)
	if text != "":
		text = text[0].to_upper() + text.substr(1) + "."
	var d := {"stats": stats}
	d.merge(extra)
	_item(id, name, type, sell, (desc + " " if desc != "" else "") + text, d)

func _items_gear() -> void:
	# helmets
	_gear("wooden_helmet", "Wooden Helmet", "helmet", [0, 1, 0, 0, 0, 0], 10)
	_gear("copper_helmet", "Copper Helmet", "helmet", [0, 3, 0, 2, 0, 0], 40)
	_gear("brass_helmet", "Brass Helmet", "helmet", [0, 4, 0, 4, 0, 0], 80)
	_gear("alien_hat", "Alien Hat", "helmet", [0, 1, 0, 3, 7, 0], 200, "Miffie's reward for 99 Jellies.")
	_gear("pumpkin_hat", "Pumppump Hat", "helmet", [0, 4, 0, 4, 4, 4], 150)
	# character hats, made by the Crafter from characters
	_gear("bear_head", "Bear Head", "helmet", [4, 4, 0, 5, 0, 5], 200)
	_gear("dark_night", "Dark Night", "helmet", [5, 4, 5, 4, 0, 0], 200)
	_gear("green_face", "Green Face", "helmet", [0, 4, 0, 5, 5, 4], 200)
	_gear("soldier_helmet", "Soldier Helmet", "helmet", [5, 4, 5, 4, 0, 0], 200)
	_gear("spy_mask", "SPY Mask", "helmet", [8, 0, 0, 10, 0, 0], 200)
	_gear("the_fly", "The Fly", "helmet", [4, 4, 5, 0, 5, 0], 200)
	_gear("trooper_pro", "Trooper Pro", "helmet", [5, 4, 5, 4, 0, 0], 200)
	_gear("bad_mask", "Bad Mask", "helmet", [5, 4, 0, 5, 0, 4], 200)
	_gear("chuu_hat", "Chuu Hat", "helmet", [0, 4, 5, 4, 5, 0], 200)
	_gear("pirate_hat", "Pirate Hat", "helmet", [5, 4, 0, 5, 0, 4], 200)
	_gear("cool_hat", "Cool Hat", "helmet", [8, 5, 0, 7, 0, 5], 400)
	_gear("roman_hat", "Roman Hat", "helmet", [8, 6, 0, 8, 0, 6], 400)
	_gear("storm_hat", "Storm Hat", "helmet", [8, 5, 0, 8, 0, 5], 400)
	_gear("wood_mask", "Wood Mask", "helmet", [0, 2, 0, 2, 0, 0], 30)
	_gear("skull_mask", "Skull Mask", "helmet", [0, 3, 0, 3, 0, 0], 50)
	_gear("fear_helmet", "Fear Helmet", "helmet", [0, 7, 0, 7, 0, 0], 300)
	_gear("fear_helmet_2", "Fear Helmet II", "helmet", [0, 15, 0, 15, 5, 0], 900)
	_gear("hell_helmet", "Hell Helmet", "helmet", [0, 4, 0, 7, 7, 0], 300)
	_gear("hell_helmet_2", "Hell Helmet II", "helmet", [5, 7, 0, 10, 10, 0], 900)
	_gear("witch_helmet", "Witch Helmet", "helmet", [0, 5, 5, 5, 5, 0], 300)
	_gear("witch_helmet_2", "Witch Helmet II", "helmet", [0, 7, 5, 10, 10, 0], 900)
	_gear("spectre_hood", "Ghost Hat", "helmet", [3, 12, 3, 5, 5, 2], 1200, "Rare Ghost Boss drop.")
	_gear("crown", "Crown", "helmet", [0, 18, 0, 0, 0, 0], 600)
	_gear("royal_mask", "Royal Mask", "helmet", [0, 9, 0, 9, 0, 0], 300)
	_gear("thors", "Thors", "helmet", [4, 5, 4, 5, 0, 0], 200)
	_gear("w_cap", "W Cap", "helmet", [7, 5, 0, 7, 0, 5], 400)
	_gear("rooster_hat", "Rooster Hat", "helmet", [0, 8, 0, 12, 12, 0], 900, "Happy Chinese New Year of the Rooster!")
	_gear("snowman_hat", "Snowman Hat", "helmet", [2, 4, 2, 2, 3, 1], 300, "Merry Christmas!")
	_gear("snowman_hat_2", "Snowman Hat II", "helmet", [2, 13, 2, 6, 13, 1], 2000, "Merry Christmas!")
	# Robo Mask Z, ZX, VII and VIII are the wiki's; I to IV are guesses that lead up to Z
	_gear("robo_mask", "Robo Mask", "helmet", [1, 2, 1, 2, 2, 1], 300)
	_gear("robo_mask_2", "Robo Mask II", "helmet", [2, 3, 2, 3, 3, 2], 600)
	_gear("robo_mask_3", "Robo Mask III", "helmet", [3, 5, 3, 5, 5, 3], 1200)
	_gear("robo_mask_4", "Robo Mask IV", "helmet", [4, 6, 4, 6, 6, 4], 2400)
	_gear("robo_mask_z", "Robo Mask Z", "helmet", [5, 8, 5, 8, 8, 5], 4000)
	_gear("robo_mask_zx", "Robo Mask ZX", "helmet", [8, 10, 8, 10, 10, 8], 8000)
	_gear("robo_mask_7", "Robo Mask VII", "helmet", [10, 12, 10, 12, 12, 10], 12000)
	_gear("robo_mask_8", "Robo Mask VIII", "helmet", [12, 14, 12, 14, 14, 12], 20000)
	# guesses: the wiki has the recipes but not the numbers
	_gear("moon_hat", "Moon Hat", "helmet", [0, 4, 4, 6, 6, 0], 600, "Mid Autumn Edition.")
	_gear("moon_hat_2", "Moon Hat II", "helmet", [0, 7, 6, 9, 9, 0], 1500, "Mid Autumn Edition.")
	_gear("x_wings", "X Wings", "helmet", [0, 8, 0, 6, 0, 2], 900)
	_gear("halloween_mask", "Halloween Mask", "helmet", [0, 0, 0, 6, 0, 0], 300, "Happy Halloween!")
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
	_gear("hell_armor_2", "Hell Armor II", "armor", [0, 34, 0, 20, 20, 0], 6000)
	_gear("hell_armor_3", "Hell Armor III", "armor", [0, 35, 0, 23, 23, 0], 9000)
	_gear("hell_armor_4", "Hell Armor IV", "armor", [1, 40, 0, 28, 28, 0], 12000)
	_gear("emperor_dress", "Emperor Dress", "armor", [0, 26, 0, 15, 15, 5], 3000)
	_gear("emperor_dress_2", "Emperor Dress II", "armor", [0, 30, 0, 30, 30, 5], 6000)
	_gear("emperor_dress_3", "Emperor Dress III", "armor", [0, 32, 0, 35, 35, 5], 9000)
	_gear("emperor_dress_4", "Emperor Dress IV", "armor", [0, 37, 0, 45, 45, 9], 12000)
	_gear("snow_dress", "Snow Dress", "armor", [2, 4, 0, 10, 4, 0], 500, "Merry Christmas!")
	_gear("snow_dress_2", "Snow Dress II", "armor", [2, 40, 0, 8, 2, 0], 5000, "Merry Christmas!")
	_gear("skull_dress", "Skull Dress", "armor", [2, 25, 0, 8, 8, 0], 2500)
	_gear("skull_dress_2", "Skull Dress II", "armor", [3, 30, 0, 10, 10, 0], 5000)
	_gear("skull_dress_3", "Skull Dress III", "armor", [5, 35, 0, 10, 10, 0], 8000)
	_gear("skull_dress_4", "Skull Dress IV", "armor", [7, 40, 0, 12, 12, 0], 11000)
	_gear("dragon_dress", "Dragon Dress", "armor", [0, 28, 0, 11, 11, 0], 3000)
	_gear("dragon_dress_2", "Dragon Dress II", "armor", [0, 29, 0, 15, 15, 0], 6000)
	# the later worlds (Modina Dress I-III and the nightmare gear from the wiki; the rest are guesses)
	_gear("modina_dress", "Modina Dress", "armor", [2, 35, 2, 20, 5, 2], 2000)
	_gear("modina_dress_2", "Modina Dress II", "armor", [1, 37, 4, 23, 6, 4], 4000)
	_gear("modina_dress_3", "Modina Dress III", "armor", [5, 42, 8, 27, 8, 6], 8000)
	_gear("nightmare_dress", "Nightmare Dress", "armor", [2, 45, 2, 15, 7, 2], 6000)
	_gear("nightmare_dress_2", "Nightmare Dress II", "armor", [3, 50, 3, 20, 10, 5], 15000)
	_gear("dress_of_lich_king", "Dress of Lich King", "armor", [4, 48, 6, 25, 8, 4], 9000, "Very rare, from Snow Valley.")
	_gear("nightmare_helmet", "Nightmare Helmet", "helmet", [6, 5, 5, 5, 1, 1], 3000)
	_gear("nightmare_helmet_2", "Nightmare Helmet II", "helmet", [3, 13, 3, 6, 2, 2], 6000)
	_gear("nightmare_helmet_3", "Nightmare Helmet III", "helmet", [4, 15, 5, 8, 4, 4], 12000)
	_gear("modina_face", "Modina Face", "helmet", [3, 6, 3, 6, 2, 1], 3000, "Modina's orange mask.")
	_gear("fortune_mask", "Fortune Mask", "helmet", [5, 8, 5, 8, 3, 2], 6000, "A childish mask with a lot of luck in it.")
	_gear("modina_ring", "Modina Ring", "ring", [0, 0, 0, 5, 1, 0], 3000, "Modina's ring.", {"regen": ["mp", 1, 15]})
	_gear("rooster_dress", "Rooster Dress", "armor", [0, 7, 0, 6, 5, 5], 300)
	_gear("ghost_dress", "Ghost Dress", "armor", [2, 30, 2, 13, 13, 0], 4000)
	_gear("ghost_dress_2", "Ghost Dress II", "armor", [3, 32, 3, 15, 15, 0], 8000)
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
	_gear("golden_faceguard", "Golden Faceguard", "shield", [0, 5, 0, 5, 0, 2], 250)
	_gear("long_sword_shield", "Long Sword Shield", "shield", [7, 2, 0, 0, 0, 0], 300)
	# the Moonclipse shields are the wiki's ("additional damage", defense, health)
	for i in 5:
		_gear("moonclipse_shield" + ["", "_2", "_3", "_4", "_5"][i], "Moonclipse Shield" + ["", " II", " III", " IV", " V"][i], "shield",
			[[5, 6, 7, 9, 11][i], [9, 13, 18, 24, 25][i], 0, [5, 6, 7, 9, 11][i], 0, 0], 600 * (i + 1), "Mid Autumn Edition.")
	# the rest of the combo-book shields: the wiki has their recipes but not their numbers (guesses)
	_gear("sapphire_long_sword_shield", "Sapphire Long Sword Shield", "shield", [9, 4, 0, 4, 0, 0], 900)
	_gear("blood_long_sword_shield", "Blood Long Sword Shield", "shield", [12, 6, 0, 6, 0, 0], 1500)
	_gear("golden_long_sword_shield", "Golden Long Sword Shield", "shield", [15, 8, 0, 8, 0, 0], 2500)
	_gear("skull_shield", "Skull Shield", "shield", [0, 10, 0, 6, 0, 2], 900)
	_gear("phase_shield", "Phase Shield", "shield", [0, 12, 0, 8, 0, 2], 900)
	_gear("pink_phase_shield", "Pink Phase Shield", "shield", [0, 16, 0, 12, 4, 2], 2500)
	_gear("titan_shield", "Titan Shield", "shield", [0, 20, 0, 12, 0, 4], 2500)
	_gear("volcan_shield", "Volcan Shield", "shield", [2, 22, 0, 12, 0, 4], 2500)
	_gear("x_shield", "X Shield", "shield", [0, 16, 0, 8, 0, 4], 2500)
	_gear("mithril_shield", "Mithril Shield", "shield", [0, 18, 0, 10, 0, 0], 2500)
	_gear("red_fluorescent_shield", "Red Fluorescent Shield", "shield", [2, 10, 0, 6, 0, 0], 900)
	_gear("blue_fluorescent_shield", "Blue Fluorescent Shield", "shield", [3, 14, 0, 8, 0, 0], 1500)
	_gear("pink_fluorescent_shield", "Pink Fluorescent Shield", "shield", [3, 14, 0, 8, 0, 0], 1500)
	_gear("green_fluorescent_shield", "Green Fluorescent Shield", "shield", [4, 18, 0, 10, 0, 0], 2500)
	_gear("yellow_fluorescent_shield", "Yellow Fluorescent Shield", "shield", [4, 16, 0, 8, 0, 0], 2000)
	_gear("hell_sword_shield", "Hell Sword Shield", "shield", [5, 20, 0, 8, 0, 0], 3000)
	_gear("evil_axe_shield", "Evil Axe Shield", "shield", [4, 18, 0, 8, 0, 0], 3000)
	_gear("evil_axe_shield_2", "Evil Axe Shield II", "shield", [6, 24, 0, 10, 0, 0], 6000)
	_gear("firey_shield", "Firey Shield", "shield", [2, 15, 0, 8, 0, 0], 1500)
	_gear("lava_shield", "Lava Shield", "shield", [4, 26, 0, 12, 0, 0], 6000)
	# rings (two ring slots)
	# The wiki lists the small rings as "1 health, 12 s cooldown". Here the silver ones
	# restore health and the gold ones mana (they're made from Big Potions and Big
	# Mana Potions); the Skull rings' numbers are guesses.
	_gear("silver_ring", "Silver Ring", "ring", [0, 0, 0, 1, 0, 0], 80, "", {"regen": ["hp", 1, 12]})
	_gear("gold_ring", "Gold Ring", "ring", [0, 0, 0, 1, 0, 0], 80, "", {"regen": ["mp", 1, 12]})
	_gear("jade_ring", "Jade Ring", "ring", [0, 0, 0, 0, 0, 0], 150, "", {"immune": "poison"})
	_gear("ruby_silver_ring", "Ruby Silver Ring", "ring", [0, 0, 0, 1, 0, 0], 200, "", {"regen": ["hp", 1, 10]})
	_gear("orb_gold_ring", "Orb Gold Ring", "ring", [0, 0, 0, 1, 0, 0], 200, "", {"regen": ["mp", 1, 10]})
	_gear("skull_silver_ring", "Skull Silver Ring", "ring", [0, 0, 0, 3, 0, 0], 600, "", {"regen": ["hp", 1, 8]})
	_gear("skull_gold_ring", "Skull Gold Ring", "ring", [0, 0, 0, 0, 3, 0], 600, "", {"regen": ["mp", 1, 8]})
	# Heartstone and Manastone I are the wiki's (+10, 1 every 10 s); the higher tiers,
	# Muscle Fire (from Heartstone) and Shattered Souls (from Manastone) are guesses.
	for i in 4:
		var n: String = ["", " II", " III", " IV"][i]
		var sfx: String = ["", "_2", "_3", "_4"][i]
		_gear("heartstone_ring" + sfx, "Heartstone Ring" + n, "ring", [0, 0, 0, 10 + i * 5, 0, 0], 2000 * (i + 1), "", {"regen": ["hp", 1, 10 - i]})
		_gear("manastone_ring" + sfx, "Manastone Ring" + n, "ring", [0, 0, 0, 0, 10 + i * 5, 0], 2000 * (i + 1), "", {"regen": ["mp", 1, 10 - i]})
		_gear("muscle_fire_ring" + sfx, "Ring of Muscle Fire" + n, "ring", [3 + i * 2, 0, 0, 10 + i * 2, 0, 0], 3000 * (i + 1), "", {"regen": ["hp", 1, 10 - i]})
		_gear("shattered_souls_ring" + sfx, "Ring of Shattered Souls" + n, "ring", [0, 0, 3 + i * 2, 0, 10 + i * 2, 0], 3000 * (i + 1), "", {"regen": ["mp", 1, 10 - i]})
	_gear("armor_ring_5", "Armor Ring V", "ring", [0, 40, 0, 0, 0, 0], 6000)
	_gear("armor_ring_6", "Armor Ring VI", "ring", [0, 45, 0, 0, 0, 0], 9000)
	_gear("armor_ring", "Armor Ring I", "ring", [0, 5, 0, 0, 0, 0], 150)
	_gear("armor_ring_2", "Armor Ring II", "ring", [0, 10, 0, 0, 0, 0], 400)
	_gear("armor_ring_3", "Armor Ring III", "ring", [0, 15, 0, 0, 0, 0], 900)
	_gear("armor_ring_4", "Armor Ring IV", "ring", [0, 20, 0, 0, 0, 0], 2000)
	_gear("ring_of_attack", "Ring of Attack", "ring", [8, 0, 0, 0, 0, 0], 2000)
	_gear("ring_of_attack_2", "Ring of Attack II", "ring", [16, 0, 0, 0, 0, 0], 4000)
	_gear("ring_of_magic", "Ring of Magic", "ring", [0, 0, 8, 0, 0, 0], 2000)
	_gear("ring_of_magic_2", "Ring of Magic II", "ring", [0, 0, 16, 0, 0, 0], 4000)

func _items_misc() -> void:
	_item("survival_book", "Survival Book", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "survival"})
	_item("combo_book_1", "Combo Book I", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "combo1"})
	_item("combo_book_2", "Combo Book II", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "combo2"})
	_item("combo_book_3", "Combo Book III", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "combo3"})
	_item("combo_book_4", "Combo Book IV", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "combo4"})
	_item("combo_book_5", "Combo Book V", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "combo5"})
	_item("combo_book_z", "Combo Book Z", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "z"})
	_item("combo_book_zx", "Combo Book ZX", "book", 0, "+50% success on its combinations. Keep it in your bag.", {"book": "zx"})
	_item("combo_book_u", "Combo Book U", "book", 0, "+50% success on its combinations: the U weapons. Keep it in your bag.", {"book": "u"})
	_item("combination_scroll", "Combination Scroll", "scroll", 100, "Put it in the scroll slot for +35% success. Used up.")
	_item("silver_key", "Silver Key", "key", 0, "Opens a Silver Chest in Pixel Town.")
	_item("golden_key", "Golden Key", "key", 0, "Opens a Golden Chest in Pixel Town.")
	_item("master_key", "Master Key", "key", 0, "Opens the Master Chest in Pixel Town.")
	_item("coin", "Pixel Coin", "coin", 0, "Money for the shops in Pixel Town.")
	_item("survival_token", "Survival Token", "token", 0, "Earned by surviving nights in Survival Grasslands. Trade them with the Miner.")
	_item("green_seeds", "Magic Seeds (Green)", "seed", 20, "Plant in the soil behind the rock wall. Grows in 6 minutes.", {"grow": 360})
	_item("red_seeds", "Magic Seeds (Red)", "seed", 60, "Plant in the soil behind the rock wall. Grows in 1 hour.", {"grow": 3600})
	_item("golden_seeds", "Magic Seeds (Golden)", "seed", 150, "Plant in the soil behind the rock wall. Grows in 3 hours.", {"grow": 10800})
	var eggs := [["green_egg", "Monster Egg (Green)"], ["pink_egg", "Monster Egg (Pink)"], ["purple_egg", "Monster Egg (Purple)"],
		["red_egg", "Monster Egg (Red)"], ["queen_egg", "Queen Egg"], ["king_egg", "King Egg"], ["blue_egg", "Monster Egg (Purple/Blue)"],
		["lunar_egg", "Lunar Egg"], ["easter_egg", "Easter Egg"], ["christmas_egg", "Christmas Egg"], ["halloween_egg", "Halloween Egg"]]
	for e in eggs:
		_item(e[0], e[1], "egg", 50, "Hatch it in the Incubator in Pixel Town.")
	for p in PETS:
		var d: Dictionary = PETS[p]
		var parts := []
		if d.get("dmg", 0) > 0: parts.append("hits nearby monsters for %d" % d.dmg)
		if d.get("hp", 0) > 0: parts.append("restores %d health" % d.hp)
		if d.get("mp", 0) > 0: parts.append("restores %d mana" % d.mp)
		if d.get("st", 0) > 0: parts.append("restores %d stamina" % d.st)
		_item(p, d.name, "pet", 0, "A pet. Every %d seconds it %s. Equip it in the pet slot." % [d.every, " and ".join(parts)])
	# characters: use one to change how you look (some come with a weapon)
	for c in CHARACTERS:
		var gives: String = CHARACTERS[c].get("gives", "")
		var d := "A character. Use it to look like the %s" % CHARACTERS[c].name
		d += (" and get a %s." % ITEMS[gives].name) if gives != "" else "."
		_item(c, CHARACTERS[c].name, "character", 50, d + " The Crafter also makes hats from them.", {"look": c, "gives": gives})
	# things you can place
	_item("wood_wall", "Wood Wall", "place", 2, "Blocks monsters. Place it in front of you.", {"hp": 60})
	_item("stone_wall", "Stone Wall", "place", 4, "A stronger wall.", {"hp": 150})
	_item("wooden_spikes", "Wooden Spikes", "place", 4, "Hurts monsters that walk over them.", {"trap": 5})
	_item("work_station", "Work Station", "place", 10, "Lets you use the blacksmith's recipes wherever you place it.")
	_item("campfire", "Campfire", "place", 10, "Slowly heals you while you stand near it.")
	_item("torch", "Torch Stand", "place", 2, "Lights up the night.")

# ---------------------------------------------------------------- characters
# Man in Suit and Nurse are the starting choices. The others are unlocked from
# quests, chests and monsters, and the Crafter turns them into hats.
var CHARACTERS := {
	"man_in_suit": {"name": "Man in Suit"}, "nurse": {"name": "Nurse"},
	"cavemun": {"name": "Cavemun", "gives": "timber_club"}, "pirate": {"name": "Pirate", "gives": "gilded_blade"},
	"the_spi": {"name": "The Spi", "gives": "azure_blade"}, "bad_man": {"name": "Bad Man"}, "school_girl": {"name": "School Girl"},
	"soldier": {"name": "Soldier"}, "chuchu": {"name": "ChuChu"}, "drone": {"name": "Drone"}, "dark_knight": {"name": "Dark Knight"},
	# in the original these two were gem-shop only; here they come from Master Chests
	"ninja": {"name": "Ninja", "gives": "tsurugi"}, "iron_bot": {"name": "Iron Bot", "gives": "iron_fist"},
	"backstreet_boy": {"name": "Backstreet Boy"}, "sailor_moons": {"name": "Sailor Moons"},
}
const START_CHARACTERS := ["man_in_suit", "nurse"]

# ---------------------------------------------------------------- pets
var PETS := {
	"pet_snowball": {"name": "Snowball", "every": 12, "dmg": 6, "look": "snowball"},
	"pet_waterball": {"name": "Waterball", "every": 12, "mp": 1, "look": "waterball"},
	"pet_fireball": {"name": "Fireball", "every": 12, "hp": 1, "look": "fireball"},
	"pet_goldball": {"name": "Goldball", "every": 12, "st": 1, "look": "goldball"},
	"pet_trex": {"name": "Rexy", "every": 10, "hp": 1, "look": "trex"},
	"pet_shell": {"name": "Shelly", "every": 10, "dmg": 10, "look": "shell"},
	"pet_chicklet": {"name": "Chicklet", "every": 10, "hp": 1, "mp": 1, "st": 1, "look": "chicklet"},
	"pet_ufo": {"name": "UFO", "every": 8, "dmg": 15, "hp": 1, "mp": 1, "look": "ufo"},
	"pet_phantom": {"name": "Ghast", "every": 6, "dmg": 18, "mp": 1, "st": 1, "look": "phantom"},
	"pet_eye": {"name": "Mrs Eye", "every": 8, "dmg": 36, "hp": 1, "st": 1, "look": "eyeball"},
	"pet_hand": {"name": "Mr Hand", "every": 8, "dmg": 36, "hp": 1, "st": 1, "look": "hand"},
	"pet_grrr": {"name": "Grrr", "every": 10, "mp": 1, "look": "grrr"},
	"pet_mini_wizard": {"name": "Mini Wizard", "every": 6, "dmg": 18, "mp": 1, "look": "wizard"},
	"pet_mini_ball": {"name": "Mini Ball", "every": 6, "dmg": 21, "hp": 1, "look": "mini_ball"},
	"pet_stone": {"name": "Stone", "every": 8, "dmg": 28, "hp": 1, "st": 1, "look": "small_stone"},
	"pet_aiai": {"name": "AiAi", "every": 10, "dmg": 35, "look": "chick_aiai"},
	"pet_cici": {"name": "CiCi", "every": 10, "hp": 2, "look": "chick_cici"},
	"pet_bibi": {"name": "BiBi", "every": 10, "mp": 2, "look": "chick_bibi"},
	"pet_dede": {"name": "DeDe", "every": 10, "st": 2, "look": "chick_dede"},
	"pet_fofo": {"name": "FoFo", "every": 10, "dmg": 35, "hp": 2, "mp": 2, "st": 2, "look": "chick_fofo"},
	"pet_bunny": {"name": "Bunny", "every": 10, "hp": 2, "mp": 2, "st": 2, "look": "pet_bunny"},
	"pet_snowman": {"name": "Snowman", "every": 10, "hp": 2, "mp": 2, "st": 2, "look": "snowman"},
	"pet_he_he_jr": {"name": "He He Jr", "every": 12, "dmg": 30, "look": "he_he"},
	"pet_he_he": {"name": "He He", "every": 12, "dmg": 40, "hp": 2, "mp": 2, "st": 2, "look": "he_he"},
	"pet_an_an_jr": {"name": "An An Jr", "every": 12, "dmg": 30, "look": "an_an"},
	"pet_an_an": {"name": "An An", "every": 12, "dmg": 40, "hp": 2, "mp": 2, "st": 2, "look": "an_an"},
	"pet_ji_ji_jr": {"name": "Ji Ji Jr", "every": 12, "dmg": 30, "look": "ji_ji"},
	"pet_ji_ji": {"name": "Ji Ji", "every": 12, "dmg": 40, "hp": 2, "mp": 2, "st": 2, "look": "ji_ji"},
	"pet_ne_ne_jr": {"name": "Ne Ne Jr", "every": 12, "dmg": 30, "look": "ne_ne"},
	"pet_ne_ne": {"name": "Ne Ne", "every": 12, "dmg": 40, "hp": 2, "mp": 2, "st": 2, "look": "ne_ne"},
	"pet_eggi": {"name": "Eggi", "every": 10, "dmg": 36, "hp": 2, "look": "egg_orange"},
	"pet_souli": {"name": "Souli", "every": 10, "dmg": 36, "mp": 2, "look": "egg_blue"},
	"pet_hopi": {"name": "Hopi", "every": 10, "dmg": 36, "st": 2, "look": "egg_purple"},
	"pet_bunny_ghost": {"name": "Bunny Ghost", "every": 10, "hp": 4, "mp": 4, "st": 4, "look": "bunny_ghost"},
	"pet_reaper": {"name": "Mr. Reaper", "every": 10, "hp": 4, "mp": 4, "look": "reaper"},
	"pet_moonwisp": {"name": "Moonwisp", "every": 10, "hp": 4, "mp": 4, "look": "moonwisp"},
}
# what hatches from each egg (equal chance)
var EGG_PETS := {
	"green_egg": ["pet_snowball", "pet_shell"], "pink_egg": ["pet_fireball", "pet_waterball", "pet_goldball"],
	"purple_egg": ["pet_ufo", "pet_phantom"], "red_egg": ["pet_trex", "pet_chicklet", "pet_grrr"],
	"queen_egg": ["pet_eye"], "king_egg": ["pet_hand"],
	# The wiki doesn't say which egg Grrr, Mini Wizard, Mini Ball and Stone hatch from; Grrr
	# joins the red egg and the other three the Purple/Blue egg (a guess). The event eggs
	# hatch their event's pets.
	"blue_egg": ["pet_mini_wizard", "pet_mini_ball", "pet_stone"],
	"lunar_egg": ["pet_aiai", "pet_cici", "pet_bibi", "pet_dede", "pet_fofo"],
	"easter_egg": ["pet_bunny", "pet_eggi", "pet_souli", "pet_hopi"],
	"christmas_egg": ["pet_snowman"], "halloween_egg": ["pet_bunny_ghost"],
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
	{"in": ["wood", "fire_crystal", "coal"], "out": "torch_weapon", "rate": 15, "book": "survival"},
	{"in": ["muscle_fire_ring_2", "em_stone", "sailor_moons"], "out": "muscle_fire_ring_3", "rate": -65, "book": "survival"},
	# The other three tier III rings aren't on the wiki's list; they follow Muscle Fire III (guess)
	{"in": ["heartstone_ring_2", "em_stone", "sailor_moons"], "out": "heartstone_ring_3", "rate": -65, "book": "survival"},
	{"in": ["manastone_ring_2", "sapphire_stone", "sailor_moons"], "out": "manastone_ring_3", "rate": -65, "book": "survival"},
	{"in": ["shattered_souls_ring_2", "ruby_stone", "sailor_moons"], "out": "shattered_souls_ring_3", "rate": -65, "book": "survival"},
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
	{"in": ["pet_snowball", "crystal"], "out": "snow_ball", "n": 10, "rate": 35, "book": "combo1"},
	{"in": ["scarab", "copper_bar"], "out": "cc_ball_1", "n": 5, "rate": 35, "book": "combo1"},
	{"in": ["honey_bug", "copper_bar"], "out": "cc_ball_2", "n": 5, "rate": 35, "book": "combo1"},
	{"in": ["stink_bug", "copper_bar"], "out": "cc_ball_3", "n": 5, "rate": 35, "book": "combo1"},
	{"in": ["scarab", "iron_bar"], "out": "wk_missile_1", "n": 5, "rate": 35, "book": "combo1"},
	{"in": ["honey_bug", "iron_bar"], "out": "wk_missile_2", "n": 5, "rate": 35, "book": "combo1"},
	{"in": ["stink_bug", "iron_bar"], "out": "wk_missile_3", "n": 5, "rate": 35, "book": "combo1"},
	# Combo Book II
	{"in": ["honey_bug", "branch", "potion"], "out": "holy_banana", "rate": -10, "book": "combo2"},
	{"in": ["wood_board", "iron_bar", "monster_leather"], "out": "faceguard", "rate": -10, "book": "combo2"},
	{"in": ["sticky_bones", "bone", "scarab"], "out": "skull_mask", "rate": -40, "book": "combo2"},
	{"in": ["herb", "branch", "scarab"], "out": "wood_mask", "rate": -40, "book": "combo2"},
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
	{"in": ["chuchu", "mooncake"], "out": "moon_hat", "rate": -40, "book": "combo3"},
	{"in": ["long_sword", "power_bug"], "out": "long_sword_shield", "rate": -40, "book": "combo3"},
	{"in": ["gold_bar", "iron_bar", "copper_bar"], "out": "pole_axe", "rate": -45, "book": "combo3"},
	{"in": ["power_bug", "armor_bug", "wk_missile_1"], "out": "waazookaa_1", "rate": -45, "book": "combo3"},
	{"in": ["power_bug", "armor_bug", "cc_ball_1"], "out": "crazy_cannon_1", "rate": -45, "book": "combo3"},
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
	{"in": ["legendary_roots", "long_sword_shield", "evil_crystal"], "out": "blood_long_sword_shield", "rate": -65, "book": "combo4"},
	{"in": ["blue_moon", "long_sword_shield", "evil_crystal"], "out": "sapphire_long_sword_shield", "rate": -65, "book": "combo4"},
	{"in": ["evil_shield", "sticky_bones", "catalyst"], "out": "skull_shield", "rate": -45, "book": "combo4"},
	{"in": ["knight_shield", "armor_bug", "catalyst"], "out": "phase_shield", "rate": -45, "book": "combo4"},
	{"in": ["brass_helmet", "armor_bug", "catalyst"], "out": "x_wings", "rate": -45, "book": "combo4"},
	{"in": ["moon_hat", "mooncake"], "out": "moon_hat_2", "rate": -45, "book": "combo4"},
	{"in": ["robo_mask", "legendary_roots", "blue_board"], "out": "robo_mask_2", "rate": -65, "book": "combo4"},
	{"in": ["purple_egg", "green_egg"], "out": "blue_egg", "rate": -45, "book": "combo4"},
	{"in": ["blue_wood", "blue_moon", "catalyst"], "out": "blue_board", "rate": -55, "book": "combo4"},
	{"in": ["healing_staff_2", "living_flame", "evil_crystal"], "out": "healing_staff_3", "rate": -55, "book": "combo4"},
	{"in": ["hero_bug", "waazookaa_1", "wk_missile_2"], "out": "waazookaa_2", "rate": -45, "book": "combo4"},
	{"in": ["hero_bug", "crazy_cannon_1", "cc_ball_2"], "out": "crazy_cannon_2", "rate": -45, "book": "combo4"},
	{"in": ["gold_ring", "big_mana_potion", "catalyst"], "out": "orb_gold_ring", "rate": -5, "book": "combo4"},
	{"in": ["silver_ring", "big_potion", "catalyst"], "out": "ruby_silver_ring", "rate": -5, "book": "combo4"},
	{"in": ["armor_ring", "erbium_bar", "power_bug"], "out": "armor_ring_2", "rate": -35, "book": "combo4"},
	{"in": ["scarab", "iron_bar", "catalyst"], "out": "armor_bug", "rate": -55, "book": "combo4"},
	{"in": ["scarab", "gold_bar", "catalyst"], "out": "power_bug", "rate": -35, "book": "combo4"},
	{"in": ["iron_ore", "honey_bug", "dust"], "out": "gold_ore", "rate": -45, "book": "combo4"},
	{"in": ["iron_ore", "scarab", "dust"], "out": "silver_ore", "rate": -45, "book": "combo4"},
	{"in": ["jelly", "apple", "old_roots"], "out": "rooster_dress", "rate": -40, "book": "combo4"},
	# Combo Book V
	{"in": ["hero_bug", "long_sword_shield", "evil_crystal"], "out": "golden_long_sword_shield", "rate": -65, "book": "combo5"},
	{"in": ["red_fluorescent_shield", "evil_crystal", "power_bug"], "out": "blue_fluorescent_shield", "rate": -60, "book": "combo5"},
	{"in": ["red_fluorescent_shield", "evil_crystal", "armor_bug"], "out": "pink_fluorescent_shield", "rate": -60, "book": "combo5"},
	{"in": ["skull_shield", "evil_crystal", "hero_bug"], "out": "titan_shield", "rate": -60, "book": "combo5"},
	{"in": ["evil_bar", "robo_mask_2", "silver_bar"], "out": "robo_mask_3", "rate": -65, "book": "combo5"},
	{"in": ["orb_gold_ring", "rejuvenate_potion", "catalyst"], "out": "skull_gold_ring", "rate": -40, "book": "combo5"},
	{"in": ["ruby_silver_ring", "rejuvenate_potion", "catalyst"], "out": "skull_silver_ring", "rate": -40, "book": "combo5"},
	{"in": ["phase_shield", "evil_crystal", "hero_bug"], "out": "volcan_shield", "rate": -60, "book": "combo5"},
	{"in": ["hellfire_blade", "evil_crystal", "hero_bug"], "out": "volcan_sword", "rate": -60, "book": "combo5"},
	{"in": ["icy_bow", "erbium_bar", "catalyst"], "out": "fira_bow", "rate": -35, "book": "combo5"},
	{"in": ["steel_bow", "erbium_bar", "blue_board"], "out": "icy_bow", "rate": -65, "book": "combo5"},
	{"in": ["living_flame", "evil_crystal", "hero_bug"], "out": "sapphire_staff", "rate": -65, "book": "combo5"},
	{"in": ["evil_bar", "healing_staff_3", "water_crystal"], "out": "healing_staff_4", "rate": -55, "book": "combo5"},
	{"in": ["moon_blade_3", "volcanic_bar", "em_stone"], "out": "moon_blade_4", "rate": -75, "book": "combo5"},
	{"in": ["evil_apple", "iron_sword_cast", "evil_bar"], "out": "hell_sword", "rate": -75, "book": "combo5"},
	{"in": ["armor_ring_2", "evil_crystal", "hero_bug"], "out": "armor_ring_3", "rate": -55, "book": "combo5"},
	{"in": ["power_bug", "armor_bug", "catalyst"], "out": "hero_bug", "rate": -65, "book": "combo5"},
	{"in": ["gold_ore", "dust", "stink_bug"], "out": "erbium", "rate": -45, "book": "combo5"},
	{"in": ["moon_blade", "gold_bar", "em_stone"], "out": "moon_blade_2", "rate": -75, "book": "combo5"},
	{"in": ["moon_blade_2", "erbium_bar", "em_stone"], "out": "moon_blade_3", "rate": -75, "book": "combo5"},
	{"in": ["ruby_stone", "em_stone", "power_bug"], "out": "ring_of_attack", "rate": -10, "book": "combo5"},
	{"in": ["ruby_stone", "sapphire_stone", "armor_bug"], "out": "ring_of_magic", "rate": -10, "book": "combo5"},
	# Combo Book Z (the Butterfly Boss and Evil Santa drop it, or combine Combo Books I, II and III)
	{"in": ["backstreet_boy", "school_girl", "blue_moon"], "out": "sapphire_stone", "rate": -75, "book": "z"},
	{"in": ["skull_gold_ring", "skull_silver_ring", "big_potion"], "out": "heartstone_ring", "rate": -65, "book": "z"},
	{"in": ["skull_gold_ring", "skull_silver_ring", "big_mana_potion"], "out": "manastone_ring", "rate": -65, "book": "z"},
	{"in": ["heartstone_ring", "hero_bug", "catalyst"], "out": "muscle_fire_ring", "rate": -65, "book": "z"},
	{"in": ["manastone_ring", "hero_bug", "catalyst"], "out": "shattered_souls_ring", "rate": -65, "book": "z"},
	{"in": ["armor_ring_3", "legendary_roots", "hero_bug"], "out": "armor_ring_4", "rate": -65, "book": "z"},
	{"in": ["heartstone_ring", "evil_bar", "dark_knight"], "out": "heartstone_ring_2", "rate": -65, "book": "z"},
	{"in": ["manastone_ring", "evil_bar", "sailor_moons"], "out": "manastone_ring_2", "rate": -65, "book": "z"},
	{"in": ["muscle_fire_ring", "evil_bar", "sailor_moons"], "out": "muscle_fire_ring_2", "rate": -65, "book": "z"},
	{"in": ["shattered_souls_ring", "evil_bar", "dark_knight"], "out": "shattered_souls_ring_2", "rate": -65, "book": "z"},
	{"in": ["robo_mask_3", "evil_bar", "hero_bug"], "out": "robo_mask_4", "rate": -75, "book": "z"},
	{"in": ["evil_shield", "armor_bug", "catalyst"], "out": "x_shield", "rate": -65, "book": "z"},
	{"in": ["gold_shield", "armor_bug", "evil_crystal"], "out": "mithril_shield", "rate": -65, "book": "z"},
	{"in": ["phase_shield", "living_flame", "apple"], "out": "pink_phase_shield", "rate": -65, "book": "z"},
	{"in": ["red_fluorescent_shield", "evil_crystal", "hero_bug"], "out": "green_fluorescent_shield", "rate": -65, "book": "z"},
	{"in": ["evil_apple", "gold_axe", "evil_bar"], "out": "evil_axe", "rate": -75, "book": "z"},
	{"in": ["icy_bow", "power_bug", "hero_bug"], "out": "jade_bow", "rate": -65, "book": "z"},
	{"in": ["fira_bow", "power_bug", "hero_bug"], "out": "magnum_bow", "rate": -65, "book": "z"},
	{"in": ["bone", "living_flame", "linen"], "out": "skull_dress", "rate": -75, "book": "z"},
	{"in": ["lavish_armor", "living_flame", "hero_bug"], "out": "hell_armor", "rate": -65, "book": "z"},
	{"in": ["dark_knight", "queen_egg", "sailor_moons"], "out": "rooster_hat", "rate": -65, "book": "z"},
	{"in": ["moon_blade_4", "nightmare_ingot", "em_stone"], "out": "moon_blade_5", "rate": -75, "book": "z"},
	{"in": ["hell_sword", "dark_stone", "volcanic_bar"], "out": "hell_sword_2", "rate": -65, "book": "z"},
	{"in": ["evil_axe_shield", "dark_stone", "volcanic_bar"], "out": "evil_axe_shield_2", "rate": -65, "book": "z"},
	{"in": ["moonclipse", "gold_bar", "em_stone"], "out": "moonclipse_2", "rate": -75, "book": "z"},
	{"in": ["moonclipse_2", "erbium_bar", "em_stone"], "out": "moonclipse_3", "rate": -75, "book": "z"},
	{"in": ["moonclipse_3", "volcanic_bar", "em_stone"], "out": "moonclipse_4", "rate": -75, "book": "z"},
	# Combo Book ZX ("Nightmare Bar" on the wiki is the Nightmare Ingot)
	{"in": ["combo_book_1", "combo_book_2", "combo_book_3"], "out": "combo_book_z", "rate": 50, "book": "zx"},
	{"in": ["heartstone_ring_3", "topaz_stone", "catalyst"], "out": "heartstone_ring_4", "rate": 10, "book": "zx"},
	{"in": ["manastone_ring_3", "topaz_stone", "catalyst"], "out": "manastone_ring_4", "rate": 10, "book": "zx"},
	{"in": ["muscle_fire_ring_3", "sapphire_stone", "catalyst"], "out": "muscle_fire_ring_4", "rate": -10, "book": "zx"},
	{"in": ["shattered_souls_ring_3", "ruby_stone", "catalyst"], "out": "shattered_souls_ring_4", "rate": -10, "book": "zx"},
	{"in": ["dark_stone", "armor_ring_4", "volcanic_bar"], "out": "armor_ring_5", "rate": -35, "book": "zx"},
	{"in": ["knights_blade", "holy_knight", "dark_knight"], "out": "twin_sun", "rate": -15, "book": "zx"},
	{"in": ["volcanic_bar", "skull_dress", "halloween_mask"], "out": "ghost_dress", "rate": -60, "book": "zx"},
	{"in": ["pink_egg", "volcanic_bar", "herb"], "out": "easter_egg", "rate": -35, "book": "zx"},
	{"in": ["cc_ball_3", "evil_bar", "dark_crystal"], "out": "devil_cannon_ball", "n": 5, "rate": 20, "book": "zx"},
	{"in": ["firey_shield", "volcanic_bar", "evil_bar"], "out": "lava_shield", "rate": -60, "book": "zx"},
	{"in": ["rooster_dress", "dark_stone", "volcanic_bar"], "out": "emperor_dress", "rate": -65, "book": "zx"},
	# the wiki's third candy is "Candy (blue)"; read as the Candy Staff
	{"in": ["candy_stick_red", "candy_stick_green", "candy_staff"], "out": "giant_candy", "rate": -75, "book": "zx"},
	{"in": ["moon_blade_5", "nightmare_ingot", "forbidden_stone"], "out": "dark_moon_blade", "rate": -75, "book": "zx"},
	{"in": ["moonclipse_4", "nightmare_ingot", "em_stone"], "out": "moonclipse_5", "rate": -75, "book": "zx"},
	{"in": ["forbidden_bar", "evil_crystal", "armor_bug"], "out": "dragon_handle", "rate": -60, "book": "zx"},
	{"in": ["popstick", "erbium_bar", "honey"], "out": "chocolate_pops", "rate": -45, "book": "zx"},
	{"in": ["chocolate_pops", "evil_bar", "honey"], "out": "red_bean_pops", "rate": -45, "book": "zx"},
	{"in": ["red_bean_pops", "volcanic_bar", "honey"], "out": "rocket_pops", "rate": -45, "book": "zx"},
	{"in": ["rocket_pops", "nightmare_ingot", "honey"], "out": "rainbow_pops", "rate": -45, "book": "zx"},
	{"in": ["combo_book_z", "missing_page_u", "sticky_bones"], "out": "combo_book_u", "rate": 15, "book": "zx"},
	{"in": ["christmas_tree", "gold_bar", "catalyst"], "out": "ultimate_tree", "rate": -80, "book": "zx"},
	# the Missing Page's recipe isn't on the wiki; it mirrors Combo Book U's (guess)
	{"in": ["combo_book_z", "missing_page", "sticky_bones"], "out": "combo_book_zx", "rate": 15, "book": "z"},
	# Combo Book U: each U weapon is its weapon + a Hero Bug + a Combo Sword. Twin Sun U and
	# Devil Spike U have the top tier's attack, so they take Twin Sun IV and Devil Spike III.
	{"in": ["rainbow_sword", "hero_bug", "combo_sword"], "out": "rainbow_sword_u", "rate": -15, "book": "u"},
	{"in": ["volcan_longsword", "hero_bug", "combo_sword"], "out": "volcan_longsword_u", "rate": -15, "book": "u"},
	{"in": ["nightmare_long_sword", "hero_bug", "combo_sword"], "out": "nightmare_long_sword_u", "rate": -15, "book": "u"},
	{"in": ["modina_1", "hero_bug", "combo_sword"], "out": "modina_u", "rate": -15, "book": "u"},
	{"in": ["dark_moon_blade", "hero_bug", "combo_sword"], "out": "dark_moon_blade_u", "rate": -15, "book": "u"},
	{"in": ["shadow_moon_blade", "hero_bug", "combo_sword"], "out": "shadow_moon_blade_u", "rate": -15, "book": "u"},
	{"in": ["blood_moon_soul_blade", "hero_bug", "combo_sword"], "out": "blood_moon_soul_blade_u", "rate": -15, "book": "u"},
	{"in": ["frost_moon_blade", "hero_bug", "combo_sword"], "out": "frost_moon_blade_u", "rate": -15, "book": "u"},
	{"in": ["hell_sword_2", "hero_bug", "combo_sword"], "out": "hell_sword_u", "rate": -15, "book": "u"},
	{"in": ["evil_shadow_blade", "hero_bug", "combo_sword"], "out": "evil_shadow_blade_u", "rate": -15, "book": "u"},
	{"in": ["evil_axe_2", "hero_bug", "combo_sword"], "out": "evil_axe_u", "rate": -15, "book": "u"},
	{"in": ["red_moon_soul_blade", "hero_bug", "combo_sword"], "out": "red_moon_soul_blade_u", "rate": -15, "book": "u"},
	{"in": ["twin_sun_4", "hero_bug", "combo_sword"], "out": "twin_sun_u", "rate": -15, "book": "u"},
	{"in": ["devil_spike_3", "hero_bug", "combo_sword"], "out": "devil_spike_u", "rate": -15, "book": "u"},
]
const BOOK_ITEM := {"survival": "survival_book", "combo1": "combo_book_1", "combo2": "combo_book_2",
	"combo3": "combo_book_3", "combo4": "combo_book_4", "combo5": "combo_book_5", "z": "combo_book_z", "zx": "combo_book_zx", "u": "combo_book_u"}
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
# Crafted by the Crafter in Pixel Town (or at a Work Station). Always succeeds.
# Grouped by the Crafter's tabs, in the order the wiki's tables list them. Recipes
# from the wiki unless marked; "guess" means the wiki doesn't say.
var SMITH := [
	# tools (under the weapon tab)
	{"out": "copper_axe", "cost": {"copper_bar": 20, "wooden_axe": 1}},
	{"out": "iron_axe", "cost": {"iron_bar": 20, "copper_axe": 1}},
	{"out": "gold_axe", "cost": {"gold_bar": 20, "iron_axe": 1}},
	{"out": "volcan_axe", "cost": {"gold_axe": 1, "erbium_bar": 75, "power_bug": 75}},
	{"out": "sky_pole_axe", "cost": {"pole_axe": 1, "silver_bar": 50, "monster_horn": 50}},
	{"out": "copper_pick", "cost": {"copper_bar": 5, "wooden_pick": 1}},
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
	{"out": "unlawful", "cost": {"plunger": 1, "stink_bug": 25, "monster_hide": 25}},
	{"out": "knights_blade", "cost": {"timber_club": 1, "azure_blade": 1, "bone": 75}},
	{"out": "kings_mace", "cost": {"knights_blade": 1, "dongle": 25, "gold_bar": 50}},
	{"out": "holy_knight", "cost": {"kings_mace": 1, "gold_bar": 75, "crystal": 75}},
	{"out": "poison_ivy", "cost": {"excalibur": 1, "gold_bar": 75, "dark_crystal": 75}},
	{"out": "hellfire_blade", "cost": {"excalibur": 1, "gold_bar": 75, "fire_crystal": 75}},
	{"out": "glow_blade_blue", "cost": {"water_crystal": 50, "iron_bar": 25}},
	{"out": "combo_sword", "cost": {"copper_sword_cast": 1, "iron_sword_cast": 1, "gold_sword_cast": 1}},
	{"out": "nightmare_blade", "cost": {"living_flame": 75, "evil_bar": 100, "power_bug": 15}},
	{"out": "staff_cast", "cost": {"wood": 50, "branch": 50, "copper_ore": 5}},
	{"out": "magic_wand", "cost": {"wood": 25, "branch": 25, "copper_ore": 25}},
	# the later worlds' weapons (guesses)
	{"out": "modina_2", "cost": {"modina_1": 2, "blue_blade": 2, "gold_bar": 20}},
	{"out": "modina_3", "cost": {"modina_2": 2, "blue_blade": 4, "erbium_bar": 20}},
	{"out": "modina_4", "cost": {"modina_3": 2, "blue_blade": 8, "nightmare_ingot": 10}},
	{"out": "long_lance_2", "cost": {"long_lance": 2, "gold_bar": 30}},
	{"out": "long_lance_3", "cost": {"long_lance_2": 2, "erbium_bar": 30}},
	{"out": "hell_spike_2", "cost": {"hell_spike": 1, "volcanic_bar": 10, "hell_bar": 20}},
	{"out": "hell_spike_3", "cost": {"hell_spike_2": 1, "volcanic_bar": 25, "nightmare_ingot": 10}},
	{"out": "nightmare_blade_2", "cost": {"nightmare_blade": 1, "nightmare_ingot": 20, "dark_heart": 2}},
	{"out": "nightmare_blade_3", "cost": {"nightmare_blade_2": 1, "nightmare_ingot": 40, "dark_heart": 5}},
	{"out": "nightmare_blade_4", "cost": {"nightmare_blade_3": 1, "bone_of_makara": 5, "sandnite_bar": 25}},
	{"out": "tsurugi_5", "cost": {"tsurugi_4": 1, "sandnite_bar": 25, "topaz_stone": 5}},
	{"out": "iron_fist_5", "cost": {"iron_fist_4": 1, "sandnite_bar": 25, "topaz_stone": 5}},
	{"out": "hell_pole_axe", "cost": {"sky_pole_axe": 1, "hell_bar": 50, "monster_horn": 50}},
	{"out": "evil_axe_2", "cost": {"evil_axe": 1, "volcanic_bar": 25, "dark_stone": 3}},
	{"out": "refined_combo_sword", "cost": {"combo_sword": 1, "iron_bar": 25, "crystal": 25}},
	{"out": "ice_sword", "cost": {"refined_combo_sword": 1, "water_crystal": 50, "silver_bar": 25}},
	{"out": "ice_devil_sword", "cost": {"ice_sword": 1, "evil_bar": 25, "water_crystal": 75}},
	{"out": "heavy_ice_devil_sword", "cost": {"ice_devil_sword": 1, "volcanic_bar": 25, "evil_crystal": 50}},
	{"out": "heavy_ice_devil_sword_2", "cost": {"heavy_ice_devil_sword": 1, "skin_of_makara": 5, "sandnite_bar": 25}},
	{"out": "volcan_longsword", "cost": {"volcan_sword": 1, "long_sword": 1, "volcanic_bar": 15}},
	{"out": "twin_sun_2", "cost": {"twin_sun": 1, "gold_bar": 50, "em_stone": 1}},
	{"out": "twin_sun_3", "cost": {"twin_sun_2": 1, "erbium_bar": 50, "em_stone": 2}},
	{"out": "twin_sun_4", "cost": {"twin_sun_3": 1, "volcanic_bar": 25, "em_stone": 3}},
	{"out": "devil_spike_2", "cost": {"devil_spike": 1, "evil_bar": 25, "hell_bar": 25}},
	{"out": "devil_spike_3", "cost": {"devil_spike_2": 1, "volcanic_bar": 25, "dark_stone": 3}},
	{"out": "firecracker_blade_2", "cost": {"firecracker_blade": 1, "volcanic_bar": 10, "fire_crystal": 99}},
	{"out": "christmas_tree_2", "cost": {"christmas_tree": 1, "snow_ball": 99, "gold_bar": 25}},
	{"out": "christmas_tree_3", "cost": {"christmas_tree_2": 1, "snow_ball": 99, "erbium_bar": 25}},
	{"out": "christmas_tree_4", "cost": {"christmas_tree_3": 1, "snow_ball": 99, "volcanic_bar": 25}},
	{"out": "dragon_blade", "cost": {"dragon_handle": 1, "dragon_spine": 1, "forbidden_bar": 5}},
	{"out": "dragon_blade_2", "cost": {"dragon_blade": 1, "dragon_spine": 1, "volcanic_bar": 25}},
	{"out": "dragon_blade_3", "cost": {"dragon_blade_2": 1, "treasure_of_makara": 1, "sandnite_bar": 25}},
	{"out": "crazy_carrot", "cost": {"king_carrot": 1, "evil_bar": 25, "power_bug": 25}},
	{"out": "pumpkin_saber_b", "cost": {"pumpkin_saber_a": 1, "fire_crystal": 50, "gold_bar": 25}},
	{"out": "pumpkin_saber_c", "cost": {"pumpkin_saber_b": 1, "dark_crystal": 50, "erbium_bar": 25}},
	{"out": "pumpkin_saber", "cost": {"pumpkin_saber_c": 1, "evil_crystal": 25, "volcanic_bar": 25}},
	{"out": "ruby_staff", "cost": {"fire_staff": 1, "ruby_stone": 3, "evil_bar": 10}},
	{"out": "ruby_staff_2", "cost": {"ruby_staff": 1, "ruby_stone": 5, "volcanic_bar": 15}},
	{"out": "healing_staff_5", "cost": {"healing_staff_4": 1, "evil_crystal": 25, "living_flame": 25}},
	{"out": "healing_staff_6", "cost": {"healing_staff_5": 1, "volcanic_bar": 10, "water_crystal": 99}},
	{"out": "devil_cannon_2", "cost": {"devil_cannon": 1, "evil_bar": 25, "power_bug": 25}},
	{"out": "devil_cannon_3", "cost": {"devil_cannon_2": 1, "volcanic_bar": 25, "hero_bug": 10}},
	# helmets
	{"out": "wooden_helmet", "cost": {"wood_board": 25}},
	{"out": "copper_helmet", "cost": {"copper_bar": 25, "armor_bug": 5, "wooden_helmet": 1}},
	{"out": "brass_helmet", "cost": {"iron_bar": 25, "armor_bug": 5, "copper_helmet": 1}},
	{"out": "pumpkin_hat", "cost": {"gold_bar": 25, "armor_bug": 5, "silver_bar": 25}},
	{"out": "bear_head", "cost": {"cavemun": 10}},
	{"out": "dark_night", "cost": {"dark_knight": 10}},
	{"out": "green_face", "cost": {"cavemun": 5, "backstreet_boy": 5}},
	{"out": "soldier_helmet", "cost": {"soldier": 10}},
	{"out": "spy_mask", "cost": {"the_spi": 10}},
	{"out": "the_fly", "cost": {"school_girl": 10}},
	{"out": "trooper_pro", "cost": {"drone": 10}},
	{"out": "bad_mask", "cost": {"bad_man": 10}},
	{"out": "chuu_hat", "cost": {"chuchu": 10}},
	{"out": "pirate_hat", "cost": {"pirate": 10}},
	{"out": "cool_hat", "cost": {"bad_man": 15, "the_spi": 15}},
	{"out": "roman_hat", "cost": {"soldier": 15, "drone": 15}},
	{"out": "storm_hat", "cost": {"pirate": 15, "chuchu": 15}},
	{"out": "thors", "cost": {"backstreet_boy": 10}},
	{"out": "w_cap", "cost": {"backstreet_boy": 15, "school_girl": 15}},
	{"out": "royal_mask", "cost": {"sailor_moons": 10}},
	{"out": "crown", "cost": {"dark_knight": 10, "sailor_moons": 10}},
	{"out": "rooster_hat", "cost": {"the_spi": 25, "dark_knight": 25, "sailor_moons": 25}},
	{"out": "snowman_hat_2", "cost": {"snowman_hat": 1, "volcanic_bar": 25, "snow_ball": 99}},
	{"out": "robo_mask_z", "cost": {"robo_mask_4": 1, "dark_stone": 3, "topaz_stone": 5}},
	{"out": "robo_mask_zx", "cost": {"robo_mask_z": 1, "living_flame": 99, "evil_bar": 99}},
	{"out": "robo_mask_8", "cost": {"robo_mask_7": 1, "forbidden_bar": 50, "dark_heart": 10}},
	{"out": "fear_helmet_2", "cost": {"dark_bar": 65, "fear_helmet": 1}},
	{"out": "hell_helmet_2", "cost": {"hell_bar": 65, "hell_helmet": 1}},
	{"out": "witch_helmet_2", "cost": {"light_bar": 65, "witch_helmet": 1}},
	{"out": "nightmare_helmet", "cost": {"hell_bar": 50, "dark_bar": 50, "dark_knight": 1}},
	{"out": "nightmare_helmet_2", "cost": {"nightmare_helmet": 1, "volcanic_bar": 45, "armor_bug": 30}},
	{"out": "nightmare_helmet_3", "cost": {"nightmare_helmet_2": 1, "nightmare_ingot": 30, "dark_heart": 5}},
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
	{"out": "hell_armor_2", "cost": {"hell_armor": 1, "dark_stone": 3, "evil_crystal": 50}},
	{"out": "hell_armor_3", "cost": {"hell_armor_2": 1, "evil_bar": 50, "volcanic_bar": 25}},
	# the wiki lists Hell Armor here, which would skip II and III; read as Hell Armor III
	{"out": "hell_armor_4", "cost": {"hell_armor_3": 1, "nightmare_ingot": 25, "dark_heart": 5}},
	{"out": "nightmare_dress", "cost": {"hell_armor_2": 1, "nightmare_ingot": 50, "dark_heart": 5}},
	{"out": "nightmare_dress_2", "cost": {"nightmare_dress": 1, "dragon_spine": 1, "dress_of_lich_king": 1}},
	{"out": "emperor_dress", "cost": {"rooster_dress": 1, "legendary_roots": 99, "evil_bar": 99}},
	{"out": "emperor_dress_2", "cost": {"emperor_dress": 1, "dark_stone": 3, "evil_crystal": 50}},
	{"out": "emperor_dress_3", "cost": {"emperor_dress_2": 1, "volcanic_bar": 20, "nightmare_ingot": 10}},
	{"out": "emperor_dress_4", "cost": {"emperor_dress_3": 1, "dark_heart": 10, "sky_stone": 10}},
	{"out": "snow_dress", "cost": {"snow_ball": 99, "water_crystal": 99, "linen": 99}},
	{"out": "snow_dress_2", "cost": {"snow_dress": 1, "volcanic_bar": 50, "evil_crystal": 50}},
	{"out": "skull_dress_2", "cost": {"skull_dress": 1, "evil_bar": 50, "dark_stone": 5}},
	{"out": "skull_dress_3", "cost": {"skull_dress_2": 1, "volcanic_bar": 25, "hero_bug": 35}},
	{"out": "skull_dress_4", "cost": {"skull_dress_3": 1, "nightmare_ingot": 1, "dark_heart": 2}},
	{"out": "modina_dress_3", "cost": {"modina_dress_2": 2, "nightmare_ingot": 40, "blue_blade": 1}},
	{"out": "dragon_dress_2", "cost": {"dragon_dress": 1, "volcanic_bar": 15, "dark_stone": 5}},
	{"out": "ghost_dress_2", "cost": {"ghost_dress": 1, "evil_bar": 99, "evil_crystal": 25}},
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
	{"out": "golden_faceguard", "cost": {"copper_faceguard": 1, "gold_bar": 25}},
	{"out": "long_sword_shield", "cost": {"iron_bar": 25, "sticky_bones": 25, "crystal": 25}},
	# rings
	{"out": "gold_ring", "cost": {"gold_bar": 5, "copper_bar": 5}},
	{"out": "silver_ring", "cost": {"silver_bar": 5, "copper_bar": 5}},
	{"out": "orb_gold_ring", "cost": {"gold_ring": 1, "power_bug": 15, "water_crystal": 50}},
	{"out": "ruby_silver_ring", "cost": {"silver_ring": 1, "power_bug": 15, "water_crystal": 50}},
	{"out": "armor_ring", "cost": {"ruby_silver_ring": 1, "iron_bar": 50, "small_evil_crystal": 5}},
	{"out": "armor_ring_2", "cost": {"armor_ring": 1, "erbium_bar": 50, "small_evil_crystal": 5}},
	{"out": "ring_of_attack_2", "cost": {"ring_of_attack": 1, "volcanic_bar": 25, "evil_bar": 15}},
	{"out": "ring_of_magic_2", "cost": {"ring_of_magic": 1, "volcanic_bar": 25, "evil_bar": 15}},
	# from the forum: three of each gem stone make a Dark Stone
	{"out": "dark_stone", "cost": {"em_stone": 3, "sapphire_stone": 3, "ruby_stone": 3}},
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
	{"out": "nightmare_ingot", "main": "nightmare_ore", "cost": {"nightmare_ore": 5, "coal": 1}, "time": 7200},
	{"out": "sandnite_bar", "main": "sandnite_ore", "cost": {"sandnite_ore": 5, "coal": 1}, "time": 7200},
	{"out": "light_bar", "main": "water_crystal", "cost": {"water_crystal": 5, "silver_bar": 5, "coal": 1}, "time": 2700},
	{"out": "dark_bar", "main": "dark_crystal", "cost": {"dark_crystal": 5, "gold_bar": 5, "coal": 1}, "time": 2700},
	{"out": "hell_bar", "main": "earth_crystal", "cost": {"earth_crystal": 5, "erbium_bar": 5, "coal": 1}, "time": 2700},
	{"out": "evil_bar", "main": "green_egg", "cost": {"green_egg": 1, "light_bar": 1, "dark_bar": 1, "hell_bar": 1, "coal": 1}, "time": 3600},
	{"out": "forbidden_bar", "main": "blue_wood", "cost": {"blue_wood": 1, "evil_bar": 1, "volcanic_bar": 1, "nightmare_ingot": 1, "coal": 1}, "time": 7200},
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
	"vase": {"tool": "pick", "min": 1, "hits": 8, "drops": [["scarab", 0.4, 1, 2], ["stink_bug", 0.3, 1, 1], ["honey_bug", 0.3, 1, 1], ["fire_bug", 0.3, 1, 1], ["power_bug", 0.03, 1, 1], ["armor_bug", 0.03, 1, 1], ["hero_bug", 0.006, 1, 1], ["honey", 0.01, 1, 1]], "color": "7b4fb8"},
	"stone": {"tool": "pick", "min": 1, "hits": 8, "drops": [["rock", 1.0, 1, 3], ["scarab", 0.25, 1, 1], ["coal", 0.3, 1, 1]], "color": "8a9099"},
	"copper": {"tool": "pick", "min": 1, "hits": 8, "drops": [["copper_ore", 1.0, 1, 2], ["stink_bug", 0.15, 1, 1], ["coal", 0.35, 1, 1]], "color": "e8864a"},
	"iron": {"tool": "pick", "min": 2, "hits": 7, "drops": [["iron_ore", 1.0, 1, 2], ["fire_bug", 0.15, 1, 1], ["coal", 0.35, 1, 1]], "color": "8ab0d8"},
	"silver": {"tool": "pick", "min": 2, "hits": 7, "drops": [["silver_ore", 1.0, 1, 2], ["coal", 0.35, 1, 1], ["honey_bug", 0.15, 1, 1]], "color": "e3ebf5"},
	"gold": {"tool": "pick", "min": 3, "hits": 6, "drops": [["gold_ore", 1.0, 1, 2], ["coal", 0.35, 1, 1], ["hero_bug", 0.01, 1, 1]], "color": "f2cf5b"},
	"erbium_rock": {"tool": "pick", "min": 4, "hits": 10, "step": 2, "drops": [["erbium", 1.0, 1, 1], ["gold_ore", 0.3, 1, 1], ["silver_ore", 0.3, 1, 1], ["coal", 0.3, 1, 1]], "color": "c83a6a"},
	"volcanic_rock": {"tool": "pick", "min": 5, "hits": 12, "step": 2, "drops": [["volcanic_ore", 0.12, 1, 1], ["erbium", 0.6, 1, 1], ["gold_ore", 0.4, 1, 1], ["coal", 0.3, 1, 1]], "color": "ff5a2a"},
	"ice_rock": {"tool": "pick", "min": 3, "hits": 6, "drops": [["water_crystal", 0.3, 1, 1], ["silver_ore", 0.6, 1, 1], ["crystal", 0.4, 1, 1]], "color": "a6e6f2"},
	"sandnite_rock": {"tool": "pick", "min": 5, "hits": 12, "step": 2, "drops": [["sandnite_ore", 0.5, 1, 1], ["gold_ore", 0.4, 1, 1], ["topaz_stone", 0.005, 1, 1], ["coal", 0.3, 1, 1]], "color": "e2cf8e"},
	"rock_wall": {"tool": "pick", "min": 4, "hits": 30, "step": 0, "drops": [], "color": "8a9099", "wall": true},
	# the wooden wall in front of the Trading Center: hit it with a Torch to burn it down
	# the stone wall in the east of Pixel Town: only the Wall Hammer breaks it
	"hammer_wall": {"tool": "hammer", "min": 1, "hits": 10, "step": 0, "drops": [], "color": "8a9099", "wall": true, "flag": "hammer_wall",
		"opened": "The stone wall crumbles! There's a way down under Pixel Town."},
	"trade_wall": {"tool": "torch", "min": 1, "hits": 3, "step": 0, "drops": [], "color": "f2a33a", "wall": true, "flag": "trade_wall",
		"opened": "The wall burns down! The Trading Center is open."},
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
	_mob("wisp", "Fira", "wisp", [15, 15], 1, "fly", [["blue_moon", 0.12, 1, 1], ["crystal", 0.1, 1, 1], ["fire_crystal", 0.05, 1, 1], ["monster_hide", 0.15, 1, 1], ["wooden_armor", 0.02, 1, 1], ["wooden_helmet", 0.02, 1, 1]], {"speed": 40})
	_mob("mummy", "Mummy", "mummy", [45, 45], 3, "charge", [["bone", 0.25, 1, 1], ["blue_moon", 0.1, 1, 1], ["dark_crystal", 0.04, 1, 1], ["monster_hide", 0.15, 1, 1], ["wooden_helmet", 0.02, 1, 1]], {"speed": 30, "charge_wait": 3.0})
	_mob("shell", "Shelly", "shell", [50, 50], 2, "accel", [["bone", 0.2, 1, 1], ["monster_shell", 0.25, 1, 1], ["monster_scale", 0.25, 1, 1], ["monster_horn", 0.1, 1, 1]], {"speed": 32})
	_mob("octopus", "Octopus", "octopus", [65, 65], 5, "accel", [["monster_horn", 0.2, 1, 1], ["herb", 0.2, 1, 1], ["monster_scale", 0.2, 1, 1], ["green_egg", 0.01, 1, 1]], {"jump": true})
	_mob("crusher", "Stone", "crusher", [999999, 999999], 1, "stone", [], {"invulnerable": true})
	_mob("trex", "Rexy", "trex", [450, 450], 7, "charge", [["antidote", 0.15, 1, 1], ["silver_key", 0.03, 1, 1], ["old_roots", 0.1, 1, 1], ["red_egg", 0.01, 1, 1], ["cavemun", 0.03, 1, 1], ["backstreet_boy", 0.03, 1, 1], ["halloween_mask", 0.01, 1, 1]], {"jump": true, "crit": 0.1, "speed": 36})
	_mob("dark_trex", "Dark Rexy", "dark_trex", [1050, 1050], 9, "charge", [["herb", 0.3, 1, 2], ["mana_potion", 0.15, 1, 1], ["potion", 0.15, 1, 1], ["cavemun", 0.04, 1, 1], ["backstreet_boy", 0.04, 1, 1], ["laser_gun", 0.01, 1, 1], ["halloween_mask", 0.01, 1, 1], ["sailor_moons", 0.01, 1, 1]], {"jump": true, "crit": 0.1, "speed": 36, "coins": [20, 60]})
	# Darklands
	_mob("dark_slime", "Dark Slime", "slime_dark", [125, 150], 7, "walk", [["herb", 0.3, 1, 1], ["jelly", 0.15, 1, 1]], {"jump": true, "status": ["poison", 0.1]})
	_mob("mantis", "Mantis", "mantis", [118, 183], 4, "accel", [["antidote_herb", 0.25, 1, 1], ["stink_bug", 0.25, 1, 1]], {"jump": true, "fast_hits": true})
	_mob("zombie", "Zombie", "zombie", [75, 75], 5, "charge", [["plant_roots", 0.3, 1, 1]], {"jump": true, "status": ["fatigue", 0.1]})
	_mob("ufo", "UFO", "ufo", [65, 65], 15, "fly", [["potion", 0.15, 1, 1], ["antidote_herb", 0.2, 1, 1], ["purple_egg", 0.008, 1, 1]], {"crit": 0.1, "speed": 44})
	_mob("worm", "Worm", "worm", [300, 500], 17, "walk", [["mana_potion", 0.2, 1, 1], ["antidote_herb", 0.2, 1, 1]], {"crit": 0.1, "speed": 22, "status": ["poison", 0.15]})
	_mob("hand", "Hand", "hand", [2214, 2214], 8, "accel", [["apple", 0.08, 1, 1], ["combo_book_3", 0.01, 1, 1], ["combo_book_4", 0.005, 1, 1], ["green_egg", 0.03, 1, 1], ["red_egg", 0.03, 1, 1], ["purple_egg", 0.02, 1, 1], ["knights_blade", 0.02, 1, 1], ["glow_blade_green", 0.01, 1, 1], ["combination_scroll", 0.05, 1, 1], ["silver_key", 0.08, 1, 1], ["golden_key", 0.03, 1, 1], ["legendary_roots", 0.03, 1, 1], ["bone", 0.4, 1, 3], ["sticky_bones", 0.15, 1, 1], ["dongle", 0.08, 1, 1], ["crystal", 0.3, 1, 2], ["school_girl", 0.02, 1, 1], ["pistol", 0.02, 1, 1], ["rolva", 0.02, 1, 1], ["firecracker_blade", 0.01, 1, 1], ["yellow_fluorescent_shield", 0.01, 1, 1], ["backstreet_boy", 0.02, 1, 1]], {"jump": true, "big_jump": true, "crit": 0.1, "speed": 38, "coins": [40, 120]})
	# Hell
	_mob("wizard", "Wizard", "wizard", [700, 800], 17, "wizard", [["crystal", 0.25, 1, 1], ["fire_crystal", 0.08, 1, 1], ["water_crystal", 0.08, 1, 1], ["earth_crystal", 0.08, 1, 1], ["dark_crystal", 0.08, 1, 1], ["potion", 0.12, 1, 1], ["mana_potion", 0.12, 1, 1]], {"speed": 24, "shoots": true})
	_mob("shadow", "Shadow", "shadow", [700, 1000], 27, "fly", [["dark_crystal", 0.1, 1, 1], ["small_evil_crystal", 0.03, 1, 1], ["pirate", 0.02, 1, 1]], {"status": ["poison", 0.15]})
	_mob("eyeball", "Eyeball", "eyeball", [1800, 2000], 46, "accel", [["dark_crystal", 0.15, 1, 1], ["small_evil_crystal", 0.05, 1, 1], ["bad_man", 0.02, 1, 1]], {"jump": true, "crit": 0.1, "status": ["poison", 0.2]})
	_mob("phantom", "Ghast", "phantom", [1500, 1500], 42, "fly", [["small_evil_crystal", 0.06, 1, 1], ["purple_egg", 0.01, 1, 1]], {"through": true, "status": ["slow", 0.3]})
	_mob("king", "King", "king", [10000, 10000], 29, "charge", [["pole_axe", 0.06, 1, 1], ["combo_book_3", 0.05, 1, 1], ["combo_book_4", 0.03, 1, 1], ["combo_book_5", 0.01, 1, 1], ["evil_apple", 0.03, 1, 1], ["silver_key", 0.25, 1, 1], ["golden_key", 0.12, 1, 1], ["king_egg", 0.03, 1, 1], ["golden_long_sword", 0.03, 1, 1], ["golden_armor", 0.04, 1, 1], ["combination_scroll", 0.15, 1, 1], ["cavemun", 0.03, 1, 1], ["pirate", 0.03, 1, 1], ["bad_man", 0.03, 1, 1], ["school_girl", 0.03, 1, 1], ["soldier", 0.03, 1, 1], ["the_spi", 0.02, 1, 1], ["chuchu", 0.02, 1, 1], ["drone", 0.02, 1, 1], ["steel_bow", 0.03, 1, 1], ["backstreet_boy", 0.03, 1, 1], ["halloween_mask", 0.02, 1, 1], ["robo_mask_2", 0.01, 1, 1]], {"jump": true, "heavy": true, "boss": true, "speed": 30, "coins": [300, 600]})
	_mob("queen", "Queen", "queen", [20000, 20000], 53, "charge", [["combo_book_3", 0.06, 1, 1], ["combo_book_4", 0.04, 1, 1], ["combo_book_5", 0.02, 1, 1], ["queen_egg", 0.05, 1, 1], ["armor_bug", 0.15, 1, 2], ["power_bug", 0.15, 1, 2], ["hero_bug", 0.03, 1, 1], ["evil_apple", 0.05, 1, 1], ["silver_key", 0.3, 1, 1], ["golden_key", 0.15, 1, 1], ["master_key", 0.03, 1, 1], ["green_seeds", 0.1, 1, 1], ["red_seeds", 0.05, 1, 1], ["golden_seeds", 0.02, 1, 1], ["fear_helmet", 0.03, 1, 1], ["hell_helmet", 0.03, 1, 1], ["witch_helmet", 0.03, 1, 1], ["armor_ring_5", 0.005, 1, 1], ["backstreet_boy", 0.03, 1, 1], ["sailor_moons", 0.02, 1, 1], ["long_sword", 0.04, 1, 1]], {"jump": true, "heavy": true, "boss": true, "speed": 32, "coins": [600, 1200]})
	# Ice Cavern
	_mob("tornado", "Tornado", "tornado", [8000, 8400], 57, "accel", [["erbium", 0.15, 1, 1], ["volcanic_ore", 0.01, 1, 1]], {"jump": true})
	_mob("tidal", "Tsunami", "tidal", [4000, 4400], 81, "accel", [["queen_egg", 0.005, 1, 1], ["water_crystal", 0.2, 1, 1], ["antidote_herb", 0.2, 1, 1], ["potion", 0.15, 1, 1], ["topaz_stone", 0.005, 1, 1]], {"jump": true})
	_mob("ice_bat", "Ice Bat", "ice_bat", [2900, 2900], 57, "fly", [["purple_egg", 0.01, 1, 1], ["erbium", 0.1, 1, 1], ["potion", 0.15, 1, 1], ["monster_horn", 0.2, 1, 1]], {"launch": true, "speed": 50, "status": ["cold", 0.2]})
	_mob("cloud", "Cloud", "cloud", [3000, 3000], 61, "fly", [["medium_potion", 0.12, 1, 1], ["water_crystal", 0.1, 1, 1], ["chuchu", 0.03, 1, 1]], {"speed": 36})
	_mob("butterfly", "Butterfly", "butterfly", [4200, 4200], 146, "fly", [["volcanic_ore", 0.01, 1, 1], ["erbium", 0.12, 1, 1], ["silver_ore", 0.2, 1, 1], ["gold_ore", 0.15, 1, 1]], {"speed": 46})
	_mob("empress", "Butterfly Boss", "empress", [72500, 72500], 141, "accel", [["em_stone", 0.06, 1, 1], ["ruby_stone", 0.06, 1, 1], ["sapphire_stone", 0.06, 1, 1], ["volcanic_ore", 0.15, 1, 2], ["herb", 0.5, 1, 3], ["monster_horn", 0.5, 1, 3], ["potion", 0.4, 1, 2], ["moon_blade", 0.05, 1, 1], ["moon_blade_2", 0.02, 1, 1], ["moon_blade_3", 0.01, 1, 1], ["master_key", 0.05, 1, 1], ["topaz_stone", 0.06, 1, 1], ["dark_stone", 0.03, 1, 1], ["moon_hat", 0.03, 1, 1], ["moon_hat_2", 0.02, 1, 1], ["heartstone_ring_3", 0.01, 1, 1], ["manastone_ring_3", 0.01, 1, 1], ["muscle_fire_ring_3", 0.01, 1, 1], ["shattered_souls_ring_3", 0.01, 1, 1], ["missing_page", 0.02, 1, 1], ["combo_book_z", 0.01, 1, 1]], {"jump": true, "heavy": true, "boss": true, "speed": 34, "coins": [2000, 4000]})
	# Ghost Arena
	_mob("ghost_1", "Ghost", "ghost_1", [2100, 2100], 68, "fly", [], {"through": true, "status": ["slow", 0.2]})
	_mob("ghost_2", "Ghost", "ghost_2", [4100, 4100], 88, "fly", [], {"through": true, "status": ["slow", 0.2]})
	_mob("ghost_lord", "Ghost Boss", "ghost_lord", [85000, 85000], 135, "fly", [["spectre_hood", 0.05, 1, 1], ["silver_key", 0.4, 1, 1], ["armor_ring", 0.08, 1, 1], ["armor_ring_2", 0.05, 1, 1], ["armor_ring_3", 0.03, 1, 1], ["armor_ring_4", 0.01, 1, 1], ["ring_of_attack", 0.02, 1, 1], ["devil_spike", 0.04, 1, 1], ["twin_sun", 0.05, 1, 1], ["living_flame", 0.1, 1, 1], ["combo_book_3", 0.06, 1, 1], ["combo_book_4", 0.04, 1, 1], ["combo_book_5", 0.02, 1, 1], ["combination_scroll", 0.2, 1, 1], ["dark_shield", 0.05, 1, 1], ["volcanic_ore", 0.15, 1, 1], ["healing_staff", 0.05, 1, 1], ["queen_egg", 0.03, 1, 1], ["bad_man", 0.04, 1, 1], ["drone", 0.04, 1, 1], ["pirate", 0.04, 1, 1], ["waazookaa_2", 0.02, 1, 1], ["halloween_mask", 0.05, 1, 1], ["giant_candy", 0.01, 1, 1], ["missing_page", 0.02, 1, 1], ["firecracker_blade", 0.03, 1, 1], ["firecracker_blade_2", 0.01, 1, 1], ["moon_blade_4", 0.01, 1, 1], ["ghost_dress", 0.005, 1, 1], ["halloween_egg", 0.03, 1, 1], ["pumpkin_saber_a", 0.03, 1, 1]], {"through": true, "heavy": true, "boss": true, "speed": 40, "coins": [3000, 6000]})
	# Modina Ruins, Nightmare Valley, Forbidden City, Snow Valley and the new arenas.
	# Damage is the wiki's; where it lists no health ("?") the health is a guess.
	var stones := [["em_stone", 0.05, 1, 1], ["ruby_stone", 0.05, 1, 1], ["sapphire_stone", 0.05, 1, 1]]
	var keys := [["silver_key", 0.3, 1, 1], ["golden_key", 0.15, 1, 1], ["master_key", 0.05, 1, 1]]
	_mob("slug", "Golden Slug", "slug", [1323, 1500], 65, "accel", [["mana_potion", 0.15, 1, 1], ["antidote_herb", 0.2, 1, 1], ["long_lance", 0.02, 1, 1], ["long_lance_2", 0.008, 1, 1], ["hell_spike", 0.004, 1, 1]], {"jump": true, "big_jump": true, "speed": 42})
	_mob("phantom_butterfly", "Phantom Butterfly", "phantom_butterfly", [2500, 2500], 77, "fly", [["silver_ore", 0.2, 1, 1], ["gold_ore", 0.15, 1, 1], ["erbium", 0.08, 1, 1], ["blue_blade", 0.02, 1, 1], ["hell_spike", 0.004, 1, 1], ["modina_dress", 0.004, 1, 1]], {"through": true, "speed": 40})
	_mob("demon_eye", "Demon Eye", "demon_eye", [3950, 3950], 91, "walk", [["green_seeds", 0.05, 1, 1], ["nightmare_ore", 0.03, 1, 1], ["gold_ore", 0.2, 1, 1], ["silver_ore", 0.2, 1, 1], ["dark_heart", 0.002, 1, 1]], {"speed": 12, "crit": 0.1})
	_mob("imp", "Demon Angel", "imp", [3000, 3200], 81, "accel", [["nightmare_ore", 0.03, 1, 1], ["dark_heart", 0.002, 1, 1], ["iron_ore", 0.3, 1, 1]], {"jump": true, "speed": 62})
	_mob("demon_bat", "Demon Bat", "demon_bat", [2500, 2500], 84, "fly", [["dark_heart", 0.002, 1, 1], ["silver_ore", 0.2, 1, 1], ["nightmare_ore", 0.03, 1, 1], ["king_egg", 0.005, 1, 1]], {"heavy": true, "speed": 52})
	_mob("an_an", "An An", "an_an", [4500, 4500], 81, "charge", [["iron_ore", 0.3, 1, 1], ["green_seeds", 0.05, 1, 1], ["fortune_mask", 0.005, 1, 1], ["forbidden_stone", 0.002, 1, 1], ["pet_an_an_jr", 0.002, 1, 1]], {"jump": true, "speed": 44})
	_mob("ji_ji", "Ji Ji", "ji_ji", [5500, 5500], 98, "charge", [["iron_ore", 0.3, 1, 1], ["green_seeds", 0.05, 1, 1], ["fortune_nugget", 0.01, 1, 1], ["forbidden_stone", 0.002, 1, 1], ["pet_ji_ji_jr", 0.002, 1, 1]], {"jump": true, "speed": 46})
	_mob("he_he", "He He", "he_he", [6500, 6500], 109, "charge", [["iron_ore", 0.3, 1, 1], ["green_seeds", 0.05, 1, 1], ["volcanic_ore", 0.01, 1, 1], ["forbidden_stone", 0.002, 1, 1], ["pet_he_he_jr", 0.002, 1, 1]], {"jump": true, "speed": 48})
	_mob("raven", "Raven", "raven", [4000, 4000], 99, "fly", [["iron_ore", 0.3, 1, 1], ["green_seeds", 0.05, 1, 1], ["volcanic_ore", 0.01, 1, 1], ["pet_ne_ne_jr", 0.002, 1, 1]], {"speed": 46})
	_mob("grinch", "Grinch", "grinch", [6000, 6000], 123, "accel", [["bone", 0.3, 1, 1], ["snowball", 0.3, 1, 1], ["erbium", 0.1, 1, 1]], {"jump": true})
	_mob("snow_turtle", "Snow Turtle", "snow_turtle", [7000, 7000], 121, "walk", [["bone", 0.3, 1, 1], ["snowball", 0.3, 1, 1], ["herb", 0.2, 1, 1], ["erbium", 0.06, 1, 1]], {"speed": 18, "heavy": true})
	_mob("lich", "Lich", "lich", [8000, 8000], 153, "wizard", [["bone", 0.3, 1, 1], ["snowball", 0.3, 1, 1], ["herb", 0.2, 1, 1], ["dress_of_lich_king", 0.003, 1, 1]], {"shoots": true, "speed": 22, "status": ["cold", 0.2]})
	_mob("fairy", "Fairy", "fairy", [6000, 6000], 143, "fly", [["bone", 0.3, 1, 1], ["snowball", 0.3, 1, 1], ["volcanic_ore", 0.01, 1, 1]], {"speed": 44})
	_mob("mango", "Mango", "mango", [9125, 9125], 57, "accel", [["herb", 0.3, 1, 1], ["honey", 0.05, 1, 1]], {"speed": 40})
	_mob("cherry", "Cherry", "cherry", [4125, 4125], 81, "walk", [["herb", 0.3, 1, 1], ["honey", 0.05, 1, 1]], {"jump": true, "speed": 34})
	_mob("pineapple", "Pineapple", "pineapple", [4125, 4125], 81, "charge", [["herb", 0.3, 1, 1], ["honey", 0.05, 1, 1]], {"jump": true, "speed": 44})
	_mob("strawberry", "Strawberry", "strawberry", [4125, 4125], 81, "accel", [["herb", 0.3, 1, 1], ["honey", 0.05, 1, 1]], {"speed": 60})
	_mob("egg_orange", "Cracked Egg", "egg_orange", [6000, 6000], 193, "accel", [["monster_shell", 0.3, 1, 1], ["eggency", 0.03, 1, 1]], {"jump": true, "speed": 42})
	_mob("egg_blue", "Cracked Egg", "egg_blue", [5500, 5500], 181, "accel", [["monster_shell", 0.3, 1, 1], ["eggency", 0.03, 1, 1]], {"jump": true, "speed": 56})
	_mob("egg_purple", "Cracked Egg", "egg_purple", [7000, 7000], 221, "accel", [["monster_shell", 0.3, 1, 1], ["eggency", 0.03, 1, 1]], {"speed": 38})
	_mob("egg_clutch", "Flying Egg Clutch", "egg_clutch", [5000, 5000], 201, "fly", [["monster_shell", 0.3, 1, 1], ["eggency", 0.03, 1, 1]], {"speed": 46})
	_mob("chick", "Chick", "chick", [5000, 5000], 201, "accel", [["monster_shell", 0.3, 1, 1], ["eggency", 0.03, 1, 1]], {"heavy": true, "speed": 52})
	_mob("giant_chick", "Giant Chick", "giant_chick", [8000, 8000], 195, "accel", [["monster_shell", 0.3, 1, 1], ["eggency", 0.03, 1, 1]], {"jump": true, "big_jump": true, "speed": 40})
	# bosses
	_mob("modina", "Modina", "modina", [72512, 72512], 103, "charge", stones + keys + [["long_lance_3", 0.02, 1, 1], ["hell_spike", 0.03, 1, 1], ["modina_1", 0.06, 1, 1], ["modina_2", 0.03, 1, 1], ["modina_dress", 0.05, 1, 1], ["modina_face", 0.04, 1, 1], ["modina_ring", 0.04, 1, 1], ["blue_blade", 0.15, 1, 2], ["hazard_wipe", 0.02, 1, 1], ["hell_sword", 0.01, 1, 1], ["healing_staff", 0.03, 1, 1], ["moon_blade", 0.04, 1, 1], ["moon_blade_2", 0.02, 1, 1], ["moon_blade_3", 0.01, 1, 1], ["golden_seeds", 0.03, 1, 1], ["herb", 0.5, 1, 3], ["bone", 0.5, 1, 3], ["monster_horn", 0.5, 1, 2], ["water_crystal", 0.3, 1, 1], ["apple", 0.2, 1, 1], ["coal", 0.5, 1, 3], ["old_roots", 0.2, 1, 1], ["legendary_roots", 0.05, 1, 1], ["pirate", 0.02, 1, 1], ["bad_man", 0.02, 1, 1], ["robo_mask", 0.03, 1, 1], ["robo_mask_2", 0.02, 1, 1], ["robo_mask_3", 0.01, 1, 1], ["mooncake", 0.1, 1, 1], ["moon_hat", 0.03, 1, 1], ["moon_hat_2", 0.02, 1, 1], ["heartstone_ring_3", 0.01, 1, 1], ["manastone_ring_3", 0.01, 1, 1], ["muscle_fire_ring_3", 0.01, 1, 1], ["shattered_souls_ring_3", 0.01, 1, 1], ["blood_long_sword_shield", 0.02, 1, 1], ["sapphire_long_sword", 0.03, 1, 1], ["topaz_stone", 0.03, 1, 1]], {"jump": true, "heavy": true, "boss": true, "speed": 36, "coins": [3000, 6000]})
	_mob("modina_2", "Modina 2", "modina_2", [42500, 42500], 143, "charge", stones + keys + [["hazard_wipe", 0.04, 1, 1], ["combo_book_5", 0.03, 1, 1], ["long_lance_3", 0.02, 1, 1], ["modina_2", 0.04, 1, 1], ["modina_3", 0.02, 1, 1], ["modina_dress", 0.05, 1, 1], ["modina_dress_2", 0.02, 1, 1], ["blue_blade", 0.2, 1, 2], ["golden_long_sword", 0.04, 1, 1], ["survival_token", 0.3, 1, 2], ["potion", 0.3, 1, 2]], {"jump": true, "heavy": true, "boss": true, "speed": 40, "coins": [4000, 8000]})
	_mob("doom", "Doom", "doom", [110000, 110000], 136, "accel", keys + [["nightmare_blade", 0.01, 1, 1], ["hell_sword", 0.02, 1, 1], ["volcanic_bar", 0.05, 1, 1], ["volcanic_ore", 0.1, 1, 2], ["hell_spike", 0.03, 1, 1], ["combination_scroll", 0.15, 1, 1], ["combo_book_3", 0.05, 1, 1], ["combo_book_4", 0.03, 1, 1], ["green_egg", 0.05, 1, 1], ["pink_egg", 0.05, 1, 1], ["queen_egg", 0.02, 1, 1], ["ring_of_attack", 0.03, 1, 1], ["nightmare_ore", 0.2, 1, 3], ["dark_heart", 0.02, 1, 1], ["evil_axe", 0.02, 1, 1], ["hell_sword_shield", 0.02, 1, 1], ["evil_axe_shield", 0.02, 1, 1], ["heartstone_ring_4", 0.005, 1, 1], ["manastone_ring_4", 0.005, 1, 1], ["muscle_fire_ring_4", 0.005, 1, 1], ["shattered_souls_ring_4", 0.005, 1, 1], ["ring_of_magic", 0.03, 1, 1], ["blue_egg", 0.03, 1, 1]], {"jump": true, "heavy": true, "boss": true, "speed": 30, "coins": [5000, 10000]})
	_mob("fortune_boss", "Fortune Boss", "fortune_boss", [118261, 118261], 159, "charge", keys + [["forbidden_stone", 0.05, 1, 1], ["dark_shield", 0.05, 1, 1], ["combination_scroll", 0.15, 1, 1], ["fortune_nugget", 0.15, 1, 2], ["fortune_mask", 0.03, 1, 1], ["ring_of_attack", 0.03, 1, 1], ["king_egg", 0.03, 1, 1], ["bad_man", 0.03, 1, 1], ["drone", 0.03, 1, 1], ["pirate", 0.03, 1, 1], ["survival_token", 0.3, 1, 2], ["golden_long_sword", 0.04, 1, 1], ["devil_spike", 0.04, 1, 1], ["armor_ring", 0.05, 1, 1], ["jade_ring", 0.05, 1, 1], ["ring_of_attack_2", 0.02, 1, 1], ["ring_of_magic_2", 0.02, 1, 1], ["muscle_fire_ring_4", 0.005, 1, 1], ["sailor_moons", 0.03, 1, 1], ["pet_he_he", 0.01, 1, 1], ["pet_an_an", 0.01, 1, 1], ["pet_ji_ji", 0.01, 1, 1], ["pet_ne_ne", 0.01, 1, 1]], {"jump": true, "heavy": true, "boss": true, "speed": 38, "coins": [6000, 12000]})
	_mob("evil_santa", "Evil Santa", "evil_santa", [125000, 125000], 164, "charge", stones + keys + [["santa_blade", 0.03, 1, 1], ["dress_of_lich_king", 0.02, 1, 1], ["nightmare_ore", 0.1, 1, 2], ["volcanic_ore", 0.1, 1, 2], ["erbium", 0.4, 1, 3], ["legendary_roots", 0.05, 1, 1], ["combo_book_5", 0.03, 1, 1], ["healing_staff", 0.03, 1, 1], ["moon_blade_3", 0.02, 1, 1], ["herb", 0.5, 1, 3], ["robo_mask", 0.03, 1, 1], ["robo_mask_2", 0.02, 1, 1], ["robo_mask_4", 0.01, 1, 1], ["robo_mask_z", 0.005, 1, 1], ["robo_mask_zx", 0.003, 1, 1], ["heartstone_ring_2", 0.01, 1, 1], ["manastone_ring_2", 0.01, 1, 1], ["muscle_fire_ring_2", 0.01, 1, 1], ["shattered_souls_ring_2", 0.01, 1, 1], ["sun_extractor", 0.02, 1, 1], ["mooncake", 0.1, 1, 1], ["popstick", 0.03, 1, 1], ["red_dream_sword", 0.02, 1, 1], ["combo_book_z", 0.02, 1, 1], ["combo_book_zx", 0.01, 1, 1], ["missing_page", 0.02, 1, 1], ["missing_page_u", 0.01, 1, 1], ["snowman_hat", 0.02, 1, 1], ["christmas_egg", 0.03, 1, 1], ["candy_stick_red", 0.02, 1, 1], ["candy_stick_green", 0.02, 1, 1], ["christmas_tree", 0.03, 1, 1], ["snow_maker", 0.02, 1, 1], ["giant_snow_ball", 0.02, 1, 1], ["topaz_stone", 0.03, 1, 1]], {"jump": true, "heavy": true, "boss": true, "speed": 38, "coins": [6000, 12000]})
	_mob("pineapple_killer", "Pineapple Killer", "pineapple_killer", [72512, 72512], 113, "charge", stones + keys + [["honey", 0.4, 1, 3], ["potion", 0.3, 1, 2], ["herb", 0.5, 1, 3], ["golden_seeds", 0.03, 1, 1], ["hell_sword", 0.01, 1, 1], ["devil_spike", 0.03, 1, 1], ["long_sword", 0.05, 1, 1], ["golden_long_sword", 0.03, 1, 1], ["moon_blade", 0.04, 1, 1], ["hazard_wipe", 0.02, 1, 1], ["erbium", 0.2, 1, 3], ["volcanic_ore", 0.08, 1, 1], ["survival_token", 0.3, 1, 2], ["sky_pole_axe", 0.03, 1, 1], ["volcan_sword", 0.02, 1, 1], ["volcan_longsword", 0.01, 1, 1], ["moon_hat", 0.03, 1, 1], ["sapphire_long_sword", 0.03, 1, 1], ["sapphire_long_sword_shield", 0.02, 1, 1], ["blood_long_sword_shield", 0.02, 1, 1], ["heartstone_ring_2", 0.01, 1, 1], ["manastone_ring_2", 0.01, 1, 1], ["shattered_souls_ring_2", 0.01, 1, 1], ["muscle_fire_ring_2", 0.01, 1, 1], ["robo_mask", 0.03, 1, 1], ["robo_mask_4", 0.01, 1, 1], ["missing_page_u", 0.01, 1, 1], ["sun_extractor", 0.02, 1, 1], ["popstick", 0.03, 1, 1], ["chocolate_pops", 0.02, 1, 1], ["red_bean_pops", 0.01, 1, 1], ["rocket_pops", 0.005, 1, 1], ["hero_bug", 0.05, 1, 1]], {"jump": true, "heavy": true, "boss": true, "speed": 40, "coins": [3000, 6000]})
	_mob("harakattu", "Harakattu", "harakattu", [172512, 172512], 201, "accel", stones + [["ring_of_magic", 0.04, 1, 1], ["sandy_armor", 0.04, 1, 1], ["eggency", 0.4, 1, 3], ["bone", 0.5, 1, 3], ["power_bug", 0.1, 1, 1], ["armor_bug", 0.1, 1, 1], ["hero_bug", 0.03, 1, 1], ["dark_armor", 0.03, 1, 1], ["potion", 0.3, 1, 2], ["mana_potion", 0.3, 1, 2], ["erbium", 0.2, 1, 3], ["dark_knight", 0.02, 1, 1], ["soldier", 0.03, 1, 1], ["pirate", 0.03, 1, 1], ["silver_key", 0.3, 1, 1], ["easter_egg", 0.03, 1, 1], ["king_carrot", 0.02, 1, 1]], {"jump": true, "big_jump": true, "heavy": true, "boss": true, "speed": 46, "coins": [8000, 16000]})
	# Tomb of Makara. Damage is the wiki's; where it lists no health the health is a guess.
	var tomb := [["sandnite_ore", 0.04, 1, 1], ["gold_ore", 0.2, 1, 1], ["potion", 0.15, 1, 1], ["medium_potion", 0.08, 1, 1], ["blue_moon", 0.15, 1, 1],
		["stink_bug", 0.15, 1, 1], ["power_bug", 0.03, 1, 1], ["volcanic_ore", 0.01, 1, 1], ["erbium", 0.08, 1, 1], ["crystal", 0.2, 1, 1]]
	_mob("tomb_worm", "Worm", "worm", [6000, 6000], 209, "walk", tomb, {"crit": 0.1, "speed": 26, "status": ["poison", 0.15]})
	_mob("tomb_ufo", "UFO", "ufo", [4750, 4750], 190, "fly", tomb, {"crit": 0.1, "speed": 48})
	_mob("sand_mantis", "Sand Mantis", "sand_mantis", [5000, 5500], 195, "accel", tomb, {"jump": true, "fast_hits": true, "speed": 40})
	# the tombstones speed up the longer they slide one way, and never jump
	_mob("tombstone", "Tombstone", "tombstone", [7000, 7000], 207, "accel", tomb, {"heavy": true, "speed": 46})
	# the Vampire one-shots most players and flies fast
	_mob("vampire", "Vampire", "vampire", [5500, 5500], 777, "fly", tomb + [["topaz_stone", 0.01, 1, 1]], {"speed": 60})
	_mob("makara", "Makara", "makara", [200000, 200000], 184, "charge", stones + keys + [["bone_of_makara", 0.15, 1, 1], ["skin_of_makara", 0.15, 1, 1], ["treasure_of_makara", 0.05, 1, 1],
		["topaz_stone", 0.1, 1, 1], ["dark_stone", 0.03, 1, 1], ["blade_of_emperor", 0.02, 1, 1], ["sandnite_ore", 0.4, 1, 3], ["volcanic_ore", 0.15, 1, 2], ["combination_scroll", 0.15, 1, 1]],
		{"jump": true, "big_jump": true, "heavy": true, "boss": true, "speed": 40, "coins": [8000, 16000]})
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
	"town": {"name": "Pixel Town", "kind": "town", "theme": "grass"},
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
		"hp": {"dark_slime": [125, 130], "trex": [462, 462], "worm": [358, 362]},
		"mobs": [["dark_slime", 5], ["mantis", 4], ["zombie", 3], ["ufo", 3], ["worm", 2], ["trex", 1], ["hand", 1]],
		"nodes": [["tree", 4], ["blue_tree", 2], ["copper", 3], ["silver", 2], ["iron", 2], ["gold", 2], ["erbium_rock", 1]]},
	"dark_2": {"name": "Darklands 2", "kind": "explore", "theme": "dark", "count": 46, "chest": true, "mult": 1.5,
		"hp": {"dark_slime": [125, 130], "trex": [462, 462], "worm": [358, 362]},
		"mobs": [["dark_slime", 4], ["mantis", 4], ["zombie", 3], ["ufo", 3], ["worm", 3], ["trex", 1], ["hand", 2]],
		"nodes": [["tree", 3], ["blue_tree", 2], ["copper", 2], ["silver", 3], ["iron", 2], ["gold", 2], ["erbium_rock", 2]]},
	"hell_1": {"name": "Hell 1", "kind": "explore", "theme": "hell", "next": "hell_2", "count": 44, "chest": true, "status": ["poison", 0.12],
		"hp": {"mantis": [250, 300], "worm": [300, 500], "hand": [900, 1100]},
		"mobs": [["mantis", 4], ["worm", 3], ["wizard", 3], ["shadow", 3], ["eyeball", 2], ["hand", 2, 1.0, 4.75], ["king", 0.3], ["queen", 0.2]],
		"nodes": [["vase", 3], ["iron", 2], ["silver", 2], ["gold", 2], ["erbium_rock", 3]]},
	"hell_2": {"name": "Hell 2", "kind": "explore", "theme": "hell", "count": 46, "chest": true, "status": ["poison", 0.12],
		"hp": {"shadow": [1400, 1400], "hand": [2000, 2000], "dark_trex": [50000, 50000]},
		"mobs": [["eyeball", 3], ["shadow", 3, 1.0, 1.7], ["phantom", 3], ["hand", 3, 1.0, 6.5], ["queen", 0.2], ["queen", 0.1, 1.25, 1.47], ["queen", 0.1, 1.5, 1.55], ["dark_trex", 0.3, 1.0, 6.3]],
		"nodes": [["vase", 3], ["iron", 2], ["silver", 2], ["gold", 3], ["erbium_rock", 4]]},
	"ice_cavern": {"name": "Ice Cavern", "kind": "explore", "theme": "ice", "count": 40,
		"mobs": [["tornado", 2], ["tidal", 3], ["ice_bat", 3], ["cloud", 3], ["butterfly", 2], ["queen", 0.3, 1.5, 1.55], ["empress", 0.15]],
		"nodes": [["ice_rock", 4], ["silver", 2], ["gold", 2], ["erbium_rock", 2]]},
	"grass_arena": {"name": "Grasslands Arena", "kind": "arena", "theme": "grass", "cap": 8,
		"mobs": [["slime", 4, 1.23], ["wisp", 2, 1.67], ["mummy", 2], ["shell", 2]],
		"bosses": [["trex", 2.22, 1.0], ["hand", 0.565, 1.0]],
		"boss_drops": [["cavemun", 0.05, 1, 1], ["combo_book_2", 0.06, 1, 1], ["combo_book_3", 0.02, 1, 1], ["iron_sword_cast", 0.1, 1, 1], ["silver_key", 0.25, 1, 1], ["small_mana_potion", 0.3, 1, 2], ["small_potion", 0.3, 1, 2], ["wooden_helmet", 0.1, 1, 1], ["moon_blade", 0.02, 1, 1], ["weak_bow", 0.06, 1, 1], ["bow", 0.04, 1, 1], ["faceguard", 0.05, 1, 1], ["crystal", 0.3, 1, 2], ["jade_ring", 0.02, 1, 1], ["big_rejuvenate_potion", 0.05, 1, 1]]},
	"dark_arena": {"name": "Darklands Arena", "kind": "arena", "theme": "dark", "cap": 9,
		"mobs": [["dark_slime", 3], ["mantis", 3], ["zombie", 2], ["ufo", 2], ["worm", 2], ["octopus", 2, 2.0, 1.5]],
		"bosses": [["dark_trex", 4.76, 1.78], ["hand", 2.26, 1.75], ["king", 0.5, 0.52]], "bosses_pick": 2,
		"mob_drops": [["herb", 0.15, 1, 1], ["antidote_herb", 0.1, 1, 1], ["stink_bug", 0.1, 1, 1], ["small_potion", 0.06, 1, 1], ["monster_horn", 0.08, 1, 1]],
		"boss_drops": [["cavemun", 0.05, 1, 1], ["crazy_cannon_1", 0.02, 1, 1], ["small_potion", 0.3, 1, 2], ["silver_key", 0.3, 1, 1], ["golden_key", 0.08, 1, 1], ["excalibur", 0.03, 1, 1], ["combination_scroll", 0.1, 1, 1], ["combo_book_3", 0.04, 1, 1], ["big_rejuvenate_potion", 0.06, 1, 1], ["bow", 0.05, 1, 1], ["copper_sword_cast", 0.08, 1, 1], ["gold_sword_cast", 0.06, 1, 1], ["green_seeds", 0.1, 1, 1], ["jade_ring", 0.04, 1, 1], ["armor_ring", 0.04, 1, 1], ["crystal", 0.3, 1, 3], ["pole_axe", 0.04, 1, 1], ["healing_staff", 0.03, 1, 1], ["rooster_dress", 0.03, 1, 1], ["copper_helmet", 0.06, 1, 1], ["golden_armor", 0.03, 1, 1], ["magic_wand", 0.05, 1, 1]]},
	"hell_arena": {"name": "Hell Arena", "kind": "arena", "theme": "hell", "cap": 9,
		"mobs": [["mantis", 3, 2.0, 1.5], ["worm", 2, 1.2, 1.3], ["wizard", 2, 1.2, 1.3], ["shadow", 2, 1.2, 1.3], ["eyeball", 1, 1.1, 1.3], ["hand", 2, 0.5, 5.5]],
		"bosses": [["king", 2.0, 1.48], ["queen", 1.25, 1.47]],
		"mob_drops": [["fire_crystal", 0.06, 1, 1], ["earth_crystal", 0.06, 1, 1], ["dark_crystal", 0.06, 1, 1], ["small_mana_potion", 0.06, 1, 1], ["medium_mana_potion", 0.03, 1, 1], ["rejuvenate_potion", 0.03, 1, 1], ["healing_staff_2", 0.003, 1, 1]],
		"boss_drops": [["pirate", 0.03, 1, 1], ["bad_man", 0.03, 1, 1], ["school_girl", 0.03, 1, 1], ["soldier", 0.03, 1, 1], ["the_spi", 0.02, 1, 1], ["chuchu", 0.02, 1, 1], ["drone", 0.02, 1, 1], ["cavemun", 0.03, 1, 1], ["fire_crystal", 0.2, 1, 2], ["earth_crystal", 0.2, 1, 2], ["dark_crystal", 0.2, 1, 2], ["medium_mana_potion", 0.2, 1, 1], ["rejuvenate_potion", 0.2, 1, 1], ["healing_staff_2", 0.02, 1, 1], ["combo_book_4", 0.05, 1, 1], ["combo_book_5", 0.02, 1, 1], ["master_key", 0.06, 1, 1], ["sapphire_stone", 0.03, 1, 1], ["moon_blade_3", 0.01, 1, 1], ["fear_helmet", 0.05, 1, 1], ["hell_helmet", 0.05, 1, 1], ["dark_shield", 0.06, 1, 1], ["dark_armor", 0.04, 1, 1], ["jelly_armor", 0.05, 1, 1], ["golden_armor", 0.05, 1, 1], ["sandy_armor", 0.02, 1, 1], ["knight_shield", 0.1, 1, 1]]},
	"dream_arena": {"name": "Dream Arena", "kind": "arena", "theme": "dream", "cap": 10,
		"mobs": [["mantis", 2], ["shadow", 2, 1.0, 1.7], ["worm", 2, 1.0, 1.6], ["eyeball", 1, 1.0, 1.5], ["wizard", 2, 1.0, 1.5], ["hand", 2, 0.45, 8.0]],
		"bosses": [["king", 2.0, 1.48], ["queen", 1.25, 1.47], ["empress", 0.93, 0.74]], "bosses_pick": 2,
		"boss_drops": [["pirate", 0.05, 1, 1], ["bad_man", 0.05, 1, 1], ["school_girl", 0.05, 1, 1], ["silver_key", 0.3, 1, 1], ["golden_key", 0.15, 1, 1], ["master_key", 0.06, 1, 1], ["glow_blade_blue", 0.04, 1, 1], ["bow", 0.05, 1, 1], ["big_rejuvenate_potion", 0.1, 1, 1], ["devil_spike", 0.02, 1, 1], ["volcanic_ore", 0.1, 1, 1], ["em_stone", 0.04, 1, 1], ["ruby_stone", 0.04, 1, 1], ["sapphire_stone", 0.04, 1, 1], ["dragon_dress", 0.005, 1, 1]]},
	"ghost_arena": {"name": "Ghost Arena", "kind": "arena", "theme": "ghost", "cap": 8,
		"mobs": [["ghost_1", 3], ["ghost_2", 2]],
		"bosses": [["ghost_lord", 1.0, 1.0]],
		"boss_drops": [["dark_knight", 0.03, 1, 1], ["waazookaa_3", 0.01, 1, 1], ["crazy_cannon_3", 0.01, 1, 1]]},
	# the later worlds. mobs: [mob, weight, health multiplier, damage multiplier], so the
	# Shadow, Ghast, Queen and the rest hit as hard here as the wiki says
	"modina_ruins": {"name": "Modina Ruins", "kind": "explore", "theme": "modina", "count": 46, "chest": true,
		"mobs": [["shadow", 3, 1.0, 1.7], ["phantom", 3, 1.17, 1.0], ["eyeball", 2, 1.05, 0.93], ["wizard", 2], ["slug", 3], ["phantom_butterfly", 2], ["dark_trex", 0.3, 36.0, 6.3], ["queen", 0.3, 1.5, 1.55], ["modina", 0.15]],
		"nodes": [["vase", 3], ["iron", 2], ["silver", 3], ["gold", 3], ["erbium_rock", 3]]},
	"nightmare_valley": {"name": "Nightmare Valley", "kind": "explore", "theme": "nightmare", "count": 48, "chest": true,
		"mobs": [["wizard", 2], ["slug", 2], ["phantom_butterfly", 2], ["demon_eye", 3], ["imp", 3], ["demon_bat", 3], ["queen", 0.25, 1.5, 1.55], ["modina", 0.1], ["empress", 0.1], ["doom", 0.1]],
		"nodes": [["vase", 3], ["silver", 2], ["gold", 2], ["erbium_rock", 3], ["volcanic_rock", 2]]},
	"forbidden_city": {"name": "Forbidden City", "kind": "explore", "theme": "forbidden", "count": 48, "chest": true,
		"mobs": [["wizard", 2], ["an_an", 3], ["ji_ji", 3], ["he_he", 2], ["raven", 3], ["demon_bat", 2], ["queen", 0.2, 1.5, 1.55], ["modina", 0.1], ["empress", 0.1], ["fortune_boss", 0.1]],
		"nodes": [["vase", 3], ["silver", 2], ["gold", 2], ["erbium_rock", 3], ["volcanic_rock", 2]]},
	"snow_valley": {"name": "Snow Valley", "kind": "explore", "theme": "snow", "count": 48, "chest": true, "def_penalty": [160, 40],
		"mobs": [["wizard", 2, 2.6, 4.9], ["grinch", 3], ["snow_turtle", 3], ["lich", 2], ["fairy", 3], ["queen", 0.2, 1.75, 1.55], ["modina_2", 0.1], ["fortune_boss", 0.08], ["evil_santa", 0.08]],
		"nodes": [["ice_rock", 3], ["silver", 2], ["gold", 2], ["erbium_rock", 3], ["volcanic_rock", 1]]},
	# An enclosed maze under the sand. Some of its walls kill on touch, you need at least
	# 8 stamina to enter, and like Snow Valley its monsters hit 40 harder below 160 defense
	# (the wiki says "probably"). Dark Rexy (50k) and King (30k) health are the wiki's.
	"tomb_of_makara": {"name": "Tomb of Makara", "kind": "explore", "theme": "tomb", "maze": true, "count": 46, "chest": true, "def_penalty": [160, 40], "min_st": 8,
		"mobs": [["tomb_worm", 3], ["tomb_ufo", 3], ["sand_mantis", 3], ["tombstone", 3], ["vampire", 1], ["dark_trex", 0.3, 47.6, 6.3], ["king", 0.3, 3.0, 3.0], ["makara", 0.12]],
		"nodes": [["vase", 3], ["stone", 2], ["gold", 2], ["erbium_rock", 2], ["volcanic_rock", 1], ["sandnite_rock", 3]]},
	"mushroom_valley": {"name": "Mushroom Valley", "kind": "arena", "theme": "mushroom", "cap": 9,
		"mobs": [["slug", 4, 1.0, 1.2], ["phantom_butterfly", 3]],
		"bosses": [["modina", 1.0, 1.0]],
		"boss_drops": [["hazard_wipe", 0.03, 1, 1], ["modina_dress", 0.05, 1, 1], ["blue_blade", 0.2, 1, 2]]},
	"fruit_loop": {"name": "Fruit Loop", "kind": "arena", "theme": "fruit", "cap": 9,
		"mobs": [["mango", 2], ["cherry", 3], ["pineapple", 3], ["strawberry", 3]],
		"bosses": [["pineapple_killer", 1.0, 1.0]],
		"boss_drops": [["honey", 0.5, 1, 3]]},
	"eggcellence": {"name": "Eggcellence", "kind": "arena", "theme": "egg", "cap": 10, "def_penalty": [99999, 40],
		"mobs": [["egg_orange", 3], ["egg_blue", 2], ["egg_purple", 2], ["egg_clutch", 2], ["chick", 2], ["giant_chick", 1]],
		"bosses": [["harakattu", 1.0, 1.0]],
		"boss_drops": [["eggency", 0.5, 1, 3], ["dark_stone", 0.1, 1, 1]]},
	"survival": {"name": "Survival Grasslands", "kind": "survival", "theme": "grass", "needs": "survival_access"},
}
# The Gatekeeper offers these. Deeper levels are reached through portals inside each world.
const WORLD_MENU := [["Exploration", ["grass_1", "dark_1", "hell_1", "ice_cavern", "modina_ruins", "nightmare_valley", "forbidden_city", "snow_valley", "tomb_of_makara"]],
	["Arena", ["grass_arena", "dark_arena", "hell_arena", "dream_arena", "ghost_arena", "mushroom_valley", "fruit_loop", "eggcellence"]],
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
# Surviving this many nights in Survival Grasslands earns the Wall Hammer (the wiki
# says it's a Survival reward but not which day, so the day is an estimate).
const WALL_HAMMER_DAY := 10

func survival_tokens(day: int) -> int:
	if day <= 1: return 0
	if day <= 4: return 1
	if day <= 10: return 2
	if day <= 28: return 3
	if day <= 40: return 4
	return 5

# ---------------------------------------------------------------- village
var NPCS := {
	"keeper": {"name": "Gatekeeper", "look": "keeper", "talk": "Which world do you want to explore? I'll open a portal for you."},
	"gruff": {"name": "Brutus", "look": "gruff", "talk": "Bring me a Wood Wall and I'll show you how to survive out there."},
	"mira": {"name": "Miffie", "look": "mira", "talk": "I always need things collected. Help me and I'll make it worth your while!"},
	"warden": {"name": "GateKeeper", "look": "warden", "talk": "Nobody gets to the furnaces without bringing me a Pretzel."},
	"smith": {"name": "Crafter", "look": "smith", "talk": "Bring me materials and I'll make anything on my list. No luck needed."},
	"merchant": {"name": "Merchant", "look": "merchant", "talk": "Buying and selling, best prices in town!"},
	"tools": {"name": "Plumber", "look": "tools", "talk": "Lost your tools? I've got spares."},
	"miner": {"name": "Miner", "look": "miner", "talk": "Survival Tokens! I'll trade seeds and keys for them."},
	"jumpie": {"name": "Jumpie", "look": "jumpie", "talk": "Hi! I'm collecting jelly too."},
	"warden_hell": {"name": "GateKeeper", "look": "warden", "talk": "Em Stones, for those who helped me."},
	# under Pixel Town, behind the east stone wall
	"nini": {"name": "Nini", "look": "ninja_npc", "talk": "Shh... the Tsurugi can be made sharper. Help me first."},
	"nana": {"name": "Nana", "look": "ninja_npc2", "talk": "Bring me what I ask, and your blade will sing."},
	"nina": {"name": "Nina", "look": "ninja_npc3", "talk": "Only the strongest Tsurugi reaches me."},
	"fc_9912": {"name": "FC 9912", "look": "robot_npc", "talk": "BEEP. IRON FIST UPGRADE PROTOCOL READY."},
	"tt_1001": {"name": "TT 1001", "look": "robot_npc2", "talk": "BOOP. MORE MATERIALS REQUIRED."},
	"oop_2219": {"name": "2219 OOP", "look": "robot_npc3", "talk": "ERROR 2219. JUST KIDDING. UPGRADES AVAILABLE."},
	"trader": {"name": "Trader", "look": "trader", "talk": "Welcome to the Trading Center! Stand at a trading table to swap items with a friend in your room. Both of you put up your items, both press Ready, and the trade happens."},
}

# Quests are done in order per villager.
var QUESTS := [
	{"id": "gruff_1", "npc": "gruff", "need": {"wood_wall": 1}, "reward": {"survival_book": 1}, "unlock": "survival_access",
		"text": "Make a Wood Wall (Wood + Rock in the combination slots) and give it to me. You'll get the Survival Book and access to Survival Grasslands."},
	{"id": "warden_1", "npc": "warden", "need": {"pretzel": 1}, "reward": {}, "unlock": "furnaces",
		"text": "Bring me a Pretzel (Honey Bug + Herb, from Combo Book I) and I'll open the gate to the furnaces."},
	# Miffie's questline in the original's order. Gems don't exist here, so quests
	# that gave gems give that many Silver Keys instead.
	{"id": "mira_1", "npc": "mira", "need": {"jelly": 10}, "reward": {"combo_book_1": 1}, "text": "Could you bring me 10 Jellies? Slimes in the Grasslands drop them."},
	{"id": "mira_2", "npc": "mira", "need": {"jelly": 50}, "reward": {"combo_book_2": 1}, "text": "More jelly! 50 this time."},
	{"id": "mira_3", "npc": "mira", "need": {"copper_bar": 10}, "take": {"copper_bar": 5}, "reward": {"gilded_blade": 1}, "text": "Bring me 10 Copper Bars from the furnace."},
	{"id": "mira_4", "npc": "mira", "need": {"iron_bar": 10}, "take": {"iron_bar": 5}, "reward": {"azure_blade": 1}, "text": "Now 10 Iron Bars, please."},
	{"id": "mira_5", "npc": "mira", "need": {"nail": 50}, "reward": {"silver_key": 1}, "text": "I need 50 Nails."},
	{"id": "mira_6", "npc": "mira", "need": {"gilded_blade": 1}, "reward": {"silver_key": 1}, "text": "Could I have a Golden Night?"},
	{"id": "mira_7", "npc": "mira", "need": {"catalyst": 10}, "reward": {"silver_key": 1}, "text": "10 Catalysts, please."},
	{"id": "mira_8", "npc": "mira", "need": {"crystal": 10}, "reward": {"brass_helmet": 1}, "text": "Bring me 10 Crystals."},
	{"id": "mira_9", "npc": "mira", "need": {"scarab": 99}, "reward": {"pirate": 1}, "text": "99 Scarabs. I know, I know."},
	{"id": "mira_10", "npc": "mira", "need": {"stink_bug": 99}, "reward": {"bad_man": 1}, "text": "99 Stink Bugs. Hold your nose."},
	{"id": "mira_11", "npc": "mira", "need": {"honey_bug": 99}, "reward": {"pirate": 1}, "text": "99 Honey Bugs."},
	{"id": "mira_12", "npc": "mira", "need": {"fire_bug": 99}, "reward": {"soldier": 1}, "text": "99 Fire Bugs."},
	{"id": "mira_13", "npc": "mira", "need": {"gold_shield": 1}, "reward": {"silver_key": 1}, "text": "I'd love a Gold Shield."},
	{"id": "mira_14", "npc": "mira", "need": {"dust": 1000}, "reward": {"silver_key": 5}, "text": "Dust! I need 1000 Dust."},
	{"id": "mira_15", "npc": "mira", "need": {"silver_bar": 25}, "reward": {"master_key": 1}, "text": "25 Silver Bars."},
	{"id": "mira_16", "npc": "mira", "need": {"jelly": 99}, "reward": {"alien_hat": 1}, "text": "99 Jellies, for old times' sake."},
	{"id": "mira_17", "npc": "mira", "need": {"living_flame": 10}, "reward": {"purple_egg": 1}, "text": "10 Firas from the furnace."},
	{"id": "mira_18", "npc": "mira", "need": {"stink_bug": 99}, "reward": {"silver_key": 2}, "text": "99 Stink Bugs again."},
	{"id": "mira_19", "npc": "mira", "need": {"scarab": 99}, "reward": {"silver_key": 3}, "text": "99 Scarabs again."},
	{"id": "mira_20", "npc": "mira", "need": {"fire_bug": 99}, "reward": {"combo_book_3": 1}, "text": "99 more Fire Bugs and you'll get Combo Book III."},
	{"id": "mira_21", "npc": "mira", "need": {"dust": 1000}, "reward": {"master_key": 3}, "text": "1000 Dust, one more time."},
	{"id": "mira_22", "npc": "mira", "need": {"gold_bar": 50}, "reward": {"master_key": 3}, "text": "50 Gold Bars."},
	{"id": "mira_23", "npc": "mira", "need": {"erbium_bar": 50}, "reward": {"master_key": 3}, "text": "50 Erbium Bars."},
	{"id": "mira_24", "npc": "mira", "need": {"dark_bar": 50}, "reward": {"master_key": 3}, "text": "50 Dark Bars."},
	{"id": "mira_25", "npc": "mira", "need": {"light_bar": 50}, "reward": {"master_key": 3}, "text": "50 Light Bars."},
	{"id": "mira_26", "npc": "mira", "need": {"hell_bar": 50}, "reward": {"master_key": 3}, "text": "50 Hell Bars."},
	{"id": "mira_27", "npc": "mira", "need": {"evil_bar": 50}, "reward": {"master_key": 3}, "text": "50 Evil Bars."},
	{"id": "jumpie_1", "npc": "jumpie", "need": {"jelly": 10}, "reward": {}, "coins": 1, "text": "Could you bring me 10 Jellies? I'll give you a Pixel Coin!"},
	# the ninjas under Pixel Town (Tsurugi upgrades; the last quest of each upgrades the blade)
	{"id": "nini_1", "npc": "nini", "need": {"monster_scale": 99}, "reward": {"iron_bar": 1}, "text": "99 Monster Scales."},
	{"id": "nini_2", "npc": "nini", "need": {"monster_horn": 99}, "reward": {"iron_bar": 1}, "text": "99 Monster Horns."},
	{"id": "nini_3", "npc": "nini", "need": {"monster_leather": 99}, "reward": {"iron_bar": 1}, "text": "99 Monster Leathers."},
	{"id": "nini_4", "npc": "nini", "need": {"antidote_herb": 99}, "reward": {"iron_bar": 1}, "text": "99 Antidote Herbs."},
	{"id": "nini_5", "npc": "nini", "need": {"old_roots": 99}, "reward": {"iron_bar": 1}, "text": "99 Old Roots."},
	{"id": "nini_6", "npc": "nini", "need": {"tsurugi": 1}, "reward": {"tsurugi_2": 1}, "text": "Now give me your Tsurugi."},
	{"id": "nana_1", "npc": "nana", "need": {"copper_bar": 99}, "reward": {"survival_token": 5}, "text": "99 Copper Bars."},
	{"id": "nana_2", "npc": "nana", "need": {"iron_bar": 99}, "reward": {"survival_token": 5}, "text": "99 Iron Bars."},
	{"id": "nana_3", "npc": "nana", "need": {"silver_bar": 99}, "reward": {"survival_token": 5}, "text": "99 Silver Bars."},
	{"id": "nana_4", "npc": "nana", "need": {"gold_bar": 99}, "reward": {"survival_token": 5}, "text": "99 Gold Bars."},
	{"id": "nana_5", "npc": "nana", "need": {"erbium_bar": 99}, "reward": {"survival_token": 5}, "text": "99 Erbium Bars."},
	{"id": "nana_6", "npc": "nana", "need": {"dark_bar": 99}, "reward": {"survival_token": 5}, "text": "99 Dark Bars."},
	{"id": "nana_7", "npc": "nana", "need": {"light_bar": 99}, "reward": {"survival_token": 5}, "text": "99 Light Bars."},
	{"id": "nana_8", "npc": "nana", "need": {"hell_bar": 99}, "reward": {"survival_token": 5}, "text": "99 Hell Bars."},
	{"id": "nana_9", "npc": "nana", "need": {"evil_crystal": 99}, "reward": {"survival_token": 5}, "text": "99 Evil Crystals."},
	{"id": "nana_10", "npc": "nana", "need": {"tsurugi_2": 1}, "reward": {"tsurugi_3": 1}, "text": "Now give me your Tsurugi II."},
	{"id": "nina_1", "npc": "nina", "need": {"em_stone": 9}, "reward": {"survival_token": 5}, "text": "9 Em Stones."},
	{"id": "nina_2", "npc": "nina", "need": {"ruby_stone": 9}, "reward": {"survival_token": 5}, "text": "9 Ruby Stones."},
	{"id": "nina_3", "npc": "nina", "need": {"sapphire_stone": 9}, "reward": {"survival_token": 5}, "text": "9 Sapphire Stones."},
	{"id": "nina_topaz", "npc": "nina", "need": {"topaz_stone": 9}, "reward": {"survival_token": 5}, "text": "9 Topaz Stones."},
	{"id": "nina_4", "npc": "nina", "need": {"volcanic_bar": 25}, "reward": {"survival_token": 5}, "text": "25 Volcanic Bars."},
	{"id": "nina_5", "npc": "nina", "need": {"tsurugi_3": 1}, "reward": {"tsurugi_4": 1}, "text": "Now give me your Tsurugi III."},
	# the robots under Pixel Town (Iron Fist upgrades)
	{"id": "fc_1", "npc": "fc_9912", "need": {"bone": 99}, "reward": {"iron_bar": 1}, "text": "REQUIRE 99 BONES."},
	{"id": "fc_2", "npc": "fc_9912", "need": {"scarab": 99}, "reward": {"iron_bar": 1}, "text": "REQUIRE 99 SCARABS."},
	{"id": "fc_3", "npc": "fc_9912", "need": {"blue_moon": 99}, "reward": {"iron_bar": 1}, "text": "REQUIRE 99 BLUE MOONS."},
	{"id": "fc_4", "npc": "fc_9912", "need": {"branch": 99}, "reward": {"iron_bar": 1}, "text": "REQUIRE 99 BRANCHES."},
	{"id": "fc_5", "npc": "fc_9912", "need": {"jelly": 99}, "reward": {"iron_bar": 1}, "text": "REQUIRE 99 JELLIES."},
	{"id": "fc_6", "npc": "fc_9912", "need": {"iron_fist": 1}, "reward": {"iron_fist_2": 1}, "text": "INSERT IRON FIST."},
	{"id": "tt_1", "npc": "tt_1001", "need": {"copper_bar": 99}, "reward": {"survival_token": 5}, "text": "REQUIRE 99 COPPER BARS."},
	{"id": "tt_2", "npc": "tt_1001", "need": {"iron_bar": 99}, "reward": {"survival_token": 5}, "text": "REQUIRE 99 IRON BARS."},
	{"id": "tt_3", "npc": "tt_1001", "need": {"silver_bar": 99}, "reward": {"survival_token": 5}, "text": "REQUIRE 99 SILVER BARS."},
	{"id": "tt_4", "npc": "tt_1001", "need": {"gold_bar": 99}, "reward": {"survival_token": 5}, "text": "REQUIRE 99 GOLD BARS."},
	{"id": "tt_5", "npc": "tt_1001", "need": {"erbium_bar": 99}, "reward": {"survival_token": 5}, "text": "REQUIRE 99 ERBIUM BARS."},
	{"id": "tt_6", "npc": "tt_1001", "need": {"dark_bar": 99}, "reward": {"survival_token": 5}, "text": "REQUIRE 99 DARK BARS."},
	{"id": "tt_7", "npc": "tt_1001", "need": {"light_bar": 99}, "reward": {"survival_token": 5}, "text": "REQUIRE 99 LIGHT BARS."},
	{"id": "tt_8", "npc": "tt_1001", "need": {"hell_bar": 99}, "reward": {"survival_token": 5}, "text": "REQUIRE 99 HELL BARS."},
	{"id": "tt_9", "npc": "tt_1001", "need": {"living_flame": 99}, "reward": {"survival_token": 5}, "text": "REQUIRE 99 FIRA."},
	{"id": "tt_10", "npc": "tt_1001", "need": {"iron_fist_2": 1}, "reward": {"iron_fist_3": 1}, "text": "INSERT IRON FIST II."},
	{"id": "oop_1", "npc": "oop_2219", "need": {"em_stone": 9}, "reward": {"survival_token": 5}, "text": "REQUIRE 9 EM STONES."},
	{"id": "oop_2", "npc": "oop_2219", "need": {"ruby_stone": 9}, "reward": {"survival_token": 5}, "text": "REQUIRE 9 RUBY STONES."},
	{"id": "oop_3", "npc": "oop_2219", "need": {"sapphire_stone": 9}, "reward": {"survival_token": 5}, "text": "REQUIRE 9 SAPPHIRE STONES."},
	{"id": "oop_topaz", "npc": "oop_2219", "need": {"topaz_stone": 9}, "reward": {"survival_token": 5}, "text": "REQUIRE 9 TOPAZ STONES."},
	{"id": "oop_4", "npc": "oop_2219", "need": {"volcanic_bar": 25}, "reward": {"survival_token": 5}, "text": "REQUIRE 25 VOLCANIC BARS."},
	{"id": "oop_5", "npc": "oop_2219", "need": {"iron_fist_3": 1}, "reward": {"iron_fist_4": 1}, "text": "INSERT IRON FIST III."},
	# the GateKeeper turns up again in Hell 2, missing his mask
	{"id": "mask_1", "npc": "warden_hell", "need": {"green_face": 1}, "reward": {"silver_key": 1}, "unlock": "em_shop",
		"text": "I lost my mask somewhere down here... Bring me a Green Face and I'll sell you Em Stones."},
]

## Miffie's Daily Bounty Quest, once her 27 quests are done: one piece of equipment a
## day (the same for everyone). Early things pay what were 5 gems (5 Silver Keys here),
## everything else a Master Key.
var _bounty := {}
func bounty_quest(day: int) -> Dictionary:
	if _bounty.has(day):
		return _bounty[day]
	var pool := []
	for r in SMITH:
		if ITEMS[r.out].type in ["weapon", "helmet", "armor", "shield", "ring"]:
			pool.append(r.out)
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919 + 17
	var want: String = pool[rng.randi() % pool.size()]
	var early: bool = int(ITEMS[want].sell) < 200
	_bounty[day] = {"id": "bounty_%d" % day, "npc": "mira", "need": {want: 1}, "reward": {"silver_key": 5} if early else {"master_key": 1},
		"text": "For today's Bounty Quest... Please bring me 1 %s! Reward will be %s!" % [ITEMS[want].name, "5 Silver Keys" if early else "1 Master Key"]}
	return _bounty[day]

# Shops: what each villager sells, and for how many coins (or tokens).
var SHOPS := {
	"merchant": {"title": "Merchant", "sells": [["combo_book_2", 1500], ["small_potion", 15], ["small_mana_potion", 15], ["antidote", 40], ["fatigue_potion", 40], ["arrow", 2], ["cc_ball_1", 8], ["wk_missile_1", 12], ["wood_wall", 10], ["campfire", 60], ["green_egg", 10000]], "buys": true},
	"tools": {"title": "Plumber", "sells": [["wooden_axe", 250], ["wooden_pick", 250], ["copper_ore", 250]], "buys": true},
	"gruff": {"title": "Brutus' Shop", "sells": [["wood", 5], ["rock", 5], ["branch", 5]], "buys": false},
	"warden_hell": {"title": "GateKeeper", "needs": "em_shop", "sells": [["em_stone", 92500]], "buys": false},
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
		["combination_scroll", 1, 1, 0.3], ["silver_key", 1, 1, 0.3], ["golden_key", 1, 1, 0.1], ["survival_token", 1, 3], ["green_egg", 1, 1, 0.1],
		["cavemun", 1, 1, 0.3], ["school_girl", 1, 1, 0.2], ["bad_man", 1, 1, 0.2], ["soldier", 1, 1, 0.2], ["pirate", 1, 1, 0.2],
		["cc_ball_1", 3, 8], ["wk_missile_1", 3, 8], ["snow_ball", 5, 10], ["pistol", 1, 1, 0.3], ["backstreet_boy", 1, 1, 0.2]]},
	"golden": {"name": "Golden Chest", "key": "golden_key", "rolls": 2, "loot": [
		["timber_club", 1, 1], ["gilded_blade", 1, 1], ["azure_blade", 1, 1], ["fire_brand", 1, 1], ["violet_edge", 1, 1], ["excalibur", 1, 1],
		["bow", 1, 1], ["long_sword", 1, 1], ["plunger", 1, 1], ["magic_wand", 1, 1], ["fire_staff", 1, 1, 0.5], ["knights_blade", 1, 1],
		["kings_mace", 1, 1, 0.3], ["moon_blade", 1, 1, 0.3], ["poison_ivy", 1, 1, 0.3], ["glow_blade_red", 1, 1], ["glow_blade_blue", 1, 1],
		["golden_long_sword", 1, 1, 0.5], ["pole_axe", 1, 1], ["leather_shield", 1, 1], ["copper_shield", 1, 1], ["knight_shield", 1, 1], ["hard_shield", 1, 1],
		["dark_shield", 1, 1], ["blue_shield", 1, 1], ["faceguard", 1, 1], ["copper_faceguard", 1, 1], ["tank_shield", 1, 1, 0.3], ["iron_shield", 1, 1, 0.3],
		["stone_armor", 1, 1], ["silver_armor", 1, 1], ["copper_armor", 1, 1], ["linen_armor", 1, 1], ["leather_armor", 1, 1], ["jelly_armor", 1, 1],
		["iron_armor", 1, 1], ["golden_armor", 1, 1], ["tough_leather_armor", 1, 1, 0.3], ["silver_ring", 1, 1], ["gold_ring", 1, 1], ["armor_ring", 1, 1],
		["jade_ring", 1, 1], ["holy_banana", 1, 2], ["evil_shield", 1, 1, 0.3], ["pink_egg", 1, 1], ["green_egg", 1, 1], ["staff_cast", 1, 1],
		["healing_staff", 1, 1, 0.3], ["healing_staff_2", 1, 1, 0.1], ["combination_scroll", 1, 2],
		["crazy_cannon_1", 1, 1, 0.3], ["waazookaa_1", 1, 1, 0.3], ["cc_ball_2", 3, 8], ["wk_missile_2", 3, 8], ["the_spi", 1, 1, 0.3], ["chuchu", 1, 1, 0.3], ["drone", 1, 1, 0.3],
		["blue_staff", 1, 1, 0.5], ["laser_gun", 1, 1, 0.5], ["pistol", 1, 1], ["rolva", 1, 1, 0.5], ["long_sword_shield", 1, 1, 0.5], ["sapphire_long_sword", 1, 1, 0.3],
		["firecracker_blade", 1, 1, 0.3], ["steel_bow", 1, 1, 0.3], ["backstreet_boy", 1, 1, 0.3]]},
	"master": {"name": "Master Chest", "key": "master_key", "rolls": 1, "loot": [
		["pole_axe", 1, 1], ["combo_sword", 1, 1], ["moon_blade", 1, 1], ["moon_blade_2", 1, 1], ["moon_blade_3", 1, 1], ["twin_sun", 1, 1],
		["devil_spike", 1, 1], ["golden_long_sword", 1, 1], ["copper_faceguard", 1, 1], ["tank_shield", 1, 1], ["iron_armor", 1, 1], ["golden_armor", 1, 1],
		["gold_shield", 1, 1], ["blue_shield", 1, 1], ["armor_ring_2", 1, 1], ["armor_ring_3", 1, 1], ["jade_ring", 1, 1], ["blood_diamond_armor", 1, 1],
		["seer_armor", 1, 1], ["ivory_armor", 1, 1], ["scale_armor", 1, 1], ["copper_helmet", 1, 1], ["brass_helmet", 1, 1], ["fear_helmet", 1, 1],
		["fear_helmet_2", 1, 1], ["hell_helmet", 1, 1], ["hell_helmet_2", 1, 1], ["witch_helmet", 1, 1], ["witch_helmet_2", 1, 1], ["golden_seeds", 1, 1],
		["healing_staff", 1, 1], ["healing_staff_2", 1, 1], ["healing_staff_3", 1, 1], ["sapphire_stone", 1, 1], ["em_stone", 1, 1], ["green_egg", 1, 1], ["gold_sword_cast", 1, 1],
		["crazy_cannon_2", 1, 1], ["waazookaa_2", 1, 1], ["crazy_cannon_3", 1, 1, 0.5], ["waazookaa_3", 1, 1, 0.5], ["dark_knight", 1, 1],
		["ninja", 1, 1, 0.3], ["iron_bot", 1, 1, 0.3],
		# Crafter materials and gear the wiki lists in the Master Chest (Sky Stone's source is a guess)
		["sky_pole_axe", 1, 1], ["golden_faceguard", 1, 1], ["skull_dress", 1, 1], ["skull_dress_2", 1, 1], ["skull_dress_3", 1, 1],
		["emperor_dress", 1, 1], ["emperor_dress_2", 1, 1], ["dragon_spine", 1, 1], ["sky_stone", 1, 1],
		# the gem-shop and event items: in the original most of these moved to the Master Chest
		# after their event, so here that's where they come from
		["moonclipse", 1, 1], ["moonclipse_2", 1, 1], ["moonclipse_3", 1, 1], ["moonclipse_4", 1, 1], ["moonclipse_5", 1, 1, 0.5],
		["moonclipse_shield", 1, 1], ["moonclipse_shield_2", 1, 1], ["moonclipse_shield_3", 1, 1], ["moonclipse_shield_4", 1, 1], ["moonclipse_shield_5", 1, 1, 0.5],
		["robo_mask_7", 1, 1, 0.3], ["armor_ring_6", 1, 1, 0.3], ["heartstone_ring", 1, 1], ["manastone_ring", 1, 1], ["shattered_souls_ring", 1, 1],
		["pet_reaper", 1, 1, 0.3], ["pet_moonwisp", 1, 1, 0.3], ["lunar_egg", 1, 1], ["easter_egg", 1, 1], ["christmas_egg", 1, 1], ["halloween_egg", 1, 1],
		["devil_cannon", 1, 1, 0.5], ["devil_cannon_ball", 5, 10], ["golden_staff", 1, 1], ["holy_staff", 1, 1, 0.5], ["green_laser_gun", 1, 1], ["blue_laser_gun", 1, 1, 0.5],
		["lucky_special", 1, 1, 0.3], ["red_fluorescent_shield", 1, 1], ["firey_shield", 1, 1], ["evil_axe_shield", 1, 1, 0.5], ["yellow_fluorescent", 1, 1],
		["rainbow_sword", 1, 1, 0.3], ["evil_shadow_blade", 1, 1, 0.3], ["red_moon_soul_blade", 1, 1, 0.3], ["frost_moon_blade", 1, 1, 0.3],
		["shadow_moon_blade", 1, 1, 0.3], ["blood_moon_soul_blade", 1, 1, 0.3], ["moon_knifes", 1, 1, 0.3], ["moon_edge", 1, 1, 0.3], ["chocolate_sword", 1, 1, 0.5],
		["ultimate_santa_blade", 1, 1, 0.2], ["ultimate_candy", 1, 1, 0.2], ["devilween", 1, 1, 0.1], ["ninja_star", 1, 1], ["christmas_tree", 1, 1],
		["candy_stick_red", 1, 1], ["candy_stick_green", 1, 1], ["candy_staff", 1, 1], ["snow_maker", 1, 1], ["giant_snow_ball", 1, 1], ["king_carrot", 1, 1],
		["pumpkin_saber_a", 1, 1], ["popstick", 1, 1], ["snowman_hat", 1, 1], ["topaz_stone", 1, 1], ["mooncake", 1, 3], ["missing_page", 1, 1, 0.3],
		["combo_book_z", 1, 1, 0.2], ["backstreet_boy", 1, 1], ["sailor_moons", 1, 1]]},
}
var REWARD_CHEST := "silver" # chests found inside worlds use the silver loot table

# What magic seeds grow into (the wiki's lists, without gems).
var SEED_LOOT := {
	"green_seeds": [["green_seeds", 1, 2], ["big_potion", 1, 1], ["big_rejuvenate_potion", 1, 1], ["silver_key", 1, 1], ["golden_key", 1, 1, 0.3],
		["coin", 200, 800], ["survival_token", 1, 3], ["silver_ore", 3, 6]],
	"red_seeds": [["green_seeds", 1, 3], ["red_seeds", 1, 1], ["silver_key", 1, 2], ["golden_key", 1, 1], ["master_key", 1, 1, 0.2], ["armor_bug", 1, 2],
		["power_bug", 1, 2], ["hero_bug", 1, 1, 0.3], ["small_evil_crystal", 1, 2], ["evil_crystal", 1, 1, 0.3], ["purple_egg", 1, 1, 0.3],
		["queen_egg", 1, 1, 0.1], ["gold_bar", 1, 3], ["erbium_bar", 1, 2], ["survival_token", 2, 5]],
	"golden_seeds": [["golden_seeds", 1, 1, 0.3], ["red_seeds", 1, 2], ["master_key", 1, 1], ["golden_key", 1, 2], ["erbium", 3, 6], ["volcanic_ore", 1, 1, 0.3]],
}

# The Daily Free Gift in Pixel Town (one roll a day): seeds, keys, potions and characters.
var DAILY_GIFT := [["green_seeds", 1, 1, 2], ["red_seeds", 1, 1, 0.5], ["silver_key", 1, 1, 1.5], ["golden_key", 1, 1, 0.4],
	["small_potion", 3, 5, 2], ["potion", 2, 3, 1], ["combination_scroll", 1, 1, 0.5], ["coin", 100, 500, 2],
	["cavemun", 1, 1, 0.3], ["school_girl", 1, 1, 0.2], ["bad_man", 1, 1, 0.2], ["pirate", 1, 1, 0.2], ["soldier", 1, 1, 0.2]]

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
