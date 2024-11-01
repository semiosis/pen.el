;;; flycheck-vale-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "flycheck-vale" "flycheck-vale.el" (0 0 0 0))
;;; Generated autoloads from flycheck-vale.el

(autoload 'flycheck-vale-setup "flycheck-vale" "\
Convenience function to setup the vale flycheck checker.

This adds the vale checker to the list of flycheck checkers." nil nil)

(autoload 'flycheck-vale-toggle-enabled "flycheck-vale" "\
Toggle `flycheck-vale-enabled'." t nil)

(register-definition-prefixes "flycheck-vale" '("flycheck-vale-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; flycheck-vale-autoloads.el ends here
