extends Node
## Plays a brand-new character through the goal list the way a player would, to
## see how the progression feels: how long each goal takes, how often new gear
## comes, the longest stretch with nothing new, and how often you faint.
## Each round it picks a world from the goal card, clears it (real fights with
## the real monster AI, real swings at trees, rocks and ores, real drops), then
## goes to town: hands in quests, combines, crafts upgrades, smelts and stores
## the rest with Banka. Walking between things is counted at walking speed
## instead of being played out, so real players will take a bit longer.
## Run headless and fast:
##   godot --headless --path . --fixed-fps 60 -- --journeytest
## Ends with "JOURNEYTEST DONE, N failures" and a timeline.
## JOURNEY_MINUTES=n is the most game time it may play (default 240).

var main: Node
const MobScript := preload("res://scripts/mob.gd")
const NodeScript := preload("res://scripts/res_node.gd")
const PickupScript := preload("res://scripts/pickup.gd")

const WALK := 82.0 # the player's walking speed
const CLIMB := 40.0 # up and down shafts and ledges is slower
const TRIP := 40.0 # back to the portal, the town errands and out to the next world
## Gear the bot makes at the Crafter when it's better than what it has, in order.
const CRAFTS := ["wooden_armor", "wooden_shield", "wooden_helmet", "short_blade", "copper_pick", "stone_armor",
	"copper_axe", "copper_helmet", "copper_armor", "iron_pick", "brass_helmet", "iron_armor"]

var clock := 0.0
var spent := {"fight": 0.0, "harvest": 0.0, "walk": 0.0, "town": 0.0}
var stash := {} # what Banka keeps
var jobs := [] # furnace jobs: [done at, bar]
var faints := 0
var bag_full := 0
var done := {} # goal index -> minutes
var events := [] # [minutes, what]: goals done and upgrades
var visits := [] # one line per world visit
var tries := {} # world -> visits that didn't reach its goal
var fails := []
var limit := 240.0 * 60.0

func _ready() -> void:
	run()

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails.append(what)

func mins() -> float:
	return clock / 60.0

func run() -> void:
	await get_tree().create_timer(0.5).timeout
	if OS.get_environment("JOURNEY_MINUTES") != "":
		limit = float(OS.get_environment("JOURNEY_MINUTES")) * 60.0
	GS.set_auto_hit(false)
	GS.slot = GS.SLOTS - 1
	main.start_game(false, "man_in_suit", "Bot")
	await get_tree().create_timer(0.3).timeout
	var last := "Enter Hell"
	while clock < limit and not _goal_is_done(last):
		var w := _pick_world()
		match Data.WORLDS[w].kind:
			"arena": await _arena(w)
			"survival": await _survival()
			_: await _clear(w)
		_errands()
	_report()

# ---------------------------------------------------------------- where to go
func _pick_world() -> String:
	var g := GS.current_goal()
	var text: String = g.get("text", "")
	var goal_worlds := {"Find the portal to Grasslands 2": "grass_2", "Reach Grasslands 3": "grass_3",
		"Clear the Grassland Arena": "grass_arena", "Survive 7 days in Survival Grasslands": "survival",
		"Explore the Darklands": "dark_1", "Reach Darklands 2": "dark_2", "Clear the Darklands Arena": "dark_arena", "Enter Hell": "hell_1"}
	if goal_worlds.has(text):
		var w: String = goal_worlds[text]
		# after two failed tries, get stronger first
		if tries.get(w, 0) < 2:
			return w
	# farm the furthest Grasslands the gear handles, but Jellies come fastest in the first
	var best := "grass_1"
	if not text.contains("Jell"):
		for w in ["grass_2", "grass_3"]:
			if GS.flags.get("been_" + w, false) and GS.world_danger(w) <= 1:
				best = w
	return best

func _goal_is_done(text: String) -> bool:
	for g in Data.GOALS:
		if g.text == text:
			return GS.goal_done(g)
	return false

