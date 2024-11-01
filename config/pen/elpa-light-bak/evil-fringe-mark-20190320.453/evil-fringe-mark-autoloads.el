;;; evil-fringe-mark-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "evil-fringe-mark" "evil-fringe-mark.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from evil-fringe-mark.el

(autoload 'evil-fringe-mark-mode "evil-fringe-mark" "\
Display evil-mode marks in the fringe.

If called interactively, toggle `Evil-Fringe-Mark mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(defvar global-evil-fringe-mark-mode nil "\
Non-nil if Global Evil-Fringe-Mark mode is enabled.
See the `global-evil-fringe-mark-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-evil-fringe-mark-mode'.")

(custom-autoload 'global-evil-fringe-mark-mode "evil-fringe-mark" nil)

(autoload 'global-evil-fringe-mark-mode "evil-fringe-mark" "\
Display evil-mode marks in the fringe.  Global version of `evil-fringe-mark-mode'.

If called interactively, toggle `Global Evil-Fringe-Mark mode'.
If the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "evil-fringe-mark" '("evil-fringe-mark-"))

;;;***

;;;### (autoloads nil "evil-fringe-mark-overlays" "evil-fringe-mark-overlays.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from evil-fringe-mark-overlays.el

(register-definition-prefixes "evil-fringe-mark-overlays" '("evil-fringe-mark-bitmaps"))

;;;***

;;;### (autoloads nil nil ("evil-fringe-mark-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; evil-fringe-mark-autoloads.el ends here
