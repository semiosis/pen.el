;;; annotate-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "annotate" "annotate.el" (0 0 0 0))
;;; Generated autoloads from annotate.el

(let ((loads (get 'annotate 'custom-loads))) (if (member '"annotate" loads) nil (put 'annotate 'custom-loads (cons '"annotate" loads))))

(autoload 'annotate-mode "annotate" "\
Toggle Annotate mode.
See https://github.com/bastibe/annotate.el/ for documentation.

If called interactively, toggle `Annotate mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "annotate" '("annotat"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; annotate-autoloads.el ends here
