extends CanvasLayer
## Everything on screen, laid out like Pixel Survival Game 2: the hotbar and
## bars top left, the sky clock top centre, the bag, compass and bomb on the
## right, grey ◀ ▶ and red A / green B buttons, and the orange menus (bag and
## combining, the Crafter, villagers, shops, books, furnaces, chests, the world
## list) plus the main menu with three character slots.

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
var bomb_btn: TextureButton
var gift_btn: Button
var touch_nodes: Array = []
var force_touch := false

var panels := {}
var bag_slots: Array = []
var equip_buttons := {}
var bag_sel := -1
var move_from := -1
var combo := [-1, -1, -1]
var combo_target := 0
var use_scroll := false
var bag_mode := "bag" # "bag" when opened from the backpack, "craft" at the Crafter
var bag_tab := "combine" # bag: character, combine, menu. craft: weapon, helmet, armor, shield, ring
var craft_sel := -1
var info_box: VBoxContainer
var tab_row: HBoxContainer
var page: Control
var station: Node = null
var station_t := 0.0
var menu_step := "title"
var new_char := "man_in_suit"
var name_edit: LineEdit
var chat_btn: Button
var chat_edit: LineEdit
var chat_log := [] # recent room chat, newest last
var room_label: Label
var room_box: VBoxContainer
var trade_bag: Array = []
var busy := false # waiting on the online server
const MobScript := preload("res://scripts/mob.gd")

const C_INK := Color("4a2410") # dark brown text on the peach panels
const C_MUTED := Color("8a5a32")
const C_EMBER := Color("d8661a")
const C_DARK := Color("1b1a24")
const C_WHITE := Color("ffffff")
const C_GOOD := Color("2e8a1e")
const C_BAD := Color("c8301a")
const C_YELLOW := Color("f2cf5b")

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
func _tex_box(tex: Texture2D, margin: int, pad: int) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.set_texture_margin_all(margin)
	s.set_content_margin_all(pad)
	return s

func _make_theme() -> void:
	ui_theme = Theme.new()
	ui_theme.default_font = Art.font_body
	ui_theme.default_font_size = 9
	ui_theme.set_color("font_color", "Label", C_INK)
	var frame := _tex_box(Art.ui_frame("frame"), 4, 6)
	ui_theme.set_stylebox("panel", "Panel", frame)
	ui_theme.set_stylebox("panel", "PanelContainer", frame)
	ui_theme.set_stylebox("normal", "Button", _tex_box(Art.ui_frame("button"), 3, 3))
	ui_theme.set_stylebox("hover", "Button", _tex_box(Art.ui_frame("button"), 3, 3))
	ui_theme.set_stylebox("pressed", "Button", _tex_box(Art.ui_frame("button_down"), 3, 3))
	var dis := _tex_box(Art.ui_frame("button_down"), 3, 3)
	dis.modulate_color = Color(0.75, 0.7, 0.65)
	ui_theme.set_stylebox("disabled", "Button", dis)
	ui_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	ui_theme.set_color("font_color", "Button", Color("3a1606"))
	ui_theme.set_color("font_hover_color", "Button", Color("3a1606"))
	ui_theme.set_color("font_pressed_color", "Button", Color("3a1606"))
	ui_theme.set_color("font_disabled_color", "Button", Color("7a5a40"))
	ui_theme.set_font_size("font_size", "Button", 9)
	ui_theme.set_type_variation("Accent", "Button")
	ui_theme.set_stylebox("normal", "Accent", _tex_box(Art.ui_frame("green"), 3, 3))
	ui_theme.set_stylebox("hover", "Accent", _tex_box(Art.ui_frame("green"), 3, 3))
	ui_theme.set_stylebox("pressed", "Accent", _tex_box(Art.ui_frame("green"), 3, 3))
	var adis := _tex_box(Art.ui_frame("green"), 3, 3)
	adis.modulate_color = Color(0.6, 0.6, 0.6)
	ui_theme.set_stylebox("disabled", "Accent", adis)
	ui_theme.set_color("font_color", "Accent", C_WHITE)
	ui_theme.set_color("font_hover_color", "Accent", C_WHITE)
	ui_theme.set_color("font_pressed_color", "Accent", C_WHITE)
	ui_theme.set_color("font_outline_color", "Accent", Color("0e3a0e"))
	ui_theme.set_constant("outline_size", "Accent", 3)
	ui_theme.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	# item slots: peach squares with a brown edge; the selected one turns green
	ui_theme.set_type_variation("Slot", "Button")
	for st in ["normal", "hover", "pressed", "disabled"]:
		ui_theme.set_stylebox(st, "Slot", _tex_box(Art.ui_frame("slot"), 1, 1))
	# LineEdit for the character name
	ui_theme.set_stylebox("normal", "LineEdit", _tex_box(Art.ui_frame("slot"), 1, 4))
	ui_theme.set_stylebox("focus", "LineEdit", _tex_box(Art.ui_frame("slot_sel"), 2, 4))
	ui_theme.set_color("font_color", "LineEdit", C_INK)

func _label(text: String, size: int = 9, color: Color = C_INK, title: bool = false) -> Label:
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

## White text with a dark outline, used for headings like the original's.
func _heading(text: String, size: int = 10) -> Label:
	return _outlined(_label(text, size, C_WHITE))

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

func _icon_button(tex: Texture2D, size: Vector2, cb: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = tex
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b

func _at(c: Control, pos: Vector2) -> Control:
	c.position = pos
	return c

func _slot(size: int = 28) -> Button:
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
	var n := _outlined(_label("", 8, C_WHITE, true))
	n.name = "Count"
	n.position = Vector2(size - 16, size - 12)
	n.size = Vector2(14, 10)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.add_child(n)
	return b

func _fill_slot(b: Button, s, ghost: Texture2D = null) -> void:
	var icon: TextureRect = b.get_node("Icon")
	var n: Label = b.get_node("Count")
	if s:
		icon.texture = Art.icon_big(s.id) if b.size.x >= 26 else Art.icon(s.id)
		icon.modulate = Color.WHITE
		n.text = str(s.n) if s.n > 1 else ""
		b.tooltip_text = Data.ITEMS[s.id].name
	else:
		icon.texture = ghost
		n.text = ""
		b.tooltip_text = ""

func _select_style(b: Button, on: bool, color: Color = C_GOOD) -> void:
	if on and b.theme_type_variation == "Slot":
		b.add_theme_stylebox_override("normal", _tex_box(Art.ui_frame("slot_sel"), 2, 1))
		b.add_theme_stylebox_override("hover", _tex_box(Art.ui_frame("slot_sel"), 2, 1))
	elif on:
		b.add_theme_stylebox_override("normal", _tex_box(Art.ui_frame("green"), 3, 3))
		b.add_theme_stylebox_override("hover", _tex_box(Art.ui_frame("green"), 3, 3))
	else:
		b.remove_theme_stylebox_override("normal")
		b.remove_theme_stylebox_override("hover")

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
		c.remove_child(k)
		k.queue_free()

func _frame(pos: Vector2, size: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

# ---------------------------------------------------------------- HUD
func _build_hud() -> void:
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud_root)
	# hotbar: the top row of the bag
	var hb := HBoxContainer.new()
	hb.position = Vector2(5, 5)
	hb.add_theme_constant_override("separation", 3)
	hud_root.add_child(hb)
	for i in GS.HOTBAR:
		var b := _slot(28)
		var idx := i
		b.pressed.connect(func(): GS.sel = idx; GS.inventory_changed.emit())
		hb.add_child(b)
		hotbar_slots.append(b)
	# health, mana and stamina
	bars = Control.new()
	bars.position = Vector2(5, 38)
	bars.size = Vector2(92, 38)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.draw.connect(_draw_bars)
	hud_root.add_child(bars)
	status_label = _outlined(_label("", 7, Color("8fd04a"), true))
	status_label.position = Vector2(5, 92)
	hud_root.add_child(status_label)
	# the "Chat.." box under the bars (rooms only); tap it to type
	chat_btn = Button.new()
	chat_btn.text = "Chat.."
	chat_btn.focus_mode = Control.FOCUS_NONE
	chat_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	chat_btn.position = Vector2(5, 77)
	chat_btn.custom_minimum_size = Vector2(92, 13)
	chat_btn.size = Vector2(92, 13)
	chat_btn.add_theme_font_size_override("font_size", 7)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0, 0, 0, 0.45)
	cs.set_content_margin_all(2)
	for st_name in ["normal", "hover", "pressed"]:
		chat_btn.add_theme_stylebox_override(st_name, cs)
	chat_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	chat_btn.add_theme_color_override("font_hover_color", C_WHITE)
	chat_btn.pressed.connect(func(): open_chat())
	chat_btn.visible = false
	hud_root.add_child(chat_btn)
	chat_btn.size = Vector2(92, 13) # after the small font is in place, or it keeps the default height
	# the sky clock, with the day and your coins next to it
	clock = Control.new()
	clock.set_anchors_preset(Control.PRESET_CENTER_TOP)
	clock.position = Vector2(-34, 0)
	clock.size = Vector2(68, 34)
	clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock.draw.connect(_draw_clock)
	hud_root.add_child(clock)
	day_label = _outlined(_label("Day 1", 9, C_YELLOW, true))
	day_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	day_label.position = Vector2(37, 3)
	hud_root.add_child(day_label)
	var coin_box := HBoxContainer.new()
	coin_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	coin_box.position = Vector2(30, 17)
	coin_box.add_theme_constant_override("separation", 2)
	coin_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plus := TextureRect.new()
	plus.texture = Art.ui_icon("plus")
	plus.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	coin_box.add_child(plus)
	var ci := TextureRect.new()
	ci.texture = Art.prop_tex("coin")
	ci.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	coin_box.add_child(ci)
	coin_label = _outlined(_label("0", 9, Color("5ce0d0"), true))
	coin_box.add_child(coin_label)
	hud_root.add_child(coin_box)
	info_label = _outlined(_label("", 8, C_YELLOW, true))
	info_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	info_label.position = Vector2(-80, 36)
	info_label.size = Vector2(160, 10)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_root.add_child(info_label)
	# right side: bag, compass (menu) and the bomb (outside town)
	var bag_btn := _icon_button(Art.ui_icon("backpack", 2), Vector2(24, 22), func(): toggle_bag())
	bag_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bag_btn.position = Vector2(-30, 6)
	bag_btn.name = "BagButton"
	hud_root.add_child(bag_btn)
	var compass := _icon_button(Art.ui_icon("compass", 2), Vector2(22, 22), func(): open_panel("pause"))
	compass.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	compass.position = Vector2(-29, 56)
	hud_root.add_child(compass)
	bomb_btn = _icon_button(Art.ui_icon("bomb", 2), Vector2(22, 24), func():
		if main.level and main.level.kind != "town":
			main.level.player.self_destruct())
	bomb_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bomb_btn.position = Vector2(-29, 96)
	hud_root.add_child(bomb_btn)
	gift_btn = _button("DAILY FREE GIFT", func(): _open_gift())
	gift_btn.add_theme_font_override("font", Art.font_title)
	gift_btn.add_theme_font_size_override("font_size", 7)
	gift_btn.add_theme_color_override("font_color", C_YELLOW)
	gift_btn.add_theme_color_override("font_hover_color", C_YELLOW)
	gift_btn.add_theme_color_override("font_outline_color", Color("4a1e08"))
	gift_btn.add_theme_constant_override("outline_size", 3)
	gift_btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	gift_btn.position = Vector2(76, 4)
	gift_btn.custom_minimum_size = Vector2(92, 16)
	hud_root.add_child(gift_btn)
	boss_box = Control.new()
	boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_box.position = Vector2(-90, 46)
	boss_box.size = Vector2(180, 18)
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.draw.connect(_draw_boss)
	boss_box.visible = false
	hud_root.add_child(boss_box)
	# "X obtained" messages, plain text under the clock like the original
	toasts = VBoxContainer.new()
	toasts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toasts.position = Vector2(-130, 66)
	toasts.size = Vector2(260, 60)
	toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toasts.add_theme_constant_override("separation", 0)
	hud_root.add_child(toasts)
	hint_label = _outlined(_label("A/D move   K jump (B)   J use (A)   E bag   1-5 hotbar", 8, C_WHITE))
	hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.position = Vector2(-150, -14)
	hint_label.size = Vector2(300, 10)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_root.add_child(hint_label)

