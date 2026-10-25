"""Source-level contracts for shared user tools and editor configuration."""

import unittest

from tests.support import ROOT

HOME = ROOT / "modules/workstation/common/home"


class SharedSourceTests(unittest.TestCase):
    def test_codex_uses_unstable_packages(self):
        self.assertIn(
            'nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";',
            (ROOT / "flake.nix").read_text(),
        )
        self.assertIn("pkgsUnstable.codex", (HOME / "packages.nix").read_text())

    def test_emacs_configures_portable_note_taking(self):
        source = (HOME / "emacs.nix").read_text()
        for text in (
            ':family "Inconsolata Nerd Font Mono"',
            "workspace/code/tjmaynes/notebook",
            "org-capture-templates",
            '"inbox.org"',
            '"tasks.org"',
            'ispell-program-name "aspell"',
            "(load-theme 'zenburn t)",
        ):
            with self.subTest(text=text):
                self.assertIn(text, source)
        self.assertRegex((HOME / "packages.nix").read_text(), r"(?m)^\s+aspell$")
        self.assertNotRegex(
            source,
            r"\.emacs\.json|package-install|package-refresh-contents|chat server|"
            r"password|<home-manager|config/dotfiles",
        )

    def test_shared_cli_packages_include_github_and_vagrant(self):
        source = (HOME / "packages.nix").read_text()
        for package in ("gh", "vagrant"):
            with self.subTest(package=package):
                self.assertRegex(source, rf"(?m)^\s+{package}$")

    def test_shell_helpers(self):
        source = (HOME / "zsh.nix").read_text()
        self.assertIn('workspace = "cd $WORKSPACE_DIRECTORY"', source)
        self.assertIn("kill-process-on-port()", source)
        self.assertNotIn("convert-m4a-to-mp3", source)

    def test_tmux_navigation(self):
        source = (HOME / "tmux.nix").read_text()
        for text in (
            'prefix = "C-g"',
            "bind m set-window-option main-pane-height",
            "set -g base-index 1",
        ):
            with self.subTest(text=text):
                self.assertIn(text, source)

    def test_mise_tool_versions(self):
        source = (HOME / "mise.nix").read_text()
        for tool, version in {
            "python": "3.14.7",
            "node": "24.20.0",
            "kubectl": "1.37.0",
            "go": "1.27.0",
        }.items():
            with self.subTest(tool=tool):
                self.assertIn(f'{tool} = "{version}"', source)
        self.assertNotIn("bun", source)

    def test_vim_plugins_and_editing_options(self):
        source = (HOME / "vim.nix").read_text()
        for plugin in (
            "nerdtree",
            "ctrlp-vim",
            "vim-fugitive",
            "vim-commentary",
            "vim-surround",
            "vim-gnupg",
            "editorconfig-vim",
            "vim-markdown",
            "goyo-vim",
            "vim-pencil",
        ):
            with self.subTest(plugin=plugin):
                self.assertRegex(source, rf"(?m)^\s+{plugin}$")
        for text in (
            "set autochdir",
            "plugins = with pkgs.vimPlugins",
            "set synmaxcol=300",
            "NERDTreeShowHidden",
            "pencil#init",
            "PyJSONPretty",
        ):
            with self.subTest(text=text):
                self.assertIn(text, source)
