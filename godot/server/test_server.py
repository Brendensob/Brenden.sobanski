"""Checks the name and friends server: python3 test_server.py"""
import json
import os
import sys
import tempfile
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
        # Bob hosts a room: friends on another network get his public address,
        # friends on the same network get his local one
        self.call("/presence", {"token": b, "room": True, "addrs": ["192.168.1.9"]}, ip="5.5.5.5")
        self.assertEqual(self.call("/friends", {"token": a}, ip="9.9.9.9")["friends"][0]["room"], "5.5.5.5")
        self.assertEqual(self.call("/friends", {"token": a}, ip="5.5.5.5")["friends"][0]["room"], "192.168.1.9")
        self.call("/friends/remove", {"token": a, "name": "Bob"})
        self.assertEqual(self.call("/friends", {"token": b})["friends"], [])

    def test_saved_to_disk(self):
        self.call("/register", {"name": "Saved"})
        with open(ps.data_path) as f:
            self.assertIn("saved", json.load(f)["players"])


if __name__ == "__main__":
    unittest.main()
