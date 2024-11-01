;;; company-irony-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "company-irony" "company-irony.el" (0 0 0 0))
;;; Generated autoloads from company-irony.el

(autoload 'company-irony "company-irony" "\


\(fn COMMAND &optional ARG &rest IGNORED)" t nil)

(autoload 'company-irony-setup-begin-commands "company-irony" "\
Include irony trigger commands to `company-begin-commands'.

This allow completion to be automatically triggered after member
accesses (obj.|, obj->|, ...).

This may be useful to company < `0.8.4', newer version of company
include these commands by default." nil nil)

(register-definition-prefixes "company-irony" '("company-irony-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; company-irony-autoloads.el ends here
