extends Node
## Two copies of the game play together over the network.
## Run one with `-- --nettest host` and another with `-- --nettest client`.

const PlacedScript := preload("res://scripts/placed.gd")
const PortalScript := preload("res://scripts/portal.gd")
const NodeScript := preload("res://scripts/res_node.gd")
const MobScript := preload("res://scripts/mob.gd")
const PickupScript := preload("res://scripts/pickup.gd")

var main: Node
var role := "host"
var out := "user://shots"
var fails := []
var chat_log := []

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	GS.auto_hit = false
	var args := OS.get_cmdline_user_args()
	var i := args.find("--nettest")
	if i >= 0 and i + 1 < args.size():
		role = args[i + 1]
	Net.chat_received.connect(func(_f: String, t: String): chat_log.append(t))
	if role == "host":
		run_host()
	elif role.begins_with("trio"):
		run_trio()
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

## The rock wall node in this game's Pixel Town, if it's still standing.
func rock_wall() -> Node:
	for n in main.level.props.get_children():
		if n is NodeScript and n.kind == "rock_wall" and n.alive and not n.is_queued_for_deletion():
			return n
	return null

func run_host() -> void:
	await wait(1.0)
	GS.slot = 2
	GS.delete_slot(2)
	var reg := await Online.register("HostA")
	check(reg.get("ok", false), "the host claims the name HostA online")
	GS.pending_token = reg.get("token", "")
	GS.new_game("man_in_suit", "HostA")
	GS.save_game()
	Net.want_public = true # Host Public Game
	main.start_game(true)
	check(Net.is_host() and Net.room_public, "Host Public Game opens the host's own room as a public game")
	check(await until(func(): return GS.trusted_time, 10.0), "the game takes its time from the online server")
	check(absf(GS.now() - Time.get_unix_time_from_system()) < 3.0, "and that time is right (%.1f s off)" % absf(GS.now() - Time.get_unix_time_from_system()))
	check(await until(func(): return Net.relay != null and Net.relay.status == MultiplayerPeer.CONNECTION_CONNECTED, 15.0), "the room is open on the relay")
	# the connection drops (a phone going to sleep): the game goes on and the
	# room reopens by itself (Brenden, 2026-11-12: "randomly sometimes it
	# kicks me out even in singleplayer")
	Net.relay.ws.close()
	check(await until(func(): return Net.connection_drops == 1, 5.0), "the dropped connection is noticed")
	check(not main.on_title() and main.level.id == "town", "a dropped connection doesn't send you to the title")
	check(await until(func(): return Net.is_host() and Net.relay.status == MultiplayerPeer.CONNECTION_CONNECTED and Net.room_public, 20.0), "the room reopens by itself, still public")
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
	# the friend breaks their rock wall: it opens in the host's town too,
	# but the unlock stays the friend's
	check(rock_wall() != null, "the host's own rock wall stands at first")
	check(await until(func(): return rock_wall() == null, 30.0), "when the friend breaks the rock wall, it opens in the host's town too")
	check(not GS.flags.get("rock_wall", false), "but it's the friend's unlock: the host's own save doesn't get it")
	await wait(0.5)
	await shot("net_host_town")
	main.change_level("grass_1")
	check(main.level.id == "grass_1", "the host went through the portal to Grasslands 1")
	await wait(3.0)
	check(main.level.puppets.is_empty(), "the portal took only the host: the friend wasn't pulled along")
	check(await until(func(): return main.level.puppets.size() == 1, 30.0), "the friend chose to follow through the portal")
	var lvl: Node = main.level
	lvl.player.position = lvl.cell_pos(Vector2i(40, lvl.surface[40] - 1)) # step away so the slime picks the friend
	lvl.player.invuln = 9999.0
	await wait(1.0)
	var pp: Node2D = lvl.puppets.values()[0]
	lvl.drop("wood", 3, pp.position + Vector2(0, -10))
	var slime: Node = lvl.spawn_mob_at("slime", pp.position + Vector2(14, 0))
	slime.aggro_forced = true
	# a monster's drop picked up right next to the friend: the friend gets one too
	await wait(2.0)
	if is_instance_valid(pp):
		lvl.player.position = pp.position + Vector2(6, 0)
		lvl.drop("rock", 2, lvl.player.position + Vector2(0, -8), false, true)
		check(await until(func(): return GS.count("rock") >= 2, 5.0), "the host picked up the shared drop")
		# a boss's loot: everyone on the map gets their own roll that only they see
		var sb0 := GS.count("sticky_balls")
		lvl.boss_loot([["sticky_balls", 1.0, 2, 2]], [], lvl.player.position + Vector2(0, -8))
		var netted_balls := 0
		for e in lvl.entities.get_children():
			if e is PickupScript and e.item == "sticky_balls" and e.nid != 0:
				netted_balls += 1
		check(netted_balls == 0, "the host's boss loot is only the host's (not sent to the room)")
		check(await until(func(): return GS.count("sticky_balls") >= sb0 + 2, 5.0), "the host picked up their own boss loot")
		lvl.player.position = lvl.cell_pos(Vector2i(40, lvl.surface[40] - 1)) # step away again so the slime picks the friend
	# the friend faints: a gravestone stands in their place, and standing by it revives them
	check(await until(func(): return is_instance_valid(pp) and pp.dead, 90.0), "the friend fainted")
	check(pp.stone.visible and not pp.body.visible, "a gravestone stands where the friend fell")
	await shot("net_host_grave")
	await wait(3.0) # the friend's game shows its faint bar first
	lvl.player.position = pp.position + Vector2(8, 0)
	check(await until(func(): return pp.revives > 0, 2.0), "touching the gravestone revives them right away")
	check(await until(func(): return not pp.dead, 5.0), "and the friend is back up")
	# far away from the friend: a marker at the edge of the screen points at them
	lvl.player.position = lvl.cell_pos(Vector2i(mini(lvl.W - 6, int(pp.position.x / 16) + 40), lvl.surface[mini(lvl.W - 6, int(pp.position.x / 16) + 40)] - 1))
	main.camera.position = lvl.player.position
	main.camera.reset_smoothing()
	await wait(0.6)
	var marks: Array = main.hud.marker_points()
	check(marks.size() == 1 and marks[0][0] == pp.peer and (marks[0][2] as Vector2).x < 0, "a marker at the screen's edge points left at the friend off screen (%s)" % [marks])
	await shot("net_host_marker")
	lvl.player.position = lvl.cell_pos(Vector2i(40, lvl.surface[40] - 1))
	check(await until(func(): return chat_log.has("hello from friend"), 90.0), "the friend's chat message arrived")
	await wait(0.2)
	var feed: VBoxContainer = main.hud.chat_feed
	check(feed.visible and (feed.get_child(0) as Label).text.contains("hello from friend") and feed.position.y >= main.hud.chat_btn.position.y + main.hud.chat_btn.size.y - 1,
		"the message shows on the side, right under the Chat.. box")
	check(main.hud.goal_btn.position.y >= feed.position.y + main.hud.chat_feed_height() - 1, "the goal moved down under the chat lines")
	for t in ["anyone got coal?", "yes, by the rocks", "need a fire crystal for a torch", "Firas drop them in Grasslands"]:
		main.hud.add_chat("Pal", t)
	await wait(0.3)
	var shown := []
	for fl in feed.get_children():
		if fl.visible:
			shown.append((fl as Label).text)
	check(shown.size() == 4 and not "|".join(shown).contains("hello from friend") and shown[3].ends_with("Firas drop them in Grasslands"), "only the last 4 messages show, newest at the bottom (%s)" % [shown])
	await shot("net_host_chat_feed")
	var em: Node = pp.get_node_or_null("Emote") if is_instance_valid(pp) else null
	check(em != null and em.texture == Art.emote("heart"), "the friend's heart emote shows over their head")
	var placed := 0
	for n in lvl.props.get_children():
		if n is PlacedScript:
			placed += 1
	check(placed == 1, "the friend's wall was built in the host's world")
	check(await until(func(): return main.level.id == "grass_2", 35.0), "the friend went through to Grasslands 2 and the host was taken along after the countdown")
	await wait(1.0)
	await shot("net_host_grass2")
	# trading at the Trading Center
	check(await until(func(): return main.level.id == "town", 35.0), "the friend went home and the host followed after the countdown")
	await wait(0.5)
	check(rock_wall() == null, "back in town, the rebuilt town keeps the wall the friend opened")
	GS.add_item("wood", 5)
	var coins0 := GS.coins
	var rock0 := GS.count("rock")
	check(await until(func(): return chat_log.has("ready to trade"), 90.0), "the friend burned the wall and is at the Trading Center")
	var host_wall: Node = null
	for n in main.level.props.get_children():
		if n is NodeScript and n.kind == "trade_wall" and n.alive and not n.is_queued_for_deletion():
			host_wall = n
	check(host_wall == null and not GS.flags.get("trade_wall", false), "the wall the friend burned is gone from the host's town too, and stays the friend's unlock")
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
	check(GS.count("rock") >= rock0 + 3 and GS.coins == coins0 + 50 and GS.count("wood") == 0, "the host got 3 Rocks and 50 coins for 5 Wood")
	check(await until(func(): return Net.players.is_empty(), 30.0), "the friend left the room")
	main.change_level("grass_1")
	await wait(1.0)
	main.change_level("town")
	await wait(1.0)
	check(rock_wall() != null, "after the friend leaves, the host's town has its own rock wall again")
	# the friend comes back; both go to Grasslands 1, and the host leaves:
	# the game goes on for the friend, who is the host now
	check(await until(func(): return Net.players.size() == 1, 60.0), "the friend joined again")
	await wait(1.0)
	main.change_level("grass_1")
	check(await until(func(): return main.level.id == "grass_1" and main.level.puppets.size() == 1, 30.0), "the friend followed into Grasslands 1")
	await wait(1.5)
	main.quit_to_title()
	check(not Net.active, "the host left the room")
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
	# not friends yet, but HostA's game is public: anyone can join it
	# (a private room turning strangers away is checked in server/test_server.py)
	main.join_game("HostA")
	check(await until(func(): return Net.active and not main.on_title() and main.level.id == "town", 30.0), "a player who isn't a friend can join a public game")
	main.quit_to_title()
	check(await until(func(): return not Net.active, 10.0), "and leave it again")
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
	var pubs := await Online.public_rooms()
	var listed := false
	for r in pubs.get("rooms", []):
		listed = listed or r.name == "HostA"
	check(listed, "Find Public Game lists HostA's public game")
	main.hud.menu_step = "public"
	main.hud.open_panel("title")
	main.hud._refresh_title()
	await wait(1.5)
	await shot("net_client_public")
	check(not fr_text.contains("127.0.0.1") and not fr_text.contains("ip"), "the friends list never shows an IP address")
	main.hud.menu_step = "mode"
	main.hud.open_friends()
	await wait(1.5)
	await shot("net_client_friends")
	main.hud._join_friend("HostA")
	check(await until(func(): return not main.on_title() and main.level.id == "town", 60.0), "joined the room in Pixel Town")
	check(await until(func(): return main.level.puppets.size() == 1, 10.0), "the friend sees the host")
	var rw: Node = rock_wall()
	for k in 40:
		if rw == null or not is_instance_valid(rw) or not rw.alive:
			break
		rw.hit(5)
		await wait(0.1)
	check(GS.flags.get("rock_wall", false) and rock_wall() == null, "the friend broke their rock wall")
	check(await until(func(): return Net.last_went == "grass_1", 30.0), "the friend is told the host went through the portal")
	await wait(3.0)
	var street_portal := false
	for n in main.level.props.get_children():
		if n is PortalScript and n.target == "grass_1":
			street_portal = true
	check(main.level.id == "town" and street_portal, "the friend can stay in town; the same portal opened on their street")
	await shot("net_client_portal_street")
	main.change_level("grass_1")
	check(await until(func(): return main.level.id == "grass_1" and main.level.netted, 15.0), "the friend went through and is on the host's Grasslands 1")
	var lvl: Node = main.level
	await wait(1.0)
	var nodes := 0
	for n in lvl.props.get_children():
		if n is NodeScript:
			nodes += 1
	check(lvl.count_mobs() > 10 and nodes > 50, "the host's monsters (%d) and resources (%d) are here" % [lvl.count_mobs(), nodes])
	check(await until(func(): return GS.count("wood") >= 3, 20.0), "picked up the wood the host dropped")
	check(await until(func(): return GS.count("rock") >= 2, 25.0), "got the same drop the host picked up right next to the friend")
	check(await until(func(): return GS.count("sticky_balls") >= 2, 25.0), "got a boss loot roll of their own (%d Sticky Balls)" % GS.count("sticky_balls"))
	var hp0: float = GS.hp
	check(await until(func(): return GS.hp < hp0, 20.0), "the host's slime hurt the friend")
	# faint: a small bar at the top, a darker screen, and a friend can revive you
	lvl.player.invuln = 0.0
	lvl.player.hurt(9999, 0.0, lvl.player.position.x - 5)
	check(await until(func(): return main.hud.dead_bar.visible, 5.0), "fainting in a room shows the small bar")
	check(main.dead_tint.visible and (main.hud.dead_bar.get_node("Text") as Label).text.contains("friend can revive"), "the screen darkens and the bar says a friend can revive you (%s)" % (main.hud.dead_bar.get_node("Text") as Label).text)
	await shot("net_client_fainted")
	check(await until(func(): return not lvl.player.dead, 40.0), "the host stood by the gravestone and revived the friend")
	check(not main.hud.dead_bar.visible and not main.dead_tint.visible and lvl.id == "grass_1", "back up where they fell, still in Grasslands 1")
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
	main.hud.use_emote("heart")
	main.hud.open_chat()
	main.hud.chat_edit.text = "hello from friend"
	await shot("net_client_chat")
	main.hud._send_chat()
	await wait(1.0)
	main.change_level("grass_2")
	check(await until(func(): return main.level.id == "grass_2", 10.0) and not main.level.netted, "the portal took the friend first, onto their own copy of Grasslands 2")
	main.change_level("grass_3")
	await wait(1.5)
	check(Net.last_notice.contains("current portal") and main.level.id == "grass_2", "another portal says someone's in the current portal (%s)" % Net.last_notice)
	await shot("net_client_portal_busy")
	check(await until(func(): return main.level.id == "grass_2" and main.level.netted, 35.0), "the host came through after the countdown and the map is shared again")
	await wait(1.0)
	await shot("net_client_grass2")
	# back to town, burn the wall with a torch, and go to the Trading Center
	main.change_level("town")
	check(await until(func(): return main.level.id == "town", 10.0), "the friend went home on their own")
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
	p.position = lvl.cell_pos(Vector2i(9, lvl.TOWN_TOP - 1)) # inside the Trading Center
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
	# the host checks their own town walls once you've gone, then you come back
	await wait(8.0)
	main.join_game("HostA")
	check(await until(func(): return Net.active and not main.on_title() and Net.players.size() == 1, 30.0), "joined HostA's room again")
	check(await until(func(): return Net.last_went == "grass_1", 30.0), "HostA went into Grasslands 1")
	main.change_level("grass_1")
	check(await until(func(): return main.level.id == "grass_1" and main.level.netted and main.level.puppets.size() == 1, 20.0), "followed HostA into the shared Grasslands 1")
	# HostA leaves: the room passes to the friend and the game goes on
	var pos: Vector2 = main.level.player.position
	check(await until(func(): return Net.host_changes == 1, 30.0), "when HostA left, the room passed on instead of closing")
	check(not main.on_title() and main.level.id == "grass_1", "the friend is still in Grasslands 1, not sent to the title screen")
	check(Net.active and Net.is_host(), "the friend is the room's host now")
	check(main.level.netted and main.level.player.position.distance_to(pos) < 64, "the same map goes on, with the friend where they stood")
	var puppets := 0
	for e in main.level.entities.get_children():
		if e is MobScript and e.puppet:
			puppets += 1
	check(main.level.count_mobs() > 5 and puppets == 0, "the monsters (%d) carry on, now run by the friend's game" % main.level.count_mobs())
	check(await until(func(): return Net.relay != null and Net.relay.status == MultiplayerPeer.CONNECTION_CONNECTED, 15.0), "the friend's room is open on the relay")
	check(main.level.puppets.is_empty() and Net.players.is_empty(), "HostA is gone from the map")
	await wait(1.0)
	await shot("net_client_new_host")
	main.quit_to_title()
	await wait(1.0)
	finish()

