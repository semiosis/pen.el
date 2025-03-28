;;; highlight-indent-guides-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "highlight-indent-guides" "highlight-indent-guides.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from highlight-indent-guides.el

(autoload 'highlight-indent-guides-auto-set-faces "highlight-indent-guides" "\
Automatically calculate indent guide faces.
If this feature is enabled, calculate reasonable values for the indent guide
colors based on the current theme's colorscheme, and set them appropriately.
This runs whenever a theme is loaded, but it can also be run interactively." t nil)

(autoload 'highlight-indent-guides-mode "highlight-indent-guides" "\
Display indent guides in a buffer.

If called interactively, toggle `Highlight-Indent-Guides mode'.
If the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "highlight-indent-guides" '("highlight-indent-guides-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; highlight-indent-guides-autoloads.el ends here
