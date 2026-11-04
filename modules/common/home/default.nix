{
  identity,
  lib,
  user,
  ...
}:
{
  imports = [
    ./ai.nix
    ./emacs.nix
    ./git.nix
    ./gnupg.nix
    ./mise.nix
    ./packages.nix
    ./zsh.nix
    ./tmux.nix
    ./vim.nix
  ];

  home = {
    inherit (identity) username;
    inherit (user) homeDirectory;
    stateVersion = lib.mkDefault "22.05";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
