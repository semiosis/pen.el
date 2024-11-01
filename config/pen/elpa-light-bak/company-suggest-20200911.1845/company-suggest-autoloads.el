;;; company-suggest-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "company-suggest" "company-suggest.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from company-suggest.el

(autoload 'company-suggest-google "company-suggest" "\
`company-mode' completion backend for Google suggestions.

\(fn COMMAND &optional ARG &rest IGNORED)" t nil)

(autoload 'company-suggest-wiktionary "company-suggest" "\
`company-mode' completion backend for Wiktionary suggestions.

\(fn COMMAND &optional ARG &rest IGNORED)" t nil)

(register-definition-prefixes "company-suggest" '("company-suggest-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; company-suggest-autoloads.el ends here
