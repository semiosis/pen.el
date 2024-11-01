;;; hy-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "hy-base" "hy-base.el" (0 0 0 0))
;;; Generated autoloads from hy-base.el

(register-definition-prefixes "hy-base" '("hy--"))

;;;***

;;;### (autoloads nil "hy-font-lock" "hy-font-lock.el" (0 0 0 0))
;;; Generated autoloads from hy-font-lock.el

(register-definition-prefixes "hy-font-lock" '("hy-font-lock-" "inferior-hy-font-lock-kwds"))

;;;***

;;;### (autoloads nil "hy-jedhy" "hy-jedhy.el" (0 0 0 0))
;;; Generated autoloads from hy-jedhy.el

(autoload 'run-jedhy "hy-jedhy" "\
Startup internal Hy interpreter process, enabling jedhy for `company-mode'." t nil)

(register-definition-prefixes "hy-jedhy" '("company-hy" "hy-" "run-jedhy--pyvenv-post-deactive-hook"))

;;;***

;;;### (autoloads nil "hy-mode" "hy-mode.el" (0 0 0 0))
;;; Generated autoloads from hy-mode.el

(add-to-list 'auto-mode-alist '("\\.hy\\'" . hy-mode))

(add-to-list 'interpreter-mode-alist '("hy" . hy-mode))

(autoload 'hy-mode "hy-mode" "\
Major mode for editing Hy files.

\(fn)" t nil)

(autoload 'hy-insert-pdb "hy-mode" "\
Import and set pdb trace at point." t nil)

(register-definition-prefixes "hy-mode" '("hy-" "inferior-hy-mode-syntax-table"))

;;;***

;;;### (autoloads nil "hy-shell" "hy-shell.el" (0 0 0 0))
;;; Generated autoloads from hy-shell.el

(autoload 'inferior-hy-mode "hy-shell" "\
Major mode for Hy inferior process.

\(fn)" t nil)

(autoload 'run-hy "hy-shell" "\
Startup and/or switch to a Hy interpreter process." t nil)

(register-definition-prefixes "hy-shell" '("hy-"))

;;;***

;;;### (autoloads nil nil ("hy-mode-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; hy-mode-autoloads.el ends here
