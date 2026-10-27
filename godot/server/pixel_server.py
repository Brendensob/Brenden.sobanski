#!/usr/bin/env python3
"""Pixel Wilds online server: player names (each name can only be taken once),
friends lists, who's online, and the room relay.

Every player's game hosts a room. Friends join it through this server's relay,
which passes the game traffic along, so players never connect to each other
directly and never learn each other's IP address. Only friends can join.

Run it on any computer or cheap server that everyone can reach:

    python3 pixel_server.py --port 24566 --data names.json

Port 24566 answers names and friends, and also carries the room relay as a
WebSocket at /relay. That's the path phones and browsers use, and the only one
a web host like Render gives you (it sets $PORT and adds https for you).
The desktop game's older raw relay is still on the next port up (24567).
Then set ONLINE_SERVER in scripts/online.gd (or godot/server.txt) to the
server's address. Only the Python standard library is needed. Data is saved
to a JSON file.
"""
import argparse
import base64
import hashlib
import json
import os
import re
import secrets
import socket
import socketserver
import struct
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

NAME_RE = re.compile(r"^[A-Za-z0-9_]{3,16}$")
ONLINE_SECONDS = 75  # how long after the last check-in someone still shows as online

lock = threading.Lock()
db = {"players": {}}  # key: lower-case name -> {name, token, friends, requests, seen}
MAX_ROOM = 4  # players in a room, host included
MAX_FRAME = 4 * 1024 * 1024
data_path = "names.json"


def load():
    global db
    if os.path.exists(data_path):
        with open(data_path, "r", encoding="utf-8") as f:
            db = json.load(f)
    db.setdefault("players", {})


def save():
    tmp = data_path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(db, f)
    os.replace(tmp, data_path)


def by_token(token):
    for key, p in db["players"].items():
        if token and p.get("token") == token:
            return key, p
    return None, None


def online(p):
    return time.time() - p.get("seen", 0) < ONLINE_SECONDS


def befriend(a, b):
    for x, y in ((a, b), (b, a)):
        if y not in db["players"][x]["friends"]:
            db["players"][x]["friends"].append(y)


def mutual(key, other_key):
    """Both players list each other (after a restore, one side can be missing)."""
    other = db["players"].get(other_key)
    return other is not None and key in other["friends"]


def friend_view(key, p):
    # never any addresses: just whether they're online and have a room open
    with relay_lock:
        room = rooms.get(key)
        hosting = room is not None
        count = 1 + len(room["clients"]) if room else 0
    return {"name": p["name"], "online": online(p) or hosting, "room": hosting, "players": count}