## Notes goals as they're done.
func _note() -> void:
	for i in Data.GOALS.size():
		if not done.has(i) and GS.goal_done(Data.GOALS[i]):
			done[i] = mins()
			events.append([mins(), "GOAL %d: %s" % [i + 1, Data.GOALS[i].text]])
			print("  %5.1f min  goal %d done: %s" % [mins(), i + 1, Data.GOALS[i].text])

# ---------------------------------------------------------------- a world
func _enter(w: String) -> Node:
	main.hud.close_panels()
	main.change_level(w)
	await get_tree().physics_frame
	var lvl: Node = main.level
	lvl.player.invuln = 0.0
	return lvl

func _clear(w: String) -> void:
	var lvl: Node = await _enter(w)
	var p: CharacterBody2D = lvl.player
	var start := clock
	var kills := 0
	var broke := 0
	var fainted := false
	var skip := {}
	var had := _totals()
	var mobs0 := _alive_mobs(lvl)
	while clock < limit:
		var t: Node = _next_target(lvl, p, skip)
		if t == null:
			break
		_walk(p.position, t.position)
		_stand_by(lvl, p, t)
		if t is MobScript:
			var won: bool = await _fight(lvl, p, t, 45.0)
			if not won and not p.dead:
				skip[t] = true
		else:
			var ok: bool = await _harvest(lvl, p, t)
			if ok:
				broke += 1
			else:
				skip[t] = true
		if p.dead:
			fainted = true
			var near := []
			for e in lvl.entities.get_children():
				if e is MobScript and not e.dead and e.position.distance_to(p.position) < 140:
					near.append(e.id)
			print("  FAINT in %s at %.1f min, around: %s" % [w, mins(), near])
			break
		await _pick_up(lvl, p)
		if _bag_is_full():
			bag_full += 1
			break
	kills = mobs0 - _alive_mobs(lvl)
	var skipped := skip.keys().filter(func(k): return is_instance_valid(k) and k is MobScript).size()
	if skipped > 0:
		print("  skipped %d monsters it couldn't get at" % skipped)
	_note()
	if fainted:
		faints += 1
		main.respawn()
		await get_tree().physics_frame
	tries[w] = tries.get(w, 0) + 1
	_log_visit(w, start, kills, broke, fainted, had)

func _alive_mobs(lvl: Node) -> int:
	var n := 0
	for e in lvl.entities.get_children():
		if e is MobScript and not e.dead and not e.def.get("invulnerable", false):
			n += 1
	return n

func _next_target(lvl: Node, p: Node2D, skip: Dictionary) -> Node:
	var best: Node = null
	var best_cost := INF
	for e in lvl.entities.get_children():
		if e is MobScript and not e.dead and not skip.has(e) and not e.def.get("invulnerable", false):
			if float(e.max_hp) > 2000:
				continue # a mini-boss like the Hand: walk away
			var c := _cost(p.position, e.position)
			if c < best_cost:
				best_cost = c
				best = e
	for n in lvl.props.get_children():
		if n is NodeScript and n.alive and not skip.has(n) and n.def.tool in ["axe", "pick"]:
			if Data.hits_needed(n.kind, GS.best_tier(n.def.tool)) < 0:
				continue
			var c := _cost(p.position, n.position)
			if c < best_cost:
				best_cost = c
				best = n
	return best

func _cost(a: Vector2, b: Vector2) -> float:
	return absf(a.x - b.x) / WALK + absf(a.y - b.y) / CLIMB

## Walking somewhere: counted, not played. Health comes back while you walk,
## as it does in the game (1 every 12 seconds).
func _walk(a: Vector2, b: Vector2) -> void:
	var s := _cost(a, b)
	_pass(s, "walk")

func _pass(s: float, what: String) -> void:
	clock += s
	spent[what] += s
	GS.hp = minf(GS.max_hp(), GS.hp + s / 12.0)
	GS.st = GS.max_st()
	GS.stats_changed.emit()

