extends Node2D
## An item lying on the ground. It pops out, lands, and flies to you when you get close.

var item := ""
var n := 1
var level: Node
var vel := Vector2.ZERO
var life := 0.0
var landed := false
var sprite: Sprite2D
var nid := 0 # shared pickups in a room have a number; the host decides who gets them
var taken := false

func setup(id: String, count: int, lvl: Node) -> void:
	item = id
	n = count
	level = lvl
	vel = Vector2(randf_range(-40, 40), randf_range(-150, -100))

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = Art.prop_tex("coin") if item == "coin" else Art.icon(item)
	sprite.position = Vector2(0, -6)
	add_child(sprite)

func _process(delta: float) -> void:
	life += delta
	if life > 180 and not (nid != 0 and Net.is_client()):
		if nid != 0 and Net.is_host() and level.netted:
			Net.pickup_gone.rpc(level.id, nid)
			level.net_objs.erase(nid)
		queue_free()
		return
	var p: Node2D = level.player
	var to := p.position + Vector2(0, -8) - position
	var can_take: bool = item == "coin" or GS.has_room(item)
	if life > 0.5 and not p.dead and can_take and to.length() < 34:
		position += to.normalized() * minf(to.length(), 170 * delta)
		if to.length() < 8:
			_collect()
		return
	if not landed:
		vel.y += 600 * delta
		var nxt := position + vel * delta
		var ground: float = level.floor_y(nxt.x, position.y - 2)
		if nxt.y >= ground:
			nxt.y = ground
			vel = Vector2.ZERO
			landed = true
		position = nxt
	sprite.position.y = (-6 - absf(sin(life * 3)) * 2) if landed else -6.0

func _collect() -> void:
	if nid != 0 and level.netted and Net.is_client():
		Net.ask_pickup(nid)
		return
	if nid != 0 and level.netted and Net.is_host():
		taken = true
		Net.pickup_gone.rpc(level.id, nid)
		level.net_objs.erase(nid)
	if item == "coin":
		GS.coins += n
		GS.stats_changed.emit()
		level.number(position + Vector2(0, -10), "+%d coins" % n, Color("f2cf5b"))
		queue_free()
		return
	var left := GS.add_item(item, n, true)
	if left < n:
		level.main.hud.toast("%s obtained" % Data.ITEMS[item].name + (" x%d" % (n - left) if n - left > 1 else ""), "")
	n = left
	if n <= 0:
		queue_free()
	else:
		level.main.hud.toast("Inventory full.", "warn")
		life = 0.0
