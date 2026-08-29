{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    bitwarden-desktop
    cmus
    feh
    gimp
    mpv
    mutt
    vscode
    virtualbox
    xclip
  ];

  xsession.enable = true;
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "Mod1";
      bars = [
        {
          id = "bar-0";
          position = "bottom";
          fonts = {
            names = [ "Inconsolata" ];
            size = 12.0;
          };
        }
      ];
    };
  };

  programs.emacs.enable = true;
  services.emacs.enable = true;
}
