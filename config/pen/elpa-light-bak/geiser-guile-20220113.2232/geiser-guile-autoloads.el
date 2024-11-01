;;; geiser-guile-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "geiser-guile" "geiser-guile.el" (0 0 0 0))
;;; Generated autoloads from geiser-guile.el

(autoload 'connect-to-guile "geiser-guile" "\
Start a Guile REPL connected to a remote process.

Start the external Guile process with the flag --listen to make
it spawn a server thread." t nil)

(geiser-activate-implementation 'guile)

(autoload 'run-guile "geiser-guile" "\
Start a Geiser Guile REPL." t)

(autoload 'switch-to-guile "geiser-guile" "\
Start a Geiser Guile REPL, or switch to a running one." t)

(register-definition-prefixes "geiser-guile" '("geiser-guile-" "guile"))

;;;***

;;;### (autoloads nil nil ("geiser-guile-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; geiser-guile-autoloads.el ends here
