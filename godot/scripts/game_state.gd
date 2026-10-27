extends Node
## Everything that gets saved, plus the combat formulas and crafting rules.

signal inventory_changed
signal stats_changed
signal message(text: String, kind: String)
## Items that didn't fit in the bag; the HUD drops them at the player's feet.
signal overflow(id: String, n: int)
signal auto_hit_changed

const VERSION := 3
const SLOTS := 3 # character slots on the main menu, like the original
const HOTBAR := 5
const BAG := 25 # 5 x 5, the top row is the hotbar
const EQUIP_SLOTS := ["helmet", "armor", "shield", "ring_l", "ring_r", "pet"]
const BASE := {"atk": 1, "def": 0, "mag": 0, "hp": 10, "mp": 2, "st": 4}
const STATUS_TIME := 10.0

var inv: Array = []
var equip := {}
var sel := 0
var coins := 0
var gems := 0 # the rare currency, spent in the Gem Shop
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
var online_token := "" # the key that proves this character owns its name on the online server
var friend_names: Array = [] # last friends list seen online, so it can be put back if the server is wiped
var pending_token := "" # a name just claimed for a character that's about to be made
var slot := 0 # which character slot is being played
## The auto-hit switch: the weapon or tool you hold keeps swinging by itself, even
## with the bag open and after switching items. A setting of the device, kept
## with the sound settings.
var auto_hit := false
const SETTINGS := "user://settings.cfg"

func _ready() -> void:
	load_unlocks()
	anchor_to_device()
	_setup_input()
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		auto_hit = bool(cfg.get_value("controls", "auto_hit", false))
	new_game()

func set_auto_hit(on: bool) -> void:
	auto_hit = on
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("controls", "auto_hit", on)
	cfg.save(SETTINGS)
	auto_hit_changed.emit()

func _setup_input() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_K, KEY_SPACE, KEY_W, KEY_UP], "attack": [KEY_J, KEY_X, KEY_ENTER],
		"bag": [KEY_E, KEY_I, KEY_TAB], "pause": [KEY_ESCAPE, KEY_P], "auto_hit": [KEY_Q],
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

# ---------------------------------------------------------------- trusted time
# Furnaces, eggs, seeds and the daily chests and bounty run on now(). It counts
# from a starting point with the computer's steady tick counter, so changing
# the device clock while playing does nothing. The starting point is the online
# server's time when it can be reached; otherwise the device clock when the game
# starts, but never earlier than the last save (setting the clock back can't
# rewind anything). Time away from the game still counts, so furnaces finish
# while you're gone.
var _anchor_unix := 0.0
var _anchor_ms := 0
var trusted_time := false
var _system_clock: Callable = func() -> float: return Time.get_unix_time_from_system()

func now() -> float:
	return _anchor_unix + (Time.get_ticks_msec() - _anchor_ms) / 1000.0

## Starts counting from the device clock (until the server's time arrives).
func anchor_to_device() -> void:
	if trusted_time:
		return
	_anchor_unix = float(_system_clock.call())
	_anchor_ms = Time.get_ticks_msec()

## The online server told us the real time: count from that from now on.
func set_trusted_time(unix: float) -> void:
	_anchor_unix = unix
	_anchor_ms = Time.get_ticks_msec()
	trusted_time = true

## A save made at `saved` (its now()): the clock can't run backwards from it.
func _no_rewind(saved: float) -> void:
	if not trusted_time and now() < saved:
		_anchor_unix += saved - now()

## The storage Banka in Pixel Town keeps for you: six backpacks of
## 5 x 6 slots, like the original's bag screen.
const BACKPACKS := 6
const BACKPACK_SLOTS := 30
var storage: Array = [] # one Array of slots per backpack

