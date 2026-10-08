#!/usr/bin/env python3
"""Pixel Wilds online server: player names (each name can only be taken once),
friends lists, and who's online and hosting a room.

Run it on any computer or cheap server that everyone can reach:

    python3 pixel_server.py --port 24566 --data names.json

Then set ONLINE_SERVER in scripts/online.gd to http://<that address>:24566.
Only the Python standard library is needed. Data is saved to a JSON file.
"""
import argparse
import json
import os
import re
import secrets
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

NAME_RE = re.compile(r"^[A-Za-z0-9_]{3,16}$")
ONLINE_SECONDS = 75  # how long after the last check-in someone still shows as online

lock = threading.Lock()
db = {"players": {}}  # key: lower-case name -> {name, token, friends, requests, room, addrs, public_ip, seen}
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


def friend_view(p, viewer_ip):
    room = None
    if online(p) and p.get("room"):
        # same public address: they're on the same network, so use a local address
        if p.get("public_ip") == viewer_ip and p.get("addrs"):
            room = p["addrs"][0]
        else:
            room = p.get("public_ip")
    return {"name": p["name"], "online": online(p), "room": room}


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
        players[key] = {"name": name, "token": token, "friends": [], "requests": [], "room": False, "addrs": [], "public_ip": ip, "seen": time.time()}
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
        me["room"] = bool(body.get("room", False))
        me["addrs"] = [str(a) for a in body.get("addrs", [])][:4]
        me["public_ip"] = ip
        return {"ok": True}
    if path == "/friends":
        me["seen"] = time.time()
        me["public_ip"] = ip
        return {"ok": True,
                "friends": [friend_view(players[f], ip) for f in me["friends"] if f in players],
                "requests": [players[r]["name"] for r in me["requests"] if r in players],
                "my_ip": ip}
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
    ap.add_argument("--data", default="names.json")
    args = ap.parse_args()
    data_path = args.data
    load()
    server = ThreadingHTTPServer(("0.0.0.0", args.port), Handler)
    print("Pixel Wilds server on port %d, saving to %s" % (args.port, data_path), flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
