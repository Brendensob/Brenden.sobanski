extends Node
## Talks to the Pixel Wilds online server (server/pixel_server.py): reserves
## player names so each one can only be taken once, keeps friends lists, and
## tells friends when you're online and hosting a room.
##
## Set ONLINE_SERVER to wherever you run the server before sharing the game.
## It can also be changed with `-- --server http://address:24566`.

const ONLINE_SERVER := "http://127.0.0.1:24566"
const NAME_RULE := "^[A-Za-z0-9_]{3,16}$"

var server := ONLINE_SERVER
var _presence_t := 0.0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--server")
	if i >= 0 and i + 1 < args.size():
		server = args[i + 1]

func valid_name(n: String) -> bool:
	var re := RegEx.new()
	re.compile(NAME_RULE)
	return re.search(n) != null

## Sends one request and waits for the answer. Never throws: on trouble it
## returns {"ok": false, "offline": true, "error": ...}.
func call_api(path: String, body: Dictionary) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = 6.0
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
		call_api("/presence", {"token": GS.online_token, "room": Net.is_host(), "addrs": Net.local_addresses()})

func ping_now() -> void:
	_presence_t = 0.0
