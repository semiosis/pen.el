;;; magit-filenotify-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "magit-filenotify" "magit-filenotify.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from magit-filenotify.el

(autoload 'magit-filenotify-mode "magit-filenotify" "\
Refresh status buffer if source tree changes.

If called interactively, toggle `Magit-Filenotify mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "magit-filenotify" '("magit-filenotify-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; magit-filenotify-autoloads.el ends here
