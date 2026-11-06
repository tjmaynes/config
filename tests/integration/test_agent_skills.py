"""Real Nix fixture behavior and Home Manager skill source wiring."""

import json
import unittest

from tests.support import DEVELOPMENT_HOSTS, ROOT, USER, eval_json, run_nix


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
            "discovers-root-skill",
            "rejects-invalid-root-skill",
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
            ("last30days-skill", "skills", ("last30days",)),
            ("archify", ".", ("archify",)),
        ):
            source = run_nix(
                "eval",
                "--impure",
                "--raw",
                "--expr",
                f"(builtins.getFlake {json.dumps(str(ROOT))}).inputs.{repository}.outPath",
            )
            for host, config in DEVELOPMENT_HOSTS.items():
                for skill in skills:
                    with self.subTest(host=host, repository=repository, skill=skill):
                        self.assertEqual(
                            eval_json(
                                f'{config}.{USER}.home.file.".agents/skills/{skill}".source'
                            ),
                            f"{source}/{subdir}/{skill}",
                        )

    def test_hosts_link_root_skill_from_locked_source(self):
        source = run_nix(
            "eval",
            "--impure",
            "--raw",
            "--expr",
            f"(builtins.getFlake {json.dumps(str(ROOT))}).inputs.humanizer.outPath",
        )
        for host, config in DEVELOPMENT_HOSTS.items():
            with self.subTest(host=host):
                self.assertEqual(
                    eval_json(
                        f'{config}.{USER}.home.file.".agents/skills/humanizer".source'
                    ),
                    source,
                )

    def test_managed_skills_report_changes_during_activation(self):
        for host, config in DEVELOPMENT_HOSTS.items():
            for skill in ("brainstorming", "humanizer"):
                with self.subTest(host=host, skill=skill):
                    hook = eval_json(
                        f'{config}.{USER}.home.file.".agents/skills/{skill}".onChange'
                    )
                    self.assertIn(f"Installed or updated agent skill: {skill}", hook)
