#!/bin/sh
set -eu

nix_eval() {
  nix --extra-experimental-features 'nix-command flakes' eval --json "$1"
}

font_pnames() {
  nix --extra-experimental-features 'nix-command flakes' eval --json \
    --apply 'packages: map (package: package.pname) packages' "$1"
}

system_package_pnames() {
  nix --extra-experimental-features 'nix-command flakes' eval --json \
    --apply 'packages: map (package: package.pname or "") packages' "$1"
}

test "$(nix_eval '.#darwinConfigurations.gaia.config.networking.hostName')" = '"gaia"'
test "$(nix_eval '.#darwinConfigurations.gaia.config.system.stateVersion')" = '4'
test "$(nix_eval '.#darwinConfigurations.gaia.config.home-manager.users.tjmaynes.programs.emacs.enable')" = true
test "$(nix_eval '.#darwinConfigurations.gaia.config.home-manager.users.tjmaynes.services.emacs.enable')" = false
test "$(nix_eval '.#darwinConfigurations.gaia.config.system.defaults.screencapture.location')" = \
  '"/Users/tjmaynes/workspace/screencaptures"'
test "$(nix_eval '.#darwinConfigurations.gaia.config.system.defaults.NSGlobalDomain.AppleInterfaceStyle')" = '"Dark"'
test "$(nix_eval '.#darwinConfigurations.gaia.config.system.defaults.NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically')" = false
test "$(nix_eval '.#darwinConfigurations.gaia.config.system.defaults.NSGlobalDomain.AppleKeyboardUIMode')" = '2'
screencapture_activation=$(nix --extra-experimental-features 'nix-command flakes' eval --raw \
  '.#darwinConfigurations.gaia.config.home-manager.users.tjmaynes.home.activation.ensureScreencaptureDirectory.data')
printf '%s' "$screencapture_activation" | \
  rg -Fq 'run mkdir -p -- "/Users/tjmaynes/workspace/screencaptures"'
system_packages=$(system_package_pnames '.#darwinConfigurations.gaia.config.environment.systemPackages')
for package in ghostty-bin obsidian google-chrome bitwarden-desktop
do
  printf '%s' "$system_packages" | jq -e --arg package "$package" 'index($package) != null' >/dev/null
done
nix_eval '.#darwinConfigurations.gaia.config.homebrew.casks' | jq -e \
  'map(.name) == ["tailscale-app", "obs"]' >/dev/null
test "$(font_pnames '.#darwinConfigurations.gaia.config.fonts.packages')" = \
  '["nerd-fonts-iosevka","nerd-fonts-inconsolata","nerd-fonts-blex-mono","linux-libertine","libre-baskerville"]'

# Keep this contract test evaluation-only so it can run on Linux CI. The
# platform-specific Gaia build runs in the Darwin workflow job.
nix --extra-experimental-features 'nix-command flakes' eval --raw \
  .#darwinConfigurations.gaia.config.system.build.toplevel.drvPath >/dev/null
