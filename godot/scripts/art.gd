extends Node
## All the pixel art, made in code. Characters and icons are text grids
## (one letter = one pixel); trees, rocks, slimes and mountains are generated.
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

# Character body; h/H hair, s/S skin, e eyes, c/C shirt, q/Q trousers, f shoes.
const BODY_TOP := [
	"...hhhhhh...",
	"..hhhhhhhhh.",
	".hhhhhhhhhhh",
	".hhhsssssh..",
	".hhssssess..",
	".hhssssessS.",
	"..hsssssss..",
	"...SSsssS...",
	"...cccccc...",
	"..cccCcccc..",
	"..sccCccsc..",
	"...cccccc...",
	"...qqqqqq...",
]
const LEGS_STAND := ["...qq..qq...", "...qq..qq...", "...ff..ff..."]
const LEGS_WALK := ["..qq....qq..", "..qq....qq..", "..ff....ff.."]
const LEGS_JUMP := ["...qq..qq...", "..ff....ff..", "............"]

const LOOKS := {
	"player": {"h": "6a3a1e", "H": "4a2814", "c": "3b5dc9", "C": "2c4596", "q": "3a3a52", "f": "2a2230", "e": "1b1a24"},
	"pip": {"h": "8a5a32", "H": "6e4426", "c": "4f9a44", "C": "3a7a32", "q": "5a4a3a", "f": "3a2a22", "e": "1b1a24"},
	"tilly": {"h": "f2cf5b", "H": "c99a2e", "c": "e06a9a", "C": "b0487a", "q": "6a3a6a", "f": "3a2a22", "e": "1b1a24"},
	"hollis": {"h": "d8d8d8", "H": "a8a8a8", "c": "8a5a32", "C": "6e4426", "q": "4a4a4a", "f": "2a2a2a", "e": "1b1a24"},
	"bram": {"h": "2a2230", "H": "1b1a24", "c": "7a7f88", "C": "5c616b", "q": "4a3428", "f": "2a2230", "e": "1b1a24"},
	"moss": {"h": "5cbf3f", "H": "3e8a2e", "c": "7b4fb8", "C": "5a3a8a", "q": "5a3a8a", "f": "2a2230", "e": "1b1a24"},
	"zombie": {"h": "3a3a2a", "H": "2a2a1e", "s": "8fb07a", "S": "5e7a52", "c": "6e5a3e", "C": "4a3e2a", "q": "3e4a5a", "f": "2a2230", "e": "d8433a"},
	"hell_knight": {"h": "3e424a", "H": "2a2c32", "s": "5c616b", "S": "3e424a", "c": "8a1e1a", "C": "5a1210", "q": "3e424a", "f": "1b1a24", "e": "f2a33a"},
	"cinder_lord": {"h": "f2a33a", "H": "d8433a", "s": "8a2416", "S": "5a1210", "c": "3a1210", "C": "1b0a08", "q": "3a1210", "f": "1b0a08", "e": "f2cf5b"},
}

