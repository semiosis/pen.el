;;; geiser-racket-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "geiser-racket" "geiser-racket.el" (0 0 0 0))
;;; Generated autoloads from geiser-racket.el

(autoload 'geiser-racket-connect "geiser-racket" "\
Start a Racket REPL connected to a remote process.

The remote process needs to be running a REPL server started
using start-geiser, a procedure in the geiser/server module." t nil)

(geiser-activate-implementation 'racket)

(geiser-implementation-extension 'racket "rkt[dl]?")

(add-to-list 'auto-mode-alist '("\\.rkt\\'" . scheme-mode))

(autoload 'run-racket "geiser-racket" "\
Start a Geiser Racket REPL." t)

(register-definition-prefixes "geiser-racket" '("geiser-racket-" "racket"))

;;;***

;;;### (autoloads nil nil ("geiser-racket-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; geiser-racket-autoloads.el ends here
