;;; geiser-mit-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "geiser-mit" "geiser-mit.el" (0 0 0 0))
;;; Generated autoloads from geiser-mit.el

(geiser-impl--add-to-alist 'regexp "\\.pkg$" 'mit t)

(geiser-activate-implementation 'mit)

(autoload 'run-mit "geiser-mit" "\
Start a Geiser MIT/GNU Scheme REPL." t)

(autoload 'switch-to-mit "geiser-mit" "\
Start a Geiser MIT/GNU Scheme REPL, or switch to a running one." t)

(register-definition-prefixes "geiser-mit" '("geiser-mit-" "mit"))

;;;***

;;;### (autoloads nil nil ("geiser-mit-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; geiser-mit-autoloads.el ends here
