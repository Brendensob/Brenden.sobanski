extends Node2D
## One map. The ground is a tile grid (1 = solid, 2 = ledge, 3 = a wall that kills
## on touch). Builds Pixel Town, exploration worlds with caves, the Tomb of
## Makara's maze, arenas and the Survival Grasslands corridor.

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
const EmoteScript := preload("res://scripts/emote.gd")
const PetScript := preload("res://scripts/pet.gd")
const PuppetScript := preload("res://scripts/remote_player.gd")
const ProjectileScript := preload("res://scripts/projectile.gd")

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
var home_cell := Vector2i(-1, -1) # where the portal back to town stands
var rng := RandomNumberGenerator.new()
var seed_used := 0
# multiplayer: every shared thing gets a number so all games agree on it
var netted := false # true when this map is shared with a room (everywhere but town)
var live := false # set once the map is built; after that, new things are announced
var net_objs := {} # nid -> node
var next_nid := 1
var puppets := {} # peer id -> remote player

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

## seed and net_state come from the room host when you're a guest in a room.
func setup(world_id: String, main_node: Node, seed: int = -1, net_state: Dictionary = {}) -> void:
	id = world_id
	def = Data.WORLDS[id]
	kind = def.kind
	main = main_node
	th = Art.theme(def.theme)
	netted = Net.active and kind != "town"
	rng.seed = seed if seed >= 0 else randi()
	seed_used = rng.seed
	match kind:
		"town": _gen_town()
		"explore": _gen_maze() if def.get("maze", false) else _gen_explore()
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
	if netted and Net.is_client():
		_apply_net_state(net_state)
	else:
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
	for peer in Net.players:
		var st: Dictionary = Net.players[peer].get("state", {})
		if not st.is_empty():
			update_puppet(peer, Net.players[peer].name, st)
	live = true
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
	return grid[idx(x, y)] != 0

## True when a solid or deadly wall stands between two points (thin ledges don't
## count), so swings can't reach monsters on the other side of a wall.
func wall_between(a: Vector2, b: Vector2) -> bool:
	var steps := maxi(1, int(a.distance_to(b) / 4.0))
	for i in range(1, steps):
		var p := a.lerp(b, float(i) / steps)
		var x := int(floor(p.x / T))
		var y := int(floor(p.y / T))
		if x >= 0 and y >= 0 and x < W and y < H and grid[idx(x, y)] in [1, 3]:
			return true
	return false

