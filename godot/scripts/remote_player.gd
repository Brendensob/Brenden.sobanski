extends Node2D
## Another player in the room, as seen on your screen: their character, the
## item they're holding, their name in red, and a swing when they attack.
## Monsters on the host's screen can hit them; the hit is sent to their game.
## When they faint, a gravestone stands in their place: touch it and they get
## back up right away (Brenden, 2026-11-11: "When someone dies make sure it's
## able to rez them right away"; it was 3.5 seconds of standing by it).

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
const Grave := preload("res://scripts/grave.gd")
var stone: Sprite2D
var revive_sent := 0.0 # seconds since you asked to revive them (they're back up any moment)
var revives := 0 # how many times you've revived them (tests read it)

func setup(peer_id: int, pname: String) -> void:
	peer = peer_id
	Art.add_shadow(self, 9)
	body = Sprite2D.new()
	add_child(body)
	held = Sprite2D.new()
	add_child(held)
	name_label = Label.new()
	Art.world_text(name_label)
	name_label.add_theme_font_size_override("font_size", 6)
	name_label.add_theme_color_override("font_color", Color("ff3a3a"))
	name_label.add_theme_color_override("font_outline_color", Color("1b1a24"))
	name_label.add_theme_constant_override("outline_size", Art.outline_for(6))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size = Vector2(80, 10)
	name_label.position = Vector2(-40, -36)
	name_label.text = pname
	add_child(name_label)
	stone = Sprite2D.new()
	stone.texture = ImageTexture.create_from_image(Grave._stone())
	stone.centered = false
	stone.position = Vector2(-7, -18)
	stone.visible = false
	add_child(stone)

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
	held.texture = Art.held_tex(h) if h != "" and Data.ITEMS.has(h) else null
	held.scale = Art.held_scale(h)
	held.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _process(delta: float) -> void:
	position = position.lerp(target, minf(1.0, delta * 14.0))
	swing -= delta
	var look: String = st.get("look", "man_in_suit")
	if not Art.LOOKS.has(look):
		look = "man_in_suit"
	var frame: String = st.get("frame", "stand")
	body.texture = Art.character(look, frame, 1, st.get("helmet", ""), st.get("armor", ""), held.texture != null and not dead)
	body.position.y = -body.texture.get_height() / 2.0
	body.flip_h = facing < 0
	flip_t += delta
	var spin := 0.0
	if flip_t < Player.FLIP_TIME:
		spin = facing * TAU * ease(flip_t / Player.FLIP_TIME, 0.6)
	body.rotation = spin
	body.visible = not dead
	stone.visible = dead
	_revive_tick(delta)
	held.position = Vector2(facing * 5, -7 + Art.frame_sink(frame))
	held.offset = Art.held_offset(held.texture, facing)
	held.flip_h = facing < 0
	var ang: float = Player.SWING_KEYS[0][1]
	if swing > 0:
		ang = Player.swing_angle(1.0 - swing / Player.SWING_TIME)
	held.rotation = ang * facing
	held.visible = not dead

## Touching a fainted friend's gravestone (alive, on the same map) gets them
## back up right away. If they're somehow still down a moment later, it asks again.
func _revive_tick(delta: float) -> void:
	if not dead:
		revive_sent = 0.0
		return
	if revive_sent > 0.0:
		revive_sent += delta
		if revive_sent < 1.5:
			return
		revive_sent = 0.0
	var lvl: Node = get_parent().get_parent() if get_parent() else null
	var me: Node2D = lvl.player if lvl and lvl.get("player") else null
	if me != null and not me.dead and me.position.distance_to(position) < Grave.NEAR:
		revive_sent = 0.001
		revives += 1
		Net.revive_friend(peer)
		if lvl:
			lvl.burst(position + Vector2(0, -10), Color("f2cf5b"), 10)

func hit_rect() -> Rect2:
	return Rect2(position.x - 5, position.y - 16, 10, 16)

## A monster (running on the host) touched this player: tell their game.
func hurt(dmg: int, crit: float, from_x: float, status := []) -> void:
	if dead:
		return
	Net.hurt_me.rpc_id(peer, dmg, crit, from_x, status)
