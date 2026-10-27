extends Node
## Plays real fights, to make sure no fight on the normal path is impossible.
## A simple bot walks up to one monster at a time and holds A (and jumps at
## flying ones, and drinks a potion when low). It uses the real player, the
## real monster AI, knockback, daze and the world's own health and damage.
## Each stage has the gear a player can make from the places before it.
## Run headless and fast:
##   godot --headless --path . --fixed-fps 60 -- --fighttest
## Ends with "FIGHTTEST DONE, N failures".
## FIGHT_TRIALS=n changes the tries per fight, FIGHT_ONLY=grass_1,dark_1 picks worlds.

var main: Node
const MobScript := preload("res://scripts/mob.gd")
var fails := []
var rows := []

## Every stage: the place, the gear you have by then, and which monsters must
## be beatable there (3 times in 4). "tough" ones must be beaten at least half
## the time: the wiki's UFO hits for 15 and flies, and its Worm hits for 17
## ("best to run away screaming if you aren't strong enough"), so they stay dangerous.
## "report" monsters are rare or optional (bosses you can leave alone), so
## they're printed but don't fail the test.
## Gear notes (what you can make before getting there):
##  fresh: the starter kit.
##  wood: Gradius (Crafter: 15 Copper Ore + 25 Rock), Wooden Helmet, Armor and Shield (wood).
##  stone: Golden Night (Miffie's 3rd quest, before Grasslands 2 on the goal list), Stone Armor.
##  copper: Golden Night, copper helmet, armor and shield (copper bars).
##  iron: Blue Night (Miffie's 4th quest), Brass Helmet (Miffie's 8th), Iron Armor and Shield.
##  gold: Kings Mace, Golden Knight Armor, Gold Shield, Brass Helmet, Gold and Silver Rings
##        (gold ore is mined in Darklands 1).
##  hell: Kings Mace, Chainmail, Fear Helmet, Gold Shield, Armor Ring I and a Gold Ring.
const STAGES := [
	{"name": "fresh", "world": "grass_1", "weapon": "sword_cast", "gear": {}, "potions": ["small_potion", 3],
		"must": ["slime", "wisp", "mummy", "shell"], "report": []},
	{"name": "wood", "world": "grass_1", "weapon": "short_blade", "gear": {"helmet": "wooden_helmet", "armor": "wooden_armor", "shield": "wooden_shield"}, "potions": ["small_potion", 5],
		"must": ["slime", "wisp", "mummy", "shell"], "report": []},
	{"name": "stone", "world": "grass_2", "weapon": "gilded_blade", "gear": {"helmet": "wooden_helmet", "armor": "stone_armor", "shield": "wooden_shield"}, "potions": ["small_potion", 6],
		"must": ["slime", "wisp", "mummy", "shell", "octopus"], "report": []},
	{"name": "copper", "world": "grass_3", "weapon": "gilded_blade", "gear": {"helmet": "copper_helmet", "armor": "copper_armor", "shield": "copper_shield"}, "potions": ["small_potion", 8],
		"must": ["slime", "octopus", "dark_slime", "mantis", "zombie", "trex"], "report": ["dark_trex"]},
	{"name": "iron", "world": "grass_arena", "weapon": "azure_blade", "gear": {"helmet": "brass_helmet", "armor": "iron_armor", "shield": "iron_shield"}, "potions": ["potion", 6],
		"must": ["slime", "wisp", "mummy", "shell"], "report": ["trex", "hand"], "boss_mul": {"trex": [2.22, 1.0], "hand": [0.565, 1.0]}},
	{"name": "iron", "world": "dark_1", "weapon": "azure_blade", "gear": {"helmet": "brass_helmet", "armor": "iron_armor", "shield": "iron_shield"}, "potions": ["potion", 6],
		"must": ["dark_slime", "mantis", "zombie", "trex"], "tough": ["ufo", "worm"], "report": ["hand"]},
	{"name": "gold", "world": "dark_2", "weapon": "kings_mace", "gear": {"helmet": "brass_helmet", "armor": "golden_knight_armor", "shield": "gold_shield", "ring_l": "gold_ring", "ring_r": "silver_ring"}, "potions": ["potion", 8],
		"must": ["dark_slime", "mantis", "zombie", "worm", "trex"], "tough": ["ufo"], "report": ["hand"]},
	{"name": "hell", "world": "hell_1", "weapon": "kings_mace", "gear": {"helmet": "fear_helmet", "armor": "chainmail", "shield": "gold_shield", "ring_l": "armor_ring", "ring_r": "gold_ring"}, "potions": ["potion", 10],
		"must": [], "report": ["mantis", "worm", "wizard", "shadow", "eyeball", "hand"]},
]

