# Nix Configuration Modernization Implementation Plan

> **For Codex:** Execute this plan with the Superbuild skill. Every phase is test-first, non-activating by default, and ends at its quality gate.

> Generated: 2026-08-28
> Status: Complete
> Author: Codex
> Last Updated: 2026-08-28

**Goal:** Replace the legacy channel-based workstation configuration with one pinned Nix flake whose Gaia and Athena outputs evaluate reproducibly from a clean checkout.

**Architecture:** A small explicit flake composes two platform-first host trees. Both system configurations embed focused common and platform-specific Home Manager modules; test scripts, Make targets, and CI keep evaluation separate from activation.

**Tech Stack:** Nix 2.35-compatible flakes, Nixpkgs/NixOS 26.05, Home Manager 26.05, nix-darwin 26.05, POSIX shell checks, GNU Make, GitHub Actions.

**Approved design:** [Nix modernization design](../../docs/superpowers/specs/2026-08-28-nix-modernization-design.md)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Technology Stack](#technology-stack)
3. [Requirements and Interview Summary](#requirements-and-interview-summary)
4. [Research and Best Practices](#research-and-best-practices)
5. [Codebase Analysis](#codebase-analysis)
6. [Refactor Assessment](#refactor-assessment)
7. [Architecture](#architecture)
8. [Implementation Phases](#implementation-phases)
9. [Testing Strategy](#testing-strategy)
10. [Assumptions, Unknowns, and Risks](#assumptions-unknowns-and-risks)
11. [Appendix](#appendix)

---

## Executive Summary

### One-line summary

Deliver a stable 26.05 flake for Gaia and Athena, consolidate portable developer configuration into Home Manager, retire unsafe legacy hosts/scripts, and continuously verify both outputs without activation.

### Goals

- [x] Pin Nixpkgs, Home Manager, and nix-darwin to exact, aligned 26.05 revisions.
- [x] Expose only `darwinConfigurations.gaia` and `nixosConfigurations.athena`.
- [x] Make Home Manager own the approved portable CLI and dotfile behavior.
- [x] Make both configurations evaluable from a clean checkout.
- [x] Add formatting, static analysis, host evaluation, hygiene checks, and non-activating CI.
- [x] Document explicit bootstrap, build, activation, rollback, and hardware-boundary workflows.

### Non-goals

- Secrets, tokens, SSH private keys, or private-key generation.
- Apollo, Demeter, Kratos, channel compatibility, Stow, Prezto, or `.bash_onstart.sh`.
- An unstable package input or a flake framework.
- Automatic Nix installation, host activation, reboot, disk formatting, or destructive Homebrew cleanup.
- A fabricated deployable Athena hardware configuration.
- State-version increases.

### Key decisions

| Decision | Rationale | Alternatives considered |
| --- | --- | --- |
| Direct native flake | Two hosts do not justify a framework | Compatibility wrapper; flake-parts |
| Stable 26.05 inputs | Reproducible, supported baseline | Fully unstable |
| Platform-first modules | Matches Gaia/Athena ownership and approved design | Home-first tree |
| Embedded Home Manager | One system rebuild owns system and user state | Standalone Home Manager output |
| Upstream Nix bootstrap | Conventional setup requested by user | Lix installer |
| Evaluation-only Athena hardware profile | Physical machine is unavailable | Guessing device configuration |
| Homebrew cleanup disabled initially | Prevent accidental application/data deletion | `uninstall` or `zap` on first switch |

### Phase overview

| Phase | Name | Depends on | Parallel with | Estimate | Status |
| --- | --- | --- | --- | ---: | --- |
| 0 | Nix and quality bootstrap | None | None | 5 | Complete |
| 1 | Flake outputs and common Home Manager | 0 | None | 8 | Complete |
| 2A | Gaia / nix-darwin migration | 1 | 2B | 8 | Complete |
| 2B | Athena / NixOS migration | 1 | 2A | 8 | Complete |
| 3 | Integration, retirement, CI, and docs | 2A, 2B | None | 8 | Complete |

**Total estimate:** 37 points.

Phases 2A and 2B must be executed with parallel sub-agents. They create disjoint platform files and disjoint test scripts.

---

## Technology Stack

### Detected languages and tools

| Area | Detected state | Target |
| --- | --- | --- |
| Configuration language | Nix modules from 2022 | Nix 26.05 module interfaces and flakes |
| Shell | Bash installer/reload scripts | Small POSIX shell test scripts only |
| Task runner | GNU Make | GNU Make with explicit check/build/switch targets |
| Dependency management | Mutable channels and remote master tarballs | `flake.nix` plus committed `flake.lock` |
| System managers | NixOS and nix-darwin | NixOS 26.05 and nix-darwin 26.05 |
| User manager | Channel-imported Home Manager | Embedded Home Manager 26.05 |

No root `AGENTS.md` or `CLAUDE.md` documents the complete stack, so codebase detection and current research were required.

### Quality tools

| Tool type | Current | Planned command |
| --- | --- | --- |
| Formatter | Missing | `nix fmt -- --check .` |
| Linter | Missing | `nix develop --command statix check .` |
| Dead-code check | Missing | `nix develop --command deadnix --fail .` |
| Shell syntax/static check | Missing | `nix develop --command shellcheck tests/*.sh` |
| Type/config validation | Missing | Host-specific `nix eval` and `nix flake check` |
| Test framework | Missing | POSIX shell contract tests under `tests/` |
| CI | Missing | GitHub Actions Linux/macOS jobs |

**Bootstrap required:** Yes. Coverage percentages do not map to declarative Nix modules; the equivalent gate is that every new output and configuration responsibility has an evaluation or explicit contract assertion.

---

## Requirements and Interview Summary

### Source

- Type: Technical epic.
- Source: User request plus the approved design specification.
- Original request: “Help me upgrade my current nix setup, do research to accomplish this.”

### Prior interview answers

| Required Superplan question | Confirmed answer | Planning implication |
| --- | --- | --- |
| What is the MVP; what is deferred? | Gaia and Athena flake outputs, shared Home Manager, evaluation and docs are MVP | No optional framework, secrets, or deployment automation |
| What is explicitly out of scope? | Secrets, Apollo, Demeter, physical activation, guessed Athena hardware | Deletion and documentation are explicit tasks |
| Performance/security requirements? | Reproducible evaluation; no secret/store leakage or destructive cleanup | Pure inputs, explicit paths, cleanup disabled |
| Test coverage expectation? | Both configs must evaluate without machines; CI must not activate | Evaluation/contract coverage replaces line coverage |

### Acceptance criteria

- [x] AC-1: The lockfile records aligned 26.05 Nixpkgs, Home Manager, and nix-darwin inputs.
- [x] AC-2: Gaia evaluates as `aarch64-darwin` with system state version 4 and Home Manager state version 22.05.
- [x] AC-3: Athena evaluates as `x86_64-linux` with both state versions at 22.05.
- [x] AC-4: Common Home Manager owns the approved package and configuration inventory.
- [x] AC-5: Gaia declares Chrome, Obsidian, Tailscale, and Bitwarden only through Homebrew/MAS.
- [x] AC-6: Athena uses maintained NixOS 26.05 interfaces for i3, PipeWire, Docker, k3s, VMware, fonts, and user configuration.
- [x] AC-7: No tracked implementation file uses channels, `NIX_PATH`, angle-bracket imports, `builtins.getEnv`, or external dotfile paths.
- [x] AC-8: Checks, CI, and builds never activate a host.
- [x] AC-9: README documents all manual safety boundaries.

---

## Research and Best Practices

Research date: 2026-08-28.

| Finding | Application |
| --- | --- |
| Flakes standardize inputs/outputs and lock exact dependency revisions | Commit `flake.nix` and `flake.lock` |
| Home Manager stable branches align with NixOS releases | Use `release-26.05` following the same Nixpkgs input |
| nix-darwin publishes a 26.05 branch and recommends flakes | Use `nix-darwin-26.05` and explicit `aarch64-darwin` |
| State versions are compatibility contracts | Preserve existing values |
| Flakes evaluate Git-tracked content in pure mode | Eliminate environment/external-dotfiles dependencies |
| Nix content is copied to the world-readable store | Exclude credentials and private keys |
| Current nix-darwin Homebrew options use `onActivation` | Set cleanup/update/upgrade to safe initial values |
| CI installers support Linux and Apple Silicon macOS | Evaluate the matching host on each platform |

Sources:

1. <https://nix.dev/concepts/flakes.html>
2. <https://nixos.org/blog/announcements/2026/nixos-2605/>
3. <https://github.com/nix-community/home-manager>
4. <https://github.com/nix-darwin/nix-darwin/blob/master/README.md>
5. <https://nixos.org/download/>
6. <https://github.com/NixOS/nix-installer-action>

### Patterns to apply

- Explicit host → platform → common-module import flow.
- Embedded Home Manager with global Nixpkgs for each system.
- Test behavior at public flake output paths, not internal implementation details.
- Separate check, build, and switch commands.
- Red/green contract scripts before each configuration slice.

### Anti-patterns to remove

- Mutable channels and master tarballs.
- Implicit host detection for activation.
- Generic reload commands that also upgrade Homebrew.
- Destructive disk/bootstrap automation.
- Runtime plugin/framework clones and external dotfile sources.
- Monolithic mixed system/user modules.

---

## Codebase Analysis

### Reusable patterns

| File | Pattern | Reuse decision |
| --- | --- | --- |
| `hosts/gaia.nix` → `modules/darwin/default.nix` | Host imports platform module and embedded Home Manager | Preserve the layering, rewrite interfaces |
| `hosts/athena.nix` → `modules/nixos/default.nix` | Host owns services/desktop overrides | Split into focused NixOS modules |
| `modules/home-manager/default.nix` | Portable user configuration merges into both hosts | Preserve intent, replace the monolith |

### Critical and high-risk debt

| Location | Risk | Plan response |
| --- | --- | --- |
| Missing `flake.nix` / `flake.lock` | No reproducible composition root | Phase 0 |
| Missing Athena hardware import | Clean checkout cannot evaluate | Phase 2B evaluation profile |
| Darwin hard-coded to Intel | Contradicts Gaia platform | Phase 1/2A |
| Gaia `cleanup = "zap"` | Can delete applications and data | Phase 2A |
| Installer `rm -rf` and disk operations | Destructive workstation changes | Phase 3 deletion |
| `builtins.getEnv` and external dotfiles | Impure, non-self-contained evaluation | Phase 1 |
| Removed NixOS/Home Manager options | 26.05 evaluation failures | Phases 2A/2B |
| Missing formatter/tests/CI | Regressions are invisible | Phases 0 and 3 |

### Inventory correction

The authoritative Gaia list includes `watchman`. It is assigned to Home Manager alongside the other portable CLI packages. The approved design was corrected before this plan was written.

---

## Refactor Assessment

**Confidence:** High — clean rewrite recommended and already approved.

The repository is small, but nearly every entry point depends on channel-era or unsafe behavior. Incremental adaptation would preserve temporary `NIX_PATH`, symlink, external-dotfile, and installer machinery. The plan therefore uses a controlled replacement:

1. Establish a locked flake and quality harness.
2. Build the common module contract.
3. Migrate Darwin and NixOS independently in parallel.
4. Verify both outputs.
5. Remove the legacy tree and rewrite operations/documentation.

This is not a big-bang behavior rewrite: each host is evaluated before its legacy source is deleted, and native Nix generations remain the runtime rollback mechanism.

---

## Architecture

### System context

    Developer
       |
       | make check / build-* / switch-*
       v
    flake.nix + flake.lock
       |
       +-----------------------------+
       |                             |
       v                             v
    Gaia output                  Athena output
    nix-darwin                   NixOS
       |                             |
       +----------+------------------+
                  v
          common Home Manager
          packages + git + zsh
          atuin + mise + tmux + vim

External systems are limited to locked GitHub inputs, the official Nix bootstrap, Homebrew/MAS during explicit Gaia activation, and mise downloads during an explicit post-activation runtime install.

### Component boundaries

| Component | Responsibility | Depends on | Public verification |
| --- | --- | --- | --- |
| `flake.nix` | Inputs, two outputs, formatter/dev shell/checks | Locked upstream flakes | `nix flake metadata/check` |
| `hosts/gaia` | Gaia identity, platform, state contracts | Darwin/common modules | Gaia contract test |
| `hosts/athena` | Athena identity, platform, state, hardware boundary | NixOS/common modules | Athena contract test |
| `modules/common/home` | Portable user environment | Home Manager/Nixpkgs | Both host evaluations |
| `modules/darwin` | macOS system preferences and GUI apps | nix-darwin | Gaia evaluation/build |
| `modules/nixos` | Linux desktop/services/user | NixOS | Athena evaluation |
| `tests` | Public output and hygiene contracts | Nix CLI, jq, ripgrep | `make test` |
| GitHub Actions | Re-run checks without activation | Linux/macOS runners | Workflow status |

### Primary data flow

    nix flake update
          |
          v
    reviewed flake.lock diff
          |
          v
    make check
      |      |
      |      +--> formatting + static + hygiene
      +----------> Gaia + Athena evaluation
          |
          v
    make build-gaia or make eval-athena
          |
          v
    explicit human-only switch target

### Error flow

- Input fetch failure: lock update fails; committed lock remains unchanged.
- Module/package error: host evaluation fails before build or switch.
- Home Manager collision: switch stops; user inventories/moves the conflicting file, then retries.
- Homebrew mismatch: first migration does not clean unmanaged items.
- Athena hardware uncertainty: evaluation profile passes, deployment remains blocked until real hardware configuration is generated and reviewed.

API, database, and UI designs are not applicable.

---

## Implementation Phases

## Phase 0: Nix and Quality Bootstrap

> **Depends on:** Nothing  
> **Can run with:** Nothing  
> **Estimate:** 5 points  
> **Status:** Complete

### Objectives

- Establish the explicit upstream Nix prerequisite without silently mutating Gaia.
- Add the initial flake inputs, lockfile, formatter, dev shell, and test tooling.
- Create a red/green bootstrap contract.

### Task 0.1: Confirm or install upstream Nix

- [x] **Task complete**

**Files:**

- Modify later: `README.md`
- Test: command prerequisite

**Step 1: Write the failing test**

    command -v nix

**Step 2: Run test to verify it fails**

- Command: `command -v nix`
- Expected: exit code 1 and no path on the current Gaia environment.
- This confirms the prerequisite is genuinely absent.

**Step 3: Write minimal implementation**

- Pause for explicit approval because this changes the host outside the repository.
- Run the official command from <https://nixos.org/download/>:

    curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh

- Start a fresh login shell before continuing.

**Step 4: Run test to verify it passes**

- Command: `nix --version`
- Expected: `nix (Nix) 2.35.x` or a newer supported upstream Nix; exit code 0.
- Also verify: `nix-store --version` exits 0.

**Step 5: Stage for commit**

- No repository file is staged for the external prerequisite.

### Task 0.2: Add the flake and quality harness

- [x] **Task complete**

**Files:**

- Create: `flake.nix`
- Create: `flake.lock`
- Create: `tests/flake-bootstrap.sh`
- Modify: `Makefile:1-21`

**Step 1: Write the failing test**

Create `tests/flake-bootstrap.sh` with this complete contract:

    #!/bin/sh
    set -eu

    nix_cmd() {
      nix --extra-experimental-features 'nix-command flakes' "$@"
    }

    test -f flake.nix
    test -f flake.lock

    metadata="$(nix_cmd flake metadata --json)"
    printf '%s' "$metadata" | jq -e '.locks.nodes.nixpkgs.locked.rev | length > 0' >/dev/null
    printf '%s' "$metadata" | jq -e '.locks.nodes."home-manager".locked.rev | length > 0' >/dev/null
    printf '%s' "$metadata" | jq -e '.locks.nodes."nix-darwin".locked.rev | length > 0' >/dev/null

    nix_cmd eval --raw .#formatter.aarch64-darwin.name >/dev/null
    nix_cmd eval --raw .#formatter.x86_64-linux.name >/dev/null

**Step 2: Run test to verify it fails**

- Command: `sh tests/flake-bootstrap.sh`
- Expected: FAIL with `test: flake.nix: No such file` or exit code 1 because the flake does not exist.
- This confirms the test detects the missing composition root.

**Step 3: Write minimal implementation**

Create `flake.nix` with exactly these contracts:

- Input URLs:
  - `github:NixOS/nixpkgs/nixos-26.05`
  - `github:nix-community/home-manager/release-26.05`
  - `github:nix-darwin/nix-darwin/nix-darwin-26.05`
- Both downstream inputs follow `nixpkgs`.
- Supported systems are exactly `aarch64-darwin` and `x86_64-linux`.
- `formatter` uses `pkgs.nixfmt` on both systems.
- `devShells.<system>.default` contains `actionlint`, `deadnix`, `jq`, `nixfmt`, `ripgrep`, `shellcheck`, and `statix`.
- Do not define host outputs until Phase 1.

Generate `flake.lock` with:

    nix --extra-experimental-features 'nix-command flakes' flake lock

Replace the Makefile with bootstrap-safe targets:

    NIX := nix --extra-experimental-features 'nix-command flakes'

    fmt:
        $(NIX) fmt

    format-check:
        $(NIX) fmt -- --check flake.nix

    lint:
        $(NIX) develop --command shellcheck tests/*.sh

    test:
        sh tests/flake-bootstrap.sh

    check: format-check lint test

    update:
        $(NIX) flake update

    .PHONY: fmt format-check lint test check update

**Step 4: Run test to verify it passes**

- Command: `sh tests/flake-bootstrap.sh`
- Expected: no output; exit code 0.
- Command: `make check`
- Expected: all formatter, static analysis, shell check, and bootstrap tests exit 0 with no warnings.

**Step 5: Stage for commit**

    git add flake.nix flake.lock Makefile tests/flake-bootstrap.sh

### Definition of Done

- [x] New Phase 0 shell code passes ShellCheck; repository-wide Nix lint is deferred until legacy retirement in Phase 3.
- [x] Code passes formatter.
- [x] Code passes type checker (Nix flake metadata/evaluation).
- [x] All new tests pass.
- [x] All existing tests pass.
- [x] Test coverage >= 80% for new code (N/A for declarative config; all Phase 0 outputs have contract assertions).
- [x] No new code warnings introduced; Nix only reports the expected dirty-worktree warning.
- [x] No host activation occurred.

### Phase completion message

    chore(nix): bootstrap flake and quality tooling

    Add aligned stable inputs, lockfile, formatter, development shell,
    shell checks, and the initial non-activating test harness.

    Files changed:
    - flake.nix (CREATE)
    - flake.lock (CREATE)
    - tests/flake-bootstrap.sh (CREATE)
    - Makefile (MODIFY)

    DO NOT COMMIT - User will handle git operations.

- [x] **CHECKPOINT: Run `/compact focus on: Phase 0 complete, upstream Nix available, flake inputs locked and quality harness created, Phase 1 adds both outputs and common Home Manager modules`**

---

## Phase 1: Flake Outputs and Common Home Manager

> **Depends on:** Phase 0  
> **Can run with:** Nothing  
> **Estimate:** 8 points  
> **Status:** Complete

### Objectives

- Add explicit shared identity/path values and both host outputs.
- Embed Home Manager into both systems.
- Build the common Nix and user configuration layer.

### Task 1.1: Define output and identity contracts

- [x] **Task complete**

**Files:**

- Create: `tests/common-eval.sh`
- Create: `hosts/gaia/default.nix`
- Create: `hosts/athena/default.nix`
- Create: `hosts/athena/hardware-eval.nix`
- Create: `modules/common/nix.nix`
- Modify: `flake.nix`

**Step 1: Write the failing test**

Create `tests/common-eval.sh`:

    #!/bin/sh
    set -eu

    nix_cmd() {
      nix --extra-experimental-features 'nix-command flakes' "$@"
    }

    test "$(nix_cmd eval --raw .#darwinConfigurations.gaia.config.networking.hostName)" = "gaia"
    test "$(nix_cmd eval --raw .#darwinConfigurations.gaia.pkgs.stdenv.hostPlatform.system)" = "aarch64-darwin"
    test "$(nix_cmd eval --json .#darwinConfigurations.gaia.config.system.stateVersion)" = "4"

    test "$(nix_cmd eval --raw .#nixosConfigurations.athena.config.networking.hostName)" = "athena"
    test "$(nix_cmd eval --raw .#nixosConfigurations.athena.pkgs.stdenv.hostPlatform.system)" = "x86_64-linux"
    test "$(nix_cmd eval --raw .#nixosConfigurations.athena.config.system.stateVersion)" = "22.05"

**Step 2: Run test to verify it fails**

- Command: `sh tests/common-eval.sh`
- Expected: FAIL with `flake does not provide attribute darwinConfigurations.gaia`.
- This confirms the host outputs are absent.

**Step 3: Write minimal implementation**

- In `flake.nix` define one plain identity set with:
  - username `tjmaynes`
  - full name `TJ Maynes`
  - email `tj@tjmaynes.com`
  - GitHub username `tjmaynes`
  - timezone `America/Chicago`
- Derive a Gaia user with `/Users/tjmaynes` and a Athena user with `/home/tjmaynes`.
- Pass the applicable user set via `specialArgs` and `home-manager.extraSpecialArgs`.
- Define Gaia with `nix-darwin.lib.darwinSystem` and Athena with `nixpkgs.lib.nixosSystem`.
- Import the locked Home Manager Darwin/NixOS module in the respective output.
- Set `home-manager.useGlobalPkgs = true` and `home-manager.useUserPackages = true`.
- Make host platform and imported modules visible in each output declaration.
- Create minimal host files with explicit hostnames, home paths, and preserved state versions.
- Create `hardware-eval.nix` with a prominently documented tmpfs root used only to satisfy evaluation; do not declare real disks, swaps, or hardware modules.
- Create `modules/common/nix.nix` with:
  - `nix.settings.experimental-features = [ "nix-command" "flakes" ]`
  - `nixpkgs.config.allowUnfree = true`
  - `nixpkgs.config.allowBroken = false`

**Step 4: Run test to verify it passes**

- Command: `sh tests/common-eval.sh`
- Expected: no output; exit code 0.
- Command: `nix flake check --no-build`
- Expected: evaluates all checks for the current system and exits 0.

**Step 5: Stage for commit**

    git add flake.nix hosts/gaia/default.nix hosts/athena/default.nix hosts/athena/hardware-eval.nix modules/common/nix.nix tests/common-eval.sh

### Task 1.2: Build the common Home Manager modules

- [x] **Task complete**

**Files:**

- Create: `modules/common/home/default.nix`
- Create: `modules/common/home/git.nix`
- Create: `modules/common/home/mise.nix`
- Create: `modules/common/home/packages.nix`
- Create: `modules/common/home/shells.nix`
- Create: `modules/common/home/tmux.nix`
- Create: `modules/common/home/vim.nix`
- Modify: `tests/common-eval.sh`

**Step 1: Write the failing test**

Append these public-contract assertions to `tests/common-eval.sh` before creating the modules:

    for host in \
      darwinConfigurations.gaia \
      nixosConfigurations.athena
    do
      prefix=".#$host.config.home-manager.users.tjmaynes"
      test "$(nix_cmd eval --json "$prefix.programs.git.enable")" = "true"
      test "$(nix_cmd eval --json "$prefix.programs.zsh.enable")" = "true"
      test "$(nix_cmd eval --json "$prefix.programs.atuin.enable")" = "true"
      test "$(nix_cmd eval --json "$prefix.programs.mise.enable")" = "true"
      test "$(nix_cmd eval --json "$prefix.programs.tmux.enable")" = "true"
      test "$(nix_cmd eval --json "$prefix.programs.vim.enable")" = "true"
      test "$(nix_cmd eval --raw "$prefix.home.stateVersion")" = "22.05"
    done

**Step 2: Run test to verify it fails**

- Command: `sh tests/common-eval.sh`
- Expected: FAIL because `programs.git.enable` evaluates to false or the Home Manager user is not yet configured.
- This confirms common user behavior is missing.

**Step 3: Write minimal implementation**

- `default.nix` imports the six focused modules, enables Home Manager/Atuin/direnv/nix-direnv, sets explicit username/home/state version, and defines:
  - `WORKSPACE_DIRECTORY=<home>/workspace`
  - `CODE_DIRECTORY=<home>/workspace/code`
  - `EDITOR=vi`
- `packages.nix` contains the maintained Nixpkgs equivalents for:
  - bat, Codex, curl, ffmpeg, GnuPG, htop, jq, OpenSSH, pandoc, ripgrep, shfmt, tree, Watchman, and WebP tools.
  - Do not include Stow, language runtimes, or packages installed automatically by a program module.
- `git.nix` uses current `programs.git.settings` for user identity, aliases, editor, delta tool, GPG program, and default branch; enable Git LFS and delta integration; never include the GitHub token.
- `mise.nix` enables Zsh integration and writes current `programs.mise.globalConfig.tools` entries:
  - direnv 2.32.1, python 3.13.10, node 24.11.1, kubectl 1.26.2, just 1.43.1, go 1.25.3, bun 1.3.10.
  - Do not run `mise install` in activation hooks.
- `shells.nix` enables Zsh, completion, autosuggestions, syntax highlighting, Oh My Zsh, `robbyrussell`, and common Git/Kubernetes plugins.
  - Keep directory-depth aliases, `workspace`, `k`, `cat`, and `ps` only when their target command is installed.
  - Keep `kill-process-on-port`, `convert-m4a-to-mp3`, and `morning-paper` as tracked shell functions.
  - Remove the dotfiles/task-master aliases, `mods` helpers, external backup wrapper, Prezto, Bash customization, `.zsh_dynamic`, and `.bash_onstart.sh`.
- `tmux.nix` translates the `C-g` prefix, pane/split/window bindings, one-based indexing, 8000-line history, status, escape timing, terminal override, activity monitoring, and reload binding.
- `vim.nix` owns the current settings/mappings/filetype rules and uses Nixpkgs Vim plugins instead of vim-plug downloads. Evaluate every chosen plugin on both platforms; document and omit only plugins absent from stable 26.05.
- Import `modules/common/home` for `tjmaynes` in both flake outputs.

**Step 4: Run test to verify it passes**

- Command: `sh tests/common-eval.sh`
- Expected: no output; all six program assertions pass for both hosts.
- Command: `make lint`
- Expected: statix, deadnix, and shellcheck exit 0 with no warnings.

**Step 5: Stage for commit**

    git add flake.nix modules/common/home tests/common-eval.sh

### Definition of Done

- [x] New shell code passes ShellCheck; Nix lint is deferred per user instruction until legacy retirement.
- [x] Code passes formatter across every new Phase 1 Nix file.
- [x] Code passes type checker (both host configurations evaluate on all systems).
- [x] All new tests pass.
- [x] All existing tests pass.
- [x] Test coverage >= 80% for new code (all common program contracts assert against both host outputs).
- [x] No new code warnings introduced.
- [x] No activation hooks perform network downloads.

### Phase completion message

    feat(home): add shared flake and developer environment

    Expose Gaia and Athena from aligned stable inputs and add the
    portable Home Manager packages, Git, shell, mise, tmux, and Vim modules.

    Files changed:
    - flake.nix (MODIFY)
    - hosts/gaia/default.nix (CREATE)
    - hosts/athena/default.nix (CREATE)
    - hosts/athena/hardware-eval.nix (CREATE)
    - modules/common/nix.nix (CREATE)
    - modules/common/home/* (CREATE)
    - tests/common-eval.sh (CREATE)

    DO NOT COMMIT - User will handle git operations.

- [x] **CHECKPOINT: Run `/compact focus on: Phase 1 complete, Gaia and Athena outputs exist, common Nix and Home Manager modules evaluate, Phases 2A and 2B independently implement Darwin and NixOS layers`**

---

## Phase 2A: Gaia / nix-darwin Migration

> **Depends on:** Phase 1  
> **Can run with:** Phase 2B using a parallel sub-agent  
> **Estimate:** 8 points  
> **Status:** Complete

### Objectives

- Migrate Gaia system preferences and safe Homebrew/MAS ownership.
- Add Darwin-only Home Manager behavior.
- Build Gaia without activation.

### Task 2A.1: Write and satisfy the Gaia contract

- [x] **Task complete**

**Files:**

- Create: `tests/gaia.sh`
- Modify: `hosts/gaia/default.nix`
- Modify: `modules/darwin/default.nix:1-35`
- Modify: `modules/darwin/preferences.nix:1-62`
- Create: `modules/darwin/homebrew.nix`
- Create: `modules/darwin/home/default.nix`

**Step 1: Write the failing test**

Create `tests/gaia.sh`:

    #!/bin/sh
    set -eu

    root=".#darwinConfigurations.gaia.config"
    test "$(nix eval --raw "$root.users.users.tjmaynes.home")" = "/Users/tjmaynes"
    test "$(nix eval --json "$root.homebrew.enable")" = "true"
    test "$(nix eval --raw "$root.homebrew.onActivation.cleanup")" = "none"
    test "$(nix eval --json "$root.homebrew.masApps.Bitwarden")" = "1352778147"
    nix eval --json "$root.homebrew.casks" |
      jq -e 'map(.name) | sort == ["google-chrome", "obsidian", "tailscale"]' >/dev/null
    test "$(nix eval --raw "$root.system.defaults.screencapture.location")" =
      "/Users/tjmaynes/libra/photos/screencaptures"

**Step 2: Run test to verify it fails**

- Command: `sh tests/gaia.sh`
- Expected: FAIL because Homebrew/preferences options are missing or still contain the legacy inventory.
- This confirms the test detects incomplete Darwin behavior.

**Step 3: Write minimal implementation**

- Rewrite `modules/darwin/default.nix` to import common Nix policy, preferences, and Homebrew; enable Zsh as an allowed/login shell, nix-darwin Nix management, and GnuPG agent support using 26.05 options.
- Keep `system.primaryUser = "tjmaynes"` and explicit hostname/computer name in the Gaia host.
- Replace `builtins.getEnv` with the passed Gaia user values.
- In `preferences.nix` migrate:
  - `fonts.packages`
  - caps-lock-to-control mapping
  - screenshot location
  - approved Dock, Finder, application firewall, login window, software update, and global UI defaults
- In `homebrew.nix` set:
  - enable true
  - casks exactly Chrome, Obsidian, and Tailscale
  - MAS app Bitwarden ID 1352778147
  - `onActivation.autoUpdate = false`
  - `onActivation.upgrade = false`
  - `onActivation.cleanup = "none"`
  - no formula list, taps, `brewPrefix`, embedded Ruby config, or `zap`
- In `modules/darwin/home/default.nix` add only the macOS Oh My Zsh plugin and a Homebrew path if current nix-darwin shell integration does not already supply it.

**Step 4: Run test to verify it passes**

- Command: `sh tests/gaia.sh`
- Expected: no output; exit code 0.
- Command: `nix build .#darwinConfigurations.gaia.system --no-link`
- Expected: derivation builds or substitutes successfully; exit code 0; no activation.

**Step 5: Stage for commit**

    git add hosts/gaia/default.nix modules/darwin tests/gaia.sh

### Definition of Done

- [x] New shell code passes ShellCheck; Nix lint remains deferred per user instruction until Phase 3 retirement.
- [x] Code passes formatter across every new Phase 2 Nix file.
- [x] Code passes type checker (Gaia evaluates and builds).
- [x] All new tests pass.
- [x] All existing tests pass.
- [x] Test coverage >= 80% for new code (Gaia identity, apps, cleanup, preferences, and build are covered).
- [x] No new code warnings introduced.
- [x] Gaia builds without activation.
- [x] No Homebrew cleanup or upgrade is executed.

### Phase completion message

    feat(darwin): modernize gaia configuration

    Migrate Gaia to current nix-darwin options, safe Homebrew and MAS
    ownership, explicit paths, and Darwin-specific Home Manager behavior.

    Files changed:
    - hosts/gaia/default.nix (MODIFY)
    - modules/darwin/default.nix (MODIFY)
    - modules/darwin/preferences.nix (MODIFY)
    - modules/darwin/homebrew.nix (CREATE)
    - modules/darwin/home/default.nix (CREATE)
    - tests/gaia.sh (CREATE)

    DO NOT COMMIT - User will handle git operations.

- [x] **CHECKPOINT: Run `/compact focus on: Phase 2A complete, Gaia evaluates and builds with safe app ownership, Phase 3 will integrate checks, retire legacy files, and document activation`**

---

## Phase 2B: Athena / NixOS Migration

> **Depends on:** Phase 1  
> **Can run with:** Phase 2A using a parallel sub-agent  
> **Estimate:** 8 points  
> **Status:** Complete

### Objectives

- Translate the Athena workstation to current NixOS/Home Manager options.
- Preserve service/desktop intent without guessing hardware.
- Evaluate the full NixOS toplevel derivation.

### Task 2B.1: Write and satisfy the Athena contract

- [x] **Task complete**

**Files:**

- Create: `tests/athena.sh`
- Modify: `hosts/athena/default.nix`
- Modify: `hosts/athena/hardware-eval.nix`
- Modify: `modules/nixos/default.nix:1-16`
- Create: `modules/nixos/desktop.nix`
- Create: `modules/nixos/services.nix`
- Create: `modules/nixos/home/default.nix`

**Step 1: Write the failing test**

Create `tests/athena.sh`:

    #!/bin/sh
    set -eu

    root=".#nixosConfigurations.athena.config"
    test "$(nix eval --raw "$root.users.users.tjmaynes.home")" = "/home/tjmaynes"
    test "$(nix eval --json "$root.services.xserver.windowManager.i3.enable")" = "true"
    test "$(nix eval --json "$root.services.pipewire.enable")" = "true"
    test "$(nix eval --json "$root.services.pipewire.pulse.enable")" = "true"
    test "$(nix eval --json "$root.virtualisation.docker.enable")" = "true"
    test "$(nix eval --json "$root.virtualisation.vmware.guest.enable")" = "true"
    test "$(nix eval --json "$root.services.k3s.enable")" = "true"
    test "$(nix eval --raw "$root.services.k3s.role")" = "server"
    test "$(nix eval --raw "$root.fileSystems.\"/\".fsType")" = "tmpfs"
    nix eval --raw .#nixosConfigurations.athena.config.system.build.toplevel.drvPath >/dev/null

**Step 2: Run test to verify it fails**

- Command: `sh tests/athena.sh`
- Expected: FAIL because current desktop/service options are absent or use removed interfaces.
- This confirms the test detects incomplete NixOS behavior.

**Step 3: Write minimal implementation**

- Rewrite `modules/nixos/default.nix` as the NixOS composition root with explicit user, groups, Zsh shell, Home Manager imports, hostname/timezone, and NetworkManager.
- `desktop.nix` owns:
  - X11 and i3
  - current display-manager default-session option
  - keyboard repeat and supported scaling variables
  - PipeWire with ALSA, 32-bit ALSA, PulseAudio compatibility, and rtkit
  - `fonts.packages` with maintained font packages
- `services.nix` owns:
  - VMware guest support
  - Docker
  - k3s server
  - firewall TCP 6443
  - maintained logind settings for the 8G runtime directory limit
- `modules/nixos/home/default.nix` owns supported Linux-only applications and i3 Home Manager behavior:
  - alacritty, Bitwarden desktop, Brave, cmus, Draw.io, feh, GIMP, Goland, mpv, mutt/maintained equivalent, Packer, pavucontrol, TeX Live, Vagrant, VS Code, VirtualBox, and xclip where supported on 26.05.
  - Do not duplicate common packages, Docker/k3s binaries supplied by services, or Go/Node/Python/Yarn runtimes now managed by mise.
  - Preserve Emacs and i3 keybinding/bar intent with current Home Manager options.
- Keep `hardware-eval.nix` visibly evaluation-only. Use a tmpfs root and no real device IDs.
- If any approved application has no 26.05 package, record its exact replacement or removal in README; do not silently drop it.

**Step 4: Run test to verify it passes**

- Command: `sh tests/athena.sh`
- Expected: no output; exit code 0.
- Command: `nix eval --raw .#nixosConfigurations.athena.config.system.build.toplevel.drvPath`
- Expected: one `/nix/store/...-nixos-system-athena-26.05...drv` path; exit code 0.

**Step 5: Stage for commit**

    git add hosts/athena modules/nixos tests/athena.sh

### Definition of Done

- [x] New shell code passes ShellCheck; Nix lint remains deferred per user instruction until Phase 3 retirement.
- [x] Code passes formatter across every new Phase 2 Nix file.
- [x] Code passes type checker (Athena toplevel evaluates).
- [x] All new tests pass.
- [x] All existing tests pass.
- [x] Test coverage >= 80% for new code (all retained desktop/service contracts are evaluated).
- [x] No new code warnings introduced.
- [x] Hardware file is visibly evaluation-only.
- [x] No activation or disk command ran.

### Phase completion message

    feat(nixos): modernize athena configuration

    Migrate Athena to current desktop, audio, service, and Home Manager
    interfaces while preserving a clearly evaluation-only hardware boundary.

    Files changed:
    - hosts/athena/default.nix (MODIFY)
    - hosts/athena/hardware-eval.nix (MODIFY)
    - modules/nixos/default.nix (MODIFY)
    - modules/nixos/desktop.nix (CREATE)
    - modules/nixos/services.nix (CREATE)
    - modules/nixos/home/default.nix (CREATE)
    - tests/athena.sh (CREATE)

    DO NOT COMMIT - User will handle git operations.

- [x] **CHECKPOINT: Run `/compact focus on: Phase 2B complete, Athena toplevel evaluates with current NixOS modules and evaluation-only hardware, Phase 3 integrates checks, retirement, CI, and documentation`**

---

## Phase 3: Integration, Retirement, CI, and Documentation

> **Depends on:** Phases 2A and 2B  
> **Can run with:** Nothing  
> **Estimate:** 8 points  
> **Status:** Complete

### Objectives

- Turn all contracts into one reliable command surface.
- Delete legacy hosts, modules, scripts, and assets only after replacements pass.
- Add non-activating CI and complete operational documentation.

### Task 3.1: Add hygiene and command contracts

**Status:** Complete

**Files:**

- Create: `tests/hygiene.sh`
- Create: `tests/docs.sh`
- Modify: `Makefile`

**Step 1: Write the failing tests**

Create `tests/hygiene.sh`:

    #!/bin/sh
    set -eu

    for path in \
      hosts/apollo.nix \
      hosts/demeter.nix \
      hosts/gaia.nix \
      hosts/athena.nix \
      hosts/kratos.sh \
      modules/common/default.nix \
      modules/common/nixpkgs.nix \
      modules/common/settings.nix \
      modules/home-manager/default.nix \
      scripts/install.sh \
      scripts/reload.sh
    do
      test ! -e "$path"
    done

    if rg -n \
      --glob '*.nix' \
      --glob '*.sh' \
      --glob 'Makefile' \
      'NIX_PATH|builtins\.getEnv|<home-manager|config/dotfiles|bash_onstart' \
      .; then
      echo "forbidden legacy dependency found" >&2
      exit 1
    fi

Create `tests/docs.sh`:

    #!/bin/sh
    set -eu

    for heading in Bootstrap Update Check Build Activate Rollback Secrets Mise Hardware
    do
      rg -q "^## $heading" README.md
    done

    rg -q 'gaia' README.md
    rg -q 'athena' README.md
    ! rg -q 'apollo|demeter|kratos' README.md

**Step 2: Run tests to verify they fail**

- Command: `sh tests/hygiene.sh`
- Expected: FAIL on the first still-present retired path.
- Command: `sh tests/docs.sh`
- Expected: FAIL because required README sections are absent.
- This confirms retirement and documentation are not complete.

**Step 3: Write minimal implementation**

Replace the Makefile command surface with:

- `fmt` and `format-check`.
- `lint` for statix, deadnix, shellcheck, and actionlint.
- `test` running every `tests/*.sh` script in a deterministic explicit order.
- `eval-gaia` and `eval-athena` using public toplevel derivation paths.
- `check` combining format, lint, tests, and both evaluations.
- `build-gaia` and `build-athena` using `nix build --no-link`.
- `switch-gaia` using `sudo darwin-rebuild switch --flake .#gaia`.
- `switch-athena` must print a refusal explaining that `hardware-eval.nix` must first be replaced; it must not invoke `nixos-rebuild switch`.
- `update` using `nix flake update`.

**Step 4: Run tests to verify they pass**

- Command: `sh tests/flake-bootstrap.sh && sh tests/common-eval.sh && sh tests/gaia.sh && sh tests/athena.sh`
- Expected: the already-completed bootstrap and host contracts pass; the deliberately red hygiene/docs contracts remain isolated until Tasks 3.2 and 3.3.
- Command: `make eval-gaia eval-athena`
- Expected: each prints a store derivation path and exits 0; no activation.

**Step 5: Stage for commit**

    git add Makefile tests/hygiene.sh tests/docs.sh

### Task 3.2: Retire legacy implementation

**Status:** Complete

**Files:**

- Delete: `hosts/apollo.nix`
- Delete: `hosts/demeter.nix`
- Delete: `hosts/gaia.nix`
- Delete: `hosts/athena.nix`
- Delete: `hosts/kratos.sh`
- Delete: `modules/common/default.nix`
- Delete: `modules/common/nixpkgs.nix`
- Delete: `modules/common/settings.nix`
- Delete: `modules/home-manager/default.nix`
- Delete: `modules/darwin/com.googlecode.iterm2.plist`
- Delete: `scripts/install.sh`
- Delete: `scripts/reload.sh`

**Step 1: Write the failing test**

- The complete test is already present in `tests/hygiene.sh`.
- Add one assertion that no supported-host output contains the retired names:

    nix flake show 2>&1 | rg -q 'gaia'
    nix flake show 2>&1 | rg -q 'athena'
    ! nix flake show 2>&1 | rg -q 'apollo|demeter|kratos'

**Step 2: Run test to verify it fails**

- Command: `sh tests/hygiene.sh`
- Expected: FAIL because retired files and forbidden legacy references still exist.
- This confirms deletion is required.

**Step 3: Write minimal implementation**

- Delete the exact files above after confirming Gaia and Athena contract tests are green.
- Remove empty legacy directories.
- Do not delete `tmp/` or modify the user's current `.gitignore` change; it is a read-only migration source and user-owned worktree state.

**Step 4: Run test to verify it passes**

- Command: `sh tests/hygiene.sh`
- Expected: no output; exit code 0.
- Command: `nix flake show`
- Expected: shows Gaia and Athena outputs and no retired host output.

**Step 5: Stage for commit**

    git add -u hosts modules scripts
    git add tests/hygiene.sh

### Task 3.3: Add CI and operational documentation

**Status:** Complete

**Files:**

- Create: `.github/workflows/check.yml`
- Modify: `README.md:1-100`
- Modify: `tests/docs.sh`

**Step 1: Write the failing test**

Extend `tests/docs.sh`:

    test -f .github/workflows/check.yml
    rg -q 'nix-installer-action' .github/workflows/check.yml
    ! rg -q 'darwin-rebuild switch|nixos-rebuild switch' .github/workflows/check.yml
    rg -q 'cleanup.*none' README.md
    rg -q 'hardware-eval.nix' README.md

**Step 2: Run test to verify it fails**

- Command: `sh tests/docs.sh`
- Expected: FAIL because the workflow and rewritten README are absent.
- This confirms operational documentation/CI are incomplete.

**Step 3: Write minimal implementation**

Create `.github/workflows/check.yml`:

- Trigger on pushes and pull requests.
- Grant only `contents: read`.
- Linux job on `ubuntu-latest`:
  - checkout
  - install upstream Nix with `NixOS/nix-installer-action`
  - run format, static analysis, hygiene, and Athena evaluation
- Darwin job on `macos-latest`:
  - checkout
  - install upstream Nix with the same action
  - run Gaia evaluation and non-activating Gaia build
- Use no activation or Homebrew mutation command.

Rewrite README with these exact top-level sections:

- Supported Hosts
- Requirements
- Bootstrap
- Update
- Check
- Build
- Activate
- Rollback
- Secrets
- Mise
- Homebrew
- Hardware

Document:

- Official upstream Nix bootstrap and fresh-shell requirement.
- First Gaia nix-darwin command with per-command flake features.
- Separate checks/builds/switch.
- Native generation rollback.
- Existing-file inventory before the first Home Manager activation.
- Homebrew cleanup remains `none` until separately reviewed.
- `mise install` is explicit after activation.
- Secrets/keys remain external.
- Athena cannot be switched with `hardware-eval.nix`; generate/review real hardware configuration first.

**Step 4: Run test to verify it passes**

- Command: `sh tests/docs.sh`
- Expected: no output; exit code 0.
- Command: `nix develop --command actionlint`
- Expected: no output; exit code 0.
- Command: `make check`
- Expected: all formatting, lint, contract, hygiene, docs, and host evaluation commands exit 0; no activation.

**Step 5: Stage for commit**

    git add .github/workflows/check.yml README.md tests/docs.sh Makefile

### Definition of Done

- [x] Code passes linter.
- [x] Code passes formatter.
- [x] Code passes type checker (both host outputs evaluate).
- [x] All new tests pass.
- [x] All existing tests pass.
- [x] Test coverage >= 80% for new code (all public outputs, retained behavior, hygiene, docs, and workflow contracts are covered).
- [x] No new warnings introduced by project checks.
- [x] Gaia non-activating build passes on Apple Silicon.
- [x] CI contains no activation command.
- [x] User-owned `.gitignore` change remains preserved and uncommitted unless the user chooses otherwise.

### Phase completion message

    feat(config): complete flake modernization

    Add CI and explicit operational commands, document bootstrap and rollback,
    and retire the unsafe channel-era hosts, modules, and scripts.

    Files changed:
    - Makefile (MODIFY)
    - README.md (MODIFY)
    - .github/workflows/check.yml (CREATE)
    - tests/* (CREATE/MODIFY)
    - legacy hosts/modules/scripts (DELETE)

    DO NOT COMMIT - User will handle git operations.

- [x] **CHECKPOINT: Run `/compact focus on: Nix modernization complete, Gaia and Athena evaluate from the locked flake, common/Darwin/NixOS modules and CI are final, no activation performed, ready for human review and first explicit Gaia switch`**

---

## Testing Strategy

### Test pyramid adapted to declarative configuration

| Level | Approximate share | Tests |
| --- | ---: | --- |
| Contract/unit-like | 80% | Individual option, identity, app, program, state-version, and hygiene assertions |
| Integration | 15% | Full Gaia and Athena module evaluation |
| End-to-end | 5% | Non-activating Gaia system build; physical activation remains manual |

### Commands and expected outputs

| Check | Command | Expected |
| --- | --- | --- |
| Bootstrap | `sh tests/flake-bootstrap.sh` | No output, exit 0 |
| Common | `sh tests/common-eval.sh` | No output, exit 0 |
| Gaia | `sh tests/gaia.sh` | No output, exit 0 |
| Athena | `sh tests/athena.sh` | No output, exit 0 |
| Hygiene | `sh tests/hygiene.sh` | No matches, exit 0 |
| Docs | `sh tests/docs.sh` | No output, exit 0 |
| Format | `make format-check` | No diff, exit 0 |
| Lint | `make lint` | No statix/deadnix/shellcheck/actionlint findings |
| Full | `make check` | All checks/evaluations exit 0 |
| Gaia build | `make build-gaia` | Store derivation built, no activation |
| Athena eval | `make eval-athena` | Toplevel derivation path |

### Red/green discipline

- Add or extend the applicable contract script before changing its Nix module.
- Run it and confirm failure is due to missing behavior.
- Implement only the behavior under test.
- Re-run the focused script and then `make check`.
- Refactor only after green.

### Manual validation after implementation

1. Review `flake.lock` revisions.
2. Review Gaia build output without switching.
3. Inventory existing files Home Manager will own.
4. Review current Homebrew formula/cask inventory; do not clean it automatically.
5. Run the explicit Gaia switch only after user approval.
6. Verify shell, Git, mise, tmux, Vim, GUI apps, and system preferences.
7. Keep the previous nix-darwin generation available for rollback.

---

## Assumptions, Unknowns, and Risks

### Assumptions

| Assumption | Risk if wrong | Mitigation |
| --- | --- | --- |
| Gaia can install upstream Nix and run an Apple Silicon build | Local verification blocked | CI/macOS runner plus explicit user approval |
| Stable 26.05 provides the approved CLI packages | A package evaluation fails | Map to maintained equivalent; no unstable input without new approval |
| Current dotfiles reflect desired tmux/Vim/shell behavior | Unwanted config is migrated | Contract only the explicitly approved behaviors |
| Homebrew is present before nix-darwin activation | GUI install step fails | README prerequisite and non-destructive retry |

### Known unknowns

| Unknown | Impact | Resolution |
| --- | --- | --- |
| Real Athena disks/modules | Cannot deploy safely | Generate real hardware config on the physical host |
| Exact supported Vim plugin set on both platforms | Some plugin names may differ | Evaluate each stable plugin before adding it |
| Whether every old Athena desktop package remains in 26.05 | Capability may need replacement | Record exact mapping in implementation notes/README |
| Existing Gaia files that collide with Home Manager | First switch may stop | Inventory and move conflicts before switch |

### Risks

| Risk | Probability | Impact | Mitigation |
| --- | --- | --- | --- |
| Cross-platform option difference | Medium | High | Separate contract tests and platform modules |
| Large Codex/Vim/Gaia builds | Medium | Medium | Use substitutes, evaluation first, selective builds |
| Homebrew removes unmanaged apps | Low | High | Cleanup/update/upgrade all false/none initially |
| Secret copied from source inventories | Low | Critical | Explicit exclusion plus review/hygiene |
| Evaluation-only Athena profile mistaken as deployable | Medium | Critical | Refusing switch target and prominent docs |

---

## Appendix

### File delta summary

**Create**

- `flake.nix`, `flake.lock`
- `hosts/gaia/default.nix`
- `hosts/athena/default.nix`, `hosts/athena/hardware-eval.nix`
- `modules/common/nix.nix` and `modules/common/home/*.nix`
- `modules/darwin/homebrew.nix`, `modules/darwin/home/default.nix`
- `modules/nixos/desktop.nix`, `services.nix`, `home/default.nix`
- `tests/*.sh`
- `.github/workflows/check.yml`

**Modify**

- `Makefile`
- `README.md`
- `modules/darwin/default.nix`
- `modules/darwin/preferences.nix`
- `modules/nixos/default.nix`

**Delete after replacement tests pass**

- `hosts/apollo.nix`, `demeter.nix`, legacy `gaia.nix` and `athena.nix`, `kratos.sh`
- `modules/common/default.nix`, `nixpkgs.nix`, `settings.nix`
- `modules/home-manager/default.nix`
- `modules/darwin/com.googlecode.iterm2.plist`
- `scripts/install.sh` and `scripts/reload.sh`

### Parallel execution instructions

After Phase 1, launch two general-purpose sub-agents:

- Phase 2A agent: read this plan, follow every TDD micro-step, run Gaia-focused quality gates, return the conventional commit message, and do not commit.
- Phase 2B agent: read this plan, follow every TDD micro-step, run Athena-focused quality gates, return the conventional commit message, and do not commit.

The primary agent must reconcile shared-tree status and run `make check` after both finish.

### Glossary

| Term | Definition |
| --- | --- |
| Evaluation | Resolve and type-check module configuration without activation |
| Build | Realize a Nix derivation without switching the active generation |
| Switch | Activate a built generation; always explicit and human-approved |
| State version | Compatibility contract controlling migration behavior |
| Evaluation profile | Tracked non-deployable declarations that let a host graph evaluate |

### Version history

| Version | Date | Author | Change |
| --- | --- | --- | --- |
| 1.0 | 2026-08-28 | Codex | Initial Superplan from approved design |

---

## Sign-off

| Role | Name | Status | Date |
| --- | --- | --- | --- |
| Author | Codex | Complete | 2026-08-28 |
| Design owner | TJ Maynes | Approved | 2026-08-28 |
| Plan reviewer | TJ Maynes | Pending | |
