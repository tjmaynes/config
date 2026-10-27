# VS Code Home Manager configuration design

## Intent

Make Visual Studio Code a user-level, declarative Home Manager program on Gaia, while disabling built-in Copilot and other AI features. Preserve existing extensions, keybindings, and workspace configuration.

## Goals

- Enable `pkgs.vscode` through Home Manager's `programs.vscode` module.
- Declaratively manage the approved VS Code user settings, including disabling
  AI features and VS Code self-updates.
- Install the approved extension list declaratively.
- Remove duplicate `vscode` package declarations from Home Manager packages and Darwin system packages.

## Non-goals

- Do not manage profiles, snippets, keybindings, or workspace settings.
- Do not activate the host configuration.

## Approaches

1. Minimal declarative baseline (selected): manage the package and approved settings with Home Manager while preserving existing extensions and other user state.
2. Fully declarative editor configuration: additionally manage extensions, keybindings, and all settings; rejected because it requires a separate migration decision.
3. Direct `home.file` settings: rejected because it duplicates the upstream VS Code module and leaves package ownership unclear.

## Design

Create `modules/workstation/common/home/vscode.nix` as the focused module. It accepts `config` so the Go alternate-tool path uses `${config.xdg.dataHome}`. Mise installs user tools beneath `${config.xdg.dataHome}/mise/installs`; the repository pins Go to `1.27.0`, so the setting targets that exact version rather than `latest`. Import the module from the common Home Manager module.

Use only extensions available from pinned `nixpkgs`. The requested Tailwind
Docs, Crontab Syntax Highlight, Mermaid Chart, HTMX Tags, and Pytest Runner
extensions remain unmanaged because they require an additional Marketplace
registry input.

```nix
programs.vscode = {
  enable = true;
  profiles.default.userSettings = {
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
    "go.alternateTools".go = "${config.xdg.dataHome}/mise/installs/go/1.27.0/bin/go";
    "go.toolsManagement.autoUpdate" = true;
    "python.terminal.activateEnvironment" = false;
    "python.terminal.activateEnvInCurrentTerminal" = false;
  };
};
```

The `profiles.default.extensions` list contains every requested extension
available in the pinned package set.

Remove standalone `vscode` entries from `packages.nix` and Darwin system packages. Add a file-only unit test covering the import, settings contract, Nix-derived Go path, and removal of duplicate package ownership.

## Constraints

- Use `programs.vscode.profiles.default.userSettings`, the profile API exposed
  by the repository's pinned Home Manager revision.
- Validate through the Makefile.
- Do not run activation commands.
