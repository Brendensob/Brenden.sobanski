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
var dark_layer: CanvasLayer
var dark_rect: ColorRect
var dead_tint: ColorRect
var dark := 0.0 # how dark the screen edges are right now (eases toward the target)

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
	# cave darkness sits over the world but under the HUD
	dark_layer = CanvasLayer.new()
	dark_layer.layer = 5
	add_child(dark_layer)
	dark_rect = ColorRect.new()
	dark_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/cave_dark.gdshader")
	dark_rect.material = mat
	dark_layer.add_child(dark_rect)
	# the screen is a little darker for you while you're fainted
	dead_tint = ColorRect.new()
	dead_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	dead_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dead_tint.color = Color(0.04, 0.02, 0.08, 0.38)
	dead_tint.visible = false
	dark_layer.add_child(dead_tint)
	Net.main = self
	Net.chat_received.connect(func(from: String, text: String): hud.add_chat(from, text))
	Net.emote_received.connect(func(peer: int, e: String):
		if level and level.puppets.has(peer) and is_instance_valid(level.puppets[peer]):
			level.show_emote(level.puppets[peer], e))
	_load_level("grass_1", true)
	hud.open_panel("title")
	if "--nettest" in OS.get_cmdline_user_args():
		var nt: Node = load("res://tests/net_test.gd").new()
		nt.main = self
		add_child(nt)
	if "--journeytest" in OS.get_cmdline_user_args():
		var jt: Node = load("res://tests/journey_test.gd").new()
		jt.main = self
		add_child(jt)
	if "--fighttest" in OS.get_cmdline_user_args():
		var ft: Node = load("res://tests/fight_test.gd").new()
		ft.main = self
		add_child(ft)
	if "--arenatest" in OS.get_cmdline_user_args():
		var at: Node = load("res://tests/arena_test.gd").new()
		at.main = self
		add_child(at)
	if "--gallery" in OS.get_cmdline_user_args():
		add_child(load("res://tests/gallery.gd").new())
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
	hud.goal_shown = ""
	hud.goal_index = -1
	hud.close_panels()
	change_level("town")
	hud.menu_step = "title"
	open_my_room()
	if not from_save:
		hud.toast("Welcome to Pixel Town! Talk to the Gatekeeper to visit the Grasslands.", "big")

func quit_to_title() -> void:
	GS.save_game()
	Net.rejoin_to = ""
	Net.stop_reopening()
	if Net.active:
		Net.leave()
	hud.menu_step = "slots"
	title_mode = true
	hud.set_boss(null)
	_load_level("grass_1", true)
	hud.open_panel("title")

func change_level(id: String) -> void:
	if Net.active:
		# in a room, a portal takes only you; the rest follow within 20 seconds
		Net.go(id)
		return
	enter_level(id)

## Loads a map for you alone. seed and solo come from a room's portal trip.
func enter_level(id: String, seed: int = -1, solo := false) -> void:
	GS.world = id
	GS.flags["been_" + id] = true
	_load_level(id, false, seed, {}, solo)
	hud.set_boss(null)
	hud.toast(Data.WORLDS[id].name, "big")
	GS.save_game()

## Someone in the room left the world you're in: you follow when the
## countdown ends (or go through the portal yourself).
func trip_started(target: String, from: String, who: String) -> void:
	if level and level.id == from:
		hud.toast("%s left for %s. Everyone here follows in %d seconds." % [who, Data.WORLDS[target].name, int(Net.TRIP_TIME)], "good")

## Someone went into a world from town: say so, and in town open the same
## portal on your street in case you want to go too.
func went(target: String, who: String) -> void:
	if who == GS.player_name:
		return
	hud.toast("%s went into the portal to %s." % [who, Data.WORLDS[target].name], "")
	if level and level.kind == "town" and target != "town":
		level.open_town_portal(target)

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
	GS.flags["been_" + world_id] = true
	if was_title:
		hud.close_panels()
	# already here on your own copy (you went through first): stay where you are
	var keep: Variant = level.player.position if level and level.id == world_id and level.player and not was_title else null
	_load_level(world_id, false, seed, state)
	if keep != null:
		level.player.position = keep
		camera.position = keep
		camera.reset_smoothing()
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

