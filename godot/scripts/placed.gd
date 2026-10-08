extends Node2D
## Something you built: walls block monsters, spikes hurt them, a campfire
## heals you, a work station lets you smith anywhere, and torches give light.

var item := ""
var level: Node
var hp := 1.0
var sprite: Sprite2D
var t := 0.0

func setup(id: String, lvl: Node) -> void:
	item = id
	level = lvl
	hp = float(Data.ITEMS[id].get("hp", 30))

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = false
	match item:
		"wood_wall", "stone_wall":
			sprite.texture = Art.prop_tex("wall", "wood" if item == "wood_wall" else "stone")
			var body := StaticBody2D.new()
			body.collision_layer = 1
			body.collision_mask = 0
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(16, 32)
			shape.shape = rect
			shape.position = Vector2(0, -16)
			body.add_child(shape)
			add_child(body)
		"wooden_spikes":
			sprite.texture = Art.prop_tex("spikes")
		"work_station":
			sprite.texture = Art.prop_tex("work_station")
		"campfire":
			sprite.texture = Art.prop_tex("campfire")
			_light(Color("f2a33a"), 1.8)
		"torch":
			sprite.texture = Art.prop_tex("torch")
			_light(Color("f2b35a"), 2.0)
	var s: Vector2 = sprite.texture.get_size()
	sprite.position = Vector2(-s.x / 2, -s.y + 1)
	add_child(sprite)

func _light(c: Color, scale: float) -> void:
	var l := PointLight2D.new()
	l.texture = Art.light_tex()
	l.color = c
	l.energy = 0.8
	l.texture_scale = scale
	l.position = Vector2(0, -10)
	add_child(l)

func _process(delta: float) -> void:
	if item == "campfire":
		t += delta
		sprite.texture = Art.prop_tex("campfire", "b" if int(t * 6) % 2 else "")

func is_wall() -> bool:
	return item == "wood_wall" or item == "stone_wall"

func trap_damage() -> int:
	return int(Data.ITEMS[item].get("trap", 0)) if item == "wooden_spikes" else 0

func interact(_player: Node) -> void:
	if item == "work_station":
		level.main.hud.open_smith()

func damage(amount: float) -> void:
	hp -= amount
	level.burst(position + Vector2(0, -16), Color("a8703f") if item == "wood_wall" else Color("9aa2ad"), 3)
	if hp <= 0:
		level.burst(position + Vector2(0, -16), Color("a8703f"), 10)
		queue_free()
