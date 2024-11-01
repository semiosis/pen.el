;;; magit-delta-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "magit-delta" "magit-delta.el" (0 0 0 0))
;;; Generated autoloads from magit-delta.el

(autoload 'magit-delta-mode "magit-delta" "\
Use Delta when displaying diffs in Magit.

If called interactively, toggle `Magit-Delta mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

https://github.com/dandavison/delta

\(fn &optional ARG)" t nil)

(register-definition-prefixes "magit-delta" '("magit-delta-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; magit-delta-autoloads.el ends here
