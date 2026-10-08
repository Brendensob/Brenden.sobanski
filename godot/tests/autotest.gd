extends Node
## Plays through the main features and saves screenshots.
## Run: godot --path . -- --autotest [--touch]   (screenshots go to user://shots)

var main: Node
var out := "user://shots"
var fails := []

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	run()

func shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name)

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails.append(what)

func goto(world: String) -> void:
	main.hud.close_panels()
	GS.hp = GS.max_hp()
	main.change_level(world)
	main.level.player.invuln = 9999.0
	await wait(0.6)

func stand_by(n: Node, side: int = -1) -> void:
	var p: Node2D = main.level.player
	p.position = n.position + Vector2(side * 10, -1)
	p.facing = -side
	p.velocity = Vector2.ZERO
	await wait(0.25)

func find_prop(pred: Callable) -> Node:
	for n in main.level.props.get_children():
		if pred.call(n):
			return n
	return null

## Every item named by a recipe, the Crafter, a furnace, a monster, a world, a quest,
## a shop or a chest must exist.
func check_data() -> void:
	var missing := []
	var ids := []
	for r in Data.RECIPES:
		ids += r.in
		ids.append(r.out)
	for r in Data.SMITH:
		ids += r.cost.keys()
		ids.append(r.out)
	for r in Data.SMELT:
		ids += r.cost.keys()
		ids.append(r.out)
	for m in Data.MOBS.values():
		for d in m.drops:
			ids.append(d[0])
	for w in Data.WORLDS.values():
		for d in w.get("boss_drops", []):
			ids.append(d[0])
	for q in Data.QUESTS:
		ids += q.need.keys()
		ids += q.reward.keys()
	for sh in Data.SHOPS.values():
		for e in sh.sells:
			ids.append(e[0])
	for c in Data.CHESTS.values():
		for e in c.loot:
			ids.append(e[0])
	for t in Data.SEED_LOOT.values():
		for e in t:
			ids.append(e[0])
	for id in ids:
		if not Data.ITEMS.has(id) and not id in missing:
			missing.append(id)
	for n in Data.NPCS.values():
		if not Art.LOOKS.has(n.look):
			missing.append("look " + n.look)
	for c in Data.CHARACTERS:
		if not Art.LOOKS.has(c):
			missing.append("look " + c)
	check(missing.is_empty(), "every item and look the data uses exists %s" % [missing])
	for id in Data.ITEMS:
		Art.icon(id)

