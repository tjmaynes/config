{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "kubectl"
      ];
    };
    shellAliases = {
      workspace = "cd $WORKSPACE_DIRECTORY";
      dotfiles = "cd $CODE_DIRECTORY/dotfiles";
      tm = "task-master";
      k = "kubectl";
      cat = "bat";
      ps = "procs";
    };
    initContent = ''
      kill-process-on-port() {
        local port="$1"
        local pid
        for pid in $(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null); do
          kill "$pid"
        done
      }

      convert-m4a-to-mp3() {
        ffmpeg -i "$1" -codec:a libmp3lame "''${1%.m4a}.mp3"
      }

      morning-paper() {
        mkdir -p "$WORKSPACE_DIRECTORY/morning-pages"
        vi "$WORKSPACE_DIRECTORY/morning-pages/$(date +%Y-%m-%d).md"
      }
    '';
  };
}
