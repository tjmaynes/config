#!/bin/sh
set -eu

nix_eval() {
  nix --extra-experimental-features 'nix-command flakes' eval --json "$1"
}

rg -q 'url = "github:obra/superpowers/main";' flake.nix
rg -q 'url = "github:tjmaynes/skills/main";' flake.nix
jq -e '
  .nodes.superpowers.flake == false
  and .nodes["tjmaynes-skills"].flake == false
' flake.lock >/dev/null
rg -q '^update:' Makefile
rg -q '^\t\$\(NIX\) flake update$' Makefile

nix --extra-experimental-features 'nix-command flakes' eval \
  --impure --json --file tests/agent-skills.nix \
  | jq -e 'all(.[]; .)' >/dev/null

flake_path=$(pwd)
superpowers_source=$(nix --extra-experimental-features 'nix-command flakes' eval \
  --impure --raw --expr "(builtins.getFlake \"$flake_path\").inputs.superpowers.outPath")
tjmaynes_skills_source=$(nix --extra-experimental-features 'nix-command flakes' eval \
  --impure --raw --expr "(builtins.getFlake \"$flake_path\").inputs.tjmaynes-skills.outPath")

for prefix in \
  '.#darwinConfigurations.gaia.config.home-manager.users.tjmaynes' \
  '.#nixosConfigurations.athena.config.home-manager.users.tjmaynes'
do
  test "$(nix_eval "$prefix.home.file.\".agents/skills/brainstorming\".source")" = \
    "\"$superpowers_source/skills/brainstorming\""
  test "$(nix_eval "$prefix.home.file.\".agents/skills/agent-context-generator\".source")" = \
    "\"$tjmaynes_skills_source/skills/agent-context-generator\""
done
