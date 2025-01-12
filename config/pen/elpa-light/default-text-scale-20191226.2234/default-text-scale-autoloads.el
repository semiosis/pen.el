;;; default-text-scale-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "default-text-scale" "default-text-scale.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from default-text-scale.el

(autoload 'default-text-scale-increase "default-text-scale" "\
Increase the height of the default face by `default-text-scale-amount'." t nil)

(autoload 'default-text-scale-decrease "default-text-scale" "\
Decrease the height of the default face by `default-text-scale-amount'." t nil)

(autoload 'default-text-scale-reset "default-text-scale" "\
Reset the height of the default face.
With prefix argument SET-CURRENT, set the current size as the
default to which subsequent sizes would be reset.

\(fn &optional SET-CURRENT)" t nil)

(defvar default-text-scale-mode nil "\
Non-nil if Default-Text-Scale mode is enabled.
See the `default-text-scale-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `default-text-scale-mode'.")

(custom-autoload 'default-text-scale-mode "default-text-scale" nil)

(autoload 'default-text-scale-mode "default-text-scale" "\
Change the size of the \"default\" face in every frame.

If called interactively, toggle `Default-Text-Scale mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "default-text-scale" '("default-text-scale-"))

;;;***

;;;### (autoloads nil nil ("default-text-scale-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; default-text-scale-autoloads.el ends here
