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
		".hhhhsssshhh",
		".hhhsbbsbbs.",
		".hhssweswes.",
		".hhssweswes.",
		"..hsssssmmm.",
		"...SSsssSS..",
	],
	"bald": [
		"...ssssss...",
		"..sssssssss.",
		".sssssssssss",
		".ssssssssss.",
		".Ssssbbsbbs.",
		".Ssssweswes.",
		".Ssssweswes.",
		"..Sssssmmm..",
		"...SSsssSS..",
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
		"over": [[1, 2, ["..h..h..h...", ".hhhhhhhhhh."]]]},
	"pirate": {"h": "1b1a24", "H": "1b1a24", "c": "f2efe6", "C": "d8433a", "v": "f2efe6", "t": "d8433a", "q": "2e3242", "f": "6e4426",
		"over": [[1, 3, ["..rrrrrr....", ".rrRrrrrrr..", "rrrrrrrrrrr."]], [0, 6, ["rr"]], [0, 7, [".r"]], [3, 8, ["kkkkkkk"]], [8, 9, ["kk"]], [8, 10, ["kk"]]]},
	"the_spi": {"h": "1b1a24", "H": "3a3a48", "c": "1b1a24", "C": "2e3242", "v": "f2efe6", "t": "1b1a24", "q": "1b1a24", "f": "1b1a24",
		"over": [[4, 9, ["kkkkkkk", ".kk.kk."]]]},
	"bad_man": {"h": "2a2a30", "H": "1b1a24", "s": "3a3a44", "S": "2a2a30", "c": "4a4a5a", "C": "2a2a30", "v": "4a4a5a", "t": "2a2a30", "q": "2a2a30", "f": "1b1a24", "hair": "bald",
		"over": [[4, 9, ["wwewwew", "wwewwew"]]]},
	"school_girl": {"h": "1b1a24", "H": "2a2230", "long": true, "c": "f2efe6", "C": "d8d0c0", "v": "3b5dc9", "t": "d8433a", "j": "3b5dc9", "q": "f2c29a", "f": "1b1a24"},
	"soldier": {"h": "5a3a20", "H": "3a2614", "c": "6a8a4a", "C": "4a6a2a", "v": "6a8a4a", "t": "4a6a2a", "j": "3a2a22", "q": "4a6a2a", "f": "3a2a22",
		"over": [[2, 2, ["..ZZZZZZ..", ".ZzZZZZZZZ.", "ZZZZZzZZZZZ", "ZZZZZZZZZZZ", "zzzzzzzzzzz"]]]},
	"chuchu": {"h": "f08ac8", "H": "c05a98", "long": true, "c": "f06aa0", "C": "c84a80", "v": "f2efe6", "t": "f2efe6", "j": "f06aa0", "q": "f2c29a", "f": "f2efe6",
		"over": [[1, 1, [".hh......hh.", "hhHh....hHhh", ".hh......hh."]]]},
	"drone": {"h": "5c616b", "H": "3e424a", "s": "a8b0bc", "S": "7a8290", "e": "4fd0f0", "c": "7a8290", "C": "5c616b", "v": "a8b0bc", "t": "4fd0f0", "q": "5c616b", "f": "3e424a", "hair": "bald",
		"over": [[6, 0, ["A", "a", "a"]], [4, 3, ["aaaaa"]], [4, 9, ["kkekkek", "kkekkek"]], [8, 11, ["kkk"]]]},
	"dark_knight": {"h": "3a2a5a", "H": "2a1e40", "s": "4a3a6a", "S": "2a1e40", "e": "d8433a", "c": "4a3a6a", "C": "2a1e40", "v": "7b4fb8", "t": "7b4fb8", "j": "2a1e40", "q": "2a1e40", "f": "1b1a24", "hair": "bald",
		"over": [[3, 0, [".rr.", "rRr.", "rr..", "PPPPPPPP"]], [2, 8, ["PPPPPPPPPP"]], [4, 9, ["kkekkek", "kkekkek"]], [8, 11, ["kkk"]]]},
	"ninja": {"h": "1b1a24", "H": "1b1a24", "s": "1b1a24", "S": "1b1a24", "m": "1b1a24", "c": "1b1a24", "C": "1b1a24", "v": "1b1a24", "t": "d8433a", "j": "d8433a", "q": "1b1a24", "f": "1b1a24", "x": "f2c29a", "hair": "bald",
		"over": [[4, 9, ["xwexwex", "xwexwex"]], [1, 7, ["rrrrrrrrrr"]], [0, 8, ["rr"]], [0, 9, [".r"]]]},
	"ninja_npc": {"h": "2a2a48", "H": "2a2a48", "s": "2a2a48", "S": "2a2a48", "m": "2a2a48", "c": "2a2a48", "C": "2a2a48", "v": "2a2a48", "t": "d8433a", "j": "d8433a", "q": "2a2a48", "f": "1b1a24", "x": "f2c29a", "hair": "bald",
		"over": [[4, 9, ["xwexwex", "xwexwex"]], [1, 7, ["rrrrrrrrrr"]], [0, 8, ["rr"]], [0, 9, [".r"]]]},
	"ninja_npc2": {"h": "5a1e2a", "H": "5a1e2a", "s": "5a1e2a", "S": "5a1e2a", "m": "5a1e2a", "c": "5a1e2a", "C": "5a1e2a", "v": "5a1e2a", "t": "f2cf5b", "j": "f2cf5b", "q": "5a1e2a", "f": "1b1a24", "x": "f2c29a", "hair": "bald",
		"over": [[4, 9, ["xwexwex", "xwexwex"]], [1, 7, ["rrrrrrrrrr"]], [0, 8, ["rr"]], [0, 9, [".r"]]]},
	"ninja_npc3": {"h": "3a2a5a", "H": "3a2a5a", "s": "3a2a5a", "S": "3a2a5a", "m": "3a2a5a", "c": "3a2a5a", "C": "3a2a5a", "v": "3a2a5a", "t": "f06aa0", "j": "f06aa0", "q": "3a2a5a", "f": "1b1a24", "x": "f2c29a", "hair": "bald",
		"over": [[4, 9, ["xwexwex", "xwexwex"]], [1, 7, ["rrrrrrrrrr"]], [0, 8, ["rr"]], [0, 9, [".r"]]]},
	"robot_npc": {"h": "5c616b", "H": "5c616b", "s": "a8b0bc", "S": "5c616b", "e": "4fd0f0", "m": "5c616b", "c": "a8b0bc", "C": "5c616b", "v": "a8b0bc", "t": "4fd0f0", "q": "5c616b", "f": "3e424a", "hair": "bald",
		"over": [[4, 9, ["kkekkek", "kkekkek"]], [5, 2, [".aa.", "aAAa"]], [2, 12, ["S"]], [9, 12, ["S"]]]},
	"robot_npc2": {"h": "c99a2e", "H": "c99a2e", "s": "f2cf5b", "S": "c99a2e", "e": "d8433a", "m": "c99a2e", "c": "f2cf5b", "C": "c99a2e", "v": "f2cf5b", "t": "d8433a", "q": "c99a2e", "f": "3e424a", "hair": "bald",
		"over": [[4, 9, ["kkekkek", "kkekkek"]], [5, 2, [".aa.", "aAAa"]], [2, 12, ["S"]], [9, 12, ["S"]]]},
	"robot_npc3": {"h": "2e8a7a", "H": "2e8a7a", "s": "5cc8b0", "S": "2e8a7a", "e": "f2efe6", "m": "2e8a7a", "c": "5cc8b0", "C": "2e8a7a", "v": "5cc8b0", "t": "f2cf5b", "q": "2e8a7a", "f": "3e424a", "hair": "bald",
		"over": [[4, 9, ["kkekkek", "kkekkek"]], [5, 2, [".aa.", "aAAa"]], [2, 12, ["S"]], [9, 12, ["S"]]]},
	"iron_bot": {"h": "2c4596", "H": "2c4596", "s": "6b8ff0", "S": "2c4596", "e": "f2cf5b", "m": "2c4596", "c": "6b8ff0", "C": "2c4596", "v": "6b8ff0", "t": "f2a33a", "q": "2c4596", "f": "3e424a", "hair": "bald",
		"over": [[4, 9, ["kkekkek", "kkekkek"]], [5, 2, [".aa.", "aAAa"]], [2, 12, ["S"]], [9, 12, ["S"]]]},
	"backstreet_boy": {"h": "f2cf5b", "H": "c99a2e", "c": "f2efe6", "C": "c8c0b0", "v": "f2efe6", "t": "3b5dc9", "j": "3b5dc9", "q": "3b5dc9", "f": "f2efe6",
		"over": [[2, 1, ["..hhhhhhh..", ".hhHhhhHhhh", "hhh......hh"]]]},
	"sailor_moons": {"h": "f2cf5b", "H": "c99a2e", "long": true, "c": "f2efe6", "C": "d8d0c0", "v": "3b5dc9", "t": "d8433a", "j": "3b5dc9", "q": "f2c29a", "f": "d8433a",
		"over": [[0, 2, ["hh........hh", "hHh......hHh", "hh........hh"]], [0, 9, ["hh"]], [0, 10, ["hh"]], [0, 11, ["hh"]], [10, 9, ["hh"]], [10, 10, ["hh"]], [10, 11, ["hh"]]]},
	# villagers
	"keeper": {"h": "3a2a5a", "H": "2a1e40", "c": "7b4fb8", "C": "5a3a8a", "q": "3a2a5a", "f": "1b1a24", "s": "e8b48a", "t": "f2cf5b",
		"over": [[2, 1, ["...PPPP...", "..PPyPPP..", ".PPPPPPPP."]]]},
	"gruff": {"h": "8a3a12", "H": "5a2208", "c": "6e5a3e", "C": "4a3e2a", "q": "4a3a2a", "f": "2a2230", "s": "f2c07a", "j": "3a2a22", "long": true,
		"over": [[0, 0, ["..hhhhhhhh..", ".hhhhhhhhhh.", "hhhhhhhhhhhh", "hhhhhhhhhhhh"]], [0, 8, ["hh"]], [0, 9, ["hh"]], [0, 10, ["hh"]], [10, 7, ["hh"]]]},
	"mira": {"h": "1b1a24", "H": "2a2a36", "s": "f2c07a", "long": true, "c": "f06aa0", "C": "c84a80", "t": "f2efe6", "j": "e06a9a", "q": "f2c07a", "f": "3a2a22"},
	"warden": {"h": "1b1a24", "H": "1b1a24", "s": "2e9a52", "S": "1e7a3e", "b": "1b1a24", "c": "3a4a3a", "C": "2a3a2a", "q": "3a3a48", "f": "1b1a24", "hair": "bald",
		"over": [[1, 2, ["..kkkkkkkk.", ".kkkkkkkkkk", "kkkkkkkkkkk"]], [4, 8, ["kkkkkkk"]]]},
	"smith": {"h": "3a2a22", "H": "2a1e18", "c": "7a5a3a", "C": "5a4028", "q": "4a3428", "f": "2a2230", "s": "c88a5a", "v": "a07a55", "t": "a07a55"},
	"merchant": {"h": "6a4220", "H": "4a2e14", "cap": "d8433a", "capH": "a82a22", "c": "3b5dc9", "C": "2c4596", "q": "4a3a2a", "f": "2a2230", "t": "f2cf5b"},
	"tools": {"h": "4a2a1a", "H": "3a2010", "cap": "d8433a", "capH": "a82a22", "c": "d8433a", "C": "a82a22", "v": "3b5dc9", "t": "3b5dc9", "j": "3b5dc9", "q": "3b5dc9", "f": "6e4426", "s": "f2c29a",
		"over": [[7, 11, ["kkkk"]]]},
	"miner": {"h": "f2cf5b", "H": "c99a2e", "c": "6e5a3e", "C": "4a3e2a", "q": "4a4a5a", "f": "2a2230"},
	"trader": {"h": "6a4220", "H": "4a2e14", "cap": "4f9a44", "capH": "2e7a2a", "c": "f2cf5b", "C": "c99a2e", "t": "4f9a44", "q": "4a3a2a", "f": "2a2230"},
	"jumpie": {"h": "1b1a24", "H": "2a2a36", "s": "f2c07a", "long": true, "c": "5cbf3f", "C": "3e8a2e", "t": "f2efe6", "j": "4f9a44", "q": "f2c07a", "f": "3a2a22",
		"over": [[8, 3, ["rr", "r."]]]},
	# monsters that are drawn as people
	"zombie": {"h": "3a3a2a", "H": "2a2a1e", "s": "8fb07a", "S": "5e7a52", "c": "6e5a3e", "C": "4a3e2a", "q": "3e4a5a", "f": "2a2230", "e": "d8433a"},
	"wizard": {"h": "3b5dc9", "H": "2c4596", "s": "e8c8a8", "S": "c8a888", "c": "3b5dc9", "C": "6b8ff0", "q": "3b5dc9", "f": "2c4596", "e": "f2cf5b"},
	"lich": {"h": "3a2a5a", "H": "2a1e44", "s": "e8e8f0", "S": "b8b8c8", "c": "5a2a8a", "C": "3a1a5a", "q": "3a1a5a", "f": "2a1e44", "e": "8affc8", "m": "2a1e44"},
	"grinch": {"h": "4a8a2a", "H": "2e6a1a", "s": "6ac83a", "S": "4a9a2a", "c": "d8433a", "C": "f2efe6", "q": "4a8a2a", "f": "2e6a1a", "e": "f2cf5b", "m": "2e6a1a"},
	"modina": {"h": "1b1a24", "H": "1b1a24", "long": true, "s": "ea8a33", "S": "b85e1c", "c": "c8a060", "C": "8a6a3a", "v": "d8433a", "t": "d8433a", "q": "c8a060", "f": "6e4426", "e": "1b1a24", "m": "8a1e1a"},
	"modina_2": {"h": "e3ebf5", "H": "a8b0bc", "long": true, "s": "6b8ff0", "S": "2c4596", "c": "3b5dc9", "C": "2c4596", "v": "f2cf5b", "t": "f2cf5b", "q": "3b5dc9", "f": "1e2a6a", "e": "1b1a24", "m": "1e2a6a"},
	"evil_santa": {"h": "f2efe6", "H": "c8c0b0", "s": "f2c29a", "S": "c8a080", "c": "c8202a", "C": "f2efe6", "v": "f2efe6", "t": "1b1a24", "q": "c8202a", "f": "1b1a24", "e": "d8433a", "m": "f2efe6"},
	"vampire": {"h": "2a1e30", "H": "1b1a24", "s": "c8b8e8", "S": "a898c8", "c": "6a2a8a", "C": "3a1a5a", "v": "d8433a", "t": "f2efe6", "q": "2a1e30", "f": "1b1a24", "e": "d8433a", "m": "d8433a",
		"over": [[0, 6, ["kk........kk", "kkk......kkk", ".kk......kk."]]]},
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
	if not map.has("m"): map.m = "e8501e"
	if not map.has("b"): map.b = "4a2a1a"
	if not map.has("w"): map.w = "ffffff"
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
		px(base, 6, 5, Color("d8433a"))
		px(base, 9, 5, Color("d8433a"))
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
		"merchant", "tools", "trader":
			rect(img, 1, 3, 10, 3, col(map.get("cap", map.h)))
			rect(img, 7, 5, 5, 1, col(map.get("capH", map.H)))
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
			_overlay(img, [[3, 7, ["ggggggggg", "ggbbgbbgg", "ggwegwegg", "ggwegwegg", "gggggmmmg", ".gGGGGGg."]]], {"g": "5cbf3f", "G": "2e7a2a", "b": "1b1a24", "w": "ffffff", "e": "1b1a24", "m": "e8501e"})
		"the_fly":
			_overlay(img, [[2, 6, ["..kkkkkk...", ".kkkkkkkkk.", "kkkcCkcCkk.", "kkkCCkCCkk."]]], {"c": "a6e6f2", "C": "4fb6d0"})
		"wood_mask", "skull_mask":
			var m: Dictionary = {"X": "a8703f", "x": "6e4426"} if helmet == "wood_mask" else {"X": "f2ecd8", "x": "a89878"}
			_overlay(img, [[4, 8, [".XXXXXX", "XXkXXkX", "XXkXXkX", "XXXXXXX", ".XxxxX."]]], m)
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

