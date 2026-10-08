extends Node
## Multiplayer rooms, like the original's: one player creates a room and up to
## three friends join. Everyone keeps their own character, bag, quests,
## furnaces and chests; the room host's game runs the shared world (the map
## everyone is on, its monsters, resources, drops, walls and the time of day).
##
## Uses Godot's ENet networking. On the same Wi-Fi, friends join with the
## host's local address. Over the internet the host forwards UDP port 24565,
## or everyone joins the same free VPN (Tailscale, ZeroTier, Radmin VPN).
## A Steam build can swap in Steam's networking peer without changing the rest.

signal players_changed
signal chat_received(from: String, text: String)

const PORT := 24565
const MAX_PLAYERS := 4
const SEND_RATE := 1.0 / 15.0

var active := false
var players := {} # peer id -> {"name", "look", "state"}
var main: Node
var _send_t := 0.0
var _tick_t := 0.0
var _pending_take := {} # nid -> true, pickups we asked the host for

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)

# ---------------------------------------------------------------- roles
func is_host() -> bool:
	return active and multiplayer.is_server()

func is_client() -> bool:
	return active and not multiplayer.is_server()

## True when this game decides what happens in the world (single player or host).
func authority() -> bool:
	return not active or multiplayer.is_server()

func my_id() -> int:
	return multiplayer.get_unique_id() if active else 1

## The host's addresses to share with friends.
func local_addresses() -> Array:
	var out := []
	for a in IP.get_local_addresses():
		if a.count(".") == 3 and not a.begins_with("127.") and not a.begins_with("169.254."):
			out.append(a)
	return out

# ---------------------------------------------------------------- rooms
func host_room() -> String:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS - 1)
	if err != OK:
		return "Couldn't open a room on port %d." % PORT
	multiplayer.multiplayer_peer = peer
	active = true
	players.clear()
	players_changed.emit()
	return ""

func join_room(address: String) -> String:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address.strip_edges(), PORT)
	if err != OK:
		return "Couldn't reach %s." % address
	multiplayer.multiplayer_peer = peer
	active = true
	players.clear()
	return ""

func leave() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	active = false
	players.clear()
	_pending_take.clear()
	players_changed.emit()

func player_count() -> int:
	return players.size() + (1 if active else 0)

func _on_peer_connected(id: int) -> void:
	if is_host() and player_count() > MAX_PLAYERS:
		multiplayer.multiplayer_peer.disconnect_peer(id)

func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		var nm: String = players[id].name
		players.erase(id)
		players_changed.emit()
		if main:
			main.hud.toast("%s left the room." % nm, "warn")
			if main.level:
				main.level.remove_puppet(id)

func _on_connected() -> void:
	hello.rpc_id(1, GS.player_name, GS.look)

func _on_failed() -> void:
	active = false
	if main:
		main.net_join_failed("Couldn't connect to that room.")

func _on_server_gone() -> void:
	leave()
	if main:
		main.net_host_left()

## A friend says hi: remember them, tell everyone, and send them the world.
@rpc("any_peer", "reliable")
func hello(pname: String, look: String) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	players[id] = {"name": pname, "look": look, "state": {}}
	players_changed.emit()
	main.hud.toast("%s joined the room." % pname, "good")
	var roster := {1: {"name": GS.player_name, "look": GS.look}}
	for pid in players:
		roster[pid] = {"name": players[pid].name, "look": players[pid].look}
	roster_update.rpc(roster)
	send_world(id)

@rpc("authority", "reliable")
func roster_update(roster: Dictionary) -> void:
	for pid in roster:
		var p := int(pid)
		if p == my_id():
			continue
		if not players.has(p):
			players[p] = {"name": roster[pid].name, "look": roster[pid].look, "state": {}}
	for p in players.keys():
		if not roster.has(p) and not roster.has(str(p)):
			players.erase(p)
	players_changed.emit()

# ---------------------------------------------------------------- the world
## Sends the whole current map to one peer (0 = everyone).
func send_world(to: int = 0) -> void:
	if not is_host() or main == null or main.level == null:
		return
	var lvl: Node = main.level
	var state: Dictionary = lvl.net_state()
	if to == 0:
		load_world.rpc(lvl.id, lvl.seed_used, state)
	else:
		load_world.rpc_id(to, lvl.id, lvl.seed_used, state)

@rpc("authority", "reliable")
func load_world(world_id: String, seed: int, state: Dictionary) -> void:
	_pending_take.clear()
	main.net_load_world(world_id, seed, state)

## A friend asks to go somewhere (portal or Gatekeeper): the whole room goes.
@rpc("any_peer", "reliable")
func request_level(target: String) -> void:
	if is_host() and Data.WORLDS.has(target):
		main.change_level(target)

func _process(delta: float) -> void:
	if not active or main == null or main.level == null or main.on_title():
		return
	_send_t += delta
	if _send_t >= SEND_RATE:
		_send_t = 0.0
		var p: Node = main.level.player
		if p:
			player_state.rpc(p.net_state())
		if is_host():
			var snap: Array = main.level.mob_snapshot()
			if not snap.is_empty():
				mob_states.rpc(snap)
	if is_host():
		_tick_t += delta
		if _tick_t >= 1.0:
			_tick_t = 0.0
			world_tick.rpc(main.level.id, GS.clock, GS.day, main.level.tick_state())

@rpc("any_peer", "unreliable_ordered")
func player_state(st: Dictionary) -> void:
	var id := multiplayer.get_remote_sender_id()
	if not players.has(id):
		return
	players[id].state = st
	if main and main.level:
		main.level.update_puppet(id, players[id].name, st)

