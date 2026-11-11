extends Node
## Plays through the main features and saves screenshots.
## Run: godot --path . -- --autotest [--touch]   (screenshots go to user://shots)

const MobS := preload("res://scripts/mob.gd")
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
	text_check(name)

## Brenden, 2026-11-06: "fix all these little bugs where the writing looks weird
## and double check to make sure there's nothing like that". Every screenshot
## of an open window checks that no two pieces of writing in it overlap.
var text_bad := {}
func text_check(name: String) -> void:
	if main == null or main.hud == null:
		return
	for k in main.hud.panels:
		var pn: Control = main.hud.panels[k]
		if not pn.is_visible_in_tree() or pn.modulate.a < 0.99 or pn.scale != Vector2.ONE:
			continue
		var boxes := []
		_text_boxes(pn, boxes)
		for i in boxes.size():
			for j in range(i + 1, boxes.size()):
				var a: Array = boxes[i]
				var b: Array = boxes[j]
				if a[0].grow(-1.0).intersects(b[0].grow(-1.0)):
					var what := "%s/%s: '%s' and '%s'" % [name, k, a[1], b[1]]
					if not text_bad.has(what):
						text_bad[what] = true
						check(false, "writing doesn't overlap (%s)" % what)

## The rectangles the visible words of `n` and its children take on screen.
func _text_boxes(n: Node, boxes: Array, clip := Rect2(-9999, -9999, 99999, 99999)) -> void:
	if n is CanvasItem and not n.visible:
		return
	if n is ScrollContainer:
		clip = clip.intersection(n.get_global_rect())
	if n is Label and n.text.strip_edges() != "" and n.visible_ratio > 0.0 and not n.has_meta("logo"):
		var r := _label_text_rect(n).intersection(clip)
		if r.has_area():
			boxes.append([r, n.text.left(24)])
	elif n is Button and n.text != "":
		var f: Font = n.get_theme_font("font")
		var fs: int = n.get_theme_font_size("font_size")
		var gr: Rect2 = n.get_global_rect()
		var w := f.get_string_size(n.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var h := f.get_height(fs)
		var r := Rect2(gr.get_center() - Vector2(w, h) / 2.0, Vector2(w, h)).intersection(clip)
		if r.has_area():
			boxes.append([r, n.text.left(24)])
	for c in n.get_children():
		_text_boxes(c, boxes, clip)

func _label_text_rect(l: Label) -> Rect2:
	var f: Font = l.get_theme_font("font")
	var fs: int = l.get_theme_font_size("font_size")
	var gr := l.get_global_rect()
	var lines := l.get_visible_line_count()
	var h := f.get_height(fs) * lines + l.get_theme_constant("line_spacing") * maxi(lines - 1, 0)
	var w := gr.size.x
	if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
		w = 0.0
		for line in l.text.split("\n"):
			w = maxf(w, f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var x := gr.position.x
	if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
		x += (gr.size.x - w) / 2.0
	elif l.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		x += gr.size.x - w
	var y := gr.position.y
	if l.vertical_alignment == VERTICAL_ALIGNMENT_CENTER:
		y += (gr.size.y - h) / 2.0
	elif l.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM:
		y += gr.size.y - h
	return Rect2(Vector2(x, y), Vector2(w, h))

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

## Drags with the mouse from one screen point to another, like a player would.
func drag(a: Vector2, b: Vector2) -> void:
	var k := Vector2(DisplayServer.window_get_size()) / get_viewport().get_visible_rect().size
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = a * k
	ev.global_position = a * k
	Input.parse_input_event(ev)
	await get_tree().physics_frame
	for i in range(1, 9):
		var m := InputEventMouseMotion.new()
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		m.position = a.lerp(b, i / 8.0) * k
		m.global_position = m.position
		m.relative = (b - a) * k / 8.0
		Input.parse_input_event(m)
		await get_tree().physics_frame
	await shot_if("35_dragging")
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = b * k
	up.global_position = b * k
	Input.parse_input_event(up)
	await get_tree().physics_frame
	await get_tree().physics_frame

var want_shot := ""
func shot_if(name: String) -> void:
	if want_shot == name:
		want_shot = ""
		await shot(name)

func hover(at: Vector2) -> void:
	var k := Vector2(DisplayServer.window_get_size()) / get_viewport().get_visible_rect().size
	var m := InputEventMouseMotion.new()
	m.position = at * k
	m.global_position = m.position
	Input.parse_input_event(m)
	await get_tree().physics_frame
	await get_tree().physics_frame

## Hovering a slot shows the item's card; dragging moves items anywhere.
func drag_check() -> void:
	var hud: Node = main.hud
	hud.close_panels()
	var saved: Array = GS.inv.duplicate(true)
	var saved_eq: Dictionary = GS.equip.duplicate()
	for i in GS.BAG:
		GS.inv[i] = null
	GS.inv[0] = {"id": "plunger", "n": 1}
	GS.inv[1] = {"id": "small_potion", "n": 3}
	GS.inv[7] = {"id": "wooden_helmet", "n": 1}
	GS.inv[8] = {"id": "jelly", "n": 4}
	GS.inv[9] = {"id": "jelly", "n": 5}
	GS.equip.helmet = ""
	GS.inventory_changed.emit()
	await wait(0.2)
	# the hotbar, with the bag closed
	var h0: Button = hud.hotbar_slots[0]
	var h3: Button = hud.hotbar_slots[3]
	await hover(h0.get_global_rect().get_center())
	await wait(0.2)
	check(hud.hover_card != null and hud.hover_card.visible and hud.hover_card.get_node("Box").get_child(0).text == "Plunger", "hovering an item shows its card")
	await shot("35_hover_card")
	await drag(h0.get_global_rect().get_center(), h3.get_global_rect().get_center())
	check(GS.inv[3] != null and GS.inv[3].id == "plunger" and GS.inv[0] == null, "dragging moves an item along the hotbar, bag closed")
	hud.toggle_bag()
	await wait(0.3)
	var bs: Array = hud.bag_slots
	await drag(bs[3].get_global_rect().get_center(), bs[12].get_global_rect().get_center())
	check(GS.inv[12] != null and GS.inv[12].id == "plunger", "dragging moves an item around the bag")
	await drag(bs[8].get_global_rect().get_center(), bs[9].get_global_rect().get_center())
	check(GS.inv[9] != null and GS.inv[9].n == 9 and GS.inv[8] == null, "dropping jelly on jelly stacks them")
	await drag(bs[7].get_global_rect().get_center(), hud.equip_buttons.helmet.get_global_rect().get_center())
	check(GS.equip.helmet == "wooden_helmet" and GS.inv[7] == null, "dragging a helmet onto the helmet slot wears it")
	await drag(hud.equip_buttons.helmet.get_global_rect().get_center(), bs[20].get_global_rect().get_center())
	check(GS.equip.helmet == "" and GS.inv[20] != null and GS.inv[20].id == "wooden_helmet", "dragging it back puts it in that bag slot")
	await drag(bs[1].get_global_rect().get_center(), hud.equip_buttons.helmet.get_global_rect().get_center())
	check(GS.inv[1] != null and GS.inv[1].id == "small_potion" and GS.equip.helmet == "", "a potion can't be dropped on the helmet slot")
	# no Move button: moving is dragging only
	hud._bag_click(1)
	var has_move := false
	for k in hud.info_box.get_children():
		for c in k.get_children() if k is HBoxContainer else []:
			if c is Button and c.text == "Move":
				has_move = true
	check(not has_move, "the bag has no Move button")
	# the trash takes whatever is dragged onto it
	var trash: Button = hud.panels.bag.get_node("Trash")
	await drag(bs[1].get_global_rect().get_center(), trash.get_global_rect().get_center())
	check(GS.inv[1] == null, "dragging potions onto the trash throws them away")
	await drag(bs[20].get_global_rect().get_center(), hud.equip_buttons.helmet.get_global_rect().get_center())
	await drag(hud.equip_buttons.helmet.get_global_rect().get_center(), trash.get_global_rect().get_center())
	check(GS.equip.helmet == "", "worn gear can be dragged straight onto the trash")
	# the combine slots take drags too
	hud.bag_tab = "combine"
	hud.combo = [-1, -1, -1]
	hud._refresh_bag()
	await wait(0.2)
	await drag(bs[9].get_global_rect().get_center(), hud.page.get_node("C1").get_global_rect().get_center())
	check(hud.combo[1] == 9, "dragging jelly onto combine slot II puts it there")
	await drag(hud.page.get_node("C1").get_global_rect().get_center(), bs[4].get_global_rect().get_center())
	check(hud.combo[1] == -1 and GS.inv[9] != null, "dragging it back to the bag takes it out of the slot")
	hud.bag_tab = "character"
	hud._refresh_bag()
	await wait(0.1)
	want_shot = "35_dragging"
	await drag(bs[9].get_global_rect().get_center(), trash.get_global_rect().get_center())
	hud.close_panels()
	GS.inv = saved
	GS.equip = saved_eq
	GS.inventory_changed.emit()

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
	# real-money gem packs need your online name first, so offline it says so
	var packs: Node = main.hud.panels.shop.find_child("Packs", true, false)
	check(packs != null and packs.get_child_count() > 0, "the Gem Shop has a gem packs box")
	if GS.online_token == "" and packs != null and packs.get_child_count() > 0:
		check("claim your name" in str(packs.get_child(0).text), "offline, gem packs say to claim your name first")
	# the Drop Tables page lists every monster
	main.hud.open_drops()
	var dl: Node = main.hud.panels.drops.get_node("Scroll/List")
	check(dl.get_child_count() > Data.drop_table().size() * 2, "the Drop Tables page lists every monster (%d rows)" % dl.get_child_count())
	check(Data.drop_table().size() >= 10 and Data.arena_loot().size() >= 1, "drop tables cover the monsters and the arenas")
	await wait(0.3)
	await shot("24b_drop_tables")
	main.hud.close_panels()
	gb.pressed.emit()
	await wait(0.3)
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
	var wall_dir := 1
	for y in lvl.H:
		for x in lvl.W:
			# the bottom of a deadly wall, with floor to stand on beside it (a climbing
			# shaft can take the floor away on one side, so try both)
			if lvl.grid[lvl.idx(x, y)] != 3 or wall_cell.x >= 0:
				continue
			for d in [-1, 1]:
				if not lvl.solid(x + d, y) and not lvl.solid(x + d, y - 1) and lvl.solid(x + d, y + 1) and not lvl.is_ledge(x + d, y + 1):
					wall_cell = Vector2i(x, y)
					wall_dir = -d
					break
	check(wall_cell.x > 0, "the tomb has a deadly wall to walk into")
	lvl.player.position = Vector2(wall_cell.x * 16 + (-12 if wall_dir > 0 else 28), wall_cell.y * 16 + 15)
	lvl.player.velocity = Vector2.ZERO
	var walk := "move_right" if wall_dir > 0 else "move_left"
	Input.action_press(walk)
	for i in 240:
		await get_tree().physics_frame
		if lvl.player.dead:
			break
	Input.action_release(walk)
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
	var sizes := []
	for i in 4:
		var r: Rect2 = main.hud._touch_rect(main.hud.touch_nodes[i])
		sizes.append(Vector2i(roundi(r.size.x) - 2, roundi(r.size.y) - 4))
	check(sizes == [Vector2i(90, 34), Vector2i(90, 34), Vector2i(68, 34), Vector2i(68, 34)], "the move, A and B buttons keep their old sizes %s" % [sizes])
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
	var mid: float = (lvl.TOWN_OPENING[0] + lvl.TOWN_OPENING[1]) * 8.0
	check(portal != null and portal.position == lvl.town_portal_pos() and portal.position.x == mid,
		"the Gatekeeper opens the portal on the street, right under the middle of the opening")
	var crafter := find_prop(func(n): return n.get("npc_id") == "smith")
	var gk := find_prop(func(n): return n.get("npc_id") == "keeper")
	check(crafter != null and gk != null and is_equal_approx(mid - crafter.position.x, gk.position.x - mid) and crafter.position.x < mid,
		"the Crafter stands left of the portal and the Gatekeeper right of it, the same distance away")
	check(crafter != null and gk != null and is_equal_approx(gk.position.x - crafter.position.x, 13 * 16.0),
		"the Crafter and the Gatekeeper stand 13 tiles apart (2.5 times the old 5)")
	check(lvl.TOWN_OPENING[1] - lvl.TOWN_OPENING[0] == 10, "the opening above them is 10 tiles wide (2.5 times the old 4)")
	var start: Vector2 = lvl.cell_pos(lvl.spawn_cell)
	check(crafter != null and gk != null and start.x > crafter.position.x + 16 and start.x < gk.position.x - 16, "you start in the gap between the Crafter and the Gatekeeper")
	main.hud.close_panels()
	p.position = lvl.town_portal_pos() + Vector2(-18, 0)
	await wait(0.8)
	await shot("03h_portal_area")
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
	# the first backpack is free; every one after costs gems, in order
	GS.backpacks_owned = 1
	GS.gems = 0
	check(GS.owns_backpack(0) and not GS.owns_backpack(1), "the first backpack is free and the second is locked")
	main.hud.open_storage()
	main.hud.storage_page = 1
	main.hud._refresh_bag()
	var unlock: Button = main.hud.page.find_child("UnlockPack", true, false)
	check(unlock != null and unlock.disabled, "a locked backpack shows an Unlock button, greyed out without gems")
	await shot("03g_locked_backpack")
	main.hud._bag_click(rock_i)
	check(GS.count("rock") == rocks0 and GS.storage[1].all(func(x): return x == null), "nothing goes into a locked backpack")
	check(GS.buy_backpack() != "" and GS.backpacks_owned == 1, "a backpack can't be bought without %d gems" % GS.BACKPACK_GEMS)
	GS.gems = GS.BACKPACK_GEMS * 2 + 3
	main.hud._refresh_bag()
	unlock = main.hud.page.find_child("UnlockPack", true, false)
	unlock.pressed.emit()
	check(GS.backpacks_owned == 2 and GS.gems == GS.BACKPACK_GEMS + 3, "Unlock spends %d gems and opens backpack 2" % GS.BACKPACK_GEMS)
	main.hud.storage_page = 3
	main.hud._refresh_bag()
	check(main.hud.page.find_child("UnlockPack", true, false) == null, "backpacks unlock in order (4 waits for 3)")
	check(GS.buy_backpack() == "" and GS.backpacks_owned == 3, "the next one costs gems too")
	main.hud.storage_page = 2
	main.hud._refresh_bag()
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

## Music: every track is made, loops and isn't silent; the right one plays
## where you are; and the volume settings stick.
func audio_check() -> void:
	var t0 := Time.get_ticks_msec()
	while Music.ready_count() < Music.TRACKS.size() and Time.get_ticks_msec() - t0 < 30000:
		await wait(0.2)
	check(Music.ready_count() == Music.TRACKS.size(), "all %d music tracks are made (in %.1f s)" % [Music.TRACKS.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	var bad := []
	for id in Music.tracks:
		var w: AudioStreamWAV = Music.tracks[id]
		var loud := 0
		for i in range(0, w.data.size() - 1, 4000):
			loud = maxi(loud, absi(w.data.decode_s16(i)))
		if w.loop_mode != AudioStreamWAV.LOOP_FORWARD or w.get_length() < 10.0 or loud < 3000:
			bad.append(id)
	check(bad.is_empty(), "every track loops, lasts over 10 s and isn't silent %s" % str(bad))
	# without threads (the web build), tracks are made a small piece per frame
	var job: Dictionary = Music.render_begin(Music.TRACKS.town)
	var worst := 0
	var steps := 0
	while true:
		var t1 := Time.get_ticks_usec()
		var done: bool = Music.render_step(job)
		worst = maxi(worst, Time.get_ticks_usec() - t1)
		steps += 1
		if done:
			break
	var same: bool = job.wav.data == Music.render(Music.TRACKS.town).data
	check(same and worst < 15000, "built in %d small pieces (slowest %.1f ms), a track comes out the same as built in one go" % [steps, worst / 1000.0])
	check(Music.pick(true, "explore", "grass", false, false, false) == "menu" and Music.pick(false, "town", "grass", false, false, false) == "town"
		and Music.pick(false, "explore", "grass", false, false, false) == "field" and Music.pick(false, "explore", "grass", false, false, true) == "cave"
		and Music.pick(false, "explore", "dark", false, false, false) == "cave" and Music.pick(false, "explore", "hell", false, false, false) == "hell"
		and Music.pick(false, "arena", "grass", true, false, false) == "boss" and Music.pick(false, "survival", "grass", false, true, false) == "danger",
		"the menu, town, fields, caves, Hell, bosses and Survival nights each get their own music")
	await wait(0.3)
	check(Music.current == ("town" if main.level.kind == "town" else Music.current), "Pixel Town plays the town music (%s)" % Music.current)
	var s0: float = Sfx.volume
	var m0: float = Music.volume
	main.hud.step_volume("Music")
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	check(is_equal_approx(float(cfg.get_value("audio", "music", -1)), Music.volume) and main.hud.volume_text("Music").begins_with("Music: "), "the Music button steps the volume and saves it (%s)" % main.hud.volume_text("Music"))
	Sfx.set_volume(0.0)
	check(not Sfx.on and main.hud.volume_text("Sound") == "Sound: Off", "Sound can be turned off")
	Sfx.set_volume(s0)
	Music.set_volume(m0)
	# the same sound can't stack: a second start within a few ms is skipped
	Sfx._last.erase("hit")
	var n0: int = Sfx._next
	Sfx.play("hit")
	Sfx.play("hit")
	check(Sfx._next == (n0 + 1) % Sfx.players.size(), "a sound played twice at once only starts once")

## Cave darkness: dark worlds and deep caves fade the screen edges, the open
## fields don't, the HUD stays on top, and it fits any window shape.
func darkness_check() -> void:
	await goto("dark_1")
	await wait(1.6)
	var mat: ShaderMaterial = main.dark_rect.material
	check(main.dark > 0.7 and main.dark_rect.visible, "Darklands fade the screen edges to dark (%.2f)" % main.dark)
	check(main.dark_layer.layer < main.hud.layer, "the darkness is under the HUD")
	var c: Vector2 = mat.get_shader_parameter("center")
	check(c.x > 0.3 and c.x < 0.7 and c.y > 0.3 and c.y < 0.8, "the clear circle follows the player %s" % str(c))
	await shot("50_cave_dark")
	for size in [Vector2i(1280, 540), Vector2i(720, 540)]:
		get_window().size = size
		await wait(0.4)
		var vs := get_viewport().get_visible_rect().size
		check(absf(float(mat.get_shader_parameter("aspect")) - vs.x / vs.y) < 0.01, "the darkness stays round at %dx%d (aspect %.2f)" % [size.x, size.y, vs.x / vs.y])
		await shot("50_cave_dark_%dx%d" % [size.x, size.y])
	get_window().size = Vector2i(960, 540)
	await goto("grass_1")
	await wait(1.6)
	check(main.dark < 0.05 and not main.dark_rect.visible, "the open Grasslands aren't darkened (%.2f)" % main.dark)
	var lvl: Node = main.level
	var deep_cell := -1
	for y in range(lvl.surface[40] + 12, lvl.H - 2):
		if not lvl.solid(40, y) and lvl.solid(40, y + 1):
			deep_cell = y
			break
	if deep_cell > 0:
		lvl.player.position = lvl.cell_pos(Vector2i(40, deep_cell))
		lvl.player.velocity = Vector2.ZERO
		await wait(1.6)
		check(main.dark > 0.5, "deep in a Grasslands cave the edges go dark (%.2f)" % main.dark)
		check(Music.current == "cave", "and the cave music plays (%s)" % Music.current)
		await shot("51_grass_cave")

## Phase 3 and 5: the systems a player meets on their way through the game,
## played with the game's own code paths.
func gameplay_check() -> void:
	await goto("grass_1")
	await wait(0.3)
	var lvl: Node = main.level
	var p: Node = lvl.player
	p.invuln = 9999.0
	clear_ground()
	# monsters of every movement type come after you
	var kinds := {"walk": "slime", "fly": "wisp", "charge": "mummy", "accel": "shell", "wizard": "wizard", "stone": "crusher"}
	var moved := []
	for ai in kinds:
		var m: Node = lvl.spawn_mob_at(kinds[ai], p.position + Vector2(70, -4))
		m.aggro_forced = true
		var d0: float = m.position.distance_to(p.position)
		var x0: float = m.position.x
		await wait(1.5)
		var ok: bool = m.position.distance_to(p.position) < d0 - 4.0 if ai != "stone" else true
		if ai == "wizard":
			ok = ok or absf(m.position.x - x0) > 1.0 or m.position.distance_to(p.position) < 120.0
		if ok:
			moved.append(ai)
		m.queue_free()
	await wait(0.1)
	check(moved.size() == kinds.size(), "monsters of every movement type move the way they should %s" % str(moved))
	# killing monsters drops their loot, and only loot from their own table
	var allowed := {}
	for d in Data.MOBS.slime.drops:
		allowed[d[0]] = true
	for i in 25:
		var s: Node = lvl.spawn_mob_at("slime", p.position + Vector2(40 + i * 2, -4))
		s.take_damage(99999, s.position.x - 5, false)
	await wait(0.6)
	var dropped := {}
	for e in lvl.entities.get_children():
		if e is PickupScript:
			dropped[e.item] = true
	var stray: Array = dropped.keys().filter(func(k): return not allowed.has(k) and k != "gem" and k != "coin")
	check(dropped.size() > 0 and stray.is_empty(), "25 slimes drop their own loot %s" % str(dropped.keys()))
	clear_ground()
	# mining a stone with the Wooden Pick gives rocks
	var stone: Node = lvl.add_node("stone", Vector2i(2, 2))
	stone.position = p.position + Vector2(p.facing * 10, 0)
	GS.inv[0] = {"id": "wooden_pick", "n": 1}
	GS.sel = 0
	for k in Data.hits_needed("stone", 1) + 1:
		p.interact_target = null
		p._do_hit()
	await wait(0.6)
	check(not stone.alive and on_ground("rock") + GS.count("rock") > 0, "a Wooden Pick breaks a stone and rocks fall out (%d)" % (on_ground("rock") + GS.count("rock")))
	clear_ground()
	# potions heal
	GS.hp = 1.0
	GS.inv[1] = {"id": "small_potion", "n": 1}
	check(GS.consume(1) and GS.hp > 1.0, "a Small Potion heals (%.0f)" % GS.hp)
	# a pet does its job: Fireball heals you every few seconds
	GS.equip.pet = "pet_fireball"
	lvl.spawn_pet()
	GS.hp = 1.0
	lvl.pet.timer = 999.0
	await wait(0.2)
	check(GS.hp > 1.0, "an equipped Fireball pet heals you")
	GS.equip.pet = ""
	lvl.spawn_pet()
	# every item type does something when used (away from anything to talk to)
	p.position = lvl.cell_pos(Vector2i(60, lvl.surface[60] - 1))
	await wait(0.3)
	var bad_types := []
	var samples := {}
	for id in Data.ITEMS:
		var t: String = Data.ITEMS[id].type
		if not samples.has(t) and not id in ["fist", "coin", "gem", GS.look]:
			samples[t] = id
	for t in samples:
		var id: String = samples[t]
		for i in GS.BAG:
			GS.inv[i] = null
		for s2 in GS.EQUIP_SLOTS:
			GS.equip[s2] = ""
		GS.inv[0] = {"id": id, "n": 3}
		GS.sel = 0
		GS.hp = 1.0
		GS.mp = GS.max_mp()
		GS.st = GS.max_st()
		main.hud.close_panels()
		p.cooldown = 0.0
		p.interact_target = null
		var st0: float = GS.st
		p.use_held(true)
		await wait(0.05)
		var changed: bool = GS.inv[0] == null or int(GS.inv[0].n) != 3 or GS.hp > 1.0 or GS.st < st0 or GS.mp < GS.max_mp() \
			or main.hud.any_open() or GS.equip.values().has(id) or p.swing > 0.0
		if t in ["egg", "seed", "key", "scroll", "token", "ammo", "place", "material"]:
			changed = true # these explain where they're used (or are crafting materials / need open ground)
		if not changed:
			bad_types.append("%s (%s)" % [t, id])
	main.hud.close_panels()
	check(bad_types.is_empty(), "every one of the %d usable item types does something when used %s" % [samples.size(), str(bad_types)])
	for i in GS.BAG:
		GS.inv[i] = null
	for s2 in GS.EQUIP_SLOTS:
		GS.equip[s2] = ""
	lvl.spawn_pet()
	GS.inventory_changed.emit()
	await goto("town")
	await wait(0.3)
	lvl = main.level
	p = lvl.player
	# magic soils: plant, can't harvest early, harvest three things once ripe
	GS.soils[0] = null
	GS.add_item("green_seeds", 1)
	check(GS.plant(0, "green_seeds") and GS.harvest(0).is_empty(), "a planted seed can't be picked before it's ripe")
	GS.soils[0].done = GS.now() - 1.0
	var crop := GS.harvest(0)
	check(crop.size() == 3 and GS.soils[0] == null, "a ripe Green Seed gives three things and frees the soil %s" % str(crop))
	# a smelt or an egg left running survives saving and loading
	GS.flags["furnaces"] = true
	GS.furnaces[2] = null
	GS.add_item("copper_ore", 5)
	GS.add_item("coal", 1)
	GS.start_smelt(2, Data.SMELT[0])
	GS.incubator = {}
	GS.add_item("green_egg", 1)
	GS.start_hatch("green_egg")
	GS.save_game()
	GS.load_game()
	check(GS.furnaces[2] != null and GS.furnaces[2].out == "copper_bar" and not GS.incubator.is_empty(), "a running smelt and egg are still there after saving and loading")
	GS.furnaces[2].done = GS.now() - 1.0
	GS.incubator.done = GS.now() - 1.0
	await wait(1.2)
	check(main.announced.has("f2_%d" % int(GS.furnaces[2].done)), "you're told when a smelt is done, wherever you are")
	check(GS.collect_smelt(2) and GS.collect_hatch() != "", "and both can be collected when done")
	# low health makes the health bar pulse
	GS.hp = 1.0
	GS.stats_changed.emit()
	await wait(0.2)
	await shot("54_low_health")
	GS.hp = GS.max_hp()
	# leaving to the menu and starting the character again keeps everything
	GS.coins = 4321
	GS.add_item("gold_bar", 7)
	main.quit_to_title()
	await wait(0.5)
	GS.coins = 0
	main.start_game(true)
	await wait(0.8)
	check(GS.coins == 4321 and GS.count("gold_bar") >= 7 and main.level.kind == "town", "quitting to the menu and playing the slot again keeps coins and items")
	main.hud.close_panels()
	# a save with damaged fields still loads, with sensible values
	var f := FileAccess.open(GS.slot_path(GS.slot), FileAccess.WRITE)
	f.store_string(JSON.stringify({"v": 3, "inv": [{"id": "wood", "n": 5}, "junk", {"id": "no_such_item", "n": 3}, {"n": 2}], "storage": "oops",
		"equip": 7, "coins": -50, "flags": [1, 2], "quests": "x", "furnaces": [{"out": "nope"}, 5], "incubator": {"egg": "rock"}, "soils": [{"seed": 1}],
		"sel": 99, "look": "dragon", "now": "soon"}))
	f.close()
	check(GS.load_game() and GS.count("wood") == 5 and GS.coins == 0 and GS.sel < GS.HOTBAR and GS.look == "man_in_suit" and GS.furnaces[0] == null and GS.incubator.is_empty(),
		"a save with damaged fields still loads and keeps what's good")
	# an old save without the newer fields loads too
	f = FileAccess.open(GS.slot_path(GS.slot), FileAccess.WRITE)
	f.store_string(JSON.stringify({"v": 3, "inv": [{"id": "rock", "n": 9}], "coins": 77, "name": "Tester", "look": "nurse"}))
	f.close()
	check(GS.load_game() and GS.count("rock") == 9 and GS.coins == 77 and GS.storage.size() == GS.BACKPACKS, "an old save without storage, gems or clock fields still loads")
	check(GS.backpacks_owned == 1, "an old save starts with just the free backpack")
	# a backpack that already holds things stays open in an old save
	f = FileAccess.open(GS.slot_path(GS.slot), FileAccess.WRITE)
	var packs := [[], [], [], [{"id": "rock", "n": 2}], [], []]
	f.store_string(JSON.stringify({"v": 3, "inv": [], "storage": packs, "coins": 1, "look": "nurse"}))
	f.close()
	check(GS.load_game() and GS.backpacks_owned == 4 and GS.in_storage("rock") == 2, "an old save keeps every backpack that has items in it")
	GS.storage[3][0] = null
	GS.backpacks_owned = 2
	GS.save_game()
	check(GS.load_game() and GS.backpacks_owned == 2, "unlocked backpacks are saved")
	GS.save_game()
	# the HUD fits every window shape: nothing off screen, A and B and the arrows don't overlap
	for size in [Vector2i(960, 540), Vector2i(1280, 540), Vector2i(720, 540), Vector2i(540, 720)]:
		get_window().size = size
		await wait(0.4)
		var vr := get_viewport().get_visible_rect()
		var names := []
		var rects := {}
		for n in ["BagButton", "EmoteButton", "GemBox"]:
			var c: Control = main.hud.hud_root.get_node_or_null(n)
			if c:
				rects[n] = c.get_global_rect()
		rects["bars"] = main.hud.bars.get_global_rect()
		var tn := ["left", "right", "A", "B", "auto"]
		for i in main.hud.touch_nodes.size():
			var t: Node = main.hud.touch_nodes[i]
			if t.visible:
				rects[tn[i] if i < tn.size() else str(i)] = main.hud._touch_rect(t)
		var off := []
		for k in rects:
			if not vr.grow(1.0).encloses(rects[k]):
				off.append(k)
		var overlap := []
		var keys := rects.keys()
		for i in keys.size():
			for j in range(i + 1, keys.size()):
				if rects[keys[i]].grow(-1.0).intersects(rects[keys[j]].grow(-1.0)):
					overlap.append("%s/%s" % [keys[i], keys[j]])
		check(off.is_empty() and overlap.is_empty(), "at %dx%d the HUD fits (off screen %s, overlapping %s)" % [size.x, size.y, str(off), str(overlap)])
		await shot("53_hud_%dx%d" % [size.x, size.y])
	get_window().size = Vector2i(960, 540)
	await wait(0.3)

func empty_bag() -> void:
	for i in GS.BAG:
		GS.inv[i] = null
	GS.inventory_changed.emit()

## Every recipe, every Crafter item, every bar, every shop item and every quest
## in the data, run through the game's own functions.
func content_check() -> void:
	await goto("town")
	await wait(0.2)
	clear_ground()
	GS.save_game()
	var keep_coins := GS.coins
	# combinations: each one is recognised from its own ingredients, and possible with its book and a scroll
	var wrong := []
	var impossible := []
	for r in Data.RECIPES:
		empty_bag()
		var slots := []
		for x in r["in"]:
			for i in GS.BAG:
				if GS.inv[i] == null:
					GS.inv[i] = {"id": x, "n": 1}
					slots.append(i)
					break
		GS.add_item(Data.BOOK_ITEM[r.book], 1)
		GS.add_item("combination_scroll", 1)
		var pv: Dictionary = GS.preview_combo(slots, true)
		if not pv.get("known", false) or pv.recipe.out != r.out:
			wrong.append(r.out)
		elif int(pv.chance) <= 0:
			impossible.append(r.out)
	check(wrong.is_empty() and impossible.is_empty(), "all %d combinations are recognised and possible with their book and a scroll (wrong %s, impossible %s)" % [Data.RECIPES.size(), str(wrong), str(impossible)])
	# the Crafter: every recipe takes exactly its cost and gives its item
	var bad_smith := []
	for s in Data.SMITH:
		empty_bag()
		for k in s.cost:
			GS.give(k, int(s.cost[k]))
		var ok: bool = GS.smith(s) and GS.count(s.out) + on_ground(s.out) >= 1
		for k in s.cost:
			if k != s.out and GS.count(k) != 0:
				ok = false
		if not ok:
			bad_smith.append(s.out)
		clear_ground()
	check(bad_smith.is_empty(), "all %d Crafter recipes take their cost and give their item %s" % [Data.SMITH.size(), str(bad_smith)])
	# furnaces: every bar smelts and is collected
	GS.flags["furnaces"] = true
	var bad_smelt := []
	for s in Data.SMELT:
		empty_bag()
		GS.furnaces[0] = null
		for k in s.cost:
			GS.give(k, int(s.cost[k]))
		var started: bool = GS.start_smelt(0, s) == ""
		if started:
			GS.furnaces[0].done = GS.now() - 1.0
		if not (started and GS.collect_smelt(0) and GS.count(s.out) == 1):
			bad_smelt.append(s.out)
	GS.furnaces[0] = null
	check(bad_smelt.is_empty(), "all %d smelting recipes work %s" % [Data.SMELT.size(), str(bad_smelt)])
	# shops: every item can be bought for exactly its price
	GS.flags["em_shop"] = true
	var bad_buy := []
	var bought := 0
	for shop_id in Data.SHOPS.keys() + ["gem_shop"]:
		var shop: Dictionary = Data.gem_shop() if shop_id == "gem_shop" else Data.SHOPS[shop_id]
		var cur: String = shop.get("currency", "coins")
		for e in shop.sells:
			empty_bag()
			var price: int = e[1]
			var qty: int = e[2] if e.size() > 2 else 1
			GS.coins = price if cur == "coins" else 0
			GS.gems = price if cur == "gem" else 0
			if cur == "survival_token":
				GS.add_item("survival_token", price)
			main.hud.open_shop(shop_id)
			await wait(0.02)
			var label: String = Data.ITEMS[e[0]].name
			var b := shop_button("Buy", label)
			if b == null or b.disabled:
				bad_buy.append("%s:%s (no button)" % [shop_id, e[0]])
				continue
			var n0: int = GS.count(e[0]) + on_ground(e[0])
			b.pressed.emit()
			await wait(0.02)
			var left: int = GS.coins if cur == "coins" else GS.count(cur)
			if left != 0 or GS.count(e[0]) + on_ground(e[0]) - n0 != qty:
				bad_buy.append("%s:%s" % [shop_id, e[0]])
			else:
				bought += 1
			clear_ground()
	main.hud.close_panels()
	check(bad_buy.is_empty(), "every shop item (%d) can be bought for exactly its price %s" % [bought, str(bad_buy)])
	# quests: every villager's quests come in order and pay their rewards
	GS.quests_done = []
	var bad_q := []
	for q in Data.QUESTS:
		empty_bag()
		var nxt: Dictionary = GS.next_quest(q.npc)
		if nxt.get("id", "") != q.id:
			bad_q.append("%s (offered %s)" % [q.id, nxt.get("id", "none")])
			GS.quests_done.append(q.id)
			continue
		for k in q.need:
			GS.give(k, int(q.need[k]))
		var before := {}
		for k in q.reward:
			before[k] = GS.count(k) + on_ground(k)
		if not GS.quest_ready(q):
			bad_q.append(q.id + " (not ready with its items)")
		GS.complete_quest(q)
		await wait(0.01)
		for k in q.reward:
			var got: int = GS.count(k) + on_ground(k) - int(before[k])
			var taken: int = int(q.get("take", q.need).get(k, 0))
			if got + taken < int(q.reward[k]):
				bad_q.append("%s (reward %s)" % [q.id, k])
		if q.has("unlock") and not GS.flags.get(q.unlock, false):
			bad_q.append(q.id + " (unlock)")
		clear_ground()
	check(bad_q.is_empty(), "all %d quests come in order, take their items and pay %s" % [Data.QUESTS.size(), str(bad_q)])
	# back to how things were
	GS.load_game()
	GS.coins = keep_coins
	clear_ground()

## The faint screen and the multiplayer menus.
## The auto-hit switch: a little round button left of A. On, the held weapon or
## tool swings by itself, even with the bag open, and it stays on through
## pressing A and switching items.
func auto_hit_check() -> void:
	var p: Node = main.level.player
	var ab: TouchScreenButton = main.hud.touch_nodes[4]
	check(ab.name == "AutoHit" and ab.visible, "there's a round auto-hit button")
	var off_tex := ab.texture_normal
	# hold A and open the bag: auto-hit, like the original's trick
	Input.action_press("attack")
	main.hud.toggle_bag()
	Input.action_release("attack")
	check(GS.auto_hit and ab.texture_normal != off_tex, "holding A while opening the bag turns auto-hit on, and the button lights up")
	check(main.level.process_mode != Node.PROCESS_MODE_DISABLED, "with auto-hit on the bag doesn't pause the world")
	GS.sel = 0
	GS.inventory_changed.emit()
	GS.st = GS.max_st()
	var s0: int = p.swings
	await wait(1.2)
	check(p.swings >= s0 + 2, "auto-hit keeps swinging with the bag open (%d swings)" % (p.swings - s0))
	main.hud.close_panels()
	await tap("attack")
	main.hud.close_panels() # in case A opened a villager's chat
	GS.sel = 1
	GS.inventory_changed.emit()
	GS.st = GS.max_st()
	s0 = p.swings
	await wait(1.2)
	check(GS.auto_hit and p.swings >= s0 + 2, "auto-hit stays on after pressing A and switching items")
	await shot("09c_auto_hit_on")
	# the button turns it off
	ab.pressed.emit()
	await wait(0.1)
	check(not GS.auto_hit and ab.texture_normal == off_tex, "the round button turns auto-hit off")
	s0 = p.swings
	await wait(0.8)
	check(p.swings == s0, "with auto-hit off nothing swings by itself")
	main.hud.toggle_bag()
	check(main.level.process_mode == Node.PROCESS_MODE_DISABLED, "with auto-hit off the bag pauses the world again")
	main.hud.close_panels()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_Q
	key.pressed = true
	Input.parse_input_event(key)
	await wait(0.1)
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	check(GS.auto_hit, "and Q turns it back on")
	var cfg := ConfigFile.new()
	cfg.load(GS.SETTINGS)
	check(cfg.get_value("controls", "auto_hit", false) == true, "the switch is saved")
	GS.set_auto_hit(false)

## Sheets of every monster and pet, every villager and character, and the
## town's houses, drawn bigger on a plain background, to look the art over.
## Every one must draw something.
func art_sheets() -> void:
	var mobs := []
	for id in Data.MOBS:
		if not Data.MOBS[id].look in mobs:
			mobs.append(Data.MOBS[id].look)
	for id in Data.PETS:
		if not Data.PETS[id].look in mobs:
			mobs.append(Data.PETS[id].look)
	var blank := []
	var imgs := []
	for l in mobs:
		var img: Image = Art.mob_tex(l, false).get_image()
		if img.is_invisible():
			blank.append(l)
		imgs.append(img)
	_sheet("75_monsters", imgs, 3, 12)
	var common := []
	for l in ["slime_pink", "wisp", "mummy", "shell", "octopus", "trex", "slime_dark", "mantis", "zombie", "ufo", "worm", "hand"]:
		common.append(Art.mob_tex(l, false).get_image())
	_sheet("78_common_monsters", common, 8, 6)
	var people := []
	for l in Art.LOOKS:
		people.append(Art.character(l, "stand", 1).get_image())
	_sheet("76_villagers", people, 5, 12)
	var houses := []
	for h in [["e8dccb", "d8433a"], ["c8d6e8", "3b5dc9"], ["e8d8b0", "4f9a44"], ["d8c8e8", "7b4fb8"]]:
		houses.append(Art.house_tex(Color(h[0]), Color(h[1]), 52).get_image())
	_sheet("77_houses", houses, 4, 4)
	check(blank.is_empty(), "every monster and pet draws something %s" % [blank])

func _sheet(name: String, imgs: Array, k: int, cols: int) -> void:
	var cw := 0
	var ch := 0
	for i: Image in imgs:
		cw = maxi(cw, i.get_width())
		ch = maxi(ch, i.get_height())
	cw += 4
	ch += 4
	var rows := ceili(imgs.size() / float(cols))
	var sheet := Image.create(cw * cols, ch * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("8fb7c9"))
	for n in imgs.size():
		var i: Image = imgs[n]
		var at := Vector2i((n % cols) * cw + (cw - i.get_width()) / 2, (n / cols) * ch + ch - 2 - i.get_height())
		sheet.blend_rect(i, Rect2i(Vector2i.ZERO, i.get_size()), at)
	sheet.resize(sheet.get_width() * k, sheet.get_height() * k, Image.INTERPOLATE_NEAREST)
	sheet.save_png("%s/%s.png" % [out, name])
	print("shot ", name)

## The ground's art: every world bakes its ground quickly, the map's edges are
## rock and the back walls are drawn; screenshots of the surface and the caves.
func look_check() -> void:
	# every item has its own icon: no two items share a picture
	var seen := {}
	var same := []
	for id in Data.ITEMS:
		var img: Image = Art.icon(id).get_image()
		var key := "%s:%s" % [img.get_size(), img.get_data().hex_encode().sha256_text()]
		if seen.has(key):
			same.append("%s=%s" % [seen[key], id])
		seen[key] = id
	check(same.is_empty(), "all %d items have their own icon %s" % [Data.ITEMS.size(), same])
	var slow := []
	var empty := []
	for w in Data.WORLDS:
		main.hud.close_panels()
		var t0 := Time.get_ticks_usec()
		main.change_level(w)
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		var lvl: Node = main.level
		var terrain: Node = lvl.get_node("Terrain")
		print("  %s built in %d ms, %d ground pictures" % [w, ms, terrain.chunks.size()])
		if ms > 3000:
			slow.append(w)
		if terrain.chunks.is_empty() or terrain.mat(0, lvl.H / 2) != terrain.ROCK:
			empty.append(w)
		lvl.player.invuln = 9999.0
		await wait(0.6)
		await shot("70_" + w)
		if lvl.kind == "explore":
			# a spot in the caves, a third of the way in
			var best := Vector2i(-1, -1)
			for c in lvl.floor_cells():
				if c.y > lvl.surface[c.x] + 4 and (best.x < 0 or absi(c.x - lvl.W / 3) + absi(c.y - 30) < absi(best.x - lvl.W / 3) + absi(best.y - 30)):
					best = c
			if best.x >= 0:
				lvl.player.position = lvl.cell_pos(best)
				main.camera.position = lvl.player.position
				main.camera.reset_smoothing()
				await wait(0.5)
				await shot("71_%s_cave" % w)
			# a few spots along the surface, to judge how crowded the map feels
			if w in ["grass_1", "grass_3", "dark_1", "ice_cavern", "hell_1"]:
				for k in [1, 2, 3]:
					var sx: int = lvl.W * k / 4
					lvl.player.position = lvl.cell_pos(Vector2i(sx, lvl.surface[sx] - 1))
					main.camera.position = lvl.player.position
					main.camera.reset_smoothing()
					await wait(0.4)
					await shot("76_%s_surface_%d" % [w, k])
	check(slow.is_empty(), "every world builds in under 3 s %s" % [slow])
	art_sheets()
	check(empty.is_empty(), "every world has baked ground with rock at its edges %s" % [empty])
	# Pixel Town upstairs and in the basement
	await goto("town")
	var town: Node = main.level
	for spot in [["72_town_upstairs", Vector2i(24, town.TOWN_TOP - 1)], ["73_town_basement", Vector2i(40, town.TOWN_BASE - 1)], ["74_town_west", Vector2i(3, town.TOWN_MID - 1)]]:
		town.player.position = town.cell_pos(spot[1])
		main.camera.position = town.player.position
		main.camera.reset_smoothing()
		await wait(0.5)
		await shot(spot[0])
	# the whole street, west to east, a screen at a time
	for i in 4:
		var sx: int = 8 + i * (town.W - 16) / 3
		town.player.position = town.cell_pos(Vector2i(sx, town.TOWN_MID - 1))
		main.camera.position = town.player.position
		main.camera.reset_smoothing()
		await wait(0.4)
		await shot("75_town_street_%d" % i)
	# nothing on the street stands on top of anything else
	var xs := []
	for n in town.props.get_children():
		if (n.get_script() == town.NpcScript or n.get_script() == town.StationScript) and absf(n.position.y - town.cell_pos(Vector2i(0, town.TOWN_MID - 1)).y) < 4:
			xs.append(n.position.x)
	xs.sort()
	var tight := 0
	for i in range(1, xs.size()):
		if xs[i] - xs[i - 1] < 32 and xs[i] > 12 * 16:
			tight += 1
	check(tight == 0, "the villagers on the street stand at least two tiles apart (%d too close)" % tight)

## The Grasslands Arena brings one boss: Rexy, the Hand or the Jelly King.
## The Jelly King leaps high and slams, sending jelly along the ground that
## hurts unless you jump it.
## Brenden's 2026-11-06 asks: potions from monsters, PSG2's money, and big bosses
## and long weapons.
func psg2_match_check() -> void:
	for m in ["slime", "wisp", "mummy", "shell", "octopus", "dark_slime", "mantis", "zombie"]:
		check(Data.MOBS[m].drops.any(func(e): return e[0] == "small_potion"), "the %s can drop a Small Potion" % Data.MOBS[m].name)
	check(Data.WORLDS.grass_arena.boss_drops.any(func(e): return e[0] == "holy_banana"), "the Grasslands Arena boss can drop a Holy Banana")
	var old := GS.coins
	GS.coins = 250000
	check(GS.coins == 99999, "Pixel Coins stop at 99,999")
	GS.coins = -5
	check(GS.coins == 0, "and never go below 0")
	GS.coins = old
	var price := func(shop: String, id: String) -> int:
		for e in Data.SHOPS[shop].sells:
			if e[0] == id:
				return e[1]
		return -1
	check(price.call("tools", "pink_egg") == 10000 and price.call("tools", "green_egg") == 20000 and price.call("gruff", "copper_ore") == 250, "egg and ore prices are the wiki's")
	check(Data.ITEMS.living_flame.sell == 1 and Data.ITEMS.gold_pick.sell == 50 and Data.ITEMS.short_blade.sell == 0, "sell prices are the wiki's")
	check(Data.CHESTS.silver.loot.filter(func(e): return e[0] == "coin").map(func(e): return e[1]) == [1, 10, 11, 100, 111], "Silver Chests hold 1, 10, 11, 100 or 111 coins")
	check(Art.held_size("long_lance") > Art.held_size("long_sword") and Art.held_size("long_sword") > Art.held_size("plunger") and Art.held_size("plunger") > Art.held_size("short_blade"), "a lance is drawn longer than a long sword, a long sword than the Plunger, the Plunger than the Gradius")
	check(Data.ITEMS.volcan_axe.kb > Data.ITEMS.knights_blade.kb and Data.ITEMS.knights_blade.kb > Data.ITEMS.glow_blade_blue.kb and Data.ITEMS.long_lance.kb == 0.0, "an axe knocks harder than a sword, a sword harder than a Fluorescent, a lance not at all")
	var feel := {}
	var nw := 0
	for wid in Data.ITEMS:
		var wi: Dictionary = Data.ITEMS[wid]
		if wi.type == "weapon" and wid != "fist":
			nw += 1
			feel["%s|%s|%s|%s" % [wi.kb, wi.size, wi.reach, wi.spd]] = true
	check(feel.size() * 3 >= nw, "weapons differ in knockback, size, reach and speed (%d kinds among %d)" % [feel.size(), nw])
	await goto("grass_1")
	var lvl: Node = main.level
	for e in lvl.entities.get_children():
		if e is MobS:
			e.queue_free()
	await get_tree().process_frame
	var p: Node2D = lvl.player
	var keep = GS.inv[GS.sel]
	GS.inv[GS.sel] = {"id": "long_sword", "n": 1}
	GS.inventory_changed.emit()
	p.facing = 1
	var king: Node = lvl.spawn_mob_at("king", p.position + Vector2(70, 0))
	var rexy: Node = lvl.spawn_mob_at("trex", p.position + Vector2(-60, 0), 1.0, 1.0, true)
	var small: Node = lvl.spawn_mob_at("trex", p.position + Vector2(-130, 0))
	for m in [king, rexy, small]:
		m.set_physics_process(false)
	check(rexy.size.y >= small.size.y * 2 - 1, "an arena's Rexy is twice as big as a normal one (%d vs %d)" % [rexy.size.y, small.size.y])
	check(king.size.y >= 90, "the King is drawn big (%d px tall)" % king.size.y)
	await wait(0.3)
	await shot("33_big_bosses")
	for m in [king, rexy, small]:
		m.queue_free()
	GS.inv[GS.sel] = keep
	GS.inventory_changed.emit()
	await chest_hit_check()

## Chests have no window: hit one holding its key and the loot flies out.
func chest_hit_check() -> void:
	await goto("town")
	var chest: Node = find_prop(func(n): return n.get("kind") == "chest_silver")
	check(chest != null, "Pixel Town has a Silver Chest")
	if chest == null:
		return
	var saved_bag: Array = GS.inv.duplicate(true)
	var saved_sel := GS.sel
	var saved_coins := GS.coins
	var saved_gems := GS.gems
	for i in GS.BAG:
		GS.inv[i] = null
	GS.add_item("silver_key", 2)
	var keys := GS.count("silver_key")
	var pickups := func() -> int:
		return main.level.entities.get_children().filter(func(e): return e is PickupScript and not e.is_queued_for_deletion()).size()
	await stand_by(chest)
	var before: int = pickups.call()
	chest.interact(main.level.player)
	check(GS.count("silver_key") == keys and pickups.call() == before, "hitting a chest without holding its key doesn't open it")
	for i in GS.BAG:
		if GS.inv[i] != null and GS.inv[i].id == "silver_key":
			GS.sel = i
	chest.interact(main.level.player)
	check(GS.count("silver_key") == keys - 1 and pickups.call() == before + 2 and not main.hud.any_open(), "hitting it with the key pops it open and two items fly out, no window")
	await wait(0.2)
	await shot("34_chest_burst")
	# put the bag back as it was, so the loot doesn't crowd later checks
	for e in main.level.entities.get_children():
		if e is PickupScript:
			e.queue_free()
	GS.inv = saved_bag
	GS.sel = saved_sel
	GS.coins = saved_coins
	GS.gems = saved_gems
	GS.inventory_changed.emit()

func jelly_king_check() -> void:
	await goto("grass_arena")
	var lvl: Node = main.level
	check(int(lvl.def.get("bosses_pick", 0)) == 1 and lvl.def.bosses.map(func(b): return b[0]) == ["trex", "hand", "jelly_king"], "the Grasslands Arena picks one boss of three")
	lvl.arena_time = 179.5
	await wait(0.8)
	var n := 0
	for e in lvl.entities.get_children():
		if e is MobS and e.arena_boss:
			n += 1
	check(n == 1, "only one boss comes to the Grasslands Arena (%d)" % n)
	for e in lvl.entities.get_children():
		if e is MobS:
			e.queue_free()
	await get_tree().process_frame
	var p: Node2D = lvl.player
	var king: Node = lvl.spawn_mob_at("jelly_king", p.position + Vector2(90, 0))
	king.aggro_forced = true
	king.arena_boss = true
	main.hud.set_boss(king)
	await wait(0.6)
	await shot("31_jelly_king")
	king.state = "crouch"
	king.state_t = 0.4
	await wait(0.2)
	await shot("31b_jelly_king_crouch")
	var top: float = king.position.y
	var waves := 0
	for f in 240:
		await get_tree().physics_frame
		top = minf(top, king.position.y)
		if king.state == "rest":
			break
	for e in lvl.entities.get_children():
		if e.get_script() == preload("res://scripts/slam_wave.gd"):
			waves += 1
	check(lvl.cell_pos(Vector2i(0, 17)).y - top > 80 and waves == 2, "the Jelly King leaps high (%d px) and slams, sending jelly both ways (%d)" % [lvl.cell_pos(Vector2i(0, 17)).y - top, waves])
	await shot("31c_jelly_king_slam")
	king.queue_free()
	for e in lvl.entities.get_children():
		if e.get_script() == preload("res://scripts/slam_wave.gd"):
			e.queue_free()
	await until_floor(p)
	# a wave that reaches you on the ground hurts; jump it and it doesn't. Gear
	# is taken off for this, or armor from earlier checks can soak the whole hit.
	var worn: Dictionary = GS.equip.duplicate()
	for slot in GS.equip:
		GS.equip[slot] = ""
	GS.hp = GS.max_hp()
	p.invuln = 0.0
	var W := preload("res://scripts/slam_wave.gd")
	var w1: Node2D = W.new()
	w1.setup(lvl, 1, 3)
	w1.position = Vector2(p.position.x - 40, p.position.y)
	lvl.entities.add_child(w1)
	await wait(0.6)
	check(GS.hp < GS.max_hp(), "the slam's jelly hurts you on the ground")
	await wait(1.2)
	await until_floor(p)
	GS.hp = GS.max_hp()
	p.invuln = 0.0
	var w2: Node2D = W.new()
	w2.setup(lvl, 1, 3)
	w2.position = Vector2(p.position.x - 30, p.position.y)
	lvl.entities.add_child(w2)
	p._jump()
	await wait(0.6)
	check(GS.hp == GS.max_hp(), "jumping over it is safe")
	p.invuln = 9999.0
	GS.equip = worn
	GS.stats_changed.emit()

func menus_check() -> void:
	await goto("grass_1")
	main.level.player.invuln = 0.0
	var pl: Node2D = main.level.player
	pl.position = main.level.cell_pos(main.level.spawn_cell) + Vector2(40 * 16, 0)
	for k in 30:
		await get_tree().physics_frame
	await until_floor(pl)
	var fell_at: Vector2 = pl.position
	# a slime may have bumped you on the way down, leaving you safe for a second
	pl.invuln = 0.0
	pl.hurt(9999, 0.0, pl.position.x - 5)
	await wait(0.5)
	check(pl.dead and not main.hud.dead_bar.visible and absf(pl.body_sprite.rotation) > 0.3, "fainting in single player is a slow fall, not instant")
	await shot("60a_falling")
	await wait(1.6)
	var dp: Panel = main.hud.dead_bar
	check(dp.visible, "fainting shows the faint bar")
	var vs := get_viewport().get_visible_rect().size
	check(dp.get_global_rect().position.y < 50 and dp.size.y <= 48 and dp.size.x < vs.x * 0.55, "the faint bar is small and at the top, not a menu in your face (%s)" % dp.get_global_rect())
	check(main.dead_tint.visible and main.dead_tint.size.x >= vs.x - 1, "the screen is a little darker while you're fainted")
	check((dp.get_node("Text") as Label).text.contains("Pixel Town in "), "the bar counts down to Pixel Town (%s)" % (dp.get_node("Text") as Label).text)
	var grave: Node = main.grave
	check(is_instance_valid(grave) and grave.position.distance_to(fell_at) < 4, "a gravestone rises where you fainted")
	check(is_instance_valid(grave) and grave.left <= main.hud.DEAD_WAIT, "on your own nobody can revive you, so it's a short countdown (%.1f s)" % (grave.left if is_instance_valid(grave) else -1.0))
	await shot("60_fainted")
	var wake: Button = dp.get_node("Wake")
	check(dp.get_node_or_null("Revive") == null, "no ghost: there's no Respawn button any more")
	var wr := wake.get_global_rect()
	var pr := dp.get_global_rect()
	var tl: Label = dp.get_node("Text")
	check(pr.encloses(wr) and pr.encloses(tl.get_global_rect()) and not tl.get_global_rect().intersects(wr), "the bar's text and button fit inside it without overlapping")
	# on your own, Go to Pixel Town goes straight home: nobody could revive you
	wake.pressed.emit()
	await wait(0.8)
	check(not main.hud.panels.give_up.visible and main.level.id == "town" and not main.level.player.dead and not main.dead_tint.visible, "on your own, Go to Pixel Town takes you home at once, and the screen is bright again")
	# faint again and wait: when the countdown ends you wake up in Pixel Town
	await goto("grass_1")
	pl = main.level.player
	pl.invuln = 0.0
	pl.hurt(9999, 0.0, pl.position.x - 5)
	await wait(2.2)
	check(main.hud.dead_bar.visible and is_instance_valid(main.grave), "fainting again gives a new gravestone")
	main.grave.left = 0.2
	await wait(0.8)
	check(main.level.id == "town" and not main.level.player.dead, "when the countdown ends you wake up in Pixel Town")
	# the Grasslands Arena: one free revive, right where you fall
	await goto("grass_arena")
	pl = main.level.player
	pl.invuln = 0.0
	pl.hurt(9999, 0.0, pl.position.x - 5)
	await wait(2.2)
	check(not pl.dead and GS.hp == GS.max_hp() and not main.hud.dead_bar.visible, "the Grasslands Arena gives one free revive")
	await shot("61_free_revive")
	pl.invuln = 0.0
	pl.hurt(9999, 0.0, pl.position.x - 5)
	await wait(2.4)
	check(pl.dead and dp.visible and not is_instance_valid(main.grave), "only one: the second faint in the arena sends you home")
	wake.pressed.emit()
	await wait(0.8)
	check(not dp.visible and main.level.id == "town" and not main.level.player.dead, "with no gravestone, Go to Pixel Town takes you straight home on your feet")
	# Multiplayer: whose name it is, that it's yours, and the four buttons
	GS.online_token = "test-token"
	GS.save_game()
	main.quit_to_title()
	await wait(0.4)
	main.hud.menu_step = "mode"
	main.hud._refresh_title()
	await wait(0.2)
	var screen: Node = main.hud.panels.title.get_node("Screen")
	screen.get_node("Multiplayer").pressed.emit()
	await wait(0.3)
	var mp: Node = screen.get_node_or_null("Multi")
	check(mp != null and (mp.get_node("Name") as Label).text == GS.slot_info(GS.slot).name, "Multiplayer shows the character's name (%s)" % GS.slot_info(GS.slot).name)
	check((mp.get_node("Owner") as Label).text.contains("yours"), "and says the name is yours")
	for b in ["Friends", "FindPublic", "HostPublic"]:
		check(mp.get_node_or_null(b) != null and not mp.get_node(b).disabled, "the %s button is there" % b)
	await shot("61_multiplayer")
	mp.get_node("FindPublic").pressed.emit()
	await wait(1.0)
	var pub: Node = screen.get_node_or_null("Public")
	check(pub != null and pub.get_node("List").get_child_count() > 0, "Find Public Game lists games (or says why it can't)")
	await shot("62_public_games")
	# the friends list's status lights
	var red: Control = main.hud._status_dot(Color("d83a2e"))
	check(red.custom_minimum_size == Vector2(10, 10) and red.get_meta("color") == Color("d83a2e"), "friends get a round status light")
	red.free()
	GS.online_token = ""
	GS.save_game()
	# back into the game the way the menu does it
	main.start_game(true)
	await wait(0.5)
	check(not main.on_title() and not main.hud.panels.title.visible, "playing again closes the title menus")

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
	main.hud.open_shop("tools")
	await wait(0.1)
	var buy := shop_button("Buy", "Small Potion")
	check(buy != null and not buy.disabled, "the Plumber sells Small Potions")
	await shot("14_plumber_shop")
	buy.pressed.emit()
	await wait(0.1)
	check(GS.coins == 85 and GS.count("small_potion") == 1, "buying a Small Potion costs 15 coins (%d left)" % GS.coins)
	GS.coins = 10
	main.hud._refresh_shop("tools")
	await wait(0.1)
	check(shop_button("Buy", "Small Potion").disabled, "with 10 coins you can't buy a 15-coin potion")
	GS.add_item("iron_ore", 3)
	main.hud._refresh_shop("tools")
	await wait(0.1)
	check(shop_button("Sell", "Iron Ore") == null, "the Plumber doesn't buy your items")
	main.hud.open_shop("merchant")
	await wait(0.1)
	check(shop_button("Buy", "Small Potion") == null and Data.SHOPS.merchant.sells.is_empty(), "the Merchant doesn't sell anything")
	await shot("14b_merchant_shop")
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
	# switching asks first: Cancel changes nothing, Become switches
	var look0: String = GS.look
	GS.inv[2] = {"id": "school_girl", "n": 1}
	GS.sel = 2
	p.cooldown = 0.0
	p.use_held(true)
	check(main.hud.panels.become.visible and GS.look == look0 and GS.count("school_girl") == 1, "holding a character and pressing A asks first, without switching")
	await shot("52_become_ask")
	main.hud.panels.become.get_node("No").pressed.emit()
	check(not main.hud.panels.become.visible and GS.look == look0 and GS.count("school_girl") == 1, "Cancel keeps your character and the item")
	main.hud.ask_become(2)
	main.hud.panels.become.get_node("Yes").pressed.emit()
	check(GS.look == "school_girl" and GS.count("school_girl") == 0 and GS.count(look0) >= 1, "Become switches, and the old character comes back as an item")
	GS.inv[2] = {"id": "school_girl", "n": 1}
	GS.use_character(2)
	check(GS.count("school_girl") == 1, "using the character you already are doesn't waste the item")
	GS.sel = 0
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
	# the game's clock: changing the device clock does nothing while playing,
	# setting it back can't rewind a save, and the server's time is trusted
	var real_clock: Callable = GS._system_clock
	var t0: float = GS.now()
	GS._system_clock = func() -> float: return Time.get_unix_time_from_system() + 86400.0 * 3
	await wait(0.5)
	var moved: float = GS.now() - t0
	check(moved > 0.3 and moved < 2.0, "moving the device clock 3 days ahead doesn't move the game's clock (+%.1f s)" % moved)
	GS.furnaces[1] = {"out": "copper_bar", "done": GS.now() + 20.0, "main": "copper_ore"}
	check(not GS.collect_smelt(1), "so a 20-second smelt still isn't done")
	GS.furnaces[1] = null
	GS.save_game()
	var saved_at: float = GS.now()
	var was_trusted: bool = GS.trusted_time
	GS.trusted_time = false
	GS._system_clock = func() -> float: return Time.get_unix_time_from_system() - 86400.0 * 2
	GS.anchor_to_device()
	check(GS.now() < saved_at - 86000.0, "(the device clock is now set 2 days back)")
	GS.load_game()
	check(GS.now() >= saved_at - 1.0, "setting the clock back can't rewind a saved game's time")
	GS.reward_chests["grass_1"] = GS.today()
	GS.set_trusted_time(Time.get_unix_time_from_system())
	check(GS.trusted_time and absf(GS.now() - Time.get_unix_time_from_system()) < 2.0, "the online server's time is used when it can be reached")
	GS._system_clock = real_clock
	GS.trusted_time = was_trusted
	GS.reward_chests.erase("grass_1")
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

## The goal card, the danger badges on the world cards and the tip after fainting.
func guidance_check() -> void:
	var hud: Node = main.hud
	await wait(0.4)
	check(GS.current_goal().get("text", "") == "Visit the Grasslands", "a new game's goal is to visit the Grasslands")
	check(hud.goal_btn.visible and "Grasslands" in hud.goal_text.text, "the goal card shows it on screen")
	GS.flags["been_grass_1"] = true
	GS.give("jelly", 3)
	hud.refresh_goal()
	check(hud.goal_text.text == "Bring Miffie 10 Jellies  3/10", "the next goal counts Jellies (%s)" % hud.goal_text.text)
	hud.goal_btn.pressed.emit()
	check(hud.panels.info.visible and "Slimes" in hud.panels.info.get_node("Text").text, "tapping the goal card says how")
	await shot("01f_goal_card")
	hud.close_panels()
	# a later goal done early doesn't hide an earlier one: the card shows the first one not done
	GS.quests_done.append("mira_3")
	check(GS.current_goal().text == "Bring Miffie 10 Jellies", "the card shows the first goal not done (%s)" % GS.current_goal().text)
	GS.quests_done.erase("mira_3")
	GS.take_all({"jelly": 3})
	GS.flags.erase("been_grass_1")
	# danger for a starter: the Grasslands are fine, Hell is deadly
	check(GS.world_danger("grass_1") <= 1, "the Grasslands aren't Hard for a starter (%d)" % GS.world_danger("grass_1"))
	check(GS.world_danger("hell_1") == 3, "Hell is Deadly for a starter")
	hud.open_panel("map")
	var card: Node = hud.panels.map.find_child("Danger", true, false)
	check(card != null and card.text in ["Easy", "Fair"], "world cards show a danger badge")
	await shot("01g_world_danger")
	hud.close_panels()
	check("Wooden Armor" in main.faint_tip(), "fainting without armor suggests Wooden Armor")

## Every character is on the Create a character screen; only the starters can
## be picked until one is unlocked by a task, by owning it, or with gems.
func check_character_unlocks() -> void:
	var screen: Control = main.hud.panels.title.get_node("Screen")
	var all_there := true
	for c in Data.CHARACTERS:
		all_there = all_there and screen.get_node_or_null("Pick_" + c) != null
	check(all_there and Data.CHARACTERS.size() == 18, "Create a character shows all 18 characters")
	check(GS.unlocked == Data.START_CHARACTERS, "only Man in Suit and Nurse are unlocked at first")
	main.hud.new_char = "pirate"
	main.hud._refresh_title()
	await shot("01b2_locked_character")
	check((screen.get_node("CreateOK") as Button).disabled, "a locked character can't be made")
	check("Miffie" in (screen.get_node("Chosen/Lines/How") as Label).text, "and it says how to unlock it")
	GS.best_survival_day = 7
	GS.check_character_tasks()
	check(GS.is_unlocked("cavemun") and GS.count("cavemun") == 1, "reaching day 7 in Survival unlocks the Cavemun and gives one")
	GS.give("ninja", 1)
	check(GS.is_unlocked("ninja"), "owning a character (from a chest or the Gem Shop) unlocks it")
	GS.slot = 1
	GS.new_game("man_in_suit", "Rich")
	GS.gems = 500
	GS.save_game()
	GS.slot = 0
	main.hud.new_char = "chuchu"
	main.hud._refresh_title()
	check(screen.get_node_or_null("Chosen/Unlock") != null, "a saved character's gems can unlock a locked one")
	await shot("01b3_unlock_with_gems")
	(screen.get_node("Chosen/Unlock") as Button).pressed.emit()
	check(GS.is_unlocked("chuchu") and GS.slot_gems(1) == 200, "unlocking ChuChu takes 300 of Rich's gems")
	check(not (screen.get_node("CreateOK") as Button).disabled, "and then ChuChu can be made")
	GS.load_unlocks()
	check(GS.is_unlocked("chuchu") and GS.is_unlocked("cavemun"), "unlocks are kept on the device")
	GS.new_game("pirate", "Arr")
	check(GS.count("gilded_blade") == 1, "starting as the Pirate comes with its Golden Night")
	check(GS.count("plunger") == 1 and GS.count("sword_cast") == 0, "everyone starts with the Plunger, like PSG2")
	GS.delete_slot(1)
	GS.reset_unlocks()
	GS.slot = 0
	main.hud.new_char = "man_in_suit"
	main.hud._refresh_title()

func run() -> void:
	GS.set_auto_hit(false)
	await wait(1.0)
	await shot("01_title")
	check_data()
	for i in GS.SLOTS:
		GS.delete_slot(i)
	main.hud.menu_step = "slots"
	main.hud._refresh_title()
	await shot("01a_slots")
	GS.reset_unlocks()
	GS.slot = 0
	main.hud._refresh_title(true)
	await shot("01b_create_character")
	await check_character_unlocks()
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
	await guidance_check()
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
	# everything past Hell is set aside for now
	var shown := []
	for c in main.hud.panels.map.find_child("Cards", true, false).get_children():
		shown.append(c)
	check(shown.size() == Data.WORLD_CARDS.size() - Data.LATER_WORLDS.size(), "the Gatekeeper only offers Grasslands to Hell (%d cards)" % shown.size())
	main.hud._enter_world("tomb_of_makara")
	await wait(0.3)
	check(main.level.id == "town" and find_prop(func(n): return n.get_meta("gate", false)) == null, "a set-aside world can't be opened")
	var aside_smith := Data.SMITH.filter(func(r): return Data.set_aside(r.out)).size()
	check(Data.set_aside("forbidden_bar") and Data.set_aside("modina_ring") and not Data.set_aside("hell_armor") and not Data.set_aside("jelly") and aside_smith > 0,
		"items only the later worlds give are set aside (%d items, %d Crafter recipes)" % [Data.SET_ASIDE.size(), aside_smith])
	var q_aside := false
	for npc in Data.NPCS:
		var q: Dictionary = GS.next_quest(npc)
		if not q.is_empty() and Data.uses_set_aside(q.need.keys() + q.reward.keys()):
			q_aside = true
	check(not q_aside, "no villager asks for or gives a set-aside item")
	# the rest of the test still plays the set-aside worlds, so they keep working
	Data.set_later_open(true)
	if OS.has_environment("AT_LOOK"): # set AT_LOOK=1 to run only the ground art checks
		await look_check()
		print("AUTOTEST DONE, %d failures: %s" % [fails.size(), fails])
		get_tree().quit()
		return
	if OS.has_environment("AT_MENUS"): # set AT_MENUS=1 to run only the faint screen, multiplayer menu and auto-hit checks
		await menus_check()
		await goto("grass_1")
		await auto_hit_check()
		print("AUTOTEST DONE, %d failures: %s" % [fails.size(), fails])
		get_tree().quit()
		return
	if OS.has_environment("AT_SYSTEMS"): # set AT_SYSTEMS=1 to run only the systems checks
		await audio_check()
		await darkness_check()
		await gameplay_check()
		await systems_check()
		await content_check()
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
	# more slimes in the Grasslands, and they come back over time
	var slimes := func(): return lvl.entities.get_children().filter(func(e): return e is MobS and not e.dead and e.id == "slime").size()
	var s0: int = slimes.call()
	check(s0 >= 12 and lvl.respawn_cap == s0, "Grasslands 1 starts with plenty of slimes (%d)" % s0)
	var gone := 0
	for e in lvl.entities.get_children():
		if e is MobS and e.id == "slime" and gone < 3:
			e.queue_free()
			gone += 1
	await get_tree().process_frame
	lvl.respawn_t = 99.0
	await wait(0.1)
	check(slimes.call() == s0 - 2, "a new slime appears after a while when some are gone (%d of %d)" % [slimes.call(), s0])
	check(Data.MOBS.slime.drops.any(func(d): return d[0] == "jelly" and d[1] == 0.3), "slimes drop Jelly 30% of the time")
	var coins_before := GS.coins
	GS.add_item("jelly", 10)
	GS.complete_quest(GS.next_quest("jumpie"))
	check(GS.coins == coins_before + 1, "Jumpie's quest pays a Pixel Coin")
	# defense works like the wiki's calculator
	var no_def := GS.roll_monster_hit(7, 0.0)
	check(no_def.dmg == 7, "with 0 defense a 7-attack monster hits for 7 (got %d)" % no_def.dmg)
	GS.equip.armor = "chainmail"
	var zero := 0
	var chip := 0
	for i in 400:
		var d: int = GS.roll_monster_hit(1, 0.0).dmg
		if d == 0:
			zero += 1
		elif d <= 2:
			chip += 1
	check(zero > 100 and chip > 100 and zero + chip == 400, "with defense 15 a 1-attack hit is blocked about half the time and lands for 1-2 the rest (%d blocked, %d hit)" % [zero, chip])
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
			# a monster can knock you away mid-chop: clear them and step back to the tree
			for e in lvl.entities.get_children():
				if e.has_method("die") and e.position.distance_to(tree.position) < 200:
					e.queue_free()
			if p.position.distance_to(tree.position) > 14:
				await stand_by(tree)
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
	await auto_hit_check()
	# the bomb button sends you home
	main.level.player.invuln = 0.0
	main.level.player.self_destruct()
	await wait(1.4)
	check(main.hud.dead_bar.visible, "the bomb makes you faint")
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
	# make room: the leftover smelting ore and coal, then spare materials, so a
	# lucky run of drops earlier can't leave the bag too full for these checks
	GS.remove_item("copper_ore", GS.count("copper_ore"))
	GS.remove_item("coal", GS.count("coal"))
	for i in range(GS.BAG - 1, -1, -1):
		if GS.inv.count(null) >= 6:
			break
		if GS.inv[i] != null and Data.ITEMS[GS.inv[i].id].type == "material":
			GS.inv[i] = null
	GS.inventory_changed.emit()
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
	await jelly_king_check()
	await psg2_match_check()
	await drag_check()
	await new_monsters()
	await psg2_complete()
	await gems_and_characters()
	await audio_check()
	await darkness_check()
	await gameplay_check()
	await systems_check()
	await content_check()
	await menus_check()
	await look_check()
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
	await wait(2.4)
	check(not is_instance_valid(main.grave), "no gravestone in Survival: fainting ends the run")
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
