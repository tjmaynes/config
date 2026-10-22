"""Protect error reporting at the Python/Nix process boundary."""

import subprocess
import unittest
from unittest.mock import patch

from tests import support


class NixSupportTests(unittest.TestCase):
    def tearDown(self):
        support.eval_json.cache_clear()
        support.eval_raw.cache_clear()

    @patch("tests.support.subprocess.run")
    def test_json_values_are_decoded_and_evaluated_once(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, '[true, "gaia", 4]', "")
        self.assertEqual(support.eval_json(".#example"), [True, "gaia", 4])
        self.assertEqual(support.eval_json(".#example"), [True, "gaia", 4])
        run.assert_called_once_with(
            [
                "nix",
                "--extra-experimental-features",
                "nix-command flakes",
                "eval",
                "--json",
                ".#example",
            ],
            cwd=support.ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

    @patch("tests.support.subprocess.run")
    def test_failed_command_reports_arguments_status_and_both_streams(self, run):
        run.return_value = subprocess.CompletedProcess(
            [], 7, "partial output", "bad option"
        )
        with self.assertRaises(AssertionError) as failure:
            support.run_nix("eval", "--json", ".#broken")
        message = str(failure.exception)
        for expected in ("nix", ".#broken", "7", "partial output", "bad option"):
            with self.subTest(expected=expected):
                self.assertIn(expected, message)

    @patch("tests.support.subprocess.run")
    def test_failed_evaluation_is_not_cached(self, run):
        run.side_effect = [
            subprocess.CompletedProcess([], 1, "", "temporary failure"),
            subprocess.CompletedProcess([], 0, "true", ""),
        ]
        with self.assertRaises(AssertionError):
            support.eval_json(".#retry")
        self.assertIs(support.eval_json(".#retry"), True)

    @patch("tests.support.subprocess.run")
    def test_invalid_json_names_attribute_and_output(self, run):
        run.return_value = subprocess.CompletedProcess([], 0, "not JSON", "")
        with self.assertRaises(AssertionError) as failure:
            support.eval_json(".#invalid")
        self.assertIn(".#invalid", str(failure.exception))
        self.assertIn("not JSON", str(failure.exception))

    @patch("tests.support.subprocess.run", side_effect=FileNotFoundError("nix missing"))
    def test_missing_nix_has_actionable_failure(self, run):
        with self.assertRaisesRegex(AssertionError, "nix.*Nix"):
            support.run_nix("flake", "metadata")
