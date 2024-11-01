;;; geiser-chicken-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "geiser-chicken" "geiser-chicken.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from geiser-chicken.el

(geiser-activate-implementation 'chicken)

(geiser-implementation-extension 'chicken "release-info")

(geiser-implementation-extension 'chicken "meta")

(geiser-implementation-extension 'chicken "setup")

(autoload 'run-chicken "geiser-chicken" "\
Start a Geiser Chicken REPL." t)

(autoload 'switch-to-chicken "geiser-chicken" "\
Start a Geiser Chicken REPL, or switch to a running one." t)

(autoload 'connect-to-chicken "geiser-chicken" "\
Connect to a remote Geiser Chicken REPL." t)

(register-definition-prefixes "geiser-chicken" '("chicken" "connect-to-chicken" "geiser-chicken"))

;;;***

;;;### (autoloads nil nil ("geiser-chicken-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; geiser-chicken-autoloads.el ends here
