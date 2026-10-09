extends Node
## Two copies of the game play together over the network.
## Run one with `-- --nettest host` and another with `-- --nettest client`.

const PlacedScript := preload("res://scripts/placed.gd")
const NodeScript := preload("res://scripts/res_node.gd")

var main: Node
var role := "host"
var out := "user://shots"
var fails := []
var chat_log := []

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var args := OS.get_cmdline_user_args()
	var i := args.find("--nettest")
	if i >= 0 and i + 1 < args.size():
		role = args[i + 1]
	Net.chat_received.connect(func(_f: String, t: String): chat_log.append(t))
	if role == "host":
		run_host()
	else:
		run_client()

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func until(cond: Callable, timeout: float) -> bool:
	var t := 0.0
	while not cond.call() and t < timeout:
		await wait(0.25)
		t += 0.25
	return cond.call()

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + "[%s] %s" % [role, what])
	if not ok:
		fails.append(what)

func tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)

func shot(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])

func finish() -> void:
	print("NETTEST %s DONE, %d failures: %s" % [role, fails.size(), fails])
	get_tree().quit()

func run_host() -> void:
	await wait(1.0)
	GS.slot = 2
	GS.delete_slot(2)
	var reg := await Online.register("HostA")
	check(reg.get("ok", false), "the host claims the name HostA online")
	GS.pending_token = reg.get("token", "")
	GS.new_game("man_in_suit", "HostA")
	GS.save_game()
	main.start_game(true)
	check(Net.is_host(), "starting the game opens the host's own room")
	check(await until(func(): return Net.relay != null and Net.relay.status == MultiplayerPeer.CONNECTION_CONNECTED, 15.0), "the room is open on the relay")
	# the friend asks to be friends; accept it (only friends can join)
	var got_req := false
	for k in 80:
		var fr := await Online.friends()
		if "Friend1" in fr.get("requests", []):
			got_req = true
			break
		await wait(0.5)
	check(got_req, "the host got a friend request from Friend1")
	await Online.answer("Friend1", true)
	check(await until(func(): return Net.players.size() == 1, 60.0), "a friend joined the room")
	check(await until(func(): return main.level.puppets.size() == 1, 10.0), "the host sees the friend in Pixel Town")
	await wait(0.5)
	await shot("net_host_town")
	main.change_level("grass_1")
	check(await until(func(): return main.level.puppets.size() == 1, 20.0), "the friend followed the host to Grasslands 1")
	var lvl: Node = main.level
	lvl.player.position = lvl.cell_pos(Vector2i(40, lvl.surface[40] - 1)) # step away so the slime picks the friend
	lvl.player.invuln = 9999.0
	await wait(1.0)
	var pp: Node2D = lvl.puppets.values()[0]
	lvl.drop("wood", 3, pp.position + Vector2(0, -10))
	var slime: Node = lvl.spawn_mob_at("slime", pp.position + Vector2(14, 0))
	slime.aggro_forced = true
	check(await until(func(): return chat_log.has("hello from friend"), 90.0), "the friend's chat message arrived")
	var placed := 0
	for n in lvl.props.get_children():
		if n is PlacedScript:
			placed += 1
	check(placed == 1, "the friend's wall was built in the host's world")
	check(await until(func(): return main.level.id == "grass_2", 20.0), "the friend's portal request moved the whole room")
	await wait(1.0)
	await shot("net_host_grass2")
	# trading at the Trading Center
	check(await until(func(): return main.level.id == "town", 30.0), "the room went back to Pixel Town")
	GS.flags["trade_wall"] = true
	GS.add_item("wood", 5)
	var coins0 := GS.coins
	check(await until(func(): return chat_log.has("ready to trade"), 90.0), "the friend burned the wall and is at the Trading Center")
	var friend_peer: int = Net.players.keys()[0]
	Net.ask_trade(friend_peer)
	check(await until(func(): return Net.trading(), 15.0), "the friend accepted the trade")
	var wood_slot := -1
	for i in GS.BAG:
		if GS.inv[i] and GS.inv[i].id == "wood":
			wood_slot = i
	Net.set_offer([wood_slot], 0)
	check(await until(func(): return Net.trade_theirs.items.size() > 0, 15.0), "the host sees the friend's offer")
	await shot("net_host_trade")
	Net.set_ready(true)
	check(await until(func(): return not Net.trading(), 20.0), "the trade finished")
	check(GS.count("rock") == 3 and GS.coins == coins0 + 50 and GS.count("wood") == 0, "the host got 3 Rocks and 50 coins for 5 Wood")
	check(await until(func(): return Net.players.is_empty(), 30.0), "the friend left the room")
	finish()

