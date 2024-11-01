;;; evil-visual-mark-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "evil-visual-mark-mode" "evil-visual-mark-mode.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from evil-visual-mark-mode.el

(defvar evil-visual-mark-mode nil "\
Non-nil if Evil-Visual-Mark mode is enabled.
See the `evil-visual-mark-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `evil-visual-mark-mode'.")

(custom-autoload 'evil-visual-mark-mode "evil-visual-mark-mode" nil)

(autoload 'evil-visual-mark-mode "evil-visual-mark-mode" "\
Makes evil marks visible and easy to remember.

If called interactively, toggle `Evil-Visual-Mark mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "evil-visual-mark-mode" '("evil-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; evil-visual-mark-mode-autoloads.el ends here
