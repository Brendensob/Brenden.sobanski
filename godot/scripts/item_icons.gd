extends RefCounted
## Every weapon, staff, bow, piece of armour, helmet, shield and ring gets its own
## icon, drawn here on the same 10 x 10 grid as the other item icons.
##
## Each kind of item has a drawer with a few choices (blade length and tip, guard,
## pommel, helmet shape, shield shape and emblem...). The choices come from the
## item's name, so they never change between runs, and items in one family
## (Moon Blade, Moon Blade 2...) share a shape and gain marks as they go up:
##   2: a gem in the guard   3: a gem in the pommel   4: a rune on the blade
##   5: a sparkle            U: gold trim and two sparkles
## `tools/icon_audit.gd` and the autotest check that no two items look the same.

const N := 10
const GEMS := ["d8433a", "3b6fd9", "5cbf3f", "f2cf5b", "a77ee0", "4fb6d0", "f06aa0", "ea8a33", "e3ebf5"]
const GUARDS := ["c99a2e", "5c616b", "3a2a22", "8a5a32"]

## A 10 x 10 grid of palette letters. "." is empty.
class Cv:
	var g: Array = []
	var anchors := {}
	func _init() -> void:
		for y in N:
			var row := []
			row.resize(N)
			row.fill(".")
			g.append(row)
	func p(x: int, y: int, ch: String) -> void:
		if x >= 0 and y >= 0 and x < N and y < N:
			g[y][x] = ch
	func at(x: int, y: int) -> String:
		if x >= 0 and y >= 0 and x < N and y < N:
			return g[y][x]
		return "."
	func r(x: int, y: int, w: int, h: int, ch: String) -> void:
		for yy in range(y, y + h):
			for xx in range(x, x + w):
				p(xx, yy, ch)
	func pts(list: Array, ch: String) -> void:
		for q in list:
			p(q[0], q[1], ch)
	## Stamps text rows at (ox, oy); "." leaves the cell as it was.
	func stamp(rows: Array, ox := 0, oy := 0) -> void:
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if row[x] != ".":
					p(ox + x, oy + y, row[x])
	func is_empty(x: int, y: int) -> bool:
		return at(x, y) == "."
	func rows() -> Array:
		var out := []
		for row in g:
			out.append("".join(PackedStringArray(row)))
		return out

static func hv(s: String, salt: int) -> int:
	return absi(("%s#%d" % [s, salt]).hash())

static func pick(s: String, salt: int, list: Array):
	return list[hv(s, salt) % list.size()]

## "moon_blade_3" -> ["moon_blade", 3]; "_u" counts as 6.
static func split_tier(id: String) -> Array:
	if id.ends_with("_u"):
		return [id.substr(0, id.length() - 2), 6]
	for pre in ["pumpkin_saber_"]:
		if id.begins_with(pre):
			return ["pumpkin_saber", {"a": 1, "b": 2, "c": 3}.get(id.substr(pre.length()), 1)]
	if id == "pumpkin_saber":
		return [id, 4]
	var parts := id.rsplit("_", true, 1)
	if parts.size() == 2 and parts[1].is_valid_int():
		var n := int(parts[1])
		# robo masks and Modina items count from 1; others start at "2"
		return [parts[0], n]
	if parts.size() == 2 and parts[1] in ["z", "zx"]:
		return [parts[0], 5 if parts[1] == "z" else 6]
	return [id, 1]

## The marks an upgraded item gets, on top of its family's shape.
static func tier_marks(cv: Cv, tier: int) -> void:
	var a: Dictionary = cv.anchors
	if tier >= 2 and a.has("gem"):
		_mark(cv, a.gem, "a")
	if tier >= 3 and a.has("pom"):
		_mark(cv, a.pom, "a")
	if tier >= 4 and a.has("rune"):
		_mark(cv, a.rune, "A")
	if tier >= 5:
		_sparkle(cv, a.get("spark", [1, 1]))
	if tier >= 6:
		for y in N:
			for x in N:
				if cv.at(x, y) == "G":
					cv.p(x, y, "t")
		_sparkle(cv, a.get("spark2", [8, 8]))

## A mark always changes the cell: on a cell that already has the mark's colour
## it becomes a white shine instead.
static func _mark(cv: Cv, c: Array, ch: String) -> void:
	cv.p(c[0], c[1], "w" if cv.at(c[0], c[1]) == ch else ch)

static func _sparkle(cv: Cv, c: Array) -> void:
	for d in [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]:
		var x: int = c[0] + d[0]
		var y: int = c[1] + d[1]
		if cv.is_empty(x, y):
			cv.p(x, y, "y" if d != [0, 0] else "w")

# ---------------------------------------------------------------- the entry point
## Returns [rows, colour map] for items drawn here, or [] to use the plain templates.
static func make(id: String, it: Dictionary, mc: Dictionary) -> Array:
	var t: String = it.get("type", "")
	var bt := split_tier(id)
	var base: String = bt[0]
	var tier: int = bt[1]
	var cv := Cv.new()
	var map := {"X": mc.X, "x": mc.x, "w": "f2efe6", "h": "a8703f", "H": "6e4426", "y": "f2cf5b", "t": "f2cf5b",
		"a": pick(base, 1, GEMS), "A": "f2efe6", "G": pick(base, 2, GUARDS)}
	# the accent gem never matches the metal or the guard, so it always shows
	var gi := hv(base, 1)
	while map.a in [String(mc.X), String(mc.x), map.G, "f2cf5b"]:
		gi += 1
		map.a = GEMS[gi % GEMS.size()]
	match t:
		"weapon":
			if not _weapon(cv, id, base, map):
				return []
		"staff":
			if id.begins_with("iron_fist"):
				return []
			_staff(cv, id, base, map)
		"bow":
			_bow(cv, id, base, map, it)
		"ammo":
			_ammo(cv, id, base, map, tier)
		"armor":
			_armor(cv, id, base, map)
		"helmet":
			_helmet(cv, id, base, map)
		"shield":
			_shield(cv, id, base, map)
		"ring":
			_ring(cv, id, base, map)
		_:
			return []
	tier_marks(cv, tier)
	return [cv.rows(), map]

