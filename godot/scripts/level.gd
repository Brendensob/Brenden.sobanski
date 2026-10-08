extends Node2D
## One map. The ground is a tile grid (1 = solid). Builds Pixel Village,
## exploration worlds with caves, arenas and the Survival Grasslands corridor.

const T := 16
const PlayerScript := preload("res://scripts/player.gd")
const MobScript := preload("res://scripts/mob.gd")
const NodeScript := preload("res://scripts/res_node.gd")
const PickupScript := preload("res://scripts/pickup.gd")
const NpcScript := preload("res://scripts/npc.gd")
const PortalScript := preload("res://scripts/portal.gd")
const PlacedScript := preload("res://scripts/placed.gd")
const StationScript := preload("res://scripts/station.gd")
const FxScript := preload("res://scripts/fx.gd")
const PetScript := preload("res://scripts/pet.gd")

var id := ""
var def: Dictionary
var kind := ""
var th: Dictionary
var W := 0
var H := 0
var grid := PackedByteArray()
var surface := PackedInt32Array() # first solid row of each column at the surface
var main: Node
var player: CharacterBody2D
var pet: Node2D
var entities: Node2D
var props: Node2D
var modulate_node: CanvasModulate
var parallax_items: Array = []
var spawn_cell := Vector2i(4, 10)
var rng := RandomNumberGenerator.new()

# arena
var arena_time := 0.0
var bosses_spawned := false
var arena_done := false
var spawn_timer := 1.0
# survival
var s_day := 1
var s_night := false
var s_boss_day := 0
var regrow_timer := 20.0

func setup(world_id: String, main_node: Node) -> void:
	id = world_id
	def = Data.WORLDS[id]
	kind = def.kind
	main = main_node
	th = Art.theme(def.theme)
	rng.seed = randi()
	match kind:
		"town": _gen_town()
		"explore": _gen_explore()
		"arena": _gen_arena()
		"survival": _gen_survival()
	_build_collision()
	_make_background()
	props = Node2D.new()
	add_child(props)
	entities = Node2D.new()
	add_child(entities)
	modulate_node = CanvasModulate.new()
	add_child(modulate_node)
	match kind:
		"town": _populate_town()
		"explore": _populate_explore()
		"arena": _populate_arena()
		"survival": _populate_survival()
	player = PlayerScript.new()
	player.level = self
	entities.add_child(player)
	player.position = cell_pos(spawn_cell)
	if GS.equip.pet != "":
		spawn_pet()
	queue_redraw()

func spawn_pet() -> void:
	if pet:
		pet.queue_free()
		pet = null
	if GS.equip.pet == "":
		return
	pet = PetScript.new()
	pet.setup(GS.equip.pet, self)
	pet.position = player.position + Vector2(-14, -10)
	entities.add_child(pet)

# ---------------------------------------------------------------- grid helpers
func idx(x: int, y: int) -> int:
	return y * W + x

func solid(x: int, y: int) -> bool:
	if x < 0 or x >= W or y >= H:
		return true
	if y < 0:
		return false
	return grid[idx(x, y)] == 1

func set_cell(x: int, y: int, v: int) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		grid[idx(x, y)] = v

func carve(x: int, y: int, w: int, h: int) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if xx > 0 and xx < W - 1 and yy > 0 and yy < H - 2:
				set_cell(xx, yy, 0)

func fill(x: int, y: int, w: int, h: int) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			set_cell(xx, yy, 1)

func cell_pos(c: Vector2i) -> Vector2:
	return Vector2(c.x * T + T / 2.0, c.y * T + T)

func floor_y(x: float, from_y: float) -> float:
	var cx := clampi(int(x / T), 0, W - 1)
	var cy := maxi(0, int(from_y / T))
	while cy < H and not solid(cx, cy):
		cy += 1
	return cy * T

