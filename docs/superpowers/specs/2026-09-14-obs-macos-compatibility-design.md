# OBS macOS Compatibility Design

## Goal

Restore Gaia evaluation and provide OBS on macOS without relying on the
Linux-only `obs-studio` Nix package.

## Design

Remove `obs-studio` from the shared Home Manager package list and add the
official `obs` Homebrew cask to Gaia's existing inline Homebrew configuration.
Keep `tailscale-app` in that cask list.

Update contract tests to stop requiring OBS in the shared package list and to
expect exactly the Gaia casks `tailscale-app` and `obs`.

## Validation

Run formatting, linting, all contract tests, and both host evaluations. No
host activation is part of validation.

## Scope and Safety

This changes OBS's package source only. It does not enable unsupported Nix
platforms, alter Tailscale, or activate Gaia.