const TIMEOUT := 90.0

func _ready() -> void:
	run()

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails.append(what)

func run() -> void:
	await get_tree().create_timer(0.5).timeout
	var trials := int(OS.get_environment("FIGHT_TRIALS")) if OS.get_environment("FIGHT_TRIALS") != "" else 4
	var only := OS.get_environment("FIGHT_ONLY")
	GS.slot = GS.SLOTS - 1
	main.start_game(false, "man_in_suit", "Bot")
	for st in STAGES:
		if only != "" and not st.world in only.split(","):
			continue
		_kit(st)
		if st.must.size() > 0:
			check(GS.world_danger(st.world) <= 2, "the %s card doesn't say Deadly with %s gear" % [st.world, st.name])
		for mob in st.must + st.get("tough", []) + st.report:
			if OS.get_environment("FIGHT_MOB") != "" and mob != OS.get_environment("FIGHT_MOB"):
				continue
			var wins := 0
			var left := 0.0
			var secs := 0.0
			var pots := 0
			for t in trials:
				var r: Dictionary = await fight(st, mob)
				if r.win:
					wins += 1
					left += r.hp_left
				secs += r.time
				pots += r.potions
			_kit(st)
			var danger: String = ["Easy", "Fair", "Hard", "Deadly"][GS.world_danger(st.world)] # what the world card says with this gear
			danger += " (%.1f)" % GS.fight_score(st.world, _entry(st, mob), true)
			var line := "%-7s %-12s %-11s won %d/%d  hp left %3d%%  %4.1fs  potions %.1f  card: %s" % [st.name, st.world, mob, wins, trials, int(100 * left / maxf(1, wins)), secs / trials, float(pots) / trials, danger]
			rows.append(line)
			print("FIGHT ", line)
			if mob in st.get("tough", []):
				check(wins * 2 >= trials, "%s gear beats a %s in %s at least half the time (%d/%d)" % [st.name, Data.MOBS[mob].name, st.world, wins, trials])
			if mob in st.must:
				check(wins * 4 >= trials * 3, "%s gear beats a %s in %s (%d/%d)" % [st.name, Data.MOBS[mob].name, st.world, wins, trials])
	print("\n== FIGHT TABLE")
	for r in rows:
		print("  ", r)
	print("FIGHTTEST DONE, %d failures" % fails.size())
	for f in fails:
		print("  failed: ", f)
	GS.delete_slot(GS.slot)
	get_tree().quit(1 if fails.size() > 0 else 0)

