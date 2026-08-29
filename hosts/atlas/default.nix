_: {
  imports = [
    ./hardware-eval.nix
    ../../modules/server
  ];

  networking.hostName = "atlas";
  system.stateVersion = "26.05";
}
