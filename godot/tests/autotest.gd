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
	for egg in Data.EGG_PETS:
		if not Data.ITEMS.has(egg):
			missing.append(egg)
		for pet in Data.EGG_PETS[egg]:
			if not Data.PETS.has(pet):
				missing.append(pet)
	for r in Data.RECIPES:
		if not Data.BOOK_ITEM.has(r.book):
			missing.append("book " + r.book)
	for sec in Data.WORLD_MENU:
		for w in sec[1]:
			if not Data.WORLDS.has(w):
				missing.append("world " + w)
	check(missing.is_empty(), "every item and look the data uses exists %s" % [missing])
	for id in Data.ITEMS:
		Art.icon(id)
	# no monster or pet falls back to the magenta placeholder blob
	var blobs := []
	var looks := []
	for m in Data.MOBS.values():
		looks.append(m.look)
	for pt in Data.PETS.values():
		looks.append(pt.look)
	for look in looks:
		var img: Image = Art.mob_tex(look, false).get_image()
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).is_equal_approx(Color("ff00ff")) and not look in blobs:
					blobs.append(look)
	check(blobs.is_empty(), "every monster and pet has its own picture %s" % [blobs])
	# no two combinations take the same items
	var seen := {}
	var dupes := []
	for r in Data.RECIPES:
		var k: Array = r.in.duplicate()
		k.sort()
		if seen.has(str(k)):
			dupes.append(r.out)
		seen[str(k)] = true
	check(dupes.is_empty(), "every combination has its own ingredients %s" % [dupes])
	var books := {}
	for r in Data.RECIPES:
		books[r.book] = books.get(r.book, 0) + 1
	check(books.get("z", 0) == 28 and books.get("zx", 0) == 22 and books.get("u", 0) == 14,
		"Combo Books Z, ZX and U have the wiki's recipes (+ the Missing Page's) %s" % [books])

func until_floor(p: CharacterBody2D) -> void:
	for f in 240:
		if p.is_on_floor():
			return
		await get_tree().physics_frame

## Clicks at a point on the game screen (480 x 270), like a mouse would.
func click(at: Vector2) -> void:
	at *= Vector2(DisplayServer.window_get_size()) / get_viewport().get_visible_rect().size
	for down in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = down
		ev.position = at
		ev.global_position = at
		Input.parse_input_event(ev)
		await get_tree().physics_frame
		await get_tree().physics_frame

## Lines up every monster from the later worlds for a picture.
func new_monsters() -> void:
	await goto("eggcellence")
	var lvl: Node = main.level
	for e in lvl.entities.get_children():
		if e.has_method("die") and not e == lvl.player:
			e.queue_free()
	var ids := ["slug", "phantom_butterfly", "demon_eye", "imp", "demon_bat", "an_an", "ji_ji", "he_he", "raven", "grinch", "snow_turtle", "lich",
		"fairy", "mango", "cherry", "pineapple", "strawberry", "egg_orange", "egg_blue", "egg_purple", "egg_clutch", "chick", "giant_chick"]
	var p: Node2D = lvl.player
	var base := p.position + Vector2(-200, -40)
	for i in ids.size():
		var m: Node = lvl.spawn_mob_at(ids[i], base + Vector2((i % 12) * 34, (i / 12) * 44))
		m.set_physics_process(false)
	await wait(0.3)
	await shot("31_new_monsters")
	for e in lvl.entities.get_children():
		if e.has_method("die") and not e == lvl.player:
			e.queue_free()
	var bosses := ["modina", "modina_2", "doom", "fortune_boss", "evil_santa", "pineapple_killer", "harakattu"]
	for i in bosses.size():
		var m: Node = lvl.spawn_mob_at(bosses[i], p.position + Vector2(-210 + i * 70, -10))
		m.set_physics_process(false)
	await wait(0.3)
	await shot("32_new_bosses")
	# Snow Valley's monsters hit 40 harder below 160 defense
	await goto("snow_valley")
	main.level.player.invuln = 0.0
	var hp0: float = GS.max_hp()
	GS.hp = 9999
	main.level.player.hurt(1, 0.0, main.level.player.position.x - 5)
	var took := int(9999 - GS.hp)
	check(took >= 41 - GS.stat("def") and took <= 41, "Snow Valley adds 40 damage under 160 defense (a 1-attack hit took %d)" % took)
	GS.hp = hp0
	main.level.player.invuln = 9999.0
	# Hell 1 uses the Hell page's health, and everything but wizards and bosses can poison
	await goto("hell_1")
	var mt: Node = main.level.spawn_mob_at("mantis", main.level.player.position + Vector2(60, 0))
	var wz: Node = main.level.spawn_mob_at("wizard", main.level.player.position + Vector2(90, 0))
	check(mt.max_hp >= 250 and mt.max_hp <= 300 and mt.status_effect() == ["poison", 0.12] and wz.status_effect().is_empty(),
		"Hell 1 Mantis has %d health (wiki: 250-300) and can poison; Wizards can't" % mt.max_hp)