# ---------------------------------------------------------------- swords and other weapons
## A blade from the handle at the bottom left to the tip at the top right.
static func sword(cv: Cv, o: Dictionary) -> void:
	var t: int = o.get("t", 0)
	var tip: String = o.get("tip", "point")
	for r in range(t, 7):
		var c := 9 - r
		var bend := 1 if o.get("curve", false) and r <= t + 1 else 0
		cv.p(c - bend, r, "X")
		cv.p(c + 1 - bend, r, "x")
		if o.get("broad", false) and r > t:
			cv.p(c - 1 - bend, r, "X")
			if o.get("fuller", false) and r > t + 1 and r < 6:
				cv.p(c - bend, r, "x")
		if o.get("serr", false) and r > t and r < 6 and (r - t) % 2 == 1:
			cv.p(c + 2 - bend, r, "x")
		if o.get("wave", false) and r > t and r < 6 and (r - t) % 2 == 0:
			cv.p(c - 2 + (0 if o.get("broad", false) else 1), r, "X")
	var tc := 9 - t - (1 if o.get("curve", false) else 0)
	match tip:
		"clip": cv.p(tc + 1, t, ".")
		"fork":
			cv.p(tc - 1, t, "X")
			if not o.get("broad", false):
				cv.p(tc - 1, t + 1, ".")
		"hook":
			cv.p(tc - 1, t, "X")
			cv.p(tc - 2, t + 1, "X")
		"round":
			cv.p(tc - 1, t, "X")
			cv.p(tc + 1, t + 1, "X")
	# the guard, across the blade where it meets the handle
	var guard: String = o.get("guard", "bar")
	match guard:
		"bar": cv.pts([[1, 6], [2, 7], [3, 8]], "G")
		"cross": cv.pts([[0, 5], [1, 6], [2, 7], [3, 8], [4, 9]], "G")
		"crescent": cv.pts([[2, 5], [1, 6], [2, 7], [3, 8], [4, 7]], "G")
		"disc": cv.pts([[1, 6], [2, 6], [1, 7], [2, 7], [3, 7], [2, 8], [3, 8]], "G")
		"wing": cv.pts([[0, 5], [0, 6], [1, 6], [2, 7], [3, 8], [3, 9], [4, 9]], "G")
		"none": cv.pts([[2, 7]], "G")
	cv.pts([[1, 8]], "h")
	cv.pts([[0, 9]], "H")
	match o.get("pommel", "none"):
		"ball": cv.pts([[0, 9]], "G")
		"gem": cv.pts([[0, 9]], "a")
	cv.anchors = {"gem": [2, 7], "pom": [0, 9], "rune": [6, 3], "spark": [1, 1], "spark2": [7, 8]}

