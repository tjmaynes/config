"""Flake smoke checks evaluate outputs without building or activating."""

import json
import unittest

from tests.support import run_nix


class FlakeSmokeTests(unittest.TestCase):
    def test_flake_metadata_is_valid_json(self):
        metadata = json.loads(run_nix("flake", "metadata", "--json"))
        self.assertIsInstance(metadata, dict)

    def test_all_systems_pass_flake_checks_without_building(self):
        run_nix("flake", "check", "--no-build", "--all-systems")

    def test_flake_outputs_exclude_retired_hosts(self):
        outputs = run_nix("flake", "show", "--all-systems", "--json")
        self.assertNotRegex(outputs, "apollo|demeter|kratos|athena")
        self.assertIsInstance(json.loads(outputs), dict)