const GRIDS := {
	"bee": [
		"...ww.....",
		"..wwww....",
		".yykyyky..",
		"yykyykyyk.",
		"yykyykyykk",
		".yykyyky..",
	],
	"shroom": [
		"...rrrrrr...",
		"..rrwrrrrr..",
		".rrrrrrwrrr.",
		"rrwrrrrrrrrr",
		"rrrrrrwrrrwr",
		"..wwwwwwww..",
		"..wwkwwkww..",
		"..wwwwwwww..",
		"...ww..ww...",
	],
	"boar": [
		".....nn.........",
		"....nNNnnnnnn...",
		"...nNnnnnnnnnn..",
		"..nnnnnnnnnnnnn.",
		".nnknnnnnnnnnnn.",
		"wnnnnnnnnnnnnnn.",
		"NNnnnnnnnnnnnnN.",
		".NnnnnnnnnnnnN..",
		"..nn.nn..nn.nn..",
		"..bb.bb..bb.bb..",
	],
	"bat": [
		"p....pp....p",
		"pp..pPPp..pp",
		"pppppPPppppp",
		".ppppppppp..",
		"..pp.rr.pp..",
		"......pp....",
	],
	"skeleton": [
		"...wwwwww...",
		"..wwwwwwww..",
		"..wwwkwwkw..",
		"..wwwwwwww..",
		"...wkwkww...",
		"....wwww....",
		"...aaaaaa...",
		"..wawawaww..",
		"..w.aaaa.w..",
		"....waaw....",
		"....w..w....",
		"....w..w....",
		"....w..w....",
		"...ww..ww...",
	],
	"imp": [
		".y......y...",
		".ry....yr...",
		"..rrrrrr....",
		".rrrkrrkrr..",
		".rrrrrrrrr..",
		"pp.rrRRrr.pp",
		"ppprrrrrrppp",
		".p.rrrrrr.p.",
		"...rr..rr...",
		"...y....y...",
	],
	"furnace": [
		"..DDDDDDDDDDDDDD..",
		".DaaaaAaaaaaAaaaD.",
		".DaAaaaaaAaaaaaaD.",
		".DaaaaaDDDDaaaAaD.",
		".DaaaaDDDDDDaaaaD.",
		".DaAaDoyyoyoDaaaD.",
		".DaaaDoyRRyoDaAaD.",
		".DaaaDrRrrRrDaaaD.",
		".DaAaDDDDDDDDaaaD.",
		".DaaaaaaAaaaaaaaD.",
		".DaaAaaaaaaaAaaaD.",
		"DDDDDDDDDDDDDDDDDD",
	],
	"torch": [
		"..y..",
		".yoy.",
		".oRo.",
		"..o..",
		"..l..",
		"..n..",
		"..n..",
		"..n..",
		"..n..",
		"..n..",
	],
	"wood_wall": [
		"nlnnlnnl",
		"nlnnlnnl",
		"NNNNNNNN",
		"lnnlnnln",
		"lnnlnnln",
		"NNNNNNNN",
		"nlnnlnnl",
		"nlnnlnnl",
		"NNNNNNNN",
		"lnnlnnln",
		"lnnlnnln",
		"NNNNNNNN",
		"nlnnlnnl",
		"nlnnlnnl",
		"NNNNNNNN",
		"lnnlnnln",
	],
	"stone_wall": [
		"aaaAaaaa",
		"aaaaaaAa",
		"DDDDDDDD",
		"AaaaDaaa",
		"aaaaDaaA",
		"DDDDDDDD",
		"aaAaaaaa",
		"aaaaaaDa",
		"DDDDDDDD",
		"aaaDaaAa",
		"AaaDaaaa",
		"DDDDDDDD",
		"aaaaAaaa",
		"aAaaaaaa",
		"DDDDDDDD",
		"aaaDaaaa",
	],
	"heart": [".rr.rr.", "rRrrrrr", "rrrrrrr", ".rrrrr.", "..rrr..", "...r..."],
	"coin": [".yyy.", "yYyyy", "yyYyy", "yyyYy", ".yyy."],
}

