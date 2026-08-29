{ pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      desktopManager.xterm.enable = false;
      windowManager.i3.enable = true;
      autoRepeatDelay = 250;
    };
    displayManager.defaultSession = "none+i3";
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  security.rtkit.enable = true;

  environment.variables = {
    GDK_SCALE = "3.0";
    GDK_DPI_SCALE = "0.25";
  };

  fonts.packages = with pkgs; [
    corefonts
    inconsolata
    libertine
    libre-baskerville
  ];
}
