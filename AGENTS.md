# AGENTS.md

This guide applies to the Nix configurations, tests, automation, and
documentation in this repository.

The working tree may contain user-owned changes. Inspect `git status` before
editing, preserve unrelated work, and never discard or rewrite changes merely
to make a task easier.

## Quick facts

- The repository uses Nix flakes, nix-darwin, and Home Manager.
- `gaia` is an Apple Silicon macOS workstation managed by nix-darwin.
- Gaia uses `aarch64-darwin`; `x86_64-linux` remains supported for development
  tooling. CI runs on macOS.
- The Makefile is the canonical interface for formatting, linting, testing,
  evaluating, building, updating, and explicitly approved activation work.

## Repository tour

- `flake.nix` declares inputs, identities, host outputs, formatters, and the
  development shell.
- `hosts/<host>/` composes modules and contains host-specific identity,
  platform, and hardware configuration.
- `modules/workstation/common/` contains portable workstation and Home Manager
  configuration used by Gaia.
- `modules/workstation/darwin/` contains macOS-only system, Homebrew,
  preference, and Home Manager configuration.
- `tests/` contains Python `unittest` checks, organized into file-only `unit/`,
  flake `smoke/`, and real Nix evaluation `integration/` suites. Shared process
  helpers live in `tests/support.py`; Nix fixture expressions and data live in
  `tests/fixtures/`. Python tooling is configured in `tests/pyproject.toml` and
  `tests/.mise.toml`.

## Commands

Run commands from the repository root:

```sh
make format-check
make lint
make test
make check
make eval
```

Use `make test-unit`, `make test-smoke`, or `make test-integration` for focused
checks. Tests use the standard library; Python and Ruff are provided by the Nix
development shell. Unit tests do not invoke Nix.

Activation is not normal validation. Run `make bootstrap` or `make
switch` only when the user explicitly requests activation and has accepted
the host-level impact.

## Working rules

Keep portable workstation packages and user configuration in
`modules/workstation/common/`; put macOS-specific behavior in the Darwin
subtree; keep host modules focused on composition and host facts. Do not put
credentials, private keys, tokens, production environment files, or machine
secrets in the repository or Nix store.

Format Nix with the flake-provided `nixfmt` and Python with Ruff. Write named
`unittest.TestCase` methods and use subtests to identify repeated host or fixture
failures. Keep Nix subprocess calls in the shared helper and never silently
skip failed evaluations. Run focused checks while iterating. Before handoff,
inspect the scoped diff, run `make format-check`, `make lint`, `make test`, and the relevant host
evaluations. Update this README and tests whenever supported hosts or commands
change.