func new_game(character: String = "man_in_suit", pname: String = "") -> void:
	look = character
	player_name = pname if pname != "" else default_name()
	online_token = pending_token
	pending_token = ""
	friend_names = []
	inv.clear()
	inv.resize(BAG)
	storage = []
	for b in BACKPACKS:
		var page := []
		page.resize(BACKPACK_SLOTS)
		storage.append(page)
	equip = {}
	for s in EQUIP_SLOTS:
		equip[s] = ""
	sel = 0
	coins = 0
	gems = 0
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
	best_survival_day = 0
	world = "town"
	add_item("sword_cast", 1, true)
	add_item("wooden_axe", 1, true)
	add_item("wooden_pick", 1, true)
	add_item("small_potion", 3, true)
	var gives: String = Data.CHARACTERS.get(character, {}).get("gives", "")
	if gives != "":
		flags["gave_" + character] = true
		add_item(gives, 1, true)
	hp = max_hp()
	mp = max_mp()
	st = max_st()

# ---------------------------------------------------------------- stats
func stat(k: String) -> int:
	var total: int = BASE[k] + int(Data.CHARACTERS.get(look, {}).get("stats", {}).get(k, 0))
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
## 0 and your defense. Like in the trailer, a hit your defense soaks up completely
## does 0. Defense equal to a monster's attack halves its hits on average.
func roll_monster_hit(dmg: int, crit_chance: float) -> Dictionary:
	var hit := dmg
	var crit := randf() < crit_chance
	if crit:
		hit *= 2
	var blocked := randi_range(0, maxi(0, stat("def")))
	return {"dmg": maxi(0, hit - blocked), "crit": crit}

func add_status(effect: String) -> void:
	if immune_to(effect):
		return
	var had := status.has(effect)
	status[effect] = STATUS_TIME
	if not had:
		message.emit({"poison": "You've been poisoned!", "fatigue": "Fatigue! Your stamina won't recover.", "slow": "You've been slowed!", "cold": "Brr! You're freezing."}.get(effect, effect), "warn")
	stats_changed.emit()

## The Jade Ring stops poison.
func immune_to(effect: String) -> bool:
	for slot in ["ring_l", "ring_r"]:
		var id: String = equip[slot]
		if id != "" and Data.ITEMS[id].get("immune", "") == effect:
			return true
	return false

func has_status(effect: String) -> bool:
	return status.has(effect)

# ---------------------------------------------------------------- inventory
func stack_size(id: String) -> int:
	var t: String = Data.ITEMS[id].type
	if t in ["weapon", "staff", "bow", "axe", "pick", "helmet", "armor", "shield", "ring", "pet", "book"]:
		return 1
	if t in ["ammo", "token", "throw"]:
		return 999
	# the wiki's stack sizes for the rarer things
	if id in ["dark_heart", "em_stone", "ruby_stone", "sapphire_stone", "topaz_stone", "dark_stone", "sky_stone", "forbidden_stone"]:
		return 1
	if id == "nightmare_ore":
		return 10
	if id == "hero_bug" or id == "living_flame":
		return 25
	if id == "legendary_roots":
		return 50
	return 99

func held() -> String:
	var s = inv[sel]
	return s.id if s else ""

func count(id: String) -> int:
	if id == "gem":
		return gems
	var n := 0
	for s in inv:
		if s and s.id == id:
			n += s.n
	return n

func has_room(id: String) -> bool:
	if id == "coin" or id == "gem":
		return true
	for s in inv:
		if s == null or (s.id == id and s.n < stack_size(id)):
			return true
	return false

## Gives items as a reward or a purchase. Whatever doesn't fit in the bag is
## dropped at the player's feet, so nothing earned or paid for is ever lost.
func give(id: String, n: int = 1) -> void:
	var left := add_item(id, n, true)
	if left > 0:
		overflow.emit(id, left)

