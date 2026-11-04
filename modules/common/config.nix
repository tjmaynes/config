# System settings shared by nix-darwin and NixOS.
_: {
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = false;
}
