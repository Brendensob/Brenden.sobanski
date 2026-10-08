extends CharacterBody2D
## The player. ◀ ▶ to move, B to jump, A to use whatever you are holding:
## swing a weapon or tool, eat food, place a wall or torch, or talk to someone nearby.

const ProjectileScript := preload("res://scripts/projectile.gd")

const SPEED := 82.0
const JUMP := -238.0
const GRAVITY := 720.0
const SWING_TIME := 0.32
const HIT_AT := 0.1

var level: Node
var facing := 1
var anim := 0.0
var swing := 0.0
var swing_hit := false
var invuln := 0.0
var flash := 0.0
var stamina_wait := 0.0
var mana_timer := 0.0
var hp_timer := 0.0
var since_hurt := 99.0
var tired_msg := 0.0
var dead := false
var body_sprite: Sprite2D
var held_sprite: Sprite2D
var light: PointLight2D
var touch_act := false

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
	held_sprite.offset = Vector2(4, -5)
	add_child(held_sprite)
	body_sprite = Sprite2D.new()
	body_sprite.position = Vector2(0, -9)
	add_child(body_sprite)
	light = PointLight2D.new()
	light.texture = Art.light_tex()
	light.texture_scale = 1.1
	light.energy = 0.0
	light.position = Vector2(0, -10)
	add_child(light)
	GS.inventory_changed.connect(_update_held)
	_update_held()

func _update_held() -> void:
	var id := GS.held()
	held_sprite.texture = Art.icon(id) if id != "" else null
	held_sprite.visible = id != ""

func _physics_process(delta: float) -> void:
	if dead:
		return
	var dir := 0.0
	if not level.main.input_blocked():
		dir = Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP
		if Input.is_action_just_pressed("attack"):
			use_held()
		elif Input.is_action_pressed("attack") and swing <= 0 and _held_type() in ["weapon", "axe", "pick", "", "wand"]:
			use_held()
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 400)
	var target := dir * SPEED
	velocity.x = move_toward(velocity.x, target, 900 * delta)
	if dir != 0:
		facing = 1 if dir > 0 else -1
	move_and_slide()
	if position.y > 200:
		position = Vector2(position.x, level.surface_y(position.x) - 4)
		velocity = Vector2.ZERO
	_tick(delta, dir)

func _held_type() -> String:
	var id := GS.held()
	return Data.ITEMS[id].type if id != "" else ""

func _tick(delta: float, dir: float) -> void:
	anim += delta
	invuln -= delta
	flash -= delta
	since_hurt += delta
	tired_msg -= delta
	# regenerate
	stamina_wait -= delta
	if stamina_wait <= 0 and GS.stamina < GS.max_stamina():
		GS.stamina = minf(GS.max_stamina(), GS.stamina + delta * 1.25)
		GS.stats_changed.emit()
	mana_timer += delta
	if mana_timer > 5.0:
		mana_timer = 0
		if GS.mana < GS.max_mana():
			GS.mana = minf(GS.max_mana(), GS.mana + 1)
			GS.stats_changed.emit()
	if since_hurt > 6.0:
		hp_timer += delta
		if hp_timer > 8.0:
			hp_timer = 0
			if GS.hp < GS.max_hp():
				GS.hp = minf(GS.max_hp(), GS.hp + 1)
				GS.stats_changed.emit()
	# swing
	if swing > 0:
		swing -= delta
		if not swing_hit and swing <= SWING_TIME - HIT_AT:
			swing_hit = true
			_do_hit()
	# looks
	var frame := "stand"
	if not is_on_floor():
		frame = "jump"
	elif dir != 0 and int(anim * 8) % 2 == 1:
		frame = "walk"
	body_sprite.texture = Art.character_flash("player") if flash > 0 else Art.character("player", frame)
	body_sprite.flip_h = facing < 0
	if invuln > 0 and flash <= 0:
		body_sprite.visible = int(anim * 20) % 2 == 0
	else:
		body_sprite.visible = true
	held_sprite.position = Vector2(facing * 5, -7)
	held_sprite.flip_h = facing < 0
	held_sprite.offset = Vector2(4 * facing, -5)
	var ang := -0.5
	if swing > 0:
		var k := 1.0 - swing / SWING_TIME
		ang = lerpf(-2.0, 1.4, minf(k * 2.0, 1.0))
	held_sprite.rotation = ang * facing
	light.energy = GS.darkness() * (0.8 if GS.held() == "torch" else 0.3)
	light.texture_scale = 1.8 if GS.held() == "torch" else 1.1

