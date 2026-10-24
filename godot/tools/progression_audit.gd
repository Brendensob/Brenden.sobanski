extends SceneTree
## Plays the game's progression on paper, with the real gates: tool tiers for
## each resource, the furnace gate (Pretzel quest), Survival access (Brutus),
## the rock wall (Gold Pickaxe) in front of the soils, the Torch wall in front
## of the Trading Center, the Wall Hammer wall in front of the basement,
## recipes that need their book or a scroll, and the stamina the Tomb (8) and
## Snow Valley (12) ask for. Monsters are assumed beatable.
## It prints the step at which each milestone opens, and every item that can
## only be got by skipping a gate (a softlock). Run from the godot folder:
##   godot --headless --path . -s tools/progression_audit.gd
## Exits with 1 if anything is softlocked.

var D
var have := {} # item -> first step
var flags := {} # flag -> first step
var step := 0
var how := {} # item -> how it first came
var pending := {} # what this round found, added when the round ends
var pending_flags := {}

const GS_BASE_ST := 4

func _initialize() -> void:
	D = load("res://scripts/data.gd").new()
	D._build_mobs()
	for id in ["sword_cast", "wooden_axe", "wooden_pick", "small_potion", "dust", "coin", "fist", "man_in_suit", "nurse"]:
		_add(id, "start")
	var changed := true
	while changed:
		step += 1
		pending = {}
		pending_flags = {}
		_round()
		changed = not pending.is_empty() or not pending_flags.is_empty()
		for id in pending:
			have[id] = step
			how[id] = pending[id]
		for f in pending_flags:
			flags[f] = step
	_report()

func _add(id: String, why: String) -> bool:
	if have.has(id) or pending.has(id):
		return false
	if step == 0:
		have[id] = 0
		how[id] = why
	else:
		pending[id] = why
	return true

func _flag(f: String) -> bool:
	if flags.has(f) or pending_flags.has(f):
		return false
	pending_flags[f] = true
	return true

func _has(id: String) -> bool:
	return id == "coin" or have.has(id)

func _tier(kind: String) -> int:
	var best := 0
	for id in have:
		if not D.ITEMS.has(id):
			continue
		var it: Dictionary = D.ITEMS[id]
		if it.type == kind:
			best = maxi(best, int(it.get("tier", 0)))
		if it.has(kind):
			best = maxi(best, int(it[kind]))
	return best

## The most stamina the gear you can get adds up to.
func _max_st() -> int:
	var best := {"helmet": 0, "armor": 0, "shield": 0, "pet": 0}
	var rings := []
	var char_st := 0
	for id in have:
		if not D.ITEMS.has(id):
			continue
		var it: Dictionary = D.ITEMS[id]
		var st := int(it.get("stats", {}).get("st", 0))
		if it.type == "ring":
			rings.append(st)
		elif best.has(it.type):
			best[it.type] = maxi(best[it.type], st)
		if it.type == "character":
			char_st = maxi(char_st, int(D.CHARACTERS.get(id, {}).get("stats", {}).get("st", 0)))
	rings.sort()
	rings.reverse()
	var total := GS_BASE_ST + char_st
	for k in best:
		total += best[k]
	for i in mini(2, rings.size()):
		total += rings[i]
	return total

func _world_open(w: String) -> bool:
	var d: Dictionary = D.WORLDS[w]
	if d.has("needs") and not flags.has(d.needs):
		return false
	return _max_st() >= int(d.get("min_st", 0))

