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
    ./vscode.nix
    ./zsh.nix
    ./tmux.nix
    ./vim.nix
  ];

  home = {
    inherit (identity) username;
    inherit (user) homeDirectory;
    stateVersion = "22.05";
    sessionVariables = {
      EDITOR = "code";
    };
  };

  services.syncthing = {
    enable = true;
    # Keep devices and folders configured through the local web interface.
    overrideDevices = false;
    overrideFolders = false;
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
