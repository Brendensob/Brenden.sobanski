extends Node2D
## Another player in the room, as seen on your screen: their character, the
## item they're holding, their name in red, and a swing when they attack.
## Monsters on the host's screen can hit them; the hit is sent to their game.

var peer := 0
var dead := false
var facing := 1
var target := Vector2.ZERO
var st := {}
var body: Sprite2D
var held: Sprite2D
var name_label: Label
var swing := 0.0
var flip_t := 99.0
var jumps := 0
var swings := 0

const Player := preload("res://scripts/player.gd")

func setup(peer_id: int, pname: String) -> void:
	peer = peer_id
	body = Sprite2D.new()
	add_child(body)
	held = Sprite2D.new()
	add_child(held)
	name_label = Label.new()
	name_label.add_theme_font_override("font", Art.font_body)
	name_label.add_theme_font_size_override("font_size", 6)
	name_label.add_theme_color_override("font_color", Color("ff3a3a"))
	name_label.add_theme_color_override("font_outline_color", Color("1b1a24"))
	name_label.add_theme_constant_override("outline_size", 2)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size = Vector2(80, 10)
	name_label.position = Vector2(-40, -36)
	name_label.text = pname
	add_child(name_label)

func apply(state: Dictionary) -> void:
	var first := st.is_empty()
	st = state
	target = Vector2(state.get("x", 0.0), state.get("y", 0.0))
	if first:
		position = target
	facing = int(state.get("f", 1))
	dead = bool(state.get("dead", false))
	var sw := int(state.get("swings", 0))
	if sw != swings:
		if not first:
			swing = Player.SWING_TIME
		swings = sw
	# a new jump: do the same flip they did
	var j := int(state.get("jumps", 0))
	if j != jumps:
		if not first:
			flip_t = 0.0
		jumps = j
	var h: String = state.get("held", "")
	held.texture = Art.icon(h) if h != "" and Data.ITEMS.has(h) else null

func _process(delta: float) -> void:
	position = position.lerp(target, minf(1.0, delta * 14.0))
	swing -= delta
	var look: String = st.get("look", "man_in_suit")
	if not Art.LOOKS.has(look):
		look = "man_in_suit"
	body.texture = Art.character(look, st.get("frame", "stand"), 1, st.get("helmet", ""), st.get("armor", ""))
	body.position.y = -body.texture.get_height() / 2.0
	body.flip_h = facing < 0
	flip_t += delta
	var spin := 0.0
	if flip_t < Player.FLIP_TIME:
		spin = facing * TAU * ease(flip_t / Player.FLIP_TIME, 0.6)
	body.rotation = PI / 2 * facing if dead else spin
	held.position = Vector2(facing * 5, -7)
	held.offset = Vector2(4 * facing, -5)
	held.flip_h = facing < 0
	var ang: float = Player.SWING_KEYS[0][1]
	if swing > 0:
		ang = Player.swing_angle(1.0 - swing / Player.SWING_TIME)
	held.rotation = ang * facing
	held.visible = not dead

func hit_rect() -> Rect2:
	return Rect2(position.x - 5, position.y - 16, 10, 16)

## A monster (running on the host) touched this player: tell their game.
func hurt(dmg: int, crit: float, from_x: float, status := []) -> void:
	if dead:
		return
	Net.hurt_me.rpc_id(peer, dmg, crit, from_x, status)