# ---------------------------------------------------------------- actions
func use_held() -> void:
	if swing > 0:
		return
	var near: Node = level.interactable_near(position)
	if near:
		near.interact(self)
		return
	var id := GS.held()
	var type := _held_type()
	if type == "food":
		if GS.consume(GS.sel):
			level.number(position + Vector2(0, -22), "Yum", Color("f2cf5b"))
		return
	if type == "place":
		if level.is_town:
			level.main.hud.toast("You can't build in the village.", "warn")
			return
		if level.place(id, position, facing):
			GS.remove_at(GS.sel)
		else:
			level.main.hud.toast("No room to place that. Face flat, empty ground.", "warn")
		return
	if type in ["book", "key", "material", "armor", "helmet", "shield", "ring"]:
		if type in Data.EQUIP_SLOTS:
			GS.equip_from(GS.sel)
			return
	if type == "wand":
		var cost: int = Data.ITEMS[id].mana_cost
		if GS.mana < cost:
			if tired_msg <= 0:
				level.main.hud.toast("Not enough mana.", "warn")
				tired_msg = 1.5
			return
		GS.mana -= cost
		GS.stats_changed.emit()
		swing = SWING_TIME
		swing_hit = true
		var p := ProjectileScript.new()
		p.setup(level, Vector2(facing * 170, 0), Data.ITEMS[id].dmg + GS.bonus_damage(), true, Color("f2a33a"))
		p.position = position + Vector2(facing * 8, -10)
		level.entities.add_child(p)
		return
	# swing a weapon, tool or fists
	if GS.stamina < 1.0:
		if tired_msg <= 0:
			level.main.hud.toast("Too tired! Wait for your stamina.", "warn")
			tired_msg = 1.5
		return
	GS.stamina -= 1.0
	stamina_wait = 0.6
	GS.stats_changed.emit()
	swing = SWING_TIME
	swing_hit = false

func _do_hit() -> void:
	var x0 := position.x + (2 if facing > 0 else -24)
	var r := Rect2(x0, position.y - 24, 22, 26)
	var id := GS.held()
	var it: Dictionary = Data.ITEMS[id] if id != "" else {}
	var dmg := float(it.get("dmg", 1)) + GS.bonus_damage()
	var mobs: Array = level.mobs_in_rect(r)
	if mobs.size() > 0:
		for m in mobs:
			m.take_damage(dmg, position.x)
		return
	var n: Node = level.node_in_rect(r)
	if n:
		var need: String = n.def.need
		var power := 1
		if need == "":
			power = 1
		elif it.get("type", "") == need:
			power = int(it.power)
			if power < int(n.def.min):
				level.main.hud.toast("You need a better %s for that." % ("pickaxe" if need == "pick" else "axe"), "warn")
				n.shake()
				return
		else:
			level.main.hud.toast("Hold %s to break that." % ("a pickaxe" if need == "pick" else "an axe"), "warn")
			n.shake()
			return
		n.hit(power)

func hurt(dmg: float, from_x: float) -> void:
	if dead or invuln > 0:
		return
	var real := maxf(1.0, dmg - GS.defense())
	GS.hp -= real
	GS.stats_changed.emit()
	invuln = 0.9
	flash = 0.12
	since_hurt = 0
	hp_timer = 0
	velocity = Vector2(signf(position.x - from_x) * 150, -140)
	level.number(position + Vector2(0, -24), "-%d" % int(real), Color("f06a5a"))
	level.main.shake(3)
	if GS.hp <= 0:
		GS.hp = 0
		dead = true
		body_sprite.rotation = PI / 2 * facing
		level.main.player_died()

func hit_rect() -> Rect2:
	return Rect2(position.x - 5, position.y - 16, 10, 16)
