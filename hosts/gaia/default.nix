{
  identity,
  pkgsUnstable,
  skillRepos,
  user,
  ...
}:
{
  imports = [ ../../modules/darwin ];

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
    extraSpecialArgs = {
      inherit
        identity
        pkgsUnstable
        skillRepos
        user
        ;
    };
    users.${identity.username} = {
      imports = [
        ../../modules/common/home
        ../../modules/darwin/home.nix
      ];

      home.stateVersion = "22.05";
    };
  };
}