# ---------------------------------------------------------------- item icons (10x10, outlined to 12x12)
const ICON_GRIDS := {
	"log": ["..........", "......nnn.", ".....nlln.", "....nlnn..", "...nlnn...", "..nlnn....", ".nlnn.....", ".nnl......", "..........", ".........."],
	"lump": ["..........", "..........", "...XXXX...", "..XxXXXX..", ".XXXXXxXX.", ".XxXXXXXx.", ".XXXXxXXx.", "..xxxxxx..", "..........", ".........."],
	"ore": ["..........", "..........", "...aaaa...", "..aXaaAa..", ".aaaaXaaa.", ".aXaaaaXa.", ".aaaXaaaD.", "..DDDDDD..", "..........", ".........."],
	"bar": ["..........", "..........", "..........", "....XXXXX.", "...XXXXXx.", "..XXXXXxx.", ".xxxxxxx..", "..........", "..........", ".........."],
	"blob": ["..........", "....X.....", "...XXx....", "..XXXXx...", ".XXwXXXx..", ".XXXXXXx..", ".XXXXXxx..", "..xxxxx...", "..........", ".........."],
	"orb": ["..........", "...XXXX...", "..XwXXXx..", ".XwXXXXXx.", ".XXXXXXXx.", ".XXXXXXxx.", "..XXXXxx..", "...xxxx...", "..........", ".........."],
	"crystal": ["....X.....", "...XwX....", "..XwXXx...", "..XXXXx...", "..XXXxx...", "..XXXxx...", "...Xxx....", "....x.....", "..........", ".........."],
	"herb": ["..........", "....g.....", "...gGg....", "..g.G.g...", ".gG.G.Gg..", "..g.G.g...", "....G.....", "....G.....", "..........", ".........."],
	"fiber": ["..g.......", "..gG..g...", "...gG.gG..", "...yyyyy..", "....gG.g..", "...gG.gG..", "..gG...g..", "..g.......", "..........", ".........."],
	"bone": ["..........", ".ww.......", ".www......", "..www.....", "...www....", "....www...", ".....www..", "......ww..", "..........", ".........."],
	"scarab": ["..........", "...k..k...", "....kk....", "...uUUu...", "..uUuuUu..", "..uuUUuu..", "..uuuuuu..", "...u..u...", "..........", ".........."],
	"snowball": ["..........", "..........", "...wwww...", "..wwwwCw..", "..wwCwww..", "..wwwwww..", "...CwwC...", "..........", "..........", ".........."],
	"stinger": ["..........", "........k.", ".......kk.", "......yk..", ".....yy...", "....yk....", "...yy.....", "..yk......", "..........", ".........."],
	"leather": ["..........", ".nn....nn.", ".nlnnnnln.", "..nlllln..", "..nlllln..", "..nlllln..", ".nlnnnnln.", ".nn....nn.", "..........", ".........."],
	"wing": ["..........", "X.........", "XX......X.", "XxX....XX.", "XxxX..XxX.", ".XxxXXxxX.", "..XXxxXX..", "....XX....", "..........", ".........."],
	"mushroom": ["..........", "...rrrr...", "..rwrrwr..", ".rrrrrrrr.", "...wwww...", "...wwww...", "...wwww...", "..........", "..........", ".........."],
	"bandage": ["..........", "..........", ".wwwwwwww.", ".wwwrrwww.", ".wwrrrrww.", ".wwwrrwww.", ".wwwwwwww.", "..........", "..........", ".........."],
	"beetle": ["..........", "...k..k...", "....kk....", "...yYYy...", "..yYyyYy..", "..yyYYyy..", "..yyyyyy..", "...y..y...", "..........", ".........."],
	"bun": ["..........", "..........", "...oooo...", "..oyoyoo..", ".ooooyooo.", ".oyoooooo.", ".OOOOOOOO.", "..........", "..........", ".........."],
	"potion": ["..........", "....nn....", "....AA....", "...AXXA...", "..AXwXXA..", "..AXXXXA..", "..AxxxxA..", "...AAAA...", "..........", ".........."],
	"sword": [".........X", "........Xx", ".......Xx.", "......Xx..", ".....Xx...", ".k..Xx....", "..kXx.....", "..lk......", ".lk.k.....", "l........."],
	"club": ["......XXX.", ".....XXXXx", ".....XXXxx", "....XXxxx.", "...nlx....", "...nl.....", "..nl......", "..nl......", ".nl.......", ".n........"],
	"hammer": ["...XXXXX..", "..XwXXXXx.", "..XXXXXxx.", "...xxnxx..", ".....nl...", ".....nl...", "....nl....", "....nl....", "...nl.....", "...n......"],
	"wand": [".......X..", "......XwX.", ".......Xx.", "......n...", ".....nl...", "....nl....", "...nl.....", "..nl......", ".nl.......", ".n........"],
	"axe": ["....XXX...", "...XxXX...", "..nXxXX...", "..nlXX....", "..nl......", "..nl......", "..nl......", "..nl......", "..nl......", ".........."],
	"pick": ["..XXXXX...", ".Xx.n.xX..", "X...nl..X.", "....nl....", "....nl....", "....nl....", "....nl....", "....nl....", "..........", ".........."],
	"armor": ["..........", ".XX....XX.", ".XxXXXXxX.", "..XXXXXX..", "..XxXXxX..", "..XXXXXX..", "..XxxxxX..", "..........", "..........", ".........."],
	"helmet": ["..........", "...XXXX...", "..XwXXXX..", ".XXXXXXXX.", ".XXxxxxXX.", ".XX....XX.", ".Xx....xX.", "..........", "..........", ".........."],
	"crown": ["..........", ".X..X..X..", ".XX.XX.XX.", ".XXXXXXXX.", ".XwXXwXXX.", ".XXXXXXXX.", ".xxxxxxxx.", "..........", "..........", ".........."],
	"shield": ["..........", ".XXXXXXXX.", ".XwXXXXxX.", ".XXXxXXxX.", ".XXXxXXxX.", "..XXxXxX..", "...XxxX...", "....XX....", "..........", ".........."],
	"ring": ["..........", "....X.....", "...XwX....", "..xxXxx...", ".x.....x..", ".x.....x..", ".x.....x..", "..xxxxx...", "..........", ".........."],
	"book": ["..........", ".XXXXXXX..", ".XwwwwwXw.", ".XXXyXXXw.", ".XXyyyXXw.", ".XXXyXXXw.", ".XXXXXXXw.", ".xxxxxxxw.", "..wwwwww..", ".........."],
	"key": ["..........", "..XXX.....", ".X...X....", ".X...X....", "..XXXxxxxx", ".....x.x.x", ".......x.x", "..........", "..........", ".........."],
	"wall": ["nlnnlnnlnn", "NNNNNNNNNN", "lnnlnnlnnl", "NNNNNNNNNN", "nlnnlnnlnn", "NNNNNNNNNN", "lnnlnnlnnl", "NNNNNNNNNN", "nlnnlnnlnn", ".........."],
	"torch_i": ["....y.....", "...yoy....", "...oRo....", "....o.....", "....l.....", "....n.....", "....n.....", "....n.....", "....n.....", ".........."],
}