func _draw_bars() -> void:
	var rows := [[GS.hp, GS.max_hp(), Color("e8402e")], [GS.mp, GS.max_mp(), Color("2b74d8")], [GS.st, GS.max_st(), Color("5ab52a")]]
	var f: Font = Art.font_title
	for i in rows.size():
		var r: Array = rows[i]
		var y := i * 13
		var w := 90.0
		bars.draw_rect(Rect2(0, y, w + 2, 11), C_DARK)
		bars.draw_rect(Rect2(1, y + 1, w, 9), Color("3a3a44"))
		var k := clampf(r[0] / maxf(r[1], 1.0), 0, 1)
		var c: Color = r[2]
		bars.draw_rect(Rect2(1, y + 1, w * k, 9), c)
		bars.draw_rect(Rect2(1, y + 1, w * k, 2), c.lightened(0.25))
		bars.draw_rect(Rect2(1, y + 8, w * k, 2), c.darkened(0.3))
		var text := "%d/%d" % [int(ceil(maxf(r[0], 0))), int(r[1])]
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		bars.draw_string_outline(f, Vector2(1 + (w - tw) / 2, y + 9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, C_DARK)
		bars.draw_string(f, Vector2(1 + (w - tw) / 2, y + 9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, C_WHITE)

## The sky disc turns once a day: day (blue, with the sun), sunset (yellow,
## orange, purple) and night (dark, with stars). The bottom middle, behind the
## little mountain, is now; the left side is what's coming.
func _sky_color(t: float) -> Color:
	t = fposmod(t, 1.0)
	if t < GS.SUNSET:
		return Color("3cc8f8")
	if t < GS.SUNSET + 1.0 / 72.0 * 4.0:
		return Color("f8b820")
	if t < GS.SUNSET + 1.0 / 72.0 * 8.0:
		return Color("d84a08")
	if t < GS.NIGHT:
		return Color("9a10c0")
	if t < GS.NIGHT + 4.5 / 24.0:
		return Color("0a3a50")
	return Color("0c1c3a")

func _draw_clock() -> void:
	var c := Vector2(34, 0)
	var r := 30.0
	clock.draw_circle(c, r + 4, Color("4a1e08"))
	clock.draw_circle(c, r + 3, Color("e8862a"))
	clock.draw_circle(c, r + 1, Color("a8501a"))
	var steps := 36
	for i in steps:
		var a0 := PI * float(i) / steps
		var a1 := PI * float(i + 1) / steps
		# a = 0 on the right, PI on the left; the bottom (PI / 2) is now
		var t := GS.clock + (((a0 + a1) / 2.0) - PI / 2) / TAU
		clock.draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r]), _sky_color(t))
	# the sun sits in the middle of the day, stars in the night
	var sun_t := GS.SUNSET / 2.0
	var sa := PI / 2 + (sun_t - GS.clock) * TAU
	sa = fposmod(sa, TAU)
	if sa > 0.1 and sa < PI - 0.1:
		clock.draw_rect(Rect2(c + Vector2(cos(sa), sin(sa)) * r * 0.6 - Vector2(3, 3), Vector2(6, 6)), Color("ffe868"))
	for k in 6:
		var st_t := GS.NIGHT + (k + 0.5) / 6.0 * (1.0 - GS.NIGHT)
		var a := fposmod(PI / 2 + (st_t - GS.clock) * TAU, TAU)
		if a > 0.15 and a < PI - 0.15:
			clock.draw_rect(Rect2(c + Vector2(cos(a), sin(a)) * r * (0.45 + 0.1 * (k % 3)), Vector2(1, 1)), Color("e8e078"))
	# the mountain in front
	clock.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, r + 1), c + Vector2(0, r - 8), c + Vector2(7, r + 1)]), Color("8a3a12"))
	clock.draw_colored_polygon(PackedVector2Array([c + Vector2(-2, r - 5), c + Vector2(0, r - 8), c + Vector2(2, r - 5)]), Color("f2efe6"))
	clock.draw_rect(Rect2(c.x - r - 4, -1, (r + 4) * 2, 2), Color("4a1e08"))

func _draw_boss() -> void:
	if not is_instance_valid(boss) or boss.dead:
		return
	var f: Font = Art.font_title
	var nm: String = boss.def.name
	var tw := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	boss_box.draw_string_outline(f, Vector2(90 - tw / 2, 7), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, C_DARK)
	boss_box.draw_string(f, Vector2(90 - tw / 2, 7), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, C_WHITE)
	boss_box.draw_rect(Rect2(0, 10, 180, 7), C_DARK)
	boss_box.draw_rect(Rect2(1, 11, 178 * clampf(boss.hp / boss.max_hp, 0, 1), 5), Color("e8402e"))
	var t := "%d / %d" % [int(boss.hp), int(boss.max_hp)]
	var w2 := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	boss_box.draw_string(f, Vector2(90 - w2 / 2, 17), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, C_WHITE)

func set_boss(b: Node) -> void:
	boss = b
	boss_box.visible = b != null

func _process(_d: float) -> void:
	clock.queue_redraw()
	var lvl: Node = main.level if main else null
	if lvl == null:
		return
	var town: bool = lvl.kind == "town"
	chat_btn.visible = Net.active
	if room_label and panels.pause.visible:
		room_label.text = _room_text()
	day_label.text = "Day %d" % (lvl.s_day if lvl.kind == "survival" else GS.day)
	bomb_btn.visible = not town
	gift_btn.visible = town and GS.gift_ready()
	var info := ""
	if lvl.kind == "arena" and not lvl.bosses_spawned:
		var s := int(lvl.arena_time_left())
		info = "Boss in %d:%02d" % [s / 60, s % 60]
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