def handle(path, body, ip):
    players = db["players"]
    if path == "/register":
        name = str(body.get("name", "")).strip()
        if not NAME_RE.match(name):
            return {"ok": False, "error": "Names are 3 to 16 letters, numbers or _."}
        key = name.lower()
        if key in players:
            return {"ok": False, "error": "That name is already taken."}
        token = secrets.token_hex(16)
        players[key] = {"name": name, "token": token, "friends": [], "requests": [], "seen": time.time()}
        save()
        return {"ok": True, "token": token, "name": name}
    if path == "/time":
        # the game's furnaces, eggs and daily chests count from this, not the device clock
        return {"ok": True, "time": time.time()}
    if path == "/check":
        name = str(body.get("name", "")).strip()
        return {"ok": True, "free": bool(NAME_RE.match(name)) and name.lower() not in players}

    if path == "/restore":
        # A free web host can wipe the server's file when it restarts. The game
        # keeps its name, key and friends, and puts them back here. A friend only
        # counts once both players have put each other back (see mutual()).
        name = str(body.get("name", "")).strip()
        token = str(body.get("token", ""))
        if not NAME_RE.match(name) or not re.match(r"^[0-9a-f]{32}$", token):
            return {"ok": False, "error": "Can't restore that name."}
        key = name.lower()
        p = players.get(key)
        if p is not None and p.get("token") != token:
            return {"ok": False, "error": "That name is already taken."}
        if p is None:
            p = players[key] = {"name": name, "token": token, "friends": [], "requests": [], "seen": time.time()}
        for f in body.get("friends", [])[:200]:
            fk = str(f).strip().lower()
            if NAME_RE.match(fk) and fk != key and fk not in p["friends"]:
                p["friends"].append(fk)
        save()
        return {"ok": True, "name": p["name"]}

    key, me = by_token(body.get("token"))
    if me is None:
        return {"ok": False, "error": "Unknown player. Register the name first.", "unknown": True}
    if path == "/release":
        for other in players.values():
            other["friends"] = [f for f in other["friends"] if f != key]
            other["requests"] = [r for r in other["requests"] if r != key]
        del players[key]
        save()
        return {"ok": True}
    if path == "/presence":
        me["seen"] = time.time()
        return {"ok": True}
    if path == "/friends":
        me["seen"] = time.time()
        return {"ok": True,
                "friends": [friend_view(f, players[f]) for f in me["friends"] if f in players and mutual(key, f)],
                "requests": [players[r]["name"] for r in me["requests"] if r in players]}
    if path == "/friends/add":
        other_key = str(body.get("name", "")).strip().lower()
        if other_key == key:
            return {"ok": False, "error": "That's you!"}
        other = players.get(other_key)
        if other is None:
            return {"ok": False, "error": "Nobody has that name."}
        if other_key in me["friends"] and key in other["friends"]:
            return {"ok": False, "error": "You're already friends."}
        if key in other["friends"]:
            # they still have us from before a restore: make it both ways again
            if other_key not in me["friends"]:
                me["friends"].append(other_key)
            save()
            return {"ok": True, "friends": True}
        if other_key in me["requests"]:
            # they already asked us: accept straight away
            me["requests"].remove(other_key)
            befriend(key, other_key)
            save()
            return {"ok": True, "friends": True}
        if key not in other["requests"]:
            other["requests"].append(key)
            save()
        return {"ok": True, "friends": False}
    if path == "/friends/answer":
        other_key = str(body.get("name", "")).strip().lower()
        if other_key in me["requests"]:
            me["requests"].remove(other_key)
            if body.get("accept") and other_key in players:
                befriend(key, other_key)
            save()
        return {"ok": True}
    if path == "/friends/remove":
        other_key = str(body.get("name", "")).strip().lower()
        me["friends"] = [f for f in me["friends"] if f != other_key]
        if other_key in players:
            players[other_key]["friends"] = [f for f in players[other_key]["friends"] if f != key]
        save()
        return {"ok": True}
    return {"ok": False, "error": "Unknown request."}


# ---------------------------------------------------------------- room relay
# Frames are [u32 length][u8 type][payload], little-endian.
# Game -> relay: 1 HELLO (json), 2 DATA ([i32 target][u8 channel][u8 mode][bytes]), 3 KICK ([i32 peer])
# Relay -> game: 0x81 WELCOME (json), 0x82 ERROR (json), 0x83 PEER_JOIN ([i32]),
#                0x84 PEER_LEAVE ([i32]), 0x85 DATA ([i32 from][u8 channel][u8 mode][bytes]), 0x86 ROOM_CLOSED
relay_lock = threading.Lock()
rooms = {}  # host's lower-case name -> {"host": Conn, "clients": {peer id: Conn}}


class Conn:
    """A raw TCP relay connection (the desktop game's older way in)."""

    def __init__(self, sock):
        self.sock = sock
        self.wlock = threading.Lock()

    def send(self, typ, payload=b""):
        data = struct.pack("<IB", len(payload) + 1, typ) + payload
        with self.wlock:
            try:
                self.sock.sendall(data)
            except OSError:
                pass

    def recv(self):
        (length,) = struct.unpack("<I", read_exact(self.sock.recv, 4))
        if length < 1 or length > MAX_FRAME:
            raise ConnectionError()
        body = read_exact(self.sock.recv, length)
        return body[0], body[1:]

    def close(self):
        try:
            self.sock.shutdown(socket.SHUT_RDWR)
        except OSError:
            pass
        try:
            self.sock.close()
        except OSError:
            pass


WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


