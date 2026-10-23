extends SceneTree
## Checks that the game's data hangs together: every id points at something real,
## every item can be obtained by playing, and every item has a use.
## Run from the godot folder:  godot --headless --path . -s tools/data_audit.gd
## Prints a report and exits with 1 when a hard error (a broken reference) is found.

var D
var errors := []
var notes := []
var sources := {} # item -> [how you get it]

func _initialize() -> void:
	D = load("res://scripts/data.gd").new()
	D._build_mobs()
	_check_refs()
	_obtainable()
	_uses()
	_spawns()
	_shop_loops()
	_recipe_clashes()
	print("\n== HARD ERRORS (%d)" % errors.size())
	for e in errors:
		print("  ERROR ", e)
	print("\n== NOTES (%d)" % notes.size())
	for n in notes:
		print("  ", n)
	quit(1 if errors.size() > 0 else 0)

func _item_ok(id: String, where: String) -> void:
	if id in ["coin", "gem", "survival_token"] and not D.ITEMS.has(id):
		return
	if not D.ITEMS.has(id):
		errors.append("%s uses unknown item '%s'" % [where, id])

func _check_refs() -> void:
	for r in D.RECIPES:
		for x in r["in"]:
			_item_ok(x, "combination for " + str(r.out))
		_item_ok(r.out, "combination output")
	for s in D.SMITH:
		_item_ok(s.out, "Crafter output")
		for k in s.cost:
			_item_ok(k, "Crafter recipe " + str(s.out))
	for s in D.SMELT:
		_item_ok(s.out, "smelting output")
		for k in s.cost:
			_item_ok(k, "smelting " + str(s.out))
	for n in D.NODES:
		for d in D.NODES[n].get("drops", []):
			_item_ok(d[0], "resource " + n)
	for m in D.MOBS:
		for d in D.MOBS[m].drops:
			_item_ok(d[0], "monster " + m)
	for w in D.WORLDS:
		var wd: Dictionary = D.WORLDS[w]
		for e in wd.get("mobs", []):
			if not D.MOBS.has(e[0]):
				errors.append("world %s spawns unknown monster '%s'" % [w, e[0]])
		for e in wd.get("bosses", []):
			if not D.MOBS.has(e[0]):
				errors.append("world %s has unknown boss '%s'" % [w, e[0]])
		for e in wd.get("nodes", []):
			if not D.NODES.has(e[0]):
				errors.append("world %s has unknown resource '%s'" % [w, e[0]])
		for key in ["boss_drops", "mob_drops"]:
			for d in wd.get(key, []):
				_item_ok(d[0], "world %s %s" % [w, key])
		if wd.has("next") and not D.WORLDS.has(wd.next):
			errors.append("world %s leads to unknown world %s" % [w, wd.next])
	for c in D.WORLD_CARDS:
		if not D.WORLDS.has(c[0]):
			errors.append("world card for unknown world " + c[0])
	for s in D.SHOPS:
		for e in D.SHOPS[s].sells:
			_item_ok(e[0], "shop " + s)
	for e in D.gem_shop().sells:
		_item_ok(e[0], "Gem Shop")
	for c in D.CHESTS:
		_item_ok(D.CHESTS[c].key, "chest key " + c)
		for e in D.CHESTS[c].loot:
			_item_ok(e[0], "chest " + c)
	for sd in D.SEED_LOOT:
		_item_ok(sd, "seed")
		for e in D.SEED_LOOT[sd]:
			_item_ok(e[0], "seed harvest " + sd)
	for q in D.QUESTS:
		if not D.NPCS.has(q.npc):
			errors.append("quest %s has unknown villager %s" % [q.id, q.npc])
		for k in q.need:
			_item_ok(k, "quest %s needs" % q.id)
		for k in q.reward:
			_item_ok(k, "quest %s reward" % q.id)
	for c in D.CHARACTERS:
		_item_ok(c, "character")
		if D.CHARACTERS[c].has("gives"):
			_item_ok(D.CHARACTERS[c].gives, "character %s gives" % c)
	for egg in D.EGG_PETS:
		_item_ok(egg, "egg")
		for p in D.EGG_PETS[egg]:
			if not D.PETS.has(p):
				errors.append("egg %s hatches unknown pet %s" % [egg, p])
			_item_ok(p, "pet from " + egg)
	for wave in D.SURVIVAL_WAVES:
		for m in wave[1]:
			if not D.MOBS.has(m):
				errors.append("survival wave has unknown monster " + m)
	for m in D.SURVIVAL_BOSSES:
		if not D.MOBS.has(m):
			errors.append("survival boss unknown " + m)