static func _weapon(cv: Cv, id: String, base: String, map: Dictionary) -> bool:
	var long := base.contains("long") or base == "excalibur"
	# the special shapes first
	if base.ends_with("_cast"):
		# a short, plain practice blade: wooden for the first, then copper, iron, gold
		if base == "sword_cast":
			map.X = "c8a070"
			map.x = "8a6a40"
		map.G = "6e4426"
		sword(cv, {"t": 2, "guard": "bar", "tip": "round" if base == "sword_cast" else "point", "broad": base == "gold_sword_cast"})
		return true
	if base.begins_with("glow_blade") or base in ["laser_sword"]:
		map.w = "ffffff"
		map.h = "5c616b"
		map.H = "3a3a48"
		sword(cv, {"t": 0, "guard": "none"})
		for r in range(0, 7):
			cv.p(9 - r, r, "w")
		cv.pts([[2, 7], [1, 8]], "h")
		return true
	if base.begins_with("candy_stick"):
		map.X = "d8433a" if base.ends_with("red") else "3e9a3a"
		map.x = "f2efe6"
		cv.stamp(["....XxX...", "...x...x..", "...X...X..", "......x...", ".....X....", "....x.....", "...X......", "..x.......", ".X........", ".........."])
		cv.anchors = {"spark": [1, 1]}
		return true
	if base in ["giant_candy", "ultimate_candy"]:
		map.X = "f06aa0" if base == "giant_candy" else "f2cf5b"
		map.x = "f2efe6"
		cv.stamp(["....XXXX..", "...XxxxXX.", "...XxXXxX.", "...XxXxxX.", "...XXxxXX.", "....XXXX..", "...hH.....", "..hH......", ".hH.......", "hH........"])
		if base == "ultimate_candy":
			_sparkle(cv, [1, 1])
		cv.anchors = {"spark": [1, 2]}
		return true
	if base in ["christmas_tree", "ultimate_tree"]:
		map.X = "3e9a3a"
		map.x = "2e6a2a"
		cv.stamp([".....y....", "....XX....", "....XXx...", "...XXXX...", "...XXXXx..", "..XXXXXX..", "..XXXXXXx.", ".XXXXXXXX.", "....hH....", "....hH...."])
		var balls := [[4, 3], [6, 5], [3, 6], [5, 7], [7, 7], [2, 7]]
		var n: int = 2 + int(split_tier(id)[1]) if base == "christmas_tree" else 6
		for i in mini(n, balls.size()):
			cv.p(balls[i][0], balls[i][1], "r" if i % 2 == 0 else "a")
		if base == "ultimate_tree":
			cv.pts([[5, 0], [4, 1]], "y")
		cv.anchors = {"spark": [1, 1], "spark2": [8, 2]}
		map.a = "f2cf5b"
		return true
	if base in ["king_carrot", "crazy_carrot"]:
		map.X = "ea8a33"
		map.x = "b85e1c"
		cv.stamp(["......g.g.", ".....gGg..", ".....XXg..", "....XXXx..", "....XXx...", "...XXx....", "...Xx.....", "..Xx......", ".Xx.......", ".x........"])
		if base == "king_carrot":
			cv.pts([[5, 0], [7, 0], [9, 0]], "y")
			cv.pts([[6, 0], [8, 0]], "y")
		else:
			cv.pts([[4, 3], [6, 3]], "k")
			cv.pts([[5, 4]], "w")
		return true
	if base.ends_with("pops") or base == "popstick":
		var cols: Array = {"popstick": ["f2e08a", "c8a060"], "chocolate_pops": ["6e4426", "3a2010"], "red_bean_pops": ["a8302a", "6a1a14"],
			"rocket_pops": ["d8433a", "3b5dc9"], "rainbow_pops": ["f06aa0", "6bc8f0"]}[base]
		map.X = cols[0]
		map.x = cols[1]
		cv.stamp(["....XXX...", "...XXXXX..", "...XXXXX..", "...XXXXx..", "...XXXxx..", "...XXXxx..", "....xxx...", ".....h....", ".....h....", ".....H...."])
		if base == "rocket_pops":
			cv.r(3, 3, 5, 1, "w")
			cv.r(3, 4, 5, 2, "x")
		elif base == "rainbow_pops":
			cv.r(3, 2, 5, 1, "y")
			cv.r(3, 3, 5, 1, "g")
			cv.r(3, 4, 5, 2, "x")
		elif base == "chocolate_pops":
			cv.pts([[4, 1], [6, 3], [4, 4]], "w")
		elif base == "red_bean_pops":
			cv.pts([[4, 2], [6, 2], [5, 4]], "k")
		return true
	if base == "ninja_star":
		cv.stamp(["....X.....", "....Xx....", "....XX....", "XXXXwxXXX.", ".xXXxXXXxx", "....XX....", "....Xx....", ".....x....", "..........", ".........."], 0, 1)
		return true
	if base == "moon_knifes":
		cv.stamp(["X.......X.", "Xx.....xX.", ".Xx...xX..", "..Xx.xX...", "...G.G....", "..h...h...", ".h.....h..", "H.......H.", "..........", ".........."], 0, 1)
		return true
	if base in ["moon_edge"]:
		cv.stamp(["...XXX....", ".....XX...", "......Xx..", "......Xx..", ".....Xx...", "....GG....", "...hG.....", "..hH......", ".hH.......", ".H........"])
		return true
	if base == "giant_snow_ball":
		map.X = "f4fbff"
		map.x = "a6c6d8"
		cv.stamp(["..........", "...XXXX...", "..XXwXXX..", ".XXwXXXXx.", ".XXXXXXXx.", ".XXXXXXxx.", ".XXXXXxxx.", "..xXxxxx..", "...xxxx...", ".........."])
		return true
	if base in ["timber_club"]:
		cv.stamp(["......XXX.", ".....XXXXx", ".....XXXxx", "....XXxxx.", "...hlx....", "...hl.....", "..hl......", "..hl......", ".hl.......", ".h........"])
		map.l = "a8703f"
		return true
	if base == "kings_mace":
		cv.stamp(["....y.y...", "...XXXXX..", "..XXwXXXX.", "...XXXXx..", "....Xxhl..", ".....hl...", "....hl....", "...hl.....", "..hl......", ".h........"])
		map.l = "6e4426"
		cv.anchors = {"gem": [4, 2], "spark": [1, 1], "spark2": [8, 7]}
		return true
	if base in ["devil_spike", "hell_spike"]:
		var rows := ["X...X...X.", ".X..X..X..", "..XXXXX...", "..XXwXX...", "..XXXXX...", "...xhx....", "....hl....", "...hl.....", "..hl......", ".h........"]
		if base == "hell_spike":
			rows = [".X.X.X.X..", "..XXXXX...", ".XXXXXXX..", "..XXwXX...", ".XXXXXXX..", "..XxhxX...", "....hl....", "...hl.....", "..hl......", ".h........"]
		cv.stamp(rows)
		map.l = "6e4426"
		cv.anchors = {"gem": [4, 3], "pom": [1, 9], "rune": [3, 2], "spark": [8, 5], "spark2": [7, 8]}
		return true
	if base == "plunger" or base == "unlawful":
		cv.stamp(["..XXXX....", ".XXXXXX...", "..xxxx....", "...hl.....", "...hl.....", "...hl.....", "...hl.....", "...hl.....", "...hl.....", ".........."], 1 if base == "unlawful" else 0, 0)
		map.l = "6e4426" if base == "plunger" else "8fb07a"
		map.h = "a8703f" if base == "plunger" else "5e7a52"
		if base == "unlawful":
			cv.pts([[3, 1], [5, 1]], "k")
		return true
	if base == "torch_weapon":
		cv.stamp(["...y.y....", "..yoyoy...", "..oRrRo...", "...oRo....", "....G.....", "....h.....", "....h.....", "....H.....", "....H.....", "....H....."])
		map.R = "f06a5a"
		map.r = "d8433a"
		map.o = "ea8a33"
		return true
	if base == "wall_hammer":
		cv.stamp(["XXXXX.....", "XwXXXx....", "XXXXXx....", "XXXXXx....", ".xxhHx....", "....hH....", ".....hH...", "......hH..", ".......hH.", "........hH"])
		return true
	if base in ["pole_axe", "sky_pole_axe", "hell_pole_axe"]:
		cv.stamp(["...XXX....", "..XxXX....", ".hXxXX....", ".hHXX.....", ".hH.......", ".hH.......", ".hH.......", ".hH.......", ".hH.......", ".hH......."])
		if base == "sky_pole_axe":
			cv.pts([[6, 0], [6, 1]], "X")
		elif base == "hell_pole_axe":
			cv.pts([[1, 0], [6, 2], [0, 2]], "X")
		cv.anchors = {"gem": [3, 1], "pom": [1, 9], "spark": [7, 5], "spark2": [6, 8]}
		return true
	if base in ["volcan_axe", "evil_axe"]:
		cv.stamp(["....XXX...", "...XxXXX..", "..hXxXXX..", "..hHXXX...", "..hH......", "..hH......", "..hH......", "..hH......", "..hH......", ".........."])
		if base == "evil_axe":
			cv.pts([[1, 1], [1, 2], [8, 0], [8, 3]], "X")
		else:
			cv.pts([[4, 1], [5, 2]], "a")
		cv.anchors = {"gem": [5, 1], "pom": [2, 8], "rune": [6, 2], "spark": [7, 6], "spark2": [6, 8]}
		return true
	if base == "long_lance":
		cv.stamp([".........X", "........XX", ".......XxA", "......Xx..", ".....hx...", "....hH....", "...GG.....", "..hH......", ".hH.......", "hH........"])
		map.A = map.a
		cv.anchors = {"gem": [3, 6], "pom": [0, 9], "rune": [6, 3], "spark": [1, 1], "spark2": [7, 8]}
		return true
	if base == "twin_sun" or base == "sun_extractor":
		map.X = "f2cf5b"
		map.x = "ea8a33"
		if base == "twin_sun":
			cv.stamp(["X.......X.", ".X.....X..", "..X...X...", "...XyX....", "...yay....", "...XyX....", "..X...X...", ".X.....X..", "x.......x.", ".........."])
			cv.anchors = {"gem": [4, 4], "pom": [4, 2], "rune": [4, 6], "spark": [8, 4], "spark2": [0, 4]}
		else:
			cv.stamp(["......yXy.", ".....yXXXy", "......XXx.", ".....Xyx..", "....Xx....", "...Xx.....", "..GG......", ".hG.......", "hH........", ".........."])
		return true
	if base == "hazard_wipe":
		map.X = "f2cf5b"
		map.x = "3a3a48"
		sword(cv, {"t": 0, "broad": true, "guard": "bar"})
		for r in range(1, 7, 2):
			cv.p(9 - r, r, "x")
			cv.p(8 - r, r, "x")
		return true
	if base.begins_with("firecracker_blade"):
		map.X = "d8433a"
		map.x = "f2cf5b"
		sword(cv, {"t": 1, "broad": true, "guard": "cross"})
		for r in range(2, 7, 2):
			cv.p(9 - r, r, "x")
		cv.pts([[9, 0], [8, 0]], "y")
		return true
	if base == "pumpkin_saber":
		map.X = "c8ced6"
		map.x = "7a8290"
		map.G = "ea8a33"
		sword(cv, {"t": 0, "curve": true, "guard": "disc"})
		cv.pts([[2, 7]], "k")
		return true
	if base == "christmas" or base.ends_with("santa_blade"):
		map.X = "f2efe6"
		map.x = "d8433a"
		sword(cv, {"t": 0, "broad": base.begins_with("ultimate"), "guard": "cross", "pommel": "ball"})
		for r in range(1, 7, 2):
			cv.p(9 - r, r, "x")
		map.G = "3e9a3a"
		return true
	if base == "fist":
		return false
	if base == "tsurugi":
		sword(cv, {"t": 0, "curve": true, "guard": "disc", "tip": "clip"})
		map.G = "3a3a48"
		return true
	if base.begins_with("modina"):
		sword(cv, {"t": 0, "broad": true, "wave": true, "guard": "wing", "pommel": "ball"})
		return true
	if base.contains("moon") or base == "moonclipse":
		var o := {"t": 0, "tip": "hook", "guard": "crescent"}
		if base.contains("soul"):
			o.serr = true
		if base.begins_with("dark") or base.begins_with("shadow"):
			o.broad = true
		if base == "moonclipse":
			o = {"t": 0, "broad": true, "tip": "round", "guard": "crescent", "pommel": "gem"}
		sword(cv, o)
		return true
	if base.begins_with("dragon"):
		map.X = "5cbf3f"
		map.x = "2e7a2a"
		sword(cv, {"t": 0, "broad": true, "serr": true, "guard": "wing"})
		return true
	if base.begins_with("rainbow"):
		sword(cv, {"t": 0, "broad": true, "guard": "cross"})
		var band := ["d8433a", "ea8a33", "f2cf5b", "5cbf3f", "3b6fd9", "a77ee0", "d8433a"]
		for r in 7:
			if cv.at(9 - r, r) == "X":
				cv.p(9 - r, r, "%d" % r)
				map["%d" % r] = band[r]
		return true
	# every other weapon: a sword with its own blade, tip, guard and pommel
	var o2 := {
		"t": 0 if long else pick(base, 3, [0, 1, 1, 2]),
		"broad": long or pick(base, 4, [false, false, true]),
		"tip": pick(base, 5, ["point", "point", "clip", "fork", "round", "hook"]),
		"guard": pick(base, 6, ["bar", "cross", "crescent", "disc", "wing", "none"]),
		"pommel": pick(base, 7, ["none", "ball", "gem"]),
		"serr": base.contains("devil") or base.contains("evil") or base.contains("hell") or pick(base, 8, [false, false, false, true]),
		"wave": base.contains("fire") or base.contains("volcan"),
		"curve": base.contains("saber") or pick(base, 9, [false, false, false, false, true]),
	}
	o2.fuller = o2.broad and pick(base, 10, [true, false])
	if base == "short_blade":
		o2.t = 3
	if base.begins_with("ice") or base.begins_with("heavy_ice"):
		map.X = "a6e6f2"
		map.x = "4fb6d0"
		if base.begins_with("heavy"):
			o2.broad = true
			o2.fuller = true
	sword(cv, o2)
	return true

