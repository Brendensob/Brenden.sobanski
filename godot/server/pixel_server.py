#!/usr/bin/env python3
"""Pixel Wilds online server: player names (each name can only be taken once),
friends lists, who's online, and the room relay.

Every player's game hosts a room. Friends join it through this server's relay,
which passes the game traffic along, so players never connect to each other
directly and never learn each other's IP address. Only friends can join.

Run it on any computer or cheap server that everyone can reach:

    python3 pixel_server.py --port 24566 --data names.json

That opens port 24566 (names and friends) and 24567 (the room relay). Then set
ONLINE_SERVER in scripts/online.gd to http://<that address>:24566.
Only the Python standard library is needed. Data is saved to a JSON file.
"""
import argparse
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
    if path == "/check":
        name = str(body.get("name", "")).strip()
        return {"ok": True, "free": bool(NAME_RE.match(name)) and name.lower() not in players}

    key, me = by_token(body.get("token"))
    if me is None:
        return {"ok": False, "error": "Unknown player. Register the name first."}
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
                "friends": [friend_view(f, players[f]) for f in me["friends"] if f in players],
                "requests": [players[r]["name"] for r in me["requests"] if r in players]}
    if path == "/friends/add":
        other_key = str(body.get("name", "")).strip().lower()
        if other_key == key:
            return {"ok": False, "error": "That's you!"}
        other = players.get(other_key)
        if other is None:
            return {"ok": False, "error": "Nobody has that name."}
        if other_key in me["friends"]:
            return {"ok": False, "error": "You're already friends."}
        if other_key in me["requests"]:
            # they already asked us: accept straight away
            me["requests"].remove(other_key)
            me["friends"].append(other_key)
            other["friends"].append(key)
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
                me["friends"].append(other_key)
                players[other_key]["friends"].append(key)
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

    def close(self):
        try:
            self.sock.shutdown(socket.SHUT_RDWR)
        except OSError:
            pass
        try:
            self.sock.close()
        except OSError:
            pass


def read_exact(sock, n):
    out = b""
    while len(out) < n:
        chunk = sock.recv(n - len(out))
        if not chunk:
            raise ConnectionError()
        out += chunk
    return out


def read_frame(sock):
    (length,) = struct.unpack("<I", read_exact(sock, 4))
    if length < 1 or length > MAX_FRAME:
        raise ConnectionError()
    body = read_exact(sock, length)
    return body[0], body[1:]


def error(conn, text):
    conn.send(0x82, json.dumps({"error": text}).encode())


def close_room(room):
    for c in list(room["clients"].values()):
        c.send(0x86)
        c.close()
    room["clients"].clear()


class RelayHandler(socketserver.BaseRequestHandler):
    def handle(self):
        sock = self.request
        sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        conn = Conn(sock)
        try:
            sock.settimeout(15)
            typ, payload = read_frame(sock)
            sock.settimeout(None)
            if typ != 1:
                return
            hello = json.loads(payload or b"{}")
            with lock:
                key, me = by_token(hello.get("token"))
                if me is not None:
                    me["seen"] = time.time()
                friends = list(me["friends"]) if me else []
            if me is None:
                error(conn, "Claim your name in Friends first.")
                return
            if hello.get("mode") == "host":
                self.host(conn, key)
            elif hello.get("mode") == "join":
                self.join(conn, key, friends, str(hello.get("room", "")).lower(), int(hello.get("id", 0)))
        except (ConnectionError, OSError, ValueError, json.JSONDecodeError, struct.error):
            pass
        finally:
            conn.close()

    def host(self, conn, key):
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
                typ, payload = read_frame(conn.sock)
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

    def join(self, conn, key, friends, host_key, cid):
        if host_key not in friends:
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
                typ, payload = read_frame(conn.sock)
                if typ == 2 and len(payload) >= 6:
                    # guests only talk to the host (the host passes things on)
                    room["host"].send(0x85, struct.pack("<i", cid) + payload[4:])
        finally:
            with relay_lock:
                still = room["clients"].pop(cid, None)
            if still is not None:
                room["host"].send(0x84, struct.pack("<i", cid))


class RelayServer(socketserver.ThreadingTCPServer):
    daemon_threads = True
    allow_reuse_address = True


class Handler(BaseHTTPRequestHandler):
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
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        pass


def main():
    global data_path
    ap = argparse.ArgumentParser(description="Pixel Wilds name and friends server")
    ap.add_argument("--port", type=int, default=24566)
    ap.add_argument("--relay-port", type=int, default=0, help="defaults to --port + 1")
    ap.add_argument("--data", default="names.json")
    args = ap.parse_args()
    data_path = args.data
    load()
    relay_port = args.relay_port or args.port + 1
    relay = RelayServer(("0.0.0.0", relay_port), RelayHandler)
    threading.Thread(target=relay.serve_forever, daemon=True).start()
    server = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    print("Pixel Wilds server: names and friends on port %d, room relay on port %d, saving to %s" % (args.port, relay_port, data_path), flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
