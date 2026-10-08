extends CanvasLayer
## On-screen interface: hotbar, bars, clock, touch buttons, and every menu
## (bag and combining, recipe books, villagers, shops, the Crafter, furnaces,
## chests, incubator, soils, world list, pause, title and fainting).

var main: Node
var root: Control
var hud_root: Control
var ui_theme: Theme
var hotbar_slots: Array = []
var bars: Control
var clock: Control
var coin_label: Label
var day_label: Label
var info_label: Label
var status_label: Label
var toasts: VBoxContainer
var boss_box: Control
var boss: Node = null
var hint_label: Label
var touch_nodes: Array = []
var force_touch := false

var panels := {}
var bag_slots: Array = []
var equip_buttons := {}
var bag_sel := -1
var move_from := -1
var combo := [-1, -1, -1]
var use_scroll := false
var info_box: VBoxContainer
var combo_box: Control
var stats_label: Label
var station: Node = null
var station_t := 0.0
const MobScript := preload("res://scripts/mob.gd")

const C_BG := Color("221d2e")
const C_BG2 := Color("2d2640")
const C_EDGE := Color("4a3e64")
const C_INK := Color("f3ecd9")
const C_MUTED := Color("a69cba")
const C_EMBER := Color("f2a33a")
const C_DARK := Color("1b1a24")
const C_GOOD := Color("7cc35a")
const C_BAD := Color("e2553f")
const C_SLOT := Color("efd2a4")
const C_SLOT_EDGE := Color("7a4a26")
const C_SLOT_SEL := Color("4fd040")

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
	_build_panels()
	GS.inventory_changed.connect(_refresh)
	GS.stats_changed.connect(_refresh_stats)
	GS.message.connect(toast)
	get_viewport().size_changed.connect(_layout_touch)
	_layout_touch()
	_refresh()

# ---------------------------------------------------------------- building blocks
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
	ui_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	ui_theme.set_color("font_color", "Button", C_INK)
	ui_theme.set_color("font_hover_color", "Button", Color.WHITE)
	ui_theme.set_color("font_disabled_color", "Button", Color("6a6080"))
	ui_theme.set_font_size("font_size", "Button", 9)
	ui_theme.set_type_variation("Accent", "Button")
	ui_theme.set_stylebox("normal", "Accent", _box(C_EMBER, Color("8a4a12"), 1, 3))
	ui_theme.set_stylebox("hover", "Accent", _box(Color("ffb850"), Color("8a4a12"), 1, 3))
	ui_theme.set_stylebox("pressed", "Accent", _box(Color("d8862a"), Color("8a4a12"), 1, 3))
	ui_theme.set_stylebox("disabled", "Accent", _box(Color("5a4a3a"), Color("3a2a1a"), 1, 3))
	ui_theme.set_color("font_color", "Accent", Color("2a1606"))
	ui_theme.set_color("font_hover_color", "Accent", Color("2a1606"))
	ui_theme.set_color("font_pressed_color", "Accent", Color("2a1606"))
	ui_theme.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	# item slots: peach squares with a brown edge, like the original
	ui_theme.set_type_variation("Slot", "Button")
	ui_theme.set_stylebox("normal", "Slot", _box(C_SLOT, C_SLOT_EDGE, 2, 1))
	ui_theme.set_stylebox("hover", "Slot", _box(Color("f8e2bc"), C_SLOT_EDGE, 2, 1))
	ui_theme.set_stylebox("pressed", "Slot", _box(Color("e2c08e"), C_SLOT_EDGE, 2, 1))
	ui_theme.set_stylebox("disabled", "Slot", _box(Color("b8a080"), C_SLOT_EDGE, 2, 1))

