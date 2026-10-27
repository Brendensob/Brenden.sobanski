"""Checks the name and friends server: python3 test_server.py"""
import base64
import hashlib
import json
import os
import socket
import struct
import sys
import tempfile
import threading
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixel_server as ps  # noqa: E402


class ServerTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        ps.data_path = os.path.join(self.dir, "names.json")
        ps.db = {"players": {}}

    def call(self, path, body, ip="1.2.3.4"):
        return ps.handle(path, body, ip)

    def test_names_are_taken_once(self):
        a = self.call("/register", {"name": "Brenden"})
        self.assertTrue(a["ok"])
        self.assertFalse(self.call("/register", {"name": "brenden"})["ok"])
        self.assertFalse(self.call("/register", {"name": "x"})["ok"])
        self.assertFalse(self.call("/register", {"name": "bad name!"})["ok"])
        self.assertFalse(self.call("/check", {"name": "BRENDEN"})["free"])
        self.call("/release", {"token": a["token"]})
        self.assertTrue(self.call("/register", {"name": "Brenden"})["ok"])

    def test_time(self):
        import time
        r = self.call("/time", {})
        self.assertTrue(r["ok"])
        self.assertAlmostEqual(r["time"], time.time(), delta=2)

    def test_friends(self):
        a = self.call("/register", {"name": "Alice"})["token"]
        b = self.call("/register", {"name": "Bob"})["token"]
        self.assertFalse(self.call("/friends/add", {"token": a, "name": "Nobody"})["ok"])
        self.assertTrue(self.call("/friends/add", {"token": a, "name": "bob"})["ok"])
        self.assertEqual(self.call("/friends", {"token": b})["requests"], ["Alice"])
        self.call("/friends/answer", {"token": b, "name": "alice", "accept": True})
        fa = self.call("/friends", {"token": a})
        self.assertEqual([f["name"] for f in fa["friends"]], ["Bob"])
        # no addresses are ever handed out, only whether a friend has a room open
        self.call("/presence", {"token": b}, ip="5.5.5.5")
        view = self.call("/friends", {"token": a}, ip="9.9.9.9")
        self.assertNotIn("5.5.5.5", json.dumps(view))
        self.assertNotIn("9.9.9.9", json.dumps(view))
        self.assertIs(view["friends"][0]["room"], False)
        self.call("/friends/remove", {"token": a, "name": "Bob"})
        self.assertEqual(self.call("/friends", {"token": b})["friends"], [])

    def test_saved_to_disk(self):
        self.call("/register", {"name": "Saved"})
        with open(ps.data_path) as f:
            self.assertIn("saved", json.load(f)["players"])


class RelayTest(unittest.TestCase):
    """A host and a friend talk through the relay without learning each other's address."""

    def setUp(self):
        self.dir = tempfile.mkdtemp()
        ps.data_path = os.path.join(self.dir, "names.json")
        ps.db = {"players": {}}
        ps.rooms.clear()
        self.relay = ps.RelayServer(("127.0.0.1", 0), ps.RelayHandler)
        self.port = self.relay.server_address[1]
        threading.Thread(target=self.relay.serve_forever, daemon=True).start()

    def tearDown(self):
        self.relay.shutdown()
        self.relay.server_close()

    def connect(self, hello):
        s = socket.create_connection(("127.0.0.1", self.port))
        s.settimeout(5)
        body = json.dumps(hello).encode()
        s.sendall(struct.pack("<IB", len(body) + 1, 1) + body)
        return s

    def frame(self, s):
        return ps.Conn(s).recv()

    def test_room_traffic(self):
        a = ps.handle("/register", {"name": "Host1"}, "1.1.1.1")["token"]
        b = ps.handle("/register", {"name": "Guest1"}, "2.2.2.2")["token"]
        c = ps.handle("/register", {"name": "Stranger"}, "3.3.3.3")["token"]
        ps.handle("/friends/add", {"token": b, "name": "Host1"}, "")
        ps.handle("/friends/answer", {"token": a, "name": "Guest1", "accept": True}, "")
        host = self.connect({"token": a, "mode": "host"})
        self.assertEqual(self.frame(host)[0], 0x81)
        # strangers can't get in
        st = self.connect({"token": c, "mode": "join", "room": "host1", "id": 77})
        typ, body = self.frame(st)
        self.assertEqual(typ, 0x82)
        self.assertIn("friends", json.loads(body)["error"])
        guest = self.connect({"token": b, "mode": "join", "room": "HOST1", "id": 42})
        self.assertEqual(json.loads(self.frame(guest)[1])["id"], 42)
        typ, body = self.frame(host)
        self.assertEqual((typ, struct.unpack("<i", body)[0]), (0x83, 42))
        self.assertTrue(ps.handle("/friends", {"token": b}, "")["friends"][0]["room"])
        # guest -> host
        guest.sendall(struct.pack("<IBiBB", 1 + 6 + 2, 2, 1, 0, 2) + b"hi")
        typ, body = self.frame(host)
        self.assertEqual(typ, 0x85)
        self.assertEqual(struct.unpack("<iBB", body[:6]), (42, 0, 2))
        self.assertEqual(body[6:], b"hi")
        # host -> everyone
        host.sendall(struct.pack("<IBiBB", 1 + 6 + 3, 2, 0, 0, 2) + b"yo!")
        typ, body = self.frame(guest)
        self.assertEqual((typ, struct.unpack("<i", body[:4])[0], body[6:]), (0x85, 1, b"yo!"))
        # the host leaves: the room closes for the guest
        host.close()
        self.assertEqual(self.frame(guest)[0], 0x86)