class WSConn(Conn):
    """The same relay over a WebSocket, which is all a browser can open.
    Each binary message is one frame: [u8 type][payload] (no length needed)."""

    def __init__(self, sock, rfile):
        super().__init__(sock)
        self.rfile = rfile

    def _read(self, n):
        data = self.rfile.read(n)
        if data is None or len(data) < n:
            raise ConnectionError()
        return data

    def _write(self, opcode, payload):
        n = len(payload)
        if n < 126:
            head = struct.pack("!BB", 0x80 | opcode, n)
        elif n < 65536:
            head = struct.pack("!BBH", 0x80 | opcode, 126, n)
        else:
            head = struct.pack("!BBQ", 0x80 | opcode, 127, n)
        with self.wlock:
            try:
                self.sock.sendall(head + payload)
            except OSError:
                pass

    def send(self, typ, payload=b""):
        self._write(0x2, bytes([typ]) + payload)

    def recv(self):
        message = b""
        while True:
            b0, b1 = self._read(2)
            opcode = b0 & 0x0F
            n = b1 & 0x7F
            if n == 126:
                (n,) = struct.unpack("!H", self._read(2))
            elif n == 127:
                (n,) = struct.unpack("!Q", self._read(8))
            if n > MAX_FRAME or len(message) + n > MAX_FRAME:
                raise ConnectionError()
            mask = self._read(4) if b1 & 0x80 else None
            data = self._read(n) if n else b""
            if mask:
                data = bytes(c ^ mask[i % 4] for i, c in enumerate(data)) if n < 64 else _unmask(data, mask)
            if opcode == 0x8:  # close
                self._write(0x8, data[:2])
                raise ConnectionError()
            if opcode == 0x9:  # ping
                self._write(0xA, data)
                continue
            if opcode == 0xA:  # pong
                continue
            message += data
            if b0 & 0x80:
                if not message:
                    continue
                return message[0], message[1:]


