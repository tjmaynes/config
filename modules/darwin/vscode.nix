{
  config,
  pkgs,
  pkgsUnstable,
  ...
}:
let
  vscode = import ../common/vscode.nix {
    inherit pkgs;
    dataHome = config.xdg.dataHome;
  };
in
{
  programs.vscode = {
    enable = true;
    package = pkgsUnstable.vscode;
    profiles.default = {
      inherit (vscode) userSettings;
      extensions = vscode.extensions ++ vscode.desktopExtensions;
    };
  };
}
