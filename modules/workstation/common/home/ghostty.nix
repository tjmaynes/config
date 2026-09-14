{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
    enableZshIntegration = true;
    installBatSyntax = true;
    installVimSyntax = true;
    settings = {
      "font-family" = "Inconsolata Nerd Font Mono";
      "font-size" = 16;
      theme = "Catppuccin Frappe";
    };
  };
}
