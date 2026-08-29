# AGENTS.md

This guide applies to the entire repository. It is the operating contract for
agents working on the Nix configurations, tests, automation, and documentation
in this project.

The working tree may contain user-owned changes. Inspect `git status` before
editing, preserve unrelated work, and never discard or rewrite changes merely
to make a task easier.

## Quick Facts

- The repository uses Nix flakes, nix-darwin, NixOS, and Home Manager.
- `gaia` is an Apple Silicon macOS workstation managed by nix-darwin.
- `athena` is an x86_64 NixOS workstation. Its checked-in hardware module is
  evaluation-only and must be replaced before activation.
- `atlas` is an x86_64 NixOS server configuration under active development. It
  is evaluation-only until its physical hardware, networking, storage, access,
  and deployment policy have been inventoried and reviewed.
- The supported flake systems are `aarch64-darwin` and `x86_64-linux`.
- The `Makefile` is the canonical interface for formatting, linting, testing,
  evaluating, building, updating, and explicitly approved activation work.
- Configuration and tests are the current source of truth. Files under
  `docs/superpowers/specs/` and `plans/` record design intent and implementation
  history; confirm their status against the working tree before following them.

## Repository Tour

- `flake.nix` declares inputs, identities, host outputs, formatters, and the
  development shell. Keep host wiring and cross-system declarations here.
- `flake.lock` pins all flake inputs. Change it only as part of a deliberate
  input update.
- `hosts/<host>/` composes modules and contains host-specific identity,
  platform, and hardware configuration.
- `modules/workstation/common/` contains portable workstation and Home Manager
  configuration shared by Gaia and Athena.
- `modules/workstation/darwin/` contains macOS-only system, Homebrew, preference,
  and Home Manager configuration.
- `modules/workstation/nixos/` contains NixOS workstation system, desktop,
  service, and Home Manager configuration.
- `modules/server/` is the in-progress boundary for Atlas host-foundation
  modules. Some focused modules may exist before the composition root imports
  them. Keep application containers, application secrets, and operational
  deployment in the existing Ansible/Compose layer rather than duplicating
  them in Nix.
- `tests/` contains POSIX shell contract tests for flake bootstrap, shared
  configuration, individual hosts, repository hygiene, and documentation.
- `.github/workflows/check.yml` defines Linux and Darwin CI validation.
- `docs/superpowers/specs/` contains approved or proposed design records.
- `plans/` contains phased implementation plans; status fields and checkboxes
  may lag behind code, so do not treat a plan as proof of completion.

## Tooling and Setup

Required local tools are GNU Make, Git, and upstream Nix 2.35 or newer. Flake
commands must enable `nix-command` and `flakes`; the Makefile already supplies
those flags.

Inspect the flake and enter its development environment with:

```sh
nix --extra-experimental-features 'nix-command flakes' flake metadata
nix --extra-experimental-features 'nix-command flakes' develop
```

The development shell supplies `actionlint`, `deadnix`, `jq`, `nixfmt`,
`ripgrep`, `shellcheck`, and `statix`. Prefer repository-provided tools and Make
targets over globally installed alternatives.

Do not rely on `NIX_PATH`, `builtins.getEnv`, external dotfile paths, or other
impure machine state. Never put credentials, private keys, tokens, production
environment files, or machine secrets in the repository or the Nix store.

## Common Tasks

Run these commands from the repository root:

| Task | Command | Notes |
| --- | --- | --- |
| Format Nix files | `make fmt` | Applies the flake formatter. |
| Check formatting | `make format-check` | Does not modify files. |
| Run static analysis | `make lint` | Runs statix, deadnix, shellcheck, and actionlint. |
| Run contract tests | `make test` | Exercises bootstrap, hosts, hygiene, and docs. |
| Run the main local gate | `make check` | Formatting, lint, tests, Gaia evaluation, and Athena evaluation. |
| Evaluate Gaia | `make eval-gaia` | Evaluation only; no activation. |
| Evaluate Athena | `make eval-athena` | Evaluation only; no activation. |
| Evaluate Atlas | `make eval-atlas` | Required for Atlas changes while it remains outside `make check`. |
| Build Gaia | `make build-gaia` | Builds without switching generations. |
| Build Athena | `make build-athena` | Builds without switching generations. |
| Update inputs | `make update` | Review all resulting `flake.lock` changes. |

