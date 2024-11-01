;;; evil-visualstar-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "evil-visualstar" "evil-visualstar.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from evil-visualstar.el

(autoload 'evil-visualstar-mode "evil-visualstar" "\
Minor mode for visual star selection.

If called interactively, toggle `Evil-Visualstar mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(put 'global-evil-visualstar-mode 'globalized-minor-mode t)

(defvar global-evil-visualstar-mode nil "\
Non-nil if Global Evil-Visualstar mode is enabled.
See the `global-evil-visualstar-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-evil-visualstar-mode'.")

(custom-autoload 'global-evil-visualstar-mode "evil-visualstar" nil)

(autoload 'global-evil-visualstar-mode "evil-visualstar" "\
Toggle Evil-Visualstar mode in all buffers.
With prefix ARG, enable Global Evil-Visualstar mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Evil-Visualstar mode is enabled in all buffers where
`turn-on-evil-visualstar-mode' would do it.

See `evil-visualstar-mode' for more information on
Evil-Visualstar mode.

\(fn &optional ARG)" t nil)

(autoload 'turn-on-evil-visualstar-mode "evil-visualstar" "\
Turns on visual star selection." t nil)

(autoload 'turn-off-evil-visualstar-mode "evil-visualstar" "\
Turns off visual star selection." t nil)

(register-definition-prefixes "evil-visualstar" '("evil-visualstar/"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; evil-visualstar-autoloads.el ends here
