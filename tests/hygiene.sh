#!/bin/sh
set -eu

for path in \
  hosts/apollo.nix hosts/demeter.nix hosts/gaia.nix hosts/athena.nix \
  hosts/kratos.sh modules/common/default.nix modules/common/nixpkgs.nix \
  modules/common/settings.nix modules/home-manager/default.nix \
  scripts/install.sh scripts/reload.sh
do
  test ! -e "$path"
done

if grep -R -n -E \
  'NIX_PATH|builtins\.getEnv|<home-manager|config/dotfiles|bash_onstart' \
  modules hosts Makefile; then
  echo "forbidden legacy dependency found" >&2
  exit 1
fi

nix --extra-experimental-features 'nix-command flakes' eval --raw .#darwinConfigurations.gaia.config.networking.hostName | rg -q '^gaia$'
nix --extra-experimental-features 'nix-command flakes' eval --raw .#nixosConfigurations.athena.config.networking.hostName | rg -q '^athena$'
if nix --extra-experimental-features 'nix-command flakes' flake show --all-systems 2>&1 | rg -q 'apollo|demeter|kratos'; then
  exit 1
fi