# ---------------------------------------------------------------- the later worlds' monsters
func slug_img(c: Color, alt: bool) -> Image:
	var img := blank(24, 12)
	var sq := 1.0 if alt else 0.0
	ellipse(img, 11, 8 + sq * 0.5, 10 + sq, 3.5 - sq * 0.5, c)
	ellipse(img, 17, 5, 4, 4, c)
	ellipse(img, 8, 6.5, 4, 1.5, c.lightened(0.35))
	for sx in [16, 20]:
		rect(img, sx, 0, 1, 4, c.darkened(0.2))
		px(img, sx, 0, OUTLINE)
	px(img, 19, 5, OUTLINE)
	rect(img, 2, 10, 18, 2, c.darkened(0.3))
	return img

## The Forbidden City's dance lions (An An, Ji Ji, He He).
func lion_img(body: Color, mane: Color, alt: bool) -> Image:
	var img := blank(26, 18)
	var l := 1 if alt else 0
	ellipse(img, 10, 10, 9, 5, body)
	rect(img, 3 + l, 13, 3, 5, body.darkened(0.2))
	rect(img, 13 - l, 13, 3, 5, body.darkened(0.2))
	ellipse(img, 19, 7, 7, 7, mane)
	ellipse(img, 20, 8, 4.5, 4.5, body.lightened(0.15))
	rect(img, 19, 6, 2, 2, Color.WHITE)
	px(img, 20, 7, OUTLINE)
	rect(img, 21, 10, 4, 2, Color("d8433a"))
	rect(img, 18, 1, 3, 2, Color("f2cf5b"))
	rect(img, 0, 6 - l, 3, 2, mane)
	return img