# ---------------------------------------------------------------- staffs, wands and guns
static func _staff(cv: Cv, id: String, base: String, map: Dictionary) -> void:
	if base == "staff_cast":
		# a plain wooden staff with a round knob
		for i in 6:
			cv.p(1 + i, 9 - i, "h" if i % 2 == 0 else "H")
		cv.stamp(["......hh..", ".....hhhH.", ".....hhHH.", "......HH.."])
		return
	if base == "pistol" or base.ends_with("laser_gun"):
		if base == "pistol":
			cv.stamp(["..........", "..........", ".XXXXXXXX.", ".XwXXXXXXx", ".XXXXxxxx.", ".hHx......", ".hH.......", "hHH.......", "..........", ".........."], 0, 1)
		else:
			map.X = "a8b0bc"
			map.x = "5c616b"
			map.a = {"laser_gun": "f06a5a", "green_laser_gun": "7cf06a", "blue_laser_gun": "6bc8f0"}[base]
			cv.stamp(["..........", "..XXXXXX..", ".XwXXXXXaa", ".XXXXXXX..", "..xxXxx...", "..hHx.....", "..hH......", ".hHH......", "..........", ".........."], 0, 1)
			cv.pts([[9, 2], [9, 4]], "a")
		cv.anchors = {"gem": [3, 3], "spark": [7, 7]}
		return
	# the shaft, bottom left to top right, and a head at the top
	if base == "magic_wand":
		cv.stamp(["......y...", ".....yXy..", "......y...", ".....h....", "....h.....", "...h......", "..H.......", ".H........", "..........", ".........."])
		cv.anchors = {"gem": [6, 1], "spark": [2, 1], "spark2": [7, 6]}
		return
	for i in 6:
		cv.p(1 + i, 9 - i, "h" if i % 2 == 0 else "H")
	var head: String = "orb"
	if base.contains("fire"):
		head = "flame"
	elif base.contains("hallow") or base.contains("holy"):
		head = "cross"
	elif base.contains("heal"):
		head = "heart"
	elif base.contains("candy"):
		head = "swirl"
	elif base.contains("ruby") or base.contains("sapphire"):
		head = "crystal"
	elif base.contains("lucky"):
		head = "clover"
	elif base.contains("golden"):
		head = "star"
	if base.contains("ruby"):
		map.X = "d8433a"
		map.x = "8a1e1a"
	elif base.contains("sapphire"):
		map.X = "3b5dc9"
		map.x = "1e2a6a"
	elif base.contains("heal"):
		map.X = "f06aa0"
		map.x = "b04a78"
	elif base.contains("lucky"):
		map.X = "5cbf3f"
		map.x = "2e7a2a"
	match head:
		"orb": cv.stamp(["......XX..", ".....XwXx.", ".....XXXx.", "......xx..", "....G....."])
		"flame": cv.stamp(["......y...", ".....yoy..", ".....oRo..", "......o...", "....G....."])
		"cross": cv.stamp(["......X...", ".....XwX..", "......X...", "......X...", "....G....."])
		"heart": cv.stamp([".....X.X..", "....XwXXx.", "....XXXXx.", ".....XXx..", "....G.x..."])
		"swirl": cv.stamp([".....XXX..", "....XxxXX.", "....XXxxX.", ".....XXX..", "....G....."])
		"crystal": cv.stamp(["......X...", ".....XwX..", ".....XXx..", "......x...", "....G....."])
		"clover": cv.stamp([".....X.X..", "....XXwXX.", ".....XXX..", "....XX.XX.", "....G....."])
		"star": cv.stamp(["......X...", "....XXwXX.", ".....XXX..", ".....X.X..", "....G....."])
	map.o = "ea8a33"
	map.R = "d8433a"
	if base == "blue_staff":
		cv.pts([[5, 2], [8, 2]], "X")
	cv.anchors = {"gem": [4, 4], "pom": [1, 9], "rune": [3, 6], "spark": [1, 1], "spark2": [8, 7]}

