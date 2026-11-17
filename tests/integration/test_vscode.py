"""Verify Gaia's VS Code package source."""

import json
import unittest

from tests.support import HOSTS, ROOT, USER, eval_raw, run_nix

GAIA = f"{HOSTS['gaia']}.{USER}"


class VscodeTests(unittest.TestCase):
    def test_gaia_uses_vscode_from_the_unstable_input(self):
        expected = run_nix(
            "eval",
            "--impure",
            "--raw",
            "--expr",
            f"(import (builtins.getFlake {json.dumps(str(ROOT))}).inputs.nixpkgs-unstable "
            '{ system = "aarch64-darwin"; config.allowUnfree = true; }).vscode.drvPath',
        ).strip()
        self.assertEqual(eval_raw(f"{GAIA}.programs.vscode.package.drvPath"), expected)
