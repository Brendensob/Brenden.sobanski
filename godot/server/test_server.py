"""Checks the name and friends server: python3 test_server.py"""
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
        return ps.read_frame(s)

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


if __name__ == "__main__":
    unittest.main()
