# VS Code Home Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Home Manager the sole declarative owner of VS Code and apply the approved user settings, extension set, AI disablement, and update disablement.

**Architecture:** Add a focused common Home Manager VS Code module and import it alongside other user-program modules. Use the pinned Home Manager `programs.vscode.profiles.default` API, derive the Mise Go path from `config.xdg.dataHome`, and declare the approved extensions available from pinned Nixpkgs. Remove package-only declarations.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager 26.05, Python `unittest`.

**Spec:** `docs/superpowers/specs/2026-10-26-vscode-home-manager-design.md`

## Global Constraints

- Manage VS Code from `modules/workstation/common/home/`; do not add Darwin-specific editor behavior.
- Preserve existing profiles, snippets, keybindings, and workspace settings.
- Use `programs.vscode.profiles.default.userSettings`, as required by the
  pinned Home Manager revision.
- Derive the Go executable from `${config.xdg.dataHome}` and match Mise's `go = "1.27.0"` version.
- Do not activate Gaia or change Nix inputs.

## Review Focus

- Gaia evaluation accepts the flat Home Manager 26.05 VS Code settings API.
- No `vscode` package entry remains outside the dedicated module.
- `chat.disableAIFeatures` is `true`.
- The Go path derives from XDG data home and has no literal user-home path or `latest` alias.
- No extension list, keybindings, snippets, profile files, or activation script is introduced.

### Task 1: Test the declarative VS Code contract

**Files:** Modify `tests/unit/test_shared_sources.py`.

**Interfaces:** Produces `SharedSourceTests.test_vscode_configuration`, verifying the module import, approved setting contract, XDG Go path, and absence of duplicate package entries.

- [ ] Write the failing test, then run `make test-unit` and confirm it fails because `vscode.nix` is absent.
- [ ] Keep the failing contract unchanged.

### Task 2: Add the focused Home Manager module

**Files:** Create `modules/workstation/common/home/vscode.nix`; modify `modules/workstation/common/home/default.nix`, `modules/workstation/common/home/packages.nix`, and `modules/workstation/darwin/default.nix`.

**Interfaces:** Consumes `config.xdg.dataHome` and Home Manager's VS Code module; produces the single declarative VS Code owner.

- [ ] Enable VS Code and reproduce each approved setting as a Nix value.
- [ ] Import the module and remove only the duplicate standalone package entries.
- [ ] Run `make test-unit` and confirm the new contract passes.

### Task 3: Format and validate the complete configuration

**Files:** Files from Tasks 1–2 only.

- [ ] Run `make format`.
- [ ] Run `make check` and confirm format, lint, tests, and Gaia evaluation pass without activation.
- [ ] Inspect `git diff --check` and the scoped diff.
