{
  config,
  identity,
  lib,
  pkgs,
  llm-agents,
  user,
  ...
}:
let
  codex = config.home-manager.users.${identity.username}.programs.codex.package;
  orca = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.orca;
  vscode = import ../common/vscode.nix {
    inherit pkgs;
    dataHome = config.home-manager.users.${identity.username}.xdg.dataHome;
  };
  serviceEnvironment = {
    HOME = user.homeDirectory;
    CODEX_HOME = "${user.homeDirectory}/.codex";
    SHELL = "${pkgs.zsh}/bin/zsh";
    PATH = lib.mkForce (
      lib.concatStringsSep ":" [
        "${user.homeDirectory}/.local/share/mise/shims"
        "/etc/profiles/per-user/${identity.username}/bin"
        "/run/wrappers/bin"
        "/run/current-system/sw/bin"
        (lib.makeBinPath [
          pkgs.coreutils
          pkgs.git
          pkgs.openssh
          pkgs.nodejs
        ])
      ]
    );
  };
in
{
  home-manager.users.${identity.username} = {
    home.packages = with pkgs; [
      gcc
      gnumake
      pkg-config
      nodejs
      ripgrep
      fd
      lsof
      procs
    ];
    xdg.dataFile."code-server/User/settings.json".text = builtins.toJSON vscode.userSettings;
  };

  # Home Manager's pinned/current Codex module manages config, not a boot
  # service. Keep the missing lifecycle integration here, with upstream CLI.
  systemd.services = {
    codex = {
      description = "Persistent Codex app server";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "home-manager-${identity.username}.service"
      ];
      requires = [ "home-manager-${identity.username}.service" ];
      environment = serviceEnvironment;
      serviceConfig = {
        User = identity.username;
        Group = "users";
        WorkingDirectory = user.homeDirectory;
        RuntimeDirectory = "codex";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        ExecStart = "${lib.getExe codex} app-server --listen unix:///run/codex/app-server.sock";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # Home Manager has no Orca module; use upstream's headless serve command.
    orca = {
      description = "Orca headless runtime";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "home-manager-${identity.username}.service"
      ];
      requires = [ "home-manager-${identity.username}.service" ];
      environment = builtins.removeAttrs serviceEnvironment [ "CODEX_HOME" ];
      serviceConfig = {
        User = identity.username;
        Group = "users";
        WorkingDirectory = user.homeDirectory;
        UMask = "0077";
        ExecStart = "${lib.getExe orca} serve --port 6768 --pairing-address athena";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    code-server = {
      after = [ "home-manager-${identity.username}.service" ];
      requires = [ "home-manager-${identity.username}.service" ];
      environment = builtins.removeAttrs serviceEnvironment [ "CODEX_HOME" ];
      serviceConfig.EnvironmentFile = "/var/lib/athena/code-server.env";
    };
  };

  services.code-server = {
    enable = true;
    package = pkgs.vscode-with-extensions.override {
      vscode = pkgs.code-server;
      vscodeExtensions = vscode.extensions ++ vscode.codeServerExtensions;
    };
    user = identity.username;
    group = "users";
    host = "0.0.0.0";
    port = 8080;
    auth = "password";
    disableTelemetry = true;
    disableUpdateCheck = true;
    extraArguments = [ "${user.homeDirectory}/workspace" ];
  };
}
