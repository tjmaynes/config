{ lib, user, ... }:
{
  home.activation.ensureScreencaptureDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p -- "${user.homeDirectory}/workspace/screencaptures"
  '';
}