# ---------------------------------------------------------------- bows and cannons
static func _bow(cv: Cv, id: String, base: String, map: Dictionary, it: Dictionary) -> void:
	if it.get("cannon", false):
		if base == "crazy_cannon":
			cv.stamp(["..........", "..........", "......kk..", ".XXXXXXXkk", "XwXXXXXXXk", "XXXXXXXXxk", ".xxxxxxkk.", "...hH.....", "..hHHh....", ".........."])
		elif base == "waazookaa":
			cv.stamp(["..........", "..........", "XXXXXXXXXX", "XwwwwwwwwX", "XXXXXXXXXX", "x.xxxxxx.x", "...hh.....", "...hH.....", "..........", ".........."])
			cv.pts([[0, 2], [0, 4], [9, 2], [9, 4]], "G")
		else:
			cv.stamp([".x......x.", "..x....x..", "..XXXXXX..", ".XwXXXXXXk", ".XXXXXXXxk", "..xxxxxxk.", "...hH.....", "..hHHh....", "..........", ".........."], 0, 1)
		cv.anchors = {"gem": [4, 4], "pom": [2, 4], "rune": [6, 4], "spark": [1, 0], "spark2": [8, 8]}
		return
	map.w = "f2efe6"
	var shapes := {
		"weak_bow": ["....hh....", "...h..w...", "..h....w..", "..h.....w.", "..h.....w.", "..h....w..", "...h..w...", "....hh....", "..........", ".........."],
		"bow": ["...hh.....", "..h.Hw....", ".h...Hw...", ".h....w...", ".hGG..w...", ".h....w...", ".h...Hw...", "..h.Hw....", "...hh.....", ".........."],
		"steel_bow": ["..XX......", ".X..xw....", "X....xw...", "X.....w...", "XGG...w...", "X.....w...", "X....xw...", ".X..xw....", "..XX......", ".........."],
		"fira_bow": ["y.........", ".XX.......", "X..xw.....", "X...xw....", "XGG..w....", "X...xw....", "X..xw.....", ".XX.......", "y.........", ".........."],
		"icy_bow": [".C.C......", "..XX......", ".X..xw....", "X....w....", "XGG..w....", "X....w....", ".X..xw....", "..XX......", ".C.C......", ".........."],
		"magnum_bow": ["XX........", ".XX.......", "..XXw.....", "...Xxw....", "..GGXw....", "...Xxw....", "..XXw.....", ".XX.......", "XX........", ".........."],
		"jade_bow": ["..X.......", ".X.Xw.....", ".X..xw....", "X....w....", "XaG..w....", "X....w....", ".X..xw....", ".X.Xw.....", "..X.......", ".........."],
		"snow_maker": ["..........", "..XXXXXX..", ".XwXXXXXXw", ".XXXXXXXXw", "..xxXxxx..", "...hH.....", "..hHH.....", "..........", "..........", ".........."],
	}
	cv.stamp(shapes.get(base, shapes.bow))
	if base == "fira_bow":
		map.X = "d8433a"
		map.x = "8a1e1a"
	elif base == "icy_bow" or base == "snow_maker":
		map.X = "a6e6f2"
		map.x = "4fb6d0"
		map.C = "f4fbff"
	elif base == "magnum_bow":
		map.X = "f2cf5b"
		map.x = "c99a2e"
	elif base == "jade_bow":
		map.X = "5cbf8a"
		map.x = "2e8a5a"
	map.G = "3a2a22"
	cv.anchors = {"gem": [2, 4], "pom": [1, 4], "spark": [8, 1], "spark2": [8, 7]}

static func _ammo(cv: Cv, id: String, base: String, map: Dictionary, tier: int) -> void:
	if base == "arrow":
		cv.stamp(["..........", "........aA", ".......a..", "......n...", ".....n....", "....n.....", "...n......", ".ww.......", ".w........", ".........."])
		map.a = "9aa2ad"
		map.A = "c8ced6"
		return
	if base == "cc_ball" or base == "devil_cannon_ball":
		var spots := [[3, 3], [7, 5], [2, 7]]
		var n := 1 if base == "devil_cannon_ball" else tier
		for i in n:
			var c: Array = spots[i] if n > 1 else [4, 4]
			cv.stamp(["XX.", "XXx", ".xx"], c[0] - 1, c[1] - 1)
			cv.p(c[0] - 1, c[1] - 1, "w")
		if base == "devil_cannon_ball":
			cv.pts([[2, 2], [6, 2]], "r")
			map.r = "d8433a"
		cv.anchors = {}
		return
	# missiles: longer and with more fins as they go up
	cv.stamp(["..........", "......XX..", ".....XwXr.", "....XXXr..", "...XXXX...", "..XXXX....", ".rXXX.....", "rrr.......", ".r........", ".........."])
	map.r = ["d8433a", "ea8a33", "a77ee0"][clampi(tier - 1, 0, 2)]
	if tier >= 2:
		cv.pts([[1, 5], [4, 8]], "r")
	if tier >= 3:
		cv.pts([[8, 0]], "y")
	cv.anchors = {}

# ---------------------------------------------------------------- armour
## The look of a piece of armour, picked from its name. The icon and the armour
## worn on your character use the same choices, so they match.
static func armor_parts(base: String) -> Dictionary:
	var dress := base.contains("dress") or base.contains("robe")
	var robe := dress or base in ["seer_armor", "lavish_armor", "linen_armor", "sage_armor"]
	var sh: String = pick(base, 11, ["none", "pads", "spikes", "round"])
	if base.contains("hell") or base.contains("skull") or base.contains("dark") or base.contains("nightmare"):
		sh = "spikes"
	elif base.contains("knight") or base.contains("golden") or base.contains("iron") or base.contains("silver"):
		sh = "pads"
	var collar: String = pick(base, 12, ["v", "high", "none"])
	var belt: bool = not robe or pick(base, 13, [true, false])
	var front: String = pick(base, 14, ["plates", "rivets", "emblem", "plain", "stripe"])
	if base.contains("chain"):
		front = "rings"
	elif base.contains("scale") or base.contains("dragon"):
		front = "scales"
	elif base.contains("skull") or base.contains("lich"):
		front = "skull"
	elif base.contains("snow"):
		front = "flake"
	elif base.contains("ghost"):
		front = "ghost"
	elif base.contains("jelly"):
		front = "jelly"
	elif base.contains("seer"):
		front = "eye"
	elif base.contains("emperor"):
		front = "stripe"
	elif base.contains("rooster"):
		front = "feather"
	return {"robe": robe, "sh": sh, "collar": collar, "belt": belt, "front": front}