# icon shape + colours for each item
const ICONS := {
	"wood": ["log", {}], "stone": ["lump", {"X": "9aa2ad", "x": "5c616b"}], "herb": ["herb", {}], "fiber": ["fiber", {}],
	"jelly": ["blob", {"X": "5cbf3f", "x": "3e8a2e"}], "bone": ["bone", {}], "scarab": ["scarab", {}], "snowball": ["snowball", {}],
	"stinger": ["stinger", {}], "leather": ["leather", {}], "coal": ["lump", {"X": "3e424a", "x": "1b1a24"}],
	"iron_ore": ["ore", {"X": "e8b48a"}], "iron_bar": ["bar", {"X": "c8ced6", "x": "7a8290"}],
	"gold_ore": ["ore", {"X": "f2cf5b"}], "gold_bar": ["bar", {"X": "f2cf5b", "x": "c99a2e"}],
	"bat_wing": ["wing", {"X": "7b4fb8", "x": "a77ee0"}], "ectoplasm": ["blob", {"X": "8affc8", "x": "3ec88a"}],
	"ember": ["orb", {"X": "f2a33a", "x": "d8433a"}], "obsidian": ["crystal", {"X": "4a3e66", "x": "2a2240"}],
	"king_jelly": ["blob", {"X": "f2cf5b", "x": "c99a2e"}], "dark_flesh": ["blob", {"X": "a77ee0", "x": "5a3a8a"}],
	"fire_essence": ["orb", {"X": "ff6a3a", "x": "a8241a"}], "dust": ["lump", {"X": "c8b89a", "x": "8a7a62"}],
	"crystal": ["crystal", {"X": "a6e6f2", "x": "4fb6d0"}],
	"mushroom": ["mushroom", {}], "bandage": ["bandage", {}], "honey_beetle": ["beetle", {}], "honey_bun": ["bun", {}],
	"ice_jelly": ["blob", {"X": "a6e6f2", "x": "4fb6d0"}], "mana_potion": ["potion", {"X": "6b8ff0", "x": "3b5dc9"}],
	"wood_club": ["club", {"X": "a8703f", "x": "6e4426"}], "stone_sword": ["sword", {"X": "c8ced6", "x": "7a8290"}],
	"rusty_blade": ["sword", {"X": "d0905a", "x": "8a4a24"}], "iron_sword": ["sword", {"X": "e3ebf5", "x": "9fb0c8"}],
	"jelly_hammer": ["hammer", {"X": "f2cf5b", "x": "c99a2e"}], "gold_sword": ["sword", {"X": "f2cf5b", "x": "c99a2e"}],
	"dark_blade": ["sword", {"X": "a77ee0", "x": "5a3a8a"}], "cinder_blade": ["sword", {"X": "ff8a3a", "x": "d8433a"}],
	"fire_wand": ["wand", {"X": "f2a33a", "x": "d8433a"}],
	"wood_axe": ["axe", {"X": "a8703f", "x": "6e4426"}], "stone_axe": ["axe", {"X": "c8ced6", "x": "7a8290"}], "iron_axe": ["axe", {"X": "e3ebf5", "x": "9fb0c8"}],
	"wood_pick": ["pick", {"X": "a8703f", "x": "6e4426"}], "stone_pick": ["pick", {"X": "c8ced6", "x": "7a8290"}],
	"iron_pick": ["pick", {"X": "e3ebf5", "x": "9fb0c8"}], "gold_pick": ["pick", {"X": "f2cf5b", "x": "c99a2e"}],
	"leather_armor": ["armor", {"X": "a8703f", "x": "6e4426"}], "iron_armor": ["armor", {"X": "c8ced6", "x": "7a8290"}],
	"gold_armor": ["armor", {"X": "f2cf5b", "x": "c99a2e"}], "obsidian_armor": ["armor", {"X": "5a4a7a", "x": "2a2240"}],
	"leather_cap": ["helmet", {"X": "a8703f", "x": "6e4426"}], "iron_helmet": ["helmet", {"X": "c8ced6", "x": "7a8290"}],
	"gold_helmet": ["helmet", {"X": "f2cf5b", "x": "c99a2e"}], "jelly_crown": ["crown", {"X": "f2cf5b", "x": "5cbf3f"}],
	"wood_shield": ["shield", {"X": "a8703f", "x": "6e4426"}], "iron_shield": ["shield", {"X": "c8ced6", "x": "7a8290"}],
	"dark_shield": ["shield", {"X": "7b4fb8", "x": "3a2a5a"}],
	"stamina_ring": ["ring", {"X": "5cbf3f", "x": "c99a2e"}], "mana_ring": ["ring", {"X": "6b8ff0", "x": "c99a2e"}], "power_ring": ["ring", {"X": "d8433a", "x": "c99a2e"}],
	"wood_wall": ["wall", {}], "stone_wall": ["wall", {"n": "9aa2ad", "l": "c8ced6", "N": "5c616b"}], "torch": ["torch_i", {}],
	"survival_book": ["book", {"X": "4f9a44", "x": "2e6a2a"}], "combo_book_1": ["book", {"X": "3b5dc9", "x": "2c4596"}],
	"combo_book_2": ["book", {"X": "d8433a", "x": "8a1e1a"}], "combo_book_3": ["book", {"X": "1b1a24", "x": "4a3e66"}],
	"grass_key": ["key", {"X": "5cbf3f", "x": "3e8a2e"}], "dark_key": ["key", {"X": "a77ee0", "x": "5a3a8a"}], "hell_key": ["key", {"X": "f2a33a", "x": "d8433a"}],
}

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
	if v is Color:
		return v
	return Color(String(v))

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

