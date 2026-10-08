extends CanvasLayer
## On-screen interface: hotbar and bars, clock, touch buttons, and every menu
## (bag and crafting, talking, shop, world map, pause, title, fainting).

var main: Node
var root: Control
var ui_theme: Theme
var hotbar_slots: Array = []
var bars: Control
var clock: Control
var coin_label: Label
var day_label: Label
var toasts: VBoxContainer
var boss_box: Control
var boss: Node = null
var hint_label: Label
var touch_nodes: Array = []
var hud_root: Control
var force_touch := false

var panels := {}
var bag_slots: Array = []
var equip_slots := {}
var bag_sel := -1
var move_from := -1
var combo := [-1, -1]
var info_box: VBoxContainer
var combo_box: Control
var stats_label: Label
var dialog_npc: Dictionary

const C_BG := Color("221d2e")
const C_BG2 := Color("2d2640")
const C_EDGE := Color("4a3e64")
const C_INK := Color("f3ecd9")
const C_MUTED := Color("a69cba")
const C_EMBER := Color("f2a33a")
const C_DARK := Color("1b1a24")

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_theme()
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = ui_theme
	add_child(root)
	_build_hud()
	_build_touch()
	_build_bag()
	_build_simple_panels()
	GS.inventory_changed.connect(_refresh)
	GS.stats_changed.connect(_refresh_stats)
	GS.message.connect(toast)
	get_viewport().size_changed.connect(_layout_touch)
	_layout_touch()
	_refresh()

# ---------------------------------------------------------------- theme
func _box(bg: Color, edge: Color, border: int = 2, pad: int = 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(border)
	s.set_content_margin_all(pad)
	return s

func _make_theme() -> void:
	ui_theme = Theme.new()
	ui_theme.default_font = Art.font_body
	ui_theme.default_font_size = 10
	ui_theme.set_color("font_color", "Label", C_INK)
	ui_theme.set_stylebox("panel", "Panel", _box(C_BG, C_EDGE, 2, 6))
	ui_theme.set_stylebox("panel", "PanelContainer", _box(C_BG, C_EDGE, 2, 6))
	ui_theme.set_stylebox("normal", "Button", _box(C_BG2, C_EDGE, 1, 3))
	ui_theme.set_stylebox("hover", "Button", _box(Color("3a3150"), C_EMBER, 1, 3))
	ui_theme.set_stylebox("pressed", "Button", _box(Color("4a3e64"), C_EMBER, 1, 3))
	ui_theme.set_stylebox("disabled", "Button", _box(Color("1e1a28"), Color("2d2640"), 1, 3))
	ui_theme.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), C_INK, 1, 3))
	ui_theme.set_color("font_color", "Button", C_INK)
	ui_theme.set_color("font_hover_color", "Button", Color.WHITE)
	ui_theme.set_color("font_disabled_color", "Button", Color("6a6080"))
	ui_theme.set_font_size("font_size", "Button", 10)
	ui_theme.set_type_variation("Accent", "Button")
	ui_theme.set_stylebox("normal", "Accent", _box(C_EMBER, Color("8a4a12"), 1, 3))
	ui_theme.set_stylebox("hover", "Accent", _box(Color("ffb850"), Color("8a4a12"), 1, 3))
	ui_theme.set_stylebox("pressed", "Accent", _box(Color("d8862a"), Color("8a4a12"), 1, 3))
	ui_theme.set_color("font_color", "Accent", Color("2a1606"))
	ui_theme.set_color("font_hover_color", "Accent", Color("2a1606"))
	ui_theme.set_color("font_pressed_color", "Accent", Color("2a1606"))

