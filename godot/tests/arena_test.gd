extends "res://tests/fight_test.gd"
## Plays the real Grasslands Arena boss fight in single player with low-level
## gear: the real arena (its last monsters before the boss, then the boss),
## the real free revive, potions when low, jumping the Jelly King's slam waves.
## Each kit fights each of the three bosses (Rexy, Hand, Jelly King). A win is
## the boss down. Run headless and fast:
##   godot --headless --path . --fixed-fps 60 -- --arenatest
## ARENA_TRIALS=n sets the tries per kit and boss, ARENA_KITS=fresh,wood picks
## kits, ARENA_BOSSES=jelly_king picks bosses.
## Ends with "ARENATEST DONE, N failures". Wood, stone and copper gear must win
## 3 times in 4; the bare starter kit (no armor) is only printed.

## Kits a low-level player has by the time they try the arena (see fight_test.gd).
const KITS := [
	{"name": "fresh", "world": "grass_arena", "weapon": "plunger", "gear": {}, "potions": ["small_potion", 3], "must": [], "report": [], "need": 0.0},
	{"name": "wood", "world": "grass_arena", "weapon": "short_blade", "gear": {"helmet": "wooden_helmet", "armor": "wooden_armor", "shield": "wooden_shield"}, "potions": ["small_potion", 5], "must": [], "report": [], "need": 0.75},
	{"name": "stone", "world": "grass_arena", "weapon": "gilded_blade", "gear": {"helmet": "wooden_helmet", "armor": "stone_armor", "shield": "wooden_shield"}, "potions": ["small_potion", 6], "must": [], "report": [], "need": 0.75},
	{"name": "copper", "world": "grass_arena", "weapon": "gilded_blade", "gear": {"helmet": "copper_helmet", "armor": "copper_armor", "shield": "copper_shield"}, "potions": ["small_potion", 8], "must": [], "report": [], "need": 0.75},
]
const ARENA_TIMEOUT := 300.0
const SlamWaveScript := preload("res://scripts/slam_wave.gd")

func run() -> void:
	await get_tree().create_timer(0.5).timeout
	var trials := int(OS.get_environment("ARENA_TRIALS")) if OS.get_environment("ARENA_TRIALS") != "" else 8
	var only := OS.get_environment("ARENA_KITS")
	var pick := OS.get_environment("ARENA_BOSSES")
	GS.slot = GS.SLOTS - 1
	main.start_game(false, "man_in_suit", "Bot")
	for kit in KITS:
		if only != "" and not kit.name in only.split(","):
			continue
		for boss in Data.WORLDS.grass_arena.bosses:
			if pick == "" or boss[0] in pick.split(","):
				await _kit_vs(kit, boss, trials)
	print("\n== ARENA TABLE")
	for r in rows:
		print("  ", r)
	print("ARENATEST DONE, %d failures" % fails.size())
	for f in fails:
		print("  failed: ", f)
	GS.delete_slot(GS.slot)
	get_tree().quit(1 if fails.size() > 0 else 0)

func _kit_vs(kit: Dictionary, boss: Array, trials: int) -> void:
	var wins := 0
	var revives := 0
	var secs := 0.0
	var pots := 0
	var boss_hp := 0.0
	for t in trials:
		var r: Dictionary = await arena_run(kit, boss)
		if r.win:
			wins += 1
			secs += r.time
		revives += r.revived
		pots += r.potions
		boss_hp += r.boss_left
	var line := "%-7s vs %-10s won %d/%d  avg win time %5.1fs  used the free revive %d/%d  potions %.1f  boss health left when lost %d%%" % [kit.name, boss[0], wins, trials,
		secs / maxf(1, wins), revives, trials, float(pots) / trials, int(100 * boss_hp / maxf(1, trials - wins))]
	rows.append(line)
	print("ARENA ", line)
	check(wins >= ceili(trials * kit.need), "%s gear beats the Grasslands Arena's %s (%d/%d, needs %d%%)" % [kit.name, Data.MOBS[boss[0]].name, wins, trials, int(kit.need * 100)])

## One arena: the last 15 seconds before the boss, then the boss, single player.
func arena_run(kit: Dictionary, boss: Array) -> Dictionary:
	main.hud.close_panels()
	_kit(kit)
	main._load_level("grass_arena", false)
	var lvl: Node2D = main.level
	for n in lvl.props.get_children():
		n.queue_free() # the Leave portal would take the bot to town
	lvl.arena_time = Data.ARENA_BOSS_TIME - 15.0
	lvl.def = lvl.def.duplicate()
	lvl.def.bosses = [boss] # this boss this time
	_kit(kit)
	var p: CharacterBody2D = lvl.player
	var t := 0.0
	var used := 0
	var revived := 0
	var pot_slot := 1
	var was_dead := false
	while t < ARENA_TIMEOUT and not lvl.arena_done:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if not is_instance_valid(p) or main.level != lvl:
			break
		if p.dead:
			for a in ["move_right", "move_left", "attack", "jump"]:
				_press(a, false)
			if not was_dead:
				was_dead = true
			if main.hud.panels.dead.visible:
				break # out of revives
			continue
		if was_dead:
			was_dead = false
			revived += 1
		var foes := []
		for e in lvl.entities.get_children():
			if e is MobScript and not e.dead and not e.def.get("invulnerable", false):
				foes.append(e)
		if foes.is_empty():
			_press("move_right", false)
			_press("move_left", false)
			continue
		var m: Node = foes[0]
		for f in foes:
			if f.position.distance_to(p.position) < m.position.distance_to(p.position):
				m = f
		var d: Vector2 = m.position - p.position
		var reach: float = Data.ITEMS[kit.weapon].get("reach", 14) + m.size.x * 0.5
		var want := 0
		if absf(d.x) > reach:
			want = 1 if d.x > 0 else -1
		elif signf(d.x) != p.facing and absf(d.x) > 2:
			want = 1 if d.x > 0 else -1
		if d.y < -30:
			# up on a ledge or on your head: back off so it comes down, like a player would
			want = -1 if p.position.x > lvl.W * 8 else 1
		_press("move_right", want > 0)
		_press("move_left", want < 0)
		_press("attack", true)
		var above: bool = d.y < -18 and absf(d.x) < 40
		# a slam wave rolling at you: jump it
		var wave := false
		for e in lvl.entities.get_children():
			if e.get_script() == SlamWaveScript and absf(e.position.x - p.position.x) < 34 and signf(p.position.x - e.position.x) == e.dir and absf(e.position.y - p.position.y) < 12:
				wave = true
		if (above or wave) and p.is_on_floor():
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
	var left := 0.0
	var full := 0.0
	for e in lvl.entities.get_children():
		if e is MobScript and e.arena_boss:
			full += e.max_hp
			if not e.dead:
				left += e.hp
	var win: bool = lvl.arena_done and is_instance_valid(p) and not p.dead
	if not win and is_instance_valid(p) and not p.dead:
		var where := []
		for e in lvl.entities.get_children():
			if e is MobScript and not e.dead:
				where.append("%s hp %d at %s" % [e.id, e.hp, (e.position - p.position).round()])
		print("  timed out with the bot at %s: %s" % [p.position.round(), where])
	main.hud.close_panels()
	if is_instance_valid(p) and p.dead:
		p.revive()
	return {"win": win, "time": t, "potions": used, "revived": revived, "boss_left": left / maxf(1, full)}
