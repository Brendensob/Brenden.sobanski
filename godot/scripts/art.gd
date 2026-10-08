extends Node
## All the pixel art, made in code: villagers from text grids, monsters and
## scenery from simple shapes, and item icons from templates coloured by material.
## Every sprite gets a dark outline added automatically.

const OUTLINE := Color("1b1a24")
var _cache := {}
var font_body: FontFile
var font_title: FontFile

const PAL := {
	"k": "1b1a24", "w": "f2efe6", "s": "f2c29a", "S": "d49a72", "b": "3a2a22",
	"r": "d8433a", "R": "f06a5a", "y": "f2cf5b", "Y": "c99a2e", "o": "ea8a33", "O": "b85e1c",
	"g": "5cbf3f", "G": "3e8a2e", "n": "8a5a32", "N": "6e4426", "l": "a8703f",
	"a": "9aa2ad", "A": "c8ced6", "d": "5c616b", "D": "3e424a",
	"i": "b8c4d6", "I": "e3ebf5", "u": "3b5dc9", "U": "6b8ff0", "p": "7b4fb8", "P": "a77ee0",
	"c": "4fb6d0", "C": "a6e6f2", "m": "e06a9a", "z": "8fb07a", "Z": "5e7a52",
}

# ---------------------------------------------------------------- characters
# Chibi people: a big head with two dot eyes, a small body and stubby legs.
# Channels: h/H hair, s/S skin, e eyes, c/C clothes, v collar, t tie or trim,
# j lower body (skirt or belt), q legs, f shoes. Missing channels fall back.
const PAD := 4 # empty rows above the head for hats
const HAIR := {
	"short": [
		"...hhhhhh...",
		"..hhhhhhhhh.",
		".hhhhhhhhhhh",
		".hhhhsssshh.",
		".hhsssesses.",
		".hhsssesseS.",
		"..hssssssss.",
		"...SSssssS..",
	],
	"bald": [
		"...ssssss...",
		"..sssssssss.",
		".sssssssssss",
		".sssssssssS.",
		".SssssesseS.",
		".SssssesseS.",
		"..Sssssssss.",
		"...SSssssS..",
	],
}
const BODY := [
	"...cvtvcc...",
	"..cccCtCcc..",
	"..sccCtCcs..",
	"...cccccc...",
	"...jjjjjj...",
]
const LEGS := {
	"stand": ["...qq..qq...", "...qq..qq...", "...ff..ff..."],
	"walk": ["..qq....qq..", "..qq....qq..", "..ff....ff.."],
	"jump": ["...qq..qq...", "..ff....ff..", "............"],
}
# over: extra pixels drawn on top, as [x, y, rows] with y counted from the top
# of the hat space (the head starts at y = PAD).
const LOOKS := {
	# playable characters
	"man_in_suit": {"h": "2a2230", "H": "1b1a24", "c": "2e3242", "C": "1e2030", "v": "f2efe6", "t": "d8433a", "q": "2e3242", "f": "1b1a24"},
	"nurse": {"h": "a0663a", "H": "6e4426", "long": true, "c": "f2efe6", "C": "d8d0c0", "v": "f2efe6", "t": "f2efe6", "j": "f2efe6", "q": "f2c29a", "f": "f2efe6",
		"over": [[3, 1, [".wwwww.", "wwwrwww", "wwrrrww", ".wwrww."]]]},
	"cavemun": {"h": "6a4220", "H": "4a2e14", "s": "e2a070", "S": "b87a4e", "c": "ea8a33", "C": "8a4a1a", "v": "e2a070", "t": "ea8a33", "j": "ea8a33", "q": "e2a070", "f": "8a5a32",
		"over": [[1, 2, ["..h..h..h...", ".hhhhhhhhhh."]], [10, 10, ["N"]], [10, 11, ["w"]]]},
	"pirate": {"h": "1b1a24", "H": "1b1a24", "c": "f2efe6", "C": "d8433a", "v": "f2efe6", "t": "d8433a", "q": "2e3242", "f": "6e4426",
		"over": [[1, 3, ["..rrrrrr....", ".rrRrrrrrr..", "rrrrrrrrrrr."]], [0, 6, ["rr"]], [0, 7, [".r"]], [3, 7, ["kkkkk"]], [8, 8, ["kk"]], [8, 9, ["kk"]]]},
	"the_spi": {"h": "1b1a24", "H": "3a3a48", "c": "1b1a24", "C": "2e3242", "v": "f2efe6", "t": "1b1a24", "q": "1b1a24", "f": "1b1a24",
		"over": [[4, 8, ["kkkkkkk"]], [5, 9, ["kUk.kUk"]]]},
	"bad_man": {"h": "2a2a30", "H": "1b1a24", "s": "3a3a44", "S": "2a2a30", "c": "4a4a5a", "C": "2a2a30", "v": "4a4a5a", "t": "2a2a30", "q": "2a2a30", "f": "1b1a24", "hair": "bald",
		"over": [[5, 8, ["wkwwkw"]], [5, 9, ["wkwwkw"]]]},
	"school_girl": {"h": "1b1a24", "H": "2a2230", "long": true, "c": "f2efe6", "C": "d8d0c0", "v": "3b5dc9", "t": "d8433a", "j": "3b5dc9", "q": "f2c29a", "f": "1b1a24"},
	"soldier": {"h": "5a3a20", "H": "3a2614", "c": "6a8a4a", "C": "4a6a2a", "v": "6a8a4a", "t": "4a6a2a", "j": "3a2a22", "q": "4a6a2a", "f": "3a2a22",
		"over": [[2, 2, ["..ZZZZZZ..", ".ZzZZZZZZZ.", "ZZZZZzZZZZZ", "ZZZZZZZZZZZ", "zzzzzzzzzzz"]]]},
	"chuchu": {"h": "f08ac8", "H": "c05a98", "long": true, "c": "f06aa0", "C": "c84a80", "v": "f2efe6", "t": "f2efe6", "j": "f06aa0", "q": "f2c29a", "f": "f2efe6",
		"over": [[1, 1, [".hh......hh.", "hhHh....hHhh", ".hh......hh."]]]},
	"drone": {"h": "5c616b", "H": "3e424a", "s": "a8b0bc", "S": "7a8290", "e": "4fd0f0", "c": "7a8290", "C": "5c616b", "v": "a8b0bc", "t": "4fd0f0", "q": "5c616b", "f": "3e424a", "hair": "bald",
		"over": [[6, 0, ["A", "a", "a"]], [4, 3, ["aaaaa"]], [5, 8, ["cCCCCc"]], [5, 9, ["cCCCCc"]], [6, 8, ["C"]]]},
	"dark_knight": {"h": "3a2a5a", "H": "2a1e40", "s": "4a3a6a", "S": "2a1e40", "e": "d8433a", "c": "4a3a6a", "C": "2a1e40", "v": "7b4fb8", "t": "7b4fb8", "j": "2a1e40", "q": "2a1e40", "f": "1b1a24", "hair": "bald",
		"over": [[3, 0, [".rr.", "rRr.", "rr..", "PPPPPPPP"]], [2, 7, ["PPPPPPPPPP"]], [5, 8, ["kekkek"]], [5, 9, ["kekkek"]]]},
	# villagers
	"keeper": {"h": "3a2a5a", "H": "2a1e40", "c": "7b4fb8", "C": "5a3a8a", "q": "3a2a5a", "f": "1b1a24", "s": "e8b48a", "t": "f2cf5b",
		"over": [[2, 1, ["...PPPP...", "..PPyPPP..", ".PPPPPPPP."]]]},
	"gruff": {"h": "6a4a2a", "H": "4a3218", "c": "6e5a3e", "C": "4a3e2a", "q": "4a3a2a", "f": "2a2230", "s": "d49a72", "j": "3a2a22",
		"over": [[6, 10, ["HHHHH"]], [7, 11, ["HHH"]]]},
	"mira": {"h": "f06aa0", "H": "c84a80", "long": true, "c": "f2efe6", "C": "d8d0c0", "t": "f06aa0", "j": "e06a9a", "q": "f2c29a", "f": "3a2a22",
		"over": [[8, 3, ["yy", "y."]]]},
	"warden": {"h": "2a2a2a", "H": "1b1a24", "s": "8fc07a", "S": "6a9a5a", "c": "4a4a5a", "C": "3a3a48", "q": "3a3a48", "f": "1b1a24"},
	"smith": {"h": "3a2a22", "H": "2a1e18", "c": "7a5a3a", "C": "5a4028", "q": "4a3428", "f": "2a2230", "s": "c88a5a", "v": "a07a55", "t": "a07a55"},
	"merchant": {"h": "d8433a", "H": "a82a22", "c": "3b5dc9", "C": "2c4596", "q": "4a3a2a", "f": "2a2230", "t": "f2cf5b"},
	"tools": {"h": "3b5dc9", "H": "2c4596", "c": "d8433a", "C": "a82a22", "v": "3b5dc9", "t": "3b5dc9", "j": "3b5dc9", "q": "3b5dc9", "f": "6e4426", "s": "f2c29a",
		"over": [[6, 10, ["bbbb"]]]},
	"miner": {"h": "f2cf5b", "H": "c99a2e", "c": "6e5a3e", "C": "4a3e2a", "q": "4a4a5a", "f": "2a2230"},
	"jumpie": {"h": "a0663a", "H": "6e4426", "c": "5cbf3f", "C": "3e8a2e", "t": "f2cf5b", "q": "3b5dc9", "f": "d8433a",
		"over": [[2, 0, ["...aAAa....", "....n......", "..ggggg....", ".gggggggg..", "gggGggggggg"]]]},
	# monsters that are drawn as people
	"zombie": {"h": "3a3a2a", "H": "2a2a1e", "s": "8fb07a", "S": "5e7a52", "c": "6e5a3e", "C": "4a3e2a", "q": "3e4a5a", "f": "2a2230", "e": "d8433a"},
	"wizard": {"h": "3b5dc9", "H": "2c4596", "s": "e8c8a8", "S": "c8a888", "c": "3b5dc9", "C": "6b8ff0", "q": "3b5dc9", "f": "2c4596", "e": "f2cf5b"},
	"mummy": {"h": "e8e0c8", "H": "b8b098", "s": "e8e0c8", "S": "b8b098", "c": "e8e0c8", "C": "b8b098", "q": "e8e0c8", "f": "b8b098", "e": "d8433a"},
}
# Character hats show the matching character's headwear when worn.
const HAT_LOOKS := {"pirate_hat": "pirate", "soldier_helmet": "soldier", "spy_mask": "the_spi", "chuu_hat": "chuchu",
	"trooper_pro": "drone", "dark_night": "dark_knight", "bad_mask": "bad_man"}