class PublicRoomTest(RelayTest):
    """A public room is listed and anyone can join it; a private one stays friends-only."""

    def test_public_room(self):
        a = ps.handle("/register", {"name": "PubHost"}, "1.1.1.1")["token"]
        c = ps.handle("/register", {"name": "Anyone"}, "3.3.3.3")["token"]
        d = ps.handle("/register", {"name": "Private"}, "4.4.4.4")["token"]
        pub = self.connect({"token": a, "mode": "host", "public": True})
        self.assertEqual(self.frame(pub)[0], 0x81)
        priv = self.connect({"token": d, "mode": "host"})
        self.assertEqual(self.frame(priv)[0], 0x81)
        listed = ps.handle("/rooms", {"token": c}, "")["rooms"]
        self.assertEqual([r["name"] for r in listed], ["PubHost"])
        self.assertEqual(listed[0]["players"], 1)
        # your own public room isn't listed to you
        self.assertEqual(ps.handle("/rooms", {"token": a}, "")["rooms"], [])
        # a stranger joins the public room...
        g = self.connect({"token": c, "mode": "join", "room": "pubhost", "id": 50})
        self.assertEqual(json.loads(self.frame(g)[1])["id"], 50)
        self.assertEqual(ps.handle("/rooms", {"token": d}, "")["rooms"][0]["players"], 2)
        # ...but not the private one
        g2 = self.connect({"token": c, "mode": "join", "room": "private", "id": 51})
        typ, body = self.frame(g2)
        self.assertEqual(typ, 0x82)
        self.assertIn("public", json.loads(body)["error"])
        pub.close()
        priv.close()


