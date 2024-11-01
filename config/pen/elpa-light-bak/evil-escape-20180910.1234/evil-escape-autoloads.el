;;; evil-escape-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "evil-escape" "evil-escape.el" (0 0 0 0))
;;; Generated autoloads from evil-escape.el

(defvar evil-escape-mode nil "\
Non-nil if Evil-Escape mode is enabled.
See the `evil-escape-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `evil-escape-mode'.")

(custom-autoload 'evil-escape-mode "evil-escape" nil)

(autoload 'evil-escape-mode "evil-escape" "\
Buffer-local minor mode to escape insert state and everything else
with a key sequence.

If called interactively, toggle `Evil-Escape mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "evil-escape" '("evil-escape"))

;;;***

;;;### (autoloads nil nil ("evil-escape-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; evil-escape-autoloads.el ends here