## Adds items; returns how many did not fit.
func add_item(id: String, n: int = 1, quiet: bool = false) -> int:
	if id == "coin":
		coins += n
		stats_changed.emit()
		return 0
	if id == "gem":
		gems += n
		stats_changed.emit()
		return 0
	if Data.ITEMS.get(id, {}).get("type", "") == "character":
		unlock_character(id)
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
	if id == "gem":
		gems = maxi(0, gems - n)
		stats_changed.emit()
		return
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
	Sfx.play("equip", 0.0)
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
		give(p.recipe.out, n)
		Sfx.play("craft", 0.0)
		return {"ok": true, "success": true, "out": p.recipe.out, "n": n}
	give("dust", 1)
	Sfx.play("fail", 0.0)
	return {"ok": true, "success": false, "known": p.known}

# ---------------------------------------------------------------- smith and furnaces
func smith(recipe: Dictionary) -> bool:
	if not has_all(recipe.cost):
		return false
	take_all(recipe.cost)
	give(recipe.out, 1)
	Sfx.play("craft", 0.0)
	return true

func start_smelt(f: int, recipe: Dictionary) -> String:
	if not flags.get("furnaces", false):
		return "The furnace gate is locked. Talk to the GateKeeper."
	if furnaces[f] != null:
		return "That furnace is busy."
	if not has_all(recipe.cost):
		return "You need %s." % cost_text(recipe.cost)
	take_all(recipe.cost)
	Sfx.play("smelt", 0.0)
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
		give(l[0], l[1])
	soils[soil] = null
	return loot

# ---------------------------------------------------------------- chests
func open_chest(kind: String) -> Array:
	var c: Dictionary = Data.CHESTS[kind]
	if count(c.key) <= 0:
		return []
	remove_item(c.key, 1)
	Sfx.play("chest", 0.0)
	var loot := []
	for i in c.rolls:
		var l := Data.pick_loot(c.loot)
		loot.append(l)
		give(l[0], l[1])
	return loot

func today() -> int:
	return int(now() / 86400.0)

# ---------------------------------------------------------------- quests
## Your best melee or ranged weapon in the bag (the fist if none).
func best_weapon() -> String:
	var best := ""
	var best_dps := 0.0
	for s in inv:
		if s == null:
			continue
		var it: Dictionary = Data.ITEMS[s.id]
		if it.get("type", "") in ["weapon", "bow"] and it.has("dmg"):
			var dps := float(it.dmg) / maxf(0.1, float(it.get("spd", 0.5)))
			if dps > best_dps:
				best_dps = dps
				best = s.id
	return best

## How hard a world's monsters are for you right now, from your attack,
## defense and health: 0 Easy, 1 Fair, 2 Hard, 3 Deadly. It's the worst
## fight_score of the world's common monsters, with limits matched to what the
## fight test (tests/fight_test.gd) sees in real fights.
func world_danger(wid: String) -> int:
	var w: Dictionary = Data.WORLDS[wid]
	var list: Array = w.get("mobs", []).filter(func(e): return float(e[1]) >= 1.5)
	if wid == "survival":
		list = Data.SURVIVAL_WAVES[0][1].map(func(m): return [m, 1.0])
	var worst := 0.0
	for e in list:
		worst = maxf(worst, fight_score(wid, e))
	for i in DANGER_LIMITS.size():
		if worst < DANGER_LIMITS[i]:
			return i
	return 3

const DANGER_LIMITS := [1.5, 5.0, 20.0]