# Adds a 1px dark outline around every opaque pixel.
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
				var px: int = x + d.x
				var py: int = y + d.y
				if px >= 0 and py >= 0 and px < w and py < h and img.get_pixel(px, py).a > 0.5:
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

func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, c)

# ---------------------------------------------------------------- characters
func character_rows(legs: Array) -> Array:
	return BODY_TOP + legs

func character(look: String, frame: String = "stand", scale: int = 1) -> Texture2D:
	return cached("char_%s_%s_%d" % [look, frame, scale], func():
		var legs = {"stand": LEGS_STAND, "walk": LEGS_WALK, "jump": LEGS_JUMP}[frame]
		var map: Dictionary = LOOKS[look].duplicate()
		var img := grid_image(character_rows(legs), map, scale)
		return to_tex(outline(img)))

func character_flash(look: String) -> Texture2D:
	return cached("charflash_" + look, func():
		var img := outline(grid_image(character_rows(LEGS_STAND), LOOKS[look]))
		return to_tex(flash_image(img)))

# ---------------------------------------------------------------- monsters
func slime_image(body: Color, w: int, h: int, crown: bool = false, squash: bool = false) -> Image:
	var hh := h - 2 if squash else h
	var ww := w + 2 if squash else w
	var top := 6 if crown else 0
	var img := Image.create(ww, hh + top, false, Image.FORMAT_RGBA8)
	var light := body.lightened(0.35)
	var dark := body.darkened(0.3)
	ellipse(img, ww / 2.0, top + hh * 0.62, ww / 2.0, hh * 0.62, body)
	img.fill_rect(Rect2i(1, top + hh - 2, ww - 2, 2), dark)
	ellipse(img, ww * 0.32, top + hh * 0.38, ww * 0.12, hh * 0.12, light)
	var ey := top + int(hh * 0.5)
	var e1 := int(ww * 0.55)
	var e2 := int(ww * 0.78)
	var es := 2 if ww > 20 else 1
	img.fill_rect(Rect2i(e1, ey, es, es + 1), OUTLINE)
	img.fill_rect(Rect2i(e2, ey, es, es + 1), OUTLINE)
	if crown:
		var cx := ww / 2 - 6
		var gold := Color("f2cf5b")
		img.fill_rect(Rect2i(cx, top - 2, 12, 3), gold)
		for i in 3:
			img.fill_rect(Rect2i(cx + i * 5, top - 5, 2, 3), gold)
		img.set_pixel(cx + 6, top - 1, Color("d8433a"))
	return img

