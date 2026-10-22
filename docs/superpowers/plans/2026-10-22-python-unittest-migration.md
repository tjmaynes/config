# Python unittest migration implementation plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task. The user approved the design and explicitly requested implementation in this chat.

**Goal:** Replace shell tests with organized Python unittest coverage and clear failures.

**Architecture:** File-only unit checks, flake smoke checks, and real Nix integration checks share a small subprocess/JSON helper. Make and the Nix development shell remain the canonical interface.

**Tech Stack:** Python 3.14, unittest, Nix, Ruff, optional mise.

**Spec:** `docs/superpowers/specs/2026-10-22-python-unittest-migration-design.md`

## Global constraints

- Preserve every shell assertion and the user's existing flake.lock changes.
- Use no third-party runtime test dependencies and no activation or test builds.
- Preserve Linux/macOS evaluation support and `make test-athena`.
- Do not rewrite historical documents.

## Review focus

- Nonzero commands must report arguments, status, stdout, and stderr.
- Invalid JSON and missing executables must fail clearly.
- Discovery must work from the repository root and tests directory.
- Moved Nix fixtures must retain correct repository and fixture paths.
- Repeated host/package checks must identify the failed host or value.

### Task 1: Python discovery and Nix support

**Files:** `tests/__init__.py`, `tests/support.py`, `tests/unit/__init__.py`, `tests/unit/test_support.py`, `tests/pyproject.toml`, `tests/.mise.toml`.

**Interfaces:** `ROOT: Path`, `run_nix(*args: str) -> str`, `eval_json(attribute: str, *, apply: str | None = None) -> object`, `eval_raw(attribute: str) -> str`.

- [x] Add support tests for successful JSON parsing, command diagnostics, malformed JSON, missing executables, and explicit cwd with mocked subprocess calls.
- [x] Run focused tests and confirm missing support fails before implementation.
- [x] Implement argument-list execution with repository cwd and successful evaluation caching.
- [x] Add project metadata, Python 3.14.7 mise pin, package markers, and Ruff configuration.
- [x] Run support tests from both working directories and confirm success.

### Task 2: Port all behavior checks

**Files:** `tests/unit/test_{documentation,repository,shared_sources}.py`, `tests/smoke/test_flake.py`, `tests/integration/test_{agent_skills,common,gaia,athena}.py`, category package markers, `tests/fixtures/agent-skills.nix`.

**Interfaces:** Consume Task 1 helpers; expose standard named unittest methods and subtests.

- [x] Port file-only assertions from docs, hygiene, common-eval, and agent-skills scripts into unit tests.
- [x] Port metadata/check/output assertions into smoke tests.
- [x] Port every host/shared evaluation, parsed package comparison, and mail configuration assertion into integration tests.
- [x] Move the agent-skills expression and adjust its root/import/fixture paths; check every returned fixture boolean by name.
- [x] Run focused categories and inspect named failures; compare ports against all seven original scripts.

### Task 3: Replace command integration and verify

**Files:** `Makefile`, `flake.nix`, `.gitignore`, `README.md`, `AGENTS.md`; delete the seven migrated `tests/*.sh` scripts.

**Interfaces:** `make test`, `test-unit`, `test-smoke`, `test-integration`, `test-athena`; Nix-shell Python and Ruff; format and lint include Python.

- [x] Replace shell runners and shellcheck with unittest and Ruff; provide Python/Ruff in the dev shell and add Python formatting.
- [x] Document category boundaries, focused/direct commands, Nix requirements, optional mise, and no runtime downloads in CI.
- [x] Remove shell scripts after verifying coverage parity; ignore Python generated files.
- [x] Run `make format-check`, `make lint`, `make test`, `make eval-gaia`, and `make eval-athena`.
- [x] Inspect scoped diff and discovery from tests cwd; obtain final code review and address issues.
- [x] Leave changes reviewable in the current checkout; preserve flake.lock exactly as found.
