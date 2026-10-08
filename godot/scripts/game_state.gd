extends Node
## Everything that gets saved, plus the combat formulas and crafting rules.

signal inventory_changed
signal stats_changed
signal message(text: String, kind: String)

const VERSION := 3
const SLOTS := 3 # character slots on the main menu, like the original
const HOTBAR := 5
const BAG := 25 # 5 x 5, the top row is the hotbar
const EQUIP_SLOTS := ["helmet", "armor", "shield", "ring_l", "ring_r", "pet"]
const BASE := {"atk": 1, "def": 0, "mag": 0, "hp": 5, "mp": 2, "st": 4}
const STATUS_TIME := 10.0

var inv: Array = []
var equip := {}
var sel := 0
var coins := 0
var hp := 5.0
var mp := 2.0
var st := 4.0
var status := {} # effect -> seconds left
var flags := {}
var quests_done: Array = []
var furnaces: Array = []
var incubator := {}
var soils: Array = []
var reward_chests := {} # world id -> unix day it was last opened
# Time of day from 0 to 1. Like the original (216 s a day): daytime for the first
# 11 of 24 ticks, sunset for 4, night for 9, then straight back to morning.
var clock := 0.0
var day := 1
var world := "town"
var best_survival_day := 0
var look := "man_in_suit" # which character you look like
var player_name := "Player"
var slot := 0 # which character slot is being played

func _ready() -> void:
	_setup_input()
	new_game()

func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_K, KEY_SPACE, KEY_W, KEY_UP], "attack": [KEY_J, KEY_X, KEY_ENTER],
		"bag": [KEY_E, KEY_I, KEY_TAB], "pause": [KEY_ESCAPE, KEY_P],
		"slot_1": [KEY_1], "slot_2": [KEY_2], "slot_3": [KEY_3], "slot_4": [KEY_4], "slot_5": [KEY_5],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var pad := {"jump": JOY_BUTTON_A, "attack": JOY_BUTTON_X, "bag": JOY_BUTTON_Y, "pause": JOY_BUTTON_START}
	for action in pad:
		var jb := InputEventJoypadButton.new()
		jb.button_index = pad[action]
		InputMap.action_add_event(action, jb)

func now() -> float:
	return Time.get_unix_time_from_system()

func new_game(character: String = "man_in_suit", pname: String = "") -> void:
	look = character
	player_name = pname if pname != "" else default_name()
	inv.clear()
	inv.resize(BAG)
	equip = {}
	for s in EQUIP_SLOTS:
		equip[s] = ""
	sel = 0
	coins = 0
	status = {}
	flags = {}
	quests_done = []
	furnaces = []
	furnaces.resize(Data.FURNACES)
	incubator = {}
	soils = []
	soils.resize(5)
	reward_chests = {}
	clock = 0.0
	day = 1
	world = "town"
	add_item("sword_cast", 1, true)
	add_item("wooden_axe", 1, true)
	add_item("wooden_pick", 1, true)
	add_item("small_potion", 3, true)
	hp = max_hp()
	mp = max_mp()
	st = max_st()

# ---------------------------------------------------------------- stats
func stat(k: String) -> int:
	var total: int = BASE[k]
	for slot in EQUIP_SLOTS:
		var id: String = equip[slot]
		if id != "" and Data.ITEMS[id].has("stats"):
			total += int(Data.ITEMS[id].stats.get(k, 0))
	return total

func max_hp() -> float: return float(stat("hp"))
func max_mp() -> float: return float(stat("mp"))
func max_st() -> float: return float(stat("st"))

func clamp_stats() -> void:
	hp = minf(hp, max_hp())
	mp = minf(mp, max_mp())
	st = minf(st, max_st())
	stats_changed.emit()

