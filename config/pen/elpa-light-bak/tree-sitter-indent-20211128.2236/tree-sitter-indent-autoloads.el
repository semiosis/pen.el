;;; tree-sitter-indent-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "tree-sitter-indent" "tree-sitter-indent.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from tree-sitter-indent.el

(autoload 'tree-sitter-indent-line "tree-sitter-indent" "\
Use Tree-sitter as backend to indent current line." nil nil)

(autoload 'tree-sitter-indent-mode "tree-sitter-indent" "\
Use Tree-sitter as backend for indenting buffer.

If called interactively, toggle `Tree-Sitter-Indent mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "tree-sitter-indent" '("tree-sitter-indent-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; tree-sitter-indent-autoloads.el ends here