func is_floor(x: int, y: int, clearance: int = 2) -> bool:
	if not solid(x, y + 1):
		return false
	for k in clearance:
		if solid(x, y - k):
			return false
	return true

func floor_cells(min_x: int = 2, max_x: int = -1) -> Array:
	if max_x < 0:
		max_x = W - 3
	var out := []
	for y in range(2, H - 1):
		for x in range(min_x, max_x + 1):
			if is_floor(x, y):
				out.append(Vector2i(x, y))
	return out

func world_size() -> Vector2:
	return Vector2(W * T, H * T)

# ---------------------------------------------------------------- generators
func _init_grid(w: int, h: int) -> void:
	W = w
	H = h
	grid = PackedByteArray()
	grid.resize(W * H)
	grid.fill(0)
	surface.resize(W)

func _surface_walk(base: int, lo: int, hi: int, flat_start: int, flat_end: int) -> void:
	var h := base
	var run := 0
	for x in W:
		if x > flat_start and x < W - flat_end:
			run -= 1
			if run <= 0:
				run = rng.randi_range(4, 10)
				h = clampi(h + rng.randi_range(-1, 1), lo, hi)
		surface[x] = h
		for y in range(h, H):
			set_cell(x, y, 1)

func _gen_explore() -> void:
	_init_grid(170, 54)
	_surface_walk(16, 13, 19, 8, 8)
	# tunnels at three depths, wandering left to right
	var layers := [27, 37, 47]
	for ly in layers:
		var y: int = ly
		var x := rng.randi_range(4, 12)
		var end_x := W - rng.randi_range(5, 12)
		while x < end_x:
			var hgt := rng.randi_range(3, 4)
			carve(x, y - hgt + 1, 4, hgt)
			x += 3
			if rng.randf() < 0.3:
				y = clampi(y + rng.randi_range(-1, 1), ly - 3, ly + 2)
	# pits from the surface into the first tunnel, and shafts between tunnels
	var shafts := []
	for i in 5:
		shafts.append([rng.randi_range(12, W - 14), -1, layers[0]])
	for li in range(layers.size() - 1):
		for i in 3:
			shafts.append([rng.randi_range(8, W - 10), layers[li] - 3, layers[li + 1]])
	for s in shafts:
		var sx: int = s[0]
		var top: int = surface[sx] if s[1] < 0 else s[1]
		var bottom: int = s[2]
		carve(sx, top, 4, bottom - top + 1)
		# climbing ledges every two rows, alternating sides
		var side := 0
		for ly in range(bottom - 2, top + 1, -2):
			fill(sx + (0 if side == 0 else 2), ly, 2, 1)
			side = 1 - side
	for x in W:
		fill(x, H - 2, 1, 2)
	for y in H:
		set_cell(0, y, 1)
		set_cell(W - 1, y, 1)
	spawn_cell = Vector2i(5, surface[5] - 1)

func _gen_arena() -> void:
	_init_grid(64, 22)
	for x in W:
		surface[x] = 18
		fill(x, 18, 1, 4)
	fill(0, 0, 1, 22)
	fill(W - 1, 0, 1, 22)
	for p in [[10, 14, 8], [46, 14, 8], [27, 10, 10]]:
		fill(p[0], p[1], p[2], 1)
	spawn_cell = Vector2i(W / 2, 17)

func _gen_survival() -> void:
	_init_grid(300, 22)
	_surface_walk(17, 16, 18, 4, 4)
	for x in W:
		if absi(x - W / 2) < 12:
			surface[x] = 17
		for y in H:
			set_cell(x, y, 1 if y >= surface[x] else 0)
	fill(0, 0, 1, H)
	fill(W - 1, 0, 1, H)
	spawn_cell = Vector2i(W / 2, 16)

func _gen_town() -> void:
	_init_grid(112, 24)
	for x in W:
		var top := 17
		if x >= 78:
			top = 13
		elif x >= 74:
			top = 17 - (x - 73)
		surface[x] = top
		fill(x, top, 1, H - top)
	fill(0, 0, 1, H)
	fill(W - 1, 0, 1, H)
	spawn_cell = Vector2i(44, 16)

