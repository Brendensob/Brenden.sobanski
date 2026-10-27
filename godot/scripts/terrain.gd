extends Node2D
## The ground of a map, drawn the way a tileset artist would draw it. Every tile
## looks at its neighbours: open tops get a grass cap with tufts (or a lit lip in
## caves), open sides an outline with a light rim on the left and shade on the
## right, open undersides a shaded edge with roots or icicle-like drips, and
## outside corners are rounded. The ground darkens the deeper it goes.
## - The map's edges are rock cliffs that carry on up past the top of the map,
##   and the bottom of a cave world is bedrock.
## - Back walls in caves get soft shadows next to the rock. Dark worlds have mossy
##   brick back walls (Brenden's Darklands recording), the tomb has sandstone
##   blocks, icy worlds have ice blocks and Pixel Town's basement is stone brick.
## - Ledges you jump up through are wooden planks underground and thin grassy
##   platforms in the open air. Deadly walls are red stone with steel spikes.
## It's all baked once into 256 x 256 pictures when the map is built, and a
## shader darkens the ground smoothly the deeper it is.

const T := 16
const CHUNK := 16 # tiles per side of a baked picture
const SKY_ROWS := 26 # the edge cliffs go on up this far past the top of the map
const TOP := 4 # a tile piece has 4 px of room above the tile (tufts)
const PIECE_H := 26 # ... and 6 px below it (roots, drips)

enum { EMPTY, EARTH, ROCK, BRICK, DEADLY, LEDGE }
const OPEN_U := 1
const OPEN_D := 2
const OPEN_L := 4
const OPEN_R := 8
const INNER_L := 16 # a wall rises on the left of an open top
const INNER_R := 32

const BACK_STYLES := {"dark": "brick", "ghost": "brick", "nightmare": "brick", "modina": "brick", "hell": "brick",
	"tomb": "sand", "ice": "ice", "snow": "ice"}
const DepthShader := preload("res://shaders/ground_depth.gdshader")
const FLOWERS := {"grass": "ffe46a", "egg": "ff8ac0", "fruit": "ff6a5a", "dream": "fff2fa", "mushroom": "f2a33a"}

static var _cache := {}

var lv: Node
var pal: Dictionary
var y_start := 0
var chunks: Array = [] # [position, texture]
var mats := PackedByteArray() # what every cell is made of, one cell of padding all round
var mw := 0

# ---------------------------------------------------------------- baking
func bake(level: Node) -> void:
	lv = level
	pal = palette(level.th, level.kind == "town")
	y_start = 0 if level.kind == "town" else -SKY_ROWS
	chunks.clear()
	var rows: int = level.H - y_start
	mw = level.W + 2
	mats.resize(mw * (rows + 2))
	for y in range(y_start - 1, level.H + 1):
		for x in range(-1, level.W + 1):
			mats[(y - y_start + 1) * mw + x + 1] = _mat_raw(x, y)
	for cy in ceili(rows / float(CHUNK)):
		for cx in ceili(level.W / float(CHUNK)):
			var x0 := cx * CHUNK
			var y0 := y_start + cy * CHUNK
			var img := Image.create(CHUNK * T, CHUNK * T, false, Image.FORMAT_RGBA8)
			var x1 := mini(x0 + CHUNK, level.W)
			var y1 := mini(y0 + CHUNK, level.H)
			# back walls first, then the ground on top (its overhangs reach one row
			# into the pictures above and below, so look one row further each way)
			if lv.kind == "explore" or lv.kind == "town":
				for y in range(maxi(y0, 0), y1):
					for x in range(x0, x1):
						if y > lv.surface[x]:
							_back_cell(img, x, y, Vector2i((x - x0) * T, (y - y0) * T))
			for y in range(y0 - 1, y1 + 1):
				for x in range(x0, x1):
					var m := mat(x, y)
					if m != EMPTY:
						var piece := _piece_for(x, y, m)
						img.blend_rect(piece, Rect2i(0, 0, T, PIECE_H), Vector2i((x - x0) * T, (y - y0) * T - TOP))
			if not img.is_invisible():
				chunks.append([Vector2(x0 * T, y0 * T), ImageTexture.create_from_image(img)])
	var surf := Image.create(level.W, 1, false, Image.FORMAT_R8)
	for x in level.W:
		surf.set_pixel(x, 0, Color(clampi(level.surface[x], 0, 255) / 255.0, 0, 0))
	var sm := ShaderMaterial.new()
	sm.shader = DepthShader
	sm.set_shader_parameter("surface", ImageTexture.create_from_image(surf))
	sm.set_shader_parameter("columns", float(level.W))
	material = sm
	queue_redraw()