## One fight: a fresh map, the stage's gear, one monster with the world's own numbers.
func fight(st: Dictionary, mob_id: String) -> Dictionary:
	main.hud.close_panels()
	main._load_level("grass_arena", false)
	var lvl: Node2D = main.level
	lvl.set_process(false) # no arena spawns or boss timer
	lvl.def = Data.WORLDS[st.world] # the world's health overrides and damage penalty
	for e in lvl.entities.get_children():
		if e is MobScript:
			e.queue_free()
	for n in lvl.props.get_children():
		n.queue_free() # the Leave portal would take the bot to town
	_kit(st)
	var p: CharacterBody2D = lvl.player
	p.position = lvl.cell_pos(Vector2i(lvl.W / 2 - 4, 17))
	p.invuln = 0.0
	p.facing = 1
	await get_tree().physics_frame
	# two at once, like you meet them: this monster in front and another of the
	# world's monsters coming from behind ("PACK=1" fights one at a time, "PACK=3"
	# adds a second one of this monster further off)
	var pack := [[mob_id, 60.0]]
	var n_pack := int(OS.get_environment("PACK")) if OS.get_environment("PACK") != "" else 2
	if n_pack >= 2 and not (st.has("boss_mul") and st.boss_mul.has(mob_id)):
		var pool: Array = st.must + st.get("tough", []) if st.must.size() > 0 else st.report
		pack.append([pool[randi() % pool.size()], -60.0])
		if n_pack >= 3:
			pack.append([mob_id, 120.0])
	var foes := []
	for e in pack:
		var mul := _mul(st, e[0])
		var m: Node = lvl.spawn_mob_at(e[0], p.position + Vector2(e[1], 0), mul.x, mul.y)
		m.aggro_forced = true
		m.arena_boss = st.has("boss_mul") and st.boss_mul.has(e[0]) # can't be pushed or dazed
		foes.append(m)
	var t := 0.0
	var used := 0
	var pot_slot := 1
	while t < TIMEOUT and not p.dead:
		foes = _alive(foes)
		if foes.is_empty():
			break
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		foes = _alive(foes)
		if foes.is_empty() or p.dead:
			break
		var m: Node = foes[0]
		for f in foes:
			if f.position.distance_to(p.position) < m.position.distance_to(p.position):
				m = f
		var d: Vector2 = m.position - p.position
		var reach: float = Data.ITEMS[st.weapon].get("reach", 14) + m.size.x * 0.5
		var want := 0
		if absf(d.x) > reach:
			want = 1 if d.x > 0 else -1
		elif signf(d.x) != p.facing and absf(d.x) > 2:
			want = 1 if d.x > 0 else -1 # turn around
		_press("move_right", want > 0)
		_press("move_left", want < 0)
		_press("attack", true)
		var above: bool = d.y < -18 and absf(d.x) < 40
		if above and p.is_on_floor():
			Input.action_press("jump")
		else:
			Input.action_release("jump")
		if GS.hp <= GS.max_hp() * 0.4 and GS.inv[pot_slot] != null and p.cooldown <= 0:
			GS.sel = pot_slot
			p.use_held(true)
			GS.sel = 0
			used += 1
	for a in ["move_right", "move_left", "attack", "jump"]:
		Input.action_release(a)
	foes = _alive(foes)
	var win: bool = not p.dead and foes.is_empty()
	var r := {"win": win, "hp_left": GS.hp / GS.max_hp(), "time": t, "potions": used}
	if p.dead:
		p.revive()
	for f in foes:
		f.queue_free()
	return r

func _alive(list: Array) -> Array:
	var out := []
	for f in list:
		if is_instance_valid(f) and not f.dead:
			out.append(f)
	return out

func _press(a: String, on: bool) -> void:
	if on and not Input.is_action_pressed(a):
		Input.action_press(a)
	elif not on and Input.is_action_pressed(a):
		Input.action_release(a)

## The health and damage multipliers the world spawns this monster with.
func _mul(st: Dictionary, mob_id: String) -> Vector2:
	if st.has("boss_mul") and st.boss_mul.has(mob_id):
		return Vector2(st.boss_mul[mob_id][0], st.boss_mul[mob_id][1])
	var w: Dictionary = Data.WORLDS[st.world]
	var mult: float = w.get("mult", 1.0) if w.kind == "explore" else 1.0
	for e in w.get("mobs", []):
		if e[0] == mob_id:
			return Vector2((float(e[2]) if e.size() > 2 else 1.0) * mult, (float(e[3]) if e.size() > 3 else 1.0) * mult)
	return Vector2(mult, mult)

## The world's spawn entry for this monster, as GS.fight_score reads it.
func _entry(st: Dictionary, mob_id: String) -> Array:
	if st.has("boss_mul") and st.boss_mul.has(mob_id):
		return [mob_id, 1.0, st.boss_mul[mob_id][0], st.boss_mul[mob_id][1]]
	for e in Data.WORLDS[st.world].get("mobs", []):
		if e[0] == mob_id:
			return e
	return [mob_id, 1.0]

func _kit(st: Dictionary) -> void:
	GS.status = {}
	for i in GS.inv.size():
		GS.inv[i] = null
	for s in GS.EQUIP_SLOTS:
		GS.equip[s] = ""
	for s in st.gear:
		GS.equip[s] = st.gear[s]
	GS.inv[0] = {"id": st.weapon, "n": 1}
	GS.inv[1] = {"id": st.potions[0], "n": st.potions[1]}
	GS.sel = 0
	GS.hp = GS.max_hp()
	GS.mp = GS.max_mp()
	GS.st = GS.max_st()
	GS.inventory_changed.emit()
	GS.stats_changed.emit()
