{ identity, user, ... }:
{
  imports = [
    ./agent-skills.nix
    ./git.nix
    ./emacs.nix
    ./gnupg.nix
    ./terminal.nix
    ./mise.nix
    ./mail.nix
    ./packages.nix
    ./zsh.nix
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

  services.syncthing = {
    enable = true;
    # Keep devices and folders configured through the local web interface.
    overrideDevices = false;
    overrideFolders = false;
  };

  programs = {
    atuin.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