func _ready() -> void:
	font_body = load("res://fonts/PixelifySans.ttf")
	font_title = load("res://fonts/Silkscreen-Regular.ttf")
	font_title.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font_title.hinting = TextServer.HINTING_NONE
	font_title.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font_body.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	font_body.hinting = TextServer.HINTING_LIGHT

# ---------------------------------------------------------------- helpers
func col(v) -> Color:
	return v if v is Color else Color(String(v))

func grid_image(rows: Array, map: Dictionary = {}, scale: int = 1) -> Image:
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var img := Image.create(w * scale, rows.size() * scale, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			var c
			if map.has(ch):
				c = col(map[ch])
			elif PAL.has(ch):
				c = col(PAL[ch])
			else:
				continue
			img.fill_rect(Rect2i(x * scale, y * scale, scale, scale), c)
	return img

func outline(src: Image, color: Color = OUTLINE) -> Image:
	var w := src.get_width() + 2
	var h := src.get_height() + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.blit_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(1, 1))
	var out := img.duplicate()
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.5:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var px2: int = x + d.x
				var py2: int = y + d.y
				if px2 >= 0 and py2 >= 0 and px2 < w and py2 < h and img.get_pixel(px2, py2).a > 0.5:
					out.set_pixel(x, y, color)
					break
	return out

func flash_image(src: Image) -> Image:
	var img := src.duplicate()
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				img.set_pixel(x, y, Color.WHITE)
	return img

func to_tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)

func cached(key: String, maker: Callable) -> Texture2D:
	if not _cache.has(key):
		_cache[key] = maker.call()
	return _cache[key]

func blank(w: int, h: int) -> Image:
	return Image.create(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)

func px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)

func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / maxf(rx, 0.1)
			var dy := (y + 0.5 - cy) / maxf(ry, 0.1)
			if dx * dx + dy * dy <= 1.0:
				px(img, x, y, c)

func eyes(img: Image, x1: int, x2: int, y: int, size: int = 1, c: Color = OUTLINE) -> void:
	rect(img, x1, y, size, size + 1, c)
	rect(img, x2, y, size, size + 1, c)

# ---------------------------------------------------------------- characters
## A person sprite. helmet and armor are item ids, drawn over the character.
func character(look: String, frame: String = "stand", scale: int = 1, helmet: String = "", armor: String = "") -> Texture2D:
	return cached("char_%s_%s_%d_%s_%s" % [look, frame, scale, helmet, armor], func():
		return to_tex(outline(_char_img(look, frame, scale, helmet, armor))))

func character_flash(look: String) -> Texture2D:
	return cached("charflash_" + look, func():
		return to_tex(flash_image(outline(_char_img(look, "stand", 1)))))

func _char_map(look: String, armor: String) -> Dictionary:
	var d: Dictionary = LOOKS.get(look, LOOKS.man_in_suit)
	var map := {}
	for k in d:
		if d[k] is String:
			map[k] = d[k]
	if not map.has("e"): map.e = "1b1a24"
	if not map.has("t"): map.t = map.get("c", "4a4a5a")
	if not map.has("v"): map.v = map.get("c", "4a4a5a")
	if not map.has("j"): map.j = map.get("q", "3a3a52")
	if armor != "":
		var mc := material_colors(armor)
		map.c = mc.X
		map.C = mc.x
		map.v = mc.X
		map.t = mc.x
	return map

func _overlay(img: Image, parts: Array, map: Dictionary) -> void:
	for o in parts:
		var g := grid_image(o[2], map)
		img.blend_rect(g, Rect2i(0, 0, g.get_width(), g.get_height()), Vector2i(o[0], o[1]))

func _char_img(look: String, frame: String, scale: int, helmet: String = "", armor: String = "") -> Image:
	var d: Dictionary = LOOKS.get(look, LOOKS.man_in_suit)
	var map := _char_map(look, armor)
	var base := grid_image(HAIR[d.get("hair", "short")] + BODY + LEGS[frame], map)
	if d.get("long", false):
		for y in range(6, 11):
			for x in [1, 2]:
				if base.get_pixel(x, y).a < 0.5 and (x == 1 or y < 9):
					base.set_pixel(x, y, col(map.h))
	if look == "mummy":
		var clean := base.duplicate()
		for y in range(0, base.get_height(), 3):
			rect(base, 0, y, base.get_width(), 1, Color("b8b098"))
		for y in base.get_height():
			for x in base.get_width():
				if clean.get_pixel(x, y).a < 0.5:
					base.set_pixel(x, y, Color(0, 0, 0, 0))
		px(base, 6, 4, Color("d8433a"))
		px(base, 9, 4, Color("d8433a"))
	var img := blank(base.get_width(), base.get_height() + PAD)
	img.blit_rect(base, Rect2i(0, 0, base.get_width(), base.get_height()), Vector2i(0, PAD))
	_overlay(img, d.get("over", []), map)
	match look:
		"wizard":
			var c := Color("2c4596")
			for i in 5:
				rect(img, 6 - (i + 1) / 2, i, 1 + i, 1, c)
			rect(img, 0, 4, 12, 2, c)
			px(img, 6, 1, Color("f2cf5b"))
		"miner":
			rect(img, 2, 3, 9, 3, Color("f2cf5b"))
			rect(img, 8, 4, 2, 2, Color("f2efe6"))
		"merchant", "tools":
			rect(img, 1, 3, 10, 3, col(map.h))
			rect(img, 7, 5, 5, 1, col(map.H))
		"warden":
			rect(img, 2, 3, 9, 2, Color("2a2a2a"))
			px(img, 1, 10, Color("a8a8b0"))
			px(img, 10, 10, Color("a8a8b0"))
	if helmet != "":
		_draw_helmet(img, helmet)
	if scale > 1:
		img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	return img

func _draw_helmet(img: Image, helmet: String) -> void:
	if HAT_LOOKS.has(helmet):
		var hl: String = HAT_LOOKS[helmet]
		_overlay(img, LOOKS[hl].get("over", []), _char_map(hl, ""))
		return
	var mc := material_colors(helmet)
	var map := {"X": mc.X, "x": mc.x}
	match helmet:
		"bear_head":
			_overlay(img, [[1, 1, [".nn.....nn..", "nNNnnnnnNNn.", "nnnnnnnnnnnn", "nnnnnnnnnnnn", "nnn.......nn"]]], {"n": "8a5a32", "N": "c8a070"})
		"green_face":
			_overlay(img, [[2, 6, ["ggggggggg", "gggkggkgg", "gggkggkgg", "ggggggggg", ".gggGGgg."]]], {"g": "5cbf3f", "G": "2e7a2a"})
		"the_fly":
			_overlay(img, [[2, 4, ["..kkkkkk...", ".kkkkkkkkk.", "kkcCkkkcCk.", "kkCCkkkCCk."]]], {"c": "a6e6f2", "C": "4fb6d0"})
		"wood_mask", "skull_mask":
			var m: Dictionary = {"X": "a8703f", "x": "6e4426"} if helmet == "wood_mask" else {"X": "f2ecd8", "x": "a89878"}
			_overlay(img, [[4, 6, [".XXXXXX", "XXkXXkX", "XXkXXkX", "XXXXXXX", ".XxxxX."]]], m)
		"cool_hat", "roman_hat", "storm_hat":
			var c3: Array = {"cool_hat": ["1b1a24", "3a3a48"], "roman_hat": ["f2cf5b", "d8433a"], "storm_hat": ["6b8ff0", "2c4596"]}[helmet]
			_overlay(img, [[1, 2, ["...XXXXXX...", "..XXXXXXXX..", "..XxxxxxxX..", "XXXXXXXXXXXX"]]], {"X": c3[0], "x": c3[1]})
		_:
			if helmet.contains("hat") or helmet.contains("witch") or helmet.contains("hood"):
				_overlay(img, [[1, 1, ["....XXXX....", "...XXXXXX...", "...XwXXXX...", "XXXXXXXXXXXX", ".xxxxxxxxxx."]]], map)
			else:
				_overlay(img, [[1, 2, ["...XXXXXX...", "..XXwXXXXXX.", ".XXXXXXXXXXX", ".XXxxxxxxxx.", ".Xx.........", ".Xx........."]]], map)