static func _armor(cv: Cv, id: String, base: String, map: Dictionary) -> void:
	var ap := armor_parts(base)
	var robe: bool = ap.robe
	# the body
	if robe:
		cv.stamp(["..........", ".XX....XX.", ".XXXXXXXX.", "..XXXXXX..", "..XXXXXX..", "..XXXXXX..", ".XXXXXXXX.", ".XXXXXXXX.", "XXXXXXXXXX", "xxxxxxxxxx"])
	else:
		cv.stamp(["..........", ".XX....XX.", ".XXXXXXXX.", "..XXXXXX..", "..XXXXXX..", "..XXXXXX..", "..XXXXXX..", "..xxxxxx..", "..........", ".........."])
	# shoulders
	var sh: String = ap.sh
	match sh:
		"pads": cv.stamp(["GGG..GGG", "GGG..GGG"], 1, 1)
		"spikes": cv.pts([[0, 0], [9, 0], [1, 1], [8, 1], [0, 1], [9, 1]], "G")
		"round": cv.pts([[0, 1], [0, 2], [9, 1], [9, 2]], "X")
	# the collar
	match ap.collar:
		"v": cv.pts([[4, 2], [5, 2]], "x")
		"high": cv.pts([[3, 1], [6, 1]], "G")
	# a belt or a sash
	if ap.belt:
		var by := 5
		cv.r(2, by, 6, 1, "G")
		cv.p(4, by, "a")
	# the front: plates, rivets, scales, rings or a picture
	var front: String = ap.front
	match front:
		"plates": cv.pts([[3, 3], [6, 3]], "x")
		"rivets": cv.pts([[3, 3], [6, 3], [3, 4], [6, 4]], "G")
		"emblem": cv.pts([[4, 3], [5, 3], [4, 4], [5, 4]], "a")
		"stripe":
			for y in range(2, 9):
				if cv.at(4, y) != ".":
					cv.p(4, y, "G")
		"rings":
			for y in range(2, 7):
				for x in range(2, 8):
					if (x + y) % 2 == 0 and cv.at(x, y) == "X":
						cv.p(x, y, "x")
		"scales":
			for y in range(3, 7):
				for x in range(2 + y % 2, 8, 2):
					if cv.at(x, y) == "X":
						cv.p(x, y, "x")
		"skull": cv.stamp(["www.", "kwk.", ".w.."], 3, 2)
		"flake": cv.pts([[4, 3], [5, 4], [4, 4], [3, 4], [4, 5]], "w")
		"ghost":
			for x in range(0, 10, 2):
				cv.p(x, 9, ".")
		"jelly": cv.pts([[3, 3], [6, 4], [4, 6]], "w")
		"eye": cv.stamp(["ww", "ak"], 4, 3)
		"feather": cv.pts([[4, 0], [5, 0], [3, 0]], "r")
	map.r = "d8433a"
	map.k = "1b1a24"
	cv.anchors = {"gem": [4, 3], "pom": [5, 6], "rune": [3, 4], "spark": [0, 4], "spark2": [9, 4]}

# ---------------------------------------------------------------- helmets, hats and masks
## The shape of a helmet, hat or mask, from its name (shared by the icon and
## the one you wear).
static func helmet_kind(base: String) -> String:
	var named := {"alien_hat": "alien", "pumpkin_hat": "pumpkin", "bear_head": "bear", "green_face": "face", "the_fly": "fly",
		"skull_mask": "skull", "snowman_hat": "snowman", "rooster_hat": "rooster", "w_cap": "cap", "x_wings": "winged", "thors": "winged",
		"crown": "crown", "witch_helmet": "witch", "spectre_hood": "hood", "robo_mask": "robo", "halloween_mask": "pumpkin",
		"cool_hat": "tophat", "pirate_hat": "pirate", "chuu_hat": "bunny", "storm_hat": "witch", "roman_hat": "crest", "moon_hat": "moon",
		"fear_helmet": "horned", "hell_helmet": "horned", "nightmare_helmet": "horned", "soldier_helmet": "dome", "trooper_pro": "visor",
		"dark_night": "visor", "wooden_helmet": "dome", "copper_helmet": "dome", "brass_helmet": "crest", "modina_face": "face",
		"fortune_mask": "mask", "royal_mask": "mask", "spy_mask": "mask", "bad_mask": "mask", "wood_mask": "mask"}
	return named.get(base, pick(base, 15, ["dome", "visor", "crest", "horned", "mask", "hat"]))