func _draw() -> void:
	for c in chunks:
		draw_texture(c[1], c[0])

## What a cell is made of. Outside the map left and right is rock; above the
## map only the edge cliffs carry on.
func mat(x: int, y: int) -> int:
	if x >= -1 and x <= lv.W and y >= y_start - 1 and y <= lv.H:
		return mats[(y - y_start + 1) * mw + x + 1]
	return _mat_raw(x, y)

func _mat_raw(x: int, y: int) -> int:
	if x < 0 or x >= lv.W:
		return ROCK
	if y >= lv.H:
		return ROCK
	if y < 0:
		return ROCK if (x == 0 or x == lv.W - 1) and lv.kind != "town" and y >= y_start else EMPTY
	var v: int = lv.grid[lv.idx(x, y)]
	match v:
		0: return EMPTY
		2: return LEDGE
		3: return DEADLY
	if x == 0 or x == lv.W - 1:
		return ROCK
	if lv.kind == "town":
		if y < lv.TOWN_CEIL or y >= lv.TOWN_BASE:
			return ROCK
		if (x == lv.TOWN_ROOM or x == lv.W - 1 - lv.TOWN_ROOM) and y < lv.TOWN_TOP:
			return BRICK
	elif lv.kind == "explore" and y >= lv.H - 2 - (1 if _hash(x, 0) % 3 == 0 else 0):
		return ROCK
	return EARTH

func _full(x: int, y: int) -> bool:
	var m := mat(x, y)
	return m != EMPTY and m != LEDGE

static func _hash(x: int, y: int) -> int:
	return posmod((x * 73856093) ^ (y * 19349663) ^ (x * y * 83492791), 1000003)

func _surf(x: int) -> int:
	return lv.surface[clampi(x, 0, lv.W - 1)]

func _piece_for(x: int, y: int, m: int) -> Image:
	var v := _hash(x, y) % 16
	if m == LEDGE:
		var ls := 1 if mat(x - 1, y) == LEDGE else (2 if _full(x - 1, y) else 0)
		var rs := 1 if mat(x + 1, y) == LEDGE else (2 if _full(x + 1, y) else 0)
		var air: bool = y <= _surf(x) and lv.kind != "town"
		return _ledge_piece(v % 4, ls, rs, air)
	var bits := 0
	if not _full(x, y - 1):
		bits |= OPEN_U
		if _full(x - 1, y) and _full(x - 1, y - 1):
			bits |= INNER_L
		if _full(x + 1, y) and _full(x + 1, y - 1):
			bits |= INNER_R
	if not _full(x, y + 1):
		bits |= OPEN_D
	if not _full(x - 1, y):
		bits |= OPEN_L
	if not _full(x + 1, y):
		bits |= OPEN_R
	var grassy := y <= _surf(x)
	# bedrock and the town's frame sit a little darker than the edge cliffs
	var dark: bool = m == ROCK and x > 0 and x < lv.W - 1
	return _solid_piece(m, v, dark, bits, grassy)

# ---------------------------------------------------------------- the theme's colours
## The same cartoon pop the sprites get (Art.cartoon): a little more saturation
## and brightness.
static func _pop(c: Color) -> Color:
	return Color.from_hsv(c.h, minf(c.s * 1.15, 1.0), minf(c.v * 1.05, 1.0), c.a)

