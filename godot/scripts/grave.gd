extends Node2D
## Your gravestone, single player only. It rises where you fainted. Pick
## "Respawn" and you come back as a ghost at the start of the map: stand by
## the stone for 3.5 seconds (a little timer counts down over it) and you get
## back up right there. After 50 seconds it crumbles and you wake up in Pixel
## Town as usual (Brenden, 2026-11-05).

const WINDOW := 50.0 # seconds the gravestone lasts
const HOLD := 3.5 # seconds to stand by it
const NEAR := 26.0 # how close counts as "by it", in pixels

var level: Node
var left := WINDOW
var held := 0.0
var label: Label
var bar_back: ColorRect
var bar: ColorRect

func setup(lvl: Node) -> void:
	level = lvl

func _ready() -> void:
	Art.add_shadow(self, 10)
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(_stone())
	s.centered = false
	s.position = Vector2(-7, -18)
	add_child(s)
	label = Label.new()
	Art.world_text(label)
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_outline_color", Color("1b1a24"))
	label.add_theme_constant_override("outline_size", Art.outline_for(7))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(40, 10)
	label.position = Vector2(-20, -47) # above the name of a ghost standing by it
	add_child(label)
	bar_back = ColorRect.new()
	bar_back.color = Color("1b1a24")
	bar_back.size = Vector2(22, 4)
	bar_back.position = Vector2(-11, -52)
	add_child(bar_back)
	bar = ColorRect.new()
	bar.color = Color("5cbf3f")
	bar.size = Vector2(0, 2)
	bar.position = Vector2(-10, -51)
	add_child(bar)
	# it pops up out of the ground
	scale = Vector2(1, 0.1)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if level:
		level.burst(position + Vector2(0, -2), Color("8a7a62"), 10)
	_show()

## A small rounded headstone with a cross, drawn in code like everything else.
static func _stone() -> Image:
	var w := 14
	var h := 18
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var edge := Color("3e424a")
	var face := Color("9aa0ac")
	var lit := Color("c8ccd8")
	var dark := Color("6e7482")
	for y in h:
		for x in w:
			# a rectangle with a round top
			var inside := false
			if y >= 6:
				inside = x >= 1 and x <= w - 2
			else:
				var dx := x - (w - 1) / 2.0
				var dy := y - 6.0
				inside = dx * dx + dy * dy <= 36.5
			if not inside:
				continue
			var c := face
			if x <= 2:
				c = lit
			elif x >= w - 4:
				c = dark
			img.set_pixel(x, y, c)
	# outline
	var out := img.duplicate()
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a == 0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or img.get_pixel(q.x, q.y).a == 0:
					out.set_pixel(x, y, edge)
	# the cross
	for y in range(4, 12):
		out.set_pixel(6, y, edge)
		out.set_pixel(7, y, edge)
	for x in range(4, 10):
		out.set_pixel(x, 6, edge)
	# grass at its foot
	for x in [1, 3, 10, 12]:
		out.set_pixel(x, h - 1, Color("4f9a44"))
		out.set_pixel(x, h - 2, Color("6ab04c"))
	return out

func _process(delta: float) -> void:
	if level == null or not is_instance_valid(level.player):
		return
	var p: Node2D = level.player
	left -= delta
	if p.ghost and p.position.distance_to(position) < NEAR:
		held += delta
	else:
		held = 0.0
	if held >= HOLD:
		p.position = position + Vector2(0, -1)
		p.revive_here()
		Sfx.play("heal", 0.0)
		level.main.hud.toast("You got back up!", "good")
		_gone()
		return
	if left <= 0:
		level.burst(position + Vector2(0, -8), Color("9aa0ac"), 14)
		_gone()
		if p.dead:
			level.main.hud.toast("Your gravestone crumbled. You wake up in Pixel Town.", "warn")
			level.main.respawn()
		return
	_show()

func _show() -> void:
	if held > 0:
		label.text = "%.1f" % maxf(0.0, HOLD - held)
		label.add_theme_color_override("font_color", Color("8fe05a"))
		bar.size.x = 20.0 * clampf(held / HOLD, 0, 1)
		bar_back.visible = true
		bar.visible = true
	else:
		label.text = str(int(ceil(left)))
		label.add_theme_color_override("font_color", Color("ff6a5a") if left < 10 else Color.WHITE)
		bar_back.visible = false
		bar.visible = false

func _gone() -> void:
	if level and level.main.get("grave") == self:
		level.main.grave = null
	queue_free()