## A line of text under the clock, like "Wood obtained". Fades after a moment.
func toast(text: String, kind: String = "") -> void:
	var color := C_WHITE
	match kind:
		"warn": color = Color("ffd0c0")
		"danger": color = Color("ff7a6a")
		"big": color = C_YELLOW
		"good": color = Color("c8ffb0")
	var l := _outlined(_label(text, 9, color))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(260, 0)
	toasts.add_child(l)
	while toasts.get_child_count() > 5:
		toasts.get_child(0).free()
	var tw := l.create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)

func _open_gift() -> void:
	var got := GS.open_gift()
	if got.is_empty():
		return
	toast("Daily Free Gift: %s x%d" % [Data.ITEMS[got[0]].name, got[1]], "big")

# ---------------------------------------------------------------- touch controls
func _build_touch() -> void:
	# grey ◀ ▶ on the left, red A above green B on the right, as in the original
	var specs := [["move_left", "<", Color("4a4a4c"), 90, 34, Color("b8b8bc")], ["move_right", ">", Color("4a4a4c"), 90, 34, Color("b8b8bc")],
		["attack", "A", Color("c01a12"), 68, 34, Color("f0a0a0")], ["jump", "B", Color("2a9a1e"), 68, 34, Color("b8f090")]]
	for s in specs:
		var t := TouchScreenButton.new()
		t.texture_normal = Art.button_tex(s[3], s[4], s[2])
		t.texture_pressed = Art.button_tex(s[3], s[4], s[2].darkened(0.25))
		t.action = s[0]
		t.passby_press = true
		var l := _label(s[1], 16, s[5], true)
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
	touch_nodes[0].position = Vector2(20, vs.y - 58)
	touch_nodes[1].position = Vector2(127, vs.y - 58)
	touch_nodes[2].position = Vector2(vs.x - 88, vs.y - 96)
	touch_nodes[3].position = Vector2(vs.x - 127, vs.y - 54)

func set_touch_visible(on: bool) -> void:
	for t in touch_nodes:
		t.visible = on and _touch() and not main.on_title()

func set_hud_visible(on: bool) -> void:
	hud_root.visible = on
	set_touch_visible(on)

# ---------------------------------------------------------------- panels
func _panel(key: String, size: Vector2, title: String = "", closable := true) -> Panel:
	var p := Panel.new()
	p.size = size
	p.visible = false
	root.add_child(p)
	panels[key] = p
	var t := _heading(title, 11)
	t.name = "Title"
	t.position = Vector2(9, 6)
	p.add_child(t)
	if closable:
		var x := _close_button(func(): close_panels())
		x.position = Vector2(size.x - 26, 5)
		p.add_child(x)
	return p

func _close_button(cb: Callable) -> Button:
	var x := _button("", cb)
	x.icon = Art.ui_icon("close")
	x.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	x.custom_minimum_size = Vector2(20, 18)
	return x

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
	if main.on_title() and not key in ["title", "friends", "trade_invite"]:
		return
	if not panels[key].visible:
		Sfx.play("open", 0.0)
	for k in panels:
		panels[k].visible = k == key
	main.set_paused(true)
	set_touch_visible(false)
	_place(key)
	# the bag covers the whole screen in the original, so the HUD hides behind it
	hud_root.visible = key != "bag" and not main.on_title()
	match key:
		"bag":
			bag_sel = -1
			move_from = -1
			_refresh_bag()
		"map": _refresh_map()
		"title": _refresh_title()
		"pause": _refresh_room_box()

func close_panels() -> void:
	if any_open() and not main.on_title():
		Sfx.play("close", 0.0)
	for k in panels:
		panels[k].visible = false
	station = null
	main.set_paused(false)
	set_touch_visible(true)
	hud_root.visible = not main.on_title()
	if main.on_title():
		panels.title.visible = true

## Centres a panel on screen; villager dialogs sit at the bottom.
func _place(key: String) -> void:
	var pn: Control = panels[key]
	var vs: Vector2 = get_viewport().get_visible_rect().size
	if key == "title":
		return
	if key == "npc":
		pn.position = Vector2(roundf((vs.x - pn.size.x) / 2), vs.y - pn.size.y - 4)
	else:
		pn.position = ((vs - pn.size) / 2).round()

func toggle_bag() -> void:
	if panels.bag.visible:
		close_panels()
	elif not any_open() and not main.on_title():
		# the original's auto-attack trick: open the bag while holding A
		if Input.is_action_pressed("attack") and main.level and main.level.player:
			main.level.player.auto_attack = true
		bag_mode = "bag"
		if not bag_tab in ["character", "combine", "menu"]:
			bag_tab = "combine"
		open_panel("bag")

# ---------------------------------------------------------------- bag, combining and the Crafter
func _build_bag() -> void:
	var p := Control.new()
	p.size = Vector2(440, 262)
	p.visible = false
	root.add_child(p)
	panels["bag"] = p
	# left: equipment column, then the trash and close buttons
	for i in GS.EQUIP_SLOTS.size():
		var slot: String = GS.EQUIP_SLOTS[i]
		var b := _slot(30)
		b.position = Vector2(0, 2 + i * 32)
		b.add_theme_stylebox_override("normal", _tex_box(Art.ui_frame("tab"), 4, 2))
		var sname := slot
		b.tooltip_text = slot.capitalize()
		b.pressed.connect(func():
			GS.unequip(sname)
			if sname == "pet":
				main.level.spawn_pet())
		p.add_child(b)
		equip_buttons[slot] = b
	var trash := _button("", func(): _trash_selected())
	trash.icon = Art.ui_icon("trash", 2)
	trash.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trash.position = Vector2(0, 200)
	trash.custom_minimum_size = Vector2(32, 26)
	trash.name = "Trash"
	p.add_child(trash)
	var x := _close_button(func(): close_panels())
	x.icon = Art.ui_icon("close", 2)
	x.position = Vector2(0, 232)
	x.custom_minimum_size = Vector2(32, 26)
	p.add_child(x)
	# middle: the 5 x 5 bag (top row is the hotbar)
	p.add_child(_frame(Vector2(38, 0), Vector2(170, 170)))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(45, 7)
	grid.add_theme_constant_override("h_separation", 1)
	grid.add_theme_constant_override("v_separation", 1)
	p.add_child(grid)
	for i in GS.BAG:
		var b := _slot(31)
		var idx := i
		b.pressed.connect(func(): _bag_click(idx))
		grid.add_child(b)
		bag_slots.append(b)
	# item info under the bag
	p.add_child(_frame(Vector2(38, 174), Vector2(170, 88)))
	info_box = VBoxContainer.new()
	info_box.position = Vector2(46, 180)
	info_box.size = Vector2(156, 76)
	info_box.add_theme_constant_override("separation", 2)
	p.add_child(info_box)
	# right: tabs and the page
	tab_row = HBoxContainer.new()
	tab_row.position = Vector2(214, 0)
	tab_row.add_theme_constant_override("separation", 2)
	p.add_child(tab_row)
	p.add_child(_frame(Vector2(214, 32), Vector2(226, 230)))
	page = Control.new()
	page.position = Vector2(220, 38)
	page.size = Vector2(214, 218)
	p.add_child(page)

func _tabs() -> Array:
	if bag_mode == "craft":
		return [["weapon", "sword_cast"], ["helmet", "copper_helmet"], ["armor", "iron_armor"], ["shield", "wooden_shield"], ["ring", "gold_ring"]]
	return [["character", ""], ["combine", ""], ["menu", ""]]

func _bag_click(i: int) -> void:
	if move_from >= 0:
		if move_from != i:
			GS.swap(move_from, i)
		move_from = -1
		bag_sel = i if GS.inv[i] else -1
		_refresh_bag()
		return
	# on the combine page, tapping an item puts it in the green slot
	if bag_mode == "bag" and bag_tab == "combine" and GS.inv[i] != null and not i in combo:
		combo[combo_target] = i
		for k in 3:
			if combo[(combo_target + k) % 3] < 0:
				combo_target = (combo_target + k) % 3
				break
	bag_sel = -1 if bag_sel == i or GS.inv[i] == null else i
	_refresh_bag()

func _trash_selected() -> void:
	if bag_sel < 0 or GS.inv[bag_sel] == null:
		toast("Pick an item to throw away first.", "warn")
		return
	var d = GS.inv[bag_sel]
	GS.inv[bag_sel] = null
	main.drop_from_player(d.id, d.n)
	bag_sel = -1
	GS.inventory_changed.emit()

