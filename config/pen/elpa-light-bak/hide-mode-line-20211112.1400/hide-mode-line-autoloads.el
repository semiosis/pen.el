;;; hide-mode-line-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "hide-mode-line" "hide-mode-line.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from hide-mode-line.el

(autoload 'hide-mode-line-mode "hide-mode-line" "\
Minor mode to hide the mode-line in the current buffer.

If called interactively, toggle `Hide-Mode-Line mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(put 'global-hide-mode-line-mode 'globalized-minor-mode t)

(defvar global-hide-mode-line-mode nil "\
Non-nil if Global Hide-Mode-Line mode is enabled.
See the `global-hide-mode-line-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-hide-mode-line-mode'.")

(custom-autoload 'global-hide-mode-line-mode "hide-mode-line" nil)

(autoload 'global-hide-mode-line-mode "hide-mode-line" "\
Toggle Hide-Mode-Line mode in all buffers.
With prefix ARG, enable Global Hide-Mode-Line mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Hide-Mode-Line mode is enabled in all buffers where
`turn-on-hide-mode-line-mode' would do it.

See `hide-mode-line-mode' for more information on
Hide-Mode-Line mode.

\(fn &optional ARG)" t nil)

(autoload 'turn-on-hide-mode-line-mode "hide-mode-line" "\
Turn on `hide-mode-line-mode'.
Unless in `fundamental-mode' or `hide-mode-line-excluded-modes'." nil nil)

(autoload 'turn-off-hide-mode-line-mode "hide-mode-line" "\
Turn off `hide-mode-line-mode'." nil nil)

(register-definition-prefixes "hide-mode-line" '("hide-mode-line-"))

;;;***

;;;### (autoloads nil nil ("hide-mode-line-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; hide-mode-line-autoloads.el ends here
