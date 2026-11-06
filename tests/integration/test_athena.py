"""Evaluate Athena's headless boot services without starting them."""

import unittest

from tests.support import USER, eval_json, eval_raw

CONFIG = ".#nixosConfigurations.athena.config"
HOME = f"{CONFIG}.{USER}"


class AthenaTests(unittest.TestCase):
    def test_orca_runs_as_the_user_and_accepts_tailnet_connections(self):
        unit = eval_json(
            f"{CONFIG}.systemd.services.orca",
            apply="service: { inherit (service) wantedBy after requires serviceConfig environment; }",
        )
        self.assertIn("multi-user.target", unit["wantedBy"])
        self.assertIn("home-manager-tjmaynes.service", unit["requires"])
        self.assertEqual(unit["serviceConfig"]["User"], "tjmaynes")
        self.assertIn(
            "serve --port 6768 --pairing-address athena",
            unit["serviceConfig"]["ExecStart"],
        )
        self.assertEqual(unit["environment"]["HOME"], "/home/tjmaynes")

    def test_emacs_is_available_as_a_terminal_editor_without_a_service(self):
        self.assertIs(eval_json(f"{HOME}.programs.emacs.enable"), True)
        self.assertIs(eval_json(f"{HOME}.services.emacs.enable"), False)
        self.assertEqual(
            eval_json(f"{HOME}.programs.emacs.package.outPath"),
            eval_json(".#nixosConfigurations.athena.pkgs.emacs-nox.outPath"),
        )

    def test_tailscale_does_not_bypass_the_host_firewall(self):
        self.assertIn(
            "--netfilter-mode=nodivert",
            eval_json(f"{CONFIG}.services.tailscale.extraSetFlags"),
        )
        self.assertIn(
            "--netfilter-mode=nodivert",
            eval_json(f"{CONFIG}.systemd.services.tailscaled-set.script"),
        )

    def test_host_evaluates_as_a_linux_server(self):
        self.assertEqual(eval_json(f"{CONFIG}.networking.hostName"), "athena")
        self.assertEqual(
            eval_json(f"{CONFIG}.nixpkgs.hostPlatform.system"), "x86_64-linux"
        )
        self.assertTrue(
            eval_raw(f"{CONFIG}.system.build.toplevel.drvPath").endswith(".drv")
        )
        self.assertEqual(eval_json(f"{HOME}.home.homeDirectory"), "/home/tjmaynes")

    def test_codex_starts_at_boot_without_login_and_keeps_a_private_socket(self):
        service = eval_json(
            f"{CONFIG}.systemd.services.codex",
            apply="service: { inherit (service) wantedBy after requires serviceConfig environment; }",
        )
        self.assertIn("multi-user.target", service["wantedBy"])
        self.assertIn("home-manager-tjmaynes.service", service["after"])
        self.assertIn("home-manager-tjmaynes.service", service["requires"])
        settings = service["serviceConfig"]
        self.assertEqual(settings["User"], "tjmaynes")
        self.assertEqual(settings["Group"], "users")
        self.assertEqual(settings["Restart"], "on-failure")
        self.assertEqual(settings["RuntimeDirectoryMode"], "0700")
        self.assertIn(
            "app-server --listen unix:///run/codex/app-server.sock",
            settings["ExecStart"],
        )
        self.assertNotIn("ws://", settings["ExecStart"])
        self.assertEqual(service["environment"]["HOME"], "/home/tjmaynes")
        self.assertEqual(service["environment"]["CODEX_HOME"], "/home/tjmaynes/.codex")
        self.assertIn(
            "/etc/profiles/per-user/tjmaynes/bin", service["environment"]["PATH"]
        )

    def test_code_server_uses_runtime_auth_and_is_ready_for_the_external_proxy(self):
        service = eval_json(f"{CONFIG}.services.code-server")
        self.assertIs(service["enable"], True)
        self.assertEqual(service["user"], "tjmaynes")
        self.assertEqual(service["host"], "0.0.0.0")
        self.assertEqual(service["port"], 8080)
        self.assertEqual(service["auth"], "password")
        unit = eval_json(
            f"{CONFIG}.systemd.services.code-server",
            apply="service: { inherit (service) wantedBy serviceConfig environment; }",
        )
        self.assertIn("multi-user.target", unit["wantedBy"])
        self.assertEqual(
            unit["serviceConfig"]["EnvironmentFile"],
            "/var/lib/athena/code-server.env",
        )
        self.assertNotIn("PASSWORD", unit["environment"])

    def test_network_services_are_only_open_on_tailscale(self):
        self.assertIs(eval_json(f"{CONFIG}.services.tailscale.enable"), True)
        self.assertIs(eval_json(f"{CONFIG}.services.openssh.enable"), True)
        self.assertIs(eval_json(f"{CONFIG}.services.openssh.openFirewall"), False)
        self.assertEqual(eval_json(f"{CONFIG}.networking.firewall.allowedTCPPorts"), [])
        self.assertEqual(
            eval_json(
                f"{CONFIG}.networking.firewall.interfaces.tailscale0.allowedTCPPorts"
            ),
            [22, 6768, 8080],
        )
        self.assertNotIn(
            "tailscale0", eval_json(f"{CONFIG}.networking.firewall.trustedInterfaces")
        )

    def test_development_profile_is_headless_and_has_codex_and_skills(self):
        for program in ("ghostty", "vscode"):
            with self.subTest(program=program):
                self.assertIs(eval_json(f"{HOME}.programs.{program}.enable"), False)
        self.assertNotIn("macos", eval_json(f"{HOME}.programs.zsh.oh-my-zsh.plugins"))
        self.assertIs(eval_json(f"{HOME}.programs.codex.enable"), True)
        self.assertIs(eval_json(f"{HOME}.programs.codex.mutableSettings"), True)
        files = eval_json(f"{HOME}.home.file", apply="files: builtins.attrNames files")
        self.assertIn(".agents/skills/brainstorming", files)
        self.assertNotIn(".config/offlineimap/config", files)
        self.assertNotIn(".codex/auth.json", files)