def _unmask(data, mask):
    # xor four bytes at a time through one big integer: fast enough in pure Python
    n = len(data)
    key = int.from_bytes((mask * (n // 4 + 1))[:n], "big")
    return (int.from_bytes(data, "big") ^ key).to_bytes(n, "big")


def read_exact(recv, n):
    out = b""
    while len(out) < n:
        chunk = recv(n - len(out))
        if not chunk:
            raise ConnectionError()
        out += chunk
    return out


def error(conn, text):
    conn.send(0x82, json.dumps({"error": text}).encode())


def close_room(room):
    for c in list(room["clients"].values()):
        c.send(0x86)
        c.close()
    room["clients"].clear()


def relay_session(conn, hello_timeout):
    """Runs one game's relay connection, raw or WebSocket, until it ends."""
    try:
        hello_timeout(15)
        typ, payload = conn.recv()
        hello_timeout(None)
        if typ != 1:
            return
        hello = json.loads(payload or b"{}")
        with lock:
            key, me = by_token(hello.get("token"))
            if me is not None:
                me["seen"] = time.time()
            friends = list(me["friends"]) if me else []
            host_key = str(hello.get("room", "")).lower()
            # only friends can join: both players must list each other
            is_friend = host_key in friends and me is not None and mutual(key, host_key)
        if me is None:
            error(conn, "Claim your name in Friends first.")
            return
        if hello.get("mode") == "host":
            relay_host(conn, key)
        elif hello.get("mode") == "join":
            relay_join(conn, is_friend, host_key, int(hello.get("id", 0)))
    except (ConnectionError, OSError, ValueError, TypeError, json.JSONDecodeError, struct.error):
        pass
    finally:
        conn.close()


def relay_host(conn, key):
    room = {"host": conn, "clients": {}}
    with relay_lock:
        old = rooms.get(key)
        if old:
            close_room(old)
            old["host"].close()
        rooms[key] = room
    conn.send(0x81, json.dumps({"id": 1}).encode())
    try:
        while True:
            typ, payload = conn.recv()
            if typ == 2 and len(payload) >= 6:
                (target,) = struct.unpack("<i", payload[:4])
                out = struct.pack("<i", 1) + payload[4:]
                with relay_lock:
                    clients = dict(room["clients"])
                for cid, c in clients.items():
                    if target == 0 or target == cid or (target < 0 and cid != -target):
                        c.send(0x85, out)
            elif typ == 3 and len(payload) >= 4:
                (cid,) = struct.unpack("<i", payload[:4])
                with relay_lock:
                    c = room["clients"].pop(cid, None)
                if c:
                    c.send(0x86)
                    c.close()
    finally:
        with relay_lock:
            if rooms.get(key) is room:
                del rooms[key]
            close_room(room)


def relay_join(conn, is_friend, host_key, cid):
    if not is_friend:
        error(conn, "You can only join friends' rooms.")
        return
    with relay_lock:
        room = rooms.get(host_key)
        if room is None:
            problem = "Their room isn't open right now."
        elif len(room["clients"]) + 1 >= MAX_ROOM:
            problem = "That room is full."
        elif cid < 2 or cid in room["clients"]:
            problem = "Couldn't join, try again."
        else:
            problem = ""
            room["clients"][cid] = conn
    if problem:
        error(conn, problem)
        return
    conn.send(0x81, json.dumps({"id": cid}).encode())
    room["host"].send(0x83, struct.pack("<i", cid))
    try:
        while True:
            typ, payload = conn.recv()
            if typ == 2 and len(payload) >= 6:
                # guests only talk to the host (the host passes things on)
                room["host"].send(0x85, struct.pack("<i", cid) + payload[4:])
    finally:
        with relay_lock:
            still = room["clients"].pop(cid, None)
        if still is not None:
            room["host"].send(0x84, struct.pack("<i", cid))


class RelayHandler(socketserver.BaseRequestHandler):
    def handle(self):
        sock = self.request
        sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        relay_session(Conn(sock), sock.settimeout)


class RelayServer(socketserver.ThreadingTCPServer):
    daemon_threads = True
    allow_reuse_address = True


class Handler(BaseHTTPRequestHandler):
    def cors(self):
        # the web build runs on another site (GitHub Pages), so browsers ask first
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(204)
        self.cors()
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self):
        if self.path.split("?")[0] == "/relay" and "websocket" in self.headers.get("Upgrade", "").lower():
            key = self.headers.get("Sec-WebSocket-Key", "")
            accept = base64.b64encode(hashlib.sha1((key + WS_GUID).encode()).digest()).decode()
            self.wfile.write(("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\n"
                              "Connection: Upgrade\r\nSec-WebSocket-Accept: %s\r\n\r\n" % accept).encode())
            self.wfile.flush()
            self.close_connection = True
            sock = self.connection
            sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            relay_session(WSConn(sock, self.rfile), sock.settimeout)
            return
        # anything else: a plain "I'm up" page (web hosts check this)
        data = b"Pixel Wilds online server is running."
        self.send_response(200)
        self.cors()
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        try:
            n = min(int(self.headers.get("Content-Length", 0)), 4096)
            body = json.loads(self.rfile.read(n) or b"{}")
            if not isinstance(body, dict):
                body = {}
        except (ValueError, json.JSONDecodeError):
            body = {}
        with lock:
            out = handle(self.path, body, self.client_address[0])
        data = json.dumps(out).encode()
        self.send_response(200)
        self.cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        pass


def main():
    global data_path
    ap = argparse.ArgumentParser(description="Pixel Wilds name and friends server")
    # web hosts (Render and the like) say which port to use in $PORT
    ap.add_argument("--port", type=int, default=int(os.environ.get("PORT", 24566)))
    ap.add_argument("--relay-port", type=int, default=0, help="defaults to --port + 1")
    ap.add_argument("--data", default=os.environ.get("PIXEL_DATA", "names.json"))
    ap.add_argument("--no-raw-relay", action="store_true", help="only the WebSocket relay (for hosts with one port)")
    args = ap.parse_args()
    data_path = args.data
    load()
    relay_port = args.relay_port or args.port + 1
    if not args.no_raw_relay:
        relay = RelayServer(("0.0.0.0", relay_port), RelayHandler)
        threading.Thread(target=relay.serve_forever, daemon=True).start()
    ThreadingHTTPServer.daemon_threads = True
    server = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    print("Pixel Wilds server: names, friends and the WebSocket relay (/relay) on port %d%s, saving to %s"
          % (args.port, "" if args.no_raw_relay else ", raw relay on port %d" % relay_port, data_path), flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