func _refresh_bag() -> void:
	for i in GS.BAG:
		_fill_slot(bag_slots[i], GS.inv[i])
		_select_style(bag_slots[i], i == bag_sel or i == move_from or (bag_mode == "bag" and bag_tab == "combine" and i in combo))
	for slot in GS.EQUIP_SLOTS:
		var id: String = GS.equip[slot]
		_fill_slot(equip_buttons[slot], {"id": id, "n": 1} if id != "" else null, Art.equip_ghost(slot))
	# tabs
	_clear(tab_row)
	for t in _tabs():
		var key: String = t[0]
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(42 if bag_mode == "craft" else 72, 30)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if bag_mode == "craft":
			b.icon = Art.icon_big(t[1])
		else:
			b.icon = Art.ui_icon({"character": "backpack", "combine": "hammer", "menu": "compass"}[key], 2)
		b.tooltip_text = key.capitalize()
		b.pressed.connect(func(): bag_tab = key; craft_sel = -1; _refresh_bag())
		if key == bag_tab:
			b.add_theme_stylebox_override("normal", _tex_box(Art.ui_frame("green"), 3, 3))
			b.add_theme_stylebox_override("hover", _tex_box(Art.ui_frame("green"), 3, 3))
		tab_row.add_child(b)
	_clear(page)
	if bag_mode == "craft":
		_page_craft()
	else:
		match bag_tab:
			"character": _page_character()
			"combine": _page_combine()
			"menu": _page_menu()
	_refresh_info()

func _page_character() -> void:
	var pic := TextureRect.new()
	pic.texture = Art.character(GS.look, "stand", 3, GS.equip.helmet, GS.equip.armor)
	pic.position = Vector2(8, 8)
	page.add_child(pic)
	page.add_child(_at(_heading(GS.player_name, 10), Vector2(64, 6)))
	page.add_child(_at(_label(Data.CHARACTERS.get(GS.look, {"name": ""}).name, 9, C_MUTED), Vector2(64, 22)))
	var ar := GS.attack_range(GS.held())
	var lines := [["Attack", "%d-%d" % [ar.x, ar.y]], ["Defense", str(GS.stat("def"))], ["Magic", str(GS.stat("mag"))],
		["Health", str(int(GS.max_hp()))], ["Mana", str(int(GS.max_mp()))], ["Stamina", str(int(GS.max_st()))]]
	for i in lines.size():
		page.add_child(_at(_label(lines[i][0], 9), Vector2(64, 40 + i * 13)))
		page.add_child(_at(_label(lines[i][1], 9, C_EMBER, true), Vector2(130, 40 + i * 13)))
	page.add_child(_at(_wrap("Equip gear by tapping it in your bag, then Equip. Tap a slot on the left to take it off.", 200, C_MUTED, 8), Vector2(6, 124)))

func _page_combine() -> void:
	for i in 3:
		if combo[i] >= 0 and GS.inv[combo[i]] == null:
			combo[i] = -1
	var pv := GS.preview_combo(combo, use_scroll)
	var title := "Combine"
	var sub := "Tap items in your bag"
	if pv.ready and pv.known:
		title = Data.ITEMS[pv.recipe.out].name
		sub = "Success: %d%%" % pv.chance
	elif pv.ready:
		title = "???"
		sub = "Unknown combination"
	var t := _heading(title, 11)
	t.size = Vector2(214, 14)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(_at(t, Vector2(0, 2)))
	var s := _heading(sub, 9)
	s.size = Vector2(214, 12)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(_at(s, Vector2(0, 17)))
	# the big result slot and the scroll slot next to it
	var out := _slot(50)
	out.position = Vector2(82, 34)
	out.disabled = true
	out.add_theme_stylebox_override("disabled", _tex_box(Art.ui_frame("button"), 3, 1))
	if pv.ready and pv.known:
		_fill_slot(out, {"id": pv.recipe.out, "n": pv.recipe.get("n", 1)})
	else:
		_fill_slot(out, null)
	page.add_child(out)
	var sc := _slot(26)
	sc.name = "Scroll"
	sc.position = Vector2(150, 46)
	sc.tooltip_text = "Combination Scroll (+35%)"
	sc.add_theme_stylebox_override("normal", _tex_box(Art.ui_frame("button"), 3, 1))
	if GS.count("combination_scroll") == 0:
		use_scroll = false
	_fill_slot(sc, {"id": "combination_scroll", "n": 1} if use_scroll else null)
	sc.pressed.connect(func():
		if GS.count("combination_scroll") == 0:
			toast("You don't have a Combination Scroll.", "warn")
			return
		use_scroll = not use_scroll
		_refresh_bag())
	page.add_child(sc)
	# slots I, II and III; the green one is where the next item goes
	for i in 3:
		var b := _slot(36)
		b.name = "C%d" % i
		b.position = Vector2(41 + i * 46, 96)
		var ci := i
		b.pressed.connect(func():
			combo[ci] = -1
			combo_target = ci
			_refresh_bag())
		_fill_slot(b, GS.inv[combo[i]] if combo[i] >= 0 else null)
		if combo[i] < 0 and i == combo_target:
			b.add_theme_stylebox_override("normal", _tex_box(Art.ui_frame("green"), 3, 1))
			b.add_theme_stylebox_override("hover", _tex_box(Art.ui_frame("green"), 3, 1))
		page.add_child(b)
	var go := _button("Combine", func(): _do_combine())
	go.name = "Go"
	go.position = Vector2(57, 140)
	go.custom_minimum_size = Vector2(100, 22)
	go.disabled = not pv.ready
	page.add_child(go)
	var hint := "Two or three items. Read a Combo Book for recipes."
	if pv.ready and pv.known and not pv.book:
		hint = "%s in your bag adds +50%%." % Data.ITEMS[Data.BOOK_ITEM[pv.recipe.book]].name
	elif pv.ready and not pv.known:
		hint = "Unknown combinations turn into Dust."
	var h := _wrap(hint, 200, C_MUTED, 8)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(_at(h, Vector2(7, 168)))

func _page_menu() -> void:
	var v := VBoxContainer.new()
	v.position = Vector2(32, 10)
	v.custom_minimum_size = Vector2(150, 0)
	v.add_theme_constant_override("separation", 6)
	page.add_child(v)
	v.add_child(_heading(Data.WORLDS[main.level.id].name if main.level else "", 10))
	v.add_child(_button("Resume", func(): close_panels()))
	v.add_child(_button("Save and leave game", func(): main.quit_to_title()))
	v.add_child(_wrap("Tip: hold A and open the bag to keep attacking on your own. Press A to stop.", 150, C_MUTED, 8))

func _crafter_tab(id: String) -> String:
	var t: String = Data.ITEMS[id].type
	if t in ["weapon", "staff", "bow", "axe", "pick"]:
		return "weapon"
	return t

func _page_craft() -> void:
	var list := []
	for i in Data.SMITH.size():
		if _crafter_tab(Data.SMITH[i].out) == bag_tab:
			list.append(i)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(4, 4)
	scroll.size = Vector2(208, 210)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 1)
	grid.add_theme_constant_override("v_separation", 1)
	scroll.add_child(grid)
	for i in list:
		var b := _slot(31)
		var ri: int = i
		_fill_slot(b, {"id": Data.SMITH[i].out, "n": 1})
		if not GS.has_all(Data.SMITH[i].cost):
			b.get_node("Icon").modulate = Color(1, 1, 1, 0.5)
		_select_style(b, i == craft_sel)
		b.pressed.connect(func(): craft_sel = ri; bag_sel = -1; _refresh_bag())
		grid.add_child(b)
	if list.is_empty():
		page.add_child(_at(_wrap("Nothing to craft here yet.", 200, C_MUTED), Vector2(8, 8)))

func _refresh_info() -> void:
	_clear(info_box)
	if bag_mode == "craft" and craft_sel >= 0 and bag_sel < 0:
		var r: Dictionary = Data.SMITH[craft_sel]
		info_box.add_child(_label(Data.ITEMS[r.out].name, 10, C_EMBER))
		info_box.add_child(_cost_row(r.cost))
		var b := _button("Craft", func():
			if GS.smith(r):
				toast("%s obtained" % Data.ITEMS[r.out].name)
			_refresh_bag(), true)
		b.disabled = not GS.has_all(r.cost)
		b.custom_minimum_size = Vector2(70, 18)
		info_box.add_child(b)
		return
	if move_from >= 0:
		info_box.add_child(_wrap("Tap a slot to move the item there.", 156, C_MUTED))
		return
	if bag_sel < 0 or GS.inv[bag_sel] == null:
		info_box.add_child(_wrap("Tap an item to see what it does." if bag_mode == "bag" else "Pick something to craft. The Crafter never fails.", 156, C_MUTED))
		return
	var s = GS.inv[bag_sel]
	var it: Dictionary = Data.ITEMS[s.id]
	info_box.add_child(_label("%s%s" % [it.name, "  x%d" % s.n if s.n > 1 else ""], 10, C_EMBER))
	var extra := ""
	if it.has("dmg") and it.type in ["weapon", "axe", "pick", "bow", "throw"]:
		extra = " Attack %d, %.2fs per %s." % [it.dmg, it.spd, "shot" if it.type in ["bow", "throw"] else "swing"]
	var d := _wrap(it.desc + extra, 156, C_INK, 8)
	d.max_lines_visible = 3
	info_box.add_child(d)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	info_box.add_child(row)
	if it.type == "food":
		row.add_child(_small_button("Use", func(): GS.consume(bag_sel)))
	if GS.equip_slot_for(s.id) != "":
		row.add_child(_small_button("Equip", func():
			var is_pet: bool = it.type == "pet"
			GS.equip_from(bag_sel)
			if is_pet:
				main.level.spawn_pet()))
	if it.type == "book":
		row.add_child(_small_button("Read", func(): open_book(it.book)))
	if it.type == "character":
		row.add_child(_small_button("Become", func():
			toast(GS.use_character(bag_sel), "big")
			bag_sel = -1
			_refresh_bag()))
	if bag_sel >= GS.HOTBAR:
		row.add_child(_small_button("Hold", func():
			GS.swap(bag_sel, GS.sel)
			bag_sel = GS.sel
			_refresh_bag()))
	row.add_child(_small_button("Move", func(): move_from = bag_sel; _refresh_bag()))

