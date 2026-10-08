extends Node
## Runs the game: loads maps, moves you between them, ticks the clock,
## handles fainting, saving and the title screen.

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
	add_child(camera)
	_load_level("grass_1", "left", true)
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
	change_level(GS.level_id, "left")
	if not from_save:
		hud.toast("Welcome to Pixel Village! Talk to Pip, then head through the portal on the right.", "big")

func quit_to_title() -> void:
	GS.save_game()
	title_mode = true
	hud.set_boss(null)
	_load_level("grass_1", "left", true)
	hud.open_panel("title")

func change_level(id: String, entry: String) -> void:
	GS.level_id = id
	GS.unlocked[id] = true
	_load_level(id, entry, false)
	hud.set_boss(null)
	hud.toast(Data.level_name(id), "big")
	GS.save_game()

func reload_level() -> void:
	var px: float = level.player.position.x
	_load_level(GS.level_id, "left", false)
	level.player.position = Vector2(px, level.surface_y(px))
	camera.position = level.player.position

func _load_level(id: String, entry: String, demo: bool) -> void:
	if level:
		level.queue_free()
		remove_child(level)
	level = LevelScript.new()
	level.setup(id, self, entry)
	add_child(level)
	move_child(level, 0)
	camera.limit_left = 0
	camera.limit_right = int(level.world_width())
	camera.limit_bottom = -28
	camera.zoom = Vector2(2, 2)
	camera.limit_top = -1000
	camera.position = level.player.position + Vector2(0, -24)
	camera.reset_smoothing()
	hud.set_hud_visible(not demo)
	if demo:
		level.player.visible = false
		level.player.set_physics_process(false)
	set_paused(false)

func use_portal(target: String) -> void:
	if target == "map":
		hud.open_panel("map")
		return
	if target == "town":
		change_level("town", "portal_town")
		return
	if target == "":
		return
	if target.ends_with("_lair"):
		var zone: Dictionary = Data.ZONES[target.split("_")[0]]
		var key: String = zone.key
		if GS.count(key) <= 0:
			hud.toast("The lair is sealed. You need a %s (Crystal + %s)." % [Data.ITEMS[key].name, _key_part(key)], "warn")
			GS.unlocked[target] = true
			return
		GS.remove_item(key, 1)
		change_level(target, "left")
		return
	var going_back: bool = level.id != "town" and _level_index(target) < _level_index(level.id)
	change_level(target, "right" if going_back else "left")

func _key_part(key: String) -> String:
	for r in Data.RECIPES:
		if r.out == key:
			return Data.ITEMS[r.b].name
	return "?"

func _level_index(id: String) -> int:
	if id == "town":
		return -1
	var p := id.split("_")
	var z := Data.ZONE_ORDER.find(p[0])
	var n := 9 if p[1] == "lair" else int(p[1])
	return z * 10 + n

func near_furnace() -> bool:
	return level != null and level.player != null and level.near_furnace(level.player.position)

func drop_from_player(id: String, n: int) -> void:
	var p: Node2D = level.player
	var pk = level.PickupScript.new()
	pk.setup(id, n, level)
	pk.position = p.position + Vector2(p.facing * 20, -6)
	pk.life = -2.0
	level.entities.add_child(pk)

func player_died() -> void:
	await get_tree().create_timer(1.0).timeout
	hud.show_dead()

func respawn() -> void:
	GS.hp = GS.max_hp()
	GS.stamina = GS.max_stamina()
	hud.close_panels()
	change_level("town", "left")

func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)

func _process(delta: float) -> void:
	if level == null:
		return
	if title_mode:
		title_t += delta
		var w: float = level.world_width()
		camera.position = Vector2(120 + (sin(title_t * 0.1) * 0.5 + 0.5) * (w - 240), -100)
		return
	if not get_tree().paused and not hud.any_open():
		GS.clock += delta / GS.DAY_LENGTH
		if GS.clock >= 1.0:
			GS.clock -= 1.0
			GS.day += 1
			hud.toast("Day %d" % GS.day, "big")
		autosave += delta
		if autosave > 30:
			autosave = 0
			GS.save_game()
	var p: Node2D = level.player
	camera.position = p.position + Vector2(0, -24)
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
