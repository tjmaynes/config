{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  security.sudo.wheelNeedsPassword = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };
}
