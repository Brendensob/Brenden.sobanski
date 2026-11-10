extends Node
## Draws a sheet of icons, rocks, worn gear and held weapons for a screenshot.
var out := "user://shots"

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	var page: String = OS.get_environment("GALLERY")
	var cl := CanvasLayer.new()
	cl.layer = 120
	add_child(cl)
	var bg := ColorRect.new()
	bg.color = Color("7ec0e8")
	bg.size = Vector2(480, 270)
	cl.add_child(bg)
	var th := {"name": "grass"}
	var x := 4.0
	var y := 4.0
	if page == "ores":
		for id in ["crystal", "fire_crystal", "water_crystal", "earth_crystal", "dark_crystal", "evil_crystal", "small_evil_crystal", "catalyst", "gem", "ruby_stone", "copper_ore", "iron_ore", "silver_ore", "gold_ore", "erbium", "volcanic_ore", "nightmare_ore", "sandnite_ore"]:
			_tex(bg, Art.icon(id), Vector2(x, y), 3)
			x += 40
			if x > 440:
				x = 4
				y += 40
		x = 4
		y += 50
		for k in ["stone", "copper", "iron", "silver", "gold", "erbium_rock", "ice_rock", "volcanic_rock", "sandnite_rock"]:
			var t: Texture2D = Art.node_tex(k, Art.theme("grass"))
			_tex(bg, t, Vector2(x, y + 24 - t.get_height() * 2), 2)
			x += 50
	elif page == "gear":
		var armors := []
		var helmets := []
		for id in Data.ITEMS:
			var t: String = Data.ITEMS[id].type
			if t == "armor" and armors.size() < 24 and not id.ends_with("_2") and not id.ends_with("_3"):
				armors.append(id)
			elif t == "helmet" and helmets.size() < 24 and not id.ends_with("_2") and not id.ends_with("_3"):
				helmets.append(id)
		for i in armors.size():
			_tex(bg, Art.character("man_in_suit", "stand", 1, "", armors[i]), Vector2(4 + (i % 12) * 39, 4 + (i / 12) * 44), 2)
		for i in helmets.size():
			_tex(bg, Art.character("man_in_suit", "stand", 1, helmets[i], ""), Vector2(4 + (i % 12) * 39, 98 + (i / 12) * 44), 2)
		var ws := ["short_blade", "plunger", "knights_blade", "excalibur", "long_sword", "volcan_axe", "long_lance", "wall_hammer", "glow_blade_blue", "hell_sword"]
		for i in ws.size():
			var s := Sprite2D.new()
			s.texture = Art.held_tex(ws[i])
			s.scale = Art.held_scale(ws[i]) * 2
			s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			s.position = Vector2(24 + i * 46, 240)
			s.rotation = -0.6
			bg.add_child(s)
	elif page == "chars":
		# every character, villager and person-shaped monster
		var looks: Array = Art.LOOKS.keys()
		for i in looks.size():
			_tex(bg, Art.character(looks[i]), Vector2(6 + (i % 15) * 31.5, 4 + (i / 15) * 52), 2)
		# the frames of one character, then worn gear
		var fx := 6.0
		for f in Art.FRAMES:
			_tex(bg, Art.character("man_in_suit", f), Vector2(fx, 162), 2)
			fx += 30
		for f in Art.FRAMES:
			_tex(bg, Art.character("nurse", f, 1, "iron_helmet", "iron_armor"), Vector2(fx, 162), 2)
			fx += 30
		for i in looks.size():
			_tex(bg, Art.character(looks[i]), Vector2(6 + i * 10.7, 244), 1)
	elif page == "mobs":
		var seen := {}
		var mx := 4.0
		var my := 4.0
		var row_h := 0.0
		for id in Data.MOBS:
			var l: String = Data.MOBS[id].look
			if seen.has(l):
				continue
			seen[l] = true
			var t: Texture2D = Art.mob_tex(l, false)
			if t.get_width() > 40:
				continue
			if mx + t.get_width() > 476:
				mx = 4
				my += row_h + 3
				row_h = 0
			_tex(bg, t, Vector2(mx, my), 1)
			mx += t.get_width() + 3
			row_h = maxf(row_h, t.get_height())
	elif page == "props":
		var px := 4.0
		for k in ["tree", "rock", "bush", "stone", "copper", "iron", "gold"]:
			var t: Texture2D = Art.node_tex(k, Art.theme("grass"))
			_tex(bg, t, Vector2(px, 100 - t.get_height() * 2), 2)
			px += t.get_width() * 2 + 6
		px = 4.0
		for id in ["wood", "rock", "jelly", "apple", "short_blade", "wood_helmet", "iron_armor", "health_potion", "torch", "gem", "pet_trex", "pirate", "combo_book", "key", "copper_bar", "iron_ore"]:
			if Data.ITEMS.has(id):
				_tex(bg, Art.icon(id), Vector2(px, 120), 2)
				px += 28
		px = 4.0
		for k in ["chest", "campfire", "furnace", "sign", "table"]:
			var t2: Texture2D = Art.prop_tex(k)
			if t2:
				_tex(bg, t2, Vector2(px, 160), 2)
				px += t2.get_width() * 2 + 6
	elif page == "char_big":
		var pick := ["man_in_suit", "nurse", "cavemun", "pirate", "the_spi", "soldier", "ninja", "iron_bot", "q_bun"]
		for i in pick.size():
			_tex(bg, Art.character(pick[i]), Vector2(6 + i * 52, 6), 3)
			_tex(bg, Art.character(pick[i], "walk"), Vector2(6 + i * 52, 90), 3)
			_tex(bg, Art.character(pick[i], "jump", 1, "gold_helmet", "gold_armor"), Vector2(6 + i * 52, 174), 3)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/gallery_%s.png" % [out, page])
	get_tree().quit()

func _tex(parent: Control, t: Texture2D, at: Vector2, k: float) -> void:
	var r := TextureRect.new()
	r.texture = t
	r.position = at
	r.size = t.get_size() * k
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(r)