## Puts the player on the ground just beside a target, on its open side.
func _stand_by(lvl: Node, p: CharacterBody2D, t: Node2D) -> void:
	var y: float = t.position.y
	for side in [-1, 1]:
		var x: float = t.position.x + side * 12.0
		var cx := int(x / 16.0)
		var cy := int((y - 4) / 16.0)
		if not lvl.solid(cx, cy) and not lvl.solid(cx, cy - 1):
			p.position = Vector2(x, lvl.floor_y(x, y - 8))
			p.facing = -side
			p.velocity = Vector2.ZERO
			return
	p.position = Vector2(t.position.x, lvl.floor_y(t.position.x, y - 8))
	p.velocity = Vector2.ZERO

# ---------------------------------------------------------------- fighting
func _best(kind: String) -> int:
	var best := -1
	var power := -1.0
	for i in GS.inv.size():
		var s = GS.inv[i]
		if s == null:
			continue
		var it: Dictionary = Data.ITEMS[s.id]
		if it.get("type", "") != kind:
			continue
		var v := float(it.get("dmg", 0)) if kind == "weapon" else float(it.get("tier", 0))
		if v > power:
			power = v
			best = i
	return best

## Fights until the target is beaten (or, with no target, until nothing is
## near), using the real controls: walk up, hold A, jump at flyers above, and
## eat or drink something when health drops under 40%.
func _fight(lvl: Node, p: CharacterBody2D, target: Node, max_t: float) -> bool:
	var w := _best("weapon")
	if w >= 0:
		GS.sel = w
	var t := 0.0
	var last_hp := -1.0
	var stuck := 0.0
	while t < max_t and not p.dead:
		if is_instance_valid(target) and target.dead:
			break
		# a target you can't get at (up on a ledge, behind a wall): give up on it
		if target != null and is_instance_valid(target):
			if target.hp != last_hp:
				last_hp = target.hp
				stuck = 0.0
			elif stuck > 8.0:
				break
			stuck += get_physics_process_delta_time()
		var foes := []
		for e in lvl.entities.get_children():
			if e is MobScript and not e.dead and not e.def.get("invulnerable", false) and e.position.distance_to(p.position) < 160:
				foes.append(e)
		if foes.is_empty() and (target == null or not is_instance_valid(target)):
			break
		var m: Node = target if target != null and is_instance_valid(target) and not target.dead else null
		for f in foes:
			if m == null or f.position.distance_to(p.position) < m.position.distance_to(p.position) - 24:
				m = f
		if m == null:
			break
		var d: Vector2 = m.position - p.position
		var reach: float = Data.ITEMS[GS.held()].get("reach", 14) + m.size.x * 0.5 if GS.held() != "" else 14.0
		var want := 0
		if absf(d.x) > reach:
			want = 1 if d.x > 0 else -1
		elif signf(d.x) != p.facing and absf(d.x) > 2:
			want = 1 if d.x > 0 else -1
		_press("move_right", want > 0)
		_press("move_left", want < 0)
		_press("attack", true)
		var above: bool = d.y < -18 and absf(d.x) < 40
		if above and p.is_on_floor():
			Input.action_press("jump")
		else:
			Input.action_release("jump")
		_heal_if_low(p, w)
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time()
		t += dt
		clock += dt
		spent.fight += dt
		if main.hud.any_open():
			main.hud.close_panels() # A near a villager opens their chat
	_release()
	return target == null or (is_instance_valid(target) and target.dead) or not is_instance_valid(target)

func _heal_if_low(p: Node, weapon: int) -> void:
	if GS.hp > GS.max_hp() * 0.4 or p.cooldown > 0:
		return
	for i in GS.inv.size():
		var s = GS.inv[i]
		if s and Data.ITEMS[s.id].get("heal", 0) > 0:
			GS.sel = i
			p.use_held(true)
			GS.sel = maxi(weapon, 0)
			return

func _press(a: String, on: bool) -> void:
	if on and not Input.is_action_pressed(a):
		Input.action_press(a)
	elif not on and Input.is_action_pressed(a):
		Input.action_release(a)

