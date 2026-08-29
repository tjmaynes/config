{ identity, user, ... }:
{
  imports = [
    ../../modules/workstation/nixos
    ./hardware-eval.nix
  ];

  networking.hostName = "athena";
  time.timeZone = identity.timezone;
  system.stateVersion = "22.05";

  users.users.${identity.username} = {
    isNormalUser = true;
    home = "/home/${identity.username}";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit identity user; };
    users.${identity.username} = {
      imports = [
        ../../modules/workstation/common/home
        ../../modules/workstation/nixos/home
      ];
      home.stateVersion = "22.05";
    };
  };
}
