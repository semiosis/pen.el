;;; geiser-chibi-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "geiser-chibi" "geiser-chibi.el" (0 0 0 0))
;;; Generated autoloads from geiser-chibi.el

(geiser-implementation-extension 'chibi "sld")

(geiser-activate-implementation 'chibi)

(autoload 'run-chibi "geiser-chibi" "\
Start a Geiser Chibi Scheme REPL." t)

(autoload 'switch-to-chibi "geiser-chibi" "\
Start a Geiser Chibi Scheme REPL, or switch to a running one." t)

(register-definition-prefixes "geiser-chibi" '("chibi" "geiser-chibi-"))

;;;***

;;;### (autoloads nil nil ("geiser-chibi-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; geiser-chibi-autoloads.el ends here