# ---------------------------------------------------------------- collision and drawing
func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var active := {} # "x0,x1" -> first row
	for y in H + 1:
		var runs := {}
		if y < H:
			var x := 0
			while x < W:
				if solid(x, y):
					var x0 := x
					while x < W and solid(x, y):
						x += 1
					runs["%d,%d" % [x0, x]] = true
				else:
					x += 1
		for key in active.keys():
			if not runs.has(key):
				var parts: PackedStringArray = key.split(",")
				var x0 := int(parts[0])
				var x1 := int(parts[1])
				var y0: int = active[key]
				var shape := CollisionShape2D.new()
				var r := RectangleShape2D.new()
				r.size = Vector2((x1 - x0) * T, (y - y0) * T)
				shape.shape = r
				shape.position = Vector2(x0 * T, y0 * T) + r.size / 2
				body.add_child(shape)
				active.erase(key)
		for key in runs:
			if not active.has(key):
				active[key] = y

func _draw() -> void:
	var tiles := Art.ground_tiles(th)
	for y in H:
		for x in W:
			var p := Vector2(x * T, y * T)
			if solid(x, y):
				var open_above := y > 0 and not solid(x, y - 1)
				if open_above and kind == "explore" and y > surface[x]:
					draw_texture(tiles[3], p)
				else:
					draw_texture(tiles[0] if open_above else tiles[1], p)
			elif kind == "explore" and y > surface[x]:
				draw_texture(tiles[2], p)

func _make_background() -> void:
	var bg := ParallaxBackground.new()
	add_child(bg)
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -110
	add_child(sky_layer)
	var sky := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, th.sky[0])
	g.set_color(1, th.sky[1])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(0, 1)
	gt.width = 8
	gt.height = 64
	sky.texture = gt
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_layer.add_child(sky)
	parallax_items.append(sky)
	var base_y := surface[0] * T
	for spec in [[Art.mountains_tex(th), 0.15, 150, 20], [Art.hills_tex(th), 0.4, 90, 24]]:
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(spec[1], 1.0)
		layer.motion_mirroring = Vector2(512, 0)
		var spr := Sprite2D.new()
		spr.texture = spec[0]
		spr.centered = false
		spr.position = Vector2(0, base_y + spec[3] - spec[2])
		layer.add_child(spr)
		bg.add_child(layer)
		parallax_items.append(layer)

# ---------------------------------------------------------------- populating
func add_node(kind_id: String, c: Vector2i) -> Node:
	var n := NodeScript.new()
	n.setup(kind_id, self)
	n.position = cell_pos(c)
	props.add_child(n)
	return n

func add_portal(c: Vector2i, target: String, label: String, color := Color("4fb6d0")) -> Node:
	var p := PortalScript.new()
	p.setup(target, label, self, color)
	p.position = cell_pos(c)
	props.add_child(p)
	return p

func add_station(kind_id: String, index: int, c: Vector2i) -> Node:
	var s := StationScript.new()
	s.setup(kind_id, index, self)
	s.position = cell_pos(c)
	props.add_child(s)
	return s

func add_npc(npc_id: String, c: Vector2i) -> void:
	var n := NpcScript.new()
	n.setup(npc_id, self)
	n.position = cell_pos(c)
	props.add_child(n)

func _weighted(list: Array) -> Array:
	var total := 0.0
	for e in list:
		total += float(e[1])
	var r := rng.randf() * total
	for e in list:
		r -= float(e[1])
		if r <= 0:
			return e
	return list[0]

