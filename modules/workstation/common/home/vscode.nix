{
  config,
  pkgs,
  ...
}:
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      userSettings = {
        "files.autoSave" = "afterDelay";
        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        "editor.fontFamily" = "Inconsolata Nerd Font";
        "editor.fontSize" = 16;
        "editor.tabCompletion" = "on";

        "terminal.integrated.fontFamily" = "Inconsolata Nerd Font";
        "terminal.integrated.fontSize" = 14;
        "terminal.integrated.tabs.location" = "left";

        "git.autofetch" = true;
        "git.openRepositoryInParentFolders" = "never";

        "workbench.accounts.showAvatar" = false;
        "workbench.activityBar.compact" = true;
        "workbench.colorTheme" = "Dark Modern";
        "workbench.secondarySideBar.defaultVisibility" = "hidden";
        "workbench.startupEditor" = "none";

        "chat.disableAIFeatures" = true;
        "update.mode" = "none";
        "update.showReleaseNotes" = false;

        "docker.extension.enableComposeLanguageServer" = false;
        "makefile.configureOnOpen" = false;
        "redhat.telemetry.enabled" = false;

        "go.alternateTools" = {
          go = "${config.xdg.dataHome}/mise/installs/go/1.27.0/bin/go";
        };
        "go.toolsManagement.autoUpdate" = true;

        "python.terminal.activateEnvironment" = false;
        "python.terminal.activateEnvInCurrentTerminal" = false;
      };

      extensions = with pkgs.vscode-extensions; [
        astro-build.astro-vscode
        bradlc.vscode-tailwindcss
        cameron.vscode-pytest
        christian-kohler.npm-intellisense
        davidanson.vscode-markdownlint
        docker.docker
        github.vscode-github-actions
        golang.go
        hashicorp.terraform
        jnoortheen.nix-ide
        ms-azuretools.vscode-containers
        ms-azuretools.vscode-docker
        ms-kubernetes-tools.vscode-kubernetes-tools
        ms-python.debugpy
        ms-python.isort
        ms-python.python
        ms-python.vscode-pylance
        ms-python.vscode-python-envs
        ms-toolsai.jupyter-renderers
        ms-vscode-remote.remote-containers
        ms-vscode.makefile-tools
        nefrob.vscode-just-syntax
        redhat.vscode-yaml
        rust-lang.rust-analyzer
        tamasfe.even-better-toml
        tauri-apps.tauri-vscode
        timonwong.shellcheck
        tomoki1207.pdf
        vitest.explorer
      ];
    };
  };
}
