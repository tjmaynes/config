# Workstation Module Layout and GitHub CLI Support

## Goal

Organize the current developer-machine modules under an explicit workstation
namespace and install the GitHub CLI on every workstation configuration. The
change must preserve Gaia and Athena behavior while leaving a clear location
for future home-server modules.

## Architecture

Move the existing module trees as follows:

```text
modules/workstation/common/
modules/workstation/darwin/
modules/workstation/nixos/
```

`workstation/common` contains shared Nix and Home Manager modules used by both
machines. `workstation/darwin` contains macOS system and home modules, and
`workstation/nixos` contains Linux workstation system and home modules.

Gaia imports the Darwin system modules and the common plus Darwin home modules.
Athena imports the NixOS system modules and the common plus NixOS home modules.
The existing module behavior and configuration values remain unchanged except
for the addition of `gh` to the shared workstation package set.

This leaves `modules/server` available for a future home-server configuration
without mixing server concerns into workstation modules.

## Implementation details

- Move all files currently under `modules/common`, `modules/darwin`, and
  `modules/nixos` into their corresponding `modules/workstation` paths.
- Update host imports, Home Manager imports, formatting/test file references,
  and documentation to use the new paths.
- Add the Nixpkgs `gh` package to the shared workstation home package module,
  making it available on both Gaia and Athena.
- Preserve existing host names, system versions, platform assignments, and
  activation behavior.
- Do not add server configuration in this change.

## Validation

- Ensure no active references to the old `modules/common`, `modules/darwin`,
  or `modules/nixos` paths remain.
- Evaluate both `darwinConfigurations.gaia` and
  `nixosConfigurations.athena`.
- Assert both workstation configurations include `gh`.
- Run formatting, linting, contract tests, documentation checks, and the
  existing non-activating evaluation targets.

