{
  # Evaluation-only placeholder. Generate and review real hardware.nix on Athena
  # before any deployment or switch operation.
  boot.isContainer = true;
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };
}
