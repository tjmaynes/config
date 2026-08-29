{
  programs.emacs = {
    enable = true;
    extraPackages =
      epkgs: with epkgs; [
        auto-complete
        circadian
        dockerfile-mode
        json-mode
        k8s-mode
        magit
        markdown-mode
        multi-term
        org
        org-journal
        paredit
        solarized-theme
        web-mode
        yaml-mode
        zenburn-theme
      ];
    extraConfig = ''
      (setq inhibit-splash-screen t
            initial-scratch-message ""
            ring-bell-function 'ignore
            visible-bell nil
            scroll-step 1
            scroll-conservatively 1000
            display-time-day-and-date t
            mode-require-final-newline t)

      (prefer-coding-system 'utf-8)
      (set-default-coding-systems 'utf-8)
      (set-terminal-coding-system 'utf-8)
      (set-keyboard-coding-system 'utf-8)

      (tool-bar-mode -1)
      (menu-bar-mode -1)
      (when (fboundp 'scroll-bar-mode)
        (scroll-bar-mode -1))
      (display-time)
      (ido-mode 1)
      (fset 'yes-or-no-p 'y-or-n-p)

      (add-hook 'emacs-lisp-mode-hook
        (lambda ()
          (paredit-mode 1)
          (prettify-symbols-mode 1)
          (show-paren-mode 1)))

      (setq web-mode-markup-indent-offset 2
            web-mode-code-indent-offset 2
            web-mode-css-indent-offset 2)
      (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))

      (setq org-startup-truncated nil)
      (setq org-columns-default-format "%50ITEM(Task) %10CLOCKSUM %16TIMESTAMP_IA")

      (when (display-graphic-p)
        (set-face-attribute 'default nil :family "Inconsolata" :height 160))
    '';
  };
}