## The hits you need to beat a monster, over the hits it needs to make you
## faint. Every hit you land dazes a monster, which stops charges cold and
## keeps slow walkers away, but flying ones come back from any side.
const MINI_BOSS_HITS := 150.0
func fight_score(wid: String, e: Array, for_test := false) -> float:
	var w: Dictionary = Data.WORLDS[wid]
	var m: Dictionary = Data.MOBS[e[0]]
	if m.get("invulnerable", false):
		return 0.0
	var r := attack_range(best_weapon())
	var my_def := stat("def")
	var mult: float = w.get("mult", 1.0) if w.get("kind", "") == "explore" else 1.0
	var hp_r: Array = w.get("hp", {}).get(e[0], m.hp)
	var hp := (float(hp_r[0]) + float(hp_r[1])) / 2.0 * (float(e[2]) if e.size() > 2 else 1.0) * mult
	var hit := maxi(1, int(round(float(m.dmg) * (float(e[3]) if e.size() > 3 else 1.0) * mult)))
	var pen: Array = w.get("def_penalty", [])
	if pen.size() == 2 and my_def < int(pen[0]):
		hit += int(pen[1])
	var taken := 0.0 # the average hit after your defense
	for b in my_def + 1:
		taken += maxf(0, hit - b)
	taken /= my_def + 1
	var hits_to_win := hp / ((r.x + r.y) / 2.0)
	if hits_to_win > MINI_BOSS_HITS and not for_test:
		return 0.0 # a mini-boss like the Hand: one to walk away from, not what the world is like
	var hits_to_faint := max_hp() / maxf(0.01, taken)
	var f := 1.0
	if m.ai == "fly":
		f = 2.0
	elif m.ai == "charge":
		f = 0.3
	elif float(m.get("speed", 30)) < 25:
		f = 0.5
	return hits_to_win / hits_to_faint * f

## Whether one of Data.GOALS is done.
func goal_done(g: Dictionary) -> bool:
	var d: Dictionary = g.done
	if d.has("quest"):
		return d.quest in quests_done
	if d.has("flag"):
		return flags.get(d.flag, false)
	if d.has("slot"):
		return equip.get(d.slot, "") != ""
	if d.has("day"):
		return best_survival_day >= int(d.day)
	if d.has("tier"):
		return best_tier(d.tier[0]) >= int(d.tier[1])
	return false

## The best tool of a kind (axe or pick) in your bag.
func best_tier(kind: String) -> int:
	var best := 0
	for s in inv:
		if s and Data.ITEMS[s.id].get("type", "") == kind:
			best = maxi(best, int(Data.ITEMS[s.id].get("tier", 0)))
	return best

## The goal to show on the HUD: the first one after the last one you've done
## (so older saves skip the early ones), then Miffie's next quest. Returns
## {"text", "help", "progress", "index"}, or {} when nothing is left.
func current_goal() -> Dictionary:
	var last := -1
	for i in Data.GOALS.size():
		if goal_done(Data.GOALS[i]):
			last = i
	for i in range(last + 1, Data.GOALS.size()):
		var g: Dictionary = Data.GOALS[i]
		if goal_done(g):
			continue
		var out := {"text": g.text, "help": g.help, "progress": "", "index": i}
		if g.has("count"):
			out.progress = "%d/%d" % [mini(count(g.count[0]), int(g.count[1])), int(g.count[1])]
		return out
	var q := next_quest("mira")
	if not q.is_empty():
		var id: String = q.need.keys()[0]
		var n := int(q.need[id])
		return {"text": "Miffie wants %d %s" % [n, Data.ITEMS[id].name], "help": q.text, "progress": "%d/%d" % [mini(count(id), n), n], "index": Data.GOALS.size() + quests_done.size()}
	return {}

func next_quest(npc: String) -> Dictionary:
	for q in Data.QUESTS:
		if q.npc == npc and not q.id in quests_done:
			return q
	if npc == "mira":
		var b := Data.bounty_quest(today())
		if not b.id in quests_done:
			return b
	return {}

func quest_ready(q: Dictionary) -> bool:
	return has_all(q.need)

func complete_quest(q: Dictionary) -> void:
	take_all(q.get("take", q.need)) # a couple of Miffie's quests check for 10 but take 5
	for id in q.reward:
		give(id, q.reward[id])
	if q.has("coins"):
		coins += int(q.coins)
	if q.has("unlock"):
		flags[q.unlock] = true
	quests_done.append(q.id)
	check_character_tasks()
	Sfx.play("quest", 0.0)
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
		"v": VERSION, "inv": inv, "storage": storage, "equip": equip, "sel": sel, "coins": coins, "gems": gems, "hp": hp, "mp": mp, "st": st,
		"flags": flags, "quests": quests_done, "furnaces": furnaces, "incubator": incubator, "soils": soils,
		"reward_chests": reward_chests, "now": now(), "clock": clock, "day": day, "best_survival_day": best_survival_day, "look": look, "name": player_name, "token": online_token,
		"friends": friend_names,
	}
	_write_slot(slot, data)

