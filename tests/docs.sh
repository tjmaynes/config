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
rg -q '/Applications/Nix Apps' README.md
rg -q 'hardware-eval.nix' README.md

for path in \
  hosts/atlas \
  modules/server \
  scripts/deploy-atlas.sh \
  tests/atlas.sh \
  docs/atlas-cutover-runbook.md \
  docs/atlas-operations.md \
  plans/003-atlas-server-foundation \
  plans/004-atlas-nixos-docker-migration \
  plans/005-home-server-repository-extraction \
  renovate.json5
do
  test ! -e "$path"
done

if rg -n -i 'atlas|sops-nix' README.md AGENTS.md Makefile flake.nix flake.lock \
  .github .gitignore
then
  echo "Atlas reference remains in root configuration" >&2
  exit 1
fi
