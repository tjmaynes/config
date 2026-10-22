{
  pkgs,
  user,
  ...
}:
{
  imports = [
    ../common/nix.nix
  ];

  environment = {
    shells = with pkgs; [ zsh ];
    systemPackages = with pkgs; [
      ghostty-bin
      obsidian
      bitwarden-desktop
      vscode
    ];
    pathsToLink = [ "/Applications" ];
  };

  homebrew = {
    enable = true;
    casks = [
      "chatgpt"
      "docker-desktop"
      "signal"
      "vcv-rack"
      "tailscale-app"
      "obs"
      "spotify"
      "virtualbox"
      "imageoptim"
      "zen"
    ];
    onActivation = {
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };
  };

  fonts.packages = with pkgs; [
    nerd-fonts.iosevka
    nerd-fonts.inconsolata
    nerd-fonts.blex-mono
    libertine
    libre-baskerville
  ];

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  system.defaults = {
    screencapture.location = "${user.homeDirectory}/workspace/screencaptures";

    dock = {
      autohide = true;
      orientation = "bottom";
      showhidden = true;
      mineffect = "genie";
      launchanim = true;
      show-process-indicators = true;
      tilesize = 48;
      static-only = true;
      mru-spaces = false;
      show-recents = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      CreateDesktop = false;
    };

    loginwindow = {
      GuestEnabled = false;
      DisableConsoleAccess = true;
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = false;
      AppleKeyboardUIMode = 2;
      ApplePressAndHoldEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      _HIHideMenuBar = false;
    };
  };

  networking.applicationFirewall = {
    enable = true;
    blockAllIncoming = false;
    enableStealthMode = true;
  };
}
