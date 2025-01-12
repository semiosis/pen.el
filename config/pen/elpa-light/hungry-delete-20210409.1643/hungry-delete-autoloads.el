;;; hungry-delete-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "hungry-delete" "hungry-delete.el" (0 0 0 0))
;;; Generated autoloads from hungry-delete.el

(autoload 'hungry-delete-forward "hungry-delete" "\
Delete the following character, or all of the following
whitespace, up to the next non-whitespace character.  See
\\[c-hungry-delete-forward].

hungry-delete-backward tries to mimic delete-backward-char's
behavior in several ways: if the region is activate, it deletes
the text in the region.  If a prefix argument is given, delete
the following N characters (previous if N is negative).

Optional second arg KILLFLAG non-nil means to kill (save in kill
ring) instead of delete.  Interactively, N is the prefix arg, and
KILLFLAG is set if N was explicitly specified.

\(fn N &optional KILLFLAG)" t nil)

(autoload 'hungry-delete-backward "hungry-delete" "\
Delete the preceding character or all preceding whitespace
back to the previous non-whitespace character.  See also
\\[c-hungry-delete-backward].

hungry-delete-backward tries to mimic delete-backward-char's
behavior in several ways: if the region is activate, it deletes
the text in the region.  If a prefix argument is given, delete
the previous N characters (following if N is negative).

In Overwrite mode, single character backward deletion may replace
tabs with spaces so as to back over columns, unless point is at
the end of the line.

Optional second arg KILLFLAG, if non-nil, means to kill (save in
kill ring) instead of delete.  Interactively, N is the prefix
arg, and KILLFLAG is set if N is explicitly specified.

\(fn N &optional KILLFLAG)" t nil)

(autoload 'hungry-delete-mode "hungry-delete" "\
Minor mode to enable hungry deletion.  This will delete all
whitespace after or before point when the deletion command is
executed.

If called interactively, toggle `Hungry-Delete mode'.  If the
prefix argument is positive, enable the mode, and if it is zero
or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'turn-on-hungry-delete-mode "hungry-delete" "\
Turn on hungry delete mode if the buffer is appropriate." t nil)

(put 'global-hungry-delete-mode 'globalized-minor-mode t)

(defvar global-hungry-delete-mode nil "\
Non-nil if Global Hungry-Delete mode is enabled.
See the `global-hungry-delete-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `global-hungry-delete-mode'.")

(custom-autoload 'global-hungry-delete-mode "hungry-delete" nil)

(autoload 'global-hungry-delete-mode "hungry-delete" "\
Toggle Hungry-Delete mode in all buffers.
With prefix ARG, enable Global Hungry-Delete mode if ARG is positive;
otherwise, disable it.  If called from Lisp, enable the mode if
ARG is omitted or nil.

Hungry-Delete mode is enabled in all buffers where
`turn-on-hungry-delete-mode' would do it.

See `hungry-delete-mode' for more information on
Hungry-Delete mode.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "hungry-delete" '("hungry-delete-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; hungry-delete-autoloads.el ends here
