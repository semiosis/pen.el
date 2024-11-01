;;; flycheck-projectile-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "flycheck-projectile" "flycheck-projectile.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from flycheck-projectile.el

(autoload 'flycheck-projectile-list-errors "flycheck-projectile" "\
Show a list of all the errors in the current project.
Start the project search at DIR. Efficiently handle the case of
the project not changing since the last time this function was
called.

\(fn &optional DIR)" t nil)

(register-definition-prefixes "flycheck-projectile" '("flycheck-projectile-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; flycheck-projectile-autoloads.el ends here
