"""Static repository hygiene and flake input contracts."""

import json
import unittest

from tests.support import ROOT


class RepositoryTests(unittest.TestCase):
    def test_make_uses_current_command_names(self):
        makefile = (ROOT / "Makefile").read_text()
        self.assertRegex(makefile, r"(?m)^format:")
        self.assertNotRegex(makefile, r"(?m)^fmt:")
        self.assertRegex(makefile, r"(?m)^deploy:")
        self.assertNotRegex(makefile, r"(?m)^switch:")
        self.assertRegex(makefile, r"(?m)^\.PHONY:.*\bdeploy\b")
        self.assertRegex(makefile, r"(?m)^update:")
        self.assertRegex(makefile, r"(?m)^\t\$\(NIX\) flake update$")
        self.assertRegex(makefile, r"(?m)^update-unstable:")
        self.assertIn("make update-unstable", (ROOT / "README.md").read_text())
        self.assertRegex(makefile, r"(?m)^update-home-manager:")
        self.assertRegex(makefile, r"(?m)^\t\$\(NIX\) flake update home-manager$")
        self.assertIn("make update-home-manager", (ROOT / "README.md").read_text())

    def test_legacy_files_are_absent(self):
        for path in (
            "hosts/apollo.nix",
            "hosts/demeter.nix",
            "hosts/gaia.nix",
            "hosts/athena.nix",
            "hosts/kratos.sh",
            "modules/common/default.nix",
            "modules/common/nixpkgs.nix",
            "modules/common/settings.nix",
            "modules/home-manager/default.nix",
            "scripts/install.sh",
            "scripts/reload.sh",
        ):
            with self.subTest(path=path):
                self.assertFalse((ROOT / path).exists(), path)

    def test_configuration_has_no_legacy_dependencies(self):
        paths = [ROOT / "Makefile"]
        for directory in ("modules", "hosts"):
            paths.extend(
                path for path in (ROOT / directory).rglob("*") if path.is_file()
            )
        for path in paths:
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertNotRegex(
                    path.read_bytes(),
                    rb"NIX_PATH|builtins\.getEnv|<home-manager|config/dotfiles|bash_onstart",
                )

    def test_skill_repositories_are_locked_nonflake_inputs(self):
        flake = (ROOT / "flake.nix").read_text()
        nodes = json.loads((ROOT / "flake.lock").read_text())["nodes"]
        for name, url in {
            "superpowers": "github:obra/superpowers/main",
            "tjmaynes-skills": "github:tjmaynes/skills/main",
            "mattpocock-skills": "github:mattpocock/skills/main",
            "addyosmani-agent-skills": "github:addyosmani/agent-skills/main",
        }.items():
            with self.subTest(repository=name):
                self.assertIn(f'url = "{url}";', flake)
                self.assertIs(nodes[name]["flake"], False)

    def test_hosts_receive_skill_repositories(self):
        for host in ("gaia",):
            with self.subTest(host=host):
                self.assertRegex(
                    (ROOT / f"hosts/{host}/default.nix").read_text(),
                    r"extraSpecialArgs = \{[^}]*skillRepos",
                )
