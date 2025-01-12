;;; company-try-hard-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "company-try-hard" "company-try-hard.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from company-try-hard.el

(autoload 'company-try-hard "company-try-hard" "\
Offer completions from the first backend in `company-backends' that
offers candidates. If called again, use the next backend, and so on." t nil)

(register-definition-prefixes "company-try-hard" '("company-try-hard--last-index"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; company-try-hard-autoloads.el ends here
