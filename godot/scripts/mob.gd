extends CharacterBody2D
## Monsters and bosses. Movement follows the wiki's descriptions:
## walk (constant speed), accel (speeds up while going one way), charge
## (waits, rushes, then stops), fly (flies at increasing speed), wizard
## (keeps distance and shoots), stone (moves up and down, can't be hurt).

const ProjectileScript := preload("res://scripts/projectile.gd")
const GRAVITY := 720.0
## Knockback, measured from the trailer: a hit with a knockback weapon pushes a
## monster back only a few pixels and it comes right back. Heavy monsters and
## bosses don't move at all.
const KNOCK_SPEED := 90.0
const KNOCK_TIME := 0.12
## The main colour of each monster's sprite, for the burst when it dies.
static var _death_colors := {}

var id := ""
var def: Dictionary
var level: Node
var hp := 1.0
var max_hp := 1.0
var dmg := 1
var dead := false
var dir := 1
var aggro := false
var aggro_forced := false
var arena_boss := false
var think := 0.0
var hop := 0.0
var accel := 0.0
var state := "idle"
var state_t := 0.0
var contact_cd := 0.0
var shoot_cd := 2.0
var regen_t := 0.0
var flash := 0.0
var anim := 0.0
var show_bar := 0.0
var spike_cd := 0.0
var knock_t := 0.0
var home := Vector2.ZERO
var frames: Array
var sprite: Sprite2D
var size := Vector2(12, 10)
var flying := false
var through := false
# multiplayer: on a guest's screen monsters are puppets that follow the host
var nid := 0
var puppet := false
var net_target := Vector2.ZERO

func setup(mob_id: String, lvl: Node, hp_mul: float = 1.0, dmg_mul: float = 1.0) -> void:
	id = mob_id
	def = Data.MOBS[id]
	level = lvl
	# a world can give a monster the health the wiki lists for it there
	var hp_range: Array = lvl.def.get("hp", {}).get(id, def.hp)
	max_hp = round(randf_range(hp_range[0], hp_range[1]) * hp_mul)
	hp = max_hp
	dmg = maxi(1, int(round(def.dmg * dmg_mul)))
	flying = def.ai == "fly"
	through = def.get("through", false)
	var look: String = def.look
	frames = [Art.mob_tex(look, false), Art.mob_tex(look, true), Art.mob_tex(look, false, true)]
	size = frames[0].get_size() * def.get("scale", 1.0)

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0 if through else 1
	disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(maxf(size.x - 6, 6), maxf(size.y - 3, 6))
	shape.shape = rect
	shape.position = Vector2(0, -rect.size.y / 2)
	add_child(shape)
	sprite = Sprite2D.new()
	sprite.texture = frames[0]
	sprite.scale = Vector2.ONE * def.get("scale", 1.0)
	sprite.position = Vector2(0, -size.y / 2 + 1)
	add_child(sprite)
	home = position
	dir = 1 if randf() < 0.5 else -1
	hop = randf_range(0.2, 1.2)
	state_t = randf_range(0.5, 2.0)

## What touching this monster can give you. In Hell every monster except
## wizards and bosses can poison you, on top of their own effects.
func status_effect() -> Array:
	var own: Array = def.get("status", [])
	if own.is_empty() and level.def.has("status") and not is_boss() and def.ai != "wizard":
		return level.def.status
	return own

## Monsters burst into squares of their own colour, like the original.
func death_color() -> Color:
	var look: String = def.look
	if not _death_colors.has(look):
		var img: Image = frames[0].get_image()
		var counts := {}
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.5 and c.get_luminance() > 0.12:
					var key := c.to_html(false)
					counts[key] = counts.get(key, 0) + 1
		var best := "f2efe6"
		for k in counts:
			if counts[k] > counts.get(best, 0):
				best = k
		_death_colors[look] = Color(best)
	return _death_colors[look]

func is_boss() -> bool:
	return def.get("boss", false) or arena_boss

