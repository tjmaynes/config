{ pkgs, pkgsUnstable, ... }:
{
  home.packages = with pkgs; [
    aspell
    bat
    pkgsUnstable.codex
    curl
    ffmpeg
    gh
    gnupg
    htop
    jq
    openssh
    pandoc
    shfmt
    tree
    vscode
  ];
}
