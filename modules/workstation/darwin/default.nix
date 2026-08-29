{ pkgs, ... }:
{
  imports = [
    ../common/nix.nix
    ./preferences.nix
    ./homebrew.nix
  ];

  environment = {
    shells = with pkgs; [ zsh ];
    systemPackages = with pkgs; [ vim ];
    pathsToLink = [ "/Applications" ];
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
