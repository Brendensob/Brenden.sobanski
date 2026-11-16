extends RefCounted
## Slime Smack, a Game House game (our own, 2026-11-16). Brenden asked for more
## minigames like Tile Match, where you smack things for prizes.
##
## Nine holes. For 20 seconds slimes pop up out of them and duck back down.
## Smack a slime for 1 point and a gold slime for 3. Smack a bomb and you lose
## 3 points. They come faster as the clock runs down. Your score picks the prize.
##
## Every number here is a placeholder for Brenden to set.

const HOLES := 9
const TIME := 20.0
const SLIME := 1
const GOLD := 3
const BOMB := -3
## [score needed, prize]: the best one you reach is yours. Placeholders.
const PRIZES := [
	[8, {"coin": 150}],
	[16, {"coin": 300, "small_potion": 2}],
	[24, {"gem": 2, "coin": 300}],
	[32, {"gem": 4, "coin": 500}],
]

var holes := [] # what is up in each hole: "", "slime", "gold" or "bomb"
var up_t := [] # how long it stays up
var time_left := TIME
var score := 0
var spawn_t := 0.5
var over := false
var rng := RandomNumberGenerator.new()

func _init(seed := -1) -> void:
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
	holes.resize(HOLES)
	holes.fill("")
	up_t.resize(HOLES)
	up_t.fill(0.0)

## 0 at the start, 1 at the end: things come faster and stay up shorter.
func progress() -> float:
	return clampf(1.0 - time_left / TIME, 0.0, 1.0)

## Moves the game on. Returns the holes that changed.
func tick(delta: float) -> Array:
	var changed := []
	if over:
		return changed
	time_left -= delta
	for i in HOLES:
		if holes[i] != "":
			up_t[i] -= delta
			if up_t[i] <= 0:
				holes[i] = ""
				changed.append(i)
	if time_left <= 0:
		time_left = 0.0
		over = true
		for i in HOLES:
			if holes[i] != "":
				holes[i] = ""
				changed.append(i)
		return changed
	spawn_t -= delta
	if spawn_t <= 0:
		spawn_t = lerpf(0.75, 0.35, progress())
		var free := []
		for i in HOLES:
			if holes[i] == "":
				free.append(i)
		if not free.is_empty():
			var i: int = free[rng.randi() % free.size()]
			var r := rng.randf()
			holes[i] = "gold" if r < 0.12 else ("bomb" if r < 0.3 else "slime")
			up_t[i] = lerpf(1.2, 0.65, progress())
			changed.append(i)
	return changed

## Smacks hole i. Returns what was in it ("" when it was empty).
func smack(i: int) -> String:
	if over or i < 0 or i >= HOLES or holes[i] == "":
		return ""
	var what: String = holes[i]
	holes[i] = ""
	match what:
		"slime": score += SLIME
		"gold": score += GOLD
		"bomb": score = maxi(0, score + BOMB)
	return what

## Stop now and keep the prize your score has reached.
func cash_out() -> void:
	over = true

## The prize for the score so far: {item id: count}.
func payout() -> Dictionary:
	var best := {}
	for p in PRIZES:
		if score >= int(p[0]):
			best = p[1]
	return best.duplicate()

## The score needed for the next prize, or -1 when you've reached the best one.
func next_goal() -> int:
	for p in PRIZES:
		if score < int(p[0]):
			return int(p[0])
	return -1