func _add(id: String, how: String) -> bool:
	if not sources.has(id):
		sources[id] = [how]
		return true
	if sources[id].size() < 4 and not how in sources[id]:
		sources[id].append(how)
	return false

func _have(id: String) -> bool:
	return id in ["coin"] or sources.has(id)

func _obtainable() -> void:
	# what a new character starts with, and what the game hands out in code
	for id in ["sword_cast", "wooden_axe", "wooden_pick", "small_potion", "dust", "coin"]:
		_add(id, "start")
	# everything any monster that appears somewhere drops, and every resource in a world
	var spawned := {}
	for w in D.WORLDS:
		var wd: Dictionary = D.WORLDS[w]
		for e in wd.get("mobs", []) + wd.get("bosses", []):
			spawned[e[0]] = w
		for e in wd.get("nodes", []):
			for d in D.NODES[e[0]].get("drops", []):
				_add(d[0], "resource " + e[0])
		for key in ["boss_drops", "mob_drops"]:
			for d in wd.get(key, []):
				_add(d[0], w + " " + key)
	for wave in D.SURVIVAL_WAVES:
		for m in wave[1]:
			spawned[m] = "survival"
	for m in D.SURVIVAL_BOSSES:
		spawned[m] = "survival"
	# the town's own resources (survival corridor, soils)
	for n in ["tree", "stone", "copper", "iron", "plant_yellow", "plant_pink", "pot"]:
		for d in D.NODES[n].get("drops", []):
			_add(d[0], "resource " + n)
	for m in spawned:
		for d in D.MOBS[m].drops:
			_add(d[0], "monster " + m)
	_add("survival_token", "Survival Grasslands")
	_add("wall_hammer", "Survival night %d" % D.WALL_HAMMER_DAY)
	for k in ["silver_key", "golden_key", "master_key"]:
		_add(k, "dying in Survival")
	_add("gem", "bosses")
	_add("silver_key", "reward chest in worlds")
	for e in D.CHESTS.silver.loot:
		_add(e[0], "world reward chest")
	# keep applying every rule until nothing new turns up
	var changed := true
	while changed:
		changed = false
		for s in D.SHOPS:
			var cur: String = D.SHOPS[s].get("currency", "coin")
			if _have(cur) and (not D.SHOPS[s].has("needs") or _have("green_face")):
				for e in D.SHOPS[s].sells:
					changed = _add(e[0], "shop " + s) or changed
		if _have("gem"):
			for e in D.gem_shop().sells:
				changed = _add(e[0], "Gem Shop") or changed
		for c in D.CHESTS:
			if _have(D.CHESTS[c].key):
				for e in D.CHESTS[c].loot:
					changed = _add(e[0], c + " chest") or changed
		for sd in D.SEED_LOOT:
			if _have(sd):
				for e in D.SEED_LOOT[sd]:
					changed = _add(e[0], sd + " harvest") or changed
		for q in D.QUESTS:
			if q.need.keys().all(func(k): return _have(k)):
				for k in q.reward:
					changed = _add(k, "quest " + q.id) or changed
		for s in D.SMITH:
			if s.cost.keys().all(func(k): return _have(k)):
				changed = _add(s.out, "Crafter") or changed
		for r in D.RECIPES:
			if r["in"].all(func(k): return _have(k)):
				changed = _add(r.out, "combining") or changed
		for s in D.SMELT:
			if s.cost.keys().all(func(k): return _have(k)):
				changed = _add(s.out, "furnace") or changed
		for egg in D.EGG_PETS:
			if _have(egg):
				for p in D.EGG_PETS[egg]:
					changed = _add(p, "hatching " + egg) or changed
		for c in D.CHARACTERS:
			if _have(c) and D.CHARACTERS[c].has("gives"):
				changed = _add(D.CHARACTERS[c].gives, "character " + c) or changed
	# bare hands, and the two characters you pick when you make a character
	for id in ["fist", "man_in_suit", "nurse"]:
		_add(id, "built in")
	var missing := []
	for id in D.ITEMS:
		if not sources.has(id):
			missing.append("%s (%s, %s)" % [id, D.ITEMS[id].name, D.ITEMS[id].type])
	notes.append("OBTAINABLE: %d of %d items can be got by playing" % [D.ITEMS.size() - missing.size(), D.ITEMS.size()])
	notes.append("UNOBTAINABLE (%d): %s" % [missing.size(), ", ".join(missing)])

