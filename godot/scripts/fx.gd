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
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", c)
	label.add_theme_color_override("font_outline_color", Color("1b1a24"))
	label.add_theme_constant_override("outline_size", 4)
	label.size = Vector2(120, 14)
	label.position = Vector2(-60, -8)
	label.pivot_offset = Vector2(60, 7)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# numbers in quick succession stack up instead of covering each other
	position.x += randf_range(-5, 5)
	add_child(label)

func setup_burst(c: Color, n: int) -> void:
	color = c
	for i in n:
		parts.append({"p": Vector2.ZERO, "v": Vector2(randf_range(-60, 60), randf_range(-120, -30))})

func _process(delta: float) -> void:
	t += delta
	if label:
		# pops up quickly, hangs for a moment, then fades (as in the trailer)
		label.position.y = -8 - 18.0 * (1.0 - exp(-t * 7.0))
		label.modulate.a = clampf((1.0 - t) / 0.35, 0, 1)
		# cartoon pop: starts big and squashes back to size
		label.scale = Vector2.ONE * (1.0 + 0.7 * exp(-t * 14.0))
	for p in parts:
		p.v.y += 400 * delta
		p.p += p.v * delta
	queue_redraw()
	if t > 1.0:
		queue_free()

func _draw() -> void:
	# cartoon poof: round puffs with a dark rim that shrink away
	var r := 3.0 * (1.0 - t) + 0.5
	for p in parts:
		draw_circle(p.p, r + 1.0, Color("1b1a24"))
	for p in parts:
		draw_circle(p.p, r, color)
		draw_circle(p.p + Vector2(-r * 0.35, -r * 0.35), r * 0.35, color.lightened(0.35))
