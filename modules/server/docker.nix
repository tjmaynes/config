{ pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  # Docker group membership is intentionally explicit: it grants
  # root-equivalent access and is required by the existing Compose workflow.
  users.users.tjmaynes.extraGroups = [ "docker" ];
  environment.systemPackages = [ pkgs.docker-compose ];
}