static func palette(th: Dictionary, town: bool) -> Dictionary:
	var dirt: Color = _pop(th.dirt)
	var grass: Color = _pop(th.top)
	var p := {
		"name": th.name + ("_town" if town else ""), "theme": th.name,
		"grass": grass, "grass_dark": _pop(th.top2), "grass_light": grass.lightened(0.32),
		"dirt": dirt, "dirt_dark": _pop(th.dirt2), "dirt_light": dirt.lightened(0.15),
		# bold, nearly black outlines like the sprites', tinted a touch by the ground
		"line": th.dirt2.darkened(0.62).lerp(Color("1b1a24"), 0.5),
		"rock": _pop((th.dirt as Color).lerp(Color("85828c"), 0.6)),
		"back": th.cave, "moss": _pop(th.top2),
		"back_style": BACK_STYLES.get(th.name, "earth"),
		"brick": Color("9a94a2"),
		"wood": Color("a86e3c"), "wood_light": Color("d29a5e"), "wood_dark": Color("6e4426"),
		"flower": Color(FLOWERS[th.name]) if FLOWERS.has(th.name) else Color(0, 0, 0, 0),
	}
	if town:
		p.back_style = "brick"
		p.back = Color("4a4450")
		p.moss = Color("3e7a3a")
	p.rock_light = (p.rock as Color).lightened(0.22)
	p.rock_dark = (p.rock as Color).darkened(0.28)
	return p

# ---------------------------------------------------------------- pixel helpers
static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

static func _shade(img: Image, x: int, y: int, k: float) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		var c := img.get_pixel(x, y)
		if c.a > 0.0:
			img.set_pixel(x, y, c.lightened(k) if k > 0 else c.darkened(-k))

static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_px(img, xx, yy, c)

## A rounded block with a light top and a dark bottom, like a stone or a brick.
static func _block(img: Image, x: int, y: int, w: int, h: int, c: Color, light: Color, dark: Color, round_it := true) -> void:
	_rect(img, x, y, w, h, c)
	_rect(img, x, y, w, 1, light)
	_rect(img, x, y, 1, h, c.lerp(light, 0.5))
	_rect(img, x, y + h - 1, w, 1, dark)
	_rect(img, x + w - 1, y, 1, h, c.lerp(dark, 0.6))
	if round_it and w > 2 and h > 2:
		for p in [Vector2i(x, y), Vector2i(x + w - 1, y), Vector2i(x, y + h - 1), Vector2i(x + w - 1, y + h - 1)]:
			_px(img, p.x, p.y, dark.darkened(0.25))

# ---------------------------------------------------------------- tile fills
## v is 0-15: eight designs, each also flipped. Mossy rock has moss on its stones.
func _fill(m: int, v: int, dark: bool, mossy: bool) -> Image:
	var key := "fill|%s|%d|%d|%s|%s" % [pal.name, m, v, dark, mossy]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%d|%d" % [pal.name, m, v % 8])
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	match m:
		EARTH: _earth(img, rng, v % 8)
		ROCK: _cobbles(img, rng, v % 4, pal.rock, pal.rock_light, pal.rock_dark, pal.moss if mossy else Color(0, 0, 0, 0))
		BRICK: _bricks(img, rng, 8, 4, pal.brick, pal.line.lerp(Color("2e2c36"), 0.6), v)
		DEADLY: _deadly(img, rng)
	if v >= 8:
		img.flip_x()
	if dark:
		_darken_all(img, 0.12)
	_cache[key] = img
	return img

static func _darken_all(img: Image, k: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, c.darkened(k))

