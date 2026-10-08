extends Node2D
## A magic bolt, an arrow, or a monster's shot.

var level: Node
var vel := Vector2.ZERO
var dmg := 1
var friendly := true
var color := Color.WHITE
var life := 1.6
var gravity := 0.0

func setup(lvl: Node, v: Vector2, damage: int, from_player: bool, c: Color) -> void:
	level = lvl
	vel = v
	dmg = damage
	friendly = from_player
	color = c

func _ready() -> void:
	var light := PointLight2D.new()
	light.texture = Art.light_tex()
	light.color = color
	light.texture_scale = 0.4
	add_child(light)

func _process(delta: float) -> void:
	life -= delta
	vel.y += gravity * delta
	position += vel * delta
	queue_redraw()
	var cx := int(position.x / 16)
	var cy := int(position.y / 16)
	if life <= 0 or level.solid(cx, cy):
		level.burst(position, color, 4)
		queue_free()
		return
	var r := Rect2(position.x - 3, position.y - 3, 6, 6)
	if friendly:
		var hit: Array = level.mobs_in_rect(r)
		if hit.size() > 0:
			hit[0].take_damage(dmg, position.x - signf(vel.x) * 10, true)
			level.burst(position, color, 6)
			queue_free()
	elif not level.player.dead and r.intersects(level.player.hit_rect()):
		level.player.hurt(dmg, 0.05, position.x - signf(vel.x) * 10)
		queue_free()

func _draw() -> void:
	draw_rect(Rect2(-3, -3, 6, 6), Color("1b1a24"))
	draw_rect(Rect2(-2, -2, 4, 4), color)
	draw_rect(Rect2(-1, -1, 2, 2), Color.WHITE)
