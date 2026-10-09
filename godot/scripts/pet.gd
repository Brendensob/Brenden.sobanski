extends Node2D
## Your pet follows you and, every few seconds, heals you, restores mana or
## stamina, or attacks the nearest monster (numbers from the wiki's pets page).

var pet_id := ""
var def: Dictionary
var level: Node
var sprite: Sprite2D
var timer := 0.0
var anim := 0.0

func setup(id: String, lvl: Node) -> void:
	pet_id = id
	def = Data.PETS[id]
	level = lvl

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = Art.mob_tex(def.look, false)
	var s: Vector2 = sprite.texture.get_size()
	var k := minf(1.0, 14.0 / maxf(s.x, s.y))
	sprite.scale = Vector2(k, k)
	add_child(sprite)

func _process(delta: float) -> void:
	anim += delta
	var p: Node2D = level.player
	var target := p.position + Vector2(-p.facing * 16, -20 + sin(anim * 3) * 3)
	position = position.lerp(target, minf(1.0, delta * 4))
	sprite.flip_h = p.facing < 0
	timer += delta
	if timer < float(def.every):
		return
	timer = 0
	if def.get("hp", 0) > 0 and GS.hp < GS.max_hp():
		GS.hp = minf(GS.max_hp(), GS.hp + def.hp)
		level.number(p.position + Vector2(0, -26), "+%d" % def.hp, Color("5cbf3f"))
	if def.get("mp", 0) > 0:
		GS.mp = minf(GS.max_mp(), GS.mp + def.mp)
	if def.get("st", 0) > 0:
		GS.st = minf(GS.max_st(), GS.st + def.st)
	GS.stats_changed.emit()
	if def.get("dmg", 0) > 0:
		var m: Node = level.nearest_mob(position, 90)
		if m:
			m.take_damage(int(def.dmg), position.x, false)
			level.burst(m.position + Vector2(0, -8), Color("f2cf5b"), 5)