## Dirt: mostly calm colour, so the edges and the things on it stand out. One
## design in four has a pebble, one in eight a bigger stone.
func _earth(img: Image, rng: RandomNumberGenerator, design: int) -> void:
	var dirt: Color = pal.dirt
	var soft: Color = dirt.lerp(pal.dirt_dark, 0.4)
	img.fill(dirt)
	for i in 2:
		var x := rng.randi_range(1, 10)
		var y := rng.randi_range(2, 12)
		_rect(img, x, y, rng.randi_range(3, 5), 2, soft)
		_rect(img, x + 1, y - 1, 2, 1, soft)
	for i in 3:
		_rect(img, rng.randi_range(1, 13), rng.randi_range(1, 14), rng.randi_range(1, 2), 1, pal.dirt_dark)
	for i in 2:
		_px(img, rng.randi_range(1, 14), rng.randi_range(1, 14), pal.dirt_light)
	if design == 1 or design == 5:
		_pebble(img, rng.randi_range(2, 10), rng.randi_range(3, 11), 3, 2)
	elif design == 3:
		_pebble(img, rng.randi_range(2, 7), rng.randi_range(3, 9), 5, 3)

## A stone in the dirt, with a dark rim, a lit top and a shaded corner.
func _pebble(img: Image, x: int, y: int, w: int, h: int) -> void:
	var rim: Color = pal.dirt_dark.darkened(0.2)
	var rock: Color = pal.rock
	_rect(img, x + 1, y, w, 1, rim)
	_rect(img, x + 1, y + h + 1, w, 1, rim)
	_rect(img, x, y + 1, 1, h, rim)
	_rect(img, x + w + 1, y + 1, 1, h, rim)
	_rect(img, x + 1, y + 1, w, h, rock)
	_rect(img, x + 1, y + 1, w - 1, 1, pal.rock_light)
	_px(img, x + w, y + h, pal.rock_dark)

## Cobbles: a few big stones per tile with dark joints between them.
static func _cobbles(img: Image, rng: RandomNumberGenerator, layout: int, rock: Color, light: Color, dark: Color, moss := Color(0, 0, 0, 0)) -> void:
	var joint := dark.darkened(0.3)
	img.fill(joint)
	var layouts := [
		[[0, 0, 10, 7], [10, 0, 6, 7], [0, 7, 6, 9], [6, 7, 10, 9]],
		[[0, 0, 6, 8], [6, 0, 10, 8], [0, 8, 9, 8], [9, 8, 7, 8]],
		[[0, 0, 16, 6], [0, 6, 8, 10], [8, 6, 8, 10]],
		[[0, 0, 8, 9], [8, 0, 8, 5], [8, 5, 8, 4], [0, 9, 16, 7]],
	]
	for s in layouts[layout]:
		var c := rock.lerp(dark if rng.randf() < 0.5 else light, rng.randf_range(0.0, 0.25))
		_block(img, s[0], s[1], s[2] - 1, s[3] - 1, c, c.lerp(light, 0.7), c.lerp(dark, 0.7))
		if s[2] > 5 and s[3] > 5 and rng.randf() < 0.5:
			_px(img, s[0] + rng.randi_range(2, s[2] - 3), s[1] + rng.randi_range(2, s[3] - 3), c.lerp(dark, 0.5))
		if moss.a > 0 and rng.randf() < 0.6:
			# moss growing on the top of the stone, dripping a little
			var mx: int = s[0] + rng.randi_range(0, maxi(0, s[2] - 5))
			var mwid := mini(rng.randi_range(3, 5), s[2] - 1)
			_rect(img, mx, s[1], mwid, 1, moss)
			_px(img, mx + 1, s[1], moss.lightened(0.25))
			_px(img, mx + rng.randi_range(0, mwid - 1), s[1] + 1, moss.darkened(0.15))

## Bricks in a running bond, each a little different.
static func _bricks(img: Image, rng: RandomNumberGenerator, bw: int, bh: int, brick: Color, mortar: Color, v: int) -> void:
	img.fill(mortar)
	for row in T / bh:
		var off := (bw / 2) if row % 2 == 1 else 0
		for bx in range(-off, T, bw):
			var c := brick.lerp(Color.BLACK if rng.randf() < 0.5 else Color.WHITE, rng.randf_range(0.0, 0.08))
			var x0 := maxi(bx, 0)
			var x1 := mini(bx + bw - 1, T)
			_rect(img, x0, row * bh, x1 - x0, bh - 1, c)
			_rect(img, x0, row * bh, x1 - x0, 1, c.lightened(0.14))
			_rect(img, x0, row * bh + bh - 2, x1 - x0, 1, c.darkened(0.12))
	if v % 3 == 0:
		# a crack
		var x := rng.randi_range(3, 11)
		var y := rng.randi_range(1, 9)
		for i in 4:
			_px(img, x + (i % 2), y + i, mortar)