## The rest of Pixel Survival Game 2: the Tomb of Makara, Combo Books Z, ZX and U,
## the rings that restore health or mana, the Jade Ring, and Miffie's Daily Bounty.
## Gems (the third currency), the Gem Shop and the characters' stats.
func gems_and_characters() -> void:
	await goto("town")
	# gems are a currency like coins: they don't take a bag slot
	var free0 := GS.inv.count(null)
	var g0 := GS.gems
	GS.add_item("gem", 3)
	check(GS.gems == g0 + 3 and GS.inv.count(null) == free0 and GS.count("gem") == GS.gems, "gems are a currency and don't use bag space")
	# where gems come from
	var bosses_ok := true
	for m in Data.MOBS:
		var d: Dictionary = Data.MOBS[m]
		if d.get("boss", false) and not d.drops.any(func(e): return e[0] == "gem"):
			bosses_ok = false
	check(bosses_ok, "every boss can drop gems")
	var chest_gems: bool = Data.CHESTS.golden.loot.any(func(e): return e[0] == "gem") and Data.CHESTS.master.loot.any(func(e): return e[0] == "gem")
	var seed_gems: bool = Data.SEED_LOOT.red_seeds.any(func(e): return e[0] == "gem") and Data.SEED_LOOT.golden_seeds.any(func(e): return e[0] == "gem")
	check(chest_gems and seed_gems, "Golden and Master Chests and Red and Golden seeds give gems")
	var quest_gems := 0
	for q in Data.QUESTS:
		quest_gems += int(q.reward.get("gem", 0))
	check(quest_gems == 15, "Miffie's and the GateKeeper's quests give the original's 15 gems (%d)" % quest_gems)
	# a boss drop lands as gems
	main.level.drop("gem", 2, main.level.player.position + Vector2(0, -4))
	await wait(1.0)
	check(GS.gems == g0 + 5, "picking up a gem drop adds gems (%d)" % GS.gems)
	# the Gem Shop opens from the gem next to the coins
	var gb: TextureButton = main.hud.find_child("GemButton", true, false)
	check(gb != null and gb.is_visible_in_tree(), "the gem counter is on screen")
	gb.pressed.emit()
	await wait(0.3)
	check(main.hud.panels.shop.visible and main.hud.panels.shop.get_node("Title").text == "Gem Shop", "tapping the gem opens the Gem Shop")
	await shot("24_gem_shop")
	# keys come in threes for 5, 15 and 40 gems, like the original
	var shop := Data.gem_shop()
	var prices := {}
	for e in shop.sells:
		prices[e[0]] = [e[1], e[2]]
	check(prices.silver_key == [5, 3] and prices.golden_key == [15, 3] and prices.master_key == [40, 3], "3 keys cost 5, 15 or 40 gems")
	check(prices.ninja[0] == 2000 and prices.iron_bot[0] == 2000 and prices.cavemun[0] == 100 and prices.q_bun[0] == 300, "characters cost 100, 300, 800 or 2000 gems")
	# buying with gems, and gems with coins
	GS.gems = 5
	var sk := GS.count("silver_key")
	var buy_btn: Button = null
	main.hud._refresh_shop("gem_shop")
	for row in main.hud.panels.shop.find_child("Buy", true, false).get_children():
		if row.get_child_count() > 2 and (row.get_child(1) as Label).text.begins_with("Silver Key"):
			buy_btn = row.get_child(2)
	check(buy_btn != null and not buy_btn.disabled, "the Silver Keys can be bought")
	if buy_btn:
		buy_btn.pressed.emit()
	await wait(0.1)
	check(GS.gems == 0 and GS.count("silver_key") == sk + 3, "5 gems buy 3 Silver Keys")
	GS.coins = Data.GEM_PRICE
	main.hud._refresh_shop("gem_shop")
	var gem_btn: Button = null
	for row in main.hud.panels.shop.find_child("Sell", true, false).get_children():
		if row is HBoxContainer and (row.get_child(1) as Label).text.begins_with("1 Gem"):
			gem_btn = row.get_child(2)
	check(gem_btn != null and not gem_btn.disabled, "gems can be bought with Pixel Coins")
	if gem_btn:
		gem_btn.pressed.emit()
	await wait(0.1)
	check(GS.gems == 1 and GS.coins == 0, "1 gem costs %d coins" % Data.GEM_PRICE)
	main.hud.close_panels()
	# every character has art, an item, a gem price and stats
	var chars_ok := true
	for c in Data.CHARACTERS:
		if not Art.LOOKS.has(c) or not Data.ITEMS.has(c) or not Data.CHARACTERS[c].has("gems"):
			chars_ok = false
	check(chars_ok and Data.CHARACTERS.size() >= 18, "all %d characters have art, an item and a price" % Data.CHARACTERS.size())
	check(Data.CHARACTERS.has("q_bun") and Data.CHARACTERS.has("mad_bun") and Data.CHARACTERS.has("nerd_bun"), "the Q, Mad and Nerd Buns are in")
	# a character's stats count on top of your gear
	var look0 := GS.look
	GS.look = "man_in_suit"
	var atk0 := GS.stat("atk")
	var hp0 := GS.stat("hp")
	for i in GS.BAG:
		if GS.inv[i] == null:
			GS.inv[i] = {"id": "ninja", "n": 1}
			GS.use_character(i)
			break
	check(GS.look == "ninja" and GS.stat("atk") == atk0 + 9 and GS.stat("hp") == hp0 + 16, "the Ninja adds his attack and health (atk %d, hp %d)" % [GS.stat("atk"), GS.stat("hp")])
	check(Data.ITEMS.ninja.desc.contains("Attack +9"), "a character's item lists its stats")
	# the buns and the Ninja in game
	main.level.player.invuln = 0.0 # no blinking in the pictures
	for c in ["q_bun", "mad_bun", "nerd_bun"]:
		GS.look = c
		await wait(0.2)
		await shot("25_%s" % c)
	GS.look = look0
	GS.clamp_stats()
	await wait(0.1)