## The room's host left, and the game goes on (Brenden, 2026-11-11: "when
## someone leaves as the host it doesn't end the game and just passes it
## down"). The map you're on keeps going as it was, now run by your own game:
## you're the new host, or you're on your own for the moment it takes to get
## back into the new host's room. Puppets of the others go until they're back.
## A fainted player gets back up, since their gravestone was on the old host's map.
func take_over_level() -> void:
	if level == null or title_mode:
		return
	for pid in level.puppets.keys():
		level.remove_puppet(pid)
	var was_dead: bool = level.player.dead
	if was_dead:
		if is_instance_valid(grave):
			grave.queue_free()
		grave = null
		wake_tip = ""
		hud.hide_dead()
		GS.hp = GS.max_hp()
	if level.kind == "town":
		if was_dead:
			level.player.revive_here()
		return
	var pos: Vector2 = level.player.position
	var facing: int = level.player.facing
	var st: Dictionary = level.net_state()
	_load_level(level.id, false, level.seed_used, st, false, true)
	level.player.position = pos
	level.player.facing = facing
	camera.position = pos
	camera.reset_smoothing()
	GS.stats_changed.emit()

func reload_level() -> void:
	var pos: Vector2 = level.player.position
	_load_level(GS.world, false)
	level.player.position = pos
	camera.position = pos

func _load_level(id: String, demo: bool, seed: int = -1, state: Dictionary = {}, solo := false, takeover := false) -> void:
	if level:
		level.queue_free()
		remove_child(level)
	level = LevelScript.new()
	level.setup(id, self, seed, state, solo, takeover)
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

## The Gatekeeper's list: in town she opens a portal on the street, like the
## original; anywhere else it takes you straight there.
func open_world(target: String) -> void:
	if level and level.kind == "town":
		level.open_town_portal(target)
		hud.toast("A portal to %s opened on the street below." % Data.WORLDS[target].name, "good")
		Sfx.play("portal", 0.0)
	else:
		change_level(target)

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

const GraveScript := preload("res://scripts/grave.gd")
const PlayerScript := preload("res://scripts/player.gd")
## Your gravestone after fainting in single player, while it stands.
var grave: Node = null
var wake_tip := ""

func player_died(on_purpose := false) -> void:
	var lvl: Node = level
	var pl: Node = level.player
	var solo := not Net.active and not on_purpose
	# the Grasslands Arena gives one free revive in single player: you get
	# straight back up where you fell (Brenden, 2026-11-05)
	if solo and lvl.def.get("free_revive", false) and not lvl.free_revive_used:
		lvl.free_revive_used = true
		await get_tree().create_timer(PlayerScript.DEATH_ANIM + 0.2).timeout
		if level != lvl or not is_instance_valid(pl) or not pl.dead:
			return
		pl.revive_here()
		hud.toast("Free revive! The Grasslands Arena gives you one.", "good")
		return
	# everywhere else (not Survival, which ends when you faint, not the bomb,
	# and not the free-revive arena once it's used) your gravestone rises. In a
	# room, friends revive you by standing by it (Brenden, 2026-11-07)
	var can_grave: bool = not on_purpose and lvl.kind in ["explore", "arena"] and not (solo and lvl.def.get("free_revive", false))
	var text := "Nothing is lost."
	if can_grave and not solo:
		text = "A friend can revive you right away by touching your gravestone."
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
			elif GS.stash(key, 1) == 0:
				text += " You earned a %s! Your bag was full, so Banka is keeping it for you." % Data.ITEMS[key].name
			else:
				text += " Your bag and storage were full, so the %s was lost." % Data.ITEMS[key].name
	var tip := faint_tip()
	if can_grave or solo:
		await get_tree().create_timer(PlayerScript.DEATH_ANIM).timeout
		if level != lvl or not is_instance_valid(pl) or not pl.dead:
			return
		if can_grave:
			if is_instance_valid(grave):
				grave.queue_free()
			grave = GraveScript.new()
			grave.setup(lvl)
			grave.position = Vector2(pl.position.x, pl.position.y)
			if solo:
				grave.left = hud.DEAD_WAIT # nobody can revive you on your own
			lvl.entities.add_child(grave)
		await get_tree().create_timer(0.4).timeout
	else:
		await get_tree().create_timer(1.0).timeout
	# already back up (woken early or moved to another map): no faint screen
	if level == null or level != lvl or not is_instance_valid(level.player) or not level.player.dead:
		return
	hud.show_dead(text, can_grave and is_instance_valid(grave))
	# the tip shows once you're back in Pixel Town, not behind the bar
	wake_tip = tip

## One tip for after fainting: the first thing that would help most.
func faint_tip() -> String:
	if GS.equip.armor == "":
		return "Make Wooden Armor at the Crafter (50 Wood) and tap it in your bag to wear it."
	if GS.equip.helmet == "" or GS.equip.shield == "":
		return "A helmet and a shield add defense. The Crafter makes wooden ones."
	var heals := 0
	for s in GS.inv:
		if s and Data.ITEMS[s.id].get("heal", 0) > 0:
			heals += s.n
	if heals == 0:
		return "Carry potions. The Plumber sells Small Potions. Pick one on the hotbar and press A to drink it."
	if level and Data.WORLDS.has(level.id) and GS.world_danger(level.id) >= 2:
		return "This place is %s for your gear. Upgrade your sword and armor at the Crafter first." % ["Easy", "Fair", "Hard", "Deadly"][GS.world_danger(level.id)]
	return "Hit monsters as they come: each hit pushes them back and stuns them for a moment."