## Damage you deal: a random number between your fixed attack + 1 and your fixed
## attack + your weapon's attack (from the wiki's game-mechanics page).
func attack_range(weapon_id: String) -> Vector2i:
	var fixed := stat("atk")
	var w := 1
	if weapon_id != "" and Data.ITEMS[weapon_id].has("dmg"):
		w = int(Data.ITEMS[weapon_id].dmg)
	return Vector2i(fixed + 1, fixed + w)

func roll_attack(weapon_id: String) -> int:
	var r := attack_range(weapon_id)
	return randi_range(r.x, r.y)

## Damage a monster deals to you, the same way the wiki's defense calculator does it:
## the monster's attack (doubled on a critical hit) minus a random number between
## 0 and your defense, never less than 1. So defense equal to a monster's attack
## halves its hits on average, and twice its attack makes most hits deal 1.
func roll_monster_hit(dmg: int, crit_chance: float) -> Dictionary:
	var hit := dmg
	var crit := randf() < crit_chance
	if crit:
		hit *= 2
	var blocked := randi_range(0, maxi(0, stat("def")))
	return {"dmg": maxi(1, hit - blocked), "crit": crit}

func add_status(effect: String) -> void:
	var had := status.has(effect)
	status[effect] = STATUS_TIME
	if not had:
		message.emit({"poison": "You've been poisoned!", "fatigue": "Fatigue! Your stamina won't recover.", "slow": "You've been slowed!", "cold": "Brr! You're freezing."}.get(effect, effect), "warn")
	stats_changed.emit()

func has_status(effect: String) -> bool:
	return status.has(effect)

# ---------------------------------------------------------------- inventory
func stack_size(id: String) -> int:
	var t: String = Data.ITEMS[id].type
	if t in ["weapon", "staff", "bow", "axe", "pick", "helmet", "armor", "shield", "ring", "pet", "book"]:
		return 1
	if t in ["ammo", "token", "throw"]:
		return 999
	if id == "hero_bug":
		return 25
	return 99

func held() -> String:
	var s = inv[sel]
	return s.id if s else ""

func count(id: String) -> int:
	var n := 0
	for s in inv:
		if s and s.id == id:
			n += s.n
	return n

func has_room(id: String) -> bool:
	if id == "coin":
		return true
	for s in inv:
		if s == null or (s.id == id and s.n < stack_size(id)):
			return true
	return false

## Adds items; returns how many did not fit.
func add_item(id: String, n: int = 1, quiet: bool = false) -> int:
	if id == "coin":
		coins += n
		stats_changed.emit()
		return 0
	var m := stack_size(id)
	for s in inv:
		if n <= 0:
			break
		if s and s.id == id and s.n < m:
			var k := mini(n, m - s.n)
			s.n += k
			n -= k
	for i in BAG:
		if n <= 0:
			break
		if inv[i] == null:
			var k := mini(n, m)
			inv[i] = {"id": id, "n": k}
			n -= k
	if n > 0 and not quiet:
		message.emit("Inventory full.", "warn")
	inventory_changed.emit()
	return n

func remove_item(id: String, n: int = 1) -> void:
	for i in range(BAG - 1, -1, -1):
		if n <= 0:
			break
		var s = inv[i]
		if s and s.id == id:
			var k := mini(n, s.n)
			s.n -= k
			n -= k
			if s.n <= 0:
				inv[i] = null
	inventory_changed.emit()

func remove_at(i: int, n: int = 1) -> void:
	var s = inv[i]
	if s == null:
		return
	s.n -= n
	if s.n <= 0:
		inv[i] = null
	inventory_changed.emit()

func has_all(cost: Dictionary) -> bool:
	for id in cost:
		if count(id) < cost[id]:
			return false
	return true

func take_all(cost: Dictionary) -> void:
	for id in cost:
		remove_item(id, cost[id])

func swap(a: int, b: int) -> void:
	var t = inv[a]
	inv[a] = inv[b]
	inv[b] = t
	inventory_changed.emit()

