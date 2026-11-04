{ lib, user, ... }:
{
  services.syncthing = {
    enable = true;
    # Keep devices and folders configured through the local web interface.
    overrideDevices = false;
    overrideFolders = false;
  };

  home.activation.ensureSyncthingLogDirectory =
    lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
      ''
        run mkdir -p -- "${user.homeDirectory}/Library/Logs/Syncthing"
      '';
}
