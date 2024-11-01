;;; transient-posframe-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "transient-posframe" "transient-posframe.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from transient-posframe.el

(defvar transient-posframe-mode nil "\
Non-nil if Transient-Posframe mode is enabled.
See the `transient-posframe-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `transient-posframe-mode'.")

(custom-autoload 'transient-posframe-mode "transient-posframe" nil)

(autoload 'transient-posframe-mode "transient-posframe" "\
Toggle transient posframe mode on of off.

If called interactively, toggle `Transient-Posframe mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "transient-posframe" '("transient-posframe-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; transient-posframe-autoloads.el ends here
