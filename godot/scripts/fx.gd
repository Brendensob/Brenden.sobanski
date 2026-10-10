extends Node2D
## Floating damage numbers and little bursts of pixels.

var t := 0.0
var label: Label
var parts: Array = []
var color := Color.WHITE

func setup_text(text: String, c: Color) -> void:
	label = Label.new()
	label.text = text
	label.add_theme_font_override("font", Art.font_title)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", c)
	label.add_theme_color_override("font_outline_color", Color("1b1a24"))
	label.add_theme_constant_override("outline_size", 2)
	label.size = Vector2(80, 10)
	label.position = Vector2(-40, -6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)

func setup_burst(c: Color, n: int) -> void:
	color = c
	for i in n:
		parts.append({"p": Vector2.ZERO, "v": Vector2(randf_range(-60, 60), randf_range(-120, -30))})

func _process(delta: float) -> void:
	t += delta
	if label:
		# pops up quickly, hangs for a moment, then fades (as in the trailer)
		label.position.y = -6 - 16.0 * (1.0 - exp(-t * 7.0))
		label.modulate.a = clampf((1.0 - t) / 0.35, 0, 1)
	for p in parts:
		p.v.y += 400 * delta
		p.p += p.v * delta
	queue_redraw()
	if t > 1.0:
		queue_free()

func _draw() -> void:
	for p in parts:
		draw_rect(Rect2(p.p.x - 1.5, p.p.y - 1.5, 3, 3), color)
