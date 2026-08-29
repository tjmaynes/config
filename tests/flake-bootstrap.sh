#!/bin/sh
set -eu

nix --extra-experimental-features 'nix-command flakes' flake metadata --json >/dev/null
nix --extra-experimental-features 'nix-command flakes' flake check --no-build --all-systems