func equip_slot_for(id: String) -> String:
	var t: String = Data.ITEMS[id].type
	if t == "ring":
		return "ring_r" if equip.ring_l != "" and equip.ring_r == "" else "ring_l"
	if t in EQUIP_SLOTS:
		return t
	return ""

func equip_from(i: int) -> void:
	var s = inv[i]
	if s == null:
		return
	var slot := equip_slot_for(s.id)
	if slot == "":
		return
	var old: String = equip[slot]
	equip[slot] = s.id
	inv[i] = {"id": old, "n": 1} if old != "" else null
	clamp_stats()
	inventory_changed.emit()
	message.emit("Equipped %s." % Data.ITEMS[s.id].name, "")

func unequip(slot: String) -> void:
	var id: String = equip[slot]
	if id == "":
		return
	if not has_room(id):
		message.emit("Inventory full.", "warn")
		return
	equip[slot] = ""
	add_item(id)
	clamp_stats()

## Uses food or a potion in slot i. Returns true if it was used.
func consume(i: int) -> bool:
	var s = inv[i]
	if s == null:
		return false
	var it: Dictionary = Data.ITEMS[s.id]
	if it.type != "food":
		return false
	var used := false
	if it.has("heal") and hp < max_hp():
		hp = minf(max_hp(), hp + it.heal)
		used = true
	if it.has("mana") and mp < max_mp():
		mp = minf(max_mp(), mp + it.mana)
		used = true
	if it.has("stamina") and st < max_st():
		st = minf(max_st(), st + it.stamina)
		used = true
	if it.has("cure") and status.has(it.cure):
		status.erase(it.cure)
		used = true
	if not used:
		message.emit("You don't need that right now.", "warn")
		return false
	remove_at(i)
	stats_changed.emit()
	return true

# ---------------------------------------------------------------- combining
func has_book(book: String) -> bool:
	return count(Data.BOOK_ITEM[book]) > 0

## What the items in the combination slots would make, and the chance.
func preview_combo(slots: Array, use_scroll: bool) -> Dictionary:
	var ids := []
	for i in slots:
		if i >= 0 and inv[i] != null:
			ids.append(inv[i].id)
	if ids.size() < 2:
		return {"ready": false}
	var r := Data.find_recipe(ids)
	if r.is_empty():
		return {"ready": true, "known": false, "chance": 0}
	var chance: int = r.rate
	var book := has_book(r.book)
	if book:
		chance += Data.BOOK_BONUS
	if use_scroll:
		chance += Data.SCROLL_BONUS
	return {"ready": true, "known": true, "recipe": r, "chance": clampi(chance, 0, 100), "book": book}

func combine(slots: Array, use_scroll: bool) -> Dictionary:
	var used := []
	var need := {}
	for i in slots:
		if i >= 0 and inv[i] != null:
			used.append(i)
			need[inv[i].id] = need.get(inv[i].id, 0) + 1
	if used.size() < 2:
		return {"ok": false, "reason": "Put at least two items in the slots."}
	if not has_all(need):
		return {"ok": false, "reason": "You don't have enough of those items."}
	if use_scroll and count("combination_scroll") <= 0:
		use_scroll = false
	var p := preview_combo(slots, use_scroll)
	take_all(need)
	if use_scroll:
		remove_item("combination_scroll", 1)
	if p.known and randi_range(1, 100) <= p.chance:
		var n: int = p.recipe.get("n", 1)
		add_item(p.recipe.out, n)
		return {"ok": true, "success": true, "out": p.recipe.out, "n": n}
	add_item("dust", 1)
	return {"ok": true, "success": false, "known": p.known}

# ---------------------------------------------------------------- smith and furnaces
func smith(recipe: Dictionary) -> bool:
	if not has_all(recipe.cost):
		return false
	take_all(recipe.cost)
	add_item(recipe.out, 1)
	return true