func bird_img(c: Color, alt: bool) -> Image:
	var img := blank(20, 14)
	ellipse(img, 9, 8, 6, 4, c)
	ellipse(img, 15, 6, 3, 3, c)
	rect(img, 17, 6, 3, 1, Color("f2cf5b"))
	px(img, 16, 5, Color("d8433a"))
	if alt:
		ellipse(img, 8, 3, 5, 2.5, c.lightened(0.15))
	else:
		ellipse(img, 8, 12, 5, 2, c.lightened(0.15))
	rect(img, 1, 7, 4, 2, c)
	return img

## Fruit Loop's fruits, dressed for summer with little legs.
func fruit_img(kind: String, alt: bool) -> Image:
	var img := blank(18, 20)
	var l := 1 if alt else 0
	var leaf := Color("5cbf3f")
	match kind:
		"mango":
			ellipse(img, 9, 11, 7, 6, Color("f2a33a"))
			ellipse(img, 7, 9, 3, 2, Color("f2cf5b"))
			rect(img, 9, 3, 1, 3, Color("6e4426"))
			ellipse(img, 12, 4, 3, 1.5, leaf)
		"cherry":
			ellipse(img, 6, 12, 4.5, 4.5, Color("d8233a"))
			ellipse(img, 12, 12, 4.5, 4.5, Color("c81a2a"))
			for i in 6:
				px(img, 6 + i / 2, 7 - i, Color("3e8a2e"))
				px(img, 12 - i / 3, 7 - i, Color("3e8a2e"))
		"pineapple":
			ellipse(img, 9, 12, 6, 6, Color("f2cf5b"))
			for y in range(8, 18, 3):
				for x in range(4, 15, 3):
					px(img, x + (y / 3) % 2, y, Color("c99a2e"))
			for i in 4:
				rect(img, 6 + i * 2, 1 + (i % 2) * 2, 1, 6 - (i % 2) * 2, leaf)
		_:
			ellipse(img, 9, 11, 7, 6, Color("e83a4a"))
			for i in 7:
				px(img, 4 + (i * 5) % 11, 8 + (i * 3) % 7, Color("f2cf5b"))
			rect(img, 5, 4, 8, 2, leaf)
			rect(img, 8, 2, 2, 2, leaf)
	eyes(img, 9, 12, 10, 1)
	rect(img, 6 - l, 17, 2, 3, Color("3a3a48"))
	rect(img, 11 + l, 17, 2, 3, Color("3a3a48"))
	return img

## Eggcellence's cracked eggs: a white egg, the top shell broken, eyes peeking out.
func egg_img(spot: Color, alt: bool, legs := true) -> Image:
	var img := blank(16, 20)
	var l := 1 if alt else 0
	ellipse(img, 8, 11, 7, 8, Color("f8f4ea"))
	for i in 4:
		ellipse(img, 4 + i * 3, 6 + (i % 2) * 6, 1.5, 1.5, spot)
	for x in range(1, 16, 2):
		px(img, x, 6 + (x / 2) % 2, OUTLINE)
	rect(img, 3, 3, 10, 3, Color(0, 0, 0, 0))
	eyes(img, 7, 10, 8, 1, Color("d8433a"))
	if legs:
		rect(img, 4 - l, 18, 2, 2, Color("f2a33a"))
		rect(img, 10 + l, 18, 2, 2, Color("f2a33a"))
	return img