func _small_button(text: String, cb: Callable) -> Button:
	var b := _button(text, cb)
	b.add_theme_font_size_override("font_size", 8)
	b.custom_minimum_size = Vector2(0, 16)
	return b

func _do_combine() -> void:
	var r := GS.combine(combo, use_scroll)
	if not r.ok:
		toast(r.reason, "warn")
	elif r.success:
		toast("%s obtained" % Data.ITEMS[r.out].name, "good")
	else:
		toast("The combination failed. Dust obtained" if r.get("known", false) else "Unknown combination. Dust obtained", "warn")
	combo_target = 0
	for k in 3:
		if combo[k] >= 0 and GS.inv[combo[k]] == null:
			combo[k] = -1
	_refresh_bag()

# ---------------------------------------------------------------- other panels
func _build_panels() -> void:
	# villager dialog, at the bottom of the screen
	var d := _panel("npc", Vector2(440, 96))
	var face := TextureRect.new()
	face.name = "Face"
	face.position = Vector2(10, 22)
	d.add_child(face)
	var text := _wrap("", 360)
	text.name = "Text"
	text.position = Vector2(66, 22)
	d.add_child(text)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.position = Vector2(66, 70)
	row.add_theme_constant_override("separation", 4)
	d.add_child(row)

	var sh := _panel("shop", Vector2(440, 240), "Shop")
	_scroll(sh, Vector2(10, 40), Vector2(206, 190)).name = "Buy"
	sh.add_child(_at(_label("Buy", 9, C_MUTED, true), Vector2(12, 26)))
	_scroll(sh, Vector2(224, 40), Vector2(206, 190)).name = "Sell"
	sh.add_child(_at(_label("Sell", 9, C_MUTED, true), Vector2(226, 26)))

	var bk := _panel("book", Vector2(440, 240), "Book")
	_scroll(bk, Vector2(10, 28), Vector2(420, 202))

	var st := _panel("station", Vector2(420, 220), "")
	var stext := _wrap("", 400)
	stext.name = "Text"
	stext.position = Vector2(10, 26)
	st.add_child(stext)
	_scroll(st, Vector2(10, 56), Vector2(400, 156))

	var m := _panel("map", Vector2(440, 214), "Gatekeeper")
	var cols := HBoxContainer.new()
	cols.name = "Cols"
	cols.position = Vector2(10, 28)
	cols.add_theme_constant_override("separation", 8)
	m.add_child(cols)
	m.add_child(_at(_wrap("Deeper levels are through the purple portal hidden underground. In arenas the boss comes after 3 minutes. In Survival, live through the nights for Survival Tokens.", 418, C_MUTED, 8), Vector2(10, 172)))

	var ch := _panel("chat", Vector2(320, 150), "Chat")
	var lines := _wrap("", 300, C_INK, 8)
	lines.name = "Lines"
	lines.position = Vector2(10, 26)
	lines.size = Vector2(300, 90)
	lines.max_lines_visible = 8
	lines.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	ch.add_child(lines)
	chat_edit = LineEdit.new()
	chat_edit.max_length = 80
	chat_edit.placeholder_text = "Type a message"
	chat_edit.position = Vector2(10, 118)
	chat_edit.size = Vector2(232, 24)
	chat_edit.text_submitted.connect(func(_t: String): _send_chat())
	ch.add_child(chat_edit)
	var send := _button("Send", func(): _send_chat(), true)
	send.position = Vector2(248, 118)
	send.custom_minimum_size = Vector2(62, 24)
	ch.add_child(send)

	var fr := _panel("friends", Vector2(440, 246), "Friends")
	var me := _label("", 9, C_INK)
	me.name = "Me"
	me.position = Vector2(80, 8)
	fr.add_child(me)
	var add_row := HBoxContainer.new()
	add_row.name = "AddRow"
	add_row.position = Vector2(10, 26)
	add_row.add_theme_constant_override("separation", 4)
	fr.add_child(add_row)
	_scroll(fr, Vector2(10, 56), Vector2(420, 182)).name = "FriendList"

	var tp := _panel("trade_pick", Vector2(260, 160), "Trading Table")
	_scroll(tp, Vector2(10, 28), Vector2(240, 124)).name = "PickList"

	var ti := _panel("trade_invite", Vector2(260, 90), "Trade?", false)
	var tit := _wrap("", 240)
	tit.name = "Text"
	tit.position = Vector2(10, 26)
	ti.add_child(tit)
	var tir := HBoxContainer.new()
	tir.position = Vector2(10, 56)
	tir.add_theme_constant_override("separation", 6)
	ti.add_child(tir)
	tir.add_child(_button("Trade", func(): close_panels(); Net.answer_trade(true), true))
	tir.add_child(_button("No thanks", func(): close_panels(); Net.answer_trade(false)))

	_build_trade()

	var info := _panel("info", Vector2(380, 140), "")
	var itext := _wrap("", 360)
	itext.name = "Text"
	itext.position = Vector2(10, 26)
	info.add_child(itext)

	var pz := _panel("pause", Vector2(260, 236), "Menu", false)
	var pv := VBoxContainer.new()
	pv.position = Vector2(20, 28)
	pv.custom_minimum_size = Vector2(220, 0)
	pv.add_theme_constant_override("separation", 6)
	pz.add_child(pv)
	pv.add_child(_button("Resume", func(): close_panels()))
	pv.add_child(_button("Save and leave game", func(): main.quit_to_title()))
	pv.add_child(_button("Friends", func(): open_friends()))
	var snd := _button("Sound: On" if Sfx.on else "Sound: Off", func(): pass)
	snd.pressed.connect(func():
		Sfx.set_on(not Sfx.on)
		snd.text = "Sound: On" if Sfx.on else "Sound: Off")
	pv.add_child(snd)
	room_label = _wrap("", 220, C_INK, 8)
	pv.add_child(room_label)
	room_box = VBoxContainer.new()
	room_box.add_theme_constant_override("separation", 2)
	pv.add_child(room_box)

	var dead := _panel("dead", Vector2(260, 110), "You fainted", false)
	var dtext := _wrap("", 240)
	dtext.name = "Text"
	dtext.position = Vector2(10, 26)
	dead.add_child(dtext)
	var wake := _button("Wake up in Pixel Town", func(): main.respawn(), true)
	wake.name = "Wake"
	wake.position = Vector2(10, 78)
	dead.add_child(wake)

	# the main menu: title, three character slots, creating a character, play mode
	var t := Control.new()
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.visible = false
	root.add_child(t)
	panels["title"] = t
	var screen := Control.new()
	screen.name = "Screen"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.add_child(screen)

# ---------------------------------------------------------------- main menu
func _logo(parent: Control, y: float) -> void:
	for i in 2:
		var l := _label(["PIXEL", "WILDS"][i], 34, Color("ffd21e"), true)
		l.add_theme_color_override("font_outline_color", Color("2a1206"))
		l.add_theme_constant_override("outline_size", 10)
		l.add_theme_color_override("font_shadow_color", Color("8a4a12"))
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 4)
		l.size = Vector2(480, 40)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.position = Vector2(0, y + i * 38)
		parent.add_child(l)

