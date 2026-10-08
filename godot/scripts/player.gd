extends CharacterBody2D
## The player. ◀ ▶ move, B jumps, A uses whatever you hold: swing a weapon or
## tool, cast with a staff, shoot a bow, eat, place a building, read a book,
## or talk to whoever you're standing next to. Hold A to keep attacking.

const ProjectileScript := preload("res://scripts/projectile.gd")

const SPEED := 82.0
const JUMP := -240.0
const GRAVITY := 720.0
const STAMINA_COST := 0.5

var level: Node
var facing := 1
var anim := 0.0
var cooldown := 0.0
var swing := 0.0
var swing_len := 0.3
var swing_hit := true
var invuln := 0.0
var flash := 0.0
var since_hurt := 99.0
var regen := {"hp": 0.0, "mp": 0.0, "st": 0.0, "poison": 0.0}
var msg_cd := 0.0
var dead := false
var body_sprite: Sprite2D
var held_sprite: Sprite2D
var light: PointLight2D
var name_label: Label
## Like the original: hold A and open the bag, and you keep attacking on your own
## until you press A again or faint.
var auto_attack := false
var cur_frame := "stand"

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 15)
	shape.shape = rect
	shape.position = Vector2(0, -7.5)
	add_child(shape)
	held_sprite = Sprite2D.new()
	add_child(held_sprite)
	body_sprite = Sprite2D.new()
	body_sprite.position = Vector2(0, -9)
	add_child(body_sprite)
	light = PointLight2D.new()
	light.texture = Art.light_tex()
	light.texture_scale = 1.2
	light.energy = 0.0
	light.position = Vector2(0, -10)
	add_child(light)
	name_label = Label.new()
	name_label.add_theme_font_override("font", Art.font_body)
	name_label.add_theme_font_size_override("font_size", 6)
	name_label.add_theme_color_override("font_color", Color("ff3a3a"))
	name_label.add_theme_color_override("font_outline_color", Color("1b1a24"))
	name_label.add_theme_constant_override("outline_size", 2)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size = Vector2(80, 10)
	name_label.position = Vector2(-40, -36)
	name_label.text = GS.player_name
	add_child(name_label)
	GS.inventory_changed.connect(_update_held)
	_update_held()

func _update_held() -> void:
	var id := GS.held()
	held_sprite.texture = Art.icon(id) if id != "" else null

func held_type() -> String:
	var id := GS.held()
	return Data.ITEMS[id].type if id != "" else ""

func _physics_process(delta: float) -> void:
	if dead:
		return
	var dir := 0.0
	if not level.main.input_blocked():
		dir = Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP
		if Input.is_action_just_pressed("attack"):
			auto_attack = false
			use_held(true)
		elif (Input.is_action_pressed("attack") or auto_attack) and cooldown <= 0 and held_type() in ["weapon", "axe", "pick", "staff", "bow", "throw", ""]:
			use_held(false)
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 420)
	var speed := SPEED
	if GS.has_status("slow"):
		speed *= 0.55
	elif GS.has_status("cold"):
		speed *= 0.75
	velocity.x = move_toward(velocity.x, dir * speed, 900 * delta)
	if dir != 0:
		facing = 1 if dir > 0 else -1
	move_and_slide()
	if position.y > level.H * 16 + 40:
		position = level.cell_pos(level.spawn_cell)
		velocity = Vector2.ZERO
	_tick(delta, dir)

func _tick(delta: float, dir: float) -> void:
	anim += delta
	invuln -= delta
	flash -= delta
	since_hurt += delta
	msg_cd -= delta
	cooldown -= delta
	# statuses wear off
	for k in GS.status.keys():
		GS.status[k] -= delta
		if GS.status[k] <= 0:
			GS.status.erase(k)
			GS.stats_changed.emit()
	# poison: 1 damage + 1 more per 15 max health, every 2 seconds
	if GS.has_status("poison"):
		regen.poison += delta
		if regen.poison >= 2.0:
			regen.poison = 0
			var p := 1 + int(GS.max_hp() / 15.0)
			GS.hp -= p
			level.number(position + Vector2(0, -24), "-%d" % p, Color("8fd04a"))
			GS.stats_changed.emit()
			if GS.hp <= 0:
				_die()
				return
	# natural recovery
	var st_rate := 1.0 if not GS.has_status("cold") else 0.5
	if not GS.has_status("fatigue"):
		_regen("st", delta * st_rate, 1.0)
	_regen("mp", delta, 5.0)
	if since_hurt > 8.0:
		_regen("hp", delta, 12.0)
	# campfires heal
	if level.structures_near(position, 40, "campfire"):
		_regen("hp", delta, 2.0)
	# swing animation and hit
	if swing > 0:
		swing -= delta
		if not swing_hit and swing <= swing_len * 0.6:
			swing_hit = true
			_do_hit()
	var frame := "stand"
	if not is_on_floor():
		frame = "jump"
	elif dir != 0 and int(anim * 8) % 2 == 1:
		frame = "walk"
	cur_frame = frame
	body_sprite.texture = Art.character_flash(GS.look) if flash > 0 else Art.character(GS.look, frame, 1, GS.equip.get("helmet", ""), GS.equip.get("armor", ""))
	body_sprite.position.y = -body_sprite.texture.get_height() / 2.0
	body_sprite.flip_h = facing < 0
	body_sprite.visible = not (invuln > 0 and flash <= 0 and int(anim * 20) % 2 == 0)
	held_sprite.position = Vector2(facing * 5, -7)
	held_sprite.flip_h = facing < 0
	held_sprite.offset = Vector2(4 * facing, -5)
	var ang := -0.5
	if swing > 0:
		var k := 1.0 - swing / swing_len
		ang = lerpf(-2.0, 1.4, minf(k * 2.0, 1.0))
	held_sprite.rotation = ang * facing
	var glow := 1.0 if GS.held() == "torch_weapon" else 0.35
	var gloom := 1.0 if level.modulate_node.color.r < 0.9 else 0.0
	light.energy = maxf(GS.darkness(), gloom) * glow