## A thin ledge: you stand on it, but jump up through it from below.
func is_ledge(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H and grid[idx(x, y)] == 2

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

func ledge(x: int, y: int, w: int) -> void:
	for xx in range(x, x + w):
		set_cell(xx, y, 2)

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

## True when the rectangle (in pixels) overlaps a wall that kills on touch.
func touches_deadly(r: Rect2) -> bool:
	for y in range(maxi(0, int(r.position.y / T)), mini(H, int(r.end.y / T) + 1)):
		for x in range(maxi(0, int(r.position.x / T)), mini(W, int(r.end.x / T) + 1)):
			if grid[idx(x, y)] == 3 and r.intersects(Rect2(x * T, y * T, T, T)):
				return true
	return false

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
			ledge(sx + (0 if side == 0 else 2), ly, 2)
			side = 1 - side
	for x in W:
		fill(x, H - 2, 1, 2)
	for y in H:
		set_cell(0, y, 1)
		set_cell(W - 1, y, 1)
	spawn_cell = Vector2i(5, surface[5] - 1)

## The Tomb of Makara: an enclosed maze of sandy rooms under the ground, four rows of
## them joined by corridors and climbing shafts. Some of the walls left standing
## between rooms are deadly.
func _gen_maze() -> void:
	_init_grid(150, 54)
	fill(0, 0, W, H)
	for x in W:
		surface[x] = 0
	var cw := 11
	var ch := 11
	var cols := (W - 4) / cw
	var rows := 4
	var ox := 2
	var oy := 2
	var floor_of := func(r: int) -> int: return oy + r * ch + ch - 1
	for r in rows:
		for c in cols:
			carve(ox + c * cw, floor_of.call(r) - 4, cw - 2, 4)
	# a random spanning tree over the rooms, plus a few extra openings
	var open := {}
	var seen := {Vector2i(0, 0): true}
	var stack := [Vector2i(0, 0)]
	while not stack.is_empty():
		var cur: Vector2i = stack[-1]
		var next := []
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = cur + d
			if n.x >= 0 and n.y >= 0 and n.x < cols and n.y < rows and not seen.has(n):
				next.append(n)
		if next.is_empty():
			stack.pop_back()
			continue
		var n: Vector2i = next[rng.randi() % next.size()]
		seen[n] = true
		open[_pair(cur, n)] = true
		stack.append(n)
	for r in rows:
		for c in cols - 1:
			if rng.randf() < 0.2:
				open[_pair(Vector2i(c, r), Vector2i(c + 1, r))] = true
	for r in rows:
		for c in cols:
			var a := Vector2i(c, r)
			var right := Vector2i(c + 1, r)
			var down := Vector2i(c, r + 1)
			var wx := ox + c * cw + cw - 2
			if c < cols - 1:
				if open.has(_pair(a, right)):
					carve(wx, floor_of.call(r) - 4, 2, 4)
				elif c > 1 and rng.randf() < 0.35:
					# a wall that kills on touch
					for y in range(floor_of.call(r) - 4, floor_of.call(r)):
						for x in range(wx, wx + 2):
							set_cell(x, y, 3)
			if r < rows - 1 and open.has(_pair(a, down)):
				var sx := ox + c * cw + 2 + rng.randi_range(0, cw - 8)
				var top: int = floor_of.call(r) - 4
				var bottom: int = floor_of.call(r + 1) - 1
				carve(sx, top, 4, bottom - top + 1)
				var side := 0
				for ly in range(bottom - 2, top + 1, -2):
					ledge(sx + (0 if side == 0 else 2), ly, 2)
					side = 1 - side
	spawn_cell = Vector2i(ox + 3, floor_of.call(0) - 1)
	home_cell = Vector2i(ox, floor_of.call(0) - 1)

static func _pair(a: Vector2i, b: Vector2i) -> String:
	return "%s%s" % [a, b] if a < b else "%s%s" % [b, a]

func _gen_arena() -> void:
	_init_grid(64, 22)
	for x in W:
		surface[x] = 18
		fill(x, 18, 1, 4)
	fill(0, 0, 1, 22)
	fill(W - 1, 0, 1, 22)
	for p in [[10, 14, 8], [46, 14, 8], [27, 10, 10]]:
		ledge(p[0], p[1], p[2])
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

## Pixel Town is small and closed in on all sides, with three floors like the
## original, the two sides mirroring each other:
## - up top: the Trading Center (behind a wooden wall you burn) on the left, then
##   the incubator and chests, and the furnace room (behind the GateKeeper's gate)
##   on the right;
## - the street in the middle, where the Gatekeeper's portals open. The opening
##   in the middle of the upper floor is the way up: jump;
## - the basement under everything, where the ninjas and robots live. You get
##   down through a hole at the east end, behind the stone wall.
const TOWN_CEIL := 3
const TOWN_TOP := 12
const TOWN_MID := 18
const TOWN_BASE := 24
const TOWN_W := 64
const TOWN_ROOM := 16 # the side rooms' walls stand this far from each edge
const TOWN_OPENING := [30, 34] # the gap in the upper floor, from x to x (exclusive), in the middle
const TOWN_PORTAL := Vector2i(31, TOWN_MID - 1)
const TOWN_HOLE := 57 # the hole down to the basement (2 wide)

func _gen_town() -> void:
	_init_grid(TOWN_W, TOWN_BASE + 4)
	for x in W:
		surface[x] = TOWN_MID
	fill(0, TOWN_MID, W, H - TOWN_MID)
	# closed in: a roof over the whole town
	fill(0, 0, W, TOWN_CEIL)
	# the basement, all the way across
	carve(1, TOWN_MID + 1, W - 2, TOWN_BASE - TOWN_MID - 1)
	# the upper floor, with one opening in the middle to jump up through
	fill(1, TOWN_TOP, W - 2, 1)
	carve(TOWN_OPENING[0], TOWN_TOP, TOWN_OPENING[1] - TOWN_OPENING[0], 1)
	# the side rooms, walled up to the roof, each with a door at the bottom
	fill(TOWN_ROOM, TOWN_CEIL, 1, TOWN_TOP - TOWN_CEIL - 3)
	fill(W - 1 - TOWN_ROOM, TOWN_CEIL, 1, TOWN_TOP - TOWN_CEIL - 3)
	# the magic soils in a cave behind the rock wall (west), and the furnace hill
	# with a low tunnel under it to the hole (east)
	fill(1, TOWN_TOP + 1, 11, 2)
	fill(W - 12, TOWN_TOP, 11, 3)
	# the hole down to the basement, with ledges to climb back out
	carve(TOWN_HOLE, TOWN_MID, 2, 1)
	ledge(TOWN_HOLE - 1, TOWN_MID, 1) # the hole's edges are thin, so from the top ledge
	ledge(TOWN_HOLE + 2, TOWN_MID, 1) # you jump up through them onto the street
	for r in [TOWN_BASE - 4, TOWN_BASE - 2]:
		ledge(TOWN_HOLE + 1, r, 1)
	fill(0, 0, 1, H)
	fill(W - 1, 0, 1, H)
	spawn_cell = Vector2i(20, TOWN_MID - 1)

## A little picture of a world's layout for the Gatekeeper's cards: builds the
## map with a fixed seed (no monsters or props) and paints one pixel per tile.
func preview_image(world_id: String) -> Image:
	id = world_id
	def = Data.WORLDS[id]
	kind = def.kind
	th = Art.theme(def.theme)
	rng.seed = 7
	match kind:
		"town": _gen_town()
		"explore": _gen_maze() if def.get("maze", false) else _gen_explore()
		"arena": _gen_arena()
		"survival": _gen_survival()
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var v: int = grid[idx(x, y)]
			var c: Color
			if v == 0:
				c = th.cave if y > surface[x] and kind == "explore" else th.sky[0].lerp(th.sky[1], float(y) / H)
			elif v == 3:
				c = Color("d8433a")
			elif y > 0 and not solid(x, y - 1) or v == 2:
				c = th.top
			else:
				c = th.dirt2 if (x + y) % 3 == 0 else th.dirt
			img.set_pixel(x, y, c)
	return img

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
				if solid(x, y) and not is_ledge(x, y):
					var x0 := x
					while x < W and solid(x, y) and not is_ledge(x, y):
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
	# ledges: one-way, so a jump goes up through them and lands on top
	for y in H:
		var x := 0
		while x < W:
			if not is_ledge(x, y):
				x += 1
				continue
			var x0 := x
			while x < W and is_ledge(x, y):
				x += 1
			var shape := CollisionShape2D.new()
			var r := RectangleShape2D.new()
			r.size = Vector2((x - x0) * T, T)
			shape.shape = r
			shape.position = Vector2(x0 * T, y * T) + r.size / 2
			shape.one_way_collision = true
			body.add_child(shape)


func _draw() -> void:
	var tiles := Art.ground_tiles(th)
	for y in H:
		for x in W:
			var p := Vector2(x * T, y * T)
			if grid[idx(x, y)] == 3:
				draw_texture(Art.deadly_tile(th), p)
			elif solid(x, y):
				var open_above := y > 0 and not solid(x, y - 1)
				if open_above and (kind == "explore" or kind == "town") and y > surface[x]:
					draw_texture(tiles[3], p)
				else:
					draw_texture(tiles[0] if open_above else tiles[1], p)
			elif (kind == "explore" or kind == "town") and y > surface[x]:
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
	_register(n)
	if live and netted and Net.is_host():
		Net.node_spawned.rpc(id, _node_data(n))
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
	if home_cell.x < 0:
		home_cell = Vector2i(2, surface[2] - 1)
	add_portal(home_cell, "town", "Town", Color("5cbf3f"))
	var cells := floor_cells(10)
	cells.shuffle()
	var used := {home_cell: true}
	var deep := []
	for c in cells:
		if c.y > 40 and c.x > W * 0.55:
			deep.append(c)
	deep.shuffle()
	if def.has("next") and deep.size() > 0:
		var pc: Vector2i = deep.pop_back()
		add_portal(pc, def.next, Data.WORLDS[def.next].name, Color("a77ee0"))
		used[pc] = true
	if id == "hell_2":
		# the GateKeeper who lost his mask
		var gc := Vector2i(12, surface[12] - 1)
		add_npc("warden_hell", gc)
		used[gc] = true
	if id == "grass_1":
		# Jumpie waits near the entrance of the first Grasslands
		var jc := Vector2i(10, surface[10] - 1)
		add_npc("jumpie", jc)
		used[jc] = true
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
		if touches_deadly(Rect2(c.x * T - 4, c.y * T - 8, T + 8, T + 8)):
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
	GS.clock = 0.0
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
	var y := TOWN_MID - 1
	var top := TOWN_TOP - 1
	var houses := [[15, "e8dccb", "d8433a", 52], [23, "c8d6e8", "3b5dc9", 52], [40, "e8d8b0", "4f9a44", 52], [47, "d8c8e8", "7b4fb8", 52]]
	for h in houses:
		var s := Sprite2D.new()
		s.texture = Art.house_tex(Color(h[1]), Color(h[2]), h[3])
		s.centered = false
		s.position = Vector2(h[0] * T - h[3] / 2, (y + 1) * T - 47)
		props.add_child(s)
	# the street, west to east: the magic soils in the cave behind the rock wall
	# (break it with a gold pickaxe), the Miner and Brutus, Miffie, the sign,
	# the Gatekeeper by her portal, the Plumber, Banka (storage), the Merchant and the Crafter
	for i in 5:
		add_station("soil", i, Vector2i(2 + i * 2, y))
	if not Net.room_opened("rock_wall"):
		var rw: Node = add_node("rock_wall", Vector2i(11, y))
		rw.make_solid()
	add_npc("miner", Vector2i(13, y))
	add_npc("gruff", Vector2i(15, y))
	add_npc("mira", Vector2i(19, y))
	add_station("sign", 0, Vector2i(27, y))
	add_npc("keeper", TOWN_PORTAL + Vector2i(3, 0))
	add_npc("tools", Vector2i(37, y))
	add_npc("banka", Vector2i(40, y))
	add_npc("merchant", Vector2i(43, y))
	add_npc("smith", Vector2i(47, y))
	# upstairs, west: the Trading Center behind its wooden wall (burn it with a Torch)
	add_npc("trader", Vector2i(3, top))
	add_board("coin", Vector2i(5, top))
	add_station("trade_table", 0, Vector2i(8, top))
	add_station("trade_table", 1, Vector2i(12, top))
	if not Net.room_opened("trade_wall"):
		var tw: Node = add_node("trade_wall", Vector2i(TOWN_ROOM, top))
		tw.make_solid()
	# the incubator and the three keg chests, each with a signboard showing its egg or key
	add_board("green_egg", Vector2i(18, top))
	add_station("incubator", 0, Vector2i(19, top))
	add_board("silver_key", Vector2i(21, top))
	add_station("chest_silver", 0, Vector2i(22, top))
	add_board("golden_key", Vector2i(24, top))
	add_station("chest_golden", 0, Vector2i(25, top))
	add_board("master_key", Vector2i(27, top))
	add_station("chest_master", 0, Vector2i(28, top))
	# upstairs, east: the green GateKeeper by the furnace room's gate
	add_npc("warden", Vector2i(W - 4 - TOWN_ROOM, top))
	if not GS.flags.get("furnaces", false):
		add_station("gate", 0, Vector2i(W - 1 - TOWN_ROOM, top))
	for i in Data.FURNACES:
		add_station("furnace", i, Vector2i(W - TOWN_ROOM + i * 3, top))
		add_station("furnace_board", i, Vector2i(W - TOWN_ROOM + 1 + i * 3, top))
	# east end of the street: the massive stone wall only the Wall Hammer breaks,
	# closing the tunnel to the hole down to the basement
	if not Net.room_opened("hammer_wall"):
		var hw: Node = add_node("hammer_wall", Vector2i(W - 12, y))
		hw.make_solid()
	var under := ["nini", "nana", "nina", "fc_9912", "tt_1001", "oop_2219"]
	for i in under.size():
		add_npc(under[i], Vector2i(24 + i * 5, TOWN_BASE - 1))

## The Gatekeeper's portal: picking a world opens it on the street.
func open_town_portal(target: String) -> void:
	for n in props.get_children():
		if n is PortalScript and n.get_meta("gate", false):
			n.queue_free()
	var p := add_portal(TOWN_PORTAL, target, Data.WORLDS[target].name, Color("a77ee0"))
	p.set_meta("gate", true)
	burst(cell_pos(TOWN_PORTAL) + Vector2(0, -16), Color("a77ee0"), 14)

func add_board(item: String, c: Vector2i) -> void:
	var s := Sprite2D.new()
	s.texture = Art.prop_tex("board", item)
	s.centered = false
	s.position = Vector2(c.x * T + 8 - s.texture.get_width() / 2.0, (c.y + 1) * T - s.texture.get_height() + 1)
	props.add_child(s)

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
	_register(m)
	if live and netted and Net.is_host():
		# sent next frame so callers can set boss and aggro flags first
		_announce_mob.call_deferred(m)
	return m

func _announce_mob(m: Node) -> void:
	if is_instance_valid(m) and not m.dead:
		Net.mob_spawned.rpc(id, _mob_data(m))

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
		if n.get("kind") == "furnace_board":
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
	if (kind == "explore" or kind == "town") and player:
		var cx := clampi(int(player.position.x / T), 0, W - 1)
		under = clampf((player.position.y / T - surface[cx]) / 6.0, 0, 0.5 if kind == "explore" else 0.3)
	var dark := maxf(d * 0.85, under)
	if def.theme == "ghost":
		dark = maxf(dark, 0.45)
	modulate_node.color = Color(1, 1, 1).lerp(Color(0.22, 0.24, 0.42), dark)
	var sky_dark := 0.5 if def.theme == "ghost" else d * 0.85
	for p in parallax_items:
		p.modulate = Color(1, 1, 1).lerp(Color(0.22, 0.24, 0.42), sky_dark)
	if not Net.authority() and netted:
		return
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
		announce("The boss has arrived!", "danger")
		main.hud.set_boss(first)
	if bosses_spawned:
		var alive := false
		for e in entities.get_children():
			if e is MobScript and e.arena_boss and not e.dead:
				alive = true
		if not alive:
			arena_done = true
			GS.flags["cleared_" + id] = true
			for d in def.boss_drops:
				if rng.randf() < d[1]:
					drop(d[0], rng.randi_range(d[2], d[3]), player.position + Vector2(0, -20))
			announce("Arena cleared!", "good")
			add_portal(Vector2i(W / 2, 17), "town", "Home", Color("5cbf3f"))

func arena_time_left() -> float:
	return maxf(0, Data.ARENA_BOSS_TIME - arena_time)

func _survival_tick(delta: float) -> void:
	var night := GS.is_night()
	if night and not s_night:
		s_night = true
		Sfx.play("night", 0.0)
		announce("Night %d. Here they come!" % s_day, "danger")
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
			GS.give("survival_token", tokens)
		if netted and Net.is_host():
			Net.night_survived.rpc(tokens)
		announce("You survived night %d! +%d Survival Tokens" % [s_day, tokens], "good")
		if s_day == Data.WALL_HAMMER_DAY:
			_give_wall_hammer()
			if netted and Net.is_host():
				Net.wall_hammer.rpc()
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
## personal: an item only you can pick up (your own overflow), never shared with the room.
func drop(item: String, n: int, pos: Vector2, personal := false) -> void:
	var p := PickupScript.new()
	p.setup(item, n, self)
	p.position = pos + Vector2(randf_range(-4, 4), -6)
	entities.add_child(p)
	if personal:
		return
	_register(p)
	if live and netted and Net.is_host():
		Net.pickup_spawned.rpc(id, [p.nid, item, n, p.position.x, p.position.y, p.vel.x, p.vel.y])

func number(pos: Vector2, text: String, color: Color) -> void:
	var f := FxScript.new()
	f.setup_text(text, color)
	f.position = pos
	add_child(f)

## An emote over someone's head (you or another player); replaces the last one.
func show_emote(who: Node2D, e: String) -> void:
	var old: Node = who.get_node_or_null("Emote")
	if old:
		old.name = "OldEmote"
		old.queue_free()
	var em := EmoteScript.new()
	em.setup(e)
	who.add_child(em)

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
	if netted and Net.is_client():
		Net.request_place.rpc_id(1, id, item, x, (cy + 1) * T)
		return true
	place_at(item, Vector2(x, (cy + 1) * T))
	return true

func place_at(item: String, pos: Vector2) -> Node:
	var p := PlacedScript.new()
	p.setup(item, self)
	p.position = pos
	props.add_child(p)
	_register(p)
	if netted and Net.is_host():
		Net.placed_spawned.rpc(id, [p.nid, item, pos.x, pos.y, p.hp])
	return p

# ---------------------------------------------------------------- multiplayer
## Says something to everyone in the room (or just you when playing alone).
func announce(text: String, kind_name: String = "") -> void:
	main.hud.toast(text, kind_name)
	if netted and Net.is_host():
		Net.announce.rpc(text, kind_name)

func _register(obj: Node) -> void:
	if obj.nid == 0:
		obj.nid = next_nid
		next_nid += 1
	else:
		next_nid = maxi(next_nid, obj.nid + 1)
	net_objs[obj.nid] = obj

func _node_data(n: Node) -> Array:
	return [n.nid, n.kind, n.position.x, n.position.y, n.hits, n.alive]

func _mob_data(m: Node) -> Array:
	return [m.nid, m.id, m.position.x, m.position.y, m.hp, m.max_hp, m.dmg, m.arena_boss, m.aggro_forced]

## Everything on this map, for a friend who's loading it.
func net_state() -> Dictionary:
	var st := {"nodes": [], "mobs": [], "pickups": [], "placed": [], "portals": [], "stations": [], "npcs": [], "tick": tick_state()}
	for n in props.get_children():
		if n is NodeScript:
			st.nodes.append(_node_data(n))
		elif n is PlacedScript:
			st.placed.append([n.nid, n.item, n.position.x, n.position.y, n.hp])
		elif n is PortalScript:
			st.portals.append([n.position.x, n.position.y, n.target, n.label_text, n.tint])
		elif n is StationScript:
			st.stations.append([n.kind, n.index, n.position.x, n.position.y])
		elif n is NpcScript:
			st.npcs.append([n.npc_id, n.position.x, n.position.y])
	for e in entities.get_children():
		if e is MobScript and not e.dead:
			st.mobs.append(_mob_data(e))
		elif e is PickupScript and e.nid != 0 and not e.taken:
			st.pickups.append([e.nid, e.item, e.n, e.position.x, e.position.y, 0.0, 0.0])
	return st

func _apply_net_state(st: Dictionary) -> void:
	for d in st.get("nodes", []):
		add_node_from(d)
	for d in st.get("placed", []):
		add_placed_from(d)
	for d in st.get("portals", []):
		var p := PortalScript.new()
		p.setup(d[2], d[3], self, d[4])
		p.position = Vector2(d[0], d[1])
		props.add_child(p)
	for d in st.get("stations", []):
		var s := StationScript.new()
		s.setup(d[0], d[1], self)
		s.position = Vector2(d[2], d[3])
		props.add_child(s)
	for d in st.get("npcs", []):
		var n := NpcScript.new()
		n.setup(d[0], self)
		n.position = Vector2(d[1], d[2])
		props.add_child(n)
	for d in st.get("mobs", []):
		add_mob_from(d)
	for d in st.get("pickups", []):
		add_pickup_from(d)
	apply_tick_state(st.get("tick", {}))

func add_node_from(d: Array) -> void:
	if net_objs.has(int(d[0])):
		return
	var n := NodeScript.new()
	n.setup(d[1], self)
	n.nid = int(d[0])
	n.position = Vector2(d[2], d[3])
	props.add_child(n)
	_register(n)
	net_node_changed(n.nid, int(d[4]), bool(d[5]))

func add_mob_from(d: Array) -> void:
	if net_objs.has(int(d[0])):
		return
	var m := MobScript.new()
	m.setup(d[1], self)
	m.nid = int(d[0])
	m.puppet = true
	m.position = Vector2(d[2], d[3])
	m.net_target = m.position
	m.hp = float(d[4])
	m.max_hp = float(d[5])
	m.dmg = int(d[6])
	m.arena_boss = bool(d[7])
	m.aggro_forced = bool(d[8])
	entities.add_child(m)
	_register(m)

func add_pickup_from(d: Array) -> void:
	if net_objs.has(int(d[0])):
		return
	var p := PickupScript.new()
	p.setup(d[1], int(d[2]), self)
	p.nid = int(d[0])
	p.position = Vector2(d[3], d[4])
	p.vel = Vector2(d[5], d[6])
	entities.add_child(p)
	_register(p)

func add_placed_from(d: Array) -> void:
	if net_objs.has(int(d[0])):
		return
	var p := PlacedScript.new()
	p.setup(d[1], self)
	p.nid = int(d[0])
	p.position = Vector2(d[2], d[3])
	p.hp = float(d[4])
	props.add_child(p)
	_register(p)

func net_mob_died(nid: int) -> void:
	var m: Node = net_objs.get(nid)
	net_objs.erase(nid)
	if m and is_instance_valid(m):
		m.die_visual()

func net_node_changed(nid: int, hits: int, alive: bool) -> void:
	var n: Node = net_objs.get(nid)
	if n == null or not is_instance_valid(n):
		return
	if alive and hits > n.hits:
		n.shake()
	if n.alive and not alive:
		burst(n.position + Vector2(0, -8), Color(n.def.color), 10)
	n.hits = hits
	n.alive = alive
	if n.sprite:
		n.sprite.visible = alive

func net_remove(nid: int, _placed: bool = false) -> void:
	var o: Node = net_objs.get(nid)
	net_objs.erase(nid)
	if o and is_instance_valid(o):
		if o is PlacedScript:
			burst(o.position + Vector2(0, -16), Color("a8703f"), 10)
		o.queue_free()

func mob_snapshot() -> Array:
	var out := []
	if not netted:
		return out
	for e in entities.get_children():
		if e is MobScript and not e.dead:
			out.append([e.nid, e.position.x, e.position.y, e.hp, e.dir])
	return out

func apply_mob_snapshot(snap: Array) -> void:
	if not netted:
		return
	for d in snap:
		var m: Node = net_objs.get(int(d[0]))
		if m and is_instance_valid(m) and m.puppet:
			m.net_target = Vector2(d[1], d[2])
			if float(d[3]) < m.hp:
				m.show_bar = 4.0
				m.flash = 0.1
			m.hp = float(d[3])
			m.dir = int(d[4])

func tick_state() -> Dictionary:
	return {"arena_time": arena_time, "bosses": bosses_spawned, "done": arena_done, "s_day": s_day, "s_night": s_night}

func apply_tick_state(ts: Dictionary) -> void:
	if ts.is_empty() or Net.authority():
		return
	arena_time = ts.get("arena_time", arena_time)
	bosses_spawned = ts.get("bosses", bosses_spawned)
	if kind == "arena" and ts.get("done", false) and not arena_done:
		add_portal(Vector2i(W / 2, 17), "town", "Home", Color("5cbf3f"))
	arena_done = ts.get("done", arena_done)
	s_day = ts.get("s_day", s_day)
	s_night = ts.get("s_night", s_night)

## Other players: shown only while they're on the same map as you.
## In Pixel Town, a wall someone else in the room has opened opens here too.
func sync_room_walls() -> void:
	if kind != "town":
		return
	for n in props.get_children():
		if n is NodeScript and n.alive and n.def.get("wall", false) and Net.room_opened(n.def.get("flag", "rock_wall")):
			n.open_wall(false)

func update_puppet(peer: int, pname: String, st: Dictionary) -> void:
	if st.get("world", "") != id:
		remove_puppet(peer)
		return
	var pp: Node = puppets.get(peer)
	if pp == null or not is_instance_valid(pp):
		pp = PuppetScript.new()
		pp.setup(peer, pname)
		entities.add_child(pp)
		puppets[peer] = pp
	pp.apply(st)
	if kind == "town" and not st.get("walls", []).is_empty():
		sync_room_walls()

func remove_puppet(peer: int) -> void:
	var pp: Node = puppets.get(peer)
	puppets.erase(peer)
	if pp and is_instance_valid(pp):
		pp.queue_free()

## The player a monster should go after: the closest one still standing.
func target_for(pos: Vector2) -> Node2D:
	var best: Node2D = player
	var bd := INF if player.dead else pos.distance_to(player.position)
	for peer in puppets:
		var pp: Node2D = puppets[peer]
		if is_instance_valid(pp) and not pp.dead:
			var d := pos.distance_to(pp.position)
			if d < bd:
				bd = d
				best = pp
	return best

## Lets the rest of the room see a projectile that was just fired here.
func share_projectile(p: Node) -> void:
	if netted and Net.active:
		Net.projectile_fx.rpc(id, p.position.x, p.position.y, p.vel.x, p.vel.y, p.gravity, p.color, p.radius, not p.friendly, p.dmg)

func net_projectile(pos: Vector2, vel: Vector2, gravity: float, color: Color, radius: float, hostile: bool, dmg: int) -> void:
	var p := ProjectileScript.new()
	p.setup(self, vel, dmg, not hostile, color)
	p.visual = not hostile # someone else's arrow: it flies, but their game does the damage
	p.gravity = gravity
	p.radius = radius
	p.position = pos
	entities.add_child(p)

## Surviving enough nights in Survival Grasslands earns the Wall Hammer, which
## breaks the stone wall in the east of Pixel Town.
func _give_wall_hammer() -> void:
	if GS.count("wall_hammer") > 0 or GS.in_storage("wall_hammer") > 0 or GS.flags.get("hammer_wall", false):
		return
	GS.give("wall_hammer", 1)
	main.hud.toast("You earned the Wall Hammer! Try it on the big stone wall in the east of Pixel Town.", "big")
