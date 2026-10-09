extends MultiplayerPeerExtension
## A multiplayer connection that goes through the online server's room relay
## instead of straight to the other player. Nobody connects to anybody else's
## computer, so players never see each other's IP address.
##
## The host's game is peer 1. Guests pick a random id, and the relay passes
## their messages to the host, who passes things on to everyone else.
## Frames: [u32 length][u8 type][payload], little-endian (see server/pixel_server.py).

const HELLO := 1
const DATA := 2
const KICK := 3
const WELCOME := 0x81
const ERROR := 0x82
const PEER_JOIN := 0x83
const PEER_LEAVE := 0x84
const IN_DATA := 0x85
const ROOM_CLOSED := 0x86

var tcp := StreamPeerTCP.new()
var status: int = MultiplayerPeer.CONNECTION_DISCONNECTED
var host := false
var my_id := 0
var last_error := ""
var _hello := {}
var _sent_hello := false
var _target := 0
var _mode: int = MultiplayerPeer.TRANSFER_MODE_RELIABLE
var _channel := 0
var _buf := PackedByteArray()
var _incoming: Array = [] # [from, channel, mode, bytes]
var _refusing := false

## Opens your room (as_host) or joins the room of the friend named `room`.
func start(address: String, port: int, token: String, as_host: bool, room: String = "") -> int:
	host = as_host
	my_id = 1 if as_host else randi_range(2, 2147483647)
	_hello = {"token": token, "mode": "host" if as_host else "join", "room": room, "id": my_id}
	var err := tcp.connect_to_host(address, port)
	if err != OK:
		last_error = "Can't reach the online server."
		return err
	tcp.set_no_delay(true)
	status = MultiplayerPeer.CONNECTION_CONNECTING
	return OK

func _send_frame(typ: int, payload: PackedByteArray) -> void:
	var head := PackedByteArray()
	head.resize(5)
	head.encode_u32(0, payload.size() + 1)
	head.encode_u8(4, typ)
	tcp.put_data(head + payload)

func _poll() -> void:
	if status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return
	tcp.poll()
	var st := tcp.get_status()
	if st == StreamPeerTCP.STATUS_ERROR or (st == StreamPeerTCP.STATUS_NONE and _sent_hello):
		if last_error == "":
			last_error = "Lost the connection to the online server."
		_drop()
		return
	if st != StreamPeerTCP.STATUS_CONNECTED:
		return
	if not _sent_hello:
		_sent_hello = true
		_send_frame(HELLO, JSON.stringify(_hello).to_utf8_buffer())
	var avail := tcp.get_available_bytes()
	if avail > 0:
		var got: Array = tcp.get_partial_data(avail)
		if got[0] == OK:
			_buf.append_array(got[1])
	while _buf.size() >= 5:
		var length := _buf.decode_u32(0)
		if _buf.size() < 4 + length:
			break
		var typ := _buf.decode_u8(4)
		var payload := _buf.slice(5, 4 + length)
		_buf = _buf.slice(4 + length)
		_handle(typ, payload)
		if status == MultiplayerPeer.CONNECTION_DISCONNECTED:
			return

func _handle(typ: int, payload: PackedByteArray) -> void:
	match typ:
		WELCOME:
			status = MultiplayerPeer.CONNECTION_CONNECTED
			if not host:
				emit_signal("peer_connected", 1)
		ERROR:
			var d = JSON.parse_string(payload.get_string_from_utf8())
			last_error = d.get("error", "The online server said no.") if typeof(d) == TYPE_DICTIONARY else "The online server said no."
			_drop()
		PEER_JOIN:
			emit_signal("peer_connected", payload.decode_s32(0))
		PEER_LEAVE:
			var gone := payload.decode_s32(0)
			# drop anything still queued from them, or the game would read it after they left
			_incoming = _incoming.filter(func(e): return e[0] != gone)
			emit_signal("peer_disconnected", gone)
		IN_DATA:
			if payload.size() >= 6:
				_incoming.append([payload.decode_s32(0), payload.decode_u8(4), payload.decode_u8(5), payload.slice(6)])
		ROOM_CLOSED:
			last_error = "The room was closed."
			_drop()

func _drop() -> void:
	var was := status
	status = MultiplayerPeer.CONNECTION_DISCONNECTED
	tcp.disconnect_from_host()
	if was == MultiplayerPeer.CONNECTION_CONNECTED and not host:
		emit_signal("peer_disconnected", 1)

func _get_available_packet_count() -> int:
	return _incoming.size()

func _get_packet_peer() -> int:
	return _incoming[0][0] if _incoming.size() > 0 else 0

func _get_packet_channel() -> int:
	return _incoming[0][1] if _incoming.size() > 0 else 0

func _get_packet_mode() -> MultiplayerPeer.TransferMode:
	return _incoming[0][2] if _incoming.size() > 0 else MultiplayerPeer.TRANSFER_MODE_RELIABLE

func _get_packet_script() -> PackedByteArray:
	if _incoming.is_empty():
		return PackedByteArray()
	return _incoming.pop_front()[3]

func _put_packet_script(p_buffer: PackedByteArray) -> Error:
	if status != MultiplayerPeer.CONNECTION_CONNECTED:
		return ERR_UNCONFIGURED
	var head := PackedByteArray()
	head.resize(6)
	head.encode_s32(0, _target if host else 1)
	head.encode_u8(4, _channel)
	head.encode_u8(5, _mode)
	_send_frame(DATA, head + p_buffer)
	return OK

func _get_max_packet_size() -> int:
	return 1 << 22

func _set_target_peer(p_peer: int) -> void:
	_target = p_peer

func _set_transfer_channel(p_channel: int) -> void:
	_channel = p_channel

func _get_transfer_channel() -> int:
	return _channel

func _set_transfer_mode(p_mode: MultiplayerPeer.TransferMode) -> void:
	_mode = p_mode

func _get_transfer_mode() -> MultiplayerPeer.TransferMode:
	return _mode

func _get_unique_id() -> int:
	return my_id

func _is_server() -> bool:
	return host

func _is_server_relay_supported() -> bool:
	return true

func _get_connection_status() -> MultiplayerPeer.ConnectionStatus:
	return status

func _close() -> void:
	if status != MultiplayerPeer.CONNECTION_DISCONNECTED:
		tcp.disconnect_from_host()
	status = MultiplayerPeer.CONNECTION_DISCONNECTED

func _disconnect_peer(p_peer: int, _p_force: bool) -> void:
	if host:
		var b := PackedByteArray()
		b.resize(4)
		b.encode_s32(0, p_peer)
		_send_frame(KICK, b)
		emit_signal("peer_disconnected", p_peer)

func _set_refuse_new_connections(p_enable: bool) -> void:
	_refusing = p_enable

func _is_refusing_new_connections() -> bool:
	return _refusing