func _round() -> bool:
	var c := false
	var axe := _tier("axe")
	var pick := _tier("pick")
	# worlds: their resources (with the right tool), monsters, chests
	var mobs := {}
	for w in D.WORLDS:
		if not _world_open(w):
			continue
		var wd: Dictionary = D.WORLDS[w]
		for e in wd.get("nodes", []):
			var n: Dictionary = D.NODES[e[0]]
			if (n.tool == "axe" and axe >= int(n.min)) or (n.tool == "pick" and pick >= int(n.min)):
				for d in n.get("drops", []):
					c = _add(d[0], "resource %s in %s" % [e[0], w]) or c
		for e in wd.get("mobs", []) + wd.get("bosses", []):
			mobs[e[0]] = w
		for key in ["boss_drops", "mob_drops"]:
			for d in wd.get(key, []):
				c = _add(d[0], "%s in %s" % [key, w]) or c
		if wd.get("chest", false):
			for e in D.CHESTS.silver.loot:
				c = _add(e[0], "reward chest in " + w) or c
	# the town's own trees and stones (around Pixel Town and the Survival corridor)
	for n in ["tree", "stone", "copper", "plant_yellow", "plant_pink", "pot"]:
		var nd: Dictionary = D.NODES[n]
		if (nd.tool == "axe" and axe >= int(nd.min)) or (nd.tool == "pick" and pick >= int(nd.min)):
			for d in nd.get("drops", []):
				c = _add(d[0], "resource " + n) or c
	if flags.has("survival_access"):
		for wave in D.SURVIVAL_WAVES:
			for m in wave[1]:
				mobs[m] = "survival"
		for m in D.SURVIVAL_BOSSES:
			mobs[m] = "survival"
		c = _add("survival_token", "Survival Grasslands") or c
		c = _add("silver_key", "dying on day 7 of Survival") or c
		c = _add("golden_key", "dying on day 19 of Survival") or c
		c = _add("master_key", "dying on day 45 of Survival") or c
		c = _add("wall_hammer", "surviving night %d" % D.WALL_HAMMER_DAY) or c
	for m in mobs:
		for d in D.MOBS[m].drops:
			c = _add(d[0], "monster %s (%s)" % [m, mobs[m]]) or c
	# town walls
	if pick >= int(D.NODES.rock_wall.min):
		c = _flag("rock_wall") or c
	if _has("torch_weapon"):
		c = _flag("trade_wall") or c
	if _has("wall_hammer"):
		c = _flag("hammer_wall") or c
	# quests (the basement villagers need the hammer wall open; Hell 2's GateKeeper is in Hell 2)
	for q in D.QUESTS:
		if q.npc in ["nini", "nana", "nina", "fc_9912", "tt_1001", "oop_2219"] and not flags.has("hammer_wall"):
			continue
		if q.npc == "warden_hell" and not _world_open("hell_2"):
			continue
		if q.need.keys().all(func(k): return _has(k)):
			for k in q.reward:
				c = _add(k, "quest " + q.id) or c
			if q.has("unlock"):
				c = _flag(q.unlock) or c
	# shops
	for s in D.SHOPS:
		var shop: Dictionary = D.SHOPS[s]
		if shop.has("needs") and not flags.has(shop.needs):
			continue
		if shop.get("currency", "coin") != "coin" and not _has(shop.currency):
			continue
		for e in shop.sells:
			c = _add(e[0], "shop " + s) or c
	if _has("gem"):
		for e in D.gem_shop().sells:
			c = _add(e[0], "Gem Shop") or c
	# chests, seeds (the soils are behind the rock wall), eggs, the Crafter, combining, furnaces
	for k in D.CHESTS:
		if _has(D.CHESTS[k].key):
			for e in D.CHESTS[k].loot:
				c = _add(e[0], k + " chest") or c
	if flags.has("rock_wall"):
		for sd in D.SEED_LOOT:
			if _has(sd):
				for e in D.SEED_LOOT[sd]:
					c = _add(e[0], sd + " harvest") or c
	for egg in D.EGG_PETS:
		if _has(egg):
			for p in D.EGG_PETS[egg]:
				c = _add(p, "hatching " + egg) or c
	for s in D.SMITH:
		if s.cost.keys().all(func(k): return _has(k)):
			c = _add(s.out, "Crafter") or c
	for r in D.RECIPES:
		if not r["in"].all(func(k): return _has(k)):
			continue
		var rate := int(r.rate)
		var book: String = D.BOOK_ITEM.get(r.get("book", ""), "")
		var ok := rate > 0
		if not ok and book != "" and _has(book):
			ok = rate + D.BOOK_BONUS > 0 or (rate + D.BOOK_BONUS + D.SCROLL_BONUS > 0 and _has("combination_scroll"))
		if ok:
			c = _add(r.out, "combining") or c
	if flags.has("furnaces"):
		for s in D.SMELT:
			if s.cost.keys().all(func(k): return _has(k)):
				c = _add(s.out, "furnace") or c
	for ch in D.CHARACTERS:
		if _has(ch) and D.CHARACTERS[ch].has("gives"):
			c = _add(D.CHARACTERS[ch].gives, "character " + ch) or c
	return c

func _report() -> void:
	print("== PROGRESSION (steps are rounds of 'what can you get with what you have')")
	for f in ["survival_access", "furnaces", "rock_wall", "trade_wall", "hammer_wall", "em_shop"]:
		print("  %-16s step %s" % [f, str(flags.get(f, "NEVER"))])
	for id in ["copper_bar", "copper_pick", "iron_ore", "iron_bar", "iron_pick", "gold_ore", "gold_pick", "erbium", "volcanic_ore", "sandnite_ore", "combo_book_1", "combo_book_2", "torch_weapon", "wall_hammer", "silver_key", "golden_key", "master_key", "gem", "hell_armor", "nightmare_ingot", "forbidden_bar", "tsurugi_4", "iron_fist_4", "moonclipse_5", "twin_sun_u"]:
		print("  %-16s step %-5s via %s" % [id, str(have.get(id, "NEVER")), how.get(id, "-")])
	for w in ["tomb_of_makara", "snow_valley"]:
		print("  %-16s %s (best stamina %d, needs %d)" % [w, "open" if _world_open(w) else "LOCKED", _max_st(), int(D.WORLDS[w].get("min_st", 0))])
	var locked := []
	for id in D.ITEMS:
		if not have.has(id) and not id in ["blood_long_sword", "stone_wall", "torch"]:
			locked.append(id)
	print("\n== SOFTLOCKED (obtainable only by skipping a gate): %d" % locked.size())
	for id in locked:
		print("  ", id, " (", D.ITEMS[id].name, ")")
	print("== reachable: %d of %d items, %d steps" % [have.size(), D.ITEMS.size(), step])
	quit(1 if locked.size() > 0 else 0)
