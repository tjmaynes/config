# Shared Codex Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Declaratively install the requested `grill-me` and `interview-me` Codex skills for the shared user profile on both Gaia and Athena.

**Architecture:** Add both public Git repositories as locked non-flake inputs, then extend the existing shared `skillRepos` list that feeds the common Home Manager agent-skills module. The existing structural validation and `include` allowlists will expose the selected upstream directories at `~/.agents/skills`, and the contract test will evaluate those links for both hosts.

**Tech Stack:** Nix flakes, Home Manager, POSIX shell contract tests, `jq`.

**Spec:** `docs/superpowers/specs/2026-09-28-agent-skill-repositories-design.md` (user-approved extension: add `grill-me` and `interview-me` to both Gaia and Athena on 2026-10-22).

## Global Constraints

- Support exactly `aarch64-darwin` Gaia and `x86_64-linux` Athena through the shared Home Manager profile.
- Pin public skill sources in `flake.lock`; Home Manager activation must never fetch a moving upstream revision.
- Declare the upstream skill repositories as non-flake inputs.
- Select only `grill-me`, its upstream-required `grilling` helper, and `interview-me`; do not expose unrelated skills from either repository.
- Preserve the existing collision and structural-validation behavior in `lib/agent-skills.nix`.
- Keep the change free of credentials, tokens, and private data.

## Review Focus

- An upstream directory layout change should fail the focused agent-skill evaluation instead of silently installing the wrong path; Task 1 asserts each selected `home.file` source exactly.
- A repository input accidentally treated as a flake should be rejected by the lockfile contract; Task 1 asserts both new `.flake` flags are `false`.
- `grill-me` must be accompanied by its delegated `grilling` helper; Task 1 asserts the helper source on both hosts.
- Each requested skill must point at the correct locked repository subdirectory; Task 1 asserts the exact `grill-me` and `interview-me` source paths.
- Gaia and Athena must receive identical selected skill targets despite different platforms; Task 1 runs each assertion through both host prefixes.

---

### Task 1: Extend the shared-skill contract test

**Files:**
- Modify: `tests/agent-skills.sh`
- Test: `tests/agent-skills.sh`

**Interfaces:**
- Consumes: flake inputs `mattpocock-skills` and `addyosmani-agent-skills`, plus the existing Home Manager `home.file` interface.
- Produces: a contract that proves both hosts link the selected skills to their exact locked source directories.

- [ ] **Step 1: Add failing assertions to `tests/agent-skills.sh`**

Require `flake.nix` to declare `github:mattpocock/skills/main` and `github:addyosmani/agent-skills/main`; require their lock nodes to have `flake == false`; resolve both input `outPath` values; and, for both existing host prefixes, compare these `home.file` sources to the resolved paths:

```sh
.agents/skills/grill-me   == "$mattpocock_skills_source/skills/productivity/grill-me"
.agents/skills/grilling   == "$mattpocock_skills_source/skills/productivity/grilling"
.agents/skills/interview-me == "$addyosmani_agent_skills_source/skills/interview-me"
```

- [ ] **Step 2: Run the focused contract test and verify it fails**

Run: `nix develop --command sh tests/agent-skills.sh`

Expected: FAIL because the two new flake inputs and Home Manager links do not yet exist.

### Task 2: Pin and expose the two upstream skill sources

**Files:**
- Modify: `flake.nix`
- Modify: `flake.lock`
- Test: `tests/agent-skills.sh`

**Interfaces:**
- Consumes: the existing `skillRepos` entries consumed by `modules/workstation/common/home/agent-skills.nix`.
- Produces: locked source paths and `home.file` targets named `grill-me`, `grilling`, and `interview-me` on both hosts.

- [ ] **Step 1: Add the two non-flake source inputs in `flake.nix`**

Declare `mattpocock-skills` from `github:mattpocock/skills/main` and `addyosmani-agent-skills` from `github:addyosmani/agent-skills/main`, each with `flake = false`; add both names to the `outputs` argument list.

- [ ] **Step 2: Extend `skillRepos` in `flake.nix` with precise allowlists**

Add a `mattpocock-skills` entry rooted at `skills/productivity` whose `include` list is `[ "grill-me" "grilling" ]`, and an `addyosmani-agent-skills` entry rooted at `skills` whose `include` list is `[ "interview-me" ]`. Preserve the existing two unrestricted repository entries.

- [ ] **Step 3: Regenerate `flake.lock` for the newly declared inputs**

Run: `nix --extra-experimental-features 'nix-command flakes' flake lock`

Expected: `flake.lock` gains locked nodes for the two public non-flake GitHub sources without changing unrelated configuration files.

- [ ] **Step 4: Run the focused contract test and verify it passes**

Run: `nix develop --command sh tests/agent-skills.sh`

Expected: PASS, proving exact links for all selected skills on both Gaia and Athena.

### Task 3: Validate the complete configuration change

**Files:**
- Verify: `flake.nix`
- Verify: `flake.lock`
- Verify: `tests/agent-skills.sh`

**Interfaces:**
- Consumes: the finished locked input declarations and shared Home Manager profile.
- Produces: formatting, static-analysis, test-suite, and host-evaluation evidence for handoff.

- [ ] **Step 1: Inspect the scoped diff**

Run: `git diff --check` and `git diff -- flake.nix flake.lock tests/agent-skills.sh`

Expected: no whitespace errors; only the declared inputs, lockfile nodes, skill-repository allowlists, and focused assertions change.

- [ ] **Step 2: Run repository validation**

Run: `make format-check`, `make lint`, and `make test`.

Expected: each command exits successfully.

- [ ] **Step 3: Evaluate both host configurations**

Run: `make eval-gaia` and `make eval-athena`.

Expected: each command emits a derivation path and exits successfully; neither command activates a host.

- [ ] **Step 4: Commit**

```bash
git add flake.nix flake.lock tests/agent-skills.sh docs/superpowers/plans/2026-10-22-add-shared-codex-skills.md
git commit -m "feat: manage shared Codex skills"
```