func _deadly(img: Image, rng: RandomNumberGenerator) -> void:
	_bricks(img, rng, 8, 4, Color("6a1a1c"), Color("2a0808"), 1)
	# glowing cracks
	for i in 2:
		var x := rng.randi_range(2, 12)
		var y := rng.randi_range(2, 11)
		_px(img, x, y, Color("ff6a3a"))
		_px(img, x + 1, y + 1, Color("ffb35a"))
		_px(img, x + 1, y + 2, Color("ff6a3a"))

# ---------------------------------------------------------------- solid pieces
func _solid_piece(m: int, v: int, dark: bool, bits: int, grassy: bool) -> Image:
	var key := "solid|%s|%d|%d|%s|%d|%s" % [pal.name, m, v, dark, bits, grassy]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(T, PIECE_H, false, Image.FORMAT_RGBA8)
	img.blit_rect(_fill(m, v, dark, m == ROCK and grassy), Rect2i(0, 0, T, T), Vector2i(0, TOP))
	var line: Color = pal.line
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var u := bits & OPEN_U != 0
	var d := bits & OPEN_D != 0
	var l := bits & OPEN_L != 0
	var r := bits & OPEN_R != 0
	# sides: light from the top left
	if l:
		for y in T:
			_shade(img, 1, TOP + y, 0.2)
			_shade(img, 2, TOP + y, 0.08)
	if r:
		for y in T:
			_shade(img, T - 2, TOP + y, -0.24)
			_shade(img, T - 3, TOP + y, -0.1)
	# the underside: shaded, with roots, drips or little icicles hanging below
	if d:
		for x in T:
			_shade(img, x, TOP + T - 2, -0.32)
			_shade(img, x, TOP + T - 3, -0.14)
			_px(img, x, TOP + T - 1, line)
		_underside(img, m, v, rng, l, r)
	# the top
	if u:
		_top_cap(img, m, v, grassy, bits, rng)
	# outlines down the open sides
	for y in range(0 if u else TOP, TOP + T):
		if l and img.get_pixel(0, y).a > 0:
			img.set_pixel(0, y, line)
		if r and img.get_pixel(T - 1, y).a > 0:
			img.set_pixel(T - 1, y, line)
	# rounded outside corners
	if u and l:
		_corner(img, false, false)
	if u and r:
		_corner(img, true, false)
	if d and l:
		_corner(img, false, true)
	if d and r:
		_corner(img, true, true)
	if m == DEADLY:
		_spikes(img, u, d, l, r)
	_cache[key] = img
	return img

## Cuts a 45-degree corner, three pixels long, and outlines it.
func _corner(img: Image, right: bool, bottom: bool) -> void:
	for a in 4:
		for b in 4:
			if a + b > 3:
				continue
			var x := (T - 1 - a) if right else a
			var y := (TOP + T - 1 - b) if bottom else (TOP + b)
			if a + b <= 2:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				img.set_pixel(x, y, pal.line)
	# clear anything hanging past the cut corner (tufts, roots)
	var ys := range(TOP + T, PIECE_H) if bottom else range(0, TOP)
	for y in ys:
		for a in 2:
			img.set_pixel((T - 1 - a) if right else a, y, Color(0, 0, 0, 0))