func _label(text: String, size: int = 10, color: Color = C_INK, title: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if title:
		l.add_theme_font_override("font", Art.font_title)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _outlined(l: Label) -> Label:
	l.add_theme_color_override("font_outline_color", C_DARK)
	l.add_theme_constant_override("outline_size", 3)
	return l

func _wrap(text: String, width: float, color: Color = C_INK, size: int = 9) -> Label:
	var l := _label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l

func _button(text: String, cb: Callable, accent: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	if accent:
		b.theme_type_variation = "Accent"
	b.pressed.connect(cb)
	return b

func _at(c: Control, pos: Vector2) -> Control:
	c.position = pos
	return c

func _slot(size: int = 22) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(size, size)
	b.size = Vector2(size, size)
	b.focus_mode = Control.FOCUS_NONE
	b.theme_type_variation = "Slot"
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)
	var n := _outlined(_label("", 8, C_INK, true))
	n.name = "Count"
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
	if on and b.theme_type_variation == "Slot":
		b.add_theme_stylebox_override("normal", _box(Color("fbe6c2"), C_SLOT_SEL if color == C_EMBER else color, 2, 1))
	elif on:
		b.add_theme_stylebox_override("normal", _box(Color("3a3150"), color, 2, 3))
	else:
		b.remove_theme_stylebox_override("normal")

func _icon(id: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Art.icon(id)
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.custom_minimum_size = Vector2(14, 14)
	t.tooltip_text = Data.ITEMS[id].name
	return t

func _cost_row(cost: Dictionary) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	for id in cost:
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 1)
		box.add_child(_icon(id))
		var have := GS.count(id)
		box.add_child(_label("%d/%d" % [have, cost[id]], 8, C_GOOD if have >= cost[id] else C_BAD, true))
		row.add_child(box)
	return row

func _clear(c: Node) -> void:
	for k in c.get_children():
		k.queue_free()

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
	bars.size = Vector2(92, 34)
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
	day_label = _outlined(_label("Day 1", 8, C_INK, true))
	day_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	day_label.position = Vector2(-50, 34)
	day_label.size = Vector2(100, 10)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_root.add_child(day_label)
	info_label = _outlined(_label("", 8, C_EMBER, true))
	info_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	info_label.position = Vector2(-80, 44)
	info_label.size = Vector2(160, 10)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_root.add_child(info_label)
	status_label = _outlined(_label("", 8, Color("8fd04a"), true))
	status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	status_label.position = Vector2(-80, 54)
	status_label.size = Vector2(160, 10)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_root.add_child(status_label)
	var coin_box := HBoxContainer.new()
	coin_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	coin_box.position = Vector2(22, 10)
	coin_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ci := TextureRect.new()
	ci.texture = Art.prop_tex("coin")
	ci.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	coin_box.add_child(ci)
	coin_label = _outlined(_label("0", 10, Color("f2cf5b"), true))
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
	boss_box.position = Vector2(-90, 64)
	boss_box.size = Vector2(180, 18)
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.draw.connect(_draw_boss)
	boss_box.visible = false
	hud_root.add_child(boss_box)
	toasts = VBoxContainer.new()
	toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toasts.position = Vector2(-130, 64)
	toasts.size = Vector2(260, 60)
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.add_theme_constant_override("separation", 2)
	hud_root.add_child(toasts)
	hint_label = _outlined(_label("A/D move   K jump (B)   J use (A)   E bag   1-5 hotbar", 8))
	hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.position = Vector2(-150, -14)
	hint_label.size = Vector2(300, 10)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_root.add_child(hint_label)

func _draw_bars() -> void:
	var rows := [[GS.hp, GS.max_hp(), Color("e2453a"), Color("8a1e1a")], [GS.mp, GS.max_mp(), Color("3b6fd9"), Color("1e3a8a")], [GS.st, GS.max_st(), Color("4fb83a"), Color("2a6a1e")]]
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
		var text := "%d/%d" % [int(ceil(maxf(r[0], 0))), int(r[1])]
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		bars.draw_string_outline(f, Vector2(1 + (w - tw) / 2, y + 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, C_DARK)
		bars.draw_string(f, Vector2(1 + (w - tw) / 2, y + 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

func _draw_clock() -> void:
	var c := Vector2(16, 16)
	clock.draw_circle(c, 15, C_DARK)
	clock.draw_circle(c, 14, Color("b85e1c"))
	clock.draw_circle(c, 12, Color("6fb6dc").lerp(Color("1e2a5a"), GS.darkness()))
	clock.draw_rect(Rect2(4, 17, 24, 11), Color("3e8a2e").lerp(Color("1e3a2a"), GS.darkness()))
	var a := GS.clock * TAU + PI / 2
	clock.draw_circle(c + Vector2(cos(a), sin(a)) * 8, 3, Color("f2cf5b"))
	clock.draw_circle(c - Vector2(cos(a), sin(a)) * 8, 2.5, Color("e8eef2"))
	clock.draw_arc(c, 13, 0, TAU, 32, C_DARK, 1)

func _draw_boss() -> void:
	if not is_instance_valid(boss) or boss.dead:
		return
	var f: Font = Art.font_title
	var nm: String = boss.def.name
	var tw := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	boss_box.draw_string_outline(f, Vector2(90 - tw / 2, 7), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, C_DARK)
	boss_box.draw_string(f, Vector2(90 - tw / 2, 7), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, C_INK)
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
	var lvl: Node = main.level if main else null
	if lvl == null:
		return
	day_label.text = Data.WORLDS[lvl.id].name
	var info := ""
	if lvl.kind == "arena" and not lvl.bosses_spawned:
		var s := int(lvl.arena_time_left())
		info = "Boss in %d:%02d" % [s / 60, s % 60]
	elif lvl.kind == "survival":
		info = "Day %d  %s" % [lvl.s_day, "Night" if GS.is_night() else ""]
	info_label.text = info
	var st := []
	for k in GS.status:
		st.append("%s %ds" % [k.capitalize(), int(ceil(GS.status[k]))])
	status_label.text = "  ".join(st)
	if boss == null:
		for e in lvl.entities.get_children():
			if e is MobScript and e.is_boss() and not e.dead and e.position.distance_to(lvl.player.position) < 260:
				set_boss(e)
				break
	if boss_box.visible:
		boss_box.queue_redraw()
		if not is_instance_valid(boss) or boss.dead:
			set_boss(null)
	if panels.station.visible and station and is_instance_valid(station):
		station_t += _d
		if station_t > 1.0:
			station_t = 0.0
			_station_tick()

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

func toast(text: String, kind: String = "") -> void:
	var p := PanelContainer.new()
	var edge := C_EDGE
	match kind:
		"good": edge = Color("5cbf3f")
		"warn": edge = Color("8a7aa0")
		"danger": edge = Color("e2453a")
		"big": edge = C_EMBER
	p.add_theme_stylebox_override("panel", _box(Color(0.08, 0.07, 0.11, 0.9), edge, 1, 3))
	var l := _label(text, 9, C_INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(250, 0)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.add_child(p)
	while toasts.get_child_count() > 2:
		toasts.get_child(0).free()
	var tw := p.create_tween()
	tw.tween_interval(2.6)
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
		var l := _outlined(_label(s[1], 14, Color.WHITE, true))
		l.size = Vector2(s[3], s[4])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		t.add_child(l)
		add_child(t)
		touch_nodes.append(t)
	force_touch = "--touch" in OS.get_cmdline_user_args()
	hint_label.visible = not _touch()

func _touch() -> bool:
	return force_touch or DisplayServer.is_touchscreen_available()

func _layout_touch() -> void:
	var vs := get_viewport().get_visible_rect().size
	if touch_nodes.size() < 4:
		return
	touch_nodes[0].position = Vector2(8, vs.y - 38)
	touch_nodes[1].position = Vector2(62, vs.y - 38)
	touch_nodes[2].position = Vector2(vs.x - 62, vs.y - 80)
	touch_nodes[3].position = Vector2(vs.x - 120, vs.y - 42)

func set_touch_visible(on: bool) -> void:
	for t in touch_nodes:
		t.visible = on and _touch() and not main.on_title()

func set_hud_visible(on: bool) -> void:
	hud_root.visible = on
	set_touch_visible(on)

# ---------------------------------------------------------------- panels
func _panel(key: String, size: Vector2, title: String = "", closable := true) -> Panel:
	var p := Panel.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.size = size
	p.position = -size / 2
	p.visible = false
	root.add_child(p)
	panels[key] = p
	if title != "" or closable:
		var t := _label(title, 12, C_EMBER, true)
		t.name = "Title"
		t.position = Vector2(8, 5)
		p.add_child(t)
	if closable:
		var x := _button("X", func(): close_panels())
		x.position = Vector2(size.x - 24, 4)
		x.custom_minimum_size = Vector2(18, 16)
		p.add_child(x)
	return p

func _scroll(p: Control, pos: Vector2, size: Vector2) -> VBoxContainer:
	var s := ScrollContainer.new()
	s.position = pos
	s.size = size
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(s)
	var v := VBoxContainer.new()
	v.name = "List"
	v.custom_minimum_size = Vector2(size.x - 12, 0)
	v.add_theme_constant_override("separation", 3)
	s.add_child(v)
	return v

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
		"map": _refresh_map()
		"title": _refresh_title()
		"smith": _refresh_smith()

func close_panels() -> void:
	for k in panels:
		panels[k].visible = false
	station = null
	main.set_paused(false)
	set_touch_visible(true)

func toggle_bag() -> void:
	if panels.bag.visible:
		close_panels()
	elif not any_open() and not main.on_title():
		open_panel("bag")

# ---------------------------------------------------------------- bag and combining
func _build_bag() -> void:
	var p := _panel("bag", Vector2(468, 258), "Bag")
	var grid := GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(8, 22)
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	p.add_child(grid)
	for i in GS.BAG:
		var b := _slot(22)
		var idx := i
		b.pressed.connect(func(): _bag_click(idx))
		grid.add_child(b)
		bag_slots.append(b)
	p.add_child(_at(_label("Top row = hotbar", 8, C_MUTED), Vector2(8, 168)))
	var eq := GridContainer.new()
	eq.columns = 2
	eq.position = Vector2(132, 22)
	eq.add_theme_constant_override("h_separation", 2)
	eq.add_theme_constant_override("v_separation", 2)
	p.add_child(eq)
	for slot in GS.EQUIP_SLOTS:
		var b := _slot(22)
		var sname: String = slot
		b.tooltip_text = slot.capitalize()
		b.pressed.connect(func():
			GS.unequip(sname)
			if sname == "pet":
				main.level.spawn_pet())
		eq.add_child(b)
		equip_buttons[slot] = b
	p.add_child(_at(_label("Helmet, armor, shield, 2 rings, pet", 6, C_MUTED), Vector2(132, 96)))
	stats_label = _label("", 8)
	stats_label.position = Vector2(132, 110)
	stats_label.size = Vector2(100, 70)
	p.add_child(stats_label)
	# combination panel
	var cb := Panel.new()
	cb.add_theme_stylebox_override("panel", _box(Color("17141f"), C_EDGE, 1, 4))
	cb.position = Vector2(236, 22)
	cb.size = Vector2(224, 96)
	p.add_child(cb)
	combo_box = cb
	cb.add_child(_at(_label("Combine", 10, C_EMBER, true), Vector2(6, 3)))
	for i in 3:
		var b := _slot(24)
		b.name = "C%d" % i
		var ci := i
		b.pressed.connect(func(): combo[ci] = -1; _refresh_bag())
		b.position = Vector2(6 + i * 30, 20)
		cb.add_child(b)
	var sc := _button("Scroll", func(): use_scroll = not use_scroll; _refresh_bag())
	sc.name = "Scroll"
	sc.position = Vector2(96, 23)
	sc.custom_minimum_size = Vector2(40, 18)
	cb.add_child(sc)
	cb.add_child(_at(_label("=", 12, C_MUTED, true), Vector2(142, 24)))
	var out := _slot(24)
	out.name = "Out"
	out.disabled = true
	out.position = Vector2(156, 20)
	cb.add_child(out)
	var chance := _label("", 8)
	chance.name = "Chance"
	chance.position = Vector2(6, 48)
	chance.size = Vector2(212, 20)
	chance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cb.add_child(chance)
	var go := _button("Combine", func(): _do_combine(), true)
	go.name = "Go"
	go.position = Vector2(6, 72)
	go.custom_minimum_size = Vector2(70, 18)
	cb.add_child(go)
	var clr := _button("Clear", func(): combo = [-1, -1, -1]; _refresh_bag())
	clr.position = Vector2(80, 72)
	cb.add_child(clr)
	info_box = VBoxContainer.new()
	info_box.position = Vector2(236, 124)
	info_box.size = Vector2(224, 128)
	info_box.add_theme_constant_override("separation", 3)
	p.add_child(info_box)

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
			_select_style(bag_slots[i], i == bag_sel or i in combo, C_EMBER if i == bag_sel else C_GOOD)
	for slot in GS.EQUIP_SLOTS:
		var id: String = GS.equip[slot]
		_fill_slot(equip_buttons[slot], {"id": id, "n": 1} if id != "" else null)
	var ar := GS.attack_range(GS.held())
	stats_label.text = "Attack %d-%d\nDefense %d\nMagic %d\nHealth %d\nMana %d\nStamina %d" % [ar.x, ar.y, GS.stat("def"), GS.stat("mag"), GS.max_hp(), GS.max_mp(), GS.max_st()]
	# combination
	for i in 3:
		if combo[i] >= 0 and GS.inv[combo[i]] == null:
			combo[i] = -1
		_fill_slot(combo_box.get_node("C%d" % i), GS.inv[combo[i]] if combo[i] >= 0 else null)
	var sc: Button = combo_box.get_node("Scroll")
	var scrolls := GS.count("combination_scroll")
	if scrolls == 0:
		use_scroll = false
	sc.disabled = scrolls == 0
	sc.text = "Scroll %s" % ("ON" if use_scroll else "off")
	_select_style(sc, use_scroll, Color("a77ee0"))
	var out: Button = combo_box.get_node("Out")
	var chance: Label = combo_box.get_node("Chance")
	var go: Button = combo_box.get_node("Go")
	_fill_slot(out, null)
	var pv := GS.preview_combo(combo, use_scroll)
	go.disabled = not pv.ready
	if not pv.ready:
		chance.text = "Pick items in your bag and tap \"Combine slot\". Two or three items."
	elif not pv.known:
		chance.text = "Unknown. Combining gives Dust."
	else:
		_fill_slot(out, {"id": pv.recipe.out, "n": pv.recipe.get("n", 1)})
		var book_name: String = Data.ITEMS[Data.BOOK_ITEM[pv.recipe.book]].name
		chance.text = "%s: %d%% success%s" % [Data.ITEMS[pv.recipe.out].name, pv.chance,
			"" if pv.book else "  (%s adds +50%%)" % book_name]
	# selected item
	_clear(info_box)
	if move_from >= 0:
		info_box.add_child(_wrap("Tap a slot to move the item there.", 220, C_MUTED))
		return
	if bag_sel < 0 or GS.inv[bag_sel] == null:
		info_box.add_child(_wrap("Tap an item to see what it does. Recipes are secret until you try them, or read a Combo Book.", 220, C_MUTED))
		return
	var s = GS.inv[bag_sel]
	var it: Dictionary = Data.ITEMS[s.id]
	info_box.add_child(_label("%s%s" % [it.name, "  x%d" % s.n if s.n > 1 else ""], 10, C_EMBER, true))
	var extra := ""
	if it.has("dmg") and it.type in ["weapon", "axe", "pick", "bow", "throw"]:
		extra = "  Attack %d, %.2fs per %s." % [it.dmg, it.spd, "shot" if it.type in ["bow", "throw"] else "swing"]
	if it.has("sell") and int(it.sell) > 0:
		extra += "  Sells for %d." % it.sell
	info_box.add_child(_wrap(it.desc + extra, 220))
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 3)
	row.add_theme_constant_override("v_separation", 3)
	info_box.add_child(row)
	if it.type == "food":
		row.add_child(_button("Use", func(): GS.consume(bag_sel)))
	if GS.equip_slot_for(s.id) != "":
		row.add_child(_button("Equip", func():
			var is_pet: bool = it.type == "pet"
			GS.equip_from(bag_sel)
			if is_pet:
				main.level.spawn_pet()))
	if it.type == "book":
		row.add_child(_button("Read", func(): open_book(it.book)))
	if it.type == "character":
		row.add_child(_button("Become", func():
			toast(GS.use_character(bag_sel), "big")
			bag_sel = -1
			_refresh_bag()))
	if bag_sel >= GS.HOTBAR:
		row.add_child(_button("Hold", func():
			GS.swap(bag_sel, GS.sel)
			bag_sel = GS.sel
			_refresh_bag()))
	row.add_child(_button("Combine slot", func():
		for k in 3:
			if combo[k] < 0:
				combo[k] = bag_sel
				break
		_refresh_bag()))
	row.add_child(_button("Move", func(): move_from = bag_sel; _refresh_bag()))
	row.add_child(_button("Drop", func():
		var d = GS.inv[bag_sel]
		GS.inv[bag_sel] = null
		main.drop_from_player(d.id, d.n)
		bag_sel = -1
		GS.inventory_changed.emit()))

func _do_combine() -> void:
	var r := GS.combine(combo, use_scroll)
	if not r.ok:
		toast(r.reason, "warn")
	elif r.success:
		toast("Success! You made %s." % Data.ITEMS[r.out].name, "good")
	else:
		toast("The combination failed. You got Dust." if r.get("known", false) else "Unknown combination. You got Dust.", "warn")
	_refresh_bag()

# ---------------------------------------------------------------- other panels
func _build_panels() -> void:
	var d := _panel("npc", Vector2(420, 132))
	var text := _wrap("", 404)
	text.name = "Text"
	text.position = Vector2(8, 22)
	d.add_child(text)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.position = Vector2(8, 106)
	row.add_theme_constant_override("separation", 4)
	d.add_child(row)

	var sh := _panel("shop", Vector2(460, 244), "Shop")
	_scroll(sh, Vector2(8, 38), Vector2(218, 198)).name = "Buy"
	sh.add_child(_at(_label("Buy", 10, C_MUTED, true), Vector2(8, 24)))
	_scroll(sh, Vector2(234, 38), Vector2(218, 198)).name = "Sell"
	sh.add_child(_at(_label("Sell", 10, C_MUTED, true), Vector2(234, 24)))

	var sm := _panel("smith", Vector2(460, 244), "Crafter")
	sm.add_child(_at(_label("Always succeeds. Gear you use up must be in your bag (not equipped).", 8, C_MUTED), Vector2(70, 8)))
	_scroll(sm, Vector2(8, 26), Vector2(444, 210))

	var bk := _panel("book", Vector2(460, 244), "Book")
	_scroll(bk, Vector2(8, 26), Vector2(444, 210))

	var st := _panel("station", Vector2(440, 230), "")
	var stext := _wrap("", 424)
	stext.name = "Text"
	stext.position = Vector2(8, 24)
	st.add_child(stext)
	_scroll(st, Vector2(8, 56), Vector2(424, 166))

	var m := _panel("map", Vector2(440, 214), "Gatekeeper")
	var cols := HBoxContainer.new()
	cols.name = "Cols"
	cols.position = Vector2(8, 26)
	cols.add_theme_constant_override("separation", 8)
	m.add_child(cols)
	m.add_child(_at(_wrap("Exploration worlds go deeper: find the purple portal hidden underground. In arenas the boss arrives after 3 minutes. In Survival, live through the nights for Survival Tokens.", 420, C_MUTED, 8), Vector2(8, 172)))

	var info := _panel("info", Vector2(380, 140), "")
	var itext := _wrap("", 364)
	itext.name = "Text"
	itext.position = Vector2(8, 24)
	info.add_child(itext)

	var pz := _panel("pause", Vector2(200, 110), "Paused", false)
	var pv := VBoxContainer.new()
	pv.position = Vector2(30, 30)
	pv.custom_minimum_size = Vector2(140, 0)
	pv.add_theme_constant_override("separation", 6)
	pz.add_child(pv)
	pv.add_child(_button("Resume", func(): close_panels(), true))
	pv.add_child(_button("Save and quit to title", func(): main.quit_to_title()))

	var dead := _panel("dead", Vector2(260, 110), "You fainted", false)
	var dtext := _wrap("", 244)
	dtext.name = "Text"
	dtext.position = Vector2(8, 24)
	dead.add_child(dtext)
	var wake := _button("Wake up in Pixel Town", func(): main.respawn(), true)
	wake.position = Vector2(8, 80)
	dead.add_child(wake)

	var t := _panel("title", Vector2(480, 270), "", false)
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
	t.add_child(_at(_outlined(_label("Explore, combine, smelt and survive. Nothing to buy, ever.", 10)), Vector2(26, 108)))
	var tv := VBoxContainer.new()
	tv.name = "Menu"
	tv.position = Vector2(26, 128)
	tv.custom_minimum_size = Vector2(130, 0)
	tv.add_theme_constant_override("separation", 5)
	t.add_child(tv)

func _refresh_title(choosing := false) -> void:
	var tv: VBoxContainer = panels.title.get_node("Menu")
	_clear(tv)
	if choosing:
		# like the original, a new adventure starts as the Man in Suit or the Nurse
		tv.add_child(_outlined(_label("Pick your character", 10, C_INK, true)))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		for c in Data.START_CHARACTERS:
			var b := _button(Data.CHARACTERS[c].name, func(): main.start_game(false, c), c == "man_in_suit")
			b.icon = Art.character(c, "stand", 2)
			b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.custom_minimum_size = Vector2(76, 0)
			row.add_child(b)
		tv.add_child(row)
		tv.add_child(_button("Back", func(): _refresh_title()))
		return
	if GS.has_save():
		tv.add_child(_button("Continue", func(): main.start_game(true), true))
	tv.add_child(_button("New game", func(): _refresh_title(true), not GS.has_save()))

func show_dead(text: String) -> void:
	panels.dead.get_node("Text").text = text
	open_panel("dead")

func open_info(title: String, text: String) -> void:
	panels.info.get_node("Title").text = title
	panels.info.get_node("Text").text = text
	open_panel("info")

# villagers
func open_npc(npc_id: String) -> void:
	open_panel("npc")
	_refresh_npc(npc_id)

func _refresh_npc(npc_id: String) -> void:
	var p: Panel = panels.npc
	var npc: Dictionary = Data.NPCS[npc_id]
	p.get_node("Title").text = npc.name
	var row: HBoxContainer = p.get_node("Row")
	_clear(row)
	var text: String = npc.talk
	var q := GS.next_quest(npc_id)
	if not q.is_empty():
		text = q.text
		var need := []
		for id in q.need:
			need.append("%s %d/%d" % [Data.ITEMS[id].name, GS.count(id), q.need[id]])
		var rewards := []
		for id in q.reward:
			rewards.append("%s x%d" % [Data.ITEMS[id].name, q.reward[id]])
		match q.get("unlock", ""):
			"survival_access": rewards.append("entry to Survival Grasslands")
			"furnaces": rewards.append("access to the furnaces")
		text += "\nNeeds: %s\nReward: %s" % [", ".join(need), ", ".join(rewards)]
		var give := _button("Hand in", func():
			GS.complete_quest(q)
			toast("Quest complete!", "good")
			if q.get("unlock", "") == "furnaces":
				main.reload_level()
			_refresh_npc(npc_id), true)
		give.disabled = not GS.quest_ready(q)
		row.add_child(give)
	if Data.SHOPS.has(npc_id):
		row.add_child(_button("Shop", func(): open_shop(npc_id), true))
	if npc_id == "smith":
		row.add_child(_button("Craft", func(): open_smith(), true))
	if npc_id == "keeper":
		row.add_child(_button("Choose a world", func(): open_panel("map"), true))
	row.add_child(_button("Bye", func(): close_panels()))
	p.get_node("Text").text = text

# shops
func open_shop(npc_id: String) -> void:
	open_panel("shop")
	_refresh_shop(npc_id)

func _refresh_shop(npc_id: String) -> void:
	var shop: Dictionary = Data.SHOPS[npc_id]
	var p: Panel = panels.shop
	p.get_node("Title").text = shop.title
	var buy: VBoxContainer = p.find_child("Buy", true, false)
	var sell: VBoxContainer = p.find_child("Sell", true, false)
	_clear(buy)
	_clear(sell)
	var currency: String = shop.get("currency", "coins")
	for e in shop.sells:
		var id: String = e[0]
		var price: int = e[1]
		var have: int = GS.coins if currency == "coins" else GS.count(currency)
		var unit := "c" if currency == "coins" else " tokens"
		buy.add_child(_row(id, "%s  %d%s" % [Data.ITEMS[id].name, price, unit], "Buy", have >= price, func():
			if not GS.has_room(id):
				toast("Inventory full.", "warn")
				return
			if currency == "coins":
				GS.coins -= price
			else:
				GS.remove_item(currency, price)
			GS.add_item(id)
			GS.stats_changed.emit()
			_refresh_shop(npc_id)))
	if not shop.get("buys", false):
		sell.add_child(_wrap("This shop doesn't buy anything.", 200, C_MUTED))
		return
	var seen := {}
	for slot in GS.inv:
		if slot == null or seen.has(slot.id):
			continue
		seen[slot.id] = true
		var id2: String = slot.id
		var price2: int = Data.ITEMS[id2].sell
		if price2 <= 0:
			continue
		sell.add_child(_row(id2, "%s x%d  %dc" % [Data.ITEMS[id2].name, GS.count(id2), price2], "Sell", true, func():
			GS.remove_item(id2, 1)
			GS.coins += price2
			GS.stats_changed.emit()
			_refresh_shop(npc_id)))

func _row(id: String, text: String, verb: String, enabled: bool, cb: Callable) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(200, 18)
	row.add_child(_icon(id))
	var l := _label(text, 9)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	row.add_child(l)
	var b := _button(verb, cb)
	b.disabled = not enabled
	row.add_child(b)
	return row

# smith
func open_smith() -> void:
	open_panel("smith")

func _refresh_smith() -> void:
	var list: VBoxContainer = panels.smith.find_child("List", true, false)
	_clear(list)
	for r in Data.SMITH:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.add_child(_icon(r.out))
		var name := _label(Data.ITEMS[r.out].name, 9)
		name.custom_minimum_size = Vector2(110, 0)
		row.add_child(name)
		var costs := _cost_row(r.cost)
		costs.custom_minimum_size = Vector2(240, 0)
		costs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(costs)
		var rr: Dictionary = r
		var b := _button("Craft", func():
			if GS.smith(rr):
				toast("You made %s." % Data.ITEMS[rr.out].name, "good")
			_refresh_smith(), true)
		b.disabled = not GS.has_all(r.cost)
		row.add_child(b)
		list.add_child(row)

# books
func open_book(book: String) -> void:
	open_panel("book")
	panels.book.get_node("Title").text = Data.ITEMS[Data.BOOK_ITEM[book]].name
	var list: VBoxContainer = panels.book.find_child("List", true, false)
	_clear(list)
	list.add_child(_wrap("These combinations get +50% while this book is in your bag. A Combination Scroll adds +35%.", 420, C_MUTED))
	for r in Data.RECIPES:
		if r.book != book:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		for i in r.in.size():
			row.add_child(_icon(r.in[i]))
			if i < r.in.size() - 1:
				row.add_child(_label("+", 9, C_MUTED))
		row.add_child(_label("=", 9, C_MUTED))
		row.add_child(_icon(r.out))
		var n := _label("%s%s" % [Data.ITEMS[r.out].name, " x%d" % r.n if r.has("n") else ""], 9)
		n.custom_minimum_size = Vector2(150, 0)
		row.add_child(n)
		row.add_child(_label("base %d%%  with book %d%%" % [r.rate, mini(100, r.rate + 50)], 8, C_EMBER))
		list.add_child(row)

# world list
func _refresh_map() -> void:
	var cols: HBoxContainer = panels.map.get_node("Cols")
	_clear(cols)
	for section in Data.WORLD_MENU:
		var v := VBoxContainer.new()
		v.custom_minimum_size = Vector2(136, 0)
		v.add_theme_constant_override("separation", 3)
		v.add_child(_label(section[0], 10, C_EMBER, true))
		for wid in section[1]:
			var w: Dictionary = Data.WORLDS[wid]
			var target: String = wid
			var b := _button(w.name, func(): close_panels(); main.change_level(target), false)
			if w.has("needs") and not GS.flags.get(w.needs, false):
				b.disabled = true
				b.tooltip_text = "Finish Brutus' quest first."
			v.add_child(b)
		cols.add_child(v)

# stations
func open_station(s: Node) -> void:
	station = s
	open_panel("station")
	_refresh_station()

func _refresh_station() -> void:
	if station == null or not is_instance_valid(station):
		return
	var p: Panel = panels.station
	var title: Label = p.get_node("Title")
	var text: Label = p.get_node("Text")
	var list: VBoxContainer = p.find_child("List", true, false)
	_clear(list)
	var k: String = station.kind
	var i: int = station.index
	match k:
		"furnace":
			title.text = "Furnace %d" % (i + 1)
			var job = GS.furnaces[i]
			if not GS.flags.get("furnaces", false):
				text.text = "The furnaces are locked. Bring the GateKeeper a Pretzel."
			elif job == null:
				text.text = "Pick what to smelt. It keeps working even while you're away."
				for r in Data.SMELT:
					var rr: Dictionary = r
					var row := HBoxContainer.new()
					row.add_child(_icon(r.out))
					var nl := _label("%s  (%s)" % [Data.ITEMS[r.out].name, _dur(r.time)], 9)
					nl.custom_minimum_size = Vector2(150, 0)
					row.add_child(nl)
					var c := _cost_row(r.cost)
					c.custom_minimum_size = Vector2(170, 0)
					row.add_child(c)
					var b := _button("Smelt", func():
						var err := GS.start_smelt(i, rr)
						if err != "":
							toast(err, "warn")
						_refresh_station(), true)
					b.disabled = not GS.has_all(r.cost)
					row.add_child(b)
					list.add_child(row)
			elif GS.now() < job.done:
				text.text = "Smelting %s. Ready in %s." % [Data.ITEMS[job.out].name, _dur(job.done - GS.now())]
			else:
				text.text = "%s is ready!" % Data.ITEMS[job.out].name
				list.add_child(_button("Collect", func():
					if not GS.collect_smelt(i):
						toast("Inventory full.", "warn")
					_refresh_station(), true))
		"chest_silver", "chest_golden", "chest_master":
			var ck := k.replace("chest_", "")
			var c2: Dictionary = Data.CHESTS[ck]
			title.text = c2.name
			text.text = "Use a %s to open it. You have %d." % [Data.ITEMS[c2.key].name, GS.count(c2.key)]
			var ob := _button("Open", func():
				var loot := GS.open_chest(ck)
				_refresh_station()
				_show_loot(loot), true)
			ob.disabled = GS.count(c2.key) <= 0
			list.add_child(ob)
		"reward_chest":
			title.text = "Reward Chest"
			var opened: bool = GS.reward_chests.get(station.level.id, -1) == GS.today()
			text.text = "Already opened today. Come back tomorrow." if opened else "A chest left by an explorer. No key needed!"
			if not opened:
				list.add_child(_button("Open", func():
					GS.reward_chests[station.level.id] = GS.today()
					var loot := []
					for n in 3:
						var l := Data.pick_loot(Data.CHESTS.silver.loot)
						GS.add_item(l[0], l[1], true)
						loot.append(l)
					_refresh_station()
					_show_loot(loot), true))
		"incubator":
			title.text = "Incubator"
			if GS.incubator.is_empty():
				text.text = "Put in a monster egg to hatch it (%s)." % _dur(Data.HATCH_TIME)
				for id in Data.EGG_PETS:
					if GS.count(id) > 0:
						var egg: String = id
						list.add_child(_row(egg, "%s x%d" % [Data.ITEMS[egg].name, GS.count(egg)], "Hatch", true, func():
							GS.start_hatch(egg)
							_refresh_station()))
				if list.get_child_count() == 0:
					list.add_child(_wrap("You don't have any eggs. Monsters drop them now and then.", 400, C_MUTED))
			elif GS.now() < GS.incubator.done:
				text.text = "Hatching %s. Ready in %s." % [Data.ITEMS[GS.incubator.egg].name, _dur(GS.incubator.done - GS.now())]
			else:
				text.text = "Something hatched!"
				list.add_child(_button("Collect pet", func():
					var pet := GS.collect_hatch()
					if pet != "":
						toast("You got a %s! Equip it in the pet slot." % Data.ITEMS[pet].name, "good")
					else:
						toast("Inventory full.", "warn")
					_refresh_station(), true))
		"soil":
			title.text = "Magic Soil %d" % (i + 1)
			var s = GS.soils[i]
			if not GS.flags.get("rock_wall", false):
				text.text = "Break the rock wall with a gold pickaxe to use these soils."
			elif s == null:
				text.text = "Plant magic seeds here."
				for id in ["green_seeds", "red_seeds", "golden_seeds"]:
					if GS.count(id) > 0:
						var seed: String = id
						list.add_child(_row(seed, "%s x%d (%s)" % [Data.ITEMS[seed].name, GS.count(seed), _dur(Data.ITEMS[seed].grow)], "Plant", true, func():
							GS.plant(i, seed)
							_refresh_station()))
				if list.get_child_count() == 0:
					list.add_child(_wrap("You don't have any magic seeds.", 400, C_MUTED))
			elif GS.now() < s.done:
				text.text = "Growing. Ready in %s." % _dur(s.done - GS.now())
			else:
				text.text = "Fully grown!"
				list.add_child(_button("Harvest", func():
					var loot := GS.harvest(i)
					_refresh_station()
					_show_loot(loot), true))

## Updates countdowns without rebuilding the list.
func _station_tick() -> void:
	var k: String = station.kind
	var i: int = station.index
	var text: Label = panels.station.get_node("Text")
	match k:
		"furnace":
			var job = GS.furnaces[i]
			if job != null:
				if GS.now() < job.done:
					text.text = "Smelting %s. Ready in %s." % [Data.ITEMS[job.out].name, _dur(job.done - GS.now())]
				elif not text.text.ends_with("ready!"):
					_refresh_station()
		"incubator":
			if not GS.incubator.is_empty():
				if GS.now() < GS.incubator.done:
					text.text = "Hatching %s. Ready in %s." % [Data.ITEMS[GS.incubator.egg].name, _dur(GS.incubator.done - GS.now())]
				elif not text.text.ends_with("hatched!"):
					_refresh_station()
		"soil":
			var s = GS.soils[i]
			if s != null:
				if GS.now() < s.done:
					text.text = "Growing. Ready in %s." % _dur(s.done - GS.now())
				elif not text.text.ends_with("grown!"):
					_refresh_station()

func _show_loot(loot: Array) -> void:
	if loot.is_empty():
		return
	var parts := []
	for l in loot:
		parts.append("%s x%d" % [Data.ITEMS[l[0]].name, l[1]])
	toast("You got: " + ", ".join(parts), "good")

func _dur(sec: float) -> String:
	var s := int(maxf(sec, 0))
	if s >= 3600:
		return "%dh %02dm" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		return "%dm %02ds" % [s / 60, s % 60]
	return "%ds" % s
