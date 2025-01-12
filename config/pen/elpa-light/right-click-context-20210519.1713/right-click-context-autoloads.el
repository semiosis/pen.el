;;; right-click-context-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "right-click-context" "right-click-context.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from right-click-context.el

(defvar right-click-context-mode nil "\
Non-nil if Right-Click-Context mode is enabled.
See the `right-click-context-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `right-click-context-mode'.")

(custom-autoload 'right-click-context-mode "right-click-context" nil)

(autoload 'right-click-context-mode "right-click-context" "\
Minor mode for enable Right Click Context menu.

If called interactively, enable Right-Click-Context mode if ARG
is positive, and disable it if ARG is zero or negative.  If
called from Lisp, also enable the mode if ARG is omitted or nil,
and toggle it if ARG is `toggle'; disable the mode otherwise.

The mode's hook is called both when the mode is enabled and when
it is disabled.

This mode just binds the context menu to <mouse-3> (\"Right Click\").

\\{right-click-context-mode-map}
If you do not want to bind this right-click, you should not call this minor-mode.

You probably want to just add follows code to your .emacs file (init.el).

    (global-set-key (kbd \"C-c :\") #'right-click-context-menu)

\(fn &optional ARG)" t nil)

(autoload 'right-click-context-click-menu "right-click-context" "\
Open Right Click Context menu by Mouse Click `EVENT'.

\(fn EVENT)" t nil)

(autoload 'right-click-context-menu "right-click-context" "\
Open Right Click Context menu." t nil)

(register-definition-prefixes "right-click-context" '("right-click-context-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; right-click-context-autoloads.el ends here
