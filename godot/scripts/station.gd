extends Node2D
## Village stations: furnaces, chests, the incubator, seed soils, the furnace
## gate and the notice sign. Reward chests also appear deep inside worlds.

var kind := ""
var index := 0
var level: Node
var sprite: Sprite2D
var label: Label
var body: StaticBody2D
var t := 0.0
var bubble: Sprite2D

func setup(k: String, i: int, lvl: Node) -> void:
	kind = k
	index = i
	level = lvl

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = false
	add_child(sprite)
	label = Label.new()
	label.add_theme_font_override("font", Art.font_body)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_outline_color", Color("1b1a24"))
	label.add_theme_constant_override("outline_size", 2)
	label.size = Vector2(70, 10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	if kind == "gate":
		body = StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(12, 48)
		shape.shape = rect
		shape.position = Vector2(0, -24)
		body.add_child(shape)
		add_child(body)
	bubble = Sprite2D.new()
	bubble.visible = false
	add_child(bubble)
	_refresh()

func _refresh() -> void:
	var tex: Texture2D
	var text := ""
	match kind:
		"furnace":
			var job = GS.furnaces[index]
			var st := ""
			if job != null:
				st = "done" if GS.now() >= job.done else "busy"
			tex = Art.prop_tex("furnace", st)
			# like the original, a bubble with the finished bar pops up when it's done
			bubble.visible = st == "done"
			if st == "done":
				bubble.texture = Art.prop_tex("bubble", job.out)
				bubble.position = Vector2(0, -tex.get_height() - 12)
			text = "" if job == null or st == "done" else _time(job.done - GS.now())
		"furnace_board":
			var job2 = GS.furnaces[index]
			tex = Art.prop_tex("board", job2.main if job2 != null and job2.has("main") else "copper_ore")
		"chest_silver", "chest_golden", "chest_master":
			var c := kind.replace("chest_", "")
			tex = Art.prop_tex("chest", c)
		"reward_chest":
			tex = Art.prop_tex("chest", "reward")
			text = "Reward Chest" if GS.reward_chests.get(level.id, -1) != GS.today() else "Opened today"
		"incubator":
			tex = Art.prop_tex("incubator", "egg" if not GS.incubator.is_empty() else "")
			if GS.incubator.is_empty():
				text = ""
			elif GS.now() >= GS.incubator.done:
				text = "Hatched!"
			else:
				text = _time(GS.incubator.done - GS.now())
		"soil":
			var s = GS.soils[index]
			var state := ""
			if s != null:
				state = "done" if GS.now() >= s.done else "growing"
			tex = Art.prop_tex("soil", state)
			text = "" if s == null else ("Ready!" if state == "done" else _time(s.done - GS.now()))
		"trade_table":
			tex = Art.prop_tex("trade_table")
			text = "Trade"
		"gate":
			tex = Art.prop_tex("gate")
			text = "Locked"
		"sign":
			tex = Art.prop_tex("sign")
			text = "Notice"
	sprite.texture = tex
	var s2: Vector2 = tex.get_size()
	sprite.position = Vector2(-s2.x / 2, -s2.y + 1)
	label.text = text
	label.position = Vector2(-35, -s2.y - 10)

func _time(sec: float) -> String:
	var s := int(maxf(sec, 0))
	if s >= 3600:
		return "%dh %02dm" % [s / 3600, (s % 3600) / 60]
	return "%d:%02d" % [s / 60, s % 60]

func _process(delta: float) -> void:
	t += delta
	if t > 0.5:
		t = 0
		_refresh()

func interact(_player: Node) -> void:
	match kind:
		"furnace_board":
			return
		"trade_table":
			level.main.hud.open_trade_pick()
		"gate":
			level.main.hud.toast("The gate is locked. Talk to the GateKeeper.", "warn")
		"sign":
			level.main.hud.open_info("Pixel Town", "West: Brutus and the rock wall (break it with a gold pickaxe to reach the magic seed soils).\nChests open with keys. The Incubator hatches monster eggs.\nCentre: the Gatekeeper takes you to every world.\nEast: Miffie, the shops, the Crafter and the Miner. Up the hill: the furnaces.")
		_:
			level.main.hud.open_station(self)