# ---------------------------------------------------------------- monster shapes
func blob(body: Color, w: int, h: int, squash: bool, face := true) -> Image:
	var hh := h - 2 if squash else h
	var ww := w + 2 if squash else w
	var img := blank(ww, hh)
	ellipse(img, ww / 2.0, hh * 0.62, ww / 2.0, hh * 0.62, body)
	rect(img, 1, hh - 2, ww - 2, 2, body.darkened(0.3))
	ellipse(img, ww * 0.32, hh * 0.38, ww * 0.12, hh * 0.12, body.lightened(0.4))
	if face:
		var s := 2 if ww > 20 else 1
		eyes(img, int(ww * 0.55), int(ww * 0.78), int(hh * 0.5), s)
	return img

func eye_img(r: int, iris: Color, lashes: bool, crown: bool, feet: bool, alt: bool) -> Image:
	var top := 7 if crown or lashes else 0
	var foot := 4 if feet else 0
	var img := blank(r * 2 + 4, r * 2 + top + foot + 2)
	var cx := r + 2.0
	var cy := r + top + 1.0
	ellipse(img, cx, cy, r, r, Color("f2efe6"))
	for i in 5:
		var a := i * 1.3
		rect(img, int(cx + cos(a) * r * 0.7), int(cy + sin(a) * r * 0.7), 2, 1, Color("e06a6a"))
	var look := 2.0 if alt else 0.0
	ellipse(img, cx + r * 0.25 + look, cy, r * 0.45, r * 0.5, iris)
	ellipse(img, cx + r * 0.32 + look, cy, r * 0.22, r * 0.28, OUTLINE)
	px(img, int(cx + r * 0.15), int(cy - r * 0.25), Color.WHITE)
	if lashes:
		var gold := Color("f2cf5b")
		for i in 7:
			var a := PI + 0.2 + i * (PI - 0.4) / 6.0
			for k in range(r + 1, r + 6):
				px(img, int(cx + cos(a) * k), int(cy + sin(a) * k), gold)
	if crown:
		var gold2 := Color("f2cf5b")
		rect(img, int(cx) - 6, top - 3, 13, 3, gold2)
		for i in 3:
			rect(img, int(cx) - 6 + i * 5, top - 6, 3, 3, gold2)
		px(img, int(cx), top - 2, Color("d8433a"))
	if feet:
		var y := int(cy + r) + 1
		var off := 1 if alt else 0
		rect(img, int(cx - r * 0.5) - off, y, 3, 3, Color("c8a888"))
		rect(img, int(cx + r * 0.3) + off, y, 3, 3, Color("c8a888"))
	return img

func ghost_img(w: int, h: int, body: Color, eye: Color, alt: bool, crown := false) -> Image:
	var top := 6 if crown else 0
	var img := blank(w, h + top)
	ellipse(img, w / 2.0, top + w / 2.0, w / 2.0, w / 2.0, body)
	rect(img, 0, top + w / 2, w, h - w / 2 - 3, body)
	var n := 4
	for i in n:
		var x := i * w / n
		var dip := 3 if (i % 2 == 0) != alt else 1
		rect(img, x, top + h - 3, w / n, 3 - dip + 1, body)
	ellipse(img, w * 0.3, top + w * 0.35, w * 0.08, w * 0.08, body.lightened(0.35))
	var es := maxi(1, w / 10)
	rect(img, int(w * 0.55), top + int(w * 0.45), es, es + 1, eye)
	rect(img, int(w * 0.78), top + int(w * 0.45), es, es + 1, eye)
	rect(img, int(w * 0.6), top + int(w * 0.7), int(w * 0.2), maxi(1, es), OUTLINE)
	if crown:
		var gold := Color("f2cf5b")
		rect(img, int(w / 2.0) - 7, top - 2, 15, 3, gold)
		for i in 4:
			rect(img, int(w / 2.0) - 7 + i * 4, top - 5, 2, 3, gold)
	return img

func wings_img(w: int, h: int, wing: Color, body: Color, alt: bool, spots := Color(0, 0, 0, 0)) -> Image:
	var img := blank(w, h)
	var cx := w / 2.0
	var lift := -2.0 if alt else 0.0
	for side in [-1, 1]:
		ellipse(img, cx + side * w * 0.26, h * 0.35 + lift, w * 0.24, h * 0.3, wing)
		ellipse(img, cx + side * w * 0.2, h * 0.7, w * 0.16, h * 0.22, wing.darkened(0.15))
		if spots.a > 0:
			ellipse(img, cx + side * w * 0.28, h * 0.32 + lift, w * 0.07, h * 0.08, spots)
	rect(img, int(cx) - 1, int(h * 0.15), 3, int(h * 0.75), body)
	px(img, int(cx) - 2, int(h * 0.1), body)
	px(img, int(cx) + 2, int(h * 0.1), body)
	return img

func bat_img(w: int, h: int, c: Color, alt: bool) -> Image:
	var img := blank(w, h)
	var cx := w / 2.0
	ellipse(img, cx, h * 0.45, w * 0.13, h * 0.35, c)
	for side in [-1, 1]:
		for i in int(w * 0.38):
			var x := int(cx + side * (w * 0.1 + i))
			var y0 := int(h * 0.2 + (i * 0.25 if alt else -i * 0.1) + h * 0.15)
			rect(img, x, y0, 1, maxi(1, int(h * 0.45) - absi(i % 4 - 2)), c.darkened(0.1))
	px(img, int(cx) - 2, int(h * 0.4), Color("d8433a"))
	px(img, int(cx) + 1, int(h * 0.4), Color("d8433a"))
	rect(img, int(cx) - 2, int(h * 0.1), 1, 2, c)
	rect(img, int(cx) + 1, int(h * 0.1), 1, 2, c)
	return img

func flame_img(c: Color, alt: bool) -> Image:
	var img := blank(12, 15)
	ellipse(img, 6, 10, 5, 5, c)
	for i in 6:
		rect(img, 3 + i / 2 + (1 if alt else 0), 2 + i, 6 - i, 1, c)
	ellipse(img, 6, 11, 3, 3, c.lightened(0.5))
	eyes(img, 5, 8, 9)
	return img

func trex_img(body: Color, belly: Color, alt: bool, spikes := false) -> Image:
	var img := blank(26, 20)
	ellipse(img, 11, 11, 8, 5, body)
	for i in 8:
		rect(img, 2 - i / 4, 9 + i / 3, 6, 2, body)
	rect(img, 15, 2, 9, 7, body)
	rect(img, 17, 7, 7, 2, body.darkened(0.25))
	for i in 3:
		px(img, 18 + i * 2, 7, Color.WHITE)
	px(img, 20, 4, OUTLINE)
	rect(img, 9, 12, 6, 3, belly)
	rect(img, 17, 10, 3, 1, body.darkened(0.2))
	var l := 1 if alt else 0
	rect(img, 8 - l, 15, 3, 5, body.darkened(0.15))
	rect(img, 13 + l, 15, 3, 5, body.darkened(0.15))
	if spikes:
		for i in 4:
			px(img, 8 + i * 3, 5, Color("e8dccb"))
			px(img, 15 + i * 2, 1, Color("e8dccb"))
	return img

func hand_img(c: Color, alt: bool) -> Image:
	var img := blank(22, 24)
	rect(img, 3, 11, 15, 11, c)
	for i in 4:
		var h := 9 + (i % 2) * 2 + (1 if alt and i == 1 else 0)
		rect(img, 3 + i * 4, 11 - h + 1, 3, h, c)
		rect(img, 3 + i * 4, 11 - h + 1, 3, 1, c.lightened(0.3))
	rect(img, 17, 13, 4, 3, c)
	rect(img, 19, 9, 3, 6, c)
	rect(img, 4, 21, 13, 2, c.darkened(0.3))
	rect(img, 5, 15, 9, 1, c.darkened(0.2))
	return img

func bug_img(w: int, h: int, shell: Color, legs: Color, alt: bool, horn := false) -> Image:
	var img := blank(w, h)
	ellipse(img, w * 0.45, h * 0.45, w * 0.4, h * 0.35, shell)
	ellipse(img, w * 0.35, h * 0.3, w * 0.15, h * 0.1, shell.lightened(0.35))
	ellipse(img, w * 0.85, h * 0.5, w * 0.14, h * 0.2, legs)
	px(img, int(w * 0.9), int(h * 0.45), OUTLINE)
	for i in 3:
		var x := int(w * 0.2 + i * w * 0.22)
		var off := 1 if (i % 2 == 0) == alt else 0
		rect(img, x + off, int(h * 0.72), 1, int(h * 0.28), legs)
	if horn:
		for i in 4:
			px(img, int(w * 0.9) + i / 2, int(h * 0.3) - i, Color("e8dccb"))
	return img

