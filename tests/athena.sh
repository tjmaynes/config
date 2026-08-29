#!/bin/sh
set -eu

nix_eval() {
  nix --extra-experimental-features 'nix-command flakes' eval --json "$1"
}

test "$(nix_eval '.#nixosConfigurations.athena.config.networking.hostName')" = '"athena"'
test "$(nix_eval '.#nixosConfigurations.athena.config.system.stateVersion')" = '"22.05"'
test "$(nix_eval '.#nixosConfigurations.athena.config.home-manager.users.tjmaynes.programs.emacs.enable')" = true
test "$(nix_eval '.#nixosConfigurations.athena.config.home-manager.users.tjmaynes.services.emacs.enable')" = true
test "$(nix_eval '.#nixosConfigurations.athena.config.fileSystems."/".device')" = '"none"'