func _release() -> void:
	for a in ["move_right", "move_left", "attack", "jump"]:
		Input.action_release(a)

# ---------------------------------------------------------------- harvesting
func _harvest(lvl: Node, p: CharacterBody2D, n: Node) -> bool:
	var tool := _best(n.def.tool)
	if tool < 0:
		return false
	GS.sel = tool
	var t := 0.0
	var ignore := {}
	while n.alive and t < 25.0 and not p.dead:
		# a monster that comes over gets dealt with first (once: one it can't
		# get at is left alone)
		for e in lvl.entities.get_children():
			if e is MobScript and not e.dead and not ignore.has(e) and not e.def.get("invulnerable", false) and e.position.distance_to(p.position) < 40:
				ignore[e] = true
				var c0 := clock
				await _fight(lvl, p, e, 20.0)
				t += clock - c0
				_stand_by(lvl, p, n)
				GS.sel = tool
				break
		p.facing = 1 if n.position.x > p.position.x else -1
		_press("attack", true)
		await get_tree().physics_frame
		var dt := get_physics_process_delta_time()
		t += dt
		clock += dt
		spent.harvest += dt
		if main.hud.any_open():
			main.hud.close_panels()
	_release()
	return not n.alive

func _pick_up(lvl: Node, p: CharacterBody2D) -> void:
	for k in 40:
		await get_tree().physics_frame
	clock += 40.0 / 60.0
	for e in lvl.entities.get_children():
		if is_instance_valid(e) and e is PickupScript and e.position.distance_to(p.position) < 120:
			p.position = e.position
			for k in 12:
				await get_tree().physics_frame
			clock += 0.2

func _bag_is_full() -> bool:
	for s in GS.inv:
		if s == null:
			return false
	return true

# ---------------------------------------------------------------- arenas and Survival
func _arena(w: String) -> void:
	var lvl: Node = await _enter(w)
	var p: CharacterBody2D = lvl.player
	var start := clock
	var had := _totals()
	while not lvl.arena_done and not p.dead and clock - start < 480.0:
		await _hunt(lvl, p)
		await _pick_up(lvl, p)
	_note()
	var fainted: bool = p.dead
	if fainted:
		faints += 1
		main.respawn()
		await get_tree().physics_frame
	else:
		main.change_level("town")
	tries[w] = tries.get(w, 0) + (0 if lvl.arena_done else 1)
	_log_visit(w, start, 0, 0, fainted, had)

func _survival() -> void:
	var lvl: Node = await _enter("survival")
	var p: CharacterBody2D = lvl.player
	var start := clock
	var had := _totals()
	while GS.best_survival_day < 7 and not p.dead and clock - start < 40 * 60:
		await _hunt(lvl, p)
	_note()
	var fainted: bool = p.dead
	if fainted:
		faints += 1
		main.respawn()
		await get_tree().physics_frame
	else:
		main.change_level("town")
	tries["survival"] = tries.get("survival", 0) + (0 if GS.best_survival_day >= 7 else 1)
	_log_visit("survival", start, 0, 0, fainted, had)

## Goes to the nearest monster, wherever it is, and fights it; with none
## about, waits a moment.
func _hunt(lvl: Node, p: CharacterBody2D) -> void:
	var m: Node = null
	for e in lvl.entities.get_children():
		if e is MobScript and not e.dead and not e.def.get("invulnerable", false):
			if m == null or e.position.distance_to(p.position) < m.position.distance_to(p.position):
				m = e
	if m == null:
		for k in 30:
			await get_tree().physics_frame
		clock += 0.5
		return
	if m.position.distance_to(p.position) > 60:
		_walk(p.position, m.position)
		_stand_by(lvl, p, m)
	await _fight(lvl, p, m, 20.0)

# ---------------------------------------------------------------- town
func have(id: String) -> int:
	return GS.count(id) + int(stash.get(id, 0))

