extends RefCounted
## Tile Match, the Game House's game (our own, 2026-11-13). Brenden: "make house
## on left a minigame room you can play every 2.5 hours and get gems or other
## rewards from by doing minigames ... where you smack the tiles and try to
## match stuff to get rewards or you match the bad ones and lose".
##
## 16 tiles lie face down: 6 pairs of prizes and 2 bad pairs (a Bomb and a Stinker).
## Smack two tiles to turn them over:
## - a matching prize pair goes into your prize pot and stays face up;
## - a matching bad pair loses the whole pot and ends the game;
## - anything else turns back over and costs one miss.
## The game ends when the misses run out, every prize is found, or you take
## your prizes. Then the pot is yours.
##
## Every amount here is a placeholder for Brenden to set.

const COLS := 4
const ROWS := 4
const MISSES := 5 # placeholder
## The prize pairs: what each one puts in the pot. Placeholders.
const PRIZES := {
	"gem": {"item": "gem", "n": 2},
	"coin": {"item": "coin", "n": 150},
	"potion": {"item": "small_potion", "n": 2},
	"key": {"item": "silver_key", "n": 1},
	"crystal": {"item": "crystal", "n": 3},
	"scroll": {"item": "combination_scroll", "n": 1},
}
## The bad pairs: matching either one loses the pot.
const BAD := ["bomb", "stinker"]

var tiles := [] # the face on each tile
var up := [] # true for tiles turned face up for good (a found prize pair)
var first := -1 # the tile turned over first this turn, or -1
var misses := MISSES
var pot := {} # prize id -> how many pairs found
var over := false
var lost := false

func _init(seed := -1) -> void:
	var rng := RandomNumberGenerator.new()
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
	for f in PRIZES.keys() + BAD:
		tiles.append(f)
		tiles.append(f)
	# shuffle with our own generator, so a seed gives the same board in tests
	for i in range(tiles.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = tiles[i]
		tiles[i] = tiles[j]
		tiles[j] = t
	up.resize(tiles.size())
	up.fill(false)

static func is_bad(face: String) -> bool:
	return face in BAD

## Smacks tile i. Returns what happened:
## {"what": "first" | "match" | "bad" | "miss" | "none", "a": tile, "b": tile, "face": face}
func smack(i: int) -> Dictionary:
	if over or i < 0 or i >= tiles.size() or up[i] or i == first:
		return {"what": "none"}
	if first < 0:
		first = i
		return {"what": "first", "a": i, "face": tiles[i]}
	var a := first
	first = -1
	var res := {"a": a, "b": i, "face": tiles[i]}
	if tiles[a] != tiles[i]:
		misses -= 1
		if misses <= 0:
			over = true
		res.what = "miss"
		return res
	if is_bad(tiles[i]):
		lost = true
		over = true
		pot.clear()
		res.what = "bad"
		return res
	up[a] = true
	up[i] = true
	pot[tiles[i]] = pot.get(tiles[i], 0) + 1
	if prizes_left() == 0:
		over = true
	res.what = "match"
	return res

func prizes_left() -> int:
	var n := 0
	for i in tiles.size():
		if not up[i] and not is_bad(tiles[i]):
			n += 1
	return n / 2

## Stop now and keep the pot.
func cash_out() -> void:
	over = true

## What the pot pays: {item id: count}.
func payout() -> Dictionary:
	var out := {}
	if lost:
		return out
	for f in pot:
		var p: Dictionary = PRIZES[f]
		out[p.item] = out.get(p.item, 0) + int(p.n) * int(pot[f])
	return out
