"""Evaluate Tailscale enrollment before and after encrypted provisioning."""

import json
import unittest

from tests.support import run_nix


class TailscaleSopsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.states = json.loads(
            run_nix(
                "eval", "--impure", "--json", "--file", "tests/fixtures/athena-sops.nix"
            )
        )

    def test_missing_encrypted_file_keeps_enrollment_disabled_with_a_warning(self):
        state = self.states["unprovisioned"]
        self.assertIsNone(state["authKeyFile"])
        self.assertTrue(
            any(
                "automatic Tailscale enrollment is disabled" in warning
                for warning in state["warnings"]
            )
        )

    def test_enrollment_consumes_only_the_root_owned_runtime_secret(self):
        state = self.states["provisioned"]
        self.assertEqual(state["key"], "TAILSCALE_AUTHKEY")
        self.assertEqual(state["owner"], "root")
        self.assertEqual(state["group"], "root")
        self.assertEqual(state["mode"], "0400")
        self.assertEqual(state["authKeyFile"], "/run/secrets/tailscale-auth-key")
        self.assertEqual(state["path"], state["authKeyFile"])
        self.assertEqual(state["sshKeyPaths"], ["/etc/ssh/ssh_host_ed25519_key"])
        self.assertIs(state["validateSopsFiles"], True)
        self.assertIs(state["useSystemdActivation"], True)
        self.assertTrue(state["toplevel"].endswith(".drv"))

    def test_enrollment_waits_for_decryption_and_preserves_firewall_settings(self):
        state = self.states["provisioned"]
        for relation in ("after", "requires"):
            self.assertIn("sops-install-secrets.service", state[relation])
        self.assertIn("multi-user.target", state["wantedBy"])
        self.assertEqual(state["extraUpFlags"], state["extraSetFlags"])
        self.assertIn("--netfilter-mode=nodivert", state["extraUpFlags"])
        self.assertIn("--accept-dns=false", state["extraUpFlags"])
        self.assertIn("tailscaled-autoconnect.service", state["restartUnits"])
