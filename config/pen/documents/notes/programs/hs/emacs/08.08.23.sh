cd /;  "emacs" "--daemon=/root/.emacs.d/server/pen-emacsd-1" "#" "<==" "emacsclient"
cd /root/notes;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /;  "emacs" "--daemon=/root/.emacs.d/server/pen-emacsd-2" "#" "<==" "emacsclient"
cd /root/.emacs.d/host/pen.el/scripts;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /root/.pen/documents/notes;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /root/.pen/documents/notes;  "emacs" "-nw" "--debug-init" "#" "<==" "zsh"
cd /root/.pen/documents/notes;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /root/.pen/documents/notes;  "emacs" "-nw" "--debug-init" "#" "<==" "zsh"
cd /root/.pen/documents/notes;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /root/.pen/documents/notes;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /root/.pen/documents/notes;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /root/.pen/documents/notes;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /root/notes;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /;  "emacs" "--daemon=/root/.emacs.d/server/pen-emacsd-1" "#" "<==" "emacsclient"
cd /;  "emacs" "--daemon=/root/.emacs.d/server/pen-emacsd-2" "#" "<==" "emacsclient"
cd /root/notes;  "emacs" "--daemon=/root/.emacs.d/server/DEFAULT" "#" "<==" "emacsclient"
cd /;  "emacs" "--daemon=/root/.emacs.d/server/pen-emacsd-1" "#" "<==" "emacsclient"
cd /;  "emacs" "--daemon=/root/.emacs.d/server/pen-emacsd-2" "#" "<==" "emacsclient"
cd /root/.pen/documents/notes;  "emacs" "-q" "--eval" "(progn
  (load \"/tmp/tetris-load.el\")
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (call-interactively 'tetris)
  (setq mode-line-format '())
  (message \"\"))" "#" "<==" "etetris"
cd /root/.pen/documents/notes;  "emacs" "-nw" "-q" "--eval" "(progn
 
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (call-interactively 'tetris)
  (setq mode-line-format '())
  (message \"\"))" "#" "<==" "etetris-vt100"
cd /root/.pen/documents/notes;  "emacs" "-nw" "-q" "--eval" "(progn
 
  (define-key global-map (kbd \"q\") #'save-buffers-kill-terminal)
  (tool-bar-mode -1)
  (menu-bar-mode -1)
  (call-interactively 'tetris)
  (setq mode-line-format '())
  (message \"\"))" "#" "<==" "etetris-xterm"
