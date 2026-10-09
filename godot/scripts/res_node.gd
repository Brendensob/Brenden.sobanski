extends Node2D
## A tree, rock, ore, plant, pot or vase. Breaks after a set number of hits;
## better tools need fewer hits (numbers from the wiki's tool pages).

const REGROW := 60.0

var kind := ""
var def: Dictionary
var level: Node
var hits := 0
var alive := true
var regrow := 0.0
var wobble := 0.0
var sprite: Sprite2D
var body: StaticBody2D
var nid := 0

func setup(k: String, lvl: Node) -> void:
	kind = k
	def = Data.NODES[k]
	level = lvl

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = Art.node_tex(kind, level.th)
	sprite.centered = false
	var s: Vector2 = sprite.texture.get_size()
	sprite.position = Vector2(-s.x / 2, -s.y + 1)
	sprite.visible = alive
	add_child(sprite)

## The village rock wall blocks the way until it's broken.
func make_solid() -> void:
	body = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 48)
	shape.shape = rect
	shape.position = Vector2(0, -24)
	body.add_child(shape)
	add_child(body)

func _process(delta: float) -> void:
	if not alive:
		if level.kind != "survival" or not Net.authority():
			return
		regrow -= delta
		if regrow <= 0:
			alive = true
			hits = 0
			sprite.visible = true
			if level.netted and Net.is_host():
				Net.node_changed.rpc(level.id, nid, hits, alive)
		return
	if wobble > 0:
		wobble -= delta
		var s: Vector2 = sprite.texture.get_size()
		sprite.position.x = -s.x / 2 + sin(wobble * 60) * 1.5

func hit_rect() -> Rect2:
	var s: Vector2 = sprite.texture.get_size()
	var w := minf(s.x, 14)
	return Rect2(position.x - w / 2, position.y - minf(s.y, 30), w, minf(s.y, 30))

func shake() -> void:
	wobble = 0.15

func hit(tier: int, _from_net: bool = false) -> void:
	if level.netted and Net.is_client():
		# the host counts the hits and drops the loot
		shake()
		level.burst(position + Vector2(0, -8), Color(def.color), 3)
		Net.hit_node.rpc_id(1, level.id, nid, tier)
		return
	var need := Data.hits_needed(kind, tier)
	hits += 1
	shake()
	var c := Color(def.color)
	level.burst(position + Vector2(0, -8), c, 3)
	level.number(position + Vector2(0, -20), "%d/%d" % [hits, need], Color("e8dccb"))
	if hits < need and level.netted and Net.is_host():
		Net.node_changed.rpc(level.id, nid, hits, alive)
	if hits >= need:
		alive = false
		Sfx.play("break")
		regrow = REGROW
		sprite.visible = false
		level.burst(position + Vector2(0, -8), c, 10)
		for d in def.drops:
			if randf() < d[1]:
				level.drop(d[0], randi_range(d[2], d[3]), position + Vector2(0, -6))
		if level.netted and Net.is_host():
			Net.node_changed.rpc(level.id, nid, hits, alive)
		if def.get("wall", false):
			GS.flags[def.get("flag", "rock_wall")] = true
			if def.tool == "torch":
				for k in 4:
					level.burst(position + Vector2(randf_range(-6, 6), -8 - k * 10), Color("f2a33a"), 8)
			level.main.hud.toast(def.get("opened", "The rock wall crumbles! The soils behind it are yours."), "good")
			if body:
				body.queue_free()
			queue_free()
