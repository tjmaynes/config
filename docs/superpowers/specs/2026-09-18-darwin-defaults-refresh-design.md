# Darwin Defaults Refresh Design

## Goal

Keep Gaia on the stable Nix 26.05 release line while updating its macOS defaults
for macOS 26 and ensuring the configured screenshot destination exists.

## Design

The Darwin system module will continue to set the screenshot destination to
`${user.homeDirectory}/workspace/screencaptures`. Its global preferences will
enforce permanent dark mode by setting `AppleInterfaceStyle` to `"Dark"` and
`AppleInterfaceStyleSwitchesAutomatically` to `false`. `AppleKeyboardUIMode`
will change from `3` to `2`, the value nix-darwin documents for Sonoma and
later.

A Darwin-only Home Manager module at `modules/workstation/darwin/home.nix` will
define `home.activation.ensureScreencaptureDirectory` with
`lib.hm.dag.entryAfter [ "writeBoundary" ]`. The activation entry will run
`mkdir -p -- "${user.homeDirectory}/workspace/screencaptures"` through Home
Manager's `run` helper. This makes the operation idempotent, honors dry-run and
verbose activation modes, and lets a directory-creation failure stop activation.
Running it in the user's Home Manager activation avoids root ownership and keeps
macOS-specific user behavior out of the shared workstation module. The Gaia
host will import the module alongside the shared Home Manager configuration.

The flake will remain on Nixpkgs 26.05, Home Manager 26.05, and nix-darwin
26.05 because coordinated 26.11 release branches are not yet available.

## Alternatives Considered

- A managed `.keep` file under `workspace/screencaptures` would create the
  directory declaratively, but it would leave an unrelated file in a directory
  intended for screenshots.
- A nix-darwin system activation script could create the directory, but it
  would need explicit ownership handling because system activation runs as
  root.

## Validation

Gaia contract tests will verify the dark-mode preferences, keyboard UI mode,
screenshot location, and the generated activation entry's exact destination and
`mkdir -p` behavior. The change will then pass formatting, linting, the full
test suite, and both host evaluations through the repository's Makefile targets.

No system activation is part of this work. A later, explicitly requested Gaia
activation will apply the defaults and create the directory. Dark mode may not
become visible until the user logs out and back in.