func octo_img(c: Color, alt: bool) -> Image:
	var img := blank(16, 16)
	ellipse(img, 8, 6, 7, 6, c)
	ellipse(img, 5, 4, 2, 2, c.lightened(0.35))
	eyes(img, 8, 11, 6)
	for i in 4:
		var x := 2 + i * 3
		var wig := 1 if (i % 2 == 0) == alt else -1
		rect(img, x, 11, 2, 3, c)
		rect(img, x + wig, 14, 2, 2, c.darkened(0.2))
	return img

func worm_img(c: Color, alt: bool) -> Image:
	var img := blank(28, 11)
	for i in 6:
		var y := 6.0 + sin(i * 1.1 + (1.5 if alt else 0.0)) * 1.5
		ellipse(img, 3 + i * 4.3, y, 3.2, 3.5, c if i % 2 == 0 else c.darkened(0.15))
	ellipse(img, 25, 5, 3.5, 4, c.lightened(0.15))
	eyes(img, 25, 27, 3)
	rect(img, 25, 7, 3, 1, Color("d8433a"))
	return img

func ufo_img(alt: bool) -> Image:
	var img := blank(18, 12)
	ellipse(img, 9, 4, 4, 4, Color("a6e6f2"))
	ellipse(img, 9, 7, 9, 3, Color("9aa2ad"))
	rect(img, 2, 7, 14, 1, Color("5c616b"))
	for i in 4:
		px(img, 3 + i * 4, 7, Color("f2cf5b") if (i % 2 == 0) == alt else Color("d8433a"))
	eyes(img, 8, 10, 3)
	return img

func cloud_img(alt: bool) -> Image:
	var img := blank(24, 16)
	var c := Color("c8ced6")
	for e in [[7, 9, 6, 5], [13, 6, 7, 6], [18, 9, 6, 5], [12, 11, 9, 4]]:
		ellipse(img, e[0], e[1], e[2], e[3], c)
	ellipse(img, 10, 5, 3, 2, Color.WHITE)
	eyes(img, 12, 16, 8)
	if alt:
		px(img, 8, 15, Color("6b8ff0"))
		px(img, 15, 15, Color("6b8ff0"))
	return img

func tornado_img(alt: bool) -> Image:
	var img := blank(20, 26)
	for y in 26:
		var w := 2 + int((26 - y) * 0.7)
		var shift := int(sin(y * 0.5 + (1.0 if alt else 0.0)) * 2)
		rect(img, 10 - w / 2 + shift, y, w, 1, Color("c8ced6") if (y / 3) % 2 == 0 else Color("9aa2ad"))
	eyes(img, 9, 13, 6)
	return img

func tidal_img(alt: bool) -> Image:
	var img := blank(22, 18)
	var c := Color("3b8fd8")
	ellipse(img, 11, 11, 10, 7, c)
	for i in 6:
		rect(img, 4 + i * 2, 4 - (i if i < 4 else 6 - i) + (1 if alt else 0), 3, 6, c)
	rect(img, 2, 14, 18, 2, Color("a6e6f2"))
	ellipse(img, 7, 8, 2, 2, c.lightened(0.4))
	eyes(img, 12, 16, 10)
	return img

func crusher_img() -> Image:
	var img := blank(18, 18)
	rect(img, 0, 0, 18, 18, Color("8a9099"))
	rect(img, 1, 1, 16, 2, Color("b8bec6"))
	rect(img, 0, 15, 18, 3, Color("5c616b"))
	rect(img, 3, 6, 4, 3, OUTLINE)
	rect(img, 11, 6, 4, 3, OUTLINE)
	rect(img, 2, 5, 5, 1, Color("3e424a"))
	rect(img, 11, 5, 5, 1, Color("3e424a"))
	rect(img, 5, 12, 8, 2, OUTLINE)
	return img

func chick_img(alt: bool) -> Image:
	var img := blank(10, 10)
	ellipse(img, 5, 6, 4.5, 4, Color("f2cf5b"))
	ellipse(img, 4, 4, 2, 2, Color("ffe89a"))
	px(img, 7, 4, OUTLINE)
	px(img, 9, 5, Color("ea8a33"))
	if alt:
		px(img, 1, 5, Color("c99a2e"))
	return img

func mob_tex(look: String, alt: bool, flash := false) -> Texture2D:
	return cached("mob_%s_%s_%s" % [look, alt, flash], func():
		var img: Image
		match look:
			"slime_pink": img = blob(Color("f06aa0"), 14, 11, alt)
			"slime_dark": img = blob(Color("7b4fb8"), 16, 12, alt)
			"small_stone": img = blob(Color("8a9099"), 16, 13, alt)
			"farmland": img = blob(Color("ea8a33"), 15, 13, alt)
			"golden_orb": img = blob(Color("f2cf5b"), 14, 14, false)
			"snowball": img = blob(Color("f2efe6"), 10, 9, alt)
			"waterball": img = blob(Color("4f8fe0"), 10, 9, alt)
			"fireball": img = blob(Color("ea6a33"), 10, 9, alt)
			"goldball": img = blob(Color("f2cf5b"), 10, 9, alt)
			"wisp": img = flame_img(Color("ea8a33"), alt)
			"mummy", "zombie", "wizard": img = _char_img(look, "walk" if alt else "stand", 1)
			"shell": img = bug_img(18, 12, Color("5aa0a8"), Color("3e6a70"), alt, true)
			"mantis": img = bug_img(16, 11, Color("3b6fd9"), Color("2c4596"), alt)
			"octopus": img = octo_img(Color("8a4ac8"), alt)
			"crusher": img = crusher_img()
			"trex": img = trex_img(Color("5cbf3f"), Color("c8e89a"), alt)
			"dark_trex": img = trex_img(Color("7a5a3a"), Color("c8a888"), alt, true)
			"ufo": img = ufo_img(alt)
			"worm": img = worm_img(Color("c8708a"), alt)
			"hand": img = hand_img(Color("e8b48a"), alt)
			"shadow": img = ghost_img(14, 16, Color("2a2240"), Color("d8433a"), alt)
			"phantom": img = ghost_img(14, 16, Color("ea8a33"), OUTLINE, alt)
			"ghost_1": img = ghost_img(16, 18, Color("e8eef2"), OUTLINE, alt)
			"ghost_2": img = ghost_img(20, 22, Color("a8c8b8"), Color("d8433a"), alt)
			"ghost_lord": img = ghost_img(40, 44, Color("d8d0f0"), Color("7b4fb8"), alt, true)
			"eyeball": img = eye_img(7, Color("d8433a"), false, false, true, alt)
			"king": img = eye_img(16, Color("5c616b"), false, true, true, alt)
			"queen": img = eye_img(17, Color("7b4fb8"), true, false, true, alt)
			"tornado": img = tornado_img(alt)
			"tidal": img = tidal_img(alt)
			"ice_bat": img = bat_img(20, 11, Color("a6e6f2"), alt)
			"bat": img = bat_img(22, 12, Color("4a3a5a"), alt)
			"cloud": img = cloud_img(alt)
			"butterfly": img = wings_img(18, 14, Color("e06a9a"), OUTLINE, alt, Color("f2cf5b"))
			"empress": img = wings_img(46, 36, Color("a77ee0"), Color("3a2a5a"), alt, Color("f2cf5b"))
			"chicklet": img = chick_img(alt)
			_: img = blob(Color("ff00ff"), 12, 10, alt)
		img = outline(img)
		if flash:
			img = flash_image(img)
		return to_tex(img))

