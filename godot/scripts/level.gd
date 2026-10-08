extends Node2D
## One map: Pixel Village, a zone level (1-8) or a boss lair.
## The ground is a row of columns; y = 0 is the bottom of the world and up is negative.

const T := 16
const PlayerScript := preload("res://scripts/player.gd")
const MobScript := preload("res://scripts/mob.gd")
const NodeScript := preload("res://scripts/res_node.gd")
const PickupScript := preload("res://scripts/pickup.gd")
const NpcScript := preload("res://scripts/npc.gd")
const PortalScript := preload("res://scripts/portal.gd")
const PlacedScript := preload("res://scripts/placed.gd")
const FxScript := preload("res://scripts/fx.gd")

var id := ""
var zone: Dictionary
var zone_id := "grass"
var level_num := 0
var is_town := false
var is_lair := false
var heights := PackedInt32Array()
var cols := 0
var main: Node
var player: CharacterBody2D
var spawn_timer := 3.0
var boss_spawned := false
var boss_timer := 2.0
var modulate_node: CanvasModulate
var parallax_items: Array = []
var furnace_pos := Vector2.ZERO

var entities: Node2D
var props: Node2D

func setup(level_id: String, main_node: Node, entry: String) -> void:
	id = level_id
	main = main_node
	is_town = id == "town"
	if is_town:
		zone_id = "grass"
	else:
		var parts := id.split("_")
		zone_id = parts[0]
		is_lair = parts[1] == "lair"
		level_num = 0 if is_lair else int(parts[1])
	zone = Data.ZONES[zone_id]
	_make_terrain()
	_make_background()
	props = Node2D.new()
	add_child(props)
	_draw_ground()
	entities = Node2D.new()
	entities.y_sort_enabled = false
	add_child(entities)
	modulate_node = CanvasModulate.new()
	add_child(modulate_node)

	if is_town:
		_build_town()
	elif is_lair:
		add_portal(3, "town", "Pixel Village")
	else:
		var back := "town" if level_num == 1 else "%s_%d" % [zone_id, level_num - 1]
		add_portal(3, back, "Back")
		var fwd := GS.level_after(id)
		add_portal(cols - 4, fwd, "Next")
		_place_nodes()

	player = PlayerScript.new()
	player.level = self
	entities.add_child(player)
	var px := 6 * T
	if entry == "right" and not is_town and not is_lair:
		px = (cols - 7) * T
	if entry == "portal_town":
		px = (cols - 12) * T
	player.position = Vector2(px, surface_y(px))
	if not is_town and not is_lair:
		var n := 3 + level_num
		for i in n:
			spawn_mob()

func _process(delta: float) -> void:
	var d := GS.darkness()
	var c := Color(1, 1, 1).lerp(Color(0.22, 0.24, 0.42), d * 0.85)
	modulate_node.color = c
	for p in parallax_items:
		p.modulate = c
	if is_town:
		return
	if is_lair:
		if not boss_spawned:
			boss_timer -= delta
			if boss_timer <= 0:
				boss_spawned = true
				var b := spawn_mob_at(zone.boss, (cols - 16) * T)
				main.hud.toast("%s appears!" % Data.MOBS[zone.boss].name, "danger")
				main.hud.set_boss(b)
		return
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = 6.0
		var target := 3 + level_num
		if GS.is_night():
			target = int(target * 1.6) + 1
		if count_mobs() < target:
			spawn_mob()

