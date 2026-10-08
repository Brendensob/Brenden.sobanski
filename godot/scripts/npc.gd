extends Node2D
## A villager. Walk up and press A to talk.

var data: Dictionary
var level: Node
var sprite: Sprite2D
var badge: Label
var t := 0.0

func setup(d: Dictionary, lvl: Node) -> void:
	data = d
	level = lvl

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = Art.character(data.look)
	sprite.position = Vector2(0, -9)
	sprite.flip_h = true
	add_child(sprite)
	var name_label := Label.new()
	name_label.text = data.name
	name_label.add_theme_font_override("font", Art.font_body)
	name_label.add_theme_font_size_override("font_size", 6)
	name_label.add_theme_color_override("font_outline_color", Color("1b1a24"))
	name_label.add_theme_constant_override("outline_size", 2)
	name_label.size = Vector2(60, 10)
	name_label.position = Vector2(-30, -32)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_label)
	badge = Label.new()
	badge.add_theme_font_override("font", Art.font_title)
	badge.add_theme_font_size_override("font_size", 6)
	badge.add_theme_color_override("font_color", Color("f2cf5b"))
	badge.add_theme_color_override("font_outline_color", Color("1b1a24"))
	badge.add_theme_constant_override("outline_size", 2)
	badge.size = Vector2(20, 10)
	badge.position = Vector2(-10, -42)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(badge)

func _process(delta: float) -> void:
	t += delta
	sprite.position.y = -9 - (1 if int(t * 2) % 2 == 0 else 0)
	var q: Dictionary = GS.next_quest(data.id)
	if data.get("shop", false):
		badge.text = "$"
	elif q.is_empty():
		badge.text = ""
	else:
		badge.text = "?" if GS.quest_ready(q) else "!"
	sprite.flip_h = level.player.position.x < position.x

func interact(_player: Node) -> void:
	level.main.hud.open_dialog(data)
