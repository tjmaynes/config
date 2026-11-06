"""Verify shared editor settings and the extensions served by code-server."""

import json
import unittest

from tests.support import ROOT, USER, eval_json, eval_raw, run_nix

GAIA = f".#darwinConfigurations.gaia.config.{USER}"
ATHENA = ".#nixosConfigurations.athena.config"


class SharedVscodeTests(unittest.TestCase):
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

    def test_code_server_receives_shared_settings_with_linux_runtime_paths(self):
        desktop = eval_json(f"{GAIA}.programs.vscode.profiles.default.userSettings")
        browser = json.loads(
            eval_json(
                f'{ATHENA}.{USER}.xdg.dataFile."code-server/User/settings.json".text'
            )
        )
        expected = desktop | {
            "go.alternateTools": {
                "go": "/home/tjmaynes/.local/share/mise/installs/go/1.27.0/bin/go"
            }
        }
        self.assertEqual(browser, expected)

    def test_code_server_bundles_shared_extensions_and_compatible_python_support(self):
        package = f"{ATHENA}.services.code-server.package"
        derivations = json.loads(run_nix("derivation", "show", package))
        wrapper = next(iter(derivations["derivations"].values()))
        extension_drvs = [
            path
            for path in wrapper["inputs"]["drvs"]
            if path.endswith("-vscode-extensions.drv")
        ]
        self.assertEqual(len(extension_drvs), 1)
        self.assertIn("--extensions-dir", wrapper["env"]["buildCommand"])
        bundle = next(
            iter(
                json.loads(
                    run_nix("derivation", "show", "/nix/store/" + extension_drvs[0])
                )["derivations"].values()
            )
        )
        desktop_drvs = set(
            eval_json(
                f"{GAIA}.programs.vscode.profiles.default.extensions",
                apply="extensions: map (extension: builtins.baseNameOf extension.drvPath) extensions",
            )
        )
        browser_drvs = set(bundle["inputs"]["drvs"])
        # Hashes differ between platforms; extension derivation names retain
        # the pinned ID/version, which should match on both hosts.
        desktop_names = {name.split("-", 1)[1].lower() for name in desktop_drvs}
        browser_names = {name.split("-", 1)[1].lower() for name in browser_drvs}
        desktop_only = {
            name
            for name in desktop_names
            if "ms-python-vscode-pylance-" in name
            or "ms-vscode-remote-remote-containers-" in name
        }
        self.assertEqual(len(desktop_only), 2)
        self.assertTrue((desktop_names - desktop_only).issubset(browser_names))
        self.assertTrue(desktop_only.isdisjoint(browser_names))
        self.assertTrue(any("ms-pyright-pyright-" in name for name in browser_names))
