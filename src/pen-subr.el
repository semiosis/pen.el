;; Always use the minibuffer
(defun use-dialog-box-p ()
  "Return non-nil if the current command should prompt the user via a dialog box."
  ;; (and last-input-event                 ; not during startup
  ;;      (or (consp last-nonmenu-event)   ; invoked by a mouse event
  ;;          (and (null last-nonmenu-event)
  ;;               (consp last-input-event))
  ;;          from--tty-menu-p)            ; invoked via TTY menu
  ;;      use-dialog-box)
  nil)

(provide 'pen-subr)