func _populate_explore() -> void:
	add_portal(Vector2i(2, surface[2] - 1), "town", "Village", Color("5cbf3f"))
	var cells := floor_cells(10)
	cells.shuffle()
	var used := {}
	var deep := []
	for c in cells:
		if c.y > 40 and c.x > W * 0.55:
			deep.append(c)
	deep.shuffle()
	if def.has("next") and deep.size() > 0:
		var pc: Vector2i = deep.pop_back()
		add_portal(pc, def.next, Data.WORLDS[def.next].name, Color("a77ee0"))
		used[pc] = true
	if def.get("chest", false) and deep.size() > 0:
		var cc: Vector2i = deep.pop_back()
		add_station("reward_chest", 0, cc)
		used[cc] = true
	# resources
	var n_nodes := int(W * 0.55)
	for c in cells:
		if n_nodes <= 0:
			break
		if used.has(c) or used.has(c + Vector2i(1, 0)) or used.has(c - Vector2i(1, 0)):
			continue
		var pick: Array = _weighted(def.nodes)
		add_node(pick[0], c)
		used[c] = true
		n_nodes -= 1
	# monsters are placed in advance, like the original
	var mult: float = def.get("mult", 1.0)
	var placed := 0
	cells.shuffle()
	for c in cells:
		if placed >= int(def.count):
			break
		if absi(c.x - spawn_cell.x) < 14 and absi(c.y - spawn_cell.y) < 6:
			continue
		var m: Array = _weighted(def.mobs)
		var hpm: float = (float(m[2]) if m.size() > 2 else 1.0) * mult
		var dmm: float = (float(m[3]) if m.size() > 3 else 1.0) * mult
		spawn_mob_at(m[0], cell_pos(c), hpm, dmm)
		placed += 1

func _populate_arena() -> void:
	add_portal(Vector2i(3, 17), "town", "Leave", Color("5cbf3f"))
	arena_time = 0.0

func _populate_survival() -> void:
	add_portal(Vector2i(W / 2 - 6, 16), "town", "Leave", Color("5cbf3f"))
	s_day = 1
	GS.clock = 0.3
	for i in 70:
		_survival_resource()

func _survival_resource() -> void:
	for tries in 10:
		var x := rng.randi_range(8, W - 9)
		if absi(x - W / 2) < 8:
			continue
		var c := Vector2i(x, surface[x] - 1)
		var busy := false
		for n in props.get_children():
			if absf(n.position.x - cell_pos(c).x) < 20:
				busy = true
				break
		if busy:
			continue
		var pick: Array = _weighted([["tree", 6], ["stone", 4], ["copper", 3], ["iron", 1], ["plant_yellow", 2], ["plant_pink", 2], ["pot", 1]])
		add_node(pick[0], c)
		return

func _populate_town() -> void:
	var y := 16
	var houses := [[18, "e8dccb", "d8433a", 60], [38, "c8d6e8", "3b5dc9", 52], [52, "e8d8b0", "4f9a44", 52], [62, "d8c8e8", "7b4fb8", 60]]
	for h in houses:
		var s := Sprite2D.new()
		s.texture = Art.house_tex(Color(h[1]), Color(h[2]), h[3])
		s.centered = false
		s.position = Vector2(h[0] * T - h[3] / 2, (y + 1) * T - 47)
		props.add_child(s)
	# west: soils for magic seeds, behind a rock wall that needs a gold pickaxe
	for i in 5:
		add_station("soil", i, Vector2i(2 + i * 2, y))
	if not GS.flags.get("rock_wall", false):
		var rw: Node = add_node("rock_wall", Vector2i(13, y))
		rw.make_solid()
	add_npc("gruff", Vector2i(16, y))
	add_station("chest_silver", 0, Vector2i(21, y))
	add_station("chest_golden", 0, Vector2i(24, y))
	add_station("chest_master", 0, Vector2i(27, y))
	add_station("incubator", 0, Vector2i(31, y))
	add_station("sign", 0, Vector2i(36, y))
	add_npc("keeper", Vector2i(40, y))
	add_npc("mira", Vector2i(48, y))
	add_npc("merchant", Vector2i(54, y))
	add_npc("tools", Vector2i(58, y))
	add_npc("smith", Vector2i(63, y))
	add_npc("miner", Vector2i(68, y))
	# east: furnaces up on the hill behind a gate
	add_npc("warden", Vector2i(79, 12))
	if not GS.flags.get("furnaces", false):
		add_station("gate", 0, Vector2i(82, 12))
	for i in Data.FURNACES:
		add_station("furnace", i, Vector2i(86 + i * 4, 12))

