extends Node
## All the pixel art, made in code: villagers from text grids, monsters and
## scenery from simple shapes, and item icons from templates coloured by material.
## Every sprite gets a dark outline added automatically.

const OUTLINE := Color("1b1a24")
const ItemIcons := preload("res://scripts/item_icons.gd")
var _cache := {}
var font_body: Font # menus and the HUD
var font_title: Font
var font_world: Font # names and numbers in the world (seen through the 2x camera)
var font_world_title: Font

const PAL := {
	"k": "1b1a24", "w": "f2efe6", "s": "f2c29a", "S": "d49a72", "b": "3a2a22",
	"r": "d8433a", "R": "f06a5a", "y": "f2cf5b", "Y": "c99a2e", "o": "ea8a33", "O": "b85e1c",
	"g": "5cbf3f", "G": "3e8a2e", "n": "8a5a32", "N": "6e4426", "l": "a8703f",
	"a": "9aa2ad", "A": "c8ced6", "d": "5c616b", "D": "3e424a",
	"i": "b8c4d6", "I": "e3ebf5", "u": "3b5dc9", "U": "6b8ff0", "p": "7b4fb8", "P": "a77ee0",
	"c": "4fb6d0", "C": "a6e6f2", "m": "e06a9a", "z": "8fb07a", "Z": "5e7a52",
	"W": "c4c2d8", "K": "4e4c6c", "B": "a82a36",
}

# ---------------------------------------------------------------- characters
# Chibi people on a 12-wide grid: a big head (9 rows), a small body (5) and
# legs (3), lit from the top left. Every colour is a short ramp: the base, a
# shadow shifted toward blue-violet and a highlight shifted toward yellow
# (see shade()), instead of plain darker and lighter copies.
# Channels: h hair (^ its shine, H its shadow), s skin (5 shine, S shadow),
# e eyes (w their glint), + blush, m mouth, c clothes (L lit, C shadow),
# v collar, t tie or trim, 1 2 sleeves (lit, shaded), 3 4 hands, j belt or
# skirt, q legs, f shoes; J Q F are their shadows. Missing channels fall back.
const PAD := 4 # empty rows above the head for hats
const HEADS := {
	"short": [
		"...hhhhhh...",
		"..h^^hhhhh..",
		".h^hhhhhhhH.",
		".hhhhhhhhhH.",
		".Hhhhsshsss.",
		".Hhssweswes.",
		".Hhsseesees.",
		"..Hs+ssmss+.",
		"...SsssssS..",
	],
	"bald": [
		"...ssssss...",
		"..s55sssss..",
		".s5sssssssS.",
		".sssssssssS.",
		".Ssssssssss.",
		".Ssssweswes.",
		".Sssseesees.",
		"..Ss+ssmss+.",
		"...SsssssS..",
	],
	# a cloth hood with only the eyes showing (x is the skin in the slit)
	"hood": [
		"...hhhhhh...",
		"..h^^hhhhh..",
		".h^hhhhhhhH.",
		".hhhhhhhhhH.",
		".HhhhhhhhhH.",
		".Hhxxwexwex.",
		".Hhxxeexeex.",
		"..HhhhhhhhH.",
		"...HhhhhhH..",
	],
	# a metal head with a dark visor and two lit eyes
	"robot": [
		"..ssssssss..",
		".s55sssssSS.",
		".s5ssssssSS.",
		".sssssssssS.",
		".sskkkkkkkk.",
		".sskkeekeek.",
		".sskkkkkkkk.",
		".sssssssssS.",
		"..SSSSSSSS..",
	],
}
const BODIES := {
	"stand": ["...LcvtvC...", "..1ccctcC2..", "..1ccctcC2..", "..3cccccC4..", "...jjjjjJ..."],
	"stride": ["...LcvtvC...", "..1ccctcC2..", ".1.ccctcC.2.", ".3.cccccC.4.", "...jjjjjJ..."],
	"up": [".3.LcvtvC.4.", "..1ccctcC2..", "...ccctcC...", "...cccccC...", "...jjjjjJ..."],
}
const LEGS := {
	"stand": ["...qq..qQ...", "...qq..qQ...", "...fff.ffF.."],
	"step_a": ["...qq..qQ...", "..qq....qQ..", ".ff.....ffF."],
	"pass": ["....qqQ.....", "....qqQ.....", "....fffF...."],
	"step_b": ["...qQ..qq...", "..qQ....qq..", ".fF.....fff."],
	"tuck": ["...qq..qQ...", "..ff....fF..", "............"],
	"fall": ["...qq..qQ...", "...qq..qQ...", "...ff..fF..."],
}
## Each frame: the arms, the legs, and how far the head and body sink (the
## bob of a step or a breath) while the feet stay on the ground.
const FRAME_DEF := {
	"stand": ["stand", "stand", 0], "idle": ["stand", "stand", 1],
	"walk0": ["stride", "step_a", 1], "walk1": ["stand", "pass", 0],
	"walk2": ["stand", "step_b", 1], "walk3": ["stride", "pass", 0],
	"jump": ["up", "tuck", 0], "fall": ["up", "fall", 0],
	"walk": ["stride", "step_a", 1],
}
const FRAMES := ["stand", "idle", "walk0", "walk1", "walk2", "walk3", "jump", "fall"]
# over: head extras (hair, hats, glasses) as [x, y, rows], y counted from the
# top of the hat space (the head starts at y = PAD, the eyes are at y = 9).
# wear: clothing details on the body, hidden when armour is worn.
const _NINJA_OVER := [[1, 7, ["rrrrrrrrrr"]], [0, 8, ["Rr"]], [0, 9, [".R"]]]
const _BOT_OVER := [[5, 1, [".a.", ".A."]], [5, 3, ["aAa"]], [2, 5, ["k"]], [2, 6, ["k"]]]
const _BOT_WEAR := [[5, 14, ["tt"]], [5, 15, ["tt"]], [3, 16, ["CCCCCC"]]]
const _BUN_EARS := [[3, 0, [".s...s..", "sps.sps.", "sps.sps.", "sps.sps.", "sss.sss."]]]
var LOOKS := {
	# playable characters
	"man_in_suit": {"h": "3a2a3e", "c": "34405e", "v": "f4f1ea", "t": "e0453c", "j": "2a2f48", "q": "34405e", "f": "1f1c2c",
		"wear": [[4, 14, ["CvtvC"]], [5, 15, ["Ct"]]]},
	"nurse": {"h": "b06a3c", "long": true, "c": "f4f1ea", "v": "f4f1ea", "t": "f4f1ea", "j": "f4f1ea", "q": "f6c5a0", "f": "f4f1ea",
		"over": [[3, 1, [".wwwwww.", "wwwrrwww", "wwrrrrww", ".WWWWWW."]]],
		"wear": [[6, 14, ["r"]], [3, 17, ["wwwwwW"]]]},
	"cavemun": {"h": "7a4a22", "s": "e0a070", "c": "f09030", "v": "e0a070", "t": "f09030", "j": "f09030", "sl": "e0a070", "q": "e0a070", "f": "c07848",
		"over": [[1, 2, ["..h..h.h.h..", ".hhh^hhhhhh."]], [1, 8, ["h"]], [10, 7, ["H"]]],
		"wear": [[3, 13, ["s"]], [3, 14, ["ss"]], [6, 15, ["O"]], [4, 16, ["O"]], [3, 18, ["c.c.c."]]]},
	"pirate": {"h": "2a2233", "c": "f4f1ea", "v": "f4f1ea", "t": "f4f1ea", "j": "8a5a32", "q": "34405e", "f": "6e4426",
		"over": [[1, 3, ["..rrrrrr...", ".rRRrrrrrr.", "rrrrrrrrrrD"]], [0, 6, ["rD"]], [0, 7, [".r"]], [3, 8, ["kkkkkkkk"]], [8, 9, ["kk"]], [8, 10, ["kk"]]],
		"wear": [[3, 14, ["rrrrrr"]], [3, 16, ["rrrrrr"]], [6, 17, ["y"]]]},
	"the_spi": {"h": "2a2233", "c": "2c2a3a", "v": "f4f1ea", "t": "2c2a3a", "j": "2c2a3a", "q": "2c2a3a", "f": "1f1c2c",
		"over": [[4, 9, ["kkkkkkk", ".kK.kK."]]],
		"wear": [[4, 14, ["CvkvC"]], [6, 15, ["k"]]]},
	"bad_man": {"h": "3e3e4c", "s": "4a4a5a", "m": "3e3e4c", "e": "f4f1ea", "w": "f4f1ea", "c": "5a5a6e", "v": "5a5a6e", "t": "3e3e4c", "j": "3e3e4c", "q": "3e3e4c", "f": "2a2a36", "head": "bald",
		"over": [[4, 8, ["kk..kk"]]]},
	"school_girl": {"h": "2a2233", "long": true, "c": "f4f1ea", "v": "3f66d0", "t": "e0453c", "j": "3f66d0", "q": "f6c5a0", "f": "2a2233",
		"over": [[1, 7, ["r"]]],
		"wear": [[3, 17, ["jjjjjJ"]], [2, 18, ["jJjJjJJ"]]]},
	"soldier": {"h": "6a4424", "c": "6f9450", "v": "6f9450", "t": "6f9450", "j": "4a3426", "q": "587a3c", "f": "4a3426",
		"over": [[1, 2, ["..zzzzzz...", ".zzZzzzzzz.", "zzzzzzZzzzz", "zzZzzzzzzzZ", "ZZZZZZZZZZZ"]]],
		"wear": [[4, 14, ["C"]], [7, 15, ["C"]], [6, 17, ["y"]]]},
	"chuchu": {"h": "f58ac8", "long": true, "c": "f470a8", "v": "f4f1ea", "t": "f4f1ea", "j": "f470a8", "q": "f6c5a0", "f": "f4f1ea",
		"over": [[0, 1, [".hh......hh.", "h^hh....h^hH", "hhhh....hhhH", ".HH......HH."]]],
		"wear": [[3, 17, ["jjjjjJ"]], [2, 18, ["jjjjjJJ"]]]},
	"drone": {"s": "aab4c4", "e": "5fe0ff", "c": "8894a6", "v": "aab4c4", "t": "5fe0ff", "j": "5c6676", "q": "6c7686", "f": "444c5a", "head": "robot",
		"over": [[6, 0, ["r", "a", "a", "a"]], [2, 5, ["k"]], [2, 6, ["k"]]],
		"wear": [[5, 14, ["tt"]], [3, 16, ["CCCCCC"]]]},
	"dark_knight": {"s": "5c4a8a", "e": "ff5a4a", "c": "5c4a8a", "v": "9a6ae0", "t": "9a6ae0", "j": "3a2c5c", "q": "443468", "f": "2a2040", "head": "robot",
		"over": [[4, 0, [".rr.", "rRr.", "rr..", "r..."]], [1, 7, ["PPPPPPPPPP"]], [1, 11, ["pppppppppp"]]],
		"wear": [[5, 14, ["tt"]], [3, 16, ["CttttC"]]]},
	"ninja": {"h": "2c2a3a", "x": "f6c5a0", "c": "2c2a3a", "v": "2c2a3a", "t": "e0453c", "j": "e0453c", "q": "2c2a3a", "f": "1f1c2c", "head": "hood", "gl": "2c2a3a",
		"over": _NINJA_OVER, "wear": [[4, 14, ["C..C"]], [5, 15, ["CC"]]]},
	"ninja_npc": {"h": "34407a", "x": "f6c5a0", "c": "34407a", "v": "34407a", "t": "e0453c", "j": "e0453c", "q": "34407a", "f": "1f1c2c", "head": "hood", "gl": "34407a",
		"over": _NINJA_OVER, "wear": [[4, 14, ["C..C"]], [5, 15, ["CC"]]]},
	"ninja_npc2": {"h": "8a2c3a", "x": "f6c5a0", "c": "8a2c3a", "v": "8a2c3a", "t": "f4cf5a", "j": "f4cf5a", "q": "8a2c3a", "f": "1f1c2c", "head": "hood", "gl": "8a2c3a", "r": "f4cf5a", "R": "c99a2e",
		"over": _NINJA_OVER, "wear": [[4, 14, ["C..C"]], [5, 15, ["CC"]]]},
	"ninja_npc3": {"h": "5a3c8a", "x": "f6c5a0", "c": "5a3c8a", "v": "5a3c8a", "t": "f470a8", "j": "f470a8", "q": "5a3c8a", "f": "1f1c2c", "head": "hood", "gl": "5a3c8a", "r": "f470a8", "R": "c84a80",
		"over": _NINJA_OVER, "wear": [[4, 14, ["C..C"]], [5, 15, ["CC"]]]},
	"robot_npc": {"s": "aab4c4", "e": "5fe0ff", "c": "aab4c4", "v": "aab4c4", "t": "5fe0ff", "j": "5c6676", "q": "6c7686", "f": "444c5a", "head": "robot", "over": _BOT_OVER, "wear": _BOT_WEAR},
	"robot_npc2": {"s": "f4cf5a", "e": "ff5a4a", "c": "f4cf5a", "v": "f4cf5a", "t": "ff5a4a", "j": "b07a20", "q": "c99a2e", "f": "444c5a", "head": "robot", "over": _BOT_OVER, "wear": _BOT_WEAR},
	"robot_npc3": {"s": "5cd0b4", "e": "f4f1ea", "c": "5cd0b4", "v": "5cd0b4", "t": "f4cf5a", "j": "2a8474", "q": "2e9a86", "f": "444c5a", "head": "robot", "over": _BOT_OVER, "wear": _BOT_WEAR},
	"iron_bot": {"s": "6b8ff0", "e": "f4cf5a", "c": "6b8ff0", "v": "6b8ff0", "t": "f4a33a", "j": "2c4596", "q": "3f5cc0", "f": "444c5a", "head": "robot", "over": _BOT_OVER, "wear": _BOT_WEAR},
	"backstreet_boy": {"h": "f4cf5a", "c": "f4f1ea", "v": "f4f1ea", "t": "f4f1ea", "j": "3f66d0", "q": "3f66d0", "f": "f4f1ea",
		"over": [[2, 2, ["..hh^^hhh..", ".h^^hhhhhhh", "hhhhhhhhhHH"]], [9, 5, ["hhH"]]],
		"wear": [[5, 14, ["u"]], [5, 15, ["uu"]]]},
	"sailor_moons": {"h": "f4cf5a", "c": "f4f1ea", "v": "3f66d0", "t": "e0453c", "j": "3f66d0", "q": "f6c5a0", "f": "e0453c",
		"over": [[0, 2, [".h........h.", "h^h......h^H", ".h........H."]], [0, 5, ["h"]], [0, 6, ["h"]], [0, 7, ["hh"]], [0, 8, ["hH"]], [0, 9, ["hH"]], [0, 10, ["h"]], [0, 11, ["h"]], [0, 12, ["H"]],
			[11, 5, ["h"]], [11, 6, ["h"]], [11, 7, ["H"]], [11, 8, ["H"]], [11, 9, ["H"]], [11, 10, ["H"]], [6, 5, ["y"]]],
		"wear": [[3, 17, ["jjjjjJ"]], [2, 18, ["jJjJjJJ"]]]},
	# the buns: bunny ears over a furry head
	"q_bun": {"p": "f5a0b8", "s": "f8f4ec", "m": "f5a0b8", "c": "f58ac8", "v": "f4f1ea", "t": "f58ac8", "j": "f58ac8", "q": "f8f4ec", "f": "f58ac8", "head": "bald",
		"over": _BUN_EARS},
	"mad_bun": {"p": "e0453c", "s": "aab4c4", "e": "e0453c", "m": "5c6676", "c": "34344a", "v": "e0453c", "t": "34344a", "j": "2a2a3a", "q": "34344a", "f": "1f1c2c", "head": "bald",
		"over": _BUN_EARS + [[4, 8, ["kk..kk"]]]},
	"nerd_bun": {"p": "f5a0b8", "s": "e6b48c", "m": "a86a4a", "c": "3f66d0", "v": "f4f1ea", "t": "f4cf5a", "j": "34407a", "q": "5a5a6e", "f": "4a3426", "head": "bald",
		"over": _BUN_EARS + [[3, 9, ["kkIikIik"]], [4, 10, ["kiikiik"]]]},
	# villagers
	"keeper": {"h": "4a3478", "c": "8a5ad0", "v": "f4cf5a", "t": "f4cf5a", "j": "5a3c8a", "q": "4a3478", "f": "2a2040", "s": "f0bc90",
		"over": [[1, 0, ["....PP.....", "...PPpp....", "..PPpppp...", ".PPyppppp..", "pppppppppp."]]],
		"wear": [[3, 17, ["yyyyyy"]]]},
	"gruff": {"h": "c04a1c", "c": "7a6644", "v": "7a6644", "t": "7a6644", "j": "4a3426", "q": "5a4632", "f": "2a2233", "s": "f4c080", "sl": "f4c080",
		"over": [[0, 1, ["..hhh^hhh...", ".hh^^hhhhhh.", "hh^hhhhhhhhh", "hhhhhhhhhhhH"]], [0, 5, ["h"]], [0, 6, ["hh"]], [0, 7, ["hh"]], [0, 8, ["hhh"]], [0, 9, ["hH"]], [0, 10, ["hH"]], [0, 11, ["HH"]],
			[4, 10, [".hhhhhh", "hhhhhhh"]], [5, 12, ["HHHH"]]]},
	"mira": {"h": "2a2233", "s": "f4c080", "long": true, "c": "f0c840", "v": "f0c840", "t": "f0c840", "j": "f0c840", "q": "f4c080", "f": "4a3426",
		"wear": [[3, 17, ["jjjjjJ"]], [2, 18, ["jjjjjJJ"]]]},
	"banka": {"h": "f6dc50", "s": "f4c080", "c": "d870d8", "v": "d870d8", "t": "d870d8", "j": "d870d8", "q": "f4c080", "f": "4a3426",
		"over": [[0, 6, ["r"]], [0, 7, ["hh"]], [0, 8, ["hH"]], [0, 9, ["hH"]], [0, 10, [".H"]], [11, 6, ["r"]], [10, 7, ["hh"]], [10, 8, [".H"]], [10, 9, [".H"]]],
		"wear": [[3, 17, ["jjjjjJ"]], [2, 18, ["jjjjjJJ"]]]},
	"warden": {"h": "2a2a36", "s": "3aaa5c", "m": "1e6a3a", "c": "4a5e4a", "v": "4a5e4a", "t": "4a5e4a", "j": "2a2a36", "q": "3e3e52", "f": "1f1c2c", "head": "bald",
		"over": [[1, 2, ["..kkkkkkk..", ".kkKkkkkkk.", "kkkkkkkkkkk", "DDDDDDDDDDD"]]],
		"wear": [[6, 17, ["a"]]]},
	"smith": {"h": "4a3426", "c": "8a6642", "v": "c8a070", "t": "8a6642", "j": "5a4028", "q": "5a4632", "f": "2a2233", "s": "d09060",
		"over": [[4, 11, ["hhhhhh"]], [5, 12, ["HHHH"]]],
		"wear": [[4, 14, ["llll"]], [4, 15, ["llll"]], [4, 16, ["lllN"]]]},
	"merchant": {"h": "f6dc50", "s": "f4c080", "c": "c0bcb0", "v": "c0bcb0", "t": "c0bcb0", "j": "3e3e52", "q": "3e3e52", "f": "2a2233",
		"over": [[0, 0, ["..h...h..h..", "h.hh.hhh.hh.", "hhh^hhhhhhhh", ".h^^hhhhhhhH", "hhhhhhhhhhhH"]], [0, 5, ["h"]], [11, 5, ["H"]], [0, 7, ["h"]]]},
	"tools": {"h": "5a321e", "c": "e0453c", "v": "e0453c", "t": "3f66d0", "j": "3f66d0", "q": "3f66d0", "f": "6e4426",
		"over": [[1, 3, ["..rrrrrr...", ".rRRrwwrrr.", "rrrrrrrrrrr", "DDDDDDDrrrrr"]], [6, 11, ["bbbbb"]]],
		"wear": [[4, 14, ["u..u"]], [3, 15, ["uuuuuU"]], [3, 16, ["uyuuyU"]]]},
	"miner": {"h": "f4cf5a", "c": "7a6644", "v": "7a6644", "t": "7a6644", "j": "4a3426", "q": "5a5a6e", "f": "2a2233",
		"over": [[1, 2, ["...yyyyy...", "..yyyyywwy.", ".yyyyyywwyY", "YYYYYYYYYYY"]]],
		"wear": [[4, 14, ["N..N"]], [4, 15, ["N..N"]]]},
	"trader": {"h": "7a4a22", "c": "f4cf5a", "v": "f4f1ea", "t": "4f9a44", "j": "4a3426", "q": "5a4632", "f": "2a2233",
		"over": [[1, 3, ["..gggggg...", ".ggGggggggg", "gggggggggGG", "ZZZZZZZggggg"]]]},
	"jumpie": {"h": "2a2233", "s": "f4c080", "long": true, "c": "5cc040", "v": "f4f1ea", "t": "5cc040", "j": "5cc040", "q": "f4c080", "f": "4a3426",
		"over": [[8, 3, ["rr", "rR"]]],
		"wear": [[3, 17, ["jjjjjJ"]], [2, 18, ["jjjjjJJ"]]]},
	# monsters that are drawn as people
	"zombie": {"h": "3e3e2a", "s": "94b87c", "m": "4a6a42", "c": "7a6644", "j": "5a4632", "q": "465468", "f": "2a2233", "e": "e0453c", "w": "f4cf5a",
		"wear": [[4, 15, ["C"]], [7, 14, ["C"]], [6, 16, ["s"]]]},
	"wizard": {"h": "e8e4f0", "s": "f0c8a4", "c": "3f66d0", "v": "f4cf5a", "t": "3f66d0", "j": "f4cf5a", "q": "3f66d0", "f": "2c4596",
		"over": [[0, 0, ["......uu....", ".....uuU....", "....uyuU....", "...uuuuUU...", "..uuuuuuUU..", "UUUUUUUUUUUU"]], [4, 11, ["hhhhhh"]], [5, 12, ["hhhh"]], [5, 13, [".HH."]]],
		"wear": [[3, 18, ["cccccC"]], [3, 19, ["cccccC"]]]},
	"lich": {"h": "4a3478", "s": "ecebf4", "c": "6a34a0", "v": "8affc8", "t": "6a34a0", "j": "4a2470", "q": "4a2470", "f": "2a2040", "e": "8affc8", "w": "f4f1ea", "m": "4a3478", "head": "bald",
		"over": [[0, 2, ["...hhhhhh...", "..h^hhhhhhh.", ".hhhhhhhhhhH", ".hhh......hH", ".hh........H", ".hh.........", ".hh........."]]],
		"wear": [[3, 18, ["cccccC"]], [3, 19, ["cccccC"]]]},
	"grinch": {"h": "58a030", "s": "74d040", "c": "e0453c", "v": "f4f1ea", "t": "e0453c", "j": "f4f1ea", "q": "58a030", "f": "2e6a1a", "e": "f4cf5a", "w": "f4f1ea", "m": "2e6a1a", "head": "bald",
		"over": [[1, 1, ["......rrw..", "....rrrr...", "..rrRrrrr..", ".rrrrrrrrr.", "wwwwwwwwwww"]]]},
	"modina": {"h": "2a2233", "long": true, "s": "f09040", "c": "d0a868", "v": "e0453c", "t": "e0453c", "j": "8a6a3a", "q": "d0a868", "f": "6e4426", "m": "8a1e1a",
		"over": [[4, 8, ["kk..kk"]], [5, 3, ["yyy"]], [6, 4, ["r"]]]},
	"modina_2": {"h": "e6eef8", "long": true, "s": "6b8ff0", "c": "3f66d0", "v": "f4cf5a", "t": "f4cf5a", "j": "2c4596", "q": "3f66d0", "f": "1e2a6a", "m": "1e2a6a",
		"over": [[4, 8, ["kk..kk"]], [5, 3, ["yyy"]], [6, 4, ["c"]]]},
	"evil_santa": {"h": "f4f1ea", "s": "f6c5a0", "c": "d02830", "v": "f4f1ea", "t": "f4f1ea", "j": "2a2233", "q": "d02830", "f": "2a2233", "e": "e0453c",
		"over": [[4, 8, ["kk..kk"]], [3, 11, ["wwwwwww"]], [4, 12, ["wwwwww"]], [5, 13, ["WWWW"]]],
		"wear": [[6, 17, ["y"]]]},
	"vampire": {"h": "2a2233", "s": "d0c0f0", "c": "2a2233", "v": "f4f1ea", "t": "e0453c", "j": "2a2233", "q": "2a2233", "f": "1f1c2c", "e": "e0453c", "m": "e0453c",
		"over": [[5, 3, ["h"]], [5, 4, ["hh"]], [1, 11, ["r"]], [10, 11, ["r"]], [8, 12, ["w"]]],
		"wear": [[1, 12, ["P", "P", "P", "P", "P", "P", "P"]], [10, 12, ["p", "p", "p", "p", "p", "p", "p"]], [4, 14, ["CvtvC"]]]},
	"mummy": {"h": "ece4cc", "s": "ece4cc", "c": "ece4cc", "v": "ece4cc", "t": "ece4cc", "j": "ece4cc", "q": "ece4cc", "f": "c0b8a0", "e": "e0453c", "w": "f4cf5a", "m": "ece4cc", "head": "bald"},
}
# Character hats show the matching character's headwear when worn.
const HAT_LOOKS := {"pirate_hat": "pirate", "soldier_helmet": "soldier", "spy_mask": "the_spi", "chuu_hat": "chuchu",
	"trooper_pro": "drone", "dark_night": "dark_knight", "bad_mask": "bad_man"}

