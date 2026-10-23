extends SceneTree
## Writes every table in data.gd to the Obsidian vault as notes in "06 Data",
## so the vault always matches the game. Run from the godot folder:
##   godot --headless --path . -s tools/vault_export.gd

const OUT := "../Pixel Wilds Vault/06 Data/"
const HEADER := "---\ntags: [data, generated]\n---\n"
const NOTE := "> [!info] Made from the game\n> Written by `godot/tools/vault_export.gd` from `scripts/data.gd`. Don't edit it here: change the game and run the export again.\n\n"

var D

func _initialize() -> void:
	D = load("res://scripts/data.gd").new()
	D._build_mobs()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://").path_join(OUT))
	_items()
	_monsters()
	_worlds()
	_recipes()
	_crafter()
	_smelting()
	_resources()
	_shops()
	_chests()
	_quests()
	_characters()
	_pets()
	_index()
	print("vault export done")
	quit()

func _write(file: String, title: String, body: String) -> void:
	var f := FileAccess.open(ProjectSettings.globalize_path("res://").path_join(OUT + file + ".md"), FileAccess.WRITE)
	f.store_string(HEADER + "# " + title + "\n\n" + NOTE + body)
	f.close()

func _n(id: String) -> String:
	if id == "coin":
		return "Pixel Coins"
	return D.ITEMS[id].name if D.ITEMS.has(id) else id.capitalize()

func _cell(s) -> String:
	return str(s).replace("|", "/").replace("\n", " ")

func _pct(p: float) -> String:
	var v := p * 100.0
	if absf(v - round(v)) < 0.001:
		return "%d%%" % int(round(v))
	return ("%.1f%%" % v) if v >= 1.0 else ("%.2f%%" % v)

func _amount(a: int, b: int) -> String:
	return str(a) if a == b else "%d–%d" % [a, b]

func _cost(c: Dictionary) -> String:
	var parts := []
	for k in c:
		parts.append("%d %s" % [c[k], _n(k)])
	return ", ".join(parts)

func _drops(list: Array) -> String:
	var parts := []
	for d in list:
		parts.append("%s %s (%s)" % [_n(d[0]), _pct(d[1]), _amount(d[2], d[3])])
	return ", ".join(parts)

func _items() -> void:
	var by_type := {}
	for id in D.ITEMS:
		var t: String = D.ITEMS[id].type
		if not by_type.has(t):
			by_type[t] = []
		by_type[t].append(id)
	var body := "%d items. Stats are the extra numbers each item carries (dmg attack, spd seconds per swing, def defense, hp/mp/st health/mana/stamina, and so on).\n\n" % D.ITEMS.size()
	var types := by_type.keys()
	types.sort()
	for t in types:
		body += "## %s (%d)\n\n| Item | id | Sell | Stats | Description |\n|---|---|---|---|---|\n" % [String(t).capitalize(), by_type[t].size()]
		for id in by_type[t]:
			var it: Dictionary = D.ITEMS[id]
			var st := []
			for k in it:
				if not k in ["name", "type", "sell", "desc", "look", "color", "icon"]:
					st.append("%s %s" % [k, it[k]])
			body += "| %s | `%s` | %d | %s | %s |\n" % [_cell(it.name), id, it.sell, _cell(", ".join(st)), _cell(it.desc)]
		body += "\n"
	_write("Items", "Items", body)

func _monsters() -> void:
	var where := {}
	for w in D.WORLDS:
		for m in D.WORLDS[w].get("mobs", []):
			if not where.has(m[0]):
				where[m[0]] = []
			where[m[0]].append(D.WORLDS[w].name)
		for b in D.WORLDS[w].get("bosses", []):
			var bid: String = b if b is String else b[0]
			if not where.has(bid):
				where[bid] = []
			where[bid].append(D.WORLDS[w].name + " (boss)")
	var body := "%d monsters. HP is a range when it varies. Drops: item, chance, amount.\n\n| Monster | id | HP | Hit | Moves | Boss | Found in | Drops |\n|---|---|---|---|---|---|---|---|\n" % D.MOBS.size()
	for id in D.MOBS:
		var m: Dictionary = D.MOBS[id]
		body += "| %s | `%s` | %s | %d | %s | %s | %s | %s |\n" % [_cell(m.name), id, _amount(m.hp[0], m.hp[1]), m.dmg, m.ai,
			"yes" if m.get("boss", false) else "", _cell(", ".join(where.get(id, []))), _cell(_drops(m.drops))]
	_write("Monsters", "Monsters", body)