func _regen(stat: String, delta: float, every: float) -> void:
	var cur: float = GS.get(stat)
	var mx: float = GS.call("max_" + stat)
	if cur >= mx:
		regen[stat] = 0.0
		return
	regen[stat] += delta
	if regen[stat] >= every:
		regen[stat] = 0.0
		GS.set(stat, minf(mx, cur + 1))
		GS.stats_changed.emit()

func _say(text: String) -> void:
	if msg_cd <= 0:
		level.main.hud.toast(text, "warn")
		msg_cd = 1.5

# ---------------------------------------------------------------- actions
func use_held(pressed: bool) -> void:
	if cooldown > 0:
		return
	if pressed:
		var near: Node = level.interactable_near(position, facing)
		if near:
			near.interact(self)
			cooldown = 0.25
			return
	var id := GS.held()
	var it: Dictionary = Data.ITEMS[id] if id != "" else {}
	var type: String = it.get("type", "")
	match type:
		"food":
			if pressed and GS.consume(GS.sel):
				level.number(position + Vector2(0, -22), "Yum", Color("f2cf5b"))
				cooldown = 0.3
			return
		"place":
			if not pressed:
				return
			if level.kind == "town":
				_say("You can't build in town.")
			elif level.place(id, position, facing):
				GS.remove_at(GS.sel)
			else:
				_say("No room to place that. Face flat, open ground.")
			cooldown = 0.25
			return
		"book":
			if pressed:
				level.main.hud.open_book(it.book)
			return
		"helmet", "armor", "shield", "ring", "pet":
			if pressed:
				GS.equip_from(GS.sel)
				if type == "pet":
					level.spawn_pet()
			return
		"character":
			if pressed:
				level.main.hud.toast(GS.use_character(GS.sel), "big")
				level.burst(position + Vector2(0, -8), Color("ffe08a"), 14)
				cooldown = 0.4
			return
		"throw":
			_throw(id, it)
			return
		"egg", "seed", "key", "scroll", "token", "ammo":
			if pressed:
				_say({"egg": "Hatch eggs in the Incubator in Pixel Town.", "seed": "Plant seeds in the soil behind the rock wall in town.",
					"key": "Use keys on the chests in Pixel Town.", "scroll": "Put scrolls in the scroll slot when combining.",
					"token": "Trade Survival Tokens with the Miner.", "ammo": "Hold the bow or cannon that uses it, then press A."}[type])
			return
		"staff":
			_cast(id, it)
			return
		"bow":
			_shoot(id, it)
			return
	_swing(id, it)

func _swing(id: String, it: Dictionary) -> void:
	if GS.st < STAMINA_COST:
		_say("Too tired! Wait for your stamina.")
		return
	GS.st -= STAMINA_COST
	GS.stats_changed.emit()
	var spd: float = it.get("spd", 0.5)
	cooldown = spd
	swing_len = minf(0.3, spd * 0.8)
	swing = swing_len
	swing_hit = false

func _cast(id: String, it: Dictionary) -> void:
	var cost: int = it.mana_cost
	if GS.mp < cost:
		_say("Not enough mana.")
		return
	GS.mp -= cost
	GS.stats_changed.emit()
	cooldown = float(it.spd)
	swing_len = 0.25
	swing = swing_len
	swing_hit = true
	if it.has("heal"):
		GS.hp = minf(GS.max_hp(), GS.hp + it.heal)
		GS.stats_changed.emit()
		level.number(position + Vector2(0, -24), "+%d" % it.heal, Color("5cbf3f"))
		level.burst(position + Vector2(0, -8), Color("5cbf3f"), 8)
		return
	var dmg := int(it.dmg) + GS.stat("mag")
	var p := ProjectileScript.new()
	p.setup(level, Vector2(facing * 170, 0), dmg, true, Color(it.color))
	p.position = position + Vector2(facing * 8, -10)
	level.entities.add_child(p)
	level.share_projectile(p)

