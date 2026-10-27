{ pkgs, ... }:
{
  home.packages = with pkgs; [
    aspell
    bat
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
    vagrant
  ];
}
