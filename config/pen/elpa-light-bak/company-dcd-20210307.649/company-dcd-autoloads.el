;;; company-dcd-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "company-dcd" "company-dcd.el" (0 0 0 0))
;;; Generated autoloads from company-dcd.el

(autoload 'company-dcd-mode "company-dcd" "\
company-backend for Dlang Completion Demon, aka DCD.

If called interactively, toggle `Company-Dcd mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "company-dcd" '("company-dcd"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; company-dcd-autoloads.el ends here
