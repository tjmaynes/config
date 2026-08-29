{ identity, user, ... }:
{
  imports = [
    ./git.nix
    ./emacs.nix
    ./mise.nix
    ./packages.nix
    ./shells.nix
    ./tmux.nix
    ./vim.nix
  ];

  home = {
    inherit (identity) username;
    inherit (user) homeDirectory;
    stateVersion = "22.05";
    sessionVariables = {
      WORKSPACE_DIRECTORY = "${user.homeDirectory}/workspace";
      CODE_DIRECTORY = "${user.homeDirectory}/workspace/code";
      EDITOR = "vi";
    };
  };

  programs = {
    atuin.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
