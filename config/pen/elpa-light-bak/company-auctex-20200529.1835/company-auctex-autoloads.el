;;; company-auctex-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "company-auctex" "company-auctex.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from company-auctex.el

(autoload 'company-auctex-macros "company-auctex" "\
company-auctex-macros backend

\(fn COMMAND &optional ARG &rest IGNORED)" t nil)

(autoload 'company-auctex-symbols "company-auctex" "\
company-auctex-symbols backend

\(fn COMMAND &optional ARG &rest IGNORED)" t nil)

(autoload 'company-auctex-environments "company-auctex" "\
company-auctex-environments backend

\(fn COMMAND &optional ARG &rest IGNORED)" t nil)

(autoload 'company-auctex-labels "company-auctex" "\
company-auctex-labels backend

\(fn COMMAND &optional ARG &rest IGNORED)" t nil)

(autoload 'company-auctex-bibs "company-auctex" "\
company-auctex-bibs backend

\(fn COMMAND &optional ARG &rest IGNORED)" t nil)

(autoload 'company-auctex-init "company-auctex" "\
Add backends provided by company-auctex to company-backends." nil nil)

(register-definition-prefixes "company-auctex" '("car-or" "company-auctex-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; company-auctex-autoloads.el ends here
