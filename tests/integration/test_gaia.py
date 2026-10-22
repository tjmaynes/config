"""Gaia contracts remain evaluation-only so they can run on Linux."""

import unittest

from tests.support import HOSTS, PACKAGE_PNAMES, USER, eval_json, eval_raw

CONFIG = HOSTS["gaia"]
HOME = f"{CONFIG}.{USER}"


class GaiaTests(unittest.TestCase):
    def test_atuin_uses_homebrew_without_a_conflicting_nix_package(self):
        brews = eval_json(f"{CONFIG}.homebrew.brews")
        self.assertIn("atuin", [brew["name"] for brew in brews])
        self.assertIs(eval_json(f"{HOME}.programs.atuin.enable"), False)
        self.assertNotIn(
            "atuin", eval_json(f"{HOME}.home.packages", apply=PACKAGE_PNAMES)
        )
        self.assertIn(
            'eval "$(/opt/homebrew/bin/atuin init zsh)"',
            eval_json(f"{HOME}.programs.zsh.initContent"),
        )

    def test_syncthing_runs_as_a_background_launch_agent(self):
        agent = f"{HOME}.launchd.agents.syncthing"
        self.assertIs(eval_json(f"{agent}.enable"), True)
        config = eval_json(f"{agent}.config")
        self.assertEqual(config["Label"], "org.nix-community.home.syncthing")
        self.assertEqual(config["ProcessType"], "Background")
        self.assertIs(config["KeepAlive"]["Crashed"], True)
        # SuccessfulExit implies RunAtLoad in launchd, including when false.
        self.assertIs(config["KeepAlive"]["SuccessfulExit"], False)

    def test_syncthing_log_directory_exists_before_agent_setup(self):
        activation = eval_json(f"{HOME}.home.activation.ensureSyncthingLogDirectory")
        self.assertIn("writeBoundary", activation["after"])
        self.assertIn("setupLaunchAgents", activation["before"])
        self.assertIn(
            'run mkdir -p -- "/Users/tjmaynes/Library/Logs/Syncthing"',
            activation["data"],
        )

    def test_host_identity_and_state_version(self):
        self.assertEqual(eval_json(f"{CONFIG}.networking.hostName"), "gaia")
        self.assertEqual(eval_json(f"{CONFIG}.system.stateVersion"), 4)

    def test_emacs_runs_without_a_background_service(self):
        self.assertIs(eval_json(f"{HOME}.programs.emacs.enable"), True)
        self.assertIs(eval_json(f"{HOME}.services.emacs.enable"), False)

    def test_application_bundles_are_copied(self):
        self.assertIs(eval_json(f"{HOME}.targets.darwin.copyApps.enable"), True)
        self.assertIs(eval_json(f"{HOME}.targets.darwin.linkApps.enable"), False)

    def test_screenshot_directory_is_created_on_activation(self):
        self.assertEqual(
            eval_json(f"{CONFIG}.system.defaults.screencapture.location"),
            "/Users/tjmaynes/workspace/screencaptures",
        )
        self.assertIn(
            'run mkdir -p -- "/Users/tjmaynes/workspace/screencaptures"',
            eval_raw(f"{HOME}.home.activation.ensureScreencaptureDirectory.data"),
        )

    def test_appearance_and_keyboard_preferences(self):
        for option, expected in {
            "AppleInterfaceStyle": "Dark",
            "AppleInterfaceStyleSwitchesAutomatically": False,
            "AppleKeyboardUIMode": 2,
        }.items():
            with self.subTest(option=option):
                self.assertEqual(
                    eval_json(f"{CONFIG}.system.defaults.NSGlobalDomain.{option}"),
                    expected,
                )

    def test_gui_applications_are_system_packages(self):
        packages = eval_json(
            f"{CONFIG}.environment.systemPackages", apply=PACKAGE_PNAMES
        )
        for package in (
            "ghostty-bin",
            "obsidian",
            "bitwarden-desktop",
        ):
            with self.subTest(package=package):
                self.assertIn(package, packages)
        self.assertNotIn("google-chrome", packages)

    def test_homebrew_casks(self):
        casks = eval_json(f"{CONFIG}.homebrew.casks")
        self.assertEqual(
            [cask["name"] for cask in casks],
            [
                "chatgpt",
                "docker-desktop",
                "signal",
                "vcv-rack",
                "tailscale-app",
                "obs",
                "spotify",
                "virtualbox",
                "imageoptim",
                "zen",
            ],
        )

    def test_font_packages(self):
        self.assertEqual(
            eval_json(f"{CONFIG}.fonts.packages", apply=PACKAGE_PNAMES),
            [
                "nerd-fonts-iosevka",
                "nerd-fonts-inconsolata",
                "nerd-fonts-blex-mono",
                "linux-libertine",
                "libre-baskerville",
            ],
        )

    def test_system_derivation_evaluates_without_building(self):
        self.assertTrue(
            eval_raw(f"{CONFIG}.system.build.toplevel.drvPath").endswith(".drv")
        )