# ---------------------------------------------------------------- item icons
const ICON_GRIDS := {
	"log": ["..........", "......nnn.", ".....nlln.", "....nlnn..", "...nlnn...", "..nlnn....", ".nlnn.....", ".nnl......", "..........", ".........."],
	"stick": ["..........", "........n.", ".......nl.", "......nl..", ".....nl...", "....nlg...", "...nl.....", "..nl......", ".nl.......", ".........."],
	"lump": ["..........", "..........", "...XXXX...", "..XxXXXX..", ".XXXXXxXX.", ".XxXXXXXx.", ".XXXXxXXx.", "..xxxxxx..", "..........", ".........."],
	"ore": ["..........", "..........", "...aaaa...", "..aXaaAa..", ".aaaaXaaa.", ".aXaaaaXa.", ".aaaXaaaD.", "..DDDDDD..", "..........", ".........."],
	"bar": ["..........", "..........", "..........", "....XXXXX.", "...XwXXXx.", "..XXXXXxx.", ".xxxxxxx..", "..........", "..........", ".........."],
	"blob": ["..........", "....X.....", "...XXx....", "..XXXXx...", ".XXwXXXx..", ".XXXXXXx..", ".XXXXXxx..", "..xxxxx...", "..........", ".........."],
	"crystal": ["....X.....", "...XwX....", "..XwXXx...", "..XXXXx...", "..XXXxx...", "..XXXxx...", "...Xxx....", "....x.....", "..........", ".........."],
	"gem": ["..........", "..XXXXX...", ".XwXXXXx..", "XwXXXXXXx.", ".XXXXXXx..", "..XXXXx...", "...XXx....", "....x.....", "..........", ".........."],
	"bug": ["..........", "...k..k...", "....kk....", "...XwwX...", "..XwXXwX..", "..XXxxXX..", "..XXXXXX..", "...k..k...", "..........", ".........."],
	"leaf": ["..........", "....g.....", "...gGg....", "..g.G.g...", ".gG.G.Gg..", "..g.G.g...", "....G.....", "....G.....", "..........", ".........."],
	"flower": ["..........", "...X.X....", "..XXwXX...", "...XXX....", "....g.....", "..g.g.....", "...gg.....", "....g.....", "..........", ".........."],
	"root": ["..........", "....X.....", "...XXx....", "...Xx.....", "..X.x.X...", ".X..x..x..", "...x.x....", "..x...x...", "..........", ".........."],
	"bone": ["..........", ".ww.......", ".www......", "..www.....", "...www....", "....www...", ".....www..", "......ww..", "..........", ".........."],
	"hide": ["..........", ".XX....XX.", ".XxXXXXxX.", "..XxxxxX..", "..XxxxxX..", "..XxxxxX..", ".XxXXXXxX.", ".XX....XX.", "..........", ".........."],
	"shell": ["..........", "..........", "...XXXX...", "..XxXxXX..", ".XXxXxXXX.", ".XxXxXxXx.", "..xxxxxx..", "..........", "..........", ".........."],
	"horn": ["..........", "........X.", ".......Xx.", "......Xx..", ".....XXx..", "....XXx...", "...XXx....", "..XXx.....", "..........", ".........."],
	"board": ["..........", "..........", ".XXXXXXXX.", ".XxXXXXxX.", ".XXXXXXXX.", ".xxxxxxxx.", "..........", "..........", "..........", ".........."],
	"nail": ["..........", "...aaaa...", "....AA....", "....Aa....", "....Aa....", "....Aa....", "....Aa....", ".....a....", "..........", ".........."],
	"apple": ["....n.....", "....ng....", "..XXXXX...", ".XwXXXXx..", ".XXXXXXx..", ".XXXXXXx..", "..XXXxx...", "...xxx....", "..........", ".........."],
	"gadget": ["..........", "..aaaaa...", ".aXXXXXa..", ".aXwXXXa..", ".aXXXXXa..", ".aaaaaaa..", "..a...a...", "..........", "..........", ".........."],
	"potion": ["..........", "....nn....", "....AA....", "...AXXA...", "..AXwXXA..", "..AXXXXA..", "..AxxxxA..", "...AAAA...", "..........", ".........."],
	"food": ["..........", "..........", "...XXXX...", "..XwXXXX..", ".XXXXxXXX.", ".XXxXXXXX.", ".xxxxxxxx.", "..........", "..........", ".........."],
	"sword": [".........X", "........Xx", ".......Xx.", "......Xx..", ".....Xx...", ".k..Xx....", "..kXx.....", "..lk......", ".lk.k.....", "l........."],
	"long": [".........X", "........Xx", ".......Xx.", "......Xx..", ".....Xx...", "....Xx....", ".kkXx.....", "..lkk.....", ".lk.......", "l........."],
	"club": ["......XXX.", ".....XXXXx", ".....XXXxx", "....XXxxx.", "...nlx....", "...nl.....", "..nl......", "..nl......", ".nl.......", ".n........"],
	"mace": ["....X.X...", "...XXXXX..", "..XXwXXXX.", "...XXXXx..", "....Xxnl..", ".....nl...", "....nl....", "...nl.....", "..nl......", ".n........"],
	"spike": ["X...X...X.", ".X..X..X..", "..XXXXX...", "..XXwXX...", "..XXXXX...", "...xnx....", "....nl....", "...nl.....", "..nl......", ".n........"],
	"plunger": ["..XXXX....", ".XXXXXX...", "..xxxx....", "...nl.....", "...nl.....", "...nl.....", "...nl.....", "...nl.....", "...nl.....", ".........."],
	"staff": [".......XX.", "......XwX.", "......XXx.", "......n...", ".....nl...", "....nl....", "...nl.....", "..nl......", ".nl.......", ".n........"],
	"bow": ["....nn....", "...n..k...", "..n....k..", "..n.....k.", "..n.....k.", "..n....k..", "...n..k...", "....nn....", "..........", ".........."],
	"arrow": ["..........", "........aA", ".......a..", "......n...", ".....n....", "....n.....", "...n......", ".ww.......", ".w........", ".........."],
	"axe": ["....XXX...", "...XxXX...", "..nXxXX...", "..nlXX....", "..nl......", "..nl......", "..nl......", "..nl......", "..nl......", ".........."],
	"pole": ["...XXX....", "..XxXX....", ".nXxXX....", ".nlXX.....", ".nl.......", ".nl.......", ".nl.......", ".nl.......", ".nl.......", ".nl......."],
	"pick": ["..XXXXX...", ".Xx.n.xX..", "X...nl..X.", "....nl....", "....nl....", "....nl....", "....nl....", "....nl....", "..........", ".........."],
	"armor": ["..........", ".XX....XX.", ".XxXXXXxX.", "..XXXXXX..", "..XxXXxX..", "..XXXXXX..", "..XxxxxX..", "..........", "..........", ".........."],
	"helmet": ["..........", "...XXXX...", "..XwXXXX..", ".XXXXXXXX.", ".XXxxxxXX.", ".XX....XX.", ".Xx....xX.", "..........", "..........", ".........."],
	"hat": ["....X.....", "...XXX....", "...XwX....", "..XXXXX...", "..XXXXX...", "XXXXXXXXX.", ".xxxxxxx..", "..........", "..........", ".........."],
	"shield": ["..........", ".XXXXXXXX.", ".XwXXXXxX.", ".XXXxXXxX.", ".XXXxXXxX.", "..XXxXxX..", "...XxxX...", "....XX....", "..........", ".........."],
	"ring": ["..........", "....X.....", "...XwX....", "..xxXxx...", ".x.....x..", ".x.....x..", ".x.....x..", "..xxxxx...", "..........", ".........."],
	"book": ["..........", ".XXXXXXX..", ".XwwwwwXw.", ".XXXyXXXw.", ".XXyyyXXw.", ".XXXyXXXw.", ".XXXXXXXw.", ".xxxxxxxw.", "..wwwwww..", ".........."],
	"scroll": ["..........", ".nwwwwwn..", "..wXXXw...", "..wwwww...", "..wXXXw...", "..wwwww...", ".nwwwwwn..", "..........", "..........", ".........."],
	"key": ["..........", "..XXX.....", ".X...X....", ".X...X....", "..XXXxxxxx", ".....x.x.x", ".......x.x", "..........", "..........", ".........."],
	"token": ["..........", "...XXXX...", "..XwXXXx..", ".XXxXXxXx.", ".XXXXXXXx.", ".XXxXXxXx.", "..XXXXxx..", "...xxxx...", "..........", ".........."],
	"seed": ["..........", "..........", "....X.....", "...XwX....", "...XXx..X.", "..X.xx.XwX", ".XwX....Xx", ".XXx......", "..x.......", ".........."],
	"egg": ["..........", "...ww.....", "..wXww....", ".wwwwXw...", ".wXwwww...", ".wwwXww...", "..wwww....", "..........", "..........", ".........."],
	"wall": ["nlnnlnnlnn", "NNNNNNNNNN", "lnnlnnlnnl", "NNNNNNNNNN", "nlnnlnnlnn", "NNNNNNNNNN", "lnnlnnlnnl", "NNNNNNNNNN", "nlnnlnnlnn", ".........."],
	"spikes": ["..........", "..........", "..........", ".A..A..A..", ".a..a..a..", "Aa.Aa.Aa..", "nnnnnnnnnn", "..........", "..........", ".........."],
	"station": ["..........", "nnnnnnnnnn", "llllllllll", ".n..aa..n.", ".n.aAAa.n.", ".n......n.", ".n......n.", ".n......n.", "..........", ".........."],
	"fire": ["..........", "....y.....", "...yoy....", "...oRo....", "..oRrRo...", ".nlnnlnl..", "nlnnlnnl..", "..........", "..........", ".........."],
	"fire2": ["..........", ".....y....", "....yoy...", "...yoRo...", "..oRrRo...", ".nlnnlnl..", "nlnnlnnl..", "..........", "..........", ".........."],
	"cannon": ["..........", "..........", "......kk..", ".XXXXXXXkk", "XwXXXXXXXk", "XXXXXXXXxk", ".xxxxxxkk.", "...nn.....", "..nNNn....", ".........."],
	"missile": ["..........", "......XX..", ".....XwXr.", "....XXXr..", "...XXXX...", "..XXXX....", ".rXXX.....", "rrr.......", ".r........", ".........."],
	"balls": ["..........", "..........", "...XX.....", "..XwXx....", "..XXxx.XX.", "...xx.XwXx", ".XX...XXxx", "XwXx...xx.", "XXxx......", ".xx......."],
	"mask": ["..........", "..XXXXXX..", ".XXXXXXXX.", ".XkkXXkkX.", ".XkkXXkkX.", ".XXXXXXXX.", "..XXxxXX..", "...XXXX...", "..........", ".........."],
	"torch_i": ["....y.....", "...yoy....", "...oRo....", "....o.....", "....l.....", "....n.....", "....n.....", "....n.....", "....n.....", ".........."],
}