func turtle_img(shell: Color, skin: Color, alt: bool) -> Image:
	var img := blank(24, 14)
	var l := 1 if alt else 0
	ellipse(img, 11, 8, 9, 6, shell)
	for i in 3:
		ellipse(img, 6 + i * 5, 7, 2, 2, shell.lightened(0.3))
	ellipse(img, 20, 9, 3.5, 3, skin)
	px(img, 21, 8, OUTLINE)
	rect(img, 5 + l, 12, 3, 2, skin)
	rect(img, 14 - l, 12, 3, 2, skin)
	return img

func imp_img(alt: bool) -> Image:
	var img := blank(20, 18)
	var red := Color("c83a2a")
	for side in [-1, 1]:
		ellipse(img, 10 + side * 6, 7 - (2 if alt else 0), 4, 3, Color("5a1a2a"))
	ellipse(img, 10, 9, 4, 5, red)
	rect(img, 7, 2, 1, 3, red)
	rect(img, 12, 2, 1, 3, red)
	eyes(img, 9, 11, 7, 1, Color("f2cf5b"))
	for side in [-1, 1]:
		ellipse(img, 10 + side * 6, 12, 2, 2, Color("f2a33a"))
		px(img, 10 + side * 6, 10, Color("f2cf5b"))
	rect(img, 8, 14, 1, 3, red.darkened(0.3))
	rect(img, 11, 14, 1, 3, red.darkened(0.3))
	return img

func bunny_img(c: Color, alt: bool) -> Image:
	var img := blank(20, 22)
	var l := 1 if alt else 0
	rect(img, 6, 0, 3, 8, c)
	rect(img, 11, 1 + l, 3, 7, c)
	rect(img, 7, 2, 1, 5, Color("f0a0b0"))
	ellipse(img, 10, 15, 8, 7, c)
	ellipse(img, 10, 10, 5, 4, c)
	eyes(img, 8, 12, 9, 1, Color("d8433a"))
	rect(img, 9, 12, 3, 1, Color("f0a0b0"))
	rect(img, 4 - l, 20, 4, 2, c.darkened(0.2))
	rect(img, 12 + l, 20, 4, 2, c.darkened(0.2))
	return img

## The Tomb of Makara's coffins: an upright brown slab with a cross and red eyes.
func tombstone_img(alt: bool) -> Image:
	var img := blank(14, 22)
	var c := Color("8a5a32")
	rect(img, 1, 2, 12, 20, c)
	rect(img, 3, 0, 8, 2, c)
	rect(img, 2, 2, 2, 20, c.lightened(0.15))
	rect(img, 6, 4, 2, 8, Color("e2cf8e"))
	rect(img, 4, 6, 6, 2, Color("e2cf8e"))
	eyes(img, 5, 9, 14 + (1 if alt else 0), 1, Color("d8433a"))
	rect(img, 1, 20, 12, 2, c.darkened(0.3))
	return img

## Makara: a red-brown pyramid with a toothy grin.
func makara_img(alt: bool) -> Image:
	var img := blank(48, 40)
	var c := Color("a8482a")
	for y in 36:
		var hw := int(y * 0.66) + 1
		rect(img, 24 - hw, y + 2, hw * 2, 1, c if y % 6 else c.darkened(0.2))
	for y in 36:
		var hw := int(y * 0.66) + 1
		rect(img, 24 - hw, y + 2, mini(3, hw), 1, c.lightened(0.18))
	ellipse(img, 18, 20, 3, 3, Color("f2cf5b"))
	ellipse(img, 30, 20, 3, 3, Color("f2cf5b"))
	px(img, 18, 20, OUTLINE)
	px(img, 30, 20, OUTLINE)
	var g := 1 if alt else 0
	rect(img, 13, 27, 22, 6 + g, OUTLINE)
	for x in range(14, 34, 3):
		rect(img, x, 27, 2, 2, Color("f2efe6"))
		rect(img, x + 1, 31 + g, 2, 2, Color("f2efe6"))
	rect(img, 21, 0, 6, 3, Color("f2cf5b"))
	return img

func snowman_img(alt: bool) -> Image:
	var img := blank(14, 18)
	ellipse(img, 7, 12, 6, 5.5, Color("f2f6fa"))
	ellipse(img, 7, 5, 4.5, 4, Color("f2f6fa"))
	eyes(img, 5, 8, 4, 1)
	px(img, 7, 6, Color("ea8a33"))
	rect(img, 2, 8 + (1 if alt else 0), 10, 2, Color("d8433a"))
	px(img, 7, 11, OUTLINE)
	px(img, 7, 14, OUTLINE)
	return img

func big(img: Image, k: int) -> Image:
	img.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return img

