# Syncthing Implementation Plan

> **For agentic workers:** Implement this small, single-task change inline.

**Goal:** Run Syncthing automatically for Gaia's primary user.

**Architecture:** Enable the existing Home Manager service in the portable
profile; use its native launch agent on Gaia. Keep peers and folders mutable.

**Tech Stack:** Nix, Home Manager, launchd, Python unittest.

**Spec:** `docs/superpowers/specs/2026-10-22-syncthing-design.md`

## Global Constraints

Keep the UI on `127.0.0.1:8384`; preserve devices and folders configured in the
UI; keep secrets local; do not activate, update inputs, or alter firewall rules.
Preserve the pre-existing untracked `PLAN.md` and `RESEARCH.md`.

## Review Focus

Check the derived Gaia agent's startup and restart behavior, wrapper command,
and log paths. Check that no configuration updater overrides mutable settings.
Runtime operation remains unverified until separately authorized activation.

## Task 1: Enable and document the background service

**Files:** Modify `modules/workstation/common/home/default.nix`,
`modules/workstation/darwin/home.nix`,
`tests/integration/test_common.py`, `tests/integration/test_gaia.py`, `README.md`.

**Interfaces:** Consume Home Manager's `services.syncthing` options; produce an
enabled user service with `overrideDevices` and `overrideFolders` set to false.

- [x] Add common evaluation coverage for service enablement, loopback address,
  and preservation of UI-managed devices and folders. Add Gaia coverage for
  the enabled launch agent, background priority, and failure restart policy.
- [x] Run these tests before implementation and confirm the missing service
  causes failures.
- [x] Enable `services.syncthing` in the portable home profile and disable both
  override options. Rely on upstream startup flags and service-manager setup.
- [x] Document activation, local UI setup, local state and log locations, and
  service inspection in the README.
- [x] Run focused tests, then `make format-check`, `make lint`, `make test`,
  and `make eval-gaia`; inspect the scoped diff and report the results.

## Execution Notes

The user approved implementation of the design. Execute in the shared checkout
without further approval prompts, preserving unrelated files. Leave the result
uncommitted for review.

Review identified that upstream does not create its log directory. Added a
Darwin activation step after `writeBoundary` and before `setupLaunchAgents`,
with an evaluation test observed failing before the fix. The original service
tests and all 47 tests passed before this review fix; final validation includes
the additional test.

Final verification: `make check` passed (formatting, lint, all 48 tests, and
Gaia system derivation evaluation). Scoped `git diff --check` passed. No
activation was performed.
