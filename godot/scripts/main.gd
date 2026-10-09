extends Node
## Runs the game: loads maps, moves you between them, ticks the clock,
## handles fainting (and Survival Grasslands key rewards), saving and the title screen.

const LevelScript := preload("res://scripts/level.gd")
const HudScript := preload("res://scripts/hud.gd")

var level: Node2D
var hud: CanvasLayer
var camera: Camera2D
var shake_amt := 0.0
var autosave := 0.0
var title_mode := true
var title_t := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud = HudScript.new()
	hud.main = self
	add_child(hud)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.zoom = Vector2(2, 2)
	add_child(camera)
	Net.main = self
	Net.chat_received.connect(func(from: String, text: String): hud.add_chat(from, text))
	_load_level("grass_1", true)
	hud.open_panel("title")
	if "--nettest" in OS.get_cmdline_user_args():
		var nt: Node = load("res://tests/net_test.gd").new()
		nt.main = self
		add_child(nt)
	if "--autotest" in OS.get_cmdline_user_args():
		var t: Node = load("res://tests/autotest.gd").new()
		t.main = self
		add_child(t)

func on_title() -> bool:
	return title_mode

func set_paused(on: bool) -> void:
	if Net.active and not title_mode:
		on = false # the world keeps going for everyone else in the room
	if level:
		level.process_mode = Node.PROCESS_MODE_DISABLED if on or title_mode else Node.PROCESS_MODE_INHERIT

func input_blocked() -> bool:
	return title_mode or hud.any_open() or hud.chat_focused()

## Starts the character in GS.slot: loads it, or creates it with a look and name.
func start_game(from_save: bool, character: String = "man_in_suit", pname: String = "") -> void:
	if not (from_save and GS.load_game()):
		GS.new_game(character, pname)
	title_mode = false
	hud.close_panels()
	change_level("town")
	hud.menu_step = "title"
	open_my_room()
	if not from_save:
		hud.toast("Welcome to Pixel Town! Talk to the Gatekeeper to visit the Grasslands.", "big")

func quit_to_title() -> void:
	GS.save_game()
	if Net.active:
		Net.leave()
	hud.menu_step = "slots"
	title_mode = true
	hud.set_boss(null)
	_load_level("grass_1", true)
	hud.open_panel("title")

func change_level(id: String) -> void:
	if Net.is_client():
		# guests ask the room host; the whole room moves together
		Net.request_level.rpc_id(1, id)
		return
	GS.world = id
	_load_level(id, false)
	hud.set_boss(null)
	hud.toast(Data.WORLDS[id].name, "big")
	GS.save_game()
	if Net.is_host():
		Net.send_world()

# ---------------------------------------------------------------- rooms
## Opens your room on the online server's relay: every player is the host of
## their own world, and friends can join it from their friends list.
func open_my_room() -> void:
	if GS.online_token == "":
		return
	var err := Net.host_room()
	if err != "":
		hud.toast(err, "warn")
	else:
		Online.ping_now()

## Joins a friend's room by name, with the character in GS.slot.
func join_game(friend: String) -> void:
	if not GS.load_game():
		net_join_failed("Pick a character first.")
		return
	var err := Net.join_room(friend)
	if err != "":
		net_join_failed(err)

## The room host sent the map everyone's on.
func net_load_world(world_id: String, seed: int, state: Dictionary) -> void:
	var was_title := title_mode
	title_mode = false
	GS.world = world_id
	if was_title:
		hud.close_panels()
	_load_level(world_id, false, seed, state)
	hud.set_boss(null)
	hud.toast(Data.WORLDS[world_id].name, "big")
	GS.save_game()

func net_join_failed(msg: String) -> void:
	Net.leave()
	title_mode = true
	hud.menu_step = "mode"
	hud.open_panel("title")
	hud.toast(msg, "danger")

func net_host_left() -> void:
	GS.save_game()
	title_mode = true
	hud.set_boss(null)
	_load_level("grass_1", true)
	hud.menu_step = "slots"
	hud.open_panel("title")
	hud.toast("The room was closed.", "warn")

func reload_level() -> void:
	var pos: Vector2 = level.player.position
	_load_level(GS.world, false)
	level.player.position = pos
	camera.position = pos

func _load_level(id: String, demo: bool, seed: int = -1, state: Dictionary = {}) -> void:
	if level:
		level.queue_free()
		remove_child(level)
	level = LevelScript.new()
	level.setup(id, self, seed, state)
	add_child(level)
	move_child(level, 0)
	var size: Vector2 = level.world_size()
	camera.limit_left = 0
	camera.limit_right = int(size.x)
	camera.limit_top = -400
	camera.limit_bottom = int(size.y) - 8
	camera.position = level.player.position + Vector2(0, -20)
	camera.reset_smoothing()
	hud.set_hud_visible(not demo)
	if demo:
		level.player.visible = false
		level.player.set_physics_process(false)
	set_paused(false)

func use_portal(target: String) -> void:
	if target == "":
		return
	Sfx.play("portal", 0.0)
	change_level(target)

func drop_from_player(id: String, n: int) -> void:
	var p: Node2D = level.player
	var pk = level.PickupScript.new()
	pk.setup(id, n, level)
	pk.position = p.position + Vector2(p.facing * 20, -6)
	pk.life = -2.0
	level.entities.add_child(pk)

func player_died() -> void:
	var text := "You'll wake up in Pixel Town with everything still in your bag."
	if level.kind == "survival" and not Net.active: # keys are single player only, like the original
		var d: int = level.s_day
		var key := ""
		if d >= 45:
			key = "master_key"
		elif d >= 19:
			key = "golden_key"
		elif d >= 7:
			key = "silver_key"
		text = "You lasted until day %d of Survival Grasslands." % d
		if key != "":
			if GS.add_item(key, 1, true) == 0:
				text += " You earned a %s!" % Data.ITEMS[key].name
			else:
				text += " Your bag was full, so the %s was lost." % Data.ITEMS[key].name
	await get_tree().create_timer(1.0).timeout
	hud.show_dead(text)

func respawn() -> void:
	GS.hp = GS.max_hp()
	GS.st = GS.max_st()
	GS.status.clear()
	hud.close_panels()
	if Net.active:
		level.player.revive()
		GS.stats_changed.emit()
		return
	change_level("town")

func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)

func _process(delta: float) -> void:
	if level == null:
		return
	if title_mode:
		title_t += delta
		var w: float = level.world_size().x
		camera.position = Vector2(140 + (sin(title_t * 0.08) * 0.5 + 0.5) * (w - 280), level.surface[10] * 16 - 40)
		return
	if Net.active or not hud.any_open():
		GS.clock += delta / Data.DAY_LENGTH
		if GS.clock >= 1.0:
			GS.clock -= 1.0
			GS.day += 1
		autosave += delta
		if autosave > 30:
			autosave = 0
			GS.save_game()
	var p: Node2D = level.player
	camera.position = p.position + Vector2(0, -20)
	shake_amt = maxf(0, shake_amt - delta * 20)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt

func _unhandled_input(event: InputEvent) -> void:
	if title_mode:
		return
	if Net.active and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T and not hud.any_open():
		hud.open_chat()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("bag"):
		hud.toggle_bag()
	elif event.is_action_pressed("pause"):
		if hud.any_open():
			if not hud.panels.dead.visible:
				hud.close_panels()
		else:
			hud.open_panel("pause")
	else:
		for i in GS.HOTBAR:
			if event.is_action_pressed("slot_%d" % (i + 1)):
				GS.sel = i
				GS.inventory_changed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if not title_mode:
			GS.save_game()
