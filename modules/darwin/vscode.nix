{ config, pkgs, ... }:
let
  vscode = import ../common/vscode.nix {
    inherit pkgs;
    dataHome = config.xdg.dataHome;
  };
in
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      inherit (vscode) userSettings;
      extensions = vscode.extensions ++ vscode.desktopExtensions;
    };
  };
}
