;;; marginalia-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "marginalia" "marginalia.el" (0 0 0 0))
;;; Generated autoloads from marginalia.el

(defvar marginalia-mode nil "\
Non-nil if Marginalia mode is enabled.
See the `marginalia-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `marginalia-mode'.")

(custom-autoload 'marginalia-mode "marginalia" nil)

(autoload 'marginalia-mode "marginalia" "\
Annotate completion candidates with richer information.

If called interactively, toggle `Marginalia mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'marginalia-cycle "marginalia" "\
Cycle between annotators in `marginalia-annotator-registry'." t nil)

(register-definition-prefixes "marginalia" '("marginalia-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; marginalia-autoloads.el ends here
