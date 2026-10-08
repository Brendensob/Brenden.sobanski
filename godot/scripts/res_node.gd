extends Node2D
## A tree, rock or bush you can harvest. Grows back after a while.

const REGROW := 45.0

var kind := ""
var def: Dictionary
var level: Node
var hp := 1.0
var alive := true
var regrow := 0.0
var wobble := 0.0
var sprite: Sprite2D

func setup(k: String, lvl: Node) -> void:
	kind = k
	def = Data.NODES[k]
	level = lvl
	hp = def.hp

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = Art.node_tex(kind, level.zone)
	sprite.centered = false
	var s: Vector2 = sprite.texture.get_size()
	sprite.position = Vector2(-s.x / 2, -s.y + 1)
	add_child(sprite)

func _process(delta: float) -> void:
	if not alive:
		regrow -= delta
		if regrow <= 0:
			alive = true
			hp = def.hp
			sprite.visible = true
			sprite.modulate.a = 0
			create_tween().tween_property(sprite, "modulate:a", 1.0, 0.5)
		return
	if wobble > 0:
		wobble -= delta
		var s: Vector2 = sprite.texture.get_size()
		sprite.position.x = -s.x / 2 + sin(wobble * 60) * 1.5

func hit_rect() -> Rect2:
	var s: Vector2 = sprite.texture.get_size()
	var w := minf(s.x, 14)
	return Rect2(position.x - w / 2, position.y - minf(s.y, 30), w, minf(s.y, 30))

func shake() -> void:
	wobble = 0.15

func hit(power: int) -> void:
	hp -= power
	shake()
	var c := Color("8a9099") if def.need == "pick" else Color("3e9a3a")
	level.burst(position + Vector2(0, -8), c, 3)
	if hp <= 0:
		alive = false
		regrow = REGROW
		sprite.visible = false
		level.burst(position + Vector2(0, -8), c, 8)
		for d in def.drops:
			if randf() < d[1]:
				level.drop(d[0], randi_range(d[2], d[3]), position + Vector2(0, -6))
