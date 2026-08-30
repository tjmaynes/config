#!/bin/sh
set -eu

nix_eval() {
  nix --extra-experimental-features 'nix-command flakes' eval --json "$1"
}

gaia_emacs=$(nix_eval '.#darwinConfigurations.gaia.config.home-manager.users.tjmaynes.programs.emacs.enable')
athena_emacs=$(nix_eval '.#nixosConfigurations.athena.config.home-manager.users.tjmaynes.programs.emacs.enable')
test "$gaia_emacs" = true
test "$athena_emacs" = true

check_delta() {
  prefix=$1

  test "$(nix_eval "$prefix.programs.delta.options.navigate")" = true
  test "$(nix_eval "$prefix.programs.delta.options.side-by-side")" = true
  test "$(nix_eval "$prefix.programs.delta.options.line-numbers")" = true
  test "$(nix_eval "$prefix.programs.git.iniContent.merge.conflictStyle")" = '"zdiff3"'
  case "$(nix_eval "$prefix.programs.git.iniContent.interactive.diffFilter")" in
    *"delta --color-only"*) : ;;
    *) return 1 ;;
  esac
  case "$(nix_eval "$prefix.programs.git.iniContent.pager.diff")" in
    *delta*) : ;;
    *) return 1 ;;
  esac
  nix_eval "$prefix.programs.git.iniContent" | jq -e 'has("diff") | not' >/dev/null
}

check_delta '.#darwinConfigurations.gaia.config.home-manager.users.tjmaynes'
check_delta '.#nixosConfigurations.athena.config.home-manager.users.tjmaynes'

rg -q '^[[:space:]]+gh$' modules/workstation/common/home/packages.nix

rg -q 'workspace = "cd \$WORKSPACE_DIRECTORY"' modules/workstation/common/home/shells.nix
rg -q 'kill-process-on-port\(\)' modules/workstation/common/home/shells.nix
rg -q 'prefix = "C-g"' modules/workstation/common/home/tmux.nix
rg -q 'bind m set-window-option main-pane-height' modules/workstation/common/home/tmux.nix
rg -q 'set -g base-index 1' modules/workstation/common/home/tmux.nix
rg -q 'set autochdir' modules/workstation/common/home/vim.nix
rg -q 'python = "3.14.7"' modules/workstation/common/home/mise.nix
rg -q 'node = "24.20.0"' modules/workstation/common/home/mise.nix
rg -q 'kubectl = "1.37.0"' modules/workstation/common/home/mise.nix
rg -q 'go = "1.27.0"' modules/workstation/common/home/mise.nix
if rg -q 'bun' modules/workstation/common/home/mise.nix; then exit 1; fi
rg -q 'plugins = with pkgs.vimPlugins' modules/workstation/common/home/vim.nix
for plugin in nerdtree ctrlp-vim vim-fugitive vim-commentary vim-surround vim-gnupg editorconfig-vim papercolor-theme vim-markdown goyo-vim vim-pencil
do
  rg -q "^[[:space:]]+$plugin$" modules/workstation/common/home/vim.nix
done
rg -q 'set synmaxcol=300' modules/workstation/common/home/vim.nix
rg -q 'NERDTreeShowHidden' modules/workstation/common/home/vim.nix
rg -q 'pencil#init' modules/workstation/common/home/vim.nix
rg -q 'PyJSONPretty' modules/workstation/common/home/vim.nix

if rg -n \
  --glob '*.nix' \
  --glob '*.sh' \
  --glob '!tests/*.sh' \
  '\.emacs\.json|package-install|package-refresh-contents|chat server|password|<home-manager|config/dotfiles' \
  modules hosts tests; then
  echo "forbidden private or imperative Emacs configuration found" >&2
  exit 1
fi