func _refresh_title(_choosing := false) -> void:
	if _choosing:
		menu_step = "create"
	var screen: Control = panels.title.get_node("Screen")
	_clear(screen)
	match menu_step:
		"title":
			_logo(screen, 34)
			var tap := _button("PLAY", func(): menu_step = "slots"; _refresh_title())
			tap.custom_minimum_size = Vector2(120, 28)
			tap.add_theme_font_override("font", Art.font_title)
			tap.add_theme_font_size_override("font_size", 12)
			screen.add_child(_at(tap, Vector2(180, 150)))
			var sub := _outlined(_label("Explore, combine, smelt and survive. Nothing to buy, ever.", 9, C_WHITE))
			sub.size = Vector2(480, 12)
			sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			screen.add_child(_at(sub, Vector2(0, 190)))
		"slots":
			var head := _heading("Choose a character slot", 12)
			head.size = Vector2(480, 16)
			head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			screen.add_child(_at(head, Vector2(0, 12)))
			for i in GS.SLOTS:
				screen.add_child(_slot_card(i, Vector2(24 + i * 148, 36)))
			screen.add_child(_at(_button("Back", func(): menu_step = "title"; _refresh_title()), Vector2(208, 236)))
		"create":
			var head2 := _heading("Create a character", 12)
			head2.size = Vector2(480, 16)
			head2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			screen.add_child(_at(head2, Vector2(0, 12)))
			for k in Data.START_CHARACTERS.size():
				var c: String = Data.START_CHARACTERS[k]
				var card := _frame(Vector2(110 + k * 140, 34), Vector2(120, 140))
				card.mouse_filter = Control.MOUSE_FILTER_PASS
				screen.add_child(card)
				var pic := _icon_button(Art.character(c, "stand", 4), Vector2(104, 100), func(): new_char = c; _refresh_title())
				pic.position = Vector2(8, 8)
				card.add_child(pic)
				var nb := _button(Data.CHARACTERS[c].name, func(): new_char = c; _refresh_title(), c == new_char)
				nb.position = Vector2(10, 112)
				nb.custom_minimum_size = Vector2(100, 20)
				card.add_child(nb)
			screen.add_child(_at(_heading("Name", 10), Vector2(110, 186)))
			var keep := name_edit.text if name_edit and is_instance_valid(name_edit) else GS.default_name()
			name_edit = LineEdit.new()
			name_edit.text = keep
			name_edit.max_length = 16
			name_edit.position = Vector2(150, 182)
			name_edit.size = Vector2(220, 20)
			screen.add_child(name_edit)
			screen.add_child(_at(_button("Back", func(): menu_step = "slots"; _refresh_title()), Vector2(150, 232)))
			var ok := _button("OK", func(): _create_ok(), true)
			ok.custom_minimum_size = Vector2(80, 22)
			screen.add_child(_at(ok, Vector2(250, 230)))
		"connecting":
			var c := _heading("Connecting to the room...", 12)
			c.size = Vector2(480, 16)
			c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			screen.add_child(_at(c, Vector2(0, 110)))
			screen.add_child(_at(_button("Cancel", func():
				Net.leave()
				menu_step = "mode"
				_refresh_title()), Vector2(208, 140)))
		"mode":
			_logo(screen, 20)
			var v := VBoxContainer.new()
			v.position = Vector2(160, 118)
			v.custom_minimum_size = Vector2(160, 0)
			v.add_theme_constant_override("separation", 8)
			screen.add_child(v)
			var info := GS.slot_info(GS.slot)
			var who := _heading(info.get("name", name_edit.text if name_edit and is_instance_valid(name_edit) else ""), 10)
			who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(who)
			var sp := _button("Play", func(): _start_from_menu(), true)
			sp.custom_minimum_size = Vector2(160, 26)
			v.add_child(sp)
			var mp := _button("Join a Friend", func(): open_friends())
			mp.custom_minimum_size = Vector2(160, 26)
			v.add_child(mp)
			v.add_child(_button("Back", func(): menu_step = "slots"; _refresh_title()))
			var note := _outlined(_label("Your world is your room: friends can join you from their friends list.", 8, C_WHITE))
			note.size = Vector2(480, 12)
			note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			screen.add_child(_at(note, Vector2(0, 252)))

func _room_text() -> String:
	if not Net.active:
		return "You're playing offline. Claim your name in Friends to open your room." if GS.online_token == "" else ""
	var names := [GS.player_name + " (you)"]
	for pid in Net.players:
		names.append(Net.players[pid].name)
	var t := "%s\n%d/%d players: %s" % ["Your room" if Net.is_host() else "A friend's room", Net.player_count(), Net.MAX_PLAYERS, ", ".join(names)]
	if Net.is_host():
		t += "\nFriends join you from their friends list. Nobody sees your IP address."
	return t

func chat_focused() -> bool:
	return chat_edit != null and chat_edit.has_focus()

func open_chat() -> void:
	open_panel("chat")
	_refresh_chat()
	chat_edit.grab_focus()

func add_chat(from: String, text: String) -> void:
	chat_log.append("%s: %s" % [from, text])
	while chat_log.size() > 8:
		chat_log.pop_front()
	toast("%s: %s" % [from, text], "good")
	if panels.has("chat") and panels.chat.visible:
		_refresh_chat()

func _refresh_chat() -> void:
	var lines: Label = panels.chat.get_node("Lines")
	lines.text = "\n".join(chat_log) if chat_log.size() > 0 else "Say hi to the room!"

func _send_chat() -> void:
	Net.say(chat_edit.text)
	chat_edit.text = ""
	close_panels()

## Makes the new character: the name must be free on this device and on the
## online server (each name can only be taken once).
func _create_ok() -> void:
	if busy:
		return
	var nm := name_edit.text.strip_edges()
	if not Online.valid_name(nm):
		toast("Names are 3 to 16 letters, numbers or _.", "warn")
		return
	if GS.name_in_other_slot(nm):
		toast("One of your other characters already has that name.", "warn")
		return
	busy = true
	toast("Checking the name...")
	var r := await Online.register(nm)
	busy = false
	if r.get("offline", false):
		toast("Couldn't reach the online server, so the name isn't claimed yet. Claim it later in Friends.", "warn")
		GS.pending_token = ""
	elif not r.get("ok", false):
		toast(r.get("error", "That name can't be used."), "danger")
		return
	else:
		GS.pending_token = r.token
	GS.new_game(new_char, nm)
	GS.save_game()
	menu_step = "mode"
	_refresh_title()

func _slot_card(i: int, pos: Vector2) -> Control:
	var card := _frame(pos, Vector2(136, 192))
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var info := GS.slot_info(i)
	var title := _heading("Slot %d" % (i + 1), 9)
	title.position = Vector2(10, 7)
	card.add_child(title)
	if info.is_empty():
		var empty := _label("Empty", 10, C_MUTED, true)
		empty.size = Vector2(136, 14)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(_at(empty, Vector2(0, 80)))
		var cb := _button("Create", func():
			GS.slot = i
			new_char = "man_in_suit"
			name_edit = null
			menu_step = "create"
			_refresh_title(), true)
		cb.custom_minimum_size = Vector2(100, 22)
		card.add_child(_at(cb, Vector2(18, 158)))
		return card
	var pic := TextureRect.new()
	pic.texture = Art.character(info.look, "stand", 4)
	pic.position = Vector2(40, 22)
	card.add_child(pic)
	var nm := _label(info.name, 9, C_INK)
	nm.size = Vector2(136, 12)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	card.add_child(_at(nm, Vector2(0, 116)))
	var dl := _label("Day %d" % info.day, 8, C_MUTED, true)
	dl.size = Vector2(136, 12)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_at(dl, Vector2(0, 130)))
	var play := _button("Play", func():
		GS.slot = i
		menu_step = "mode"
		_refresh_title(), true)
	play.custom_minimum_size = Vector2(70, 22)
	card.add_child(_at(play, Vector2(12, 158)))
	var del := _button("", func():
		GS.delete_slot(i)
		toast("Slot %d deleted." % (i + 1), "warn")
		_refresh_title())
	del.icon = Art.ui_icon("trash", 2)
	del.custom_minimum_size = Vector2(32, 22)
	card.add_child(_at(del, Vector2(90, 158)))
	return card

func _start_from_menu() -> void:
	if GS.slot_info(GS.slot).is_empty():
		var nm := name_edit.text.strip_edges() if name_edit and is_instance_valid(name_edit) else ""
		main.start_game(false, new_char, nm)
	else:
		main.start_game(true)

func show_dead(text: String) -> void:
	if Net.active:
		text = "Your friends can keep going. Get back up at the start of this map."
	panels.dead.get_node("Wake").text = "Get back up" if Net.active else "Wake up in Pixel Town"
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

