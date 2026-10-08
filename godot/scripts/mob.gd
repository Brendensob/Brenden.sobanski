extends CharacterBody2D
## Monsters and bosses. AI types: hopper, walker, charger, flyer.

const ProjectileScript := preload("res://scripts/projectile.gd")
const GRAVITY := 720.0
const FACES_LEFT := ["boar"]

var id := ""
var def: Dictionary
var level: Node
var hp := 1.0
var max_hp := 1.0
var dead := false
var dir := 1
var aggro := false
var think := 0.0
var hop_timer := 0.0
var contact_cd := 0.0
var flash := 0.0
var anim := 0.0
var show_bar := 0.0
var charge := 0.0
var rest := 0.0
var shoot_timer := 3.0
var summon_timer := 8.0
var blocked_time := 0.0
var home := Vector2.ZERO
var frames: Array
var sprite: Sprite2D
var size := Vector2(12, 10)

func setup(mob_id: String, lvl: Node) -> void:
	id = mob_id
	def = Data.MOBS[id]
	level = lvl
	max_hp = randf_range(def.hp[0], def.hp[1])
	hp = max_hp
	frames = Art.mob_frames(def.sprite)
	size = frames[0].get_size()

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(maxf(size.x - 6, 6), maxf(size.y - 4, 6))
	shape.shape = rect
	shape.position = Vector2(0, -rect.size.y / 2)
	add_child(shape)
	sprite = Sprite2D.new()
	sprite.texture = frames[0]
	sprite.position = Vector2(0, -size.y / 2 + 1)
	add_child(sprite)
	home = position
	dir = 1 if randf() < 0.5 else -1
	hop_timer = randf_range(0.2, 1.2)

func is_boss() -> bool:
	return def.get("boss", false)

func _physics_process(delta: float) -> void:
	if dead:
		return
	anim += delta
	flash -= delta
	contact_cd -= delta
	show_bar -= delta
	var p: CharacterBody2D = level.player
	var dx := p.position.x - position.x
	var dist := absf(dx)
	var player_ok: bool = not p.dead
	aggro = player_ok and dist < def.aggro and absf(p.position.y - position.y) < 120
	if is_boss():
		var rate: float = def.regen * (1.0 if aggro else 10.0)
		hp = minf(max_hp, hp + rate * delta)

	match def.ai:
		"hopper":
			_hopper(delta, dx, dist)
		"walker":
			_walker(delta, dx, dist)
		"charger":
			_charger(delta, dx, dist)
		"flyer":
			_flyer(delta, p)
	if def.ai != "flyer":
		velocity.y = minf(velocity.y + GRAVITY * delta, 400)
	var before := position.x
	move_and_slide()
	if position.y > 200:
		position.y = level.surface_y(position.x) - 2
	# stuck against a wall the player built: break it
	if def.ai != "flyer" and absf(velocity.x) > 1 and absf(position.x - before) < 0.05:
		blocked_time += delta
		if blocked_time > 0.8:
			blocked_time = 0
			_hit_wall()
	else:
		blocked_time = 0
	if is_boss() and def.has("summon"):
		summon_timer -= delta
		if summon_timer <= 0 and aggro:
			summon_timer = 10.0
			if level.count_mobs() < 5:
				level.spawn_mob_at(def.summon, position.x - dir * 30)
	if def.get("shoots", false) and aggro:
		shoot_timer -= delta
		if shoot_timer <= 0:
			shoot_timer = 2.2
			var to := (p.position + Vector2(0, -8) - position).normalized()
			var pr := ProjectileScript.new()
			pr.setup(level, to * 110, def.dmg, false, Color("a77ee0"))
			pr.position = position + Vector2(0, -12)
			level.entities.add_child(pr)
	# touching the player hurts
	if player_ok and contact_cd <= 0 and hit_rect().intersects(p.hit_rect()):
		contact_cd = 0.8
		p.hurt(def.dmg, position.x)
	# looks
	var alt := false
	match def.ai:
		"hopper":
			alt = is_on_floor() and hop_timer < 0.15
		"flyer":
			alt = int(anim * 8) % 2 == 1
		_:
			alt = absf(velocity.x) > 1 and int(anim * 6) % 2 == 1
	sprite.texture = frames[2] if flash > 0 else frames[1 if alt else 0]
	var face_left := velocity.x < -1 or (absf(velocity.x) <= 1 and dir < 0)
	sprite.flip_h = face_left != (def.sprite in FACES_LEFT)
	queue_redraw()

