#!/bin/sh
set -eu

nix_eval() {
  nix --extra-experimental-features 'nix-command flakes' eval --json "$1"
}

font_pnames() {
  nix --extra-experimental-features 'nix-command flakes' eval --json \
    --apply 'packages: map (package: package.pname) packages' "$1"
}

test "$(nix_eval '.#nixosConfigurations.athena.config.networking.hostName')" = '"athena"'
test "$(nix_eval '.#nixosConfigurations.athena.config.system.stateVersion')" = '"22.05"'
test "$(nix_eval '.#nixosConfigurations.athena.config.home-manager.users.tjmaynes.programs.emacs.enable')" = true
test "$(nix_eval '.#nixosConfigurations.athena.config.home-manager.users.tjmaynes.services.emacs.enable')" = true
test "$(nix_eval '.#nixosConfigurations.athena.config.fileSystems."/".device')" = '"none"'
font_pnames '.#nixosConfigurations.athena.config.fonts.packages' \
  | jq -e '
    index("nerd-fonts-iosevka") != null
    and index("nerd-fonts-inconsolata") != null
    and index("nerd-fonts-blex-mono") != null
    and index("linux-libertine") != null
    and index("libre-baskerville") != null
  ' >/dev/null
nix_eval '.#nixosConfigurations.athena.config.home-manager.users.tjmaynes.xsession.windowManager.i3.config.bars' \
  | jq -e '.[0].fonts.names == ["Inconsolata Nerd Font Mono"]' >/dev/null