const MATERIAL_COLORS := [
	["bear", "8a5a32", "5a3a1a"], ["pirate", "d8433a", "8a1e1a"], ["soldier", "6a8a4a", "4a6a2a"], ["spy", "3a3a48", "1b1a24"],
	["the_fly", "3a3a48", "1b1a24"], ["bad_mask", "3a3a44", "1b1a24"], ["chuu", "f08ac8", "c05a98"], ["trooper", "a8b0bc", "5c616b"],
	["green_face", "5cbf3f", "2e7a2a"], ["skull", "f2ecd8", "a89878"], ["cool", "3a3a48", "1b1a24"], ["roman", "f2cf5b", "d8433a"],
	["storm", "6b8ff0", "2c4596"], ["crazy", "5c616b", "2a2c32"], ["waazoo", "6a8a4a", "3e5a2a"], ["cc_ball", "3a3a44", "1b1a24"],
	["wk_missile", "a8b0bc", "5c616b"],
	["volcanic", "ff5a2a", "a8241a"], ["erbium", "c83a6a", "7a1e4a"], ["copper", "e8864a", "a85a2a"], ["silver", "e3ebf5", "9fb0c8"],
	["golden_knight", "f2cf5b", "c99a2e"], ["gold", "f2cf5b", "c99a2e"], ["iron", "8ab0d8", "5a7a9a"], ["light", "f2efe6", "c8c0b0"],
	["dark", "7b4fb8", "3a2a5a"], ["hell", "d8433a", "8a1e1a"], ["evil", "5a2a6a", "2a1030"], ["fear", "5c616b", "2a2c32"],
	["witch", "7b4fb8", "3a2a5a"], ["spectre", "d8d0f0", "8a80b0"], ["wooden", "a8703f", "6e4426"], ["wood", "a8703f", "6e4426"],
	["timber", "a8703f", "6e4426"], ["stone", "9aa2ad", "5c616b"], ["rock", "9aa2ad", "5c616b"], ["leather", "a07a55", "6e4a2a"],
	["jelly", "f06aa0", "b04a78"], ["brass", "d0a050", "8a6a2a"], ["blue", "6b8ff0", "2c4596"], ["azure", "6b8ff0", "2c4596"],
	["knight", "c8ced6", "7a8290"], ["tank", "7a8290", "4a5260"], ["ivory", "f2ecd8", "c8bca0"], ["jade", "5cbf8a", "2e8a5a"],
	["sandy", "e2cf8e", "b09a5a"], ["sage", "8fb07a", "5e7a52"], ["lavish", "d8a0e0", "9a5aa8"], ["chain", "aab0b8", "6a7078"],
	["scale", "4fb6d0", "2a7a90"], ["seer", "a77ee0", "5a3a8a"], ["linen", "e8dccb", "b0a088"], ["rooster", "d8433a", "f2cf5b"],
	["pumpkin", "ea8a33", "b85e1c"], ["faceguard", "9aa2ad", "5c616b"], ["blood", "c8302a", "7a1414"], ["ruby", "d8433a", "8a1e1a"],
	["sapphire", "3b5dc9", "1e2a6a"], ["em_", "5cbf3f", "2e7a2a"], ["violet", "a77ee0", "5a3a8a"], ["fire", "f2a33a", "d8433a"],
	["glow_blade_blue", "6bc8f0", "2c7ab0"], ["glow_blade_red", "f06a5a", "a82a22"], ["glow_blade_green", "7cf06a", "2e9a2a"],
	["glow_blade_pink", "f08ac8", "b04a90"], ["moon", "e3ebf5", "8a9ab8"], ["holy", "f2efe6", "f2cf5b"], ["poison", "6ac83a", "2e7a1a"],
	["excalibur", "e3ebf5", "6b8ff0"], ["twin", "f2cf5b", "ea8a33"], ["devil", "d8433a", "3a1a1a"], ["kings", "f2cf5b", "8a6a2a"],
	["plunger", "d8433a", "8a1e1a"], ["short", "c8ced6", "7a8290"], ["gilded", "f2cf5b", "c99a2e"], ["combo", "c8a0e8", "7a5aa8"],
	["long", "c8ced6", "7a8290"], ["cast", "a8a8b0", "6a6a72"], ["staff", "a77ee0", "5a3a8a"], ["healing", "5cbf3f", "2e7a2a"],
	["magic", "a77ee0", "5a3a8a"], ["hallow", "8affc8", "3ec88a"], ["pole", "c8ced6", "7a8290"],
]

func material_colors(id: String) -> Dictionary:
	for m in MATERIAL_COLORS:
		if id.contains(m[0]):
			return {"X": m[1], "x": m[2]}
	return {"X": "c8ced6", "x": "7a8290"}

func icon_spec(id: String) -> Array:
	var it: Dictionary = Data.ITEMS.get(id, {})
	var t: String = it.get("type", "material")
	var mc := material_colors(id)
	match id:
		"wood": return ["log", {}]
		"blue_wood": return ["log", {"l": "6b8ff0", "n": "2c4596"}]
		"branch": return ["stick", {}]
		"rock": return ["lump", {"X": "9aa2ad", "x": "5c616b"}]
		"coal": return ["lump", {"X": "3e424a", "x": "1b1a24"}]
		"dust": return ["lump", {"X": "c8b89a", "x": "8a7a62"}]
		"jelly": return ["blob", {"X": "f06aa0", "x": "b04a78"}]
		"sticky_balls": return ["blob", {"X": "a8e86a", "x": "5aa82a"}]
		"snowball": return ["blob", {"X": "f2efe6", "x": "a6c6d8"}]
		"bone": return ["bone", {}]
		"sticky_bones": return ["bone", {"w": "c8e89a"}]
		"herb": return ["leaf", {}]
		"antidote_herb": return ["leaf", {"g": "4fb6d0", "G": "2a7a90"}]
		"blue_moon": return ["flower", {"X": "6b8ff0"}]
		"plant_roots": return ["root", {"X": "c8a070", "x": "8a6a40"}]
		"old_roots": return ["root", {"X": "8a6a40", "x": "5a4020"}]
		"legendary_roots": return ["root", {"X": "f2cf5b", "x": "c99a2e"}]
		"crystal": return ["crystal", {"X": "a6e6f2", "x": "4fb6d0"}]
		"fire_crystal": return ["crystal", {"X": "f2a33a", "x": "d8433a"}]
		"water_crystal": return ["crystal", {"X": "6b8ff0", "x": "2c4596"}]
		"earth_crystal": return ["crystal", {"X": "a8703f", "x": "5cbf3f"}]
		"dark_crystal": return ["crystal", {"X": "7b4fb8", "x": "3a2a5a"}]
		"evil_crystal", "small_evil_crystal": return ["crystal", {"X": "5a2a6a", "x": "d8433a"}]
		"catalyst": return ["gem", {"X": "f2cf5b", "x": "4fb6d0"}]
		"dongle": return ["gadget", {"X": "5cbf3f"}]
		"monster_hide": return ["hide", {"X": "a07a55", "x": "6e4a2a"}]
		"monster_leather": return ["hide", {"X": "8a5a32", "x": "5a3a1a"}]
		"harden_leather": return ["hide", {"X": "5a3a1a", "x": "3a2010"}]
		"monster_shell": return ["shell", {"X": "5aa0a8", "x": "3e6a70"}]
		"monster_scale": return ["shell", {"X": "4fb6d0", "x": "2a7a90"}]
		"monster_horn": return ["horn", {"X": "e8dccb", "x": "a89878"}]
		"linen": return ["hide", {"X": "e8dccb", "x": "b0a088"}]
		"wood_board": return ["board", {"X": "a8703f", "x": "6e4426"}]
		"nail": return ["nail", {}]
		"apple": return ["apple", {"X": "d8433a", "x": "8a1e1a"}]
		"evil_apple": return ["apple", {"X": "5a2a6a", "x": "2a1030"}]
		"living_flame": return ["blob", {"X": "f2a33a", "x": "d8433a"}]
		"em_stone", "ruby_stone", "sapphire_stone": return ["gem", mc]
		"scarab": return ["bug", {"X": "3b5dc9", "x": "2c4596"}]
		"stink_bug": return ["bug", {"X": "8fb07a", "x": "5e7a52"}]
		"honey_bug": return ["bug", {"X": "f2cf5b", "x": "c99a2e"}]
		"fire_bug": return ["bug", {"X": "ea6a33", "x": "a83a1a"}]
		"power_bug": return ["bug", {"X": "d8433a", "x": "8a1e1a"}]
		"armor_bug": return ["bug", {"X": "9aa2ad", "x": "5c616b"}]
		"hero_bug": return ["bug", {"X": "f2cf5b", "x": "7b4fb8"}]
		"pretzel": return ["food", {"X": "c8865a", "x": "8a5a32"}]
		"holy_banana": return ["food", {"X": "f2cf5b", "x": "c99a2e"}]
		"torch_weapon": return ["torch_i", {}]
		"pole_axe": return ["pole", mc]
		"timber_club": return ["club", {"X": "a8703f", "x": "6e4426"}]
		"kings_mace": return ["mace", mc]
		"devil_spike": return ["spike", mc]
		"plunger": return ["plunger", mc]
		"arrow": return ["arrow", {}]
		"snow_ball": return ["balls", {"X": "f4fbff", "x": "a6c6d8"}]
		"wood_wall": return ["wall", {}]
		"stone_wall": return ["wall", {"n": "9aa2ad", "l": "c8ced6", "N": "5c616b"}]
		"wooden_spikes": return ["spikes", {}]
		"work_station": return ["station", {}]
		"campfire": return ["fire", {}]
		"torch": return ["torch_i", {}]
		"survival_token": return ["token", {"X": "5cbf3f", "x": "2e7a2a"}]
		"combination_scroll": return ["scroll", {"X": "a77ee0"}]
	if id.ends_with("_ore") or id == "erbium":
		return ["ore", {"X": mc.X}]
	if id.ends_with("_bar"):
		return ["bar", mc]
	match t:
		"food":
			var c := "d8433a"
			if id.contains("mana"): c = "3b6fd9"
			elif id.contains("rejuvenate"): c = "a77ee0"
			elif id == "antidote": c = "5cbf3f"
			elif id == "fatigue_potion": c = "f2cf5b"
			return ["potion", {"X": c, "x": Color(c).darkened(0.35).to_html(false)}]
		"weapon":
			return ["long" if id.contains("long") or id == "excalibur" else "sword", mc]
		"staff": return ["staff", mc]
		"bow": return ["cannon", mc] if it.get("cannon", false) else ["bow", {}]
		"ammo": return ["balls", mc] if id.begins_with("cc_") else ["missile", mc]
		"axe": return ["axe", mc]
		"pick": return ["pick", mc]
		"armor": return ["armor", mc]
		"helmet":
			if id.ends_with("_mask") or id == "green_face" or id == "the_fly":
				return ["mask", mc]
			return ["hat" if id.contains("hat") or id.contains("witch") or id.contains("hood") else "helmet", mc]
		"shield": return ["shield", mc]
		"ring": return ["ring", {"X": mc.X, "x": "c99a2e"}]
		"book":
			var bc := {"survival_book": "4f9a44", "combo_book_1": "3b5dc9", "combo_book_2": "d8433a", "combo_book_3": "f2a33a", "combo_book_4": "7b4fb8", "combo_book_5": "1b1a24"}
			return ["book", {"X": bc.get(id, "3b5dc9"), "x": "1b1a24"}]
		"key":
			var kc := {"silver_key": "e3ebf5", "golden_key": "f2cf5b", "master_key": "d8433a"}
			return ["key", {"X": kc.get(id, "f2cf5b"), "x": "8a8a8a"}]
		"seed":
			var sc := {"green_seeds": "5cbf3f", "red_seeds": "d8433a", "golden_seeds": "f2cf5b"}
			return ["seed", {"X": sc.get(id, "5cbf3f"), "x": "1b1a24"}]
		"egg":
			var ec := {"green_egg": "5cbf3f", "pink_egg": "f06aa0", "purple_egg": "7b4fb8", "red_egg": "d8433a", "queen_egg": "f2cf5b", "king_egg": "5c616b"}
			return ["egg", {"X": ec.get(id, "5cbf3f")}]
	return ["lump", mc]