func _top_cap(img: Image, m: int, v: int, grassy: bool, bits: int, rng: RandomNumberGenerator) -> void:
	var line: Color = pal.line
	var lip := not grassy or m == BRICK or m == DEADLY
	if lip:
		for x in T:
			_px(img, x, TOP, line)
			_shade(img, x, TOP + 1, 0.22)
			_shade(img, x, TOP + 2, 0.08)
		if m == EARTH and (v == 2 or v == 13):
			# a pebble resting on a cave floor
			var x := rng.randi_range(3, 11)
			_rect(img, x, TOP - 1, 2, 1, pal.rock)
			_px(img, x, TOP - 1, pal.rock_light)
			_px(img, x - 1, TOP - 1, line)
			_px(img, x + 2, TOP - 1, line)
			_rect(img, x, TOP - 2, 2, 1, line)
		return
	# grass: a dark outline on top, a bright rim, round scallops hanging into the dirt
	var grass: Color = pal.grass
	var deep := 3 if m == ROCK else 5 # rock only gets a mossy fringe
	for x in T:
		var g := deep + int(round(1.4 * sin(x * TAU / 8.0)))
		_rect(img, x, TOP, 1, g, grass)
		_px(img, x, TOP + 1, pal.grass_light)
		_px(img, x, TOP + g, pal.grass_dark)
		_shade(img, x, TOP + g + 1, -0.3)
		_px(img, x, TOP, line)
	# a few light blades in the grass
	for i in 2:
		var x := rng.randi_range(2, 13)
		_px(img, x, TOP + 2, pal.grass_light)
	# shade where a wall rises beside the grass
	if bits & INNER_L:
		for y in 7:
			_shade(img, 0, TOP + y, -0.3)
			_shade(img, 1, TOP + y, -0.15)
	if bits & INNER_R:
		for y in 7:
			_shade(img, T - 1, TOP + y, -0.3)
			_shade(img, T - 2, TOP + y, -0.15)
	# tufts sticking up above the tile
	var lo := 3 if bits & OPEN_L else 1
	var hi := T - 4 if bits & OPEN_R else T - 2
	# half the tiles have none, some one, a few two, so the grass doesn't look combed
	var spots := []
	if v % 4 >= 2:
		spots.append(rng.randi_range(lo, (lo + hi) / 2 - 1))
	if v % 4 == 3 or v == 6:
		spots.append(rng.randi_range((lo + hi) / 2 + 1, hi))
	for i in spots.size():
		var x: int = spots[i]
		var tall := (v + i) % 3 == 0
		var h := 3 if tall else 2
		for y in h:
			_px(img, x, TOP - 1 - y, grass if y < h - 1 else pal.grass_light)
			_px(img, x - 1, TOP - 1 - y, line)
			_px(img, x + 1, TOP - 1 - y, line)
		_px(img, x, TOP - 1 - h, line)
		_px(img, x, TOP, grass)
		if tall and (pal.flower as Color).a > 0 and (v == 3 or v == 15):
			_px(img, x, TOP - 1 - h, pal.flower)

func _underside(img: Image, m: int, v: int, rng: RandomNumberGenerator, l: bool, r: bool) -> void:
	var line: Color = pal.line
	var lo := 3 if l else 1
	var hi := T - 4 if r else T - 2
	if m == ROCK or m == BRICK:
		# little stone drips
		if v % 2 == 0:
			var x := rng.randi_range(lo, hi - 1)
			var c: Color = pal.rock_dark if m == ROCK else (pal.brick as Color).darkened(0.3)
			_rect(img, x, TOP + T, 2, 1, c)
			_px(img, x, TOP + T + 1, c)
			_px(img, x - 1, TOP + T, line)
			_px(img, x + 2, TOP + T, line)
			_px(img, x + 1, TOP + T + 1, line)
			_px(img, x - 1, TOP + T + 1, line)
			_px(img, x, TOP + T + 2, line)
		return
	if m != EARTH:
		return
	# a lump and a root or two
	if v % 3 != 2:
		var x := rng.randi_range(lo, hi - 1)
		_rect(img, x, TOP + T - 1, 2, 1, pal.dirt_dark.darkened(0.2))
		_px(img, x - 1, TOP + T, line)
		_px(img, x + 2, TOP + T, line)
		_rect(img, x, TOP + T, 2, 1, line)
	for i in (1 if v % 2 == 0 else 0) + (1 if v == 5 else 0):
		var x := rng.randi_range(lo, hi)
		var y := TOP + T
		var root: Color = pal.dirt_dark.darkened(0.25)
		for k in rng.randi_range(2, 5):
			_px(img, x, y + k, root)
			if k % 2 == 1:
				x += rng.randi_range(-1, 1)

