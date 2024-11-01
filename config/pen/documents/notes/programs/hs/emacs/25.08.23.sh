cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
 
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (call-interactively 'tetris)
  (setq mode-line-format '())
  (message \"\"))" "#" "<==" "etetris-vt100"
cd /root/notes;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /root/.emacs.d;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /root/notes;  "emacs" "-q" "--eval" "(progn
  (load \"/tmp/tetris-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (call-interactively 'tetris)
  (setq mode-line-format '())
  (message \"\"))" "#" "<==" "etetris"