@rpc("authority", "unreliable_ordered")
func mob_states(snap: Array) -> void:
	if main and main.level:
		main.level.apply_mob_snapshot(snap)

@rpc("authority", "unreliable_ordered")
func world_tick(world_id: String, clock: float, day: int, ts: Dictionary) -> void:
	if main == null or main.level == null or main.level.id != world_id:
		return
	GS.clock = clock
	GS.day = day
	main.level.apply_tick_state(ts)

# ---------------------------------------------------------------- events from the host
func _lvl() -> Node:
	return main.level if main else null

@rpc("authority", "reliable")
func mob_spawned(world_id: String, data: Array) -> void:
	if _lvl() and _lvl().id == world_id:
		_lvl().add_mob_from(data)

@rpc("authority", "reliable")
func mob_died(world_id: String, nid: int) -> void:
	if _lvl() and _lvl().id == world_id:
		_lvl().net_mob_died(nid)

@rpc("authority", "reliable")
func node_spawned(world_id: String, data: Array) -> void:
	if _lvl() and _lvl().id == world_id:
		_lvl().add_node_from(data)

@rpc("authority", "reliable")
func node_changed(world_id: String, nid: int, hits: int, alive: bool) -> void:
	if _lvl() and _lvl().id == world_id:
		_lvl().net_node_changed(nid, hits, alive)

@rpc("authority", "reliable")
func pickup_spawned(world_id: String, data: Array) -> void:
	if _lvl() and _lvl().id == world_id:
		_lvl().add_pickup_from(data)

@rpc("authority", "reliable")
func pickup_gone(world_id: String, nid: int) -> void:
	if _lvl() and _lvl().id == world_id:
		_lvl().net_remove(nid)

@rpc("authority", "reliable")
func placed_spawned(world_id: String, data: Array) -> void:
	if _lvl() and _lvl().id == world_id:
		_lvl().add_placed_from(data)

@rpc("authority", "reliable")
func placed_gone(world_id: String, nid: int) -> void:
	if _lvl() and _lvl().id == world_id:
		_lvl().net_remove(nid, true)

## Everyone in the room gets the same messages (boss arrived, night falls...).
@rpc("authority", "reliable")
func announce(text: String, kind: String) -> void:
	if main:
		main.hud.toast(text, kind)

## Survival Grasslands: everyone who lived through the night gets the tokens.
@rpc("authority", "reliable")
func night_survived(tokens: int) -> void:
	if tokens > 0:
		GS.add_item("survival_token", tokens)

## A monster on the host's screen hit you.
@rpc("authority", "reliable")
func hurt_me(dmg: int, crit: float, from_x: float, status: Array) -> void:
	if main and main.level and main.level.player:
		main.level.player.hurt(dmg, crit, from_x, status)

## The host handed you a pickup you asked for.
@rpc("authority", "reliable")
func grant(nid: int, item: String, n: int) -> void:
	_pending_take.erase(nid)
	var left := GS.add_item(item, n, true)
	if item == "coin":
		main.level.number(main.level.player.position + Vector2(0, -24), "+%d coins" % n, Color("f2cf5b"))
	elif left < n:
		main.hud.toast("%s obtained%s" % [Data.ITEMS[item].name, " x%d" % (n - left) if n - left > 1 else ""])

# ---------------------------------------------------------------- requests to the host
@rpc("any_peer", "reliable")
func hit_mob(world_id: String, nid: int, amount: int, from_x: float, knock: bool) -> void:
	if is_host() and _lvl() and _lvl().id == world_id:
		var m: Node = _lvl().net_objs.get(nid)
		if m and is_instance_valid(m) and m.has_method("take_damage"):
			m.take_damage(amount, from_x, knock, true)

@rpc("any_peer", "reliable")
func hit_node(world_id: String, nid: int, tier: int) -> void:
	if is_host() and _lvl() and _lvl().id == world_id:
		var n: Node = _lvl().net_objs.get(nid)
		if n and is_instance_valid(n) and n.alive:
			n.hit(tier, true)

@rpc("any_peer", "reliable")
func take_pickup(world_id: String, nid: int) -> void:
	if not is_host() or _lvl() == null or _lvl().id != world_id:
		return
	var p: Node = _lvl().net_objs.get(nid)
	if p == null or not is_instance_valid(p) or p.taken:
		return
	p.taken = true
	grant.rpc_id(multiplayer.get_remote_sender_id(), nid, p.item, p.n)
	_lvl().net_remove(nid)
	pickup_gone.rpc(world_id, nid)

func ask_pickup(nid: int) -> void:
	if _pending_take.has(nid):
		return
	_pending_take[nid] = true
	take_pickup.rpc_id(1, _lvl().id, nid)

@rpc("any_peer", "reliable")
func request_place(world_id: String, item: String, x: float, y: float) -> void:
	if is_host() and _lvl() and _lvl().id == world_id:
		_lvl().place_at(item, Vector2(x, y))

## Arrows, magic and thrown snowballs: other players just see them fly.
@rpc("any_peer", "unreliable")
func projectile_fx(world_id: String, x: float, y: float, vx: float, vy: float, gravity: float, color: Color, radius: float, hostile: bool, dmg: int) -> void:
	if _lvl() and _lvl().id == world_id:
		_lvl().net_projectile(Vector2(x, y), Vector2(vx, vy), gravity, color, radius, hostile, dmg)

# ---------------------------------------------------------------- chat
func say(text: String) -> void:
	text = text.strip_edges().left(80)
	if text == "" or not active:
		return
	chat.rpc(GS.player_name, text)
	chat_received.emit(GS.player_name, text)

@rpc("any_peer", "reliable")
func chat(from: String, text: String) -> void:
	chat_received.emit(from, text.left(80))
