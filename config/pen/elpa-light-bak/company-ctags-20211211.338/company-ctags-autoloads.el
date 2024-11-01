;;; company-ctags-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "company-ctags" "company-ctags.el" (0 0 0 0))
;;; Generated autoloads from company-ctags.el

(autoload 'company-ctags-debug-info "company-ctags" "\
Print all debug information." t nil)

(autoload 'company-ctags "company-ctags" "\
Completion backend of for ctags.  Execute COMMAND with ARG and IGNORED.

\(fn COMMAND &optional ARG &rest IGNORED)" t nil)

(autoload 'company-ctags-replace-backend "company-ctags" "\
Replace `company-etags' with `company-ctags' in BACKENDS.

\(fn BACKENDS)" nil nil)

(autoload 'company-ctags-auto-setup "company-ctags" "\
Set up `company-backends'." nil nil)

(register-definition-prefixes "company-ctags" '("company-ctags-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; company-ctags-autoloads.el ends here