func _worlds() -> void:
	var body := "Monsters: each one's share of the spawns (a world places its *count* monsters, or keeps up to *cap* in an arena). A rare one like King at 0.3 weight is a small share, not zero. ×1.5 hp / ×6.3 hit are that world's health and damage multipliers.\n\n| World | id | Kind | Theme | Next | Monsters (share of spawns) | Bosses (arena) | Resources (share) |\n|---|---|---|---|---|---|---|---|\n"
	for id in D.WORLDS:
		var w: Dictionary = D.WORLDS[id]
		var mobs := []
		var total := 0.0
		for m in w.get("mobs", []):
			total += float(m[1])
		for m in w.get("mobs", []):
			var extra := ""
			if m.size() > 2 and float(m[2]) != 1.0:
				extra += " ×%s hp" % m[2]
			if m.size() > 3 and float(m[3]) != 1.0:
				extra += " ×%s hit" % m[3]
			mobs.append("%s %s%s" % [D.MOBS[m[0]].name if D.MOBS.has(m[0]) else m[0], _pct(float(m[1]) / total), extra])
		var bosses := []
		for b in w.get("bosses", []):
			bosses.append(D.MOBS[b[0]].name if D.MOBS.has(b[0]) else b[0])
		var nodes := []
		var ntotal := 0.0
		for n in w.get("nodes", []):
			ntotal += float(n[1])
		for n in w.get("nodes", []):
			nodes.append("%s %s" % [n[0], _pct(float(n[1]) / ntotal)])
		body += "| %s | `%s` | %s | %s | %s | %s | %s | %s |\n" % [_cell(w.name), id, w.get("kind", ""), w.get("theme", ""), w.get("next", ""), _cell(", ".join(mobs)), _cell(", ".join(bosses)), _cell(", ".join(nodes))]
	body += "\n## Gatekeeper cards (in order)\n\n| # | World | Text |\n|---|---|---|\n"
	var i := 1
	for c in D.WORLD_CARDS:
		body += "| %d | %s | %s |\n" % [i, c[1], c[2]]
		i += 1
	_write("World Data", "World Data", body)

func _recipes() -> void:
	var by_book := {}
	for r in D.RECIPES:
		var b: String = r.get("book", "none")
		if not by_book.has(b):
			by_book[b] = []
		by_book[b].append(r)
	var body := "Combining in the bag. The book in your bag adds +%d%%, a Combination Scroll +%d%%.\n\n" % [D.BOOK_BONUS, D.SCROLL_BONUS]
	for b in by_book:
		body += "## %s (%d)\n\n| Makes | From | Base chance |\n|---|---|---|\n" % [_n(D.BOOK_ITEM.get(b, b)) if D.BOOK_ITEM.has(b) else String(b).capitalize(), by_book[b].size()]
		for r in by_book[b]:
			var ins := []
			for x in r["in"]:
				ins.append(_n(x))
			body += "| %s | %s | %d%% |\n" % [_n(r.out), " + ".join(ins), r.rate]
		body += "\n"
	_write("Combinations", "Combinations", body)

func _crafter() -> void:
	var body := "Everything the Crafter makes (%d).\n\n| Makes | Costs |\n|---|---|\n" % D.SMITH.size()
	for s in D.SMITH:
		body += "| %s | %s |\n" % [_n(s.out), _cost(s.cost)]
	_write("Crafter Recipes", "Crafter Recipes", body)

func _smelting() -> void:
	var body := "| Bar | Costs | Seconds |\n|---|---|---|\n"
	for s in D.SMELT:
		body += "| %s | %s | %d |\n" % [_n(s.out), _cost(s.cost), s.time]
	_write("Smelting", "Smelting", body)

