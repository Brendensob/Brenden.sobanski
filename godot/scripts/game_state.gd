extends Node
## Everything that gets saved: inventory, equipment, stats, coins, quests,
## unlocked maps and the time of day. Also sets up the controls.

signal inventory_changed
signal stats_changed
signal message(text: String, kind: String)

const SAVE_PATH := "user://save.json"
const HOTBAR := 5
const BAG := 25
const DAY_LENGTH := 360.0 # seconds for a full day and night

var inv: Array = []
var equip := {"helmet": "", "armor": "", "shield": "", "ring": ""}
var sel := 0
var coins := 0
var hp := 5.0
var mana := 2.0
var stamina := 4.0
var quests_done: Array = []
var bosses: Array = []
var unlocked := {"town": true, "grass_1": true}
var furnace := false
var day := 1
var clock := 0.2 # 0..1, night is from 0.7 to 0.95
var level_id := "town"

func _ready() -> void:
	_setup_input()
	new_game()

func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_K, KEY_SPACE, KEY_W, KEY_UP],
		"attack": [KEY_J, KEY_X, KEY_ENTER],
		"bag": [KEY_E, KEY_I, KEY_TAB],
		"pause": [KEY_ESCAPE, KEY_P],
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

func new_game() -> void:
	inv.clear()
	inv.resize(BAG)
	equip = {"helmet": "", "armor": "", "shield": "", "ring": ""}
	sel = 0
	coins = 0
	quests_done = []
	bosses = []
	unlocked = {"town": true, "grass_1": true}
	furnace = false
	day = 1
	clock = 0.2
	level_id = "town"
	add_item("wood_club")
	add_item("wood_axe")
	add_item("wood_pick")
	hp = max_hp()
	mana = max_mana()
	stamina = max_stamina()

# ---------------------------------------------------------------- stats
func _gear_sum(stat: String) -> float:
	var total := 0.0
	for slot in equip:
		var id: String = equip[slot]
		if id != "":
			total += float(Data.ITEMS[id].get(stat, 0))
	return total

func max_hp() -> float: return 5.0 + _gear_sum("hp")
func max_mana() -> float: return 2.0 + _gear_sum("mana")
func max_stamina() -> float: return 4.0 + _gear_sum("stamina")
func defense() -> float: return _gear_sum("def")
func bonus_damage() -> float: return _gear_sum("bonus_dmg")

func clamp_stats() -> void:
	hp = minf(hp, max_hp())
	mana = minf(mana, max_mana())
	stamina = minf(stamina, max_stamina())
	stats_changed.emit()

# ---------------------------------------------------------------- inventory
func stack_size(id: String) -> int:
	return 1 if Data.ITEMS[id].type in Data.UNSTACKABLE else Data.STACK

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
	for s in inv:
		if s == null or (s.id == id and s.n < stack_size(id)):
			return true
	return false

## Returns how many did not fit.
func add_item(id: String, n: int = 1) -> int:
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

func swap(a: int, b: int) -> void:
	var t = inv[a]
	inv[a] = inv[b]
	inv[b] = t
	inventory_changed.emit()

func equip_from(i: int) -> void:
	var s = inv[i]
	if s == null:
		return
	var slot: String = Data.ITEMS[s.id].type
	if not slot in Data.EQUIP_SLOTS:
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
		message.emit("Your bag is full.", "warn")
		return
	equip[slot] = ""
	add_item(id)
	clamp_stats()

## Eats or drinks the item in slot i. Returns true when it was used.
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
	if it.has("stamina") and stamina < max_stamina():
		stamina = max_stamina()
		used = true
	if it.has("mana") and mana < max_mana():
		mana = max_mana()
		used = true
	if not used:
		message.emit("You don't need that right now.", "warn")
		return false
	remove_at(i)
	stats_changed.emit()
	return true

# ---------------------------------------------------------------- combining
## Works out what two items make and the success chance, before trying it.
func preview_combo(a: String, b: String, near_furnace: bool) -> Dictionary:
	var r := Data.find_recipe(a, b)
	if r.is_empty():
		return {"known": false}
	var chance: int = r.chance
	var book := ""
	if r.tier > 0:
		book = Data.TIER_BOOK[r.tier]
		if count(book) > 0:
			chance += int(Data.ITEMS[book].bonus)
	var blocked := ""
	if r.get("station", "") == "furnace" and not near_furnace:
		blocked = "Stand next to the furnace in Pixel Village to smelt."
	return {"known": true, "recipe": r, "chance": mini(chance, 100), "book": book, "blocked": blocked}

