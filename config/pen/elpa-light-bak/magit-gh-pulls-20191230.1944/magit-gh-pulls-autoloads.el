;;; magit-gh-pulls-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "magit-gh-pulls" "magit-gh-pulls.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from magit-gh-pulls.el

(autoload 'magit-gh-pulls-mode "magit-gh-pulls" "\
Pull requests support for Magit

If called interactively, toggle `Magit-Gh-Pulls mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'turn-on-magit-gh-pulls "magit-gh-pulls" "\
Unconditionally turn on `magit-pulls-mode'." nil nil)

(register-definition-prefixes "magit-gh-pulls" '("-magit-gh-pulls-filter-and-split-host-lines" "magit-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; magit-gh-pulls-autoloads.el ends here