## Moves what a recipe needs from Banka into the bag.
func _to_bag(need: Dictionary) -> void:
	for id in need:
		var missing := int(need[id]) - GS.count(id)
		var n := mini(missing, int(stash.get(id, 0)))
		if n > 0:
			stash[id] -= n
			GS.add_item(id, n, true)

func _keep(id: String) -> bool:
	var it: Dictionary = Data.ITEMS[id]
	return it.get("type", "") in ["weapon", "axe", "pick", "book"] or it.get("heal", 0) > 0 or id.contains("book")

func _store() -> void:
	for i in GS.inv.size():
		var s = GS.inv[i]
		if s and not _keep(s.id):
			stash[s.id] = int(stash.get(s.id, 0)) + int(s.n)
			GS.inv[i] = null
	GS.inventory_changed.emit()

## What the next quests need, so crafting doesn't spend it.
func _reserved(id: String) -> int:
	var r := 0
	for npc in ["mira", "gruff", "warden"]:
		var q := GS.next_quest(npc)
		if not q.is_empty() and q.need.has(id):
			r += int(q.need[id])
	return r

func _errands() -> void:
	_pass(TRIP, "town")
	_store()
	# furnaces
	var left := []
	for j in jobs:
		if clock >= j[0]:
			stash[j[1]] = int(stash.get(j[1], 0)) + 1
		else:
			left.append(j)
	jobs = left
	# quests, then what they need made
	for k in 2:
		for npc in ["mira", "gruff", "warden"]:
			var q := GS.next_quest(npc)
			if q.is_empty() or q.id.begins_with("bounty"):
				continue
			var ok := true
			for id in q.need:
				if have(id) < int(q.need[id]):
					ok = false
			if ok:
				_to_bag(q.need)
				GS.complete_quest(q)
				_store()
				_note()
		if not "gruff_1" in GS.quests_done:
			_combine("wood", "rock", "wood_wall", 1)
		if not "warden_1" in GS.quests_done and have("combo_book_1") > 0:
			_combine("honey_bug", "herb", "pretzel", 1)
	# boards for a helmet, potions to carry
	if GS.equip.helmet == "" and have("survival_book") > 0:
		_combine("wood", "branch", "wood_board", 25)
	if have("combo_book_1") > 0:
		_combine("herb", "plant_roots", "potion", 6)
	_craft()
	_smelt()
	_store()
	_note()

func _combine(a: String, b: String, out: String, want: int) -> void:
	var guard := 0
	while have(out) < want and have(a) - _reserved(a) > 0 and have(b) - _reserved(b) > 0 and guard < 200:
		guard += 1
		_to_bag({a: 1, b: 1})
		var ia := -1
		var ib := -1
		for i in GS.inv.size():
			if GS.inv[i] and GS.inv[i].id == a and ia < 0:
				ia = i
			elif GS.inv[i] and GS.inv[i].id == b and ib < 0:
				ib = i
		if ia < 0 or ib < 0:
			return
		GS.combine([ia, ib], false)
	_pass(2.0, "town")

func _power(id: String) -> float:
	var it: Dictionary = Data.ITEMS[id]
	if it.get("type", "") == "weapon":
		return float(it.get("dmg", 0))
	if it.get("type", "") in ["axe", "pick"]:
		return float(it.get("tier", 0))
	var s: Dictionary = it.get("stats", {})
	return float(s.get("def", 0)) * 2.0 + float(s.get("hp", 0)) * 0.5 + float(s.get("atk", 0)) * 2.0

func _current(id: String) -> float:
	var it: Dictionary = Data.ITEMS[id]
	var type: String = it.get("type", "")
	if type in ["weapon", "axe", "pick"]:
		var b := _best(type)
		return _power(GS.inv[b].id) if b >= 0 else 0.0
	var slot := GS.equip_slot_for(id)
	return _power(GS.equip[slot]) if slot != "" and GS.equip[slot] != "" else 0.0