## Uses one of each input. Success gives the result; failure gives Dust.
func combine(slot_a: int, slot_b: int, near_furnace: bool) -> Dictionary:
	var sa = inv[slot_a]
	var sb = inv[slot_b]
	if sa == null or sb == null:
		return {"ok": false, "reason": "Pick two items."}
	if slot_a == slot_b and sa.n < 2:
		return {"ok": false, "reason": "You need two of that item."}
	var p := preview_combo(sa.id, sb.id, near_furnace)
	if not p.known:
		return {"ok": false, "reason": "Unknown"}
	if p.blocked != "":
		return {"ok": false, "reason": p.blocked}
	var a_id: String = sa.id
	var b_id: String = sb.id
	remove_item(a_id, 1)
	remove_item(b_id, 1)
	if randi_range(1, 100) <= p.chance:
		var left := add_item(p.recipe.out, p.recipe.n)
		return {"ok": true, "success": true, "out": p.recipe.out, "n": p.recipe.n, "left": left}
	add_item("dust", 1)
	return {"ok": true, "success": false}

# ---------------------------------------------------------------- quests
func next_quest(npc: String) -> Dictionary:
	for q in Data.QUESTS:
		if q.npc == npc and not q.id in quests_done:
			return q
	return {}

func quest_ready(q: Dictionary) -> bool:
	for id in q.need:
		if count(id) < q.need[id]:
			return false
	if q.has("boss") and not q.boss in bosses:
		return false
	return true

func complete_quest(q: Dictionary) -> void:
	for id in q.need:
		remove_item(id, q.need[id])
	for id in q.reward:
		var left := add_item(id, q.reward[id])
		if left > 0:
			message.emit("Your bag is full, so some of the reward was lost.", "warn")
	coins += int(q.get("coins", 0))
	if q.get("unlock", "") == "furnace":
		furnace = true
	quests_done.append(q.id)
	inventory_changed.emit()
	stats_changed.emit()

# ---------------------------------------------------------------- maps
func level_after(id: String) -> String:
	var parts := id.split("_")
	if parts[1] == "lair":
		return ""
	var n := int(parts[1])
	if n < Data.LEVELS_PER_ZONE:
		return "%s_%d" % [parts[0], n + 1]
	return parts[0] + "_lair"

func defeat_boss(mob_id: String) -> void:
	if not mob_id in bosses:
		bosses.append(mob_id)
	for z in Data.ZONE_ORDER:
		if Data.ZONES[z].unlock_after == mob_id:
			unlocked[z + "_1"] = true
			message.emit("%s is now open!" % Data.ZONES[z].name, "good")

func is_night() -> bool:
	return clock >= 0.7 and clock < 0.95

func darkness() -> float:
	if clock < 0.62:
		return 0.0
	if clock < 0.72:
		return (clock - 0.62) / 0.10
	if clock < 0.92:
		return 1.0
	return clampf((1.0 - clock) / 0.08, 0.0, 1.0)

# ---------------------------------------------------------------- saving
func save_game() -> void:
	var data := {
		"v": 1, "inv": inv, "equip": equip, "sel": sel, "coins": coins, "hp": hp, "mana": mana,
		"stamina": stamina, "quests": quests_done, "bosses": bosses, "unlocked": unlocked,
		"furnace": furnace, "day": day, "clock": clock, "level": level_id,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return false
	inv.clear()
	inv.resize(BAG)
	var saved_inv: Array = d.get("inv", [])
	for i in mini(saved_inv.size(), BAG):
		var s = saved_inv[i]
		if s and Data.ITEMS.has(s.id):
			inv[i] = {"id": s.id, "n": int(s.n)}
	for slot in equip:
		var id: String = d.get("equip", {}).get(slot, "")
		equip[slot] = id if Data.ITEMS.has(id) else ""
	sel = int(d.get("sel", 0))
	coins = int(d.get("coins", 0))
	quests_done = d.get("quests", [])
	bosses = d.get("bosses", [])
	unlocked = d.get("unlocked", {"town": true, "grass_1": true})
	furnace = bool(d.get("furnace", false))
	day = int(d.get("day", 1))
	clock = float(d.get("clock", 0.2))
	level_id = d.get("level", "town")
	hp = float(d.get("hp", max_hp()))
	mana = float(d.get("mana", max_mana()))
	stamina = float(d.get("stamina", max_stamina()))
	if hp <= 0:
		hp = max_hp()
	clamp_stats()
	inventory_changed.emit()
	return true