## Writes a save: a new file first, keeping the last good save as a backup,
## then the new one is swapped in, so a crash or power cut mid-save can never
## wipe a character.
func _write_slot(i: int, data: Dictionary) -> void:
	var path := slot_path(i)
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(_abs(path), _abs(backup_path(i)))
		DirAccess.remove_absolute(_abs(path))
	DirAccess.rename_absolute(_abs(path + ".tmp"), _abs(path))

func slot_path(i: int) -> String:
	return "user://slot%d.json" % i

## The save before the last one, used if the newest file is ever damaged.
func backup_path(i: int) -> String:
	return "user://slot%d.bak.json" % i

func _abs(p: String) -> String:
	return ProjectSettings.globalize_path(p)

func has_save() -> bool:
	return FileAccess.file_exists(slot_path(slot))

## A slot's save: the newest file, or the backup if the newest is damaged or
## half-written. A damaged file is kept as slotN.damaged.json, never just dropped.
func _read_slot(i: int):
	for p in [slot_path(i), backup_path(i), slot_path(i) + ".tmp"]:
		var d = _parse_save(p)
		if d != null:
			return d
		if p == slot_path(i) and FileAccess.file_exists(p) and not FileAccess.file_exists("user://slot%d.damaged.json" % i):
			DirAccess.copy_absolute(_abs(p), _abs("user://slot%d.damaged.json" % i))
	return null

func _parse_save(p: String):
	if not FileAccess.file_exists(p):
		return null
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return null
	var d = JSON.parse_string(f.get_as_text())
	# older saves load too: every field has a default
	if typeof(d) != TYPE_DICTIONARY or not d.has("inv"):
		return null
	return d

## What the main menu shows for a slot: name, look and day, or empty if it's free.
func slot_info(i: int) -> Dictionary:
	var d = _read_slot(i)
	if d == null:
		return {}
	return {"name": str(d.get("name", "Player")), "look": str(d.get("look", "man_in_suit")), "day": int(d.get("day", 1)), "token": str(d.get("token", ""))}

## Names used by this device's other character slots (each name only once).
func name_in_other_slot(pname: String) -> bool:
	for i in SLOTS:
		if i != slot and str(slot_info(i).get("name", "")).to_lower() == pname.to_lower():
			return true
	return false

