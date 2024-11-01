;;; tree-sitter-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "tree-sitter" "tree-sitter.el" (0 0 0 0))
;;; Generated autoloads from tree-sitter.el

(autoload 'tree-sitter-mode "tree-sitter" "\
Minor mode that keeps an up-to-date syntax tree using incremental parsing.

If called interactively, toggle `Tree-Sitter mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'turn-on-tree-sitter-mode "tree-sitter" "\
Turn on `tree-sitter-mode' in a buffer, if possible." nil nil)

(put 'global-tree-sitter-mode 'globalized-minor-mode t)

(defvar global-tree-sitter-mode nil "\
Non-nil if Global Tree-Sitter mode is enabled.
See the `global-tree-sitter-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-tree-sitter-mode'.")

(custom-autoload 'global-tree-sitter-mode "tree-sitter" nil)

(autoload 'global-tree-sitter-mode "tree-sitter" "\
Toggle Tree-Sitter mode in all buffers.
With prefix ARG, enable Global Tree-Sitter mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Tree-Sitter mode is enabled in all buffers where
`turn-on-tree-sitter-mode' would do it.

See `tree-sitter-mode' for more information on
Tree-Sitter mode.

\(fn &optional ARG)" t nil)

(define-obsolete-function-alias 'tree-sitter-node-at-point 'tree-sitter-node-at-pos "2021-08-30")

(autoload 'tree-sitter-node-at-pos "tree-sitter" "\
Return the smallest syntax node of type NODE-TYPE at POS.
NODE-TYPE may be a symbol, corresponding to a named syntax node; a string,
corresponding to an anonymous node, or a keyword, holding a special value. For
the special value `:named', return the smallest named node at POS. For the
special value `:anonymous', return the smallest anonymous node at POS. IF POS is
nil, POS defaults to the point. Unless IGNORE-INVALID-TYPE is non-nil, signal an
error when a specified named NODE-TYPE does not exist in the current grammar.
Whenever NODE-TYPE is non-nil (other than `:named'), it is possible for the
function to return nil.

\(fn &optional NODE-TYPE POS IGNORE-INVALID-TYPE)" nil nil)

(register-definition-prefixes "tree-sitter" '("tree-sitter-"))

;;;***

;;;### (autoloads nil "tree-sitter-cli" "tree-sitter-cli.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from tree-sitter-cli.el

(register-definition-prefixes "tree-sitter-cli" '("tree-sitter-cli-"))

;;;***

;;;### (autoloads nil "tree-sitter-debug" "tree-sitter-debug.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from tree-sitter-debug.el

(autoload 'tree-sitter-debug-mode "tree-sitter-debug" "\
Toggle syntax tree debugging for the current buffer.
This mode displays the syntax tree in another buffer, and keeps it up-to-date.

If called interactively, toggle `Tree-Sitter-Debug mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'tree-sitter-debug-query "tree-sitter-debug" "\
Execute query PATTERNS against the current syntax tree and return captures.

If the optional arg MATCHES is non-nil, matches (from `tsc-query-matches') are
returned instead of captures (from `tsc-query-captures').

If the optional arg TAG-ASSIGNER is non-nil, it is passed to `tsc-make-query' to
assign custom tags to capture names.

This function is primarily useful for debugging purpose. Other packages should
build queries and cursors once, then reuse them.

\(fn PATTERNS &optional MATCHES TAG-ASSIGNER)" nil nil)

(register-definition-prefixes "tree-sitter-debug" '("tree-sitter-debug-"))

;;;***

;;;### (autoloads nil "tree-sitter-extras" "tree-sitter-extras.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from tree-sitter-extras.el

(autoload 'tree-sitter-save-excursion "tree-sitter-extras" "\
Save the current location within the syntax tree; execute BODY; restore it.

If the original location cannot be restored due to the syntax tree changing too
much, this macro behaves like `save-excursion', unless
`tree-sitter-save-excursion-try-hard' is non-nil, in which case it tries to get
as close as possible to the original location.

After the location is restored, the buffer text is scrolled so that point stays
at roughly the same vertical screen position. If `pixel-scroll' is available and
`tree-sitter-save-excursion-pixelwise' is non-nil, pixelwise scrolling is used
instead, to make this restoration exact.

\(fn &rest BODY)" nil t)

(function-put 'tree-sitter-save-excursion 'lisp-indent-function '0)

(register-definition-prefixes "tree-sitter-extras" '("tree-sitter-"))

;;;***

;;;### (autoloads nil "tree-sitter-hl" "tree-sitter-hl.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from tree-sitter-hl.el

(autoload 'tree-sitter-hl-add-patterns "tree-sitter-hl" "\
Add custom syntax highlighting PATTERNS.
If LANG-SYMBOL is non-nil, it identifies the language that PATTERNS should be
applied to. If LANG-SYMBOL is nil, PATTERNS are applied to the current buffer,
and are prioritized over language-specific patterns. Either way, PATTERNS are
prioritized over `tree-sitter-hl-default-patterns'.

This function should be used by minor modes and configuration code. Major modes
should set `tree-sitter-hl-default-patterns' instead.

\(fn LANG-SYMBOL PATTERNS)" nil nil)

(function-put 'tree-sitter-hl-add-patterns 'lisp-indent-function '1)

(autoload 'tree-sitter-hl-mode "tree-sitter-hl" "\
Toggle syntax highlighting based on Tree-sitter's syntax tree.
If `tree-sitter-hl-default-patterns' is nil, turning on this mode does nothing,
and does not interfere with `font-lock-mode'.

If called interactively, toggle `Tree-Sitter-Hl mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

Enabling this automatically enables `tree-sitter-mode' in the buffer.

To enable this automatically whenever `tree-sitter-mode' is enabled:

 (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode)

\(fn &optional ARG)" t nil)

(register-definition-prefixes "tree-sitter-hl" '("tree-sitter-hl-"))

;;;***

;;;### (autoloads nil "tree-sitter-load" "tree-sitter-load.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from tree-sitter-load.el

(autoload 'tree-sitter-require "tree-sitter-load" "\
Return the language object loaded and registered under the name LANG-SYMBOL.
If the language has not been loaded yet, load it with `tree-sitter-load'.

FILE should be the base name (without extension) of the native shared library
that exports the language as the native symbol NATIVE-SYMBOL-NAME.

If FILE is nil, the base name is assumed to be LANG-SYMBOL's name.

If NATIVE-SYMBOL-NAME is nil, the name of the exported native symbol is assumed
to be LANG-SYMBOL's name, prefixed with \"tree_sitter_\".

\(fn LANG-SYMBOL &optional FILE NATIVE-SYMBOL-NAME)" nil nil)

(register-definition-prefixes "tree-sitter-load" '("tree-sitter-l"))

;;;***

;;;### (autoloads nil "tree-sitter-query" "tree-sitter-query.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from tree-sitter-query.el

(autoload 'tree-sitter-query-builder "tree-sitter-query" "\
Provide means for developers to write and test tree-sitter queries.

The buffer on focus when the command is called is set as the target buffer." t nil)

(register-definition-prefixes "tree-sitter-query" '("tree-sitter-"))

;;;***

;;;### (autoloads nil nil ("tree-sitter-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; tree-sitter-autoloads.el ends here