# ---------------------------------------------------------------- monsters
func count_mobs(include_boss: bool = true) -> int:
	var n := 0
	for e in entities.get_children():
		if e is MobScript and not e.dead and (include_boss or not e.is_boss()):
			n += 1
	return n

func spawn_mob_at(mob_id: String, pos: Vector2, hp_mul: float = 1.0, dmg_mul: float = 1.0) -> Node:
	var m := MobScript.new()
	m.setup(mob_id, self, hp_mul, dmg_mul)
	m.position = pos + (Vector2(0, -30) if Data.MOBS[mob_id].ai == "fly" else Vector2(0, -1))
	entities.add_child(m)
	return m

func mobs_in_rect(r: Rect2) -> Array:
	var out := []
	for e in entities.get_children():
		if e is MobScript and not e.dead and e.hit_rect().intersects(r):
			out.append(e)
	return out

func nearest_mob(pos: Vector2, radius: float) -> Node:
	var best: Node = null
	var bd := radius
	for e in entities.get_children():
		if e is MobScript and not e.dead and not e.def.get("invulnerable", false):
			var d: float = e.position.distance_to(pos)
			if d < bd:
				bd = d
				best = e
	return best

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

func interactable_near(pos: Vector2, facing: int) -> Node:
	var best: Node = null
	var bd := 18.0
	for n in props.get_children():
		if n is PlacedScript and n.item != "work_station":
			continue
		if n.has_method("interact") and absf(n.position.y - pos.y) < 20:
			var dx: float = n.position.x - pos.x
			var d := absf(dx)
			if d < bd and (d < 6 or signf(dx) == facing or n is PortalScript):
				bd = d
				best = n
	return best

func structures_near(pos: Vector2, radius: float, kind_id: String) -> bool:
	for n in props.get_children():
		if n is PlacedScript and n.item == kind_id and n.position.distance_to(pos) < radius:
			return true
	return false

# ---------------------------------------------------------------- per frame
func _process(delta: float) -> void:
	var d := GS.darkness()
	var under := 0.0
	if kind == "explore" and player:
		var cx := clampi(int(player.position.x / T), 0, W - 1)
		under = clampf((player.position.y / T - surface[cx]) / 6.0, 0, 0.5)
	var dark := maxf(d * 0.85, under)
	if def.theme == "ghost":
		dark = maxf(dark, 0.45)
	modulate_node.color = Color(1, 1, 1).lerp(Color(0.22, 0.24, 0.42), dark)
	var sky_dark := 0.5 if def.theme == "ghost" else d * 0.85
	for p in parallax_items:
		p.modulate = Color(1, 1, 1).lerp(Color(0.22, 0.24, 0.42), sky_dark)
	match kind:
		"arena": _arena_tick(delta)
		"survival": _survival_tick(delta)

