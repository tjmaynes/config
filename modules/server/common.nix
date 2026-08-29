{ identity, pkgs, ... }:
{
  users.users.${identity.username} = {
    isNormalUser = true;
    createHome = true;
    home = "/home/${identity.username}";
    description = identity.fullName;
    extraGroups = [
      "wheel"
      "docker"
    ];
  };

  users.groups.docker = { };

  environment.systemPackages = with pkgs; [
    curl
    git
    jq
    vim
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = identity.timezone;
}