func delete_slot(i: int) -> void:
	var token: String = slot_info(i).get("token", "")
	if token != "":
		Online.release(token) # free the name for someone else
	for p in [slot_path(i), backup_path(i), slot_path(i) + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(_abs(p))

func default_name() -> String:
	return "Player_%d" % randi_range(100000000, 999999999)

func load_game() -> bool:
	var d = _read_slot(slot)
	if d == null:
		return false
	new_game()
	inv.clear()
	inv.resize(BAG)
	var saved: Array = _arr(d, "inv")
	for i in mini(saved.size(), BAG):
		inv[i] = _stack(saved[i])
	var saved_storage: Array = _arr(d, "storage")
	for b in mini(saved_storage.size(), BACKPACKS):
		var page: Array = saved_storage[b] if saved_storage[b] is Array else []
		for k in mini(page.size(), BACKPACK_SLOTS):
			storage[b][k] = _stack(page[k])
	var eq: Dictionary = _dict(d, "equip")
	for slot in EQUIP_SLOTS:
		var id := str(eq.get(slot, ""))
		equip[slot] = id if Data.ITEMS.has(id) else ""
	sel = clampi(int(d.get("sel", 0)), 0, HOTBAR - 1)
	coins = maxi(0, int(d.get("coins", 0)))
	gems = maxi(0, int(d.get("gems", 0)))
	flags = _dict(d, "flags")
	quests_done = _arr(d, "quests")
	var fs: Array = _arr(d, "furnaces")
	for i in mini(fs.size(), Data.FURNACES):
		furnaces[i] = fs[i] if fs[i] is Dictionary and Data.ITEMS.has(str(fs[i].get("out", ""))) else null
	incubator = _dict(d, "incubator")
	if not incubator.is_empty() and not Data.EGG_PETS.has(str(incubator.get("egg", ""))):
		incubator = {}
	var ss: Array = _arr(d, "soils")
	for i in mini(ss.size(), 5):
		soils[i] = ss[i] if ss[i] is Dictionary and Data.SEED_LOOT.has(str(ss[i].get("seed", ""))) else null
	reward_chests = _dict(d, "reward_chests")
	# the device clock is only read when the game starts, so quitting to the menu
	# and loading again can't pick up a changed clock either
	_no_rewind(float(d.get("now", 0.0)))
	clock = 0.0 # entering Pixel Town from the menu always starts at morning
	day = int(d.get("day", 1))
	best_survival_day = int(d.get("best_survival_day", 0))
	look = str(d.get("look", "man_in_suit"))
	player_name = str(d.get("name", "Player"))
	online_token = str(d.get("token", ""))
	friend_names = Array(d.get("friends", [])).filter(func(f): return typeof(f) == TYPE_STRING)
	if not Data.CHARACTERS.has(look):
		look = "man_in_suit"
	hp = clampf(float(d.get("hp", max_hp())), 1, max_hp())
	mp = float(d.get("mp", max_mp()))
	st = float(d.get("st", max_st()))
	clamp_stats()
	inventory_changed.emit()
	return true

# a damaged save can hold anything; these only let through what makes sense
func _arr(d: Dictionary, k: String) -> Array:
	return d[k] if d.get(k) is Array else []

func _dict(d: Dictionary, k: String) -> Dictionary:
	return d[k] if d.get(k) is Dictionary else {}

func _stack(s):
	if s is Dictionary and Data.ITEMS.has(str(s.get("id", ""))) and int(s.get("n", 0)) > 0:
		return {"id": str(s.id), "n": int(s.n)}
	return null

## Use a character item: you take on its look, and some characters come with a weapon.
func use_character(i: int) -> String:
	var s = inv[i]
	if s == null or Data.ITEMS[s.id].type != "character":
		return ""
	var it: Dictionary = Data.ITEMS[s.id]
	var new_id: String = s.id
	if look == new_id:
		return "You're already the %s." % it.name
	remove_at(i, 1)
	# you don't lose the character you were: it goes back in the bag
	var old_id := look
	if old_id != new_id and Data.ITEMS.has(old_id):
		give(old_id, 1)
	look = it.look
	clamp_stats()
	stats_changed.emit()
	var msg := "You're now the %s!" % it.name
	# a character's weapon comes with it once, so swapping back and forth can't farm it
	if it.gives != "" and not flags.get("gave_" + new_id, false):
		flags["gave_" + new_id] = true
		give(it.gives, 1)
		msg += " You got a %s." % Data.ITEMS[it.gives].name
	inventory_changed.emit()
	return msg

# ---------------------------------------------------------------- storage
## Moves a whole stack from one list of slots to another, stacking onto what's
## already there first. Returns how many didn't fit.
func _move_stack(from: Array, i: int, to: Array) -> int:
	var s = from[i]
	if s == null:
		return 0
	var left: int = s.n
	var cap := stack_size(s.id)
	for k in to.size():
		if left > 0 and to[k] and to[k].id == s.id and to[k].n < cap:
			var put := mini(left, cap - int(to[k].n))
			to[k].n += put
			left -= put
	for k in to.size():
		if left > 0 and to[k] == null:
			var put := mini(left, cap)
			to[k] = {"id": s.id, "n": put}
			left -= put
	from[i] = null if left <= 0 else {"id": s.id, "n": left}
	inventory_changed.emit()
	return left

## Puts items straight into Banka's storage (for rewards earned while you can't
## pick anything up). Returns how many didn't fit anywhere.
func stash(id: String, n: int) -> int:
	for b in storage:
		if n <= 0:
			break
		n = _move_stack([{"id": id, "n": n}], 0, b)
	return n

## How many of an item sit in Banka's storage.
func in_storage(id: String) -> int:
	var t := 0
	for b in storage:
		for s in b:
			if s and s.id == id:
				t += int(s.n)
	return t

## Bag slot i into backpack b.
func store(i: int, b: int) -> int:
	return _move_stack(inv, i, storage[b])

## Backpack b's slot k back into the bag.
func retrieve(b: int, k: int) -> int:
	return _move_stack(storage[b], k, inv)


# ---------------------------------------------------------------- unlocked characters
# Like the original, a new character can only be the Man in Suit or the Nurse at
# first. Owning a character in any save (from a quest, a chest, a monster or the
# Gem Shop) or finishing its task in Data.CHARACTER_TASKS unlocks it for good,
# for every slot on this device.
const UNLOCKS_PATH := "user://unlocks.json"
var unlocked: Array = []

func load_unlocks() -> void:
	unlocked = Data.START_CHARACTERS.duplicate()
	if not FileAccess.file_exists(UNLOCKS_PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(UNLOCKS_PATH))
	if d is Dictionary and d.get("characters") is Array:
		for c in d.characters:
			if Data.CHARACTERS.has(str(c)) and not str(c) in unlocked:
				unlocked.append(str(c))

func _save_unlocks() -> void:
	var f := FileAccess.open(UNLOCKS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"characters": unlocked}))

