_: {
  # Evaluation-only placeholder. Replace with generated hardware
  # configuration after Atlas hardware has been inventoried.
  boot.isContainer = true;
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };
  nixpkgs.hostPlatform = "x86_64-linux";
}
