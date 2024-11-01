;;; geiser-gambit-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "geiser-gambit" "geiser-gambit.el" (0 0 0 0))
;;; Generated autoloads from geiser-gambit.el

(autoload 'connect-to-gambit "geiser-gambit" "\
Start a Gambit REPL connected to a remote process." t nil)

(geiser-activate-implementation 'gambit)

(autoload 'run-gambit "geiser-gambit" "\
Start a Geiser Gambit REPL." t)

(autoload 'switch-to-gambit "geiser-gambit" "\
Start a Geiser Gambit REPL, or switch to a running one." t)

(register-definition-prefixes "geiser-gambit" '("gambit" "geiser-gambit-"))

;;;***

;;;### (autoloads nil nil ("geiser-gambit-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; geiser-gambit-autoloads.el ends here