For a focused test during development, run it inside the development shell:

```sh
nix --extra-experimental-features 'nix-command flakes' develop --command sh tests/atlas.sh
```

Replace `atlas.sh` with the contract test relevant to the change.

Activation is not a normal validation step. Run `make bootstrap-gaia` or
`make switch-gaia` only when the user explicitly requests activation and has
accepted the host-level impact. `make switch-athena` intentionally refuses
while the evaluation-only hardware module is present. Atlas has no approved
activation target.

## Testing and Quality

- Add or update a focused contract test when changing an evaluated host or
  shared configuration invariant.
- Keep tests deterministic, evaluation-oriented, and safe to run in CI. Tests
  must not activate systems, mutate Homebrew, format disks, contact production
  services, or require secrets.
- Shell tests use POSIX `sh`, begin with `set -eu`, and must pass `shellcheck`.
- Format Nix with the flake-provided `nixfmt`; do not hand-format around it.
- Run the smallest relevant test while iterating, then run `make check` before
  handoff. For Atlas work, also run `make eval-atlas` until it is incorporated
  into the main `check` target.
- When changing platform-specific build behavior, run the corresponding build
  on that platform when available. CI builds Gaia on Darwin and evaluates NixOS
  on Linux.
- If a required check cannot run in the current environment, report exactly
  which check was skipped and why. Do not claim an unrun check passed.

## Workflow Expectations

1. Read `README.md`, inspect `git status`, and identify the affected host and
   module boundary before editing.
2. Preserve existing user changes and keep the patch scoped to the request.
3. Put portable workstation packages and user configuration in
   `modules/workstation/common/`; put OS-specific behavior in the Darwin or
   NixOS subtree; keep host modules focused on composition and host facts.
4. Keep Atlas separate from workstation Home Manager configuration unless a
   later approved design explicitly changes that boundary.
5. Represent unknown physical details as inert, documented placeholders. Never
   invent disk identifiers, filesystem layouts, NIC names, gateways, SSH keys,
   GPU paths, serial devices, or routable addresses.
6. Prefer evaluation and `--no-link` builds over activation. Never deploy,
   switch a generation, reboot, format storage, enroll a service, or expose a
   port without explicit authorization.
7. Update tests and documentation in the same change when behavior, commands,
   host support, prerequisites, or safety constraints change.
8. Review the complete diff for unintended lock-file churn, generated outputs,
   secrets, private paths, and unrelated formatting before handoff.

When a design spec conflicts with evaluated code, tests, or a newer approved
decision, surface the conflict instead of silently choosing one. Plans should
be updated when implementing them, but historical design records should remain
useful explanations of why a boundary exists.

## Documentation Duties

Update `README.md` when a change affects:

- supported hosts or their readiness for build or activation;
- bootstrap, update, check, build, activation, or rollback commands;
- tool or Nix version requirements;
- secret handling, hardware prerequisites, or other safety constraints;
- Homebrew or mise behavior visible to repository users.

Keep examples copy-pasteable from the repository root. Describe evaluation,
build, activation, and deployment as distinct operations. Do not document an
unsafe placeholder as production-ready.

Use specs for durable architectural decisions and plans for multi-phase
execution. Keep status metadata honest, and do not create a new plan for a
small, obvious maintenance change unless requested.

## Finish-Task Checklist

Before handing work back:

- [ ] Inspect `git status --short` and the complete scoped diff.
- [ ] Run the focused test or evaluation for the changed host or module.
- [ ] Run `make format-check` and `make lint`.
- [ ] Run `make test` and the relevant host evaluations; prefer `make check`
      when the environment supports the full gate.
- [ ] Run `make eval-atlas` separately for Atlas changes.
- [ ] Update `README.md`, tests, specs, or plans when the change affects their
      documented contract.
- [ ] Confirm no secrets, machine-specific hardware guesses, activation steps,
      generated results, or unrelated user changes entered the patch.
- [ ] Summarize files changed, validation performed, skipped checks, and any
      remaining safety constraints or follow-up work.
- [ ] Provide a Conventional Commit suggestion such as `docs: add agent
      workflow guide`, `feat(atlas): add server foundation`, or `fix(nix): ...`.
