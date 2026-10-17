extends Sprite2D
## An emote over someone's head: it pops up, bobs gently and fades after a
## few seconds. A new emote replaces the old one.

const SHOW_TIME := 3.0
var t := 0.0

func setup(id: String) -> void:
	name = "Emote"
	texture = Art.emote(id)
	position = Vector2(0, -47)
	z_index = 5

func _process(delta: float) -> void:
	t += delta
	# cartoon pop in, then a slow bob
	scale = Vector2.ONE * (1.0 + 0.6 * exp(-t * 10.0)) if t < 0.5 else Vector2.ONE
	position.y = -47 + sin(t * 4.0) * 1.0
	modulate.a = clampf((SHOW_TIME - t) / 0.4, 0, 1)
	if t > SHOW_TIME:
		queue_free()