func _uses() -> void:
	var used := {}
	for r in D.RECIPES:
		for x in r["in"]:
			used[x] = true
	for s in D.SMITH + D.SMELT:
		for k in s.cost:
			used[k] = true
	for q in D.QUESTS:
		for k in q.need:
			used[k] = true
	for egg in D.EGG_PETS:
		used[egg] = true
	var dead := []
	var sell_only := []
	for id in D.ITEMS:
		var it: Dictionary = D.ITEMS[id]
		if it.type in ["material"] and not used.has(id):
			if int(it.sell) <= 0:
				dead.append(id)
			else:
				sell_only.append(id)
	notes.append("MATERIALS WITH NO USE AND NO SELL PRICE (%d): %s" % [dead.size(), ", ".join(dead)])
	notes.append("MATERIALS ONLY GOOD FOR SELLING (%d): %s" % [sell_only.size(), ", ".join(sell_only)])
	var types := {}
	for id in D.ITEMS:
		types[D.ITEMS[id].type] = types.get(D.ITEMS[id].type, 0) + 1
	notes.append("ITEM TYPES: %s" % str(types))

func _spawns() -> void:
	var spawned := {}
	for w in D.WORLDS:
		for e in D.WORLDS[w].get("mobs", []) + D.WORLDS[w].get("bosses", []):
			spawned[e[0]] = true
	for wave in D.SURVIVAL_WAVES:
		for m in wave[1]:
			spawned[m] = true
	for m in D.SURVIVAL_BOSSES:
		spawned[m] = true
	var never := []
	for m in D.MOBS:
		if not spawned.has(m):
			never.append(m)
	notes.append("MONSTERS THAT NEVER SPAWN (%d): %s" % [never.size(), ", ".join(never)])
	var placed := {}
	for w in D.WORLDS:
		for e in D.WORLDS[w].get("nodes", []):
			placed[e[0]] = true
	var unplaced := []
	for n in D.NODES:
		if not placed.has(n):
			unplaced.append(n)
	notes.append("RESOURCES NOT PLACED IN ANY WORLD LIST (%d): %s" % [unplaced.size(), ", ".join(unplaced)])
	for w in D.WORLDS:
		var mobs: Array = D.WORLDS[w].get("mobs", [])
		var total := 0.0
		for e in mobs:
			total += float(e[1])
		for e in mobs:
			if float(e[1]) < 1.0:
				var per_map: float = float(D.WORLDS[w].get("count", D.WORLDS[w].get("cap", 0))) * float(e[1]) / total
				notes.append("RARE SPAWN %s in %s: weight %s = %.1f%% of spawns (~%.2f per visit)" % [e[0], w, e[1], 100.0 * float(e[1]) / total, per_map])

func _shop_loops() -> void:
	for s in D.SHOPS:
		if D.SHOPS[s].get("currency", "coin") != "coin":
			continue
		for e in D.SHOPS[s].sells:
			var sell := int(D.ITEMS[e[0]].sell) if D.ITEMS.has(e[0]) else 0
			if sell >= int(e[1]):
				errors.append("MONEY LOOP: %s sells %s for %d but it sells back for %d" % [s, e[0], e[1], sell])

func _recipe_clashes() -> void:
	var needs_book := 0
	var seen := {}
	for r in D.RECIPES:
		var k: Array = r["in"].duplicate()
		k.sort()
		var key := "+".join(k)
		if seen.has(key) and seen[key] != r.out:
			notes.append("SAME INGREDIENTS, TWO RESULTS: %s -> %s and %s" % [key, seen[key], r.out])
		seen[key] = r.out
		# the wiki's rates assume the book (+50) and a scroll (+35) can be added,
		# so a negative base rate is normal; only one that stays at 0 is impossible
		if int(r.rate) + D.BOOK_BONUS + D.SCROLL_BONUS <= 0 or int(r.rate) > 100:
			errors.append("combination %s has rate %s: impossible even with book and scroll" % [r.out, r.rate])
		if not D.BOOK_ITEM.has(r.get("book", "")):
			errors.append("combination %s belongs to unknown book %s" % [r.out, r.get("book", "")])
		elif int(r.rate) + D.SCROLL_BONUS <= 0:
			needs_book += 1
	notes.append("COMBINATIONS THAT NEED THEIR BOOK IN THE BAG (base rate + scroll still 0): %d" % needs_book)