# ---------------------------------------------------------------- terrain
func _make_terrain() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	if is_town:
		cols = 60
	elif is_lair:
		cols = 42
	else:
		cols = 100 + level_num * 8
	heights.resize(cols)
	var h := 5
	var run := 0
	for x in cols:
		if not is_town and not is_lair and x > 8 and x < cols - 9:
			run -= 1
			if run <= 0:
				run = rng.randi_range(5, 12)
				var step := rng.randi_range(-1, 1)
				h = clampi(h + step, 4, 7)
		heights[x] = h
	# solid ground, one box per run of equal height
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var start := 0
	for x in range(1, cols + 1):
		if x == cols or heights[x] != heights[start]:
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			var top := -heights[start] * T
			rect.size = Vector2((x - start) * T, -top + 64)
			shape.shape = rect
			shape.position = Vector2(start * T + rect.size.x / 2, top + rect.size.y / 2)
			body.add_child(shape)
			start = x
	for side in [-1, 1]:
		var s := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(32, 2000)
		s.shape = r
		s.position = Vector2(-16 if side < 0 else cols * T + 16, -900)
		body.add_child(s)

func surface_y(x: float) -> float:
	var c := clampi(int(x / T), 0, cols - 1)
	return -heights[c] * T

func world_width() -> float:
	return cols * T

func _draw_ground() -> void:
	queue_redraw()

func _draw() -> void:
	var tiles := Art.ground_tiles(zone)
	for x in cols:
		var top := -heights[x] * T
		draw_texture(tiles[0], Vector2(x * T, top))
		var y := top + T
		while y < 32:
			draw_texture(tiles[1], Vector2(x * T, y))
			y += T

func _make_background() -> void:
	var bg := ParallaxBackground.new()
	add_child(bg)
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -110
	add_child(sky_layer)
	var sky := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, zone.sky[0])
	g.set_color(1, zone.sky[1])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 64
	sky.texture = gt
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_layer.add_child(sky)
	parallax_items.append(sky)
	for spec in [[Art.mountains_tex(zone), 0.15, 150, -60], [Art.hills_tex(zone), 0.4, 90, -56]]:
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(spec[1], 1.0)
		layer.motion_mirroring = Vector2(512, 0)
		var spr := Sprite2D.new()
		spr.texture = spec[0]
		spr.centered = false
		spr.position = Vector2(0, spec[3] - spec[2])
		layer.add_child(spr)
		bg.add_child(layer)
		parallax_items.append(layer)

# ---------------------------------------------------------------- contents
func _place_nodes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id) + 11
	var pool: Array = []
	for n in zone.nodes:
		if level_num >= n[1]:
			for i in n[2]:
				pool.append(n[0])
	var x := 10
	while x < cols - 10:
		if rng.randf() < 0.7:
			add_node(pool[rng.randi() % pool.size()], x)
		x += rng.randi_range(3, 6)

func add_node(kind: String, col: int) -> void:
	var n := NodeScript.new()
	n.setup(kind, self)
	n.position = Vector2(col * T + T / 2, surface_y(col * T + T / 2))
	props.add_child(n)

func add_portal(col: int, target: String, label: String) -> void:
	var p := PortalScript.new()
	p.setup(target, label, self)
	p.position = Vector2(col * T + T / 2, surface_y(col * T))
	props.add_child(p)

func _build_town() -> void:
	var houses := [[7, "e8dccb", "d8433a"], [15, "c8d6e8", "3b5dc9"], [23, "e8d8b0", "4f9a44"], [31, "d8c8e8", "7b4fb8"], [39, "e8c8b0", "b85e1c"]]
	for h in houses:
		var s := Sprite2D.new()
		s.texture = Art.house_tex(Color(h[1]), Color(h[2]))
		s.centered = false
		s.position = Vector2(h[0] * T - 6, surface_y(0) - 47)
		props.add_child(s)
	for npc in Data.NPCS:
		var n := NpcScript.new()
		n.setup(npc, self)
		n.position = Vector2(npc.x * T + 8, surface_y(0))
		props.add_child(n)
	# furnace
	var f := Sprite2D.new()
	f.texture = Art.prop_tex("furnace")
	f.centered = false
	furnace_pos = Vector2(47 * T, surface_y(0))
	f.position = furnace_pos + Vector2(-10, -14)
	f.modulate = Color.WHITE if GS.furnace else Color(0.6, 0.6, 0.7)
	f.name = "Furnace"
	props.add_child(f)
	var sign := Label.new()
	sign.text = "Furnace" if GS.furnace else "Furnace (cold)"
	sign.add_theme_font_override("font", Art.font_body)
	sign.add_theme_font_size_override("font_size", 6)
	sign.position = furnace_pos + Vector2(-22, -28)
	sign.size = Vector2(44, 10)
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	props.add_child(sign)
	if GS.furnace:
		var l := PointLight2D.new()
		l.texture = Art.light_tex()
		l.texture_scale = 1.2
		l.color = Color("f2a33a")
		l.position = furnace_pos + Vector2(0, -6)
		props.add_child(l)
	add_portal(54, "map", "World")

