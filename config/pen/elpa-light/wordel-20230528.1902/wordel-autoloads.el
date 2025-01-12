;;; wordel-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "wordel" "wordel.el" (0 0 0 0))
;;; Generated autoloads from wordel.el

(autoload 'wordel "wordel" "\
Start a new game.
If STATE is non-nil, it is used in lieu of `wordel--game'.

\(fn &optional STATE)" t nil)

(autoload 'wordel-marathon "wordel" "\
Start a new marathon." t nil)

(autoload 'wordel-help "wordel" "\
Display game rules." t nil)

(autoload 'wordel-choose-word-list "wordel" "\
Set `wordel-word-list-file' to file at PATH.

\(fn PATH)" t nil)

(register-definition-prefixes "wordel" '("wordel-"))

;;;***

;;;### (autoloads nil nil ("wordel-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; wordel-autoloads.el ends here
