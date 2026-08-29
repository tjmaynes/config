{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    codex
    curl
    ffmpeg
    gh
    gnupg
    htop
    jq
    libwebp
    openssh
    pandoc
    procs
    ripgrep
    shfmt
    tree
    watchman
  ];
}
