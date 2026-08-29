#!/bin/sh
set -eu

nix_eval() {
  nix --extra-experimental-features 'nix-command flakes' eval --json "$1"
}

test "$(nix_eval '.#darwinConfigurations.gaia.config.networking.hostName')" = '"gaia"'
test "$(nix_eval '.#darwinConfigurations.gaia.config.system.stateVersion')" = '4'
test "$(nix_eval '.#darwinConfigurations.gaia.config.home-manager.users.tjmaynes.programs.emacs.enable')" = true
test "$(nix_eval '.#darwinConfigurations.gaia.config.home-manager.users.tjmaynes.services.emacs.enable')" = false

# Keep this contract test evaluation-only so it can run on Linux CI. The
# platform-specific Gaia build runs in the Darwin workflow job.
nix --extra-experimental-features 'nix-command flakes' eval --raw \
  .#darwinConfigurations.gaia.config.system.build.toplevel.drvPath >/dev/null