func eye_image() -> Image:
	var img := Image.create(24, 26, false, Image.FORMAT_RGBA8)
	ellipse(img, 12, 11, 11, 11, Color("7b4fb8"))
	ellipse(img, 12, 11, 8, 8, Color("f2efe6"))
	ellipse(img, 14, 11, 4, 5, Color("d8433a"))
	ellipse(img, 15, 11, 2, 3, OUTLINE)
	img.set_pixel(13, 9, Color.WHITE)
	for i in 4:
		var x := 5 + i * 4
		img.fill_rect(Rect2i(x, 20, 2, 3 + (i % 2) * 3), Color("5a3a8a"))
	return img

func mob_frames(sprite: String) -> Array:
	# returns [normal, alternate, flash]
	return [mob_tex(sprite, false), mob_tex(sprite, true), mob_tex(sprite, false, true)]

func mob_tex(sprite: String, alt: bool, flash: bool = false) -> Texture2D:
	return cached("mob_%s_%s_%s" % [sprite, alt, flash], func():
		var img: Image
		match sprite:
			"slime":
				img = slime_image(Color("5cbf3f"), 14, 11, false, alt)
			"dark_slime":
				img = slime_image(Color("7b4fb8"), 16, 12, false, alt)
			"magma_slime":
				img = slime_image(Color("e8602a"), 18, 13, false, alt)
			"slime_king":
				img = slime_image(Color("4fb04a"), 40, 30, true, alt)
			"gloom_eye":
				img = eye_image()
				if alt:
					img.fill_rect(Rect2i(0, 20, 24, 6), Color(0, 0, 0, 0))
					for i in 4:
						img.fill_rect(Rect2i(5 + i * 4, 20, 2, 6 - (i % 2) * 3), Color("5a3a8a"))
			"zombie", "hell_knight":
				img = grid_image(character_rows(LEGS_WALK if alt else LEGS_STAND), LOOKS[sprite])
			"cinder_lord":
				img = grid_image(character_rows(LEGS_WALK if alt else LEGS_STAND), LOOKS[sprite], 2)
			_:
				var rows: Array = GRIDS[sprite]
				if alt and sprite in ["bee", "bat", "imp"]:
					rows = rows.duplicate()
					rows[0] = rows[0].replace("w", ".").replace("p", ".")
				img = grid_image(rows)
		img = outline(img)
		if flash:
			img = flash_image(img)
		return to_tex(img))

# ---------------------------------------------------------------- items
func icon(id: String) -> Texture2D:
	return cached("icon_" + id, func():
		var def = ICONS.get(id, ["lump", {"X": "ff00ff", "x": "880088"}])
		return to_tex(outline(grid_image(ICON_GRIDS[def[0]], def[1]))))