func psg2_complete() -> void:
	# the Tomb of Makara needs 8 stamina
	GS.equip.ring_l = ""
	GS.equip.ring_r = ""
	GS.equip.armor = ""
	main.hud.close_panels()
	var st0: float = GS.max_st()
	main.hud._enter_world("tomb_of_makara")
	await wait(0.3)
	check(st0 >= 8 or main.level.id != "tomb_of_makara", "the Tomb of Makara turns you away under 8 stamina (%d)" % st0)
	GS.equip.armor = "emperor_dress_4" # +9 stamina
	main.hud._enter_world("tomb_of_makara")
	await wait(0.6)
	var lvl: Node = main.level
	check(lvl.id == "tomb_of_makara", "with 8 stamina the Gatekeeper opens the Tomb of Makara")
	lvl.player.invuln = 9999.0
	var deadly := 0
	var sky := 0
	for y in lvl.H:
		for x in lvl.W:
			if lvl.grid[lvl.idx(x, y)] == 3:
				deadly += 1
	for x in lvl.W:
		if not lvl.solid(x, 0):
			sky += 1
	check(deadly > 0 and sky == 0, "the tomb is an enclosed maze with deadly walls (%d deadly tiles)" % deadly)
	var home: Node = null
	for n in lvl.props.get_children() + lvl.entities.get_children():
		if n.get("target") == "town":
			home = n
	check(home != null and absf(home.position.y - lvl.player.position.y) < 20, "the portal home is next to where you start in the tomb")
	# every room can be reached: flood fill the open cells from the start
	var todo := [lvl.spawn_cell]
	var reach := {lvl.spawn_cell: true}
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x >= 0 and n.y >= 0 and n.x < lvl.W and n.y < lvl.H and not reach.has(n) and (not lvl.solid(n.x, n.y) or lvl.is_ledge(n.x, n.y)):
				reach[n] = true
				todo.append(n)
	var rooms_ok := true
	for r in 4:
		for c in (lvl.W - 4) / 11:
			if not reach.has(Vector2i(2 + c * 11 + 1, 2 + r * 11 + 9)):
				rooms_ok = false
	check(rooms_ok, "every room of the tomb's maze is connected")
	await shot("21_tomb_of_makara")
	# touching a deadly wall makes you faint
	var wall_cell := Vector2i(-1, -1)
	for y in lvl.H:
		for x in lvl.W:
			# the bottom of a deadly wall, with floor to stand on just left of it
			if lvl.grid[lvl.idx(x, y)] == 3 and not lvl.solid(x - 1, y) and not lvl.solid(x - 1, y - 1) and lvl.solid(x - 1, y + 1) and not lvl.is_ledge(x - 1, y + 1) and wall_cell.x < 0:
				wall_cell = Vector2i(x, y)
	check(wall_cell.x > 0, "the tomb has a deadly wall to walk into")
	lvl.player.position = Vector2(wall_cell.x * 16 - 12, wall_cell.y * 16 + 15)
	lvl.player.velocity = Vector2.ZERO
	Input.action_press("move_right")
	for i in 240:
		await get_tree().physics_frame
		if lvl.player.dead:
			break
	Input.action_release("move_right")
	check(lvl.player.dead, "a deadly wall in the tomb makes you faint")
	main.respawn()
	await wait(0.3)
	# the tomb's monsters and Makara
	await goto("tomb_of_makara")
	lvl = main.level
	for e in lvl.entities.get_children():
		if e.has_method("die") and not e == lvl.player:
			e.queue_free()
	var p: Node2D = lvl.player
	var ids := ["tomb_worm", "tomb_ufo", "sand_mantis", "tombstone", "vampire", "makara"]
	for i in ids.size():
		var m: Node = lvl.spawn_mob_at(ids[i], p.position + Vector2(30 + i * 40, -10))
		m.set_physics_process(false)
	await wait(0.3)
	await shot("22_tomb_monsters")
	# hits 40 harder below 160 defense, like Snow Valley
	p.invuln = 0.0
	GS.hp = 9999
	p.hurt(1, 0.0, p.position.x - 5)
	check(9999 - GS.hp >= 41 - GS.stat("def"), "the tomb's monsters hit 40 harder below 160 defense")
	GS.hp = GS.max_hp()
	p.invuln = 9999.0
	GS.equip.armor = ""
	# the Jade Ring stops poison
	GS.equip.ring_l = "jade_ring"
	GS.status.erase("poison")
	GS.add_status("poison")
	check(not GS.has_status("poison"), "the Jade Ring stops poison")
	GS.equip.ring_l = ""
	GS.add_status("poison")
	check(GS.has_status("poison"), "without it you can be poisoned")
	GS.status.erase("poison")
	# a Heartstone Ring restores 1 health every 10 seconds
	GS.equip.ring_l = "heartstone_ring"
	GS.hp = 1
	p.ring_t.ring_l = 9.9
	for i in 30:
		await get_tree().physics_frame
	check(GS.hp >= 2, "the Heartstone Ring restores health (%.0f)" % GS.hp)
	GS.equip.ring_l = ""
	GS.hp = GS.max_hp()
	# Combo Book Z: a Skull Dress from Bone + Fira + Linen with the book and a scroll
	for i in GS.BAG:
		GS.inv[i] = null
	GS.add_item("combo_book_z", 1)
	var slot_of := func(id: String) -> int:
		for i in GS.BAG:
			if GS.inv[i] and GS.inv[i].id == id:
				return i
		return -1
	var made := 0
	var pv := {}
	for t in 100:
		GS.add_item("bone", 1)
		GS.add_item("living_flame", 1)
		GS.add_item("linen", 1)
		GS.add_item("combination_scroll", 1)
		var sl := [slot_of.call("bone"), slot_of.call("living_flame"), slot_of.call("linen")]
		if t == 0:
			pv = GS.preview_combo(sl, true)
		GS.combine(sl, true)
		GS.remove_item("dust", 99)
		if GS.count("skull_dress") > 0:
			made = t + 1
			break
	check(pv.get("chance", 0) == 10 and pv.get("book", false), "Skull Dress is -75%%, +50%% with Combo Book Z and +35%% with a scroll (%s%%)" % pv.get("chance", "?"))
	check(made > 0, "Combo Book Z makes a Skull Dress (took %d tries)" % made)
	main.hud.open_book("z")
	await shot("23_combo_book_z")
	main.hud.close_panels()
	main.hud.open_book("u")
	await shot("23b_combo_book_u")
	main.hud.close_panels()
	# the wiki's stack sizes
	check(GS.stack_size("dark_heart") == 1 and GS.stack_size("living_flame") == 25 and GS.stack_size("legendary_roots") == 50 and GS.stack_size("nightmare_ore") == 10,
		"Dark Hearts don't stack, Fira stacks to 25, Legendary Roots to 50, Nightmare Ore to 10")
	# the Forbidden Bar is smelted while holding Blue Wood
	var fb := {}
	for r in Data.SMELT:
		if r.out == "forbidden_bar":
			fb = r
	check(fb.get("main", "") == "blue_wood" and fb.time == 7200, "the Forbidden Bar smelts from Blue Wood, Evil, Volcanic and Nightmare metal in 2 hours")
	# Miffie's Daily Bounty Quest after her 27 quests
	for q in Data.QUESTS:
		if q.npc == "mira" and not q.id in GS.quests_done:
			GS.quests_done.append(q.id)
	var bq := GS.next_quest("mira")
	check(bq.get("id", "").begins_with("bounty_") and bq.need.size() == 1, "Miffie gives a Daily Bounty Quest once her questline is done (%s)" % bq.get("text", ""))
	for id in bq.need:
		GS.add_item(id, 1)
	var keys0 := GS.count("master_key") + GS.gems
	GS.complete_quest(bq)
	check(GS.count("master_key") + GS.gems > keys0 and GS.next_quest("mira").is_empty(), "the bounty pays gems or a Master Key, once a day")
	# the Topaz steps in Nina's and 2219 OOP's quests
	var topaz := 0
	for q in Data.QUESTS:
		if q.need.has("topaz_stone"):
			topaz += 1
	check(topaz == 2, "Nina and 2219 OOP ask for 9 Topaz Stones")
	for i in GS.BAG:
		GS.inv[i] = null
	GS.add_item("iron_sword_cast", 1)

## Holds a direction without jumping.
func walk(dir: String, done: Callable, timeout: float) -> bool:
	Input.action_press(dir)
	var t := 0.0
	while not done.call() and t < timeout:
		await get_tree().physics_frame
		t += 1.0 / 60.0
	Input.action_release(dir)
	return done.call()