func run() -> void:
	await wait(1.0)
	await shot("01_title")
	check_data()
	for i in GS.SLOTS:
		GS.delete_slot(i)
	main.hud.menu_step = "slots"
	main.hud._refresh_title()
	await shot("01a_slots")
	GS.slot = 0
	main.hud._refresh_title(true)
	await shot("01b_create_character")
	main.hud.menu_step = "mode"
	main.hud._refresh_title()
	await shot("01c_mode")
	main.start_game(false, "nurse", "Tester")
	check(GS.look == "nurse" and GS.player_name == "Tester", "a new game starts as the Nurse named Tester")
	check(GS.slot_info(0).get("name", "") == "Tester", "the character is saved in slot 1")
	check(GS.clock == 0.0 and not GS.is_night(), "a new game starts in the morning")
	GS.clock = 0.5
	check(GS.darkness() > 0.0 and not GS.is_night(), "sunset starts after 11 of 24 hours")
	GS.clock = 0.7
	check(GS.is_night(), "night starts after 15 of 24 hours")
	GS.clock = 0.0
	var g1 := GS.open_gift()
	check(not g1.is_empty() and GS.open_gift().is_empty(), "the Daily Free Gift opens once a day")
	await wait(0.8)
	await shot("02_village")
	# talk to the Gatekeeper
	var keeper := find_prop(func(n): return n.get("npc_id") == "keeper")
	await stand_by(keeper)
	await tap("attack")
	await wait(0.2)
	check(main.hud.panels.npc.visible, "talking to the Gatekeeper opens a dialog")
	await shot("03_keeper")
	main.hud.open_panel("map")
	await shot("04_world_list")
	main.hud.close_panels()
	# Grasslands 1
	await goto("grass_1")
	await shot("05_grasslands")
	var lvl: Node = main.level
	var p: Node2D = lvl.player
	var jumpie := find_prop(func(n): return n.get("npc_id") == "jumpie")
	check(jumpie != null, "Jumpie is in Grasslands 1")
	var coins_before := GS.coins
	GS.add_item("jelly", 10)
	GS.complete_quest(GS.next_quest("jumpie"))
	check(GS.coins == coins_before + 1, "Jumpie's quest pays a Pixel Coin")
	# defense works like the wiki's calculator
	var no_def := GS.roll_monster_hit(7, 0.0)
	check(no_def.dmg == 7, "with 0 defense a 7-attack monster hits for 7 (got %d)" % no_def.dmg)
	GS.equip.armor = "chainmail"
	var low := 99
	for i in 200:
		low = mini(low, GS.roll_monster_hit(7, 0.0).dmg)
	check(low == 1, "with defense 15 a 7-attack monster can drop to 1 damage")
	GS.equip.armor = ""
	# characters: becoming the Pirate gives a Golden Night, and character hats are crafted
	GS.add_item("pirate", 11)
	for i in GS.BAG:
		if GS.inv[i] and GS.inv[i].id == "pirate":
			GS.use_character(i)
			break
	check(GS.look == "pirate" and GS.count("gilded_blade") == 1, "becoming the Pirate gives a Golden Night")
	var hat_recipe := {}
	for r0 in Data.SMITH:
		if r0.out == "pirate_hat":
			hat_recipe = r0
	check(GS.smith(hat_recipe) and GS.count("pirate_hat") == 1, "the Crafter turns 10 Pirates into a Pirate Hat")
	for i in GS.BAG:
		if GS.inv[i] and GS.inv[i].id == "pirate_hat":
			GS.equip_from(i)
	await wait(0.3)
	await shot("05b_pirate_hat")
	# cannons use their own ammo
	GS.inv[4] = {"id": "crazy_cannon_1", "n": 1}
	GS.add_item("cc_ball_1", 5)
	GS.sel = 4
	GS.inventory_changed.emit()
	p.cooldown = 0
	await tap("attack")
	await wait(0.2)
	check(GS.count("cc_ball_1") == 4, "Crazy Cannon I fires a ball")
	await shot("05c_cannon")
	GS.inv[4] = null
	var slime: Node = lvl.spawn_mob_at("slime", p.position + Vector2(14, 0))
	GS.sel = 0
	GS.inventory_changed.emit()
	for i in 12:
		if not is_instance_valid(slime) or slime.dead:
			break
		slime.position = p.position + Vector2(12 * p.facing, 0)
		await tap("attack")
		await wait(0.55)
		GS.st = GS.max_st()
		GS.hp = GS.max_hp()
	check(not is_instance_valid(slime) or slime.dead, "a slime dies to the starter sword")
	await shot("06_fight")
	# chop a tree with the wooden axe: 8 hits
	var tree := find_prop(func(n): return n.get("kind") == "tree" and n.position.y < 20 * 16)
	if tree:
		for e in lvl.entities.get_children():
			if e.has_method("die") and e.position.distance_to(tree.position) < 120:
				e.queue_free()
		await stand_by(tree)
		GS.sel = 1
		GS.inventory_changed.emit()
		for i in 9:
			await tap("attack")
			await wait(0.55)
			GS.st = GS.max_st()
			GS.hp = GS.max_hp()
		await wait(1.0)
	check(GS.count("wood") > 0, "chopping a tree gives wood (got %d)" % GS.count("wood"))
	await shot("07_chopped")
	# underground
	var deep := Vector2i(-1, -1)
	for c in lvl.floor_cells(20):
		if c.y > 40:
			deep = c
			break
	if deep.x > 0:
		p.position = lvl.cell_pos(deep)
		await wait(0.6)
		await shot("08_cave")
	# combine wood + rock into a wall
	GS.add_item("wood", 3)
	GS.add_item("rock", 3)
	main.hud.bag_mode = "bag"
	main.hud.bag_tab = "combine"
	main.hud.open_panel("bag")
	var wi := -1
	var ri := -1
	for i in GS.BAG:
		if GS.inv[i] and GS.inv[i].id == "wood": wi = i
		if GS.inv[i] and GS.inv[i].id == "rock": ri = i
	main.hud.combo = [wi, ri, -1]
	main.hud.bag_sel = wi
	main.hud._refresh_bag()
	await shot("09_bag")
	var before := GS.count("wood_wall") + GS.count("dust")
	main.hud._do_combine()
	check(GS.count("wood_wall") + GS.count("dust") == before + 1, "combining gives a wall or dust")
	main.hud.bag_tab = "character"
	main.hud._refresh_bag()
	await shot("09b_bag_character")
	main.hud.close_panels()
	# hold A and open the bag: auto-attack, like the original
	Input.action_press("attack")
	main.hud.toggle_bag()
	Input.action_release("attack")
	check(main.level.player.auto_attack, "holding A while opening the bag turns on auto-attack")
	main.hud.close_panels()
	await tap("attack")
	check(not main.level.player.auto_attack, "pressing A stops auto-attack")
	# the bomb button sends you home
	main.level.player.invuln = 0.0
	main.level.player.self_destruct()
	await wait(1.4)
	check(main.hud.panels.dead.visible, "the bomb makes you faint")
	main.respawn()
	await wait(0.4)
	await shot("09c_town")
	# quests in the village
	await goto("town")
	GS.add_item("wood_wall", 1)
	GS.complete_quest(GS.next_quest("gruff"))
	check(GS.flags.get("survival_access", false) and GS.count("survival_book") == 1, "Brutus' quest gives the Survival Book and survival access")
	GS.add_item("pretzel", 1)
	GS.complete_quest(GS.next_quest("warden"))
	main.reload_level()
	await wait(0.3)
	check(GS.flags.get("furnaces", false), "the Pretzel unlocks the furnaces")
	# Miffie's 3rd quest asks for 10 Copper Bars but only takes 5
	for q in ["mira_1", "mira_2"]:
		GS.quests_done.append(q)
	GS.add_item("copper_bar", 10)
	GS.complete_quest(GS.next_quest("mira"))
	check(GS.count("copper_bar") == 5 and GS.count("gilded_blade") >= 1, "Miffie checks for 10 Copper Bars and takes 5")
	GS.remove_item("copper_bar", 5)
	# smelt copper, then smith a copper axe
	GS.add_item("copper_ore", 100)
	GS.add_item("coal", 20)
	var err := GS.start_smelt(0, Data.SMELT[0])
	check(err == "", "starting a copper smelt")
	var furnace := find_prop(func(n): return n.get("kind") == "furnace" and n.index == 0)
	await stand_by(furnace)
	await tap("attack")
	await wait(0.3)
	await shot("10_furnace_busy")
	main.hud.close_panels()
	GS.furnaces[0].done = GS.now() - 1
	GS.collect_smelt(0)
	check(GS.count("copper_bar") == 1, "collecting a copper bar")
	GS.add_item("copper_bar", 19)
	main.hud.open_smith()
	main.hud.craft_sel = 0
	main.hud._refresh_bag()
	await shot("11_crafter")
	main.hud.close_panels()
	var r: Dictionary = Data.SMITH[0]
	check(GS.smith(r) and GS.count("copper_axe") == 1, "the Crafter makes a Copper Axe")
	main.hud.open_book("survival")
	await shot("12_book")
	main.hud.close_panels()
	# pets
	GS.add_item("pink_egg", 1)
	check(GS.start_hatch("pink_egg"), "the incubator takes an egg")
	GS.incubator.done = GS.now() - 1
	var pet := GS.collect_hatch()
	check(pet != "", "a pet hatches (%s)" % pet)
	for i in GS.BAG:
		if GS.inv[i] and GS.inv[i].id == pet:
			GS.equip_from(i)
	main.level.spawn_pet()
	await wait(0.5)
	await shot("13_village_pet")
	# chests
	GS.add_item("silver_key", 1)
	var loot := GS.open_chest("silver")
	check(loot.size() == 2, "a silver chest gives two items")
	# worlds
	for w in ["grass_2", "grass_3", "dark_1", "dark_2", "hell_1", "hell_2", "ice_cavern"]:
		await goto(w)
		check(main.level.count_mobs() > 10, "%s has monsters (%d)" % [w, main.level.count_mobs()])
		await shot("20_" + w)
	for w in ["grass_arena", "dark_arena", "hell_arena", "dream_arena", "ghost_arena"]:
		await goto(w)
		main.level.arena_time = 179.0
		await wait(1.6)
		check(main.level.bosses_spawned, "%s boss arrives at 3 minutes" % w)
		await shot("30_" + w)
	# survival at night
	await goto("survival")
	GS.clock = 0.85
	main.level.s_day = 7
	await wait(3.0)
	await shot("40_survival_night")
	main.level.player.invuln = 0.0
	main.level.player.hurt(9999, 0.0, main.level.player.position.x - 5)
	await wait(1.5)
	check(GS.count("silver_key") >= 1, "dying on day 7 of Survival gives a Silver Key")
	await shot("41_fainted")
	main.respawn()
	await wait(0.3)
	GS.save_game()
	check(GS.load_game(), "save and load")
	print("AUTOTEST DONE, %d failures: %s" % [fails.size(), fails])
	get_tree().quit()
