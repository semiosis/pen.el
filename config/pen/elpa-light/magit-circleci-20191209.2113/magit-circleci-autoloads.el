;;; magit-circleci-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "magit-circleci" "magit-circleci.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from magit-circleci.el

(defvar magit-circleci-mode nil "\
Non-nil if Magit-Circleci mode is enabled.
See the `magit-circleci-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `magit-circleci-mode'.")

(custom-autoload 'magit-circleci-mode "magit-circleci" nil)

(autoload 'magit-circleci-mode "magit-circleci" "\
CircleCI integration for Magit

If called interactively, toggle `Magit-Circleci mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "magit-circleci" '("circleci-transient" "magit-circleci-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; magit-circleci-autoloads.el ends here
