# Syncthing background service

## Intent

Run Syncthing automatically in the background for Gaia's primary user.

## Approach

Use Home Manager's existing `services.syncthing` module. It provides a macOS
launch agent and follows the repository's existing user configuration model.
Homebrew would add separate service management; a custom launch agent would
duplicate the upstream module. Home Manager is the proposed choice.

## Behavior and scope

- Enable the service in the portable workstation Home Manager configuration.
  Home Manager selects the native service manager for each platform.
- On Gaia, start the user agent at login and retain upstream restart behavior.
- Create Gaia's Syncthing log directory before Home Manager loads launch agents.
- Keep the web interface on `127.0.0.1:8384`, without opening a browser at login.
- Leave devices and folders managed through the web interface. Preserve those
  settings across rebuilds rather than overriding them with empty Nix lists.
- Keep generated identity keys and runtime configuration in the user's local
  Syncthing data directory, outside the repository and Nix store.
- Document setup, state and log locations, and the explicit activation command.

## Validation and constraints

Add evaluation checks for the service, loopback web address, preservation of
devices and folders, and Gaia's launch agent. Run formatting, lint, all tests,
and Gaia evaluation through Make. Do not activate the configuration: activation
requires a separate explicit user request under AGENTS.md.

## Implementation discretion

Use the locked Home Manager module's native behavior. Add only the configuration
needed to meet these requirements; no peer IDs, sync paths, credentials, firewall
changes, or input updates are part of this change.
