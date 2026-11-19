"""Verify Gaia's Cursor installation."""

import unittest

from tests.support import HOSTS, PACKAGE_PNAMES, USER, eval_json

GAIA = f"{HOSTS['gaia']}.{USER}"


class CursorTests(unittest.TestCase):
    def test_cursor_is_enabled_on_gaia(self):
        self.assertTrue(eval_json(f"{GAIA}.programs.cursor.enable"))

    def test_cursor_is_in_system_applications(self):
        packages = eval_json(
            f"{HOSTS['gaia']}.environment.systemPackages", apply=PACKAGE_PNAMES
        )
        self.assertIn("cursor", packages)
