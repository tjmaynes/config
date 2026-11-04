# AGENTS.md

This guide applies to the Nix configurations, tests, automation, and
documentation in this repository.

The working tree may contain user-owned changes. Inspect `git status` before
editing, preserve unrelated work, and never discard or rewrite changes merely
to make a task easier.

## Quick facts

- The repository uses Nix flakes, nix-darwin, and Home Manager.
- `gaia` is an Apple Silicon macOS workstation managed by nix-darwin.
- `athena` is a headless `x86_64-linux` NixOS development server (MS-A2).
  Its hardware module is an installation template until replaced on the machine.
- Gaia uses `aarch64-darwin`; `x86_64-linux` remains supported for development
  tooling. CI runs on macOS.
- The Makefile is the canonical interface for formatting, linting, testing,
  evaluating, building, updating, and explicitly approved activation work.

## Repository tour

- `flake.nix` declares inputs, identities, host outputs, formatters, and the
  development shell.
- `hosts/<host>/` composes modules and contains host-specific identity,
  platform, and hardware configuration.
- `modules/common/` contains portable workstation and Home Manager
  configuration used by Gaia.
- `modules/darwin/` contains macOS-only system, Homebrew,
  preference, and Home Manager configuration.
- `modules/nixos/` contains Athena's NixOS system services and headless home
  composition. Portable development configuration stays in `modules/common/`.
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

`make eval` evaluates Gaia and Athena; `make build` still builds Gaia.
Use `make build-athena` on Linux or with a configured Linux builder.
Athena's code-server is proxied by the separate home-server Caddy configuration
at `https://coding.bewoogie.local`. Its runtime password file and Codex login
must stay outside Nix. Codex runs as a system service under `tjmaynes` at boot
and listens on a private Unix socket; do not expose it directly to the network.
Athena's Tailscale enrollment uses sops-nix when `secrets/athena.sops.yaml` is
provisioned. Only encrypted ciphertext belongs in `secrets/`; follow its
README for recipients and host-key provisioning. Missing ciphertext leaves
automatic enrollment disabled with an explicit evaluation warning.

Use `make test-unit`, `make test-smoke`, or `make test-integration` for focused
checks. Tests use the standard library; Python and Ruff are provided by the Nix
development shell. Unit tests do not invoke Nix.

Activation is not normal validation. Run `make bootstrap` or `make
deploy` only when the user explicitly requests activation and has accepted
the host-level impact.

## Working rules

Before designing an app or service integration, check Home Manager's existing
modules and options in both the pinned version and current upstream source and
documentation. Prefer upstream support over custom wrappers, activation scripts,
configuration mergers, or services. If support requires a newer version, explain
the dependency update and compatibility tradeoffs before choosing an approach.
Create custom integration code only after identifying and documenting a gap in
upstream support.

Keep portable workstation packages and user configuration in `modules/common/`;
put macOS-specific behavior in the Darwin
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

When adding a repository-managed Codex skill, update the Codex skills table in
`README.md` with its purpose, usage, and source repository URL.