## The boss version of a character: three times as big, with extras.
func boss_char(look: String, alt: bool) -> Image:
	var img := _char_img(look, "walk" if alt else "stand", 3)
	match look:
		"modina", "modina_2":
			# four swords, two on each side
			for side in [0, 1]:
				for k in 2:
					var x: int = 2 + side * 28 + k * 3
					rect(img, x, 22 + k * 6, 2, 22, Color("e3ebf5"))
					rect(img, x - 1, 40 + k * 6, 4, 2, Color("f2cf5b"))
		"evil_santa":
			rect(img, 6, 6, 26, 6, Color("c8202a"))
			rect(img, 30, 2, 6, 6, Color("c8202a"))
			rect(img, 34, 0, 4, 4, Color("f2efe6"))
			rect(img, 6, 12, 26, 3, Color("f2efe6"))
			rect(img, 9, 36, 20, 12, Color("f2efe6"))
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
			"slug": img = slug_img(Color("f2cf5b"), alt)
			"phantom_butterfly": img = wings_img(20, 16, Color("b8903a"), OUTLINE, alt, Color("1b1a24"))
			"demon_eye": img = eye_img(9, Color("8a1e2a"), false, false, true, alt)
			"imp": img = imp_img(alt)
			"demon_bat": img = bat_img(24, 13, Color("5a1a2a"), alt)
			"an_an": img = lion_img(Color("8a4ac8"), Color("f2cf5b"), alt)
			"ji_ji": img = lion_img(Color("5cbf3f"), Color("d8433a"), alt)
			"he_he": img = lion_img(Color("f2a33a"), Color("d8433a"), alt)
			"raven": img = bird_img(Color("2a2a3a"), alt)
			"grinch", "lich": img = _char_img(look, "walk" if alt else "stand", 1)
			"snow_turtle": img = turtle_img(Color("a6c8e0"), Color("e3f2f8"), alt)
			"fairy": img = wings_img(16, 14, Color("f0a8e8"), Color("f2efe6"), alt, Color("8affc8"))
			"mango", "cherry", "pineapple", "strawberry": img = fruit_img(look, alt)
			"egg_orange": img = egg_img(Color("f2a33a"), alt)
			"egg_blue": img = egg_img(Color("6b8ff0"), alt)
			"egg_purple": img = egg_img(Color("8a4ac8"), alt, false)
			"egg_clutch":
				img = blank(26, 18)
				for i in 3:
					var e := egg_img([Color("f2a33a"), Color("6b8ff0"), Color("8a4ac8")][i], alt, false)
					e.resize(10, 12, Image.INTERPOLATE_NEAREST)
					img.blend_rect(e, Rect2i(0, 0, 10, 12), Vector2i(i * 8, 3 + (i % 2) * 3 - (2 if alt else 0)))
			"chick": img = big(chick_img(alt), 2)
			"giant_chick": img = big(chick_img(alt), 3)
			"modina", "modina_2", "evil_santa": img = boss_char(look, alt)
			"doom": img = eye_img(22, Color("5a1e5a"), true, false, true, alt)
			"fortune_boss":
				var li := lion_img(Color("f2cf5b"), Color("d8433a"), alt)
				ellipse(li, 20, 8, 3.5, 3.5, Color("f8d8e8"))
				px(li, 19, 7, OUTLINE)
				px(li, 21, 7, OUTLINE)
				rect(li, 19, 9, 3, 1, Color("d8433a"))
				img = big(li, 3)
			"pineapple_killer":
				var pk := fruit_img("pineapple", alt)
				rect(pk, 1, 10, 3, 2, Color("3a3a48"))
				rect(pk, 14, 10 - (1 if alt else 0), 3, 2, Color("3a3a48"))
				eyes(pk, 8, 11, 10, 1, Color("d8433a"))
				img = big(pk, 3)
			"harakattu": img = big(bunny_img(Color("f2efe6"), alt), 3)
			# Tomb of Makara
			"sand_mantis": img = bug_img(18, 12, Color("e8a0a8"), Color("b06a7a"), alt)
			"tombstone": img = tombstone_img(alt)
			"vampire": img = _char_img(look, "walk" if alt else "stand", 1)
			"makara": img = makara_img(alt)
			# pets
			"grrr": img = trex_img(Color("8a4ac8"), Color("c8a0e8"), alt)
			"mini_ball": img = blob(Color("5a5a6a"), 10, 9, alt)
			"chick_aiai", "chick_cici", "chick_bibi", "chick_dede", "chick_fofo":
				img = chick_img(alt)
				var tint: Color = {"chick_aiai": Color("f06a5a"), "chick_cici": Color("5cbf3f"), "chick_bibi": Color("6b8ff0"), "chick_dede": Color("f2cf5b"), "chick_fofo": Color("a77ee0")}[look]
				for y in img.get_height():
					for x in img.get_width():
						var c := img.get_pixel(x, y)
						if c.a > 0.5 and c.is_equal_approx(Color("f2cf5b")):
							img.set_pixel(x, y, tint)
			"pet_bunny": img = bunny_img(Color("c8a070"), alt)
			"snowman": img = snowman_img(alt)
			"ne_ne": img = lion_img(Color("6b8ff0"), Color("f2efe6"), alt)
			"bunny_ghost": img = ghost_img(14, 16, Color("f8e8f0"), Color("e06a9a"), alt)
			"reaper": img = ghost_img(14, 16, Color("2a2a3a"), Color("8affc8"), alt)
			"moonwisp": img = flame_img(Color("a6e6f2"), alt)
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
	"bighammer": ["XXXXX.....", "XwXXXx....", "XXXXXx....", "XXXXXx....", ".xxnlx....", "....nl....", ".....nl...", "......nl..", ".......nl.", "........nl"],
	"fist": ["..........", "..XXXX....", ".XwXXXX...", ".XXXXXXk..", ".XxXxXXo..", ".XXXXXXk..", "..XXXXx...", "...xxx....", "..........", ".........."],
	"torch_i": ["....y.....", "...yoy....", "...oRo....", "....o.....", "....l.....", "....n.....", "....n.....", "....n.....", "....n.....", ".........."],
}