func start_smelt(f: int, recipe: Dictionary) -> String:
	if not flags.get("furnaces", false):
		return "The furnace gate is locked. Talk to the GateKeeper."
	if furnaces[f] != null:
		return "That furnace is busy."
	if not has_all(recipe.cost):
		return "You need %s." % cost_text(recipe.cost)
	take_all(recipe.cost)
	furnaces[f] = {"out": recipe.out, "done": now() + recipe.time, "main": recipe.main}
	return ""

func collect_smelt(f: int) -> bool:
	var job = furnaces[f]
	if job == null or now() < job.done:
		return false
	if add_item(job.out, 1) > 0:
		return false
	furnaces[f] = null
	return true

func cost_text(cost: Dictionary) -> String:
	var parts := []
	for id in cost:
		parts.append("%d %s" % [cost[id], Data.ITEMS[id].name])
	return ", ".join(parts)

# ---------------------------------------------------------------- incubator and soils
func start_hatch(egg: String) -> bool:
	if not incubator.is_empty() or count(egg) <= 0:
		return false
	remove_item(egg, 1)
	incubator = {"egg": egg, "done": now() + Data.HATCH_TIME}
	return true

func collect_hatch() -> String:
	if incubator.is_empty() or now() < incubator.done:
		return ""
	var options: Array = Data.EGG_PETS[incubator.egg]
	var pet: String = options[randi() % options.size()]
	if add_item(pet, 1) > 0:
		return ""
	incubator = {}
	return pet

func plant(soil: int, seed: String) -> bool:
	if soils[soil] != null or count(seed) <= 0:
		return false
	remove_item(seed, 1)
	soils[soil] = {"seed": seed, "done": now() + float(Data.ITEMS[seed].grow)}
	return true

func harvest(soil: int) -> Array:
	var s = soils[soil]
	if s == null or now() < s.done:
		return []
	var loot := []
	for i in 3:
		loot.append(Data.pick_loot(Data.SEED_LOOT[s.seed]))
	for l in loot:
		add_item(l[0], l[1], true)
	soils[soil] = null
	return loot

# ---------------------------------------------------------------- chests
func open_chest(kind: String) -> Array:
	var c: Dictionary = Data.CHESTS[kind]
	if count(c.key) <= 0:
		return []
	remove_item(c.key, 1)
	var loot := []
	for i in c.rolls:
		var l := Data.pick_loot(c.loot)
		loot.append(l)
		add_item(l[0], l[1], true)
	return loot

func today() -> int:
	return int(now() / 86400.0)

# ---------------------------------------------------------------- quests
func next_quest(npc: String) -> Dictionary:
	for q in Data.QUESTS:
		if q.npc == npc and not q.id in quests_done:
			return q
	return {}

func quest_ready(q: Dictionary) -> bool:
	return has_all(q.need)

func complete_quest(q: Dictionary) -> void:
	take_all(q.get("take", q.need)) # a couple of Miffie's quests check for 10 but take 5
	for id in q.reward:
		add_item(id, q.reward[id])
	if q.has("coins"):
		coins += int(q.coins)
	if q.has("unlock"):
		flags[q.unlock] = true
	quests_done.append(q.id)
	inventory_changed.emit()
	stats_changed.emit()

# ---------------------------------------------------------------- time of day
const SUNSET := 11.0 / 24.0
const NIGHT := 15.0 / 24.0

func darkness() -> float:
	if clock < SUNSET:
		return 0.0
	if clock < NIGHT:
		return (clock - SUNSET) / (NIGHT - SUNSET)
	return 1.0

func is_night() -> bool:
	return clock >= NIGHT

