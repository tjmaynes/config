"""Portable Home Manager behavior evaluated on the supported host."""

import unittest

from tests.support import HOSTS, PACKAGE_NAMES, PACKAGE_PNAMES, USER, eval_json


class CommonHomeTests(unittest.TestCase):
    def test_syncthing_preserves_web_managed_devices_and_folders(self):
        for host, config in HOSTS.items():
            service = f"{config}.{USER}.services.syncthing"
            for option, expected in {
                "enable": True,
                "guiAddress": "127.0.0.1:8384",
                "overrideDevices": False,
                "overrideFolders": False,
            }.items():
                with self.subTest(host=host, option=option):
                    self.assertEqual(eval_json(f"{service}.{option}"), expected)

    def test_editors_and_platform_ghostty_packages(self):
        for host, config in HOSTS.items():
            home = f"{config}.{USER}"
            with self.subTest(host=host):
                self.assertIs(eval_json(f"{home}.programs.emacs.enable"), True)
                self.assertIs(eval_json(f"{home}.programs.ghostty.enable"), True)
                self.assertEqual(
                    eval_json(f"{home}.programs.ghostty.package.pname"),
                    "ghostty-bin",
                )

    def test_delta_navigation_and_git_integration(self):
        for host, config in HOSTS.items():
            home = f"{config}.{USER}"
            for option in ("navigate", "side-by-side", "line-numbers"):
                with self.subTest(host=host, option=option):
                    self.assertIs(
                        eval_json(f"{home}.programs.delta.options.{option}"), True
                    )
            with self.subTest(host=host):
                git = eval_json(f"{home}.programs.git.iniContent")
                self.assertEqual(git["merge"]["conflictStyle"], "zdiff3")
                self.assertIn("delta --color-only", git["interactive"]["diffFilter"])
                self.assertIn("delta", git["pager"]["diff"])
                self.assertNotIn("diff", git)

    def test_oh_my_zsh_plugins(self):
        for host, config in HOSTS.items():
            with self.subTest(host=host):
                self.assertEqual(
                    eval_json(f"{config}.{USER}.programs.zsh.oh-my-zsh.plugins"),
                    ["git", "kubectl", "macos"],
                )

    def test_gpg_agent_supports_ssh(self):
        for host, config in HOSTS.items():
            for option in ("enable", "enableSshSupport"):
                with self.subTest(host=host, option=option):
                    self.assertIs(
                        eval_json(f"{config}.{USER}.services.gpg-agent.{option}"), True
                    )

    def test_shared_application_and_mail_packages(self):
        for host, config in HOSTS.items():
            attribute = f"{config}.{USER}.home.packages"
            packages = eval_json(attribute, apply=PACKAGE_PNAMES)
            for package in (
                "vscode",
                "offlineimap",
                "mutt",
                "notmuch",
                "password-store",
            ):
                with self.subTest(host=host, package=package):
                    self.assertIn(package, packages)
            with self.subTest(host=host, package="sync-icloud-mail"):
                self.assertIn(
                    "sync-icloud-mail", eval_json(attribute, apply=PACKAGE_NAMES)
                )


class ReadOnlyMailTests(unittest.TestCase):
    def test_notmuch_indexes_local_mail_without_syncing_flags(self):
        for host, config in HOSTS.items():
            with self.subTest(host=host):
                text = eval_json(f'{config}.{USER}.home.file.".notmuch-config".text')
                for line in (
                    "path=/Users/tjmaynes/workspace/mailbox",
                    "primary_email=tj@tjmaynes.com",
                    "synchronize_flags=false",
                ):
                    self.assertIn(line, text.splitlines())

    def test_emacs_includes_notmuch_interface(self):
        for host, config in HOSTS.items():
            with self.subTest(host=host):
                packages = eval_json(
                    f"{config}.{USER}.programs.emacs.finalPackage",
                    apply='package: map (p: p.pname or "") package.explicitRequires',
                )
                self.assertIn("notmuch", packages)

    def test_offlineimap_is_manual_read_only_and_uses_password_lookup(self):
        for host, config in HOSTS.items():
            mailbox = "/Users/tjmaynes/workspace/mailbox"
            with self.subTest(host=host):
                text = eval_json(
                    f'{config}.{USER}.home.file.".config/offlineimap/config".text'
                )
                lines = text.splitlines()
                for line in (
                    f"localfolders = {mailbox}",
                    "remoteuser = tjmaynes",
                    "readonly = true",
                    "remotepasseval = get_password()",
                ):
                    with self.subTest(host=host, line=line):
                        self.assertIn(line, lines)
                self.assertRegex(
                    text,
                    r"(?m)^sslcacertfile = /nix/store/.*/etc/ssl/certs/ca-bundle.crt$",
                )
                self.assertNotRegex(text, r"(?m)^remotepass =")
                self.assertNotRegex(text, r"(?m)^autorefresh =")

    def test_mutt_uses_local_mail_and_disables_sending(self):
        for host, config in HOSTS.items():
            home_directory = "/Users/tjmaynes"
            mailbox = f"{home_directory}/workspace/mailbox"
            with self.subTest(host=host):
                text = eval_json(f'{config}.{USER}.home.file.".mutt/muttrc".text')
                for line in (
                    f'set folder = "{mailbox}"',
                    f'set spoolfile = "{mailbox}/INBOX"',
                    "set read_only = yes",
                    'set sendmail = "/usr/bin/false"',
                    f'source "{home_directory}/.mutt/dracula.muttrc"',
                ):
                    with self.subTest(host=host, line=line):
                        self.assertIn(line, text.splitlines())
                self.assertNotIn("smtp_url", text)

    def test_dracula_theme_has_valid_email_and_emphasis_rules(self):
        for host, config in HOSTS.items():
            with self.subTest(host=host):
                theme = eval_json(
                    f'{config}.{USER}.home.file.".mutt/dracula.muttrc".text'
                )
                self.assertRegex(theme, r"(?m)^color\s+status\s+color141\s+color236$")
                self.assertIn(
                    r"color body color231 default [\-\.+_a-zA-Z0-9]+@[\-\.a-zA-Z0-9]+",
                    theme.splitlines(),
                )
                self.assertIn(
                    "color body color231 default (^|[[:space:]])[*][^[:space:]]+[*]([[:space:]]|$)",
                    theme.splitlines(),
                )
                self.assertNotIn(r"\*[^[:space:]]+\*", theme)