static func _helmet(cv: Cv, id: String, base: String, map: Dictionary) -> void:
	var kind := helmet_kind(base)
	var dome := ["..........", "...XXXX...", "..XwXXXX..", ".XXXXXXXX.", ".XXXXXXXX.", ".XX....XX.", ".Xx....xX.", "..........", "..........", ".........."]
	match kind:
		"dome":
			cv.stamp(dome, 0, 1)
			cv.r(1, 5, 8, 1, "x")
			if base != "wooden_helmet":
				cv.r(1, 5, 8, 1, "G")
		"visor":
			cv.stamp(dome, 0, 1)
			cv.r(2, 6, 6, 2, "X")
			cv.r(2, 6, 6, 1, "k")
			cv.p(4, 7, "x")
		"crest":
			cv.stamp(dome, 0, 2)
			cv.stamp(["..aaaa....", ".aaaaaa..."], 1, 0)
		"horned":
			cv.stamp(dome, 0, 2)
			cv.pts([[0, 0], [0, 1], [1, 2], [9, 0], [9, 1], [8, 2]], "w")
			cv.r(2, 6, 6, 1, "k")
		"winged":
			cv.stamp(dome, 0, 2)
			cv.pts([[0, 2], [0, 3], [1, 3], [9, 2], [9, 3], [8, 3]], "w")
			cv.pts([[0, 1], [9, 1]], "w")
			cv.r(1, 6, 8, 1, "G")
		"hat":
			cv.stamp(["....X.....", "...XXX....", "...XwX....", "..XXXXX...", "..XXXXX...", "XXXXXXXXX.", ".xxxxxxx.."], 0, 2)
			cv.r(2, 6, 5, 1, "G")
		"tophat":
			cv.stamp(["..XXXXX...", "..XwXXX...", "..XXXXX...", "..XXXXX...", "..GGGGG...", "XXXXXXXXX.", ".xxxxxxx.."], 0, 2)
		"witch":
			cv.stamp([".......X..", "......XX..", ".....XXX..", "....XwXX..", "...XXXXX..", "..GGGGGG..", "XXXXXXXXXX", ".xxxxxxxx."], 0, 1)
		"pirate":
			cv.stamp(["..XXXXXX..", ".XXXXXXXX.", "XXXwwXXXXX", "XXXwwXXXXX", ".xxxxxxxx."], 0, 3)
		"cap":
			cv.stamp(["..XXXXX...", ".XXwXXXX..", ".XXXXXXX..", ".xxxxxxxGG", "........GG"], 0, 3)
			cv.p(3, 4, "w")
			map.w = "f2efe6"
		"crown":
			map.X = "f2cf5b"
			map.x = "c99a2e"
			cv.stamp(["X..X..X...", "XX.XX.XX..", "XXXXXXXX..", "XaXXaXXa..", "XXXXXXXX..", "xxxxxxxx.."], 1, 2)
		"hood":
			cv.stamp(["...XXXX...", "..XXXXXX..", ".XXkkkkXX.", ".XkkkkkkX.", ".XkCkkCkX.", ".XkkkkkkX.", "XXXkkkkXXX", "xxx....xxx"], 0, 1)
			map.C = "a6e6f2"
		"mask":
			cv.stamp(["..XXXXXX..", ".XXXXXXXX.", ".XkkXXkkX.", ".XkkXXkkX.", ".XXXXXXXX.", "..XXxxXX..", "...XXXX..."], 0, 1)
			match pick(base, 16, [0, 1, 2]):
				1: cv.pts([[2, 4], [7, 4]], "w")
				2: cv.r(1, 2, 8, 1, "G")
		"face":
			cv.stamp(["..XXXXXX..", ".XXXXXXXX.", ".XXXXXXXX.", ".XkXXXXkX.", ".XXXXXXXX.", ".XXkkkkXX.", "..XXXXXX..", "...xxxx..."], 0, 1)
		"alien":
			map.X = "7cf06a"
			map.x = "3e9a2a"
			cv.stamp(["a......a..", ".a....a...", "..XXXXX...", ".XXXXXXX..", "XkkXXXkkX.", "XkkXXXkkX.", ".XXXXXXX..", "..xxxxx..."], 0, 1)
		"pumpkin":
			map.X = "ea8a33"
			map.x = "b85e1c"
			cv.stamp(["....gg....", "..XXXXXX..", ".XXXXXXXX.", "XXkXXXXkXX", "XXXXXXXXXX", "XXkXkXkXXX", ".XXkXkXXX.", "..xxxxxx.."], 0, 1)
			if base == "halloween_mask":
				cv.pts([[3, 4], [6, 4]], "y")
		"bear":
			map.X = "8a5a32"
			map.x = "5a3a1a"
			cv.stamp([".XX....XX.", ".XxXXXXxX.", ".XXXXXXXX.", ".XkXXXXkX.", ".XXXwwXXX.", ".XXwkkwXX.", "..XXXXXX..", "...xxxx..."], 0, 1)
		"fly":
			cv.stamp(["..k....k..", "...k..k...", ".XXXXXXXX.", "XRRXXXXRRX", "XRRwXXRRwX", "XRRXXXXRRX", ".XXXXXXXX.", "..xxxxxx.."], 0, 1)
			map.R = "d8433a"
		"skull":
			map.X = "f2ecd8"
			map.x = "a89878"
			cv.stamp(["..XXXXXX..", ".XXXXXXXX.", ".XkkXXkkX.", ".XkkXXkkX.", ".XXXkkXXX.", "..XXXXXX..", "..XkXkXk..", "...xxxx..."], 0, 1)
		"snowman":
			cv.stamp(["..GGGGG...", "..GGGGG...", ".GGGGGGG..", "..WWWWW...", ".WkWWWkW..", ".WWWoWWW..", ".WWWWWWW..", "..wwwww..."], 0, 1)
			map.G = "3a3a48"
			map.W = "f4fbff"
			map.w = "a6c6d8"
			map.o = "ea8a33"
		"rooster":
			cv.stamp(["..r.r.r...", "..rrrrr...", "..XXXXXX..", ".XXXXXXXX.", ".XkXXXXX.y", ".XXXXXXyyy", "..XXXXXX..", "...r.....", "...rr....."], 0, 1)
			map.r = "d8433a"
			map.X = "f2efe6"
			map.x = "c8c0b0"
		"bunny":
			cv.stamp(["..X...X...", "..Xm..Xm..", "..Xm..Xm..", "..XXXXXX..", ".XXXXXXXX.", ".XkXXXXkX.", ".XXXmmXXX.", "..xxxxxx.."], 0, 1)
			map.m = "f06aa0"
		"robo":
			cv.stamp(["....a.....", "....G.....", "..XXXXXX..", ".XXXXXXXX.", ".GaaaaaaG.", ".XXXXXXXX.", ".XxXXXXxX.", "..xxxxxx.."], 0, 1)
			map.a = pick(id, 17, ["f06a5a", "6bc8f0", "7cf06a", "f2cf5b", "f08ac8", "a77ee0", "ffffff", "ea8a33"])
		"moon":
			cv.stamp(["....XX....", "...Xx.....", "...XX.....", "..XXXXX...", "..XXXXX...", "XXXXXXXXX.", ".xxxxxxx.."], 0, 2)
			cv.pts([[5, 0], [4, 1]], "y")
	cv.anchors = {"gem": [4, 3], "pom": [5, 3], "rune": [6, 5], "spark": [8, 0], "spark2": [0, 9]}

