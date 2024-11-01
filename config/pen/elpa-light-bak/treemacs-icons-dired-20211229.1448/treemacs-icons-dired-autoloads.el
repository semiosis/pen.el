;;; treemacs-icons-dired-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "treemacs-icons-dired" "treemacs-icons-dired.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from treemacs-icons-dired.el

(defvar treemacs-icons-dired-mode nil "\
Non-nil if Treemacs-Icons-Dired mode is enabled.
See the `treemacs-icons-dired-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `treemacs-icons-dired-mode'.")

(custom-autoload 'treemacs-icons-dired-mode "treemacs-icons-dired" nil)

(autoload 'treemacs-icons-dired-mode "treemacs-icons-dired" "\
Display treemacs icons for each file in a Dired buffer.

If called interactively, toggle `Treemacs-Icons-Dired mode'.  If
the prefix argument is positive, enable the mode, and if it is
zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'treemacs-icons-dired-enable-once "treemacs-icons-dired" "\
Enable `treemacs-icons-dired-mode' and remove self from `dired-mode-hook'.

This function is meant to be used as a single-use toggle added to
`dired-mode-hook' to enable icons for Dired only once, without having to use
\"with-eval-after-load 'dired\", since Dired tends to be loaded early." nil nil)

(register-definition-prefixes "treemacs-icons-dired" '("treemacs-icons-dired-"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; treemacs-icons-dired-autoloads.el ends here
