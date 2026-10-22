"""Real Nix fixture behavior and Home Manager skill source wiring."""

import json
import unittest

from tests.support import HOSTS, ROOT, USER, eval_json, run_nix


class AgentSkillsTests(unittest.TestCase):
    def test_skill_discovery_filters_and_rejects_invalid_repositories(self):
        checks = json.loads(
            run_nix(
                "eval",
                "--impure",
                "--json",
                "--file",
                "tests/fixtures/agent-skills.nix",
            )
        )
        expected = {
            "discovers-valid-skills",
            "filters-included-skills",
            "rejects-duplicate-repositories",
            "rejects-duplicate-targets",
            "rejects-missing-subdirectory",
            "rejects-duplicate-includes",
            "rejects-unknown-includes",
            "rejects-structurally-invalid-includes",
        }
        self.assertEqual(set(checks), expected)
        for name, passed in checks.items():
            with self.subTest(contract=name):
                self.assertIs(passed, True)

    def test_hosts_link_skills_from_locked_sources(self):
        for repository, subdir, skills in (
            ("superpowers", "skills", ("brainstorming",)),
            ("tjmaynes-skills", "skills", ("agent-context-generator",)),
            ("mattpocock-skills", "skills/productivity", ("grill-me", "grilling")),
            ("addyosmani-agent-skills", "skills", ("interview-me",)),
        ):
            source = run_nix(
                "eval",
                "--impure",
                "--raw",
                "--expr",
                f"(builtins.getFlake {json.dumps(str(ROOT))}).inputs.{repository}.outPath",
            )
            for host, config in HOSTS.items():
                for skill in skills:
                    with self.subTest(host=host, repository=repository, skill=skill):
                        self.assertEqual(
                            eval_json(
                                f'{config}.{USER}.home.file.".agents/skills/{skill}".source'
                            ),
                            f"{source}/{subdir}/{skill}",
                        )