const MATERIAL_COLORS := [
	["topaz", "f2cf5b", "c98a2e"], ["sandnite", "f2e0a0", "c8a060"], ["makara", "a8482a", "6a2a14"], ["moonclipse", "f2cf5b", "8a9ab8"],
	["robo", "a8b0bc", "4fd0f0"], ["candy", "f06aa0", "f2efe6"], ["pops", "c8865a", "f06aa0"], ["popstick", "f2e08a", "c8a060"], ["carrot", "ea8a33", "5cbf3f"],
	["christmas", "3e9a3a", "d8433a"], ["ultimate", "f2cf5b", "d8433a"], ["pumpkin", "ea8a33", "3a2a22"], ["rainbow", "f06aa0", "6bc8f0"],
	["heartstone", "d8433a", "f2cf5b"], ["manastone", "3b6fd9", "f2cf5b"], ["muscle", "ea6a33", "8a1e1a"], ["shattered", "a77ee0", "3a2a5a"],
	["crown", "f2cf5b", "c99a2e"], ["royal", "a77ee0", "f2cf5b"], ["thors", "c8ced6", "d8433a"], ["w_cap", "3b5dc9", "f2efe6"], ["snowman", "f2f6fa", "d8433a"],
	["halloween", "ea8a33", "1b1a24"], ["ghost_dress", "e8eef2", "8a80b0"], ["x_wings", "c8ced6", "3b5dc9"], ["x_shield", "c8ced6", "3b5dc9"],
	["mithril", "c8e0f0", "7a90a8"], ["titan", "8a9099", "f2cf5b"], ["phase", "a77ee0", "4fb6d0"], ["lava", "ff5a2a", "3a1a1a"], ["firey", "f2a33a", "d8433a"],
	["yellow_fluor", "f2e05a", "c9a02e"], ["red_fluor", "f06a5a", "a82a22"], ["blue_fluor", "6bc8f0", "2c7ab0"], ["green_fluor", "7cf06a", "2e9a2a"], ["pink_fluor", "f08ac8", "b04a90"],
	["frost", "a6e6f2", "4fb6d0"], ["ice", "a6e6f2", "4fb6d0"], ["shadow", "3a3a48", "7b4fb8"], ["dream", "f06a5a", "f2cf5b"], ["chocolate", "6e4426", "3a2010"],
	["laser", "a8b0bc", "f06a5a"], ["pistol", "5c616b", "8a5a32"], ["rolva", "c8ced6", "4fb6d0"], ["firecracker", "d8433a", "f2cf5b"], ["ninja_star", "5c616b", "1b1a24"],
	["sun_extractor", "f2cf5b", "ea8a33"], ["devilween", "ea8a33", "5a2a6a"], ["refined", "c8a0e8", "7a5aa8"], ["mooncake", "c8865a", "f2cf5b"],
	["emperor", "f2cf5b", "d8433a"], ["snow_dress", "f2efe6", "a6c6d8"], ["dragon", "5cbf3f", "2e7a2a"], ["volcan_", "ff5a2a", "a8241a"],
	["sky", "a6e6f2", "4fb6d0"], ["unlawful", "8fb07a", "5e7a52"], ["dark_stone", "3e424a", "7b4fb8"],
	["modina", "ea8a33", "8a4a1a"], ["nightmare", "8a1e3a", "2a0a14"], ["long_lance", "e3ebf5", "6b8ff0"],
	["hazard", "f2cf5b", "3a3a48"], ["santa", "d8433a", "f2efe6"], ["lich", "8a4ac8", "3a1a5a"], ["fortune", "f2cf5b", "d8433a"],
	["blue_blade", "6b8ff0", "2c4596"], ["dark_heart", "8a1e2a", "2a0a14"], ["forbidden", "d8433a", "f2cf5b"],
	["tsurugi", "c8d8f0", "4a5a7a"],
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
		"em_stone", "ruby_stone", "sapphire_stone", "dark_stone", "sky_stone": return ["gem", mc]
		"dragon_spine": return ["bone", {"w": "a8e86a"}]
		"volcan_axe": return ["axe", mc]
		"sky_pole_axe": return ["pole", mc]
		"unlawful": return ["plunger", mc]
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
		"wall_hammer": return ["bighammer", {"X": "9aa2ad", "x": "5c616b"}]
		"kings_mace": return ["mace", mc]
		"devil_spike", "hell_spike", "hell_spike_2", "hell_spike_3": return ["spike", mc]
		"long_lance", "long_lance_2", "long_lance_3": return ["pole", mc]
		"blue_blade": return ["sword", mc]
		"dark_heart": return ["apple", {"X": "8a1e2a", "x": "2a0a14"}]
		"forbidden_stone": return ["gem", mc]
		"fortune_nugget": return ["lump", {"X": "f2cf5b", "x": "c99a2e"}]
		"honey": return ["blob", {"X": "f2b83a", "x": "c8802a"}]
		"eggency": return ["egg", {"X": "f2a33a"}]
		"nightmare_ingot": return ["bar", mc]
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
		"coin": return ["token", {"X": "f2cf5b", "x": "c99a2e"}]
		"combination_scroll": return ["scroll", {"X": "a77ee0"}]
		"missing_page": return ["scroll", {"X": "1b1a24"}]
		"missing_page_u": return ["scroll", {"X": "d8433a"}]
		"topaz_stone": return ["gem", {"X": "f2cf5b", "x": "c98a2e"}]
		"blue_board": return ["board", {"X": "6b8ff0", "x": "2c4596"}]
		"mooncake": return ["food", {"X": "c8865a", "x": "f2cf5b"}]
		"dragon_handle": return ["stick", {"n": "5cbf3f", "l": "2e7a2a", "g": "f2cf5b"}]
		"bone_of_makara": return ["bone", {"w": "e2cf8e"}]
		"skin_of_makara": return ["hide", {"X": "a8482a", "x": "6a2a14"}]
		"treasure_of_makara": return ["gem", {"X": "f2cf5b", "x": "a8482a"}]
		"evil_axe", "evil_axe_2", "evil_axe_u": return ["axe", mc]
		"hell_pole_axe": return ["pole", mc]
		"devil_spike_2", "devil_spike_3", "devil_spike_u": return ["spike", mc]
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
		"staff":
			if id.begins_with("iron_fist"):
				return ["fist", {"X": "c83a2a" if id == "iron_fist" else ("f2a33a" if id == "iron_fist_2" else ("f2cf5b" if id == "iron_fist_3" else "e3ebf5")), "x": "6a1e14"}]
			return ["staff", mc]
		"bow": return ["cannon", mc] if it.get("cannon", false) else ["bow", {}]
		"ammo": return ["balls", mc] if id.begins_with("cc_") or id == "devil_cannon_ball" else ["missile", mc]
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
			var bc := {"survival_book": "4f9a44", "combo_book_1": "3b5dc9", "combo_book_2": "d8433a", "combo_book_3": "f2a33a", "combo_book_4": "7b4fb8", "combo_book_5": "1b1a24",
				"combo_book_z": "5c616b", "combo_book_zx": "8a1e2a", "combo_book_u": "f2cf5b"}
			return ["book", {"X": bc.get(id, "3b5dc9"), "x": "1b1a24"}]
		"key":
			var kc := {"silver_key": "e3ebf5", "golden_key": "f2cf5b", "master_key": "d8433a"}
			return ["key", {"X": kc.get(id, "f2cf5b"), "x": "8a8a8a"}]
		"seed":
			var sc := {"green_seeds": "5cbf3f", "red_seeds": "d8433a", "golden_seeds": "f2cf5b"}
			return ["seed", {"X": sc.get(id, "5cbf3f"), "x": "1b1a24"}]
		"egg":
			var ec := {"green_egg": "5cbf3f", "pink_egg": "f06aa0", "purple_egg": "7b4fb8", "red_egg": "d8433a", "queen_egg": "f2cf5b", "king_egg": "5c616b",
				"blue_egg": "3b5dc9", "lunar_egg": "f2a33a", "easter_egg": "f08ac8", "christmas_egg": "d8433a", "halloween_egg": "ea8a33"}
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

## The same icon at double size, for the big bag and hotbar slots.
func icon_big(id: String) -> Texture2D:
	return cached("iconbig_" + id, func():
		var img: Image = icon(id).get_image()
		img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
		return to_tex(img))

# ---------------------------------------------------------------- world themes
const THEMES := {
	"grass": {"sky": ["6fb6dc", "bfe3ee"], "mount": "5a8c8a", "snow": "e8f2f2", "hills": "3f8a52", "top": "5cbf3f", "top2": "3e9a2e", "dirt": "8a5a32", "dirt2": "6e4426", "cave": "4a3020"},
	"dark": {"sky": ["2a2340", "5a4a6e"], "mount": "4a3e6a", "snow": "9a8ab0", "hills": "2e2a3e", "top": "6a5a8a", "top2": "4a3e66", "dirt": "3e3040", "dirt2": "2c2230", "cave": "1e1624"},
	"hell": {"sky": ["3a1020", "7a2a3a"], "mount": "5a1e3a", "snow": "c83a6a", "hills": "3a1028", "top": "8a3a6a", "top2": "5a2048", "dirt": "3a1a30", "dirt2": "2a1020", "cave": "1a0a14"},
	"ice": {"sky": ["9ad0f0", "e3f2f8"], "mount": "8ab0d0", "snow": "ffffff", "hills": "a6c8e0", "top": "e3f2f8", "top2": "a6d0e8", "dirt": "5a8ab0", "dirt2": "4a7098", "cave": "2a4a6a"},
	"dream": {"sky": ["f0a8d8", "fde2f2"], "mount": "c88ac8", "snow": "fff0fa", "hills": "a870c0", "top": "f08ac8", "top2": "c86aa8", "dirt": "7a4a8a", "dirt2": "5a3a6a", "cave": "3a2a4a"},
	"modina": {"sky": ["2a3a2a", "6a8a4a"], "mount": "3a4a36", "snow": "8ac85a", "hills": "2a3a28", "top": "7ab83a", "top2": "4a7a2a", "dirt": "4a3a3a", "dirt2": "3a2a2a", "cave": "1a1414"},
	"nightmare": {"sky": ["120a14", "4a1424"], "mount": "2a0e1a", "snow": "8a1e2a", "hills": "1e0a12", "top": "6a1e30", "top2": "3a1420", "dirt": "2a1218", "dirt2": "1e0c10", "cave": "0e060a"},
	"forbidden": {"sky": ["c8503a", "f2c27a"], "mount": "8a2a2a", "snow": "f2cf5b", "hills": "6a1e1e", "top": "c83a2a", "top2": "8a2a1e", "dirt": "5a2a1e", "dirt2": "3e1e14", "cave": "2a120c"},
	"snow": {"sky": ["1e2a4a", "5a7aa8"], "mount": "3a4a6a", "snow": "ffffff", "hills": "2a3a5a", "top": "f2f6fa", "top2": "c8d8e8", "dirt": "4a5a7a", "dirt2": "3a4a68", "cave": "1e2638"},
	"mushroom": {"sky": ["4a2a5a", "a86ac8"], "mount": "6a3a7a", "snow": "f2a33a", "hills": "4a2a5a", "top": "c86ac8", "top2": "8a4a9a", "dirt": "4a3040", "dirt2": "3a2030", "cave": "1e1220"},
	"fruit": {"sky": ["3ab8e0", "bff0f8"], "mount": "5ac8a8", "snow": "fff2a0", "hills": "3aa86a", "top": "f2e08a", "top2": "d8c06a", "dirt": "c8a060", "dirt2": "a8804a", "cave": "6a4a2a"},
	"egg": {"sky": ["a8e0f8", "fff6e0"], "mount": "c8e8a8", "snow": "fff0f8", "hills": "a8d88a", "top": "8ad86a", "top2": "6ab84a", "dirt": "d8b890", "dirt2": "b89870", "cave": "6a5040"},
	"tomb": {"sky": ["5a3a1e", "a8803a"], "mount": "6a4a2a", "snow": "e2cf8e", "hills": "4a3018", "top": "e2cf8e", "top2": "c8a060", "dirt": "c8a060", "dirt2": "a87a3a", "cave": "4a2e18"},
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
	if th.name == "tomb":
		# the tomb's sandy walls have a zig-zag pattern
		for x in 16:
			px(fill, x, 4 + absi((x % 8) - 4), th.dirt2)
			px(fill, x, 12 + absi((x % 8) - 4) - 4, th.dirt.lightened(0.15))
	var ledge := fill.duplicate()
	rect(ledge, 0, 0, 16, 3, th.dirt.lightened(0.18))
	for x in 16:
		px(ledge, x, 3 + (x * 7) % 2, th.dirt2)
	var tex := [to_tex(top), to_tex(fill), to_tex(back), to_tex(ledge)]
	_cache[key] = tex
	return tex

## A wall in the Tomb of Makara that kills on touch: dark red stone with spikes.
func deadly_tile(th: Dictionary) -> Texture2D:
	return cached("deadly_" + th.name, func():
		var img := blank(16, 16)
		img.fill(Color("5a1414"))
		for y in range(0, 16, 4):
			for x in range(0, 16, 4):
				px(img, x + 1, y + 1, Color("d8433a"))
				px(img, x + 2, y + 2, Color("f06a5a"))
		rect(img, 0, 0, 16, 1, Color("f06a5a"))
		rect(img, 0, 15, 16, 1, Color("2a0a0a"))
		return to_tex(img))

func node_tex(kind: String, th: Dictionary) -> Texture2D:
	return cached("node_%s_%s" % [kind, th.name], func():
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(kind)
		var img: Image
		var ore := {"copper": "e8864a", "iron": "8ab0d8", "silver": "e3ebf5", "gold": "f2cf5b", "erbium_rock": "e04a7a", "ice_rock": "a6e6f2", "volcanic_rock": "ff5a2a", "sandnite_rock": "f2e0a0"}
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
			"hammer_wall":
				# the massive stone wall in the east of Pixel Town
				img = blank(20, 48)
				rect(img, 0, 0, 20, 48, Color("4e535c"))
				for y in range(0, 48, 6):
					for x in range(0 if (y / 6) % 2 == 0 else -4, 20, 8):
						rect(img, x + 1, y + 1, 7, 5, Color("6e737c"))
						rect(img, x + 1, y + 1, 7, 1, Color("8a9099"))
				for k in 5:
					px(img, rng.randi_range(2, 17), rng.randi_range(2, 45), Color("2e3138"))
			"trade_wall":
				# rough wooden planks with vines, in front of the Trading Center
				img = blank(18, 48)
				for x in [0, 6, 12]:
					rect(img, x + 1, 0, 5, 48, Color("8a5a32"))
					rect(img, x + 1, 0, 1, 48, Color("a8703f"))
					rect(img, x + 2, 2, 3, 1, Color("5a3a1a"))
				for y in [8, 30]:
					rect(img, 0, y, 18, 3, Color("6e4426"))
				for k in 6:
					rect(img, rng.randi_range(0, 16), rng.randi_range(0, 44), 2, 4, Color("3e8a2e"))
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
				if th.name == "tomb": base = Color("8a6a4a")
				if kind == "volcanic_rock": base = Color("3a2a2e")
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
				# a dark iron stove on short legs; the window glows while smelting
				img = blank(16, 24)
				rect(img, 3, 0, 10, 2, Color("3e4a62"))
				rect(img, 1, 2, 14, 17, Color("2a3348"))
				rect(img, 2, 2, 12, 2, Color("4a5a78"))
				rect(img, 1, 18, 14, 2, Color("1e2436"))
				var lit: bool = state == "busy" or state == "done"
				rect(img, 3, 7, 10, 7, Color("e2501e") if lit else Color("0e0e16"))
				rect(img, 4, 8, 8, 5, Color("ff8a2a") if lit else Color("1b1a24"))
				if lit:
					rect(img, 5, 9, 6, 2, Color("ffc04a"))
				rect(img, 3, 14, 10, 1, Color("1e2436"))
				rect(img, 2, 20, 3, 4, Color("1e2436"))
				rect(img, 11, 20, 3, 4, Color("1e2436"))
			"chest":
				# keg-shaped chests like the original: wooden slats with coloured bands
				img = blank(20, 15)
				var band: Color = {"silver": Color("e3ebf5"), "golden": Color("f2cf5b"), "master": Color("c8a0e8"), "reward": Color("c8ced6")}.get(state, Color("c8ced6"))
				var wood: Color = Color("7b4fb8") if state == "master" else Color("b8642a")
				rect(img, 1, 1, 18, 13, wood)
				for x in range(3, 18, 3):
					rect(img, x, 1, 1, 13, wood.darkened(0.3))
				rect(img, 1, 1, 18, 2, wood.lightened(0.2))
				rect(img, 0, 0, 3, 15, band)
				rect(img, 17, 0, 3, 15, band)
				rect(img, 1, 0, 1, 15, band.darkened(0.25))
				rect(img, 18, 0, 1, 15, band.darkened(0.25))
				rect(img, 8, 9, 4, 4, band)
				px(img, 9, 10, OUTLINE)
				px(img, 10, 10, OUTLINE)
			"incubator":
				# a blue capsule with a dark window
				img = blank(16, 22)
				ellipse(img, 8, 11, 8, 11, Color("2c4596"))
				ellipse(img, 8, 11, 6, 9, Color("3b5dc9"))
				ellipse(img, 8, 10, 4, 6, Color("0e1a3a"))
				rect(img, 3, 19, 10, 3, Color("1e2a6a"))
				if state != "":
					ellipse(img, 8, 11, 2.5, 3.5, Color("f2efe6"))
					px(img, 7, 10, Color("5cbf3f"))
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
			"trade_table":
				# a trading table with a little scale on it
				img = blank(22, 16)
				rect(img, 0, 6, 22, 3, Color("a8703f"))
				rect(img, 0, 6, 22, 1, Color("c89058"))
				rect(img, 2, 9, 2, 7, Color("6e4426"))
				rect(img, 18, 9, 2, 7, Color("6e4426"))
				rect(img, 10, 0, 2, 6, Color("c99a2e"))
				rect(img, 5, 1, 12, 1, Color("c99a2e"))
				rect(img, 4, 2, 4, 2, Color("f2cf5b"))
				rect(img, 14, 2, 4, 2, Color("f2cf5b"))
			"board":
				# a signboard showing what's next to it (state = item id)
				img = blank(14, 18)
				rect(img, 6, 13, 2, 5, Color("4a2e14"))
				rect(img, 0, 0, 14, 14, Color("4a2e14"))
				rect(img, 1, 1, 12, 12, Color("8a4a1e"))
				if state != "" and Data.ITEMS.has(state):
					var ic: Image = icon(state).get_image()
					img.blend_rect(ic, Rect2i(0, 0, ic.get_width(), ic.get_height()), Vector2i(7 - ic.get_width() / 2, 7 - ic.get_height() / 2))
			"bubble":
				# a speech bubble with an item in it (state = item id)
				img = blank(16, 17)
				rect(img, 1, 0, 14, 14, Color("f2efe6"))
				rect(img, 0, 1, 16, 12, Color("f2efe6"))
				rect(img, 5, 14, 3, 2, Color("f2efe6"))
				px(img, 5, 16, Color("f2efe6"))
				if state != "" and Data.ITEMS.has(state):
					var ib: Image = icon(state).get_image()
					img.blend_rect(ib, Rect2i(0, 0, ib.get_width(), ib.get_height()), Vector2i(8 - ib.get_width() / 2, 7 - ib.get_height() / 2))
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

# ---------------------------------------------------------------- interface
const UI_GRIDS := {
	"backpack": ["...nnn....", "..n...n...", ".NNNNNNN..", "NnnnnnnnN.", "NnNNNNNnN.", "NnnyynnnN.", "NnnyynnnN.", "NnnnnnnnN.", ".NNNNNNN.."],
	"compass": ["..YYYY..", ".YwwwwY.", "YwwrwwwY", "YwwrwwwY", "YwwkwwwY", "YwwkwwwY", ".YwwwwY.", "..YYYY.."],
	"bomb": ["......yo", ".....n..", "...DDn..", ".DDDDDD.", "DDwwDDDD", "DwDwDDDD", "DDwwDDDD", "DDDDDDDD", ".DDDDDD.", "..DDDD.."],
	"hammer": [".aaaa.....", "aAAAAa....", "aAAAAan...", ".aaaa.nl..", "......nl..", ".......nl.", "........nl"],
	"trash": ["...kk...", "kkkkkkkk", ".kkkkkk.", ".kOkOkk.", ".kOkOkk.", ".kOkOkk.", ".kkkkkk."],
	"close": ["kk....kk", ".kk..kk.", "..kkkk..", "...kk...", "..kkkk..", ".kk..kk.", "kk....kk"],
	"plus": ["..g..", "..g..", "ggggg", "..g..", "..g.."],
}

## Small interface icons (backpack, compass, bomb, hammer, trash, close).
func ui_icon(name: String, scale: int = 1) -> Texture2D:
	return cached("ui_%s_%d" % [name, scale], func():
		var map := {"N": "6a3a4a", "n": "9a5a6a", "Y": "c99a2e", "O": "e8862a", "k": "5a2a10", "g": "f2cf5b"}
		var img := grid_image(UI_GRIDS[name], map, scale)
		if name in ["trash", "close", "plus"]:
			return to_tex(img)
		return to_tex(outline(img)))

## Faded placeholder for an empty equipment slot.
func equip_ghost(slot: String) -> Texture2D:
	return cached("ghost_" + slot, func():
		var g: String = {"helmet": "helmet", "armor": "armor", "shield": "shield", "ring_l": "ring", "ring_r": "ring", "pet": "egg"}.get(slot, "ring")
		var img := grid_image(ICON_GRIDS[g], {"X": "e8a050", "x": "d8903e", "w": "f0b868", "k": "d8903e"}, 2)
		return to_tex(img))

## Nine-slice frames for the orange interface. kind: frame, cell, button, button_down, green, tab
func ui_frame(kind: String) -> Texture2D:
	return cached("frame_" + kind, func():
		var img := blank(12, 12)
		var dark := Color("4a1e08")
		match kind:
			"frame":
				rect(img, 0, 0, 12, 12, dark)
				rect(img, 1, 1, 10, 10, Color("e8862a"))
				rect(img, 1, 1, 10, 1, Color("f8b050"))
				rect(img, 3, 3, 6, 6, Color("a8501a"))
				rect(img, 4, 4, 4, 4, Color("f9c98a"))
			"cell":
				rect(img, 0, 0, 12, 12, Color("c8803e"))
				rect(img, 1, 1, 10, 10, Color("f6b882"))
			"button", "button_down", "tab":
				var fill := Color("e8862a") if kind != "button_down" else Color("c86a1a")
				rect(img, 0, 0, 12, 12, dark)
				rect(img, 1, 1, 10, 10, fill)
				rect(img, 1, 1, 10, 2, fill.lightened(0.25))
				rect(img, 1, 9, 10, 2, fill.darkened(0.25))
				if kind == "tab":
					rect(img, 3, 3, 6, 6, Color("a8501a"))
			"green":
				rect(img, 0, 0, 12, 12, Color("0e3a0e"))
				rect(img, 1, 1, 10, 10, Color("2e9a1e"))
				rect(img, 1, 1, 10, 2, Color("5cc83a"))
				rect(img, 1, 9, 10, 2, Color("1e6a12"))
			"slot":
				rect(img, 0, 0, 12, 12, Color("7a4a26"))
				rect(img, 1, 1, 10, 10, Color("f6b882"))
			"slot_sel":
				rect(img, 0, 0, 12, 12, Color("1e8a12"))
				rect(img, 1, 1, 10, 10, Color("4fd040"))
				rect(img, 2, 2, 8, 8, Color("f6b882"))
		return to_tex(img))