# ---------------------------------------------------------------- shields
static func _shield(cv: Cv, id: String, base: String, map: Dictionary) -> void:
	var shapes := {
		"heater": [".GGGGGGGG.", ".GXXXXXXG.", ".GXXXXXXG.", ".GXXXXXXG.", ".GXXXXXXG.", "..GXXXXG..", "...GXXG...", "....GG....", "..........", ".........."],
		"round": ["...GGGG...", "..GXXXXG..", ".GXXXXXXG.", ".GXXXXXXG.", ".GXXXXXXG.", ".GXXXXXXG.", "..GXXXXG..", "...GGGG...", "..........", ".........."],
		"kite": ["..GGGGGG..", ".GXXXXXXG.", ".GXXXXXXG.", ".GXXXXXXG.", "..GXXXXG..", "..GXXXXG..", "...GXXG...", "...GXXG...", "....GG....", ".........."],
		"tower": ["..GGGGGG..", ".GXXXXXXG.", ".GXXXXXXG.", ".GXXXXXXG.", ".GXXXXXXG.", ".GXXXXXXG.", ".GXXXXXXG.", ".GXXXXXXG.", ".GGGGGGGG.", ".........."],
		"buckler": ["..........", "...GGGG...", "..GXXXXG..", ".GXXXXXXG.", ".GXXXXXXG.", ".GXXXXXXG.", "..GXXXXG..", "...GGGG...", "..........", ".........."],
	}
	var shape: String = pick(base, 18, ["heater", "round", "kite", "tower", "buckler"])
	if base.contains("tank") or base.contains("titan") or base.contains("hard"):
		shape = "tower"
	elif base.contains("faceguard"):
		shape = "heater"
	elif base.contains("wooden") or base.contains("leather"):
		shape = "round"
	cv.stamp(shapes[shape])
	# the emblem
	var em: String = pick(base, 19, ["boss", "cross", "stripe", "chevron", "plain", "star"])
	if base.contains("sword_shield"):
		em = "sword"
	elif base.contains("axe_shield"):
		em = "axe"
	elif base.contains("skull"):
		em = "skull"
	elif base.contains("faceguard"):
		em = "face"
	elif base.contains("moonclipse"):
		em = "moon"
	elif base.contains("firey") or base.contains("lava") or base.contains("volcan"):
		em = "flame"
	elif base.contains("fluorescent") or base.contains("phase"):
		em = "glow"
	elif base.contains("x_shield"):
		em = "x"
	elif base.contains("wooden"):
		em = "planks"
	var cy := 3 if shape != "buckler" else 4
	match em:
		"boss": cv.stamp(["GG", "Gw"], 4, cy)
		"cross":
			cv.r(4, 1, 2, 6 if shape != "buckler" else 5, "a")
			cv.r(2, cy, 6, 1, "a")
		"stripe":
			for i in 7:
				if cv.at(2 + i, 1 + i) == "X":
					cv.p(2 + i, 1 + i, "a")
		"chevron": cv.pts([[2, 3], [3, 4], [4, 5], [5, 5], [6, 4], [7, 3]], "a")
		"star": cv.pts([[4, 2], [5, 2], [3, 3], [4, 3], [5, 3], [6, 3], [4, 4], [5, 4]], "a")
		"sword":
			for r in range(1, 7):
				cv.p(8 - r, r, "w")
			cv.pts([[2, 5], [4, 7]], "G")
		"axe": cv.stamp([".ww.", "www.", ".ww.", "..h.", "..h."], 3, 1)
		"skull": cv.stamp(["www.", "kwk.", ".w.."], 3, 2)
		"face": cv.stamp(["kk.kk", "....."], 2, 3)
		"moon": cv.stamp([".yy.", "y...", "y...", ".yy."], 3, 2)
		"flame": cv.stamp(["..y..", ".yoy.", ".oRo.", "..o.."], 3, 2)
		"glow":
			for y in N:
				for x in N:
					if cv.at(x, y) == "G":
						cv.p(x, y, "a")
			map.a = {"red": "f06a5a", "blue": "6bc8f0", "pink": "f08ac8", "green": "7cf06a", "yellow": "f2e05a"}.get(base.get_slice("_", 0), "a77ee0")
			cv.stamp(["ww", "w."], 3, 2)
		"x": cv.pts([[2, 1], [3, 2], [4, 3], [5, 4], [6, 5], [7, 1], [6, 2], [5, 3], [3, 5], [2, 6], [7, 6]], "a")
		"planks":
			for y in range(1, 8):
				if cv.at(4, y) == "X":
					cv.p(4, y, "x")
	map.o = "ea8a33"
	map.R = "d8433a"
	map.k = "1b1a24"
	cv.anchors = {"gem": [4, 1], "pom": [5, 6], "rune": [2, 2], "spark": [9, 1], "spark2": [0, 8]}

# ---------------------------------------------------------------- rings
static func _ring(cv: Cv, id: String, base: String, map: Dictionary) -> void:
	var gold := not (base.contains("silver") or base.contains("armor") or base.contains("modina"))
	map.G = "f2cf5b" if gold else "c8ced6"
	map.g = "c99a2e" if gold else "7a8290"
	if base.contains("modina"):
		map.G = "ea8a33"
		map.g = "8a4a1a"
	cv.stamp(["..........", "..........", "..........", "...GggG...", "..G.....g.", ".G.......g", ".G.......g", "..g.....g.", "...gggg...", ".........."], 0, 0)
	# the stone
	var stone: String = "gem"
	var sc := {"X": mc_of(base), "x": ""}
	if base.contains("heart"):
		stone = "heart"
	elif base.contains("mana"):
		stone = "drop"
	elif base.contains("muscle") or base.contains("fire"):
		stone = "flame"
	elif base.contains("shattered"):
		stone = "burst"
	elif base.contains("skull"):
		stone = "skull"
	elif base.contains("orb"):
		stone = "orb"
	elif base.contains("armor"):
		stone = "shield"
	elif base.contains("attack"):
		stone = "sword"
	elif base.contains("magic"):
		stone = "star"
	elif base.contains("jade") or base.contains("ruby") or base.contains("modina"):
		stone = "square"
	match stone:
		"gem": cv.stamp(["..XXX...", ".XwXXx..", "..Xxx..."], 1, 1)
		"square": cv.stamp(["...XXX..", "...XwX..", "...XXx.."], 0, 1)
		"heart": cv.stamp(["..X.X...", ".XwXXx..", "..XXx...", "...x...."], 1, 0)
		"drop": cv.stamp(["...X....", "..XwX...", "..XXx...", "...x...."], 1, 0)
		"flame": cv.stamp(["...y....", "..yXy...", "..XRX...", "...X...."], 1, 0)
		"burst": cv.stamp(["..X.X...", "...X....", "..XwX...", "...X...."], 1, 0)
		"skull": cv.stamp(["..www...", "..kwk...", "...w...."], 1, 1)
		"orb": cv.stamp(["..XXX...", ".XwXXX..", ".XXXXx..", "..xxx..."], 1, 0)
		"shield": cv.stamp(["..XXXX..", "..XwXx..", "...Xx..."], 1, 1)
		"sword": cv.stamp([".....w..", "....w...", "...w....", "..G....."], 1, 0)
		"star": cv.stamp(["...X....", "..XwX...", "...X...."], 1, 1)
	map.X = sc.X[0]
	map.x = sc.X[1]
	map.R = "d8433a"
	map.k = "1b1a24"
	cv.anchors = {"gem": [1, 5], "pom": [8, 5], "rune": [4, 8], "spark": [8, 1], "spark2": [1, 1]}

static func mc_of(base: String) -> Array:
	var stones := {"heartstone": ["d8433a", "8a1e1a"], "manastone": ["3b6fd9", "1e2a6a"], "muscle_fire": ["ea6a33", "8a1e1a"],
		"shattered": ["a77ee0", "3a2a5a"], "jade": ["5cbf8a", "2e8a5a"], "ruby": ["d8433a", "8a1e1a"], "orb": ["6bc8f0", "2c7ab0"],
		"skull": ["f2ecd8", "a89878"], "armor": ["9aa2ad", "5c616b"], "attack": ["d8433a", "8a1e1a"], "magic": ["a77ee0", "5a3a8a"],
		"modina": ["ea8a33", "8a4a1a"], "silver": ["e3ebf5", "9fb0c8"], "gold": ["f2cf5b", "c99a2e"]}
	for k in stones:
		if base.contains(k):
			return stones[k]
	return ["6bc8f0", "2c7ab0"]
