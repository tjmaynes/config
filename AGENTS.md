# AGENTS.md

This guide applies to the Nix configurations, tests, automation, and
documentation in this repository.

The working tree may contain user-owned changes. Inspect `git status` before
editing, preserve unrelated work, and never discard or rewrite changes merely
to make a task easier.

## Quick facts

- The repository uses Nix flakes, nix-darwin, NixOS, and Home Manager.
- `gaia` is an Apple Silicon macOS workstation managed by nix-darwin.
- `athena` is an x86_64 NixOS workstation. Its checked-in hardware module is
  evaluation-only and must be replaced before activation.
- The supported flake systems are `aarch64-darwin` and `x86_64-linux`.
- The Makefile is the canonical interface for formatting, linting, testing,
  evaluating, building, updating, and explicitly approved activation work.

## Repository tour

- `flake.nix` declares inputs, identities, host outputs, formatters, and the
  development shell.
- `hosts/<host>/` composes modules and contains host-specific identity,
  platform, and hardware configuration.
- `modules/workstation/common/` contains portable workstation and Home Manager
  configuration shared by Gaia and Athena.
- `modules/workstation/darwin/` contains macOS-only system, Homebrew,
  preference, and Home Manager configuration.
- `modules/workstation/nixos/` contains NixOS workstation system, desktop,
  service, and Home Manager configuration.
- `tests/` contains POSIX shell contract tests for flake bootstrap, shared
  configuration, individual hosts, repository hygiene, and documentation.

## Commands

Run commands from the repository root:

```sh
make format-check
make lint
make test
make check
make eval-gaia
make eval-athena
```

Activation is not normal validation. Run `make bootstrap-gaia` or `make
switch-gaia` only when the user explicitly requests activation and has accepted
the host-level impact. `make switch-athena` intentionally refuses while the
evaluation-only hardware module is present.

## Working rules

Keep portable workstation packages and user configuration in
`modules/workstation/common/`; put OS-specific behavior in the Darwin or NixOS
subtree; keep host modules focused on composition and host facts. Do not put
credentials, private keys, tokens, production environment files, or machine
secrets in the repository or Nix store.

Format Nix with the flake-provided `nixfmt`, keep shell tests POSIX-compatible,
and run focused checks while iterating. Before handoff, inspect the scoped diff,
run `make format-check`, `make lint`, `make test`, and the relevant host
evaluations. Update this README and tests whenever supported hosts or commands
change.
