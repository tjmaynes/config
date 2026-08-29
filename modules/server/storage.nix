{ pkgs, ... }:
{
  # Atlas storage is intentionally hardware-agnostic during evaluation. Do
  # not add fileSystems, device paths, UUIDs, RAID, or formatting commands
  # until the physical inventory has been reviewed.
  boot.supportedFilesystems = [ "btrfs" ];
  environment.systemPackages = [ pkgs.btrfs-progs ];
}
