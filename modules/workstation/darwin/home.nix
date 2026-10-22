{ lib, user, ... }:
{
  targets.darwin = {
    copyApps.enable = true;
    linkApps.enable = false;
  };

  home.activation.ensureScreencaptureDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p -- "${user.homeDirectory}/workspace/screencaptures"
  '';

  home.activation.ensureSyncthingLogDirectory =
    lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
      ''
        run mkdir -p -- "${user.homeDirectory}/Library/Logs/Syncthing"
      '';
}