class WebSocketRelayTest(unittest.TestCase):
    """Phones and browsers reach the same relay as a WebSocket on the main port."""

    def setUp(self):
        self.dir = tempfile.mkdtemp()
        ps.data_path = os.path.join(self.dir, "names.json")
        ps.db = {"players": {}}
        ps.rooms.clear()
        self.http = ps.ThreadingHTTPServer(("127.0.0.1", 0), ps.Handler)
        self.http.daemon_threads = True
        self.port = self.http.server_address[1]
        threading.Thread(target=self.http.serve_forever, daemon=True).start()

    def tearDown(self):
        self.http.shutdown()
        self.http.server_close()

    def ws(self, hello):
        s = socket.create_connection(("127.0.0.1", self.port))
        s.settimeout(5)
        key = base64.b64encode(os.urandom(16)).decode()
        s.sendall(("GET /relay HTTP/1.1\r\nHost: x\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                   "Sec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n" % key).encode())
        head = b""
        while b"\r\n\r\n" not in head:
            head += s.recv(1)
        self.assertIn(b"101", head.split(b"\r\n")[0])
        want = base64.b64encode(hashlib.sha1((key + ps.WS_GUID).encode()).digest())
        self.assertIn(want, head)
        self.send(s, 1, json.dumps(hello).encode())
        return s

    def send(self, s, typ, payload, split=False):
        # browsers always mask what they send; also try a message split in two
        data = bytes([typ]) + payload
        parts = [data[:3], data[3:]] if split else [data]
        for i, part in enumerate(parts):
            mask = os.urandom(4)
            fin = 0x80 if i == len(parts) - 1 else 0
            op = 0x2 if i == 0 else 0x0
            n = len(part)
            head = struct.pack("!BB", fin | op, 0x80 | n) if n < 126 else struct.pack("!BBH", fin | op, 0x80 | 126, n)
            s.sendall(head + mask + bytes(c ^ mask[j % 4] for j, c in enumerate(part)))

    def frame(self, s):
        b0, b1 = ps.read_exact(s.recv, 2)
        n = b1 & 0x7F
        if n == 126:
            (n,) = struct.unpack("!H", ps.read_exact(s.recv, 2))
        elif n == 127:
            (n,) = struct.unpack("!Q", ps.read_exact(s.recv, 8))
        data = ps.read_exact(s.recv, n)
        return data[0], data[1:]

    def test_room_over_websocket(self):
        a = ps.handle("/register", {"name": "WebHost"}, "")["token"]
        b = ps.handle("/register", {"name": "PhoneGuy"}, "")["token"]
        ps.handle("/friends/add", {"token": b, "name": "WebHost"}, "")
        ps.handle("/friends/answer", {"token": a, "name": "PhoneGuy", "accept": True}, "")
        host = self.ws({"token": a, "mode": "host"})
        self.assertEqual(self.frame(host)[0], 0x81)
        guest = self.ws({"token": b, "mode": "join", "room": "webhost", "id": 9})
        self.assertEqual(self.frame(guest)[0], 0x81)
        self.assertEqual(self.frame(host), (0x83, struct.pack("<i", 9)))
        big = os.urandom(70000)
        self.send(guest, 2, struct.pack("<iBB", 1, 0, 2) + b"split", split=True)
        typ, body = self.frame(host)
        self.assertEqual((typ, struct.unpack("<i", body[:4])[0], body[6:]), (0x85, 9, b"split"))
        # a big message (a whole map) goes through in one piece
        mask = os.urandom(4)
        data = bytes([2]) + struct.pack("<iBB", 1, 0, 2) + big
        guest.sendall(struct.pack("!BBQ", 0x82, 0x80 | 127, len(data)) + mask + ps._unmask(data, mask))
        typ, body = self.frame(host)
        self.assertEqual(body[6:], big)
        self.send(host, 2, struct.pack("<iBB", 0, 0, 2) + b"yo")
        self.assertEqual(self.frame(guest)[1][6:], b"yo")
        host.close()
        self.assertEqual(self.frame(guest)[0], 0x86)

    def test_web_build_can_ask(self):
        # browsers check first (CORS), then post
        s = socket.create_connection(("127.0.0.1", self.port))
        s.sendall(b"OPTIONS /time HTTP/1.1\r\nHost: x\r\nOrigin: https://brendensob.github.io\r\n\r\n")
        reply = s.recv(4096)
        self.assertIn(b"204", reply)
        self.assertIn(b"Access-Control-Allow-Origin: *", reply)


class RestoreTest(unittest.TestCase):
    """A free host can wipe the server; the games put their names and friends back."""

    def setUp(self):
        self.dir = tempfile.mkdtemp()
        ps.data_path = os.path.join(self.dir, "names.json")
        ps.db = {"players": {}}

    def test_restore_after_wipe(self):
        a = ps.handle("/register", {"name": "Alice"}, "")["token"]
        b = ps.handle("/register", {"name": "Bob"}, "")["token"]
        ps.handle("/friends/add", {"token": a, "name": "Bob"}, "")
        ps.handle("/friends/answer", {"token": b, "name": "Alice", "accept": True}, "")
        ps.db = {"players": {}}  # the server restarted with an empty file
        self.assertTrue(ps.handle("/friends", {"token": a}, "").get("unknown"))
        self.assertTrue(ps.handle("/restore", {"name": "Alice", "token": a, "friends": ["Bob"]}, "")["ok"])
        # Bob isn't back yet, so he isn't a friend yet
        self.assertEqual(ps.handle("/friends", {"token": a}, "")["friends"], [])
        ps.handle("/restore", {"name": "Bob", "token": b, "friends": ["alice"]}, "")
        self.assertEqual([f["name"] for f in ps.handle("/friends", {"token": a}, "")["friends"]], ["Bob"])
        # nobody can take a restored name with a different key, or fake a friendship
        self.assertFalse(ps.handle("/restore", {"name": "Alice", "token": "0" * 32}, "")["ok"])
        c = ps.handle("/register", {"name": "Mallory"}, "")["token"]
        ps.handle("/restore", {"name": "Mallory", "token": c, "friends": ["Alice"]}, "")
        self.assertNotIn("Alice", [f["name"] for f in ps.handle("/friends", {"token": c}, "")["friends"]])


if __name__ == "__main__":
    unittest.main()