func _ready() -> void:
	# Smooth, round letters instead of pixel ones (Brenden, 2026-11-06: "make the
	# words on the screen non pixelated and just smooth white letters with black
	# outline"). Fredoka, OFL. The world copy is drawn 8x finer, because the
	# camera's 2x zoom would otherwise blow its letters up into blocks.
	var ui: FontFile = load("res://fonts/Fredoka.ttf")
	ui.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	# No hinting and quarter-pixel placement: hinted or whole-pixel letters land
	# unevenly once the 480x270 screen is stretched to the phone, so gaps came
	# and went between letters (Brenden, 2026-11-06: "the writing looks weird").
	ui.hinting = TextServer.HINTING_NONE
	ui.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_ONE_QUARTER
	var world: FontFile = ui.duplicate()
	world.oversampling = 8.0
	font_body = _weight(ui, 600)
	font_title = _weight(ui, 700)
	font_world = _weight(world, 600)
	font_world_title = _weight(world, 700)

func _weight(f: FontFile, w: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = f
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): w}
	return v

## How thick a text outline is for a font size. A third of the letter height
## (the old fixed 3) swallowed the gaps between small letters, so they ran
## together: Brenden's "writing looks weird". About a fifth reads cleanly.
func outline_for(size: int) -> int:
	return clampi(roundi(size * 0.2), 1, 8)

## Gives a label in the world the smooth world font, sampled smoothly.
func world_text(l: Label, title: bool = false) -> void:
	l.add_theme_font_override("font", font_world_title if title else font_world)
	l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

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
	return ink(cartoon(src), color)

