# Codex Unstable Package Design

## Goal

Keep Gaia and Athena on the pinned `nixos-26.05` package set while sourcing
only the `codex` Home Manager package from a separately pinned
`nixos-unstable` input.

## Design

Add `nixpkgs-unstable` as a second flake input. For each supported host,
import that input with the host's platform and the same `allowUnfree` and
`allowBroken` policy as the primary package set. Pass the resulting
`pkgsUnstable` package set through the host's Home Manager `extraSpecialArgs`.

The shared Home Manager package module will continue to source its package
list from stable `pkgs`, except for `codex`, which will use
`pkgsUnstable.codex`. No overlay is needed: this direct, explicit package
selection makes the exception visible and confines unstable dependencies to
Codex's runtime closure.

Future Codex upgrades will update only this input through the repository's
canonical Makefile interface:

```sh
make update-unstable
```

## Validation

Extend the shared Home Manager contract test to evaluate the configured Codex
package and verify that its derivation comes from `nixpkgs-unstable`, while a
representative ordinary package remains on stable `nixpkgs`. Run formatting,
linting, all shell contract tests, and both host evaluations. No activation is
part of validation.

## Scope and Safety

The change updates the flake inputs and lock file, Home Manager argument
wiring for Gaia and Athena, the shared package declaration, and focused test
coverage. It does not alter either host's primary `nixpkgs` input, activate a
host, add secrets, or install a separately managed Nix profile package.
