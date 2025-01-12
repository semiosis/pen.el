;;; company-plsense-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "company-plsense" "company-plsense.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from company-plsense.el

(autoload 'company-plsense-setup "company-plsense" "\
Setup the default ‘company-plsense’ configuration.
This will start the server and enable command `company-mode'
with the appropriate major modes." t nil)

(autoload 'company-plsense "company-plsense" "\
Company backend for PlSense server.

\(fn COMMAND &optional ARG &rest IGNORED)" t nil)

(register-definition-prefixes "company-plsense" '("company-plsense-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; company-plsense-autoloads.el ends here