func _hopper(delta: float, dx: float, dist: float) -> void:
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, 600 * delta)
		hop_timer -= delta
		if hop_timer <= 0:
			if aggro:
				dir = 1 if dx > 0 else -1
			elif randf() < 0.3:
				dir = -dir
			var big: bool = def.get("jump_close", false) and aggro and dist < 60
			velocity.y = -250.0 if big else -150.0
			velocity.x = dir * def.speed * (2.2 if big else 1.6)
			hop_timer = randf_range(0.5, 1.1) if aggro else randf_range(0.9, 2.2)

func _walker(delta: float, dx: float, dist: float) -> void:
	think -= delta
	if aggro:
		dir = 1 if dx > 0 else -1
		if dist < 4:
			velocity.x = 0
		else:
			velocity.x = dir * def.speed
		if def.get("jump_close", false) and dist < 50 and is_on_floor() and randf() < delta * 1.5:
			velocity.y = -220
	else:
		if think <= 0:
			think = randf_range(1.0, 3.0)
			dir = [-1, 0, 1][randi() % 3]
		velocity.x = dir * def.speed * 0.5
	if is_on_wall() and is_on_floor():
		velocity.y = -210

func _charger(delta: float, dx: float, dist: float) -> void:
	if rest > 0:
		rest -= delta
		velocity.x = move_toward(velocity.x, 0, 400 * delta)
		return
	if charge > 0:
		charge -= delta
		velocity.x = dir * def.speed * 3.2
		if charge <= 0:
			rest = 0.9
		if is_on_wall() and is_on_floor():
			velocity.y = -210
		return
	if aggro and dist < 110:
		dir = 1 if dx > 0 else -1
		charge = 0.9
		if def.get("jump_close", false) and is_on_floor() and randf() < 0.4:
			velocity.y = -260
		return
	_walker(delta, dx, dist)

func _flyer(delta: float, p: Node2D) -> void:
	var target: Vector2
	if aggro:
		target = p.position + Vector2(0, -14 + sin(anim * 3) * 10)
	else:
		target = home + Vector2(sin(anim * 0.7) * 40, sin(anim * 1.3) * 10)
	var to := target - position
	var want: Vector2 = to.normalized() * float(def.speed) if to.length() > 2 else Vector2.ZERO
	if def.get("shoots", false) and aggro and to.length() < 70:
		want = -want * 0.5
	velocity = velocity.move_toward(want, 300 * delta)
	if velocity.x != 0:
		dir = 1 if velocity.x > 0 else -1

func _hit_wall() -> void:
	for n in level.props.get_children():
		if n.has_method("is_wall") and n.is_wall() and absf(n.position.x - position.x) < size.x / 2 + 12:
			n.damage(def.dmg)
			return

func hit_rect() -> Rect2:
	return Rect2(position.x - size.x / 2 + 2, position.y - size.y + 2, size.x - 4, size.y - 2)

func take_damage(dmg: float, from_x: float) -> void:
	if dead:
		return
	hp -= dmg
	flash = 0.1
	show_bar = 4.0
	aggro = true
	level.number(position + Vector2(0, -size.y - 4), str(int(dmg)), Color.WHITE)
	if not def.get("no_knockback", false):
		velocity = Vector2(signf(position.x - from_x) * 130, -110)
	if hp <= 0:
		die()

func die() -> void:
	dead = true
	level.burst(position + Vector2(0, -size.y / 2), Color("f2efe6"), 10 if is_boss() else 6)
	for d in def.drops:
		if randf() < d[1]:
			level.drop(d[0], randi_range(d[2], d[3]), position)
	var c := randi_range(def.coins[0], def.coins[1])
	if c > 0:
		level.drop("coin", c, position)
	if is_boss():
		GS.defeat_boss(id)
		level.main.hud.toast("%s defeated!" % def.name, "good")
		level.main.hud.set_boss(null)
		level.main.shake(6)
		for e in level.entities.get_children():
			if e != self and e.has_method("die") and not e.dead:
				e.die()
	queue_free()

func _draw() -> void:
	if show_bar > 0 and not is_boss() and not dead:
		var w := maxf(size.x, 14)
		var y := -size.y - 4
		draw_rect(Rect2(-w / 2 - 1, y - 1, w + 2, 4), Color("1b1a24"))
		draw_rect(Rect2(-w / 2, y, w * clampf(hp / max_hp, 0, 1), 2), Color("e2553f"))
