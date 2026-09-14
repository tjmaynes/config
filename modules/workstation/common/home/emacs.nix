{
  home.file = {
    ".local/state/emacs/auto-save/.keep".text = "";
    ".local/state/emacs/backups/.keep".text = "";
  };

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
      (defconst tjmaynes/emacs-state-directory
        (expand-file-name ".local/state/emacs/" (getenv "HOME")))
      (defconst tjmaynes/org-directory
        (expand-file-name "workspace/code/tjmaynes/notebook/" (getenv "HOME")))

      (setq inhibit-splash-screen t
            initial-scratch-message ""
            ring-bell-function 'ignore
            visible-bell nil
            scroll-step 1000
            scroll-conservatively 1000
            redisplay-dont-pause t
            scroll-preserve-screen-position 1
            display-time-day-and-date t
            mode-require-final-newline t
            backup-by-copying t
            backup-directory-alist
            `((".*" . ,(expand-file-name "backups/" tjmaynes/emacs-state-directory)))
            auto-save-file-name-transforms
            `((".*" ,(expand-file-name "auto-save/" tjmaynes/emacs-state-directory) t))
            delete-old-versions t
            kept-new-versions 6
            kept-old-versions 2
            version-control t)

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
      (load-theme 'zenburn t)

      (require 'auto-complete-config)
      (ac-config-default)

      (add-hook 'emacs-lisp-mode-hook
        (lambda ()
          (paredit-mode 1)
          (prettify-symbols-mode 1)
          (show-paren-mode 1)))

      (setq web-mode-markup-indent-offset 2
            web-mode-code-indent-offset 2
            web-mode-css-indent-offset 2
            web-mode-enable-auto-pairing t
            web-mode-enable-auto-expanding t
            web-mode-enable-css-colorization t)
      (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))

      (setq org-directory tjmaynes/org-directory
            org-default-notes-file (expand-file-name "inbox.org" org-directory)
            org-startup-truncated nil
            org-columns-default-format "%50ITEM(Task) %10CLOCKSUM %16TIMESTAMP_IA"
            org-capture-templates
            `(("t" "Todo" entry (file ,org-default-notes-file)
               "* TODO %?\n%u\n%a\n" :clock-in t :clock-resume t)
              ("m" "Meeting" entry (file ,org-default-notes-file)
               "* MEETING with %? :MEETING:\n%t" :clock-in t :clock-resume t)
              ("i" "Idea" entry (file ,org-default-notes-file)
               "* %? :IDEA: \n%t")
              ("n" "Next Task" entry
               (file+headline ,(expand-file-name "tasks.org" org-directory) "Tasks")
               "** NEXT %? \nDEADLINE: %t"))
            org-todo-keywords
            '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)")
              (sequence "WAITING(w@/!)" "INACTIVE(i@/)" "|" "CANCELLED(c@/!)" "MEETING"))
            org-todo-state-tags-triggers
            '(("CANCELLED" ("CANCELLED" . t))
              ("WAITING" ("WAITING" . t))
              ("INACTIVE" ("WAITING") ("INACTIVE" . t))
              (done ("WAITING") ("INACTIVE"))
              ("TODO" ("WAITING") ("CANCELLED") ("INACTIVE"))
              ("NEXT" ("WAITING") ("CANCELLED") ("INACTIVE"))
              ("DONE" ("WAITING") ("CANCELLED") ("INACTIVE")))
            org-todo-keyword-faces
            '(("TODO" :foreground "red" :weight bold)
              ("NEXT" :foreground "blue" :weight bold)
              ("DONE" :foreground "forest green" :weight bold)
              ("WAITING" :foreground "orange" :weight bold)
              ("INACTIVE" :foreground "magenta" :weight bold)
              ("CANCELLED" :foreground "forest green" :weight bold)
              ("MEETING" :foreground "forest green" :weight bold)))

      (setq ispell-program-name "aspell"
            ispell-extra-args '("--sug-mode=ultra" "--lang=en_US")
            ispell-personal-dictionary nil)
      (add-to-list 'ispell-skip-region-alist '(":\\(PROPERTIES\\|LOGBOOK\\):" . ":END:"))
      (add-to-list 'ispell-skip-region-alist '("#\\+begin_src" . "#\\+end_src"))
      (add-to-list 'ispell-skip-region-alist '("#\\+begin_quote" . "#\\+end_quote"))

      (global-set-key (kbd "C-c g") 'magit-status)
      (global-set-key (kbd "C-c t") 'multi-term)
      (global-set-key (kbd "C-x <left>") 'windmove-left)
      (global-set-key (kbd "C-x <right>") 'windmove-right)
      (global-set-key (kbd "C-x <up>") 'windmove-up)
      (global-set-key (kbd "C-x <down>") 'windmove-down)

      (when (display-graphic-p)
        (set-face-attribute 'default nil :family "Inconsolata Nerd Font Mono" :height 160))
    '';
  };
}
