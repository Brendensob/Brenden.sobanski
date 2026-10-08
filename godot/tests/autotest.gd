extends Node
## Plays through the main features and saves screenshots.
## Run: godot --path . -- --autotest   (screenshots go to user://shots)

var main: Node
var out := "user://shots"

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

func hold(action: String, t: float) -> void:
	Input.action_press(action)
	await wait(t)
	Input.action_release(action)

func tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)

func run() -> void:
	await wait(1.0)
	await shot("01_title")
	main.start_game(false)
	await wait(1.0)
	await shot("02_town")
	var lvl: Node = main.level
	var p: Node2D = lvl.player
	p.position.x = 9 * 16 + 8 - 10
	await wait(0.3)
	await tap("attack")
	await wait(0.3)
	await shot("03_dialog")
	main.hud.close_panels()

	main.change_level("grass_1", "left")
	await wait(0.8)
	lvl = main.level
	p = lvl.player
	await hold("move_right", 0.8)
	await tap("jump")
	await wait(0.3)
	await shot("04_grass_jump")
	# fight a slime
	var m: Node = lvl.spawn_mob_at("slime", p.position.x + 20)
	await wait(0.4)
	GS.sel = 0
	for i in 8:
		if not is_instance_valid(m) or m.dead:
			break
		m.position.x = p.position.x + 12 * p.facing
		await tap("attack")
		await wait(0.35)
		GS.stamina = GS.max_stamina()
	print("slime dead: ", not is_instance_valid(m) or m.dead)
	await wait(0.2)
	await shot("05_after_fight")
	await wait(1.5)
	# chop a tree
	var tree: Node = null
	for n in lvl.props.get_children():
		if n.get("kind") == "tree":
			tree = n
			break
	if tree:
		p.position = Vector2(tree.position.x - 12, lvl.surface_y(tree.position.x - 12) - 2)
		p.facing = 1
		GS.sel = 1
		GS.inventory_changed.emit()
		for i in 6:
			await tap("attack")
			await wait(0.35)
			GS.stamina = GS.max_stamina()
		await wait(1.2)
	print("wood: ", GS.count("wood"), " inv: ", GS.inv.filter(func(s): return s != null))
	await shot("06_chopped")
	# combine wood + wood
	GS.add_item("wood", 4)
	GS.add_item("jelly", 2)
	GS.add_item("scarab", 2)
	main.hud.open_panel("bag")
	var wi := -1
	for i in GS.BAG:
		if GS.inv[i] and GS.inv[i].id == "wood":
			wi = i
	main.hud.combo = [wi, wi]
	main.hud.bag_sel = wi
	main.hud._refresh_bag()
	await shot("07_bag")
	main.hud._do_combine()
	print("walls: ", GS.count("wood_wall"))
	main.hud.close_panels()
	# quest hand-in
	main.use_portal("town")
	await wait(0.5)
	main.level.player.position.x = 9 * 16 + 8 - 10
	await wait(0.2)
	await tap("attack")
	await wait(0.2)
	var q: Dictionary = GS.next_quest("pip")
	print("quest ready: ", GS.quest_ready(q))
	GS.complete_quest(q)
	main.hud._refresh_dialog()
	await shot("07b_quest_done")
	print("has survival book: ", GS.count("survival_book"))
	main.hud.open_panel("shop")
	await shot("07c_shop")
	main.hud.close_panels()
	main.change_level("grass_1", "left")
	await wait(0.5)
	lvl = main.level
	p = lvl.player
	p.position.x = 30 * 16
	await wait(0.3)
	# build a wall and a torch, then night
	for n in lvl.props.get_children():
		if absf(n.position.x - p.position.x) < 50 and n.get("kind") != null:
			n.queue_free()
	await wait(0.1)
	GS.sel = 0
	GS.inv[0] = {"id": "wood_wall", "n": 2}
	GS.inv[4] = {"id": "torch", "n": 3}
	GS.inventory_changed.emit()
	p.facing = 1
	await tap("attack")
	GS.sel = 4
	p.facing = -1
	await tap("attack")
	await wait(0.3)
	await shot("08a_built")
	GS.clock = 0.8
	for i in 3:
		lvl.spawn_mob_at(["slime", "bee"][i % 2], p.position.x + 60 + i * 20)
	await wait(1.5)
	await shot("08_night")
	# lair
	GS.clock = 0.3
	GS.add_item("grass_key")
	GS.inv[0] = {"id": "iron_sword", "n": 1}
	GS.sel = 0
	main.use_portal("grass_lair")
	await wait(2.8)
	await hold("move_right", 1.6)
	await wait(0.6)
	lvl = main.level
	for e in lvl.entities.get_children():
		if e.get("id") == "slime_king":
			lvl.player.position.x = e.position.x - 70
	await wait(0.6)
	await shot("09_lair")
	lvl = main.level
	for e in lvl.entities.get_children():
		if e.get("id") == "slime_king":
			e.take_damage(10000, e.position.x - 10)
	await wait(1.0)
	print("bosses: ", GS.bosses, " unlocked dark: ", GS.unlocked.has("dark_1"))
	await shot("10_boss_down")
	main.use_portal("town")
	await wait(0.5)
	main.hud.open_panel("map")
	await shot("11_map")
	main.hud.close_panels()
	main.change_level("dark_3", "left")
	await wait(1.0)
	await shot("12_darklands")
	main.change_level("hell_4", "left")
	await wait(1.0)
	await shot("13_hell")
	main.level.player.hurt(999, main.level.player.position.x - 5)
	await wait(1.5)
	await shot("14_fainted")
	main.respawn()
	await wait(0.5)
	print("respawned in ", GS.level_id, " hp=", GS.hp)
	GS.save_game()
	print("AUTOTEST DONE coins=", GS.coins, " hp=", GS.hp)
	get_tree().quit()
