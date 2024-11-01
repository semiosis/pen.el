;;; company-prescient-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "company-prescient" "company-prescient.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from company-prescient.el

(defvar company-prescient-mode nil "\
Non-nil if Company-Prescient mode is enabled.
See the `company-prescient-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `company-prescient-mode'.")

(custom-autoload 'company-prescient-mode "company-prescient" nil)

(autoload 'company-prescient-mode "company-prescient" "\
Minor mode to use prescient.el in Company completions.

If called interactively, toggle `Company-Prescient mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "company-prescient" '("company-prescient-"))

;;;***

;;;### (autoloads nil nil ("company-prescient-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; company-prescient-autoloads.el ends here
