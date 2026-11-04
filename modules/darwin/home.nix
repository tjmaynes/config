{
  lib,
  user,
  ...
}:
{
  imports = [
    ./mail.nix
    ./syncthing.nix
    ./terminal.nix
    ./vscode.nix
  ];

  home.sessionVariables.EDITOR = lib.mkDefault "code";

  programs.mpv.enable = true;

  targets.darwin = {
    copyApps.enable = true;
    linkApps.enable = false;
  };

  programs.zsh.initContent = lib.mkAfter ''
    if [[ $options[zle] = on ]] && [[ -x /opt/homebrew/bin/atuin ]]; then
      eval "$(/opt/homebrew/bin/atuin init zsh)"
    fi
  '';

  home.activation = {
    ensureScreencaptureDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p -- "${user.homeDirectory}/workspace/screencaptures"
    '';

  };
}
