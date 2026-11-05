extends Node2D
## The ripple of jelly the Jelly King sends along the ground when he slams down
## from a big jump. It rolls away along the floor on both sides; it hurts if it
## runs into you while you're on the ground, so jump over it (Brenden,
## 2026-11-05: "he jumps high sometimes slams and you have to jump").

const SPEED := 125.0
const LIFE := 2.4
const HEIGHT := 9.0

var level: Node
var dir := 1
var dmg := 4
var life := LIFE
var t := 0.0

func setup(lvl: Node, d: int, damage: int) -> void:
	level = lvl
	dir = d
	dmg = damage

## Where it can hurt: low along the ground, so a jump clears it.
func hit_rect() -> Rect2:
	return Rect2(position.x - 7, position.y - HEIGHT, 14, HEIGHT)

func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	position.x += dir * SPEED * delta
	var cx := int(floor(position.x / 16.0))
	var floor_y := int(floor((position.y + 1) / 16.0))
	# it stops at a wall or where the floor ends
	if life <= 0 or not level.solid(cx, floor_y) or level.solid(cx, floor_y - 1):
		queue_free()
		return
	var p: Node2D = level.player
	if is_instance_valid(p) and not p.dead and hit_rect().intersects(p.hit_rect()):
		p.hurt(dmg, 0.05, position.x - dir * 10)
	queue_redraw()

func _draw() -> void:
	var fade := clampf(life / 0.4, 0, 1)
	var body := Color("f06aa0", 0.9 * fade)
	var dark := Color("b04a78", 0.9 * fade)
	var lite := Color("ffc0da", 0.9 * fade)
	# a wobbling crest of goo, tallest at the front
	for i in 5:
		var x := -dir * i * 3.0
		var h := (HEIGHT - i * 1.6) * (0.85 + 0.15 * sin(t * 20.0 + i))
		draw_rect(Rect2(x - 2, -h, 4, h), body)
		draw_rect(Rect2(x - 2, -h, 4, 1), lite)
		draw_rect(Rect2(x - 2, -1, 4, 1), dark)