## Jumps straight up whenever on the ground (through one-way ledges).
func climb_up(done: Callable, timeout: float) -> bool:
	var p: CharacterBody2D = main.level.player
	var t := 0.0
	while not done.call() and t < timeout:
		if p.is_on_floor():
			Input.action_press("jump")
			await get_tree().physics_frame
			Input.action_release("jump")
		await get_tree().physics_frame
		t += 1.0 / 60.0
	return done.call()

## Holds a direction and jumps whenever on the ground, until `done` or time runs out.
func climb(dir: String, done: Callable, timeout: float) -> bool:
	var lvl: Node = main.level
	var p: CharacterBody2D = lvl.player
	var t := 0.0
	var from_y := p.position.y
	while not done.call() and t < timeout:
		if p.is_on_floor():
			from_y = p.position.y
			Input.action_press(dir)
			Input.action_press("jump")
			await get_tree().physics_frame
			Input.action_release("jump")
		elif p.velocity.y > 0 and lvl.floor_y(p.position.x, p.position.y) < from_y - 8 and lvl.floor_y(p.position.x, p.position.y) >= p.position.y - 1:
			Input.action_release(dir) # over a higher step: drop onto it
		await get_tree().physics_frame
		t += 1.0 / 60.0
	Input.action_release(dir)
	return done.call()

## The PSG2 jump, and the ninjas and robots behind the stone wall east of town.
func jump_and_underground() -> void:
	var lvl: Node = main.level
	var p: CharacterBody2D = lvl.player
	p.position = lvl.cell_pos(Vector2i(lvl.TOWN_OPENING[0] + 2, lvl.TOWN_MID - 1)) # under the opening
	p.velocity = Vector2.ZERO
	await wait(0.6)
	var y0 := p.position.y
	var top := y0
	var t_top := 0.0
	var spun := 0.0
	var t := 0.0
	Input.action_press("jump")
	await get_tree().physics_frame
	Input.action_release("jump")
	while t < 2.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if p.position.y < top:
			top = p.position.y
			t_top = t
		spun = maxf(spun, absf(p.body_sprite.rotation))
		if t > 0.1 and p.is_on_floor():
			break
	var apex := y0 - top
	check(apex > 42 and apex < 52, "a jump goes up almost 3 blocks (%.1f px)" % apex)
	check(t_top > 0.15 and t_top <= 0.25, "the jump rises smoothly for about 0.2 s (%.2f s)" % t_top)
	check(t > 0.5 and t < 0.8, "a jump is about 0.65 s in the air (%.2f s)" % t)
	check(spun > PI and p.body_sprite.rotation == 0.0, "the player does a full flip and lands upright")
	await tap("jump")
	await wait(0.1)
	await shot("03b_jump_flip")
	await wait(1.0)
	# jumping again in the air uses the green bar: one point a jump
	GS.st = 4.0
	var ground := p.position.y
	var high := ground
	await tap("jump")
	for k in 4:
		for f in 8:
			await get_tree().physics_frame
			high = minf(high, p.position.y)
		await tap("jump")
	for f in 10:
		await get_tree().physics_frame
		high = minf(high, p.position.y)
	check(GS.st < 1.0 and ground - high > 120, "4 air jumps on a full green bar go %.0f px high and use it up (%.1f left)" % [ground - high, GS.st])
	await shot("03b2_multi_jump")
	await until_floor(p)
	GS.st = 0.0
	GS.add_status("fatigue") # no stamina coming back during the check
	ground = p.position.y
	await tap("jump")
	for f in 8:
		await get_tree().physics_frame
	var y1 := p.position.y
	await tap("jump")
	for f in 12:
		await get_tree().physics_frame
	check(p.position.y > y1, "with an empty green bar there's no jump in the air")
	GS.status.erase("fatigue")
	await until_floor(p)
	GS.st = GS.max_st()
	# clicking: the world hits, the on-screen buttons press
	var sw0: int = p.swings
	await click(Vector2(240, 60))
	check(p.swings == sw0 + 1, "clicking in the world hits")
	var a_btn: TouchScreenButton = main.hud.touch_nodes[2]
	p.cooldown = 0
	await click(a_btn.global_position + Vector2(10, 10))
	check(p.swings == sw0 + 2, "clicking the red A button hits")
	var b_btn: TouchScreenButton = main.hud.touch_nodes[3]
	await click(b_btn.global_position + Vector2(10, 10))
	await get_tree().physics_frame
	check(not p.is_on_floor(), "clicking the green B button jumps")
	await until_floor(p)
	# three floors, like the original: jump up through the opening in the upper floor
	p.position = lvl.cell_pos(Vector2i(lvl.TOWN_OPENING[0] + 1, lvl.TOWN_MID - 1))
	GS.st = GS.max_st()
	await wait(0.4)
	await tap("jump")
	for k in 5:
		for f in 8:
			await get_tree().physics_frame
		if p.position.y < lvl.TOWN_TOP * 16 + 16:
			Input.action_press("move_left") # above the floor: steer onto it
		await tap("jump")
	Input.action_release("move_left")
	check(await walk("move_left", func(): return p.is_on_floor(), 2.0) and p.position.y <= lvl.TOWN_TOP * 16 + 1,
		"jumping up through the opening reaches the chests and furnaces")
	await shot("03a_upstairs")
	# picking a world opens a portal on the street, and hitting it takes you there
	main.open_world("grass_1")
	var portal := find_prop(func(n): return n.get_meta("gate", false))
	check(portal != null and portal.position == lvl.cell_pos(lvl.TOWN_PORTAL), "the Gatekeeper opens the portal on the street")
	main.hud.close_panels()
	# Banka: six backpacks of 30 slots next to your bag
	var sgirl := find_prop(func(n): return n.get("npc_id") == "banka")
	check(sgirl != null, "Banka (storage) is on the street")
	check(GS.storage.size() == 6 and GS.storage[0].size() == 30, "the storage has 6 backpacks of 30 slots")
	GS.add_item("rock", 7)
	var rock_i := -1
	for i in GS.BAG:
		if GS.inv[i] and GS.inv[i].id == "rock":
			rock_i = i
	var rocks0 := GS.count("rock")
	main.hud.open_storage()
	main.hud.storage_page = 2
	main.hud._bag_click(rock_i)
	var in_pack := 0
	for s0 in GS.storage[2]:
		if s0 and s0.id == "rock":
			in_pack += int(s0.n)
	check(in_pack == rocks0 and GS.count("rock") == 0, "tapping a stack puts it in the open backpack (%d rocks in backpack 3)" % in_pack)
	await shot("03f_storage")
	for k in GS.BACKPACK_SLOTS:
		if GS.storage[2][k] and GS.storage[2][k].id == "rock":
			GS.retrieve(2, k)
	check(GS.count("rock") == rocks0, "and tapping it there brings it back")
	main.hud.close_panels()
	# the Gatekeeper's cards, in the original's order, each with a map picture
	main.hud.open_panel("map")
	var cards: Node = main.hud.panels.map.find_child("Cards", true, false)
	check(cards.get_child_count() == Data.WORLD_CARDS.size() and cards.get_child(0).find_child("Activate", true, false) != null,
		"the Gatekeeper shows %d world cards with Activate buttons" % cards.get_child_count())
	await shot("04b_world_cards")
	main.hud.close_panels()
	check(not main.hud.day_label.visible, "no day counter in town (only in Survival)")
	# the friend, chat and emote buttons by the bars, and the emote panel
	for bn in ["FriendButton", "ChatButton", "EmoteButton"]:
		check(main.hud.hud_root.get_node_or_null(bn) != null, "the %s sits right of the bars" % bn)
	(main.hud.hud_root.get_node("EmoteButton") as Button).pressed.emit()
	var egrid: Node = main.hud.emote_panel.get_child(0)
	check(main.hud.emote_panel.visible and egrid.get_child_count() == 21, "the emote button opens the panel with 21 emotes")
	var drawn := 0
	for e in Data.EMOTES:
		if Art.emote(e).get_width() == 18:
			drawn += 1
	check(drawn == Data.EMOTES.size(), "all %d emotes are drawn" % drawn)
	(egrid.get_node("laugh") as TextureButton).pressed.emit()
	var bubble: Node = lvl.player.get_node_or_null("Emote")
	check(bubble != null and bubble.texture == Art.emote("laugh"), "tapping an emote shows it over your head")
	await get_tree().create_timer(0.3).timeout
	await shot("03g_emotes")
	await get_tree().create_timer(3.2).timeout
	check(not is_instance_valid(bubble) or bubble.is_queued_for_deletion(), "the emote fades after a few seconds")
	main.hud.toggle_emotes()
	check(not main.hud.emote_panel.visible, "and the emote button closes the panel again")
	# the stone wall needs the Wall Hammer
	var wall := find_prop(func(n): return n.get("kind") == "hammer_wall")
	check(wall != null, "a massive stone wall stands east of the furnaces")
	await stand_by(wall)
	await shot("03c_stone_wall")
	GS.sel = 0
	GS.inventory_changed.emit()
	p.cooldown = 0
	await tap("attack")
	await wait(0.6)
	check(not GS.flags.get("hammer_wall", false), "a sword can't break the stone wall")
	GS.inv[4] = {"id": "wall_hammer", "n": 1}
	GS.sel = 4
	GS.inventory_changed.emit()
	for i in 14:
		if GS.flags.get("hammer_wall", false):
			break
		p.cooldown = 0
		GS.st = GS.max_st()
		await tap("attack")
		await wait(0.7)
	check(GS.flags.get("hammer_wall", false), "the Wall Hammer breaks the stone wall")
	# through the tunnel and down the hole into the basement
	check(await walk("move_right", func(): return p.position.y > (lvl.TOWN_BASE - 2) * 16 and p.is_on_floor(), 12.0), "down the hole into the basement under Pixel Town")
	for id in ["nini", "nana", "nina", "fc_9912", "tt_1001", "oop_2219"]:
		check(find_prop(func(n): return n.get("npc_id") == id) != null, "%s lives under Pixel Town" % Data.NPCS[id].name)
	var nini := find_prop(func(n): return n.get("npc_id") == "nini")
	await stand_by(nini)
	await shot("03d_underground")
	await tap("attack")
	await wait(0.2)
	check(main.hud.panels.npc.visible, "Nini the ninja talks to you")
	await shot("03e_nini")
	main.hud.close_panels()
	# and back up the ledges under the hole
	p.position = lvl.cell_pos(Vector2i(lvl.TOWN_HOLE + 1, lvl.TOWN_BASE - 1))
	await wait(0.3)
	await climb_up(func(): return p.position.y <= (lvl.TOWN_MID + 2) * 16 + 1 and p.is_on_floor(), 8.0)
	var out: bool = await climb("move_right", func(): return p.position.y <= lvl.TOWN_MID * 16 + 1 and p.is_on_floor(), 4.0)
	check(out, "the ledges under the hole climb back up to the street")
	GS.inv[4] = null
	GS.sel = 0
	GS.inventory_changed.emit()
	# the whole town in one picture
	var cam: Camera2D = main.camera
	var size: Vector2 = lvl.world_size()
	var old_zoom := cam.zoom
	main.hud.visible = false
	main.set_process(false) # stop the camera following the player
	cam.zoom = Vector2.ONE * minf(480.0 / size.x, 270.0 / size.y)
	cam.position_smoothing_enabled = false
	cam.global_position = size / 2
	p.position = lvl.cell_pos(lvl.spawn_cell)
	await wait(0.3)
	await shot("03z_town_map")
	cam.zoom = old_zoom
	main.set_process(true)
	main.hud.visible = true