## Steel spikes along the open sides of a deadly wall, inside the tile.
func _spikes(img: Image, u: bool, d: bool, l: bool, r: bool) -> void:
	var steel := Color("e2dcd6")
	var shade := Color("8f8486")
	var line := Color("2a0808")
	for c in [3, 8, 13]:
		for k in 4:
			var half := k / 2
			for o in range(-half, half + 1):
				var col: Color = steel if o <= 0 else shade
				if l:
					_px(img, k, TOP + c + o, col)
				if r:
					_px(img, T - 1 - k, TOP + c + o, col)
				if u:
					_px(img, c + o, TOP + k, col)
				if d:
					_px(img, c + o, TOP + T - 1 - k, col)
		if l:
			_px(img, 0, TOP + c, line)
		if r:
			_px(img, T - 1, TOP + c, line)
		if u:
			_px(img, c, TOP, line)
		if d:
			_px(img, c, TOP + T - 1, line)

# ---------------------------------------------------------------- ledges
## ls/rs: what's beside it on each side: 0 open, 1 more ledge, 2 a wall.
func _ledge_piece(v: int, ls: int, rs: int, air: bool) -> Image:
	var key := "ledge|%s|%d|%d|%d|%s" % [pal.name, v, ls, rs, air]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(T, PIECE_H, false, Image.FORMAT_RGBA8)
	var line: Color = pal.line
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var hgt := 0
	if air:
		# a thin grassy platform
		hgt = 9
		for x in T:
			var g := 4 + int(round(0.8 * sin(x * TAU / 8.0)))
			_rect(img, x, TOP, 1, g, pal.grass)
			_px(img, x, TOP + 1, pal.grass_light)
			_px(img, x, TOP + g, pal.grass_dark)
			_rect(img, x, TOP + g + 1, 1, hgt - g - 2, pal.dirt)
			_px(img, x, TOP + hgt - 2, pal.dirt_dark)
			_px(img, x, TOP, line)
			_px(img, x, TOP + hgt - 1, line)
		if v % 2 == 0:
			var x := rng.randi_range(2, 12)
			_rect(img, x, TOP + hgt, 1, rng.randi_range(1, 3), pal.dirt_dark.darkened(0.25))
	else:
		# wooden planks
		hgt = 6
		var wood: Color = pal.wood
		for x in T:
			_px(img, x, TOP, line)
			_px(img, x, TOP + 1, pal.wood_light)
			_rect(img, x, TOP + 2, 1, 2, wood)
			_px(img, x, TOP + 4, pal.wood_dark)
			_px(img, x, TOP + 5, line)
		# a seam, grain and nails
		_rect(img, 8 if v % 2 else 4, TOP + 1, 1, 4, pal.wood_dark)
		_rect(img, rng.randi_range(1, 4), TOP + 3, 3, 1, wood.darkened(0.15))
		_rect(img, rng.randi_range(9, 12), TOP + 2, 3, 1, wood.lightened(0.1))
		_px(img, 2, TOP + 2, Color("3a3438"))
		_px(img, 13, TOP + 2, Color("3a3438"))
	for side in 2:
		var s := ls if side == 0 else rs
		var x := 0 if side == 0 else T - 1
		var dx := 1 if side == 0 else -1
		if s == 0:
			# a rounded open end
			for y in hgt:
				_px(img, x, TOP + y, line)
			img.set_pixel(x, TOP, Color(0, 0, 0, 0))
			img.set_pixel(x, TOP + hgt - 1, Color(0, 0, 0, 0))
			_px(img, x + dx, TOP, line)
			_px(img, x + dx, TOP + hgt - 1, line)
		elif s == 2 and not air:
			# a bracket holding the plank to the wall
			for k in 4:
				_rect(img, mini(x, x + dx * (3 - k)), TOP + hgt + k, 4 - k, 1, pal.wood_dark)
				_px(img, x + dx * (4 - k), TOP + hgt + k, line)
			_px(img, x, TOP + hgt + 4, line)
	_cache[key] = img
	return img

