extends Node
## Talks to the Pixel Wilds online server (server/pixel_server.py): reserves
## player names so each one can only be taken once, keeps friends lists, and
## tells friends when you're online. Rooms go through the same server's
## WebSocket relay (/relay), so no player ever sees another player's IP address,
## and phones in a browser can join just like computers.
##
## ONLINE_SERVER is the shared server everyone uses (hosted on Render, see
## 03 Tech/Online Server.md in the vault). To use another one, put its address
## in godot/server.txt, in a server.txt next to the game (like 192.168.1.20),
## add ?server=https://address to the web game's link, or run the game with
## `-- --server http://address:24566`.

const ONLINE_SERVER := "https://pixel-wilds-brendensob.onrender.com"
const NAME_RULE := "^[A-Za-z0-9_]{3,16}$"

var server := ONLINE_SERVER
var _presence_t := 0.0

func _ready() -> void:
	# a server.txt in the game, next to it, or in its save folder holds the server's address
	for path in ["res://server.txt", OS.get_executable_path().get_base_dir().path_join("server.txt"), "user://server.txt"]:
		if FileAccess.file_exists(path):
			var t := FileAccess.get_file_as_string(path).strip_edges()
			if t != "":
				server = t if t.begins_with("http") else "http://%s:24566" % t
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('server') || ''")
		if typeof(q) == TYPE_STRING and q.begins_with("http"):
			server = q
	server = server.trim_suffix("/")
	var args := OS.get_cmdline_user_args()
	var i := args.find("--server")
	if i >= 0 and i + 1 < args.size():
		server = args[i + 1]
	elif args.has("--autotest") or args.has("--nettest"):
		server = "http://127.0.0.1:24566" # the checks use a server started on this computer
	fetch_time()

## Asks the server for the real time, so changing the device clock can't
## speed up furnaces or reset daily chests. Offline, the game keeps its own count.
## This is also the game's first call, so it waits long enough for a free
## server that was asleep to wake up (about a minute).
func fetch_time() -> bool:
	var t0 := Time.get_ticks_msec()
	var r := await call_api("/time", {}, 75.0)
	if not r.get("ok", false) or not r.has("time"):
		return false
	if Time.get_ticks_msec() - t0 > 4000:
		return await fetch_time() # it was asleep: ask again for a time that isn't late
	# half the round trip went by since the server read its clock
	GS.set_trusted_time(float(r.time) + (Time.get_ticks_msec() - t0) / 2000.0)
	return true

func valid_name(n: String) -> bool:
	var re := RegEx.new()
	re.compile(NAME_RULE)
	return re.search(n) != null

## Sends one request and waits for the answer. Never throws: on trouble it
## returns {"ok": false, "offline": true, "error": ...}. If the server has
## forgotten this character (a free host can wipe it when it restarts), the
## game puts its name and friends back and asks again.
func call_api(path: String, body: Dictionary, wait := 10.0) -> Dictionary:
	var r := await _request(path, body, wait)
	if r.get("unknown", false) and GS.online_token != "" and body.get("token", "") == GS.online_token:
		if await restore():
			r = await _request(path, body, wait)
	if path == "/friends" and r.get("ok", false):
		var names: Array = []
		for f in r.get("friends", []):
			names.append(str(f.name))
		if names != GS.friend_names:
			GS.friend_names = names
			GS.save_game()
	return r

## Puts this character's name, key and friends back on a wiped server.
func restore() -> bool:
	var r := await _request("/restore", {"name": GS.player_name, "token": GS.online_token, "friends": GS.friend_names}, 10.0)
	return r.get("ok", false)

func _request(path: String, body: Dictionary, wait: float) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = wait
	add_child(req)
	var err := req.request(server + path, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		req.queue_free()
		return {"ok": false, "offline": true, "error": "Can't reach the online server."}
	var res: Array = await req.request_completed
	req.queue_free()
	if res[0] != HTTPRequest.RESULT_SUCCESS or res[1] != 200:
		return {"ok": false, "offline": true, "error": "Can't reach the online server."}
	var d = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	if typeof(d) != TYPE_DICTIONARY:
		return {"ok": false, "offline": true, "error": "The online server sent something odd."}
	return d

## Claims a name. On success the answer has the key ("token") that proves it's yours.
func register(pname: String) -> Dictionary:
	if not valid_name(pname):
		return {"ok": false, "error": "Names are 3 to 16 letters, numbers or _."}
	return await call_api("/register", {"name": pname})

## Frees a deleted character's name so someone else can use it.
func release(token: String) -> void:
	if token != "":
		await call_api("/release", {"token": token})

## Rooms anyone can join ("Find Public Game"): [{name, players, full}].
func public_rooms() -> Dictionary:
	return await call_api("/rooms", {"token": GS.online_token})

func friends() -> Dictionary:
	return await call_api("/friends", {"token": GS.online_token})

func add_friend(pname: String) -> Dictionary:
	return await call_api("/friends/add", {"token": GS.online_token, "name": pname})

func answer(pname: String, accept: bool) -> Dictionary:
	return await call_api("/friends/answer", {"token": GS.online_token, "name": pname, "accept": accept})

func remove_friend(pname: String) -> Dictionary:
	return await call_api("/friends/remove", {"token": GS.online_token, "name": pname})

## Every 30 seconds while playing: "I'm online", and whether you're hosting a room.
func _process(delta: float) -> void:
	if GS.online_token == "" or Net.main == null or Net.main.on_title():
		return
	_presence_t -= delta
	if _presence_t <= 0:
		_presence_t = 30.0
		call_api("/presence", {"token": GS.online_token})

func ping_now() -> void:
	_presence_t = 0.0

## Where the room relay is: the same server and port, as a WebSocket.
func relay_url() -> String:
	if server.begins_with("https://"):
		return "wss://" + server.trim_prefix("https://") + "/relay"
	return "ws://" + server.trim_prefix("http://") + "/relay"
