;;; geiser-chez-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "geiser-chez" "geiser-chez.el" (0 0 0 0))
;;; Generated autoloads from geiser-chez.el

(geiser-implementation-extension 'chez "def")

(geiser-activate-implementation 'chez)

(autoload 'run-chez "geiser-chez" "\
Start a Geiser Chez REPL." t)

(autoload 'switch-to-chez "geiser-chez" "\
Start a Geiser Chez REPL, or switch to a running one." t)

(register-definition-prefixes "geiser-chez" '("chez" "geiser-chez-"))

;;;***

;;;### (autoloads nil nil ("geiser-chez-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; geiser-chez-autoloads.el ends here