## The cartoon finish every outlined sprite gets: colours a bit brighter and
## punchier, a light rim along the top and left edges and a shadow along the
## bottom and right, so flat shapes look rounded.
func cartoon(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var img := src.duplicate()
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if c.v < 0.2:
				continue # leave eyes and dark details crisp
			c = Color.from_hsv(c.h, minf(c.s * 1.15, 1.0), minf(c.v * 1.05, 1.0), c.a)
			if _clear(src, x, y - 1):
				c = shade(c, 0.55)
			elif _clear(src, x, y + 1):
				c = shade(c, -0.8)
			elif _clear(src, x - 1, y):
				c = shade(c, 0.25)
			elif _clear(src, x + 1, y):
				c = shade(c, -0.45)
			img.set_pixel(x, y, c)
	return img

## Rounds a flat sprite: within each column the top quarter is lit and the bottom
## third shaded, the right edge a little darker, and a small shine sits up on
## the top left. Eyes and dark details (near black or near white) are left as
## they are. cartoon() then adds its rim on top, for four tones in all.
func volume(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var img := src.duplicate()
	var top := PackedInt32Array()
	var bot := PackedInt32Array()
	top.resize(w)
	bot.resize(w)
	var lo := Vector2i(w, h)
	var hi := Vector2i(-1, -1)
	for x in w:
		top[x] = -1
		for y in h:
			if src.get_pixel(x, y).a > 0.5:
				if top[x] < 0:
					top[x] = y
				bot[x] = y
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	if hi.x < 0:
		return img
	var left := PackedInt32Array()
	var right := PackedInt32Array()
	left.resize(h)
	right.resize(h)
	for y in h:
		left[y] = -1
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				if left[y] < 0:
					left[y] = x
				right[y] = x
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a < 0.5 or c.v < 0.22 or (c.s < 0.08 and c.v > 0.92):
				continue
			var span := bot[x] - top[x]
			if span < 4:
				continue
			var t := float(y - top[x]) / span
			if t < 0.28:
				c = shade(c, 0.25)
			elif t > 0.66:
				c = shade(c, -0.5)
			if right[y] - left[y] >= 5 and x >= right[y] - 1 and x > left[y] + 2:
				c = shade(c, -0.25)
			img.set_pixel(x, y, c)
	# the shine
	var bw := hi.x - lo.x
	var bh := hi.y - lo.y
	if bw >= 8 and bh >= 7:
		var sp := Vector2i(lo.x + int(bw * 0.28), lo.y + int(bh * 0.24))
		for r in 3:
			var hit := false
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var q := sp + Vector2i(dx, dy)
					if hit or q.x < 0 or q.y < 0 or q.x + 1 >= w or q.y >= h:
						continue
					var a := src.get_pixel(q.x, q.y)
					var b := src.get_pixel(q.x + 1, q.y)
					if a.a > 0.5 and b.a > 0.5 and a.v >= 0.22 and b.v >= 0.22 and a.s >= 0.08 and q.y > top[q.x] and q.y > top[q.x + 1]:
						img.set_pixel(q.x, q.y, a.lerp(Color.WHITE, 0.6))
						img.set_pixel(q.x + 1, q.y, b.lerp(Color.WHITE, 0.4))
						hit = true
			if hit:
				break
	return img

func _clear(img: Image, x: int, y: int) -> bool:
	return x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height() or img.get_pixel(x, y).a < 0.5

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

## A shiny faceted lump of ore set in rock: lit top left, shaded bottom right.
func nugget(img: Image, x: int, y: int, c: Color) -> void:
	px(img, x + 1, y, c.lightened(0.45))
	px(img, x + 2, y, c)
	px(img, x, y + 1, c)
	px(img, x + 1, y + 1, c)
	px(img, x + 2, y + 1, c.darkened(0.3))
	px(img, x + 1, y + 2, c.darkened(0.45))

## A thin crystal standing up out of the rock: a light face, a dark face and a
## bright pointed tip. `y` is where it leaves the rock.
func shard(img: Image, x: int, y: int, h: int, c: Color) -> void:
	for yy in range(y - h + 2, y + 3):
		px(img, x, yy, c.lightened(0.3))
		px(img, x + 1, yy, c.darkened(0.2))
	px(img, x, y - h + 1, c.lightened(0.6))
	px(img, x, y - h + 3, Color(1, 1, 1, 0.9))

# ---------------------------------------------------------------- clean upscaling
## Makes pixel art bigger without the jagged staircase look: Scale2x and Scale3x
## round off diagonal edges, so big bosses and big icons look drawn, not blown up.
func upscale(src: Image, k: int) -> Image:
	match k:
		1: return src
		2: return _scale2x(src)
		3: return _scale3x(src)
		4: return _scale2x(_scale2x(src))
		6: return _scale2x(_scale3x(src))
	var img := src.duplicate()
	img.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return img

func _at(img: Image, x: int, y: int) -> Color:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return Color(0, 0, 0, 0)
	var c := img.get_pixel(x, y)
	return c if c.a > 0.01 else Color(0, 0, 0, 0)

func _scale2x(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var img := Image.create(w * 2, h * 2, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var e := _at(src, x, y)
			var b := _at(src, x, y - 1)
			var d := _at(src, x - 1, y)
			var f := _at(src, x + 1, y)
			var hh := _at(src, x, y + 1)
			var e0 := e
			var e1 := e
			var e2 := e
			var e3 := e
			if b != hh and d != f:
				e0 = d if d == b else e
				e1 = f if b == f else e
				e2 = d if d == hh else e
				e3 = f if hh == f else e
			img.set_pixel(x * 2, y * 2, e0)
			img.set_pixel(x * 2 + 1, y * 2, e1)
			img.set_pixel(x * 2, y * 2 + 1, e2)
			img.set_pixel(x * 2 + 1, y * 2 + 1, e3)
	return img

func _scale3x(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var img := Image.create(w * 3, h * 3, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var a := _at(src, x - 1, y - 1)
			var b := _at(src, x, y - 1)
			var c := _at(src, x + 1, y - 1)
			var d := _at(src, x - 1, y)
			var e := _at(src, x, y)
			var f := _at(src, x + 1, y)
			var g := _at(src, x - 1, y + 1)
			var hh := _at(src, x, y + 1)
			var i := _at(src, x + 1, y + 1)
			var o := [e, e, e, e, e, e, e, e, e]
			if b != hh and d != f:
				o[0] = d if d == b else e
				o[1] = b if (d == b and e != c) or (b == f and e != a) else e
				o[2] = f if b == f else e
				o[3] = d if (d == b and e != g) or (d == hh and e != a) else e
				o[5] = f if (b == f and e != i) or (hh == f and e != c) else e
				o[6] = d if d == hh else e
				o[7] = hh if (d == hh and e != i) or (hh == f and e != g) else e
				o[8] = f if hh == f else e
			for k in 9:
				img.set_pixel(x * 3 + k % 3, y * 3 + k / 3, o[k])
	return img

# ---------------------------------------------------------------- smooth shapes
## Soft, anti-aliased shapes drawn at a higher resolution and shown scaled down,
## for the clean cartoon parts: shadows, glows, the touch buttons and clouds.
func _cover(dist: float) -> float:
	return clampf(0.5 - dist, 0.0, 1.0)

func _mix(img: Image, x: int, y: int, c: Color, k: float) -> void:
	if k <= 0.0 or x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, img.get_pixel(x, y).blend(Color(c.r, c.g, c.b, c.a * k)))

func soft_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color, feather := 1.0) -> void:
	for y in range(int(cy - ry - feather) - 1, int(cy + ry + feather) + 2):
		for x in range(int(cx - rx - feather) - 1, int(cx + rx + feather) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			var dist := (sqrt(dx * dx + dy * dy) - 1.0) * minf(rx, ry)
			_mix(img, x, y, c, clampf(0.5 - dist / feather, 0.0, 1.0))

func soft_rrect(img: Image, x0: float, y0: float, w: float, h: float, r: float, c: Color) -> void:
	for y in range(int(y0) - 1, int(y0 + h) + 2):
		for x in range(int(x0) - 1, int(x0 + w) + 2):
			var qx := absf(x + 0.5 - (x0 + w / 2)) - (w / 2 - r)
			var qy := absf(y + 0.5 - (y0 + h / 2)) - (h / 2 - r)
			var dist := Vector2(maxf(qx, 0), maxf(qy, 0)).length() + minf(maxf(qx, qy), 0.0) - r
			_mix(img, x, y, c, _cover(dist))

func soft_triangle(img: Image, pts: Array, c: Color) -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p: Vector2 in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	# the edge normals must point outwards whichever way the corners go round
	var wind := signf((pts[1] - pts[0]).cross(pts[2] - pts[0]))
	for y in range(int(lo.y) - 1, int(hi.y) + 2):
		for x in range(int(lo.x) - 1, int(hi.x) + 2):
			var q := Vector2(x + 0.5, y + 0.5)
			var dist := -INF
			for i in 3:
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[(i + 1) % 3]
				var n := Vector2(b.y - a.y, a.x - b.x).normalized() * wind
				dist = maxf(dist, (q - a).dot(n))
			_mix(img, x, y, c, _cover(dist))

## The soft oval shadow under people and monsters (shown at a quarter scale).
func shadow_tex(w: int) -> Texture2D:
	return cached("shadow_%d" % w, func():
		var img := blank(w * 4 + 8, 18)
		soft_ellipse(img, img.get_width() / 2.0, 9, w * 2.0, 5, Color(0.08, 0.05, 0.12, 0.32), 3.0)
		return to_tex(img))

## A round glow to add over bright things (portals, drops, ores).
func glow_tex() -> Texture2D:
	return cached("glow", func():
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		return t)

## A Sprite2D that adds a soft coloured glow behind whatever it's added to.
func glow_sprite(c: Color, size: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = glow_tex()
	s.modulate = c
	s.scale = Vector2.ONE * size / 64.0
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	s.show_behind_parent = true
	return s

## Puts a soft shadow under a person or monster standing at the node's origin.
func add_shadow(n: Node2D, w: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = "Shadow"
	s.texture = shadow_tex(int(w))
	s.scale = Vector2(0.25, 0.25)
	s.position = Vector2(0, 0.5)
	n.add_child(s)
	n.move_child(s, 0)
	return s

const TOUCH_K := 3 # the touch buttons are drawn 3x bigger and shown at 1/3 so they stay sharp on phones

## The on-screen buttons: round red A and green B, and soft grey arrow pads,
## with a drop shadow and a shiny top; pressed ones sink down.
## The on-screen buttons keep the sizes they had before the cartoon pass
## (Brenden, 2026-10-27): ◀ ▶ 90 x 34, A and B 68 x 34.
const TOUCH_SIZE := {"left": Vector2i(90, 34), "right": Vector2i(90, 34), "A": Vector2i(68, 34), "B": Vector2i(68, 34)}

func touch_tex(kind: String, pressed: bool) -> Texture2D:
	return cached("touch_%s_%s" % [kind, pressed], func():
		var k := TOUCH_K
		var w: int = TOUCH_SIZE[kind].x
		var h: int = TOUCH_SIZE[kind].y
		var img := blank((w + 2) * k, (h + 4) * k)
		var body: Color = {"A": Color("e0302a"), "B": Color("34b02a"), "left": Color("55555c"), "right": Color("55555c")}[kind]
		var sink := 2.0 * k if pressed else 0.0
		var lip := 0.0 if pressed else 3.0 * k
		var rim := Color("1b1a24")
		var x0 := 1.0 * k
		var r := 9.0 * k
		soft_rrect(img, x0, 3.0 * k, w * k, h * k, r, Color(0, 0, 0, 0.22))
		soft_rrect(img, x0, sink, w * k, (h - 1) * k, r, rim)
		soft_rrect(img, x0 + 1.5 * k, sink + 1.5 * k, (w - 3) * k, (h - 4) * k, r - 1.5 * k, body.darkened(0.3))
		soft_rrect(img, x0 + 1.5 * k, sink + 1.5 * k, (w - 3) * k, (h - 4) * k - lip, r - 1.5 * k, body)
		soft_rrect(img, x0 + 5 * k, sink + 3.5 * k, (w - 10) * k, 6 * k, 3 * k, Color(1, 1, 1, 0.16 if kind in ["left", "right"] else 0.24))
		if kind in ["left", "right"]:
			var cx := (w / 2.0 + 1) * k
			var cy := sink + ((h - 4) / 2.0 + 1) * k - lip / 2
			var s := 8.0 * k
			var dirx := -1.0 if kind == "left" else 1.0
			soft_triangle(img, [Vector2(cx + dirx * s, cy), Vector2(cx - dirx * s * 0.7, cy - s), Vector2(cx - dirx * s * 0.7, cy + s)], Color("e8e8ee"))
		return to_tex(img))

## The little round auto-hit switch: a sword on grey when off, on gold when on.
func auto_tex(on: bool, pressed: bool) -> Texture2D:
	return cached("auto_%s_%s" % [on, pressed], func():
		var k := TOUCH_K
		var w := 26
		var h := 26
		var img := blank((w + 2) * k, (h + 4) * k)
		var body := Color("f2a21e") if on else Color("55555c")
		var sink := 2.0 * k if pressed else 0.0
		var lip := 0.0 if pressed else 2.0 * k
		var cx := (w / 2.0 + 1) * k
		var r := (w / 2.0 - 1) * k
		var cy := h / 2.0 * k + sink + 1 * k
		soft_ellipse(img, cx, h / 2.0 * k + 3 * k, r, r, Color(0, 0, 0, 0.28), 2.0 * k)
		soft_ellipse(img, cx, cy, r, r - 1.5 * k, OUTLINE)
		soft_ellipse(img, cx, cy, r - 1.5 * k, r - 3 * k, body.darkened(0.35))
		soft_ellipse(img, cx, cy - lip / 2, r - 1.5 * k, r - 3 * k - lip / 2, body)
		soft_ellipse(img, cx - r * 0.18, cy - lip / 2 - r * 0.45, r * 0.5, r * 0.25, Color(1, 1, 1, 0.3))
		# a sword pointing up to the right
		var c := Vector2(cx, cy - lip / 2) + Vector2(-1.5, 1.5) * k
		var d := Vector2(1, -1).normalized()
		var n := Vector2(1, 1).normalized()
		var blade := Color.WHITE if on else Color("c8c8d0")
		var hilt := Color("6e4426") if on else Color("3a3a40")
		var tip := c + d * 8.0 * k
		soft_triangle(img, [c + n * 1.4 * k, tip, c - n * 1.4 * k], blade)
		soft_triangle(img, [c + n * 3.6 * k + d * 0.7 * k, c - n * 3.6 * k + d * 0.7 * k, c - n * 3.6 * k - d * 0.7 * k], hilt)
		soft_triangle(img, [c + n * 3.6 * k + d * 0.7 * k, c + n * 3.6 * k - d * 0.7 * k, c - n * 3.6 * k - d * 0.7 * k], hilt)
		soft_triangle(img, [c + n * 0.9 * k, c - d * 4.0 * k + n * 0.9 * k, c - d * 4.0 * k - n * 0.9 * k], hilt)
		soft_triangle(img, [c + n * 0.9 * k, c - n * 0.9 * k, c - d * 4.0 * k - n * 0.9 * k], hilt)
		soft_ellipse(img, (c - d * 4.6 * k).x, (c - d * 4.6 * k).y, 1.3 * k, 1.3 * k, hilt)
		return to_tex(img))

## Puffy cartoon clouds for the far sky.
func clouds_tex(th: Dictionary) -> Texture2D:
	return cached("clouds_" + th.name, func():
		var w := 512
		var h := 80
		var img := blank(w * 2, h * 2)
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var tint: Color = Color(1, 1, 1).lerp(th.sky[1], 0.25)
		tint.a = 0.85
		var shade: Color = tint.lerp(th.sky[0], 0.35)
		for i in 7:
			var cx := rng.randf_range(0, w) * 2
			var cy := rng.randf_range(16, h - 20) * 2
			var s := rng.randf_range(0.7, 1.3)
			for o in [-w * 2, 0, w * 2]:
				for part in [[-22, 4, 16, 9], [0, -2, 20, 14], [22, 4, 15, 9], [8, 6, 22, 8]]:
					soft_ellipse(img, cx + o + part[0] * s * 2, cy + part[1] * s * 2 + 3, part[2] * s * 2, part[3] * s * 2, shade, 1.5)
				for part in [[-22, 4, 16, 9], [0, -2, 20, 14], [22, 4, 15, 9], [8, 6, 22, 8]]:
					soft_ellipse(img, cx + o + part[0] * s * 2, cy + part[1] * s * 2, part[2] * s * 2, part[3] * s * 2, tint, 1.5)
		return to_tex(img))

func eyes(img: Image, x1: int, x2: int, y: int, size: int = 1, c: Color = OUTLINE) -> void:
	rect(img, x1, y, size, size + 1, c)
	rect(img, x2, y, size, size + 1, c)

# ---------------------------------------------------------------- characters
## One step along a colour's ramp: t below 0 is shadow, above 0 is light.
## Shadows drift toward blue-violet and gain colour, lights drift toward
## yellow and lose a little, the way pixel artists build ramps by hand, so
## shading never turns grey or muddy.
func shade(c: Color, t: float) -> Color:
	if c.a <= 0.0 or t == 0.0:
		return c
	var k := absf(t)
	var h := c.h
	var s := c.s
	var v := c.v
	if t < 0.0:
		if s < 0.1:
			h = 0.7
			s = minf(s + 0.1 * k, 1.0)
		else:
			var d := fposmod(0.72 - h + 0.5, 1.0) - 0.5
			h = fposmod(h + signf(d) * minf(absf(d), 0.05 * k), 1.0)
			s = minf(s + 0.1 * k, 1.0)
		v *= maxf(0.0, 1.0 - 0.26 * k)
	else:
		if v < 0.3:
			# dark things (black hair, suits) catch a cool sheen
			h = 0.66 if s < 0.1 else h
			s = clampf(s + 0.08 * k, 0.0, 1.0)
			v = v + 0.2 * k
		else:
			if s >= 0.1:
				var d2 := fposmod(0.13 - h + 0.5, 1.0) - 0.5
				h = fposmod(h + signf(d2) * minf(absf(d2), 0.035 * k), 1.0)
			s *= maxf(0.0, 1.0 - 0.3 * k)
			v = v + (1.0 - v) * minf(0.45 * k, 1.0)
	return Color.from_hsv(h, s, clampf(v, 0.0, 1.0), c.a)

## A coloured outline: each outline pixel is a very dark, hue-shifted copy of
## the colour it touches, so red things get a dark red edge and skin a warm
## brown one. Edges under and to the right of the sprite stay darkest.
func ink(src: Image, dark: Color = OUTLINE) -> Image:
	var w := src.get_width() + 2
	var h := src.get_height() + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.blit_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(1, 1))
	var out := img.duplicate()
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.5:
				continue
			# down and right first: an outline pixel above or left of the sprite takes the lighter tint
			var found := false
			var tint := dark
			var lit := false
			for d: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
				var q := Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h:
					continue
				var n := img.get_pixel(q.x, q.y)
				if n.a > 0.5:
					if not found:
						tint = n
						lit = d.x > 0 or d.y > 0
					found = true
			if found:
				out.set_pixel(x, y, dark.lerp(shade(tint, -2.2), 0.6 if lit else 0.35))
	return out

## A person sprite. helmet and armor are item ids, drawn over the character;
## hold stretches the front arm out to grip whatever is in the hand.
func character(look: String, frame: String = "stand", scale: int = 1, helmet: String = "", armor: String = "", hold: bool = false) -> Texture2D:
	return cached("char_%s_%s_%d_%s_%s_%s" % [look, frame, scale, helmet, armor, hold], func():
		# bigger copies keep their square pixels, outline included
		var img := ink(_char_img(look, frame, 1, helmet, armor, hold))
		if scale > 1:
			img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
		return to_tex(img))

func character_flash(look: String) -> Texture2D:
	return cached("charflash_" + look, func():
		return to_tex(flash_image(ink(_char_img(look, "stand", 1)))))

func _char_map(look: String, armor: String) -> Dictionary:
	var d: Dictionary = LOOKS.get(look, LOOKS.man_in_suit)
	var map := {}
	for k in d:
		if d[k] is String:
			map[k] = d[k]
	if not map.has("s"): map.s = "f6c5a0"
	if not map.has("h"): map.h = "3a2a3e"
	if not map.has("c"): map.c = "5a5a6e"
	if not map.has("q"): map.q = "3e3e52"
	if not map.has("f"): map.f = "2a2233"
	if not map.has("e"): map.e = "241c2e"
	if not map.has("w"): map.w = "ffffff"
	if not map.has("t"): map.t = map.c
	if not map.has("v"): map.v = map.c
	if not map.has("j"): map.j = map.q
	var sleeve = map.get("sl", map.c)
	var own_sleeve: bool = map.has("sl")
	if armor != "":
		var mc := material_colors(armor)
		map.c = mc.X
		map.C = mc.x
		map.v = mc.X
		map.t = mc.x
		sleeve = mc.X
		own_sleeve = false
		# armour (not robes) comes with matching leg guards
		if not ItemIcons.armor_parts(ItemIcons.split_tier(armor)[0]).robe:
			map.q = mc.x
			map.j = mc.x
	# the ramps: a shadow and a highlight for every base colour
	for p in [["h", "H", "^"], ["s", "S", "5"], ["c", "C", "L"], ["q", "Q", ""], ["f", "F", ""], ["j", "J", ""]]:
		var base := col(map[p[0]])
		if not map.has(p[1]):
			map[p[1]] = shade(base, -1.0)
		if p[2] != "" and not map.has(p[2]):
			map[p[2]] = shade(base, 1.0)
	map["1"] = col(sleeve)
	map["2"] = shade(col(sleeve), -1.0) if own_sleeve else col(map.C)
	var hand := col(map.get("gl", map.s))
	map["3"] = hand
	map["4"] = shade(hand, -1.0)
	var skin := col(map.s)
	if not map.has("m"): map.m = shade(skin, -1.8)
	# blush on the cheeks of people, not on masks, robots, mummies or zombies
	var human := skin.h < 0.13 and skin.s > 0.2 and skin.v > 0.45
	map["+"] = skin.lerp(Color("ff6a7a"), 0.45) if human else skin
	return map

## How many pixels the head, body and hands sit lower in this frame.
func frame_sink(frame: String) -> int:
	return FRAME_DEF.get(frame, FRAME_DEF.stand)[2]

func _overlay(img: Image, parts: Array, map: Dictionary) -> void:
	for o in parts:
		var g := grid_image(o[2], map)
		img.blend_rect(g, Rect2i(0, 0, g.get_width(), g.get_height()), Vector2i(o[0], o[1]))

func _char_img(look: String, frame: String, scale: int, helmet: String = "", armor: String = "", hold: bool = false) -> Image:
	var d: Dictionary = LOOKS.get(look, LOOKS.man_in_suit)
	var map := _char_map(look, armor)
	var fd: Array = FRAME_DEF.get(frame, FRAME_DEF.stand)
	var body: Array = BODIES[fd[0]].duplicate()
	if hold:
		# the front arm reaches forward, its hand where the held item's grip is
		for r in 4:
			body[r] = String(body[r]).substr(0, 9) + "..."
		body[1] = String(body[1]).substr(0, 9) + "24."
	var hgt: int = PAD + 17
	# the head and body, with everything worn on them
	var up := blank(12, hgt)
	var base := grid_image(HEADS[d.get("head", "short")] + body, map)
	up.blit_rect(base, Rect2i(0, 0, 12, 14), Vector2i(0, PAD))
	if d.get("long", false):
		# long hair down the back, behind the arm
		for y in range(PAD + 7, PAD + 12):
			for x in [1, 2]:
				if up.get_pixel(x, y).a < 0.5 and (x == 1 or y < PAD + 10):
					up.set_pixel(x, y, col(map.H if x == 1 or y > PAD + 8 else map.h))
	if look == "mummy":
		for y in range(PAD + 1, PAD + 14, 3):
			for x in 12:
				if up.get_pixel(x, y).a > 0.5 and not (y == PAD + 5 or y == PAD + 6):
					up.set_pixel(x, y, shade(col(map.s), -1.0))
	_overlay(up, d.get("over", []), map)
	if armor != "":
		_draw_armor(up, armor)
	else:
		_overlay(up, d.get("wear", []), map)
	if helmet != "":
		_draw_helmet(up, helmet)
	# the legs stay on the ground; the rest sinks a pixel on a step or a breath
	var img := blank(12, hgt)
	var legs := grid_image(LEGS[fd[1]], map)
	if look == "mummy":
		for x in 12:
			if legs.get_pixel(x, 1).a > 0.5:
				legs.set_pixel(x, 1, shade(col(map.s), -1.0))
	img.blit_rect(legs, Rect2i(0, 0, 12, 3), Vector2i(0, PAD + 14))
	var dy: int = fd[2]
	img.blend_rect(up, Rect2i(0, 0, 12, hgt - dy), Vector2i(0, dy))
	if scale > 1:
		img = upscale(img, scale)
	return img

func _draw_helmet(img: Image, helmet: String) -> void:
	if helmet == "bad_mask":
		# the Bad Man's dark face, worn as a mask, with his white eyes
		_overlay(img, [[1, 6, ["..XXXXXXXXX.", ".XXXXXXXXXXX", ".XXXXXXXXXXX", ".XXXXXXXXXXX", ".XXXXXXXXXXX", "..XXXXXXXXX."]]], {"X": "3a3a44"})
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
			_overlay(img, [[3, 7, ["ggggggggg", "ggbbgbbgg", "ggwegwegg", "ggwegwegg", "ggggmmggg", ".gGGGGGg."]]], {"g": "5cbf3f", "G": "2e7a2a", "b": "1b1a24", "w": "ffffff", "e": "1b1a24", "m": "8a2a2a"})
		"the_fly":
			_overlay(img, [[2, 6, ["..kkkkkk...", ".kkkkkkkkk.", "kkkcCkcCkk.", "kkkCCkCCkk."]]], {"c": "a6e6f2", "C": "4fb6d0"})
		"wood_mask", "skull_mask":
			var m: Dictionary = {"X": "a8703f", "x": "6e4426"} if helmet == "wood_mask" else {"X": "f2ecd8", "x": "a89878"}
			_overlay(img, [[4, 8, [".XXXXXX", "XXkXXkX", "XXkXXkX", "XXXXXXX", ".XxxxX."]]], m)
		"cool_hat", "roman_hat", "storm_hat":
			var c3: Array = {"cool_hat": ["1b1a24", "3a3a48"], "roman_hat": ["f2cf5b", "d8433a"], "storm_hat": ["6b8ff0", "2c4596"]}[helmet]
			_overlay(img, [[1, 2, ["...XXXXXX...", "..XXXXXXXX..", "..XxxxxxxX..", "XXXXXXXXXXXX"]]], {"X": c3[0], "x": c3[1]})
		_:
			_draw_helmet_kind(img, helmet, map)

## Worn helmets take the shape of their icon (Brenden, 2026-11-06: armours and
## helmets should "look distinct from each other"): a dome, a knight's visor,
## a plume, horns, wings, a crown, a hood, a mask and so on, in the helmet's
## colours. Upgrades add a gem on the front.
func _draw_helmet_kind(img: Image, helmet: String, map: Dictionary) -> void:
	var bt: Array = ItemIcons.split_tier(helmet)
	var base: String = bt[0]
	var kind: String = ItemIcons.helmet_kind(base)
	map.w = "f2efe6"
	map.k = "1b1a24"
	map.G = ItemIcons.pick(base, 2, ItemIcons.GUARDS)
	map.a = ItemIcons.pick(base, 1, ItemIcons.GEMS)
	map.y = "f2cf5b"
	var dome := ["....XXXX....", "..XXwXXXXX..", ".XXwXXXXXXX.", ".XXXXXXXXXXX", ".GGGGGGGGGGG", ".Xx.........", ".Xx........."]
	var parts := []
	match kind:
		"dome":
			parts = [[0, 2, dome]]
		"visor":
			parts = [[0, 2, dome], [0, 8, ["...XXXXXXXX.", "...XkkkkkkkX", "...XXXXXXXX."]]]
		"crest":
			parts = [[0, 2, dome], [0, 0, ["...aaaaa....", "..aaaaaaa..."]]]
		"horned":
			parts = [[0, 2, dome], [0, 0, ["w..........w", "w..........w", ".w........w."]]]
		"winged":
			parts = [[0, 2, dome], [0, 1, ["w..........w", "ww........ww", "ww........ww", ".w........w."]]]
		"hat":
			parts = [[0, 0, [".....XX.....", "....XXXX....", "....XwXX....", "...XXXXXX...", "...GGGGGG...", "XXXXXXXXXXXX", ".xxxxxxxxxx."]]]
		"tophat":
			parts = [[0, 0, ["...XXXXXX...", "...XwXXXX...", "...XXXXXX...", "...GGGGGG...", "XXXXXXXXXXXX", ".xxxxxxxxxx."]]]
		"witch":
			parts = [[0, 0, [".......XX...", "......XXX...", ".....XXXX...", "....XwXXX...", "...GGGGGGG..", "XXXXXXXXXXXX", ".xxxxxxxxxx."]]]
		"cap":
			parts = [[0, 2, ["...XXXXXX...", "..XXwXXXXX..", "..XXXXXXXXGG", "..xxxxxxxxGG"]]]
		"crown":
			map.X = "f2cf5b"
			map.x = "c99a2e"
			parts = [[0, 1, ["..X..X..X...", "..XX.XX.XX..", "..XXXXXXXX..", "..XaXXaXXa..", "..xxxxxxxx.."]]]
		"hood":
			parts = [[0, 2, ["...XXXXXX...", "..XXXXXXXXX.", ".XXXXXXXXXXX", ".XXX......XX", ".XX.......XX", ".XX.......X.", ".XX.......X.", ".XXX.....XX.", "..XX.....X.."]]]
		"mask", "face":
			parts = [[0, 8, ["...XXXXXXXX.", "...XX..X..X.", "...xXXXXXXx."]]]
		"robo", "alien":
			if kind == "alien":
				map.X = "7cf06a"
				map.x = "3e9a2a"
			parts = [[0, 0, [".....a......", ".....G......", "...XXXXXX...", "..XXwXXXXX..", ".XXXXXXXXXXX", ".XXXXXXXXXXX", ".XXXXXXXXXXX", ".XXXXXXXXXXX", ".XXGaaaaaaaG", ".XXXXXXXXXXX", ".xXXXXXXXXx.", "..xxxxxxxx.."]]]
		"pumpkin":
			map.X = "ea8a33"
			map.x = "b85e1c"
			parts = [[0, 2, [".....gg.....", "...XXXXXX...", "..XXXXXXXXX.", ".XXXXXXXXXXX", ".XXXXXXXXXXX", ".XXXXXXXXXXX", ".XXXXkXXkXXX", ".XXXXXXXXXXX", ".XXXkXkXkXX.", "..xxxxxxxx.."]]]
			map.g = "5cbf3f"
		"moon":
			parts = [[0, 0, [".......yy...", "......y.....", "......yy....", "...XXXXXX...", "...XwXXXX...", "XXXXXXXXXXXX", ".xxxxxxxxxx."]]]
		"snowman":
			map.X = "3a3a48"
			map.x = "1b1a24"
			parts = [[0, 0, ["...XXXXXX...", "...XwXXXX...", "...XXXXXX...", "...rrrrrr...", "XXXXXXXXXXXX", ".xxxxxxxxxx."]]]
			map.r = "d8433a"
		"rooster":
			map.r = "d8433a"
			parts = [[0, 0, ["....r.r.r...", "....rrrrr...", "...XXXXXX...", "..XXwXXXXX..", ".XXXXXXXXXXX", ".xxxxxxxxxx."]]]
		_:
			parts = [[0, 2, dome]]
	_overlay(img, parts, map)
	if bt[1] >= 2:
		px(img, 6, 4 if kind not in ["hat", "tophat", "witch", "moon", "snowman"] else 4, col(map.a))
	if bt[1] >= 4:
		px(img, 3, 3, Color("f2efe6"))

## Worn armour gets the same shoulders, belt and front as its icon, so two
## armours never look like the same shirt in another colour.
func _draw_armor(img: Image, armor: String) -> void:
	var bt: Array = ItemIcons.split_tier(armor)
	var base: String = bt[0]
	var ap: Dictionary = ItemIcons.armor_parts(base)
	var mc := material_colors(armor)
	var X := col(mc.X)
	var x := col(mc.x)
	var G := col(ItemIcons.pick(base, 2, ItemIcons.GUARDS))
	var a := col(ItemIcons.pick(base, 1, ItemIcons.GEMS))
	var w := Color("f2efe6")
	var k := Color("1b1a24")
	var y0 := PAD + 9 # the top row of the body
	match ap.sh:
		"pads":
			rect(img, 1, y0, 3, 1, G)
			rect(img, 8, y0, 3, 1, G)
			px(img, 1, y0 + 1, G)
			px(img, 10, y0 + 1, G)
		"spikes":
			px(img, 1, y0 - 1, w)
			px(img, 10, y0 - 1, w)
			rect(img, 1, y0, 3, 1, G)
			rect(img, 8, y0, 3, 1, G)
		"round":
			rect(img, 1, y0, 2, 2, X)
			rect(img, 9, y0, 2, 2, X)
			px(img, 1, y0, X.lightened(0.3))
			px(img, 9, y0, X.lightened(0.3))
	match ap.collar:
		"v": rect(img, 5, y0, 2, 1, x)
		"high":
			px(img, 4, y0, G)
			px(img, 7, y0, G)
	if ap.robe:
		# a long skirt over the legs
		for yy in range(y0 + 4, y0 + 7):
			rect(img, 2, yy, 8, 1, X if yy < y0 + 6 else x)
		if ap.front == "ghost":
			for xx in range(2, 10, 2):
				px(img, xx, y0 + 6, Color(0, 0, 0, 0))
	if ap.belt:
		rect(img, 3, y0 + 4, 6, 1, G)
		px(img, 5, y0 + 4, a)
	match ap.front:
		"plates":
			px(img, 4, y0 + 1, x)
			px(img, 7, y0 + 1, x)
			rect(img, 4, y0 + 3, 4, 1, x)
		"rivets":
			for q in [[4, 1], [7, 1], [4, 3], [7, 3]]:
				px(img, q[0], y0 + q[1], G)
		"emblem":
			rect(img, 5, y0 + 1, 2, 2, a)
			px(img, 5, y0 + 1, a.lightened(0.4))
		"stripe":
			rect(img, 5, y0, 2, 4, G)
		"rings":
			for yy in range(y0, y0 + 4):
				for xx in range(3, 9):
					if (xx + yy) % 2 == 0 and img.get_pixel(xx, yy).a > 0.5:
						px(img, xx, yy, x)
		"scales":
			for yy in range(y0 + 1, y0 + 4):
				for xx in range(3 + yy % 2, 9, 2):
					px(img, xx, yy, x)
		"skull":
			rect(img, 4, y0 + 1, 3, 1, w)
			px(img, 4, y0 + 2, k)
			px(img, 5, y0 + 2, w)
			px(img, 6, y0 + 2, k)
		"flake":
			for q in [[5, 1], [4, 2], [5, 2], [6, 2], [5, 3]]:
				px(img, q[0], y0 + q[1], w)
		"jelly":
			for q in [[4, 1], [7, 2], [5, 3]]:
				px(img, q[0], y0 + q[1], w)
		"eye":
			px(img, 5, y0 + 1, w)
			px(img, 6, y0 + 1, w)
			px(img, 5, y0 + 2, a)
			px(img, 6, y0 + 2, k)
		"feather":
			px(img, 2, y0 - 1, Color("d8433a"))
			px(img, 3, y0 - 1, Color("d8433a"))
	# upgrades: a gem on the chest, then a shine
	if bt[1] >= 2:
		px(img, 6, y0 + 1, a)
	if bt[1] >= 5:
		px(img, 3, y0 + 1, w)

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

## The Jelly King: a big pink slime with a gold crown slipped half off its
## head, hanging crooked over one side (Brenden, 2026-11-05). `alt` is the
## squashed frame, `crouch` the deep squash before a big jump.
func jelly_king_img(alt: bool, crouch := false) -> Image:
	var body := Color("f06aa0")
	var w := 24
	var h := 15
	if alt:
		w += 2
		h -= 1
	if crouch:
		w += 4
		h -= 4
	var top := 7 # room for the crown
	var img := blank(w + 2, h + top + 1)
	var cx := (w + 2) / 2.0
	ellipse(img, cx, top + h * 0.6, w / 2.0, h * 0.6, body)
	rect(img, 2, top + h - 2, w - 2, 2, body.darkened(0.3))
	ellipse(img, cx - w * 0.2, top + h * 0.35, w * 0.12, h * 0.12, body.lightened(0.4))
	px(img, int(cx - w * 0.3), top + int(h * 0.5), body.lightened(0.25))
	# a grumpy royal face
	eyes(img, int(cx + w * 0.05), int(cx + w * 0.3), top + int(h * 0.48), 2)
	rect(img, int(cx + w * 0.05) - 1, top + int(h * 0.48) - 2, 3, 1, OUTLINE)
	rect(img, int(cx + w * 0.3) - 1, top + int(h * 0.48) - 2, 3, 1, OUTLINE)
	rect(img, int(cx + w * 0.12), top + int(h * 0.75), 4, 1, OUTLINE)
	# the crown, tipped over to the right and slipping down the side of the head
	var gold := Color("f2cf5b")
	var shade := Color("c89a2a")
	var x0 := int(cx + 1)
	for i in 10:
		var drop := i / 3 # each column a little lower: crooked
		var y0 := top - 3 + drop + (1 if crouch else 0)
		px(img, x0 + i, y0 + 1, gold)
		px(img, x0 + i, y0 + 2, shade)
		if i % 4 == 0:
			px(img, x0 + i, y0, gold)
			px(img, x0 + i, y0 - 1, gold)
	px(img, x0 + 4, top - 1 + 1, Color("d8433a"))
	px(img, x0 + 8, top + 1 + 1, Color("4f8fe0"))
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

## Outlined first and then smoothly enlarged, so a big monster keeps a bold
## outline and round edges instead of a hairline around giant square pixels.
func big(img: Image, k: int) -> Image:
	return upscale(outline(img), k)

## The boss version of a character: three times as big, with extras.
func boss_char(look: String, alt: bool) -> Image:
	var img := _char_img(look, "walk" if alt else "stand", 4)
	# the extras are laid out for a 3x character; q() moves them onto the 4x one
	var q := func(v: int) -> int: return int(round(v * 4.0 / 3.0))
	match look:
		"modina", "modina_2":
			# four swords, two on each side
			for side in [0, 1]:
				for k in 2:
					var x: int = 2 + side * 28 + k * 3
					rect(img, q.call(x), q.call(22 + k * 6), 3, q.call(22), Color("e3ebf5"))
					rect(img, q.call(x - 1), q.call(40 + k * 6), 5, 3, Color("f2cf5b"))
		"evil_santa":
			rect(img, q.call(6), q.call(6), q.call(26), q.call(6), Color("c8202a"))
			rect(img, q.call(30), q.call(2), q.call(6), q.call(6), Color("c8202a"))
			rect(img, q.call(34), 0, q.call(4), q.call(4), Color("f2efe6"))
			rect(img, q.call(6), q.call(12), q.call(26), q.call(3), Color("f2efe6"))
			rect(img, q.call(9), q.call(36), q.call(20), q.call(12), Color("f2efe6"))
	return img

func _person_mob(look: String, alt: bool, flash: bool) -> Image:
	var img := ink(_char_img(look, "walk0" if alt else "walk2", 1))
	return flash_image(img) if flash else img

func mob_tex(look: String, alt: bool, flash := false, k := 1) -> Texture2D:
	if k > 1:
		# a boss drawn k times bigger, smoothly enlarged so it doesn't look blown up
		return cached("mob_%s_%s_%s_x%d" % [look, alt, flash, k], func():
			return to_tex(upscale(mob_tex(look, alt, flash).get_image(), k)))
	return cached("mob_%s_%s_%s" % [look, alt, flash], func():
		var img: Image
		match look:
			"slime_pink": img = blob(Color("f06aa0"), 14, 11, alt)
			"jelly_king": img = big(jelly_king_img(alt), 3)
			"jelly_king_crouch": img = big(jelly_king_img(true, true), 3)
			"slime_dark": img = blob(Color("7b4fb8"), 16, 12, alt)
			"small_stone": img = blob(Color("8a9099"), 16, 13, alt)
			"farmland": img = blob(Color("ea8a33"), 15, 13, alt)
			"golden_orb": img = blob(Color("f2cf5b"), 14, 14, false)
			"snowball": img = blob(Color("f2efe6"), 10, 9, alt)
			"waterball": img = blob(Color("4f8fe0"), 10, 9, alt)
			"fireball": img = blob(Color("ea6a33"), 10, 9, alt)
			"goldball": img = blob(Color("f2cf5b"), 10, 9, alt)
			"wisp": img = flame_img(Color("ea8a33"), alt)
			"mummy", "zombie", "wizard": return to_tex(_person_mob(look, alt, flash))
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
			"grinch", "lich": return to_tex(_person_mob(look, alt, flash))
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
				img = big(li, 4)
			"pineapple_killer":
				var pk := fruit_img("pineapple", alt)
				rect(pk, 1, 10, 3, 2, Color("3a3a48"))
				rect(pk, 14, 10 - (1 if alt else 0), 3, 2, Color("3a3a48"))
				eyes(pk, 8, 11, 10, 1, Color("d8433a"))
				img = big(pk, 4)
			"harakattu": img = big(bunny_img(Color("f2efe6"), alt), 4)
			# Tomb of Makara
			"sand_mantis": img = bug_img(18, 12, Color("e8a0a8"), Color("b06a7a"), alt)
			"tombstone": img = tombstone_img(alt)
			"vampire": return to_tex(_person_mob(look, alt, flash))
			"makara": img = makara_img(alt)
			# pets
			"grrr": img = trex_img(Color("8a4ac8"), Color("c8a0e8"), alt)
			"mini_ball": img = blob(Color("5a5a6a"), 10, 9, alt)
			"chick_aiai", "chick_cici", "chick_bibi", "chick_dede", "chick_fofo":
				img = chick_img(alt)
				var tint: Color = {"chick_aiai": Color("f06a5a"), "chick_cici": Color("5cbf3f"), "chick_bibi": Color("6b8ff0"), "chick_dede": Color("ea8a33"), "chick_fofo": Color("a77ee0")}[look]
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
		img = outline(volume(img))
		if flash:
			img = flash_image(img)
		return to_tex(img))

# ---------------------------------------------------------------- item icons
const ICON_GRIDS := {
	"log": ["..........", "......nnn.", ".....nlln.", "....nlnn..", "...nlnn...", "..nlnn....", ".nlnn.....", ".nnl......", "..........", ".........."],
	"stick": ["..........", "........n.", ".......nl.", "......nl..", ".....nl...", "....nlg...", "...nl.....", "..nl......", ".nl.......", ".........."],
	"lump": ["..........", "..........", "...XXXX...", "..XxXXXX..", ".XXXXXxXX.", ".XxXXXXXx.", ".XXXXxXXx.", "..xxxxxx..", "..........", ".........."],
	"ore": ["..........", "...AAAa...", "..AAaaaad.", ".AaXwaaad.", ".AaXxaXwd.", "AaaaaaXxdD", "AaXwaaaadD", ".aXxadddD.", "..dDDDDD..", ".........."],
	"bar": ["..........", "..........", "..........", "....XXXXX.", "...XwXXXx.", "..XXXXXxx.", ".xxxxxxx..", "..........", "..........", ".........."],
	"blob": ["..........", "....X.....", "...XXx....", "..XXXXx...", ".XXwXXXx..", ".XXXXXXx..", ".XXXXXxx..", "..xxxxx...", "..........", ".........."],
	"crystal": [".....w....", "....LXx...", "....LXx...", "....LXx...", ".w..LXx...", "LXx.LXx.w.", "LXx.LXxLx.", "LXxwLXxLx.", ".dDDDDDDd.", ".........."],
	"gem": ["..........", "..LLXXX...", ".LwLXXXx..", "LLLLxxxxx.", ".XXXXXXx..", "..XXXXx...", "...XXx....", "....x.....", "..........", ".........."],
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
	"vial": ["..........", "..........", "....nn....", "....AA....", "...AXXA...", "...AwXA...", "...AxxA...", "....AA....", "..........", ".........."],
	"flask": ["....nn....", "....AA....", "....AA....", "...AXXA...", "..AXwXXA..", ".AXXXXXXA.", ".AXXXXXXA.", ".AxxxxxxA.", "..AAAAAA..", ".........."],
	"jug": ["...nnnn...", "...AAAA...", "..AXXXXA..", ".AXwXXXXAA", ".AXXXXXXAA", ".AXXXXXXAA", ".AXXXXXXA.", ".AxxxxxxA.", "..AAAAAA..", ".........."],
	"shard": ["..........", "..........", ".....w....", "....LXx...", "....LXx...", "....LXx...", "....LXx...", ".....xx...", "..........", ".........."],
	"egg_spots": ["..........", "...ww.....", "..wXww....", ".wwaawX...", ".wXwwww...", ".waawaw...", "..wwww....", "..........", "..........", ".........."],
	"torch_stand": ["....y.....", "...yoy....", "...oRo....", "..aaoaa...", "...aaa....", "....a.....", "....a.....", "...aaa....", "..aaaaa...", ".........."],
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
		"evil_crystal": return ["crystal", {"X": "5a2a6a", "x": "d8433a"}]
		"small_evil_crystal": return ["shard", {"X": "5a2a6a", "x": "d8433a"}]
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
		"em_stone": return ["gem", {"X": "5cbf3f", "x": "2e7a2a"}]
		"ruby_stone": return ["gem", {"X": "d8433a", "x": "8a1e1a"}]
		"sapphire_stone": return ["gem", {"X": "3b5dc9", "x": "1e2a6a"}]
		"dark_stone", "sky_stone": return ["gem", mc]
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
		"eggency": return ["egg_spots", {"X": "f2a33a", "a": "d8433a"}]
		"christmas_egg": return ["egg_spots", {"X": "d8433a", "a": "3e9a3a"}]
		"easter_egg": return ["egg_spots", {"X": "f08ac8", "a": "6bc8f0"}]
		"halloween_egg": return ["egg_spots", {"X": "ea8a33", "a": "1b1a24"}]
		"nightmare_ingot": return ["bar", mc]
		"plunger": return ["plunger", mc]
		"arrow": return ["arrow", {}]
		"snow_ball": return ["balls", {"X": "f4fbff", "x": "a6c6d8"}]
		"wood_wall": return ["wall", {}]
		"stone_wall": return ["wall", {"n": "9aa2ad", "l": "c8ced6", "N": "5c616b"}]
		"wooden_spikes": return ["spikes", {}]
		"work_station": return ["station", {}]
		"campfire": return ["fire", {}]
		"torch": return ["torch_stand", {}]
		"survival_token": return ["token", {"X": "5cbf3f", "x": "2e7a2a"}]
		"coin": return ["token", {"X": "f2cf5b", "x": "c99a2e"}]
		"gem": return ["gem", {"X": "dcecf8", "x": "7a9ab8"}] # the original's white-blue diamond
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
		return ["ore", {"X": mc.X, "x": mc.x}]
	if id.ends_with("_bar"):
		return ["bar", mc]
	match t:
		"food":
			var c := "d8433a"
			if id.contains("mana"): c = "3b6fd9"
			elif id.contains("rejuvenate"): c = "a77ee0"
			elif id == "antidote": c = "5cbf3f"
			elif id == "fatigue_potion": c = "f2cf5b"
			# bottles get bigger with the potion: small, normal, medium, big
			var shape := "potion"
			if id.begins_with("small_"): shape = "vial"
			elif id.begins_with("medium_"): shape = "flask"
			elif id.begins_with("big_"): shape = "jug"
			return [shape, {"X": c, "x": Color(c).darkened(0.35).to_html(false)}]
		"weapon":
			return ["long" if id.contains("long") or id == "excalibur" else "sword", mc]
		"staff":
			if id.begins_with("iron_fist"):
				return ["fist", {"X": "c83a2a" if id == "iron_fist" else ("f2a33a" if id == "iron_fist_2" else ("f2cf5b" if id == "iron_fist_3" else ("e3ebf5" if id == "iron_fist_4" else "a77ee0"))), "x": "6a1e14"}]
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

## Long weapons (reach 24 or more: long swords, Excalibur, pole axes, lances,
## Modina swords and the like) are drawn twice as big in your hand, like the
## original (Brenden, 2026-11-06). Short ones stay icon-sized.
## How big an item looks in the hand (1 = its icon's size). Each weapon has its
## own size from its reach and weight, so a Gradius is a little knife and a
## Long Lance is twice your height (Brenden, 2026-11-06).
func held_size(id: String) -> float:
	return float(Data.ITEMS.get(id, {}).get("size", 1.0))

## Held items are drawn from a 4x smoothed copy of the icon and scaled down to
## their size, so every size from 0.9 to 2.6 stays clean instead of blocky.
const HELD_K := 4

## The texture for an item held in the hand.
func held_tex(id: String) -> Texture2D:
	return cached("held_%s" % id, func(): return to_tex(upscale(icon(id).get_image(), HELD_K)))

## The scale to draw `held_tex` at.
func held_scale(id: String) -> Vector2:
	return Vector2.ONE * held_size(id) / HELD_K

## Puts the held item's handle (its lower corner) in the hand, whatever its size.
func held_offset(tex: Texture2D, facing: int) -> Vector2:
	if tex == null:
		return Vector2(4 * facing, -5)
	return Vector2((tex.get_width() / 2.0 - 2.0 * HELD_K) * facing, -(tex.get_height() / 2.0 - 1.0 * HELD_K))

func icon(id: String) -> Texture2D:
	return cached("icon_" + id, func():
		var it: Dictionary = Data.ITEMS.get(id, {})
		if it.get("type", "") == "character":
			var full: Image = _char_img(it.look, "stand", 1)
			return to_tex(ink(full.get_region(Rect2i(0, 1, full.get_width(), 16))))
		if it.get("type", "") == "pet":
			var img: Image = mob_tex(pet_look(id), false).get_image().duplicate()
			# a Jr pet is drawn a little smaller than the grown-up one
			var s := (9.0 if id.ends_with("_jr") else 12.0) / maxf(img.get_width(), img.get_height())
			if s < 1.0 or id.ends_with("_jr"):
				img.resize(maxi(1, int(img.get_width() * s)), maxi(1, int(img.get_height() * s)), Image.INTERPOLATE_NEAREST)
			return to_tex(img)
		var drawn: Array = ItemIcons.make(id, it, material_colors(id))
		if not drawn.is_empty():
			return to_tex(outline(grid_image(drawn[0], drawn[1])))
		var spec := icon_spec(id)
		var map: Dictionary = spec[1].duplicate()
		# "L" is the lit face of crystals and gems: a lighter shade of the main colour
		if not map.has("L"):
			map["L"] = col(map.get("X", "c8ced6")).lightened(0.4).to_html(false)
		return to_tex(outline(grid_image(ICON_GRIDS[spec[0]], map))))

## The same icon at double size, for the big bag and hotbar slots.
func icon_big(id: String) -> Texture2D:
	return cached("iconbig_" + id, func():
		return to_tex(upscale(icon(id).get_image(), 2)))

# ---------------------------------------------------------------- emotes
## An emote for the emote panel and over people's heads.
func emote(id: String) -> Texture2D:
	return cached("emote_" + id, func(): return to_tex(outline(emote_img(id))))

func _face(img: Image, c: Color) -> void:
	ellipse(img, 8, 8, 7, 7, c)

func emote_img(id: String) -> Image:
	var img := blank(16, 16)
	var k := OUTLINE
	var y := Color("f2cf5b")
	var w := Color("f2efe6")
	var r := Color("d8433a")
	var m := Color("8a1e1a")
	var s := Color("f2c29a")
	var b := Color("6bb8f0")
	match id:
		"angry":
			_face(img, Color("f0903a"))
			for d in 3:
				px(img, 4 + d, 5 + d / 2, k)
				px(img, 11 - d, 5 + d / 2, k)
			rect(img, 5, 7, 1, 2, k)
			rect(img, 10, 7, 1, 2, k)
			px(img, 5, 12, k)
			rect(img, 6, 11, 4, 1, k)
			px(img, 10, 12, k)
		"grin":
			_face(img, y)
			for e in [4, 9]:
				px(img, e, 7, k)
				px(img, e + 1, 6, k)
				px(img, e + 2, 7, k)
			rect(img, 4, 9, 8, 3, k)
			rect(img, 5, 9, 6, 2, w)
		"bomb":
			ellipse(img, 8, 9.5, 6, 6, Color("2a2a30"))
			rect(img, 6, 7, 4, 3, w)
			px(img, 7, 8, k)
			px(img, 8, 8, w)
			px(img, 9, 8, k)
			rect(img, 7, 10, 2, 1, w)
			px(img, 11, 3, Color("8a5a32"))
			px(img, 12, 2, Color("8a5a32"))
			px(img, 13, 1, y)
			px(img, 14, 0, Color("ea8a33"))
			px(img, 14, 2, Color("ea8a33"))
		"sleepy":
			_face(img, y)
			rect(img, 4, 8, 3, 1, k)
			rect(img, 9, 8, 3, 1, k)
			rect(img, 7, 11, 2, 2, m)
			rect(img, 11, 0, 4, 1, b)
			px(img, 13, 1, b)
			px(img, 12, 2, b)
			rect(img, 11, 3, 4, 1, b)
		"poop":
			var brown := Color("8a5a32")
			ellipse(img, 8, 13, 7, 2.5, brown)
			ellipse(img, 8, 9.5, 5, 2.2, brown)
			ellipse(img, 8, 6.5, 3, 1.8, brown)
			px(img, 9, 4, brown)
			px(img, 10, 3, brown)
			rect(img, 5, 9, 2, 2, w)
			rect(img, 9, 9, 2, 2, w)
			px(img, 6, 10, k)
			px(img, 10, 10, k)
			rect(img, 6, 13, 4, 1, k)
		"laugh":
			_face(img, y)
			px(img, 4, 6, k)
			px(img, 5, 7, k)
			px(img, 4, 8, k)
			px(img, 11, 6, k)
			px(img, 10, 7, k)
			px(img, 11, 8, k)
			rect(img, 4, 10, 8, 3, m)
			rect(img, 5, 10, 6, 1, w)
			rect(img, 6, 12, 4, 1, Color("f06a8a"))
			px(img, 1, 8, b)
			px(img, 14, 8, b)
		"shock":
			_face(img, y)
			rect(img, 4, 5, 3, 3, w)
			rect(img, 9, 5, 3, 3, w)
			px(img, 5, 6, k)
			px(img, 10, 6, k)
			rect(img, 7, 10, 2, 3, m)
			px(img, 6, 11, m)
			px(img, 9, 11, m)
		"thumbs":
			_face(img, y)
			rect(img, 5, 6, 1, 2, k)
			rect(img, 10, 6, 1, 2, k)
			px(img, 5, 10, k)
			rect(img, 6, 11, 4, 1, k)
			px(img, 10, 10, k)
			rect(img, 0, 11, 5, 5, s)
			rect(img, 1, 7, 2, 4, s)
			rect(img, 1, 12, 4, 1, s.darkened(0.25))
			rect(img, 1, 14, 4, 1, s.darkened(0.25))
		"cry":
			_face(img, y)
			for e in [4, 9]:
				px(img, e, 6, k)
				px(img, e + 1, 7, k)
				px(img, e + 2, 6, k)
			rect(img, 4, 8, 1, 7, b)
			rect(img, 11, 8, 1, 7, b)
			rect(img, 6, 11, 4, 2, m)
			px(img, 6, 11, y)
			px(img, 9, 11, y)
		"salute":
			_face(img, y)
			rect(img, 5, 7, 1, 2, k)
			rect(img, 10, 7, 1, 2, k)
			px(img, 5, 11, k)
			rect(img, 6, 12, 4, 1, k)
			px(img, 10, 11, k)
			rect(img, 8, 2, 7, 3, s)
			rect(img, 13, 0, 3, 3, s)
			rect(img, 9, 3, 5, 1, s.darkened(0.25))
		"devil":
			ellipse(img, 8, 9, 6.5, 6.5, r)
			px(img, 2, 0, r)
			rect(img, 2, 1, 2, 2, r)
			rect(img, 3, 3, 2, 1, r)
			px(img, 13, 0, r)
			rect(img, 12, 1, 2, 2, r)
			rect(img, 11, 3, 2, 1, r)
			rect(img, 5, 8, 2, 1, y)
			rect(img, 9, 8, 2, 1, y)
			px(img, 4, 7, k)
			px(img, 11, 7, k)
			px(img, 4, 11, k)
			rect(img, 5, 12, 6, 1, k)
			px(img, 11, 11, k)
		"rose":
			var g := Color("4f9a44")
			rect(img, 7, 8, 1, 8, g)
			rect(img, 8, 11, 3, 1, g)
			px(img, 10, 10, g)
			rect(img, 4, 13, 3, 1, g)
			ellipse(img, 7.5, 5, 4.5, 4, r)
			px(img, 7, 3, m)
			px(img, 8, 4, m)
			px(img, 6, 5, m)
			px(img, 9, 6, m)
		"ghost":
			var gh := ghost_img(14, 15, Color("a6e6f2"), k, false)
			img.blit_rect(gh, Rect2i(Vector2i.ZERO, gh.get_size()), Vector2i(1, 1))
		"gift":
			rect(img, 2, 8, 12, 8, r)
			rect(img, 1, 5, 14, 3, r.lightened(0.15))
			rect(img, 7, 5, 2, 11, w)
			rect(img, 1, 10, 14, 1, w)
			ellipse(img, 5.5, 3, 2.5, 2, w)
			ellipse(img, 10.5, 3, 2.5, 2, w)
		"lips":
			ellipse(img, 8, 6.5, 7, 2.5, r)
			ellipse(img, 8, 9.5, 6, 2.5, r)
			rect(img, 2, 8, 12, 1, m)
			px(img, 8, 4, Color(0, 0, 0, 0))
			px(img, 5, 10, r.lightened(0.35))
		"heart":
			ellipse(img, 5, 5.5, 3.5, 3.5, r)
			ellipse(img, 11, 5.5, 3.5, 3.5, r)
			for i in 8:
				rect(img, 1 + i, 6 + i, 14 - 2 * i, 1, r)
			px(img, 4, 4, w)
		"wave":
			_face(img, y)
			rect(img, 5, 6, 1, 2, k)
			rect(img, 10, 6, 1, 2, k)
			px(img, 5, 10, k)
			rect(img, 6, 11, 4, 1, k)
			px(img, 10, 10, k)
			rect(img, 0, 9, 4, 6, s)
			for f in 3:
				rect(img, f + f / 2, 6, 1, 3, s)
		"left", "up", "right", "down":
			ellipse(img, 8, 8, 7, 7, Color("3b7be0"))
			for i in 5:
				rect(img, 7 - i, 3 + i, 2 + 2 * i, 1, w)
			rect(img, 6, 8, 4, 5, w)
			match id:
				"right": img.rotate_90(CLOCKWISE)
				"left": img.rotate_90(COUNTERCLOCKWISE)
				"down": img.rotate_180()
	return img

# ---------------------------------------------------------------- world themes
const THEMES := {
	"grass": {"sky": ["6fb6dc", "bfe3ee"], "mount": "5a8c8a", "snow": "e8f2f2", "hills": "3f8a52", "top": "5cbf3f", "top2": "3e9a2e", "dirt": "8a5a32", "dirt2": "6e4426", "cave": "4a3020"},
	"dark": {"sky": ["2a2340", "5a4a6e"], "mount": "4a3e6a", "snow": "9a8ab0", "hills": "2e2a3e", "top": "6a5a8a", "top2": "4a3e66", "dirt": "3e3040", "dirt2": "2c2230", "cave": "1e1624"},
	"hell": {"sky": ["3a1020", "7a2a3a"], "mount": "5a1e3a", "snow": "c83a6a", "hills": "3a1028", "top": "8a3a6a", "top2": "5a2048", "dirt": "3a1a30", "dirt2": "2a1020", "cave": "1a0a14"},
	"ice": {"sky": ["9ad0f0", "e3f2f8"], "mount": "8ab0d0", "snow": "ffffff", "hills": "a6c8e0", "top": "e3f2f8", "top2": "a6d0e8", "dirt": "5a8ab0", "dirt2": "4a7098", "cave": "2a4a6a"},
	"dream": {"sky": ["f0a8d8", "fde2f2"], "mount": "c88ac8", "snow": "fff0fa", "hills": "a870c0", "top": "f08ac8", "top2": "c86aa8", "dirt": "7a4a8a", "dirt2": "5a3a6a", "cave": "3a2a4a"},
	# Modina Ruins is yellow (Brenden, 2026-11-06); it was a poison green
	"modina": {"sky": ["c8901e", "f6dc6a"], "mount": "b8862a", "snow": "fff2a0", "hills": "8a6418", "top": "f2cf3a", "top2": "c89a1e", "dirt": "8a6a2a", "dirt2": "6a4e1e", "cave": "2a1e0a"},
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

func node_tex(kind: String, th: Dictionary) -> Texture2D:
	return cached("node_%s_%s" % [kind, th.name], func():
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(kind)
		var img: Image
		var ore := {"copper": "e8864a", "iron": "8ab0d8", "silver": "e3ebf5", "gold": "f2cf5b", "erbium_rock": "e04a7a", "ice_rock": "a6e6f2", "volcanic_rock": "ff5a2a", "sandnite_rock": "f2e0a0"}
		match kind:
			"tree", "blue_tree":
				# a bushy crown built from leaf clumps (lit on the top left, shaded
				# underneath) on a trunk with bark, a knot and flared roots
				img = blank(26, 48)
				var trunk := Color("7a4a26") if kind == "tree" else Color("3b5dc9")
				if th.name == "dark" and kind == "tree": trunk = Color("4a3e4a")
				if th.name == "ice": trunk = Color("6a8aa8")
				rect(img, 11, 18, 4, 30, trunk)
				rect(img, 11, 18, 1, 30, shade(trunk, 0.7))
				rect(img, 14, 18, 1, 30, shade(trunk, -0.8))
				rect(img, 10, 45, 6, 3, trunk)
				px(img, 9, 47, trunk)
				px(img, 16, 47, shade(trunk, -0.8))
				rect(img, 11, 18, 4, 4, shade(trunk, -1.2)) # the crown's shadow
				for b in [[12, 27], [13, 34], [12, 40]]:
					px(img, b[0], b[1], shade(trunk, -1.0))
					px(img, b[0], b[1] + 1, shade(trunk, -1.0))
				px(img, 13, 30, shade(trunk, 0.6))
				var leaf := Color("3e9a3a") if kind == "tree" else Color("7b4fb8")
				if th.name == "dark" and kind == "tree": leaf = Color("5a4a7a")
				if th.name == "ice": leaf = Color("e3f2f8")
				var deep := shade(leaf, -1.2)
				var lit := shade(leaf, 0.6)
				ellipse(img, 13, 13, 12, 8, deep)
				ellipse(img, 6, 15, 5, 4, deep)
				ellipse(img, 20, 15, 5, 4, deep)
				ellipse(img, 12, 10, 10, 7, leaf)
				ellipse(img, 19, 11, 6, 5, leaf)
				ellipse(img, 6, 12, 5, 4, leaf)
				ellipse(img, 13, 5, 6, 4, leaf)
				ellipse(img, 8, 8, 4, 3, lit)
				ellipse(img, 13, 4, 4, 2, lit)
				ellipse(img, 18, 9, 3, 2, lit)
				for q in [[6, 6], [11, 3], [17, 8]]:
					px(img, q[0], q[1], shade(leaf, 1.3))
					px(img, q[0] + 1, q[1], shade(leaf, 1.3))
				# leafy dents along the underside
				for q in [[4, 17], [9, 20], [14, 20], [18, 19], [22, 17]]:
					px(img, q[0], q[1], leaf)
				for q in [[10, 14], [15, 13], [20, 13], [5, 13]]:
					px(img, q[0], q[1], deep)
					px(img, q[0] + 1, q[1] + 1, deep)
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
				# a lumpy boulder lit from the top left, with cracks; ore shows as
				# shiny faceted nuggets, crystal rocks grow thin shards on top
				# (Brenden, 2026-11-06: "make crystals better looking and thinner
				# same with ores give them more detail")
				var crystal := kind in ["ice_rock", "erbium_rock"]
				var top := 7 if crystal else 0
				img = blank(18, 14 + top)
				var base := Color("8a9099")
				if th.name == "ice": base = Color("a6c0d8")
				if th.name == "hell": base = Color("6a4a5a")
				if th.name == "tomb": base = Color("8a6a4a")
				if kind == "volcanic_rock": base = Color("3a2a2e")
				ellipse(img, 9, 8 + top, 9, 6, base)
				ellipse(img, 7, 7 + top, 6, 4, base.lightened(0.12))
				ellipse(img, 6, 5 + top, 3, 2, base.lightened(0.28))
				rect(img, 2, 12 + top, 14, 2, base.darkened(0.3))
				rect(img, 12, 6 + top, 3, 6, base.darkened(0.12))
				# cracks
				for cr in [[4, 9, 1], [11, 5, -1]]:
					for d in 3:
						px(img, cr[0] + d * cr[2], cr[1] + top + d, base.darkened(0.4))
				if ore.has(kind):
					var oc := Color(ore[kind])
					if crystal:
						for s in [[5, 7], [8, 10], [12, 6]]:
							shard(img, s[0], top + 5, s[1], oc)
						for i in 3:
							nugget(img, [3, 9, 12][i], [8, 10, 9][i] + top, oc)
					else:
						var spots := [[3, 6], [8, 4], [12, 7], [6, 9], [11, 10]]
						for sp in spots:
							nugget(img, sp[0] + rng.randi_range(0, 1), sp[1] + top, oc)
		return to_tex(outline(img)))

# ---------------------------------------------------------------- village and props
## A Pixel Town house, drawn like a little cartoon cottage: a shingled roof with
## eaves, a ridge cap and a brick chimney, wooden siding between corner posts,
## framed windows with a shine and a flower box, an arched door with a knob and
## a stone step, and a stone foundation. The wall and roof colours vary per house.
func house_tex(wall: Color, roof: Color, w: int = 52) -> Texture2D:
	return cached("house_%s_%s_%d" % [wall.to_html(), roof.to_html(), w], func():
		var h := 46
		var img := blank(w, h)
		var trim := wall.lerp(Color("fff8ec"), 0.6)
		var wood := Color("8a5a32")
		var x0 := 4
		var x1 := w - 5 # the wall's last column
		var wall_top := 21
		# stone foundation
		for y in range(h - 4, h):
			for x in range(x0 - 1, x1 + 2):
				var stone := Color("8f8a96") if ((x + (2 if y >= h - 2 else 0)) / 4) % 2 == 0 else Color("7d7884")
				px(img, x, y, stone if (x + (2 if y >= h - 2 else 0)) % 4 != 3 else Color("5e5a66"))
		rect(img, x0 - 1, h - 4, x1 - x0 + 3, 1, Color("a8a4b0"))
		# siding: boards three pixels tall, a groove and a lit top line on each
		for y in range(wall_top, h - 4):
			var row := (y - wall_top) % 3
			var c := wall if row != 2 else wall.darkened(0.16)
			if row == 0:
				c = wall.lightened(0.08)
			rect(img, x0, y, x1 - x0 + 1, 1, c)
		# a soft shadow under the eaves
		rect(img, x0, wall_top, x1 - x0 + 1, 2, wall.darkened(0.28))
		# corner posts
		for x in [x0, x0 + 1, x1 - 1, x1]:
			rect(img, x, wall_top, 1, h - 4 - wall_top, trim if x == x0 or x == x1 - 1 else trim.darkened(0.12))
		# windows: a frame, four panes with a sky gradient and a shine, a sill and a flower box
		for wx in [x0 + 4, x1 - 13]:
			var wy := 27
			rect(img, wx - 1, wy - 1, 11, 10, trim)
			rect(img, wx, wy, 9, 8, Color("8fd8f2"))
			rect(img, wx, wy + 4, 9, 4, Color("5ab0d8"))
			rect(img, wx + 4, wy, 1, 8, trim)
			rect(img, wx, wy + 3, 9, 1, trim)
			px(img, wx + 1, wy + 1, Color("f2fbff"))
			px(img, wx + 2, wy + 1, Color("f2fbff"))
			px(img, wx + 1, wy + 2, Color("f2fbff"))
			px(img, wx + 6, wy + 5, Color("d8f2fb"))
			rect(img, wx - 2, wy + 8, 13, 1, trim.darkened(0.15))
			# a flower box
			rect(img, wx - 1, wy + 9, 11, 2, wood)
			rect(img, wx - 1, wy + 9, 11, 1, wood.lightened(0.15))
			for f in 4:
				var fc: Color = [Color("f25a6a"), Color("ffe46a"), Color("f2f2f6"), Color("f25a6a")][(f + int(roof.h * 10)) % 4]
				px(img, wx + f * 3, wy + 8, Color("4f9a44"))
				px(img, wx + f * 3, wy + 7, fc)
		# the door: an arch, planks, a knob and a stone step
		var dw := 10
		var dx := w / 2 - dw / 2
		var dy := 30
		rect(img, dx - 1, dy - 1, dw + 2, h - 4 - dy + 1, trim)
		rect(img, dx, dy, dw, h - 4 - dy, wood)
		for k in [2, 5, 8]:
			rect(img, dx + k, dy + 1, 1, h - 5 - dy, wood.darkened(0.2))
		rect(img, dx, dy, dw, 1, wood.lightened(0.18))
		# a rounded top: the frame wraps the door's top corners
		px(img, dx, dy, trim)
		px(img, dx + dw - 1, dy, trim)
		px(img, dx - 1, dy - 1, wall.darkened(0.16))
		px(img, dx + dw, dy - 1, wall.darkened(0.16))
		rect(img, dx + dw - 3, dy + 7, 2, 2, Color("f2cf5b"))
		px(img, dx + dw - 3, dy + 7, Color("fff2b0"))
		rect(img, dx - 2, h - 5, dw + 4, 1, Color("b8b4c0"))
		# a brick chimney on the right slope
		var cx := w - 16
		for y in range(5, 16):
			for x in range(cx, cx + 6):
				var brick := Color("b8583a") if ((x + (2 if (y / 2) % 2 else 0)) / 3) % 2 == 0 else Color("a24a30")
				px(img, x, y, brick if y % 2 == 0 or (x + (2 if (y / 2) % 2 else 0)) % 3 != 0 else Color("7a3424"))
		rect(img, cx - 1, 4, 8, 2, Color("6e6a76"))
		rect(img, cx - 1, 4, 8, 1, Color("8f8a96"))
		# the roof: shingle rows with a lit left slope and a shaded right slope,
		# eaves sticking out past the walls, and a ridge cap on top
		var peak := 3
		for y in range(peak, wall_top + 1):
			var half := int((y - peak) * 1.42) + 3
			var l := w / 2 - half
			var r := w / 2 + half - 1
			l = maxi(l, 0)
			r = mini(r, w - 1)
			var band := (y - peak) % 3
			for x in range(l, r + 1):
				var lit := x < w / 2
				var c := roof.lightened(0.08) if lit else roof.darkened(0.12)
				if band == 2:
					c = c.darkened(0.22)
				elif band == 0 and (x + (y / 3) * 2) % 4 == 0:
					c = c.darkened(0.12)
				px(img, x, y, c)
			# the roof's edge
			px(img, l, y, roof.darkened(0.35))
			px(img, r, y, roof.darkened(0.45))
		# eaves board
		rect(img, 0, wall_top - 1, w, 2, roof.darkened(0.4))
		rect(img, 0, wall_top - 1, w, 1, roof.darkened(0.25))
		# ridge cap
		rect(img, w / 2 - 4, peak - 1, 8, 2, roof.darkened(0.3))
		rect(img, w / 2 - 4, peak - 1, 8, 1, roof.lightened(0.15))
		# a round attic window in the gable
		ellipse(img, w / 2, 13, 3.2, 3.2, trim)
		ellipse(img, w / 2, 13, 2.2, 2.2, Color("5ab0d8"))
		px(img, w / 2 - 1, 12, Color("f2fbff"))
		return to_tex(outline(img)))

## The Game House (2026-11-13): the west house of Pixel Town with a sign of
## three little game tiles over its door.
func game_house_tex() -> Texture2D:
	return cached("game_house", func():
		var img: Image = house_tex(Color("e8dccb"), Color("d8433a"), 52).get_image().duplicate()
		var x0 := 18
		var y0 := 21
		rect(img, x0, y0, 16, 8, OUTLINE)
		rect(img, x0 + 1, y0 + 1, 14, 6, Color("8a5a32"))
		rect(img, x0 + 1, y0 + 1, 14, 1, Color("a8703f"))
		var tile_c := [Color("7b4fb8"), Color("5ce0d0"), Color("f2cf5b")]
		for i in 3:
			rect(img, x0 + 2 + i * 4, y0 + 2, 3, 4, tile_c[i])
			px(img, x0 + 2 + i * 4, y0 + 2, tile_c[i].lightened(0.4))
		return to_tex(img))

## Tile Match tiles, 30 pixels square: the back (a purple tile with a star),
## a prize face (cream, with the prize's picture) or a bad face (red).
const MATCH_TILE := 30
func match_tile(face: String) -> Texture2D:
	return cached("match_" + face, func():
		var n := MATCH_TILE
		var img := blank(n, n)
		var fill := Color("7b4fb8")
		if face == "back":
			fill = Color("7b4fb8")
		elif face in ["bomb", "stinker"]:
			fill = Color("f6b4a8")
		else:
			fill = Color("fff1d2")
		var rim := fill.darkened(0.45)
		# a rounded tile with a lit top and a thick shaded bottom lip
		rect(img, 1, 0, n - 2, n, rim)
		rect(img, 0, 1, n, n - 2, rim)
		rect(img, 1, 1, n - 2, n - 3, fill)
		rect(img, 1, n - 4, n - 2, 2, fill.darkened(0.2))
		rect(img, 2, 1, n - 4, 1, fill.lightened(0.35))
		if face == "back":
			# a diamond pattern and a big star in the middle
			for y in range(3, n - 4):
				for x in range(2, n - 2):
					if (x + y) % 6 == 0 or (x - y + 60) % 6 == 0:
						px(img, x, y, fill.lightened(0.12))
			var star := ["....y....", "...yyy...", "yyyyyyyyy", ".yyyyyyy.", "..yyyyy..", ".yyy.yyy.", ".yy...yy."]
			var si := grid_image(star, {"y": "f2cf5b"})
			img.blend_rect(outline(si), Rect2i(Vector2i.ZERO, si.get_size()), Vector2i((n - si.get_width()) / 2, (n - si.get_height()) / 2 - 1))
			return to_tex(img)
		var pic: Image
		match face:
			"bomb":
				pic = emote_img("bomb")
			"stinker":
				pic = emote_img("poop")
			"coin":
				pic = prop_tex("coin").get_image()
			_:
				pic = icon(MATCH_PICS.get(face, face)).get_image()
		pic = pic.duplicate()
		if pic.get_format() != Image.FORMAT_RGBA8:
			pic.convert(Image.FORMAT_RGBA8)
		img.blend_rect(pic, Rect2i(Vector2i.ZERO, pic.get_size()), Vector2i((n - pic.get_width()) / 2, (n - 2 - pic.get_height()) / 2))
		return to_tex(img))

const MATCH_PICS := {"gem": "gem", "potion": "small_potion", "key": "silver_key", "crystal": "crystal", "scroll": "combination_scroll"}

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

## Mountains: a sunny left face and a shaded right face on every peak, a ragged
## ridge, snow caps with a jagged lower edge, and haze toward the bottom. The far
## range is paler and closer to the sky's colour, so it reads as further away.
func mountains_tex(th: Dictionary, far := false) -> Texture2D:
	return cached("mount_%s_%s" % [th.name, far], func():
		var w := 512
		var h := 150
		var img := blank(w, h)
		var peaks := [[40, 70], [120, 40], [200, 80], [270, 30], [350, 64], [430, 46], [500, 74]]
		if far:
			peaks = [[0, 50], [90, 22], [170, 56], [240, 34], [320, 18], [400, 48], [470, 28]]
		var haze: Color = th.sky[1]
		var base: Color = th.mount.lerp(haze, 0.45) if far else th.mount
		var snow: Color = th.snow.lerp(haze, 0.35) if far else th.snow
		var slope := 0.75 if far else 0.9
		var lit := base.lightened(0.07)
		var shade := base.darkened(0.16)
		for x in w:
			# the highest slope over this column wins; the ridge gets a little roughness
			var top := 999.0
			var side := 0.0
			var dist := 0.0
			for p in peaks:
				for o in [-w, 0, w]:
					var dx := float(x - (p[0] + o))
					var t: float = p[1] + absf(dx) * slope
					if t < top:
						top = t
						side = signf(dx)
						dist = absf(dx)
			var rough := roundf(1.2 * sin(x * 0.31) + 0.8 * sin(x * 0.113 + 2.0))
			var ty := clampi(int(top + rough), 0, h)
			for y in range(ty, h):
				var c := lit if side <= 0 else shade
				# a few creases running down the faces
				if posmod(int(dist * 0.5) + y / 3, 23) == 0 and y > ty + 6:
					c = c.darkened(0.08) if side <= 0 else c.lightened(0.04)
				# snow on the peaks, with a zig-zag lower edge
				var cap := 17.0 - dist * 0.5 + absf(posmod(x, 10) - 5.0) * 0.9
				if y < ty + cap and dist < 34:
					c = snow if side <= 0 else snow.darkened(0.13)
					if y == ty and side <= 0:
						c = snow.lightened(0.3)
				# haze toward the bottom
				var k := clampf((y - (h - 60)) / 60.0, 0.0, 1.0) * (0.55 if far else 0.35)
				img.set_pixel(x, y, c.lerp(haze, k))
			# a lit rim along the sunny ridges
			if side <= 0 and dist > 2 and ty < h:
				img.set_pixel(x, ty, img.get_pixel(x, ty).lightened(0.12))
		return to_tex(img))

## A tree line: two rows of round treetops, the back row darker. Each bump is lit
## along its top edge and speckled with leaves, and a band of bushes closes the
## bottom. Tinted by the world's colours, so dark worlds get dark forests.
func hills_tex(th: Dictionary) -> Texture2D:
	return cached("hills_" + th.name, func():
		var w := 512
		var h := 90
		var img := blank(w, h)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var col: Color = th.hills
		for row in 2:
			var mask := blank(w, h)
			var n := 30 if row == 0 else 44
			for i in n:
				var x := rng.randi_range(0, w)
				var r := rng.randi_range(13, 21) if row == 0 else rng.randi_range(9, 15)
				var cy := (h - 40 if row == 0 else h - 26) + rng.randi_range(-6, 6)
				for o in [-w, 0, w]:
					ellipse(mask, x + o, cy, r, r * 1.1, Color.WHITE)
			rect(mask, 0, h - (26 if row == 0 else 14), w, 26 if row == 0 else 14, Color.WHITE)
			var c := col.darkened(0.18) if row == 0 else col
			for y in h:
				for x in w:
					if mask.get_pixel(x, y).a == 0.0:
						continue
					var pc := c
					if y == 0 or mask.get_pixel(x, y - 1).a == 0.0:
						pc = c.lightened(0.22)
					elif y < 2 or mask.get_pixel(x, y - 2).a == 0.0:
						pc = c.lightened(0.1)
					elif posmod(x * 7 + y * 13, 29) == 0:
						pc = c.darkened(0.12)
					img.set_pixel(x, y, pc)
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
	"lock": ["..kkkk..", ".k....k.", ".k....k.", "YYYYYYYY", "YggggggY", "YgggkggY", "YgggkggY", "YggggggY", "YYYYYYYY"],
	"close": ["kk....kk", ".kk..kk.", "..kkkk..", "...kk...", "..kkkk..", ".kk..kk.", "kk....kk"],
	"plus": ["..g..", "..g..", "ggggg", "..g..", "..g.."],
	"friend": ["..kk....", ".kkkk...", ".kkkk.k.", "..kk.kkk", ".kkkk.k.", "kkkkkk..", "kkkkkk.."],
	"chat": [".kkkkkk.", "kkkkkkkk", "kkkkkkkk", "kkkkkkkk", ".kkkkkk.", "..kk....", ".k......"],
	"smile": ["..kkkk..", ".k....k.", "k.k..k.k", "k......k", "k.k..k.k", "k..kk..k", ".k....k.", "..kkkk.."],
}

## Small interface icons (backpack, compass, bomb, hammer, trash, close).
func ui_icon(name: String, scale: int = 1) -> Texture2D:
	return cached("ui_%s_%d" % [name, scale], func():
		var map := {"N": "6a3a4a", "n": "9a5a6a", "Y": "c99a2e", "O": "e8862a", "k": "5a2a10", "g": "f2cf5b"}
		var img := grid_image(UI_GRIDS[name], map, scale)
		if name in ["trash", "close", "plus", "friend", "chat", "smile"]:
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
