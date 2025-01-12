;;; diredfl-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "diredfl" "diredfl.el" (0 0 0 0))
;;; Generated autoloads from diredfl.el

(autoload 'diredfl-mode "diredfl" "\
Enable additional font locking in `dired-mode'.

If called interactively, toggle `Diredfl mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(put 'diredfl-global-mode 'globalized-minor-mode t)

(defvar diredfl-global-mode nil "\
Non-nil if Diredfl-Global mode is enabled.
See the `diredfl-global-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `diredfl-global-mode'.")

(custom-autoload 'diredfl-global-mode "diredfl" nil)

(autoload 'diredfl-global-mode "diredfl" "\
Toggle Diredfl mode in all buffers.
With prefix ARG, enable Diredfl-Global mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Diredfl mode is enabled in all buffers where
`(lambda nil (when (derived-mode-p 'dired-mode) (diredfl-mode)))' would do it.

See `diredfl-mode' for more information on
Diredfl mode.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "diredfl" '("diredfl-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; diredfl-autoloads.el ends here