# ---------------------------------------------------------------- world
func ground_tiles(zone: Dictionary) -> Array:
	var key: String = "ground_" + zone.name
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(zone.name)
	var top := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	top.fill(zone.dirt)
	for i in 10:
		top.set_pixel(rng.randi_range(0, 15), rng.randi_range(6, 15), zone.dirt2)
	top.fill_rect(Rect2i(0, 0, 16, 5), zone.top)
	for x in 16:
		var d := rng.randi_range(4, 7)
		top.fill_rect(Rect2i(x, 0, 1, d), zone.top)
		top.set_pixel(x, d, zone.top2)
	for i in 4:
		top.set_pixel(rng.randi_range(0, 15), rng.randi_range(0, 2), zone.top.lightened(0.25))
	var fill := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	fill.fill(zone.dirt)
	for i in 14:
		var c: Color = zone.dirt2 if i % 3 else zone.dirt.lightened(0.12)
		fill.fill_rect(Rect2i(rng.randi_range(0, 14), rng.randi_range(0, 14), 2, 1), c)
	var tex := [to_tex(top), to_tex(fill)]
	_cache[key] = tex
	return tex

func node_tex(kind: String, zone: Dictionary) -> Texture2D:
	return cached("node_%s_%s" % [kind, zone.name], func():
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(kind)
		var img: Image
		match kind:
			"tree", "ash_tree":
				img = Image.create(26, 40, false, Image.FORMAT_RGBA8)
				var trunk := Color("6e4426") if kind == "tree" else Color("2a2222")
				img.fill_rect(Rect2i(11, 20, 5, 20), trunk)
				img.fill_rect(Rect2i(12, 20, 1, 20), trunk.lightened(0.2))
				var leaf := Color("3e9a3a") if kind == "tree" else Color("5a2a22")
				var light := Color("6ccf4a") if kind == "tree" else Color("e8602a")
				for c in [[13, 11, 11, 10], [7, 16, 7, 6], [19, 16, 7, 6], [13, 6, 8, 6]]:
					ellipse(img, c[0], c[1], c[2], c[3], leaf)
				for c in [[10, 8, 4, 3], [16, 12, 3, 2], [7, 14, 3, 2]]:
					ellipse(img, c[0], c[1], c[2], c[3], light)
				for i in 6:
					img.set_pixel(rng.randi_range(4, 22), rng.randi_range(6, 20), leaf.darkened(0.3))
			"dead_tree":
				img = Image.create(22, 38, false, Image.FORMAT_RGBA8)
				var t := Color("4a3e4a")
				img.fill_rect(Rect2i(9, 8, 4, 30), t)
				img.fill_rect(Rect2i(3, 12, 7, 2), t)
				img.fill_rect(Rect2i(3, 6, 2, 7), t)
				img.fill_rect(Rect2i(12, 16, 7, 2), t)
				img.fill_rect(Rect2i(17, 9, 2, 8), t)
				img.fill_rect(Rect2i(10, 2, 2, 7), t)
			"rock", "iron_rock", "gold_rock", "obsidian_rock":
				img = Image.create(18, 13, false, Image.FORMAT_RGBA8)
				var base := Color("8a9099") if kind != "obsidian_rock" else Color("3a2e4a")
				ellipse(img, 9, 8, 9, 6, base)
				ellipse(img, 7, 6, 5, 3, base.lightened(0.2))
				img.fill_rect(Rect2i(2, 11, 14, 2), base.darkened(0.3))
				var spec := {"iron_rock": Color("e8b48a"), "gold_rock": Color("f2cf5b"), "obsidian_rock": Color("a77ee0")}
				if spec.has(kind):
					for i in 7:
						img.fill_rect(Rect2i(rng.randi_range(3, 13), rng.randi_range(4, 10), 2, 1), spec[kind])
			"bush":
				img = Image.create(18, 11, false, Image.FORMAT_RGBA8)
				for c in [[5, 6, 5, 5], [12, 6, 6, 5], [9, 4, 5, 4]]:
					ellipse(img, c[0], c[1], c[2], c[3], Color("3e9a3a"))
				ellipse(img, 7, 4, 2, 2, Color("6ccf4a"))
				for p in [[5, 6], [11, 5], [14, 8], [8, 8]]:
					img.set_pixel(p[0], p[1], Color("f2efe6"))
			"mushrooms":
				img = Image.create(16, 10, false, Image.FORMAT_RGBA8)
				for m in [[4, 4, 4], [11, 3, 5]]:
					img.fill_rect(Rect2i(m[0] - 1, m[1] + 2, 2, 6 - m[1] + 2), Color("e8dccb"))
					ellipse(img, m[0], m[1] + 1, m[2], 2.5, Color("a77ee0"))
					img.set_pixel(m[0] - 1, m[1], Color("f2efe6"))
		return to_tex(outline(img)))