func _shoot(id: String, it: Dictionary) -> void:
	var ammo: String = it.get("ammo", "arrow")
	if GS.count(ammo) <= 0:
		_say("You're out of %s." % Data.ITEMS[ammo].name)
		return
	GS.remove_item(ammo, 1)
	cooldown = float(it.spd)
	var r := GS.attack_range(id)
	var p := ProjectileScript.new()
	if it.get("cannon", false):
		p.setup(level, Vector2(facing * 200, -40), randi_range(r.x, r.y), true, Color("3a3540") if ammo.begins_with("cc") else Color("d9542c"))
		p.radius = 4.0
		p.gravity = 160.0
		level.main.shake(2.0)
	else:
		p.setup(level, Vector2(facing * 220, -20), randi_range(r.x, r.y), true, Color("e8dccb"))
		p.gravity = 120.0
	p.position = position + Vector2(facing * 8, -10)
	level.entities.add_child(p)
	level.share_projectile(p)

## Snow Balls are thrown straight from the hand and used up.
func _throw(id: String, it: Dictionary) -> void:
	GS.remove_at(GS.sel, 1)
	cooldown = float(it.spd)
	var r := GS.attack_range(id)
	var p := ProjectileScript.new()
	p.setup(level, Vector2(facing * 180, -60), randi_range(r.x, r.y), true, Color("f4fbff"))
	p.gravity = 300.0
	p.position = position + Vector2(facing * 8, -10)
	level.entities.add_child(p)
	level.share_projectile(p)

func _do_hit() -> void:
	var id := GS.held()
	var it: Dictionary = Data.ITEMS[id] if id != "" else {}
	var reach: float = it.get("reach", 14)
	var x0 := position.x + (2.0 if facing > 0 else -2.0 - reach)
	var r := Rect2(x0, position.y - 24, reach, 26)
	var mobs: Array = level.mobs_in_rect(r)
	if mobs.size() > 0:
		for m in mobs:
			m.take_damage(GS.roll_attack(id), position.x, it.get("kb", false))
		return
	var n: Node = level.node_in_rect(r)
	if n == null:
		return
	var need: String = n.def.tool
	var tier := 0
	if it.get("type", "") == need:
		tier = int(it.tier)
	elif need == "axe" and it.has("axe"):
		tier = int(it.axe)
	if tier <= 0:
		_say("You need %s for that." % ("an axe" if need == "axe" else "a pickaxe"))
		n.shake()
		return
	if Data.hits_needed(n.kind, tier) < 0:
		_say("You need a better %s for that." % ("axe" if need == "axe" else "pickaxe"))
		n.shake()
		return
	n.hit(tier)

func hurt(dmg: int, crit_chance: float, from_x: float, status := []) -> void:
	if dead or invuln > 0:
		return
	var r := GS.roll_monster_hit(dmg, crit_chance)
	GS.hp -= r.dmg
	GS.stats_changed.emit()
	invuln = 0.6
	flash = 0.12
	since_hurt = 0
	velocity = Vector2(signf(position.x - from_x) * 140, -130)
	level.number(position + Vector2(0, -24), ("CRIT -%d" if r.crit else "-%d") % r.dmg, Color("f06a5a"))
	level.main.shake(4 if r.crit else 2)
	if status.size() == 2 and randf() < status[1]:
		GS.add_status(status[0])
	if GS.hp <= 0:
		_die()

func _die() -> void:
	auto_attack = false
	GS.hp = 0
	dead = true
	body_sprite.rotation = PI / 2 * facing
	level.main.player_died()

func hit_rect() -> Rect2:
	return Rect2(position.x - 5, position.y - 16, 10, 16)

## The bomb button: faint on purpose to get back to Pixel Town (nothing is lost).
func self_destruct() -> void:
	if dead:
		return
	level.burst(position + Vector2(0, -8), Color("3e424a"), 16)
	level.main.shake(3.0)
	_die()

## What the rest of the room needs to draw you.
func net_state() -> Dictionary:
	return {"world": level.id, "x": position.x, "y": position.y, "f": facing, "frame": cur_frame, "look": GS.look,
		"helmet": GS.equip.get("helmet", ""), "armor": GS.equip.get("armor", ""), "held": GS.held(), "dead": dead, "swing": swing > 0}

## In a room you get back up where the map starts instead of going home.
func revive() -> void:
	dead = false
	body_sprite.rotation = 0
	position = level.cell_pos(level.spawn_cell)
	velocity = Vector2.ZERO
	invuln = 2.0