func _refresh_npc(npc_id: String, said: String = "") -> void:
	var p: Panel = panels.npc
	var npc: Dictionary = Data.NPCS[npc_id]
	p.get_node("Title").text = npc.name
	var face: TextureRect = p.get_node("Face")
	var full: Image = Art.character(npc.look, "stand", 1).get_image()
	var head := full.get_region(Rect2i(0, 2, full.get_width(), 14))
	head.resize(head.get_width() * 3, head.get_height() * 3, Image.INTERPOLATE_NEAREST)
	face.texture = ImageTexture.create_from_image(head)
	var row: HBoxContainer = p.get_node("Row")
	_clear(row)
	var text: String = said if said != "" else npc.talk
	var q := GS.next_quest(npc_id)
	if not q.is_empty() and said == "":
		text = q.text
		var need := []
		for id in q.need:
			need.append("%d %s (%d)" % [q.need[id], Data.ITEMS[id].name, GS.count(id)])
		text += "\nBring: %s" % ", ".join(need)
		var give := _button("Give", func():
			GS.complete_quest(q)
			toast("Quest Complete!", "big")
			if q.get("unlock", "") == "furnaces":
				main.reload_level()
			_refresh_npc(npc_id, ["Thank you %s!", "You are amazing %s!"][randi() % 2] % GS.player_name), true)
		give.disabled = not GS.quest_ready(q)
		row.add_child(give)
	if Data.SHOPS.has(npc_id) and GS.flags.get(Data.SHOPS[npc_id].get("needs", ""), true):
		row.add_child(_button("Shop", func(): open_shop(npc_id)))
	if npc_id == "smith":
		row.add_child(_button("Craft", func(): open_smith(), true))
	if npc_id == "keeper":
		row.add_child(_button("Open a portal", func(): open_panel("map"), true))
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
			toast("%s obtained" % Data.ITEMS[id].name)
			_refresh_shop(npc_id)))
	if not shop.get("buys", false):
		sell.add_child(_wrap("This shop doesn't buy anything.", 190, C_MUTED))
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
	row.custom_minimum_size = Vector2(190, 18)
	row.add_child(_icon(id))
	var l := _label(text, 9)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.clip_text = true
	row.add_child(l)
	var b := _button(verb, cb)
	b.disabled = not enabled
	row.add_child(b)
	return row

# the Crafter: the bag on the left, his list on the right, sorted into tabs
func open_smith() -> void:
	bag_mode = "craft"
	bag_tab = "weapon"
	craft_sel = -1
	open_panel("bag")

# books
func open_book(book: String) -> void:
	open_panel("book")
	panels.book.get_node("Title").text = Data.ITEMS[Data.BOOK_ITEM[book]].name
	var list: VBoxContainer = panels.book.find_child("List", true, false)
	_clear(list)
	list.add_child(_wrap("These combinations get +50% while this book is in your bag. A Combination Scroll adds +35%.", 400, C_MUTED))
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
		row.add_child(_label("Success: %d%%  (book %d%%)" % [maxi(0, r.rate), clampi(r.rate + 50, 0, 100)], 8, C_EMBER))
		list.add_child(row)

# world list
func _refresh_map() -> void:
	var cols: HBoxContainer = panels.map.get_node("Cols")
	_clear(cols)
	for section in Data.WORLD_MENU:
		var v := VBoxContainer.new()
		v.custom_minimum_size = Vector2(134, 0)
		v.add_theme_constant_override("separation", 3)
		v.add_child(_heading(section[0], 10))
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
	_station_body(station.kind, station.index, title, text, list)
	_fit_station()

