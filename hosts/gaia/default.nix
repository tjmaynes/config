{ identity, user, ... }:
{
  imports = [ ../../modules/workstation/darwin ];

  networking.hostName = "gaia";
  networking.computerName = "gaia";
  system.primaryUser = identity.username;
  system.stateVersion = 4;
  ids.gids.nixbld = 350;

  users.users.${identity.username} = {
    home = "/Users/${identity.username}";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit identity user; };
    users.${identity.username} = {
      imports = [
        ../../modules/workstation/common/home
        ../../modules/workstation/darwin/home
      ];
      home.stateVersion = "22.05";
    };
  };
}