func near_furnace(pos: Vector2) -> bool:
	return is_town and GS.furnace and absf(pos.x - furnace_pos.x) < 40

# ---------------------------------------------------------------- monsters
func pick_mob() -> String:
	var options: Array = []
	for m in zone.mobs:
		if level_num >= m[1]:
			options.append(m[0])
	return options[randi() % options.size()]

func count_mobs() -> int:
	var n := 0
	for e in entities.get_children():
		if e is MobScript and not e.dead:
			n += 1
	return n

func spawn_mob() -> void:
	for tries in 20:
		var x := randf_range(10 * T, (cols - 10) * T)
		if player and absf(x - player.position.x) < 170:
			continue
		spawn_mob_at(pick_mob(), x)
		return

func spawn_mob_at(mob_id: String, x: float) -> Node:
	var m := MobScript.new()
	m.setup(mob_id, self)
	var y := surface_y(x) - (40 if m.def.ai == "flyer" else 2)
	m.position = Vector2(x, y)
	entities.add_child(m)
	return m

func mobs_in_rect(r: Rect2) -> Array:
	var out := []
	for e in entities.get_children():
		if e is MobScript and not e.dead and e.hit_rect().intersects(r):
			out.append(e)
	return out

func node_in_rect(r: Rect2) -> Node:
	var best: Node = null
	var bd := 1e9
	for n in props.get_children():
		if n is NodeScript and n.alive and n.hit_rect().intersects(r):
			var d := absf(n.position.x - r.get_center().x)
			if d < bd:
				bd = d
				best = n
	return best

func interactable_near(pos: Vector2) -> Node:
	for n in props.get_children():
		if (n is NpcScript or n is PortalScript) and absf(n.position.x - pos.x) < 14 and absf(n.position.y - pos.y) < 24:
			return n
	if near_furnace(pos):
		return null
	return null

# ---------------------------------------------------------------- drops and effects
func drop(item: String, n: int, pos: Vector2) -> void:
	var p := PickupScript.new()
	p.setup(item, n, self)
	p.position = pos + Vector2(randf_range(-4, 4), -6)
	entities.add_child(p)

func number(pos: Vector2, text: String, color: Color) -> void:
	var f := FxScript.new()
	f.setup_text(text, color)
	f.position = pos
	add_child(f)

func burst(pos: Vector2, color: Color, n: int = 6) -> void:
	var f := FxScript.new()
	f.setup_burst(color, n)
	f.position = pos
	add_child(f)

func place(item: String, pos: Vector2, facing: int) -> bool:
	var col := int((pos.x + facing * 22) / T)
	if col < 6 or col > cols - 7:
		return false
	if absf(heights[col] - heights[clampi(int(pos.x / T), 0, cols - 1)]) > 1:
		return false
	var x := col * T + T / 2.0
	for n in props.get_children():
		if (n is PlacedScript or n is NodeScript or n is PortalScript) and absf(n.position.x - x) < 10:
			return false
	if item != "torch" and absf(player.position.x - x) < 13:
		return false
	var p := PlacedScript.new()
	p.setup(item, self)
	p.position = Vector2(x, surface_y(x))
	props.add_child(p)
	return true
