{
  config,
  lib,
  user,
  ...
}:
{
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

    ensureSyncthingLogDirectory = lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ] ''
      run mkdir -p -- "${user.homeDirectory}/Library/Logs/Syncthing"
    '';

    ensureICloudMailLogDirectory =
      lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
        ''
          run mkdir -p -- "${user.homeDirectory}/workspace/mailbox/logs"
          run chmod 700 -- "${user.homeDirectory}/workspace/mailbox/logs"
        '';
  };

  launchd.agents.sync-icloud-mail = {
    enable = true;
    config = {
      ProgramArguments = [ "${config.home.profileDirectory}/bin/sync-icloud-mail" ];
      EnvironmentVariables.HOME = user.homeDirectory;
      StartCalendarInterval = {
        Hour = 2;
        Minute = 0;
      };
      RunAtLoad = false;
      KeepAlive = false;
      ProcessType = "Background";
      StandardOutPath = "${user.homeDirectory}/workspace/mailbox/logs/stdout.log";
      StandardErrorPath = "${user.homeDirectory}/workspace/mailbox/logs/stderr.log";
    };
  };
}
