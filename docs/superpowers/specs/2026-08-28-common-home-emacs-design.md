# Common Home Manager Emacs Support Design

**Status:** Approved for implementation
**Date:** 2026-08-28

## Summary

Add portable Emacs, shell, tmux, Vim, and mise support to
`modules/common/home` by reconciling the useful, non-secret behavior from
`tmp/dotfiles` into native Home Manager modules. Prezto, Stow, and the legacy
dotfile deployment model remain excluded.

## Scope

Create or update focused modules under `modules/common/home` and import them
from the common Home Manager module. Enable Emacs for both Gaia and Athena
through the shared module, install Emacs and portable editor support
declaratively, and generate an `init.el` with portable editing, coding-mode,
theme, shell, and development settings. Reconcile shell aliases,
the `kill-process-on-port` function, tmux, Vim, and the six retained mise
entries (`direnv`, `python`, `node`, `kubectl`, `just`, and `go`).

Do not migrate M4A conversion, morning papers, staged auto-commit, commit
summaries, repository backups, IRC/chat credentials, passwords, room/server
configuration, `~/.emacs.json`, private files, or runtime package
installation. Omit `mu4e`, `w3m`, and `gptel`/Ollama configuration with chat
and email integrations. These remain external or deferred. Do not reintroduce
Prezto, Stow, `.zpreztorc`, or external dotfile paths.

## Migration mapping

- General utility helpers become local Emacs Lisp functions where useful.
- Emacs backup/autosave customization is intentionally not migrated.
- JSON, YAML, Markdown, and web editing use declarative Nix packages.
- Portable Org and development settings are retained without private paths.
- Zsh integration avoids hard-coded `/usr/local/bin` assumptions.
- Theme and GUI defaults retain safe terminal/GUI fallbacks.
- Chat setup is intentionally omitted.

## Emacs package and daemon policy

The common Emacs module owns `programs.emacs.enable` and installs its declared
packages through Home Manager’s `programs.emacs.extraPackages`. The initial
portable package set is `magit`, `json-mode`, `yaml-mode`, `markdown-mode`,
`web-mode`, `paredit`, `dockerfile-mode`, `k8s-mode`, `multi-term`,
`auto-complete`, `org`, `org-journal`, `circadian`, `solarized-theme`, and
`zenburn-theme`. `org` is deliberately listed even where bundled with Emacs,
so the package closure is explicit and evaluated on both target systems.
Every function referenced by generated Lisp must come from Emacs itself or
this declared package set, and the full set must evaluate on both systems.

NixOS retains `services.emacs.enable` for its existing daemon behavior;
Gaia does not enable an Emacs daemon. The shared module owns only portable
user configuration.

## Portability and generated files

Home Manager writes the configuration to
`~/.emacs.d/init.el` through `programs.emacs.extraConfig`. It does not create,
load, or inspect `.custom.el`, `~/.emacs.json`, credentials, private paths, or
external dotfiles. Zsh and PATH integration must use Home Manager/Nix-derived
values or runtime environment discovery, never hard-coded `/usr/local/bin`.
Optional tools unavailable on a host must not make evaluation fail; related
features are omitted or guarded. Theme and GUI settings must have terminal-safe
fallbacks.

## Shell/editor migration

Retain only the portable aliases `workspace`, `dotfiles`, and `tm`, plus
`kill-process-on-port`. Its implementation must be BSD-compatible on Gaia:
guard the `lsof` result before invoking `kill` and do not use GNU-only
`xargs -r`. Reconcile the existing native tmux and Vim modules with
the source bindings and editor defaults, without restoring plugin-manager shell
commands or imperative file creation. Mise versions are represented in the
existing declarative `globalConfig.tools` map with `nodejs` normalized to the
module’s `node` key. Bun is intentionally removed from the managed toolset.

## Verification

The implementation must keep existing formatting, lint, and shell checks green.
Host contract tests must assert that the common Home Manager configuration
enables Emacs and the migrated portable tools on both outputs. Tests must
inspect generated configuration/package closure text for forbidden strings:
`.emacs.json`, passwords, chat server/room settings, private paths,
`package-install`, `package-refresh-contents`, and external dotfile references.
Both host outputs and all declared packages must evaluate cross-system without
activation or machine access. CI and local checks must not activate systems.