func _arena_tick(delta: float) -> void:
	if arena_done:
		return
	arena_time += delta
	spawn_timer -= delta
	if spawn_timer <= 0 and not bosses_spawned:
		spawn_timer = 2.5
		if count_mobs() < int(def.cap):
			var m: Array = _weighted(def.mobs)
			var x := 3 if rng.randf() < 0.5 else W - 4
			var mob: Node = spawn_mob_at(m[0], cell_pos(Vector2i(x, 17)), float(m[2]) if m.size() > 2 else 1.0, float(m[3]) if m.size() > 3 else 1.0)
			mob.aggro_forced = true
	if not bosses_spawned and arena_time >= Data.ARENA_BOSS_TIME:
		bosses_spawned = true
		var list: Array = def.bosses.duplicate()
		list.shuffle()
		var n: int = def.get("bosses_pick", list.size())
		var first: Node = null
		for i in mini(n, list.size()):
			var b: Array = list[i]
			var m: Node = spawn_mob_at(b[0], cell_pos(Vector2i(W / 2 + (i - n / 2) * 8, 17)), b[1], b[2])
			m.aggro_forced = true
			m.arena_boss = true
			if first == null:
				first = m
		main.hud.toast("The boss has arrived!", "danger")
		main.hud.set_boss(first)
	if bosses_spawned:
		var alive := false
		for e in entities.get_children():
			if e is MobScript and e.arena_boss and not e.dead:
				alive = true
		if not alive:
			arena_done = true
			for d in def.boss_drops:
				if rng.randf() < d[1]:
					drop(d[0], rng.randi_range(d[2], d[3]), player.position + Vector2(0, -20))
			main.hud.toast("Arena cleared!", "good")
			add_portal(Vector2i(W / 2, 17), "town", "Home", Color("5cbf3f"))

func arena_time_left() -> float:
	return maxf(0, Data.ARENA_BOSS_TIME - arena_time)

func _survival_tick(delta: float) -> void:
	var night := GS.is_night()
	if night and not s_night:
		s_night = true
		main.hud.toast("Night %d. Here they come!" % s_day, "danger")
		if s_day % 6 == 0 and s_boss_day != s_day:
			s_boss_day = s_day
			var b: String = Data.SURVIVAL_BOSSES[(s_day / 6 - 1) % Data.SURVIVAL_BOSSES.size()]
			var m: Node = spawn_mob_at(b, cell_pos(Vector2i(W - 6, surface[W - 6] - 1)), _surv_scale() * 0.5, 1.0)
			m.aggro_forced = true
			main.hud.set_boss(m)
	if not night and s_night:
		s_night = false
		var tokens := Data.survival_tokens(s_day)
		if tokens > 0:
			GS.add_item("survival_token", tokens)
		main.hud.toast("You survived night %d! +%d Survival Tokens" % [s_day, tokens], "good")
		s_day += 1
		GS.best_survival_day = maxi(GS.best_survival_day, s_day)
	if night:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_timer = maxf(0.8, 2.5 - s_day * 0.06)
			if count_mobs() < 10 + s_day:
				var pool := []
				for wave in Data.SURVIVAL_WAVES:
					if s_day >= wave[0]:
						pool.append_array(wave[1])
				var mid: String = pool[rng.randi() % pool.size()]
				var x := 3 if rng.randf() < 0.5 else W - 4
				var s := _surv_scale()
				var mob: Node = spawn_mob_at(mid, cell_pos(Vector2i(x, surface[x] - 1)), s, s)
				mob.aggro_forced = true
	else:
		regrow_timer -= delta
		if regrow_timer <= 0:
			regrow_timer = 12.0
			_survival_resource()

func _surv_scale() -> float:
	return 1.0 + (s_day - 1) * 0.08

# ---------------------------------------------------------------- drops, effects, building
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
	var cx := int((pos.x + facing * 20) / T)
	var cy := int((pos.y - 2) / T)
	while cy < H and not solid(cx, cy + 1):
		cy += 1
	if solid(cx, cy) or solid(cx, cy - 1) or cy >= H - 2:
		return false
	var x := cx * T + T / 2.0
	for n in props.get_children():
		if absf(n.position.x - x) < 10 and absf(n.position.y - (cy + 1) * T) < 20:
			return false
	if item in ["wood_wall", "stone_wall", "work_station"] and absf(player.position.x - x) < 13:
		return false
	var p := PlacedScript.new()
	p.setup(item, self)
	p.position = Vector2(x, (cy + 1) * T)
	props.add_child(p)
	return true
