;;; consult-lsp-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "consult-lsp" "consult-lsp.el" (0 0 0 0))
;;; Generated autoloads from consult-lsp.el

(autoload 'consult-lsp-diagnostics "consult-lsp" "\
Query LSP-mode diagnostics. When ARG is set through prefix, query all workspaces.

\(fn ARG)" t nil)

(autoload 'consult-lsp-symbols "consult-lsp" "\
Query workspace symbols. When ARG is set through prefix, query all workspaces.

\(fn ARG)" t nil)

(autoload 'consult-lsp-file-symbols "consult-lsp" "\
Search symbols defined in current file in a manner similar to `consult-line'.

If the prefix argument GROUP-RESULTS is specified, symbols are grouped by their
kind; otherwise they are returned in the order that they appear in the file.

\(fn GROUP-RESULTS)" t nil)

(register-definition-prefixes "consult-lsp" '("consult-lsp-"))

;;;***

;;;### (autoloads nil "consult-lsp-marginalia" "consult-lsp-marginalia.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from consult-lsp-marginalia.el

(defvar consult-lsp-marginalia-mode nil "\
Non-nil if Consult-Lsp-Marginalia mode is enabled.
See the `consult-lsp-marginalia-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `consult-lsp-marginalia-mode'.")

(custom-autoload 'consult-lsp-marginalia-mode "consult-lsp-marginalia" nil)

(autoload 'consult-lsp-marginalia-mode "consult-lsp-marginalia" "\
Use marginalia with consult-lsp functions.

If called interactively, toggle `Consult-Lsp-Marginalia mode'.
If the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "consult-lsp-marginalia" '("consult-lsp-marginalia--"))

;;;***

;;;### (autoloads nil nil ("consult-lsp-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; consult-lsp-autoloads.el ends here