func pet_look(id: String) -> String:
	var look: String = Data.PETS[id].look
	return look

func icon(id: String) -> Texture2D:
	return cached("icon_" + id, func():
		var it: Dictionary = Data.ITEMS.get(id, {})
		if it.get("type", "") == "character":
			var full: Image = _char_img(it.look, "stand", 1)
			return to_tex(outline(full.get_region(Rect2i(0, 1, full.get_width(), 16))))
		if it.get("type", "") == "pet":
			var img: Image = mob_tex(pet_look(id), false).get_image()
			var s := 12.0 / maxf(img.get_width(), img.get_height())
			if s < 1.0:
				img.resize(maxi(1, int(img.get_width() * s)), maxi(1, int(img.get_height() * s)), Image.INTERPOLATE_NEAREST)
			return to_tex(img)
		var spec := icon_spec(id)
		return to_tex(outline(grid_image(ICON_GRIDS[spec[0]], spec[1]))))

# ---------------------------------------------------------------- world themes
const THEMES := {
	"grass": {"sky": ["6fb6dc", "bfe3ee"], "mount": "5a8c8a", "snow": "e8f2f2", "hills": "3f8a52", "top": "5cbf3f", "top2": "3e9a2e", "dirt": "8a5a32", "dirt2": "6e4426", "cave": "4a3020"},
	"dark": {"sky": ["2a2340", "5a4a6e"], "mount": "4a3e6a", "snow": "9a8ab0", "hills": "2e2a3e", "top": "6a5a8a", "top2": "4a3e66", "dirt": "3e3040", "dirt2": "2c2230", "cave": "1e1624"},
	"hell": {"sky": ["3a1020", "7a2a3a"], "mount": "5a1e3a", "snow": "c83a6a", "hills": "3a1028", "top": "8a3a6a", "top2": "5a2048", "dirt": "3a1a30", "dirt2": "2a1020", "cave": "1a0a14"},
	"ice": {"sky": ["9ad0f0", "e3f2f8"], "mount": "8ab0d0", "snow": "ffffff", "hills": "a6c8e0", "top": "e3f2f8", "top2": "a6d0e8", "dirt": "5a8ab0", "dirt2": "4a7098", "cave": "2a4a6a"},
	"dream": {"sky": ["f0a8d8", "fde2f2"], "mount": "c88ac8", "snow": "fff0fa", "hills": "a870c0", "top": "f08ac8", "top2": "c86aa8", "dirt": "7a4a8a", "dirt2": "5a3a6a", "cave": "3a2a4a"},
	"ghost": {"sky": ["1a1a2e", "3a3a5a"], "mount": "2e2e4a", "snow": "8a8ab0", "hills": "24243a", "top": "4a5a4a", "top2": "34403a", "dirt": "2a2a34", "dirt2": "1e1e28", "cave": "121218"},
}

func theme(name: String) -> Dictionary:
	var t: Dictionary = THEMES[name]
	var d := {"name": name}
	for k in t:
		if k == "sky":
			d.sky = [Color(t.sky[0]), Color(t.sky[1])]
		else:
			d[k] = Color(t[k])
	return d

## Tiles: [grass top, dirt, cave back wall]
func ground_tiles(th: Dictionary) -> Array:
	var key: String = "ground_" + th.name
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(th.name)
	var top := blank(16, 16)
	top.fill(th.dirt)
	for i in 10:
		px(top, rng.randi_range(0, 15), rng.randi_range(6, 15), th.dirt2)
	for x in 16:
		var d := rng.randi_range(4, 7)
		rect(top, x, 0, 1, d, th.top)
		px(top, x, d, th.top2)
	for i in 4:
		px(top, rng.randi_range(0, 15), rng.randi_range(0, 2), th.top.lightened(0.25))
	var fill := blank(16, 16)
	fill.fill(th.dirt)
	for i in 14:
		rect(fill, rng.randi_range(0, 14), rng.randi_range(0, 14), 2, 1, th.dirt2 if i % 3 else th.dirt.lightened(0.12))
	var back := blank(16, 16)
	back.fill(th.cave)
	for i in 8:
		rect(back, rng.randi_range(0, 14), rng.randi_range(0, 14), 2, 1, th.cave.lightened(0.08))
	var ledge := fill.duplicate()
	rect(ledge, 0, 0, 16, 3, th.dirt.lightened(0.18))
	for x in 16:
		px(ledge, x, 3 + (x * 7) % 2, th.dirt2)
	var tex := [to_tex(top), to_tex(fill), to_tex(back), to_tex(ledge)]
	_cache[key] = tex
	return tex

func node_tex(kind: String, th: Dictionary) -> Texture2D:
	return cached("node_%s_%s" % [kind, th.name], func():
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(kind)
		var img: Image
		var ore := {"copper": "e8864a", "iron": "8ab0d8", "silver": "e3ebf5", "gold": "f2cf5b", "erbium_rock": "e04a7a", "ice_rock": "a6e6f2"}
		match kind:
			"tree", "blue_tree":
				img = blank(18, 46)
				var trunk := Color("6e4426") if kind == "tree" else Color("3b5dc9")
				if th.name == "dark" and kind == "tree": trunk = Color("4a3e4a")
				if th.name == "ice": trunk = Color("6a8aa8")
				rect(img, 7, 10, 4, 36, trunk)
				rect(img, 7, 10, 1, 36, trunk.lightened(0.2))
				var leaf := Color("3e9a3a") if kind == "tree" else Color("7b4fb8")
				if th.name == "dark" and kind == "tree": leaf = Color("5a4a7a")
				if th.name == "ice": leaf = Color("e3f2f8")
				ellipse(img, 9, 7, 8, 7, leaf)
				ellipse(img, 7, 5, 3, 2, leaf.lightened(0.3))
			"plant_yellow", "plant_pink":
				img = blank(14, 14)
				var bulb := Color("f2cf5b") if kind == "plant_yellow" else Color("d84a7a")
				ellipse(img, 7, 10, 6, 4, bulb)
				ellipse(img, 5, 9, 2, 1, bulb.lightened(0.35))
				for i in 3:
					rect(img, 4 + i * 3, 2 + (i % 2) * 2, 2, 6, Color("3e9a3a"))
			"pot", "vase":
				img = blank(14, 16)
				var c := Color("c8865a") if kind == "pot" else Color("7b4fb8")
				ellipse(img, 7, 10, 6, 6, c)
				rect(img, 4, 1, 6, 4, c)
				rect(img, 3, 1, 8, 1, c.darkened(0.3))
				rect(img, 2, 9, 10, 1, c.lightened(0.25))
			"rock_wall":
				img = blank(20, 48)
				for y in range(0, 48, 8):
					for x in range(0 if (y / 8) % 2 == 0 else -5, 20, 10):
						rect(img, x + 1, y + 1, 9, 7, Color("8a9099"))
						rect(img, x + 1, y + 1, 9, 1, Color("b8bec6"))
			_:
				img = blank(18, 14)
				var base := Color("8a9099")
				if th.name == "ice": base = Color("a6c0d8")
				if th.name == "hell": base = Color("6a4a5a")
				ellipse(img, 9, 8, 9, 6, base)
				ellipse(img, 7, 6, 5, 3, base.lightened(0.2))
				rect(img, 2, 12, 14, 2, base.darkened(0.3))
				if ore.has(kind):
					for i in 8:
						rect(img, rng.randi_range(3, 13), rng.randi_range(4, 11), 2, 2, Color(ore[kind]))
		return to_tex(outline(img)))