func run_client() -> void:
	await wait(4.0)
	GS.slot = 1
	GS.delete_slot(1)
	var taken := await Online.register("hosta")
	check(not taken.get("ok", true) and str(taken.get("error", "")).contains("taken"), "HostA's name can't be taken again, even as hosta")
	var reg := await Online.register("Friend1")
	check(reg.get("ok", false), "the friend claims the name Friend1")
	GS.pending_token = reg.get("token", "")
	GS.new_game("nurse", "Friend1")
	GS.save_game()
	await wait(2.0)
	# not friends yet: the room won't let you in
	main.join_game("HostA")
	check(await until(func(): return not Net.active and main.on_title(), 20.0), "a player who isn't a friend can't join the room")
	var add := await Online.add_friend("HostA")
	check(add.get("ok", false), "sent HostA a friend request")
	var in_room := false
	var fr_text := ""
	for k in 80:
		var fr := await Online.friends()
		fr_text = JSON.stringify(fr)
		for f in fr.get("friends", []):
			if f.name == "HostA" and f.room == true:
				in_room = true
		if in_room:
			break
		await wait(0.5)
	check(in_room, "HostA shows in the friends list as playing")
	check(not fr_text.contains("127.0.0.1") and not fr_text.contains("ip"), "the friends list never shows an IP address")
	main.hud.menu_step = "mode"
	main.hud.open_friends()
	await wait(1.5)
	await shot("net_client_friends")
	main.hud._join_friend("HostA")
	check(await until(func(): return not main.on_title() and main.level.id == "town", 60.0), "joined the room in Pixel Town")
	check(await until(func(): return main.level.puppets.size() == 1, 10.0), "the friend sees the host")
	check(await until(func(): return main.level.id == "grass_1", 30.0), "followed the host to Grasslands 1")
	var lvl: Node = main.level
	await wait(1.0)
	var nodes := 0
	for n in lvl.props.get_children():
		if n is NodeScript:
			nodes += 1
	check(lvl.count_mobs() > 10 and nodes > 50, "the host's monsters (%d) and resources (%d) are here" % [lvl.count_mobs(), nodes])
	check(await until(func(): return GS.count("wood") >= 3, 20.0), "picked up the wood the host dropped")
	var hp0: float = GS.hp
	check(await until(func(): return GS.hp < hp0, 20.0), "the host's slime hurt the friend")
	await shot("net_client_grass1")
	check(main.hud.chat_btn.visible and main.hud.chat_btn.size.y <= 14, "the Chat.. box shows under the bars")
	GS.hp = GS.max_hp()
	var m: Node = lvl.nearest_mob(lvl.player.position, 400)
	var nid: int = m.nid if m else -1
	if m:
		m.take_damage(99999, m.position.x - 5, false)
	check(await until(func(): return nid > 0 and not lvl.net_objs.has(nid), 10.0), "the friend's hit killed the host's monster")
	var tree: Node = null
	for n in lvl.props.get_children():
		if n is NodeScript and n.alive and n.kind == "tree":
			tree = n
			break
	for k in 40:
		if tree == null or not tree.alive:
			break
		tree.hit(5)
		await wait(0.2)
	check(tree != null and not tree.alive, "the friend chopped down the host's tree")
	GS.add_item("wood_wall", 1)
	lvl.player.position = lvl.cell_pos(lvl.spawn_cell)
	await wait(0.5)
	lvl.place("wood_wall", lvl.player.position, 1)
	var placed := 0
	await wait(1.5)
	for n in lvl.props.get_children():
		if n is PlacedScript:
			placed += 1
	check(placed == 1, "the wall shows up for the friend too")
	main.hud.open_chat()
	main.hud.chat_edit.text = "hello from friend"
	await shot("net_client_chat")
	main.hud._send_chat()
	await wait(1.0)
	main.change_level("grass_2")
	check(await until(func(): return main.level.id == "grass_2", 20.0), "the room moved to Grasslands 2")
	await wait(1.0)
	await shot("net_client_grass2")
	# back to town, burn the wall with a torch, and go to the Trading Center
	main.change_level("town")
	check(await until(func(): return main.level.id == "town", 20.0), "the room went back to Pixel Town")
	await wait(0.5)
	lvl = main.level
	var wall: Node = null
	for n in lvl.props.get_children():
		if n is NodeScript and n.kind == "trade_wall":
			wall = n
	check(wall != null, "a wooden wall blocks the Trading Center")
	GS.inv[4] = {"id": "torch_weapon", "n": 1}
	GS.sel = 4
	GS.inventory_changed.emit()
	var p: Node2D = lvl.player
	p.position = wall.position + Vector2(12, -1)
	p.facing = -1
	await wait(0.3)
	await shot("net_client_wall")
	for k in 4:
		p.cooldown = 0
		await tap("attack")
		await wait(1.1)
	check(GS.flags.get("trade_wall", false), "the Torch burned the wall down")
	p.position = lvl.cell_pos(Vector2i(26, 10))
	GS.add_item("rock", 3)
	GS.coins = 100
	Net.say("ready to trade")
	check(await until(func(): return Net.trade_invite_from != 0, 30.0), "HostA asked to trade")
	await shot("net_client_trade_invite")
	main.hud.close_panels()
	Net.answer_trade(true)
	check(await until(func(): return Net.trading() and main.hud.panels.trade.visible, 10.0), "the trade window opened")
	var rock_slot := -1
	for i in GS.BAG:
		if GS.inv[i] and GS.inv[i].id == "rock":
			rock_slot = i
	Net.set_offer([rock_slot], 50)
	check(await until(func(): return Net.trade_theirs.items.size() > 0, 15.0), "the friend sees HostA's offer")
	await wait(0.5)
	await shot("net_client_trade")
	Net.set_ready(true)
	check(await until(func(): return not Net.trading(), 20.0), "the trade finished")
	check(GS.count("wood") >= 5 and GS.count("rock") == 0 and GS.coins == 50, "the friend got 5 Wood for 3 Rocks and 50 coins")
	await wait(0.5)
	main.quit_to_title()
	await wait(1.0)
	finish()
