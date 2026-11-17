{
  identity,
  pkgs,
  user,
  ...
}:
{
  imports = [
    ../common/config.nix
    ./development.nix
  ];

  users.users.${identity.username} = {
    isNormalUser = true;
    description = identity.fullName;
    home = user.homeDirectory;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
    # Add authorized public keys here before installation.
    openssh.authorizedKeys.keys = [ ];
  };
  programs.zsh.enable = true;
  networking.useDHCP = true;

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  services.tailscale = {
    enable = true;
    openFirewall = true;
    # Let NixOS filter incoming tailnet traffic instead of Tailscale's
    # default accept-all rule. These settings also apply to manual enrollment.
    extraSetFlags = [
      "--accept-dns=false"
      "--netfilter-mode=nodivert"
    ];
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    22
    8080
  ];
}
