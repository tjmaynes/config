#!/bin/sh
set -eu

nix_eval() {
  nix --extra-experimental-features 'nix-command flakes' eval --json "$1"
}

test "$(nix_eval '.#nixosConfigurations.atlas.config.networking.hostName')" = '"atlas"'
test "$(nix_eval '.#nixosConfigurations.atlas.pkgs.system')" = '"x86_64-linux"'
test "$(nix_eval '.#nixosConfigurations.atlas.config.system.stateVersion')" = '"26.05"'
test "$(nix_eval '.#nixosConfigurations.atlas.config.services.openssh.enable')" = 'true'
test "$(nix_eval '.#nixosConfigurations.atlas.config.networking.firewall.enable')" = 'true'
test "$(nix_eval '.#nixosConfigurations.atlas.config.users.users.tjmaynes.isNormalUser')" = 'true'
test "$(nix_eval '.#nixosConfigurations.atlas.config.users.groups.docker.name')" = '"docker"'
test "$(nix_eval '.#nixosConfigurations.atlas.config.virtualisation.docker.enable')" = 'true'
nix_eval '.#nixosConfigurations.atlas.config.boot.supportedFilesystems' | rg -q '"btrfs":true'
file_systems=$(nix_eval '.#nixosConfigurations.atlas.config.fileSystems')
test "$(printf '%s' "$file_systems" | jq -r 'keys | length')" = 1
test "$(printf '%s' "$file_systems" | jq -r '.["/"].device')" = none
nix --extra-experimental-features 'nix-command flakes' eval --raw \
  .#nixosConfigurations.atlas.config.system.build.toplevel.drvPath >/dev/null