func _resources() -> void:
	var body := "Trees, rocks, ores and plants. Tool tier needed, hits to break, and drops.\n\n| Resource | Tool | Min tier | Hits | Drops |\n|---|---|---|---|---|\n"
	for id in D.NODES:
		var n: Dictionary = D.NODES[id]
		body += "| %s | %s | %s | %s | %s |\n" % [id.capitalize(), n.get("tool", ""), n.get("min", ""), n.get("hits", ""), _cell(_drops(n.get("drops", [])))]
	_write("Resources", "Resources", body)

func _shops() -> void:
	var body := "1 gem costs %d Pixel Coins.\n\n" % D.GEM_PRICE
	for id in D.SHOPS:
		var s: Dictionary = D.SHOPS[id]
		var cur: String = _n(s.get("currency", "coin"))
		body += "## %s\n\n| Item | Price (%s) |\n|---|---|\n" % [s.title, cur]
		for e in s.sells:
			body += "| %s | %d |\n" % [_n(e[0]), e[1]]
		body += "\nBuys your items: %s\n\n" % ("yes" if s.get("buys", false) else "no")
	_write("Shops", "Shops", body)

func _loot(list: Array) -> String:
	var body := "| Item | Amount | Chance if picked |\n|---|---|---|\n"
	for e in list:
		body += "| %s | %s | %s |\n" % [_n(e[0]), _amount(e[1], e[2]), _pct(e[3]) if e.size() > 3 else "100%"]
	return body

func _chests() -> void:
	var body := ""
	for id in D.CHESTS:
		var c: Dictionary = D.CHESTS[id]
		body += "## %s\n\nOpens with: %s · picks %d times from:\n\n%s\n" % [c.name, _n(c.key), c.rolls, _loot(c.loot)]
	for id in D.SEED_LOOT:
		body += "## %s (magic soil harvest)\n\n%s\n" % [_n(id), _loot(D.SEED_LOOT[id])]
	_write("Chests and Seeds", "Chests and Seeds", body)

func _quests() -> void:
	var body := "%d quests, in order.\n\n| # | Who | Needs | Gives | Says |\n|---|---|---|---|---|\n" % D.QUESTS.size()
	var i := 1
	for q in D.QUESTS:
		var who: String = D.NPCS[q.npc].name if D.NPCS.has(q.npc) else q.npc
		body += "| %d | %s | %s | %s | %s |\n" % [i, who, _cost(q.need), _cost(q.reward) if not q.reward.is_empty() else q.get("unlock", ""), _cell(q.text)]
		i += 1
	_write("Quests", "Quests", body)

func _characters() -> void:
	var body := "| Character | Gems | Gives | Stats |\n|---|---|---|---|\n"
	for id in D.CHARACTERS:
		var c: Dictionary = D.CHARACTERS[id]
		var st := []
		for k in c.get("stats", {}):
			st.append("%s +%s" % [k, c.stats[k]])
		body += "| %s | %d | %s | %s |\n" % [c.name, c.get("gems", 0), _n(c.gives) if c.has("gives") else "", ", ".join(st)]
	_write("Character Data", "Character Data", body)

func _pets() -> void:
	var body := "| Pet | Every (s) | Does |\n|---|---|---|\n"
	for id in D.PETS:
		var p: Dictionary = D.PETS[id]
		var does := []
		for k in ["dmg", "hp", "mp", "st"]:
			if p.has(k):
				does.append({"dmg": "hits for %s", "hp": "+%s health", "mp": "+%s mana", "st": "+%s stamina"}[k] % p[k])
		body += "| %s | %s | %s |\n" % [p.name, p.get("every", ""), ", ".join(does)]
	_write("Pets", "Pets", body)

func _index() -> void:
	var body := "Every number in the game, exported from `scripts/data.gd`.\n\n"
	for n in ["Items", "Monsters", "World Data", "Combinations", "Crafter Recipes", "Smelting", "Resources", "Shops", "Chests and Seeds", "Quests", "Character Data", "Pets"]:
		body += "- [[%s]]\n" % n
	body += "\nWhich numbers are real and which are estimates: [[Numbers and Estimates]].\n"
	_write("Game Data", "Game Data", body)
