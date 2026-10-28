"""Documentation and CI contracts formerly checked by docs.sh."""

import unittest

from tests.support import ROOT


class DocumentationTests(unittest.TestCase):
    def test_readme_covers_workstation_operations(self):
        readme = (ROOT / "README.md").read_text()
        for heading in (
            "Bootstrap",
            "Update",
            "Check",
            "Build",
            "Activate",
            "Rollback",
            "Secrets",
            "Mise",
        ):
            with self.subTest(heading=heading):
                self.assertRegex(readme, rf"(?m)^## {heading}")
        for text in (
            "gaia",
            "make bootstrap",
            "make deploy",
            "/Applications/Nix Apps",
        ):
            with self.subTest(text=text):
                self.assertIn(text, readme)
        self.assertNotRegex(readme, "apollo|demeter|kratos|athena")

    def test_ci_installs_nix_without_activation(self):
        workflow = (ROOT / ".github/workflows/check.yml").read_text()
        self.assertIn("nix-installer-action", workflow)
        self.assertNotRegex(workflow, "darwin-rebuild switch|nixos-rebuild switch")

    def test_extracted_server_files_are_absent(self):
        for path in (
            "hosts/atlas",
            "modules/server",
            "scripts/deploy-atlas.sh",
            "tests/atlas.sh",
            "docs/atlas-cutover-runbook.md",
            "docs/atlas-operations.md",
            "plans/003-atlas-server-foundation",
            "plans/004-atlas-nixos-docker-migration",
            "plans/005-home-server-repository-extraction",
            "renovate.json5",
        ):
            with self.subTest(path=path):
                self.assertFalse((ROOT / path).exists(), path)

    def test_root_configuration_has_no_extracted_server_references(self):
        paths = [
            ROOT / name
            for name in (
                "README.md",
                "AGENTS.md",
                "Makefile",
                "flake.nix",
                "flake.lock",
                ".gitignore",
            )
        ]
        paths.extend(path for path in (ROOT / ".github").rglob("*") if path.is_file())
        for path in paths:
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertNotRegex(path.read_text().lower(), "atlas|sops-nix")
