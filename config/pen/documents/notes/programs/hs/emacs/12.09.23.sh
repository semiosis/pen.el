cd /root/notes;  "emacs" "-nw" "-q" "--eval" "(progn
 
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (call-interactively 'tetris)
  (setq mode-line-format '())
  (message \"\"))" "#" "<==" "etetris-vt100"