# ---------------------------------------------------------------- village and props
func house_tex(wall: Color, roof: Color, w: int = 52) -> Texture2D:
	return cached("house_%s_%s_%d" % [wall.to_html(), roof.to_html(), w], func():
		var img := blank(w, 46)
		rect(img, 4, 20, w - 8, 26, wall)
		for y in range(22, 46, 4):
			rect(img, 4, y, w - 8, 1, wall.darkened(0.15))
		for i in 20:
			rect(img, i, 20 - i, w - i * 2, 1, roof if i % 3 else roof.darkened(0.2))
		rect(img, w / 2 - 5, 32, 10, 14, Color("6e4426"))
		px(img, w / 2 + 3, 39, Color("f2cf5b"))
		rect(img, 8, 27, 8, 7, Color("a6e6f2"))
		rect(img, w - 16, 27, 8, 7, Color("a6e6f2"))
		return to_tex(outline(img)))

func prop_tex(kind: String, state: String = "") -> Texture2D:
	return cached("prop_%s_%s" % [kind, state], func():
		var img: Image = null
		match kind:
			"furnace":
				img = blank(22, 26)
				rect(img, 1, 4, 20, 22, Color("7a7f88"))
				for y in range(5, 26, 4):
					rect(img, 1, y, 20, 1, Color("5c616b"))
				rect(img, 6, 0, 10, 5, Color("5c616b"))
				rect(img, 6, 13, 10, 8, Color("1b1a24"))
				if state == "busy" or state == "done":
					rect(img, 7, 16, 8, 5, Color("ea8a33"))
					rect(img, 9, 14, 4, 3, Color("f2cf5b"))
				if state == "done":
					rect(img, 8, 1, 6, 3, Color("5cbf3f"))
			"chest":
				img = blank(20, 16)
				var c: Color = {"silver": Color("c8ced6"), "golden": Color("f2cf5b"), "master": Color("d8433a"), "reward": Color("a8703f")}.get(state, Color("a8703f"))
				rect(img, 0, 4, 20, 12, Color("8a5a32"))
				rect(img, 0, 0, 20, 6, Color("a8703f"))
				rect(img, 0, 5, 20, 2, c)
				rect(img, 0, 0, 2, 16, c)
				rect(img, 18, 0, 2, 16, c)
				rect(img, 8, 6, 4, 4, c)
				px(img, 9, 8, OUTLINE)
			"incubator":
				img = blank(18, 22)
				ellipse(img, 9, 8, 8, 8, Color(0.7, 0.9, 1.0, 0.85))
				rect(img, 2, 14, 14, 8, Color("7a7f88"))
				rect(img, 2, 14, 14, 2, Color("a8a8b0"))
				if state != "":
					ellipse(img, 9, 9, 3.5, 4.5, Color("f2efe6"))
					px(img, 8, 8, Color("5cbf3f"))
			"soil":
				img = blank(18, 8)
				rect(img, 0, 2, 18, 6, Color("5a3a1a"))
				rect(img, 1, 2, 16, 1, Color("7a5a32"))
				if state == "growing":
					rect(img, 8, 0, 2, 3, Color("5cbf3f"))
				elif state == "done":
					rect(img, 8, 0, 2, 3, Color("5cbf3f"))
					ellipse(img, 9, 1, 3, 2, Color("f2cf5b"))
			"wall":
				var brick := grid_image(ICON_GRIDS.wall, {} if state == "wood" else {"n": "9aa2ad", "l": "c8ced6", "N": "5c616b"})
				img = blank(16, 32)
				for y in range(0, 32, 9):
					for x in range(0, 16, 10):
						img.blit_rect(brick, Rect2i(0, 0, 10, 9), Vector2i(x, y))
			"spikes":
				var sp := grid_image(ICON_GRIDS.spikes)
				img = blank(16, 8)
				img.blit_rect(sp, Rect2i(0, 2, 10, 5), Vector2i(0, 2))
				img.blit_rect(sp, Rect2i(0, 2, 10, 5), Vector2i(7, 2))
			"work_station": img = grid_image(ICON_GRIDS.station, {}, 2)
			"campfire": img = grid_image(ICON_GRIDS.fire2 if state == "b" else ICON_GRIDS.fire, {}, 2)
			"torch": img = grid_image(ICON_GRIDS.torch_i)
			"coin": img = grid_image([".yyy.", "yYyyy", "yyYyy", "yyyYy", ".yyy."])
			"heart": img = grid_image([".rr.rr.", "rRrrrrr", "rrrrrrr", ".rrrrr.", "..rrr..", "...r..."])
			"sign":
				img = blank(16, 16)
				rect(img, 7, 6, 2, 10, Color("6e4426"))
				rect(img, 0, 0, 16, 8, Color("a8703f"))
				rect(img, 2, 2, 12, 1, Color("6e4426"))
				rect(img, 2, 5, 9, 1, Color("6e4426"))
			"gate":
				img = blank(12, 48)
				for x in [0, 4, 8]:
					rect(img, x, 0, 3, 48, Color("5c616b"))
				for y in [4, 22, 40]:
					rect(img, 0, y, 12, 2, Color("3e424a"))
		if img == null:
			img = blank(8, 8)
		return to_tex(outline(img)))

func portal_tex(frame: int, tint: Color) -> Texture2D:
	return cached("portal_%d_%s" % [frame, tint.to_html()], func():
		var img := blank(18, 34)
		ellipse(img, 9, 17, 9, 17, tint.darkened(0.4))
		ellipse(img, 9, 17, 7, 14, tint)
		ellipse(img, 9, 17, 4, 9, tint.lightened(0.4))
		for i in 6:
			var a := frame * 0.8 + i * 1.05
			px(img, int(9 + cos(a) * 5), int(17 + sin(a) * 11), Color.WHITE)
		return to_tex(outline(img)))

func mountains_tex(th: Dictionary) -> Texture2D:
	return cached("mount_" + th.name, func():
		var w := 512
		var h := 150
		var img := blank(w, h)
		var peaks := [[40, 70], [120, 40], [200, 80], [270, 30], [350, 64], [430, 46], [500, 74]]
		for x in w:
			var top := h
			for p in peaks:
				for o in [-w, 0, w]:
					top = mini(top, int(p[1] + absf(x - (p[0] + o)) * 0.9))
			rect(img, x, top, 1, h - top, th.mount)
			for p in peaks:
				for o in [-w, 0, w]:
					var d2 := absf(x - (p[0] + o))
					if int(p[1] + d2 * 0.9) == top and d2 < 16:
						rect(img, x, top, 1, maxi(10 - int(d2 / 3) + (x * 7) % 3, 2), th.snow)
		return to_tex(img))

func hills_tex(th: Dictionary) -> Texture2D:
	return cached("hills_" + th.name, func():
		var w := 512
		var h := 90
		var img := blank(w, h)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 40:
			var x := rng.randi_range(0, w)
			var r := rng.randi_range(10, 22)
			for o in [-w, 0, w]:
				ellipse(img, x + o, h - 30 + rng.randi_range(-6, 6), r, r * 1.3, th.hills)
				ellipse(img, x + o - r * 0.3, h - 36, r * 0.4, r * 0.4, th.hills.lightened(0.12))
		rect(img, 0, h - 20, w, 20, th.hills)
		return to_tex(img))

func light_tex() -> Texture2D:
	return cached("light", func():
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		return t)

func button_tex(w: int, h: int, c: Color) -> Texture2D:
	return cached("btn_%d_%d_%s" % [w, h, c.to_html()], func():
		var img := blank(w, h)
		rect(img, 1, 0, w - 2, h, OUTLINE)
		rect(img, 0, 1, w, h - 2, OUTLINE)
		rect(img, 2, 2, w - 4, h - 4, c)
		rect(img, 2, h - 5, w - 4, 3, c.darkened(0.3))
		rect(img, 3, 3, w - 6, 2, c.lightened(0.25))
		return to_tex(img))