func is_unlocked(c: String) -> bool:
	return c in unlocked

## Unlocks a character for new characters. Returns false if it already was.
func unlock_character(c: String) -> bool:
	if is_unlocked(c) or not Data.CHARACTERS.has(c):
		return false
	unlocked.append(c)
	_save_unlocks()
	message.emit("%s unlocked! You can pick it for a new character." % Data.CHARACTERS[c].name, "good")
	return true

## Locks everything again but the starters (used by the tests).
func reset_unlocks() -> void:
	unlocked = Data.START_CHARACTERS.duplicate()
	_save_unlocks()

func character_task_done(t: Dictionary) -> bool:
	if t.has("survive"):
		return best_survival_day >= int(t.survive)
	if t.has("clear"):
		return flags.get("cleared_" + str(t.clear), false)
	if t.has("quest"):
		return str(t.quest) in quests_done
	return false

## Unlocks any character whose task is now done, and puts one in your bag.
func check_character_tasks() -> void:
	for c in Data.CHARACTER_TASKS:
		if not is_unlocked(c) and character_task_done(Data.CHARACTER_TASKS[c]):
			give(c, 1) # owning it unlocks it

func arena_cleared(world_id: String) -> void:
	flags["cleared_" + world_id] = true
	check_character_tasks()

## Gems saved in a slot, so the Create a character screen can unlock one with them.
func slot_gems(i: int) -> int:
	var d = _read_slot(i)
	return maxi(0, int(d.get("gems", 0))) if d is Dictionary else 0

## The saved character with the most gems, or -1 if none has any.
func richest_slot() -> int:
	var best := -1
	for i in SLOTS:
		if slot_gems(i) > 0 and (best < 0 or slot_gems(i) > slot_gems(best)):
			best = i
	return best

## Unlocks a character with gems from the saved character that has the most.
func buy_unlock(c: String) -> bool:
	var price := int(Data.CHARACTERS.get(c, {}).get("gems", 0))
	var i := richest_slot()
	if is_unlocked(c) or price <= 0 or i < 0 or slot_gems(i) < price:
		return false
	var d: Dictionary = _read_slot(i)
	d["gems"] = int(d.get("gems", 0)) - price
	_write_slot(i, d)
	unlock_character(c)
	return true
