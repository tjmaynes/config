{
  virtualisation = {
    docker.enable = true;
    docker.enableOnBoot = false;
    vmware.guest.enable = true;
  };

  networking.firewall.allowedTCPPorts = [ 6443 ];

  services.logind.settings.Login = {
    RuntimeDirectorySize = "8G";
  };
}