func _physics_process(delta: float) -> void:
	if dead:
		return
	if puppet:
		_puppet_tick(delta)
		return
	anim += delta
	flash -= delta
	contact_cd -= delta
	show_bar -= delta
	spike_cd -= delta
	var p: Node2D = level.target_for(position)
	var to := p.position - position
	var dist := to.length()
	var player_ok: bool = not p.dead
	var rng_aggro := 400.0 if is_boss() else 150.0
	aggro = player_ok and (aggro_forced or (dist < rng_aggro and absf(to.y) < 90))
	if is_boss():
		# bosses heal, ten times faster when nobody is fighting them
		regen_t += delta
		if regen_t >= 1.0:
			regen_t = 0
			hp = minf(max_hp, hp + max_hp * 0.0008 * (1.0 if aggro else 10.0))
	if knock_t > 0:
		# pushed back: the monster slides a little before it moves on its own again
		knock_t -= delta
		velocity.x = move_toward(velocity.x, 0, 500 * delta)
		if flying:
			velocity.y = move_toward(velocity.y, 0, 500 * delta)
	else:
		match def.ai:
			"walk": _walk(delta, to, dist)
			"accel": _accel(delta, to, dist)
			"charge": _charge(delta, to, dist)
			"fly": _fly(delta, to, dist)
			"wizard": _wizard(delta, to, dist)
			"stone": _stone(delta)
	if not flying and def.ai != "stone":
		velocity.y = minf(velocity.y + GRAVITY * delta, 420)
	move_and_slide()
	if position.y > level.H * 16 + 60:
		dead = true
		if level.netted and Net.is_host():
			Net.mob_died.rpc(level.id, nid)
			level.net_objs.erase(nid)
		queue_free()
		return
	# walk into the player's walls: hit them
	if not flying and is_on_wall() and absf(velocity.x) > 1:
		if is_on_floor() and randf() < delta * 3:
			velocity.y = -220
		for n in level.props.get_children():
			if n.has_method("is_wall") and n.is_wall() and absf(n.position.x - position.x) < size.x / 2 + 12 and contact_cd <= 0:
				n.damage(dmg)
				contact_cd = 1.0
				break
	# spike traps
	if spike_cd <= 0:
		for n in level.props.get_children():
			if n.has_method("trap_damage") and absf(n.position.x - position.x) < 10 and absf(n.position.y - position.y) < 10:
				take_damage(n.trap_damage(), n.position.x, false)
				spike_cd = 0.7
				break
	# touching the player hurts
	if player_ok and contact_cd <= 0 and hit_rect().intersects(p.hit_rect()):
		contact_cd = 0.5 if def.get("fast_hits", false) else 0.9
		p.hurt(dmg, def.get("crit", 0.05), position.x, status_effect())
	# looks
	var alt := int(anim * (8 if flying else 5)) % 2 == 1 and (absf(velocity.x) > 1 or flying)
	if def.get("hop", false):
		alt = is_on_floor() and hop < 0.15
	sprite.texture = frames[2] if flash > 0 else frames[1 if alt else 0]
	if absf(velocity.x) > 1:
		dir = 1 if velocity.x > 0 else -1
	sprite.flip_h = dir < 0
	queue_redraw()

func _wander(delta: float) -> void:
	think -= delta
	if think <= 0:
		think = randf_range(1.0, 3.0)
		dir = [-1, 0, 1][randi() % 3]
	velocity.x = dir * float(def.speed) * 0.4

func _maybe_jump(dist: float, power: float = -230.0) -> void:
	if def.get("jump", false) and is_on_floor() and dist < 46 and randf() < 0.04:
		velocity.y = -330.0 if def.get("big_jump", false) else power

func _walk(delta: float, to: Vector2, dist: float) -> void:
	if def.get("hop", false):
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 600 * delta)
			hop -= delta
			if hop <= 0:
				if aggro:
					dir = 1 if to.x > 0 else -1
				elif randf() < 0.3:
					dir = -dir
				velocity.y = -150
				velocity.x = dir * float(def.speed) * 1.6
				hop = randf_range(0.5, 1.1) if aggro else randf_range(1.0, 2.2)
		return
	if aggro:
		velocity.x = signf(to.x) * float(def.speed) if absf(to.x) > 3 else 0.0
		_maybe_jump(dist)
	else:
		_wander(delta)

func _accel(delta: float, to: Vector2, dist: float) -> void:
	if not aggro:
		accel = 0
		_wander(delta)
		return
	var want := 1 if to.x > 0 else -1
	if want != dir:
		accel = 0
		dir = want
	accel = minf(accel + delta * 0.8, 1.6)
	velocity.x = dir * float(def.speed) * (0.6 + accel)
	_maybe_jump(dist)

func _charge(delta: float, to: Vector2, dist: float) -> void:
	state_t -= delta
	match state:
		"idle":
			if aggro:
				velocity.x = move_toward(velocity.x, signf(to.x) * float(def.speed) * 0.5, 300 * delta)
				if state_t <= 0:
					state = "charge"
					state_t = 1.3
					dir = 1 if to.x > 0 else -1
					if def.get("jump", false) and is_on_floor() and randf() < 0.5:
						velocity.y = -260
			else:
				_wander(delta)
				state_t = float(def.get("charge_wait", 1.5))
		"charge":
			velocity.x = dir * float(def.speed) * 3.0
			if state_t <= 0:
				state = "rest"
				state_t = 2.0
		"rest":
			velocity.x = move_toward(velocity.x, 0, 400 * delta)
			if state_t <= 0:
				state = "idle"
				state_t = float(def.get("charge_wait", 1.5))

