;;; lsp-focus-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "lsp-focus" "lsp-focus.el" (0 0 0 0))
;;; Generated autoloads from lsp-focus.el

(autoload 'lsp-focus-mode "lsp-focus" "\
Enables LSP support for focus.el.

If called interactively, toggle `Lsp-Focus mode'.  If the prefix
argument is positive, enable the mode, and if it is zero or
negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "lsp-focus" '("lsp-focus-thing"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; lsp-focus-autoloads.el ends here
