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
	_load_level("grass_1", true)
	hud.open_panel("title")
	if "--autotest" in OS.get_cmdline_user_args():
		var t: Node = load("res://tests/autotest.gd").new()
		t.main = self
		add_child(t)

func on_title() -> bool:
	return title_mode

func set_paused(on: bool) -> void:
	if level:
		level.process_mode = Node.PROCESS_MODE_DISABLED if on or title_mode else Node.PROCESS_MODE_INHERIT

func input_blocked() -> bool:
	return title_mode or hud.any_open()

func start_game(from_save: bool) -> void:
	if not (from_save and GS.load_game()):
		GS.new_game()
	title_mode = false
	hud.close_panels()
	change_level("town")
	if not from_save:
		hud.toast("Welcome to Pixel Village! Talk to the Portal Keeper to visit the Grasslands.", "big")

func quit_to_title() -> void:
	GS.save_game()
	title_mode = true
	hud.set_boss(null)
	_load_level("grass_1", true)
	hud.open_panel("title")

func change_level(id: String) -> void:
	GS.world = id
	_load_level(id, false)
	hud.set_boss(null)
	hud.toast(Data.WORLDS[id].name, "big")
	GS.save_game()

func reload_level() -> void:
	var pos: Vector2 = level.player.position
	_load_level(GS.world, false)
	level.player.position = pos
	camera.position = pos

func _load_level(id: String, demo: bool) -> void:
	if level:
		level.queue_free()
		remove_child(level)
	level = LevelScript.new()
	level.setup(id, self)
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
	change_level(target)

func drop_from_player(id: String, n: int) -> void:
	var p: Node2D = level.player
	var pk = level.PickupScript.new()
	pk.setup(id, n, level)
	pk.position = p.position + Vector2(p.facing * 20, -6)
	pk.life = -2.0
	level.entities.add_child(pk)

func player_died() -> void:
	var text := "You'll wake up in Pixel Village with everything still in your bag."
	if level.kind == "survival":
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
	if not hud.any_open():
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
	if event.is_action_pressed("bag"):
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
