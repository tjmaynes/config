# Restore Native Codex Home Manager Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore Home Manager's native, mutable Codex settings and shared MCP registry while sourcing Codex from the existing unstable package input.

**Architecture:** Track Home Manager's pre-release 26.11 development line through its `master` input, but continue following the repository's pinned 26.05 nixpkgs input. Define the Codex and MCP declarations as focused shared Home Manager modules, and use Home Manager's native mutable-settings activation rather than managing Codex's full TOML file.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager, Python `unittest` evaluation tests.

**Spec:** `docs/superpowers/specs/2026-10-24-codex-mcp-design.md`

## Global Constraints

- Update only the Home Manager input from `release-26.05` to `master`; retain 26.05 nixpkgs and nix-darwin inputs.
- Keep the resulting Home Manager 26.11 / nixpkgs 26.05 mismatch visible and documented.
- Source the Codex package explicitly from the existing `pkgsUnstable.codex` package set.
- Use `programs.codex.mutableSettings`; do not create an immutable `~/.codex/config.toml` or custom merger.
- Declare the shared n8n endpoint as `https://n8n.tjmaynes.com/mcp-server/http`.
- Do not manage project trust, credentials, authentication, or the Sproutup project configuration in this repository.
- Do not activate Gaia or contact either n8n endpoint.

## Review Focus

- Home Manager remains the sole pre-release input; nixpkgs and nix-darwin must stay on their 26.05 release branches, verified by source-level tests.
- Codex uses the unstable package set despite Home Manager inheriting global stable packages, verified by evaluating `programs.codex.package.pname`.
- The mutable activation preserves Codex ownership of its live config rather than creating `home.file` entries for config or auth files, verified by evaluation.
- Shared MCP settings reach Codex through `enableMcpIntegration` and retain the exact n8n URL, verified by evaluation.
- No project-specific path or profile leaks into the shared workstation configuration, verified by checking empty profiles and generated home-file names.

---

### Task 1: Restore the Home Manager input and native configuration modules

**Files:**
- Modify: `flake.nix:8-11`
- Modify: `flake.lock`
- Modify: `modules/common/home/default.nix:3-15`
- Create: `modules/common/home/codex.nix`
- Create: `modules/common/home/mcp.nix`
- Modify: `modules/common/home/packages.nix:1-10`
- Modify: `README.md:145-147`

**Interfaces:**
- Consumes: `pkgsUnstable` passed from `flake.nix` through the host's `home-manager.extraSpecialArgs`.
- Produces: `programs.codex` with `enable`, `package`, `mutableSettings`, `enableMcpIntegration`, and declared settings; `programs.mcp.servers.n8n.url`.

- [ ] **Step 1: Update Home Manager test expectations first**

Change the source-level test to require `home-manager` to track `master` and to require `package = pkgsUnstable.codex;` in `modules/common/home/codex.nix`.

- [ ] **Step 2: Run the focused unit test to verify it fails**

Run: `make test-unit`

Expected: FAIL because the source still points Home Manager at `release-26.05` and has no `codex.nix` module.

- [ ] **Step 3: Switch only the Home Manager input and regenerate its lock node**

Set `home-manager.url` to `github:nix-community/home-manager/master`; keep its `nixpkgs.follows = "nixpkgs"` setting and retain the existing nixpkgs and nix-darwin URLs. Update only the Home Manager lock node.

- [ ] **Step 4: Add the shared `codex.nix` and `mcp.nix` modules and import them**

Declare `programs.codex.enable = true`, `package = pkgsUnstable.codex`, `mutableSettings = true`, and `enableMcpIntegration = true`. Set the approved model, reasoning effort, personality, and `features.js_repl` values from the spec. Declare `programs.mcp.enable = true` and the exact shared n8n URL. Remove the separate `pkgsUnstable.codex` entry from `home.packages` so Codex has one owner.

- [ ] **Step 5: Document the explicit compatibility boundary**

Add a concise README section that explains mutable settings, the shared MCP registry, credential and activation limits, and that Home Manager tracks the pre-release 26.11 development line while nixpkgs and nix-darwin remain on 26.05.

- [ ] **Step 6: Run the focused unit test to verify it passes**

Run: `make test-unit`

Expected: PASS, including the updated Codex source contract.

### Task 2: Add native-module evaluation coverage

**Files:**
- Create: `tests/integration/test_codex.py`

**Interfaces:**
- Consumes: `tests.support.HOSTS`, `USER`, and `eval_json`.
- Produces: named `CodexHomeTests` methods that assert the evaluated Home Manager options and generated activation behavior.

- [ ] **Step 1: Write failing integration tests for the native configuration**

Add `CodexHomeTests` that, for each host, asserts Codex and MCP enablement; `programs.codex.package.pname == "codex"`; the exact n8n URL; the `codexMutableSettings` activation is generated after `linkGeneration`; and no immutable `.codex/config.toml`, `.codex/auth.json`, managed-state path, project profile, or Sproutup path is produced.

- [ ] **Step 2: Run the focused integration test to verify it fails**

Run: `make test-integration`

Expected: FAIL before Task 1's modules are present, with missing `programs.codex` or `programs.mcp` options.

- [ ] **Step 3: Evaluate the restored native modules**

Use the Task 1 implementation as the minimal production configuration; do not add wrappers, a custom TOML merger, project configuration, or activation scripts beyond Home Manager's generated mutable-settings activation.

- [ ] **Step 4: Run the focused integration test to verify it passes**

Run: `make test-integration`

Expected: PASS for the Gaia evaluation.

### Task 3: Verify and review the scoped upgrade

**Files:**
- Modify: files from Tasks 1 and 2 only as required by validation findings

**Interfaces:**
- Consumes: the configured flake and all repository checks.
- Produces: a formatting-clean, evaluated configuration that has not been activated.

- [ ] **Step 1: Format changed Nix and Python sources**

Run: `make format`

Expected: changed Nix sources use the flake formatter and Python tests use Ruff formatting.

- [ ] **Step 2: Run the required repository checks**

Run: `make format-check && make lint && make test && make eval`

Expected: every command exits successfully; the evaluation may emit the documented Home Manager/nixpkgs version-mismatch warning but must not fail.

- [ ] **Step 3: Inspect the scoped diff**

Run: `git diff --check` and `git diff -- flake.nix flake.lock modules/common/home README.md tests`

Expected: only the planned Home Manager input, native Codex/MCP modules, tests, and documentation change; no activation, credentials, or project-specific configuration appears.

- [ ] **Step 4: Request an independent code review**

Ask a reviewer to check source ownership, input boundaries, native module options, activation safety, and test coverage before declaring completion.
