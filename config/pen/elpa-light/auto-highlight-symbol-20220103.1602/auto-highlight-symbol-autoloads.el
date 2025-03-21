;;; auto-highlight-symbol-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "auto-highlight-symbol" "auto-highlight-symbol.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from auto-highlight-symbol.el

(put 'global-auto-highlight-symbol-mode 'globalized-minor-mode t)

(defvar global-auto-highlight-symbol-mode nil "\
Non-nil if Global Auto-Highlight-Symbol mode is enabled.
See the `global-auto-highlight-symbol-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-auto-highlight-symbol-mode'.")

(custom-autoload 'global-auto-highlight-symbol-mode "auto-highlight-symbol" nil)

(autoload 'global-auto-highlight-symbol-mode "auto-highlight-symbol" "\
Toggle Auto-Highlight-Symbol mode in all buffers.
With prefix ARG, enable Global Auto-Highlight-Symbol mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Auto-Highlight-Symbol mode is enabled in all buffers where
`ahs-mode-maybe' would do it.

See `auto-highlight-symbol-mode' for more information on
Auto-Highlight-Symbol mode.

\(fn &optional ARG)" t nil)

(autoload 'auto-highlight-symbol-mode "auto-highlight-symbol" "\
Toggle Auto Highlight Symbol Mode

If called interactively, toggle `Auto-Highlight-Symbol mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "auto-highlight-symbol" '("ahs-" "auto-highlight-symbol-mode" "dropdown-list-overlays"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; auto-highlight-symbol-autoloads.el ends here
