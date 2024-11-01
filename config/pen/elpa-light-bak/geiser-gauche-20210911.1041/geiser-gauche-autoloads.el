;;; geiser-gauche-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "geiser-gauche" "geiser-gauche.el" (0 0 0 0))
;;; Generated autoloads from geiser-gauche.el

(geiser-activate-implementation 'gauche)

(autoload 'run-gauche "geiser-gauche" "\
Start a Geiser Gauche Scheme REPL." t)

(autoload 'switch-to-gauche "geiser-gauche" "\
Start a Geiser Gauche Scheme REPL, or switch to a running one." t)

(register-definition-prefixes "geiser-gauche" '("gauche" "geiser-gauche--"))

;;;***

;;;### (autoloads nil nil ("geiser-gauche-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; geiser-gauche-autoloads.el ends here
