{
  lib,
  user,
  ...
}:
{
  imports = [
    ./mail.nix
    ./terminal.nix
    ./vscode.nix
  ];

  home.sessionVariables.EDITOR = lib.mkDefault "code";

  programs = {
    cursor.enable = true;
    mpv.enable = true;
    zsh.initContent = lib.mkAfter ''
      if [[ $options[zle] = on ]] && [[ -x /opt/homebrew/bin/atuin ]]; then
        eval "$(/opt/homebrew/bin/atuin init zsh)"
      fi
    '';
  };

  launchd.agents.open-chatgpt = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/open"
        "/Applications/ChatGPT.app"
      ];
      LimitLoadToSessionType = "Aqua";
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  targets.darwin = {
    copyApps.enable = true;
    linkApps.enable = false;
  };

  home.activation = {
    ensureScreencaptureDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p -- "${user.homeDirectory}/workspace/screencaptures"
    '';

  };
}
