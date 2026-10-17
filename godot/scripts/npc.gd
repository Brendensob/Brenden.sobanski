extends Node2D
## A villager. Stand next to them, face them and press A.

var npc_id := ""
var data: Dictionary
var level: Node
var sprite: Sprite2D
var badge: Label
var t := 0.0
var say: Label
var say_t := 0.0

func setup(id: String, lvl: Node) -> void:
	npc_id = id
	data = Data.NPCS[id]
	level = lvl

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = Art.character(data.look)
	sprite.position = Vector2(0, -sprite.texture.get_height() / 2.0)
	add_child(sprite)
	add_child(_label(data.name, Vector2(-30, -36), Color.WHITE, Art.font_body))
	badge = _label("", Vector2(-10, -46), Color("f2cf5b"), Art.font_title)
	add_child(badge)
	# shopkeepers call out now and then, like the original
	say = _label("New stocked items!", Vector2(-50, -46), Color.WHITE, Art.font_body)
	say.visible = false
	add_child(say)
	say_t = randf_range(2.0, 8.0)

func _label(text: String, pos: Vector2, c: Color, f: Font) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", 6)
	l.add_theme_color_override("font_color", c)
	l.add_theme_color_override("font_outline_color", Color("1b1a24"))
	l.add_theme_constant_override("outline_size", 2)
	l.size = Vector2(-pos.x * 2, 10)
	l.position = pos
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _process(delta: float) -> void:
	t += delta
	sprite.position.y = -9 - (1 if int(t * 2) % 2 == 0 else 0)
	var q: Dictionary = GS.next_quest(npc_id)
	if not q.is_empty():
		badge.text = "?" if GS.quest_ready(q) else "!"
	elif Data.SHOPS.has(npc_id):
		badge.text = "$"
	else:
		badge.text = ""
	sprite.flip_h = level.player.position.x < position.x
	if Data.SHOPS.has(npc_id):
		say_t -= delta
		if say_t <= 0:
			say.visible = not say.visible
			say_t = 4.0 if say.visible else randf_range(10.0, 18.0)
		badge.visible = not say.visible

func interact(_player: Node) -> void:
	level.main.hud.open_npc(npc_id)