func respawn() -> void:
	grave = null
	GS.hp = GS.max_hp()
	GS.st = GS.max_st()
	GS.status.clear()
	hud.close_panels()
	hud.hide_dead()
	if Net.active:
		if level.kind == "town":
			level.player.revive()
			GS.stats_changed.emit()
			return
		# back to your own Pixel Town: only you, the room isn't pulled along
		Net.go("town", true)
	else:
		change_level("town")
	if wake_tip != "":
		hud.toast("Tip: " + wake_tip, "")
		wake_tip = ""

## A friend stood by your gravestone long enough: back up where you fell.
func revived_by(who: String) -> void:
	if level == null or not is_instance_valid(level.player) or not level.player.dead:
		return
	if is_instance_valid(grave):
		grave.queue_free()
	grave = null
	level.player.revive_here()
	hud.hide_dead()
	hud.toast("%s revived you!" % who, "good")
	Sfx.play("heal", 0.0)

func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount)

var deep := false # underground in an explore world (the cave music plays)

func _music() -> void:
	var kind: String = level.kind
	if kind == "explore" and is_instance_valid(level.player):
		var c := int(level.player.position.x / 16.0)
		var down: int = int(level.player.position.y / 16.0) - level.surface[clampi(c, 0, level.surface.size() - 1)]
		deep = down > 6 if deep else down > 10 # a little slack so it doesn't flip at the edge
	else:
		deep = false
	Music.want(Music.pick(title_mode, kind, String(level.def.get("theme", "")), hud.boss != null and is_instance_valid(hud.boss),
		kind == "survival" and GS.is_night(), deep))

## How dark the edges should be: the dark worlds always, any explore world
## once you're well underground, and never in town, menus or the open fields.
func dark_target() -> float:
	if title_mode or level == null or not is_instance_valid(level.player):
		return 0.0
	var theme := String(level.def.get("theme", ""))
	var base := 0.0
	if theme in ["dark", "ghost", "tomb", "nightmare", "modina"]:
		base = 0.78
	elif theme == "hell":
		base = 0.6
	if level.kind == "explore":
		var c := clampi(int(level.player.position.x / 16.0), 0, level.surface.size() - 1)
		var down: float = level.player.position.y / 16.0 - level.surface[c]
		base = maxf(base, clampf((down - 3.0) / 10.0, 0.0, 0.9))
	return base

func _darkness(delta: float) -> void:
	dark = move_toward(dark, dark_target(), delta * 0.8)
	dark_rect.visible = dark > 0.01
	if not dark_rect.visible:
		return
	var vs := get_viewport().get_visible_rect().size
	var mat: ShaderMaterial = dark_rect.material
	var at: Vector2 = level.player.get_global_transform_with_canvas().origin + Vector2(0, -12)
	mat.set_shader_parameter("center", at / vs)
	mat.set_shader_parameter("aspect", vs.x / vs.y)
	mat.set_shader_parameter("strength", dark)

var _timer_check := 0.0
var announced := {} # timers already reported as done

## Tells you when a smelt, an egg or a crop finishes, wherever you are.
func _timers(delta: float) -> void:
	_timer_check += delta
	if _timer_check < 1.0 or title_mode:
		return
	_timer_check = 0.0
	var t := GS.now()
	var done := []
	for i in GS.furnaces.size():
		var j = GS.furnaces[i]
		if j and t >= float(j.done):
			done.append(["f%d_%d" % [i, int(j.done)], "Your %s is ready in the furnace." % Data.ITEMS[j.out].name])
	if not GS.incubator.is_empty() and t >= float(GS.incubator.done):
		done.append(["egg_%d" % int(GS.incubator.done), "Your %s has hatched in the incubator!" % Data.ITEMS[GS.incubator.egg].name])
	for i in GS.soils.size():
		var s = GS.soils[i]
		if s and t >= float(s.done):
			done.append(["soil%d_%d" % [i, int(s.done)], "Your %s is ripe in the soil." % Data.ITEMS[s.seed].name])
	for d in done:
		if not announced.has(d[0]):
			announced[d[0]] = true
			hud.toast(d[1], "good")
			Sfx.play("coin", 0.0, -6.0)

func _process(delta: float) -> void:
	if level == null:
		return
	_music()
	_timers(delta)
	_darkness(delta)
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
	# the phone browser can throw a hidden page away, so save when it's hidden too
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if not title_mode:
			GS.save_game()
