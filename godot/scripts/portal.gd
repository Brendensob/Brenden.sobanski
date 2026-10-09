extends Node2D
## A portal to another place. Stand in it and press A.

var target := ""
var label_text := ""
var level: Node
var sprite: Sprite2D
var t := 0.0
var tint := Color("4fb6d0")

func setup(tgt: String, lbl: String, lvl: Node, color: Color) -> void:
	target = tgt
	label_text = lbl
	level = lvl
	tint = color

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.position = Vector2(0, -18)
	add_child(sprite)
	var l := Label.new()
	l.text = label_text
	l.add_theme_font_override("font", Art.font_body)
	l.add_theme_font_size_override("font_size", 6)
	l.add_theme_color_override("font_outline_color", Color("1b1a24"))
	l.add_theme_constant_override("outline_size", 2)
	l.size = Vector2(80, 10)
	l.position = Vector2(-40, -46)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	var light := PointLight2D.new()
	light.texture = Art.light_tex()
	light.color = tint
	light.energy = 0.8
	light.texture_scale = 0.8
	light.position = Vector2(0, -18)
	add_child(light)

func _process(delta: float) -> void:
	t += delta
	sprite.texture = Art.portal_tex(int(t * 6) % 4, tint)

func interact(_player: Node) -> void:
	level.main.use_portal(target)