func _craft() -> void:
	for out in CRAFTS:
		if _power(out) <= _current(out):
			continue
		var r: Dictionary = {}
		for s in Data.SMITH:
			if s.out == out:
				r = s
		var ok := true
		for id in r.cost:
			var mine := have(id) + (1 if GS.equip.values().has(id) else 0)
			if mine - _reserved(id) < int(r.cost[id]):
				ok = false
		if not ok:
			continue
		for id in r.cost:
			for slot in GS.equip:
				if GS.equip[slot] == id and GS.count(id) == 0 and have(id) == 0:
					GS.unequip(slot)
		_to_bag(r.cost)
		if GS.smith(r):
			for i in GS.inv.size():
				if GS.inv[i] and GS.inv[i].id == out and GS.equip_slot_for(out) != "":
					GS.equip_from(i)
					break
			events.append([mins(), "made %s" % Data.ITEMS[out].name])
			print("  %5.1f min  made %s" % [mins(), Data.ITEMS[out].name])
			_pass(3.0, "town")
	_note()

func _smelt() -> void:
	if not GS.flags.get("furnaces", false):
		return
	for bar in ["iron_bar", "gold_bar", "copper_bar"]:
		var r: Dictionary = Data.SMELT.filter(func(s): return s.out == bar)[0]
		while jobs.size() < Data.FURNACES:
			var ok := true
			for id in r.cost:
				if have(id) < int(r.cost[id]):
					ok = false
			if not ok:
				break
			for id in r.cost:
				var n := int(r.cost[id])
				var from_stash := mini(n, int(stash.get(id, 0)))
				stash[id] = int(stash.get(id, 0)) - from_stash
				if n - from_stash > 0:
					GS.remove_item(id, n - from_stash)
			jobs.append([clock + float(r.time), r.out])

# ---------------------------------------------------------------- reporting
func _totals() -> Dictionary:
	var t := stash.duplicate()
	for s in GS.inv:
		if s:
			t[s.id] = int(t.get(s.id, 0)) + int(s.n)
	return t

func _log_visit(w: String, start: float, kills: int, broke: int, fainted: bool, had: Dictionary) -> void:
	var now := _totals()
	var got := []
	for id in ["jelly", "wood", "rock", "copper_ore", "iron_ore", "coal", "honey_bug", "herb", "scarab"]:
		var d := int(now.get(id, 0)) - int(had.get(id, 0))
		if d > 0:
			got.append("%s %d" % [id, d])
	var line := "%5.1f min  %-12s %4.1f min  kills %2d  nodes %2d%s  | %s" % [mins(), w, (clock - start) / 60.0, kills, broke, "  FAINTED" if fainted else "", ", ".join(got)]
	visits.append(line)
	print("VISIT ", line)

func _report() -> void:
	print("\n== TIMELINE (game minutes)")
	for e in events:
		print("  %6.1f  %s" % [e[0], e[1]])
	print("\n== TIME SPENT: fighting %.0f min, harvesting %.0f min, walking %.0f min, town %.0f min; faints %d; bag full %d times" % [
		spent.fight / 60.0, spent.harvest / 60.0, spent.walk / 60.0, spent.town / 60.0, faints, bag_full])
	# the longest stretch with no goal done and nothing new made
	var gap := 0.0
	var gap_at := ""
	var prev := 0.0
	for e in events:
		if e[0] - prev > gap:
			gap = e[0] - prev
			gap_at = e[1]
		prev = e[0]
	print("== LONGEST STRETCH WITH NOTHING NEW: %.1f min, before \"%s\"" % [gap, gap_at])
	var grass_last := -1
	for i in Data.GOALS.size():
		if Data.GOALS[i].text == "Clear the Grassland Arena":
			grass_last = i
	for i in grass_last + 1:
		check(done.has(i), "goal %d (%s) is reached" % [i + 1, Data.GOALS[i].text])
	print("JOURNEYTEST DONE, %d failures" % fails.size())
	GS.delete_slot(GS.slot)
	get_tree().quit(1 if fails.size() > 0 else 0)