## Three players (`--nettest trio0`, `trio1`, `trio2`, started in that order a
## few seconds apart): Trio0 hosts, both others follow into Grasslands 1, and
## Trio0 leaves. Trio1 (who joined first) becomes the host, and Trio2 gets
## back into Trio1's room without leaving the map.
func run_trio() -> void:
	var n := int(role.substr(4))
	await wait(1.0 + n * 4.0)
	GS.slot = 3 + n
	GS.delete_slot(GS.slot)
	var reg := await Online.register("Trio%d" % n)
	check(reg.get("ok", false), "claimed the name Trio%d" % n)
	GS.pending_token = reg.get("token", "")
	GS.new_game(["man_in_suit", "nurse", "ninja"][n], "Trio%d" % n)
	GS.save_game()
	if n == 0:
		Net.want_public = true
		main.start_game(true)
		check(await until(func(): return Net.players.size() == 2, 60.0), "both friends joined")
		main.change_level("grass_1")
		check(await until(func(): return main.level.puppets.size() == 2, 40.0), "both followed into Grasslands 1")
		await wait(2.0)
		main.quit_to_title()
		finish()
		return
	main.join_game("Trio0")
	check(await until(func(): return Net.active and not main.on_title(), 30.0), "joined Trio0's room")
	check(await until(func(): return Net.last_went == "grass_1", 40.0), "Trio0 went into Grasslands 1")
	main.change_level("grass_1")
	check(await until(func(): return main.level.id == "grass_1" and main.level.netted and main.level.puppets.size() == 2, 30.0), "followed into the shared Grasslands 1")
	check(await until(func(): return Net.host_changes == 1, 40.0), "Trio0 left and the room passed on")
	if n == 1:
		check(Net.is_host() and not main.on_title() and main.level.id == "grass_1", "Trio1, who joined first, is the host now and still in Grasslands 1")
		check(await until(func(): return Net.players.size() == 1 and main.level.puppets.size() == 1, 30.0), "Trio2 is back in the room and on the map")
		await wait(6.0)
	else:
		check(not main.on_title() and main.level.id == "grass_1", "Trio2 stays in Grasslands 1 while the room passes on")
		check(await until(func(): return Net.is_client() and Net.players.size() == 1 and Net.rejoin_to == "", 30.0), "and gets back into Trio1's room")
		check(await until(func(): return main.level.id == "grass_1" and main.level.netted and main.level.puppets.size() == 1, 15.0), "sharing Trio1's Grasslands 1")
		await wait(1.0)
		await shot("net_trio_rejoined")
	finish()
