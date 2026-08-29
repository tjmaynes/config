{
  programs.tmux = {
    enable = true;
    escapeTime = 0;
    historyLimit = 8000;
    keyMode = "vi";
    mouse = true;
    newSession = true;
    terminal = "screen-256color";
    prefix = "C-g";
    extraConfig = ''
      set -g base-index 1
      setw -g pane-base-index 1
      set -g monitor-activity on
      set -g visual-activity on
      set -g status-interval 1
      set -g status-justify centre
      set -g status-left-length 20
      set -g status-right-length 140
      set -g status-style "fg=white,bg=black"
      set -ag terminal-overrides ',screen*:cvvis=\\E[34l\\E[?25h'
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind m set-window-option main-pane-height 60 \; select-layout main-horizontal
      bind a send-prefix
      bind \\ split-window -h
      bind - split-window
      bind C command-prompt -p "Name of new window: " "new-window -n '%%'"
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "reloaded"
    '';
  };
}
