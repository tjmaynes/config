# Ghostty macOS Application Search Design

## Goal

Make the Darwin `ghostty-bin` application discoverable through macOS global
application search while preserving the existing Home Manager-managed Ghostty
configuration.

## Design

Add `pkgs.ghostty-bin` to `environment.systemPackages` in the shared Darwin
workstation module. nix-darwin builds application bundles from system packages
and places them in `/Applications/Nix Apps`, a location beneath the system
Applications directory that macOS indexes.

The existing `programs.ghostty` Home Manager declaration remains unchanged. It
continues to select `ghostty-bin` on Darwin and owns Ghostty's settings,
Zsh integration, and syntax integrations. Declaring the same package in the
Darwin system package set intentionally gives nix-darwin responsibility for
the macOS application bundle without moving user configuration out of Home
Manager.

No Homebrew cask, imperative application copy, Spotlight reindexing command,
or activation is part of this change.

## Validation

Run the flake formatter check, lint suite, shell contract tests, and Gaia host
evaluation. These verify the configuration evaluates cleanly without activating
the workstation. After a user-approved `make switch-gaia`, verify that
`/Applications/Nix Apps/Ghostty.app` exists and that Ghostty appears in
Spotlight.

## Scope and Safety

The implementation changes only the Darwin system package list. It does not
modify the existing Ghostty configuration, activate Gaia, change Homebrew,
write outside the repository, or introduce credentials or secrets.
