{ identity, pkgs, ... }:
{
  imports = [
    ../common/nix.nix
    ./desktop.nix
    ./services.nix
  ];

  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;
  networking.networkmanager.enable = true;

  users.users.${identity.username} = {
    isNormalUser = true;
    createHome = true;
    home = "/home/${identity.username}";
    description = identity.fullName;
    extraGroups = [
      "audio"
      "docker"
      "networkmanager"
      "video"
      "wheel"
    ];
    uid = 1000;
    shell = pkgs.zsh;
  };
}
