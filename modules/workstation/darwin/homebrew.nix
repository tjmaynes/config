{
  homebrew = {
    enable = true;
    casks = [
      "google-chrome"
      "obsidian"
      "tailscale-app"
    ];
    masApps = {
      Bitwarden = 1352778147;
    };
    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = false;
    };
  };
}
