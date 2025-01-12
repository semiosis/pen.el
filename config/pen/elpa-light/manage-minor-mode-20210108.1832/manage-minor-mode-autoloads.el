;;; manage-minor-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "manage-minor-mode" "manage-minor-mode.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from manage-minor-mode.el

(autoload 'manage-minor-mode-set "manage-minor-mode" "\
Manage minor mode set." nil nil)

(autoload 'manage-minor-mode "manage-minor-mode" "\
The minor mode.
Record for the $LAST-TOGGLED-ITEM.

\(fn &optional $LAST-TOGGLED-ITEM)" t nil)

(autoload 'manage-minor-mode-bals "manage-minor-mode" "\
Eradicate all minor-modes in the current buffer.
This command may cause unexpected effect even to other buffers.
However, don't worry, restore command exists:
`manage-minor-mode-restore-from-bals'." t nil)

(register-definition-prefixes "manage-minor-mode" '("manage-minor-mode-"))

;;;***

;;;### (autoloads nil nil ("manage-minor-mode-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; manage-minor-mode-autoloads.el ends here
