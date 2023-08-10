(require 'popwin)

;; Actually, I don't really want this package.
;; It might conflict with shackle.

;; (popwin-mode -1)
(comment
  (popwin-mode 1)

  (setq popwin:special-display-config
        '(("*Miniedit Help*" :noselect t)
          help-mode
          (completion-list-mode :noselect t)
          (compilation-mode :noselect t)
          (grep-mode :noselect t)
          (occur-mode :noselect t)
          ("*Pp Macroexpand Output*" :noselect t)
          "*Shell Command Output*" "*vc-diff*" "*vc-change-log*"
          (" *undo-tree*" :width 60 :position right)
          ("^\\*anything.*\\*$" :regexp t)
          "*slime-apropos*" "*slime-macroexpansion*" "*slime-description*"
          ("*slime-compilation*" :noselect t)
          "*slime-xref*"
          (sldb-mode :stick t)
          slime-repl-mode slime-connection-list-mode)))

(provide 'pen-popwin)