func _fly(delta: float, to: Vector2, dist: float) -> void:
	var target: Vector2
	if aggro:
		target = to + Vector2(0, -12 + sin(anim * 3) * 8)
		accel = minf(accel + delta * 0.5, 1.8)
	else:
		target = home - position + Vector2(sin(anim * 0.7) * 40, sin(anim * 1.3) * 10)
		accel = 0.3
	var want := target.normalized() * float(def.speed) * (0.5 + accel) if target.length() > 2 else Vector2.ZERO
	velocity = velocity.move_toward(want, 220 * delta)
	if def.get("launch", false) and aggro and dist < 40 and randf() < 0.03:
		velocity.y = -200

func _wizard(delta: float, to: Vector2, dist: float) -> void:
	if not aggro:
		_wander(delta)
		return
	velocity.x = signf(to.x) * float(def.speed) if dist > 90 else 0.0
	dir = 1 if to.x > 0 else -1
	shoot_cd -= delta
	if shoot_cd <= 0 and dist < 200:
		shoot_cd = 2.2
		var pr := ProjectileScript.new()
		pr.setup(level, (to + Vector2(0, -8)).normalized() * 110, dmg, false, Color("6b8ff0") if id == "wizard" else Color("f2cf5b"))
		pr.position = position + Vector2(0, -12)
		level.entities.add_child(pr)
		level.share_projectile(pr)

func _stone(delta: float) -> void:
	velocity = Vector2.ZERO
	position.y = home.y - (sin(anim * 1.6) * 0.5 + 0.5) * 40.0

func hit_rect() -> Rect2:
	return Rect2(position.x - size.x / 2 + 2, position.y - size.y + 2, size.x - 4, size.y - 2)

func _puppet_tick(delta: float) -> void:
	anim += delta
	flash -= delta
	show_bar -= delta
	var moving := position.distance_to(net_target) > 0.5
	position = position.lerp(net_target, minf(1.0, delta * 12.0))
	var alt := int(anim * (8 if flying else 5)) % 2 == 1 and (moving or flying)
	sprite.texture = frames[2] if flash > 0 else frames[1 if alt else 0]
	sprite.flip_h = dir < 0
	queue_redraw()

func take_damage(amount: int, from_x: float, knock: bool, _from_net: bool = false) -> void:
	if dead:
		return
	if puppet:
		# show the hit right away; the host's game does the real damage
		if def.get("invulnerable", false):
			level.number(position + Vector2(0, -size.y - 4), "0", Color("9aa2ad"))
			return
		flash = 0.1
		show_bar = 4.0
		Sfx.play("hit")
		level.number(position + Vector2(0, -size.y - 4), str(amount), Color.WHITE)
		Net.hit_mob.rpc_id(1, level.id, nid, amount, from_x, knock)
		return
	if def.get("invulnerable", false):
		level.number(position + Vector2(0, -size.y - 4), "0", Color("9aa2ad"))
		return
	hp -= amount
	flash = 0.1
	if not _from_net:
		Sfx.play("hit")
	show_bar = 4.0
	aggro_forced = true
	level.number(position + Vector2(0, -size.y - 4), str(amount), Color.WHITE)
	if knock and not def.get("heavy", false) and not is_boss():
		velocity.x = signf(position.x - from_x) * KNOCK_SPEED
		if flying:
			velocity.y = -KNOCK_SPEED * 0.3
		elif is_on_floor():
			velocity.y = -60.0
		knock_t = KNOCK_TIME
		accel = 0.0 # a monster that was speeding up has to start over
	if hp <= 0:
		die()

func die() -> void:
	dead = true
	Sfx.play("mob_die")
	if level.netted and Net.is_host():
		Net.mob_died.rpc(level.id, nid)
		level.net_objs.erase(nid)
	level.burst(position + Vector2(0, -size.y / 2), death_color(), 24 if is_boss() else 10)
	# arena monsters drop the arena's own small loot, like the original
	var drops: Array = def.drops
	if level.kind == "arena" and not is_boss() and level.def.has("mob_drops"):
		drops = level.def.mob_drops
	for d in drops:
		if randf() < d[1]:
			level.drop(d[0], randi_range(d[2], d[3]), position)
	if def.has("coins"):
		level.drop("coin", randi_range(def.coins[0], def.coins[1]), position)
	if is_boss():
		level.announce("%s defeated!" % def.name, "good")
		level.main.shake(6)
	queue_free()

## A guest's copy of a monster the host's game says has died.
func die_visual() -> void:
	dead = true
	Sfx.play("mob_die")
	level.burst(position + Vector2(0, -size.y / 2), death_color(), 24 if is_boss() else 10)
	if is_boss():
		level.main.shake(6)
	queue_free()

func _draw() -> void:
	if show_bar > 0 and not is_boss() and not dead:
		var w := maxf(size.x, 14)
		var y := -size.y - 4
		draw_rect(Rect2(-w / 2 - 1, y - 1, w + 2, 4), Color("1b1a24"))
		draw_rect(Rect2(-w / 2, y, w * clampf(hp / max_hp, 0, 1), 2), Color("e2553f"))
