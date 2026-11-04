{
  identity,
  llm-agents,
  pkgsUnstable,
  skillRepos,
  user,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./secrets.nix
    ../../modules/nixos
  ];

  networking.hostName = "athena";
  nixpkgs.hostPlatform = "x86_64-linux";
  time.timeZone = identity.timezone;
  system.stateVersion = "26.05";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit
        identity
        llm-agents
        pkgsUnstable
        skillRepos
        user
        ;
    };
    users.${identity.username} = {
      imports = [ ../../modules/nixos/home.nix ];
      home.stateVersion = "26.05";
    };
  };
}
