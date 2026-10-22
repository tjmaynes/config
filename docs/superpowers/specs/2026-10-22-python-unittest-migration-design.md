# Python unittest migration

## Intent

Replace the seven shell test scripts with Python standard-library `unittest`
tests. The user wants clearer organization, more useful failures, and easier
maintenance. Preserve the current coverage and evaluation-only behavior.

## Layout

```text
tests/
  pyproject.toml
  .mise.toml
  __init__.py
  support.py
  unit/
    __init__.py
    test_documentation.py
    test_repository.py
    test_shared_sources.py
  smoke/
    __init__.py
    test_flake.py
  integration/
    __init__.py
    test_agent_skills.py
    test_common.py
    test_gaia.py
    test_athena.py
  fixtures/
    agent-skills.nix
    agent-skills/...
```

Unit tests inspect repository files without invoking Nix. Smoke tests verify
flake metadata, flake checks, and supported outputs. Integration tests evaluate
real Nix configuration, including the existing agent-skill fixture expression.
Keep the Nix fixture logic and data; fix relative paths when moving it.

## Behavior

- Use named `TestCase` methods for related behaviors and `subTest` for repeated
  host, package, path, or fixture checks. Compare parsed JSON values with normal
  unittest assertions instead of shell pipelines and stringified JSON.
- A shared helper resolves the repository from its own location, invokes Nix
  with argument lists and an explicit working directory, and includes the
  command, return code, stdout, and stderr in command failures. Failed commands,
  malformed JSON, and missing Nix fail clearly; they never silently skip tests.
- Cache identical successful evaluations within one test process where useful.
  Never cache failures or substitute mocks for the real integration evaluations.
- Preserve every assertion in the existing scripts, including mail safety,
  removed-host checks, skill collision fixtures, fonts, and platform behavior.
- Tests never build or activate systems. Gaia remains evaluable on Linux.

## Tooling and commands

Keep Make as the canonical entry point. `make test` runs verbose unittest
discovery for all categories in the Nix development shell. Add focused
`test-unit`, `test-smoke`, and `test-integration` targets; retain `test-athena`.
Document direct unittest discovery from the repository root and tests directory.

The builder's choices are to use no third-party test runner or runtime test
dependencies; put Python project metadata and Ruff settings in
`tests/pyproject.toml`; pin the existing approved Python version, 3.14.7, in
`tests/.mise.toml`; and provide Python and Ruff in the Nix development shell.
Replace shellcheck in `make lint` with Ruff. Include Python formatting in the
existing format targets. Mise is an optional local runtime path, while Nix
continues to provide CI tooling without mise downloads.

Update README, AGENTS, and Python ignore patterns. CI keeps invoking Make on
Linux and macOS. Remove migrated shell scripts rather than retaining wrappers.
Historical design and plan documents are left as historical records.

## Constraints and validation

Preserve the user's existing flake.lock changes. Do not change workstation
configuration, inputs, activation commands, or build policy. Exact module and
helper boundaries can be adjusted by the builder without changing the above
behavior. Validate category discovery and named failures, then run
`make format-check`, `make lint`, `make test`, `make eval-gaia`, and
`make eval-athena`. Inspect the scoped diff for lost assertions and stale active
references to shell tests. Report any environment blockers accurately.
