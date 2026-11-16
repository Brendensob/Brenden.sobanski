extends RefCounted
## High or Low, a Game House game (our own, 2026-11-16). A push-your-luck game:
## a card from 1 to 9 is face up. Guess whether the next card is higher or
## lower. Every right guess moves your prize up the ladder; one wrong guess
## loses it all. Take your prize whenever you like.
##
## Every prize here is a placeholder for Brenden to set.

const LOW := 1
const HIGH := 9
## The prize after 1, 2, 3... right guesses in a row. Placeholders.
const LADDER := [
	{"coin": 100},
	{"coin": 250},
	{"gem": 1, "coin": 250},
	{"gem": 2, "coin": 400},
	{"gem": 4, "coin": 600},
	{"gem": 8, "coin": 1000},
]

var card := 5
var streak := 0
var over := false
var lost := false
var rng := RandomNumberGenerator.new()

func _init(seed := -1) -> void:
	if seed >= 0:
		rng.seed = seed
	else:
		rng.randomize()
	card = rng.randi_range(LOW, HIGH)

## The next card is never the same number, so every guess wins or loses.
func _draw_card() -> int:
	var n := rng.randi_range(LOW, HIGH - 1)
	return n + 1 if n >= card else n

## Guess higher (true) or lower (false). Returns {"ok": right or not, "card": the new card}.
func guess(higher: bool) -> Dictionary:
	if over:
		return {"ok": false, "card": card, "none": true}
	var next := _draw_card()
	var ok := next > card if higher else next < card
	card = next
	if ok:
		streak += 1
		if streak >= LADDER.size():
			over = true
	else:
		lost = true
		over = true
	return {"ok": ok, "card": next}

## Stop now and keep your prize.
func cash_out() -> void:
	over = true

func payout() -> Dictionary:
	if lost or streak == 0:
		return {}
	return (LADDER[streak - 1] as Dictionary).duplicate()

## The prize one more right guess would give, or {} at the top of the ladder.
func next_prize() -> Dictionary:
	return LADDER[streak] if streak < LADDER.size() else {}