func _station_body(k: String, i: int, title: Label, text: Label, list: VBoxContainer) -> void:
	match k:
		"furnace":
			title.text = "Furnace %d" % (i + 1)
			var job = GS.furnaces[i]
			if not GS.flags.get("furnaces", false):
				text.text = "Don't touch! [Property of the GateKeeper] Bring him a Pretzel."
			elif job == null:
				text.text = "Five ores and a coal make a bar. It keeps smelting even while you're away."
				for r in Data.SMELT:
					var rr: Dictionary = r
					var row := HBoxContainer.new()
					row.add_child(_icon(r.out))
					var nl := _label("%s  (%s)" % [Data.ITEMS[r.out].name, _dur(r.time)], 9)
					nl.custom_minimum_size = Vector2(150, 0)
					row.add_child(nl)
					var c := _cost_row(r.cost)
					c.custom_minimum_size = Vector2(160, 0)
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
					var out_id: String = job.out
					if not GS.collect_smelt(i):
						toast("Inventory full.", "warn")
					else:
						toast("%s obtained" % Data.ITEMS[out_id].name)
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
					list.add_child(_wrap("You don't have any eggs. Monsters drop them now and then.", 380, C_MUTED))
			elif GS.now() < GS.incubator.done:
				text.text = "Hatching %s. Ready in %s." % [Data.ITEMS[GS.incubator.egg].name, _dur(GS.incubator.done - GS.now())]
			else:
				text.text = "Something hatched!"
				list.add_child(_button("Collect pet", func():
					var pet := GS.collect_hatch()
					if pet != "":
						toast("%s obtained" % Data.ITEMS[pet].name, "good")
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
					list.add_child(_wrap("You don't have any magic seeds.", 380, C_MUTED))
			elif GS.now() < s.done:
				text.text = "Growing. Ready in %s." % _dur(s.done - GS.now())
			else:
				text.text = "Fully grown!"
				list.add_child(_button("Harvest", func():
					var loot := GS.harvest(i)
					_refresh_station()
					_show_loot(loot), true))

func _fit_station() -> void:
	var p: Panel = panels.station
	var list: VBoxContainer = p.find_child("List", true, false)
	p.size = Vector2(420, 220) if list.get_child_count() > 1 else Vector2(300, 100)
	p.find_child("List", true, false).get_parent().size = Vector2(p.size.x - 20, p.size.y - 64)
	p.get_node("Text").custom_minimum_size.x = p.size.x - 20
	p.get_node("Text").size.x = p.size.x - 20
	for c in p.get_children():
		if c is Button and c.name != "List":
			c.position.x = p.size.x - 26
	_place("station")

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
	for l in loot:
		toast("%s obtained%s" % [Data.ITEMS[l[0]].name, " x%d" % l[1] if l[1] > 1 else ""], "good")

func _dur(sec: float) -> String:
	var s := int(maxf(sec, 0))
	if s >= 3600:
		return "%dh %02dm" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		return "%dm %02ds" % [s / 60, s % 60]
	return "%ds" % s

# ---------------------------------------------------------------- friends
func open_friends() -> void:
	if main.on_title() and GS.slot_info(GS.slot).is_empty():
		toast("Make your character first.", "warn")
		return
	if main.on_title():
		GS.load_game()
	open_panel("friends")
	_refresh_friends()

func _refresh_friends() -> void:
	var p: Panel = panels.friends
	var list: VBoxContainer = p.find_child("FriendList", true, false)
	var add_row: HBoxContainer = p.get_node("AddRow")
	_clear(list)
	_clear(add_row)
	(p.get_node("Me") as Label).text = "You: %s" % GS.player_name
	if GS.online_token == "":
		# this character's name was never claimed (made while offline)
		var ne := LineEdit.new()
		ne.text = GS.player_name
		ne.max_length = 16
		ne.custom_minimum_size = Vector2(200, 22)
		add_row.add_child(ne)
		add_row.add_child(_button("Claim this name", func(): _claim_name(ne.text.strip_edges()), true))
		list.add_child(_wrap("Claim your name to use friends. Each name can only belong to one player, so if it's taken, pick another (your character gets the new name).", 400, C_MUTED))
		return
	var fe := LineEdit.new()
	fe.placeholder_text = "Friend's name"
	fe.max_length = 16
	fe.custom_minimum_size = Vector2(200, 22)
	add_row.add_child(fe)
	add_row.add_child(_button("Add friend", func(): _add_friend(fe.text.strip_edges()), true))
	add_row.add_child(_button("Refresh", func(): _refresh_friends()))
	list.add_child(_label("Loading...", 9, C_MUTED))
	var r := await Online.friends()
	if not panels.friends.visible:
		return
	_clear(list)
	if not r.get("ok", false):
		list.add_child(_wrap(r.get("error", "Can't reach the online server."), 400, C_BAD))
		return
	var reqs: Array = r.get("requests", [])
	if reqs.size() > 0:
		list.add_child(_heading("Friend requests", 9))
		for nm in reqs:
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 4)
			var l := _label(str(nm), 9)
			l.custom_minimum_size = Vector2(200, 0)
			row.add_child(l)
			var who: String = nm
			row.add_child(_button("Accept", func(): _answer(who, true), true))
			row.add_child(_button("Decline", func(): _answer(who, false)))
			list.add_child(row)
	var fl: Array = r.get("friends", [])
	list.add_child(_heading("Friends (%d)" % fl.size(), 9))
	if fl.is_empty():
		list.add_child(_wrap("No friends yet. Type a name above, or add players from your room in the compass menu.", 400, C_MUTED))
	for f in fl:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var dot := ColorRect.new()
		dot.color = C_GOOD if f.online else Color("9a8a7a")
		dot.custom_minimum_size = Vector2(6, 6)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		var l := _label(str(f.name), 9)
		l.custom_minimum_size = Vector2(130, 0)
		row.add_child(l)
		var status := "Playing (%d/4)" % int(f.get("players", 1)) if f.room else ("Online" if f.online else "Offline")
		var sl := _label(status, 8, C_MUTED)
		sl.custom_minimum_size = Vector2(80, 0)
		row.add_child(sl)
		if f.room:
			var host_name: String = f.name
			row.add_child(_button("Join", func(): _join_friend(host_name), true))
		var fname: String = f.name
		row.add_child(_button("Remove", func(): _remove_friend(fname)))
		list.add_child(row)

func _claim_name(nm: String) -> void:
	if busy:
		return
	if not Online.valid_name(nm):
		toast("Names are 3 to 16 letters, numbers or _.", "warn")
		return
	if nm.to_lower() != GS.player_name.to_lower() and GS.name_in_other_slot(nm):
		toast("One of your other characters already has that name.", "warn")
		return
	busy = true
	var r := await Online.register(nm)
	busy = false
	if not r.get("ok", false):
		toast(r.get("error", "That name can't be used."), "danger")
		return
	GS.online_token = r.token
	GS.player_name = r.name
	GS.save_game()
	if main.level and main.level.player and main.level.player.name_label:
		main.level.player.name_label.text = GS.player_name
	toast("The name %s is yours!" % GS.player_name, "good")
	_refresh_friends()

func _add_friend(nm: String) -> void:
	if nm == "":
		return
	var r := await Online.add_friend(nm)
	if r.get("ok", false):
		toast("You're now friends with %s!" % nm if r.get("friends", false) else "Friend request sent to %s." % nm, "good")
	else:
		toast(r.get("error", "Couldn't add them."), "warn")
	if panels.friends.visible:
		_refresh_friends()

func _answer(nm: String, accept: bool) -> void:
	await Online.answer(nm, accept)
	_refresh_friends()

func _remove_friend(nm: String) -> void:
	await Online.remove_friend(nm)
	_refresh_friends()

## Joins the room a friend is hosting (your own room closes first).
func _join_friend(friend: String) -> void:
	if not main.on_title():
		main.quit_to_title()
	menu_step = "connecting"
	open_panel("title")
	main.join_game(friend)

func _refresh_room_box() -> void:
	if room_box == null:
		return
	_clear(room_box)
	if not Net.active:
		return
	for pid in Net.players:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var l := _label(Net.players[pid].name, 8)
		l.custom_minimum_size = Vector2(120, 0)
		row.add_child(l)
		if GS.online_token != "":
			var nm: String = Net.players[pid].name
			row.add_child(_small_button("Add friend", func(): _add_friend(nm)))
		room_box.add_child(row)

# ---------------------------------------------------------------- trading
func open_trade_pick() -> void:
	if not Net.active:
		toast("Trading needs friends in your room. Claim your name in Friends so they can join.", "warn")
		return
	open_panel("trade_pick")
	var list: VBoxContainer = panels.trade_pick.find_child("PickList", true, false)
	_clear(list)
	var here := Net.players_in_town()
	if here.is_empty():
		list.add_child(_wrap("Nobody else from your room is in Pixel Town right now.", 230, C_MUTED))
		return
	list.add_child(_wrap("Who do you want to trade with?", 230, C_MUTED))
	for pid in here:
		var row := HBoxContainer.new()
		var l := _label(Net.players[pid].name, 9)
		l.custom_minimum_size = Vector2(150, 0)
		row.add_child(l)
		var peer: int = pid
		row.add_child(_button("Trade", func(): close_panels(); Net.ask_trade(peer), true))
		list.add_child(row)

func _on_trade_invited(_peer: int, from: String) -> void:
	open_panel("trade_invite")
	(panels.trade_invite.get_node("Text") as Label).text = "%s wants to trade with you." % from

func _build_trade() -> void:
	var t := _panel("trade", Vector2(440, 250), "Trade", false)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.position = Vector2(10, 28)
	grid.add_theme_constant_override("h_separation", 1)
	grid.add_theme_constant_override("v_separation", 1)
	t.add_child(grid)
	for i in GS.BAG:
		var b := _slot(28)
		var idx := i
		b.pressed.connect(func(): _trade_toggle(idx))
		grid.add_child(b)
		trade_bag.append(b)
	t.add_child(_at(_wrap("Tap items in your bag to offer them.", 145, C_MUTED, 8), Vector2(10, 176)))
	t.add_child(_at(_heading("You give", 9), Vector2(166, 24)))
	var mine := HBoxContainer.new()
	mine.name = "Mine"
	mine.position = Vector2(166, 38)
	mine.add_theme_constant_override("separation", 1)
	t.add_child(mine)
	var crow := HBoxContainer.new()
	crow.name = "Coins"
	crow.position = Vector2(166, 72)
	crow.add_theme_constant_override("separation", 3)
	t.add_child(crow)
	var them_h := _heading("They give", 9)
	them_h.name = "TheirName"
	t.add_child(_at(them_h, Vector2(166, 100)))
	var theirs := HBoxContainer.new()
	theirs.name = "Theirs"
	theirs.position = Vector2(166, 114)
	theirs.add_theme_constant_override("separation", 1)
	t.add_child(theirs)
	var tc := _label("", 9, C_INK, true)
	tc.name = "TheirCoins"
	tc.position = Vector2(166, 150)
	t.add_child(tc)
	var st := _label("", 9, C_INK)
	st.name = "State"
	st.position = Vector2(166, 172)
	t.add_child(st)
	var ready := _button("Ready", func(): Net.set_ready(not Net.trade_ready_me), true)
	ready.name = "Ready"
	ready.position = Vector2(166, 208)
	ready.custom_minimum_size = Vector2(110, 24)
	t.add_child(ready)
	t.add_child(_at(_button("Cancel", func(): Net.cancel_trade()), Vector2(290, 208)))
	Net.trade_invited.connect(_on_trade_invited)
	Net.trade_started.connect(func(): open_panel("trade"); _refresh_trade())
	Net.trade_changed.connect(_refresh_trade)
	Net.trade_closed.connect(func():
		if panels.trade.visible or panels.trade_invite.visible:
			close_panels())

func _trade_toggle(i: int) -> void:
	var slots: Array = Net.trade_mine.duplicate()
	if i in slots:
		slots.erase(i)
	elif GS.inv[i] != null and slots.size() < Net.TRADE_SLOTS:
		var it: Dictionary = Data.ITEMS[GS.inv[i].id]
		if it.type in ["book"] and GS.inv[i].id == "survival_book":
			toast("The Survival Book can't be traded.", "warn")
			return
		slots.append(i)
	Net.set_offer(slots, Net.trade_coins)

func _refresh_trade() -> void:
	if not Net.trading():
		return
	var t: Panel = panels.trade
	var partner: String = Net.players.get(Net.trade_peer, {"name": "?"}).name
	(t.get_node("Title") as Label).text = "Trade with %s" % partner
	(t.get_node("TheirName") as Label).text = "%s gives" % partner
	for i in GS.BAG:
		_fill_slot(trade_bag[i], GS.inv[i])
		_select_style(trade_bag[i], i in Net.trade_mine)
	var mine: HBoxContainer = t.get_node("Mine")
	_clear(mine)
	var offer := Net.my_offer()
	for k in Net.TRADE_SLOTS:
		var b := _slot(28)
		if k < offer.size():
			_fill_slot(b, {"id": offer[k][0], "n": offer[k][1]})
			var slot_i: int = Net.trade_mine[k]
			b.pressed.connect(func(): _trade_toggle(slot_i))
		else:
			_fill_slot(b, null)
		mine.add_child(b)
	var crow: HBoxContainer = t.get_node("Coins")
	_clear(crow)
	var ci := TextureRect.new()
	ci.texture = Art.prop_tex("coin")
	ci.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	crow.add_child(ci)
	var cl := _label(str(Net.trade_coins), 9, C_INK, true)
	cl.custom_minimum_size = Vector2(44, 0)
	crow.add_child(cl)
	for add in [10, 100, 1000]:
		var amount: int = add
		crow.add_child(_small_button("+%d" % amount, func(): Net.set_offer(Net.trade_mine, mini(GS.coins, Net.trade_coins + amount))))
	crow.add_child(_small_button("Clear", func(): Net.set_offer(Net.trade_mine, 0)))
	var theirs: HBoxContainer = t.get_node("Theirs")
	_clear(theirs)
	var their_items: Array = Net.trade_theirs.items
	for k in Net.TRADE_SLOTS:
		var b := _slot(28)
		b.disabled = true
		if k < their_items.size() and Data.ITEMS.has(str(their_items[k][0])):
			_fill_slot(b, {"id": str(their_items[k][0]), "n": int(their_items[k][1])})
		else:
			_fill_slot(b, null)
		theirs.add_child(b)
	(t.get_node("TheirCoins") as Label).text = "%d coins" % Net.trade_theirs.coins
	(t.get_node("State") as Label).text = "You: %s     %s: %s" % ["Ready!" if Net.trade_ready_me else "not ready", partner, "Ready!" if Net.trade_ready_them else "not ready"]
	var rb: Button = t.get_node("Ready")
	rb.text = "Not ready" if Net.trade_ready_me else "Ready"