# ---------------------------------------------------------------- saving
func save_game() -> void:
	var data := {
		"v": VERSION, "inv": inv, "equip": equip, "sel": sel, "coins": coins, "hp": hp, "mp": mp, "st": st,
		"flags": flags, "quests": quests_done, "furnaces": furnaces, "incubator": incubator, "soils": soils,
		"reward_chests": reward_chests, "clock": clock, "day": day, "best_survival_day": best_survival_day, "look": look, "name": player_name,
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func slot_path(i: int) -> String:
	return "user://slot%d.json" % i

func has_save() -> bool:
	return FileAccess.file_exists(slot_path(slot))

func _read_slot(i: int):
	if not FileAccess.file_exists(slot_path(i)):
		return null
	var f := FileAccess.open(slot_path(i), FileAccess.READ)
	if f == null:
		return null
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY or int(d.get("v", 0)) != VERSION:
		return null
	return d

## What the main menu shows for a slot: name, look and day, or empty if it's free.
func slot_info(i: int) -> Dictionary:
	var d = _read_slot(i)
	if d == null:
		return {}
	return {"name": str(d.get("name", "Player")), "look": str(d.get("look", "man_in_suit")), "day": int(d.get("day", 1))}

func delete_slot(i: int) -> void:
	if FileAccess.file_exists(slot_path(i)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(i)))

func default_name() -> String:
	return "Player_%d" % randi_range(100000000, 999999999)

func load_game() -> bool:
	var d = _read_slot(slot)
	if d == null:
		return false
	new_game()
	inv.clear()
	inv.resize(BAG)
	var saved: Array = d.get("inv", [])
	for i in mini(saved.size(), BAG):
		var s = saved[i]
		if s and Data.ITEMS.has(s.id):
			inv[i] = {"id": s.id, "n": int(s.n)}
	for slot in EQUIP_SLOTS:
		var id: String = d.get("equip", {}).get(slot, "")
		equip[slot] = id if Data.ITEMS.has(id) else ""
	sel = int(d.get("sel", 0))
	coins = int(d.get("coins", 0))
	flags = d.get("flags", {})
	quests_done = d.get("quests", [])
	var fs: Array = d.get("furnaces", [])
	for i in mini(fs.size(), Data.FURNACES):
		furnaces[i] = fs[i]
	incubator = d.get("incubator", {})
	var ss: Array = d.get("soils", [])
	for i in mini(ss.size(), 5):
		soils[i] = ss[i]
	reward_chests = d.get("reward_chests", {})
	clock = 0.0 # entering Pixel Town from the menu always starts at morning
	day = int(d.get("day", 1))
	best_survival_day = int(d.get("best_survival_day", 0))
	look = str(d.get("look", "man_in_suit"))
	player_name = str(d.get("name", "Player"))
	if not Data.CHARACTERS.has(look):
		look = "man_in_suit"
	hp = clampf(float(d.get("hp", max_hp())), 1, max_hp())
	mp = float(d.get("mp", max_mp()))
	st = float(d.get("st", max_st()))
	clamp_stats()
	inventory_changed.emit()
	return true

## Use a character item: you take on its look, and some characters come with a weapon.
func use_character(i: int) -> String:
	var s = inv[i]
	if s == null or Data.ITEMS[s.id].type != "character":
		return ""
	var it: Dictionary = Data.ITEMS[s.id]
	remove_at(i, 1)
	look = it.look
	var msg := "You're now the %s!" % it.name
	if it.gives != "":
		if add_item(it.gives, 1, true) == 0:
			msg += " You got a %s." % Data.ITEMS[it.gives].name
		else:
			msg += " Your bag was full, so the %s was lost." % Data.ITEMS[it.gives].name
	inventory_changed.emit()
	return msg

## The Daily Free Gift button in Pixel Town: one free roll per real day.
func gift_ready() -> bool:
	return int(flags.get("gift_day", -1)) != today()

func open_gift() -> Array:
	if not gift_ready():
		return []
	flags["gift_day"] = today()
	var got: Array = Data.pick_loot(Data.DAILY_GIFT)
	if add_item(got[0], got[1], true) > 0:
		message.emit("Your bag is full.", "warn")
	inventory_changed.emit()
	return got