# ---------------------------------------------------------------- systems
const PickupScript := preload("res://scripts/pickup.gd")

## How many of an item lie on the ground as pickups.
func on_ground(id: String) -> int:
	var t := 0
	for e in main.level.entities.get_children():
		if e is PickupScript and e.item == id and not e.is_queued_for_deletion():
			t += e.n
	return t

func clear_ground() -> void:
	for e in main.level.entities.get_children():
		if e is PickupScript:
			e.queue_free()

func shop_button(container: String, label_start: String) -> Button:
	var box: Node = main.hud.panels.shop.find_child(container, true, false)
	for row in box.get_children():
		if row is HBoxContainer and (row.get_child(1) as Label).text.begins_with(label_start):
			return row.get_child(2)
	return null

## The systems behind the items: nothing earned is lost, shops, gear, ammo,
## mana, keys, furnaces, walls and saving.
func systems_check() -> void:
	await goto("town")
	await wait(0.3)
	var p: Node = main.level.player
	p.invuln = 9999.0
	var keep_inv: Array = GS.inv.duplicate(true)
	clear_ground()
	# a full bag never eats a reward: the rest drops at your feet
	for i in GS.BAG:
		GS.inv[i] = {"id": "rock", "n": 99}
	GS.give("wood", 40)
	await wait(0.1)
	check(on_ground("wood") == 40, "with a full bag, 40 Wood from a reward drops at your feet (%d)" % on_ground("wood"))
	GS.inv[GS.BAG - 1] = {"id": "silver_key", "n": 1}
	var before := {}
	var loot := GS.open_chest("silver")
	await wait(0.1)
	var ok: bool = loot.size() == Data.CHESTS.silver.rolls
	var got := {}
	for l in loot:
		got[l[0]] = got.get(l[0], 0) + int(l[1])
	for id in got:
		var have: int = (GS.count(id) if id != "rock" else GS.count(id) - 24 * 99) + on_ground(id)
		if id == "coin" or id == "gem":
			continue
		ok = ok and have >= got[id]
	check(ok, "a chest opened with a full bag keeps all its loot %s" % str(loot))
	GS.inv[0] = {"id": "wood_board", "n": 25}
	var helm_before := on_ground("wooden_helmet") + GS.count("wooden_helmet")
	GS.smith({"out": "wooden_helmet", "cost": {"wood_board": 25}})
	await wait(0.1)
	check(on_ground("wooden_helmet") + GS.count("wooden_helmet") == helm_before + 1, "the Crafter's item isn't lost when the bag is full")
	clear_ground()
	for i in GS.BAG:
		GS.inv[i] = null
	GS.inventory_changed.emit()
	# shops: buying takes the price, can't buy without the money, selling pays the item's price
	GS.coins = 100
	main.hud.open_shop("merchant")
	await wait(0.1)
	var buy := shop_button("Buy", "Small Potion")
	check(buy != null and not buy.disabled, "the Merchant sells Small Potions")
	buy.pressed.emit()
	await wait(0.1)
	check(GS.coins == 85 and GS.count("small_potion") == 1, "buying a Small Potion costs 15 coins (%d left)" % GS.coins)
	GS.coins = 10
	main.hud._refresh_shop("merchant")
	await wait(0.1)
	check(shop_button("Buy", "Small Potion").disabled, "with 10 coins you can't buy a 15-coin potion")
	GS.add_item("iron_ore", 3)
	main.hud._refresh_shop("merchant")
	await wait(0.1)
	var sell := shop_button("Sell", "Iron Ore")
	var coins0 := GS.coins
	sell.pressed.emit()
	await wait(0.1)
	check(GS.coins == coins0 + int(Data.ITEMS.iron_ore.sell) and GS.count("iron_ore") == 2, "selling one Iron Ore pays its price (%d)" % Data.ITEMS.iron_ore.sell)
	main.hud.close_panels()
	# gear: equipping adds the item's stats, taking it off removes them
	for slot in GS.EQUIP_SLOTS:
		GS.equip[slot] = ""
	GS.clamp_stats()
	var def0 := GS.stat("def")
	GS.inv[3] = {"id": "copper_helmet", "n": 1}
	GS.equip_from(3)
	var plus: int = Data.ITEMS.copper_helmet.stats.def if Data.ITEMS.copper_helmet.has("stats") else int(Data.ITEMS.copper_helmet.get("def", 0))
	check(GS.equip.helmet == "copper_helmet" and GS.stat("def") == def0 + plus, "a Copper Helmet adds %d defense when worn" % plus)
	GS.unequip("helmet")
	check(GS.stat("def") == def0 and GS.count("copper_helmet") == 1, "and taking it off puts it back in the bag")
	# bows use arrows, staffs use mana
	GS.inv[0] = {"id": "bow", "n": 1}
	GS.inv[1] = {"id": "arrow", "n": 2}
	GS.sel = 0
	p.cooldown = 0.0
	p._shoot("bow", Data.ITEMS.bow)
	p._shoot("bow", Data.ITEMS.bow)
	p._shoot("bow", Data.ITEMS.bow)
	check(GS.count("arrow") == 0, "each bow shot uses one arrow, and an empty quiver stops it")
	GS.mp = 3.0
	p._cast("blue_staff", Data.ITEMS.blue_staff)
	var mp_after := GS.mp
	p._cast("blue_staff", Data.ITEMS.blue_staff)
	check(is_equal_approx(mp_after, 1.0) and is_equal_approx(GS.mp, 1.0), "a Blue Staff spell costs 2 mana and won't cast with 1 left")
	# keys: no key, no chest
	GS.remove_item("silver_key", GS.count("silver_key"))
	check(GS.open_chest("silver").is_empty(), "a chest won't open without its key")
	# furnaces: not before it's done, and only once
	GS.flags["furnaces"] = true
	GS.furnaces[0] = null
	GS.add_item("copper_ore", 5)
	GS.add_item("coal", 1)
	var recipe: Dictionary = Data.SMELT[0]
	check(GS.start_smelt(0, recipe) == "" and GS.count("copper_ore") == 0, "smelting takes 5 Copper Ore and Coal")
	check(not GS.collect_smelt(0), "a bar can't be collected before it's done")
	GS.furnaces[0].done = GS.now() - 1.0
	var bars := GS.count("copper_bar")
	check(GS.collect_smelt(0) and not GS.collect_smelt(0) and GS.count("copper_bar") == bars + 1, "a finished bar is collected once")
	# quests pay once
	if not "gruff_1" in GS.quests_done:
		GS.add_item("wood_wall", 1)
		GS.complete_quest(Data.QUESTS[0])
	check(GS.next_quest("gruff").get("id", "") != "gruff_1" and GS.quests_done.count("gruff_1") == 1, "Brutus' quest can't be done twice")
	# swings don't go through walls
	GS.inv[0] = {"id": "sword_cast", "n": 1}
	GS.sel = 0
	var lvl: Node = main.level
	var c: Vector2i = Vector2i(int(p.position.x / lvl.T), int((p.position.y - 10) / lvl.T))
	var slime: Node = lvl.spawn_mob_at("slime", p.position + Vector2(p.facing * 20, 0))
	slime.hp = 999.0
	var wall := c + Vector2i(p.facing, 0)
	var old: int = lvl.grid[lvl.idx(wall.x, wall.y)]
	lvl.set_cell(wall.x, wall.y, 1)
	p.interact_target = null
	p._do_hit()
	var through: bool = slime.hp < 999.0
	lvl.set_cell(wall.x, wall.y, old)
	p._do_hit()
	check(not through and slime.hp < 999.0, "a swing can't hit a monster through a wall, but hits it in the open")
	slime.queue_free()
	await wait(0.05)
	# tools: gold needs an Iron Pickaxe or better; better tools take fewer hits
	var gold: Node = lvl.add_node("gold", Vector2i(2, 2))
	gold.position = p.position + Vector2(p.facing * 10, 0)
	GS.inv[0] = {"id": "wooden_pick", "n": 1}
	p.interact_target = null
	p._do_hit()
	var wood_hits: int = gold.hits
	GS.inv[0] = {"id": "iron_pick", "n": 1}
	p._do_hit()
	check(wood_hits == 0 and gold.hits == 1 and Data.hits_needed("gold", 4) < Data.hits_needed("gold", 3),
		"a Wooden Pick can't mine gold, an Iron Pickaxe can, and a Gold Pickaxe needs fewer hits (%d, %d)" % [wood_hits, gold.hits])
	gold.queue_free()
	# the Miner trades Survival Tokens, and won't without enough
	GS.remove_item("survival_token", GS.count("survival_token"))
	GS.add_item("survival_token", 20)
	main.hud.open_shop("miner")
	await wait(0.1)
	var seeds := GS.count("green_seeds")
	shop_button("Buy", "Magic Seeds (Green)").pressed.emit()
	await wait(0.1)
	check(GS.count("survival_token") == 5 and GS.count("green_seeds") == seeds + 1, "the Miner sells Green Seeds for 15 Survival Tokens")
	check(shop_button("Buy", "Magic Seeds (Green)").disabled, "and won't with only 5 tokens left")
	main.hud.close_panels()
	# potions cure what they're for
	GS.add_status("poison")
	GS.inv[0] = {"id": "antidote", "n": 1}
	check(GS.consume(0) and not GS.has_status("poison"), "an Antidote cures poison")
	# switching character hands the old one back; a character's weapon comes once
	var was: String = GS.look
	GS.inv[2] = {"id": "soldier", "n": 1}
	GS.use_character(2)
	check(GS.look == "soldier" and GS.count(was) >= 1, "becoming the Soldier gives your old character (%s) back as an item" % was)
	var pirate_blades := GS.count("gilded_blade")
	GS.flags["gave_pirate"] = true
	GS.inv[2] = {"id": "pirate", "n": 1}
	GS.use_character(2)
	check(GS.count("gilded_blade") == pirate_blades, "becoming the Pirate again doesn't hand out a second Golden Night")
	# saving keeps everything, and a damaged save falls back to the backup
	GS.storage[1][0] = {"id": "gold_bar", "n": 3}
	GS.flags["test_flag"] = true
	GS.coins = 1234
	GS.gems = 56
	GS.inv[4] = {"id": "copper_helmet", "n": 1}
	GS.equip_from(4)
	GS.save_game()
	GS.save_game()
	GS.storage[1][0] = null
	GS.coins = 0
	GS.flags.erase("test_flag")
	check(GS.load_game(), "the game loads")
	check(GS.storage[1][0] != null and GS.storage[1][0].id == "gold_bar" and GS.coins == 1234 and GS.gems == 56 and GS.flags.get("test_flag", false) and GS.equip.helmet == "copper_helmet" and GS.furnaces[0] == null and "gruff_1" in GS.quests_done,
		"saving keeps storage, coins, gems, unlocks, gear, furnaces and quests")
	var f := FileAccess.open(GS.slot_path(GS.slot), FileAccess.WRITE)
	f.store_string("{ this is not a save")
	f.close()
	GS.coins = 0
	check(GS.load_game() and GS.coins == 1234, "a damaged save loads from its backup instead of losing the character")
	check(FileAccess.file_exists("user://slot%d.damaged.json" % GS.slot), "and the damaged file is kept aside, not deleted")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://slot%d.damaged.json" % GS.slot))
	GS.save_game()
	GS.inv = keep_inv
	GS.inventory_changed.emit()
	p.invuln = 0.0

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
	main.hud.menu_step = "title"
	main.hud._refresh_title()
	check(main.hud.panels.title.get_node("Screen/Play") != null, "the title has Play and Options at the bottom left")
	main.hud.menu_step = "options"
	main.hud._refresh_title()
	await shot("01d_options")
	main.hud.menu_step = "invite"
	main.hud._refresh_title()
	await shot("01e_invite")
	main.start_game(false, "nurse", "Tester")
	check(GS.look == "nurse" and GS.player_name == "Tester", "a new game starts as the Nurse named Tester")
	check(GS.slot_info(0).get("name", "") == "Tester", "the character is saved in slot 1")
	check(GS.clock == 0.0 and not GS.is_night(), "a new game starts in the morning")
	GS.clock = 0.5
	check(GS.darkness() > 0.0 and not GS.is_night(), "sunset starts after 11 of 24 hours")
	GS.clock = 0.7
	check(GS.is_night(), "night starts after 15 of 24 hours")
	GS.clock = 0.0
	await wait(0.8)
	await shot("02_village")
	# talk to the Gatekeeper
	var keeper := find_prop(func(n): return n.get("npc_id") == "keeper")
	await stand_by(keeper)
	await tap("attack")
	var early: bool = main.hud.panels.npc.visible
	await wait(0.2)
	check(not early and main.hud.panels.npc.visible, "hitting the Gatekeeper opens his dialog when the swing lands")
	var PlayerScript := preload("res://scripts/player.gd")
	check(PlayerScript.swing_angle(0.0) > 0 and PlayerScript.swing_angle(0.2) < 0 and PlayerScript.swing_angle(0.55) > 1.0 and PlayerScript.swing_angle(1.0) == PlayerScript.swing_angle(0.0),
		"the swing goes up, slams down, holds low and comes back like PSG2")
	var silent := []
	for id in Sfx.sounds:
		if Sfx.sounds[id].data.size() < 400:
			silent.append(id)
	check(Sfx.sounds.size() >= 25 and silent.is_empty(), "%d sound effects are made (%s empty)" % [Sfx.sounds.size(), silent])
	await shot("03_keeper")
	main.hud.open_panel("map")
	await shot("04_world_list")
	main.hud.close_panels()
	if OS.has_environment("AT_SYSTEMS"): # set AT_SYSTEMS=1 to run only the systems checks
		await systems_check()
		print("AUTOTEST DONE, %d failures: %s" % [fails.size(), fails])
		get_tree().quit()
		return
	await jump_and_underground()
	if OS.has_environment("AT_QUICK"): # set AT_QUICK=1 to stop here
		print("AUTOTEST DONE, %d failures: %s" % [fails.size(), fails])
		get_tree().quit()
		return
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
	check(low == 0, "with defense 15 a 7-attack monster's hit can be blocked completely (0 damage)")
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
	# knockback: about a tile for monsters (out of touching range), none for bosses, a nudge for you
	var mum: Node = lvl.spawn_mob_at("mummy", p.position + Vector2(40, -2))
	mum.max_hp = 9999
	mum.hp = 9999
	await wait(0.6)
	mum.set_physics_process(false)
	await get_tree().physics_frame
	mum.set_physics_process(true)
	var x0: float = mum.position.x
	mum.take_damage(1, mum.position.x - 10, true)
	var far := 0.0
	while mum.knock_t > 0:
		await get_tree().physics_frame
	far = mum.position.x - x0 # how far the push itself moved it
	check(far > 10 and far < 26, "a knockback hit pushes a monster back about a tile (%.1f)" % far)
	# any hit, even a fist with no knockback, dazes a monster so it can't touch you right away
	mum.take_damage(1, mum.position.x - 10, false)
	check(mum.knock_t >= mum.STUN_TIME - 0.01 and mum.contact_cd > 0.3, "a hit dazes a monster and stops its touch for a moment")
	while mum.knock_t > 0:
		await get_tree().physics_frame
	var boss: Node = lvl.spawn_mob_at("king", p.position + Vector2(-60, -2))
	await wait(0.4)
	boss.take_damage(1, boss.position.x - 10, true)
	check(boss.knock_t <= 0.0 and mum.knock_t <= 0.0, "bosses don't get knocked back")
	mum.queue_free()
	boss.queue_free()
	p.invuln = 0.0
	var px0: float = p.position.x
	GS.hp = 9999
	p.hurt(40, 0.0, p.position.x - 10)
	var pfar := 0.0
	for f in 20:
		await get_tree().physics_frame
		pfar = maxf(pfar, absf(p.position.x - px0))
	check(pfar < 4, "getting hit barely moves you (%.1f px)" % pfar)
	p.invuln = 9999.0
	GS.hp = GS.max_hp()
	await shot("06_fight")
	p.cooldown = 0
	GS.st = GS.max_st()
	await tap("attack")
	await shot("06b_swing")
	# chop a tree with the wooden axe: 8 hits
	var tree := find_prop(func(n): return n.get("kind") == "tree" and n.position.y < 20 * 16)
	if tree:
		for e in lvl.entities.get_children():
			if e.has_method("die") and e.position.distance_to(tree.position) < 120:
				e.queue_free()
		await stand_by(tree)
		GS.sel = 1
		GS.inventory_changed.emit()
		for i in 14:
			if not tree.alive:
				break
			p.cooldown = 0
			await tap("attack")
			await wait(0.55)
			GS.st = GS.max_st()
			GS.hp = GS.max_hp()
		await wait(1.0)
		# the wood can roll down a cave next to the tree: go and get it
		for e in lvl.entities.get_children():
			if e.get("item") == "wood" and is_instance_valid(e):
				p.position = e.position
				await wait(0.4)
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
	# every Crafter tab has something on it, and the Hell Armor line works all the way up
	var tabs := {}
	for r1 in Data.SMITH:
		tabs[main.hud._crafter_tab(r1.out)] = true
	check(tabs.keys().size() == 5 and tabs.has("ring"), "the Crafter has weapons, helmets, armor, shields and rings %s" % [tabs.keys()])
	var made := []
	for id in ["hell_armor", "hell_armor_2", "hell_armor_3", "hell_armor_4"]:
		for r1 in Data.SMITH:
			if r1.out == id:
				for k in r1.cost:
					if not k.begins_with("hell_armor"):
						GS.add_item(k, r1.cost[k])
				if GS.smith(r1):
					made.append(id)
	check(made.size() == 4 and GS.count("hell_armor_4") == 1 and GS.count("hell_armor") == 0, "the Crafter makes Hell Armor, then II, III and IV %s" % [made])
	GS.remove_item("hell_armor_4", 1)
	GS.add_item("hell_armor", 1)
	GS.add_item("dark_stone", 1)
	main.hud.open_smith()
	main.hud.bag_tab = "armor"
	for i in Data.SMITH.size():
		if Data.SMITH[i].out == "hell_armor_2":
			main.hud.craft_sel = i
	main.hud._refresh_bag()
	await wait(0.1)
	var go: Button = main.hud.page.find_child("Go", true, false)
	check(go != null and go.disabled, "Hell Armor II can't be crafted with 1 of its 3 Dark Stones")
	await shot("11b_crafter_hell_armor")
	main.hud.close_panels()
	GS.remove_item("hell_armor", 1)
	GS.remove_item("dark_stone", 1)
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
	for w in ["grass_2", "grass_3", "dark_1", "dark_2", "hell_1", "hell_2", "ice_cavern", "modina_ruins", "nightmare_valley", "forbidden_city", "snow_valley", "tomb_of_makara"]:
		await goto(w)
		check(main.level.count_mobs() > 10, "%s has monsters (%d)" % [w, main.level.count_mobs()])
		await shot("20_" + w)
	for w in ["grass_arena", "dark_arena", "hell_arena", "dream_arena", "ghost_arena", "mushroom_valley", "fruit_loop", "eggcellence"]:
		await goto(w)
		main.level.arena_time = 179.0
		await wait(1.6)
		check(main.level.bosses_spawned, "%s boss arrives at 3 minutes" % w)
		await shot("30_" + w)
	await new_monsters()
	await psg2_complete()
	await gems_and_characters()
	await systems_check()
	# survival at night
	await goto("survival")
	await wait(0.2)
	check(main.hud.day_label.visible, "Survival Grasslands shows the day")
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
	# villagers call out when you walk up to them
	var brutus: Node = find_prop(func(n): return n.get("npc_id") == "gruff")
	main.level.player.position = brutus.position + Vector2(20, 0)
	await wait(0.3)
	check(brutus.name_label.text == "Looking for the Book of Survival?", "Brutus asks about the Book of Survival when you're near")
	await shot("42_greeting")
	# leaving asks first, then goes to "Select a character"
	main.hud.open_panel("leave")
	await wait(0.2)
	check(main.hud.panels.leave.visible, "leaving asks: Save and Leave Game?")
	await shot("43_save_and_leave")
	main.hud.panels.leave.get_node("Yes").pressed.emit()
	await wait(1.0)
	check(main.on_title() and main.hud.menu_step == "slots", "Yes saves and goes to Select a character")
	var scr: Node = main.hud.panels.title.get_node("Screen")
	check(scr.get_node_or_null("Slot0") != null and scr.get_node_or_null("Delete0") != null and scr.get_node_or_null("Delete1") == null, "slot 1 shows the character with a red X; empty slots have no X")
	await shot("44_select_character")
	scr.get_node("Delete0").pressed.emit()
	await wait(0.2)
	check(main.hud.menu_step == "delete" and GS.slot_info(0).size() > 0, "the red X asks before deleting")
	await shot("45_delete_ask")
	main.hud.menu_step = "slots"
	main.hud._refresh_title()
	print("AUTOTEST DONE, %d failures: %s" % [fails.size(), fails])
	get_tree().quit()