func _label(text: String, size: int = 10, color: Color = C_INK, title: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if title:
		l.add_theme_font_override("font", Art.font_title)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _button(text: String, cb: Callable, accent: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	if accent:
		b.theme_type_variation = "Accent"
	b.pressed.connect(cb)
	return b

func _slot(size: int = 22) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(size, size)
	b.focus_mode = Control.FOCUS_NONE
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	var n := _label("", 8, C_INK, true)
	n.name = "Count"
	n.add_theme_color_override("font_outline_color", C_DARK)
	n.add_theme_constant_override("outline_size", 3)
	n.position = Vector2(size - 15, size - 12)
	n.size = Vector2(13, 10)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_child(n)
	return b

func _fill_slot(b: Button, s) -> void:
	var icon: TextureRect = b.get_node("Icon")
	var n: Label = b.get_node("Count")
	if s:
		icon.texture = Art.icon(s.id)
		n.text = str(s.n) if s.n > 1 else ""
		b.tooltip_text = Data.ITEMS[s.id].name
	else:
		icon.texture = null
		n.text = ""
		b.tooltip_text = ""

func _select_style(b: Button, on: bool, color: Color = C_EMBER) -> void:
	if on:
		b.add_theme_stylebox_override("normal", _box(Color("3a3150"), color, 2, 3))
	else:
		b.remove_theme_stylebox_override("normal")

# ---------------------------------------------------------------- HUD
func _build_hud() -> void:
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud_root)
	var hb := HBoxContainer.new()
	hb.position = Vector2(4, 4)
	hb.add_theme_constant_override("separation", 2)
	hud_root.add_child(hb)
	for i in GS.HOTBAR:
		var b := _slot(22)
		var idx := i
		b.pressed.connect(func(): GS.sel = idx; GS.inventory_changed.emit())
		hb.add_child(b)
		hotbar_slots.append(b)

	bars = Control.new()
	bars.position = Vector2(4, 30)
	bars.size = Vector2(90, 32)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.draw.connect(_draw_bars)
	hud_root.add_child(bars)

	clock = Control.new()
	clock.set_anchors_preset(Control.PRESET_CENTER_TOP)
	clock.position = Vector2(-16, 2)
	clock.size = Vector2(32, 32)
	clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock.draw.connect(_draw_clock)
	hud_root.add_child(clock)
	day_label = _label("Day 1", 8, C_INK, true)
	day_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	day_label.position = Vector2(-30, 34)
	day_label.size = Vector2(60, 10)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.add_theme_color_override("font_outline_color", C_DARK)
	day_label.add_theme_constant_override("outline_size", 3)
	hud_root.add_child(day_label)

	var coin_box := HBoxContainer.new()
	coin_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	coin_box.position = Vector2(22, 10)
	coin_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ci := TextureRect.new()
	ci.texture = Art.prop_tex("coin")
	ci.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	coin_box.add_child(ci)
	coin_label = _label("0", 10, Color("f2cf5b"), true)
	coin_label.add_theme_color_override("font_outline_color", C_DARK)
	coin_label.add_theme_constant_override("outline_size", 3)
	coin_box.add_child(coin_label)
	hud_root.add_child(coin_box)

	var tr := HBoxContainer.new()
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.position = Vector2(-62, 4)
	tr.add_theme_constant_override("separation", 3)
	hud_root.add_child(tr)
	var bag_btn := _button("Bag", func(): toggle_bag())
	bag_btn.custom_minimum_size = Vector2(32, 22)
	tr.add_child(bag_btn)
	var pause_btn := _button("II", func(): open_panel("pause"))
	pause_btn.custom_minimum_size = Vector2(22, 22)
	tr.add_child(pause_btn)

	boss_box = Control.new()
	boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_box.position = Vector2(-90, 46)
	boss_box.size = Vector2(180, 18)
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.draw.connect(_draw_boss)
	boss_box.visible = false
	hud_root.add_child(boss_box)

	toasts = VBoxContainer.new()
	toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toasts.position = Vector2(-130, 70)
	toasts.size = Vector2(260, 60)
	toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.add_theme_constant_override("separation", 2)
	hud_root.add_child(toasts)

	hint_label = _label("A/D move   K jump (B)   J use (A)   E bag   1-5 hotbar", 8, C_INK)
	hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.position = Vector2(-150, -14)
	hint_label.size = Vector2(300, 10)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_outline_color", C_DARK)
	hint_label.add_theme_constant_override("outline_size", 3)
	hud_root.add_child(hint_label)

func _draw_bars() -> void:
	var rows := [
		[GS.hp, GS.max_hp(), Color("e2453a"), Color("8a1e1a")],
		[GS.mana, GS.max_mana(), Color("3b6fd9"), Color("1e3a8a")],
		[GS.stamina, GS.max_stamina(), Color("4fb83a"), Color("2a6a1e")],
	]
	var f: Font = Art.font_title
	for i in rows.size():
		var r: Array = rows[i]
		var y := i * 11
		var w := 88.0
		bars.draw_rect(Rect2(0, y, w + 2, 10), C_DARK)
		bars.draw_rect(Rect2(1, y + 1, w, 8), r[3])
		var k := clampf(r[0] / maxf(r[1], 1.0), 0, 1)
		bars.draw_rect(Rect2(1, y + 1, w * k, 8), r[2])
		bars.draw_rect(Rect2(1, y + 1, w * k, 2), r[2].lightened(0.3))
		var text := "%d/%d" % [int(ceil(r[0])), int(r[1])]
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		bars.draw_string_outline(f, Vector2(1 + (w - tw) / 2, y + 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, C_DARK)
		bars.draw_string(f, Vector2(1 + (w - tw) / 2, y + 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

func _draw_clock() -> void:
	var c := Vector2(16, 16)
	clock.draw_circle(c, 15, C_DARK)
	clock.draw_circle(c, 14, Color("b85e1c"))
	var sky := Color("6fb6dc").lerp(Color("1e2a5a"), GS.darkness())
	clock.draw_circle(c, 12, sky)
	clock.draw_rect(Rect2(4, 17, 24, 11), Color("3e8a2e").lerp(Color("1e3a2a"), GS.darkness()))
	var a := GS.clock * TAU - PI
	var sun := c + Vector2(cos(a), sin(a)) * 8
	var moon := c - Vector2(cos(a), sin(a)) * 8
	clock.draw_circle(sun, 3, Color("f2cf5b"))
	clock.draw_circle(moon, 2.5, Color("e8eef2"))
	clock.draw_arc(c, 13, 0, TAU, 32, C_DARK, 1)

func _draw_boss() -> void:
	if not is_instance_valid(boss) or boss.dead:
		return
	var f: Font = Art.font_title
	var name: String = boss.def.name
	var tw := f.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	boss_box.draw_string_outline(f, Vector2(90 - tw / 2, 7), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, C_DARK)
	boss_box.draw_string(f, Vector2(90 - tw / 2, 7), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, C_INK)
	boss_box.draw_rect(Rect2(0, 10, 180, 7), C_DARK)
	boss_box.draw_rect(Rect2(1, 11, 178 * clampf(boss.hp / boss.max_hp, 0, 1), 5), Color("e2453a"))
	var t := "%d / %d" % [int(boss.hp), int(boss.max_hp)]
	var w2 := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	boss_box.draw_string(f, Vector2(90 - w2 / 2, 17), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

func set_boss(b: Node) -> void:
	boss = b
	boss_box.visible = b != null

func _process(_d: float) -> void:
	clock.queue_redraw()
	day_label.text = "Day %d" % GS.day
	if boss_box.visible:
		boss_box.queue_redraw()
		if not is_instance_valid(boss):
			set_boss(null)

func _refresh_stats() -> void:
	bars.queue_redraw()
	coin_label.text = str(GS.coins)

func _refresh() -> void:
	for i in GS.HOTBAR:
		_fill_slot(hotbar_slots[i], GS.inv[i])
		_select_style(hotbar_slots[i], i == GS.sel)
	_refresh_stats()
	if panels.has("bag") and panels.bag.visible:
		_refresh_bag()
	if panels.has("shop") and panels.shop.visible:
		_refresh_shop()

func toast(text: String, kind: String = "") -> void:
	var p := PanelContainer.new()
	var edge := C_EDGE
	match kind:
		"good": edge = Color("5cbf3f")
		"warn": edge = Color("8a7aa0")
		"danger": edge = Color("e2453a")
		"big": edge = C_EMBER
	var sb := _box(Color(0.08, 0.07, 0.11, 0.9), edge, 1, 3)
	p.add_theme_stylebox_override("panel", sb)
	var l := _label(text, 9, C_INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(250, 0)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.add_child(p)
	while toasts.get_child_count() > 3:
		toasts.get_child(0).free()
	var tw := p.create_tween()
	tw.tween_interval(2.8)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)

# ---------------------------------------------------------------- touch controls
func _build_touch() -> void:
	var specs := [["move_left", "<", Color("5c616b"), 48, 30], ["move_right", ">", Color("5c616b"), 48, 30],
		["attack", "A", Color("c8302a"), 54, 34], ["jump", "B", Color("2e9a3a"), 54, 34]]
	for s in specs:
		var t := TouchScreenButton.new()
		t.texture_normal = Art.button_tex(s[3], s[4], s[2])
		t.texture_pressed = Art.button_tex(s[3], s[4], s[2].darkened(0.25))
		t.action = s[0]
		t.passby_press = true
		var l := _label(s[1], 14, Color.WHITE, true)
		l.size = Vector2(s[3], s[4])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_outline_color", C_DARK)
		l.add_theme_constant_override("outline_size", 3)
		t.add_child(l)
		add_child(t)
		touch_nodes.append(t)
	force_touch = "--touch" in OS.get_cmdline_user_args()
	set_touch_visible(true)
	hint_label.visible = not _touch()

func _layout_touch() -> void:
	var vs := get_viewport().get_visible_rect().size
	if touch_nodes.size() < 4:
		return
	touch_nodes[0].position = Vector2(8, vs.y - 38)
	touch_nodes[1].position = Vector2(62, vs.y - 38)
	touch_nodes[2].position = Vector2(vs.x - 62, vs.y - 80)
	touch_nodes[3].position = Vector2(vs.x - 120, vs.y - 42)

func _touch() -> bool:
	return force_touch or DisplayServer.is_touchscreen_available()

func set_touch_visible(on: bool) -> void:
	for t in touch_nodes:
		t.visible = on and _touch() and not main.on_title()

func set_hud_visible(on: bool) -> void:
	hud_root.visible = on
	set_touch_visible(on)

# ---------------------------------------------------------------- panels
func _panel(key: String, size: Vector2) -> Panel:
	var p := Panel.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.size = size
	p.position = -size / 2
	p.visible = false
	root.add_child(p)
	panels[key] = p
	return p

func any_open() -> bool:
	for k in panels:
		if panels[k].visible:
			return true
	return false

func open_panel(key: String) -> void:
	if main.on_title() and key != "title":
		return
	for k in panels:
		panels[k].visible = k == key
	main.set_paused(true)
	set_touch_visible(false)
	match key:
		"bag":
			bag_sel = -1
			move_from = -1
			_refresh_bag()
		"shop":
			_refresh_shop()
		"map":
			_refresh_map()
		"title":
			_refresh_title()

func close_panels() -> void:
	for k in panels:
		panels[k].visible = false
	main.set_paused(false)
	set_touch_visible(true)

func toggle_bag() -> void:
	if panels.bag.visible:
		close_panels()
	elif not any_open() and not main.on_title():
		open_panel("bag")

func _header(p: Control, title: String, closable: bool = true) -> void:
	var t := _label(title, 12, C_EMBER, true)
	t.position = Vector2(8, 5)
	p.add_child(t)
	if closable:
		var x := _button("X", func(): close_panels())
		x.position = Vector2(p.size.x - 24, 4)
		x.custom_minimum_size = Vector2(18, 16)
		p.add_child(x)

# ---------------------------------------------------------------- bag and combining
func _build_bag() -> void:
	var p := _panel("bag", Vector2(460, 250))
	_header(p, "Bag")
	var grid := GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(8, 24)
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	p.add_child(grid)
	for i in GS.BAG:
		var b := _slot(24)
		var idx := i
		b.pressed.connect(func(): _bag_click(idx))
		grid.add_child(b)
		bag_slots.append(b)
	var hot := _label("Top row = hotbar", 8, C_MUTED)
	hot.position = Vector2(8, 156)
	p.add_child(hot)

	var eq := VBoxContainer.new()
	eq.position = Vector2(142, 24)
	eq.add_theme_constant_override("separation", 2)
	p.add_child(eq)
	for slot in Data.EQUIP_SLOTS:
		var row := HBoxContainer.new()
		var b := _slot(24)
		var sname: String = slot
		b.pressed.connect(func(): GS.unequip(sname))
		row.add_child(b)
		row.add_child(_label(slot.capitalize(), 8, C_MUTED))
		eq.add_child(row)
		equip_slots[slot] = b
	stats_label = _label("", 8, C_INK)
	stats_label.position = Vector2(142, 132)
	stats_label.size = Vector2(80, 60)
	p.add_child(stats_label)

	# combination panel
	var cb := Panel.new()
	cb.add_theme_stylebox_override("panel", _box(Color("17141f"), C_EDGE, 1, 4))
	cb.position = Vector2(228, 24)
	cb.size = Vector2(224, 92)
	p.add_child(cb)
	combo_box = cb
	cb.add_child(_at(_label("Combine", 10, C_EMBER, true), Vector2(6, 4)))
	for i in 2:
		var b := _slot(26)
		b.name = "C%d" % i
		var ci := i
		b.pressed.connect(func(): combo[ci] = -1; _refresh_bag())
		b.position = Vector2(8 + i * 40, 22)
		cb.add_child(b)
	cb.add_child(_at(_label("+", 12, C_MUTED, true), Vector2(37, 28)))
	cb.add_child(_at(_label("=", 12, C_MUTED, true), Vector2(78, 28)))
	var out := _slot(26)
	out.name = "Out"
	out.disabled = true
	out.position = Vector2(94, 22)
	cb.add_child(out)
	var chance := _label("", 8, C_INK)
	chance.name = "Chance"
	chance.position = Vector2(126, 20)
	chance.size = Vector2(94, 34)
	chance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cb.add_child(chance)
	var go := _button("Combine", func(): _do_combine(), true)
	go.name = "Go"
	go.position = Vector2(8, 58)
	go.custom_minimum_size = Vector2(70, 18)
	cb.add_child(go)
	var why := _label("", 8, C_MUTED)
	why.name = "Why"
	why.position = Vector2(84, 56)
	why.size = Vector2(136, 34)
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cb.add_child(why)

	info_box = VBoxContainer.new()
	info_box.position = Vector2(228, 122)
	info_box.size = Vector2(224, 120)
	info_box.add_theme_constant_override("separation", 3)
	p.add_child(info_box)

func _at(c: Control, pos: Vector2) -> Control:
	c.position = pos
	return c

func _bag_click(i: int) -> void:
	if move_from >= 0:
		if move_from != i:
			GS.swap(move_from, i)
		move_from = -1
		bag_sel = i if GS.inv[i] else -1
		_refresh_bag()
		return
	bag_sel = -1 if bag_sel == i or GS.inv[i] == null else i
	_refresh_bag()

func _refresh_bag() -> void:
	for i in GS.BAG:
		_fill_slot(bag_slots[i], GS.inv[i])
		if i == move_from:
			_select_style(bag_slots[i], true, Color("6b8ff0"))
		else:
			_select_style(bag_slots[i], i == bag_sel or i == combo[0] or i == combo[1], C_EMBER if i == bag_sel else Color("5cbf3f"))
	for slot in Data.EQUIP_SLOTS:
		var id: String = GS.equip[slot]
		_fill_slot(equip_slots[slot], {"id": id, "n": 1} if id != "" else null)
	stats_label.text = "Health %d\nMana %d\nStamina %d\nBlock %d\nBonus dmg %d\nCoins %d" % [
		GS.max_hp(), GS.max_mana(), GS.max_stamina(), GS.defense(), GS.bonus_damage(), GS.coins]
	# combination
	for i in 2:
		if combo[i] >= 0 and GS.inv[combo[i]] == null:
			combo[i] = -1
		_fill_slot(combo_box.get_node("C%d" % i), GS.inv[combo[i]] if combo[i] >= 0 else null)
	var out: Button = combo_box.get_node("Out")
	var chance: Label = combo_box.get_node("Chance")
	var go: Button = combo_box.get_node("Go")
	var why: Label = combo_box.get_node("Why")
	_fill_slot(out, null)
	chance.text = ""
	go.disabled = true
	why.text = "Pick an item, then tap Combine 1 or Combine 2."
	if combo[0] >= 0 and combo[1] >= 0:
		var a: String = GS.inv[combo[0]].id
		var b: String = GS.inv[combo[1]].id
		var pv := GS.preview_combo(a, b, main.near_furnace())
		if not pv.known:
			chance.text = "Unknown"
			why.text = "These two don't make anything."
		else:
			_fill_slot(out, {"id": pv.recipe.out, "n": pv.recipe.n})
			chance.text = "%s\n%d%% chance" % [Data.ITEMS[pv.recipe.out].name, pv.chance]
			if pv.blocked != "":
				why.text = pv.blocked
			else:
				go.disabled = combo[0] == combo[1] and GS.inv[combo[0]].n < 2
				why.text = "Fails give Dust." if pv.chance < 100 else ""
				if pv.book != "" and GS.count(pv.book) == 0:
					why.text = "%s would add +%d%%." % [Data.ITEMS[pv.book].name, Data.ITEMS[pv.book].bonus]
	# selected item info
	for c in info_box.get_children():
		c.queue_free()
	if move_from >= 0:
		info_box.add_child(_wrap_label("Tap a slot to move the item there.", C_MUTED))
		return
	if bag_sel < 0 or GS.inv[bag_sel] == null:
		info_box.add_child(_wrap_label("Tap an item to see what it does. Put two items in the Combine slots to make something new.", C_MUTED))
		return
	var s = GS.inv[bag_sel]
	var it: Dictionary = Data.ITEMS[s.id]
	info_box.add_child(_label("%s%s" % [it.name, "  x%d" % s.n if s.n > 1 else ""], 10, C_EMBER, true))
	var extra := ""
	if it.has("dmg"):
		extra = "  Damage %d." % it.dmg
	if it.has("power"):
		extra += " Power %d." % it.power
	info_box.add_child(_wrap_label(it.desc + extra, C_INK))
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 3)
	row.add_theme_constant_override("v_separation", 3)
	info_box.add_child(row)
	if it.type == "food":
		row.add_child(_button("Use", func(): GS.consume(bag_sel)))
	if it.type in Data.EQUIP_SLOTS:
		row.add_child(_button("Equip", func(): GS.equip_from(bag_sel)))
	if bag_sel >= GS.HOTBAR:
		row.add_child(_button("Hold", func():
			GS.swap(bag_sel, GS.sel)
			bag_sel = GS.sel
			_refresh_bag()))
	row.add_child(_button("Combine 1", func(): combo[0] = bag_sel; _refresh_bag()))
	row.add_child(_button("Combine 2", func(): combo[1] = bag_sel; _refresh_bag()))
	row.add_child(_button("Move", func(): move_from = bag_sel; _refresh_bag()))
	row.add_child(_button("Drop", func():
		var d = GS.inv[bag_sel]
		GS.inv[bag_sel] = null
		main.drop_from_player(d.id, d.n)
		bag_sel = -1
		GS.inventory_changed.emit()))

func _wrap_label(text: String, color: Color) -> Label:
	var l := _label(text, 9, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(220, 0)
	return l

func _do_combine() -> void:
	var r := GS.combine(combo[0], combo[1], main.near_furnace())
	if not r.ok:
		toast(r.reason, "warn")
		return
	if r.success:
		toast("Success! You made %s." % Data.ITEMS[r.out].name, "good")
	else:
		toast("The combination failed. You got Dust.", "warn")
	_refresh_bag()

# ---------------------------------------------------------------- dialog, shop, map, pause, title, death
func _build_simple_panels() -> void:
	var d := _panel("dialog", Vector2(400, 110))
	_header(d, "")
	var name := _label("", 12, C_EMBER, true)
	name.name = "Name"
	name.position = Vector2(8, 5)
	d.add_child(name)
	var text := _label("", 10, C_INK)
	text.name = "Text"
	text.position = Vector2(8, 22)
	text.size = Vector2(384, 50)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_child(text)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.position = Vector2(8, 84)
	row.add_theme_constant_override("separation", 4)
	d.add_child(row)

	var s := _panel("shop", Vector2(440, 236))
	_header(s, "Tilly's Shop")
	var buy := VBoxContainer.new()
	buy.name = "Buy"
	var buy_scroll := ScrollContainer.new()
	buy_scroll.position = Vector2(8, 38)
	buy_scroll.size = Vector2(206, 190)
	buy_scroll.add_child(buy)
	s.add_child(buy_scroll)
	s.add_child(_at(_label("Buy", 10, C_MUTED, true), Vector2(8, 24)))
	var sell := VBoxContainer.new()
	sell.name = "Sell"
	var sell_scroll := ScrollContainer.new()
	sell_scroll.position = Vector2(224, 38)
	sell_scroll.size = Vector2(208, 190)
	sell_scroll.add_child(sell)
	s.add_child(sell_scroll)
	s.add_child(_at(_label("Sell", 10, C_MUTED, true), Vector2(224, 24)))

	var m := _panel("map", Vector2(440, 220))
	_header(m, "World Map")
	var tip := _wrap_label("Reach the far right of a level to unlock the next one. Each lair opens after level 8 and uses up one key per visit.", C_MUTED)
	tip.custom_minimum_size = Vector2(420, 0)
	m.add_child(_at(tip, Vector2(8, 176)))
	var cols := HBoxContainer.new()
	cols.name = "Cols"
	cols.position = Vector2(8, 26)
	cols.add_theme_constant_override("separation", 8)
	m.add_child(cols)

	var pz := _panel("pause", Vector2(200, 110))
	_header(pz, "Paused", false)
	var pv := VBoxContainer.new()
	pv.position = Vector2(30, 30)
	pv.custom_minimum_size = Vector2(140, 0)
	pv.add_theme_constant_override("separation", 6)
	pz.add_child(pv)
	pv.add_child(_button("Resume", func(): close_panels(), true))
	pv.add_child(_button("Save and quit to title", func(): main.quit_to_title()))

	var dead := _panel("dead", Vector2(240, 96))
	_header(dead, "You fainted", false)
	dead.add_child(_at(_wrap_label("You'll wake up in Pixel Village with everything still in your bag.", C_INK), Vector2(8, 26)))
	var wake := _button("Wake up", func(): main.respawn(), true)
	wake.position = Vector2(8, 66)
	dead.add_child(wake)

	var t := _panel("title", Vector2(480, 270))
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.position = Vector2.ZERO
	t.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	for i in 2:
		var title := _label(["PIXEL", "WILDS"][i], 36, C_EMBER, true)
		title.add_theme_color_override("font_shadow_color", Color("8a4a12"))
		title.add_theme_constant_override("shadow_offset_x", 3)
		title.add_theme_constant_override("shadow_offset_y", 3)
		title.add_theme_color_override("font_outline_color", C_DARK)
		title.add_theme_constant_override("outline_size", 8)
		title.position = Vector2(24, 18 + i * 40)
		t.add_child(title)
	var sub := _label("Chop, fight, combine and explore. Nothing to buy, ever.", 10, C_INK)
	sub.add_theme_color_override("font_outline_color", C_DARK)
	sub.add_theme_constant_override("outline_size", 4)
	sub.position = Vector2(26, 108)
	t.add_child(sub)
	var tv := VBoxContainer.new()
	tv.name = "Menu"
	tv.position = Vector2(26, 128)
	tv.custom_minimum_size = Vector2(130, 0)
	tv.add_theme_constant_override("separation", 5)
	t.add_child(tv)

func _refresh_title() -> void:
	var tv: VBoxContainer = panels.title.get_node("Menu")
	for c in tv.get_children():
		c.queue_free()
	if GS.has_save():
		tv.add_child(_button("Continue", func(): main.start_game(true), true))
	tv.add_child(_button("New game", func(): main.start_game(false), not GS.has_save()))

func show_dead() -> void:
	open_panel("dead")

func open_dialog(npc: Dictionary) -> void:
	dialog_npc = npc
	open_panel("dialog")
	_refresh_dialog()

func _refresh_dialog() -> void:
	var d: Panel = panels.dialog
	var npc := dialog_npc
	d.get_node("Name").text = npc.name
	var row: HBoxContainer = d.get_node("Row")
	for c in row.get_children():
		c.queue_free()
	var text: String = npc.talk
	var q := GS.next_quest(npc.id)
	if not q.is_empty():
		text = q.text
		var need := []
		for id in q.need:
			need.append("%s %d/%d" % [Data.ITEMS[id].name, GS.count(id), q.need[id]])
		if q.has("boss"):
			need.append("%s: %s" % [Data.MOBS[q.boss].name, "defeated" if q.boss in GS.bosses else "not yet"])
		var rewards := []
		for id in q.reward:
			rewards.append("%s x%d" % [Data.ITEMS[id].name, q.reward[id]])
		if q.get("coins", 0) > 0:
			rewards.append("%d coins" % q.coins)
		if q.get("unlock", "") == "furnace":
			rewards.append("the furnace")
		text += "\nNeeds: %s\nReward: %s" % [", ".join(need) if need.size() else "-", ", ".join(rewards)]
		var give := _button("Hand in", func():
			GS.complete_quest(q)
			toast("Quest complete!", "good")
			if q.get("unlock", "") == "furnace":
				main.reload_level()
			_refresh_dialog(), true)
		give.disabled = not GS.quest_ready(q)
		row.add_child(give)
	elif npc.id != "tilly":
		text += "\n(No more tasks for now.)"
	if npc.get("shop", false):
		row.add_child(_button("Shop", func(): open_panel("shop"), true))
	row.add_child(_button("Bye", func(): close_panels()))
	d.get_node("Text").text = text

func _refresh_shop() -> void:
	var s: Panel = panels.shop
	var buy: VBoxContainer = s.get_node("ScrollContainer/Buy") if s.has_node("ScrollContainer/Buy") else null
	for c in s.get_children():
		if c is ScrollContainer:
			var list: VBoxContainer = c.get_child(0)
			for k in list.get_children():
				k.queue_free()
			if list.name == "Buy":
				buy = list
	for id in Data.SHOP:
		var price := Data.buy_price(id)
		buy.add_child(_shop_row(id, "%s  %dc" % [Data.ITEMS[id].name, price], "Buy", GS.coins >= price, func():
			if GS.coins >= price and GS.has_room(id):
				GS.coins -= price
				GS.add_item(id)
			elif not GS.has_room(id):
				toast("Your bag is full.", "warn")))
	var sell: VBoxContainer
	for c in s.get_children():
		if c is ScrollContainer and c.get_child(0).name == "Sell":
			sell = c.get_child(0)
	var seen := {}
	for slot in GS.inv:
		if slot == null or seen.has(slot.id):
			continue
		seen[slot.id] = true
		var id: String = slot.id
		var price: int = Data.ITEMS[id].sell
		if price <= 0:
			continue
		var n := GS.count(id)
		sell.add_child(_shop_row(id, "%s x%d  %dc" % [Data.ITEMS[id].name, n, price], "Sell", true, func():
			GS.remove_item(id, 1)
			GS.coins += price
			GS.inventory_changed.emit()))

func _shop_row(id: String, text: String, verb: String, enabled: bool, cb: Callable) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(196, 18)
	var ic := TextureRect.new()
	ic.texture = Art.icon(id)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ic.custom_minimum_size = Vector2(14, 14)
	row.add_child(ic)
	var l := _label(text, 9, C_INK)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var b := _button(verb, cb)
	b.disabled = not enabled
	row.add_child(b)
	return row

func _refresh_map() -> void:
	var cols: HBoxContainer = panels.map.get_node("Cols")
	for c in cols.get_children():
		c.queue_free()
	for z in Data.ZONE_ORDER:
		var zone: Dictionary = Data.ZONES[z]
		var v := VBoxContainer.new()
		v.custom_minimum_size = Vector2(134, 0)
		v.add_theme_constant_override("separation", 2)
		v.add_child(_label(zone.name, 10, C_EMBER, true))
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 2)
		grid.add_theme_constant_override("v_separation", 2)
		for n in range(1, Data.LEVELS_PER_ZONE + 1):
			var lid := "%s_%d" % [z, n]
			var b := _button(str(n), func(): close_panels(); main.change_level(lid, "left"))
			b.custom_minimum_size = Vector2(30, 18)
			b.disabled = not GS.unlocked.has(lid)
			grid.add_child(b)
		v.add_child(grid)
		var lair: String = z + "_lair"
		var key: String = zone.key
		var lb := _button("Lair  (%d %s)" % [GS.count(key), "key" if GS.count(key) == 1 else "keys"], func(): close_panels(); main.use_portal(lair), true)
		lb.disabled = not GS.unlocked.has(lair)
		v.add_child(lb)
		var done: bool = zone.boss in GS.bosses
		v.add_child(_label("Boss: %s%s" % [Data.MOBS[zone.boss].name, " (beaten)" if done else ""], 8, C_MUTED))
		cols.add_child(v)
