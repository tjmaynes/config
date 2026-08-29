#!/bin/sh
set -eu

for heading in Bootstrap Update Check Build Activate Rollback Secrets Mise Hardware
do
  rg -q "^## $heading" README.md
done

rg -q 'gaia' README.md
rg -q 'athena' README.md
rg -q 'make bootstrap-gaia' README.md
rg -q 'make switch-gaia' README.md
if rg -q 'apollo|demeter|kratos' README.md; then exit 1; fi
test -f .github/workflows/check.yml
rg -q 'nix-installer-action' .github/workflows/check.yml
if rg -q 'darwin-rebuild switch|nixos-rebuild switch' .github/workflows/check.yml; then exit 1; fi
rg -q 'cleanup remains `none`' README.md
rg -q 'hardware-eval.nix' README.md
