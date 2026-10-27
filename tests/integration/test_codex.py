"""Verify native Home Manager Codex and MCP configuration."""

import unittest

from tests.support import HOSTS, USER, eval_json


class CodexHomeTests(unittest.TestCase):
    def test_codex_uses_native_mutable_settings_and_unstable_package(self):
        for host, config in HOSTS.items():
            home = f"{config}.{USER}"
            with self.subTest(host=host):
                self.assertIs(eval_json(f"{home}.programs.codex.enable"), True)
                self.assertIs(eval_json(f"{home}.programs.codex.mutableSettings"), True)
                self.assertIs(
                    eval_json(f"{home}.programs.codex.enableMcpIntegration"), True
                )
                self.assertIs(eval_json(f"{home}.programs.mcp.enable"), True)
                self.assertEqual(
                    eval_json(f"{home}.programs.codex.package.pname"), "codex"
                )
                self.assertEqual(
                    eval_json(f"{home}.programs.codex.settings.model"),
                    "gpt-6.1-terra",
                )
                self.assertIs(
                    eval_json(f"{home}.programs.codex.settings.features.js_repl"),
                    True,
                )
                self.assertEqual(
                    eval_json(f"{home}.programs.mcp.servers.n8n.url"),
                    "https://n8n.tjmaynes.com/mcp-server/http",
                )

    def test_user_config_is_merged_without_an_immutable_home_file(self):
        for host, config in HOSTS.items():
            home = f"{config}.{USER}"
            with self.subTest(host=host):
                activation = eval_json(f"{home}.home.activation.codexMutableSettings")
                self.assertIn("linkGeneration", activation["after"])
                self.assertIn("/.codex/config.toml", activation["data"])
                files = eval_json(
                    f"{home}.home.file", apply="files: builtins.attrNames files"
                )
                self.assertNotIn(".codex/config.toml", files)
                self.assertNotIn(".codex/auth.json", files)
                self.assertNotIn(".config/codex-nix/managed.json", files)

    def test_home_manager_does_not_manage_project_overrides(self):
        for host, config in HOSTS.items():
            home = f"{config}.{USER}"
            with self.subTest(host=host):
                self.assertEqual(eval_json(f"{home}.programs.codex.profiles"), {})
                files = eval_json(
                    f"{home}.home.file", apply="files: builtins.attrNames files"
                )
                self.assertFalse(any("consulting/sproutup" in path for path in files))