func prop_tex(kind: String) -> Texture2D:
	return cached("prop_" + kind, func():
		if GRIDS.has(kind):
			return to_tex(outline(grid_image(GRIDS[kind])))
		return null)

func house_tex(wall: Color, roof: Color) -> Texture2D:
	return cached("house_%s_%s" % [wall.to_html(), roof.to_html()], func():
		var img := Image.create(52, 46, false, Image.FORMAT_RGBA8)
		img.fill_rect(Rect2i(4, 20, 44, 26), wall)
		for y in range(22, 46, 4):
			img.fill_rect(Rect2i(4, y, 44, 1), wall.darkened(0.15))
		for i in 20:
			img.fill_rect(Rect2i(i, 20 - i, 52 - i * 2, 1), roof if i % 3 else roof.darkened(0.2))
		img.fill_rect(Rect2i(21, 32, 10, 14), Color("6e4426"))
		img.set_pixel(29, 39, Color("f2cf5b"))
		img.fill_rect(Rect2i(8, 27, 8, 7), Color("a6e6f2"))
		img.fill_rect(Rect2i(36, 27, 8, 7), Color("a6e6f2"))
		img.fill_rect(Rect2i(11, 27, 1, 7), OUTLINE)
		img.fill_rect(Rect2i(39, 27, 1, 7), OUTLINE)
		return to_tex(outline(img)))

func portal_tex(frame: int, tint: Color) -> Texture2D:
	return cached("portal_%d_%s" % [frame, tint.to_html()], func():
		var img := Image.create(18, 34, false, Image.FORMAT_RGBA8)
		ellipse(img, 9, 17, 9, 17, tint.darkened(0.4))
		ellipse(img, 9, 17, 7, 14, tint)
		ellipse(img, 9, 17, 4, 9, tint.lightened(0.4))
		for i in 6:
			var a := frame * 0.8 + i * 1.05
			img.set_pixel(int(9 + cos(a) * 5), int(17 + sin(a) * 11), Color.WHITE)
		return to_tex(outline(img)))

func mountains_tex(zone: Dictionary) -> Texture2D:
	return cached("mount_" + zone.name, func():
		var w := 512
		var h := 150
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var peaks := [[40, 70], [120, 40], [200, 80], [270, 30], [350, 64], [430, 46], [500, 74]]
		for x in w:
			var top := h
			for p in peaks:
				for o in [-w, 0, w]:
					var d := absf(x - (p[0] + o))
					top = mini(top, int(p[1] + d * 0.9))
			img.fill_rect(Rect2i(x, top, 1, h - top), zone.mount)
			for p in peaks:
				for o in [-w, 0, w]:
					var d2 := absf(x - (p[0] + o))
					var py: int = p[1] + int(d2 * 0.9)
					if py == top and d2 < 16:
						var depth := 10 - int(d2 / 3) + (int(x * 7) % 3)
						img.fill_rect(Rect2i(x, top, 1, maxi(depth, 2)), zone.snow)
		return to_tex(img))

func hills_tex(zone: Dictionary) -> Texture2D:
	return cached("hills_" + zone.name, func():
		var w := 512
		var h := 90
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var c: Color = zone.hills
		for i in 40:
			var x := rng.randi_range(0, w)
			var r := rng.randi_range(10, 22)
			for o in [-w, 0, w]:
				ellipse(img, x + o, h - 30 + rng.randi_range(-6, 6), r, r * 1.3, c)
				ellipse(img, x + o - r * 0.3, h - 36, r * 0.4, r * 0.4, c.lightened(0.12))
		img.fill_rect(Rect2i(0, h - 20, w, 20), c)
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
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		img.fill_rect(Rect2i(1, 0, w - 2, h), OUTLINE)
		img.fill_rect(Rect2i(0, 1, w, h - 2), OUTLINE)
		img.fill_rect(Rect2i(2, 2, w - 4, h - 4), c)
		img.fill_rect(Rect2i(2, h - 5, w - 4, 3), c.darkened(0.3))
		img.fill_rect(Rect2i(3, 3, w - 6, 2), c.lightened(0.25))
		return to_tex(img))