# ---------------------------------------------------------------- back walls
func _back_cell(img: Image, x: int, y: int, at: Vector2i) -> void:
	var v := _hash(x, y) % 16
	img.blit_rect(_back(v), Rect2i(0, 0, T, T), at)
	if _full(x, y) and mat(x, y) != LEDGE:
		return
	# soft shadows next to the rock, moss under ceilings
	var sides := 0
	if _full(x, y - 1):
		sides |= 1
	if _full(x, y + 1):
		sides |= 2
	if _full(x - 1, y):
		sides |= 4
	if _full(x + 1, y):
		sides |= 8
	if sides != 0:
		img.blend_rect(_shadow(sides, v), Rect2i(0, 0, T, T), at)

func _back(v: int) -> Image:
	var key := "back|%s|%d" % [pal.name, v]
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|back|%d" % [pal.name, v % 8])
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	var back: Color = pal.back
	match pal.back_style:
		"brick":
			_bricks(img, rng, 8, 4, back.lightened(0.1), back.darkened(0.35), v)
		"sand":
			_bricks(img, rng, 16, 8, back.lightened(0.14), back.darkened(0.3), 1)
			if v % 4 == 1:
				# a carved zig-zag band
				for xx in T:
					_px(img, xx, 3 + absi((xx % 6) - 3) / 2, back.darkened(0.1))
		"ice":
			img.fill(back)
			_rect(img, 0, 0, T, 1, back.darkened(0.25))
			_rect(img, 0, 0, 1, T, back.darkened(0.25))
			for k in 5:
				_px(img, 3 + k + (v % 3), 9 - k, back.lightened(0.18))
			_px(img, 11, 3, back.lightened(0.3))
		_:
			img.fill(back)
			# a flat, dim rock face: an odd ledge-like streak and a few dark flecks
			if v % 8 < 5:
				var bx := rng.randi_range(1, 8)
				var by := rng.randi_range(2, 12)
				var bw := rng.randi_range(4, 7)
				_rect(img, bx, by, bw, 1, back.lightened(0.07))
				_rect(img, bx + 1, by + 1, bw - 1, 1, back.darkened(0.14))
			for i in 3:
				_rect(img, rng.randi_range(1, 13), rng.randi_range(1, 14), rng.randi_range(1, 2), 1, back.darkened(0.12))
	if v >= 8:
		img.flip_x()
	_cache[key] = img
	return img

## Shadow bands cast on the back wall by the ground around it: strongest under a
## ceiling. Brick back walls get moss hanging from the ceiling.
func _shadow(sides: int, v: int) -> Image:
	var key := "shadow|%s|%d|%d" % [pal.name, sides, v % 4]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	for y in T:
		for x in T:
			var a := 0.0
			if sides & 1:
				a = maxf(a, 0.5 * (1.0 - y / 7.0))
			if sides & 2:
				a = maxf(a, 0.3 * (1.0 - (T - 1 - y) / 4.0))
			if sides & 4:
				a = maxf(a, 0.38 * (1.0 - x / 5.0))
			if sides & 8:
				a = maxf(a, 0.38 * (1.0 - (T - 1 - x) / 5.0))
			if a > 0.0:
				# stepped, so it stays crisp pixel art
				img.set_pixel(x, y, Color(0, 0, 0, snappedf(a, 0.1)))
	if sides & 1 and pal.back_style == "brick":
		var rng := RandomNumberGenerator.new()
		rng.seed = v * 31 + 7
		var moss: Color = pal.moss
		for i in 3:
			var x := rng.randi_range(1, 14)
			var n := rng.randi_range(1, 4)
			for k in n:
				img.set_pixel(x, k, moss if k < n - 1 else moss.lightened(0.25))
			img.set_pixel(clampi(x + 1, 0, T - 1), 0, moss.darkened(0.2))
	_cache[key] = img
	return img
