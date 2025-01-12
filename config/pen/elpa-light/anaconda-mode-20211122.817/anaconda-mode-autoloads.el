;;; anaconda-mode-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "anaconda-mode" "anaconda-mode.el" (0 0 0 0))
;;; Generated autoloads from anaconda-mode.el

(autoload 'anaconda-mode "anaconda-mode" "\
Code navigation, documentation lookup and completion for Python.

If called interactively, toggle `Anaconda mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\\{anaconda-mode-map}

\(fn &optional ARG)" t nil)

(autoload 'anaconda-eldoc-mode "anaconda-mode" "\
Toggle echo area display of Python objects at point.

If called interactively, toggle `Anaconda-Eldoc mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "anaconda-mode" '("anaconda-" "turn-o"))

;;;***

;;;### (autoloads nil nil ("anaconda-mode-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; anaconda-mode-autoloads.el ends here
