extends Node2D
## Something you built: a wall that blocks monsters, or a torch.

var item := ""
var level: Node
var hp := 1.0
var body: StaticBody2D
var sprite: Sprite2D

func setup(id: String, lvl: Node) -> void:
	item = id
	level = lvl
	hp = float(Data.ITEMS[id].get("hp", 1))

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = false
	if is_wall():
		var img := Art.grid_image(Art.GRIDS[item])
		var tall := Image.create(8, 32, false, Image.FORMAT_RGBA8)
		tall.blit_rect(img, Rect2i(0, 0, 8, 16), Vector2i(0, 0))
		tall.blit_rect(img, Rect2i(0, 0, 8, 16), Vector2i(0, 16))
		var wide := Image.create(16, 32, false, Image.FORMAT_RGBA8)
		wide.blit_rect(tall, Rect2i(0, 0, 8, 32), Vector2i(0, 0))
		wide.blit_rect(tall, Rect2i(0, 0, 8, 32), Vector2i(8, 0))
		sprite.texture = Art.to_tex(Art.outline(wide))
		sprite.position = Vector2(-9, -33)
		body = StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(16, 32)
		shape.shape = rect
		shape.position = Vector2(0, -16)
		body.add_child(shape)
		add_child(body)
	else:
		sprite.texture = Art.prop_tex("torch")
		sprite.position = Vector2(-3, -12)
		var light := PointLight2D.new()
		light.texture = Art.light_tex()
		light.color = Color("f2b35a")
		light.energy = 0.7
		light.texture_scale = 2.0
		light.position = Vector2(0, -10)
		add_child(light)
	add_child(sprite)

func is_wall() -> bool:
	return item != "torch"

func damage(amount: float) -> void:
	hp -= amount
	level.burst(position + Vector2(0, -16), Color("a8703f") if item == "wood_wall" else Color("9aa2ad"), 3)
	if hp <= 0:
		level.burst(position + Vector2(0, -16), Color("a8703f"), 10)
		queue_free()
